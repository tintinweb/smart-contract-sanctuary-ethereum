/**
 *Submitted for verification at Etherscan.io on 2022-06-03
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.14;

contract Transactions {
    address public owner;
    uint256 public transactionCount;
    uint256 public totalAmount;

    event Transfer(address from, address receiver, uint amount, string message, uint256 timestamp, string keyword, string metaData);
    event PuppyAdded(string dogId, string imageUrl, uint256 timestamp);

    struct TransferStruct { 
        address sender;
        address receiver;
        uint amount;
        string message;
        uint256 timestamp;
        string keyword;
        string metaData; // dogId, -1 for donate food
    }
    
    struct Puppy {
        string dogId;
        string imageUrl;
    }

    TransferStruct[] transactions;
    Puppy[] puppies;
    mapping (string => TransferStruct[]) puppyMap;  // dogId => Transaction[]

    constructor(address _owner) {
        owner = _owner;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    function setOwner(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }

    function checkIsOwner() public view returns (bool) {
        return msg.sender == owner;
    }

    function donateForFood(uint amount, string memory message, string memory keyword) public {
        transactionCount += 1;
        totalAmount += amount;
        transactions.push(TransferStruct(msg.sender, owner, amount, message, block.timestamp, keyword, "-1"));

        emit Transfer(msg.sender, owner, amount, message, block.timestamp, keyword, "-1");
    }

    function donateForPupppy(string memory dogId, uint amount, string memory message, string memory keyword) public {
        transactionCount += 1;
        totalAmount += amount;
        transactions.push(TransferStruct(msg.sender, owner, amount, message, block.timestamp, keyword, dogId));
        puppyMap[dogId].push(TransferStruct(msg.sender, owner, amount, message, block.timestamp, keyword, dogId));
        
        emit Transfer(msg.sender, owner, amount, message, block.timestamp, keyword, dogId);
    }

    function addPuppy(string memory dogId, string memory imageUrl) public onlyOwner {
        puppies.push(Puppy(dogId, imageUrl));

        emit PuppyAdded(dogId, imageUrl, block.timestamp);
    }

    function getAllPuppys() public view returns (Puppy[] memory) {
        return puppies;
    }

    // get donate details by dogId
    function getPuppyDonateDetailById(string memory dogId) public view returns (TransferStruct[] memory) {
        return puppyMap[dogId];
    }

    // all transactions (optimize: paging)
    function getAllTransactions() public view returns (TransferStruct[] memory) {
        return transactions;
    }
}