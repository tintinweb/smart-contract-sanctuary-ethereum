/**
 *Submitted for verification at Etherscan.io on 2022-04-14
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract Test {
    bool private pause = true;
    address private owner;

    constructor() {
        owner = msg.sender;
    }

    function mint() external view {
        require(!pause, "not begin");
    }

    function setPause() external {
        require(tx.origin == owner, "not permission");

        pause = !pause;
    }
}