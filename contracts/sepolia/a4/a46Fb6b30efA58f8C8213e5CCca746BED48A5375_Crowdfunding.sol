// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

/**
 * @title Crowdfunding
 * @dev A contract for a crowdfunding platform.
 */
contract Crowdfunding {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    struct Project {
        address owner;
        string name;
        string description;
        string imageUrl;
        uint256 fundingGoal;
        uint256 fundsRaised;
        uint256 endTime;
        mapping(address => uint256) contributions;
        mapping(address => bool) rewardClaimed;
        bool closed;
    }

    mapping(uint256 => Project) public projects;
    uint256 public projectCounter;

    event ProjectCreated(uint256 indexed projectId, address indexed owner);
    event ContributionMade(uint256 indexed projectId, address indexed contributor, uint256 amount);
    event FundingSuccessful(uint256 indexed projectId, uint256 amountRaised);
    event RewardClaimed(uint256 indexed projectId, address indexed contributor, uint256 reward);

    /**
     * @dev Checks if the project is open.
     * @param _projectId The project ID.
     */
    modifier onlyOpenProject(uint256 _projectId) {
        require(!projects[_projectId].closed, "The project is closed");
        _;
    }

    /**
     * @dev Checks if the caller is the contract owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function");
        _;
    }

    /**
     * @dev Creates a new crowdfunding project.
     * @param _name The name of the project.
     * @param _description The description of the project.
     * @param _imageUrl The URL of the project's image.
     * @param _fundingGoal The funding goal of the project.
     * @param _endTime The end time of the project's fundraising period.
     */
    function createProject(
        string memory _name,
        string memory _description,
        string memory _imageUrl,
        uint256 _fundingGoal,
        uint256 _endTime
    ) external {
        require(_fundingGoal > 0, "The funding goal must be greater than zero");
        require(_endTime > block.timestamp, "The end time must be in the future");

        uint256 newProjectId = projectCounter;
        Project storage project = projects[newProjectId];
        project.owner = msg.sender;
        project.fundingGoal = _fundingGoal;
        project.endTime = _endTime;
        project.name = _name;
        project.description = _description;
        project.imageUrl = _imageUrl;
        projectCounter++;

        emit ProjectCreated(newProjectId, msg.sender);
    }

    /**
     * @dev Contributes to the funding of a project.
     * @param _projectId The project ID.
     */
    function contribute(uint256 _projectId) external payable onlyOpenProject(_projectId) {
        Project storage project = projects[_projectId];
        require(block.timestamp < project.endTime, "The project has ended");
        require(msg.value > 0, "The contribution amount must be greater than zero");

        project.contributions[msg.sender] += msg.value;
        project.fundsRaised += msg.value;

        emit ContributionMade(_projectId, msg.sender, msg.value);
    }

    /**
     * @dev Claims the reward for a given contribution to a project.
     * @param _projectId The project ID.
     */
    function claimReward(uint256 _projectId) external onlyOpenProject(_projectId) {
        Project storage project = projects[_projectId];
        require(block.timestamp >= project.endTime, "The project has not ended yet");
        require(project.contributions[msg.sender] > 0, "No contribution made");
        require(!project.rewardClaimed[msg.sender], "Reward already claimed");

        uint256 rewardPercentage = (project.contributions[msg.sender] * 100) / project.fundingGoal;

        project.rewardClaimed[msg.sender] = true;

        emit RewardClaimed(_projectId, msg.sender, rewardPercentage);
    }

    /**
     * @dev Closes a project.
     * @param _projectId The project ID.
     */
    function closeProject(uint256 _projectId) external onlyOwner {
        Project storage project = projects[_projectId];
        require(!project.closed, "The project is already closed");
        require(block.timestamp >= project.endTime, "The project has not ended yet");

        project.closed = true;
        emit FundingSuccessful(_projectId, project.fundsRaised);
    }
}