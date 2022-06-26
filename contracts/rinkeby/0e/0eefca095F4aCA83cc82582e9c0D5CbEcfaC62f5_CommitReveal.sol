// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


contract CommitReveal {
    uint constant public MIN_REGISTRATION_DURATION = 28 days;

    uint public minCommitmentAge;
    uint public maxCommitmentAge;

    mapping(bytes32=>uint) public commitments;
    mapping(bytes32=>uint) public commitVal;

    bool public locked = false;
    address immutable seller;
    address immutable seaPort;
    address buyer;

    modifier lockedTrue {
      require(locked == true);
      _;
    }
    modifier lockedFalse {
      require(locked == false);
      _;
    }  

    constructor(uint _minCommitmentAge, uint _maxCommitmentAge, address _seaPort)  {
        require(_maxCommitmentAge > _minCommitmentAge);
        minCommitmentAge = _minCommitmentAge;
        maxCommitmentAge = _maxCommitmentAge;
        seller = msg.sender;
        seaPort = _seaPort;
    }

    function getCommitment(bool trueCommit, address buyer_, bytes32 secret) pure public returns(bytes32) {
        return keccak256(abi.encodePacked(trueCommit, buyer_, secret));
    }
    function commit(bytes32 commitment) public payable lockedFalse{
        commitments[commitment] = block.timestamp;
        commitVal[commitment] += msg.value;
    }
    function reveal(bytes32 commitment, bytes32 secret) public lockedFalse{
        require(keccak256(abi.encodePacked(true, msg.sender, secret)) == commitment, "Wrong reveal inputs!");
        locked = true;
        buyer = msg.sender;
        payable(seller).transfer(commitVal[commitment]);
    }
    function validateReveal(address caller, address offerer, bytes32 secret) external view returns (bool) {
        if (locked == true) {
            return true;
        } else {
            return false;
        }
    }
    function refund(bool trueCommit, bytes32 commitment, bytes32 secret) public {
        require(keccak256(abi.encodePacked(trueCommit, msg.sender, secret)) == commitment);
        if (locked == true || (block.timestamp - commitments[commitment] > maxCommitmentAge)){
            uint returnValue = commitVal[commitment];
            commitVal[commitment] = 0;
            payable(msg.sender).transfer(returnValue);
        }
    }
}