//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';

import './interfaces/IStaking.sol';
import './interfaces/IStakingFactory.sol';
import './interfaces/IRootChainManager.sol';

import '../matic/interfaces/IERC20Mintable.sol';
import './Errors.sol';

contract Staking is Initializable, OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable, IStaking {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    enum DepositState {
        NOT_CREATED,
        DEPOSITED,
        WITHDRAWN,
        REWARD_CLAIMED
    }

    struct Deposit {
        uint256 amount;
        uint256 startBlock;
        uint256 unlockBlock;
        uint256 plasmaLastClaimedAt;
        address user;
        DepositState depositState;
        uint256 vestedRewardUnlockBlock;
        uint256 vestedRewards;
    }

    /**
     * @notice Total number of blocks in one year
     */
    uint256 public constant totalBlocksPerYear = 365 * 24 * 60 * 60; // one year as a second
    // uint256 public constant totalBlocksPerYear = 1210; // for local
    // uint256 public constant totalBlocksPerYear = 120010; // for goerli

    uint256 public constant vestingLockBlocks = totalBlocksPerYear; // for mainnet and local
    // uint256 public constant vestingLockBlocks = 1; // for goerli

    /**
     * @notice Address of factory
     */
    address public factory;

    /**
     * @notice minimum number of blocks to be locked
     */
    uint256 public lockinBlocks;

    /**
     * @notice Block at which starting starts
     */
    uint256 public startBlock;

    /**
     * @notice address of staking token
     */
    address public stakingToken;

    /**
     * @notice address of plasma token
     */
    address public immutable plasmaToken;

    /**
     * @notice address of matic bridge
     */
    address public immutable maticBridge;

    /**
     * @notice address of erc20 predicate
     */
    address public immutable erc20Predicate;

    /**
     * @notice deposit counter
     */
    uint256 public depositCounter;

    /**
     * @notice total value locked
     */
    uint256 public tvl;

    /**
     * @notice deposits
     */
    mapping(uint256 => Deposit) public deposits;

    /**
     * @notice event when deposit is emitted
     */
    event Deposited(uint256 indexed depositNumber, address indexed depositor, uint256 amount, uint256 unlockBlock);

    /**
     * @notice event when plasma is claimed
     */
    event ClaimPlasma(uint256 indexed depositNumber, address indexed user, uint256 amount);

    /**
     * @notice event when deposit is withdrawn
     */
    event Withdraw(uint256 indexed depositNumber);

    /**
     * @notice event when vested reward is withdrawn
     */
    event WithdrawVestedReward(uint256 indexed depositNumber);

    /**
     * @notice event when token are withdrawn on emergency
     */
    event EmegencyWithdrawToken(uint256 indexed depositNumber);

    /**
     * @notice event Plasma Per Block is emitted
     */
    event UpdatePlasmaPerBlockPerToken(uint256 newReward);

    /**
     * @notice number of plasma tokens per block per staking token
     */
    uint256 public plasmaPerBlockPerToken;

    /**
     * @notice Plasma weight
     */
    uint256 public constant weightScale = 1e18;

    /**
     * @notice max number of deposits that can be operated in the single call
     */
    uint256 public constant MAX_LOOP_ITERATIONS = 100;

    /**
     * @notice Boolean parameter to indicate if the pool is flexi pool
     */
    bool isFlexiPool;

    /**
     * @param _plasmaToken Address of the plasma token
     * @param _erc20Predicate Address of the predicate contract
     * @param _maticBridge Address of the matic bridge
     */
    constructor(
        address _plasmaToken,
        address _erc20Predicate,
        address _maticBridge
    ) {
        require(_plasmaToken != address(0), Errors.SHOULD_BE_NON_ZERO);
        require(_maticBridge != address(0), Errors.SHOULD_BE_NON_ZERO);
        require(_erc20Predicate != address(0), Errors.SHOULD_BE_NON_ZERO);

        plasmaToken = _plasmaToken;

        maticBridge = _maticBridge;
        erc20Predicate = _erc20Predicate;
    }

    /**
     * @param _stakingToken address of token to stake
     * @param _lockinBlocks Minimum number of blocks the deposit should be staked
     * @param _operator Address of the staking operator
     * @param _isFlexiPool True if the current pool is flexi pool
     */
    function initialize(
        address _stakingToken,
        uint256 _lockinBlocks,
        address _operator,
        bool _isFlexiPool
    ) external override initializer {
        require(_lockinBlocks < totalBlocksPerYear, Errors.LOCK_IN_BLOCK_LESS_THAN_MIN);
        require(_operator != address(0), Errors.SHOULD_BE_NON_ZERO);
        require(_stakingToken != address(0), Errors.SHOULD_BE_NON_ZERO);

        __Ownable_init();
        transferOwnership(_operator);
        __Pausable_init();

        lockinBlocks = _lockinBlocks;
        // transfer ownership
        factory = msg.sender;
        stakingToken = _stakingToken;
        startBlock = block.timestamp;

        isFlexiPool = _isFlexiPool;
    }

    /**
     * @notice Deposit to Staking Contract, The token must be approved before this function is called
     * @param _to address that receives the tokens on behalf of
     * @param amount Amount of tokens to be staked
     */
    function depositTo(address _to, uint256 amount) external override nonReentrant {
        _depositInternal(_to, amount);
    }

    /**
     * @notice Deposit to Staking Contract, The token must be approved before this function is called
     * @param amount Amount of tokens to be staked
     */
    function deposit(uint256 amount) external override nonReentrant {
        _depositInternal(msg.sender, amount);
    }

    // actual logic of deposit(internal function)
    function _depositInternal(address _to, uint256 amount) internal {
        depositCounter++;
        uint256 timeStamp = block.timestamp;
        uint256 unlockTimeStamp = timeStamp + lockinBlocks;
        deposits[depositCounter] = Deposit(amount, timeStamp, unlockTimeStamp, timeStamp, _to, DepositState.DEPOSITED, 0, 0);
        tvl = tvl + (amount);

        emit Deposited(depositCounter, _to, amount, unlockTimeStamp);

        IERC20Upgradeable(stakingToken).safeTransferFrom(msg.sender, address(this), amount);
        IStakingFactory(factory).updateTVL(tvl);
        _updatePlasmaPerBlockPerToken();
    }

    /**
     * @notice Claim Plasma from factory.
     * @param depositNumbers Deposit Numbers to claim plasma from
     * @param depositor Address of the depositor
     */
    function claimPlasmaFromFactory(
        uint256[] calldata depositNumbers,
        address depositor,
        address plasmaRecipient
    ) external override onlyFactory nonReentrant {
        require(depositNumbers.length <= MAX_LOOP_ITERATIONS, Errors.EXCEEDS_MAX_ITERATION);
        _updatePlasmaPerBlockPerToken();
        uint256 totalPlasmaToMint;
        for (uint256 index = 0; index < depositNumbers.length; index++) {
            totalPlasmaToMint += _claimPlasmaFromFactory(depositNumbers[index], depositor);
        }
        _mintAndSendPlasma(depositor, totalPlasmaToMint, plasmaRecipient);
    }

    /**
     * @notice internal function to claim plasm from factory contract
     * @param depositNumber Deposit number to claim plasma from
     * @param depositor Address of the depostor
     */
    function _claimPlasmaFromFactory(uint256 depositNumber, address depositor)
        internal
        onlyWhenDeposited(depositNumber)
        onlyDepositor(depositNumber, depositor)
        returns (uint256 amount)
    {
        (uint256 claimablePlasma, address user) = getClaimablePlasma(depositNumber);
        deposits[depositNumber].plasmaLastClaimedAt = _getCurrentBlockWrtEndBlock();
        amount = _claimPlasma(depositNumber, user, claimablePlasma);
    }

    function claimPlasmaMultiple(uint256[] calldata depositNumbers, address plasmaRecipient) external nonReentrant {
        uint256 totalAmount;
        _updatePlasmaPerBlockPerToken();
        for (uint256 index = 0; index < depositNumbers.length; index++) {
            totalAmount += _claimPlasmaMultiple(depositNumbers[index], msg.sender);
        }
        _mintAndSendPlasma(msg.sender, totalAmount, plasmaRecipient);
    }

    function _claimPlasmaMultiple(uint256 depositNumber, address depositor)
        internal
        onlyWhenDeposited(depositNumber)
        onlyDepositor(depositNumber, depositor)
        returns (uint256)
    {
        (uint256 claimablePlasma, address user) = getClaimablePlasma(depositNumber);
        deposits[depositNumber].plasmaLastClaimedAt = _getCurrentBlockWrtEndBlock();
        uint256 amount = _claimPlasma(depositNumber, user, claimablePlasma);
        return amount;
    }

    /**
     * @notice Withdraw Multiple Deposits
     * @param depositNumbers Deposit Numbers to withdraw
     */
    function withdrawUfoMultiple(uint256[] calldata depositNumbers, address plasmaRecipient) external {
        require(depositNumbers.length <= MAX_LOOP_ITERATIONS, Errors.EXCEEDS_MAX_ITERATION);
        _updatePlasmaPerBlockPerToken();
        uint256 totalPlasmaToClaim;
        uint256 totalTokensToWithdraw;
        uint256 vestedRewards;

        uint256 totalPoolShare = IStakingFactory(factory).getPoolShare(address(this));

        for (uint256 index = 0; index < depositNumbers.length; index++) {
            (uint256 a, uint256 b, uint256 c) = _withdrawUfoMultiple(depositNumbers[index], msg.sender, totalPoolShare);
            totalPlasmaToClaim += a;
            totalTokensToWithdraw += b;
            vestedRewards += c;
        }

        IERC20Upgradeable(stakingToken).safeTransfer(msg.sender, totalTokensToWithdraw);
        _mintAndSendPlasma(msg.sender, totalPlasmaToClaim, plasmaRecipient);
        IStakingFactory(factory).updateTVL(tvl);
        IStakingFactory(factory).updateClaimedRewards(vestedRewards);
    }

    /**
     * @notice Withdraw Multiple Deposits
     * @param depositNumbers Deposit Numbers to withdraw
     */
    function withdrawPartialUfoMultiple(
        uint256[] calldata depositNumbers,
        uint256 fraction,
        address plasmaRecipient
    ) external {
        require(isFlexiPool, Errors.ONLY_FEATURE_OF_FLEXI_POOLS);
        require(fraction < weightScale, Errors.MORE_THAN_FRACTION);
        require(depositNumbers.length <= MAX_LOOP_ITERATIONS, Errors.EXCEEDS_MAX_ITERATION);
        _updatePlasmaPerBlockPerToken();
        uint256 totalPlasmaToClaim;
        uint256 totalTokensToWithdraw;
        uint256 totalTokensToStakeBack;
        uint256 vestedRewards;

        uint256 totalPoolShare = IStakingFactory(factory).getPoolShare(address(this));

        for (uint256 index = 0; index < depositNumbers.length; index++) {
            (uint256 a, uint256 b, uint256 c, uint256 d) = _withdrawPartialUfoMultiple(
                depositNumbers[index],
                msg.sender,
                fraction,
                totalPoolShare
            );
            totalPlasmaToClaim += a;
            totalTokensToWithdraw += b;
            totalTokensToStakeBack += c;
            vestedRewards += d;
        }

        depositCounter++;
        uint256 nowTimeStamp = block.timestamp;
        uint256 unlockBlock = nowTimeStamp + lockinBlocks;
        deposits[depositCounter] = Deposit(
            totalTokensToStakeBack,
            nowTimeStamp,
            unlockBlock,
            nowTimeStamp,
            msg.sender,
            DepositState.DEPOSITED,
            0,
            0
        );

        emit Deposited(depositCounter, msg.sender, totalTokensToStakeBack, unlockBlock);

        IERC20Upgradeable(stakingToken).safeTransfer(msg.sender, totalTokensToWithdraw);
        _mintAndSendPlasma(msg.sender, totalPlasmaToClaim, plasmaRecipient);
        IStakingFactory(factory).updateTVL(tvl);
        IStakingFactory(factory).updateClaimedRewards(vestedRewards);
    }

    /**
     * @notice internal function to withdraw multple deposits/UFO tokens
     * @param depositNumber Deposit Number to withdraw
     * @param depositor Address of the depositor
     */
    function _withdrawPartialUfoMultiple(
        uint256 depositNumber,
        address depositor,
        uint256 fraction,
        uint256 totalPoolShare
    )
        internal
        onlyWhenDeposited(depositNumber)
        onlyDepositor(depositNumber, depositor)
        returns (
            uint256 plasmToClaim,
            uint256 stakedTokensToWithdraw,
            uint256 stakedTokensToBeAddedBack,
            uint256 vestedRewardsObtained
        )
    {
        Deposit storage _deposit = deposits[depositNumber];
        require(block.timestamp > _deposit.unlockBlock, Errors.ONLY_AFTER_END_BLOCK);

        stakedTokensToWithdraw = (fraction * _deposit.amount) / weightScale;
        stakedTokensToBeAddedBack = _deposit.amount - stakedTokensToWithdraw;

        require(stakedTokensToWithdraw != 0, Errors.SHOULD_BE_NON_ZERO);

        (plasmToClaim, vestedRewardsObtained) = _calculateParamWhenWithdrawUfo(_deposit, depositNumber, totalPoolShare);

        tvl = tvl - stakedTokensToWithdraw;

        emit Withdraw(depositNumber);
    }

    /**
     * @notice internal function to withdraw multple deposits/UFO tokens
     * @param depositNumber Deposit Number to withdraw
     * @param depositor Address of the depositor
     */
    function _withdrawUfoMultiple(
        uint256 depositNumber,
        address depositor,
        uint256 totalPoolShare
    )
        internal
        onlyWhenDeposited(depositNumber)
        onlyDepositor(depositNumber, depositor)
        returns (
            uint256 plasmToClaim,
            uint256 stakedTokensToWithdraw,
            uint256 vestedTokensObtained
        )
    {
        Deposit storage _deposit = deposits[depositNumber];
        require(block.timestamp > _deposit.unlockBlock, Errors.ONLY_AFTER_END_BLOCK);

        (plasmToClaim, vestedTokensObtained) = _calculateParamWhenWithdrawUfo(_deposit, depositNumber, totalPoolShare);
        stakedTokensToWithdraw = _deposit.amount;
        tvl = tvl - _deposit.amount;

        emit Withdraw(depositNumber);
    }

    function _calculateParamWhenWithdrawUfo(
        Deposit storage _deposit,
        uint256 depositNumber,
        uint256 totalPoolShare
    ) internal returns (uint256 plasmToClaim, uint256 vestedReward) {
        (uint256 claimablePlasma, address user) = getClaimablePlasma(depositNumber);
        plasmToClaim = _claimPlasma(depositNumber, user, claimablePlasma);

        uint256 blockNumber = _getCurrentBlockWrtEndBlock();

        _deposit.plasmaLastClaimedAt = blockNumber;
        _deposit.depositState = DepositState.WITHDRAWN;
        _deposit.vestedRewardUnlockBlock = blockNumber + (vestingLockBlocks);

        uint256 numberOfBlocksStaked = block.timestamp - _deposit.startBlock;

        vestedReward = getVestedRewards(totalPoolShare, _deposit.amount, numberOfBlocksStaked);
        _deposit.vestedRewards = vestedReward;
    }

    /**
     * @notice Returns the number of Vested UFO token for a given deposit
     * @param depositNumber Deposit Number
     */
    function getUfoVestedAmount(uint256 depositNumber) external view returns (uint256) {
        Deposit storage _deposit = deposits[depositNumber];
        if (_deposit.depositState != DepositState.WITHDRAWN) {
            return 0;
        }

        uint256 numberOfBlocksStaked = block.timestamp - _deposit.startBlock;
        uint256 totalPoolShare = IStakingFactory(factory).getPoolShare(address(this));
        return getVestedRewards(totalPoolShare, _deposit.amount, numberOfBlocksStaked);
    }

    /**
     * @notice Withdraw Multiple Vested Rewards
     * @param depositNumbers Deposit Numbers to withdraw
     */
    function withdrawVestedUfoMultiple(uint256[] calldata depositNumbers) external {
        require(depositNumbers.length <= MAX_LOOP_ITERATIONS, Errors.EXCEEDS_MAX_ITERATION);
        _updatePlasmaPerBlockPerToken();
        uint256 totalAmount;
        for (uint256 index = 0; index < depositNumbers.length; index++) {
            totalAmount += _withdrawVestedUfoMultiple(depositNumbers[index], msg.sender);
        }
        _transferVestedRewards(msg.sender, totalAmount);
    }

    /**
     * @notice Internal function to withdraw UFO tokens
     * @param depositNumber Deposit to claim the vested reward
     * @param depositor of the depositor
     */
    function _withdrawVestedUfoMultiple(uint256 depositNumber, address depositor)
        internal
        onlyWhenWithdrawn(depositNumber)
        onlyDepositor(depositNumber, depositor)
        returns (uint256)
    {
        Deposit storage _deposit = deposits[depositNumber];
        require(block.timestamp > _deposit.vestedRewardUnlockBlock, Errors.VESTED_TIME_NOT_REACHED);
        _deposit.depositState = DepositState.REWARD_CLAIMED;
        emit WithdrawVestedReward(depositNumber);
        return _deposit.vestedRewards;
    }

    /**
     * @notice Returns the number of  plasma claimed
     * @param depositNumber Deposit Number
     */
    function getClaimablePlasma(uint256 depositNumber) public view returns (uint256 claimablePlasma, address user) {
        Deposit storage _deposit = deposits[depositNumber];
        user = _deposit.user;
        if (_deposit.depositState != DepositState.DEPOSITED) {
            claimablePlasma = 0;
        } else {
            uint256 blockNumber = _getCurrentBlockWrtEndBlock();
            claimablePlasma = ((blockNumber - (_deposit.plasmaLastClaimedAt)) * (plasmaPerBlockPerToken) * (_deposit.amount));
        }
    }

    /**
     * @notice Returns the number of Vested Rewards for given number of blocks and amount
     * @param totalPoolShare Total share of the pool
     * @param amount Amount of staked token
     * @param numberOfBlocksStaked Number of blocks staked
     */
    function getVestedRewards(
        uint256 totalPoolShare,
        uint256 amount,
        uint256 numberOfBlocksStaked
    ) internal view returns (uint256) {
        return (totalPoolShare * (amount) * (numberOfBlocksStaked)) / (totalBlocksPerYear) / (tvl);
    }

    /**
     * @notice Internal function to claim plasma tokens. The claimed plasma tokens are sent to polygon chain directly
     * @param user Address to transfer
     * @param amount Amount of tokens to transfer
     */
    function _claimPlasma(
        uint256 depositNumber,
        address user,
        uint256 amount
    ) internal returns (uint256) {
        require(amount != 0, Errors.SHOULD_BE_NON_ZERO);
        emit ClaimPlasma(depositNumber, user, amount);
        return amount;
    }

    // if recipient is address(0), send to depositor eth address, else bridge it on polygon
    function _mintAndSendPlasma(
        address depositor,
        uint256 amount,
        address recipient
    ) internal {
        if (recipient != address(0)) {
            uint256 amountMinted = IERC20Mintable(plasmaToken).mint(address(this), amount);
            bool status = IERC20Upgradeable(plasmaToken).approve(erc20Predicate, amountMinted); // use of safeApprove is depricated and not recommended
            require(status, Errors.APPROVAL_UNSUCCESSFUL);
            IRootChainManager(maticBridge).depositFor(recipient, plasmaToken, abi.encode(amountMinted));
        } else {
            IERC20Mintable(plasmaToken).mint(depositor, amount);
        }
        IStakingFactory(factory).updateClaimedPlasma(amount);
    }

    /**
     * @notice Function to transfer vested rewards to the receiver
     * @param receiver Address that recevies the tokens
     * @param amount Amount of tokens to send
     */
    function _transferVestedRewards(address receiver, uint256 amount) internal {
        IStakingFactory(factory).flushReward(receiver, amount);
    }

    /**
     * @notice Withdraw Multiple Vested Rewards
     * @param depositNumbers Deposit Numbers to emergency withdraw
     */
    function emergencyWithdrawMultiple(uint256[] calldata depositNumbers) external {
        require(depositNumbers.length <= MAX_LOOP_ITERATIONS, Errors.EXCEEDS_MAX_ITERATION);
        uint256 totalAmount;
        for (uint256 index = 0; index < depositNumbers.length; index++) {
            totalAmount = totalAmount + _emergencyWithdrawMultiple(depositNumbers[index], msg.sender);
        }

        if (tvl < totalAmount) {
            totalAmount = tvl;
        }

        tvl = tvl - totalAmount;

        IERC20Upgradeable(stakingToken).safeTransfer(msg.sender, totalAmount);
        try IStakingFactory(factory).updateTVL(tvl) {} catch Error(string memory) {}
    }

    /**
     * @notice Internal function to withdraw the tokens
     * @param depositNumber Deposit number
     * @param depositor Address of the depositor
     */
    function _emergencyWithdrawMultiple(uint256 depositNumber, address depositor)
        internal
        onlyWhenDeposited(depositNumber)
        onlyDepositor(depositNumber, depositor)
        whenPaused
        returns (uint256)
    {
        Deposit memory _deposit = deposits[depositNumber];
        delete deposits[depositNumber];
        emit EmegencyWithdrawToken(depositNumber);
        return _deposit.amount;
    }

    /**
     * @notice Return the staking end block
     */
    function _getCurrentBlockWrtEndBlock() internal view returns (uint256 blockNumber) {
        blockNumber = block.timestamp;
    }

    /**
     * @notice function to pause
     */
    function pauseStaking() external onlyOwner {
        _pause();
    }

    /**
     * @notice function to unpause
     */
    function unpauseStaking() external onlyOwner {
        _unpause();
    }

    /**
     * @notice Update Plasma Tokens Per Block
     */
    function _updatePlasmaPerBlockPerToken() internal {
        uint256 _plasmaPerBlockPerToken = IStakingFactory(factory).getPlasmaPerBlock();
        plasmaPerBlockPerToken = _plasmaPerBlockPerToken / totalBlocksPerYear;
        emit UpdatePlasmaPerBlockPerToken(plasmaPerBlockPerToken);
    }

    /**
     * @notice Update the plasma per block in the current pool
     */
    function upatePlasmPerBlock() external {
        _updatePlasmaPerBlockPerToken();
    }

    /**
     * @notice Modifier that allows only factory contract to call
     */
    modifier onlyFactory() {
        require(msg.sender == factory, Errors.ONLY_FACTORY_CAN_CALL);
        _;
    }

    /**
     * @notice Modifier to check if the deposit state is DEPOSITED
     */
    modifier onlyWhenDeposited(uint256 depositNumber) {
        require(deposits[depositNumber].depositState == DepositState.DEPOSITED, Errors.ONLY_WHEN_DEPOSITED);
        _;
    }

    /**
     * @notice Modifier to check if the deposit state is WITHDRAWN
     */
    modifier onlyWhenWithdrawn(uint256 depositNumber) {
        require(deposits[depositNumber].depositState == DepositState.WITHDRAWN, Errors.ONLY_WHEN_WITHDRAWN);
        _;
    }

    /**
     * @notice Modifier to ensure only depositor calls
     */
    modifier onlyDepositor(uint256 depositNumber, address depositor) {
        require(deposits[depositNumber].user == depositor, Errors.ONLY_DEPOSITOR);
        _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IStaking {
    function initialize(
        address _stakingToken,
        uint256 _lockinBlocks,
        address _operator,
        bool _isFlexiPool
    ) external;

    function claimPlasmaFromFactory(
        uint256[] calldata depositNumbers,
        address depositor,
        address plasmaRecipient
    ) external;

    function deposit(uint256 amount) external;

    function depositTo(address _to, uint256 amount) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IStakingFactory {
    function updateTVL(uint256 tvl) external;

    function flushReward(address user, uint256 amount) external;

    function getTotalTVLWeight() external view returns (uint256 lockedPoolTvlWeight, uint256 unlockedPoolTvlWeight);

    function getPoolShare(address pool) external view returns (uint256 amount);

    function getTotalTVL() external view returns (uint256 totalLockedUfo);

    function getPlasmaPerBlock() external view returns (uint256 plasmaPerBlock);

    function updateClaimedRewards(uint256 amount) external;

    function updateClaimedPlasma(uint256 amount) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IRootChainManager {
    function depositFor(
        address user,
        address rootToken,
        bytes calldata depositData
    ) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 * @notice Interface for minting any ERC20 token
 */
interface IERC20Mintable {
    function mint(address _to, uint256 _amount) external returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

library Errors {
    string public constant ONLY_WHEN_DEPOSITED = '1';
    string public constant ONLY_DEPOSITOR = '2';
    string public constant VESTED_TIME_NOT_REACHED = '3';
    string public constant ONLY_AFTER_END_BLOCK = '4';
    string public constant ONLY_BEFORE_STAKING_ENDS = '5';
    string public constant ONLY_FACTORY_CAN_CALL = '6';
    string public constant DEFENCE = '7';
    string public constant ONLY_WHEN_WITHDRAWN = '8';
    string public constant SHOULD_BE_NON_ZERO = '9';
    string public constant SHOULD_BE_MORE_THAN_CLAIMED = 'A';
    string public constant ONLY_POOLS_CAN_CALL = 'B';
    string public constant LOCK_IN_BLOCK_LESS_THAN_MIN = 'C';
    string public constant EXCEEDS_MAX_ITERATION = 'D';
    string public constant SHOULD_BE_ZERO = 'E';
    string public constant ARITY_MISMATCH = 'F';
    string public constant APPROVAL_UNSUCCESSFUL = '10';
    string public constant MORE_THAN_FRACTION = '11';
    string public constant ONLY_FEATURE_OF_FLEXI_POOLS = '12';
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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