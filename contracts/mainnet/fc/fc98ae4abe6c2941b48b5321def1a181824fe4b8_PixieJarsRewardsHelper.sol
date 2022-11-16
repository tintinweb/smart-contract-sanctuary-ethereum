// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;


abstract contract PixieJars { 
    function balanceOf(address owner) public view virtual returns (uint256);
}

contract PixieJarsRewardsHelper {
    PixieJars pixieJars;
    PixieJars stakedJars;

    constructor(address _pixieJars, address _stakedJars) {
        pixieJars = PixieJars(_pixieJars);
        stakedJars = PixieJars(_stakedJars);
    }

    function balanceOf(address owner) public view returns (uint256) {
       return (pixieJars.balanceOf(owner) + stakedJars.balanceOf(owner));
    }
}