// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

import { StableMath } from "../utils/StableMath.sol";
import { Governable } from "../governance/Governable.sol";
import { IVault } from "../interfaces/IVault.sol";
import { IOracle } from "../interfaces/IOracle.sol";
import { IStrategy } from "../interfaces/IStrategy.sol";
import { IUniswapV2Router } from "../interfaces/uniswap/IUniswapV2Router02.sol";
import "../utils/Helpers.sol";

contract Harvester is Governable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using StableMath for uint256;

    event UniswapUpdated(address _address);
    event SupportedStrategyUpdate(address _address, bool _isSupported);
    event RewardTokenConfigUpdated(
        address _tokenAddress,
        uint16 _allowedSlippageBps,
        uint16 _harvestRewardBps,
        address _uniswapV2CompatibleAddr,
        uint256 _liquidationLimit,
        bool _doSwapRewardToken
    );

    // Configuration properties for harvesting logic of reward tokens
    struct RewardTokenConfig {
        // Max allowed slippage when swapping reward token for a stablecoin denominated in basis points.
        uint16 allowedSlippageBps;
        // Reward when calling a harvest function denominated in basis points.
        uint16 harvestRewardBps;
        /* Address of Uniswap V2 compatible exchange (Uniswap V2, SushiSwap).
         */
        address uniswapV2CompatibleAddr;
        /* When true the reward token is being swapped. In a need of (temporarily) disabling the swapping of
         * a reward token this needs to be set to false.
         */
        bool doSwapRewardToken;
        /* How much token can be sold per one harvest call. If the balance of rewards tokens
         * exceeds that limit multiple harvest calls are required to harvest all of the tokens.
         * Set it to MAX_INT to effectively disable the limit.
         */
        uint256 liquidationLimit;
    }

    mapping(address => RewardTokenConfig) public rewardTokenConfigs;
    mapping(address => bool) public supportedStrategies;

    address public immutable vaultAddress;
    address public immutable usdtAddress;

    /**
     * Address receiving rewards proceeds. Initially the Vault contract later will possibly
     * be replaced by another contract that eases out rewards distribution.
     */
    address public rewardProceedsAddress;

    /**
     * @dev Constructor to set up initial internal state
     * @param _vaultAddress Address of the Vault
     * @param _usdtAddress Address of Tether
     */
    constructor(address _vaultAddress, address _usdtAddress) {
        require(address(_vaultAddress) != address(0));
        require(address(_usdtAddress) != address(0));
        vaultAddress = _vaultAddress;
        usdtAddress = _usdtAddress;
    }

    /***************************************
                 Configuration
    ****************************************/

    /**
     * @dev Throws if called by any address other than the Vault.
     */
    modifier onlyVaultOrGovernor() {
        require(
            msg.sender == vaultAddress || isGovernor(),
            "Caller is not the Vault or Governor"
        );
        _;
    }

    /**
     * Set the Address receiving rewards proceeds.
     * @param _rewardProceedsAddress Address of the reward token
     */
    function setRewardsProceedsAddress(address _rewardProceedsAddress)
        external
        onlyGovernor
    {
        require(
            _rewardProceedsAddress != address(0),
            "Rewards proceeds address should be a non zero address"
        );

        rewardProceedsAddress = _rewardProceedsAddress;
    }

    /**
     * @dev Add/update a reward token configuration that holds harvesting config variables
     * @param _tokenAddress Address of the reward token
     * @param _allowedSlippageBps uint16 maximum allowed slippage denominated in basis points.
     *        Example: 300 == 3% slippage
     * @param _harvestRewardBps uint16 amount of reward tokens the caller of the function is rewarded.
     *        Example: 100 == 1%
     * @param _uniswapV2CompatibleAddr Address Address of a UniswapV2 compatible contract to perform
     *        the exchange from reward tokens to stablecoin (currently hard-coded to USDT)
     * @param _liquidationLimit uint256 Maximum amount of token to be sold per one swap function call.
     *        When value is 0 there is no limit.
     * @param _doSwapRewardToken bool When true the reward token is being swapped. In a need of (temporarily)
     *        disabling the swapping of a reward token this needs to be set to false.
     */
    function setRewardTokenConfig(
        address _tokenAddress,
        uint16 _allowedSlippageBps,
        uint16 _harvestRewardBps,
        address _uniswapV2CompatibleAddr,
        uint256 _liquidationLimit,
        bool _doSwapRewardToken
    ) external onlyGovernor {
        require(
            _allowedSlippageBps <= 1000,
            "Allowed slippage should not be over 10%"
        );
        require(
            _harvestRewardBps <= 1000,
            "Harvest reward fee should not be over 10%"
        );
        require(
            _uniswapV2CompatibleAddr != address(0),
            "Uniswap compatible address should be non zero address"
        );

        RewardTokenConfig memory tokenConfig = RewardTokenConfig({
            allowedSlippageBps: _allowedSlippageBps,
            harvestRewardBps: _harvestRewardBps,
            uniswapV2CompatibleAddr: _uniswapV2CompatibleAddr,
            doSwapRewardToken: _doSwapRewardToken,
            liquidationLimit: _liquidationLimit
        });

        address oldUniswapAddress = rewardTokenConfigs[_tokenAddress]
            .uniswapV2CompatibleAddr;
        rewardTokenConfigs[_tokenAddress] = tokenConfig;

        IERC20 token = IERC20(_tokenAddress);

        address priceProvider = IVault(vaultAddress).priceProvider();

        // Revert if feed does not exist
        // slither-disable-next-line unused-return
        IOracle(priceProvider).price(_tokenAddress);

        // if changing token swap provider cancel existing allowance
        if (
            /* oldUniswapAddress == address(0) when there is no pre-existing
             * configuration for said rewards token
             */
            oldUniswapAddress != address(0) &&
            oldUniswapAddress != _uniswapV2CompatibleAddr
        ) {
            token.safeApprove(oldUniswapAddress, 0);
        }

        // Give Uniswap infinite approval when needed
        if (oldUniswapAddress != _uniswapV2CompatibleAddr) {
            token.safeApprove(_uniswapV2CompatibleAddr, 0);
            token.safeApprove(_uniswapV2CompatibleAddr, type(uint256).max);
        }

        emit RewardTokenConfigUpdated(
            _tokenAddress,
            _allowedSlippageBps,
            _harvestRewardBps,
            _uniswapV2CompatibleAddr,
            _liquidationLimit,
            _doSwapRewardToken
        );
    }

    /**
     * @dev Flags a strategy as supported or not supported one
     * @param _strategyAddress Address of the strategy
     * @param _isSupported Bool marking strategy as supported or not supported
     */
    function setSupportedStrategy(address _strategyAddress, bool _isSupported)
        external
        onlyVaultOrGovernor
    {
        supportedStrategies[_strategyAddress] = _isSupported;
        emit SupportedStrategyUpdate(_strategyAddress, _isSupported);
    }

    /***************************************
                    Rewards
    ****************************************/

    /**
     * @dev Transfer token to governor. Intended for recovering tokens stuck in
     *      contract, i.e. mistaken sends.
     * @param _asset Address for the asset
     * @param _amount Amount of the asset to transfer
     */
    function transferToken(address _asset, uint256 _amount)
        external
        onlyGovernor
    {
        IERC20(_asset).safeTransfer(governor(), _amount);
    }

    /**
     * @dev Collect reward tokens from all strategies
     */
    function harvest() external onlyGovernor nonReentrant {
        _harvest();
    }

    /**
     * @dev Swap all supported swap tokens for stablecoins via Uniswap.
     */
    function swap() external onlyGovernor nonReentrant {
        _swap(rewardProceedsAddress);
    }

    /*
     * @dev Collect reward tokens from all strategies and swap for supported
     *      stablecoin via Uniswap
     */
    function harvestAndSwap() external onlyGovernor nonReentrant {
        _harvest();
        _swap(rewardProceedsAddress);
    }

    /**
     * @dev Collect reward tokens for a specific strategy. Called from the vault.
     * @param _strategyAddr Address of the strategy to collect rewards from
     */
    function harvest(address _strategyAddr) external onlyGovernor nonReentrant {
        _harvest(_strategyAddr);
    }

    /**
     * @dev Collect reward tokens for a specific strategy and swap for supported
     *      stablecoin via Uniswap. Can be called by anyone. Rewards incentivizing
     *      the caller are sent to the caller of this function.
     * @param _strategyAddr Address of the strategy to collect rewards from
     */
    function harvestAndSwap(address _strategyAddr) external nonReentrant {
        // Remember _harvest function checks for the validity of _strategyAddr
        _harvestAndSwap(_strategyAddr, msg.sender);
    }

    /**
     * @dev Collect reward tokens for a specific strategy and swap for supported
     *      stablecoin via Uniswap. Can be called by anyone.
     * @param _strategyAddr Address of the strategy to collect rewards from
     * @param _rewardTo Address where to send a share of harvest rewards to as an incentive
     *      for executing this function
     */
    function harvestAndSwap(address _strategyAddr, address _rewardTo)
        external
        nonReentrant
    {
        // Remember _harvest function checks for the validity of _strategyAddr
        _harvestAndSwap(_strategyAddr, _rewardTo);
    }

    /**
     * @dev Governance convenience function to swap a specific _rewardToken and send
     *       rewards to the vault.
     * @param _swapToken Address of the token to swap.
     */
    function swapRewardToken(address _swapToken)
        external
        onlyGovernor
        nonReentrant
    {
        _swap(_swapToken, rewardProceedsAddress);
    }

    /**
     * @dev Collect reward tokens from all strategies
     */
    function _harvest() internal {
        address[] memory allStrategies = IVault(vaultAddress)
            .getAllStrategies();
        for (uint256 i = 0; i < allStrategies.length; i++) {
            _harvest(allStrategies[i]);
        }
    }

    /**
     * @dev Collect reward tokens for a specific strategy and swap for supported
     *      stablecoin via Uniswap.
     * @param _strategyAddr Address of the strategy to collect rewards from
     * @param _rewardTo Address where to send a share of harvest rewards to as an incentive
     *      for executing this function
     */
    function _harvestAndSwap(address _strategyAddr, address _rewardTo)
        internal
    {
        _harvest(_strategyAddr);
        IStrategy strategy = IStrategy(_strategyAddr);
        address[] memory rewardTokens = strategy.getRewardTokenAddresses();
        for (uint256 i = 0; i < rewardTokens.length; i++) {
            _swap(rewardTokens[i], _rewardTo);
        }
    }

    /**
     * @dev Collect reward tokens from a single strategy and swap them for a
     *      supported stablecoin via Uniswap
     * @param _strategyAddr Address of the strategy to collect rewards from.
     */
    function _harvest(address _strategyAddr) internal {
        require(
            supportedStrategies[_strategyAddr],
            "Not a valid strategy address"
        );

        IStrategy strategy = IStrategy(_strategyAddr);
        address[] memory rewardTokenAddresses = strategy
            .getRewardTokenAddresses();

        strategy.collectRewardTokens();
    }

    /**
     * @dev Swap all supported swap tokens for stablecoins via Uniswap. And send the incentive part
     * of the rewards to _rewardTo address.
     * @param _rewardTo Address where to send a share of harvest rewards to as an incentive
     *      for executing this function
     */
    function _swap(address _rewardTo) internal {
        address[] memory allStrategies = IVault(vaultAddress)
            .getAllStrategies();

        for (uint256 i = 0; i < allStrategies.length; i++) {
            IStrategy strategy = IStrategy(allStrategies[i]);
            address[] memory rewardTokenAddresses = strategy
                .getRewardTokenAddresses();

            for (uint256 j = 0; j < rewardTokenAddresses.length; j++) {
                _swap(rewardTokenAddresses[j], _rewardTo);
            }
        }
    }

    /**
     * @dev Swap a reward token for stablecoins on Uniswap. The token must have
     *       a registered price feed with the price provider.
     * @param _swapToken Address of the token to swap.
     * @param _rewardTo Address where to send the share of harvest rewards to
     */
    function _swap(address _swapToken, address _rewardTo) internal {
        RewardTokenConfig memory tokenConfig = rewardTokenConfigs[_swapToken];

        /* This will trigger a return when reward token configuration has not yet been set
         * or we have temporarily disabled swapping of specific reward token via setting
         * doSwapRewardToken to false.
         */
        if (!tokenConfig.doSwapRewardToken) {
            return;
        }

        address priceProvider = IVault(vaultAddress).priceProvider();

        IERC20 swapToken = IERC20(_swapToken);
        uint256 balance = swapToken.balanceOf(address(this));

        if (balance == 0) {
            return;
        }

        uint256 balanceToSwap = Math.min(balance, tokenConfig.liquidationLimit);

        // This'll revert if there is no price feed
        uint256 oraclePrice = IOracle(priceProvider).price(_swapToken);
        // Oracle price is 1e8, USDT output is 1e6
        uint256 minExpected = (balanceToSwap *
            oraclePrice *
            (1e4 - tokenConfig.allowedSlippageBps)).scaleBy( // max allowed slippage
            6,
            Helpers.getDecimals(_swapToken) + 8
        ) / 1e4; // fix the max slippage decimal position

        // Uniswap redemption path
        address[] memory path = new address[](3);
        path[0] = _swapToken;
        path[1] = IUniswapV2Router(tokenConfig.uniswapV2CompatibleAddr).WETH();
        path[2] = usdtAddress;

        // slither-disable-next-line unused-return
        IUniswapV2Router(tokenConfig.uniswapV2CompatibleAddr)
            .swapExactTokensForTokens(
                balanceToSwap,
                minExpected,
                path,
                address(this),
                block.timestamp
            );

        IERC20 usdt = IERC20(usdtAddress);
        uint256 usdtBalance = usdt.balanceOf(address(this));

        uint256 vaultBps = 1e4 - tokenConfig.harvestRewardBps;
        uint256 rewardsProceedsShare = (usdtBalance * vaultBps) / 1e4;

        require(
            vaultBps > tokenConfig.harvestRewardBps,
            "Address receiving harvest incentive is receiving more rewards than the rewards proceeds address"
        );

        usdt.safeTransfer(rewardProceedsAddress, rewardsProceedsShare);
        usdt.safeTransfer(
            _rewardTo,
            usdtBalance - rewardsProceedsShare // remaining share of the rewards
        );
    }
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";

// Based on StableMath from Stability Labs Pty. Ltd.
// https://github.com/mstable/mStable-contracts/blob/master/contracts/shared/StableMath.sol

library StableMath {
    using SafeMath for uint256;

    /**
     * @dev Scaling unit for use in specific calculations,
     * where 1 * 10**18, or 1e18 represents a unit '1'
     */
    uint256 private constant FULL_SCALE = 1e18;

    /***************************************
                    Helpers
    ****************************************/

    /**
     * @dev Adjust the scale of an integer
     * @param to Decimals to scale to
     * @param from Decimals to scale from
     */
    function scaleBy(
        uint256 x,
        uint256 to,
        uint256 from
    ) internal pure returns (uint256) {
        if (to > from) {
            x = x.mul(10**(to - from));
        } else if (to < from) {
            x = x.div(10**(from - to));
        }
        return x;
    }

    /***************************************
               Precise Arithmetic
    ****************************************/

    /**
     * @dev Multiplies two precise units, and then truncates by the full scale
     * @param x Left hand input to multiplication
     * @param y Right hand input to multiplication
     * @return Result after multiplying the two inputs and then dividing by the shared
     *         scale unit
     */
    function mulTruncate(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulTruncateScale(x, y, FULL_SCALE);
    }

    /**
     * @dev Multiplies two precise units, and then truncates by the given scale. For example,
     * when calculating 90% of 10e18, (10e18 * 9e17) / 1e18 = (9e36) / 1e18 = 9e18
     * @param x Left hand input to multiplication
     * @param y Right hand input to multiplication
     * @param scale Scale unit
     * @return Result after multiplying the two inputs and then dividing by the shared
     *         scale unit
     */
    function mulTruncateScale(
        uint256 x,
        uint256 y,
        uint256 scale
    ) internal pure returns (uint256) {
        // e.g. assume scale = fullScale
        // z = 10e18 * 9e17 = 9e36
        uint256 z = x.mul(y);
        // return 9e36 / 1e18 = 9e18
        return z.div(scale);
    }

    /**
     * @dev Multiplies two precise units, and then truncates by the full scale, rounding up the result
     * @param x Left hand input to multiplication
     * @param y Right hand input to multiplication
     * @return Result after multiplying the two inputs and then dividing by the shared
     *          scale unit, rounded up to the closest base unit.
     */
    function mulTruncateCeil(uint256 x, uint256 y)
        internal
        pure
        returns (uint256)
    {
        // e.g. 8e17 * 17268172638 = 138145381104e17
        uint256 scaled = x.mul(y);
        // e.g. 138145381104e17 + 9.99...e17 = 138145381113.99...e17
        uint256 ceil = scaled.add(FULL_SCALE.sub(1));
        // e.g. 13814538111.399...e18 / 1e18 = 13814538111
        return ceil.div(FULL_SCALE);
    }

    /**
     * @dev Precisely divides two units, by first scaling the left hand operand. Useful
     *      for finding percentage weightings, i.e. 8e18/10e18 = 80% (or 8e17)
     * @param x Left hand input to division
     * @param y Right hand input to division
     * @return Result after multiplying the left operand by the scale, and
     *         executing the division on the right hand input.
     */
    function divPrecisely(uint256 x, uint256 y)
        internal
        pure
        returns (uint256)
    {
        // e.g. 8e18 * 1e18 = 8e36
        uint256 z = x.mul(FULL_SCALE);
        // e.g. 8e36 / 10e18 = 8e17
        return z.div(y);
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

/**
 * @title OUSD Governable Contract
 * @dev Copy of the openzeppelin Ownable.sol contract with nomenclature change
 *      from owner to governor and renounce methods removed. Does not use
 *      Context.sol like Ownable.sol does for simplification.
 * @author Origin Protocol Inc
 */
contract Governable {
    // Storage position of the owner and pendingOwner of the contract
    // keccak256("OUSD.governor");
    bytes32 private constant governorPosition =
        0x7bea13895fa79d2831e0a9e28edede30099005a50d652d8957cf8a607ee6ca4a;

    // keccak256("OUSD.pending.governor");
    bytes32 private constant pendingGovernorPosition =
        0x44c4d30b2eaad5130ad70c3ba6972730566f3e6359ab83e800d905c61b1c51db;

    // keccak256("OUSD.reentry.status");
    bytes32 private constant reentryStatusPosition =
        0x53bf423e48ed90e97d02ab0ebab13b2a235a6bfbe9c321847d5c175333ac4535;

    // See OpenZeppelin ReentrancyGuard implementation
    uint256 constant _NOT_ENTERED = 1;
    uint256 constant _ENTERED = 2;

    event PendingGovernorshipTransfer(
        address indexed previousGovernor,
        address indexed newGovernor
    );

    event GovernorshipTransferred(
        address indexed previousGovernor,
        address indexed newGovernor
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial Governor.
     */
    constructor() {
        _setGovernor(msg.sender);
        emit GovernorshipTransferred(address(0), _governor());
    }

    /**
     * @dev Returns the address of the current Governor.
     */
    function governor() public view returns (address) {
        return _governor();
    }

    /**
     * @dev Returns the address of the current Governor.
     */
    function _governor() internal view returns (address governorOut) {
        bytes32 position = governorPosition;
        assembly {
            governorOut := sload(position)
        }
    }

    /**
     * @dev Returns the address of the pending Governor.
     */
    function _pendingGovernor()
        internal
        view
        returns (address pendingGovernor)
    {
        bytes32 position = pendingGovernorPosition;
        assembly {
            pendingGovernor := sload(position)
        }
    }

    /**
     * @dev Throws if called by any account other than the Governor.
     */
    modifier onlyGovernor() {
        require(isGovernor(), "Caller is not the Governor");
        _;
    }

    /**
     * @dev Returns true if the caller is the current Governor.
     */
    function isGovernor() public view returns (bool) {
        return msg.sender == _governor();
    }

    function _setGovernor(address newGovernor) internal {
        bytes32 position = governorPosition;
        assembly {
            sstore(position, newGovernor)
        }
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        bytes32 position = reentryStatusPosition;
        uint256 _reentry_status;
        assembly {
            _reentry_status := sload(position)
        }

        // On the first call to nonReentrant, _notEntered will be true
        require(_reentry_status != _ENTERED, "Reentrant call");

        // Any calls to nonReentrant after this point will fail
        assembly {
            sstore(position, _ENTERED)
        }

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        assembly {
            sstore(position, _NOT_ENTERED)
        }
    }

    function _setPendingGovernor(address newGovernor) internal {
        bytes32 position = pendingGovernorPosition;
        assembly {
            sstore(position, newGovernor)
        }
    }

    /**
     * @dev Transfers Governance of the contract to a new account (`newGovernor`).
     * Can only be called by the current Governor. Must be claimed for this to complete
     * @param _newGovernor Address of the new Governor
     */
    function transferGovernance(address _newGovernor) external onlyGovernor {
        _setPendingGovernor(_newGovernor);
        emit PendingGovernorshipTransfer(_governor(), _newGovernor);
    }

    /**
     * @dev Claim Governance of the contract to a new account (`newGovernor`).
     * Can only be called by the new Governor.
     */
    function claimGovernance() external {
        require(
            msg.sender == _pendingGovernor(),
            "Only the pending Governor can complete the claim"
        );
        _changeGovernor(msg.sender);
    }

    /**
     * @dev Change Governance of the contract to a new account (`newGovernor`).
     * @param _newGovernor Address of the new Governor
     */
    function _changeGovernor(address _newGovernor) internal {
        require(_newGovernor != address(0), "New Governor is address(0)");
        emit GovernorshipTransferred(_governor(), _newGovernor);
        _setGovernor(_newGovernor);
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

interface IVault {
    event AssetSupported(address _asset);
    event AssetDefaultStrategyUpdated(address _asset, address _strategy);
    event AssetAllocated(address _asset, address _strategy, uint256 _amount);
    event StrategyApproved(address _addr);
    event StrategyRemoved(address _addr);
    event Mint(address _addr, uint256 _value);
    event Redeem(address _addr, uint256 _value);
    event CapitalPaused();
    event CapitalUnpaused();
    event RebasePaused();
    event RebaseUnpaused();
    event VaultBufferUpdated(uint256 _vaultBuffer);
    event RedeemFeeUpdated(uint256 _redeemFeeBps);
    event PriceProviderUpdated(address _priceProvider);
    event AllocateThresholdUpdated(uint256 _threshold);
    event RebaseThresholdUpdated(uint256 _threshold);
    event StrategistUpdated(address _address);
    event MaxSupplyDiffChanged(uint256 maxSupplyDiff);
    event YieldDistribution(address _to, uint256 _yield, uint256 _fee);
    event TrusteeFeeBpsChanged(uint256 _basis);
    event TrusteeAddressChanged(address _address);

    // Governable.sol
    function transferGovernance(address _newGovernor) external;

    function claimGovernance() external;

    function governor() external view returns (address);

    // VaultAdmin.sol
    function setPriceProvider(address _priceProvider) external;

    function priceProvider() external view returns (address);

    function setRedeemFeeBps(uint256 _redeemFeeBps) external;

    function redeemFeeBps() external view returns (uint256);

    function setVaultBuffer(uint256 _vaultBuffer) external;

    function vaultBuffer() external view returns (uint256);

    function setAutoAllocateThreshold(uint256 _threshold) external;

    function autoAllocateThreshold() external view returns (uint256);

    function setRebaseThreshold(uint256 _threshold) external;

    function rebaseThreshold() external view returns (uint256);

    function setStrategistAddr(address _address) external;

    function strategistAddr() external view returns (address);

    function setMaxSupplyDiff(uint256 _maxSupplyDiff) external;

    function maxSupplyDiff() external view returns (uint256);

    function setTrusteeAddress(address _address) external;

    function trusteeAddress() external view returns (address);

    function setTrusteeFeeBps(uint256 _basis) external;

    function trusteeFeeBps() external view returns (uint256);

    function supportAsset(address _asset) external;

    function approveStrategy(address _addr) external;

    function removeStrategy(address _addr) external;

    function setAssetDefaultStrategy(address _asset, address _strategy)
        external;

    function assetDefaultStrategies(address _asset)
        external
        view
        returns (address);

    function pauseRebase() external;

    function unpauseRebase() external;

    function rebasePaused() external view returns (bool);

    function pauseCapital() external;

    function unpauseCapital() external;

    function capitalPaused() external view returns (bool);

    function transferToken(address _asset, uint256 _amount) external;

    function priceUSDMint(address asset) external view returns (uint256);

    function priceUSDRedeem(address asset) external view returns (uint256);

    function withdrawAllFromStrategy(address _strategyAddr) external;

    function withdrawAllFromStrategies() external;

    function reallocate(
        address _strategyFromAddress,
        address _strategyToAddress,
        address[] calldata _assets,
        uint256[] calldata _amounts
    ) external;

    // VaultCore.sol
    function mint(
        address _asset,
        uint256 _amount,
        uint256 _minimumOusdAmount
    ) external;

    function redeem(uint256 _amount, uint256 _minimumUnitAmount) external;

    function redeemAll(uint256 _minimumUnitAmount) external;

    function allocate() external;

    function rebase() external;

    function totalValue() external view returns (uint256 value);

    function checkBalance(address _asset) external view returns (uint256);

    function calculateRedeemOutputs(uint256 _amount)
        external
        view
        returns (uint256[] memory);

    function getAssetCount() external view returns (uint256);

    function getAllAssets() external view returns (address[] memory);

    function getStrategyCount() external view returns (uint256);

    function getAllStrategies() external view returns (address[] memory);

    function isSupportedAsset(address _asset) external view returns (bool);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

interface IOracle {
    /**
     * @dev returns the asset price in USD, 8 decimal digits.
     */
    function price(address asset) external view returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

/**
 * @title Platform interface to integrate with lending platform like Compound, AAVE etc.
 */
interface IStrategy {
    /**
     * @dev Deposit the given asset to platform
     * @param _asset asset address
     * @param _amount Amount to deposit
     */
    function deposit(address _asset, uint256 _amount) external;

    /**
     * @dev Deposit the entire balance of all supported assets in the Strategy
     *      to the platform
     */
    function depositAll() external;

    /**
     * @dev Withdraw given asset from Lending platform
     */
    function withdraw(
        address _recipient,
        address _asset,
        uint256 _amount
    ) external;

    /**
     * @dev Liquidate all assets in strategy and return them to Vault.
     */
    function withdrawAll() external;

    /**
     * @dev Returns the current balance of the given asset.
     */
    function checkBalance(address _asset)
        external
        view
        returns (uint256 balance);

    /**
     * @dev Returns bool indicating whether strategy supports asset.
     */
    function supportsAsset(address _asset) external view returns (bool);

    /**
     * @dev Collect reward tokens from the Strategy.
     */
    function collectRewardTokens() external;

    /**
     * @dev The address array of the reward tokens for the Strategy.
     */
    function getRewardTokenAddresses() external view returns (address[] memory);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

interface IUniswapV2Router {
    function WETH() external pure returns (address);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

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
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import { IBasicToken } from "../interfaces/IBasicToken.sol";

library Helpers {
    /**
     * @notice Fetch the `symbol()` from an ERC20 token
     * @dev Grabs the `symbol()` from a contract
     * @param _token Address of the ERC20 token
     * @return string Symbol of the ERC20 token
     */
    function getSymbol(address _token) internal view returns (string memory) {
        string memory symbol = IBasicToken(_token).symbol();
        return symbol;
    }

    /**
     * @notice Fetch the `decimals()` from an ERC20 token
     * @dev Grabs the `decimals()` from a contract and fails if
     *      the decimal value does not live within a certain range
     * @param _token Address of the ERC20 token
     * @return uint256 Decimals of the ERC20 token
     */
    function getDecimals(address _token) internal view returns (uint256) {
        uint256 decimals = IBasicToken(_token).decimals();
        require(
            decimals >= 4 && decimals <= 18,
            "Token must have sufficient decimal places"
        );

        return decimals;
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

interface IBasicToken {
    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}