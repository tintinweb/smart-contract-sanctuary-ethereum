/**
 *Submitted for verification at Etherscan.io on 2022-11-23
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.25 <0.9.0;

contract DoubleMyContract {
    uint256 public balance; //State variable
    uint256 public balance1; //State variable

    // call this function to send a response
    function doubleMyContract(uint256 _amount) public {
        balance = _amount * 3;
        balance1 += 50;
    }

    // call this function to send a response
    function sendMeMoneyContract() public payable {}
}