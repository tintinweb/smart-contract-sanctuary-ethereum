// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./interfaces/tokens/erc20permit-upgradeable/IERC20PermitUpgradeable.sol";

import "./libraries/DecimalsConverter.sol";
import "./libraries/SafeMath.sol";

import "./interfaces/IDemandBook.sol";
import "./interfaces/IContractsRegistry.sol";
import "./interfaces/IDemandBookLiquidity.sol";
import "./interfaces/ICapitalPool.sol";
import "./interfaces/IClaimingRegistry.sol";
import "./interfaces/IClaimVoting.sol";
import "./interfaces/helpers/IPriceFeed.sol";
import "./interfaces/IPolicyBookAdmin.sol";

import "./abstract/AbstractDependant.sol";

import "./Globals.sol";

contract DemandBook is IDemandBook, Initializable, AbstractDependant {
    using SafeERC20 for IERC20Metadata;
    using SafeMath for uint256;
    using Math for uint256;
    using EnumerableSet for EnumerableSet.UintSet;

    uint256 public constant override OPEN_PERIOD = 1 hours;
    uint256 public constant override PENDING_PERIOD = 1 hours;
    uint256 public constant override STILL_CLAIMABLE_FOR = 1 weeks;

    IERC20Metadata public stablecoin;
    IDemandBookLiquidity public demandBookLiquidity;
    ICapitalPool public capitalPool;
    IClaimingRegistry public claimingRegistry;
    IClaimVoting public claimVoting;
    IPolicyBookAdmin public policyBookAdmin;
    IPriceFeed public priceFeed;

    uint256 public stblDecimals;

    uint256 private _demandIndex;
    mapping(uint256 => DemandInfo) public override demandInfo; // demandIndex -> DemandInfo
    EnumerableSet.UintSet internal _allDemands; // demandIndexes
    mapping(address => EnumerableSet.UintSet) internal _createdDemands; // demander -> demandIndex
    mapping(address => EnumerableSet.UintSet) internal _investedDemands; // provider -> demandIndex

    mapping(address => mapping(address => uint256)) internal _demandsToIndex; // demander -> protocol -> demandIndex

    address public deinToken;

    EnumerableSet.UintSet internal _allValidatedDemands; // demandIndexes

    modifier onlyCapitalPool() {
        require(address(capitalPool) == msg.sender, "DB: Caller is not CP contract");
        _;
    }

    modifier onlyDemandBookLiquidity() {
        require(address(demandBookLiquidity) == msg.sender, "DB: Caller is not DBL contract");
        _;
    }

    modifier onlyClaimingRegistry() {
        require(address(claimingRegistry) == msg.sender, "DB: Caller is not CR contract");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == address(policyBookAdmin), "DB: Not a PBA");
        _;
    }

    modifier withExistingDemand(uint256 demandIndex) {
        require(demandExists(demandIndex), "DB: This demand doesn't exist");
        _;
    }

    function __DemandBook_init() external initializer {
        _demandIndex = 1;
    }

    function setDependencies(IContractsRegistry _contractsRegistry)
        external
        override
        onlyInjectorOrZero
    {
        stablecoin = IERC20Metadata(_contractsRegistry.getUSDTContract());
        demandBookLiquidity = IDemandBookLiquidity(
            _contractsRegistry.getDemandBookLiquidityContract()
        );
        capitalPool = ICapitalPool(_contractsRegistry.getCapitalPoolContract());
        claimingRegistry = IClaimingRegistry(_contractsRegistry.getClaimingRegistryContract());
        claimVoting = IClaimVoting(_contractsRegistry.getClaimVotingContract());
        policyBookAdmin = IPolicyBookAdmin(_contractsRegistry.getPolicyBookAdminContract());
        priceFeed = IPriceFeed(_contractsRegistry.getPriceFeedContract());

        stblDecimals = stablecoin.decimals();
        deinToken = _contractsRegistry.getDEINContract();
    }

    function demandExists(uint256 demandIndex) public view override returns (bool) {
        return _allDemands.contains(demandIndex);
    }

    /// @dev a open demand is a demand created, younger than 72h
    function _isDemandOpen(uint256 demandIndex) internal view returns (bool) {
        uint256 creationTime = demandInfo[demandIndex].creationTime;
        return creationTime == 0 ? false : block.timestamp < creationTime.tryAdd(OPEN_PERIOD);
    }

    /// @dev a pending demand is a demand created, not started and not closed
    function _isDemandPending(uint256 demandIndex) internal view returns (bool) {
        uint256 creationTime = demandInfo[demandIndex].creationTime;
        uint256 startTime = demandInfo[demandIndex].startTime;
        return
            creationTime == 0 || startTime != 0
                ? false
                : block.timestamp >= creationTime.tryAdd(OPEN_PERIOD) &&
                    block.timestamp < creationTime.tryAdd(OPEN_PERIOD).tryAdd(PENDING_PERIOD);
    }

    /// @dev a closed demand is a demand created, not started after 24h pending
    function _isDemandClosed(uint256 demandIndex) internal view returns (bool) {
        uint256 creationTime = demandInfo[demandIndex].creationTime;
        uint256 startTime = demandInfo[demandIndex].startTime;
        return
            creationTime == 0 || startTime != 0
                ? false
                : block.timestamp >= creationTime.tryAdd(OPEN_PERIOD).tryAdd(PENDING_PERIOD);
    }

    /// @dev a valid demand is a demand created, started and not expired
    function _isDemandValid(uint256 demandIndex) internal view returns (bool) {
        uint256 endTime = demandInfo[demandIndex].endTime;
        return endTime == 0 ? false : block.timestamp < endTime;
    }

    /// @dev an expired demand is a demand created, started, expired and not ended
    /// @dev after demand expires, user can create new one
    function _isDemandExpired(uint256 demandIndex) internal view returns (bool) {
        uint256 endTime = demandInfo[demandIndex].endTime;
        return
            endTime == 0
                ? false
                : block.timestamp >= endTime &&
                    block.timestamp < endTime.tryAdd(STILL_CLAIMABLE_FOR);
    }

    /// @dev an active demand is a demand created, started and not ended
    /// @dev before demand end, user can claim
    function isDemandActive(address demander, uint256 demandIndex)
        public
        view
        override
        returns (bool)
    {
        return _isDemandActive(demandIndex) && _createdDemands[demander].contains(demandIndex);
    }

    function _isDemandActive(uint256 demandIndex) internal view returns (bool) {
        return
            demandExists(demandIndex) &&
            (_isDemandValid(demandIndex) || _isDemandExpired(demandIndex));
    }

    /// @dev an ended demand is a demand created, started older than endTime + 1 epoch
    function _isDemandEnded(uint256 demandIndex) internal view returns (bool) {
        uint256 endTime = demandInfo[demandIndex].endTime;
        return endTime == 0 ? false : block.timestamp >= endTime.tryAdd(STILL_CLAIMABLE_FOR);
    }

    function getDemandStatus(uint256 demandIndex)
        public
        view
        override
        withExistingDemand(demandIndex)
        returns (DemandStatus status)
    {
        if (_isDemandOpen(demandIndex)) {
            status = DemandStatus.OPEN;
        }
        if (_isDemandPending(demandIndex)) {
            status = DemandStatus.PENDING;
        }
        if (_isDemandClosed(demandIndex)) {
            status = DemandStatus.CLOSED;
        }
        if (_isDemandActive(demandIndex)) {
            status = DemandStatus.ACTIVE;
        }
        if (_isDemandEnded(demandIndex)) {
            status = DemandStatus.ENDED;
        }
    }

    function demandStartTime(uint256 demandIndex)
        external
        view
        override
        returns (uint256 startTime)
    {
        startTime = demandInfo[demandIndex].startTime;
    }

    function getDemandAmountInfo(uint256 demandIndex)
        external
        view
        override
        returns (
            uint256 coverageAmount,
            uint256 depositedLiquidity,
            uint256 currentLiquidity,
            uint256 premiumAmount,
            uint256 protocolFeeAmount,
            uint256 rewardAmount
        )
    {
        coverageAmount = demandInfo[demandIndex].coverageAmount;
        depositedLiquidity = demandInfo[demandIndex].depositedLiquidity;
        currentLiquidity = demandInfo[demandIndex].currentLiquidity;
        premiumAmount = demandInfo[demandIndex].premiumAmount;
        rewardAmount = _getRewardAmount(demandIndex);
        protocolFeeAmount = demandInfo[demandIndex].protocolFeeAmount;
    }

    function getDemandDemanderInfo(uint256 demandIndex)
        external
        view
        override
        returns (address demander, bool isPremiumWithdrawn)
    {
        demander = demandInfo[demandIndex].demander;
        isPremiumWithdrawn = demandInfo[demandIndex].isPremiumWithdrawn;
    }

    function _getRewardAmount(uint256 demandIndex) internal view returns (uint256 rewardAmount) {
        if (demandInfo[demandIndex].depositedLiquidity > 0) {
            if (
                _isDemandOpen(demandIndex) ||
                _isDemandPending(demandIndex) ||
                _isDemandClosed(demandIndex)
            ) {
                rewardAmount = demandInfo[demandIndex]
                    .premiumAmount
                    .mul(CLOSED_REWARD_PERCENTAGE)
                    .uncheckedDiv(PERCENTAGE_100);
            }
            if (_isDemandActive(demandIndex) || _isDemandEnded(demandIndex)) {
                rewardAmount = demandInfo[demandIndex]
                    .premiumAmount
                    .mul(ACTIVE_REWARD_PERCENTAGE)
                    .uncheckedDiv(PERCENTAGE_100);
            }
        }
    }

    function countAllDemands() external view override returns (uint256) {
        return _allDemands.length();
    }

    function countAllValidatedDemands() external view override returns (uint256) {
        return _allDemands.length();
    }

    function countCreatedDemands(address _demander) external view override returns (uint256) {
        return _createdDemands[_demander].length();
    }

    function countInvestedDemands(address _provider) external view override returns (uint256) {
        return _investedDemands[_provider].length();
    }

    function getDemandIndex(address _demander, address _protocol)
        external
        view
        override
        returns (uint256)
    {
        return _demandsToIndex[_demander][_protocol];
    }

    /// @notice use with countAllValidatedDemands()
    function listValidatedDemands(uint256 offset, uint256 limit)
        external
        view
        override
        returns (uint256[] memory _demandIndexesArr)
    {
        return _list(offset, limit, _allValidatedDemands);
    }

    function _list(
        uint256 offset,
        uint256 limit,
        EnumerableSet.UintSet storage set
    ) internal view returns (uint256[] memory _demandIndexesArr) {
        uint256 to = (offset.add(limit)).min(set.length()).max(offset);

        _demandIndexesArr = new uint256[](to.uncheckedSub(offset));

        for (uint256 i = offset; i < to; i = uncheckedInc(i)) {
            _demandIndexesArr[i.uncheckedSub(offset)] = set.at(i);
        }
    }

    /// @dev use with countAllDemands() if listOption == ListOption.ALL
    /// @dev use with countCreatedDemands() if listOption == ListOption.CREATED
    /// @dev use with countInvestedDemands() if listOption == ListOption.INVESTED
    function getListDemands(
        uint256 offset,
        uint256 limit,
        ListOption listOption
    ) external view override returns (PublicDemandInfo[] memory publicDemandInfo) {
        uint256 count;
        if (listOption == ListOption.ALL) {
            count = _allDemands.length();
        } else if (listOption == ListOption.CREATED) {
            count = _createdDemands[msg.sender].length();
        } else if (listOption == ListOption.INVESTED) {
            count = _investedDemands[msg.sender].length();
        }

        uint256 to = (offset.tryAdd(limit)).min(count).max(offset);
        publicDemandInfo = new PublicDemandInfo[](to.uncheckedSub(offset));

        for (uint256 i = offset; i < to; i = uncheckedInc(i)) {
            uint256 demandIndex;
            if (listOption == ListOption.ALL) {
                demandIndex = _allDemands.at(i);
            } else if (listOption == ListOption.CREATED) {
                demandIndex = _createdDemands[msg.sender].at(i);
            } else if (listOption == ListOption.INVESTED) {
                demandIndex = _investedDemands[msg.sender].at(i);
            }

            uint256 newIndex = i.uncheckedSub(offset);
            publicDemandInfo[newIndex] = getPublicDemandInfo(demandIndex);
        }
    }

    function getPublicDemandInfo(uint256 demandIndex)
        public
        view
        returns (PublicDemandInfo memory publicDemandInfo)
    {
        DemandInfo memory info = demandInfo[demandIndex];

        publicDemandInfo.demandIndex = _demandsToIndex[info.demander][info.protocol];
        publicDemandInfo.demander = info.demander;
        publicDemandInfo.protocol = info.protocol;
        publicDemandInfo.coverageAmount = info.coverageAmount;
        publicDemandInfo.currentLiquidity = info.currentLiquidity;
        publicDemandInfo.premiumAmount = info.premiumAmount;
        publicDemandInfo.rewardAmount = _getRewardAmount(demandIndex);
        publicDemandInfo.epochAmount = info.epochAmount;
        publicDemandInfo.creationTime = info.creationTime;
        publicDemandInfo.startTime = info.startTime;
        publicDemandInfo.endTime = info.endTime;
        publicDemandInfo.status = getDemandStatus(demandIndex);
        if (publicDemandInfo.status == DemandStatus.OPEN) {
            publicDemandInfo.time = info.creationTime.tryAdd(OPEN_PERIOD).trySub(block.timestamp);
        } else if (publicDemandInfo.status == DemandStatus.PENDING) {
            publicDemandInfo.time = info
                .creationTime
                .tryAdd(OPEN_PERIOD)
                .tryAdd(PENDING_PERIOD)
                .trySub(block.timestamp);
        } else if (publicDemandInfo.status == DemandStatus.ACTIVE) {
            publicDemandInfo.time = info.endTime.tryAdd(STILL_CLAIMABLE_FOR).trySub(
                block.timestamp
            );
        }
    }

    function createDemand(
        address _protocol,
        uint256 _coverageAmount,
        uint256 _premiumAmount,
        uint256 _epochAmount
    ) external override {
        uint256 demandIndex = _demandsToIndex[msg.sender][_protocol];
        require(
            !demandExists(demandIndex) ||
                !(_isDemandOpen(demandIndex) ||
                    _isDemandPending(demandIndex) ||
                    _isDemandValid(demandIndex)),
            "DB: Already insured"
        );
        require(_premiumAmount > 0, "DB: Wrong premium");
        require(_coverageAmount >= MINUMUM_COVERAGE, "DB: Wrong cover");
        require(
            _epochAmount > 0 && _epochAmount <= policyBookAdmin.demandMaxEpoch(),
            "DB: Wrong epoch duration"
        );

        claimingRegistry.canBuyNewBook(
            IClaimingRegistry.ClaimProvenance(
                IClaimingRegistry.Provenance.DEMAND,
                msg.sender,
                address(this),
                demandIndex
            )
        );

        demandInfo[_demandIndex].demander = msg.sender;
        demandInfo[_demandIndex].protocol = _protocol;
        demandInfo[_demandIndex].coverageAmount = _coverageAmount;
        demandInfo[_demandIndex].premiumAmount = _premiumAmount;
        demandInfo[_demandIndex].epochAmount = _epochAmount;
        demandInfo[_demandIndex].creationTime = block.timestamp;

        _allDemands.add(_demandIndex);
        _createdDemands[msg.sender].add(_demandIndex);
        _demandsToIndex[msg.sender][_protocol] = _demandIndex;

        _demandIndex = _demandIndex.add(1);

        // transfer from demander to DemandBookLiquidity : premiumAmount
        stablecoin.safeTransferFrom(
            msg.sender,
            address(demandBookLiquidity),
            DecimalsConverter.convertFrom18(_premiumAmount, stblDecimals)
        );
    }

    /// @dev update liquidity from providers at addLiquidity() and withdrawLiquidity()
    function updateLiquidity(
        uint256 demandIndex,
        address _provider,
        uint256 _liquidityAmount,
        bool _isAddedLiquidity,
        bool _nullCurrentLiquidity
    ) external override onlyDemandBookLiquidity {
        if (_isAddedLiquidity) {
            demandInfo[demandIndex].depositedLiquidity = demandInfo[demandIndex]
                .depositedLiquidity
                .add(_liquidityAmount);
            demandInfo[demandIndex].currentLiquidity = demandInfo[demandIndex]
                .currentLiquidity
                .add(_liquidityAmount);
            _investedDemands[_provider].add(demandIndex);
        } else {
            demandInfo[demandIndex].currentLiquidity = demandInfo[demandIndex]
                .currentLiquidity
                .sub(_liquidityAmount);
            if (_nullCurrentLiquidity) {
                _investedDemands[_provider].remove(demandIndex);
            }
        }
    }

    /// @dev update liquidity from claiming at withdrawClaim() and updateLostInDefiDB()
    function updateLiquidity(uint256 demandIndex, uint256 _liquidityLoss)
        external
        override
        withExistingDemand(demandIndex)
        onlyCapitalPool
    {
        demandInfo[demandIndex].currentLiquidity = demandInfo[demandIndex].currentLiquidity.sub(
            _liquidityLoss
        );
    }

    function validateDemand(uint256 demandIndex) external override onlyDemandBookLiquidity {
        _validateDemand(demandIndex);
    }

    function _validateDemand(uint256 demandIndex) internal {
        uint256 epochAmount = demandInfo[demandIndex].epochAmount;
        demandInfo[demandIndex].startTime = block.timestamp;
        demandInfo[demandIndex].endTime = block.timestamp.tryAdd(
            (epochAmount).tryMul(DEMAND_EPOCH_DURATION)
        );

        uint256 premiumAmount = demandInfo[demandIndex].premiumAmount;
        uint256 protocolFeeAmount =
            premiumAmount.mul(policyBookAdmin.demandProtocolFee()).uncheckedDiv(PERCENTAGE_100);

        demandInfo[demandIndex].protocolFeeAmount = protocolFeeAmount;

        demandBookLiquidity.transferFundsAtValidation(
            demandInfo[demandIndex].depositedLiquidity,
            protocolFeeAmount
        );

        _allValidatedDemands.add(demandIndex);
    }

    function forceValidateDemand(uint256 demandIndex)
        external
        override
        withExistingDemand(demandIndex)
    {
        require(_isDemandPending(demandIndex), "DB: Demand is not pending");
        require(demandInfo[demandIndex].demander == msg.sender, "DB: Cannot validate");
        require(demandInfo[demandIndex].depositedLiquidity != 0, "DB: There is no liquidity");

        uint256 lastPremiumAmount = demandInfo[demandIndex].premiumAmount;
        uint256 newPremiumAmount =
            demandInfo[demandIndex].depositedLiquidity.mul(lastPremiumAmount).uncheckedDiv(
                demandInfo[demandIndex].coverageAmount
            );
        demandInfo[demandIndex].premiumAmount = newPremiumAmount;
        if (newPremiumAmount < lastPremiumAmount) {
            uint256 premiumLoss = lastPremiumAmount.uncheckedSub(newPremiumAmount);
            // transfer from DemandBookLiquidity to demander : premiumLoss
            demandBookLiquidity.refundPremium(msg.sender, premiumLoss);
        }
        demandInfo[demandIndex].coverageAmount = demandInfo[demandIndex].depositedLiquidity;

        _validateDemand(demandIndex);
    }

    function updatePremium(uint256 demandIndex) external override onlyDemandBookLiquidity {
        demandInfo[demandIndex].isPremiumWithdrawn = true;
    }

    function getClaimApprovalAmount(uint256 demandIndex) public view override returns (uint256) {
        uint256 coverageAmount = demandInfo[demandIndex].coverageAmount;

        return
            priceFeed.howManyDEINsInUSDT(
                DecimalsConverter.convertFrom18(coverageAmount.uncheckedDiv(100), stblDecimals)
            );
    }

    function submitClaimAndInitializeVoting(uint256 demandIndex, string calldata _evidenceURI)
        external
        override
    {
        _submitClaimAndInitializeVoting(msg.sender, demandIndex, _evidenceURI, false);
    }

    function submitClaimAndInitializeVotingWithPermit(
        uint256 demandIndex,
        string calldata _evidenceURI,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external override {
        uint256 lockedAmount = getClaimApprovalAmount(demandIndex);
        IERC20PermitUpgradeable(address(deinToken)).permit(
            msg.sender,
            address(claimingRegistry),
            lockedAmount,
            _deadline,
            _v,
            _r,
            _s
        );
        _submitClaimAndInitializeVoting(msg.sender, demandIndex, _evidenceURI, false);
    }

    function submitAppealAndInitializeVoting(uint256 demandIndex, string calldata _evidenceURI)
        external
        override
    {
        _submitClaimAndInitializeVoting(msg.sender, demandIndex, _evidenceURI, true);
    }

    function submitAppealAndInitializeVotingWithPermit(
        uint256 demandIndex,
        string calldata _evidenceURI,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external override {
        uint256 lockedAmount = getClaimApprovalAmount(demandIndex);
        IERC20PermitUpgradeable(address(deinToken)).permit(
            msg.sender,
            address(claimingRegistry),
            lockedAmount,
            _deadline,
            _v,
            _r,
            _s
        );
        _submitClaimAndInitializeVoting(msg.sender, demandIndex, _evidenceURI, true);
    }

    function _submitClaimAndInitializeVoting(
        address demander,
        uint256 demandIndex,
        string memory _evidenceURI,
        bool _appeal
    ) internal {
        IClaimingRegistry.ClaimProvenance memory claimProvenance =
            IClaimingRegistry.ClaimProvenance(
                IClaimingRegistry.Provenance.DEMAND,
                demander,
                address(this),
                demandIndex
            );

        if (!_appeal) {
            require(claimingRegistry.canClaim(claimProvenance), "CR: Cannot claim");
        } else if (_appeal) {
            require(claimingRegistry.canAppeal(claimProvenance), "CR: Cannot appeal");
        }

        uint256 coverage =
            Math.min(
                demandInfo[demandIndex].coverageAmount,
                demandInfo[demandIndex].currentLiquidity
            );

        claimingRegistry.submitClaim(claimProvenance, _evidenceURI, coverage, _appeal);
    }

    function commitWithdrawnClaim(uint256 demandIndex) external override onlyClaimingRegistry {
        _endDemand(demandIndex, block.timestamp);
    }

    function endActiveDemand(uint256 demandIndex) external override onlyClaimingRegistry {
        _endDemand(demandIndex, block.timestamp);
    }

    function _endDemand(uint256 demandIndex, uint256 _endTime) internal {
        demandInfo[demandIndex].startTime < _endTime.sub(STILL_CLAIMABLE_FOR)
            ? demandInfo[demandIndex].endTime = _endTime.sub(STILL_CLAIMABLE_FOR)
            : demandInfo[demandIndex].endTime = demandInfo[demandIndex].startTime;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

uint256 constant SECONDS_IN_THE_YEAR = 365 * 24 * 60 * 60; // 365 days * 24 hours * 60 minutes * 60 seconds
uint256 constant SECONDS_IN_THE_MONTH = 30 * 24 * 60 * 60; // 30 days * 24 hours * 60 minutes * 60 seconds
uint256 constant DAYS_IN_THE_YEAR = 365;
uint256 constant MAX_INT = type(uint256).max;

uint256 constant DECIMALS18 = 10**18;

uint256 constant INITIAL_STAKED_AMOUNT = 100 * DECIMALS18;
uint256 constant INITIAL_STAKED_AMOUNT_LP = 1 * DECIMALS18;

uint256 constant PRECISION = 10**25;
uint256 constant PERCENTAGE_100 = 100 * PRECISION;

uint256 constant CUSTOM_PRECISION = 10**7;

uint256 constant BLOCKS_PER_DAY = 7200;
uint256 constant BLOCKS_PER_MONTH = BLOCKS_PER_DAY * 30;
uint256 constant BLOCKS_PER_YEAR = BLOCKS_PER_DAY * 365;

uint256 constant APY_TOKENS = DECIMALS18;

uint256 constant ACTIVE_REWARD_PERCENTAGE = 80 * PRECISION;
uint256 constant CLOSED_REWARD_PERCENTAGE = 1 * PRECISION;

uint256 constant DEFAULT_REBALANCING_THRESHOLD = 10**23;

uint256 constant EPOCH_DAYS_AMOUNT = 7;

// ClaimVoting ClaimingRegistry
uint256 constant APPROVAL_PERCENTAGE = 66 * PRECISION;
uint256 constant PENALTY_THRESHOLD = 11 * PRECISION;
uint256 constant QUORUM = 10 * PRECISION;
uint256 constant CALCULATION_REWARD_PER_DAY = PRECISION;
uint256 constant PERCENTAGE_50 = 50 * PRECISION;
uint256 constant PENALTY_PERCENTAGE = 10 * PRECISION;
uint256 constant UNEXPOSED_PERCENTAGE = 1 * PRECISION;

// PolicyBook
uint256 constant MINUMUM_COVERAGE = 100 * DECIMALS18; // 100 STBL
uint256 constant ANNUAL_COVERAGE_TOKENS = MINUMUM_COVERAGE * 10; // 1000 STBL

uint256 constant PREMIUM_DISTRIBUTION_EPOCH = 1 days;
uint256 constant MAX_PREMIUM_DISTRIBUTION_EPOCHS = 90;
// policy
uint256 constant EPOCH_DURATION = 1 weeks;
uint256 constant MAXIMUM_EPOCHS = SECONDS_IN_THE_YEAR / EPOCH_DURATION;
uint256 constant MAXIMUM_EPOCHS_FOR_COMPOUND_LIQUIDITY = 5; //5 epoch
uint256 constant VIRTUAL_EPOCHS = 1;
// demand
uint256 constant DEMAND_EPOCH_DURATION = 1 days;
uint256 constant DEMAND_MAXIMUM_EPOCHS = SECONDS_IN_THE_YEAR / DEMAND_EPOCH_DURATION;
uint256 constant MINIMUM_EPOCHS = SECONDS_IN_THE_MONTH / DEMAND_EPOCH_DURATION;

uint256 constant PERIOD_DURATION = 30 days;
uint256 constant MAX_WITHDRAWAL_REQUESTS = 200;

enum Networks {ETH, BSC, POL}

/// @dev unchecked increment
function uncheckedInc(uint256 i) pure returns (uint256) {
    unchecked {return i + 1;}
}

/// @dev unchecked decrement
function uncheckedDec(uint256 i) pure returns (uint256) {
    unchecked {return i - 1;}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../libraries/SafeMath.sol";

/// @notice the intention of this library is to be able to easily convert
///     one amount of tokens with N decimal places
///     to another amount with M decimal places
library DecimalsConverter {
    using SafeMath for uint256;

    function convert(
        uint256 amount,
        uint256 baseDecimals,
        uint256 destinationDecimals
    ) internal pure returns (uint256) {
        if (baseDecimals > destinationDecimals) {
            amount = amount.uncheckedDiv(10**(baseDecimals.uncheckedSub(destinationDecimals)));
        } else if (baseDecimals < destinationDecimals) {
            amount = amount.mul(10**(destinationDecimals.uncheckedSub(baseDecimals)));
        }

        return amount;
    }

    function convertTo18(uint256 amount, uint256 baseDecimals) internal pure returns (uint256) {
        if (baseDecimals == 18) return amount;
        return convert(amount, baseDecimals, 18);
    }

    function convertFrom18(uint256 amount, uint256 destinationDecimals)
        internal
        pure
        returns (uint256)
    {
        if (destinationDecimals == 18) return amount;
        return convert(amount, 18, destinationDecimals);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.7;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * COPIED FROM https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.5/contracts/utils/math/SafeMath.sol
 * customize try functions to return one value which is uint256 instead of return tupple
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return 0;
            return c;
        }
    }

    function uncheckedAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {return a + b;}
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {
            if (b > a) return 0;
            return a - b;
        }
    }

    function uncheckedSub(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {return a - b;}
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return 0;
            uint256 c = a * b;
            if (c / a != b) return 0;
            return c;
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {
            if (b == 0) return 0;
            return a / b;
        }
    }

    function uncheckedDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {return a / b;}
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {
            if (b == 0) return 0;
            return a % b;
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../Globals.sol";

interface IContractsRegistry {
    function getAMMRouterContract() external view returns (address);

    function getAMMDEINToETHPairContract() external view returns (address);

    function getPriceFeedContract() external view returns (address);

    function getWETHContract() external view returns (address);

    function getUSDTContract() external view returns (address);

    function getBMIContract() external view returns (address);

    function getDEINContract() external view returns (address);

    function getPolicyBookRegistryContract() external view returns (address);

    function getPolicyBookFabricContract() external view returns (address);

    function getBMICoverStakingContract() external view returns (address);

    function getBMITreasury() external view returns (address);

    function getDEINCoverStakingContract() external view returns (address);

    function getBMICoverStakingViewContract() external view returns (address);

    function getDEINTreasuryContract() external view returns (address);

    function getRewardsGeneratorContract() external view returns (address);

    function getDEINRewardsGeneratorContract() external view returns (address);

    function getLiquidityBridgeContract() external view returns (address);

    function getClaimingRegistryContract() external view returns (address);

    function getPolicyRegistryContract() external view returns (address);

    function getLiquidityRegistryContract() external view returns (address);

    function getClaimVotingContract() external view returns (address);

    function getRewardPoolContract() external view returns (address);

    function getCompoundPoolContract() external view returns (address);

    function getLeveragePortfolioViewContract() external view returns (address);

    function getCapitalPoolContract() external view returns (address);

    function getPolicyBookAdminContract() external view returns (address);

    function getPolicyQuoteContract() external view returns (address);

    function getBMIStakingContract() external view returns (address);

    function getDEINStakingContract() external view returns (address);

    function getDEINStakingViewContract() external view returns (address);

    function getDEINNFTStakingContract() external view returns (address);

    function getSTKBMIContract() external view returns (address);

    function getStkBMIStakingContract() external view returns (address);

    function getLiquidityMiningStakingETHContract() external view returns (address);

    function getLiquidityMiningStakingUSDTContract() external view returns (address);

    function getReputationSystemContract() external view returns (address);

    function getDefiProtocol1Contract() external view returns (address);

    function getAaveLendPoolAddressProvdierContract() external view returns (address);

    function getAaveATokenContract() external view returns (address);

    function getDefiProtocol2Contract() external view returns (address);

    function getCompoundCTokenContract() external view returns (address);

    function getCompoundComptrollerContract() external view returns (address);

    function getDefiProtocol3Contract() external view returns (address);

    function getYearnVaultContract() external view returns (address);

    function getYieldGeneratorContract() external view returns (address);

    function getShieldMiningContract() external view returns (address);

    function getDemandBookContract() external view returns (address);

    function getDemandBookLiquidityContract() external view returns (address);

    function getSwapEventContract() external view returns (address);

    function getVestingContract() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
pragma experimental ABIEncoderV2;

interface IDemandBookLiquidity {
    struct ProviderInfo {
        uint256 liquidityAmount;
        bool isRewardWithdrawn;
    }

    struct LiquidityWithdrawalInfo {
        uint256 liquidityAmount;
        uint256 readyToWithdrawDate;
    }

    enum WithdrawalStatus {NONE, PENDING, READY}

    function liquidityWithdrawalInfo(uint256 demandIndex, address _provider)
        external
        view
        returns (uint256 liquidityAmount, uint256 readyToWithdrawDate);

    function addLiquidity(uint256 demandIndex, uint256 _liquidityAmount) external;

    function transferFundsAtValidation(uint256 _liquidityAmount, uint256 _protocolFeeAmount)
        external;

    function refundPremium(address _demander, uint256 _premiumLoss) external;

    function requestLiquidityWithdrawal(uint256 demandIndex) external;

    function getLiquidityWithdrawalStatus(uint256 demandIndex, address _provider)
        external
        view
        returns (WithdrawalStatus);

    function getWithdrawlRequestProvidersListCount() external view returns (uint256);

    function getAllPendingWithdrawalRequestsAmount(bool isRebalancing, uint256 _limit)
        external
        view
        returns (uint256 totalLiquidityAmount, uint256 count);

    function withdrawLiquidity(uint256 demandIndex) external;

    function calculateReward(uint256 demandIndex, address _provider)
        external
        view
        returns (uint256);

    function calculateExpectedReward(uint256 demandIndex, uint256 _liquidityAmount)
        external
        view
        returns (uint256);

    function getReward(uint256[] memory demandIndexes) external;

    function withdrawPremium(uint256 demandIndex) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./IClaimingRegistry.sol";

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

interface IDemandBook {
    struct DemandInfo {
        address demander;
        address protocol;
        uint256 coverageAmount;
        uint256 depositedLiquidity; // total deposited liquidity
        uint256 currentLiquidity; // total deposited liquidity minus lost amount in case of liquidity withdrawal, refund claim and defi loss
        uint256 premiumAmount; // premiumAmount = rewardAmount + protocolFeeAmount
        uint256 protocolFeeAmount;
        bool isPremiumWithdrawn;
        uint256 epochAmount; // in days
        uint256 creationTime;
        uint256 startTime;
        uint256 endTime;
    }

    struct PublicDemandInfo {
        uint256 demandIndex;
        address demander;
        address protocol;
        uint256 coverageAmount;
        uint256 currentLiquidity;
        uint256 premiumAmount; // premiumAmount = rewardAmount + protocolFeeAmount
        uint256 rewardAmount;
        uint256 epochAmount;
        uint256 creationTime;
        uint256 startTime;
        uint256 endTime;
        DemandStatus status;
        uint256 time;
    }

    enum ListOption {ALL, CREATED, INVESTED}
    enum DemandStatus {OPEN, PENDING, CLOSED, ACTIVE, ENDED} // ACTIVE = VALID + EXPIRED

    function OPEN_PERIOD() external view returns (uint256);

    function PENDING_PERIOD() external view returns (uint256);

    function STILL_CLAIMABLE_FOR() external view returns (uint256);

    function demandExists(uint256 demandIndex) external view returns (bool);

    function demandInfo(uint256 demandIndex)
        external
        view
        returns (
            address demander,
            address protocol,
            uint256 coverageAmount,
            uint256 depositedLiquidity,
            uint256 currentLiquidity,
            uint256 premiumAmount,
            uint256 protocolFeeAmount,
            bool isPremiumWithdrawn,
            uint256 epochAmount,
            uint256 creationTime,
            uint256 startTime,
            uint256 endTime
        );

    function getDemandAmountInfo(uint256 demandIndex)
        external
        view
        returns (
            uint256 coverageAmount,
            uint256 depositedLiquidity,
            uint256 currentLiquidity,
            uint256 premiumAmount,
            uint256 protocolFeeAmount,
            uint256 rewardAmount
        );

    function getDemandDemanderInfo(uint256 demandIndex)
        external
        view
        returns (address demander, bool isPremiumWithdrawn);

    function isDemandActive(address demander, uint256 demandIndex) external view returns (bool);

    function getDemandStatus(uint256 demandIndex) external view returns (DemandStatus status);

    function getDemandIndex(address _demander, address _protocol) external view returns (uint256);

    function demandStartTime(uint256 demandIndex) external view returns (uint256);

    function countAllDemands() external view returns (uint256);

    function countAllValidatedDemands() external view returns (uint256);

    function countCreatedDemands(address _demander) external view returns (uint256);

    function countInvestedDemands(address _provider) external view returns (uint256);

    function listValidatedDemands(uint256 offset, uint256 limit)
        external
        view
        returns (uint256[] memory _demandIndexesArr);

    function getListDemands(
        uint256 offset,
        uint256 limit,
        ListOption listOption
    ) external view returns (PublicDemandInfo[] memory publicDemandInfo);

    function createDemand(
        address _protocol,
        uint256 _coverageAmount,
        uint256 _premiumAmount,
        uint256 _epochAmount
    ) external;

    function updateLiquidity(
        uint256 demandIndex,
        address _provider,
        uint256 _liquidityAmount,
        bool _isAddedLiquidity,
        bool _nullCurrentLiquidity
    ) external;

    function updateLiquidity(uint256 demandIndex, uint256 _liquidityLoss) external;

    function validateDemand(uint256 demandIndex) external;

    function forceValidateDemand(uint256 demandIndex) external;

    function updatePremium(uint256 demandIndex) external;

    function getClaimApprovalAmount(uint256 demandIndex) external view returns (uint256);

    function submitClaimAndInitializeVoting(uint256 demandIndex, string calldata evidenceURI)
        external;

    function submitClaimAndInitializeVotingWithPermit(
        uint256 demandIndex,
        string calldata _evidenceURI,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;

    function submitAppealAndInitializeVoting(uint256 demandIndex, string calldata evidenceURI)
        external;

    function submitAppealAndInitializeVotingWithPermit(
        uint256 demandIndex,
        string calldata _evidenceURI,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;

    function commitWithdrawnClaim(uint256 demandIndex) external;

    function endActiveDemand(uint256 demandIndex) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./IPolicyBookFacade.sol";
import "./IClaimingRegistry.sol";

interface ICapitalPool {
    struct PremiumFactors {
        uint256 epochsNumber;
        uint256 premiumPrice;
        uint256 vStblOfCP;
        uint256 poolUtilizationRation;
        uint256 premiumPerDeployment;
        uint256 userLeveragePoolsCount;
        IPolicyBookFacade policyBookFacade;
    }

    enum PoolType {COVERAGE, LEVERAGE, DEMAND}

    function virtualUsdtAccumulatedBalance() external view returns (uint256);

    function liquidityCushionBalance() external view returns (uint256);

    ///@notice disable leveraging
    /// @notice distributes the policybook premiums into pools (CP, LP)
    /// @dev distributes the balances acording to the established percentages
    /// @param _stblAmount amount hardSTBL ingressed into the system
    function addPolicyHoldersHardSTBL(uint256 _stblAmount) external;

    /// @notice distributes the hardSTBL from the coverage providers
    /// @dev emits PoolBalancedUpdated event
    /// @param _stblAmount amount hardSTBL ingressed into the system
    function addCoverageProvidersHardSTBL(uint256 _stblAmount) external;

    /// @notice distributes the hardSTBL from the leverage providers
    /// @dev emits PoolBalancedUpdated event
    /// @param _stblAmount amount hardSTBL ingressed into the system
    function addLeverageProvidersHardSTBL(uint256 _stblAmount) external;

    /// @notice distributes the hardSTBL from the demand liquidity providers
    /// @dev emits PoolBalancedUpdated event
    /// @param _stblAmount amount hardSTBL ingressed into the system
    function addDemandProvidersHardSTBL(uint256 _stblAmount) external;

    /// @notice add instant withdawal amount from defi protocol to the hardSTBL
    /// @param _stblAmount amount hardSTBL returned to the system
    /// @param _accumaltedAmount amount hardstable of defi interest returned to the dein treasury
    function addWithdrawalHardSTBL(uint256 _stblAmount, uint256 _accumaltedAmount) external;

    /// @notice rebalances pools acording to v2 specification and dao enforced policies
    /// @dev  emits PoolBalancesUpdated
    function rebalanceLiquidityCushion() external;

    /// @notice Fullfils policybook claims by transfering the balance to claimer
    /// @param claimProvenance, address of the claimer recieving the withdraw and book provenance
    /// @param _claimAmount uint256 amount to be withdrawn
    function fundClaim(
        IClaimingRegistry.ClaimProvenance calldata claimProvenance,
        uint256 _claimAmount,
        bool takeCommission
    ) external returns (uint256);

    /// @notice Withdraws liquidity from a specific policbybook to the user
    /// @param _sender, address of the user beneficiary of the withdraw
    /// @param _stblAmount uint256 amount to be withdrawn
    /// @param _isLeveragePool bool wether the pool is ULP or CP(policybook)
    function withdrawLiquidity(
        address _sender,
        uint256 _stblAmount,
        bool _isLeveragePool
    ) external returns (uint256);

    /// @notice Withdraws liquidity from a specific policbybook to the user
    /// @param _sender, address of the user beneficiary of the withdraw
    /// @param _stblAmount uint256 amount to be withdrawn
    function withdrawDemandLiquidity(address _sender, uint256 _stblAmount)
        external
        returns (uint256 _actualAmount);

    function rebalanceDuration() external view returns (uint256);

    function getWithdrawPeriod() external view returns (uint256);

    function canRequestWithdraw(uint256 amount) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

interface IClaimVoting {
    enum VoteStatus {ANONYMOUS, EXPOSED, CLOSED}
    enum VotePublicStatus {ANONYMOUS, EXPOSED, TO_RECEIVE, CLOSED}
    enum ListOption {VOTED, AWAITING}

    struct Voting {
        uint256 voteCount;
        uint256 votedAverageWithdrawalAmount;
        uint256 totalStakedVoted;
        uint256 votedYesTotalPower;
        uint256 votedNoTotalPower;
        uint256 votedYesPercentage;
    }

    struct VoteInfo {
        uint256 claimIndex;
        address voter;
        string encryptedVote;
        bytes32 finalHash;
        uint256 votingReputation;
        EnumerableSet.UintSet tokenIDs;
        VoteStatus voteStatus;
        uint256 suggestedAmount;
    }

    struct VotePublicInfo {
        uint256 voteIndex;
        uint256 claimIndex;
        uint256 votingReputation;
        uint256 claimAmount;
        VotePublicStatus votePublicStatus;
        uint256 suggestedAmount;
        uint256 timeRemaining;
        uint256 deinReward;
        uint256 deinPenalty;
        uint256 newReputation;
    }

    function getVotesCount(uint256 claimIndex) external view returns (uint256 countVoteOnClaim);

    function getRepartition(uint256 claimIndex)
        external
        view
        returns (uint256 yesPercentage, uint256 noPercentage);

    function canUnlock(uint256 tokenID, address user) external view returns (bool);

    function canVote(uint256 claimIndex, address voter) external view returns (bool);

    function canExpose(uint256 claimIndex, address voter) external view returns (bool);

    function canReceive(uint256 claimIndex, address voter) external view returns (bool);

    /// @notice anonymously vote
    function anonymouslyVoteBatch(
        uint256[] calldata claimIndexes,
        bytes32[] calldata finalHashes,
        string[] calldata encryptedVotes,
        uint256[] calldata tokenIDs
    ) external;

    /// @notice expose vote
    function exposeVoteBatch(
        uint256[] calldata claimIndexes,
        uint256[] calldata suggestedAmounts,
        bytes32[] calldata hashedSignaturesOfClaims,
        bool[] calldata isConfirmed
    ) external;

    /// @notice resolve voting, only access by ClaimingRegistry
    function resolveVoting(uint256 claimIndex)
        external
        returns (
            uint256 totalStakedVoted,
            uint256 votedYesPercentage,
            uint256 claimRefund
        );

    /// @notice receive vote results
    function receiveVoteResultBatch(uint256[] calldata claimIndexes) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./IPolicyBookFabric.sol";

interface IClaimingRegistry {
    enum Provenance {POLICY, DEMAND}
    enum BookStatus {UNCLAIMABLE, CAN_CLAIM, CAN_APPEAL}

    enum ClaimStatus {PENDING, ACCEPTED, DENIED, REJECTED, EXPIRED}
    enum ClaimPublicStatus {VOTING, EXPOSURE, REVEAL, ACCEPTED, DENIED, REJECTED, EXPIRED}

    enum WithdrawalStatus {NONE, PENDING, READY}

    enum ListOption {ALL, MINE}

    struct ClaimInfo {
        ClaimProvenance claimProvenance;
        string evidenceURI;
        uint256 dateStart;
        uint256 dateEnd;
        bool appeal;
        ClaimStatus claimStatus;
        uint256 claimAmount;
        uint256 claimRefund;
        uint256 lockedAmount;
        uint256 rewardAmount;
    }

    struct PublicClaimInfo {
        uint256 claimIndex;
        ClaimProvenance claimProvenance;
        string evidenceURI;
        uint256 dateStart;
        bool appeal;
        ClaimPublicStatus claimPublicStatus;
        uint256 claimAmount;
        uint256 claimRefund;
        uint256 timeRemaining;
        bool canVote;
        bool canExpose;
        bool canCalculate;
        bool canWithdrawLocked;
        uint256 calculationReward;
        uint256 votesCount;
        uint256 repartitionYES;
        uint256 repartitionNO;
    }

    struct ClaimProvenance {
        Provenance provenance;
        address claimer;
        address bookAddress; // policy address or DemandBook address
        uint256 demandIndex; // in case it's a demand
    }

    struct ClaimWithdrawalInfo {
        uint256 readyToWithdrawDate;
        bool committed;
    }

    function claimInfo(uint256 claimIndex)
        external
        view
        returns (
            ClaimProvenance memory claimProvenance,
            string memory evidenceURI,
            uint256 dateStart,
            uint256 dateEnd,
            bool appeal,
            ClaimStatus claimStatus,
            uint256 claimAmount,
            uint256 lockedAmount,
            uint256 claimRefund,
            uint256 rewardAmount
        );

    /// @notice returns anonymous voting duration
    function anonymousVotingDuration() external view returns (uint256);

    /// @notice returns the whole voting duration
    function votingDuration() external view returns (uint256);

    /// @notice returns claim index
    function getClaimIndex(ClaimProvenance calldata claimProvenance)
        external
        view
        returns (uint256);

    /// @notice returns current status of a claim
    function getClaimStatus(uint256 claimIndex) external view returns (ClaimStatus claimStatus);

    /// @notice returns claim provenance
    function getClaimProvenance(uint256 claimIndex) external view returns (ClaimProvenance memory);

    /// @notice returns claim start date
    function getClaimDateStart(uint256 claimIndex) external view returns (uint256 dateStart);

    /// @notice returns claim end date
    function getClaimDateEnd(uint256 claimIndex) external view returns (uint256 dateEnd);

    /// @notice returns claim amounts
    function getClaimAmounts(uint256 claimIndex)
        external
        view
        returns (
            uint256 claimAmount,
            uint256 lockedAmount,
            uint256 rewardAmount
        );

    function isClaimAppeal(uint256 claimIndex) external view returns (bool);

    function isClaimAnonymouslyVotable(uint256 claimIndex) external view returns (bool);

    function isClaimExposablyVotable(uint256 claimIndex) external view returns (bool);

    function isClaimResolved(uint256 claimIndex) external view returns (bool);

    function claimsToRefundCount() external view returns (uint256);

    function updateImageUriOfClaim(uint256 claimIndex, string calldata newEvidenceURI) external;

    function canClaim(ClaimProvenance calldata claimProvenance) external view returns (bool);

    function canAppeal(ClaimProvenance calldata claimProvenance) external view returns (bool);

    function submitClaim(
        ClaimProvenance calldata claimProvenance,
        string calldata evidenceURI,
        uint256 cover,
        bool isAppeal
    ) external;

    function calculateResult(uint256 claimIndex) external;

    function getAllPendingClaimsAmount(
        bool isRebalancing,
        uint256 limit,
        address bookAddress
    ) external view returns (uint256 totalClaimsAmount);

    function withdrawClaim(uint256 claimIndex) external;

    function canBuyNewBook(ClaimProvenance calldata claimProvenance) external;

    function getBookStatus(ClaimProvenance memory claimProvenance)
        external
        view
        returns (BookStatus);

    function hasProcedureOngoing(address bookAddress, uint256 demandIndex)
        external
        view
        returns (bool);

    function isPolicyOnProcedure(address policyBookAddress, address userAddress)
        external
        view
        returns (bool isOnProcedure);

    function withdrawLockedAmount(uint256 claimIndex) external;

    function rewardForVoting(address voter, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IPolicyBookAdmin {
    enum PoolTypes {POLICY_BOOK, POLICY_FACADE, LEVERAGE_POOL}

    function maxEpoch() external view returns (uint256);

    function demandMaxEpoch() external view returns (uint256);

    function demandProtocolFee() external view returns (uint256);

    function getProtocolFee(bool isWhitelisted) external view returns (uint256 _protocolFee);

    function getUpgrader() external view returns (address);

    function getImplementationOfPolicyBook(address policyBookAddress) external returns (address);

    function getImplementationOfPolicyBookFacade(address policyBookFacadeAddress)
        external
        returns (address);

    function getCurrentPolicyBooksImplementation() external view returns (address);

    function getCurrentPolicyBooksFacadeImplementation() external view returns (address);

    function getCurrentUserLeverageImplementation() external view returns (address);

    /// @notice It blacklists or whitelists a PolicyBook. Only whitelisted PolicyBooks can
    ///         receive stakes and funds
    /// @param policyBookAddress PolicyBook address that will be whitelisted or blacklisted
    /// @param whitelisted true to whitelist or false to blacklist a PolicyBook
    function whitelist(address policyBookAddress, bool whitelisted) external;

    /// @notice Whitelist distributor address. Commission fee is 2-5% of the Premium
    ///         It comes from the Protocol’s fee part
    /// @dev If commission fee is 5%, so _distributorFee = 5
    /// @param _distributor distributor address that will receive funds
    /// @param _distributorFee distributor fee amount
    function whitelistDistributor(address _distributor, uint256 _distributorFee) external;

    /// @notice Removes a distributor address from the distributor whitelist
    /// @param _distributor distributor address that will be blacklist
    function blacklistDistributor(address _distributor) external;

    /// @notice Distributor commission fee is 2-5% of the Premium
    ///         It comes from the Protocol’s fee part
    /// @dev If max commission fee is 5%, so _distributorFeeCap = 5. Default value is 5
    /// @param _distributor address of the distributor
    /// @return true if address is a whitelisted distributor
    function isWhitelistedDistributor(address _distributor) external view returns (bool);

    /// @notice Distributor commission fee is 2-5% of the Premium
    ///         It comes from the Protocol’s fee part
    /// @dev If max commission fee is 5%, so _distributorFeeCap = 5. Default value is 5
    /// @param _distributor address of the distributor
    /// @return distributor fee value. It is distributor commission
    function distributorFees(address _distributor) external view returns (uint256);

    /// @notice Used to get a list of whitelisted distributors
    /// @dev If max commission fee is 5%, so _distributorFeeCap = 5. Default value is 5
    /// @return _distributors a list containing distritubors addresses
    /// @return _distributorsFees a list containing distritubors fees
    function listDistributors(uint256 offset, uint256 limit)
        external
        view
        returns (address[] memory _distributors, uint256[] memory _distributorsFees);

    /// @notice Returns number of whitelisted distributors, access: ANY
    function countDistributors() external view returns (uint256);

    /// @notice sets the policybookFacade mpls values
    /// @param _facadeAddress address of the policybook facade
    /// @param _leveragePoolMPL uint256 value of the user leverage mpl;
    function setPolicyBookFacadeMPLs(address _facadeAddress, uint256 _leveragePoolMPL) external;

    /// @notice sets the policybookFacade mpls values
    /// @param _facadeAddress address of the policybook facade
    /// @param _newRebalancingThreshold uint256 Threshold for amount of liquidity changes that trigger the leverage rebalancing
    function setPolicyBookFacadeRebalancingThreshold(
        address _facadeAddress,
        uint256 _newRebalancingThreshold
    ) external;

    /// @notice sets current pricing model
    /// @param _facadeAddress address of the policybook facade
    /// @param _currentPricingModel uint256 is the pricing model index applied to the pool
    function setPolicyBookFacadePricingModel(address _facadeAddress, uint256 _currentPricingModel)
        external;

    function setLeveragePortfolioRebalancingThreshold(
        address _LeveragePoolAddress,
        uint256 _newRebalancingThreshold
    ) external;

    function setLeveragePortfolioProtocolConstant(
        address _LeveragePoolAddress,
        uint256 _targetUR,
        uint256 _d_ProtocolConstant,
        uint256 _a1_ProtocolConstant,
        uint256 _a2_ProtocolConstant,
        uint256 _max_ProtocolConstant
    ) external;

    function setUserLeverageMaxCapacities(address _userLeverageAddress, uint256 _maxCapacities)
        external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../interfaces/IContractsRegistry.sol";

abstract contract AbstractDependant {
    /// @dev keccak256(AbstractDependant.setInjector(address)) - 1
    bytes32 private constant _INJECTOR_SLOT =
        0xd6b8f2e074594ceb05d47c27386969754b6ad0c15e5eb8f691399cd0be980e76;

    modifier onlyInjectorOrZero() {
        address _injector = injector();

        require(_injector == address(0) || _injector == msg.sender, "Dependant: Not an injector");
        _;
    }

    function setInjector(address _injector) external onlyInjectorOrZero {
        bytes32 slot = _INJECTOR_SLOT;

        assembly {
            sstore(slot, _injector)
        }
    }

    /// @dev has to apply onlyInjectorOrZero() modifier
    function setDependencies(IContractsRegistry) external virtual;

    function injector() public view returns (address _injector) {
        bytes32 slot = _INJECTOR_SLOT;

        assembly {
            _injector := sload(slot)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IPriceFeed {
    enum Token {DEIN, ETH}

    function howManyDEINsInUSDT(uint256 usdtAmount) external view returns (uint256);

    function howManyUSDTsInDEIN(uint256 deinAmount) external view returns (uint256);

    function howManyETHsInUSDT(uint256 usdtAmount) external view returns (uint256);

    function howManyUSDTsInETH(uint256 ethAmount) external view returns (uint256);

    function updateTokensPrice() external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

/**
 * COPIED FROM https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/tree/release-v4.5/contracts/drafts
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

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
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
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
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
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
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

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
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
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
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
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

        /// @solidity memory-safe-assembly
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
     * @dev Returns the number of values in the set. O(1).
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

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
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
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
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
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

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

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

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

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

    function safePermit(
        IERC20Permit token,
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
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
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
pragma solidity ^0.8.7;

import "../Globals.sol";

interface IPolicyBookFabric {
    /// @dev update getContractTypes() in RewardGenerator each time this enum is modified
    enum ContractType {CONTRACT, STABLECOIN, SERVICE, EXCHANGE, VARIOUS, CUSTODIAN}

    /// @notice Create new Policy Book contract, access: ANY
    ///@notice disable SM //address _shieldMiningToken
    /// @param _insuranceContracts is Contracts to create policy book for
    /// @param _insuranceContractsNetworks is network of the insurance contract
    /// @param _contractType is Contract to create policy book for
    /// @param _description is bmiXCover token desription for this policy book
    /// @param _projectSymbol replaces x in bmiXCover token symbol
    /// @param _initialDeposit is an amount user deposits on creation (addLiquidity())
    /// @return _policyBook is address of created contract
    function create(
        address[] calldata _insuranceContracts,
        Networks[] calldata _insuranceContractsNetworks,
        ContractType _contractType,
        string calldata _description,
        string calldata _projectSymbol,
        uint256 _initialDeposit
    ) external returns (address);

    function createLeveragePools(
        ContractType _contractType,
        string calldata _description,
        string calldata _projectSymbol
    ) external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./IPolicyBook.sol";
import "./IPolicyBookFabric.sol";
import "./ILeveragePool.sol";

import "../Globals.sol";

interface IPolicyBookFacade {
    struct InsuranceContract {
        Networks networkId;
        address insuranceContract;
    }

    function policyBook() external view returns (IPolicyBook);

    function userLiquidity(address account) external view returns (uint256);

    /// @notice leverage funds deployed by user leverage pool
    function LUuserLeveragePool(address userLeveragePool) external view returns (uint256);

    /// @notice total leverage funds deployed to the pool sum of (VUreinsurnacePool,LUreinsurnacePool,LUuserLeveragePool)
    function totalLeveragedLiquidity() external view returns (uint256);

    function userleveragedMPL() external view returns (uint256);

    function rebalancingThreshold() external view returns (uint256);

    function currentPricingModel() external view returns (uint256);

    /// @notice policyBookFacade initializer
    /// @param pbProxy polciybook address upgreadable cotnract.
    function __PolicyBookFacade_init(
        address[] calldata _insuranceContract,
        Networks[] calldata _insuranceContractsNetworks,
        address pbProxy,
        address liquidityProvider,
        uint256 initialDeposit
    ) external;

    function updateInsuranceContracts(
        Networks _network,
        address currentInsuranceAddress,
        address _newInsuranceAddress
    ) external;

    /// @notice Let user to buy policy by supplying stable coin, access: ANY
    /// @param _epochsNumber period policy will cover
    /// @param _coverTokens amount paid for the coverage
    function buyPolicy(uint256 _epochsNumber, uint256 _coverTokens) external;

    /// @param _holder who owns coverage
    /// @param _epochsNumber period policy will cover
    /// @param _coverTokens amount paid for the coverage
    function buyPolicyFor(
        address _holder,
        uint256 _epochsNumber,
        uint256 _coverTokens
    ) external;

    /// @param _epochsNumber period policy will cover
    /// @param _coverTokens amount paid for the coverage
    /// @param _distributor if it was sold buy a whitelisted distributor, it is distributor address to receive fee (commission)
    function buyPolicyFromDistributor(
        uint256 _epochsNumber,
        uint256 _coverTokens,
        address _distributor
    ) external;

    /// @param _buyer who is buying the coverage
    /// @param _epochsNumber period policy will cover
    /// @param _coverTokens amount paid for the coverage
    /// @param _distributor if it was sold buy a whitelisted distributor, it is distributor address to receive fee (commission)
    function buyPolicyFromDistributorFor(
        address _buyer,
        uint256 _epochsNumber,
        uint256 _coverTokens,
        address _distributor
    ) external;

    function addLiquidityFor(
        address _liquidityHolderAddr,
        uint256 _liquidityAmount,
        uint256 _lock
    ) external;

    /// @notice Let user to add liquidity by supplying stable coin and stake it,
    /// @dev access: ANY
    function addLiquidity(uint256 _liquidityAmount, uint256 _lock) external;

    /// @notice Let user to withdraw deposited liqiudity, access: ANY
    function withdrawLiquidity() external;

    /// @notice submits new claim of the policy book
    function submitClaimAndInitializeVoting(string calldata evidenceURI) external;

    function submitClaimAndInitializeVotingWithPermit(
        string calldata evidenceURI,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;

    /// @notice submits new appeal claim of the policy book
    function submitAppealAndInitializeVoting(string calldata evidenceURI) external;

    function submitAppealAndInitializeVotingWithPermit(
        string calldata evidenceURI,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;

    function getAvailableDEINXWithdrawableAmount(address _userAddr)
        external
        view
        returns (uint256);

    function getPremiumDistributionEpoch() external view returns (uint256);

    function getPremiumsDistribution(uint256 lastEpoch, uint256 currentEpoch)
        external
        view
        returns (
            int256 currentDistribution,
            uint256 distributionEpoch,
            uint256 newTotalLiquidity
        );

    /// @notice forces an update of RewardsGenerator multiplier
    function forceUpdateDEINCoverStakingRewardMultiplier() external;

    /// @notice view function to get precise policy price
    /// @param _holder the address of the holder
    /// @param _epochsNumber is number of epochs to cover
    /// @param _coverTokens is number of tokens to cover
    /// @param newTotalCoverTokens is number of total tokens cover
    /// @param newTotalLiquidity is number of total liquidity
    /// @param _availableCompoundLiquidity the available CompoundLiquidity for the pool
    /// @param _deployedCompoundedLiquidity the deployed amount from compound liquidity for the cover
    /// @return totalSeconds is number of seconds to cover
    /// @return totalPrice is the policy price which will pay by the buyer
    function getPolicyPrice(
        address _holder,
        uint256 _epochsNumber,
        uint256 _coverTokens,
        uint256 newTotalCoverTokens,
        uint256 newTotalLiquidity,
        uint256 _availableCompoundLiquidity,
        uint256 _deployedCompoundedLiquidity
    ) external view returns (uint256 totalSeconds, uint256 totalPrice);

    function getPolicyPrice(uint256 _epochsNumber, uint256 _coverTokens)
        external
        view
        returns (uint256 totalSeconds, uint256 totalPrice);

    function secondsToEndCurrentEpoch() external view returns (uint256);

    /// @notice deploy leverage funds (RP lStable, ULP lStable)
    /// @param  deployedAmount uint256 the deployed amount to be added or substracted from the total liquidity
    function deployLeverageFundsAfterRebalance(uint256 deployedAmount) external;

    ///@dev in case ur changed of the pools by commit a claim or policy expired
    function reevaluateProvidedLeverageStable() external;

    /// @notice set the MPL for the leverage pool
    /// @param _leveragePoolMPL uint256 value of the user leverage MPL
    function setMPLs(uint256 _leveragePoolMPL) external;

    /// @notice sets the rebalancing threshold value
    /// @param _newRebalancingThreshold uint256 rebalancing threshhold value
    function setRebalancingThreshold(uint256 _newRebalancingThreshold) external;

    /// @notice sets current pricing model
    /// @param _currentPricingModel uint256 is the pricing model index applied to the pool
    function setPricingModel(uint256 _currentPricingModel) external;

    /// @notice returns how many DEIN tokens needs to approve in order to submit a claim
    function getClaimApprovalAmount(address user) external view returns (uint256);

    /// @notice upserts a withdraw request
    /// @dev prevents adding a request if an already pending or ready request is open.
    /// @param _tokensToWithdraw uint256 amount of tokens to withdraw
    function requestWithdrawal(uint256 _tokensToWithdraw) external;

    function requestWithdrawalWithPermit(
        uint256 _tokensToWithdraw,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;

    function listUserLeveragePools(uint256 offset, uint256 limit)
        external
        view
        returns (address[] memory _userLeveragePools);

    function countUserLeveragePools() external view returns (uint256);

    /// @notice function to get precise current cover, liquidity ,  available Compounded Liquidity
    function getNewCoverAndLiquidity()
        external
        view
        returns (
            uint256 newTotalCoverTokens,
            uint256 newTotalLiquidity,
            uint256 availableCompoundLiquidity
        );

    function getAPY() external view returns (uint256);

    /// @notice Getting user stats, access: ANY
    function userStats(address _user) external view returns (IPolicyBook.PolicyHolder memory);

    /// @notice Getting number stats, access: ANY
    /// @return _maxCapacities is a max token amount that a user can buy
    /// @return _availableCompoundLiquidity the available CompoundLiquidity for the pool which increases the pool capacity
    /// @return _totalSTBLLiquidity is PolicyBook's liquidity
    /// @return _totalLeveragedLiquidity is PolicyBook's leveraged liquidity
    /// @return _annualProfitYields is its APY
    /// @return _estMonthlyCost_UR is estimate monthly cost percentage of cover tokens that is required to be paid for 1 month of insurance based on UR
    /// @return _estMonthlyCost_CUR is estimate monthly cost percentage of cover tokens that is required to be paid for 1 month of insurance based on CUR
    function numberStats()
        external
        view
        returns (
            uint256 _maxCapacities,
            uint256 _availableCompoundLiquidity,
            uint256 _totalSTBLLiquidity,
            uint256 _totalLeveragedLiquidity,
            uint256 _annualProfitYields,
            uint256 _estMonthlyCost_UR,
            uint256 _estMonthlyCost_CUR
        );

    /// @notice Getting info, access: ANY
    /// @return _symbol is the symbol of PolicyBook (deinXCover)
    /// @return _insuredContract is an addres of insured contract
    /// @return _contractType is a type of insured contract
    /// @return _whitelisted is a state of whitelisting
    function info()
        external
        view
        returns (
            string memory _symbol,
            address _insuredContract,
            IPolicyBookFabric.ContractType _contractType,
            bool _whitelisted
        );

    function listInsuranceContracts()
        external
        view
        returns (InsuranceContract[] memory _insuranceContracts);

    function countInsuranceContracts() external view returns (uint256);

    ///@notice migrate insurance contracts from single state to a list ,to be removed before release
    /// migrate pricing modelfrom bool state to index of pricing model
    ///@dev migration function
    function migrate() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./IPolicyBookFabric.sol";
import "./IClaimingRegistry.sol";
import "./IPolicyBookFacade.sol";

interface IPolicyBook {
    enum WithdrawalStatus {NONE, PENDING, READY, EXPIRED}

    enum Operator {ADD, SUB}

    struct PolicyHolder {
        uint256 coverTokens;
        uint256 startEpochNumber;
        uint256 endEpochNumber;
        uint256 paid;
        uint256 protocolFee;
    }

    struct WithdrawalInfo {
        uint256 withdrawalAmountDEINx;
        uint256 withdrawalAmountSTBL;
        uint256 readyToWithdrawDate;
        bool withdrawalAllowed;
    }

    struct BuyPolicyParameters {
        address buyer; // who is transferring funds
        address holder; // who owns coverage
        uint256 epochsNumber; // period policy will cover
        uint256 coverTokens; // amount paid for the coverage
        uint256 pendingWithdrawalAmount; // pending Withdrawal Amount
        uint256 deployedCompoundedLiquidity; // used compound liquidity in the policy
        uint256 compoundLiquidity; // available compound liquidity for the pool
        uint256 distributorFee; // distributor fee (commission). It can't be greater than PROTOCOL_PERCENTAGE
        address distributor; // if it was sold buy a whitelisted distributor, it is distributor address to receive fee (commission)
    }

    function policyHolders(address _holder)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        );

    function policyBookFacade() external view returns (IPolicyBookFacade);

    function stblDecimals() external view returns (uint256);

    function READY_TO_WITHDRAW_PERIOD() external view returns (uint256);

    function whitelisted() external view returns (bool);

    function epochStartTime() external view returns (uint256);

    function lastDistributionEpoch() external view returns (uint256);

    function lastPremiumDistributionEpoch() external view returns (uint256);

    function lastPremiumDistributionAmount() external view returns (int256);

    function epochAmounts(uint256 _epochNo) external view returns (uint256);

    function premiumDistributionDeltas(uint256 _epochNo) external view returns (int256);

    // @TODO: should we let DAO to change contract address?
    /// @notice Returns address of contract this PolicyBook covers, access: ANY
    /// @return _contract is address of covered contract
    function insuranceContractAddress() external view returns (address _contract);

    /// @notice Returns type of contract this PolicyBook covers, access: ANY
    /// @return _type is type of contract
    function contractType() external view returns (IPolicyBookFabric.ContractType _type);

    function totalLiquidity() external view returns (uint256);

    function totalCoverTokens() external view returns (uint256);

    function withdrawalsInfo(address _userAddr)
        external
        view
        returns (
            uint256 _withdrawalAmountDEIN,
            uint256 _withdrawalAmountSTBL,
            uint256 _readyToWithdrawDate,
            bool _withdrawalAllowed
        );

    function __PolicyBook_init(
        address _policyBookFacadeAddress,
        IPolicyBookFabric.ContractType _contractType,
        string calldata _description,
        string calldata _projectSymbol
    ) external;

    function whitelist(bool _whitelisted) external;

    function getEpoch(uint256 time) external view returns (uint256);

    /// @notice get STBL equivalent
    function convertDEINXToSTBL(uint256 _amount) external view returns (uint256);

    /// @notice get DEINX equivalent
    function convertSTBLToDEINX(uint256 _amount) external view returns (uint256);

    /// @notice submits new claim of the policy book
    function submitClaimAndInitializeVoting(
        address policyHolder,
        string calldata evidenceURI,
        bool appeal
    ) external;

    /// @notice updates info on claim when not accepted
    function commitClaim(
        address claimer,
        uint256 claimEndTime,
        IClaimingRegistry.ClaimStatus status
    ) external;

    function commitWithdrawnClaim(address claimer) external;

    /// @notice Let user to buy policy by supplying stable coin, access: ANY
    function buyPolicy(BuyPolicyParameters memory parameters) external returns (uint256);

    /// @notice end active policy from ClaimingRegistry in case of a new bought policy
    function endActivePolicy(address _holder) external;

    function updateEpochsInfo() external;

    /// @notice Let eligible contracts add liqiudity for another user by supplying stable coin
    /// @param _liquidityHolderAddr is address of address to assign cover
    /// @param _liqudityAmount is amount of stable coin tokens to secure
    function addLiquidityFor(address _liquidityHolderAddr, uint256 _liqudityAmount) external;

    /// @notice Let user to add liquidity by supplying stable coin, access: ANY
    /// @param _liquidityBuyerAddr address the one that transfer funds
    /// @param _liquidityHolderAddr address the one that owns liquidity
    /// @param _liquidityAmount uint256 amount to be added on behalf the sender
    /// @param _lock uint256 locking period for staking
    function addLiquidity(
        address _liquidityBuyerAddr,
        address _liquidityHolderAddr,
        uint256 _liquidityAmount,
        uint256 _lock
    ) external returns (uint256);

    function getWithdrawalStatus(address _userAddr) external view returns (WithdrawalStatus);

    function requestWithdrawal(
        uint256 _tokensToWithdraw,
        uint256 _availableSTBLBalance,
        uint256 _pendingWithdrawalAmount,
        address _user
    ) external;

    // function requestWithdrawalWithPermit(
    //     uint256 _tokensToWithdraw,
    //     uint8 _v,
    //     bytes32 _r,
    //     bytes32 _s
    // ) external;

    function unlockTokens() external;

    /// @notice Let user to withdraw deposited liqiudity, access: ANY
    function withdrawLiquidity(address sender)
        external
        returns (uint256 _tokensToWithdraw, uint256 _stblTokensToWithdraw);

    ///@notice for doing defi hard rebalancing, access: policyBookFacade
    function updateLiquidity(uint256 _newLiquidity) external;

    function migrateHashedName(string memory newName) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./IPolicyBookFabric.sol";
import "./IClaimingRegistry.sol";
import "./IPolicyBookFacade.sol";

interface ILeveragePool {
    struct LevFundsFactors {
        uint256 netMPL;
        uint256 netMPLn;
        address policyBookAddr;
    }

    enum WithdrawalStatus {NONE, PENDING, READY, EXPIRED}

    struct WithdrawalInfo {
        uint256 withdrawalAmountDEINx;
        uint256 withdrawalAmountSTBL;
        uint256 readyToWithdrawDate;
        bool withdrawalAllowed;
    }

    struct DEINMultiplierFactors {
        uint256 poolMultiplier;
        uint256 leverageProvided;
        uint256 multiplier;
    }

    function targetUR() external view returns (uint256);

    function d_ProtocolConstant() external view returns (uint256);

    function a1_ProtocolConstant() external view returns (uint256);

    function a2_ProtocolConstant() external view returns (uint256);

    function max_ProtocolConstant() external view returns (uint256);

    /// @return uint256 the amount of vStable stored in the pool
    function totalLiquidity() external view returns (uint256);

    /// @notice Returns type of contract this PolicyBook covers, access: ANY
    /// @return _type is type of contract
    function contractType() external view returns (IPolicyBookFabric.ContractType _type);

    function READY_TO_WITHDRAW_PERIOD() external view returns (uint256);

    function epochStartTime() external view returns (uint256);

    function withdrawalsInfo(address _userAddr)
        external
        view
        returns (
            uint256 _withdrawalAmountDEIN,
            uint256 _withdrawalAmountSTBL,
            uint256 _readyToWithdrawDate,
            bool _withdrawalAllowed
        );

    function __UserLeveragePool_init(
        IPolicyBookFabric.ContractType _contractType,
        string calldata _description,
        string calldata _projectSymbol
    ) external;

    /// @notice deploy lStable from leverage pool using 2 formulas: access by policybook.
    function deployLeverageStableToCoveragePools() external returns (uint256);

    /// @notice set the threshold % for re-evaluation of the lStable provided across all Coverage pools : access by owner
    /// @param threshold uint256 is the reevaluatation threshold
    function setRebalancingThreshold(uint256 threshold) external;

    /// @notice set the protocol constant : access by owner
    /// @param _targetUR uint256 target utitlization ration
    /// @param _d_ProtocolConstant uint256 D protocol constant
    /// @param  _a1_ProtocolConstant uint256 A1 protocol constant
    /// @param  _a2_ProtocolConstant uint256 A2 protocol constant
    /// @param _max_ProtocolConstant uint256 the max % included
    function setProtocolConstant(
        uint256 _targetUR,
        uint256 _d_ProtocolConstant,
        uint256 _a1_ProtocolConstant,
        uint256 _a2_ProtocolConstant,
        uint256 _max_ProtocolConstant
    ) external;

    /// @notice add the portion of 80% of premium to user leverage pool where the leverage provide lstable : access policybook
    /// add the 20% of premium + portion of 80% of premium where reisnurance pool participate in coverage pools (vStable)  : access policybook
    /// @param epochsNumber uint256 the number of epochs which the policy holder will pay a premium for
    /// @param  premiumAmount uint256 the premium amount which is a portion of 80% of the premium
    function addPremium(uint256 epochsNumber, uint256 premiumAmount) external;

    /// @notice Used to get a list of coverage pools which get leveraged , use with count()
    /// @return _coveragePools a list containing policybook addresses
    function listleveragedCoveragePools(uint256 offset, uint256 limit)
        external
        view
        returns (address[] memory _coveragePools);

    /// @notice get count of coverage pools which get leveraged
    function countleveragedCoveragePools() external view returns (uint256);

    function updateLiquidity(uint256 _lostLiquidity) external;

    function forceUpdateDEINCoverStakingRewardMultiplier() external;

    function getEpoch(uint256 time) external view returns (uint256);

    /// @notice get STBL equivalent
    function convertDEINXToSTBL(uint256 _amount) external view returns (uint256);

    /// @notice get DEINX equivalent
    function convertSTBLToDEINX(uint256 _amount) external view returns (uint256);

    /// @notice function to get precise current cover and liquidity
    function getNewCoverAndLiquidity()
        external
        view
        returns (
            uint256 newTotalCoverTokens,
            uint256 newTotalLiquidity,
            uint256 availableCompoundLiquidity
        );

    function updateEpochsInfo() external;

    function secondsToEndCurrentEpoch() external view returns (uint256);

    /// @notice Let user to add liquidity by supplying stable coin, access: ANY
    /// @param _liquidityAmount is amount of stable coin tokens to secure
    /// @param _lock locking period
    function addLiquidity(uint256 _liquidityAmount, uint256 _lock) external;

    function getAvailableDEINXWithdrawableAmount(address _userAddr)
        external
        view
        returns (uint256);

    function getWithdrawalStatus(address _userAddr) external view returns (WithdrawalStatus);

    function requestWithdrawalWithPermit(
        uint256 _tokensToWithdraw,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;

    function requestWithdrawal(uint256 _tokensToWithdraw) external;

    function unlockTokens() external;

    /// @notice Let user to withdraw deposited liqiudity, access: ANY
    function withdrawLiquidity() external;

    function getAPY() external view returns (uint256);

    function whitelisted() external view returns (bool);

    function whitelist(bool _whitelisted) external;

    /// @notice set max total liquidity for the pool
    /// @param _maxCapacities uint256 the max total liquidity
    function setMaxCapacities(uint256 _maxCapacities) external;

    /// @notice Getting number stats, access: ANY
    /// @return _maxCapacities is a max liquidity of the pool
    /// @return _availableCompoundLiquidity is becuase to follow the same function in policy book
    /// @return _totalSTBLLiquidity is PolicyBook's liquidity
    /// @return _totalLeveragedLiquidity is becuase to follow the same function in policy book
    /// @return _annualProfitYields is its APY
    /// @return _estMonthlyCost_UR is becuase to follow the same function in policy book
    /// @return _estMonthlyCost_CUR is becuase to follow the same function in policy book
    function numberStats()
        external
        view
        returns (
            uint256 _maxCapacities,
            uint256 _availableCompoundLiquidity,
            uint256 _totalSTBLLiquidity,
            uint256 _totalLeveragedLiquidity,
            uint256 _annualProfitYields,
            uint256 _estMonthlyCost_UR,
            uint256 _estMonthlyCost_CUR
        );

    /// @notice Getting info, access: ANY
    /// @return _symbol is the symbol of PolicyBook (deinXCover)
    /// @return _insuredContract is an addres of insured contract
    /// @return _contractType is becuase to follow the same function in policy book
    /// @return _whitelisted is a state of whitelisting
    function info()
        external
        view
        returns (
            string memory _symbol,
            address _insuredContract,
            IPolicyBookFabric.ContractType _contractType,
            bool _whitelisted
        );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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
interface IERC20Permit {
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