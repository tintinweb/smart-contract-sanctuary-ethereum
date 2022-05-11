// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.
    (c) Enzyme Council <[email protected]>
    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title IExternalPosition Contract
/// @author Enzyme Council <[email protected]>
interface IExternalPosition {
    function getDebtAssets() external returns (address[] memory, uint256[] memory);

    function getManagedAssets() external returns (address[] memory, uint256[] memory);

    function init(bytes memory) external;

    function receiveCallFromVault(bytes memory) external;
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title IExternalPositionParser Interface
/// @author Enzyme Council <[email protected]>
/// @notice Interface for all external position parsers
interface IExternalPositionParser {
    function parseAssetsForAction(
        address _externalPosition,
        uint256 _actionId,
        bytes memory _encodedActionArgs
    )
        external
        returns (
            address[] memory assetsToTransfer_,
            uint256[] memory amountsToTransfer_,
            address[] memory assetsToReceive_
        );

    function parseInitArgs(address _vaultProxy, bytes memory _initializationData)
        external
        returns (bytes memory initArgs_);
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.
    (c) Enzyme Council <[email protected]>
    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

import "../../../../../persistent/external-positions/IExternalPosition.sol";

pragma solidity 0.6.12;

/// @title ILiquityDebtPosition Interface
/// @author Enzyme Council <[email protected]>
interface ILiquityDebtPosition is IExternalPosition {
    enum Actions {OpenTrove, AddCollateral, RemoveCollateral, Borrow, RepayBorrow, CloseTrove}
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.
    (c) Enzyme Council <[email protected]>
    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title LiquityDebtPositionDataDecoder Contract
/// @author Enzyme Council <[email protected]>
/// @notice Abstract contract containing data decodings for LiquityDebtPosition payloads
abstract contract LiquityDebtPositionDataDecoder {
    /// @dev Helper to decode args used during the AddCollateral action
    function __decodeAddCollateralActionArgs(bytes memory _actionArgs)
        internal
        pure
        returns (
            uint256 collateralAmount_,
            address upperHint_,
            address lowerHint_
        )
    {
        return abi.decode(_actionArgs, (uint256, address, address));
    }

    /// @dev Helper to decode args used during the Borrow action
    function __decodeBorrowActionArgs(bytes memory _actionArgs)
        internal
        pure
        returns (
            uint256 maxFeePercentage_,
            uint256 lusdAmount_,
            address upperHint_,
            address lowerHint_
        )
    {
        return abi.decode(_actionArgs, (uint256, uint256, address, address));
    }

    /// @dev Helper to decode args used during the CloseTrove action
    function __decodeCloseTroveActionArgs(bytes memory _actionArgs)
        internal
        pure
        returns (uint256 lusdAmount_)
    {
        return abi.decode(_actionArgs, (uint256));
    }

    /// @dev Helper to decode args used during the OpenTrove action
    function __decodeOpenTroveArgs(bytes memory _actionArgs)
        internal
        pure
        returns (
            uint256 maxFeePercentage_,
            uint256 collateralAmount_,
            uint256 lusdAmount_,
            address upperHint_,
            address lowerHint_
        )
    {
        return abi.decode(_actionArgs, (uint256, uint256, uint256, address, address));
    }

    /// @dev Helper to decode args used during the RemoveCollateral action
    function __decodeRemoveCollateralActionArgs(bytes memory _actionArgs)
        internal
        pure
        returns (
            uint256 collateralAmount_,
            address upperHint_,
            address lowerHint_
        )
    {
        return abi.decode(_actionArgs, (uint256, address, address));
    }

    /// @dev Helper to decode args used during the RepayBorrow action
    function __decodeRepayBorrowActionArgs(bytes memory _actionArgs)
        internal
        pure
        returns (
            uint256 lusdAmount_,
            address upperHint_,
            address lowerHint_
        )
    {
        return abi.decode(_actionArgs, (uint256, address, address));
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

import "../.../../../../../interfaces/ILiquityTroveManager.sol";
import "../IExternalPositionParser.sol";
import "./ILiquityDebtPosition.sol";
import "./LiquityDebtPositionDataDecoder.sol";

pragma solidity 0.6.12;

/// @title LiquityDebtPositionParser
/// @author Enzyme Council <[email protected]>
/// @notice Parser for Liquity Debt Positions
contract LiquityDebtPositionParser is IExternalPositionParser, LiquityDebtPositionDataDecoder {
    address private immutable LIQUITY_TROVE_MANAGER;
    address private immutable LUSD_TOKEN;
    address private immutable WETH_TOKEN;

    constructor(
        address _liquityTroveManager,
        address _lusdToken,
        address _wethToken
    ) public {
        LIQUITY_TROVE_MANAGER = _liquityTroveManager;
        LUSD_TOKEN = _lusdToken;
        WETH_TOKEN = _wethToken;
    }

    /// @notice Parses the assets to send and receive for the callOnExternalPosition
    /// @param _externalPosition The _externalPosition to be called
    /// @param _actionId The _actionId for the callOnExternalPosition
    /// @param _encodedActionArgs The encoded parameters for the callOnExternalPosition
    /// @return assetsToTransfer_ The assets to be transfered from the Vault
    /// @return amountsToTransfer_ The amounts to be transfered from the Vault
    /// @return assetsToReceive_ The assets to be received at the Vault
    function parseAssetsForAction(
        address _externalPosition,
        uint256 _actionId,
        bytes memory _encodedActionArgs
    )
        external
        override
        returns (
            address[] memory assetsToTransfer_,
            uint256[] memory amountsToTransfer_,
            address[] memory assetsToReceive_
        )
    {
        if (_actionId == uint256(ILiquityDebtPosition.Actions.OpenTrove)) {
            (, uint256 collateralAmount, , , ) = __decodeOpenTroveArgs(_encodedActionArgs);

            assetsToTransfer_ = new address[](1);
            amountsToTransfer_ = new uint256[](1);
            assetsToTransfer_[0] = WETH_TOKEN;
            amountsToTransfer_[0] = collateralAmount;
            assetsToReceive_ = new address[](1);
            assetsToReceive_[0] = LUSD_TOKEN;
        }
        if (_actionId == uint256(ILiquityDebtPosition.Actions.AddCollateral)) {
            (uint256 collateralAmount, , ) = __decodeAddCollateralActionArgs(_encodedActionArgs);

            assetsToTransfer_ = new address[](1);
            amountsToTransfer_ = new uint256[](1);
            assetsToTransfer_[0] = WETH_TOKEN;
            amountsToTransfer_[0] = collateralAmount;
        }
        if (_actionId == uint256(ILiquityDebtPosition.Actions.RemoveCollateral)) {
            assetsToReceive_ = new address[](1);
            assetsToReceive_[0] = WETH_TOKEN;
        } else if (_actionId == uint256(ILiquityDebtPosition.Actions.RepayBorrow)) {
            (uint256 lusdAmount, , ) = __decodeRepayBorrowActionArgs(_encodedActionArgs);
            assetsToTransfer_ = new address[](1);
            amountsToTransfer_ = new uint256[](1);
            assetsToTransfer_[0] = LUSD_TOKEN;
            amountsToTransfer_[0] = lusdAmount;
        } else if (_actionId == uint256(ILiquityDebtPosition.Actions.Borrow)) {
            assetsToReceive_ = new address[](1);
            assetsToReceive_[0] = LUSD_TOKEN;
        } else if (_actionId == uint256(ILiquityDebtPosition.Actions.CloseTrove)) {
            uint256 lusdAmount = ILiquityTroveManager(LIQUITY_TROVE_MANAGER).getTroveDebt(
                _externalPosition
            );

            assetsToTransfer_ = new address[](1);
            assetsToReceive_ = new address[](1);
            amountsToTransfer_ = new uint256[](1);

            assetsToTransfer_[0] = LUSD_TOKEN;
            amountsToTransfer_[0] = lusdAmount;
            assetsToReceive_[0] = WETH_TOKEN;
        }

        return (assetsToTransfer_, amountsToTransfer_, assetsToReceive_);
    }

    /// @notice Parse and validate input arguments to be used when initializing a newly-deployed ExternalPositionProxy
    /// @return initArgs_ Parsed and encoded args for ExternalPositionProxy.init()
    function parseInitArgs(address, bytes memory)
        external
        override
        returns (bytes memory initArgs_)
    {
        return "";
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

/// @title ILiquityTroveManager Interface
/// @author Enzyme Council <[email protected]>
/// @notice Minimal interface for our interactions with Liquity Trove Mangager contract
interface ILiquityTroveManager {
    function getTroveColl(address) external view returns (uint256);

    function getTroveDebt(address) external view returns (uint256);
}