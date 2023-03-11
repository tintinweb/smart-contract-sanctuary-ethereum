// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

/*
PoolInfo

https://github.com/gysr-io/core

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.18;

import "../interfaces/IPoolInfo.sol";
import "../interfaces/IPool.sol";
import "../interfaces/IStakingModule.sol";
import "../interfaces/IRewardModule.sol";
import "../interfaces/IStakingModuleInfo.sol";
import "../interfaces/IRewardModuleInfo.sol";
import "../OwnerController.sol";

/**
 * @title Pool info library
 *
 * @notice this implements the Pool info library, which provides read-only
 * convenience functions to query additional information and metadata
 * about the core Pool contract.
 */

contract PoolInfo is IPoolInfo, OwnerController {
    mapping(address => address) public registry;

    /**
     * @inheritdoc IPoolInfo
     */
    function modules(
        address pool
    ) public view override returns (address, address, address, address) {
        IPool p = IPool(pool);
        IStakingModule s = IStakingModule(p.stakingModule());
        IRewardModule r = IRewardModule(p.rewardModule());
        return (address(s), address(r), s.factory(), r.factory());
    }

    /**
     * @notice register factory to info module
     * @param factory address of factory
     * @param info address of info module contract
     */
    function register(address factory, address info) external onlyController {
        registry[factory] = info;
    }

    /**
     * @inheritdoc IPoolInfo
     */
    function rewards(
        address pool,
        address addr,
        bytes calldata stakingdata,
        bytes calldata rewarddata
    ) public view override returns (uint256[] memory rewards_) {
        address stakingModule;
        address rewardModule;
        IStakingModuleInfo stakingModuleInfo;
        IRewardModuleInfo rewardModuleInfo;
        {
            address stakingModuleType;
            address rewardModuleType;
            (
                stakingModule,
                rewardModule,
                stakingModuleType,
                rewardModuleType
            ) = modules(pool);

            stakingModuleInfo = IStakingModuleInfo(registry[stakingModuleType]);
            rewardModuleInfo = IRewardModuleInfo(registry[rewardModuleType]);
        }

        rewards_ = new uint256[](IPool(pool).rewardTokens().length);

        (bytes32[] memory accounts, uint256[] memory shares) = stakingModuleInfo
            .positions(stakingModule, addr, stakingdata);

        for (uint256 i; i < accounts.length; ++i) {
            uint256[] memory r = rewardModuleInfo.rewards(
                rewardModule,
                accounts[i],
                shares[i],
                rewarddata
            );
            for (uint256 j; j < r.length; ++j) rewards_[j] += r[j];
        }
    }
}

/*
IEvents

https://github.com/gysr-io/core

SPDX-License-Identifier: MIT
 */

pragma solidity 0.8.18;

/**
 * @title GYSR event system
 *
 * @notice common interface to define GYSR event system
 */
interface IEvents {
    // staking
    event Staked(
        bytes32 indexed account,
        address indexed user,
        address indexed token,
        uint256 amount,
        uint256 shares
    );
    event Unstaked(
        bytes32 indexed account,
        address indexed user,
        address indexed token,
        uint256 amount,
        uint256 shares
    );
    event Claimed(
        bytes32 indexed account,
        address indexed user,
        address indexed token,
        uint256 amount,
        uint256 shares
    );
    event Updated(bytes32 indexed account, address indexed user);

    // rewards
    event RewardsDistributed(
        address indexed user,
        address indexed token,
        uint256 amount,
        uint256 shares
    );
    event RewardsFunded(
        address indexed token,
        uint256 amount,
        uint256 shares,
        uint256 timestamp
    );
    event RewardsExpired(
        address indexed token,
        uint256 amount,
        uint256 shares,
        uint256 timestamp
    );
    event RewardsWithdrawn(
        address indexed token,
        uint256 amount,
        uint256 shares,
        uint256 timestamp
    );
    event RewardsUpdated(bytes32 indexed account);

    // gysr
    event GysrSpent(address indexed user, uint256 amount);
    event GysrVested(address indexed user, uint256 amount);
    event GysrWithdrawn(uint256 amount);
}

/*
IOwnerController

https://github.com/gysr-io/core

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.18;

/**
 * @title Owner controller interface
 *
 * @notice this defines the interface for any contracts that use the
 * owner controller access pattern
 */
interface IOwnerController {
    /**
     * @dev Returns the address of the current owner.
     */
    function owner() external view returns (address);

    /**
     * @dev Returns the address of the current controller.
     */
    function controller() external view returns (address);

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`). This can
     * include renouncing ownership by transferring to the zero address.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) external;

    /**
     * @dev Transfers control of the contract to a new account (`newController`).
     * Can only be called by the owner.
     */
    function transferControl(address newController) external;
}

/*
IPool

https://github.com/gysr-io/core

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.18;

/**
 * @title Pool interface
 *
 * @notice this defines the core Pool contract interface
 */
interface IPool {
    /**
     * @return staking tokens for Pool
     */
    function stakingTokens() external view returns (address[] memory);

    /**
     * @return reward tokens for Pool
     */
    function rewardTokens() external view returns (address[] memory);

    /**
     * @return staking balances for user
     */
    function stakingBalances(
        address user
    ) external view returns (uint256[] memory);

    /**
     * @return total staking balances for Pool
     */
    function stakingTotals() external view returns (uint256[] memory);

    /**
     * @return reward balances for Pool
     */
    function rewardBalances() external view returns (uint256[] memory);

    /**
     * @return GYSR usage ratio for Pool
     */
    function usage() external view returns (uint256);

    /**
     * @return address of staking module
     */
    function stakingModule() external view returns (address);

    /**
     * @return address of reward module
     */
    function rewardModule() external view returns (address);

    /**
     * @notice stake asset and begin earning rewards
     * @param amount number of tokens to stake
     * @param stakingdata data passed to staking module
     * @param rewarddata data passed to reward module
     */
    function stake(
        uint256 amount,
        bytes calldata stakingdata,
        bytes calldata rewarddata
    ) external;

    /**
     * @notice unstake asset and claim rewards
     * @param amount number of tokens to unstake
     * @param stakingdata data passed to staking module
     * @param rewarddata data passed to reward module
     */
    function unstake(
        uint256 amount,
        bytes calldata stakingdata,
        bytes calldata rewarddata
    ) external;

    /**
     * @notice claim rewards without unstaking
     * @param amount number of tokens to claim against
     * @param stakingdata data passed to staking module
     * @param rewarddata data passed to reward module
     */
    function claim(
        uint256 amount,
        bytes calldata stakingdata,
        bytes calldata rewarddata
    ) external;

    /**
     * @notice method called ad hoc to update user accounting
     * @param stakingdata data passed to staking module
     * @param rewarddata data passed to reward module
     */
    function update(
        bytes calldata stakingdata,
        bytes calldata rewarddata
    ) external;

    /**
     * @notice method called ad hoc to clean up and perform additional accounting
     * @param stakingdata data passed to staking module
     * @param rewarddata data passed to reward module
     */
    function clean(
        bytes calldata stakingdata,
        bytes calldata rewarddata
    ) external;

    /**
     * @return gysr balance available for withdrawal
     */
    function gysrBalance() external view returns (uint256);

    /**
     * @notice withdraw GYSR tokens applied during unstaking
     * @param amount number of GYSR to withdraw
     */
    function withdraw(uint256 amount) external;

    /**
     * @notice transfer control of the staking module to another account
     * @param newController address of new controller
     */
    function transferControlStakingModule(address newController) external;

    /**
     * @notice transfer control of the reward module to another account
     * @param newController address of new controller
     */
    function transferControlRewardModule(address newController) external;

    /**
     * @notice execute multiple operations in a single call
     * @param data array of encoded function data
     */
    function multicall(
        bytes[] calldata data
    ) external returns (bytes[] memory results);
}

/*
IPoolInfo

https://github.com/gysr-io/core

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.18;

/**
 * @title Pool info interface
 *
 * @notice this defines the Pool info contract interface
 */

interface IPoolInfo {
    /**
     * @notice get information about the underlying staking and reward modules
     * @param pool address of Pool contract
     * @return staking module address
     * @return reward module address
     * @return staking module type
     * @return reward module type
     */
    function modules(
        address pool
    ) external view returns (address, address, address, address);

    /**
     * @notice get pending rewards for arbitrary Pool and user pair
     * @param pool address of Pool contract
     * @param addr address of user for preview
     * @param stakingdata additional data passed to staking module info library
     * @param rewarddata additional data passed to reward module info library
     */
    function rewards(
        address pool,
        address addr,
        bytes calldata stakingdata,
        bytes calldata rewarddata
    ) external view returns (uint256[] memory);
}

/*
IRewardModule

https://github.com/gysr-io/core

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./IEvents.sol";
import "./IOwnerController.sol";

/**
 * @title Reward module interface
 *
 * @notice this contract defines the common interface that any reward module
 * must implement to be compatible with the modular Pool architecture.
 */
interface IRewardModule is IOwnerController, IEvents {
    /**
     * @return array of reward tokens
     */
    function tokens() external view returns (address[] memory);

    /**
     * @return array of reward token balances
     */
    function balances() external view returns (uint256[] memory);

    /**
     * @return GYSR usage ratio for reward module
     */
    function usage() external view returns (uint256);

    /**
     * @return address of module factory
     */
    function factory() external view returns (address);

    /**
     * @notice perform any necessary accounting for new stake
     * @param account bytes32 id of staking account
     * @param sender address of sender
     * @param shares number of new shares minted
     * @param data addtional data
     * @return amount of gysr spent
     * @return amount of gysr vested
     */
    function stake(
        bytes32 account,
        address sender,
        uint256 shares,
        bytes calldata data
    ) external returns (uint256, uint256);

    /**
     * @notice reward user and perform any necessary accounting for unstake
     * @param account bytes32 id of staking account
     * @param sender address of sender
     * @param receiver address of reward receiver
     * @param shares number of shares burned
     * @param data additional data
     * @return amount of gysr spent
     * @return amount of gysr vested
     */
    function unstake(
        bytes32 account,
        address sender,
        address receiver,
        uint256 shares,
        bytes calldata data
    ) external returns (uint256, uint256);

    /**
     * @notice reward user and perform and necessary accounting for existing stake
     * @param account bytes32 id of staking account
     * @param sender address of sender
     * @param receiver address of reward receiver
     * @param shares number of shares being claimed against
     * @param data additional data
     * @return amount of gysr spent
     * @return amount of gysr vested
     */
    function claim(
        bytes32 account,
        address sender,
        address receiver,
        uint256 shares,
        bytes calldata data
    ) external returns (uint256, uint256);

    /**
     * @notice method called by anyone to update accounting
     * @dev will only be called ad hoc and should not contain essential logic
     * @param account bytes32 id of staking account for update
     * @param sender address of sender
     * @param data additional data
     */
    function update(
        bytes32 account,
        address sender,
        bytes calldata data
    ) external;

    /**
     * @notice method called by owner to clean up and perform additional accounting
     * @dev will only be called ad hoc and should not contain any essential logic
     * @param data additional data
     */
    function clean(bytes calldata data) external;
}

/*
IRewardModuleInfo

https://github.com/gysr-io/core

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.18;

/**
 * @title Reward module info interface
 *
 * @notice this contract defines the common interface that any reward module info
 * must implement to be compatible with the modular Pool architecture.
 */

interface IRewardModuleInfo {
    /**
     * @notice get all token metadata
     * @param module address of reward module
     * @return addresses
     * @return names
     * @return symbols
     * @return decimals
     */
    function tokens(
        address module
    )
        external
        view
        returns (
            address[] memory,
            string[] memory,
            string[] memory,
            uint8[] memory
        );

    /**
     * @notice generic function to get pending reward balances
     * @param module address of reward module
     * @param account bytes32 account of interest for preview
     * @param shares number of shares that would be used
     * @param data additional encoded data
     * @return estimated reward balances
     */
    function rewards(
        address module,
        bytes32 account,
        uint256 shares,
        bytes calldata data
    ) external view returns (uint256[] memory);
}

/*
IStakingModule

https://github.com/gysr-io/core

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./IEvents.sol";
import "./IOwnerController.sol";

/**
 * @title Staking module interface
 *
 * @notice this contract defines the common interface that any staking module
 * must implement to be compatible with the modular Pool architecture.
 */
interface IStakingModule is IOwnerController, IEvents {
    /**
     * @return array of staking tokens
     */
    function tokens() external view returns (address[] memory);

    /**
     * @notice get balance of user
     * @param user address of user
     * @return balances of each staking token
     */
    function balances(address user) external view returns (uint256[] memory);

    /**
     * @return address of module factory
     */
    function factory() external view returns (address);

    /**
     * @notice get total staked amount
     * @return totals for each staking token
     */
    function totals() external view returns (uint256[] memory);

    /**
     * @notice stake an amount of tokens for user
     * @param sender address of sender
     * @param amount number of tokens to stake
     * @param data additional data
     * @return bytes32 id of staking account
     * @return number of shares minted for stake
     */
    function stake(
        address sender,
        uint256 amount,
        bytes calldata data
    ) external returns (bytes32, uint256);

    /**
     * @notice unstake an amount of tokens for user
     * @param sender address of sender
     * @param amount number of tokens to unstake
     * @param data additional data
     * @return bytes32 id of staking account
     * @return address of reward receiver
     * @return number of shares burned for unstake
     */
    function unstake(
        address sender,
        uint256 amount,
        bytes calldata data
    ) external returns (bytes32, address, uint256);

    /**
     * @notice quote the share value for an amount of tokens without unstaking
     * @param sender address of sender
     * @param amount number of tokens to claim with
     * @param data additional data
     * @return bytes32 id of staking account
     * @return address of reward receiver
     * @return number of shares that the claim amount is worth
     */
    function claim(
        address sender,
        uint256 amount,
        bytes calldata data
    ) external returns (bytes32, address, uint256);

    /**
     * @notice method called by anyone to update accounting
     * @dev will only be called ad hoc and should not contain essential logic
     * @param sender address of user for update
     * @param data additional data
     * @return bytes32 id of staking account
     */
    function update(
        address sender,
        bytes calldata data
    ) external returns (bytes32);

    /**
     * @notice method called by owner to clean up and perform additional accounting
     * @dev will only be called ad hoc and should not contain any essential logic
     * @param data additional data
     */
    function clean(bytes calldata data) external;
}

/*
IStakingModuleInfo

https://github.com/gysr-io/core

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.18;

/**
 * @title Staking module info interface
 *
 * @notice this contract defines the common interface that any staking module info
 * must implement to be compatible with the modular Pool architecture.
 */
interface IStakingModuleInfo {
    /**
     * @notice convenience function to get all token metadata in a single call
     * @param module address of staking module
     * @return addresses
     * @return names
     * @return symbols
     * @return decimals
     */
    function tokens(
        address module
    )
        external
        view
        returns (
            address[] memory,
            string[] memory,
            string[] memory,
            uint8[] memory
        );

    /**
     * @notice get all staking positions for user
     * @param module address of staking module
     * @param addr user address of interest
     * @param data additional encoded data
     * @return accounts_
     * @return shares_
     */
    function positions(
        address module,
        address addr,
        bytes calldata data
    ) external view returns (bytes32[] memory, uint256[] memory);
}

/*
OwnerController

https://github.com/gysr-io/core

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.18;

import "./interfaces/IOwnerController.sol";

/**
 * @title Owner controller
 *
 * @notice this base contract implements an owner-controller access model.
 *
 * @dev the contract is an adapted version of the OpenZeppelin Ownable contract.
 * It allows the owner to designate an additional account as the controller to
 * perform restricted operations.
 *
 * Other changes include supporting role verification with a require method
 * in addition to the modifier option, and removing some unneeded functionality.
 *
 * Original contract here:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol
 */
contract OwnerController is IOwnerController {
    address private _owner;
    address private _controller;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    event ControlTransferred(
        address indexed previousController,
        address indexed newController
    );

    constructor() {
        _owner = msg.sender;
        _controller = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
        emit ControlTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view override returns (address) {
        return _owner;
    }

    /**
     * @dev Returns the address of the current controller.
     */
    function controller() public view override returns (address) {
        return _controller;
    }

    /**
     * @dev Modifier that throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == msg.sender, "oc1");
        _;
    }

    /**
     * @dev Modifier that throws if called by any account other than the controller.
     */
    modifier onlyController() {
        require(_controller == msg.sender, "oc2");
        _;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    function requireOwner() internal view {
        require(_owner == msg.sender, "oc1");
    }

    /**
     * @dev Throws if called by any account other than the controller.
     */
    function requireController() internal view {
        require(_controller == msg.sender, "oc2");
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`). This can
     * include renouncing ownership by transferring to the zero address.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override {
        requireOwner();
        require(newOwner != address(0), "oc3");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    /**
     * @dev Transfers control of the contract to a new account (`newController`).
     * Can only be called by the owner.
     */
    function transferControl(address newController) public virtual override {
        requireOwner();
        require(newController != address(0), "oc4");
        emit ControlTransferred(_controller, newController);
        _controller = newController;
    }
}