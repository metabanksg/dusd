// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

contract vote {

    struct Candidate {
        uint256 id;
        string name;
        uint256 votes;
    }

    uint256 public totalCandidates; // 候选人总数
    uint256 public totalVotes; // 投票总数

    mapping(address => bool) public hasVoted; // 地址是否已投票映射
    mapping(string => bool) public didVoted; // DID是否已投票映射

    mapping(uint256 => Candidate) public candidates; // 候选人映射
    uint256 public nextCandidateId; // 下一个候选人的ID

    address public chairperson; // 主席地址

    constructor(uint256 _totalCandidates) {
        totalCandidates = _totalCandidates;
        chairperson = msg.sender; // 合约创建者为主席
        nextCandidateId = 1; // 初始化候选人ID为1
    }

    modifier onlyChairperson() {
        require(msg.sender == chairperson, "Only the chairperson can perform this action"); // 限制只有主席可以执行
        _;
    }

    //增加候选人
    function addCandidate(string memory candidateName) public onlyChairperson returns (uint256) {
        require(nextCandidateId <= totalCandidates, "The number of candidates has reached the upper limit"); // 确保候选人数量未超过上限

        Candidate storage candidate = candidates[nextCandidateId];
        candidate.id = nextCandidateId;
        candidate.name = candidateName;
        candidate.votes = 0;

        nextCandidateId++; // 更新下一个候选人的ID

        return candidate.id; // 返回候选人ID
    }

    function voting(uint256 candidateId, string memory did) public returns (bool) {
        require(candidateId > 0 && candidateId < nextCandidateId, "Invalid candidate"); // 确保候选人ID有效
        require(!hasVoted[msg.sender], "You have already voted"); // 确保地址未投票
        require(!didVoted[did], "This DID has already voted"); // 确保DID未投票

        Candidate storage candidate = candidates[candidateId];
        candidate.votes++; // 增加候选人的得票数

        hasVoted[msg.sender] = true; // 将地址标记为已投票状态
        didVoted[did] = true; // 将DID标记为已投票状态

        totalVotes++; // 增加总投票数

        return true;
    }

    function getVotes(uint256 candidateId) public view returns (uint256) {
        require(candidateId > 0 && candidateId < nextCandidateId, "Invalid candidate"); // 确保候选人ID有效

        Candidate storage candidate = candidates[candidateId];
        return candidate.votes; // 返回候选人的得票数
    }

    //返回所有候选人信息
    function getAllCandidates() public view returns (Candidate[] memory) {
        Candidate[] memory allCandidates = new Candidate[](nextCandidateId - 1);

        for (uint256 i = 1; i < nextCandidateId; i++) {
            Candidate storage candidate = candidates[i];
            allCandidates[i - 1] = candidate;
        }

        return allCandidates;
    }

}
