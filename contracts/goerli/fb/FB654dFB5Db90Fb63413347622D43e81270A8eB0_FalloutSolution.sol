/**
 *Submitted for verification at Etherscan.io on 2023-03-10
*/

// File: contracts/ethernaut/fallout/FalloutSolution.sol

/**
 *Submitted for verification at Etherscan.io on 2023-03-04
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;



interface IFalloutFuncs {
 
    function Fallout() external payable;
}

contract FalloutSolution {


    IFalloutFuncs falloutsFuncs;

    constructor(IFalloutFuncs contractAddress) {
        falloutsFuncs = IFalloutFuncs(contractAddress);
    }


    function allocateAux() public {
        falloutsFuncs.Fallout();
    }


}