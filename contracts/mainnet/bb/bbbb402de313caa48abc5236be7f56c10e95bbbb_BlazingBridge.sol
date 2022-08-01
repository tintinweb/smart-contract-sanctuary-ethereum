/**
 *Submitted for verification at Etherscan.io on 2022-08-01
*/

/*  
BlazingBridge

Created, deployed, run, managed and maintained by CodeCraftrs
https://codecraftrs.com
*/

// Code written by MrGreenCrypto
// SPDX-License-Identifier: None

pragma solidity 0.8.15;

interface IBEP20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
}

interface IRouter {
    function WETH() external pure returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline) external;
}

contract BlazingBridge {
    address private constant BRIDGE = 0x78051f622c502801fdECc56d544cDa87065Acb76;
    address private constant CC = 0xc0de2d009aa6b2F37469902D860fa64ca4DCc0DE;
    address private constant CEO = 0x7c4ad2B72bA1bDB68387E0AE3496F49561b45625;
    mapping (string => bool) public bridgingCompleted;
    mapping (address => uint256) public feeInPerMille;
    mapping (address => uint256) public minFee;
    mapping (address => uint256) public maxFee;
    mapping (address => address) private routerAddress;
    mapping (address => uint256) private swapAtAmount;
    mapping (address => uint256) private feesCollected;
    uint256 public myChain;

    modifier onlyBridge() {
        if(msg.sender != BRIDGE) return;
         _;
    }
    
    modifier onlyOwner() {
        if(msg.sender != CEO) return;
         _;
    }

    event BridgingInitiated(
        address from,
        address to,
        uint256 myChain,
        uint256 toChain,
        address token,
        uint256 amount
    );

    event BridgingCompleted(string txID);

    constructor(uint256 chainID) {
        myChain = chainID;
    }

    function bridgeTokens(address to, address token, uint256 toChain, uint256 amount) external {
        IBEP20(token).transferFrom(msg.sender, address(this), amount);
        uint256 fee = amount * feeInPerMille[token] / 1000;
        if(fee < minFee[token]) fee = minFee[token];
        if(fee > maxFee[token]) fee = maxFee[token];
        uint256 amountAfterFee = amount - fee;
        feesCollected[token] += fee;
        if(feesCollected[token] >= swapAtAmount[token]) swapTokensForBNB(feesCollected[token], token);
        emit BridgingInitiated(msg.sender, to, myChain, toChain, token, amountAfterFee);
    }

    function sendTokens(address to, uint256 chainTo, address token, uint256 amount, string calldata txID) external onlyBridge {
        if(chainTo != myChain) return;
        if(bridgingCompleted[txID]) return;
        bridgingCompleted[txID] = true;
        IBEP20(token).transfer(to, amount);
        emit BridgingCompleted(txID);
    }

    function addToken(address token, uint256 fee, uint256 _minFee, uint256 _maxFee, address _router, uint256 _swapThreshold) external onlyOwner {
        feeInPerMille[token] = fee;
        minFee[token] = _minFee;
        maxFee[token] = _maxFee;
        routerAddress[token] = _router;
        swapAtAmount[token] = _swapThreshold;
    }

    function swapTokensForBNB(uint256 tokenAmount, address tokenAddress) private {
        address[] memory path = new address[](2);
        path[0] = tokenAddress;
        path[1] = IRouter(routerAddress[tokenAddress]).WETH();
        IBEP20(tokenAddress).approve(routerAddress[tokenAddress], type(uint256).max);
        IRouter(routerAddress[tokenAddress]).swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, CC, block.timestamp);
    }
}