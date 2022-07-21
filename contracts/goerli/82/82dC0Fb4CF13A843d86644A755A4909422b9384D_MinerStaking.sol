// SPDX-License-Identifier: AGPL-3.0
pragma solidity =0.7.5;

// ============= Libraries =============
import "./libraries/SafeMath.sol";
import "./libraries/SafeERC20.sol";

// ============= Interface =============
import "./interfaces/IERC20.sol";
import "./interfaces/IvMINER.sol";
import "./interfaces/IgMINER.sol";
import "./interfaces/IDistributor.sol";

// ============= Other =============
import "./types/MinerAccessControlled.sol";

contract MinerStaking is MinerAccessControlled {
    /* ========== DEPENDENCIES ========== */

    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using SafeERC20 for IvMINER;
    using SafeERC20 for IgMINER;

    /* ========== EVENTS ========== */

    event DistributorSet(address distributor);
    event WarmupSet(uint256 warmup);

    /* ========== DATA STRUCTURES ========== */

    struct Epoch {
        uint256 length; // in seconds
        uint256 number; // since inception
        uint256 end; // timestamp
        uint256 distribute; // amount
    }

    struct Claim {
        uint256 deposit; // if forfeiting
        uint256 gons; // staked balance
        uint256 expiry; // end of warmup period
        bool lock; // prevents malicious delays for claim
    }

    struct UserInfo {
        uint256 stakedAmount;
        uint256 firstTimeDeposited;
        uint256 lastTimeDeposited;
        uint256 lockEndTime;
    }

    /* ========== STATE VARIABLES ========== */

    IERC20 public immutable miner;
    IvMINER public immutable vMINER;
    IgMINER public immutable gMINER;

    Epoch public epoch;

    IDistributor public distributor;

    mapping(address => Claim) public warmupInfo;
    mapping(address => UserInfo) public userInfo;

    uint256 public warmupPeriod;
    uint256 private gonsInWarmup;

    uint256 public constant WEEK = 7 * 86400; // all future times are rounded by week
    uint256 public constant MAXTIME = 4 * 365 * 86400; // 4 years
    uint256 public constant MULTIPLIER = 1e9;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _miner,
        address _vMINER,
        address _gMINER,
        uint256 _epochLength,
        uint256 _firstEpochNumber,
        uint256 _firstEpochTime,
        address _authority
    ) MinerAccessControlled(IMinerAuthority(_authority)) {
        require(_miner != address(0), "Zero address: MINER");
        miner = IERC20(_miner);
        require(_vMINER != address(0), "Zero address: vMINER");
        vMINER = IvMINER(_vMINER);
        require(_gMINER != address(0), "Zero address: gMINER");
        gMINER = IgMINER(_gMINER);

        epoch = Epoch({length: _epochLength, number: _firstEpochNumber, end: _firstEpochTime, distribute: 0});
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @notice stake MINER to enter warmup
     * @param _to  The address to stake to.
     * @param _amount  The amount of Miner tokens to stake.
     * @param _unlockTime  The time to lock the stake.
     * @return uint
     */
    function stake(
        address _to,
        uint256 _amount,
        uint256 _unlockTime
    ) external returns (uint256) {
        miner.safeTransferFrom(msg.sender, address(this), _amount);
        _amount = _amount.add(rebase()); // add bounty if rebase occurred

        uint256 unlockTime = (_unlockTime / WEEK) * WEEK; // Locktime is rounded down to weeks
        // UserInfo storage user = userInfo[_to];

        require(_amount > 0, "Invalid Amount"); // dev: need non-zero value
        require(unlockTime > block.timestamp, "MINIMUM: Lock for 1 week");
        require(unlockTime <= block.timestamp + MAXTIME, "Lock can be 4 years max");

        _depositFor(_to, _amount, unlockTime);
        return _send(_to, _amount);
    }

    function updateLocker(uint256 _value, uint256 _unlockTime) external {
        UserInfo storage user = userInfo[msg.sender];

        if (_value > 0) {
            require(_value > 0); // dev: need non-zero value
            require(user.stakedAmount > 0, "No existing lock found");
            require(user.lockEndTime > block.timestamp, "Cannot add to expired lock. Withdraw");
            miner.safeTransferFrom(msg.sender, address(this), _value);
            _send(msg.sender, _value);
        }

        if (_unlockTime > 0) {
            uint256 unlockTime = (_unlockTime / WEEK) * WEEK; // Locktime is rounded down to weeks

            require(user.lockEndTime > block.timestamp, "Lock expired");
            require(user.stakedAmount > 0, "Nothing is locked");
            require(unlockTime > user.lockEndTime, "Can only increase lock duration");
            require(unlockTime <= block.timestamp + MAXTIME, "Voting lock can be 4 years max");
        }

        _depositFor(msg.sender, _value, _unlockTime);
    }

    /// @notice Deposit tokens for miner allocation.
    /// @param _user  address The user to deposit tokens for.
    /// @param _amount uint The amount of tokens to deposit.
    /// @param _unlockTime uint The time at which the user's deposit will be unlocked.
    function _depositFor(
        address _user,
        uint256 _amount,
        uint256 _unlockTime
    ) internal {
        UserInfo storage user = userInfo[_user];

        user.stakedAmount = user.stakedAmount.add(_amount);
        user.lastTimeDeposited = block.timestamp;
        if (user.firstTimeDeposited == 0) {
            user.firstTimeDeposited = block.timestamp;
        }

        if (_unlockTime != 0) {
            user.lockEndTime = _unlockTime;
        }

        gMINER.updateUserCheckPoint(_user, _amount, _unlockTime, block.timestamp);
    }

    /**
     * @notice redeem vMINER for MINERs
     * @param _to address
     * @param _trigger bool
     * @return amount_ uint
     */
    function unstake(address _to, bool _trigger) external returns (uint256 amount_) {
        UserInfo storage user = userInfo[msg.sender];
        require(user.firstTimeDeposited != 0, "User has not deposited");

        uint256 _amount = vMINER.balanceOf(msg.sender);
        amount_ = _amount;
        if (block.timestamp < user.lockEndTime) {
            amount_ = user.stakedAmount;
        }

        uint256 bounty;
        if (_trigger) {
            bounty = rebase();
        }

        vMINER.safeTransferFrom(msg.sender, address(this), _amount);
        // amount_ = amount_.add(bounty);
        // user.stakedAmount = user.stakedAmount.sub(_amount);

        require(amount_ <= miner.balanceOf(address(this)), "Insufficient MINER balance in contract");
        miner.safeTransfer(_to, amount_);
        delete userInfo[msg.sender];
    }

    /**
     * @notice convert _amount vMINER into gBalance_ gMINER
     * @param _to address
     * @param _amount uint
     * @return gBalance_ uint
     */
    function wrap(address _to, uint256 _amount) external returns (uint256 gBalance_) {
        vMINER.safeTransferFrom(msg.sender, address(this), _amount);
        gBalance_ = gMINER.balanceTo(_amount);
        gMINER.mint(_to, gBalance_);
    }

    /**
     * @notice convert _amount gMINER into sBalance_ vMINER
     * @param _to address
     * @param _amount uint
     * @return sBalance_ uint
     */
    function unwrap(address _to, uint256 _amount) external returns (uint256 sBalance_) {
        gMINER.burn(msg.sender, _amount);
        sBalance_ = gMINER.balanceFrom(_amount);
        vMINER.safeTransfer(_to, sBalance_);
    }

    /**
     * @notice trigger rebase if epoch over
     * @return uint256
     */
    function rebase() public returns (uint256) {
        uint256 bounty;
        if (epoch.end <= block.timestamp) {
            vMINER.rebase(epoch.distribute, epoch.number);

            epoch.end = epoch.end.add(epoch.length);
            epoch.number++;

            if (address(distributor) != address(0)) {
                distributor.distribute();
                bounty = distributor.retrieveBounty(); // Will mint miner for this contract if there exists a bounty
            }
            uint256 balance = miner.balanceOf(address(this));
            uint256 staked = vMINER.circulatingSupply();
            if (balance <= staked.add(bounty)) {
                epoch.distribute = 0;
            } else {
                epoch.distribute = balance.sub(staked).sub(bounty);
            }
        }
        return bounty;
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    /**
     * @notice send staker their amount as vMINER or gMINER
     * @param _to address
     * @param _amount uint
     */
    function _send(address _to, uint256 _amount) internal returns (uint256) {
        vMINER.safeTransfer(_to, _amount); // send as vMINER (equal unit as MINER)
        return _amount;
    }

    /* ========== VIEW FUNCTIONS ========== */

    /**
     * @notice returns the vMINER index, which tracks rebase growth
     * @return uint
     */
    function index() public view returns (uint256) {
        return vMINER.index();
    }

    /**
     * @notice total supply in warmup
     */
    function supplyInWarmup() public view returns (uint256) {
        return vMINER.balanceForGons(gonsInWarmup);
    }

    /**
     * @notice seconds until the next epoch begins
     */
    function secondsToNextEpoch() external view returns (uint256) {
        return epoch.end.sub(block.timestamp);
    }

    /* ========== MANAGERIAL FUNCTIONS ========== */

    /**
     * @notice sets the contract address for LP staking
     * @param _distributor address
     */
    function setDistributor(address _distributor) external onlyGovernor {
        distributor = IDistributor(_distributor);
        emit DistributorSet(_distributor);
    }

    /**
     * @notice set warmup period for new stakers
     * @param _warmupPeriod uint
     */
    function setWarmupLength(uint256 _warmupPeriod) external onlyGovernor {
        warmupPeriod = _warmupPeriod;
        emit WarmupSet(_warmupPeriod);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

interface IDistributor {
    function distribute() external;

    function bounty() external view returns (uint256);

    function retrieveBounty() external returns (uint256);

    function nextRewardAt(uint256 _rate) external view returns (uint256);

    function nextRewardFor(address _recipient) external view returns (uint256);

    function setBounty(uint256 _bounty) external;

    function addRecipient(address _recipient, uint256 _rewardRate) external;

    function removeRecipient(uint256 _index) external;

    function setAdjustment(
        uint256 _index,
        bool _add,
        uint256 _rate,
        uint256 _target
    ) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

interface IMinerAuthority {
    /* ========== EVENTS ========== */

    event GovernorPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event GuardianPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event PolicyPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event VaultPushed(address indexed from, address indexed to, bool _effectiveImmediately);

    event GovernorPulled(address indexed from, address indexed to);
    event GuardianPulled(address indexed from, address indexed to);
    event PolicyPulled(address indexed from, address indexed to);
    event VaultPulled(address indexed from, address indexed to);

    /* ========== VIEW ========== */

    function governor() external view returns (address);

    function guardian() external view returns (address);

    function policy() external view returns (address);

    function vault() external view returns (address);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

import "./IERC20.sol";

interface IgMINER is IERC20 {
    function mint(address _to, uint256 _amount) external;

    function burn(address _from, uint256 _amount) external;

    function index() external view returns (uint256);

    function balanceFrom(uint256 _amount) external view returns (uint256);

    function balanceTo(uint256 _amount) external view returns (uint256);

    function migrate(address _staking, address _vMINER) external;

    function updateUserCheckPoint(
        address _user,
        uint256 lockedAmount,
        uint256 _duration,
        uint256 _time
    ) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

import "./IERC20.sol";

interface IvMINER is IERC20 {
    function rebase(uint256 minerProfit_, uint256 epoch_) external returns (uint256);

    function circulatingSupply() external view returns (uint256);

    function gonsForBalance(uint256 amount) external view returns (uint256);

    function balanceForGons(uint256 gons) external view returns (uint256);

    function index() external view returns (uint256);

    function toG(uint256 amount) external view returns (uint256);

    function fromG(uint256 amount) external view returns (uint256);

    function changeDebt(
        uint256 amount,
        address debtor,
        bool add
    ) external;

    function debtBalances(address _address) external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.5;

import {IERC20} from "../interfaces/IERC20.sol";

/// @notice Safe IERC20 and ETH transfer library that safely handles missing return values.
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v3-periphery/blob/main/contracts/libraries/TransferHelper.sol)
/// Taken from Solmate
library SafeERC20 {
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.transfer.selector, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "TRANSFER_FAILED");
    }

    function safeApprove(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.approve.selector, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "APPROVE_FAILED");
    }

    function safeTransferETH(address to, uint256 amount) internal {
        (bool success, ) = to.call{value: amount}(new bytes(0));

        require(success, "ETH_TRANSFER_FAILED");
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.7.5;

// TODO(zx): Replace all instances of SafeMath with OZ implementation
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        assert(a == b * c + (a % b)); // There is no case in which this doesn't hold

        return c;
    }

    // Only used in the  BondingCalculator.sol
    function sqrrt(uint256 a) internal pure returns (uint256 c) {
        if (a > 3) {
            c = a;
            uint256 b = add(div(a, 2), 1);
            while (b < c) {
                c = b;
                b = div(add(div(a, b), b), 2);
            }
        } else if (a != 0) {
            c = 1;
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.5;

import "../interfaces/IMinerAuthority.sol";

abstract contract MinerAccessControlled {
    /* ========== EVENTS ========== */

    event AuthorityUpdated(IMinerAuthority indexed authority);

    string UNAUTHORIZED = "UNAUTHORIZED"; // save gas

    /* ========== STATE VARIABLES ========== */

    IMinerAuthority public authority;

    /* ========== Constructor ========== */

    constructor(IMinerAuthority _authority) {
        authority = _authority;
        emit AuthorityUpdated(_authority);
    }

    /* ========== MODIFIERS ========== */

    modifier onlyGovernor() {
        require(msg.sender == authority.governor(), UNAUTHORIZED);
        _;
    }

    modifier onlyGuardian() {
        require(msg.sender == authority.guardian(), UNAUTHORIZED);
        _;
    }

    modifier onlyPolicy() {
        require(msg.sender == authority.policy(), UNAUTHORIZED);
        _;
    }

    modifier onlyVault() {
        require(msg.sender == authority.vault(), UNAUTHORIZED);
        _;
    }

    /* ========== GOV ONLY ========== */

    function setAuthority(IMinerAuthority _newAuthority) external onlyGovernor {
        authority = _newAuthority;
        emit AuthorityUpdated(_newAuthority);
    }
}