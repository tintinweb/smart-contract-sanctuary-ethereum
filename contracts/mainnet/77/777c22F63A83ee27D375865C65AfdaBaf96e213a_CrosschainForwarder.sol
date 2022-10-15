// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";

import "./interfaces/IDeBridgeGate.sol";
import "./interfaces/ICrossChainForwarder.sol";
import "./libraries/SignatureUtil.sol";
import "./ForwarderBase.sol";

contract CrosschainForwarder is ForwarderBase, ICrossChainForwarder {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SignatureUtil for bytes;

    address public constant NATIVE_TOKEN = address(0);

    IDeBridgeGate public deBridgeGate;

    mapping(address => bool) public supportedRouters;

    /* ========== Events ========== */

    event SupportedRouter(address srcSwapRouter, bool isSupported);

    /* ========== ERRORS ========== */

    // swap router didn't put target tokens on this (forwarder's) address
    error SwapEmptyResult(address srcTokenOut);

    error SwapFailed(address srcRouter);

    error NotEnoughSrcFundsIn(uint256 amount);
    error NotSupportedRouter();

    /* ========== INITIALIZERS ========== */

    function initialize(IDeBridgeGate _deBridgeGate) external initializer {
        ForwarderBase.initializeBase();
        deBridgeGate = _deBridgeGate;
    }

    /* ========== PUBLIC METHODS ========== */

    function sendV2(
        address _srcTokenIn,
        uint256 _srcAmountIn,
        bytes memory _srcTokenInPermit,
        GateParams memory _gateParams
    ) external payable override {
        _obtainSrcTokenIn(_srcTokenIn, _srcAmountIn, _srcTokenInPermit);
        _sendToBridge(_srcTokenIn, _srcAmountIn, msg.value, _gateParams);
    }

    function sendV3(
        address _srcTokenIn,
        uint256 _srcAmountIn,
        bytes memory _srcTokenInPermit,
        uint256 _affiliateFeeAmount,
        address _affiliateFeeRecipient,
        GateParams memory _gateParams
    ) external payable override {
        _obtainSrcTokenIn(_srcTokenIn, _srcAmountIn, _srcTokenInPermit);
        (uint256 srcAmountInAfterFee, uint256 msgValueAfterFee) = _distributeAffiliateFee(
            _srcTokenIn,
            _srcAmountIn,
            _affiliateFeeAmount,
            _affiliateFeeRecipient
        );

        _sendToBridge(_srcTokenIn, srcAmountInAfterFee, msgValueAfterFee, _gateParams);
    }

    function swapAndSendV3(
        address _srcTokenIn,
        uint256 _srcAmountIn,
        bytes memory _srcTokenInPermit,
        uint256 _affiliateFeeAmount,
        address _affiliateFeeRecipient,
        address _srcSwapRouter,
        bytes calldata _srcSwapCalldata,
        address _srcTokenOut,
        GateParams memory _gateParams
    ) external payable override {
        _obtainSrcTokenIn(_srcTokenIn, _srcAmountIn, _srcTokenInPermit);
        (uint256 srcAmountInAfterFee, uint256 msgValueAfterFee) = _distributeAffiliateFee(
            _srcTokenIn,
            _srcAmountIn,
            _affiliateFeeAmount,
            _affiliateFeeRecipient
        );

        (uint256 srcAmountOut, uint256 msgValueAfterSwap) = _performSwap(
            _srcTokenIn,
            srcAmountInAfterFee,
            msgValueAfterFee,
            _srcSwapRouter,
            _srcSwapCalldata,
            _srcTokenOut
        );

        _sendToBridge(_srcTokenOut, srcAmountOut, msgValueAfterSwap, _gateParams);
    }

    function swapAndSendV2(
        address _srcTokenIn,
        uint256 _srcAmountIn,
        bytes memory _srcTokenInPermit,
        address _srcSwapRouter,
        bytes calldata _srcSwapCalldata,
        address _srcTokenOut,
        GateParams memory _gateParams
    ) external payable override {
        _obtainSrcTokenIn(_srcTokenIn, _srcAmountIn, _srcTokenInPermit);

        (uint256 srcAmountOut, uint256 msgValueAfterSwap) = _performSwap(
            _srcTokenIn,
            _srcAmountIn,
            msg.value,
            _srcSwapRouter,
            _srcSwapCalldata,
            _srcTokenOut
        );

        _sendToBridge(_srcTokenOut, srcAmountOut, msgValueAfterSwap, _gateParams);
    }

    /* ========== INTERNAL METHODS ========== */

    function _distributeAffiliateFee(
        address _srcTokenIn,
        uint256 _srcAmountIn,
        uint256 _affiliateFeeAmount,
        address _affiliateFeeRecipient
    ) internal returns (uint256 srcAmountInCleared, uint256 msgValueInCleared) {
        srcAmountInCleared = _srcAmountIn;
        msgValueInCleared = msg.value;

        if (_affiliateFeeAmount > 0 && _affiliateFeeRecipient != address(0)) {
            // cut off fee from srcAmountInCleared
            srcAmountInCleared -= _affiliateFeeAmount;

            if (_srcTokenIn == NATIVE_TOKEN) {
                // reduce value as well!
                msgValueInCleared -= _affiliateFeeAmount;

                (bool success, ) = _affiliateFeeRecipient.call{
                    value: _affiliateFeeAmount
                }("");
                if (!success) {
                    revert AffiliateFeeDistributionFailed(
                        _affiliateFeeRecipient,
                        NATIVE_TOKEN,
                        _affiliateFeeAmount
                    );
                }
            } else {
                IERC20Upgradeable(_srcTokenIn).safeTransfer(
                    _affiliateFeeRecipient,
                    _affiliateFeeAmount
                );
            }
        }
    }

    function _obtainSrcTokenIn(
        address _srcTokenIn,
        uint256 _srcAmountIn,
        bytes memory _srcTokenInPermit
    ) internal {
        if (_srcTokenIn == NATIVE_TOKEN) {
            if (!(address(this).balance > _srcAmountIn))
                revert NotEnoughSrcFundsIn(_srcAmountIn);
        } else {
            uint256 srcAmountCleared = _collectSrcERC20In(
                IERC20Upgradeable(_srcTokenIn),
                _srcAmountIn,
                _srcTokenInPermit
            );
            if (srcAmountCleared < _srcAmountIn)
                revert NotEnoughSrcFundsIn(_srcAmountIn);
        }
    }

    function _performSwap(
        address _srcTokenIn,
        uint256 _srcAmountIn,
        uint256 _msgValue,
        address _srcSwapRouter,
        bytes calldata _srcSwapCalldata,
        address _srcTokenOut
    ) internal returns (uint256 srcAmountOut, uint256 msgValueAfterSwap) {
        if (!supportedRouters[_srcSwapRouter]) revert NotSupportedRouter();

        uint256 ethBalanceBefore = address(this).balance - _msgValue;

        if (_srcTokenIn == NATIVE_TOKEN) {
            srcAmountOut = _swapToERC20Via(
                _srcSwapRouter,
                _srcSwapCalldata,
                _srcAmountIn,
                IERC20Upgradeable(_srcTokenOut)
            );
        } else {
            IERC20Upgradeable(_srcTokenIn).safeApprove(
                _srcSwapRouter,
                _srcAmountIn
            );
            if (_srcTokenOut == NATIVE_TOKEN) {
                srcAmountOut = _swapToETHVia(_srcSwapRouter, _srcSwapCalldata);
            } else {
                srcAmountOut = _swapToERC20Via(
                    _srcSwapRouter,
                    _srcSwapCalldata,
                    0, /*value*/
                    IERC20Upgradeable(_srcTokenOut)
                );
            }
            IERC20Upgradeable(_srcTokenIn).safeApprove(_srcSwapRouter, 0);
        }

        msgValueAfterSwap = address(this).balance - ethBalanceBefore;
    }

    function _collectSrcERC20In(
        IERC20Upgradeable _token,
        uint256 _amount,
        bytes memory _permit
    ) internal returns (uint256) {
        // call permit before transferring token
        if (_permit.length > 0) {
            uint256 deadline = _permit.toUint256(0);
            (bytes32 r, bytes32 s, uint8 v) = _permit.parseSignature(32);
            IERC20Permit(address(_token)).permit(
                msg.sender,
                address(this),
                _amount,
                deadline,
                v,
                r,
                s
            );
        }

        uint256 balanceBefore = _token.balanceOf(address(this));
        _token.safeTransferFrom(msg.sender, address(this), _amount);
        uint256 balanceAfter = _token.balanceOf(address(this));

        if (!(balanceAfter > balanceBefore))
            revert NotEnoughSrcFundsIn(_amount);

        return (balanceAfter - balanceBefore);
    }

    function _swapToETHVia(address _router, bytes calldata _calldata)
        internal
        returns (uint256)
    {
        uint256 balanceBefore = address(this).balance;

        bool success = _externalCall(_router, _calldata, 0);
        if (!success) {
            revert SwapFailed(_router);
        }

        uint256 balanceAfter = address(this).balance;

        if (balanceBefore >= balanceAfter) revert SwapEmptyResult(address(0));

        uint256 swapDstTokenBalance = balanceAfter - balanceBefore;
        return swapDstTokenBalance;
    }

    function _swapToERC20Via(
        address _router,
        bytes calldata _calldata,
        uint256 _msgValue,
        IERC20Upgradeable _targetToken
    ) internal returns (uint256) {
        uint256 balanceBefore = _targetToken.balanceOf(address(this));

        bool success = _externalCall(_router, _calldata, _msgValue);
        if (!success) {
            revert SwapFailed(_router);
        }

        uint256 balanceAfter = _targetToken.balanceOf(address(this));
        if (balanceBefore >= balanceAfter)
            revert SwapEmptyResult(address(_targetToken));

        uint256 swapDstTokenBalance = balanceAfter - balanceBefore;
        return swapDstTokenBalance;
    }

    function _sendToBridge(
        address token,
        uint256 amount,
        uint256 _msgValue,
        GateParams memory _gateParams
    ) internal {
        // remember balance to correctly calc the change
        uint256 ethBalanceBefore = address(this).balance - _msgValue;

        if (token != NATIVE_TOKEN) {
            // allow deBridge gate to take all these wrapped tokens
            IERC20Upgradeable(token).safeApprove(address(deBridgeGate), amount);
        }

        // send to deBridge gate
        deBridgeGate.send{value: _msgValue}(
            token, // _tokenAddress
            amount, // _amount
            _gateParams.chainId, // _chainIdTo
            abi.encodePacked(_gateParams.receiver), // _receiver
            "", // _permit
            _gateParams.useAssetFee, // _useAssetFee
            _gateParams.referralCode, // _referralCode
            _gateParams.autoParams // _autoParams
        );

        if (token != NATIVE_TOKEN) {
            // turn off allowance
            IERC20Upgradeable(token).safeApprove(address(deBridgeGate), 0);
        }

        // return change, if any
        if (address(this).balance > ethBalanceBefore) {
            _safeTransferETH(
                msg.sender,
                address(this).balance - ethBalanceBefore
            );
        }
    }

    function updateSupportedRouter(address _srcSwapRouter, bool _isSupported)
        external
        onlyAdmin
    {
        supportedRouters[_srcSwapRouter] = _isSupported;
        emit SupportedRouter(_srcSwapRouter, _isSupported);
    }

    // ============ Version Control ============

    /// @dev Get this contract's version
    function version() external pure returns (uint256) {
        return 131; // 1.3.1
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
        IERC20PermitUpgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IDeBridgeGate {
    /* ========== STRUCTS ========== */

    struct TokenInfo {
        uint256 nativeChainId;
        bytes nativeAddress;
    }

    struct DebridgeInfo {
        uint256 chainId; // native chain id
        uint256 maxAmount; // maximum amount to transfer
        uint256 balance; // total locked assets
        uint256 lockedInStrategies; // total locked assets in strategy (AAVE, Compound, etc)
        address tokenAddress; // asset address on the current chain
        uint16 minReservesBps; // minimal hot reserves in basis points (1/10000)
        bool exist;
    }

    struct DebridgeFeeInfo {
        uint256 collectedFees; // total collected fees
        uint256 withdrawnFees; // fees that already withdrawn
        mapping(uint256 => uint256) getChainFee; // whether the chain for the asset is supported
    }

    struct ChainSupportInfo {
        uint256 fixedNativeFee; // transfer fixed fee
        bool isSupported; // whether the chain for the asset is supported
        uint16 transferFeeBps; // transfer fee rate nominated in basis points (1/10000) of transferred amount
    }

    struct DiscountInfo {
        uint16 discountFixBps; // fix discount in BPS
        uint16 discountTransferBps; // transfer % discount in BPS
    }

    /// @param executionFee Fee paid to the transaction executor.
    /// @param fallbackAddress Receiver of the tokens if the call fails.
    struct SubmissionAutoParamsTo {
        uint256 executionFee;
        uint256 flags;
        bytes fallbackAddress;
        bytes data;
    }

    /// @param executionFee Fee paid to the transaction executor.
    /// @param fallbackAddress Receiver of the tokens if the call fails.
    struct SubmissionAutoParamsFrom {
        uint256 executionFee;
        uint256 flags;
        address fallbackAddress;
        bytes data;
        bytes nativeSender;
    }

    struct FeeParams {
        uint256 receivedAmount;
        uint256 fixFee;
        uint256 transferFee;
        bool useAssetFee;
        bool isNativeToken;
    }

    /* ========== PUBLIC VARS GETTERS ========== */
    /// @dev Returns whether the transfer with the submissionId was claimed.
    /// submissionId is generated in getSubmissionIdFrom
    function isSubmissionUsed(bytes32 submissionId) external returns (bool);

    /* ========== FUNCTIONS ========== */
    function callProxy() external returns (address);

    /// @dev This method is used for the transfer of assets [from the native chain](https://docs.debridge.finance/the-core-protocol/transfers#transfer-from-native-chain).
    /// It locks an asset in the smart contract in the native chain and enables minting of deAsset on the secondary chain.
    /// @param _tokenAddress Asset identifier.
    /// @param _amount Amount to be transferred (note: the fee can be applied).
    /// @param _chainIdTo Chain id of the target chain.
    /// @param _receiver Receiver address.
    /// @param _permit deadline + signature for approving the spender by signature.
    /// @param _useAssetFee use assets fee for pay protocol fix (work only for specials token)
    /// @param _referralCode Referral code
    /// @param _autoParams Auto params for external call in target network
    function send(
        address _tokenAddress,
        uint256 _amount,
        uint256 _chainIdTo,
        bytes memory _receiver,
        bytes memory _permit,
        bool _useAssetFee,
        uint32 _referralCode,
        bytes calldata _autoParams
    ) external payable;

    /// @dev Is used for transfers [into the native chain](https://docs.debridge.finance/the-core-protocol/transfers#transfer-from-secondary-chain-to-native-chain)
    /// to unlock the designated amount of asset from collateral and transfer it to the receiver.
    /// @param _debridgeId Asset identifier.
    /// @param _amount Amount of the transferred asset (note: the fee can be applied).
    /// @param _chainIdFrom Chain where submission was sent
    /// @param _receiver Receiver address.
    /// @param _nonce Submission id.
    /// @param _signatures Validators signatures to confirm
    /// @param _autoParams Auto params for external call
    function claim(
        bytes32 _debridgeId,
        uint256 _amount,
        uint256 _chainIdFrom,
        address _receiver,
        uint256 _nonce,
        bytes calldata _signatures,
        bytes calldata _autoParams
    ) external;

    /// @dev Get a flash loan, msg.sender must implement IFlashCallback
    /// @param _tokenAddress An asset to loan
    /// @param _receiver Where funds should be sent
    /// @param _amount Amount to loan
    /// @param _data Data to pass to sender's flashCallback function
    function flash(
        address _tokenAddress,
        address _receiver,
        uint256 _amount,
        bytes memory _data
    ) external;

    /// @dev Get reserves of a token available to use in defi
    /// @param _tokenAddress Token address
    function getDefiAvaliableReserves(address _tokenAddress)
        external
        view
        returns (uint256);

    /// @dev Request the assets to be used in DeFi protocol.
    /// @param _tokenAddress Asset address.
    /// @param _amount Amount of tokens to request.
    function requestReserves(address _tokenAddress, uint256 _amount) external;

    /// @dev Return the assets that were used in DeFi  protocol.
    /// @param _tokenAddress Asset address.
    /// @param _amount Amount of tokens to claim.
    function returnReserves(address _tokenAddress, uint256 _amount) external;

    /// @dev Withdraw collected fees to feeProxy
    /// @param _debridgeId Asset identifier.
    function withdrawFee(bytes32 _debridgeId) external;

    /// @dev Get native chain id and native address of a token
    /// @param currentTokenAddress address of a token on the current chain
    function getNativeTokenInfo(address currentTokenAddress)
        external
        view
        returns (uint256 chainId, bytes memory nativeAddress);

    /// @dev Returns asset fixed fee value for specified debridge and chainId.
    /// @param _debridgeId Asset identifier.
    /// @param _chainId Chain id.
    function getDebridgeChainAssetFixedFee(
        bytes32 _debridgeId,
        uint256 _chainId
    ) external view returns (uint256);

    /* ========== EVENTS ========== */

    /// @dev Emitted once the tokens are sent from the original(native) chain to the other chain; the transfer tokens
    /// are expected to be claimed by the users.
    event Sent(
        bytes32 submissionId,
        bytes32 indexed debridgeId,
        uint256 amount,
        bytes receiver,
        uint256 nonce,
        uint256 indexed chainIdTo,
        uint32 referralCode,
        FeeParams feeParams,
        bytes autoParams,
        address nativeSender
        // bool isNativeToken //added to feeParams
    );

    /// @dev Emitted once the tokens are transferred and withdrawn on a target chain
    event Claimed(
        bytes32 submissionId,
        bytes32 indexed debridgeId,
        uint256 amount,
        address indexed receiver,
        uint256 nonce,
        uint256 indexed chainIdFrom,
        bytes autoParams,
        bool isNativeToken
    );

    /// @dev Emitted when new asset support is added.
    event PairAdded(
        bytes32 debridgeId,
        address tokenAddress,
        bytes nativeAddress,
        uint256 indexed nativeChainId,
        uint256 maxAmount,
        uint16 minReservesBps
    );

    /// @dev Emitted when the asset is allowed/disallowed to be transferred to the chain.
    event ChainSupportUpdated(
        uint256 chainId,
        bool isSupported,
        bool isChainFrom
    );
    /// @dev Emitted when the supported chains are updated.
    event ChainsSupportUpdated(
        uint256 chainIds,
        ChainSupportInfo chainSupportInfo,
        bool isChainFrom
    );

    /// @dev Emitted when the new call proxy is set.
    event CallProxyUpdated(address callProxy);
    /// @dev Emitted when the transfer request is executed.
    event AutoRequestExecuted(
        bytes32 submissionId,
        bool indexed success,
        address callProxy
    );

    /// @dev Emitted when a submission is blocked.
    event Blocked(bytes32 submissionId);
    /// @dev Emitted when a submission is unblocked.
    event Unblocked(bytes32 submissionId);

    /// @dev Emitted when a flash loan is successfully returned.
    event Flash(
        address sender,
        address indexed tokenAddress,
        address indexed receiver,
        uint256 amount,
        uint256 paid
    );

    /// @dev Emitted when fee is withdrawn.
    event WithdrawnFee(bytes32 debridgeId, uint256 fee);

    /// @dev Emitted when globalFixedNativeFee and globalTransferFeeBps are updated.
    event FixedNativeFeeUpdated(
        uint256 globalFixedNativeFee,
        uint256 globalTransferFeeBps
    );

    /// @dev Emitted when globalFixedNativeFee is updated by feeContractUpdater
    event FixedNativeFeeAutoUpdated(uint256 globalFixedNativeFee);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

interface ICrossChainForwarder {
    error AffiliateFeeDistributionFailed(
        address recipient,
        address token,
        uint256 amount
    );

    struct GateParams {
        uint256 chainId;
        address receiver;
        bool useAssetFee;
        uint32 referralCode;
        bytes autoParams;
    }

    /// @dev Takes `_srcTokenInAmount` of `_srcTokenIn` from the msg.sender (executing `_srcTokenInPermit` if given),
    ///      swaps `_srcTokenIn` to `_srcTokenOut` by `CALL`-ing `_srcSwapCalldata` against `_srcSwapRouter`,
    ///      and finally sends the result of a swap to deBridge gate using the given gateParams
    /// @notice Since 1.2.0
    function swapAndSendV2(
        address _srcTokenIn,
        uint256 _srcTokenInAmount,
        bytes memory _srcTokenInPermit,
        address _srcSwapRouter,
        bytes calldata _srcSwapCalldata,
        address _srcTokenOut,
        GateParams memory _gateParams
    ) external payable;

    /// @dev Takes `_srcTokenInAmount` of `_srcTokenIn` from the msg.sender (executing `_srcTokenInPermit` if given),
    ///      cuts off the `affiliateFeeAmount` of `_srcTokenIn` sending this fee to `affiliateFeeRecipient` (if given),
    ///      swaps `_srcTokenIn` to `_srcTokenOut` by `CALL`-ing `_srcSwapCalldata` against `_srcSwapRouter`,
    ///      and finally sends the result of a swap to deBridge gate using the given gateParams
    /// @notice Since 1.3.0
    function swapAndSendV3(
        address _srcTokenIn,
        uint256 _srcTokenInAmount,
        bytes memory _srcTokenInPermit,
        uint256 _affiliateFeeAmount,
        address _affiliateFeeRecipient,
        address _srcSwapRouter,
        bytes calldata _srcSwapCalldata,
        address _srcTokenOut,
        GateParams memory _gateParams
    ) external payable;

    /// @dev Takes `_srcTokenInAmount` of `_srcTokenIn` from the msg.sender (executing `_srcTokenInPermit` if given),
    ///      and finally sends the resulting amount to deBridge gate using the given gateParams
    /// @notice Since 1.3.0
    function sendV2(
        address _srcTokenIn,
        uint256 _srcTokenInAmount,
        bytes memory _srcTokenInPermit,
        GateParams memory _gateParams
    ) external payable;

    /// @dev Takes `_srcTokenInAmount` of `_srcTokenIn` from the msg.sender (executing `_srcTokenInPermit` if given),
    ///      cuts off the `affiliateFeeAmount` of `_srcTokenIn` sending this fee to `affiliateFeeRecipient` (if given),
    ///      and finally sends the resulting amount to deBridge gate using the given gateParams
    /// @notice Since 1.3.0
    function sendV3(
        address _srcTokenIn,
        uint256 _srcTokenInAmount,
        bytes memory _srcTokenInPermit,
        uint256 _affiliateFeeAmount,
        address _affiliateFeeRecipient,
        GateParams memory _gateParams
    ) external payable;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

library SignatureUtil {
    /* ========== ERRORS ========== */

    error WrongArgumentLength();
    error SignatureInvalidLength();
    error SignatureInvalidV();

    /// @dev Prepares raw msg that was signed by the oracle.
    /// @param _submissionId Submission identifier.
    function getUnsignedMsg(bytes32 _submissionId) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _submissionId));
    }

    /// @dev Splits signature bytes to r,s,v components.
    /// @param _signature Signature bytes in format r+s+v.
    function splitSignature(bytes memory _signature)
        internal
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        if (_signature.length != 65) revert SignatureInvalidLength();
        return parseSignature(_signature, 0);
    }

    function parseSignature(bytes memory _signatures, uint256 offset)
        internal
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        assembly {
            r := mload(add(_signatures, add(32, offset)))
            s := mload(add(_signatures, add(64, offset)))
            v := and(mload(add(_signatures, add(65, offset))), 0xff)
        }

        if (v < 27) v += 27;
        if (v != 27 && v != 28) revert SignatureInvalidV();
    }

    function toUint256(bytes memory _bytes, uint256 _offset)
        internal
        pure
        returns (uint256 result)
    {
        if (_bytes.length < _offset + 32) revert WrongArgumentLength();

        assembly {
            result := mload(add(add(_bytes, 0x20), _offset))
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

contract ForwarderBase is Initializable, AccessControlUpgradeable {

    /* ========== ERRORS ========== */

    error EthTransferFailed();
    error AdminBadRole();

    /* ========== MODIFIERS ========== */

    modifier onlyAdmin() {
        if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) revert AdminBadRole();
        _;
    }

    /* ========== INITIALIZERS ========== */

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initializeBase() internal initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function _externalCall(
        address _destination,
        bytes memory _data,
        uint256 _value
    ) internal returns (bool result) {
        assembly {
            result := call(
                gas(),
                _destination,
                _value,
                add(_data, 0x20),
                mload(_data),
                0,
                0
            )
        }
    }

    /*
     * @dev transfer ETH to an address, revert if it fails.
     * @param to recipient of the transfer
     * @param value the amount to send
     */
    function _safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        if (!success) revert EthTransferFailed();
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT
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
interface IERC20PermitUpgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
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
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
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
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
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
interface IERC165Upgradeable {
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import "./interfaces/IReceivingForwarder.sol";
import "./libraries/SwapCalldataUtils.sol";
import "./ForwarderBase.sol";

contract ReceivingForwarder is ForwarderBase, IReceivingForwarder {
    using SwapCalldataUtils for bytes;
    using AddressUpgradeable for address;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address public constant NATIVE_TOKEN = address(0);

    /* ========== ERRORS ========== */

    error SwapFailed(address dstRouter);

    /* ========== INITIALIZERS ========== */

    function initialize() external initializer {
        ForwarderBase.initializeBase();
    }

    /* ========== FORWARDER METHOD ========== */

    function forward(
        address _dstTokenIn,
        address _router,
        bytes memory _routerCalldata,
        address _dstTokenOut,
        address _fallbackAddress
    ) external payable override {
        if (_dstTokenIn == NATIVE_TOKEN) {
            return _forwardFromETH(
                _router,
                _routerCalldata,
                new uint16[](0),
                _dstTokenOut,
                _fallbackAddress
            );
        }
        else {
            return _forwardFromERC20(
                IERC20Upgradeable(_dstTokenIn),
                _router,
                _routerCalldata,
                new uint16[](0),
                _dstTokenOut,
                _fallbackAddress
            );
        }
    }

    function forwardUniversal(
        address _dstTokenIn,
        address _router,
        bytes memory _routerCalldata,
        uint16[] memory _routerAmountPositions,
        address _dstTokenOut,
        address _fallbackAddress
    ) external payable override {
        if (_dstTokenIn == NATIVE_TOKEN) {
            return _forwardFromETH(
                _router,
                _routerCalldata,
                _routerAmountPositions,
                _dstTokenOut,
                _fallbackAddress
            );
        }
        else {
            return _forwardFromERC20(
                IERC20Upgradeable(_dstTokenIn),
                _router,
                _routerCalldata,
                _routerAmountPositions,
                _dstTokenOut,
                _fallbackAddress
            );
        }
    }

    /* ========== INTERNAL METHODS ========== */

    function _forwardFromETH(
        address _router,
        bytes memory _routerCalldata,
        uint16[] memory _routerAmountPositions,
        address _dstTokenOut,
        address _fallbackAddress
    ) internal {
        uint correction = address(this).balance - msg.value;
        uint dstTokenInAmount = msg.value;

        _forward(
            NATIVE_TOKEN,
            dstTokenInAmount,
            _router,
            _routerCalldata,
            _routerAmountPositions,
            _dstTokenOut,
            _fallbackAddress
        );

        if(address(this).balance > correction) {
            _safeTransferETH(_fallbackAddress, address(this).balance - correction);
        }
    }

    function _forwardFromERC20(
        IERC20Upgradeable dstTokenIn,
        address _router,
        bytes memory _routerCalldata,
        uint16[] memory _routerAmountPositions,
        address _dstTokenOut,
        address _fallbackAddress
    ) internal {
        // 1. Grab tokens from the gate
        uint correction = dstTokenIn.balanceOf(address(this));
        uint dstTokenInAmount = dstTokenIn.balanceOf(msg.sender);
        dstTokenIn.safeTransferFrom(
            msg.sender,
            address(this),
            dstTokenInAmount
        );

        dstTokenInAmount = dstTokenIn.balanceOf(address(this)) - correction;
        _customApprove(dstTokenIn, _router, dstTokenInAmount);

        _forward(
            address(dstTokenIn),
            dstTokenInAmount,
            _router,
            _routerCalldata,
            _routerAmountPositions,
            _dstTokenOut,
            _fallbackAddress
        );

        // finalize
        dstTokenIn.safeApprove(_router, 0);
        uint postBalance = dstTokenIn.balanceOf(address(this));
        if (postBalance > correction) {
            dstTokenIn.safeTransfer(_fallbackAddress, postBalance - correction);
        }
    }

    function _customApprove(IERC20Upgradeable token, address spender, uint value) internal {
        bytes memory returndata = address(token).functionCall(
            abi.encodeWithSelector(token.approve.selector, spender, value),
            "ERC20 approve failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "ERC20 operation did not succeed");
        }
    }

    function _forwardToETH(
        address _router,
        bytes memory _routerCalldata,
        address _fallbackAddress
    ) internal {
        uint balanceBefore = address(this).balance;

        // value=0 because it's obvious that we won't need ETH to swap to ETH
        // (i.e., impossible: dstTokenIn == dstTokenOut == address(0))
        bool success = _externalCall(_router, _routerCalldata, 0);
        if (!success) {
            revert SwapFailed(_router);
        }

        uint balanceAfter = address(this).balance;

        if (balanceAfter > balanceBefore) {
            _safeTransferETH(_fallbackAddress, balanceAfter - balanceBefore);
        }
    }

    function _forwardToERC20(
        uint256 dstAmountIn,
        address _router,
        bytes memory _routerCalldata,
        IERC20Upgradeable dstTokenOut,
        address _fallbackAddress
    ) internal {
        uint balanceBefore = dstTokenOut.balanceOf(address(this));

        bool success = _externalCall(_router, _routerCalldata, dstAmountIn);
        if (!success) {
            revert SwapFailed(_router);
        }

        uint balanceAfter = dstTokenOut.balanceOf(address(this));

        if (balanceAfter > balanceBefore) {
            dstTokenOut.safeTransfer(
                _fallbackAddress,
                balanceAfter - balanceBefore
            );
        }
    }

    function _forward(
        address _dstTokenIn,
        uint256 _dstAmountIn,
        address _router,
        bytes memory _routerCalldata,
        uint16[] memory _routerAmountPositions,
        address _dstTokenOut,
        address _fallbackAddress
    ) internal {
        bytes memory patchedCalldata;
        bool success;

        if (_routerAmountPositions.length > 0) {
            patchedCalldata = _routerCalldata;

            for (
                uint16 i = 0;
                i < _routerAmountPositions.length;
                i += 1
            ) {
                (patchedCalldata, success) = patchedCalldata.patchAt(
                    _dstAmountIn,
                    _routerAmountPositions[i]
                );

                if (!success) break;
            }
        }
        else {
            (patchedCalldata, success) = _routerCalldata.patch(
                _dstAmountIn
            );
        }

        if (!success) {
            return;
        }

        if (_dstTokenOut == NATIVE_TOKEN) {
            return _forwardToETH(
                 _router,
                 patchedCalldata,
                 _fallbackAddress
            );
        }
        else if (_dstTokenIn == NATIVE_TOKEN) {
            return _forwardToERC20(
                 _dstAmountIn,
                 _router,
                 patchedCalldata,
                 IERC20Upgradeable(_dstTokenOut),
                 _fallbackAddress
            );
        }
        else {
            return _forwardToERC20(
                 0,
                 _router,
                 patchedCalldata,
                 IERC20Upgradeable(_dstTokenOut),
                 _fallbackAddress
            );
        }
    }

    // ============ Version Control ============

    /// @dev Get this contract's version
    function version() external pure returns (uint256) {
        return 121; // 1.2.1
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

interface IReceivingForwarder {
    function forward(
        address _dstTokenIn,
        address _router,
        bytes memory _routerCalldata,
        address _dstTokenOut,
        address _fallbackAddress
    ) external payable;

    function forwardUniversal(
        address _dstTokenIn,
        address _router,
        bytes memory _routerCalldata,
        uint16[] memory _routerAmountPositions,
        address _dstTokenOut,
        address _fallbackAddress
    ) external payable;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

import "./CalldataUtils.sol";

library SwapCalldataUtils {
    using CalldataUtils for bytes;

    bytes4 public constant SWAP_SELECTOR = 0x7c025200;
    bytes4 public constant UNOSWAP_SELECTOR = 0x2e95b6c8;
    bytes4 public constant UNOSWAPV3_SELECTOR = 0xe449022e;
    bytes4 public constant FILLORDERRFQ_SELECTOR = 0xd0a3b665;
    bytes4 public constant CLIPPERSWAP_SELECTOR = 0xb0431182;
    bytes4 public constant YY_SWAP_NO_SPLIT = 0x6bf2df86;
    bytes4 public constant YY_SWAP_NO_SPLIT_FROM_AVAX = 0xfe38c5e6;
    bytes4 public constant YY_SWAP_NO_SPLIT_TO_AVAX = 0xf0350382;

    function patchAt(bytes memory _data, uint256 amount, uint16 pos)
        internal
        pure
        returns (bytes memory patchedData, bool success)
    {
        if (_data.length >= pos + 32) {
            success = true;
            patchedData = bytes.concat(
                _data.slice(0, pos), //   _data[:pos],
                abi.encodePacked(amount),
                _data.slice(pos + 32, _data.length - (pos + 32)) //_data[pos+32:]
            );
        }
    }

    function patch(bytes memory _data, uint256 amount)
        internal
        pure
        returns (bytes memory patchedData, bool success)
    {
        bytes4 sig = _data.getSig();
        (uint256 pos, bool success_) = getAmountPos(sig);

        if (success_ && _data.length >= pos + 32) {
            success = true;
            patchedData = bytes.concat(
                _data.slice(0, pos), //   _data[:pos],
                abi.encodePacked(amount),
                _data.slice(pos + 32, _data.length - (pos + 32)) //_data[pos+32:]
            );
        }
    }

    function getAmount(bytes memory _data)
        internal
        pure
        returns (uint256 amount, bool success)
    {
        (uint256 pos, bool amountSuccess) = getAmountPos(_data.getSig());
        if (!amountSuccess || _data.length < pos + 32) {
            return (0, false);
        }

        assembly {
            amount := mload(add(_data, add(0x20, pos)))
        }
        success = true;
    }

    function getAmountPos(bytes4 sig)
        internal
        pure
        returns (uint256 pos, bool success)
    {
        success = true;
        if (sig == SWAP_SELECTOR) {
            // 456
            pos = 228;
        } else if (sig == UNOSWAP_SELECTOR) {
            // 72
            pos = 36;
        } else if (sig == UNOSWAPV3_SELECTOR) {
            // 8
            pos = 4;
        } else if (sig == FILLORDERRFQ_SELECTOR) {
            // 584
            pos = 292;
        } else if (sig == CLIPPERSWAP_SELECTOR) {
            //136
            pos = 68;
        } else if (sig == YY_SWAP_NO_SPLIT || sig == YY_SWAP_NO_SPLIT_FROM_AVAX || sig == YY_SWAP_NO_SPLIT_TO_AVAX) {
            // 200
            pos = 100;
        } else {
            success = false;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

// Gas efficient calldata parser
// https://github.com/ethereum/solidity/issues/9439#issuecomment-660134770
library CalldataUtils {
    function getSig(bytes memory _data) internal pure returns (bytes4 sig) {
        assembly {
            sig := mload(add(_data, 32))
        }
    }

    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    ) internal pure returns (bytes memory) {
        require(_bytes.length >= (_start + _length));

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(
                    add(tempBytes, lengthmod),
                    mul(0x20, iszero(lengthmod))
                )
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(
                        add(
                            add(_bytes, lengthmod),
                            mul(0x20, iszero(lengthmod))
                        ),
                        _start
                    )
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../libraries/SwapCalldataUtils.sol";

contract TargetTokenHolder {
    using SafeERC20 for IERC20;
    using SwapCalldataUtils for bytes;

    address targetToken;

    constructor(address targetToken_) {
        targetToken = targetToken_;
    }

    // called for any calldata (see SAMPLE_CALLDATA in src/SwapCalldataParser.js)
    // thus emulating real-world pool/router behavior
    fallback (bytes calldata _input) external returns (bytes memory) {
        (uint256 amount, bool success) = _input.getAmount();
        if (success) {
            IERC20(targetToken).transferFrom(msg.sender, address(this), amount);
        }
    }

    function obtain(address _wrappedToken) external {
        IERC20 wrappedToken = IERC20(_wrappedToken);
        wrappedToken.transferFrom(
            msg.sender,
            address(this),
            wrappedToken.balanceOf(msg.sender)
        );
    }
}

// SPDX-License-Identifier: MIT
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../interfaces/ICurve.sol";
import "../libraries/SwapCalldataUtils.sol";
import "../libraries/Flags.sol";

contract DummyPool is ICurve {
    using SwapCalldataUtils for bytes;

    address public tokenA;
    address public tokenB;

    constructor(address _tokenA, address _tokenB) {
        tokenA = _tokenA;
        tokenB = _tokenB;
    }

    // called for any calldata (see SAMPLE_CALLDATA in src/SwapCalldataParser.js)
    // thus emulating real-world pool/router behavior
    fallback (bytes calldata _input) external returns (bytes memory) {
        // pick token where msg.sender have positive balance
        address token = IERC20(tokenA).balanceOf(msg.sender) > 0
            ? tokenA
            : tokenB;
        require(IERC20(token).balanceOf(msg.sender) > 0, "unexpected zeroes");

        // extract amount from the calldata
        (uint256 amount, bool success) = _input.getAmount();
        if (success) {
            (IERC20 srcToken, IERC20 dstToken) = _getSrcAndDst(token);
            _swap(srcToken, dstToken, msg.sender, msg.sender, amount);
        }
    }

    function swap(
        address token,
        address from,
        address to,
        uint256 amount
    ) external returns (uint256) {
        (IERC20 srcToken, IERC20 dstToken) = _getSrcAndDst(token);
        return _swap(srcToken, dstToken, from, to, amount);
    }

    function swap(
        address token,
        address from,
        address to
    ) external returns (uint256) {
        (IERC20 srcToken, IERC20 dstToken) = _getSrcAndDst(token);

        uint256 amount = srcToken.balanceOf(from);
        return _swap(srcToken, dstToken, from, to, amount);
    }

    function exchange_underlying(
        int128 _i,
        int128 _j,
        uint256 _dx,
        uint256 _min_dy
    ) external override returns (uint256) {
        address token = _i == 0 ? tokenA : tokenB;
        (IERC20 srcToken, IERC20 dstToken) = _getSrcAndDst(token);
        return _swap(srcToken, dstToken, msg.sender, msg.sender, _dx);
    }

    function exchange_underlying(
        address _pool,
        int128 _i,
        int128 _j,
        uint256 _dx,
        uint256 _min_dy,
        address _receiver
    ) external override returns (uint256) {
        address token = _i == 0 ? tokenA : tokenB;
        (IERC20 srcToken, IERC20 dstToken) = _getSrcAndDst(token);
        return _swap(srcToken, dstToken, msg.sender, _receiver, _dx);

        // address token = _i == 0 ? tokenA : tokenB;
        // (IERC20 srcToken, IERC20 dstToken) = _getSrcAndDst(token);

        // srcToken.transferFrom(msg.sender, address(this), _dx);
        // uint amount = ICurve(_pool).exchange_underlying(_i, _j, _dx, _min_dy);
        // if (amount > 0) {
        //     dstToken.transfer(_receiver, amount);
        // }
        // else {
        //     srcToken.transfer(msg.sender, _dx);
        // }
    }

    function _getSrcAndDst(address _srcToken)
        internal
        view
        returns (IERC20 srcToken, IERC20 dstToken)
    {
        srcToken = IERC20(tokenA);
        dstToken = IERC20(tokenB);
        if (_srcToken == address(dstToken)) {
            dstToken = srcToken;
            srcToken = IERC20(_srcToken);
        } else {
            require(_srcToken == address(srcToken));
        }
    }

    function _swap(
        IERC20 srcToken,
        IERC20 dstToken,
        address from,
        address to,
        uint256 amount
    ) internal returns (uint256) {
        uint256 amountOut = amount - amount / 100;

        if (dstToken.balanceOf(address(this)) > amountOut) {
            srcToken.transferFrom(from, address(this), amount);

            dstToken.transfer(to, amount - amount / 100);

            return amountOut;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

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

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.7;

interface ICurve {
    function exchange_underlying(
        int128 _i,
        int128 _j,
        uint256 _dx,
        uint256 _min_dy
    ) external returns (uint256);

    // @external
    // def exchange_underlying(
    //     _pool: address,
    //     _i: int128,
    //     _j: int128,
    //     _dx: uint256,
    //     _min_dy: uint256,
    //     _receiver: address = msg.sender,
    //     _use_underlying: bool = True
    // ) -> uint256:
    function exchange_underlying(
        address _pool,
        int128 _i,
        int128 _j,
        uint256 _dx,
        uint256 _min_dy,
        address _receiver
    ) external returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

library Flags {
    /* ========== FLAGS ========== */

    /// @dev Flag to unwrap ETH
    uint256 public constant UNWRAP_ETH = 0;
    /// @dev Flag to revert if external call fails
    uint256 public constant REVERT_IF_EXTERNAL_FAIL = 1;
    /// @dev Flag to call proxy with a sender contract
    uint256 public constant PROXY_WITH_SENDER = 2;

    /// @dev Get flag
    /// @param _packedFlags Flags packed to uint256
    /// @param _flag Flag to check
    function getFlag(uint256 _packedFlags, uint256 _flag)
        internal
        pure
        returns (bool)
    {
        uint256 flag = (_packedFlags >> _flag) & uint256(1);
        return flag == 1;
    }

    /// @dev Set flag
    /// @param _packedFlags Flags packed to uint256
    /// @param _flag Flag to set
    /// @param _value Is set or not set
    function setFlag(
        uint256 _packedFlags,
        uint256 _flag,
        bool _value
    ) internal pure returns (uint256) {
        if (_value) return _packedFlags | (uint256(1) << _flag);
        else return _packedFlags & ~(uint256(1) << _flag);
    }
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

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../libraries/Flags.sol";

contract DummyCallProxy {
    using Flags for uint256;
    using SafeERC20 for IERC20;

    uint256 public submissionChainIdFrom;
    bytes public submissionNativeSender;

    error ExternalCallFailed();

    function callERC20(
        address _token,
        address _reserveAddress,
        address _receiver,
        bytes memory _data,
        uint256 _flags,
        bytes memory _nativeSender,
        uint256 _chainIdFrom
    ) external returns (bool _result) {
        IERC20 token = IERC20(_token);

        uint256 amount = token.balanceOf(address(this));
        token.approve(_receiver, amount);

        _result = externalCall(
            _receiver,
            0,
            _data,
            _nativeSender,
            _chainIdFrom,
            _flags.getFlag(Flags.PROXY_WITH_SENDER)
        );

        token.approve(_receiver, 0);

        amount = token.balanceOf(address(this));

        if (!_result && _flags.getFlag(Flags.REVERT_IF_EXTERNAL_FAIL)) {
            revert ExternalCallFailed();
        }
        if (amount > 0) {
            token.safeTransfer(_reserveAddress, amount);
        }
    }

    function externalCall(
        address destination,
        uint256 value,
        bytes memory data,
        bytes memory _nativeSender,
        uint256 _chainIdFrom,
        bool storeSender
    ) internal returns (bool result) {
        // Temporary write to a storage nativeSender and chainIdFrom variables.
        // External contract can read them during a call if needed
        if (storeSender) {
            submissionChainIdFrom = _chainIdFrom;
            submissionNativeSender = _nativeSender;
        }
        uint256 dataLength = data.length;
        assembly {
            let x := mload(0x40) // "Allocate" memory for output (0x40 is where "free memory" pointer is stored by convention)
            let d := add(data, 32) // First 32 bytes are the padded length of data, so exclude that
            result := call(
                sub(gas(), 34710), // 34710 is the value that solidity is currently emitting
                // It includes callGas (700) + callVeryLow (3, to pay for SUB) + callValueTransferGas (9000) +
                // callNewAccountGas (25000, in case the destination address does not exist and needs creating)
                destination,
                value,
                d,
                dataLength, // Size of the input (in bytes) - this is what fixes the padding problem
                x,
                0 // Output is ignored, therefore the output size is zero
            )
        }

        // clear storage variables to get gas refund
        if (storeSender) {
            submissionChainIdFrom = 0;
            submissionNativeSender = "";
        }
    }
}

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DummyToken is ERC20 {
    uint8 _decimals;

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) ERC20(name_, symbol_) {
        _decimals = decimals_;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function mint(address recipient, uint256 amount) external {
        _mint(recipient, amount);
    }
}

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./DummyCallProxy.sol";
import "../interfaces/IDeBridgeGate.sol";
import "../libraries/Flags.sol";

contract DummyBridge {
    using SafeERC20 for IERC20;

    DummyCallProxy callProxy;

    constructor(DummyCallProxy _callProxy) {
        callProxy = _callProxy;
    }

    function getChainId() public view virtual returns (uint256 cid) {
        assembly {
            cid := chainid()
        }
    }

    function send(
        address _tokenAddress,
        uint256 _amount,
        uint256 _chainIdTo,
        bytes memory _receiver,
        bytes memory _permit,
        bool _useAssetFee,
        uint32 _referralCode,
        bytes calldata _autoParams
    ) external {
        IERC20 tokenAddress = IERC20(_tokenAddress);

        IDeBridgeGate.SubmissionAutoParamsTo memory autoParams;
        if (_autoParams.length > 0) {
            autoParams = abi.decode(
                _autoParams,
                (IDeBridgeGate.SubmissionAutoParamsTo)
            );
        }

        if (_amount > 0) {
            tokenAddress.safeTransferFrom(msg.sender, address(this), _amount);
        }

        address receiver;
        assembly {
            receiver := mload(add(_receiver, 20))
        }

        address fallbackAddress;
        bytes memory fb = autoParams.fallbackAddress;
        assembly {
            fallbackAddress := mload(add(fb, 20))
        }

        if (autoParams.data.length > 0) {
            if (_amount > 0) {
                uint256 fee = (_amount * 10) / 10000;
                _amount -= fee;
                tokenAddress.safeTransfer(address(callProxy), _amount);
            }

            callProxy.callERC20(
                _tokenAddress,
                fallbackAddress,
                receiver,
                autoParams.data,
                autoParams.flags,
                abi.encodePacked(msg.sender),
                getChainId()
            );
        } else {
            if (_amount > 0) {
                uint256 fee = (_amount * 10) / 10000;
                _amount -= fee;
                tokenAddress.safeTransfer(receiver, _amount);
            }
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

import "../libraries/CalldataUtils.sol";
import "../libraries/SwapCalldataUtils.sol";

contract SwapCalldataMock {
    using CalldataUtils for bytes;
    using SwapCalldataUtils for bytes;

    function patch(bytes calldata _data, uint256 amount)
        external
        pure
        returns (bytes memory patchedData, bool success)
    {
        (patchedData, success) = _data.patch(amount);
    }
}