// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.5;

import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "./OpiumPositionToken.sol";
import "./base/RegistryManager.sol";
import "../libs/LibDerivative.sol";
import "../libs/LibPosition.sol";
import "../libs/LibBokkyPooBahsDateTimeLibrary.sol";
import "../interfaces/IOpiumPositionToken.sol";
import "../interfaces/IRegistry.sol";

/**
    Error codes:
    - F1 = ERROR_OPIUM_PROXY_FACTORY_NOT_CORE
    - F2 = ERROR_OPIUM_PROXY_CUSTOM_POSITION_TOKEN_NAME_TOO_LONG
 */

/// @title Opium.OpiumProxyFactory contract manages the deployment of ERC20 LONG/SHORT positions for a given `LibDerivative.Derivative` structure and it's responsible for minting and burning positions according to the parameters supplied by `Opium.Core`
contract OpiumProxyFactory is RegistryManager {
    using LibDerivative for LibDerivative.Derivative;
    using LibPosition for bytes32;

    event LogPositionTokenPair(
        bytes32 indexed _derivativeHash,
        address indexed _longPositionAddress,
        address indexed _shortPositionAddress
    );

    address private opiumPositionTokenImplementation;

    /// @notice It is applied to functions that must be called only by the `Opium.Core` contract
    modifier onlyCore() {
        require(msg.sender == registry.getCore(), "F1");
        _;
    }

    // ****************** EXTERNAL FUNCTIONS ******************

    // ***** GETTERS *****

    /// @notice It retrieves the information about the underlying derivative
    /// @return _opiumPositionTokenParams OpiumPositionTokenParams struct which contains `LibDerivative.Derivative` schema of the derivative, the ` LibDerivative.PositionType` of the present ERC20 token and the bytes32 hash `derivativeHash` of the `LibDerivative.Derivative` derivative
    function getImplementationAddress() external view returns (address) {
        return opiumPositionTokenImplementation;
    }

    // ***** SETTERS *****

    /// @notice It is called only once upon deployment of the contract
    /// @dev It sets the the address of the implementation of the OpiumPositionToken contract which will be used for the factory-deployment of erc20 positions via the minimal proxy contract
    /// @param _registry address of Opium.Registry
    function initialize(address _registry) external initializer {
        __RegistryManager__init(_registry);
        opiumPositionTokenImplementation = address(new OpiumPositionToken());
    }

    /// @notice It creates a specified amount of LONG/SHORT position tokens on behalf of the buyer(LONG) and seller(SHORT) - the specified amount can be 0 in which case the ERC20 contract of the position tokens will only be deployed
    /// @dev if either of the LONG or SHORT position contracts already exists then it is expected to fail
    /// @param _buyer address of the recipient of the LONG position tokens
    /// @param _seller address of the recipient of the SHORT position tokens
    /// @param _amount amount of position tokens to be minted to the _positionHolder
    /// @param _derivativeHash bytes32 hash of `LibDerivative.Derivative`
    /// @param _derivative LibDerivative.Derivative Derivative definition
    function create(
        address _buyer,
        address _seller,
        uint256 _amount,
        bytes32 _derivativeHash,
        LibDerivative.Derivative calldata _derivative
    ) external onlyCore {
        address longPositionAddress = _derivativeHash.deployOpiumPosition(true, opiumPositionTokenImplementation);
        address shortPositionAddress = _derivativeHash.deployOpiumPosition(false, opiumPositionTokenImplementation);

        IOpiumPositionToken(longPositionAddress).initialize(
            _derivativeHash,
            LibDerivative.PositionType.LONG,
            _derivative
        );
        IOpiumPositionToken(shortPositionAddress).initialize(
            _derivativeHash,
            LibDerivative.PositionType.SHORT,
            _derivative
        );
        emit LogPositionTokenPair(_derivativeHash, longPositionAddress, shortPositionAddress);
        if (_amount > 0) {
            IOpiumPositionToken(longPositionAddress).mint(_buyer, _amount);
            IOpiumPositionToken(shortPositionAddress).mint(_seller, _amount);
        }
    }

    /// @notice it creates a specified amount of LONG/SHORT position tokens on behalf of the buyer(LONG) and seller(SHORT) - the specified amount can be 0 in which case the ERC20 contract of the position tokens will only be deployed
    /// @dev if LONG or SHORT position contracts have not been deployed yet at the provided addresses then it is expected to fail
    /// @param _buyer address of the recipient of the LONG position tokens
    /// @param _seller address of the recipient of the SHORT position tokens
    /// @param _longPositionAddress address of the deployed LONG position token
    /// @param _shortPositionAddress address of the deployed SHORT position token
    /// @param _amount amount of position tokens to be minted to the _positionHolder
    function mintPair(
        address _buyer,
        address _seller,
        address _longPositionAddress,
        address _shortPositionAddress,
        uint256 _amount
    ) external onlyCore {
        IOpiumPositionToken(_longPositionAddress).mint(_buyer, _amount);
        IOpiumPositionToken(_shortPositionAddress).mint(_seller, _amount);
    }

    /// @notice it burns specified amount of a specific position tokens on behalf of a specified owner
    /// @notice it is consumed by Opium.Core to execute or cancel a specific position type
    /// @dev if no position has been deployed at the provided address, it is expected to revert
    /// @param _positionOwner address of the owner of the specified position token
    /// @param _positionAddress address of the position token to be burnt
    /// @param _amount amount of position tokens to be minted to the _positionHolder
    function burn(
        address _positionOwner,
        address _positionAddress,
        uint256 _amount
    ) external onlyCore {
        IOpiumPositionToken(_positionAddress).burn(_positionOwner, _amount);
    }

    /// @notice It burns the specified amount of LONG/SHORT position tokens on behalf of a specified owner
    /// @notice It is consumed by Opium.Core to redeem market neutral position pairs
    /// @param _positionOwner address of the owner of the LONG/SHORT position tokens
    /// @param _longPositionAddress address of the deployed LONG position token
    /// @param _shortPositionAddress address of the deployed SHORT position token
    /// @param _amount amount of position tokens to be minted to the _positionHolder
    function burnPair(
        address _positionOwner,
        address _longPositionAddress,
        address _shortPositionAddress,
        uint256 _amount
    ) external onlyCore {
        IOpiumPositionToken(_longPositionAddress).burn(_positionOwner, _amount);
        IOpiumPositionToken(_shortPositionAddress).burn(_positionOwner, _amount);
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.5;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-ERC20PermitUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "../interfaces/IDerivativeLogic.sol";
import "../libs/LibDerivative.sol";
import "../libs/LibBokkyPooBahsDateTimeLibrary.sol";

/**
    Error codes:
    - P1 = ERROR_OPIUM_POSITION_TOKEN_NOT_FACTORY
 */

/// @title Opium.OpiumPositionToken is an ERC20PermitUpgradeable child contract created by the Opium.OpiumProxyFactory. It represents a specific position (either LONG or SHORT) for a given `LibDerivative.Derivative` derivative
contract OpiumPositionToken is ERC20PermitUpgradeable {
    using LibDerivative for LibDerivative.Derivative;

    /// It describes the derivative whose position (either LONG or SHORT) is being represented by the OpiumPositionToken
    struct OpiumPositionTokenParams {
        LibDerivative.Derivative derivative;
        LibDerivative.PositionType positionType;
        bytes32 derivativeHash;
    }

    address private factory;
    OpiumPositionTokenParams private opiumPositionTokenParams;

    /// @notice It is applied to all the stateful functions in OpiumPositionToken as they are meant to be consumed only via the OpiumProxyFactory
    modifier onlyFactory() {
        require(msg.sender == factory, "P1");
        _;
    }

    // ****************** EXTERNAL FUNCTIONS ******************

    // ***** SETTERS *****

    /// @notice `it is called only once upon deployment of the contract
    /// @dev it sets the state variables that are meant to be read-only and should be consumed by other contracts to retrieve information about the derivative
    /// @param _derivativeHash bytes32 hash of `LibDerivative.Derivative`
    /// @param _positionType  LibDerivative.PositionType _positionType describes whether the present ERC20 token is LONG or SHORT
    /// @param _derivative LibDerivative.Derivative Derivative definition
    function initialize(
        bytes32 _derivativeHash,
        LibDerivative.PositionType _positionType,
        LibDerivative.Derivative calldata _derivative
    ) external initializer {
        __ERC20_init("", "");
        __EIP712_init_unchained("Opium Position Token", "1");
        __ERC20Permit_init_unchained("");
        factory = msg.sender;
        opiumPositionTokenParams = OpiumPositionTokenParams({
            derivative: _derivative,
            positionType: _positionType,
            derivativeHash: _derivativeHash
        });
    }

    /// @notice it mints a specified amount of tokens to the given address
    /// @dev can only be called by the factory contract set in the `initialize` function
    /// @param _positionOwner address of the recipient of the position tokens
    /// @param _amount amount of position tokens to be minted to the _positionOwner
    function mint(address _positionOwner, uint256 _amount) external onlyFactory {
        _mint(_positionOwner, _amount);
    }

    /// @notice it burns a specified amount of tokens owned by the given address
    /// @dev can only be called by the factory contract set in the `initialize` function
    /// @param _positionOwner address of the owner of the position tokens
    /// @param _amount amount of position tokens to be burnt
    function burn(address _positionOwner, uint256 _amount) external onlyFactory {
        _burn(_positionOwner, _amount);
    }

    // ***** GETTERS *****

    /// @notice It retrieves the address of the factory contract set in the `initialize` function
    /// @return address of the factory contract (OpiumProxyFactory)
    function getFactoryAddress() external view returns (address) {
        return factory;
    }

    /// @notice It retrieves all the stored information about the underlying derivative
    /// @return _opiumPositionTokenParams OpiumPositionTokenParams struct which contains `LibDerivative.Derivative` schema of the derivative, the `LibDerivative.PositionType` of the present ERC20 token and the bytes32 hash `derivativeHash` of the `LibDerivative.Derivative` derivative
    function getPositionTokenData() external view returns (OpiumPositionTokenParams memory _opiumPositionTokenParams) {
        return opiumPositionTokenParams;
    }

    // ****************** PUBLIC FUNCTIONS ******************

    /**
     * @notice It overrides the OpenZeppelin name() getter and returns a custom erc20 name which is derived from the endTime of the erc20 token's associated derivative's maturity, the custom derivative name chosen by the derivative author and the derivative hash
     */
    function name() public view override returns (string memory) {
        string memory derivativeAuthorCustomName = IDerivativeLogic(opiumPositionTokenParams.derivative.syntheticId).getSyntheticIdName();
        string memory derivativeHashSlice = _toDerivativeHashStringIdentifier(opiumPositionTokenParams.derivativeHash);
        bytes memory endTimeDate = _toDerivativeEndTimeIdentifier(opiumPositionTokenParams.derivative.endTime);
        bytes memory baseCustomName = abi.encodePacked(
            "Opium:",
            endTimeDate,
            "-",
            derivativeAuthorCustomName,
            "-",
            derivativeHashSlice
        );
        return
            string(
                abi.encodePacked(
                    baseCustomName,
                    opiumPositionTokenParams.positionType == LibDerivative.PositionType.LONG ? "-LONG" : "-SHORT"
                )
            );
    }

    /**
     * @notice It overrides the OpenZeppelin symbol() getter and returns a custom erc20 symbol which is derived from the endTime of the erc20 token's associated derivative's maturity, the custom derivative name chosen by the derivative author and the derivative hash
     */
    function symbol() public view override returns (string memory) {
        string memory derivativeAuthorCustomName = IDerivativeLogic(opiumPositionTokenParams.derivative.syntheticId).getSyntheticIdName();
        string memory derivativeHashSlice = _toDerivativeHashStringIdentifier(opiumPositionTokenParams.derivativeHash);
        bytes memory endTimeDate = _toDerivativeEndTimeIdentifier(opiumPositionTokenParams.derivative.endTime);
        bytes memory customSymbol = abi.encodePacked(
            "OPIUM",
            "_",
            endTimeDate,
            "_",
            derivativeAuthorCustomName,
            "_",
            derivativeHashSlice
        );
        return
            string(
                abi.encodePacked(
                    customSymbol,
                    opiumPositionTokenParams.positionType == LibDerivative.PositionType.LONG ? "_L" : "_S"
                )
            );
    }

    // ****************** PRIVATE FUNCTIONS ******************

    /// @notice It is used to obtain a slice of derivativeHash and convert it to a string to be used as part of an Opium position token's name
    /// @param _data bytes32 representing a derivativeHash
    /// @return string representing the first 4 characters of a derivativeHash prefixed by "0x"
    function _toDerivativeHashStringIdentifier(bytes32 _data) private pure returns (string memory) {
        bytes4 result;
        assembly {
            result := or(
                and(
                    or(
                        shr(4, and(_data, 0xF000F000F000F000F000F000F000F000F000F000F000F000F000F000F000F000)),
                        shr(8, and(_data, 0x0F000F000F000F000F000F000F000F000F000F000F000F000F000F000F000F00))
                    ),
                    0xffff000000000000000000000000000000000000000000000000000000000000
                ),
                shr(
                    16,
                    or(
                        shr(4, and(shl(8, _data), 0xF000F000F000F000F000F000F000F000F000F000F000F000F000F000F000F000)),
                        shr(8, and(shl(8, _data), 0x0F000F000F000F000F000F000F000F000F000F000F000F000F000F000F000F00))
                    )
                )
            )
        }

        return
            string(
                abi.encodePacked(
                    "0x",
                    bytes4(0x30303030 + uint32(result) + (((uint32(result) + 0x06060606) >> 4) & 0x0F0F0F0F) * 7)
                )
            );
    }

    /// @notice It is used to convert a derivative.endTime to a human-readable date to be used as part of an Opium position token's name
    /// @dev { See the third-party library ./libs/LibBokkyPooBahsDateTimeLibrary.sol }
    /// @param _derivativeEndTime uint256 representing the timestamp of a given derivative's maturity
    /// @return bytes representing the encoding of the derivativeEndTime converted to day-month-year in the format DD/MM/YYYY
    function _toDerivativeEndTimeIdentifier(uint256 _derivativeEndTime) private pure returns (bytes memory) {
        (uint256 year, uint256 month, uint256 day) = BokkyPooBahsDateTimeLibrary.timestampToDate(_derivativeEndTime);

        return
            abi.encodePacked(
                StringsUpgradeable.toString(year),
                month < 10
                    ? abi.encodePacked("0", StringsUpgradeable.toString(month))
                    : bytes(StringsUpgradeable.toString(month)),
                day < 10
                    ? abi.encodePacked("0", StringsUpgradeable.toString(day))
                    : bytes(StringsUpgradeable.toString(day))
            );
    }

    // Reserved storage space to allow for layout changes in the future.
    // The gaps left for the `OpiumPositionToken` are less than the slots allocated for the other upgradeable contracts in the protocol because the OpiumPositionToken is the only contract that is programmatically deployed (frequently), hence we want to minimize the gas cost
    uint256[30] private __gap;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.5;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../../interfaces/IRegistry.sol";

/**
    Error codes:
    - M1 = ERROR_REGISTRY_MANAGER_ONLY_REGISTRY_MANAGER_ROLE
    - M2 = ERROR_REGISTRY_MANAGER_ONLY_CORE_CONFIGURATION_UPDATER_ROLE
 */
contract RegistryManager is Initializable {
    event LogRegistryChanged(address indexed _changer, address indexed _newRegistryAddress);

    IRegistry internal registry;

    modifier onlyRegistryManager() {
        require(registry.isRegistryManager(msg.sender), "M1");
        _;
    }

    modifier onlyCoreConfigurationUpdater() {
        require(registry.isCoreConfigurationUpdater(msg.sender), "M2");
        _;
    }

    function __RegistryManager__init(address _registry) internal initializer {
        require(_registry != address(0));
        registry = IRegistry(_registry);
        emit LogRegistryChanged(msg.sender, _registry);
    }

    function setRegistry(address _registry) external onlyRegistryManager {
        registry = IRegistry(_registry);
        emit LogRegistryChanged(msg.sender, _registry);
    }

    function getRegistry() external view returns (address) {
        return address(registry);
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[50] private __gap;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.5;

/// @title Opium.Lib.LibDerivative contract should be inherited by contracts that use Derivative structure and calculate derivativeHash
library LibDerivative {
    enum PositionType {
        SHORT,
        LONG
    }

    // Opium derivative structure (ticker) definition
    struct Derivative {
        // Margin parameter for syntheticId
        uint256 margin;
        // Maturity of derivative
        uint256 endTime;
        // Additional parameters for syntheticId
        uint256[] params;
        // oracleId of derivative
        address oracleId;
        // Margin token address of derivative
        address token;
        // syntheticId of derivative
        address syntheticId;
    }

    /// @notice Calculates hash of provided Derivative
    /// @param _derivative Derivative Instance of derivative to hash
    /// @return derivativeHash bytes32 Derivative hash
    function getDerivativeHash(Derivative memory _derivative) internal pure returns (bytes32 derivativeHash) {
        derivativeHash = keccak256(
            abi.encodePacked(
                _derivative.margin,
                _derivative.endTime,
                _derivative.params,
                _derivative.oracleId,
                _derivative.token,
                _derivative.syntheticId
            )
        );
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.5;

import "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";

library LibPosition {
    function predictDeterministicAddress(
        bytes32 _derivativeHash,
        bool _isLong,
        address _positionImplementationAddress,
        address _factoryAddress
    ) internal pure returns (address) {
        return _predictDeterministicAddress(_derivativeHash, _isLong, _positionImplementationAddress, _factoryAddress);
    }

    function predictAndCheckDeterministicAddress(
        bytes32 _derivativeHash,
        bool _isLong,
        address _positionImplementationAddress,
        address _factoryAddress
    ) internal view returns (address, bool) {
        address predicted = _predictDeterministicAddress(
            _derivativeHash,
            _isLong,
            _positionImplementationAddress,
            _factoryAddress
        );
        bool isDeployed = _isContract(predicted);
        return (predicted, isDeployed);
    }

    function deployOpiumPosition(
        bytes32 _derivativeHash,
        bool _isLong,
        address _positionImplementationAddress
    ) internal returns (address) {
        bytes32 salt = keccak256(abi.encodePacked(_derivativeHash, _isLong ? "L" : "S"));
        return ClonesUpgradeable.cloneDeterministic(_positionImplementationAddress, salt);
    }

    function _predictDeterministicAddress(
        bytes32 _derivativeHash,
        bool _isLong,
        address _positionImplementationAddress,
        address _factoryAddress
    ) private pure returns (address) {
        bytes32 salt = keccak256(abi.encodePacked(_derivativeHash, _isLong ? "L" : "S"));
        return ClonesUpgradeable.predictDeterministicAddress(_positionImplementationAddress, salt, _factoryAddress);
    }

    /// @notice checks whether a contract has already been deployed at a specific address
    /// @return bool true if a contract has been deployed at a specific address and false otherwise
    function _isContract(address _address) private view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(_address)
        }
        return size > 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

// ----------------------------------------------------------------------------
// BokkyPooBah's DateTime Library v1.01
//
// A gas-efficient Solidity date and time library
//
// https://github.com/bokkypoobah/BokkyPooBahsDateTimeLibrary
//
// Tested date range 1970/01/01 to 2345/12/31
//
// Conventions:
// Unit      | Range         | Notes
// :-------- |:-------------:|:-----
// timestamp | >= 0          | Unix timestamp, number of seconds since 1970/01/01 00:00:00 UTC
// year      | 1970 ... 2345 |
// month     | 1 ... 12      |
// day       | 1 ... 31      |
// hour      | 0 ... 23      |
// minute    | 0 ... 59      |
// second    | 0 ... 59      |
// dayOfWeek | 1 ... 7       | 1 = Monday, ..., 7 = Sunday
//
//
// Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2018-2019. The MIT Licence.
// ----------------------------------------------------------------------------

// version v1.01
library BokkyPooBahsDateTimeLibrary {
    uint256 constant SECONDS_PER_DAY = 24 * 60 * 60;
    int256 constant OFFSET19700101 = 2440588;

    // ------------------------------------------------------------------------
    // Calculate year/month/day from the number of days since 1970/01/01 using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and adding the offset 2440588 so that 1970/01/01 is day 0
    //
    // int L = days + 68569 + offset
    // int N = 4 * L / 146097
    // L = L - (146097 * N + 3) / 4
    // year = 4000 * (L + 1) / 1461001
    // L = L - 1461 * year / 4 + 31
    // month = 80 * L / 2447
    // dd = L - 2447 * month / 80
    // L = month / 11
    // month = month + 2 - 12 * L
    // year = 100 * (N - 49) + year + L
    // ------------------------------------------------------------------------
    function _daysToDate(uint256 _days)
        internal
        pure
        returns (
            uint256 year,
            uint256 month,
            uint256 day
        )
    {
        int256 __days = int256(_days);

        int256 L = __days + 68569 + OFFSET19700101;
        int256 N = (4 * L) / 146097;
        L = L - (146097 * N + 3) / 4;
        int256 _year = (4000 * (L + 1)) / 1461001;
        L = L - (1461 * _year) / 4 + 31;
        int256 _month = (80 * L) / 2447;
        int256 _day = L - (2447 * _month) / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;

        year = uint256(_year);
        month = uint256(_month);
        day = uint256(_day);
    }

    function timestampToDate(uint256 timestamp)
        internal
        pure
        returns (
            uint256 year,
            uint256 month,
            uint256 day
        )
    {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.5;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-IERC20PermitUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "../libs/LibDerivative.sol";

interface IOpiumPositionToken is IERC20PermitUpgradeable, IERC20Upgradeable {
    struct OpiumPositionTokenParams {
        LibDerivative.Derivative derivative;
        LibDerivative.PositionType positionType;
        bytes32 derivativeHash;
    }

    function initialize(
        bytes32 _derivativeHash,
        LibDerivative.PositionType _positionType,
        LibDerivative.Derivative calldata _derivative
    ) external;

    function mint(address _positionOwner, uint256 _amount) external;

    function burn(address _positionOwner, uint256 _amount) external;

    function getFactoryAddress() external view returns (address);

    function getPositionTokenData() external view returns (OpiumPositionTokenParams memory opiumPositionTokenParams);

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) external;

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.5;
import "../core/registry/RegistryEntities.sol";

interface IRegistry {
    function initialize(address _governor) external;

    function setProtocolAddresses(
        address _opiumProxyFactory,
        address _core,
        address _oracleAggregator,
        address _syntheticAggregator,
        address _tokenSpender
    ) external;

    function setNoDataCancellationPeriod(uint32 _noDataCancellationPeriod) external;

    function addToWhitelist(address _whitelisted) external;

    function removeFromWhitelist(address _whitelisted) external;

    function setProtocolExecutionReserveClaimer(address _protocolExecutionReserveClaimer) external;

    function setProtocolRedemptionReserveClaimer(address _protocolRedemptionReserveClaimer) external;

    function setProtocolExecutionReservePart(uint32 _protocolExecutionReservePart) external;

    function setDerivativeAuthorExecutionFeeCap(uint32 _derivativeAuthorExecutionFeeCap) external;

    function setProtocolRedemptionReservePart(uint32 _protocolRedemptionReservePart) external;

    function setDerivativeAuthorRedemptionReservePart(uint32 _derivativeAuthorRedemptionReservePart) external;

    function pause() external;

    function pauseProtocolPositionCreation() external;

    function pauseProtocolPositionMinting() external;

    function pauseProtocolPositionRedemption() external;

    function pauseProtocolPositionExecution() external;

    function pauseProtocolPositionCancellation() external;

    function pauseProtocolReserveClaim() external;

    function unpause() external;

    function getProtocolParameters() external view returns (RegistryEntities.ProtocolParametersArgs memory);

    function getProtocolAddresses() external view returns (RegistryEntities.ProtocolAddressesArgs memory);

    function isRegistryManager(address _address) external view returns (bool);

    function isCoreConfigurationUpdater(address _address) external view returns (bool);

    function getCore() external view returns (address);

    function isCoreSpenderWhitelisted(address _address) external view returns (bool);

    function isProtocolPaused() external view returns (bool);

    function isProtocolPositionCreationPaused() external view returns (bool);

    function isProtocolPositionMintingPaused() external view returns (bool);

    function isProtocolPositionRedemptionPaused() external view returns (bool);

    function isProtocolPositionExecutionPaused() external view returns (bool);

    function isProtocolPositionCancellationPaused() external view returns (bool);

    function isProtocolReserveClaimPaused() external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./draft-IERC20PermitUpgradeable.sol";
import "../ERC20Upgradeable.sol";
import "../../../utils/cryptography/draft-EIP712Upgradeable.sol";
import "../../../utils/cryptography/ECDSAUpgradeable.sol";
import "../../../utils/CountersUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * _Available since v3.4._
 */
abstract contract ERC20PermitUpgradeable is Initializable, ERC20Upgradeable, IERC20PermitUpgradeable, EIP712Upgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    mapping(address => CountersUpgradeable.Counter) private _nonces;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private _PERMIT_TYPEHASH;

    /**
     * @dev Initializes the {EIP712} domain separator using the `name` parameter, and setting `version` to `"1"`.
     *
     * It's a good idea to use the same `name` that is defined as the ERC20 token name.
     */
    function __ERC20Permit_init(string memory name) internal initializer {
        __Context_init_unchained();
        __EIP712_init_unchained(name, "1");
        __ERC20Permit_init_unchained(name);
    }

    function __ERC20Permit_init_unchained(string memory name) internal initializer {
        _PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");}

    /**
     * @dev See {IERC20Permit-permit}.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

        bytes32 structHash = keccak256(abi.encode(_PERMIT_TYPEHASH, owner, spender, value, _useNonce(owner), deadline));

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSAUpgradeable.recover(hash, v, r, s);
        require(signer == owner, "ERC20Permit: invalid signature");

        _approve(owner, spender, value);
    }

    /**
     * @dev See {IERC20Permit-nonces}.
     */
    function nonces(address owner) public view virtual override returns (uint256) {
        return _nonces[owner].current();
    }

    /**
     * @dev See {IERC20Permit-DOMAIN_SEPARATOR}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @dev "Consume a nonce": return the current value and increment.
     *
     * _Available since v4.1._
     */
    function _useNonce(address owner) internal virtual returns (uint256 current) {
        CountersUpgradeable.Counter storage nonce = _nonces[owner];
        current = nonce.current();
        nonce.increment();
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.5;

import "../libs/LibDerivative.sol";

/// @title Opium.Interface.IDerivativeLogic is an interface that every syntheticId should implement
interface IDerivativeLogic {
    // Event with syntheticId metadata JSON string (for DIB.ONE derivative explorer)
    event LogMetadataSet(string metadata);

    /// @notice Validates ticker
    /// @param _derivative Derivative Instance of derivative to validate
    /// @return Returns boolean whether ticker is valid
    function validateInput(LibDerivative.Derivative memory _derivative) external view returns (bool);

    /// @return Returns the custom name of a derivative ticker which will be used as part of the name of its positions
    function getSyntheticIdName() external view returns (string memory);

    /// @notice Calculates margin required for derivative creation
    /// @param _derivative Derivative Instance of derivative
    /// @return buyerMargin uint256 Margin needed from buyer (LONG position)
    /// @return sellerMargin uint256 Margin needed from seller (SHORT position)
    function getMargin(LibDerivative.Derivative memory _derivative)
        external
        view
        returns (uint256 buyerMargin, uint256 sellerMargin);

    /// @notice Calculates payout for derivative execution
    /// @param _derivative Derivative Instance of derivative
    /// @param _result uint256 Data retrieved from oracleId on the maturity
    /// @return buyerPayout uint256 Payout in ratio for buyer (LONG position holder)
    /// @return sellerPayout uint256 Payout in ratio for seller (SHORT position holder)
    function getExecutionPayout(LibDerivative.Derivative memory _derivative, uint256 _result)
        external
        view
        returns (uint256 buyerPayout, uint256 sellerPayout);

    /// @notice Returns syntheticId author address for Opium commissions
    /// @return authorAddress address The address of syntheticId address
    function getAuthorAddress() external view returns (address authorAddress);

    /// @notice Returns syntheticId author commission in base of COMMISSION_BASE
    /// @return commission uint256 Author commission
    function getAuthorCommission() external view returns (uint256 commission);

    /// @notice Returns whether thirdparty could execute on derivative's owner's behalf
    /// @param _derivativeOwner address Derivative owner address
    /// @return Returns boolean whether _derivativeOwner allowed third party execution
    function thirdpartyExecutionAllowed(address _derivativeOwner) external view returns (bool);

    /// @notice Sets whether thirds parties are allowed or not to execute derivative's on msg.sender's behalf
    /// @param _allow bool Flag for execution allowance
    function allowThirdpartyExecution(bool _allow) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20PermitUpgradeable {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal initializer {
        _name = name_;
        _symbol = symbol_;
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

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
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

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
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

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ECDSAUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712Upgradeable is Initializable {
    /* solhint-disable var-name-mixedcase */
    bytes32 private _HASHED_NAME;
    bytes32 private _HASHED_VERSION;
    bytes32 private constant _TYPE_HASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    function __EIP712_init(string memory name, string memory version) internal initializer {
        __EIP712_init_unchained(name, version);
    }

    function __EIP712_init_unchained(string memory name, string memory version) internal initializer {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        return _buildDomainSeparator(_TYPE_HASH, _EIP712NameHash(), _EIP712VersionHash());
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSAUpgradeable.toTypedDataHash(_domainSeparatorV4(), structHash);
    }

    /**
     * @dev The hash of the name parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712NameHash() internal virtual view returns (bytes32) {
        return _HASHED_NAME;
    }

    /**
     * @dev The hash of the version parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712VersionHash() internal virtual view returns (bytes32) {
        return _HASHED_VERSION;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library CountersUpgradeable {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
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
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
    function transferFrom(
        address sender,
        address recipient,
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

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.5;

library RegistryEntities {
    struct ProtocolParametersArgs {
        // Period of time after which ticker could be canceled if no data was provided to the `oracleId`
        uint32 noDataCancellationPeriod;
        // Max fee that derivative author can set
        // it works as an upper bound for when the derivative authors set their synthetic's fee
        uint32 derivativeAuthorExecutionFeeCap;
        // Fixed part (percentage) that the derivative author receives for each redemption of market neutral positions
        // It is not set by the derivative authors themselves
        uint32 derivativeAuthorRedemptionReservePart;
        // Represents which part of derivative author reserves originated from derivative executions go to the protocol reserves
        uint32 protocolExecutionReservePart;
        // Represents which part of derivative author reserves originated from redemption of market neutral positions go to the protocol reserves
        uint32 protocolRedemptionReservePart;
        /// Initially uninitialized variables to allow some flexibility in case of future changes and upgradeability
        uint32 __gapOne;
        uint32 __gapTwo;
        uint32 __gapThree;
    }

    struct ProtocolAddressesArgs {
        // Address of Opium.Core contract
        address core;
        // Address of Opium.OpiumProxyFactory contract
        address opiumProxyFactory;
        // Address of Opium.OracleAggregator contract
        address oracleAggregator;
        // Address of Opium.SyntheticAggregator contract
        address syntheticAggregator;
        // Address of Opium.TokenSpender contract
        address tokenSpender;
        // Address of the recipient of execution protocol reserves
        address protocolExecutionReserveClaimer;
        // Address of the recipient of redemption protocol reserves
        address protocolRedemptionReserveClaimer;
        /// Initially uninitialized variables to allow some flexibility in case of future changes and upgradeability
        uint32 __gapOne;
        uint32 __gapTwo;
    }

    struct ProtocolPausabilityArgs {
        // if true, all the protocol's entry-points are paused
        bool protocolGlobal;
        // if true, no new positions can be created
        bool protocolPositionCreation;
        // if true, no new positions can be minted
        bool protocolPositionMinting;
        // if true, no new positions can be redeemed
        bool protocolPositionRedemption;
        // if true, no new positions can be executed
        bool protocolPositionExecution;
        // if true, no new positions can be cancelled
        bool protocolPositionCancellation;
        // if true, no reserves can be claimed
        bool protocolReserveClaim;
        /// Initially uninitialized variables to allow some flexibility in case of future changes and upgradeability
        bool __gapOne;
        bool __gapTwo;
        bool __gapThree;
        bool __gapFour;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library ClonesUpgradeable {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}