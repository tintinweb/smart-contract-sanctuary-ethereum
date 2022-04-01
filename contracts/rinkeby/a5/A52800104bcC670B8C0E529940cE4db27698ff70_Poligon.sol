/**
 *Submitted for verification at Etherscan.io on 2022-03-31
*/

//SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;
contract Poligon{
    uint public count = 0;
    function increment() public returns(uint){
        count +=1;
        return count;
    }
}