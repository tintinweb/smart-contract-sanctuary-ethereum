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

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../../../../interfaces/IVotiumMultiMerkleStash.sol";

/// @title ConvexVotingPositionDataDecoder Contract
/// @author Enzyme Council <[email protected]>
/// @notice Abstract contract containing data decodings for ConvexVotingPosition payloads
abstract contract ConvexVotingPositionDataDecoder {
    /// @dev Helper to decode args used during the ClaimRewards action
    function __decodeClaimRewardsActionArgs(bytes memory _actionArgs)
        internal
        pure
        returns (
            address[] memory allTokensToTransfer_,
            bool claimLockerRewards_,
            address[] memory extraRewardTokens_,
            IVotiumMultiMerkleStash.ClaimParam[] memory votiumClaims_,
            bool unstakeCvxCrv_
        )
    {
        return
            abi.decode(
                _actionArgs,
                (address[], bool, address[], IVotiumMultiMerkleStash.ClaimParam[], bool)
            );
    }

    /// @dev Helper to decode args used during the Delegate action
    function __decodeDelegateActionArgs(bytes memory _actionArgs)
        internal
        pure
        returns (address delegatee_)
    {
        return abi.decode(_actionArgs, (address));
    }

    /// @dev Helper to decode args used during the Lock action
    function __decodeLockActionArgs(bytes memory _actionArgs)
        internal
        pure
        returns (uint256 amount_, uint256 spendRatio_)
    {
        return abi.decode(_actionArgs, (uint256, uint256));
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
import "./ConvexVotingPositionDataDecoder.sol";
import "./IConvexVotingPosition.sol";

pragma solidity 0.6.12;

/// @title ConvexVotingPositionParser
/// @author Enzyme Council <[email protected]>
/// @notice Parser for Convex vlCVX positions
contract ConvexVotingPositionParser is IExternalPositionParser, ConvexVotingPositionDataDecoder {
    address private immutable CVX_TOKEN;

    constructor(address _cvxToken) public {
        CVX_TOKEN = _cvxToken;
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
        if (_actionId == uint256(IConvexVotingPosition.Actions.Lock)) {
            (uint256 amount, ) = __decodeLockActionArgs(_encodedActionArgs);

            assetsToTransfer_ = new address[](1);
            assetsToTransfer_[0] = CVX_TOKEN;

            amountsToTransfer_ = new uint256[](1);
            amountsToTransfer_[0] = amount;
        } else if (_actionId == uint256(IConvexVotingPosition.Actions.Withdraw)) {
            assetsToReceive_ = new address[](1);
            assetsToReceive_[0] = CVX_TOKEN;
        }

        // No validations or transferred assets passed for Actions.ClaimRewards

        return (assetsToTransfer_, amountsToTransfer_, assetsToReceive_);
    }

    /// @notice Parse and validate input arguments to be used when initializing a newly-deployed ExternalPositionProxy
    /// @dev Empty for this external position type
    function parseInitArgs(address, bytes memory) external override returns (bytes memory) {}
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

/// @title IConvexVotingPosition Interface
/// @author Enzyme Council <[email protected]>
interface IConvexVotingPosition is IExternalPosition {
    enum Actions {Lock, Relock, Withdraw, ClaimRewards, Delegate}
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

/// @title IVotiumMultiMerkleStash Interface
/// @author Enzyme Council <[email protected]>
interface IVotiumMultiMerkleStash {
    struct ClaimParam {
        address token;
        uint256 index;
        uint256 amount;
        bytes32[] merkleProof;
    }

    function claimMulti(address, ClaimParam[] calldata) external;
}