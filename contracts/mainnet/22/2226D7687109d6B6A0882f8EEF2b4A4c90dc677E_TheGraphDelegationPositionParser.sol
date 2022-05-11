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

/// @title ITheGraphDelegationPosition Interface
/// @author Enzyme Council <[email protected]>
interface ITheGraphDelegationPosition is IExternalPosition {
    enum Actions {Delegate, Undelegate, Withdraw}
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.
    (c) Enzyme Council <[email protected]>
    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

/// @title TheGraphDelegationPositionDataDecoder Contract
/// @author Enzyme Council <[email protected]>
/// @notice Abstract contract containing data decodings for TheGraphDelegationPosition payloads
abstract contract TheGraphDelegationPositionDataDecoder {
    /// @dev Helper to decode args used during the Delegate action
    function __decodeDelegateActionArgs(bytes memory _actionArgs)
        internal
        pure
        returns (address indexer_, uint256 tokens_)
    {
        return abi.decode(_actionArgs, (address, uint256));
    }

    /// @dev Helper to decode args used during the Undelegate action
    function __decodeUndelegateActionArgs(bytes memory _actionArgs)
        internal
        pure
        returns (address indexer_, uint256 shares_)
    {
        return abi.decode(_actionArgs, (address, uint256));
    }

    /// @dev Helper to decode args used during the Withdraw action
    function __decodeWithdrawActionArgs(bytes memory _actionArgs)
        internal
        pure
        returns (address indexer_, address nextIndexer_)
    {
        return abi.decode(_actionArgs, (address, address));
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.
    (c) Enzyme Council <[email protected]>
    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

import "../IExternalPositionParser.sol";
import "./TheGraphDelegationPositionDataDecoder.sol";
import "./ITheGraphDelegationPosition.sol";

pragma solidity 0.6.12;

/// @title TheGraphDelegationPositionParser
/// @author Enzyme Council <[email protected]>
/// @notice Parser for The Graph Delegation positions
contract TheGraphDelegationPositionParser is
    IExternalPositionParser,
    TheGraphDelegationPositionDataDecoder
{
    address private immutable GRT_TOKEN;

    constructor(address _grtToken) public {
        GRT_TOKEN = _grtToken;
    }

    /// @notice Parses the assets to send and receive for the callOnExternalPosition
    /// @param _actionId The _actionId for the callOnExternalPosition
    /// @param _encodedActionArgs The encoded parameters for the callOnExternalPosition
    /// @return assetsToTransfer_ The assets to be transferred from the Vault
    /// @return amountsToTransfer_ The amounts to be transferred from the Vault
    /// @return assetsToReceive_ The assets to be received at the Vault
    function parseAssetsForAction(
        address,
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
        if (_actionId == uint256(ITheGraphDelegationPosition.Actions.Delegate)) {
            (, uint256 amount) = __decodeDelegateActionArgs(_encodedActionArgs);

            assetsToTransfer_ = new address[](1);
            assetsToTransfer_[0] = GRT_TOKEN;

            amountsToTransfer_ = new uint256[](1);
            amountsToTransfer_[0] = amount;
        } else {
            // Action.Undelegate and Action.Withdraw
            assetsToReceive_ = new address[](1);
            assetsToReceive_[0] = GRT_TOKEN;
        }

        return (assetsToTransfer_, amountsToTransfer_, assetsToReceive_);
    }

    /// @notice Parse and validate input arguments to be used when initializing a newly-deployed ExternalPositionProxy
    /// @dev Empty for this external position type
    function parseInitArgs(address, bytes memory) external override returns (bytes memory) {}
}