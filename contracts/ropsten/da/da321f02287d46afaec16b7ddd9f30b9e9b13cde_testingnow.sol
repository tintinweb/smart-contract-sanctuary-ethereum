// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ownable.sol";


contract testingnow is Ownable {
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
    
    function withdraw() public onlyOwner {
        msg.sender.call{ value:address(this).balance }("");
    }

    function changefee(uint _fee) public onlyOwner {
        fee = _fee;
    }
    
    function freewrite(string memory _message) public {
        message = _message;
    }

    function payablewrite(string memory _message) public payable {
        require(msg.value == fee);
        message = _message;
    }
}