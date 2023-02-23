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

import "../vault/interfaces/IVaultCore.sol";
import "./bases/GlobalConfigLibBase1.sol";
import "./interfaces/IGlobalConfig2.sol";
import "./interfaces/IGlobalConfigLibComptrollerV4.sol";

/// @title GlobalConfigLib Contract
/// @author Enzyme Council <[email protected]>
/// @notice The proxiable library contract for GlobalConfigProxy
/// @dev Only supports releases v4 and higher
contract GlobalConfigLib is IGlobalConfig2, GlobalConfigLibBase1 {
    uint256 private constant ONE_HUNDRED_PERCENT_IN_BPS = 10000;

    address private immutable FUND_DEPLOYER_V4;

    constructor(address _fundDeployerV4) public {
        FUND_DEPLOYER_V4 = _fundDeployerV4;
    }

    /// @notice Formats a deposit call, relative to a vault's current version
    /// @param _vaultProxy The VaultProxy (shares token)
    /// @param _depositAsset The token to deposit for shares
    /// @param _depositAssetAmount The exact amount of _depositAsset to deposit
    /// @dev Caller must validate expected shares received if required
    function formatDepositCall(
        address _vaultProxy,
        address _depositAsset,
        uint256 _depositAssetAmount
    ) external view override returns (address target_, bytes memory payload_) {
        // Get release for _vaultProxy
        address fundDeployer = __getFundDeployerForVaultProxy(_vaultProxy);

        if (fundDeployer == FUND_DEPLOYER_V4) {
            address comptrollerProxy = IVaultCore(_vaultProxy).getAccessor();

            // Deposit asset must be denominationAsset
            require(
                _depositAsset ==
                    IGlobalConfigLibComptrollerV4(comptrollerProxy).getDenominationAsset(),
                "formatDepositCall: Unsupported _depositAsset"
            );

            target_ = comptrollerProxy;
            payload_ = abi.encodeWithSelector(
                IGlobalConfigLibComptrollerV4.buyShares.selector,
                _depositAssetAmount,
                1
            );
        } else {
            revert("formatDepositCall: Unsupported release");
        }

        return (target_, payload_);
    }

    /// @notice Formats a redemption call to receive a single asset, relative to a vault's current version
    /// @param _vaultProxy The VaultProxy (shares token)
    /// @param _recipient The recipient of _asset
    /// @param _asset The asset to receive
    /// @param _amount The exact amount of either shares or _asset, determined by _amountIsShares
    /// @param _amountIsShares True if _amount is shares (to redeem), false if _asset (to receive)
    /// @dev Caller must validate expected shares received if required
    function formatSingleAssetRedemptionCall(
        address _vaultProxy,
        address _recipient,
        address _asset,
        uint256 _amount,
        bool _amountIsShares
    ) external view override returns (address target_, bytes memory payload_) {
        // Get release for _vaultProxy
        address fundDeployer = __getFundDeployerForVaultProxy(_vaultProxy);

        if (fundDeployer == FUND_DEPLOYER_V4) {
            // `_amountIsShares == false` is not yet unsupported
            require(
                _amountIsShares,
                "formatSingleAssetRedemptionCall: _amountIsShares must be true"
            );

            target_ = IVaultCore(_vaultProxy).getAccessor();

            address[] memory assets = new address[](1);
            assets[0] = _asset;

            uint256[] memory percentages = new uint256[](1);
            percentages[0] = ONE_HUNDRED_PERCENT_IN_BPS;

            payload_ = abi.encodeWithSelector(
                IGlobalConfigLibComptrollerV4.redeemSharesForSpecificAssets.selector,
                _recipient,
                _amount,
                assets,
                percentages
            );
        } else {
            revert("formatSingleAssetRedemptionCall: Unsupported release");
        }

        return (target_, payload_);
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
        address fundDeployer = __getFundDeployerForVaultProxy(_vaultProxy);

        // Validate call data based on release
        if (fundDeployer == FUND_DEPLOYER_V4) {
            // Validate contract
            if (_redeemContract != IVaultCore(_vaultProxy).getAccessor()) {
                return false;
            }

            // Validate selector
            if (
                !(_redeemSelector ==
                    IGlobalConfigLibComptrollerV4.redeemSharesForSpecificAssets.selector ||
                    _redeemSelector == IGlobalConfigLibComptrollerV4.redeemSharesInKind.selector)
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

    /// @dev Helper to get the FundDeployer (release) for a given vault
    function __getFundDeployerForVaultProxy(address _vaultProxy)
        private
        view
        returns (address fundDeployer_)
    {
        return IDispatcher(getDispatcher()).getFundDeployerForVaultProxy(_vaultProxy);
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
    address internal constant NO_VALIDATION_DUMMY_ADDRESS =
        0x000000000000000000000000000000000000aaaa;
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

    modifier onlyDispatcherOwner() {
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

import "./IGlobalConfig1.sol";

/// @title IGlobalConfig2 Interface
/// @author Enzyme Council <[email protected]>
/// @dev Each interface should inherit the previous interface,
/// e.g., `IGlobalConfig2 is IGlobalConfig1`
interface IGlobalConfig2 is IGlobalConfig1 {
    function formatDepositCall(
        address _vaultProxy,
        address _depositAsset,
        uint256 _depositAssetAmount
    ) external view returns (address target_, bytes memory payload_);

    function formatSingleAssetRedemptionCall(
        address _vaultProxy,
        address _recipient,
        address _asset,
        uint256 _amount,
        bool _amountIsShares
    ) external view returns (address target_, bytes memory payload_);
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.
    (c) Enzyme Council <[email protected]>
    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title IGlobalConfigLibComptrollerV4 Interface
/// @author Enzyme Council <[email protected]>
/// @notice Limited interface for GlobalConfigLib's required Enzyme v4 ComptrollerLib calls
interface IGlobalConfigLibComptrollerV4 {
    function buyShares(uint256 _investmentAmount, uint256 _minSharesQuantity)
        external
        returns (uint256 sharesReceived_);

    function getDenominationAsset() external view returns (address denominationAsset_);

    function redeemSharesForSpecificAssets(
        address _recipient,
        uint256 _sharesQuantity,
        address[] calldata _payoutAssets,
        uint256[] calldata _payoutAssetPercentages
    ) external returns (uint256[] memory payoutAmounts_);

    function redeemSharesInKind(
        address _recipient,
        uint256 _sharesQuantity,
        address[] calldata _additionalAssets,
        address[] calldata _assetsToSkip
    ) external returns (address[] memory payoutAssets_, uint256[] memory payoutAmounts_);
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
    bytes32 internal constant EIP_1822_PROXIABLE_UUID =
        0xf25d88d51901d7fabc9924b03f4c2fe4300e6fe1aae4b5134c0a90b68cd8e81c;
    // `bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1)`
    bytes32 internal constant EIP_1967_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
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

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title IVaultCore interface
/// @author Enzyme Council <[email protected]>
/// @notice Interface for getters of core vault storage
/// @dev DO NOT EDIT CONTRACT
interface IVaultCore {
    function getAccessor() external view returns (address accessor_);

    function getCreator() external view returns (address creator_);

    function getMigrator() external view returns (address migrator_);

    function getOwner() external view returns (address owner_);
}