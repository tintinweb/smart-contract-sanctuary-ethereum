/**
 *Submitted for verification at Etherscan.io on 2022-07-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Created by: 0xInuarashi.eth

abstract contract Ownable {
    address public owner; 
    constructor() { owner = msg.sender; }
    modifier onlyOwner { require(owner == msg.sender, "Not Owner!"); _; }
    function transferOwnership(address new_) external onlyOwner { owner = new_; }
}

interface iZenToken {
    function burnAsController(address from_, uint256 amount_) external;
}

interface IERC20Burnable { 
    function transferFrom(address from_, address to_, uint256 amount_) external;
    function approve(address spender_, uint256 amount_) external;
    function burn(uint256 amount_) external;
    function balanceOf(address wallet_) external view returns (uint256);
}

contract zenApeTokenAccessControlBasic is Ownable {

    iZenToken public ZenToken = iZenToken(0x0591c71E88a74E612aE1759ABc938973421Ba027);
    IERC20Burnable public Banana = 
        IERC20Burnable(0x94e496474F1725f1c1824cB5BDb92d7691A4F03a);

    uint256 public featurePrice = 10 ether;
    uint256 public bananaFeaturePrice = 1 ether;

    mapping(address => bool) public featureEnabledForAddress;  

    function changeFeaturePrice(uint256 price_) external onlyOwner {
        featurePrice = price_;
    }
    function changeBananaFeaturePrice(uint256 price_) external onlyOwner {
        bananaFeaturePrice = price_;
    }

    function ownerSetFeatureToAddress(address address_, bool bool_) external onlyOwner {
        featureEnabledForAddress[address_] = bool_;
    }

    function enableFeature(uint256 tokenType_) external {
        require(!featureEnabledForAddress[msg.sender],
            "You already have this feature enabled!");

        if (tokenType_ == 1) {
            ZenToken.burnAsController(msg.sender, featurePrice);
        }

        else if (tokenType_ == 2) {
            Banana.transferFrom(msg.sender, address(this), bananaFeaturePrice);
            Banana.burn(Banana.balanceOf(address(this)));
        }

        else { revert("Invalid token type!"); }
        
        featureEnabledForAddress[msg.sender] = true;
    }
}