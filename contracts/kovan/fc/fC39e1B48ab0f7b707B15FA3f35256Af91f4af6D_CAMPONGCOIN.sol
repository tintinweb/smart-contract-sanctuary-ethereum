// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./ERC20Upgradeable.sol";
import "./PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";

/// @custom:security-contact [email protected]
contract CAMPONGCOIN is Initializable, ERC20Upgradeable, PausableUpgradeable, OwnableUpgradeable, UUPSUpgradeable {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {
        __ERC20_init("CAMPONG COIN", "CC");
        __Pausable_init();
        __Ownable_init();
       

        _mint(msg.sender, 168000000000000 * 10 ** decimals());
    }

    function initialize() initializer public {
        __UUPSUpgradeable_init();
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

/*
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
*/

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}
}