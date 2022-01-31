/**
 *Submitted for verification at Etherscan.io on 2022-01-31
*/

pragma solidity ^0.8.4;

contract C {

    fallback() external payable {
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
}