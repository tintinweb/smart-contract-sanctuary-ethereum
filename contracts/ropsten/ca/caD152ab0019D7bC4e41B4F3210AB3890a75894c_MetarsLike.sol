// contracts/MetarsLike.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

contract MetarsLike {
    address public owner;

    uint256 public maxVotePer;
    uint256 public currentTerm;
    uint256 public startTime;
    uint256 public endTime;

    // address -> (artId => termId)
    mapping(address => mapping(uint256 => uint256)) public userVotedMap;
    // artId -> (termId => vote)
    mapping(uint256 => mapping(uint256 => uint256)) public artVoteMap;
    // address => (artId => (termId => vote))
    mapping(address => mapping(uint256 => mapping(uint256 => uint256))) public voteMap;

    constructor(uint256 _startTime, uint256 _endTime) {
        owner = msg.sender;
        maxVotePer = 10;
        currentTerm = 1;
        startTime = _startTime;
        endTime = _endTime;
    }

    event Liked(address indexed _user, uint256 _termId, uint256 _artId, uint256 _vote);

    function like(
        uint256 _termId,
        uint256 _artId,
        uint256 _voteAmount
    ) external {
        require(currentTerm == _termId, "Err: termId error");
        require(block.timestamp >= startTime, "Err: not start");
        require(block.timestamp <= endTime, "Err: already end");
        require(_voteAmount <= maxVotePer, "Err: voteAmount too big");
        uint256 alreadyUseVote = userVotedMap[msg.sender][_termId];
        require((alreadyUseVote + _voteAmount) <= maxVotePer, "Err: exceed maxVotePer");
        userVotedMap[msg.sender][_termId] = alreadyUseVote + _voteAmount;
        artVoteMap[_artId][_termId] = artVoteMap[_artId][_termId] + _voteAmount;

        mapping(uint256 => uint256) storage _artMap = voteMap[msg.sender][_artId];
        _artMap[_termId] = _artMap[_termId] + _voteAmount;
        emit Liked(msg.sender, _termId, _artId, _voteAmount);
    }

    function setNextTerm(uint256 _startTime, uint256 _endTime) external {
        require(msg.sender == owner, "not owner");
        currentTerm = currentTerm + 1;
       
        startTime = _startTime;
        endTime = _endTime;
    }

    function queryUserVote(
        uint256 _termId,
        address _user,
        uint256 _artId
    ) external view returns (uint256) {
        return voteMap[_user][_artId][_termId];
    }

    function queryArtVote(uint256 _termId, uint256 _artId) external view returns (uint256) {
        return artVoteMap[_artId][_termId];
    }

    function queryUserUsedVote(uint256 _termId, address _user) external view returns (uint256) {
        return userVotedMap[_user][_termId];
    }
}