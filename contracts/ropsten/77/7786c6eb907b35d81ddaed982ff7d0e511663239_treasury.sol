/**
 *Submitted for verification at Etherscan.io on 2022-04-03
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
contract treasury{
    address  public Gov;
    constructor(address _gov) payable {
        Gov = _gov;
    }
    function withdraw(address _to, uint amount)  external returns(bool success){
        require(msg.sender == Gov, "only Gov can withdraw");
        require(amount <= address(this).balance, "poor");
        (success, ) = _to.call{value: amount}(new bytes(0));
        require(success, 'STE');
    }
}