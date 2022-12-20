/**
 *Submitted for verification at Etherscan.io on 2022-12-20
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IContract {
    function attempt() external;
}

contract Interact {
    address attemptAddress = 0xa1FaAD6A98D395b847b97fb93aeE0e8e7554424e;

    function interact() external {
        IContract(attemptAddress).attempt();
    }
}