// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.17;

import { ITokenDecimals } from './interfaces/ITokenDecimals.sol';
import { ITokenBurn } from './interfaces/ITokenBurn.sol';
import { VaultBase } from './VaultBase.sol';
import { AssetSpenderRole } from './AssetSpenderRole.sol';
import { MultichainRouterRole } from './MultichainRouterRole.sol';
import { BalanceManagement } from './BalanceManagement.sol';


contract Vault is VaultBase, AssetSpenderRole, MultichainRouterRole, BalanceManagement {

    error TokenDecimalsError();
    error TokenNotSetError();
    error TokenNotEnabledError();

    address public immutable underlying; // Anyswap ERC20 standard

    address public variableToken;
    bool public variableTokenEnabled;

    event SetVariableToken(address indexed variableToken);
    event SetVariableTokenEnabled(bool indexed isEnabled);
    event RedeemVariableToken(address indexed caller, uint256 amount);

    constructor(
        address _asset,
        string memory _name,
        string memory _symbol,
        address[] memory _assetSpenders,
        bool _depositAllowed,
        address _ownerAddress,
        bool _grantManagerRoleToOwner
    )
        VaultBase(
            _asset,
            _name,
            _symbol,
            _depositAllowed
        )
    {
        underlying = address(0);

        for (uint256 index; index < _assetSpenders.length; index++) {
            _setAssetSpender(_assetSpenders[index], true);
        }

        _initRoles(_ownerAddress, _grantManagerRoleToOwner);
    }

    function setAssetSpender(address _assetSpender, bool _value) external onlyManager {
        _setAssetSpender(_assetSpender, _value);
    }

    function setMultichainRouter(address _account, bool _value) external onlyManager {
        _setMultichainRouter(_account, _value);
    }

    function setVariableToken(address _variableToken, bool _isEnabled) external onlyManager {
        // Zero address is allowed
        if (
            _variableToken != address(0) &&
            ITokenDecimals(_variableToken).decimals() != decimals
        ) {
            revert TokenDecimalsError();
        }

        variableToken = _variableToken;

        emit SetVariableToken(_variableToken);

        _setVariableTokenEnabled(_isEnabled);
    }

    function setVariableTokenEnabled(bool _isEnabled) external onlyManager {
        _setVariableTokenEnabled(_isEnabled);
    }

    function mint(address _to, uint256 _amount) external onlyMultichainRouter returns (bool) {
        _mint(_to, _amount);

        return true;
    }

    function burn(address _from, uint256 _amount) external onlyMultichainRouter returns (bool) {
        _burn(_from, _amount);

        return true;
    }

    function requestAsset(
        uint256 _amount,
        address _to,
        bool _forVariableToken
    )
        external
        onlyAssetSpender
        whenNotPaused
        returns (address assetAddress)
    {
        if (_forVariableToken && !variableTokenEnabled) {
            revert TokenNotEnabledError();
        }

        safeTransfer(asset, _to, _amount);

        return asset;
    }

    function redeemVariableToken(uint256 _amount) external whenNotPaused {
        if (variableToken == address(0)) {
            revert TokenNotSetError();
        }

        if (!variableTokenEnabled) {
            revert TokenNotEnabledError();
        }

        ITokenBurn(variableToken).burn(msg.sender, _amount);

        emit RedeemVariableToken(msg.sender, _amount);

        safeTransfer(asset, msg.sender, _amount);
    }

    function isReservedToken(address _tokenAddress) public view override returns (bool) {
        return _tokenAddress == asset;
    }

    function _setVariableTokenEnabled(bool _isEnabled) private {
        variableTokenEnabled = _isEnabled;

        emit SetVariableTokenEnabled(_isEnabled);
    }

    function _initRoles(address _ownerAddress, bool _grantManagerRoleToOwner) private {
        address ownerAddress =
            _ownerAddress == address(0) ?
                msg.sender :
                _ownerAddress;

        if (_grantManagerRoleToOwner) {
            setManager(ownerAddress, true);
        }

        if (ownerAddress != msg.sender) {
            transferOwnership(ownerAddress);
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.17;

import { ITokenDecimals } from './interfaces/ITokenDecimals.sol';
import { Pausable } from './Pausable.sol';
import { ERC20 } from './ERC20.sol';
import { CallerGuard } from './CallerGuard.sol';
import { SafeTransfer } from './SafeTransfer.sol';


abstract contract VaultBase is Pausable, ERC20, CallerGuard, SafeTransfer {

    error ZeroAmountError();
    error TotalSupplyLimitError();

    address public immutable asset;
    uint256 public totalSupplyLimit;

    event SetTotalSupplyLimit(uint256 limit);

    event Deposit(address indexed caller, uint256 assetAmount);
    event Withdraw(address indexed caller, uint256 assetAmount);

    constructor(
        address _asset,
        string memory _name,
        string memory _symbol,
        bool _depositAllowed
    )
        ERC20(
            _name,
            _symbol,
            ITokenDecimals(_asset).decimals()
        )
    {
        asset = _asset;

        _setTotalSupplyLimit(
            _depositAllowed ?
                type(uint256).max :
                0
        );
    }

    // Decimals = vault token decimals = asset decimals
    function setTotalSupplyLimit(uint256 _limit) external onlyManager {
        _setTotalSupplyLimit(_limit);
    }

    function deposit(uint256 assetAmount) public virtual whenNotPaused checkCaller {
        if (assetAmount == 0) {
            revert ZeroAmountError();
        }

        if (totalSupply + assetAmount > totalSupplyLimit) {
            revert TotalSupplyLimitError();
        }

        // Need to transfer before minting or ERC777s could reenter
        safeTransferFrom(asset, msg.sender, address(this), assetAmount);

        _mint(msg.sender, assetAmount);

        emit Deposit(msg.sender, assetAmount);
    }

    function withdraw(uint256 assetAmount) public virtual whenNotPaused checkCaller {
        _burn(msg.sender, assetAmount);

        emit Withdraw(msg.sender, assetAmount);

        safeTransfer(asset, msg.sender, assetAmount);
    }

    function _setTotalSupplyLimit(uint256 _limit) private {
        totalSupplyLimit = _limit;

        emit SetTotalSupplyLimit(_limit);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.17;


interface ITokenDecimals {
    function decimals() external pure returns (uint8);
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.17;

import { DataStructures } from './DataStructures.sol';


abstract contract AssetSpenderRole is DataStructures {

    error OnlyAssetSpenderError();

    address[] public assetSpenderList;
    mapping(address => OptionalValue) public assetSpenderListIndex;

    event SetAssetSpender(address indexed account, bool indexed value);

    modifier onlyAssetSpender {
        if (!isAssetSpender(msg.sender)) {
            revert OnlyAssetSpenderError();
        }

        _;
    }

    function isAssetSpender(address _account) public view virtual returns (bool) {
        return assetSpenderListIndex[_account].isSet;
    }

    function assetSpenderCount() public view virtual returns (uint256) {
        return assetSpenderList.length;
    }

    function _setAssetSpender(address _account, bool _value) internal virtual {
        if (_value) {
            uniqueAddressListAdd(assetSpenderList, assetSpenderListIndex, _account);
        } else {
            uniqueAddressListRemove(assetSpenderList, assetSpenderListIndex, _account);
        }

        emit SetAssetSpender(_account, _value);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.17;


interface ITokenBurn {
    function burn(address _from, uint256 _amount) external returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.17;

import { DataStructures } from './DataStructures.sol';


abstract contract MultichainRouterRole is DataStructures {

    error OnlyMultichainRouterError();

    address[] public multichainRouterList;
    mapping(address => OptionalValue) public multichainRouterIndexMap;

    event SetMultichainRouter(address indexed account, bool indexed value);

    modifier onlyMultichainRouter() {
        if (!isMultichainRouter(msg.sender)) {
            revert OnlyMultichainRouterError();
        }

        _;
    }

    function isMultichainRouter(address _account) public view virtual returns (bool) {
        return multichainRouterIndexMap[_account].isSet;
    }

    function multichainRouterCount() public view virtual returns (uint256) {
        return multichainRouterList.length;
    }

    function _setMultichainRouter(address _account, bool _value) internal virtual {
        uniqueAddressListUpdate(multichainRouterList, multichainRouterIndexMap, _account, _value);

        emit SetMultichainRouter(_account, _value);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.17;

import { ITokenBalance } from './interfaces/ITokenBalance.sol';
import { ManagerRole } from './ManagerRole.sol';
import { NativeTokenAddress } from './NativeTokenAddress.sol';
import { SafeTransfer } from './SafeTransfer.sol';


abstract contract BalanceManagement is ManagerRole, NativeTokenAddress, SafeTransfer {

    error ReservedTokenError();

    function cleanup(address _tokenAddress, uint256 _tokenAmount) external onlyManager {
        if (isReservedToken(_tokenAddress)) {
            revert ReservedTokenError();
        }

        if (_tokenAddress == NATIVE_TOKEN_ADDRESS) {
            safeTransferNative(msg.sender, _tokenAmount);
        } else {
            safeTransfer(_tokenAddress, msg.sender, _tokenAmount);
        }
    }

    function tokenBalance(address _tokenAddress) public view returns (uint256) {
        if (_tokenAddress == NATIVE_TOKEN_ADDRESS) {
            return address(this).balance;
        } else {
            return ITokenBalance(_tokenAddress).balanceOf(address(this));
        }
    }

    function isReservedToken(address /*_tokenAddress*/) public view virtual returns (bool) {
        return false;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.17;


abstract contract ERC20 {

    string public name;
    string public symbol;
    uint8 public immutable decimals;

    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user balances can't exceed the max uint256 value
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
    )
        public
        virtual
        returns (bool)
    {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals

        if (allowed != type(uint256).max) {
            allowance[from][msg.sender] = allowed - amount;
        }

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user balances can't exceed the max uint256 value
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user balances can't exceed the max uint256 value
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance will never be larger than the total supply
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.17;

import { ManagerRole } from './ManagerRole.sol';


abstract contract Pausable is ManagerRole {

    error WhenNotPausedError();
    error WhenPausedError();

    bool public paused = false;

    event Pause();
    event Unpause();

    modifier whenNotPaused() {
        if (paused) {
            revert WhenNotPausedError();
        }

        _;
    }

    modifier whenPaused() {
        if (!paused) {
            revert WhenPausedError();
        }

        _;
    }

    function pause() onlyManager whenNotPaused public {
        paused = true;

        emit Pause();
    }

    function unpause() onlyManager whenPaused public {
        paused = false;

        emit Unpause();
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.17;


abstract contract SafeTransfer {

    error SafeApproveError();
    error SafeTransferError();
    error SafeTransferFromError();
    error SafeTransferNativeError();

    function safeApprove(address _token, address _to, uint256 _value) internal {
        // 0x095ea7b3 is the selector for "approve(address,uint256)"
        (bool success, bytes memory data) = _token.call(abi.encodeWithSelector(0x095ea7b3, _to, _value));

        bool condition = success && (data.length == 0 || abi.decode(data, (bool)));

        if (!condition) {
            revert SafeApproveError();
        }
    }

    function safeTransfer(address _token, address _to, uint256 _value) internal {
        // 0xa9059cbb is the selector for "transfer(address,uint256)"
        (bool success, bytes memory data) = _token.call(abi.encodeWithSelector(0xa9059cbb, _to, _value));

        bool condition = success && (data.length == 0 || abi.decode(data, (bool)));

        if (!condition) {
            revert SafeTransferError();
        }
    }

    function safeTransferFrom(address _token, address _from, address _to, uint256 _value) internal {
        // 0x23b872dd is the selector for "transferFrom(address,address,uint256)"
        (bool success, bytes memory data) = _token.call(abi.encodeWithSelector(0x23b872dd, _from, _to, _value));

        bool condition = success && (data.length == 0 || abi.decode(data, (bool)));

        if (!condition) {
            revert SafeTransferFromError();
        }
    }

    function safeTransferNative(address _to, uint256 _value) internal {
        (bool success, ) = _to.call{value: _value}(new bytes(0));

        if (!success) {
            revert SafeTransferNativeError();
        }
    }

    function safeTransferNativeUnchecked(address _to, uint256 _value) internal {
        (bool ignore, ) = _to.call{value: _value}(new bytes(0));

        ignore;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.17;

import { ManagerRole } from './ManagerRole.sol';


abstract contract CallerGuard is ManagerRole {

    error ContractCallerError();

    bool public contractCallerAllowed;

    event SetContractCallerAllowed(bool indexed value);

    modifier checkCaller {
        if (msg.sender != tx.origin && !contractCallerAllowed) {
            revert ContractCallerError();
        }

        _;
    }

    function setContractCallerAllowed(bool _value) external onlyManager {
        contractCallerAllowed = _value;

        emit SetContractCallerAllowed(_value);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.17;

import { Ownable } from './Ownable.sol';
import { DataStructures } from './DataStructures.sol';


abstract contract ManagerRole is Ownable, DataStructures {

    error OnlyManagerError();

    address[] public managerList;
    mapping(address => OptionalValue) public managerIndexMap;

    event SetManager(address indexed account, bool indexed value);

    modifier onlyManager {
        if (!isManager(msg.sender)) {
            revert OnlyManagerError();
        }

        _;
    }

    function setManager(address _account, bool _value) public virtual onlyOwner {
        _setManager(_account, _value);
    }

    function renounceManagerRole() public virtual onlyManager {
        _setManager(msg.sender, false);
    }

    function isManager(address _account) public view virtual returns (bool) {
        return managerIndexMap[_account].isSet;
    }

    function managerCount() public view virtual returns (uint256) {
        return managerList.length;
    }

    function _setManager(address _account, bool _value) private {
        uniqueAddressListUpdate(managerList, managerIndexMap, _account, _value);

        emit SetManager(_account, _value);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.17;


abstract contract DataStructures {

    struct OptionalValue {
        bool isSet;
        uint256 value;
    }

    struct KeyToValue {
        uint256 key;
        uint256 value;
    }

    struct KeyToAddressValue {
        uint256 key;
        address value;
    }

    struct KeyToAddressAndFlag {
        uint256 key;
        address value;
        bool flag;
    }

    function combinedMapSet(
        mapping(uint256 => address) storage _map,
        uint256[] storage _keyList,
        mapping(uint256 => OptionalValue) storage _keyIndexMap,
        uint256 _key,
        address _value
    )
        internal
        returns (bool isNewKey)
    {
        isNewKey = !_keyIndexMap[_key].isSet;

        if (isNewKey) {
            uniqueListAdd(_keyList, _keyIndexMap, _key);
        }

        _map[_key] = _value;
    }

    function combinedMapRemove(
        mapping(uint256 => address) storage _map,
        uint256[] storage _keyList,
        mapping(uint256 => OptionalValue) storage _keyIndexMap,
        uint256 _key
    )
        internal
        returns (bool isChanged)
    {
        isChanged = _keyIndexMap[_key].isSet;

        if (isChanged) {
            delete _map[_key];
            uniqueListRemove(_keyList, _keyIndexMap, _key);
        }
    }

    function uniqueListAdd(
        uint256[] storage _list,
        mapping(uint256 => OptionalValue) storage _indexMap,
        uint256 _value
    )
        internal
        returns (bool isChanged)
    {
        isChanged = !_indexMap[_value].isSet;

        if (isChanged) {
            _indexMap[_value] = OptionalValue(true, _list.length);
            _list.push(_value);
        }
    }

    function uniqueListRemove(
        uint256[] storage _list,
        mapping(uint256 => OptionalValue) storage _indexMap,
        uint256 _value
    )
        internal
        returns (bool isChanged)
    {
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

    function uniqueAddressListAdd(
        address[] storage _list,
        mapping(address => OptionalValue) storage _indexMap,
        address _value
    )
        internal
        returns (bool isChanged)
    {
        isChanged = !_indexMap[_value].isSet;

        if (isChanged) {
            _indexMap[_value] = OptionalValue(true, _list.length);
            _list.push(_value);
        }
    }

    function uniqueAddressListRemove(
        address[] storage _list,
        mapping(address => OptionalValue) storage _indexMap,
        address _value
    )
        internal
        returns (bool isChanged)
    {
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

    function uniqueAddressListUpdate(
        address[] storage _list,
        mapping(address => OptionalValue) storage _indexMap,
        address _value,
        bool _flag
    )
        internal
        returns (bool isChanged)
    {
        return _flag ?
            uniqueAddressListAdd(_list, _indexMap, _value) :
            uniqueAddressListRemove(_list, _indexMap, _value);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.17;

import { ZeroAddressError } from './Errors.sol';


abstract contract Ownable {

    error OnlyOwnerError();

    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        if (msg.sender != owner) {
            revert OnlyOwnerError();
        }

        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert ZeroAddressError();
        }

        address previousOwner = owner;
        owner = newOwner;

        emit OwnershipTransferred(previousOwner, newOwner);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.17;


error ZeroAddressError();

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.17;


abstract contract NativeTokenAddress {

    address public constant NATIVE_TOKEN_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.17;


interface ITokenBalance {
    function balanceOf(address _account) external view returns (uint256);
}