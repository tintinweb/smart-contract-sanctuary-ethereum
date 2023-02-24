// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "./interfaces/IEconomyEngineV1Factory.sol";
import "./interfaces/IEconomyAddressesProvider.sol";
import "./engines/staking/StakingEngine.sol";
import "./engines/staking/StakingBasket.sol";
import "./engines/pledge/PledgeEngine.sol";

import "hardhat/console.sol";

/// @author
/// @title Economy Engine Factory v3 for Ink Economy System
/// @dev EconomyEngineV1Factory is used to create different engines in the Ink Economy System.
contract EconomyEngineV1Factory is IEconomyEngineV1Factory {

    address immutable stakingEngineImplementation;

    address immutable stakingBasketImplementation;

    ///@dev mapping for created engines, key is the address of creator.
    mapping(address => address[]) private enginesByOwner;

    ///@dev mapping for created engines, key is the address of governance token.
    mapping(address => address[]) private enginesByToken;

    ///@dev address of Ink Addresses Provider contract
    address private _addressProvider;

    ///@dev owner address of Economy factory
    address private _owner;

    modifier onlyDaoOwner() {
        require(msg.sender == IEconomyAddressesProvider(_addressProvider).getInkFinanceAdmin(), 
            "Not verified Admin of Ink Root DAO");
        _;
    }

    constructor(address addressProvider) {
        _owner = msg.sender;
        _addressProvider = addressProvider;

        stakingEngineImplementation = address(new StakingEngine());
        stakingBasketImplementation = address(new StakingBasket());
    }

    /// @notice Inherit from IEconomyEngineV1Factory
    /// @dev create a staking engine from several parameters.
    /// @param governanceToken erc20 token's address for governance, such as QUILL token
    /// @param initDailyEmission init daily emission for this staking engine
    /// @param accruingPeriod minimum days for claim rewards
    function createStakingEngine(
        address governanceToken, 
        uint256 initDailyEmission, 
        uint256 accruingPeriod,
        uint256 adminTokenIn
    ) 
    external 
    onlyDaoOwner
    override {

        address engineContract = Clones.clone(stakingEngineImplementation);

        address pledgeEngine = getPledgeEngineAddress(engineContract);

        StakingEngine(engineContract).initialize(
            msg.sender, 
            _addressProvider, 
            pledgeEngine,
            governanceToken, 
            initDailyEmission, 
            accruingPeriod,
            adminTokenIn);

        address[] storage _userEngines = enginesByOwner[msg.sender];
        _userEngines.push(engineContract);

        address[] storage _enginesByToken = enginesByToken[governanceToken];
        _enginesByToken.push(engineContract);
        
        createPledgeEngine(pledgeEngine, engineContract);

        emit StakingEngineCreated(msg.sender, engineContract, governanceToken, block.timestamp);
    }    

    /// @dev create a staking basket from several parameters.
    /// @param period days for staking period
    /// @param weight the weight decide how many token would be put into this basket as rewards. (daily).
    /// @return basket address of new created staking basket
    function createStakingBasket(uint256 period, uint256 weight) 
    external 
    override returns (address) {
        address basket = Clones.clone(stakingBasketImplementation);
        StakingBasket(basket).initialize(msg.sender, period, weight);
        return basket;
    }

    function getPledgeEngineAddress(address engineContract) 
    internal 
    returns (address) {
        bytes memory bytecode = type(PledgeEngine).creationCode;
        bytes32 salt = keccak256(
            abi.encodePacked(engineContract, block.number)
        );
        address pledgeContractAddress;

        assembly {
            pledgeContractAddress := create2(
                0,
                add(bytecode, 32),
                mload(bytecode),
                salt
            )
        }

        return pledgeContractAddress;
    }

    /// @notice Inherit from IEconomyEngineV1Factory
    /// @dev create a new pledge engine related with a staking engine
    /// @param pledgeContract precreated pledge engine's address
    /// @param stakingContract staking engine contract's address
    function createPledgeEngine(
        address pledgeContract,
        address stakingContract
    ) 
    internal {
        PledgeEngine(pledgeContract).initialize(
            msg.sender,
            stakingContract
        );

        emit PledgeEngineCreated(msg.sender, pledgeContract, block.timestamp);
    }

    /// @notice not implemented yet
    /// @dev create new sponsorship engine from the various params
    /// @return engine address of new created sponshorship engine
    function createSponsorEngine() 
    external 
    returns (address engine) {
        
    }

    /// @notice Inherit from IEconomyEngineV1Factory
    /// @dev get all engines filtered by msg.sender and type
    /// @return array of owned engines from msg.sender
    function getCreatedEngines() 
    external 
    view override returns(address[] memory) {
        return enginesByOwner[msg.sender];
    }

    /// @notice Inherit from IEconomyEngineV1Factory    
    /// @dev get all engines filtered by governancetoken and type
    /// @param token governance token's address
    /// @return array of owned engines which governancetoken is same with the token param
    function getEnginesByToken(address token) 
    external 
    view override returns(address[] memory) {
        return enginesByToken[token];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.4;

/// @title The interface for the Ink Finannce StakingEngine v3 Factory
interface IEconomyEngineV1Factory {
    
    /// @notice Emitted when a staking engine is created
    event StakingEngineCreated(address indexed owner, address indexed engine, address govToken, uint256 createTime);

    /// @notice Emitted when a pledge engine is created
    event PledgeEngineCreated(address indexed owner, address indexed engine, uint256 createTime);

    /// @notice Creates new staking engine for the Dao creator
    /// @dev Each staking engine will have main governance token and daily emission curve, valid duration days.
    /// @param governanceToken the engine's main governance token
    /// @param initDailyEmission init daily emission for this staking engine
    /// @param accruingPeriod minimum days for claim reward
    function createStakingEngine(address governanceToken, uint256 initDailyEmission, uint256 accruingPeriod, uint256 adminTokenIn) external;

    /// @notice Creates a staking basket for the dao users
    /// @param period the basket's valid principal expired days
    /// @param weight weight of new basket
    /// @return basket the created basket's address
    function createStakingBasket(uint256 period, uint256 weight) external returns (address);

    /// @notice Get all staking engines created by caller
    /// @dev Dao creators can get all own staking engines using this.
    /// @return engines array of engines created by msg.sender/
    function getCreatedEngines() external view returns (address[] memory engines);

    /// @notice Get all staking engines related with the governance token
    /// @dev Dao creators can get all own staking engines that use this token as governance token.
    /// @return engines array of engines that use this token as governance token
    function getEnginesByToken(address token) external view returns (address[] memory engines);
}

/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title Ink Economy Addresses Provider Contract Interface
/// @dev Main registry of addresses part of or connected to the Ink Economy, including permissioned roles
/// - Acting also as factory of proxies and admin of those, so with right to change its implementations
/// - Owned by the Ink Economy Super Admin
/// @author Ink Finanace

interface IEconomyAddressesProvider {

    event InkEngineCreatorUpdated(address indexed newAddress);
    
    event EconomyEngineFactoryUpdated(address indexed newAddress);

    event DaoGovernanceUpdated(address indexed newAddress);
    
    event InkGovernanceTokenUpdated(address indexed newAddress);
    
    event PriceOracleUpdated(address indexed newAddress);

    event ServerWalletUpdated(address indexed newAddress);
    
    event ProxyCreated(bytes32 id, address indexed newAddress);
    
    event AddressSet(bytes32 id, address indexed newAddress, bool hasProxy);
    
    function setAddress(bytes32 id, address newAddress) external;

    function getAddress(bytes32 id) external view returns (address);

    function getInkFinanceAdmin() external view returns (address);

    function setInkEngineCreatorImpl(address inkAdmin) external;

    function getEconomyEngineFactory() external view returns (address);

    function setEconomyEngineFactoryImpl(address factory) external;

    function getInkDaoGovernance() external view returns (address);

    function setInkDaoGovernanceImpl(address daogovernance) external;

    function getInkGovernanceToken() external view returns (address);

    function setInkGovernanceTokenImpl(address daogovernance) external;

    function getPriceOracle() external view returns (address);

    function setPriceOracle(address priceOracle) external;

    function getServerWallet() external view returns (address);

    function setServerWallet(address serverWallet) external;
}

/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../interfaces/IEconomyAddressesProvider.sol";
import "../../interfaces/IEconomyEngineV1Factory.sol";
import "../../interfaces/IStakingEngine.sol";
import "../../interfaces/IPledgeEngine.sol";
import "../../interfaces/IStakingBasket.sol";
import "../../libraries/LDatetime.sol";
import "../../libraries/PRBMathUD60x18.sol";
import "../pools/EmissionPool.sol";
import "../../dao/IRootDaoGovernance.sol";
// import "hardhat/console.sol";

/// @notice Ken
/// @title Ink Finance v3 staking engine
/// @dev StakingEngine is used to create and manage a number of staking baskets, 
///     one emission pool and interface for staking mechanism
contract StakingEngine is IStakingEngine, Initializable {

    /// @notice Emitted when basket address is zero
    error STKEngine_InvalidBasket(address basket);

    /// @notice Emitted when staker address is zero
    error STKEngine_InvalidStaker(address staker);

        /// @notice Emitted when trust or client address is zero
    error STKEngine_InvalidTrustClient();

    /// @notice Emitted when token address is zero
    error STKEngine_InvalidToken(address token);

    /// @notice Emitted when principal token's convertion ratio is not valid
    error STKEngine_InvalidConvRatio(address token, uint256 ratio);

    /// @notice Emitted when invalid day id will be entered
    error STKEngine_InvalidDayId(uint256 dayId);

    /// @notice Emitted when terms info is not valid
    error STKEngine_InvalidTermsDay();

    /// @notice Emitted when token amount is not valid
    error STKEngine_InvalidAmount(uint256 amount);

    /// @notice Emitted when basket weight is smaller than 1.0
    error STKEngine_InvalidBasketWeight();

    /// @notice Emitted when invalid token will be entered in staking
    error STKEngine_NotAddedTokenInEngine(address token);

    /// @notice Emitted when token will not be transfered successully
    error STKEngine_FailedTokenTransfer(address token);

    /// @notice Emitted when msg.sender is not engine creator
    error STKEngine_OnlyEngineCreator();

    /// @notice Emitted when msg.sender is not pledge engine
    error STKEngine_OnlyPledgeEngine();

    using LDatetime for uint256;

    /// @dev address of IEconomyEngineV1Factory instance
    IEconomyEngineV1Factory private _engineFactory;

    /// @dev the creator of this staking engine instance
    address private _engineCreator;

    /// @dev address of Ink Governance Module contract
    address private _inkRootDao;

    /// @dev address of pledge engine related with staking engine
    address public pledgeEngineContract;

    /// @dev interface variable for one emission pool
    address private _emissionPool;

    /// @dev staking token address
    address private _stakingToken;

    /// @dev init daily emission token amount, K: Emission (days) = K * Power(A, Power(B, days))
    uint256 private _initDailyEmission;

    /// @dev minimum days for DAO user to claim reward from the staking engine
    uint256 private _accruingPeriod;

    /// @dev array of created staking baskets, maybe optimized later
    address[] _baskets;

    /// @dev array of erc20 tokens for staking in  
    address[] private _principalTokens;

    /// @dev array of ratios for each erc20 token
    mapping(address => uint256) _conversionRatios;

    /// @dev start timestamp of this engine
    uint256 private _beginDayId;

    /// @dev admin token in
    uint256 private _adminTokenIn;
    uint256 private _adminTokenClaimed;

    /// @dev last time of this engine
    uint256 private _prevSettledDate;
    uint256 private _currSettledDate;

    /// @dev staked token's balance of this engine
    uint256 private _prevStakedTokens;
    uint256 private _currStakedTokens;

    /// @dev reward ratios of this engine
    uint256 private _prevRewardRatio;
    uint256 private _currRewardRatio;

    /// @dev trust contract's address
    address private _trustAddress; 
    mapping(bytes32 => address) private _itemRewardsTo;

    /// @dev throws if called by any account other than the creator of this staking engine
    modifier onlyOwner() {
        if (msg.sender != _engineCreator)
            revert STKEngine_OnlyEngineCreator();
        _;
    }

    /// @dev throws if called by valid basket address
    modifier validBasket(address basket) {
        if (basket == address(0))
            revert STKEngine_InvalidBasket(basket);
        _;
    }

    /// @dev throws if called by valid staker address
    modifier validStaker(address staker) {
        if (staker == address(0))
            revert STKEngine_InvalidStaker(staker);
        _;
    }

    /// @dev throws if called by valid token address
    modifier validToken(address token) {
        if (token == address(0))
            revert STKEngine_InvalidToken(token);
        _;
    }

    /// @dev see {EconomyEngineV1Factory-createStakingEngine} for more infos about params
    function initialize(
        address engineCreator, 
        address addressProvider,
        address pledgeEngine,
        address stakingToken, 
        uint256 initDailyEmission, 
        uint256 accruingPeriod,
        uint256 adminTokenIn) 
    public initializer
    {
        /// @dev exception handling
        _engineFactory = IEconomyEngineV1Factory(msg.sender);

        if (stakingToken == address(0))
            revert STKEngine_InvalidToken(stakingToken);

        /// @dev initialize state variables
        _engineCreator = engineCreator;
        _inkRootDao = IEconomyAddressesProvider(addressProvider).getInkDaoGovernance();        
        _stakingToken = stakingToken;
        _accruingPeriod = accruingPeriod;
        _initDailyEmission = initDailyEmission;
        _beginDayId = block.timestamp.getDayID();
        _currSettledDate = block.timestamp;

        pledgeEngineContract = pledgeEngine;

        /// @dev set mapping for primary token
        _principalTokens.push(stakingToken);
        _conversionRatios[stakingToken] = 1 ether;

        /// @dev create new emission pool for real token transfer
        _emissionPool = address(new EmissionPool(_stakingToken));   

        _adminTokenIn = adminTokenIn;
        _updateGlobals(true, adminTokenIn);
    }

    /// @dev add liquidity of governance token for daily reward
    /// @param amount governance token's balance for daily reward
    function addLiquidity(uint256 amount) 
    public onlyOwner {
        if (amount == 0) 
            revert STKEngine_InvalidAmount(amount);
        
        if (!IERC20(_stakingToken).transferFrom(msg.sender, _emissionPool, amount)) {
            revert STKEngine_FailedTokenTransfer(_stakingToken);
        }
    }

    /// @notice For the DAO super user, can be used to add principal token and ratio in to a staking basket.
    /// @dev add principal token and ratio to engine one by one, and will be used to calculate the effective staking balance.
    /// @param principalToken array of available erc20 token address for staking in  
    /// @param conversionRatio array of conversion ratio for each erc20 token
    function addPrincipalCurrencyToEngine(address principalToken, uint256 conversionRatio) 
    external 
    override onlyOwner validToken(principalToken) {

        if (conversionRatio == 0) 
            revert STKEngine_InvalidConvRatio(principalToken, conversionRatio);

        /// @dev set mapping for token ratios
        if (_conversionRatios[principalToken] == 0) {
            _principalTokens.push(principalToken);            
        }
        _conversionRatios[principalToken] = conversionRatio;
    } 

    /// @notice For the DAO super user, can be used to create a staking basket.
    /// @dev create a staking basket from several parameters.
    /// @param termDays term days for staking period
    /// @param weight the weight decide how many token would be put into this basket as rewards. (daily).
    function createStakingBasket(
        uint256 termDays,
        uint256 weight
    ) external 
    override onlyOwner {
        if (termDays == 0)
            revert STKEngine_InvalidTermsDay();

        if (weight < PRBMathUD60x18.SCALE)
            revert STKEngine_InvalidBasketWeight();

        /// @dev create a new basket
        address basket = _engineFactory.createStakingBasket(termDays, weight);
                
        /// @dev add the created basket into _baskets array
        _baskets.push(basket);

        /// @dev add basketPool into emissionPool for token trasnfer
        address basketPool = IStakingBasket(basket).getBasketPool();
        IEmissionPool(_emissionPool).addBasketPool(basketPool);

        /// @dev emit the event StakingBasketCreated with basket address
        emit StakingBasketCreated(basket);
    }

    /// @notice Inherit from IStakingEngine
    /// @dev provide the all avaialbe staking-in tokens' array
    /// @return tokens array of staking tokens' addresses
    function getStakingTokensAddresses() 
    external 
    override view returns (address[] memory) 
    {
        return _principalTokens;
    }

    /// @notice Inherit from IStakingEngine
    /// @dev provide the all avaialbe staking-in token' ratio
    /// @param token principal token's address for querying the ratio
    /// @return ratio staking token' ratio
    function getStakingTokenRatio(address token) 
    external 
    override view returns (uint256) 
    {
        return _conversionRatios[token];
    }

    /// @notice Inherit from IStakingEngine
    /// @dev provide the all staking items in one basket for any staker
    /// @param basket basket addres for getting items
    /// @return items array of staking items from basket and msg.sender
    function getStakingItems(address basket) 
    external validBasket(basket)
    view override returns (LStakingItem.StakingItem[] memory) {
        return IStakingBasket(basket).getStakingItems(msg.sender);
    }

    /// @notice Inherit from IStakingEngine
    /// @return pool address of the emission pool for this staking engine
    function getEmissionPool() 
    external 
    view override returns (address) {
        return _emissionPool;
    }

    /// @notice Inherit from IStakingEngine
    /// @dev stake in a basket with a token, see {StakingBasket-stake} for more details.
    /// @param basket specific basket address for staking
    /// @param token erc20 token address, must be exist in available staking-in tokens' array
    /// @param amount erc20 token amount
    function stake(address basket, address token, uint256 amount) 
    external 
    override validBasket(basket) validToken(token) {
        bytes32 itemId = _stake(msg.sender, basket, token, amount);
        emit BasketStaked(msg.sender, basket, itemId);    
    }

    function _stake(address owner, address basket, address token, uint256 amount)
    internal 
    returns(bytes32) {
        if (amount == 0)
            revert STKEngine_InvalidAmount(amount);

        if (_conversionRatios[token] == 0) {
            revert STKEngine_NotAddedTokenInEngine(token);
        }

        /// transfer token to emission pool
        if (!IERC20(token).transferFrom(msg.sender, _emissionPool, amount)) {
            revert STKEngine_FailedTokenTransfer(token);
        }

        /// calculate effective staking value from ratios
        uint256 _effectiveStakingValue = (1 ether * amount) / _conversionRatios[token];        

        /// update globals
        _updateGlobals(true, _effectiveStakingValue);

        /// stake in the basket
        bytes32 itemId = IStakingBasket(basket).stake(
            owner, 
            token, 
            amount, 
            _effectiveStakingValue,
            _prevRewardRatio
        );

        return itemId;
    }

    /// @notice Inherit from IStakingEngine
    /// @dev when DAO user unstake an item, all accrued reward also be withdrawn, regardless of the accruing period
    /// @param basket basket address for unstaking
    /// @param itemId staking item's id in the basket for unstaking
    function unstake(address basket, bytes32 itemId) 
    external 
    override validBasket(basket) {    
        _unstake(basket, itemId, address(0));
        emit BasketUnstaked(msg.sender, basket, itemId);
    }

    function _unstake(address basket, bytes32 itemId, address to) 
    internal {
        (LStakingItem.StakingItem memory stakedItem, ) = 
            IStakingBasket(basket).getStakingItemInfo(itemId);

        require(stakedItem.effectiveStakingValue > 0, "Invalid basket and item");

        /// claim rewards
        _claimRewards(basket, itemId, true);

        /// update globals
        _updateGlobals(false, stakedItem.effectiveStakingValue);

        /// unstake from basket
        IStakingBasket(basket).unstake(itemId, to);
    }


    function _updateGlobals(bool plus, uint256 amount)
    internal {
        unchecked {
            _prevSettledDate = _currSettledDate;
            _currSettledDate = block.timestamp;
            _prevStakedTokens = _currStakedTokens;

            if (plus) {
                _currStakedTokens += amount;
            }
            else {
                require(_currStakedTokens >= amount, "Invalid amount updateGlobals");
                _currStakedTokens -= amount;
            }

            if (_prevStakedTokens > 0) {
                _prevRewardRatio = _calculateRewardsRatio(_prevSettledDate, _prevStakedTokens);
            }
        }
    }

    /// @notice Inherit from IStakingEngine
    /// @dev when DAO user earlyRedeem an item, all accrued reward also be withdrawn with penalty, regardless of the accruing period
    /// @param basket basket address for earlyRedeem
    /// @param itemId staking item's id in the basket for earlyRedeem
    /// @param amount balance for earlyRedeem, if 0, it means all balance of this item
    function earlyRedeem(address basket, bytes32 itemId, uint256 amount) 
    external 
    override validBasket(basket) {    
        if (amount == 0)
            revert STKEngine_InvalidAmount(amount);

        (LStakingItem.StakingItem memory stakedItem, ) = 
            IStakingBasket(basket).getStakingItemInfo(itemId);

        require(stakedItem.effectiveStakingValue > 0, "Invalid basket and item");

        /// update globals
        _updateGlobals(false, stakedItem.effectiveStakingValue);

        if (getPenaltySetting()) {
            /// early redeem from basket
            uint256 penaltyRate = _getPenaltyRate(0);
            (uint256 penaltyBalance, uint256 forfeitRewards) = IStakingBasket(basket).earlyRedeem(itemId, penaltyRate, address(0));

            emit BasketEarlyRedeemed(msg.sender, basket, itemId, penaltyBalance, forfeitRewards);
        }
        else {
            /// unstake from basket
            IStakingBasket(basket).unstake(itemId, address(0));

            emit BasketUnstaked(msg.sender, basket, itemId);
        }
    }

    /// @notice Inherit from IStakingEngine
    /// @dev call _claimRewards internal function
    /// @param basket basket address for claiming reward
    /// @param itemId staking item's index in the basket for claiming reward
    function claimRewards(address basket, bytes32 itemId) 
    external 
    override validBasket(basket) {
        /// claim rewards
        _claimRewards(basket, itemId, false);
    }

    /// @notice internal function for claim rewards, it will be called in unstake too.
    /// @dev request to claim rewards for msg.sender's special staking item.
    /// @param basket basket address for claim reward
    /// @param itemId staking item's index in the basket for claim reward
    /// @param checkAccruingPeriod flag whether check accruing period for claim reward
    /// @return remainDays remain days of staking item
    function _claimRewards(address basket, bytes32 itemId, bool checkAccruingPeriod) 
    internal 
    returns (uint256) {
        uint256 _rewardRatio = _calculateRewardsRatio(_currSettledDate, _currStakedTokens);
        
        (address staker, uint256 rewards, uint256 remainDays) = 
        IStakingBasket(basket).claimRewards(
            itemId,
            checkAccruingPeriod ? _accruingPeriod : 0,
            getPenaltySetting(),
            _rewardRatio);
        
        if (rewards > 0) {   
            rewards = PRBMathUD60x18.toUint(rewards);             
            address token = IEmissionPool(_emissionPool).getEmissionToken();
            IEmissionPool(_emissionPool).tokenTransfer(
                staker, 
                token, 
                rewards);
        }

        emit BasketClaimedRewards(staker, rewards);
        return remainDays;
    }

    /// @notice For DAO users, user can estimate the accrued rewards
    /// @param basket staking basket's address to estimate rewards
    /// @param itemId staking item's unique id
    /// @return accruedReward accrued reward balance after staking
    function estimateRewards(address basket, bytes32 itemId) 
    external 
    validBasket(basket)
    override view returns (uint256 accruedReward) {
        uint256 _rewardRatio = _calculateRewardsRatio(_currSettledDate, _currStakedTokens);
        accruedReward = PRBMathUD60x18.toUint(IStakingBasket(basket).estimatedRewards(itemId, _rewardRatio));
    }

    /// @notice For DAO users, user can estimate the accrued rewards
    /// @param basket staking basket's address to estimate rewards
    /// @return accruedReward all of the accrued reward balance in the basket
    function estimateAllRewards(address basket) 
    external 
    validBasket(basket)
    override view returns (uint256 accruedReward) {
        uint256 _rewardRatio = _calculateRewardsRatio(_currSettledDate, _currStakedTokens);
        LStakingItem.StakingItem[] memory _stkItems = IStakingBasket(basket).getStakingItems(msg.sender);
        for (uint256 i = 0; i < _stkItems.length; i++) {
            accruedReward += IStakingBasket(basket).estimatedRewards(_stkItems[i].itemId, _rewardRatio);
        }   
        accruedReward = PRBMathUD60x18.toUint(accruedReward);
    }

    function _calculateRewardsRatio(uint256 beginTime, uint256 total) 
    internal view returns (uint256) {        
        uint256 _days = PRBMathUD60x18.fromUint(
            LDatetime.getDaysBetweenTwoDayId(beginTime.getDayID(), block.timestamp.getDayID())
        );

        unchecked {
            if (total > 0)
                return _prevRewardRatio + _initDailyEmission * _days / total;   
            
            return 0;
        }                
    }

    /// @dev For DAO super users, provide the penalty flag
    /// @return enabled penalty flag
    function getPenaltySetting() 
    public
    view returns (bool) {
        return IRootDaoGovernance(_inkRootDao).getDaoPenaltySetting();
    }

    /// @dev For DAO super users, provide the DAO treasury vault
    /// @return valut DAO treasury vault address
    function getDAOVaultSetting() 
    public
    view returns (address) {
        return IRootDaoGovernance(_inkRootDao).getDaoTreasuryVault();
    }

    function getReclaimableBalance()
    public 
    view returns (uint256 reclaimableBalance) {
        uint256 _rewardRatio = _calculateRewardsRatio(_currSettledDate, _currStakedTokens);
        reclaimableBalance = PRBMathUD60x18.toUint(_adminTokenIn * _rewardRatio);
    }

    /// @notice Inherit from IStakingEngine
    /// @notice For DAO super users, to reclaim Reward balances of dao super user's genesis item to the DAO's treasury vault,
    /// and the vault address must be verified by the staking engine, via calling back the DAO's interface
    function reclaimRewards()
    external
    override onlyOwner {
        address vault = getDAOVaultSetting();

        // reclaim genesis item's rewards
        uint256 balance = getReclaimableBalance();
        IEmissionPool(_emissionPool).reclaimRewards(vault, balance);
    }

    /// @notice Inherit from IStakingEngine
    /// @notice For DAO super users, to reclaim all the Penalty balances of normal user's items to the DAO's treasury vault,
    /// and the vault address must be verified by the staking engine, via calling back the DAO's interface
    function reclaimPenalties()
    external
    override onlyOwner {
        address vault = getDAOVaultSetting();

        // reclaim penaltied tokens
        for (uint256 i = 0; i < _principalTokens.length; i++) {
            IEmissionPool(_emissionPool).reclaimPenalty(
                _principalTokens[i], vault);
        }
    }

    /// @notice Inherit from IStakingEngine
    /// @dev For DAO users, to verify withdrawal amount whether there are enough pledges for them or not.   
    /// @param staker dao user's wallet address for verifying withdrawal amount
    /// @param amount amount for veritying withdrawal of the dao user
    /// @return verified verified result got from the pledge engine
    function verifyWithdrawal(address staker, uint256 amount) 
    external
    override view returns (bool verified) {
        return IPledgeEngine(pledgeEngineContract).verifyWithdrawal(
            staker, 
            _getPledgeValue(staker),
            amount);
    }

    /// @notice Inherit from IStakingEngine
    /// @dev get all the staking baskets with detail information in the staking engine
    /// @return baskets array of staking baskets' address
    function getStakingBaskets() 
    external 
    view override returns (address[] memory) {        
        return _baskets;
    }

    /// @notice Inherit from IStakingEngine
    /// @dev return staking basket information object, see {LStakingBasket-StakingBasketInfo}.
    /// @return basketInfo filled StakingBasketInfo object
    function getStakingBasket(address basket) 
    external validBasket(basket)
    view override returns (LStakingBasket.StakingBasketInfo memory) {
        return IStakingBasket(basket).getBasketInfo();
    }

    /// @notice Inherit from IStakingEngine
    /// @dev provide the all effective staking balance for one staking basket
    /// @param basket basket address for getting effective staking balance
    /// @return principalBalance effective staking balance in pricipal zone
    /// @return bufferBalance effective staking balance in buffer zone    
    function getStakingBasketBalance(address basket) 
    external validBasket(basket)
    view override returns (uint256, uint256)
    {
        return IStakingBasket(basket).getBasketStakingBalanceDayId(getCurrentDayId());
    }

    function _getPenaltyRate(uint256 remainDays)
    internal 
    view returns (uint256) {    
        
    }

    /// @dev can get begin day Id of this staking engine        
    function getBeginDayId() 
    external 
    override view returns (uint256) {
        return _beginDayId;
    }

    /// @dev can get current day Id of this staking engine        
    function getCurrentDayId() 
    public 
    view returns (uint256) {
        return block.timestamp.getDayID();
    }

    /// @notice Inherit from IStakingEngine
    /// @dev can get daily emission from day counts, Emission (day) = Emission (day - 1) * Power(A, Power(B, day))
    /// @param dayId day Id for getting daily emission for this staking engine
    function getDailyEmission(uint256 dayId) 
    external 
    override view returns (uint256, uint256) {          
        require(_beginDayId < dayId, "Invalid day id");
        uint256 totalEmission = LDatetime.getDaysBetweenTwoDayId(_beginDayId, dayId) * _initDailyEmission;

        return (_initDailyEmission, totalEmission);
    }    

    /// @notice Inherit from IStakingEngine    
    /// @dev get effective pledge value for pledge engine
    /// @param staker staker's address
    /// @return effectivePledgeValue balance of effective pledges
    function getPledgeValue(address staker) 
    external 
    validStaker(staker)
    override view returns (uint256 effectivePledgeValue) {
        if (msg.sender != pledgeEngineContract)        
            revert STKEngine_OnlyPledgeEngine();

        effectivePledgeValue = _getPledgeValue(staker);
    }

    /// @notice Internal function of getPledgeValue    
    /// @dev get effective pledge value for pledge engine
    /// @param staker staker's address
    /// @return effectivePledgeValue balance of effective pledges
    function _getPledgeValue(address staker) 
    internal 
    view returns (uint256) {
        uint256 effectivePledgeValue = 0;
        for (uint256 i = 0; i < _baskets.length; i++) {
            uint256 effectiveStakingValue = IStakingBasket(_baskets[i]).getEffectiveStakingValue(staker);
            uint256 weight = IStakingBasket(_baskets[i]).getBasketInfo().weight;
            effectivePledgeValue += PRBMathUD60x18.mul(PRBMathUD60x18.fromUint(effectiveStakingValue), weight);            
        }
        effectivePledgeValue = PRBMathUD60x18.toUint(effectivePledgeValue);
        return effectivePledgeValue;
    }

    /// @dev set trust contract address for staking engine
    /// @param trustAddress trust contract's address
    function addTrustAddress(address trustAddress)
    external
    onlyOwner {
        _trustAddress = trustAddress;
    }

    /// @dev stake token by creator for client, deposit will be extracted from the trust address
    /// @param daoUser trusted dao user's address
    /// @param rewardForUser if true, client owner can call the claimReward to claim his emission rewards, if false, only creator can call claimRewardsForTrust()
    /// @param basket specific basket address for staking
    /// @param token erc20 token address, must be exist in available staking-in tokens' array
    /// @param amount erc20 token amount
    function stakeForTrust(address daoUser, bool rewardForUser, address basket, address token, uint256 amount)
    external override
    onlyOwner {
        if (_trustAddress == address(0)) {
            revert STKEngine_InvalidTrustClient();
        }

        bytes32 itemId = _stake(daoUser, basket, token, amount);

        _itemRewardsTo[itemId] = rewardForUser ? daoUser : _trustAddress;
        emit BasketStaked(msg.sender, basket, itemId);    
    }

    /// @dev unstake token by creator for client
    /// @param basket specific basket address for staking
    /// @param itemId staking item's id for unstaking
    function unstakeForTrust(address basket, bytes32 itemId)
    external override
    onlyOwner {
        _unstake(basket, itemId, _trustAddress);

        delete _itemRewardsTo[itemId];
        emit BasketUnstaked(msg.sender, basket, itemId);
    }

    /// @dev claim rewards for trust contract
    /// @param client address of staking client
    function claimRewardsForTrust(address client) 
    external override
    onlyOwner {
        for (uint256 i = 0; i < _baskets.length; i++) {
            LStakingItem.StakingItem[] memory _items = IStakingBasket(_baskets[i]).getStakingItems(client);
            for (uint256 j = 0; j < _items.length; j++) {
                if (_itemRewardsTo[_items[j].itemId] == _trustAddress) { 
                    _claimRewards(_baskets[i], _items[j].itemId, true);                    
                }
            }            
        }  
    }

    /// @dev get current global variables
    /// @return rewardRatio1
    /// @return rewardRatio2
    /// @return prevTotal
    /// @return currTotal
    function getCurrentGlobalVariables()
    public view returns (uint256 rewardRatio1, uint256 rewardRatio2, uint256 prevTotal, uint256 currTotal) {
        rewardRatio1 =_prevRewardRatio;
        rewardRatio2 = _calculateRewardsRatio(_currSettledDate, _currStakedTokens);
        prevTotal = _prevStakedTokens;
        currTotal = _currStakedTokens;
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../../interfaces/IStakingBasket.sol";
import "../../interfaces/IStakingEngine.sol";
import "../../interfaces/IBasketPool.sol";
import "../../libraries/LDatetime.sol";
import "../../libraries/PRBMathUD60x18.sol";
import "../pools/BasketPool.sol";

// import "hardhat/console.sol";

/// @notice Ken
/// @title Ink Finance v3 staking basket
/// @dev StakingBasket is used to create and manage a number of staking requests with n days from DAO normal user,
///     one basket has one basket pool.
contract StakingBasket is IStakingBasket, Initializable{

    /// @notice Emitted when msg.sender is not staking engine
    error STKBasket_OnlySTKEngine(address caller, address engine);

    /// @notice Emitted when staking item is not valid
    error STKBasket_InvalidSTKItem(bytes32 itemId);

    /// @notice Emitted when staker tries to unstake with overflowed balance
    error STKBasket_OverflowedUnstakeBalance(uint256 request, uint256 available);

    /// @notice Emitted when staker's pledgeable valule will be not enough
    error STKBasket_InsufficientPledges(address staker, uint256 pledges);

    using LDatetime for uint256;
    using EnumerableSet for EnumerableSet.Bytes32Set;

    /// @dev address of parent staking engine
    IStakingEngine private _stakingEngine;

    /// @dev see {StakingEngine-createStakingBasket, rewardWeight parameter}
    uint256 private _weight;
        
    /// @dev see {StakingEngine-createStakingBasket, stakingPeriod parameter}
    uint256 private _stakingPeriod;

    /// @dev see {StakingEngine-createStakingBasket, startTime parameter}
    uint256 private _startDate;

    /// @dev default reward weight for day 1 staking, fixed length float 1.0
    uint256 private _defaultWeight;

    /// @dev address of basket pool contract
    address private _basketPool;

    /// @dev mapping of staking balances, key is staking day id
    mapping(uint256 => LStakingBasket.BasketBalance) private _dailyBalances;

    /// @dev mapping of staking items, key is staker's address, value is staking item index
    mapping(address => EnumerableSet.Bytes32Set) private stakerItems;

    /// @dev mapping of staking items, key is staking item index, value is staking item infomation
    mapping(bytes32 => LStakingItem.StakingItem) private stakingItems;

    /// @dev count of all staking items
    uint256 private _itemsCount;

    /// @dev nounce for generating random
    uint256 private nounce = 0;

    /// @dev throws if called by any account other than the parent staking engine
    modifier allowedStakingEngine() {
        if (msg.sender != address(_stakingEngine))
            revert STKBasket_OnlySTKEngine(msg.sender, address(_stakingEngine));
        _;
    }

    /// @dev throws if called with invalid staking item
    modifier validStakingItem(bytes32 itemId) {        
        if (stakingItems[itemId].staker == address(0))
            revert STKBasket_InvalidSTKItem(itemId);
        _;
    }

    /**
        @dev see {StakingEngine-createStakingBasket} for more infos about params
    */
    function initialize (
        address stakingEngine,
        uint256 stakingPeriod,
        uint256 weight ) 
    public initializer 
    {
        /// @dev set initial variables for staking engine
        _stakingEngine = IStakingEngine(stakingEngine);
        _stakingPeriod = stakingPeriod;
        _startDate = block.timestamp;
        _weight = weight;        
        _defaultWeight = PRBMathUD60x18.fromUint(1);
        
        /// @dev create a new basket pool with tokens array, reward pool, start date, staking period
        address pool = address(new BasketPool(
            _stakingEngine.getEmissionPool(),
            _startDate,
            _stakingPeriod
        ));
        _basketPool = pool;       
    }

    /**
        @dev see {StakingEngine-stake}
    */
    function stake(address staker, address token, uint256 amount, uint256 effective, uint256 rewardRatio) 
    external 
    allowedStakingEngine
    override returns (bytes32 itemId) {
        /// @dev create and add a new staking item
        uint256 stakeTime = _getCurrentTime();
        itemId = _generateItemID(staker);

        LStakingItem.StakingItem storage item = stakingItems[itemId];
        item.itemId = itemId;
        item.staker = staker;
        item.effectiveStakingValue = effective;
        item.endDate = stakeTime.addDays(_stakingPeriod).getDayID();
        item.settledDate = stakeTime.getDayID();
        item.settledReward = 0;
        item.rewardRatio = rewardRatio;

        EnumerableSet.Bytes32Set storage _stkitems = stakerItems[staker];
        _stkitems.add(itemId);

        _itemsCount++;

        /// @dev initialize the staking token vs amount in the basket pool
        IBasketPool(_basketPool).stake(itemId, token, amount);

        emit StakedItem(address(this), itemId, item.effectiveStakingValue, item.endDate);
    }

    /// @dev generate an item id by using nounce and keecake256 hash
    /// @param staker address of staker account
    /// @return new item id
    function _generateItemID(address staker) private returns (bytes32) {
        bytes32 itemId = keccak256(abi.encodePacked(nounce, staker, address(this)));
        nounce++;
        return itemId;
    }
        
    /**
        @dev see {StakingEngine-unstake}
    */
    function unstake(bytes32 itemId, address rewardTo) 
    external 
    allowedStakingEngine
    validStakingItem(itemId)
    override {        
        LStakingItem.StakingItem storage item = stakingItems[itemId];     
        verifyWithdrawal(item.staker, item.effectiveStakingValue);

        if (rewardTo == address(0))
            rewardTo = item.staker;

        /// here, staked token transfers back from the emission pool to the staker's wallet
        IBasketPool(_basketPool).unstake(
            itemId, rewardTo, item.effectiveStakingValue, item.effectiveStakingValue
        );

        /// here, I will remove the staking item on the blockchain,
        _removeStakingItem(itemId);                    

        emit UnstakedItem(address(this), itemId, rewardTo);
    }

    /// @notice called from {StakingEngine-unstake} function
    /// @dev forfeited rewards and principal penalties will move to Reclaim Balances
    /// @param itemId staking item's unique id for earlyRedeem
    /// @param penaltyRate staking item's penalty rate for earlyRedeem
    /// @param rewardTo reward receiver's address
    /// @return penaltyBalance penalty calculated principal balance in staking item
    /// @return forfeitRewards forfeited rewards in staking item
    function earlyRedeem(bytes32 itemId, uint256 penaltyRate, address rewardTo) 
    external      
    allowedStakingEngine 
    validStakingItem(itemId) 
    override returns (uint256 penaltyBalance, uint256 forfeitRewards) {

    }

    /// @notice called from {StakingEngine-claimRewards} function
    /// @dev clear settled rewards for this basket's one staking item
    /// @param itemId staking item's id for clear rewards
    function clearRewards(bytes32 itemId)
    external
    allowedStakingEngine
    validStakingItem(itemId) override {

    }
    
    /// @notice called from {StakingEngine-claimRewards} function
    /// @dev request to claim rewards for msg.sender's special staking item.
    /// @param itemId staking item's index in the basket for claiming reward
    /// @param accruingPeriod minimum days for claiming rewards
    /// @param penaltyFlag penalty setting flag from staking engine
    /// @param rewardRatio staking engine's current reward ratio
    /// @return staker staker who will receive the rewards
    /// @return rewards available cliamed rewards balance
    /// @return remainDays remain days of staking item
    function claimRewards(bytes32 itemId, uint256 accruingPeriod, bool penaltyFlag, uint256 rewardRatio) 
    external 
    allowedStakingEngine
    validStakingItem(itemId)
    override returns (address staker, uint256 rewards, uint256 remainDays) {
        /// here, I have to recalculate the rewards and transfer them to the staker's wallet,
        LStakingItem.StakingItem storage item = stakingItems[itemId];
        require(rewardRatio >= item.rewardRatio, "Invalid reward ratio");

        staker = item.staker;
        (, uint256 currDayId) = _currentDate();

        if (item.endDate <= currDayId) {
            // after staking item matures,
            if (accruingPeriod > 0) {                
                uint256 passDays = item.settledDate.getDaysBetweenTwoDayId(currDayId);                
                if (passDays < accruingPeriod) {
                    revert("Disabled claim reward before accruing period");
                }
            }
        }
        else {
            remainDays = currDayId.getDaysBetweenTwoDayId(item.endDate);
        }
        if (!penaltyFlag || remainDays == 0) {
            uint256 rewardsForItem = item.effectiveStakingValue * (rewardRatio - item.rewardRatio);
            if (rewardsForItem > item.settledReward) {  
                rewards = rewardsForItem - item.settledReward;  
                item.settledDate = _getCurrentTime().getDayID();
                item.settledReward = rewardsForItem;
            }
        }
    }

    /// @notice internal estimate rewards function
    /// @dev return estimated rewards for this basket's one staking item
    /// @param itemId staking item unique id for estimating rewards
    /// @param rewardRatio staking engine's current reward ratio
    /// @return rewardsForItem calculated rewards for staking item
    function estimatedRewards(bytes32 itemId, uint256 rewardRatio) 
    external
    allowedStakingEngine
    override view returns (uint256 rewardsForItem) {
        LStakingItem.StakingItem memory item = stakingItems[itemId];
        require(rewardRatio >= item.rewardRatio, "Invalid reward ratio");

        rewardsForItem = item.effectiveStakingValue * (rewardRatio - item.rewardRatio)
            - item.settledReward;
    }

    /// @dev return current timestamp
    function _getCurrentTime() 
    internal 
    view returns (uint256) {
        return block.timestamp;
    }

    /// @dev calculate staking item's zone type
    /// @param stakingItem staking item's id
    /// @return zone type: true - principal staking item, false - buffer staking item
    function _getItemZoneType(LStakingItem.StakingItem memory stakingItem) 
    internal 
    view returns (bool zone) {        

    }

    /// @dev calculate current staking balances of this budget
    /// @return principalBalance effective staking balance in pricipal zone
    /// @return bufferBalance effective staking balance in buffer zone
    function getBasketStakingBalanceDayId(uint256 dayId) 
    external 
    allowedStakingEngine
    override view returns (uint256 principalBalance, uint256 bufferBalance) {

    }

    /// @dev provide the basket pool for this staking basket
    /// @return address of basket pool
    function getBasketPool() 
    external 
    override view returns (address) {
        return _basketPool;
    }

    /// @dev provide basket information
    function getBasketInfo() 
    external 
    allowedStakingEngine 
    override view returns (LStakingBasket.StakingBasketInfo memory basketInfo) {
        basketInfo.weight = _weight;
        basketInfo.startDate = _startDate;
        basketInfo.stakingPeriod = _stakingPeriod;    
    }

    /// @dev provide the all staking items created by special staker, see {LStakingItem-StakingItem}.
    /// @param staker address of staker who wants to get all staking items.
    function getStakingItems(address staker) 
    external 
    allowedStakingEngine
    override view returns (LStakingItem.StakingItem[] memory items) {
        /// @dev maybe will be optimized later
        EnumerableSet.Bytes32Set storage _set = stakerItems[staker];

        items = new LStakingItem.StakingItem[](_set.length());
        for (uint256 i = 0; i < _set.length(); i++) {
            items[i] = stakingItems[_set.at(i)];
        }
    }    

    /// @dev get token of the staking items in the basket
    /// @param itemId staking item's identity
    /// @return stakedItem staked item object
    /// @return stakedToken staked token address
    function getStakingItemInfo(bytes32 itemId) 
    external 
    override view returns (LStakingItem.StakingItem memory stakedItem, address stakedToken) {
        stakedItem = stakingItems[itemId];
        stakedToken = IBasketPool(_basketPool).principalCurrency(itemId);
    }

    /// @dev provide the all staking items's effective staking value by special staker
    /// @param staker address of staker who wants to get effective staking value
    /// @return effectiveStakingValue balance of effective staking value in the staker's all staking items
    function getEffectiveStakingValue(address staker) 
    external 
    allowedStakingEngine
    override view returns (uint256 effectiveStakingValue) {
        for (uint256 i = 0; i < stakerItems[staker].length(); i++) {
            effectiveStakingValue += stakingItems[stakerItems[staker].at(i)].effectiveStakingValue;
        }
    } 

    function getAllItemsCount()
    external
    allowedStakingEngine
    override view returns (uint256) {
        return _itemsCount;
    }

    function _removeStakingItem(bytes32 itemId) 
    internal {
        _itemsCount--;

        LStakingItem.StakingItem memory item = stakingItems[itemId];        
        stakerItems[item.staker].remove(itemId);
        delete stakingItems[itemId];
    }

    function _currentDate() 
    internal 
    view returns (uint256, uint256) {
        uint256 currTime = _getCurrentTime();
        uint256 currDayId = currTime.getDayID();
        return (currTime, currDayId);
    }

    function _getOneDaySeconds() 
    internal 
    pure returns (uint256) {
        return LDatetime.SECONDS_PER_DAY;
    }

    function verifyWithdrawal(address staker, uint256 effectiveStakingValue) 
    internal view {
        uint256 pledges = PRBMathUD60x18.toUint(
            PRBMathUD60x18.mul(PRBMathUD60x18.fromUint(effectiveStakingValue), _weight)
        );
        if (!_stakingEngine.verifyWithdrawal(staker, pledges)) {
            revert STKBasket_InsufficientPledges(staker, pledges);
        }
    }
}

/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../../interfaces/IPledgeEngine.sol";
import "../../interfaces/IStakingEngine.sol";

// import "hardhat/console.sol";

/// @notice Ken
/// @title Ink Finance v3 pledge engine
/// @dev PledgeEngine is to maintain any dao user's committed pledges in the governance process
contract PledgeEngine is IPledgeEngine, Initializable {

    /// @notice Emitted when the pledges is zero
    error PLGEngine_InvalidPledges(uint256 pledges);

    /// @notice Emitted when the proposal exists already with same id
    error PLGEngine_AlreadyExistProposal(address daoUser, bytes32 proposalId);

    /// @notice Emitted when any proposal doesn't exist with same id
    error PLGEngine_NotExistProposal(address daoUser, bytes32 proposalId);

    /// @notice Emitted when user tries to use more pledges than pledgeable amount
    error PLGEngine_InsufficientPledges(uint256 pledgeableValue, uint256 pledgeRquest);

    bytes32 public constant USER_MANAGER_ROLE = keccak256("USER_MANAGER_ROLE");

    bytes32 public constant USER_VOTER_ROLE = keccak256("USER_VOTER_ROLE");

    address private _stakingEngine;

    address private _inkRootDao;

    mapping(address => bool) private _daos;

    mapping(address => mapping(address => bytes32)) private _userDaoRoles;

    mapping(address => uint256) private _userPledgeValues;

    mapping(address => mapping(bytes32 => LPledgeEngine.PledgeItemInfo)) private _userProposalPledges;

    mapping(address => bytes32[]) private _userProposalIds;

    modifier sufficientPledges(uint256 pledges) {
        if (pledges == 0)
            revert PLGEngine_InvalidPledges(pledges);
        _;
    }

    modifier onlyInkRootDao() {        
        require( _inkRootDao == msg.sender, "Not Ink Root Dao");
        _;
    }

    modifier onlyDaoGovernance() {        
        require( _daos[msg.sender], "Not dao governance");
        _;
    }

    modifier onlyDaoUser(address daoAddress, address daoUser, bytes32 userRole) {
        require(
            _userDaoRoles[daoUser][daoAddress] == userRole,
            "Not verified dao user"
        );
        _;
    }

    modifier onlyStakingEngine() {
         require(msg.sender == _stakingEngine, "Not staking engine");
        _;
    }

    modifier onlyNotExistProposalId(address daoUser, bytes32 proposalId) {
        if (_userProposalPledges[daoUser][proposalId].pledges > 0)
            revert PLGEngine_AlreadyExistProposal(daoUser, proposalId);
        _;
    }

    modifier onlyExistProposalId(address daoUser, bytes32 proposalId) {
        if (_userProposalPledges[daoUser][proposalId].pledges == 0)
            revert PLGEngine_NotExistProposal(daoUser, proposalId);
        _;
    }

    function initialize (address inkDao, address stakingEngine) 
    public initializer {
        _inkRootDao = inkDao;
        _stakingEngine = stakingEngine;
    }

    function removeProposal(address daoUser, bytes32 proposalId)
    internal {
        delete _userProposalPledges[daoUser][proposalId];
        for (uint256 i = 0; i < _userProposalIds[daoUser].length; i++) {
            if (_userProposalIds[daoUser][i] == proposalId) {
                _userProposalIds[daoUser][i] = _userProposalIds[daoUser][
                    _userProposalIds[daoUser].length - 1
                ];
                _userProposalIds[daoUser].pop();
            }
        }
    }

    /// @dev called by Ink Root (Meta) DAO Governance to add or remove the DAO user with Sub DAO address and User roles
    /// @param daoAddress new created Sub DAO's address
    /// @param daoUser DAO user's address
    /// @param userRole new DAO user's role in the Sub DAO (Manager or Voter)
    /// @param addFlag add or remove flag, true - add, false - remove
    function updateDaoUser(address daoAddress, address daoUser, bytes32 userRole, bool addFlag)
    external
    onlyInkRootDao
    override {
        require(
            userRole == USER_MANAGER_ROLE || userRole == USER_VOTER_ROLE,
            "Invalid user role");

        if (addFlag) {
            _daos[daoAddress] = true;
            _userDaoRoles[daoUser][daoAddress] = userRole;
        }
        else {
            delete _daos[daoAddress];
            delete _userDaoRoles[daoUser][daoAddress];
        }

        emit UpdatedDaoUser(daoAddress, daoUser, userRole, addFlag);
    }

    /// @dev called by Staking Engine to make sure that the dao user can support his outstanding pledge
    /// @param daoUser staker's address in Staking Engine
    /// @param effectivePledgeValue effective pledge value calculated by Staking Engine
    /// @param withdrawPledges request pledge value from staker
    /// @return availableWithdraw if available pledges are enough, return true
    function verifyWithdrawal(address daoUser, uint256 effectivePledgeValue, uint256 withdrawPledges) 
    external 
    onlyStakingEngine()
    sufficientPledges(withdrawPledges)
    override view returns (bool) {
        if (effectivePledgeValue >= _userPledgeValues[daoUser] + withdrawPledges)
            return true;
            
        return false;
    }

    
    function addPledges(address daoUser, uint256 pledges)
    internal {
        uint256 effectivePledgeValue = IStakingEngine(_stakingEngine).getPledgeValue(daoUser);
        if (effectivePledgeValue < pledges) {
            revert PLGEngine_InsufficientPledges(effectivePledgeValue, pledges);
        }

        _userPledgeValues[daoUser] += pledges;
    }


    /// @dev called by Sub DAO Governance to use pledges for becoming a voter of new Sub DAO
    /// @param daoAddress new created Sub DAO's address
    /// @param daoUser dao user's address
    /// @param proposalId proposal id from DAO Governance
    /// @param pledges request pledge value from DAO Governance
    function pledgeForVoter(address daoAddress, address daoUser, bytes32 proposalId, uint256 pledges)
    external 
    onlyDaoUser(msg.sender, daoUser, USER_VOTER_ROLE)
    sufficientPledges(pledges)
    onlyNotExistProposalId(daoUser, proposalId) override {
        
        addPledges(daoUser, pledges);

        LPledgeEngine.PledgeItemInfo storage pledgeItem = _userProposalPledges[daoUser][proposalId];
        pledgeItem.proposalId = proposalId;
        pledgeItem.pledges = pledges;

        _userProposalIds[daoUser].push(proposalId);

        emit PledgedForVoting(daoAddress, daoUser, proposalId, pledges);
    }

    /// @dev called by Sub DAO Governance to use pledges for creating an new Sub DAO
    /// @param daoAddress new created Sub DAO's address
    /// @param daoManager dao manager's address
    /// @param dutyId duty Id from DAO Governance
    /// @param pledges request pledge value from DAO Governance
    function pledgeForManager(address daoAddress, address daoManager, bytes32 dutyId, uint256 pledges)
    external 
    onlyDaoUser(msg.sender, daoManager, USER_MANAGER_ROLE)
    sufficientPledges(pledges)
    onlyNotExistProposalId(daoManager, dutyId)
    override {
                
        addPledges(daoManager, pledges);

        LPledgeEngine.PledgeItemInfo storage pledgeItem = _userProposalPledges[daoManager][dutyId];
        pledgeItem.dutyId = dutyId;
        pledgeItem.pledges = pledges;

        _userProposalIds[daoManager].push(dutyId);

        emit PledgedForManager(daoAddress, daoManager, dutyId, pledges);
    }

    /// @dev called by DAO Governance to release pledges from voting or becoming manager
    /// @param daoUser dao user's address
    /// @param proposalId proposal id from DAO Governance
    function unpledge(address daoUser, bytes32 proposalId)
    external 
    onlyDaoGovernance
    onlyExistProposalId(daoUser, proposalId) override {

        LPledgeEngine.PledgeItemInfo memory pledgeItem = _userProposalPledges[daoUser][proposalId];
        _userPledgeValues[daoUser] -= pledgeItem.pledges;

        removeProposal(daoUser, proposalId);

        emit UnpledgedProposal(daoUser, proposalId);
    }

    /// @dev called by DAO Governance to get a list of voting pledged values with each pledges' proposal id 
    /// @param daoUser dao user's address
    /// @return pledgeItems array of pledged value items
    function getPledgedValueForVoting(address daoUser)
    external
    onlyDaoGovernance
    override view returns (LPledgeEngine.PledgeItemInfo[] memory pledgeItems) {            
        return _getPledgeValueFromType(daoUser, LPledgeEngine.ProposalType.Voting);   
    }

    /// @dev called by DAO Governance to get a list of manager pledged values with each pledges' proposal id 
    /// @param daoUser dao user's address
    /// @return pledgeItems array of pledged value items
    function getPledgedValueForManager(address daoUser)
    external
    onlyDaoGovernance
    override view returns (LPledgeEngine.PledgeItemInfo[] memory pledgeItems) {
        return _getPledgeValueFromType(daoUser, LPledgeEngine.ProposalType.Manager);
    }

    function _getPledgeValueFromType(address daoUser, LPledgeEngine.ProposalType _type) 
    internal 
    view returns (LPledgeEngine.PledgeItemInfo[] memory pledgeItems) {
        
    }

    /// @dev called by DAO Governance to get a number of available pledges for the wallet
    /// @param daoUser dao user's address
    /// @return availablePledgeValue difference between the staking engine's pledge value and already committed pledges
    function getAvailablePledgeValue(address daoUser)
    external 
    onlyDaoGovernance
    override view returns (uint256) {
        uint256 effectivePledgeValue = IStakingEngine(_stakingEngine).getPledgeValue(daoUser);
        if (effectivePledgeValue < _userPledgeValues[daoUser]) {
            return 0;
        }
        return effectivePledgeValue - _userPledgeValues[daoUser];
    }
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

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../libraries/LStakingItem.sol";
import "../libraries/LStakingBasket.sol";
import "../libraries/LStakingEngine.sol";

/// @title The interface for Ink Finance Economy v3 StakingEngine
/// @notice Ken
/// @dev The Ink Finance Economy StakingEngine facilitates creation of staking baskets and management of all behaviors for staking.
interface IStakingEngine {

    /// @notice when DAO super user created new staking basket, this event would be emit.
    /// @param basketAddress new created basket's address
    event StakingBasketCreated(address indexed basketAddress);

    /// @notice when user staked new item in a basket, this event would be emit.
    /// @param staker staking user's address
    /// @param basket target basket's address of the staking user
    /// @param itemId new created staking item's unique id
    event BasketStaked(address indexed staker, address indexed basket, bytes32 itemId);    

    /// @notice when user unstaked an item from a basket, this event would be emit.
    /// @param staker unstaking user's address
    /// @param basket target basket's address of the unstaking user
    /// @param itemId unstaking item's unique id
    event BasketUnstaked(address indexed staker, address indexed basket, bytes32 itemId);  

    /// @notice when user cliamed rewards from a basket, this event would be emit.
    /// @param staker claim rewards user's address
    /// @param amount claimed rewards balance
    event BasketClaimedRewards(address indexed staker, uint256 amount);

    /// @notice when user tried early redeem from a basket, this event would be emit.
    /// @param staker claim rewards user's address
    /// @param basket target basket's address of the earlyRedeem
    /// @param itemId staking item's unique id
    /// @param penaltyBalance penalty calculated principal balance in staking item
    /// @param forfeitRewards forfeited rewards in staking item
    event BasketEarlyRedeemed(address indexed staker, address indexed basket, bytes32 itemId, 
        uint256 penaltyBalance, uint256 forfeitRewards);

    /// @notice For the DAO super user, can be used to add principal token and ratio in to a staking basket.
    /// @dev add principal token and ratio to engine one by one, and will be used to calculate the effective staking balance.
    /// @param principalToken array of available erc20 token address for staking in  
    /// @param conversionRatio array of conversion ratio for each erc20 token
    function addPrincipalCurrencyToEngine(address principalToken, uint256 conversionRatio) external; 

    /// @notice For the DAO super user, can be used to create a staking basket.
    /// @dev create a staking basket from several parameters.
    /// @param termDays term days for staking period
    /// @param weight the weight decide how many token would be put into this basket as rewards. (daily).
    function createStakingBasket(uint256 termDays, uint256 weight) external;

    /// @notice For DAO users, user stakes their tokens into the basket
    /// @param basket specific basket address for staking
    /// @param token erc20 token address, must be exist in available staking-in tokens' array
    /// @param amount erc20 token amount
    function stake(address basket, address token, uint256 amount) external;

    /// @notice For DAO users, user stop to stake their tokens from the basket
    /// @param basket basket address for unstaking
    /// @param itemId staking item's unique id for unstaking
    function unstake(address basket, bytes32 itemId) external;

    /// @notice For DAO users, user stop to stake their tokens from the basket with penalty before period
    /// @param basket basket address for earlyRedeem
    /// @param itemId staking item's unique id for earlyRedeem
    /// @param amount balance for earlyRedeem, if 0, it means all balance of this item
    function earlyRedeem(address basket, bytes32 itemId, uint256 amount) external;

    /// @notice For DAO users, user claims the rewards of the basket
    /// @param basket staking basket's address to claim rewards
    /// @param itemId staking item's unique id
    function claimRewards(address basket, bytes32 itemId) external;

    /// @notice For DAO creator, stake token by admin for trusted dao user, deposit will be extracted from the trust address
    /// @param daoUser trusted dao user's address
    /// @param rewardForUser if true, dao user can call the claimReward to claim his emission rewards, if false, only creator can call claimRewardsForTrust()
    /// @param basket specific basket address for staking
    /// @param token erc20 token address, must be exist in available staking-in tokens' array
    /// @param amount erc20 token amount
    function stakeForTrust(address daoUser, bool rewardForUser, address basket, address token, uint256 amount) external;

    /// @notice For DAO creator, unstake the item staked using stakeForTurst by admin
    /// @param basket specific basket address for staking
    /// @param itemId staking item's id for unstaking
    function unstakeForTrust(address basket, bytes32 itemId) external;

    /// @notice For DAO creator, claim rewards earned by the item staked using stakeForTurst
    /// @param client trusted client's address
    function claimRewardsForTrust(address client) external;

    /// @notice For DAO users, user can estimate the accrued rewards
    /// @param basket staking basket's address to estimate rewards
    /// @param itemId staking item's unique id
    /// @return accruedReward accrued reward balance after staking
    function estimateRewards(address basket, bytes32 itemId) external view returns (uint256);

    /// @notice For DAO users, user can estimate the accrued rewards
    /// @param basket staking basket's address to estimate rewards
    /// @return accruedReward all of the accrued reward balance in the basket
    function estimateAllRewards(address basket) external view returns (uint256);

    /// @notice For DAO super users, to reclaim Reward balances of dao super user's genesis item to the DAO's treasury vault,
    /// and the vault address must be verified by the staking engine, via calling back the DAO's interface
    function reclaimRewards() external;

    /// @notice For DAO super users, to reclaim all the Penalty balances of normal user's items to the DAO's treasury vault,
    /// and the vault address must be verified by the staking engine, via calling back the DAO's interface
    function reclaimPenalties() external;

    /// @notice For DAO users, to verify withdrawal amount whether there are enough pledges for them or not.    
    function verifyWithdrawal(address staker, uint256 amount) external view returns (bool);

    /// @dev get reward pool for staking engine
    /// @return pool emission pool's address
    function getEmissionPool() external view returns (address);

    /// @dev get all the staking items in the basket
    /// @param basket staking basket's address
    /// @return stakingitems array of staking items' information
    function getStakingItems(address basket) external view returns (LStakingItem.StakingItem[] memory);

    /// @dev get all the staking baskets with detail information in the staking engine
    /// @return baskets array of staking baskets' address
    function getStakingBaskets() external view returns (address[] memory);

    /// @dev get one staking basket's detail information from basket address
    /// @param basket staking basket's address
    /// @return stakingbaskets array of staking baskets' information
    function getStakingBasket(address basket) external view returns (LStakingBasket.StakingBasketInfo memory);

    /// @dev provide the all effective staking balance for one staking basket
    /// @param basket staking basket's address
    function getStakingBasketBalance(address basket) external view returns (uint256, uint256);

    /// @dev to get staked tokens' addresses
    /// @return tokens array of principal tokens' address in this engine
    function getStakingTokensAddresses() external view returns (address[] memory);

    /// @dev to get staked tokens' ratios
    /// @param token principal token's address for querying the ratio
    /// @return ratio conversion ratio of the token in this engine
    function getStakingTokenRatio(address token) external view returns (uint256 ratio);

    /// @dev to get begin day Id
    /// @return dayId begine day Id of this engine
    function getBeginDayId() external view returns (uint256);

    /// @dev to get total daily emission amount
    /// @param dayId day unique id for getting daily emission
    /// @return dailyEmission daily emission balance in a curve
    /// @return totalEmission sum of all daily emission balance in a curve
    function getDailyEmission(uint256 dayId) external view returns (uint256, uint256) ;

    /// @dev to get effective pledge value for pledge engine
    /// @param staker staker's address
    /// @return effectivePledgeValue balance of effective pledges
    function getPledgeValue(address staker) external view returns (uint256);
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "../libraries/LPledgeEngine.sol";

/// @title The interface for Ink Finance Economy v3 PledgeEngine
/// @notice Ken
/// @dev The Ink Finance Economy PledgeEngine is to maintain any dao user's committed pledges in the governance process
interface IPledgeEngine {

    event UpdatedDaoUser(address indexed daoAddress, address indexed daoUser, bytes32 userRole, bool added);

    event PledgedForVoting(address indexed daoAddress, address indexed daoUser, bytes32 proposalId, uint256 pledges);

    event PledgedForManager(address indexed daoAddress, address indexed daoUser, bytes32 dutyId, uint256 pledges);

    event UnpledgedProposal(address indexed daoUser, bytes32 proposalId);

    /// @dev called by Ink Root (Meta) DAO Governance to add or remove the DAO user with Sub DAO address and User roles
    /// @param daoAddress new created Sub DAO's address
    /// @param daoUser DAO user's address
    /// @param userRole new DAO user's role in the Sub DAO (Manager or Voter)
    /// @param addFlag add or remove flag, true - add, false - remove
    function updateDaoUser(address daoAddress, address daoUser, bytes32 userRole, bool addFlag) external;

    /// @dev called by Staking Engine to make sure that the dao user can support his outstanding pledge
    /// @param daoUser staker's address in Staking Engine
    /// @param effectivePledgeValue effective pledge value calculated by Staking Engine
    /// @param withdrawPledges request pledge value from staker
    /// @return availableWithdraw if available pledges are enough, return true
    function verifyWithdrawal(address daoUser, uint256 effectivePledgeValue, uint256 withdrawPledges) external view returns (bool);

    /// @dev called by Sub DAO Governance to use pledges for becoming a voter of new Sub DAO
    /// @param daoAddress new created Sub DAO's address
    /// @param daoUser dao user's address
    /// @param proposalId proposal id from DAO Governance
    /// @param pledges request pledge value from DAO Governance
    function pledgeForVoter(address daoAddress, address daoUser, bytes32 proposalId, uint256 pledges) external;

    /// @dev called by Sub DAO Governance to use pledges for creating an new Sub DAO
    /// @param daoAddress new created Sub DAO's address
    /// @param daoManager dao manager's address
    /// @param dutyId duty Id from DAO Governance
    /// @param pledges request pledge value from DAO Governance
    function pledgeForManager(address daoAddress, address daoManager, bytes32 dutyId, uint256 pledges) external;


    /// @dev called by Sub DAO Governance to release pledges from voting or becoming manager
    /// @param daoUser dao user's address
    /// @param proposalId proposal id from DAO Governance
    function unpledge(address daoUser, bytes32 proposalId) external;

    /// @dev called by Sub DAO Governance to get a list of voting pledged values with each pledges' proposal id 
    /// @param daoUser dao user's address
    /// @return pledgeItems array of pledged value items
    function getPledgedValueForVoting(address daoUser) external view returns (LPledgeEngine.PledgeItemInfo[] memory);

    /// @dev called by Sub DAO Governance to get a list of manager pledged values with each pledges' proposal id 
    /// @param daoUser dao user's address
    /// @return pledgeItems array of pledged value items
    function getPledgedValueForManager(address daoUser) external view returns (LPledgeEngine.PledgeItemInfo[] memory);

    /// @dev called by Sub DAO Governance to get a number of available pledges for the wallet
    /// @param daoUser dao user's address
    /// @return availablePledgeValue difference between the staking engine's pledge value and already committed pledges
    function getAvailablePledgeValue(address daoUser) external view returns (uint256);
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../libraries/LStakingItem.sol";
import "../libraries/LStakingBasket.sol";

/// @title The interface for Ink Finance Economy v3 StakingBasket
/// @notice Ken
interface IStakingBasket {  

    /// @notice when user staked new item in a basket, this event would be emit.
    /// @param basket target basket's address of the staking user
    /// @param itemId new created staking item's unique id
    /// @param effectiveStakingValue all effective staking value
    /// @param endDate end date of this staking item
    event StakedItem(address indexed basket, bytes32 itemId, uint256 effectiveStakingValue, uint256 endDate);   

    /// @notice when user unstaked an item from a basket, this event would be emit.
    /// @param basket target basket's address of the unstaking user
    /// @param itemId unstaking item's unique id
    /// @param rewardTo reward receiver's address, if zero, staker will be used for this.
    event UnstakedItem(address indexed basket, bytes32 itemId, address indexed rewardTo); 

    /// @notice For DAO users, user stakes their tokens in this basket
    /// @param staker staking user's address
    /// @param token staking token's address
    /// @param amount staking token's amount
    /// @param effective effective staking balance calculated by token's principal ratio
    /// @param rewardRatio ratio for calculating of rewards
    function stake(address staker, address token, uint256 amount, uint256 effective, uint256 rewardRatio) external returns (bytes32);

    /// @notice For DAO users, user stop to stake their tokens from the basket
    /// @param itemId staking item's unique id for unstaking
    /// @param rewardTo reward receiver's address, if zero, staker will be used for this.
    function unstake(bytes32 itemId, address rewardTo) external;

    /// @notice For the DAO user to unstake an item before it matures, StakingBasket will move this reward to Reclaim Balances
    /// @dev forfeited rewards and principal penalties will move to Reclaim Balances
    /// @param itemId staking item's unique id for earlyRedeem
    /// @param penaltyRate staking item's penalty rate for earlyRedeem
    /// @param rewardTo reward receiver's address
    /// @return penaltyBalance penalty calculated principal balance in staking item
    /// @return forfeitRewards forfeited rewards in staking item    
    function earlyRedeem(bytes32 itemId, uint256 penaltyRate, address rewardTo) external returns (uint256, uint256);

    /// @notice called from {StakingEngine-claimRewards} function
    /// @dev clear settled rewards for this basket's one staking item
    /// @param itemId staking item's id for clear rewards
    function clearRewards(bytes32 itemId) external;

    /// @notice For the DAO super user to claim rewards, StakingBasket will return the rewards to staker
    /// @dev 
    /// @param itemId staking item's unique id for claiming rewards
    /// @param accruingPeriod minimum days for claiming rewards
    /// @param penaltyFlag penalty setting flag from staking engine    
    /// @param rewardRatio staking engine's current reward ratio
    /// @return staker staker who will receive the rewards
    /// @return rewards available cliamed rewards balance
    /// @return remainDays remain days of staking item
    function claimRewards(bytes32 itemId, uint256 accruingPeriod, bool penaltyFlag, uint256 rewardRatio) external returns (address, uint256, uint256);

    /// @notice internal estimate rewards function
    /// @dev return estimated rewards for this basket's one staking item
    /// @param itemId staking item unique id for estimating rewards
    /// @param rewardRatio staking engine's current reward ratio
    /// @return rewardsForItem calculated rewards for staking item
    function estimatedRewards(bytes32 itemId, uint256 rewardRatio) external view returns (uint256 rewardsForItem);

    /// @notice For StakingEngine, get pool's address for this basket
    /// @return pool emission pool address for this basket
    function getBasketPool() external view returns (address);

    /// @notice For StakingEngine and DAO user, get structured detail information for this basket
    /// @return basketInfo basket detail information
    function getBasketInfo() external view returns (LStakingBasket.StakingBasketInfo memory);

    /// @dev get all the staking items in the basket
    /// @param staker staking user's address
    /// @return stakingitems array of staking items' information
    function getStakingItems(address staker) external view returns (LStakingItem.StakingItem[] memory);    

    /// @dev get token of the staking items in the basket
    /// @param itemId staking item's identity
    /// @return stakedItem staked item object
    /// @return stakedToken staked token address
    function getStakingItemInfo(bytes32 itemId) external view returns (LStakingItem.StakingItem memory stakedItem, address stakedToken);    

    /// @dev provide the all staking items's effective staking value by special staker
    /// @param staker address of staker who wants to get effective staking value
    /// @return effectiveStakingValue balance of effective staking value in the staker's all staking items
    function getEffectiveStakingValue(address staker) external view returns (uint256);

    /// @dev get the all effective staking balance for this basket
    /// @param dayId day id for getting balance
    /// @return principalBalance effective staking balance in pricipal zone
    /// @return bufferBalance effective staking balance in buffer zone 
    function getBasketStakingBalanceDayId(uint256 dayId) external view returns (uint256, uint256);

    function getAllItemsCount() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

library LDatetime {
    uint256 constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint256 constant SECONDS_PER_HOUR = 60 * 60;
    uint256 constant SECONDS_PER_MINUTE = 60;
    int256 constant OFFSET19700101 = 2440588;

    // ------------------------------------------------------------------------
    // Calculate year/month/day from the number of days since 1970/01/01 using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and adding the offset 2440588 so that 1970/01/01 is day 0
    //
    // int L = days + 68569 + offset
    // int N = 4 * L / 146097
    // L = L - (146097 * N + 3) / 4
    // year = 4000 * (L + 1) / 1461001
    // L = L - 1461 * year / 4 + 31
    // month = 80 * L / 2447
    // dd = L - 2447 * month / 80
    // L = month / 11
    // month = month + 2 - 12 * L
    // year = 100 * (N - 49) + year + L
    // ------------------------------------------------------------------------
    function _daysToDate(uint256 _days)
        internal
        pure
        returns (
            uint256 year,
            uint256 month,
            uint256 day
        )
    {
        int256 __days = int256(_days);
        int256 L = __days + 68569 + OFFSET19700101;
        int256 N = (4 * L) / 146097;
        L = L - (146097 * N + 3) / 4;
        int256 _year = (4000 * (L + 1)) / 1461001;
        L = L - (1461 * _year) / 4 + 31;
        int256 _month = (80 * L) / 2447;
        int256 _day = L - (2447 * _month) / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;

        year = uint256(_year);
        month = uint256(_month);
        day = uint256(_day);
    }

    // ------------------------------------------------------------------------
    // Calculate the number of days from 1970/01/01 to year/month/day using
    // the date conversion algorithm from
    //   https://aa.usno.navy.mil/faq/JD_formula.html
    // and subtracting the offset 2440588 so that 1970/01/01 is day 0
    //
    // days = day
    //      - 32075
    //      + 1461 * (year + 4800 + (month - 14) / 12) / 4
    //      + 367 * (month - 2 - (month - 14) / 12 * 12) / 12
    //      - 3 * ((year + 4900 + (month - 14) / 12) / 100) / 4
    //      - offset
    // ------------------------------------------------------------------------
    function _daysFromDate(uint year, uint month, uint day) internal pure returns (uint _days) {
        require(year >= 1970);
        int _year = int(year);
        int _month = int(month);
        int _day = int(day);

        int __days = _day
          - 32075
          + 1461 * (_year + 4800 + (_month - 14) / 12) / 4
          + 367 * (_month - 2 - (_month - 14) / 12 * 12) / 12
          - 3 * ((_year + 4900 + (_month - 14) / 12) / 100) / 4
          - OFFSET19700101;

        _days = uint(__days);
    }

    function timestampToDate(uint256 timestamp)
        internal
        pure
        returns (
            uint256 year,
            uint256 month,
            uint256 day
        )
    {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
 
    function addDays(uint timestamp, uint _days) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _days * SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }

    function timestampFromDayId(uint dayId) internal pure returns (uint) {
        uint day = dayId % 100;
        uint month = ((dayId - day) / 100) % 100;
        uint year = (dayId - day - 100 * month) / 10000;

        uint timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY;
        return timestamp;
    }

    function decreaseDayId(uint256 dayId, uint256 _days) internal pure returns (uint) {
        uint timestamp = timestampFromDayId(dayId);
        require(timestamp >= _days * SECONDS_PER_DAY, "Invalid decrease days");

        timestamp = timestamp - _days * SECONDS_PER_DAY;
        return getDayID(timestamp);
    }
    
    function increaseDayId(uint256 dayId, uint256 _days) internal pure returns (uint) {
        uint timestamp = timestampFromDayId(dayId);
        timestamp += _days * SECONDS_PER_DAY;
        return getDayID(timestamp);
    }

    function getDaysBetweenTwoDayId(uint256 dayIdBefore, uint256 dayIdAfter) internal pure returns (uint) {
        uint timestampBefore = timestampFromDayId(dayIdBefore);
        uint timestampAfter = timestampFromDayId(dayIdAfter);
        require(timestampBefore <= timestampAfter, "Invalid before and after dayids");

        return (timestampAfter - timestampBefore) / SECONDS_PER_DAY;
    }

    function getDayID(uint256 timestamp) internal pure returns (uint256 dayId) {
        (uint256 year, uint256 month, uint256 day) = timestampToDate(timestamp);
        dayId = (year * 10000) + month * 100 + day;
    }    

    function getNextDayID(uint256 timestamp) internal pure returns (uint256 dayId) {
        timestamp += SECONDS_PER_DAY;
        (uint256 year, uint256 month, uint256 day) = timestampToDate(timestamp);
        dayId = (year * 10000) + month * 100 + day;
    }

    function getPrevDayID(uint256 timestamp) internal pure returns (uint256 dayId) {
        timestamp -= SECONDS_PER_DAY;
        (uint256 year, uint256 month, uint256 day) = timestampToDate(timestamp);
        dayId = (year * 10000) + month * 100 + day;
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4;

import "./PRBMath.sol";

/// @title PRBMathUD60x18
/// @author Paul Razvan Berg
/// @notice Smart contract library for advanced fixed-point math that works with uint256 numbers considered to have 18
/// trailing decimals. We call this number representation unsigned 60.18-decimal fixed-point, since there can be up to 60
/// digits in the integer part and up to 18 decimals in the fractional part. The numbers are bound by the minimum and the
/// maximum values permitted by the Solidity type uint256.
library PRBMathUD60x18 {
    /// @dev Half the SCALE number.
    uint256 internal constant HALF_SCALE = 5e17;

    /// @dev log2(e) as an unsigned 60.18-decimal fixed-point number.
    uint256 internal constant LOG2_E = 1_442695040888963407;

    /// @dev The maximum value an unsigned 60.18-decimal fixed-point number can have.
    uint256 internal constant MAX_UD60x18 =
        115792089237316195423570985008687907853269984665640564039457_584007913129639935;

    /// @dev The maximum whole value an unsigned 60.18-decimal fixed-point number can have.
    uint256 internal constant MAX_WHOLE_UD60x18 =
        115792089237316195423570985008687907853269984665640564039457_000000000000000000;

    /// @dev How many trailing decimals can be represented.
    uint256 internal constant SCALE = 1e18;

    /// @notice Calculates the arithmetic average of x and y, rounding down.
    /// @param x The first operand as an unsigned 60.18-decimal fixed-point number.
    /// @param y The second operand as an unsigned 60.18-decimal fixed-point number.
    /// @return result The arithmetic average as an unsigned 60.18-decimal fixed-point number.
    function avg(uint256 x, uint256 y) internal pure returns (uint256 result) {
        // The operations can never overflow.
        unchecked {
            // The last operand checks if both x and y are odd and if that is the case, we add 1 to the result. We need
            // to do this because if both numbers are odd, the 0.5 remainder gets truncated twice.
            result = (x >> 1) + (y >> 1) + (x & y & 1);
        }
    }

    /// @notice Yields the least unsigned 60.18 decimal fixed-point number greater than or equal to x.
    ///
    /// @dev Optimized for fractional value inputs, because for every whole value there are (1e18 - 1) fractional counterparts.
    /// See https://en.wikipedia.org/wiki/Floor_and_ceiling_functions.
    ///
    /// Requirements:
    /// - x must be less than or equal to MAX_WHOLE_UD60x18.
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number to ceil.
    /// @param result The least integer greater than or equal to x, as an unsigned 60.18-decimal fixed-point number.
    function ceil(uint256 x) internal pure returns (uint256 result) {
        if (x > MAX_WHOLE_UD60x18) {
            revert PRBMathUD60x18__CeilOverflow(x);
        }
        assembly {
            // Equivalent to "x % SCALE" but faster.
            let remainder := mod(x, SCALE)

            // Equivalent to "SCALE - remainder" but faster.
            let delta := sub(SCALE, remainder)

            // Equivalent to "x + delta * (remainder > 0 ? 1 : 0)" but faster.
            result := add(x, mul(delta, gt(remainder, 0)))
        }
    }

    /// @notice Divides two unsigned 60.18-decimal fixed-point numbers, returning a new unsigned 60.18-decimal fixed-point number.
    ///
    /// @dev Uses mulDiv to enable overflow-safe multiplication and division.
    ///
    /// Requirements:
    /// - The denominator cannot be zero.
    ///
    /// @param x The numerator as an unsigned 60.18-decimal fixed-point number.
    /// @param y The denominator as an unsigned 60.18-decimal fixed-point number.
    /// @param result The quotient as an unsigned 60.18-decimal fixed-point number.
    function div(uint256 x, uint256 y) internal pure returns (uint256 result) {
        result = PRBMath.mulDiv(x, SCALE, y);
    }

    /// @notice Returns Euler's number as an unsigned 60.18-decimal fixed-point number.
    /// @dev See https://en.wikipedia.org/wiki/E_(mathematical_constant).
    function e() internal pure returns (uint256 result) {
        result = 2_718281828459045235;
    }

    /// @notice Calculates the natural exponent of x.
    ///
    /// @dev Based on the insight that e^x = 2^(x * log2(e)).
    ///
    /// Requirements:
    /// - All from "log2".
    /// - x must be less than 133.084258667509499441.
    ///
    /// @param x The exponent as an unsigned 60.18-decimal fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function exp(uint256 x) internal pure returns (uint256 result) {
        // Without this check, the value passed to "exp2" would be greater than 192.
        if (x >= 133_084258667509499441) {
            revert PRBMathUD60x18__ExpInputTooBig(x);
        }

        // Do the fixed-point multiplication inline to save gas.
        unchecked {
            uint256 doubleScaleProduct = x * LOG2_E;
            result = exp2((doubleScaleProduct + HALF_SCALE) / SCALE);
        }
    }

    /// @notice Calculates the binary exponent of x using the binary fraction method.
    ///
    /// @dev See https://ethereum.stackexchange.com/q/79903/24693.
    ///
    /// Requirements:
    /// - x must be 192 or less.
    /// - The result must fit within MAX_UD60x18.
    ///
    /// @param x The exponent as an unsigned 60.18-decimal fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function exp2(uint256 x) internal pure returns (uint256 result) {
        // 2^192 doesn't fit within the 192.64-bit format used internally in this function.
        if (x >= 192e18) {
            revert PRBMathUD60x18__Exp2InputTooBig(x);
        }

        unchecked {
            // Convert x to the 192.64-bit fixed-point format.
            uint256 x192x64 = (x << 64) / SCALE;

            // Pass x to the PRBMath.exp2 function, which uses the 192.64-bit fixed-point number representation.
            result = PRBMath.exp2(x192x64);
        }
    }

    /// @notice Yields the greatest unsigned 60.18 decimal fixed-point number less than or equal to x.
    /// @dev Optimized for fractional value inputs, because for every whole value there are (1e18 - 1) fractional counterparts.
    /// See https://en.wikipedia.org/wiki/Floor_and_ceiling_functions.
    /// @param x The unsigned 60.18-decimal fixed-point number to floor.
    /// @param result The greatest integer less than or equal to x, as an unsigned 60.18-decimal fixed-point number.
    function floor(uint256 x) internal pure returns (uint256 result) {
        assembly {
            // Equivalent to "x % SCALE" but faster.
            let remainder := mod(x, SCALE)

            // Equivalent to "x - remainder * (remainder > 0 ? 1 : 0)" but faster.
            result := sub(x, mul(remainder, gt(remainder, 0)))
        }
    }

    /// @notice Yields the excess beyond the floor of x.
    /// @dev Based on the odd function definition https://en.wikipedia.org/wiki/Fractional_part.
    /// @param x The unsigned 60.18-decimal fixed-point number to get the fractional part of.
    /// @param result The fractional part of x as an unsigned 60.18-decimal fixed-point number.
    function frac(uint256 x) internal pure returns (uint256 result) {
        assembly {
            result := mod(x, SCALE)
        }
    }

    /// @notice Converts a number from basic integer form to unsigned 60.18-decimal fixed-point representation.
    ///
    /// @dev Requirements:
    /// - x must be less than or equal to MAX_UD60x18 divided by SCALE.
    ///
    /// @param x The basic integer to convert.
    /// @param result The same number in unsigned 60.18-decimal fixed-point representation.
    function fromUint(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            if (x > MAX_UD60x18 / SCALE) {
                revert PRBMathUD60x18__FromUintOverflow(x);
            }
            result = x * SCALE;
        }
    }

    /// @notice Calculates geometric mean of x and y, i.e. sqrt(x * y), rounding down.
    ///
    /// @dev Requirements:
    /// - x * y must fit within MAX_UD60x18, lest it overflows.
    ///
    /// @param x The first operand as an unsigned 60.18-decimal fixed-point number.
    /// @param y The second operand as an unsigned 60.18-decimal fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function gm(uint256 x, uint256 y) internal pure returns (uint256 result) {
        if (x == 0) {
            return 0;
        }

        unchecked {
            // Checking for overflow this way is faster than letting Solidity do it.
            uint256 xy = x * y;
            if (xy / x != y) {
                revert PRBMathUD60x18__GmOverflow(x, y);
            }

            // We don't need to multiply by the SCALE here because the x*y product had already picked up a factor of SCALE
            // during multiplication. See the comments within the "sqrt" function.
            result = PRBMath.sqrt(xy);
        }
    }

    /// @notice Calculates 1 / x, rounding toward zero.
    ///
    /// @dev Requirements:
    /// - x cannot be zero.
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the inverse.
    /// @return result The inverse as an unsigned 60.18-decimal fixed-point number.
    function inv(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            // 1e36 is SCALE * SCALE.
            result = 1e36 / x;
        }
    }

    /// @notice Calculates the natural logarithm of x.
    ///
    /// @dev Based on the insight that ln(x) = log2(x) / log2(e).
    ///
    /// Requirements:
    /// - All from "log2".
    ///
    /// Caveats:
    /// - All from "log2".
    /// - This doesn't return exactly 1 for 2.718281828459045235, for that we would need more fine-grained precision.
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the natural logarithm.
    /// @return result The natural logarithm as an unsigned 60.18-decimal fixed-point number.
    function ln(uint256 x) internal pure returns (uint256 result) {
        // Do the fixed-point multiplication inline to save gas. This is overflow-safe because the maximum value that log2(x)
        // can return is 196205294292027477728.
        unchecked {
            result = (log2(x) * SCALE) / LOG2_E;
        }
    }

    /// @notice Calculates the common logarithm of x.
    ///
    /// @dev First checks if x is an exact power of ten and it stops if yes. If it's not, calculates the common
    /// logarithm based on the insight that log10(x) = log2(x) / log2(10).
    ///
    /// Requirements:
    /// - All from "log2".
    ///
    /// Caveats:
    /// - All from "log2".
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the common logarithm.
    /// @return result The common logarithm as an unsigned 60.18-decimal fixed-point number.
    function log10(uint256 x) internal pure returns (uint256 result) {
        if (x < SCALE) {
            revert PRBMathUD60x18__LogInputTooSmall(x);
        }

        // Note that the "mul" in this block is the assembly multiplication operation, not the "mul" function defined
        // in this contract.
        // prettier-ignore
        assembly {
            switch x
            case 1 { result := mul(SCALE, sub(0, 18)) }
            case 10 { result := mul(SCALE, sub(1, 18)) }
            case 100 { result := mul(SCALE, sub(2, 18)) }
            case 1000 { result := mul(SCALE, sub(3, 18)) }
            case 10000 { result := mul(SCALE, sub(4, 18)) }
            case 100000 { result := mul(SCALE, sub(5, 18)) }
            case 1000000 { result := mul(SCALE, sub(6, 18)) }
            case 10000000 { result := mul(SCALE, sub(7, 18)) }
            case 100000000 { result := mul(SCALE, sub(8, 18)) }
            case 1000000000 { result := mul(SCALE, sub(9, 18)) }
            case 10000000000 { result := mul(SCALE, sub(10, 18)) }
            case 100000000000 { result := mul(SCALE, sub(11, 18)) }
            case 1000000000000 { result := mul(SCALE, sub(12, 18)) }
            case 10000000000000 { result := mul(SCALE, sub(13, 18)) }
            case 100000000000000 { result := mul(SCALE, sub(14, 18)) }
            case 1000000000000000 { result := mul(SCALE, sub(15, 18)) }
            case 10000000000000000 { result := mul(SCALE, sub(16, 18)) }
            case 100000000000000000 { result := mul(SCALE, sub(17, 18)) }
            case 1000000000000000000 { result := 0 }
            case 10000000000000000000 { result := SCALE }
            case 100000000000000000000 { result := mul(SCALE, 2) }
            case 1000000000000000000000 { result := mul(SCALE, 3) }
            case 10000000000000000000000 { result := mul(SCALE, 4) }
            case 100000000000000000000000 { result := mul(SCALE, 5) }
            case 1000000000000000000000000 { result := mul(SCALE, 6) }
            case 10000000000000000000000000 { result := mul(SCALE, 7) }
            case 100000000000000000000000000 { result := mul(SCALE, 8) }
            case 1000000000000000000000000000 { result := mul(SCALE, 9) }
            case 10000000000000000000000000000 { result := mul(SCALE, 10) }
            case 100000000000000000000000000000 { result := mul(SCALE, 11) }
            case 1000000000000000000000000000000 { result := mul(SCALE, 12) }
            case 10000000000000000000000000000000 { result := mul(SCALE, 13) }
            case 100000000000000000000000000000000 { result := mul(SCALE, 14) }
            case 1000000000000000000000000000000000 { result := mul(SCALE, 15) }
            case 10000000000000000000000000000000000 { result := mul(SCALE, 16) }
            case 100000000000000000000000000000000000 { result := mul(SCALE, 17) }
            case 1000000000000000000000000000000000000 { result := mul(SCALE, 18) }
            case 10000000000000000000000000000000000000 { result := mul(SCALE, 19) }
            case 100000000000000000000000000000000000000 { result := mul(SCALE, 20) }
            case 1000000000000000000000000000000000000000 { result := mul(SCALE, 21) }
            case 10000000000000000000000000000000000000000 { result := mul(SCALE, 22) }
            case 100000000000000000000000000000000000000000 { result := mul(SCALE, 23) }
            case 1000000000000000000000000000000000000000000 { result := mul(SCALE, 24) }
            case 10000000000000000000000000000000000000000000 { result := mul(SCALE, 25) }
            case 100000000000000000000000000000000000000000000 { result := mul(SCALE, 26) }
            case 1000000000000000000000000000000000000000000000 { result := mul(SCALE, 27) }
            case 10000000000000000000000000000000000000000000000 { result := mul(SCALE, 28) }
            case 100000000000000000000000000000000000000000000000 { result := mul(SCALE, 29) }
            case 1000000000000000000000000000000000000000000000000 { result := mul(SCALE, 30) }
            case 10000000000000000000000000000000000000000000000000 { result := mul(SCALE, 31) }
            case 100000000000000000000000000000000000000000000000000 { result := mul(SCALE, 32) }
            case 1000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 33) }
            case 10000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 34) }
            case 100000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 35) }
            case 1000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 36) }
            case 10000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 37) }
            case 100000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 38) }
            case 1000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 39) }
            case 10000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 40) }
            case 100000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 41) }
            case 1000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 42) }
            case 10000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 43) }
            case 100000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 44) }
            case 1000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 45) }
            case 10000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 46) }
            case 100000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 47) }
            case 1000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 48) }
            case 10000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 49) }
            case 100000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 50) }
            case 1000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 51) }
            case 10000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 52) }
            case 100000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 53) }
            case 1000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 54) }
            case 10000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 55) }
            case 100000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 56) }
            case 1000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 57) }
            case 10000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 58) }
            case 100000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 59) }
            default {
                result := MAX_UD60x18
            }
        }

        if (result == MAX_UD60x18) {
            // Do the fixed-point division inline to save gas. The denominator is log2(10).
            unchecked {
                result = (log2(x) * SCALE) / 3_321928094887362347;
            }
        }
    }

    /// @notice Calculates the binary logarithm of x.
    ///
    /// @dev Based on the iterative approximation algorithm.
    /// https://en.wikipedia.org/wiki/Binary_logarithm#Iterative_approximation
    ///
    /// Requirements:
    /// - x must be greater than or equal to SCALE, otherwise the result would be negative.
    ///
    /// Caveats:
    /// - The results are nor perfectly accurate to the last decimal, due to the lossy precision of the iterative approximation.
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the binary logarithm.
    /// @return result The binary logarithm as an unsigned 60.18-decimal fixed-point number.
    function log2(uint256 x) internal pure returns (uint256 result) {
        if (x < SCALE) {
            revert PRBMathUD60x18__LogInputTooSmall(x);
        }
        unchecked {
            // Calculate the integer part of the logarithm and add it to the result and finally calculate y = x * 2^(-n).
            uint256 n = PRBMath.mostSignificantBit(x / SCALE);

            // The integer part of the logarithm as an unsigned 60.18-decimal fixed-point number. The operation can't overflow
            // because n is maximum 255 and SCALE is 1e18.
            result = n * SCALE;

            // This is y = x * 2^(-n).
            uint256 y = x >> n;

            // If y = 1, the fractional part is zero.
            if (y == SCALE) {
                return result;
            }

            // Calculate the fractional part via the iterative approximation.
            // The "delta >>= 1" part is equivalent to "delta /= 2", but shifting bits is faster.
            for (uint256 delta = HALF_SCALE; delta > 0; delta >>= 1) {
                y = (y * y) / SCALE;

                // Is y^2 > 2 and so in the range [2,4)?
                if (y >= 2 * SCALE) {
                    // Add the 2^(-m) factor to the logarithm.
                    result += delta;

                    // Corresponds to z/2 on Wikipedia.
                    y >>= 1;
                }
            }
        }
    }

    /// @notice Multiplies two unsigned 60.18-decimal fixed-point numbers together, returning a new unsigned 60.18-decimal
    /// fixed-point number.
    /// @dev See the documentation for the "PRBMath.mulDivFixedPoint" function.
    /// @param x The multiplicand as an unsigned 60.18-decimal fixed-point number.
    /// @param y The multiplier as an unsigned 60.18-decimal fixed-point number.
    /// @return result The product as an unsigned 60.18-decimal fixed-point number.
    function mul(uint256 x, uint256 y) internal pure returns (uint256 result) {
        result = PRBMath.mulDivFixedPoint(x, y);
    }

    /// @notice Returns PI as an unsigned 60.18-decimal fixed-point number.
    function pi() internal pure returns (uint256 result) {
        result = 3_141592653589793238;
    }

    /// @notice Raises x to the power of y.
    ///
    /// @dev Based on the insight that x^y = 2^(log2(x) * y).
    ///
    /// Requirements:
    /// - All from "exp2", "log2" and "mul".
    ///
    /// Caveats:
    /// - All from "exp2", "log2" and "mul".
    /// - Assumes 0^0 is 1.
    ///
    /// @param x Number to raise to given power y, as an unsigned 60.18-decimal fixed-point number.
    /// @param y Exponent to raise x to, as an unsigned 60.18-decimal fixed-point number.
    /// @return result x raised to power y, as an unsigned 60.18-decimal fixed-point number.
    function pow(uint256 x, uint256 y) internal pure returns (uint256 result) {
        if (x == 0) {
            result = y == 0 ? SCALE : uint256(0);
        } else {
            result = exp2(mul(log2(x), y));
        }
    }

    /// @notice Raises x (unsigned 60.18-decimal fixed-point number) to the power of y (basic unsigned integer) using the
    /// famous algorithm "exponentiation by squaring".
    ///
    /// @dev See https://en.wikipedia.org/wiki/Exponentiation_by_squaring
    ///
    /// Requirements:
    /// - The result must fit within MAX_UD60x18.
    ///
    /// Caveats:
    /// - All from "mul".
    /// - Assumes 0^0 is 1.
    ///
    /// @param x The base as an unsigned 60.18-decimal fixed-point number.
    /// @param y The exponent as an uint256.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function powu(uint256 x, uint256 y) internal pure returns (uint256 result) {
        // Calculate the first iteration of the loop in advance.
        result = y & 1 > 0 ? x : SCALE;

        // Equivalent to "for(y /= 2; y > 0; y /= 2)" but faster.
        for (y >>= 1; y > 0; y >>= 1) {
            x = PRBMath.mulDivFixedPoint(x, x);

            // Equivalent to "y % 2 == 1" but faster.
            if (y & 1 > 0) {
                result = PRBMath.mulDivFixedPoint(result, x);
            }
        }
    }

    /// @notice Returns 1 as an unsigned 60.18-decimal fixed-point number.
    function scale() internal pure returns (uint256 result) {
        result = SCALE;
    }

    /// @notice Calculates the square root of x, rounding down.
    /// @dev Uses the Babylonian method https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method.
    ///
    /// Requirements:
    /// - x must be less than MAX_UD60x18 / SCALE.
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the square root.
    /// @return result The result as an unsigned 60.18-decimal fixed-point .
    function sqrt(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            if (x > MAX_UD60x18 / SCALE) {
                revert PRBMathUD60x18__SqrtOverflow(x);
            }
            // Multiply x by the SCALE to account for the factor of SCALE that is picked up when multiplying two unsigned
            // 60.18-decimal fixed-point numbers together (in this case, those two numbers are both the square root).
            result = PRBMath.sqrt(x * SCALE);
        }
    }

    /// @notice Converts a unsigned 60.18-decimal fixed-point number to basic integer form, rounding down in the process.
    /// @param x The unsigned 60.18-decimal fixed-point number to convert.
    /// @return result The same number in basic integer form.
    function toUint(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            result = x / SCALE;
        }
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../../interfaces/IEmissionPool.sol";

/**
    @author 
    @title Ink Finance v3 staking emission pool
    @dev EmissionPool is used to store and manage the governance tokens for rewards
        each staking engine will have one emission pool.
*/
contract EmissionPool is IEmissionPool {

    address private immutable _token;

    address private immutable _stakingEngine;

    mapping(address => bool) private _basketPools;

    /// @dev mapping for reclaimed balances, key is principal token, value is principal balance
    mapping(address => uint256) private _reclaimablePenalty;

    /// @dev mapping for reclaimed reward
    uint256 private _reclaimRewards;
    uint256 private _emptyDaysRewards;

    modifier onlyStakingEngine() {
        require(msg.sender == _stakingEngine, "Only allowed from StakingEngine");
        _;
    }

    modifier onlyBasketPool(address basketPool) {
        require(_basketPools[basketPool] == true || basketPool == _stakingEngine, 
            "Only allowed from BasketPool");
        _;
    }

    constructor(address token) {
        _token = token;
        _stakingEngine = msg.sender;
    }

    function addBasketPool(address basketPool) 
    external 
    override onlyStakingEngine {        
        _basketPools[basketPool] = true;
    }

    function addPenaltyToken(address reclaimedToken, uint256 penalty) 
    external
    override onlyBasketPool(msg.sender) {
        _reclaimablePenalty[reclaimedToken] += penalty;
    }

    function addPenaltyRewards(uint256 forfeitedRewards)
    external
    override onlyBasketPool(msg.sender) {
        _reclaimRewards += forfeitedRewards;
    }

    function reclaimPenalty(address reclaimedToken, address vault)
    external
    override onlyStakingEngine returns (bool) {
        bool bSent = IERC20(reclaimedToken).transfer(vault, _reclaimablePenalty[reclaimedToken]);
        _reclaimablePenalty[reclaimedToken] = 0;
        return bSent;
    }

    function reclaimRewards(address vault, uint256 emptyDaysRewards)
    external
    override onlyStakingEngine returns (bool) {
        require(emptyDaysRewards > _emptyDaysRewards, "Invalid empty day rewards");
        
        uint256 _deltaEmptyDaysRewards = emptyDaysRewards - _emptyDaysRewards;
        bool bSent = IERC20(_token).transfer(vault, _reclaimRewards + _deltaEmptyDaysRewards);
        _reclaimRewards = 0;
        _emptyDaysRewards = emptyDaysRewards;
        return bSent;
    }

    function tokenTransfer(address to, address token, uint256 amount) 
    external 
    override onlyBasketPool(msg.sender) returns (bool) {
        require(to != address(0) && token != address(0), "Invalid token or to address");

        return IERC20(token).transfer(to, amount);
    }

    function getEmissionToken()
    external 
    override view returns (address) {
        return _token;
    }
}

/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IRootDaoGovernance {
    
    function getDaoTreasuryVault() external view returns (address);

    function getDaoPenaltySetting() external view returns (bool);

    function setDaoPenaltySetting(bool penaltyFlag) external;
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

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library LStakingItem {
    enum State {
        PENDING,
        STAKING,
        UNSTAKING
    }

    struct StakingItem {
        /// @dev itemId generated base on basket and owner address and total items in the basket
        bytes32 itemId;
        /// @dev address of staking holder
        address staker;
        /// @dev the container basket of the stake item, view property
        uint256 effectiveStakingValue;
        /// @dev reward ratio
        uint256 rewardRatio;
        /// @dev end date of principal staking
        uint256 endDate;
        /// @dev settled time
        uint256 settledDate;
        /// @dev settled reward
        uint256 settledReward;        
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

library LStakingBasket {

    enum Arithmetic {
        FIX,
        LINEAR
    }

    struct EmissionArithmetic {
        Arithmetic arithmetic;
    }

    struct StakingBasketInfo {
        uint256 stakingPeriod;
        uint256 weight;
        uint256 startDate;     
    }

    struct BasketBalance {
        uint256 principalBalance;
        uint256 bufferBalance;
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library LStakingEngine {

    /// @dev constant state of engine
    enum State {
        PENDING,
        ALIVE,
        MATURITY
    }

    struct EngineInfo {
        uint256 engineAddress;
        uint256 emissionTokens;
        address governanceToken;
    }

    /// @dev structure for a pair of token and ratio
    struct TokenRatioInfo {
        address tokenAddress;
        uint256 tokenRatio;
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

library LPledgeEngine {

    /// @dev constant state of engine
    enum ProposalType {
        Voting,
        Manager
    }

    struct PledgeItemInfo {
        bytes32 proposalId;        
        uint256 pledges;
        bytes32 dutyId;
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4;

/// @notice Emitted when the result overflows uint256.
error PRBMath__MulDivFixedPointOverflow(uint256 prod1);

/// @notice Emitted when the result overflows uint256.
error PRBMath__MulDivOverflow(uint256 prod1, uint256 denominator);

/// @notice Emitted when one of the inputs is type(int256).min.
error PRBMath__MulDivSignedInputTooSmall();

/// @notice Emitted when the intermediary absolute result overflows int256.
error PRBMath__MulDivSignedOverflow(uint256 rAbs);

/// @notice Emitted when the input is MIN_SD59x18.
error PRBMathSD59x18__AbsInputTooSmall();

/// @notice Emitted when ceiling a number overflows SD59x18.
error PRBMathSD59x18__CeilOverflow(int256 x);

/// @notice Emitted when one of the inputs is MIN_SD59x18.
error PRBMathSD59x18__DivInputTooSmall();

/// @notice Emitted when one of the intermediary unsigned results overflows SD59x18.
error PRBMathSD59x18__DivOverflow(uint256 rAbs);

/// @notice Emitted when the input is greater than 133.084258667509499441.
error PRBMathSD59x18__ExpInputTooBig(int256 x);

/// @notice Emitted when the input is greater than 192.
error PRBMathSD59x18__Exp2InputTooBig(int256 x);

/// @notice Emitted when flooring a number underflows SD59x18.
error PRBMathSD59x18__FloorUnderflow(int256 x);

/// @notice Emitted when converting a basic integer to the fixed-point format overflows SD59x18.
error PRBMathSD59x18__FromIntOverflow(int256 x);

/// @notice Emitted when converting a basic integer to the fixed-point format underflows SD59x18.
error PRBMathSD59x18__FromIntUnderflow(int256 x);

/// @notice Emitted when the product of the inputs is negative.
error PRBMathSD59x18__GmNegativeProduct(int256 x, int256 y);

/// @notice Emitted when multiplying the inputs overflows SD59x18.
error PRBMathSD59x18__GmOverflow(int256 x, int256 y);

/// @notice Emitted when the input is less than or equal to zero.
error PRBMathSD59x18__LogInputTooSmall(int256 x);

/// @notice Emitted when one of the inputs is MIN_SD59x18.
error PRBMathSD59x18__MulInputTooSmall();

/// @notice Emitted when the intermediary absolute result overflows SD59x18.
error PRBMathSD59x18__MulOverflow(uint256 rAbs);

/// @notice Emitted when the intermediary absolute result overflows SD59x18.
error PRBMathSD59x18__PowuOverflow(uint256 rAbs);

/// @notice Emitted when the input is negative.
error PRBMathSD59x18__SqrtNegativeInput(int256 x);

/// @notice Emitted when the calculating the square root overflows SD59x18.
error PRBMathSD59x18__SqrtOverflow(int256 x);

/// @notice Emitted when addition overflows UD60x18.
error PRBMathUD60x18__AddOverflow(uint256 x, uint256 y);

/// @notice Emitted when ceiling a number overflows UD60x18.
error PRBMathUD60x18__CeilOverflow(uint256 x);

/// @notice Emitted when the input is greater than 133.084258667509499441.
error PRBMathUD60x18__ExpInputTooBig(uint256 x);

/// @notice Emitted when the input is greater than 192.
error PRBMathUD60x18__Exp2InputTooBig(uint256 x);

/// @notice Emitted when converting a basic integer to the fixed-point format format overflows UD60x18.
error PRBMathUD60x18__FromUintOverflow(uint256 x);

/// @notice Emitted when multiplying the inputs overflows UD60x18.
error PRBMathUD60x18__GmOverflow(uint256 x, uint256 y);

/// @notice Emitted when the input is less than 1.
error PRBMathUD60x18__LogInputTooSmall(uint256 x);

/// @notice Emitted when the calculating the square root overflows UD60x18.
error PRBMathUD60x18__SqrtOverflow(uint256 x);

/// @notice Emitted when subtraction underflows UD60x18.
error PRBMathUD60x18__SubUnderflow(uint256 x, uint256 y);

/// @dev Common mathematical functions used in both PRBMathSD59x18 and PRBMathUD60x18. Note that this shared library
/// does not always assume the signed 59.18-decimal fixed-point or the unsigned 60.18-decimal fixed-point
/// representation. When it does not, it is explicitly mentioned in the NatSpec documentation.
library PRBMath {
    /// STRUCTS ///

    struct SD59x18 {
        int256 value;
    }

    struct UD60x18 {
        uint256 value;
    }

    /// STORAGE ///

    /// @dev How many trailing decimals can be represented.
    uint256 internal constant SCALE = 1e18;

    /// @dev Largest power of two divisor of SCALE.
    uint256 internal constant SCALE_LPOTD = 262144;

    /// @dev SCALE inverted mod 2^256.
    uint256 internal constant SCALE_INVERSE =
        78156646155174841979727994598816262306175212592076161876661_508869554232690281;

    /// FUNCTIONS ///

    /// @notice Calculates the binary exponent of x using the binary fraction method.
    /// @dev Has to use 192.64-bit fixed-point numbers.
    /// See https://ethereum.stackexchange.com/a/96594/24693.
    /// @param x The exponent as an unsigned 192.64-bit fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function exp2(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            // Start from 0.5 in the 192.64-bit fixed-point format.
            result = 0x800000000000000000000000000000000000000000000000;

            // Multiply the result by root(2, 2^-i) when the bit at position i is 1. None of the intermediary results overflows
            // because the initial result is 2^191 and all magic factors are less than 2^65.
            if (x & 0x8000000000000000 > 0) {
                result = (result * 0x16A09E667F3BCC909) >> 64;
            }
            if (x & 0x4000000000000000 > 0) {
                result = (result * 0x1306FE0A31B7152DF) >> 64;
            }
            if (x & 0x2000000000000000 > 0) {
                result = (result * 0x1172B83C7D517ADCE) >> 64;
            }
            if (x & 0x1000000000000000 > 0) {
                result = (result * 0x10B5586CF9890F62A) >> 64;
            }
            if (x & 0x800000000000000 > 0) {
                result = (result * 0x1059B0D31585743AE) >> 64;
            }
            if (x & 0x400000000000000 > 0) {
                result = (result * 0x102C9A3E778060EE7) >> 64;
            }
            if (x & 0x200000000000000 > 0) {
                result = (result * 0x10163DA9FB33356D8) >> 64;
            }
            if (x & 0x100000000000000 > 0) {
                result = (result * 0x100B1AFA5ABCBED61) >> 64;
            }
            if (x & 0x80000000000000 > 0) {
                result = (result * 0x10058C86DA1C09EA2) >> 64;
            }
            if (x & 0x40000000000000 > 0) {
                result = (result * 0x1002C605E2E8CEC50) >> 64;
            }
            if (x & 0x20000000000000 > 0) {
                result = (result * 0x100162F3904051FA1) >> 64;
            }
            if (x & 0x10000000000000 > 0) {
                result = (result * 0x1000B175EFFDC76BA) >> 64;
            }
            if (x & 0x8000000000000 > 0) {
                result = (result * 0x100058BA01FB9F96D) >> 64;
            }
            if (x & 0x4000000000000 > 0) {
                result = (result * 0x10002C5CC37DA9492) >> 64;
            }
            if (x & 0x2000000000000 > 0) {
                result = (result * 0x1000162E525EE0547) >> 64;
            }
            if (x & 0x1000000000000 > 0) {
                result = (result * 0x10000B17255775C04) >> 64;
            }
            if (x & 0x800000000000 > 0) {
                result = (result * 0x1000058B91B5BC9AE) >> 64;
            }
            if (x & 0x400000000000 > 0) {
                result = (result * 0x100002C5C89D5EC6D) >> 64;
            }
            if (x & 0x200000000000 > 0) {
                result = (result * 0x10000162E43F4F831) >> 64;
            }
            if (x & 0x100000000000 > 0) {
                result = (result * 0x100000B1721BCFC9A) >> 64;
            }
            if (x & 0x80000000000 > 0) {
                result = (result * 0x10000058B90CF1E6E) >> 64;
            }
            if (x & 0x40000000000 > 0) {
                result = (result * 0x1000002C5C863B73F) >> 64;
            }
            if (x & 0x20000000000 > 0) {
                result = (result * 0x100000162E430E5A2) >> 64;
            }
            if (x & 0x10000000000 > 0) {
                result = (result * 0x1000000B172183551) >> 64;
            }
            if (x & 0x8000000000 > 0) {
                result = (result * 0x100000058B90C0B49) >> 64;
            }
            if (x & 0x4000000000 > 0) {
                result = (result * 0x10000002C5C8601CC) >> 64;
            }
            if (x & 0x2000000000 > 0) {
                result = (result * 0x1000000162E42FFF0) >> 64;
            }
            if (x & 0x1000000000 > 0) {
                result = (result * 0x10000000B17217FBB) >> 64;
            }
            if (x & 0x800000000 > 0) {
                result = (result * 0x1000000058B90BFCE) >> 64;
            }
            if (x & 0x400000000 > 0) {
                result = (result * 0x100000002C5C85FE3) >> 64;
            }
            if (x & 0x200000000 > 0) {
                result = (result * 0x10000000162E42FF1) >> 64;
            }
            if (x & 0x100000000 > 0) {
                result = (result * 0x100000000B17217F8) >> 64;
            }
            if (x & 0x80000000 > 0) {
                result = (result * 0x10000000058B90BFC) >> 64;
            }
            if (x & 0x40000000 > 0) {
                result = (result * 0x1000000002C5C85FE) >> 64;
            }
            if (x & 0x20000000 > 0) {
                result = (result * 0x100000000162E42FF) >> 64;
            }
            if (x & 0x10000000 > 0) {
                result = (result * 0x1000000000B17217F) >> 64;
            }
            if (x & 0x8000000 > 0) {
                result = (result * 0x100000000058B90C0) >> 64;
            }
            if (x & 0x4000000 > 0) {
                result = (result * 0x10000000002C5C860) >> 64;
            }
            if (x & 0x2000000 > 0) {
                result = (result * 0x1000000000162E430) >> 64;
            }
            if (x & 0x1000000 > 0) {
                result = (result * 0x10000000000B17218) >> 64;
            }
            if (x & 0x800000 > 0) {
                result = (result * 0x1000000000058B90C) >> 64;
            }
            if (x & 0x400000 > 0) {
                result = (result * 0x100000000002C5C86) >> 64;
            }
            if (x & 0x200000 > 0) {
                result = (result * 0x10000000000162E43) >> 64;
            }
            if (x & 0x100000 > 0) {
                result = (result * 0x100000000000B1721) >> 64;
            }
            if (x & 0x80000 > 0) {
                result = (result * 0x10000000000058B91) >> 64;
            }
            if (x & 0x40000 > 0) {
                result = (result * 0x1000000000002C5C8) >> 64;
            }
            if (x & 0x20000 > 0) {
                result = (result * 0x100000000000162E4) >> 64;
            }
            if (x & 0x10000 > 0) {
                result = (result * 0x1000000000000B172) >> 64;
            }
            if (x & 0x8000 > 0) {
                result = (result * 0x100000000000058B9) >> 64;
            }
            if (x & 0x4000 > 0) {
                result = (result * 0x10000000000002C5D) >> 64;
            }
            if (x & 0x2000 > 0) {
                result = (result * 0x1000000000000162E) >> 64;
            }
            if (x & 0x1000 > 0) {
                result = (result * 0x10000000000000B17) >> 64;
            }
            if (x & 0x800 > 0) {
                result = (result * 0x1000000000000058C) >> 64;
            }
            if (x & 0x400 > 0) {
                result = (result * 0x100000000000002C6) >> 64;
            }
            if (x & 0x200 > 0) {
                result = (result * 0x10000000000000163) >> 64;
            }
            if (x & 0x100 > 0) {
                result = (result * 0x100000000000000B1) >> 64;
            }
            if (x & 0x80 > 0) {
                result = (result * 0x10000000000000059) >> 64;
            }
            if (x & 0x40 > 0) {
                result = (result * 0x1000000000000002C) >> 64;
            }
            if (x & 0x20 > 0) {
                result = (result * 0x10000000000000016) >> 64;
            }
            if (x & 0x10 > 0) {
                result = (result * 0x1000000000000000B) >> 64;
            }
            if (x & 0x8 > 0) {
                result = (result * 0x10000000000000006) >> 64;
            }
            if (x & 0x4 > 0) {
                result = (result * 0x10000000000000003) >> 64;
            }
            if (x & 0x2 > 0) {
                result = (result * 0x10000000000000001) >> 64;
            }
            if (x & 0x1 > 0) {
                result = (result * 0x10000000000000001) >> 64;
            }

            // We're doing two things at the same time:
            //
            //   1. Multiply the result by 2^n + 1, where "2^n" is the integer part and the one is added to account for
            //      the fact that we initially set the result to 0.5. This is accomplished by subtracting from 191
            //      rather than 192.
            //   2. Convert the result to the unsigned 60.18-decimal fixed-point format.
            //
            // This works because 2^(191-ip) = 2^ip / 2^191, where "ip" is the integer part "2^n".
            result *= SCALE;
            result >>= (191 - (x >> 64));
        }
    }

    /// @notice Finds the zero-based index of the first one in the binary representation of x.
    /// @dev See the note on msb in the "Find First Set" Wikipedia article https://en.wikipedia.org/wiki/Find_first_set
    /// @param x The uint256 number for which to find the index of the most significant bit.
    /// @return msb The index of the most significant bit as an uint256.
    function mostSignificantBit(uint256 x) internal pure returns (uint256 msb) {
        if (x >= 2**128) {
            x >>= 128;
            msb += 128;
        }
        if (x >= 2**64) {
            x >>= 64;
            msb += 64;
        }
        if (x >= 2**32) {
            x >>= 32;
            msb += 32;
        }
        if (x >= 2**16) {
            x >>= 16;
            msb += 16;
        }
        if (x >= 2**8) {
            x >>= 8;
            msb += 8;
        }
        if (x >= 2**4) {
            x >>= 4;
            msb += 4;
        }
        if (x >= 2**2) {
            x >>= 2;
            msb += 2;
        }
        if (x >= 2**1) {
            // No need to shift x any more.
            msb += 1;
        }
    }

    /// @notice Calculates floor(x*y÷denominator) with full precision.
    ///
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv.
    ///
    /// Requirements:
    /// - The denominator cannot be zero.
    /// - The result must fit within uint256.
    ///
    /// Caveats:
    /// - This function does not work with fixed-point numbers.
    ///
    /// @param x The multiplicand as an uint256.
    /// @param y The multiplier as an uint256.
    /// @param denominator The divisor as an uint256.
    /// @return result The result as an uint256.
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
        // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2^256 + prod0.
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(x, y, not(0))
            prod0 := mul(x, y)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Handle non-overflow cases, 256 by 256 division.
        if (prod1 == 0) {
            unchecked {
                result = prod0 / denominator;
            }
            return result;
        }

        // Make sure the result is less than 2^256. Also prevents denominator == 0.
        if (prod1 >= denominator) {
            revert PRBMath__MulDivOverflow(prod1, denominator);
        }

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0].
        uint256 remainder;
        assembly {
            // Compute remainder using mulmod.
            remainder := mulmod(x, y, denominator)

            // Subtract 256 bit number from 512 bit number.
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
        // See https://cs.stackexchange.com/q/138556/92363.
        unchecked {
            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 lpotdod = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by lpotdod.
                denominator := div(denominator, lpotdod)

                // Divide [prod1 prod0] by lpotdod.
                prod0 := div(prod0, lpotdod)

                // Flip lpotdod such that it is 2^256 / lpotdod. If lpotdod is zero, then it becomes one.
                lpotdod := add(div(sub(0, lpotdod), lpotdod), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * lpotdod;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /// @notice Calculates floor(x*y÷1e18) with full precision.
    ///
    /// @dev Variant of "mulDiv" with constant folding, i.e. in which the denominator is always 1e18. Before returning the
    /// final result, we add 1 if (x * y) % SCALE >= HALF_SCALE. Without this, 6.6e-19 would be truncated to 0 instead of
    /// being rounded to 1e-18.  See "Listing 6" and text above it at https://accu.org/index.php/journals/1717.
    ///
    /// Requirements:
    /// - The result must fit within uint256.
    ///
    /// Caveats:
    /// - The body is purposely left uncommented; see the NatSpec comments in "PRBMath.mulDiv" to understand how this works.
    /// - It is assumed that the result can never be type(uint256).max when x and y solve the following two equations:
    ///     1. x * y = type(uint256).max * SCALE
    ///     2. (x * y) % SCALE >= SCALE / 2
    ///
    /// @param x The multiplicand as an unsigned 60.18-decimal fixed-point number.
    /// @param y The multiplier as an unsigned 60.18-decimal fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function mulDivFixedPoint(uint256 x, uint256 y) internal pure returns (uint256 result) {
        uint256 prod0;
        uint256 prod1;
        assembly {
            let mm := mulmod(x, y, not(0))
            prod0 := mul(x, y)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        if (prod1 >= SCALE) {
            revert PRBMath__MulDivFixedPointOverflow(prod1);
        }

        uint256 remainder;
        uint256 roundUpUnit;
        assembly {
            remainder := mulmod(x, y, SCALE)
            roundUpUnit := gt(remainder, 499999999999999999)
        }

        if (prod1 == 0) {
            unchecked {
                result = (prod0 / SCALE) + roundUpUnit;
                return result;
            }
        }

        assembly {
            result := add(
                mul(
                    or(
                        div(sub(prod0, remainder), SCALE_LPOTD),
                        mul(sub(prod1, gt(remainder, prod0)), add(div(sub(0, SCALE_LPOTD), SCALE_LPOTD), 1))
                    ),
                    SCALE_INVERSE
                ),
                roundUpUnit
            )
        }
    }

    /// @notice Calculates floor(x*y÷denominator) with full precision.
    ///
    /// @dev An extension of "mulDiv" for signed numbers. Works by computing the signs and the absolute values separately.
    ///
    /// Requirements:
    /// - None of the inputs can be type(int256).min.
    /// - The result must fit within int256.
    ///
    /// @param x The multiplicand as an int256.
    /// @param y The multiplier as an int256.
    /// @param denominator The divisor as an int256.
    /// @return result The result as an int256.
    function mulDivSigned(
        int256 x,
        int256 y,
        int256 denominator
    ) internal pure returns (int256 result) {
        if (x == type(int256).min || y == type(int256).min || denominator == type(int256).min) {
            revert PRBMath__MulDivSignedInputTooSmall();
        }

        // Get hold of the absolute values of x, y and the denominator.
        uint256 ax;
        uint256 ay;
        uint256 ad;
        unchecked {
            ax = x < 0 ? uint256(-x) : uint256(x);
            ay = y < 0 ? uint256(-y) : uint256(y);
            ad = denominator < 0 ? uint256(-denominator) : uint256(denominator);
        }

        // Compute the absolute value of (x*y)÷denominator. The result must fit within int256.
        uint256 rAbs = mulDiv(ax, ay, ad);
        if (rAbs > uint256(type(int256).max)) {
            revert PRBMath__MulDivSignedOverflow(rAbs);
        }

        // Get the signs of x, y and the denominator.
        uint256 sx;
        uint256 sy;
        uint256 sd;
        assembly {
            sx := sgt(x, sub(0, 1))
            sy := sgt(y, sub(0, 1))
            sd := sgt(denominator, sub(0, 1))
        }

        // XOR over sx, sy and sd. This is checking whether there are one or three negative signs in the inputs.
        // If yes, the result should be negative.
        result = sx ^ sy ^ sd == 0 ? -int256(rAbs) : int256(rAbs);
    }

    /// @notice Calculates the square root of x, rounding down.
    /// @dev Uses the Babylonian method https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method.
    ///
    /// Caveats:
    /// - This function does not work with fixed-point numbers.
    ///
    /// @param x The uint256 number for which to calculate the square root.
    /// @return result The result as an uint256.
    function sqrt(uint256 x) internal pure returns (uint256 result) {
        if (x == 0) {
            return 0;
        }

        // Set the initial guess to the least power of two that is greater than or equal to sqrt(x).
        uint256 xAux = uint256(x);
        result = 1;
        if (xAux >= 0x100000000000000000000000000000000) {
            xAux >>= 128;
            result <<= 64;
        }
        if (xAux >= 0x10000000000000000) {
            xAux >>= 64;
            result <<= 32;
        }
        if (xAux >= 0x100000000) {
            xAux >>= 32;
            result <<= 16;
        }
        if (xAux >= 0x10000) {
            xAux >>= 16;
            result <<= 8;
        }
        if (xAux >= 0x100) {
            xAux >>= 8;
            result <<= 4;
        }
        if (xAux >= 0x10) {
            xAux >>= 4;
            result <<= 2;
        }
        if (xAux >= 0x8) {
            result <<= 1;
        }

        // The operations can never overflow because the result is max 2^127 when it enters this block.
        unchecked {
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1; // Seven iterations should be enough
            uint256 roundedDownResult = x / result;
            return result >= roundedDownResult ? roundedDownResult : result;
        }
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "../libraries/LStakingItem.sol";

interface IEmissionPool {

    function addBasketPool(address basketPool) external;

    function addPenaltyToken(address reclaimedToken, uint256 reclaimedBalance) external;

    function addPenaltyRewards(uint256 forfeitedRewards) external;

    function reclaimPenalty(address reclaimedToken, address vault) external returns (bool);

    function reclaimRewards(address vault, uint256 emptyDaysRewards) external returns (bool);

    function tokenTransfer(address to, address token, uint256 amount) external returns (bool);

    function getEmissionToken() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IBasketPool {

    function stake(bytes32 itemId, address token, uint256 amount) external;

    function unstake(bytes32 itemId, address to, uint256 current, uint256 amount) external;    

    function earlyRedeem(bytes32 itemId, uint256 rewards) external;

    function getPoolType() external view returns (bool);

    function principalBalance(bytes32 itemId) external view returns (uint256);    

    function principalCurrency(bytes32 itemId) external view returns (address);
}

/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../../interfaces/IEmissionPool.sol";
import "../../interfaces/IBasketPool.sol";
import "../../libraries/LDatetime.sol";

// import "hardhat/console.sol";

/**
    @author 
    @title Ink Finance v3 staking basket pool
    @dev BasketPool is used to manage multiple staking tokens and staking request such as stake, earlyredeem, etc
        each basket will have one basket pool.
*/
contract BasketPool is IBasketPool {
    using SafeERC20 for IERC20;

    struct TokenPair {
        address token;
        uint256 amount;
    }

    /// @dev normal staking pool's variables
    address private immutable _myBasket;
    address private immutable _rewardPool;
    uint256 private immutable _stakingBegin;
    uint256 private immutable _stakingPeriod;

    /// @dev pool's flag (true: principal pool, false: buffer pool) */ 
    bool private _type; 

    /// @dev mapping for token pairs, key is staking id, value is TokenPair mapping
    mapping(bytes32 => TokenPair) private _stakingTokenPairs;

    constructor(address rewardPool,
        uint256 stakingBegin,
        uint256 stakingPeriod) {

        _myBasket = msg.sender;
        _rewardPool = rewardPool;
        _stakingBegin = stakingBegin;
        _stakingPeriod = stakingPeriod;
        _type = false;
    }

    /// @dev throws if called by any account other than the parent staking basket
    modifier onlyMyBasket() {
        require (msg.sender == _myBasket, "Invalid caller");
        _;
    }

    function getPoolType() external override view returns (bool) {
        return _type;
    }

    /// @dev stake request
    function stake(bytes32 itemId, address token, uint256 amount) 
    external override onlyMyBasket {
        /// @dev transfer staking-in erc20 tokens to basketpool, but now disabled only for testing
        _stakingTokenPairs[itemId].token = token;
        _stakingTokenPairs[itemId].amount = amount;
        _updateShare();
    }

    /// @dev unstake request
    function unstake(bytes32 itemId, address to, uint256 current, uint256 amount) 
    external override onlyMyBasket {
        require(_stakingTokenPairs[itemId].amount >= amount, "Invalid amount in BasketPool");

        if (_stakingTokenPairs[itemId].amount > 0) {
            uint256 value = _stakingTokenPairs[itemId].amount * amount / current;        
            _stakingTokenPairs[itemId].amount -= value;

            IEmissionPool(_rewardPool).tokenTransfer(to, _stakingTokenPairs[itemId].token, value);
        }
        _updateShare();
    }

    function earlyRedeem(bytes32 itemId, uint256 rewards)
    external override onlyMyBasket {
        if (_stakingTokenPairs[itemId].amount > 0) {
            uint256 value = _stakingTokenPairs[itemId].amount;
            _stakingTokenPairs[itemId].amount = 0;

            IEmissionPool(_rewardPool).addPenaltyToken(_stakingTokenPairs[itemId].token, value);
        }
        IEmissionPool(_rewardPool).addPenaltyRewards(rewards);
        _updateShare();
    }

    function _updateShare() internal {
        
    }

    /// @dev get item's staking token balance
    function principalBalance(bytes32 itemId) 
    external 
    override view returns (uint256) {
        return _stakingTokenPairs[itemId].amount;
    }

    /// @dev get item's staking token balance
    function principalCurrency(bytes32 itemId) 
    external 
    override view returns (address) {
        return _stakingTokenPairs[itemId].token;
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
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
        IERC20 token,
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
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
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
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
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