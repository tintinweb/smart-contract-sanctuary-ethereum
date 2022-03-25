/**
 *Submitted for verification at Etherscan.io on 2022-03-25
*/

pragma solidity 0.6.0;

// File: @openzeppelin/contracts-upgradeable/proxy/Initializable.sol
// SPDX-License-Identifier: MIT
pragma solidity >=0.4.24 <0.7.0;
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
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        // solhint-disable-next-line no-inline-assembly
        assembly { cs := extcodesize(self) }
        return cs == 0;
    }
}
// File: @openzeppelin/contracts-upgradeable/GSN/ContextUpgradeable.sol
// SPDX-License-Identifier: MIT
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
// File: @openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol
// SPDX-License-Identifier: MIT
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
contract OwnableUpgradeable is Initializable, ContextUpgradeable {
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
    function owner() public view returns (address) {
        return _owner;
    }
    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
// File: contracts/MasterRegistryV2.sol
// SPDX-License-Identifier: UNLICENSED
/**
 * Master Registry Contract.
 */
contract MasterRegistryV2 is Initializable, OwnableUpgradeable {
    event RecordChanged(address indexed series, uint16 indexed key, address value);
    event ContentChanged(address indexed series, uint16 indexed key, string value);
    event DocumentTimestamped(address indexed series, uint256 timestamp, string filename, string cid);
    // Mapping PluginID => Pluggin contract address
    mapping(uint16=>address) private plugins;
    // Mapping Series Address => PluginID => Deployd Contract Address 
    mapping(address=>mapping(uint16=>address)) private records;
    // Mapping Series Address => PluginID => Content
    mapping(address=>mapping(uint16=>string)) private contents;
    /**
     * Modifier that only allow the following entities change content:
     * - Series owners
     * - Plugin itself in case of empty series record
     * - Current module itself addressed by record
     * @param _series The plugin index to update.
     * @param _key The new address where remains the plugin.
     */
    modifier authorizedRecord(address _series, uint16 _key) {
        require(isSeriesOwner(_series) ||
        isRecordItself(_series, _key) || 
        isRecordPlugin(_series, _key), "Not authorized");
        _;
    }
    /**
     * Modifier to allow only series owners to change content.
     * @param _series The plugin index to update.
     * @param _key The new address where remains the plugin.
     */
    modifier onlySeriesOwner(address _series, uint16 _key) {
        require(isSeriesOwner(_series), "Not authorized");
        _;
    }
    /**
     * Sets the module contract associated with an Series and record.
     * May only be called by the owner of that series, module itself or record plugin itself.
     * @param series The series to update.
     * @param key The key to set.
     * @param value The text data value to set.
     */
    function setRecord(address series, uint16 key, address value) public authorizedRecord(series, key) {
        records[series][key] = value;
        emit RecordChanged(series, key, value);
    }
    /**
     * Returns the data associated with an record Series and Key.
     * @param series The series node to query.
     * @param key The text data key to query.
     * @return The associated text data.
     */
    function getRecord(address series, uint16 key) public view returns (address) {
        return records[series][key];
    }
    /**
     * Sets the content data associated with an Series and key.
     * May only be called by the owner of that series.
     * @param series The series to update.
     * @param key The key to set.
     * @param value The text data value to set.
     */
    function setContent(address series, uint16 key, string memory value) public onlySeriesOwner(series, key) {
        contents[series][key] = value;
        emit ContentChanged(series, key, value);
    }
    /**
     * Returns the content associated with an content Series and Key.
     * @param series The series node to query.
     * @param key The text data key to query.
     * @return The associated text data.
     */
    function getContent(address series, uint16 key) public view returns (string memory) {
        return contents[series][key];
    }
    /**
     * Sets the plugin that controls specific entry on records.
     * Only owner of this contract has permission.
     * @param pluginID The plugin index to update.
     * @param pluginAddress The new address where remains the plugin.
     */
    function setPluginController(uint16 pluginID, address pluginAddress) public onlyOwner {
        plugins[pluginID] = pluginAddress;
    }
    /**
    @notice Sets the module contract associated with an Series and record.
    May only be called by the owner of that series, module itself or record plugin itself.
    @param series The series to update.
    @param cid The hash content to be added.
     */
    function addTimestamp(address series, string memory filename, string memory cid) public onlySeriesOwner(series, 1) {
        //DocumentEntry memory doc = DocumentEntry(value, block.timestamp);
        //timestamps[series].push(doc);
        emit DocumentTimestamped(series, block.timestamp, filename, cid);
    }
    function isSeriesOwner(address _series) private view returns (bool) {
        return OwnableUpgradeable(_series).owner() == _msgSender();
    }
    function isRecordItself(address _series, uint16 _key) private view returns (bool) {
        return records[_series][_key] == _msgSender();
    }
    function isRecordPlugin(address _series, uint16 _key) private view returns (bool) {
        return _msgSender() == plugins[_key] && records[_series][_key] == address(0);
    }
}