/**
 *Submitted for verification at Etherscan.io on 2022-05-18
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
contract coin{
    address public minter;
    mapping (address => uint)public balances;
    constructor(){
        minter =msg.sender;
    }
    function mint (address reciver ,uint amount)public{
        require(msg.sender == minter);
        require (amount <1000);
        balances[reciver]+=amount;
    }
    function send(address reciver,uint amount)public{
        require(amount <= balances[msg.sender],"insuffcent blances");
        balances[msg.sender]-=amount;
        balances[reciver]+=amount;
    }
}