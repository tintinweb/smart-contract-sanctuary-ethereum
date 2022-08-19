/**
 *Submitted for verification at Etherscan.io on 2022-08-19
*/

/**
*
* https://www.chungalungacoin.com/
* https://t.me/chungalunga
* https://twitter.com/chungalungacoin
*
*/

// SPDX-License-Identifier: MIT

// File: @uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol

pragma solidity >=0.5.0;


interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

// File: @uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol

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

// File: @uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol

pragma solidity >=0.6.2;


interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// File: @uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol

pragma solidity >=0.6.2;



interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// File: contracts/interfaces/ISafetyControl.sol

pragma solidity ^0.8.3;


/**
 * Enables safety and general transaction restrictions control.
 * 
 * Safety control :
 *  1. enabling/disabling anti pajeet system (APS). Can be called by admins to decide whether additional limitiations to sales should be imposed on not
 *  2. enabling/disabling trade control  system (TCS).
 *  3. enabling/disabling sending of tokens between accounts
 *  
 * General control:
 *  1. presale period. During presale all taxes are disabled
 *  2. trade. Before trade is open, no transactions are allowed
 *  3. LP state control. Before LP has been created, trade cannot be opened.
 * 
 */
interface ISafetyControl {

    /**
    * Defines state of APS after change of some of properties.
    * Properties:
    *   - enabled -> is APS enabled
    *   - thresh -> number of tokens(in wei). If one holds more that this number than he cannot sell more than 20% of his tokens at once
    *   - interval -> number of minutes between two consecutive sales
    */
    event APSStateUpdate (
        bool enabled,
        uint256 thresh,
        uint256 interval
    );
    
    /**
     * Enables/disables Anti pajeet system.
     * If enabled it will impose sale restrictions:
     *   - cannot sell more than 0.2% of total supply at once
	 *   - if owns more than 1% total supply:
	 *	    - can sell at most 20% at once (but not more than 0.2 of total supply)
	 *	    - can sell once every hour
     * 
     * emits APSStateUpdate
	 * 
	 * @param enabled   Defines state of APS. true or false
     */
    function setAPS(bool enabled) external;

    /**
     * Enables/disables Trade Control System.
     * If enabled it will impose sale restrictions:
     *   - max TX will be checked
	 *   - holders will not be able to purchase and hold more than _holderLimit tokens
	 *	 - single account can sell once every 2 mins
	 * 
	 * @param enabled   Defines state of TCS. true or false
     */
    function setTCS(bool enabled) external;

    /**
     * Defines new Anti pajeet system threshold in percentage. Value supports single digit, Meaning 10 means 1%.
     * Examples:
     *    to set 1%: 10
     *    to set 0.1%: 1
     * 
     * emits APSStateUpdate
     *
	 * @param thresh  New threshold in percentage of total supply. Value supports single digit.
     */
    function setAPSThreshPercent(uint256 thresh) external;

    /**
    * Defines new Anti pajeet system threshold in tokens. Minimal amount is 1000 tokens
    * 
    * emits APSStateUpdate
    *
	* @param thresh  New threshold in token amount
    */
    function setAPSThreshAmount(uint256 thresh) external;

    /**
    * Sets new interval user will have to wait in between two consecutive sales, if APS is enabled.
    * Default value is 1 hour
    * 
    * 
    * emits APSStateUpdate
    *
    * @param interval   interval between two consecutive sales, in minutes. E.g. 60 means 1 hour
    */
    function setAPSInterval(uint256 interval) external;
    
    /**
     * Upon start of presale all taxes are disabled
	 * Once presale is stopped, taxes are enabled once more
	 * 
	 * @param start     Defines state of Presale. started or stopped
     */
    function setPreSale(bool start) external;
    
    /**
     * Only once trading is open will transactions be allowed. 
     * Trading is disabled by default.
     * Liquidity MUST be proviided before trading can be opened
     *
     * @param on    true if trade is to be opened, otherwise false
     */
    function tradeCtrl(bool on) external;

    /**
    * Enables/disables sharing of tokens between accounts.
    * If enabled, sending tokens from one account to another is permitted. 
    * If disabled, sending tokens from one account to another will be blocked.
    *
    * @param enabled    True if sending between account is permitter, otherwise false      
    */
    function setAccountShare(bool enabled) external;

}
// File: contracts/interfaces/IFeeControl.sol

pragma solidity ^0.8.3;


/**
 * Defines control over:
 *  - who will be paying fees
 *  - when will fees be applied
 */
interface IFeeControl {
    event ExcludeFromFees (
        address indexed account,
        bool isExcluded
    );
    
    event TakeFeeOnlyOnSwap (
        bool enabled
    );
	
	event MinTokensBeforeSwapUpdated (
        uint256 minTokensBeforeSwap
    );
    
    /**
     * Exclude or include account in fee system. Excluded accounts don't pay any fee.
     *
     * @param account   Account address
     * @param exclude   If true account will be excluded, otherwise it will be included in fee
     */
    function feeControl(address account, bool exclude) external;

    /**
     * Is account excluded from paying fees?
     *
     * @param account   Account address
     */
    function isExcludedFromFee(address account) external view returns(bool);
    /**
     * Taking fee only on swaps.
     * Emits TakeFeeOnlyOnSwap(true) event.
     * 
     * @param onSwap    Take fee only on swap (true) or always (false)
     */
     function takeFeeOnlyOnSwap(bool onSwap) external;
     
    /**
	* Changes number of tokens collected before swap can be triggered
    * - emits MinTokensBeforeSwapUpdated event
    *
    * @param thresh     New number of tokens that must be collected before swap is triggered
	*/
	function changeSwapThresh(uint256 thresh) external;
}
// File: contracts/interfaces/IFee.sol

pragma solidity ^0.8.3;


/**
 * Defines Fees:
 *  - marketing
 *  - liquidity
 * All fees are using 1 decimal: 1000 means 100%, 100 means 10%, 10 means 1%, 1 means 0.1%
 */
interface IFee {
    /**
     * Struct of fees.
     */
    struct Fees {
      uint256 marketingFee;
      uint256 liquidityFee;
    }
    
    /**
     * Marketing wallet can be changed
     *
     * @param newWallet     Address of new marketing wallet
     */
    function changeMarketingWallet(address newWallet) external;

    /**
	* Changing fees. Distinguishes between buy and sell fees
    *
    * @param liquidityFee   New liquidity fee in percentage written as integer divisible by 1000. E.g. 5% => 0.05 => 50/1000 => 50
    * @param marketingFee   New marketing fee in percentage written as integer divisible by 1000. E.g. 5% => 0.05 => 50/1000 => 50
    * @param isBuy          Are fees for buy or not(for sale)
	*/
    function setFees(uint256 liquidityFee, uint256 marketingFee, bool isBuy)  external;
    
    /**
     * Control whether tokens collected from fees will be automatically swapped or not
     *
     * @param enable        True if swap should be enabled, otherwise false
     */
    function setSwapOfFeeTokens(bool enable) external;
}
// File: contracts/interfaces/IBlacklisting.sol

pragma solidity ^0.8.3;


/**
 * Some blacklisting/whitelisting functionalities:
 *  - adding account to list of blacklisted/whitelisted accounts
 *  - removing account from list of blacklisted/whitelisted accounts
 *  - check whether account is blacklisted/whitelisted accounts (against internal list)
 */
interface IBlacklisting {

    /**
    * Sent once address is blacklisted.
    */
    event BlacklistedAddress(
        address account
    );

    /**
     * Define account status in blacklist
	 *
	 * @param account   Account to be added or removed to/from blacklist
	 * @param add       Should account be added or removed from blacklist
     */
    function setBlacklist(address account, bool add) external;

    /**
     * Define account status in whitelist
	 *
	 * @param account   Account to be added or removed to/from whitelist
	 * @param add       Should account be added or removed from whitelist
     */
    function setWhitelist(address account, bool add) external;
    /**
     * Checks whether account is blacklisted
     */
    function isBlacklisted(address account) external view returns(bool);
	/**
     * Checks whether account is whitelisted
     */
    function isWhitelisted(address account) external view returns(bool);

    /**
    *  Define fee charged to blacklist. Fee supports singe decimal place, i.e it should be multiplied by 10 to get unsigned int: 100 means 10%, 10 means 1% and 1 means 0.1%
    */
    function setBlacklistFee(uint256 blacklistFee) external;
    
}
// File: @openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;


/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// File: contracts/interfaces/IChungalunga.sol

pragma solidity ^0.8.3;







interface IChungalunga is IERC20, IERC20Metadata, IBlacklisting, ISafetyControl, IFee, IFeeControl {
    
    event UpdateSwapV2Router (
        address indexed newAddress
    );
    
    event SwapAndLiquifyEnabledUpdated (
        bool enabled
    );

    event MarketingSwap (
        uint256 tokensSwapped,
        uint256 ethReceived,
        bool success
    );
    
    event SwapAndLiquify (
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    /**
    * Defines new state of properties TCS uses after some property was changed
    * Properties:
    *   - enabled ->is TCS system enabled
    *   - maxTxLimit -> max number of tokens (in wei) one can sell/buy at once
    *   - holderLimit -> max number of tokens one account can hold
    *   - interval ->interval between two consecutive sales in minutes
    */
    event TCSStateUpdate (
        bool enabled,
        uint256 maxTxLimit,
        uint256 holderLimit,
        uint256 interval
    );


    /**
    * (un)Setting *swapV2Pair address.
    *
    * @param pair       address of AMM pair
    * @param value      true if it's to be treated as AMM pair, otherwise false
    */
    function setLPP(address pair, bool value) external;
    
    /**
     * Max TX can be set either by providing percentage of total supply or exact amount.
     *
     * !MAX TX percentage MUST be between 1 and 10!
     * 
     * emits TCSStateUpdate
     *
     * @param maxTxPercent    new percentage used to calculate max number of tokens that can be transferred at the same time
     */
    function setMaxTxPercent(uint256 maxTxPercent) external;
    /**
     * max TX can be set either by providing percentage of total supply or exact amount.
     *
     * emits TCSStateUpdate
     *
     * @param maxTxAmount    new max number of tokens that can be transferred at the same time
     */
    function setMaxTxAmount(uint256 maxTxAmount) external;

    /**
     * Excluded accounts are not limited by max TX amount.
	 * Included accounts are limited by max TX amount.
     *
     * @param account   account address
     * @param exclude   true if account is to be excluded from max TX control. Otherwise false
     */
    function maxTxControl(address account, bool exclude) external;
    /**
     * Is account excluded from MAX TX limitations?
     *
     * @param account   account address
     * @return          true if account is excluded, otherwise false
     */
    function isExcludedFromMaxTx(address account) external view returns(bool);

    /**
    * Defines new limit to max token amount holder can possess.
    *
    * ! Holder limit MUST be greater than 0.5% total supply
    *
    * emits TCSStateUpdate
    *
    * @param limit      Max number of tokens one holder can possess
    */
    function setHolderLimit(uint256 limit) external;
    
    /**
     * Once set, LP provisioning from liquidity fees will start. 
     * Disabled by default. 
     * Must be called manually
     * - emits SwapAndLiquifyEnabledUpdated event
     *
     * @param enabled   true if swap is enabled, otherwise false
     */
    function setSwapAndLiquifyEnabled(bool enabled) external;
    
    /**
     * It will exclude sale helper router address and presale router address from fee's and rewards
     *
     * @param helperRouter  address of router used by helper 
     * @param presaleRouter address of presale router(contract) used by helper 
     */
    function setHelperSaleAddress(address helperRouter, address presaleRouter) external;
    
    /**
     * Any leftover coin balance on contract can be transferred (withdrawn) to chosen account.
     * Used to clear contract state.
     *
     * @param recipient     address of recipient
     */
    function withdrawLocked(address payable recipient) external;

    /**
     * Function to withdraw collected fees to marketing wallet in case automatic swap is disabled.
     * 
     * ! Will fail it swap is not disabled
     */
    function withdrawFees() external;
    
    /**
     * Updates address of V2 swap router
     * - emits UpdateSwapV2Router event
     *
     * @param newAddress    address of swap router
     */
    function updateSwapV2Router(address newAddress) external;

    /**
     * Starts whitelisted process. 
     * Whitelisted process will is valid for limited time only starting from current time. 
     * It will last for at most provided duration in minutes.
     *
     * @param duration      Duration in minutes. 
     */
    function wlProcess(uint256 duration) external;    
}
// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;




/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: @openzeppelin/contracts/utils/structs/EnumerableSet.sol


// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;


/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// File: @openzeppelin/contracts/utils/Strings.sol


// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// File: @openzeppelin/contracts/access/IAccessControl.sol


// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// File: @openzeppelin/contracts/access/IAccessControlEnumerable.sol


// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;


/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;




/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: @openzeppelin/contracts/access/AccessControl.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;





/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// File: @openzeppelin/contracts/access/AccessControlEnumerable.sol


// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;




/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view virtual override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view virtual override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account) internal virtual override {
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
    }
}

// File: contracts/Chungalunga.sol


pragma solidity ^0.8.3;
















/**
*
* https://www.chungalungacoin.com/
* https://t.me/chungalunga
* https://twitter.com/chungalungacoin
*
*/
contract Chungalunga is IChungalunga, ERC20, Ownable, AccessControlEnumerable {
    using SafeMath for uint256;
    using Address for address;
    using SafeERC20 for IERC20;

    event StateProgress (
        bool liquidityAdded,
        bool whitelistStarted,
        bool tradeOpened
    );

    event WHStart (
        uint256 duration
    );
    
    struct TaxedValues{
      uint256 amount;
      uint256 tAmount;
      uint256 tMarketing;
      uint256 tLiquidity;
    }
	
	struct SwapValues{
		uint256 tMarketing;
		uint256 tLiquidity;
		uint256 tHalfLiquidity;
		uint256 tTotal;
		uint256 swappedBalance;
	}
	
	// 
	// CONSTANTS
	//
	//uint256 private constant MAX = ~uint256(0);

	/* Using 18 decimals */
	uint8 private constant DECIMALS = 18;
	
	/* Total supply : 10_000_000_000 tokens (10 Billion) */
	uint256 private constant TOKENS_INITIAL = 10 * 10 ** 9;
	
	/* Minimal number of tokens that must be collected before swap can be triggered: 1000. Real threshold cannot be set below this value */
	uint256 private constant MIN_SWAP_THRESHOLD = 1 * 10 ** 3 * 10 ** uint256(DECIMALS);

    /* By what to divide calculated fee to compensate for supported decimals */
    uint256 private constant DECIMALS_FEES = 1000;
	
	/* Max amount of individual fee. 9.0% */
	uint256 private constant LIMIT_FEES = 90;
	
	/* Max amount of total fees. 10.0% */
	uint256 private constant LIMIT_TOTAL_FEES = 100;

    /* Number of minutes between 2 sales. 117 seconds */
    uint256 private constant TCS_TIME_INTERVAL = 117;
	
	/* Dead address */
	address private constant deadAddress = 0x000000000000000000000000000000000000dEaD;
	
	bytes32 private constant ADMIN_ROLE = keccak256("CL_ADMIN_ROLE");
    bytes32 private constant CTRL_ROLE = keccak256("CL_CTRL_ROLE");
	
	// 
	// MEMBERS
	//
	
	/* How much can each address allow for another address */
    mapping (address => mapping (address => uint256)) private _allowances;
	
	/* Map of addresses and whether they are excluded from fee */
    mapping (address => bool) private _isExcludedFromFee;
    
    /* Map of addresses and whether they are excluded from max TX check */
    mapping (address => bool) private _isExcludedFromMaxTx;
    
    /* Map of blacklisted addresses */
    mapping(address => bool) private _blacklist;
	
	/* Map of whitelisted addresses */
    mapping(address => bool) private _whitelist;
	
	/* Fee that will be charged to blacklisted accounts. Default is 90% */
	uint256 private _blacklistFee = 900;
    
    /* Marketing wallet address */
    address public marketingWalletAddress;

    /* Number of tokens currently pending swap for marketing */
    uint256 public tPendingMarketing;
    /* Number of tokens currently pending swap for liquidity */
    uint256 public tPendingLiquidity;
	
	/* Total tokens in wei. Will be created during initial mint in constructor */
    uint256 private _tokensTotal = TOKENS_INITIAL * 10 ** uint256(DECIMALS);
	
	/* Total fees taken so far */
    Fees private _totalTakenFees = Fees(
    {marketingFee: 0,
      liquidityFee: 0
    });
    
    Fees private _buyFees = Fees(
    {marketingFee: 40,
      liquidityFee: 10
    });
    
    Fees private _previousBuyFees = Fees(
     {marketingFee: _buyFees.marketingFee,
      liquidityFee: _buyFees.liquidityFee
    });
    
    Fees private _sellFees = Fees(
     {marketingFee: 40,
      liquidityFee: 10
    });
    
    Fees private _previousSellFees = Fees(
     {marketingFee: _sellFees.marketingFee,
      liquidityFee: _sellFees.liquidityFee
    });
    
	/* Swap and liquify safety flag */
    bool private _inSwapAndLiquify;
	
	/* Whether swap and liquify is enabled or not. Enabled by default */
    bool private _swapAndLiquifyEnabled = true;
    
	/* Anti Pajeet system */
    bool public apsEnabled = false;

    /* Trade control system */
    bool public tcsEnabled = false;

    /* Is whitelisted process active */
    bool private _whProcActive = false;

    /* When did whitelisted process start? */
    uint256 private _whStart = 0;

    /* Duration of whitelisted process */
    uint256 private _whDuration = 1;

    /* Account sharing system (sending of tokens between accounts. Disabled by default */
    bool private _accSharing = false;

    /* Anti Pajeet system threshold. If a single account holds more that that number of tokens APS limits will be applied */
    uint256 private _apsThresh = 20 * 10 ** 6 * 10 ** uint256(DECIMALS);

    /* Anti Pajeet system interval between two consecutive sales. In minutes. It defines when is the earlies user can sell depending on his last sale. Can be as low as 1 min. Defaults to 1440 mins (24 hours).  */
    uint256 private _apsInterval = 1440;
	
	/* Was LP provided? False by default */
	bool public liquidityAdded = false;
	
	/* Is trade open? False by default */
	bool public tradingOpen = false;
	
	/* Should tokens in marketing wallet be swapped automatically */
	bool private _swapMarketingTokens = true;
	
	/* Should fees be applied only on swaps? Otherwise, all transactions will be taxed */
	bool public feeOnlyOnSwap = false;
	
	/* Mapping of previous sales by address. Used to limit sell occurrence */
    mapping (address => uint256) private _previousSale;

    /* Mapping of previous buys by address. Used to limit buy occurrence */
    mapping (address => uint256) private _previousBuy;
    
	/* Maximal transaction amount -> cannot be higher than available token supply. It will be dynamically adjusted upon start */
    uint256 private _maxTxAmount = 0;

    /* Maximal amount single holder can possess -> cannot be higher than available token supply. Initially it will be set to 1% of total supply. It will be dynamically adjusted */
    uint256 private _maxHolderAmount = (_tokensTotal * 1) / 100;
	
	/* Min number of tokens to trigger sell and add to liquidity. Initially, 300k tokens */
    uint256 private _swapThresh =  300 * 10 ** 3 * 10 ** uint256(DECIMALS);

    /* Number of block when liquidity was added */
    uint256 private _lpCreateBlock = 0;

    /* Number of block when WH process was started */
    uint256 private _whStartBlock = 0;
    
    /* *Swap V2 router */
    IUniswapV2Router02 private _swapV2Router;
    
    /* Swap V2 pair */
    address private _swapV2Pair;
	
	/* Map of AMMs. Special rules apply when AMM is "to" */
	mapping (address => bool) public ammPairs;
    
    constructor () ERC20("Chungalunga", "CL") {
		
        _changeMarketingWallet(address(0x69cEC9B2FFDfE02481fBDC372Cd885FE83F3f694));
		
		_setupRole(CTRL_ROLE, msg.sender);
	
        // 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D is RouterV2 on mainnet
        _setupSwap(address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D));
        _setupExclusions();
		
		_setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
        _setRoleAdmin(CTRL_ROLE, ADMIN_ROLE);

        _setupRole(ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, address(this));

        _setupRole(CTRL_ROLE, msg.sender);
        _setupRole(CTRL_ROLE, address(this));
		
        _mint(msg.sender, _tokensTotal);
		
		transferOwnership(msg.sender);
    }
    
    //
    // EXTERNAL ACCESS
    //

	function addCTRLMember(address account) public virtual onlyRole(ADMIN_ROLE) {
        grantRole(CTRL_ROLE, account);
    }

    function removeCTRLMember(address account) public virtual onlyRole(ADMIN_ROLE) {
        revokeRole(CTRL_ROLE, account);
    }

    function renounceAdminRole() public virtual onlyRole(ADMIN_ROLE) {
        revokeRole(CTRL_ROLE, msg.sender);
        revokeRole(ADMIN_ROLE, msg.sender);
    }

    /**
    * Fetches how many tokens were taken as fee so far
    *
    * @return (marketingFeeTokens, liquidityFeeTokens)
    */
    function totalTakenFees() public view returns (uint256, uint256) {
        return (_totalTakenFees.marketingFee, _totalTakenFees.liquidityFee);
    }

    /**
    * Fetches current fee settings: buy or sell.
    *
    * @param isBuy  true if buy fees are requested, otherwise false
    * @return (marketingFee, liquidityFee)
    */
    function currentFees(bool isBuy) public view returns (uint256, uint256) {
        if(isBuy){
            return (_buyFees.marketingFee, _buyFees.liquidityFee);
        } else {
            return (_sellFees.marketingFee, _sellFees.liquidityFee);
        }
    }
    
    function feeControl(address account, bool exclude) override external onlyRole(CTRL_ROLE) {
        _isExcludedFromFee[account] = exclude;
    }
    
    /* Check whether account is exclude from fee */
    function isExcludedFromFee(address account) override external view returns(bool) {
        return _isExcludedFromFee[account];
    }
    
    function maxTxControl(address account, bool exclude) external override onlyRole(CTRL_ROLE) {
        _isExcludedFromMaxTx[account] = exclude;
    }
    
    function isExcludedFromMaxTx(address account) public view override returns(bool) {
        return _isExcludedFromMaxTx[account];
    }

    function setHolderLimit(uint256 limit) external override onlyRole(CTRL_ROLE) {
        require(limit > 0 && limit < TOKENS_INITIAL, "HOLDER_LIMIT1");

        uint256 new_limit = limit * 10 ** uint256(DECIMALS);

        // new limit cannot be less than 0.5%
        require(new_limit > ((_tokensTotal * 5) / DECIMALS_FEES), "HOLDER_LIMIT2");

        _maxHolderAmount = new_limit;

        emit TCSStateUpdate(tcsEnabled, _maxTxAmount, _maxHolderAmount, TCS_TIME_INTERVAL);
    }

    /* It will exclude sale helper router address and presale router address from fee's and rewards */
    function setHelperSaleAddress(address helperRouter, address presaleRouter) external override onlyRole(CTRL_ROLE) {
        _excludeAccount(helperRouter, true);
        _excludeAccount(presaleRouter, true);
    }

    /* Enable Trade control system. Imposes limitations on buy/sell */
    function setTCS(bool enabled) override external onlyRole(CTRL_ROLE) {
        tcsEnabled = enabled;

        emit TCSStateUpdate(tcsEnabled, _maxTxAmount, _maxHolderAmount, TCS_TIME_INTERVAL);
    }

    /**
     * Returns TCS state:
     * - max TX amount in wei
     * - max holder amount in wei
     * - TCS buy/sell interval in minutes
     */
    function getTCSState() public view onlyRole(CTRL_ROLE) returns(uint256, uint256, uint256) {
        return (_maxTxAmount, _maxHolderAmount, TCS_TIME_INTERVAL);
    }
    
	/* Enable anti-pajeet system. Imposes limitations on sale */
    function setAPS(bool enabled) override external onlyRole(CTRL_ROLE) {
        apsEnabled = enabled;

        emit APSStateUpdate(apsEnabled, _apsThresh, _apsInterval);
    }

	/* Sets new APS threshold. It cannot be set to more than 5% */
    function setAPSThreshPercent(uint256 thresh) override external onlyRole(CTRL_ROLE) {
        require(thresh < 50, "APS-THRESH-PERCENT");

        _apsThresh = _tokensTotal.mul(thresh).div(DECIMALS_FEES);

        emit APSStateUpdate(apsEnabled, _apsThresh, _apsInterval);
    }

    function setAPSThreshAmount(uint256 thresh) override external onlyRole(CTRL_ROLE) {
        require(thresh > 1000 && thresh < TOKENS_INITIAL, "APS-THRESH-AMOUNT");

        _apsThresh = thresh * 10 ** uint256(DECIMALS);

        emit APSStateUpdate(apsEnabled, _apsThresh, _apsInterval);
    }

    /* Sets new min APS sale interval. In minutes */
    function setAPSInterval(uint256 interval) override external onlyRole(CTRL_ROLE) {
        require(interval > 0, "APS-INTERVAL-0");

        _apsInterval = interval;

        emit APSStateUpdate(apsEnabled, _apsThresh, _apsInterval);
    }

    /**
     * Returns APS state:
     * - threshold in tokens
     * - interval in minutes
     */
    function getAPSState() public view onlyRole(CTRL_ROLE) returns(uint256, uint256) {
        return (_apsThresh, _apsInterval);
    }

    /* wnables/disables account sharing: sending of tokens between accounts */
    function setAccountShare(bool enabled) override external onlyRole(CTRL_ROLE) {
        _accSharing = enabled;
    }
    
	/* Changing marketing wallet */
    function changeMarketingWallet(address account) override external onlyRole(CTRL_ROLE) {
        _changeMarketingWallet(account);
    }
    
    function setFees(uint256 liquidityFee, uint256 marketingFee, bool isBuy) external override onlyRole(CTRL_ROLE) {
        // fees are setup so they can not exceed 10% in total
        // and specific limits for each one.
        require(marketingFee + liquidityFee <= LIMIT_TOTAL_FEES, "FEE-MAX");
       
        _setMarketingFeePercent(marketingFee, isBuy);
        _setLiquidityFeePercent(liquidityFee, isBuy);
    }
   
    /* Define MAX TX amount. In percentage of total supply */
    function setMaxTxPercent(uint256 maxTxPercent) override external onlyRole(CTRL_ROLE) {
        require(maxTxPercent <= 1000, "MAXTX_PERC_LIMIT");
        _maxTxAmount = _tokensTotal.mul(maxTxPercent).div(DECIMALS_FEES);

        emit TCSStateUpdate(tcsEnabled, _maxTxAmount, _maxHolderAmount, TCS_TIME_INTERVAL);
    }
    
	/* Define MAX TX amount. In token count */
    function setMaxTxAmount(uint256 maxTxAmount) override external onlyRole(CTRL_ROLE) {
        require(maxTxAmount <= TOKENS_INITIAL, "MAXTX_AMNT_LIMIT");
        _maxTxAmount = maxTxAmount * 10 ** uint256(DECIMALS);

        emit TCSStateUpdate(tcsEnabled, _maxTxAmount, _maxHolderAmount, TCS_TIME_INTERVAL);
    }

    /* Enable LP provisioning */
    function setSwapAndLiquifyEnabled(bool enabled) override external onlyRole(CTRL_ROLE) {
        _swapAndLiquifyEnabled = enabled;
        emit SwapAndLiquifyEnabledUpdated(enabled);
    }
	
	/* Define new swap threshold. Cannot be less than MIN_SWAP_THRESHOLD: 1000 tokens */
	function changeSwapThresh(uint256 thresh) override external onlyRole(CTRL_ROLE){
        uint256 newThresh = thresh * 10 ** uint256(DECIMALS);

		require(newThresh > MIN_SWAP_THRESHOLD, "THRESH-LOW");

		_swapThresh = newThresh;
	}

    /* take a look at current swap threshold */
    function swapThresh() public view onlyRole(CTRL_ROLE) returns(uint256) {
        return _swapThresh;
    }
    
	/* Once presale is done and LP is created, trading can be enabled for all. Only once this is set will normal transactions be completed successfully */
    function tradeCtrl(bool on) override external onlyRole(CTRL_ROLE) {
        require(liquidityAdded, "LIQ-NONE");
       _tradeCtrl(on);
    }

    function _tradeCtrl(bool on) internal {
        tradingOpen = on;

        emit StateProgress(true, true, true);
    }

    function wlProcess(uint256 duration) override external onlyRole(CTRL_ROLE) {
        require(liquidityAdded && _lpCreateBlock > 0, "LIQ-NONE");
        require(duration > 1, "WHT-DUR-LOW");

        _whStartBlock = block.number;

        _whProcActive = true;
        _whDuration = duration;
        _whStart = block.timestamp;

        // set MAX TX limit to 10M tokens
        _maxTxAmount = 10 * 10 ** 6 * 10 ** uint256(DECIMALS);

        // make sure trading is closed
        tradingOpen = false;

        // enable aps
        apsEnabled = true;

        // enable tcs
        tcsEnabled = true;

        // return APS thresh to 20M
        _apsThresh = 20 * 10 ** 6 * 10 ** uint256(DECIMALS);

        // emit current state
        emit StateProgress(true, true, false);

        // emit start of whitelist process
        emit WHStart(duration);
    }

	/* Sets should tokens collected through fees be automatically swapped to ETH or not */
    function setSwapOfFeeTokens(bool enabled) override external onlyRole(CTRL_ROLE) {
        _swapMarketingTokens = enabled;
    }
    
	/* Sets should fees be taken only on swap or on all transactions */
    function takeFeeOnlyOnSwap(bool onSwap) override external onlyRole(CTRL_ROLE) {
        feeOnlyOnSwap = onSwap;
        emit TakeFeeOnlyOnSwap(feeOnlyOnSwap);
    }
	
	/* Should be called once LP is created. Manually or programatically (by calling #addInitialLiquidity()) */
	function defineLiquidityAdded() public onlyRole(CTRL_ROLE) {
        liquidityAdded = true;

        if(_lpCreateBlock == 0) {
            _lpCreateBlock = block.number;
        }

        emit StateProgress(true, false, false);
    }
    
	/* withdraw any ETH balance stuck in contract */
    function withdrawLocked(address payable recipient) external override onlyRole(CTRL_ROLE) {
        require(recipient != address(0), 'ADDR-0');
        require(address(this).balance > 0, 'BAL-0');
	
        uint256 amount = address(this).balance;
        // address(this).balance = 0;
    
        (bool success,) = payable(recipient).call{value: amount}('');
    
        if(!success) {
          revert();
        }
    }

    function withdrawFees() external override onlyRole(CTRL_ROLE) {
        require(!_swapAndLiquifyEnabled, "WITHDRAW-SWAP");

        super._transfer(address(this), marketingWalletAddress, balanceOf(address(this)));

        tPendingMarketing = 0;
        tPendingLiquidity = 0;
    }
    
    function isBlacklisted(address account) external view override returns(bool) {
        return _blacklist[account];
    }
	
	function isWhitelisted(address account) external view override returns(bool) {
        return _whitelist[account];
    }
    
    function setBlacklist(address account, bool add) external override onlyRole(CTRL_ROLE) {
		_setBlacklist(account, add);
    }
    
    function setWhitelist(address account, bool add) external override onlyRole(CTRL_ROLE) {
        _whitelist[account] = add;
    }
	
	function setBlacklistFee(uint256 blacklistFee) external override onlyRole(CTRL_ROLE) {
		_blacklistFee = blacklistFee;
	}

    function _setBlacklist(address account, bool add) private {
        _blacklist[account] = add;

        emit BlacklistedAddress(account);
    }

    function bulkWhitelist(address[] calldata addrs, bool add) external onlyRole(CTRL_ROLE) {
        for (uint i=0; i<addrs.length; i++){
            _whitelist[addrs[i]] = add;
        }
    }

    function bulkBlacklist(address[] calldata addrs, bool add) external onlyRole(CTRL_ROLE) {
        for (uint i=0; i<addrs.length; i++){
            _blacklist[addrs[i]] = add;
        }
    }

    function provisionPrivate(address[] calldata addrs, uint256 amount) external onlyRole(CTRL_ROLE) {
        for (uint i=0; i<addrs.length; i++){
            super.transfer(addrs[i], amount);
        }
    }
	
	/* To be called whan presale begins/ends. It will remove/add fees */
	function setPreSale(bool start) external override onlyRole(CTRL_ROLE) {
		if(start) { // presale started
			// remove all fees (buy)
			_removeAllFee(true);
			// remove all fees (sell)
			_removeAllFee(false);
		} else { // presale stopped
			// restore all fees (buy)
			_restoreAllFee(true);
			// restore all fees (sell)
			_restoreAllFee(false);
		}
    }
    
    function updateSwapV2Router(address newAddress) external override onlyRole(CTRL_ROLE) {
        require(newAddress != address(0), "R2-1");
        _setupSwap(newAddress);
    }
    
     //to receive ETH from *swapV2Router when swaping. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    //fallback() external payable {}
    
    //
    // PRIVATE ACCESS
    //
    
    function _setupSwap(address routerAddress) private {
        // Uniswap V2 router: 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        
        _swapV2Router = IUniswapV2Router02(routerAddress);
    
        // create a swap pair for this new token
        _swapV2Pair = IUniswapV2Factory(_swapV2Router.factory()).createPair(address(this), _swapV2Router.WETH());

		_setAMMPair(address(_swapV2Pair), true);

        //_approve(owner(), address(_swapV2Router), type(uint256).max);

        _isExcludedFromMaxTx[address(_swapV2Router)] = true;

        _approve(owner(), address(_swapV2Router), type(uint256).max);
        ERC20(address(_swapV2Router.WETH())).approve(address(_swapV2Router), type(uint256).max);
        ERC20(address(_swapV2Router.WETH())).approve(address(this), type(uint256).max);
		
		emit UpdateSwapV2Router(routerAddress);
    }
	
	function setLPP(address pair, bool value) external override onlyRole(CTRL_ROLE) {
        _setAMMPair(pair, value);

        if (!liquidityAdded) {
            defineLiquidityAdded();
        }
    }

    function _setAMMPair(address pair, bool value) private {
        ammPairs[pair] = value;

        _isExcludedFromMaxTx[pair] = value;
    }
    
    function _excludeAccount(address addr, bool ex) private {
         _isExcludedFromFee[addr] = ex;
         _isExcludedFromMaxTx[addr] = ex;
    }
    
    function _setupExclusions() private {
        _excludeAccount(msg.sender, true);
        _excludeAccount(address(this), true);
        _excludeAccount(owner(), true);
		_excludeAccount(deadAddress, true);
        _excludeAccount(marketingWalletAddress, true);
    }
    
    function _changeMarketingWallet(address addr) internal {
        require(addr != address(0), "ADDR-0");
        _excludeAccount(marketingWalletAddress, false);
		
        marketingWalletAddress = addr;
		
		_excludeAccount(addr, true);
    }
    
    function _isBuy(address from) internal view returns(bool) {
        //return from == address(_swapV2Pair) || ammPairs[from];
        return ammPairs[from];
    }
    
    function _isSell(address to) internal view returns(bool) {
        //return to == address(_swapV2Pair) || ammPairs[to];
        return ammPairs[to];
    }
    
    function _checkTxLimit(address from, address to, uint256 amount) internal view {
        if (_isBuy(from)) { // buy
			require(amount <= _maxTxAmount || _isExcludedFromMaxTx[to], "TX-LIMIT-BUY");
        } else  if (_isSell(to)) { // sell
            require(amount <= _maxTxAmount || _isExcludedFromMaxTx[from], "TX-LIMIT-SELL");
        } else { // transfer
			require(amount <= _maxTxAmount || (_isExcludedFromMaxTx[from] || _isExcludedFromMaxTx[to]), "TX-LIMIT");
        }
    }
    
    function _setMarketingFeePercent(uint256 fee, bool isBuy) internal {
        require(fee <= LIMIT_FEES, "FEE-LIMIT-M");
        
        if(isBuy){
            _previousBuyFees.marketingFee = _buyFees.marketingFee;
            _buyFees.marketingFee = fee;
        } else {
            _previousSellFees.marketingFee = _sellFees.marketingFee;
            _sellFees.marketingFee = fee;
        }
    }
    
    function _setLiquidityFeePercent(uint256 liquidityFee, bool isBuy) internal {
        require(liquidityFee <= LIMIT_FEES, "FEE-LIMIT-L");
        
         if(isBuy){
            _previousBuyFees.liquidityFee = _buyFees.liquidityFee;
            _buyFees.liquidityFee = liquidityFee;
        } else {
            _previousSellFees.liquidityFee = _sellFees.liquidityFee;
            _sellFees.liquidityFee = liquidityFee;
        }
    }

    function _getValues(uint256 amount, bool isBuy) private view returns (TaxedValues memory totalValues) {
        totalValues.amount = amount;
        totalValues.tMarketing = _calculateMarketingFee(amount, isBuy);
        totalValues.tLiquidity = _calculateLiquidityFee(amount, isBuy);
        
        totalValues.tAmount = amount.sub(totalValues.tMarketing).sub(totalValues.tLiquidity);
        
        return totalValues;
    }
    
    function _calculateMarketingFee(uint256 amount, bool isBuy) private view returns (uint256) {
        if(isBuy){
            return _buyFees.marketingFee > 0 ?
                amount.mul(_buyFees.marketingFee).div(DECIMALS_FEES) : 0;
        } else {
            return _sellFees.marketingFee > 0 ?
                amount.mul(_sellFees.marketingFee).div(DECIMALS_FEES) : 0;
        }
    }

    function _calculateLiquidityFee(uint256 amount, bool isBuy) private view returns (uint256) {
        if(isBuy){
            return _buyFees.liquidityFee > 0 ?
                amount.mul(_buyFees.liquidityFee).div(DECIMALS_FEES) : 0;
        } else {
            return _sellFees.liquidityFee > 0 ?
                amount.mul(_sellFees.liquidityFee).div(DECIMALS_FEES) : 0; 
        }
    }
    
    function _removeAllFee(bool isBuy) private {
        if(isBuy){
            _previousBuyFees = _buyFees;
            _buyFees.liquidityFee = 0;
            _buyFees.marketingFee = 0;
        } else {
            _previousSellFees = _sellFees;
            _sellFees.liquidityFee = 0;
            _sellFees.marketingFee = 0;
        }
    }
    
    function _restoreAllFee(bool isBuy) private {
        if(isBuy){
            _buyFees = _previousBuyFees;
        } else {
            _sellFees = _previousSellFees;
        }
    }
    
    /**
    * Transfer codes:
    *   - FROM-ADDR-0 -> from address is 0
    *   - TO-ADDR-0 -> to address is 0
    *   - ADDR-0 -> if some address is 0 
    *   - CNT-0 -> if some amount is 0
    */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "FROM-ADDR-0");
        require(to != address(0), "TO-ADDR-0");
        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        if(_blacklist[from] || _blacklist[to]) {
			_blacklistDefense(from, to, amount);
            return;
        }

        if (!_inSwapAndLiquify) {

            // whitelist process check
            _whitelistProcessCheck();

            // general rules of conduct
            _generalRules(from, to, amount);

            // TCS  (Trade Control System) check
            _tcsCheck(from, to, amount);
            
            // APS (Anti Pajeet System) check
            _apsCheck(from, to, amount);

            // DLP (Delayed Provision)
            _delayedProvision(from, to);
        }

        //indicates if fee should be deducted from transfer
        bool takeFee = !_inSwapAndLiquify;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to] ) {
            takeFee = false;
        }

        /*
        // take fee only on swaps depending on input flag
        if (feeOnlyOnSwap && !_isBuy(from) && !_isSell(to)) {
            takeFee = false;
        }
        */
        
        //transfer amount, it will take tax, special, liquidity fee
        _tokenTransfer(from, to, amount, takeFee);
    }

    function _defense(address from, address to, uint256 amount, uint256 fee) private {
		uint256 tFee = amount * fee / DECIMALS_FEES;
		uint256 tRest = amount - tFee;

        super._transfer(from, address(this), tFee);
        super._transfer(from, to, tRest);

        uint256 totalFeeP = 0;
        uint256 mFee = 0;
        uint256 lFee = 0;
        if (_isBuy(from)) {
            totalFeeP = _buyFees.liquidityFee + _buyFees.marketingFee;
            if (totalFeeP > 0) {
                lFee = _buyFees.liquidityFee > 0 ? tFee * _buyFees.liquidityFee / totalFeeP : 0;
                mFee = tFee - lFee;
            }
        } else {
            totalFeeP = _sellFees.liquidityFee + _sellFees.marketingFee;
            if (totalFeeP > 0) {
                lFee = _sellFees.liquidityFee > 0 ? tFee * _sellFees.liquidityFee / totalFeeP : 0;
                mFee = tFee - lFee;
            }
        }

        if (totalFeeP > 0) {
            tPendingMarketing += mFee;
            tPendingLiquidity += lFee;
            _totalTakenFees.marketingFee += mFee;
            _totalTakenFees.liquidityFee += lFee;
        }
		
	}
	
	function _blacklistDefense(address from, address to, uint256 amount) private {
        _defense(from, to, amount, _blacklistFee);		
	}

    function _whitelistProcessCheck() private {
        if (_whProcActive) {

            require(block.number - _whStartBlock >= 2, "SNIPER-WL");

            if (_whStart + (_whDuration * 1 minutes) < block.timestamp) {
                // whitelist process has expired. Disable it
                _whProcActive = false;

            	// set MAX TX limit to 15M tokens
                _maxTxAmount = 15 * 10 ** 6 * 10 ** uint256(DECIMALS);

                // open trading
                _tradeCtrl(true);
            }
        }
    }

    /**
    * GENERAL codes:
    *   - ACC-SHARE -> account sharing is disabled
    *   - TX-LIMIT-BUY -> transaction limit has been reached during buy
    *   - TX-LIMIT-SELL -> transaction limit has been reached during sell
    *   - TX-LIMIT -> transaction limit has been reached during share
    */
    function _generalRules(address from, address to, uint256 amount) private view {

        // acc sharing
        require(_accSharing || _isBuy(from) || _isSell(to) || from == owner() || to == owner(), "ACC-SHARE"); // either acc sharing is enabled, or at least one of from-to is AMM

        // anti bot
        if (!tradingOpen && liquidityAdded && from != owner() && to != owner()) {

            require(block.number - _lpCreateBlock >= 3, "SNIPER-LP" );

            require(_whProcActive && (_whitelist[from] || _whitelist[to]), "WH-ILLEGAL");
        }

        // check TX limit
        _checkTxLimit(from, to, amount);

    }
    
    
    /**
    * TCS codes:
    *   - TCS-HOLDER-LIMIT -> holder limit is exceeded
    *   - TCS-TIME -> must wait for at least 2min before another sell
    */
    function _tcsCheck(address from, address to, uint256 amount) private view {
        //
        // TCS (Trade Control System):
        // 1. trade imposes MAX tokens that single holder can possess
        // 2. buy/sell time limits of 2 mins
		//

        if (tcsEnabled) {

            // check max holder amount limit
            if (_isBuy(from)) {
                require(amount + balanceOf(to) <= _maxHolderAmount, "TCS-HOLDER-LIMIT");
            } else if(!_isSell(to)) {
                require(amount + balanceOf(to) <= _maxHolderAmount, "TCS-HOLDER-LIMIT");
            }

            // buy/sell limit
            if (_isSell(to)) {
                require( (_previousSale[from] + (TCS_TIME_INTERVAL * 1 seconds)) < block.timestamp, "TCS-TIME");
            } else if (_isBuy(from)) {
                require( (_previousBuy[to] + (TCS_TIME_INTERVAL * 1 seconds)) < block.timestamp, "TCS-TIME");
            } else {
                // token sharing 
                require( (_previousSale[from] + (TCS_TIME_INTERVAL * 1 seconds)) < block.timestamp, "TCS-TIME");
                require( (_previousBuy[to] + (TCS_TIME_INTERVAL * 1 seconds)) < block.timestamp, "TCS-TIME");
            }
        }
    }
    
    /**
    * APS codes:
    *   - APS-BALANCE -> cannot sell more than 20% of current balance if holds more than apsThresh tokens
    *   - APS-TIME -> must wait until _apsInterval passes before another sell
    */
    function _apsCheck(address from, address to, uint256 amount) view private {
        //
		// APS (Anti Pajeet System):
		// 1. can sell at most 20% of tokens in possession at once if holder has more than _apsThresh tokens
		// 2. can sell once every _apsInterval (60) minutes
		//
		
        if (apsEnabled) {
            
            // Sell in progress
            if(_isSell(to)) {

                uint256 fromBalance = balanceOf(from);	// how many tokens does account own

                // if total number of tokens is above threshold, only 20% of tokens can be sold at once!
                if(fromBalance >= _apsThresh) {
                    require(amount < (fromBalance / (5)), "APS-BALANCE");
                }

                // at most 1 sell every _apsInterval minutes (60 by default)
                require( (_previousSale[from] + (_apsInterval * 1 minutes)) < block.timestamp, "APS-TIME");
            }
			
        }
    }
	
	function _swapAndLiquifyAllFees() private {
        uint256 contractBalance = balanceOf(address(this));

        uint256 tTotal = tPendingLiquidity + tPendingMarketing;
        
        if(contractBalance == 0 || tTotal == 0 || tTotal < _swapThresh) {return;}
        
		uint256 tLiqHalf = tPendingLiquidity > 0 ? contractBalance.mul(tPendingLiquidity).div(tTotal).div(2) : 0;
        uint256 amountToSwapForETH = contractBalance.sub(tLiqHalf);
        
        // starting contract's ETH balance
        uint256 initialBalance = address(this).balance;

		// swap tokens for ETH
        _swapTokensForEth(amountToSwapForETH, address(this));
		
		// how much ETH did we just swap into?
        uint256 swappedBalance = address(this).balance.sub(initialBalance);
		
		// calculate ETH shares
		uint256 cMarketing = swappedBalance.mul(tPendingMarketing).div(tTotal);
        uint256 cLiq = swappedBalance - cMarketing;

		// liquify
		if(tPendingLiquidity > 0 && cLiq > 0){
		
			//
			// DLP (Delayed Liquidity Provision):
			// - adding to liquidity only after some threshold has been met to avoid LP provision on every transaction
			//  * NOTE: liquidity provision MUST be enabled first
			//  * NOTE: don't enrich liquidity if sender is swap pair
			//
		
			// add liquidity to LP
			_addLiquidity(tLiqHalf, cLiq);
        
			emit SwapAndLiquify(tLiqHalf, cLiq, tPendingLiquidity.sub(tLiqHalf));
		}
        
		// transfer to marketing
        (bool sent,) = address(marketingWalletAddress).call{value: cMarketing}("");
        emit MarketingSwap(tPendingMarketing, cMarketing, sent);

         // reset token count
        tPendingLiquidity = 0;
        tPendingMarketing = 0;
    }
    
    function _delayedProvision(address from, address to) private {

        if (
            !_inSwapAndLiquify &&
            !_isBuy(from) &&
            _swapAndLiquifyEnabled &&
            !_isExcludedFromFee[from] &&
            !_isExcludedFromFee[to]
        ) {
            _inSwapAndLiquify = true;
			_swapAndLiquifyAllFees();
            _inSwapAndLiquify = false;
		}
    }

    function _swapTokensForEth(uint256 tokenAmount, address account) private {
        // generate the uniswap pair path of token -> weth
		address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _swapV2Router.WETH();

        _approve(address(this), address(_swapV2Router), tokenAmount);

        // make the swap
        _swapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            account,
            block.timestamp
        );
    }

    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(_swapV2Router), tokenAmount);

        // add the liquidity
        _swapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            deadAddress,
            block.timestamp
        );
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
        bool isBuy = _isBuy(sender);

        uint256 fees = 0;
        if (takeFee) {
            TaxedValues memory totalValues = _getValues(amount, isBuy);

            fees = totalValues.tMarketing + totalValues.tLiquidity;

            if(fees > 0) {

                tPendingMarketing += totalValues.tMarketing;
                tPendingLiquidity += totalValues.tLiquidity;

                _totalTakenFees.marketingFee += totalValues.tMarketing;
                _totalTakenFees.liquidityFee += totalValues.tLiquidity;

                super._transfer(sender, address(this), fees);

                amount -= fees;
            }
        }

        if (isBuy) {
            _previousBuy[recipient] = block.timestamp;
        } else if(_isSell(recipient)) {
            _previousSale[sender] = block.timestamp;
        } else {
            // token sharing
            _previousBuy[recipient] = block.timestamp;
            _previousSale[sender] = block.timestamp;
        }

        super._transfer(sender, recipient, amount);

    }
    
}