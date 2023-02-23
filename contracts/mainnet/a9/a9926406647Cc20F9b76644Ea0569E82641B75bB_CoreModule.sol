//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title Library for access related errors.
 */
library AccessError {
    /**
     * @dev Thrown when an address tries to perform an unauthorized action.
     * @param addr The address that attempts the action.
     */
    error Unauthorized(address addr);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title Library for address related errors.
 */
library AddressError {
    /**
     * @dev Thrown when a zero address was passed as a function parameter (0x0000000000000000000000000000000000000000).
     */
    error ZeroAddress();

    /**
     * @dev Thrown when an address representing a contract is expected, but no code is found at the address.
     * @param contr The address that was expected to be a contract.
     */
    error NotAContract(address contr);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title Library for change related errors.
 */
library ChangeError {
    /**
     * @dev Thrown when a change is expected but none is detected.
     */
    error NoChange();
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title Library for initialization related errors.
 */
library InitError {
    /**
     * @dev Thrown when attempting to initialize a contract that is already initialized.
     */
    error AlreadyInitialized();

    /**
     * @dev Thrown when attempting to interact with a contract that has not been initialized yet.
     */
    error NotInitialized();
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "../errors/InitError.sol";

/**
 * @title Mixin for contracts that require initialization.
 */
abstract contract InitializableMixin {
    /**
     * @dev Reverts if contract is not initialized.
     */
    modifier onlyIfInitialized() {
        if (!_isInitialized()) {
            revert InitError.NotInitialized();
        }

        _;
    }

    /**
     * @dev Reverts if contract is already initialized.
     */
    modifier onlyIfNotInitialized() {
        if (_isInitialized()) {
            revert InitError.AlreadyInitialized();
        }

        _;
    }

    /**
     * @dev Override this function to determine if the contract is initialized.
     * @return True if initialized, false otherwise.
     */
    function _isInitialized() internal view virtual returns (bool);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title Contract for facilitating ownership by a single address.
 */
interface IOwnable {
    /**
     * @notice Thrown when an address tries to accept ownership but has not been nominated.
     * @param addr The address that is trying to accept ownership.
     */
    error NotNominated(address addr);

    /**
     * @notice Emitted when an address has been nominated.
     * @param newOwner The address that has been nominated.
     */
    event OwnerNominated(address newOwner);

    /**
     * @notice Emitted when the owner of the contract has changed.
     * @param oldOwner The previous owner of the contract.
     * @param newOwner The new owner of the contract.
     */
    event OwnerChanged(address oldOwner, address newOwner);

    /**
     * @notice Allows a nominated address to accept ownership of the contract.
     * @dev Reverts if the caller is not nominated.
     */
    function acceptOwnership() external;

    /**
     * @notice Allows the current owner to nominate a new owner.
     * @dev The nominated owner will have to call `acceptOwnership` in a separate transaction in order to finalize the action and become the new contract owner.
     * @param newNominatedOwner The address that is to become nominated.
     */
    function nominateNewOwner(address newNominatedOwner) external;

    /**
     * @notice Allows a nominated owner to reject the nomination.
     */
    function renounceNomination() external;

    /**
     * @notice Returns the current owner of the contract.
     */
    function owner() external view returns (address);

    /**
     * @notice Returns the current nominated owner of the contract.
     * @dev Only one address can be nominated at a time.
     */
    function nominatedOwner() external view returns (address);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title Contract to be used as the implementation of a Universal Upgradeable Proxy Standard (UUPS) proxy.
 *
 * Important: A UUPS proxy requires its upgradeability functions to be in the implementation as opposed to the proxy. This means that if the proxy is upgraded to an implementation that does not support this interface, it will no longer be upgradeable.
 */
interface IUUPSImplementation {
    /**
     * @notice Thrown when an incoming implementation will not be able to receive future upgrades.
     */
    error ImplementationIsSterile(address implementation);

    /**
     * @notice Thrown intentionally when testing future upgradeability of an implementation.
     */
    error UpgradeSimulationFailed();

    /**
     * @notice Emitted when the implementation of the proxy has been upgraded.
     * @param self The address of the proxy whose implementation was upgraded.
     * @param implementation The address of the proxy's new implementation.
     */
    event Upgraded(address indexed self, address implementation);

    /**
     * @notice Allows the proxy to be upgraded to a new implementation.
     * @param newImplementation The address of the proxy's new implementation.
     * @dev Will revert if `newImplementation` is not upgradeable.
     * @dev The implementation of this function needs to be protected by some sort of access control such as `onlyOwner`.
     */
    function upgradeTo(address newImplementation) external;

    /**
     * @notice Function used to determine if a new implementation will be able to receive future upgrades in `upgradeTo`.
     * @param newImplementation The address of the new implementation being tested for future upgradeability.
     * @dev This function will always revert, but will revert with different error messages. The function `upgradeTo` uses this error to determine the future upgradeability of the implementation in question.
     */
    function simulateUpgradeTo(address newImplementation) external;

    /**
     * @notice Retrieves the current implementation of the proxy.
     * @return The address of the current implementation.
     */
    function getImplementation() external view returns (address);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "./OwnableStorage.sol";
import "../interfaces/IOwnable.sol";
import "../errors/AddressError.sol";
import "../errors/ChangeError.sol";

/**
 * @title Contract for facilitating ownership by a single address.
 * See IOwnable.
 */
contract Ownable is IOwnable {
    constructor(address initialOwner) {
        OwnableStorage.load().owner = initialOwner;
    }

    /**
     * @inheritdoc IOwnable
     */
    function acceptOwnership() public override {
        OwnableStorage.Data storage store = OwnableStorage.load();

        address currentNominatedOwner = store.nominatedOwner;
        if (msg.sender != currentNominatedOwner) {
            revert NotNominated(msg.sender);
        }

        emit OwnerChanged(store.owner, currentNominatedOwner);
        store.owner = currentNominatedOwner;

        store.nominatedOwner = address(0);
    }

    /**
     * @inheritdoc IOwnable
     */
    function nominateNewOwner(address newNominatedOwner) public override onlyOwner {
        OwnableStorage.Data storage store = OwnableStorage.load();

        if (newNominatedOwner == address(0)) {
            revert AddressError.ZeroAddress();
        }

        if (newNominatedOwner == store.nominatedOwner) {
            revert ChangeError.NoChange();
        }

        store.nominatedOwner = newNominatedOwner;
        emit OwnerNominated(newNominatedOwner);
    }

    /**
     * @inheritdoc IOwnable
     */
    function renounceNomination() external override {
        OwnableStorage.Data storage store = OwnableStorage.load();

        if (store.nominatedOwner != msg.sender) {
            revert NotNominated(msg.sender);
        }

        store.nominatedOwner = address(0);
    }

    /**
     * @inheritdoc IOwnable
     */
    function owner() external view override returns (address) {
        return OwnableStorage.load().owner;
    }

    /**
     * @inheritdoc IOwnable
     */
    function nominatedOwner() external view override returns (address) {
        return OwnableStorage.load().nominatedOwner;
    }

    /**
     * @dev Reverts if the caller is not the owner.
     */
    modifier onlyOwner() {
        OwnableStorage.onlyOwner();

        _;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "../errors/AccessError.sol";

library OwnableStorage {
    bytes32 private constant _SLOT_OWNABLE_STORAGE =
        keccak256(abi.encode("io.synthetix.core-contracts.Ownable"));

    struct Data {
        address owner;
        address nominatedOwner;
    }

    function load() internal pure returns (Data storage store) {
        bytes32 s = _SLOT_OWNABLE_STORAGE;
        assembly {
            store.slot := s
        }
    }

    function onlyOwner() internal view {
        if (msg.sender != getOwner()) {
            revert AccessError.Unauthorized(msg.sender);
        }
    }

    function getOwner() internal view returns (address) {
        return OwnableStorage.load().owner;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

contract ProxyStorage {
    bytes32 private constant _SLOT_PROXY_STORAGE =
        keccak256(abi.encode("io.synthetix.core-contracts.Proxy"));

    struct ProxyStore {
        address implementation;
        bool simulatingUpgrade;
    }

    function _proxyStore() internal pure returns (ProxyStore storage store) {
        bytes32 s = _SLOT_PROXY_STORAGE;
        assembly {
            store.slot := s
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "../interfaces/IUUPSImplementation.sol";
import "../errors/AddressError.sol";
import "../errors/ChangeError.sol";
import "../utils/AddressUtil.sol";
import "./ProxyStorage.sol";

abstract contract UUPSImplementation is IUUPSImplementation, ProxyStorage {
    /**
     * @inheritdoc IUUPSImplementation
     */
    function simulateUpgradeTo(address newImplementation) public override {
        ProxyStore storage store = _proxyStore();

        store.simulatingUpgrade = true;

        address currentImplementation = store.implementation;
        store.implementation = newImplementation;

        (bool rollbackSuccessful, ) = newImplementation.delegatecall(
            abi.encodeCall(this.upgradeTo, (currentImplementation))
        );

        if (!rollbackSuccessful || _proxyStore().implementation != currentImplementation) {
            revert UpgradeSimulationFailed();
        }

        store.simulatingUpgrade = false;

        // solhint-disable-next-line reason-string
        revert();
    }

    /**
     * @inheritdoc IUUPSImplementation
     */
    function getImplementation() external view override returns (address) {
        return _proxyStore().implementation;
    }

    function _upgradeTo(address newImplementation) internal virtual {
        if (newImplementation == address(0)) {
            revert AddressError.ZeroAddress();
        }

        if (!AddressUtil.isContract(newImplementation)) {
            revert AddressError.NotAContract(newImplementation);
        }

        ProxyStore storage store = _proxyStore();

        if (newImplementation == store.implementation) {
            revert ChangeError.NoChange();
        }

        if (!store.simulatingUpgrade && _implementationIsSterile(newImplementation)) {
            revert ImplementationIsSterile(newImplementation);
        }

        store.implementation = newImplementation;

        emit Upgraded(address(this), newImplementation);
    }

    function _implementationIsSterile(
        address candidateImplementation
    ) internal virtual returns (bool) {
        (bool simulationReverted, bytes memory simulationResponse) = address(this).delegatecall(
            abi.encodeCall(this.simulateUpgradeTo, (candidateImplementation))
        );

        return
            !simulationReverted &&
            keccak256(abi.encodePacked(simulationResponse)) ==
            keccak256(abi.encodePacked(UpgradeSimulationFailed.selector));
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

library AddressUtil {
    function isContract(address account) internal view returns (bool) {
        uint256 size;

        assembly {
            size := extcodesize(account)
        }

        return size > 0;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title Module for giving a system owner based access control.
 */
// solhint-disable-next-line no-empty-blocks
interface IOwnerModule {

}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import {OwnerModule} from "./OwnerModule.sol";
import {UpgradeModule} from "./UpgradeModule.sol";

// solhint-disable-next-line no-empty-blocks
contract CoreModule is OwnerModule, UpgradeModule {

}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "@synthetixio/core-contracts/contracts/ownership/Ownable.sol";
import "@synthetixio/core-contracts/contracts/initializable/InitializableMixin.sol";
import "../interfaces/IOwnerModule.sol";

/**
 * @title Module for giving a system owner based access control.
 * See IOwnerModule.
 */
contract OwnerModule is Ownable, IOwnerModule {
    // solhint-disable-next-line no-empty-blocks
    constructor() Ownable(address(0)) {
        // empty intentionally
    }

    // no impl intentionally
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "@synthetixio/core-contracts/contracts/proxy/UUPSImplementation.sol";
import "@synthetixio/core-contracts/contracts/ownership/OwnableStorage.sol";

contract UpgradeModule is UUPSImplementation {
    function upgradeTo(address newImplementation) public override {
        OwnableStorage.onlyOwner();
        _upgradeTo(newImplementation);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/// @title Interface an aggregator needs to adhere.
interface IAggregatorV3Interface {
    /// @notice decimals used by the aggregator
    function decimals() external view returns (uint8);

    /// @notice aggregator's description
    function description() external view returns (string memory);

    /// @notice aggregator's version
    function version() external view returns (uint256);

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    /// @notice get's round data for requested id
    function getRoundData(
        uint80 id
    )
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    /// @notice get's latest round data
    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "../interfaces/external/IAggregatorV3Interface.sol";

contract AggregatorV3Mock is IAggregatorV3Interface {
    uint80 private _roundId;
    uint256 private _timestamp;
    uint256 private _price;

    function decimals() external pure override returns (uint8) {
        return 18;
    }

    function description() external pure override returns (string memory) {
        return "Fake price feed";
    }

    function version() external pure override returns (uint256) {
        return 3;
    }

    function mockSetCurrentPrice(uint256 currentPrice) external {
        _price = currentPrice;
        _timestamp = block.timestamp;
        _roundId++;
    }

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function getRoundData(
        uint80
    )
        external
        view
        override
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        return this.latestRoundData();
    }

    function latestRoundData()
        external
        view
        override
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        // solhint-disable-next-line numcast/safe-cast
        return (_roundId, int256(_price), _timestamp, _timestamp, _roundId);
    }

    function setRoundId(uint80 roundId) external {
        _roundId = roundId;
    }

    function setTimestamp(uint256 timestamp) external {
        _timestamp = timestamp;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "@synthetixio/main/contracts/mocks/AggregatorV3Mock.sol";

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import {CoreModule as BaseCoreModule} from "@synthetixio/core-modules/contracts/modules/CoreModule.sol";

// solhint-disable-next-line no-empty-blocks
contract CoreModule is BaseCoreModule {

}