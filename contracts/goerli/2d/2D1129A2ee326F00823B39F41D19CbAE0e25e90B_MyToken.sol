// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "ERC20Upgradeable.sol";
import "OwnableUpgradeable.sol";
import "Initializable.sol";
import "UUPSUpgradeable.sol";

contract MyToken is Initializable, ERC20Upgradeable, OwnableUpgradeable, UUPSUpgradeable {
    /// @custom:oz-upgrades-unsafe-allow constructor

    function initialize() initializer public {
        __ERC20_init("MyToken", "MTK");
        __Ownable_init();
        __UUPSUpgradeable_init();

        _mint(msg.sender, 200 * 10 ** decimals());
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}
}