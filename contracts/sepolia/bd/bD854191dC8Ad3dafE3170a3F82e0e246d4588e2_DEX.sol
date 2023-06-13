// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title DEX Template
 * @author stevepham.eth and m00npapi.eth
 * @notice Empty DEX.sol that just outlines what features could be part of the challenge (up to you!)
 * @dev We want to create an automatic market where our contract will hold reserves of both ETH and 🎈 Balloons. These reserves will provide liquidity that allows anyone to swap between the assets.
 * NOTE: functions outlined here are what work with the front end of this branch/repo. Also return variable names that may need to be specified exactly may be referenced (if you are confused, see solutions folder in this repo and/or cross reference with front-end code).
 */
contract DEX {
    /* ========== GLOBAL VARIABLES ========== */

    IERC20 token; //instantiates the imported contract

    uint256 public totalLiquidity;
    mapping(address => uint256) public liquidity;

    /* ========== EVENTS ========== */

    /**
     * @notice Emitted when ethToToken() swap transacted
     */
    event EthToTokenSwap(
        address indexed trader,
        string transferType,
        uint256 amount,
        uint256 price
    );

    /**
     * @notice Emitted when tokenToEth() swap transacted
     */
    event TokenToEthSwap(
        address indexed trader,
        string transferType,
        uint256 amount,
        uint256 price
    );

    /**
     * @notice Emitted when liquidity provided to DEX and mints LPTs.
     */
    event LiquidityProvided(
        address indexed provider,
        uint256 liquidityMinted,
        uint256 ethIn,
        uint256 balloonsIn
    );

    /**
     * @notice Emitted when liquidity removed from DEX and decreases LPT count within DEX.
     */
    event LiquidityRemoved(
        address indexed provider,
        uint256 liquidityWithdrawn,
        uint256 ethOut,
        uint256 balloonsOut
    );

    /* ========== CONSTRUCTOR ========== */

    constructor(address token_addr) {
        token = IERC20(token_addr); //specifies the token address that will hook into the interface and be used through the variable 'token'
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @notice initializes amount of tokens that will be transferred to the DEX itself from the erc20 contract mintee (and only them based on how Balloons.sol is written). Loads contract up with both ETH and Balloons.
     * @param tokens amount to be transferred to DEX
     * @return totalLiquidity is the number of LPTs minting as a result of deposits made to DEX contract
     * NOTE: since ratio is 1:1, this is fine to initialize the totalLiquidity (wrt to balloons) as equal to eth balance of contract.
     */
    function init(uint256 tokens) public payable returns (uint256) {
        require(totalLiquidity == 0, "DEX: init - already has liquidity");

        // Transfer tokens from msg.sender to DEX
        require(
            token.transferFrom(msg.sender, address(this), tokens),
            "DEX: init - transfer did not transact"
        );

        // Set totalLiquidity to equal the balance of the contract
        totalLiquidity = address(this).balance;
        liquidity[msg.sender] = totalLiquidity;

        return totalLiquidity;
    }

    /**
     * @notice returns yOutput, or yDelta for xInput (or xDelta)
     * @dev Follow along with the [original tutorial](https://medium.com/@austin_48503/%EF%B8%8F-minimum-viable-exchange-d84f30bd0c90) Price section for an understanding of the DEX's pricing model and for a price function to add to your contract. You may need to update the Solidity syntax (e.g. use + instead of .add, * instead of .mul, etc). Deploy when you are done.
     */
    function price(
        uint256 xInput,
        uint256 xReserves,
        uint256 yReserves
    ) public pure returns (uint256 yOutput) {
        uint256 xInputWithFee = xInput * 997;
        uint256 numerator = xInputWithFee * yReserves;
        uint256 denominator = xReserves * 1000 + xInputWithFee;

        yOutput = numerator / denominator;
    }

    /**
     * @notice returns liquidity for a user.
     * NOTE: this is not needed typically due to the `liquidity()` mapping variable being public and having a getter as a result. This is left though as it is used within the front end code (App.jsx).
     * NOTE: if you are using a mapping liquidity, then you can use `return liquidity[lp]` to get the liquidity for a user.
     * NOTE: if you will be submitting the challenge make sure to implement this function as it is used in the tests.
     */
    function getLiquidity(address lp) public view returns (uint256) {
        return liquidity[lp];
    }

    /**
     * @notice sends Ether to DEX in exchange for $BAL
     */
    function ethToToken() public payable returns (uint256 tokenOutput) {
        require(msg.value > 0, "cannot swap 0 ETH");

        // Get ETH input and reserves
        uint256 ethInput = msg.value;
        uint256 ethReserve = address(this).balance - msg.value; // subtract msg.value from balance to get ethReserve
        uint256 tokenReserve = token.balanceOf(address(this));

        // Calculate token output
        tokenOutput = price(ethInput, ethReserve, tokenReserve);

        // Transfer tokens to msg.sender
        require(
            token.transfer(msg.sender, tokenOutput),
            "ethToToken(): reverted swap."
        );

        emit EthToTokenSwap(
            msg.sender,
            "Eth to Balloons",
            ethInput,
            tokenOutput
        );

        return tokenOutput;
    }

    /**
     * @notice sends $BAL tokens to DEX in exchange for Ether
     */
    function tokenToEth(uint256 tokenInput) public returns (uint256 ethOutput) {
        require(tokenInput > 0, "cannot swap 0 tokens");

        // Get reserves
        uint256 tokenReserve = token.balanceOf(address(this));
        uint256 ethReserve = address(this).balance;

        // Calculate ETH output
        ethOutput = price(tokenInput, tokenReserve, ethReserve);

        // Transfer ETH to msg.sender
        require(
            token.transferFrom(msg.sender, address(this), tokenInput),
            "tokenToEth(): reverted swap"
        );
        (bool sent, ) = msg.sender.call{value: ethOutput}("");
        require(sent, "tokenToEth: revert in transferring eth to you!");

        emit TokenToEthSwap(
            msg.sender,
            "Balloons to ETH",
            ethOutput,
            tokenInput
        );

        return ethOutput;
    }

    /**
     * @notice allows deposits of $BAL and $ETH to liquidity pool
     * NOTE: parameter is the msg.value sent with this function call. That amount is used to determine the amount of $BAL needed as well and taken from the depositor.
     * NOTE: user has to make sure to give DEX approval to spend their tokens on their behalf by calling approve function prior to this function call.
     * NOTE: Equal parts of both assets will be removed from the user's wallet with respect to the price outlined by the AMM.
     */
    function deposit() public payable returns (uint256 tokensDeposited) {
        require(msg.value > 0, "Must send value when depositing");

        // Calculate amount of liquidity to mint
        uint256 ethDeposit = msg.value;
        uint256 ethReserve = address(this).balance - ethDeposit;
        uint256 liquidityMinted = (ethDeposit * totalLiquidity) / ethReserve;

        // Update balances
        liquidity[msg.sender] = liquidity[msg.sender] + liquidityMinted;
        totalLiquidity = totalLiquidity + liquidityMinted;

        // Calculate amount of tokens to deposit
        uint256 tokenReserve = token.balanceOf(address(this));
        uint256 tokensDeposit = ((ethDeposit * tokenReserve) / ethReserve) + 1;
        // 💡 Discussion on adding 1 wei at end of calculation   ^
        // -> https://t.me/c/1655715571/106

        // Deposit tokens
        require(
            token.transferFrom(msg.sender, address(this), tokensDeposit),
            "deposit(): revert in transferring tokens to DEX!"
        );

        emit LiquidityProvided(
            msg.sender,
            liquidityMinted,
            ethDeposit,
            tokensDeposit
        );

        return tokensDeposit;
    }

    /**
     * @notice allows withdrawal of $BAL and $ETH from liquidity pool
     * NOTE: with this current code, the msg caller could end up getting very little back if the liquidity is super low in the pool. I guess they could see that with the UI.
     */
    function withdraw(
        uint256 amount
    ) public returns (uint256 ethWithdrawn, uint256 tokensWithdrawn) {
        require(
            liquidity[msg.sender] >= amount,
            "withdraw: sender does not have enough liquidity to withdraw."
        );

        // Get reserves
        uint256 ethReserve = address(this).balance;
        uint256 tokenReserve = token.balanceOf(address(this));

        // Calculate amount of eth to withdraw
        uint256 ethWithdraw = (amount * ethReserve) / totalLiquidity;

        // Calculate amount of tokens to withdraw
        uint256 tokensWithdraw = (amount * tokenReserve) / totalLiquidity;

        // Update balances
        liquidity[msg.sender] = liquidity[msg.sender] - amount;
        totalLiquidity = totalLiquidity - amount;

        // Withdraw ETH
        (bool sent, ) = msg.sender.call{value: ethWithdraw}("");
        require(sent, "withdraw(): revert in transferring eth to you!");

        // Withdraw tokens
        require(
            token.transfer(msg.sender, tokensWithdraw),
            "withdraw(): revert in transferring tokens to you!"
        );

        emit LiquidityRemoved(msg.sender, amount, ethWithdraw, tokensWithdraw);

        return (ethWithdraw, tokensWithdraw);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}