// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

import "./BaseModule.sol";
import "./IWallet.sol";
import "./IModuleRegistry.sol";

contract Wallet is IWallet, Initializable {
    // Events
    event Deposited(address from, uint value, bytes data);
    event SafeModeActivated(address msgSender);
    event AuthorisedModule(address indexed module, bool value);
    event Received(uint indexed value, address indexed sender, bytes data);
    event Invoked(address from, address to, uint value, bytes data);
    event RawInvoked(address from, address to, uint value, bytes data);
    event OwnerReplaced(address _newOwner);

    /*
     * We classify three kinds of selectors used in _setLock to distinguish different types of locks:
     * 1.SignerSelector is calculated from SecurityModule.addSigner.selector, representing the locks added by these functions: 
     * addSigner, replaceSigner, removeSigner and triggerRecovery.
     * 2.GlobalSelector is calculated from SecurityModule.lock.selector, representing the lock added by lock.
     * The difference between 2 and 1 is that when users trigger SecurityModule's lock funtion, they want to actively lock, 
     * but when they triggered addSigner, replaceSigner, removeSigner or executeLargeTransaction, the wallet is locked because 
     * We don't want users to trigger these actions too often for security reasons. And 2 is a global lock, 1 is a local lock,
     * which means that you can add a global lock after a local lock, but you can't do the other way around.
     */
    bytes4 internal constant SignerSelector = 0x2239f556;
    bytes4 internal constant GlobalSelector = 0xf435f5a7;

    // Public fields
    address public override owner;
    uint public override modules;

    // Internal fields
    uint constant SEQUENCE_ID_WINDOW_SIZE = 10;
    uint[10] recentSequenceIds_;

    // locks
    mapping (bytes4 => uint64) internal locks;

     // The authorised modules
    mapping (address => bool) public override authorised;

     /**
     * @notice Throws if the sender is not an authorised module.
     */
    modifier onlyModule {
        require(authorised[msg.sender], "W: must be module");
        _;
    }
    modifier onlyModuleOrOwner {
        require(authorised[msg.sender] || msg.sender == owner, "W: must be owner or module");
        _;
    } 

    modifier onlyRegisteredModule(address _moduleRegistry) {
        require(IModuleRegistry(_moduleRegistry).isRegisteredModule(msg.sender), "W: module is not registered");
        _;
    }

    /**
     * Modifier that will check if sender is owner
     */
    modifier onlySelf() {
        require(msg.sender == address(this), "only self");
        _;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "W: must be owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    /**
     * Set up a simple multi-sig wallet by specifying the signers allowed to be used on this wallet.
     * 2 signers will be required to send a transaction from this wallet.
     * Note: The sender is NOT automatically added to the list of signers.
     * Signers CANNOT be changed once they are set
     *
     * @param _modules All modules to authrized by wallet
     * @param _data All modules to authrized by wallet
     */
    function initialize(address[] calldata _modules, bytes[] calldata _data) public initializer {
        require(owner == address(0), "W: wallet already initialized");
        require(_modules.length > 0 && _modules.length == _data.length, 
                "W: empty modules or not matched data");
        modules = _modules.length;
        owner = msg.sender;
        for (uint256 i = 0; i < _modules.length; i++) {
            require(authorised[_modules[i]] == false, "Module is already added");
            authorised[_modules[i]] = true;
            IModule(_modules[i]).init(address(this), _data[i]);  // uncomment will make test/proxy.test.ts failed
            emit AuthorisedModule(_modules[i], true);
        }
        if (address(this).balance > 0) {
            emit Received(address(this).balance, address(0), "");
        }
    }

    /**
     * Upgrade model or remove model for wallet
     */
    function authoriseModule(address _moduleRegistry, address _module, bool _value, bytes calldata _data) external override onlyRegisteredModule(_moduleRegistry) {
        if (authorised[_module] != _value) {
            emit AuthorisedModule(_module, _value);
            if (_value == true) {
                modules += 1;
                authorised[_module] = true;
                IModule(_module).init(address(this), _data);
            } else {
                modules -= 1;
                require(modules > 0, "BW: cannot remove last module");
                IModule instanceModule = IModule(_module);
                instanceModule.removeModule(address(this));
                delete authorised[_module];    
            }
        }
    }

    /**
     * @notice Helper method to check the wallet's lock situation.
     * Refer to the permission flag of linux => 
     * 2: locked by signer related operation 
     * 1: locked globally
     */
    function isLocked() external view override returns (uint) {
        uint lockFlag = 0;
        if (locks[SignerSelector] > uint64(block.timestamp)) {
            lockFlag += 2;
        }  
        if (locks[GlobalSelector] > uint64(block.timestamp)) {
            lockFlag += 1;
        }
        return lockFlag;
    }

    /**
     * @notice Lock the wallet
     */
    function setLock(uint256 _releaseAfter, bytes4 _locker) external override onlyModule {
        locks[_locker] = uint64(_releaseAfter);
    }

    function replaceOwner(address _newOwner) external override onlyModule {
        require(_newOwner != address(0), "W: invalid newOwner");
        owner = _newOwner;
        emit OwnerReplaced(_newOwner);
    }

    /**
    * Gets called when a transaction is received without calling a method
    */
    fallback() external payable {
        if (msg.value > 0) {
            // Fire deposited event if we are receiving funds
            emit Deposited(msg.sender, msg.value, msg.data);
        }
    }

    /**
     * Verify that the sequence id has not been used before and inserts it. Throws if the sequence ID was not accepted.
     * We collect a window of up to 10 recent sequence ids, and allow any sequence id that is not in the window and
     * greater than the minimum element in the window.
     * @param sequenceId to insert into array of stored ids
     */
    function tryInsertSequenceId(uint sequenceId) internal {
        // Keep a pointer to the lowest value element in the window
        uint lowestValueIndex = 0;
        for (uint i = 0; i < SEQUENCE_ID_WINDOW_SIZE; i++) {
            // This sequence ID has been used before. Disallow!
            require (recentSequenceIds_[i] != sequenceId, "W: the sequence ID has been used");
            if (recentSequenceIds_[i] < recentSequenceIds_[lowestValueIndex]) {
                lowestValueIndex = i;
            }
        }
        // The sequence ID being used is lower than the lowest value in the window
        // so we cannot accept it as it may have been used before
        require(sequenceId >= recentSequenceIds_[lowestValueIndex],
                "W: the sequence ID being used is lower thatn the lowest value");

        // Block sequence IDs which are much higher than the lowest value
        // This prevents people blocking the contract by using very large sequence IDs quickly
        require(sequenceId <= (recentSequenceIds_[lowestValueIndex] + 10000),
                "W: block sequnece ID are much higer than the lowest value");
        recentSequenceIds_[lowestValueIndex] = sequenceId;
    }

    /**
     * Gets the next available sequence ID for signing when using executeAndConfirm
     * returns the sequenceId one higher than the highest currently stored
     */
    function getNextSequenceId() public view returns (uint) {
        uint highestSequenceId = 0;
        for (uint i = 0; i < SEQUENCE_ID_WINDOW_SIZE; i++) {
            if (recentSequenceIds_[i] > highestSequenceId) {
                highestSequenceId = recentSequenceIds_[i];
            }
        }
        return highestSequenceId + 1;
    }

    /**
     * @notice Performs a generic transaction.
     * @param _target The address for the transaction.
     * @param _value The value of the transaction.
     * @param _data The data of the transaction.
     * @param _expireTime The data of the transaction.
     * @param _sequenceId The data of the transaction.
     */
    function invoke(address _target, uint _value, bytes calldata _data,
                    uint _expireTime, uint _sequenceId
                   ) external override onlyModule returns (bytes memory _result) {
        require(_target != address(this), "W: cann't call itself");
        bool success;
        require(_expireTime >= block.timestamp, "Transaction expired");

        tryInsertSequenceId(_sequenceId);
        (success, _result) = _target.call{value: _value}(_data);
        if (!success) {
            // solhint-disable-next-line no-inline-assembly
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
        emit Invoked(msg.sender, _target, _value, _data);
    }

    function raw_invoke(address _target, uint _value, bytes calldata _data
                   ) external override onlyModule returns (bytes memory _result) {
        require(_target != address(this), "W: cann't call itself");
        bool success;
        (success, _result) = _target.call{value: _value}(_data);
        if (!success) {
            // solhint-disable-next-line no-inline-assembly
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
        emit RawInvoked(msg.sender, _target, _value, _data);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
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
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

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

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !Address.isContract(address(this));
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./IModule.sol";
import "./IWallet.sol";
import "./IModuleRegistry.sol";


abstract contract BaseModule is IModule {

    address public implementation;
    address public admin;
    IModuleRegistry internal registry;
    address[] internal wallets;

    struct CallArgs {
        address to;
        uint value;
        bytes data;
        uint sequenceId;
        uint expireTime;
    }
    event MultiCalled(address to, uint value, bytes data);

    /**
     * Modifier that will check if sender is owner
     */
    modifier onlySelf() {
        require(msg.sender == address(this), "only self");
        _;
    }

    function _isSelf(address _self) internal view returns (bool) {
        return _self == address(this);
    }

     /**
     * @notice Throws if the wallet is not locked.
     */
    modifier onlyWhenLocked(address _wallet) {
        require(IWallet(_wallet).isLocked() != 0, "BM: wallet must be locked");
        _;
    }

    /**
     * @notice Throws if the wallet is not globally locked.
     */
    modifier onlyWhenGloballyLocked(address _wallet) {
        uint lockFlag = IWallet(_wallet).isLocked();
        require(lockFlag % 2 == 1, "BM: wallet must be globally locked");
        _;
    }

    /**
     * @dev Throws if the sender is not the target wallet of the call.
     */
    modifier onlyWallet(address _wallet) {
        require(msg.sender == _wallet, "BM: caller must be wallet");
        _;
    }

    /**
     * @notice Throws if the wallet is locked.
     */
    modifier onlyWhenUnlocked(address _wallet) {
        require(IWallet(_wallet).isLocked() == 0, "BM: wallet locked");
        _;
    }

    /**
     * @notice Throws if the wallet is locked globally.
     */      
    modifier onlyWhenNonGloballyLocked(address _wallet) {
        uint lockFlag = IWallet(_wallet).isLocked();
        require(lockFlag % 2 == 0, "BM: wallet locked globally");
        _;
    }

    /**
     * @notice Throws if the wallet is locked by signer related operation.
     */
    modifier onlyWhenNonSignerLocked(address _wallet) {
        uint lockFlag = IWallet(_wallet).isLocked();
        require(lockFlag != 2 && lockFlag != 3, "BM: wallet locked by signer related operation");
        _;
    }

    function isRegisteredWallet(address _wallet) internal view returns (bool){
        for (uint i = 0; i < wallets.length; i++) {
            if ( wallets[i] == _wallet ) {
                return true;
            }
        }
        return false;
    }

    /**
     * @notice Helper method to check if an address is the owner of a target wallet.
     * @param _wallet The target wallet.
     * @param _addr The address.
     */
    function _isOwner(address _wallet, address _addr) internal view returns (bool) {
        return IWallet(_wallet).owner() == _addr;
    }

    modifier onlyOwner(address _wallet) {
        require(IWallet(_wallet).owner() == msg.sender, "BM: must be owner");
        _;
    }

    function addWallet(address _wallet) internal {
        // duplicate check
        require(!isRegisteredWallet(_wallet), "BM: wallet already registered");
        wallets.push(_wallet); 
    }

    function removeWallet(address _wallet) internal {
        uint endIndex = wallets.length - 1;
        for (uint i = 0; i < endIndex; i ++) {
            if ( wallets[i] == _wallet ) {
                wallets[i] = wallets[endIndex];
                i = endIndex;
            }
        }
        wallets.pop();
    }

    function execute(address _wallet, CallArgs memory _args) internal {
        address to = _args.to;
        uint value = _args.value;
        bytes memory data = _args.data;
        uint sequenceId = _args.sequenceId;
        uint expireTime = _args.expireTime;
        IWallet(_wallet).invoke(to, value, data, expireTime, sequenceId);
        emit MultiCalled(to, value, data);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface IWallet {

    /**
     * @notice Return the owner
     */
    function owner() external view returns (address);

    /**
     * @notice Returns the number of authorised modules.
     * @return The number of authorised modules.
     */
    function modules() external view returns (uint);

    /**
     * @notice replace the wallet owner.
     * @param _newOwner The new signer.
     */
    function replaceOwner(address _newOwner) external;

    /**
     * @notice Checks if a module is authorised on the wallet.
     * @param _module The module address to check.
     * @return `true` if the module is authorised, otherwise `false`.
     */
    function authorised(address _module) external view returns (bool);

    /**
     * @notice Enables/Disables a module.
     * @param _module The target module.
     * @param _value Set to `true` to authorise the module.
     */
    function authoriseModule(address _moduleRegistry, address _module, bool _value, bytes memory data) external;

    function isLocked() external view returns (uint);

    function setLock(uint256 _releaseAfter, bytes4 _locker) external; 

    function invoke(
        address toAddress,
        uint value,
        bytes calldata data,
        uint expireTime,
        uint sequenceId
    ) external returns (bytes memory);

    function raw_invoke(
        address toAddress,
        uint value,
        bytes calldata data
    ) external returns (bytes memory);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface IModuleRegistry {
    function registerModule(address _module, bytes32 _name) external;

    function deregisterModule(address _module) external;

    function moduleName(address _module) external view returns (bytes32);

    function isRegisteredModule(address _module) external view returns (bool);
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

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface IModule {
    function init(address _wallet, bytes memory _data) external;
    function removeModule(address _wallet) external;
    function addModule(address _moduleRegistry, address _wallet, address _module, bytes calldata _data) external;
}