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

pragma solidity >=0.8.0 <0.9.0;
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title DEX
 * @author Steve P.
 * @notice this is a single token pair reserves DEX, ref: "Scaffold-ETH Challenge 2" as per https://speedrunethereum.com/challenge/token-vendor
 */
contract DEX {
    uint256 public totalLiquidity;
    mapping(address => uint256) public liquidity;

    IERC20 token; //instantiates the imported contract

    /* ========== EVENTS ========== */

    /**
     * @notice Emitted when ethToToken() swap transacted
     */
    event EthToTokenSwap(address _swapper, uint256 tokenOutput, uint256 ethInput);

    /**
     * @notice Emitted when tokenToEth() swap transacted
     */
     event TokenToEthSwap(address _swapper, uint256 ethOutput, uint256 tokensInput);

    /**
     * @notice Emitted when liquidity provided to DEX
     */
    event LiquidityProvided(
        address _liquidityProvider,
        uint256 ethInput,
        uint256 tokensInput,
        uint256 newLiquidityPosition,
        uint256 liquidityMinted,
        uint256 totalLiquidity
    );
    /**
     * @notice Emitted when liquidity removed from DEX
     */
    event LiquidityRemoved(
        address _liquidityRemover,
        uint256 ethOutput,
        uint256 tokensOutput,
        uint256 newLiquidityPosition,
        uint256 liquidityWithdrawn,
        uint256 totalLiquidity
    );


    /* ========== CONSTRUCTOR ========== */

    constructor(address token_addr) public {
        token = IERC20(token_addr); //specifies the token address that will hook into the interface and be used through the variable 'token'
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @notice initializes amount of tokens that will be transferred to the DEX itself from the erc20 contract mintee (and only them based on how Balloons.sol is written). Loads contract up with both ETH and Balloons.
     * @param tokens amount to be transferred to DEX
     * @return totalLiquidity is the balance of this DEX contract
     * NOTE: since ratio is 1:1, this is fine to initialize the totalLiquidity (wrt to balloons) as equal to eth balance of contract.
     */
    function init(uint256 tokens) public payable returns (uint256) {
        require(totalLiquidity == 0, "DEX already has liquidity.");
        totalLiquidity = address(this).balance;
        liquidity[msg.sender] = totalLiquidity;
        require(token.transferFrom((msg.sender), address(this), tokens), "Transfer failed.");

        return totalLiquidity;
    }

    /**
     * @notice returns yOutput, or yDelta for xInput (or xDelta)
     */
    function price(uint256 xInput, uint256 xReserves, uint256 yReserves) public view returns (uint256 yOutput) {
        uint256 xInputWithFee = xInput * 997;
        uint256 numerator = xInputWithFee * yReserves;
        uint256 denominator = (xReserves * 1000) + xInputWithFee;
        
        return (numerator / denominator);
    }

    /**
     * @notice sends Ether to DEX in exchange for $BAL
     */
    function ethToToken() public payable returns (uint256 tokenOutput) {
        require(msg.value > 0, "Value of eth must be grater then 0.");
        uint256 ethReserve = address(this).balance - msg.value;
        uint256 tokenReserve = token.balanceOf(address(this));
        uint256 tokenOutput = price(msg.value, ethReserve, tokenReserve);

        require(token.transfer(msg.sender, tokenOutput), "Transfer failed");
        emit EthToTokenSwap(msg.sender, msg.value, tokenOutput);

        return tokenOutput;
    }

    /**
     * @notice sends $BAL tokens to DEX in exchange for Ether
     */
    function tokenToEth(uint256 tokenInput) public payable returns (uint256 ethOutput) {
        require(tokenInput > 0, "Value of token must be grater then 0.");
        uint256 ethReserve = address(this).balance;
        uint256 tokenReserve = token.balanceOf(address(this));
        uint256 ethOutput = price(tokenInput, tokenReserve, ethReserve);

        require(token.transferFrom(msg.sender, address(this), ethOutput), "Transfer failed");
        emit TokenToEthSwap(msg.sender, ethOutput, tokenInput);

        return ethOutput;
    }

    /**
     * @notice allows deposits of $BAL and $ETH to liquidity pool
     * NOTE: Ratio needs to be maintained.
     */
    function deposit() public payable returns(uint256 tokenDeposited) {
        uint256 ethReserve = address(this).balance - msg.value;
        uint256 tokenReserve = token.balanceOf(address(this));
        uint256 tokenDeposit;
        uint256 liquidityMinted;

        tokenDeposit = msg.value * (tokenReserve / ethReserve) + 1;
        liquidityMinted = msg.value * (totalLiquidity / ethReserve);
        liquidity[msg.sender] = liquidity[msg.sender] + liquidityMinted;
        totalLiquidity = totalLiquidity + liquidityMinted;

        emit LiquidityProvided(msg.sender, msg.value, tokenDeposit, liquidity[msg.sender], 
                            liquidityMinted, totalLiquidity);

        return tokenDeposit;
    }
 

    /**
     * @notice allows withdrawal of $BAL and $ETH from liquidity pool
     */
    function withdraw(uint256 amount) public returns (uint256 ethAmount, uint256 tokenAmount) {
        require(liquidity[msg.sender] >= amount, "Not enough money.");
        uint256 ethReserve = address(this).balance;
        uint256 tokenReserve = token.balanceOf(address(this));
        uint256 ethWithdrawn;
        uint256 tokenAmount;

        ethWithdrawn = amount * ethReserve / totalLiquidity;
        tokenAmount = amount * tokenReserve / totalLiquidity;
        liquidity[msg.sender] = liquidity[msg.sender] - amount;
        totalLiquidity = totalLiquidity - amount;

        (bool sent, ) = payable(msg.sender).call{value: ethWithdrawn}("");
        require(sent, "Withdraw failed.");
        require(token.transfer(msg.sender, tokenAmount));

        emit LiquidityRemoved(
            msg.sender,
            ethWithdrawn,
            tokenAmount,
            liquidity[msg.sender],
            ethWithdrawn,
            totalLiquidity
        );

        return (ethWithdrawn, tokenAmount);
    }
}