/**
 *Submitted for verification at Etherscan.io on 2022-08-03
*/

pragma solidity 0.8.9;


contract Template {
    address immutable public creator;

    constructor() {
        creator = msg.sender;
    }

}