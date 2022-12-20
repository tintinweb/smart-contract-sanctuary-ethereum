/**
 *Submitted for verification at Etherscan.io on 2022-12-20
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

interface Contract {
    function attempt() external;
}

contract auwinner {
    address public c = 0xcF469d3BEB3Fc24cEe979eFf83BE33ed50988502;

    function winner() external {
        Contract(c).attempt();
    }
}