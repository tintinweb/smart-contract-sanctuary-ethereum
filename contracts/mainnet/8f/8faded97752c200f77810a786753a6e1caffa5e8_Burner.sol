/**
 *Submitted for verification at Etherscan.io on 2022-08-03
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface ITmls {
    function burn(uint256) external;
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

contract Burner {
    ITmls public timelessMfer;
    constructor () {
        timelessMfer = ITmls(0xabf8039Db2e751e60C1b45b58F381F569a413bF8);

    }

    function doBurns(uint16[] calldata ids) public returns (bool) {
        uint256 len = ids.length;

        for (uint256 i; i < len;) {
            timelessMfer.transferFrom(msg.sender, address(this), ids[i]);
            timelessMfer.burn(ids[i]);  
            unchecked {++i;}
        }

        return true;
    }
}