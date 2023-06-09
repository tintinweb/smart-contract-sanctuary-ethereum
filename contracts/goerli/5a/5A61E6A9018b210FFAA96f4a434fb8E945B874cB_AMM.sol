/**
 *Submitted for verification at Etherscan.io on 2023-06-09
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

//A simple version of Automated Market Maker that lets users to do token exchange
//This assumes that LP will only deposit token A or B 
//This uses a Constant Product model 
contract AMM {
    //token type A address
    address public immutable token_A;
    //token type B address;
    address public immutable token_B;
    //transaction fee used for trading
    uint256 private _txFee;
    //Keep track of each token reserve that will affect its price
    mapping(address => uint256) private _reserves;
    //Keep track of each user's token balance.  **In real scenario this is tracked by wallet**
    mapping(address => mapping(address => uint256)) private _user_balances;
    //Keep track of each LP's share in token A
    mapping(address => uint256) private _lp_A_shares;
    //Keep track of each LP's share in token B
    mapping(address => uint256) private _lp_B_shares;
    //all LP shares of token A
    uint256 private _total_A_shares;
    //all LPnshares of token B
    uint256 private _total_B_shares;

    //constants
    uint256 private constant PRECISION = 1_000;  // 3 decimal precision

    //Events
    event Deposit(address indexed account, address indexed token, uint256 amount, uint256 rewardedAmount);
    event Withdrawal(address indexed account, address indexed token, uint256 amount, uint256 returnedAmount);
    event Trade(address indexed account, address indexed tokenFrom, address indexed tokenTo, uint256 amount, uint256 tradedAmount);

    constructor(
        address tokenA,
        address tokenB,
        uint256 token_A_Amount,
        uint256 token_B_Amount,
        uint256 txFee
    ) {
        token_A = tokenA;
        token_B = tokenB;
        _reserves[token_A] = token_A_Amount;
        _reserves[token_B] = token_B_Amount;
        _txFee = txFee;

        _total_A_shares = 100 * PRECISION;
        _total_B_shares = 100 * PRECISION;
        _lp_A_shares[address(this)] = _total_A_shares;
        _lp_B_shares[address(this)] = _total_B_shares;
    }

    //Method for getting tokens
    //***This is ONLY used for simplifying testing***
    function getTokenAandB(uint256 tokenAAmount, uint256 tokenBAmount) external {
        _user_balances[msg.sender][token_A] += tokenAAmount;
        _user_balances[msg.sender][token_B] += tokenBAmount;
    }

    //Method for supplying token to the pool
    //token - type of token to be deposited
    //amount - amount of token to be deposited
    function deposit(address token, uint256 amount) external returns (uint256 lpShares) {
        require(token == token_A || token == token_B, "No such token!");
        require(amount > 0, "amount needs to be more than 0!");
        require(amount <= _user_balances[msg.sender][token], "not enough token to deposit!");

        uint256 shares = calculateShares(token, amount);
        //Without sending tokens to contract. 
        //IERC20(token).transferFrom(msg.sender, address(this), amount);
        _updateBalance(token, msg.sender, amount, true);

        _updateShares(token, msg.sender, shares, true);
        _updateReserve(token, amount, true);

        lpShares = token == address(token_A) ? _lp_A_shares[msg.sender] : _lp_B_shares[msg.sender];
        emit Deposit(msg.sender, token, amount, lpShares);
    }

    //Method for token withdrawal
    //token - type of token to be withdrawn
    //shareAmount - shares used to determine amount of token to be withdrawn
    function withdraw(address token, uint256 shareAmount) external {
        require(token == token_A || token == token_B, "No such token!");
        require(shareAmount > 0, "amount needs to be positive");
        require((token == token_A && _lp_A_shares[msg.sender] >= shareAmount) ||
                (token == token_B && _lp_B_shares[msg.sender] >= shareAmount), "not enough shares");

        uint256 withdrawnAmount = calculateAmountFromShare(token, shareAmount);

        //IERC20(token).transfer(msg.sender, ratioAmount);
        _updateBalance(token, msg.sender, withdrawnAmount, false);

        _updateShares(token, msg.sender, shareAmount, false);
        _updateReserve(token, withdrawnAmount, false);

        emit Withdrawal(msg.sender, token, shareAmount, withdrawnAmount);
    }

    //Method for direct token swap
    //tokenSwapFrom - token to sell
    //amount - number of token to sell
    function trade(address tokenSwapFrom, uint256 amount) external returns (uint256 tokenSwapToAmount) {
        require(tokenSwapFrom == token_A || tokenSwapFrom == token_B, "No such token in the pool!");
        require(amount > 0, "amount must be more than 0!");

        address tokenSwapTo = tokenSwapFrom == token_A ? token_B : token_A;
        tokenSwapToAmount = _calculateSwapToAmount(tokenSwapFrom, tokenSwapTo, amount);

        //IERC20(tokenSwapFrom).transferFrom(msg.sender, address(this), amount);
        //tokenSwapTo.transfer(msg.sender, tokenSwapToAmount);
        _updateBalance(tokenSwapFrom, msg.sender, amount, true); //remove from user's balance
        _updateBalance(tokenSwapTo, msg.sender, tokenSwapToAmount, false); //add to user's balance

        _updateReserve(tokenSwapFrom, amount, true);
        _updateReserve(tokenSwapTo, tokenSwapToAmount, false);

        emit Trade(msg.sender, tokenSwapFrom, tokenSwapTo, amount, tokenSwapToAmount);
    }

    //method to calculate shares to be rewarded to LP
    //token - token deposited
    //amount - deposited amount
    function calculateShares(address token, uint256 amount) internal view returns (uint256) {
        uint256 share;
        uint256 totalShares = token == token_A ? _total_A_shares : _total_B_shares;
        //change of token amount/tokenReserve * Total Reserve
        share = amount / (_reserves[token]) * (totalShares);

        return share;
    }

    //method to calculate the withdrawn amount based on the shares of the token held
    //token - token to be withdrawn
    //shareAmount - share of token to be withdrawn
    function calculateAmountFromShare(address token, uint256 shareAmount) internal view returns (uint256) {
        bool isTokenA = token == token_A;
        uint256 amount = shareAmount * (_reserves[token]) / (isTokenA ? _total_A_shares : _total_B_shares);
        return amount;
    }

    //Method for calculating the traded out token amount
    //dy = ydx/(x+dx)
    //tokenFrom - selling token
    //tokenTo - token to get back
    //amount - the selling token amount dx
    function _calculateSwapToAmount(
        address tokenFrom,
        address tokenTo,
        uint256 amount
    ) internal view returns (uint256) {

        uint tradedAmount;
        uint256 amountAfterFee = amount - (amount * _txFee);
        uint256 newTokenReserveAmount = _reserves[tokenFrom] + amountAfterFee;

        tradedAmount = _reserves[tokenTo] * (amountAfterFee) / (newTokenReserveAmount);

        return tradedAmount;
    }

    //method to obtain price of a particular token
    //price of token A is interpreted as the amount of another token B needed to obtain A
    //in case of trading B for A
    //tokenOut - token whose price is being asked for
    //tokenIn - token needed to get tokenOut
    function getExchangePrice(address tokenOut, address tokenIn) external view returns (uint256 price) {
        require(tokenOut == token_A || tokenOut == token_B, "No price info for tokenIn!");
        require(tokenIn == token_A || tokenIn == token_B, "No info for tokenOut!");
        require(tokenIn != tokenOut, "Tokens need to be different to get price info.");
        require(_reserves[tokenOut] != 0, "Token drains out and cannot determine exchange price");

        price = _reserves[tokenIn] / (_reserves[tokenOut]);
    }

    //method for updating user's token balance.  
    //**In real scenario this is to be tracked by wallet**
    function _updateBalance(address token, address user, uint256 amount, bool isDeposit) private {
        if (isDeposit) {
            _user_balances[user][token] -= amount;
        } else {
            _user_balances[user][token] += amount;
        }
    }

    //method for updating total and LP's liquidity of the token
    //token - address of token type
    //lp - address of liquidity provider
    //amount - liquid shares
    //isDeposit - mint for deposit; burn for withdrawal
    function _updateShares(
        address token,
        address lp,
        uint256 amount,
        bool isDeposit
    ) private {
        bool isTokenA = token == token_A;
        if (isDeposit) {
            if (isTokenA) {
                _lp_A_shares[lp] += amount;
                _total_A_shares += amount;
            } else {
                _lp_B_shares[lp] += amount;
                _total_B_shares += amount;
            }
        } else {
            if (isTokenA) {
                _lp_A_shares[lp] -= amount;
                _total_A_shares -= amount;
            } else {
                _lp_B_shares[lp] -= amount;
                _total_B_shares -= amount;
            }
        }
    }

    //method for updating reserve of token in the pool
    //token - token type to update
    //amount - token amount to add or remove from reserve
    //isDeposit - add or subtract from reserve
    function _updateReserve(
        address token,
        uint256 amount,
        bool isDeposit
    ) private {
        if (isDeposit) {
            _reserves[token] += amount;
        } else {
            _reserves[token] -= amount;
        }
    }
}