/**
 *Submitted for verification at Etherscan.io on 2022-10-27
*/

/**
 *Submitted for verification at Etherscan.io on 2022-10-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

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

    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }


    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}
library StorageSlotUpgradeable {
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
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
} 
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

    uint256[50] private __gap;
}

abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

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

    uint256[49] private __gap;
}
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
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
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
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
            _functionDelegateCall(newImplementation, data);
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
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
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
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
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


    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

interface IERC1822ProxiableUpgradeable {

    function proxiableUUID() external view returns (bytes32);
}
interface IBeaconUpgradeable {

    function implementation() external view returns (address);
}

abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);


    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }


    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    function _authorizeUpgrade(address newImplementation) internal virtual;

    uint256[50] private __gap;
}

library AddressUpgradeable {
  
    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }


    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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

library SafeMath {

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");

    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, "SafeMath: subtraction overflow");
  }

  function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    uint256 c = a - b;

    return c;
  }


  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");

    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, "SafeMath: division by zero");
  }

  function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, errorMessage);
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }


  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, "SafeMath: modulo by zero");
  }

  function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}

interface IERC20 {

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}
interface IERC20Upgradeable {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external;

    function allowance(address owner, address spender) external view returns (uint256);
    
    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external;

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable {
    using SafeMath for uint256;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    address private _owner;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
         _owner = _msgSender();

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
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }


    function transfer(address to, uint256 amount) public virtual override{
        _transfer(_msgSender(), to, amount);
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override{
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }
    }
    
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

  
     function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

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

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    uint256[45] private __gap;
}


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract CommonUtil{
    struct LockItem {       
        uint256 tgeAmount;
        uint256 tgeTime;
        uint256 releaseTime;
        uint256 lockedAmount;
        uint256 amountInPeriod;
    }

    struct Transaction {
        uint256 id;
        address from;
        address to;
        uint256 value;
        bool isExecuted;
        bool canExecuted;
        uint256 numConfirmations;
        uint256[] lockParams;
        address[] signers;
    }

    struct TradingPool {
        address poolAddr;
        // can be 0,1. default 0. 0: no tax, 1: tax
        uint8 takeFee;
        uint256 totalTax;
        uint256 sellTaxFee;
        uint256 buyTaxFee;
    }
    uint256 public periodInSecond = 900; // 1 month

    event SubmitTransaction(address indexed _signer, uint256 indexed txIndex, address indexed to, uint256 value);
    event ConfirmTransaction(address indexed _signer, uint256 indexed txIndex);
    event RevokeConfirmation(address indexed _signer, uint256 indexed txIndex);
    event ExecuteTransaction(address indexed _signer, uint256 indexed txIndex);
    event CheckExecuteTransaction(address _from, address _to, uint256 _available, uint256 _value, bool _execute);
    //event LogSender(address indexed _sender, address indexed _from, address indexed _receiver);

    event event_lockSystemWallet(address _sender, address _wallet, uint256 _lockedAmount, uint256 _releaseTime, uint256 _numOfPeriod);
    event event_lockWallet(address _sender, address _wallet, uint256 _lockedAmount, uint256 _releaseTime, uint256 _numOfPeriod);
    function _getLockItem(uint256 _amount, uint256 _nextReleaseTime, uint256 _numOfPeriod, uint256 _tgeTime, uint256 _tgeAmount) 
    internal pure returns (LockItem memory){
        uint256 _lockedAmount = _amount - _tgeAmount;
        return LockItem({
            tgeTime: _tgeTime,
            tgeAmount: _tgeAmount,
            releaseTime: _nextReleaseTime, 
            lockedAmount: _lockedAmount, 
            amountInPeriod: (_lockedAmount/_numOfPeriod)
            });
    }
    
    function _getTradingPool(address _addr, uint8 _takeFee, uint256 _sellTaxFee, uint256 _buyTaxFee) internal pure returns (TradingPool memory){
        return TradingPool({
            poolAddr: _addr,
            takeFee: _takeFee,
            totalTax: 0,
            sellTaxFee: _sellTaxFee,
            buyTaxFee: _buyTaxFee
            });
    }
}

contract CoronaInu is Initializable, ERC20Upgradeable, OwnableUpgradeable, UUPSUpgradeable, CommonUtil{

  // ------------------------ DECLARATION ------------------------
  uint256 private _txIndex = 1;

  address public taxWallet;
  uint16 public numOfSigners = 0;
  uint16 public leastSignerToExecuteTransaction = 3;
  uint8 public constant decimals = 8;
  
  
  // 1 if in whitelist, 2 if in blacklist`
  mapping(address => uint8) private _specialList;
  // 1 if signer, 2 if admin
  mapping(address => uint) public roles;
  // address system wallet
  mapping(address => bool) public isSystem;
  // address -> lockItem
  mapping (address => LockItem) public lockeds;
  // address -> tradingPool
  mapping(address => TradingPool) public tradingPools;
  // check locked
  mapping(address => bool) isLocked;

  Transaction[] private transactions;

  //txId -> transactions
  mapping(uint256 => Transaction) private mapTransactions;
  // txId -> address signer -> bool(confirmed)
  mapping(uint256 => mapping(address => bool)) private confirms;

  event ChangeTaxWalletAddress(address indexed _oldAddress, address indexed _newAddress);
  event ReceivedEther(address indexed _sender, uint256 _amount);

  function _authorizeUpgrade(address) internal override onlyOwner {}
  function initialize(address _taxAddress, string memory name, string memory symbol) public initializer {
    __Context_init_unchained();
    __ERC20_init_unchained(name, symbol);
    __UUPSUpgradeable_init_unchained();
    __Ownable_init();
    taxWallet = _taxAddress;
    roles[_msgSender()] = 2;
  }

  function mint(address _address, uint256 _totalMint, uint256 _releaseDate, uint256 _tgePercent, uint256 _numOfPeriod,  uint256 _cliff) 
  external onlyOwner {
      uint256 _amount = _totalMint * 10 ** decimals;
      _mint(_address, _amount);

      if(block.timestamp < _releaseDate){
        uint256 _tgeAmount = _amount * _tgePercent/100;
        uint256 _nextReleaseTime = _releaseDate + (_cliff * periodInSecond);

        LockItem memory item = _getLockItem(_amount, _nextReleaseTime, _numOfPeriod, _releaseDate, _tgeAmount);
        lockeds[_address] = item;
        isLocked[_address] = true;
      }
  }

  function burn(address _address, uint256 _totalBurn) public onlyOwner(){
       uint256 _amount = _totalBurn * 10 ** decimals;
      _burn(_address, _amount);
                                                
  }
  

  function withdraw(address _tokenContract, address _receiveAddress, uint256 amount) external onlyOwner() {
      require(_receiveAddress != address(0), "require receive address");
      if(_tokenContract == address(0)){
          uint256 value = address(this).balance;
          require(value >= amount, "current balance must be than withdraw amount");
          payable(_receiveAddress).transfer(amount);
      }else{
          IERC20 token = IERC20(_tokenContract);
          uint256 value = token.balanceOf(address(this));
          require(value >= amount, "current balance must be than withdraw amount");
          token.transfer(_receiveAddress, amount);
      }
  }

  function init(uint256 totalSupply_, uint256 _releaseDate, address[] memory _wallets, uint256[] memory _percents, address[] memory _signers,
    uint256[] memory _tgePercents, uint256[] memory _numOfPeriods, uint256[] memory _cliffs) external onlyOwner {
      totalSupply_ = totalSupply_*10 ** uint256(decimals);
      for (uint256 i = 0; i < _wallets.length; i++) {                                                                       
            uint256 _amount = totalSupply_  * _percents[i]/100;
            uint256 _tgeAmount = _amount * _tgePercents[i]/100;
            uint256 _nextReleaseTime = _releaseDate + (_cliffs[i] * periodInSecond);

            _mint(_wallets[i], _amount); 
            LockItem memory item = _getLockItem(_amount, _nextReleaseTime, _numOfPeriods[i], _releaseDate, _tgeAmount);
            lockeds[_wallets[i]] = item;
            isLocked[_wallets[i]] = true;
            isSystem[_wallets[i]] = true; 
            emit event_lockSystemWallet(owner(), _wallets[i], item.lockedAmount, item.releaseTime, _numOfPeriods[i]);
        }
    for (uint256 i = 0; i < _signers.length; i++) {
        roles[_signers[i]] = 1; 
        ++numOfSigners;
    }
  }
  
  function initTradingPool(address[] memory _addr, uint8[] memory _takeFees, uint256[] memory _sellTaxFees, uint256[] memory _buyTaxFees) 
    external onlyOwner() {
      for(uint16 i=0; i< _addr.length; i++){
        TradingPool memory pool = _getTradingPool(_addr[i], _takeFees[i], _sellTaxFees[i],_buyTaxFees[i]);
        tradingPools[_addr[i]] = pool;
      }
  }

  function removeTradingPool(address _addr) external onlyOwner {
    delete tradingPools[_addr];
  }

  function editTradingPool(address _addr, uint8 _takeFee, uint256 _sellTaxFee, uint256 _buyTaxFee) 
  external onlyOwner {
    require(isPoolWallet(_addr), "Pool not exist");
      TradingPool storage pool = tradingPools[_addr];
      pool.takeFee = _takeFee;
      pool.sellTaxFee =_sellTaxFee;
      pool.buyTaxFee = _buyTaxFee;
  }

  function roleAdd(address[] memory _addresses, uint8[] memory _roles) external onlyOwner{
      for (uint256 i = 0; i < _addresses.length; i++) {
          roles[_addresses[i]] = _roles[i];
          if(_roles[i]==1){   // signer
            ++numOfSigners;
          }
          if(_roles[i] == 2){ //if address is admin => add to whilelist
             _specialList[_addresses[i]] = 1;
          }
      }
  }

  function roleRemove(address[] memory _addresses) external onlyOwner{
    for (uint256 i = 0; i < _addresses.length; i++) {
        address _add = _addresses[i];           
        require(roles[_add] > 0 , "Address is not admin or signer");
      
        if(roles[_add] == 1) {
          --numOfSigners;
        }else if(roles[_add] == 2){ //if address is admin => remove from whilelist
          _specialList[_addresses[i]] = 0;
        }
        roles[_add] = 0;
    }
  }


  function specialAdd(address[] memory _addresses, uint8[] memory _types) public onlyOwner{
        for (uint256 i = 0; i < _addresses.length; i++) {              
            _specialList[_addresses[i]] = _types[i];
        }
  }
  
  function setLeastSignerToRelease(uint16 _leastSigner) external onlyOwner{
    require(_leastSigner <= numOfSigners, "leastSigner must be less than numOfSigners");
    leastSignerToExecuteTransaction = _leastSigner;
  }
    function setTaxWallet(address _taxWallet) external onlyAdmin {
    require(_taxWallet != address(0), "Tax wallet address cannot be zero address");
    emit ChangeTaxWalletAddress(taxWallet, _taxWallet);
    taxWallet = _taxWallet;
  }

  function getTradingPool(address _address) external view returns(TradingPool memory) {
    require(isPoolWallet(_address), "Pool not exist");
    return tradingPools[_address];
  }

// ------------------------MODIFIERs ------------------------
  modifier onlyAdmin() {
    require(roles[_msgSender()] == 2, "Caller is not an admin");
    _;
  }

  modifier requireSigner() {
    require(roles[_msgSender()] == 1, "Access denied. Required signer Role");
    _;
  }

  modifier requireSystem() {
    require(isSystem[_msgSender()] == true, "Access denied. Required system wallet");
    _;
  }

  modifier requiredTransfer(address _sender, address _from, address _receiver, uint256 _amount) {
      require(_specialList[_sender] != 2, "sender in black list");
      require(_specialList[_from] != 2, "from address in black list");
      require(_from != _receiver && _receiver != address(0), "invalid address");
      require(_amount > 0 && _amount <= _availableBalance(_from), "not enough funds to transfer");
      _;
  }
  
  modifier onlyWhitelist(){
    require(_specialList[msg.sender] == 1, "Access denied. Required whitelist Role");
    _;
  }
  
// ------------------------FOR SIGNER AND SYSTEM WALLET ------------------------
 function _validateTransaction(uint256 _txId) internal view returns (bool){
      Transaction memory _transaction = mapTransactions[_txId];
      require(mapTransactions[_txId].to != address(0), "tx does not exist");
      require(!_transaction.isExecuted, "tx already executed");
      return true;
  }

  function getTransactions() public view returns (Transaction[] memory) {
      return transactions;
  }

  function getTransaction(uint256 _txId) public view returns (Transaction memory) {
      return mapTransactions[_txId];
  }

  function getSignerOfTransaction(uint256 _txId) public view returns (address[] memory) {
      return mapTransactions[_txId].signers;
  }

  function transactionSubmit(address _sender, address _receiver, uint256 _value, uint256[] memory _lockParams) public 
  requireSystem returns (bool){
      Transaction memory item = Transaction(
          { 
              id: _txIndex,
              from: _sender, 
              to: _receiver, 
              value: _value, 
              isExecuted: false, 
              canExecuted: false,
              numConfirmations: 0, 
              lockParams: _lockParams,
              signers: new address[](0)
          });
      transactions.push(item);
      mapTransactions[_txIndex] = item;
      emit SubmitTransaction(_sender, _txIndex, _receiver, _value);
      _txIndex += 1;
      return true;
  }

  function transactionConfirm(uint256 _txId) public 
  requireSigner
  returns (bool){
      require(!confirms[_txId][_msgSender()], "tx already confirmed");
      _validateTransaction(_txId);

      Transaction storage _transaction = mapTransactions[_txId];
      _transaction.numConfirmations += 1;
      _transaction.signers.push(_msgSender());
      confirms[_txId][_msgSender()] = true;

      if (_transaction.numConfirmations >= leastSignerToExecuteTransaction || _transaction.numConfirmations == numOfSigners){
          _transaction.canExecuted = true;
          transactionExecuted(_txId);
      }
      return true;
  }

  function transactionRevoke(uint256 _txId) public 
  requireSigner
  returns (bool){
      require(confirms[_txId][_msgSender()], "tx unconfirmed");
      _validateTransaction(_txId);

      Transaction storage _transaction = mapTransactions[_txId];
      _transaction.numConfirmations -= 1;
      bool existed;
      uint256 index;
      (existed, index) = _indexOf(_transaction.signers, _msgSender());
      if(existed) {
          _transaction.signers[index] = _transaction.signers[_transaction.signers.length - 1];
          _transaction.signers.pop();
      }
      confirms[_txId][_msgSender()] = false;
      return true;
  }

  function transactionExecuted(uint256 _txId) public 
  requireSigner
  returns (bool){
      _validateTransaction(_txId);

      Transaction storage _transaction = mapTransactions[_txId];
      require(_availableBalance(_transaction.from) >=  _transaction.value, "from address not enough balance");
      require(_transaction.canExecuted == true, "tx not enough signers confirm");

      _transfer(_transaction.from, _transaction.to, _transaction.value);
      uint256[] memory _params = _transaction.lockParams;
      if(_params.length >0  && _params[0] > 0){
          LockItem memory item = _getLockItem(_transaction.value, _params[0], _params[1], 0, 0);
          lockeds[_transaction.to]= item;
          isLocked[_transaction.to] = true;
          emit event_lockWallet(_transaction.from, _transaction.to, item.lockedAmount, item.releaseTime, _params[1]);
      }
      _transaction.isExecuted = true;
      emit ExecuteTransaction(_msgSender(), _txId);
      return true;
  }

  function _availableBalance(address lockedAddress) internal returns(uint256) {
      uint256 bal = balanceOf(lockedAddress);
      uint256 locked = _getLockedAmount(lockedAddress);
      if(locked == 0) {
          isLocked[lockedAddress] = false;
      }
      return bal-locked;
	}

  function _indexOf(address[] memory addresses, address seach) internal pure returns(bool, uint256){
    for(uint256 i =0; i< addresses.length; ++i){
      if (addresses[i] == seach){
        return (true,i);
      }
    }
    return (false,0);
  }  

  // ------------------------FOR TOKEN -----s-------------------

  function getAvailableBalance(address lockedAddress) public view returns(uint256) {
      uint256 bal = balanceOf(lockedAddress);
      uint256 locked = _getLockedAmount(lockedAddress);
      return bal-locked;
    }

  function _getLockedAmount(address lockedAddress) internal view returns(uint256) {
      if(isLocked[lockedAddress] == false) return 0;    
      LockItem memory item = lockeds[lockedAddress];
      if(item.tgeAmount > 0 && block.timestamp >= item.tgeTime){
          item.tgeAmount = 0;
      }
      if(item.lockedAmount > 0){
          while(block.timestamp >= item.releaseTime){
              if(item.lockedAmount > item.amountInPeriod){
                  item.lockedAmount = item.lockedAmount - item.amountInPeriod;
              }else{
                  item.lockedAmount = 0;
              }
              item.releaseTime = item.releaseTime + periodInSecond;
          }
      }
      return item.lockedAmount + item.tgeAmount;
  }

  function transfer(address _receiver, uint256 _amount) public override{
      _doTransfer(_msgSender(), _msgSender(), _receiver, _amount);
	}
	
  function transferFrom(address _from, address _receiver, uint256 _amount)  public override {
      _doTransfer(_msgSender(), _from, _receiver, _amount);
  }

  function _doTransfer(address _sender, address _from, address _receiver, uint256 _amount) internal 
  requiredTransfer(_sender, _from, _receiver, _amount) returns (bool){
      uint8 _role = _specialList[_sender];
      if(_role == 2){ // blacklist block
          return false;
      }
      if(_role == 1){ // in whitelist (ko thu tax)
          _transfer(_from, _receiver, _amount);
          return true;
      }
   
      //emit LogSender(_sender, _from, _receiver);
      uint256 fee = 0;
      if(isPoolWallet(_receiver) && tradingPools[_receiver].takeFee > 0){
          fee = _amount * tradingPools[_receiver].buyTaxFee/100;
          tradingPools[_receiver].totalTax += fee;
      }else if(isPoolWallet(_sender) && tradingPools[_sender].takeFee > 0){
          fee = _amount * tradingPools[_sender].sellTaxFee/100;
          tradingPools[_sender].totalTax += fee;
      }
      if(fee > 0){
          _transfer(_from, taxWallet, fee);
      }
      _transfer(_from, _receiver, _amount - fee);
      return true;
  }

  function isPoolWallet(address _address) public view returns(bool){
      return tradingPools[_address].poolAddr != address(0);
  }

  receive() external payable {
      emit ReceivedEther(msg.sender, msg.value);
  }
}