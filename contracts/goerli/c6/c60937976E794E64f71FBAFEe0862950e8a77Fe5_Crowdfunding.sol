/**
 *Submitted for verification at Etherscan.io on 2022-08-06
*/

// Sources flattened with hardhat v2.10.1 https://hardhat.org

// File contracts/Crowdfunding.sol


pragma solidity ^0.8.9;
pragma abicoder v2;

contract Crowdfunding {


  enum State {
    Inactive,
    Active
  }

  struct Project {
    string id;
    string projectName;
    string description;
    address payable author;
    State active;
    uint funds;
    uint fundsGoal;
  }

  struct Contribution {
    address contributor;
    uint value;
  }

  Project [] public projects;
  mapping(string => Contribution[]) public contributions;

  function createProject(string memory _id, string memory _projectName, string memory _description, uint _fundsGoal) public{
    require(_fundsGoal > 0, 'Goal must be greater than 0');
    Project memory project = Project(_id, _projectName, _description, payable(msg.sender), State.Active , 0, _fundsGoal);
    projects.push(project);
  }


  event projectFunded(
    uint256 value,
    string id
  );


  event statusProject(
    State status,
    string id
  );


  modifier notOwner(uint projectIndex) {
    require(
      msg.sender != projects[projectIndex].author,
      "Owners can not fund their own projects"
    );
    _;
  }


  modifier onlyOwner(uint projectIndex) {
    require(
      msg.sender == projects[projectIndex].author,
      "Only the owner can changes the status of the Project"
    );
    _;
  }


  /** Sends Eth to the project */
  function fundProject(uint projectIndex) public payable notOwner(projectIndex){
    require(projects[projectIndex].active == State.Active, 'The project is closed, you can not send funds');
    require(msg.value > 0, 'Fund value must be greater than 0');
    Project memory project = projects[projectIndex];
    project.author.transfer(msg.value);
    project.funds += msg.value;
    projects[projectIndex] = project;
    contributions[project.id].push(Contribution(msg.sender, msg.value));
    emit projectFunded(msg.value, projects[projectIndex].id);
  }


  /** Change the status of the project */
  function changeStatus(State _active, uint projectIndex) public onlyOwner(projectIndex){
    require(projects[projectIndex].active != _active, 'The project is in that status already');
    projects[projectIndex].active = _active;
    emit statusProject(_active, projects[projectIndex].id);
  }
}