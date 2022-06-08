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

// SPDX-License-Identifier: Apache-2.0
// Copyright 2022 Aztec
pragma solidity >=0.8.4;

import {IDefiBridge} from '../interfaces/IDefiBridge.sol';
import {AztecTypes} from '../AztecTypes.sol';
import {IRollupProcessor} from '../interfaces/IRollupProcessor.sol';

/**
 * @dev Warning: do not deploy in real environments, for testing only
 */
contract ReentryBridge is IDefiBridge {
    /*----------------------------------------
      ERROR TAGS
      ----------------------------------------*/
    error PAUSED();
    error NOT_PAUSED();
    error LOCKED_NO_REENTER();
    error INVALID_PROVIDER();
    error THIRD_PARTY_CONTRACTS_FLAG_NOT_SET();
    error INSUFFICIENT_DEPOSIT();
    error INVALID_ASSET_ID();
    error INVALID_ASSET_ADDRESS();
    error INVALID_LINKED_TOKEN_ADDRESS();
    error INVALID_LINKED_BRIDGE_ADDRESS();
    error INVALID_BRIDGE_ID();
    error INVALID_BRIDGE_ADDRESS();
    error BRIDGE_ID_IS_INCONSISTENT();
    error BRIDGE_WITH_IDENTICAL_INPUT_ASSETS(uint256 inputAssetId);
    error BRIDGE_WITH_IDENTICAL_OUTPUT_ASSETS(uint256 outputAssetId);
    error ZERO_TOTAL_INPUT_VALUE();
    error ARRAY_OVERFLOW();
    error MSG_VALUE_WRONG_AMOUNT();
    error INSUFFICIENT_ETH_PAYMENT();
    error WITHDRAW_TO_ZERO_ADDRESS();
    error DEPOSIT_TOKENS_WRONG_PAYMENT_TYPE();
    error INSUFFICIENT_TOKEN_APPROVAL();
    error NONZERO_OUTPUT_VALUE_ON_NOT_USED_ASSET(uint256 outputValue);
    error INCORRECT_STATE_HASH(bytes32 oldStateHash, bytes32 newStateHash);
    error INCORRECT_DATA_START_INDEX(uint256 providedIndex, uint256 expectedIndex);
    error INCORRECT_PREVIOUS_DEFI_INTERACTION_HASH(
        bytes32 providedDefiInteractionHash,
        bytes32 expectedDefiInteractionHash
    );
    error PUBLIC_INPUTS_HASH_VERIFICATION_FAILED(uint256, uint256);
    error PROOF_VERIFICATION_FAILED();

    address public immutable rollupProcessor;

    struct Action {
        uint256 id;
        uint256 nonce;
        bool noOp;
        bool canFinalise;
        bool isAsync;
        bytes nextAction;
        uint256 a;
        uint256 b;
    }

    mapping(uint256 => bool) public executed;
    uint256 idCount;
    Action[] public actions;

    bool public died;

    uint256 public lastNonce;

    receive() external payable {}

    constructor(address _rollupProcessor) {
        rollupProcessor = _rollupProcessor;
    }

    function addAction(
        uint256 _nonce,
        bool _isAsync,
        bool _canFinalise,
        bool _noOp,
        bytes memory _nextAction,
        uint256 _a,
        uint256 _b
    ) external {
        Action memory action = Action({
            id: idCount++,
            nonce: _nonce,
            isAsync: _isAsync,
            canFinalise: _canFinalise,
            noOp: _noOp,
            nextAction: _nextAction,
            a: _a,
            b: _b
        });
        actions.push(action);
    }

    function convert(
        AztecTypes.AztecAsset memory,
        AztecTypes.AztecAsset memory,
        AztecTypes.AztecAsset memory,
        AztecTypes.AztecAsset memory,
        uint256,
        uint256,
        uint64,
        address
    )
        external
        payable
        override
        returns (
            uint256,
            uint256,
            bool
        )
    {
        Action memory action = actions[actions.length - 1];
        bool isAsync = action.isAsync;

        if (isAsync) {
            return (0, 0, isAsync);
        }

        execute();
        return (action.a, action.b, isAsync);
    }

    function canFinalise(uint256) external view override returns (bool) {
        return actions[actions.length - 1].canFinalise;
    }

    function finalise(
        AztecTypes.AztecAsset memory,
        AztecTypes.AztecAsset memory,
        AztecTypes.AztecAsset memory,
        AztecTypes.AztecAsset memory,
        uint256,
        uint64
    )
        external
        payable
        override
        returns (
            uint256,
            uint256,
            bool
        )
    {
        require(msg.sender == rollupProcessor, 'invalid sender!');

        (uint256 a, uint256 b) = execute();

        return (a, b, true);
    }

    function execute() internal returns (uint256, uint256) {
        Action memory action = actions[actions.length - 1];
        executed[action.id] = true;
        actions.pop();

        lastNonce = action.nonce;
        IRollupProcessor(rollupProcessor).receiveEthFromBridge{value: 1}(action.nonce);

        if (!action.noOp) {
            (bool success, ) = rollupProcessor.call(action.nextAction);
            assembly {
                if iszero(success) {
                    returndatacopy(0, 0, returndatasize())
                    revert(0, returndatasize())
                }
            }
            if (!success) {
                died = true;
            }
        }

        return (action.a, action.b);
    }
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2022 Aztec
pragma solidity >=0.8.4;

import {AztecTypes} from '../AztecTypes.sol';

interface IDefiBridge {
    function convert(
        AztecTypes.AztecAsset memory inputAssetA,
        AztecTypes.AztecAsset memory inputAssetB,
        AztecTypes.AztecAsset memory outputAssetA,
        AztecTypes.AztecAsset memory outputAssetB,
        uint256 totalInputValue,
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

    function canFinalise(uint256 interactionNonce) external view returns (bool);

    function finalise(
        AztecTypes.AztecAsset memory inputAssetA,
        AztecTypes.AztecAsset memory inputAssetB,
        AztecTypes.AztecAsset memory outputAssetA,
        AztecTypes.AztecAsset memory outputAssetB,
        uint256 interactionNonce,
        uint64 auxData
    )
        external
        payable
        returns (
            uint256 outputValueA,
            uint256 outputValueB,
            bool interactionCompleted
        );
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

// SPDX-License-Identifier: Apache-2.0
// Copyright 2022 Aztec
pragma solidity >=0.8.4;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import {IDefiBridge} from '../interfaces/IDefiBridge.sol';
import {AztecTypes} from '../AztecTypes.sol';
import {IRollupProcessor} from '../interfaces/IRollupProcessor.sol';

/**
 * @dev Warning: do not deploy in real environments, for testing only
 */
contract ReentryAsync is IDefiBridge {
    address public immutable rollupProcessor;

    uint256 public nonce;
    uint256 public counter;
    uint256 public aOut;

    receive() external payable {}

    constructor(address _rollupProcessor) {
        rollupProcessor = _rollupProcessor;
    }

    function setValues(uint256 _nonce, uint256 _aOut) public {
        nonce = _nonce;
        aOut = _aOut;
    }

    function convert(
        AztecTypes.AztecAsset memory,
        AztecTypes.AztecAsset memory,
        AztecTypes.AztecAsset memory,
        AztecTypes.AztecAsset memory,
        uint256,
        uint256,
        uint64,
        address
    )
        external
        payable
        override
        returns (
            uint256,
            uint256,
            bool
        )
    {
        return (0, 0, true);
    }

    function canFinalise(uint256) external pure override returns (bool) {
        return true;
    }

    function finalise(
        AztecTypes.AztecAsset memory,
        AztecTypes.AztecAsset memory,
        AztecTypes.AztecAsset memory,
        AztecTypes.AztecAsset memory,
        uint256,
        uint64
    )
        external
        payable
        override
        returns (
            uint256,
            uint256,
            bool
        )
    {
        require(msg.sender == rollupProcessor, 'invalid sender!');
        counter++;

        if (counter < 2) {
            IRollupProcessor(rollupProcessor).processAsyncDefiInteraction(nonce);
        }

        IRollupProcessor(rollupProcessor).receiveEthFromBridge{value: aOut}(nonce);

        return (aOut, 0, true);
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

// SPDX-License-Identifier: Apache-2.0
// Copyright 2022 Aztec
pragma solidity >=0.8.4;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import {IDefiBridge} from '../interfaces/IDefiBridge.sol';
import {AztecTypes} from '../AztecTypes.sol';

/**
 * @dev Warning: do not deploy in real environments, for testing only
 */
contract MockDefiBridge is IDefiBridge {
    address public immutable rollupProcessor;

    bool immutable canConvert;
    bool immutable isAsync;
    uint256 immutable outputValueA;
    uint256 immutable outputValueB;
    uint256 immutable returnValueA;
    uint256 immutable returnValueB;
    uint256 immutable returnInputValue;

    mapping(uint256 => uint256) interestRates;

    mapping(uint256 => uint256) interactions;

    enum AUX_DATA_SELECTOR {
        NADA,
        OPEN_LOAN,
        CLOSE_LOAN,
        OPEN_LP,
        CLOSE_LP
    }

    receive() external payable {}

    constructor(
        address _rollupProcessor,
        bool _canConvert,
        uint256 _outputValueA,
        uint256 _outputValueB,
        uint256 _returnValueA,
        uint256 _returnValueB,
        uint256 _returnInputValue,
        bool _isAsync
    ) {
        rollupProcessor = _rollupProcessor;
        canConvert = _canConvert;
        outputValueA = _outputValueA;
        outputValueB = _outputValueB;
        returnValueA = _returnValueA;
        returnValueB = _returnValueB;
        returnInputValue = _returnInputValue;
        isAsync = _isAsync;
    }

    // Input cases:
    // Case1: 1 real input.
    // Case2: 1 virtual asset input.
    // Case3: 1 real 1 virtual input.

    // Output cases:
    // 1 real
    // 2 real
    // 1 real 1 virtual
    // 1 virtual

    // E2E example use cases.
    // 1 1: Swapping.
    // 1 2: Swapping with incentives (2nd output reward token).
    // 1 3: Borrowing. Lock up collateral, get back loan asset and virtual position asset.
    // 1 4: Opening lending position OR Purchasing NFT. Input real asset, get back virtual asset representing NFT or position.
    // 2 1: Selling NFT. Input the virtual asset, get back a real asset.
    // 2 2: Closing a lending position. Get back original asset and reward asset.
    // 2 3: Claiming fees from an open position.
    // 2 4: Voting on a 1 4 case.
    // 3 1: Repaying a borrow. Return loan plus interest. Get collateral back.
    // 3 2: Repaying a borrow. Return loan plus interest. Get collateral plus reward token. (AAVE)
    // 3 3: Partial loan repayment.
    // 3 4: DAO voting stuff.
    function convert(
        AztecTypes.AztecAsset memory inputAssetA,
        AztecTypes.AztecAsset memory inputAssetB,
        AztecTypes.AztecAsset memory outputAssetA,
        AztecTypes.AztecAsset memory outputAssetB,
        uint256 totalInputValue,
        uint256 interactionNonce,
        uint64 auxData,
        address
    )
        external
        payable
        override
        returns (
            uint256,
            uint256,
            bool
        )
    {
        require(canConvert, 'MockDefiBridge: canConvert = false');

        uint256 modifiedReturnValueA = returnValueA;
        if (auxData == uint32(AUX_DATA_SELECTOR.CLOSE_LOAN) && inputAssetB.id > 0) {
            require(
                inputAssetB.assetType == AztecTypes.AztecAssetType.VIRTUAL,
                'MockDefiBridge: INPUT_ASSET_A_NOT_VIRTUAL'
            );
            // get interest rate from the mapping interestRates
            modifiedReturnValueA -= (returnValueA * interestRates[inputAssetB.id]) / 100;
        }

        if (!isAsync) {
            approveTransfer(inputAssetA, returnInputValue, interactionNonce);
            approveTransfer(outputAssetA, modifiedReturnValueA, interactionNonce);
            approveTransfer(outputAssetB, returnValueB, interactionNonce);
        }
        interactions[interactionNonce] = totalInputValue;
        if (isAsync) {
            return (0, 0, isAsync);
        }
        return (modifiedReturnValueA, returnValueB, isAsync);
    }

    function recordInterestRate(uint256 interactionNonce, uint256 rate) external {
        interestRates[interactionNonce] = rate;
    }

    function canFinalise(
        uint256 /*interactionNonce*/
    ) external pure override returns (bool) {
        return true;
    }

    function finalise(
        AztecTypes.AztecAsset memory inputAssetA,
        AztecTypes.AztecAsset memory, /*inputAssetB*/
        AztecTypes.AztecAsset memory outputAssetA,
        AztecTypes.AztecAsset memory outputAssetB,
        uint256 interactionNonce,
        uint64
    )
        external
        payable
        override
        returns (
            uint256,
            uint256,
            bool
        )
    {
        require(msg.sender == rollupProcessor, 'invalid sender!');
        approveTransfer(inputAssetA, returnInputValue, interactionNonce);
        approveTransfer(outputAssetA, returnValueA, interactionNonce);
        approveTransfer(outputAssetB, returnValueB, interactionNonce);

        return (outputValueA, outputValueB, true);
    }

    function approveTransfer(
        AztecTypes.AztecAsset memory asset,
        uint256 value,
        uint256 interactionNonce
    ) internal returns (uint256 msgCallValue) {
        if (asset.assetType == AztecTypes.AztecAssetType.ETH) {
            msgCallValue = value;
            bytes memory payload = abi.encodeWithSignature('receiveEthFromBridge(uint256)', interactionNonce);
            (bool success, ) = address(rollupProcessor).call{value: msgCallValue}(payload);
            assembly {
                if iszero(success) {
                    returndatacopy(0x00, 0x00, returndatasize())
                    revert(0x00, returndatasize())
                }
            }
        } else if (asset.assetType == AztecTypes.AztecAssetType.ERC20) {
            IERC20(asset.erc20Address).approve(rollupProcessor, value);
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2022 Aztec
pragma solidity >=0.8.4;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import {IDefiBridge} from '../interfaces/IDefiBridge.sol';
import {AztecTypes} from '../AztecTypes.sol';
import {IRollupProcessor} from '../interfaces/IRollupProcessor.sol';

/**
 * @dev Warning: do not deploy in real environments, for testing only
 */
contract FailingBridge is IDefiBridge {
    address public immutable rollupProcessor;

    bool public complete;
    uint256 public nonce;

    receive() external payable {}

    constructor(address _rollupProcessor) {
        rollupProcessor = _rollupProcessor;
    }

    function setComplete(bool flag, uint256 _nonce) public {
        complete = flag;
        nonce = _nonce;
    }

    function convert(
        AztecTypes.AztecAsset memory,
        AztecTypes.AztecAsset memory,
        AztecTypes.AztecAsset memory,
        AztecTypes.AztecAsset memory,
        uint256,
        uint256,
        uint64,
        address
    )
        external
        payable
        override
        returns (
            uint256,
            uint256,
            bool
        )
    {
        return (0, 0, true);
    }

    function canFinalise(uint256) external pure override returns (bool) {
        return true;
    }

    function finalise(
        AztecTypes.AztecAsset memory,
        AztecTypes.AztecAsset memory,
        AztecTypes.AztecAsset memory,
        AztecTypes.AztecAsset memory,
        uint256,
        uint64
    )
        external
        payable
        override
        returns (
            uint256,
            uint256,
            bool
        )
    {
        require(msg.sender == rollupProcessor, 'invalid sender!');

        if (!complete) {
            return (0, 0, false);
        }

        IRollupProcessor(rollupProcessor).receiveEthFromBridge{value: 1}(nonce);

        return (1, 0, true);
    }
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2022 Aztec
pragma solidity >=0.8.4;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import {IDefiBridge} from '../interfaces/IDefiBridge.sol';
import {AztecTypes} from '../AztecTypes.sol';
import {IRollupProcessor} from '../interfaces/IRollupProcessor.sol';

/**
 * @dev Warning: do not deploy in real environments, for testing only
 */
contract FailingAsyncBridge is IDefiBridge {
    address public immutable rollupProcessor;

    uint256 public a;
    uint256 public b;

    receive() external payable {}

    constructor(address _rollupProcessor) {
        rollupProcessor = _rollupProcessor;
    }

    function setReturnValues(uint256 _a, uint256 _b) public {
        a = _a;
        b = _b;
    }

    function convert(
        AztecTypes.AztecAsset memory,
        AztecTypes.AztecAsset memory,
        AztecTypes.AztecAsset memory,
        AztecTypes.AztecAsset memory,
        uint256,
        uint256,
        uint64,
        address
    )
        external
        payable
        override
        returns (
            uint256,
            uint256,
            bool
        )
    {
        return (a, b, true);
    }

    function canFinalise(uint256) external pure override returns (bool) {
        return true;
    }

    function finalise(
        AztecTypes.AztecAsset memory,
        AztecTypes.AztecAsset memory,
        AztecTypes.AztecAsset memory,
        AztecTypes.AztecAsset memory,
        uint256,
        uint64
    )
        external
        payable
        override
        returns (
            uint256,
            uint256,
            bool
        )
    {
        return (1, 0, true);
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

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
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

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
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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

// SPDX-License-Identifier: Apache-2.0
// Copyright 2022 Aztec.
pragma solidity >=0.8.4;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {AccessControl} from '@openzeppelin/contracts/access/AccessControl.sol';
import {Initializable} from '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';

import {IVerifier} from './interfaces/IVerifier.sol';
import {IRollupProcessor} from './interfaces/IRollupProcessor.sol';
import {IERC20Permit} from './interfaces/IERC20Permit.sol';
import {IDefiBridge} from './interfaces/IDefiBridge.sol';

import {Decoder} from './Decoder.sol';
import {AztecTypes} from './AztecTypes.sol';

import {TokenTransfers} from './libraries/TokenTransfers.sol';
import './libraries/RollupProcessorLibrary.sol';

/**
 * @title Rollup Processor
 * @dev Smart contract responsible for processing Aztec zkRollups, including relaying them to a verifier
 * contract for validation and performing all relevant ERC20 token transfers
 */
contract RollupProcessor is IRollupProcessor, Decoder, Initializable, AccessControl {
    /*----------------------------------------
      ERROR TAGS
      ----------------------------------------*/
    error PAUSED();
    error NOT_PAUSED();
    error LOCKED_NO_REENTER();
    error INVALID_PROVIDER();
    error THIRD_PARTY_CONTRACTS_FLAG_NOT_SET();
    error INSUFFICIENT_DEPOSIT();
    error INVALID_ASSET_ID();
    error INVALID_ASSET_ADDRESS();
    error INVALID_LINKED_TOKEN_ADDRESS();
    error INVALID_LINKED_BRIDGE_ADDRESS();
    error INVALID_BRIDGE_ID();
    error INVALID_BRIDGE_ADDRESS();
    error BRIDGE_ID_IS_INCONSISTENT();
    error BRIDGE_WITH_IDENTICAL_INPUT_ASSETS(uint256 inputAssetId);
    error BRIDGE_WITH_IDENTICAL_OUTPUT_ASSETS(uint256 outputAssetId);
    error ZERO_TOTAL_INPUT_VALUE();
    error ARRAY_OVERFLOW();
    error MSG_VALUE_WRONG_AMOUNT();
    error INSUFFICIENT_ETH_PAYMENT();
    error WITHDRAW_TO_ZERO_ADDRESS();
    error DEPOSIT_TOKENS_WRONG_PAYMENT_TYPE();
    error INSUFFICIENT_TOKEN_APPROVAL();
    error NONZERO_OUTPUT_VALUE_ON_NOT_USED_ASSET(uint256 outputValue);
    error INCORRECT_STATE_HASH(bytes32 oldStateHash, bytes32 newStateHash);
    error INCORRECT_DATA_START_INDEX(uint256 providedIndex, uint256 expectedIndex);
    error INCORRECT_PREVIOUS_DEFI_INTERACTION_HASH(
        bytes32 providedDefiInteractionHash,
        bytes32 expectedDefiInteractionHash
    );
    error PUBLIC_INPUTS_HASH_VERIFICATION_FAILED(uint256, uint256);
    error PROOF_VERIFICATION_FAILED();

    /*----------------------------------------
      EVENTS
      ----------------------------------------*/
    event OffchainData(uint256 indexed rollupId, uint256 chunk, uint256 totalChunks, address sender);
    event RollupProcessed(uint256 indexed rollupId, bytes32[] nextExpectedDefiHashes, address sender);
    event DefiBridgeProcessed(
        uint256 indexed bridgeId,
        uint256 indexed nonce,
        uint256 totalInputValue,
        uint256 totalOutputValueA,
        uint256 totalOutputValueB,
        bool result,
        bytes errorReason
    );
    event AsyncDefiBridgeProcessed(uint256 indexed bridgeId, uint256 indexed nonce, uint256 totalInputValue);
    event Deposit(uint256 indexed assetId, address indexed depositorAddress, uint256 depositValue);
    event WithdrawError(bytes errorReason);
    event AssetAdded(uint256 indexed assetId, address indexed assetAddress, uint256 assetGasLimit);
    event BridgeAdded(uint256 indexed bridgeAddressId, address indexed bridgeAddress, uint256 bridgeGasLimit);
    event RollupProviderUpdated(address indexed providerAddress, bool valid);
    event VerifierUpdated(address indexed verifierAddress);
    event Paused(address account);
    event Unpaused(address account);

    /*----------------------------------------
      STRUCTS
      ----------------------------------------*/

    enum Lock {
        UNLOCKED,
        ALLOW_ASYNC_REENTER,
        LOCKED
    }

    /**
     * @dev RollupState struct contains the following data (offsets are for when used as storage slot):
     *
     * | bit offset   | num bits    | description |
     * | ---          | ---         | ---         |
     * | 0            | 160         | PLONK verifier contract address |
     * | 160          | 32          | datasize: number of filled entries in note tree |
     * | 192          | 16          | asyncDefiInteractionHashes.length : number of entries in asyncDefiInteractionHashes array |
     * | 208          | 16          | defiInteractionHashes.length : number of entries in defiInteractionHashes array |
     * | 224          | 8           | Lock enum used to guard against reentrancy attacks (minimum value to store in is uint8)
     * | 232          | 8           | pause flag, true if contract is paused, false otherwise
     */
    struct RollupState {
        IVerifier verifier;
        uint32 datasize;
        uint16 numAsyncDefiInteractionHashes;
        uint16 numDefiInteractionHashes;
        Lock lock;
        bool paused;
    }

    /**
     * @dev Contains information that describes a specific DeFi bridge
     * @notice A single smart contract can be used to represent multiple bridges
     *
     * @param bridgeAddressId the bridge contract address = supportedBridges[bridgeAddressId]
     * @param bridgeAddress   the bridge contract address
     * @param inputAssetIdA
     */
    struct BridgeData {
        uint256 bridgeAddressId;
        address bridgeAddress;
        uint256 inputAssetIdA;
        uint256 inputAssetIdB;
        uint256 outputAssetIdA;
        uint256 outputAssetIdB;
        uint256 auxData;
        bool firstInputVirtual;
        bool secondInputVirtual;
        bool firstOutputVirtual;
        bool secondOutputVirtual;
        bool secondInputInUse;
        bool secondOutputInUse;
        uint256 bridgeGasLimit;
    }

    /**
     * @dev Represents an asynchronous defi bridge interaction that has not been resolved
     * @param bridgeId the bridge id
     * @param totalInputValue number of tokens/wei sent to the bridge
     */
    struct PendingDefiBridgeInteraction {
        uint256 bridgeId;
        uint256 totalInputValue;
    }

    /**
     * @dev Container for the results of a DeFi interaction
     * @param outputValueA number of returned tokens for the interaction's first output asset
     * @param outputValueB number of returned tokens for the interaction's second output asset (if relevant)
     * @param isAsync is the interaction asynchronous? i.e. triggering an interaction does not immediately resolve
     * @param success did the call to the bridge succeed or fail?
     *
     * @notice async interactions must have outputValueA == 0 and outputValueB == 0 (tokens get returned later via calling `processAsyncDefiInteraction`)
     */
    struct BridgeResult {
        uint256 outputValueA;
        uint256 outputValueB;
        bool isAsync;
        bool success;
    }

    /**
     * @dev Container for the inputs of a Defi interaction
     * @param totalInputValue number of tokens/wei sent to the bridge
     * @param interactionNonce the unique id of the interaction
     * @param auxData additional input specific to the type of interaction
     */
    struct InteractionInputs {
        uint256 totalInputValue;
        uint256 interactionNonce;
        uint64 auxData;
    }

    /*----------------------------------------
      FUNCTION SELECTORS (PRECOMPUTED)
      ----------------------------------------*/
    // DEFI_BRIDGE_PROXY_CONVERT_SELECTOR = function signature of:
    //   function convert(
    //       address,
    //       AztecTypes.AztecAsset memory inputAssetA,
    //       AztecTypes.AztecAsset memory inputAssetB,
    //       AztecTypes.AztecAsset memory outputAssetA,
    //       AztecTypes.AztecAsset memory outputAssetB,
    //       uint256 totalInputValue,
    //       uint256 interactionNonce,
    //       uint256 auxData,
    //       uint256 ethPaymentsSlot
    //       address rollupBeneficary)
    // N.B. this is the selector of the 'convert' function of the DefiBridgeProxy contract.
    //      This has a different interface to the IDefiBridge.convert function
    bytes4 private constant DEFI_BRIDGE_PROXY_CONVERT_SELECTOR = 0x4bd947a8;

    /*----------------------------------------
      CONSTANT STATE VARIABLES
      ----------------------------------------*/
    uint256 private constant ethAssetId = 0; // if assetId == ethAssetId, treat as native ETH and not ERC20 token

    // starting root hash of the DeFi interaction result Merkle tree
    bytes32 private constant INIT_DEFI_ROOT = 0x2e4ab7889ab3139204945f9e722c7a8fdb84e66439d787bd066c3d896dba04ea;

    bytes32 private constant DEFI_BRIDGE_PROCESSED_SIGHASH =
        0x692cf5822a02f5edf084dc7249b3a06293621e069f11975ed70908ed10ed2e2c;

    bytes32 private constant ASYNC_BRIDGE_PROCESSED_SIGHASH =
        0x38ce48f4c2f3454bcf130721f25a4262b2ff2c8e36af937b30edf01ba481eb1d;

    // We need to cap the amount of gas sent to the DeFi bridge contract for two reasons.
    // 1: To provide consistency to rollup providers around costs.
    // 2: To prevent griefing attacks where a bridge consumes all our gas.
    uint256 private constant MIN_BRIDGE_GAS_LIMIT = 35000;
    uint256 private constant MIN_ERC20_GAS_LIMIT = 55000;
    uint256 private constant MAX_BRIDGE_GAS_LIMIT = 5000000;
    uint256 private constant MAX_ERC20_GAS_LIMIT = 1500000;

    // Bit offsets and bit masks used to convert a `uint256 bridgeId` into a BridgeData member
    uint256 private constant INPUT_ASSET_ID_A_SHIFT = 32;
    uint256 private constant INPUT_ASSET_ID_B_SHIFT = 62;
    uint256 private constant OUTPUT_ASSET_ID_A_SHIFT = 92;
    uint256 private constant OUTPUT_ASSET_ID_B_SHIFT = 122;
    uint256 private constant BITCONFIG_SHIFT = 152;
    uint256 private constant AUX_DATA_SHIFT = 184;
    uint256 private constant VIRTUAL_ASSET_ID_FLAG_SHIFT = 29;
    uint256 private constant VIRTUAL_ASSET_ID_FLAG = 0x20000000; // 2 ** 29
    uint256 private constant MASK_THIRTY_TWO_BITS = 0xffffffff;
    uint256 private constant MASK_THIRTY_BITS = 0x3fffffff;
    uint256 private constant MASK_SIXTY_FOUR_BITS = 0xffffffffffffffff;

    // Offsets and masks used to encode/decode the stateHash storage variable of RollupProcessor
    uint256 private constant DATASIZE_BIT_OFFSET = 160;
    uint256 private constant ASYNCDEFIINTERACTIONHASHES_BIT_OFFSET = 192;
    uint256 private constant DEFIINTERACTIONHASHES_BIT_OFFSET = 208;
    uint256 private constant ARRAY_LENGTH_MASK = 0x3ff; // 1023
    uint256 private constant DATASIZE_MASK = 0xffffffff;

    // the value of hashing a 'zeroed' defi interaction result
    bytes32 private constant DEFI_RESULT_ZERO_HASH = 0x2d25a1e3a51eb293004c4b56abe12ed0da6bca2b4a21936752a85d102593c1b4;

    // roles used in access control
    bytes32 public constant OWNER_ROLE = keccak256('OWNER_ROLE');
    bytes32 public constant EMERGENCY_ROLE = keccak256('EMERGENCY_ROLE');

    // bounds used for escapehatch
    uint256 public immutable escapeBlockLowerBound;
    uint256 public immutable escapeBlockUpperBound;

    /*----------------------------------------
      STATE VARIABLES
      ----------------------------------------*/
    RollupState internal rollupState;

    // Array of supported ERC20 token address.
    address[] internal supportedAssets;

    // Array of supported bridge contract addresses (similar to assetIds)
    address[] internal supportedBridges;

    // Mapping from index to async interaction hash (emulates an array), next index stored in the RollupState
    mapping(uint256 => bytes32) public asyncDefiInteractionHashes;

    // Mapping from index to sync interaction hash (emulates an array), next index stored in the RollupState
    mapping(uint256 => bytes32) public defiInteractionHashes;

    // Mapping from assetId to mapping of userAddress to public userBalance stored on this contract
    mapping(uint256 => mapping(address => uint256)) public userPendingDeposits;

    // Mapping from user address to mapping of proof hashes to flag for approval
    mapping(address => mapping(bytes32 => bool)) public depositProofApprovals;

    // The hash of the latest rollup state
    bytes32 public override(IRollupProcessor) rollupStateHash;

    // The address of the defi bridge proxy
    address public override(IRollupProcessor) defiBridgeProxy;

    // Flag to allow third party contracts to list assets and bridges when out of BETA
    bool public allowThirdPartyContracts;

    // Mapping from address to flag, true if address is approved, false otherwise
    mapping(address => bool) public rollupProviders;

    // map defiInteractionNonce to PendingDefiBridgeInteraction
    mapping(uint256 => PendingDefiBridgeInteraction) public pendingDefiInteractions;

    // map interaction nonces to eth send to RollupProcessor during a bridge interaction
    mapping(uint256 => uint256) public ethPayments;

    // map asset id to Gas Limit
    mapping(uint256 => uint256) public assetGasLimits;

    // map bridge id to Gas Limit
    mapping(uint256 => uint256) public bridgeGasLimits;

    // stores the hash of the hashes of the pending defi interactions, the notes of which are expected to be added in the 'next' rollup
    bytes32 public override(IRollupProcessor) prevDefiInteractionsHash;

    /*----------------------------------------
      MODIFIERS
      ----------------------------------------*/
    /**
     * @dev Modifier to protect functions from being called while the contract is still in BETA.
     */
    modifier checkThirdPartyContractStatus() {
        if (!hasRole(OWNER_ROLE, msg.sender) && !allowThirdPartyContracts) {
            revert THIRD_PARTY_CONTRACTS_FLAG_NOT_SET();
        }
        _;
    }

    /**
     * @dev Modifier reverting if contract is paused
     */
    modifier whenNotPaused() {
        if (rollupState.paused) {
            revert PAUSED();
        }
        _;
    }

    /**
     * @dev Modifier reverting if contract is NOT paused
     */
    modifier whenPaused() {
        if (!rollupState.paused) {
            revert NOT_PAUSED();
        }
        _;
    }

    /**
     * @dev Modifier reverting on any re-enter.
     */
    modifier noReenter() {
        if (rollupState.lock != Lock.UNLOCKED) {
            revert LOCKED_NO_REENTER();
        }
        rollupState.lock = Lock.LOCKED;
        _;
        rollupState.lock = Lock.UNLOCKED;
    }

    /**
     * @dev Modifier reverting on any re-enter but allowing async to be called.
     */
    modifier allowAsyncReenter() {
        if (rollupState.lock != Lock.UNLOCKED) {
            revert LOCKED_NO_REENTER();
        }
        rollupState.lock = Lock.ALLOW_ASYNC_REENTER;
        _;
        rollupState.lock = Lock.UNLOCKED;
    }

    /**
     * @dev Modifier reverting if re-entering after locking, but passes if unlocked or allowing async.
     */
    modifier noReenterButAsync() {
        Lock lock = rollupState.lock;
        if (lock == Lock.ALLOW_ASYNC_REENTER) {
            _;
        } else if (lock == Lock.UNLOCKED) {
            rollupState.lock = Lock.ALLOW_ASYNC_REENTER;
            _;
            rollupState.lock = Lock.UNLOCKED;
        } else {
            revert LOCKED_NO_REENTER();
        }
    }

    /**
     * @dev throw if a given assetId represents a virtual asset
     * @param assetId 30-bit integer that describes the asset.
     * If assetId's 29th bit is set, it represents a virtual asset with no ERC20 equivalent
     * Virtual assets are used by defi bridges to track non-token data. E.g. to represent a loan.
     * If an assetId is *not* a virtual asset, its ERC20 address can be recovered from `supportedAssets[assetId]`
     */
    modifier validateAssetIdIsNotVirtual(uint256 assetId) {
        if (assetId > 0x1fffffff) {
            revert INVALID_ASSET_ID();
        }
        _;
    }

    /*----------------------------------------
      CONSTRUCTORS & INITIALIZERS
      ----------------------------------------*/
    /**
     * @dev Constructor used to store immutable values for escape hatch window and
     * ensure that the implementation cannot be initialized
     * @param _escapeBlockLowerBound defines start of escape hatch window
     * @param _escapeBlockUpperBound defines end of the escape hatch window
     */
    constructor(uint256 _escapeBlockLowerBound, uint256 _escapeBlockUpperBound) {
        _disableInitializers();
        rollupState.paused = true;

        escapeBlockLowerBound = _escapeBlockLowerBound;
        escapeBlockUpperBound = _escapeBlockUpperBound;
    }

    /**
     * @dev Initialiser function. Emulates constructor behaviour for upgradeable contracts
     * @param _verifierAddress the address of the Plonk verification smart contract
     * @param _defiBridgeProxy address of the proxy contract that we route defi bridge calls through via `delegateCall`
     * @param _contractOwner owner address of RollupProcessor. Should be a multisig contract
     * @param _initDataRoot starting state of the Aztec data tree. Init tree state should be all-zeroes excluding migrated account notes
     * @param _initNullRoot starting state of the Aztec nullifier tree. Init tree state should be all-zeroes excluding migrated account nullifiers
     * @param _initRootRoot starting state of the Aztec data roots tree. Init tree state should be all-zeroes excluding 1 leaf containing _initDataRoot
     * @param _initDatasize starting size of the Aztec data tree.
     * @param _allowThirdPartyContracts flag that specifies whether 3rd parties are allowed to add state to the contract
     */
    function initialize(
        address _verifierAddress,
        address _defiBridgeProxy,
        address _contractOwner,
        bytes32 _initDataRoot,
        bytes32 _initNullRoot,
        bytes32 _initRootRoot,
        uint32 _initDatasize,
        bool _allowThirdPartyContracts
    ) external reinitializer(getImplementationVersion()) {
        _grantRole(DEFAULT_ADMIN_ROLE, _contractOwner);
        _grantRole(OWNER_ROLE, _contractOwner);
        _grantRole(EMERGENCY_ROLE, _contractOwner);
        // compute rollupStateHash
        assembly {
            let mPtr := mload(0x40)
            mstore(mPtr, 0) // nextRollupId
            mstore(add(mPtr, 0x20), _initDataRoot)
            mstore(add(mPtr, 0x40), _initNullRoot)
            mstore(add(mPtr, 0x60), _initRootRoot)
            mstore(add(mPtr, 0x80), INIT_DEFI_ROOT)
            sstore(rollupStateHash.slot, keccak256(mPtr, 0xa0))
        }
        rollupState.datasize = _initDatasize;
        rollupState.verifier = IVerifier(_verifierAddress);
        defiBridgeProxy = _defiBridgeProxy;
        allowThirdPartyContracts = _allowThirdPartyContracts;
        // initial value of the hash of 32 'zero' defi note hashes
        prevDefiInteractionsHash = 0x14e0f351ade4ba10438e9b15f66ab2e6389eea5ae870d6e8b2df1418b2e6fd5b;
    }

    /*----------------------------------------
      MUTATING FUNCTIONS WITH ACCESS CONTROL 
      ----------------------------------------*/
    /**
     * @dev Allow the multisig owner to pause the contract.
     */
    function pause() public override(IRollupProcessor) whenNotPaused onlyRole(EMERGENCY_ROLE) noReenter {
        rollupState.paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Allow the multisig owner to unpause the contract.
     */
    function unpause() public override(IRollupProcessor) whenPaused onlyRole(OWNER_ROLE) noReenter {
        rollupState.paused = false;
        emit Unpaused(msg.sender);
    }

    /**
     * @dev adds/removes an authorized rollup provider that can publish rollup blocks. Admin only
     * @param providerAddress address of rollup provider
     * @param valid are we adding or removing the provider?
     */
    function setRollupProvider(address providerAddress, bool valid)
        external
        override(IRollupProcessor)
        onlyRole(OWNER_ROLE)
        noReenter
    {
        rollupProviders[providerAddress] = valid;
        emit RollupProviderUpdated(providerAddress, valid);
    }

    /**
     * @dev sets the address of the PLONK verification smart contract. Admin only
     * @param _verifierAddress address of the verification smart contract
     */
    function setVerifier(address _verifierAddress) public override(IRollupProcessor) onlyRole(OWNER_ROLE) noReenter {
        rollupState.verifier = IVerifier(_verifierAddress);
        emit VerifierUpdated(_verifierAddress);
    }

    /**
     * @dev Set a flag that allows a third party dev to register assets and bridges.
     * @param _flag - bool if the flag should be set or not
     */
    function setAllowThirdPartyContracts(bool _flag)
        external
        override(IRollupProcessor)
        onlyRole(OWNER_ROLE)
        noReenter
    {
        allowThirdPartyContracts = _flag;
    }

    /**
     * @dev sets the address of the defi bridge proxy. Admin only
     * @param defiBridgeProxyAddress address of the defi bridge proxy contract
     */
    function setDefiBridgeProxy(address defiBridgeProxyAddress)
        public
        override(IRollupProcessor)
        onlyRole(OWNER_ROLE)
        noReenter
    {
        defiBridgeProxy = defiBridgeProxyAddress;
    }

    /**
     * @dev Set the mapping between an assetId and the address of the linked asset.
     * @param linkedToken - address of the asset
     * @param gasLimit - uint256 gas limit for ERC20 token transfers of this asset
     */
    function setSupportedAsset(address linkedToken, uint256 gasLimit)
        external
        override(IRollupProcessor)
        whenNotPaused
        checkThirdPartyContractStatus
        noReenter
    {
        if (linkedToken == address(0)) {
            revert INVALID_LINKED_TOKEN_ADDRESS();
        }

        supportedAssets.push(linkedToken);

        uint256 assetId = supportedAssets.length;
        assetGasLimits[assetId] = sanitiseAssetGasLimit(gasLimit);

        emit AssetAdded(assetId, linkedToken, assetGasLimits[assetId]);
    }

    /**
     * @dev Set the mapping between an bridge contract id and the address of the linked bridge contract.
     * @param linkedBridge - address of the bridge contract
     * @param gasLimit - uint256 gas limit to send to the bridge convert function
     */
    function setSupportedBridge(address linkedBridge, uint256 gasLimit)
        external
        override(IRollupProcessor)
        whenNotPaused
        checkThirdPartyContractStatus
        noReenter
    {
        if (linkedBridge == address(0)) {
            revert INVALID_LINKED_BRIDGE_ADDRESS();
        }
        supportedBridges.push(linkedBridge);

        uint256 bridgeAddressId = supportedBridges.length;
        bridgeGasLimits[bridgeAddressId] = sanitiseBridgeGasLimit(gasLimit);

        emit BridgeAdded(bridgeAddressId, linkedBridge, bridgeGasLimits[bridgeAddressId]);
    }

    /**
     * @dev Process a rollup - decode the rollup, update relevant state variables and
     * verify the proof
     * @param - cryptographic proof data associated with a rollup
     * @param signatures - bytes array of secp256k1 ECDSA signatures, authorising a transfer of tokens
     * from the publicOwner for the particular inner proof in question. There is a signature for each
     * inner proof.
     *
     * Structure of each signature in the bytes array is:
     * 0x00 - 0x20 : r
     * 0x20 - 0x40 : s
     * 0x40 - 0x60 : v (in form: 0x0000....0001b for example)
     *
     * @param - offchainTxData Note: not used in the logic
     * of the rollupProcessor contract, but called here as a convenient to place data on chain
     */
    function processRollup(
        bytes calldata, /* encodedProofData */
        bytes calldata signatures
    ) external override(IRollupProcessor) whenNotPaused allowAsyncReenter {
        // 1. Process a rollup if the escape hatch is open or,
        // 2. There msg.sender is an authorised rollup provider
        // 3. Always transfer fees to the passed in feeReceiver
        (bool isOpen, ) = getEscapeHatchStatus();
        if (!(rollupProviders[msg.sender] || isOpen)) {
            revert INVALID_PROVIDER();
        }

        (bytes memory proofData, uint256 numTxs, uint256 publicInputsHash) = decodeProof();
        address rollupBeneficiary = extractRollupBeneficiaryAddress(proofData);

        processRollupProof(proofData, signatures, numTxs, publicInputsHash, rollupBeneficiary);

        transferFee(proofData, rollupBeneficiary);
    }

    /*----------------------------------------
      PUBLIC/EXTERNAL MUTATING FUNCTIONS 
      ----------------------------------------*/

    /**
     * @dev Used by bridge contracts to send RollupProcessor ETH during a bridge interaction
     * @param interactionNonce the Defi interaction nonce that this payment is logged against
     */
    function receiveEthFromBridge(uint256 interactionNonce) external payable override(IRollupProcessor) {
        assembly {
            // ethPayments[interactionNonce] += msg.value
            mstore(0x00, interactionNonce)
            mstore(0x20, ethPayments.slot)
            let slot := keccak256(0x00, 0x40)
            // no need to check for overflows as this would require sending more than the blockchain's total supply of ETH!
            sstore(slot, add(sload(slot), callvalue()))
        }
    }

    /**
     * @dev Approve a proofHash for spending a users deposited funds, this is one way and must be called by the owner of the funds
     * @param _proofHash - keccack256 hash of the inner proof public inputs
     */
    function approveProof(bytes32 _proofHash) public override(IRollupProcessor) whenNotPaused {
        // asm implementation to reduce compiled bytecode size
        assembly {
            // depositProofApprovals[msg.sender][_proofHash] = true;
            mstore(0x00, caller())
            mstore(0x20, depositProofApprovals.slot)
            mstore(0x20, keccak256(0x00, 0x40))
            mstore(0x00, _proofHash)
            sstore(keccak256(0x00, 0x40), 1)
        }
    }

    /**
     * @dev Deposit funds as part of the first stage of the two stage deposit. Non-permit flow
     * @param assetId - unique ID of the asset
     * @param amount - number of tokens being deposited
     * @param owner - address that can spend the deposited funds
     * @param proofHash - the 32 byte transaction id that can spend the deposited funds
     */
    function depositPendingFunds(
        uint256 assetId,
        uint256 amount,
        address owner,
        bytes32 proofHash
    ) external payable override(IRollupProcessor) whenNotPaused noReenter {
        // Perform sanity checks on user input
        if (assetId == ethAssetId && msg.value != amount) {
            revert MSG_VALUE_WRONG_AMOUNT();
        }
        if (assetId != ethAssetId && msg.value != 0) {
            revert DEPOSIT_TOKENS_WRONG_PAYMENT_TYPE();
        }

        internalDeposit(assetId, owner, amount, proofHash);

        if (assetId != ethAssetId) {
            address assetAddress = getSupportedAsset(assetId);
            // check user approved contract to transfer funds, so can throw helpful error to user
            if (IERC20(assetAddress).allowance(msg.sender, address(this)) < amount) {
                revert INSUFFICIENT_TOKEN_APPROVAL();
            }
            TokenTransfers.safeTransferFrom(assetAddress, msg.sender, address(this), amount);
        }
    }

    /**
     * @dev Deposit funds as part of the first stage of the two stage deposit. Permit flow
     * @param assetId - unique ID of the asset
     * @param amount - number of tokens being deposited
     * @param depositorAddress - address from which funds are being transferred to the contract
     * @param proofHash - the 32 byte transaction id that can spend the deposited funds
     * @param deadline - when the permit signature expires
     * @param v - ECDSA sig param
     * @param r - ECDSA sig param
     * @param s - ECDSA sig param
     */
    function depositPendingFundsPermit(
        uint256 assetId,
        uint256 amount,
        address depositorAddress,
        bytes32 proofHash,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override(IRollupProcessor) whenNotPaused noReenter {
        internalDeposit(assetId, depositorAddress, amount, proofHash);

        address assetAddress = getSupportedAsset(assetId);
        IERC20Permit(assetAddress).permit(depositorAddress, address(this), amount, deadline, v, r, s);
        TokenTransfers.safeTransferFrom(assetAddress, depositorAddress, address(this), amount);
    }

    /**
     * @dev Deposit funds as part of the first stage of the two stage deposit. Permit flow
     * @param assetId - unique ID of the asset
     * @param amount - number of tokens being deposited
     * @param depositorAddress - address from which funds are being transferred to the contract
     * @param proofHash - the 32 byte transaction id that can spend the deposited funds
     * @param nonce - user's nonce on the erc20 contract, for replay protection
     * @param deadline - when the permit signature expires
     * @param v - ECDSA sig param
     * @param r - ECDSA sig param
     * @param s - ECDSA sig param
     */
    function depositPendingFundsPermitNonStandard(
        uint256 assetId,
        uint256 amount,
        address depositorAddress,
        bytes32 proofHash,
        uint256 nonce,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override(IRollupProcessor) whenNotPaused noReenter {
        internalDeposit(assetId, depositorAddress, amount, proofHash);

        address assetAddress = getSupportedAsset(assetId);
        IERC20Permit(assetAddress).permit(depositorAddress, address(this), nonce, deadline, true, v, r, s);
        TokenTransfers.safeTransferFrom(assetAddress, depositorAddress, address(this), amount);
    }

    /**
     * @dev Used to publish data that doesn't need to be on chain. Should eventually be published elsewhere.
     * This maybe called multiple times to work around maximum tx size limits.
     * The data will need to be reconstructed by the client.
     * @param rollupId - the rollup id this data is related to.
     * @param chunk - the chunk number, from 0 to totalChunks-1.
     * @param totalChunks - the total number of chunks.
     * @param - the data.
     */
    function offchainData(
        uint256 rollupId,
        uint256 chunk,
        uint256 totalChunks,
        bytes calldata /* offchainTxData */
    ) external override(IRollupProcessor) whenNotPaused {
        emit OffchainData(rollupId, chunk, totalChunks, msg.sender);
    }

    /**
     * @dev Process asyncdefi interactions.
     *      Callback function for asynchronous bridge interactions.
     * @param interactionNonce - unique id of the interaection
     */
    function processAsyncDefiInteraction(uint256 interactionNonce)
        external
        override(IRollupProcessor)
        whenNotPaused
        noReenterButAsync
        returns (bool)
    {
        uint256 bridgeId;
        uint256 totalInputValue;
        assembly {
            mstore(0x00, interactionNonce)
            mstore(0x20, pendingDefiInteractions.slot)
            let interactionPtr := keccak256(0x00, 0x40)

            bridgeId := sload(interactionPtr)
            totalInputValue := sload(add(interactionPtr, 0x01))
        }
        if (bridgeId == 0) {
            revert INVALID_BRIDGE_ID();
        }
        BridgeData memory bridgeData = getBridgeData(bridgeId);

        (
            AztecTypes.AztecAsset memory inputAssetA,
            AztecTypes.AztecAsset memory inputAssetB,
            AztecTypes.AztecAsset memory outputAssetA,
            AztecTypes.AztecAsset memory outputAssetB
        ) = getAztecAssetTypes(bridgeData, interactionNonce);

        // Extract the bridge address from the bridgeId
        IDefiBridge bridgeContract;
        assembly {
            mstore(0x00, supportedBridges.slot)
            let bridgeSlot := keccak256(0x00, 0x20)

            bridgeContract := and(bridgeId, 0xffffffff)
            bridgeContract := sload(add(bridgeSlot, sub(bridgeContract, 0x01)))
            bridgeContract := and(bridgeContract, ADDRESS_MASK)
        }
        if (address(bridgeContract) == address(0)) {
            revert INVALID_BRIDGE_ADDRESS();
        }

        // delete pendingDefiInteractions[interactionNonce]
        // N.B. only need to delete 1st slot value `bridgeId`. Deleting vars costs gas post-London
        // setting bridgeId to 0 is enough to cause future calls with this interaction nonce to fail
        pendingDefiInteractions[interactionNonce].bridgeId = 0;

        // Copy some variables to front of stack to get around stack too deep errors
        InteractionInputs memory inputs = InteractionInputs(
            totalInputValue,
            interactionNonce,
            uint64(bridgeData.auxData)
        );
        (uint256 outputValueA, uint256 outputValueB, bool interactionCompleted) = bridgeContract.finalise(
            inputAssetA,
            inputAssetB,
            outputAssetA,
            outputAssetB,
            inputs.interactionNonce,
            inputs.auxData
        );

        if (!interactionCompleted) {
            pendingDefiInteractions[inputs.interactionNonce].bridgeId = bridgeId;
            return false;
        }

        if (outputValueB > 0 && outputAssetB.assetType == AztecTypes.AztecAssetType.NOT_USED) {
            revert NONZERO_OUTPUT_VALUE_ON_NOT_USED_ASSET(outputValueB);
        }

        if (outputValueA == 0 && outputValueB == 0) {
            // issue refund.
            transferTokensAsync(address(bridgeContract), inputAssetA, inputs.totalInputValue, inputs.interactionNonce);
        } else {
            // transfer output tokens to rollup contract
            transferTokensAsync(address(bridgeContract), outputAssetA, outputValueA, inputs.interactionNonce);
            transferTokensAsync(address(bridgeContract), outputAssetB, outputValueB, inputs.interactionNonce);
        }

        // compute defiInteractionHash and push it onto the asyncDefiInteractionHashes array
        bool result;
        assembly {
            // Load values from `input` (to get around stack too deep)
            let inputValue := mload(inputs)
            let nonce := mload(add(inputs, 0x20))
            result := iszero(and(eq(outputValueA, 0), eq(outputValueB, 0)))

            // Compute defi interaction hash
            let mPtr := mload(0x40)
            mstore(mPtr, bridgeId)
            mstore(add(mPtr, 0x20), nonce)
            mstore(add(mPtr, 0x40), inputValue)
            mstore(add(mPtr, 0x60), outputValueA)
            mstore(add(mPtr, 0x80), outputValueB)
            mstore(add(mPtr, 0xa0), result)
            pop(staticcall(gas(), 0x2, mPtr, 0xc0, 0x00, 0x20))
            let defiInteractionHash := mod(mload(0x00), CIRCUIT_MODULUS)

            // Load sync and async array lengths from rollup state
            let state := sload(rollupState.slot)
            // asyncArrayLen = rollupState.numAsyncDefiInteractionHashes
            let asyncArrayLen := and(ARRAY_LENGTH_MASK, shr(ASYNCDEFIINTERACTIONHASHES_BIT_OFFSET, state))
            // defiArrayLen = rollupState.numDefiInteractionHashes
            let defiArrayLen := and(ARRAY_LENGTH_MASK, shr(DEFIINTERACTIONHASHES_BIT_OFFSET, state))

            // check that size of asyncDefiInteractionHashes isn't such that
            // adding 1 to it will make the next block's defiInteractionHashes length hit 512
            if gt(add(add(1, asyncArrayLen), defiArrayLen), 512) {
                // store keccak256("ARRAY_OVERFLOW()")
                // this code is equivalent to `revert ARRAY_OVERFLOW()`
                mstore(mPtr, 0x58a4ab0e00000000000000000000000000000000000000000000000000000000)
                revert(mPtr, 0x04)
            }

            // asyncDefiInteractionHashes[asyncArrayLen] = defiInteractionHash
            mstore(0x00, asyncArrayLen)
            mstore(0x20, asyncDefiInteractionHashes.slot)
            sstore(keccak256(0x00, 0x40), defiInteractionHash)

            // increase asyncDefiInteractionHashes.length by 1
            let oldState := and(not(shl(ASYNCDEFIINTERACTIONHASHES_BIT_OFFSET, ARRAY_LENGTH_MASK)), state)
            let newState := or(oldState, shl(ASYNCDEFIINTERACTIONHASHES_BIT_OFFSET, add(asyncArrayLen, 0x01)))

            sstore(rollupState.slot, newState)
        }
        emit DefiBridgeProcessed(
            bridgeId,
            inputs.interactionNonce,
            inputs.totalInputValue,
            outputValueA,
            outputValueB,
            result,
            ''
        );

        return true;
    }

    /*----------------------------------------
      INTERNAL/PRIVATE MUTATING FUNCTIONS 
      ----------------------------------------*/

    /**
     * @dev Increase the userPendingDeposits mapping
     * assembly impl to reduce compiled bytecode size and improve gas costs
     */
    function increasePendingDepositBalance(
        uint256 assetId,
        address depositorAddress,
        uint256 amount
    ) internal validateAssetIdIsNotVirtual(assetId) {
        assembly {
            // userPendingDeposit = userPendingDeposits[assetId][depositorAddress]
            mstore(0x00, assetId)
            mstore(0x20, userPendingDeposits.slot)
            mstore(0x20, keccak256(0x00, 0x40))
            mstore(0x00, depositorAddress)
            let userPendingDepositSlot := keccak256(0x00, 0x40)
            let userPendingDeposit := sload(userPendingDepositSlot)
            let newDeposit := add(userPendingDeposit, amount)
            if lt(newDeposit, userPendingDeposit) {
                revert(0, 0)
            }
            sstore(userPendingDepositSlot, newDeposit)
        }
    }

    /**
     * @dev Decrease the userPendingDeposits mapping
     * assembly impl to reduce compiled bytecode size. Also removes a sload op and saves a fair chunk of gas per deposit tx
     */
    function decreasePendingDepositBalance(
        uint256 assetId,
        address transferFromAddress,
        uint256 amount
    ) internal validateAssetIdIsNotVirtual(assetId) {
        bool insufficientDeposit = false;
        assembly {
            // userPendingDeposit = userPendingDeposits[assetId][transferFromAddress]
            mstore(0x00, assetId)
            mstore(0x20, userPendingDeposits.slot)
            mstore(0x20, keccak256(0x00, 0x40))
            mstore(0x00, transferFromAddress)
            let userPendingDepositSlot := keccak256(0x00, 0x40)
            let userPendingDeposit := sload(userPendingDepositSlot)

            insufficientDeposit := lt(userPendingDeposit, amount)

            let newDeposit := sub(userPendingDeposit, amount)

            sstore(userPendingDepositSlot, newDeposit)
        }

        if (insufficientDeposit) {
            revert INSUFFICIENT_DEPOSIT();
        }
    }

    /**
     * @dev Deposit funds as part of the first stage of the two stage deposit. Non-permit flow
     * @param assetId - unique ID of the asset
     * @param depositorAddress - address from which funds are being transferred to the contract
     * @param amount - amount being deposited
     * @param proofHash - the 32 byte transaction id that can spend the deposited funds
     */
    function internalDeposit(
        uint256 assetId,
        address depositorAddress,
        uint256 amount,
        bytes32 proofHash
    ) internal {
        increasePendingDepositBalance(assetId, depositorAddress, amount);

        if (proofHash != 0) {
            approveProof(proofHash);
        }

        emit Deposit(assetId, depositorAddress, amount);
    }

    /**
     * @dev processes a rollup proof. Will verify the proof's correctness and use the provided
     * proof data to update the rollup state + merkle roots, as well as validate/enact any deposits/withdrawals in the block.
     * Finally any defi interactions specified in the block will be executed
     * @param proofData the block's proof data (contains PLONK proof and public input data linked to the proof)
     * @param signatures ECDSA signatures from users authorizing deposit transactions
     * @param numTxs the number of transactions in the block
     * @param publicInputsHash the SHA256 hash of the proof's public inputs
     */
    function processRollupProof(
        bytes memory proofData,
        bytes memory signatures,
        uint256 numTxs,
        uint256 publicInputsHash,
        address rollupBeneficiary
    ) internal {
        uint256 rollupId = verifyProofAndUpdateState(proofData, publicInputsHash);
        processDepositsAndWithdrawals(proofData, numTxs, signatures);
        bytes32[] memory nextDefiHashes = processDefiBridges(proofData, rollupBeneficiary);
        emit RollupProcessed(rollupId, nextDefiHashes, msg.sender);
    }

    /**
     * @dev Verify the zk proof and update the contract state variables with those provided by the rollup.
     * @param proofData - cryptographic zk proof data. Passed to the verifier for verification.
     */
    function verifyProofAndUpdateState(bytes memory proofData, uint256 publicInputsHash)
        internal
        returns (uint256 rollupId)
    {
        // Verify the rollup proof.
        //
        // We manually call the verifier contract via assembly to save on gas costs and to reduce contract bytecode size
        assembly {
            /**
             * Validate correctness of zk proof.
             *
             * 1st Item is to format verifier calldata.
             **/

            // Our first input param `encodedProofData` contains the concatenation of
            // encoded 'broadcasted inputs' and the actual zk proof data.
            // (The `boadcasted inputs` is converted into a 32-byte SHA256 hash, which is
            // validated to equal the first public inputs of the zk proof. This is done in `Decoder.sol`).
            // We need to identify the location in calldata that points to the start of the zk proof data.

            // Step 1: compute size of zk proof data and its calldata pointer.
            /**
                Data layout for `bytes encodedProofData`...

                0x00 : 0x20 : length of array
                0x20 : 0x20 + header : root rollup header data
                0x20 + header : 0x24 + header : X, the length of encoded inner join-split public inputs
                0x24 + header : 0x24 + header + X : (inner join-split public inputs)
                0x24 + header + X : 0x28 + header + X : Y, the length of the zk proof data
                0x28 + header + X : 0x28 + haeder + X + Y : zk proof data

                We need to recover the numeric value of `0x28 + header + X` and `Y`
             **/
            // Begin by getting length of encoded inner join-split public inputs.
            // `calldataload(0x04)` points to start of bytes array. Add 0x24 to skip over length param and function signature.
            // The calldata param 4 bytes *after* the header is the length of the pub inputs array. However it is a packed 4-byte param.
            // To extract it, we subtract 24 bytes from the calldata pointer and mask off all but the 4 least significant bytes.
            let encodedInnerDataSize := and(
                calldataload(add(add(calldataload(0x04), 0x24), sub(ROLLUP_HEADER_LENGTH, 0x18))),
                0xffffffff
            )

            // add 8 bytes to skip over the two packed params that follow the rollup header data
            // broadcastedDataSize = inner join-split pubinput size + header size
            let broadcastedDataSize := add(add(ROLLUP_HEADER_LENGTH, 8), encodedInnerDataSize)

            // Compute zk proof data size by subtracting broadcastedDataSize from overall length of bytes encodedProofsData
            let zkProofDataSize := sub(calldataload(add(calldataload(0x04), 0x04)), broadcastedDataSize)

            // Compute calldata pointer to start of zk proof data by adding calldata offset to broadcastedDataSize
            // (+0x24 skips over function signature and length param of bytes encodedProofData)
            let zkProofDataPtr := add(broadcastedDataSize, add(calldataload(0x04), 0x24))

            // Step 2: Format calldata for verifier contract call.

            // Get free memory pointer - we copy calldata into memory starting here
            let dataPtr := mload(0x40)

            // We call the function `verify(bytes,uint256)`
            // The function signature is 0xac318c5d
            // Calldata map is:
            // 0x00 - 0x04 : 0xac318c5d
            // 0x04 - 0x24 : 0x40 (number of bytes between 0x04 and the start of the `proofData` array at 0x44)
            // 0x24 - 0x44 : publicInputsHash
            // 0x44 - .... : proofData
            mstore8(dataPtr, 0xac)
            mstore8(add(dataPtr, 0x01), 0x31)
            mstore8(add(dataPtr, 0x02), 0x8c)
            mstore8(add(dataPtr, 0x03), 0x5d)
            mstore(add(dataPtr, 0x04), 0x40)
            mstore(add(dataPtr, 0x24), publicInputsHash)
            mstore(add(dataPtr, 0x44), zkProofDataSize) // length of zkProofData bytes array
            calldatacopy(add(dataPtr, 0x64), zkProofDataPtr, zkProofDataSize) // copy the zk proof data into memory

            // Step 3: Call our verifier contract. If does not return any values, but will throw an error if the proof is not valid
            // i.e. verified == false if proof is not valid
            let verifierAddress := and(sload(rollupState.slot), ADDRESS_MASK)
            let proof_verified := staticcall(gas(), verifierAddress, dataPtr, add(zkProofDataSize, 0x64), 0x00, 0x00)

            // Check the proof is valid!
            if iszero(proof_verified) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }

        // Validate and update state hash
        rollupId = validateAndUpdateMerkleRoots(proofData);
    }

    /**
     * @dev Extract public inputs and validate they are inline with current contract rollupState.
     * @param proofData - Rollup proof data.
     */
    function validateAndUpdateMerkleRoots(bytes memory proofData) internal returns (uint256) {
        (
            uint256 rollupId,
            bytes32 oldStateHash,
            bytes32 newStateHash,
            uint32 numDataLeaves,
            uint32 dataStartIndex
        ) = computeRootHashes(proofData);

        if (oldStateHash != rollupStateHash) {
            revert INCORRECT_STATE_HASH(oldStateHash, newStateHash);
        }

        unchecked {
            uint32 storedDataSize = rollupState.datasize;
            // Ensure we are inserting at the next subtree boundary.
            if (storedDataSize % numDataLeaves == 0) {
                if (dataStartIndex != storedDataSize) {
                    revert INCORRECT_DATA_START_INDEX(dataStartIndex, storedDataSize);
                }
            } else {
                uint256 expected = storedDataSize + numDataLeaves - (storedDataSize % numDataLeaves);
                if (dataStartIndex != expected) {
                    revert INCORRECT_DATA_START_INDEX(dataStartIndex, expected);
                }
            }

            rollupStateHash = newStateHash;
            rollupState.datasize = dataStartIndex + numDataLeaves;
        }
        return rollupId;
    }

    /**
     * @dev Process deposits and withdrawls.
     * @param proofData - the proof data
     * @param numTxs - number of transactions rolled up in the proof
     * @param signatures - bytes array of secp256k1 ECDSA signatures, authorising a transfer of tokens
     */
    function processDepositsAndWithdrawals(
        bytes memory proofData,
        uint256 numTxs,
        bytes memory signatures
    ) internal {
        uint256 sigIndex = 0x00;
        uint256 proofDataPtr;
        uint256 end;
        assembly {
            // add 0x20 to skip over 1st member of the bytes type (the length field).
            // Also skip over the rollup header.
            proofDataPtr := add(ROLLUP_HEADER_LENGTH, add(proofData, 0x20))

            // compute the position of proofDataPtr after we iterate through every transaction
            end := add(proofDataPtr, mul(numTxs, TX_PUBLIC_INPUT_LENGTH))
        }

        // This is a bit of a hot loop, we iterate over every tx to determine whether to process deposits or withdrawals.
        while (proofDataPtr < end) {
            // extract the minimum information we need to determine whether to skip this iteration
            uint256 publicValue;
            assembly {
                publicValue := mload(add(proofDataPtr, 0xa0))
            }
            if (publicValue > 0) {
                uint256 proofId;
                uint256 assetId;
                address publicOwner;
                assembly {
                    proofId := mload(proofDataPtr)
                    assetId := mload(add(proofDataPtr, 0xe0))
                    publicOwner := mload(add(proofDataPtr, 0xc0))
                }

                if (proofId == 1) {
                    // validate user has approved deposit
                    bytes32 digest;
                    assembly {
                        // compute the tx id to check if user has approved tx
                        digest := keccak256(proofDataPtr, TX_PUBLIC_INPUT_LENGTH)
                    }
                    // check if there is an existing entry in depositProofApprovals
                    // if there is, no further work required.
                    // we don't need to clear `depositProofApprovals[publicOwner][digest]` because proofs cannot be re-used.
                    // A single proof describes the creation of 2 output notes and the addition of 2 input note nullifiers
                    // (both of these nullifiers can be categorised as "fake". They may not map to existing notes but are still inserted in the nullifier set)
                    // Replaying the proof will fail to satisfy the rollup circuit's non-membership check on the input nullifiers.
                    // We avoid resetting `depositProofApprovals` because that would cost additional gas post-London hard fork.
                    if (!depositProofApprovals[publicOwner][digest]) {
                        // extract and validate signature
                        // we can create a bytes memory container for the signature without allocating new memory,
                        // by overwriting the previous 32 bytes in the `signatures` array with the 'length' of our synthetic byte array (92)
                        // we store the memory we overwrite in `temp`, so that we can restore it
                        bytes memory signature;
                        uint256 temp;
                        assembly {
                            // set `signature` to point to 32 bytes less than the desired `r, s, v` values in `signatures`
                            signature := add(signatures, sigIndex)
                            // cache the memory we're about to overwrite
                            temp := mload(signature)
                            // write in a 92-byte 'length' parameter into the `signature` bytes array
                            mstore(signature, 0x60)
                        }

                        bytes32 hashedMessage = RollupProcessorLibrary.getSignedMessageForTxId(digest);

                        RollupProcessorLibrary.validateSheildSignatureUnpacked(hashedMessage, signature, publicOwner);
                        // restore the memory we overwrote
                        assembly {
                            mstore(signature, temp)
                            sigIndex := add(sigIndex, 0x60)
                        }
                    }
                    decreasePendingDepositBalance(assetId, publicOwner, publicValue);
                }

                if (proofId == 2) {
                    withdraw(publicValue, publicOwner, assetId);
                }
            }
            // don't check for overflow, would take > 2^200 iterations of this loop for that to happen!
            unchecked {
                proofDataPtr += TX_PUBLIC_INPUT_LENGTH;
            }
        }
    }

    /**
     * @dev Token transfer method used by processAsyncDefiInteraction
     * Calls `transferFrom` on the target erc20 token, if asset is of type ERC
     * If asset is ETH, we validate a payment has been made against the provided interaction nonce
     * @param bridgeContract address of bridge contract we're taking tokens from
     * @param asset the AztecAsset being transferred
     * @param outputValue the expected value transferred
     * @param interactionNonce the defi interaction nonce of the interaction
     */
    function transferTokensAsync(
        address bridgeContract,
        AztecTypes.AztecAsset memory asset,
        uint256 outputValue,
        uint256 interactionNonce
    ) internal {
        if (outputValue == 0) {
            return;
        }
        if (asset.assetType == AztecTypes.AztecAssetType.ETH) {
            if (outputValue > ethPayments[interactionNonce]) {
                revert INSUFFICIENT_ETH_PAYMENT();
            }
            ethPayments[interactionNonce] = 0;
        } else if (asset.assetType == AztecTypes.AztecAssetType.ERC20) {
            address tokenAddress = asset.erc20Address;
            TokenTransfers.safeTransferFrom(tokenAddress, bridgeContract, address(this), outputValue);
        }
    }

    /**
     * @dev Transfer a fee to the feeReceiver
     * @param proofData proof of knowledge of a rollup block update
     * @param feeReceiver fee beneficiary as described kby the rollup provider
     */
    function transferFee(bytes memory proofData, address feeReceiver) internal {
        for (uint256 i = 0; i < NUMBER_OF_ASSETS; ) {
            uint256 txFee = extractTotalTxFee(proofData, i);
            if (txFee > 0) {
                uint256 assetId = extractAssetId(proofData, i);
                if (assetId == ethAssetId) {
                    // We explicitly do not throw if this call fails, as this opens up the possiblity of
                    // griefing attacks, as engineering a failed fee will invalidate an entire rollup block
                    assembly {
                        pop(call(50000, feeReceiver, txFee, 0, 0, 0, 0))
                    }
                } else {
                    address assetAddress = getSupportedAsset(assetId);
                    TokenTransfers.transferToDoNotBubbleErrors(
                        assetAddress,
                        feeReceiver,
                        txFee,
                        assetGasLimits[assetId]
                    );
                }
            }
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Internal utility function to withdraw funds from the contract to a receiver address
     * @param withdrawValue - value being withdrawn from the contract
     * @param receiverAddress - address receiving public ERC20 tokens
     * @param assetId - ID of the asset for which a withdrawl is being performed
     */
    function withdraw(
        uint256 withdrawValue,
        address receiverAddress,
        uint256 assetId
    ) internal validateAssetIdIsNotVirtual(assetId) {
        if (receiverAddress == address(0)) {
            revert WITHDRAW_TO_ZERO_ADDRESS();
        }
        if (assetId == 0) {
            // We explicitly do not throw if this call fails, as this opens up the possiblity of
            // griefing attacks, as engineering a failed withdrawal will invalidate an entire rollup block
            assembly {
                pop(call(30000, receiverAddress, withdrawValue, 0, 0, 0, 0))
            }
            // payable(receiverAddress).call{gas: 30000, value: withdrawValue}('');
        } else {
            // We explicitly do not throw if this call fails, as this opens up the possiblity of
            // griefing attacks, as engineering a failed withdrawal will invalidate an entire rollup block
            // the user should ensure their withdrawal will succeed or they will loose funds
            address assetAddress = getSupportedAsset(assetId);
            TokenTransfers.transferToDoNotBubbleErrors(
                assetAddress,
                receiverAddress,
                withdrawValue,
                assetGasLimits[assetId]
            );
        }
    }

    /*----------------------------------------
      PUBLIC/EXTERNAL NON-MUTATING FUNCTIONS 
      ----------------------------------------*/

    /**
     * @dev Get the version number of the implementation
     * @return version - The version number of the implementation
     */
    function getImplementationVersion() public view virtual returns (uint8 version) {
        return 1;
    }

    /**
     * @dev Get true if the contract is paused, false otherwise
     * @return isPaused - True if paused, false otherwise
     */
    function paused() external view override(IRollupProcessor) returns (bool isPaused) {
        return rollupState.paused;
    }

    /**
     * @dev get the number of filled entries in the data tree.
     * This is equivalent to the number of notes created in the Aztec L2
     * @return dataSize
     */
    function getDataSize() public view override(IRollupProcessor) returns (uint256 dataSize) {
        assembly {
            dataSize := and(DATASIZE_MASK, shr(DATASIZE_BIT_OFFSET, sload(rollupState.slot)))
        }
    }

    /**
     * @dev Get number of pending defi interactions that have resolved but have not yet added into the Defi Tree
     * This value can never exceed 512. This is to prevent griefing attacks; `processRollup` iterates through `asyncDefiInteractionHashes` and
     * copies their values into `defiInteractionHashes`. Loop is bounded to < 512 so that tx does not exceed block gas limit
     * @return res the number of pending interactions
     */
    function getPendingDefiInteractionHashesLength() public view override(IRollupProcessor) returns (uint256 res) {
        assembly {
            let state := sload(rollupState.slot)
            let defiInteractionHashesLength := and(ARRAY_LENGTH_MASK, shr(DEFIINTERACTIONHASHES_BIT_OFFSET, state))
            let asyncDefiInteractionhashesLength := and(
                ARRAY_LENGTH_MASK,
                shr(ASYNCDEFIINTERACTIONHASHES_BIT_OFFSET, state)
            )
            res := add(defiInteractionHashesLength, asyncDefiInteractionhashesLength)
        }
    }

    /**
     * @dev get the address of the PLONK verification smart contract
     * @return verifierAddress - address of the verification smart contract
     */
    function verifier() public view override(IRollupProcessor) returns (address verifierAddress) {
        // asm implementation to reduce compiled bytecode size
        assembly {
            verifierAddress := and(sload(rollupState.slot), ADDRESS_MASK)
        }
    }

    /**
     * @dev Get the number of supported bridges
     * @return res The number of supported bridges
     */
    function getSupportedBridgesLength() external view override(IRollupProcessor) returns (uint256 res) {
        res = supportedBridges.length;
    }

    /**
     * @dev Get the bridge contract address for a given bridgeAddressId
     * @param bridgeAddressId - identifier used to denote a particular bridge
     */
    function getSupportedBridge(uint256 bridgeAddressId) public view override(IRollupProcessor) returns (address) {
        return supportedBridges[bridgeAddressId - 1];
    }

    /**
     * @dev Get the number of supported assets
     * @return res The number of supported assets
     */
    function getSupportedAssetsLength() external view override(IRollupProcessor) returns (uint256 res) {
        res = supportedAssets.length;
    }

    /**
     * @dev Get the ERC20 token address of a supported asset, for a given assetId
     * @param assetId - identifier used to denote a particular asset
     */
    function getSupportedAsset(uint256 assetId) public view override(IRollupProcessor) returns (address) {
        // If the asset ID is >= 2^29, the asset represents a 'virtual' asset that has no ERC20 analogue
        // Virtual assets are used by defi bridges to track non-token data. E.g. to represent a loan.
        // If an assetId is *not* a virtual asset, its ERC20 address can be recovered from `supportedAssets[assetId]`
        if (assetId > 0x1fffffff) {
            revert INVALID_ASSET_ID();
        }

        // If assetId == ethAssetId (i.e. 0), this represents native ETH.
        // ERC20 token asset id values start at 1
        if (assetId == ethAssetId) {
            return address(0x0);
        }
        address result = supportedAssets[assetId - 1];
        if (result == address(0)) {
            revert INVALID_ASSET_ADDRESS();
        }
        return result;
    }

    /**
     * @dev Get the gas limit for the bridge specified by bridgeAddressId
     * @param bridgeAddressId - identifier used to denote a particular bridge
     */
    function getBridgeGasLimit(uint256 bridgeAddressId) public view override(IRollupProcessor) returns (uint256) {
        return bridgeGasLimits[bridgeAddressId];
    }

    /**
     * @dev Get the status of the escape hatch, specifically retrieve whether the
     * hatch is open and also the number of blocks until the hatch will switch from
     * open to closed or vice versa
     */
    function getEscapeHatchStatus() public view override(IRollupProcessor) returns (bool, uint256) {
        uint256 blockNum = block.number;

        bool isOpen = blockNum % escapeBlockUpperBound >= escapeBlockLowerBound;
        uint256 blocksRemaining = 0;
        if (isOpen) {
            // num blocks escape hatch will remain open for
            blocksRemaining = escapeBlockUpperBound - (blockNum % escapeBlockUpperBound);
        } else {
            // num blocks until escape hatch will be opened
            blocksRemaining = escapeBlockLowerBound - (blockNum % escapeBlockUpperBound);
        }
        return (isOpen, blocksRemaining);
    }

    /**
     * @dev Get number of defi interaction hashes
     * A defi interaction hash represents a synchronous defi interaction that has resolved, but whose interaction result data
     * has not yet been added into the Aztec Defi Merkle tree. This step is needed in order to convert L2 Defi claim notes into L2 value notes
     * @return res the number of pending defi interaction hashes
     */
    function getDefiInteractionHashesLength() public view override(IRollupProcessor) returns (uint256 res) {
        assembly {
            res := and(ARRAY_LENGTH_MASK, shr(DEFIINTERACTIONHASHES_BIT_OFFSET, sload(rollupState.slot)))
        }
    }

    /**
     * @dev Get all pending defi interaction hashes
     * A defi interaction hash represents a synchronous defi interaction that has resolved, but whose interaction result data
     * has not yet been added into the Aztec Defi Merkle tree. This step is needed in order to convert L2 Defi claim notes into L2 value notes
     * @return res the set of all pending defi interaction hashes
     */
    function getDefiInteractionHashes() external view override(IRollupProcessor) returns (bytes32[] memory res) {
        uint256 len = getDefiInteractionHashesLength();
        assembly {
            // Allocate memory for return value
            res := mload(0x40)
            mstore(res, len)
            // Update 0x40 (the free memory pointer)
            mstore(0x40, add(res, add(0x20, mul(len, 0x20))))

            // Prepare slot computation
            mstore(0x20, defiInteractionHashes.slot)
            let ptr := add(res, 0x20)
            for {
                let i := 0
            } lt(i, len) {
                i := add(i, 0x01)
            } {
                // Fetch defiInteractionHashes[i] and add it to the return value
                mstore(0x00, i)
                mstore(ptr, sload(keccak256(0x00, 0x40)))
                ptr := add(ptr, 0x20)
            }
        }
        return res;
    }

    /**
     * @dev Get number of asynchronous defi interaction hashes
     * An async defi interaction hash represents an asynchronous defi interaction that has resolved, but whose interaction result data
     * has not yet been added into the Aztec Defi Merkle tree. This step is needed in order to convert L2 Defi claim notes into L2 value notes
     * @return res the number of pending async defi interaction hashes
     */
    function getAsyncDefiInteractionHashesLength() public view override(IRollupProcessor) returns (uint256 res) {
        assembly {
            res := and(ARRAY_LENGTH_MASK, shr(ASYNCDEFIINTERACTIONHASHES_BIT_OFFSET, sload(rollupState.slot)))
        }
    }

    /**
     * @dev Get all pending async defi interaction hashes
     * An async defi interaction hash represents an asynchronous defi interaction that has resolved, but whose interaction result data
     * has not yet been added into the Aztec Defi Merkle tree. This step is needed in order to convert L2 Defi claim notes into L2 value notes
     * @return res the set of all pending async defi interaction hashes
     */
    function getAsyncDefiInteractionHashes() external view override(IRollupProcessor) returns (bytes32[] memory res) {
        uint256 len = getAsyncDefiInteractionHashesLength();
        assembly {
            // Allocate memory for return value
            res := mload(0x40)
            mstore(res, len)
            // Update 0x40 (the free memory pointer)
            mstore(0x40, add(res, add(0x20, mul(len, 0x20))))

            // Prepare slot computation
            mstore(0x20, asyncDefiInteractionHashes.slot)
            let ptr := add(res, 0x20)
            for {
                let i := 0
            } lt(i, len) {
                i := add(i, 0x01)
            } {
                // Fetch asyncDefiInteractionHashes[i] and add it to the return value
                mstore(0x00, i)
                mstore(ptr, sload(keccak256(0x00, 0x40)))
                ptr := add(ptr, 0x20)
            }
        }
        return res;
    }

    /**
     * @dev Get the addresses of all supported bridge contracts
     */
    function getSupportedBridges()
        external
        view
        override(IRollupProcessor)
        returns (address[] memory, uint256[] memory)
    {
        uint256 supportedBridgesLength = supportedBridges.length;
        uint256[] memory gasLimits = new uint256[](supportedBridgesLength);
        for (uint256 i = 0; i < supportedBridgesLength; ) {
            gasLimits[i] = bridgeGasLimits[i + 1];
            unchecked {
                ++i;
            }
        }
        return (supportedBridges, gasLimits);
    }

    /**
     * @dev Get the addresses of all supported ERC20 tokens
     */
    function getSupportedAssets()
        external
        view
        override(IRollupProcessor)
        returns (address[] memory, uint256[] memory)
    {
        uint256 supportedAssetsLength = supportedAssets.length;
        uint256[] memory gasLimits = new uint256[](supportedAssetsLength);
        for (uint256 i = 0; i < supportedAssetsLength; ) {
            gasLimits[i] = assetGasLimits[i + 1];
            unchecked {
                ++i;
            }
        }
        return (supportedAssets, gasLimits);
    }

    /*----------------------------------------
      INTERNAL/PRIVATE NON-MUTATING FUNCTIONS
      ----------------------------------------*/

    /**
     * @dev helper function to sanitise a given bridge gas limit value to be within pre-defined limits
     * @param bridgeGasLimit - the gas limit that needs to be sanitised
     */
    function sanitiseBridgeGasLimit(uint256 bridgeGasLimit) internal pure returns (uint256) {
        if (bridgeGasLimit < MIN_BRIDGE_GAS_LIMIT) {
            return MIN_BRIDGE_GAS_LIMIT;
        }
        if (bridgeGasLimit > MAX_BRIDGE_GAS_LIMIT) {
            return MAX_BRIDGE_GAS_LIMIT;
        }
        return bridgeGasLimit;
    }

    /**
     * @dev helper function to sanitise a given asset gas limit value to be within pre-defined limits
     * @param assetGasLimit - the gas limit that needs to be sanitised
     */
    function sanitiseAssetGasLimit(uint256 assetGasLimit) internal pure returns (uint256) {
        if (assetGasLimit < MIN_ERC20_GAS_LIMIT) {
            return MIN_ERC20_GAS_LIMIT;
        }
        if (assetGasLimit > MAX_ERC20_GAS_LIMIT) {
            return MAX_ERC20_GAS_LIMIT;
        }
        return assetGasLimit;
    }

    /**
     * @dev Unpack the bridgeId into a BridgeData struct
     * @param bridgeId - Bit-array that encodes data that describes a DeFi bridge.
     *
     * Structure of the bit array is as follows (starting at least significant bit):
     * | bit range | parameter       | description |
     * | 0 - 32    | bridgeAddressId | The address ID. Bridge address = `supportedBridges[bridgeAddressId]` |
     * | 32 - 62   | inputAssetIdA   | First input asset ID. |
     * | 62 - 92   | inputAssetIdB   | Second input asset ID. Must be 0 if bridge does not have a 2nd input asset. |
     * | 92 - 122  | outputAssetIdA  | First output asset ID. |
     * | 122 - 152 | outputAssetIdB  | Second output asset ID. Must be 0 if bridge does not have a 2nd output asset. |
     * | 152 - 184 | bitConfig       | Bit-array that contains boolean bridge settings. |
     * | 184 - 248 | auxData         | 64 bits of custom data to be passed to the bridge contract. Structure is defined/checked by the bridge contract. |
     *
     * Structure of the `bitConfig` parameter is as follows
     * | bit | parameter               | description |
     * | 0   | secondInputInUse        | Does the bridge have a second input asset? |
     * | 1   | secondOutputInUse       | Does the bridge have a second output asset? |
     *
     * Brief note on virtual assets: Virtual assets are assets that don't have an ERC20 token analogue and exist solely as notes within the Aztec network.
     * They can be created/spent as a result of DeFi interactions. They are used to enable defi bridges to track internally-defined data without having to
     * mint a new token on-chain.
     * An example use of a virtual asset would a virtual loan asset that tracks an outstanding debt that must be repaid to recover collateral deposited into the bridge.
     *
     * @return bridgeData - struct that contains bridgeId data in a human-readable form.
     */
    function getBridgeData(uint256 bridgeId) internal view returns (BridgeData memory bridgeData) {
        assembly {
            mstore(bridgeData, and(bridgeId, MASK_THIRTY_TWO_BITS)) // bridgeAddressId
            mstore(add(bridgeData, 0x40), and(shr(INPUT_ASSET_ID_A_SHIFT, bridgeId), MASK_THIRTY_BITS)) // inputAssetIdA
            mstore(add(bridgeData, 0x60), and(shr(INPUT_ASSET_ID_B_SHIFT, bridgeId), MASK_THIRTY_BITS)) // inputAssetIdB
            mstore(add(bridgeData, 0x80), and(shr(OUTPUT_ASSET_ID_A_SHIFT, bridgeId), MASK_THIRTY_BITS)) // outputAssetIdA
            mstore(add(bridgeData, 0xa0), and(shr(OUTPUT_ASSET_ID_B_SHIFT, bridgeId), MASK_THIRTY_BITS)) // outputAssetIdB
            mstore(add(bridgeData, 0xc0), and(shr(AUX_DATA_SHIFT, bridgeId), MASK_SIXTY_FOUR_BITS)) // auxData

            mstore(
                add(bridgeData, 0xe0),
                and(shr(add(INPUT_ASSET_ID_A_SHIFT, VIRTUAL_ASSET_ID_FLAG_SHIFT), bridgeId), 1)
            ) // firstInputVirtual (30th bit of inputAssetIdA) == 1
            mstore(
                add(bridgeData, 0x100),
                and(shr(add(INPUT_ASSET_ID_B_SHIFT, VIRTUAL_ASSET_ID_FLAG_SHIFT), bridgeId), 1)
            ) // secondInputVirtual (30th bit of inputAssetIdB) == 1
            mstore(
                add(bridgeData, 0x120),
                and(shr(add(OUTPUT_ASSET_ID_A_SHIFT, VIRTUAL_ASSET_ID_FLAG_SHIFT), bridgeId), 1)
            ) // firstOutputVirtual (30th bit of outputAssetIdA) == 1
            mstore(
                add(bridgeData, 0x140),
                and(shr(add(OUTPUT_ASSET_ID_B_SHIFT, VIRTUAL_ASSET_ID_FLAG_SHIFT), bridgeId), 1)
            ) // secondOutputVirtual (30th bit of outputAssetIdB) == 1
            let bitConfig := and(shr(BITCONFIG_SHIFT, bridgeId), MASK_THIRTY_TWO_BITS)
            // bitConfig = bit mask that contains bridge ID settings
            // bit 0 = second input asset in use?
            // bit 1 = second output asset in use?
            mstore(add(bridgeData, 0x160), eq(and(bitConfig, 1), 1)) // secondInputInUse (bitConfig & 1) == 1
            mstore(add(bridgeData, 0x180), eq(and(shr(1, bitConfig), 1), 1)) // secondOutputInUse ((bitConfig >> 1) & 1) == 1
        }
        bridgeData.bridgeAddress = supportedBridges[bridgeData.bridgeAddressId - 1];
        bridgeData.bridgeGasLimit = getBridgeGasLimit(bridgeData.bridgeAddressId);

        // potential conflicting states that are explicitly ruled out by circuit constraints:
        if (!bridgeData.secondInputInUse && bridgeData.inputAssetIdB > 0) {
            revert BRIDGE_ID_IS_INCONSISTENT();
        }
        if (!bridgeData.secondOutputInUse && bridgeData.outputAssetIdB > 0) {
            revert BRIDGE_ID_IS_INCONSISTENT();
        }
        if (bridgeData.secondInputInUse && (bridgeData.inputAssetIdA == bridgeData.inputAssetIdB)) {
            revert BRIDGE_WITH_IDENTICAL_INPUT_ASSETS(bridgeData.inputAssetIdA);
        }
        // Outputs can both be virtual. In that case, their asset ids will both be 2 ** 29.
        bool secondOutputReal = bridgeData.secondOutputInUse && !bridgeData.secondOutputVirtual;
        if (secondOutputReal && bridgeData.outputAssetIdA == bridgeData.outputAssetIdB) {
            revert BRIDGE_WITH_IDENTICAL_OUTPUT_ASSETS(bridgeData.outputAssetIdA);
        }
    }

    /**
     * @dev Get the four input/output assets associated with a DeFi bridge
     * @param bridgeData - Information about the DeFi bridge
     * @param defiInteractionNonce - The defi interaction nonce
     *
     * @return inputAssetA inputAssetB outputAssetA outputAssetB : input and output assets represented as AztecAsset structs
     */
    function getAztecAssetTypes(BridgeData memory bridgeData, uint256 defiInteractionNonce)
        internal
        view
        returns (
            AztecTypes.AztecAsset memory inputAssetA,
            AztecTypes.AztecAsset memory inputAssetB,
            AztecTypes.AztecAsset memory outputAssetA,
            AztecTypes.AztecAsset memory outputAssetB
        )
    {
        if (bridgeData.firstInputVirtual) {
            // asset id will be defi interaction nonce that created note
            inputAssetA.id = bridgeData.inputAssetIdA - VIRTUAL_ASSET_ID_FLAG;
            inputAssetA.erc20Address = address(0x0);
            inputAssetA.assetType = AztecTypes.AztecAssetType.VIRTUAL;
        } else {
            inputAssetA.id = bridgeData.inputAssetIdA;
            inputAssetA.erc20Address = getSupportedAsset(bridgeData.inputAssetIdA);
            inputAssetA.assetType = inputAssetA.erc20Address == address(0x0)
                ? AztecTypes.AztecAssetType.ETH
                : AztecTypes.AztecAssetType.ERC20;
        }
        if (bridgeData.firstOutputVirtual) {
            // use nonce as asset id.
            outputAssetA.id = defiInteractionNonce;
            outputAssetA.erc20Address = address(0x0);
            outputAssetA.assetType = AztecTypes.AztecAssetType.VIRTUAL;
        } else {
            outputAssetA.id = bridgeData.outputAssetIdA;
            outputAssetA.erc20Address = getSupportedAsset(bridgeData.outputAssetIdA);
            outputAssetA.assetType = outputAssetA.erc20Address == address(0x0)
                ? AztecTypes.AztecAssetType.ETH
                : AztecTypes.AztecAssetType.ERC20;
        }

        if (bridgeData.secondInputVirtual) {
            // asset id will be defi interaction nonce that created note
            inputAssetB.id = bridgeData.inputAssetIdB - VIRTUAL_ASSET_ID_FLAG;
            inputAssetB.erc20Address = address(0x0);
            inputAssetB.assetType = AztecTypes.AztecAssetType.VIRTUAL;
        } else if (bridgeData.secondInputInUse) {
            inputAssetB.id = bridgeData.inputAssetIdB;
            inputAssetB.erc20Address = getSupportedAsset(bridgeData.inputAssetIdB);
            inputAssetB.assetType = inputAssetB.erc20Address == address(0x0)
                ? AztecTypes.AztecAssetType.ETH
                : AztecTypes.AztecAssetType.ERC20;
        } else {
            inputAssetB.id = 0;
            inputAssetB.erc20Address = address(0x0);
            inputAssetB.assetType = AztecTypes.AztecAssetType.NOT_USED;
        }

        if (bridgeData.secondOutputVirtual) {
            // use nonce as asset id.
            outputAssetB.id = defiInteractionNonce;
            outputAssetB.erc20Address = address(0x0);
            outputAssetB.assetType = AztecTypes.AztecAssetType.VIRTUAL;
        } else if (bridgeData.secondOutputInUse) {
            outputAssetB.id = bridgeData.outputAssetIdB;
            outputAssetB.erc20Address = getSupportedAsset(bridgeData.outputAssetIdB);
            outputAssetB.assetType = outputAssetB.erc20Address == address(0x0)
                ? AztecTypes.AztecAssetType.ETH
                : AztecTypes.AztecAssetType.ERC20;
        } else {
            outputAssetB.id = 0;
            outputAssetB.erc20Address = address(0x0);
            outputAssetB.assetType = AztecTypes.AztecAssetType.NOT_USED;
        }
    }

    /**
     * @dev Get the length of the defi interaction hashes array and the number of pending interactions
     *
     * @return defiInteractionHashesLength the complete length of the defi interaction array
     * @return numPendingInteractions the current number of pending defi interactions
     */
    function getDefiHashesLengths()
        internal
        view
        returns (uint256 defiInteractionHashesLength, uint256 numPendingInteractions)
    {
        assembly {
            // retrieve the total length of the defi interactions array and also the number of pending interactions to a maximum of NUMBER_OF_BRIDGE_CALLS
            let state := sload(rollupState.slot)
            {
                defiInteractionHashesLength := and(ARRAY_LENGTH_MASK, shr(DEFIINTERACTIONHASHES_BIT_OFFSET, state))
                numPendingInteractions := defiInteractionHashesLength
                if gt(numPendingInteractions, NUMBER_OF_BRIDGE_CALLS) {
                    numPendingInteractions := NUMBER_OF_BRIDGE_CALLS
                }
            }
        }
    }

    /**
     * @dev Get the set of hashes that comprise the current pending defi interactions
     *
     * @return hashes the set of valid (i.e. non-zero) hashes that comprise the pending defi interactions
     * @return nextExpectedHash the hash of all hashes (including zero hashes) that comprise the pending defi interactions
     */
    function calculateNextExpectedDefiHash() internal view returns (bytes32[] memory hashes, bytes32 nextExpectedHash) {
        /**----------------------------------------
         * Compute nextExpectedHash
         *-----------------------------------------
         *
         * The `defiInteractionHashes` mapping emulates an array that represents the
         * set of defi interactions from previous blocks that have been resolved.
         *
         * We need to take the interaction result data from each of the above defi interactions,
         * and add that data into the Aztec L2 merkle tree that contains defi interaction results
         * (the "Defi Tree". Its merkle root is one of the inputs to the storage variable `rollupStateHash`)
         *
         * It is the rollup provider's responsibility to perform these additions.
         * In the current block being processed, the rollup provider must take these pending interaction results,
         * create commitments to each result and insert each commitment into the next empty leaf of the defi tree.
         *
         * The following code validates that this has happened! This is how:
         *
         * Part 1: What are we checking?
         *
         * The rollup circuit will receive, as a private input from the rollup provider, the pending defi interaction results
         * (`bridgeId`, `totalInputValue`, `totalOutputValueA`, `totalOutputValueB`, `result`)
         * The rollup circuit will compute the SHA256 hash of each interaction result (the defiInteractionHash)
         * Finally the SHA256 hash of `NUMBER_OF_BRIDGE_CALLS` of these defiInteractionHash values is computed.
         * (if there are fewer than `NUMBER_OF_BRIDGE_CALLS` pending defi interaction results, the SHA256 hash of an empty defi interaction result is used instead. i.e. all variable values are set to 0)
         * The above SHA256 hash, the `pendingDefiInteractionHash` is one of the broadcasted values that forms the `publicInputsHash` public input to the rollup circuit.
         * When verifying a rollup proof, this smart contract will compute `publicInputsHash` from the input calldata. The PLONK Verifier smart contract will then validate
         * that our computed value for `publicInputHash` matches the value used when generating the rollup proof.
         *
         * TLDR of the above: our proof data contains a variable `pendingDefiInteractionHash`, which is the CLAIMED VALUE of SHA256 hashing the SHA256 hashes of the defi interactions that have resolved but whose data has not yet been added into the defi tree.
         *
         * Part 2: How do we check `pendingDefiInteractionHash` is correct???
         *
         * This contract will call `DefiBridgeProxy.convert` (via delegatecall) on every new defi interaction present in the block.
         * The return values from the bridge proxy contract are used to construct a defi interaction result. Its hash is then computed
         * and stored in `defiInteractionHashes`.
         *
         * N.B. It's very important that DefiBridgeProxy does not call selfdestruct, or makes a delegatecall out to a contract that can selfdestruct :o
         *
         * Similarly, when async defi interactions resolve, the interaction result is stored in `asyncDefiInteractionHashes`. At the end of the processDefiBridges function,
         * the contents of the async array is copied into `defiInteractionHashes` (i.e. async interaction results are delayed by 1 rollup block. This is to prevent griefing attacks where
         * the rollup state changes between the time taken for a rollup tx to be constructed and the rollup tx to be mined)
         *
         * We use the contents of `defiInteractionHashes` to reconstruct `pendingDefiInteractionHash`, and validate it matches the value present in calldata and
         * therefore the value used in the rollup circuit when this block's rollup proof was constructed.
         * This validates that all of the required defi interaction results were added into the defi tree by the rollup provider
         * (the circuit logic enforces this, we just need to check the rollup provider used the correct inputs)
         */
        (uint256 defiInteractionHashesLength, uint256 numPendingInteractions) = getDefiHashesLengths();
        uint256 offset = defiInteractionHashesLength - numPendingInteractions;
        assembly {
            // allocate the output array of hashes
            hashes := mload(0x40)
            let hashData := add(hashes, 0x20)
            // update the free memory pointer to point past the end of our array
            // our array will consume 32 bytes for the length field plus NUMBER_OF_BRIDGE_BYTES for all of the hashes
            mstore(0x40, add(hashes, add(NUMBER_OF_BRIDGE_BYTES, 0x20)))
            // set the length of hashes to only include the non-zero hash values
            // although this function will write all of the hashes into our allocated memory, we only want to return the non-zero hashes
            mstore(hashes, numPendingInteractions)

            // Prepare the reusable part of the defi interaction hashes slot computation
            mstore(0x20, defiInteractionHashes.slot)
            let i := 0

            // Iterate over numPendingInteractions (will be between 0 and NUMBER_OF_BRIDGE_CALLS)
            // Load defiInteractionHashes[offset + i] and store in memory
            // in order to compute SHA2 hash (nextExpectedHash)
            for {

            } lt(i, numPendingInteractions) {
                i := add(i, 0x01)
            } {
                // hashData[i] = defiInteractionHashes[offset + i]
                mstore(0x00, add(offset, i))
                mstore(add(hashData, mul(i, 0x20)), sload(keccak256(0x00, 0x40)))
            }

            // If numPendingInteractions < NUMBER_OF_BRIDGE_CALLS, continue iterating up to NUMBER_OF_BRIDGE_CALLS, this time
            // inserting the "zero hash", the result of sha256(emptyDefiInteractionResult)
            for {

            } lt(i, NUMBER_OF_BRIDGE_CALLS) {
                i := add(i, 0x01)
            } {
                // hashData[i] = DEFI_RESULT_ZERO_HASH
                mstore(add(hashData, mul(i, 0x20)), DEFI_RESULT_ZERO_HASH)
            }
            pop(staticcall(gas(), 0x2, hashData, NUMBER_OF_BRIDGE_BYTES, 0x00, 0x20))
            nextExpectedHash := mod(mload(0x00), CIRCUIT_MODULUS)
        }
    }

    /**
     * @dev Process defi interactions.
     *      1. pop NUMBER_OF_BRIDGE_CALLS (if available) interaction hashes off of `defiInteractionHashes`,
     *         validate their hash (calculated at the end of the previous rollup and stored as nextExpectedDefiInteractionsHash) equals `numPendingInteractions`
     *         (this validates that rollup block has added these interaction results into the L2 data tree)
     *      2. iterate over rollup block's new defi interactions (up to NUMBER_OF_BRIDGE_CALLS). Trigger interactions by
     *         calling DefiBridgeProxy contract. Record results in either `defiInteractionHashes` (for synchrohnous txns)
     *         or, for async txns, the `pendingDefiInteractions` mapping
     *      3. copy the contents of `asyncInteractionHashes` into `defiInteractionHashes` && clear `asyncInteractionHashes`
     *      4. calculate the next value of nextExpectedDefiInteractionsHash from the new set of defiInteractionHashes
     * @param proofData - the proof data
     * @param rollupBeneficiary - the address that should be paid any subsidy for processing a defi bridge
     * @return nextExpectedHashes - the set of non-zero hashes that comprise the current pending defi interactions
     */
    function processDefiBridges(bytes memory proofData, address rollupBeneficiary)
        internal
        returns (bytes32[] memory nextExpectedHashes)
    {
        uint256 defiInteractionHashesLength;
        // Verify that nextExpectedDefiInteractionsHash equals the value given in the rollup
        // Then remove the set of pending hashes
        {
            // Extract the claimed value of previousDefiInteractionHash present in the proof data
            bytes32 providedDefiInteractionsHash = extractPrevDefiInteractionHash(proofData);

            // Validate the stored interactionHash matches the value used when making the rollup proof!
            if (providedDefiInteractionsHash != prevDefiInteractionsHash) {
                revert INCORRECT_PREVIOUS_DEFI_INTERACTION_HASH(providedDefiInteractionsHash, prevDefiInteractionsHash);
            }
            uint256 numPendingInteractions;
            (defiInteractionHashesLength, numPendingInteractions) = getDefiHashesLengths();
            // numPendingInteraction equals the number of interactions expected to be in the given rollup
            // this is the length of the defiInteractionHashes array, capped at the NUM_BRIDGE_CALLS as per the following
            // numPendingInteractions = min(defiInteractionsHashesLength, numberOfBridgeCalls)

            // Reduce DefiInteractionHashes.length by numPendingInteractions
            defiInteractionHashesLength -= numPendingInteractions;

            assembly {
                // Update DefiInteractionHashes.length in storage
                let state := sload(rollupState.slot)
                let oldState := and(not(shl(DEFIINTERACTIONHASHES_BIT_OFFSET, ARRAY_LENGTH_MASK)), state)
                let newState := or(oldState, shl(DEFIINTERACTIONHASHES_BIT_OFFSET, defiInteractionHashesLength))
                sstore(rollupState.slot, newState)
            }
        }
        uint256 interactionNonce = getRollupId(proofData) * NUMBER_OF_BRIDGE_CALLS;

        // ### Process DefiBridge Calls
        uint256 proofDataPtr;
        assembly {
            proofDataPtr := add(proofData, BRIDGE_IDS_OFFSET)
        }
        BridgeResult memory bridgeResult;
        assembly {
            bridgeResult := mload(0x40)
            mstore(0x40, add(bridgeResult, 0x80))
        }
        for (uint256 i = 0; i < NUMBER_OF_BRIDGE_CALLS; ) {
            uint256 bridgeId;
            assembly {
                bridgeId := mload(proofDataPtr)
            }
            if (bridgeId == 0) {
                // no more bridges to call
                break;
            }
            uint256 totalInputValue;
            assembly {
                totalInputValue := mload(add(proofDataPtr, mul(0x20, NUMBER_OF_BRIDGE_CALLS)))
            }
            if (totalInputValue == 0) {
                revert ZERO_TOTAL_INPUT_VALUE();
            }

            BridgeData memory bridgeData = getBridgeData(bridgeId);

            (
                AztecTypes.AztecAsset memory inputAssetA,
                AztecTypes.AztecAsset memory inputAssetB,
                AztecTypes.AztecAsset memory outputAssetA,
                AztecTypes.AztecAsset memory outputAssetB
            ) = getAztecAssetTypes(bridgeData, interactionNonce);
            assembly {
                // call the following function of DefiBridgeProxy via delegatecall...
                //     function convert(
                //          address bridgeAddress,
                //          AztecTypes.AztecAsset calldata inputAssetA,
                //          AztecTypes.AztecAsset calldata inputAssetB,
                //          AztecTypes.AztecAsset calldata outputAssetA,
                //          AztecTypes.AztecAsset calldata outputAssetB,
                //          uint256 totalInputValue,
                //          uint256 interactionNonce,
                //          uint256 auxInputData,
                //          uint256 ethPaymentsSlot,
                //          address rollupBeneficary
                //     )

                // Construct the calldata we send to DefiBridgeProxy
                // mPtr = memory pointer. Set to free memory location (0x40)
                let mPtr := mload(0x40)
                // first 4 bytes is the function signature
                mstore(mPtr, DEFI_BRIDGE_PROXY_CONVERT_SELECTOR)
                mPtr := add(mPtr, 0x04)

                let bridgeAddress := mload(add(bridgeData, 0x20))
                mstore(mPtr, bridgeAddress)
                mstore(add(mPtr, 0x20), mload(inputAssetA))
                mstore(add(mPtr, 0x40), mload(add(inputAssetA, 0x20)))
                mstore(add(mPtr, 0x60), mload(add(inputAssetA, 0x40)))
                mstore(add(mPtr, 0x80), mload(inputAssetB))
                mstore(add(mPtr, 0xa0), mload(add(inputAssetB, 0x20)))
                mstore(add(mPtr, 0xc0), mload(add(inputAssetB, 0x40)))
                mstore(add(mPtr, 0xe0), mload(outputAssetA))
                mstore(add(mPtr, 0x100), mload(add(outputAssetA, 0x20)))
                mstore(add(mPtr, 0x120), mload(add(outputAssetA, 0x40)))
                mstore(add(mPtr, 0x140), mload(outputAssetB))
                mstore(add(mPtr, 0x160), mload(add(outputAssetB, 0x20)))
                mstore(add(mPtr, 0x180), mload(add(outputAssetB, 0x40)))
                mstore(add(mPtr, 0x1a0), totalInputValue)
                mstore(add(mPtr, 0x1c0), interactionNonce)

                let auxData := mload(add(bridgeData, 0xc0))
                mstore(add(mPtr, 0x1e0), auxData)
                mstore(add(mPtr, 0x200), ethPayments.slot)
                mstore(add(mPtr, 0x220), rollupBeneficiary)

                // Call the bridge proxy via delegatecall!
                // We want the proxy to share state with the rollup processor, as the proxy is the entity sending/recovering tokens from the bridge contracts.
                // We wrap this logic in a delegatecall so that if the call fails (i.e. the bridge interaction fails), we can unwind bridge-interaction specific state changes,
                // without reverting the entire transaction.
                let success := delegatecall(
                    mload(add(bridgeData, 0x1a0)), // bridgeData.gasSentToBridge
                    sload(defiBridgeProxy.slot),
                    sub(mPtr, 0x04),
                    0x244,
                    0,
                    0
                )
                returndatacopy(mPtr, 0, returndatasize())

                switch success
                case 1 {
                    mstore(bridgeResult, mload(mPtr)) // outputValueA
                    mstore(add(bridgeResult, 0x20), mload(add(mPtr, 0x20))) // outputValueB
                    mstore(add(bridgeResult, 0x40), mload(add(mPtr, 0x40))) // isAsync
                    mstore(add(bridgeResult, 0x60), 1) // success
                }
                default {
                    // If the call failed, mark this interaction as failed. No tokens have been exchanged, users can
                    // use the "claim" circuit to recover the initial tokens they sent to the bridge
                    mstore(bridgeResult, 0) // outputValueA
                    mstore(add(bridgeResult, 0x20), 0) // outputValueB
                    mstore(add(bridgeResult, 0x40), 0) // isAsync
                    mstore(add(bridgeResult, 0x60), 0) // success
                }
            }

            if (!bridgeData.secondOutputInUse) {
                bridgeResult.outputValueB = 0;
            }

            // emit events and update state
            assembly {
                // if interaction is Async, update pendingDefiInteractions
                // if interaction is synchronous, compute the interaction hash and add to defiInteractionHashes
                switch mload(add(bridgeResult, 0x40)) // switch isAsync
                case 1 {
                    let mPtr := mload(0x40)
                    // emit AsyncDefiBridgeProcessed(indexed bridgeId, indexed interactionNonce, totalInputValue)
                    {
                        mstore(mPtr, totalInputValue)
                        log3(mPtr, 0x20, ASYNC_BRIDGE_PROCESSED_SIGHASH, bridgeId, interactionNonce)
                    }
                    // pendingDefiInteractions[interactionNonce] = PendingDefiBridgeInteraction(bridgeId, totalInputValue)
                    mstore(0x00, interactionNonce)
                    mstore(0x20, pendingDefiInteractions.slot)
                    let pendingDefiInteractionsSlotBase := keccak256(0x00, 0x40)

                    sstore(pendingDefiInteractionsSlotBase, bridgeId)
                    sstore(add(pendingDefiInteractionsSlotBase, 0x01), totalInputValue)
                }
                default {
                    let mPtr := mload(0x40)
                    // prepare the data required to publish the DefiBridgeProcessed event, we will only publish it if isAsync == false
                    // async interactions that have failed, have their isAsync property modified to false above
                    // emit DefiBridgeProcessed(indexed bridgeId, indexed interactionNonce, totalInputValue, outputValueA, outputValueB, success)

                    {
                        mstore(mPtr, totalInputValue)
                        mstore(add(mPtr, 0x20), mload(bridgeResult)) // outputValueA
                        mstore(add(mPtr, 0x40), mload(add(bridgeResult, 0x20))) // outputValueB
                        mstore(add(mPtr, 0x60), mload(add(bridgeResult, 0x60))) // success
                        mstore(add(mPtr, 0x80), 0xa0) // position in event data block of `bytes` object

                        if mload(add(bridgeResult, 0x60)) {
                            mstore(add(mPtr, 0xa0), 0)
                            log3(mPtr, 0xc0, DEFI_BRIDGE_PROCESSED_SIGHASH, bridgeId, interactionNonce)
                        }
                        if iszero(mload(add(bridgeResult, 0x60))) {
                            mstore(add(mPtr, 0xa0), returndatasize())
                            let size := returndatasize()
                            let remainder := mul(iszero(iszero(size)), sub(32, mod(size, 32)))
                            returndatacopy(add(mPtr, 0xc0), 0, size)
                            mstore(add(mPtr, add(0xc0, size)), 0)
                            log3(
                                mPtr,
                                add(0xc0, add(size, remainder)),
                                DEFI_BRIDGE_PROCESSED_SIGHASH,
                                bridgeId,
                                interactionNonce
                            )
                        }
                    }
                    // compute defiInteractionnHash
                    mstore(mPtr, bridgeId)
                    mstore(add(mPtr, 0x20), interactionNonce)
                    mstore(add(mPtr, 0x40), totalInputValue)
                    mstore(add(mPtr, 0x60), mload(bridgeResult)) // outputValueA
                    mstore(add(mPtr, 0x80), mload(add(bridgeResult, 0x20))) // outputValueB
                    mstore(add(mPtr, 0xa0), mload(add(bridgeResult, 0x60))) // success
                    pop(staticcall(gas(), 0x2, mPtr, 0xc0, 0x00, 0x20))
                    let defiInteractionHash := mod(mload(0x00), CIRCUIT_MODULUS)

                    // defiInteractionHashes[defiInteractionHashesLength] = defiInteractionHash;
                    mstore(0x00, defiInteractionHashesLength)
                    mstore(0x20, defiInteractionHashes.slot)
                    sstore(keccak256(0x00, 0x40), defiInteractionHash)

                    // Increase the length of defiInteractionHashes by 1
                    defiInteractionHashesLength := add(defiInteractionHashesLength, 0x01)
                }

                // advance interactionNonce and proofDataPtr
                interactionNonce := add(interactionNonce, 0x01)
                proofDataPtr := add(proofDataPtr, 0x20)
            }
            unchecked {
                ++i;
            }
        }

        assembly {
            /**
             * Cleanup
             *
             * 1. Copy asyncDefiInteractionHashes into defiInteractionHashes
             * 2. Update defiInteractionHashes.length
             * 2. Clear asyncDefiInteractionHashes.length
             */
            let state := sload(rollupState.slot)

            let asyncDefiInteractionHashesLength := and(
                ARRAY_LENGTH_MASK,
                shr(ASYNCDEFIINTERACTIONHASHES_BIT_OFFSET, state)
            )

            // Validate we are not overflowing our 1024 array size
            let arrayOverflow := gt(
                add(asyncDefiInteractionHashesLength, defiInteractionHashesLength),
                ARRAY_LENGTH_MASK
            )

            // Throw an error if defiInteractionHashesLength > ARRAY_LENGTH_MASK (i.e. is >= 1024)
            // should never hit this! If block `i` generates synchronous txns,
            // block 'i + 1' must process them.
            // Only way this array size hits 1024 is if we produce a glut of async interaction results
            // between blocks. HOWEVER we ensure that async interaction callbacks fail iff they would increase
            // defiInteractionHashes length to be >= 512
            // Still, can't hurt to check...
            if arrayOverflow {
                // keccak256("ARRAY_OVERFLOW()")
                mstore(0x00, 0x58a4ab0e00000000000000000000000000000000000000000000000000000000)
                revert(0x00, 0x04)
            }

            // Now, copy async hashes into defiInteractionHashes

            // Cache the free memory pointer
            let freePtr := mload(0x40)

            // Prepare the reusable parts of slot computation
            mstore(0x20, defiInteractionHashes.slot)
            mstore(0x60, asyncDefiInteractionHashes.slot)
            for {
                let i := 0
            } lt(i, asyncDefiInteractionHashesLength) {
                i := add(i, 1)
            } {
                // defiInteractionHashesLength[defiInteractionHashesLength + i] = asyncDefiInteractionHashes[i]
                mstore(0x00, add(defiInteractionHashesLength, i))
                mstore(0x40, i)
                sstore(keccak256(0x00, 0x40), sload(keccak256(0x40, 0x40)))
            }
            // Restore the free memory pointer
            mstore(0x40, freePtr)

            // clear defiInteractionHashesLength in state
            state := and(not(shl(DEFIINTERACTIONHASHES_BIT_OFFSET, ARRAY_LENGTH_MASK)), state)

            // write new defiInteractionHashesLength in state
            state := or(
                shl(
                    DEFIINTERACTIONHASHES_BIT_OFFSET,
                    add(asyncDefiInteractionHashesLength, defiInteractionHashesLength)
                ),
                state
            )

            // clear asyncDefiInteractionHashesLength in state
            state := and(not(shl(ASYNCDEFIINTERACTIONHASHES_BIT_OFFSET, ARRAY_LENGTH_MASK)), state)

            // write new state
            sstore(rollupState.slot, state)
        }

        // now we want to extract the next set of pending defi interaction hashes and calculate their hash to store for the next rollup
        (bytes32[] memory hashes, bytes32 nextExpectedHash) = calculateNextExpectedDefiHash();
        nextExpectedHashes = hashes;
        prevDefiInteractionsHash = nextExpectedHash;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

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
        bool isTopLevelCall = _setInitializedVersion(1);
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
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
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
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2022 Aztec
pragma solidity >=0.8.4;

interface IVerifier {
    function verify(bytes memory serialized_proof, uint256 _publicInputsHash) external returns (bool);
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2022 Aztec
pragma solidity >=0.8.4;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IERC20Permit is IERC20 {
    function nonces(address user) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function permit(
        address holder,
        address spender,
        uint256 nonce,
        uint256 expiry,
        bool allowed,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2022 Aztec
pragma solidity >=0.8.4;

/**
 * ----------------------------------------
 *  PROOF DATA SPECIFICATION
 * ----------------------------------------
 * Our input "proof data" is represented as a single byte array - we use a custom encoding the encode the
 * data associated with a rollup block. The encoded structure is as follows (excluding the length param of the bytes type):
 * 
   | byte range      | num bytes        | name                             | description |
   | ---             | ---              | ---                              | ---         |
   | 0x00  - 0x20    | 32               | rollupId                         | Unique rollup block identifier. Equivalent to block number |
   | 0x20  - 0x40    | 32               | rollupSize                       | Max number of transactions in the block |
   | 0x40  - 0x60    | 32               | dataStartIndex                   | Position of the next empty slot in the Aztec data tree |
   | 0x60  - 0x80    | 32               | oldDataRoot                      | Root of the data tree prior to rollup block's state updates |
   | 0x80  - 0xa0    | 32               | newDataRoot                      | Root of the data tree after rollup block's state updates |
   | 0xa0  - 0xc0    | 32               | oldNullRoot                      | Root of the nullifier tree prior to rollup block's state updates |
   | 0xc0  - 0xe0    | 32               | newNullRoot                      | Root of the nullifier tree after rollup block's state updates |
   | 0xe0  - 0x100   | 32               | oldDataRootsRoot                 | Root of the tree of data tree roots prior to rollup block's state updates |
   | 0x100 - 0x120   | 32               | newDataRootsRoot                 | Root of the tree of data tree roots after rollup block's state updates |
   | 0x120 - 0x140   | 32               | oldDefiRoot                      | Root of the defi tree prior to rollup block's state updates |
   | 0x140 - 0x160   | 32               | newDefiRoot                      | Root of the defi tree after rollup block's state updates |
   | 0x160 - 0x560   | 1024             | bridgeIds[NUMBER_OF_BRIDGE_CALLS]   | Size-32 array of bridgeIds for bridges being called in this block. If bridgeId == 0, no bridge is called |
   | 0x560 - 0x960   | 1024             | depositSums[NUMBER_OF_BRIDGE_CALLS] | Size-32 array of deposit values being sent for bridges being called in this block |
   | 0x960 - 0xb60   | 512              | assetIds[NUMBER_OF_ASSETS]         | Size-16 array of the assetIds for assets being deposited/withdrawn/used to pay fees in this block |
   | 0xb60 - 0xd60   | 512              | txFees[NUMBER_OF_ASSETS]           | Size-16 array of transaction fees paid to the rollup beneficiary, denominated in each assetId |
   | 0xd60 - 0x1160  | 1024             | interactionNotes[NUMBER_OF_BRIDGE_CALLS] | Size-32 array of defi interaction result commitments that must be inserted into the defi tree at this rollup block |
   | 0x1160 - 0x1180 | 32               | prevDefiInteractionHash          | A SHA256 hash of the data used to create each interaction result commitment. Used to validate correctness of interactionNotes |
   | 0x1180 - 0x11a0 | 32               | rollupBeneficiary                | The address that the fees from this rollup block should be sent to. Prevents a rollup proof being taken from the transaction pool and having its fees redirected |
   | 0x11a0 - 0x11c0 | 32               | numRollupTxs                     | Number of "inner rollup" proofs used to create the block proof. "inner rollup" circuits process 3-28 user txns, the outer rollup circuit processes 1-28 inner rollup proofs. |
   | 0x11c0 - 0x11c4 | 4                | numRealTxs                       | Number of transactions in the rollup excluding right-padded padding proofs
   | 0x11c4 - 0x11c8 | 4                | encodedInnerTxData.length        | Number of bytes of encodedInnerTxData |
   | 0x11c8 - end    | encodedInnerTxData.length | encodedInnerTxData      | Encoded inner transaction data. Contains encoded form of the broadcasted data associated with each tx in the rollup block |
 **/

 /**
  * --------------------------------------------
  *  DETERMINING THE NUMBER OF REAL TRANSACTIONS
  * --------------------------------------------
  * The `rollupSize` parameter describes the MAX number of txns in a block.
  * However the block may not be full.
  * Incomplete blocks will be padded with "padding" transactions that represent empty txns.
  *
  * The amount of end padding is not explicitly defined in `proofData`. It is derived.
  * The encodedInnerTxData does not include tx data for the txns associated with this end padding.
  * (it does include any padding transactions that are not part of the end padding, which can sometimes happen)
  * When decoded, the transaction data for each transaction is a fixed size (256 bytes)
  * Number of real transactions = rollupSize - (decoded tx data size / 256)
  *
  * The decoded transaction data associated with padding transactions is 256 zero bytes.
 **/

/**
 * @title Decoder
 * @dev contains functions for decoding/extracting the encoded proof data passed in as calldata,
 * as well as computing the SHA256 hash of the decoded data (publicInputsHash).
 * The publicInputsHash is used to ensure the data passed in as calldata matches the data used within the rollup circuit
 */
contract Decoder {

    /*----------------------------------------
      CONSTANTS
      ----------------------------------------*/
    uint256 internal constant NUMBER_OF_ASSETS = 16; // max number of assets in a block
    uint256 internal constant NUMBER_OF_BRIDGE_CALLS = 32; // max number of bridge calls in a block
    uint256 internal constant NUMBER_OF_BRIDGE_BYTES = 1024; // NUMBER_OF_BRIDGE_CALLS * 32
    uint256 internal constant NUMBER_OF_PUBLIC_INPUTS_PER_TX = 8; // number of ZK-SNARK "public inputs" per join-split/account/claim transaction
    uint256 internal constant TX_PUBLIC_INPUT_LENGTH = 256; // byte-length of NUMBER_OF_PUBLIC_INPUTS_PER_TX. NUMBER_OF_PUBLIC_INPUTS_PER_TX * 32;
    uint256 internal constant ROLLUP_NUM_HEADER_INPUTS = 142; // 58; // number of ZK-SNARK "public inputs" that make up the rollup header 14 + (NUMBER_OF_BRIDGE_CALLS * 3) + (NUMBER_OF_ASSETS * 2);
    uint256 internal constant ROLLUP_HEADER_LENGTH = 4544; // 1856; // ROLLUP_NUM_HEADER_INPUTS * 32;

    // ENCODED_PROOF_DATA_LENGTH_OFFSET = byte offset into the rollup header such that `numRealTransactions` occupies
    // the least significant 4 bytes of the 32-byte word being pointed to.
    // i.e. ROLLUP_HEADER_LENGTH - 28
    uint256 internal constant NUM_REAL_TRANSACTIONS_OFFSET = 4516;

    // ENCODED_PROOF_DATA_LENGTH_OFFSET = byte offset into the rollup header such that `encodedInnerProofData.length` occupies
    // the least significant 4 bytes of the 32-byte word being pointed to.
    // i.e. ROLLUP_HEADER_LENGTH - 24
    uint256 internal constant ENCODED_PROOF_DATA_LENGTH_OFFSET = 4520;

    // offset we add to `proofData` to point to the bridgeIds
    uint256 internal constant BRIDGE_IDS_OFFSET = 0x180;

    // offset we add to `proofData` to point to prevDefiInteractionhash
    uint256 internal constant PREVIOUS_DEFI_INTERACTION_HASH_OFFSET = 4480; // ROLLUP_HEADER_LENGTH - 0x40

    // offset we add to `proofData` to point to rollupBeneficiary
    uint256 internal constant ROLLUP_BENEFICIARY_OFFSET = 4512; // ROLLUP_HEADER_LENGTH - 0x20

    // CIRCUIT_MODULUS = group order of the BN254 elliptic curve. All arithmetic gates in our ZK-SNARK circuits are evaluated modulo this prime.
    // Is used when computing the public inputs hash - our SHA256 hash outputs are reduced modulo CIRCUIT_MODULUS
    uint256 internal constant CIRCUIT_MODULUS =
        21888242871839275222246405745257275088548364400416034343698204186575808495617;

    // SHA256 hashes
    uint256 internal constant PADDING_ROLLUP_HASH_SIZE_1 =
        0x22dd983f8337d97d56071f7986209ab2ee6039a422242e89126701c6ee005af0;
    uint256 internal constant PADDING_ROLLUP_HASH_SIZE_2 =
        0x076a27c79e5ace2a3d47f9dd2e83e4ff6ea8872b3c2218f66c92b89b55f36560;
    uint256 internal constant PADDING_ROLLUP_HASH_SIZE_4 =
        0x2f0c70a5bf5460465e9902f9c96be324e8064e762a5de52589fdb97cbce3c6ee;
    uint256 internal constant PADDING_ROLLUP_HASH_SIZE_8 =
        0x240ed0de145447ff0ceff2aa477f43e0e2ed7f3543ee3d8832f158ec76b183a9;
    uint256 internal constant PADDING_ROLLUP_HASH_SIZE_16 =
        0x1c52c159b4dae66c3dcf33b44d4d61ead6bc4d260f882ac6ba34dccf78892ca4;
    uint256 internal constant PADDING_ROLLUP_HASH_SIZE_32 =
        0x0df0e06ab8a02ce2ff08babd7144ab23ca2e99ddf318080cf88602eeb8913d44;
    uint256 internal constant PADDING_ROLLUP_HASH_SIZE_64 =
        0x1f83672815ac9b3ca31732d641784035834e96b269eaf6a2e759bf4fcc8e5bfd;

    uint256 internal constant ADDRESS_MASK = 0x00ffffffffffffffffffffffffffffffffffffffff;

    /*----------------------------------------
      ERROR TAGS
      ----------------------------------------*/
    error ENCODING_BYTE_INVALID();
    error INVALID_ROLLUP_TOPOLOGY();

    /*----------------------------------------
      DECODING FUNCTIONS
      ----------------------------------------*/
    /**
     * In `bytes proofData`, transaction data is appended after the rollup header data
     * Each transaction is described by 8 'public inputs' used to create a user transaction ZK-SNARK proof
     * (i.e. there are 8 public inputs for each of the "join-split", "account" and "claim" circuits)
     * The public inputs are represented in calldata according to the following specification:
     *
     * | public input idx | calldata size (bytes) | variable | description |
     * | 0                | 1                     |proofId         | transaction type identifier       |
     * | 1                | 32                    | encrypted form of 1st output note |
     * | 2                | 32                    | encrypted form of 2nd output note |
     * | 3                | 32                    | nullifier of 1st input note       |
     * | 4                | 32                    | nullifier of 2nd input note       |
     * | 5                | 32                    | amount being deposited or withdrawn |
     * | 6                | 20                    | address of depositor or withdraw destination |
     * | 7                | 4                     | assetId used in transaction |
     *
     * The following table maps proofId values to transaction types
     *
     *
     * | proofId | tx type     | description |
     * | ---     | ---         | ---         |
     * | 0       | padding     | empty transaction. Rollup blocks have a fixed number of txns. If number of real txns is less than block size, padding txns make up the difference |
     * | 1       | deposit     | deposit Eth/tokens into Aztec in exchange for encrypted Aztec notes |
     * | 2       | withdraw    | exchange encrypted Aztec notes for Eth/tokens sent to a public address |
     * | 3       | send        | private send |
     * | 4       | account     | creates an Aztec account |
     * | 5       | defiDeposit | deposit Eth/tokens into a L1 smart contract via a Defi bridge contract |
     * | 6       | defiClaim   | convert proceeds of defiDeposit tx back into encrypted Aztec notes |
     *
     * Most of the above transaction types do not use the full set of 8 public inputs (i.e. some are zero).
     * To save on calldata costs, we encode each transaction into the smallest payload possible.
     * In `decodeProof`, the encoded transaction data decoded, with the decoded tx data written into memory
     *
     * As part of the decoding algorithms we must convert the 20-byte `publicOwner` and 4-byte `assetId` fields
     * into 32-byte EVM words
     *
     * The following functions perform transaction-specific decoding. The `proofId` field is decoded prior to calling these functions
     */

    /**
     * @dev decode a padding tx
     * @param inPtr location in calldata of the encoded transaction
     * @return location in calldata of the next encoded transaction
     *
     * Encoded padding tx consists of 1 byte, the `proofId`
     * The proofId has been written into memory before we called this function so there is nothing to copy.
     * Advance the calldatapointer by 1 byte to move to the next transaction
     */
    function paddingTx(uint256 inPtr, uint256) internal pure returns (uint256) {
        unchecked{
            return (inPtr + 0x1);
        }
    }

    /**
     * @dev decode a deposit or a withdraw tx
     * @param inPtr location in calldata of the encoded transaction
     * @param outPtr location in memory to write the decoded transaction to
     * @return location in calldata of the next encoded transaction
     *
     * the deposit tx uses all 8 public inputs. All calldata is copied into memory
     */
    function depositOrWithdrawTx(uint256 inPtr, uint256 outPtr) internal pure returns (uint256) {
        // Copy deposit calldata into memory
        assembly {
            // start copying into `outPtr + 0x20`, as `outPtr` points to `proofId`, which has already been written into memry
            calldatacopy(add(outPtr, 0x20), add(inPtr, 0x20), 0xa0) // noteCommitment1 ... publicValue
            calldatacopy(add(outPtr, 0xcc), add(inPtr, 0xc0), 0x14) // convert 20-byte publicOwner calldata variable into 32-byte EVM word
            calldatacopy(add(outPtr, 0xfc), add(inPtr, 0xd4), 0x4) // convert 4-byte assetId variable into 32-byte EVM word
        }
        // advance calldata ptr by 185 bytes
        unchecked {
            return (inPtr + 0xb9);
        }
    }

    /**
     * @dev decode a send tx
     * @param inPtr location in calldata of the encoded transaction
     * @param outPtr location in memory to write the decoded transaction to
     * @return location in calldata of the next encoded transaction
     *
     * The send tx has 0-values for `publicValue`, `publicOwner` and `assetId`
     * No need to copy anything into memory for these fields as memory defaults to 0
     */
    function sendTx(uint256 inPtr, uint256 outPtr) internal pure returns (uint256) {
        assembly {
            calldatacopy(add(outPtr, 0x20), add(inPtr, 0x20), 0x80) // noteCommitment1 ... nullifier2
        }
        unchecked {
            return (inPtr + 0x81);
        }
    }

    /**
     * @dev decode an account tx
     * @param inPtr location in calldata of the encoded transaction
     * @param outPtr location in memory to write the decoded transaction to
     * @return location in calldata of the next encoded transaction
     *
     * The send tx has 0-values for `nullifier2`, `publicValue`, `publicOwner` and `assetId`
     * No need to copy anything into memory for these fields as memory defaults to 0
     */
    function accountTx(uint256 inPtr, uint256 outPtr) internal pure returns (uint256) {
        assembly {
            calldatacopy(add(outPtr, 0x20), add(inPtr, 0x20), 0x80) // noteCommitment1 ... nullifier2
        }
        unchecked {
            return (inPtr + 0x81);
        }
    }

    /**
     * @dev decode a defi deposit or claim tx
     * @param inPtr location in calldata of the encoded transaction
     * @param outPtr location in memory to write the decoded transaction to
     * @return location in calldata of the next encoded transaction
     *
     * The defi deposit/claim txns has 0-values for `publicValue`, `publicOwner` and `assetId`
     * No need to copy anything into memory for these fields as memory defaults to 0
     */
    function defiDepositOrClaimTx(uint256 inPtr, uint256 outPtr) internal pure returns (uint256) {
        assembly {
            calldatacopy(add(outPtr, 0x20), add(inPtr, 0x20), 0x80) // noteCommitment1 ... nullifier2
        }
        unchecked {
            return (inPtr + 0x81);
        }
    }

    /**
     * @dev invalid transaction function
     * If we hit this, there is a transaction whose proofId is invalid (i.e. not 0 to 7).
     * Throw an error and revert the tx.
     */
    function invalidTx(uint256, uint256) internal pure returns (uint256) {
        revert ENCODING_BYTE_INVALID();
    }

    /**
     * @dev decodes the rollup block's proof data
     * This function converts the proof data into a representation we can work with in memory
     * In particular, encoded transaction calldata is decoded and written into memory
     * The rollup header is also copied from calldata into memory
     * @return proofData numTxs publicInputsHash
     * proofData is a memory pointer to the decoded proof data
     *
     * The publicInputsHash is a sha256 hash of the public inputs associated with each transaction in the rollup.
     * It is used to validate the correctness of the data being fed into the rollup circuit
     * (there is a bit of nomenclature abuse here. Processing a public input in the verifier algorithm costs 150 gas, which
     * adds up very quickly. Instead of this, we sha256 hash what used to be the "public" inputs and only set the hash to be public.
     * We then make the old "public" inputs private in the rollup circuit, and validate their correctness by checking their sha256 hash matches
     * what we compute in the decodeProof function!
     *
     * numTxs = number of transactions in the rollup, excluding end-padding transactions
     * 
     */
    function decodeProof()
        internal
        view
        returns (
            bytes memory proofData,
            uint256 numTxs,
            uint256 publicInputsHash
        )
    {
        // declare some variables that will be set inside asm blocks
        uint256 dataSize; // size of our decoded transaction data, in bytes
        uint256 outPtr; // memory pointer to where we will write our decoded transaction data
        uint256 inPtr; // calldata pointer into our proof data
        uint256 rollupSize; // max number of transactions in the rollup block
        uint256 decodedTxDataStart;

        {
            uint256 tailInPtr; // calldata pointer to the end of our proof data

            /**
             * Let's build a function table!
             *
             * To decode our tx data, we need to iterate over every encoded transaction and call its
             * associated decoding function. If we did this via a `switch` statement this would be VERY expensive,
             * due to the large number of JUMPI instructions that would be called.
             *
             * Instead, we use function pointers.
             * The `proofId` field in our encoded proof data is an integer from 0-6,
             * we can use `proofId` to index a table of function pointers for our respective decoding functions.
             * This is much faster as there is no conditional branching!
             */
            function(uint256, uint256) pure returns (uint256) callfunc; // we're going to use `callfunc` as a function pointer
            // `functionTable` is a pointer to a table in memory, containing function pointers
            // Step 1: reserve memory for functionTable
            uint256 functionTable;
            assembly {
                functionTable := mload(0x40)
                mstore(0x40, add(functionTable, 0x100)) // reserve 256 bytes for function pointers
            }
            {
                // Step 2: copy function pointers into local variables so that inline asm code can access them
                function(uint256, uint256) pure returns (uint256) t0 = paddingTx;
                function(uint256, uint256) pure returns (uint256) t1 = depositOrWithdrawTx;
                function(uint256, uint256) pure returns (uint256) t3 = sendTx;
                function(uint256, uint256) pure returns (uint256) t4 = accountTx;
                function(uint256, uint256) pure returns (uint256) t5 = defiDepositOrClaimTx;
                function(uint256, uint256) pure returns (uint256) t7 = invalidTx;

                // Step 3: write function pointers into the table!
                assembly {
                    mstore(functionTable, t0)
                    mstore(add(functionTable, 0x20), t1)
                    mstore(add(functionTable, 0x40), t1)
                    mstore(add(functionTable, 0x60), t3)
                    mstore(add(functionTable, 0x80), t4)
                    mstore(add(functionTable, 0xa0), t5)
                    mstore(add(functionTable, 0xc0), t5)
                    mstore(add(functionTable, 0xe0), t7) // a proofId of 7 is not a valid transaction type, set to invalidTx
                }
            }
            uint256 decodedTransactionDataSize;
            assembly {
                // Add encoded proof data size to dataSize, minus the 4 bytes of encodedInnerProofData.length.
                // Set inPtr to point to the length parameter of `bytes calldata proofData`
                inPtr := add(calldataload(0x04), 0x4) // `proofData = first input parameter. Calldata offset to proofData will be at 0x04. Add 0x04 to account for function signature.
                
                // set dataSize to be the length of `bytes calldata proofData`
                // dataSize := sub(calldataload(inPtr), 0x4)

                // Advance inPtr to point to the start of proofData
                inPtr := add(inPtr, 0x20)

                numTxs := and(
                    calldataload(add(inPtr, NUM_REAL_TRANSACTIONS_OFFSET)),
                    0xffffffff
                )
                // Get encoded inner proof data size.
                // add ENCODED_PROOF_DATA_LENGTH_OFFSET to inPtr to point to the correct variable in our header block,
                // mask off all but 4 least significant bytes as this is a packed 32-bit variable.
                let encodedInnerDataSize := and(
                    calldataload(add(inPtr, ENCODED_PROOF_DATA_LENGTH_OFFSET)),
                    0xffffffff
                )
                // Add the size of trimmed zero bytes to dataSize.

                // load up the rollup size from `proofData`
                rollupSize := calldataload(add(inPtr, 0x20))

                // compute the number of bytes our decoded proof data will take up.
                // i.e. num total txns in the rollup (including padding) * number of public inputs per transaction
                let decodedInnerDataSize := mul(rollupSize, TX_PUBLIC_INPUT_LENGTH)

                // we want dataSize to equal: rollup header length + decoded tx length (excluding padding blocks)
                let numInnerRollups := calldataload(add(inPtr, sub(ROLLUP_HEADER_LENGTH, 0x20)))
                let numTxsPerRollup := div(rollupSize, numInnerRollups)

                let numFilledBlocks := div(numTxs, numTxsPerRollup)
                numFilledBlocks := add(numFilledBlocks, iszero(eq(mul(numFilledBlocks, numTxsPerRollup), numTxs)))

                decodedTransactionDataSize := mul(mul(numFilledBlocks, numTxsPerRollup), TX_PUBLIC_INPUT_LENGTH)
                // i.e. current dataSize value + (difference between decoded and encoded data)
                dataSize := add(ROLLUP_HEADER_LENGTH, decodedTransactionDataSize)

                // Allocate memory for `proofData`.
                proofData := mload(0x40)
                // set free mem ptr to dataSize + 0x20 (to account for the 0x20 bytes for the length param of proofData)
                // This allocates memory whose size is equal to the rollup header size, plus the data required for
                // each transaction's decoded tx data (256 bytes * number of non-padding blocks)
                // only reserve memory for blocks that contain non-padding proofs. These "padding" blocks don't need to be
                // stored in memory as we don't need their data for any computations
                mstore(0x40, add(proofData, add(dataSize, 0x20)))

                // set outPtr to point to the proofData length parameter
                outPtr := proofData
                // write dataSize into proofData.length
                mstore(outPtr, dataSize)
                // advance outPtr to point to start of proofData
                outPtr := add(outPtr, 0x20)

                // Copy rollup header data to `proofData`.
                calldatacopy(outPtr, inPtr, ROLLUP_HEADER_LENGTH)
                // Advance outPtr to point to the end of the header data (i.e. the start of the decoded inner transaction data)
                outPtr := add(outPtr, ROLLUP_HEADER_LENGTH)

                // Advance inPtr to point to the start of our encoded inner transaction data.
                // Add (ROLLUP_HEADER_LENGTH + 0x08) to skip over the packed (numRealTransactions, encodedProofData.length) parameters
                inPtr := add(inPtr, add(ROLLUP_HEADER_LENGTH, 0x08))

                // Set tailInPtr to point to the end of our encoded transaction data
                tailInPtr := add(inPtr, encodedInnerDataSize)
                // Set decodedTxDataStart pointer
                decodedTxDataStart := outPtr
            }
            /**
             * Start of decoding algorithm
             *
             * Iterate over every encoded transaction, load out the first byte (`proofId`) and use it to
             * jump to the relevant transaction's decoding function
             */
            assembly {
                // subtract 31 bytes off of inPtr, so that the first byte of the encoded transaction data
                // is located at the least significant byte of calldataload(inPtr)
                // also adjust tailInPtr as we compare inPtr against tailInPtr
                inPtr := sub(inPtr, 0x1f)
                tailInPtr := sub(tailInPtr, 0x1f)
            }
            unchecked {
                for (; tailInPtr > inPtr; ) {
                    assembly {
                        // For each tx, the encoding byte determines how we decode the tx calldata
                        // The encoding byte can take values from 0 to 7; we want to turn these into offsets that can index our function table.
                        // 1. Access encoding byte via `calldataload(inPtr)`. The least significant byte is our encoding byte. Mask off all but the 3 least sig bits
                        // 2. Shift left by 5 bits. This is equivalent to multiplying the encoding byte by 32.
                        // 4. The result will be 1 of 8 offset values (0x00, 0x20, ..., 0xe0) which we can use to retrieve the relevant function pointer from `functionTable`
                        let encoding := and(calldataload(inPtr), 7)
                        // store proofId at outPtr.
                        mstore(outPtr, encoding) // proofId

                        // use proofId to extract the relevant function pointer from functionTable
                        callfunc := mload(add(functionTable, shl(5, encoding)))
                    }
                    // call the decoding function. Return value will be next required value of inPtr
                    inPtr = callfunc(inPtr, outPtr);
                    // advance outPtr by the size of a decoded transaction
                    outPtr += TX_PUBLIC_INPUT_LENGTH;
                }
            }
        }

        /**
         * Compute the public inputs hash
         *
         * We need to take our decoded proof data and compute its SHA256 hash.
         * This hash is fed into our rollup proof as a public input.
         * If the hash does not match the SHA256 hash computed within the rollup circuit
         * on the equivalent parameters, the proof will reject.
         * This check ensures that the transaction data present in calldata are equal to
         * the transaction data values present in the rollup ZK-SNARK circuit.
         *
         * One complication is the structure of the SHA256 hash.
         * We slice transactions into chunks equal to the number of transactions in the "inner rollup" circuit
         * (a rollup circuit verifies multiple "inner rollup" circuits, which each verify 3-28 private user transactions.
         *  This tree structure helps parallelise proof construction)
         * We then SHA256 hash each transaction *chunk*
         * Finally we SHA256 hash the above SHA256 hashes to get our public input hash!
         *
         * We do the above instead of a straight hash of all of the transaction data,
         * because it's faster to parallelise proof construction if the majority of the SHA256 hashes are computed in
         * the "inner rollup" circuit and not the main rollup circuit.
         */
        // Step 1: compute the hashes that constitute the inner proofs data
        bool invalidRollupTopology;
        assembly {
            // we need to figure out how many rollup proofs are in this tx and how many user transactions are in each rollup
            let numRollupTxs := mload(add(proofData, ROLLUP_HEADER_LENGTH))
            let numJoinSplitsPerRollup := div(rollupSize, numRollupTxs)
            let rollupDataSize := mul(mul(numJoinSplitsPerRollup, NUMBER_OF_PUBLIC_INPUTS_PER_TX), 32)

            // Compute the number of inner rollups that don't contain padding proofs
            let numNotEmptyInnerRollups := div(numTxs, numJoinSplitsPerRollup)
            numNotEmptyInnerRollups := add(
                numNotEmptyInnerRollups,
                iszero(eq(mul(numNotEmptyInnerRollups, numJoinSplitsPerRollup), numTxs))
            )
            // Compute the number of inner rollups that only contain padding proofs!
            // For these "empty" inner rollups, we don't need to compute their public inputs hash directly,
            // we can use a precomputed value
            let numEmptyInnerRollups := sub(numRollupTxs, numNotEmptyInnerRollups)

            let proofdataHashPtr := mload(0x40)
            // copy the header data into the proofdataHash
            // header start is at calldataload(0x04) + 0x24 (+0x04 to skip over func signature, +0x20 to skip over byte array length param)
            calldatacopy(proofdataHashPtr, add(calldataload(0x04), 0x24), ROLLUP_HEADER_LENGTH)

            // update pointer
            proofdataHashPtr := add(proofdataHashPtr, ROLLUP_HEADER_LENGTH)

            // compute the endpoint for the proofdataHashPtr (used as a loop boundary condition)
            let endPtr := add(proofdataHashPtr, mul(numNotEmptyInnerRollups, 0x20))
            // iterate over the public inputs for each inner rollup proof and compute their SHA256 hash

            // better solution here is ... iterate over number of non-padding rollup blocks
            // and hash those
            // for padding rollup blocks...just append the zero hash
            for {

            } lt(proofdataHashPtr, endPtr) {
                proofdataHashPtr := add(proofdataHashPtr, 0x20)
            } {
                // address(0x02) is the SHA256 precompile address
                if iszero(staticcall(gas(), 0x02, decodedTxDataStart, rollupDataSize, 0x00, 0x20)) {
                    revert(0x00, 0x00)
                }

                mstore(proofdataHashPtr, mod(mload(0x00), CIRCUIT_MODULUS))
                decodedTxDataStart := add(decodedTxDataStart, rollupDataSize)
            }

            // If there are empty inner rollups, we can use a precomputed hash
            // of their public inputs instead of computing it directly.
            if iszero(iszero(numEmptyInnerRollups))
            {
                let zeroHash
                switch numJoinSplitsPerRollup
                case 32 {
                    zeroHash := PADDING_ROLLUP_HASH_SIZE_32
                }
                case 16 {
                    zeroHash := PADDING_ROLLUP_HASH_SIZE_16
                }
                case 64 {
                    zeroHash := PADDING_ROLLUP_HASH_SIZE_64
                }
                case 1 {
                    zeroHash := PADDING_ROLLUP_HASH_SIZE_1
                }
                case 2 {
                    zeroHash := PADDING_ROLLUP_HASH_SIZE_2
                }
                case 4 {
                    zeroHash := PADDING_ROLLUP_HASH_SIZE_4
                }
                case 8 {
                    zeroHash := PADDING_ROLLUP_HASH_SIZE_8
                }
                default {
                    invalidRollupTopology := true
                }
    
                endPtr := add(endPtr, mul(numEmptyInnerRollups, 0x20))
                for {

                } lt (proofdataHashPtr, endPtr) {
                    proofdataHashPtr := add(proofdataHashPtr, 0x20)
                } {
                    mstore(proofdataHashPtr, zeroHash)
                }
            }
            // compute SHA256 hash of header data + inner public input hashes
            let startPtr := mload(0x40)
            if iszero(staticcall(gas(), 0x02, startPtr, sub(proofdataHashPtr, startPtr), 0x00, 0x20)) {
                revert(0x00, 0x00)
            }
            publicInputsHash := mod(mload(0x00), CIRCUIT_MODULUS)
        }
        if (invalidRollupTopology)
        {
            revert INVALID_ROLLUP_TOPOLOGY();
        }
    }

    /**
     * @dev Extract the `rollupId` param from the decoded proof data.
     * represents the rollupId of the next valid rollup block
     * @param proofData the decoded proof data
     * @return nextRollupId the expected id of the next rollup block
     */
    function getRollupId(bytes memory proofData) internal pure returns (uint256 nextRollupId) {
        assembly {
            nextRollupId := mload(add(proofData, 0x20))
        }
    }

    /**
     * @dev Decode the public inputs component of proofData and compute sha3 hash of merkle roots && dataStartIndex
     *      The rollup's state is uniquely defined by the following variables:
     *          * The next empty location in the data root tree (rollupId + 1)
     *          * The next empty location in the data tree (dataStartIndex + rollupSize)
     *          * The root of the data tree
     *          * The root of the nullifier set
     *          * The root of the data root tree (tree containing all previous roots of the data tree)
     *          * The root of the defi tree
     *      Instead of storing all of these variables in storage (expensive!), we store a keccak256 hash of them.
     *      To validate the correctness of a block's state transition, we must perform the following:
     *          * Use proof broadcasted inputs to reconstruct the "old" state hash
     *          * Use proof broadcasted inputs to reconstruct the "new" state hash
     *          * Validate the old state hash matches what is in storage
     *          * Set the old state hash to the new state hash
     *      N.B. we still store dataSize as a separate storage var as proofData does not contain all
     *           neccessary information to reconstruct its old value.
     * @param proofData - cryptographic proofData associated with a rollup
     */
    function computeRootHashes(bytes memory proofData)
        internal
        pure
        returns (
            uint256 rollupId,
            bytes32 oldStateHash,
            bytes32 newStateHash,
            uint32 numDataLeaves,
            uint32 dataStartIndex
        )
    {
        assembly {
            let dataStart := add(proofData, 0x20) // jump over first word, it's length of data
            numDataLeaves := shl(1, mload(add(dataStart, 0x20))) // rollupSize * 2 (2 notes per tx)
            dataStartIndex := mload(add(dataStart, 0x40))

            // validate numDataLeaves && dataStartIndex are uint32s
            if or(gt(numDataLeaves, 0xffffffff), gt(dataStartIndex, 0xffffffff))
            {
                revert(0,0)
            }
            rollupId := mload(dataStart)

            let mPtr := mload(0x40)

            mstore(mPtr, rollupId) // old nextRollupId
            mstore(add(mPtr, 0x20), mload(add(dataStart, 0x60))) // oldDataRoot
            mstore(add(mPtr, 0x40), mload(add(dataStart, 0xa0))) // oldNullRoot
            mstore(add(mPtr, 0x60), mload(add(dataStart, 0xe0))) // oldRootRoot
            mstore(add(mPtr, 0x80), mload(add(dataStart, 0x120))) // oldDefiRoot
            oldStateHash := keccak256(mPtr, 0xa0)

            mstore(mPtr, add(rollupId, 0x01)) // new nextRollupId
            mstore(add(mPtr, 0x20), mload(add(dataStart, 0x80))) // newDataRoot
            mstore(add(mPtr, 0x40), mload(add(dataStart, 0xc0))) // newNullRoot
            mstore(add(mPtr, 0x60), mload(add(dataStart, 0x100))) // newRootRoot
            mstore(add(mPtr, 0x80), mload(add(dataStart, 0x140))) // newDefiRoot
            newStateHash := keccak256(mPtr, 0xa0)
        }
    }

    /**
     * @dev extract the `prevDefiInterationHash` from the proofData's rollup header
     * @param proofData byte array of our input proof data
     * @return prevDefiInteractionHash the defiInteractionHash of the previous rollup block
     */
    function extractPrevDefiInteractionHash(bytes memory proofData)
        internal
        pure
        returns (bytes32 prevDefiInteractionHash)
    {
        assembly {
            prevDefiInteractionHash := mload(add(proofData, PREVIOUS_DEFI_INTERACTION_HASH_OFFSET))
        }
    }

    /**
     * @dev extract the address we pay the rollup fee to, from the proofData's rollup header
     * This "rollup beneficiary" address is included as part of the ZK-SNARK circuit data, so that
     * the rollup provider can explicitly define who should get the fee at the point they generate the ZK-SNARK proof.
     * (instead of simply sending the fee to msg.sender)
     * This prevents front-running attacks where an attacker can take somebody else's rollup proof from out of the tx pool and replay it, stealing the fee.
     * @param proofData byte array of our input proof data
     * @return rollupBeneficiaryAddress the address we pay this rollup block's fee to
     */
    function extractRollupBeneficiaryAddress(bytes memory proofData)
        internal
        pure
        returns (address rollupBeneficiaryAddress)
    {
        assembly {
            rollupBeneficiaryAddress := mload(add(proofData, ROLLUP_BENEFICIARY_OFFSET))
            // validate rollupBeneficiaryAddress is an address!
            if gt(rollupBeneficiaryAddress, ADDRESS_MASK) {
                revert(0, 0)
            }

        }
    }

    /**
     * @dev Extract an assetId from the rollup block.
     * The rollup block contains up to 16 different assets, which can be recovered from the rollup header data.
     * @param proofData byte array of our input proof data
     * @param idx The index of the asset we want. assetId = header.assetIds[idx]
     * @return assetId the 30-bit identifier of an asset. The ERC20 token address is obtained via the mapping `supportedAssets[assetId]`, 
     */
    function extractAssetId(
        bytes memory proofData,
        uint256 idx
    ) internal pure returns (uint256 assetId) {
        assembly {
            assetId := mload(add(add(add(proofData, BRIDGE_IDS_OFFSET), mul(0x40, NUMBER_OF_BRIDGE_CALLS)), mul(0x20, idx)))
            // validate assetId is a uint32!
            if gt(assetId, 0xffffffff) {
                revert(0, 0)
            }
        }
    }

    /**
     * @dev Extract the transaction fee, for a given asset, due to be paid to the rollup beneficiary
     * The total fee is the sum of the individual fees paid by each transaction in the rollup block.
     * This sum is computed directly in the rollup circuit, and is present in the rollup header data
     * @param proofData byte array of our input proof data
     * @param idx The index of the asset the fee is denominated in
     * @return totalTxFee 
     */
    function extractTotalTxFee(
        bytes memory proofData,
        uint256 idx
    ) internal pure returns (uint256 totalTxFee) {
        assembly {
            totalTxFee := mload(add(add(add(proofData, 0x380), mul(0x40, NUMBER_OF_BRIDGE_CALLS)), mul(0x20, idx)))
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2022 Aztec
pragma solidity >=0.8.4;

/**
 * @title TokenTransfers
 * @dev Provides functions to safely call `transfer` and `transferFrom` methods on ERC20 tokens,
 * as well as the ability to call `transfer` and `transferFrom` without bubbling up errors
 */
library TokenTransfers {
    bytes4 private constant TRANSFER_SELECTOR = 0xa9059cbb; // bytes4(keccak256('transfer(address,uint256)'));
    bytes4 private constant TRANSFER_FROM_SELECTOR = 0x23b872dd; // bytes4(keccak256('transferFrom(address,address,uint256)'));

    /**
     * @dev Safely call ERC20.transfer, handles tokens that do not throw on transfer failure or do not return transfer result
     * @param tokenAddress Where does the token live?
     * @param to Who are we sending tokens to?
     * @param amount How many tokens are we transferring?
     */
    function safeTransferTo(
        address tokenAddress,
        address to,
        uint256 amount
    ) internal {
        // The ERC20 token standard states that:
        // 1. failed transfers must throw
        // 2. the result of the transfer (success/fail) is returned as a boolean
        // Some token contracts don't implement the spec correctly and will do one of the following:
        // 1. Contract does not throw if transfer fails, instead returns false
        // 2. Contract throws if transfer fails, but does not return any boolean value
        // We can check for these by evaluating the following:
        // | call succeeds? (c) | return value (v) | returndatasize == 0 (r)| interpreted result |
        // | ---                | ---              | ---                    | ---                |
        // | false              | false            | false                  | transfer fails     |
        // | false              | false            | true                   | transfer fails     |
        // | false              | true             | false                  | transfer fails     |
        // | false              | true             | true                   | transfer fails     |
        // | true               | false            | false                  | transfer fails     |
        // | true               | false            | true                   | transfer succeeds  |
        // | true               | true             | false                  | transfer succeeds  |
        // | true               | true             | true                   | transfer succeeds  |
        //
        // i.e. failure state = !(c && (r || v))
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, TRANSFER_SELECTOR)
            mstore(add(ptr, 0x4), to)
            mstore(add(ptr, 0x24), amount)
            let call_success := call(gas(), tokenAddress, 0, ptr, 0x44, 0x00, 0x20)
            let result_success := or(iszero(returndatasize()), and(mload(0), 1))
            if iszero(and(call_success, result_success)) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
    }

    /**
     * @dev Safely call ERC20.transferFrom, handles tokens that do not throw on transfer failure or do not return transfer result
     * @param tokenAddress Where does the token live?
     * @param source Who are we transferring tokens from
     * @param target Who are we transferring tokens to?
     * @param amount How many tokens are being transferred?
     */
    function safeTransferFrom(
        address tokenAddress,
        address source,
        address target,
        uint256 amount
    ) internal {
        assembly {
            // call tokenAddress.transferFrom(source, target, value)
            let mPtr := mload(0x40)
            mstore(mPtr, TRANSFER_FROM_SELECTOR)
            mstore(add(mPtr, 0x04), source)
            mstore(add(mPtr, 0x24), target)
            mstore(add(mPtr, 0x44), amount)
            let call_success := call(gas(), tokenAddress, 0, mPtr, 0x64, 0x00, 0x20)
            let result_success := or(iszero(returndatasize()), and(mload(0), 1))
            if iszero(and(call_success, result_success)) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
    }

    /**
     * @dev Calls ERC(tokenAddress).transfer(to, amount). Errors are ignored! Use with caution!
     * @param tokenAddress Where does the token live?
     * @param to Who are we sending to?
     * @param amount How many tokens are being transferred?
     * @param gasToSend Amount of gas to send the contract. If value is 0, function uses gas() instead
     */
    function transferToDoNotBubbleErrors(
        address tokenAddress,
        address to,
        uint256 amount,
        uint256 gasToSend
    ) internal {
        assembly {
            let callGas := gas()
            if gasToSend {
                callGas := gasToSend
            }
            let ptr := mload(0x40)
            mstore(ptr, TRANSFER_SELECTOR)
            mstore(add(ptr, 0x4), to)
            mstore(add(ptr, 0x24), amount)
            pop(call(callGas, tokenAddress, 0, ptr, 0x44, 0x00, 0x00))
        }
    }

    /**
     * @dev Calls ERC(tokenAddress).transferFrom(source, target, amount). Errors are ignored! Use with caution!
     * @param tokenAddress Where does the token live?
     * @param source Who are we transferring tokens from
     * @param target Who are we transferring tokens to?
     * @param amount How many tokens are being transferred?
     * @param gasToSend Amount of gas to send the contract. If value is 0, function uses gas() instead
     */
    function transferFromDoNotBubbleErrors(
        address tokenAddress,
        address source,
        address target,
        uint256 amount,
        uint256 gasToSend
    ) internal {
        assembly {
            let callGas := gas()
            if gasToSend {
                callGas := gasToSend
            }
            let mPtr := mload(0x40)
            mstore(mPtr, TRANSFER_FROM_SELECTOR)
            mstore(add(mPtr, 0x04), source)
            mstore(add(mPtr, 0x24), target)
            mstore(add(mPtr, 0x44), amount)
            pop(call(callGas, tokenAddress, 0, mPtr, 0x64, 0x00, 0x00))
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2022 Aztec
pragma solidity >=0.8.4;

library RollupProcessorLibrary {
    error SIGNATURE_ADDRESS_IS_ZERO();
    error SIGNATURE_RECOVERY_FAILED();
    error INVALID_SIGNATURE();

    /**
     * Extracts the address of the signer with ECDSA. Performs checks on `s` and `v` to
     * to prevent signature malleability based attacks
     * @param digest - Hashed data being signed over.
     * @param signature - ECDSA signature over the secp256k1 elliptic curve.
     * @param signer - Address that signs the signature.
     */
    function validateSignature(
        bytes32 digest,
        bytes memory signature,
        address signer
    ) internal view {
        bool result;
        address recoveredSigner = address(0x0);
        if (signer == address(0x0)) {
            revert SIGNATURE_ADDRESS_IS_ZERO();
        }

        // prepend "\x19Ethereum Signed Message:\n32" to the digest to create the signed message
        bytes32 message;
        assembly {
            mstore(0, '\x19Ethereum Signed Message:\n32')
            mstore(add(0, 28), digest)
            message := keccak256(0, 60)
        }
        assembly {
            let mPtr := mload(0x40)
            let byteLength := mload(signature)

            // store the signature digest
            mstore(mPtr, message)

            // load 'v' - we need it for a condition check
            // add 0x60 to jump over 3 words - length of bytes array, r and s
            let v := shr(248, mload(add(signature, 0x60))) // bitshifting, to resemble padLeft
            let s := mload(add(signature, 0x40))

            /**
             * Original memory map for input to precompile
             *
             * signature : signature + 0x20            message
             * signature + 0x20 : signature + 0x40     r
             * signature + 0x40 : signature + 0x60     s
             * signature + 0x60 : signature + 0x80     v
             * Desired memory map for input to precompile
             *
             * signature : signature + 0x20            message
             * signature + 0x20 : signature + 0x40     v
             * signature + 0x40 : signature + 0x60     r
             * signature + 0x60 : signature + 0x80     s
             */

            // store s
            mstore(add(mPtr, 0x60), s)
            // store r
            mstore(add(mPtr, 0x40), mload(add(signature, 0x20)))
            // store v
            mstore(add(mPtr, 0x20), v)
            result := and(
                and(
                    // validate s is in lower half order
                    lt(s, 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A1),
                    and(
                        // validate signature length == 0x41
                        eq(byteLength, 0x41),
                        // validate v == 27 or v == 28
                        or(eq(v, 27), eq(v, 28))
                    )
                ),
                // validate call to ecrecover precompile succeeds
                staticcall(gas(), 0x01, mPtr, 0x80, mPtr, 0x20)
            )

            // save the recoveredSigner only if the first word in signature is not `message` anymore
            switch eq(message, mload(mPtr))
            case 0 {
                recoveredSigner := mload(mPtr)
            }
            mstore(mPtr, byteLength) // and put the byte length back where it belongs

            // validate that recoveredSigner is not address(0x00)
            result := and(result, not(iszero(recoveredSigner)))
        }
        if (!result) {
            revert SIGNATURE_RECOVERY_FAILED();
        }
        if (recoveredSigner != signer) {
            revert INVALID_SIGNATURE();
        }
    }

    /**
     * Extracts the address of the signer with ECDSA. Performs checks on `s` and `v` to
     * to prevent signature malleability based attacks
     * This 'Unpacked' version expects 'signature' to be a 92-byte array.
     * i.e. the `v` parameter occupies a full 32 bytes of memory, not 1 byte
     * @param hashedMessage - Hashed data being signed over. This function only works if the message has been pre formated to EIP https://eips.ethereum.org/EIPS/eip-191
     * @param signature - ECDSA signature over the secp256k1 elliptic curve.
     * @param signer - Address that signs the signature.
     */
    function validateSheildSignatureUnpacked(
        bytes32 hashedMessage,
        bytes memory signature,
        address signer
    ) internal view {
        bool result;
        address recoveredSigner = address(0x0);
        if (signer == address(0x0)) {
            revert SIGNATURE_ADDRESS_IS_ZERO();
        }
        assembly {
            let mPtr := mload(0x40)
            // There's a little trick we can pull. We expect `signature` to be a byte array, of length 0x60, with
            // 'v', 'r' and 's' located linearly in memory. Preceeding this is the length parameter of `signature`.
            // We *replace* the length param with the signature msg to get a memory block formatted for the precompile
            // load length as a temporary variable
            // N.B. we mutate the signature by re-ordering r, s, and v!
            let byteLength := mload(signature)

            // store the signature digest
            mstore(signature, hashedMessage)

            // load 'v' - we need it for a condition check
            // add 0x60 to jump over 3 words - length of bytes array, r and s
            let v := mload(add(signature, 0x60))
            let s := mload(add(signature, 0x40))

            /**
             * Original memory map for input to precompile
             *
             * signature : signature + 0x20            message
             * signature + 0x20 : signature + 0x40     r
             * signature + 0x40 : signature + 0x60     s
             * signature + 0x60 : signature + 0x80     v
             * Desired memory map for input to precompile
             *
             * signature : signature + 0x20            message
             * signature + 0x20 : signature + 0x40     v
             * signature + 0x40 : signature + 0x60     r
             * signature + 0x60 : signature + 0x80     s
             */

            // move s to v position
            mstore(add(signature, 0x60), s)
            // move r to s position
            mstore(add(signature, 0x40), mload(add(signature, 0x20)))
            // move v to r position
            mstore(add(signature, 0x20), v)
            result := and(
                and(
                    // validate s is in lower half order
                    lt(s, 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A1),
                    and(
                        // validate signature length == 0x60 (unpacked)
                        eq(byteLength, 0x60),
                        // validate v == 27 or v == 28
                        or(eq(v, 27), eq(v, 28))
                    )
                ),
                // validate call to ecrecover precompile succeeds
                staticcall(gas(), 0x01, signature, 0x80, signature, 0x20)
            )

            // save the recoveredSigner only if the first word in signature is not `message` anymore
            switch eq(hashedMessage, mload(signature))
            case 0 {
                recoveredSigner := mload(signature)
            }
            mstore(signature, byteLength) // and put the byte length back where it belongs

            // validate that recoveredSigner is not address(0x00)
            result := and(result, not(iszero(recoveredSigner)))
        }
        if (!result) {
            revert SIGNATURE_RECOVERY_FAILED();
        }
        if (recoveredSigner != signer) {
            revert INVALID_SIGNATURE();
        }
    }

    /**
     * Extracts the address of the signer with ECDSA. Performs checks on `s` and `v` to
     * to prevent signature malleability based attacks
     * This 'Unpacked' version expects 'signature' to be a 92-byte array.
     * i.e. the `v` parameter occupies a full 32 bytes of memory, not 1 byte
     * @param digest - Hashed data being signed over.
     * @param signature - ECDSA signature over the secp256k1 elliptic curve.
     * @param signer - Address that signs the signature.
     */
    function validateUnpackedSignature(
        bytes32 digest,
        bytes memory signature,
        address signer
    ) internal view {
        bool result;
        address recoveredSigner = address(0x0);
        if (signer == address(0x0)) {
            revert SIGNATURE_ADDRESS_IS_ZERO();
        }

        // prepend "\x19Ethereum Signed Message:\n32" to the digest to create the signed message
        bytes32 message;
        assembly {
            mstore(0, '\x19Ethereum Signed Message:\n32')
            mstore(28, digest)
            message := keccak256(0, 60)
        }
        assembly {
            // There's a little trick we can pull. We expect `signature` to be a byte array, of length 0x60, with
            // 'v', 'r' and 's' located linearly in memory. Preceeding this is the length parameter of `signature`.
            // We *replace* the length param with the signature msg to get a memory block formatted for the precompile
            // load length as a temporary variable
            // N.B. we mutate the signature by re-ordering r, s, and v!
            let byteLength := mload(signature)

            // store the signature digest
            mstore(signature, message)

            // load 'v' - we need it for a condition check
            // add 0x60 to jump over 3 words - length of bytes array, r and s
            let v := mload(add(signature, 0x60))
            let s := mload(add(signature, 0x40))

            /**
             * Original memory map for input to precompile
             *
             * signature : signature + 0x20            message
             * signature + 0x20 : signature + 0x40     r
             * signature + 0x40 : signature + 0x60     s
             * signature + 0x60 : signature + 0x80     v
             * Desired memory map for input to precompile
             *
             * signature : signature + 0x20            message
             * signature + 0x20 : signature + 0x40     v
             * signature + 0x40 : signature + 0x60     r
             * signature + 0x60 : signature + 0x80     s
             */

            // move s to v position
            mstore(add(signature, 0x60), s)
            // move r to s position
            mstore(add(signature, 0x40), mload(add(signature, 0x20)))
            // move v to r position
            mstore(add(signature, 0x20), v)
            result := and(
                and(
                    // validate s is in lower half order
                    lt(s, 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A1),
                    and(
                        // validate signature length == 0x60 (unpacked)
                        eq(byteLength, 0x60),
                        // validate v == 27 or v == 28
                        or(eq(v, 27), eq(v, 28))
                    )
                ),
                // validate call to ecrecover precompile succeeds
                staticcall(gas(), 0x01, signature, 0x80, signature, 0x20)
            )

            // save the recoveredSigner only if the first word in signature is not `message` anymore
            switch eq(message, mload(signature))
            case 0 {
                recoveredSigner := mload(signature)
            }
            mstore(signature, byteLength) // and put the byte length back where it belongs

            // validate that recoveredSigner is not address(0x00)
            result := and(result, not(iszero(recoveredSigner)))
        }
        if (!result) {
            revert SIGNATURE_RECOVERY_FAILED();
        }
        if (recoveredSigner != signer) {
            revert INVALID_SIGNATURE();
        }
    }

    /**
     * Convert a bytes32 into an ASCII encoded hex string
     * @param input bytes32 variable
     * @return result hex-encoded string
     */
    function toHexString(bytes32 input) public pure returns (string memory result) {
        if (uint256(input) == 0x00) {
            assembly {
                result := mload(0x40)
                mstore(result, 0x40)
                mstore(add(result, 0x20), 0x3030303030303030303030303030303030303030303030303030303030303030)
                mstore(add(result, 0x40), 0x3030303030303030303030303030303030303030303030303030303030303030)
                mstore(0x40, add(result, 0x60))
            }
            return result;
        }
        assembly {
            result := mload(0x40)
            let table := add(result, 0x60)

            // Store lookup table that maps an integer from 0 to 99 into a 2-byte ASCII equivalent
            // Store lookup table that maps an integer from 0 to ff into a 2-byte ASCII equivalent
            mstore(add(table, 0x1e), 0x3030303130323033303430353036303730383039306130623063306430653066)
            mstore(add(table, 0x3e), 0x3130313131323133313431353136313731383139316131623163316431653166)
            mstore(add(table, 0x5e), 0x3230323132323233323432353236323732383239326132623263326432653266)
            mstore(add(table, 0x7e), 0x3330333133323333333433353336333733383339336133623363336433653366)
            mstore(add(table, 0x9e), 0x3430343134323433343434353436343734383439346134623463346434653466)
            mstore(add(table, 0xbe), 0x3530353135323533353435353536353735383539356135623563356435653566)
            mstore(add(table, 0xde), 0x3630363136323633363436353636363736383639366136623663366436653666)
            mstore(add(table, 0xfe), 0x3730373137323733373437353736373737383739376137623763376437653766)
            mstore(add(table, 0x11e), 0x3830383138323833383438353836383738383839386138623863386438653866)
            mstore(add(table, 0x13e), 0x3930393139323933393439353936393739383939396139623963396439653966)
            mstore(add(table, 0x15e), 0x6130613161326133613461356136613761386139616161626163616461656166)
            mstore(add(table, 0x17e), 0x6230623162326233623462356236623762386239626162626263626462656266)
            mstore(add(table, 0x19e), 0x6330633163326333633463356336633763386339636163626363636463656366)
            mstore(add(table, 0x1be), 0x6430643164326433643464356436643764386439646164626463646464656466)
            mstore(add(table, 0x1de), 0x6530653165326533653465356536653765386539656165626563656465656566)
            mstore(add(table, 0x1fe), 0x6630663166326633663466356636663766386639666166626663666466656666)
            /**
             * Convert `input` into ASCII.
             *
             * Slice 2 base-10  digits off of the input, use to index the ASCII lookup table.
             *
             * We start from the least significant digits, write results into mem backwards,
             * this prevents us from overwriting memory despite the fact that each mload
             * only contains 2 byteso f useful data.
             **/

            let base := input
            function slice(v, tableptr) {
                mstore(0x1e, mload(add(tableptr, shl(1, and(v, 0xff)))))
                mstore(0x1c, mload(add(tableptr, shl(1, and(shr(8, v), 0xff)))))
                mstore(0x1a, mload(add(tableptr, shl(1, and(shr(16, v), 0xff)))))
                mstore(0x18, mload(add(tableptr, shl(1, and(shr(24, v), 0xff)))))
                mstore(0x16, mload(add(tableptr, shl(1, and(shr(32, v), 0xff)))))
                mstore(0x14, mload(add(tableptr, shl(1, and(shr(40, v), 0xff)))))
                mstore(0x12, mload(add(tableptr, shl(1, and(shr(48, v), 0xff)))))
                mstore(0x10, mload(add(tableptr, shl(1, and(shr(56, v), 0xff)))))
                mstore(0x0e, mload(add(tableptr, shl(1, and(shr(64, v), 0xff)))))
                mstore(0x0c, mload(add(tableptr, shl(1, and(shr(72, v), 0xff)))))
                mstore(0x0a, mload(add(tableptr, shl(1, and(shr(80, v), 0xff)))))
                mstore(0x08, mload(add(tableptr, shl(1, and(shr(88, v), 0xff)))))
                mstore(0x06, mload(add(tableptr, shl(1, and(shr(96, v), 0xff)))))
                mstore(0x04, mload(add(tableptr, shl(1, and(shr(104, v), 0xff)))))
                mstore(0x02, mload(add(tableptr, shl(1, and(shr(112, v), 0xff)))))
                mstore(0x00, mload(add(tableptr, shl(1, and(shr(120, v), 0xff)))))
            }

            mstore(result, 0x40)
            slice(base, table)
            mstore(add(result, 0x40), mload(0x1e))
            base := shr(128, base)
            slice(base, table)
            mstore(add(result, 0x20), mload(0x1e))
            mstore(0x40, add(result, 0x60))
        }
    }

    function getSignedMessageForTxId(bytes32 txId) internal pure returns (bytes32 hashedMessage) {
        // we know this string length is 64 bytes
        string memory txIdHexString = toHexString(txId);

        assembly {
            let mPtr := mload(0x40)
            mstore(add(mPtr, 32), '\x19Ethereum Signed Message:\n210')
            mstore(add(mPtr, 61), 'Signing this message will allow ')
            mstore(add(mPtr, 93), 'your pending funds to be spent i')
            mstore(add(mPtr, 125), 'n Aztec transaction:\n\n0x')
            mstore(add(mPtr, 149), mload(add(txIdHexString, 0x20)))
            mstore(add(mPtr, 181), mload(add(txIdHexString, 0x40)))
            mstore(add(mPtr, 213), '\n\nIMPORTANT: Only sign the messa')
            mstore(add(mPtr, 245), 'ge if you trust the client')
            hashedMessage := keccak256(add(mPtr, 32), 239)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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

// SPDX-License-Identifier: Apache-2.0
// Copyright 2022 Aztec
pragma solidity >=0.8.4;

import {RollupProcessor} from '../RollupProcessor.sol';

/**
 * @title Rollup processor contract
 * @dev Warning: do not deploy in real environments, for testing only
 * Adds some methods to fiddle around with storage vars
 */
contract TestRollupProcessor is RollupProcessor {
    constructor(uint256 _escapeBlockLowerBound, uint256 _escapeBlockUpperBound)
        RollupProcessor(_escapeBlockLowerBound, _escapeBlockUpperBound)
    {}

    // Used to pre-fund the rollup with some Eth (to mimic deposited Eth for defi interactions)
    receive() external payable {}

    // Used to test we correctly check the length of asyncDefiTransactionHashes
    function stubAsyncTransactionHashesLength(uint256 size) public {
        rollupState.numAsyncDefiInteractionHashes = uint16(size);
    }

    // Used to test we correctly check length of defiTransactionhashes
    function stubTransactionHashesLength(uint256 size) public {
        rollupState.numDefiInteractionHashes = uint16(size);
        assembly {
            mstore(0x00, defiInteractionHashes.slot)
            // Write the 'zero-hash' into the last `numberOfBridgeCalls` entries to ensure that computed
            // defiInteractionHash will be correct
            let slot := keccak256(0x00, 0x20)
            for {
                let i := 0
            } lt(i, NUMBER_OF_BRIDGE_CALLS) {
                i := add(i, 1)
            } {
                sstore(
                    add(slot, sub(size, add(i, 1))),
                    0x2d25a1e3a51eb293004c4b56abe12ed0da6bca2b4a21936752a85d102593c1b4
                )
            }
        }
    }
}

contract UpgradedTestRollupProcessorV0 is TestRollupProcessor {
    constructor(uint256 _escapeBlockLowerBound, uint256 _escapeBlockUpperBound)
        TestRollupProcessor(_escapeBlockLowerBound, _escapeBlockUpperBound)
    {}

    function getImplementationVersion() public pure override returns (uint8) {
        return 0;
    }
}

contract UpgradedTestRollupProcessorV2 is TestRollupProcessor {
    constructor(uint256 _escapeBlockLowerBound, uint256 _escapeBlockUpperBound)
        TestRollupProcessor(_escapeBlockLowerBound, _escapeBlockUpperBound)
    {}

    function getImplementationVersion() public pure override returns (uint8) {
        return 2;
    }
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2022 Aztec
pragma solidity >=0.8.4;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';

import {IUniswapV2Router02} from '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
import {IUniswapV2Pair} from '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import {IWETH} from '@uniswap/v2-periphery/contracts/interfaces/IWETH.sol';

import {TokenTransfers} from '../libraries/TokenTransfers.sol';
import {IFeeDistributor} from './interfaces/IFeeDistributor.sol';

/**
 * @title UniswapV2LibraryErrata
 * @dev Methods from UniswapV2Library that we need. Re-implemented due to the original from @uniswap failing to compile w. Solidity >=0.8.0
 */
library UniswapV2LibraryErrata {
    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(
        address factory,
        address tokenA,
        address tokenB
    ) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        uint256 pairUint = uint256(
            keccak256(
                abi.encodePacked(
                    hex'ff',
                    factory,
                    keccak256(abi.encodePacked(token0, token1)),
                    hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
                )
            )
        );
        assembly {
            pair := and(pairUint, 0xffffffffffffffffffffffffffffffffffffffff)
        }
    }

    // fetches and sorts the reserves for a pair
    function getReserves(
        address factory,
        address tokenA,
        address tokenB
    ) internal view returns (uint256 reserveA, uint256 reserveB) {
        (address token0, ) = sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint256 amountInWithFee = amountIn * 997;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = reserveIn * 1000 + amountInWithFee;
        amountOut = numerator / denominator;
    }
}

contract AztecFeeDistributor is IFeeDistributor, Ownable {
    using TokenTransfers for address;

    uint256 public override feeLimit = 4e17;
    address public override aztecFeeClaimer;
    address public rollupProcessor;

    uint256 public override convertConstant = 157768 * 20; // gas for calling convert() / 5%

    address public immutable override router;
    address public immutable override factory;
    address public immutable override WETH;

    constructor(
        address _feeClaimer,
        address _rollupProcessor,
        address _router
    ) {
        aztecFeeClaimer = _feeClaimer;
        rollupProcessor = _rollupProcessor;
        router = _router;
        factory = IUniswapV2Router02(_router).factory();
        WETH = IUniswapV2Router02(_router).WETH();
    }

    // @dev top up the designated address by feeLimit
    receive() external payable {
        if (msg.sender == rollupProcessor) {
            if (aztecFeeClaimer.balance < feeLimit) {
                uint256 toSend = address(this).balance > feeLimit ? feeLimit : address(this).balance;
                (bool success, ) = aztecFeeClaimer.call{gas: 3000, value: toSend}('');
                emit FeeReimbursed(aztecFeeClaimer, toSend);
            }
        }
    }

    function setFeeLimit(uint256 _feeLimit) external override onlyOwner {
        feeLimit = _feeLimit;
    }

    function setConvertConstant(uint256 _convertConstant) external override onlyOwner {
        convertConstant = _convertConstant;
    }

    function setFeeClaimer(address _feeClaimer) external override onlyOwner {
        aztecFeeClaimer = _feeClaimer;
    }

    function txFeeBalance(address assetAddress) public view override returns (uint256) {
        if (assetAddress == address(0)) {
            return address(this).balance;
        } else {
            return IERC20(assetAddress).balanceOf(address(this));
        }
    }

    function convert(address assetAddress, uint256 minOutputValue)
        public
        override
        onlyOwner
        returns (uint256 outputValue)
    {
        require(assetAddress != address(0), 'Fee Distributor: NOT_A_TOKEN_ASSET');

        uint256 inputValue = IERC20(assetAddress).balanceOf(address(this));
        require(inputValue > 0, 'Fee Distributor: EMPTY_BALANCE');

        if (assetAddress == WETH) {
            IWETH(WETH).withdraw(inputValue);
        } else {
            outputValue = getAmountOut(assetAddress, inputValue);
            require(outputValue >= minOutputValue, 'Fee Distributor: INSUFFICIENT_OUTPUT_AMOUNT');
            swapTokensForETH(assetAddress, inputValue, outputValue);
        }

        emit Convert(assetAddress, inputValue, outputValue);
    }

    function getAmountOut(address assetAddress, uint256 inputValue) internal view returns (uint256 outputValue) {
        (uint256 reserveIn, uint256 reserveOut) = UniswapV2LibraryErrata.getReserves(factory, assetAddress, WETH);
        outputValue = UniswapV2LibraryErrata.getAmountOut(inputValue, reserveIn, reserveOut);
    }

    function swapTokensForETH(
        address assetAddress,
        uint256 inputValue,
        uint256 outputValue
    ) internal {
        address pair = UniswapV2LibraryErrata.pairFor(factory, assetAddress, WETH);
        assetAddress.safeTransferTo(pair, inputValue);

        (uint256 amountOut0, uint256 amountOut1) = assetAddress < WETH
            ? (uint256(0), outputValue)
            : (outputValue, uint256(0));
        IUniswapV2Pair(pair).swap(amountOut0, amountOut1, address(this), new bytes(0));

        IWETH(WETH).withdraw(outputValue);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

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

pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2022 Aztec
pragma solidity >=0.8.4;

interface IFeeDistributor {
    event FeeReimbursed(address receiver, uint256 amount);
    event Convert(address assetAddress, uint256 inputValue, uint256 outputValue);

    function convertConstant() external view returns (uint256);

    function feeLimit() external view returns (uint256);

    function aztecFeeClaimer() external view returns (address);

    function router() external view returns (address);

    function factory() external view returns (address);

    function WETH() external view returns (address);

    function setFeeClaimer(address _feeClaimer) external;

    function setFeeLimit(uint256 _feeLimit) external;

    function setConvertConstant(uint256 _convertConstant) external;

    function txFeeBalance(address assetAddress) external view returns (uint256);

    function convert(address assetAddress, uint256 minOutputValue) external returns (uint256 outputValue);
}

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

// SPDX-License-Identifier: Apache-2.0
// Copyright 2022 Aztec
pragma solidity >=0.8.4;

// import {UniswapV2Library} from '@uniswap/v2-periphery/contracts/libraries/UniswapV2Library.sol';
import {IUniswapV2Router02} from '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

import {IDefiBridge} from '../interfaces/IDefiBridge.sol';
import {IERC20Permit} from '../interfaces/IERC20Permit.sol';

import {AztecTypes} from '../AztecTypes.sol';

contract UniswapBridge is IDefiBridge {
    address public immutable rollupProcessor;
    address public weth;

    IUniswapV2Router02 router;

    constructor(address _rollupProcessor, address _router) {
        rollupProcessor = _rollupProcessor;
        router = IUniswapV2Router02(_router);
        weth = router.WETH();
    }

    receive() external payable {}

    function convert(
        AztecTypes.AztecAsset memory inputAssetA,
        AztecTypes.AztecAsset memory inputAssetB,
        AztecTypes.AztecAsset memory outputAssetA,
        AztecTypes.AztecAsset memory outputAssetB,
        uint256 totalInputValue,
        uint256 interactionNonce,
        uint64, /*auxData*/
        address
    )
        external
        payable
        override
        returns (
            uint256 outputValueA,
            uint256 outputValueB,
            bool isAsync
        )
    {
        // ### INITIALIZATION AND SANITY CHECKS
        require(msg.sender == rollupProcessor, 'UniswapBridge: INVALID_CALLER');
        require(
            inputAssetB.assetType == AztecTypes.AztecAssetType.NOT_USED,
            'UniswapBridge: EXPECTED_SECOND_INPUT_ASSET_NOT_USED'
        );
        require(
            outputAssetB.assetType == AztecTypes.AztecAssetType.NOT_USED,
            'UniswapBridge: EXPECTED_SECOND_OUTPUT_ASSET_NOT_USED'
        );
        outputValueB = 0;
        isAsync = false;

        // ### BRIDGE LOGIC
        uint256[] memory amounts;
        uint256 deadline = block.timestamp;
        if (inputAssetA.assetType == AztecTypes.AztecAssetType.ETH) {
            require(
                outputAssetA.assetType != AztecTypes.AztecAssetType.ETH,
                'UniswapBridge: INPUT_AND_OUTPUT_BOTH_ETH!'
            );
            address[] memory path = new address[](2);
            path[0] = weth;
            path[1] = outputAssetA.erc20Address;
            amounts = router.swapExactETHForTokens{value: totalInputValue}(0, path, address(this), deadline);
            outputValueA = amounts[1];
            IERC20Permit(outputAssetA.erc20Address).approve(rollupProcessor, outputValueA);
        } else if (outputAssetA.assetType == AztecTypes.AztecAssetType.ETH) {
            address[] memory path = new address[](2);
            path[0] = inputAssetA.erc20Address;
            path[1] = weth;
            require(
                IERC20Permit(inputAssetA.erc20Address).approve(address(router), totalInputValue),
                'UniswapBridge: APPROVE_FAILED'
            );
            amounts = router.swapExactTokensForETH(totalInputValue, 0, path, address(this), deadline);
            outputValueA = amounts[1];
            bytes memory payload = abi.encodeWithSignature('receiveEthFromBridge(uint256)', interactionNonce);
            (bool success, ) = address(rollupProcessor).call{value: outputValueA}(payload);
        } else {
            require(
                inputAssetA.assetType == AztecTypes.AztecAssetType.ERC20,
                'UniswapBridge: INPUT_ASSET_A_NOT_ETH_OR_ERC20'
            );
            require(
                outputAssetA.assetType == AztecTypes.AztecAssetType.ERC20,
                'UniswapBridge: OUTPUT_ASSET_A_NOT_ETH_OR_ERC20'
            );
            address[] memory path = new address[](3);
            path[0] = inputAssetA.erc20Address;
            path[1] = weth;
            path[2] = outputAssetA.erc20Address;
            require(
                IERC20Permit(inputAssetA.erc20Address).approve(address(router), totalInputValue),
                'UniswapBridge: APPROVE_FAILED'
            );
            amounts = router.swapExactTokensForTokens(totalInputValue, 0, path, rollupProcessor, deadline);
            outputValueA = amounts[2];
            IERC20Permit(outputAssetA.erc20Address).approve(rollupProcessor, outputValueA);
        }
    }

    function canFinalise(
        uint256 /*interactionNonce*/
    ) external pure override returns (bool) {
        return false;
    }

    function finalise(
        AztecTypes.AztecAsset memory, /*inputAssetA*/
        AztecTypes.AztecAsset memory, /*inputAssetB*/
        AztecTypes.AztecAsset memory, /*outputAssetA*/
        AztecTypes.AztecAsset memory, /*outputAssetB*/
        uint256, /*interactionNonce*/
        uint64 /*auxData*/
    )
        external
        payable
        override
        returns (
            uint256,
            uint256,
            bool
        )
    {
        require(false);
        return (0, 0, false);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/transparent/ProxyAdmin.sol)

pragma solidity ^0.8.0;

import "./TransparentUpgradeableProxy.sol";
import "../../access/Ownable.sol";

/**
 * @dev This is an auxiliary contract meant to be assigned as the admin of a {TransparentUpgradeableProxy}. For an
 * explanation of why you would want to use this see the documentation for {TransparentUpgradeableProxy}.
 */
contract ProxyAdmin is Ownable {
    /**
     * @dev Returns the current implementation of `proxy`.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function getProxyImplementation(TransparentUpgradeableProxy proxy) public view virtual returns (address) {
        // We need to manually run the static call since the getter cannot be flagged as view
        // bytes4(keccak256("implementation()")) == 0x5c60da1b
        (bool success, bytes memory returndata) = address(proxy).staticcall(hex"5c60da1b");
        require(success);
        return abi.decode(returndata, (address));
    }

    /**
     * @dev Returns the current admin of `proxy`.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function getProxyAdmin(TransparentUpgradeableProxy proxy) public view virtual returns (address) {
        // We need to manually run the static call since the getter cannot be flagged as view
        // bytes4(keccak256("admin()")) == 0xf851a440
        (bool success, bytes memory returndata) = address(proxy).staticcall(hex"f851a440");
        require(success);
        return abi.decode(returndata, (address));
    }

    /**
     * @dev Changes the admin of `proxy` to `newAdmin`.
     *
     * Requirements:
     *
     * - This contract must be the current admin of `proxy`.
     */
    function changeProxyAdmin(TransparentUpgradeableProxy proxy, address newAdmin) public virtual onlyOwner {
        proxy.changeAdmin(newAdmin);
    }

    /**
     * @dev Upgrades `proxy` to `implementation`. See {TransparentUpgradeableProxy-upgradeTo}.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function upgrade(TransparentUpgradeableProxy proxy, address implementation) public virtual onlyOwner {
        proxy.upgradeTo(implementation);
    }

    /**
     * @dev Upgrades `proxy` to `implementation` and calls a function on the new implementation. See
     * {TransparentUpgradeableProxy-upgradeToAndCall}.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function upgradeAndCall(
        TransparentUpgradeableProxy proxy,
        address implementation,
        bytes memory data
    ) public payable virtual onlyOwner {
        proxy.upgradeToAndCall{value: msg.value}(implementation, data);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/transparent/TransparentUpgradeableProxy.sol)

pragma solidity ^0.8.0;

import "../ERC1967/ERC1967Proxy.sol";

/**
 * @dev This contract implements a proxy that is upgradeable by an admin.
 *
 * To avoid https://medium.com/nomic-labs-blog/malicious-backdoors-in-ethereum-proxies-62629adf3357[proxy selector
 * clashing], which can potentially be used in an attack, this contract uses the
 * https://blog.openzeppelin.com/the-transparent-proxy-pattern/[transparent proxy pattern]. This pattern implies two
 * things that go hand in hand:
 *
 * 1. If any account other than the admin calls the proxy, the call will be forwarded to the implementation, even if
 * that call matches one of the admin functions exposed by the proxy itself.
 * 2. If the admin calls the proxy, it can access the admin functions, but its calls will never be forwarded to the
 * implementation. If the admin tries to call a function on the implementation it will fail with an error that says
 * "admin cannot fallback to proxy target".
 *
 * These properties mean that the admin account can only be used for admin actions like upgrading the proxy or changing
 * the admin, so it's best if it's a dedicated account that is not used for anything else. This will avoid headaches due
 * to sudden errors when trying to call a function from the proxy implementation.
 *
 * Our recommendation is for the dedicated account to be an instance of the {ProxyAdmin} contract. If set up this way,
 * you should think of the `ProxyAdmin` instance as the real administrative interface of your proxy.
 */
contract TransparentUpgradeableProxy is ERC1967Proxy {
    /**
     * @dev Initializes an upgradeable proxy managed by `_admin`, backed by the implementation at `_logic`, and
     * optionally initialized with `_data` as explained in {ERC1967Proxy-constructor}.
     */
    constructor(
        address _logic,
        address admin_,
        bytes memory _data
    ) payable ERC1967Proxy(_logic, _data) {
        assert(_ADMIN_SLOT == bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1));
        _changeAdmin(admin_);
    }

    /**
     * @dev Modifier used internally that will delegate the call to the implementation unless the sender is the admin.
     */
    modifier ifAdmin() {
        if (msg.sender == _getAdmin()) {
            _;
        } else {
            _fallback();
        }
    }

    /**
     * @dev Returns the current admin.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyAdmin}.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`
     */
    function admin() external ifAdmin returns (address admin_) {
        admin_ = _getAdmin();
    }

    /**
     * @dev Returns the current implementation.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyImplementation}.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
     */
    function implementation() external ifAdmin returns (address implementation_) {
        implementation_ = _implementation();
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-changeProxyAdmin}.
     */
    function changeAdmin(address newAdmin) external virtual ifAdmin {
        _changeAdmin(newAdmin);
    }

    /**
     * @dev Upgrade the implementation of the proxy.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgrade}.
     */
    function upgradeTo(address newImplementation) external ifAdmin {
        _upgradeToAndCall(newImplementation, bytes(""), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy, and then call a function from the new implementation as specified
     * by `data`, which should be an encoded function call. This is useful to initialize new storage variables in the
     * proxied contract.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgradeAndCall}.
     */
    function upgradeToAndCall(address newImplementation, bytes calldata data) external payable ifAdmin {
        _upgradeToAndCall(newImplementation, data, true);
    }

    /**
     * @dev Returns the current admin.
     */
    function _admin() internal view virtual returns (address) {
        return _getAdmin();
    }

    /**
     * @dev Makes sure the admin cannot access the fallback function. See {Proxy-_beforeFallback}.
     */
    function _beforeFallback() internal virtual override {
        require(msg.sender != _getAdmin(), "TransparentUpgradeableProxy: admin cannot fallback to proxy target");
        super._beforeFallback();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/ERC1967/ERC1967Proxy.sol)

pragma solidity ^0.8.0;

import "../Proxy.sol";
import "./ERC1967Upgrade.sol";

/**
 * @dev This contract implements an upgradeable proxy. It is upgradeable because calls are delegated to an
 * implementation address that can be changed. This address is stored in storage in the location specified by
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967], so that it doesn't conflict with the storage layout of the
 * implementation behind the proxy.
 */
contract ERC1967Proxy is Proxy, ERC1967Upgrade {
    /**
     * @dev Initializes the upgradeable proxy with an initial implementation specified by `_logic`.
     *
     * If `_data` is nonempty, it's used as data in a delegate call to `_logic`. This will typically be an encoded
     * function call, and allows initializating the storage of the proxy like a Solidity constructor.
     */
    constructor(address _logic, bytes memory _data) payable {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        _upgradeToAndCall(_logic, _data, false);
    }

    /**
     * @dev Returns the current implementation address.
     */
    function _implementation() internal view virtual override returns (address impl) {
        return ERC1967Upgrade._getImplementation();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/Proxy.sol)

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overridden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overridden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeacon.sol";
import "../../interfaces/draft-IERC1822.sol";
import "../../utils/Address.sol";
import "../../utils/StorageSlot.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967Upgrade {
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlot.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822Proxiable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlot.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(Address.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            Address.isContract(IBeacon(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlot.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822Proxiable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2022 Aztec
pragma solidity >=0.8.4;

import {TransparentUpgradeableProxy} from '@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol';

contract ProxyDeployer {
    event ProxyDeployed(address logic, address admin, bytes32 salt, address proxy);

    constructor() {}

    function deployProxy(
        address _logic,
        address _admin,
        bytes memory _data,
        bytes32 _salt
    ) public returns (address) {
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy{salt: _salt}(_logic, _admin, _data);

        emit ProxyDeployed(_logic, _admin, _salt, address(proxy));

        return address(proxy);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import {TransparentUpgradeableProxy} from '@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol';
import {ProxyAdmin} from '@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol';

// SPDX-License-Identifier: Apache-2.0
// Copyright 2022 Aztec
pragma solidity >=0.8.4;

import {IDefiBridge} from './interfaces/IDefiBridge.sol';
import {AztecTypes} from './AztecTypes.sol';
import {TokenTransfers} from './libraries/TokenTransfers.sol';

contract DefiBridgeProxy {
    error OUTPUT_A_EXCEEDS_252_BITS(uint256 outputValue);
    error OUTPUT_B_EXCEEDS_252_BITS(uint256 outputValue);
    error ASYNC_NONZERO_OUTPUT_VALUES(uint256 outputValueA, uint256 outputValueB);
    error INSUFFICIENT_ETH_PAYMENT();

    /**
     * @dev Use interaction result data to pull tokens into DefiBridgeProxy
     * @param asset The AztecAsset being targetted
     * @param outputValue The claimed output value provided by the bridge
     * @param interactionNonce The defi interaction nonce of the interaction
     * @param bridgeContract Address of the defi bridge contract
     * @param ethPaymentsSlot The slot value of the `ethPayments` storage mapping in RollupProcessor.sol!
     * More details on ethPaymentsSlot are in the comments for the `convert` function
     */
    function recoverTokens(
        AztecTypes.AztecAsset memory asset,
        uint256 outputValue,
        uint256 interactionNonce,
        address bridgeContract,
        uint256 ethPaymentsSlot
    ) internal {
        if (outputValue == 0) {
            return;
        }
        if (asset.assetType == AztecTypes.AztecAssetType.ETH) {
            uint256 ethPayment;
            uint256 ethPaymentsSlotBase;
            assembly {
                mstore(0x00, interactionNonce)
                mstore(0x20, ethPaymentsSlot)
                ethPaymentsSlotBase := keccak256(0x00, 0x40)
                ethPayment := sload(ethPaymentsSlotBase) // ethPayment = ethPayments[interactionNonce]
            }
            if (outputValue > ethPayment) {
                revert INSUFFICIENT_ETH_PAYMENT();
            }
            assembly {
                sstore(ethPaymentsSlotBase, 0) // ethPayments[interactionNonce] = 0;
            }
        } else if (asset.assetType == AztecTypes.AztecAssetType.ERC20) {
            TokenTransfers.safeTransferFrom(asset.erc20Address, bridgeContract, address(this), outputValue);
        }
    }

    /**
     * @dev Convert input assets into output assets via calling a defi bridge contract
     * @param bridgeAddress Address of the defi bridge contract
     * @param inputAssetA First input asset
     * @param inputAssetB Second input asset. Is either VIRTUAL or NOT_USED (checked by RollupProcessor)
     * @param outputAssetA First output asset
     * @param outputAssetB Second output asset
     * @param totalInputValue The total amount of inputAssetA to be sent to the bridge
     * @param interactionNonce Integer that is unique for a given defi interaction
     * @param auxInputData Optional custom data to be sent to the bridge (defined in the L2 SNARK circuits when creating claim notes)
     * @param ethPaymentsSlot The slot value of the `ethPayments` storage mapping in RollupProcessor.sol!
     * @param rollupBeneficiary The address that should be payed any fees / subsidy for executing this bridge.

     * We assume this contract is called from the RollupProcessor via `delegateCall`,
     * if not... this contract behaviour is undefined! So don't do that.
     * The idea here is that, if the defi bridge has returned native ETH, they will do so via calling
     * `RollupProcessor.receiveEthPayment(uint256 interactionNonce)`.
     * To summarise the issue, we must solve for the following:
     * 1. We need to be able to read the `ethPayments` state variable to determine how much Eth has been sent (and reset it)
     * 2. We must encapsulate the entire defi interaction flow via a 'delegatecall' so that we can safely revert
     *    all token/eth transfers if the defi interaction fails, *without* throwing the entire rollup transaction
     * 3. We don't want to directly call `delegateCall` on RollupProcessor.sol to minimise the attack surface against delegatecall re-entrancy exploits
     *
     * Solution is to pass the ethPayments.slot storage slot in as a param during the delegateCall and update in assembly via `sstore`
     * We could achieve the same effect via getters/setters on the function, but that would be expensive as that would trigger additional `call` opcodes.
     * We could *also* just hard-code the slot value, but that is quite brittle as
     * any re-ordering of storage variables during development would require updating the hardcoded constant
     *
     * @return outputValueA outputvalueB isAsync
     * outputValueA = the number of outputAssetA tokens we must recover from the bridge
     * outputValueB = the number of outputAssetB tokens we must recover from the bridge
     * isAsync describes whether the defi interaction has instantly resolved, or if the interaction must be finalised in a future Eth block
     * if isAsync == true, outputValueA and outputValueB must both equal 0
     */
    function convert(
        address bridgeAddress,
        AztecTypes.AztecAsset memory inputAssetA,
        AztecTypes.AztecAsset memory inputAssetB,
        AztecTypes.AztecAsset memory outputAssetA,
        AztecTypes.AztecAsset memory outputAssetB,
        uint256 totalInputValue,
        uint256 interactionNonce,
        uint256 auxInputData, // (auxData)
        uint256 ethPaymentsSlot,
        address rollupBeneficiary
    )
        external
        returns (
            uint256 outputValueA,
            uint256 outputValueB,
            bool isAsync
        )
    {
        if (inputAssetA.assetType == AztecTypes.AztecAssetType.ERC20) {
            // Transfer totalInputValue to the bridge contract if erc20. ETH is sent on call to convert.
            TokenTransfers.safeTransferTo(inputAssetA.erc20Address, bridgeAddress, totalInputValue);
        }
        if (inputAssetB.assetType == AztecTypes.AztecAssetType.ERC20) {
            // Transfer totalInputValue to the bridge contract if erc20. ETH is sent on call to convert.
            TokenTransfers.safeTransferTo(inputAssetB.erc20Address, bridgeAddress, totalInputValue);
        }
        // Call bridge.convert(), which will return output values for the two output assets.
        // If input is ETH, send it along with call to convert.
        uint256 ethValue = (inputAssetA.assetType == AztecTypes.AztecAssetType.ETH ||
            inputAssetB.assetType == AztecTypes.AztecAssetType.ETH)
            ? totalInputValue
            : 0;
        (outputValueA, outputValueB, isAsync) = IDefiBridge(bridgeAddress).convert{value: ethValue}(
            inputAssetA,
            inputAssetB,
            outputAssetA,
            outputAssetB,
            totalInputValue,
            interactionNonce,
            uint64(auxInputData),
            rollupBeneficiary
        );

        if (isAsync) {
            if (outputValueA > 0 || outputValueB > 0) {
                revert ASYNC_NONZERO_OUTPUT_VALUES(outputValueA, outputValueB);
            }
        } else {
            address bridgeAddressCopy = bridgeAddress; // stack overflow workaround
            if (outputValueA >= (1 << 252)) {
                revert OUTPUT_A_EXCEEDS_252_BITS(outputValueA);
            }
            if (outputValueB >= (1 << 252)) {
                revert OUTPUT_B_EXCEEDS_252_BITS(outputValueB);
            }
            recoverTokens(outputAssetA, outputValueA, interactionNonce, bridgeAddressCopy, ethPaymentsSlot);
            recoverTokens(outputAssetB, outputValueB, interactionNonce, bridgeAddressCopy, ethPaymentsSlot);
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2022 Aztec
pragma solidity >=0.8.4;

import {Decoder} from '../Decoder.sol';
import {IVerifier} from '../interfaces/IVerifier.sol';

/**
 * TODO: Pretty sure this should all be removed and we should be testing decodeProof response directly.
 */
contract HashInputs is Decoder {
    IVerifier public verifier;
    error PUBLIC_INPUTS_HASH_VERIFICATION_FAILED(uint256, uint256);

    constructor(address _verifierAddress) {
        verifier = IVerifier(_verifierAddress);
    }

    function computePublicInputHash(
        bytes calldata /* encodedProofData */
    ) external view returns (bytes32) {
        decodeProof();
        return 0;
    }

    function verifyProofTest(
        bytes calldata /* encodedProofData */
    ) external view {
        (, , uint256 publicInputsHash) = decodeProof();
        uint256 broadcastedDataSize = ROLLUP_HEADER_LENGTH + 8; // add 8 bytes for two packed params at end of header
        bool proof_verified;
        assembly {
            /**
             * Validate correctness of zk proof.
             *
             * 1st Item is to format verifier calldata.
             **/

            // Our first input param `encodedProofData` contains the concatenation of
            // encoded 'broadcasted inputs' and the actual zk proof data.
            // (The `boadcasted inputs` is converted into a 32-byte SHA256 hash, which is
            // validated to equal the first public inputs of the zk proof. This is done in `Decoder.sol`).
            // We need to identify the location in calldata that points to the start of the zk proof data.

            // Step 1: compute size of zk proof data and its calldata pointer.
            /**
                Data layout for `bytes encodedProofData`...

                0x00 : 0x20 : length of array
                0x20 : 0x20 + header : root rollup header data
                0x20 + header : 0x24 + header : X, the length of encoded inner join-split public inputs
                0x24 + header : 0x24 + header + X : (inner join-split public inputs)
                0x24 + header + X : 0x28 + header + X : Y, the length of the zk proof data
                0x28 + header + X : 0x28 + haeder + X + Y : zk proof data

                We need to recover the numeric value of `0x28 + header + X` and `Y`
             **/
            // Begin by getting length of encoded inner join-split public inputs.
            // `calldataload(0x04)` points to start of bytes array. Add 0x24 to skip over length param and function signature.
            // The calldata param *after* the header is the length of the pub inputs array. However it is a packed 4-byte param.
            // To extract it, we subtract 28 bytes from the calldata pointer and mask off all but the 4 least significant bytes.
            let encodedInnerDataSize := and(
                calldataload(add(add(calldataload(0x04), 0x24), sub(ROLLUP_HEADER_LENGTH, 0x18))),
                0xffffffff
            )

            // broadcastedDataSize = inner join-split pubinput size + header size + 8 bytes (skip over zk proof length param)
            broadcastedDataSize := add(broadcastedDataSize, encodedInnerDataSize)

            // Compute zk proof data size by subtracting broadcastedDataSize from overall length of bytes encodedProofsData
            let zkProofDataSize := sub(calldataload(add(calldataload(0x04), 0x04)), broadcastedDataSize)

            // Compute calldata pointer to start of zk proof data by adding calldata offset to broadcastedDataSize
            // (+0x24 skips over function signature and numRealTxs param and length param of bytes encodedProofData)
            // add +4 for new param or not?
            let zkProofDataPtr := add(broadcastedDataSize, add(calldataload(0x04), 0x24))

            // Step 2: Format calldata for verifier contract call.

            // Get free memory pointer - we copy calldata into memory starting here
            let dataPtr := mload(0x40)

            // We call the function `verify(bytes,uint256)`
            // The function signature is 0xac318c5d
            // Calldata map is:
            // 0x00 - 0x04 : 0xac318c5d
            // 0x04 - 0x24 : 0x40 (number of bytes between 0x04 and the start of the `proofData` array at 0x44)
            // 0x24 - 0x44 : publicInputsHash
            // 0x44 - .... : proofData
            mstore8(dataPtr, 0xac)
            mstore8(add(dataPtr, 0x01), 0x31)
            mstore8(add(dataPtr, 0x02), 0x8c)
            mstore8(add(dataPtr, 0x03), 0x5d)
            mstore(add(dataPtr, 0x04), 0x40)
            mstore(add(dataPtr, 0x24), publicInputsHash)
            mstore(add(dataPtr, 0x44), zkProofDataSize) // length of zkProofData bytes array
            calldatacopy(add(dataPtr, 0x64), zkProofDataPtr, zkProofDataSize) // copy the zk proof data into memory

            // Step 3: Call our verifier contract. If does not return any values, but will throw an error if the proof is not valid
            // i.e. verified == false if proof is not valid
            proof_verified := staticcall(gas(), sload(verifier.slot), dataPtr, add(zkProofDataSize, 0x64), 0x00, 0x00)
        }

        if (!proof_verified) {
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2022 Aztec
pragma solidity >=0.8.4;
// gas count: 299,341 (includes 21,000 tx base cost, includes cost of 3 pub inputs. Cost of circuit without pub inputs is 298,312)

import {IVerifier} from '../interfaces/IVerifier.sol';
import {VerificationKey} from './keys/VerificationKey.sol';
import {StandardTypes} from './cryptography/StandardTypes.sol';

/**
 * @title Standard Plonk proof verification contract
 * @dev Top level Plonk proof verification contract, which allows Plonk proof to be verified
 *
 * Copyright 2022 Aztec
 *
 * Licensed under the GNU General Public License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */
contract StandardVerifier is IVerifier {
    // VERIFICATION KEY MEMORY LOCATIONS
    uint256 internal constant N_LOC =                                    0x200 + 0x00;
    uint256 internal constant NUM_INPUTS_LOC =                           0x200 + 0x20;
    uint256 internal constant OMEGA_LOC =                                0x200 + 0x40;
    uint256 internal constant DOMAIN_INVERSE_LOC =                       0x200 + 0x60;
    uint256 internal constant Q1_X_LOC =                                 0x200 + 0x80;
    uint256 internal constant Q1_Y_LOC =                                 0x200 + 0xa0;
    uint256 internal constant Q2_X_LOC =                                 0x200 + 0xc0;
    uint256 internal constant Q2_Y_LOC =                                 0x200 + 0xe0;
    uint256 internal constant Q3_X_LOC =                                 0x200 + 0x100;
    uint256 internal constant Q3_Y_LOC =                                 0x200 + 0x120;
    uint256 internal constant QM_X_LOC =                                 0x200 + 0x140;
    uint256 internal constant QM_Y_LOC =                                 0x200 + 0x160;
    uint256 internal constant QC_X_LOC =                                 0x200 + 0x180;
    uint256 internal constant QC_Y_LOC =                                 0x200 + 0x1a0;
    uint256 internal constant SIGMA1_X_LOC =                             0x200 + 0x1c0;
    uint256 internal constant SIGMA1_Y_LOC =                             0x200 + 0x1e0;
    uint256 internal constant SIGMA2_X_LOC =                             0x200 + 0x200;
    uint256 internal constant SIGMA2_Y_LOC =                             0x200 + 0x220;
    uint256 internal constant SIGMA3_X_LOC =                             0x200 + 0x240;
    uint256 internal constant SIGMA3_Y_LOC =                             0x200 + 0x260;
    uint256 internal constant CONTAINS_RECURSIVE_PROOF_LOC =             0x200 + 0x280;
    uint256 internal constant RECURSIVE_PROOF_PUBLIC_INPUT_INDICES_LOC = 0x200 + 0x2a0;
    uint256 internal constant G2X_X0_LOC =                               0x200 + 0x2c0;
    uint256 internal constant G2X_X1_LOC =                               0x200 + 0x2e0;
    uint256 internal constant G2X_Y0_LOC =                               0x200 + 0x300;
    uint256 internal constant G2X_Y1_LOC =                               0x200 + 0x320;
    // 26

    // ### PROOF DATA MEMORY LOCATIONS
    uint256 internal constant W1_X_LOC =                                 0x200 + 0x340 + 0x00;
    uint256 internal constant W1_Y_LOC =                                 0x200 + 0x340 + 0x20;
    uint256 internal constant W2_X_LOC =                                 0x200 + 0x340 + 0x40;
    uint256 internal constant W2_Y_LOC =                                 0x200 + 0x340 + 0x60;
    uint256 internal constant W3_X_LOC =                                 0x200 + 0x340 + 0x80;
    uint256 internal constant W3_Y_LOC =                                 0x200 + 0x340 + 0xa0;
    uint256 internal constant Z_X_LOC =                                  0x200 + 0x340 + 0xc0;
    uint256 internal constant Z_Y_LOC =                                  0x200 + 0x340 + 0xe0;
    uint256 internal constant T1_X_LOC =                                 0x200 + 0x340 + 0x100;
    uint256 internal constant T1_Y_LOC =                                 0x200 + 0x340 + 0x120;
    uint256 internal constant T2_X_LOC =                                 0x200 + 0x340 + 0x140;
    uint256 internal constant T2_Y_LOC =                                 0x200 + 0x340 + 0x160;
    uint256 internal constant T3_X_LOC =                                 0x200 + 0x340 + 0x180;
    uint256 internal constant T3_Y_LOC =                                 0x200 + 0x340 + 0x1a0;
    uint256 internal constant W1_EVAL_LOC =                              0x200 + 0x340 + 0x1c0;
    uint256 internal constant W2_EVAL_LOC =                              0x200 + 0x340 + 0x1e0;
    uint256 internal constant W3_EVAL_LOC =                              0x200 + 0x340 + 0x200;
    uint256 internal constant SIGMA1_EVAL_LOC =                          0x200 + 0x340 + 0x220;
    uint256 internal constant SIGMA2_EVAL_LOC =                          0x200 + 0x340 + 0x240;
    uint256 internal constant Z_OMEGA_EVAL_LOC =                         0x200 + 0x340 + 0x260;
    uint256 internal constant PI_Z_X_LOC =                               0x200 + 0x340 + 0x280;
    uint256 internal constant PI_Z_Y_LOC =                               0x200 + 0x340 + 0x2a0;
    uint256 internal constant PI_Z_OMEGA_X_LOC =                         0x200 + 0x340 + 0x2c0;
    uint256 internal constant PI_Z_OMEGA_Y_LOC =                         0x200 + 0x340 + 0x2e0;
    // 25

    // ### CHALLENGES MEMORY OFFSETS
    uint256 internal constant C_BETA_LOC =                               0x200 + 0x340 + 0x300 + 0x00;
    uint256 internal constant C_GAMMA_LOC =                              0x200 + 0x340 + 0x300 + 0x20;
    uint256 internal constant C_ALPHA_LOC =                              0x200 + 0x340 + 0x300 + 0x40;
    uint256 internal constant C_ARITHMETIC_ALPHA_LOC =                   0x200 + 0x340 + 0x300 + 0x60;
    uint256 internal constant C_ZETA_LOC =                               0x200 + 0x340 + 0x300 + 0x80;
    uint256 internal constant C_CURRENT_LOC =                            0x200 + 0x340 + 0x300 + 0xa0;
    uint256 internal constant C_V0_LOC =                                 0x200 + 0x340 + 0x300 + 0xc0;
    uint256 internal constant C_V1_LOC =                                 0x200 + 0x340 + 0x300 + 0xe0;
    uint256 internal constant C_V2_LOC =                                 0x200 + 0x340 + 0x300 + 0x100;
    uint256 internal constant C_V3_LOC =                                 0x200 + 0x340 + 0x300 + 0x120;
    uint256 internal constant C_V4_LOC =                                 0x200 + 0x340 + 0x300 + 0x140;
    uint256 internal constant C_V5_LOC =                                 0x200 + 0x340 + 0x300 + 0x160;
    uint256 internal constant C_U_LOC =                                  0x200 + 0x340 + 0x300 + 0x180;
    // 13

    // ### LOCAL VARIABLES MEMORY OFFSETS
    uint256 internal constant DELTA_NUMERATOR_LOC =                      0x200 + 0x340 + 0x300 + 0x1a0 + 0x00;
    uint256 internal constant DELTA_DENOMINATOR_LOC =                    0x200 + 0x340 + 0x300 + 0x1a0 + 0x20;
    uint256 internal constant ZETA_POW_N_LOC =                           0x200 + 0x340 + 0x300 + 0x1a0 + 0x40;
    uint256 internal constant PUBLIC_INPUT_DELTA_LOC =                   0x200 + 0x340 + 0x300 + 0x1a0 + 0x60;
    uint256 internal constant ZERO_POLY_LOC =                            0x200 + 0x340 + 0x300 + 0x1a0 + 0x80;
    uint256 internal constant L_START_LOC =                              0x200 + 0x340 + 0x300 + 0x1a0 + 0xa0;
    uint256 internal constant L_END_LOC =                                0x200 + 0x340 + 0x300 + 0x1a0 + 0xc0;
    uint256 internal constant R_ZERO_EVAL_LOC =                          0x200 + 0x340 + 0x300 + 0x1a0 + 0xe0;
    uint256 internal constant ACCUMULATOR_X_LOC =                        0x200 + 0x340 + 0x300 + 0x1a0 + 0x100;
    uint256 internal constant ACCUMULATOR_Y_LOC =                        0x200 + 0x340 + 0x300 + 0x1a0 + 0x120;
    uint256 internal constant ACCUMULATOR2_X_LOC =                       0x200 + 0x340 + 0x300 + 0x1a0 + 0x140;
    uint256 internal constant ACCUMULATOR2_Y_LOC =                       0x200 + 0x340 + 0x300 + 0x1a0 + 0x160;
    uint256 internal constant PAIRING_LHS_X_LOC =                        0x200 + 0x340 + 0x300 + 0x1a0 + 0x180;
    uint256 internal constant PAIRING_LHS_Y_LOC =                        0x200 + 0x340 + 0x300 + 0x1a0 + 0x1a0;
    uint256 internal constant PAIRING_RHS_X_LOC =                        0x200 + 0x340 + 0x300 + 0x1a0 + 0x1c0;
    uint256 internal constant PAIRING_RHS_Y_LOC =                        0x200 + 0x340 + 0x300 + 0x1a0 + 0x1e0;
    // 21

    // ### SUCCESS FLAG MEMORY LOCATIONS
    uint256 internal constant GRAND_PRODUCT_SUCCESS_FLAG =               0x200 + 0x340 + 0x300 + 0x1a0 + 0x200 + 0x00;
    uint256 internal constant ARITHMETIC_TERM_SUCCESS_FLAG =             0x200 + 0x340 + 0x300 + 0x1a0 + 0x200 + 0x20;
    uint256 internal constant BATCH_OPENING_SUCCESS_FLAG =               0x200 + 0x340 + 0x300 + 0x1a0 + 0x200 + 0x40;
    uint256 internal constant OPENING_COMMITMENT_SUCCESS_FLAG =          0x200 + 0x340 + 0x300 + 0x1a0 + 0x200 + 0x60;
    uint256 internal constant PAIRING_PREAMBLE_SUCCESS_FLAG =            0x200 + 0x340 + 0x300 + 0x1a0 + 0x200 + 0x80;
    uint256 internal constant PAIRING_SUCCESS_FLAG =                     0x200 + 0x340 + 0x300 + 0x1a0 + 0x200 + 0xa0;
    uint256 internal constant RESULT_FLAG =                              0x200 + 0x340 + 0x300 + 0x1a0 + 0x200 + 0xc0;
    // 7

    // misc stuff
    uint256 internal constant OMEGA_INVERSE_LOC = 0x200 + 0x340 + 0x300 + 0x1a0 + 0x200 + 0xe0;
    uint256 internal constant C_ALPHA_SQR_LOC = 0x200 + 0x340 + 0x300 + 0x1a0 + 0x200 + 0xe0 + 0x20;
    // 3

    // ### RECURSION VARIABLE MEMORY LOCATIONS
    uint256 internal constant RECURSIVE_P1_X_LOC = 0x200 + 0x340 + 0x300 + 0x1a0 + 0x200 + 0xe0 + 0x40;
    uint256 internal constant RECURSIVE_P1_Y_LOC = 0x200 + 0x340 + 0x300 + 0x1a0 + 0x200 + 0xe0 + 0x60;
    uint256 internal constant RECURSIVE_P2_X_LOC = 0x200 + 0x340 + 0x300 + 0x1a0 + 0x200 + 0xe0 + 0x80;
    uint256 internal constant RECURSIVE_P2_Y_LOC = 0x200 + 0x340 + 0x300 + 0x1a0 + 0x200 + 0xe0 + 0xa0;

    uint256 internal constant PUBLIC_INPUTS_HASH_LOCATION = 0x200 + 0x340 + 0x300 + 0x1a0 + 0x200 + 0xe0 + 0xc0;

    error PUBLIC_INPUTS_HASH_VERIFICATION_FAILED(uint256, uint256);
    /**
     * @dev Verify a Plonk proof
     * @param - array of serialized proof data
     * @param - public input hash as computed from the broadcast data
     */
    function verify(bytes calldata, uint256 public_inputs_hash) external view override returns (bool) {
        // validate the correctness of the public inputs hash
        {
            bool hash_matches_input;
            uint256 recovered_hash;
            assembly {
                recovered_hash := calldataload(add(calldataload(0x04), 0x24))
                hash_matches_input := eq(recovered_hash, public_inputs_hash)
            }
            if (!hash_matches_input)
            {
                revert PUBLIC_INPUTS_HASH_VERIFICATION_FAILED(public_inputs_hash, recovered_hash);
            }
        }

        StandardTypes.VerificationKey memory vk = VerificationKey.get_verification_key();

        assembly {
            /**
             * LOAD VKEY
             * TODO REPLACE THIS WITH A CONTRACT CALL
             */
            {
                mstore(N_LOC, mload(vk))
                mstore(NUM_INPUTS_LOC, mload(add(vk, 0x20)))
                mstore(OMEGA_LOC,           mload(add(vk, 0x40)))
                mstore(DOMAIN_INVERSE_LOC,  mload(add(vk, 0x60)))
                mstore(OMEGA_INVERSE_LOC,   mload(add(vk, 0x80)))
                mstore(Q1_X_LOC,            mload(mload(add(vk, 0xa0))))
                mstore(Q1_Y_LOC,            mload(add(mload(add(vk, 0xa0)), 0x20)))
                mstore(Q2_X_LOC,            mload(mload(add(vk, 0xc0))))
                mstore(Q2_Y_LOC,            mload(add(mload(add(vk, 0xc0)), 0x20)))
                mstore(Q3_X_LOC,            mload(mload(add(vk, 0xe0))))
                mstore(Q3_Y_LOC,            mload(add(mload(add(vk, 0xe0)), 0x20)))
                mstore(QM_X_LOC,            mload(mload(add(vk, 0x100))))
                mstore(QM_Y_LOC,            mload(add(mload(add(vk, 0x100)), 0x20)))
                mstore(QC_X_LOC,            mload(mload(add(vk, 0x120))))
                mstore(QC_Y_LOC,            mload(add(mload(add(vk, 0x120)), 0x20)))
                mstore(SIGMA1_X_LOC,        mload(mload(add(vk, 0x140))))
                mstore(SIGMA1_Y_LOC,        mload(add(mload(add(vk, 0x140)), 0x20)))
                mstore(SIGMA2_X_LOC,        mload(mload(add(vk, 0x160))))
                mstore(SIGMA2_Y_LOC,        mload(add(mload(add(vk, 0x160)), 0x20)))
                mstore(SIGMA3_X_LOC,        mload(mload(add(vk, 0x180))))
                mstore(SIGMA3_Y_LOC,        mload(add(mload(add(vk, 0x180)), 0x20)))
                mstore(CONTAINS_RECURSIVE_PROOF_LOC, mload(add(vk, 0x1a0)))
                mstore(RECURSIVE_PROOF_PUBLIC_INPUT_INDICES_LOC, mload(add(vk, 0x1c0)))
                mstore(G2X_X0_LOC, 0x260e01b251f6f1c7e7ff4e580791dee8ea51d87a358e038b4efe30fac09383c1)
                mstore(G2X_X1_LOC, 0x0118c4d5b837bcc2bc89b5b398b5974e9f5944073b32078b7e231fec938883b0)
                mstore(G2X_Y0_LOC, 0x04fc6369f7110fe3d25156c1bb9a72859cf2a04641f99ba4ee413c80da6a5fe4)
                mstore(G2X_Y1_LOC, 0x22febda3c0c0632a56475b4214e5615e11e6dd3f96e6cea2854a87d4dacc5e55)
            }

            let q := 21888242871839275222246405745257275088696311157297823662689037894645226208583 // EC group order
            let p := 21888242871839275222246405745257275088548364400416034343698204186575808495617 // Prime field order


            /**
             * LOAD PROOF FROM CALLDATA
             */
            {
                let data_ptr := add(calldataload(0x04), 0x24)
                if mload(CONTAINS_RECURSIVE_PROOF_LOC)
                {
                    let index_counter := add(mul(mload(RECURSIVE_PROOF_PUBLIC_INPUT_INDICES_LOC), 32), data_ptr)

                    let x0 := calldataload(index_counter)
                    x0 := add(x0, shl(68, calldataload(add(index_counter, 0x20))))
                    x0 := add(x0, shl(136, calldataload(add(index_counter, 0x40))))
                    x0 := add(x0, shl(204, calldataload(add(index_counter, 0x60))))
                    let y0 := calldataload(add(index_counter, 0x80))
                    y0 := add(y0, shl(68, calldataload(add(index_counter, 0xa0))))
                    y0 := add(y0, shl(136, calldataload(add(index_counter, 0xc0))))
                    y0 := add(y0, shl(204, calldataload(add(index_counter, 0xe0))))
                    let x1 := calldataload(add(index_counter, 0x100))
                    x1 := add(x1, shl(68, calldataload(add(index_counter, 0x120))))
                    x1 := add(x1, shl(136, calldataload(add(index_counter, 0x140))))
                    x1 := add(x1, shl(204, calldataload(add(index_counter, 0x160))))
                    let y1 := calldataload(add(index_counter, 0x180))
                    y1 := add(y1, shl(68, calldataload(add(index_counter, 0x1a0))))
                    y1 := add(y1, shl(136, calldataload(add(index_counter, 0x1c0))))
                    y1 := add(y1, shl(204, calldataload(add(index_counter, 0x1e0))))
                    mstore(RECURSIVE_P1_X_LOC, x0)
                    mstore(RECURSIVE_P1_Y_LOC, y0)
                    mstore(RECURSIVE_P2_X_LOC, x1)
                    mstore(RECURSIVE_P2_Y_LOC, y1)

                    // validate these are valid bn128 G1 points
                    if iszero(and(
                        and(lt(x0, q), lt(x1, q)),
                        and(lt(y0, q), lt(y1, q))
                    )) {
                        revert(0x00, 0x00)
                    }
                }

            let public_input_byte_length := mul(mload(NUM_INPUTS_LOC), 32)
            data_ptr := add(data_ptr, public_input_byte_length)


            mstore(W1_X_LOC, mod(calldataload(add(data_ptr, 0x20)), q))
            mstore(W1_Y_LOC, mod(calldataload(data_ptr), q))
            mstore(W2_X_LOC, mod(calldataload(add(data_ptr, 0x60)), q))
            mstore(W2_Y_LOC, mod(calldataload(add(data_ptr, 0x40)), q))
            mstore(W3_X_LOC, mod(calldataload(add(data_ptr, 0xa0)), q))
            mstore(W3_Y_LOC, mod(calldataload(add(data_ptr, 0x80)), q))
            mstore(Z_X_LOC, mod(calldataload(add(data_ptr, 0xe0)), q))
            mstore(Z_Y_LOC, mod(calldataload(add(data_ptr, 0xc0)), q))
            mstore(T1_X_LOC, mod(calldataload(add(data_ptr, 0x120)), q))
            mstore(T1_Y_LOC, mod(calldataload(add(data_ptr, 0x100)), q))
            mstore(T2_X_LOC, mod(calldataload(add(data_ptr, 0x160)), q))
            mstore(T2_Y_LOC, mod(calldataload(add(data_ptr, 0x140)), q))
            mstore(T3_X_LOC, mod(calldataload(add(data_ptr, 0x1a0)), q))
            mstore(T3_Y_LOC, mod(calldataload(add(data_ptr, 0x180)), q))
            mstore(W1_EVAL_LOC, mod(calldataload(add(data_ptr, 0x1c0)), p))
            mstore(W2_EVAL_LOC, mod(calldataload(add(data_ptr, 0x1e0)), p))
            mstore(W3_EVAL_LOC, mod(calldataload(add(data_ptr, 0x200)), p))
            mstore(SIGMA1_EVAL_LOC, mod(calldataload(add(data_ptr, 0x220)), p))
            mstore(SIGMA2_EVAL_LOC, mod(calldataload(add(data_ptr, 0x240)), p))
            mstore(Z_OMEGA_EVAL_LOC, mod(calldataload(add(data_ptr, 0x260)), p))
            mstore(PI_Z_X_LOC, mod(calldataload(add(data_ptr, 0x2a0)), q))
            mstore(PI_Z_Y_LOC, mod(calldataload(add(data_ptr, 0x280)), q))
            mstore(PI_Z_OMEGA_X_LOC, mod(calldataload(add(data_ptr, 0x2e0)), q))
            mstore(PI_Z_OMEGA_Y_LOC, mod(calldataload(add(data_ptr, 0x2c0)), q))
            }

            {
            /**
             * Generate initial challenge
             **/

            mstore(0x00, shl(224, mload(N_LOC)))
            mstore(0x04, shl(224, mload(NUM_INPUTS_LOC)))
            let challenge := keccak256(0x00, 0x08)

            /**
             * Generate beta, gamma challenges
             */
            mstore(PUBLIC_INPUTS_HASH_LOCATION, challenge)
            let inputs_start := add(calldataload(0x04), 0x24)
            let num_calldata_bytes := add(0xc0, mul(mload(NUM_INPUTS_LOC), 0x20))
            calldatacopy(add(PUBLIC_INPUTS_HASH_LOCATION, 0x20), inputs_start, num_calldata_bytes)

            challenge := keccak256(PUBLIC_INPUTS_HASH_LOCATION, add(num_calldata_bytes, 0x20))

            mstore(C_BETA_LOC, mod(challenge, p))

            mstore(0x00, challenge)
            mstore8(0x20, 0x01)
            challenge := keccak256(0x00, 0x21)
            mstore(C_GAMMA_LOC, mod(challenge, p))

            /**
             * Generate alpha challenge
             */
            mstore(0x00, challenge)
            mstore(0x20, mload(Z_Y_LOC))
            mstore(0x40, mload(Z_X_LOC))
            challenge := keccak256(0x00, 0x60)
            mstore(C_ALPHA_LOC, mod(challenge, p))
            /**
             * Generate zeta challenge
             */
            mstore(0x00, challenge)
            mstore(0x20, mload(T1_Y_LOC))
            mstore(0x40, mload(T1_X_LOC))
            mstore(0x60, mload(T2_Y_LOC))
            mstore(0x80, mload(T2_X_LOC))
            mstore(0xa0, mload(T3_Y_LOC))
            mstore(0xc0, mload(T3_X_LOC))
            challenge := keccak256(0x00, 0xe0)

            mstore(C_ZETA_LOC, mod(challenge, p))
            mstore(C_CURRENT_LOC, challenge)
            }

            /**
             * EVALUATE FIELD OPERATIONS
             */

            /**
             * COMPUTE PUBLIC INPUT DELTA
             */
            {
                let gamma := mload(C_GAMMA_LOC)
                let work_root := mload(OMEGA_LOC)
                let endpoint := sub(mul(mload(NUM_INPUTS_LOC), 0x20), 0x20)
                let public_inputs
                let root_1 := mload(C_BETA_LOC)
                let root_2 := root_1
                let numerator_value := 1
                let denominator_value := 1

                let p_clone := p // move p to the front of the stack
                let valid := true

                root_1 := mulmod(root_1, 0x05, p_clone) // k1.beta
                root_2 := mulmod(root_2, 0x07, p_clone) // 0x05 + 0x07 = 0x0c = external coset generator

                public_inputs := add(calldataload(0x04), 0x24)
                endpoint := add(endpoint, public_inputs)

                for {} lt(public_inputs, endpoint) {}
                {
                    let input0 := calldataload(public_inputs)
                    let N0 := add(root_1, add(input0, gamma))
                    let D0 := add(root_2, N0) // 4x overloaded

                    root_1 := mulmod(root_1, work_root, p_clone)
                    root_2 := mulmod(root_2, work_root, p_clone)

                    let input1 := calldataload(add(public_inputs, 0x20))
                    let N1 := add(root_1, add(input1, gamma))

                    denominator_value := mulmod(mulmod(D0, denominator_value, p_clone), add(N1, root_2), p_clone)
                    numerator_value := mulmod(mulmod(N1, N0, p_clone), numerator_value, p_clone)

                    root_1 := mulmod(root_1, work_root, p_clone)
                    root_2 := mulmod(root_2, work_root, p_clone)

                    valid := and(valid, and(lt(input0, p_clone), lt(input1, p_clone)))
                    public_inputs := add(public_inputs, 0x40)

                    // validate public inputs are field elements (i.e. < p)
                    if iszero(and(lt(input0, p), lt(input1, p)))
                    {
                        revert(0x00, 0x00)
                    }
                }

                endpoint := add(endpoint, 0x20)
                for {} lt(public_inputs, endpoint) { public_inputs := add(public_inputs, 0x20) }
                {
                    let input0 := calldataload(public_inputs)

                    // validate public inputs are field elements (i.e. < p)
                    if iszero(lt(input0, p))
                    {
                        revert(0x00, 0x00)
                    }
        
                    valid := and(valid, lt(input0, p_clone))
                    let T0 := addmod(input0, gamma, p_clone)
                    numerator_value := mulmod(
                        numerator_value,
                        add(root_1, T0), // 0x05 = coset_generator0
                        p
                    )
                    denominator_value := mulmod(
                        denominator_value,
                        add(add(root_1, root_2), T0), // 0x0c = coset_generator7
                        p
                    )
                    root_1 := mulmod(root_1, work_root, p_clone)
                    root_2 := mulmod(root_2, work_root, p_clone)
                }

                mstore(DELTA_NUMERATOR_LOC, numerator_value)
                mstore(DELTA_DENOMINATOR_LOC, denominator_value)
            }

            /**
             * Compute lagrange poly and vanishing poly fractions
             */
            {
                let zeta := mload(C_ZETA_LOC)

                // compute zeta^n, where n is a power of 2
                let vanishing_numerator := zeta
                {
                    // pow_small
                    let exponent := mload(N_LOC)
                    let count := 1
                    for {} lt(count, exponent) { count := add(count, count) }
                    {
                        vanishing_numerator := mulmod(vanishing_numerator, vanishing_numerator, p)
                    }
                }
                mstore(ZETA_POW_N_LOC, vanishing_numerator)
                vanishing_numerator := addmod(vanishing_numerator, sub(p, 1), p)

                let accumulating_root := mload(OMEGA_INVERSE_LOC)
                let work_root := sub(p, accumulating_root)
                let domain_inverse := mload(DOMAIN_INVERSE_LOC)

                let vanishing_denominator := addmod(zeta, work_root, p)
                work_root := mulmod(work_root, accumulating_root, p)
                vanishing_denominator := mulmod(vanishing_denominator, addmod(zeta, work_root, p), p)
                work_root := mulmod(work_root, accumulating_root, p)
                vanishing_denominator := mulmod(vanishing_denominator, addmod(zeta, work_root, p), p)
                vanishing_denominator := mulmod(vanishing_denominator, addmod(zeta, mulmod(work_root, accumulating_root, p), p), p)

                work_root := mload(OMEGA_LOC)

                let lagrange_numerator := mulmod(vanishing_numerator, domain_inverse, p)
                let l_start_denominator := addmod(zeta, sub(p, 1), p)

                // l_end_denominator term contains a term \omega^5 to cut out 5 roots of unity from vanishing poly
                accumulating_root := mulmod(work_root, work_root, p)

                let l_end_denominator := addmod(
                    mulmod(
                        mulmod(
                            mulmod(accumulating_root, accumulating_root, p),
                            work_root, p
                        ),
                        zeta, p
                    ),
                    sub(p, 1), p
                )

            /**
             * Compute inversions using Montgomery's batch inversion trick
             */
                let accumulator := mload(DELTA_DENOMINATOR_LOC)
                let t0 := accumulator
                accumulator := mulmod(accumulator, vanishing_denominator, p)
                let t1 := accumulator
                accumulator := mulmod(accumulator, l_start_denominator, p)
                let t2 := accumulator
                {
                    mstore(0, 0x20)
                    mstore(0x20, 0x20)
                    mstore(0x40, 0x20)
                    mstore(0x60, mulmod(accumulator, l_end_denominator, p))
                    mstore(0x80, sub(p, 2))
                    mstore(0xa0, p)
                    if iszero(staticcall(gas(), 0x05, 0x00, 0xc0, 0x00, 0x20))
                    {
                        mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                        mstore(0x04, 0x20)
                        mstore(0x24, 32)
                        mstore(0x44, "PROOF_VERIFICATION_FAILED_TYPE_1")
                        revert(0x00, 0x64)
                    }
                    accumulator := mload(0x00)
                }

                t2 := mulmod(accumulator, t2, p)
                accumulator := mulmod(accumulator, l_end_denominator, p)

                t1 := mulmod(accumulator, t1, p)
                accumulator := mulmod(accumulator, l_start_denominator, p)

                t0 := mulmod(accumulator, t0, p)
                accumulator := mulmod(accumulator, vanishing_denominator, p)

                accumulator := mulmod(mulmod(accumulator, accumulator, p), mload(DELTA_DENOMINATOR_LOC), p)

                mstore(PUBLIC_INPUT_DELTA_LOC, mulmod(mload(DELTA_NUMERATOR_LOC), accumulator, p))
                mstore(ZERO_POLY_LOC, mulmod(vanishing_numerator, t0, p))
                mstore(L_START_LOC, mulmod(lagrange_numerator, t1, p))
                mstore(L_END_LOC, mulmod(lagrange_numerator, t2, p))
            }

            /**
             * COMPUTE CONSTANT TERM (r_0) OF LINEARISATION POLYNOMIAL
             */
            {
                let alpha := mload(C_ALPHA_LOC)
                let beta := mload(C_BETA_LOC)
                let gamma := mload(C_GAMMA_LOC)
                let r_0 := sub(p,
                    mulmod(
                        mulmod(
                            mulmod(
                                add(add(mload(W1_EVAL_LOC), gamma), mulmod(beta, mload(SIGMA1_EVAL_LOC), p)),
                                add(add(mload(W2_EVAL_LOC), gamma), mulmod(beta, mload(SIGMA2_EVAL_LOC), p)),
                                p
                            ),
                            add(mload(W3_EVAL_LOC), gamma),
                            p
                        ),
                        mload(Z_OMEGA_EVAL_LOC),
                        p
                    )
                )
                // r_0 = -(ā + βs̄_σ1 + γ)( b̄ + βs̄_σ2 + γ)(c̄ + γ)z̄_ω
                let alpha_sqr := mulmod(alpha, alpha, p)
                mstore(C_ALPHA_SQR_LOC, alpha_sqr)
                mstore(C_ARITHMETIC_ALPHA_LOC, mulmod(alpha_sqr, alpha_sqr, p))

                mstore(R_ZERO_EVAL_LOC,
                            mulmod(
                                addmod(
                                    addmod(r_0, sub(p, mulmod(mload(L_START_LOC), alpha_sqr, p)), p),
                                    mulmod(
                                        mulmod(mload(L_END_LOC), alpha, p),
                                        addmod(mload(Z_OMEGA_EVAL_LOC), sub(p, mload(PUBLIC_INPUT_DELTA_LOC)), p), p
                                    ), p
                                ),
                                alpha, p
                            )
                        )
            }


            /**
             * GENERATE NU AND SEPARATOR CHALLENGES
             */
            {
                let current_challenge := mload(C_CURRENT_LOC)
                // get a calldata pointer that points to the start of the data we want to copy
                let calldata_ptr := add(calldataload(0x04), 0x24)
                // skip over the public inputs
                calldata_ptr := add(calldata_ptr, mul(mload(NUM_INPUTS_LOC), 0x20))
                // There are SEVEN G1 group elements added into the transcript in the `beta` round, that we need to skip over
                // W1, W2, W3 (W4), Z, T1, T2, T3, (T4)
                calldata_ptr := add(calldata_ptr, 0x1c0) // 7 * 0x40 = 0x1c0

                mstore(0x00, current_challenge)
                calldatacopy(0x20, calldata_ptr, 0xc0) // 6 * 0x20 = 0xc0
                let challenge := keccak256(0x00, 0xe0) // hash length = 0xe0 (0x20 + num field elements), we include the previous challenge in the hash

                mstore(C_V0_LOC, mod(challenge, p))

                mstore(0x00, challenge)
                mstore8(0x20, 0x01)
                mstore(C_V1_LOC, mod(keccak256(0x00, 0x21), p))

                mstore8(0x20, 0x02)
                mstore(C_V2_LOC, mod(keccak256(0x00, 0x21), p))

                mstore8(0x20, 0x03)
                mstore(C_V3_LOC, mod(keccak256(0x00, 0x21), p))

                mstore8(0x20, 0x04)
                mstore(C_V4_LOC, mod(keccak256(0x00, 0x21), p))

                mstore8(0x20, 0x05)
                challenge := keccak256(0x00, 0x21)
                mstore(C_V5_LOC, mod(challenge, p))

                // separator
                mstore(0x00, challenge)
                mstore(0x20, mload(PI_Z_Y_LOC))
                mstore(0x40, mload(PI_Z_X_LOC))
                mstore(0x60, mload(PI_Z_OMEGA_Y_LOC))
                mstore(0x80, mload(PI_Z_OMEGA_X_LOC))

                mstore(C_U_LOC, mod(keccak256(0x00, 0xa0), p))
            }

            // mstore(C_ALPHA_BASE_LOC, mload(C_ALPHA_LOC))

            /**
             * COMPUTE LINEARISED OPENING TERMS
             */
            {
                // /**
                //  * COMPUTE GRAND PRODUCT OPENING GROUP ELEMENT
                //  */
                let beta := mload(C_BETA_LOC)
                let zeta := mload(C_ZETA_LOC)
                let gamma := mload(C_GAMMA_LOC)
                let alpha := mload(C_ALPHA_LOC)
                let beta_zeta := mulmod(beta, zeta, p)

                let witness_term := addmod(mload(W1_EVAL_LOC), gamma, p)
                let partial_grand_product := addmod(beta_zeta, witness_term, p)
                let sigma_multiplier := addmod(mulmod(mload(SIGMA1_EVAL_LOC), beta, p), witness_term, p)
                witness_term := addmod(mload(W2_EVAL_LOC), gamma, p)
                sigma_multiplier := mulmod(sigma_multiplier, addmod(mulmod(mload(SIGMA2_EVAL_LOC), beta, p), witness_term, p), p)
                let k1_beta_zeta := mulmod(0x05, beta_zeta, p)
                //  partial_grand_product = mulmod( mulmod( partial_grand_product, w2 + k1.beta.zeta + gamma , p), k2.beta.zeta + gamma + w3, p)
                partial_grand_product := mulmod(
                    mulmod(
                        partial_grand_product,
                        addmod(k1_beta_zeta, witness_term, p), // w2 + k1.beta.zeta + gamma
                        p
                    ),
                    addmod(addmod(add(k1_beta_zeta, beta_zeta), gamma, p), mload(W3_EVAL_LOC), p), // k2.beta.zeta + gamma + w3 where k2 = k1+1
                    p
                )


                let linear_challenge := alpha // Owing to the simplified Plonk, nu =1, linear_challenge = nu * alpha = alpha


                mstore(0x00, mload(SIGMA3_X_LOC))
                mstore(0x20, mload(SIGMA3_Y_LOC))
                mstore(0x40, mulmod(
                    mulmod(
                        sub(p, mulmod(sigma_multiplier, mload(Z_OMEGA_EVAL_LOC), p)),
                        beta,
                        p
                    ),
                    linear_challenge,
                    p
                ))

                // Validate Z
                let success
                {
                    let x := mload(Z_X_LOC)
                    let y := mload(Z_Y_LOC)
                    let xx := mulmod(x, x, q)
                    success := eq(mulmod(y, y, q), addmod(mulmod(x, xx, q), 3, q))
                    mstore(0x60, x)
                    mstore(0x80, y)
                }
                mstore(0xa0, addmod(
                    mulmod(
                        addmod(partial_grand_product, mulmod(mload(L_START_LOC), mload(C_ALPHA_SQR_LOC), p), p),
                        linear_challenge,
                        p),
                    mload(C_U_LOC),
                    p
                ))
            // 0x00 = SIGMA3_X_LOC,
            // 0x20 = SIGMA3_Y_LOC,
            // 0x40 = −(ā + βs̄_σ1 + γ)( b̄ + βs̄_σ2 + γ)αβz̄_ω,
            // 0x60 = Z_X_LOC,
            // 0x80 = Z_Y_LOC,
            // 0xa0 = (ā + βz + γ)( b̄ + βk_1 z + γ)(c̄ + βk_2 z + γ)α + L_1(z)α^3 + u
                success := and(success, and(
                    staticcall(gas(), 6, ACCUMULATOR_X_LOC, 0x80, ACCUMULATOR_X_LOC, 0x40),
                    // Why ACCUMULATOR_X_LOC := ACCUMULATOR_X_LOC + ACCUMULATOR2_X_LOC? Inner parenthesis is executed before?
                    and(
                        staticcall(gas(), 7, 0x60, 0x60, ACCUMULATOR_X_LOC, 0x40),
                        // [ACCUMULATOR_X_LOC, ACCUMULATOR_X_LOC + 0x40) = ((ā + βz + γ)( b̄ + βk_1 z + γ)(c̄ + βk_2 z + γ)α + L_1(z)α^3 + u)*[z]_1
                        staticcall(gas(), 7, 0x00, 0x60, ACCUMULATOR2_X_LOC, 0x40)
                        // [ACCUMULATOR2_X_LOC, ACCUMULATOR2_X_LOC + 0x40) = −(ā + βs̄_σ1 + γ)( b̄ + βs̄_σ2 + γ)αβz̄_ω * [s_σ3]_1
                    )
                ))

                mstore(GRAND_PRODUCT_SUCCESS_FLAG, success)

            }

            /**
             * COMPUTE ARITHMETIC SELECTOR OPENING GROUP ELEMENT
             */
            {
                let linear_challenge := mload(C_ARITHMETIC_ALPHA_LOC) // Owing to simplified Plonk, nu = 1,  linear_challenge = C_ARITHMETIC_ALPHA (= alpha^4)

                let t1 := mulmod(mload(W1_EVAL_LOC), linear_challenge, p) // reuse this for QM scalar multiplier
                // Q1
                mstore(0x00, mload(Q1_X_LOC))
                mstore(0x20, mload(Q1_Y_LOC))
                mstore(0x40, t1)

                // add Q1 scalar mul into grand product scalar mul
                // Observe that ACCUMULATOR_X_LOC and ACCUMULATOR2_X_LOC are 0x40 bytes apart. Below, ACCUMULATOR2_X_LOC
                // captures new terms Q1, Q2, and so on and they get accumulated to ACCUMULATOR_X_LOC
                let success := and(
                    staticcall(gas(), 6, ACCUMULATOR_X_LOC, 0x80, ACCUMULATOR_X_LOC, 0x40),
                    // [ACCUMULATOR_X_LOC, ACCUMULATOR_X_LOC + 0x40) = ((ā + βz + γ)( b̄ + βk_1 z + γ)(c̄ + βk_2 z + γ)α + L_1(z)α^3 + u)*[z]_1 −(ā + βs̄_σ1 + γ)( b̄ + βs̄_σ2 + γ)αβz̄_ω * [s_σ3]_1
                    staticcall(gas(), 7, 0x00, 0x60, ACCUMULATOR2_X_LOC, 0x40)
                    // [ACCUMULATOR2_X_LOC, ACCUMULATOR2_X_LOC + 0x40) = ā * [q_L]_1
                )

                // Q2
                mstore(0x00, mload(Q2_X_LOC))
                mstore(0x20, mload(Q2_Y_LOC))
                mstore(0x40, mulmod(mload(W2_EVAL_LOC), linear_challenge, p))
                success := and(
                    success,
                    and(
                        staticcall(gas(), 6, ACCUMULATOR_X_LOC, 0x80, ACCUMULATOR_X_LOC, 0x40),
                        staticcall(gas(), 7, 0x00, 0x60, ACCUMULATOR2_X_LOC, 0x40)
                    )
                )

                // Q3
                mstore(0x00, mload(Q3_X_LOC))
                mstore(0x20, mload(Q3_Y_LOC))
                mstore(0x40, mulmod(mload(W3_EVAL_LOC), linear_challenge, p))
                success := and(
                    success,
                    and(
                        staticcall(gas(), 6, ACCUMULATOR_X_LOC, 0x80, ACCUMULATOR_X_LOC, 0x40),
                        staticcall(gas(), 7, 0x00, 0x60, ACCUMULATOR2_X_LOC, 0x40)
                    )
                )

                // QM
                mstore(0x00, mload(QM_X_LOC))
                mstore(0x20, mload(QM_Y_LOC))
                mstore(0x40, mulmod(t1, mload(W2_EVAL_LOC), p))
                success := and(
                    success,
                    and(
                        staticcall(gas(), 6, ACCUMULATOR_X_LOC, 0x80, ACCUMULATOR_X_LOC, 0x40),
                        staticcall(gas(), 7, 0x00, 0x60, ACCUMULATOR2_X_LOC, 0x40)
                    )
                )

                // QC
                mstore(0x00, mload(QC_X_LOC))
                mstore(0x20, mload(QC_Y_LOC))
                mstore(0x40, linear_challenge)
                success := and(
                    success,
                    and(
                        staticcall(gas(), 6, ACCUMULATOR_X_LOC, 0x80, ACCUMULATOR_X_LOC, 0x40),
                        staticcall(gas(), 7, 0x00, 0x60, ACCUMULATOR2_X_LOC, 0x40)
                    )
                )

                mstore(ARITHMETIC_TERM_SUCCESS_FLAG, success)
            }

             /**
             * COMPUTE BATCH OPENING COMMITMENT
             */
            {
                // previous scalar_multiplier = 1, z^n, z^2n
                // scalar_multiplier owing to the simplified Plonk = 1 * -Z_H(z), z^n * -Z_H(z), z^2n * -Z_H(z)
                // VALIDATE T1
                let success
                {
                    let x := mload(T1_X_LOC)
                    let y := mload(T1_Y_LOC)
                    let xx := mulmod(x, x, q)
                    success := eq(mulmod(y, y, q), addmod(mulmod(x, xx, q), 3, q))
                    mstore(0x00, x)
                    mstore(0x20, y)
                    mstore(0x40, sub(p, mload(ZERO_POLY_LOC)))
                    // mstore(ACCUMULATOR2_X_LOC, x)
                    // mstore(ACCUMULATOR2_Y_LOC, y)
                }
                success := and(success,
                and(
                    staticcall(gas(), 6, ACCUMULATOR_X_LOC, 0x80, ACCUMULATOR_X_LOC, 0x40),
                    staticcall(gas(), 7, 0x00, 0x60, ACCUMULATOR2_X_LOC, 0x40)
                ))

                // VALIDATE T2
                let scalar_multiplier := mload(ZETA_POW_N_LOC)
                {
                    let x := mload(T2_X_LOC)
                    let y := mload(T2_Y_LOC)
                    let xx := mulmod(x, x, q)
                    success := and(success, eq(mulmod(y, y, q), addmod(mulmod(x, xx, q), 3, q)))
                    mstore(0x00, x)
                    mstore(0x20, y)
                }
                mstore(0x40, mulmod(scalar_multiplier, sub(p, mload(ZERO_POLY_LOC)), p))

                success := and(
                    staticcall(gas(), 6, ACCUMULATOR_X_LOC, 0x80, ACCUMULATOR_X_LOC, 0x40),
                    and(
                        success,
                        staticcall(gas(), 7, 0x00, 0x60, ACCUMULATOR2_X_LOC, 0x40)
                    )
                )

                // VALIDATE T3
                {
                    let x := mload(T3_X_LOC)
                    let y := mload(T3_Y_LOC)
                    let xx := mulmod(x, x, q)
                    success := and(success, eq(mulmod(y, y, q), addmod(mulmod(x, xx, q), 3, q)))
                    mstore(0x00, x)
                    mstore(0x20, y)
                }
                mstore(0x40, mulmod(scalar_multiplier, mulmod(scalar_multiplier, sub(p, mload(ZERO_POLY_LOC)), p), p))
                success := and(
                    staticcall(gas(), 6, ACCUMULATOR_X_LOC, 0x80, ACCUMULATOR_X_LOC, 0x40),
                    and(
                        success,
                        staticcall(gas(), 7, 0x00, 0x60, ACCUMULATOR2_X_LOC, 0x40)
                    )
                )

                // VALIDATE W1
                {
                    let x := mload(W1_X_LOC)
                    let y := mload(W1_Y_LOC)
                    let xx := mulmod(x, x, q)
                    success := and(success, eq(mulmod(y, y, q), addmod(mulmod(x, xx, q), 3, q)))
                    mstore(0x00, x)
                    mstore(0x20, y)
                }
                mstore(0x40, mload(C_V0_LOC))

                success := and(
                    staticcall(gas(), 6, ACCUMULATOR_X_LOC, 0x80, ACCUMULATOR_X_LOC, 0x40),
                    and(
                        success,
                        staticcall(gas(), 7, 0x00, 0x60, ACCUMULATOR2_X_LOC, 0x40)
                    )
                )

                // VALIDATE W2
                {
                    let x := mload(W2_X_LOC)
                    let y := mload(W2_Y_LOC)
                    let xx := mulmod(x, x, q)
                    success := and(success, eq(mulmod(y, y, q), addmod(mulmod(x, xx, q), 3, q)))
                    mstore(0x00, x)
                    mstore(0x20, y)
                }
                mstore(0x40, mload(C_V1_LOC))
                success := and(
                    staticcall(gas(), 6, ACCUMULATOR_X_LOC, 0x80, ACCUMULATOR_X_LOC, 0x40),
                    and(
                        success,
                        staticcall(gas(), 7, 0x00, 0x60, ACCUMULATOR2_X_LOC, 0x40)
                    )
                )

                // VALIDATE W3
                {
                    let x := mload(W3_X_LOC)
                    let y := mload(W3_Y_LOC)
                    let xx := mulmod(x, x, q)
                    success := and(success, eq(mulmod(y, y, q), addmod(mulmod(x, xx, q), 3, q)))
                    mstore(0x00, x)
                    mstore(0x20, y)
                }
                mstore(0x40, mload(C_V2_LOC))
                success := and(
                    staticcall(gas(), 6, ACCUMULATOR_X_LOC, 0x80, ACCUMULATOR_X_LOC, 0x40),
                    and(
                        success,
                        staticcall(gas(), 7, 0x00, 0x60, ACCUMULATOR2_X_LOC, 0x40)
                    )
                )

                mstore(0x00, mload(SIGMA1_X_LOC))
                mstore(0x20, mload(SIGMA1_Y_LOC))
                mstore(0x40, mload(C_V3_LOC))
                success := and(
                    staticcall(gas(), 6, ACCUMULATOR_X_LOC, 0x80, ACCUMULATOR_X_LOC, 0x40),
                    and(
                        success,
                        staticcall(gas(), 7, 0x00, 0x60, ACCUMULATOR2_X_LOC, 0x40)
                    )
                )

                mstore(0x00, mload(SIGMA2_X_LOC))
                mstore(0x20, mload(SIGMA2_Y_LOC))
                mstore(0x40, mload(C_V4_LOC))
                success := and(
                    staticcall(gas(), 6, ACCUMULATOR_X_LOC, 0x80, ACCUMULATOR_X_LOC, 0x40),
                    and(
                        success,
                        staticcall(gas(), 7, 0x00, 0x60, ACCUMULATOR2_X_LOC, 0x40)
                    )
                )

                mstore(BATCH_OPENING_SUCCESS_FLAG, success)
            }

            /**
             * COMPUTE BATCH EVALUATION SCALAR MULTIPLIER
             */
            {
                mstore(0x00, 0x01) // [1].x
                mstore(0x20, 0x02) // [1].y
                // Yul stack optimizer doing some work here...
                mstore(0x40, sub(p,
                    addmod(
                        mulmod(mload(C_U_LOC), mload(Z_OMEGA_EVAL_LOC), p),
                        addmod(
                            sub(p, mload(R_ZERO_EVAL_LOC)), // Change owing to the simplified Plonk
                                addmod(
                                    mulmod(mload(C_V4_LOC), mload(SIGMA2_EVAL_LOC), p),
                                    addmod(
                                        mulmod(mload(C_V3_LOC), mload(SIGMA1_EVAL_LOC), p),
                                        addmod(
                                            mulmod(mload(C_V2_LOC), mload(W3_EVAL_LOC), p),
                                            addmod(
                                                mulmod(mload(C_V1_LOC), mload(W2_EVAL_LOC), p),
                                                mulmod(mload(C_V0_LOC), mload(W1_EVAL_LOC), p),
                                                p
                                            ),
                                            p
                                        ),
                                        p
                                    ),
                                    p
                                ),
                                p
                            ),
                            p
                        )
                    )
                )

                let success := and(
                    staticcall(gas(), 6, ACCUMULATOR_X_LOC, 0x80, ACCUMULATOR_X_LOC, 0x40),
                    staticcall(gas(), 7, 0x00, 0x60, ACCUMULATOR2_X_LOC, 0x40)
                )
                mstore(OPENING_COMMITMENT_SUCCESS_FLAG, success)
            }

             /**
             * PERFORM PAIRING PREAMBLE
             */
            {
                let u := mload(C_U_LOC)
                let zeta := mload(C_ZETA_LOC)
                let success
                // VALIDATE PI_Z
                {
                    let x := mload(PI_Z_X_LOC)
                    let y := mload(PI_Z_Y_LOC)
                    let xx := mulmod(x, x, q)
                    success := eq(mulmod(y, y, q), addmod(mulmod(x, xx, q), 3, q))
                    mstore(0x00, x)
                    mstore(0x20, y)
                }
                // compute zeta.[PI_Z] and add into accumulator
                mstore(0x40, zeta)
                success := and(success, and(
                    staticcall(gas(), 6, ACCUMULATOR_X_LOC, 0x80, ACCUMULATOR_X_LOC, 0x40),
                    staticcall(gas(), 7, 0x00, 0x60, ACCUMULATOR2_X_LOC, 0x40)
                ))

                // VALIDATE PI_Z_OMEGA
                {
                    let x := mload(PI_Z_OMEGA_X_LOC)
                    let y := mload(PI_Z_OMEGA_Y_LOC)
                    let xx := mulmod(x, x, q)
                    success := and(success, eq(mulmod(y, y, q), addmod(mulmod(x, xx, q), 3, q)))
                    mstore(0x00, x)
                    mstore(0x20, y)
                }
                // compute u.zeta.omega.[PI_Z_OMEGA] and add into accumulator
                mstore(0x40, mulmod(mulmod(u, zeta, p), mload(OMEGA_LOC), p))
                success := and(
                    staticcall(gas(), 6, ACCUMULATOR_X_LOC, 0x80, PAIRING_RHS_X_LOC, 0x40),
                    and(
                        success,
                        staticcall(gas(), 7, 0x00, 0x60, ACCUMULATOR2_X_LOC, 0x40)
                    )
                )

                mstore(0x00, mload(PI_Z_X_LOC))
                mstore(0x20, mload(PI_Z_Y_LOC))
                mstore(0x40, mload(PI_Z_OMEGA_X_LOC))
                mstore(0x60, mload(PI_Z_OMEGA_Y_LOC))
                mstore(0x80, u)
                success := and(
                    staticcall(gas(), 6, 0x00, 0x80, PAIRING_LHS_X_LOC, 0x40),
                    and(
                        success,
                        staticcall(gas(), 7, 0x40, 0x60, 0x40, 0x40)
                    )
                )
                // negate lhs y-coordinate
                mstore(PAIRING_LHS_Y_LOC, sub(q, mload(PAIRING_LHS_Y_LOC)))

                if mload(CONTAINS_RECURSIVE_PROOF_LOC)
                {
                    // VALIDATE RECURSIVE P1
                    {
                        let x := mload(RECURSIVE_P1_X_LOC)
                        let y := mload(RECURSIVE_P1_Y_LOC)
                        let xx := mulmod(x, x, q)
                        success := and(success, eq(mulmod(y, y, q), addmod(mulmod(x, xx, q), 3, q)))
                        mstore(0x00, x)
                        mstore(0x20, y)
                    }

                    // compute u.u.[recursive_p1] and write into 0x60
                    mstore(0x40, mulmod(u, u, p))
                    success := and(success, staticcall(gas(), 7, 0x00, 0x60, 0x60, 0x40))
                    // VALIDATE RECURSIVE P2
                    {
                        let x := mload(RECURSIVE_P2_X_LOC)
                        let y := mload(RECURSIVE_P2_Y_LOC)
                        let xx := mulmod(x, x, q)
                        success := and(success, eq(mulmod(y, y, q), addmod(mulmod(x, xx, q), 3, q)))
                        mstore(0x00, x)
                        mstore(0x20, y)
                    }
                    // compute u.u.[recursive_p2] and write into 0x00
                    // 0x40 still contains u*u
                    success := and(success, staticcall(gas(), 7, 0x00, 0x60, 0x00, 0x40))

                    // compute u.u.[recursiveP1] + rhs and write into rhs
                    mstore(0xa0, mload(PAIRING_RHS_X_LOC))
                    mstore(0xc0, mload(PAIRING_RHS_Y_LOC))
                    success := and(success, staticcall(gas(), 6, 0x60, 0x80, PAIRING_RHS_X_LOC, 0x40))

                    // compute u.u.[recursiveP2] + lhs and write into lhs
                    mstore(0x40, mload(PAIRING_LHS_X_LOC))
                    mstore(0x60, mload(PAIRING_LHS_Y_LOC))
                    success := and(success, staticcall(gas(), 6, 0x00, 0x80, PAIRING_LHS_X_LOC, 0x40))
                }

                if iszero(success)
                {
                    mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                    mstore(0x04, 0x20)
                    mstore(0x24, 32)
                    mstore(0x44, "PROOF_VERIFICATION_FAILED_TYPE_2")
                    revert(0x00, 0x64)
                }
                mstore(PAIRING_PREAMBLE_SUCCESS_FLAG, success)
            }

            /**
             * PERFORM PAIRING
             */
            {
                // rhs paired with [1]_2
                // lhs paired with [x]_2

                mstore(0x00, mload(PAIRING_RHS_X_LOC))
                mstore(0x20, mload(PAIRING_RHS_Y_LOC))
                mstore(0x40, 0x198e9393920d483a7260bfb731fb5d25f1aa493335a9e71297e485b7aef312c2) // this is [1]_2
                mstore(0x60, 0x1800deef121f1e76426a00665e5c4479674322d4f75edadd46debd5cd992f6ed)
                mstore(0x80, 0x090689d0585ff075ec9e99ad690c3395bc4b313370b38ef355acdadcd122975b)
                mstore(0xa0, 0x12c85ea5db8c6deb4aab71808dcb408fe3d1e7690c43d37b4ce6cc0166fa7daa)

                mstore(0xc0, mload(PAIRING_LHS_X_LOC))
                mstore(0xe0, mload(PAIRING_LHS_Y_LOC))
                mstore(0x100, mload(G2X_X0_LOC))
                mstore(0x120, mload(G2X_X1_LOC))
                mstore(0x140, mload(G2X_Y0_LOC))
                mstore(0x160, mload(G2X_Y1_LOC))

                let success := staticcall(
                    gas(),
                    8,
                    0x00,
                    0x180,
                    0x00,
                    0x20
                )
                mstore(PAIRING_SUCCESS_FLAG, success)
                mstore(RESULT_FLAG, mload(0x00))
            }
            if iszero(and(
                and(
                    and(
                        and(
                            and(
                                and(
                                    mload(PAIRING_SUCCESS_FLAG),
                                    mload(RESULT_FLAG)
                                ),
                                mload(PAIRING_PREAMBLE_SUCCESS_FLAG)
                            ),
                            mload(OPENING_COMMITMENT_SUCCESS_FLAG)
                        ),
                        mload(BATCH_OPENING_SUCCESS_FLAG)
                    ),
                    mload(ARITHMETIC_TERM_SUCCESS_FLAG)
                ),
                mload(GRAND_PRODUCT_SUCCESS_FLAG)
            ))
            {
                mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                mstore(0x04, 0x20)
                mstore(0x24, 32)
                mstore(0x44, "PROOF_VERIFICATION_FAILED_TYPE_3")
                revert(0x00, 0x64)
            }
            {
                mstore(0x00, 0x01)
                return(0x00, 0x20) // Proof succeeded!
            }
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2022 Aztec
pragma solidity >=0.8.4;

import {StandardTypes} from '../cryptography/StandardTypes.sol';

// Placeholder VK
library VerificationKey {
    function get_verification_key() external pure returns (StandardTypes.VerificationKey memory) {
        StandardTypes.VerificationKey memory vk;
        return vk;
    }
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2022 Aztec
pragma solidity >=0.8.4;

/**
 * @title Bn254Crypto library used for the fr, g1 and g2 point types
 * @dev Used to manipulate fr, g1, g2 types, perform modular arithmetic on them and call
 * the precompiles add, scalar mul and pairing
 *
 * Notes on optimisations
 * 1) Perform addmod, mulmod etc. in assembly - removes the check that Solidity performs to confirm that
 * the supplied modulus is not 0. This is safe as the modulus's used (r_mod, q_mod) are hard coded
 * inside the contract and not supplied by the user
 */
library StandardTypes {
    uint256 internal constant PROGRAM_WIDTH = 3;
    uint256 internal constant NUM_NU_CHALLENGES = 6;

    uint256 internal constant coset_generator0 = 0x0000000000000000000000000000000000000000000000000000000000000005;
    uint256 internal constant coset_generator1 = 0x0000000000000000000000000000000000000000000000000000000000000006;
    uint256 internal constant coset_generator2 = 0x0000000000000000000000000000000000000000000000000000000000000007;

    // TODO: add external_coset_generator() method to compute this
    uint256 internal constant coset_generator7 = 0x000000000000000000000000000000000000000000000000000000000000000c;

    struct G1Point {
        uint256 x;
        uint256 y;
    }

    // G2 group element where x \in Fq2 = x0 * z + x1
    struct G2Point {
        uint256 x0;
        uint256 x1;
        uint256 y0;
        uint256 y1;
    }

    // N>B. Do not re-order these fields! They must appear in the same order as they
    // appear in the proof data
    struct Proof {
        G1Point W1;
        G1Point W2;
        G1Point W3;
        G1Point Z;
        G1Point T1;
        G1Point T2;
        G1Point T3;
        uint256 w1;
        uint256 w2;
        uint256 w3;
        uint256 sigma1;
        uint256 sigma2;
        //    uint256 linearization_polynomial;
        uint256 grand_product_at_z_omega;
        G1Point PI_Z;
        G1Point PI_Z_OMEGA;
        G1Point recursive_P1;
        G1Point recursive_P2;
        uint256 r_0; // Changes owing to the simplified Plonk
    }

    struct ChallengeTranscript {
        uint256 alpha_base;
        uint256 alpha;
        uint256 zeta;
        uint256 beta;
        uint256 gamma;
        uint256 u;
        uint256 v0;
        uint256 v1;
        uint256 v2;
        uint256 v3;
        uint256 v4;
        uint256 v5;
        uint256 v6;
        // uint256 v7;
    }

    struct VerificationKey {
        uint256 circuit_size;
        uint256 num_inputs;
        uint256 work_root;
        uint256 domain_inverse;
        uint256 work_root_inverse;
        G1Point Q1;
        G1Point Q2;
        G1Point Q3;
        G1Point QM;
        G1Point QC;
        G1Point SIGMA1;
        G1Point SIGMA2;
        G1Point SIGMA3;
        bool contains_recursive_proof;
        uint256 recursive_proof_indices;
        G2Point g2_x;
        // zeta challenge raised to the power of the circuit size.
        // Not actually part of the verification key, but we put it here to prevent stack depth errors
        uint256 zeta_pow_n;
    }
}

/**

    ### MEMORY LAYOUT

    0x00 - 0x200 RESERVED FOR SCRATCH SPACE

    0x200 - 0x600 RESERVED FOR VERIFICATION KEY

    0x600 - 0x900 RESERVED FOR LOCAL VARIABLES

    ### VERIFICATION KEY ###
    ### ALL LOCALTIONS ARE RELATIVE TO THE START OF THIS BLOCK IN MEMORY (0x200)

    0x00          : n
    0x20          : num_inputs
    0x40          : omega
    0x60          : n^{-1}
    0x80          : omega^{-1}
    0xa0 - 0xe0   : Q1
    0xe0 - 0x120  : Q2
    0x120 - 0x160 : Q3
    0x160 - 0x1a0 : QM
    0x1a0 - 0x1e0 : QC
    0x1e0 - 0x220 : SIGMA1
    0x220 - 0x260 : SIGMA2
    0x260 - 0x2a0 : SIGMA3
    0x2a0 - 0x2c0 : contains_recursive_proof
    0x2c0 - 0x340 : G2_x ([x]_2)

    ### LOCAL VARIABLES ###
    ### ALL LOCALTIONS ARE RELATIVE TO THE START OF THIS BLOCK IN MEMORY (0x200)

    0x00  : zeta_pow_n
    0x20  : quotient_poly_eval
    0x40  : public_input_delta_numerator
    0x60  : public_input_delta_denominator
    0x80  : vanishing_numerator
    0xa0  : vanishing_denominator
    0xc0  : lagrange_numerator
    0xe0  : l_start_denominator
    0x100 : l_end_denominator
    0x120 : zero_poly_eval
    0x140 : public_input_delta
    0x160 : l_start
    0x180 : l_end
    0x200 : p
    0x220 : proof_calldata_ptr

    ### PROOF ###

    0x00  - 0x40  : W1
    0x40  - 0x80  : W2
    0x80  - 0xc0  : W3
    0xc0  - 0x100 : Z
    0x100 - 0x140 : T1
    0x140 - 0x180 : T2
    0x180 - 0x1c0 : T3
    0x1c0 - 0x200 : w1
    0x200 - 0x220 : w2
    0x220 - 0x240 : w3
    0x240 - 0x260 : sigma1
    0x260 - 0x280 : sigma2
    0x280 - 0x2a0 : r
    0x2a0 - 0x2c0 : z_omega
    0x2c0 - 0x300 : PI_Z
    0x300 - 0x340 : PI_Z_OMEGA
    0x340 - 0x380 : RECURSIVE_P1
    0x380 - 0x3c0 : RECURSIVE_P2
 */

// Verification Key Hash: 231a6b3ded1c9472f543428e5fa1b7dd085d852173f37b4659308745c9e930e6
// SPDX-License-Identifier: Apache-2.0
// Copyright 2022 Aztec
pragma solidity >=0.8.4;

import {StandardTypes} from '../cryptography/StandardTypes.sol';

library VerificationKey28x32 {

    function get_verification_key() external pure returns (StandardTypes.VerificationKey memory) {
        StandardTypes.VerificationKey memory vk;

        assembly {
            mstore(add(vk, 0x00), 8388608) // vk.circuit_size
            mstore(add(vk, 0x20), 17) // vk.num_inputs
            mstore(add(vk, 0x40),0x0210fe635ab4c74d6b7bcf70bc23a1395680c64022dd991fb54d4506ab80c59d) // vk.work_root
            mstore(add(vk, 0x60),0x30644e121894ba67550ff245e0f5eb5a25832df811e8df9dd100d30c2c14d821) // vk.domain_inverse
            mstore(add(vk, 0x80),0x2165a1a5bda6792b1dd75c9f4e2b8e61126a786ba1a6eadf811b03e7d69ca83b) // vk.work_root_inverse
            mstore(mload(add(vk, 0xa0)), 0x0f7c715011823362f824b9de259a685032eedb928431724439a567967852d773)//vk.Q1
            mstore(add(mload(add(vk, 0xa0)), 0x20), 0x17ec42a324359512a7d093faa7e55103b1f017af1bfaa5e1ccd31cc9e4ff8df0)
            mstore(mload(add(vk, 0xc0)), 0x12bba50d7bc3e87e00bd3ce419001f3b2c59201b5ddf8cd1bba70f74061c7e7b)//vk.Q2
            mstore(add(mload(add(vk, 0xc0)), 0x20), 0x2c3cd5dbb0d5a28b93f57660812ad5ae468aa908c5cf3ec3499973af026d9e2a)
            mstore(mload(add(vk, 0xe0)), 0x07c448ca9631b9d24fc45d555f1b1952134eaf083c3bd46a000fcf5434a94478)//vk.Q3
            mstore(add(mload(add(vk, 0xe0)), 0x20), 0x0e18227b6c1a461c1cbb59826cac7ebabe89e6490d80312be1504d0f7fb98059)
            mstore(mload(add(vk, 0x100)), 0x24a14b8c3bc0ee2a31a5a8bb1c69a1519a814de7c78cb5fe3248b1717893e7f8)//vk.QM
            mstore(add(mload(add(vk, 0x100)), 0x20), 0x1abd8e73735327575cec64e8d3c20fe5ae58f23468478a9dc6aee652332ed569)
            mstore(mload(add(vk, 0x120)), 0x1531778c4bbda77a659dd68bf49102ceb1ab6fbd96fd5cc2f7f335e3c1ec2ce5)//vk.QC
            mstore(add(mload(add(vk, 0x120)), 0x20), 0x166f3cd25cc14370885bf52637ff5dc382c8a6243f552cfb96a09a64f314631f)
            mstore(mload(add(vk, 0x140)), 0x289dcb3bb09ce8d1a5c6d08cdf87ba9fc0f22ea255cf644523a602e6d3ae348e)//vk.SIGMA1
            mstore(add(mload(add(vk, 0x140)), 0x20), 0x2d21049d7f8b99c666d353e6f7101663ed09b4877f0a829d275bb83c223d1076)
            mstore(mload(add(vk, 0x160)), 0x0d4e31a8d510770f6912e7ee0f7454ecaf51b4df1c5f5865e0017023eab933c8)//vk.SIGMA2
            mstore(add(mload(add(vk, 0x160)), 0x20), 0x0f974eb06e1bae83bf339bc7d15b5ea18d826aa4c877ca1b63317e2a8debe7d1)
            mstore(mload(add(vk, 0x180)), 0x2d1d6ae2a57defc6f3a789129f67f9c9969961b8642a92b91a9bdc0afb8b7f99)//vk.SIGMA3
            mstore(add(mload(add(vk, 0x180)), 0x20), 0x300c3f15de1f550c772a7306a3a7e491b84ec7e7a9d4601c8b88107eff4f45ee)
            mstore(add(vk, 0x1a0), 0x01) // vk.contains_recursive_proof
            mstore(add(vk, 0x1c0), 1) // vk.recursive_proof_public_input_indices
            mstore(mload(add(vk, 0x1e0)), 0x260e01b251f6f1c7e7ff4e580791dee8ea51d87a358e038b4efe30fac09383c1) // vk.g2_x.X.c1
            mstore(add(mload(add(vk, 0x1e0)), 0x20), 0x0118c4d5b837bcc2bc89b5b398b5974e9f5944073b32078b7e231fec938883b0) // vk.g2_x.X.c0
            mstore(add(mload(add(vk, 0x1e0)), 0x40), 0x04fc6369f7110fe3d25156c1bb9a72859cf2a04641f99ba4ee413c80da6a5fe4) // vk.g2_x.Y.c1
            mstore(add(mload(add(vk, 0x1e0)), 0x60), 0x22febda3c0c0632a56475b4214e5615e11e6dd3f96e6cea2854a87d4dacc5e55) // vk.g2_x.Y.c0
        }
        return vk;
    }
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2022 Aztec
pragma solidity >=0.8.4;

import {StandardTypes} from '../cryptography/StandardTypes.sol';

library VerificationKey1x1 {
    function get_verification_key() external pure returns (StandardTypes.VerificationKey memory) {
        StandardTypes.VerificationKey memory vk;

        assembly {
            mstore(add(vk, 0x00), 8388608) // vk.circuit_size
            mstore(add(vk, 0x20), 17) // vk.num_inputs
            mstore(add(vk, 0x40), 0x0210fe635ab4c74d6b7bcf70bc23a1395680c64022dd991fb54d4506ab80c59d) // vk.work_root
            mstore(add(vk, 0x60), 0x30644e121894ba67550ff245e0f5eb5a25832df811e8df9dd100d30c2c14d821) // vk.domain_inverse
            mstore(add(vk, 0x80), 0x2165a1a5bda6792b1dd75c9f4e2b8e61126a786ba1a6eadf811b03e7d69ca83b) // vk.work_root_inverse
            mstore(mload(add(vk, 0xa0)), 0x0f7c715011823362f824b9de259a685032eedb928431724439a567967852d773) //vk.Q1
            mstore(add(mload(add(vk, 0xa0)), 0x20), 0x17ec42a324359512a7d093faa7e55103b1f017af1bfaa5e1ccd31cc9e4ff8df0)
            mstore(mload(add(vk, 0xc0)), 0x3010206be637307bc068ce5169be29f803e7fd6c2b69f653ca3b745864d30996) //vk.Q2
            mstore(add(mload(add(vk, 0xc0)), 0x20), 0x0de1236425db4e2287118dec6d53937eb1cb8d3b4a0e3816ef3d9c61aa394cf0)
            mstore(mload(add(vk, 0xe0)), 0x07c448ca9631b9d24fc45d555f1b1952134eaf083c3bd46a000fcf5434a94478) //vk.Q3
            mstore(add(mload(add(vk, 0xe0)), 0x20), 0x0e18227b6c1a461c1cbb59826cac7ebabe89e6490d80312be1504d0f7fb98059)
            mstore(mload(add(vk, 0x100)), 0x24a14b8c3bc0ee2a31a5a8bb1c69a1519a814de7c78cb5fe3248b1717893e7f8) //vk.QM
            mstore(add(mload(add(vk, 0x100)), 0x20), 0x1abd8e73735327575cec64e8d3c20fe5ae58f23468478a9dc6aee652332ed569)
            mstore(mload(add(vk, 0x120)), 0x1531778c4bbda77a659dd68bf49102ceb1ab6fbd96fd5cc2f7f335e3c1ec2ce5) //vk.QC
            mstore(add(mload(add(vk, 0x120)), 0x20), 0x166f3cd25cc14370885bf52637ff5dc382c8a6243f552cfb96a09a64f314631f)
            mstore(mload(add(vk, 0x140)), 0x289dcb3bb09ce8d1a5c6d08cdf87ba9fc0f22ea255cf644523a602e6d3ae348e) //vk.SIGMA1
            mstore(add(mload(add(vk, 0x140)), 0x20), 0x2d21049d7f8b99c666d353e6f7101663ed09b4877f0a829d275bb83c223d1076)
            mstore(mload(add(vk, 0x160)), 0x0d4e31a8d510770f6912e7ee0f7454ecaf51b4df1c5f5865e0017023eab933c8) //vk.SIGMA2
            mstore(add(mload(add(vk, 0x160)), 0x20), 0x0f974eb06e1bae83bf339bc7d15b5ea18d826aa4c877ca1b63317e2a8debe7d1)
            mstore(mload(add(vk, 0x180)), 0x2d1d6ae2a57defc6f3a789129f67f9c9969961b8642a92b91a9bdc0afb8b7f99) //vk.SIGMA3
            mstore(add(mload(add(vk, 0x180)), 0x20), 0x300c3f15de1f550c772a7306a3a7e491b84ec7e7a9d4601c8b88107eff4f45ee)
            mstore(add(vk, 0x1a0), 0x01) // vk.contains_recursive_proof
            mstore(add(vk, 0x1c0), 1) // vk.recursive_proof_public_input_indices
            mstore(mload(add(vk, 0x1e0)), 0x260e01b251f6f1c7e7ff4e580791dee8ea51d87a358e038b4efe30fac09383c1) // vk.g2_x.X.c1
            mstore(add(mload(add(vk, 0x1e0)), 0x20), 0x0118c4d5b837bcc2bc89b5b398b5974e9f5944073b32078b7e231fec938883b0) // vk.g2_x.X.c0
            mstore(add(mload(add(vk, 0x1e0)), 0x40), 0x04fc6369f7110fe3d25156c1bb9a72859cf2a04641f99ba4ee413c80da6a5fe4) // vk.g2_x.Y.c1
            mstore(add(mload(add(vk, 0x1e0)), 0x60), 0x22febda3c0c0632a56475b4214e5615e11e6dd3f96e6cea2854a87d4dacc5e55) // vk.g2_x.Y.c0
        }
        return vk;
    }
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2022 Aztec
pragma solidity >=0.8.4;

import {StandardTypes} from '../cryptography/StandardTypes.sol';

library MockVerificationKey {
    function get_verification_key() external pure returns (StandardTypes.VerificationKey memory) {
        StandardTypes.VerificationKey memory vk;

        assembly {
            mstore(add(vk, 0x00), 8192) // vk.circuit_size
            mstore(add(vk, 0x20), 17) // vk.num_inputs
            mstore(add(vk, 0x40), 0x006fab49b869ae62001deac878b2667bd31bf3e28e3a2d764aa49b8d9bbdd310) // vk.work_root
            mstore(add(vk, 0x60), 0x3062cb506d9a969cb702833453cd4c52654aa6a93775a2c5bf57d68443608001) // vk.domain_inverse
            mstore(add(vk, 0x80), 0x1670ed58bfac610408e124db6a1cb6c8c8df74fa978188ca3b0b205aabd95dc9) // vk.work_root_inverse
            mstore(mload(add(vk, 0xa0)), 0x0be8a2b6819e5ed4fd15bb5cb484086e452297e53e83878519ea8dd5f7abbf2c) //vk.Q1
            mstore(add(mload(add(vk, 0xa0)), 0x20), 0x295a1fca477ff3f65be1f71f2f4fc2df95cb23bf05de6b9cd2779348570c9236)
            mstore(mload(add(vk, 0xc0)), 0x0b051497e878ea0d54f0004fec15b1c6d3be2d8872a688e39d43b61499942094) //vk.Q2
            mstore(add(mload(add(vk, 0xc0)), 0x20), 0x19ae5022420456ca185141db41f6a64ed82b8a2217fd9d50f6dddb0dab725f45)
            mstore(mload(add(vk, 0xe0)), 0x043a124edd1942909fbd2ba016716b174326462cf54f8c20e567eb39b858e83a) //vk.Q3
            mstore(add(mload(add(vk, 0xe0)), 0x20), 0x0d50bd8e2c83217fdbf3c150d51f3b9e4baa4b1dc3ee57e305d3896a53bc3562)
            mstore(mload(add(vk, 0x100)), 0x137d4c5f8e111374a1b162a273b058ac41c42735a7f26910443e48796206171c) //vk.QM
            mstore(add(mload(add(vk, 0x100)), 0x20), 0x047e986785533350b315c24a1e029349870e22258c4c1293f7094a6376c1ab12)
            mstore(mload(add(vk, 0x120)), 0x06a31854eac27a0a9b65f9b098d3a47ca10ee3d5ae1c178d9704e94c8b889f4b) //vk.QC
            mstore(add(mload(add(vk, 0x120)), 0x20), 0x08d9b7926623abaab8b5decac0415b3849c112d3396b5296ee3a7a0a34285469)
            mstore(mload(add(vk, 0x140)), 0x095f1b2a902ebe4a8351574b3ccbf9a2024b0e56b3d0cbe781b9244505d52894) //vk.SIGMA1
            mstore(add(mload(add(vk, 0x140)), 0x20), 0x1314e8bb583f3166f76f0d1e1ce9f964c06d88e6bbecfc64ce38aab8df55f1fc)
            mstore(mload(add(vk, 0x160)), 0x0db72f65f3a6cf58085528d93d19b58ea26919ac206b240822616015185d2f3d) //vk.SIGMA2
            mstore(add(mload(add(vk, 0x160)), 0x20), 0x2b3c4c58a3cc75c104c9f0f5af5218616b71d7430df19b2a1bd5f4ecc0dac64e)
            mstore(mload(add(vk, 0x180)), 0x09342cc8fc28c2fd14f3a3219c311575d4ab9adeba8385a53f201d8afba4312d) //vk.SIGMA3
            mstore(add(mload(add(vk, 0x180)), 0x20), 0x1156442cf1bd1cd4d4583d3b21a054b3171b5452e4fa96a2ddcd769004ecd3d8)
            mstore(add(vk, 0x1a0), 0x00) // vk.contains_recursive_proof
            mstore(add(vk, 0x1c0), 0) // vk.recursive_proof_public_input_indices
            mstore(mload(add(vk, 0x1e0)), 0x260e01b251f6f1c7e7ff4e580791dee8ea51d87a358e038b4efe30fac09383c1) // vk.g2_x.X.c1
            mstore(add(mload(add(vk, 0x1e0)), 0x20), 0x0118c4d5b837bcc2bc89b5b398b5974e9f5944073b32078b7e231fec938883b0) // vk.g2_x.X.c0
            mstore(add(mload(add(vk, 0x1e0)), 0x40), 0x04fc6369f7110fe3d25156c1bb9a72859cf2a04641f99ba4ee413c80da6a5fe4) // vk.g2_x.Y.c1
            mstore(add(mload(add(vk, 0x1e0)), 0x60), 0x22febda3c0c0632a56475b4214e5615e11e6dd3f96e6cea2854a87d4dacc5e55) // vk.g2_x.Y.c0
        }
        return vk;
    }
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2022 Aztec
pragma solidity >=0.8.4;

import {IVerifier} from '../interfaces/IVerifier.sol';

/**
 * @title Plonk proof verification contract
 * @dev Warning: do not deploy in real environments, for testing only
 * Mocks the role of a PLONK verifier contract
 */
contract MockVerifier is IVerifier {
    /**
     * @dev Mock verify a Plonk proof
     */
    function verify(bytes memory, uint256) external pure override returns (bool) {
        return true;
    }
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2022 Aztec
pragma solidity >=0.8.4;

import {ERC20} from '@openzeppelin/contracts/token/ERC20/ERC20.sol';

/**
 * @dev Warning: do not deploy in real environments, for testing only
 * ERC20 contract where anybody is able to mint
 */
contract ERC20Mintable is ERC20 {
    uint8 public asset_decimals = 18;

    constructor(string memory symbol_) ERC20(symbol_, symbol_) {}

    function mint(address _to, uint256 _value) public returns (bool) {
        _mint(_to, _value);
        return true;
    }

    function decimals() public view virtual override returns (uint8) {
        return asset_decimals;
    }

    function setDecimals(uint8 _decimals) external {
        asset_decimals = _decimals;
    }
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2022 Aztec
pragma solidity >=0.8.4;

import {ERC20Mintable} from './ERC20Mintable.sol';

import {IRollupProcessor} from '../interfaces/IRollupProcessor.sol';

/**
 * @dev Warning: do not deploy in real environments, for testing only
 * ERC20 contract where the transfer() fn will always throw
 */
contract ERC20Reenter is ERC20Mintable {
    error LOCKED_NO_REENTER();

    constructor() ERC20Mintable('TEST') {}

    function transferFrom(
        address,
        address to,
        uint256
    ) public override returns (bool) {
        IRollupProcessor(to).processRollup('', '');
        return true;
    }
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2022 Aztec
pragma solidity >=0.8.4;

import {ERC20Mintable} from './ERC20Mintable.sol';

/**
 * @dev Warning: do not deploy in real environments, for testing only
 * ERC20 contract which has permit implementation and is mintable
 */
contract ERC20Permit is ERC20Mintable {
    bytes32 public DOMAIN_SEPARATOR;
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint256) public nonces;

    // bytes32 public constant PERMIT_TYPEHASH_NON_STANDARD = keccak256("Permit(address holder,address spender,uint256 nonce,uint256 expiry,bool allowed)");
    bytes32 public constant PERMIT_TYPEHASH_NON_STANDARD =
        0xea2aa0a1be11a07ed86d755c93467f4f82362b452371d1ba94d1715123511acb;

    constructor(string memory symbol_) ERC20Mintable(symbol_) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes(name())),
                keccak256(bytes('1')),
                chainId,
                address(this)
            )
        );
    }

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(deadline >= block.timestamp, 'EXPIRED');
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, 'INVALID_SIGNATURE');
        _approve(owner, spender, value);
    }

    function permit(
        address holder,
        address spender,
        uint256 nonce,
        uint256 expiry,
        bool allowed,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH_NON_STANDARD, holder, spender, nonce, expiry, allowed))
            )
        );

        require(holder != address(0), 'INVALID_HOLDER');
        require(holder == ecrecover(digest, v, r, s), 'INVALID_SIGNATURE');
        require(expiry == 0 || expiry >= block.timestamp, 'EXPIRED');
        require(nonce == nonces[holder]++, 'INVALID_NONCE');
        uint256 value = allowed ? (2**256) - 1 : 0;
        _approve(holder, spender, value);
    }
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2022 Aztec
pragma solidity >=0.8.4;

import {ERC20Mintable} from './ERC20Mintable.sol';

/**
 * @dev Warning: do not deploy in real environments, for testing only
 * ERC20 contract where the transfer() fn will always throw
 */
contract ERC20FaultyTransfer is ERC20Mintable {
    constructor() ERC20Mintable('TEST') {}

    function transfer(address, uint256) public pure override returns (bool) {
        require(true == false, 'ERC20FaultyTransfer: FAILED');
        return false;
    }
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2022 Aztec
pragma solidity >=0.8.4;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {IDefiBridge} from '../interfaces/IDefiBridge.sol';
import {AztecTypes} from '../AztecTypes.sol';

/**
 * @dev Warning: do not deploy in real environments, for testing only
 */
contract DummyDefiBridge is IDefiBridge {
    address public immutable rollupProcessor;
    uint256 immutable outputValueEth;
    uint256 immutable outputValueToken;
    uint256 immutable outputVirtualValueA;
    uint256 immutable outputVirtualValueB;

    receive() external payable {}

    constructor(
        address _rollupProcessor,
        uint256 _outputValueEth,
        uint256 _outputValueToken,
        uint256 _outputVirtualValueA,
        uint256 _outputVirtualValueB
    ) {
        rollupProcessor = _rollupProcessor;
        outputValueEth = _outputValueEth;
        outputValueToken = _outputValueToken;
        outputVirtualValueA = _outputVirtualValueA;
        outputVirtualValueB = _outputVirtualValueB;
    }

    function convert(
        AztecTypes.AztecAsset memory, /*inputAssetA*/
        AztecTypes.AztecAsset memory, /*inputAssetB*/
        AztecTypes.AztecAsset memory outputAssetA,
        AztecTypes.AztecAsset memory outputAssetB,
        uint256, /*totalInputValue*/
        uint256 interactionNonce,
        uint64 auxData,
        address
    )
        external
        payable
        override
        returns (
            uint256,
            uint256,
            bool
        )
    {
        bool isAsync = auxData > 0;
        if (isAsync) {
            return (0, 0, isAsync);
        }

        uint256 returnValueA = approveTransfer(outputAssetA, outputVirtualValueA, interactionNonce);
        uint256 returnValueB = approveTransfer(outputAssetB, outputVirtualValueB, interactionNonce);
        return (returnValueA, returnValueB, isAsync);
    }

    function canFinalise(
        uint256 /*interactionNonce*/
    ) external pure override returns (bool) {
        return true;
    }

    function finalise(
        AztecTypes.AztecAsset memory, /*inputAssetA*/
        AztecTypes.AztecAsset memory, /*inputAssetB*/
        AztecTypes.AztecAsset memory outputAssetA,
        AztecTypes.AztecAsset memory outputAssetB,
        uint256 interactionNonce,
        uint64
    )
        external
        payable
        override
        returns (
            uint256,
            uint256,
            bool
        )
    {
        require(msg.sender == rollupProcessor, 'invalid sender!');

        uint256 returnValueA = approveTransfer(outputAssetA, outputVirtualValueA, interactionNonce);
        uint256 returnValueB = approveTransfer(outputAssetB, outputVirtualValueB, interactionNonce);
        return (returnValueA, returnValueB, true);
    }

    function approveTransfer(
        AztecTypes.AztecAsset memory asset,
        uint256 virtualValue,
        uint256 interactionNonce
    ) internal returns (uint256 returnValue) {
        if (asset.assetType == AztecTypes.AztecAssetType.VIRTUAL) {
            returnValue = virtualValue;
        } else if (asset.assetType == AztecTypes.AztecAssetType.ETH) {
            returnValue = outputValueEth;
            bytes memory payload = abi.encodeWithSignature('receiveEthFromBridge(uint256)', interactionNonce);
            (bool success, ) = address(rollupProcessor).call{value: outputValueEth}(payload);
            assembly {
                if iszero(success) {
                    returndatacopy(0x00, 0x00, returndatasize())
                    revert(0x00, returndatasize())
                }
            }
        } else if (asset.assetType == AztecTypes.AztecAssetType.ERC20) {
            returnValue = outputValueToken;
            IERC20(asset.erc20Address).approve(rollupProcessor, outputValueToken);
        }
    }
}