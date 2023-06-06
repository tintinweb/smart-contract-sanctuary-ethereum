// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

import { ITokenBurn } from './interfaces/ITokenBurn.sol';
import { ITokenDecimals } from './interfaces/ITokenDecimals.sol';
import { AssetSpenderRole } from './roles/AssetSpenderRole.sol';
import { BalanceManagement } from './BalanceManagement.sol';
import { SystemVersionId } from './SystemVersionId.sol';
import { VaultBase } from './VaultBase.sol';
import { TokenBurnError } from './Errors.sol';
import './helpers/AddressHelper.sol' as AddressHelper;
import './helpers/TransferHelper.sol' as TransferHelper;

/**
 * @title Vault
 * @notice The vault contract
 */
contract Vault is SystemVersionId, VaultBase, AssetSpenderRole, BalanceManagement {
    /**
     * @dev The variable token contract address, can be a zero address
     */
    address public variableToken;

    /**
     * @dev The state of variable token and balance actions
     */
    bool public variableRepaymentEnabled;

    /**
     * @notice Emitted when the state of variable token and balance actions is updated
     * @param variableRepaymentEnabled The state of variable token and balance actions
     */
    event SetVariableRepaymentEnabled(bool indexed variableRepaymentEnabled);

    /**
     * @notice Emitted when the variable token contract address is updated
     * @param variableToken The address of the variable token contract
     */
    event SetVariableToken(address indexed variableToken);

    /**
     * @notice Emitted when the variable tokens are redeemed for the vault asset
     * @param caller The address of the vault asset receiver account
     * @param amount The amount of redeemed variable tokens
     */
    event RedeemVariableToken(address indexed caller, uint256 amount);

    /**
     * @notice Emitted when the variable token decimals do not match the vault asset
     */
    error TokenDecimalsError();

    /**
     * @notice Emitted when a variable token or balance action is not allowed
     */
    error VariableRepaymentNotEnabledError();

    /**
     * @notice Emitted when setting the variable token is attempted while the token is already set
     */
    error VariableTokenAlreadySetError();

    /**
     * @notice Emitted when a variable token action is attempted while the token address is not set
     */
    error VariableTokenNotSetError();

    /**
     * @notice Deploys the VariableToken contract
     * @param _asset The vault asset address
     * @param _name The ERC20 token name
     * @param _symbol The ERC20 token symbol
     * @param _assetSpenders The addresses of initial asset spenders
     * @param _depositAllowed The initial state of deposit availability
     * @param _variableRepaymentEnabled The initial state of variable token and balance actions
     * @param _owner The address of the initial owner of the contract
     * @param _managers The addresses of initial managers of the contract
     * @param _addOwnerToManagers The flag to optionally add the owner to the list of managers
     */
    constructor(
        address _asset,
        string memory _name,
        string memory _symbol,
        address[] memory _assetSpenders,
        bool _depositAllowed,
        bool _variableRepaymentEnabled,
        address _owner,
        address[] memory _managers,
        bool _addOwnerToManagers
    ) VaultBase(_asset, _name, _symbol, _depositAllowed) {
        for (uint256 index; index < _assetSpenders.length; index++) {
            _setAssetSpender(_assetSpenders[index], true);
        }

        _setVariableRepaymentEnabled(_variableRepaymentEnabled);

        _initRoles(_owner, _managers, _addOwnerToManagers);
    }

    /**
     * @notice Updates the Asset Spender role status for the account
     * @param _account The account address
     * @param _value The Asset Spender role status flag
     */
    function setAssetSpender(address _account, bool _value) external onlyManager {
        _setAssetSpender(_account, _value);
    }

    /**
     * @notice Sets the variable token contract address
     * @dev Setting the address value is possible only once
     * @param _variableToken The address of the variable token contract
     */
    function setVariableToken(address _variableToken) external onlyManager {
        if (variableToken != address(0)) {
            revert VariableTokenAlreadySetError();
        }

        AddressHelper.requireContract(_variableToken);

        if (ITokenDecimals(_variableToken).decimals() != decimals) {
            revert TokenDecimalsError();
        }

        variableToken = _variableToken;

        emit SetVariableToken(_variableToken);
    }

    /**
     * @notice Updates the state of variable token and balance actions
     * @param _variableRepaymentEnabled The state of variable token and balance actions
     */
    function setVariableRepaymentEnabled(bool _variableRepaymentEnabled) external onlyManager {
        _setVariableRepaymentEnabled(_variableRepaymentEnabled);
    }

    /**
     * @notice Requests the vault asset tokens
     * @param _amount The amount of the vault asset tokens
     * @param _to The address of the vault asset tokens receiver
     * @param _forVariableBalance True if the request is made for a variable balance repayment, otherwise false
     * @return assetAddress The address of the vault asset token
     */
    function requestAsset(
        uint256 _amount,
        address _to,
        bool _forVariableBalance
    ) external whenNotPaused onlyAssetSpender returns (address assetAddress) {
        if (_forVariableBalance && !variableRepaymentEnabled) {
            revert VariableRepaymentNotEnabledError();
        }

        TransferHelper.safeTransfer(asset, _to, _amount);

        return asset;
    }

    /**
     * @notice Redeems variable tokens for the vault asset
     * @param _amount The number of variable tokens to redeem
     */
    function redeemVariableToken(uint256 _amount) external whenNotPaused nonReentrant checkCaller {
        checkVariableTokenState();

        bool burnSuccess = ITokenBurn(variableToken).burn(msg.sender, _amount);

        if (!burnSuccess) {
            revert TokenBurnError();
        }

        emit RedeemVariableToken(msg.sender, _amount);

        TransferHelper.safeTransfer(asset, msg.sender, _amount);
    }

    /**
     * @notice Checks the status of the variable token and balance actions and the variable token address
     * @dev Throws an error if variable token actions are not allowed
     * @return The address of the variable token
     */
    function checkVariableTokenState() public view returns (address) {
        if (!variableRepaymentEnabled) {
            revert VariableRepaymentNotEnabledError();
        }

        if (variableToken == address(0)) {
            revert VariableTokenNotSetError();
        }

        return variableToken;
    }

    /**
     * @notice Getter of the reserved token flag
     * @dev Returns true if the provided token address is the address of the vault asset
     * @param _tokenAddress The address of the token
     * @return The reserved token flag
     */
    function isReservedToken(address _tokenAddress) public view override returns (bool) {
        return _tokenAddress == asset;
    }

    function _setVariableRepaymentEnabled(bool _variableRepaymentEnabled) private {
        variableRepaymentEnabled = _variableRepaymentEnabled;

        emit SetVariableRepaymentEnabled(_variableRepaymentEnabled);
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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
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

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

import { ITokenBalance } from './interfaces/ITokenBalance.sol';
import { ManagerRole } from './roles/ManagerRole.sol';
import './helpers/TransferHelper.sol' as TransferHelper;
import './Constants.sol' as Constants;

/**
 * @title BalanceManagement
 * @notice Base contract for the withdrawal of tokens, except for reserved ones
 */
abstract contract BalanceManagement is ManagerRole {
    /**
     * @notice Emitted when the specified token is reserved
     */
    error ReservedTokenError();

    /**
     * @notice Performs the withdrawal of tokens, except for reserved ones
     * @dev Use the "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE" address for the native token
     * @param _tokenAddress The address of the token
     * @param _tokenAmount The amount of the token
     */
    function cleanup(address _tokenAddress, uint256 _tokenAmount) external onlyManager {
        if (isReservedToken(_tokenAddress)) {
            revert ReservedTokenError();
        }

        if (_tokenAddress == Constants.NATIVE_TOKEN_ADDRESS) {
            TransferHelper.safeTransferNative(msg.sender, _tokenAmount);
        } else {
            TransferHelper.safeTransfer(_tokenAddress, msg.sender, _tokenAmount);
        }
    }

    /**
     * @notice Getter of the token balance of the current contract
     * @dev Use the "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE" address for the native token
     * @param _tokenAddress The address of the token
     * @return The token balance of the current contract
     */
    function tokenBalance(address _tokenAddress) public view returns (uint256) {
        if (_tokenAddress == Constants.NATIVE_TOKEN_ADDRESS) {
            return address(this).balance;
        } else {
            return ITokenBalance(_tokenAddress).balanceOf(address(this));
        }
    }

    /**
     * @notice Getter of the reserved token flag
     * @dev Override to add reserved token addresses
     * @param _tokenAddress The address of the token
     * @return The reserved token flag
     */
    function isReservedToken(address _tokenAddress) public view virtual returns (bool) {
        // The function returns false by default.
        // The explicit return statement is omitted to avoid the unused parameter warning.
        // See https://github.com/ethereum/solidity/issues/5295
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

import { ManagerRole } from './roles/ManagerRole.sol';
import './helpers/AddressHelper.sol' as AddressHelper;
import './Constants.sol' as Constants;
import './DataStructures.sol' as DataStructures;

/**
 * @title CallerGuard
 * @notice Base contract to control access from other contracts
 */
abstract contract CallerGuard is ManagerRole {
    /**
     * @dev Caller guard mode enumeration
     */
    enum CallerGuardMode {
        ContractForbidden,
        ContractList,
        ContractAllowed
    }

    /**
     * @dev Caller guard mode value
     */
    CallerGuardMode public callerGuardMode = CallerGuardMode.ContractForbidden;

    /**
     * @dev Registered contract list for "ContractList" mode
     */
    address[] public listedCallerGuardContractList;

    /**
     * @dev Registered contract list indices for "ContractList" mode
     */
    mapping(address /*account*/ => DataStructures.OptionalValue /*index*/)
        public listedCallerGuardContractIndexMap;

    /**
     * @notice Emitted when the caller guard mode is set
     * @param callerGuardMode The caller guard mode
     */
    event SetCallerGuardMode(CallerGuardMode indexed callerGuardMode);

    /**
     * @notice Emitted when a registered contract for "ContractList" mode is added or removed
     * @param contractAddress The contract address
     * @param isListed The registered contract list inclusion flag
     */
    event SetListedCallerGuardContract(address indexed contractAddress, bool indexed isListed);

    /**
     * @notice Emitted when the caller is not allowed to perform the intended action
     */
    error CallerGuardError(address caller);

    /**
     * @dev Modifier to check if the caller is allowed to perform the intended action
     */
    modifier checkCaller() {
        if (msg.sender != tx.origin) {
            bool condition = (callerGuardMode == CallerGuardMode.ContractAllowed ||
                (callerGuardMode == CallerGuardMode.ContractList &&
                    isListedCallerGuardContract(msg.sender)));

            if (!condition) {
                revert CallerGuardError(msg.sender);
            }
        }

        _;
    }

    /**
     * @notice Sets the caller guard mode
     * @param _callerGuardMode The caller guard mode
     */
    function setCallerGuardMode(CallerGuardMode _callerGuardMode) external onlyManager {
        callerGuardMode = _callerGuardMode;

        emit SetCallerGuardMode(_callerGuardMode);
    }

    /**
     * @notice Updates the list of registered contracts for the "ContractList" mode
     * @param _items The addresses and flags for the contracts
     */
    function setListedCallerGuardContracts(
        DataStructures.AccountToFlag[] calldata _items
    ) external onlyManager {
        for (uint256 index; index < _items.length; index++) {
            DataStructures.AccountToFlag calldata item = _items[index];

            if (item.flag) {
                AddressHelper.requireContract(item.account);
            }

            DataStructures.uniqueAddressListUpdate(
                listedCallerGuardContractList,
                listedCallerGuardContractIndexMap,
                item.account,
                item.flag,
                Constants.LIST_SIZE_LIMIT_DEFAULT
            );

            emit SetListedCallerGuardContract(item.account, item.flag);
        }
    }

    /**
     * @notice Getter of the registered contract count
     * @return The registered contract count
     */
    function listedCallerGuardContractCount() external view returns (uint256) {
        return listedCallerGuardContractList.length;
    }

    /**
     * @notice Getter of the complete list of registered contracts
     * @return The complete list of registered contracts
     */
    function fullListedCallerGuardContractList() external view returns (address[] memory) {
        return listedCallerGuardContractList;
    }

    /**
     * @notice Getter of a listed contract flag
     * @param _account The contract address
     * @return The listed contract flag
     */
    function isListedCallerGuardContract(address _account) public view returns (bool) {
        return listedCallerGuardContractIndexMap[_account].isSet;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

/**
 * @dev The default token decimals value
 */
uint256 constant DECIMALS_DEFAULT = 18;

/**
 * @dev The maximum uint256 value for swap amount limit settings
 */
uint256 constant INFINITY = type(uint256).max;

/**
 * @dev The default limit of account list size
 */
uint256 constant LIST_SIZE_LIMIT_DEFAULT = 100;

/**
 * @dev The limit of swap router list size
 */
uint256 constant LIST_SIZE_LIMIT_ROUTERS = 200;

/**
 * @dev The factor for percentage settings. Example: 100 is 0.1%
 */
uint256 constant MILLIPERCENT_FACTOR = 100_000;

/**
 * @dev The de facto standard address to denote the native token
 */
address constant NATIVE_TOKEN_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

/**
 * @notice Optional value structure
 * @dev Is used in mappings to allow zero values
 * @param isSet Value presence flag
 * @param value Numeric value
 */
struct OptionalValue {
    bool isSet;
    uint256 value;
}

/**
 * @notice Key-to-value structure
 * @dev Is used as an array parameter item to perform multiple key-value settings
 * @param key Numeric key
 * @param value Numeric value
 */
struct KeyToValue {
    uint256 key;
    uint256 value;
}

/**
 * @notice Key-to-value structure for address values
 * @dev Is used as an array parameter item to perform multiple key-value settings with address values
 * @param key Numeric key
 * @param value Address value
 */
struct KeyToAddressValue {
    uint256 key;
    address value;
}

/**
 * @notice Address-to-flag structure
 * @dev Is used as an array parameter item to perform multiple settings
 * @param account Account address
 * @param flag Flag value
 */
struct AccountToFlag {
    address account;
    bool flag;
}

/**
 * @notice Emitted when a list exceeds the size limit
 */
error ListSizeLimitError();

/**
 * @notice Sets or updates a value in a combined map (a mapping with a key list and key index mapping)
 * @param _map The mapping reference
 * @param _keyList The key list reference
 * @param _keyIndexMap The key list index mapping reference
 * @param _key The numeric key
 * @param _value The address value
 * @param _sizeLimit The map and list size limit
 * @return isNewKey True if the key was just added, otherwise false
 */
function combinedMapSet(
    mapping(uint256 => address) storage _map,
    uint256[] storage _keyList,
    mapping(uint256 => OptionalValue) storage _keyIndexMap,
    uint256 _key,
    address _value,
    uint256 _sizeLimit
) returns (bool isNewKey) {
    isNewKey = !_keyIndexMap[_key].isSet;

    if (isNewKey) {
        uniqueListAdd(_keyList, _keyIndexMap, _key, _sizeLimit);
    }

    _map[_key] = _value;
}

/**
 * @notice Removes a value from a combined map (a mapping with a key list and key index mapping)
 * @param _map The mapping reference
 * @param _keyList The key list reference
 * @param _keyIndexMap The key list index mapping reference
 * @param _key The numeric key
 * @return isChanged True if the combined map was changed, otherwise false
 */
function combinedMapRemove(
    mapping(uint256 => address) storage _map,
    uint256[] storage _keyList,
    mapping(uint256 => OptionalValue) storage _keyIndexMap,
    uint256 _key
) returns (bool isChanged) {
    isChanged = _keyIndexMap[_key].isSet;

    if (isChanged) {
        delete _map[_key];
        uniqueListRemove(_keyList, _keyIndexMap, _key);
    }
}

/**
 * @notice Adds a value to a unique value list (a list with value index mapping)
 * @param _list The list reference
 * @param _indexMap The value index mapping reference
 * @param _value The numeric value
 * @param _sizeLimit The list size limit
 * @return isChanged True if the list was changed, otherwise false
 */
function uniqueListAdd(
    uint256[] storage _list,
    mapping(uint256 => OptionalValue) storage _indexMap,
    uint256 _value,
    uint256 _sizeLimit
) returns (bool isChanged) {
    isChanged = !_indexMap[_value].isSet;

    if (isChanged) {
        if (_list.length >= _sizeLimit) {
            revert ListSizeLimitError();
        }

        _indexMap[_value] = OptionalValue(true, _list.length);
        _list.push(_value);
    }
}

/**
 * @notice Removes a value from a unique value list (a list with value index mapping)
 * @param _list The list reference
 * @param _indexMap The value index mapping reference
 * @param _value The numeric value
 * @return isChanged True if the list was changed, otherwise false
 */
function uniqueListRemove(
    uint256[] storage _list,
    mapping(uint256 => OptionalValue) storage _indexMap,
    uint256 _value
) returns (bool isChanged) {
    OptionalValue storage indexItem = _indexMap[_value];

    isChanged = indexItem.isSet;

    if (isChanged) {
        uint256 itemIndex = indexItem.value;
        uint256 lastIndex = _list.length - 1;

        if (itemIndex != lastIndex) {
            uint256 lastValue = _list[lastIndex];
            _list[itemIndex] = lastValue;
            _indexMap[lastValue].value = itemIndex;
        }

        _list.pop();
        delete _indexMap[_value];
    }
}

/**
 * @notice Adds a value to a unique address value list (a list with value index mapping)
 * @param _list The list reference
 * @param _indexMap The value index mapping reference
 * @param _value The address value
 * @param _sizeLimit The list size limit
 * @return isChanged True if the list was changed, otherwise false
 */
function uniqueAddressListAdd(
    address[] storage _list,
    mapping(address => OptionalValue) storage _indexMap,
    address _value,
    uint256 _sizeLimit
) returns (bool isChanged) {
    isChanged = !_indexMap[_value].isSet;

    if (isChanged) {
        if (_list.length >= _sizeLimit) {
            revert ListSizeLimitError();
        }

        _indexMap[_value] = OptionalValue(true, _list.length);
        _list.push(_value);
    }
}

/**
 * @notice Removes a value from a unique address value list (a list with value index mapping)
 * @param _list The list reference
 * @param _indexMap The value index mapping reference
 * @param _value The address value
 * @return isChanged True if the list was changed, otherwise false
 */
function uniqueAddressListRemove(
    address[] storage _list,
    mapping(address => OptionalValue) storage _indexMap,
    address _value
) returns (bool isChanged) {
    OptionalValue storage indexItem = _indexMap[_value];

    isChanged = indexItem.isSet;

    if (isChanged) {
        uint256 itemIndex = indexItem.value;
        uint256 lastIndex = _list.length - 1;

        if (itemIndex != lastIndex) {
            address lastValue = _list[lastIndex];
            _list[itemIndex] = lastValue;
            _indexMap[lastValue].value = itemIndex;
        }

        _list.pop();
        delete _indexMap[_value];
    }
}

/**
 * @notice Adds or removes a value to/from a unique address value list (a list with value index mapping)
 * @dev The list size limit is checked on items adding only
 * @param _list The list reference
 * @param _indexMap The value index mapping reference
 * @param _value The address value
 * @param _flag The value inclusion flag
 * @param _sizeLimit The list size limit
 * @return isChanged True if the list was changed, otherwise false
 */
function uniqueAddressListUpdate(
    address[] storage _list,
    mapping(address => OptionalValue) storage _indexMap,
    address _value,
    bool _flag,
    uint256 _sizeLimit
) returns (bool isChanged) {
    return
        _flag
            ? uniqueAddressListAdd(_list, _indexMap, _value, _sizeLimit)
            : uniqueAddressListRemove(_list, _indexMap, _value);
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

/**
 * @notice Emitted when an attempt to burn a token fails
 */
error TokenBurnError();

/**
 * @notice Emitted when an attempt to mint a token fails
 */
error TokenMintError();

/**
 * @notice Emitted when a zero address is specified where it is not allowed
 */
error ZeroAddressError();

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

/**
 * @notice Emitted when the account is not a contract
 * @param account The account address
 */
error NonContractAddressError(address account);

/**
 * @notice Function to check if the account is a contract
 * @return The account contract status flag
 */
function isContract(address _account) view returns (bool) {
    return _account.code.length > 0;
}

/**
 * @notice Function to require an account to be a contract
 */
function requireContract(address _account) view {
    if (!isContract(_account)) {
        revert NonContractAddressError(_account);
    }
}

/**
 * @notice Function to require an account to be a contract or a zero address
 */
function requireContractOrZeroAddress(address _account) view {
    if (_account != address(0)) {
        requireContract(_account);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

/**
 * @notice Emitted when an approval action fails
 */
error SafeApproveError();

/**
 * @notice Emitted when a transfer action fails
 */
error SafeTransferError();

/**
 * @notice Emitted when a transferFrom action fails
 */
error SafeTransferFromError();

/**
 * @notice Emitted when a transfer of the native token fails
 */
error SafeTransferNativeError();

/**
 * @notice Safely approve the token to the account
 * @param _token The token address
 * @param _to The token approval recipient address
 * @param _value The token approval amount
 */
function safeApprove(address _token, address _to, uint256 _value) {
    // 0x095ea7b3 is the selector for "approve(address,uint256)"
    (bool success, bytes memory data) = _token.call(
        abi.encodeWithSelector(0x095ea7b3, _to, _value)
    );

    bool condition = success && (data.length == 0 || abi.decode(data, (bool)));

    if (!condition) {
        revert SafeApproveError();
    }
}

/**
 * @notice Safely transfer the token to the account
 * @param _token The token address
 * @param _to The token transfer recipient address
 * @param _value The token transfer amount
 */
function safeTransfer(address _token, address _to, uint256 _value) {
    // 0xa9059cbb is the selector for "transfer(address,uint256)"
    (bool success, bytes memory data) = _token.call(
        abi.encodeWithSelector(0xa9059cbb, _to, _value)
    );

    bool condition = success && (data.length == 0 || abi.decode(data, (bool)));

    if (!condition) {
        revert SafeTransferError();
    }
}

/**
 * @notice Safely transfer the token between the accounts
 * @param _token The token address
 * @param _from The token transfer source address
 * @param _to The token transfer recipient address
 * @param _value The token transfer amount
 */
function safeTransferFrom(address _token, address _from, address _to, uint256 _value) {
    // 0x23b872dd is the selector for "transferFrom(address,address,uint256)"
    (bool success, bytes memory data) = _token.call(
        abi.encodeWithSelector(0x23b872dd, _from, _to, _value)
    );

    bool condition = success && (data.length == 0 || abi.decode(data, (bool)));

    if (!condition) {
        revert SafeTransferFromError();
    }
}

/**
 * @notice Safely transfer the native token to the account
 * @param _to The native token transfer recipient address
 * @param _value The native token transfer amount
 */
function safeTransferNative(address _to, uint256 _value) {
    (bool success, ) = _to.call{ value: _value }(new bytes(0));

    if (!success) {
        revert SafeTransferNativeError();
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

/**
 * @title ITokenBalance
 * @notice Token balance interface
 */
interface ITokenBalance {
    /**
     * @notice Getter of the token balance by the account
     * @param _account The account address
     * @return Token balance
     */
    function balanceOf(address _account) external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

/**
 * @title ITokenBurn
 * @notice Token burning interface
 */
interface ITokenBurn {
    /**
     * @notice Burns tokens from the account, reducing the total supply
     * @param _from The token holder account address
     * @param _amount The number of tokens to burn
     * @return Token burning success status
     */
    function burn(address _from, uint256 _amount) external returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

/**
 * @title ITokenDecimals
 * @notice Token decimals interface
 */
interface ITokenDecimals {
    /**
     * @notice Getter of the token decimals
     * @return Token decimals
     */
    function decimals() external pure returns (uint8);
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

import { ERC20 } from 'solmate/src/tokens/ERC20.sol';
import { BurnerRole } from './roles/BurnerRole.sol';
import { MinterRole } from './roles/MinterRole.sol';
import { MultichainRouterRole } from './roles/MultichainRouterRole.sol';
import { Pausable } from './Pausable.sol';
import { ZeroAddressError } from './Errors.sol';
import './Constants.sol' as Constants;

/**
 * @title MultichainTokenBase
 * @notice Base contract that implements the Multichain token logic
 */
abstract contract MultichainTokenBase is Pausable, ERC20, MultichainRouterRole {
    /**
     * @dev Anyswap ERC20 standard
     */
    address public immutable underlying;

    bool private immutable useExplicitAccess;

    /**
     * @notice Emitted when token burning is not allowed to the caller
     */
    error BurnAccessError();

    /**
     * @notice Emitted when the token allowance is not sufficient for burning
     */
    error BurnAllowanceError();

    /**
     * @notice Emitted when token minting is not allowed to the caller
     */
    error MintAccessError();

    /**
     * @notice Initializes the MultichainTokenBase properties of descendant contracts
     * @param _name The ERC20 token name
     * @param _symbol The ERC20 token symbol
     * @param _decimals The ERC20 token decimals
     * @param _useExplicitAccess The mint and burn actions access flag
     */
    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        bool _useExplicitAccess
    ) ERC20(_name, _symbol, _decimals) {
        underlying = address(0);
        useExplicitAccess = _useExplicitAccess;
    }

    /**
     * @notice Updates the Multichain Router role status for the account
     * @param _account The account address
     * @param _value The Multichain Router role status flag
     */
    function setMultichainRouter(address _account, bool _value) external onlyManager {
        _setMultichainRouter(_account, _value);
    }

    /**
     * @notice Mints tokens and assigns them to the account, increasing the total supply
     * @dev The mint function returns a boolean value, as required by the Anyswap ERC20 standard
     * @param _to The token receiver account address
     * @param _amount The number of tokens to mint
     * @return Token minting success status
     */
    function mint(address _to, uint256 _amount) external whenNotPaused returns (bool) {
        bool condition = isMultichainRouter(msg.sender) ||
            (useExplicitAccess && _isExplicitMinter());

        if (!condition) {
            revert MintAccessError();
        }

        _mint(_to, _amount);

        return true;
    }

    /**
     * @notice Burns tokens from the account, reducing the total supply
     * @dev The burn function returns a boolean value, as required by the Anyswap ERC20 standard
     * @param _from The token holder account address
     * @param _amount The number of tokens to burn
     * @return Token burning success status
     */
    function burn(address _from, uint256 _amount) external whenNotPaused returns (bool) {
        bool condition = isMultichainRouter(msg.sender) ||
            (useExplicitAccess && _isExplicitBurner());

        if (!condition) {
            revert BurnAccessError();
        }

        if (_from == address(0)) {
            revert ZeroAddressError();
        }

        uint256 allowed = allowance[_from][msg.sender];

        if (allowed < _amount) {
            revert BurnAllowanceError();
        }

        if (allowed != Constants.INFINITY) {
            // Cannot overflow because the allowed value
            // is greater or equal to the amount
            unchecked {
                allowance[_from][msg.sender] = allowed - _amount;
            }
        }

        _burn(_from, _amount);

        return true;
    }

    /**
     * @dev Override to add explicit minter access
     */
    function _isExplicitMinter() internal view virtual returns (bool) {
        return false;
    }

    /**
     * @dev Override to add explicit burner access
     */
    function _isExplicitBurner() internal view virtual returns (bool) {
        return false;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

import { Pausable as PausableBase } from '@openzeppelin/contracts/security/Pausable.sol';
import { ManagerRole } from './roles/ManagerRole.sol';

/**
 * @title Pausable
 * @notice Base contract that implements the emergency pause mechanism
 */
abstract contract Pausable is PausableBase, ManagerRole {
    /**
     * @notice Enter pause state
     */
    function pause() external onlyManager whenNotPaused {
        _pause();
    }

    /**
     * @notice Exit pause state
     */
    function unpause() external onlyManager whenPaused {
        _unpause();
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

import { RoleBearers } from './RoleBearers.sol';

/**
 * @title AssetSpenderRole
 * @notice Base contract that implements the Asset Spender role
 */
abstract contract AssetSpenderRole is RoleBearers {
    bytes32 private constant ROLE_KEY = keccak256('AssetSpender');

    /**
     * @notice Emitted when the Asset Spender role status for the account is updated
     * @param account The account address
     * @param value The Asset Spender role status flag
     */
    event SetAssetSpender(address indexed account, bool indexed value);

    /**
     * @notice Emitted when the caller is not an Asset Spender role bearer
     */
    error OnlyAssetSpenderError();

    /**
     * @dev Modifier to check if the caller is an Asset Spender role bearer
     */
    modifier onlyAssetSpender() {
        if (!isAssetSpender(msg.sender)) {
            revert OnlyAssetSpenderError();
        }

        _;
    }

    /**
     * @notice Getter of the Asset Spender role bearer count
     * @return The Asset Spender role bearer count
     */
    function assetSpenderCount() external view returns (uint256) {
        return _roleBearerCount(ROLE_KEY);
    }

    /**
     * @notice Getter of the complete list of the Asset Spender role bearers
     * @return The complete list of the Asset Spender role bearers
     */
    function fullAssetSpenderList() external view returns (address[] memory) {
        return _fullRoleBearerList(ROLE_KEY);
    }

    /**
     * @notice Getter of the Asset Spender role bearer status
     * @param _account The account address
     */
    function isAssetSpender(address _account) public view returns (bool) {
        return _isRoleBearer(ROLE_KEY, _account);
    }

    function _setAssetSpender(address _account, bool _value) internal {
        _setRoleBearer(ROLE_KEY, _account, _value);

        emit SetAssetSpender(_account, _value);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

import { RoleBearers } from './RoleBearers.sol';

/**
 * @title BurnerRole
 * @notice Base contract that implements the Burner role
 */
abstract contract BurnerRole is RoleBearers {
    bytes32 private constant ROLE_KEY = keccak256('Burner');

    /**
     * @notice Emitted when the Burner role status for the account is updated
     * @param account The account address
     * @param value The Burner role status flag
     */
    event SetBurner(address indexed account, bool indexed value);

    /**
     * @notice Getter of the Burner role bearer count
     * @return The Burner role bearer count
     */
    function burnerCount() external view returns (uint256) {
        return _roleBearerCount(ROLE_KEY);
    }

    /**
     * @notice Getter of the complete list of the Burner role bearers
     * @return The complete list of the Burner role bearers
     */
    function fullBurnerList() external view returns (address[] memory) {
        return _fullRoleBearerList(ROLE_KEY);
    }

    /**
     * @notice Getter of the Burner role bearer status
     * @param _account The account address
     */
    function isBurner(address _account) public view returns (bool) {
        return _isRoleBearer(ROLE_KEY, _account);
    }

    function _setBurner(address _account, bool _value) internal {
        _setRoleBearer(ROLE_KEY, _account, _value);

        emit SetBurner(_account, _value);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

import { Ownable } from '@openzeppelin/contracts/access/Ownable.sol';
import { RoleBearers } from './RoleBearers.sol';

/**
 * @title ManagerRole
 * @notice Base contract that implements the Manager role.
 * The manager role is a high-permission role for core team members only.
 * Managers can set vaults and routers addresses, fees, cross-chain protocols,
 * and other parameters for Interchain (cross-chain) swaps and single-network swaps.
 * Please note, the manager role is unique for every contract,
 * hence different addresses may be assigned as managers for different contracts.
 */
abstract contract ManagerRole is Ownable, RoleBearers {
    bytes32 private constant ROLE_KEY = keccak256('Manager');

    /**
     * @notice Emitted when the Manager role status for the account is updated
     * @param account The account address
     * @param value The Manager role status flag
     */
    event SetManager(address indexed account, bool indexed value);

    /**
     * @notice Emitted when the Manager role status for the account is renounced
     * @param account The account address
     */
    event RenounceManagerRole(address indexed account);

    /**
     * @notice Emitted when the caller is not a Manager role bearer
     */
    error OnlyManagerError();

    /**
     * @dev Modifier to check if the caller is a Manager role bearer
     */
    modifier onlyManager() {
        if (!isManager(msg.sender)) {
            revert OnlyManagerError();
        }

        _;
    }

    /**
     * @notice Updates the Manager role status for the account
     * @param _account The account address
     * @param _value The Manager role status flag
     */
    function setManager(address _account, bool _value) public onlyOwner {
        _setRoleBearer(ROLE_KEY, _account, _value);

        emit SetManager(_account, _value);
    }

    /**
     * @notice Renounces the Manager role
     */
    function renounceManagerRole() external onlyManager {
        _setRoleBearer(ROLE_KEY, msg.sender, false);

        emit RenounceManagerRole(msg.sender);
    }

    /**
     * @notice Getter of the Manager role bearer count
     * @return The Manager role bearer count
     */
    function managerCount() external view returns (uint256) {
        return _roleBearerCount(ROLE_KEY);
    }

    /**
     * @notice Getter of the complete list of the Manager role bearers
     * @return The complete list of the Manager role bearers
     */
    function fullManagerList() external view returns (address[] memory) {
        return _fullRoleBearerList(ROLE_KEY);
    }

    /**
     * @notice Getter of the Manager role bearer status
     * @param _account The account address
     */
    function isManager(address _account) public view returns (bool) {
        return _isRoleBearer(ROLE_KEY, _account);
    }

    function _initRoles(
        address _owner,
        address[] memory _managers,
        bool _addOwnerToManagers
    ) internal {
        address ownerAddress = _owner == address(0) ? msg.sender : _owner;

        for (uint256 index; index < _managers.length; index++) {
            setManager(_managers[index], true);
        }

        if (_addOwnerToManagers && !isManager(ownerAddress)) {
            setManager(ownerAddress, true);
        }

        if (ownerAddress != msg.sender) {
            transferOwnership(ownerAddress);
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

import { RoleBearers } from './RoleBearers.sol';

/**
 * @title MinterRole
 * @notice Base contract that implements the Minter role
 */
abstract contract MinterRole is RoleBearers {
    bytes32 private constant ROLE_KEY = keccak256('Minter');

    /**
     * @notice Emitted when the Minter role status for the account is updated
     * @param account The account address
     * @param value The Minter role status flag
     */
    event SetMinter(address indexed account, bool indexed value);

    /**
     * @notice Getter of the Minter role bearer count
     * @return The Minter role bearer count
     */
    function minterCount() external view returns (uint256) {
        return _roleBearerCount(ROLE_KEY);
    }

    /**
     * @notice Getter of the complete list of the Minter role bearers
     * @return The complete list of the Minter role bearers
     */
    function fullMinterList() external view returns (address[] memory) {
        return _fullRoleBearerList(ROLE_KEY);
    }

    /**
     * @notice Getter of the Minter role bearer status
     * @param _account The account address
     */
    function isMinter(address _account) public view returns (bool) {
        return _isRoleBearer(ROLE_KEY, _account);
    }

    function _setMinter(address _account, bool _value) internal {
        _setRoleBearer(ROLE_KEY, _account, _value);

        emit SetMinter(_account, _value);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

import { RoleBearers } from './RoleBearers.sol';

/**
 * @title MultichainRouterRole
 * @notice Base contract that implements the Multichain Router role
 */
abstract contract MultichainRouterRole is RoleBearers {
    bytes32 private constant ROLE_KEY = keccak256('MultichainRouter');

    /**
     * @notice Emitted when the Multichain Router role status for the account is updated
     * @param account The account address
     * @param value The Multichain Router role status flag
     */
    event SetMultichainRouter(address indexed account, bool indexed value);

    /**
     * @notice Getter of the Multichain Router role bearer count
     * @return The Multichain Router role bearer count
     */
    function multichainRouterCount() external view returns (uint256) {
        return _roleBearerCount(ROLE_KEY);
    }

    /**
     * @notice Getter of the complete list of the Multichain Router role bearers
     * @return The complete list of the Multichain Router role bearers
     */
    function fullMultichainRouterList() external view returns (address[] memory) {
        return _fullRoleBearerList(ROLE_KEY);
    }

    /**
     * @notice Getter of the Multichain Router role bearer status
     * @param _account The account address
     */
    function isMultichainRouter(address _account) public view returns (bool) {
        return _isRoleBearer(ROLE_KEY, _account);
    }

    function _setMultichainRouter(address _account, bool _value) internal {
        _setRoleBearer(ROLE_KEY, _account, _value);

        emit SetMultichainRouter(_account, _value);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

import '../Constants.sol' as Constants;
import '../DataStructures.sol' as DataStructures;

/**
 * @title RoleBearers
 * @notice Base contract that implements role-based access control
 * @dev A custom implementation providing full role bearer lists
 */
abstract contract RoleBearers {
    mapping(bytes32 /*roleKey*/ => address[] /*roleBearers*/) private roleBearerTable;
    mapping(bytes32 /*roleKey*/ => mapping(address /*account*/ => DataStructures.OptionalValue /*status*/))
        private roleBearerIndexTable;

    function _setRoleBearer(bytes32 _roleKey, address _account, bool _value) internal {
        DataStructures.uniqueAddressListUpdate(
            roleBearerTable[_roleKey],
            roleBearerIndexTable[_roleKey],
            _account,
            _value,
            Constants.LIST_SIZE_LIMIT_DEFAULT
        );
    }

    function _isRoleBearer(bytes32 _roleKey, address _account) internal view returns (bool) {
        return roleBearerIndexTable[_roleKey][_account].isSet;
    }

    function _roleBearerCount(bytes32 _roleKey) internal view returns (uint256) {
        return roleBearerTable[_roleKey].length;
    }

    function _fullRoleBearerList(bytes32 _roleKey) internal view returns (address[] memory) {
        return roleBearerTable[_roleKey];
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

/**
 * @title SystemVersionId
 * @notice Base contract providing the system version identifier
 */
abstract contract SystemVersionId {
    /**
     * @dev The system version identifier
     */
    uint256 public constant SYSTEM_VERSION_ID = uint256(keccak256('Testnet - Initial B'));
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

import { ERC20 } from 'solmate/src/tokens/ERC20.sol';
import { ReentrancyGuard } from '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import { ITokenDecimals } from './interfaces/ITokenDecimals.sol';
import { CallerGuard } from './CallerGuard.sol';
import { MultichainTokenBase } from './MultichainTokenBase.sol';
import './helpers/TransferHelper.sol' as TransferHelper;
import './Constants.sol' as Constants;

/**
 * @title VaultBase
 * @notice Base contract that implements the vault logic
 */
abstract contract VaultBase is MultichainTokenBase, ReentrancyGuard, CallerGuard {
    /**
     * @dev The vault asset address
     */
    address public immutable asset;

    /**
     * @dev The total vault token supply limit
     */
    uint256 public totalSupplyLimit;

    /**
     * @notice Emitted when the total supply limit is set
     * @param limit The total supply limit value
     */
    event SetTotalSupplyLimit(uint256 limit);

    /**
     * @notice Emitted when a deposit action is performed
     * @param caller The address of the depositor account
     * @param assetAmount The amount of the deposited asset
     */
    event Deposit(address indexed caller, uint256 assetAmount);

    /**
     * @notice Emitted when a withdrawal action is performed
     * @param caller The address of the withdrawal account
     * @param assetAmount The amount of the withdrawn asset
     */
    event Withdraw(address indexed caller, uint256 assetAmount);

    /**
     * @notice Emitted when the total supply limit is exceeded
     */
    error TotalSupplyLimitError();

    /**
     * @notice Emitted when a deposit is attempted with a zero amount
     */
    error ZeroAmountError();

    /**
     * @notice Initializes the VaultBase properties of descendant contracts
     * @param _asset The vault asset address
     * @param _name The ERC20 token name
     * @param _symbol The ERC20 token symbol
     * @param _depositAllowed The initial state of deposit availability
     */
    constructor(
        address _asset,
        string memory _name,
        string memory _symbol,
        bool _depositAllowed
    ) MultichainTokenBase(_name, _symbol, ITokenDecimals(_asset).decimals(), false) {
        asset = _asset;

        _setTotalSupplyLimit(_depositAllowed ? Constants.INFINITY : 0);
    }

    /**
     * @notice Sets the total supply
     * @dev Decimals = vault token decimals = asset decimals
     * @param _limit The total supply limit value
     */
    function setTotalSupplyLimit(uint256 _limit) external onlyManager {
        _setTotalSupplyLimit(_limit);
    }

    /**
     * @notice Performs a deposit action. User deposits usdc/usdt for iusdc/iusdt used in Stablecoin Farm.
     * @param _assetAmount The amount of the deposited asset
     */
    function deposit(uint256 _assetAmount) external virtual whenNotPaused nonReentrant checkCaller {
        if (_assetAmount == 0) {
            revert ZeroAmountError();
        }

        if (totalSupply + _assetAmount > totalSupplyLimit) {
            revert TotalSupplyLimitError();
        }

        // Need to transfer before minting or ERC777s could reenter
        TransferHelper.safeTransferFrom(asset, msg.sender, address(this), _assetAmount);

        _mint(msg.sender, _assetAmount);

        emit Deposit(msg.sender, _assetAmount);
    }

    /**
     * @notice Performs a withdrawal action
     * @param _assetAmount The amount of the withdrawn asset
     */
    function withdraw(
        uint256 _assetAmount
    ) external virtual whenNotPaused nonReentrant checkCaller {
        _burn(msg.sender, _assetAmount);

        emit Withdraw(msg.sender, _assetAmount);

        TransferHelper.safeTransfer(asset, msg.sender, _assetAmount);
    }

    function _setTotalSupplyLimit(uint256 _limit) private {
        totalSupplyLimit = _limit;

        emit SetTotalSupplyLimit(_limit);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}