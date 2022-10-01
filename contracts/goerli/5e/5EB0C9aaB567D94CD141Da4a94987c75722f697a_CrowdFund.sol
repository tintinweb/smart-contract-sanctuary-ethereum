// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract CrowdFund{
    struct Project{
        uint256 id;
        uint256 targetAmount;
        uint256 accumulatedAmount;
        string name;
        address owner;
        address recipient;
    }
    //store amount a user had donated
    //use a nested mapping
    mapping(address=>mapping(uint256=>uint256))public donatationsPerUserPerProject;
    //storing in mappings is much cheaper. Rather store data than try and process
    mapping(address => uint256) public usersTotalDonations;
    //donatationsPerUserPerProject[msg.sender][0]


    //create mapping
    mapping(uint => Project) public projects;
    //make sure you track the size of the mapping with a counter.
    uint256 public numberOfProjects=0;
    constructor(){

    }

    mapping(uint256 => uint256) public balances;

    //use "memory" to save a string as a local variable
    function createProject(string memory _name,address _recipient,uint256 _targetAmount) public {
        //FIRST: always make sure params are valud
        require(_recipient!= address(0),"Cannot be address zero");

        //2nd, create project object and set variables
        projects[numberOfProjects]=Project({
            id:numberOfProjects,
            targetAmount: _targetAmount,
            accumulatedAmount: 0,
            name:_name,
            owner:msg.sender,
            recipient: _recipient
        });
        //Increment number of projects
        numberOfProjects++;
    }

    function donate(uint256 _projectID) public payable {
        //make sure that the project exist
        require(_projectID<=numberOfProjects,"Invalid ID");
        //get amount that was sent into the contract
        projects[_projectID].accumulatedAmount+=msg.value;
        balances[_projectID]+=msg.value;
        usersTotalDonations[msg.sender]+=msg.value;
        donatationsPerUserPerProject[msg.sender][_projectID]+=msg.value;

        if(projects[_projectID].accumulatedAmount>=projects[_projectID].targetAmount){
            //call withdraw
            withdraw(_projectID);
        }

        
    }

    function withdraw(uint256 _projectID) internal {

        //for optimisations
        Project memory tempProject=projects[_projectID];


        balances[_projectID]-=tempProject.accumulatedAmount;
        address targetRecipient=tempProject.recipient;
        uint256 amountPayable=tempProject.accumulatedAmount;
        (bool sent, )=targetRecipient.call{value:amountPayable}("");
        require(sent, "Failed to send Ether");
    }
    //for a contract to know that it can accept Ether
    receive() external payable{}
}