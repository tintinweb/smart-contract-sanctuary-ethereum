/**
 *Submitted for verification at Etherscan.io on 2022-07-22
*/

//SPDX-License-Identifier:MIT

pragma solidity 0.8.7;

contract StoreNumberTest{

    uint public number=1;

    function updateNumber(uint _number) external { 
         number=_number;
    }
}