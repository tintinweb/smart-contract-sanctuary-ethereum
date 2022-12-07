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
        DEPRECATED_LendV1,
        DEPRECATED_LendAndStakeV1,
        DEPRECATED_IntendToRedeemV1,
        DEPRECATED_RedeemV1,
        DEPRECATED_StakeV1,
        DEPRECATED_UnstakeV1,
        DEPRECATED_UnstakeAndRedeemV1,
        DEPRECATED_ClaimInterestV1,
        ClaimRewardsV1,
        LendV2,
        RequestRedeemV2,
        RedeemV2,
        CancelRedeemV2
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
    ////////////////
    // V1 ACTIONS //
    ////////////////

    /// @dev Helper to decode args used during the ClaimRewardsV1 action
    function __decodeClaimRewardsV1ActionArgs(bytes memory _actionArgs)
        internal
        pure
        returns (address rewardsContract_)
    {
        return abi.decode(_actionArgs, (address));
    }

    ////////////////
    // V2 ACTIONS //
    ////////////////

    /// @dev Helper to decode args used during the CancelRedeemV2 action
    function __decodeCancelRedeemV2ActionArgs(bytes memory _actionArgs)
        internal
        pure
        returns (address pool_, uint256 poolTokenAmount_)
    {
        return abi.decode(_actionArgs, (address, uint256));
    }

    /// @dev Helper to decode args used during the LendV2 action
    function __decodeLendV2ActionArgs(bytes memory _actionArgs)
        internal
        pure
        returns (address pool_, uint256 liquidityAssetAmount_)
    {
        return abi.decode(_actionArgs, (address, uint256));
    }

    /// @dev Helper to decode args used during the RedeemV2 action
    function __decodeRedeemV2ActionArgs(bytes memory _actionArgs)
        internal
        pure
        returns (address pool_, uint256 poolTokenAmount_)
    {
        return abi.decode(_actionArgs, (address, uint256));
    }

    /// @dev Helper to decode args used during the RequestRedeemV2 action
    function __decodeRequestRedeemV2ActionArgs(bytes memory _actionArgs)
        internal
        pure
        returns (address pool_, uint256 poolTokenAmount_)
    {
        return abi.decode(_actionArgs, (address, uint256));
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

import "../../../../interfaces/IMapleV1MplRewardsFactory.sol";
import "../../../../interfaces/IMapleV2Globals.sol";
import "../../../../interfaces/IMapleV2Pool.sol";
import "../../../../interfaces/IMapleV2PoolManager.sol";
import "../../../../interfaces/IMapleV2ProxyFactory.sol";
import "../IExternalPositionParser.sol";
import "./IMapleLiquidityPosition.sol";
import "./MapleLiquidityPositionDataDecoder.sol";

pragma solidity 0.6.12;

/// @title MapleLiquidityPositionParser
/// @author Enzyme Council <[email protected]>
/// @notice Parser for Maple liquidity positions
contract MapleLiquidityPositionParser is
    MapleLiquidityPositionDataDecoder,
    IExternalPositionParser
{
    address private immutable MAPLE_V1_MPL_REWARDS_FACTORY;
    address private immutable MAPLE_V2_GLOBALS;

    constructor(address _mapleV2Globals, address _mapleV1MplRewardsFactory) public {
        MAPLE_V1_MPL_REWARDS_FACTORY = _mapleV1MplRewardsFactory;
        MAPLE_V2_GLOBALS = _mapleV2Globals;
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
        if (_actionId == uint256(IMapleLiquidityPosition.Actions.LendV2)) {
            (address pool, uint256 liquidityAssetAmount) = __decodeLendV2ActionArgs(
                _encodedActionArgs
            );
            __validatePoolV2(pool);

            assetsToTransfer_ = new address[](1);
            amountsToTransfer_ = new uint256[](1);

            assetsToTransfer_[0] = IMapleV2Pool(pool).asset();
            amountsToTransfer_[0] = liquidityAssetAmount;
        } else if (_actionId == uint256(IMapleLiquidityPosition.Actions.RequestRedeemV2)) {
            (address pool, ) = __decodeRequestRedeemV2ActionArgs(_encodedActionArgs);
            __validatePoolV2(pool);
        } else if (_actionId == uint256(IMapleLiquidityPosition.Actions.RedeemV2)) {
            (address pool, ) = __decodeRedeemV2ActionArgs(_encodedActionArgs);
            __validatePoolV2(pool);

            assetsToReceive_ = new address[](1);
            assetsToReceive_[0] = IMapleV2Pool(pool).asset();
        } else if (_actionId == uint256(IMapleLiquidityPosition.Actions.CancelRedeemV2)) {
            (address pool, ) = __decodeCancelRedeemV2ActionArgs(_encodedActionArgs);
            __validatePoolV2(pool);
        } else if (_actionId == uint256(IMapleLiquidityPosition.Actions.ClaimRewardsV1)) {
            address rewardsContract = __decodeClaimRewardsV1ActionArgs(_encodedActionArgs);
            __validateRewardsContract(rewardsContract);
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

    // Validates that a pool v2 has been deployed from a Maple factory
    function __validatePoolV2(address _poolV2) private view {
        address poolManager = IMapleV2Pool(_poolV2).manager();
        require(
            IMapleV2PoolManager(poolManager).pool() == _poolV2,
            "__validatePoolV2: Invalid PoolManager relation"
        );

        address poolManagerFactory = IMapleV2PoolManager(poolManager).factory();
        require(
            IMapleV2ProxyFactory(poolManagerFactory).isInstance(poolManager),
            "__validatePoolV2: Invalid PoolManagerFactory relation"
        );

        require(
            IMapleV2Globals(MAPLE_V2_GLOBALS).isFactory("POOL_MANAGER", poolManagerFactory),
            "__validatePoolV2: Invalid Globals relation"
        );
    }

    // Validates that a rewards contract has been deployed from the Maple rewards factory
    function __validateRewardsContract(address _rewardsContract) private view {
        require(
            IMapleV1MplRewardsFactory(MAPLE_V1_MPL_REWARDS_FACTORY).isMplRewards(_rewardsContract),
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

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title IERC4626 Interface
/// @author Enzyme Council <[email protected]>
/// @notice Minimal interface for interactions with IERC4626 tokens
interface IERC4626 is IERC20 {
    function asset() external view returns (address asset_);

    function deposit(uint256 _assets, address _receiver) external returns (uint256 shares_);

    function mint(uint256 shares_, address _receiver) external returns (uint256 assets_);

    function redeem(
        uint256 _shares,
        address _receiver,
        address _owner
    ) external returns (uint256 assets_);

    function withdraw(
        uint256 _assets,
        address _receiver,
        address _owner
    ) external returns (uint256 shares_);

    function convertToAssets(uint256 _shares) external view returns (uint256 assets_);

    function convertToShares(uint256 _assets) external view returns (uint256 shares_);

    function maxDeposit(address _receiver) external view returns (uint256 assets_);

    function maxMint(address _receiver) external view returns (uint256 shares_);

    function maxRedeem(address _owner) external view returns (uint256 shares_);

    function maxWithdraw(address _owner) external view returns (uint256 _assets);

    function previewDeposit(uint256 _assets) external view returns (uint256 shares_);

    function previewMint(uint256 _shares) external view returns (uint256 assets_);

    function previewRedeem(uint256 _shares) external view returns (uint256 assets_);

    function previewWithdraw(uint256 _assets) external view returns (uint256 shares_);

    function totalAssets() external view returns (uint256 totalAssets_);
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
interface IMapleV1MplRewardsFactory {
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

/// @title IMapleV2Globals Interface
/// @author Enzyme Council <[email protected]>
interface IMapleV2Globals {
    function isFactory(bytes32 _key, address _who) external view returns (bool isFactory_);
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/
import "./IERC4626.sol";

pragma solidity 0.6.12;

/// @title IMapleV2Pool Interface
/// @author Enzyme Council <[email protected]>
interface IMapleV2Pool is IERC4626 {
    function convertToExitAssets(uint256 _shares) external view returns (uint256 assets_);

    function removeShares(uint256 _shares, address _owner) external;

    function requestRedeem(uint256 _shares, address _owner) external;

    function manager() external view returns (address poolManager_);
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title IMapleV2PoolManager Interface
/// @author Enzyme Council <[email protected]>
interface IMapleV2PoolManager {
    function factory() external view returns (address factory_);

    function pool() external view returns (address pool_);

    function withdrawalManager() external view returns (address withdrawalManager_);
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title IMapleV2ProxyFactory Interface
/// @author Enzyme Council <[email protected]>
interface IMapleV2ProxyFactory {
    function isInstance(address instance_) external view returns (bool isInstance_);
}