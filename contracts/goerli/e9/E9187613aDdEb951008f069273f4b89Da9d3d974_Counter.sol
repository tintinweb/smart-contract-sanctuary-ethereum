// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract Counter {
    //counter计数；
    uint public counter;
    //管理员；
    address public admin;
    //初始化counter,admin；
    constructor() {
        counter = 0;
        admin = msg.sender;
    }
    //累加步数为一；
    function count() public onlyOwner {
        counter +=1;
    }
    //按指定数据累加；
    function add(uint num) public onlyOwner {
        counter += num;
    }
    //counter归零；
    function clear() public onlyOwner {
        counter = 0;
    }
    //修改器鉴权；
    modifier onlyOwner() {
        require(admin == msg.sender,"Only Admin");
        _;
    }
}