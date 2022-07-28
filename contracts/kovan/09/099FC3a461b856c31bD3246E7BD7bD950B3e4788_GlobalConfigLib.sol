// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title IDispatcher Interface
/// @author Enzyme Council <[email protected]>
interface IDispatcher {
    function cancelMigration(address _vaultProxy, bool _bypassFailure) external;

    function claimOwnership() external;

    function deployVaultProxy(
        address _vaultLib,
        address _owner,
        address _vaultAccessor,
        string calldata _fundName
    ) external returns (address vaultProxy_);

    function executeMigration(address _vaultProxy, bool _bypassFailure) external;

    function getCurrentFundDeployer() external view returns (address currentFundDeployer_);

    function getFundDeployerForVaultProxy(address _vaultProxy)
        external
        view
        returns (address fundDeployer_);

    function getMigrationRequestDetailsForVaultProxy(address _vaultProxy)
        external
        view
        returns (
            address nextFundDeployer_,
            address nextVaultAccessor_,
            address nextVaultLib_,
            uint256 executableTimestamp_
        );

    function getMigrationTimelock() external view returns (uint256 migrationTimelock_);

    function getNominatedOwner() external view returns (address nominatedOwner_);

    function getOwner() external view returns (address owner_);

    function getSharesTokenSymbol() external view returns (string memory sharesTokenSymbol_);

    function getTimelockRemainingForMigrationRequest(address _vaultProxy)
        external
        view
        returns (uint256 secondsRemaining_);

    function hasExecutableMigrationRequest(address _vaultProxy)
        external
        view
        returns (bool hasExecutableRequest_);

    function hasMigrationRequest(address _vaultProxy)
        external
        view
        returns (bool hasMigrationRequest_);

    function removeNominatedOwner() external;

    function setCurrentFundDeployer(address _nextFundDeployer) external;

    function setMigrationTimelock(uint256 _nextTimelock) external;

    function setNominatedOwner(address _nextNominatedOwner) external;

    function setSharesTokenSymbol(string calldata _nextSymbol) external;

    function signalMigration(
        address _vaultProxy,
        address _nextVaultAccessor,
        address _nextVaultLib,
        bool _bypassFailure
    ) external;
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.
    (c) Enzyme Council <[email protected]>
    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "./bases/GlobalConfigLibBase1.sol";
import "./interfaces/IGlobalConfig1.sol";
import "./interfaces/IGlobalConfigVaultAccessGetter.sol";

/// @title GlobalConfigLib Contract
/// @author Enzyme Council <[email protected]>
/// @notice The proxiable library contract for GlobalConfigProxy
/// @dev Only supports releases v4 and higher
contract GlobalConfigLib is IGlobalConfig1, GlobalConfigLibBase1 {
    bytes4 private constant REDEEM_IN_KIND_V4 = 0x6af8e7eb;
    bytes4 private constant REDEEM_SPECIFIC_ASSETS_V4 = 0x3462fcc1;

    address private immutable FUND_DEPLOYER_V4;

    constructor(address _fundDeployerV4) public {
        FUND_DEPLOYER_V4 = _fundDeployerV4;
    }

    /// @notice Validates whether a call to redeem shares is valid for the shares version
    /// @param _vaultProxy The VaultProxy (shares token)
    /// @param _recipientToValidate The intended recipient of the assets received from the redemption
    /// @param _sharesAmountToValidate The intended amount of shares to redeem
    /// @param _redeemContract The contract to call
    /// @param _redeemSelector The selector to call
    /// @param _redeemData The encoded params to call
    /// @return isValid_ True if valid
    /// @dev Use  NO_VALIDATION_ constants to skip optional validation of recipient and/or amount
    function isValidRedeemSharesCall(
        address _vaultProxy,
        address _recipientToValidate,
        uint256 _sharesAmountToValidate,
        address _redeemContract,
        bytes4 _redeemSelector,
        bytes calldata _redeemData
    ) external view override returns (bool isValid_) {
        // Get release for _vaultProxy
        address fundDeployer = IDispatcher(getDispatcher()).getFundDeployerForVaultProxy(
            _vaultProxy
        );

        // Validate call data based on release
        if (fundDeployer == FUND_DEPLOYER_V4) {
            // Validate contract
            if (_redeemContract != IGlobalConfigVaultAccessGetter(_vaultProxy).getAccessor()) {
                return false;
            }

            // Validate selector
            if (
                !(_redeemSelector == REDEEM_SPECIFIC_ASSETS_V4 ||
                    _redeemSelector == REDEEM_IN_KIND_V4)
            ) {
                return false;
            }

            // Both functions have the same first two params so we can ignore the rest of _redeemData
            (address encodedRecipient, uint256 encodedSharesAmount) = abi.decode(
                _redeemData,
                (address, uint256)
            );

            // Optionally validate recipient
            if (
                _recipientToValidate != NO_VALIDATION_DUMMY_ADDRESS &&
                _recipientToValidate != encodedRecipient
            ) {
                return false;
            }

            // Optionally validate shares amount
            if (
                _sharesAmountToValidate != NO_VALIDATION_DUMMY_AMOUNT &&
                _sharesAmountToValidate != encodedSharesAmount
            ) {
                return false;
            }

            return true;
        }

        return false;
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "./GlobalConfigLibBaseCore.sol";

/// @title GlobalConfigLibBase1 Contract
/// @author Enzyme Council <[email protected]>
/// @notice A base implementation for GlobalConfigLib
/// @dev Each next base implementation inherits the previous base implementation,
/// e.g., `GlobalConfigLibBase2 is GlobalConfigLibBase1`
/// DO NOT EDIT CONTRACT.
abstract contract GlobalConfigLibBase1 is GlobalConfigLibBaseCore {
    address
        internal constant NO_VALIDATION_DUMMY_ADDRESS = 0x000000000000000000000000000000000000aaaa;
    // Don't use max, since a max value can be valid
    uint256 internal constant NO_VALIDATION_DUMMY_AMOUNT = type(uint256).max - 1;
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.
    (c) Enzyme Council <[email protected]>
    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "../../../persistent/dispatcher/IDispatcher.sol";
import "../utils/ProxiableGlobalConfigLib.sol";

/// @title GlobalConfigLibBaseCore Contract
/// @author Enzyme Council <[email protected]>
/// @notice The core implementation of GlobalConfigLib
/// @dev To be inherited by the first GlobalConfigLibBase implementation only.
/// DO NOT EDIT CONTRACT.
abstract contract GlobalConfigLibBaseCore is ProxiableGlobalConfigLib {
    event GlobalConfigLibSet(address nextGlobalConfigLib);

    address internal dispatcher;

    modifier onlyDispatcherOwner {
        require(
            msg.sender == IDispatcher(getDispatcher()).getOwner(),
            "Only the Dispatcher owner can call this function"
        );

        _;
    }

    /// @notice Initializes the GlobalConfigProxy with core configuration
    /// @param _dispatcher The Dispatcher contract
    /// @dev Serves as a pseudo-constructor
    function init(address _dispatcher) external {
        require(getDispatcher() == address(0), "init: Proxy already initialized");

        dispatcher = _dispatcher;

        emit GlobalConfigLibSet(getGlobalConfigLib());
    }

    /// @notice Sets the GlobalConfigLib target for the GlobalConfigProxy
    /// @param _nextGlobalConfigLib The address to set as the GlobalConfigLib
    /// @dev This function is absolutely critical. __updateCodeAddress() validates that the
    /// target is a valid Proxiable contract instance.
    /// Does not block _nextGlobalConfigLib from being the same as the current GlobalConfigLib
    function setGlobalConfigLib(address _nextGlobalConfigLib) external onlyDispatcherOwner {
        __updateCodeAddress(_nextGlobalConfigLib);

        emit GlobalConfigLibSet(_nextGlobalConfigLib);
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the `dispatcher` variable
    /// @return dispatcher_ The `dispatcher` variable value
    function getDispatcher() public view returns (address dispatcher_) {
        return dispatcher;
    }

    /// @notice Gets the GlobalConfigLib target for the GlobalConfigProxy
    /// @return globalConfigLib_ The address of the GlobalConfigLib target
    function getGlobalConfigLib() public view returns (address globalConfigLib_) {
        assembly {
            globalConfigLib_ := sload(EIP_1967_SLOT)
        }

        return globalConfigLib_;
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title IGlobalConfig1 Interface
/// @author Enzyme Council <[email protected]>
/// @dev Each interface should inherit the previous interface,
/// e.g., `IGlobalConfig2 is IGlobalConfig1`
interface IGlobalConfig1 {
    function isValidRedeemSharesCall(
        address _vaultProxy,
        address _recipientToValidate,
        uint256 _sharesAmountToValidate,
        address _redeemContract,
        bytes4 _redeemSelector,
        bytes calldata _redeemData
    ) external view returns (bool isValid_);
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title IGlobalConfigVaultAccessGetter Interface
/// @author Enzyme Council <[email protected]>
/// @notice Vault access getters related to VaultLib from v2 to present
interface IGlobalConfigVaultAccessGetter {
    function getAccessor() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title GlobalConfigProxyConstants Contract
/// @author Enzyme Council <[email protected]>
/// @notice Constant values used in GlobalConfig proxy-related contracts
abstract contract GlobalConfigProxyConstants {
    // `bytes32(keccak256('mln.proxiable.globalConfigLib'))`
    bytes32
        internal constant EIP_1822_PROXIABLE_UUID = 0xf25d88d51901d7fabc9924b03f4c2fe4300e6fe1aae4b5134c0a90b68cd8e81c;
    // `bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1)`
    bytes32
        internal constant EIP_1967_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.
    (c) Enzyme Council <[email protected]>
    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "./GlobalConfigProxyConstants.sol";

/// @title ProxiableGlobalConfigLib Contract
/// @author Enzyme Council <[email protected]>
/// @notice A contract that defines the upgrade behavior for GlobalConfigLib instances
/// @dev The recommended implementation of the target of a proxy according to EIP-1822 and EIP-1967
/// See: https://eips.ethereum.org/EIPS/eip-1822
/// See: https://eips.ethereum.org/EIPS/eip-1967
abstract contract ProxiableGlobalConfigLib is GlobalConfigProxyConstants {
    /// @dev Updates the target of the proxy to be the contract at _nextGlobalConfigLib
    function __updateCodeAddress(address _nextGlobalConfigLib) internal {
        require(
            ProxiableGlobalConfigLib(_nextGlobalConfigLib).proxiableUUID() ==
                bytes32(EIP_1822_PROXIABLE_UUID),
            "__updateCodeAddress: _nextGlobalConfigLib not compatible"
        );
        assembly {
            sstore(EIP_1967_SLOT, _nextGlobalConfigLib)
        }
    }

    /// @notice Returns a unique bytes32 hash for GlobalConfigLib instances
    /// @return uuid_ The bytes32 hash representing the UUID
    function proxiableUUID() public pure returns (bytes32 uuid_) {
        return EIP_1822_PROXIABLE_UUID;
    }
}