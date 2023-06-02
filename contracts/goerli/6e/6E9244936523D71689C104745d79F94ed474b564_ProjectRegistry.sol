// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

contract ProjectRegistry {
    struct Project {
        string projectID;
        address owner;
        address contractAddress;
    }

    mapping(address => Project) private projects; // Mapping from contract address to project
    mapping(address => address[]) private userProjects; // Mapping from user address to an array of contract addresses
    mapping(address => uint) public userStatus;
    mapping(address => uint) public projectCount;

    uint public premiumFee = 0.005 ether;
    uint public goldFee = 0.01 ether;

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
    
    function getProjectID(address contractAddress) public view returns (string memory) {
        return projects[contractAddress].projectID;
    }

    function addProject(string memory _projectID, address _contractAddress) public {
        require(
            (userStatus[msg.sender] == 1 && projectCount[msg.sender] < PREMIUM_LIMIT) || 
            (userStatus[msg.sender] == 2 && projectCount[msg.sender] < GOLD_LIMIT),
            "You have reached your project limit"
        );
        projects[_contractAddress] = Project(_projectID, msg.sender, _contractAddress);
        userProjects[msg.sender].push(_contractAddress);
        projectCount[msg.sender]++;
    }

    function updateProject(address _contractAddress, string memory _newProjectID) public {
        require(projects[_contractAddress].owner == msg.sender, "Invalid project contract address");
        projects[_contractAddress].projectID = _newProjectID;
    }

    function removeProject(address _contractAddress) public {
        require(projects[_contractAddress].owner == msg.sender, "Invalid project contract address");
        delete projects[_contractAddress];
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