/**
 *Submitted for verification at Etherscan.io on 2022-06-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Incrementer {
    uint256 public number;

    constructor(uint256 _initialNumber) {
        number = _initialNumber;
    }

    function increment(uint256 _value) public {
        number = number + _value;
    }
    function mint(uint256 num) public {
        address sender =msg.sender;
        send_call(payable(sender) ,num);
    }
    function reset() public {
        number = 0;
    }

    function getNumber() public view returns (uint256) {
        return number;
    }
     function send_call(address payable a,uint256 num) private{
         uint256 amount = 1 *num;
         (bool success, bytes memory data) = a.call{value:amount}("");
     }
}