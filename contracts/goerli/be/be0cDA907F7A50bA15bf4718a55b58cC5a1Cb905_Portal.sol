// SPDX-License-Identifier: MIT

//   ██████╗ ███████╗ ██████╗ ██████╗ ███████╗    ██████╗  ██████╗ ██████╗ ████████╗ █████╗ ██╗
//  ██╔════╝ ██╔════╝██╔═══██╗██╔══██╗██╔════╝    ██╔══██╗██╔═══██╗██╔══██╗╚══██╔══╝██╔══██╗██║
//  ██║  ███╗█████╗  ██║   ██║██║  ██║█████╗      ██████╔╝██║   ██║██████╔╝   ██║   ███████║██║
//  ██║   ██║██╔══╝  ██║   ██║██║  ██║██╔══╝      ██╔═══╝ ██║   ██║██╔══██╗   ██║   ██╔══██║██║
//  ╚██████╔╝███████╗╚██████╔╝██████╔╝███████╗    ██║     ╚██████╔╝██║  ██║   ██║   ██║  ██║███████╗
//   ╚═════╝ ╚══════╝ ╚═════╝ ╚═════╝ ╚══════╝    ╚═╝      ╚═════╝ ╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝╚══════╝
//

pragma solidity =0.8.7;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "./utils/DataStoreUtilsLib.sol";
import "./utils/GeodeUtilsLib.sol";
import "./utils/OracleUtilsLib.sol";
import "./utils/MaintainerUtilsLib.sol";
import "./utils/StakeUtilsLib.sol";

import "../interfaces/IPortal.sol";
import "../interfaces/IgETH.sol";

/**
 * @author Icebear & Crash Bandicoot
 * @title Geode Finance Ethereum Portal: Trustless Dynamic Liquid Staking Pools
 * *
 * @notice Geode Portal provides a first of its kind trustless implementation on LSDs: gETH
 * * * These derivatives are maintained within Portal's functionality.
 *
 * * Global trustlessness is achieved by GeodeUtils, which makes sure that
 * * * every update is approved by a Senate before being effective.
 * * * Senate is elected by the all maintainers.
 *
 * * Local trustlessness is achieved by MiniGovernances, which is used as a withdrawal
 * * * credential contract. However, similar to Portal, upgrade requires the approval of
 * * * local Senate. Isolation Mode (WIP), will allow these contracts to become mini-portals
 * * * and allow the unstaking operations to be done directly, in the future.
 *
 * * StakeUtils contains all the staking related functionalities, including pool management
 * * * and Oracle activities.
 * * * These operations relies on a Dynamic Withdrawal Pool, which is a StableSwap
 * * * pool with a dynamic peg.
 *
 * * * One thing to consider is that currently private pools implementation is WIP, but the overall
 * * * design is done while ensuring it is possible without much changes in the future.
 *
 * @dev refer to DataStoreUtils before reviewing
 * @dev refer to GeodeUtils > Includes the logic for management of Geode Portal with Senate/Governance.
 * @dev refer to StakeUtils > Includes the logic for staking functionality with Withdrawal Pools
 * * * MaintainerUtils is a library used by StakeUtils, handling the maintainer related functionalities
 * * * OracleUtils is a library used by StakeUtils, handling the Oracle related functionalities
 *
 * @notice TYPE: seperates the proposals and related functionality between different ID types.
 * * CURRENTLY RESERVED TYPES on Portal:
 * * * TYPE 0: *invalid*
 * * * TYPE 1: Senate Election
 * * * TYPE 2: Portal Upgrade
 * * * TYPE 3: *gap*
 * * * TYPE 4: Validator Operator
 * * * TYPE 5: Planet (public pool)
 * * * TYPE 6: Comet (private pool)
 * * * TYPE 11: MiniGovernance Upgrade
 *
 * note ctrl+k+2 and ctrl+k+1 then scroll while reading the function names and opening the comments.
 */

contract Portal is
    IPortal,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    ERC1155HolderUpgradeable,
    UUPSUpgradeable
{
    using DataStoreUtils for DataStoreUtils.DataStore;
    using MaintainerUtils for DataStoreUtils.DataStore;
    using GeodeUtils for GeodeUtils.Universe;
    using StakeUtils for StakeUtils.StakePool;
    using OracleUtils for OracleUtils.Oracle;

    /**
     * @dev following events are added to help fellow devs with a better ABI
     */

    /// GeodeUtils EVENTS
    event GovernanceTaxUpdated(uint256 newFee);
    event MaxGovernanceTaxUpdated(uint256 newMaxFee);
    event ControllerChanged(uint256 id, address newCONTROLLER);
    event Proposed(
        uint256 id,
        address CONTROLLER,
        uint256 TYPE,
        uint256 deadline
    );
    event ProposalApproved(uint256 id);
    event ElectorTypeSet(uint256 TYPE, bool isElector);
    event Vote(uint256 proposalId, uint256 electorId);
    event NewSenate(address senate, uint256 senateExpiry);

    /// MaintainerUtils EVENTS
    event IdInitiated(uint256 id, uint256 TYPE);
    event MaintainerChanged(uint256 id, address newMaintainer);
    event MaintainerFeeSwitched(
        uint256 id,
        uint256 fee,
        uint256 effectiveTimestamp
    );

    /// OracleUtils EVENTS
    event Alienated(bytes pubkey);
    event Busted(bytes pubkey);
    event Prisoned(uint256 id, uint256 releaseTimestamp);
    event Released(uint256 id);
    event VerificationIndexUpdated(uint256 validatorVerificationIndex);

    /// StakeUtils EVENTS
    event ValidatorPeriodUpdated(uint256 operatorId, uint256 newPeriod);
    event OperatorApproval(
        uint256 planetId,
        uint256 operatorId,
        uint256 allowance
    );
    event PausedPool(uint256 id);
    event UnpausedPool(uint256 id);
    event ProposeStaked(bytes pubkey, uint256 planetId, uint256 operatorId);
    event BeaconStaked(bytes pubkey);
    event UnstakeSignal(bytes pubkey);

    // Portal Events
    event ContractVersionSet(uint256 version);
    event ParamsUpdated(
        address DEFAULT_gETH_INTERFACE,
        address DEFAULT_DWP,
        address DEFAULT_LP_TOKEN,
        uint256 MAX_MAINTAINER_FEE,
        uint256 BOOSTRAP_PERIOD,
        uint256 PERIOD_PRICE_INCREASE_LIMIT,
        uint256 PERIOD_PRICE_DECREASE_LIMIT,
        uint256 COMET_TAX,
        uint256 BOOST_SWITCH_LATENCY
    );

    // Portal VARIABLES
    /**
     * @notice always refers to the proposal (TYPE2) id.
     * Does NOT increase uniformly like the expected versioning style.
     */
    uint256 public CONTRACT_VERSION;
    DataStoreUtils.DataStore private DATASTORE;
    GeodeUtils.Universe private GEODE;
    StakeUtils.StakePool private STAKEPOOL;

    function initialize(
        address _GOVERNANCE,
        address _gETH,
        address _ORACLE_POSITION,
        address _DEFAULT_gETH_INTERFACE,
        address _DEFAULT_DWP,
        address _DEFAULT_LP_TOKEN,
        address _MINI_GOVERNANCE_POSITION,
        uint256 _GOVERNANCE_TAX,
        uint256 _COMET_TAX,
        uint256 _MAX_MAINTAINER_FEE,
        uint256 _BOOSTRAP_PERIOD
    ) public virtual override initializer {
        __ReentrancyGuard_init();
        __Pausable_init();
        __ERC1155Holder_init();
        __UUPSUpgradeable_init();

        GEODE.SENATE = _GOVERNANCE;
        GEODE.GOVERNANCE = _GOVERNANCE;
        GEODE.GOVERNANCE_TAX = _GOVERNANCE_TAX;
        GEODE.MAX_GOVERNANCE_TAX = _GOVERNANCE_TAX;
        GEODE.SENATE_EXPIRY = type(uint256).max;

        STAKEPOOL.GOVERNANCE = _GOVERNANCE;
        STAKEPOOL.gETH = IgETH(_gETH);
        STAKEPOOL.TELESCOPE.gETH = IgETH(_gETH);
        STAKEPOOL.TELESCOPE.ORACLE_POSITION = _ORACLE_POSITION;
        STAKEPOOL.TELESCOPE.MONOPOLY_THRESHOLD = 20000;

        _updateStakingParams(
            _DEFAULT_gETH_INTERFACE,
            _DEFAULT_DWP,
            _DEFAULT_LP_TOKEN,
            _MAX_MAINTAINER_FEE,
            _BOOSTRAP_PERIOD,
            type(uint256).max,
            type(uint256).max,
            _COMET_TAX,
            3 days
        );

        uint256 _MINI_GOVERNANCE_VERSION = GEODE.newProposal(
            _MINI_GOVERNANCE_POSITION,
            11,
            "mini-v1",
            2 days
        );
        GEODE.approveProposal(DATASTORE, _MINI_GOVERNANCE_VERSION);
        STAKEPOOL.MINI_GOVERNANCE_VERSION = _MINI_GOVERNANCE_VERSION;

        // currently only planet controllers has a say on Senate elections
        GEODE.setElectorType(DATASTORE, 5, true);
        uint256 version_id = GEODE.newProposal(
            _getImplementation(),
            2,
            "V1",
            2 days
        );
        GEODE.approveProposal(DATASTORE, version_id);
        CONTRACT_VERSION = version_id;
        GEODE.approvedUpgrade = address(0);

        emit ContractVersionSet(getVersion());
    }

    /**
     * @dev required by the OZ UUPS module
     * note that there is no Governance check, as upgrades are effective
     * * right after the Senate approval
     */
    function _authorizeUpgrade(address proposed_implementation)
        internal
        virtual
        override
    {
        require(proposed_implementation != address(0));
        require(
            GEODE.isUpgradeAllowed(proposed_implementation),
            "Portal: is not allowed to upgrade"
        );
    }

    function pause() external virtual override {
        require(
            msg.sender == GEODE.GOVERNANCE,
            "Portal: sender not GOVERNANCE"
        );
        _pause();
    }

    function unpause() external virtual override {
        require(
            msg.sender == GEODE.GOVERNANCE,
            "Portal: sender not GOVERNANCE"
        );
        _unpause();
    }

    function getVersion() public view virtual override returns (uint256) {
        return CONTRACT_VERSION;
    }

    function gETH() external view virtual override returns (address) {
        return address(STAKEPOOL.gETH);
    }

    /// @return returns an array of IDs of the given TYPE from Datastore
    function allIdsByType(uint256 _type)
        external
        view
        virtual
        override
        returns (uint256[] memory)
    {
        return DATASTORE.allIdsByType[_type];
    }

    /**
     *                                  ** DataStore Functionalities **
     */

    /// @notice id is keccak(name, type)
    function generateId(string calldata _name, uint256 _type)
        public
        pure
        virtual
        override
        returns (uint256 id)
    {
        id = uint256(keccak256(abi.encodePacked(_name, _type)));
    }

    function readAddressForId(uint256 id, bytes32 key)
        external
        view
        virtual
        override
        returns (address data)
    {
        data = DATASTORE.readAddressForId(id, key);
    }

    function readUintForId(uint256 id, bytes32 key)
        external
        view
        virtual
        override
        returns (uint256 data)
    {
        data = DATASTORE.readUintForId(id, key);
    }

    function readBytesForId(uint256 id, bytes32 key)
        external
        view
        virtual
        override
        returns (bytes memory data)
    {
        data = DATASTORE.readBytesForId(id, key);
    }

    /**
     *                                  ** Geode Functionalities **
     */

    function GeodeParams()
        external
        view
        virtual
        override
        returns (
            address SENATE,
            address GOVERNANCE,
            uint256 GOVERNANCE_TAX,
            uint256 MAX_GOVERNANCE_TAX,
            uint256 SENATE_EXPIRY
        )
    {
        SENATE = GEODE.getSenate();
        GOVERNANCE = GEODE.getGovernance();
        GOVERNANCE_TAX = GEODE.getGovernanceTax();
        MAX_GOVERNANCE_TAX = GEODE.getMaxGovernanceTax();
        SENATE_EXPIRY = GEODE.getSenateExpiry();
    }

    function getProposal(uint256 id)
        external
        view
        virtual
        override
        returns (GeodeUtils.Proposal memory proposal)
    {
        proposal = GEODE.getProposal(id);
    }

    function isUpgradeAllowed(address proposedImplementation)
        external
        view
        virtual
        override
        returns (bool)
    {
        return GEODE.isUpgradeAllowed(proposedImplementation);
    }

    /**
     * @notice GOVERNANCE Functions
     */

    function setGovernanceTax(uint256 newFee)
        external
        virtual
        override
        whenNotPaused
        returns (bool)
    {
        return GEODE.setGovernanceTax(newFee);
    }

    function newProposal(
        address _CONTROLLER,
        uint256 _TYPE,
        bytes calldata _NAME,
        uint256 duration
    ) external virtual override whenNotPaused {
        require(
            msg.sender == GEODE.GOVERNANCE,
            "Portal: sender not GOVERNANCE"
        );
        GEODE.newProposal(_CONTROLLER, _TYPE, _NAME, duration);
    }

    /**
     * @notice SENATE Functions
     */

    function setMaxGovernanceTax(uint256 newMaxFee)
        external
        virtual
        override
        whenNotPaused
        returns (bool)
    {
        return GEODE.setMaxGovernanceTax(newMaxFee);
    }

    function approveProposal(uint256 id)
        external
        virtual
        override
        whenNotPaused
    {
        GEODE.approveProposal(DATASTORE, id);
        if (DATASTORE.readUintForId(id, "TYPE") == 11)
            STAKEPOOL.setMiniGovernanceVersion(DATASTORE, id);
    }

    /**
     * @notice CONTROLLER Functions
     */

    function changeIdCONTROLLER(uint256 id, address newCONTROLLER)
        external
        virtual
        override
        whenNotPaused
    {
        GeodeUtils.changeIdCONTROLLER(DATASTORE, id, newCONTROLLER);
    }

    function approveSenate(uint256 proposalId, uint256 electorId)
        external
        virtual
        override
        whenNotPaused
        nonReentrant
    {
        GEODE.approveSenate(DATASTORE, proposalId, electorId);
    }

    /**
     *                                  ** gETH Functionalities **
     */

    function allInterfaces(uint256 id)
        external
        view
        virtual
        override
        returns (address[] memory)
    {
        return StakeUtils.allInterfaces(DATASTORE, id);
    }

    /**
     *                                     ** Oracle Operations **
     */
    function TelescopeParams()
        external
        view
        virtual
        override
        returns (
            address ORACLE_POSITION,
            uint256 ORACLE_UPDATE_TIMESTAMP,
            uint256 MONOPOLY_THRESHOLD,
            uint256 VALIDATORS_INDEX,
            uint256 VERIFICATION_INDEX,
            uint256 PERIOD_PRICE_INCREASE_LIMIT,
            uint256 PERIOD_PRICE_DECREASE_LIMIT,
            bytes32 PRICE_MERKLE_ROOT
        )
    {
        ORACLE_POSITION = STAKEPOOL.TELESCOPE.ORACLE_POSITION;
        ORACLE_UPDATE_TIMESTAMP = STAKEPOOL.TELESCOPE.ORACLE_UPDATE_TIMESTAMP;
        MONOPOLY_THRESHOLD = STAKEPOOL.TELESCOPE.MONOPOLY_THRESHOLD;
        VALIDATORS_INDEX = STAKEPOOL.TELESCOPE.VALIDATORS_INDEX;
        VERIFICATION_INDEX = STAKEPOOL.TELESCOPE.VERIFICATION_INDEX;
        PERIOD_PRICE_INCREASE_LIMIT = STAKEPOOL
            .TELESCOPE
            .PERIOD_PRICE_INCREASE_LIMIT;
        PERIOD_PRICE_DECREASE_LIMIT = STAKEPOOL
            .TELESCOPE
            .PERIOD_PRICE_DECREASE_LIMIT;
        PRICE_MERKLE_ROOT = STAKEPOOL.TELESCOPE.PRICE_MERKLE_ROOT;
    }

    function getValidator(bytes calldata pubkey)
        external
        view
        virtual
        override
        returns (OracleUtils.Validator memory)
    {
        return STAKEPOOL.TELESCOPE.getValidator(pubkey);
    }

    /**
     * @notice Updating PricePerShare
     */
    function isOracleActive() external view virtual override returns (bool) {
        return STAKEPOOL.TELESCOPE._isOracleActive();
    }

    function reportOracle(
        bytes32 merkleRoot,
        uint256[] calldata beaconBalances,
        bytes32[][] calldata priceProofs
    ) external virtual override nonReentrant {
        STAKEPOOL.TELESCOPE.reportOracle(
            DATASTORE,
            merkleRoot,
            beaconBalances,
            priceProofs
        );
    }

    /**
     * @notice Batch validator verification and regulating operators
     */
    function isPrisoned(uint256 operatorId)
        external
        view
        virtual
        override
        returns (bool)
    {
        return OracleUtils.isPrisoned(DATASTORE, operatorId);
    }

    function updateVerificationIndex(
        uint256 allValidatorsCount,
        uint256 validatorVerificationIndex,
        bytes[] calldata alienatedPubkeys
    ) external virtual override {
        STAKEPOOL.TELESCOPE.updateVerificationIndex(
            DATASTORE,
            allValidatorsCount,
            validatorVerificationIndex,
            alienatedPubkeys
        );
    }

    function regulateOperators(
        bytes[] calldata bustedExits,
        bytes[] calldata bustedSignals,
        uint256[2][] calldata feeThefts
    ) external virtual override {
        STAKEPOOL.TELESCOPE.regulateOperators(
            DATASTORE,
            bustedExits,
            bustedSignals,
            feeThefts
        );
    }

    /**
     *                                       ** Staking Operations **
     */
    function StakingParams()
        external
        view
        virtual
        override
        returns (
            address DEFAULT_gETH_INTERFACE,
            address DEFAULT_DWP,
            address DEFAULT_LP_TOKEN,
            uint256 MINI_GOVERNANCE_VERSION,
            uint256 MAX_MAINTAINER_FEE,
            uint256 BOOSTRAP_PERIOD,
            uint256 COMET_TAX
        )
    {
        DEFAULT_gETH_INTERFACE = STAKEPOOL.DEFAULT_gETH_INTERFACE;
        DEFAULT_DWP = STAKEPOOL.DEFAULT_DWP;
        DEFAULT_LP_TOKEN = STAKEPOOL.DEFAULT_LP_TOKEN;
        MINI_GOVERNANCE_VERSION = STAKEPOOL.MINI_GOVERNANCE_VERSION;
        MAX_MAINTAINER_FEE = STAKEPOOL.MAX_MAINTAINER_FEE;
        BOOSTRAP_PERIOD = STAKEPOOL.BOOSTRAP_PERIOD;
        COMET_TAX = STAKEPOOL.COMET_TAX;
    }

    // function getPlanet(uint256 planetId)
    //     external
    //     view
    //     virtual
    //     override
    //     returns (
    //         bytes memory name,
    //         address CONTROLLER,
    //         address maintainer,
    //         uint256 initiated,
    //         uint256 fee,
    //         uint256 feeSwitch,
    //         uint256 surplus,
    //         uint256 secured,
    //         uint256 withdrawalBoost,
    //         address withdrawalPool,
    //         address LPToken,
    //         address miniGovernance
    //     )
    // {
    //     name = DATASTORE.readBytesForId(planetId, "NAME");
    //     CONTROLLER = DATASTORE.readAddressForId(planetId, "CONTROLLER");
    //     maintainer = DATASTORE.readAddressForId(planetId, "maintainer");
    //     initiated = DATASTORE.readUintForId(planetId, "initiated");
    //     fee = DATASTORE.getMaintainerFee(planetId);
    //     feeSwitch = DATASTORE.readUintForId(planetId, "feeSwitch");
    //     surplus = DATASTORE.readUintForId(planetId, "surplus");
    //     secured = DATASTORE.readUintForId(planetId, "secured");
    //     withdrawalBoost = DATASTORE.readUintForId(planetId, "withdrawalBoost");
    //     withdrawalPool = DATASTORE.readAddressForId(planetId, "withdrawalPool");
    //     LPToken = DATASTORE.readAddressForId(planetId, "LPToken");
    //     miniGovernance = DATASTORE.readAddressForId(planetId, "miniGovernance");
    // }

    // function getOperator(uint256 operatorId)
    //     external
    //     view
    //     virtual
    //     override
    //     returns (
    //         bytes memory name,
    //         address CONTROLLER,
    //         address maintainer,
    //         uint256 initiated,
    //         uint256 fee,
    //         uint256 feeSwitch,
    //         uint256 totalActiveValidators,
    //         uint256 validatorPeriod,
    //         uint256 released
    //     )
    // {
    //     name = DATASTORE.readBytesForId(operatorId, "NAME");
    //     CONTROLLER = DATASTORE.readAddressForId(operatorId, "CONTROLLER");
    //     maintainer = DATASTORE.readAddressForId(operatorId, "maintainer");
    //     initiated = DATASTORE.readUintForId(operatorId, "initiated");
    //     fee = DATASTORE.getMaintainerFee(operatorId);
    //     feeSwitch = DATASTORE.readUintForId(operatorId, "feeSwitch");
    //     totalActiveValidators = DATASTORE.readUintForId(
    //         operatorId,
    //         "totalActiveValidators"
    //     );
    //     validatorPeriod = DATASTORE.readUintForId(
    //         operatorId,
    //         "validatorPeriod"
    //     );
    //     released = DATASTORE.readUintForId(operatorId, "released");
    // }

    function miniGovernanceVersion()
        external
        view
        virtual
        override
        returns (uint256 version)
    {
        version = STAKEPOOL.MINI_GOVERNANCE_VERSION;
    }

    /**
     * @notice Governance functions on pools
     */

    /**
     * @notice updating the StakePool Params that does NOT require Senate approval
     * @dev onlyGovernance on external funciton
     */
    function _updateStakingParams(
        address _DEFAULT_gETH_INTERFACE,
        address _DEFAULT_DWP,
        address _DEFAULT_LP_TOKEN,
        uint256 _MAX_MAINTAINER_FEE,
        uint256 _BOOSTRAP_PERIOD,
        uint256 _PERIOD_PRICE_INCREASE_LIMIT,
        uint256 _PERIOD_PRICE_DECREASE_LIMIT,
        uint256 _COMET_TAX,
        uint256 _BOOST_SWITCH_LATENCY
    ) internal virtual {
        require(
            _DEFAULT_gETH_INTERFACE.code.length > 0,
            "Portal: DEFAULT_gETH_INTERFACE NOT contract"
        );
        require(
            _DEFAULT_DWP.code.length > 0,
            "Portal: DEFAULT_DWP NOT contract"
        );
        require(
            _DEFAULT_LP_TOKEN.code.length > 0,
            "Portal: DEFAULT_LP_TOKEN NOT contract"
        );
        require(
            _MAX_MAINTAINER_FEE > 0 &&
                _MAX_MAINTAINER_FEE <= StakeUtils.PERCENTAGE_DENOMINATOR,
            "Portal: incorrect MAX_MAINTAINER_FEE"
        );
        require(
            _PERIOD_PRICE_INCREASE_LIMIT > 0,
            "Portal: incorrect PERIOD_PRICE_INCREASE_LIMIT"
        );
        require(
            _PERIOD_PRICE_DECREASE_LIMIT > 0,
            "Portal: incorrect PERIOD_PRICE_DECREASE_LIMIT"
        );
        require(
            _COMET_TAX <= _MAX_MAINTAINER_FEE,
            "Portal: COMET_TAX should be less than MAX_MAINTAINER_FEE"
        );
        STAKEPOOL.DEFAULT_gETH_INTERFACE = _DEFAULT_gETH_INTERFACE;
        STAKEPOOL.DEFAULT_DWP = _DEFAULT_DWP;
        STAKEPOOL.DEFAULT_LP_TOKEN = _DEFAULT_LP_TOKEN;
        STAKEPOOL.MAX_MAINTAINER_FEE = _MAX_MAINTAINER_FEE;
        STAKEPOOL.COMET_TAX = _COMET_TAX;
        STAKEPOOL.BOOSTRAP_PERIOD = _BOOSTRAP_PERIOD;
        STAKEPOOL.BOOST_SWITCH_LATENCY = _BOOST_SWITCH_LATENCY;
        STAKEPOOL
            .TELESCOPE
            .PERIOD_PRICE_INCREASE_LIMIT = _PERIOD_PRICE_INCREASE_LIMIT;
        STAKEPOOL
            .TELESCOPE
            .PERIOD_PRICE_DECREASE_LIMIT = _PERIOD_PRICE_DECREASE_LIMIT;
        emit ParamsUpdated(
            _DEFAULT_gETH_INTERFACE,
            _DEFAULT_DWP,
            _DEFAULT_LP_TOKEN,
            _MAX_MAINTAINER_FEE,
            _BOOSTRAP_PERIOD,
            _PERIOD_PRICE_INCREASE_LIMIT,
            _PERIOD_PRICE_DECREASE_LIMIT,
            _COMET_TAX,
            _BOOST_SWITCH_LATENCY
        );
    }

    function updateStakingParams(
        address _DEFAULT_gETH_INTERFACE,
        address _DEFAULT_DWP,
        address _DEFAULT_LP_TOKEN,
        uint256 _MAX_MAINTAINER_FEE,
        uint256 _BOOSTRAP_PERIOD,
        uint256 _PERIOD_PRICE_INCREASE_LIMIT,
        uint256 _PERIOD_PRICE_DECREASE_LIMIT,
        uint256 _COMET_TAX,
        uint256 _BOOST_SWITCH_LATENCY
    ) external virtual override {
        require(
            msg.sender == GEODE.GOVERNANCE,
            "Portal: sender not GOVERNANCE"
        );
        _updateStakingParams(
            _DEFAULT_gETH_INTERFACE,
            _DEFAULT_DWP,
            _DEFAULT_LP_TOKEN,
            _MAX_MAINTAINER_FEE,
            _BOOSTRAP_PERIOD,
            _PERIOD_PRICE_INCREASE_LIMIT,
            _PERIOD_PRICE_DECREASE_LIMIT,
            _COMET_TAX,
            _BOOST_SWITCH_LATENCY
        );
    }

    /**
     * @dev onlyGovernance
     */
    function releasePrisoned(uint256 operatorId) external virtual override {
        require(
            msg.sender == GEODE.GOVERNANCE,
            "Portal: sender not GOVERNANCE"
        );
        OracleUtils.releasePrisoned(DATASTORE, operatorId);
    }

    /**
     * @notice ID initiatiors for different types
     * @dev comets(private pools) are not implemented yet
     */

    function initiateOperator(
        uint256 _id,
        uint256 _fee,
        address _maintainer,
        uint256 _validatorPeriod
    ) external virtual override whenNotPaused {
        STAKEPOOL.initiateOperator(
            DATASTORE,
            _id,
            _fee,
            _maintainer,
            _validatorPeriod
        );
    }

    function initiatePlanet(
        uint256 _id,
        uint256 _fee,
        address _maintainer,
        bytes calldata _name,
        string calldata _interfaceName,
        string calldata _interfaceSymbol
    ) external virtual override whenNotPaused {
        require(
            DATASTORE.readUintForId(_id, "initiated") == 0,
            "Portal: already initiated"
        );
        DATASTORE.writeBytesForId(_id, "NAME", _name);
        DATASTORE.writeAddressForId(_id, "CONTROLLER", _maintainer);
        DATASTORE.writeUintForId(_id, "TYPE", 5);

        STAKEPOOL.initiatePlanet(
            DATASTORE,
            _id,
            _fee,
            _maintainer,
            [_interfaceName, _interfaceSymbol]
        );
    }

    /**
     * @notice Maintainer functions
     */
    function changeMaintainer(uint256 id, address newMaintainer)
        external
        virtual
        override
        whenNotPaused
    {
        StakeUtils.changeMaintainer(DATASTORE, id, newMaintainer);
    }

    function switchMaintainerFee(uint256 id, uint256 newFee)
        external
        virtual
        override
        whenNotPaused
    {
        STAKEPOOL.switchMaintainerFee(DATASTORE, id, newFee);
    }

    /**
     * @notice Maintainer wallet
     */

    function getMaintainerWalletBalance(uint256 id)
        external
        view
        virtual
        override
        returns (uint256)
    {
        return DATASTORE.getMaintainerWalletBalance(id);
    }

    function increaseMaintainerWallet(uint256 id)
        external
        payable
        virtual
        override
        whenNotPaused
        nonReentrant
        returns (bool success)
    {
        success = StakeUtils.increaseMaintainerWallet(DATASTORE, id);
    }

    function decreaseMaintainerWallet(uint256 id, uint256 value)
        external
        virtual
        override
        whenNotPaused
        nonReentrant
        returns (bool success)
    {
        success = StakeUtils.decreaseMaintainerWallet(DATASTORE, id, value);
    }

    /**
     * @notice Pool - Operator interactions
     */

    function switchWithdrawalBoost(uint256 poolId, uint256 withdrawalBoost)
        external
        virtual
        override
        whenNotPaused
    {
        STAKEPOOL.switchWithdrawalBoost(DATASTORE, poolId, withdrawalBoost);
    }

    function operatorAllowance(uint256 poolId, uint256 operatorId)
        external
        view
        virtual
        override
        returns (
            uint256 allowance,
            uint256 proposedValidators,
            uint256 activeValidators
        )
    {
        allowance = StakeUtils.operatorAllowance(DATASTORE, poolId, operatorId);
        proposedValidators = DATASTORE.readUintForId(
            poolId,
            DataStoreUtils.getKey(operatorId, "proposedValidators")
        );
        activeValidators = DATASTORE.readUintForId(
            poolId,
            DataStoreUtils.getKey(operatorId, "activeValidators")
        );
    }

    function approveOperator(
        uint256 poolId,
        uint256 operatorId,
        uint256 allowance
    ) external virtual override whenNotPaused returns (bool) {
        return
            StakeUtils.approveOperator(
                DATASTORE,
                poolId,
                operatorId,
                allowance
            );
    }

    function switchValidatorPeriod(uint256 operatorId, uint256 newPeriod)
        external
        virtual
        override
        whenNotPaused
    {
        StakeUtils.updateValidatorPeriod(DATASTORE, operatorId, newPeriod);
    }

    /**
     * @notice Depositing functions (user)
     * @dev comets(private pools) are not implemented yet
     */

    function canDeposit(uint256 id)
        external
        view
        virtual
        override
        returns (bool)
    {
        return StakeUtils.canDeposit(DATASTORE, id);
    }

    function pauseStakingForPool(uint256 id) external virtual override {
        StakeUtils.pauseStakingForPool(DATASTORE, id);
    }

    function unpauseStakingForPool(uint256 id)
        external
        virtual
        override
        whenNotPaused
    {
        StakeUtils.unpauseStakingForPool(DATASTORE, id);
    }

    function depositPlanet(
        uint256 poolId,
        uint256 mingETH,
        uint256 deadline
    )
        external
        payable
        virtual
        override
        whenNotPaused
        nonReentrant
        returns (uint256 gEthToSend)
    {
        gEthToSend = STAKEPOOL.depositPlanet(
            DATASTORE,
            poolId,
            mingETH,
            deadline
        );
    }

    /**
     * @notice Withdrawal functions (user)
     * @dev comets(private pools) are not implemented yet
     */

    function withdrawPlanet(
        uint256 poolId,
        uint256 gEthToWithdraw,
        uint256 minETH,
        uint256 deadline
    )
        external
        virtual
        override
        whenNotPaused
        nonReentrant
        returns (uint256 EthToSend)
    {
        EthToSend = STAKEPOOL.withdrawPlanet(
            DATASTORE,
            poolId,
            gEthToWithdraw,
            minETH,
            deadline
        );
    }

    /**
     * @notice Validator creation (Stake) functions (operator)
     */

    function canStake(bytes calldata pubkey)
        external
        view
        virtual
        override
        returns (bool)
    {
        return STAKEPOOL.canStake(DATASTORE, pubkey);
    }

    function proposeStake(
        uint256 poolId,
        uint256 operatorId,
        bytes[] calldata pubkeys,
        bytes[] calldata signatures
    ) external virtual override whenNotPaused nonReentrant {
        STAKEPOOL.proposeStake(
            DATASTORE,
            poolId,
            operatorId,
            pubkeys,
            signatures
        );
    }

    function beaconStake(uint256 operatorId, bytes[] calldata pubkeys)
        external
        virtual
        override
        whenNotPaused
        nonReentrant
    {
        STAKEPOOL.beaconStake(DATASTORE, operatorId, pubkeys);
    }

    /**
     * @notice Validator exiting (Unstake) functions (operator)
     */

    function signalUnstake(bytes[] calldata pubkeys)
        external
        virtual
        override
        whenNotPaused
        nonReentrant
    {
        STAKEPOOL.signalUnstake(DATASTORE, pubkeys);
    }

    function fetchUnstake(
        uint256 poolId,
        uint256 operatorId,
        bytes[] calldata pubkeys,
        uint256[] calldata balances,
        bool[] calldata isExit
    ) external virtual override whenNotPaused nonReentrant {
        STAKEPOOL.fetchUnstake(
            DATASTORE,
            poolId,
            operatorId,
            pubkeys,
            balances,
            isExit
        );
    }

    /**
     * @notice We do care.
     */

    function Do_we_care() external pure returns (bool) {
        return true;
    }

    /// @dev fallbacks
    fallback() external payable {}

    receive() external payable {}

    /// @notice keep the contract size at 50
    uint256[46] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.7;

import "../Portal/utils/GeodeUtilsLib.sol";
import "../Portal/utils/OracleUtilsLib.sol";

interface IPortal {
    function initialize(
        address _GOVERNANCE,
        address _gETH,
        address _ORACLE_POSITION,
        address _DEFAULT_gETH_INTERFACE,
        address _DEFAULT_DWP,
        address _DEFAULT_LP_TOKEN,
        address _MINI_GOVERNANCE_POSITION,
        uint256 _GOVERNANCE_TAX,
        uint256 _COMET_TAX,
        uint256 _MAX_MAINTAINER_FEE,
        uint256 _BOOSTRAP_PERIOD
    ) external;

    function pause() external;

    function unpause() external;

    function getVersion() external view returns (uint256);

    function gETH() external view returns (address);

    function allIdsByType(uint256 _type)
        external
        view
        returns (uint256[] memory);

    function generateId(string calldata _name, uint256 _type)
        external
        pure
        returns (uint256 id);

    function readAddressForId(uint256 id, bytes32 key)
        external
        view
        returns (address data);

    function readUintForId(uint256 id, bytes32 key)
        external
        view
        returns (uint256 data);

    function readBytesForId(uint256 id, bytes32 key)
        external
        view
        returns (bytes memory data);

    function GeodeParams()
        external
        view
        returns (
            address SENATE,
            address GOVERNANCE,
            uint256 GOVERNANCE_TAX,
            uint256 MAX_GOVERNANCE_TAX,
            uint256 SENATE_EXPIRY
        );

    function getProposal(uint256 id)
        external
        view
        returns (GeodeUtils.Proposal memory proposal);

    function isUpgradeAllowed(address proposedImplementation)
        external
        view
        returns (bool);

    function setGovernanceTax(uint256 newFee) external returns (bool);

    function newProposal(
        address _CONTROLLER,
        uint256 _TYPE,
        bytes calldata _NAME,
        uint256 duration
    ) external;

    function setMaxGovernanceTax(uint256 newMaxFee) external returns (bool);

    function approveProposal(uint256 id) external;

    function changeIdCONTROLLER(uint256 id, address newCONTROLLER) external;

    function approveSenate(uint256 proposalId, uint256 electorId) external;

    function allInterfaces(uint256 id) external view returns (address[] memory);

    function TelescopeParams()
        external
        view
        returns (
            address ORACLE_POSITION,
            uint256 ORACLE_UPDATE_TIMESTAMP,
            uint256 MONOPOLY_THRESHOLD,
            uint256 VALIDATORS_INDEX,
            uint256 VERIFICATION_INDEX,
            uint256 PERIOD_PRICE_INCREASE_LIMIT,
            uint256 PERIOD_PRICE_DECREASE_LIMIT,
            bytes32 PRICE_MERKLE_ROOT
        );

    function releasePrisoned(uint256 operatorId) external;

    function miniGovernanceVersion() external view returns (uint256 id);

    function getValidator(bytes calldata pubkey)
        external
        view
        returns (OracleUtils.Validator memory);

    function isOracleActive() external view returns (bool);

    function reportOracle(
        bytes32 merkleRoot,
        uint256[] calldata beaconBalances,
        bytes32[][] calldata priceProofs
    ) external;

    function isPrisoned(uint256 operatorId) external view returns (bool);

    function updateVerificationIndex(
        uint256 allValidatorsCount,
        uint256 validatorVerificationIndex,
        bytes[] calldata alienatedPubkeys
    ) external;

    function regulateOperators(
        bytes[] calldata bustedExits,
        bytes[] calldata bustedSignals,
        uint256[2][] calldata feeThefts
    ) external;

    function StakingParams()
        external
        view
        returns (
            address DEFAULT_gETH_INTERFACE,
            address DEFAULT_DWP,
            address DEFAULT_LP_TOKEN,
            uint256 MINI_GOVERNANCE_VERSION,
            uint256 MAX_MAINTAINER_FEE,
            uint256 BOOSTRAP_PERIOD,
            uint256 COMET_TAX
        );

    function updateStakingParams(
        address _DEFAULT_gETH_INTERFACE,
        address _DEFAULT_DWP,
        address _DEFAULT_LP_TOKEN,
        uint256 _MAX_MAINTAINER_FEE,
        uint256 _BOOSTRAP_PERIOD,
        uint256 _PERIOD_PRICE_INCREASE_LIMIT,
        uint256 _PERIOD_PRICE_DECREASE_LIMIT,
        uint256 _COMET_TAX,
        uint256 _BOOST_SWITCH_LATENCY
    ) external;

    function initiateOperator(
        uint256 _id,
        uint256 _fee,
        address _maintainer,
        uint256 _validatorPeriod
    ) external;

    function initiatePlanet(
        uint256 _id,
        uint256 _fee,
        address _maintainer,
        bytes calldata _name,
        string calldata _interfaceName,
        string calldata _interfaceSymbol
    ) external;

    function changeMaintainer(uint256 id, address newMaintainer) external;

    function getMaintainerWalletBalance(uint256 id)
        external
        view
        returns (uint256);

    function switchMaintainerFee(uint256 id, uint256 newFee) external;

    function increaseMaintainerWallet(uint256 id)
        external
        payable
        returns (bool success);

    function decreaseMaintainerWallet(uint256 id, uint256 value)
        external
        returns (bool success);

    function switchWithdrawalBoost(uint256 poolId, uint256 withdrawalBoost)
        external;

    function operatorAllowance(uint256 poolId, uint256 operatorId)
        external
        view
        returns (
            uint256 allowance,
            uint256 proposedValidators,
            uint256 activeValidators
        );

    function approveOperator(
        uint256 poolId,
        uint256 operatorId,
        uint256 allowance
    ) external returns (bool);

    function switchValidatorPeriod(uint256 operatorId, uint256 newPeriod)
        external;

    function canDeposit(uint256 _id) external view returns (bool);

    function canStake(bytes calldata pubkey) external view returns (bool);

    function pauseStakingForPool(uint256 id) external;

    function unpauseStakingForPool(uint256 id) external;

    function depositPlanet(
        uint256 poolId,
        uint256 mingETH,
        uint256 deadline
    ) external payable returns (uint256 gEthToSend);

    function withdrawPlanet(
        uint256 poolId,
        uint256 gEthToWithdraw,
        uint256 minETH,
        uint256 deadline
    ) external returns (uint256 EthToSend);

    function proposeStake(
        uint256 poolId,
        uint256 operatorId,
        bytes[] calldata pubkeys,
        bytes[] calldata signatures
    ) external;

    function beaconStake(uint256 operatorId, bytes[] calldata pubkeys) external;

    function signalUnstake(bytes[] calldata pubkeys) external;

    function fetchUnstake(
        uint256 poolId,
        uint256 operatorId,
        bytes[] calldata pubkeys,
        uint256[] calldata balances,
        bool[] calldata isExit
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.7;

interface IgETH {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    function uri(uint256) external view returns (string memory);

    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);

    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        external
        view
        returns (uint256[] memory);

    function setApprovalForAll(address operator, bool approved) external;

    function isApprovedForAll(address account, address operator)
        external
        view
        returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external;

    function burn(
        address account,
        uint256 id,
        uint256 value
    ) external;

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) external;

    function totalSupply(uint256 id) external view returns (uint256);

    function exists(uint256 id) external view returns (bool);

    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external;

    function pause() external;

    function unpause() external;

    function denominator() external view returns (uint256);

    function pricePerShare(uint256 id) external view returns (uint256);

    function priceUpdateTimestamp(uint256 id) external view returns (uint256);

    function setPricePerShare(uint256 price, uint256 id) external;

    function isInterface(address _interface, uint256 id)
        external
        view
        returns (bool);

    function setInterface(
        address _interface,
        uint256 id,
        bool isSet
    ) external;

    function updateMinterRole(address Minter) external;

    function updatePauserRole(address Pauser) external;

    function updateOracleRole(address Oracle) external;
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.7;

import "./DataStoreUtilsLib.sol";

/**
 * @author Icebear & Crash Bandicoot
 * @title GeodeUtils library
 * @notice Exclusively contains functions responsible for administration of DATASTORE,
 * including functions related to "limited upgradability" with Senate & Proposals.
 * @dev Contracts relying on this library must initialize GeodeUtils.Universe
 * @dev ALL "fee" variables are limited by PERCENTAGE_DENOMINATOR = 100%
 * @dev Admin functions are already protected
 * Note this library contains both functions called by users(ID) (approveSenate) and admins(GOVERNANCE, SENATE)
 * Note refer to DataStoreUtils before reviewing
 */
library GeodeUtils {
    using DataStoreUtils for DataStoreUtils.DataStore;

    event GovernanceTaxUpdated(uint256 newFee);
    event MaxGovernanceTaxUpdated(uint256 newMaxFee);
    event ControllerChanged(uint256 id, address newCONTROLLER);
    event Proposed(
        uint256 id,
        address CONTROLLER,
        uint256 TYPE,
        uint256 deadline
    );
    event ProposalApproved(uint256 id);
    event ElectorTypeSet(uint256 TYPE, bool isElector);
    event Vote(uint256 proposalId, uint256 electorId);
    event NewSenate(address senate, uint256 senateExpiry);

    /**
     * @notice Proposal basically refers to give the control of an ID to a CONTROLLER.
     *
     * @notice A Proposal has 4 specs:
     * @param TYPE: separates the proposals and related functionality between different ID types.
     * * RESERVED TYPES on GeodeUtils:
     * * * TYPE 0: inactive
     * * * TYPE 1: Senate: controls state of governance, contract updates and other members of A Universe
     * * * TYPE 2: Upgrade: address of the implementation for desired contract upgrade
     * * * TYPE 3: **gap** : formally it represented the admin contract, however since UUPS is being used as a upgrade path,
     * this TYPE is now reserved.
     *
     * @param name: id is created by keccak(name, type)
     *
     * @param CONTROLLER: the address that refers to the change that is proposed by given proposal ID.
     * * This slot can refer to the controller of an id, a new implementation contract, a new Senate etc.
     *
     * @param deadline: refers to last timestamp until a proposal expires, limited by MAX_PROPOSAL_DURATION
     * * Expired proposals can not be approved by Senate
     * * Expired proposals can not be overriden by new proposals
     **/
    struct Proposal {
        address CONTROLLER;
        uint256 TYPE;
        bytes NAME;
        uint256 deadline;
    }

    /**
     * @notice Universe is A blockchain. In this case, it defines Ethereum
     * @param GOVERNANCE a community that works to improve the core product and ensures its adoption in the DeFi ecosystem
     * Suggests updates, such as new planets, operators, comets, contract upgrades and new Senate, on the Ecosystem -without any permission to force them-
     * @param SENATE An address that controls the state of governance, updates and other users in the Geode Ecosystem
     * Note SENATE is proposed by Governance and voted by all elector types, operates if ⌊2/3⌋ approves.
     * @param GOVERNANCE_TAX operation fee of the given contract, acquired by GOVERNANCE. Limited by MAX_GOVERNANCE_TAX
     * @param MAX_GOVERNANCE_TAX set by SENATE, limited by PERCENTAGE_DENOMINATOR
     * @param SENATE_EXPIRY refers to the last timestamp that SENATE can continue operating. Enforces a new election, limited by MAX_SENATE_PERIOD
     * @param approvedUpgrade only 1 implementation contract can be "approved" at any given time. @dev safe to set to address(0) after every upgrade
     * @param _electorCount increased when a new id is added with _electorTypes[id] == true
     * @param _electorTypes only given types can vote @dev MUST only change during upgrades.
     * @param _proposalForId proposals are kept seperately instead of setting the parameters of id in DATASTORE, and then setting it's type; to allow surpassing type checks to save gas cost
     * @param __gap keep the struct size at 16
     **/
    struct Universe {
        address SENATE;
        address GOVERNANCE;
        uint256 GOVERNANCE_TAX;
        uint256 MAX_GOVERNANCE_TAX;
        uint256 SENATE_EXPIRY;
        address approvedUpgrade;
        uint256 _electorCount;
        mapping(uint256 => bool) _electorTypes;
        mapping(uint256 => Proposal) _proposalForId;
        uint256[7] __gap;
    }

    /// @notice PERCENTAGE_DENOMINATOR represents 100%
    uint256 public constant PERCENTAGE_DENOMINATOR = 10**10;

    uint32 public constant MIN_PROPOSAL_DURATION = 1 days;
    uint32 public constant MAX_PROPOSAL_DURATION = 2 weeks;
    uint32 public constant MAX_SENATE_PERIOD = 365 days; // 1 year

    modifier onlySenate(Universe storage self) {
        require(msg.sender == self.SENATE, "GeodeUtils: SENATE role needed");
        require(
            block.timestamp < self.SENATE_EXPIRY,
            "GeodeUtils: SENATE not active"
        );
        _;
    }

    modifier onlyGovernance(Universe storage self) {
        require(
            msg.sender == self.GOVERNANCE,
            "GeodeUtils: GOVERNANCE role needed"
        );
        _;
    }

    modifier onlyController(
        DataStoreUtils.DataStore storage DATASTORE,
        uint256 id
    ) {
        require(
            msg.sender == DATASTORE.readAddressForId(id, "CONTROLLER"),
            "GeodeUtils: CONTROLLER role needed"
        );
        _;
    }

    /**
     *                                         ** UNIVERSE GETTERS **
     **/

    /**
     * @return address of SENATE
     **/
    function getSenate(Universe storage self) external view returns (address) {
        return self.SENATE;
    }

    /**
     * @return address of GOVERNANCE
     **/
    function getGovernance(Universe storage self)
        external
        view
        returns (address)
    {
        return self.GOVERNANCE;
    }

    /**
     * @notice MAX_GOVERNANCE_TAX must limit GOVERNANCE_TAX even if MAX is changed
     * @return active GOVERNANCE_TAX, limited by MAX_GOVERNANCE_TAX
     */
    function getGovernanceTax(Universe storage self)
        external
        view
        returns (uint256)
    {
        return self.GOVERNANCE_TAX;
    }

    /**
     *  @return MAX_GOVERNANCE_TAX
     */
    function getMaxGovernanceTax(Universe storage self)
        external
        view
        returns (uint256)
    {
        return self.MAX_GOVERNANCE_TAX;
    }

    /**
     * @return the expiration date of current SENATE as a timestamp
     */
    function getSenateExpiry(Universe storage self)
        external
        view
        returns (uint256)
    {
        return self.SENATE_EXPIRY;
    }

    /**
     *                                         ** UNIVERSE SETTERS **
     */

    /**
     * @dev can not set the fee more than MAX_GOVERNANCE_TAX
     * @dev no need to check PERCENTAGE_DENOMINATOR because MAX_GOVERNANCE_TAX is limited already
     * @return true if the operation was succesful, might be helpful when governance rights are distributed
     */
    function setGovernanceTax(Universe storage self, uint256 newFee)
        external
        onlyGovernance(self)
        returns (bool)
    {
        require(
            newFee <= self.MAX_GOVERNANCE_TAX,
            "GeodeUtils: cannot be more than MAX_GOVERNANCE_TAX"
        );

        self.GOVERNANCE_TAX = newFee;

        emit GovernanceTaxUpdated(newFee);

        return true;
    }

    /**
     * @dev can not set a fee more than PERCENTAGE_DENOMINATOR (100%)
     * @return true if the operation was succesful
     */
    function setMaxGovernanceTax(Universe storage self, uint256 newMaxFee)
        external
        onlySenate(self)
        returns (bool)
    {
        require(
            newMaxFee <= PERCENTAGE_DENOMINATOR,
            "GeodeUtils: fee more than 100%"
        );

        self.MAX_GOVERNANCE_TAX = newMaxFee;

        emit MaxGovernanceTaxUpdated(newMaxFee);

        return true;
    }

    /**
     *                                          ** ID **
     */

    /**
     * @dev Some TYPEs may require permissionless creation. But to allow anyone to claim any ID,
     * meaning malicious actors can claim names and operate pools to mislead people. To prevent this
     * TYPEs will be considered during id generation.
     */
    function _generateId(bytes calldata _NAME, uint256 _TYPE)
        internal
        pure
        returns (uint256)
    {
        return uint256(keccak256(abi.encodePacked(_NAME, _TYPE)));
    }

    /**
     * @dev returns address(0) for empty ids, mandatory
     */
    function getCONTROLLERFromId(
        DataStoreUtils.DataStore storage DATASTORE,
        uint256 id
    ) external view returns (address) {
        return DATASTORE.readAddressForId(id, "CONTROLLER");
    }

    /**
     * @dev returns uint(0) for empty ids, mandatory
     */
    function getTYPEFromId(
        DataStoreUtils.DataStore storage DATASTORE,
        uint256 id
    ) external view returns (uint256) {
        return DATASTORE.readUintForId(id, "TYPE");
    }

    /**
     * @dev returns bytes(0) for empty ids, mandatory
     */
    function getNAMEFromId(
        DataStoreUtils.DataStore storage DATASTORE,
        uint256 id
    ) external view returns (bytes memory) {
        return DATASTORE.readBytesForId(id, "NAME");
    }

    /**
     * @notice only the current CONTROLLER can change
     * @dev this operation can not be reverted by the old CONTROLLER
     * @dev in case the current controller wants to remove the
     * need to upgrade to Controller they should provide smt like 0x000000000000000000000000000000000000dEaD
     */
    function changeIdCONTROLLER(
        DataStoreUtils.DataStore storage DATASTORE,
        uint256 id,
        address newCONTROLLER
    ) external onlyController(DATASTORE, id) {
        require(
            newCONTROLLER != address(0),
            "GeodeUtils: CONTROLLER can not be zero"
        );

        DATASTORE.writeAddressForId(id, "CONTROLLER", newCONTROLLER);

        emit ControllerChanged(id, newCONTROLLER);
    }

    /**
     *                                          ** PROPOSALS **
     */

    /**
     * CONTROLLER Proposals
     */

    function getProposal(Universe storage self, uint256 id)
        external
        view
        returns (Proposal memory)
    {
        return self._proposalForId[id];
    }

    /**
     * @notice a proposal can never be overriden.
     * @notice DATASTORE(id) will not be updated until the proposal is approved.
     * @dev refer to structure of Proposal for explanations of params
     */
    function newProposal(
        Universe storage self,
        address _CONTROLLER,
        uint256 _TYPE,
        bytes calldata _NAME,
        uint256 duration
    ) external returns (uint256 id) {
        require(
            duration >= MIN_PROPOSAL_DURATION,
            "GeodeUtils: duration should be higher than MIN_PROPOSAL_DURATION"
        );
        require(
            duration <= MAX_PROPOSAL_DURATION,
            "GeodeUtils: duration exceeds MAX_PROPOSAL_DURATION"
        );

        id = _generateId(_NAME, _TYPE);

        require(
            self._proposalForId[id].deadline == 0,
            "GeodeUtils: NAME already proposed"
        );

        self._proposalForId[id] = Proposal({
            CONTROLLER: _CONTROLLER,
            TYPE: _TYPE,
            NAME: _NAME,
            deadline: block.timestamp + duration
        });

        emit Proposed(id, _CONTROLLER, _TYPE, block.timestamp + duration);
    }

    /**
     *  @notice type specific changes for reserved_types(1,2,3) are implemented here,
     *  any other addition should take place in Portal, as not related
     *  @param id given ID proposal that has been approved by Senate
     *  @dev Senate should not be able to approve approved proposals
     *  @dev Senate should not be able to approve expired proposals
     *  @dev Senate should not be able to approve SENATE proposals :)
     */
    function approveProposal(
        Universe storage self,
        DataStoreUtils.DataStore storage DATASTORE,
        uint256 id
    ) external onlySenate(self) {
        require(
            self._proposalForId[id].deadline > block.timestamp,
            "GeodeUtils: proposal expired"
        );
        require(
            self._proposalForId[id].TYPE != 1,
            "GeodeUtils: Senate can not approve Senate Election"
        );

        DATASTORE.writeAddressForId(
            id,
            "CONTROLLER",
            self._proposalForId[id].CONTROLLER
        );
        DATASTORE.writeUintForId(id, "TYPE", self._proposalForId[id].TYPE);
        DATASTORE.writeBytesForId(id, "NAME", self._proposalForId[id].NAME);

        if (self._proposalForId[id].TYPE == 2) {
            self.approvedUpgrade = self._proposalForId[id].CONTROLLER;
        }

        if (self._electorTypes[DATASTORE.readUintForId(id, "TYPE")]) {
            self._electorCount += 1;
        }

        DATASTORE.allIdsByType[self._proposalForId[id].TYPE].push(id);
        self._proposalForId[id].deadline = block.timestamp;

        emit ProposalApproved(id);
    }

    /**
     * SENATE Proposals
     */

    /**
     * @notice only elector types can vote for senate
     * @param _TYPE selected type
     * @param isElector true if selected _type can vote for senate from now on
     * @dev can not set with the same value again, preventing double increment/decrements
     */
    function setElectorType(
        Universe storage self,
        DataStoreUtils.DataStore storage DATASTORE,
        uint256 _TYPE,
        bool isElector
    ) external onlyGovernance(self) {
        require(
            self._electorTypes[_TYPE] != isElector,
            "GeodeUtils: type already _isElector"
        );
        require(
            _TYPE != 0 && _TYPE != 1 && _TYPE != 2 && _TYPE != 3,
            "GeodeUtils: 0, Senate, Upgrade cannot be elector"
        );

        self._electorTypes[_TYPE] = isElector;

        if (isElector) {
            self._electorCount += DATASTORE.allIdsByType[_TYPE].length;
        } else {
            self._electorCount -= DATASTORE.allIdsByType[_TYPE].length;
        }

        emit ElectorTypeSet(_TYPE, isElector);
    }

    /**
     * @notice Proposed CONTROLLER is the new Senate after 2/3 of the electors approved
     * NOTE mathematically, min 4 elector is needed for (c+1)*2/3 to work properly
     * @notice id can not vote if:
     * - approved already
     * - proposal is expired
     * - not its type is elector
     * - not senate proposal
     * @param electorId should have the voting rights, msg.sender should be the CONTROLLER of given ID
     * @dev pins id as "voted" when approved
     * @dev increases "approvalCount" of proposalId by 1 when approved
     */
    function approveSenate(
        Universe storage self,
        DataStoreUtils.DataStore storage DATASTORE,
        uint256 proposalId,
        uint256 electorId
    ) external onlyController(DATASTORE, electorId) {
        require(
            self._proposalForId[proposalId].TYPE == 1,
            "GeodeUtils: NOT Senate Proposal"
        );
        require(
            self._proposalForId[proposalId].deadline >= block.timestamp,
            "GeodeUtils: proposal expired"
        );
        require(
            self._electorTypes[DATASTORE.readUintForId(electorId, "TYPE")],
            "GeodeUtils: NOT an elector"
        );
        require(
            DATASTORE.readUintForId(
                proposalId,
                DataStoreUtils.getKey(electorId, "voted")
            ) == 0,
            " GeodeUtils: already approved"
        );

        DATASTORE.writeUintForId(
            proposalId,
            DataStoreUtils.getKey(electorId, "voted"),
            1
        );
        DATASTORE.addUintForId(proposalId, "approvalCount", 1);

        if (
            DATASTORE.readUintForId(proposalId, "approvalCount") >=
            ((self._electorCount + 1) * 2) / 3
        ) {
            self._proposalForId[proposalId].deadline = block.timestamp;
            _setSenate(
                self,
                self._proposalForId[proposalId].CONTROLLER,
                MAX_SENATE_PERIOD
            );
        }

        emit Vote(proposalId, electorId);
    }

    function _setSenate(
        Universe storage self,
        address _newSenate,
        uint256 _senatePeriod
    ) internal {
        self.SENATE = _newSenate;
        self.SENATE_EXPIRY = block.timestamp + _senatePeriod;

        emit NewSenate(self.SENATE, self.SENATE_EXPIRY);
    }

    /**
     * @notice Get if it is allowed to change a specific contract with the current version.
     * @return True if it is allowed by senate and false if not.
     * @dev address(0) should return false
     * @dev DO NOT TOUCH, EVER! WHATEVER YOU DEVELOP IN FUCKING 3022
     **/
    function isUpgradeAllowed(
        Universe storage self,
        address proposedImplementation
    ) external view returns (bool) {
        return
            self.approvedUpgrade != address(0) &&
            self.approvedUpgrade == proposedImplementation;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.7;

/**
 * @author Icebear & Crash Bandicoot
 * @title Storage Management Library for dynamic structs, based on data types and ids
 *
 * DataStoreUtils is a storage management tool designed to create a safe and scalable
 * storage layout with the help of ids and keys.
 * Mainly focusing on upgradable contracts with multiple user types to create a
 * sustainable development environment.
 *
 * In summary, extra gas cost that would be saved with Storage packing are
 * ignored to create upgradable structs*.
 *
 * IDs are the representation of a user with any given key as properties.
 * Type for ID is not mandatory, not all IDs should have an explicit type.
 * Thus there is no checks of types or keys.
 *
 * @notice distinct id and key pairs return different storage slots
 *
 */
library DataStoreUtils {
    /**
     * @notice Main Struct for reading and writing data to storage for given (id, key) pairs
     * @param allIdsByType optional categorization for given ID, requires direct access, type => id[]
     * @param uintData keccak(id, key) =>  returns uint256
     * @param bytesData keccak(id, key) => returns bytes
     * @param addressData keccak(id, key) =>  returns address
     * @dev any other storage type can be expressed as bytes
     * @param __gap keep the struct size at 16
     */
    struct DataStore {
        mapping(uint256 => uint256[]) allIdsByType;
        mapping(bytes32 => uint256) uintData;
        mapping(bytes32 => bytes) bytesData;
        mapping(bytes32 => address) addressData;
        uint256[12] __gap;
    }

    /**
     *                              ** HELPER **
     **/

    /**
     * @notice hashes given id with parameter to be used as key in getters and setters
     * @return key bytes32 hash of id and parameter to be stored
     **/
    function getKey(uint256 _id, bytes32 _param)
        internal
        pure
        returns (bytes32 key)
    {
        key = keccak256(abi.encodePacked(_id, _param));
    }

    /**
     *                              **DATA GETTERS **
     **/

    function readUintForId(
        DataStore storage self,
        uint256 _id,
        bytes32 _key
    ) internal view returns (uint256 data) {
        data = self.uintData[getKey(_id, _key)];
    }

    function readBytesForId(
        DataStore storage self,
        uint256 _id,
        bytes32 _key
    ) internal view returns (bytes memory data) {
        data = self.bytesData[getKey(_id, _key)];
    }

    function readAddressForId(
        DataStore storage self,
        uint256 _id,
        bytes32 _key
    ) internal view returns (address data) {
        data = self.addressData[getKey(_id, _key)];
    }

    /**
     *                              **DATA SETTERS **
     **/
    function writeUintForId(
        DataStore storage self,
        uint256 _id,
        bytes32 _key,
        uint256 _data
    ) internal {
        self.uintData[getKey(_id, _key)] = _data;
    }

    function addUintForId(
        DataStore storage self,
        uint256 _id,
        bytes32 _key,
        uint256 _addend
    ) internal {
        self.uintData[getKey(_id, _key)] += _addend;
    }

    function subUintForId(
        DataStore storage self,
        uint256 _id,
        bytes32 _key,
        uint256 _minuend
    ) internal {
        self.uintData[getKey(_id, _key)] -= _minuend;
    }

    function writeBytesForId(
        DataStore storage self,
        uint256 _id,
        bytes32 _key,
        bytes memory _data
    ) internal {
        self.bytesData[getKey(_id, _key)] = _data;
    }

    function writeAddressForId(
        DataStore storage self,
        uint256 _id,
        bytes32 _key,
        address _data
    ) internal {
        self.addressData[getKey(_id, _key)] = _data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.7;
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./DataStoreUtilsLib.sol";
import {DepositContractUtils as DCU} from "./DepositContractUtilsLib.sol";
import "../../interfaces/IgETH.sol";

/**
 * @author Icebear & Crash Bandicoot
 * @title OracleUtils library to be used within stakeUtils
 * @notice Oracle, named Telescope, is responsible from 2 tasks:
 * * regulating the validator creations and exits
 * * syncs the price of all pools with merkleroot
 *
 * Regulating the validators/operators:
 * * state 1: validators is proposed since enough allowence is given from pool maintainers, 1 ETH is locked from maintainerWallet
 * * state 2: stake was approved by Oracle, operator used user funds to activate the validator, 1 ETH is released
 * * state 69: validator was malicious(alien), probably front-runned with a problematic withdrawalCredential, (https://bit.ly/3Tkc6UC)
 * * state 3: validator is exited. However, if the signal turns out to be false, then Telescope reports and sets to state 2, prisoning the operator.
 * * * Reports the Total number of Beacon validators to make sure no operator is running more validators then they should within Geode Universe.
 *
 *
 * Syncing the Prices:
 * * Telescope works the first 30 minutes of every day(GMT), with an archive node that points the first second.
 * * Catches the beacon chain balances and decreases the fees, groups them by ids
 * * Creates a merkle root, by simply calculating all prices from every pool, either private or public
 * * Verifies merkle root with price proofs of all public pools.
 * * * Private pools need to verify their own price once a day, otherwise minting is not allowed.
 * * * * This is why merkle root of all prices is needed
 *
 * @dev Prisoned Validator:
 * * 1. created a malicious validator(alien)
 * * 2. withdrawn without a signal
 * * 3. signaled but not withdrawn
 * * 4. did not respect the validatorPeriod
 *
 * @dev ALL "fee" variables are limited by PERCENTAGE_DENOMINATOR = 100%
 * Note refer to DataStoreUtils before reviewing
 */

library OracleUtils {
    using DataStoreUtils for DataStoreUtils.DataStore;

    event Alienated(bytes pubkey);
    event Busted(bytes pubkey);
    event Prisoned(uint256 id, uint256 releaseTimestamp);
    event Released(uint256 id);
    event VerificationIndexUpdated(uint256 validatorVerificationIndex);
    event FeeTheft(uint256 id, uint256 blockNumber);

    /**
     * @param state 0: inactive, 1: proposed/cured validator, 2: active validator, 3: exited,  69: alienated proposal
     * @param index representing this validators placement on the chronological order of the proposed validators
     * @param planetId needed for withdrawal_credential
     * @param operatorId needed for staking after allowence
     * @param poolFee percentage of the rewards that will got to pool's maintainer, locked when the validator is created
     * @param operatorFee percentage of the rewards that will got to operator's maintainer, locked when the validator is created
     * @param createdAt the timestamp pointing the proposal to create a validator with given pubkey.
     * @param expectedExit expected timestamp of the exit of validator. Calculated with operator["validatorPeriod"]
     * @param signature BLS12-381 signature of the validator
     **/
    struct Validator {
        uint8 state;
        uint256 index;
        uint256 poolId;
        uint256 operatorId;
        uint256 poolFee;
        uint256 operatorFee;
        uint256 createdAt;
        uint256 expectedExit;
        bytes signature;
    }
    /**
     * @param ORACLE_POSITION https://github.com/Geodefi/Telescope-Eth
     * @param ORACLE_UPDATE_TIMESTAMP the timestamp of the latest oracle update
     * @param MONOPOLY_THRESHOLD max number of validators 1 operator is allowed to operate, updated daily by oracle
     * @param VALIDATORS_INDEX total number of validators that are proposed at some point. includes all states of validators.
     * @param VERIFICATION_INDEX the highest index of the validators that are verified ( to be not alien ) by Telescope. Updated by Telescope.
     * @param PERIOD_PRICE_INCREASE_LIMIT limiting the price increases for one oracle period, 24h. Effective for any time interval
     * @param PERIOD_PRICE_DECREASE_LIMIT limiting the price decreases for one oracle period, 24h. Effective for any time interval
     * @param PRICE_MERKLE_ROOT merkle root of the prices of every pool, planet or comet
     * @param _validators contains all the data about proposed or/and active validators
     * @param __gap keep the struct size at 16
     **/
    struct Oracle {
        IgETH gETH;
        address ORACLE_POSITION;
        uint256 ORACLE_UPDATE_TIMESTAMP;
        uint256 MONOPOLY_THRESHOLD;
        uint256 VALIDATORS_INDEX;
        uint256 VERIFICATION_INDEX;
        uint256 PERIOD_PRICE_INCREASE_LIMIT;
        uint256 PERIOD_PRICE_DECREASE_LIMIT;
        bytes32 PRICE_MERKLE_ROOT;
        mapping(bytes => Validator) _validators;
        uint256[6] __gap;
    }

    /// @notice PERCENTAGE_DENOMINATOR represents 100%
    uint256 public constant PERCENTAGE_DENOMINATOR = 10**10;

    /// @notice Oracle is active for the first 30 min of every day
    uint256 public constant ORACLE_PERIOD = 1 days;
    uint256 public constant ORACLE_ACTIVE_PERIOD = 30 minutes;

    /// @notice effective on MONOPOLY_THRESHOLD, limiting the active validators, set to 5% at start.
    uint256 public constant MONOPOLY_RATIO = (5 * PERCENTAGE_DENOMINATOR) / 100;

    /// @notice limiting some abilities of Operators in case of bad behaviour
    uint256 public constant PRISON_SENTENCE = 30 days;

    modifier onlyOracle(Oracle storage self) {
        require(
            msg.sender == self.ORACLE_POSITION,
            "OracleUtils: sender NOT ORACLE"
        );

        _;
    }

    function getValidator(Oracle storage self, bytes calldata pubkey)
        external
        view
        returns (Validator memory)
    {
        return self._validators[pubkey];
    }

    /**
     * @notice Oracle is only allowed for a period every day & some operations are stopped then
     * @return false if the last oracle update happened already (within the current daily period)
     */
    function _isOracleActive(Oracle storage self) internal view returns (bool) {
        return
            (block.timestamp % ORACLE_PERIOD <= ORACLE_ACTIVE_PERIOD) &&
            (self.ORACLE_UPDATE_TIMESTAMP <
                block.timestamp - ORACLE_ACTIVE_PERIOD);
    }

    /**
     * @notice              ** Regulating the Operators and PubKeys **
     */

    /**
     * @notice Checks if the given operator is Prisoned
     * @dev "released" key refers to the end of the last imprisonment, the limit on the abilities of operator is lifted then
     */
    function isPrisoned(
        DataStoreUtils.DataStore storage DATASTORE,
        uint256 _operatorId
    ) internal view returns (bool _isPrisoned) {
        _isPrisoned =
            block.timestamp <= DATASTORE.readUintForId(_operatorId, "released");
    }

    /**
     * @notice releases an imprisoned operator immidately
     * @dev in different situations such as a faulty improsenment or coordinated testing periods
     * * Governance can vote on releasing the prisoners
     * @dev onlyGovernance check is in Portal
     */
    function releasePrisoned(
        DataStoreUtils.DataStore storage DATASTORE,
        uint256 operatorId
    ) external {
        require(
            isPrisoned(DATASTORE, operatorId),
            "OracleUtils: NOT in prison"
        );
        DATASTORE.writeUintForId(operatorId, "released", block.timestamp);
        emit Released(operatorId);
    }

    /**
     * @notice Put an operator in prison, "release" points to the date the operator will be out
     */
    function imprison(
        DataStoreUtils.DataStore storage DATASTORE,
        uint256 _operatorId
    ) internal {
        DATASTORE.writeUintForId(
            _operatorId,
            "released",
            block.timestamp + PRISON_SENTENCE
        );
        emit Prisoned(_operatorId, block.timestamp + PRISON_SENTENCE);
    }

    /**
     * @notice checks if a validator can use pool funds
     * Creation of a Validator takes 2 steps.
     * Before entering beaconStake function, _canStake verifies the eligibility of
     * given pubKey that is proposed by an operator with proposeStake function.
     * Eligibility is defined by an optimistic alienation, check alienate() for info.
     *
     *  @param pubkey BLS12-381 public key of the validator
     *  @return true if:
     *   - pubkey should be proposeStaked
     *   - pubkey should not be alienated (https://bit.ly/3Tkc6UC)
     *   - validator's index should be lower than VERIFICATION_INDEX. Updated by Telescope.
     *  else:
     *      return false
     * @dev to optimize batch checks verificationIndex is taken as a memeory param
     */
    function _canStake(
        Oracle storage self,
        bytes calldata pubkey,
        uint256 verificationIndex
    ) internal view returns (bool) {
        return
            self._validators[pubkey].state == 1 &&
            self._validators[pubkey].index <= verificationIndex;
    }

    /**
     * @notice An "Alien" is a validator that is created with a false withdrawal credential, this is a malicious act.
     * @dev imprisonates the operator who proposed a malicious validator.
     */
    function _alienateValidator(
        Oracle storage self,
        DataStoreUtils.DataStore storage DATASTORE,
        bytes calldata _pk
    ) internal {
        require(
            self._validators[_pk].state == 1,
            "OracleUtils: NOT all alienPubkeys are pending"
        );
        uint256 planetId = self._validators[_pk].poolId;
        DATASTORE.subUintForId(planetId, "secured", DCU.DEPOSIT_AMOUNT);
        DATASTORE.addUintForId(planetId, "surplus", DCU.DEPOSIT_AMOUNT);
        self._validators[_pk].state = 69;

        imprison(DATASTORE, self._validators[_pk].operatorId);
        emit Alienated(_pk);
    }

    /**
     * @notice "Busting" refers to a false signal, meaning there is a signal but no Unstake
     * @dev imprisonates the operator who signaled a fake Unstake
     */
    function _bustSignal(
        Oracle storage self,
        DataStoreUtils.DataStore storage DATASTORE,
        bytes calldata _pk
    ) internal {
        require(
            self._validators[_pk].state == 3,
            "OracleUtils: pubkey is NOT signaled"
        );
        self._validators[_pk].state = 2;

        imprison(DATASTORE, self._validators[_pk].operatorId);
        emit Busted(_pk);
    }

    /**
     * @notice "Busting" refers to unsignaled withdrawal, meaning there is an unstake but no Signal
     * @dev imprisonates the operator who haven't signal the unstake
     */
    function _bustExit(
        Oracle storage self,
        DataStoreUtils.DataStore storage DATASTORE,
        bytes calldata _pk
    ) internal {
        require(
            self._validators[_pk].state == 2,
            "OracleUtils: Signaled, cannot be busted"
        );
        self._validators[_pk].state = 3;

        imprison(DATASTORE, self._validators[_pk].operatorId);
        emit Busted(_pk);
    }

    /**
     * @notice Updating VERIFICATION_INDEX, signaling that it is safe to allow
     * validators with lower index than VERIFICATION_INDEX to stake with staking pool funds
     * @param allValidatorsCount total number of validators to figure out what is the current Monopoly Requirement
     * @param validatorVerificationIndex index of the highest validator that is verified to be activated
     * @param alienatedPubkeys proposals with lower index than new_index who frontrunned proposeStake
     * with incorrect withdrawal credential results in imprisonment.
     */
    function updateVerificationIndex(
        Oracle storage self,
        DataStoreUtils.DataStore storage DATASTORE,
        uint256 allValidatorsCount,
        uint256 validatorVerificationIndex,
        bytes[] calldata alienatedPubkeys
    ) external onlyOracle(self) {
        require(!_isOracleActive(self), "OracleUtils: oracle is active");
        require(allValidatorsCount > 4999, "OracleUtils: low validator count");
        require(
            self.VALIDATORS_INDEX >= validatorVerificationIndex,
            "OracleUtils: high VERIFICATION_INDEX"
        );
        require(
            validatorVerificationIndex >= self.VERIFICATION_INDEX,
            "OracleUtils: low VERIFICATION_INDEX"
        );
        self.VERIFICATION_INDEX = validatorVerificationIndex;

        for (uint256 i; i < alienatedPubkeys.length; i++) {
            _alienateValidator(self, DATASTORE, alienatedPubkeys[i]);
        }

        self.MONOPOLY_THRESHOLD =
            (allValidatorsCount * MONOPOLY_RATIO) /
            PERCENTAGE_DENOMINATOR;

        emit VerificationIndexUpdated(validatorVerificationIndex);
    }

    /**
     * @notice regulating operators within Geode with verifiable proofs
     * @param bustedExits validators that have not signaled before Unstake
     * @param bustedSignals validators that are "mistakenly:)" signaled but not Unstaked
     * @param feeThefts [0]: Operator ids who have stolen MEV or block rewards, [1]: detected BlockNumber as proof
     * @dev Both of these functions results in imprisonment.
     */
    function regulateOperators(
        Oracle storage self,
        DataStoreUtils.DataStore storage DATASTORE,
        bytes[] calldata bustedExits,
        bytes[] calldata bustedSignals,
        uint256[2][] calldata feeThefts
    ) external onlyOracle(self) {
        require(!_isOracleActive(self), "OracleUtils: oracle is active");

        for (uint256 i; i < bustedExits.length; i++) {
            _bustExit(self, DATASTORE, bustedExits[i]);
        }

        for (uint256 j; j < bustedSignals.length; j++) {
            _bustSignal(self, DATASTORE, bustedSignals[j]);
        }
        for (uint256 k; k < feeThefts.length; k++) {
            imprison(DATASTORE, feeThefts[k][0]);
            emit FeeTheft(feeThefts[k][0], feeThefts[k][1]);
        }
    }

    /**
     * @notice                          ** Updating PricePerShare **
     */

    /**
     * @notice calculates the current price and expected report price
     * @dev surplus at the oracle time is found with the help of mint and burn buffers
     * @param _dailyBufferMintKey represents the gETH minted during oracleActivePeriod, unique to every day
     * @param _dailyBufferBurnKey represents the gETH burned during oracleActivePeriod, unique to every day
     * @dev calculates the totalEther amount, decreases the amount minted while oracle was working (first 30m),
     * finds the expected Oracle price by totalEther / supply , finds the current price by unbufferedEther / unbufferedSupply
     */
    function _findPricesClearBuffer(
        Oracle storage self,
        DataStoreUtils.DataStore storage DATASTORE,
        bytes32 _dailyBufferMintKey,
        bytes32 _dailyBufferBurnKey,
        uint256 _poolId,
        uint256 _beaconBalance
    ) internal returns (uint256, uint256) {
        uint256 totalEther = _beaconBalance +
            DATASTORE.readUintForId(_poolId, "secured") +
            DATASTORE.readUintForId(_poolId, "surplus");

        uint256 denominator = self.gETH.denominator();
        uint256 unbufferedEther;

        {
            uint256 price = self.gETH.pricePerShare(_poolId);
            unbufferedEther =
                totalEther -
                (DATASTORE.readUintForId(_poolId, _dailyBufferMintKey) *
                    price) /
                denominator;

            unbufferedEther +=
                (DATASTORE.readUintForId(_poolId, _dailyBufferBurnKey) *
                    price) /
                denominator;
        }

        uint256 supply = self.gETH.totalSupply(_poolId);

        uint256 unbufferedSupply = supply -
            DATASTORE.readUintForId(_poolId, _dailyBufferMintKey);

        unbufferedSupply += DATASTORE.readUintForId(
            _poolId,
            _dailyBufferBurnKey
        );

        // clears daily buffer for the gas refund
        DATASTORE.writeUintForId(_poolId, _dailyBufferMintKey, 0);
        DATASTORE.writeUintForId(_poolId, _dailyBufferBurnKey, 0);

        return (
            (unbufferedEther * denominator) / unbufferedSupply,
            (totalEther * denominator) / supply
        );
    }

    /**
     * @dev in order to prevent attacks from malicious Oracle there are boundaries to price & fee updates.
     * 1. Price should not be increased more than PERIOD_PRICE_INCREASE_LIMIT
     *  with the factor of how many days since oracleUpdateTimestamp has past.
     * 2. Price should not be decreased more than PERIOD_PRICE_DECREASE_LIMIT
     *  with the factor of how many days since oracleUpdateTimestamp has past.
     */
    function _sanityCheck(
        Oracle storage self,
        uint256 _id,
        uint256 _periodsSinceUpdate,
        uint256 _newPrice
    ) internal view {
        uint256 curPrice = self.gETH.pricePerShare(_id);
        uint256 maxPrice = curPrice +
            ((curPrice *
                self.PERIOD_PRICE_INCREASE_LIMIT *
                _periodsSinceUpdate) / PERCENTAGE_DENOMINATOR);

        uint256 minPrice = curPrice -
            ((curPrice *
                self.PERIOD_PRICE_DECREASE_LIMIT *
                _periodsSinceUpdate) / PERCENTAGE_DENOMINATOR);

        require(
            _newPrice >= minPrice && _newPrice <= maxPrice,
            "OracleUtils: price is insane"
        );
    }

    /**
     * @notice syncing the price of g-derivative after checking the merkle proofs and the sanity of it.
     * @param _beaconBalance the total balance -excluding fees- of all validators of this pool
     * @param _periodsSinceUpdate time(s) since the last update of the g-derivative's price.
     * while public pools are using ORACLE_UPDATE_TIMESTAMP, private pools will refer gEth.priceUpdateTimestamp()
     * @param _priceProofs the merkle proof of the latests prices that are reported by Telescope
     * @dev if merkle proof holds the oracle price, new price is the current price of the derivative
     */
    function _priceSync(
        Oracle storage self,
        DataStoreUtils.DataStore storage DATASTORE,
        bytes32[2] memory _dailyBufferKeys,
        uint256 _poolId,
        uint256 _beaconBalance,
        uint256 _periodsSinceUpdate, // calculation for this changes for private pools
        bytes32[] calldata _priceProofs // uint256 prices[]
    ) internal {
        (uint256 oraclePrice, uint256 price) = _findPricesClearBuffer(
            self,
            DATASTORE,
            _dailyBufferKeys[0],
            _dailyBufferKeys[1],
            _poolId,
            _beaconBalance
        );
        _sanityCheck(self, _poolId, _periodsSinceUpdate, oraclePrice);
        bytes32 node = keccak256(abi.encodePacked(_poolId, oraclePrice));

        require(
            MerkleProof.verify(_priceProofs, self.PRICE_MERKLE_ROOT, node),
            "OracleUtils: NOT all proofs are valid"
        );

        self.gETH.setPricePerShare(price, _poolId);
    }

    /**
     * @notice Telescope reports all of the g-derivate prices with a new PRICE_MERKLE_ROOT
     * @notice after report updates the prices of the public pools
     * @notice updates the ORACLE_UPDATE_TIMESTAMP
     * @dev if merkle proof holds the oracle price, new price is the found price of the derivative
     */
    function reportOracle(
        Oracle storage self,
        DataStoreUtils.DataStore storage DATASTORE,
        bytes32 merkleRoot,
        uint256[] calldata beaconBalances,
        bytes32[][] calldata priceProofs
    ) external onlyOracle(self) {
        require(_isOracleActive(self), "OracleUtils: oracle is NOT active");

        {
            uint256 planetCount = DATASTORE.allIdsByType[5].length;
            require(
                beaconBalances.length == planetCount,
                "OracleUtils: incorrect beaconBalances length"
            );
            require(
                priceProofs.length == planetCount,
                "OracleUtils: incorrect priceProofs length"
            );
        }

        self.PRICE_MERKLE_ROOT = merkleRoot;

        uint256 periodsSinceUpdate = (block.timestamp +
            ORACLE_ACTIVE_PERIOD -
            self.ORACLE_UPDATE_TIMESTAMP) / ORACLE_PERIOD;

        // refering the first second of the period: block.timestamp - (block.timestamp % ORACLE_PERIOD)
        bytes32[2] memory dailyBufferKeys = [
            DataStoreUtils.getKey(
                block.timestamp - (block.timestamp % ORACLE_PERIOD),
                "mintBuffer"
            ),
            DataStoreUtils.getKey(
                block.timestamp - (block.timestamp % ORACLE_PERIOD),
                "burnBuffer"
            )
        ];

        for (uint256 i = 0; i < beaconBalances.length; i++) {
            _priceSync(
                self,
                DATASTORE,
                dailyBufferKeys,
                DATASTORE.allIdsByType[5][i],
                beaconBalances[i],
                periodsSinceUpdate,
                priceProofs[i]
            );
        }
        self.ORACLE_UPDATE_TIMESTAMP =
            block.timestamp -
            (block.timestamp % ORACLE_PERIOD);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.7;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "./DataStoreUtilsLib.sol";
import "../../interfaces/IgETH.sol";
import "../../interfaces/IMiniGovernance.sol";
import {IERC20InterfacePermitUpgradable as IgETHInterface} from "../../interfaces/IERC20InterfacePermitUpgradable.sol";
import "../../interfaces/ISwap.sol";
import "../../interfaces/ILPToken.sol";

/**
 * @author Icebear & Crash Bandicoot
 * @title MaintainerUtils library to be used with a DataStore
 * @notice for Geode, there are different TYPEs active within Staking operations.
 * These types(4,5,6) always has a maintainer.
 * The staking logic is shaped around the control of maintainers over pools.
 *
 * @dev ALL "fee" variables are limited by PERCENTAGE_DENOMINATOR = 100%
 * Note refer to DataStoreUtils before reviewing
 */
library MaintainerUtils {
    using DataStoreUtils for DataStoreUtils.DataStore;

    event IdInitiated(uint256 id, uint256 TYPE);
    event MaintainerChanged(uint256 id, address newMaintainer);
    event MaintainerFeeSwitched(
        uint256 id,
        uint256 fee,
        uint256 effectiveTimestamp // the timestamp when the fee will start to be used after switch
    );

    /// @notice PERCENTAGE_DENOMINATOR represents 100%
    uint256 public constant PERCENTAGE_DENOMINATOR = 10**10;

    /// @notice when a maintainer changes the fee, it is effective after a delay
    uint256 public constant SWITCH_LATENCY = 3 days;

    /// @notice default DWP parameters
    uint256 public constant DEFAULT_A = 60;
    uint256 public constant DEFAULT_FEE = (4 * PERCENTAGE_DENOMINATOR) / 10000;
    uint256 public constant DEFAULT_ADMIN_FEE =
        (5 * PERCENTAGE_DENOMINATOR) / 10;

    modifier initiator(
        DataStoreUtils.DataStore storage DATASTORE,
        uint256 _TYPE,
        uint256 _id,
        address _maintainer
    ) {
        require(
            msg.sender == DATASTORE.readAddressForId(_id, "CONTROLLER"),
            "MaintainerUtils: sender NOT CONTROLLER"
        );
        require(
            DATASTORE.readUintForId(_id, "TYPE") == _TYPE,
            "MaintainerUtils: id NOT correct TYPE"
        );
        require(
            DATASTORE.readUintForId(_id, "initiated") == 0,
            "MaintainerUtils: already initiated"
        );

        DATASTORE.writeAddressForId(_id, "maintainer", _maintainer);
        DATASTORE.writeUintForId(_id, "initiated", block.timestamp);

        _;

        emit IdInitiated(_id, _TYPE);
    }

    /**
     * @notice restricts the access to given function based on TYPE
     * @notice also allows onlyMaintainer check whenever required
     * @param expectMaintainer restricts the access to only maintainer
     * @param restrictionMap 0: Operator = TYPE(4), Planet = TYPE(5), Comet = TYPE(6),
     */
    function authenticate(
        DataStoreUtils.DataStore storage DATASTORE,
        uint256 id,
        bool expectMaintainer,
        bool[3] memory restrictionMap
    ) internal view {
        if (expectMaintainer) {
            require(
                msg.sender == DATASTORE.readAddressForId(id, "maintainer"),
                "MaintainerUtils: sender NOT maintainer"
            );
        }
        uint256 typeOfId = DATASTORE.readUintForId(id, "TYPE");

        require(
            DATASTORE.readUintForId(id, "initiated") != 0,
            "MaintainerUtils: ID is not initiated"
        );

        if (typeOfId == 4) {
            require(
                restrictionMap[0] == true,
                "MaintainerUtils: TYPE NOT allowed"
            );
        } else if (typeOfId == 5) {
            require(
                restrictionMap[1] == true,
                "MaintainerUtils: TYPE NOT allowed"
            );
        } else if (typeOfId == 6) {
            require(
                restrictionMap[2] == true,
                "MaintainerUtils: TYPE NOT allowed"
            );
        } else revert("MaintainerUtils: invalid TYPE");
    }

    /**
     * @notice                      ** Initiate ID functions **
     */

    /**
     * @notice initiates ID as a node operator
     * @dev requires ID to be approved as a node operator with a specific CONTROLLER
     */
    function initiateOperator(
        DataStoreUtils.DataStore storage DATASTORE,
        uint256 id,
        uint256 fee,
        address maintainer
    ) external initiator(DATASTORE, 4, id, maintainer) {
        DATASTORE.writeUintForId(id, "fee", fee);
    }

    /**
     * @notice initiates ID as a planet (public pool): deploys a miniGovernance, a Dynamic Withdrawal Pool, an ERC1155Interface
     * @dev requires ID to be approved as a planet with a specific CONTROLLER
     * @param uintSpecs 0:_id, 1:_fee, 2:_MINI_GOVERNANCE_VERSION
     * @param addressSpecs 0:gETH, 1:_maintainer, 2:DEFAULT_gETH_INTERFACE_, 3:DEFAULT_DWP, 4:DEFAULT_LP_TOKEN
     * @param interfaceSpecs 0: interface name, 1: interface symbol
     */
    function initiatePlanet(
        DataStoreUtils.DataStore storage DATASTORE,
        uint256[3] memory uintSpecs,
        address[5] memory addressSpecs,
        string[2] calldata interfaceSpecs
    )
        external
        initiator(DATASTORE, 5, uintSpecs[0], addressSpecs[1])
        returns (
            address miniGovernance,
            address gInterface,
            address withdrawalPool
        )
    {
        DATASTORE.writeUintForId(uintSpecs[0], "fee", uintSpecs[1]);
        {
            miniGovernance = _deployMiniGovernance(
                DATASTORE,
                addressSpecs[0],
                uintSpecs[0],
                uintSpecs[2]
            );
        }
        {
            gInterface = Clones.clone(addressSpecs[2]);
            IgETHInterface(gInterface).initialize(
                uintSpecs[0],
                interfaceSpecs[0],
                interfaceSpecs[1],
                addressSpecs[0]
            );
        }
        {
            withdrawalPool = _deployWithdrawalPool(
                DATASTORE,
                uintSpecs[0],
                addressSpecs[0],
                addressSpecs[3],
                addressSpecs[4]
            );
        }
    }

    /**
     * @notice initiates ID as a comet (private pool)
     * @dev requires ID to be approved as comet with a specific CONTROLLER,
     * NOTE CONTROLLER check will be surpassed with portal.
     */
    function initiateComet(
        DataStoreUtils.DataStore storage DATASTORE,
        uint256 id,
        uint256 fee,
        address maintainer
    ) external initiator(DATASTORE, 6, id, maintainer) {
        DATASTORE.writeUintForId(id, "fee", fee);
    }

    /**
     * @notice deploys a mini governance contract that will be used as a withdrawal credential
     * using an approved MINI_GOVERNANCE_VERSION
     * @return miniGovernance address which is deployed
     */
    function _deployMiniGovernance(
        DataStoreUtils.DataStore storage DATASTORE,
        address _gETH,
        uint256 _id,
        uint256 _versionId
    ) internal returns (address miniGovernance) {
        ERC1967Proxy newGovernance = new ERC1967Proxy(
            DATASTORE.readAddressForId(_versionId, "CONTROLLER"),
            abi.encodeWithSelector(
                IMiniGovernance(address(0)).initialize.selector,
                _gETH,
                address(this),
                DATASTORE.readAddressForId(_id, "CONTROLLER"),
                _id,
                _versionId
            )
        );
        DATASTORE.writeAddressForId(
            _id,
            "miniGovernance",
            address(newGovernance)
        );
        miniGovernance = address(newGovernance);
    }

    /**
     * @notice deploys a new withdrawal pool using DEFAULT_DWP
     * @dev sets the withdrawal pool and LP token for id
     * @return withdrawalPool address which is deployed
     */
    function _deployWithdrawalPool(
        DataStoreUtils.DataStore storage DATASTORE,
        uint256 _id,
        address _gETH,
        address _DEFAULT_DWP,
        address _DEFAULT_LP_TOKEN
    ) internal returns (address withdrawalPool) {
        withdrawalPool = Clones.clone(_DEFAULT_DWP);
        bytes memory NAME = DATASTORE.readBytesForId(_id, "NAME");
        address WPToken = ISwap(withdrawalPool).initialize(
            IgETH(_gETH),
            _id,
            string(abi.encodePacked(NAME, "-Geode LP Token")),
            string(abi.encodePacked(NAME, "-LP")),
            DEFAULT_A,
            DEFAULT_FEE,
            DEFAULT_ADMIN_FEE,
            _DEFAULT_LP_TOKEN
        );
        DATASTORE.writeAddressForId(_id, "withdrawalPool", withdrawalPool);
        DATASTORE.writeAddressForId(_id, "LPToken", WPToken);
    }

    /**
     * @notice "Maintainer" is a shared logic (like "NAME") by both operators and private or public pools.
     * Maintainers have permissiones to maintain the given id like setting a new fee or interface as
     * well as creating validators etc. for operators.
     * @dev every ID has one maintainer that is set by CONTROLLER
     */
    function getMaintainerFromId(
        DataStoreUtils.DataStore storage DATASTORE,
        uint256 id
    ) external view returns (address maintainer) {
        maintainer = DATASTORE.readAddressForId(id, "maintainer");
    }

    /**
     * @notice CONTROLLER of the ID can change the maintainer to any address other than ZERO_ADDRESS
     * @dev it is wise to change the CONTROLLER before the maintainer, in case of any migration
     * @dev handle with care
     * NOTE intended (suggested) usage is to set a contract address that will govern the id for maintainer,
     * while keeping the controller as a multisig or provide smt like 0x000000000000000000000000000000000000dEaD
     */
    function changeMaintainer(
        DataStoreUtils.DataStore storage DATASTORE,
        uint256 id,
        address newMaintainer
    ) external {
        require(
            msg.sender == DATASTORE.readAddressForId(id, "CONTROLLER"),
            "MaintainerUtils: sender NOT CONTROLLER"
        );
        require(
            newMaintainer != address(0),
            "MaintainerUtils: maintainer can NOT be zero"
        );

        DATASTORE.writeAddressForId(id, "maintainer", newMaintainer);
        emit MaintainerChanged(id, newMaintainer);
    }

    /**
     * @notice Gets fee percentage in terms of PERCENTAGE_DENOMINATOR.
     * @dev even if MAX_MAINTAINER_FEE is decreased later, it returns limited maximum.
     * @param id planet, comet or operator ID
     * @return fee = percentage * PERCENTAGE_DENOMINATOR / 100 as a perfcentage
     */
    function getMaintainerFee(
        DataStoreUtils.DataStore storage DATASTORE,
        uint256 id
    ) internal view returns (uint256 fee) {
        if (DATASTORE.readUintForId(id, "feeSwitch") > block.timestamp) {
            return DATASTORE.readUintForId(id, "priorFee");
        }
        return DATASTORE.readUintForId(id, "fee");
    }

    /**
     * @notice Changes the fee that is applied by distributeFee on Oracle Updates.
     * @dev advise that 100% == PERCENTAGE_DENOMINATOR
     * @param id planet, comet or operator ID
     */
    function switchMaintainerFee(
        DataStoreUtils.DataStore storage DATASTORE,
        uint256 id,
        uint256 newFee
    ) external {
        require(
            block.timestamp > DATASTORE.readUintForId(id, "feeSwitch"),
            "MaintainerUtils: fee is currently switching"
        );
        DATASTORE.writeUintForId(
            id,
            "priorFee",
            DATASTORE.readUintForId(id, "fee")
        );
        DATASTORE.writeUintForId(
            id,
            "feeSwitch",
            block.timestamp + SWITCH_LATENCY
        );
        DATASTORE.writeUintForId(id, "fee", newFee);

        emit MaintainerFeeSwitched(
            id,
            newFee,
            block.timestamp + SWITCH_LATENCY
        );
    }

    /**
     * @notice When a fee is collected it is put in the maintainer's wallet
     * @notice Maintainer wallet also keeps Ether put in Portal by Operator Maintainer to make proposeStake easier, instead of sending n ETH to contract
     * while preStaking for n validator(s) for each time. Operator can put some ETHs to their wallet
     * and from there, ETHs can be used to proposeStake. Then when it is approved and staked, it will be
     * added back to the wallet to be used for other proposeStake calls.
     * @param id the id of the Maintainer
     * @return walletBalance the balance of Operator with the given _operatorId has
     */
    function getMaintainerWalletBalance(
        DataStoreUtils.DataStore storage DATASTORE,
        uint256 id
    ) external view returns (uint256 walletBalance) {
        walletBalance = DATASTORE.readUintForId(id, "wallet");
    }

    /**
     * @notice To increase the balance of a Maintainer's wallet
     * @param _id the id of the Operator
     * @param _value Ether (in Wei) amount to increase the wallet balance.
     * @return success boolean value which is true if successful, should be used by Operator is Maintainer is a contract.
     */
    function _increaseMaintainerWallet(
        DataStoreUtils.DataStore storage DATASTORE,
        uint256 _id,
        uint256 _value
    ) internal returns (bool success) {
        DATASTORE.addUintForId(_id, "wallet", _value);
        return true;
    }

    /**
     * @notice To decrease the balance of an Operator's wallet
     * @dev only maintainer can decrease the balance
     * @param _id the id of the Operator
     * @param _value Ether (in Wei) amount to decrease the wallet balance and send back to Maintainer.
     * @return success boolean value which is "sent", should be used by Operator is Maintainer is a contract.
     */
    function _decreaseMaintainerWallet(
        DataStoreUtils.DataStore storage DATASTORE,
        uint256 _id,
        uint256 _value
    ) internal returns (bool success) {
        require(
            DATASTORE.readUintForId(_id, "wallet") >= _value,
            "MaintainerUtils: NOT enough balance in wallet"
        );

        DATASTORE.subUintForId(_id, "wallet", _value);
        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./DataStoreUtilsLib.sol";
import {DepositContractUtils as DCU} from "./DepositContractUtilsLib.sol";
import "./MaintainerUtilsLib.sol";
import "./OracleUtilsLib.sol";
import "../../interfaces/IgETH.sol";
import "../../interfaces/IMiniGovernance.sol";
import "../../interfaces/ISwap.sol";

/**
 * @author Icebear & Crash Bandicoot
 * @title StakeUtils library
 * @notice Exclusively contains functions related to ETH Liquid Staking design
 * @notice biggest part of the functionality is related to Dynamic Staking Pools
 * which relies on continuous buybacks (DWP) to maintain the price health with debt/surplus calculations
 * @dev Contracts relying on this library must initialize StakeUtils.StakePool
 * @dev ALL "fee" variables are limited by PERCENTAGE_DENOMINATOR.
 * * For example, when fee is equal to PERCENTAGE_DENOMINATOR/2, it means 50% of the fee
 * Note refer to DataStoreUtils before reviewing
 * Note refer to MaintainerUtilsLib before reviewing
 * Note refer to OracleUtilsLib before reviewing
 * Note *suggested* refer to GeodeUtils before reviewing
 * Note beware of the staking pool and operator implementations:
 *
 * Type 4 stands for Operators:
 * They maintain Beacon Chain Validators on behalf of Planets and Comets
 * * only if they are allowed to
 * Operators have properties like fee(as a percentage), maintainer.
 *
 * Type 5 stands for Public Staking Pool (Planets):
 * * Every Planet is also an Operator by design.
 * * * Planets inherits Operator functionalities and parameters, with additional
 * * * properties related to miniGovernances and staking pools - surplus, secured, withdrawalPool etc.
 * * ID of a pool represents an id of gETH.
 * * For now, creation of staking pools are not permissionless but the usage of it is.
 * * * Meaning Everyone can stake and unstake using public pools.
 *
 * Type 6 stands for Private Staking Pools (Comets):
 * * It is permissionless, one can directly create a Comet by simply
 * * * choosing a name and sending MIN_AMOUNT which is expected to be 32 ether.
 * * GeodeUtils generates IDs based on types, meaning same name can be used for a Planet and a Comet simultaneously.
 * * The creation process is permissionless but staking is not.
 * * * Meaning Only Comet's maintainer can stake but everyone can hold the derivative
 * * In Comets, there is a Withdrawal Queue instead of DWP.
 * * NOT IMPLEMENTED YET
 *
 * Type 11 stands for a new Mini Governance implementation id:
 * * like always CONTROLLER is the implementation contract position
 * * requires the approval of Senate
 * * Pools are in "Isolation Mode" until their mini governance is upgraded to given proposal ID.
 * * * Meaning, no more Depositing or Staking can happen.
 */

library StakeUtils {
    event ValidatorPeriodUpdated(uint256 operatorId, uint256 newPeriod);
    event OperatorApproval(
        uint256 planetId,
        uint256 operatorId,
        uint256 allowance
    );
    event PoolPaused(uint256 id);
    event PoolUnpaused(uint256 id);
    event ProposeStaked(bytes pubkey, uint256 planetId, uint256 operatorId);
    event BeaconStaked(bytes pubkey);
    event UnstakeSignal(uint256 poolId, bytes pubkey);
    event WithdrawalBoostChanged(
        uint256 poolId,
        uint256 withdrawalBoost,
        uint256 effectiveAfter
    );
    using DataStoreUtils for DataStoreUtils.DataStore;
    using MaintainerUtils for DataStoreUtils.DataStore;
    using OracleUtils for OracleUtils.Oracle;

    /**
     * @notice StakePool includes the parameters related to multiple Staking Pool Contracts.
     * @notice Dynamic Staking Pool contains a staking pool that works with a *bound* Withdrawal Pool (DWP) to create best pricing
     * for the staking derivative. Withdrawal Pools (DWP) uses StableSwap algorithm with Dynamic Pegs.
     * @param gETH ERC1155 contract that keeps the totalSupply, pricePerShare and balances of all StakingPools by ID
     * @param DEFAULT_gETH_INTERFACE default interface for the g-derivative, currently equivalent to ERC20
     * @param DEFAULT_DWP Dynamic Withdrawal Pool implementation, a STABLESWAP pool that will be used for given ID
     * @param DEFAULT_LP_TOKEN LP token implementation that will be used for DWP of given ID
     * @param MINI_GOVERNANCE_VERSION  limited to be changed with the senate approval.
     * * versioning is done by GeodeUtils.proposal.id, implementation is stored in DataStore.id.controller
     * @param MAX_MAINTAINER_FEE  limits fees, set by GOVERNANCE
     * @param BOOSTRAP_PERIOD during this period the surplus of the pool can not be burned for withdrawals, initially set to 6 months
     * @param BOOST_SWITCH_LATENCY when a maintainer changes the withdrawalBoost, it is effective after a delay
     * @param COMET_TAX tax that will be taken from private pools, limited by MAX_MAINTAINER_FEE, set by GOVERNANCE
     * @dev gETH should not be changed, ever!
     * @dev changing some of these parameters (gETH, ORACLE) MUST require a contract upgrade to ensure security.
     * We can change this in the future with a better GeodeUtils design, giving every update a type, like MINI_GOVERNANCE_VERSION
     **/
    struct StakePool {
        IgETH gETH;
        OracleUtils.Oracle TELESCOPE;
        address GOVERNANCE;
        address DEFAULT_gETH_INTERFACE;
        address DEFAULT_DWP;
        address DEFAULT_LP_TOKEN;
        uint256 MINI_GOVERNANCE_VERSION;
        uint256 MAX_MAINTAINER_FEE;
        uint256 BOOSTRAP_PERIOD;
        uint256 BOOST_SWITCH_LATENCY;
        uint256 COMET_TAX;
        uint256[5] __gap;
    }

    /// @notice PERCENTAGE_DENOMINATOR represents 100%
    uint256 public constant PERCENTAGE_DENOMINATOR = 10**10;

    /// @notice limiting the operator.validatorPeriod, currently around 5 years
    uint256 public constant MIN_VALIDATOR_PERIOD = 90 days;
    uint256 public constant MAX_VALIDATOR_PERIOD = 1825 days;

    /// @notice ignoring any buybacks if the DWP has a low debt
    uint256 public constant IGNORABLE_DEBT = 1 ether;

    modifier onlyGovernance(StakePool storage self) {
        require(
            msg.sender == self.GOVERNANCE,
            "StakeUtils: sender NOT GOVERNANCE"
        );
        _;
    }

    /**
     * @notice                      ** gETH specific functions **
     */

    /**
     * @notice sets a erc1155Interface for gETH
     * @param _interface address of the new gETH ERC1155 interface for given ID
     * @dev every interface has a unique index within "interfaces" dynamic array.
     * * even if unsetted, it just replaces the implementation with address(0) for obvious security reasons
     */
    function _setInterface(
        StakePool storage self,
        DataStoreUtils.DataStore storage DATASTORE,
        uint256 id,
        address _interface
    ) internal {
        uint256 interfacesLength = DATASTORE.readUintForId(
            id,
            "interfacesLength"
        );
        require(
            !self.gETH.isInterface(_interface, id),
            "StakeUtils: already interface"
        );
        DATASTORE.writeAddressForId(
            id,
            DataStoreUtils.getKey(interfacesLength, "interfaces"),
            _interface
        );
        DATASTORE.addUintForId(id, "interfacesLength", 1);
        self.gETH.setInterface(_interface, id, true);
    }

    /**
     * @dev Consensys Diligence Audit team advised that there are many issues with having multiple interfaces,
     * as well as the possibility of setting a malicious interface.
     *
     * Interfaces are developed to provide a flexibility for the owners of a Staking Pools, however these risks
     * are very strong blockers, even with gETH.Avoiders implementation.
     *
     * Until there is a request for other interfaces, with proper solutions for provided issues,
     * we are limiting the abilities of Maintainers on Interfaces, except standard ERC20.
     */

    // function setInterface(
    //     StakePool storage self,
    //     DataStoreUtils.DataStore storage DATASTORE,
    //     uint256 id,
    //     address _interface
    // ) external {
    //     DATASTORE.authenticate(id, true, [false, true, true]);
    //     _setInterface(self, DATASTORE, id, _interface);
    // }

    /**
     * @notice unsets a erc1155Interface for gETH with given index -acquired from allInterfaces()-
     * @param index index of given interface at the "interfaces" dynamic array
     * @dev every interface has a unique interface index within interfaces dynamic array.
     * * even if unsetted, it just replaces the implementation with address(0) for obvious security reasons
     * @dev old Interfaces will still be active if not unsetted
     */
    // function unsetInterface(
    //     StakePool storage self,
    //     DataStoreUtils.DataStore storage DATASTORE,
    //     uint256 id,
    //     uint256 index
    // ) external {
    //     DATASTORE.authenticate(id, true, [false, true, true]);
    //     address _interface = DATASTORE.readAddressForId(
    //         id,
    //         DataStoreUtils.getKey(index, "interfaces")
    //     );
    //     require(
    //         _interface != address(0) && self.gETH.isInterface(_interface, id),
    //         "StakeUtils: already NOT interface"
    //     );
    //     DATASTORE.writeAddressForId(
    //         id,
    //         DataStoreUtils.getKey(index, "interfaces"),
    //         address(0)
    //     );
    //     self.gETH.setInterface(_interface, id, false);
    // }

    /**
     * @notice lists all interfaces, unsetted interfaces will return address(0)
     */
    function allInterfaces(
        DataStoreUtils.DataStore storage DATASTORE,
        uint256 id
    ) external view returns (address[] memory) {
        uint256 interfacesLength = DATASTORE.readUintForId(
            id,
            "interfacesLength"
        );
        address[] memory interfaces = new address[](interfacesLength);
        for (uint256 i = 0; i < interfacesLength; i++) {
            interfaces[i] = DATASTORE.readAddressForId(
                id,
                DataStoreUtils.getKey(i, "interfaces")
            );
        }
        return interfaces;
    }

    /**
     * @notice                      ** Maintainer Initiators **
     */
    /**
     * @notice initiates ID as an node operator
     * @dev requires ID to be approved as a node operator with a specific CONTROLLER
     * @param _validatorPeriod the expected maximum staking interval. This value should between
     * * MIN_VALIDATOR_PERIOD and MAX_VALIDATOR_PERIOD values defined as constants above,
     * * this check is done inside updateValidatorPeriod function.
     * Operator can unstake at any given point before this period ends.
     * If operator disobeys this rule, it can be prisoned with blameOperator()
     */
    function initiateOperator(
        StakePool storage self,
        DataStoreUtils.DataStore storage DATASTORE,
        uint256 _id,
        uint256 _fee,
        address _maintainer,
        uint256 _validatorPeriod
    ) external {
        require(
            _fee <= self.MAX_MAINTAINER_FEE,
            "StakeUtils: MAX_MAINTAINER_FEE ERROR"
        );
        DATASTORE.initiateOperator(_id, _fee, _maintainer);
        _updateValidatorPeriod(DATASTORE, _id, _validatorPeriod);
    }

    /**
     * @notice initiates ID as a planet (public pool)
     * @dev requires ID to be approved as a planet with a specific CONTROLLER
     * @param _interfaceSpecs 0: interface name, 1: interface symbol, currently ERC20 specs.
     */
    function initiatePlanet(
        StakePool storage self,
        DataStoreUtils.DataStore storage DATASTORE,
        uint256 _id,
        uint256 _fee,
        address _maintainer,
        string[2] calldata _interfaceSpecs
    ) external {
        require(
            _fee <= self.MAX_MAINTAINER_FEE,
            "StakeUtils: MAX_MAINTAINER_FEE ERROR"
        );

        address[5] memory addressSpecs = [
            address(self.gETH),
            _maintainer,
            self.DEFAULT_gETH_INTERFACE,
            self.DEFAULT_DWP,
            self.DEFAULT_LP_TOKEN
        ];
        uint256[3] memory uintSpecs = [_id, _fee, self.MINI_GOVERNANCE_VERSION];
        (
            address miniGovernance,
            address gInterface,
            address withdrawalPool
        ) = DATASTORE.initiatePlanet(uintSpecs, addressSpecs, _interfaceSpecs);

        DATASTORE.writeBytesForId(
            _id,
            "withdrawalCredential",
            DCU.addressToWC(miniGovernance)
        );

        _setInterface(self, DATASTORE, _id, gInterface);

        // initially 1 ETHER = 1 ETHER
        self.gETH.setPricePerShare(1 ether, _id);

        // transfer ownership of DWP to GOVERNANCE
        Ownable(withdrawalPool).transferOwnership(self.GOVERNANCE);
        // approve token so we can use it in buybacks
        self.gETH.setApprovalForAll(withdrawalPool, true);
    }

    /**
     * @notice                      ** Governance specific functions **
     */

    /**
     * @notice called when a proposal(TYPE=11) for a new MiniGovernance is approved by Senate
     * @dev CONTROLLER of the proposal id represents the implementation address
     * @dev This function seems like everyone can call, but it is called inside portal after approveProposal function
     * * and approveProposal has onlySenate modifier, can be called only by senate.
     */
    function setMiniGovernanceVersion(
        StakePool storage self,
        DataStoreUtils.DataStore storage DATASTORE,
        uint256 id
    ) external {
        require(DATASTORE.readUintForId(id, "TYPE") == 11);
        self.MINI_GOVERNANCE_VERSION = id;
    }

    /**
     * @notice                      ** Maintainer specific functions **
     */

    /**
     * @notice changes maintainer of the given operator, planet or comet
     * @dev Seems like authenticate is not correct, but authenticate checks for maintainer
     * and this function expects controller and DATASTORE.changeMaintainer checks that.
     */
    function changeMaintainer(
        DataStoreUtils.DataStore storage DATASTORE,
        uint256 id,
        address newMaintainer
    ) external {
        DATASTORE.authenticate(id, false, [true, true, true]);
        DATASTORE.changeMaintainer(id, newMaintainer);
    }

    /**
     * @param newFee new fee percentage in terms of PERCENTAGE_DENOMINATOR, reverts if given more than MAX_MAINTAINER_FEE
     * @dev there is a 7 days delay before the new fee is activated,
     * * this protect the pool maintainers from making bad operator choices
     */
    function switchMaintainerFee(
        StakePool storage self,
        DataStoreUtils.DataStore storage DATASTORE,
        uint256 id,
        uint256 newFee
    ) external {
        DATASTORE.authenticate(id, true, [true, true, true]);
        require(
            newFee <= self.MAX_MAINTAINER_FEE,
            "StakeUtils: MAX_MAINTAINER_FEE ERROR"
        );
        DATASTORE.switchMaintainerFee(id, newFee);
    }

    /**
     * @dev only maintainer can increase the balance directly,
     * * other than that it also collects validator rewards
     */
    function increaseMaintainerWallet(
        DataStoreUtils.DataStore storage DATASTORE,
        uint256 id
    ) external returns (bool success) {
        DATASTORE.authenticate(id, true, [true, false, false]);

        return DATASTORE._increaseMaintainerWallet(id, msg.value);
    }

    /**
     * @dev only maintainer can decrease the balance directly,
     * * other than that it can be used to propose Validators
     * @dev if a maintainer is in prison, it can not decrease the wallet
     */
    function decreaseMaintainerWallet(
        DataStoreUtils.DataStore storage DATASTORE,
        uint256 id,
        uint256 value
    ) external returns (bool success) {
        DATASTORE.authenticate(id, true, [true, true, true]);

        require(
            !OracleUtils.isPrisoned(DATASTORE, id),
            "StakeUtils: you are in prison, get in touch with governance"
        );

        require(
            address(this).balance >= value,
            "StakeUtils: not enough balance in Portal (?)"
        );

        bool decreased = DATASTORE._decreaseMaintainerWallet(id, value);

        (bool sent, ) = msg.sender.call{value: value}("");
        require(decreased && sent, "StakeUtils: Failed to send ETH");
        return sent;
    }

    /**
     * @notice                           ** Pool - Operator interactions **
     */
    /**
     * @param withdrawalBoost the percentage of arbitrague that will be shared
     * with Operator on Unstake. Can be used to incentivise Unstakes in case of depeg
     * @dev to prevent malicious swings in the withdrawal boost that can harm the competition,
     * Boost changes is also has a delay.
     */
    function switchWithdrawalBoost(
        StakePool storage self,
        DataStoreUtils.DataStore storage DATASTORE,
        uint256 poolId,
        uint256 withdrawalBoost
    ) external {
        DATASTORE.authenticate(poolId, true, [false, true, true]);
        require(
            block.timestamp > DATASTORE.readUintForId(poolId, "boostSwitch"),
            "StakeUtils: boost is currently switching"
        );
        DATASTORE.writeUintForId(
            poolId,
            "priorBoost",
            DATASTORE.readUintForId(poolId, "withdrawalBoost")
        );
        DATASTORE.writeUintForId(
            poolId,
            "boostSwitch",
            block.timestamp + self.BOOST_SWITCH_LATENCY
        );
        DATASTORE.writeUintForId(poolId, "withdrawalBoost", withdrawalBoost);

        emit WithdrawalBoostChanged(
            poolId,
            withdrawalBoost,
            block.timestamp + self.BOOST_SWITCH_LATENCY
        );
    }

    /**
     * @notice returns the withdrawalBoost with a time delay
     */
    function getWithdrawalBoost(
        DataStoreUtils.DataStore storage DATASTORE,
        uint256 id
    ) internal view returns (uint256 boost) {
        if (DATASTORE.readUintForId(id, "boostSwitch") > block.timestamp) {
            return DATASTORE.readUintForId(id, "priorBoost");
        }
        return DATASTORE.readUintForId(id, "withdrawalBoost");
    }

    /** *
     * @notice operatorAllowence is the number of validators that the given Operator is allowed to create on behalf of the Planet
     * @dev an operator can not create new validators if:
     * * 1. allowence is 0 (zero)
     * * 2. lower than the current (proposed + active) number of validators
     * * But if operator withdraws a validator, then able to create a new one.
     * @dev prestake checks the approved validator count to make sure the number of validators are not bigger than allowence
     * @dev allowence doesn't change when new validators created or old ones are unstaked.
     * @return allowance
     */
    function operatorAllowance(
        DataStoreUtils.DataStore storage DATASTORE,
        uint256 poolId,
        uint256 operatorId
    ) public view returns (uint256 allowance) {
        allowance = DATASTORE.readUintForId(
            poolId,
            DataStoreUtils.getKey(operatorId, "allowance")
        );
    }

    /**
     * @notice To allow a Node Operator run validators for your Planet with Max number of validators.
     * * This number can be set again at any given point in the future.
     *
     * @dev If planet decreases the approved validator count, below current running validator,
     * operator can only withdraw until to new allowence.
     * @dev only maintainer of _planetId can approve an Operator
     * @param poolId the gETH id of the Planet, only Maintainer can call this function
     * @param operatorId the id of the Operator to allow them create validators for a given Planet
     * @param allowance the MAX number of validators that can be created by the Operator for a given Planet
     */
    function approveOperator(
        DataStoreUtils.DataStore storage DATASTORE,
        uint256 poolId,
        uint256 operatorId,
        uint256 allowance
    ) external returns (bool) {
        DATASTORE.authenticate(poolId, true, [false, true, true]);
        DATASTORE.authenticate(operatorId, false, [true, false, false]);

        DATASTORE.writeUintForId(
            poolId,
            DataStoreUtils.getKey(operatorId, "allowance"),
            allowance
        );

        emit OperatorApproval(poolId, operatorId, allowance);
        return true;
    }

    /**
     * @notice                ** Operator (TYPE 4 and 5) specific functions **
     */

    /**
     * @notice updates validatorPeriod for given operator, limited by MAX_VALIDATOR_PERIOD
     */
    function _updateValidatorPeriod(
        DataStoreUtils.DataStore storage DATASTORE,
        uint256 operatorId,
        uint256 newPeriod
    ) internal {
        require(
            newPeriod >= MIN_VALIDATOR_PERIOD,
            "StekeUtils: should be more than MIN_VALIDATOR_PERIOD"
        );
        require(
            newPeriod <= MAX_VALIDATOR_PERIOD,
            "StekeUtils: should be less than MAX_VALIDATOR_PERIOD"
        );

        require(
            block.timestamp >
                DATASTORE.readUintForId(operatorId, "periodSwitch"),
            "StakeUtils: period is currently switching"
        );
        DATASTORE.writeUintForId(
            operatorId,
            "priorPeriod",
            DATASTORE.readUintForId(operatorId, "validatorPeriod")
        );
        DATASTORE.writeUintForId(
            operatorId,
            "periodSwitch",
            block.timestamp + MaintainerUtils.SWITCH_LATENCY
        );
        DATASTORE.writeUintForId(operatorId, "validatorPeriod", newPeriod);

        emit ValidatorPeriodUpdated(operatorId, newPeriod);
    }

    function updateValidatorPeriod(
        DataStoreUtils.DataStore storage DATASTORE,
        uint256 operatorId,
        uint256 newPeriod
    ) external {
        DATASTORE.authenticate(operatorId, true, [true, false, false]);
        _updateValidatorPeriod(DATASTORE, operatorId, newPeriod);
    }

    /**
     * @notice                      ** STAKING POOL (TYPE 5 and 6)  specific functions **
     */

    /**
     * @notice returns miniGovernance as a contract
     */
    function miniGovernanceById(
        DataStoreUtils.DataStore storage DATASTORE,
        uint256 _id
    ) internal view returns (IMiniGovernance) {
        return
            IMiniGovernance(DATASTORE.readAddressForId(_id, "miniGovernance"));
    }

    /**
     * @notice returns withdrawalPool as a contract
     */
    function withdrawalPoolById(
        DataStoreUtils.DataStore storage DATASTORE,
        uint256 _id
    ) internal view returns (ISwap) {
        return ISwap(DATASTORE.readAddressForId(_id, "withdrawalPool"));
    }

    /**
     * @dev pausing requires pool to be NOT paused already
     */
    function pauseStakingForPool(
        DataStoreUtils.DataStore storage DATASTORE,
        uint256 id
    ) external {
        DATASTORE.authenticate(id, true, [false, true, true]);

        require(
            DATASTORE.readUintForId(id, "stakePaused") == 0,
            "StakeUtils: staking already paused"
        );

        DATASTORE.writeUintForId(id, "stakePaused", 1); // meaning true
        emit PoolPaused(id);
    }

    /**
     * @dev unpausing requires pool to be paused already
     */
    function unpauseStakingForPool(
        DataStoreUtils.DataStore storage DATASTORE,
        uint256 id
    ) external {
        DATASTORE.authenticate(id, true, [false, true, true]);

        require(
            DATASTORE.readUintForId(id, "stakePaused") == 1,
            "StakeUtils: staking already NOT paused"
        );

        DATASTORE.writeUintForId(id, "stakePaused", 0); // meaning false
        emit PoolUnpaused(id);
    }

    /**
     * @notice                      ** DEPOSIT(user) functions **
     */

    /**
     * @notice checks if staking is allowed in a pool.
     * * when a pool is paused for staking NO new funds can be minted.
     * @notice staking is not allowed if:
     * 1. MiniGovernance is in Isolation Mode, this means it is not upgraded to current version
     * 2. Staking is simply paused by the Pool maintainer
     * @dev minting is paused when stakePaused == 1, meaning true.
     */
    function canDeposit(DataStoreUtils.DataStore storage DATASTORE, uint256 _id)
        public
        view
        returns (bool)
    {
        return
            (DATASTORE.readUintForId(_id, "stakePaused") == 0) &&
            !(miniGovernanceById(DATASTORE, _id).isolationMode());
    }

    /**
     * @notice conducts a buyback using the given withdrawal pool,
     * @param to address to send bought gETH(id). burns the tokens if to=address(0), transfers if not
     * @param poolId id of the gETH that will be bought
     * @param sellEth ETH amount to sell
     * @param minToBuy TX is expected to revert by Swap.sol if not meet
     * @param deadline TX is expected to revert by Swap.sol if not meet
     * @dev this function assumes that pool is deployed by deployWithdrawalPool
     * as index 0 is eth and index 1 is Geth
     */
    function _buyback(
        StakePool storage self,
        DataStoreUtils.DataStore storage DATASTORE,
        address to,
        uint256 poolId,
        uint256 sellEth,
        uint256 minToBuy,
        uint256 deadline
    ) internal returns (uint256 outAmount) {
        // SWAP in WP
        outAmount = withdrawalPoolById(DATASTORE, poolId).swap{value: sellEth}(
            0,
            1,
            sellEth,
            minToBuy,
            deadline
        );
        if (to == address(0)) {
            // burn
            self.gETH.burn(address(this), poolId, outAmount);
        } else {
            // send back to user
            self.gETH.safeTransferFrom(
                address(this),
                to,
                poolId,
                outAmount,
                ""
            );
        }
    }

    /**
     * @notice Allowing users to deposit into a public staking pool.
     * * Buys from DWP if price is low -debt-, mints new tokens if surplus is sent -more than debt-
     * @param planetId id of the staking pool, withdrawal pool and gETH to be used.
     * @param mingETH withdrawal pool parameter
     * @param deadline withdrawal pool parameter
     * // debt  msg.value
     * // 100   10  => buyback
     * // 100   100 => buyback
     * // 10    100 => buyback + mint
     * // 1     x   => mint
     * // 0.5   x   => mint
     * // 0     x   => mint
     */
    function depositPlanet(
        StakePool storage self,
        DataStoreUtils.DataStore storage DATASTORE,
        uint256 planetId,
        uint256 mingETH,
        uint256 deadline
    ) external returns (uint256 totalgETH) {
        DATASTORE.authenticate(planetId, false, [false, true, false]);

        require(msg.value > 1e15, "StakeUtils: at least 0.001 eth ");
        require(deadline > block.timestamp, "StakeUtils: deadline not met");
        require(canDeposit(DATASTORE, planetId), "StakeUtils: minting paused");
        uint256 debt = withdrawalPoolById(DATASTORE, planetId).getDebt();
        if (debt >= msg.value) {
            return
                _buyback(
                    self,
                    DATASTORE,
                    msg.sender,
                    planetId,
                    msg.value,
                    mingETH,
                    deadline
                );
        } else {
            uint256 boughtgETH = 0;
            uint256 remEth = msg.value;
            if (debt > IGNORABLE_DEBT) {
                boughtgETH = _buyback(
                    self,
                    DATASTORE,
                    msg.sender,
                    planetId,
                    debt,
                    0,
                    deadline
                );
                remEth -= debt;
            }
            uint256 mintedgETH = (
                ((remEth * self.gETH.denominator()) /
                    self.gETH.pricePerShare(planetId))
            );
            self.gETH.mint(msg.sender, planetId, mintedgETH, "");
            DATASTORE.addUintForId(planetId, "surplus", remEth);

            require(
                boughtgETH + mintedgETH >= mingETH,
                "StakeUtils: less than mingETH"
            );
            if (self.TELESCOPE._isOracleActive()) {
                bytes32 dailyBufferKey = DataStoreUtils.getKey(
                    block.timestamp -
                        (block.timestamp % OracleUtils.ORACLE_PERIOD),
                    "mintBuffer"
                );
                DATASTORE.addUintForId(planetId, dailyBufferKey, mintedgETH);
            }
            return boughtgETH + mintedgETH;
        }
    }

    /**
     * @notice                      ** WITHDRAWAL(user) functions **
     */

    /**
     * @notice figuring out how much of gETH and ETH should be donated in case of _burnSurplus
     * @dev Refering to improvement proposal, fees are donated to DWP when surplus
     * is being used as a withdrawal source. This is necessary to:
     * 1. create a financial cost for boostrap period
     */
    function _donateBalancedFees(
        DataStoreUtils.DataStore storage DATASTORE,
        uint256 poolId,
        uint256 burnSurplus,
        uint256 burnGeth
    ) internal returns (uint256 EthDonation, uint256 gEthDonation) {
        // find half of the fees to burn from surplus
        uint256 fee = withdrawalPoolById(DATASTORE, poolId).getSwapFee();
        EthDonation = (burnSurplus * fee) / PERCENTAGE_DENOMINATOR / 2;

        // find the remaining half as gETH with respect to PPS
        gEthDonation = (burnGeth * fee) / PERCENTAGE_DENOMINATOR / 2;

        //send both fees to DWP
        withdrawalPoolById(DATASTORE, poolId).donateBalancedFees{
            value: EthDonation
        }(EthDonation, gEthDonation);
    }

    /**
     * @dev Refering to improvement proposal, it is now allowed to use surplus to
     * * withdraw from public pools (after boostrap period).
     * * This means, "surplus" becomes a parameter of, freshly named, Dynamic Staking Pools
     * * which is the combination of DWP+public staking pools. Now, (assumed) there wont be
     * * surplus and debt at the same time.
     * @dev burnBuffer should be increased if the ORACLE is active, otherwise we can not
     * verify the legitacy of Telescope price calculations
     */
    function _burnSurplus(
        StakePool storage self,
        DataStoreUtils.DataStore storage DATASTORE,
        uint256 poolId,
        uint256 gEthToWithdraw
    ) internal returns (uint256, uint256) {
        uint256 pps = self.gETH.pricePerShare(poolId);

        uint256 spentGeth = gEthToWithdraw;
        uint256 spentSurplus = ((spentGeth * pps) / self.gETH.denominator());
        uint256 surplus = DATASTORE.readUintForId(poolId, "surplus");
        if (spentSurplus >= surplus) {
            spentSurplus = surplus;
            spentGeth = ((spentSurplus * self.gETH.denominator()) / pps);
        }

        (uint256 EthDonation, uint256 gEthDonation) = _donateBalancedFees(
            DATASTORE,
            poolId,
            spentSurplus,
            spentGeth
        );

        DATASTORE.subUintForId(poolId, "surplus", spentSurplus);
        self.gETH.burn(address(this), poolId, spentGeth - gEthDonation);

        if (self.TELESCOPE._isOracleActive()) {
            bytes32 dailyBufferKey = DataStoreUtils.getKey(
                block.timestamp - (block.timestamp % OracleUtils.ORACLE_PERIOD),
                "burnBuffer"
            );
            DATASTORE.addUintForId(
                poolId,
                dailyBufferKey,
                spentGeth - gEthDonation
            );
        }

        return (spentSurplus - (EthDonation * 2), gEthToWithdraw - spentGeth);
    }

    /**
     * @notice withdraw funds from Dynamic Staking Pool (Public Staking Pool + DWP)
     * * If not in Boostrap Period, first checks the surplus, than swaps from DWP to create debt
     * @param gEthToWithdraw amount of g-derivative that should be withdrawn
     * @param minETH TX is expected to revert by Swap.sol if not meet
     * @param deadline TX is expected to revert by Swap.sol if not meet
     */
    function withdrawPlanet(
        StakePool storage self,
        DataStoreUtils.DataStore storage DATASTORE,
        uint256 poolId,
        uint256 gEthToWithdraw,
        uint256 minETH,
        uint256 deadline
    ) external returns (uint256 EthToSend) {
        DATASTORE.authenticate(poolId, false, [false, true, false]);

        require(deadline > block.timestamp, "StakeUtils: deadline not met");
        {
            // transfer token first
            uint256 beforeBalance = self.gETH.balanceOf(address(this), poolId);

            self.gETH.safeTransferFrom(
                msg.sender,
                address(this),
                poolId,
                gEthToWithdraw,
                ""
            );
            // Use the transferred amount
            gEthToWithdraw =
                self.gETH.balanceOf(address(this), poolId) -
                beforeBalance;
        }

        if (
            block.timestamp >
            DATASTORE.readUintForId(poolId, "initiated") + self.BOOSTRAP_PERIOD
        ) {
            (EthToSend, gEthToWithdraw) = _burnSurplus(
                self,
                DATASTORE,
                poolId,
                gEthToWithdraw
            );
        }

        if (gEthToWithdraw > 0) {
            EthToSend += withdrawalPoolById(DATASTORE, poolId).swap(
                1,
                0,
                gEthToWithdraw,
                EthToSend >= minETH ? 0 : minETH - EthToSend,
                deadline
            );
        }
        (bool sent, ) = payable(msg.sender).call{value: EthToSend}("");
        require(sent, "StakeUtils: Failed to send Ether");
    }

    /**
     * @notice                      ** STAKE(operator) functions **
     */

    /**
     * @notice internal function that checks if validator is allowed
     * by Telescope and also not in isolationMode
     */
    function _canStake(
        StakePool storage self,
        DataStoreUtils.DataStore storage DATASTORE,
        bytes calldata pubkey,
        uint256 verificationIndex
    ) internal view returns (bool) {
        return
            self.TELESCOPE._canStake(pubkey, verificationIndex) &&
            !(
                miniGovernanceById(
                    DATASTORE,
                    self.TELESCOPE._validators[pubkey].poolId
                ).isolationMode()
            );
    }

    /**
     * @notice external function to check if a validator can use planet funds
     */
    function canStake(
        StakePool storage self,
        DataStoreUtils.DataStore storage DATASTORE,
        bytes calldata pubkey
    ) external view returns (bool) {
        return
            _canStake(
                self,
                DATASTORE,
                pubkey,
                self.TELESCOPE.VERIFICATION_INDEX
            );
    }

    /**
     * @notice Validator Credentials Proposal function, first step of crating validators.
     * * Once a pubKey is proposed and not alienated for some time,
     * * it is optimistically allowed to take funds from staking pools.
     *
     * @param poolId the id of the staking pool whose TYPE can be 5 or 6.
     * @param operatorId the id of the Operator whose maintainer calling this function
     * @param pubkeys  Array of BLS12-381 public keys of the validators that will be proposed
     * @param signatures Array of BLS12-381 signatures of the validators that will be proposed
     *
     * @dev DEPOSIT_AMOUNT_PRESTAKE = 1 ether, which is the minimum number to create validator.
     * 31 Ether will be staked after verification of oracles. 32 in total.
     * 1 ether will be sent back to Node Operator when finalized deposit is successful.
     * @dev ProposeStake requires enough allowance from Staking Pools to Operators.
     * @dev ProposeStake requires enough funds within maintainerWallet.
     * @dev Max number of validators to propose is MAX_DEPOSITS_PER_CALL (currently 64)
     */
    function proposeStake(
        StakePool storage self,
        DataStoreUtils.DataStore storage DATASTORE,
        uint256 poolId,
        uint256 operatorId,
        bytes[] calldata pubkeys,
        bytes[] calldata signatures
    ) external {
        DATASTORE.authenticate(operatorId, true, [true, false, false]);
        DATASTORE.authenticate(poolId, false, [false, true, true]);
        require(
            !OracleUtils.isPrisoned(DATASTORE, operatorId),
            "StakeUtils: operator is in prison, get in touch with governance"
        );

        require(
            pubkeys.length == signatures.length,
            "StakeUtils: pubkeys and signatures NOT same length"
        );
        require(
            pubkeys.length > 0 && pubkeys.length <= DCU.MAX_DEPOSITS_PER_CALL,
            "StakeUtils: MAX 64 nodes"
        );
        require(
            (DATASTORE.readUintForId(operatorId, "totalActiveValidators") +
                DATASTORE.readUintForId(operatorId, "totalProposedValidators") +
                pubkeys.length) <= self.TELESCOPE.MONOPOLY_THRESHOLD,
            "StakeUtils: IceBear does NOT like monopolies"
        );
        require(
            (DATASTORE.readUintForId(
                poolId,
                DataStoreUtils.getKey(operatorId, "proposedValidators")
            ) +
                DATASTORE.readUintForId(
                    poolId,
                    DataStoreUtils.getKey(operatorId, "activeValidators")
                ) +
                pubkeys.length) <=
                operatorAllowance(DATASTORE, poolId, operatorId),
            "StakeUtils: NOT enough allowance"
        );

        require(
            DATASTORE.readUintForId(poolId, "surplus") >=
                DCU.DEPOSIT_AMOUNT * pubkeys.length,
            "StakeUtils: NOT enough surplus"
        );

        DATASTORE._decreaseMaintainerWallet(
            operatorId,
            pubkeys.length * DCU.DEPOSIT_AMOUNT_PRESTAKE
        );

        DATASTORE.subUintForId(
            poolId,
            "surplus",
            (DCU.DEPOSIT_AMOUNT * pubkeys.length)
        );

        DATASTORE.addUintForId(
            poolId,
            "secured",
            (DCU.DEPOSIT_AMOUNT * pubkeys.length)
        );

        DATASTORE.addUintForId(
            poolId,
            DataStoreUtils.getKey(operatorId, "proposedValidators"),
            pubkeys.length
        );

        DATASTORE.addUintForId(
            operatorId,
            "totalProposedValidators",
            pubkeys.length
        );

        self.TELESCOPE.VALIDATORS_INDEX += pubkeys.length;
        {
            uint256[2] memory fees = [
                DATASTORE.getMaintainerFee(poolId),
                DATASTORE.getMaintainerFee(operatorId)
            ];
            bytes memory withdrawalCredential = DATASTORE.readBytesForId(
                poolId,
                "withdrawalCredential"
            );
            uint256 expectedExit = block.timestamp +
                DATASTORE.readUintForId(operatorId, "validatorPeriod");
            uint256 nextValidatorsIndex = self.TELESCOPE.VALIDATORS_INDEX + 1;
            for (uint256 i; i < pubkeys.length; i++) {
                require(
                    self.TELESCOPE._validators[pubkeys[i]].state == 0,
                    "StakeUtils: Pubkey already used or alienated"
                );
                require(
                    pubkeys[i].length == DCU.PUBKEY_LENGTH,
                    "StakeUtils: PUBKEY_LENGTH ERROR"
                );
                require(
                    signatures[i].length == DCU.SIGNATURE_LENGTH,
                    "StakeUtils: SIGNATURE_LENGTH ERROR"
                );

                DCU.depositValidator(
                    pubkeys[i],
                    withdrawalCredential,
                    signatures[i],
                    DCU.DEPOSIT_AMOUNT_PRESTAKE
                );

                self.TELESCOPE._validators[pubkeys[i]] = OracleUtils.Validator(
                    1,
                    nextValidatorsIndex + i,
                    poolId,
                    operatorId,
                    fees[0],
                    fees[1],
                    block.timestamp,
                    expectedExit,
                    signatures[i]
                );
                emit ProposeStaked(pubkeys[i], poolId, operatorId);
            }
        }
    }

    /**
     *  @notice Sends 31 Eth from staking pool to validators that are previously created with ProposeStake.
     *  1 Eth per successful validator boostraping is returned back to MaintainerWallet.
     *
     *  @param operatorId the id of the Operator whose maintainer calling this function
     *  @param pubkeys  Array of BLS12-381 public keys of the validators that are already proposed with ProposeStake.
     *
     *  @dev To save gas cost, pubkeys should be arranged by planedIds.
     *  ex: [pk1, pk2, pk3, pk4, pk5, pk6, pk7]
     *  pk1, pk2, pk3 from planet1
     *  pk4, pk5 from planet2
     *  pk6 from planet3
     *  seperate them in similar groups as much as possible.
     *  @dev Max number of validators to boostrap is MAX_DEPOSITS_PER_CALL (currently 64)
     *  @dev A pubkey that is alienated will not get through. Do not frontrun during ProposeStake.
     */
    function beaconStake(
        StakePool storage self,
        DataStoreUtils.DataStore storage DATASTORE,
        uint256 operatorId,
        bytes[] calldata pubkeys
    ) external {
        DATASTORE.authenticate(operatorId, true, [true, false, false]);

        require(
            !self.TELESCOPE._isOracleActive(),
            "StakeUtils: ORACLE is active"
        );
        require(
            pubkeys.length > 0 && pubkeys.length <= DCU.MAX_DEPOSITS_PER_CALL,
            "StakeUtils: MAX 64 nodes"
        );
        {
            uint256 verificationIndex = self.TELESCOPE.VERIFICATION_INDEX;
            for (uint256 j; j < pubkeys.length; j++) {
                require(
                    _canStake(self, DATASTORE, pubkeys[j], verificationIndex),
                    "StakeUtils: NOT all pubkeys are stakeable"
                );
            }
        }
        {
            bytes32 activeValKey = DataStoreUtils.getKey(
                operatorId,
                "activeValidators"
            );
            bytes32 proposedValKey = DataStoreUtils.getKey(
                operatorId,
                "proposedValidators"
            );

            uint256 planetId = self.TELESCOPE._validators[pubkeys[0]].poolId;
            bytes memory withdrawalCredential = DATASTORE.readBytesForId(
                planetId,
                "withdrawalCredential"
            );

            uint256 lastPlanetChange;
            for (uint256 i; i < pubkeys.length; i++) {
                if (planetId != self.TELESCOPE._validators[pubkeys[i]].poolId) {
                    DATASTORE.subUintForId(
                        planetId,
                        "secured",
                        (DCU.DEPOSIT_AMOUNT * (i - lastPlanetChange))
                    );
                    DATASTORE.addUintForId(
                        planetId,
                        activeValKey,
                        (i - lastPlanetChange)
                    );
                    DATASTORE.subUintForId(
                        planetId,
                        proposedValKey,
                        (i - lastPlanetChange)
                    );
                    lastPlanetChange = i;
                    planetId = self.TELESCOPE._validators[pubkeys[i]].poolId;
                    withdrawalCredential = DATASTORE.readBytesForId(
                        planetId,
                        "withdrawalCredential"
                    );
                }

                bytes memory signature = self
                    .TELESCOPE
                    ._validators[pubkeys[i]]
                    .signature;

                DCU.depositValidator(
                    pubkeys[i],
                    withdrawalCredential,
                    signature,
                    DCU.DEPOSIT_AMOUNT - DCU.DEPOSIT_AMOUNT_PRESTAKE
                );

                self.TELESCOPE._validators[pubkeys[i]].state = 2;
                emit BeaconStaked(pubkeys[i]);
            }

            DATASTORE.subUintForId(
                planetId,
                "secured",
                DCU.DEPOSIT_AMOUNT * (pubkeys.length - lastPlanetChange)
            );
            DATASTORE.addUintForId(
                planetId,
                activeValKey,
                (pubkeys.length - lastPlanetChange)
            );
            DATASTORE.subUintForId(
                planetId,
                proposedValKey,
                (pubkeys.length - lastPlanetChange)
            );
            DATASTORE.subUintForId(
                operatorId,
                "totalProposedValidators",
                pubkeys.length
            );
            DATASTORE.addUintForId(
                operatorId,
                "totalActiveValidators",
                pubkeys.length
            );
        }
        DATASTORE._increaseMaintainerWallet(
            operatorId,
            DCU.DEPOSIT_AMOUNT_PRESTAKE * pubkeys.length
        );
    }

    /**
     * @notice                      ** UNSTAKE(operator) functions **
     */

    /**
     * @notice allows improsening an Operator if the validator have not been exited until expectedExit
     * @dev anyone can call this function
     * @dev if operator has given enough allowence, they can rotate the validators to avoid being prisoned
     */
    function blameOperator(
        StakePool storage self,
        DataStoreUtils.DataStore storage DATASTORE,
        bytes calldata pk
    ) external {
        if (
            block.timestamp > self.TELESCOPE._validators[pk].expectedExit &&
            self.TELESCOPE._validators[pk].state == 2
        ) {
            OracleUtils.imprison(
                DATASTORE,
                self.TELESCOPE._validators[pk].operatorId
            );
        }
    }

    /**
     * @notice allows giving a unstake signal, meaning validator has been exited.
     * * And boost can be claimed upon arrival of the funds.
     * @dev to maintain the health of Geode Universe, we should protect the race conditions.
     * * opeators should know when others are unstaking so they don't spend money for no boost.
     */
    function signalUnstake(
        StakePool storage self,
        DataStoreUtils.DataStore storage DATASTORE,
        bytes[] calldata pubkeys
    ) external {
        uint256 expectedOperator = self
            .TELESCOPE
            ._validators[pubkeys[0]]
            .operatorId;

        DATASTORE.authenticate(expectedOperator, true, [true, false, false]);

        for (uint256 i = 0; i < pubkeys.length; i++) {
            require(self.TELESCOPE._validators[pubkeys[i]].state == 2);
            require(
                self.TELESCOPE._validators[pubkeys[i]].operatorId ==
                    expectedOperator
            );

            self.TELESCOPE._validators[pubkeys[i]].state = 3;

            emit UnstakeSignal(
                self.TELESCOPE._validators[pubkeys[i]].poolId,
                pubkeys[i]
            );
        }
    }

    /**
     * @notice Operator finalizing an Unstake event by calling Telescope's multisig:
     * * distributing fees + boost
     * * distributes rewards by burning the derivative
     * * does a buyback if necessary
     * * putting the extra within surplus.
     * @param isExit according to eip-4895, there can be multiple ways to distriute the rewards
     * * and not all of them requires exit. Even in such cases reward can be catched from
     * * withdrawal credential and distributed.
     *
     * @dev although OnlyOracle, logically this has nothing to do with Telescope.
     * * So we are keeping it here.
     * * @dev operator is prisoned if:
     * 1. withdrawn without signalled, being sneaky. in such case they also doesn't receive the boost
     * 2. signalled without withdrawal, deceiving other operators
     */
    function fetchUnstake(
        StakePool storage self,
        DataStoreUtils.DataStore storage DATASTORE,
        uint256 poolId,
        uint256 operatorId,
        bytes[] calldata pubkeys,
        uint256[] calldata balances,
        bool[] calldata isExit
    ) external {
        require(
            msg.sender == self.TELESCOPE.ORACLE_POSITION,
            "StakeUtils: sender NOT ORACLE"
        );
        require(
            !self.TELESCOPE._isOracleActive(),
            "StakeUtils: ORACLE is active"
        );

        uint256 cumBal;
        uint256[2] memory fees;
        {
            uint256 exitCount;

            for (uint256 i = 0; i < pubkeys.length; i++) {
                uint256 balance = balances[i];
                cumBal += balances[i];

                if (isExit[i]) {
                    exitCount += 1;
                    if (balance > DCU.DEPOSIT_AMOUNT) {
                        balance -= DCU.DEPOSIT_AMOUNT;
                    } else {
                        balance = 0;
                    }
                }

                if (balance > 0) {
                    fees[0] += ((balance *
                        self.TELESCOPE._validators[pubkeys[i]].poolFee) /
                        PERCENTAGE_DENOMINATOR);

                    fees[1] += ((balance *
                        self.TELESCOPE._validators[pubkeys[i]].operatorFee) /
                        PERCENTAGE_DENOMINATOR);
                }
            }

            {
                bool success = miniGovernanceById(DATASTORE, poolId)
                    .claimUnstake(cumBal);
                require(success, "StakeUtils: Failed to claim");
            }

            // decrease the sum of isExit activeValidators and totalValidators
            DATASTORE.subUintForId(
                poolId,
                DataStoreUtils.getKey(operatorId, "activeValidators"),
                exitCount
            );
            DATASTORE.subUintForId(
                operatorId,
                "totalActiveValidators",
                exitCount
            );

            cumBal = cumBal - (fees[0] + fees[1]);
        }

        uint256 debt = withdrawalPoolById(DATASTORE, poolId).getDebt();
        if (debt > IGNORABLE_DEBT) {
            if (debt > cumBal) {
                debt = cumBal;
            }
            {
                uint256 boost = getWithdrawalBoost(DATASTORE, poolId);
                if (boost > 0) {
                    uint256 arb = withdrawalPoolById(DATASTORE, poolId)
                        .calculateSwap(0, 1, debt);
                    arb -=
                        (debt * self.gETH.denominator()) /
                        self.gETH.pricePerShare(poolId);
                    boost = (arb * boost) / PERCENTAGE_DENOMINATOR;

                    fees[1] += boost;
                    cumBal -= boost;
                }
            }

            _buyback(
                self,
                DATASTORE,
                address(0), // burn
                poolId,
                debt,
                0,
                type(uint256).max
            );
            cumBal -= debt;
        }

        if (cumBal > 0) {
            DATASTORE.addUintForId(poolId, "surplus", cumBal);
        }

        DATASTORE._increaseMaintainerWallet(poolId, fees[0]);
        DATASTORE._increaseMaintainerWallet(operatorId, fees[1]);
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
     * This empty reserved space is put in place to allow future versions to add new
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
     * This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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
     * This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155ReceiverUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155HolderUpgradeable is Initializable, ERC1155ReceiverUpgradeable {
    function __ERC1155Holder_init() internal onlyInitializing {
    }

    function __ERC1155Holder_init_unchained() internal onlyInitializing {
    }
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    /**
     * This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.7;

import "../../interfaces/IDepositContract.sol";
import "../helpers/BytesLib.sol";

library DepositContractUtils {
    IDepositContract internal constant DEPOSIT_CONTRACT =
        IDepositContract(0x00000000219ab540356cBB839Cbe05303d7705Fa);
    uint256 internal constant PUBKEY_LENGTH = 48;
    uint256 internal constant SIGNATURE_LENGTH = 96;
    uint256 internal constant WITHDRAWAL_CREDENTIALS_LENGTH = 32;
    uint256 internal constant DEPOSIT_AMOUNT = 32 ether;
    uint256 internal constant DEPOSIT_AMOUNT_PRESTAKE = 1 ether;
    uint256 internal constant MAX_DEPOSITS_PER_CALL = 64;

    /**
     * @dev Padding memory array with zeroes up to 64 bytes on the right
     * @param _b Memory array of size 32 .. 64
     */
    function _pad64(bytes memory _b) internal pure returns (bytes memory) {
        assert(_b.length >= 32 && _b.length <= 64);
        if (64 == _b.length) return _b;

        bytes memory zero32 = new bytes(32);
        assembly {
            mstore(add(zero32, 0x20), 0)
        }

        if (32 == _b.length) return BytesLib.concat(_b, zero32);
        else
            return
                BytesLib.concat(
                    _b,
                    BytesLib.slice(zero32, 0, uint256(64 - _b.length))
                );
    }

    /**
     * @dev Converting value to little endian bytes and padding up to 32 bytes on the right
     * @param _value Number less than `2**64` for compatibility reasons
     */
    function _toLittleEndian64(uint256 _value)
        internal
        pure
        returns (uint256 result)
    {
        result = 0;
        uint256 temp_value = _value;
        for (uint256 i = 0; i < 8; ++i) {
            result = (result << 8) | (temp_value & 0xFF);
            temp_value >>= 8;
        }

        assert(0 == temp_value); // fully converted
        result <<= (24 * 8);
    }

    function _getDepositDataRoot(
        bytes memory _pubkey,
        bytes memory _withdrawalCredentials,
        bytes memory _signature,
        uint256 _stakeAmount
    ) internal pure returns (bytes32) {
        require(
            _stakeAmount >= 1 ether,
            "DepositContract: deposit value too low"
        );
        require(
            _stakeAmount % 1 gwei == 0,
            "DepositContract: deposit value not multiple of gwei"
        );

        uint256 deposit_amount = _stakeAmount / 1 gwei;
        bytes32 pubkeyRoot = sha256(_pad64(_pubkey));
        bytes32 signatureRoot = sha256(
            abi.encodePacked(
                sha256(BytesLib.slice(_signature, 0, 64)),
                sha256(
                    _pad64(
                        BytesLib.slice(_signature, 64, SIGNATURE_LENGTH - 64)
                    )
                )
            )
        );

        bytes32 depositDataRoot = sha256(
            abi.encodePacked(
                sha256(abi.encodePacked(pubkeyRoot, _withdrawalCredentials)),
                sha256(
                    abi.encodePacked(
                        _toLittleEndian64(deposit_amount),
                        signatureRoot
                    )
                )
            )
        );

        return depositDataRoot;
    }

    function addressToWC(address wcAddress)
        internal
        pure
        returns (bytes memory)
    {
        uint256 w = 1 << 248;

        return
            abi.encodePacked(
                bytes32(w) | bytes32(uint256(uint160(address(wcAddress))))
            );
    }

    function depositValidator(
        bytes calldata pubkey,
        bytes memory withdrawalCredential,
        bytes memory signature,
        uint256 amount
    ) internal {
        DEPOSIT_CONTRACT.deposit{value: amount}(
            pubkey,
            withdrawalCredential,
            signature,
            _getDepositDataRoot(pubkey, withdrawalCredential, signature, amount)
        );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.7;

// This interface is designed to be compatible with the Vyper version.
/// @notice This is the Ethereum 2.0 deposit contract interface.
/// For more information see the Phase 0 specification under https://github.com/ethereum/eth2.0-specs
interface IDepositContract {
    /// @notice A processed deposit event.
    event DepositEvent(
        bytes pubkey,
        bytes withdrawal_credentials,
        bytes amount,
        bytes signature,
        bytes index
    );

    /// @notice Submit a Phase 0 DepositData object.
    /// @param pubkey A BLS12-381 public key.
    /// @param withdrawal_credentials Commitment to a public key for withdrawals.
    /// @param signature A BLS12-381 signature.
    /// @param deposit_data_root The SHA-256 hash of the SSZ-encoded DepositData object.
    /// Used as a protection against malformed input.
    function deposit(
        bytes calldata pubkey,
        bytes calldata withdrawal_credentials,
        bytes calldata signature,
        bytes32 deposit_data_root
    ) external payable;

    /// @notice Query the current deposit root hash.
    /// @return The deposit root hash.
    function get_deposit_root() external view returns (bytes32);

    /// @notice Query the current deposit count.
    /// @return The deposit count encoded as a little endian 64-bit number.
    function get_deposit_count() external view returns (bytes memory);
}

// SPDX-License-Identifier: Unlicense
/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */
pragma solidity =0.8.7;

library BytesLib {
    function concat(bytes memory _preBytes, bytes memory _postBytes)
        internal
        pure
        returns (bytes memory)
    {
        bytes memory tempBytes;

        assembly {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
            tempBytes := mload(0x40)

            // Store the length of the first bytes array at the beginning of
            // the memory for tempBytes.
            let length := mload(_preBytes)
            mstore(tempBytes, length)

            // Maintain a memory counter for the current write location in the
            // temp bytes array by adding the 32 bytes for the array length to
            // the starting location.
            let mc := add(tempBytes, 0x20)
            // Stop copying when the memory counter reaches the length of the
            // first bytes array.
            let end := add(mc, length)

            for {
                // Initialize a copy counter to the start of the _preBytes data,
                // 32 bytes into its memory.
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
                // Increase both counters by 32 bytes each iteration.
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                // Write the _preBytes data into the tempBytes memory 32 bytes
                // at a time.
                mstore(mc, mload(cc))
            }

            // Add the length of _postBytes to the current length of tempBytes
            // and store it as the new length in the first 32 bytes of the
            // tempBytes memory.
            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

            // Move the memory counter back from a multiple of 0x20 to the
            // actual end of the _preBytes data.
            mc := end
            // Stop copying when the memory counter reaches the new combined
            // length of the arrays.
            end := add(mc, length)

            for {
                let cc := add(_postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            // Update the free-memory pointer by padding our last write location
            // to 32 bytes: add 31 bytes to the end of tempBytes to move to the
            // next 32 byte block, then round down to the nearest multiple of
            // 32. If the sum of the length of the two arrays is zero then add
            // one before rounding down to leave a blank 32 bytes (the length block with 0).
            mstore(
                0x40,
                and(
                    add(add(end, iszero(add(length, mload(_preBytes)))), 31),
                    not(31) // Round down to the nearest 32 bytes.
                )
            )
        }

        return tempBytes;
    }

    function concatStorage(bytes storage _preBytes, bytes memory _postBytes)
        internal
    {
        assembly {
            // Read the first 32 bytes of _preBytes storage, which is the length
            // of the array. (We don't need to use the offset into the slot
            // because arrays use the entire slot.)
            let fslot := sload(_preBytes.slot)
            // Arrays of 31 bytes or less have an even value in their slot,
            // while longer arrays have an odd value. The actual length is
            // the slot divided by two for odd values, and the lowest order
            // byte divided by two for even values.
            // If the slot is even, bitwise and the slot with 255 and divide by
            // two to get the length. If the slot is odd, bitwise and the slot
            // with -1 and divide by two.
            let slength := div(
                and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)),
                2
            )
            let mlength := mload(_postBytes)
            let newlength := add(slength, mlength)
            // slength can contain both the length and contents of the array
            // if length < 32 bytes so let's prepare for that
            // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
            switch add(lt(slength, 32), lt(newlength, 32))
            case 2 {
                // Since the new array still fits in the slot, we just need to
                // update the contents of the slot.
                // uint256(bytes_storage) = uint256(bytes_storage) + uint256(bytes_memory) + new_length
                sstore(
                    _preBytes.slot,
                    // all the modifications to the slot are inside this
                    // next block
                    add(
                        // we can just add to the slot contents because the
                        // bytes we want to change are the LSBs
                        fslot,
                        add(
                            mul(
                                div(
                                    // load the bytes from memory
                                    mload(add(_postBytes, 0x20)),
                                    // zero all bytes to the right
                                    exp(0x100, sub(32, mlength))
                                ),
                                // and now shift left the number of bytes to
                                // leave space for the length in the slot
                                exp(0x100, sub(32, newlength))
                            ),
                            // increase length by the double of the memory
                            // bytes length
                            mul(mlength, 2)
                        )
                    )
                )
            }
            case 1 {
                // The stored value fits in the slot, but the combined value
                // will exceed it.
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // The contents of the _postBytes array start 32 bytes into
                // the structure. Our first read should obtain the `submod`
                // bytes that can fit into the unused space in the last word
                // of the stored array. To get this, we read 32 bytes starting
                // from `submod`, so the data we read overlaps with the array
                // contents by `submod` bytes. Masking the lowest-order
                // `submod` bytes allows us to add that value directly to the
                // stored value.

                let submod := sub(32, slength)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(
                    sc,
                    add(
                        and(
                            fslot,
                            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00
                        ),
                        and(mload(mc), mask)
                    )
                )

                for {
                    mc := add(mc, 0x20)
                    sc := add(sc, 1)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
            default {
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                // Start copying to the last used word of the stored array.
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // Copy over the first `submod` bytes of the new data as in
                // case 1 above.
                let slengthmod := mod(slength, 32)
                let mlengthmod := mod(mlength, 32)
                let submod := sub(32, slengthmod)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(sc, add(sload(sc), and(mload(mc), mask)))

                for {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
        }
    }

    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    ) internal pure returns (bytes memory) {
        require(_length + 31 >= _length, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(
                    add(tempBytes, lengthmod),
                    mul(0x20, iszero(lengthmod))
                )
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(
                        add(
                            add(_bytes, lengthmod),
                            mul(0x20, iszero(lengthmod))
                        ),
                        _start
                    )
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function toAddress(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (address)
    {
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(
                mload(add(add(_bytes, 0x20), _start)),
                0x1000000000000000000000000
            )
        }

        return tempAddress;
    }

    function toUint8(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (uint8)
    {
        require(_bytes.length >= _start + 1, "toUint8_outOfBounds");
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }

        return tempUint;
    }

    function toUint16(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (uint16)
    {
        require(_bytes.length >= _start + 2, "toUint16_outOfBounds");
        uint16 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x2), _start))
        }

        return tempUint;
    }

    function toUint32(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (uint32)
    {
        require(_bytes.length >= _start + 4, "toUint32_outOfBounds");
        uint32 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x4), _start))
        }

        return tempUint;
    }

    function toUint64(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (uint64)
    {
        require(_bytes.length >= _start + 8, "toUint64_outOfBounds");
        uint64 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x8), _start))
        }

        return tempUint;
    }

    function toUint96(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (uint96)
    {
        require(_bytes.length >= _start + 12, "toUint96_outOfBounds");
        uint96 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0xc), _start))
        }

        return tempUint;
    }

    function toUint128(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (uint128)
    {
        require(_bytes.length >= _start + 16, "toUint128_outOfBounds");
        uint128 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x10), _start))
        }

        return tempUint;
    }

    function toUint256(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (uint256)
    {
        require(_bytes.length >= _start + 32, "toUint256_outOfBounds");
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function toBytes32(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (bytes32)
    {
        require(_bytes.length >= _start + 32, "toBytes32_outOfBounds");
        bytes32 tempBytes32;

        assembly {
            tempBytes32 := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBytes32;
    }

    function equal(bytes memory _preBytes, bytes memory _postBytes)
        internal
        pure
        returns (bool)
    {
        bool success = true;

        assembly {
            let length := mload(_preBytes)

            // if lengths don't match the arrays are not equal
            switch eq(length, mload(_postBytes))
            case 1 {
                // cb is a circuit breaker in the for loop since there's
                //  no said feature for inline assembly loops
                // cb = 1 - don't breaker
                // cb = 0 - break
                let cb := 1

                let mc := add(_preBytes, 0x20)
                let end := add(mc, length)

                for {
                    let cc := add(_postBytes, 0x20)
                    // the next line is the loop condition:
                    // while(uint256(mc < end) + cb == 2)
                } eq(add(lt(mc, end), cb), 2) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    // if any of these checks fails then arrays are not equal
                    if iszero(eq(mload(mc), mload(cc))) {
                        // unsuccess:
                        success := 0
                        cb := 0
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }

    function equalStorage(bytes storage _preBytes, bytes memory _postBytes)
        internal
        view
        returns (bool)
    {
        bool success = true;

        assembly {
            // we know _preBytes_offset is 0
            let fslot := sload(_preBytes.slot)
            // Decode the length of the stored array like in concatStorage().
            let slength := div(
                and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)),
                2
            )
            let mlength := mload(_postBytes)

            // if lengths don't match the arrays are not equal
            switch eq(slength, mlength)
            case 1 {
                // slength can contain both the length and contents of the array
                // if length < 32 bytes so let's prepare for that
                // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
                if iszero(iszero(slength)) {
                    switch lt(slength, 32)
                    case 1 {
                        // blank the last byte which is the length
                        fslot := mul(div(fslot, 0x100), 0x100)

                        if iszero(eq(fslot, mload(add(_postBytes, 0x20)))) {
                            // unsuccess:
                            success := 0
                        }
                    }
                    default {
                        // cb is a circuit breaker in the for loop since there's
                        //  no said feature for inline assembly loops
                        // cb = 1 - don't breaker
                        // cb = 0 - break
                        let cb := 1

                        // get the keccak hash to get the contents of the array
                        mstore(0x0, _preBytes.slot)
                        let sc := keccak256(0x0, 0x20)

                        let mc := add(_postBytes, 0x20)
                        let end := add(mc, mlength)

                        // the next line is the loop condition:
                        // while(uint256(mc < end) + cb == 2)
                        for {

                        } eq(add(lt(mc, end), cb), 2) {
                            sc := add(sc, 1)
                            mc := add(mc, 0x20)
                        } {
                            if iszero(eq(sload(sc), mload(mc))) {
                                // unsuccess:
                                success := 0
                                cb := 0
                            }
                        }
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.7;

import "../Portal/utils/GeodeUtilsLib.sol";

interface IMiniGovernance {
    function initialize(
        address _gETH,
        address _PORTAL,
        address _MAINTAINER,
        uint256 _ID,
        uint256 _VERSION
    ) external;

    function pause() external;

    function unpause() external;

    function getCurrentVersion() external view returns (uint256);

    function getProposedVersion() external view returns (uint256);

    function isolationMode() external view returns (bool);

    function fetchUpgradeProposal() external;

    function approveProposal(uint256 _id) external;

    function setSenate(address newController) external;

    function claimUnstake(uint256 claim) external returns (bool success);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.7;
import "./IgETH.sol";

interface IERC20InterfacePermitUpgradable {
    function initialize(
        uint256 id_,
        string memory name_,
        string memory symbol_,
        address gETH_1155
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.7;

import "./IgETH.sol";

interface ISwap {
    function donateBalancedFees(uint256 EthDonation, uint256 gEthDonation)
        external
        payable
        returns (uint256, uint256);

    // pool data view functions
    function getERC1155() external view returns (address);

    function getA() external view returns (uint256);

    function getAPrecise() external view returns (uint256);

    function getSwapFee() external view returns (uint256);

    function getToken() external view returns (uint256);

    function getTokenBalance(uint8 index) external view returns (uint256);

    function getVirtualPrice() external view returns (uint256);

    function getDebt() external view returns (uint256);

    function getAdminBalance(uint256 index) external view returns (uint256);

    // min return calculation functions
    function calculateSwap(
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx
    ) external view returns (uint256);

    function calculateTokenAmount(uint256[] calldata amounts, bool deposit)
        external
        view
        returns (uint256);

    function calculateRemoveLiquidity(uint256 amount)
        external
        view
        returns (uint256[] memory);

    function calculateRemoveLiquidityOneToken(
        uint256 tokenAmount,
        uint8 tokenIndex
    ) external view returns (uint256 availableTokenAmount);

    // state modifying functions
    function initialize(
        IgETH _gEth,
        uint256 _pooledTokenId,
        string memory lpTokenName,
        string memory lpTokenSymbol,
        uint256 _a,
        uint256 _fee,
        uint256 _adminFee,
        address lpTokenTargetAddress
    ) external returns (address lpToken);

    function swap(
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx,
        uint256 minDy,
        uint256 deadline
    ) external payable returns (uint256);

    function addLiquidity(
        uint256[] calldata amounts,
        uint256 minToMint,
        uint256 deadline
    ) external payable returns (uint256);

    function removeLiquidity(
        uint256 amount,
        uint256[] calldata minAmounts,
        uint256 deadline
    ) external returns (uint256[] memory);

    function removeLiquidityOneToken(
        uint256 tokenAmount,
        uint8 tokenIndex,
        uint256 minAmount,
        uint256 deadline
    ) external returns (uint256);

    function removeLiquidityImbalance(
        uint256[] calldata amounts,
        uint256 maxBurnAmount,
        uint256 deadline
    ) external returns (uint256);

    function withdrawAdminFees() external;

    function setAdminFee(uint256 newAdminFee) external;

    function setSwapFee(uint256 newSwapFee) external;

    function rampA(uint256 futureA, uint256 futureTime) external;

    function stopRampA() external;
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.7;

interface ILPToken {
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function burn(uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;

    function decimals() external view returns (uint8);

    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        returns (bool);

    function increaseAllowance(address spender, uint256 addedValue)
        external
        returns (bool);

    function initialize(string memory name, string memory symbol)
        external
        returns (bool);

    function mint(address recipient, uint256 amount) external;

    function name() external view returns (string memory);

    function owner() external view returns (address);

    function renounceOwnership() external;

    function symbol() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function transferOwnership(address newOwner) external;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/ERC1967/ERC1967Proxy.sol)

pragma solidity ^0.8.0;

import "../Proxy.sol";
import "./ERC1967Upgrade.sol";

/**
 * @dev This contract implements an upgradeable proxy. It is upgradeable because calls are delegated to an
 * implementation address that can be changed. This address is stored in storage in the location specified by
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967], so that it doesn't conflict with the storage layout of the
 * implementation behind the proxy.
 */
contract ERC1967Proxy is Proxy, ERC1967Upgrade {
    /**
     * @dev Initializes the upgradeable proxy with an initial implementation specified by `_logic`.
     *
     * If `_data` is nonempty, it's used as data in a delegate call to `_logic`. This will typically be an encoded
     * function call, and allows initializating the storage of the proxy like a Solidity constructor.
     */
    constructor(address _logic, bytes memory _data) payable {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        _upgradeToAndCall(_logic, _data, false);
    }

    /**
     * @dev Returns the current implementation address.
     */
    function _implementation() internal view virtual override returns (address impl) {
        return ERC1967Upgrade._getImplementation();
    }
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
     * This empty reserved space is put in place to allow future versions to add new
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
     * This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155ReceiverUpgradeable.sol";
import "../../../utils/introspection/ERC165Upgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155ReceiverUpgradeable is Initializable, ERC165Upgradeable, IERC1155ReceiverUpgradeable {
    function __ERC1155Receiver_init() internal onlyInitializing {
    }

    function __ERC1155Receiver_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return interfaceId == type(IERC1155ReceiverUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155ReceiverUpgradeable is IERC165Upgradeable {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
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
     * This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
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