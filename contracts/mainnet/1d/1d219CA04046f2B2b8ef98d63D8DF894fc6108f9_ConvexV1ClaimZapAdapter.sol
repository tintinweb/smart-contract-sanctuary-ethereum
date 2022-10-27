// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2022
pragma solidity ^0.8.10;
pragma abicoder v1;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { AbstractAdapter } from "@gearbox-protocol/core-v2/contracts/adapters/AbstractAdapter.sol";

import { IClaimZap } from "../../integrations/convex/IClaimZap.sol";
import { IRewards, IBasicRewards } from "../../integrations/convex/IRewards.sol";
import { IBaseRewardPool } from "../../integrations/convex/IBaseRewardPool.sol";
import { IAdapter, AdapterType } from "@gearbox-protocol/core-v2/contracts/interfaces/adapters/IAdapter.sol";

/// @title ConvexV1ClaimZapAdapter adapter
/// @dev Implements logic for interacting with the Convex ClaimZap contract
contract ConvexV1ClaimZapAdapter is
    AbstractAdapter,
    IClaimZap,
    ReentrancyGuard
{
    AdapterType public constant _gearboxAdapterType =
        AdapterType.CONVEX_V1_CLAIM_ZAP;
    uint16 public constant _gearboxAdapterVersion = 1;

    /// @dev Constructor
    /// @param _creditManager Address of the Credit manager
    /// @param _claimZap Address of the ClaimZap contract
    constructor(address _creditManager, address _claimZap)
        AbstractAdapter(_creditManager, _claimZap)
    {}

    /// @dev Claims rewards from multiple sources for a Credit Account
    /// @param rewardContracts Base reward pools to claim from
    /// @param extraRewardContracts Base reward pools to claim from
    /// @param tokenRewardContracts Special reward pools to claim from
    /// @param tokenRewardTokens Tokens to claim from special reward pools
    /// @notice Additional parameters for claimZap are ignored, since they deal
    /// with pools and contracts that are currently not supported.
    function claimRewards(
        address[] calldata rewardContracts,
        address[] calldata extraRewardContracts,
        address[] calldata tokenRewardContracts,
        address[] calldata tokenRewardTokens,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256
    ) external {
        address creditAccount = creditManager.getCreditAccountOrRevert(
            msg.sender
        );

        _claimAndEnableRewards(creditAccount, rewardContracts); // F: [ACVX1_Z-1]

        _claimAndEnableExtraRewards(creditAccount, extraRewardContracts); // F: [ACVX1_Z-1,2]

        _claimAndEnableTokenRewards( // F: [ACVX1_Z-1,4]
            creditAccount,
            tokenRewardContracts,
            tokenRewardTokens
        );

        _enableTokenIfHasBalance(creditAccount, crv()); // F: [ACVX1_Z-1]
        _enableTokenIfHasBalance(creditAccount, cvx()); // F: [ACVX1_Z-1]

        _checkAndOptimizeEnabledTokens(creditAccount);
    }

    /// @dev Calls getReward on base reward contracts and enables extra reward tokens, if available
    /// @param creditAccount Credit account to claim for
    /// @param rewardContracts BaseRewardPool contracts to claim from
    /// @notice The reward token itself is not enabled, since it is always CRV,
    /// which is enabled at the end of the main function
    function _claimAndEnableRewards(
        address creditAccount,
        address[] calldata rewardContracts
    ) internal {
        address token;
        uint256 len = rewardContracts.length;

        for (uint256 i; i < len; ) {
            address rewardContract = rewardContracts[i];

            IBaseRewardPool(rewardContract).getReward(creditAccount, true); // F: [ACVX1_Z-1]
            token = IRewards(rewardContract).rewardToken();

            try IBaseRewardPool(rewardContract).extraRewards(0) returns (
                address extraRewardContract1
            ) {
                // F: [ACVX1_Z-5]
                token = IRewards(extraRewardContract1).rewardToken();
                _enableTokenIfHasBalance(creditAccount, token); // F: [ACVX1_Z-1]

                try IBaseRewardPool(rewardContract).extraRewards(1) returns (
                    address extraRewardContract2
                ) {
                    token = IRewards(extraRewardContract2).rewardToken();
                    _enableTokenIfHasBalance(creditAccount, token); // F: [ACVX1_Z-1]
                } catch {}
            } catch {}

            unchecked {
                ++i;
            }
        }
    }

    /// @dev Calls getReward on extra reward contracts and enables extra reward tokens
    /// @param creditAccount Credit account to claim for
    /// @param extraRewardContracts VirtualBalanceRewardPool contracts to claim from
    function _claimAndEnableExtraRewards(
        address creditAccount,
        address[] calldata extraRewardContracts
    ) internal {
        address token;

        uint256 len = extraRewardContracts.length;

        for (uint256 i = 0; i < len; ) {
            token = IRewards(extraRewardContracts[i]).rewardToken();
            IRewards(extraRewardContracts[i]).getReward(creditAccount); // F: [ACVX1_Z-1,2]

            _enableTokenIfHasBalance(creditAccount, token); // F: [ACVX1_Z-1,2]

            unchecked {
                ++i;
            }
        }
    }

    /// @dev Calls getReward on special reward contracts and enables designated reward tokens
    /// @param creditAccount Credit account to claim for
    /// @param tokenRewardContracts Contracts to claim from
    /// @param tokenRewardTokens Tokens to claim
    /// @notice If the sizes of two arrays don't match, then any tokens that
    /// don't have a corresponding contract will be ignored
    function _claimAndEnableTokenRewards(
        address creditAccount,
        address[] calldata tokenRewardContracts,
        address[] calldata tokenRewardTokens
    ) internal {
        address token;
        uint256 len = tokenRewardContracts.length; // F: [ACVX1_Z-4]
        //claim from multi reward token contract
        for (uint256 i; i < len; ) {
            token = tokenRewardTokens[i];
            IBasicRewards(tokenRewardContracts[i]).getReward( // F: [ACVX1_Z-1,4]
                creditAccount,
                token
            );

            _enableTokenIfHasBalance(creditAccount, token); // F: [ACVX1_Z-1,4]

            unchecked {
                ++i;
            }
        }
    }

    /// @dev Enables token for a credit account if it has balance > 1
    /// @param creditAccount The CA to enable the token for
    /// @param token The token to enable
    function _enableTokenIfHasBalance(address creditAccount, address token)
        internal
    {
        if (IERC20(token).balanceOf(creditAccount) > 1) {
            creditManager.checkAndEnableToken(creditAccount, token);
        }
    }

    /// @dev Returns the CRV token address
    function crv() public view returns (address) {
        return IClaimZap(targetContract).crv();
    }

    /// @dev Returns the CVX token address
    function cvx() public view returns (address) {
        return IClaimZap(targetContract).cvx();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2022
pragma solidity ^0.8.10;
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ICreditManagerV2 } from "../interfaces/ICreditManagerV2.sol";
import { IAdapter } from "../interfaces/adapters/IAdapter.sol";
import { ZeroAddressException } from "../interfaces/IErrors.sol";

abstract contract AbstractAdapter is IAdapter {
    using Address for address;

    ICreditManagerV2 public immutable override creditManager;
    address public immutable override creditFacade;
    address public immutable override targetContract;

    constructor(address _creditManager, address _targetContract) {
        if (_creditManager == address(0) || _targetContract == address(0))
            revert ZeroAddressException(); // F:[AA-2]

        creditManager = ICreditManagerV2(_creditManager); // F:[AA-1]
        creditFacade = ICreditManagerV2(_creditManager).creditFacade(); // F:[AA-1]
        targetContract = _targetContract; // F:[AA-1]
    }

    /// @dev Approves a token from the Credit Account to the target contract
    /// @param token Token to be approved
    /// @param amount Amount to be approved
    function _approveToken(address token, uint256 amount) internal {
        creditManager.approveCreditAccount(
            msg.sender,
            targetContract,
            token,
            amount
        );
    }

    /// @dev Sends CallData to call the target contract from the Credit Account
    /// @param callData Data to be sent to the target contract
    function _execute(bytes memory callData)
        internal
        returns (bytes memory result)
    {
        result = creditManager.executeOrder(
            msg.sender,
            targetContract,
            callData
        );
    }

    /// @dev Calls a target contract with maximal allowance and performs a fast check after
    /// @param creditAccount A credit account from which a call is made
    /// @param tokenIn The token that the interaction is expected to spend
    /// @param tokenOut The token that the interaction is expected to produce
    /// @param callData Data to call targetContract with
    /// @param allowTokenIn Whether the input token must be approved beforehand
    /// @param disableTokenIn Whether the input token should be disable afterwards (for interaction that spend the entire balance)
    /// @notice Must only be used for highly secure and immutable protocols, such as Uniswap & Curve
    function _executeMaxAllowanceFastCheck(
        address creditAccount,
        address tokenIn,
        address tokenOut,
        bytes memory callData,
        bool allowTokenIn,
        bool disableTokenIn
    ) internal returns (bytes memory result) {
        uint256 balanceInBefore;
        uint256 balanceOutBefore;

        if (msg.sender != creditFacade) {
            balanceInBefore = IERC20(tokenIn).balanceOf(creditAccount); // F:[AA-4A]
            balanceOutBefore = IERC20(tokenOut).balanceOf(creditAccount); // F:[AA-4A]
        }

        if (allowTokenIn) {
            _approveToken(tokenIn, type(uint256).max);
        }

        result = creditManager.executeOrder(
            msg.sender,
            targetContract,
            callData
        );

        if (allowTokenIn) {
            _approveToken(tokenIn, type(uint256).max);
        }

        _fastCheck(
            creditAccount,
            tokenIn,
            tokenOut,
            balanceInBefore,
            balanceOutBefore,
            disableTokenIn
        );
    }

    /// @dev Wrapper for _executeMaxAllowanceFastCheck that computes the Credit Account on the spot
    /// See params and other details above
    function _executeMaxAllowanceFastCheck(
        address tokenIn,
        address tokenOut,
        bytes memory callData,
        bool allowTokenIn,
        bool disableTokenIn
    ) internal returns (bytes memory result) {
        address creditAccount = creditManager.getCreditAccountOrRevert(
            msg.sender
        ); // F:[AA-3]

        result = _executeMaxAllowanceFastCheck(
            creditAccount,
            tokenIn,
            tokenOut,
            callData,
            allowTokenIn,
            disableTokenIn
        );
    }

    /// @dev Calls a target contract with maximal allowance, then sets allowance to 1 and performs a fast check
    /// @param creditAccount A credit account from which a call is made
    /// @param tokenIn The token that the interaction is expected to spend
    /// @param tokenOut The token that the interaction is expected to produce
    /// @param callData Data to call targetContract with
    /// @param allowTokenIn Whether the input token must be approved beforehand
    /// @param disableTokenIn Whether the input token should be disable afterwards (for interaction that spend the entire balance)
    function _safeExecuteFastCheck(
        address creditAccount,
        address tokenIn,
        address tokenOut,
        bytes memory callData,
        bool allowTokenIn,
        bool disableTokenIn
    ) internal returns (bytes memory result) {
        uint256 balanceInBefore;
        uint256 balanceOutBefore;

        if (msg.sender != creditFacade) {
            balanceInBefore = IERC20(tokenIn).balanceOf(creditAccount);
            balanceOutBefore = IERC20(tokenOut).balanceOf(creditAccount); // F:[AA-4A]
        }

        if (allowTokenIn) {
            _approveToken(tokenIn, type(uint256).max);
        }

        result = creditManager.executeOrder(
            msg.sender,
            targetContract,
            callData
        );

        if (allowTokenIn) {
            _approveToken(tokenIn, 1);
        }

        _fastCheck(
            creditAccount,
            tokenIn,
            tokenOut,
            balanceInBefore,
            balanceOutBefore,
            disableTokenIn
        );
    }

    /// @dev Wrapper for _safeExecuteFastCheck that computes the Credit Account on the spot
    /// See params and other details above
    function _safeExecuteFastCheck(
        address tokenIn,
        address tokenOut,
        bytes memory callData,
        bool allowTokenIn,
        bool disableTokenIn
    ) internal returns (bytes memory result) {
        address creditAccount = creditManager.getCreditAccountOrRevert(
            msg.sender
        );

        result = _safeExecuteFastCheck(
            creditAccount,
            tokenIn,
            tokenOut,
            callData,
            allowTokenIn,
            disableTokenIn
        );
    }

    //
    // HEALTH CHECK FUNCTIONS
    //

    /// @dev Performs a fast check during ordinary adapter call, or skips
    /// it for multicalls (since a full collateral check is always performed after a multicall)
    /// @param creditAccount Credit Account for which the fast check is performed
    /// @param tokenIn Token that is spent by the operation
    /// @param tokenOut Token that is received as a result of operation
    /// @param balanceInBefore Balance of tokenIn before the operation
    /// @param balanceOutBefore Balance of tokenOut before the operation
    /// @param disableTokenIn Whether tokenIn needs to be disabled (required for multicalls, where the fast check is skipped)
    function _fastCheck(
        address creditAccount,
        address tokenIn,
        address tokenOut,
        uint256 balanceInBefore,
        uint256 balanceOutBefore,
        bool disableTokenIn
    ) private {
        if (msg.sender != creditFacade) {
            creditManager.fastCollateralCheck(
                creditAccount,
                tokenIn,
                tokenOut,
                balanceInBefore,
                balanceOutBefore
            );
        } else {
            if (disableTokenIn)
                creditManager.disableToken(creditAccount, tokenIn);
            creditManager.checkAndEnableToken(creditAccount, tokenOut);
        }
    }

    /// @dev Performs a full collateral check during ordinary adapter call, or skips
    /// it for multicalls (since a full collateral check is always performed after a multicall)
    /// @param creditAccount Credit Account for which the full check is performed
    function _fullCheck(address creditAccount) internal {
        if (msg.sender != creditFacade) {
            creditManager.fullCollateralCheck(creditAccount);
        }
    }

    /// @dev Performs a enabled token optimization on account or skips
    /// it for multicalls (since a full collateral check is always performed after a multicall,
    /// and includes enabled token optimization by default)
    /// @param creditAccount Credit Account for which the full check is performed
    /// @notice Used when new tokens are added on an account but no tokens are subtracted
    ///         (e.g., claiming rewards)
    function _checkAndOptimizeEnabledTokens(address creditAccount) internal {
        if (msg.sender != creditFacade) {
            creditManager.checkAndOptimizeEnabledTokens(creditAccount);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;
pragma abicoder v1;

interface IClaimZap {
    function claimRewards(
        address[] calldata rewardContracts,
        address[] calldata extraRewardContracts,
        address[] calldata tokenRewardContracts,
        address[] calldata tokenRewardTokens,
        uint256 depositCrvMaxAmount,
        uint256 minAmountOut,
        uint256 depositCvxMaxAmount,
        uint256 spendCvxAmount,
        uint256 options
    ) external;

    function crv() external view returns (address);

    function cvx() external view returns (address);
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IBaseRewardPool {
    //
    // STATE CHANGING FUNCTIONS
    //

    function stake(uint256 _amount) external returns (bool);

    function stakeAll() external returns (bool);

    function stakeFor(address _for, uint256 _amount) external returns (bool);

    function withdraw(uint256 amount, bool claim) external returns (bool);

    function withdrawAll(bool claim) external;

    function withdrawAndUnwrap(uint256 amount, bool claim)
        external
        returns (bool);

    function withdrawAllAndUnwrap(bool claim) external;

    function getReward(address _account, bool _claimExtras)
        external
        returns (bool);

    function getReward() external returns (bool);

    function donate(uint256 _amount) external returns (bool);

    //
    // GETTERS
    //

    function earned(address account) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function extraRewardsLength() external view returns (uint256);

    function lastTimeRewardApplicable() external view returns (uint256);

    function rewardPerToken() external view returns (uint256);

    function rewardToken() external view returns (IERC20);

    function stakingToken() external view returns (IERC20);

    function duration() external view returns (uint256);

    function operator() external view returns (address);

    function rewardManager() external view returns (address);

    function pid() external view returns (uint256);

    function periodFinish() external view returns (uint256);

    function rewardRate() external view returns (uint256);

    function lastUpdateTime() external view returns (uint256);

    function rewardPerTokenStored() external view returns (uint256);

    function queuedRewards() external view returns (uint256);

    function currentRewards() external view returns (uint256);

    function historicalRewards() external view returns (uint256);

    function newRewardRatio() external view returns (uint256);

    function userRewardPerTokenPaid(address account)
        external
        view
        returns (uint256);

    function rewards(address account) external view returns (uint256);

    function extraRewards(uint256 i) external view returns (address);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

interface IRewards {
    function stake(address, uint256) external;

    function stakeFor(address, uint256) external;

    function withdraw(address, uint256) external;

    function exit(address) external;

    function getReward(address) external;

    function queueNewRewards(uint256) external;

    function notifyRewardAmount(uint256) external;

    function addExtraReward(address) external;

    function stakingToken() external view returns (address);

    function rewardToken() external view returns (address);

    function earned(address account) external view returns (uint256);
}

interface IBasicRewards {
    function getReward(address _account, bool _claimExtras) external;

    function getReward(address _account) external;

    function getReward(address _account, address _token) external;

    function stakeFor(address, uint256) external;
}

// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2022
pragma solidity ^0.8.10;
import { ICreditManagerV2 } from "../ICreditManagerV2.sol";

enum AdapterType {
    ABSTRACT,
    UNISWAP_V2_ROUTER,
    UNISWAP_V3_ROUTER,
    CURVE_V1_EXCHANGE_ONLY,
    YEARN_V2,
    CURVE_V1_2ASSETS,
    CURVE_V1_3ASSETS,
    CURVE_V1_4ASSETS,
    CURVE_V1_STECRV_POOL,
    CURVE_V1_WRAPPER,
    CONVEX_V1_BASE_REWARD_POOL,
    CONVEX_V1_BOOSTER,
    CONVEX_V1_CLAIM_ZAP,
    LIDO_V1,
    UNIVERSAL,
    LIDO_WSTETH_V1
}

interface IAdapterExceptions {
    /// @dev Thrown when the adapter attempts to use a token
    ///      that is not recognized as collateral in the connected
    ///      Credit Manager
    error TokenIsNotInAllowedList(address);
}

interface IAdapter is IAdapterExceptions {
    /// @dev Returns the Credit Manager connected to the adapter
    function creditManager() external view returns (ICreditManagerV2);

    /// @dev Returns the Credit Facade connected to the adapter's Credit Manager
    function creditFacade() external view returns (address);

    /// @dev Returns the address of the contract the adapter is interacting with
    function targetContract() external view returns (address);

    /// @dev Returns the adapter type
    function _gearboxAdapterType() external pure returns (AdapterType);

    /// @dev Returns the adapter version
    function _gearboxAdapterVersion() external pure returns (uint16);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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

// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2022
pragma solidity ^0.8.10;

import { IPriceOracleV2 } from "./IPriceOracle.sol";
import { IVersion } from "./IVersion.sol";

enum ClosureAction {
    CLOSE_ACCOUNT,
    LIQUIDATE_ACCOUNT,
    LIQUIDATE_EXPIRED_ACCOUNT,
    LIQUIDATE_PAUSED
}

interface ICreditManagerV2Events {
    /// @dev Emits when a call to an external contract is made through the Credit Manager
    event ExecuteOrder(address indexed borrower, address indexed target);

    /// @dev Emits when a configurator is upgraded
    event NewConfigurator(address indexed newConfigurator);
}

interface ICreditManagerV2Exceptions {
    /// @dev Thrown if an access-restricted function is called by an address that is not
    ///      the connected Credit Facade, or an allowed adapter
    error AdaptersOrCreditFacadeOnlyException();

    /// @dev Thrown if an access-restricted function is called by an address that is not
    ///      the connected Credit Facade
    error CreditFacadeOnlyException();

    /// @dev Thrown if an access-restricted function is called by an address that is not
    ///      the connected Credit Configurator
    error CreditConfiguratorOnlyException();

    /// @dev Thrown on attempting to open a Credit Account for or transfer a Credit Account
    ///      to the zero address or an address that already owns a Credit Account
    error ZeroAddressOrUserAlreadyHasAccountException();

    /// @dev Thrown on attempting to execute an order to an address that is not an allowed
    ///      target contract
    error TargetContractNotAllowedException();

    /// @dev Thrown on failing a full collateral check after an operation
    error NotEnoughCollateralException();

    /// @dev Thrown on attempting to receive a token that is not a collateral token
    ///      or was forbidden
    error TokenNotAllowedException();

    /// @dev Thrown if an attempt to approve a collateral token to a target contract failed
    error AllowanceFailedException();

    /// @dev Thrown on attempting to perform an action for an address that owns no Credit Account
    error HasNoOpenedAccountException();

    /// @dev Thrown on attempting to add a token that is already in a collateral list
    error TokenAlreadyAddedException();

    /// @dev Thrown on configurator attempting to add more than 256 collateral tokens
    error TooManyTokensException();

    /// @dev Thrown if more than the maximal number of tokens were enabled on a Credit Account,
    ///      and there are not enough unused token to disable
    error TooManyEnabledTokensException();

    /// @dev Thrown when a reentrancy into the contract is attempted
    error ReentrancyLockException();
}

/// @notice All Credit Manager functions are access-restricted and can only be called
///         by the Credit Facade or allowed adapters. Users are not allowed to
///         interact with the Credit Manager directly
interface ICreditManagerV2 is
    ICreditManagerV2Events,
    ICreditManagerV2Exceptions,
    IVersion
{
    //
    // CREDIT ACCOUNT MANAGEMENT
    //

    ///  @dev Opens credit account and borrows funds from the pool.
    /// - Takes Credit Account from the factory;
    /// - Requests the pool to lend underlying to the Credit Account
    ///
    /// @param borrowedAmount Amount to be borrowed by the Credit Account
    /// @param onBehalfOf The owner of the newly opened Credit Account
    function openCreditAccount(uint256 borrowedAmount, address onBehalfOf)
        external
        returns (address);

    ///  @dev Closes a Credit Account - covers both normal closure and liquidation
    /// - Checks whether the contract is paused, and, if so, if the payer is an emergency liquidator.
    ///   Only emergency liquidators are able to liquidate account while the CM is paused.
    ///   Emergency liquidations do not pay a liquidator premium or liquidation fees.
    /// - Calculates payments to various recipients on closure:
    ///    + Computes amountToPool, which is the amount to be sent back to the pool.
    ///      This includes the principal, interest and fees, but can't be more than
    ///      total position value
    ///    + Computes remainingFunds during liquidations - these are leftover funds
    ///      after paying the pool and the liquidator, and are sent to the borrower
    ///    + Computes protocol profit, which includes interest and liquidation fees
    ///    + Computes loss if the totalValue is less than borrow amount + interest
    /// - Checks the underlying token balance:
    ///    + if it is larger than amountToPool, then the pool is paid fully from funds on the Credit Account
    ///    + else tries to transfer the shortfall from the payer - either the borrower during closure, or liquidator during liquidation
    /// - Send assets to the "to" address, as long as they are not included into skipTokenMask
    /// - If convertWETH is true, the function converts WETH into ETH before sending
    /// - Returns the Credit Account back to factory
    ///
    /// @param borrower Borrower address
    /// @param closureActionType Whether the account is closed, liquidated or liquidated due to expiry
    /// @param totalValue Portfolio value for liqution, 0 for ordinary closure
    /// @param payer Address which would be charged if credit account has not enough funds to cover amountToPool
    /// @param to Address to which the leftover funds will be sent
    /// @param skipTokenMask Tokenmask contains 1 for tokens which needed to be skipped for sending
    /// @param convertWETH If true converts WETH to ETH
    function closeCreditAccount(
        address borrower,
        ClosureAction closureActionType,
        uint256 totalValue,
        address payer,
        address to,
        uint256 skipTokenMask,
        bool convertWETH
    ) external returns (uint256 remainingFunds);

    /// @dev Manages debt size for borrower:
    ///
    /// - Increase debt:
    ///   + Increases debt by transferring funds from the pool to the credit account
    ///   + Updates the cumulative index to keep interest the same. Since interest
    ///     is always computed dynamically as borrowedAmount * (cumulativeIndexNew / cumulativeIndexOpen - 1),
    ///     cumulativeIndexOpen needs to be updated, as the borrow amount has changed
    ///
    /// - Decrease debt:
    ///   + Repays debt partially + all interest and fees accrued thus far
    ///   + Updates cunulativeIndex to cumulativeIndex now
    ///
    /// @param creditAccount Address of the Credit Account to change debt for
    /// @param amount Amount to increase / decrease the principal by
    /// @param increase True to increase principal, false to decrease
    /// @return newBorrowedAmount The new debt principal
    function manageDebt(
        address creditAccount,
        uint256 amount,
        bool increase
    ) external returns (uint256 newBorrowedAmount);

    /// @dev Adds collateral to borrower's credit account
    /// @param payer Address of the account which will be charged to provide additional collateral
    /// @param creditAccount Address of the Credit Account
    /// @param token Collateral token to add
    /// @param amount Amount to add
    function addCollateral(
        address payer,
        address creditAccount,
        address token,
        uint256 amount
    ) external;

    /// @dev Transfers Credit Account ownership to another address
    /// @param from Address of previous owner
    /// @param to Address of new owner
    function transferAccountOwnership(address from, address to) external;

    /// @dev Requests the Credit Account to approve a collateral token to another contract.
    /// @param borrower Borrower's address
    /// @param targetContract Spender to change allowance for
    /// @param token Collateral token to approve
    /// @param amount New allowance amount
    function approveCreditAccount(
        address borrower,
        address targetContract,
        address token,
        uint256 amount
    ) external;

    /// @dev Requests a Credit Account to make a low-level call with provided data
    /// This is the intended pathway for state-changing interactions with 3rd-party protocols
    /// @param borrower Borrower's address
    /// @param targetContract Contract to be called
    /// @param data Data to pass with the call
    function executeOrder(
        address borrower,
        address targetContract,
        bytes memory data
    ) external returns (bytes memory);

    //
    // COLLATERAL VALIDITY AND ACCOUNT HEALTH CHECKS
    //

    /// @dev Enables a token on a Credit Account, including it
    /// into account health and total value calculations
    /// @param creditAccount Address of a Credit Account to enable the token for
    /// @param token Address of the token to be enabled
    function checkAndEnableToken(address creditAccount, address token) external;

    /// @dev Optimized health check for individual swap-like operations.
    /// @notice Fast health check assumes that only two tokens (input and output)
    ///         participate in the operation and computes a % change in weighted value between
    ///         inbound and outbound collateral. The cumulative negative change across several
    ///         swaps in sequence cannot be larger than feeLiquidation (a fee that the
    ///         protocol is ready to waive if needed). Since this records a % change
    ///         between just two tokens, the corresponding % change in TWV will always be smaller,
    ///         which makes this check safe.
    ///         More details at https://dev.gearbox.fi/docs/documentation/risk/fast-collateral-check#fast-check-protection
    /// @param creditAccount Address of the Credit Account
    /// @param tokenIn Address of the token spent by the swap
    /// @param tokenOut Address of the token received from the swap
    /// @param balanceInBefore Balance of tokenIn before the operation
    /// @param balanceOutBefore Balance of tokenOut before the operation
    function fastCollateralCheck(
        address creditAccount,
        address tokenIn,
        address tokenOut,
        uint256 balanceInBefore,
        uint256 balanceOutBefore
    ) external;

    /// @dev Performs a full health check on an account, summing up
    /// value of all enabled collateral tokens
    /// @param creditAccount Address of the Credit Account to check
    function fullCollateralCheck(address creditAccount) external;

    /// @dev Checks that the number of enabled tokens on a Credit Account
    ///      does not violate the maximal enabled token limit and tries
    ///      to disable unused tokens if it does
    /// @param creditAccount Account to check enabled tokens for
    function checkAndOptimizeEnabledTokens(address creditAccount) external;

    /// @dev Disables a token on a credit account
    /// @notice Usually called by adapters to disable spent tokens during a multicall,
    ///         but can also be called separately from the Credit Facade to remove
    ///         unwanted tokens
    /// @return True if token mask was change otherwise False
    function disableToken(address creditAccount, address token)
        external
        returns (bool);

    //
    // GETTERS
    //

    /// @dev Returns the address of a borrower's Credit Account, or reverts if there is none.
    /// @param borrower Borrower's address
    function getCreditAccountOrRevert(address borrower)
        external
        view
        returns (address);

    /// @dev Computes amounts that must be sent to various addresses before closing an account
    /// @param totalValue Credit Accounts total value in underlying
    /// @param closureActionType Type of account closure
    ///        * CLOSE_ACCOUNT: The account is healthy and is closed normally
    ///        * LIQUIDATE_ACCOUNT: The account is unhealthy and is being liquidated to avoid bad debt
    ///        * LIQUIDATE_EXPIRED_ACCOUNT: The account has expired and is being liquidated (lowered liquidation premium)
    ///        * LIQUIDATE_PAUSED: The account is liquidated while the system is paused due to emergency (no liquidation premium)
    /// @param borrowedAmount Credit Account's debt principal
    /// @param borrowedAmountWithInterest Credit Account's debt principal + interest
    /// @return amountToPool Amount of underlying to be sent to the pool
    /// @return remainingFunds Amount of underlying to be sent to the borrower (only applicable to liquidations)
    /// @return profit Protocol's profit from fees (if any)
    /// @return loss Protocol's loss from bad debt (if any)
    function calcClosePayments(
        uint256 totalValue,
        ClosureAction closureActionType,
        uint256 borrowedAmount,
        uint256 borrowedAmountWithInterest
    )
        external
        view
        returns (
            uint256 amountToPool,
            uint256 remainingFunds,
            uint256 profit,
            uint256 loss
        );

    /// @dev Calculates the debt accrued by a Credit Account
    /// @param creditAccount Address of the Credit Account
    /// @return borrowedAmount The debt principal
    /// @return borrowedAmountWithInterest The debt principal + accrued interest
    /// @return borrowedAmountWithInterestAndFees The debt principal + accrued interest and protocol fees
    function calcCreditAccountAccruedInterest(address creditAccount)
        external
        view
        returns (
            uint256 borrowedAmount,
            uint256 borrowedAmountWithInterest,
            uint256 borrowedAmountWithInterestAndFees
        );

    /// @dev Maps Credit Accounts to bit masks encoding their enabled token sets
    /// Only enabled tokens are counted as collateral for the Credit Account
    /// @notice An enabled token mask encodes an enabled token by setting
    ///         the bit at the position equal to token's index to 1
    function enabledTokensMap(address creditAccount)
        external
        view
        returns (uint256);

    /// @dev Maps the Credit Account to its current percentage drop across all swaps since
    ///      the last full check, in RAY format
    function cumulativeDropAtFastCheckRAY(address creditAccount)
        external
        view
        returns (uint256);

    /// @dev Returns the collateral token at requested index and its liquidation threshold
    /// @param id The index of token to return
    function collateralTokens(uint256 id)
        external
        view
        returns (address token, uint16 liquidationThreshold);

    /// @dev Returns the collateral token with requested mask and its liquidationThreshold
    /// @param tokenMask Token mask corresponding to the token
    function collateralTokensByMask(uint256 tokenMask)
        external
        view
        returns (address token, uint16 liquidationThreshold);

    /// @dev Total number of known collateral tokens.
    function collateralTokensCount() external view returns (uint256);

    /// @dev Returns the mask for the provided token
    /// @param token Token to returns the mask for
    function tokenMasksMap(address token) external view returns (uint256);

    /// @dev Bit mask encoding a set of forbidden tokens
    function forbiddenTokenMask() external view returns (uint256);

    /// @dev Maps allowed adapters to their respective target contracts.
    function adapterToContract(address adapter) external view returns (address);

    /// @dev Maps 3rd party contracts to their respective adapters
    function contractToAdapter(address targetContract)
        external
        view
        returns (address);

    /// @dev Address of the underlying asset
    function underlying() external view returns (address);

    /// @dev Address of the connected pool
    function pool() external view returns (address);

    /// @dev Address of the connected pool
    /// @notice [DEPRECATED]: use pool() instead.
    function poolService() external view returns (address);

    /// @dev A map from borrower addresses to Credit Account addresses
    function creditAccounts(address borrower) external view returns (address);

    /// @dev Address of the connected Credit Configurator
    function creditConfigurator() external view returns (address);

    /// @dev Address of WETH
    function wethAddress() external view returns (address);

    /// @dev Returns the liquidation threshold for the provided token
    /// @param token Token to retrieve the LT for
    function liquidationThresholds(address token)
        external
        view
        returns (uint16);

    /// @dev The maximal number of enabled tokens on a single Credit Account
    function maxAllowedEnabledTokenLength() external view returns (uint8);

    /// @dev Maps addresses to their status as emergency liquidator.
    /// @notice Emergency liquidators are trusted addresses
    /// that are able to liquidate positions while the contracts are paused,
    /// e.g. when there is a risk of bad debt while an exploit is being patched.
    /// In the interest of fairness, emergency liquidators do not receive a premium
    /// And are compensated by the Gearbox DAO separately.
    function canLiquidateWhilePaused(address) external view returns (bool);

    /// @dev Returns the fee parameters of the Credit Manager
    /// @return feeInterest Percentage of interest taken by the protocol as profit
    /// @return feeLiquidation Percentage of account value taken by the protocol as profit
    ///         during unhealthy account liquidations
    /// @return liquidationDiscount Multiplier that reduces the effective totalValue during unhealthy account liquidations,
    ///         allowing the liquidator to take the unaccounted for remainder as premium. Equal to (1 - liquidationPremium)
    /// @return feeLiquidationExpired Percentage of account value taken by the protocol as profit
    ///         during expired account liquidations
    /// @return liquidationDiscountExpired Multiplier that reduces the effective totalValue during expired account liquidations,
    ///         allowing the liquidator to take the unaccounted for remainder as premium. Equal to (1 - liquidationPremiumExpired)
    function fees()
        external
        view
        returns (
            uint16 feeInterest,
            uint16 feeLiquidation,
            uint16 liquidationDiscount,
            uint16 feeLiquidationExpired,
            uint16 liquidationDiscountExpired
        );

    /// @dev Address of the connected Credit Facade
    function creditFacade() external view returns (address);

    /// @dev Address of the connected Price Oracle
    function priceOracle() external view returns (IPriceOracleV2);

    /// @dev Address of the universal adapter
    function universalAdapter() external view returns (address);

    /// @dev Contract's version
    function version() external view returns (uint256);

    /// @dev Paused() state
    function checkEmergencyPausable(address caller, bool state)
        external
        returns (bool);
}

// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2022
pragma solidity ^0.8.10;

/// @dev Common contract exceptions

/// @dev Thrown on attempting to set an important address to zero address
error ZeroAddressException();

/// @dev Thrown on attempting to call a non-implemented function
error NotImplementedException();

/// @dev Thrown on attempting to set an EOA as an important contract in the system
error AddressIsNotContractException(address);

/// @dev Thrown on attempting to use a non-ERC20 contract or an EOA as a token
error IncorrectTokenContractException();

/// @dev Thrown on attempting to set a token price feed to an address that is not a
///      correct price feed
error IncorrectPriceFeedException();

/// @dev Thrown on attempting to call an access restricted function as a non-Configurator
error CallerNotConfiguratorException();

/// @dev Thrown on attempting to pause a contract as a non-Pausable admin
error CallerNotPausableAdminException();

/// @dev Thrown on attempting to pause a contract as a non-Unpausable admin
error CallerNotUnPausableAdminException();

error TokenIsNotAddedToCreditManagerException(address token);

// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2022
pragma solidity ^0.8.10;
import { IVersion } from "./IVersion.sol";

interface IPriceOracleV2Events {
    /// @dev Emits when a new price feed is added
    event NewPriceFeed(address indexed token, address indexed priceFeed);
}

interface IPriceOracleV2Exceptions {
    /// @dev Thrown if a price feed returns 0
    error ZeroPriceException();

    /// @dev Thrown if the last recorded result was not updated in the last round
    error ChainPriceStaleException();

    /// @dev Thrown on attempting to get a result for a token that does not have a price feed
    error PriceOracleNotExistsException();
}

/// @title Price oracle interface
interface IPriceOracleV2 is
    IPriceOracleV2Events,
    IPriceOracleV2Exceptions,
    IVersion
{
    /// @dev Converts a quantity of an asset to USD (decimals = 8).
    /// @param amount Amount to convert
    /// @param token Address of the token to be converted
    function convertToUSD(uint256 amount, address token)
        external
        view
        returns (uint256);

    /// @dev Converts a quantity of USD (decimals = 8) to an equivalent amount of an asset
    /// @param amount Amount to convert
    /// @param token Address of the token converted to
    function convertFromUSD(uint256 amount, address token)
        external
        view
        returns (uint256);

    /// @dev Converts one asset into another
    ///
    /// @param amount Amount to convert
    /// @param tokenFrom Address of the token to convert from
    /// @param tokenTo Address of the token to convert to
    function convert(
        uint256 amount,
        address tokenFrom,
        address tokenTo
    ) external view returns (uint256);

    /// @dev Returns collateral values for two tokens, required for a fast check
    /// @param amountFrom Amount of the outbound token
    /// @param tokenFrom Address of the outbound token
    /// @param amountTo Amount of the inbound token
    /// @param tokenTo Address of the inbound token
    /// @return collateralFrom Value of the outbound token amount in USD
    /// @return collateralTo Value of the inbound token amount in USD
    function fastCheck(
        uint256 amountFrom,
        address tokenFrom,
        uint256 amountTo,
        address tokenTo
    ) external view returns (uint256 collateralFrom, uint256 collateralTo);

    /// @dev Returns token's price in USD (8 decimals)
    /// @param token The token to compute the price for
    function getPrice(address token) external view returns (uint256);

    /// @dev Returns the price feed address for the passed token
    /// @param token Token to get the price feed for
    function priceFeeds(address token)
        external
        view
        returns (address priceFeed);

    /// @dev Returns the price feed for the passed token,
    ///      with additional parameters
    /// @param token Token to get the price feed for
    function priceFeedsWithFlags(address token)
        external
        view
        returns (
            address priceFeed,
            bool skipCheck,
            uint256 decimals
        );
}

interface IPriceOracleV2Ext is IPriceOracleV2 {
    /// @dev Sets a price feed if it doesn't exist, or updates an existing one
    /// @param token Address of the token to set the price feed for
    /// @param priceFeed Address of a USD price feed adhering to Chainlink's interface
    function addPriceFeed(address token, address priceFeed) external;
}

// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2022
pragma solidity ^0.8.10;

/// @title IVersion
/// @dev Declares a version function which returns the contract's version
interface IVersion {
    /// @dev Returns contract version
    function version() external view returns (uint256);
}