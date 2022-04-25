//SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;
import "./IFarmDeployer.sol";
import "./ERC20FarmFixEnd.sol";

contract FarmDeployer20FixEnd is IFarmDeployer20FixEnd {

    modifier onlyFarmDeployer() {
        require(farmDeployer == msg.sender, "Only Farm Deployer");
        _;
    }

    address public farmDeployer;

    /*
     * @notice Initialize the contract
     * @param _farmDeployer: Farm deployer address
     */
    constructor(
        address _farmDeployer
    ) {
        farmDeployer = _farmDeployer;
    }


    /*
    * @notice Deploys ERC20Farm contract. Requires amount of BNB to be paid
     * @param _stakeToken: Stake token contract address
     * @param _rewardToken: Reward token contract address
     * @param _startBlock: Start block
     * @param _endBlock: End block of reward distribution
     * @param _userStakeLimit: Maximum amount of tokens a user is allowed to stake (if any, else 0)
     * @param _minimumLockTime: Minimum number of blocks user should wait after deposit to withdraw without fee
     * @param _earlyWithdrawalFee: Fee for early withdrawal - in basis points
     * @param _feeReceiver: Receiver of early withdrawal fees
     * @param owner: Owner of the contract
     * @return farmAddress: Address of deployed pool contract
     */
    function deploy(
        address _stakeToken,
        address _rewardToken,
        uint256 _startBlock,
        uint256 _endBlock,
        uint256 _userStakeLimit,
        uint256 _minimumLockTime,
        uint256 _earlyWithdrawalFee,
        address _feeReceiver,
        address owner
    ) external onlyFarmDeployer returns(address farmAddress){

        farmAddress = address(new ERC20FarmFixEnd());
        IERC20FarmFixEnd(farmAddress).initialize(
            _stakeToken,
            _rewardToken,
            _startBlock,
            _endBlock,
            _userStakeLimit,
            _minimumLockTime,
            _earlyWithdrawalFee,
            _feeReceiver,
            owner
        );
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFarmDeployer {
    function maxLockTime() external returns(uint256);
    function incomeFee() external returns(uint256);
    function feeReceiver() external returns(address payable);
}

interface IFarmDeployer20 {
    function farmDeployer() external returns(address);
    function deploy(
        address _stakeToken,
        address _rewardToken,
        uint256 _startBlock,
        uint256 _rewardPerBlock,
        uint256 _userStakeLimit,
        uint256 _minimumLockTime,
        uint256 _earlyWithdrawalFee,
        address _feeReceiver,
        bool _keepReflectionOnDeposit,
        address owner
    ) external returns(address);
}

interface IFarmDeployer20FixEnd {
    function farmDeployer() external returns(address);
    function deploy(
        address _stakeToken,
        address _rewardToken,
        uint256 _startBlock,
        uint256 _endBlock,
        uint256 _userStakeLimit,
        uint256 _minimumLockTime,
        uint256 _earlyWithdrawalFee,
        address _feeReceiver,
        address owner
    ) external returns(address);
}

interface IFarmDeployer721 {
    function farmDeployer() external returns(address);
    function deploy(
        address _stakeToken,
        address _rewardToken,
        uint256 _startBlock,
        uint256 _rewardPerBlock,
        uint256 _userStakeLimit,
        uint256 _minimumLockTime,
        address owner
    ) external returns(address);
}

interface IFarmDeployer721FixEnd {
    function farmDeployer() external returns(address);
    function deploy(
        address _stakeToken,
        address _rewardToken,
        uint256 _startBlock,
        uint256 _endBlock,
        uint256 _userStakeLimit,
        uint256 _minimumLockTime,
        address owner
    ) external returns(address);
}

interface IERC20Farm {
    function initialize(
        address _stakeToken,
        address _rewardToken,
        uint256 _startBlock,
        uint256 _rewardPerBlock,
        uint256 _userStakeLimit,
        uint256 _minimumLockTime,
        uint256 _earlyWithdrawalFee,
        address _feeReceiver,
        bool _keepReflectionOnDeposit,
        address owner
    ) external;
}

interface IERC20FarmFixEnd {
    function initialize(
        address _stakeToken,
        address _rewardToken,
        uint256 _startBlock,
        uint256 _endBlock,
        uint256 _userStakeLimit,
        uint256 _minimumLockTime,
        uint256 _earlyWithdrawalFee,
        address _feeReceiver,
        address owner
    ) external;
}

interface IERC721Farm {
    function initialize(
        address _stakeToken,
        address _rewardToken,
        uint256 _startBlock,
        uint256 _rewardPerBlock,
        uint256 _userStakeLimit,
        uint256 _minimumLockTime,
        address owner
    ) external;
}

interface IERC721FarmFixEnd {
    function initialize(
        address _stakeToken,
        address _rewardToken,
        uint256 _startBlock,
        uint256 _endBlock,
        uint256 _userStakeLimit,
        uint256 _minimumLockTime,
        address owner
    ) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./IFarmDeployer.sol";

contract ERC20FarmFixEnd is Ownable, ReentrancyGuard, IERC20FarmFixEnd{

    event AdminTokenRecovery(address tokenRecovered, uint256 amount);
    event Deposit(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);
    event NewStartBlock(uint256);
    event NewEndBlock(uint256);
    event NewMinimumLockTime(uint256);
    event NewUserStakeLimit(uint256);
    event RewardIncome(uint256);
    event NewReflectionOnDeposit(bool);
    event NewFeeReceiver(address);
    event Withdraw(address indexed user, uint256 amount);

    address public feeReceiver;
    IERC20 public stakeToken;
    IERC20 public rewardToken;
    IFarmDeployer private farmDeployer;

    uint256 public startBlock;
    uint256 public endBlock;
    uint256 public lastRewardBlock;
    uint256 public userStakeLimit;
    uint256 public minimumLockTime;
    uint256 public earlyWithdrawalFee;
    uint256 private rewardTotalShares = 0;
    uint256 private stakeTotalShares = 0;
    uint256 private totalPendingReward = 0;

    // Accrued token per share
    uint256 public accTokenPerShare;

    // The precision factor
    uint256 public PRECISION_FACTOR;

    // Info of each user that stakes tokens (stakeToken)
    mapping(address => UserInfo) public userInfo;
    bool private initialized = false;

    struct UserInfo {
        uint256 shares; // How many shares the user has for staking
        uint256 rewardDebt; // Reward debt
        uint256 depositBlock; // Reward debt
    }

    /*
     * @notice Initialize the contract
     * @param _stakeToken: stake token address
     * @param _rewardToken: reward token address
     * @param _startBlock: start block
     * @param _endBlock: end reward block
     * @param _userStakeLimit: maximum amount of tokens a user is allowed to stake (if any, else 0)
     * @param _minimumLockTime: minimum number of blocks user should wait after deposit to withdraw without fee
     * @param _earlyWithdrawalFee: fee for early withdrawal - in basis points
     * @param _feeReceiver: Receiver of early withdrawal fees
     * @param owner: admin address with ownership
     */
    function initialize(
        address _stakeToken,
        address _rewardToken,
        uint256 _startBlock,
        uint256 _endBlock,
        uint256 _userStakeLimit,
        uint256 _minimumLockTime,
        uint256 _earlyWithdrawalFee,
        address _feeReceiver,
        address owner
    ) external {
        require(initialized == false, "Already initialized");
        initialized = true;

        transferOwnership(owner);

        if(_feeReceiver == address(0)){
            feeReceiver = address(this);
        } else {
            feeReceiver = _feeReceiver;
        }

        farmDeployer = IFarmDeployer(IFarmDeployer20FixEnd(msg.sender).farmDeployer());

        stakeToken = IERC20(_stakeToken);
        rewardToken = IERC20(_rewardToken);
        startBlock = _startBlock;
        lastRewardBlock = _startBlock;
        endBlock = _endBlock;
        userStakeLimit = _userStakeLimit;
        minimumLockTime = _minimumLockTime;
        earlyWithdrawalFee = _earlyWithdrawalFee;

        uint256 decimalsRewardToken = uint256(
            IERC20Metadata(_rewardToken).decimals()
        );
        require(decimalsRewardToken < 30, "Must be inferior to 30");
        PRECISION_FACTOR = uint256(10**(30 - decimalsRewardToken));
    }


    /*
     * @notice Deposit staked tokens and collect reward tokens (if any)
     * @param _amount: amount to deposit (in stakedToken)
     */
    function deposit(uint256 _amount) external nonReentrant {
        require(block.number >= startBlock, "Pool is not active yet");
        require(_amount > 0);
        UserInfo storage user = userInfo[msg.sender];

        if (userStakeLimit > 0) {
            require(
                _amount + user.shares * stakePPS() <= userStakeLimit,
                "User amount above limit"
            );
        }

        _updatePool();
        uint256 PPS = stakePPS();

        if (user.shares > 0) {
            uint256 pending = user.shares * accTokenPerShare / PRECISION_FACTOR - user.rewardDebt;
            if (pending > 0) {
                _transferReward(address(msg.sender), pending);
                totalPendingReward -= pending;
            }
        }

        user.shares = user.shares + _amount / PPS;
        stakeToken.transferFrom(
            address(msg.sender),
            address(this),
            _amount
        );
        stakeTotalShares += _amount / PPS;

        user.rewardDebt = user.shares * accTokenPerShare / PRECISION_FACTOR;
        user.depositBlock = block.number;

        emit Deposit(msg.sender, _amount);
    }


    /*
     * @notice Withdraw staked tokens and collect reward tokens
     * @notice Early withdrawal has a penalty
     * @param _shares: amount of shares to withdraw
     */
    function withdraw(uint256 _shares) external nonReentrant {
        UserInfo storage user = userInfo[msg.sender];
        require(user.shares >= _shares, "Amount to withdraw too high");

        _updatePool();

        uint256 pending = user.shares * accTokenPerShare / PRECISION_FACTOR - user.rewardDebt;

        if (_shares > 0) {
            user.shares = user.shares - _shares;
            uint256 earliestBlockToWithdrawWithoutFee = user.depositBlock + minimumLockTime;
            if(block.number < earliestBlockToWithdrawWithoutFee){
                _transferStakeWithFee(address(msg.sender), _shares);
            } else {
                _transferStake(address(msg.sender), _shares);
            }
        }

        if (pending > 0) {
            _transferReward(address(msg.sender), pending);
            totalPendingReward -= pending;
        }

        user.rewardDebt = user.shares * accTokenPerShare / PRECISION_FACTOR;

        emit Withdraw(msg.sender, _shares * stakePPS());
    }


    /*
     * @notice Withdraw staked tokens without caring about rewards
     * @notice Early withdrawal has a penalty
     * @dev Needs to be for emergency.
     */
    function emergencyWithdraw() external nonReentrant {
        UserInfo storage user = userInfo[msg.sender];
        uint256 shares = user.shares;

        uint256 pending = user.shares * accTokenPerShare / PRECISION_FACTOR - user.rewardDebt;
        totalPendingReward -= pending;
        user.shares = 0;
        user.rewardDebt = 0;

        if (shares > 0) {
            uint256 earliestBlockToWithdrawWithoutFee = user.depositBlock + minimumLockTime;
            if(block.number < earliestBlockToWithdrawWithoutFee){
                _transferStakeWithFee(address(msg.sender), shares);
            } else {
                _transferStake(address(msg.sender), shares);
            }
        }

        emit EmergencyWithdraw(msg.sender, shares * stakePPS());
    }


    /*
     * @notice Calculates the reward per block shares amount
     * @return Amount of reward shares
     */
    function rewardPerBlock() public view returns (uint256) {
        if(endBlock < lastRewardBlock) {
            return 0;
        }
        return (rewardTotalShares - totalPendingReward) / (endBlock - lastRewardBlock);
    }


    /*
     * @notice Calculates Price Per Share of Stake token
     * @return Price Per Share of Stake token
     */
    function stakePPS() public view returns(uint256) {
        if(stakeTotalShares > 10000) {
            if(address(stakeToken) != address(rewardToken)){
                return stakeToken.balanceOf(address(this)) / stakeTotalShares;
            } else {
                return stakeToken.balanceOf(address(this)) / (stakeTotalShares + rewardTotalShares);
            }
        } else if (address(stakeToken) == address(rewardToken) && rewardTotalShares > 10000) {
            return rewardPPS();
        }
        return 10**14;
    }


    /*
     * @notice Calculates Price Per Reward of Reward token
     * @return Price Per Share of Reward token
     */
    function rewardPPS() public view returns(uint256) {
        if(rewardTotalShares > 10000) {
            if(address(stakeToken) != address(rewardToken)){
                return rewardToken.balanceOf(address(this)) / rewardTotalShares;
            } else {
                return rewardToken.balanceOf(address(this)) / (stakeTotalShares + rewardTotalShares);
            }
        } else if (address(stakeToken) == address(rewardToken) && stakeTotalShares > 10000) {
            return stakePPS();
        }
        return 10**14;
    }


    /*
     * @notice Allows Owner to withdraw ERC20 tokens from the contract
     * @notice Can't withdraw deposited funds
     * @param _tokenAddress: Address of ERC20 token contract
     * @param _tokenAmount: Amount of tokens to withdraw
     */
    function recoverERC20(
        address _tokenAddress,
        uint256 _tokenAmount
    ) external onlyOwner {
        //If stake and reward tokens are same - forbid recover of these tokens
        require(!(address(stakeToken) == address(rewardToken)
            && _tokenAddress == address(stakeToken))
            , "Not allowed");

        if(_tokenAddress == address(stakeToken)){
            require(_tokenAmount <= (stakeToken.balanceOf(address(this)) - stakeTotalShares * stakePPS())
            , "Over deposits amount");
        }

        if(_tokenAddress == address(rewardToken)){
            uint256 allowedAmount = (rewardTotalShares - totalPendingReward) * rewardPPS();
            require(_tokenAmount <= allowedAmount, "Over pending rewards");
            if(rewardTotalShares * rewardPPS() > _tokenAmount) {
                rewardTotalShares -= _tokenAmount / rewardPPS();
            } else {
                rewardTotalShares = 0;
            }
        }

        IERC20(_tokenAddress).transfer(address(msg.sender), _tokenAmount);
        emit AdminTokenRecovery(_tokenAddress, _tokenAmount);
    }


    /*
     * @notice Sets start block of the pool
     * @param _startBlock: Number of start block
     */
    function setStartBlock(uint256 _startBlock) external onlyOwner {
        require(_startBlock >= block.number, "Can't set past block");
        require(startBlock >= block.number, "Staking has already started");
        startBlock = _startBlock;
        lastRewardBlock = _startBlock;

        emit NewStartBlock(_startBlock);
    }


    /*
     * @notice Sets end block of reward distribution
     * @param _endBlock: End block
     */
    function setEndBlock(uint256 _endBlock) external onlyOwner {
        require(block.number < _endBlock, "Invalid number");
        _updatePool();
        endBlock = _endBlock;

        emit NewEndBlock(_endBlock);
    }


    /*
     * @notice Sets maximum amount of tokens 1 user is able to stake. 0 for no limit
     * @param _userStakeLimit: Maximum amount of tokens allowed to stake
     */
    function setUserStakeLimit(uint256 _userStakeLimit) external onlyOwner {
        require(_userStakeLimit != 0);
        userStakeLimit = _userStakeLimit;

        emit NewUserStakeLimit(_userStakeLimit);
    }


    /*
     * @notice Sets early withdrawal fee
     * @param _earlyWithdrawalFee: Early withdrawal fee (in basis points)
     */
    function setEarlyWithdrawalFee(uint256 _earlyWithdrawalFee) external onlyOwner {
        require(earlyWithdrawalFee <= 10000);
        earlyWithdrawalFee = _earlyWithdrawalFee;

        emit NewUserStakeLimit(_earlyWithdrawalFee);
    }


    /*
     * @notice Sets minimum amount of blocks that should pass before user can withdraw
     * his deposit without a fee
     * @param _minimumLockTime: Number of blocks
     */
    function setMinimumLockTime(uint256 _minimumLockTime) external onlyOwner {
        require(_minimumLockTime <= farmDeployer.maxLockTime(),"Over max lock time");
        minimumLockTime = _minimumLockTime;

        emit NewMinimumLockTime(_minimumLockTime);
    }


    /*
     * @notice Sets receivers of fees for early withdrawal
     * @param _feeReceiver: Address of fee receiver
     */
    function setFeeReceiver(address _feeReceiver) external onlyOwner {
        require(_feeReceiver != address(0));
        require(_feeReceiver != feeReceiver, "Already set");

        feeReceiver = _feeReceiver;

        emit NewFeeReceiver(_feeReceiver);
    }


    /*
     * @notice Adds reward to the pool
     * @param amount: Amount of reward token
     */
    function addReward(uint256 amount) external onlyOwner {
        require(amount != 0);
        rewardToken.transferFrom(msg.sender, address(this), amount);

        uint256 feeAmount = amount * farmDeployer.incomeFee() / 10_000;
        rewardToken.transfer(farmDeployer.feeReceiver(), feeAmount);
        uint256 finalAmount = amount - feeAmount;

        rewardTotalShares += finalAmount / rewardPPS();
        emit RewardIncome(finalAmount);
    }


    /*
     * @notice View function to see pending reward on frontend.
     * @param _user: user address
     * @return Pending reward for a given user
     */
    function pendingReward(address _user) external view returns (uint256) {
        UserInfo storage user = userInfo[_user];
        if (block.number > lastRewardBlock && stakeTotalShares != 0) {
            uint256 multiplier = _getMultiplier(lastRewardBlock, block.number);
            uint256 cakeReward = multiplier * rewardPerBlock();
            uint256 adjustedTokenPerShare = accTokenPerShare +
                cakeReward * PRECISION_FACTOR / stakeTotalShares;
            return (user.shares * adjustedTokenPerShare / PRECISION_FACTOR - user.rewardDebt) * rewardPPS();
        } else {
            return (user.shares * accTokenPerShare / PRECISION_FACTOR - user.rewardDebt) * rewardPPS();
        }
    }


    /*
     * @notice Updates pool variables
     */
    function _updatePool() private {
        if (block.number <= lastRewardBlock) {
            return;
        }

        if (stakeTotalShares == 0) {
            lastRewardBlock = block.number;
            return;
        }

        uint256 multiplier = _getMultiplier(lastRewardBlock, block.number);
        uint256 cakeReward = multiplier == 0 ? 0 : multiplier * rewardPerBlock();
        totalPendingReward += cakeReward;
        accTokenPerShare = accTokenPerShare +
            cakeReward * PRECISION_FACTOR / stakeTotalShares;
        lastRewardBlock = block.number;
    }


    /*
     * @notice Calculates number of blocks to pay reward for.
     * @param _from: Starting block
     * @param _to: Ending block
     * @return Number of blocks, that should be rewarded
     */
    function _getMultiplier(
        uint256 _from,
        uint256 _to
    )
    private
    view
    returns (uint256)
    {
        if (_to <= endBlock) {
            return _to - _from;
        } else if (_from >= endBlock) {
            return 0;
        } else {
            return endBlock - _from;
        }
    }


    /*
     * @notice Transfers specific amount of shares of stake tokens.
     * @param receiver: Receiver address
     * @param shares: Amount of shares
     */
    function _transferStake(address receiver, uint256 shares) private {
        stakeToken.transfer(receiver, shares * stakePPS());
        stakeTotalShares -= shares;
    }


    /*
     * @notice Transfers specific amount of shares of stake tokens.
     * @notice Calculating fee for early withdrawal.
     * @param receiver: Receiver address
     * @param shares: Amount of shares
     */
    function _transferStakeWithFee(address receiver, uint256 shares) private {
        uint256 feeAmount = shares * earlyWithdrawalFee / 10000;
        uint256 transferAmount = shares - feeAmount;
        _transferStake(address(msg.sender), transferAmount);

        if(feeReceiver != address(this)) {
            _transferStake(feeReceiver, feeAmount);
        } else if(address(stakeToken) == address(rewardToken)) {
            rewardTotalShares += feeAmount;
        }
    }


    /*
     * @notice Transfers specific amount of shares of reward tokens.
     * @param receiver: Receiver address
     * @param shares: Amount of shares
     */
    function _transferReward(address receiver, uint256 shares) private {
        rewardToken.transfer(receiver, shares * rewardPPS());
        rewardTotalShares -= shares;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address sender,
        address recipient,
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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