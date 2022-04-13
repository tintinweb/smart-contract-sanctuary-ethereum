/**
 *Submitted for verification at Etherscan.io on 2022-04-12
*/

// Sources flattened with hardhat v2.8.4 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/[email protected]

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
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


// File @uniswap/v2-core/contracts/interfaces/[email protected]

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}


// File contracts/ValueShuttle.sol

pragma solidity >=0.8;
/// @notice Proof of Concept of contract used to account for totalValue accumulated during
/// rebase. `Bonding` should direct all bonded assets to this contract. When rebase
/// time arrives, `Staking` retrieves the totalValue accumulated and sends totalValue to
/// Treasury.
contract ValueShuttle {

    /* -------------------------------------------------------------------------- */
    /*                                   EVENTS                                   */
    /* -------------------------------------------------------------------------- */

    event ValueShuttled(
        address indexed caller, 
        uint256 stablesToLp, 
        uint256 lpReceived, 
        uint256 totalAccrued
    );

    /* -------------------------------------------------------------------------- */
    /*                                   STORAGE                                  */
    /* -------------------------------------------------------------------------- */

    /// @notice account that received forwarded DAI + CNV/DAI LP
    address public treasury;

    /// @notice concave staking contract
    address public staking;
    
    /// @notice concave accrual bonds contract
    address public bonding;

    /// @notice concave token
    address public CNV;

    /// @notice dai token
    address public DAI;
    
    /// @notice CNV/DAI liquidity pair
    address public DAI_CNV_PAIR;
    
    /// @notice percent in bips of DAI balance to convert to LP
    uint256 public percentToConvert = 3_000; // bips

    /* -------------------------------------------------------------------------- */
    /*                                CONSTRUCTION                                */
    /* -------------------------------------------------------------------------- */

    function initialize(
        address _staking, 
        address _treasury, 
        address _CNV,
        address _DAI, 
        address _DAI_CNV_PAIR, 
        address _bonding
    ) external {
        staking = _staking;
        
        treasury = _treasury;
        
        DAI = _DAI;
        
        CNV = _CNV;
        
        DAI_CNV_PAIR = _DAI_CNV_PAIR;

        bonding = _bonding;
    }

    /* -------------------------------------------------------------------------- */
    /*                               SHUTTLE LOGIC                                */
    /* -------------------------------------------------------------------------- */

    /// @notice staking contract calls this during rebase, `totalValue` is the totalValue accumulated during rebase.
    function shuttleValue() external returns (uint256 totalValue) {
        // make sure caller is staking contract
        require(msg.sender == staking, "!STAKING");
        
        // fetch balance of DAI in this contract
        totalValue = IERC20(DAI).balanceOf(address(this));

        // calculate total amount of DAI that need to be converted to lp
        uint256 amountForLP = totalValue * percentToConvert / 1e4;
        
        // calculate halves to be converted into LP
        uint256 half0 = amountForLP >> 1;
        uint256 half1 = amountForLP - half0;

        // swap first half into CNV
        uint256 cnvAmount = swap(half0, DAI);

        // add liquidity using other half and CNV from above swap
        uint256 lpReceived = addLiquidity(DAI_CNV_PAIR, half1, cnvAmount);
        
        // transfer remaining DAIcoin balance from this contract to treasury
        IERC20(DAI).transfer(treasury, IERC20(DAI).balanceOf(address(this)));
        
        // T2 - Are events emitted for every storage mutating function?
        emit ValueShuttled(msg.sender, half0, lpReceived, totalValue);
    }

    function setPercentToConvert(uint256 _percentToConvert) external {
        
        require(msg.sender == bonding, "!bonding");

        percentToConvert = _percentToConvert;
    }

    /* -------------------------------------------------------------------------- */
    /*                                 VIEW LOGIC                                 */
    /* -------------------------------------------------------------------------- */

    function valueAccumulated() external view returns(uint256) {
        return IERC20(DAI).balanceOf(address(this));
    }

    // NOTE testing this will likely fail because it relies 
    // on the fact that our mainet CNV address is less than DAI address

    function swap(
        uint256 amountIn, 
        address fromToken
    ) internal returns (uint256 amountOut) {
        // interface pair contract
        IUniswapV2Pair pair = IUniswapV2Pair(DAI_CNV_PAIR);
        // fetch CNV, DAI reserves
        (uint112 reserve0, uint112 reserve1,) = pair.getReserves();
        // calculate amountIn accouting for fee
        uint256 amountInWithFee = amountIn * 9975;
        // calculate amountOut while maintaining equality
        amountOut = amountInWithFee * reserve0 / (reserve1 * 1e4 + amountInWithFee);
        // transfer input to pair
        safeTransfer(fromToken, address(pair), amountIn);
        // swap with output sent to treasury
        pair.swap(amountOut, 0, address(this), new bytes(0));
    }
    
    // NOTE testing this will likely fail because it relies 
    // on the fact that our mainet CNV address is less than DAI address

    function addLiquidity(
        address depositToken, 
        uint256 maxAmountIn0, 
        uint256 maxAmountIn1
    ) internal returns (uint256) {
        // fetch reserves from pair
        (uint112 reserve0, uint112 reserve1,) = IUniswapV2Pair(address(depositToken)).getReserves();
        // calculate DAI amountIn
        uint256 amountIn1 = maxAmountIn0 * reserve1 / reserve0;
        // if DAI amountIn is greater than max DAI amountIn
        if (amountIn1 > maxAmountIn1) {
            // DAI amountIn is equal to maxAmountIn1 (DAI max amount)
            amountIn1 = maxAmountIn1;
            // quote maxAmountIn for CNV
            maxAmountIn0 = maxAmountIn1 * reserve0 / reserve1;
        }
        // transfer CNV + DAI to pair to be converted into LP tokens
        safeTransfer(CNV, depositToken, maxAmountIn0);
        safeTransfer(DAI, depositToken, amountIn1);
        // mint LP tokens to the treasury
        return IUniswapV2Pair(depositToken).mint(treasury);
    }

    function safeTransfer(address token, address to, uint256 totalValue) internal {
        require(IERC20(token).transfer(to, totalValue), "SwapLib::TRANSFER_FROM_FAILED");
    }
}