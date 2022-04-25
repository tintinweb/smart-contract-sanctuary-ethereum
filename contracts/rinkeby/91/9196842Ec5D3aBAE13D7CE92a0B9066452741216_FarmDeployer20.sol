//SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;
import "./ERC20Farm.sol";
import "./IFarmDeployer.sol";

contract FarmDeployer20 is IFarmDeployer20 {

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
     * @param _rewardPerBlock: Reward per block (in rewardToken)
     * @param _userStakeLimit: Maximum amount of tokens a user is allowed to stake (if any, else 0)
     * @param _minimumLockTime: Minimum number of blocks user should wait after deposit to withdraw without fee
     * @param _earlyWithdrawalFee: Fee for early withdrawal - in basis points
     * @param _feeReceiver: Receiver of early withdrawal fees
     * @param _keepReflectionOnDeposit: Should the farm keep track of reflection tokens on deposit?
     * @param owner: Owner of the contract
     * @return farmAddress: Address of deployed pool contract
     */
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
    ) external onlyFarmDeployer returns(address farmAddress){

        farmAddress = address(new ERC20Farm());
        IERC20Farm(farmAddress).initialize(
            _stakeToken,
            _rewardToken,
            _startBlock,
            _rewardPerBlock,
            _userStakeLimit,
            _minimumLockTime,
            _earlyWithdrawalFee,
            _feeReceiver,
            _keepReflectionOnDeposit,
            owner
        );
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./IFarmDeployer.sol";

contract ERC20Farm is Ownable, ReentrancyGuard, IERC20Farm{

    event AdminTokenRecovery(address tokenRecovered, uint256 amount);
    event Deposit(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);
    event NewStartBlock(uint256 startBlock);
    event NewRewardPerBlock(uint256 rewardPerBlock);
    event NewMinimumLockTime(uint256 minimumLockTime);
    event NewUserStakeLimit(uint256 userStakeLimit);
    event NewReflectionOnDeposit(bool);
    event NewFeeReceiver(address);
    event Withdraw(address indexed user, uint256 amount);

    address public feeReceiver;
    IERC20 public stakeToken;
    IERC20 public rewardToken;
    IFarmDeployer private farmDeployer;

    uint256 public startBlock;
    uint256 public lastRewardBlock;
    uint256 public rewardPerBlock;
    uint256 public userStakeLimit;
    uint256 public minimumLockTime;
    uint256 public earlyWithdrawalFee;
    uint256 private stakeTotalShares = 0;
    uint256 private totalPendingReward = 0;
    uint256 private lastRewardTokenBalance = 0;
    bool public keepReflectionOnDeposit;
    bool private initialized = false;

    // Accrued token per share
    uint256 public accTokenPerShare;

    // The precision factor
    uint256 public PRECISION_FACTOR;

    // Info of each user that stakes tokens (stakeToken)
    mapping(address => UserInfo) public userInfo;

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
     * @param _rewardPerBlock: reward per block (in rewardToken)
     * @param _userStakeLimit: maximum amount of tokens a user is allowed to stake (if any, else 0)
     * @param _minimumLockTime: minimum number of blocks user should wait after deposit to withdraw without fee
     * @param _earlyWithdrawalFee: fee for early withdrawal - in basis points
     * @param _feeReceiver: Receiver of early withdrawal fees
     * @param _keepReflectionOnDeposit: Should the farm keep track of reflection tokens on deposit?
     * @param owner: admin address with ownership
     */
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
    ) external {
        require(initialized == false, "Already initialized");
        initialized = true;

        if(_keepReflectionOnDeposit) {
            require(_stakeToken != _rewardToken, "Can't track deposit reflections with same reward token");
        }
        transferOwnership(owner);

        if(_feeReceiver == address(0)){
            feeReceiver = address(this);
        } else {
            feeReceiver = _feeReceiver;
        }

        farmDeployer = IFarmDeployer(IFarmDeployer20(msg.sender).farmDeployer());

        stakeToken = IERC20(_stakeToken);
        rewardToken = IERC20(_rewardToken);
        startBlock = _startBlock;
        lastRewardBlock = _startBlock;
        rewardPerBlock = _rewardPerBlock;
        userStakeLimit = _userStakeLimit;
        minimumLockTime = _minimumLockTime;
        earlyWithdrawalFee = _earlyWithdrawalFee;
        keepReflectionOnDeposit = _keepReflectionOnDeposit;

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
        _collectFee();
        require(block.number >= startBlock, "Pool is not active yet");
        require(_amount > 0);
        UserInfo storage user = userInfo[msg.sender];

        if (userStakeLimit > 0) {
            require(
                _amount + user.shares * pricePerShare() <= userStakeLimit,
                "User amount above limit"
            );
        }

        _updatePool();
        uint256 PPS = pricePerShare();

        if (user.shares > 0) {
            uint256 pending = user.shares * accTokenPerShare / PRECISION_FACTOR - user.rewardDebt;
            if (pending > 0) {
                rewardToken.transfer(address(msg.sender), pending);
            }
            totalPendingReward -= pending;
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
        lastRewardTokenBalance = rewardToken.balanceOf(address(this));

        emit Deposit(msg.sender, _amount);
    }


    /*
     * @notice Withdraw staked tokens and collect reward tokens
     * @notice Early withdrawal has a penalty
     * @param _shares: amount of shares to withdraw
     */
    function withdraw(uint256 _shares) external nonReentrant {
        _collectFee();
        UserInfo storage user = userInfo[msg.sender];
        require(user.shares >= _shares, "Amount to withdraw too high");

        _updatePool();

        uint256 pending = user.shares * accTokenPerShare / PRECISION_FACTOR - user.rewardDebt;
        uint256 transferAmount = _shares * pricePerShare();

        if (_shares > 0) {
            user.shares = user.shares - _shares;
            uint256 earliestBlockToWithdrawWithoutFee = user.depositBlock + minimumLockTime;
            if(block.number < earliestBlockToWithdrawWithoutFee){
                uint256 feeAmount = transferAmount * earlyWithdrawalFee / 10000;
                transferAmount -= feeAmount;
                stakeToken.transfer(address(msg.sender), transferAmount);
                if(address(stakeToken) != address(rewardToken)) {
                    stakeToken.transfer(feeReceiver, feeAmount);
                }
            } else {
                stakeToken.transfer(address(msg.sender), transferAmount);
            }
            stakeTotalShares -= _shares;
        }

        if (pending > 0) {
            rewardToken.transfer(address(msg.sender), pending);
            totalPendingReward -= pending;
        }

        user.rewardDebt = user.shares * accTokenPerShare / PRECISION_FACTOR;
        lastRewardTokenBalance = rewardToken.balanceOf(address(this));

        emit Withdraw(msg.sender, transferAmount);
    }


    /*
     * @notice Withdraw staked tokens without caring about rewards
     * @notice Early withdrawal has a penalty
     * @dev Needs to be for emergency.
     */
    function emergencyWithdraw() external nonReentrant {
        _collectFee();
        UserInfo storage user = userInfo[msg.sender];
        uint256 shares = user.shares;
        uint256 amountToTransfer = user.shares * pricePerShare();

        uint256 pending = user.shares * accTokenPerShare / PRECISION_FACTOR - user.rewardDebt;
        totalPendingReward -= pending;
        user.shares = 0;
        user.rewardDebt = 0;

        if (amountToTransfer > 0) {
            uint256 earliestBlockToWithdrawWithoutFee = user.depositBlock + minimumLockTime;
            if(block.number < earliestBlockToWithdrawWithoutFee){
                uint256 feeAmount = amountToTransfer * earlyWithdrawalFee / 10000;
                uint256 transferAmount = amountToTransfer - feeAmount;
                stakeToken.transfer(address(msg.sender), transferAmount);
                if(address(stakeToken) != address(rewardToken)) {
                    stakeToken.transfer(feeReceiver, feeAmount);
                }
            } else {
                stakeToken.transfer(address(msg.sender), amountToTransfer);
            }
            stakeTotalShares -= shares;
        }

        lastRewardTokenBalance = rewardToken.balanceOf(address(this));
        emit EmergencyWithdraw(msg.sender, amountToTransfer);
    }


    /*
     * @notice Calculates the last block number according to available funds
     */
    function getFinalBlockNumber() public view returns (uint256) {
        //in case reward token == stake token
        uint256 sameTokenAmount = address(rewardToken) == address(stakeToken)
            ? stakeTotalShares * pricePerShare()
            : 0;

        uint256 contractBalance = rewardToken.balanceOf(address(this)) - sameTokenAmount;
        return lastRewardBlock + (contractBalance - totalPendingReward) / rewardPerBlock;
    }


    /*
     * @notice Calculates Price Per Share
     */
    function pricePerShare() public view returns(uint256) {
        if(keepReflectionOnDeposit && stakeTotalShares > 10000) {
            return stakeToken.balanceOf(address(this)) / stakeTotalShares;
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
        if(keepReflectionOnDeposit) {
            require(_tokenAddress != address(stakeToken), "Can't recover reflection stake token");
        }

        if(_tokenAddress == address(stakeToken)){
            require(_tokenAmount <= (stakeToken.balanceOf(address(this)) - stakeTotalShares * pricePerShare())
            , "Over deposits amount");
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
     * @notice Sets reward amount per block
     * @param _rewardPerBlock: Token amount to be distributed for each block
     */
    function setRewardPerBlock(uint256 _rewardPerBlock) external onlyOwner {
        require(_rewardPerBlock != 0);
        rewardPerBlock = _rewardPerBlock;

        emit NewRewardPerBlock(_rewardPerBlock);
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
     * @notice Sets calculation of reflection tokens on deposit
     * @param _keepReflectionOnDeposit: Should contract keep track of reflections of deposit tokens?
     */
    function setReflectionOnDeposit(bool _keepReflectionOnDeposit) external onlyOwner {
        require(_keepReflectionOnDeposit != keepReflectionOnDeposit, "Already set");
        require(address(stakeToken) != address(rewardToken), "Can't track deposit reflections with same reward token");
        keepReflectionOnDeposit = _keepReflectionOnDeposit;

        emit NewReflectionOnDeposit(_keepReflectionOnDeposit);
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
     * @notice View function to see pending reward on frontend.
     * @param _user: user address
     * @return Pending reward for a given user
     */
    function pendingReward(address _user) external view returns (uint256) {
        UserInfo storage user = userInfo[_user];
        if (block.number > lastRewardBlock && stakeTotalShares != 0) {
            uint256 multiplier = _getMultiplier(lastRewardBlock, block.number);
            uint256 cakeReward = multiplier * rewardPerBlock;
            uint256 adjustedTokenPerShare = accTokenPerShare +
                cakeReward * PRECISION_FACTOR / stakeTotalShares;
            return user.shares * adjustedTokenPerShare / PRECISION_FACTOR - user.rewardDebt;
        } else {
            return user.shares * accTokenPerShare / PRECISION_FACTOR - user.rewardDebt;
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
        uint256 cakeReward = multiplier * rewardPerBlock;
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
        uint256 finalBlock = getFinalBlockNumber();
        if (_to <= finalBlock) {
            return _to - _from;
        } else if (_from >= finalBlock) {
            return 0;
        } else {
            return finalBlock - _from;
        }
    }


    /*
     * @notice Calculates reward token income and transfers specific fee amount.
     * @notice Fee share and fee receiver are specified on Deployer contract
     */
    function _collectFee() private {
        uint256 rewardBalance = rewardToken.balanceOf(address(this));
        if(rewardBalance != lastRewardTokenBalance) {
            uint256 income = rewardBalance - lastRewardTokenBalance;
            uint256 feeAmount = income * farmDeployer.incomeFee() / 10_000;
            rewardToken.transfer(farmDeployer.feeReceiver(), feeAmount);
        }
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