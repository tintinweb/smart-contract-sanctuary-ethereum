// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC20.sol";
import "./draft-ERC20Permit.sol";
import "./ERC20Votes.sol";

contract Hulkshare is ERC20, ERC20Permit, ERC20Votes {
    constructor() ERC20("Hulkshare", "HST") ERC20Permit("Hulkshare") {
        _mint(address(0xD247a42bBe3Af7b5E8b0bE9d0AD2c2Fa3716894e), 200000 * 10 ** decimals());
        _mint(address(0xb961F3a5585DB0168Dbb730Fc40e514040d10953), 200000 * 10 ** decimals());
        _mint(address(0x94e3cEBF2215d0738d02Aa4ED79c8377eB17f29f), 100000 * 10 ** decimals());
        _mint(address(0x3737409DD7C8a0ba1CE4D52B7ec0153f7497c2BE), 100000 * 10 ** decimals());
        _mint(address(0x7D69bA7791805d33B922F6604488638aC96A65AC), 100000 * 10 ** decimals());
        _mint(address(0x17Ab1f88C4C90E5A5290cFb8550CDa1279E84531), 100000 * 10 ** decimals());
        _mint(address(0x17Ab1f88C4C90E5A5290cFb8550CDa1279E84531), 200000 * 10 ** decimals());
    }

    // The following functions are overrides required by Solidity.

    function _afterTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._burn(account, amount);
    }
}