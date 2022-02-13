//SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import {
    ERC20Votes,
    ERC20Permit,
    ERC20
} from "./ERC20Votes.sol";

/**
 * ERC20 contract having 18 decimals and total fixed supply of
 * 369 Millions tokens.
 */
contract AlphaNiko is ERC20Votes {

    // Capital of total supply.
    uint256 public immutable Capital;

    // Private pre-sale address
    address public immutable privPreSale;

    // Public pre-sale address
    address public immutable pubPreSale;

    // Marketing funds address.
    address public immutable marketing;

    // Development Team funds address.
    address public immutable DevTeam;

    // Locked funds address.
    address public immutable lockedLiquidity;

    address public immutable lockedCommunityTreasury;

    /// Initialises contract's state and mints 369 Millions tokens.
    constructor()
        ERC20Permit("Alpha Niko")
        ERC20("Alpha Niko", "NIKO")
    {
        Capital = 369_000_000 * (10 ** decimals());

        privPreSale = 0x72443EF9f3Fea196B482B920EA3F852d89BB2d6B;
        pubPreSale = 0xA40b90A441Bb2b049Edbb15c554b4039296cbCf8;
        marketing = 0xDaf2e01fFcd81A690C78aB0D37349EE1369BD8fd;
        DevTeam = 0x768495198685755A6F3f126089731CaCe0d0F887;
        lockedLiquidity = 0x8BCA2997fD17953764dDAAD39a412C8FD34c7b89;
        lockedCommunityTreasury = 0x49c84E370F5878e2Cc9612E43f299aDC9Ef4B49b;

        _mint(privPreSale, Capital * 5 / 100); // 18.450.000
        _mint(pubPreSale, Capital * 10 / 100);   // 36.900.000
        _mint(marketing, Capital * 25 / 100);   // 92.250.000
        _mint(DevTeam, Capital * 10 / 100);     // 36.900.000
        _mint(lockedLiquidity, Capital * 15 / 100); //55.350.000
        _mint(lockedCommunityTreasury, Capital * 35 / 100);  //129.150.000

        assert(totalSupply() == Capital);
    }
}