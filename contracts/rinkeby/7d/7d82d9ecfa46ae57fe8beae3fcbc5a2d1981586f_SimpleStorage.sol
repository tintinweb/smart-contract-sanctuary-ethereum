/**
 *Submitted for verification at Etherscan.io on 2022-09-16
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract SimpleStorage{
  address payable public owner;
  //address[] public approved;// contributors ka address save krny k liye
  uint public projectTax;// tax deduct krny k liye
  uint public projectCount=0;// kitne prijects total ho chuky h
  uint public balances;// projrct account me balance 
  projectStat public stat; // whole crowd funding projects
  projectInfo[] projects;// project li sari info k liye ik alag se structure

mapping(address => projectInfo[]) projectsOf;
mapping(uint => donarInfo[]) backersOf;
mapping(uint => bool) public projectExist;
// whole picture of the projects
struct projectStat{
uint totalProjects;
uint totalBacking;
uint totalCollection;
}

//priject ki different states k liye
enum projectStatus{
  open,
  approved,
  reverted,
  deleted,
  paidout
}
//donar ki info k liye structured datatype

struct donarInfo{
  address backer;
  uint contribution;
  uint timestamp;
  bool refund;
}
//donar ki info k liye structured datatype

struct projectInfo{
  uint id;
  address owner;
  string title;
  string description;
  string imageUrl;   
  uint timestamp;
  uint cost;
  uint raised;
  uint backer;
  uint expiresAt;
  projectStatus status;
}
//to perform diff events
event Action (
    uint256 id,
    string actionType,
    address indexed executor,
    uint256 timestamp
);

// the constructor dhould b owner check and min Contributionn check
//uint tax, uint minimum 
//projectTax = tax;
//  minContributions= minimum;
constructor () payable
{
  owner=payable(msg.sender);
  
}

// to create the project
function createProject(
  string memory title,
  string memory description,
  string memory imageUrl,
  uint cost,
  uint expiresAt
  )public returns(bool) {
  require(bytes(title).length > 0,"Title can't be empty");
  require(bytes(description).length > 0,"Description can't be empty");

  require(bytes(imageUrl).length > 0,"Image can't be empty");
  projectInfo memory project;
  project.id = projectCount;
  project.owner = msg.sender;
  project.title =title;
  project.description= description;
  project.imageUrl= imageUrl;
  project.cost = cost;
  project.timestamp = block.timestamp;
  project.expiresAt = expiresAt;
  projects.push(project);
  projectExist[projectCount] = true;
  projectsOf[msg.sender].push(project);
  stat.totalProjects += 1;
  projectCount++;
  emit Action(projectCount, "Project Created", msg.sender, block.timestamp);
  //projectExist == true;
  return true;
}

function updateProject(
    uint id,
    string memory title,
    string memory description,
    string memory imageURL,
    uint expiresAt
    ) public returns (bool) {
    require(msg.sender == projects[id].owner, "Unauthorized Entity");
    require(projectExist[id], "Project not found");
    require(bytes(title).length > 0, "Title cannot be empty");
    require(bytes(description).length > 0, "Description cannot be empty");
    require(bytes(imageURL).length > 0, "ImageURL cannot be empty");
    projects[id].title = title;
    projects[id].description = description;
    projects[id].imageUrl = imageURL;
    projects[id].expiresAt = expiresAt;

    emit Action (
        id,
        "PROJECT UPDATED",
        msg.sender,
        block.timestamp
    );
    return true;
}

function deleteProject(uint id) public returns (bool) {
    require(projectExist[id], "Project not found");
    require(projects[id].status == projectStatus.open, "Project no longer opened");
    require(
        msg.sender == projects[id].owner ||
        msg.sender == owner,
        "Unauthorized Entity"
    );

    projects[id].status = projectStatus.deleted;

    emit Action (
        id,
        "PROJECT DELETED",
        msg.sender,
        block.timestamp
    );
    return true;
}
// this function is for donar to contribute 
  function contribute (uint id) public payable returns( bool)
  {
    donarInfo memory donar;
    donar.contribution=msg.value;
    require(projectExist[id],"project not found");
    require(projects[id].status ==projectStatus.open,"Project is closed");

    stat.totalBacking += 1;
    stat.totalCollection += msg.value;
    projects[id].raised += msg.value;
    projects[id].backer += 1;
    balances=msg.value;
    backersOf[id].push(
            donarInfo(
                msg.sender,
                msg.value,
                block.timestamp,
                false
            ));
    emit Action(
                projectCount, 
                "YOU ARE CONTRIBUTED TO THE PRIJECT"
                ,  msg.sender
                , block.timestamp);

      if(projects[id].raised >= projects[id].cost) {
            projects[id].status = projectStatus.approved;
            balances += projects[id].raised;
            performPayout(id);
            return true;
        }

        if(block.timestamp >= projects[id].expiresAt) {
            projects[id].status = projectStatus.reverted;
            performRefund(id);
            return true;
        }
    
    
  }

    function performPayout(uint id) internal {
        uint raised = (projects[id].raised);

        projects[id].status = projectStatus.paidout;
        payTo(owner, raised);

        balances -= projects[id].raised;

        emit Action (
            id,
            "PROJECT PAID OUT",
            msg.sender,
            block.timestamp
        );
    }

     function performRefund(uint id) internal {
        for(uint i = 0; i < backersOf[id].length; i++) {
            address _owner = backersOf[id][i].backer;
            uint _contribution = backersOf[id][i].contribution;
            
            backersOf[id][i].refund = true;
            backersOf[id][i].timestamp = block.timestamp;
            payTo(_owner, _contribution);

            stat.totalBacking -= 1;
            stat.totalCollection -= _contribution;
        }
    }


     function payTo(address to, uint256 amount) internal {
        (bool success, ) = payable(to).call{value: amount}("");
        require(success);
    }

//owner can start compain and set the. min contrubution
  /*function compaign(uint minValue) public  onlyOwner
  {
      minContributions=minValue;
   
  }
  */
function getBackers(uint id) public view returns (donarInfo[] memory) {
        return backersOf[id];
    }

      function getProjects() public view returns (projectInfo[] memory) {
        return projects;
    }

        function getProject(uint id) public view returns (projectInfo memory) {
        require(projectExist[id], "Project not found");

        return projects[id];
    }

     //function send() public payable{

       //     owner.transfer(msg.value);

        //}    //function transfer(address payable _to, uint _amount) public onlyOwner { 
    //    _to.transfer(_amount);
  //}
}