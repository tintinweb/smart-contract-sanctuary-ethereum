// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./IERC20.sol";
import "./ERC20.sol";
import "./SafeMath.sol";

// BuryLeash is the coolest pit in town. You come in with some Leash, and leave with more! The longer you stay, the more Leash you get.
//
// This contract handles swapping to and from xLeash.
contract BuryLeash is ERC20("xLeash Staked Leash", "xLEASH"){
    using SafeMath for uint256;

    IERC20 public immutable LEASH;

    // Define the Leash token contract
    constructor(IERC20 _LEASH) public {
        require(address(_LEASH) != address(0), "_LEASH is a zero address");
        LEASH = _LEASH;
    }

    // Enter the doghouse. Pay some LEASHs. Earn some shares.
    // Locks Leash and mints xLeash
    function enter(uint256 _amount) public {
        // Gets the amount of Leash locked in the contract
        uint256 totalLeash = LEASH.balanceOf(address(this));
        // Gets the amount of xLeash in existence
        uint256 totalShares = totalSupply();
        // If no xLeash exists, mint it 1:1 to the amount put in
        if (totalShares == 0 || totalLeash == 0) {
            _mint(msg.sender, _amount);
        } 
        // Calculate and mint the amount of xLeash the Leash is worth. The ratio will change overtime, as xLeash is burned/minted and Leash deposited + gained from fees / withdrawn.
        else {
            uint256 what = _amount.mul(totalShares).div(totalLeash);
            _mint(msg.sender, what);
        }
        // Lock the Leash in the contract
        LEASH.transferFrom(msg.sender, address(this), _amount);
    }

    // Leave the doghouse. Claim back your LEASHs.
    // Unclocks the staked + gained Leash and burns xLeash
    function leave(uint256 _share) public {
        // Gets the amount of xLeash in existence
        uint256 totalShares = totalSupply();

        // Calculates the amount of Leash the xLeash is worth
        uint256 what = _share.mul(LEASH.balanceOf(address(this))).div(totalShares);
        _burn(msg.sender, _share);
        LEASH.transfer(msg.sender, what);
    }
}