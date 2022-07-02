/**
 *Submitted for verification at Etherscan.io on 2022-07-02
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;


contract Event{

    event perform(address indexed _from,string _operation);

    function performfun(uint _a,uint _b)public returns(uint _sum){
        _sum=_a+_b;
    
        emit perform(msg.sender,'Addition');
        return _sum;
    }

}