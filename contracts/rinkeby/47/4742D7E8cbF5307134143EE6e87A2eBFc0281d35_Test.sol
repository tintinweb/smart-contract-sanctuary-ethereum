/**
 *Submitted for verification at Etherscan.io on 2022-02-09
*/

pragma solidity ^0.8.4;

contract Test {
    uint256 public x;
    event R();
    event F();

    receive() external payable {
        x = 10;
        emit R();
    }

    fallback() external payable {
        x = 20;
        emit F();
    }
}