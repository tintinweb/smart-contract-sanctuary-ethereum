/**
 *Submitted for verification at Etherscan.io on 2022-03-19
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;


contract Chal {
    string private flag;
    address public owner = msg.sender;

    constructor(string memory _flag) {
        flag = _flag;
    }

    function random() private view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, msg.sender)));        
    }

    function query() public payable returns (bytes1) {
        require(msg.value >= 15 ether);
        bytes memory _flag = bytes(flag);
        bytes1 idx = bytes1(uint8(random() % _flag.length));
        return _flag[uint8(idx)] ^ idx;
    }

    function withdraw(address payable to) public {
        require (msg.sender == owner);
        to.transfer(address(this).balance);
    }
}