/**
 *Submitted for verification at Etherscan.io on 2023-03-02
*/

pragma solidity ^0.8.7;

contract SimpleToken {
    address public owner;

    constructor(address _owner) {
        owner = _owner;
    }
}