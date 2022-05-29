/**
 *Submitted for verification at Etherscan.io on 2022-05-29
*/

// File: contracts\interfaces\ISlashCore.sol

pragma solidity ^0.8.0;

interface ISlashCore {
    /**
     * @dev Get in-amount to get out-amount of receive token
     * @return in-amount of token
     */
    function getAmountIn(
        address merchant_,
        address payingToken_,
        uint256 amountOut_,
        address[] memory path_,
        bytes memory reserved_
    ) external view returns (uint256);

    /**
     * @dev Get out-amount from the in-amount of token
     * @return out-amount of receive token
     */
    function getAmountOut(
        address merchant_,
        address payingToken_,
        uint256 amountIn_,
        address[] memory path_,
        bytes memory reserved_
    ) external view returns (uint256);

    /**
     * @dev Get fee amount from the out-amount of token
     * @param feePath_: swap path from _receiveToken to WETH
     * @return totalFee: in Ether
     * @return donationFee: in Ether
     */
    function getFeeAmount(
        address merchant_,
        address account_,
        uint256 amountOut_,
        address[] memory feePath_,
        bytes memory reserved_
    ) external view returns (uint256, uint256);

    /**
     * @dev Submit transaction
     * @param feePath_: swap path from _payingTokenAddress to WETH
     * @param path_: swap path from _payingTokenAddress to receive token
     * @param amountIn_: user paid amount of input token
     * @param requiredAmountOut_: required amount of output token
     * @return refTokBal Redundant token amount that is refunded to the user
     * @return refFeeBal Redundant fee amount that is refunded to the user
     */
    function submitTransaction(
        address merchant_,
        address account_,
        address payingToken_,
        uint256 amountIn_,
        uint256 requiredAmountOut_,
        address[] memory path_,
        address[] memory feePath_,
        bytes memory reserved_
    )
        external
        payable
        returns (
            uint256, /** refTokBal */
            uint256 /** refFeeBal */
        );
}

// File: contracts\interfaces\IStakingPool.sol

pragma solidity ^0.8.0;

interface IStakingPool {
    function balanceOf(address _account) external view returns (uint256);

    function getShare(address _account) external view returns (uint256);
}

// File: contracts\interfaces\IAffiliatePool.sol

pragma solidity ^0.8.0;

interface IAffiliatePool {
    /**
     * deposit affiliate fee
     * _account: affiliator wallet address
     * _amount: deposit amount
     */
    function deposit(address _account, uint256 _amount) external returns (bool);

    /**
     * withdraw affiliate fee
     * withdraw sender's affiliate fee to sender address
     * _amount: withdraw amount. withdraw all amount if _amount is 0
     */
    function withdraw(uint256 _amount) external returns (bool);

    /**
     * get affiliate fee balance
     * _account: affiliator wallet address
     */
    function balanceOf(address _account) external view returns (uint256);


    /**
     * initialize contract (only owner)
     * _tokenAddress: token contract address of affiliate fee
     */
    function initialize(address _tokenAddress) external;

    /**
     * transfer ownership (only owner)
     * _account: wallet address of new owner
     */
    function transferOwnership(address _account) external;

    /**
     * recover wrong tokens (only owner)
     */
    function recoverWrongTokens(address _tokenAddress, uint256 _tokenAmount) external;

    /**
     * @dev called by the owner to pause, triggers stopped state
     * deposit, withdraw method is suspended
     */
    function pause() external;

    /**
     * @dev called by the owner to unpause, untriggers stopped state
     * deposit, withdraw method is enabled
     */
    function unpause() external;
}

// File: contracts\libs\IERC20.sol

pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function getOwner() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address _owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

// File: contracts\interfaces\IDexAggregator.sol

pragma solidity ^0.8.0;


interface IDexAggregator {
    function getExpectedInput(
        address fromToken,
        address destToken,
        address[] memory path,
        uint256 amountOut,
        address[] memory exchanges,
        uint256[] memory flags
    ) external view returns (uint256 bestAmount, uint256 bestIndex);

    function getExpectedReturn(
        address fromToken,
        address destToken,
        address[] memory path,
        uint256 amountIn,
        address[] memory exchanges,
        uint256[] memory flags
    ) external view returns (uint256 bestAmount, uint256 bestIndex);

    function swap(
        IERC20 fromToken,
        IERC20 destToken,
        address[] memory path,
        uint256 amountIn,
        uint256 minReturn,
        address recipient,
        address[] memory exchanges,
        uint256[] memory flags
    ) external payable;
}

// File: contracts\interfaces\IMerchantProperty.sol

pragma solidity ^0.8.0;

interface IMerchantProperty {
    function viewFeeMaxPercent() external view returns (uint16);

    function viewFeeMinPercent() external view returns (uint16);

    function viewDonationFee() external view returns (uint16);

    function viewTransactionFee() external view returns (uint16);

    function viewWeb3BalanceForFreeTx() external view returns (uint256);

    function viewMinAmountToProcessFee() external view returns (uint256);

    function viewMarketingWallet() external view returns (address payable);

    function viewDonationWallet() external view returns (address payable);

    function viewWeb3Token() external view returns (address);

    function viewAffiliatePool() external view returns (address);

    function viewStakingPool() external view returns (address);

    function viewMainExchange() external view returns (address, uint256);

    function viewExchanges() external view returns (address[] memory, uint256[] memory);

    function isBlacklistedFromPayToken(address token_)
        external
        view
        returns (bool);

    function isWhitelistedForRecToken(address token_)
        external
        view
        returns (bool);

    function viewMerchantWallet() external view returns (address);

    function viewAffiliatorWallet() external view returns (address);

    function viewFeeProcessingMethod() external view returns (uint8);

    function viewReceiveToken() external view returns (address);

    function viewDonationFeeCollected() external view returns (uint256);

    /**
     * @dev Update fee max percentage
     * Only callable by owner
     */
    function updateFeeMaxPercent(uint16 maxPercent_) external;

    /**
     * @dev Update fee min percentage
     * Only callable by owner
     */
    function updateFeeMinPercent(uint16 minPercent_) external;

    /**
     * @dev Update donation fee
     * Only callable by owner
     */
    function updateDonationFee(uint16 fee_) external;

    /**
     * @dev Update the transaction fee
     * Can only be called by the owner
     */
    function updateTransactionFee(uint16 fee_) external;

    /**
     * @dev Update the web3 balance for free transaction
     * Can only be called by the owner
     */
    function updateWeb3BalanceForFreeTx(uint256 web3Balance_) external;

    /**
     * @dev Update the web3 balance for free transaction
     * Can only be called by the owner
     */
    function updateMinAmountToProcessFee(uint256 minAmount_) external;

    /**
     * @dev Update the marketing wallet address
     * Can only be called by the owner.
     */
    function updateMarketingWallet(address payable marketingWallet_) external;

    /**
     * @dev Update the donation wallet address
     * Can only be called by the owner.
     */
    function updateDonationWallet(address payable donationWallet_) external;

    /**
     * @dev Update web3 token address
     * Callable only by owner
     */
    function updateWeb3TokenAddress(address tokenAddress_) external;

    function updateaffiliatePool(address affiliatePool_) external;

    function updateStakingPool(address stakingPool_) external;

    /**
     * @dev Update the main exchange address.
     * Can only be called by the owner.
     */
    function updateMainExchange(address exchange_, uint256 flag_) external;

    /**
     * @dev Add new exchange.
     * @param flag_: exchange type
     * Can only be called by the owner.
     */
    function addExchange(address exchange_, uint256 flag_) external;

    /**
     * @dev Remove the exchange.
     * Can only be called by the owner.
     */
    function removeExchange(uint256 index_) external;

    /**
     * @dev Exclude a token from paying blacklist
     * Only callable by owner
     */
    function excludeFromPayTokenBlacklist(address token_) external;

    /**
     * @dev Include a token in paying blacklist
     * Only callable by owner
     */
    function includeInPayTokenBlacklist(address token_) external;

    /**
     * @dev Exclude a token from receiving whitelist
     * Only callable by owner
     */
    function excludeFromRecTokenWhitelist(address token_) external;

    /**
     * @dev Include a token in receiving whitelist
     * Only callable by owner
     */
    function includeInRecTokenWhitelist(address token_) external;

    /**
     * @dev Update the merchant wallet address
     * Can only be called by the owner.
     */
    function updateMerchantWallet(address merchantWallet_) external;

    /**
     * @dev Update affiliator wallet address
     * Only callable by owner
     */
    function updateAffiliatorWallet(address affiliatorWallet_) external;

    /**
     * @dev Update fee processing method
     * Only callable by owner
     */
    function updateFeeProcessingMethod(uint8 method_) external;

    /**
     * @dev Update donationFeeCollected
     * Only callable by owner
     */
    function updateDonationFeeCollected(uint256 fee_) external;
}

// File: contracts\interfaces\IUniswapAmm.sol

// File: @uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

// File: @uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

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
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

// File: @uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol

pragma solidity >=0.6.2;

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// File: contracts\interfaces\IWETH.sol

pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

// File: contracts\libs\SafeMath.sol

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
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
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: contracts\libs\Address.sol

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

// File: contracts\libs\SafeERC20.sol

pragma solidity ^0.8.0;




/**
 * @title SafeERC20
 * @dev Wrappers around BEP20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
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
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(
            value
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            "SafeERC20: decreased allowance below zero"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
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

        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: BEP20 operation did not succeed"
            );
        }
    }
}

// File: contracts\libs\MerchantLibrary.sol

pragma solidity ^0.8.0;




library MerchantLibrary {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /**
     * @dev Swap tokens for eth
     * This function is called when fee processing mode is LIQU or AFLIQU which means web3 token is always set
     */
    function swapEtherToToken(
        address swapRouter_,
        address token_,
        uint256 etherAmount_,
        address to_
    ) public returns (uint256 tokenAmount, bool success) {
        IUniswapV2Router02 swapRouter = IUniswapV2Router02(swapRouter_);
        IERC20 token = IERC20(token_);

        // generate the saunaSwap pair path of bnb -> web3
        address[] memory path = new address[](2);
        path[0] = swapRouter.WETH();
        path[1] = token_;

        // make the swap
        uint256 balanceBefore = token.balanceOf(to_);
        try
            swapRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{
                value: etherAmount_
            }(
                0, // accept any amount of WEB3
                path,
                to_,
                block.timestamp.add(300)
            )
        {
            tokenAmount = token.balanceOf(to_).sub(balanceBefore);
            success = true;
        } catch (
            bytes memory /* lowLevelData */
        ) {
            success = false;
            tokenAmount = 0;
        }
    }

    /**
     * @dev Add liquidity
     * This function is called when fee processing mode is LIQU or AFLIQU which means web3 token is always set
     */
    function addLiquidityETH(
        address swapRouter_,
        address token_,
        uint256 tokenAmount_,
        uint256 etherAmount_,
        address to_
    ) public returns (bool success) {
        IUniswapV2Router02 swapRouter = IUniswapV2Router02(swapRouter_);
        IERC20 token = IERC20(token_);

        // approve token transfer to cover all possible scenarios
        token.safeApprove(address(swapRouter), tokenAmount_);

        // add the liquidity
        try
            swapRouter.addLiquidityETH{value: etherAmount_}(
                token_,
                tokenAmount_,
                0, // slippage is unavoidable
                0, // slippage is unavoidable
                to_,
                block.timestamp.add(300)
            )
        {
            success = true;
        } catch (
            bytes memory /* lowLevelData */
        ) {
            success = false;
        }
    }
}

// File: contracts\libs\Context.sol

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor() {}

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: contracts\libs\Ownable.sol

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts\libs\UniversalERC20.sol

pragma solidity ^0.8.0;



// File: contracts/UniversalERC20.sol

library UniversalERC20 {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 private constant ZERO_ADDRESS =
        IERC20(0x0000000000000000000000000000000000000000);
    IERC20 private constant ETH_ADDRESS =
        IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    function universalTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal returns (bool) {
        if (amount == 0) {
            return true;
        }

        if (isETH(token)) {
            payable(address(uint160(to))).transfer(amount);
            return true;
        } else {
            token.safeTransfer(to, amount);
            return true;
        }
    }

    function universalTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        if (amount == 0) {
            return;
        }

        if (isETH(token)) {
            require(
                from == msg.sender && msg.value >= amount,
                "Wrong useage of ETH.universalTransferFrom()"
            );
            if (to != address(this)) {
                payable(address(uint160(to))).transfer(amount);
            }
            if (msg.value > amount) {
                payable(msg.sender).transfer(msg.value.sub(amount));
            }
        } else {
            token.safeTransferFrom(from, to, amount);
        }
    }

    function universalTransferFromSenderToThis(IERC20 token, uint256 amount)
        internal
    {
        if (amount == 0) {
            return;
        }

        if (isETH(token)) {
            if (msg.value > amount) {
                // Return remainder if exist
                payable(msg.sender).transfer(msg.value.sub(amount));
            }
        } else {
            token.safeTransferFrom(msg.sender, address(this), amount);
        }
    }

    function universalApprove(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        if (!isETH(token)) {
            if (amount > 0 && token.allowance(address(this), to) > 0) {
                token.safeApprove(to, 0);
            }
            token.safeApprove(to, amount);
        }
    }

    function universalBalanceOf(IERC20 token, address who)
        internal
        view
        returns (uint256)
    {
        if (isETH(token)) {
            return who.balance;
        } else {
            return token.balanceOf(who);
        }
    }

    function universalDecimals(IERC20 token) internal view returns (uint256) {
        if (isETH(token)) {
            return 18;
        }

        (bool success, bytes memory data) = address(token).staticcall{
            gas: 10000
        }(abi.encodeWithSignature("decimals()"));
        if (!success || data.length == 0) {
            (success, data) = address(token).staticcall{gas: 10000}(
                abi.encodeWithSignature("DECIMALS()")
            );
        }

        return (success && data.length > 0) ? abi.decode(data, (uint256)) : 18;
    }

    function isETH(IERC20 token) internal pure returns (bool) {
        return (address(token) == address(ZERO_ADDRESS) ||
            address(token) == address(ETH_ADDRESS));
    }
}

// File: contracts\SlashCore.sol

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;











contract SlashCore is ISlashCore, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using UniversalERC20 for IERC20;

    enum FeeMethod {
        SIMPLE,
        LIQU,
        AFLIQU
    }

    event SwapEtherToWeb3TokenFailed(
        address indexed merchant,
        uint256 etherAmount
    );
    event AddLiquidityFailed(
        address indexed merchant,
        uint256 tokenAmount,
        uint256 etherAmount,
        address to
    );

    mapping(address => uint256) _taxFeePerMerchant;
    mapping(address => uint256) _donationFeePerMerchant;
    IDexAggregator private _dexAggregator;

    //to recieve ETH
    receive() external payable {}

    function handleFeeLiq(IMerchantProperty merchant_, uint256 taxFeeAmount_)
        internal
    {
        address payable marketingWallet = merchant_.viewMarketingWallet();
        (address mainExchange, ) = merchant_.viewMainExchange();
        address web3Token = merchant_.viewWeb3Token();

        // 50% of staked fee is added to WEB3-BNB liquidity and sent to the marketing address
        uint256 liquidifyBalance = taxFeeAmount_.div(2);

        uint256 half = liquidifyBalance.div(2);
        uint256 otherHalf = liquidifyBalance.sub(half);

        // Swap ether to web3
        (uint256 swappedWeb3Balance, bool success) = MerchantLibrary
            .swapEtherToToken(mainExchange, web3Token, half, address(this));
        if (!success) {
            emit SwapEtherToWeb3TokenFailed(address(merchant_), half);
            return;
        }

        // Add liquidity
        success = MerchantLibrary.addLiquidityETH(
            mainExchange,
            web3Token,
            swappedWeb3Balance,
            otherHalf,
            marketingWallet
        );
        if (!success) {
            emit AddLiquidityFailed(
                address(merchant_),
                swappedWeb3Balance,
                otherHalf,
                marketingWallet
            );
            // Do not return this time
        }

        // 50% of staked fee is swapped to WEB3 tokens to be sent to the marketing address
        uint256 directSwapBalance = taxFeeAmount_.sub(liquidifyBalance);
        // Swap bnb to web3
        (, success) = MerchantLibrary.swapEtherToToken(
            mainExchange,
            web3Token,
            directSwapBalance,
            marketingWallet
        );
        if (!success) {
            emit SwapEtherToWeb3TokenFailed(
                address(merchant_),
                directSwapBalance
            );
        }
    }

    function handleFeeAfLiq(IMerchantProperty merchant_, uint256 taxFeeAmount_)
        internal
    {
        IAffiliatePool affiliatePool = IAffiliatePool(
            merchant_.viewAffiliatePool()
        );
        address payable marketingWallet = merchant_.viewMarketingWallet();
        (address mainExchange, ) = merchant_.viewMainExchange();
        address web3Token = merchant_.viewWeb3Token();

        // 55% of staked fee is swapped to WEB3 token
        uint256 buyupBalance = taxFeeAmount_.mul(55).div(100);
        uint256 remainedEthBalance = taxFeeAmount_.sub(buyupBalance);

        (uint256 swappedWeb3Balance, bool success) = MerchantLibrary
            .swapEtherToToken(
                mainExchange,
                web3Token,
                buyupBalance,
                address(this)
            );
        if (!success) {
            emit SwapEtherToWeb3TokenFailed(address(merchant_), buyupBalance);
            return;
        }

        uint256 web3AmountToStake = swappedWeb3Balance.mul(10).div(55);

        // When fee processing method is AFLIQU, affiliatePool & affiliatorWallet addresses are not zero
        IERC20(web3Token).approve(address(affiliatePool), web3AmountToStake);
        // 5% amount of WEB3 token is deposited to affiliate pool for merchant and affiliator
        uint256 eachStakeAmount = web3AmountToStake.div(2);
        if (eachStakeAmount > 0) {
            affiliatePool.deposit(
                merchant_.viewMerchantWallet(),
                eachStakeAmount
            );
            affiliatePool.deposit(
                merchant_.viewAffiliatorWallet(),
                eachStakeAmount
            );
        }

        // WEB3 + BNB to liquidity
        uint256 liqifyBalance = swappedWeb3Balance.sub(web3AmountToStake);
        // Add liquidity
        success = MerchantLibrary.addLiquidityETH(
            mainExchange,
            web3Token,
            liqifyBalance,
            remainedEthBalance,
            marketingWallet
        );
        if (!success) {
            emit AddLiquidityFailed(
                address(merchant_),
                liqifyBalance,
                remainedEthBalance,
                marketingWallet
            );
            return;
        }
    }

    /**
     * @dev Handle fee
     * @param taxFeeAmount_: tax fee
     * @param donationFeeAmount_: donation fee is processed separately, so pass this amount
     */
    function handleFee(
        address merchant_,
        uint256 taxFeeAmount_,
        uint256 donationFeeAmount_
    ) internal {
        IMerchantProperty merchant = IMerchantProperty(merchant_);
        uint256 taxFeeAmount = taxFeeAmount_.add(_taxFeePerMerchant[merchant_]);
        uint256 donationFeeAmount = donationFeeAmount_.add(
            _donationFeePerMerchant[merchant_]
        );

        uint256 feeAmount = taxFeeAmount.add(donationFeeAmount);

        // Fee will be processed only when it is more than specific amount
        if (feeAmount < merchant.viewMinAmountToProcessFee()) {
            return;
        }

        if (donationFeeAmount > 0) {
            merchant.viewDonationWallet().transfer(donationFeeAmount);
            _donationFeePerMerchant[merchant_] = 0;
        }

        if (taxFeeAmount == 0) {
            return;
        }

        address payable marketingWallet = merchant.viewMarketingWallet();
        FeeMethod feeProcessingMethod = FeeMethod(
            merchant.viewFeeProcessingMethod()
        );

        if (feeProcessingMethod == FeeMethod.SIMPLE) {
            marketingWallet.transfer(taxFeeAmount);
        } else if (feeProcessingMethod == FeeMethod.LIQU) {
            handleFeeLiq(merchant, taxFeeAmount);
        } else if (feeProcessingMethod == FeeMethod.AFLIQU) {
            handleFeeAfLiq(merchant, taxFeeAmount);
        }
        _taxFeePerMerchant[merchant_] = 0;
    }

    /**
     * @dev Get in-amount to get out-amount of receive token
     * @return in-amount of token
     */
    function getAmountIn(
        address merchant_,
        address payingToken_,
        uint256 amountOut_,
        address[] memory path_,
        bytes memory /** reserved */
    ) external view override returns (uint256) {
        IMerchantProperty merchant = IMerchantProperty(merchant_);

        // Blacklisted token can not be used as paying token
        if (merchant.isBlacklistedFromPayToken(payingToken_)) {
            return 0;
        }
        (address[] memory exchanges, uint256[] memory flags) = merchant
            .viewExchanges();
        (uint256 bestAmount, ) = _dexAggregator.getExpectedInput(
            payingToken_,
            merchant.viewReceiveToken(),
            path_,
            amountOut_,
            exchanges,
            flags
        );

        return bestAmount;
    }

    /**
     * @dev Get out-amount from the in-amount of token
     * @return out-amount of receive token
     */
    function getAmountOut(
        address merchant_,
        address payingToken_,
        uint256 amountIn_,
        address[] memory path_,
        bytes memory /** reserved */
    ) external view override returns (uint256) {
        IMerchantProperty merchant = IMerchantProperty(merchant_);

        // Blacklisted token can not be used as paying token
        if (merchant.isBlacklistedFromPayToken(payingToken_)) {
            return 0;
        }

        (address[] memory exchanges, uint256[] memory flags) = merchant
            .viewExchanges();
        (uint256 bestAmount, ) = _dexAggregator.getExpectedReturn(
            payingToken_,
            merchant.viewReceiveToken(),
            path_,
            amountIn_,
            exchanges,
            flags
        );

        return bestAmount;
    }

    /**
     * @dev Swap token to receive token and transfer to the merchant wallet
     * @param path_: swap path from _payingTokenAddress to receive token
     * @param amountIn_: user paid amount of input token
     * @param requiredAmountOut_: required amount of output token
     */
    function doMerchantDeposit(
        address merchant_,
        address account_,
        address payingToken_,
        uint256 amountIn_,
        uint256 requiredAmountOut_,
        address[] memory path_
    ) private returns (uint256 redundantAmount) {
        // Blacklisted token can not be used as paying token
        IMerchantProperty merchant = IMerchantProperty(merchant_);
        require(
            !merchant.isBlacklistedFromPayToken(payingToken_),
            "Blacklisted token"
        );

        address receiveToken = merchant.viewReceiveToken();
        address merchantWallet = merchant.viewMerchantWallet();

        // In case of payng token is same as receive token
        if (payingToken_ == receiveToken) {
            require(amountIn_ >= requiredAmountOut_, "Insufficient amountIn_");
            // Transfer token directly to merchant wallet
            IERC20(receiveToken).universalTransfer(
                merchantWallet,
                requiredAmountOut_
            );
            // Transfer redundant token back to the user
            if (amountIn_ > requiredAmountOut_) {
                redundantAmount = amountIn_.sub(requiredAmountOut_);
                IERC20(receiveToken).universalTransfer(
                    account_,
                    redundantAmount
                );
            }
        } else {
            (address[] memory exchanges, uint256[] memory flags) = merchant
                .viewExchanges();
            IERC20(payingToken_).universalApprove(
                address(_dexAggregator),
                uint256(int256(-1))
            );
            uint256 balanceBefore = IERC20(receiveToken).universalBalanceOf(
                address(this)
            );
            _dexAggregator.swap{
                value: IERC20(payingToken_).isETH() ? amountIn_ : 0
            }(
                IERC20(payingToken_),
                IERC20(receiveToken),
                path_,
                amountIn_,
                requiredAmountOut_,
                merchantWallet,
                exchanges,
                flags
            );
            uint256 balanceAfter = IERC20(receiveToken).universalBalanceOf(
                address(this)
            );
            if (balanceAfter > balanceBefore) {
                redundantAmount = balanceAfter.sub(balanceBefore);
                IERC20(receiveToken).universalTransfer(
                    account_,
                    redundantAmount
                );
            }
        }
    }

    /**
     * @dev Get tax fee amount
     */
    function getTxFeeAmount(
        IMerchantProperty merchant_,
        address account_,
        uint256 amountOut_
    ) private view returns (uint256) {
        IERC20 web3Token = IERC20(merchant_.viewWeb3Token());
        uint256 web3BalanceForFreeTx = merchant_.viewWeb3BalanceForFreeTx();
        IStakingPool stakingPool = IStakingPool(merchant_.viewStakingPool());
        uint256 feeMaxPercent = merchant_.viewFeeMaxPercent();

        // If user wallet has enough web3 token, fee amount is 0
        if (
            address(web3Token) != address(0) &&
            web3Token.balanceOf(account_) >= web3BalanceForFreeTx
        ) {
            return 0;
        }
        // If user did stake enough amount in staking contract, fee amount is 0
        if (
            address(stakingPool) != address(0) &&
            stakingPool.balanceOf(account_) >= web3BalanceForFreeTx
        ) {
            return 0;
        }
        // If staking contract is set to the merchant, determine fee amount from the staking amount
        if (address(stakingPool) != address(0)) {
            return
                amountOut_
                    .mul(
                        uint256(feeMaxPercent).sub(
                            stakingPool.getShare(account_).mul(
                                uint256(feeMaxPercent).sub(
                                    merchant_.viewFeeMinPercent()
                                )
                            )
                        )
                    )
                    .div(10000);
        }
        // Default fee amount
        return amountOut_.mul(merchant_.viewTransactionFee()).div(10000);
    }

    /**
     * @dev Get fee amount from the out-amount of token
     * @param feePath_: swap path from _receiveToken to ETH
     * @return taxFee: tax fee in ether
     * @return donationFee: donation fee in ether
     */
    function getFeeAmount(
        address merchant_,
        address account_,
        uint256 amountOut_,
        address[] memory feePath_,
        bytes memory /** reserved */
    ) public view override returns (uint256, uint256) {
        IMerchantProperty merchant = IMerchantProperty(merchant_);
        (address mainExchange, ) = merchant.viewMainExchange();
        IUniswapV2Router02 swapRouter = IUniswapV2Router02(mainExchange);
        address receiveToken = merchant.viewReceiveToken();

        uint256 taxFeeAmount = getTxFeeAmount(merchant, account_, amountOut_);
        // There is donation fee set always
        uint256 donationFeeAmount = amountOut_
            .mul(merchant.viewDonationFee())
            .div(10000);
        uint256 feeAmount = taxFeeAmount.add(donationFeeAmount);

        if (feeAmount == 0) {
            return (0, 0);
        }

        if (IERC20(receiveToken).isETH()) {
            return (taxFeeAmount, donationFeeAmount);
        }

        if (
            !(feePath_.length >= 2 &&
                feePath_[0] == receiveToken &&
                feePath_[feePath_.length - 1] == swapRouter.WETH())
        ) {
            feePath_ = new address[](2);
            feePath_[0] = receiveToken;
            feePath_[1] = swapRouter.WETH();
        }

        uint256[] memory amounts = swapRouter.getAmountsOut(
            feeAmount,
            feePath_
        );
        uint256 outAmount = amounts[feePath_.length - 1];
        return (
            outAmount.mul(taxFeeAmount).div(feeAmount),
            outAmount.mul(donationFeeAmount).div(feeAmount)
        );
    }

    /**
     * @dev Submit transaction
     * @param payingToken_: the address of paying token, zero address will be considered as native token
     * @param feePath_: swap path from _payingTokenAddress to WETH
     * @param path_: swap path from _payingTokenAddress to receive token
     * @param amountIn_: user paid amount of input token
     * @param requiredAmountOut_: required amount of output token
     * @return refTokBal Redundant token amount that is refunded to the user
     * @return refFeeBal Redundant fee amount that is refunded to the user
     */
    function submitTransaction(
        address merchant_,
        address account_,
        address payingToken_,
        uint256 amountIn_,
        uint256 requiredAmountOut_,
        address[] memory path_,
        address[] memory feePath_,
        bytes memory reserved_ /** reserved */
    ) external payable override returns (uint256 refTokBal, uint256 refFeeBal) {
        require(amountIn_ > 0, "_amountIn > 0");
        IMerchantProperty merchant = IMerchantProperty(merchant_);

        require(
            !merchant.isBlacklistedFromPayToken(payingToken_),
            "blacklisted"
        );

        IERC20 payingToken = IERC20(payingToken_);

        if (!payingToken.isETH()) {
            uint256 balanceBefore = payingToken.balanceOf(address(this));
            payingToken.safeTransferFrom(account_, address(this), amountIn_);
            amountIn_ = payingToken.balanceOf(address(this)).sub(balanceBefore);
        }

        (uint256 taxFeeAmount, uint256 donationFeeAmount) = getFeeAmount(
            merchant_,
            account_,
            requiredAmountOut_,
            feePath_,
            reserved_
        );

        uint256 ethRequired = taxFeeAmount.add(donationFeeAmount).add(
            payingToken.isETH() ? amountIn_ : 0
        ); // msg.value required for this transaction
        require(msg.value >= ethRequired, "Insufficient msg.value");

        // Swap token to receive token and transfer to the merchant wallet
        refTokBal = doMerchantDeposit(
            merchant_,
            account_,
            payingToken_,
            amountIn_,
            requiredAmountOut_,
            path_
        );

        // Handle fee
        handleFee(merchant_, taxFeeAmount, donationFeeAmount);

        // Return redundant ETH back to user
        if (msg.value > ethRequired) {
            refFeeBal = msg.value.sub(ethRequired);
            payable(account_).transfer(refFeeBal);
        }
    }

    /**
     * @notice Set dex aggregator
     * @dev Only owner can call this function
     */
    function setDexAggregator(address dexAggregator_) external onlyOwner {
        require(dexAggregator_ != address(0), "Invalid dex aggregator");
        _dexAggregator = IDexAggregator(dexAggregator_);
    }

    function viewDexAggregator() external view returns (address) {
        return address(_dexAggregator);
    }

    /**
     * @notice It allows the admin to recover tokens sent to the contract
     * @param token_: the address of the token to withdraw
     * @param amount_: the number of tokens to withdraw
     * @dev This function is only callable by admin.
     */
    function recoverTokens(address token_, uint256 amount_) external onlyOwner {
        IERC20(token_).universalTransfer(_msgSender(), amount_);
    }
}