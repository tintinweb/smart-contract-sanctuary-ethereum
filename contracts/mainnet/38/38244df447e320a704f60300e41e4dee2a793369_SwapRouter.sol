// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC20.sol";

contract SwapRouter is Ownable {

    address public feeTo;

    struct TokenInfo {
        uint256 chainId;
        address token;
    }

    struct FeeInfo {
        uint256 rate;
        uint256 min;
    }

    mapping(address => mapping(uint256 => mapping(address => FeeInfo))) public feePair;
    mapping(uint256 => mapping(address => uint256)) public tokenBalances;
    mapping(uint256 => mapping(address => bool)) swapTokens;
    TokenInfo[] public allTokens;

    event PairCreated(address indexed token0, address indexed token1, uint256 chainId, uint256 feeRate, uint256 feeMin);

    event Withdraw(address indexed payment, address indexed token, uint256 chainId, uint256 amount);

    event Swap(address indexed token0, address indexed token1, address indexed payment, uint256 chainId, uint256 amount, uint256 fee);

    constructor() {
    }

    function createPair(address tokenA, address tokenB, uint256 chainId, uint256 feeRate, uint256 feeMin) external onlyOwner {

        require(feeRate <= 1000, "Rate ratio cannot be greater than 1000");

        require(tokenA != address(0), 'ZERO_ADDRESS');
        require(tokenB != address(0), 'ZERO_ADDRESS');
        require(tokenA != tokenB, "token cannot be the same");

        FeeInfo memory feeInfo;
        feeInfo.rate = feeRate;
        feeInfo.min = feeMin;
        feePair[tokenA][chainId][tokenB] = feeInfo;

        emit PairCreated(tokenA, tokenB, chainId, feeRate, feeMin);
    }

    function withdraw(address payment, address token, uint256 chainId, uint256 amount) payable external onlyOwner {

        require(payment != address(0), 'ZERO_ADDRESS');
        require(token != address(0), 'ZERO_ADDRESS');
        require(amount > 0, "Withdrawal amount must be greater than 0");

        require(tokenBalances[chainId][token] > amount, 'Not Balance');
        tokenBalances[chainId][token] -= amount;

        if (token != address(1)) {
            IERC20(token).transfer(payment, amount);
        } else {
            payable(payment).transfer(amount);
        }

        emit Withdraw(payment, token, chainId, amount);
    }

    function swap(address tokenA, address tokenB, address payment, uint256 chainId, uint256 amount) payable external {

        if (tokenA == address(1)) {
            amount = msg.value;
        }
        require(amount > 0, "Swap amount must be greater than 0");

        if (!swapTokens[chainId][tokenA]) {
            TokenInfo memory _tokenInfo = TokenInfo({
            chainId : chainId,
            token : tokenA
            });
            allTokens.push(_tokenInfo);
        }

        FeeInfo memory feeInfo = feePair[tokenA][chainId][tokenB];
        uint256 feeRate = feeInfo.rate;
        uint256 fee = 0;

        if (tokenA != address(1)) {
            uint256 before = IERC20(tokenA).balanceOf(address(this));
            IERC20(tokenA).transferFrom(msg.sender, address(this), amount);
            amount = IERC20(tokenA).balanceOf(address(this)) - before;

            if (feeTo != address(0) && feeRate > 0) {
                fee = amount * feeRate / 1000;
            }

            if (fee < feeInfo.min) {
                fee = feeInfo.min;
            }

            require(amount - fee > 0, "Swap amount must be greater than fee");
            if (fee > 0) {
                IERC20(tokenA).transfer(feeTo, fee);
            }
        } else {
            if (feeTo != address(0) && feeRate > 0) {
                fee = amount * feeRate / 1000;
            }

            if (fee < feeInfo.min) {
                fee = feeInfo.min;
            }
            if (fee > 0) {
                payable(feeTo).transfer(fee);
            }
        }

        uint256 realAmount = amount - fee;

        tokenBalances[chainId][tokenA] += realAmount;

        emit Swap(tokenA, tokenB, payment, chainId, realAmount, fee);
    }

    function setFeeTo(address _feeTo) external onlyOwner {
        feeTo = _feeTo;
    }

    function balance() public view returns (uint256) {
        return address(this).balance;
    }

    function deposit(uint256 chainId, address token, uint256 amount) payable external returns (bool){
        uint256 before = IERC20(token).balanceOf(address(this));
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        amount = IERC20(token).balanceOf(address(this)) - before;

        tokenBalances[chainId][token] += amount;

        return true;
    }
}