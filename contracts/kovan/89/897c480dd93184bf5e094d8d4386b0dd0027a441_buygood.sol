/**
 *Submitted for verification at Etherscan.io on 2022-03-27
*/

// File: buygood.sol

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

struct paylog{
    address customer;
    uint value;
    bool isvalid;
}

contract buygood{

    address public owner;
    mapping(string => paylog) logs;

    constructor() {
        owner = msg.sender;
    }

    receive() external payable {}

    modifier onlyowner() {
        require(msg.sender == owner,"Only Owner");
        _;
    }

    function withdraw() public payable onlyowner {
        payable(owner).transfer(address(this).balance);
    }

    function buy(string memory hash) public payable returns (bool) {
        logs[hash] = paylog(msg.sender,msg.value,true);
        return true;
    }

    function check(string memory hash, address customer,uint value) public view returns (bool) {
        paylog memory log = logs[hash];
        if(log.customer != customer || log.value < value || log.isvalid == false){
            return false;
        }
        else{
            return true;
        }
    }

}