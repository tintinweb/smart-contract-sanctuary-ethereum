// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.6.12;

import "../utility/ContractRegistryClient.sol";
import "./interfaces/IConverterRegistryData.sol";

/**
 * @dev This contract is an integral part of the converter registry,
 * and it serves as the database contract that holds all registry data.
 *
 * The registry is separated into two different contracts for upgradeability - the data contract
 * is harder to upgrade as it requires migrating all registry data into a new contract, while
 * the registry contract itself can be easily upgraded.
 *
 * For that same reason, the data contract is simple and contains no logic beyond the basic data
 * access utilities that it exposes.
 */
contract ConverterRegistryData is IConverterRegistryData, ContractRegistryClient {
    struct Item {
        bool valid;
        uint256 index;
    }

    struct Items {
        address[] array;
        mapping(address => Item) table;
    }

    struct List {
        uint256 index;
        Items items;
    }

    struct Lists {
        address[] array;
        mapping(address => List) table;
    }

    Items private _anchors;
    Items private _liquidityPools;
    Lists private _convertibleTokens;

    /**
     * @dev initializes a new ConverterRegistryData instance
     */
    constructor(IContractRegistry registry) public ContractRegistryClient(registry) {}

    /**
     * @dev adds an anchor
     */
    function addSmartToken(IConverterAnchor anchor) external override only(CONVERTER_REGISTRY) {
        _addItem(_anchors, address(anchor));
    }

    /**
     * @dev removes an anchor
     */
    function removeSmartToken(IConverterAnchor anchor) external override only(CONVERTER_REGISTRY) {
        _removeItem(_anchors, address(anchor));
    }

    /**
     * @dev adds a liquidity pool
     */
    function addLiquidityPool(IConverterAnchor liquidityPoolAnchor) external override only(CONVERTER_REGISTRY) {
        _addItem(_liquidityPools, address(liquidityPoolAnchor));
    }

    /**
     * @dev removes a liquidity pool
     */
    function removeLiquidityPool(IConverterAnchor liquidityPoolAnchor) external override only(CONVERTER_REGISTRY) {
        _removeItem(_liquidityPools, address(liquidityPoolAnchor));
    }

    /**
     * @dev adds a convertible token
     */
    function addConvertibleToken(IReserveToken convertibleToken, IConverterAnchor anchor)
        external
        override
        only(CONVERTER_REGISTRY)
    {
        List storage list = _convertibleTokens.table[address(convertibleToken)];
        if (list.items.array.length == 0) {
            list.index = _convertibleTokens.array.length;
            _convertibleTokens.array.push(address(convertibleToken));
        }
        _addItem(list.items, address(anchor));
    }

    /**
     * @dev removes a convertible token
     */
    function removeConvertibleToken(IReserveToken convertibleToken, IConverterAnchor anchor)
        external
        override
        only(CONVERTER_REGISTRY)
    {
        List storage list = _convertibleTokens.table[address(convertibleToken)];
        _removeItem(list.items, address(anchor));
        if (list.items.array.length == 0) {
            address lastConvertibleToken = _convertibleTokens.array[_convertibleTokens.array.length - 1];
            _convertibleTokens.table[lastConvertibleToken].index = list.index;
            _convertibleTokens.array[list.index] = lastConvertibleToken;
            _convertibleTokens.array.pop();
            delete _convertibleTokens.table[address(convertibleToken)];
        }
    }

    /**
     * @dev returns the number of anchors
     */
    function getSmartTokenCount() external view override returns (uint256) {
        return _anchors.array.length;
    }

    /**
     * @dev returns the list of anchors
     */
    function getSmartTokens() external view override returns (address[] memory) {
        return _anchors.array;
    }

    /**
     * @dev returns the anchor at a given index
     */
    function getSmartToken(uint256 index) external view override returns (IConverterAnchor) {
        return IConverterAnchor(_anchors.array[index]);
    }

    /**
     * @dev checks whether or not a given value is an anchor
     */
    function isSmartToken(address value) external view override returns (bool) {
        return _anchors.table[value].valid;
    }

    /**
     * @dev returns the number of liquidity pools
     */
    function getLiquidityPoolCount() external view override returns (uint256) {
        return _liquidityPools.array.length;
    }

    /**
     * @dev returns the list of liquidity pools
     */
    function getLiquidityPools() external view override returns (address[] memory) {
        return _liquidityPools.array;
    }

    /**
     * @dev returns the liquidity pool at a given index
     */
    function getLiquidityPool(uint256 index) external view override returns (IConverterAnchor) {
        return IConverterAnchor(_liquidityPools.array[index]);
    }

    /**
     * @dev checks whether or not a given value is a liquidity pool
     */
    function isLiquidityPool(address value) external view override returns (bool) {
        return _liquidityPools.table[value].valid;
    }

    /**
     * @dev returns the number of convertible tokens
     */
    function getConvertibleTokenCount() external view override returns (uint256) {
        return _convertibleTokens.array.length;
    }

    /**
     * @dev returns the list of convertible tokens
     */
    function getConvertibleTokens() external view override returns (address[] memory) {
        return _convertibleTokens.array;
    }

    /**
     * @dev returns the convertible token at a given index
     */
    function getConvertibleToken(uint256 index) external view override returns (IReserveToken) {
        return IReserveToken(_convertibleTokens.array[index]);
    }

    /**
     * @dev checks whether or not a given value is a convertible token
     */
    function isConvertibleToken(address value) external view override returns (bool) {
        return _convertibleTokens.table[value].items.array.length > 0;
    }

    /**
     * @dev returns the number of anchors associated with a given convertible token
     */
    function getConvertibleTokenSmartTokenCount(IReserveToken convertibleToken)
        external
        view
        override
        returns (uint256)
    {
        return _convertibleTokens.table[address(convertibleToken)].items.array.length;
    }

    /**
     * @dev returns the list of anchors associated with a given convertible token
     */
    function getConvertibleTokenSmartTokens(IReserveToken convertibleToken)
        external
        view
        override
        returns (address[] memory)
    {
        return _convertibleTokens.table[address(convertibleToken)].items.array;
    }

    /**
     * @dev returns the anchor associated with a given convertible token at a given index
     */
    function getConvertibleTokenSmartToken(IReserveToken convertibleToken, uint256 index)
        external
        view
        override
        returns (IConverterAnchor)
    {
        return IConverterAnchor(_convertibleTokens.table[address(convertibleToken)].items.array[index]);
    }

    /**
     * @dev checks whether or not a given value is an anchor of a given convertible token
     */
    function isConvertibleTokenSmartToken(IReserveToken convertibleToken, address value)
        external
        view
        override
        returns (bool)
    {
        return _convertibleTokens.table[address(convertibleToken)].items.table[value].valid;
    }

    /**
     * @dev adds an item to a list of items
     */
    function _addItem(Items storage items, address value) internal validAddress(value) {
        Item storage item = items.table[value];
        require(!item.valid, "ERR_INVALID_ITEM");

        item.index = items.array.length;
        items.array.push(value);
        item.valid = true;
    }

    /**
     * @dev removes an item from a list of items
     */
    function _removeItem(Items storage items, address value) internal validAddress(value) {
        Item storage item = items.table[value];
        require(item.valid, "ERR_INVALID_ITEM");

        address lastValue = items.array[items.array.length - 1];
        items.table[lastValue].index = item.index;
        items.array[item.index] = lastValue;
        items.array.pop();
        delete items.table[value];
    }
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.6.12;

import "./Owned.sol";
import "./Utils.sol";
import "./interfaces/IContractRegistry.sol";

/**
 * @dev This is the base contract for ContractRegistry clients.
 */
contract ContractRegistryClient is Owned, Utils {
    bytes32 internal constant CONTRACT_REGISTRY = "ContractRegistry";
    bytes32 internal constant BANCOR_NETWORK = "BancorNetwork";
    bytes32 internal constant CONVERTER_FACTORY = "ConverterFactory";
    bytes32 internal constant CONVERSION_PATH_FINDER = "ConversionPathFinder";
    bytes32 internal constant CONVERTER_UPGRADER = "BancorConverterUpgrader";
    bytes32 internal constant CONVERTER_REGISTRY = "BancorConverterRegistry";
    bytes32 internal constant CONVERTER_REGISTRY_DATA = "BancorConverterRegistryData";
    bytes32 internal constant BNT_TOKEN = "BNTToken";
    bytes32 internal constant BANCOR_X = "BancorX";
    bytes32 internal constant BANCOR_X_UPGRADER = "BancorXUpgrader";
    bytes32 internal constant LIQUIDITY_PROTECTION = "LiquidityProtection";
    bytes32 internal constant NETWORK_SETTINGS = "NetworkSettings";

    // address of the current contract registry
    IContractRegistry private _registry;

    // address of the previous contract registry
    IContractRegistry private _prevRegistry;

    // only the owner can update the contract registry
    bool private _onlyOwnerCanUpdateRegistry;

    /**
     * @dev verifies that the caller is mapped to the given contract name
     */
    modifier only(bytes32 contractName) {
        _only(contractName);
        _;
    }

    // error message binary size optimization
    function _only(bytes32 contractName) internal view {
        require(msg.sender == _addressOf(contractName), "ERR_ACCESS_DENIED");
    }

    /**
     * @dev initializes a new ContractRegistryClient instance
     */
    constructor(IContractRegistry initialRegistry) internal validAddress(address(initialRegistry)) {
        _registry = IContractRegistry(initialRegistry);
        _prevRegistry = IContractRegistry(initialRegistry);
    }

    /**
     * @dev updates to the new contract registry
     */
    function updateRegistry() external {
        // verify that this function is permitted
        require(msg.sender == owner() || !_onlyOwnerCanUpdateRegistry, "ERR_ACCESS_DENIED");

        // get the new contract registry
        IContractRegistry newRegistry = IContractRegistry(_addressOf(CONTRACT_REGISTRY));

        // verify that the new contract registry is different and not zero
        require(newRegistry != _registry && address(newRegistry) != address(0), "ERR_INVALID_REGISTRY");

        // verify that the new contract registry is pointing to a non-zero contract registry
        require(newRegistry.addressOf(CONTRACT_REGISTRY) != address(0), "ERR_INVALID_REGISTRY");

        // save a backup of the current contract registry before replacing it
        _prevRegistry = _registry;

        // replace the current contract registry with the new contract registry
        _registry = newRegistry;
    }

    /**
     * @dev restores the previous contract registry
     */
    function restoreRegistry() external ownerOnly {
        // restore the previous contract registry
        _registry = _prevRegistry;
    }

    /**
     * @dev restricts the permission to update the contract registry
     */
    function restrictRegistryUpdate(bool restrictOwnerOnly) public ownerOnly {
        // change the permission to update the contract registry
        _onlyOwnerCanUpdateRegistry = restrictOwnerOnly;
    }

    /**
     * @dev returns the address of the current contract registry
     */
    function registry() public view returns (IContractRegistry) {
        return _registry;
    }

    /**
     * @dev returns the address of the previous contract registry
     */
    function prevRegistry() external view returns (IContractRegistry) {
        return _prevRegistry;
    }

    /**
     * @dev returns whether only the owner can update the contract registry
     */
    function onlyOwnerCanUpdateRegistry() external view returns (bool) {
        return _onlyOwnerCanUpdateRegistry;
    }

    /**
     * @dev returns the address associated with the given contract name
     */
    function _addressOf(bytes32 contractName) internal view returns (address) {
        return _registry.addressOf(contractName);
    }
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.6.12;

import "../../token/interfaces/IReserveToken.sol";

import "./IConverterAnchor.sol";

/**
 * @dev Converter Registry Data interface
 */
interface IConverterRegistryData {
    function addSmartToken(IConverterAnchor anchor) external;

    function removeSmartToken(IConverterAnchor anchor) external;

    function addLiquidityPool(IConverterAnchor liquidityPoolAnchor) external;

    function removeLiquidityPool(IConverterAnchor liquidityPoolAnchor) external;

    function addConvertibleToken(IReserveToken convertibleToken, IConverterAnchor anchor) external;

    function removeConvertibleToken(IReserveToken convertibleToken, IConverterAnchor anchor) external;

    function getSmartTokenCount() external view returns (uint256);

    function getSmartTokens() external view returns (address[] memory);

    function getSmartToken(uint256 index) external view returns (IConverterAnchor);

    function isSmartToken(address value) external view returns (bool);

    function getLiquidityPoolCount() external view returns (uint256);

    function getLiquidityPools() external view returns (address[] memory);

    function getLiquidityPool(uint256 index) external view returns (IConverterAnchor);

    function isLiquidityPool(address value) external view returns (bool);

    function getConvertibleTokenCount() external view returns (uint256);

    function getConvertibleTokens() external view returns (address[] memory);

    function getConvertibleToken(uint256 index) external view returns (IReserveToken);

    function isConvertibleToken(address value) external view returns (bool);

    function getConvertibleTokenSmartTokenCount(IReserveToken convertibleToken) external view returns (uint256);

    function getConvertibleTokenSmartTokens(IReserveToken convertibleToken) external view returns (address[] memory);

    function getConvertibleTokenSmartToken(IReserveToken convertibleToken, uint256 index)
        external
        view
        returns (IConverterAnchor);

    function isConvertibleTokenSmartToken(IReserveToken convertibleToken, address value) external view returns (bool);
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.6.12;

import "./interfaces/IOwned.sol";

/**
 * @dev This contract provides support and utilities for contract ownership.
 */
contract Owned is IOwned {
    address private _owner;
    address private _newOwner;

    /**
     * @dev triggered when the owner is updated
     */
    event OwnerUpdate(address indexed prevOwner, address indexed newOwner);

    /**
     * @dev initializes a new Owned instance
     */
    constructor() public {
        _owner = msg.sender;
    }

    // allows execution by the owner only
    modifier ownerOnly() {
        _ownerOnly();

        _;
    }

    // error message binary size optimization
    function _ownerOnly() private view {
        require(msg.sender == _owner, "ERR_ACCESS_DENIED");
    }

    /**
     * @dev allows transferring the contract ownership
     *
     * Requirements:
     *
     * - the caller must be the owner of the contract
     *
     * note the new owner still needs to accept the transfer
     */
    function transferOwnership(address newOwner) public override ownerOnly {
        require(newOwner != _owner, "ERR_SAME_OWNER");

        _newOwner = newOwner;
    }

    /**
     * @dev used by a new owner to accept an ownership transfer
     */
    function acceptOwnership() public override {
        require(msg.sender == _newOwner, "ERR_ACCESS_DENIED");

        emit OwnerUpdate(_owner, _newOwner);

        _owner = _newOwner;
        _newOwner = address(0);
    }

    /**
     * @dev returns the address of the current owner
     */
    function owner() public view override returns (address) {
        return _owner;
    }

    /**
     * @dev returns the address of the new owner candidate
     */
    function newOwner() external view returns (address) {
        return _newOwner;
    }
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @dev Utilities & Common Modifiers
 */
contract Utils {
    uint32 internal constant PPM_RESOLUTION = 1000000;

    // verifies that a value is greater than zero
    modifier greaterThanZero(uint256 value) {
        _greaterThanZero(value);

        _;
    }

    // error message binary size optimization
    function _greaterThanZero(uint256 value) internal pure {
        require(value > 0, "ERR_ZERO_VALUE");
    }

    // validates an address - currently only checks that it isn't null
    modifier validAddress(address addr) {
        _validAddress(addr);

        _;
    }

    // error message binary size optimization
    function _validAddress(address addr) internal pure {
        require(addr != address(0), "ERR_INVALID_ADDRESS");
    }

    // ensures that the portion is valid
    modifier validPortion(uint32 _portion) {
        _validPortion(_portion);

        _;
    }

    // error message binary size optimization
    function _validPortion(uint32 _portion) internal pure {
        require(_portion > 0 && _portion <= PPM_RESOLUTION, "ERR_INVALID_PORTION");
    }

    // validates an external address - currently only checks that it isn't null or this
    modifier validExternalAddress(address addr) {
        _validExternalAddress(addr);

        _;
    }

    // error message binary size optimization
    function _validExternalAddress(address addr) internal view {
        require(addr != address(0) && addr != address(this), "ERR_INVALID_EXTERNAL_ADDRESS");
    }

    // ensures that the fee is valid
    modifier validFee(uint32 fee) {
        _validFee(fee);

        _;
    }

    // error message binary size optimization
    function _validFee(uint32 fee) internal pure {
        require(fee <= PPM_RESOLUTION, "ERR_INVALID_FEE");
    }
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.6.12;

/**
 * @dev Contract Registry interface
 */
interface IContractRegistry {
    function addressOf(bytes32 contractName) external view returns (address);
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.6.12;

/**
 * @dev Owned interface
 */
interface IOwned {
    function owner() external view returns (address);

    function transferOwnership(address newOwner) external;

    function acceptOwnership() external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.6.12;

/**
 * @dev This contract is used to represent reserve tokens, which are tokens that can either be regular ERC20 tokens or
 * native ETH (represented by the NATIVE_TOKEN_ADDRESS address)
 *
 * Please note that this interface is intentionally doesn't inherit from IERC20, so that it'd be possible to effectively
 * override its balanceOf() function in the ReserveToken library
 */
interface IReserveToken {

}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.6.12;

import "../../utility/interfaces/IOwned.sol";

/**
 * @dev Converter Anchor interface
 */
interface IConverterAnchor is IOwned {

}