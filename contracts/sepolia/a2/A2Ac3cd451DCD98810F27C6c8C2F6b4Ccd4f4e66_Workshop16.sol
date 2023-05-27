/**
 *Submitted for verification at Etherscan.io on 2023-05-26
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

interface workshop12 {
    function getInterest(address _account_address) external view returns (uint);
    function update(address _account_address, uint _balances) external;
}

contract Workshop16 {
    workshop12 anotherContract = workshop12 (0x072FfA7B9b80b66Ae190a25B95b8a74c44AD1810);

    function getTax(address  a) public view returns (uint) {
        return anotherContract.getInterest(a) * 10 / 100;
    }
}