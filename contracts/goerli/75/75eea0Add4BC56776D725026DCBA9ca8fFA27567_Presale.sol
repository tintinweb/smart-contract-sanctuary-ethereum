// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IERC20.sol";
import "./SafeERC20.sol";

contract Presale {
    using SafeERC20 for IERC20;

    IERC20 public usdt;
    IERC20 public token;
    uint256 public rate;
    uint256 public stage;
    bool public claimingStarted = false;
    address public owner;
    mapping(uint => uint256) public ratePerStage;
    mapping(address => uint256) public balanceOf;

    modifier onlyOwner {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    constructor(IERC20 _usdt) {
        usdt = _usdt;
        owner = msg.sender;
        stage = 1;
        ratePerStage[1] = 1000;
        ratePerStage[2] = 900;
        ratePerStage[3] = 800;
        rate = ratePerStage[stage];
    }

    function buyTokens(uint256 usdtAmount) external {
        require(!claimingStarted, "Claiming has started, cannot buy more tokens");
        require(usdtAmount > 0, "Cannot buy with 0 amount");
        require(usdt.balanceOf(msg.sender) >= usdtAmount, "Not enough USDT balance");
        uint256 tokenAmount = usdtAmount * rate;
        require(token.balanceOf(address(this)) >= tokenAmount, "Not enough tokens in contract");

        usdt.safeTransferFrom(msg.sender, address(this), usdtAmount);
        balanceOf[msg.sender] += tokenAmount;
    }

    function claimTokens() external {
        require(claimingStarted, "Claiming has not started yet");
        uint256 tokenAmount = balanceOf[msg.sender];
        require(tokenAmount > 0, "No tokens to claim");
        require(token.balanceOf(address(this)) >= tokenAmount, "Not enough tokens in contract");

        balanceOf[msg.sender] = 0;
        token.safeTransfer(msg.sender, tokenAmount);
    }

    function startClaiming() external onlyOwner {
        claimingStarted = true;
    }

    function advanceStage() external onlyOwner {
        if(stage < 3) {
            stage += 1;
            rate = ratePerStage[stage];
        }
    }

    function setToken(IERC20 _token) external onlyOwner {
        token = _token;
    }
}