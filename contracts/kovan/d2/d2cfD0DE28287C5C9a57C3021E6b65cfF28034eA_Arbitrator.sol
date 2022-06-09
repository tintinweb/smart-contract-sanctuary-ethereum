// SPDX-License-Identifier: MIT

pragma solidity >=0.8;

import "@kleros/erc-792/contracts/IArbitrable.sol";
import "@kleros/erc-792/contracts/IArbitrator.sol";

/** @title An IArbitrator implemetation for testing purposes.
 *  @dev DON'T USE ON PRODUCTION.
 */
contract Arbitrator is IArbitrator {
  address public governor = msg.sender;
  uint256 internal arbitrationPrice = 1_000_000_000;

  struct Dispute {
    IArbitrable arbitrated;
    uint256 numberOfRulingOptions;
    uint256 ruling;
    DisputeStatus status;
    uint256 appealDeadline;
  }

  modifier onlyGovernor() {
    require(msg.sender == governor, "Can only be called by the governor.");
    _;
  }

  Dispute[] public disputes;

  function setArbitrationPrice(uint256 _arbitrationPrice) external onlyGovernor {
    arbitrationPrice = _arbitrationPrice;
  }

  function arbitrationCost(bytes memory) public view override returns (uint256 fee) {
    return arbitrationPrice;
  }

  function appealCost(uint256, bytes memory) public view override returns (uint256 fee) {
    return arbitrationCost("UNUSED");
  }

  function createDispute(uint256 _choices, bytes memory _extraData) public payable override returns (uint256 disputeID) {
    uint256 arbitrationFee = arbitrationCost(_extraData);
    require(msg.value >= arbitrationFee, "Value is less than required arbitration fee.");
    disputes.push(Dispute({
      arbitrated: IArbitrable(msg.sender),
      numberOfRulingOptions: _choices,
      ruling: 0,
      status: DisputeStatus.Waiting,
      appealDeadline: 0
    })); // Create the dispute and return its number.
    disputeID = disputes.length - 1;
    emit DisputeCreation(disputeID, IArbitrable(msg.sender));
  }

  function giveRuling(
    uint256 _disputeID,
    uint256 _ruling,
    uint256 _appealWindow
  ) external onlyGovernor {
    Dispute storage dispute = disputes[_disputeID];
    require(_ruling <= dispute.numberOfRulingOptions, "Invalid ruling.");
    require(dispute.status == DisputeStatus.Waiting, "The dispute must be waiting for arbitration.");

    dispute.ruling = _ruling;
    dispute.status = DisputeStatus.Appealable;
    dispute.appealDeadline = block.timestamp + _appealWindow;

    emit AppealPossible(_disputeID, dispute.arbitrated);
  }

  function appeal(uint256 _disputeID, bytes memory _extraData) public payable override {
    Dispute storage dispute = disputes[_disputeID];
    uint256 appealFee = appealCost(_disputeID, _extraData);
    require(dispute.status == DisputeStatus.Appealable, "The dispute must be appealable.");
    require(block.timestamp < dispute.appealDeadline, "The appeal must occur before the end of the appeal period.");
    require(msg.value >= appealFee, "Value is less than required appeal fee");

    dispute.appealDeadline = 0;
    dispute.status = DisputeStatus.Waiting;
    emit AppealDecision(_disputeID, IArbitrable(msg.sender));
  }

  function executeRuling(uint256 _disputeID) external {
    Dispute storage dispute = disputes[_disputeID];
    require(dispute.status == DisputeStatus.Appealable, "The dispute must be appealable.");
    require(block.timestamp >= dispute.appealDeadline, "The dispute must be executed after its appeal period has ended.");

    dispute.status = DisputeStatus.Solved;
    dispute.arbitrated.rule(_disputeID, dispute.ruling);
  }

  function disputeStatus(uint256 _disputeID) public view override returns (DisputeStatus status) {
    Dispute storage dispute = disputes[_disputeID];
    if (disputes[_disputeID].status == DisputeStatus.Appealable && block.timestamp >= dispute.appealDeadline)
      // If the appeal period is over, consider it solved even if rule has not been called yet.
      return DisputeStatus.Solved;
    else return disputes[_disputeID].status;
  }

  function currentRuling(uint256 _disputeID) public view override returns (uint256 ruling) {
    return disputes[_disputeID].ruling;
  }

  function appealPeriod(uint256 _disputeID) public view override returns (uint256 start, uint256 end) {
    Dispute storage dispute = disputes[_disputeID];
    return (block.timestamp, dispute.appealDeadline);
  }
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