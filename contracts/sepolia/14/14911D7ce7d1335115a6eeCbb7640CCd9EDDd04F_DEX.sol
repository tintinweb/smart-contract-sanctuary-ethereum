// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DEX {
    /* ========== GLOBAL VARIABLES ========== */
    IERC20 token;
    uint256 public totalLiquidity;
    mapping(address => uint) public liquidity;
    /* ========== EVENTS ========== */

    event EthToTokenSwap(
        address sender,
        string message,
        uint256 inputAmount,
        uint256 outputAmount
    );

    event TokenToEthSwap(
        address sender,
        string message,
        uint256 ethOutput,
        uint256 tokenInput
    );

    event LiquidityProvided(
        address provider,
        uint256 liquidityMinted,
        uint256 ethDeposit,
        uint256 tokenDeposit
    );

    event LiquidityRemoved(
        address liquidityRemover,
        uint256 liquidityRemoved,
        uint256 eth_amount,
        uint256 token_amount
    );

    /* ========== CONSTRUCTOR ========== */

    constructor(address token_addr) public {
        token = IERC20(token_addr);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */
    function init(uint256 tokens) public payable returns (uint256) {
        require(totalLiquidity == 0, "Dex already has liquidity");
        liquidity[msg.sender] = msg.value;
        totalLiquidity = msg.value;
        require(token.transferFrom(msg.sender, address(this), tokens));
        return totalLiquidity;
    }

    function price(
        uint256 xInput,
        uint256 xReserves,
        uint256 yReserves
    ) public view returns (uint256 yOutput) {
        uint256 input_token_with_fees = xInput * 997;
        uint256 numerator = yReserves * input_token_with_fees;
        uint256 denominator = (xReserves * 1000) + (input_token_with_fees);
        yOutput = numerator / denominator;
        return yOutput;
    }

    function ethToToken() public payable returns (uint256 tokenOutput) {
        require(msg.value > 0, "Cannot swap 0 ETH");
        uint256 xReserves = address(this).balance - msg.value;
        uint256 yReserves = token.balanceOf(address(this));

        tokenOutput = price(msg.value, xReserves, yReserves);

        require(
            token.transfer(msg.sender, tokenOutput),
            "ethToToken(): reverted swap."
        );
        emit EthToTokenSwap(
            msg.sender,
            "Eth to Balloons",
            msg.value,
            tokenOutput
        );
        return tokenOutput;
    }

    function tokenToEth(uint256 tokenInput) public returns (uint256 ethOutput) {
        require(tokenInput > 0, "Cannot swapt 0 token");
        uint256 xReserves = address(this).balance;
        uint256 yReserves = token.balanceOf(address(this));

        ethOutput = price(tokenInput, yReserves, xReserves);

        require(
            token.transferFrom(msg.sender, address(this), tokenInput),
            "tokenToEth(): reverted swap."
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

    function deposit() public payable returns (uint256 tokensDeposited) {
        require(msg.value > 0);
        uint256 ethReserve = address(this).balance - (msg.value);
        uint256 tokenReserve = token.balanceOf(address(this));
        uint256 tokenDeposit;

        tokenDeposit = (msg.value * (tokenReserve) / ethReserve) + (1);
        uint256 liquidityMinted = msg.value * (totalLiquidity) / ethReserve;
        liquidity[msg.sender] = liquidity[msg.sender] + (liquidityMinted);
        totalLiquidity = totalLiquidity + (liquidityMinted);

        require(token.transferFrom(msg.sender, address(this), tokenDeposit));
        emit LiquidityProvided(
            msg.sender,
            liquidityMinted,
            msg.value,
            tokenDeposit
        );
        return tokenDeposit;
    }

    function withdraw(uint256 amount)
        public
        returns (uint256 eth_amount, uint256 token_amount)
    {
        require(
            liquidity[msg.sender] >= amount,
            "withdraw: sender does not have enough liquidity to withdraw."
        );

        uint256 xReserves = address(this).balance;
        uint256 yReserves = token.balanceOf(address(this));

        eth_amount = (xReserves * amount) / totalLiquidity;
        token_amount = (yReserves * amount) / totalLiquidity;

        liquidity[msg.sender] = liquidity[msg.sender] - amount;
        totalLiquidity = totalLiquidity - amount;
        (bool sent, ) = payable(msg.sender).call{value: eth_amount}("");
        require(sent, "withdraw(): revert in transferring eth to you!");
        require(token.transfer(msg.sender, token_amount));
        emit LiquidityRemoved(msg.sender, amount, eth_amount, token_amount);
        return (eth_amount, token_amount);
    }

    function getLiquidity(address provider) public view returns(uint256) {
        return liquidity[provider];
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