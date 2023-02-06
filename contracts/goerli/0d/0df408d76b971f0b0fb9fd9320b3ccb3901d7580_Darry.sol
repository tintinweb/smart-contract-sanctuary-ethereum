/**
 *Submitted for verification at Etherscan.io on 2023-02-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// import "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
// import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";


struct IdData {
    uint256 targetId;
    bool matched;
    bool revoking;
    uint256[] targetIdHistory;
}

contract Darry {
    address public ownerId;
    mapping(address => uint256) private _addressMap;
    mapping(uint256 => IdData) private _idMap;

    event IdMatch(uint256 leftId, uint256 rightId);
    event IdUnmatch(uint256 leftId, uint256 rightId);

    constructor() {
        ownerId = msg.sender;
    }

    function matchTarget(uint256 myId, uint256 targetId) public {
        require(myId != 0 && targetId != 0, "wrong fields");
        require(_addressMap[msg.sender] == 0 || _addressMap[msg.sender] == myId, "wrong ID");
        require(_idMap[myId].matched == false, "Already set");

        _addressMap[msg.sender] = myId;
        _idMap[myId].targetId = targetId;

        if (_idMap[targetId].targetId != 0) {
            require(_idMap[targetId].targetId == myId, "not match");
            require(_idMap[targetId].matched == false, "not match");
            require(_idMap[targetId].revoking == false, "not match");
            _idMap[myId].matched = true;
            _idMap[targetId].matched = true;
            emit IdMatch(myId, targetId);
        }
    }

    function unmatchTarget() public {
        uint256 myId = _addressMap[msg.sender];
        require(myId != 0, "not set yet");
        require(_idMap[myId].targetId != 0, "not set yet");
        uint256 targetId = _idMap[myId].targetId;
        if (_idMap[myId].matched == true) {
            if (_idMap[targetId].revoking == true) {
                _idMap[myId].targetId = 0;
                _idMap[myId].revoking = false;
                _idMap[myId].matched = false;
                _idMap[targetId].targetId = 0;
                _idMap[targetId].revoking = false;
                _idMap[targetId].matched = false;
                _idMap[myId].targetIdHistory.push(targetId);
                _idMap[targetId].targetIdHistory.push(myId);
            } else {
                _idMap[myId].revoking = true;
            }
        } else {
            _idMap[myId].targetId = 0;
            _idMap[myId].revoking = false;
        }
    }

    function checkMatched(uint256 userId) public view returns (bool) {
        if (userId == 0) {
            userId = _addressMap[msg.sender];
        }
        return _idMap[userId].matched;
    }

    function checkRevoking(uint256 userId) public view returns (bool) {
        if (userId == 0) {
            userId = _addressMap[msg.sender];
        }
        return _idMap[userId].revoking;
    }
}