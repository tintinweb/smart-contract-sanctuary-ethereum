// SPDX-License-Identifier: GPL-2.0-or-later
// (C) Florence Finance, 2022 - https://florence.finance/
pragma solidity 0.8.9;

import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./LendingPool.sol";
import "./interfaces/ILendingPoolFactory.sol";
import "hardhat/console.sol";

/// @title LendingPoolFactory
/// @dev Facilitates the creation and registration of upgradabale LendingPools via beacon pattern
contract LendingPoolFactory is ILendingPoolFactory, Ownable {
    /// @dev
    UpgradeableBeacon public upgradeableBeacon;

    /// @dev lendingPool id => lending pool proxy address
    mapping(string => address) private lendingPools;

    /// @dev
    string[] public lendingPoolIds;

    /// @dev init
    /// @param _initialLendingPoolImpl the initial lendingPool implementation
    constructor(address _initialLendingPoolImpl) {
        setUpgradeableBeacon(new UpgradeableBeacon(_initialLendingPoolImpl));
    }

    /// @dev Upgrades all LendingPools
    /// @param _newLendingPoolImpl the new implementation
    function upgrade(address _newLendingPoolImpl) public onlyOwner {
        require(address(_newLendingPoolImpl) != address(0), "new impplementation is null");
        require(address(upgradeableBeacon) != address(0), "no beacon/factory upgraded");
        upgradeableBeacon.upgradeTo(_newLendingPoolImpl);
    }

    /// @dev Creates an upgradable LendingPool and registers it
    /// @param id unique id of the LendingPool
    /// @param lendingPoolTokenSymbol symbol of the LendingPoolToken
    function createLendingPool(string memory id, string memory lendingPoolTokenSymbol) external onlyOwner {
        require(lendingPools[id] == address(0), "lendingPool already exists");
        require(address(upgradeableBeacon) != address(0), "no beacon/factory upgraded");

        address lendingPoolProxyAddress = address(new BeaconProxy(address(upgradeableBeacon), ""));
        LendingPool(lendingPoolProxyAddress).initialize(id, lendingPoolTokenSymbol);
        LendingPool(lendingPoolProxyAddress).transferOwnership(owner());
        lendingPools[id] = lendingPoolProxyAddress;
        lendingPoolIds.push(id);
        emit LendingPoolCreated(id, lendingPoolProxyAddress);
    }

    /// @dev Allows to add an already existing lendingPool to the registry. For reploy purposes.
    /// @param id id of the lendingPool
    /// @param lendingPoolProxyAddress address of the lendingPool proxy
    function addLendingPool(string memory id, address lendingPoolProxyAddress) external onlyOwner {
        require(lendingPools[id] == address(0), "lendingPool already exists");
        lendingPools[id] = lendingPoolProxyAddress;
        lendingPoolIds.push(id);
    }

    /// @dev Allows to set the upgradeableBeacon. For reploy purposes.
    /// @param _upgradeableBeacon the upgradeableBeacon
    function setUpgradeableBeacon(UpgradeableBeacon _upgradeableBeacon) public onlyOwner {
        upgradeableBeacon = _upgradeableBeacon;
    }

    /// @dev get a LendingPool by id
    /// @param id the id
    /// @return the address of the lendingPool proxy
    function getLendingPool(string calldata id) external view returns (address) {
        require(lendingPools[id] != address(0), "lendingPool not found");
        return lendingPools[id];
    }

    function getLendingPoolIds() external view returns (string[] memory) {
        return lendingPoolIds;
    }

    function upgradeFactory(LendingPoolFactory newLendingPoolFactory) external onlyOwner {
        require(address(upgradeableBeacon) != address(0), "no beacon/factory upgraded");
        require(newLendingPoolFactory.owner() == address(this), "upgradeFactory: invalidOwner"); //for the migration the old factory must own the new factory
        upgradeableBeacon.transferOwnership(address(newLendingPoolFactory)); //transfer ownership of beacon to new factory
        newLendingPoolFactory.setUpgradeableBeacon(upgradeableBeacon); //transfer beacon to new factory
        upgradeableBeacon = UpgradeableBeacon(address(0)); //remove beacon from this contract
        //register existing lendingpools with new factory
        for (uint256 i = 0; i < lendingPoolIds.length; i++) {
            string memory lendingPoolId = lendingPoolIds[i];
            newLendingPoolFactory.addLendingPool(lendingPoolId, lendingPools[lendingPoolId]);
        }
        newLendingPoolFactory.transferOwnership(_msgSender()); //transfer ownership of new factory to msgSender
        emit LendingPoolFactoryUpgrade(address(this), address(newLendingPoolFactory));
    }
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

// SPDX-License-Identifier: GPL-2.0-or-later
// (C) Florence Finance, 2022 - https://florence.finance/
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./LendingPoolToken.sol";
import "./interfaces/ILendingPool.sol";
//import "./libraries/Util.sol";
import "./libraries/PeriodStaking.sol";
import "./libraries/LinearStaking.sol";
import "./libraries/Funding.sol";

/// @title LendingPool
/// @dev
contract LendingPool is ILendingPool, Initializable, OwnableUpgradeable, PausableUpgradeable {
    /// @dev unique identifier
    string public id;

    /// @dev LendingPoolToken of the pool
    ILendingPoolToken public lendingPoolToken;

    /// @dev Storage for funding logic
    Funding.FundingStorage public fundingStorage;

    /// @dev Storage for linear staking logic
    LinearStaking.LinearStakingStorage private linearStakingStorage;

    /// @dev Storage for period staking logic
    PeriodStaking.PeriodStakingStorage public periodStakingStorage;

    /// @dev address of the treasury
    address public treasury;

    /// @dev modifier to make function callable by borrower only
    modifier onlyBorrower() {
        require(fundingStorage.borrowers[_msgSender()], "caller address is no borrower");
        _;
    }

    /// @dev initialization of the lendingPool (required since upgradable contracts can not be initialized via constructor)
    /// @param _lendingPoolId unique identifier
    /// @param _lendingPoolTokenSymbol symbol of the LendingPoolToken
    function initialize(string memory _lendingPoolId, string memory _lendingPoolTokenSymbol) external initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        __Pausable_init_unchained();

        pause();

        id = _lendingPoolId;

        lendingPoolToken = new LendingPoolToken(_lendingPoolId, _lendingPoolTokenSymbol);

        emit LendingPoolInitialized(address(this), _lendingPoolId, address(lendingPoolToken));
    }

    /////////////////////////////////////////////////////////////////////////
    /////////////////////////////////GENERAL/////////////////////////////////
    /////////////////////////////////////////////////////////////////////////

    /// @dev pauses the lendingPool. Only affects function with pausable related modifiers
    function pause() public onlyOwner {
        super._pause();
    }

    /// @dev unpauses the lendingPool. In order to unpause the configuration must be consistent. Only affects function with pausable related modifiers
    function unpause() public onlyOwner {
        require(treasury != address(0), "treasury not set");
        require(address(fundingStorage.principalToken) != address(0), "principalToken not set");
        super._unpause();
    }

    /// @dev Set the treasury address
    /// @param _treasury the treasury address
    function setTreasury(address _treasury) public onlyOwner {
        treasury = _treasury;
    }

    /// @dev returns the current version of this smart contract
    /// @return the current version of this smart contract
    function getVersion() public pure virtual returns (string memory) {
        return "V1";
    }

    /////////////////////////////////////////////////////////////////////////
    /////////////////////////////////FUNDING/////////////////////////////////
    /////////////////////////////////////////////////////////////////////////

    /// @dev Set whether a token should be accepted for funding the pool
    /// @param fundingToken the funding token
    /// @param accepted whether it is accepted
    function setFundingToken(IERC20 fundingToken, bool accepted) public onlyOwner {
        Funding.setFundingToken(fundingStorage, fundingToken, accepted);
    }

    /// @dev returns the accepted funding tokens
    function getFundingTokens() external view returns (IERC20[] memory) {
        return fundingStorage._fundingTokens;
    }

    /// @dev returns true if wallet is whitelisted (primary funder wallet)
    function isPrimaryFunder(address wallet) public view returns (bool) {
        return fundingStorage.primaryFunders[wallet];
    }

    /// @dev Change primaryFunder status of an address
    /// @param primaryFunder the address
    /// @param accepted whether its accepted as primaryFunder
    function setPrimaryFunder(address primaryFunder, bool accepted) public onlyOwner {
        Funding.setPrimaryFunder(fundingStorage, primaryFunder, accepted);
    }

    /// @dev returns true if wallet is borrower wallet
    function isBorrower(address wallet) external view returns (bool) {
        return fundingStorage.borrowers[wallet];
    }

    /// @dev Change borrower status of an address
    /// @param borrower the address
    /// @param accepted whether its accepted as primaryFunder
    function setBorrower(address borrower, bool accepted) public {
        require(
            _msgSender() == owner() || fundingStorage.borrowers[_msgSender()],
            "caller address is no borrower or owner"
        );
        Funding.setBorrower(fundingStorage, borrower, accepted);
    }

    /// @dev returns accepted principal token
    function getPrincipalToken() external view returns (IERC20) {
        return fundingStorage.principalToken;
    }

    /// @dev Set the principal token
    /// @param _principalToken the principal token
    function setPrincipalToken(IERC20 _principalToken) public onlyOwner {
        fundingStorage.principalToken = _principalToken;
    }

    /// @dev returns amount of available principal
    function getAvailablePrincipal() external view returns (uint256) {
        return fundingStorage.availablePrincipal;
    }

    /// @dev Borrower adds funding request
    /// @param amount funding request amount
    /// @param durationDays days that funding request is open
    /// @param interestRate interest rate for funding request
    function addFundingRequest(
        uint256 amount,
        uint256 durationDays,
        uint256 interestRate
    ) public onlyBorrower whenNotPaused {
        Funding.addFundingRequest(fundingStorage, amount, durationDays, interestRate);
    }

    /// @dev Borrower cancels funding request
    /// @param fundingRequestId funding request id to cancel
    function cancelFundingRequest(uint256 fundingRequestId) public onlyBorrower whenNotPaused {
        Funding.cancelFundingRequest(fundingStorage, fundingRequestId);
    }

    /// @dev Get information about the funding Request with the funding request ID
    /// @param fundingRequestId the funding request ID
    /// @return the FundingRequest structure selected with _fundingRequestID
    function getFundingRequest(uint256 fundingRequestId)
        public
        view
        whenNotPaused
        returns (Funding.FundingRequest memory)
    {
        return fundingStorage.fundingRequests[fundingRequestId];
    }

    /// @dev Allows primary funders to fund the pool
    /// @param fundingToken token used for the funding
    /// @param fundingTokenAmount funding amount (funding token decimals)
    function fund(IERC20 fundingToken, uint256 fundingTokenAmount) public whenNotPaused {
        Funding.fund(fundingStorage, fundingToken, fundingTokenAmount, lendingPoolToken);
    }

    /// @dev Allows the deposit of principal funds. This is usually used by the borrower or treasury
    /// @param amount the amount of principal (principalToken decimals)
    function depositPrincipal(uint256 amount) public {
        Funding.depositPrincipal(fundingStorage, amount);
    }

    /// @dev Allows the withdrawal of principal funds to the treasury
    /// @param amount the amount to be withdrawn
    function transferPrincipalToTreasury(uint256 amount) public onlyOwner {
        Funding.transferPrincipalToTreasury(fundingStorage, amount, treasury);
    }

    /// @dev Get an exchange rate for an ERC20<>Currnecy conversion
    /// @param token the token
    /// @return the exchange rate and the decimals of the exchange rate
    function getExchangeRate(IERC20 token) public view returns (uint256, uint8) {
        return Funding.getExchangeRate(fundingStorage, token);
    }

    /// @dev Adds a mapping between a token, currency and ChainLink price feed
    /// @param token the token
    /// @param chainLinkFeed the ChainLink price feed
    /// @param invertExchangeRate whether the rate returned by the chainLinkFeed needs to be inverted to match the token-currency pair order
    function setTokenChainLinkFeedMapping(
        IERC20 token,
        AggregatorV3Interface chainLinkFeed,
        bool invertExchangeRate
    ) external onlyOwner {
        Funding.setTokenChainLinkFeedMapping(fundingStorage, token, chainLinkFeed, invertExchangeRate);
    }

    /// @dev Get a ChainLink price feed for a token-currency pair
    /// @param token the token
    /// @return the ChainLink price feed
    function getTokenChainLinkFeedMapping(IERC20 token) public view returns (AggregatorV3Interface) {
        return fundingStorage.tokenChainlinkFeedMapping[token];
    }

    /////////////////////////////////////////////////////////////////////////
    /////////////////////////////LINEAR STAKING//////////////////////////////
    /////////////////////////////////////////////////////////////////////////

    /// @dev Sets the rewardTokensPerBlock for a stakedToken-rewardToken pair
    /// @param stakedToken the staked token
    /// @param rewardToken the reward token
    /// @param rewardTokensPerBlock rewardTokens per rewardToken per block (rewardToken decimals)
    function setRewardTokensPerBlockLinear(
        IERC20 stakedToken,
        IERC20 rewardToken,
        uint256 rewardTokensPerBlock
    ) public onlyOwner {
        LinearStaking.setRewardTokensPerBlockLinear(
            linearStakingStorage,
            stakedToken,
            rewardToken,
            rewardTokensPerBlock
        );
    }

    /// @dev Get available rewards for linear staking
    /// @param rewardToken the reward token
    function getAvailableLinearStakingRewards(IERC20 rewardToken) external view returns (uint256) {
        return linearStakingStorage.availableRewards[rewardToken];
    }

    /// @dev Lock or unlock the rewards for a staked token during linear staking
    /// @param stakedToken the staked token
    /// @param rewardToken the reward token
    /// @param rewardsLocked true = lock; false = unlock
    function setRewardsLockedLinear(
        IERC20 stakedToken,
        IERC20 rewardToken,
        bool rewardsLocked
    ) public onlyOwner {
        LinearStaking.setRewardsLockedLinear(linearStakingStorage, stakedToken, rewardToken, rewardsLocked);
    }

    /// @dev Staking of a stakable token
    /// @param stakableToken the stakeable token
    /// @param amount the amount to stake (stakableToken decimals)
    function stakeLinear(IERC20 stakableToken, uint256 amount) public whenNotPaused {
        LinearStaking.stakeLinear(linearStakingStorage, stakableToken, amount);
    }

    /// @dev Get the staked balance for a specific token and wallet
    /// @param wallet the wallet
    /// @param stakableToken the staked token
    /// @return the staked balance (stakableToken decimals)
    function getStakedBalanceLinear(address wallet, IERC20 stakableToken) public view returns (uint256) {
        return LinearStaking.getStakedBalanceLinear(linearStakingStorage, wallet, stakableToken);
    }

    /// @dev Unstaking of a staked token
    /// @param stakedToken the staked token
    /// @param amount the amount to unstake
    function unstakeLinear(IERC20 stakedToken, uint256 amount) public whenNotPaused {
        LinearStaking.unstakeLinear(linearStakingStorage, stakedToken, amount);
    }

    /// @dev Calculates the outstanding rewards for a wallet, staked token and reward token
    /// @param wallet the wallet
    /// @param stakedToken the staked token
    /// @param rewardToken the reward token
    /// @return the outstading rewards (rewardToken decimals)
    function calculateRewardsLinear(
        address wallet,
        IERC20 stakedToken,
        IERC20 rewardToken
    ) public view returns (uint256) {
        return LinearStaking.calculateRewardsLinear(linearStakingStorage, wallet, stakedToken, rewardToken);
    }

    /// @dev Claims all rewards for a staked tokens
    /// @param stakedToken the staked token
    function claimRewardsLinear(IERC20 stakedToken) public whenNotPaused {
        LinearStaking.claimRewardsLinear(linearStakingStorage, stakedToken);
    }

    /// @dev Check if rewards for a staked token are locked or not
    /// @param stakedToken the staked token
    /// @param rewardToken the reward token
    /// @return true = locked; false = unlocked
    function getRewardsLocked(IERC20 stakedToken, IERC20 rewardToken) public view returns (bool) {
        return linearStakingStorage.rewardConfigurations[stakedToken].rewardsLocked[rewardToken];
    }

    /// @dev Allows the deposit of reward funds. This is usually used by the borrower or treasury
    /// @param rewardToken the reward token
    /// @param amount the amount of tokens (rewardToken decimals)
    function depositRewardsLinear(IERC20 rewardToken, uint256 amount) public {
        LinearStaking.depositRewardsLinear(linearStakingStorage, rewardToken, amount);
    }

    /// @dev Allows the withdrawal of reward funds to the treasury
    /// @param rewardToken the reward token
    /// @param amount the amount to be withdrawn
    function transferRewardsToTreasury(IERC20 rewardToken, uint256 amount) public onlyOwner {
        LinearStaking.transferRewardsToTreasury(linearStakingStorage, rewardToken, amount, treasury);
    }

    /////////////////////////////////////////////////////////////////////////
    /////////////////////////////PERIOD STAKING//////////////////////////////
    /////////////////////////////////////////////////////////////////////////

    /// @dev Set the duration of the reward period
    /// @param duration duration in blocks of the reward period
    function setRewardPeriodDuration(uint256 duration) external onlyOwner {
        periodStakingStorage.duration = duration;
    }

    /// @dev Get variables of the period staking
    /// @return returns the id, duration and the rward token of the current reward period
    function getPeriodStakingInfo()
        external
        view
        returns (
            uint256,
            uint256,
            IERC20
        )
    {
        return (
            periodStakingStorage.currentRewardPeriodId,
            periodStakingStorage.duration,
            periodStakingStorage.rewardToken
        );
    }

    /// @dev Set the reward token of the reward period
    /// @param rewardToken the rward token of the reward period
    function setRewardPeriodRewardToken(IERC20 rewardToken) external onlyOwner {
        periodStakingStorage.rewardToken = rewardToken;
    }

    /// @dev Get the reward period
    /// @return returns the struct of the reward period
    function getRewardPeriod(uint256 rewardPeriodId) external view returns (PeriodStaking.RewardPeriod memory) {
        return periodStakingStorage.rewardPeriods[rewardPeriodId];
    }

    /// @dev Get all reward periods
    /// @return returns an array including the structs of all reward periods
    function getRewardPeriods() external view returns (PeriodStaking.RewardPeriod[] memory) {
        return PeriodStaking.getRewardPeriods(periodStakingStorage);
    }

    /// @dev Get open funding requests
    /// @return returns an array including the structs of all funding requests
    function getOpenFundingRequests() external view returns (Funding.FundingRequest[] memory) {
        return Funding.getFundingRequests(fundingStorage);
    }

    /// @dev Start next reward period
    function startNextRewardPeriod() external {
        PeriodStaking.startNextRewardPeriod(periodStakingStorage);
    }

    /// @dev deposit rewards for staking period
    /// @param rewardPeriodId staking period id
    /// @param totalRewards total rewards to be deposited
    function depositRewardPeriodRewards(uint256 rewardPeriodId, uint256 totalRewards) public onlyOwner {
        PeriodStaking.depositRewardPeriodRewards(periodStakingStorage, rewardPeriodId, totalRewards);
    }

    /// @dev Get staking score of a wallet for a certain staking period
    /// @param wallet wallet address
    /// @param period staking period id
    function getWalletRewardPeriodStakingScore(address wallet, uint256 period) public view returns (uint256) {
        return PeriodStaking.getWalletRewardPeriodStakingScore(periodStakingStorage, wallet, period);
    }

    /// @dev stake Lending Pool Token during reward period
    /// @param amount amount of Lending Pool Token to stake
    function stakeRewardPeriod(uint256 amount) external {
        PeriodStaking.stakeRewardPeriod(periodStakingStorage, amount, lendingPoolToken);
    }

    /// @dev unstake Lending Pool Token during reward period
    /// @param amount amount of Lending Pool Token to unstake
    function unstakeRewardPeriod(uint256 amount) external {
        PeriodStaking.unstakeRewardPeriod(periodStakingStorage, amount, lendingPoolToken);
    }

    /// @dev claim rewards of staking period
    /// @param rewardPeriodId staking period id
    function claimRewardPeriod(uint256 rewardPeriodId) external {
        PeriodStaking.claimRewardPeriod(periodStakingStorage, rewardPeriodId, lendingPoolToken);
    }

    /// @dev calculate rewards for a wallet of a certain staking period
    /// @param wallet wallet address
    /// @param rewardPeriodId staking period id
    /// @param projectedTotalRewards projected total rewards for staking period
    function calculateWalletRewardsPeriod(
        address wallet,
        uint256 rewardPeriodId,
        uint256 projectedTotalRewards
    ) public view returns (uint256) {
        return
            PeriodStaking.calculateWalletRewardsPeriod(
                periodStakingStorage,
                wallet,
                rewardPeriodId,
                projectedTotalRewards
            );
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
// (C) Florence Finance, 2022 - https://florence.finance/
pragma solidity 0.8.9;

interface ILendingPoolFactory {
    event LendingPoolCreated(string indexed id, address indexed proxyAddress);
    event LendingPoolFactoryUpgrade(address indexed fromFactory, address indexed toFactory);
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int)", p0));
	}

	function logUint(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
	}

	function log(uint p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
	}

	function log(uint p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
	}

	function log(uint p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
	}

	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
	}

	function log(uint p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
	}

	function log(uint p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
	}

	function log(uint p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
	}

	function log(uint p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
	}

	function log(uint p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
	}

	function log(uint p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
	}

	function log(uint p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
	}

	function log(uint p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
	}

	function log(uint p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
	}

	function log(uint p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
	}

	function log(uint p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
	}

	function log(bool p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
	}

	function log(bool p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
	}

	function log(bool p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
	}

	function log(address p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
	}

	function log(address p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
	}

	function log(address p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
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
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/Proxy.sol)

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
     * This function does not return to its internal call site, it will return directly to the external caller.
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
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeacon.sol";
import "../../interfaces/draft-IERC1822.sol";
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
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlot.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822Proxiable(newImplementation).proxiableUUID() returns (bytes32 slot) {
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
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822Proxiable {
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
// (C) Florence Finance, 2022 - https://florence.finance/
pragma solidity 0.8.9;

import "./interfaces/ILendingPoolToken.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title LendingPoolToken
/// @author Florence Finance
/// @dev Every LendingPool has its own LendingPoolToken which can be minted and burned by the LendingPool
contract LendingPoolToken is ERC20, ILendingPoolToken, Ownable {
    /// @dev
    /// @param _lendingPoolId (uint256) id of the LendingPool this token belongs to
    /// @param _name (string) name of the token (see ERC20)
    /// @param _symbol (string) symbol of the token (see ERC20)
    // solhint-disable-next-line
    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {}

    /// @dev Allows owner to mint tokens.
    /// @param _receiver (address) receiver of the minted tokens
    /// @param _amount (uint256) the amount to mint (18 decimals)
    function mint(address _receiver, uint256 _amount) external override onlyOwner {
        require(_amount > 0, "LendingPoolToken: invalidAmount");
        _mint(_receiver, _amount);
    }

    /// @dev Allows owner to burn tokens.
    /// @param _amount (uint256) the amount to burn (18 decimals)
    function burn(uint256 _amount) external override {
        require(_amount > 0, "LendingPoolToken: invalidAmount");
        _burn(msg.sender, _amount);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
// (C) Florence Finance, 2022 - https://florence.finance/
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @dev Interface of the Lending Pool contract and IERC20 standard as defined in the EIP.
 */
interface ILendingPool {
    event LendingPoolInitialized(address _address, string id, address lendingPoolToken);
    event FundingTokenUpdated(IERC20 token, bool accepted);
    event PrimaryFunderUpdated(address primaryFunder, bool accepted);
    event BorrowerUpdated(address borrower, bool accepted);
    event FundingRequestAdded(uint256 id, address borrower, uint256 amount, uint256 durationDays, uint256 interestRate);
    event FundingRequestCancelled(
        uint256 fundingRequestId,
        uint256 fundingRequestAmount,
        uint256 fundingRequestAmountFilled,
        uint256 latestFundingRequestId
    );

    event RewardTokensPerBlockUpdated(
        IERC20 stakedToken,
        IERC20 rewardToken,
        uint256 oldRewardTokensPerBlock,
        uint256 newRewardTokensPerBlock
    );
    event RewardsLockedUpdated(IERC20 stakedToken, IERC20 rewardToken, bool rewardsLocked);

    event Funded(
        address indexed funder,
        IERC20 fundingToken,
        uint256 fundingTokenAmount,
        uint256 lendingPoolTokenAmount
    );
    event PrincipalDeposited(address depositor, uint256 amount);
    event RewardsDeposited(address depositor, IERC20 rewardToken, uint256 amount);

    event PrincipalTransferedToTreasury(uint256 amount);
    event RewardsTransferedToTreasury(IERC20 rewardToken, uint256 amount);
    event LendingPoolTokensRedeemed(
        address redeemer,
        uint256 lendingPoolTokenAmount,
        IERC20 principalToken,
        uint256 principalTokenAmount
    );

    event StakedLinear(address indexed staker, IERC20 indexed stakableToken, uint256 amount);
    event UnstakedLinear(address indexed unstaker, IERC20 indexed stakedToken, uint256 amount);
    event ClaimedRewardsLinear(address indexed claimer, IERC20 stakedToken, IERC20 rewardToken, uint256 amount);

    event StakedPeriod(address indexed staker, IERC20 indexed stakableToken, uint256 amount);
    event UnstakedPeriod(address indexed unstaker, IERC20 indexed stakedToken, uint256 amount);
    event ClaimedRewardsPeriod(address indexed claimer, IERC20 stakedToken, IERC20 rewardToken, uint256 amount);
}

// SPDX-License-Identifier: GPL-2.0-or-later
// (C) Florence Finance, 2022 - https://florence.finance/
pragma solidity 0.8.9;

import "./Util.sol";

/// @title Period staking contract
/// @dev this library contains all funcionality related to the period staking mechanism
/// Lending Pool Token (LPT) owner stake their LPTs within an active staking period (e.g. staking period could be three months)
/// The LPTs can remain staked over several consecutive periods while accumulating staking rewards (currently USDC token).
/// The amount of staking rewards depends on the total staking score per staking period of the LPT owner address and
/// on the total amount of rewards distrubuted for this staking period
/// E.g. Staking period is 90 days and total staking rewards is 900 USDC
/// LPT staker 1 stakes 100 LPTs during the whole 90 days
/// LPT staker 2 starts staking after 45 days and stakes 100 LPTs until the end of the staking period
/// staker 1 staking score is 600 and staker 2 staking score is 300
/// staker 1 claims 600 USDC after staking period is completed
/// staker 2 claims 300 USDC after staking period is completed
/// the staking rewards need to be claimed actively after each staking period is completed and the total rewards have been deposited to the contract by the Borrower

library PeriodStaking {
    event StakedPeriod(address indexed staker, IERC20 indexed stakableToken, uint256 amount);
    event UnstakedPeriod(address indexed unstaker, IERC20 indexed stakedToken, uint256 amount);
    event ClaimedRewardsPeriod(address indexed claimer, IERC20 stakedToken, IERC20 rewardToken, uint256 amount);

    struct WalletStakingState {
        uint256 stakedBalance;
        uint256 lastUpdate;
        mapping(IERC20 => uint256) outstandingRewards;
    }

    struct PeriodStakingStorage {
        mapping(uint256 => RewardPeriod) rewardPeriods;
        mapping(address => WalletStakingState) walletStakedAmounts;
        mapping(uint256 => mapping(address => uint256)) walletStakingScores;
        uint256 currentRewardPeriodId;
        uint256 duration;
        IERC20 rewardToken;
    }

    struct RewardPeriod {
        uint256 start;
        uint256 end;
        uint256 totalRewards;
        uint256 totalStakingScore;
        uint256 finalStakedAmount;
        IERC20 rewardToken;
    }

    /// @dev Get the struct/info of all reward periods
    /// @param periodStakingStorage pointer to period staking storage struct
    /// @return returns the array including all reward period structs
    function getRewardPeriods(PeriodStakingStorage storage periodStakingStorage)
        external
        view
        returns (RewardPeriod[] memory)
    {
        RewardPeriod[] memory rewardPeriodsArray = new RewardPeriod[](periodStakingStorage.currentRewardPeriodId);

        for (uint256 i = 1; i <= periodStakingStorage.currentRewardPeriodId; i++) {
            RewardPeriod storage rewardPeriod = periodStakingStorage.rewardPeriods[i];
            rewardPeriodsArray[i - 1] = rewardPeriod;
        }
        return rewardPeriodsArray;
    }

    /// @dev Start the next reward period
    /// @param periodStakingStorage pointer to period staking storage struct
    function startNextRewardPeriod(PeriodStakingStorage storage periodStakingStorage) external {
        //require: periodStakingStorage.duration && periodStakingStorage.rewardToken
        RewardPeriod storage currentRewardPeriod = periodStakingStorage.rewardPeriods[
            periodStakingStorage.currentRewardPeriodId
        ];
        if (periodStakingStorage.currentRewardPeriodId > 0) {
            require(currentRewardPeriod.end > 0 && currentRewardPeriod.end < block.number, "nP1");
        }

        periodStakingStorage.currentRewardPeriodId += 1;
        RewardPeriod storage nextRewardPeriod = periodStakingStorage.rewardPeriods[
            periodStakingStorage.currentRewardPeriodId
        ];
        nextRewardPeriod.rewardToken = periodStakingStorage.rewardToken;
        nextRewardPeriod.start = currentRewardPeriod.end != 0 ? currentRewardPeriod.end : block.number;
        nextRewardPeriod.end = nextRewardPeriod.start + periodStakingStorage.duration;
        nextRewardPeriod.finalStakedAmount = currentRewardPeriod.finalStakedAmount;
        nextRewardPeriod.totalStakingScore =
            currentRewardPeriod.finalStakedAmount *
            (nextRewardPeriod.end - nextRewardPeriod.start);
    }

    /// @dev Deposit the rewards (USDC token) for a reward period
    /// @param periodStakingStorage pointer to period staking storage struct
    /// @param rewardPeriodId The ID of the reward period
    /// @param _totalRewards total amount of period rewards to deposit
    function depositRewardPeriodRewards(
        PeriodStakingStorage storage periodStakingStorage,
        uint256 rewardPeriodId,
        uint256 _totalRewards
    ) public {
        RewardPeriod storage rewardPeriod = periodStakingStorage.rewardPeriods[rewardPeriodId];

        require(rewardPeriod.end > 0 && rewardPeriod.end < block.number, "period has not ended");

        periodStakingStorage.rewardPeriods[rewardPeriodId].totalRewards = Util.checkedTransferFrom(
            rewardPeriod.rewardToken,
            msg.sender,
            address(this),
            _totalRewards
        );
    }

    /// @dev Updates the staking score for a wallet over all staking periods
    /// @param periodStakingStorage pointer to period staking storage struct
    function updatePeriod(PeriodStakingStorage storage periodStakingStorage) internal {
        WalletStakingState storage walletStakedAmount = periodStakingStorage.walletStakedAmounts[msg.sender];
        if (
            walletStakedAmount.stakedBalance > 0 &&
            walletStakedAmount.lastUpdate < periodStakingStorage.currentRewardPeriodId &&
            walletStakedAmount.lastUpdate > 0
        ) {
            uint256 i = walletStakedAmount.lastUpdate + 1;
            for (; i <= periodStakingStorage.currentRewardPeriodId; i++) {
                RewardPeriod storage rewardPeriod = periodStakingStorage.rewardPeriods[i];
                periodStakingStorage.walletStakingScores[i][msg.sender] =
                    walletStakedAmount.stakedBalance *
                    (rewardPeriod.end - rewardPeriod.start);
            }
        }
        walletStakedAmount.lastUpdate = periodStakingStorage.currentRewardPeriodId;
    }

    /// @dev Calculate the staking score for a wallet for a given rewards period
    /// @param periodStakingStorage pointer to period staking storage struct
    /// @param wallet wallet address
    /// @param period period ID for which to calculate the staking rewards
    /// @return wallet staking score for a given rewards period
    function getWalletRewardPeriodStakingScore(
        PeriodStakingStorage storage periodStakingStorage,
        address wallet,
        uint256 period
    ) public view returns (uint256) {
        WalletStakingState storage walletStakedAmount = periodStakingStorage.walletStakedAmounts[wallet];
        RewardPeriod storage rewardPeriod = periodStakingStorage.rewardPeriods[period];
        if (walletStakedAmount.lastUpdate > 0 && walletStakedAmount.lastUpdate < period) {
            return walletStakedAmount.stakedBalance * (rewardPeriod.end - rewardPeriod.start);
        } else {
            return periodStakingStorage.walletStakingScores[period][wallet];
        }
    }

    /// @dev Stake Lending Pool Token in current rewards period
    /// @notice emits event StakedPeriod
    /// @param periodStakingStorage pointer to period staking storage struct
    /// @param amount amount of LPT to stake
    /// @param lendingPoolToken Lending Pool Token address
    function stakeRewardPeriod(
        PeriodStakingStorage storage periodStakingStorage,
        uint256 amount,
        IERC20 lendingPoolToken
    ) external {
        RewardPeriod storage currentRewardPeriod = periodStakingStorage.rewardPeriods[
            periodStakingStorage.currentRewardPeriodId
        ];
        require(
            currentRewardPeriod.start <= block.number && currentRewardPeriod.end > block.number,
            "no active period"
        );

        updatePeriod(periodStakingStorage);

        amount = Util.checkedTransferFrom(lendingPoolToken, msg.sender, address(this), amount);
        emit StakedPeriod(msg.sender, lendingPoolToken, amount);

        periodStakingStorage.walletStakedAmounts[msg.sender].stakedBalance += amount;
        currentRewardPeriod.finalStakedAmount += amount;

        currentRewardPeriod.totalStakingScore += (currentRewardPeriod.end - block.number) * amount;

        periodStakingStorage.walletStakingScores[periodStakingStorage.currentRewardPeriodId][msg.sender] +=
            (currentRewardPeriod.end - block.number) *
            amount;
    }

    /// @dev Unstake Lending Pool Token
    /// @notice emits event UnstakedPeriod
    /// @param periodStakingStorage pointer to period staking storage struct
    /// @param amount amount of LPT to unstake
    /// @param lendingPoolToken Lending Pool Token address
    function unstakeRewardPeriod(
        PeriodStakingStorage storage periodStakingStorage,
        uint256 amount,
        IERC20 lendingPoolToken
    ) external {
        require(
            amount <= periodStakingStorage.walletStakedAmounts[msg.sender].stakedBalance,
            "amount greater than staked amount"
        );
        updatePeriod(periodStakingStorage);

        RewardPeriod storage currentRewardPeriod = periodStakingStorage.rewardPeriods[
            periodStakingStorage.currentRewardPeriodId
        ];

        periodStakingStorage.walletStakedAmounts[msg.sender].stakedBalance -= amount;
        currentRewardPeriod.finalStakedAmount -= amount;
        if (currentRewardPeriod.end > block.number) {
            currentRewardPeriod.totalStakingScore -= (currentRewardPeriod.end - block.number) * amount;
            periodStakingStorage.walletStakingScores[periodStakingStorage.currentRewardPeriodId][msg.sender] -=
                (currentRewardPeriod.end - block.number) *
                amount;
        }

        lendingPoolToken.transfer(msg.sender, amount);
        emit UnstakedPeriod(msg.sender, lendingPoolToken, amount);
    }

    /// @dev Claim rewards (USDC) for a certain staking period
    /// @notice emits event ClaimedRewardsPeriod
    /// @param periodStakingStorage pointer to period staking storage struct
    /// @param rewardPeriodId period ID of which to claim staking rewards
    /// @param lendingPoolToken Lending Pool Token address
    function claimRewardPeriod(
        PeriodStakingStorage storage periodStakingStorage,
        uint256 rewardPeriodId,
        IERC20 lendingPoolToken
    ) external {
        RewardPeriod storage rewardPeriod = periodStakingStorage.rewardPeriods[rewardPeriodId];
        require(
            rewardPeriod.end > 0 && rewardPeriod.end < block.number && rewardPeriod.totalRewards > 0,
            "period not ready for claiming"
        );
        updatePeriod(periodStakingStorage);

        require(periodStakingStorage.walletStakingScores[rewardPeriodId][msg.sender] > 0, "no rewards to claim");

        uint256 payableRewardAmount = calculatePeriodRewards(
            rewardPeriod.rewardToken,
            rewardPeriod.totalRewards,
            rewardPeriod.totalStakingScore,
            periodStakingStorage.walletStakingScores[rewardPeriodId][msg.sender]
        );
        periodStakingStorage.walletStakingScores[rewardPeriodId][msg.sender] = 0;

        // This condition can never be true, because:
        // calculateRewardsPeriod can never have a walletStakingScore > totalPeriodStakingScore
        // require(payableRewardAmount > 0, "no rewards to claim");

        rewardPeriod.rewardToken.transfer(msg.sender, payableRewardAmount);
        emit ClaimedRewardsPeriod(msg.sender, lendingPoolToken, rewardPeriod.rewardToken, payableRewardAmount);
    }

    /// @dev Calculate the staking rewards of a staking period for a wallet address
    /// @param periodStakingStorage pointer to period staking storage struct
    /// @param rewardPeriodId period ID for which to calculate the rewards
    /// @param projectedTotalRewards The amount of total rewards which is planned to be deposited at the end of the staking period
    /// @return returns the amount of staking rewards for a wallet address for a certain staking period
    function calculateWalletRewardsPeriod(
        PeriodStakingStorage storage periodStakingStorage,
        address wallet,
        uint256 rewardPeriodId,
        uint256 projectedTotalRewards
    ) public view returns (uint256) {
        RewardPeriod storage rewardPeriod = periodStakingStorage.rewardPeriods[rewardPeriodId];
        if (projectedTotalRewards == 0) {
            projectedTotalRewards = rewardPeriod.totalRewards;
        }
        return
            calculatePeriodRewards(
                rewardPeriod.rewardToken,
                projectedTotalRewards,
                rewardPeriod.totalStakingScore,
                getWalletRewardPeriodStakingScore(periodStakingStorage, wallet, rewardPeriodId)
            );
    }

    /// @dev Calculate the total amount of payable rewards
    /// @param rewardToken The reward token (e.g. USDC)
    /// @param totalPeriodRewards The total amount of rewards for a certain period
    /// @param totalPeriodStakingScore The total staking score (of all wallet addresses during a certain staking period)
    /// @param walletStakingScore The total staking score (of one wallet address during a certain staking period)
    /// @return returns the total payable amount of staking rewards
    function calculatePeriodRewards(
        IERC20 rewardToken,
        uint256 totalPeriodRewards,
        uint256 totalPeriodStakingScore,
        uint256 walletStakingScore
    ) public view returns (uint256) {
        uint256 rewardTokenDecimals = Util.getERC20Decimals(rewardToken);
        uint256 payableRewardAmount = Util.percent(
            (walletStakingScore * totalPeriodRewards),
            totalPeriodStakingScore,
            rewardTokenDecimals
        );
        // We need to devide after the calculation, so that the 'rest' is cut off
        return payableRewardAmount / (uint256(10)**rewardTokenDecimals);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
// (C) Florence Finance, 2022 - https://florence.finance/
pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "./Util.sol";

/// @title Linear staking contract
/// @dev this library contains all funcionality related to the linear staking mechanism
/// Curve Token owner stake their curve token and receive Medici (MDC) token as rewards.
/// The amount of reward token (MDC) is calculated based on:
/// - the number of staked curve token
/// - the number of blocks the curve tokens are beig staked
/// - the amount of MDC rewards per Block per staked curve token
/// E.g. 10 MDC reward token per block per staked curve token
/// staker 1 stakes 100 curve token and claims rewards (MDC) after 200 Blocks
/// staker 1 recieves 200000 MDC reward tokens (200 blocks * 10 MDC/Block/CurveToken * 100 CurveToken)

library LinearStaking {
    event RewardTokensPerBlockUpdated(
        IERC20 stakedToken,
        IERC20 rewardToken,
        uint256 oldRewardTokensPerBlock,
        uint256 newRewardTokensPerBlock
    );
    event RewardsLockedUpdated(IERC20 stakedToken, IERC20 rewardToken, bool rewardsLocked);

    event StakedLinear(address indexed staker, IERC20 indexed stakableToken, uint256 amount);
    event UnstakedLinear(address indexed unstaker, IERC20 indexed stakedToken, uint256 amount);
    event ClaimedRewardsLinear(address indexed claimer, IERC20 stakedToken, IERC20 rewardToken, uint256 amount);

    event RewardsDeposited(address depositor, IERC20 rewardToken, uint256 amount);
    event RewardsTransferedToTreasury(IERC20 rewardToken, uint256 amount);

    struct LinearStakingStorage {
        /// @dev configuration of rewards for particular stakable tokens
        mapping(IERC20 => RewardConfiguration) rewardConfigurations;
        /// @dev storage of accumulated staking rewards for the pool participants addresses
        mapping(address => mapping(IERC20 => WalletStakingState)) walletStakingStates;
        /// @dev amount of tokens available to be distributed as staking rewards
        mapping(IERC20 => uint256) availableRewards;
    }

    struct RewardConfiguration {
        bool isStakable;
        IERC20[] rewardTokens;
        // mapping(IERC20 => uint256) rewardTokensPerBlock; //Old, should be removed when new algorithm is implemented

        // RewardToken => BlockNumber => RewardTokensPerBlock
        mapping(IERC20 => mapping(uint256 => uint256)) rewardTokensPerBlockHistory;
        // RewardToken => BlockNumbers/Keys of rewardTokensPerBlockHistory[RewardToken][BlockNumbers]
        mapping(IERC20 => uint256[]) rewardTokensPerBlockHistoryBlocks;
        mapping(IERC20 => bool) rewardsLocked;
    }

    struct WalletStakingState {
        uint256 stakedBalance;
        uint256 lastUpdate;
        mapping(IERC20 => uint256) outstandingRewards;
    }

    /// @dev Sets the rewardTokensPerBlock for a stakedToken-rewardToken pair
    /// @param linearStakingStorage pointer to linear staking storage struct
    /// @param stakedToken the staked token
    /// @param rewardToken the reward token
    /// @param rewardTokensPerBlock rewardTokens per rewardToken per block (rewardToken decimals)
    function setRewardTokensPerBlockLinear(
        LinearStakingStorage storage linearStakingStorage,
        IERC20 stakedToken,
        IERC20 rewardToken,
        uint256 rewardTokensPerBlock
    ) public {
        require(
            address(stakedToken) != address(0) && address(rewardToken) != address(0),
            "token adress cannot be zero"
        );

        RewardConfiguration storage rewardConfiguration = linearStakingStorage.rewardConfigurations[stakedToken];

        uint256[] storage rewardTokensPerBlockHistoryBlocks = rewardConfiguration.rewardTokensPerBlockHistoryBlocks[
            rewardToken
        ];

        uint256 currentRewardTokensPerBlock = 0;

        if (rewardTokensPerBlockHistoryBlocks.length > 0) {
            uint256 lastRewardTokensPerBlockBlock = rewardTokensPerBlockHistoryBlocks[
                rewardTokensPerBlockHistoryBlocks.length - 1
            ];
            currentRewardTokensPerBlock = rewardConfiguration.rewardTokensPerBlockHistory[rewardToken][
                lastRewardTokensPerBlockBlock
            ];
        }

        require(
            rewardTokensPerBlock != currentRewardTokensPerBlock,
            "rewardTokensPerBlock already set to expected value"
        );

        if (rewardTokensPerBlock != 0 && currentRewardTokensPerBlock == 0) {
            rewardConfiguration.rewardTokens.push(rewardToken);
        }

        rewardConfiguration.isStakable = rewardTokensPerBlock != 0;

        rewardConfiguration.rewardTokensPerBlockHistory[rewardToken][block.number] = rewardTokensPerBlock;
        rewardTokensPerBlockHistoryBlocks.push(block.number);

        emit RewardTokensPerBlockUpdated(stakedToken, rewardToken, currentRewardTokensPerBlock, rewardTokensPerBlock);
    }

    /// @dev Locks/Unlocks the reward token (MDC) for a certain staking token (Curve Token)
    /// @param linearStakingStorage pointer to linear staking storage struct
    /// @param stakedToken the staked token
    /// @param rewardToken the reward token
    /// @param rewardsLocked true = lock rewards; false = unlock rewards
    function setRewardsLockedLinear(
        LinearStakingStorage storage linearStakingStorage,
        IERC20 stakedToken,
        IERC20 rewardToken,
        bool rewardsLocked
    ) public {
        require(
            address(stakedToken) != address(0) && address(rewardToken) != address(0),
            "token adress cannot be zero"
        );

        if (linearStakingStorage.rewardConfigurations[stakedToken].rewardsLocked[rewardToken] != rewardsLocked) {
            linearStakingStorage.rewardConfigurations[stakedToken].rewardsLocked[rewardToken] = rewardsLocked;
            emit RewardsLockedUpdated(stakedToken, rewardToken, rewardsLocked);
        }
    }

    /// @dev Staking of a stakable token
    /// @param linearStakingStorage pointer to linear staking storage struct
    /// @param stakableToken the stakeable token
    /// @param amount the amount to stake (stakableToken decimals)
    function stakeLinear(
        LinearStakingStorage storage linearStakingStorage,
        IERC20 stakableToken,
        uint256 amount
    ) public {
        require(amount > 0, "amount must be greater zero");
        require(linearStakingStorage.rewardConfigurations[stakableToken].isStakable, "token is not stakable");
        updateRewardSnapshotLinear(linearStakingStorage, msg.sender, stakableToken);
        linearStakingStorage.walletStakingStates[msg.sender][stakableToken].stakedBalance += Util.checkedTransferFrom(
            stakableToken,
            msg.sender,
            address(this),
            amount
        );
        emit StakedLinear(msg.sender, stakableToken, amount);
    }

    /// @dev Unstaking of a staked token
    /// @param linearStakingStorage pointer to linear staking storage struct
    /// @param stakedToken the staked token
    /// @param amount the amount to unstake
    function unstakeLinear(
        LinearStakingStorage storage linearStakingStorage,
        IERC20 stakedToken,
        uint256 amount
    ) public {
        amount = Math.min(amount, linearStakingStorage.walletStakingStates[msg.sender][stakedToken].stakedBalance);
        require(amount > 0, "amount must be greater zero");
        updateRewardSnapshotLinear(linearStakingStorage, msg.sender, stakedToken);
        linearStakingStorage.walletStakingStates[msg.sender][stakedToken].stakedBalance -= amount;
        stakedToken.transfer(msg.sender, amount);
        emit UnstakedLinear(msg.sender, stakedToken, amount);
    }

    /// @dev Updates the outstanding rewards for a specific wallet and staked token. This needs to be called every time before any changes to staked balances are made
    /// @param linearStakingStorage pointer to linear staking storage struct
    /// @param wallet the wallet
    /// @param stakedToken the staked token
    function updateRewardSnapshotLinear(
        LinearStakingStorage storage linearStakingStorage,
        address wallet,
        IERC20 stakedToken
    ) internal {
        uint256 lastUpdate = linearStakingStorage.walletStakingStates[wallet][stakedToken].lastUpdate;

        if (lastUpdate != 0) {
            IERC20[] memory rewardTokens = linearStakingStorage.rewardConfigurations[stakedToken].rewardTokens;
            for (uint256 i = 0; i < rewardTokens.length; i++) {
                IERC20 rewardToken = rewardTokens[i];
                uint256 newOutstandingRewards = calculateRewardsLinear(
                    linearStakingStorage,
                    wallet,
                    stakedToken,
                    rewardToken
                );
                linearStakingStorage.walletStakingStates[wallet][stakedToken].outstandingRewards[
                        rewardToken
                    ] = newOutstandingRewards;
            }
        }
        linearStakingStorage.walletStakingStates[wallet][stakedToken].lastUpdate = block.number;
    }

    /// @dev Calculates the outstanding rewards for a wallet, staked token and reward token
    /// @param linearStakingStorage pointer to linear staking storage struct
    /// @param wallet the wallet
    /// @param stakedToken the staked token
    /// @param rewardToken the reward token
    /// @return the outstading rewards (rewardToken decimals)
    function calculateRewardsLinear(
        LinearStakingStorage storage linearStakingStorage,
        address wallet,
        IERC20 stakedToken,
        IERC20 rewardToken
    ) public view returns (uint256) {
        uint256 lastUpdate = linearStakingStorage.walletStakingStates[wallet][stakedToken].lastUpdate;

        if (lastUpdate != 0) {
            uint256 stakedBalance = linearStakingStorage.walletStakingStates[wallet][stakedToken].stakedBalance /
                10**Util.getERC20Decimals(stakedToken);

            uint256 accumulatedRewards; // = 0

            uint256 rewardRangeStart;
            uint256 rewardRangeStop = block.number;
            uint256 rewardRangeTokensPerBlock;
            uint256 rewardRangeBlocks;

            uint256[] memory fullHistory = linearStakingStorage
                .rewardConfigurations[stakedToken]
                .rewardTokensPerBlockHistoryBlocks[rewardToken];
            uint256 i = fullHistory.length - 1;
            for (; i >= 0; i--) {
                rewardRangeStart = fullHistory[i];

                rewardRangeTokensPerBlock = linearStakingStorage
                    .rewardConfigurations[stakedToken]
                    .rewardTokensPerBlockHistory[rewardToken][fullHistory[i]];

                if (rewardRangeStart < lastUpdate) {
                    rewardRangeStart = lastUpdate;
                }

                rewardRangeBlocks = rewardRangeStop - rewardRangeStart;

                accumulatedRewards += stakedBalance * rewardRangeBlocks * rewardRangeTokensPerBlock;

                if (rewardRangeStart == lastUpdate) break;

                rewardRangeStop = rewardRangeStart;
            }

            uint256 outStandingRewards = linearStakingStorage
            .walletStakingStates[wallet][stakedToken].outstandingRewards[rewardToken];

            return (outStandingRewards + accumulatedRewards);
        }
        return 0;
    }

    /// @dev Claims all rewards for a staked tokens
    /// @param linearStakingStorage pointer to linear staking storage struct
    /// @param stakedToken the staked token
    function claimRewardsLinear(LinearStakingStorage storage linearStakingStorage, IERC20 stakedToken) public {
        updateRewardSnapshotLinear(linearStakingStorage, msg.sender, stakedToken);

        IERC20[] memory rewardTokens = linearStakingStorage.rewardConfigurations[stakedToken].rewardTokens;
        for (uint256 i = 0; i < rewardTokens.length; i++) {
            IERC20 rewardToken = rewardTokens[i];

            if (linearStakingStorage.rewardConfigurations[stakedToken].rewardsLocked[rewardToken]) {
                //rewards for the token are not claimable yet
                continue;
            }

            uint256 rewardAmount = linearStakingStorage.walletStakingStates[msg.sender][stakedToken].outstandingRewards[
                rewardToken
            ];
            uint256 payableRewardAmount = Math.min(rewardAmount, linearStakingStorage.availableRewards[rewardToken]);
            require(payableRewardAmount > 0, "no rewards available for payout");

            linearStakingStorage.walletStakingStates[msg.sender][stakedToken].outstandingRewards[
                    rewardToken
                ] -= payableRewardAmount;
            linearStakingStorage.availableRewards[rewardToken] -= payableRewardAmount;

            rewardToken.transfer(msg.sender, payableRewardAmount);
            emit ClaimedRewardsLinear(msg.sender, stakedToken, rewardToken, payableRewardAmount);
        }
    }

    /// @dev Allows the deposit of reward funds. This is usually used by the borrower or treasury
    /// @param linearStakingStorage pointer to linear staking storage struct
    /// @param rewardToken the reward token
    /// @param amount the amount of tokens (rewardToken decimals)
    function depositRewardsLinear(
        LinearStakingStorage storage linearStakingStorage,
        IERC20 rewardToken,
        uint256 amount
    ) public {
        linearStakingStorage.availableRewards[rewardToken] += Util.checkedTransferFrom(
            rewardToken,
            msg.sender,
            address(this),
            amount
        );
        emit RewardsDeposited(msg.sender, rewardToken, amount);
    }

    /// @dev Get the staked balance for a specific token and wallet
    /// @param linearStakingStorage pointer to linear staking storage struct
    /// @param wallet the wallet
    /// @param stakableToken the staked token
    /// @return the staked balance (stakableToken decimals)
    function getStakedBalanceLinear(
        LinearStakingStorage storage linearStakingStorage,
        address wallet,
        IERC20 stakableToken
    ) public view returns (uint256) {
        return linearStakingStorage.walletStakingStates[wallet][stakableToken].stakedBalance;
    }

    /// @dev Allows the withdrawal of reward funds to the treasury
    /// @param linearStakingStorage pointer to linear staking storage struct
    /// @param rewardToken the reward token
    /// @param amount the amount to be withdrawn
    function transferRewardsToTreasury(
        LinearStakingStorage storage linearStakingStorage,
        IERC20 rewardToken,
        uint256 amount,
        address treasury
    ) public {
        require(amount <= linearStakingStorage.availableRewards[rewardToken], "amount exceeds available rewards");
        linearStakingStorage.availableRewards[rewardToken] -= Util.checkedTransfer(rewardToken, treasury, amount);
        emit RewardsTransferedToTreasury(rewardToken, amount);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
// (C) Florence Finance, 2022 - https://florence.finance/
pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "../interfaces/ILendingPoolToken.sol";
import "./Util.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/// @title Funding contract
/// @dev this library contains all funcionality related to the funding mechanism
/// A borrower creates a new funding request to fund an amount of Lending Pool Token (LPT)
/// A whitelisted primary funder buys LPT from the open funding request with own USDC
/// The treasury wallet is a MultiSig wallet
/// The funding request can be cancelled by the borrower

library Funding {
    event FundingRequestAdded(uint256 id, address borrower, uint256 amount, uint256 durationDays, uint256 interestRate);
    event FundingRequestCancelled(
        uint256 fundingRequestId,
        uint256 fundingRequestAmount,
        uint256 fundingRequestAmountFilled,
        uint256 latestFundingRequestId
    );
    event Funded(
        address indexed funder,
        IERC20 fundingToken,
        uint256 fundingTokenAmount,
        uint256 lendingPoolTokenAmount
    );
    event LendingPoolTokensRedeemed(
        address redeemer,
        uint256 lendingPoolTokenAmount,
        IERC20 principalToken,
        uint256 principalTokenAmount
    );

    event PrincipalDeposited(address depositor, uint256 amount);

    event PrincipalTransferedToTreasury(uint256 amount);

    event FundingTokenUpdated(IERC20 token, bool accepted);

    event PrimaryFunderUpdated(address primaryFunder, bool accepted);

    event BorrowerUpdated(address borrower, bool accepted);

    enum FundingRequestState {
        OPEN,
        FILLED,
        CANCELLED
    }

    struct FundingRequest {
        uint256 id;
        address borrower;
        uint256 amount;
        uint256 durationDays;
        uint256 interestRate;
        uint256 amountFilled;
        FundingRequestState state;
        uint256 next; // ID of next exntry
        uint256 prev; // ID of previous entry
    }

    struct FundingStorage {
        mapping(uint256 => FundingRequest) fundingRequests;
        uint256 currentID; // current funding request ID
        uint256 lastID; // last given funding request ID
        /// @dev addresses of primary funders and their whitelist status
        mapping(address => bool) primaryFunders;
        /// @dev tokens the pool can be funded with
        mapping(IERC20 => bool) fundingTokens;
        IERC20[] _fundingTokens;
        /// @dev amount of principal capital ready to be used for LendingPoolToken redemption
        uint256 availablePrincipal;
        /// @dev token the of the principal capital
        IERC20 principalToken;
        /// @dev addresses of borrowers and their status
        mapping(address => bool) borrowers;
        /// @dev
        mapping(IERC20 => AggregatorV3Interface) tokenChainlinkFeedMapping;
        /// @dev
        mapping(IERC20 => bool) invertExchangeRate;
    }

    /// @dev get array of funding requests
    /// @param fundingStorage pointer to funding storage struct
    /// @return Array including all funding request structs
    function getFundingRequests(FundingStorage storage fundingStorage) external view returns (FundingRequest[] memory) {
        uint256 amountFundingRequests = fundingStorage.lastID - fundingStorage.currentID;
        FundingRequest[] memory fundingRequestArray = new FundingRequest[](amountFundingRequests + 1);
        uint256 j = 0;
        for (uint256 i = fundingStorage.currentID; i <= fundingStorage.lastID; i++) {
            FundingRequest storage fundingRequest = fundingStorage.fundingRequests[i];
            fundingRequestArray[j++] = fundingRequest;
        }
        return fundingRequestArray;
    }

    /// @dev Add funding request
    /// @param fundingStorage pointer to funding storage struct
    /// @param amount total amount of LPT to request funding for
    /// @param durationDays the duration of the funding request (e.g. three months)
    /// @param interestRate the announced interest rate for the funding
    function addFundingRequest(
        FundingStorage storage fundingStorage,
        uint256 amount,
        uint256 durationDays,
        uint256 interestRate
    ) public {
        require(amount > 0 && durationDays > 0 && interestRate > 0, "invalid funding request data");

        uint256 prevLastID = fundingStorage.lastID;

        fundingStorage.lastID++;

        if (prevLastID != 0) {
            fundingStorage.fundingRequests[prevLastID].next = fundingStorage.lastID;
        }

        emit FundingRequestAdded(fundingStorage.lastID, msg.sender, amount, durationDays, interestRate);

        fundingStorage.fundingRequests[fundingStorage.lastID] = FundingRequest(
            fundingStorage.lastID,
            msg.sender,
            amount,
            durationDays,
            interestRate,
            0,
            FundingRequestState.OPEN,
            0, // next ID
            prevLastID // prev ID
        );

        if (fundingStorage.currentID == 0) {
            fundingStorage.currentID = fundingStorage.lastID;
        }
    }

    /// @dev Cancel a funding request
    /// @param fundingStorage pointer to funding storage struct
    /// @param fundingRequestId the id of the funding request to cancel
    function cancelFundingRequest(FundingStorage storage fundingStorage, uint256 fundingRequestId) public {
        require(fundingStorage.fundingRequests[fundingRequestId].id != 0, "funding request not found");
        require(
            fundingStorage.fundingRequests[fundingRequestId].state == FundingRequestState.OPEN,
            "funding request already processing"
        );

        emit FundingRequestCancelled(
            fundingRequestId,
            fundingStorage.fundingRequests[fundingRequestId].amount,
            fundingStorage.fundingRequests[fundingRequestId].amountFilled,
            fundingStorage.lastID
        );

        fundingStorage.fundingRequests[fundingRequestId].state = FundingRequestState.CANCELLED;

        FundingRequest storage currentRequest = fundingStorage.fundingRequests[fundingRequestId];

        if (currentRequest.prev != 0) {
            fundingStorage.fundingRequests[currentRequest.prev].next = currentRequest.next;
        }

        if (currentRequest.next != 0) {
            fundingStorage.fundingRequests[currentRequest.next].prev = currentRequest.prev;
        }

        uint256 saveNext = fundingStorage.fundingRequests[fundingRequestId].next;
        fundingStorage.fundingRequests[fundingRequestId].prev = 0;
        fundingStorage.fundingRequests[fundingRequestId].next = 0;

        if (fundingStorage.currentID == fundingRequestId) {
            fundingStorage.currentID = saveNext; // can be zero which is fine
        }
    }

    /// @dev Allows primary funders to fund the pool
    /// @param fundingStorage pointer to funding storage struct
    /// @param fundingToken token used for the funding (e.g. USDC)
    /// @param fundingTokenAmount funding amount
    /// @param lendingPoolToken the Lending Pool Token
    function fund(
        FundingStorage storage fundingStorage,
        IERC20 fundingToken,
        uint256 fundingTokenAmount,
        ILendingPoolToken lendingPoolToken
    ) public {
        require(fundingStorage.primaryFunders[msg.sender], "address is not primary funder");
        require(fundingStorage.fundingTokens[fundingToken], "unrecognized funding token");
        require(fundingStorage.currentID != 0, "no active funding request");

        uint256 lendingPoolTokenAmount = convertFundingTokenToLendingPoolToken(
            fundingStorage,
            fundingToken,
            fundingTokenAmount,
            lendingPoolToken
        );

        FundingRequest storage currentFundingRequest = fundingStorage.fundingRequests[fundingStorage.currentID];
        uint256 currentFundingNeed = currentFundingRequest.amount - currentFundingRequest.amountFilled;

        require(lendingPoolTokenAmount <= currentFundingNeed, "amount exceeds requested funding");
        Util.checkedTransferFrom(fundingToken, msg.sender, currentFundingRequest.borrower, fundingTokenAmount);
        currentFundingRequest.amountFilled += lendingPoolTokenAmount;

        if (currentFundingRequest.amount == currentFundingRequest.amountFilled) {
            currentFundingRequest.state = FundingRequestState.FILLED;

            fundingStorage.currentID = currentFundingRequest.next; // this can be zero which is ok
        }

        lendingPoolToken.mint(msg.sender, lendingPoolTokenAmount);
        emit Funded(msg.sender, fundingToken, fundingTokenAmount, lendingPoolTokenAmount);
    }

    /// @dev Get an exchange rate for an ERC20<>Currnecy conversion
    /// @param fundingStorage pointer to funding storage struct
    /// @param token the token
    /// @return the exchange rate and the decimals of the exchange rate
    function getExchangeRate(FundingStorage storage fundingStorage, IERC20 token) public view returns (uint256, uint8) {
        require(address(fundingStorage.tokenChainlinkFeedMapping[token]) != address(0), "no exchange rate available");

        (, int256 exchangeRate, , , ) = fundingStorage.tokenChainlinkFeedMapping[token].latestRoundData();
        require(exchangeRate != 0, "zero exchange rate");

        uint8 exchangeRateDecimals = fundingStorage.tokenChainlinkFeedMapping[token].decimals();

        if (fundingStorage.invertExchangeRate[token]) {
            exchangeRate = int256(10**(exchangeRateDecimals * 2)) / exchangeRate;
        }

        return (uint256(exchangeRate), exchangeRateDecimals);
    }

    /// @dev Adds a mapping between a token, currency and ChainLink price feed
    /// @param fundingStorage pointer to funding storage struct
    /// @param token the token
    /// @param chainLinkFeed the ChainLink price feed
    /// @param _invertExchangeRate whether the rate returned by the chainLinkFeed needs to be inverted to match the token-currency pair order
    function setTokenChainLinkFeedMapping(
        FundingStorage storage fundingStorage,
        IERC20 token,
        AggregatorV3Interface chainLinkFeed,
        bool _invertExchangeRate
    ) external {
        fundingStorage.tokenChainlinkFeedMapping[token] = chainLinkFeed;
        fundingStorage.invertExchangeRate[token] = _invertExchangeRate;
    }

    /// @dev Converts amount of fundingToken to LendingPoolToken using ExchangeRateProvider
    /// @param fundingStorage pointer to funding storage struct
    /// @param fundingToken the funding token
    /// @param fundingTokenAmount the amount to be converted
    /// @param lendingPoolToken the Lending Pool Token
    /// @return the amount of lendingPoolTokens (LendingPoolToken decimals (18))
    function convertFundingTokenToLendingPoolToken(
        FundingStorage storage fundingStorage,
        IERC20 fundingToken,
        uint256 fundingTokenAmount,
        ILendingPoolToken lendingPoolToken
    ) private view returns (uint256) {
        (uint256 exchangeRate, uint256 exchangeRateDecimals) = getExchangeRate(fundingStorage, fundingToken);
        return ((Util.convertDecimalsERC20(fundingTokenAmount, fundingToken, lendingPoolToken) *
            (uint256(10)**exchangeRateDecimals)) / exchangeRate);
    }

    /// @dev Allows the deposit of principal funds. This is usually used by the borrower or treasury
    /// @param fundingStorage pointer to funding storage struct
    /// @param amount the amount of principal (principalToken decimals)
    function depositPrincipal(FundingStorage storage fundingStorage, uint256 amount) public {
        fundingStorage.availablePrincipal += Util.checkedTransferFrom(
            fundingStorage.principalToken,
            msg.sender,
            address(this),
            amount
        );
        emit PrincipalDeposited(msg.sender, amount);
    }

    /// @dev Allows the withdrawal of principal funds to the treasury
    /// @param fundingStorage pointer to funding storage struct
    /// @param amount the amount to be withdrawn
    /// @param treasury the treasury address
    function transferPrincipalToTreasury(
        FundingStorage storage fundingStorage,
        uint256 amount,
        address treasury
    ) public {
        require(amount <= fundingStorage.availablePrincipal, "amount exceeds available principal");
        fundingStorage.availablePrincipal -= Util.checkedTransfer(fundingStorage.principalToken, treasury, amount);
        emit PrincipalTransferedToTreasury(amount);
    }

    /// @dev Set whether a token should be accepted for funding the pool
    /// @param fundingStorage pointer to funding storage struct
    /// @param fundingToken the token
    /// @param accepted whether it is accepted
    function setFundingToken(
        FundingStorage storage fundingStorage,
        IERC20 fundingToken,
        bool accepted
    ) public {
        if (fundingStorage.fundingTokens[fundingToken] != accepted) {
            fundingStorage.fundingTokens[fundingToken] = accepted;
            emit FundingTokenUpdated(fundingToken, accepted);
            if (accepted) {
                fundingStorage._fundingTokens.push(fundingToken);
            } else {
                Util.removeValueFromArray(fundingToken, fundingStorage._fundingTokens);
            }
        }
    }

    /// @dev Change primaryFunder status of an address
    /// @param fundingStorage pointer to funding storage struct
    /// @param primaryFunder the address
    /// @param accepted whether its accepted as primaryFunder
    function setPrimaryFunder(
        FundingStorage storage fundingStorage,
        address primaryFunder,
        bool accepted
    ) public {
        if (fundingStorage.primaryFunders[primaryFunder] != accepted) {
            fundingStorage.primaryFunders[primaryFunder] = accepted;
            emit PrimaryFunderUpdated(primaryFunder, accepted);
        }
    }

    /// @dev Change borrower status of an address
    /// @param fundingStorage pointer to funding storage struct
    /// @param borrower the borrower address
    /// @param accepted whether its accepted as primaryFunder (true or false)
    function setBorrower(
        FundingStorage storage fundingStorage,
        address borrower,
        bool accepted
    ) public {
        if (fundingStorage.borrowers[borrower] != accepted) {
            fundingStorage.borrowers[borrower] = accepted;
            emit BorrowerUpdated(borrower, accepted);
            if (fundingStorage.borrowers[msg.sender]) {
                fundingStorage.borrowers[msg.sender] = false;
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

// SPDX-License-Identifier: GPL-2.0-or-later
// (C) Florence Finance, 2022 - https://florence.finance/
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/**
 * @dev Interface of the Lending Pool contract and IERC20 standard as defined in the EIP.
 */
interface ILendingPoolToken is IERC20Metadata {
    function mint(address _address, uint256 _amount) external;

    function burn(uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

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
contract ERC20 is Context, IERC20, IERC20Metadata {
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
    constructor(string memory name_, string memory symbol_) {
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
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
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
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
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

// SPDX-License-Identifier: GPL-2.0-or-later
// (C) Florence Finance, 2022 - https://florence.finance/
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "../interfaces/ILendingPool.sol";

library Util {
    /// @dev Return the decimals of an ERC20 token (if the implementations offers it)
    /// @param _token (IERC20) the ERC20 token
    /// @return  (uint8) the decimals
    function getERC20Decimals(IERC20 _token) internal view returns (uint8) {
        return IERC20Metadata(address(_token)).decimals();
    }

    function checkedTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal returns (uint256) {
        require(amount > 0, "checkedTransferFrom: amount zero");
        uint256 balanceBefore = token.balanceOf(to);
        token.transferFrom(from, to, amount);
        uint256 receivedAmount = token.balanceOf(to) - balanceBefore;
        require(receivedAmount == amount, "checkedTransferFrom: not amount");
        return receivedAmount;
    }

    function checkedTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) public returns (uint256) {
        require(amount > 0, "checkedTransfer: amount zero");
        uint256 balanceBefore = token.balanceOf(to);
        token.transfer(to, amount);
        uint256 receivedAmount = token.balanceOf(to) - balanceBefore;
        require(receivedAmount == amount, "checkedTransfer: not amount");
        return receivedAmount;
    }

    /// @dev Converts a number from one decimal precision to the other
    /// @param _number (uint256) the number
    /// @param _currentDecimals (uint256) the current decimals of the number
    /// @param _targetDecimals (uint256) the desired decimals for the number
    /// @return  (uint256) the number with _targetDecimals decimals
    function convertDecimals(
        uint256 _number,
        uint256 _currentDecimals,
        uint256 _targetDecimals
    ) public pure returns (uint256) {
        uint256 diffDecimals;

        uint256 amountCorrected = _number;

        if (_targetDecimals < _currentDecimals) {
            diffDecimals = _currentDecimals - _targetDecimals;
            amountCorrected = _number / (uint256(10)**diffDecimals);
        } else if (_targetDecimals > _currentDecimals) {
            diffDecimals = _targetDecimals - _currentDecimals;
            amountCorrected = _number * (uint256(10)**diffDecimals);
        }

        return (amountCorrected);
    }

    function convertDecimalsERC20(
        uint256 _number,
        IERC20 _sourceToken,
        IERC20 _targetToken
    ) public view returns (uint256) {
        return convertDecimals(_number, getERC20Decimals(_sourceToken), getERC20Decimals(_targetToken));
    }

    function percent(
        uint256 numerator,
        uint256 denominator,
        uint256 precision
    ) public pure returns (uint256 quotient) {
        // caution, check safe-to-multiply here
        uint256 _numerator = numerator * 10**(precision + 1);
        // with rounding of last digit
        uint256 _quotient = ((_numerator / denominator) + 5) / 10;
        return (_quotient);
    }

    function removeValueFromArray(IERC20 value, IERC20[] storage array) public {
        bool shift = false;
        uint256 i = 0;
        while (i < array.length - 1) {
            if (array[i] == value) shift = true;
            if (shift) {
                array[i] = array[i + 1];
            }
            i++;
        }
        array.pop();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}