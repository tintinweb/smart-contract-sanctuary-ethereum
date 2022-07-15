/// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./interfaces/IHarvester.sol";
import "./interfaces/IUniswapV3Router.sol";
import "./interfaces/ICurveV2Pool.sol";
import "../../interfaces/IVault.sol";
import "../../interfaces/IAggregatorV3.sol";

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title Harvester
/// @author PradeepSelva
/// @notice A contract to harvest rewards from Convex staking position into Want TOken
contract Harvester is IHarvester {
    using SafeERC20 for IERC20;
    using SafeERC20 for IERC20Metadata;

    /*///////////////////////////////////////////////////////////////
                        GLOBAL CONSTANTS
  //////////////////////////////////////////////////////////////*/
    /// @notice desired uniswap fee for WETH
    uint24 public constant WETH_SWAP_FEE = 500;
    /// @notice desired uniswap fee for snx
    uint24 public constant SNX_SWAP_FEE = 10000;
    /// @notice the max basis points used as normalizing factor
    uint256 public constant MAX_BPS = 1000;
    /// @notice normalization factor for decimals (USD)
    uint256 public constant USD_NORMALIZATION_FACTOR = 1e8;
    /// @notice normalization factor for decimals (ETH)
    uint256 public constant ETH_NORMALIZATION_FACTOR = 1e18;

    /// @notice address of crv token
    IERC20 public constant override crv =
        IERC20(0xD533a949740bb3306d119CC777fa900bA034cd52);
    /// @notice address of cvx token
    IERC20 public constant override cvx =
        IERC20(0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B);
    /// @notice address of snx token
    IERC20 public constant override snx =
        IERC20(0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F);
    /// @notice address of 3CRV LP token
    IERC20 public constant override _3crv =
        IERC20(0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490);
    /// @notice address of WETH token
    IERC20 private constant weth =
        IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    /// @notice address of Curve's CRV/ETH pool
    ICurveV2Pool private constant crveth =
        ICurveV2Pool(0x8301AE4fc9c624d1D396cbDAa1ed877821D7C511);
    /// @notice address of Curve's CVX/ETH pool
    ICurveV2Pool private constant cvxeth =
        ICurveV2Pool(0xB576491F1E6e5E62f1d8F26062Ee822B40B0E0d4);
    /// @notice address of Curve's 3CRV metapool
    ICurveV2Pool private constant _3crvPool =
        ICurveV2Pool(0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7);
    /// @notice address of uniswap router
    IUniswapV3Router private constant uniswapRouter =
        IUniswapV3Router(0xE592427A0AEce92De3Edee1F18E0157C05861564);

    /// @notice chainlink data feed for CRV/ETH
    IAggregatorV3 public constant crvEthPrice =
        IAggregatorV3(0x8a12Be339B0cD1829b91Adc01977caa5E9ac121e);
    /// @notice chainlink data feed for CVX/ETH
    IAggregatorV3 public constant cvxEthPrice =
        IAggregatorV3(0x231e764B44b2C1b7Ca171fa8021A24ed520Cde10);
    /// @notice chainlinkd ata feed for SNX/ETH
    IAggregatorV3 public constant snxUsdPrice =
        IAggregatorV3(0xDC3EA94CD0AC27d9A86C180091e7f78C683d3699);
    /// @notice chainlink data feed for ETH/USD
    IAggregatorV3 public constant ethUsdPrice =
        IAggregatorV3(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);

    /*///////////////////////////////////////////////////////////////
                        MUTABLE ACCESS MODFIERS
  //////////////////////////////////////////////////////////////*/
    /// @notice instance of vault
    IVault public override vault;
    /// @notice maximum acceptable slippage
    uint256 public maxSlippage = 1000;

    /// @notice creates a new Harvester
    /// @param _vault address of vault
    constructor(address _vault) {
        vault = IVault(_vault);

        // max approve CRV to CRV/ETH pool on curve
        crv.approve(address(crveth), type(uint256).max);
        // max approve CVX to CVX/ETH pool on curve
        cvx.approve(address(cvxeth), type(uint256).max);
        // max approve _3CRV to 3 CRV pool on curve
        _3crv.approve(address(_3crvPool), type(uint256).max);
        // max approve WETH to uniswap router
        weth.approve(address(uniswapRouter), type(uint256).max);
        // max approve SNX to uniswap router
        snx.approve(address(uniswapRouter), type(uint256).max);
    }

    /*///////////////////////////////////////////////////////////////
                         VIEW FUNCTONS
  //////////////////////////////////////////////////////////////*/

    /// @notice Function which returns address of reward tokens
    /// @return rewardTokens array of reward token addresses
    function rewardTokens() external pure override returns (address[] memory) {
        address[] memory rewards = new address[](4);
        rewards[0] = address(crv);
        rewards[1] = address(cvx);
        rewards[2] = address(_3crv);
        rewards[3] = address(snx);
        return rewards;
    }

    /*///////////////////////////////////////////////////////////////
                    KEEPER FUNCTONS
  //////////////////////////////////////////////////////////////*/
    /// @notice Keeper function to set maximum slippage
    /// @param _slippage new maximum slippage
    function setSlippage(uint256 _slippage) external override onlyKeeper {
        maxSlippage = _slippage;
    }

    /*///////////////////////////////////////////////////////////////
                      GOVERNANCE FUNCTIONS
  //////////////////////////////////////////////////////////////*/
    /// @notice Governance function to sweep a token's balance lying in Harvester
    /// @param _token address of token to sweep
    function sweep(address _token) external override onlyGovernance {
        IERC20(_token).safeTransfer(
            vault.governance(),
            IERC20Metadata(_token).balanceOf(address(this))
        );
    }

    /*///////////////////////////////////////////////////////////////
                    STATE MODIFICATION FUNCTONS
  //////////////////////////////////////////////////////////////*/

    /// @notice Harvest the entire swap tokens list, i.e convert them into wantToken
    /// @dev Pulls all swap token balances from the msg.sender, swaps them into wantToken, and sends back the wantToken balance
    function harvest() external override {
        uint256 crvBalance = crv.balanceOf(address(this));
        uint256 cvxBalance = cvx.balanceOf(address(this));
        uint256 _3crvBalance = _3crv.balanceOf(address(this));
        uint256 snxBalance = snx.balanceOf(address(this));

        // swap convex to eth
        if (cvxBalance > 0) {
            uint256 expectedOut = (_getPriceForAmount(crvEthPrice, cvxBalance));
            cvxeth.exchange(
                1,
                0,
                cvxBalance,
                _getMinReceived(expectedOut),
                false
            );
        }
        // swap crv to eth
        if (crvBalance > 0) {
            uint256 expectedOut = (_getPriceForAmount(crvEthPrice, crvBalance));
            crveth.exchange(
                1,
                0,
                crvBalance,
                _getMinReceived(expectedOut),
                false
            );
        }

        uint256 wethBalance = weth.balanceOf(address(this));

        // swap eth to USDC using 0.5% pool
        if (wethBalance > 0) {
            _swapToWantOnUniV3(
                address(weth),
                wethBalance,
                WETH_SWAP_FEE,
                ethUsdPrice
            );
        }

        // swap _crv to usdc
        if (_3crvBalance > 0) {
            _3crvPool.remove_liquidity_one_coin(_3crvBalance, 1, 0);
        }
        // swap SNX to usdc
        if (snxBalance > 0) {
            _swapToWantOnUniV3(
                address(snx),
                snxBalance,
                SNX_SWAP_FEE,
                snxUsdPrice
            );
        }

        // send token usdc back to vault
        IERC20(vault.wantToken()).safeTransfer(
            msg.sender,
            IERC20(vault.wantToken()).balanceOf(address(this))
        );
    }

    /// @notice helper to perform swap snx -> usdc on uniswap v3
    function _swapToWantOnUniV3(
        address tokenIn,
        uint256 amount,
        uint256 fee,
        IAggregatorV3 priceFeed
    ) internal {
        uint256 expectedOut = (_getPriceForAmount(priceFeed, amount) * 1e6) /
            ETH_NORMALIZATION_FACTOR;

        uniswapRouter.exactInput(
            IUniswapV3Router.ExactInputParams(
                abi.encodePacked(
                    tokenIn,
                    uint24(fee),
                    address(vault.wantToken())
                ),
                address(this),
                block.timestamp,
                amount,
                _getMinReceived(expectedOut)
            )
        );
    }

    /// @notice helper to get price of tokens in ETH, from chainlink
    /// @param priceFeed the price feed to fetch latest price from
    function _getPriceForAmount(IAggregatorV3 priceFeed, uint256 amount)
        internal
        view
        returns (uint256)
    {
        (, int256 latestPrice, , , ) = priceFeed.latestRoundData();
        return ((uint256(latestPrice) * amount) / 10**priceFeed.decimals());
    }

    /// @notice helper to get minimum amount to receive from swap
    function _getMinReceived(uint256 amount) internal view returns (uint256) {
        return (amount * (MAX_BPS - maxSlippage)) / MAX_BPS;
    }

    /*///////////////////////////////////////////////////////////////
                        ACCESS MODIFIERS
  //////////////////////////////////////////////////////////////*/

    /// @notice to check for valid address
    modifier validAddress(address _addr) {
        require(_addr != address(0), "_addr invalid");
        _;
    }

    /// @notice to check if caller is governance
    modifier onlyGovernance() {
        require(
            msg.sender == vault.governance(),
            "Harvester :: onlyGovernance"
        );
        _;
    }

    /// @notice to check if caller is keeper
    modifier onlyKeeper() {
        require(msg.sender == vault.keeper(), "auth: keeper");
        _;
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;
import "../../../interfaces/IVault.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IHarvester {
    function crv() external view returns (IERC20);

    function cvx() external view returns (IERC20);

    function _3crv() external view returns (IERC20);

    function snx() external view returns (IERC20);

    function vault() external view returns (IVault);

    // Swap tokens to wantToken
    function harvest() external;

    function sweep(address _token) external;

    function setSlippage(uint256 _slippage) external;

    function rewardTokens() external view returns (address[] memory);
}

pragma solidity ^0.8.0;

interface IUniswapV3Router {
    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    function exactInput(ExactInputParams calldata params)
        external
        payable
        returns (uint256 amountOut);
}

pragma solidity ^0.8.0;

interface ICurveV2Pool {
    function get_virtual_price() external view returns (uint256);

    function add_liquidity(
        // EURt
        uint256[2] calldata amounts,
        uint256 min_mint_amount
    ) external payable;

    function add_liquidity(
        // Compound, sAave
        uint256[2] calldata amounts,
        uint256 min_mint_amount,
        bool _use_underlying
    ) external payable returns (uint256);

    function add_liquidity(
        // Iron Bank, Aave
        uint256[3] calldata amounts,
        uint256 min_mint_amount,
        bool _use_underlying
    ) external payable returns (uint256);

    function add_liquidity(
        // 3Crv Metapools
        address pool,
        uint256[4] calldata amounts,
        uint256 min_mint_amount
    ) external;

    function add_liquidity(
        // Y and yBUSD
        uint256[4] calldata amounts,
        uint256 min_mint_amount,
        bool _use_underlying
    ) external payable returns (uint256);

    function add_liquidity(
        // 3pool
        uint256[3] calldata amounts,
        uint256 min_mint_amount
    ) external payable;

    function add_liquidity(
        // sUSD
        uint256[4] calldata amounts,
        uint256 min_mint_amount
    ) external payable;

    function remove_liquidity_imbalance(
        uint256[2] calldata amounts,
        uint256 max_burn_amount
    ) external;

    function remove_liquidity(uint256 _amount, uint256[2] calldata amounts)
        external;

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 min_amount
    ) external;

    function exchange(
        int128 from,
        int128 to,
        uint256 _from_amount,
        uint256 _min_to_amount
    ) external;

    function exchange(
        uint256 from,
        uint256 to,
        uint256 _from_amount,
        uint256 _min_to_amount,
        bool use_eth
    ) external;

    function balances(uint256) external view returns (uint256);

    function get_dy(
        int128 from,
        int128 to,
        uint256 _from_amount
    ) external view returns (uint256);

    // EURt
    function calc_token_amount(uint256[2] calldata _amounts, bool _is_deposit)
        external
        view
        returns (uint256);

    // 3Crv Metapools
    function calc_token_amount(
        address _pool,
        uint256[4] calldata _amounts,
        bool _is_deposit
    ) external view returns (uint256);

    // sUSD, Y pool, etc
    function calc_token_amount(uint256[4] calldata _amounts, bool _is_deposit)
        external
        view
        returns (uint256);

    // 3pool, Iron Bank, etc
    function calc_token_amount(uint256[3] calldata _amounts, bool _is_deposit)
        external
        view
        returns (uint256);

    function calc_withdraw_one_coin(uint256 amount, int128 i)
        external
        view
        returns (uint256);
}

/// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface IVault {
    function keeper() external view returns (address);

    function governance() external view returns (address);

    function wantToken() external view returns (address);

    function deposit(uint256 amountIn, address receiver)
        external
        returns (uint256 shares);

    function withdraw(uint256 sharesIn, address receiver)
        external
        returns (uint256 amountOut);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;
pragma abicoder v2;

/// @notice chainlink aggregator interface
interface IAggregatorV3 {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function getRoundData(uint80 _roundId)
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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