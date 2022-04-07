// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.6.12;

import "../utility/ContractRegistryClient.sol";

import "../token/interfaces/IDSToken.sol";

import "./interfaces/IConverter.sol";
import "./interfaces/IConverterFactory.sol";
import "./interfaces/IConverterRegistry.sol";
import "./interfaces/IConverterRegistryData.sol";

/**
 * @dev This contract maintains a list of all active converters in the Bancor Network.
 *
 * Since converters can be upgraded and thus their address can change, the registry actually keeps
 * converter anchors internally and not the converters themselves.
 * The active converter for each anchor can be easily accessed by querying the anchor's owner.
 *
 * The registry exposes 3 different lists that can be accessed and iterated, based on the use-case of the caller:
 * - Anchors - can be used to get all the latest / historical data in the network
 * - Liquidity pools - can be used to get all liquidity pools for funding, liquidation etc.
 * - Convertible tokens - can be used to get all tokens that can be converted in the network (excluding pool
 *   tokens), and for each one - all anchors that hold it in their reserves
 *
 *
 * The contract fires events whenever one of the primitives is added to or removed from the registry
 *
 * The contract is upgradable.
 */
contract ConverterRegistry is IConverterRegistry, ContractRegistryClient {
    /**
     * @dev triggered when a converter anchor is added to the registry
     */
    event ConverterAnchorAdded(IConverterAnchor indexed anchor);

    /**
     * @dev triggered when a converter anchor is removed from the registry
     */
    event ConverterAnchorRemoved(IConverterAnchor indexed anchor);

    /**
     * @dev triggered when a liquidity pool is added to the registry
     */
    event LiquidityPoolAdded(IConverterAnchor indexed liquidityPool);

    /**
     * @dev triggered when a liquidity pool is removed from the registry
     */
    event LiquidityPoolRemoved(IConverterAnchor indexed liquidityPool);

    /**
     * @dev triggered when a convertible token is added to the registry
     */
    event ConvertibleTokenAdded(IReserveToken indexed convertibleToken, IConverterAnchor indexed smartToken);

    /**
     * @dev triggered when a convertible token is removed from the registry
     */
    event ConvertibleTokenRemoved(IReserveToken indexed convertibleToken, IConverterAnchor indexed smartToken);

    /**
     * @dev deprecated, backward compatibility, use `ConverterAnchorAdded`
     */
    event SmartTokenAdded(IConverterAnchor indexed smartToken);

    /**
     * @dev deprecated, backward compatibility, use `ConverterAnchorRemoved`
     */
    event SmartTokenRemoved(IConverterAnchor indexed smartToken);

    /**
     * @dev initializes a new ConverterRegistry instance
     */
    constructor(IContractRegistry registry) public ContractRegistryClient(registry) {}

    /**
     * @dev creates an empty liquidity pool and adds its converter to the registry
     */
    function newConverter(
        uint16 converterType,
        string memory name,
        string memory symbol,
        uint8 decimals,
        uint32 maxConversionFee,
        IReserveToken[] memory reserveTokens,
        uint32[] memory reserveWeights
    ) public virtual returns (IConverter) {
        uint256 length = reserveTokens.length;
        require(length == reserveWeights.length, "ERR_INVALID_RESERVES");

        // for standard pools, change type 1 to type 3
        if (converterType == 1 && _isStandardPool(reserveWeights)) {
            converterType = 3;
        }

        require(
            getLiquidityPoolByConfig(converterType, reserveTokens, reserveWeights) == IConverterAnchor(0),
            "ERR_ALREADY_EXISTS"
        );

        IConverterFactory factory = IConverterFactory(_addressOf(CONVERTER_FACTORY));
        IConverterAnchor anchor = IConverterAnchor(factory.createAnchor(converterType, name, symbol, decimals));
        IConverter converter = IConverter(factory.createConverter(converterType, anchor, registry(), maxConversionFee));

        anchor.acceptOwnership();
        converter.acceptOwnership();

        for (uint256 i = 0; i < length; i++) {
            converter.addReserve(reserveTokens[i], reserveWeights[i]);
        }

        anchor.transferOwnership(address(converter));
        converter.acceptAnchorOwnership();
        converter.transferOwnership(msg.sender);

        _addConverter(converter);

        return converter;
    }

    /**
     * @dev adds an existing converter to the registry
     *
     * Requirements:
     *
     * - the caller must be the owner of the contract
     */
    function addConverter(IConverter converter) public ownerOnly {
        require(isConverterValid(converter), "ERR_INVALID_CONVERTER");

        _addConverter(converter);
    }

    /**
     * @dev removes a converter from the registry
     *
     *
     * Requirements:
     *
     * - anyone can remove an existing converter from the registry, as long as the converter is invalid, but only the
     * owner can also remove valid converters
     */
    function removeConverter(IConverter converter) public {
        require(msg.sender == owner() || !isConverterValid(converter), "ERR_ACCESS_DENIED");

        _removeConverter(converter);
    }

    /**
     * @dev returns the number of converter anchors in the registry
     */
    function getAnchorCount() public view override returns (uint256) {
        return IConverterRegistryData(_addressOf(CONVERTER_REGISTRY_DATA)).getSmartTokenCount();
    }

    /**
     * @dev returns the list of converter anchors in the registry
     */
    function getAnchors() public view override returns (address[] memory) {
        return IConverterRegistryData(_addressOf(CONVERTER_REGISTRY_DATA)).getSmartTokens();
    }

    /**
     * @dev returns the converter anchor at a given index
     */
    function getAnchor(uint256 index) public view override returns (IConverterAnchor) {
        return IConverterRegistryData(_addressOf(CONVERTER_REGISTRY_DATA)).getSmartToken(index);
    }

    /**
     * @dev checks whether or not a given value is a converter anchor
     */
    function isAnchor(address value) public view override returns (bool) {
        return IConverterRegistryData(_addressOf(CONVERTER_REGISTRY_DATA)).isSmartToken(value);
    }

    /**
     * @dev returns the number of liquidity pools in the registry
     */
    function getLiquidityPoolCount() public view override returns (uint256) {
        return IConverterRegistryData(_addressOf(CONVERTER_REGISTRY_DATA)).getLiquidityPoolCount();
    }

    /**
     * @dev returns the list of liquidity pools in the registry
     */
    function getLiquidityPools() public view override returns (address[] memory) {
        return IConverterRegistryData(_addressOf(CONVERTER_REGISTRY_DATA)).getLiquidityPools();
    }

    /**
     * @dev returns the liquidity pool at a given index
     */
    function getLiquidityPool(uint256 index) public view override returns (IConverterAnchor) {
        return IConverterRegistryData(_addressOf(CONVERTER_REGISTRY_DATA)).getLiquidityPool(index);
    }

    /**
     * @dev checks whether or not a given value is a liquidity pool
     */
    function isLiquidityPool(address value) public view override returns (bool) {
        return IConverterRegistryData(_addressOf(CONVERTER_REGISTRY_DATA)).isLiquidityPool(value);
    }

    /**
     * @dev returns the number of convertible tokens in the registry
     */
    function getConvertibleTokenCount() public view override returns (uint256) {
        return IConverterRegistryData(_addressOf(CONVERTER_REGISTRY_DATA)).getConvertibleTokenCount();
    }

    /**
     * @dev returns the list of convertible tokens in the registry
     */
    function getConvertibleTokens() public view override returns (address[] memory) {
        return IConverterRegistryData(_addressOf(CONVERTER_REGISTRY_DATA)).getConvertibleTokens();
    }

    /**
     * @dev returns the convertible token at a given index
     */
    function getConvertibleToken(uint256 index) public view override returns (IReserveToken) {
        return IConverterRegistryData(_addressOf(CONVERTER_REGISTRY_DATA)).getConvertibleToken(index);
    }

    /**
     * @dev checks whether or not a given value is a convertible token
     */
    function isConvertibleToken(address value) public view override returns (bool) {
        return IConverterRegistryData(_addressOf(CONVERTER_REGISTRY_DATA)).isConvertibleToken(value);
    }

    /**
     * @dev returns the number of converter anchors associated with a given convertible token
     */
    function getConvertibleTokenAnchorCount(IReserveToken convertibleToken) public view override returns (uint256) {
        return
            IConverterRegistryData(_addressOf(CONVERTER_REGISTRY_DATA)).getConvertibleTokenSmartTokenCount(
                convertibleToken
            );
    }

    /**
     * @dev returns the list of converter anchors associated with a given convertible token
     */
    function getConvertibleTokenAnchors(IReserveToken convertibleToken)
        public
        view
        override
        returns (address[] memory)
    {
        return
            IConverterRegistryData(_addressOf(CONVERTER_REGISTRY_DATA)).getConvertibleTokenSmartTokens(
                convertibleToken
            );
    }

    /**
     * @dev returns the converter anchor associated with a given convertible token at a given index
     */
    function getConvertibleTokenAnchor(IReserveToken convertibleToken, uint256 index)
        public
        view
        override
        returns (IConverterAnchor)
    {
        return
            IConverterRegistryData(_addressOf(CONVERTER_REGISTRY_DATA)).getConvertibleTokenSmartToken(
                convertibleToken,
                index
            );
    }

    /**
     * @dev checks whether or not a given value is a converter anchor of a given convertible token
     */
    function isConvertibleTokenAnchor(IReserveToken convertibleToken, address value)
        public
        view
        override
        returns (bool)
    {
        return
            IConverterRegistryData(_addressOf(CONVERTER_REGISTRY_DATA)).isConvertibleTokenSmartToken(
                convertibleToken,
                value
            );
    }

    /**
     * @dev returns a list of converters for a given list of anchors
     */
    function getConvertersByAnchors(address[] memory anchors) public view returns (IConverter[] memory) {
        IConverter[] memory converters = new IConverter[](anchors.length);

        for (uint256 i = 0; i < anchors.length; i++) {
            converters[i] = IConverter(payable(IConverterAnchor(anchors[i]).owner()));
        }

        return converters;
    }

    /**
     * @dev checks whether or not a given converter is valid
     */
    function isConverterValid(IConverter converter) public view returns (bool) {
        // verify that the converter is active
        return converter.token().owner() == address(converter);
    }

    /**
     * @dev checks if a liquidity pool with given configuration is already registered
     */
    function isSimilarLiquidityPoolRegistered(IConverter converter) public view returns (bool) {
        uint256 reserveTokenCount = converter.connectorTokenCount();
        IReserveToken[] memory reserveTokens = new IReserveToken[](reserveTokenCount);
        uint32[] memory reserveWeights = new uint32[](reserveTokenCount);

        // get the reserve-configuration of the converter
        for (uint256 i = 0; i < reserveTokenCount; i++) {
            IReserveToken reserveToken = converter.connectorTokens(i);
            reserveTokens[i] = reserveToken;
            reserveWeights[i] = _getReserveWeight(converter, reserveToken);
        }

        // return if a liquidity pool with the same configuration is already registered
        return
            getLiquidityPoolByConfig(_getConverterType(converter, reserveTokenCount), reserveTokens, reserveWeights) !=
            IConverterAnchor(0);
    }

    /**
     * @dev searches for a liquidity pool with specific configuration
     */
    function getLiquidityPoolByConfig(
        uint16 converterType,
        IReserveToken[] memory reserveTokens,
        uint32[] memory reserveWeights
    ) public view override returns (IConverterAnchor) {
        // verify that the input parameters represent a valid liquidity pool
        if (reserveTokens.length == reserveWeights.length && reserveTokens.length > 1) {
            // get the anchors of the least frequent token (optimization)
            address[] memory convertibleTokenAnchors = _getLeastFrequentTokenAnchors(reserveTokens);
            // search for a converter with the same configuration
            for (uint256 i = 0; i < convertibleTokenAnchors.length; i++) {
                IConverterAnchor anchor = IConverterAnchor(convertibleTokenAnchors[i]);
                IConverter converter = IConverter(payable(anchor.owner()));
                if (_isConverterReserveConfigEqual(converter, converterType, reserveTokens, reserveWeights)) {
                    return anchor;
                }
            }
        }

        return IConverterAnchor(0);
    }

    /**
     * @dev adds a converter anchor to the registry
     */
    function _addAnchor(IConverterRegistryData converterRegistryData, IConverterAnchor anchor) internal {
        converterRegistryData.addSmartToken(anchor);
        emit ConverterAnchorAdded(anchor);
        emit SmartTokenAdded(anchor);
    }

    /**
     * @dev removes a converter anchor from the registry
     */
    function _removeAnchor(IConverterRegistryData converterRegistryData, IConverterAnchor anchor) internal {
        converterRegistryData.removeSmartToken(anchor);
        emit ConverterAnchorRemoved(anchor);
        emit SmartTokenRemoved(anchor);
    }

    /**
     * @dev adds a liquidity pool to the registry
     */
    function _addLiquidityPool(IConverterRegistryData converterRegistryData, IConverterAnchor liquidityPoolAnchor)
        internal
    {
        converterRegistryData.addLiquidityPool(liquidityPoolAnchor);
        emit LiquidityPoolAdded(liquidityPoolAnchor);
    }

    /**
     * @dev removes a liquidity pool from the registry
     */
    function _removeLiquidityPool(IConverterRegistryData converterRegistryData, IConverterAnchor liquidityPoolAnchor)
        internal
    {
        converterRegistryData.removeLiquidityPool(liquidityPoolAnchor);
        emit LiquidityPoolRemoved(liquidityPoolAnchor);
    }

    /**
     * @dev adds a convertible token to the registry
     */
    function _addConvertibleToken(
        IConverterRegistryData converterRegistryData,
        IReserveToken convertibleToken,
        IConverterAnchor anchor
    ) internal {
        converterRegistryData.addConvertibleToken(convertibleToken, anchor);
        emit ConvertibleTokenAdded(convertibleToken, anchor);
    }

    /**
     * @dev removes a convertible token from the registry
     */
    function _removeConvertibleToken(
        IConverterRegistryData converterRegistryData,
        IReserveToken convertibleToken,
        IConverterAnchor anchor
    ) internal {
        converterRegistryData.removeConvertibleToken(convertibleToken, anchor);

        emit ConvertibleTokenRemoved(convertibleToken, anchor);
    }

    /**
     * @dev checks whether or not a given configuration depicts a standard pool
     */
    function _isStandardPool(uint32[] memory reserveWeights) internal pure virtual returns (bool) {
        return
            reserveWeights.length == 2 &&
            reserveWeights[0] == PPM_RESOLUTION / 2 &&
            reserveWeights[1] == PPM_RESOLUTION / 2;
    }

    function _addConverter(IConverter converter) private {
        IConverterRegistryData converterRegistryData = IConverterRegistryData(_addressOf(CONVERTER_REGISTRY_DATA));
        IConverterAnchor anchor = IConverter(converter).token();
        uint256 reserveTokenCount = converter.connectorTokenCount();

        // add the converter anchor
        _addAnchor(converterRegistryData, anchor);
        if (reserveTokenCount > 1) {
            _addLiquidityPool(converterRegistryData, anchor);
        } else {
            _addConvertibleToken(converterRegistryData, IReserveToken(address(anchor)), anchor);
        }

        // add all reserve tokens
        for (uint256 i = 0; i < reserveTokenCount; i++) {
            _addConvertibleToken(converterRegistryData, converter.connectorTokens(i), anchor);
        }
    }

    function _removeConverter(IConverter converter) private {
        IConverterRegistryData converterRegistryData = IConverterRegistryData(_addressOf(CONVERTER_REGISTRY_DATA));
        IConverterAnchor anchor = IConverter(converter).token();
        uint256 reserveTokenCount = converter.connectorTokenCount();

        // remove the converter anchor
        _removeAnchor(converterRegistryData, anchor);
        if (reserveTokenCount > 1) {
            _removeLiquidityPool(converterRegistryData, anchor);
        } else {
            _removeConvertibleToken(converterRegistryData, IReserveToken(address(anchor)), anchor);
        }

        // remove all reserve tokens
        for (uint256 i = 0; i < reserveTokenCount; i++) {
            _removeConvertibleToken(converterRegistryData, converter.connectorTokens(i), anchor);
        }
    }

    function _getLeastFrequentTokenAnchors(IReserveToken[] memory reserveTokens)
        private
        view
        returns (address[] memory)
    {
        IConverterRegistryData converterRegistryData = IConverterRegistryData(_addressOf(CONVERTER_REGISTRY_DATA));
        uint256 minAnchorCount = converterRegistryData.getConvertibleTokenSmartTokenCount(reserveTokens[0]);
        uint256 index = 0;

        // find the reserve token which has the smallest number of converter anchors
        for (uint256 i = 1; i < reserveTokens.length; i++) {
            uint256 convertibleTokenAnchorCount = converterRegistryData.getConvertibleTokenSmartTokenCount(
                reserveTokens[i]
            );
            if (minAnchorCount > convertibleTokenAnchorCount) {
                minAnchorCount = convertibleTokenAnchorCount;
                index = i;
            }
        }

        return converterRegistryData.getConvertibleTokenSmartTokens(reserveTokens[index]);
    }

    function _isConverterReserveConfigEqual(
        IConverter converter,
        uint16 converterType,
        IReserveToken[] memory reserveTokens,
        uint32[] memory reserveWeights
    ) private view returns (bool) {
        uint256 reserveTokenCount = converter.connectorTokenCount();

        if (converterType != _getConverterType(converter, reserveTokenCount)) {
            return false;
        }

        if (reserveTokens.length != reserveTokenCount) {
            return false;
        }

        for (uint256 i = 0; i < reserveTokens.length; i++) {
            if (reserveWeights[i] != _getReserveWeight(converter, reserveTokens[i])) {
                return false;
            }
        }

        return true;
    }

    // utility to get the reserve weight (including from older converters that don't support the new _getReserveWeight function)
    function _getReserveWeight(IConverter converter, IReserveToken reserveToken) private view returns (uint32) {
        (, uint32 weight, , , ) = converter.connectors(reserveToken);
        return weight;
    }

    bytes4 private constant CONVERTER_TYPE_FUNC_SELECTOR = bytes4(keccak256("converterType()"));

    // utility to get the converter type (including from older converters that don't support the new converterType function)
    function _getConverterType(IConverter converter, uint256 reserveTokenCount) private view returns (uint16) {
        (bool success, bytes memory returnData) = address(converter).staticcall(
            abi.encodeWithSelector(CONVERTER_TYPE_FUNC_SELECTOR)
        );
        if (success && returnData.length == 32) {
            return abi.decode(returnData, (uint16));
        }

        return reserveTokenCount > 1 ? 1 : 0;
    }

    /**
     * @dev deprecated, backward compatibility, use `getAnchorCount`
     */
    function getSmartTokenCount() public view returns (uint256) {
        return getAnchorCount();
    }

    /**
     * @dev deprecated, backward compatibility, use `getAnchors`
     */
    function getSmartTokens() public view returns (address[] memory) {
        return getAnchors();
    }

    /**
     * @dev deprecated, backward compatibility, use `getAnchor`
     */
    function getSmartToken(uint256 index) public view returns (IConverterAnchor) {
        return getAnchor(index);
    }

    /**
     * @dev deprecated, backward compatibility, use `isAnchor`
     */
    function isSmartToken(address value) public view returns (bool) {
        return isAnchor(value);
    }

    /**
     * @dev deprecated, backward compatibility, use `getConvertibleTokenAnchorCount`
     */
    function getConvertibleTokenSmartTokenCount(IReserveToken convertibleToken) public view returns (uint256) {
        return getConvertibleTokenAnchorCount(convertibleToken);
    }

    /**
     * @dev deprecated, backward compatibility, use `getConvertibleTokenAnchors`
     */
    function getConvertibleTokenSmartTokens(IReserveToken convertibleToken) public view returns (address[] memory) {
        return getConvertibleTokenAnchors(convertibleToken);
    }

    /**
     * @dev deprecated, backward compatibility, use `getConvertibleTokenAnchor`
     */
    function getConvertibleTokenSmartToken(IReserveToken convertibleToken, uint256 index)
        public
        view
        returns (IConverterAnchor)
    {
        return getConvertibleTokenAnchor(convertibleToken, index);
    }

    /**
     * @dev deprecated, backward compatibility, use `isConvertibleTokenAnchor`
     */
    function isConvertibleTokenSmartToken(IReserveToken convertibleToken, address value) public view returns (bool) {
        return isConvertibleTokenAnchor(convertibleToken, value);
    }

    /**
     * @dev deprecated, backward compatibility, use `getConvertersByAnchors`
     */
    function getConvertersBySmartTokens(address[] memory smartTokens) public view returns (IConverter[] memory) {
        return getConvertersByAnchors(smartTokens);
    }

    /**
     * @dev deprecated, backward compatibility, use `getLiquidityPoolByConfig`
     */
    function getLiquidityPoolByReserveConfig(IReserveToken[] memory reserveTokens, uint32[] memory reserveWeights)
        public
        view
        returns (IConverterAnchor)
    {
        return getLiquidityPoolByConfig(reserveTokens.length > 1 ? 1 : 0, reserveTokens, reserveWeights);
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

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../../converter/interfaces/IConverterAnchor.sol";
import "../../utility/interfaces/IOwned.sol";

/**
 * @dev DSToken interface
 */
interface IDSToken is IConverterAnchor, IERC20 {
    function issue(address recipient, uint256 amount) external;

    function destroy(address recipient, uint256 amount) external;
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./IConverterAnchor.sol";

import "../../utility/interfaces/IOwned.sol";

import "../../token/interfaces/IReserveToken.sol";

/**
 * @dev Converter interface
 */
interface IConverter is IOwned {
    function converterType() external pure returns (uint16);

    function anchor() external view returns (IConverterAnchor);

    function isActive() external view returns (bool);

    function targetAmountAndFee(
        IReserveToken sourceToken,
        IReserveToken targetToken,
        uint256 sourceAmount
    ) external view returns (uint256, uint256);

    function convert(
        IReserveToken sourceToken,
        IReserveToken targetToken,
        uint256 sourceAmount,
        address trader,
        address payable beneficiary
    ) external payable returns (uint256);

    function conversionFee() external view returns (uint32);

    function maxConversionFee() external view returns (uint32);

    function reserveBalance(IReserveToken reserveToken) external view returns (uint256);

    receive() external payable;

    function transferAnchorOwnership(address newOwner) external;

    function acceptAnchorOwnership() external;

    function setConversionFee(uint32 fee) external;

    function addReserve(IReserveToken token, uint32 weight) external;

    function transferReservesOnUpgrade(address newConverter) external;

    function onUpgradeComplete() external;

    // deprecated, backward compatibility
    function token() external view returns (IConverterAnchor);

    function transferTokenOwnership(address newOwner) external;

    function acceptTokenOwnership() external;

    function reserveTokenCount() external view returns (uint16);

    function reserveTokens() external view returns (IReserveToken[] memory);

    function connectors(IReserveToken reserveToken)
        external
        view
        returns (
            uint256,
            uint32,
            bool,
            bool,
            bool
        );

    function getConnectorBalance(IReserveToken connectorToken) external view returns (uint256);

    function connectorTokens(uint256 index) external view returns (IReserveToken);

    function connectorTokenCount() external view returns (uint16);

    /**
     * @dev triggered when the converter is activated
     */
    event Activation(uint16 indexed converterType, IConverterAnchor indexed anchor, bool indexed activated);

    /**
     * @dev triggered when a conversion between two tokens occurs
     */
    event Conversion(
        IReserveToken indexed sourceToken,
        IReserveToken indexed targetToken,
        address indexed trader,
        uint256 sourceAmount,
        uint256 targetAmount,
        int256 conversionFee
    );

    /**
     * @dev triggered when the rate between two tokens in the converter changes
     *
     * note that the event might be dispatched for rate updates between any two tokens in the converter
     */
    event TokenRateUpdate(address indexed token1, address indexed token2, uint256 rateN, uint256 rateD);

    /**
     * @dev triggered when the conversion fee is updated
     */
    event ConversionFeeUpdate(uint32 prevFee, uint32 newFee);
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.6.12;

import "./IConverter.sol";
import "./IConverterAnchor.sol";
import "../../utility/interfaces/IContractRegistry.sol";

/**
 * @dev Converter Factory interface
 */
interface IConverterFactory {
    function createAnchor(
        uint16 converterType,
        string memory name,
        string memory symbol,
        uint8 decimals
    ) external returns (IConverterAnchor);

    function createConverter(
        uint16 converterType,
        IConverterAnchor anchor,
        IContractRegistry registry,
        uint32 maxConversionFee
    ) external returns (IConverter);
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.6.12;

import "../../token/interfaces/IReserveToken.sol";

import "./IConverterAnchor.sol";

/**
 * @dev Converter Registry interface
 */
interface IConverterRegistry {
    function getAnchorCount() external view returns (uint256);

    function getAnchors() external view returns (address[] memory);

    function getAnchor(uint256 index) external view returns (IConverterAnchor);

    function isAnchor(address value) external view returns (bool);

    function getLiquidityPoolCount() external view returns (uint256);

    function getLiquidityPools() external view returns (address[] memory);

    function getLiquidityPool(uint256 index) external view returns (IConverterAnchor);

    function isLiquidityPool(address value) external view returns (bool);

    function getConvertibleTokenCount() external view returns (uint256);

    function getConvertibleTokens() external view returns (address[] memory);

    function getConvertibleToken(uint256 index) external view returns (IReserveToken);

    function isConvertibleToken(address value) external view returns (bool);

    function getConvertibleTokenAnchorCount(IReserveToken convertibleToken) external view returns (uint256);

    function getConvertibleTokenAnchors(IReserveToken convertibleToken) external view returns (address[] memory);

    function getConvertibleTokenAnchor(IReserveToken convertibleToken, uint256 index)
        external
        view
        returns (IConverterAnchor);

    function isConvertibleTokenAnchor(IReserveToken convertibleToken, address value) external view returns (bool);

    function getLiquidityPoolByConfig(
        uint16 converterType,
        IReserveToken[] memory reserveTokens,
        uint32[] memory reserveWeights
    ) external view returns (IConverterAnchor);
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

import "../../utility/interfaces/IOwned.sol";

/**
 * @dev Converter Anchor interface
 */
interface IConverterAnchor is IOwned {

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