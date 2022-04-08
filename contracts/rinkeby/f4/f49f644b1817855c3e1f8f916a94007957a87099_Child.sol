/**
 *Submitted for verification at Etherscan.io on 2022-04-08
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract HelloWorld {
    string private name;
    bool b;
    mapping(address => uint) id_mapping;
    mapping(uint => string) name_mapping;
    uint sum = 0;
    address owner;

    struct stduent {
        string name;
        uint grade;
    }

    constructor() {
        name = "hello";
        owner = msg.sender;
    }

    // 用于修饰函数的
    modifier OnlyOwner {
        require(msg.sender == owner);
        // 动态添加
        _;
    }

    modifier ControlLevel(uint needLevel) {
        require(needLevel > 2);
        _;
    }

    function changeName(string memory _name) public OnlyOwner ControlLevel(2) {
        name = _name;
    }

    function register(string memory n) public {
        sum++;
        address account = msg.sender;
        id_mapping[account] = sum;
        name_mapping[sum] = n;
    }

    function getIdByAddress(address addr) public view returns(uint) {
        return id_mapping[addr];
    }

    function getNameById(uint id) public view returns(string memory) {
        return name_mapping[id];
    }

    // function getName() public view returns (string memory) {
    //     return name;
    // }

    // function setName(string memory _name) public {
    //     name = _name;
    // }

    function pureName(string memory _name) pure public returns (string memory) {
        return _name;
    }

    function getBool() public view returns (bool) {
        return b;
    }

    function equal(int num1, int num2) public pure returns (bool) {
        return num1 == num2;
    }

    function pay() public payable {

    }

    function getThisBalance() public view returns (uint) {
        return address(this).balance;
    }

    function getBalance(address account) public view returns (uint) {
        return account.balance;
    }

    function transfer() external payable {
        require(msg.value > 0);
        address account = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;
        // payable(account).transfer(msg.value);
        payable(account).transfer(10 ether);
    }

    // function kill() public {
    //     if(msg.sender == owner) {
    //         selfdestruct(owner);
    //     }
    // }
}

contract Child is HelloWorld {
        
}