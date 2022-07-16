/**
 *Submitted for verification at Etherscan.io on 2022-07-16
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


contract Payer {
    uint public Counter; 
    function IncCounter(address rec) public returns(bool) {
        Counter++;
        (bool success,) = payable(Receiver(payable(rec))).call{value: 10}("");
        return success;
    }
    function getBalance() public view returns(uint) {
        return address(this).balance;
    }
    receive() external payable {
    }

}

contract Receiver {
    function getBalance() public view returns(uint) {
        return address(this).balance;
    }
    fallback() external payable {

    }
}