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

import { BalanceManagement } from '../BalanceManagement.sol';
import { ZeroAddressError } from '../Errors.sol';
import '../helpers/TransferHelper.sol' as TransferHelper;
import '../Constants.sol' as Constants;
import '../DataStructures.sol' as DataStructures;

/**
 * @title FeeMediator
 * @notice The fees distribution mediator contract
 */
contract FeeMediator is BalanceManagement {
    /**
     * @dev The address of the buyback account
     */
    address public buybackAddress;

    /**
     * @dev The address of the ITP token lockers distribution account
     */
    address public feeDistributionITPLockersAddress;

    /**
     * @dev The address of the LP token lockers distribution account
     */
    address public feeDistributionLPLockersAddress;

    /**
     * @dev The address of the treasury account
     */
    address public treasuryAddress;

    /**
     * @dev The share of the distribution for the buyback (in milli-percent, e.g., 100 is 0.1%)
     */
    uint256 public buybackPart;

    /**
     * @dev The share of the distribution for the ITP token lockers (in milli-percent, e.g., 100 is 0.1%)
     */
    uint256 public ITPLockersPart;

    /**
     * @dev The share of the distribution for the LP token lockers (in milli-percent, e.g., 100 is 0.1%)
     */
    uint256 public LPLockersPart;

    /**
     * @dev The list of the asset token addresses
     */
    address[] public assetList;

    /**
     * @dev The indices of the asset token address list
     */
    mapping(address /*assetAddress*/ => DataStructures.OptionalValue /*assetIndex*/)
        public assetIndexMap;

    /**
     * @notice Emitted when the address of the buyback account is set
     * @param buybackAddress The address of the buyback account
     */
    event SetBuybackAddress(address indexed buybackAddress);

    /**
     * @notice Emitted when the address of the ITP token lockers distribution account is set
     * @param feeDistributionITPLockersAddress The address of the ITP token lockers distribution account
     */
    event SetFeeDistributionITPLockersAddress(address indexed feeDistributionITPLockersAddress);

    /**
     * @notice Emitted when the address of the LP token lockers distribution account is set
     * @param feeDistributionLPLockersAddress The address of the LP token lockers distribution account
     */
    event SetFeeDistributionLPLockersAddress(address indexed feeDistributionLPLockersAddress);

    /**
     * @notice Emitted when the address of the treasury account is set
     * @param treasuryAddress The address of the treasury account
     */
    event SetTreasuryAddress(address indexed treasuryAddress);

    /**
     * @notice Emitted when the distribution percentage is updated
     * @dev The part values are in milli-percent, e.g., 100 is 0.1%
     * @param buybackPart The share of the distribution for the buyback
     * @param ITPLockersPart The share of the distribution for the ITP token lockers
     * @param LPLockersPart The share of the distribution for the LP token lockers
     */
    event SetDistributionParts(uint256 buybackPart, uint256 ITPLockersPart, uint256 LPLockersPart);

    /**
     * @notice Emitted when the provided distribution percentage values are not consistent
     */
    error PartValueError();

    /**
     * @notice Deploys the FeeMediator contract
     * @dev The part values are in milli-percent, e.g., 100 is 0.1%
     * @param _buybackAddress The initial address of the buyback account
     * @param _ITPLockersAddress The initial address of the ITP token lockers distribution account
     * @param _LPLockersAddress The initial address of the LP token lockers distribution account
     * @param _treasuryAddress The initial address of the treasury account
     * @param _buybackPart The initial share of the distribution for the buyback (in milli-percent)
     * @param _ITPLockersPart The initial share of the distribution for the ITP token lockers (in milli-percent)
     * @param _LPLockersPart The initial share of the distribution for the LP token lockers (in milli-percent)
     * @param _assets The initial list of the asset token addresses
     * @param _owner The address of the initial owner of the contract
     * @param _managers The addresses of initial managers of the contract
     * @param _addOwnerToManagers The flag to optionally add the owner to the list of managers
     */
    constructor(
        address _buybackAddress,
        address _ITPLockersAddress,
        address _LPLockersAddress,
        address _treasuryAddress,
        uint256 _buybackPart,
        uint256 _ITPLockersPart,
        uint256 _LPLockersPart,
        address[] memory _assets,
        address _owner,
        address[] memory _managers,
        bool _addOwnerToManagers
    ) {
        if (
            _buybackAddress == address(0) ||
            _ITPLockersAddress == address(0) ||
            _LPLockersAddress == address(0) ||
            _treasuryAddress == address(0)
        ) {
            revert ZeroAddressError();
        }

        buybackAddress = _buybackAddress;
        feeDistributionITPLockersAddress = _ITPLockersAddress;
        feeDistributionLPLockersAddress = _LPLockersAddress;
        treasuryAddress = _treasuryAddress;

        _setDistributionParts(_buybackPart, _ITPLockersPart, _LPLockersPart);

        for (uint256 index; index < _assets.length; index++) {
            _setAsset(_assets[index], true);
        }

        _initRoles(_owner, _managers, _addOwnerToManagers);
    }

    /**
     * @notice Sets the address of the buyback account
     * @param _buybackAddress The address of the buyback account
     */
    function setBuybackAddress(address _buybackAddress) external onlyManager {
        if (_buybackAddress == address(0)) {
            revert ZeroAddressError();
        }

        buybackAddress = _buybackAddress;

        emit SetBuybackAddress(_buybackAddress);
    }

    /**
     * @notice Sets the address of the ITP token lockers distribution account
     * @param _ITPLockersAddress The address of the ITP token lockers distribution account
     */
    function setFeeDistributionITPLockersAddress(address _ITPLockersAddress) external onlyManager {
        if (_ITPLockersAddress == address(0)) {
            revert ZeroAddressError();
        }

        feeDistributionITPLockersAddress = _ITPLockersAddress;

        emit SetFeeDistributionITPLockersAddress(_ITPLockersAddress);
    }

    /**
     * @notice Sets the address of the LP token lockers distribution account
     * @param _LPLockersAddress The address of the LP token lockers distribution account
     */
    function setFeeDistributionLPLockersAddress(address _LPLockersAddress) external onlyManager {
        if (_LPLockersAddress == address(0)) {
            revert ZeroAddressError();
        }

        feeDistributionLPLockersAddress = _LPLockersAddress;

        emit SetFeeDistributionITPLockersAddress(_LPLockersAddress);
    }

    /**
     * @notice Sets the address of the treasury account
     * @param _treasuryAddress The address of the treasury account
     */
    function setTreasuryAddress(address _treasuryAddress) external onlyManager {
        if (_treasuryAddress == address(0)) {
            revert ZeroAddressError();
        }

        treasuryAddress = _treasuryAddress;

        emit SetTreasuryAddress(_treasuryAddress);
    }

    /**
     * @notice Updates the distribution percentage
     * @dev The part values are in milli-percent, e.g., 100 is 0.1%
     * @param _buybackPart The share of the distribution for the buyback
     * @param _ITPLockersPart The share of the distribution for the ITP token lockers
     * @param _LPLockersPart The share of the distribution for the LP token lockers
     */
    function setDistributionParts(
        uint256 _buybackPart,
        uint256 _ITPLockersPart,
        uint256 _LPLockersPart
    ) external onlyManager {
        _setDistributionParts(_buybackPart, _ITPLockersPart, _LPLockersPart);
    }

    /**
     * @notice Updates the asset status by the asset token address
     * @param _tokenAddress The asset token address
     * @param _value The asset status flag
     */
    function setAsset(address _tokenAddress, bool _value) external onlyManager {
        _setAsset(_tokenAddress, _value);
    }

    /**
     * @notice Performs the distribution of the fees
     */
    function process() external onlyManager {
        uint256 assetListLength = assetList.length;

        for (uint256 assetIndex; assetIndex < assetListLength; assetIndex++) {
            address assetToken = assetList[assetIndex];

            uint256 assetBalance = tokenBalance(assetToken);

            if (assetBalance > 0) {
                uint256 buybackAmount = (assetBalance * buybackPart) /
                    Constants.MILLIPERCENT_FACTOR;
                uint256 ITPLockersAmount = (assetBalance * ITPLockersPart) /
                    Constants.MILLIPERCENT_FACTOR;
                uint256 LPLockersAmount = (assetBalance * LPLockersPart) /
                    Constants.MILLIPERCENT_FACTOR;
                uint256 treasuryAmount = assetBalance -
                    buybackAmount -
                    ITPLockersAmount -
                    LPLockersAmount;

                if (buybackAmount > 0) {
                    // Transfer to the buyback account
                    TransferHelper.safeTransfer(assetToken, buybackAddress, buybackAmount);
                }

                if (ITPLockersAmount > 0) {
                    // Transfer to the fee distribution (ITP lockers) account
                    TransferHelper.safeTransfer(
                        assetToken,
                        feeDistributionITPLockersAddress,
                        ITPLockersAmount
                    );
                }

                if (LPLockersAmount > 0) {
                    // Transfer to the fee distribution (LP lockers) account
                    TransferHelper.safeTransfer(
                        assetToken,
                        feeDistributionLPLockersAddress,
                        LPLockersAmount
                    );
                }

                // Transfer to the treasury account
                if (treasuryAmount > 0) {
                    TransferHelper.safeTransfer(assetToken, treasuryAddress, treasuryAmount);
                }
            }
        }
    }

    /**
     * @notice Getter of the registered asset count
     * @return The registered asset count
     */
    function assetCount() external view returns (uint256) {
        return assetList.length;
    }

    /**
     * @notice Getter of the complete list of the registered assets
     * @return The complete list of the registered assets
     */
    function fullAssetList() external view returns (address[] memory) {
        return assetList;
    }

    /**
     * @notice Getter of the asset status by the token address
     * @param _tokenAddress The token address
     * @return The asset status flag
     */
    function isAsset(address _tokenAddress) public view returns (bool) {
        return assetIndexMap[_tokenAddress].isSet;
    }

    /**
     * @notice Getter of the reserved token flag
     * @param _tokenAddress The address of the token
     * @return The reserved token flag
     */
    function isReservedToken(address _tokenAddress) public view override returns (bool) {
        return isAsset(_tokenAddress);
    }

    function _setDistributionParts(
        uint256 _buybackPart, // milli-percent
        uint256 _ITPLockersPart, // milli-percent
        uint256 _LPLockersPart // milli-percent
    ) private {
        if (_buybackPart + _ITPLockersPart + _LPLockersPart > Constants.MILLIPERCENT_FACTOR) {
            revert PartValueError();
        }

        buybackPart = _buybackPart;
        ITPLockersPart = _ITPLockersPart;
        LPLockersPart = _LPLockersPart;

        emit SetDistributionParts(_buybackPart, _ITPLockersPart, _LPLockersPart);
    }

    function _setAsset(address _tokenAddress, bool _value) private {
        DataStructures.uniqueAddressListUpdate(
            assetList,
            assetIndexMap,
            _tokenAddress,
            _value,
            Constants.LIST_SIZE_LIMIT_DEFAULT
        );
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