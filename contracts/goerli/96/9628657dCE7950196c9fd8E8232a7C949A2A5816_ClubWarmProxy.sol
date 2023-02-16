/**
 *Submitted for verification at Etherscan.io on 2023-02-16
*/

// SPDX-License-Identifier: MIT

// Specifies the version of Solidity, using semantic versioning.
// Learn more: https://solidity.readthedocs.io/en/v0.5.10/layout-of-source-files.html#pragma
pragma solidity >=0.7.3;

// Wallet : 0xcF8FB44C326A6Cc342648AbF53C63AF73723F6fD
// Token: 0xbca63e82869c9778b842ccbd8e88bbd766b48578

interface WarmInterface {
    function balanceOf(address tokenAddress, address owner)
        external
        view
        returns (uint256);

    function ownerOf(address tokenAddress, uint256 tokenId)
        external
        view
        returns (address);
}

contract ClubWarmProxy {
    address public constant WARM_CONTRACT_ADDRESS =
        0xB2790b357c3a1258efdc68a4fD043FFc137aC26b;

    function getBalance(address tokenAddress, address walletAddress)
        public
        view
        returns (uint256)
    {
        WarmInterface token = WarmInterface(WARM_CONTRACT_ADDRESS);
        return token.balanceOf(tokenAddress, walletAddress);
    }

    function ownerOf(address tokenAddress, uint256 tokenId)
        public
        view
        returns (address)
    {
        WarmInterface token = WarmInterface(WARM_CONTRACT_ADDRESS);
        return token.ownerOf(tokenAddress, tokenId);
    }
}