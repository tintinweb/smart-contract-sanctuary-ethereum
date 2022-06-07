/**
 *Submitted for verification at Etherscan.io on 2022-06-07
*/

pragma solidity 0.8.13;

// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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

// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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

/**
 * @title IJob
 * @dev IJob contract
 * @author Federico Luzzi - <[email protected]>
 */
interface IJob {
    function workable() external view returns (bool, bytes memory);

    function work(bytes calldata _data) external;
}

/**
 * @title IERC20Permit
 * @dev IERC20Permit contract
 * @author Federico Luzzi - <[email protected]>
 */
interface IERC20Permit is IERC20 {
    function mint(address _to, uint256 _amount) external;

    function permit(
        address _owner,
        address _spender,
        uint256 _value,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;
}

/**
 * @title IMaster
 * @dev IMaster contract
 * @author Federico Luzzi - <[email protected]>
 */
interface IMaster {
    struct Worker {
        bool disallowed;
        uint256 bonded;
        uint256 earned;
        uint256 bonding;
        uint256 bondingBlock;
        uint256 unbonding;
        uint256 unbondingBlock;
    }

    struct WorkerInfo {
        address addrezz;
        bool disallowed;
        uint256 bonded;
        uint256 earned;
        uint256 bonding;
        uint256 bondingBlock;
        uint256 unbonding;
        uint256 unbondingBlock;
    }

    struct Job {
        address addrezz;
        address owner;
        string specification;
        uint256 credit;
    }

    struct JobInfo {
        uint256 id;
        address addrezz;
        address owner;
        string specification;
        uint256 credit;
    }

    struct EnumerableJobSet {
        mapping(uint256 => Job) byId;
        mapping(address => uint256) idForAddress;
        mapping(address => uint256[]) byOwner;
        uint256[] keys;
        uint256 ids;
    }

    struct EnumerableWorkerSet {
        mapping(address => Worker) byAddress;
        address[] keys;
    }

    function bond(uint256 _amount) external;

    function bondWithPermit(
        uint256 _amount,
        uint256 _permittedAmount, // can be used for infinite approvals
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;

    function consolidateBond() external;

    function cancelBonding() external;

    function unbond(uint256 _amount) external;

    function consolidateUnbonding() external;

    function cancelUnbonding() external;

    function slash(address _worker, uint256 _amount) external;

    function disallow(address _worker) external;

    function allowJobCreator(address _creator) external;

    function disallowJobCreator(address _creator) external;

    function addJob(
        address _address,
        address _owner,
        string calldata _specification
    ) external;

    function upgradeJob(
        uint256 _id,
        address _newJob,
        string calldata _newSpecification
    ) external;

    function removeJob(uint256 _id) external;

    function addCredit(uint256 _id) external payable;

    function removeCredit(uint256 _id, uint256 _amount) external;

    function workable(address _worker, uint256 _jobId)
        external
        view
        returns (bool, bytes memory);

    function work(uint256 _id, bytes calldata _data) external;

    function setFee(uint16 _fee) external;

    function setBonus(uint16 _bonus) external;

    function setAssignedTurnBlocks(uint32 _assignedTurnBlocks) external;

    function setCompetitiveTurnBlocks(uint32 _competitiveTurnBlocks) external;

    function setStakableToken(address _stakableToken) external;

    function setFeeReceiver(address _feeReceiver) external;

    function setBondingBlocks(uint32 _bondingBlocks) external;

    function setUnbondingBlocks(uint32 _unbondingBlocks) external;

    function totalBonded() external view returns (uint256);

    function epochCheckpoint() external view returns (uint256);

    function bondingBlocks() external view returns (uint32);

    function unbondingBlocks() external view returns (uint32);

    function fee() external view returns (uint16);

    function assignedTurnBlocks() external view returns (uint32);

    function competitiveTurnBlocks() external view returns (uint32);

    function stakableToken() external view returns (address);

    function feeReceiver() external view returns (address);

    function jobsCreator(address _jobsCreator) external view returns (bool);

    function workersAmount() external view returns (uint256);

    function worker(address _address) external view returns (WorkerInfo memory);

    function workersSlice(uint256 _fromIndex, uint256 _toIndex)
        external
        view
        returns (WorkerInfo[] memory);

    function jobsAmount() external view returns (uint256);

    function job(uint256 _id) external view returns (JobInfo memory);

    function jobsSlice(uint256 _fromIndex, uint256 _toIndex)
        external
        view
        returns (JobInfo[] memory);

    function jobsOfOwner(address _owner)
        external
        view
        returns (JobInfo[] memory);
}

/**
 * @title ArrayManagement
 * @dev ArrayManagement library
 * @author Federico Luzzi - <[email protected]>
 */
library ArrayManagement {
    // uint arrays

    function add(uint256[] storage _self, uint256 _added) external {
        _self.push(_added);
    }

    function remove(uint256[] storage _self, uint256 _removed) external {
        uint256[] memory _memoryArray = _self;
        uint256 _arrayLength = _memoryArray.length;
        for (uint256 _i = 0; _i < _arrayLength; _i++) {
            if (_memoryArray[_i] == _removed) {
                if (_arrayLength > 1 && _i < _arrayLength - 1)
                    _self[_i] = _self[_arrayLength - 1];
                _self.pop();
                return;
            }
        }
    }

    // address arrays

    function add(address[] storage _self, address _added) external {
        _self.push(_added);
    }

    function remove(address[] storage _self, address _removed) external {
        address[] memory _memoryArray = _self;
        uint256 _arrayLength = _memoryArray.length;
        for (uint256 _i = 0; _i < _arrayLength; _i++) {
            if (_memoryArray[_i] == _removed) {
                if (_arrayLength > 1 && _i < _arrayLength - 1)
                    _self[_i] = _self[_arrayLength - 1];
                _self.pop();
                return;
            }
        }
    }
}

/**
 * @title Master
 * @dev Master contract
 * @author Federico Luzzi - <[email protected]>
 * SPDX-License-Identifier: GPL-3.0
 */
// TODO: implement way to add job and add credit at the same time
// FIXME: make sure workers can only be activated at the start of a turn in
// order not to mess up any off-chain turn calculation
// FIXME: might want to add an hardcoded maximum limit to the bonding blocks
contract Master is IMaster, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using ArrayManagement for uint256[];
    using ArrayManagement for address[];

    uint16 public fee;
    uint16 public bonus;
    uint32 public assignedTurnBlocks;
    uint32 public competitiveTurnBlocks;
    uint32 public bondingBlocks;
    uint32 public unbondingBlocks;
    address public feeReceiver;
    address public stakableToken;
    EnumerableJobSet internal jobs;
    EnumerableWorkerSet internal workers;
    mapping(address => bool) public jobsCreator;
    uint256 public totalBonded;
    uint256 public epochCheckpoint;

    uint256 private immutable BASE = 10000;

    error InvalidFee();
    error InvalidSpecification();
    error InvalidAssignedTurnBlocks();
    error InvalidCompetitiveTurnBlocks();
    error ZeroAddressStakableToken();
    error ZeroAddressFeeReceiver();
    error ZeroAddressJobsCreator();
    error NonExistentJob();
    error InconsistentUpgrade();
    error ZeroAddressJob();
    error ZeroAddressOwner();
    error ZeroAddressNewJob();
    error NotAWorker();
    error InvalidTurn();
    error InvalidUnbondingBlocks();
    error InvalidBondingBlocks();
    error NotEnoughBonded();
    error NotBonding();
    error NotUnbonding();
    error Forbidden();
    error NothingToConsolidate();
    error Disallowed();
    error InvalidIndices();
    error InvalidAmount();
    error InvalidBonus();
    error NotEnoughCredit();

    constructor(
        address _stakableToken,
        uint32 _bondingBlocks,
        uint32 _unbondingBlocks,
        uint16 _fee,
        uint16 _bonus,
        uint32 _assignedTurnBlocks,
        uint32 _competitiveTurnBlocks,
        address _feeReceiver
    ) {
        if (_stakableToken == address(0)) revert ZeroAddressStakableToken();
        if (
            _unbondingBlocks == 0 ||
            _unbondingBlocks < _assignedTurnBlocks + _competitiveTurnBlocks
        ) revert InvalidUnbondingBlocks();
        if (_bondingBlocks == 0) revert InvalidBondingBlocks();
        if (_fee >= BASE) revert InvalidFee();
        if (_bonus == 0) revert InvalidBonus();
        if (_assignedTurnBlocks == 0) revert InvalidAssignedTurnBlocks();
        if (_competitiveTurnBlocks == 0) revert InvalidCompetitiveTurnBlocks();
        if (_feeReceiver == address(0)) revert ZeroAddressFeeReceiver();
        stakableToken = _stakableToken;
        bondingBlocks = _bondingBlocks;
        unbondingBlocks = _unbondingBlocks;
        fee = _fee;
        bonus = _bonus;
        assignedTurnBlocks = _assignedTurnBlocks;
        competitiveTurnBlocks = _competitiveTurnBlocks;
        epochCheckpoint = block.number;
        feeReceiver = _feeReceiver;
    }

    function bond(uint256 _amount) external override {
        _bond(_amount);
    }

    function bondWithPermit(
        uint256 _amount,
        uint256 _permittedAmount, // can be used for infinite approvals
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external override {
        IERC20Permit(stakableToken).permit(
            msg.sender,
            address(this),
            _permittedAmount,
            block.timestamp,
            _v,
            _r,
            _s
        );
        _bond(_amount);
    }

    // FIXME: is 0-bonding allowed?
    function _bond(uint256 _amount) internal {
        if (_amount == 0) revert InvalidAmount();
        Worker storage _worker = workers.byAddress[msg.sender];
        if (_worker.disallowed) revert Disallowed();
        uint256 _bondingBlocks = bondingBlocks; // gas savings
        if (_bondingBlocks == 0) {
            unchecked {
                totalBonded += _amount;
                if (_worker.bonded == 0) workers.keys.add(msg.sender);
                _worker.bonded += _amount;
            }
        } else {
            unchecked {
                _worker.bonding += _amount;
                _worker.bondingBlock = block.number + _bondingBlocks;
            }
        }
        IERC20(stakableToken).safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );
    }

    function consolidateBond() external override {
        Worker storage _worker = workers.byAddress[msg.sender];
        if (_worker.disallowed) revert Disallowed();
        uint256 _bonding = _worker.bonding;
        if (_bonding == 0) revert NotBonding();
        if (_worker.bondingBlock > block.number) revert NothingToConsolidate();
        if (_worker.bonded == 0) workers.keys.add(msg.sender);
        unchecked {
            totalBonded += _bonding;
            _worker.bonded += _bonding;
            _worker.bonding = 0;
        }
    }

    function cancelBonding() external override {
        Worker storage _worker = workers.byAddress[msg.sender];
        if (_worker.disallowed) revert Disallowed();
        if (_worker.bonding == 0) revert NotBonding();
        uint256 _refundedAmount = _worker.bonding;
        _worker.bonding = 0;
        IERC20(stakableToken).safeTransfer(msg.sender, _refundedAmount);
    }

    // FIXME: imagine a worker wants to stop working but has to wait
    // until the unbonding is consolidated in order to turn off the
    // Jolt node. An idea could be to remove the worker from the pool
    // as soon as he unbonds all. If a bonding happens after that,
    // and before the unbonding is consolidated, he can be added again.
    function unbond(uint256 _amount) external override {
        Worker storage _worker = workers.byAddress[msg.sender];
        if (_worker.disallowed) revert Disallowed();
        if (_worker.bonded - _worker.unbonding < _amount)
            revert NotEnoughBonded();
        _worker.unbonding += _amount;
        _worker.unbondingBlock = block.number + unbondingBlocks;
    }

    function consolidateUnbonding() external override {
        Worker storage _worker = workers.byAddress[msg.sender];
        if (_worker.disallowed) revert Disallowed();
        uint256 _unbonding = _worker.unbonding;
        if (_unbonding == 0) revert NotUnbonding();
        if (_worker.unbondingBlock > block.number)
            revert NothingToConsolidate();
        unchecked {
            totalBonded -= _unbonding;
            _worker.bonded -= _unbonding;
            _worker.unbonding = 0;
        }
        if (_worker.bonded == 0) {
            delete workers.byAddress[msg.sender];
            workers.keys.remove(msg.sender);
        }
        IERC20(stakableToken).safeTransfer(msg.sender, _unbonding);
    }

    function cancelUnbonding() external override {
        Worker storage _worker = workers.byAddress[msg.sender];
        if (_worker.disallowed) revert Disallowed();
        if (_worker.unbonding == 0) revert NotUnbonding();
        _worker.unbonding = 0;
    }

    function slash(address _address, uint256 _amount) external override {
        if (_amount == 0) revert InvalidAmount();
        if (msg.sender != owner()) revert Forbidden();
        Worker memory _worker = workers.byAddress[_address];
        if (_worker.disallowed) revert Disallowed();
        if (_worker.bonded < _amount) revert NotEnoughBonded();
        unchecked {
            workers.byAddress[_address].bonded -= _amount;
            totalBonded -= _amount;
        }
    }

    // FIXME: should we do something with the slashed/lost native currency?
    // It currently just sits in the contract, locked forever
    function disallow(address _address) external override {
        if (msg.sender != owner()) revert Forbidden();
        Worker storage _worker = workers.byAddress[_address];
        if (_worker.disallowed) revert Disallowed();
        if (_worker.bonded == 0) revert NotAWorker();
        unchecked {
            totalBonded -= _worker.bonded;
        }
        delete workers.byAddress[_address];
        _worker.disallowed = true;
    }

    function allowJobCreator(address _creator) external override {
        if (msg.sender != owner()) revert Forbidden();
        if (_creator == address(0)) revert ZeroAddressJobsCreator();
        jobsCreator[_creator] = true;
    }

    function disallowJobCreator(address _creator) external override {
        if (msg.sender != owner()) revert Forbidden();
        jobsCreator[_creator] = false;
    }

    function addJob(
        address _address,
        address _owner,
        string calldata _specification
    ) external override {
        if (_address == address(0)) revert ZeroAddressJob();
        if (_owner == address(0)) revert ZeroAddressOwner();
        bool _fromJobCreator = jobsCreator[msg.sender];
        if (msg.sender != owner() && !_fromJobCreator) revert Forbidden();
        if (!_fromJobCreator && bytes(_specification).length == 0)
            revert InvalidSpecification();
        uint256 _id = ++jobs.ids; // 0 is never used
        Job storage _job = jobs.byId[_id];
        _job.addrezz = _address;
        _job.owner = _owner;
        _job.specification = _specification;
        jobs.idForAddress[_address] = _id;
        jobs.byOwner[_owner].add(_id);
        jobs.keys.add(_id);
    }

    function upgradeJob(
        uint256 _id,
        address _newAddress,
        string calldata _newSpecification
    ) external override {
        if (_newAddress == address(0)) revert ZeroAddressNewJob();
        if (bytes(_newSpecification).length == 0) revert InvalidSpecification();
        if (msg.sender != owner()) revert Forbidden();
        Job storage _job = jobs.byId[_id];
        if (_job.addrezz == address(0)) revert NonExistentJob();
        if (_job.addrezz == _newAddress) revert InconsistentUpgrade();
        _job.addrezz = _newAddress;
        _job.specification = _newSpecification;
    }

    // TODO: make it possible for jobs themselves to unsubscribe
    // if their role has become useless
    // TODO: make it possible for jobs to specify if they're
    // upgradeable or not at creation (Carrot use case, where the job ownership
    // is given to the KPI token creator in order to refund any credit, but no upgrade can happen)
    function removeJob(uint256 _id) external override nonReentrant {
        if (msg.sender != owner()) revert Forbidden();
        Job storage _job = jobs.byId[_id];
        address _jobOwner = _job.owner;
        if (_jobOwner == address(0)) revert NonExistentJob();
        if (_job.credit > 0) address(_jobOwner).call{value: _job.credit}("");
        delete jobs.idForAddress[_job.addrezz];
        delete jobs.byId[_id];
        jobs.byOwner[_jobOwner].remove(_id);
        jobs.keys.remove(_id);
    }

    function addCredit(uint256 _id) external payable override {
        if (msg.value == 0) revert NotEnoughCredit();
        Job storage _job = jobs.byId[_id];
        if (_job.owner == address(0)) revert NonExistentJob();
        uint256 _fee = (msg.value * fee) / BASE;
        _job.credit += msg.value - _fee;
        feeReceiver.call{value: _fee}("");
    }

    function removeCredit(uint256 _id, uint256 _amount) external {
        Job storage _job = jobs.byId[_id];
        if (msg.sender != _job.owner) revert Forbidden();
        _job.credit -= _amount;
        msg.sender.call{value: _amount}("");
    }

    // FIXME: when a worker is removed, keys are updated in such a way that the last
    // worker overwrites the deleted element. This makes the last worker change
    // indexes occasionally. Can this be an issue?
    function _turnInfo()
        internal
        view
        returns (
            bool,
            uint256,
            uint256
        )
    {
        unchecked {
            uint32 _assignedTurnBlocks = assignedTurnBlocks; // gas savings
            uint32 _competitiveTurnBlocks = competitiveTurnBlocks; // gas savings
            uint256 _epochCheckpoint = epochCheckpoint; // gas savings
            uint64 _fullTurnBlocks = uint64(
                _assignedTurnBlocks + _competitiveTurnBlocks
            );
            uint256 _fullTurnIndex = uint256(
                (block.number - _epochCheckpoint) / _fullTurnBlocks
            );
            uint256 _firstBlockInTurn = _epochCheckpoint +
                (_fullTurnIndex * _fullTurnBlocks);
            return (
                block.number - _firstBlockInTurn < _assignedTurnBlocks,
                _fullTurnIndex,
                _firstBlockInTurn
            );
        }
    }

    function _workerIndex(
        uint256 _turnIndex,
        uint256 _firstBlockInTurn,
        uint256 _jobId,
        uint256 _workersAmount
    ) internal view returns (uint256) {
        unchecked {
            return
                (_turnIndex +
                    _jobId +
                    uint256(blockhash(_firstBlockInTurn - 1))) % _workersAmount;
        }
    }

    function workable(address _worker, uint256 _jobId)
        external
        view
        override
        returns (bool, bytes memory)
    {
        Job storage _job = jobs.byId[_jobId];
        Job memory _memoryJob = _job; // gas savings
        if (_memoryJob.owner == address(0)) return (false, bytes(""));
        if (workers.byAddress[_worker].bonded == 0) return (false, bytes(""));
        (
            bool _assignedTurn,
            uint256 _turnIndex,
            uint256 _firstBlockInTurn
        ) = _turnInfo();
        if (_assignedTurn) {
            address[] memory _workerKeys = workers.keys; // gas savings
            if (
                _worker !=
                _workerKeys[
                    _workerIndex(
                        _turnIndex,
                        _firstBlockInTurn,
                        _jobId,
                        _workerKeys.length
                    )
                ]
            ) return (false, bytes(""));
        }
        return IJob(_memoryJob.addrezz).workable();
    }

    function work(uint256 _id, bytes calldata _data) external override {
        uint256 _gasCheckpoint = gasleft(); // even turn validation should be paid out to workers
        Job storage _job = jobs.byId[_id];
        Job memory _memoryJob = _job; // gas savings
        if (_memoryJob.owner == address(0)) revert NonExistentJob();
        if (workers.byAddress[msg.sender].bonded == 0) revert NotAWorker();
        (
            bool _assignedTurn,
            uint256 _turnIndex,
            uint256 _firstBlockInTurn
        ) = _turnInfo();
        Worker storage _worker = workers.byAddress[msg.sender];
        if (_worker.bonded == 0) revert NotAWorker();
        if (_worker.disallowed) revert Disallowed();
        if (_assignedTurn) {
            address[] memory _workerKeys = workers.keys; // gas savings
            if (
                msg.sender !=
                _workerKeys[
                    _workerIndex(
                        _turnIndex,
                        _firstBlockInTurn,
                        _id,
                        _workerKeys.length
                    )
                ]
            ) revert InvalidTurn();
        }
        IJob(_memoryJob.addrezz).work(_data);
        uint256 _usedGas = _gasCheckpoint - gasleft(); // FIXME: calculate bonus on spent gas
        uint256 _usedCredit = _usedGas + ((_usedGas * bonus) / BASE);
        _job.credit -= _usedCredit;
        totalBonded += _usedCredit;
        _worker.bonded += _usedCredit;
        _worker.earned += _usedCredit;
    }

    function jobsOfOwner(address _owner)
        external
        view
        override
        returns (JobInfo[] memory)
    {
        uint256[] memory _jobIds = jobs.byOwner[_owner];
        uint256 _jobsAmount = _jobIds.length;
        JobInfo[] memory _jobs = new JobInfo[](_jobsAmount);
        for (uint256 _i = 0; _i < _jobsAmount; _i++) {
            uint256 _jobId = _jobIds[_i];
            Job memory _job = jobs.byId[_jobId];
            _jobs[_i] = JobInfo({
                id: _jobId,
                addrezz: _job.addrezz,
                owner: _job.owner,
                specification: _job.specification,
                credit: _job.credit
            });
        }
        return _jobs;
    }

    function workersAmount() external view override returns (uint256) {
        return workers.keys.length;
    }

    // TODO: in case the worker is non-existent, should we make addrezz the 0 address?
    function worker(address _address)
        external
        view
        override
        returns (WorkerInfo memory)
    {
        Worker memory _worker = workers.byAddress[_address];
        return
            WorkerInfo({
                addrezz: _address,
                disallowed: _worker.disallowed,
                bonded: _worker.bonded,
                earned: _worker.earned,
                bonding: _worker.bonding,
                bondingBlock: _worker.bondingBlock,
                unbonding: _worker.unbonding,
                unbondingBlock: _worker.unbondingBlock
            });
    }

    function workersSlice(uint256 _fromIndex, uint256 _toIndex)
        external
        view
        override
        returns (WorkerInfo[] memory)
    {
        if (_toIndex > workers.keys.length || _fromIndex > _toIndex)
            revert InvalidIndices();
        uint256 _range = _toIndex - _fromIndex;
        WorkerInfo[] memory _workerInfos = new WorkerInfo[](_range);
        for (uint256 _i = _fromIndex; _i < _fromIndex + _range; _i++) {
            address _workerAddress = workers.keys[_i];
            Worker memory _worker = workers.byAddress[_workerAddress];
            _workerInfos[_i] = WorkerInfo({
                addrezz: _workerAddress,
                disallowed: _worker.disallowed,
                bonded: _worker.bonded,
                earned: _worker.earned,
                bonding: _worker.bonded,
                bondingBlock: _worker.bondingBlock,
                unbonding: _worker.unbonding,
                unbondingBlock: _worker.unbondingBlock
            });
        }
        return _workerInfos;
    }

    function jobsAmount() external view override returns (uint256) {
        return jobs.keys.length;
    }

    function job(uint256 _id) external view override returns (JobInfo memory) {
        Job memory _job = jobs.byId[_id];
        return
            JobInfo({
                id: _id,
                addrezz: _job.addrezz,
                owner: _job.owner,
                specification: _job.specification,
                credit: _job.credit
            });
    }

    function jobsSlice(uint256 _fromIndex, uint256 _toIndex)
        external
        view
        override
        returns (JobInfo[] memory)
    {
        if (_toIndex > workers.keys.length || _fromIndex > _toIndex)
            revert InvalidIndices();
        uint256 _range = _toIndex - _fromIndex;
        JobInfo[] memory _jobInfos = new JobInfo[](_range);
        for (uint256 _i = _fromIndex; _i < _fromIndex + _range; _i++) {
            uint256 _jobId = jobs.keys[_i];
            Job memory _job = jobs.byId[_jobId];
            _jobInfos[_i] = JobInfo({
                id: _jobId,
                addrezz: _job.addrezz,
                owner: _job.owner,
                specification: _job.specification,
                credit: _job.credit
            });
        }
        return _jobInfos;
    }

    function setFee(uint16 _fee) external override {
        if (msg.sender != owner()) revert Forbidden();
        if (_fee >= BASE) revert InvalidFee();
        fee = _fee;
    }

    function setBonus(uint16 _bonus) external override {
        if (msg.sender != owner()) revert Forbidden();
        if (_bonus == 0) revert InvalidBonus();
        bonus = _bonus;
    }

    // FIXME: apply new assigned blocks starting from next turn
    function setAssignedTurnBlocks(uint32 _assignedTurnBlocks)
        external
        override
    {
        if (msg.sender != owner()) revert Forbidden();
        if (
            _assignedTurnBlocks == 0 ||
            _assignedTurnBlocks < competitiveTurnBlocks
        ) revert InvalidAssignedTurnBlocks();
        epochCheckpoint = block.number;
        assignedTurnBlocks = _assignedTurnBlocks;
    }

    // FIXME: apply new competitive blocks starting from next turn
    function setCompetitiveTurnBlocks(uint32 _competitiveTurnBlocks)
        external
        override
    {
        if (msg.sender != owner()) revert Forbidden();
        if (
            _competitiveTurnBlocks == 0 ||
            _competitiveTurnBlocks > assignedTurnBlocks
        ) revert InvalidCompetitiveTurnBlocks();
        epochCheckpoint = block.number;
        competitiveTurnBlocks = _competitiveTurnBlocks;
    }

    function setFeeReceiver(address _feeReceiver) external override {
        if (msg.sender != owner()) revert Forbidden();
        if (_feeReceiver == address(0)) revert ZeroAddressFeeReceiver();
        feeReceiver = _feeReceiver;
    }

    function setBondingBlocks(uint32 _bondingBlocks) external override {
        if (msg.sender != owner()) revert Forbidden();
        bondingBlocks = _bondingBlocks;
    }

    function setUnbondingBlocks(uint32 _unbondingBlocks) external override {
        if (msg.sender != owner()) revert Forbidden();
        if (_unbondingBlocks < assignedTurnBlocks + competitiveTurnBlocks)
            revert InvalidUnbondingBlocks();
        unbondingBlocks = _unbondingBlocks;
    }

    function setStakableToken(address _token) external override {
        if (msg.sender != owner()) revert Forbidden();
        if (_token == address(0)) revert ZeroAddressStakableToken();
        stakableToken = _token;
    }
}