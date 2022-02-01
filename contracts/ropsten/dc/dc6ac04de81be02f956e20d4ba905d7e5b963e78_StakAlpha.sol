// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AlphaToken.sol";

// StakAlpha is the coolest pit in town. You come in with some Alpha, and leave with more! The longer you stay, the more Alpha you get.
//
// This contract handles swapping to and from xAlpha, EdenSwap's staking token.
contract StakAlpha is ERC20("tAlpha Staked Alpha EdenSwap", "tAlpha"){
    using SafeMath for uint256;

    IERC20 public immutable Alpha;

    // Define the Alpha token contract
    constructor(IERC20 _Alpha) {
        require(address(_Alpha) != address(0), "_Alpha is a zero address");
        Alpha = _Alpha;
    }

    // Enter the Edenhouse. Pay some Alphas. Earn some shares.
    // Locks Alpha and mints tAlpha
    function enter(uint256 _amount) public {
        // Gets the amount of Alpha locked in the contract
        uint256 totalAlpha = Alpha.balanceOf(address(this));
        // Gets the amount of tAlpha in existence
        uint256 totalShares = totalSupply();
        // If no tAlpha exists, mint it 1:1 to the amount put in
        if (totalShares == 0 || totalAlpha == 0) {
            _mint(msg.sender, _amount);
        } 
        // Calculate and mint the amount of tAlpha the Alpha is worth. The ratio will change overtime, as tAlpha is burned/minted and Alpha deposited + gained from fees / withdrawn.
        else {
            uint256 what = _amount.mul(totalShares).div(totalAlpha);
            _mint(msg.sender, what);
        }
        // Lock the Alpha in the contract
        Alpha.transferFrom(msg.sender, address(this), _amount);
    }

    // Leave the doghouse. Claim back your Alphas.
    // Unclocks the staked + gained Alpha and burns tAlpha
    function leave(uint256 _share) public {
        // Gets the amount of xAlpha in existence
        uint256 totalShares = totalSupply();

        // Calculates the amount of Alpha the xAlpha is worth
        uint256 what = _share.mul(Alpha.balanceOf(address(this))).div(totalShares);
        _burn(msg.sender, _share);
        Alpha.transfer(msg.sender, what);
    }
}