// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.7.6;

import {Address} from '@openzeppelin/contracts/utils/Address.sol';
import {OwnableUpgradeable} from '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import {AddressUpgradeable} from '@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {ERC20} from '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';

import {IRewardsDistributor} from './interfaces/IRewardsDistributor.sol';
import {IGarden} from './interfaces/IGarden.sol';
import {IGardenFactory} from './interfaces/IGardenFactory.sol';
import {IStrategy} from './interfaces/IStrategy.sol';
import {IPriceOracle} from './interfaces/IPriceOracle.sol';
import {IIshtarGate} from './interfaces/IIshtarGate.sol';
import {IIntegration} from './interfaces/IIntegration.sol';
import {IBabController} from './interfaces/IBabController.sol';
import {IHypervisor} from './interfaces/IHypervisor.sol';
import {IWETH} from './interfaces/external/weth/IWETH.sol';

import {AddressArrayUtils} from './lib/AddressArrayUtils.sol';
import {LowGasSafeMath} from './lib/LowGasSafeMath.sol';
import {PreciseUnitMath} from './lib/PreciseUnitMath.sol';

/**
 * @title BabController
 * @author Babylon Finance Protocol
 *
 * BabController is a smart contract used to deploy new gardens contracts and house the
 * integrations and resources of the system.
 */
contract BabController is OwnableUpgradeable, IBabController {
    using AddressArrayUtils for address[];
    using Address for address;
    using AddressUpgradeable for address;
    using LowGasSafeMath for uint256;
    using SafeERC20 for IERC20;
    using PreciseUnitMath for uint256;

    /* ============ Events ============ */

    event GardenAdded(address indexed _garden, address indexed _factory);
    event GardenRemoved(address indexed _garden);

    event ControllerIntegrationAdded(address _integration, string indexed _integrationName);
    event ControllerIntegrationRemoved(address _integration, string indexed _integrationName);
    event ControllerIntegrationEdited(address _newIntegration, string indexed _integrationName);
    event ControllerOperationSet(uint8 indexed _kind, address _address);
    event MasterSwapperChanged(address indexed _newTradeIntegration, address _oldTradeIntegration);

    event ReserveAssetAdded(address indexed _reserveAsset);
    event ReserveAssetRemoved(address indexed _reserveAsset);
    event ProtocolWantedAssetUpdated(address indexed _wantedAsset, bool _wanted);
    event GardenAffiliateRateUpdated(address indexed _garden, uint256 _affiliateRate);
    event AffiliateRewardsClaimed(address indexed _user, uint256 _rewardsClaimed);
    event AffiliateRewards(address indexed _depositor, address indexed _referrer, uint256 _reserve, uint256 _reward);
    event LiquidityMinimumEdited(address indexed _resesrveAsset, uint256 _newMinLiquidityReserve);

    event PriceOracleChanged(address indexed _priceOracle, address _oldPriceOracle);
    event RewardsDistributorChanged(address indexed _rewardsDistributor, address _oldRewardsDistributor);
    event TreasuryChanged(address _newTreasury, address _oldTreasury);
    event IshtarGateChanged(address _newIshtarGate, address _oldIshtarGate);
    event MardukGateChanged(address _newMardukGate, address _oldMardukGate);
    event GardenValuerChanged(address indexed _gardenValuer, address _oldGardenValuer);
    event GardenFactoryChanged(address indexed _gardenFactory, address _oldGardenFactory);
    event UniswapFactoryChanged(address indexed _newUniswapFactory, address _oldUniswapFactory);
    event GardenNFTChanged(address indexed _newGardenNFT, address _oldStrategyNFT);
    event StrategyNFTChanged(address indexed _newStrategyNFT, address _oldStrategyNFT);
    event HeartChanged(address indexed _newHeart, address _oldHeart);

    event StrategyFactoryEdited(address indexed _strategyFactory, address _oldStrategyFactory);

    /// @notice Emitted when pause guardian is changed
    event NewPauseGuardian(address _oldPauseGuardian, address _newPauseGuardian);

    /// @notice Emitted when an action is paused globally
    event ActionPaused(bool _pauseState);

    /// @notice Emitted when an action is paused individually
    event ActionPausedIndividually(address _address, bool _pauseState);

    /* ============ Modifiers ============ */

    function _onlyGovernanceOrEmergency() internal view {
        require(msg.sender == owner() || msg.sender == EMERGENCY_OWNER, 'Not enough privileges');
    }

    /* ============ State Variables ============ */

    // List of enabled Communities
    address[] public gardens;
    address[] public reserveAssets;
    address private uniswapFactory; // do not use
    address public override gardenValuer;
    address public override priceOracle;
    address public override gardenFactory;
    address public override rewardsDistributor;
    address public override ishtarGate;
    address public override strategyFactory;
    address public override gardenNFT;
    address public override strategyNFT;

    // Mapping of integration name => integration address
    mapping(bytes32 => address) private enabledIntegrations; // DEPRECATED
    // Address of the master swapper used by the protocol
    address public override masterSwapper;
    // Mapping of valid operations
    address[MAX_OPERATIONS] public override enabledOperations;

    // Mappings to check whether address is valid Garden or Reserve Asset
    mapping(address => bool) public override isGarden;
    mapping(address => bool) public validReserveAsset;

    // Mapping to check whitelisted assets
    mapping(address => bool) private assetWhitelist;

    // Mapping to check keepers
    mapping(address => bool) public keeperList;

    // Mapping of minimum liquidity per reserve asset
    mapping(address => uint256) public override minLiquidityPerReserve;

    // Recipient of protocol fees
    address public override treasury;

    // Strategy Profit Sharing
    uint256 private strategistProfitPercentage; // DEPRECATED
    uint256 private stewardsProfitPercentage; // DEPRECATED
    uint256 private lpsProfitPercentage; // DEPRECATED

    // Strategy BABL Rewards Sharing
    uint256 private strategistBABLPercentage; // DEPRECATED
    uint256 private stewardsBABLPercentage; // DEPRECATED
    uint256 private lpsBABLPercentage; // DEPRECATED

    uint256 private gardenCreatorBonus; // DEPRECATED

    // Assets

    // Enable Transfer of ERC20 gardenTokens
    // Only members can transfer tokens until the protocol is fully decentralized
    bool public override gardenTokensTransfersEnabled;

    // Enable and starts the BABL Mining program within Rewards Distributor contract
    bool public override bablMiningProgramEnabled;
    // Enable public gardens
    bool public override allowPublicGardens;

    uint256 public override protocolPerformanceFee; // 5% (0.01% = 1e14, 1% = 1e16) on profits
    uint256 public override protocolManagementFee; // 0.5% (0.01% = 1e14, 1% = 1e16)
    uint256 private protocolDepositGardenTokenFee; // 0 (0.01% = 1e14, 1% = 1e16)
    uint256 private protocolWithdrawalGardenTokenFee; // 0 (0.01% = 1e14, 1% = 1e16)

    // Maximum number of contributors per garden
    uint256 private maxContributorsPerGarden; // DEPRECATED

    // Enable garden creations to be fully open to the public (no need of Ishtar gate anymore)
    bool public override gardenCreationIsOpen;

    // Pause Guardian
    address public guardian;
    mapping(address => bool) public override guardianPaused;
    bool public override guardianGlobalPaused;

    address public override mardukGate;
    address public override heart;
    address public override curveMetaRegistry;
    mapping(address => bool) public override protocolWantedAssets;
    mapping(address => uint256) public override gardenAffiliateRates; // 18 decimals
    mapping(address => uint256) public override affiliateRewards;

    // Mapping oldIntegration -> _newIntegration
    // Allows to fix bugs for integrations per address
    mapping(address => address) public override patchedIntegrations;

    /* ============ Constants ============ */

    address public constant override EMERGENCY_OWNER = 0x97FcC2Ae862D03143b393e9fA73A32b563d57A6e;
    IWETH public constant WETH = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IERC20 public constant BABL = IERC20(0xF4Dc48D260C93ad6a96c5Ce563E70CA578987c74);
    uint8 public constant MAX_OPERATIONS = 20;

    /* ============ Constructor ============ */

    /**
     * Initializes the initial fee recipient on deployment.
     */
    function initialize() public initializer {
        OwnableUpgradeable.__Ownable_init();

        // vars init values has to be set in initialize due to how upgrade proxy pattern works
        protocolManagementFee = 5e15; // 0.5% (0.01% = 1e14, 1% = 1e16)
        protocolPerformanceFee = 5e16; // 5% (0.01% = 1e14, 1% = 1e16) on profits
        protocolDepositGardenTokenFee = 0; // 0% (0.01% = 1e14, 1% = 1e16) on profits
        protocolWithdrawalGardenTokenFee = 0; // 0% (0.01% = 1e14, 1% = 1e16) on profits

        maxContributorsPerGarden = 100;
        gardenCreationIsOpen = false;
        allowPublicGardens = true;
        bablMiningProgramEnabled = true;
    }

    /* ============ External Functions ============ */

    // ===========  Garden related Gov Functions ======
    /**
     * Creates a Garden smart contract and registers the Garden with the controller.
     *
     * If asset is not WETH, the creator needs to approve the controller
     * @param _reserveAsset                     Reserve asset of the Garden. Initially just weth
     * @param _name                             Name of the Garden
     * @param _symbol                           Symbol of the Garden
     * @param _gardenParams                     Array of numeric garden params
     * @param _tokenURI                         Garden NFT token URI
     * @param _seed                             Seed to regenerate the garden NFT
     * @param _initialContribution              Initial contribution by the gardener
     * @param _publicGardenStrategistsStewards  Public garden, public strategist rights and public stewards rights
     * @param _profitSharing                    Custom profit sharing (if any)
     */
    function createGarden(
        address _reserveAsset,
        string memory _name,
        string memory _symbol,
        string memory _tokenURI,
        uint256 _seed,
        uint256[] calldata _gardenParams,
        uint256 _initialContribution,
        bool[] memory _publicGardenStrategistsStewards,
        uint256[] memory _profitSharing
    ) external payable override returns (address) {
        require(masterSwapper != address(0), 'Need a default trade integration');
        require(enabledOperations.length > 0, 'Need operations enabled');
        require(
            mardukGate != address(0) &&
                gardenNFT != address(0) &&
                strategyFactory != address(0) &&
                gardenValuer != address(0) &&
                treasury != address(0),
            'Parameters not initialized'
        );
        require(
            gardenCreationIsOpen || IIshtarGate(mardukGate).canCreate(msg.sender),
            'User does not have creation permissions'
        );
        address newGarden =
            IGardenFactory(gardenFactory).createGarden(
                _reserveAsset,
                msg.sender,
                _name,
                _symbol,
                _tokenURI,
                _seed,
                _gardenParams,
                _initialContribution,
                _publicGardenStrategistsStewards
            );
        if (_reserveAsset != address(WETH) || msg.value == 0) {
            IERC20(_reserveAsset).safeTransferFrom(msg.sender, address(this), _initialContribution);
            IERC20(_reserveAsset).safeApprove(newGarden, _initialContribution);
        }
        require(!isGarden[newGarden], 'Garden already exists');
        isGarden[newGarden] = true;
        gardens.push(newGarden);
        IGarden(newGarden).deposit{value: msg.value}(
            _initialContribution,
            _initialContribution,
            msg.sender,
            address(0)
        );
        // Avoid gas cost if default sharing values are provided (0,0,0)
        if (_profitSharing[0] != 0 || _profitSharing[1] != 0 || _profitSharing[2] != 0) {
            IRewardsDistributor(rewardsDistributor).setProfitRewards(
                newGarden,
                _profitSharing[0],
                _profitSharing[1],
                _profitSharing[2]
            );
        }
        emit GardenAdded(newGarden, msg.sender);
        return newGarden;
    }

    /**
     * PRIVILEGED GOVERNANCE FUNCTION. Allows governance to remove a Garden
     *
     * @param _garden               Address of the Garden contract to remove
     */
    function removeGarden(address _garden) external override onlyOwner {
        require(isGarden[_garden], 'Garden does not exist');
        require(IGarden(_garden).getStrategies().length == 0, 'Garden has active strategies!');
        gardens = gardens.remove(_garden);
        delete isGarden[_garden];

        emit GardenRemoved(_garden);
    }

    /**
     * PRIVILEGED GOVERNANCE FUNCTION. Allows transfers of ERC20 gardenTokens
     * Can only happen after 2021 is finished.
     */
    function enableGardenTokensTransfers() external override onlyOwner {
        require(block.timestamp > 1641024000, 'Transfers cannot be enabled yet');
        gardenTokensTransfersEnabled = true;
    }

    // ===========  Protocol related Gov Functions ======

    /**
     * PRIVILEGED FUNCTION. Adds a new valid keeper to the list
     *
     * @param _keeper Address of the keeper
     */
    function addKeeper(address _keeper) external override {
        _onlyGovernanceOrEmergency();
        require(!keeperList[_keeper] && _keeper != address(0), 'Incorrect address');
        keeperList[_keeper] = true;
    }

    /**
     * PRIVILEGED FUNCTION. Removes a keeper
     *
     * @param _keeper Address of the keeper
     */
    function removeKeeper(address _keeper) external override {
        _onlyGovernanceOrEmergency();
        require(keeperList[_keeper], 'Keeper is whitelisted');
        delete keeperList[_keeper];
    }

    /**
     * PRIVILEGED FUNCTION. Adds a list of assets to the whitelist
     *
     * @param _keepers List with keeprs of the assets to whitelist
     */
    function addKeepers(address[] memory _keepers) external override {
        _onlyGovernanceOrEmergency();
        for (uint256 i = 0; i < _keepers.length; i++) {
            keeperList[_keepers[i]] = true;
        }
    }

    /**
     * PRIVILEGED FUNCTION. Adds a new valid reserve asset for gardens
     *
     * @param _reserveAsset Address of the reserve assset
     */
    function addReserveAsset(address _reserveAsset) external override {
        _onlyGovernanceOrEmergency();
        require(_reserveAsset != address(0) && ERC20(_reserveAsset).decimals() <= 18, 'Incorrect address');
        require(!validReserveAsset[_reserveAsset], 'Reserve asset already added');
        validReserveAsset[_reserveAsset] = true;
        reserveAssets.push(_reserveAsset);
        emit ReserveAssetAdded(_reserveAsset);
    }

    /**
     * PRIVILEGED GOVERNANCE FUNCTION. Allows governance to remove a reserve asset
     *
     * @param _reserveAsset               Address of the reserve asset to remove
     */
    function removeReserveAsset(address _reserveAsset) external override {
        _onlyGovernanceOrEmergency();
        require(validReserveAsset[_reserveAsset], 'Reserve asset does not exist');
        reserveAssets = reserveAssets.remove(_reserveAsset);
        delete validReserveAsset[_reserveAsset];
        emit ReserveAssetRemoved(_reserveAsset);
    }

    /**
     * PRIVILEGED FUNCTION. Updates a protocol wanted asset
     *
     * @param _wantedAsset  Address of the wanted assset
     * @param _wanted       True if wanted, false otherwise
     */
    function updateProtocolWantedAsset(address _wantedAsset, bool _wanted) external override {
        _onlyGovernanceOrEmergency();
        require(_wantedAsset != address(0) && ERC20(_wantedAsset).decimals() <= 18, 'Incorrect address');
        require(protocolWantedAssets[_wantedAsset] != _wanted, 'Wanted asset already added');
        protocolWantedAssets[_wantedAsset] = _wanted;
        emit ProtocolWantedAssetUpdated(_wantedAsset, _wanted);
    }

    /**
     * PRIVILEGED FUNCTION. Updates the affiliate rate for a garden. 0 if none.
     *
     * @param _garden              Address of the garden
     * @param _affiliateRate       Affiliate rate for this garden
     */
    function updateGardenAffiliateRate(address _garden, uint256 _affiliateRate) external override {
        _onlyGovernanceOrEmergency();
        require(isGarden[_garden], 'Garden is not valid');
        require(gardenAffiliateRates[_garden] != _affiliateRate, 'Rate already set');
        gardenAffiliateRates[_garden] = _affiliateRate;
        emit GardenAffiliateRateUpdated(_garden, _affiliateRate);
    }

    /**
     * PRIVILEGED FUNCTION. Adds the affiliate rewards earned by an user
     *
     * Only a garden can call this
     *
     * @param _depositor            Address of the user that deposits
     * @param _referrer             Address of the user that refers
     * @param _reserveAmount        Amount of reserved deposited by a link of the user
     */
    function addAffiliateReward(
        address _depositor,
        address _referrer,
        uint256 _reserveAmount
    ) external override {
        require(isGarden[msg.sender], 'Only garden can add rewards');
        require(_referrer != address(0) && _reserveAmount > 0, 'User and/or amount invalid');
        if (gardenAffiliateRates[msg.sender] > 0) {
            uint256 totalReward = _reserveAmount.preciseMul(gardenAffiliateRates[msg.sender]);
            affiliateRewards[_depositor] = affiliateRewards[_depositor].add(totalReward.div(2));
            if (_depositor != _referrer) {
                affiliateRewards[_referrer] = affiliateRewards[_referrer].add(totalReward.div(2));
            }
            emit AffiliateRewards(_depositor, _referrer, _reserveAmount, totalReward);
        }
    }

    /**
     * Claims affiliate rewards
     * Controller needs to hold BABL.
     */
    function claimRewards() external override {
        uint256 rewards = affiliateRewards[msg.sender];

        require(rewards > 0, 'No affiliate rewards');
        require(BABL.balanceOf(address(this)) >= rewards, 'Not enough BABL balance');

        delete affiliateRewards[msg.sender];

        BABL.transfer(msg.sender, rewards);

        emit AffiliateRewardsClaimed(msg.sender, rewards);
    }

    /**
     * PRIVILEGED GOVERNANCE FUNCTION. Allows governance to change the Marduk Gate Address
     *
     * @param _mardukGate               Address of the new Marduk Gate
     */
    function editMardukGate(address _mardukGate) external override onlyOwner {
        require(_mardukGate != mardukGate, 'Marduk Gate already exists');

        require(_mardukGate != address(0), 'Marduk Gate oracle must exist');

        address oldMardukGate = mardukGate;
        mardukGate = _mardukGate;

        emit MardukGateChanged(_mardukGate, oldMardukGate);
    }

    function editRewardsDistributor(address _newRewardsDistributor) external override onlyOwner {
        require(_newRewardsDistributor != address(0), 'Address must not be 0');

        address oldRewardsDistributor = rewardsDistributor;
        rewardsDistributor = _newRewardsDistributor;

        emit RewardsDistributorChanged(_newRewardsDistributor, oldRewardsDistributor);
    }

    /**
     * PRIVILEGED GOVERNANCE FUNCTION. Allows governance to edit the protocol fee recipient
     *
     * @param _newTreasury      Address of the new protocol fee recipient
     */
    function editTreasury(address _newTreasury) external override onlyOwner {
        require(_newTreasury != address(0), 'Address must not be 0');

        address oldTreasury = treasury;
        treasury = _newTreasury;

        emit TreasuryChanged(_newTreasury, oldTreasury);
    }

    /**
     * PRIVILEGED GOVERNANCE FUNCTION. Allows governance to edit the heart contract
     *
     * @param _newHeart      Address of the new heart
     */
    function editHeart(address _newHeart) external override {
        _onlyGovernanceOrEmergency();
        require(_newHeart != address(0), 'Address must not be 0');

        address oldHeart = heart;
        heart = _newHeart;

        emit HeartChanged(_newHeart, oldHeart);
    }

    /**
     * PRIVILEGED GOVERNANCE FUNCTION. Allows governance to edit the curve meta registry
     *
     * @param _curveMetaRegistry      Address of the new curve meta registry
     */
    function editCurveMetaRegistry(address _curveMetaRegistry) external override {
        _onlyGovernanceOrEmergency();
        require(_curveMetaRegistry != address(0), 'Address must not be 0');

        curveMetaRegistry = _curveMetaRegistry;
    }

    /**
     * GOVERNANCE FUNCTION: Edits the minimum liquidity an asset must have on Uniswap
     *
     * @param  _reserve                         Address of the reserve to edit
     * @param  _newMinLiquidityReserve          Absolute min liquidity of an asset to grab price
     */
    function editLiquidityReserve(address _reserve, uint256 _newMinLiquidityReserve) public override onlyOwner {
        require(_newMinLiquidityReserve > 0, '_minRiskyPairLiquidityEth > 0');
        require(validReserveAsset[_reserve], 'Needs to be a valid reserve');
        minLiquidityPerReserve[_reserve] = _newMinLiquidityReserve;

        emit LiquidityMinimumEdited(_reserve, _newMinLiquidityReserve);
    }

    // Setter that can be changed by the team in case of an emergency

    /**
     * PRIVILEGED GOVERNANCE FUNCTION. Allows governance to change the price oracle
     *
     * @param _priceOracle               Address of the new price oracle
     */
    function editPriceOracle(address _priceOracle) external override {
        _onlyGovernanceOrEmergency();
        require(_priceOracle != priceOracle, 'Price oracle already exists');

        require(_priceOracle != address(0), 'Price oracle must exist');

        address oldPriceOracle = priceOracle;
        priceOracle = _priceOracle;

        emit PriceOracleChanged(_priceOracle, oldPriceOracle);
    }

    /**
     * PRIVILEGED GOVERNANCE FUNCTION. Allows governance to change the garden valuer
     *
     * @param _gardenValuer Address of the new garden valuer
     */
    function editGardenValuer(address _gardenValuer) external override {
        _onlyGovernanceOrEmergency();
        require(_gardenValuer != gardenValuer, 'Garden Valuer already exists');

        require(_gardenValuer != address(0), 'Garden Valuer must exist');

        address oldGardenValuer = gardenValuer;
        gardenValuer = _gardenValuer;

        emit GardenValuerChanged(_gardenValuer, oldGardenValuer);
    }

    /**
     * PRIVILEGED GOVERNANCE FUNCTION. Allows governance to edit the protocol garden factory
     *
     * @param _newGardenFactory      Address of the new garden factory
     */
    function editGardenFactory(address _newGardenFactory) external override {
        _onlyGovernanceOrEmergency();
        require(_newGardenFactory != address(0), 'Address must not be 0');

        address oldGardenFactory = gardenFactory;
        gardenFactory = _newGardenFactory;

        emit GardenFactoryChanged(_newGardenFactory, oldGardenFactory);
    }

    /**
     * PRIVILEGED GOVERNANCE FUNCTION. Allows governance to edit the protocol garden NFT
     *
     * @param _newGardenNFT      Address of the new garden NFT
     */
    function editGardenNFT(address _newGardenNFT) external override {
        _onlyGovernanceOrEmergency();
        require(_newGardenNFT != address(0), 'Address must not be 0');

        address oldGardenNFT = gardenNFT;
        gardenNFT = _newGardenNFT;

        emit GardenNFTChanged(_newGardenNFT, oldGardenNFT);
    }

    /**
     * PRIVILEGED GOVERNANCE FUNCTION. Allows governance to edit the protocol strategy NFT
     *
     * @param _newStrategyNFT      Address of the new strategy NFT
     */
    function editStrategyNFT(address _newStrategyNFT) external override {
        _onlyGovernanceOrEmergency();
        require(_newStrategyNFT != address(0), 'Address must not be 0');

        address oldStrategyNFT = strategyNFT;
        strategyNFT = _newStrategyNFT;

        emit StrategyNFTChanged(_newStrategyNFT, oldStrategyNFT);
    }

    /**
     * PRIVILEGED GOVERNANCE FUNCTION. Allows governance to edit the protocol strategy factory
     *
     * @param _newStrategyFactory      Address of the new strategy factory
     */
    function editStrategyFactory(address _newStrategyFactory) external override {
        _onlyGovernanceOrEmergency();
        require(_newStrategyFactory != address(0), 'Address must not be 0');

        address oldStrategyFactory = strategyFactory;
        strategyFactory = _newStrategyFactory;

        emit StrategyFactoryEdited(_newStrategyFactory, oldStrategyFactory);
    }

    /**
     * PRIVILEGED GOVERNANCE FUNCTION. Allows governance to edit the protocol default trde integration
     *
     * @param _newDefaultMasterSwapper     Address of the new default trade integration
     */
    function setMasterSwapper(address _newDefaultMasterSwapper) external override {
        _onlyGovernanceOrEmergency();
        require(_newDefaultMasterSwapper != address(0), 'Address must not be 0');
        require(_newDefaultMasterSwapper != masterSwapper, 'Address must be different');
        address oldMasterSwapper = masterSwapper;
        masterSwapper = _newDefaultMasterSwapper;

        emit MasterSwapperChanged(_newDefaultMasterSwapper, oldMasterSwapper);
    }

    /**
     * GOVERNANCE FUNCTION: Edit an existing operation on the registry
     *
     * @param  _kind             Operation kind
     * @param  _operation        Address of the operation contract to set
     */
    function setOperation(uint8 _kind, address _operation) public override {
        _onlyGovernanceOrEmergency();
        require(_kind < MAX_OPERATIONS, 'Max operations reached');
        require(enabledOperations[_kind] != _operation, 'Operation already set');
        require(_operation != address(0), 'Operation address must exist.');
        enabledOperations[_kind] = _operation;

        emit ControllerOperationSet(_kind, _operation);
    }

    // ===========  Protocol security related Gov Functions ======

    /**
     * PRIVILEGED GOVERNANCE FUNCTION. Set-up a pause guardian
     * @param _guardian               Address of the guardian
     */
    function setPauseGuardian(address _guardian) external override {
        require(
            msg.sender == guardian || msg.sender == owner(),
            'only pause guardian and owner can update pause guardian'
        );
        require(msg.sender == owner() || _guardian != address(0), 'Guardian cannot remove himself');
        // Save current value for inclusion in log
        address oldPauseGuardian = guardian;
        // Store pauseGuardian with value newPauseGuardian
        guardian = _guardian;
        // Emit NewPauseGuardian(OldPauseGuardian, NewPauseGuardian)
        emit NewPauseGuardian(oldPauseGuardian, _guardian);
    }

    /**
     * PRIVILEGED GOVERNANCE FUNCTION. Pause the protocol globally in case of unexpected issue
     * Only the governance can unpause it
     * @param _state               True to pause, false to unpause.
     */
    function setGlobalPause(bool _state) external override returns (bool) {
        require(
            msg.sender == guardian || msg.sender == owner() || msg.sender == EMERGENCY_OWNER,
            'Not enough privileges'
        );
        require(!(msg.sender == guardian && _state == false), 'Not enough privileges');

        guardianGlobalPaused = _state;

        emit ActionPaused(_state);
        return _state;
    }

    /**
     * PRIVILEGED GOVERNANCE FUNCTION. Pause some smartcontracts in a batch process in case of unexpected issue
     * Only the governance can unpause it
     * @param _address             Addresses of protocol smartcontract to be paused
     * @param _state               Boolean pause state
     */
    function setSomePause(address[] memory _address, bool _state) external override returns (bool) {
        require(
            msg.sender == guardian || msg.sender == owner() || msg.sender == EMERGENCY_OWNER,
            'Not enough privileges'
        );
        require(!(msg.sender == guardian && _state == false), 'Not enough privileges');

        for (uint256 i = 0; i < _address.length; i++) {
            guardianPaused[_address[i]] = _state;
            emit ActionPausedIndividually(_address[i], _state);
        }
        return _state;
    }

    /**
     * Replace old integration with a new one for all the strategies using this integration
     * @param _old  Old integration address
     * @param _new  New integration address
     */
    function patchIntegration(address _old, address _new) external override {
        _onlyGovernanceOrEmergency();
        patchedIntegrations[_old] = _new;
    }

    /* ============ External Getter Functions ============ */

    function owner() public view override(IBabController, OwnableUpgradeable) returns (address) {
        return OwnableUpgradeable.owner();
    }

    function getGardens() external view override returns (address[] memory) {
        return gardens;
    }

    function getOperations() external view override returns (address[20] memory) {
        return enabledOperations;
    }

    function getReserveAssets() external view override returns (address[] memory) {
        return reserveAssets;
    }

    function isValidReserveAsset(address _reserveAsset) external view override returns (bool) {
        return validReserveAsset[_reserveAsset];
    }

    function isValidKeeper(address _keeper) external view override returns (bool) {
        return keeperList[_keeper];
    }

    /**
     * Check whether or not there is a global pause or a specific pause of the provided contract address
     * @param _contract               Smartcontract address to check for a global or specific pause
     */
    function isPaused(address _contract) external view override returns (bool) {
        return guardianGlobalPaused || guardianPaused[_contract];
    }

    /**
     * Check if a contract address is a garden or one of the system contracts
     *
     * @param  _contractAddress           The contract address to check
     */
    function isSystemContract(address _contractAddress) external view override returns (bool) {
        if (_contractAddress == address(0)) {
            return false;
        }
        return (isGarden[_contractAddress] ||
            gardenValuer == _contractAddress ||
            priceOracle == _contractAddress ||
            gardenFactory == _contractAddress ||
            masterSwapper == _contractAddress ||
            strategyFactory == _contractAddress ||
            rewardsDistributor == _contractAddress ||
            owner() == _contractAddress ||
            _contractAddress == address(this) ||
            _isOperation(_contractAddress) ||
            (isGarden[address(IStrategy(_contractAddress).garden())] &&
                IGarden(IStrategy(_contractAddress).garden()).strategyMapping(_contractAddress)) ||
            (isGarden[address(IStrategy(_contractAddress).garden())] &&
                IGarden(IStrategy(_contractAddress).garden()).isGardenStrategy(_contractAddress)));
    }

    /* ============ Internal Only Function ============ */

    /**
     * Hashes the string and returns a bytes32 value
     */
    function _nameHash(string memory _name) private pure returns (bytes32) {
        return keccak256(bytes(_name));
    }

    function _isOperation(address _address) private view returns (bool) {
        for (uint8 i = 0; i < MAX_OPERATIONS; i++) {
            if (_address == enabledOperations[i]) {
                return true;
            }
        }
        return false;
    }

    // Can receive ETH
    // solhint-disable-next-line
    receive() external payable {}
}

contract BabControllerV18 is BabController {}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

pragma solidity >=0.6.0 <0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";
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
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

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
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
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
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
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
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
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

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.7.6;

import {TimeLockedToken} from '../token/TimeLockedToken.sol';

/**
 * @title IRewardsDistributor
 * @author Babylon Finance
 *
 * Interface for the rewards distributor in charge of the BABL Mining Program.
 */

interface IRewardsDistributor {
    /* ========== View functions ========== */

    function getStrategyRewards(address _strategy) external view returns (uint256);

    function getRewards(
        address _garden,
        address _contributor,
        address[] calldata _finalizedStrategies
    ) external view returns (uint256[] memory);

    function getGardenProfitsSharing(address _garden) external view returns (uint256[3] memory);

    function checkMining(uint256 _quarterNum, address _strategy) external view returns (uint256[17] memory);

    function estimateUserRewards(address _strategy, address _contributor) external view returns (uint256[] memory);

    function estimateStrategyRewards(address _strategy) external view returns (uint256);

    function getPriorBalance(
        address _garden,
        address _contributor,
        uint256 _timestamp
    )
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    /* ============ External Functions ============ */

    function setProfitRewards(
        address _garden,
        uint256 _strategistShare,
        uint256 _stewardsShare,
        uint256 _lpShare
    ) external;

    function migrateAddressToCheckpoints(address[] memory _garden, bool _toMigrate) external;

    function setBABLMiningParameters(uint256[11] memory _newMiningParams) external;

    function updateProtocolPrincipal(uint256 _capital, bool _addOrSubstract) external;

    function updateGardenPowerAndContributor(
        address _garden,
        address _contributor,
        uint256 _previousBalance,
        uint256 _tokenDiff,
        bool _addOrSubstract
    ) external;

    function sendBABLToContributor(address _to, uint256 _babl) external returns (uint256);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.7.6;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {IERC1271} from '../interfaces/IERC1271.sol';

import {IBabController} from './IBabController.sol';

/**
 * @title IStrategyGarden
 *
 * Interface for functions of the garden
 */
interface IStrategyGarden {
    /* ============ Write ============ */

    function finalizeStrategy(
        uint256 _profits,
        int256 _returns,
        uint256 _burningAmount
    ) external;

    function allocateCapitalToStrategy(uint256 _capital) external;

    function expireCandidateStrategy(address _strategy) external;

    function addStrategy(
        string memory _name,
        string memory _symbol,
        uint256[] calldata _stratParams,
        uint8[] calldata _opTypes,
        address[] calldata _opIntegrations,
        bytes calldata _opEncodedDatas
    ) external;

    function updateStrategyRewards(
        address _strategy,
        uint256 _newTotalAmount,
        uint256 _newCapitalReturned
    ) external;

    function payKeeper(address payable _keeper, uint256 _fee) external;
}

/**
 * @title IAdminGarden
 *
 * Interface for amdin functions of the Garden
 */
interface IAdminGarden {
    /* ============ Write ============ */
    function initialize(
        address _reserveAsset,
        IBabController _controller,
        address _creator,
        string memory _name,
        string memory _symbol,
        uint256[] calldata _gardenParams,
        uint256 _initialContribution,
        bool[] memory _publicGardenStrategistsStewards
    ) external payable;

    function makeGardenPublic() external;

    function transferCreatorRights(address _newCreator, uint8 _index) external;

    function addExtraCreators(address[4] memory _newCreators) external;

    function setPublicRights(bool _publicStrategist, bool _publicStewards) external;

    function delegateVotes(address _token, address _address) external;

    function updateCreators(address _newCreator, address[4] memory _newCreators) external;

    function updateGardenParams(uint256[12] memory _newParams) external;

    function verifyGarden(uint256 _verifiedCategory) external;

    function resetHardlock(uint256 _hardlockStartsAt) external;
}

/**
 * @title IGarden
 *
 * Interface for operating with a Garden.
 */
interface ICoreGarden {
    /* ============ Constructor ============ */

    /* ============ View ============ */

    function privateGarden() external view returns (bool);

    function publicStrategists() external view returns (bool);

    function publicStewards() external view returns (bool);

    function controller() external view returns (IBabController);

    function creator() external view returns (address);

    function isGardenStrategy(address _strategy) external view returns (bool);

    function getContributor(address _contributor)
        external
        view
        returns (
            uint256 lastDepositAt,
            uint256 initialDepositAt,
            uint256 claimedAt,
            uint256 claimedBABL,
            uint256 claimedRewards,
            uint256 withdrawnSince,
            uint256 totalDeposits,
            uint256 nonce,
            uint256 lockedBalance
        );

    function reserveAsset() external view returns (address);

    function verifiedCategory() external view returns (uint256);

    function canMintNftAfter() external view returns (uint256);

    function hardlockStartsAt() external view returns (uint256);

    function totalContributors() external view returns (uint256);

    function gardenInitializedAt() external view returns (uint256);

    function minContribution() external view returns (uint256);

    function depositHardlock() external view returns (uint256);

    function minLiquidityAsset() external view returns (uint256);

    function minStrategyDuration() external view returns (uint256);

    function maxStrategyDuration() external view returns (uint256);

    function reserveAssetRewardsSetAside() external view returns (uint256);

    function absoluteReturns() external view returns (int256);

    function totalStake() external view returns (uint256);

    function minVotesQuorum() external view returns (uint256);

    function minVoters() external view returns (uint256);

    function maxDepositLimit() external view returns (uint256);

    function strategyCooldownPeriod() external view returns (uint256);

    function getStrategies() external view returns (address[] memory);

    function extraCreators(uint256 index) external view returns (address);

    function getFinalizedStrategies() external view returns (address[] memory);

    function strategyMapping(address _strategy) external view returns (bool);

    function keeperDebt() external view returns (uint256);

    function totalKeeperFees() external view returns (uint256);

    function lastPricePerShare() external view returns (uint256);

    function lastPricePerShareTS() external view returns (uint256);

    function pricePerShareDecayRate() external view returns (uint256);

    function pricePerShareDelta() external view returns (uint256);

    /* ============ Write ============ */

    function deposit(
        uint256 _amountIn,
        uint256 _minAmountOut,
        address _to,
        address _referrer
    ) external payable;

    function depositBySig(
        uint256 _amountIn,
        uint256 _minAmountOut,
        uint256 _nonce,
        uint256 _maxFee,
        address _to,
        uint256 _pricePerShare,
        uint256 _fee,
        address _signer,
        address _referrer,
        bytes memory signature
    ) external;

    function withdraw(
        uint256 _amountIn,
        uint256 _minAmountOut,
        address payable _to,
        bool _withPenalty,
        address _unwindStrategy
    ) external;

    function withdrawBySig(
        uint256 _amountIn,
        uint256 _minAmountOut,
        uint256 _nonce,
        uint256 _maxFee,
        bool _withPenalty,
        address _unwindStrategy,
        uint256 _pricePerShare,
        uint256 _strategyNAV,
        uint256 _fee,
        address _signer,
        bytes memory signature
    ) external;

    function claimReturns(address[] calldata _finalizedStrategies) external;

    function claimAndStakeReturns(uint256 _minAmountOut, address[] calldata _finalizedStrategies) external;

    function claimRewardsBySig(
        uint256 _babl,
        uint256 _profits,
        uint256 _nonce,
        uint256 _maxFee,
        uint256 _fee,
        address signer,
        bytes memory signature
    ) external;

    function claimAndStakeRewardsBySig(
        uint256 _babl,
        uint256 _profits,
        uint256 _minAmountOut,
        uint256 _nonce,
        uint256 _nonceHeart,
        uint256 _maxFee,
        uint256 _pricePerShare,
        uint256 _fee,
        address _signer,
        bytes memory _signature
    ) external;

    function stakeBySig(
        uint256 _amountIn,
        uint256 _profits,
        uint256 _minAmountOut,
        uint256 _nonce,
        uint256 _nonceHeart,
        uint256 _maxFee,
        address _to,
        uint256 _pricePerShare,
        address _signer,
        bytes memory _signature
    ) external;

    function claimNFT() external;
}

interface IERC20Metadata {
    function name() external view returns (string memory);
}

interface IGarden is ICoreGarden, IAdminGarden, IStrategyGarden, IERC20, IERC20Metadata, IERC1271 {
    struct Contributor {
        uint256 lastDepositAt;
        uint256 initialDepositAt;
        uint256 claimedAt;
        uint256 claimedBABL;
        uint256 claimedRewards;
        uint256 withdrawnSince;
        uint256 totalDeposits;
        uint256 nonce;
        uint256 lockedBalance;
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.7.6;

import {IIntegration} from './IIntegration.sol';

/**
 * @title IGardenFactory
 * @author Babylon Finance
 *
 * Interface for the garden factory
 */
interface IGardenFactory {
    function createGarden(
        address _reserveAsset,
        address _creator,
        string memory _name,
        string memory _symbol,
        string memory _tokenURI,
        uint256 _seed,
        uint256[] calldata _gardenParams,
        uint256 _initialContribution,
        bool[] memory _publicGardenStrategistsStewards
    ) external returns (address);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.7.6;

import {IGarden} from '../interfaces/IGarden.sol';

/**
 * @title IStrategy
 * @author Babylon Finance
 *
 * Interface for strategy
 */
interface IStrategy {
    function initialize(
        address _strategist,
        address _garden,
        address _controller,
        uint256 _maxCapitalRequested,
        uint256 _stake,
        uint256 _strategyDuration,
        uint256 _expectedReturn,
        uint256 _maxAllocationPercentage,
        uint256 _maxGasFeePercentage,
        uint256 _maxTradeSlippagePercentage
    ) external;

    function resolveVoting(
        address[] calldata _voters,
        int256[] calldata _votes,
        uint256 fee
    ) external;

    function updateParams(uint256[5] calldata _params) external;

    function sweep(address _token, uint256 _newSlippage) external;

    function updateStrategyRewards(uint256 _newTotalRewards, uint256 _newCapitalReturned) external;

    function setData(
        uint8[] calldata _opTypes,
        address[] calldata _opIntegrations,
        bytes memory _opEncodedData
    ) external;

    function executeStrategy(uint256 _capital, uint256 fee) external;

    function getNAV() external view returns (uint256);

    function opEncodedData() external view returns (bytes memory);

    function getOperationsCount() external view returns (uint256);

    function getOperationByIndex(uint8 _index)
        external
        view
        returns (
            uint8,
            address,
            bytes memory
        );

    function finalizeStrategy(
        uint256 fee,
        string memory _tokenURI,
        uint256 _minReserveOut
    ) external;

    function unwindStrategy(uint256 _amountToUnwind, uint256 _strategyNAV) external;

    function invokeFromIntegration(
        address _target,
        uint256 _value,
        bytes calldata _data
    ) external returns (bytes memory);

    function invokeApprove(
        address _spender,
        address _asset,
        uint256 _quantity
    ) external;

    function trade(
        address _sendToken,
        uint256 _sendQuantity,
        address _receiveToken
    ) external returns (uint256);

    function trade(
        address _sendToken,
        uint256 _sendQuantity,
        address _receiveToken,
        uint256 _overrideSlippage
    ) external returns (uint256);

    function handleWeth(bool _isDeposit, uint256 _wethAmount) external;

    function getStrategyDetails()
        external
        view
        returns (
            address,
            address,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            address,
            uint256,
            uint256
        );

    function getStrategyState()
        external
        view
        returns (
            address,
            bool,
            bool,
            bool,
            uint256,
            uint256,
            uint256
        );

    function getStrategyRewardsContext()
        external
        view
        returns (
            address,
            uint256[] memory,
            bool[] memory
        );

    function isStrategyActive() external view returns (bool);

    function getUserVotes(address _address) external view returns (int256);

    function strategist() external view returns (address);

    function enteredAt() external view returns (uint256);

    function enteredCooldownAt() external view returns (uint256);

    function stake() external view returns (uint256);

    function strategyRewards() external view returns (uint256);

    function maxCapitalRequested() external view returns (uint256);

    function maxAllocationPercentage() external view returns (uint256);

    function maxTradeSlippagePercentage() external view returns (uint256);

    function maxGasFeePercentage() external view returns (uint256);

    function expectedReturn() external view returns (uint256);

    function duration() external view returns (uint256);

    function totalPositiveVotes() external view returns (uint256);

    function totalNegativeVotes() external view returns (uint256);

    function capitalReturned() external view returns (uint256);

    function capitalAllocated() external view returns (uint256);

    function garden() external view returns (IGarden);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.7.6;

import {ITokenIdentifier} from './ITokenIdentifier.sol';

/**
 * @title IPriceOracle
 * @author Babylon Finance
 *
 * Interface for interacting with PriceOracle
 */
interface IPriceOracle {
    /* ============ Functions ============ */

    function getPrice(address _assetOne, address _assetTwo) external view returns (uint256);

    function getPriceNAV(address _assetOne, address _assetTwo) external view returns (uint256);

    function updateReserves(address[] memory list) external;

    function updateMaxTwapDeviation(int24 _maxTwapDeviation) external;

    function updateTokenIdentifier(ITokenIdentifier _tokenIdentifier) external;

    function getCompoundExchangeRate(address _asset, address _finalAsset) external view returns (uint256);

    function getCreamExchangeRate(address _asset, address _finalAsset) external view returns (uint256);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.7.6;

import {IBabylonGate} from './IBabylonGate.sol';

/**
 * @title IIshtarGate
 * @author Babylon Finance
 *
 * Interface for interacting with the Gate Guestlist NFT
 */
interface IIshtarGate is IBabylonGate {
    /* ============ Functions ============ */

    function tokenURI() external view returns (string memory);

    function updateGardenURI(string memory _tokenURI) external;
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.7.6;

/**
 * @title IIntegration
 * @author Babylon Finance
 *
 * Interface for protocol integrations
 */
interface IIntegration {
    function getName() external view returns (string memory);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.7.6;

/**
 * @title IBabController
 * @author Babylon Finance
 *
 * Interface for interacting with BabController
 */
interface IBabController {
    /* ============ Functions ============ */

    function createGarden(
        address _reserveAsset,
        string memory _name,
        string memory _symbol,
        string memory _tokenURI,
        uint256 _seed,
        uint256[] calldata _gardenParams,
        uint256 _initialContribution,
        bool[] memory _publicGardenStrategistsStewards,
        uint256[] memory _profitSharing
    ) external payable returns (address);

    function removeGarden(address _garden) external;

    function addReserveAsset(address _reserveAsset) external;

    function removeReserveAsset(address _reserveAsset) external;

    function updateProtocolWantedAsset(address _wantedAsset, bool _wanted) external;

    function updateGardenAffiliateRate(address _garden, uint256 _affiliateRate) external;

    function addAffiliateReward(
        address _depositor,
        address _referrer,
        uint256 _reserveAmount
    ) external;

    function claimRewards() external;

    function editPriceOracle(address _priceOracle) external;

    function editMardukGate(address _mardukGate) external;

    function editGardenValuer(address _gardenValuer) external;

    function editTreasury(address _newTreasury) external;

    function editHeart(address _newHeart) external;

    function editRewardsDistributor(address _rewardsDistributor) external;

    function editGardenFactory(address _newGardenFactory) external;

    function editGardenNFT(address _newGardenNFT) external;

    function editCurveMetaRegistry(address _curveMetaRegistry) external;

    function editStrategyNFT(address _newStrategyNFT) external;

    function editStrategyFactory(address _newStrategyFactory) external;

    function setOperation(uint8 _kind, address _operation) external;

    function setMasterSwapper(address _newMasterSwapper) external;

    function addKeeper(address _keeper) external;

    function addKeepers(address[] memory _keepers) external;

    function removeKeeper(address _keeper) external;

    function enableGardenTokensTransfers() external;

    function editLiquidityReserve(address _reserve, uint256 _minRiskyPairLiquidityEth) external;

    function patchIntegration(address _old, address _new) external;

    function gardenCreationIsOpen() external view returns (bool);

    function owner() external view returns (address);

    function EMERGENCY_OWNER() external view returns (address);

    function guardianGlobalPaused() external view returns (bool);

    function guardianPaused(address _address) external view returns (bool);

    function setPauseGuardian(address _guardian) external;

    function setGlobalPause(bool _state) external returns (bool);

    function setSomePause(address[] memory _address, bool _state) external returns (bool);

    function isPaused(address _contract) external view returns (bool);

    function priceOracle() external view returns (address);

    function gardenValuer() external view returns (address);

    function heart() external view returns (address);

    function gardenNFT() external view returns (address);

    function strategyNFT() external view returns (address);

    function curveMetaRegistry() external view returns (address);

    function rewardsDistributor() external view returns (address);

    function gardenFactory() external view returns (address);

    function treasury() external view returns (address);

    function ishtarGate() external view returns (address);

    function mardukGate() external view returns (address);

    function strategyFactory() external view returns (address);

    function masterSwapper() external view returns (address);

    function gardenTokensTransfersEnabled() external view returns (bool);

    function bablMiningProgramEnabled() external view returns (bool);

    function allowPublicGardens() external view returns (bool);

    function enabledOperations(uint256 _kind) external view returns (address);

    function getGardens() external view returns (address[] memory);

    function getReserveAssets() external view returns (address[] memory);

    function getOperations() external view returns (address[20] memory);

    function isGarden(address _garden) external view returns (bool);

    function protocolWantedAssets(address _wantedAsset) external view returns (bool);

    function gardenAffiliateRates(address _wantedAsset) external view returns (uint256);

    function affiliateRewards(address _user) external view returns (uint256);

    function patchedIntegrations(address _integration) external view returns (address);

    function isValidReserveAsset(address _reserveAsset) external view returns (bool);

    function isValidKeeper(address _keeper) external view returns (bool);

    function isSystemContract(address _contractAddress) external view returns (bool);

    function protocolPerformanceFee() external view returns (uint256);

    function protocolManagementFee() external view returns (uint256);

    function minLiquidityPerReserve(address _reserve) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.7.6;
pragma abicoder v2;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IHypervisor {
    // @param deposit0 Amount of token0 transfered from sender to Hypervisor
    // @param deposit1 Amount of token0 transfered from sender to Hypervisor
    // @param to Address to which liquidity tokens are minted
    // @return shares Quantity of liquidity tokens minted as a result of deposit
    function deposit(
        uint256 deposit0,
        uint256 deposit1,
        address to
    ) external returns (uint256);

    // @param shares Number of liquidity tokens to redeem as pool assets
    // @param to Address to which redeemed pool assets are sent
    // @param from Address from which liquidity tokens are sent
    // @return amount0 Amount of token0 redeemed by the submitted liquidity tokens
    // @return amount1 Amount of token1 redeemed by the submitted liquidity tokens
    function withdraw(
        uint256 shares,
        address to,
        address from
    ) external returns (uint256, uint256);

    function rebalance(
        int24 _baseLower,
        int24 _baseUpper,
        int24 _limitLower,
        int24 _limitUpper,
        address _feeRecipient,
        int256 swapQuantity
    ) external;

    function addBaseLiquidity(uint256 amount0, uint256 amount1) external;

    function addLimitLiquidity(uint256 amount0, uint256 amount1) external;

    function pullLiquidity(uint256 shares)
        external
        returns (
            uint256 base0,
            uint256 base1,
            uint256 limit0,
            uint256 limit1
        );

    function token0() external view returns (IERC20);

    function token1() external view returns (IERC20);

    function pool() external view returns (address);

    function balanceOf(address) external view returns (uint256);

    function approve(address, uint256) external returns (bool);

    function transferFrom(
        address,
        address,
        uint256
    ) external returns (bool);

    function transfer(address, uint256) external returns (bool);

    function getTotalAmounts() external view returns (uint256 total0, uint256 total1);

    function pendingFees() external returns (uint256 fees0, uint256 fees1);

    function totalSupply() external view returns (uint256);

    function setMaxTotalSupply(uint256 _maxTotalSupply) external;

    function setDepositMax(uint256 _deposit0Max, uint256 _deposit1Max) external;

    function appendList(address[] memory listed) external;

    function toggleWhitelist() external;

    function transferOwnership(address newOwner) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256 wad) external;
}

// SPDX-License-Identifier: Apache-2.0

/*
    Copyright 2020 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/

pragma solidity 0.7.6;

/**
 * @title AddressArrayUtils
 * @author Set Protocol
 *
 * Utility functions to handle Address Arrays
 */
library AddressArrayUtils {
    /**
     * Finds the index of the first occurrence of the given element.
     * @param A The input array to search
     * @param a The value to find
     * @return Returns (index and isIn) for the first occurrence starting from index 0
     */
    function indexOf(address[] memory A, address a) internal pure returns (uint256, bool) {
        uint256 length = A.length;
        for (uint256 i = 0; i < length; i++) {
            if (A[i] == a) {
                return (i, true);
            }
        }
        return (uint256(-1), false);
    }

    /**
     * Returns true if the value is present in the list. Uses indexOf internally.
     * @param A The input array to search
     * @param a The value to find
     * @return Returns isIn for the first occurrence starting from index 0
     */
    function contains(address[] memory A, address a) internal pure returns (bool) {
        (, bool isIn) = indexOf(A, a);
        return isIn;
    }

    /**
     * Returns true if there are 2 elements that are the same in an array
     * @param A The input array to search
     * @return Returns boolean for the first occurrence of a duplicate
     */
    function hasDuplicate(address[] memory A) internal pure returns (bool) {
        require(A.length > 0, 'A is empty');

        for (uint256 i = 0; i < A.length - 1; i++) {
            address current = A[i];
            for (uint256 j = i + 1; j < A.length; j++) {
                if (current == A[j]) {
                    return true;
                }
            }
        }
        return false;
    }

    /**
     * @param A The input array to search
     * @param a The address to remove
     * @return Returns the array with the object removed.
     */
    function remove(address[] memory A, address a) internal pure returns (address[] memory) {
        (uint256 index, bool isIn) = indexOf(A, a);
        if (!isIn) {
            revert('Address not in array.');
        } else {
            (address[] memory _A, ) = pop(A, index);
            return _A;
        }
    }

    /**
     * Removes specified index from array
     * @param A The input array to search
     * @param index The index to remove
     * @return Returns the new array and the removed entry
     */
    function pop(address[] memory A, uint256 index) internal pure returns (address[] memory, address) {
        uint256 length = A.length;
        require(index < A.length, 'Index must be < A length');
        address[] memory newAddresses = new address[](length - 1);
        for (uint256 i = 0; i < index; i++) {
            newAddresses[i] = A[i];
        }
        for (uint256 j = index + 1; j < length; j++) {
            newAddresses[j - 1] = A[j];
        }
        return (newAddresses, A[index]);
    }

    /**
     * Returns the combination of the two arrays
     * @param A The first array
     * @param B The second array
     * @return Returns A extended by B
     */
    function extend(address[] memory A, address[] memory B) internal pure returns (address[] memory) {
        uint256 aLength = A.length;
        uint256 bLength = B.length;
        address[] memory newAddresses = new address[](aLength + bLength);
        for (uint256 i = 0; i < aLength; i++) {
            newAddresses[i] = A[i];
        }
        for (uint256 j = 0; j < bLength; j++) {
            newAddresses[aLength + j] = B[j];
        }
        return newAddresses;
    }

    /*
      Unfortunately Solidity does not support convertion of the fixed array to dynamic array so these functions are
      required. This functionality would be supported in the future so these methods can be removed.
    */
    function toDynamic(address _one, address _two) internal pure returns (address[] memory) {
        address[] memory arr = new address[](2);
        arr[0] = _one;
        arr[1] = _two;
        return arr;
    }

    function toDynamic(
        address _one,
        address _two,
        address _three
    ) internal pure returns (address[] memory) {
        address[] memory arr = new address[](3);
        arr[0] = _one;
        arr[1] = _two;
        arr[2] = _three;
        return arr;
    }

    function toDynamic(
        address _one,
        address _two,
        address _three,
        address _four
    ) internal pure returns (address[] memory) {
        address[] memory arr = new address[](4);
        arr[0] = _one;
        arr[1] = _two;
        arr[2] = _three;
        arr[3] = _four;
        return arr;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity 0.7.6;

/// @title Optimized overflow and underflow safe math operations
/// @notice Contains methods for doing math operations that revert on overflow or underflow for minimal gas cost
library LowGasSafeMath {
    /// @notice Returns x + y, reverts if sum overflows uint256
    /// @param x The augend
    /// @param y The addend
    /// @return z The sum of x and y
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x);
    }

    /// @notice Returns x - y, reverts if underflows
    /// @param x The minuend
    /// @param y The subtrahend
    /// @return z The difference of x and y
    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x);
    }

    /// @notice Returns x * y, reverts if overflows
    /// @param x The multiplicand
    /// @param y The multiplier
    /// @return z The product of x and y
    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(x == 0 || (z = x * y) / x == y);
    }

    /// @notice Returns x + y, reverts if overflows or underflows
    /// @param x The augend
    /// @param y The addend
    /// @return z The sum of x and y
    function add(int256 x, int256 y) internal pure returns (int256 z) {
        require((z = x + y) >= x == (y >= 0));
    }

    /// @notice Returns x - y, reverts if overflows or underflows
    /// @param x The minuend
    /// @param y The subtrahend
    /// @return z The difference of x and y
    function sub(int256 x, int256 y) internal pure returns (int256 z) {
        require((z = x - y) <= x == (y >= 0));
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, 'SafeMath: division by zero');
        return a / b;
    }
}

// SPDX-License-Identifier: Apache-2.0

/*
    Copyright 2020 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/

pragma solidity 0.7.6;

import {SignedSafeMath} from '@openzeppelin/contracts/math/SignedSafeMath.sol';

import {LowGasSafeMath} from './LowGasSafeMath.sol';

/**
 * @title PreciseUnitMath
 * @author Set Protocol
 *
 * Arithmetic for fixed-point numbers with 18 decimals of precision. Some functions taken from
 * dYdX's BaseMath library.
 *
 * CHANGELOG:
 * - 9/21/20: Added safePower function
 */
library PreciseUnitMath {
    using LowGasSafeMath for uint256;
    using SignedSafeMath for int256;

    // The number One in precise units.
    uint256 internal constant PRECISE_UNIT = 10**18;
    int256 internal constant PRECISE_UNIT_INT = 10**18;

    // Max unsigned integer value
    uint256 internal constant MAX_UINT_256 = type(uint256).max;
    // Max and min signed integer value
    int256 internal constant MAX_INT_256 = type(int256).max;
    int256 internal constant MIN_INT_256 = type(int256).min;

    /**
     * @dev Getter function since constants can't be read directly from libraries.
     */
    function decimals() internal pure returns (uint256) {
        return 18;
    }

    /**
     * @dev Getter function since constants can't be read directly from libraries.
     */
    function preciseUnit() internal pure returns (uint256) {
        return PRECISE_UNIT;
    }

    /**
     * @dev Getter function since constants can't be read directly from libraries.
     */
    function preciseUnitInt() internal pure returns (int256) {
        return PRECISE_UNIT_INT;
    }

    /**
     * @dev Getter function since constants can't be read directly from libraries.
     */
    function maxUint256() internal pure returns (uint256) {
        return MAX_UINT_256;
    }

    /**
     * @dev Getter function since constants can't be read directly from libraries.
     */
    function maxInt256() internal pure returns (int256) {
        return MAX_INT_256;
    }

    /**
     * @dev Getter function since constants can't be read directly from libraries.
     */
    function minInt256() internal pure returns (int256) {
        return MIN_INT_256;
    }

    /**
     * @dev Multiplies value a by value b (result is rounded down). It's assumed that the value b is the significand
     * of a number with 18 decimals precision.
     */
    function preciseMul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a.mul(b).div(PRECISE_UNIT);
    }

    /**
     * @dev Multiplies value a by value b (result is rounded towards zero). It's assumed that the value b is the
     * significand of a number with 18 decimals precision.
     */
    function preciseMul(int256 a, int256 b) internal pure returns (int256) {
        return a.mul(b).div(PRECISE_UNIT_INT);
    }

    /**
     * @dev Multiplies value a by value b (result is rounded up). It's assumed that the value b is the significand
     * of a number with 18 decimals precision.
     */
    function preciseMulCeil(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0 || b == 0) {
            return 0;
        }
        return a.mul(b).sub(1).div(PRECISE_UNIT).add(1);
    }

    /**
     * @dev Divides value a by value b (result is rounded down).
     */
    function preciseDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        return a.mul(PRECISE_UNIT).div(b);
    }

    /**
     * @dev Divides value a by value b (result is rounded towards 0).
     */
    function preciseDiv(int256 a, int256 b) internal pure returns (int256) {
        return a.mul(PRECISE_UNIT_INT).div(b);
    }

    /**
     * @dev Divides value a by value b (result is rounded up or away from 0).
     */
    function preciseDivCeil(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, 'Cant divide by 0');

        return a > 0 ? a.mul(PRECISE_UNIT).sub(1).div(b).add(1) : 0;
    }

    /**
     * @dev Divides value a by value b (result is rounded down - positive numbers toward 0 and negative away from 0).
     */
    function divDown(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, 'Cant divide by 0');
        require(a != MIN_INT_256 || b != -1, 'Invalid input');

        int256 result = a.div(b);
        if (a ^ b < 0 && a % b != 0) {
            result -= 1;
        }

        return result;
    }

    /**
     * @dev Multiplies value a by value b where rounding is towards the lesser number.
     * (positive values are rounded towards zero and negative values are rounded away from 0).
     */
    function conservativePreciseMul(int256 a, int256 b) internal pure returns (int256) {
        return divDown(a.mul(b), PRECISE_UNIT_INT);
    }

    /**
     * @dev Divides value a by value b where rounding is towards the lesser number.
     * (positive values are rounded towards zero and negative values are rounded away from 0).
     */
    function conservativePreciseDiv(int256 a, int256 b) internal pure returns (int256) {
        return divDown(a.mul(PRECISE_UNIT_INT), b);
    }

    /**
     * @dev Performs the power on a specified value, reverts on overflow.
     */
    function safePower(uint256 a, uint256 pow) internal pure returns (uint256) {
        require(a > 0, 'Value must be positive');

        uint256 result = 1;
        for (uint256 i = 0; i < pow; i++) {
            uint256 previousResult = result;

            // Using safemath multiplication prevents overflows
            result = previousResult.mul(a);
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
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
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

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

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.7.6;

import {IBabController} from '../interfaces/IBabController.sol';
import {TimeLockRegistry} from './TimeLockRegistry.sol';
import {IRewardsDistributor} from '../interfaces/IRewardsDistributor.sol';
import {VoteToken} from './VoteToken.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {Errors, _require} from '../lib/BabylonErrors.sol';
import {LowGasSafeMath} from '../lib/LowGasSafeMath.sol';
import {IBabController} from '../interfaces/IBabController.sol';

/**
 * @title TimeLockedToken
 * @notice Time Locked ERC20 Token
 * @author Babylon Finance
 * @dev Contract which gives the ability to time-lock tokens specially for vesting purposes usage
 *
 * By overriding the balanceOf() and transfer() functions in ERC20,
 * an account can show its full, post-distribution balance and use it for voting power
 * but only transfer or spend up to an allowed amount
 *
 * A portion of previously non-spendable tokens are allowed to be transferred
 * along the time depending on each vesting conditions, and after all epochs have passed, the full
 * account balance is unlocked. In case on non-completion vesting period, only the Time Lock Registry can cancel
 * the delivery of the pending tokens and only can cancel the remaining locked ones.
 */

abstract contract TimeLockedToken is VoteToken {
    using LowGasSafeMath for uint256;

    /* ============ Events ============ */

    /// @notice An event that emitted when a new lockout ocurr
    event NewLockout(
        address account,
        uint256 tokenslocked,
        bool isTeamOrAdvisor,
        uint256 startingVesting,
        uint256 endingVesting
    );

    /// @notice An event that emitted when a new Time Lock is registered
    event NewTimeLockRegistration(address previousAddress, address newAddress);

    /// @notice An event that emitted when a new Rewards Distributor is registered
    event NewRewardsDistributorRegistration(address previousAddress, address newAddress);

    /// @notice An event that emitted when a cancellation of Lock tokens is registered
    event Cancel(address account, uint256 amount);

    /// @notice An event that emitted when a claim of tokens are registered
    event Claim(address _receiver, uint256 amount);

    /// @notice An event that emitted when a lockedBalance query is done
    event LockedBalance(address _account, uint256 amount);

    /* ============ Modifiers ============ */

    modifier onlyTimeLockRegistry() {
        require(
            msg.sender == address(timeLockRegistry),
            'TimeLockedToken:: onlyTimeLockRegistry: can only be executed by TimeLockRegistry'
        );
        _;
    }

    modifier onlyTimeLockOwner() {
        if (address(timeLockRegistry) != address(0)) {
            require(
                msg.sender == Ownable(timeLockRegistry).owner(),
                'TimeLockedToken:: onlyTimeLockOwner: can only be executed by the owner of TimeLockRegistry'
            );
        }
        _;
    }
    modifier onlyUnpaused() {
        // Do not execute if Globally or individually paused
        _require(!IBabController(controller).isPaused(address(this)), Errors.ONLY_UNPAUSED);
        _;
    }

    /* ============ State Variables ============ */

    // represents total distribution for locked balances
    mapping(address => uint256) distribution;

    /// @notice The profile of each token owner under its particular vesting conditions
    /**
     * @param team Indicates whether or not is a Team member or Advisor (true = team member/advisor, false = private investor)
     * @param vestingBegin When the vesting begins for such token owner
     * @param vestingEnd When the vesting ends for such token owner
     * @param lastClaim When the last claim was done
     */
    struct VestedToken {
        bool teamOrAdvisor;
        uint256 vestingBegin;
        uint256 vestingEnd;
        uint256 lastClaim;
    }

    /// @notice A record of token owners under vesting conditions for each account, by index
    mapping(address => VestedToken) public vestedToken;

    // address of Time Lock Registry contract
    IBabController public controller;

    // address of Time Lock Registry contract
    TimeLockRegistry public timeLockRegistry;

    // address of Rewards Distriburor contract
    IRewardsDistributor public rewardsDistributor;

    // Enable Transfer of ERC20 BABL Tokens
    // Only Minting or transfers from/to TimeLockRegistry and Rewards Distributor can transfer tokens until the protocol is fully decentralized
    bool private tokenTransfersEnabled;
    bool private tokenTransfersWereDisabled;

    /* ============ Functions ============ */

    /* ============ Constructor ============ */

    constructor(string memory _name, string memory _symbol) VoteToken(_name, _symbol) {
        tokenTransfersEnabled = true;
    }

    /* ============ External Functions ============ */

    /* ===========  Token related Gov Functions ====== */

    /**
     * PRIVILEGED GOVERNANCE FUNCTION. Disables transfers of ERC20 BABL Tokens
     */
    function disableTokensTransfers() external onlyOwner {
        require(!tokenTransfersWereDisabled, 'BABL must flow');
        tokenTransfersEnabled = false;
        tokenTransfersWereDisabled = true;
    }

    /**
     * PRIVILEGED GOVERNANCE FUNCTION. Allows transfers of ERC20 BABL Tokens
     * Can only happen after the protocol is fully decentralized.
     */
    function enableTokensTransfers() external onlyOwner {
        tokenTransfersEnabled = true;
    }

    /**
     * PRIVILEGED GOVERNANCE FUNCTION. Set the Time Lock Registry contract to control token vesting conditions
     *
     * @notice Set the Time Lock Registry contract to control token vesting conditions
     * @param newTimeLockRegistry Address of TimeLockRegistry contract
     */
    function setTimeLockRegistry(TimeLockRegistry newTimeLockRegistry) external onlyTimeLockOwner returns (bool) {
        require(address(newTimeLockRegistry) != address(0), 'cannot be zero address');
        require(address(newTimeLockRegistry) != address(this), 'cannot be this contract');
        require(address(newTimeLockRegistry) != address(timeLockRegistry), 'must be new TimeLockRegistry');
        emit NewTimeLockRegistration(address(timeLockRegistry), address(newTimeLockRegistry));

        timeLockRegistry = newTimeLockRegistry;

        return true;
    }

    /**
     * PRIVILEGED GOVERNANCE FUNCTION. Set the Rewards Distributor contract to control either BABL Mining or profit rewards
     *
     * @notice Set the Rewards Distriburor contract to control both types of rewards (profit and BABL Mining program)
     * @param newRewardsDistributor Address of Rewards Distributor contract
     */
    function setRewardsDistributor(IRewardsDistributor newRewardsDistributor) external onlyOwner returns (bool) {
        require(address(newRewardsDistributor) != address(0), 'cannot be zero address');
        require(address(newRewardsDistributor) != address(this), 'cannot be this contract');
        require(address(newRewardsDistributor) != address(rewardsDistributor), 'must be new Rewards Distributor');
        emit NewRewardsDistributorRegistration(address(rewardsDistributor), address(newRewardsDistributor));

        rewardsDistributor = newRewardsDistributor;

        return true;
    }

    /**
     * PRIVILEGED GOVERNANCE FUNCTION. Register new token lockup conditions for vested tokens defined only by Time Lock Registry
     *
     * @notice Tokens are completely delivered during the registration however lockup conditions apply for vested tokens
     * locking them according to the distribution epoch periods and the type of recipient (Team, Advisor, Investor)
     * Emits a transfer event showing a transfer to the recipient
     * Only the registry can call this function
     * @param _receiver Address to receive the tokens
     * @param _amount Tokens to be transferred
     * @param _profile True if is a Team Member or Advisor
     * @param _vestingBegin Unix Time when the vesting for that particular address
     * @param _vestingEnd Unix Time when the vesting for that particular address
     * @param _lastClaim Unix Time when the claim was done from that particular address
     *
     */
    function registerLockup(
        address _receiver,
        uint256 _amount,
        bool _profile,
        uint256 _vestingBegin,
        uint256 _vestingEnd,
        uint256 _lastClaim
    ) external onlyTimeLockRegistry returns (bool) {
        require(balanceOf(msg.sender) >= _amount, 'insufficient balance');
        require(_receiver != address(0), 'cannot be zero address');
        require(_receiver != address(this), 'cannot be this contract');
        require(_receiver != address(timeLockRegistry), 'cannot be the TimeLockRegistry contract itself');
        require(_receiver != msg.sender, 'the owner cannot lockup itself');

        // update amount of locked distribution
        distribution[_receiver] = distribution[_receiver].add(_amount);

        VestedToken storage newVestedToken = vestedToken[_receiver];

        newVestedToken.teamOrAdvisor = _profile;
        newVestedToken.vestingBegin = _vestingBegin;
        newVestedToken.vestingEnd = _vestingEnd;
        newVestedToken.lastClaim = _lastClaim;

        // transfer tokens to the recipient
        _transfer(msg.sender, _receiver, _amount);
        emit NewLockout(_receiver, _amount, _profile, _vestingBegin, _vestingEnd);

        return true;
    }

    /**
     * PRIVILEGED GOVERNANCE FUNCTION. Cancel and remove locked tokens due to non-completion of vesting period
     * applied only by Time Lock Registry and specifically to Team or Advisors as it does not apply to investors.
     *
     * @dev Cancel distribution registration
     * @param lockedAccount that should have its still locked distribution removed due to non-completion of its vesting period
     */
    function cancelVestedTokens(address lockedAccount) external onlyTimeLockRegistry returns (uint256) {
        return _cancelVestedTokensFromTimeLock(lockedAccount);
    }

    /**
     * GOVERNANCE FUNCTION. Each token owner can claim its own specific tokens with its own specific vesting conditions from the Time Lock Registry
     *
     * @dev Claim msg.sender tokens (if any available in the registry)
     */
    function claimMyTokens() external {
        // claim msg.sender tokens from timeLockRegistry
        uint256 amount = timeLockRegistry.claim(msg.sender);
        // After a proper claim, locked tokens of Team and Advisors profiles are under restricted special vesting conditions so they automatic grant
        // rights to the Time Lock Registry to only retire locked tokens if non-compliance vesting conditions take places along the vesting periods.
        // It does not apply to Investors under vesting (their locked tokens cannot be removed).
        if (vestedToken[msg.sender].teamOrAdvisor == true) {
            approve(address(timeLockRegistry), amount);
        }
        // emit claim event
        emit Claim(msg.sender, amount);
    }

    /**
     * GOVERNANCE FUNCTION. Get unlocked balance for an account
     *
     * @notice Get unlocked balance for an account
     * @param account Account to check
     * @return Amount that is unlocked and available eg. to transfer
     */
    function unlockedBalance(address account) public returns (uint256) {
        // totalBalance - lockedBalance
        return balanceOf(account).sub(lockedBalance(account));
    }

    /**
     * GOVERNANCE FUNCTION. View the locked balance for an account
     *
     * @notice View locked balance for an account
     * @param account Account to check
     * @return Amount locked in the time of checking
     */

    function viewLockedBalance(address account) public view returns (uint256) {
        // distribution of locked tokens
        // get amount from distributions

        uint256 amount = distribution[account];
        uint256 lockedAmount = amount;

        // Team and investors cannot transfer tokens in the first year
        if (vestedToken[account].vestingBegin.add(365 days) > block.timestamp && amount != 0) {
            return lockedAmount;
        }

        // in case of vesting has passed, all tokens are now available, if no vesting lock is 0 as well
        if (block.timestamp >= vestedToken[account].vestingEnd || amount == 0) {
            lockedAmount = 0;
        } else if (amount != 0) {
            // in case of still under vesting period, locked tokens are recalculated
            lockedAmount = amount.mul(vestedToken[account].vestingEnd.sub(block.timestamp)).div(
                vestedToken[account].vestingEnd.sub(vestedToken[account].vestingBegin)
            );
        }
        return lockedAmount;
    }

    /**
     * GOVERNANCE FUNCTION. Get locked balance for an account
     *
     * @notice Get locked balance for an account
     * @param account Account to check
     * @return Amount locked in the time of checking
     */
    function lockedBalance(address account) public returns (uint256) {
        // get amount from distributions locked tokens (if any)
        uint256 lockedAmount = viewLockedBalance(account);
        // in case of vesting has passed, all tokens are now available so we set mapping to 0 only for accounts under vesting
        if (
            block.timestamp >= vestedToken[account].vestingEnd &&
            msg.sender == account &&
            lockedAmount == 0 &&
            vestedToken[account].vestingEnd != 0
        ) {
            delete distribution[account];
        }
        emit LockedBalance(account, lockedAmount);
        return lockedAmount;
    }

    /**
     * PUBLIC FUNCTION. Get the address of Time Lock Registry
     *
     * @notice Get the address of Time Lock Registry
     * @return Address of the Time Lock Registry
     */
    function getTimeLockRegistry() external view returns (address) {
        return address(timeLockRegistry);
    }

    /**
     * PRIVILEGED GOVERNANCE FUNCTION. Override the Approval of allowances of ERC20 with special conditions for vesting
     *
     * @notice Override of "Approve" function to allow the `spender` to transfer up to `amount` from `src`
     * @dev This will overwrite the approval amount for `spender` except in the case of spender is Time Lock Registry
     * and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
     * @param spender The address of the account which may transfer tokens
     * @param rawAmount The number of tokens that are approved (2^256-1 means infinite)
     * @return Whether or not the approval succeeded
     */
    function approve(address spender, uint256 rawAmount) public override nonReentrant returns (bool) {
        require(spender != address(0), 'TimeLockedToken::approve: spender cannot be zero address');
        require(spender != msg.sender, 'TimeLockedToken::approve: spender cannot be the msg.sender');

        uint96 amount;
        if (rawAmount == uint256(-1)) {
            amount = uint96(-1);
        } else {
            amount = safe96(rawAmount, 'TimeLockedToken::approve: amount exceeds 96 bits');
        }

        // There is no option to decreaseAllowance to timeLockRegistry in case of vested tokens
        if ((spender == address(timeLockRegistry)) && (amount < allowance(msg.sender, address(timeLockRegistry)))) {
            amount = safe96(
                allowance(msg.sender, address(timeLockRegistry)),
                'TimeLockedToken::approve: cannot decrease allowance to timelockregistry'
            );
        }
        _approve(msg.sender, spender, amount);
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /**
     * PRIVILEGED GOVERNANCE FUNCTION. Override the Increase of allowances of ERC20 with special conditions for vesting
     *
     * @notice Atomically increases the allowance granted to `spender` by the caller.
     *
     * @dev This is an override with respect to the fulfillment of vesting conditions along the way
     * However an user can increase allowance many times, it will never be able to transfer locked tokens during vesting period
     * @return Whether or not the increaseAllowance succeeded
     */
    function increaseAllowance(address spender, uint256 addedValue) public override nonReentrant returns (bool) {
        require(
            unlockedBalance(msg.sender) >= allowance(msg.sender, spender).add(addedValue) ||
                spender == address(timeLockRegistry),
            'TimeLockedToken::increaseAllowance:Not enough unlocked tokens'
        );
        require(spender != address(0), 'TimeLockedToken::increaseAllowance:Spender cannot be zero address');
        require(spender != msg.sender, 'TimeLockedToken::increaseAllowance:Spender cannot be the msg.sender');
        _approve(msg.sender, spender, allowance(msg.sender, spender).add(addedValue));
        return true;
    }

    /**
     * PRIVILEGED GOVERNANCE FUNCTION. Override the decrease of allowances of ERC20 with special conditions for vesting
     *
     * @notice Atomically decrease the allowance granted to `spender` by the caller.
     *
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     * This is an override with respect to the fulfillment of vesting conditions along the way
     * An user cannot decrease the allowance to the Time Lock Registry who is in charge of vesting conditions
     * @return Whether or not the decreaseAllowance succeeded
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public override nonReentrant returns (bool) {
        require(spender != address(0), 'TimeLockedToken::decreaseAllowance:Spender cannot be zero address');
        require(spender != msg.sender, 'TimeLockedToken::decreaseAllowance:Spender cannot be the msg.sender');
        require(
            allowance(msg.sender, spender) >= subtractedValue,
            'TimeLockedToken::decreaseAllowance:Underflow condition'
        );

        // There is no option to decreaseAllowance to timeLockRegistry in case of vested tokens
        require(
            address(spender) != address(timeLockRegistry),
            'TimeLockedToken::decreaseAllowance:cannot decrease allowance to timeLockRegistry'
        );

        _approve(msg.sender, spender, allowance(msg.sender, spender).sub(subtractedValue));
        return true;
    }

    /* ============ Internal Only Function ============ */

    /**
     * PRIVILEGED GOVERNANCE FUNCTION. Override the _transfer of ERC20 BABL tokens only allowing the transfer of unlocked tokens
     *
     * @dev Transfer function which includes only unlocked tokens
     * Locked tokens can always be transfered back to the returns address
     * Transferring to owner allows re-issuance of funds through registry
     *
     * @param _from The address to send tokens from
     * @param _to The address that will receive the tokens
     * @param _value The amount of tokens to be transferred
     */
    function _transfer(
        address _from,
        address _to,
        uint256 _value
    ) internal override onlyUnpaused {
        require(_from != address(0), 'TimeLockedToken:: _transfer: cannot transfer from the zero address');
        require(_to != address(0), 'TimeLockedToken:: _transfer: cannot transfer to the zero address');
        require(
            _to != address(this),
            'TimeLockedToken:: _transfer: do not transfer tokens to the token contract itself'
        );

        require(balanceOf(_from) >= _value, 'TimeLockedToken:: _transfer: insufficient balance');

        // check if enough unlocked balance to transfer
        require(unlockedBalance(_from) >= _value, 'TimeLockedToken:: _transfer: attempting to transfer locked funds');
        super._transfer(_from, _to, _value);
        // voting power
        _moveDelegates(
            delegates[_from],
            delegates[_to],
            safe96(_value, 'TimeLockedToken:: _transfer: uint96 overflow')
        );
    }

    /**
     * PRIVILEGED GOVERNANCE FUNCTION. Disable BABL token transfer until certain conditions are met
     *
     * @dev Override the _beforeTokenTransfer of ERC20 BABL tokens until certain conditions are met:
     * Only allowing minting or transfers from Time Lock Registry and Rewards Distributor until transfers are allowed in the controller
     * Transferring to owner allows re-issuance of funds through registry
     *
     * @param _from The address to send tokens from
     * @param _to The address that will receive the tokens
     * @param _value The amount of tokens to be transferred
     */

    // Disable garden token transfers. Allow minting and burning.
    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _value
    ) internal virtual override {
        super._beforeTokenTransfer(_from, _to, _value);
        _require(
            _from == address(0) ||
                _from == address(timeLockRegistry) ||
                _from == address(rewardsDistributor) ||
                _to == address(timeLockRegistry) ||
                tokenTransfersEnabled,
            Errors.BABL_TRANSFERS_DISABLED
        );
    }

    /**
     * PRIVILEGED GOVERNANCE FUNCTION. Cancel and remove locked tokens due to non-completion of  vesting period
     * applied only by Time Lock Registry and specifically to Team or Advisors
     *
     * @dev Cancel distribution registration
     * @param lockedAccount that should have its still locked distribution removed due to non-completion of its vesting period
     */
    function _cancelVestedTokensFromTimeLock(address lockedAccount) internal onlyTimeLockRegistry returns (uint256) {
        require(distribution[lockedAccount] != 0, 'TimeLockedToken::cancelTokens:Not registered');

        // get an update on locked amount from distributions at this precise moment
        uint256 loosingAmount = lockedBalance(lockedAccount);

        require(loosingAmount > 0, 'TimeLockedToken::cancelTokens:There are no more locked tokens');
        require(
            vestedToken[lockedAccount].teamOrAdvisor == true,
            'TimeLockedToken::cancelTokens:cannot cancel locked tokens to Investors'
        );

        // set distribution mapping to 0
        delete distribution[lockedAccount];

        // set tokenVested mapping to 0
        delete vestedToken[lockedAccount];

        // transfer only locked tokens back to TimeLockRegistry Owner (msg.sender)
        require(
            transferFrom(lockedAccount, address(timeLockRegistry), loosingAmount),
            'TimeLockedToken::cancelTokens:Transfer failed'
        );

        // emit cancel event
        emit Cancel(lockedAccount, loosingAmount);

        return loosingAmount;
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {Address} from '@openzeppelin/contracts/utils/Address.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import {TimeLockedToken} from './TimeLockedToken.sol';
import {AddressArrayUtils} from '../lib/AddressArrayUtils.sol';

import {LowGasSafeMath} from '../lib/LowGasSafeMath.sol';

/**
 * @title TimeLockRegistry
 * @notice Register Lockups for TimeLocked ERC20 Token BABL (e.g. vesting)
 * @author Babylon Finance
 * @dev This contract allows owner to register distributions for a TimeLockedToken
 *
 * To register a distribution, register method should be called by the owner.
 * claim() should be called only by the BABL Token smartcontract (modifier onlyBABLToken)
 *  when any account registered to receive tokens make its own claim
 * If case of a mistake, owner can cancel registration before the claim is done by the account
 *
 * Note this contract address must be setup in the TimeLockedToken's contract pointing
 * to interact with (e.g. setTimeLockRegistry() function)
 */

contract TimeLockRegistry is Ownable {
    using LowGasSafeMath for uint256;
    using Address for address;
    using AddressArrayUtils for address[];

    /* ============ Events ============ */

    event Register(address receiver, uint256 distribution);
    event Cancel(address receiver, uint256 distribution);
    event Claim(address account, uint256 distribution);

    /* ============ Modifiers ============ */

    modifier onlyBABLToken() {
        require(msg.sender == address(token), 'only BABL Token');
        _;
    }

    /* ============ State Variables ============ */

    // time locked token
    TimeLockedToken public token;

    /**
     * @notice The profile of each token owner under vesting conditions and its special conditions
     * @param receiver Account being registered
     * @param investorType Indicates whether or not is a Team member (true = team member / advisor, false = private investor)
     * @param vestingStarting Date When the vesting begins for such token owner
     * @param distribution Tokens amount that receiver is due to get
     */
    struct Registration {
        address receiver;
        uint256 distribution;
        bool investorType;
        uint256 vestingStartingDate;
    }

    /**
     * @notice The profile of each token owner under vesting conditions and its special conditions
     * @param team Indicates whether or not is a Team member (true = team member / advisor, false = private investor)
     * @param vestingBegin When the vesting begins for such token owner
     * @param vestingEnd When the vesting ends for such token owner
     * @param lastClaim When the last claim was done
     */
    struct TokenVested {
        bool team;
        bool cliff;
        uint256 vestingBegin;
        uint256 vestingEnd;
        uint256 lastClaim;
    }

    /// @notice A record of token owners under vesting conditions for each account, by index
    mapping(address => TokenVested) public tokenVested;

    // mapping from token owners under vesting conditions to BABL due amount (e.g. SAFT addresses, team members, advisors)
    mapping(address => uint256) public registeredDistributions;

    // array of all registrations
    address[] public registrations;

    // total amount of tokens registered
    uint256 public totalTokens;

    // vesting for Team Members
    uint256 private constant teamVesting = 365 days * 4;

    // vesting for Investors and Advisors
    uint256 private constant investorVesting = 365 days * 3;

    /* ============ Functions ============ */

    /* ============ Constructor ============ */

    /**
     * @notice Construct a new Time Lock Registry and gives ownership to sender
     * @param _token TimeLockedToken contract to use in this registry
     */
    constructor(TimeLockedToken _token) {
        token = _token;
    }

    /* ============ External Functions ============ */

    /* ============ External Getter Functions ============ */

    /**
     * Gets registrations
     *
     * @return  address[]        Returns list of registrations
     */

    function getRegistrations() external view returns (address[] memory) {
        return registrations;
    }

    /* ===========  Token related Gov Functions ====== */

    /**
     * PRIVILEGED GOVERNANCE FUNCTION
     *
     * @notice Register multiple investors/team in a batch
     * @param _registrations Registrations to process
     */
    function registerBatch(Registration[] memory _registrations) external onlyOwner {
        for (uint256 i = 0; i < _registrations.length; i++) {
            register(
                _registrations[i].receiver,
                _registrations[i].distribution,
                _registrations[i].investorType,
                _registrations[i].vestingStartingDate
            );
        }
    }

    /**
     * PRIVILEGED GOVERNANCE FUNCTION
     *
     * @notice Register new account under vesting conditions (Team, Advisors, Investors e.g. SAFT purchaser)
     * @param receiver Address belonging vesting conditions
     * @param distribution Tokens amount that receiver is due to get
     */
    function register(
        address receiver,
        uint256 distribution,
        bool investorType,
        uint256 vestingStartingDate
    ) public onlyOwner {
        require(receiver != address(0), 'TimeLockRegistry::register: cannot register the zero address');
        require(
            receiver != address(this),
            'TimeLockRegistry::register: Time Lock Registry contract cannot be an investor'
        );
        require(distribution != 0, 'TimeLockRegistry::register: Distribution = 0');
        require(
            registeredDistributions[receiver] == 0,
            'TimeLockRegistry::register:Distribution for this address is already registered'
        );
        require(vestingStartingDate >= 1614553200, 'Cannot register earlier than March 2021'); // 1614553200 is UNIX TIME of 2021 March the 1st
        require(
            vestingStartingDate <= block.timestamp.add(30 days),
            'Cannot register more than 30 days ahead in the future'
        );
        require(totalTokens.add(distribution) <= IERC20(token).balanceOf(address(this)), 'Not enough tokens');

        totalTokens = totalTokens.add(distribution);
        // register distribution
        registeredDistributions[receiver] = distribution;
        registrations.push(receiver);

        // register token vested conditions
        TokenVested storage newTokenVested = tokenVested[receiver];
        newTokenVested.team = investorType;
        newTokenVested.vestingBegin = vestingStartingDate;

        if (newTokenVested.team == true) {
            newTokenVested.vestingEnd = vestingStartingDate.add(teamVesting);
        } else {
            newTokenVested.vestingEnd = vestingStartingDate.add(investorVesting);
        }
        newTokenVested.lastClaim = vestingStartingDate;

        tokenVested[receiver] = newTokenVested;

        // emit register event
        emit Register(receiver, distribution);
    }

    /**
     * PRIVILEGED GOVERNANCE FUNCTION. Cancel distribution registration in case of mistake and before a claim is done
     *
     * @notice Cancel distribution registration
     * @dev A claim has not to be done earlier
     * @param receiver Address that should have it's distribution removed
     * @return Whether or not it succeeded
     */
    function cancelRegistration(address receiver) external onlyOwner returns (bool) {
        require(registeredDistributions[receiver] != 0, 'Not registered');

        // get amount from distributions
        uint256 amount = registeredDistributions[receiver];

        // set distribution mapping to 0
        delete registeredDistributions[receiver];

        // set tokenVested mapping to 0
        delete tokenVested[receiver];

        // remove from the list of all registrations
        registrations.remove(receiver);

        // decrease total tokens
        totalTokens = totalTokens.sub(amount);

        // emit cancel event
        emit Cancel(receiver, amount);

        return true;
    }

    /**
     * PRIVILEGED GOVERNANCE FUNCTION. Cancel distribution registration in case of mistake and before a claim is done
     *
     * @notice Cancel already delivered tokens. It might only apply when non-completion of vesting period of Team members or Advisors
     * @dev An automatic override allowance is granted during the claim process
     * @param account Address that should have it's distribution removed
     * @return Whether or not it succeeded
     */
    function cancelDeliveredTokens(address account) external onlyOwner returns (bool) {
        uint256 loosingAmount = token.cancelVestedTokens(account);

        // emit cancel event
        emit Cancel(account, loosingAmount);
        return true;
    }

    /**
     * PRIVILEGED GOVERNANCE FUNCTION. Recover tokens in Time Lock Registry smartcontract address by the owner
     *
     * @notice Send tokens from smartcontract address to the owner.
     * It might only apply after a cancellation of vested tokens
     * @param amount Amount to be recovered by the owner of the Time Lock Registry smartcontract from its balance
     * @return Whether or not it succeeded
     */
    function transferToOwner(uint256 amount) external onlyOwner returns (bool) {
        SafeERC20.safeTransfer(token, msg.sender, amount);
        return true;
    }

    /**
     * PRIVILEGED GOVERNANCE FUNCTION. Claim locked tokens by the registered account
     *
     * @notice Claim tokens due amount.
     * @dev Claim is done by the user in the TimeLocked contract and the contract is the only allowed to call
     * this function on behalf of the user to make the claim
     * @return The amount of tokens registered and delivered after the claim
     */
    function claim(address _receiver) external onlyBABLToken returns (uint256) {
        require(registeredDistributions[_receiver] != 0, 'Not registered');

        // get amount from distributions
        uint256 amount = registeredDistributions[_receiver];
        TokenVested storage claimTokenVested = tokenVested[_receiver];

        claimTokenVested.lastClaim = block.timestamp;

        // set distribution mapping to 0
        delete registeredDistributions[_receiver];

        // decrease total tokens
        totalTokens = totalTokens.sub(amount);

        // register lockup in TimeLockedToken
        // this will transfer funds from this contract and lock them for sender
        token.registerLockup(
            _receiver,
            amount,
            claimTokenVested.team,
            claimTokenVested.vestingBegin,
            claimTokenVested.vestingEnd,
            claimTokenVested.lastClaim
        );

        // set tokenVested mapping to 0
        delete tokenVested[_receiver];

        // emit claim event
        emit Claim(_receiver, amount);

        return amount;
    }

    /* ============ Getter Functions ============ */

    function checkVesting(address address_)
        external
        view
        returns (
            bool team,
            uint256 start,
            uint256 end,
            uint256 last
        )
    {
        TokenVested storage checkTokenVested = tokenVested[address_];

        return (
            checkTokenVested.team,
            checkTokenVested.vestingBegin,
            checkTokenVested.vestingEnd,
            checkTokenVested.lastClaim
        );
    }

    function checkRegisteredDistribution(address address_) external view returns (uint256 amount) {
        return registeredDistributions[address_];
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.7.6;

import {ERC20} from '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import {IVoteToken} from '../interfaces/IVoteToken.sol';
import {ReentrancyGuard} from '@openzeppelin/contracts/utils/ReentrancyGuard.sol';
import {LowGasSafeMath} from '../lib/LowGasSafeMath.sol';
import {Context} from '@openzeppelin/contracts/utils/Context.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {Address} from '@openzeppelin/contracts/utils/Address.sol';

/**
 * @title VoteToken
 * @notice Custom token which tracks voting power for governance
 * @dev This is an abstraction of a fork of the Compound governance contract
 * VoteToken is used by BABL to allow tracking voting power
 * Checkpoints are created every time state is changed which record voting power
 * Inherits standard ERC20 behavior
 */

abstract contract VoteToken is Context, ERC20, Ownable, IVoteToken, ReentrancyGuard {
    using LowGasSafeMath for uint256;
    using Address for address;

    /* ============ Events ============ */

    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);
    event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);

    /* ============ Modifiers ============ */

    /* ============ State Variables ============ */

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH =
        keccak256('EIP712Domain(string name,uint256 chainId,address verifyingContract)');

    /// @notice The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant DELEGATION_TYPEHASH =
        keccak256('Delegation(address delegatee,uint256 nonce,uint256 expiry)');

    /// @dev A record of votes checkpoints for each account, by index
    mapping(address => address) public delegates;

    /// @notice A checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint32 fromBlock;
        uint96 votes;
    }

    /// @notice A record of votes checkpoints for each account, by index
    mapping(address => mapping(uint32 => Checkpoint)) public checkpoints;

    /// @notice The number of checkpoints for each account
    mapping(address => uint32) public numCheckpoints;

    /// @notice A record of states for signing / validating signatures
    mapping(address => uint256) public nonces;

    /* ============ Functions ============ */

    /* ============ Constructor ============ */

    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {}

    /* ============ External Functions ============ */

    /* ===========  Token related Gov Functions ====== */

    /**
     * PRIVILEGED GOVERNANCE FUNCTION. Delegating votes from msg.sender to delegatee
     *
     * @notice Delegate votes from `msg.sender` to `delegatee`
     * @param delegatee The address to delegate votes to
     */

    function delegate(address delegatee) external override {
        return _delegate(msg.sender, delegatee);
    }

    /**
     * PRIVILEGED GOVERNANCE FUNCTION. Delegate votes using signature to 'delegatee'
     *
     * @notice Delegates votes from signatory to `delegatee`
     * @param delegatee The address to delegate votes to
     * @param nonce The contract state required to match the signature
     * @param expiry The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */

    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s,
        bool prefix
    ) external override {
        address signatory;
        bytes32 domainSeparator =
            keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name())), getChainId(), address(this)));
        bytes32 structHash = keccak256(abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, expiry));
        bytes32 digest = keccak256(abi.encodePacked('\x19\x01', domainSeparator, structHash));
        if (prefix) {
            bytes32 digestHash = keccak256(abi.encodePacked('\x19Ethereum Signed Message:\n32', digest));
            signatory = ecrecover(digestHash, v, r, s);
        } else {
            signatory = ecrecover(digest, v, r, s);
        }

        require(balanceOf(signatory) > 0, 'VoteToken::delegateBySig: invalid delegator');
        require(signatory != address(0), 'VoteToken::delegateBySig: invalid signature');
        require(nonce == nonces[signatory], 'VoteToken::delegateBySig: invalid nonce');
        nonces[signatory]++;
        require(block.timestamp <= expiry, 'VoteToken::delegateBySig: signature expired');
        return _delegate(signatory, delegatee);
    }

    /**
     * GOVERNANCE FUNCTION. Check Delegate votes using signature to 'delegatee'
     *
     * @notice Get current voting power for an account
     * @param account Account to get voting power for
     * @return Voting power for an account
     */
    function getCurrentVotes(address account) external view virtual override returns (uint96) {
        uint32 nCheckpoints = numCheckpoints[account];
        return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }

    /**
     * GOVERNANCE FUNCTION. Get voting power at a specific block for an account
     *
     * @param account Account to get voting power for
     * @param blockNumber Block to get voting power at
     * @return Voting power for an account at specific block
     */
    function getPriorVotes(address account, uint256 blockNumber) external view virtual override returns (uint96) {
        require(blockNumber < block.number, 'BABLToken::getPriorVotes: not yet determined');
        uint32 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
            return checkpoints[account][nCheckpoints - 1].votes;
        }

        // Next check implicit zero balance
        if (checkpoints[account][0].fromBlock > blockNumber) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory cp = checkpoints[account][center];
            if (cp.fromBlock == blockNumber) {
                return cp.votes;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[account][lower].votes;
    }

    function getMyDelegatee() external view override returns (address) {
        return delegates[msg.sender];
    }

    function getDelegatee(address account) external view override returns (address) {
        return delegates[account];
    }

    function getCheckpoints(address account, uint32 id)
        external
        view
        override
        returns (uint32 fromBlock, uint96 votes)
    {
        Checkpoint storage getCheckpoint = checkpoints[account][id];
        return (getCheckpoint.fromBlock, getCheckpoint.votes);
    }

    function getNumberOfCheckpoints(address account) external view override returns (uint32) {
        return numCheckpoints[account];
    }

    /* ============ Internal Only Function ============ */

    /**
     * GOVERNANCE FUNCTION. Make a delegation
     *
     * @dev Internal function to delegate voting power to an account
     * @param delegator The address of the account delegating votes from
     * @param delegatee The address to delegate votes to
     */

    function _delegate(address delegator, address delegatee) internal {
        address currentDelegate = delegates[delegator];
        uint96 delegatorBalance = safe96(_balanceOf(delegator), 'VoteToken::_delegate: uint96 overflow');
        delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }

    function _balanceOf(address account) internal view virtual returns (uint256) {
        return balanceOf(account);
    }

    /**
     * GOVERNANCE FUNCTION. Move the delegates
     *
     * @dev Internal function to move delegates between accounts
     * @param srcRep The address of the account delegating votes from
     * @param dstRep The address of the account delegating votes to
     * @param amount The voting power to move
     */
    function _moveDelegates(
        address srcRep,
        address dstRep,
        uint96 amount
    ) internal {
        if (srcRep != dstRep && amount > 0) {
            // It must not revert but do nothing in cases of address(0) being part of the move
            // Sub voting amount to source in case it is not the zero address (e.g. transfers)
            if (srcRep != address(0)) {
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint96 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
                uint96 srcRepNew = sub96(srcRepOld, amount, 'VoteToken::_moveDelegates: vote amount underflows');
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }
            if (dstRep != address(0)) {
                // Add it to destination in case it is not the zero address (e.g. any transfer of tokens or delegations except a first mint to a specific address)
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint96 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
                uint96 dstRepNew = add96(dstRepOld, amount, 'VoteToken::_moveDelegates: vote amount overflows');
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    /**
     * GOVERNANCE FUNCTION. Internal function to write a checkpoint for voting power
     *
     * @dev internal function to write a checkpoint for voting power
     * @param delegatee The address of the account delegating votes to
     * @param nCheckpoints The num checkpoint
     * @param oldVotes The previous voting power
     * @param newVotes The new voting power
     */
    function _writeCheckpoint(
        address delegatee,
        uint32 nCheckpoints,
        uint96 oldVotes,
        uint96 newVotes
    ) internal {
        uint32 blockNumber = safe32(block.number, 'VoteToken::_writeCheckpoint: block number exceeds 32 bits');

        if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
            checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
        } else {
            checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
            numCheckpoints[delegatee] = nCheckpoints + 1;
        }

        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }

    /**
     * INTERNAL FUNCTION. Internal function to convert from uint256 to uint32
     *
     * @dev internal function to convert from uint256 to uint32
     */
    function safe32(uint256 n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    /**
     * INTERNAL FUNCTION. Internal function to convert from uint256 to uint96
     *
     * @dev internal function to convert from uint256 to uint96
     */
    function safe96(uint256 n, string memory errorMessage) internal pure returns (uint96) {
        require(n < 2**96, errorMessage);
        return uint96(n);
    }

    /**
     * INTERNAL FUNCTION. Internal function to add two uint96 numbers
     *
     * @dev internal safe math function to add two uint96 numbers
     */
    function add96(
        uint96 a,
        uint96 b,
        string memory errorMessage
    ) internal pure returns (uint96) {
        uint96 c = a + b;
        require(c >= a, errorMessage);
        return c;
    }

    /**
     * INTERNAL FUNCTION. Internal function to subtract two uint96 numbers
     *
     * @dev internal safe math function to subtract two uint96 numbers
     */
    function sub96(
        uint96 a,
        uint96 b,
        string memory errorMessage
    ) internal pure returns (uint96) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * INTERNAL FUNCTION. Internal function to get chain ID
     *
     * @dev internal function to get chain ID
     */
    function getChainId() internal pure returns (uint256) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: Apache-2.0

/*
    Original version by Synthetix.io
    https://docs.synthetix.io/contracts/source/libraries/safedecimalmath

    Adapted by Babylon Finance.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/

pragma solidity 0.7.6;

// solhint-disable

/**
 * @notice Forked from https://github.com/balancer-labs/balancer-core-v2/blob/master/contracts/lib/helpers/BalancerErrors.sol
 * @dev Reverts if `condition` is false, with a revert reason containing `errorCode`. Only codes up to 999 are
 * supported.
 */
function _require(bool condition, uint256 errorCode) pure {
    if (!condition) _revert(errorCode);
}

/**
 * @dev Reverts with a revert reason containing `errorCode`. Only codes up to 999 are supported.
 */
function _revert(uint256 errorCode) pure {
    // We're going to dynamically create a revert string based on the error code, with the following format:
    // 'BAB#{errorCode}'
    // where the code is left-padded with zeroes to three digits (so they range from 000 to 999).
    //
    // We don't have revert strings embedded in the contract to save bytecode size: it takes much less space to store a
    // number (8 to 16 bits) than the individual string characters.
    //
    // The dynamic string creation algorithm that follows could be implemented in Solidity, but assembly allows for a
    // much denser implementation, again saving bytecode size. Given this function unconditionally reverts, this is a
    // safe place to rely on it without worrying about how its usage might affect e.g. memory contents.
    assembly {
        // First, we need to compute the ASCII representation of the error code. We assume that it is in the 0-999
        // range, so we only need to convert three digits. To convert the digits to ASCII, we add 0x30, the value for
        // the '0' character.

        let units := add(mod(errorCode, 10), 0x30)

        errorCode := div(errorCode, 10)
        let tenths := add(mod(errorCode, 10), 0x30)

        errorCode := div(errorCode, 10)
        let hundreds := add(mod(errorCode, 10), 0x30)

        // With the individual characters, we can now construct the full string. The "BAB#" part is a known constant
        // (0x42414223): we simply shift this by 24 (to provide space for the 3 bytes of the error code), and add the
        // characters to it, each shifted by a multiple of 8.
        // The revert reason is then shifted left by 200 bits (256 minus the length of the string, 7 characters * 8 bits
        // per character = 56) to locate it in the most significant part of the 256 slot (the beginning of a byte
        // array).

        let revertReason := shl(200, add(0x42414223000000, add(add(units, shl(8, tenths)), shl(16, hundreds))))

        // We can now encode the reason in memory, which can be safely overwritten as we're about to revert. The encoded
        // message will have the following layout:
        // [ revert reason identifier ] [ string location offset ] [ string length ] [ string contents ]

        // The Solidity revert reason identifier is 0x08c739a0, the function selector of the Error(string) function. We
        // also write zeroes to the next 28 bytes of memory, but those are about to be overwritten.
        mstore(0x0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
        // Next is the offset to the location of the string, which will be placed immediately after (20 bytes away).
        mstore(0x04, 0x0000000000000000000000000000000000000000000000000000000000000020)
        // The string length is fixed: 7 characters.
        mstore(0x24, 7)
        // Finally, the string itself is stored.
        mstore(0x44, revertReason)

        // Even if the string is only 7 bytes long, we need to return a full 32 byte slot containing it. The length of
        // the encoded message is therefore 4 + 32 + 32 + 32 = 100.
        revert(0, 100)
    }
}

library Errors {
    // Max deposit limit needs to be under the limit
    uint256 internal constant MAX_DEPOSIT_LIMIT = 0;
    // Creator needs to deposit
    uint256 internal constant MIN_CONTRIBUTION = 1;
    // Min Garden token supply >= 0
    uint256 internal constant MIN_TOKEN_SUPPLY = 2;
    // Deposit hardlock needs to be at least 1 block
    uint256 internal constant DEPOSIT_HARDLOCK = 3;
    // Needs to be at least the minimum
    uint256 internal constant MIN_LIQUIDITY = 4;
    // _reserveAssetQuantity is not equal to msg.value
    uint256 internal constant MSG_VALUE_DO_NOT_MATCH = 5;
    // Withdrawal amount has to be equal or less than msg.sender balance
    uint256 internal constant MSG_SENDER_TOKENS_DO_NOT_MATCH = 6;
    // Tokens are staked
    uint256 internal constant TOKENS_STAKED = 7;
    // Balance too low
    uint256 internal constant BALANCE_TOO_LOW = 8;
    // msg.sender doesn't have enough tokens
    uint256 internal constant MSG_SENDER_TOKENS_TOO_LOW = 9;
    //  There is an open redemption window already
    uint256 internal constant REDEMPTION_OPENED_ALREADY = 10;
    // Cannot request twice in the same window
    uint256 internal constant ALREADY_REQUESTED = 11;
    // Rewards and profits already claimed
    uint256 internal constant ALREADY_CLAIMED = 12;
    // Value have to be greater than zero
    uint256 internal constant GREATER_THAN_ZERO = 13;
    // Must be reserve asset
    uint256 internal constant MUST_BE_RESERVE_ASSET = 14;
    // Only contributors allowed
    uint256 internal constant ONLY_CONTRIBUTOR = 15;
    // Only controller allowed
    uint256 internal constant ONLY_CONTROLLER = 16;
    // Only creator allowed
    uint256 internal constant ONLY_CREATOR = 17;
    // Only keeper allowed
    uint256 internal constant ONLY_KEEPER = 18;
    // Fee is too high
    uint256 internal constant FEE_TOO_HIGH = 19;
    // Only strategy allowed
    uint256 internal constant ONLY_STRATEGY = 20;
    // Only active allowed
    uint256 internal constant ONLY_ACTIVE = 21;
    // Only inactive allowed
    uint256 internal constant ONLY_INACTIVE = 22;
    // Address should be not zero address
    uint256 internal constant ADDRESS_IS_ZERO = 23;
    // Not within range
    uint256 internal constant NOT_IN_RANGE = 24;
    // Value is too low
    uint256 internal constant VALUE_TOO_LOW = 25;
    // Value is too high
    uint256 internal constant VALUE_TOO_HIGH = 26;
    // Only strategy or protocol allowed
    uint256 internal constant ONLY_STRATEGY_OR_CONTROLLER = 27;
    // Normal withdraw possible
    uint256 internal constant NORMAL_WITHDRAWAL_POSSIBLE = 28;
    // User does not have permissions to join garden
    uint256 internal constant USER_CANNOT_JOIN = 29;
    // User does not have permissions to add strategies in garden
    uint256 internal constant USER_CANNOT_ADD_STRATEGIES = 30;
    // Only Protocol or garden
    uint256 internal constant ONLY_PROTOCOL_OR_GARDEN = 31;
    // Only Strategist
    uint256 internal constant ONLY_STRATEGIST = 32;
    // Only Integration
    uint256 internal constant ONLY_INTEGRATION = 33;
    // Only garden and data not set
    uint256 internal constant ONLY_GARDEN_AND_DATA_NOT_SET = 34;
    // Only active garden
    uint256 internal constant ONLY_ACTIVE_GARDEN = 35;
    // Contract is not a garden
    uint256 internal constant NOT_A_GARDEN = 36;
    // Not enough tokens
    uint256 internal constant STRATEGIST_TOKENS_TOO_LOW = 37;
    // Stake is too low
    uint256 internal constant STAKE_HAS_TO_AT_LEAST_ONE = 38;
    // Duration must be in range
    uint256 internal constant DURATION_MUST_BE_IN_RANGE = 39;
    // Max Capital Requested
    uint256 internal constant MAX_CAPITAL_REQUESTED = 41;
    // Votes are already resolved
    uint256 internal constant VOTES_ALREADY_RESOLVED = 42;
    // Voting window is closed
    uint256 internal constant VOTING_WINDOW_IS_OVER = 43;
    // Strategy needs to be active
    uint256 internal constant STRATEGY_NEEDS_TO_BE_ACTIVE = 44;
    // Max capital reached
    uint256 internal constant MAX_CAPITAL_REACHED = 45;
    // Capital is less then rebalance
    uint256 internal constant CAPITAL_IS_LESS_THAN_REBALANCE = 46;
    // Strategy is in cooldown period
    uint256 internal constant STRATEGY_IN_COOLDOWN = 47;
    // Strategy is not executed
    uint256 internal constant STRATEGY_IS_NOT_EXECUTED = 48;
    // Strategy is not over yet
    uint256 internal constant STRATEGY_IS_NOT_OVER_YET = 49;
    // Strategy is already finalized
    uint256 internal constant STRATEGY_IS_ALREADY_FINALIZED = 50;
    // No capital to unwind
    uint256 internal constant STRATEGY_NO_CAPITAL_TO_UNWIND = 51;
    // Strategy needs to be inactive
    uint256 internal constant STRATEGY_NEEDS_TO_BE_INACTIVE = 52;
    // Duration needs to be less
    uint256 internal constant DURATION_NEEDS_TO_BE_LESS = 53;
    // Can't sweep reserve asset
    uint256 internal constant CANNOT_SWEEP_RESERVE_ASSET = 54;
    // Voting window is opened
    uint256 internal constant VOTING_WINDOW_IS_OPENED = 55;
    // Strategy is executed
    uint256 internal constant STRATEGY_IS_EXECUTED = 56;
    // Min Rebalance Capital
    uint256 internal constant MIN_REBALANCE_CAPITAL = 57;
    // Not a valid strategy NFT
    uint256 internal constant NOT_STRATEGY_NFT = 58;
    // Garden Transfers Disabled
    uint256 internal constant GARDEN_TRANSFERS_DISABLED = 59;
    // Tokens are hardlocked
    uint256 internal constant TOKENS_HARDLOCKED = 60;
    // Max contributors reached
    uint256 internal constant MAX_CONTRIBUTORS = 61;
    // BABL Transfers Disabled
    uint256 internal constant BABL_TRANSFERS_DISABLED = 62;
    // Strategy duration range error
    uint256 internal constant DURATION_RANGE = 63;
    // Checks the min amount of voters
    uint256 internal constant MIN_VOTERS_CHECK = 64;
    // Ge contributor power error
    uint256 internal constant CONTRIBUTOR_POWER_CHECK_WINDOW = 65;
    // Not enough reserve set aside
    uint256 internal constant NOT_ENOUGH_RESERVE = 66;
    // Garden is already public
    uint256 internal constant GARDEN_ALREADY_PUBLIC = 67;
    // Withdrawal with penalty
    uint256 internal constant WITHDRAWAL_WITH_PENALTY = 68;
    // Withdrawal with penalty
    uint256 internal constant ONLY_MINING_ACTIVE = 69;
    // Overflow in supply
    uint256 internal constant OVERFLOW_IN_SUPPLY = 70;
    // Overflow in power
    uint256 internal constant OVERFLOW_IN_POWER = 71;
    // Not a system contract
    uint256 internal constant NOT_A_SYSTEM_CONTRACT = 72;
    // Strategy vs Garden mismatch
    uint256 internal constant STRATEGY_GARDEN_MISMATCH = 73;
    // Minimum quarters is 1
    uint256 internal constant QUARTERS_MIN_1 = 74;
    // Too many strategy operations
    uint256 internal constant TOO_MANY_OPS = 75;
    // Only operations
    uint256 internal constant ONLY_OPERATION = 76;
    // Strat params wrong length
    uint256 internal constant STRAT_PARAMS_LENGTH = 77;
    // Garden params wrong length
    uint256 internal constant GARDEN_PARAMS_LENGTH = 78;
    // Token names too long
    uint256 internal constant NAME_TOO_LONG = 79;
    // Contributor power overflows over garden power
    uint256 internal constant CONTRIBUTOR_POWER_OVERFLOW = 80;
    // Contributor power window out of bounds
    uint256 internal constant CONTRIBUTOR_POWER_CHECK_DEPOSITS = 81;
    // Contributor power window out of bounds
    uint256 internal constant NO_REWARDS_TO_CLAIM = 82;
    // Pause guardian paused this operation
    uint256 internal constant ONLY_UNPAUSED = 83;
    // Reentrant intent
    uint256 internal constant REENTRANT_CALL = 84;
    // Reserve asset not supported
    uint256 internal constant RESERVE_ASSET_NOT_SUPPORTED = 85;
    // Withdrawal/Deposit check min amount received
    uint256 internal constant RECEIVE_MIN_AMOUNT = 86;
    // Total Votes has to be positive
    uint256 internal constant TOTAL_VOTES_HAVE_TO_BE_POSITIVE = 87;
    // Signer has to be valid
    uint256 internal constant INVALID_SIGNER = 88;
    // Nonce has to be valid
    uint256 internal constant INVALID_NONCE = 89;
    // Garden is not public
    uint256 internal constant GARDEN_IS_NOT_PUBLIC = 90;
    // Setting max contributors
    uint256 internal constant MAX_CONTRIBUTORS_SET = 91;
    // Profit sharing mismatch for customized gardens
    uint256 internal constant PROFIT_SHARING_MISMATCH = 92;
    // Max allocation percentage
    uint256 internal constant MAX_STRATEGY_ALLOCATION_PERCENTAGE = 93;
    // new creator must not exist
    uint256 internal constant NEW_CREATOR_MUST_NOT_EXIST = 94;
    // only first creator can add
    uint256 internal constant ONLY_FIRST_CREATOR_CAN_ADD = 95;
    // invalid address
    uint256 internal constant INVALID_ADDRESS = 96;
    // creator can only renounce in some circumstances
    uint256 internal constant CREATOR_CANNOT_RENOUNCE = 97;
    // no price for trade
    uint256 internal constant NO_PRICE_FOR_TRADE = 98;
    // Max capital requested
    uint256 internal constant ZERO_CAPITAL_REQUESTED = 99;
    // Unwind capital above the limit
    uint256 internal constant INVALID_CAPITAL_TO_UNWIND = 100;
    // Mining % sharing does not match
    uint256 internal constant INVALID_MINING_VALUES = 101;
    // Max trade slippage percentage
    uint256 internal constant MAX_TRADE_SLIPPAGE_PERCENTAGE = 102;
    // Max gas fee percentage
    uint256 internal constant MAX_GAS_FEE_PERCENTAGE = 103;
    // Mismatch between voters and votes
    uint256 internal constant INVALID_VOTES_LENGTH = 104;
    // Only Rewards Distributor
    uint256 internal constant ONLY_RD = 105;
    // Fee is too LOW
    uint256 internal constant FEE_TOO_LOW = 106;
    // Only governance or emergency
    uint256 internal constant ONLY_GOVERNANCE_OR_EMERGENCY = 107;
    // Strategy invalid reserve asset amount
    uint256 internal constant INVALID_RESERVE_AMOUNT = 108;
    // Heart only pumps once a week
    uint256 internal constant HEART_ALREADY_PUMPED = 109;
    // Heart needs garden votes to pump
    uint256 internal constant HEART_VOTES_MISSING = 110;
    // Not enough fees for heart
    uint256 internal constant HEART_MINIMUM_FEES = 111;
    // Invalid heart votes length
    uint256 internal constant HEART_VOTES_LENGTH = 112;
    // Heart LP tokens not received
    uint256 internal constant HEART_LP_TOKENS = 113;
    // Heart invalid asset to lend
    uint256 internal constant HEART_ASSET_LEND_INVALID = 114;
    // Heart garden not set
    uint256 internal constant HEART_GARDEN_NOT_SET = 115;
    // Heart asset to lend is the same
    uint256 internal constant HEART_ASSET_LEND_SAME = 116;
    // Heart invalid ctoken
    uint256 internal constant HEART_INVALID_CTOKEN = 117;
    // Price per share is wrong
    uint256 internal constant PRICE_PER_SHARE_WRONG = 118;
    // Heart asset to purchase is same
    uint256 internal constant HEART_ASSET_PURCHASE_INVALID = 119;
    // Reset hardlock bigger than timestamp
    uint256 internal constant RESET_HARDLOCK_INVALID = 120;
    // Invalid referrer
    uint256 internal constant INVALID_REFERRER = 121;
    // Only Heart Garden
    uint256 internal constant ONLY_HEART_GARDEN = 122;
    // Max BABL Cap to claim by sig
    uint256 internal constant MAX_BABL_CAP_REACHED = 123;
    // Not enough BABL
    uint256 internal constant NOT_ENOUGH_BABL = 124;
    // Claim garden NFT
    uint256 internal constant CLAIM_GARDEN_NFT = 125;
    // Not enough collateral
    uint256 internal constant NOT_ENOUGH_COLLATERAL = 126;
    // Amount too low
    uint256 internal constant AMOUNT_TOO_LOW = 127;
    // Amount too high
    uint256 internal constant AMOUNT_TOO_HIGH = 128;
    // Not enough to repay debt
    uint256 internal constant SLIPPAGE_TOO_HIH = 129;
    // Invalid amount
    uint256 internal constant INVALID_AMOUNT = 130;
    // Not enough BABL
    uint256 internal constant NOT_ENOUGH_AMOUNT = 131;
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.7.6;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IVoteToken {
    function delegate(address delegatee) external;

    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s,
        bool prefix
    ) external;

    function getCurrentVotes(address account) external view returns (uint96);

    function getPriorVotes(address account, uint256 blockNumber) external view returns (uint96);

    function getMyDelegatee() external view returns (address);

    function getDelegatee(address account) external view returns (address);

    function getCheckpoints(address account, uint32 id) external view returns (uint32 fromBlock, uint96 votes);

    function getNumberOfCheckpoints(address account) external view returns (uint32);
}

interface IVoteTokenWithERC20 is IVoteToken, IERC20 {}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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

pragma solidity 0.7.6;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 */
interface IERC1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.7.6;

import {ICurveMetaRegistry} from './ICurveMetaRegistry.sol';

/**
 * @title IPriceOracle
 * @author Babylon Finance
 *
 * Interface for interacting with PriceOracle
 */
interface ITokenIdentifier {
    /* ============ Functions ============ */

    function identifyTokens(
        address _tokenIn,
        address _tokenOut,
        ICurveMetaRegistry _curveMetaRegistry
    )
        external
        view
        returns (
            uint8,
            uint8,
            address,
            address
        );

    function updateYearnVault(address[] calldata _vaults, bool[] calldata _values) external;

    function updateVisor(address[] calldata _vaults, bool[] calldata _values) external;

    function updateSynth(address[] calldata _synths, bool[] calldata _values) external;

    function updateCreamPair(address[] calldata _creamTokens, address[] calldata _underlyings) external;

    function updateAavePair(address[] calldata _aaveTokens, address[] calldata _underlyings) external;

    function updateCompoundPair(address[] calldata _cTokens, address[] calldata _underlyings) external;
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.7.6;

/**
 * @title ICurveMetaRegistry
 * @author Babylon Finance
 *
 * Interface for interacting with all the curve registries
 */
interface ICurveMetaRegistry {
    /* ============ Functions ============ */

    function updatePoolsList() external;

    function updateCryptoRegistries() external;

    /* ============ View Functions ============ */

    function isPool(address _poolAddress) external view returns (bool);

    function getCoinAddresses(address _pool, bool _getUnderlying) external view returns (address[8] memory);

    function getNCoins(address _pool) external view returns (uint256);

    function getLpToken(address _pool) external view returns (address);

    function getPoolFromLpToken(address _lpToken) external view returns (address);

    function getVirtualPriceFromLpToken(address _pool) external view returns (uint256);

    function isMeta(address _pool) external view returns (bool);

    function getUnderlyingAndRate(address _pool, uint256 _i) external view returns (address, uint256);

    function findPoolForCoins(
        address _fromToken,
        address _toToken,
        uint256 _i
    ) external view returns (address);

    function getCoinIndices(
        address _pool,
        address _fromToken,
        address _toToken
    )
        external
        view
        returns (
            uint256,
            uint256,
            bool
        );
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.7.6;

/**
 * @title IBabylonGate
 * @author Babylon Finance
 *
 * Interface for interacting with the Guestlists
 */
interface IBabylonGate {
    /* ============ Functions ============ */

    function setGardenAccess(
        address _user,
        address _garden,
        uint8 _permission
    ) external returns (uint256);

    function setCreatorPermissions(address _user, bool _canCreate) external returns (uint256);

    function grantGardenAccessBatch(
        address _garden,
        address[] calldata _users,
        uint8[] calldata _perms
    ) external returns (bool);

    function maxNumberOfInvites() external view returns (uint256);

    function setMaxNumberOfInvites(uint256 _maxNumberOfInvites) external;

    function grantCreatorsInBatch(address[] calldata _users, bool[] calldata _perms) external returns (bool);

    function canCreate(address _user) external view returns (bool);

    function canJoinAGarden(address _garden, address _user) external view returns (bool);

    function canVoteInAGarden(address _garden, address _user) external view returns (bool);

    function canAddStrategiesInAGarden(address _garden, address _user) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @title SignedSafeMath
 * @dev Signed math operations with safety checks that revert on error.
 */
library SignedSafeMath {
    int256 constant private _INT256_MIN = -2**255;

    /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == _INT256_MIN), "SignedSafeMath: multiplication overflow");

        int256 c = a * b;
        require(c / a == b, "SignedSafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "SignedSafeMath: division by zero");
        require(!(b == -1 && a == _INT256_MIN), "SignedSafeMath: division overflow");

        int256 c = a / b;

        return c;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath: subtraction overflow");

        return c;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

        return c;
    }
}