/**
 *Submitted for verification at Etherscan.io on 2022-05-12
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract token {

    address landlord = 0xA79352975EA080aA52c4F8d221Cc6fB5c9bEf8cC;
    address tenent = 0xb9158f55d2CCf5f77A87d58B47B113e95655Fb4C;

    function Pay(uint value) public {
        payable(landlord).transfer(value);
    } 
}