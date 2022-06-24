// SPDX-License-Identifier: Apache-2.0
// Copyright 2022 Aztec.
pragma solidity >=0.8.4;

import {ICurvePool} from "../../interfaces/curve/ICurvePool.sol";
import {ILido} from "../../interfaces/lido/ILido.sol";
import {IWstETH} from "../../interfaces/lido/IWstETH.sol";
import {IRollupProcessor} from "../../aztec/interfaces/IRollupProcessor.sol";

import {BridgeBase} from "../base/BridgeBase.sol";
import {ErrorLib} from "../base/ErrorLib.sol";
import {AztecTypes} from "../../aztec/libraries/AztecTypes.sol";

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @notice A DeFiBridge for trading between Eth and wstEth using curve and the stEth wrapper.
 * @dev Synchronous and stateless bridge that will hold no funds beyond dust for gas-savings.
 * @author Aztec Team
 */
contract CurveStEthBridge is BridgeBase {
    using SafeERC20 for ILido;
    using SafeERC20 for IWstETH;

    error InvalidConfiguration();
    error InvalidUnwrapReturnValue();

    ILido public constant LIDO = ILido(0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84);
    IWstETH public constant WRAPPED_STETH = IWstETH(0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0);
    ICurvePool public constant CURVE_POOL = ICurvePool(0xDC24316b9AE028F1497c275EB9192a3Ea0f67022);

    // Indexes of the assets in the curve pool
    int128 private constant CURVE_ETH_INDEX = 0;
    int128 private constant CURVE_STETH_INDEX = 1;

    /**
     * @notice Sets the address of the RollupProcessor and pre-approve tokens
     * @dev As the contract will not be holding state nor tokens, it can be approved safely.
     * @param _rollupProcessor The address of the RollupProcessor to use
     */
    constructor(address _rollupProcessor) BridgeBase(_rollupProcessor) {
        if (CURVE_POOL.coins(uint256(uint128(CURVE_STETH_INDEX))) != address(LIDO)) {
            revert InvalidConfiguration();
        }

        LIDO.safeIncreaseAllowance(address(WRAPPED_STETH), type(uint256).max);
        LIDO.safeIncreaseAllowance(address(CURVE_POOL), type(uint256).max);
        WRAPPED_STETH.safeIncreaseAllowance(ROLLUP_PROCESSOR, type(uint256).max);
    }

    // Empty receive function for the contract to be able to receive Eth
    receive() external payable {}

    /**
     * @notice Swaps between the eth<->wstEth tokens through the curve eth/stEth pool and wrapping stEth
     * @param _inputAssetA The inputAsset (eth or wstEth)
     * @param _outputAssetA The output asset (eth or wstEth) opposite `_inputAssetB`
     * @param _inputValue The amount of token deposited
     * @param _interactionNonce The nonce of the DeFi interaction, used when swapping wstEth -> eth
     * @return outputValueA The amount of `_outputAssetA` that the RollupProcessor should pull
     */
    function convert(
        AztecTypes.AztecAsset calldata _inputAssetA,
        AztecTypes.AztecAsset calldata,
        AztecTypes.AztecAsset calldata _outputAssetA,
        AztecTypes.AztecAsset calldata,
        uint256 _inputValue,
        uint256 _interactionNonce,
        uint64,
        address
    )
        external
        payable
        override(BridgeBase)
        onlyRollup
        returns (
            uint256 outputValueA,
            uint256,
            bool
        )
    {
        bool isETHInput = _inputAssetA.assetType == AztecTypes.AztecAssetType.ETH;
        bool isWstETHInput = _inputAssetA.assetType == AztecTypes.AztecAssetType.ERC20 &&
            _inputAssetA.erc20Address == address(WRAPPED_STETH);

        if (!(isETHInput || isWstETHInput)) {
            revert ErrorLib.InvalidInputA();
        }

        outputValueA = isETHInput
            ? _wrapETH(_inputValue, _outputAssetA)
            : _unwrapETH(_inputValue, _outputAssetA, _interactionNonce);
    }

    /**
     * @notice Swaps eth to stEth through curve and wrap the stEth into wstEth
     * @dev Reverts if `_outputAsset` is not wstEth
     * @param _inputValue The amount of token that is deposited
     * @param _outputAsset The asset that the DeFi interaction specify as output, must be wstEth
     * @return outputValue The amount of wstEth received from the interaction
     */
    function _wrapETH(uint256 _inputValue, AztecTypes.AztecAsset calldata _outputAsset)
        private
        returns (uint256 outputValue)
    {
        if (
            _outputAsset.assetType != AztecTypes.AztecAssetType.ERC20 ||
            _outputAsset.erc20Address != address(WRAPPED_STETH)
        ) {
            revert ErrorLib.InvalidOutputA();
        }

        // Swap eth -> stEth on curve
        uint256 dy = CURVE_POOL.exchange{value: _inputValue}(CURVE_ETH_INDEX, CURVE_STETH_INDEX, _inputValue, 0);

        // wrap stEth
        outputValue = WRAPPED_STETH.wrap(dy);
    }

    /**
     * @notice Unwraps wstEth and swap stEth to eth through curve
     * @dev Reverts if `_outputAsset` is not eth
     * @param _inputValue The amount of token that is deposited
     * @param _outputAsset The asset that the DeFi interaction specify as output, must be eth
     * @return outputValue The amount of eth received from the interaction
     */
    function _unwrapETH(
        uint256 _inputValue,
        AztecTypes.AztecAsset calldata _outputAsset,
        uint256 _interactionNonce
    ) private returns (uint256 outputValue) {
        if (_outputAsset.assetType != AztecTypes.AztecAssetType.ETH) {
            revert ErrorLib.InvalidOutputA();
        }

        // Convert wstETH to stETH so we can exchange it on curve
        uint256 stETH = WRAPPED_STETH.unwrap(_inputValue);

        // Exchange stETH to ETH via curve
        uint256 dy = CURVE_POOL.exchange(CURVE_STETH_INDEX, CURVE_ETH_INDEX, stETH, 0);

        outputValue = address(this).balance;
        if (outputValue < dy) {
            revert InvalidUnwrapReturnValue();
        }

        // Send ETH to rollup processor
        IRollupProcessor(ROLLUP_PROCESSOR).receiveEthFromBridge{value: outputValue}(_interactionNonce);
    }
}

// SPDX-License-Identifier: GPLv2
pragma solidity >=0.8.4;

interface ICurvePool {
    function coins(uint256) external view returns (address);

    function get_dy(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256);

    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external payable returns (uint256);
}

// SPDX-License-Identifier: GPLv2
pragma solidity >=0.8.4;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ILido is IERC20 {
    function getTotalShares() external view returns (uint256);

    function sharesOf(address _account) external view returns (uint256);

    function getSharesByPooledEth(uint256 _amount) external view returns (uint256);

    function getPooledEthByShares(uint256 _amount) external view returns (uint256);

    function submit(address _referral) external payable returns (uint256);
}

// SPDX-License-Identifier: GPLv2
pragma solidity >=0.8.4;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWstETH is IERC20 {
    function wrap(uint256 _stETHAmount) external returns (uint256);

    function unwrap(uint256 _wstETHAmount) external returns (uint256);

    function getStETHByWstETH(uint256 _wstETHAmount) external view returns (uint256);

    function getWstETHByStETH(uint256 _stETHAmount) external view returns (uint256);
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2022 Aztec
pragma solidity >=0.8.4;

interface IRollupProcessor {
    /*----------------------------------------
      MUTATING FUNCTIONS
      ----------------------------------------*/

    function pause() external;

    function unpause() external;

    function setRollupProvider(address providerAddress, bool valid) external;

    function setVerifier(address verifierAddress) external;

    function setAllowThirdPartyContracts(bool _flag) external;

    function setDefiBridgeProxy(address feeDistributorAddress) external;

    function setSupportedAsset(address linkedToken, uint256 gasLimit) external;

    function setSupportedBridge(address linkedBridge, uint256 gasLimit) external;

    function processRollup(bytes calldata proofData, bytes calldata signatures) external;

    function receiveEthFromBridge(uint256 interactionNonce) external payable;

    function approveProof(bytes32 _proofHash) external;

    function depositPendingFunds(
        uint256 assetId,
        uint256 amount,
        address owner,
        bytes32 proofHash
    ) external payable;

    function depositPendingFundsPermit(
        uint256 assetId,
        uint256 amount,
        address owner,
        bytes32 proofHash,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function depositPendingFundsPermitNonStandard(
        uint256 assetId,
        uint256 amount,
        address owner,
        bytes32 proofHash,
        uint256 nonce,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function offchainData(
        uint256 rollupId,
        uint256 chunk,
        uint256 totalChunks,
        bytes calldata offchainTxData
    ) external;

    function processAsyncDefiInteraction(uint256 interactionNonce) external returns (bool);

    /*----------------------------------------
      NON-MUTATING FUNCTIONS
      ----------------------------------------*/

    function rollupStateHash() external view returns (bytes32);

    function userPendingDeposits(uint256 assetId, address userAddress) external view returns (uint256);

    function defiBridgeProxy() external view returns (address);

    function prevDefiInteractionsHash() external view returns (bytes32);

    function paused() external view returns (bool);

    function verifier() external view returns (address);

    function getDataSize() external view returns (uint256);

    function getPendingDefiInteractionHashesLength() external view returns (uint256);

    function getDefiInteractionHashesLength() external view returns (uint256);

    function getAsyncDefiInteractionHashesLength() external view returns (uint256 res);

    function getSupportedBridge(uint256 bridgeAddressId) external view returns (address);

    function getSupportedBridgesLength() external view returns (uint256);

    function getSupportedAssetsLength() external view returns (uint256);

    function getSupportedAsset(uint256 assetId) external view returns (address);

    function getBridgeGasLimit(uint256 bridgeAddressId) external view returns (uint256);

    function getEscapeHatchStatus() external view returns (bool, uint256);

    function getDefiInteractionHashes() external view returns (bytes32[] memory);

    function getAsyncDefiInteractionHashes() external view returns (bytes32[] memory);

    function getSupportedAssets() external view returns (address[] memory, uint256[] memory);

    function getSupportedBridges() external view returns (address[] memory, uint256[] memory);
}

// SPDX-License-Identifier: GPL-2.0-only
// Copyright 2022 Spilsbury Holdings Ltd
pragma solidity >=0.8.4;

import {IDefiBridge} from "../../aztec/interfaces/IDefiBridge.sol";
import {AztecTypes} from "../../aztec/libraries/AztecTypes.sol";
import {ErrorLib} from "./ErrorLib.sol";

/**
 * @title BridgeBase
 * @notice A base that bridges can be built upon which imports a limited set of features
 * @dev Reverts `convert` with missing implementation, and `finalise` with async disabled
 * @author Lasse Herskind
 */
abstract contract BridgeBase is IDefiBridge {
    error MissingImplementation();

    address public immutable ROLLUP_PROCESSOR;

    constructor(address _rollupProcessor) {
        ROLLUP_PROCESSOR = _rollupProcessor;
    }

    modifier onlyRollup() {
        if (msg.sender != ROLLUP_PROCESSOR) {
            revert ErrorLib.InvalidCaller();
        }
        _;
    }

    function convert(
        AztecTypes.AztecAsset calldata,
        AztecTypes.AztecAsset calldata,
        AztecTypes.AztecAsset calldata,
        AztecTypes.AztecAsset calldata,
        uint256,
        uint256,
        uint64,
        address
    )
        external
        payable
        virtual
        override(IDefiBridge)
        returns (
            uint256,
            uint256,
            bool
        )
    {
        revert MissingImplementation();
    }

    function finalise(
        AztecTypes.AztecAsset calldata,
        AztecTypes.AztecAsset calldata,
        AztecTypes.AztecAsset calldata,
        AztecTypes.AztecAsset calldata,
        uint256,
        uint64
    )
        external
        payable
        virtual
        override(IDefiBridge)
        returns (
            uint256,
            uint256,
            bool
        )
    {
        revert ErrorLib.AsyncDisabled();
    }
}

// SPDX-License-Identifier: GPL-2.0-only
// Copyright 2022 Spilsbury Holdings Ltd
pragma solidity >=0.8.4;

library ErrorLib {
    error InvalidCaller();

    error InvalidInput();
    error InvalidInputA();
    error InvalidInputB();
    error InvalidOutputA();
    error InvalidOutputB();
    error InvalidInputAmount();
    error InvalidAuxData();

    error ApproveFailed(address token);
    error TransferFailed(address token);

    error InvalidNonce();
    error AsyncDisabled();
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2022 Aztec
pragma solidity >=0.8.4;

library AztecTypes {
    enum AztecAssetType {
        NOT_USED,
        ETH,
        ERC20,
        VIRTUAL
    }

    struct AztecAsset {
        uint256 id;
        address erc20Address;
        AztecAssetType assetType;
    }
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

// SPDX-License-Identifier: GPL-2.0-only
// Copyright 2022 Spilsbury Holdings Ltd
pragma solidity >=0.8.4;

import {AztecTypes} from "../libraries/AztecTypes.sol";

interface IDefiBridge {
    /**
     * Input cases:
     * Case1: 1 real input.
     * Case2: 1 virtual asset input.
     * Case3: 1 real 1 virtual input.
     *
     * Output cases:
     * Case1: 1 real
     * Case2: 2 real
     * Case3: 1 real 1 virtual
     * Case4: 1 virtual
     *
     * Example use cases with asset mappings
     * 1 1: Swapping.
     * 1 2: Swapping with incentives (2nd output reward token).
     * 1 3: Borrowing. Lock up collateral, get back loan asset and virtual position asset.
     * 1 4: Opening lending position OR Purchasing NFT. Input real asset, get back virtual asset representing NFT or position.
     * 2 1: Selling NFT. Input the virtual asset, get back a real asset.
     * 2 2: Closing a lending position. Get back original asset and reward asset.
     * 2 3: Claiming fees from an open position.
     * 2 4: Voting on a 1 4 case.
     * 3 1: Repaying a borrow. Return loan plus interest. Get collateral back.
     * 3 2: Repaying a borrow. Return loan plus interest. Get collateral plus reward token. (AAVE)
     * 3 3: Partial loan repayment.
     * 3 4: DAO voting stuff.
     */

    // @dev This function is called from the RollupProcessor.sol contract via the DefiBridgeProxy. It receives the aggregate sum of all users funds for the input assets.
    // @param AztecAsset inputAssetA a struct detailing the first input asset, this will always be set
    // @param AztecAsset inputAssetB an optional struct detailing the second input asset, this is used for repaying borrows and should be virtual
    // @param AztecAsset outputAssetA a struct detailing the first output asset, this will always be set
    // @param AztecAsset outputAssetB a struct detailing an optional second output asset
    // @param uint256 inputValue, the total amount input, if there are two input assets, equal amounts of both assets will have been input
    // @param uint256 interactionNonce a globally unique identifier for this DeFi interaction. This is used as the assetId if one of the output assets is virtual
    // @param uint64 auxData other data to be passed into the bridge contract (slippage / nftID etc)
    // @return uint256 outputValueA the amount of outputAssetA returned from this interaction, should be 0 if async
    // @return uint256 outputValueB the amount of outputAssetB returned from this interaction, should be 0 if async or bridge only returns 1 asset.
    // @return bool isAsync a flag to toggle if this bridge interaction will return assets at a later date after some third party contract has interacted with it via finalise()
    function convert(
        AztecTypes.AztecAsset calldata inputAssetA,
        AztecTypes.AztecAsset calldata inputAssetB,
        AztecTypes.AztecAsset calldata outputAssetA,
        AztecTypes.AztecAsset calldata outputAssetB,
        uint256 inputValue,
        uint256 interactionNonce,
        uint64 auxData,
        address rollupBeneficiary
    )
        external
        payable
        returns (
            uint256 outputValueA,
            uint256 outputValueB,
            bool isAsync
        );

    // @dev This function is called from the RollupProcessor.sol contract via the DefiBridgeProxy. It receives the aggregate sum of all users funds for the input assets.
    // @param AztecAsset inputAssetA a struct detailing the first input asset, this will always be set
    // @param AztecAsset inputAssetB an optional struct detailing the second input asset, this is used for repaying borrows and should be virtual
    // @param AztecAsset outputAssetA a struct detailing the first output asset, this will always be set
    // @param AztecAsset outputAssetB a struct detailing an optional second output asset
    // @param uint256 interactionNonce
    // @param uint64 auxData other data to be passed into the bridge contract (slippage / nftID etc)
    // @return uint256 outputValueA the return value of output asset A
    // @return uint256 outputValueB optional return value of output asset B
    // @dev this function should have a modifier on it to ensure it can only be called by the Rollup Contract
    function finalise(
        AztecTypes.AztecAsset calldata inputAssetA,
        AztecTypes.AztecAsset calldata inputAssetB,
        AztecTypes.AztecAsset calldata outputAssetA,
        AztecTypes.AztecAsset calldata outputAssetB,
        uint256 interactionNonce,
        uint64 auxData
    )
        external
        payable
        returns (
            uint256 outputValueA,
            uint256 outputValueB,
            bool interactionComplete
        );
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