// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "./openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "./openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./USBStakingFactory.sol";
import "./USBStaking.sol";


contract USBStakingYield is Initializable, PausableUpgradeable {

    using SafeERC20Upgradeable for ERC20Upgradeable;

    /**
     * @dev The USBStaking contract.
     */
    USBStaking public usbStaking;

    /** 
     * @dev address of yield reward token contract 
     */
    ERC20Upgradeable public yieldRewardToken;
   
    /**
     * @notice amount of reward token to be distribute for one block 
     * @dev [yieldRewardPerBlock]=yieldRewardToken/block
     */ 
    uint256 public yieldRewardPerBlock;

    /** 
     * @notice block number when staking starts
     * @dev [startBlock]=block
     */
    uint256 public startBlock;

    /**
     * @notice block number when staking ends
     * @dev [endBlock]=block
     */
    uint256 public endBlock;
   
    /**
     * @notice block number when latest reward was accrued
     * @dev [lastYieldRewardBlock]=block
     */
    uint256 public lastYieldRewardBlock;
    
    /**
     * @notice accumulated reward tokens per stake token. Accumulates with every update() call
     * @dev [accumulatedYieldRewardTokenPerStakeToken]=yieldRewardToken/stakeToken
     */
    uint256 public accumulatedYieldRewardTokenPerStakeToken;

    /**
     * @notice total pending reward token. If you want to get current pending reward call `getTotalPendingReward(0)`
     * @dev [totalPendingYieldReward]=rewardToken
     */
    uint256 public totalPendingYieldReward;

    /**
     * @notice total reward token claimed by stakers
     * @dev totalClaimedYieldReward = sum of all claimedReward by all users
     * @dev [totalClaimedYieldReward]=rewardToken
     */
    uint256 public totalClaimedYieldReward;
    
    /**
     * @notice user yield position
     * @dev user address => UserYieldPosition
     */
    mapping (address => UserYieldPosition) public userYieldPosition;

    struct UserYieldPosition {
        uint256 pendingYieldReward;
        uint256 claimedYieldReward;
        uint256 instantAccumulatedShareOfYieldReward;
    }

    event ClaimYieldReward(address indexed user, uint256 yieldRewardAmount);
    event SetYieldRewardPerBlock(uint256 yieldRewardPerBlock);
    event SetYieldPeriod(uint256 startBlock, uint256 endBlock);

    modifier onlyAdmin() {
        bytes32 adminRole = usbStaking.DEFAULT_ADMIN_ROLE();
        require(usbStaking.hasRole(adminRole, msg.sender), "USBStakingYield: Caller is not the Admin");
        _;
    }

    modifier onlyManager() {
        bytes32 managerRole = usbStaking.MANAGER_ROLE();
        require(usbStaking.hasRole(managerRole, msg.sender), "USBStakingYield: Caller is not the Manager");
        _;
    }

    modifier onlyUsbStaking() {
        require(msg.sender == address(usbStaking), "USBStakingYield: Caller is not the Manager");
        _;
    }

    /**
     * @dev initializer of USBStakingYield
     * @param _usbStaking address of usbStaking
     * @param _yieldRewardToken address of yield token
     * @param _initialYieldReward the amount of reward token to be initial reward
     * @param _yieldRewardPerBlock the amount of reward to be distributed for one block
     * @param _startBlock the block number when staking starts
     * @param _endBlock the block number when staking ends
     */
    function initialize(
        address _usbStaking,
        address _yieldRewardToken,
        uint256 _initialYieldReward,
        uint256 _yieldRewardPerBlock,
        uint256 _startBlock,
        uint256 _endBlock
    ) external initializer {
        __Pausable_init();

        usbStaking = USBStaking(_usbStaking);
        yieldRewardToken = ERC20Upgradeable(_yieldRewardToken);

        if(_initialYieldReward > 0) {
            yieldRewardToken.safeTransferFrom(msg.sender, address(this), _initialYieldReward);
        }

        _setYieldRewardPerBlock(_yieldRewardPerBlock);
        _setYieldPeriod(_startBlock, _endBlock);
    }

    //************* ADMIN FUNCTIONS *************//

    /**
     * @dev transfer any tokens from yield staking
     * @param _token address of token to be transferred
     * @param _recipient address of receiver of tokens
     * @param _amount amount of token to be transferred
     */
    function sweepTokens(address _token, address _recipient, uint256 _amount) external onlyAdmin {
        require(_amount > 0, "USBStaking: amount=0");
        ERC20Upgradeable(_token).safeTransfer(_recipient, _amount);
    }

    /**
     * @dev pause yield rewarding
     */
    function pause() external onlyAdmin {
        update();
        super._pause();
    }
   
    /**
     * @dev unpause yield rewarding
     */
    function unpause() external onlyAdmin {
        lastYieldRewardBlock = block.number;
        super._unpause();
    }

    //************* END ADMIN FUNCTIONS *************//
    //************* MANAGER FUNCTIONS *************//

    /**
     * @dev sets yield reward per block
     * @param _yieldRewardPerBlock amount of `yieldRewardToken` to be rewarded each block
     */
    function setYieldRewardPerBlock(uint256 _yieldRewardPerBlock) external onlyManager {
        _setYieldRewardPerBlock(_yieldRewardPerBlock);
    }

    /**
     * @dev sets yield reward per block
     * @param _yieldRewardPerBlock amount of `yieldRewardToken` to be rewarded each block
     */
    function _setYieldRewardPerBlock(uint256 _yieldRewardPerBlock) internal {
        update();
        yieldRewardPerBlock = _yieldRewardPerBlock;
        emit SetYieldRewardPerBlock(_yieldRewardPerBlock);
    }

    /**
     * @dev sets period of yield rewarding
     * @param _startBlock block number of start staking
     * @param _endBlock block number of end staking
     */
    function setYieldPeriod(uint256 _startBlock, uint256 _endBlock) external onlyManager {
        _setYieldPeriod(_startBlock, _endBlock);
    }

    /**
     * @dev sets period of yield rewarding
     * @param _startBlock block number of start staking
     * @param _endBlock block number of end staking
     */
    function _setYieldPeriod(uint256 _startBlock, uint256 _endBlock) internal {
        require(_startBlock < _endBlock, "USBStakingYield: should be startBlock<endBlock");
        startBlock = _startBlock;
        endBlock = _endBlock;
        emit SetYieldPeriod(_startBlock, _endBlock);
    }

    //************* END MANAGER FUNCTIONS *************//
    //************* MAIN FUNCTIONS *************//

    /**
     * @dev update the `accumulatedYieldRewardTokenPerStakeToken`
     */
    function update() public whenNotPaused {
        if (block.number <= lastYieldRewardBlock) {
            return;
        }
        uint256 totalStaked = usbStaking.totalStake();
        if (totalStaked == 0) {
            lastYieldRewardBlock = block.number;
            return;
        }
        uint256 rewardAmount = calculateTotalPendingYieldReward(0);
        uint256 accumulatorMultiplier = getAccumulatorMultiplier();
        accumulatedYieldRewardTokenPerStakeToken += rewardAmount * accumulatorMultiplier / totalStaked;
        totalPendingYieldReward += rewardAmount;
        lastYieldRewardBlock = block.number;
    }

    /**
     * @dev update the `pendingYieldReward`
     * @param user address of user
     */
    function updatePendingYieldReward(address user) external onlyUsbStaking {
        _updatePendingYieldReward(user);
    }

    /**
     * @dev update the `pendingYieldReward`
     * @param user address of user
     */
    function _updatePendingYieldReward(address user) internal {
        UserYieldPosition storage userYield = userYieldPosition[user];
        uint256 accumulatedShareOfYieldReward = getAccumulatedShareOfYieldReward(user);
        if (accumulatedShareOfYieldReward > userYield.instantAccumulatedShareOfYieldReward){
            userYield.pendingYieldReward += accumulatedShareOfYieldReward - userYield.instantAccumulatedShareOfYieldReward;
        }
    }
    
    /**
     * @dev update the `instantAccumulatedShareOfYieldReward`
     * @param user address of user
     */
    function updateInstantAccumulatedShareOfYieldReward(address user) external onlyUsbStaking {
        _updateInstantAccumulatedShareOfYieldReward(user);
    }
    
    /**
     * @dev update the `instantAccumulatedShareOfYieldReward`
     * @param user address of user
     */
    function _updateInstantAccumulatedShareOfYieldReward(address user) internal {
        userYieldPosition[user].instantAccumulatedShareOfYieldReward = getAccumulatedShareOfYieldReward(user);
    }

    /**
     * @notice claim the yield reward to `msg.sender`
     */
    function claimYieldReward() external whenNotPaused {
        update();
        _updatePendingYieldReward(msg.sender);
        _updateInstantAccumulatedShareOfYieldReward(msg.sender);
        UserYieldPosition storage userYield = userYieldPosition[msg.sender];
        uint256 pendingYieldReward = userYield.pendingYieldReward;
        if (pendingYieldReward > 0) {
            totalClaimedYieldReward += pendingYieldReward;
            userYield.claimedYieldReward += pendingYieldReward;
            userYield.pendingYieldReward = 0;
            _safeYieldRewardTokenTransfer(msg.sender, pendingYieldReward);
            emit ClaimYieldReward(msg.sender, pendingYieldReward);
        }
    }

    /**
     * @notice claim the yield reward to user address
     * @param beneficiary the address of user
     */
    function claimYieldRewardTo(address beneficiary) external onlyUsbStaking whenNotPaused {
        update();
        _updatePendingYieldReward(beneficiary);
        _updateInstantAccumulatedShareOfYieldReward(beneficiary);
        UserYieldPosition storage userYield = userYieldPosition[beneficiary];
        uint256 pendingYieldReward = userYield.pendingYieldReward;
        if (pendingYieldReward > 0) {
            totalClaimedYieldReward += pendingYieldReward;
            userYield.claimedYieldReward += pendingYieldReward;
            userYield.pendingYieldReward = 0;
            _safeYieldRewardTokenTransfer(beneficiary, pendingYieldReward);
            emit ClaimYieldReward(beneficiary, pendingYieldReward);
        }
    }

    /**
     * @dev internal transfer of yield reward token
     * @param beneficiar address of receiver
     * @param amount amount of reward token `beneficiar` will receive
     */
    function _safeYieldRewardTokenTransfer(address beneficiar, uint256 amount) internal {
        uint256 yieldTokenBalance = getYieldRewardTokenAmount();
        if (amount > yieldTokenBalance) {
            yieldRewardToken.safeTransfer(beneficiar, yieldTokenBalance);
            uint256 shortfall = amount - yieldTokenBalance;
            totalClaimedYieldReward -= shortfall;
            userYieldPosition[beneficiar].claimedYieldReward -= shortfall;
            userYieldPosition[beneficiar].pendingYieldReward += shortfall;
        } else {
            yieldRewardToken.safeTransfer(beneficiar, amount);
        }
    }
    
    //************* END MAIN FUNCTIONS *************//
    //************* VIEW FUNCTIONS *************//

    /**
     * @dev return the share of reward of `user` by his stake
     */
    function getAccumulatedShareOfYieldReward(address user) public view returns (uint256) {
        uint256 accumulatorMultiplier = getAccumulatorMultiplier();
        (uint256 userStake,,,) = usbStaking.userPosition(user);
        return userStake * accumulatedYieldRewardTokenPerStakeToken / accumulatorMultiplier;
    }
    
    /**
     * @dev calculates the pending reward from `lastRewardBlock` to current block + `blocks`
     * @param blocks the number of blocks to get the pending reward
     */
    function calculateTotalPendingYieldReward(uint256 blocks) public view returns (uint256) {
        uint256 blockDelta = getBlockDelta(lastYieldRewardBlock, block.number + blocks);
        return blockDelta * yieldRewardPerBlock;
    }

    /**
     * @dev return sum of all rewardsPerBlock to current block + `blocks`
     * @param blocks the number of blocks
     */
    function getTotalPendingYieldReward(uint256 blocks) public view returns (uint256) {
        return totalPendingYieldReward + calculateTotalPendingYieldReward(blocks);
    }

    /**
     * @dev return the unclaimed rewards amount
     */
    function getUnclaimedRewardAmount() external view returns (uint256 unclaimedYieldRewards) {
        uint256 _totalPendingYieldReward = getTotalPendingYieldReward(0);
        if (_totalPendingYieldReward >= totalClaimedYieldReward) {
            unclaimedYieldRewards = _totalPendingYieldReward - totalClaimedYieldReward;
        }
    }

    /**
     * @dev return the amount of reward token on contract
     */
    function getYieldRewardTokenAmount() public view returns (uint256) {
        return yieldRewardToken.balanceOf(address(this));
    }
    
    /** 
     * @dev return reward blockDelta over the given `from` to `to` block 
     */
    function getBlockDelta(uint256 from, uint256 to) public view returns (uint256 blockDelta) {
        require (from <= to, "USBStakingYield: incorrect from/to sequence");
        uint256 _startBlock = startBlock;
        uint256 _endBlock = endBlock;
        if (_startBlock == 0 || to <= _startBlock || from >= _endBlock) {
            return 0;
        }
        uint256 lastBlock = to <= _endBlock ? to : _endBlock;
        uint256 firstBlock = from >= _startBlock ? from : _startBlock;
        blockDelta = lastBlock - firstBlock;
    }

    /**
     * @dev return user position as (total yield rewarded, intime pending reward)
     */
    function getUserYieldPosition(address user) external view returns (uint256 userClaimedYieldReward, uint256 userPendingYieldReward) {
        UserYieldPosition memory userYield = userYieldPosition[user];
        (uint256 userStake,,,) = usbStaking.userPosition(user);
        uint256 totalStaked = usbStaking.totalStake();
        uint256 accumulatedYieldRewardTokenPerStakeTokenLocal = accumulatedYieldRewardTokenPerStakeToken;
        uint256 accumulatorMultiplier = getAccumulatorMultiplier();
        userPendingYieldReward = userYield.pendingYieldReward;
        if (block.number > lastYieldRewardBlock && totalStaked != 0) {
            uint256 blockDelta = getBlockDelta(lastYieldRewardBlock, block.number);
            uint256 rewardAmount = blockDelta * yieldRewardPerBlock;
            accumulatedYieldRewardTokenPerStakeTokenLocal += rewardAmount * accumulatorMultiplier / totalStaked;
            uint256 accumulatedShareOfReward = userStake * accumulatedYieldRewardTokenPerStakeTokenLocal / accumulatorMultiplier;
            if (accumulatedShareOfReward > userYield.instantAccumulatedShareOfYieldReward) {
                userPendingYieldReward += accumulatedShareOfReward - userYield.instantAccumulatedShareOfYieldReward;
            }
        }
        return (userYield.claimedYieldReward, userPendingYieldReward);
    }

    /**
     * @dev returns the accumulator multiplier for accumulatedYieldRewardTokenPerStakeToken
     */
    function getAccumulatorMultiplier() public view returns (uint256 accumulatorMultiplier) {
        uint8 stakeTokenDecimals = usbStaking.stakeToken().decimals();
        uint8 yieldRewardTokenDecimals = yieldRewardToken.decimals();
        if (stakeTokenDecimals >= yieldRewardTokenDecimals){
            accumulatorMultiplier = 10 ** (12 + stakeTokenDecimals - yieldRewardTokenDecimals);
        } else {
            accumulatorMultiplier =  10 ** stakeTokenDecimals;
        }
    }

    //************* END VIEW FUNCTIONS *************//

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import "./openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import "./openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "./openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./USBStaking.sol";
import "./USBStakingYield.sol";

contract USBStakingFactory is Initializable, AccessControlUpgradeable {

    using SafeERC20Upgradeable for ERC20Upgradeable;

    /**
     * @dev 32 byte code of FACTORY_MANAGER_ROLE
     */
    bytes32 public constant FACTORY_MANAGER_ROLE = keccak256("FACTORY_MANAGER_ROLE");

    /**
     * @dev address of upgradeableBeacon of USBStaking contract
     */
    UpgradeableBeacon public upgradeableBeaconUsbStaking;

    /**
     * @dev address of upgradeableBeacon of USBStakingYield contract
     */
    UpgradeableBeacon public upgradeableBeaconUsbStakingYield;

    /**
     * @dev list of USBStaking contracts
     */
    USBStaking[] public stakings;
    
    /**
     * @dev USBStaking address => id in list `stakings`
     */
    mapping(address => uint256) public stakingId;

    event DeployStaking(address indexed usbStaking, uint256 indexed stakingId, address stakeToken, address rewardToken, uint256 initialReward, uint256 rewardPerBlock, uint256 startBlock, uint256 endBlock);
    event AddYieldToStaking(address indexed usbStaking, address yieldRewardToken, uint256 initialYieldReward, uint256 yieldRewardPerBlock, uint256 startBlock, uint256 endBlock);
    event RemoveYieldStaking(address indexed usbStaking, uint8 yiedlId);

    modifier onlyAdmin {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "USBStakingFactory: Caller is not the Admin");
        _;
    }

    modifier onlyFactoryManager(){
        require(hasRole(FACTORY_MANAGER_ROLE, msg.sender), "USBStakingFactory: Caller is not the factory manager");
        _;
    }

    /**
     * @dev initializer of USBStaking factory
     * @param _usbStaking address of logic contract of USBStaking
     * @param _usbStakingYield address of logic contract of USBStakingYield
     */
    function initialize(
        address _usbStaking,
        address _usbStakingYield
    ) external initializer {
        require(_usbStaking != address(0), "USBStakingFactory: _usbStaking=0");
        require(_usbStakingYield != address(0), "USBStakingFactory: _usbStakingYield=0");
        __AccessControl_init();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(FACTORY_MANAGER_ROLE, msg.sender);
        
        upgradeableBeaconUsbStaking = new UpgradeableBeacon(_usbStaking);
        upgradeableBeaconUsbStakingYield = new UpgradeableBeacon(_usbStakingYield);
    }

    /******************** ADMIN FUNCTIONS ******************** */

    /**
     * @dev transfer admin of USBStakingFactory to `_admin`
     * @param _admin address of new admin
     */
    function transferAdminship(address _admin) external onlyAdmin {
        require(_admin != address(0), "USBStakingFactory: _admin is zero");
        require(!hasRole(DEFAULT_ADMIN_ROLE, _admin), "USBStakingFactory: _admin already have admin role");
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @dev grants `_factoryManager` factory manager
     * @param _factoryManager address of new factory manager
     */
    function grantFactoryManager(address _factoryManager) external onlyAdmin{
        _grantRole(FACTORY_MANAGER_ROLE, _factoryManager);
    }

    /**
     * @dev revokes factory manager
     * @param _factoryManager address of factory manager
     */
    function revokeFactoryManager(address _factoryManager) external onlyAdmin{
        _revokeRole(FACTORY_MANAGER_ROLE, _factoryManager);
    }
     
    /**
     * @dev upgrade the logic implementation of usb staking  
     * @param _usbStaking address of contract with logic usbStaking
     */
    function setUsbStaking(address _usbStaking) external onlyAdmin() {
        require(_usbStaking != address(0), "USBStakingFactory: invalid _usbStaking");
        upgradeableBeaconUsbStaking.upgradeTo(_usbStaking);
    }

    /**
     * @dev upgrade the logic implementation of usb staking yield 
     * @param _usbStakingYield address of contract with logic usbStakingYield
     */
    function setUsbStakingYield(address _usbStakingYield) external onlyAdmin() {
        require(_usbStakingYield != address(0), "USBStakingFactory: invalid _usbStakingYield");
        upgradeableBeaconUsbStakingYield.upgradeTo(_usbStakingYield);
    }

    /******************** END ADMIN FUNCTIONS ******************** */

    /******************** FACTORY MANAGER FUNCTIONS ******************** */

    /**
     * @dev deploys new staking
     * @param _stakeToken address of stake token
     * @param _rewardToken address of reward token
     * @param _initialReward amount of initial reward
     * @param _rewardPerBlock the amount of reward token to be initial reward
     * @param _startBlock block number of start staking
     * @param _endBlock block number of end staking
     */
    function deployStaking(
        address _stakeToken,
        address _rewardToken,
        uint256 _initialReward,
        uint256 _rewardPerBlock,
        uint256 _startBlock,
        uint256 _endBlock
    ) external onlyFactoryManager {
        address beaconProxy = address(new BeaconProxy(address(upgradeableBeaconUsbStaking), ""));
        USBStaking usbStaking = USBStaking(beaconProxy);
        if (_initialReward > 0) {
            ERC20Upgradeable(_rewardToken).safeTransferFrom(msg.sender, address(this), _initialReward);
            ERC20Upgradeable(_rewardToken).approve(beaconProxy, _initialReward);
        }
        usbStaking.initialize(
            address(this), 
            _stakeToken, 
            _rewardToken, 
            _initialReward, 
            _rewardPerBlock, 
            _startBlock, 
            _endBlock
        );
        usbStaking.grantManager(msg.sender);
        usbStaking.revokeManager(address(this));
        usbStaking.transferAdminship(msg.sender);
        stakingId[address(usbStaking)] = stakingsLength();
        stakings.push(usbStaking);
        emit DeployStaking(address(usbStaking), stakingsLength() - 1, _stakeToken, _rewardToken, _initialReward, _rewardPerBlock, _startBlock, _endBlock);
    }
    
    /**
     * @dev add yield on staking
     * @param _usbStaking address of USBStaking
     * @param _yieldRewardToken address of yield reward token
     * @param _initialYieldReward amount of initial yield reward
     * @param _yieldRewardPerBlock the amount of yield reward token to be initial reward
     * @param _startBlock block number of start yield rewarding
     * @param _endBlock block number of end yield rewarding
     */
    function addYieldToStaking(
        address _usbStaking,
        address _yieldRewardToken,
        uint256 _initialYieldReward,
        uint256 _yieldRewardPerBlock,
        uint256 _startBlock,
        uint256 _endBlock
    ) external {
        USBStaking usbStaking = USBStaking(_usbStaking);
        bytes32 adminRole = usbStaking.DEFAULT_ADMIN_ROLE();
        require(usbStaking.hasRole(adminRole, msg.sender), "USBStakingFactory: msg.sender is not admin of _usbStaking");

        address beaconProxy = address(new BeaconProxy(address(upgradeableBeaconUsbStakingYield), ""));
        USBStakingYield usbStakingYield = USBStakingYield(beaconProxy);
        if (_initialYieldReward > 0) {
            ERC20Upgradeable(_yieldRewardToken).safeTransferFrom(msg.sender, address(this), _initialYieldReward);
            ERC20Upgradeable(_yieldRewardToken).approve(beaconProxy, _initialYieldReward);
        }
        usbStakingYield.initialize(
            _usbStaking, 
            _yieldRewardToken, 
            _initialYieldReward, 
            _yieldRewardPerBlock, 
            _startBlock, 
            _endBlock
        );
        usbStaking.addYield(usbStakingYield);
        emit AddYieldToStaking(_usbStaking, _yieldRewardToken, _initialYieldReward, _yieldRewardPerBlock, _startBlock, _endBlock);
    }

    /**
     * @dev remove the yield on staking
     * @param _usbStaking address of staking
     * @param yiedlId id of yield
     */
    function removeYieldStaking(
        address _usbStaking,
        uint8 yiedlId
    ) external {
        USBStaking usbStaking = USBStaking(_usbStaking);
        bytes32 adminRole = usbStaking.DEFAULT_ADMIN_ROLE();
        require(usbStaking.hasRole(adminRole, msg.sender), "USBStakingFactory: msg.sender is not admin of _usbStaking");

        usbStaking.removeYield(yiedlId);
        emit RemoveYieldStaking(_usbStaking, yiedlId);
    }

    /******************** END FACTORY MANAGER FUNCTIONS ******************** */
    
    /******************** VIEW FUNCTIONS ******************** */
    
    /**
     * @dev returns the staking address in array `stakings`
     * @param _stakingId id of staking address in array `stakings`
     */
    function getStaking(uint8 _stakingId) external view returns(address) {
        require(_stakingId < stakingsLength(), "USBStakingFactory: invalid _stakingId");
        return address(stakings[_stakingId]);
    }

    /**
     * @dev return the length of array `stakings`
     */
    function stakingsLength() public view returns (uint256) {
        return stakings.length;
    }


    /******************** END VIEW FUNCTIONS ******************** */

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "./openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "./openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./USBStakingFactory.sol";
import "./USBStakingYield.sol";

contract USBStaking is Initializable, PausableUpgradeable, AccessControlUpgradeable {

    using SafeERC20Upgradeable for ERC20Upgradeable;

    /** 
     * @dev Manager is the person allowed to manage this product 
     */
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    /** 
     * @dev The factory of farming contracts. Can be zero address if this farming is not deployed by factory.
     */
    USBStakingFactory public factory; 

    /** 
     * @dev address of stake token contract 
     */
    ERC20Upgradeable public stakeToken;  

    /** 
     * @dev address of reward token contract 
     */
    ERC20Upgradeable public rewardToken;
   
    /**
     * @notice amount of reward token to be distribute for one block 
     * @dev [rewardPerBlock]=rewardToken/block
     */ 
    uint256 public rewardPerBlock;

    /** 
     * @notice block number when staking starts
     * @dev [startBlock]=block
     */
    uint256 public startBlock;

    /**
     * @notice block number when staking ends
     * @dev [endBlock]=block
     */
    uint256 public endBlock;

    /**
     * @notice last block number when tokens distribution occurs
     * @dev [lastRewardBlock]=block
     */
    uint256 public lastRewardBlock;
    
    /**
     * @notice accumulated reward tokens per stake token. Accumulates with every update() call
     * @dev [accumulatedRewardTokenPerStakeToken]=rewardToken/stakeToken
     */
    uint256 public accumulatedRewardTokenPerStakeToken;
    
    /**
     * @notice total amount of staked token by all stakers
     * @dev [totalStake]=stakeToken
     */
    uint256 public totalStake;

    /**
     * @notice total pending reward token. If you want to get current pending reward call `getTotalPendingReward(0)`
     * @dev [totalPendingReward]=rewardToken
     */
    uint256 public totalPendingReward;

    /**
     * @notice total reward token claimed by stakers
     * @dev totalClaimedReward = sum of all claimedReward by all users
     * @dev [totalClaimedReward]=rewardToken
     */
    uint256 public totalClaimedReward;

    /**
     * @notice user position
     * @dev address of user => UserPosition
     */
    mapping (address => UserPosition) public userPosition;

    /**
     * @notice array of yield rewards contracts
     */
    USBStakingYield[] public yields;

    /**
     * @notice is stake paused
     * @dev true - paused, false - unpaused
     */
    bool public isStakePaused;
    
    /** 
     * @notice info of each user
     */
    struct UserPosition {
        uint256 stake;          // how many stake tokens the user has provided. [stake]=stakeToken
        uint256 claimedReward;  // total stake of tokens send as reward to user [claimedReward]=rewardToken
        uint256 pendingReward;  // how many reward tokens user was rewarded with. [pendingReward]=rewardToken
        uint256 instantAccumulatedShareOfReward;   // how many tokens already pended. [instantAccumulatedShareOfReward]=rewardToken
    }
   
    event Stake(address indexed user, uint256 stakeAmount);
    event Unstake(address indexed user, uint256 unstakeAmount);
    event ClaimReward(address indexed user, uint256 claimedRewardAmount);
    event ClaimRewardAndStake(address indexed user, uint256 claimedRewardAndStakedAmount);
    event Exit(address indexed user, uint256 exitAmount, uint256 claimedRewardAmount);
    event EmergencyUnstake(address indexed user, uint256 withdrawAmount);

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "USBStaking: Caller is not the Admin");
        _;
    }

    modifier onlyAdminOrFactory() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender) || msg.sender == address(factory), "USBStaking: Caller is not the admin or factory");
        _;
    }

    modifier onlyManager() {
        require(hasRole(MANAGER_ROLE, msg.sender), "USBStaking: Caller is not the Manager");
        _;
    }

    modifier onlyNonStakePaused() {
        require(!isStakePaused, "USBStaking: stake is paused");
        _;
    }

    /**
     * @dev initializer of USBStaking
     * @param _factory address of factory contract. Possible to zero address
     * @param _rewardToken address of reward token
     * @param _stakeToken address of stake token
     * @param _initialReward the amount of reward token to be initial reward
     * @param _rewardPerBlock the amount of reward to be distributed for one block
     */
    function initialize(
        address _factory,
        address _stakeToken,
        address _rewardToken,
        uint256 _initialReward,
        uint256 _rewardPerBlock,
        uint256 _startBlock,
        uint256 _endBlock
    ) external initializer {
        __AccessControl_init();
        __Pausable_init_unchained();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MANAGER_ROLE, msg.sender);

        if(_factory != address(0)){
            factory = USBStakingFactory(_factory);
            _setupRole(MANAGER_ROLE, _factory);
        }
        
        stakeToken = ERC20Upgradeable(_stakeToken);
        rewardToken = ERC20Upgradeable(_rewardToken);

        if(_initialReward > 0) {
            rewardToken.safeTransferFrom(msg.sender, address(this), _initialReward);
        }

        _setRewardPerBlock(_rewardPerBlock);
        _setPeriod(_startBlock, _endBlock);
    }

    //************* ADMIN FUNCTIONS *************//

    /**
     * @dev transfer admin of USBStakingFactory to `_admin`
     * @param _admin address of new admin
     */
    function transferAdminship(address _admin) external onlyAdmin {
        require(_admin != address(0), "USBStaking: _admin is zero");
        require(!hasRole(DEFAULT_ADMIN_ROLE, _admin), "USBStaking: _admin already have admin role");
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }
    
    /**
     * @dev grant the manager
     * @param _manager address of manager
     */
    function grantManager(address _manager) external onlyAdmin {
        _grantRole(MANAGER_ROLE, _manager);
    }

    /**
     * @dev revoke the manager
     * @param _manager address of manager
     */
    function revokeManager(address _manager) external onlyAdmin {
        _revokeRole(MANAGER_ROLE, _manager);
    }
    
    /**
     * @dev transfer any tokens from staking
     * @param _token address of token to be transferred
     * @param _recipient address of receiver of tokens
     * @param _amount amount of token to be transferred
     */
    function sweepTokens(address _token, address _recipient, uint256 _amount) external onlyAdmin {
        require(_amount > 0, "USBStaking: amount=0");
        if (_token == address(stakeToken)) {
            uint256 balanceOfStakeToken = stakeToken.balanceOf(address(this));
            require(balanceOfStakeToken > totalStake, "USBStaking: balanceOfStakeToken==totalStake");
            uint256 excess = balanceOfStakeToken - totalStake;
            require(excess >= _amount, "USBStaking: sweep more than allowed");   
        }
        ERC20Upgradeable(_token).safeTransfer(_recipient, _amount);
    }

    /**
     * @dev pause staking
     */
    function pause() external onlyAdmin {
        update();
        super._pause();
    }

    /**
     * @dev unpause staking
     */
    function unpause() external onlyAdmin {
        lastRewardBlock = block.number;
        super._unpause();
    }
    
    /**
     * @dev add yield
     * @param _yield address of USBStakingYield
     */
    function addYield(USBStakingYield _yield) external onlyAdminOrFactory {
        require(yields.length < type(uint8).max, "USBStaking: reached max amount of yield reward pools");
        yields.push(_yield);
    }

    /**
     * @dev removed yield
     * @param _yieldId id of yield in array `yields`
     */
    function removeYield(uint8 _yieldId) external onlyAdminOrFactory {
        require(_yieldId < yields.length, "USBStaking: yieldId >= yields.length");
        if (yields.length > 1 && _yieldId != (yields.length - 1)) {
            yields[_yieldId] = yields[yields.length - 1];
        }
        yields.pop();
    }

    //************* END ADMIN FUNCTIONS *************//
    //************* MANAGER FUNCTIONS *************//

    /**
     * @dev sets reward per block. Can be called by manager
     * @param _rewardPerBlock amount of `rewardToken` to be rewarded each block
     */
    function setRewardPerBlock(uint256 _rewardPerBlock) public onlyManager {
        _setRewardPerBlock(_rewardPerBlock);
    }

    /**
     * @dev sets reward per block
     * @param _rewardPerBlock amount of `rewardToken` to be rewarded each block
     */
    function _setRewardPerBlock(uint256 _rewardPerBlock) internal {
        update();
        rewardPerBlock = _rewardPerBlock;
    }

    /**
     * @dev sets period of staking. Can be called by manager
     * @param _startBlock block number of start staking
     * @param _endBlock block number of end staking
     */
    function setPeriod(uint256 _startBlock, uint256 _endBlock) public onlyManager {
        _setPeriod(_startBlock, _endBlock);
    }

    /**
     * @dev sets period of staking
     * @param _startBlock block number of start staking
     * @param _endBlock block number of end staking
     */
    function _setPeriod(uint256 _startBlock, uint256 _endBlock) internal {
        require(_startBlock < _endBlock, "USBStaking: should be startBlock<endBlock");
        startBlock = _startBlock;
        endBlock = _endBlock;
    }

    /**
     * @dev sets reward per block and period of staking
     * @param _rewardPerBlock amount of `rewardToken` to be rewarded each block
     * @param _startBlock block number of start staking
     * @param _endBlock block number of end staking
     */
    function setParams(uint256 _rewardPerBlock, uint256 _startBlock, uint256 _endBlock) external onlyManager {
        _setRewardPerBlock(_rewardPerBlock);
        _setPeriod(_startBlock, _endBlock);
    }

    /**
     * @dev sets staking to pause
     * @param _paused true - paused, false - unpaused
     */
    function setStakePaused(bool _paused) external onlyManager {
        isStakePaused = _paused;
    }

    //************* END MANAGER FUNCTIONS *************//
    //************* MAIN FUNCTIONS *************//

    /**
     * @dev update the `accumulatedRewardTokenPerStakeToken`
     */
    function update() public whenNotPaused {
        if (block.number <= lastRewardBlock) {
            return;
        }   
        if (totalStake == 0) {
            lastRewardBlock = block.number;
            return;
        }
        uint256 rewardAmount = calculateTotalPendingReward(0);
        uint256 accumulatorMultiplier = getAccumulatorMultiplier();
        accumulatedRewardTokenPerStakeToken += rewardAmount * accumulatorMultiplier / totalStake;
        totalPendingReward += rewardAmount;
        lastRewardBlock = block.number;
        uint256 yieldsLength = yields.length;
        for(uint8 i = 0; i < yieldsLength;) {
            try yields[i].update() {

            } catch {

            }
            unchecked { ++i; }
        }
    }

    /**
     * @dev update pending yields
     */
    function updatePendingYieldReward(address user) internal {
        uint256 yieldsLength = yields.length;
        for(uint8 i = 0; i < yieldsLength;) {
            yields[i].updatePendingYieldReward(user);
            unchecked { ++i; }
        }
    }

    /**
     * @dev update instant accumulated share of yield
     */
    function updateInstantAccumulatedShareOfYieldReward(address user) internal {
        uint256 yieldsLength = yields.length;
        for(uint8 i = 0; i < yieldsLength;) {
            yields[i].updateInstantAccumulatedShareOfYieldReward(user);
            unchecked { ++i; }
        }
    }

    /**
     * @notice stake `stakeToken` to msg.sender
     * @param stakeTokenAmount amount of `stakeToken`
     */
    function stake(uint256 stakeTokenAmount) external {
        stakeTo(msg.sender, stakeTokenAmount);
    }

    /**
     * @notice stake `stakeToken` to `beneficiary`
     * @param beneficiary the address of user
     * @param stakeTokenAmount amount of `stakeToken`
     */
    function stakeTo(address beneficiary, uint256 stakeTokenAmount) public onlyNonStakePaused {
        require(stakeTokenAmount > 0, "USBStaking: stakeTokenAmount should be not zero");
        update();
        UserPosition storage user = userPosition[beneficiary];
        uint256 accumulatedShareOfReward = getAccumulatedShareOfReward(beneficiary);
        if (accumulatedShareOfReward > user.instantAccumulatedShareOfReward) {
            user.pendingReward += accumulatedShareOfReward - user.instantAccumulatedShareOfReward;  
        }
        updatePendingYieldReward(beneficiary);
        stakeToken.safeTransferFrom(address(msg.sender), address(this), stakeTokenAmount);
        totalStake += stakeTokenAmount;
        user.stake += stakeTokenAmount;
        user.instantAccumulatedShareOfReward = getAccumulatedShareOfReward(beneficiary);
        updateInstantAccumulatedShareOfYieldReward(beneficiary);
        emit Stake(beneficiary, stakeTokenAmount);
    }

    /**
     * @notice unstake `stakeToken`.
     * @param stakeTokenAmount amount of `stakeToken` to unstake
     */
    function unstake(uint256 stakeTokenAmount) external whenNotPaused {
        UserPosition storage user = userPosition[msg.sender];
        require(stakeTokenAmount > 0, "USBStaking: stakeTokenAmount should be not zero");
        require(stakeTokenAmount <= user.stake, "USBStaking: amount exceeded user stake");
        update();
        uint256 accumulatedShareOfReward = getAccumulatedShareOfReward(msg.sender);
        if(accumulatedShareOfReward > user.instantAccumulatedShareOfReward) {
            user.pendingReward += accumulatedShareOfReward - user.instantAccumulatedShareOfReward;
        }
        updatePendingYieldReward(msg.sender);
        user.stake -= stakeTokenAmount;
        totalStake -= stakeTokenAmount;
        stakeToken.safeTransfer(msg.sender, stakeTokenAmount);
        user.instantAccumulatedShareOfReward = getAccumulatedShareOfReward(msg.sender);
        updateInstantAccumulatedShareOfYieldReward(msg.sender);
        emit Unstake(msg.sender, stakeTokenAmount);
    }

    /**
     * @notice claim the reward
     */
    function claimReward() public whenNotPaused {
        update();
        UserPosition storage user = userPosition[msg.sender];
        uint256 accumulatedShareOfReward = getAccumulatedShareOfReward(msg.sender);
        if(accumulatedShareOfReward > user.instantAccumulatedShareOfReward) {
            user.pendingReward += accumulatedShareOfReward - user.instantAccumulatedShareOfReward;
            user.instantAccumulatedShareOfReward = accumulatedShareOfReward;
        }
        updatePendingYieldReward(msg.sender);
        updateInstantAccumulatedShareOfYieldReward(msg.sender);
        uint256 pendingReward = user.pendingReward;
        if (pendingReward > 0) {
            totalClaimedReward += pendingReward;
            user.claimedReward += pendingReward;
            user.pendingReward = 0;
            _safeRewardTokenTransfer(msg.sender, pendingReward);
            emit ClaimReward(msg.sender, pendingReward);
        }
    }

    /**
     * @notice claim reward from staking and yield
     */
    function claimAllReward() external whenNotPaused {
        uint256 yieldsLength = yields.length;
        for(uint8 i = 0; i < yieldsLength;) {
            yields[i].claimYieldRewardTo(msg.sender);
            unchecked { ++i; }
        }
        claimReward();
    }

    /**
     * @notice stake the reward. Possible to call if reward token equal to stake token
     */
    function claimRewardAndStake() external whenNotPaused {
        require(address(rewardToken) == address(stakeToken), "USBStaking: not allowed for this product");
        update();
        UserPosition storage user = userPosition[msg.sender];
        uint256 accumulatedShareOfReward = getAccumulatedShareOfReward(msg.sender);
        if (accumulatedShareOfReward > user.instantAccumulatedShareOfReward) {
            user.pendingReward += accumulatedShareOfReward - user.instantAccumulatedShareOfReward;
        }
        uint256 pendingReward = user.pendingReward;
        require(pendingReward > 0, "USBStaking: pendingReward=0");
        require(pendingReward <= getRewardTokenAmount(), "USBStaking: insufficient amount of rewardToken");
        totalClaimedReward += pendingReward;
        user.claimedReward += pendingReward;
        updatePendingYieldReward(msg.sender);
        totalStake += pendingReward;
        user.stake += pendingReward;
        user.pendingReward = 0;
        user.instantAccumulatedShareOfReward = getAccumulatedShareOfReward(msg.sender);
        updateInstantAccumulatedShareOfYieldReward(msg.sender);
        emit ClaimRewardAndStake(msg.sender, pendingReward);
    }

    /**
     * @notice unstake all staked token + claim reward
     */
    function exit() external whenNotPaused {
        update();
        UserPosition storage user = userPosition[msg.sender];
        uint256 userStake = user.stake;
        require(userStake > 0, "USBStaking: no stake");
        uint256 accumulatedShareOfReward = getAccumulatedShareOfReward(msg.sender);
        if (accumulatedShareOfReward > user.instantAccumulatedShareOfReward) {
            user.pendingReward += accumulatedShareOfReward - user.instantAccumulatedShareOfReward;
        }
        updatePendingYieldReward(msg.sender);
        totalStake -= userStake;
        user.stake = 0;
        stakeToken.safeTransfer(msg.sender, userStake);
        
        uint256 pendingReward = user.pendingReward;
        if(pendingReward > 0){
            totalClaimedReward += pendingReward;
            user.claimedReward += pendingReward;
            user.pendingReward = 0;
            _safeRewardTokenTransfer(msg.sender, pendingReward);
        }
        user.instantAccumulatedShareOfReward = 0;
        updateInstantAccumulatedShareOfYieldReward(msg.sender);
        emit Exit(msg.sender, userStake, pendingReward);
    }

    /**
     * @notice emergency unstake `stakeToken` without carrying about reward
     */
    function emergencyUnstake() external {
        if (!paused()) {
            update();
        }
        UserPosition storage user = userPosition[msg.sender];
        uint256 userStake = user.stake;
        require(userStake > 0, "USBStaking: no emergency stake");
        totalStake -= userStake;
        user.stake = 0;
        user.instantAccumulatedShareOfReward = 0;
        stakeToken.safeTransfer(address(msg.sender), userStake);
        emit EmergencyUnstake(msg.sender, userStake);
    }

    /**
     * @dev internal transfer of reward token
     * @param beneficiar address of receiver
     * @param amount amount of reward token `beneficiar` will receive
     */
    function _safeRewardTokenTransfer(address beneficiar, uint256 amount) internal {
        uint256 rewardTokenBalance = getRewardTokenAmount();
        if (amount > rewardTokenBalance) {
            rewardToken.safeTransfer(beneficiar, rewardTokenBalance);
            uint256 shortfall = amount - rewardTokenBalance;
            totalClaimedReward -= shortfall;
            userPosition[beneficiar].claimedReward -= shortfall;
            userPosition[beneficiar].pendingReward += shortfall;
        } else {
            rewardToken.safeTransfer(beneficiar, amount);
        }
    }

    //************* END MAIN FUNCTIONS *************//
    //************* VIEW FUNCTIONS *************//

    /**
     * @dev return the share of reward of `user` by his stake
     */
    function getAccumulatedShareOfReward(address user) public view returns (uint256) {
        uint256 accumulatorMultiplier = getAccumulatorMultiplier();
        return userPosition[user].stake * accumulatedRewardTokenPerStakeToken / accumulatorMultiplier;
    }

    /**
     * @dev calculates the pending reward from `lastRewardBlock` to current block + `blocks`
     * @param blocks the number of blocks to get the pending reward
     */
    function calculateTotalPendingReward(uint256 blocks) public view returns (uint256) {
        uint256 blockDelta = getBlockDelta(lastRewardBlock, block.number + blocks);
        return blockDelta * rewardPerBlock;
    }

    /**
     * @dev return sum of all rewardsPerBlock to current block + `blocks`
     * @param blocks the number of blocks
     */
    function getTotalPendingReward(uint256 blocks) public view returns (uint256) {
        return totalPendingReward + calculateTotalPendingReward(blocks);
    }

    /**
     * @dev return the unclaimed rewards amount of users
     */
    function getUnclaimedRewardAmount() external view returns (uint256 unclaimedRewards) {
        uint256 _totalPendingReward = getTotalPendingReward(0);
        if (_totalPendingReward >= totalClaimedReward) {
            unclaimedRewards = _totalPendingReward - totalClaimedReward;
        }
    }

    /**
     * @dev return the length of array `yields`
     */
    function getYieldsLength() external view returns (uint256) {
        return yields.length;
    }

    /**
     * @dev return the amount of reward token on contract
     */
    function getRewardTokenAmount() public view returns (uint256) {
        uint256 rewardTokenBalance = rewardToken.balanceOf(address(this));
        if (rewardToken == stakeToken) {
            return rewardTokenBalance > totalStake ? rewardTokenBalance - totalStake : 0;
        } else {
            return rewardTokenBalance;
        }
    }
    
    /**
     * @dev return the amount of stake token on contract
     */
    function getStakedTokenAmount() external view returns (uint256) {
        return stakeToken.balanceOf(address(this));
    }

    /** 
     * @dev return reward blockDelta over the given from to to block 
     */
    function getBlockDelta(uint256 from, uint256 to) public view returns (uint256 blockDelta) {
        require (from <= to, "USBStaking: should be from<=to");
        uint256 _startBlock = startBlock;
        uint256 _endBlock = endBlock;
        if (_startBlock == 0 || to <= _startBlock || from >= _endBlock) {
            return 0;
        }
        uint256 lastBlock = to <= _endBlock ? to : _endBlock;
        uint256 firstBlock = from >= _startBlock ? from : _startBlock;
        blockDelta = lastBlock - firstBlock;
    }

    /**
     * @dev return user position as (user stake, totalClaimedReward, intime pending reward)
     */
    function getUserPosition(address _user) external view returns (uint256 userStake, uint256 userClaimedReward, uint256 userPendingReward) {
        UserPosition storage user = userPosition[_user];
        uint256 accumulatedRewardTokenPerStakedTokenLocal = accumulatedRewardTokenPerStakeToken;
        uint256 accumulatorMultiplier = getAccumulatorMultiplier();
        userPendingReward = user.pendingReward;
        if (block.number > lastRewardBlock && totalStake != 0) {
            uint256 blockDelta = getBlockDelta(lastRewardBlock, block.number);
            uint256 rewardAmount = blockDelta * rewardPerBlock;
            accumulatedRewardTokenPerStakedTokenLocal += rewardAmount * accumulatorMultiplier / totalStake;
            uint256 accumulatedShareOfReward = user.stake * accumulatedRewardTokenPerStakedTokenLocal / accumulatorMultiplier;
            if (accumulatedShareOfReward > user.instantAccumulatedShareOfReward) {
                userPendingReward += accumulatedShareOfReward - user.instantAccumulatedShareOfReward;
            }
        }
        return (user.stake, user.claimedReward, userPendingReward);
    }

    /**
     * @dev returns the accumulator multiplier for accumulatedRewardTokenPerStakeToken
     * @dev Description why `accumulatorMultiplier` look by this way
        There are need to calculate this formula:
        blockDifference * rewardPerBlock * accamulatorMultiplier / totalStaked
        The dimention of it 
        [blockDifference] * [rewardPerBlock] * [accamulatorMultiplier] / [totalStaked]=
        =block * rewardToken / block * 1 / stakeToken = rewardToken / stakeToken
        reward token and stake token may have different decimals.
        So, we need to optimize this formula by unknown variable `accamulatorMultiplier` to be positive integer
        `rewardPerBlock * accamulatorMultiplier / totalStaked` is positive integer (1)
                                    
        let accamulatorMultiplier = 10 ** (12 + stakeTokenDecimals - rewardTokenDecimals), if stakeTokenDecimals >= rewardTokenDecimals
        let accamulatorMultiplier = 10 ** stakeTokenDecimals, if stakeTokenDecimals < rewardTokenDecimals

        To show that it is good solution for optimization, take a metric:
        M = LOG10(rewardPerBlock * accamulatorMultiplier / totalStaked)

        M = 18 , if stake token decimals < reward token decimals
        M = 12 , if stake token decimals >= reward token decimals

        In another words, this metric shows that order of formula (1) will always be positive integer and will have order 18 or 12.

     */
    function getAccumulatorMultiplier() public view returns (uint256 accumulatorMultiplier) {
        uint8 stakeTokenDecimals = stakeToken.decimals();
        uint8 rewardTokenDecimals = rewardToken.decimals();
        if (stakeTokenDecimals >= rewardTokenDecimals){
            accumulatorMultiplier = 10 ** (12 + stakeTokenDecimals - rewardTokenDecimals);
        } else {
            accumulatorMultiplier =  10 ** stakeTokenDecimals;
        }
    }

    //************* END VIEW FUNCTIONS *************//

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

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
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

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
        __Context_init_unchained();
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
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
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
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
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
// OpenZeppelin Contracts v4.4.1 (access/AccessControl.sol)

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
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
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
        _checkRole(role, _msgSender());
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
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
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
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
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
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/BeaconProxy.sol)

pragma solidity ^0.8.0;

import "./IBeacon.sol";
import "../Proxy.sol";
import "../ERC1967/ERC1967Upgrade.sol";

/**
 * @dev This contract implements a proxy that gets the implementation address for each call from a {UpgradeableBeacon}.
 *
 * The beacon address is stored in storage slot `uint256(keccak256('eip1967.proxy.beacon')) - 1`, so that it doesn't
 * conflict with the storage layout of the implementation behind the proxy.
 *
 * _Available since v3.4._
 */
contract BeaconProxy is Proxy, ERC1967Upgrade {
    /**
     * @dev Initializes the proxy with `beacon`.
     *
     * If `data` is nonempty, it's used as data in a delegate call to the implementation returned by the beacon. This
     * will typically be an encoded function call, and allows initializating the storage of the proxy like a Solidity
     * constructor.
     *
     * Requirements:
     *
     * - `beacon` must be a contract with the interface {IBeacon}.
     */
    constructor(address beacon, bytes memory data) payable {
        assert(_BEACON_SLOT == bytes32(uint256(keccak256("eip1967.proxy.beacon")) - 1));
        _upgradeBeaconToAndCall(beacon, data, false);
    }

    /**
     * @dev Returns the current beacon address.
     */
    function _beacon() internal view virtual returns (address) {
        return _getBeacon();
    }

    /**
     * @dev Returns the current implementation address of the associated beacon.
     */
    function _implementation() internal view virtual override returns (address) {
        return IBeacon(_getBeacon()).implementation();
    }

    /**
     * @dev Changes the proxy to use a new beacon. Deprecated: see {_upgradeBeaconToAndCall}.
     *
     * If `data` is nonempty, it's used as data in a delegate call to the implementation returned by the beacon.
     *
     * Requirements:
     *
     * - `beacon` must be a contract.
     * - The implementation returned by `beacon` must be a contract.
     */
    function _setBeacon(address beacon, bytes memory data) internal virtual {
        _upgradeBeaconToAndCall(beacon, data, false);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/UpgradeableBeacon.sol)

pragma solidity ^0.8.0;

import "./IBeacon.sol";
import "../../access/Ownable.sol";
import "../../utils/Address.sol";

/**
 * @dev This contract is used in conjunction with one or more instances of {BeaconProxy} to determine their
 * implementation contract, which is where they will delegate all function calls.
 *
 * An owner is able to change the implementation the beacon points to, thus upgrading the proxies that use this beacon.
 */
contract UpgradeableBeacon is IBeacon, Ownable {
    address private _implementation;

    /**
     * @dev Emitted when the implementation returned by the beacon is changed.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Sets the address of the initial implementation, and the deployer account as the owner who can upgrade the
     * beacon.
     */
    constructor(address implementation_) {
        _setImplementation(implementation_);
    }

    /**
     * @dev Returns the current implementation address.
     */
    function implementation() public view virtual override returns (address) {
        return _implementation;
    }

    /**
     * @dev Upgrades the beacon to a new implementation.
     *
     * Emits an {Upgraded} event.
     *
     * Requirements:
     *
     * - msg.sender must be the owner of the contract.
     * - `newImplementation` must be a contract.
     */
    function upgradeTo(address newImplementation) public virtual onlyOwner {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Sets the implementation contract address for this beacon
     *
     * Requirements:
     *
     * - `newImplementation` must be a contract.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "UpgradeableBeacon: implementation is not a contract");
        _implementation = newImplementation;
    }
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
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (proxy/Proxy.sol)

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overriden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeacon.sol";
import "../../utils/Address.sol";
import "../../utils/StorageSlot.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967Upgrade {
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
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
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
            Address.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallSecure(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        address oldImplementation = _getImplementation();

        // Initial upgrade and setup call
        _setImplementation(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }

        // Perform rollback test if not already in progress
        StorageSlot.BooleanSlot storage rollbackTesting = StorageSlot.getBooleanSlot(_ROLLBACK_SLOT);
        if (!rollbackTesting.value) {
            // Trigger rollback using upgradeTo from the new implementation
            rollbackTesting.value = true;
            Address.functionDelegateCall(
                newImplementation,
                abi.encodeWithSignature("upgradeTo(address)", oldImplementation)
            );
            rollbackTesting.value = false;
            // Check rollback was effective
            require(oldImplementation == _getImplementation(), "ERC1967Upgrade: upgrade breaks further upgrades");
            // Finally reset to the new implementation and log the upgrade
            _upgradeTo(newImplementation);
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
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
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
        return StorageSlot.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(Address.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            Address.isContract(IBeacon(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlot.getAddressSlot(_BEACON_SLOT).value = newBeacon;
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
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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
// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

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
library StorageSlot {
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
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
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