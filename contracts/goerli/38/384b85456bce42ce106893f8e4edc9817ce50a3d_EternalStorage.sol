/**
 *Submitted for verification at Etherscan.io on 2022-08-15
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract EternalStorage{
    // EternalStorage contract by Crypto Chyvak
    mapping(address => string) public cells;
    address payable public owner;

    constructor(){
        owner = payable(msg.sender);
    }

    function write(string memory _data) public{
        require(bytes(_data).length <= 30, "String is too long");
        require(bytes(cells[msg.sender]).length == 0, "Cell is not empty");
        cells[msg.sender] = _data;
    }

    function rewrite(string memory _data) public payable{
        require(bytes(_data).length <= 30, "String is too long");
        require(msg.value >= 1000000 gwei, "Send more than 0.001 BNB");
        cells[msg.sender] = _data;
    }

    function read() view public returns(string memory){
        return (cells[msg.sender]);
    }

    function withdraw() public{
        require(msg.sender == owner, "Only owner!");
        owner.transfer(address(this).balance);
    }
}