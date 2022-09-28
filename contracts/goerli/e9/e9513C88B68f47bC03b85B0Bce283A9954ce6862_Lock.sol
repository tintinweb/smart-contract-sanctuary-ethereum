// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract Lock {
    string [] public arr = ['prashant','vijay','ajay','ravi','raj','akash'];
    address public admin;

    constructor() {
        admin = msg.sender;
    }
    
    modifier onlyOwner()  {
       require(admin == msg.sender,"Admin can do this action");
        _;
    }

    function addUser(string memory user) public {
        arr.push(user);
    }

    function allUsers() public view returns (string [] memory){
        return arr;
    }

    function random() internal view returns (uint){
        return uint(keccak256(abi.encodePacked(block.difficulty, block.coinbase, msg.sender)));
    }

    function checkWinner() public view onlyOwner returns (string memory){
        require(arr.length >= 2, 'Users not enough');
        uint indexing = random() % arr.length;
        return arr[indexing];
    }

    function resetLottery() public onlyOwner{
        delete arr;
    }

    function pay(address to) public {
        payable(to).transfer(0.1 ether);
    }

    
}