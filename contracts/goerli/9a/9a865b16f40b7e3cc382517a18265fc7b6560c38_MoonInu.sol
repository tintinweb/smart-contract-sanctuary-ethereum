// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ERC20Upgradeable.sol";

import "./Initializable.sol";
import "./UUPSUpgradeable.sol";

contract MoonInu is  Initializable, ERC20Upgradeable, UUPSUpgradeable {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() initializer public {
        __ERC20_init("Moon Inu", "$MOON");
        __Ownable_init();
        __UUPSUpgradeable_init();

        _mint(msg.sender, 100000000000 * 10 ** decimals());
    }
  function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}
  
}