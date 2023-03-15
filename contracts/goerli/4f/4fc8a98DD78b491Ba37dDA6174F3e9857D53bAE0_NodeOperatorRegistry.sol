// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./IWithdrawalManager.sol";
import "./WithdrawalManagerFactory.sol";

interface IEthStakingStrategy {
    function safeStaking() external view returns (address);

    function registry() external view returns (address);

    function depositContract() external view returns (address);

    function deposit(uint256 amount) external;
}

contract NodeOperatorRegistry is Ownable {
    event OperatorAdded(uint256 indexed id, string name, address operatorOwner);
    event OperatorOwnerUpdated(uint256 indexed id, address newOperatorOwner);
    event RewardAddressUpdated(uint256 indexed id, address newRewardAddress);
    event VerifiedCountUpdated(uint256 indexed id, uint256 newVerifiedCount);
    event DepositLimitUpdated(uint256 indexed id, uint256 newDepositLimit);
    event KeyAdded(uint256 indexed id, bytes pubkey, uint256 index);
    event KeyUsed(uint256 indexed id, uint256 count);
    event KeyTruncated(uint256 indexed id, uint256 newTotalCount);
    event StrategyUpdated(address newStrategy);

    /// @notice Statistics of validator pubkeys from a node operator.
    /// @param totalCount Total number of validator pubkeys uploaded to this contract
    /// @param usedCount Number of validator pubkeys that are already used
    /// @param verifiedCount Number of validator pubkeys that are verified by the contract owner
    /// @param depositLimit Maximum number of usable validator pubkeys, set by the node operator
    struct KeyStat {
        uint64 totalCount;
        uint64 usedCount;
        uint64 verifiedCount;
        uint64 depositLimit;
    }

    /// @notice Node operator parameters and internal state
    /// @param operatorOwner Admin address of the node operator
    /// @param name Human-readable name
    /// @param withdrawalAddress Address receiving withdrawals and execution layer rewards
    /// @param rewardAddress Address receiving performance rewards
    struct Operator {
        address operatorOwner;
        string name;
        address rewardAddress;
        address withdrawalAddress;
        KeyStat keyStat;
    }

    struct Key {
        bytes32 pubkey0;
        bytes32 pubkey1; // Only the higher 16 bytes of the second slot are used
        bytes32 signature0;
        bytes32 signature1;
        bytes32 signature2;
    }

    uint256 private constant PUBKEY_LENGTH = 48;
    uint256 private constant SIGNATURE_LENGTH = 96;

    WithdrawalManagerFactory public immutable factory;

    address public strategy;

    /// @notice Number of node operators.
    uint256 public operatorCount;

    /// @dev Mapping of node operator ID => node operator.
    mapping(uint256 => Operator) private _operators;

    /// @dev Mapping of node operator ID => index => validator pubkey and deposit signature.
    mapping(uint256 => mapping(uint256 => Key)) private _keys;

    uint256 public registryVersion;

    constructor(address strategy_, address withdrawalManagerFactory_) public {
        _updateStrategy(strategy_);
        factory = WithdrawalManagerFactory(withdrawalManagerFactory_);
    }

    function initialize(address oldRegistry) external onlyOwner {
        require(operatorCount == 0);

        operatorCount = NodeOperatorRegistry(oldRegistry).operatorCount();
        for (uint256 i = 0; i < operatorCount; i++) {
            Operator memory operator = NodeOperatorRegistry(oldRegistry).getOperator(i);
            operator.operatorOwner = msg.sender;
            uint64 usedCount = operator.keyStat.usedCount;
            operator.keyStat.totalCount = usedCount;
            operator.keyStat.verifiedCount = usedCount;
            _operators[i] = operator;
            emit OperatorAdded(i, operator.name, msg.sender);
            if (operator.rewardAddress != msg.sender) {
                emit RewardAddressUpdated(i, operator.rewardAddress);
            }
            emit DepositLimitUpdated(i, operator.keyStat.depositLimit);

            Key[] memory keys = NodeOperatorRegistry(oldRegistry).getKeys(i, 0, usedCount);
            for (uint256 j = 0; j < usedCount; j++) {
                bytes32 pk0 = keys[j].pubkey0;
                bytes32 pk1 = keys[j].pubkey1;
                _keys[i][j].pubkey0 = pk0;
                _keys[i][j].pubkey1 = pk1;
                emit KeyAdded(i, abi.encodePacked(pk0, bytes16(pk1)), j);
            }
            emit VerifiedCountUpdated(i, usedCount);
            emit KeyUsed(i, usedCount);
        }
    }

    function getOperator(uint256 id) external view returns (Operator memory) {
        return _operators[id];
    }

    function getOperators() external view returns (Operator[] memory operators) {
        uint256 count = operatorCount;
        operators = new Operator[](count);
        for (uint256 i = 0; i < count; i++) {
            operators[i] = _operators[i];
        }
    }

    function getRewardAddress(uint256 id) external view returns (address) {
        return _operators[id].rewardAddress;
    }

    function getRewardAddresses() external view returns (address[] memory addresses) {
        uint256 count = operatorCount;
        addresses = new address[](count);
        for (uint256 i = 0; i < count; i++) {
            addresses[i] = _operators[i].rewardAddress;
        }
    }

    function getWithdrawalAddress(uint256 id) external view returns (address) {
        return _operators[id].withdrawalAddress;
    }

    function getWithdrawalAddresses() external view returns (address[] memory addresses) {
        uint256 count = operatorCount;
        addresses = new address[](count);
        for (uint256 i = 0; i < count; i++) {
            addresses[i] = _operators[i].withdrawalAddress;
        }
    }

    function getWithdrawalCredential(uint256 id) external view returns (bytes32) {
        return IWithdrawalManager(_operators[id].withdrawalAddress).getWithdrawalCredential();
    }

    function getKeyStat(uint256 id) external view returns (KeyStat memory) {
        return _operators[id].keyStat;
    }

    function getKeyStats() external view returns (KeyStat[] memory keyStats) {
        uint256 count = operatorCount;
        keyStats = new KeyStat[](count);
        for (uint256 i = 0; i < count; i++) {
            keyStats[i] = _operators[i].keyStat;
        }
    }

    function getKey(uint256 id, uint256 index) external view returns (Key memory) {
        return _keys[id][index];
    }

    function getKeys(
        uint256 id,
        uint256 start,
        uint256 count
    ) external view returns (Key[] memory keys) {
        keys = new Key[](count);
        mapping(uint256 => Key) storage operatorKeys = _keys[id];
        for (uint256 i = 0; i < count; i++) {
            keys[i] = operatorKeys[start + i];
        }
    }

    function getPubkeys(
        uint256 id,
        uint256 start,
        uint256 count
    ) external view returns (bytes[] memory pubkeys) {
        pubkeys = new bytes[](count);
        mapping(uint256 => Key) storage operatorKeys = _keys[id];
        for (uint256 i = 0; i < count; i++) {
            Key storage key = operatorKeys[start + i];
            pubkeys[i] = abi.encodePacked(key.pubkey0, bytes16(key.pubkey1));
        }
    }

    function getSignatures(
        uint256 id,
        uint256 start,
        uint256 count
    ) external view returns (bytes[] memory signatures) {
        signatures = new bytes[](count);
        mapping(uint256 => Key) storage operatorKeys = _keys[id];
        for (uint256 i = 0; i < count; i++) {
            Key storage key = operatorKeys[start + i];
            signatures[i] = abi.encode(key.signature0, key.signature1, key.signature2);
        }
    }

    function addKeys(
        uint256 id,
        bytes calldata pubkeys,
        bytes calldata signatures
    ) external onlyOperatorOwner(id) {
        uint256 count = pubkeys.length / PUBKEY_LENGTH;
        require(
            pubkeys.length == count * PUBKEY_LENGTH &&
                signatures.length == count * SIGNATURE_LENGTH,
            "Invalid param length"
        );
        mapping(uint256 => Key) storage operatorKeys = _keys[id];
        Operator storage operator = _operators[id];
        KeyStat memory stat = operator.keyStat;
        for (uint256 i = 0; i < count; ++i) {
            Key memory key;
            key.pubkey0 = abi.decode(pubkeys[i * PUBKEY_LENGTH:i * PUBKEY_LENGTH + 32], (bytes32));
            key.pubkey1 = abi.decode(
                pubkeys[i * PUBKEY_LENGTH + 16:i * PUBKEY_LENGTH + 48],
                (bytes32)
            );
            key.pubkey1 = bytes32(uint256(key.pubkey1) << 128);
            (key.signature0, key.signature1, key.signature2) = abi.decode(
                signatures[i * SIGNATURE_LENGTH:(i + 1) * SIGNATURE_LENGTH],
                (bytes32, bytes32, bytes32)
            );
            require(
                key.pubkey0 | key.pubkey1 != 0 &&
                    key.signature0 | key.signature1 | key.signature2 != 0,
                "Empty pubkey or signature"
            );
            operatorKeys[stat.totalCount + i] = key;
            emit KeyAdded(
                id,
                abi.encodePacked(key.pubkey0, bytes16(key.pubkey1)),
                stat.totalCount + i
            );
        }
        stat.totalCount += uint64(count);
        operator.keyStat = stat;
        registryVersion++;
    }

    function truncateUnusedKeys(uint256 id) external onlyOperatorOwner(id) {
        _truncateUnusedKeys(id);
    }

    function updateRewardAddress(uint256 id, address newRewardAddress)
        external
        onlyOperatorOwner(id)
    {
        _operators[id].rewardAddress = newRewardAddress;
        emit RewardAddressUpdated(id, newRewardAddress);
    }

    function updateDepositLimit(uint256 id, uint64 newDepositLimit) external onlyOperatorOwner(id) {
        _operators[id].keyStat.depositLimit = newDepositLimit;
        registryVersion++;
        emit DepositLimitUpdated(id, newDepositLimit);
    }

    function useKeys(uint256 id, uint256 count)
        external
        onlyStrategy
        returns (Key[] memory keys, bytes32 withdrawalCredential)
    {
        Operator storage operator = _operators[id];
        KeyStat memory stat = operator.keyStat;
        mapping(uint256 => Key) storage operatorKeys = _keys[id];
        uint256 usedCount = stat.usedCount;
        uint256 newUsedCount = usedCount + count;
        require(
            newUsedCount <= stat.totalCount &&
                newUsedCount <= stat.depositLimit &&
                newUsedCount <= stat.verifiedCount,
            "No enough pubkeys"
        );
        keys = new Key[](count);
        for (uint256 i = 0; i < count; i++) {
            Key storage k = operatorKeys[usedCount + i];
            keys[i] = k;
            // Clear storage for gas refund
            k.signature0 = 0;
            k.signature1 = 0;
            k.signature2 = 0;
        }
        stat.usedCount = uint64(newUsedCount);
        operator.keyStat = stat;
        withdrawalCredential = IWithdrawalManager(operator.withdrawalAddress)
            .getWithdrawalCredential();
        registryVersion++;
        emit KeyUsed(id, count);
    }

    function addOperator(string calldata name, address operatorOwner)
        external
        onlyOwner
        returns (uint256 id, address withdrawalAddress)
    {
        id = operatorCount++;
        withdrawalAddress = factory.deployContract(id);
        Operator storage operator = _operators[id];
        operator.operatorOwner = operatorOwner;
        operator.name = name;
        operator.withdrawalAddress = withdrawalAddress;
        operator.rewardAddress = operatorOwner;
        emit OperatorAdded(id, name, operatorOwner);
    }

    function updateOperatorOwner(uint256 id, address newOperatorOwner) external onlyOwner {
        require(id < operatorCount, "Invalid operator ID");
        _operators[id].operatorOwner = newOperatorOwner;
        emit OperatorOwnerUpdated(id, newOperatorOwner);
    }

    function updateVerifiedCount(
        uint256 id,
        uint64 newVerifiedCount,
        uint256 offchainregistryVersion
    ) external {
        require(msg.sender == IEthStakingStrategy(strategy).safeStaking(), "Only safe staking");
        require(registryVersion == offchainregistryVersion, "Registry version changed");

        _operators[id].keyStat.verifiedCount = newVerifiedCount;
        registryVersion++;
        emit VerifiedCountUpdated(id, newVerifiedCount);
    }

    function truncateAllUnusedKeys() external onlyOwner {
        uint256 count = operatorCount;
        for (uint256 i = 0; i < count; i++) {
            _truncateUnusedKeys(i);
        }
    }

    function _truncateUnusedKeys(uint256 id) private {
        Operator storage operator = _operators[id];
        KeyStat memory stat = operator.keyStat;
        stat.totalCount = stat.usedCount;
        stat.verifiedCount = stat.usedCount;
        operator.keyStat = stat;
        emit KeyTruncated(id, stat.totalCount);
    }

    function updateStrategy(address newStrategy) external onlyOwner {
        _updateStrategy(newStrategy);
    }

    function _updateStrategy(address newStrategy) private {
        strategy = newStrategy;
        emit StrategyUpdated(newStrategy);
    }

    modifier onlyOperatorOwner(uint256 id) {
        require(msg.sender == _operators[id].operatorOwner, "Only operator owner");
        _;
    }

    modifier onlyStrategy() {
        require(msg.sender == strategy, "Only strategy");
        _;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;

interface IWithdrawalManager {
    function getWithdrawalCredential() external view returns (bytes32);

    function transferToStrategy(uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./WithdrawalManagerProxy.sol";

contract WithdrawalManagerFactory is Ownable {
    event ImplementationUpdated(address indexed newImplementation);

    address public implementation;

    constructor(address implementation_) public {
        _updateImplementation(implementation_);
    }

    function deployContract(uint256 id) external returns (address) {
        WithdrawalManagerProxy proxy = new WithdrawalManagerProxy(this, id);
        return address(proxy);
    }

    function updateImplementation(address newImplementation) external onlyOwner {
        _updateImplementation(newImplementation);
    }

    function _updateImplementation(address newImplementation) private {
        implementation = newImplementation;
        emit ImplementationUpdated(newImplementation);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/proxy/Proxy.sol";

import "./WithdrawalManagerFactory.sol";

// An individual withdraw maanger for a node operator

contract WithdrawalManagerProxy is Proxy {
    using Address for address;

    WithdrawalManagerFactory internal immutable withdrawalManagerFactory;

    constructor(WithdrawalManagerFactory withdrawalManagerFactory_, uint256 operatorID_) public {
        // Initialize withdrawalManagerFactory
        require(address(withdrawalManagerFactory_) != address(0x0), "Invalid factory address");
        withdrawalManagerFactory = withdrawalManagerFactory_;
        // Check for contract existence
        address implAddress = withdrawalManagerFactory_.implementation();
        require(implAddress.isContract(), "Delegate contract does not exist");
        // Call Initialize on delegate
        (bool success, ) =
            implAddress.delegatecall(abi.encodeWithSignature("initialize(uint256)", operatorID_));
        if (!success) {
            revert("Failed delegatecall");
        }
    }

    function _implementation() internal view override returns (address) {
        return withdrawalManagerFactory.implementation();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
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
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
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
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        // solhint-disable-next-line no-inline-assembly
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
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    /**
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback () external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive () external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overriden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {
    }
}