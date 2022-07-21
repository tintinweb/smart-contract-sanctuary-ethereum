// SPDX-License-Identifier: MIT

/// @author Jourdan Dunkley

pragma solidity ^0.8.14;

import "./ERC20.sol";
import "./Owned.sol";

contract Space is ERC20, Owned {

    constructor() ERC20("Space", "Space", 18) Owned(msg.sender) {}

    /// @notice Allows owner to mint a particular amount of $Space.
    /// @param account The account to mint the $Space to.
    /// @param amount The amount of $Space that will be minted.
    function rewardMint(address account, uint256 amount) external onlyOwner {
        _mint(account, amount);
    }

    /// @notice Allows a user to burn his/her $Space.
    /// @param user The user trying to burn $Space.
    /// @param amount The amount of $Space the user would like to burn.
    function burn(address user, uint256 amount) external onlyOwner {
        _burn(user, amount);
    }
}