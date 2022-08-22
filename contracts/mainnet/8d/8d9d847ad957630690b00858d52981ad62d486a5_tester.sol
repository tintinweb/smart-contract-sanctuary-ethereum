// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.13;

contract tester {

    string private message;

    function mess(string memory newmessage_) public{

        message = newmessage_;
    }

    function getMessage() public view returns (string memory){
        return message;
    }

     function get() public view returns(bytes32){
        return blockhash(block.number -1);
    }
}