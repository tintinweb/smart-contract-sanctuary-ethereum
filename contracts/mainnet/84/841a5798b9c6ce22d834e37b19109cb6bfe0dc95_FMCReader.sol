/**
 *Submitted for verification at Etherscan.io on 2022-09-09
*/

// SPDX-License-Identifier: MIT

/**
* Author: Lambdalf the White
*/

pragma solidity 0.8.10;

abstract contract FMC {
    function balanceOf( address owner, uint256 id ) external virtual view returns ( uint256 );
}

contract FMCReader {
    FMC public immutable fmc;

    constructor( address fmc_ ) {
        fmc = FMC( fmc_ );
    }

    function balanceOf( address tokenOwner_ ) public view returns ( uint256 ) {
        return fmc.balanceOf( tokenOwner_, 1 );
    }
}