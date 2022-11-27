/**
 *Submitted for verification at Etherscan.io on 2022-11-27
*/

pragma solidity 0.8.17;

contract TestA {
    address owner;

    constructor() {
        owner = msg.sender;
    }

    function isAuthorized() public view returns (bool) {
        if (owner == msg.sender) {
            return true;
        } else {
            return false;
        }
    }
}