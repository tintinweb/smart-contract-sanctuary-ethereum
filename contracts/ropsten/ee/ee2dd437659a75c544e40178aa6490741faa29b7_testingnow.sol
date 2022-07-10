/**
 *Submitted for verification at Etherscan.io on 2022-07-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;


contract testingnow{
    //0.1
    uint fee = 0.1 ether;
    string message = "ho";

    function read() public view returns(string memory) {
        return message;
    }

    function balance() public view returns(uint) {
        return address(this).balance;
    }

    function checkfee() public view returns(uint) {
        return fee;
    }
    
    function withdraw() public {
        msg.sender.call{ value:address(this).balance }("");
    }

    function changefee(uint _fee) public {
        fee = _fee;
    }
    
    function write(string memory _message) public payable {
        require(msg.value == fee);
        message = _message;
    }
}