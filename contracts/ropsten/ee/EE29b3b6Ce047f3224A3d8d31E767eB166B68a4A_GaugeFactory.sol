// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "IGauge.sol";
import "IExtraReward.sol";
import "IGaugeFactory.sol";

/** @title  GaugeFactory
    @notice Creates Gauge and ExtraReward
    @dev Uses clone to create new contracts
 */
contract GaugeFactory is IGaugeFactory {
    address public immutable deployedGauge;
    address public immutable deployedExtra;

    event GaugeCreated(address indexed gauge);
    event ExtraRewardCreated(address indexed extraReward);

    constructor(address _deployedGauge, address _deployedExtra) {
        deployedGauge = _deployedGauge;
        deployedExtra = _deployedExtra;
    }

    /** @notice Create a new reward Gauge clone
        @param _vault the vault address.
        @param _yfi the YFI token address.
        @param _owner owner
        @param _manager manager
        @param _ve veYFI
        @param _veYfiRewardPool veYfi RewardPool
        @return gauge address
    */
    function createGauge(
        address _vault,
        address _yfi,
        address _owner,
        address _manager,
        address _ve,
        address _veYfiRewardPool
    ) external override returns (address) {
        address newGauge = _clone(deployedGauge);
        emit GaugeCreated(newGauge);
        IGauge(newGauge).initialize(
            _vault,
            _yfi,
            _owner,
            _manager,
            _ve,
            _veYfiRewardPool
        );

        return newGauge;
    }

    /** @notice Create ExtraReward clone
        @param _gauge the gauge associated.
        @param _reward The token distributed as a rewards
        @param _owner owner 
        @return ExtraReward address
    */
    function createExtraReward(
        address _gauge,
        address _reward,
        address _owner
    ) external returns (address) {
        address newExtraReward = _clone(deployedExtra);
        emit ExtraRewardCreated(newExtraReward);
        IExtraReward(newExtraReward).initialize(_gauge, _reward, _owner);

        return newExtraReward;
    }

    function _clone(address _source) internal returns (address result) {
        bytes20 targetBytes = bytes20(_source);
        assembly {
            let clone := mload(0x40)
            mstore(
                clone,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(clone, 0x14), targetBytes)
            mstore(
                add(clone, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            result := create(0, clone, 0x37)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;
import "IBaseGauge.sol";

interface IGauge is IBaseGauge {
    function initialize(
        address _stakingToken,
        address _rewardToken,
        address _owner,
        address _rewardManager,
        address _ve,
        address _veYfiRewardPool
    ) external;

    function totalSupply() external view returns (uint256);

    function balanceOf(address _account) external view returns (uint256);

    function boostedBalanceOf(address _account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;
import "IERC20.sol";

interface IBaseGauge {
    function queueNewRewards(uint256 _amount) external returns (bool);

    function rewardToken() external view returns (IERC20);

    function earned(address _account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
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
pragma solidity 0.8.13;
import "IERC20.sol";
import "IBaseGauge.sol";

interface IExtraReward is IBaseGauge {
    function initialize(
        address _gauge,
        address _reward,
        address _owner
    ) external;

    function rewardCheckpoint(address _account) external returns (bool);

    function getRewardFor(address _account) external returns (bool);

    function getReward() external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IGaugeFactory {
    function createGauge(
        address,
        address,
        address,
        address,
        address,
        address
    ) external returns (address);
}