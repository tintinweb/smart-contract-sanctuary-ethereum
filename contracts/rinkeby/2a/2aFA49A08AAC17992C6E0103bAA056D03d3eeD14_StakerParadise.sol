// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

//  __  __  _____        ______ _     ___ 
// |  \/  |/ _ \ \      / / ___| |   |_ _|
// | |\/| | | | \ \ /\ / / |  _| |    | | 
// | |  | | |_| |\ V  V /| |_| | |___ | | 
// |_|  |_|\___/  \_/\_/  \____|_____|___|
// ``````````````````````````````` investmentPool = IVP````````````````````````
contract StakerParadise is Ownable {
    // --------------------- Var --------------------

    mapping(uint256 => IVP) private idToIVP;
    mapping(address => mapping(uint256 => uint256)) public userBalanceInPool;
    mapping(address => uint256) public userRewards;

    uint256 private IVPids = 1;
    IERC20 public SPT;

    struct IVP {
        uint256 id;
        address tokenAddress; //
        uint256 maxSupply; // max total can be staked in this pool
        uint256 depositTime; // how much days after creation
        uint256 minDeposit;
        uint256 amountOfTokenReward;
        uint256 currentBalance;
        uint256 stakeTime; // in days
        address[] stakers;
        uint256 createdAt;
    }

    // --------------------------- Events ------------------------

    event PoolCreated(uint256 indexed poolId, uint256 indexed createdAt);
    event NewStaker(uint256 indexed poolId, address indexed userAddress);
    event Unstaked(uint256 indexed poolId, address indexed userAddress);
    event Claimed(address indexed user);

    constructor(address spt_token_address) {
        SPT = IERC20(spt_token_address);
    }

    //                                  Main Functions

    // create an investment pool only owner can do it
    function createInvestmentPool(
        address _tokenAddress,
        uint256 _maxSupply,
        uint256 _depositTime,
        uint256 _minDeposit,
        uint256 _amountOfTokenReward,
        uint256 _stakeTime
    ) external onlyOwner {
        uint256 currentId = IVPids;
        IVPids += 1; // increment ids
        // fill the pool
        idToIVP[currentId].id = currentId;
        idToIVP[currentId].tokenAddress = _tokenAddress;
        idToIVP[currentId].maxSupply = _maxSupply;
        idToIVP[currentId].depositTime = _depositTime;
        idToIVP[currentId].minDeposit = _minDeposit;
        idToIVP[currentId].amountOfTokenReward = _amountOfTokenReward;
        idToIVP[currentId].stakeTime = _stakeTime;
        idToIVP[currentId].createdAt = block.timestamp;
        SPT.transferFrom(
            msg.sender,
            address(this),
            _amountOfTokenReward * 10**18
        );
        emit PoolCreated(currentId, block.timestamp);
    }

    // user can stake the token allowed on the pool

    function stake(uint256 _IVPid, uint256 _amount) external {
        IVP memory ivp = idToIVP[_IVPid];

        require(
            IERC20(ivp.tokenAddress).balanceOf(msg.sender) >= _amount * 10**18,
            "not enough"
        ); // user must hold the amount he wanna stake it
        require(_amount >= ivp.minDeposit, "mini entry"); // user should respect the mini entry amount
        require((_amount + ivp.currentBalance) <= ivp.maxSupply, "over amount"); // user should respect the max amount of the pool

        
        require(
            ivp.createdAt + ivp.depositTime * 1 days >= block.timestamp,
            "too late"
        ); // user should respect the deposit time

        // check if user if already staker
        if (isUserStaker(msg.sender, _IVPid) == false) {
            idToIVP[_IVPid].stakers.push(msg.sender);
        }
        idToIVP[_IVPid].currentBalance += _amount;
        userBalanceInPool[msg.sender][_IVPid] += _amount;

        IERC20(ivp.tokenAddress).transferFrom(
            msg.sender,
            address(this),
            _amount * 10**18
        );
        emit NewStaker(_IVPid, msg.sender);
    }

    function unstake(uint256 _IVPid) external {
        IVP memory ivp = idToIVP[_IVPid];

        require(
            (ivp.createdAt +
                ivp.depositTime *
                1 days +
                ivp.stakeTime *
                1 days) <= block.timestamp,
            "not yet"
        );
        uint256 user_amount_invested = userBalanceInPool[msg.sender][_IVPid];
        userBalanceInPool[msg.sender][_IVPid] = 0;

        userRewards[msg.sender] +=
            (user_amount_invested / idToIVP[_IVPid].currentBalance) *
            100; // calculte user reward
        IERC20(ivp.tokenAddress).transfer(
            msg.sender,
            user_amount_invested * 10**18
        );
        emit Unstaked(_IVPid, msg.sender);
    }

    function claimReward() external {
        uint256 userReward = userRewards[msg.sender];
        userRewards[msg.sender] = 0;
        SPT.transfer(msg.sender, userReward * 10**18);
        emit Claimed(msg.sender);
    }

    //                              Helpful Functions

    // this function return true if the user is already investor in a pool
    // return false if not
    function isUserStaker(address _user, uint256 _IVPid)
        public
        view
        returns (bool)
    {
        IVP memory ivp = idToIVP[_IVPid];
        for (uint256 index = 0; index < ivp.stakers.length; index++) {
            if (ivp.stakers[index] == _user) {
                return true;
            }
        }
        return false;
    }

    // get the current Count of ids

    function getCurrentId() external view returns (uint256) {
        return IVPids;
    }

    // get the details of an IVP

    function getIVPdetails(uint256 _IVPid) external view returns (IVP memory) {
        return idToIVP[_IVPid];
    }

    // get all the live IVP

    function getLiveIVP() external view returns (IVP[] memory) {
        uint256 currentIndex = 0;
        uint256 totalLive = 0;

        for (uint256 i = 1; i < IVPids; i++) {
            if (
                block.timestamp <
                idToIVP[i].createdAt + idToIVP[i].depositTime * 1 days
            ) {
                totalLive += 1;
            }
        }

        IVP[] memory ivps = new IVP[](totalLive);
        for (uint256 i = 1; i < IVPids; i++) {
            if (
                block.timestamp <
                idToIVP[i].createdAt + idToIVP[i].depositTime * 1 days
            ) {
                IVP storage current_ivp = idToIVP[i];
                ivps[currentIndex] = current_ivp;
                currentIndex++;
            }
        }
        
        return ivps;
    }

    // get all the end IVP
    function getEndIVP() external view returns (IVP[] memory) {
        uint256 currentIndex = 0;
        uint256 totalLive = 0;

        for (uint256 i = 1; i < IVPids; i++) {
            if (
                block.timestamp >
                idToIVP[i].createdAt + idToIVP[i].depositTime * 1 days
            ) {
                totalLive += 1;
            }
        }

        IVP[] memory ivps = new IVP[](totalLive);
        for (uint256 i = 1; i < IVPids; i++) {
            if (
                block.timestamp >
                idToIVP[i].createdAt + idToIVP[i].depositTime * 1 days
            ) {
                IVP storage current_ivp = idToIVP[i];
                ivps[currentIndex] = current_ivp;
                currentIndex++;
            }
        }
        return ivps;
    }

    // get all the user IVP

    function getUserInvestment(address _user)
        external
        view
        returns (IVP[] memory)
    {
        uint256 currentIndex = 0;
        uint256 userPools = 0;

        for (uint256 i = 1; i < IVPids; i++) {
            if (isUserStaker(_user, i) == true) {
                userPools += 1;
            }
        }

        IVP[] memory ivps = new IVP[](userPools);
        for (uint256 i = 1; i < IVPids; i++) {
            if (isUserStaker(_user, i) == true) {
                IVP storage current_ivp = idToIVP[i];
                ivps[currentIndex] = current_ivp;
                currentIndex++;
            }
        }
        return ivps;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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