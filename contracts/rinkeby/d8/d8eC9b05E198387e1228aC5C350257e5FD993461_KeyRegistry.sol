// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;
import "./interfaces/IKeyRegistry.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract KeyRegistry is OwnableUpgradeable, IKeyRegistry {
    uint256 public constant PUBKEY_LENGTH = 48;
    uint256 public constant WITHDRAWAL_CREDENTIAL_LENGTH = 32;
    uint256 public constant SIGNATURE_LENGTH = 96;

    address public EPotter;
    address public assetManager;

    mapping(address => KeyInfo[]) internal keys;
    mapping(address => uint256) internal next;

    mapping(bytes32 => bool) public existingPubKeys;

    mapping(address => address) public feeRecipientInfo;

    /// @dev Initialize only once
    /// @param _assetManager assetManager address
    function initialize(address _assetManager) public initializer {
        require(address(_assetManager) != address(0), "ZERO_ADDRESS");
        assetManager = _assetManager;
        __Ownable_init();
    }

    /// @dev Only "EPotter" can call
    modifier onlyEPotter() {
        require(msg.sender == EPotter, "NOT_EPOTTER_CONTRACT");
        _;
    }

    /// @param _EPotter EPotter contract address
    function setEPotter(address _EPotter) public override onlyOwner {
        require(_EPotter != address(0), "ZERO_ADDRESS");
        require(EPotter != _EPotter, "EPOTTER_REPEAT");
        EPotter = _EPotter;
        emit UpdateEPotter(_EPotter);
    }

    /// @dev Only assetManager can call
    modifier onlyAssetManager() {
        require(msg.sender == assetManager, "NOT_ASSET_MANAGER");
        _;
    }

    /// @param _assetManager assetManager address
    function updateAssetManager(address _assetManager)
        public
        override
        onlyOwner
    {
        require(_assetManager != address(0), "ZERO_ADDRESS");
        require(assetManager != _assetManager, "ASSET_MANAGER_REPEAT");
        assetManager = _assetManager;
        emit UpdateAssetManager(_assetManager);
    }

    /// @dev AssetManager submit keys. pubkeys, withdrawalCredentials and signatures are one-to-one correspondence in array.
    /// @param _addr address that can use keys submitted
    /// @param quantity keys' quantity
    /// @param pubkeys pubkeys
    /// @param withdrawalCredentials withdrawalCredentials  
    /// @param signatures signatures
    function addKeys(
        address _addr,
        uint256 quantity,
        bytes[] calldata pubkeys,
        bytes[] calldata withdrawalCredentials,
        bytes[] calldata signatures
    ) 
        public 
        override 
        onlyAssetManager 
    {
        require(quantity != 0, "ZERO_QUANTITY");
        require(pubkeys.length == quantity, "INVALID_TOTAL_PUBKEY_LENGTH");
        require(withdrawalCredentials.length == quantity, "INVALID_TOTAL_WITHDRAWAL_CREDENTIAL_LENGTH");
        require(signatures.length == quantity, "INVALID_TOTAL_SIGNATURE_LENGTH");

        for (uint256 i = 0; i < quantity; ++i) {
            require(pubkeys[i].length == PUBKEY_LENGTH, "INVALID_PUBKEY_LENGTH");
            require(withdrawalCredentials[i].length == WITHDRAWAL_CREDENTIAL_LENGTH, "INVALID_WITHDRAWAL_CREDENTIAL_LENGTH");
            require(signatures[i].length == SIGNATURE_LENGTH, "INVALID_SIGNATURE_LENGTH");

            KeyInfo memory keyInfo;
            keyInfo.pubkey = pubkeys[i];

            // check duplicated
            require(!existingPubKeys[keccak256(keyInfo.pubkey)], "PUBKEY_EXISTS");
            existingPubKeys[keccak256(keyInfo.pubkey)] = true;

            keyInfo.withdrawalCredential = withdrawalCredentials[i];
            keyInfo.signature = signatures[i];

            keys[_addr].push(keyInfo);

            emit AddKey(keyInfo.pubkey);
        }
    }

    /// @dev AssetManager remove keys. Will remove [startIdx, endIdx] range in keys[_addr].
    /// @param _addr address's keys to remove
    /// @param startIdx start index to remove. The startIdx element is removed
    /// @param endIdx end index to remove. The endIdx element is removed.
    function removeKeys(
        address _addr,
        uint256 startIdx,
        uint256 endIdx
    ) 
        public 
        override 
        onlyAssetManager 
    {
        require(startIdx < keys[_addr].length, "START_INDEX_OVERSIZE");
        require(startIdx >= next[_addr], "START_INDEX_KEY_USED");
        require(startIdx <= endIdx, "INVALID_RANGE");
        require(endIdx < keys[_addr].length, "END_INDEX_OVERSIZE");

        for (uint256 i = endIdx; ; i--) {
            bytes memory removedPubkey = keys[_addr][i].pubkey;

            keys[_addr][i] = keys[_addr][keys[_addr].length - 1];
            keys[_addr].pop();

            delete existingPubKeys[keccak256(removedPubkey)];
            emit RemoveKey(removedPubkey);

            if (i <= startIdx) {
                break;
            }
        }
    }

    /// @dev EPotter assign keys to use. require keys are enough.
    /// @param _addr address's keys to assign
    /// @param quantity quantity
    /// @return return pubkeys, withdrawalCredentials and signatures, they are one-to-one correspondence in array.
    function assignKeys(address _addr, uint256 quantity) public override onlyEPotter returns (
            bytes[] memory,
            bytes[] memory,
            bytes[] memory
        )
    {
        require(quantity != 0, "ZERO_QUANTITY");
        require(next[_addr] + quantity - 1 < keys[_addr].length, "KEYS_NOT_ENOUGH");

        bytes[] memory pubkeys = new bytes[](quantity);
        bytes[] memory withdrawalCredentials = new bytes[](quantity);
        bytes[] memory signatures = new bytes[](quantity);
        uint256 startIdx = next[_addr];
        uint256 aIdx = 0;

        for (uint256 i = startIdx; i < (startIdx + quantity); i++) {
            pubkeys[aIdx] = keys[_addr][i].pubkey;
            withdrawalCredentials[aIdx] = keys[_addr][i].withdrawalCredential;
            signatures[aIdx] = keys[_addr][i].signature;

            next[_addr]++;
            aIdx++;
            emit AssignKey(keys[_addr][i].pubkey);
        }

        return (pubkeys, withdrawalCredentials, signatures);
    }

    /// @dev associate single accout or multiple accounts with single fee recipient address, only assetManager can use this method
    /// @param _addrs single or multiple whiteList user accounts
    /// @param _feeRecipient which accociated with whiteList user accounts
    function setFeeRecipient(address[] memory _addrs, address _feeRecipient) onlyAssetManager public override {
        require(_feeRecipient != address(0),"INVALID_FEERECIPIENT_ADDRESS");
        for(uint256 i = 0; i < _addrs.length; i++){
            require(_addrs[i] != address(0),"INVALID_ACCOUNT_ADDRESS");
            require(feeRecipientInfo[_addrs[i]] != _feeRecipient,"ALREADY_SET");

            feeRecipientInfo[_addrs[i]] = _feeRecipient;
            emit SetFeeRecipient(_addrs[i], _feeRecipient);
        }
    }

    /// @dev remove association relationship about whiteList user accounts with fee recipient, only assetManager can use this method 
    /// @param _addrs single or multiple whiteList user accounts
    function removeFeeRecipient(address[] memory _addrs) onlyAssetManager external override {
        for(uint256 i = 0; i < _addrs.length; i++) { 
            require(_addrs[i] != address(0),"INVALID_ACCOUNT_ADDRESS");
            require(feeRecipientInfo[_addrs[i]] != address(0),"ALREADY_REMOVE");

            delete feeRecipientInfo[_addrs[i]];
            emit RemoveFeeRecipient(_addrs[i]);
        }
    }

    /// @dev Get total quantity of _addr's keys
    /// @param _addr who's key
    /// @return total quantity
    function getTotalQuantity(address _addr) public view override returns (uint256) {
        return keys[_addr].length;
    }

    /// @dev Get used quantity of _addr's keys
    /// @param _addr who's key
    /// @return used quantity
    function getUsedQuantity(address _addr) public view override returns (uint256){
        return next[_addr];
    }

    /// @dev Get unused quantity of _addr's keys
    /// @param _addr who's key
    /// @return unused quantity
    function getUnusedQuantity(address _addr) public view override returns (uint256) {
        return getTotalQuantity(_addr) - getUsedQuantity(_addr);
    }

    /// @dev Get all _addr's keys
    /// @param _addr who's key
    /// @return all keys
    function getKeys(address _addr) public view override returns (KeyInfo[] memory) {
        return keys[_addr];
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

interface IKeyRegistry {

    /// @dev Emitted when EPotter contract address updated
    event UpdateEPotter(address indexed _EPotter);

    /// @param _EPotter EPotter contract address
    function setEPotter(address _EPotter) external;

    /// @dev Emitted when Asset Manager updated
    event UpdateAssetManager(address indexed _assetManager);

    /// @dev Emitted when set feeRecipient
    event SetFeeRecipient(address indexed _addr, address indexed _feeRecipient);

    /// @dev Emitted when remove feeRecipient
    event RemoveFeeRecipient(address indexed _addr);

    /// @param _assetManager assetManager address
    function updateAssetManager(address _assetManager) external;


    /// @dev Key structure
    struct KeyInfo {
        bytes pubkey;
        bytes withdrawalCredential;
        bytes signature;
    }

    /// @dev Emitted when one key added
    event AddKey(bytes pubkey);

    /// @dev AssetManager submit keys. pubkeys, withdrawalCredentials and signatures are one-to-one correspondence in array.
    /// @param _addr address that can use keys submitted
    /// @param quantity keys' quantity
    /// @param pubkeys pubkeys
    /// @param withdrawalCredentials withdrawalCredentials
    /// @param signatures signatures
    function addKeys(
        address _addr,
        uint256 quantity,
        bytes[] calldata pubkeys,
        bytes[] calldata withdrawalCredentials,
        bytes[] calldata signatures
    ) external;

    /// @dev Emitted when one key removed
    event RemoveKey(bytes pubkey);

    /// @dev AssetManager remove keys. Will remove [startIdx, endIdx] range in keys[_addr].
    /// @param _addr address's keys to remove
    /// @param startIdx start index to remove, the startIdx element is removed
    /// @param endIdx end index to remove, the endIdx element is removed.
    function removeKeys(
        address _addr,
        uint256 startIdx,
        uint256 endIdx
    ) external;

    /// @dev Emitted when one key assigned
    event AssignKey(bytes pubkey);

    /// @dev EPotter assign keys to use. require keys are enough.
    /// @param _addr address's keys to assign
    /// @param quantity quantity
    /// @return return pubkeys, withdrawalCredentials and signatures, they are one-to-one correspondence in array.
    function assignKeys(address _addr, uint256 quantity)
        external
        returns (
            bytes[] memory,
            bytes[] memory,
            bytes[] memory
        );

    /// @dev Get total quantity of _addr's keys
    /// @param _addr who's key
    /// @return total quantity
    function getTotalQuantity(address _addr) external view returns (uint256);

    /// @dev Get used quantity of _addr's keys
    /// @param _addr who's key
    /// @return used quantity
    function getUsedQuantity(address _addr) external view returns (uint256);

    /// @dev Get unused quantity of _addr's keys
    /// @param _addr who's key
    /// @return unused quantity
    function getUnusedQuantity(address _addr) external view returns (uint256);

    /// @dev Get all _addr's keys
    /// @param _addr who's key
    /// @return all keys
    function getKeys(address _addr) external view returns (KeyInfo[] memory);

    /// @dev associate single accout or multiple accounts with single fee recipient address, only assetManager can use this method
    /// @param _addrs single or multiple whiteList user accounts
    /// @param _feeRecipient which accociated with whiteList user accounts
    function setFeeRecipient(address[] memory _addrs, address _feeRecipient) external;

    /// @dev remove association relationship about whiteList user accounts with fee recipient, only assetManager can use this method 
    /// @param _addrs single or multiple whiteList user accounts
    function removeFeeRecipient(address[] memory _addrs) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";
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
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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