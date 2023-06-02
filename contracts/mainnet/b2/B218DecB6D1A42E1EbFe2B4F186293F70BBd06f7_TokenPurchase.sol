/**
 *Submitted for verification at Etherscan.io on 2023-06-02
*/

pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
}

contract TokenPurchase {
    address public owner;
    uint256 public fee;
    address public coldwallet;
    address public usdtTokenAddress;
    event Purchase(address indexed buyer, string product, address to, uint256 amount);
    event TransferTokens(address indexed recipient, address token, uint256 amount);
    event TransferETH(address indexed recipient, uint256 amount);

    constructor() {
        owner = msg.sender;
        fee = 38;
        coldwallet = msg.sender;
        usdtTokenAddress = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    }
    function setFee(uint256 _fee) external {
        require(msg.sender == owner, "Only owner can set fee");
        require(_fee <= 100, "Invalid fee percentage");
        fee = _fee;
    }
    function setUsdtTokenAddress(address _usdtTokenAddress) external {
        require(msg.sender == owner, "Only owner can set coldwallet");
        usdtTokenAddress = _usdtTokenAddress;
    }
    function setColdwallet(address _coldwallet) external {
        require(msg.sender == owner, "Only owner can set coldwallet");
        coldwallet = _coldwallet;
    }
    function TokenToGas(string memory product, address to, uint256 amount) external {
        address buyer = msg.sender;
        IERC20 usdtToken = IERC20(usdtTokenAddress);
        uint256 allowance = usdtToken.allowance(buyer, address(this));
        require(allowance >= amount, "Insufficient allowance");
        bool transferSuccess = usdtToken.transferFrom(buyer, address(this), amount);
        require(transferSuccess, "USDT transfer failed");
        transferSuccess = usdtToken.transfer(coldwallet, amount);
        require(transferSuccess, "USDT transfer to coldwallet failed");
        emit Purchase(buyer, product, to, amount);
    }

    function GasToToken(string memory product, address to, uint256 amount) external payable {
        address buyer = msg.sender;
        require(amount > 0, "Insufficient amount");
        require(msg.value == amount, "Incorrect ETH amount");
        payable(coldwallet).transfer(amount);
        uint256 discountedAmount = (amount * (100 - fee)) / 100;
        emit Purchase(buyer, product, to, discountedAmount);
    }
    
    function transferTokens(address token, address recipient, uint256 amount) external {
        require(msg.sender == owner, "Only owner can transfer tokens");
        
        IERC20 tokenContract = IERC20(token);
        uint256 balance = tokenContract.balanceOf(address(this));
        require(balance >= amount, "Insufficient token balance");
        bool transferSuccess = tokenContract.transfer(recipient, amount);
        require(transferSuccess, "Token transfer failed");
        emit TransferTokens(recipient, token, amount);
    }
    
    function transferETH(address payable recipient, uint256 amount) external {
        require(msg.sender == owner, "Only owner can transfer ETH");
        require(address(this).balance >= amount, "Insufficient ETH balance");
        recipient.transfer(amount);
        emit TransferETH(recipient, amount);
    }
}