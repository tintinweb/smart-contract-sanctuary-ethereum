// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

import {GeneralRandcastConsumerBase, BasicRandcastConsumerBase} from "../GeneralRandcastConsumerBase.sol";

contract GetRandomNumberExample is GeneralRandcastConsumerBase {
    /* requestId -> randomness */
    mapping(bytes32 => uint256) public randomResults;
    uint256[] public randomnessResults;

    // solhint-disable-next-line no-empty-blocks
    constructor(address adapter) BasicRandcastConsumerBase(adapter) {}

    /**
     * Requests randomness
     */
    function getRandomNumber() external returns (bytes32) {
        bytes memory params;
        return _requestRandomness(RequestType.Randomness, params);
    }

    /**
     * Callback function used by Randcast Adapter
     */
    function _fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        randomResults[requestId] = randomness;
        randomnessResults.push(randomness);
    }

    function lengthOfRandomnessResults() public view returns (uint256) {
        return randomnessResults.length;
    }

    function lastRandomnessResult() public view returns (uint256) {
        return randomnessResults[randomnessResults.length - 1];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

import {RequestIdBase} from "../utils/RequestIdBase.sol";
import {GasEstimationBase} from "../utils/GasEstimationBase.sol";
import {BasicRandcastConsumerBase, IAdapter} from "./BasicRandcastConsumerBase.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";

/**
 * @notice This provides callbackGaslimit auto-calculating and TODO balance checking to save user's effort.
 */
abstract contract GeneralRandcastConsumerBase is
    BasicRandcastConsumerBase,
    RequestIdBase,
    GasEstimationBase,
    Ownable
{
    // Sets user seed as 0 to so that users don't have to pass it.
    uint256 private constant _USER_SEED_PLACEHOLDER = 0;
    // Default blocks the working group to wait before responding to the request.
    uint16 private constant _DEFAULT_REQUEST_CONFIRMATIONS = 6;
    // TODO Gives a fixed buffer so that some logic differ in the callback slightly raising gas used will be supported.
    uint256 private constant _GAS_FOR_CALLBACK_OVERHEAD = 30_000;
    // Dummy randomness for estimating gas of callback.
    uint256 private constant _RANDOMNESS_PLACEHOLDER =
        103921425973949831153159651530394295952228049817797655588722524414385831936256;
    // Auto-calculating CallbackGasLimit in the first request call, also user can set it manually.
    uint256 public callbackGasLimit;
    // Auto-estimating CallbackMaxGasFee as 3 times tx.gasprice of the request call, also user can set it manually.
    // notes: tx.gasprice stands for effective_gas_price even post EIP-1559
    // priority_fee_per_gas = min(transaction.max_priority_fee_per_gas, transaction.max_fee_per_gas - block.base_fee_per_gas)
    // effective_gas_price = priority_fee_per_gas + block.base_fee_per_gas
    uint256 public callbackMaxGasFee;

    function setCallbackGasConfig(uint256 _callbackGasLimit, uint256 _callbackMaxGasFee) external onlyOwner {
        callbackGasLimit = _callbackGasLimit;
        callbackMaxGasFee = _callbackMaxGasFee;
    }

    function _requestRandomness(RequestType requestType, bytes memory params)
        internal
        calculateCallbackGasLimit
        returns (bytes32)
    {
        uint256 rawSeed = _makeRandcastInputSeed(_USER_SEED_PLACEHOLDER, msg.sender, nonce);
        // This should be identical to adapter generated requestId.
        bytes32 requestId = _makeRequestId(rawSeed);
        // Only in the first place we calculate the callbackGasLimit, then next time we directly use it to request randomness.
        if (callbackGasLimit == 0) {
            // Prepares the message call of callback function according to request type
            bytes memory data;
            if (requestType == RequestType.Randomness) {
                data = abi.encodeWithSelector(this.rawFulfillRandomness.selector, requestId, _RANDOMNESS_PLACEHOLDER);
            } else if (requestType == RequestType.RandomWords) {
                uint32 numWords = abi.decode(params, (uint32));
                uint256[] memory randomWords = new uint256[](numWords);
                for (uint256 i = 0; i < numWords; i++) {
                    randomWords[i] = uint256(keccak256(abi.encode(_RANDOMNESS_PLACEHOLDER, i)));
                }
                data = abi.encodeWithSelector(this.rawFulfillRandomWords.selector, requestId, randomWords);
            } else if (requestType == RequestType.Shuffling) {
                uint32 upper = abi.decode(params, (uint32));
                uint256[] memory arr = new uint256[](upper);
                for (uint256 k = 0; k < upper; k++) {
                    arr[k] = k;
                }
                data = abi.encodeWithSelector(this.rawFulfillShuffledArray.selector, requestId, arr);
            }

            // We don't want message call for estimating gas to take effect, therefore success should be false,
            // and result should be the reverted reason, which in fact is gas used we encoded to string.
            (bool success, bytes memory result) =
            // solhint-disable-next-line avoid-low-level-calls
             address(this).call(abi.encodeWithSelector(this.requiredTxGas.selector, address(this), 0, data));

            // This will be 0 if message call for callback fails,
            // we pass this message to tell user that callback implementation need to be checked.
            uint256 gasUsed = _parseGasUsed(result);

            require(!success && gasUsed != 0, "fulfillRandomness dry-run failed");

            callbackGasLimit = gasUsed + _GAS_FOR_CALLBACK_OVERHEAD;
        }
        return _rawRequestRandomness(
            requestType,
            params,
            IAdapter(adapter).getLastSubscription(address(this)),
            _USER_SEED_PLACEHOLDER,
            _DEFAULT_REQUEST_CONFIRMATIONS,
            callbackGasLimit,
            callbackMaxGasFee == 0 ? tx.gasprice * 3 : callbackMaxGasFee
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

contract RequestIdBase {
    function _makeRandcastInputSeed(uint256 _userSeed, address _requester, uint256 _nonce)
        internal
        pure
        returns (uint256)
    {
        return uint256(keccak256(abi.encode(_userSeed, _requester, _nonce)));
    }

    function _makeRequestId(uint256 inputSeed) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(inputSeed));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

// solhint-disable-next-line no-global-import
import "./StringAndUintConverter.sol" as StringAndUintConverter;

contract GasEstimationBase {
    /**
     * @notice Estimates gas used by actually calling that function then reverting with the gas used as string
     * @param to Destination address
     * @param value Ether value
     * @param data Data payload
     */
    function requiredTxGas(address to, uint256 value, bytes calldata data) external returns (uint256) {
        uint256 startGas = gasleft();
        // We don't provide an error message here, as we use it to return the estimate
        // solhint-disable-next-line reason-string
        require(_executeCall(to, value, data, gasleft()));
        uint256 requiredGas = startGas - gasleft();
        string memory s = StringAndUintConverter.uintToString(requiredGas);
        // Convert response to string and return via error message
        revert(s);
    }

    function _executeCall(address to, uint256 value, bytes memory data, uint256 txGas)
        internal
        returns (bool success)
    {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            success := call(txGas, to, value, add(data, 0x20), mload(data), 0, 0)
        }
    }

    /**
     * @notice Parses the gas used from the revert msg
     * @param _returnData the return data of requiredTxGas
     */
    function _parseGasUsed(bytes memory _returnData) internal pure returns (uint256) {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return 0; //"Transaction reverted silently";

        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        return StringAndUintConverter.stringToUint(abi.decode(_returnData, (string))); // All that remains is the revert string
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

import {IAdapter, IRequestTypeBase} from "../interfaces/IAdapter.sol";

/**
 * @notice Interface for contracts using VRF randomness.
 * @notice Extends this and overrides particular fulfill callback function to use randomness safely.
 */
abstract contract BasicRandcastConsumerBase is IRequestTypeBase {
    address public immutable adapter;
    // Nonce on the user's side(count from 1) for generating real requestId,
    // which should be identical to the nonce on adapter's side, or it will be pointless.
    uint256 public nonce = 1;
    // Ignore fulfilling from adapter check during fee estimation.
    bool private _isEstimatingCallbackGasLimit;

    modifier calculateCallbackGasLimit() {
        _isEstimatingCallbackGasLimit = true;
        _;
        _isEstimatingCallbackGasLimit = false;
    }

    constructor(address _adapter) {
        adapter = _adapter;
    }

    // solhint-disable-next-line no-empty-blocks
    function _fulfillRandomness(bytes32 requestId, uint256 randomness) internal virtual {}
    // solhint-disable-next-line no-empty-blocks
    function _fulfillRandomWords(bytes32 requestId, uint256[] memory randomWords) internal virtual {}
    // solhint-disable-next-line no-empty-blocks
    function _fulfillShuffledArray(bytes32 requestId, uint256[] memory shuffledArray) internal virtual {}

    function _rawRequestRandomness(
        RequestType requestType,
        bytes memory params,
        uint64 subId,
        uint256 seed,
        uint16 requestConfirmations,
        uint256 callbackGasLimit,
        uint256 callbackMaxGasPrice
    ) internal returns (bytes32) {
        nonce = nonce + 1;

        IAdapter.RandomnessRequestParams memory p = IAdapter.RandomnessRequestParams(
            requestType, params, subId, seed, requestConfirmations, callbackGasLimit, callbackMaxGasPrice
        );

        return IAdapter(adapter).requestRandomness(p);
    }

    function rawFulfillRandomness(bytes32 requestId, uint256 randomness) external {
        require(_isEstimatingCallbackGasLimit || msg.sender == adapter, "Only adapter can fulfill");
        _fulfillRandomness(requestId, randomness);
    }

    function rawFulfillRandomWords(bytes32 requestId, uint256[] memory randomWords) external {
        require(_isEstimatingCallbackGasLimit || msg.sender == adapter, "Only adapter can fulfill");
        _fulfillRandomWords(requestId, randomWords);
    }

    function rawFulfillShuffledArray(bytes32 requestId, uint256[] memory shuffledArray) external {
        require(_isEstimatingCallbackGasLimit || msg.sender == adapter, "Only adapter can fulfill");
        _fulfillShuffledArray(requestId, shuffledArray);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

function uintToString(uint256 v) pure returns (string memory str) {
    uint256 maxlength = 100;
    bytes memory reversed = new bytes(maxlength);
    uint256 i = 0;
    while (v != 0) {
        uint256 remainder = v % 10;
        v = v / 10;
        reversed[i++] = bytes1(uint8(48 + remainder));
    }
    bytes memory s = new bytes(i + 1);
    for (uint256 j = 0; j <= i; j++) {
        s[j] = reversed[i - j];
    }
    str = string(s);
}

function stringToUint(string memory s) pure returns (uint256 result) {
    bytes memory b = bytes(s);
    uint256 i;
    result = 0;
    for (i = 0; i < b.length; i++) {
        uint256 c = uint256(uint8(b[i]));
        if (c >= 48 && c <= 57) {
            result = result * 10 + (c - 48);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

import {IRequestTypeBase} from "./IRequestTypeBase.sol";

interface IAdapter is IRequestTypeBase {
    struct PartialSignature {
        uint256 index;
        uint256 partialSignature;
    }

    struct RandomnessRequestParams {
        RequestType requestType;
        bytes params;
        uint64 subId;
        uint256 seed;
        uint16 requestConfirmations;
        uint256 callbackGasLimit;
        uint256 callbackMaxGasPrice;
    }

    struct RequestDetail {
        uint64 subId;
        uint256 groupIndex;
        RequestType requestType;
        bytes params;
        address callbackContract;
        uint256 seed;
        uint16 requestConfirmations;
        uint256 callbackGasLimit;
        uint256 callbackMaxGasPrice;
        uint256 blockNum;
    }

    // controller transaction
    function nodeWithdrawETH(address recipient, uint256 ethAmount) external;

    // consumer contract transaction
    function requestRandomness(RandomnessRequestParams calldata params) external returns (bytes32);

    function fulfillRandomness(
        uint256 groupIndex,
        bytes32 requestId,
        uint256 signature,
        RequestDetail calldata requestDetail,
        PartialSignature[] calldata partialSignatures
    ) external;

    // user transaction
    function createSubscription() external returns (uint64);

    function addConsumer(uint64 subId, address consumer) external;

    function fundSubscription(uint64 subId) external payable;

    function setReferral(uint64 subId, uint64 referralSubId) external;

    function cancelSubscription(uint64 subId, address to) external;

    function removeConsumer(uint64 subId, address consumer) external;

    // view
    function getLastSubscription(address consumer) external view returns (uint64);

    function getSubscription(uint64 subId)
        external
        view
        returns (uint256 balance, uint256 inflightCost, uint64 reqCount, address owner, address[] memory consumers);

    function getPendingRequestCommitment(bytes32 requestId) external view returns (bytes32);

    function getLastRandomness() external view returns (uint256);

    function getRandomnessCount() external view returns (uint256);

    /*
     * @notice Compute fee based on the request count
     * @param reqCount number of requests
     * @return feePPM fee in ARPA PPM
     */
    function getFeeTier(uint64 reqCount) external view returns (uint32);

    // Estimate the amount of gas used for fulfillment
    function estimatePaymentAmountInETH(
        uint256 callbackGasLimit,
        uint256 gasExceptCallback,
        uint32 fulfillmentFlatFeeEthPPM,
        uint256 weiPerUnitGas
    ) external view returns (uint256);
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
pragma solidity >=0.8.10;

interface IRequestTypeBase {
    enum RequestType {
        Randomness,
        RandomWords,
        Shuffling
    }
}