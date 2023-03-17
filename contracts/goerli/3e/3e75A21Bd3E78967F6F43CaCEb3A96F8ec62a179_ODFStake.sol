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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../contracts/access/Ownable.sol";

contract $Ownable is Ownable {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor(address owner_) Ownable(owner_) {}

    function $_checkOwner() external view {
        super._checkOwner();
    }

    function $_transferOwnership(address newOwner) external {
        super._transferOwnership(newOwner);
    }

    function $_msgSender() external view returns (address ret0) {
        (ret0) = super._msgSender();
    }

    function $_msgData() external view returns (bytes memory ret0) {
        (ret0) = super._msgData();
    }

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../contracts/interfaces/IODFStake.sol";

contract $IODFStake is IODFStake {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() {}

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../contracts/interfaces/IODFToken.sol";

abstract contract $IODFToken is IODFToken {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() {}

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../contracts/ODFStake.sol";

contract $ODFStake is ODFStake {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor(address stakingToken_, uint256 rewardRate_, address owner_) ODFStake(stakingToken_, rewardRate_, owner_) {}

    function $_checkOwner() external view {
        super._checkOwner();
    }

    function $_transferOwnership(address newOwner) external {
        super._transferOwnership(newOwner);
    }

    function $_msgSender() external view returns (address ret0) {
        (ret0) = super._msgSender();
    }

    function $_msgData() external view returns (bytes memory ret0) {
        (ret0) = super._msgData();
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/Context.sol';

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor(address owner_) {
        _transferOwnership(owner_);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), 'Ownable: caller is not the owner');
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            'Ownable: new owner is the zero address'
        );
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface IODFStake {
    /**
     * @notice Error to revert when amount is under or over the limit.
     */
    error InvalidAmount();

    /**
     * @notice Error to revert when account has not staked.
     */
    error NotStaked();

    /**
     * @notice Error to revert when period is under or over the limit.
     */
    error InvalidPeriod();

    /**
     * @notice Event to emit when a stake is created.
     */
    event Staked(
        address indexed account,
        uint256 id,
        uint256 amount,
        uint256 period
    );

    /**
     * @notice Event to emit when a stake is removed.
     */
    event UnStaked(address indexed account, uint256 id, uint256 amount);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IODFToken is IERC20 {
    function mint(address receiver_, uint256 amount_) external;

    function burn(address receiver_, uint256 amount_) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import '@openzeppelin/contracts/utils/Counters.sol';
import './interfaces/IODFStake.sol';
import './interfaces/IODFToken.sol';
import './access/Ownable.sol';

contract ODFStake is IODFStake, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _stakingCounter;
    /**
     * @notice Minimum amount of tokens to stake.
     */
    uint256 public constant MIN_AMOUNT = 1000 ether;
    uint256 public constant MAX_AMOUNT = 1000000 ether;

    /**
     * @notice Minimum and maximum period to lock tokens given in days.
     */
    uint16 public constant MIN_LOCK_PERIOD = 14;
    uint16 public constant MAX_LOCK_PERIOD = 730;

    /**
     * @notice Save the address of the token to stake as an instance of IERC20.
     */
    IODFToken public immutable stakingToken;

    /**
     * @notice Reward tokens earn for each token staked in a period of one year.
     */
    uint256 public rewardRate;

    /**
     * @notice Struct to save the data of a stake.
     */
    struct Stake {
        uint256 amount;
        uint256 period;
        uint256 timestamp;
        address account;
    }

    /**
     * @notice Mapping to save the stakes.
     * @dev The id is the key of the mapping.
     * ID => Stake
     */
    mapping(uint256 => Stake) public stakes;

    /**
     * @notice Start staking contract and ERC20 used as rewards.
     * @param stakingToken_ Address of token to stake in this smart contract.
     * @param rewardRate_ The rewards get for token each year.
     */
    constructor(
        address stakingToken_,
        uint256 rewardRate_,
        address owner_
    ) Ownable(owner_) {
        stakingToken = IODFToken(stakingToken_);
        rewardRate = rewardRate_;
    }

    /**
     * @notice Save tokens to start accumulating rewards.
     * @dev The smart contract's address must have enough allowance in ERC20.
     * @param amount_ Amount of tokens for staking
     */
    function stake(uint256 amount_, uint16 _period) external {
        if (amount_ < MIN_AMOUNT) {
            revert InvalidAmount();
        }
        if (amount_ > MAX_AMOUNT) {
            revert InvalidAmount();
        }
        if (_period < MIN_LOCK_PERIOD || _period > MAX_LOCK_PERIOD) {
            revert InvalidPeriod();
        }
        stakingToken.transferFrom(msg.sender, address(this), amount_);
        _stakingCounter.increment();
        uint256 id = _stakingCounter.current();

        Stake memory data = Stake(
            amount_,
            (uint256(_period) * 1 days),
            block.timestamp,
            msg.sender
        );
        stakes[id] = data;
        emit Staked(msg.sender, id, amount_, _period);
    }

    /**
     * @notice Calculate rewards for a stake.
     * @param id_ Id of the stake.
     */
    function getRewards(uint256 id_) public view returns (uint256 rewards) {
        Stake memory stake_ = stakes[id_];
        rewards =
            (((stake_.period * rewardRate) / 100) * stake_.amount) /
            365 days;
    }

    /**
     * @notice Withdraw tokens and rewards.
     * @param id_ Id of the stake.
     */
    function unStake(uint256 id_) external {
        Stake memory stake_ = stakes[id_];
        if (stake_.account != msg.sender) {
            revert NotStaked();
        }

        if (block.timestamp < stake_.timestamp + stake_.period) {
            revert InvalidPeriod();
        }

        uint256 amount = stake_.amount;
        uint256 rewards = getRewards(id_);
        stakingToken.mint(msg.sender, rewards);
        stakingToken.transfer(msg.sender, amount);
        delete stakes[id_];
        emit UnStaked(msg.sender, id_, amount);
    }

    /**
     * @notice Change rewards rate.
     * WARNING: CHANGE THIS VARIABLE IS GOING TO AFFECT THE REWARDS THAT HAVE NOT BEEN SAVED
     * EXECUTING "updateRewards", TAKING THE NEW VALUE AS PARAMETER TO CALCULATE THE E
     * @param rate_ Amount of tokens earn per token each year.
     */
    function setRewardsRate(uint256 rate_) external onlyOwner {
        rewardRate = rate_;
    }

    /**
     * @notice Get all stakes.
     * @dev This function is used to get all stakes in the frontend.
     * @dev Avoid using this function in the smart contract, it can spend a lot of
     * fees depending in the amount of stakes.
     * @return stakes_ Array of stakes.
     */
    function getStakes() external view returns (Stake[] memory) {
        uint256 total = _stakingCounter.current();
        uint256 stakeCount;
        for (uint256 i = total; i > 0; ) {
            if (stakes[i].account != address(0)) {
                stakeCount++;
            }

            unchecked {
                i--;
            }
        }

        Stake[] memory stakes_ = new Stake[](stakeCount);

        for (uint256 i = total; i > 0; ) {
            if (stakes[i].account != address(0)) {
                stakes_[stakeCount - 1] = stakes[i];
                unchecked {
                    stakeCount--;
                }
            }

            unchecked {
                i--;
            }
        }
        return stakes_;
    }

    /**
     * @notice Get all stakes of an account.
     * @dev This function is used to get all stakes of an account in the frontend.
     * @dev Avoid using this function in the smart contract, it can spend a lot of
     * fees depending in the amount of stakes.
     * @param account Address of the account.
     * @return stakes_ Array of stakes.
     */
    function getUserStakes(
        address account
    ) external view returns (Stake[] memory) {
        uint256 total = _stakingCounter.current();
        uint256 stakeCount;
        for (uint256 i = total; i > 0; ) {
            if (stakes[i].account == account) {
                stakeCount++;
            }

            unchecked {
                i--;
            }
        }

        Stake[] memory stakes_ = new Stake[](stakeCount);

        for (uint256 i = total; i > 0; ) {
            if (stakes[i].account == account) {
                stakes_[stakeCount - 1] = stakes[i];
                unchecked {
                    stakeCount--;
                }
            }

            unchecked {
                i--;
            }
        }
        return stakes_;
    }
}