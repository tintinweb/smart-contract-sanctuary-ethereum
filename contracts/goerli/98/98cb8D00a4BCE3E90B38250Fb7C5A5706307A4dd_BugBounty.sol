// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// The BugBounty contract manages the overall bounty program and allows users to
// submit and confirm bug reports.
contract BugBounty {
  // The address of the contract owner.
  address public owner;
  address public bugReport;

  // The mapping of bounty IDs to Bounty structs.
  mapping(uint => Bounty) public bounties;

  // The mapping of bounty IDs to bugReports array.
  mapping(uint => BugReport[]) public reports;

  // The mapping of bounty IDs to report id to voted.
  mapping (uint => mapping (uint => mapping (address => bool))) voted;

 // The mapping of user to his balance.
  mapping(address => uint) public balances;

  // The struct representing a bounty.
  struct Bounty {
    // The ID of the bounty.
    uint id;
    // The reward for this bounty.
    uint reward;
    // The status of the bounty.
    // 0: open
    // 1: closed (reward paid)
    // 2: closed (no reward paid)
    uint status;
    // total evaluations
    uint total_eval;
    // total reports
    uint total_reports;
    // The name of the project.
    string name;
    // the creator of the bounty program
    address creator;
  }

  struct BugReport{
    // the Id of the Bounty
    uint bounty_id;
    // The severity of the issue {CRITICAL => 4, HIGH => 3, MEDIUM => 2, LOW => 1, INFORMATIONAL => 0}
    uint severity;
    // The reward in Wei
    uint reward;
    // the evaluation of the issue
    uint eval;
    // The address of the user who reported the bug.
    address reporter;
    // The title of the issue
    string title;
    // the description of the Bug
    string description;
    // the description of the Bug
    string recommendation;
  }

  // The counter for generating unique bounty IDs.
  uint public bountyCounter;

  // The event that is emitted when a new bounty is created.
  event NewBounty(uint id, uint reward, string name);
  // The event that is emitted when a new report is created.
  event NewReport(uint id, string _title, string _description, string _recommendation, address reporter);
  // The event that is emitted when a bounty is closed.
  event BountyClosed(uint id, uint status);

  // The constructor sets the contract owner to the calling address.
  constructor() {
    owner = msg.sender;
  }

  // The createBounty function allows the owner to create a new bounty.
  function createBounty(string memory name,uint _reward) public payable {
    require(msg.value == _reward, "The reward should be payed to the contract");
    bountyCounter++;
    bounties[bountyCounter] = Bounty(bountyCounter, _reward, 0, 0, 0, name, msg.sender);
    emit NewBounty(bountyCounter, _reward, name);
  }

  // The reportBug function allows any user to report a bug for an open bounty.
  function reportBug(uint _bountyId,uint _severity,string memory _title, string memory _description, string memory _recommendation) public {
    require(_severity <= 4, "Invalid severity");
    Bounty storage bounty = bounties[_bountyId];
    require(bounty.status == 0, "This bounty is not open.");
    reports[bountyCounter].push(BugReport(bountyCounter, _severity, 0, 0, msg.sender, _title, _description, _recommendation));
    bounty.total_reports++;
    emit NewReport(_bountyId, _title, _description,  _recommendation,  msg.sender);
  }

  // The confirmBug function allows the owner to confirm that a reported bug is valid
  // and pay the reward to the reporter.
  function evalBug(uint _bountyId, uint _report_id,uint _eval) public {
    Bounty storage bounty = bounties[_bountyId];
    BugReport storage report = reports[_bountyId][_report_id];
    require(bounty.status == 0, "This bounty is not open.");
    require(msg.sender == owner, "Only the owner can confirm bugs.");
    require(_eval <= 10, "Only the owner can confirm bugs.");
    require(voted[_bountyId][_report_id][msg.sender], "Already voted");
    report.eval += _eval;
    voted[_bountyId][_report_id][msg.sender] = true;
    bounty.total_eval += _eval;
  }

  // The closeBounty function allows the creator to close a bounty
  function closeBounty(uint _bountyId) public {
    Bounty storage bounty = bounties[_bountyId];
    require(bounty.status == 0, "This bounty is not open.");
    require(msg.sender == bounty.creator, "Only the creator can close the bounty.");
    bounty.status = 1;
    if (bounty.total_eval > 0) _distribute(bounty);
    emit BountyClosed(_bountyId, 1);
  }

  // The _distribute function allows the creator to distribute the reward of the bounty
  function _distribute(Bounty storage _bounty) private{
    for (uint i = 0; i < _bounty.total_reports; i++) {
      BugReport storage report = reports[_bounty.id][i];
      report.reward = _bounty.reward * report.eval/ _bounty.total_eval;
      balances[msg.sender] += report.reward;
    }
  }
}