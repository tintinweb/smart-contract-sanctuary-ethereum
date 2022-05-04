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

/// @title IMapleLiquidityPosition Interface
/// @author Enzyme Council <[email protected]>
interface IMapleLiquidityPosition is IExternalPosition {
    enum Actions {
        Lend,
        LendAndStake,
        IntendToRedeem,
        Redeem,
        Stake,
        Unstake,
        UnstakeAndRedeem,
        ClaimInterest,
        ClaimRewards
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

/// @title MapleLiquidityPositionDataDecoder Contract
/// @author Enzyme Council <[email protected]>
/// @notice Abstract contract containing data decodings for MapleLiquidityPosition payloads
abstract contract MapleLiquidityPositionDataDecoder {
    /// @dev Helper to decode args used during the ClaimInterest action
    function __decodeClaimInterestActionArgs(bytes memory _actionArgs)
        internal
        pure
        returns (address pool_)
    {
        return abi.decode(_actionArgs, (address));
    }

    /// @dev Helper to decode args used during the ClaimRewards action
    function __decodeClaimRewardsActionArgs(bytes memory _actionArgs)
        internal
        pure
        returns (address rewardsContract_)
    {
        return abi.decode(_actionArgs, (address));
    }

    /// @dev Helper to decode args used during the Lend action
    function __decodeLendActionArgs(bytes memory _actionArgs)
        internal
        pure
        returns (address pool_, uint256 liquidityAssetAmount_)
    {
        return abi.decode(_actionArgs, (address, uint256));
    }

    /// @dev Helper to decode args used during the LendAndStake action
    function __decodeLendAndStakeActionArgs(bytes memory _actionArgs)
        internal
        pure
        returns (
            address pool_,
            address rewardsContract_,
            uint256 liquidityAssetAmount_
        )
    {
        return abi.decode(_actionArgs, (address, address, uint256));
    }

    /// @dev Helper to decode args used during the IntendToRedeem action
    function __decodeIntendToRedeemActionArgs(bytes memory _actionArgs)
        internal
        pure
        returns (address pool_)
    {
        return abi.decode(_actionArgs, (address));
    }

    /// @dev Helper to decode args used during the Redeem action
    function __decodeRedeemActionArgs(bytes memory _actionArgs)
        internal
        pure
        returns (address pool_, uint256 liquidityAssetAmount_)
    {
        return abi.decode(_actionArgs, (address, uint256));
    }

    /// @dev Helper to decode args used during the Stake action
    function __decodeStakeActionArgs(bytes memory _actionArgs)
        internal
        pure
        returns (
            address rewardsContract_,
            address pool_,
            uint256 poolTokenAmount_
        )
    {
        return abi.decode(_actionArgs, (address, address, uint256));
    }

    /// @dev Helper to decode args used during the Unstake action
    function __decodeUnstakeActionArgs(bytes memory _actionArgs)
        internal
        pure
        returns (address rewardsContract_, uint256 poolTokenAmount_)
    {
        return abi.decode(_actionArgs, (address, uint256));
    }

    /// @dev Helper to decode args used during the UnstakeAndRedeem action
    function __decodeUnstakeAndRedeemActionArgs(bytes memory _actionArgs)
        internal
        pure
        returns (
            address pool_,
            address rewardsContract_,
            uint256 poolTokenAmount_
        )
    {
        return abi.decode(_actionArgs, (address, address, uint256));
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

import "../../../../interfaces/IMaplePool.sol";
import "../../../../interfaces/IMaplePoolFactory.sol";
import "../../../../interfaces/IMapleMplRewardsFactory.sol";
import "../IExternalPositionParser.sol";
import "./IMapleLiquidityPosition.sol";
import "./MapleLiquidityPositionDataDecoder.sol";

pragma solidity 0.6.12;

/// @title MapleLiquidityPositionParser
/// @author Enzyme Council <[email protected]>
/// @notice Parser for Maple Debt Positions
contract MapleLiquidityPositionParser is
    MapleLiquidityPositionDataDecoder,
    IExternalPositionParser
{
    address private immutable MAPLE_POOL_FACTORY;
    address private immutable MAPLE_MPL_REWARDS_FACTORY;

    constructor(address _maplePoolFactory, address _mapleMplRewardsFactory) public {
        MAPLE_POOL_FACTORY = _maplePoolFactory;
        MAPLE_MPL_REWARDS_FACTORY = _mapleMplRewardsFactory;
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
        __validateActionData(_actionId, _encodedActionArgs);

        if (_actionId == uint256(IMapleLiquidityPosition.Actions.Lend)) {
            (address pool, uint256 liquidityAssetAmount) = __decodeLendActionArgs(
                _encodedActionArgs
            );

            assetsToTransfer_ = new address[](1);
            amountsToTransfer_ = new uint256[](1);

            assetsToTransfer_[0] = IMaplePool(pool).liquidityAsset();
            amountsToTransfer_[0] = liquidityAssetAmount;
        } else if (_actionId == uint256(IMapleLiquidityPosition.Actions.LendAndStake)) {
            (address pool, , uint256 liquidityAssetAmount) = __decodeLendAndStakeActionArgs(
                _encodedActionArgs
            );

            assetsToTransfer_ = new address[](1);
            amountsToTransfer_ = new uint256[](1);

            assetsToTransfer_[0] = IMaplePool(pool).liquidityAsset();
            amountsToTransfer_[0] = liquidityAssetAmount;
        } else if (_actionId == uint256(IMapleLiquidityPosition.Actions.Redeem)) {
            (address pool, ) = __decodeRedeemActionArgs(_encodedActionArgs);

            assetsToReceive_ = new address[](1);
            assetsToReceive_[0] = IMaplePool(pool).liquidityAsset();
        } else if (_actionId == uint256(IMapleLiquidityPosition.Actions.UnstakeAndRedeem)) {
            (address pool, , ) = __decodeUnstakeAndRedeemActionArgs(_encodedActionArgs);

            assetsToReceive_ = new address[](1);
            assetsToReceive_[0] = IMaplePool(pool).liquidityAsset();
        } else if (_actionId == uint256(IMapleLiquidityPosition.Actions.ClaimInterest)) {
            address pool = __decodeClaimInterestActionArgs(_encodedActionArgs);

            assetsToReceive_ = new address[](1);
            assetsToReceive_[0] = IMaplePool(pool).liquidityAsset();
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

    // PRIVATE FUNCTIONS

    /// @dev Runs validations before running a callOnExternalPosition.
    function __validateActionData(uint256 _actionId, bytes memory _actionArgs) private view {
        if (_actionId == uint256(IMapleLiquidityPosition.Actions.Lend)) {
            (address pool, ) = __decodeLendActionArgs(_actionArgs);

            __validatePool(pool);
        } else if (_actionId == uint256(IMapleLiquidityPosition.Actions.LendAndStake)) {
            (address pool, address rewardsContract, ) = __decodeLendAndStakeActionArgs(
                _actionArgs
            );

            __validatePool(pool);
            __validateRewardsContract(rewardsContract);
        } else if (_actionId == uint256(IMapleLiquidityPosition.Actions.IntendToRedeem)) {
            address pool = __decodeIntendToRedeemActionArgs(_actionArgs);

            __validatePool(pool);
        } else if (_actionId == uint256(IMapleLiquidityPosition.Actions.Redeem)) {
            (address pool, ) = __decodeRedeemActionArgs(_actionArgs);

            __validatePool(pool);
        } else if (_actionId == uint256(IMapleLiquidityPosition.Actions.Stake)) {
            (address rewardsContract, address pool, ) = __decodeStakeActionArgs(_actionArgs);

            __validatePool(pool);
            __validateRewardsContract(rewardsContract);
        } else if (_actionId == uint256(IMapleLiquidityPosition.Actions.Unstake)) {
            (address rewardsContract, ) = __decodeUnstakeActionArgs(_actionArgs);

            __validateRewardsContract(rewardsContract);
        } else if (_actionId == uint256(IMapleLiquidityPosition.Actions.UnstakeAndRedeem)) {
            (address pool, address rewardsContract, ) = __decodeUnstakeAndRedeemActionArgs(
                _actionArgs
            );

            __validatePool(pool);
            __validateRewardsContract(rewardsContract);
        } else if (_actionId == uint256(IMapleLiquidityPosition.Actions.ClaimInterest)) {
            address pool = __decodeClaimInterestActionArgs(_actionArgs);

            __validatePool(pool);
        } else if (_actionId == uint256(IMapleLiquidityPosition.Actions.ClaimRewards)) {
            address rewardsContract = __decodeClaimRewardsActionArgs(_actionArgs);

            __validateRewardsContract(rewardsContract);
        }
    }

    // Validates that a pool has been deployed from the Maple pool factory
    function __validatePool(address _pool) private view {
        require(
            IMaplePoolFactory(MAPLE_POOL_FACTORY).isPool(_pool),
            "__validatePool: Invalid pool"
        );
    }

    // Validates that a rewards contract has been deployed from the Maple rewards factory
    function __validateRewardsContract(address _rewardsContract) private view {
        require(
            IMapleMplRewardsFactory(MAPLE_MPL_REWARDS_FACTORY).isMplRewards(_rewardsContract),
            "__validateRewardsContract: Invalid rewards contract"
        );
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

/// @title IMapleRewardsFactory Interface
/// @author Enzyme Council <[email protected]>
interface IMapleMplRewardsFactory {
    function isMplRewards(address) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title IMaplePool Interface
/// @author Enzyme Council <[email protected]>
interface IMaplePool {
    function deposit(uint256) external;

    function increaseCustodyAllowance(address, uint256) external;

    function intendToWithdraw() external;

    function liquidityAsset() external view returns (address);

    function recognizableLossesOf(address) external returns (uint256);

    function withdraw(uint256) external;

    function withdrawFunds() external;

    function withdrawableFundsOf(address) external returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title IMaplePoolFactory Interface
/// @author Enzyme Council <[email protected]>
interface IMaplePoolFactory {
    function isPool(address) external view returns (bool);
}