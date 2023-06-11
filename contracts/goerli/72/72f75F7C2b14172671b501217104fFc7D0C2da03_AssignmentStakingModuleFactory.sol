/*
AssignmentStakingModuleFactory

https://github.com/gysr-io/core

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.18;

import "./interfaces/IModuleFactory.sol";
import "./AssignmentStakingModule.sol";

/**
 * @title Assignment staking module factory
 *
 * @notice this factory contract handles deployment for the
 * AssignmentStakingModule contract
 *
 * @dev it is called by the parent PoolFactory and is responsible
 * for parsing constructor arguments before creating a new contract
 */
contract AssignmentStakingModuleFactory is IModuleFactory {
    /**
     * @inheritdoc IModuleFactory
     */
    function createModule(address, bytes calldata)
        external
        override
        returns (address)
    {
        // create module
        AssignmentStakingModule module =
            new AssignmentStakingModule(address(this));
        module.transferOwnership(msg.sender);

        // output
        emit ModuleCreated(msg.sender, address(module));
        return address(module);
    }
}

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
ERC20StakingModule

https://github.com/gysr-io/core

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.18;

import "./interfaces/IStakingModule.sol";
import "./OwnerController.sol";

/**
 * @title Assignment staking module
 *
 * @notice this staking module allows an administrator to set a fixed rate of
 * earnings for a specific user.
 */
contract AssignmentStakingModule is IStakingModule, OwnerController {
    // constant
    uint256 public constant SHARES_COEFF = 1e6;

    // members
    address private immutable _factory;

    uint256 public totalRate;
    mapping(address => uint256) public rates;

    /**
     * @param factory_ address of module factory
     */
    constructor(address factory_) {
        _factory = factory_;
    }

    /**
     * @inheritdoc IStakingModule
     */
    function tokens()
        external
        pure
        override
        returns (address[] memory tokens_)
    {
        tokens_ = new address[](1);
        tokens_[0] = address(0x0);
    }

    /**
     * @inheritdoc IStakingModule
     */
    function balances(
        address user
    ) external view override returns (uint256[] memory balances_) {
        balances_ = new uint256[](1);
        balances_[0] = rates[user];
    }

    /**
     * @inheritdoc IStakingModule
     */
    function factory() external view override returns (address) {
        return _factory;
    }

    /**
     * @inheritdoc IStakingModule
     */
    function totals()
        external
        view
        override
        returns (uint256[] memory totals_)
    {
        totals_ = new uint256[](1);
        totals_[0] = totalRate;
    }

    /**
     * @inheritdoc IStakingModule
     */
    function stake(
        address sender,
        uint256 amount,
        bytes calldata data
    ) external override onlyOwner returns (bytes32, uint256) {
        // validate
        require(amount > 0, "asm1");
        require(sender == controller(), "asm2");
        require(data.length == 32, "asm3");

        address assignee;
        assembly {
            assignee := calldataload(132)
        }

        // increase rate
        rates[assignee] += amount;
        totalRate += amount;

        // emit
        bytes32 account = bytes32(uint256(uint160(assignee)));
        uint256 shares = amount * SHARES_COEFF;
        emit Staked(account, sender, address(0x0), amount, shares);

        return (account, shares);
    }

    /**
     * @inheritdoc IStakingModule
     */
    function unstake(
        address sender,
        uint256 amount,
        bytes calldata data
    ) external override onlyOwner returns (bytes32, address, uint256) {
        // validate
        require(amount > 0, "asm4");
        require(sender == controller(), "asm5");
        require(data.length == 32, "asm6");

        address assignee;
        assembly {
            assignee := calldataload(132)
        }
        uint256 r = rates[assignee];
        require(amount <= r, "asm7");

        // decrease rate
        rates[assignee] = r - amount;
        totalRate -= amount;

        // emit
        bytes32 account = bytes32(uint256(uint160(assignee)));
        uint256 shares = amount * SHARES_COEFF;
        emit Unstaked(account, sender, address(0x0), amount, shares);

        return (account, assignee, shares);
    }

    /**
     * @inheritdoc IStakingModule
     */
    function claim(
        address sender,
        uint256 amount,
        bytes calldata
    ) external override onlyOwner returns (bytes32, address, uint256) {
        require(amount > 0, "asm8");
        require(amount <= rates[sender], "asm9");
        bytes32 account = bytes32(uint256(uint160(sender)));
        uint256 shares = amount * SHARES_COEFF;
        emit Claimed(account, sender, address(0x0), amount, shares);
        return (account, sender, shares);
    }

    /**
     * @inheritdoc IStakingModule
     */
    function update(
        address sender,
        bytes calldata
    ) external pure override returns (bytes32) {
        return (bytes32(uint256(uint160(sender))));
    }

    /**
     * @inheritdoc IStakingModule
     */
    function clean(bytes calldata) external override {}
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
    event Fee(address indexed receiver, address indexed token, uint256 amount);
}

/*
IModuleFactory

https://github.com/gysr-io/core

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.18;

/**
 * @title Module factory interface
 *
 * @notice this defines the common module factory interface used by the
 * main factory to create the staking and reward modules for a new Pool.
 */
interface IModuleFactory {
    // events
    event ModuleCreated(address indexed user, address module);

    /**
     * @notice create a new Pool module
     * @param config address for configuration contract
     * @param data binary encoded construction parameters
     * @return address of newly created module
     */
    function createModule(address config, bytes calldata data)
        external
        returns (address);
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
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
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