//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC4626.sol";
import "./IERC20.sol";
import "./ERC20.sol";

contract SemiVault is IERC4626, ERC20 {

    ERC20 public immutable asset;

    mapping(address => uint256) shareHolder;


    event Deposit(address caller, uint256 amt);
    event Withdraw(address caller, address receiver, uint256 amt, uint256 shares);

    constructor(ERC20 _underlying, string memory _name, string memory _symbol )
     ERC20(_name, _symbol, 18) {
        asset = _underlying;
    }

    // a deposit function that receives assets from users
    function deposit(uint256 assets) public{
        require (assets > 0, "Deposit less than Zero");

        asset.transferFrom(msg.sender, address(this), assets);
        shareHolder[msg.sender] += assets;
        _mint(msg.sender, assets);

        emit Deposit(msg.sender, assets);

    }

    function totalAssets() public view override returns(uint256) {
        return asset.balanceOf(address(this));
    } 

    function redeem(uint256 shares, address receiver ) internal returns (uint256 assets) {
        require(shareHolder[msg.sender] > 0, "Not a share holder");
        shareHolder[msg.sender] -= shares;

        uint256 per = (10 * shares) / 100;

        _burn(msg.sender, shares);

        assets = shares + per;

        emit Withdraw(receiver, receiver, assets, per);
        return assets;
    }

    function withdraw(uint256 shares, address receiver) public {
        uint256 payout = redeem(shares, receiver);
        asset.transfer(receiver, payout);
    }

}