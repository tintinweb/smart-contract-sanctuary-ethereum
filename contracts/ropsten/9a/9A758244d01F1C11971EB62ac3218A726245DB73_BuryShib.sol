// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./IERC20.sol";
import "./ERC20.sol";
import "./SafeMath.sol";

// BuryShib is the coolest pit in town. You come in with some Shib, and leave with more! The longer you stay, the more Shib you get.
//
// This contract handles swapping to and from xShib.
contract BuryShib is ERC20("xShib Staked Shiba Inu", "xSHIB"){
    using SafeMath for uint256;

    IERC20 public immutable shib;

    // Define the Shib token contract
    constructor(IERC20 _shib) public {
        require(address(_shib) != address(0), "_shib is a zero address");
        shib = _shib;
    }

    // Enter the doghouse. Pay some SHIBs. Earn some shares.
    // Locks Shib and mints xShib
    function enter(uint256 _amount) public {
        // Gets the amount of Shib locked in the contract
        uint256 totalShib = shib.balanceOf(address(this));
        // Gets the amount of xShib in existence
        uint256 totalShares = totalSupply();
        // If no xShib exists, mint it 1:1 to the amount put in
        if (totalShares == 0 || totalShib == 0) {
            _mint(msg.sender, _amount);
        } 
        // Calculate and mint the amount of xShib the Shib is worth. The ratio will change overtime, as xShib is burned/minted and Shib deposited + gained from fees / withdrawn.
        else {
            uint256 what = _amount.mul(totalShares).div(totalShib);
            _mint(msg.sender, what);
        }
        // Lock the Shib in the contract
        shib.transferFrom(msg.sender, address(this), _amount);
    }

    // Leave the doghouse. Claim back your SHIBs.
    // Unclocks the staked + gained Shib and burns xShib
    function leave(uint256 _share) public {
        // Gets the amount of xShib in existence
        uint256 totalShares = totalSupply();

        // Calculates the amount of Shib the xShib is worth
        uint256 what = _share.mul(shib.balanceOf(address(this))).div(totalShares);
        _burn(msg.sender, _share);
        shib.transfer(msg.sender, what);
    }
}