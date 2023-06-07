// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./AggregatorV3Interface.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";

contract Presale is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;
    
    IERC20 public token;
    IERC20 public USDC = IERC20(0xda9d4f9b69ac6C22e444eD9aF0CfC043b7a7f53f);  // USDT Sepolia Address
    IERC20 public WETH = IERC20(0x694AA1769357215DE4FAC081bf1f309aDC325306);  // WETH Sepolia Address
    AggregatorV3Interface internal priceFeed;
    address payable private ownerAddress;

    uint256 public stage;
    mapping(uint => uint256) public rate;
    mapping(address => uint256) public tokensPurchased;

    bool public canClaimTokens = false;

    constructor(address _priceFeed) {
        priceFeed = AggregatorV3Interface(_priceFeed);
        ownerAddress = payable(msg.sender);  // Save the address of the deployer

        // Set initial stage
        stage = 1;

        // Set rates for each stage
        rate[1] = 1000; // 1 token per 0.001 USDT
        rate[2] = 500;  // 1 token per 0.002 USDT
        rate[3] = 333;  // 1 token per 0.003 USDT
        // ... set rates for remaining stages up to 10
    }

    function buyTokensWithUSDC(uint256 _amount) external nonReentrant {
        require(stage <= 10, "Presale ended");
        uint256 tokens = _amount / rate[stage];
        USDC.safeTransferFrom(msg.sender, ownerAddress, _amount);  // USDT transferred to the deployer
        tokensPurchased[msg.sender] += tokens;
    }

    function buyTokensWithWETH(uint256 _amount) external nonReentrant {
        require(stage <= 10, "Presale ended");
        int latestPrice = getCurrentWETHPrice();
        require(latestPrice > 0, "Invalid WETH price");
        uint256 tokens = _amount * uint256(latestPrice) / rate[stage];
        WETH.safeTransferFrom(msg.sender, ownerAddress, _amount);  // WETH transferred to the deployer
        tokensPurchased[msg.sender] += tokens;
    }

    function claimTokens() external nonReentrant {
        require(canClaimTokens, "Tokens are not yet claimable");
        uint256 amount = tokensPurchased[msg.sender];
        require(amount > 0, "No tokens to claim");
        tokensPurchased[msg.sender] = 0;
        token.safeTransfer(msg.sender, amount);
    }

    function setClaimable(bool _canClaimTokens) external onlyOwner {
        canClaimTokens = _canClaimTokens;
    }

    function setStage(uint256 _stage) external onlyOwner {
        require(_stage <= 10, "Invalid stage");
        stage = _stage;
    }

    function setTokenAddress(IERC20 _token) external onlyOwner {
        token = _token;
    }

    function getCurrentWETHPrice() public view returns (int) {
        (
            , 
            int price,
            ,
            ,
        ) = priceFeed.latestRoundData();
        return price;
    }

    function withdraw() external onlyOwner {
        uint256 tokenBalance = token.balanceOf(address(this));
        uint256 USDCBalance = USDC.balanceOf(address(this));
        uint256 WETHBalance = WETH.balanceOf(address(this));
        if (tokenBalance > 0) {
            token.safeTransfer(ownerAddress, tokenBalance);
        }
        if (USDCBalance > 0) {
            USDC.safeTransfer(ownerAddress, USDCBalance);
        }
        if (WETHBalance > 0) {
            WETH.safeTransfer(ownerAddress, WETHBalance);
        }
    }
}