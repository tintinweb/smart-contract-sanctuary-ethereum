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

contract DEX {
    uint256 public totalLiquidity;
    mapping (address => uint256) public liquidity;

    IERC20 token;

    event EthToTokenSwap(address sender, string message, uint256 amountEth, uint256 amountToken);
    event TokenToEthSwap(address sender, string message, uint256 amountToken, uint256 amountEth);
    event LiquidityProvided(address sender, uint256 liquidityMinted, uint256 amountEth, uint256 tokenDeposit);
    event LiquidityRemoved(address sender, uint256 liquidityAmount, uint256 ethAmount, uint256 tokenAmount);

    constructor(address token_addr) {
        token = IERC20(token_addr);
    }

    function init(uint256 tokens) public payable returns (uint256) {
        require(totalLiquidity == 0, "DEX: already initialized");
        totalLiquidity = address(this).balance;
        liquidity[msg.sender] = totalLiquidity;
        require(token.transferFrom(msg.sender, address(this), tokens), "DEX: transfer failed");

        return totalLiquidity;
    }

    function price(
        uint256 xInput,
        uint256 xReserves,
        uint256 yReserves
    ) public pure returns (uint256 yOutput) {
        uint256 xInputWithFee = 997 * xInput;
        uint256 numerator = yReserves * xInputWithFee;
        uint denominator = 1000*xReserves + xInputWithFee;
        yOutput = numerator / denominator;

        return yOutput;
    }

    function getLiquidity(address lp) public view returns (uint256) {
        return liquidity[lp];
    }

    function ethToToken() public payable returns (uint256 tokenOutput) {
        require(msg.value > 0, "cannot swap 0 ETH");

        uint256 ethReserve = address(this).balance - msg.value;
        uint256 tokenReserve = token.balanceOf(address(this));
        
        tokenOutput = price(msg.value, ethReserve, tokenReserve);
        require(token.transfer(msg.sender, tokenOutput), "DEX: ethToToken swap failed");

        emit EthToTokenSwap(msg.sender, "Eth to Balloons", msg.value, tokenOutput);

        return tokenOutput;
    }

    function tokenToEth(uint256 tokenInput) public returns (uint256 ethOutput) {
        require(tokenInput > 0, "cannot swap 0 tokens");

        uint256 tokenReserve = token.balanceOf(address(this));
        uint256 ethReserve = address(this).balance;

        ethOutput = price(tokenInput, tokenReserve, ethReserve);
        require(token.transferFrom(msg.sender, address(this), tokenInput), "DEX: tokenToEth swap failed to send tokens");

        (bool sentEth, ) = msg.sender.call{value: ethOutput}("");
        require(sentEth, "DEX: tokenToEth swap failed to send ETH");
        
        emit TokenToEthSwap(msg.sender, "Balloons to ETH", tokenInput, ethOutput);

        return ethOutput;
    }

    function deposit() public payable returns (uint256 tokenDeposit) {
        require(msg.value > 0, "DEX: deposit failed, no ETH sent");

        uint256 ethReserve = address(this).balance - msg.value;
        uint256 tokenReserve = token.balanceOf(address(this));

        tokenDeposit = (msg.value * tokenReserve / ethReserve) + 1;

        require(token.transferFrom(msg.sender, address(this), tokenDeposit));

        uint256 liquidityMinted = msg.value * totalLiquidity / ethReserve;
        liquidity[msg.sender] += liquidityMinted;
        totalLiquidity += liquidityMinted;

        emit LiquidityProvided(msg.sender, liquidityMinted, msg.value, tokenDeposit);

        return tokenDeposit;
    }

    function withdraw(uint256 liquidityAmount) public returns (uint256 ethAmount, uint256 tokenAmount) {
        require(liquidity[msg.sender] >= liquidityAmount, "DEX: withdraw failed, sender does not have enough liquidity");

        uint256 ethReserve = address(this).balance;
        uint256 tokenReserve = token.balanceOf(address(this));
        ethAmount = liquidityAmount * ethReserve / totalLiquidity;
        tokenAmount = liquidityAmount * tokenReserve / totalLiquidity;

        liquidity[msg.sender] -= liquidityAmount;
        totalLiquidity -= liquidityAmount;

        (bool sent, ) = payable(msg.sender).call{ value: ethAmount }("");
        require(sent, "withdraw(): revert in transferring eth to you!");
        require(token.transfer(msg.sender, tokenAmount));

        emit LiquidityRemoved(msg.sender, liquidityAmount, ethAmount, tokenAmount);
        
        return (ethAmount, tokenAmount);
    }
}