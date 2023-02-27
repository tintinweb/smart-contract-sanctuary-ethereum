// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./IERC677Receiver.sol";
import "./IFrankencoin.sol";

/**
 * A minting contract for another CHF stablecoin that we trust.
 */
contract StablecoinBridge {

    IERC20 public immutable chf;
    IFrankencoin public immutable zchf;

    uint256 public immutable horizon;
    uint256 public immutable limit;

    constructor(address other, address zchfAddress, uint256 limit_){
        chf = IERC20(other);
        zchf = IFrankencoin(zchfAddress);
        horizon = block.timestamp + 52 weeks;
        limit = limit_;
    }

    function mint(uint256 amount) external {
        mint(msg.sender, amount);
    }

    function mint(address target, uint256 amount) public {
        chf.transferFrom(msg.sender, address(this), amount);
        mintInternal(target, amount);
    }

    function mintInternal(address target, uint256 amount) internal {
        require(block.timestamp <= horizon, "expired");
        require(chf.balanceOf(address(this)) <= limit, "limit");
        zchf.mint(target, amount);
    }
    
    function burn(uint256 amount) external {
        burnInternal(msg.sender, msg.sender, amount);
    }

    function burn(address target, uint256 amount) external {
        burnInternal(msg.sender, target, amount);
    }

    function burnInternal(address zchfHolder, address target, uint256 amount) internal {
        zchf.burn(zchfHolder, amount);
        chf.transfer(target, amount);
    }

    function onTokenTransfer(address from, uint256 amount, bytes calldata) external returns (bool){
        if (msg.sender == address(chf)){
            mintInternal(from, amount);
        } else if (msg.sender == address(zchf)){
            burnInternal(address(this), from, amount);
        } else {
            require(false, "unsupported token");
        }
        return true;
    }
    
}