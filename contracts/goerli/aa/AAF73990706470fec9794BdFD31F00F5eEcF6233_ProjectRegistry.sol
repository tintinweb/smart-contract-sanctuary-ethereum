// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

contract ProjectRegistry {
    struct Project {
        string projectID;
        address owner;
        address contractAddress;
    }

    mapping(address => mapping(string => Project)) private projects;
    mapping(address => uint) public userStatus;
    mapping(address => uint) public projectCount;

    uint public premiumFee = 0.05 ether;
    uint public goldFee = 0.1 ether;

    uint constant public PREMIUM_LIMIT = 3;
    uint constant public GOLD_LIMIT = 10;

    address payable public contractOwner;

    event PremiumUpgrade(address indexed user, uint amount);
    event GoldUpgrade(address indexed user, uint amount);

    constructor() {
        contractOwner = payable(msg.sender);
    }
    
    function getProjectCount(address user) public view returns (uint) {
        return projectCount[user];
    }
    
    function getProjectID(address user, string memory index) public view returns (string memory) {
        return projects[user][index].projectID;
    }

    function getContractAddress(address user, string memory index) public view returns (address) {
        return projects[user][index].contractAddress;
    }

    function addProject(string memory _projectID, string memory _index, address _contractAddress) public {
        require(
            (userStatus[msg.sender] == 1 && projectCount[msg.sender] < PREMIUM_LIMIT) || 
            (userStatus[msg.sender] == 2 && projectCount[msg.sender] < GOLD_LIMIT),
            "You have reached your project limit"
        );
        projects[msg.sender][_index] = Project(_projectID, msg.sender, _contractAddress);
        projectCount[msg.sender]++;
    }

    function updateProject(string memory _index, string memory _newProjectID, address _newContractAddress) public {
        require(projects[msg.sender][_index].owner == msg.sender, "Invalid project index");
        projects[msg.sender][_index].projectID = _newProjectID;
        projects[msg.sender][_index].contractAddress = _newContractAddress;
    }

    function removeProject(string memory _index) public {
        require(projects[msg.sender][_index].owner == msg.sender, "Invalid project index");
        delete projects[msg.sender][_index];
        if (projectCount[msg.sender] > 0) {
            projectCount[msg.sender]--;
        }
    }

    function upgradeToPremium() public payable {
        require(userStatus[msg.sender] < 1, "Already a premium or gold user");
        require(msg.value >= premiumFee, "Insufficient payment");
        userStatus[msg.sender] = 1;
        contractOwner.transfer(msg.value);
        emit PremiumUpgrade(msg.sender, msg.value);
    }

    function upgradeToGold() public payable {
        require(userStatus[msg.sender] < 2, "Already a gold user");
        require(msg.value >= goldFee, "Insufficient payment");
        userStatus[msg.sender] = 2;
        contractOwner.transfer(msg.value);
        emit GoldUpgrade(msg.sender, msg.value);
    }
}