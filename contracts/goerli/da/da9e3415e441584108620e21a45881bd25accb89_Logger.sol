/**
 *Submitted for verification at Etherscan.io on 2022-11-02
*/

//SPDX-License-Identifier:MIT
pragma solidity ^0.8.17;

contract Logger{
    event nftlogged(
        address sender,
        string status,
        uint256 num
    );

    function AddNft() public {
        emit nftlogged(msg.sender,"yes",2);
    }
}