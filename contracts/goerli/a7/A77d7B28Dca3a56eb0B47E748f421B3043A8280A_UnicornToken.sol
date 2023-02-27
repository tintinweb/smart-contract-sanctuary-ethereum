// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
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
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
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

pragma solidity ^0.8.4;

interface IUnicornRewards {
    function lastTimeRewardApplicable() external view returns (uint256);

    function rewardPerToken() external view returns (uint256);

    function stake(address _account) external;

    function unstake(address _account) external;

    function earned(address _account) external view returns (uint256);

    function getReward() external;

    function notifyRewardAmount(uint256 _amount) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./IVotingInitialize.sol";

interface IVotingFactory is IVotingInitialize {
    function createVoting(
        VotingVariants _typeVoting,
        bytes memory _voteDescription,
        uint256 _duration,
        uint256 _qtyVoters,
        uint256 _minPercentageVoters,
        address _applicant
    ) external;

    function getVotingInstancesLength() external view returns (uint256);

    function isVotingInstance(address instance) external view returns (bool);

    event CreateVoting(
        address indexed instanceAddress,
        VotingVariants indexed instanceType
    );
    event SetMasterVoting(
        address indexed previousContract,
        address indexed newContract
    );
    event SetMasterVotingAllowList(
        address indexed previousContract,
        address indexed newContract
    );
    event SetVotingTokenRate(
        uint256 indexed previousRate,
        uint256 indexed newRate
    );
    event SetCreateProposalRate(
        uint256 indexed previousRate,
        uint256 indexed newRate
    );
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IVotingInitialize {
    enum VotingVariants {
        UNICORNADDING,
        UNICORNREMOVAL,
        CHARITY
    }

    struct Params {
        bytes description;
        uint256 start;
        uint256 qtyVoters;
        uint256 minPercentageVoters;
        uint256 minQtyVoters;
        uint256 duration;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IUnicornRewards.sol";
import "./interfaces/IVotingFactory.sol";

/// @notice SoulBound token
contract UnicornToken is Ownable {
    /// @notice Name of the token
    string private name;

    /// @notice Symbol of the token
    string private symbol;

    /// @notice Shows if contract is initialized
    bool private isInit;

    /// @notice VotingFactory instance
    IVotingFactory public votingAddress;

    /// @notice UnicornRewards instance
    IUnicornRewards public unicornRewards;

    /// @notice Mappint (address => bool). Shows if user is Unicorn
    mapping(address => bool) private isUnicorn;

    /// @notice Array of all Unicorns
    address[] private unicorns;

    /// @notice Indicates that unicorn status was granted
    /// @param to Account of new Unicorn
    event unicornStatusGranted(address to);

    /// @notice Indicates that unicorn status was removed
    /// @param from Account of removed Unicorn
    event unicornStatusRemoved(address from);


    /// @notice Checks if caller is Voting instance
    modifier onlyVoting() {
        require(
            votingAddress.isVotingInstance(msg.sender),
            "UnicornToken: caller in not a Voting!"
        );
        _;
    }

    /// @notice Checks if init method was called only once
    modifier onlyOnce() {
        require(!isInit, "UnicornToken: Already initialized!");
        _;
    }

    /// @param name_ Name of the token
    /// @param symbol_ Symbol of the token
    /// @param votingAddress_ Address of VotingFactory contract
    /// @param unicornRewards_ Address of UnicornRewards contract
    constructor(
        string memory name_,
        string memory symbol_,
        address votingAddress_,
        address unicornRewards_
    ) {
        name = name_;
        symbol = symbol_;
        votingAddress = IVotingFactory(votingAddress_);
        unicornRewards = IUnicornRewards(unicornRewards_);
        isInit = false;
    }


    /// @notice Sets first Unicorn (Owner)
    /**
    @dev This method can be called only by an Owner of the contract.
    This method can be called only once
    **/
    function init(address user) external onlyOnce onlyOwner {
        isInit = true;
        isUnicorn[user] = true;
        unicorns.push(user);
        unicornRewards.stake(user);
        emit unicornStatusGranted(user);
    }

    /// @notice Returns Unicorn status
    /// @param user Account to check
    /// @return bool True - user is Unicorn, False - User is not a Unicorn
    function getIsUnicorn(address user) external view returns (bool) {
        return isUnicorn[user];
    }

    /// @notice Returns all Unicorns
    /// @return addresses Array of Unicorns addresses
    function getAllUnicorns() external view returns (address[] memory) {
        return unicorns;
    }

    /// @notice Returns total amount of Unicorns
    /// @return amount Total amount of Unicorns
    function getUnicornsLength() external view returns (uint256) {
        return unicorns.length;
    }

    /// @notice Grants Unicorn status to targeted account
    /// @param to Targeted account
    /** 
    @dev This method can be called only by a Voting Inctance
    User can have only one Unicorn token
    **/ 
    function mint(address to) external onlyVoting {
        require(isUnicorn[to] == false, "UnicornToken: already Unicorn!");
        isUnicorn[to] = true;
        unicorns.push(to);
        unicornRewards.stake(to);
        emit unicornStatusGranted(to);
    }

    /// @notice Removes Unicorn status to targeted account
    /// @param from Targeted account
    /** 
    @dev This method can be called only by a Voting Inctance
    **/ 
    function burn(address from) external onlyVoting {
        require(
            isUnicorn[from] == true,
            "UnicornToken: user is not a Unicorn!"
        );
        unicornRewards.unstake(from);
        isUnicorn[from] = false;
        for (uint256 i = 0; i < unicorns.length; i++) {
            if (unicorns[i] == from) {
                unicorns[i] = unicorns[unicorns.length - 1];
                unicorns.pop();
                break;
            }
        }
        emit unicornStatusRemoved(from);
    }
}