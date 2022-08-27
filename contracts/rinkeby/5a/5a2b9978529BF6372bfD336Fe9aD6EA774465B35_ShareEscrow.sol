// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {IERC20Upgradeable as IERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {SignatureDecoder} from "./libraries/SignatureDecoder.sol";

/// All possible states for a task
enum Status {
    None,
    Inactive,
    Active,
    InDispute,
    Complete,
    Cancel
}

enum SignatureFunction {
    AssignTask,
    CancelTask,
    CompleteTasks
}

/// Stores all task related information
struct Task {
    Status status;
    address reviewer;
    address token;
    address contributor;
    uint256 amount;
    uint256 fee;
}

error InvalidData();
error InvalidSignature();
error NoChange();
error InvalidFee();
error InvalidAddress();
error ArgumentLengthMismatch();
error InvalidTaskAmount();
error OnlyArbitrator();
error OnlyReviewerOrContributor();
error InvalidStatus(Status got, Status expected);

contract ShareEscrow is OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20;

    /// Share treasury. Must not be address(0).
    address public treasury;

    /// Share arbitrator. Must not be address(0).
    address public arbitrator;

    /// Share fee percent in ppm. Must be >= 0 & < PPM_DIVISOR.
    uint256 public shareFee;

    /// Task count.
    uint256 public taskCount;

    uint256 internal constant PPM_DIVISOR = 1_000_000;

    /// Tasks mapping. Starts from task id 0.
    mapping(uint256 => Task) public tasks;

    mapping(address => mapping(bytes32 => bool)) public approvedHashes;

    event CreateTasks(
        uint256 taskCount,
        address indexed reviewer,
        address indexed token,
        uint256[] amountList,
        bytes[] offchainDetailsList
    );
    event AssignTask(uint256 indexed taskId, address indexed _contributor, bytes _offchainDetails);
    event CompleteTasks(uint256[] taskIdList, bytes[] offchainDetailsList);
    event CancelTask(uint256 indexed taskId, bytes offchainDetails);
    event RaiseDispute(uint256 indexed taskId, address indexed sender, bytes offchainDetails);
    event ResolveDispute(uint256 indexed taskId, uint8 indexed disputeDecision, bytes offchainDetails);
    event ApproveHash(bytes32 hash, address signer);
    event ChangeShareFee(uint256 indexed newShareFee);
    event ChangeTreasury(address indexed newTreasury);
    event ChangeArbitrator(address indexed newArbitrator);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        uint256 _shareFee,
        address _treasury,
        address _arbitrator
    ) external initializer {
        __Ownable_init();

        _nonZero(_treasury);
        _nonZero(_arbitrator);
        if (!(_shareFee < PPM_DIVISOR)) revert InvalidFee();

        shareFee = _shareFee;
        treasury = _treasury;
        arbitrator = _arbitrator;
    }

    /// @notice create multiple tasks with same reviewer and token.
    function createTasks(
        address _token,
        uint256[] calldata _amountList,
        bytes[] calldata _offchainDetailsList
    ) external {
        uint256 _loopLength = _amountList.length;

        if (_loopLength != _offchainDetailsList.length) revert ArgumentLengthMismatch();

        // Local instance of variable for gas saving.
        uint256 _shareFee = shareFee;
        uint256 _ppmDevisor = PPM_DIVISOR;

        uint256 _taskId = taskCount;
        uint256 _totalAmountWithFee;

        for (uint256 i; i < _loopLength; ) {
            if (_amountList[i] == 0) revert InvalidTaskAmount();

            uint256 _fee = (_amountList[i] * _shareFee) / _ppmDevisor;

            Task storage _task = tasks[_taskId];
            _task.reviewer = _msgSender();
            _task.token = _token;
            _task.amount = _amountList[i];
            _task.fee = _fee;
            _task.status = Status.Inactive;

            ++_taskId;
            _totalAmountWithFee += _amountList[i] + _fee;

            unchecked {
                ++i;
            }
        }

        taskCount = _taskId;

        emit CreateTasks(_taskId, _msgSender(), _token, _amountList, _offchainDetailsList);

        // --- NO INTERNAL STATE CHANGE MUST HAPPEN AFTER THIS ---

        // Transfer escrow amount and fee to this contract
        // _msgSender (reviewer) must have approved escrow amount + fee to this contract.
        IERC20(_token).safeTransferFrom(_msgSender(), address(this), _totalAmountWithFee);
    }

    function assignTask(bytes calldata _data, bytes calldata _signature) external {
        // Decode params from _data
        (
            SignatureFunction _decodedFunction,
            address _contractAddress,
            uint256 _chainId,
            uint256 _taskId,
            address _contributor,
            bytes memory _offchainDetails
        ) = abi.decode(_data, (SignatureFunction, address, uint256, uint256, address, bytes));

        _nonZero(_contributor);
        Task storage _task = tasks[_taskId];

        // Revert if task is active(contributor assigned) or none(task not exits).
        if (_task.status != Status.Inactive) revert InvalidStatus(_task.status, Status.Inactive);
        if (_task.reviewer == _contributor) revert InvalidAddress();

        _validateData(SignatureFunction.AssignTask, _decodedFunction, _contractAddress, _chainId);

        // Calculate hash from bytes
        bytes32 _hash = keccak256(_data);

        // Check reviewer signature
        _checkUserSignature(_task.reviewer, _hash, _signature, 0);

        // Check new contributor signature
        _checkUserSignature(_contributor, _hash, _signature, 1);

        // Set contributor
        _task.contributor = _contributor;

        // Set task as Active
        _task.status = Status.Active;

        emit AssignTask(_taskId, _contributor, _offchainDetails);
    }

    function completeTasks(bytes calldata _data, bytes calldata _signature) external {
        // Decode params from _data
        (
            SignatureFunction _decodedFunction,
            address _contractAddress,
            uint256 _chainId,
            uint256[] memory _taskIdList,
            bytes[] memory _offchainDetailsList
        ) = abi.decode(_data, (SignatureFunction, address, uint256, uint256[], bytes[]));

        _validateData(SignatureFunction.CompleteTasks, _decodedFunction, _contractAddress, _chainId);

        // Calculate hash from bytes
        bytes32 _hash = keccak256(_data);

        Task storage _firstTask = tasks[_taskIdList[0]];
        address _token = _firstTask.token;
        address _reviewer = _firstTask.reviewer;
        address _contributor = _firstTask.contributor;

        // Check reviewer signature
        _checkUserSignature(_reviewer, _hash, _signature, 0);

        // Check new contributor signature
        _checkUserSignature(_contributor, _hash, _signature, 1);

        // Revert if task is not active.
        if (_firstTask.status != Status.Active) revert InvalidStatus(_firstTask.status, Status.Active);

        uint256 _loopLength = _taskIdList.length;

        uint256 _totalFee = _firstTask.fee;
        uint256 _totalAmount = _firstTask.amount;

        _firstTask.status = Status.Complete;

        for (uint256 i = 1; i < _loopLength; ) {
            Task storage _task = tasks[_taskIdList[i]];

            // Make sure task token, reviewer and contributor are similar to decoded.
            if (_task.token != _firstTask.token || _task.reviewer != _reviewer || _task.contributor != _contributor) {
                revert InvalidData();
            }

            // Revert if task is not active.
            if (_task.status != Status.Active) revert InvalidStatus(_task.status, Status.Active);

            _totalFee += _task.fee;
            _totalAmount += _task.amount;

            // Set task status as complete
            _task.status = Status.Complete;

            unchecked {
                ++i;
            }
        }

        emit CompleteTasks(_taskIdList, _offchainDetailsList);

        // --- NO INTERNAL STATE CHANGE MUST HAPPEN AFTER THIS ---

        // Transfer fee to Share Treasury
        IERC20(_token).safeTransfer(treasury, _totalFee);

        // Transfer tokens to contributor
        IERC20(_token).safeTransfer(_contributor, _totalAmount);
    }

    function cancelTask(bytes calldata _data, bytes calldata _signature) external {
        // Decode params from _data
        (
            SignatureFunction _decodedFunction,
            address _contractAddress,
            uint256 _chainId,
            uint256 _taskId,
            bytes memory _offchainDetails
        ) = abi.decode(_data, (SignatureFunction, address, uint256, uint256, bytes));

        Task storage _task = tasks[_taskId];

        // Calculate hash from bytes
        bytes32 _hash = keccak256(_data);

        if (_task.contributor == address(0)) {
            // Revert if task is not Inactive.
            if (_task.status != Status.Inactive) revert InvalidStatus(_task.status, Status.Inactive);
        } else {
            // Revert if task is not Active.
            if (_task.status != Status.Active) revert InvalidStatus(_task.status, Status.Active);

            // Check new contributor signature
            _checkUserSignature(_task.contributor, _hash, _signature, 1);
        }

        _validateData(SignatureFunction.CancelTask, _decodedFunction, _contractAddress, _chainId);

        // Check reviewer signature
        _checkUserSignature(_task.reviewer, _hash, _signature, 0);

        // Cancel task
        _cancelTask(_taskId, _offchainDetails);
    }

    function raiseDispute(uint256 _taskId, bytes calldata _offchainDetails) external {
        Task storage _task = tasks[_taskId];

        // Only task's reviewer or contributor can raise dispute
        if (_msgSender() != _task.reviewer && _msgSender() != _task.contributor) revert OnlyReviewerOrContributor();

        // Revert if task is not Active
        if (_task.status != Status.Active) revert InvalidStatus(_task.status, Status.Active);

        // Set task status as InDispute
        _task.status = Status.InDispute;

        emit RaiseDispute(_taskId, _msgSender(), _offchainDetails);
    }

    /// @notice Resolve dispute by either cancelling or completing the task.
    /// @param _decision uint8 0 - to cancel and 1 - to complete the task
    function resolveDispute(
        uint256 _taskId,
        uint8 _decision,
        bytes calldata _offchainDetails
    ) external {
        Task storage _task = tasks[_taskId];

        // Only owner can resolve dispute
        if (_msgSender() != arbitrator) revert OnlyArbitrator();

        // Make sure task status is InDispute
        if (_task.status != Status.InDispute) revert InvalidStatus(_task.status, Status.InDispute);

        emit ResolveDispute(_taskId, _decision, _offchainDetails);

        if (_decision == 0) {
            // Cancel task
            _cancelTask(_taskId, _offchainDetails);
        } else if (_decision == 1) {
            uint256[] memory _taskIdList = new uint256[](1);
            bytes[] memory _offchainDetailsList = new bytes[](1);
            _taskIdList[0] = _taskId;
            _offchainDetailsList[0] = _offchainDetails;

            emit CompleteTasks(_taskIdList, _offchainDetailsList);

            // Set task status as complete
            _task.status = Status.Complete;

            // --- NO INTERNAL STATE CHANGE MUST HAPPEN AFTER THIS ---

            // Transfer fee to Share Treasury
            IERC20(_task.token).safeTransfer(treasury, _task.fee);

            // Transfer tokens to contributor
            IERC20(_task.token).safeTransfer(_task.contributor, _task.amount);
        } else {
            revert("Share: invalid decision");
        }
    }

    function approveHash(bytes32 _hash) external {
        // Allowing anyone to sign, as its hard to add restrictions here.
        // Store _hash as signed for _msgSender.
        approvedHashes[_msgSender()][_hash] = true;

        emit ApproveHash(_hash, _msgSender());
    }

    function changeShareFee(uint256 _newShareFee) external onlyOwner {
        if (shareFee == _newShareFee) revert NoChange();
        if (!(_newShareFee < PPM_DIVISOR)) revert InvalidFee();

        shareFee = _newShareFee;

        emit ChangeShareFee(_newShareFee);
    }

    function changeTreasury(address _newTreasury) external onlyOwner {
        _noChange(treasury, _newTreasury);
        _nonZero(_newTreasury);

        treasury = _newTreasury;

        emit ChangeTreasury(_newTreasury);
    }

    function changeArbitrator(address _newArbitrator) external onlyOwner {
        _noChange(arbitrator, _newArbitrator);
        _nonZero(_newArbitrator);

        arbitrator = _newArbitrator;

        emit ChangeArbitrator(_newArbitrator);
    }

    function _cancelTask(uint256 _taskId, bytes memory _offchainDetails) internal {
        Task storage _task = tasks[_taskId];

        // Set task status as Cancel
        _task.status = Status.Cancel;

        emit CancelTask(_taskId, _offchainDetails);

        // --- NO INTERNAL STATE CHANGE MUST HAPPEN AFTER THIS ---

        // Transfer tokens back to reviewer
        IERC20(_task.token).safeTransfer(_task.reviewer, _task.amount + _task.fee);
    }

    /**
     * @dev Internal function for checking signature validity
     * @dev Checks if the signature is approved or recovered
     * @dev Reverts if not.

     * @param _address address - address checked for validity
     * @param _hash bytes32 - hash for which the signature is recovered
     * @param _signature bytes - signatures
     * @param _signatureIndex uint256 - index at which the signature should be present
     */
    function _checkUserSignature(
        address _address,
        bytes32 _hash,
        bytes calldata _signature,
        uint256 _signatureIndex
    ) internal {
        address _recoveredSignature = SignatureDecoder.recoverKey(_hash, _signature, _signatureIndex);
        if (_recoveredSignature != _address && !approvedHashes[_address][_hash]) {
            revert InvalidSignature();
        }
        // delete approved hash
        delete approvedHashes[_address][_hash];
    }

    function _validateData(
        SignatureFunction _expectedFunction,
        SignatureFunction _decodedFunction,
        address _contractAddress,
        uint256 _chainId
    ) internal view {
        // Although checking function uint8 is not mandatory now for signature uniqueness, but still keeping it to future proof-
        // a function that may have same set of encoded data as an existing function.
        if (_expectedFunction != _decodedFunction || _contractAddress != address(this) || _chainId != block.chainid) {
            revert InvalidData();
        }
    }

    function _nonZero(address _address) internal pure {
        if (_address == address(0)) revert InvalidAddress();
    }

    function _noChange(address _old, address _new) internal pure {
        if (_old == _new) revert NoChange();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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

pragma solidity 0.8.16;

/**
 * @title SignatureDecoder
 
 * @notice Decodes signatures that a encoded as bytes
 */
library SignatureDecoder {
    /**
    * @dev Recovers address who signed the message

    * @param messageHash bytes32 - keccak256 hash of message
    * @param messageSignatures bytes - concatenated message signatures
    * @param pos uint256 - which signature to read

    * @return address - recovered address
    */
    function recoverKey(
        bytes32 messageHash,
        bytes memory messageSignatures,
        uint256 pos
    ) internal pure returns (address) {
        if (messageSignatures.length % 65 != 0) {
            return (address(0));
        }

        uint8 v;
        bytes32 r;
        bytes32 s;
        (v, r, s) = signatureSplit(messageSignatures, pos);

        // If the version is correct return the signer address
        if (v != 27 && v != 28) {
            return (address(0));
        } else {
            // solium-disable-next-line arg-overflow
            return ecrecover(toEthSignedMessageHash(messageHash), v, r, s);
        }
    }

    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
    * @dev Divides bytes signature into `uint8 v, bytes32 r, bytes32 s`.
    * @dev Make sure to perform a bounds check for @param pos, to avoid out of bounds access on @param signatures

    * @param pos which signature to read. A prior bounds check of this parameter should be performed, to avoid out of bounds access
    * @param signatures concatenated rsv signatures
    */
    function signatureSplit(bytes memory signatures, uint256 pos)
        internal
        pure
        returns (
            uint8 v,
            bytes32 r,
            bytes32 s
        )
    {
        // The signature format is a compact form of:
        //   {bytes32 r}{bytes32 s}{uint8 v}
        // Compact means, uint8 is not padded to 32 bytes.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let signaturePos := mul(0x41, pos)
            r := mload(add(signatures, add(signaturePos, 0x20)))
            s := mload(add(signatures, add(signaturePos, 0x40)))
            v := byte(0, mload(add(signatures, add(signaturePos, 0x60))))
        }

        // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
        if (v < 27) {
            v += 27;
        }
    }
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