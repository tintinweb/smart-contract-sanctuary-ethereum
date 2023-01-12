/**
 * @authors: [@ferittuncer, @hbarcelos]
 * @reviewers: [@remedcu]
 * @auditors: []
 * @bounties: []
 * @deployments: []
 * SPDX-License-Identifier: MIT
 */
pragma solidity ^0.8.0;

import "./IArbitrator.sol";

/**
 * @title IArbitrable
 * Arbitrable interface.
 * When developing arbitrable contracts, we need to:
 * - Define the action taken when a ruling is received by the contract.
 * - Allow dispute creation. For this a function must call arbitrator.createDispute{value: _fee}(_choices,_extraData);
 */
interface IArbitrable {
    /**
     * @dev To be raised when a ruling is given.
     * @param _arbitrator The arbitrator giving the ruling.
     * @param _disputeID ID of the dispute in the Arbitrator contract.
     * @param _ruling The ruling which was given.
     */
    event Ruling(IArbitrator indexed _arbitrator, uint256 indexed _disputeID, uint256 _ruling);

    /**
     * @dev Give a ruling for a dispute. Must be called by the arbitrator.
     * The purpose of this function is to ensure that the address calling it has the right to rule on the contract.
     * @param _disputeID ID of the dispute in the Arbitrator contract.
     * @param _ruling Ruling given by the arbitrator. Note that 0 is reserved for "Not able/wanting to make a decision".
     */
    function rule(uint256 _disputeID, uint256 _ruling) external;
}

/**
 * @authors: [@ferittuncer, @hbarcelos]
 * @reviewers: [@remedcu]
 * @auditors: []
 * @bounties: []
 * @deployments: []
 * SPDX-License-Identifier: MIT
 */

pragma solidity ^0.8.0;

import "./IArbitrable.sol";

/**
 * @title Arbitrator
 * Arbitrator abstract contract.
 * When developing arbitrator contracts we need to:
 * - Define the functions for dispute creation (createDispute) and appeal (appeal). Don't forget to store the arbitrated contract and the disputeID (which should be unique, may nbDisputes).
 * - Define the functions for cost display (arbitrationCost and appealCost).
 * - Allow giving rulings. For this a function must call arbitrable.rule(disputeID, ruling).
 */
interface IArbitrator {
    enum DisputeStatus {
        Waiting,
        Appealable,
        Solved
    }

    /**
     * @dev To be emitted when a dispute is created.
     * @param _disputeID ID of the dispute.
     * @param _arbitrable The contract which created the dispute.
     */
    event DisputeCreation(uint256 indexed _disputeID, IArbitrable indexed _arbitrable);

    /**
     * @dev To be emitted when a dispute can be appealed.
     * @param _disputeID ID of the dispute.
     * @param _arbitrable The contract which created the dispute.
     */
    event AppealPossible(uint256 indexed _disputeID, IArbitrable indexed _arbitrable);

    /**
     * @dev To be emitted when the current ruling is appealed.
     * @param _disputeID ID of the dispute.
     * @param _arbitrable The contract which created the dispute.
     */
    event AppealDecision(uint256 indexed _disputeID, IArbitrable indexed _arbitrable);

    /**
     * @dev Create a dispute. Must be called by the arbitrable contract.
     * Must be paid at least arbitrationCost(_extraData).
     * @param _choices Amount of choices the arbitrator can make in this dispute.
     * @param _extraData Can be used to give additional info on the dispute to be created.
     * @return disputeID ID of the dispute created.
     */
    function createDispute(uint256 _choices, bytes calldata _extraData) external payable returns (uint256 disputeID);

    /**
     * @dev Compute the cost of arbitration. It is recommended not to increase it often, as it can be highly time and gas consuming for the arbitrated contracts to cope with fee augmentation.
     * @param _extraData Can be used to give additional info on the dispute to be created.
     * @return cost Amount to be paid.
     */
    function arbitrationCost(bytes calldata _extraData) external view returns (uint256 cost);

    /**
     * @dev Appeal a ruling. Note that it has to be called before the arbitrator contract calls rule.
     * @param _disputeID ID of the dispute to be appealed.
     * @param _extraData Can be used to give extra info on the appeal.
     */
    function appeal(uint256 _disputeID, bytes calldata _extraData) external payable;

    /**
     * @dev Compute the cost of appeal. It is recommended not to increase it often, as it can be higly time and gas consuming for the arbitrated contracts to cope with fee augmentation.
     * @param _disputeID ID of the dispute to be appealed.
     * @param _extraData Can be used to give additional info on the dispute to be created.
     * @return cost Amount to be paid.
     */
    function appealCost(uint256 _disputeID, bytes calldata _extraData) external view returns (uint256 cost);

    /**
     * @dev Compute the start and end of the dispute's current or next appeal period, if possible. If not known or appeal is impossible: should return (0, 0).
     * @param _disputeID ID of the dispute.
     * @return start The start of the period.
     * @return end The end of the period.
     */
    function appealPeriod(uint256 _disputeID) external view returns (uint256 start, uint256 end);

    /**
     * @dev Return the status of a dispute.
     * @param _disputeID ID of the dispute to rule.
     * @return status The status of the dispute.
     */
    function disputeStatus(uint256 _disputeID) external view returns (DisputeStatus status);

    /**
     * @dev Return the current ruling of a dispute. This is useful for parties to know if they should appeal.
     * @param _disputeID ID of the dispute.
     * @return ruling The ruling which has been given or the one which will be given if there is no appeal.
     */
    function currentRuling(uint256 _disputeID) external view returns (uint256 ruling);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import { ILightGeneralizedTCR } from "../interfaces/ILightGeneralizedTCR.sol";
import { ILightGTCRFactory } from "../interfaces/ILightGTCRFactory.sol";
import { IArbitrator } from "../../lib/erc-792/contracts/IArbitrator.sol";
// import "../../lib/openzeppelin-contracts/contracts/proxy/utils/Initializable.sol";

import "../interfaces/IBadgeController.sol";
import "../interfaces/ITheBadge.sol";

// TODO: make this upgradable
// TODO: only callable from TheBadge contract
contract KlerosBadgeTypeController is IBadgeController {
    ITheBadge public theBadge;
    IArbitrator public arbitrator;
    address public tcrFactory;

    /**
     * Struct to use as args to create a Kleros badge type strategy.
     *  @param badgeMetadata IPFS uri for the badge
     *  @param governor An address with permission to updates parameters of the list. Use Kleros governor for full decentralization.
     *  @param admin The address with permission to add/remove items directly.
     *  @param courtId The ID of the kleros's court.
     *  @param numberOfJurors The number of jurors required if a dispute is initiated.
     *  @param registrationMetaEvidence The URI of the meta evidence object for registration requests.
     *  @param clearingMetaEvidence The URI of the meta evidence object for clearing requests.
     *  @param challengePeriodDuration The time in seconds parties have to challenge a request.
     *  @param baseDeposits The base deposits for requests/challenges as follows:
     *  - The base deposit to submit an item.
     *  - The base deposit to remove an item.
     *  - The base deposit to challenge a submission.
     *  - The base deposit to challenge a removal request.
     *  @param stakeMultipliers Multipliers of the arbitration cost in basis points (see GeneralizedTCR MULTIPLIER_DIVISOR) as follows:
     *  - The multiplier applied to each party's fee stake for a round when there is no winner/loser in the previous round (e.g. when it's the first round or the arbitrator refused to arbitrate).
     *  - The multiplier applied to the winner's fee stake for an appeal round.
     *  - The multiplier applied to the loser's fee stake for an appeal round.
     * @param mintCost The cost for minting a badge, it goes to the emitter.
     * @param validFor The time in seconds of how long the badge is valid. (cero for infinite)
     */
    struct CreateBadgeType {
        address governor;
        address admin;
        uint256 courtId;
        uint256 numberOfJurors;
        string registrationMetaEvidence;
        string clearingMetaEvidence;
        uint256 challengePeriodDuration;
        uint256[4] baseDeposits;
        uint256[3] stakeMultipliers;
    }

    struct RequestBadgeData {
        string evidence;
    }

    /**
     * @param tcrList The TCR List created for a particular badge type
     */
    struct KlerosBadgeType {
        address tcrList;
    }

    /**
     * @param itemID internal Kleros TCR list ID
     * @param callee address paying the deposit
     * @param deposit the deposit amount
     */
    struct KlerosBadge {
        bytes32 itemID;
        address callee;
        uint256 deposit;
    }

    /**
     * =========================
     * Store
     * =========================
     */

    /**
     * @notice Kleros's badge information.
     * badgeId => KlerosBadgeInfo
     */
    mapping(uint256 => KlerosBadgeType) public klerosBadgeType;

    /**
     * @notice Information related to a specific asset from a kleros strategy
     * badgeId => address => KlerosAssetInfo
     */
    mapping(uint256 => mapping(address => KlerosBadge)) public klerosBadge;

    /**
     * =========================
     * Events
     * =========================
     */
    event NewKlerosStrategy(uint256 indexed strategyId, address indexed klerosTCRAddress, string registrationMetadata);
    event MintKlerosBadge(address indexed callee, uint256 indexed badgeTypeId, address indexed to, string evidence);

    /**
     * =========================
     * Errors
     * =========================
     */
    error KlerosBadgeTypeController__createBadgeType_badgeTypeAlreadyCreated();
    error KlerosBadgeTypeController__onlyTheBadge_senderNotTheBadge();
    error KlerosBadgeTypeController__mintBadge_alreadyMinted();
    error KlerosBadgeTypeController__mintBadge_wrongBadgeType();
    error KlerosBadgeTypeController__mintBadge_isPaused();
    error KlerosBadgeTypeController__mintBadge_wrongValue();
    error KlerosBadgeTypeController__claimBadge_insufficientBalance();
    error KlerosBadgeTypeController__createBadgeType_TCRListAddressZero();

    /**
     * =========================
     * Modifiers
     * =========================
     */

    modifier onlyTheBadge() {
        if (address(theBadge) != msg.sender) {
            revert KlerosBadgeTypeController__onlyTheBadge_senderNotTheBadge();
        }
        _;
    }

    constructor(address _theBadge, address _arbitrator, address _tcrFactory) {
        theBadge = ITheBadge(_theBadge);
        arbitrator = IArbitrator(_arbitrator);
        tcrFactory = _tcrFactory;
    }

    /**
     * @notice Allows to create off-chain kleros strategies for registered entities
     * @param badgeId BadgeId from TheBadge contract
     * @param data Encoded data required to create a Kleros TCR list
     */
    // TODO: add onlyTheBadge modifier
    function createBadgeType(uint256 badgeId, bytes calldata data) public payable {
        KlerosBadgeType storage _klerosBadgeType = klerosBadgeType[badgeId];
        if (_klerosBadgeType.tcrList != address(0)) {
            revert KlerosBadgeTypeController__createBadgeType_badgeTypeAlreadyCreated();
        }

        ILightGTCRFactory lightGTCRFactory = ILightGTCRFactory(tcrFactory);

        CreateBadgeType memory args = abi.decode(data, (CreateBadgeType));

        lightGTCRFactory.deploy(
            IArbitrator(arbitrator),
            bytes.concat(abi.encodePacked(args.courtId), abi.encodePacked(args.numberOfJurors)),
            address(0), // TODO: check this.
            args.registrationMetaEvidence,
            args.clearingMetaEvidence,
            args.governor,
            args.baseDeposits,
            args.challengePeriodDuration,
            args.stakeMultipliers,
            args.admin
        );

        // Get the address for the strategy created
        uint256 index = lightGTCRFactory.count() - 1;
        address klerosTcrListAddress = address(lightGTCRFactory.instances(index));
        if (klerosTcrListAddress == address(0)) {
            revert KlerosBadgeTypeController__createBadgeType_TCRListAddressZero();
        }

        klerosBadgeType[badgeId] = KlerosBadgeType(klerosTcrListAddress);

        emit NewKlerosStrategy(badgeId, klerosTcrListAddress, args.registrationMetaEvidence);
    }

    /**
     * @notice Returns the cost for minting a badge for a kleros strategy
     * It sums kleros base deposit + kleros arbitration cost
     */
    function badgeRequestValue(uint256 badgeId) public view returns (uint256) {
        KlerosBadgeType storage _klerosBadgeType = klerosBadgeType[badgeId];

        ILightGeneralizedTCR lightGeneralizedTCR = ILightGeneralizedTCR(_klerosBadgeType.tcrList);

        uint256 arbitrationCost = arbitrator.arbitrationCost(lightGeneralizedTCR.arbitratorExtraData());
        uint256 baseDeposit = lightGeneralizedTCR.submissionBaseDeposit();

        return arbitrationCost + baseDeposit;
    }

    /**
     * @notice Badge can be minted if it was never requested for the address or if it has a due date before now
     */
    function canRequestBadge(uint256 _badgeId, address _account) public view returns (bool) {
        ITheBadge.Badge memory _badge = theBadge.badge(_badgeId, _account);

        if (_badge.dueDate == 0 && (_badge.status == BadgeStatus.InReview || _badge.status == BadgeStatus.Approved)) {
            return false;
        }

        if (_badge.dueDate > 0 && block.timestamp < _badge.dueDate) {
            return false;
        }

        return true;
    }

    /**
     * @notice mint badge for kleros strategy
     */
    function requestBadge(address callee, uint256 badgeId, address account, bytes calldata data) public payable {
        uint256 mintCost = badgeRequestValue(badgeId);
        if (msg.value != mintCost) {
            revert KlerosBadgeTypeController__mintBadge_wrongValue();
        }

        KlerosBadgeType storage _klerosBadgeType = klerosBadgeType[badgeId];

        ILightGeneralizedTCR lightGeneralizedTCR = ILightGeneralizedTCR(_klerosBadgeType.tcrList);
        RequestBadgeData memory args = abi.decode(data, (RequestBadgeData));

        // save deposit amount for callee as it has to be returned if it was not challenged.
        lightGeneralizedTCR.addItem{ value: (msg.value) }(args.evidence);

        klerosBadge[badgeId][account] = KlerosBadge(keccak256(abi.encodePacked(args.evidence)), callee, msg.value);
        emit MintKlerosBadge(callee, badgeId, account, args.evidence);
    }

    /**
     * @notice claim a badge from a TCR list
     * a. Marks asset as Approved
     * b. Transfers deposit to badge's callee
     * c. Sets badge's callee deposit to 0
     */
    function claimBadge(uint256 badgeId, address account) public payable {
        KlerosBadgeType storage _klerosBadgeType = klerosBadgeType[badgeId];
        KlerosBadge storage _klerosBadge = klerosBadge[badgeId][account];

        ILightGeneralizedTCR lightGeneralizedTCR = ILightGeneralizedTCR(_klerosBadgeType.tcrList);
        lightGeneralizedTCR.executeRequest(_klerosBadge.itemID);

        theBadge.updateBadgeStatus(badgeId, account, BadgeStatus.Approved);

        if (_klerosBadge.deposit > address(this).balance) {
            revert KlerosBadgeTypeController__claimBadge_insufficientBalance();
        }

        payable(_klerosBadge.callee).transfer(_klerosBadge.deposit);
        _klerosBadge.deposit = 0;
    }

    function balanceOf(uint256 badgeId, address account) public view returns (uint256) {
        KlerosBadgeType storage _klerosBadgeType = klerosBadgeType[badgeId];
        KlerosBadge storage _klerosBadge = klerosBadge[badgeId][account];

        if (_klerosBadgeType.tcrList != address(0)) {
            ILightGeneralizedTCR lightGeneralizedTCR = ILightGeneralizedTCR(_klerosBadgeType.tcrList);
            (uint8 klerosItemStatus, , ) = lightGeneralizedTCR.getItemInfo(_klerosBadge.itemID);
            if (klerosItemStatus == 1 || klerosItemStatus == 3) {
                return 1;
            }
        }

        return 0;
    }

    /**
     * @notice we need a receive function to receive deposits devolution from kleros
     */
    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "../utils.sol";

interface IBadgeController {
    function createBadgeType(uint256 badgeId, bytes calldata data) external payable;

    function requestBadge(address callee, uint256 badgeId, address account, bytes calldata data) external payable;

    function claimBadge(uint256 badgeId, address account) external payable;

    function badgeRequestValue(uint256 badgeId) external view returns (uint256);

    function canRequestBadge(uint256 badgeId, address account) external view returns (bool);

    function balanceOf(uint256 badgeId, address account) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

/**
 *  @title LightGeneralizedTCR
 *  Aa curated registry for any types of items. Just like a TCR contract it features the request-challenge protocol and appeal fees crowdfunding.
 *  The difference between LightGeneralizedTCR and GeneralizedTCR is that instead of storing item data in storage and event logs,
 *  LightCurate only stores the URI of item in the logs. This makes it considerably cheaper to use and allows more flexibility with the item columns.
 */
interface ILightGeneralizedTCR {
    enum Status {
        Absent, // The item is not in the registry.
        Registered, // The item is in the registry.
        RegistrationRequested, // The item has a request to be added to the registry.
        ClearingRequested // The item has a request to be removed from the registry.
    }

    /**
     * @dev Submit a request to register an item. Accepts enough ETH to cover the deposit, reimburses the rest.
     * @param _item The URI to the item data.
     */
    function addItem(string calldata _item) external payable;

    /**
     * @notice Gets the arbitratorExtraData for new requests.
     * @dev Gets the latest value in arbitrationParamsChanges.
     * @return The arbitrator extra data.
     */
    function arbitratorExtraData() external view returns (bytes memory);

    function submissionBaseDeposit() external view returns (uint256);

    function getItemInfo(
        bytes32 _itemID
    ) external view returns (uint8 status, uint256 numberOfRequests, uint256 sumDeposit);

    function executeRequest(bytes32 _itemID) external;

    function challengePeriodDuration() external returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import { ILightGeneralizedTCR } from "./ILightGeneralizedTCR.sol";

import { IArbitrator } from "../../lib/erc-792/contracts/IArbitrator.sol";

/**
 *  @title LightGTCRFactory
 *  registry for LightGeneralizedTCR instances.
 */
interface ILightGTCRFactory {
    /**
     *  @dev Deploy the arbitrable curated registry.
     *  @param _arbitrator Arbitrator to resolve potential disputes. The arbitrator is trusted to support appeal periods and not reenter.
     *  @param _arbitratorExtraData Extra data for the trusted arbitrator contract.
     *  @param _connectedTCR The address of the TCR that stores related TCR addresses. This parameter can be left empty.
     *  @param _registrationMetaEvidence The URI of the meta evidence object for registration requests.
     *  @param _clearingMetaEvidence The URI of the meta evidence object for clearing requests.
     *  @param _governor The trusted governor of this contract.
     *  @param _baseDeposits The base deposits for requests/challenges as follows:
     *  - The base deposit to submit an item.
     *  - The base deposit to remove an item.
     *  - The base deposit to challenge a submission.
     *  - The base deposit to challenge a removal request.
     *  @param _challengePeriodDuration The time in seconds parties have to challenge a request.
     *  @param _stakeMultipliers Multipliers of the arbitration cost in basis points (see LightGeneralizedTCR MULTIPLIER_DIVISOR) as follows:
     *  - The multiplier applied to each party's fee stake for a round when there is no winner/loser in the previous round.
     *  - The multiplier applied to the winner's fee stake for an appeal round.
     *  - The multiplier applied to the loser's fee stake for an appeal round.
     *  @param _relayContract The address of the relay contract to add/remove items directly.
     */
    function deploy(
        IArbitrator _arbitrator,
        bytes memory _arbitratorExtraData,
        address _connectedTCR,
        string memory _registrationMetaEvidence,
        string memory _clearingMetaEvidence,
        address _governor,
        uint256[4] memory _baseDeposits,
        uint256 _challengePeriodDuration,
        uint256[3] memory _stakeMultipliers,
        address _relayContract
    ) external;

    function instances(uint256 index) external returns (ILightGeneralizedTCR);

    function count() external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "../utils.sol";

interface ITheBadge {
    struct Badge {
        BadgeStatus status;
        uint256 dueDate;
    }

    function badge(uint256 _badgeId, address _account) external view returns (Badge memory);

    function updateBadgeStatus(uint256 badgeId, address badgeOwner, BadgeStatus status) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

// TODO: check how it can be marked as challenged. 
// Also how if it was rejected by kleros, can it be marked as Rejected here. 
enum BadgeStatus {
    // The asset has not been created.
    NotCreated,
    // The asset is going through an approval process.
    InReview,
    // The asset was approved.
    Approved,
    // The asset was rejected.
    Rejected,
    // The asset was revoked.
    Revoked
}