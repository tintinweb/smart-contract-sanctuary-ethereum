// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
contract CrowdFunding{
  address public owner;
  uint public projectTax;
  uint public projectCount;
  uint public balance;
  statStruct public stat;
  projectStruct[] projects;

  mapping (address => projectStruct[]) projectsOf;
  mapping (uint => backersStruct[]) backersOf;
  mapping (uint => bool) projectExist;

    enum statusEnum {
        OPEN,
        APPROVED,
        REVERTED,
        DELETED,
        PAIDOUT
    }
    struct statStruct {
        uint totalProjects;
        uint totalBacking;
        uint totalDonations;
    }
    struct backersStruct {
        address owner;
        uint contribution;
        uint timestamp;
        bool refunded;

    }
    struct projectStruct {
        uint id;
        address owner;
        string title;
        string desc;
        string image;
        uint goal;
        uint collected;
        uint createdTIme;
        uint expiresAt;
        uint backers;
        statusEnum status;
        uint redFlags;

    }
    modifier ownerOnly() {
        require(msg.sender==owner,"owner reserved part");
        _;
    }
    event Action(
        uint256 id,
        string actionType,
        address indexed executer,
        uint256 timestamp);

    constructor(uint _tax){
        owner=msg.sender;
        projectTax=_tax;
    }
    function  createProject (
        string memory _title,
        string memory _desc,
        string memory _image,
        uint _goal,
        uint _expiresAt) public  returns (bool) {

            require(bytes(_title).length>0,"Title cannot be empty");
            require(bytes(_desc).length>0,"Description cannot be empty");
            require(bytes(_image).length>0,"url cannot be empty");
            require(_goal>0 ether,"goal should be greater than 0");
            require(_expiresAt>block.timestamp,"expiration should be greater than the current timestamp");
            
            projectStruct memory newProject;

            newProject.id=projectCount;
            newProject.owner=msg.sender;
            newProject.title=_title;
            newProject.desc=_desc;
            newProject.image=_image;
            newProject.goal=_goal;
            newProject.expiresAt=_expiresAt;
            newProject.collected=0;
            newProject.createdTIme=block.timestamp;
            newProject.redFlags=0;
            newProject.status=statusEnum.OPEN;

            projects.push(newProject);
            projectExist[newProject.id]=true;
            projectsOf[newProject.owner].push(newProject);

            stat.totalProjects++;

            emit Action(projectCount++," new project created",msg.sender,block.timestamp);
            return true;
    

        
    }
    function updateProject ( uint id ,
    string memory _title,
    string memory _desc,
    string memory _image,
    uint _expiresAt) public returns (bool){
        require(msg.sender==projects[id].owner,"your are not the owner of this project");
        require(bytes(_title).length>0,"title cant be empty");
        require(bytes(_desc).length>0,"Description cant be empty");
        require(bytes(_image).length>0,"URL cant be empty");
        require(_expiresAt > block.timestamp,"time should be greter than the current time");
        projects[id].desc=_desc;
        projects[id].title=_title;
        projects[id].image=_image;
        projects[id].expiresAt=_expiresAt;
        
        emit Action(id,"project details got updated ",msg.sender,block.timestamp);
        return true;


    }

    function deleteProject(uint id) public returns (bool){
        require(msg.sender==projects[id].owner,"Unauthorized acess");
        projects[id].status==statusEnum.DELETED;
        //refund(id);
        emit Action(id,"Project deleted",msg.sender,block.timestamp);
        return true;
    }
    
}