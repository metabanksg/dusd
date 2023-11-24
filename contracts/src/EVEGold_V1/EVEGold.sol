// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./LockedGoldOracle.sol";

contract EVEGold is IERC20, Ownable {

    using SafeMath for uint256;

    //代币名称、代币符号、小数位数
    string public constant name = "EVE Gold";
    string public constant symbol = "EGT";
    uint8 public constant decimals = 8;

    //代币单位 10^8 即 100000000（由于小数位数为 8）
    uint256 private constant TOKEN = 10 ** uint256(decimals);

    //每天的秒数
    uint256 private constant DAY = 86400;

    //每年的天数
    uint256 private constant YEAR = 365;

    //存储费用分母 0.25%/每年
    uint256 private constant STORAGE_FEE_DENOMINATOR = 40000000000;

    //在经过一天后需要支付存储费用的最低余额：
    uint256 private constant MIN_BALANCE_FOR_FEES = 146000;

    //代币总供应量上限
    uint256 public constant SUPPLY_CAP = 8133525786 * TOKEN;

    //每个地址的代币余额：_balances，通过地址映射到对应的余额。
    mapping (address => uint256) private _balances;

    //允许从地址进行转账的授权额度：_allowances，通过地址映射到对应的授权额度。
    mapping (address => mapping (address => uint256)) private _allowances;

    //上次支付存储费用的时间
    mapping (address => uint256) private _timeStorageFeePaid;

    //不需要支付存储费用的地址：_storageFeeExempt，通过地址映射到布尔值。
    mapping (address => bool) private _storageFeeExempt;

    //存储费用的宽限期：_storageFeeGracePeriod，通过地址映射到对应的宽限期天数。
    mapping (address => uint256) private _storageFeeGracePeriod;

    //当前的代币总供应量
    uint256 private _totalSupply;

    //存储费用收集的地址
    address private _feeAddress;

    // “支持金库”的地址。当一块金条被锁定在金库中用于铸币时，它们会在backed_treasury中创建，然后可以从这个地址出售。
    address private _backedTreasury;

    // “未支持金库”的地址。 未支持金库是存储未锁定在金库中的多余代币的存储地址
    // 因此不对应于任何现实世界的值。 如果有新的锁定在金库中，代币将首先从未支持的状态中移走
    // 在铸造新代币之前将金库存入支持的金库。
    // 该地址仅接受来自 _backedTreasury 的转账
    address private _unbackedTreasury;

    //用于确定流通中的代币数量的 LockedGoldOracle 的地址：_oracle。
    address private _oracle;

    //可以强制要求支付存储费用
    address private _feeEnforcer;

    //存储费用的宽限期天数
    uint256 private _storageFeeGracePeriodDays = 0;

    // 当金条被锁定时，我们通过将其从非支持金库转移或铸造新代币的方式向流通中添加代币
    event AddBackedGold(uint256 amount);

    // 在金条可以解锁（从流通中移除）之前，它们必须被移动到非支持金库，
    // 当这种情况发生时，我们会发出一个事件来表示流通供应的变化
    event RemoveGold(uint256 amount);


    /**
    * @param unbackedTreasury 无支持金库的地址
    * @param backedTreasury 支持金库的地址
    * @param feeAddress 收取费用的地址
    * @param oracle 的地址
    */
    constructor(address unbackedTreasury, address backedTreasury, address feeAddress, address oracle) public {
        _unbackedTreasury = unbackedTreasury;
        _backedTreasury = backedTreasury;
        _feeAddress = feeAddress;
        _feeEnforcer = owner();
        _oracle = oracle;
        setFeeExempt(_feeAddress);
        setFeeExempt(_backedTreasury);
        setFeeExempt(_unbackedTreasury);
        setFeeExempt(owner());
    }

    /**
     * @dev 将账户设置为免除所有费用。这可以在特殊情况下用于由EVE、交易所等拥有的冷存储地址。
     * @param account 要免除存储费用的账户
    */
    function setFeeExempt(address account) public onlyOwner {
        _storageFeeExempt[account] = true;
    }

    /**
      * @dev 如果被执行者以外的任何帐户调用则抛出异常
    */
    modifier onlyEnforcer() {
        require(msg.sender == _feeEnforcer);
        _;
    }

    /**
     * @dev 给指定地址转账token
     * @param to 要传输到的地址。
     * @param value 要转账的金额。
    */
    function transfer(address to, uint256 value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    /**
     * @dev 授权指定地址代表msg.sender花费指定数量的代币。
     * @param spender 将花费资金的地址。
     * @param value 要花费的代币数量。
     */
    function approve(address spender, uint256 value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev 从一个地址向另一个地址转移代币。
     * 注意，虽然此函数会触发Approval事件，但根据规范并不需要，其他符合规范的实现可能不会触发该事件。
     * 还要注意，即使没有显式检查余额要求，任何超过批准金额的转账尝试都会由于SafeMath将批准减去负余额而自动失败。
     * @param from 要发送代币的地址。
     * @param to 要转移代币的地址。
     * @param value 要转移的代币数量。
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        _transfer(from, to, value);
        _approve(from, msg.sender, _allowances[from][msg.sender].sub(value));
        return true;
    }

    /**
     * @dev 增加一个地址能够花费的代币数量。
     * 当allowed_[_spender] == 0时，应调用approve。
     * 为了增加授权值，最好使用这个函数，以避免2次调用（并等待第一笔交易被确认）。
     * 触发Approval事件。
     * @param spender 将花费资金的地址。
     * @param addedValue 要增加的授权金额。
     */
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    /**
     * @dev 减少一个地址能够花费的代币数量。
     * 当allowed_[_spender] == 0时，应调用approve。
     * 为了减少授权值，最好使用这个函数，以避免2次调用（并等待第一笔交易被确认）。
     * 触发Approval事件。
     * @param spender 将花费资金的地址。
     * @param subtractedValue 要减少的授权金额。
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    /**
     * @dev 向支持的资金池添加一定数量的代币。这将首先从_unbackedTreasury地址中取出任何代币，并将其移动到_backedTreasury地址。
     * 任何剩余的代币将实际进行铸造。
     * 如果根据LockedGoldOracle确定，没有足够的锁定黄金供应来验证此操作，则此操作将失败。
     *
     * @param value 要添加到支持中的代币数量。
     * @return 操作是否成功的布尔值。
     */
    function addBackedTokens(uint256 value) external onlyOwner returns (bool)
    {
        uint256 unbackedBalance = _balances[_unbackedTreasury];

        // 使用oracle检查实际上是否有足够的黄金在保管库中
        uint256 lockedGrams =  LockedGoldOracle(_oracle).lockedGold();

        // 如果总供应量超过实际在保险库中锁定的数量，则应拒绝铸造
        require(lockedGrams >= totalCirculation().add(value),
            "Insufficent grams locked in LockedGoldOracle to complete operation");

        // 如果我们有足够的余额，只需从_unbackedTreasury转移到_backedTreasury地址
        if (value <= unbackedBalance) {
            _transfer(_unbackedTreasury, _backedTreasury, value);
        } else {
            if (unbackedBalance > 0) {
                // 没有足够的余额，因此我们既要转移又要铸造新代币
                // 将剩余的_unbackedTreasury余额转移到backedTreasury
                _transfer(_unbackedTreasury, _backedTreasury, unbackedBalance);
            }

            // 并且铸造剩余的代币到backedTreasury
            _mint(value.sub(unbackedBalance));
        }
        emit AddBackedGold(value);
        return true;
    }

    /**
     * @dev 手动为发送者地址支付存储费用。交易所可以定期调用此函数支付欠费的存储费用。
     * 这是比“发送给自己”更便宜的选项，后者还会触发支付存储费用。
     *
     * @return 表示操作是否成功的布尔值。
     */
    function payStorageFee() external returns (bool) {
        _payStorageFee(msg.sender);
        return true;
    }

    /**
     * @dev 合约允许在地址满足以下条件时，强制收取存储费用：
     * 如果距离上次支付该地址的存储费用已经超过365天，则可以收取存储费用。
     *
     * @param account 要支付存储费用的地址
     * @return 表示操作是否成功的布尔值。
     */
    function forcePayFees(address account) external onlyEnforcer returns(bool) {
        require(account != address(0));
        require(_balances[account] > 0,
            "Account has no balance, cannot force paying fees");

        // 强制支付欠费的存储费用，
        // 只能在存储费用逾期超过365天时调用
        require(daysSincePaidStorageFee(account) >= YEAR,
            "Account has paid storage fees more recently than 365 days");
        uint256 paid = _payStorageFee(account);
        require(paid > 0, "No appreciable storage fees due, will refund gas");

        return true;
    }

    /**
     * @dev 设置可以强制从用户那里收取费用的地址。
     * @param enforcer 强制收取费用的地址
     * @return 表示成功更改执行者地址的布尔值。
     */
    function setFeeEnforcer(address enforcer) external onlyOwner returns(bool) {
        require(enforcer != address(0));
        _feeEnforcer = enforcer;
        setFeeExempt(_feeEnforcer);
        return true;
    }

    /**
     * @dev 设置收取费用的地址。
     * @param newFeeAddress 收取存储费用的地址
     * @return 表示成功更改费用地址的布尔值。
     */
    function setFeeAddress(address newFeeAddress) external onlyOwner returns(bool) {
        require(newFeeAddress != address(0));
        require(newFeeAddress != _unbackedTreasury,
            "Cannot set fee address to unbacked treasury");
        _feeAddress = newFeeAddress;
        setFeeExempt(_feeAddress);
        return true;
    }

    /**
     * @dev 设置支持金库的地址。
     * @param newBackedAddress 支持金库的地址
     * @return 表示成功更改支持地址的布尔值。
     */
    function setBackedAddress(address newBackedAddress) external onlyOwner returns(bool) {
        require(newBackedAddress != address(0));
        require(newBackedAddress != _unbackedTreasury,
            "Cannot set backed address to unbacked treasury");
        _backedTreasury = newBackedAddress;
        setFeeExempt(_backedTreasury);
        return true;
    }

    /**
     * @dev 设置未支持金库的地址。
     * @param newUnbackedAddress 未支持金库的地址
     * @return 表示成功更改未支持地址的布尔值。
     */
    function setUnbackedAddress(address newUnbackedAddress) external onlyOwner returns(bool) {
        require(newUnbackedAddress != address(0));
        require(newUnbackedAddress != _backedTreasury,
            "Cannot set unbacked treasury to backed treasury");
        require(newUnbackedAddress != _feeAddress,
            "Cannot set unbacked treasury to fee address ");
        _unbackedTreasury = newUnbackedAddress;
        setFeeExempt(_unbackedTreasury);
        return true;
    }

    /**
     * @dev 设置LockedGoldOracle地址。
     * @param oracleAddress Oracle的地址
     * @return 表示成功更改oracle地址的布尔值。
     */
    function setOracleAddress(address oracleAddress) external onlyOwner returns(bool) {
        require(oracleAddress != address(0));
        _oracle = oracleAddress;
        return true;
    }

    /**
     * @dev 设置存储费用开始计算前的天数宽限期。
     * @param daysGracePeriod 存储费用开始计算前的全局宽限期设置。
     * 请注意，调用此函数不会更改已经处于宽限期内的地址的宽限期。
     */
    function setStorageFeeGracePeriodDays(uint256 daysGracePeriod) external onlyOwner {
        _storageFeeGracePeriodDays = daysGracePeriod;
    }

    /**
     * @dev 将该账户设置为免除存储费用。这可以在特殊情况下用于由EVE、交易所等拥有的冷存储地址。
     * @param account 要免除存储费用的账户
     */
    function setStorageFeeExempt(address account) external onlyOwner {
        _storageFeeExempt[account] = true;
    }

    /**
     * @dev 获取指定地址的余额，扣除欠费并考虑包括转账费用在内的最大可发送金额。
     * @param owner 要查询余额的地址。
     * @return 代表通过传入地址可以发送的金额（包括交易和存储费用）的uint256值。
     */
    function balanceOf(address owner) external view returns (uint256) {
        return calcSendAllBalance(owner);
    }

    /**
     * @dev 获取指定地址的余额，不扣除欠费。
     * 这返回的是在合约存储中当前存储的“传统”ERC-20余额。
     * @param owner 要查询余额的地址。
     * @return 代表存储在传入地址中的金额的uint256值。
     */
    function balanceOfNoFees(address owner) external view returns (uint256) {
        return _balances[owner];
    }

    /**
     * @dev 总发行量。这包括未支持的金库中的代币，这些代币基本上是不可用的且不在流通中。
     * @return 代表发行的总代币数量的uint256值。
     */
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev 检查所有者允许spender花费的代币数量。
     * @param owner 拥有资金的地址。
     * @param spender 将花费资金的地址。
     * @return 指定仍然可供spender使用的代币数量的uint256值。
     */
    function allowance(address owner, address spender) external view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @return 强制支付过期未付费的地址
    */
    function feeEnforcer() external view returns(address) {
        return _feeEnforcer;
    }

    /**
     * @return 收集费用的地址
   */
    function feeAddress() external view returns(address) {
        return _feeAddress;
    }

    /**
     * @return 支持金库的地址
   */
    function backedTreasury() external view returns(address) {
        return _backedTreasury;
    }

    /**
    * @return 未支持金库的地址
  */
    function unbackedTreasury() external view returns(address) {
        return _unbackedTreasury;
    }

    /**
    * @return Oracle合约的地址
  */
    function oracleAddress() external view returns(address) {
        return _oracle;
    }

    /**
    * @return 免除存储费用的天数和地址
  */
    function storageFeeGracePeriodDays() external view returns(uint256) {
        return _storageFeeGracePeriodDays;
    }

    /**
     * @dev 检查给定地址是否免除存储费用
     * @param account 要检查的地址
     * @return 一个布尔值，指示传入的地址是否免除存储费用
     */
    function isStorageFeeExempt(address account) public view returns(bool) {
        return _storageFeeExempt[account];
    }

    /**
     * @dev 实际流通中的代币总量，即扣除未支持金库中的代币总量
     * @return 代表实际流通中的代币总量的uint256值
     */
    function totalCirculation() public view returns (uint256) {
        return _totalSupply.sub(_balances[_unbackedTreasury]);
    }

    /**
     * @dev 获取账户最后一次支付存储费用以来的天数
     * @param account 要检查的地址
     * @return 一个uint256值，表示距离上次支付存储费用的天数
     */
    function daysSincePaidStorageFee(address account) public view returns(uint256) {
        if (_timeStorageFeePaid[account] == 0) {
            return 0;
        }
        return block.timestamp.sub(_timeStorageFeePaid[account]).div(DAY);
    }

    /**
     * @dev 计算清除地址余额所需的金额，包括欠款的存储费
     * @param account 要检查的地址
     * @return 一个表示地址可用于发送的总金额的 uint256 值
     */
    function calcSendAllBalance(address account) public view returns (uint256) {
        require(account != address(0));

        //内部地址不支付费用，因此它们可以发送其全部余额
        uint256 balanceAfterStorage = _balances[account].sub(calcStorageFee(account));

        // 当余额为 0.00000001 但实际上为 0 时的边界情况
        if (balanceAfterStorage <= 1) {
            return 0;
        }

        // 计算包括存储费用在内的全部发送金额
        // 发送全部金额 = 余额 / 1.001
        // 并四舍五入到 0.00000001
        uint256 sendAllAmount = balanceAfterStorage.mul(TOKEN).add(1);

        // 修复包括舍入误差
        if (sendAllAmount > balanceAfterStorage) {
            return sendAllAmount.sub(1);
        }

        return sendAllAmount;
    }


    /**
     * @dev 计算给定地址当前应支付的存储费用
     * @param account 要检查的地址
     * @return 一个 uint256 值，表示地址当前的存储费用
     */
    function calcStorageFee(address account) public view returns(uint256) {

        //账户被豁免支付存储费用，或者账户余额为0，则返回0
        uint256 balance = _balances[account];
        if (isStorageFeeExempt(account) || balance == 0) {
            return 0;
        }

        uint256 daysSinceStoragePaid = daysSincePaidStorageFee(account);
        uint256 gracePeriod = _storageFeeGracePeriod[account];

        // 如果存在宽限期，可以从 daysSinceStoragePaid 中扣除它
        if (gracePeriod > 0) {
            if (daysSinceStoragePaid > gracePeriod) {
                daysSinceStoragePaid = daysSinceStoragePaid.sub(gracePeriod);
            } else {
                daysSinceStoragePaid = 0;
            }
        }

        if (daysSinceStoragePaid == 0) {
            return 0;
        }

        // 常规情况下的存储费用计算
        return storageFee(balance, daysSinceStoragePaid);
    }

    /*
     * @dev 计算给定余额在一定数量的天数过去后，自上次支付费用以来应支付的存储费用
     * @param balance 地址的当前余额
     * @param daysSinceStoragePaid 自上次支付费用以来过去的天数
     * @return 一个表示应支付的存储费用的 uint256 值
     */
    function storageFee(uint256 balance, uint256 daysSinceStoragePaid) public pure returns(uint256) {
        uint256 fee = balance.mul(TOKEN).mul(daysSinceStoragePaid).div(YEAR).div(STORAGE_FEE_DENOMINATOR);
        if (fee > balance) {
            return balance;
        }
        return fee;
    }

    /**
     * @dev 授权一个地址可以花费另一个地址的代币
     * @param owner 拥有代币的地址
     * @param spender 将花费代币的地址
     * @param value 可以花费的代币数量
     */
    function _approve(address owner, address spender, uint256 value) internal {
        require(spender != address(0));
        require(owner != address(0));

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    /**
     * @dev 为指定地址之间的转账传输代币。与标准的 ERC20 合约不同，转账还必须处理代币本身的转账和存储费用。此外，还有一些内部地址不需要支付费用。
     * @param from 要转账的地址
     * @param to 接收代币的地址
     * @param value 要转账的数量
     */
    function _transfer(address from, address to, uint256 value) internal {

        _transferRestrictions(to, from);

        uint256 storageFeeFrom = calcStorageFee(from);
        uint256 storageFeeTo = 0;
        uint256 allFeeFrom = storageFeeFrom;
        uint256 balanceFromBefore = _balances[from];
        uint256 balanceToBefore = _balances[to];

        // 如果不是自己转账，则需要支付接收方的存储费用
        if (from != to) {
            // 如果不是自己转账，则接收方需要存储费用
            storageFeeTo = calcStorageFee(to);
            _balances[from] = balanceFromBefore.sub(value).sub(allFeeFrom);
            _balances[to] = balanceToBefore.add(value).sub(storageFeeTo);
            _balances[_feeAddress] = _balances[_feeAddress].add(allFeeFrom).add(storageFeeTo);

        } else {
            // 如果转账给自己，则只需要支付存储费用
            _balances[from] = balanceFromBefore.sub(storageFeeFrom);
            _balances[_feeAddress] = _balances[_feeAddress].add(storageFeeFrom);
        }

        // 常规转账
        emit Transfer(from, to, value);

        // 从 `from` 地址中转移手续费
        if (allFeeFrom > 0) {
            emit Transfer(from, _feeAddress, allFeeFrom);
            if (storageFeeFrom > 0) {
                _endGracePeriod(from);
            }
        }

        // 从 `to` 地址中转移存储费用
        if (storageFeeTo > 0) {
            emit Transfer(to, _feeAddress, storageFeeTo);
            _endGracePeriod(to);
        } else if (balanceToBefore < MIN_BALANCE_FOR_FEES) {
            // MIN_BALANCE_FOR_FEES 是在经过一天后产生存储费用的最低金额，因此如果余额高于该金额，
            // 存储费用将始终大于0。
            //
            // 这避免了以下情况：
            // 1. 用户接收代币
            // 2. 用户将所有代币转移到其他地址，仅保留少量代币
            // 3. 一年后，用户再次接收代币。由于其先前的余额非常小，没有明显的存储费用，因此存储费用计时器未重置
            // 4. 用户现在需要在整个余额上支付存储费用，就好像他们持有代币一年，而不是重置计时器到当前时间。
            _timeStorageFeePaid[to] = block.timestamp;
        }

        // 如果转账到未支持的金库，则代币正在从流通中被取出，因为黄金正在从保险库中“解锁”
        if (to == _unbackedTreasury) {
            emit RemoveGold(value);
        }
    }

    /**
     * @dev 对转账地址的限制规则进行强制执行
     * @param to 发送地址
     * @param from 接收地址
     */
    function _transferRestrictions(address to, address from) internal view {
        require(from != address(0));
        require(to != address(0));
        require(to != address(this), "Cannot transfer tokens to the contract");

        // 未支持的资金池只能转账给支持的资金池
        if (from == _unbackedTreasury) {
            require(to == _backedTreasury,
                "Unbacked treasury can only transfer to backed treasury");
        }

        // 只有支持的资金池可以转账给未支持的资金池
        if (to == _unbackedTreasury) {
            require((from == _backedTreasury),
                "Unbacked treasury can only receive from backed treasury");
        }

        // 只有未支持的资金池可以转账给支持的资金池
        if (to == _backedTreasury) {
            require((from == _unbackedTreasury),
                "Only unbacked treasury can transfer to backed treasury");
        }
    }

    /**
     * @dev 向支持的金库铸造代币的函数。通常情况下，此方法不会单独调用，而是从 addBackedTokens 调用。
     * @param value 要铸造到支持的金库的代币数量
     * @return 表示操作是否成功的布尔值。
     */
    function _mint(uint256 value) internal returns(bool) {

        // 不能超过总供应上限
        require(_totalSupply.add(value) <= SUPPLY_CAP, "Call would exceed supply cap");

        // 只能在未支持的金库余额为0时进行铸造
        require(_balances[_unbackedTreasury] == 0, "The unbacked treasury balance is not 0");

        // 只能铸造给支持的金库
        _totalSupply = _totalSupply.add(value);
        _balances[_backedTreasury] = _balances[_backedTreasury].add(value);
        emit Transfer(address(0), _backedTreasury, value);
        return true;
    }

    /**
     * @dev 应用存储费用扣除
     * @param account 要支付存储费用的账户
     * @return 表示支付的存储费用的 uint256 值
     */
    function _payStorageFee(address account) internal returns(uint256) {
        uint256 storeFee = calcStorageFee(account);
        if (storeFee == 0) {
            return 0;
        }

        // 减少账户余额并增加到费用地址
        _balances[account] = _balances[account].sub(storeFee);
        _balances[_feeAddress] = _balances[_feeAddress].add(storeFee);
        emit Transfer(account, _feeAddress, storeFee);
        _timeStorageFeePaid[account] = block.timestamp;
        _endGracePeriod(account);
        return storeFee;
    }

    /**
     * @dev 关闭地址的存储费用宽限期（当宽限期结束后第一次支付存储费用时）
     * @param account 要关闭存储费用宽限期的账户
     */
    function _endGracePeriod(address account) internal {
        if (_storageFeeGracePeriod[account] > 0) {
            _storageFeeGracePeriod[account] = 0;
        }
    }
}
