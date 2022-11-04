/**
 *Submitted for verification at Etherscan.io on 2022-11-04
*/

//SPDX-License-Identifier:MIT

pragma solidity 0.8.16;

contract smartWallet{
    mapping(address =>uint)public balance;
    constructor(){
        balance[msg.sender]=100;
    }
    function transfer(address _to, uint _amount)public{
        balance[msg.sender]-=_amount;
        balance[_to]+=_amount;

    }
    function someCrypticFunction(address _addr) public {
balance[_addr]=5;
    }

}