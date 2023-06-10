/**
 *Submitted for verification at Etherscan.io on 2023-06-10
*/

//SPDX-License-Identifier : MIT

pragma solidity ^0.8.0;

contract SendEther{
    constructor () payable {}

    receive () external payable {} 
    uint256  public amount ;

    function sendViaTransfer (address payable _to) external   payable    {
            _to.transfer(123);
    }
    
    function sendViaSend (address payable _to) external  payable {
        bool send =  _to.send(123);
        require (send , "Send fail");
    }

    function sendViaCall ( address payable  _to) external   payable {
        (bool success , )= _to.call{value: 123 }("");
        require(success ,  " Send fail");
    }

    function setAmount( uint256 _amount ) public {
        amount = _amount ; 
    }

    function fundContract () external payable {
        require (msg.value == amount, "Fund fail !");
    }
}

contract EthReciver {
    event Log( uint amount , uint gas);
    receive () external payable {
        emit Log (msg.value, gasleft() );
    }
}