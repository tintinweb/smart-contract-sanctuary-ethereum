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
    uint256 totalLiquidity; //total liquidity in DEX
    mapping(address => uint256) liquidty;

    /* ========== EVENTS ========== */

    /**
     * @notice Emitted when ethToToken() swap transacted
     */
    event EthToTokenSwap();

    /**
     * @notice Emitted when tokenToEth() swap transacted
     */
    event TokenToEthSwap();

    /**
     * @notice Emitted when liquidity provided to DEX and mints LPTs.
     */
    event LiquidityProvided();

    /**
     * @notice Emitted when liquidity removed from DEX and decreases LPT count within DEX.
     */
    event LiquidityRemoved();

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
        require(totalLiquidity == 0, "Init: Contract has liquidity"); //ensures that totalLiquidity is equal to 0
        totalLiquidity = tokens; //initializes totalLiquidity
        liquidty[msg.sender] = tokens; //initializes liquidty for msg.sender
        bool success = token.transferFrom(msg.sender, address(this), tokens);

        require(success, "Init: TransferFrom failed"); //ensures that the transferFrom() function was successful
        return totalLiquidity; //returns the totalLiquidity
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
        yOutput =
            (yReserves * ((xInput * 997) / 1000)) /
            (xReserves + ((xInput * 997) / 1000)); //returns yOutput, or yDelta for xInput (or xDelta)
    }

    /**
     * @notice returns liquidity for a user. Note this is not needed typically due to the `liquidity()` mapping variable being public and having a getter as a result. This is left though as it is used within the front end code (App.jsx).
     * if you are using a mapping liquidity, then you can use `return liquidity[lp]` to get the liquidity for a user.
     *
     */
    function getLiquidity(address lp) public view returns (uint256) {}

    /**
     * @notice sends Ether to DEX in exchange for $BAL
     */
    function ethToToken() public payable returns (uint256 tokenOutput) {
        uint256 ethReserves = address(this).balance - msg.value; //gets the amount of ether reserves in the contract
        uint256 tokenReserves = token.balanceOf(address(this)); //gets the amount of token reserves in the contract
        tokenOutput = price(msg.value, ethReserves, tokenReserves); //returns the amount of tokens that will be sent to the user
        bool success = token.transfer(msg.sender, tokenOutput); //transfers the tokens to the contract
        require(success, "EthToToken: Transfer failed"); //ensures that the transferFrom() function was successful
        emit EthToTokenSwap(); //emits the EthToTokenSwap event
    }

    /**
     * @notice sends $BAL tokens to DEX in exchange for Ether
     */
    function tokenToEth(uint256 tokenInput) public returns (uint256 ethOutput) {
        uint256 tokenReserves = token.balanceOf(address(this)); //gets the amount of token reserves in the contract
        uint256 ethReserves = address(this).balance; //gets the amount of ether reserves in the contract
        ethOutput = price(tokenInput, tokenReserves, ethReserves); //returns the amount of ether that will be sent to the user

        bool success = token.transferFrom(
            msg.sender,
            address(this),
            tokenInput
        ); //transfers the tokens to the contract
        require(success, "TokenToEth: TransferFrom failed");

        (bool done, ) = payable(msg.sender).call{value: ethOutput}(""); //transfers the tokens to the contract
        require(done, "TokenToEth: ETH Transfer failed"); //ensures that the transferFrom() function was successful //emits an event when liquidity is provided to the contract
        emit TokenToEthSwap(); //emits the TokenToEthSwap event
    }

    /**
     * @notice allows deposits of $BAL and $ETH to liquidity pool
     * NOTE: parameter is the msg.value sent with this function call. That amount is used to determine the amount of $BAL needed as well and taken from the depositor.
     * NOTE: user has to make sure to give DEX approval to spend their tokens on their behalf by calling approve function prior to this function call.
     * NOTE: Equal parts of both assets will be removed from the user's wallet with respect to the price outlined by the AMM.
     */
    function deposit() public payable returns (uint256 tokensDeposited) {
        uint256 ethReserves = address(this).balance - msg.value;
        uint256 ethInput = msg.value; //gets the amount of ether sent to the contract
        uint256 tokenReserves = token.balanceOf(address(this)); //gets the amount of token reserves in the contract
        tokensDeposited = (tokenReserves * ethInput) / ethReserves; //returns the amount of tokens that will be sent to the user
        uint256 liquidtyMinted = (totalLiquidity * ethInput) / ethReserves; //returns the amount of tokens that will be sent to the user
        liquidty[msg.sender] += liquidtyMinted; //adds the amount of liquidity minted to the user's liquidity
        totalLiquidity += liquidtyMinted; //adds the amount of liquidity minted to the totalLiquidity
        bool success = token.transferFrom(
            msg.sender,
            address(this),
            tokensDeposited
        ); //transfers the tokens to the contract
        require(success, "Deposit: TransferFrom failed"); //ensures that the transferFrom() function was successful
        emit LiquidityProvided(); //emits the LiquidityProvided event
    }

    /**
     * @notice allows withdrawal of $BAL and $ETH from liquidity pool
     * NOTE: with this current code, the msg caller could end up getting very little back if the liquidity is super low in the pool. I guess they could see that with the UI.
     */
    function withdraw(uint256 amount)
        public
        returns (uint256 ethAmount, uint256 tokenAmount)
    {
        uint256 ethReserves = address(this).balance;
        uint256 tokenReserves = token.balanceOf(address(this));
        ethAmount = (ethReserves * amount) / totalLiquidity; //returns the amount of ether that will be sent to the user
        tokenAmount = (tokenReserves * amount) / totalLiquidity; //returns the amount of tokens that will be sent to the user
        liquidty[msg.sender] -= ethAmount; //subtracts the amount of liquidity withdrawn from the user's liquidity
        totalLiquidity -= ethAmount; //subtracts the amount of liquidity withdrawn from the totalLiquidity
        (bool done, ) = payable(msg.sender).call{value: ethAmount}(""); //transfers the tokens to the contract
        require(done, "Withdraw: ETH Transfer failed"); //ensures that the transferFrom() function was successful //emits an event when liquidity is withdrawn from the contract

        bool success = token.transfer(msg.sender, tokenAmount); //transfers the tokens to the contract
        require(success, "Withdraw: token transfer failed");
        emit LiquidityRemoved(); //emits the LiquidityWithdrawn event
    }
}