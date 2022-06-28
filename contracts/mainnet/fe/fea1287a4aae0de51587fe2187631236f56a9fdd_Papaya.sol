// SPDX-License-Identifier: MIT

/***   
  _____                     _                __   _   _             _____                _ _                      
 |  __ \                   | |              / _| | | | |           / ____|              (_) |                     
 | |__) |_ _ _ __ _ __ ___ | |_ ___    ___ | |_  | |_| |__   ___  | |     __ _ _ __ _ __ _| |__   ___  __ _ _ __  
 |  ___/ _` | '__| '__/ _ \| __/ __|  / _ \|  _| | __| '_ \ / _ \ | |    / _` | '__| '__| | '_ \ / _ \/ _` | '_ \ 
 | |  | (_| | |  | | | (_) | |_\__ \ | (_) | |   | |_| | | |  __/ | |___| (_| | |  | |  | | |_) |  __/ (_| | | | |
 |_|   \__,_|_|  |_|  \___/ \__|___/  \___/|_|    \__|_| |_|\___|  \_____\__,_|_|  |_|  |_|_.__/ \___|\__,_|_| |_|                                                                                                                                                                                                            
*/

/// @title Parrots of the Caribbean $PAPAYA Token
/// @author jackparrot

pragma solidity ^0.8.14;

import "./ERC20.sol";
import "./Owned.sol";

/// @notice Thrown if a user tries to burn $PAPAYA he/she does not own.
error NotYourPapaya();
/// @notice Thrown if an invalid staking contract or user tries to mint $PAPAYA. 
error InvalidMinter();

contract Papaya is ERC20, Owned {
    /// @notice Staking Contracts authorized to mint $PAPAYA.
    mapping(address => bool) private authorizedStakingContracts;

    constructor() ERC20("PAPAYA", "PAPAYA", 18) Owned(msg.sender) {}

    /// @notice Allows owner to mint a particular amount of $PAPAYA.
    /// @param account The account to mint the $PAPAYA to.
    /// @param amount The amount of $PAPAYA that will be minted.
    function ownerMint(address account, uint256 amount) external onlyOwner {
        _mint(account, amount);
    }

    /// @notice Minting function called by staking contract.
    /// @dev This is called when the user is claiming his/her reward from staking their parrot.
    /// @param account The user claiming staking rewards.
    /// @param amount The amount of reward that will be paid out to the user.
    function stakerMint(address account, uint256 amount) external {
        if (!authorizedStakingContracts[msg.sender]) revert InvalidMinter();
        _mint(account, amount);
    }

    /// @notice Allows a staking contract to mint $PAPAYA.
    /// @param staker The staking contract's address
    function flipStakingContract(address staker) external onlyOwner {
        authorizedStakingContracts[staker] = !authorizedStakingContracts[staker];
    }

    /// @notice Allows a user to burn his/her $PAPAYA.
    /// @param user The user trying to burn $PAPAYA.
    /// @param amount The amount of $PAPAYA the user would like to burn.
    function burn(address user, uint256 amount) external {
        if (user != msg.sender) revert NotYourPapaya();
        _burn(user, amount);
    }
}