// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

//Defining a function for Contract..
contract DonationPlatform {
    struct Project {
        address owner;          //describes the address of the owner of the project
        string title;           //describes the name of the project
        string about;           //describes what the project is all about.
        uint256 target;         //describes the amount needed for the project.
        uint256 deadline;       //describes the deadline date for the payment of project to be paid. 
        uint256 fundsCollected;     //describes the overall amount of funds collected for each project
        string photos;          //gives the url of the picture of the project
        address[] donators;     //provides the addresses of the project donators.
        uint256[] donations;    //provides the number of donations in the platform.
    }

    mapping(uint256 => Project) public projects;

    uint256 public numberOfProjects = 0;        //To keep track of the number of projects in the platform.

    //Defining the functionalities the project will contain..
    function createProject(address _owner, string memory _title, string memory _about, uint256 _target,
    uint256 _deadline, string memory _photos) public returns (uint256) {
        Project storage project = projects[numberOfProjects];

        //To test if everything is okay..
        require(project.deadline < block.timestamp, "The deadline for the Project has not been reached yet!" );

        project.owner = _owner;
        project.title = _title;
        project.about = _about;
        project.target = _target;
        project.deadline = _deadline;
        project.fundsCollected = 0;
        project.photos = _photos;

        numberOfProjects++;                 //incrementing number of projects as projects are added...

        return numberOfProjects - 1;        //the index of the mostly newly project...
    }

    function donateToProject(uint256 _id) public payable {
        uint256 amount = msg.value;         //this represents the amount you are trying to sen from the front-end...

        Project storage project = projects[_id];

        project.donators.push(msg.sender);      //this pushes the address of the person that donated into the platform...
        project.donations.push(amount);         //this pushes the amount the donator donated into the platform...

        (bool sent,) = payable(project.owner).call{value: amount}("");       //it lets us know if the transaction has been sent or not...

        if(sent) {
            project.fundsCollected = project.fundsCollected + amount;
        }
    }

    function getDonators(uint256 _id) view public returns (address[] memory, uint256[] memory) {
        return (projects[_id].donators, projects[_id].donations);
    }

    function getProjects() public view returns (Project[] memory)  {
        Project[] memory allProjects = new Project[](numberOfProjects);         //Creation of a new variable of empty arrays

        for (uint i = 0; i < numberOfProjects; i++) {
            Project storage item = projects[i];

            allProjects[i] = item;
        }

        return allProjects;
    }
}