// // SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./../interfaces/IExchange.sol";
import "./../interfaces/IBalancer.sol";
import "./CvxDistributor.sol";
import "./../interfaces/IAlluoLockedV3.sol";

contract AlluoLockedV4 is
    Initializable,
    UUPSUpgradeable,
    AccessControlUpgradeable,
    PausableUpgradeable,
    IBalancerStructs
{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using AddressUpgradeable for address;

    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    // Locking's reward amount produced per distribution time.
    uint256 public rewardPerDistribution;
    // Locking's reward distribution time.
    uint256 public constant distributionTime = 86400; 
    // Amount of currently locked tokens from all users (in lp).
    uint256 public totalLocked;

    // Auxiliary parameter (tpl) for locking's math
    uint256 private tokensPerLock;
    // Аuxiliary parameter for locking's math
    uint256 private rewardProduced;
    // Аuxiliary parameter for locking's math
    uint256 private allProduced;
    // Аuxiliary parameter for locking's math
    uint256 private producedTime;

    //period of locking after lock function call
    uint256 public depositLockDuration;
    //period of locking after unlock function call
    uint256 public withdrawLockDuration;

    // Amount of locked tokens waiting for withdraw (in Alluo).
    uint256 public waitingForWithdrawal;
    // Amount of currently claimed rewards by the users.
    uint256  public totalDistributed;
    // flag for allowing upgrade
    bool public upgradeStatus;

    //erc20-like interface
    struct TokenInfo {
        string name;
        string symbol;
        uint8 decimals;
    }

    TokenInfo private token;

    // Locker contains info related to each locker.
    struct Locker {
        uint256 amount; // Tokens currently locked to the contract and vote power (in lp)
        uint256 rewardAllowed; // Rewards allowed to be paid out
        uint256 rewardDebt; // Param is needed for correct calculation locker's share
        uint256 distributed; // Amount of distributed tokens
        uint256 unlockAmount; // Amount of tokens which is available to withdraw (in alluo)
        uint256 depositUnlockTime; // The time when tokens are available to unlock
        uint256 withdrawUnlockTime; // The time when tokens are available to withdraw
    }

    // Lockers info by token holders.
    mapping(address => Locker) public _lockers;

    // Contract that manages extra rewards in CVX tokens
    CvxDistributor public cvxDistributor;

    // old values available for claim from old vlAlluo contract
    mapping(address => uint256) public oldClaim;
    mapping(address => uint256) public oldWithdraw;

    // ERC20 token locked on the contract and earned by locker as reward.
    IERC20Upgradeable public constant alluoToken =
        IERC20Upgradeable(0x1E5193ccC53f25638Aa22a940af899B692e10B09);

    IExchange public constant exchange =
        IExchange(0x29c66CF57a03d41Cfe6d9ecB6883aa0E2AbA21Ec);
    IBalancer public constant balancer =
        IBalancer(0xBA12222222228d8Ba445958a75a0704d566BF2C8);
    IERC20Upgradeable public constant alluoBalancerLp =
        IERC20Upgradeable(0x85Be1e46283f5f438D1f864c2d925506571d544f);
    IERC20Upgradeable public constant weth = 
        IERC20Upgradeable(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    bytes32 public constant poolId =
        0x85be1e46283f5f438d1f864c2d925506571d544f0002000000000000000001aa;

    /**
     * @dev Emitted in `updateWithdrawLockDuration` when the lock time after unlock() was changed
     */
    event WithdrawLockDurationUpdated(uint256 time, uint256 timestamp);

    /**
     * @dev Emitted in `updateDepositLockDuration` when the lock time after lock() was changed
     */
    event DepositLockDurationUpdated(uint256 time, uint256 timestamp);

    /**
     * @dev Emitted in `setReward` when the new rewardPerDistribution was set
     */
    event RewardAmountUpdated(uint256 amount, uint256 produced);

    /**
     * @dev Emitted in `lock` when the user locked the tokens
     */
    event TokensLocked(
        address indexed sender,
        address tokenAddress, 
        uint256 tokenAmount, 
        uint256 time
    );

    /**
     * @dev Emitted in `unlock` when the user unbinded his locked tokens
     */
    event TokensUnlocked(
        address indexed sender,
        uint256 alluoAmount,
        uint256 time
    );
    
    /**
     * @dev Emitted in `withdraw` when the user withdrew his locked tokens from the contract
     */
    event TokensWithdrawed(
        address indexed sender,
        uint256 alluoAmount,
        uint256 time
    );

    /**
     * @dev Emitted in `claim` when the user claimed his reward tokens
     */
    event TokensClaimed(
        address indexed sender,
        uint256 alluoAmount, 
        uint256 time
    );

    // allows to see balances on etherscan  
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Contract constructor without parameters
     */
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}
 
    /**
     * @dev Contract initializer 
     */
    function initialize(
        address _multiSigWallet,
        uint256 _rewardPerDistribution
    ) public initializer{
        __AccessControl_init();
        __Pausable_init();
        __UUPSUpgradeable_init();

        require(_multiSigWallet.isContract(), "Locking: not contract");

        _setupRole(DEFAULT_ADMIN_ROLE, _multiSigWallet);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(UPGRADER_ROLE, _multiSigWallet);

        token = TokenInfo({
            name: "Vote Locked Alluo Token",
            symbol: "vlAlluo",
            decimals: 18
        });

        rewardPerDistribution = _rewardPerDistribution; 
        producedTime = block.timestamp;

        depositLockDuration = 86400 * 7; 
        withdrawLockDuration = 86400 * 5;
    }

    function decimals() public view returns (uint8) {
        return token.decimals;
    }

    function name() public view returns (string memory) {
        return token.name;
    }

    function symbol() public view returns (string memory) {
        return token.symbol;
    }

    /**
     * @dev Calculates the necessary parameters for locking
     * @return Totally produced rewards
     */
    function produced() private view returns (uint256) {
        return
            allProduced +
            (rewardPerDistribution * (block.timestamp - producedTime)) /
            distributionTime;
    }

    /**
     * @dev Updates the produced rewards parameter for locking
     */
    function update() public whenNotPaused {
        uint256 rewardProducedAtNow = produced();
        if (rewardProducedAtNow > rewardProduced) {
            uint256 producedNew = rewardProducedAtNow - rewardProduced;
            if (totalLocked > 0) {
                tokensPerLock =
                    tokensPerLock +
                    (producedNew * 1e20) /
                    totalLocked;
            }
            rewardProduced = rewardProduced + producedNew;
        }
    }

    /**
     * @dev Locks specified amount Alluo tokens in the contract
     * @param _amount An amount of Alluo tokens to lock
     */
    function lock(uint256 _amount) public {

        Locker storage locker = _lockers[msg.sender];

        alluoToken.safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );

        if (totalLocked > 0) {
            update();
        }

        locker.rewardDebt =
            locker.rewardDebt +
            ((_amount * tokensPerLock) / 1e20);
        totalLocked = totalLocked + _amount;
        locker.amount = locker.amount + _amount;
        locker.depositUnlockTime = block.timestamp + depositLockDuration;

        emit TokensLocked(msg.sender, address(alluoToken), _amount, block.timestamp);
        emit Transfer(address(0), msg.sender, _amount);

        cvxDistributor.receiveStakeInfo(msg.sender, _amount);
    }

    /**
     * @dev Migrates all balances from old contract
     * @param _users list of lockers from old contract
     * @param _amounts list of amounts each equal to the share of locker on old contract
     */
    function migrationLock(address[] memory _users, uint256[] memory _amounts) external onlyRole(DEFAULT_ADMIN_ROLE){
        for(uint i = 0; i < _users.length; i++){
            Locker storage locker = _lockers[_users[i]];

            if (totalLocked > 0) {
                update();
            }

            locker.rewardDebt =
                locker.rewardDebt +
                ((_amounts[i] * tokensPerLock) / 1e20);
            totalLocked = totalLocked + _amounts[i];
            locker.amount = _amounts[i];
            locker.depositUnlockTime = block.timestamp + depositLockDuration;

            cvxDistributor.receiveStakeInfo(_users[i], _amounts[i]);

            emit TokensLocked(_users[i], address(0), _amounts[i], block.timestamp);
            emit Transfer(address(0), _users[i], _amounts[i]);
        }
    }

    /// @notice Migrate withdraw or claim debt for users who did not have vlAlluo from previous version
    /// @param _users user addresses to migrate
    /// @param _withdraw true if migrating withdrawals, false for claim
    function migrateWithdrawOrClaimValues(address[] memory _users, bool _withdraw) external onlyRole(DEFAULT_ADMIN_ROLE) {
        IAlluoLockedV3 oldLocker = IAlluoLockedV3(0xF295EE9F1FA3Df84493Ae21e08eC2e1Ca9DebbAf);

        for (uint256 i = 0; i < _users.length; i++) {
            address user = _users[i];

            (
                uint256 locked_,
                uint256 unlockAmount_,
                uint256 claim_,
                ,
                uint256 withdrawUnlockTime_
            ) = oldLocker.getInfoByAddress(user);

            if (_withdraw && withdrawUnlockTime_ < block.timestamp) {
                oldWithdraw[user] = unlockAmount_;
            } 
            else if (!_withdraw) {
                require(locked_ == 0, "AlluoLockedV4: use migrationLock");
                oldClaim[user] = claim_;
            } 
        }
    }

    /**
     * @dev Unbinds specified amount of tokens
     * @param _amount An amount to unbid
     */
    function unlock(uint256 _amount) public {
        Locker storage locker = _lockers[msg.sender];

        require(
            locker.depositUnlockTime <= block.timestamp,
            "Locking: tokens not available"
        );

        require(
            locker.amount >= _amount,
            "Locking: not enough lp tokens" 
        );

        update();

        locker.rewardAllowed =
            locker.rewardAllowed +
            ((_amount * tokensPerLock) / 1e20);
        locker.amount -= _amount;
        totalLocked -= _amount;

        waitingForWithdrawal += _amount;

        locker.unlockAmount += _amount;
        locker.withdrawUnlockTime = block.timestamp + withdrawLockDuration;

        emit TokensUnlocked(msg.sender, _amount, block.timestamp);
        emit Transfer(msg.sender, address(0), _amount);

        cvxDistributor.receiveUnstakeInfo(msg.sender, _amount);
    }

    /**
     * @dev Unbinds all amount
     */
    function unlockAll() public {
        Locker storage locker = _lockers[msg.sender];

        require(
            locker.depositUnlockTime <= block.timestamp,
            "Locking: tokens not available"
        );

        uint256 amount = locker.amount;

        require(amount > 0, "Locking: not enough lp tokens");

        update();

        locker.rewardAllowed =
            locker.rewardAllowed +
            ((amount * tokensPerLock) / 1e20);
        locker.amount = 0;
        totalLocked -= amount;

        waitingForWithdrawal += amount;

        locker.unlockAmount += amount;
        locker.withdrawUnlockTime = block.timestamp + withdrawLockDuration;

        emit TokensUnlocked(msg.sender, amount, block.timestamp);
        emit Transfer(msg.sender, address(0), amount);

        cvxDistributor.receiveUnstakeInfo(msg.sender, amount);
    }

    /**
     * @dev Unlocks unbinded tokens and transfers them to locker's address
     */
    function withdraw() public whenNotPaused {
        Locker storage locker = _lockers[msg.sender];
        uint256 _oldWithdraw = oldWithdraw[msg.sender];

        if(_oldWithdraw != 0) {
            alluoToken.safeTransfer(msg.sender, _oldWithdraw);
            emit TokensWithdrawed(msg.sender, _oldWithdraw, block.timestamp);
            oldWithdraw[msg.sender] = 0;

            // to avoid tx revert, if there is no current unlocked amount
            if (locker.unlockAmount == 0 || block.timestamp >= locker.withdrawUnlockTime) {
                return;
            }
        }

        require(
            locker.unlockAmount > 0,
            "Locking: not enough tokens"
        );

        require(
            block.timestamp >= locker.withdrawUnlockTime,
            "Locking: tokens not available"
        );

        uint256 amount = locker.unlockAmount;
        locker.unlockAmount = 0;
        waitingForWithdrawal -= amount;

        alluoToken.safeTransfer(msg.sender, amount);
        emit TokensWithdrawed(msg.sender, amount, block.timestamp);
    }

    /**
     * @dev Сlaims available rewards
     */
    function claim() public {
        if (totalLocked > 0) {
            update();
        }

        uint256 reward = calcReward(msg.sender, tokensPerLock);
        uint256 oldReward = oldClaim[msg.sender];

        if (oldReward > 0) {
            alluoToken.safeTransfer(msg.sender, oldReward);
            emit TokensClaimed(msg.sender, oldReward, block.timestamp);
            oldClaim[msg.sender] = 0;

            // to avoid tx revert, if there is no current claim amount
            if (reward == 0) {
                return;
            }
        }

        // require(reward > 0, "Locking: Nothing to claim");
        if (reward > 0) {
            Locker storage locker = _lockers[msg.sender];

            locker.distributed = locker.distributed + reward;
            totalDistributed += reward;

            alluoToken.safeTransfer(msg.sender, reward);
            emit TokensClaimed(msg.sender, reward, block.timestamp);
        }

        cvxDistributor.claim(msg.sender);
    }

    /**
     * @dev Сalculates available reward
     * @param _locker Address of the locker
     * @param _tpl Tokens per lock parameter
     */
    function calcReward(address _locker, uint256 _tpl)
        private
        view
        returns (uint256 reward)
    {
        Locker storage locker = _lockers[_locker];

        reward =
            ((locker.amount * _tpl) / 1e20) +
            locker.rewardAllowed -
            locker.distributed -
            locker.rewardDebt;

        return reward;
    }

    /**
     * @dev Returns locker's available rewards
     * @param _locker Address of the locker
     * @return reward Available reward to claim
     */
    function getClaim(address _locker) public view returns (uint256 reward) {
        uint256 _tpl = tokensPerLock;
        if (totalLocked > 0) {
            uint256 rewardProducedAtNow = produced();
            if (rewardProducedAtNow > rewardProduced) {
                uint256 producedNew = rewardProducedAtNow - rewardProduced;
                _tpl = _tpl + ((producedNew * 1e20) / totalLocked);
            }
        }
        reward = calcReward(_locker, _tpl);

        return reward;
    }

    /**
     * @dev Returns locker's available CVX rewards
     * @param locker Address of the locker
     * @return reward Available CVX reward to claim
     */
    function getClaimCvx(address locker) public view returns (uint256 reward) {
        return cvxDistributor.getClaim(locker);
    }

    /**
     * @dev Returns balance of the specified locker
     * @param _address Locker's address
     * @return amount of vote/locked tokens
     */
    function balanceOf(address _address)
        external
        view
        returns (uint256 amount)
    {
        return _lockers[_address].amount;
    }

    /**
     * @dev Returns unlocked balance of the specified locker
     * @param _address Locker's address
     * @return amount of unlocked tokens
     */
    function unlockedBalanceOf(address _address)
        external
        view
        returns (uint256 amount)
    {
        return _lockers[_address].unlockAmount;
    }

    /**
     * @dev Returns total amount of locked tokens (in lp)
     * @return amount of locked 
     */
    function totalSupply() external view returns (uint256 amount) {
        return totalLocked;
    }

    /**
     * @dev Returns information about the specified locker
     * @param _address Locker's address
     * @return locked_ Locked amount of tokens (in lp)
     * @return unlockAmount_ Unlocked amount of tokens (in Alluo)
     * @return claim_  Reward amount available to be claimed
     * @return claimCvx_  Reward amount of CVX LP available to be claimed
     * @return depositUnlockTime_ Timestamp when tokens will be available to unlock
     * @return withdrawUnlockTime_ Timestamp when tokens will be available to withdraw
     */
    function getInfoByAddress(address _address)
        external
        view
        returns (
            uint256 locked_,
            uint256 unlockAmount_,
            uint256 claim_,
            uint256 claimCvx_,
            uint256 depositUnlockTime_,
            uint256 withdrawUnlockTime_
        )
    {
        Locker memory locker = _lockers[_address];
        locked_ = locker.amount;
        unlockAmount_ = locker.unlockAmount;
        depositUnlockTime_ = locker.depositUnlockTime;
        withdrawUnlockTime_ = locker.withdrawUnlockTime;
        claim_ = getClaim(_address);
        claimCvx_ = cvxDistributor.getClaim(_address);

        return (
            locked_,
            unlockAmount_,
            claim_,
            claimCvx_,
            depositUnlockTime_,
            withdrawUnlockTime_
        );
    }

    /* ========== ADMIN CONFIGURATION ========== */

    ///@dev Pauses the locking
    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    ///@dev Unpauses the locking
    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    /**
     * @dev Adds reward tokens to the contract
     * @param _amount Specifies the amount of tokens to be transferred to the contract
     */
    function addReward(uint256 _amount) external {
        alluoToken.safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );
    }

    /**
     * @dev Sets amount of reward during `distributionTime`
     * @param _amount Sets total reward amount per `distributionTime`
     */
    function setReward(uint256 _amount) 
        external 
        onlyRole(DEFAULT_ADMIN_ROLE) 
    {
        allProduced = produced();
        producedTime = block.timestamp;
        rewardPerDistribution = _amount;
        emit RewardAmountUpdated(_amount, allProduced);
    }

    /**
     * @dev Allows to update the time when the rewards are available to unlock
     * @param _depositLockDuration Date in unix timestamp format
     */
    function updateDepositLockDuration(uint256 _depositLockDuration)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        depositLockDuration = _depositLockDuration;
        emit DepositLockDurationUpdated(_depositLockDuration, block.timestamp);
    }
    
    /**
     * @dev Allows to update the time when the rewards are available to withdraw
     * @param _withdrawLockDuration Date in unix timestamp format
     */
    function updateWithdrawLockDuration(uint256 _withdrawLockDuration)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        withdrawLockDuration = _withdrawLockDuration;
        emit WithdrawLockDurationUpdated(_withdrawLockDuration, block.timestamp);
    }

    function withdrawTokens(
        address withdrawToken,
        address to,
        uint256 amount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {

        IERC20Upgradeable(withdrawToken).safeTransfer(to, amount);
    }

    /**
     * @dev allows and prohibits to upgrade contract
     * @param _status flag for allowing upgrade from gnosis
     */
    function changeUpgradeStatus(bool _status)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        upgradeStatus = _status;
    }

    /**
     * @dev Set CVX rewards manager contract address
     * @param cvxDistributorAddress contract address
     */
    function setCvxDistributor(address cvxDistributorAddress)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        cvxDistributor = CvxDistributor(cvxDistributorAddress);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(UPGRADER_ROLE)
    { 
        require(upgradeStatus, "Locking: upgrade not allowed");
        upgradeStatus = false;
    } 
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IAlluoLockedV3 {
    function DEFAULT_ADMIN_ROLE() external view returns (bytes32);

    function UPGRADER_ROLE() external view returns (bytes32);

    function _lockers(address)
        external
        view
        returns (
            uint256 amount,
            uint256 rewardAllowed,
            uint256 rewardDebt,
            uint256 distributed,
            uint256 unlockAmount,
            uint256 depositUnlockTime,
            uint256 withdrawUnlockTime
        );

    function addReward(uint256 _amount) external;

    function alluoBalancerLp() external view returns (address);

    function alluoToken() external view returns (address);

    function balanceOf(address _address) external view returns (uint256 amount);

    function balancer() external view returns (address);

    function changeUpgradeStatus(bool _status) external;

    function claim() external;

    function convertAlluoToLp(uint256 _amount) external view returns (uint256);

    function convertLpToAlluo(uint256 _amount) external view returns (uint256);

    function decimals() external view returns (uint8);

    function depositLockDuration() external view returns (uint256);

    function distributionTime() external view returns (uint256);

    function exchange() external view returns (address);

    function getClaim(address _locker) external view returns (uint256 reward);

    function getInfoByAddress(address _address)
        external
        view
        returns (
            uint256 locked_,
            uint256 unlockAmount_,
            uint256 claim_,
            uint256 depositUnlockTime_,
            uint256 withdrawUnlockTime_
        );

    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    function grantRole(bytes32 role, address account) external;

    function hasRole(bytes32 role, address account)
        external
        view
        returns (bool);

    function initialize(address _multiSigWallet, uint256 _rewardPerDistribution)
        external;

    function lock(uint256 _amount) external;

    function lockWETH(uint256 _amount) external;

    function migrationLock(address[] memory _users, uint256[] memory _amounts)
        external;

    function name() external view returns (string memory);

    function pause() external;

    function paused() external view returns (bool);

    function poolId() external view returns (bytes32);

    function proxiableUUID() external view returns (bytes32);

    function renounceRole(bytes32 role, address account) external;

    function revokeRole(bytes32 role, address account) external;

    function rewardPerDistribution() external view returns (uint256);

    function setReward(uint256 _amount) external;

    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    function symbol() external view returns (string memory);

    function totalDistributed() external view returns (uint256);

    function totalLocked() external view returns (uint256);

    function totalSupply() external view returns (uint256 amount);

    function unlock(uint256 _amount) external;

    function unlockAll() external;

    function unlockedBalanceOf(address _address)
        external
        view
        returns (uint256 amount);

    function unpause() external;

    function update() external;

    function updateDepositLockDuration(uint256 _depositLockDuration) external;

    function updateWithdrawLockDuration(uint256 _withdrawLockDuration) external;

    function upgradeStatus() external view returns (bool);

    function upgradeTo(address newImplementation) external;

    function upgradeToAndCall(address newImplementation, bytes memory data)
        external;

    function waitingForWithdrawal() external view returns (uint256);

    function weth() external view returns (address);

    function withdraw() external;

    function withdrawLockDuration() external view returns (uint256);

    function withdrawTokens(
        address withdrawToken,
        address to,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IExchange{
    struct RouteEdge {
        uint32 swapProtocol; // 0 - unknown edge, 1 - UniswapV2, 2 - Curve...
        address pool; // address of pool to call
        address fromCoin; // address of coin to deposit to pool
        address toCoin; // address of coin to get from pool
    }

    function exchange(
        address from,
        address to,
        uint256 amountIn,
        uint256 minAmountOut
    ) external payable returns (uint256);

     function buildRoute(address from, address to)
        external
        view
        returns (RouteEdge[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./IBalancerStructs.sol";

interface IBalancer is IBalancerStructs {
    function swap(
        SingleSwap memory singleSwap,
        FundManagement memory funds,
        uint256 limit,
        uint256 deadline
    ) external payable returns (uint256 amountCalculated);

    function joinPool(
        bytes32 poolId,
        address sender,
        address recipient,
        JoinPoolRequest memory request
    ) external payable;

    function getPoolTokens(bytes32 poolId)
        external
        view
        returns (
            address[] memory tokens,
            uint256[] memory balances,
            uint256 lastChangeBlock
        );

    function exitPool(
        bytes32 poolId,
        address sender,
        address payable recipient,
        ExitPoolRequest memory request
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import "./../interfaces/curve/mainnet/ICvxBooster.sol";
import "./../interfaces/curve/mainnet/ICvxBaseRewardPool.sol";
import "../interfaces/IExchange.sol";
import "./../interfaces/curve/mainnet/ICurveCVXETH.sol";

contract CvxDistributor is
    Initializable,
    UUPSUpgradeable,
    AccessControlUpgradeable
{
    using SafeERC20Upgradeable for IERC20MetadataUpgradeable;

    bytes32 public constant PROTOCOL_ROLE = keccak256("PROTOCOL_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    uint256 public constant distributionTime = 14 days;

    IERC20MetadataUpgradeable public constant crvCVXETH =
        IERC20MetadataUpgradeable(0x3A283D9c08E8b55966afb64C515f5143cf907611);
    IERC20MetadataUpgradeable public constant cvxRewards =
        IERC20MetadataUpgradeable(0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B);
    IERC20MetadataUpgradeable public constant crvRewards =
        IERC20MetadataUpgradeable(0xD533a949740bb3306d119CC777fa900bA034cd52);
    IERC20MetadataUpgradeable public constant WETH =
        IERC20MetadataUpgradeable(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    ICvxBooster public constant cvxBooster =
        ICvxBooster(0xF403C135812408BFbE8713b5A23a04b3D48AAE31);
    ICurveCVXETH public constant CurveCVXETH =
        ICurveCVXETH(0xB576491F1E6e5E62f1d8F26062Ee822B40B0E0d4);
    uint256 public constant crvCVXETHPoolId = 64;

    ///@dev Stakers info by token holders.
    mapping(address => Staker) public _stakers;

    // Staker contains info related to each staker.
    struct Staker {
        uint256 amount; // tokens currently staked to the contract
        uint256 rewardAllowed; // rewards allowed to be paid out
        uint256 rewardDebt; // param is needed for correct calculation staker's share
        uint256 distributed; // amount of distributed tokens
    }

    struct RewardData {
        address token;
        uint256 amount;
    }
    
    ///@dev ERC20 token earned by stakers as reward.
    IERC20MetadataUpgradeable public rewardToken;

    // Locking's reward amount produced per distribution time.
    uint256 public rewardTotal;

    // Auxiliary parameter (tpl) for locking's math
    uint256 public tokensPerStake;
    // Аuxiliary parameter for locking's math
    uint256 public rewardProduced;
    // Аuxiliary parameter for locking's math
    uint256 public allProduced;
    // Аuxiliary parameter for locking's math
    uint256 public producedTime;

    // Amount of currently locked tokens from all users (in lp).
    uint256 public totalStaked;
    // Amount of currently claimed rewards by the users (in CVX-ETH LP).
    uint256 public totalDistributed;

    // flag for upgrades availability
    bool public upgradeStatus;

    // Convex rewards pool
    ICvxBaseRewardPool rewards;

    // Alluo exchange address
    address public exchangeAddress;

    /**
     * @dev Emitted in `receiveStakeInfo` when the user locked the tokens
     */
    event StakeInfoReceived(
        uint256 amount,
        uint256 time,
        address indexed sender
    );

    /**
     * @dev Emitted in `claim` when the user claimed his reward tokens
     */
    event CvxClaimed(uint256 amount, uint256 time, address indexed sender);
    
    /**
     * @dev Emitted in `receiveUnstakeInfo` when the user unbinded his locked tokens
     */
    event UnstakeInfoReceived(
        uint256 amount,
        uint256 time,
        address indexed sender
    );

    /**
     * @dev Emitted in `setReward` when the new rewardPerDistribution was set
     */
    event RewardAmountUpdated(uint256 amount, uint256 produced);

    /**
     * @dev Contract constructor without parameters
     */
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    /**
     * @dev Contract initializer 
     */
    function initialize(
        address _multiSigWallet,
        address vlAlluo,
        address rewardTokenAddress,
        address _exchangeAddress
    ) public initializer {
        __AccessControl_init();
        __UUPSUpgradeable_init();

        producedTime = block.timestamp;
        rewardToken = IERC20MetadataUpgradeable(rewardTokenAddress);

        _setupRole(PROTOCOL_ROLE, vlAlluo);
        _setupRole(DEFAULT_ADMIN_ROLE, _multiSigWallet);

        rewards = getCvxRewardPool(crvCVXETHPoolId);
        exchangeAddress = _exchangeAddress;

        crvRewards.safeApprove(exchangeAddress, type(uint256).max);

        crvCVXETH.approve(address(cvxBooster), type(uint256).max);

        cvxRewards.safeApprove(address(CurveCVXETH), type(uint256).max);
        WETH.safeApprove(address(CurveCVXETH), type(uint256).max);
    }

    /**
     * @dev Receive info about user token locking event. Should be called by AlluoLocked contract
     * @param user User who locked tokens
     * @param _amount An amount of Alluo locked
     */
    function receiveStakeInfo(address user, uint256 _amount)
        external
        onlyRole(PROTOCOL_ROLE)
    {
        Staker storage staker = _stakers[user];

        if (totalStaked > 0) {
            update();
        }
        staker.rewardDebt =
            staker.rewardDebt +
            ((_amount * tokensPerStake) / 1e20);

        totalStaked = totalStaked + _amount;
        staker.amount = staker.amount + _amount;

        emit StakeInfoReceived(_amount, block.timestamp, user);
    }

    /**
     * @dev Receive info about user token unlocking event. Should be called by AlluoLocked contract
     * @param user User who unlocked tokens
     * @param _amount An amount of Alluo unlocked
     */
    function receiveUnstakeInfo(address user, uint256 _amount)
        external
        onlyRole(PROTOCOL_ROLE)
    {
        Staker storage staker = _stakers[user];

        update();

        staker.rewardAllowed =
            staker.rewardAllowed +
            ((_amount * tokensPerStake) / 1e20);
        staker.amount = staker.amount - _amount;
        totalStaked = totalStaked - _amount;

        emit UnstakeInfoReceived(_amount, block.timestamp, user);
    }

    /**
     * @dev Сlaims available rewards for user. Should be called by AlluoLocked contract
     * @param user User to claim for
     */
    function claim(address user) external onlyRole(PROTOCOL_ROLE) {
        if (totalStaked > 0) {
            update();
        }

        uint256 reward = calcReward(user, tokensPerStake);
        if (reward == 0) {
            return;
        }
        Staker storage staker = _stakers[user];

        staker.distributed = staker.distributed + reward;
        totalDistributed = totalDistributed + reward;

        rewards.withdrawAndUnwrap(reward, false);

        uint256 rewardPure = CurveCVXETH.remove_liquidity_one_coin(
            reward,
            1,
            0,
            false
        );

        cvxRewards.safeTransfer(user, rewardPure);
        emit CvxClaimed(reward, block.timestamp, user);
    }

    /**
     * @dev Receive information about incoming CVX-ETH LP tokens that have to be distributed to lockers
     * @param _amount Amount on LP tokens received
     */
    function receiveReward(uint256 _amount) external onlyRole(PROTOCOL_ROLE) {
        _amount += getRewards();
        allProduced = produced();
        producedTime = block.timestamp;
        rewardTotal = _amount;

        cvxBooster.deposit(crvCVXETHPoolId, _amount, true);

        emit RewardAmountUpdated(_amount, allProduced);
    }

    /**
     * @dev Deposit LP tokens to Convex pool
     * @param _amount Amount on LP tokens received
     */
    function forceDeposit(uint256 _amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        cvxBooster.deposit(crvCVXETHPoolId, _amount, true);
    }

    /**
     * @dev Withdraw LP tokens from Convex pool
     * @param _amount Amount on LP tokens to get
     */
    function forceWithdraw(uint256 _amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        rewards.withdrawAndUnwrap(_amount, false);
    }

    /**
     * @dev Claim contract available rewards and re-invest them into Convex pools
     */
    function forceClaimCycle() external onlyRole(DEFAULT_ADMIN_ROLE) {
        getRewards();
    }

    /**
     * @dev Сalculates available reward
     * @param _staker Address of the locker
     * @param _tps Tokens per lock parameter
     */
    function calcReward(address _staker, uint256 _tps)
        private
        view
        returns (uint256 reward)
    {
        Staker storage staker = _stakers[_staker];

        reward =
            ((staker.amount * _tps) / 1e20) +
            staker.rewardAllowed -
            staker.distributed -
            staker.rewardDebt;

        return reward;
    }

    /**
     * @dev Calculates the necessary parameters for staking
     * @return Totally produced rewards
     */
    function produced() private view returns (uint256) {
        uint256 timePassed = (block.timestamp - producedTime);
        if (timePassed > distributionTime) {
            timePassed = distributionTime;
        }
        return
            allProduced +
            (rewardTotal * timePassed) /
            distributionTime;
    }

    /**
     * @dev Returns staker's available rewards
     * @param _staker Address of the staker
     * @return reward Available reward to claim
     */
    function getClaim(address _staker) public view returns (uint256 reward) {
        uint256 _tps = tokensPerStake;
        if (totalStaked > 0) {
            uint256 rewardProducedAtNow = produced();
            if (rewardProducedAtNow > rewardProduced) {
                uint256 producedNew = rewardProducedAtNow - rewardProduced;
                _tps = _tps + ((producedNew * 1e20) / totalStaked);
            }
        }
        uint256 rewardLp = calcReward(_staker, _tps);

        return
            rewardLp == 0 ? 0 : CurveCVXETH.calc_withdraw_one_coin(rewardLp, 1);
    }

    /**
     * @dev Updates the produced rewards parameter for staking
     */
    function update() public onlyRole(PROTOCOL_ROLE) {
        uint256 rewardProducedAtNow = produced();
        if (rewardProducedAtNow > rewardProduced) {
            uint256 producedNew = rewardProducedAtNow - rewardProduced;
            if (totalStaked > 0) {
                tokensPerStake =
                    tokensPerStake +
                    (producedNew * 1e20) /
                    totalStaked;
            }
            rewardProduced = rewardProduced + producedNew;
        }
    }

    /**
     * @dev allows and prohibits to upgrade contract
     * @param _status flag for allowing upgrade from gnosis
     */
    function changeUpgradeStatus(bool _status)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        upgradeStatus = _status;
    }

    /**
     * @dev admin function for adding/changing exchange address
     * @param _exchangeAddress new exchange address
     */
    function addExchange(address _exchangeAddress)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        exchangeAddress = _exchangeAddress;
    }

    function withdrawTokens(
        address withdrawToken,
        address to,
        uint256 amount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        IERC20MetadataUpgradeable(withdrawToken).safeTransfer(to, amount);
    }

    function _authorizeUpgrade(address)
        internal
        override
        onlyRole(UPGRADER_ROLE)
    {
        require(upgradeStatus, "Upgrade !allowed");
        upgradeStatus = false;
    }

    function getRewards() private returns (uint256) {
        rewards.getReward(address(this), true);

        uint256 crvAmount = crvRewards.balanceOf(address(this));
        uint256 cvxAmount = cvxRewards.balanceOf(address(this));

        uint256 wethReceived;

        if (crvAmount > 0) {
            wethReceived = IExchange(exchangeAddress).exchange(
                address(crvRewards),
                address(WETH),
                crvAmount,
                0
            );
        }

        if (crvAmount > 0 || cvxAmount > 0) {
            return CurveCVXETH.add_liquidity([wethReceived, cvxAmount], 0);
        } else {
            return 0;
        }
    }

    function accruedRewards() public view returns (RewardData[] memory) {
        (, , , address pool, , ) = cvxBooster.poolInfo(crvCVXETHPoolId);
        ICvxBaseRewardPool mainCvxPool = ICvxBaseRewardPool(pool);
        uint256 extraRewardsLength = mainCvxPool.extraRewardsLength();
        RewardData[] memory rewardArray = new RewardData[](extraRewardsLength + 1);
        rewardArray[0] = RewardData(mainCvxPool.rewardToken(),mainCvxPool.earned(address(this)));
        for (uint256 i; i < extraRewardsLength; i++) {
            ICvxBaseRewardPool extraReward = ICvxBaseRewardPool(mainCvxPool.extraRewards(i));

            rewardArray[i+1] = (RewardData(extraReward.rewardToken(), extraReward.earned(address(this))));
        }
        return rewardArray;
    }

    function stakerAccruedRewards(address _staker) public view returns (RewardData[] memory) {
        RewardData[] memory accruals = accruedRewards();
        Staker memory staker = _stakers[_staker];

        uint256 stakerAmount = staker.amount;
        uint256 totalStakedAmount = totalStaked;

        for (uint256 i; i < accruals.length; i++) {
            uint256 stakerShareOfaccruals = accruals[i].amount * stakerAmount / totalStakedAmount;
            accruals[i].amount = stakerShareOfaccruals;
        }

        return (accruals);
    }

    function getCvxRewardPool(uint256 poolId)
        private
        view
        returns (ICvxBaseRewardPool)
    {
        (, , , address pool, , ) = cvxBooster.poolInfo(poolId);
        return ICvxBaseRewardPool(pool);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate that the this implementation remains valid after an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20PermitUpgradeable token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IBalancerStructs {
    enum SwapKind {
        GIVEN_IN,
        GIVEN_OUT
    }

    enum JoinKind {
        INIT,
        EXACT_TOKENS_IN_FOR_BPT_OUT,
        TOKEN_IN_FOR_EXACT_BPT_OUT,
        ALL_TOKENS_IN_FOR_EXACT_BPT_OUT
    }

    enum ExitKind {
        EXACT_BPT_IN_FOR_ONE_TOKEN_OUT,
        EXACT_BPT_IN_FOR_TOKENS_OUT,
        BPT_IN_FOR_EXACT_TOKENS_OUT,
        MANAGEMENT_FEE_TOKENS_OUT // for InvestmentPool
    }

    struct SingleSwap {
        bytes32 poolId;
        SwapKind kind;
        address assetIn;
        address assetOut;
        uint256 amount;
        bytes userData;
    }

    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address payable recipient;
        bool toInternalBalance;
    }

    struct JoinPoolRequest {
        address[] assets;
        uint256[] maxAmountsIn;
        bytes userData;
        bool fromInternalBalance;
    }

    struct ExitPoolRequest {
        address[] assets;
        uint256[] minAmountsOut;
        bytes userData;
        bool toInternalBalance;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

// Interface from ABI of
// https://etherscan.io/address/0xF403C135812408BFbE8713b5A23a04b3D48AAE31
// Built with https://bia.is/tools/abi2solidity/

// solhint-disable func-name-mixedcase

interface ICvxBooster {
    function FEE_DENOMINATOR() external view returns (uint256);

    function MaxFees() external view returns (uint256);

    function addPool(
        address _lptoken,
        address _gauge,
        uint256 _stashVersion
    ) external returns (bool);

    function claimRewards(uint256 _pid, address _gauge) external returns (bool);

    function crv() external view returns (address);

    function deposit(
        uint256 _pid,
        uint256 _amount,
        bool _stake
    ) external returns (bool);

    function depositAll(uint256 _pid, bool _stake) external returns (bool);

    function distributionAddressId() external view returns (uint256);

    function earmarkFees() external returns (bool);

    function earmarkIncentive() external view returns (uint256);

    function earmarkRewards(uint256 _pid) external returns (bool);

    function feeDistro() external view returns (address);

    function feeManager() external view returns (address);

    function feeToken() external view returns (address);

    function gaugeMap(address) external view returns (bool);

    function isShutdown() external view returns (bool);

    function lockFees() external view returns (address);

    function lockIncentive() external view returns (uint256);

    function lockRewards() external view returns (address);

    function minter() external view returns (address);

    function owner() external view returns (address);

    function platformFee() external view returns (uint256);

    function poolInfo(uint256)
        external
        view
        returns (
            address lptoken,
            address token,
            address gauge,
            address crvRewards,
            address stash,
            bool shutdown
        );

    function poolLength() external view returns (uint256);

    function poolManager() external view returns (address);

    function registry() external view returns (address);

    function rewardArbitrator() external view returns (address);

    function rewardClaimed(
        uint256 _pid,
        address _address,
        uint256 _amount
    ) external returns (bool);

    function rewardFactory() external view returns (address);

    function setArbitrator(address _arb) external;

    function setFactories(
        address _rfactory,
        address _sfactory,
        address _tfactory
    ) external;

    function setFeeInfo() external;

    function setFeeManager(address _feeM) external;

    function setFees(
        uint256 _lockFees,
        uint256 _stakerFees,
        uint256 _callerFees,
        uint256 _platform
    ) external;

    function setGaugeRedirect(uint256 _pid) external returns (bool);

    function setOwner(address _owner) external;

    function setPoolManager(address _poolM) external;

    function setRewardContracts(address _rewards, address _stakerRewards)
        external;

    function setTreasury(address _treasury) external;

    function setVoteDelegate(address _voteDelegate) external;

    function shutdownPool(uint256 _pid) external returns (bool);

    function shutdownSystem() external;

    function staker() external view returns (address);

    function stakerIncentive() external view returns (uint256);

    function stakerRewards() external view returns (address);

    function stashFactory() external view returns (address);

    function tokenFactory() external view returns (address);

    function treasury() external view returns (address);

    function vote(
        uint256 _voteId,
        address _votingAddress,
        bool _support
    ) external returns (bool);

    function voteDelegate() external view returns (address);

    function voteGaugeWeight(address[] memory _gauge, uint256[] memory _weight)
        external
        returns (bool);

    function voteOwnership() external view returns (address);

    function voteParameter() external view returns (address);

    function withdraw(uint256 _pid, uint256 _amount) external returns (bool);

    function withdrawAll(uint256 _pid) external returns (bool);

    function withdrawTo(
        uint256 _pid,
        uint256 _amount,
        address _to
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

// Interface from ABI of
// https://etherscan.io/address/0xB900EF131301B307dB5eFcbed9DBb50A3e209B2e
// Built with https://bia.is/tools/abi2solidity/

interface ICvxBaseRewardPool {
    function addExtraReward(address _reward) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function clearExtraRewards() external;

    function currentRewards() external view returns (uint256);

    function donate(uint256 _amount) external returns (bool);

    function duration() external view returns (uint256);

    function earned(address account) external view returns (uint256);

    function extraRewards(uint256) external view returns (address);

    function extraRewardsLength() external view returns (uint256);

    function getReward() external returns (bool);

    function getReward(address _account, bool _claimExtras)
        external
        returns (bool);

    function historicalRewards() external view returns (uint256);

    function lastTimeRewardApplicable() external view returns (uint256);

    function lastUpdateTime() external view returns (uint256);

    function newRewardRatio() external view returns (uint256);

    function operator() external view returns (address);

    function periodFinish() external view returns (uint256);

    function pid() external view returns (uint256);

    function queueNewRewards(uint256 _rewards) external returns (bool);

    function queuedRewards() external view returns (uint256);

    function rewardManager() external view returns (address);

    function rewardPerToken() external view returns (uint256);

    function rewardPerTokenStored() external view returns (uint256);

    function rewardRate() external view returns (uint256);

    function rewardToken() external view returns (address);

    function rewards(address) external view returns (uint256);

    function stake(uint256 _amount) external returns (bool);

    function stakeAll() external returns (bool);

    function stakeFor(address _for, uint256 _amount) external returns (bool);

    function stakingToken() external view returns (address);

    function totalSupply() external view returns (uint256);

    function userRewardPerTokenPaid(address) external view returns (uint256);

    function withdraw(uint256 amount, bool claim) external returns (bool);

    function withdrawAll(bool claim) external;

    function withdrawAllAndUnwrap(bool claim) external;

    function withdrawAndUnwrap(uint256 amount, bool claim)
        external
        returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ICurveCVXETH {
    function token() external view returns (address);

    function coins(uint256 i) external view returns (address);

    function A() external view returns (uint256);

    function gamma() external view returns (uint256);

    function fee() external view returns (uint256);

    function get_virtual_price() external view returns (uint256);

    function exchange(
        uint256 i,
        uint256 j,
        uint256 dx,
        uint256 min_dy
    ) external returns (uint256);

    function exchange(
        uint256 i,
        uint256 j,
        uint256 dx,
        uint256 min_dy,
        bool use_eth
    ) external returns (uint256);

    function exchange_underlying(
        uint256 i,
        uint256 j,
        uint256 dx,
        uint256 min_dy
    ) external returns (uint256);

    function get_dy(
        uint256 i,
        uint256 j,
        uint256 dx
    ) external view returns (uint256);

    function add_liquidity(uint256[2] memory amounts, uint256 min_mint_amount)
        external
        returns (uint256);

    function add_liquidity(
        uint256[2] memory amounts,
        uint256 min_mint_amount,
        bool use_eth
    ) external returns (uint256);

    function remove_liquidity(uint256 _amount, uint256[2] memory min_amounts)
        external;

    function remove_liquidity(
        uint256 _amount,
        uint256[2] memory min_amounts,
        bool use_eth
    ) external;

    function calc_token_amount(uint256[2] memory amounts)
        external
        view
        returns (uint256);

    function calc_withdraw_one_coin(uint256 token_amount, uint256 i)
        external
        view
        returns (uint256);

    function remove_liquidity_one_coin(
        uint256 token_amount,
        uint256 i,
        uint256 min_amount
    ) external returns (uint256);

    function remove_liquidity_one_coin(
        uint256 token_amount,
        uint256 i,
        uint256 min_amount,
        bool use_eth
    ) external returns (uint256);

    function claim_admin_fees() external;

    function ramp_A_gamma(
        uint256 future_A,
        uint256 future_gamma,
        uint256 future_time
    ) external;

    function stop_ramp_A_gamma() external;

    function commit_new_parameters(
        uint256 _new_mid_fee,
        uint256 _new_out_fee,
        uint256 _new_admin_fee,
        uint256 _new_fee_gamma,
        uint256 _new_allowed_extra_profit,
        uint256 _new_adjustment_step,
        uint256 _new_ma_half_time
    ) external;

    function apply_new_parameters() external;

    function revert_new_parameters() external;

    function commit_transfer_ownership(address _owner) external;

    function apply_transfer_ownership() external;

    function revert_transfer_ownership() external;

    function kill_me() external;

    function unkill_me() external;

    function set_admin_fee_receiver(address _admin_fee_receiver) external;

    function lp_price() external view returns (uint256);

    function price_scale() external view returns (uint256);

    function price_oracle() external view returns (uint256);

    function last_prices() external view returns (uint256);

    function last_prices_timestamp() external view returns (uint256);

    function initial_A_gamma() external view returns (uint256);

    function future_A_gamma() external view returns (uint256);

    function initial_A_gamma_time() external view returns (uint256);

    function future_A_gamma_time() external view returns (uint256);

    function allowed_extra_profit() external view returns (uint256);

    function future_allowed_extra_profit() external view returns (uint256);

    function fee_gamma() external view returns (uint256);

    function future_fee_gamma() external view returns (uint256);

    function adjustment_step() external view returns (uint256);

    function future_adjustment_step() external view returns (uint256);

    function ma_half_time() external view returns (uint256);

    function future_ma_half_time() external view returns (uint256);

    function mid_fee() external view returns (uint256);

    function out_fee() external view returns (uint256);

    function admin_fee() external view returns (uint256);

    function future_mid_fee() external view returns (uint256);

    function future_out_fee() external view returns (uint256);

    function future_admin_fee() external view returns (uint256);

    function balances(uint256 arg0) external view returns (uint256);

    function D() external view returns (uint256);

    function owner() external view returns (address);

    function future_owner() external view returns (address);

    function xcp_profit() external view returns (uint256);

    function xcp_profit_a() external view returns (uint256);

    function virtual_price() external view returns (uint256);

    function is_killed() external view returns (bool);

    function kill_deadline() external view returns (uint256);

    function transfer_ownership_deadline() external view returns (uint256);

    function admin_actions_deadline() external view returns (uint256);

    function admin_fee_receiver() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20PermitUpgradeable {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}