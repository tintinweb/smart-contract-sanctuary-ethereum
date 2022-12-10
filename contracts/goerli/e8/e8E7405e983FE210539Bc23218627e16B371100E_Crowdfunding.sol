// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import {ICrowdfunding} from "./ICrowdfunding.sol";

/**
 * @title Crowdfunding
 * @author Lars Raschke
 * @dev Complete source code: https://github.com/raschke-chainsulting/crowdfunding
 * @notice This contract implements a crowdfunding platform. It allows users to
 * create crowdfunding projects and participate to them. The owner of a project
 * can withdraw the funds of the project.
 */
contract Crowdfunding is ICrowdfunding {
    // counter to generate unique project ids
    uint256 private projectIdCounter;

    // array to store all projects
    Project[] private projects;

    // mapping to store all contributions of users to projects
    // user address => project id => amount of ether contributed
    mapping(address => mapping(uint256 => uint256)) private contributions;

    // modifier to check if the project with the given id exists
    modifier projectExists(uint256 _projectId) {
        require(
            _projectId < projectIdCounter,
            "Project with given id does not exist"
        );
        _;
    }

    // modifier to check if the caller of a function is the owner of the project
    modifier onlyProjectOwner(uint256 _projectId) {
        require(
            projects[_projectId].owner == msg.sender,
            "Only the project owner can call this function"
        );
        _;
    }

    /**
     * @notice Creates a new crowdfunding project. The caller of this function
     * will be the owner of the project.
     * @param _title The title of the project.
     * @param _description The description of the project.
     * @param _participationAmount The amount of ether that must be sent to the
     * project to participate to it.
     * @return The id of the created project.
     */
    function createProject(
        string calldata _title,
        string calldata _description,
        uint256 _participationAmount
    ) external override returns (uint256) {
        // check if input parameters are valid
        require(bytes(_title).length > 0, "Title must not be empty");
        require(
            bytes(_description).length > 0,
            "Description must not be empty"
        );
        require(
            _participationAmount > 0,
            "Participation amount must be greater than 0"
        );

        // create new project and push it to the projects array
        projects.push(
            Project(
                projectIdCounter,
                _title,
                _description,
                payable(msg.sender),
                _participationAmount,
                0
            )
        );

        // emit event for the created project
        emit ProjectCreated(projectIdCounter, msg.sender);

        // increment project id counter
        projectIdCounter++;

        // return the id of the created project
        return projectIdCounter - 1;
    }

    /**
     * @notice The caller of this function will participate to the project with
     * the given id. The amount of ether sent with the transaction will be
     * added to the project's balance if it is not already finished. The amount
     * of ther must be the defined participation amount.
     */
    function participateToProject(
        uint256 _projectId
    ) external payable override projectExists(_projectId) {
        // check if participation amount is correct
        require(
            msg.value >= projects[_projectId].participationAmount,
            "Not enough funds sent"
        );
        // update users contributions
        contributions[msg.sender][_projectId] += msg.value;

        // update total funding amount
        projects[_projectId].totalFundingAmount += msg.value;

        // emit event for the participation
        emit ParticipatedToProject(_projectId, msg.sender, msg.value);
    }

    /**
     * @notice Returns the project with the given id.
     * @param _projectId The id of the project.
     * @return The project with the given id.
     */
    function searchForProject(
        uint256 _projectId
    )
        external
        view
        override
        projectExists(_projectId)
        returns (Project memory)
    {
        return projects[_projectId];
    }

    /**
     * @notice Returns the amount of ether contributed by the given contributor to
     * the project with the given id.
     * @param _contributor The address of the contributor.
     * @param _projectId The id of the project.
     * @return The amount of ether contributed by the given contributor to the
     * project with the given id.
     */
    function retrieveContributions(
        address _contributor,
        uint256 _projectId
    ) external view override projectExists(_projectId) returns (uint256) {
        return contributions[_contributor][_projectId];
    }

    /**
     * @notice Withdraws the funds of the project with the given id. The caller
     * must be the owner of the project.
     * @param _projectId The id of the project.
     */
    function withdrawlFunds(
        uint256 _projectId
    ) external override projectExists(_projectId) onlyProjectOwner(_projectId) {
        // check if there are funds to withdraw
        require(
            projects[_projectId].totalFundingAmount > 0,
            "No funds to withdraw"
        );

        // get the amount to withdraw
        uint256 amount = projects[_projectId].totalFundingAmount;
        // reset total funding amount
        projects[_projectId].totalFundingAmount = 0;
        // emit withdrawl event
        emit FundsWithdrawn(_projectId, msg.sender, amount);
        // transfer the amount to the owner
        payable(msg.sender).transfer(amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

/**
 * @title ICrowdfunding
 * @author Lars Raschke
 * @dev Complete source code: https://github.com/raschke-chainsulting/crowdfunding
 * @notice This interface defines the functions, structs and events that are
 * used and implemented by the Crowdfunding contract.
 */
interface ICrowdfunding {
    // The struct that defines a crowdfunding project.
    struct Project {
        uint256 id;
        string title;
        string description;
        address payable owner;
        uint256 participationAmount;
        uint256 totalFundingAmount;
    }

    /**
     * @notice Emitted when a new project is created.
     * @param _projectId The id of the created project.
     * @param _projectOwner The address of the project owner.
     */
    event ProjectCreated(
        uint256 indexed _projectId,
        address indexed _projectOwner
    );

    /**
     * @notice Emitted when a user participates to a project.
     * @param _projectId The id of the project.
     * @param _participant The address of the participant.
     * @param _amount The amount of ether sent by the participant.
     */
    event ParticipatedToProject(
        uint256 indexed _projectId,
        address indexed _participant,
        uint256 _amount
    );

    /**
     * @notice Emitted when the owner of a project withdraws the funds of the project.
     * @param _projectId The id of the project.
     * @param _projectOwner The address of the project owner.
     * @param _amount The amount of ether withdrawn by the project owner.
     */
    event FundsWithdrawn(
        uint256 indexed _projectId,
        address indexed _projectOwner,
        uint256 _amount
    );

    /**
     * @notice Creates a new crowdfunding project. The caller of this function
     * will be the owner of the project.
     * @param _title The title of the project.
     * @param _description The description of the project.
     * @param _participationAmount The amount of ether that must be sent to the
     * project to participate to it.
     * @return The id of the created project.
     */
    function createProject(
        string calldata _title,
        string calldata _description,
        uint256 _participationAmount
    ) external returns (uint256);

    /**
     * @notice The caller of this function will participate to the project with
     * the given id. The amount of ether sent with the transaction will be
     * added to the project's balance if it is not already finished. The amount
     * of ther must be the defined participation amount.
     */
    function participateToProject(uint256 _projectId) external payable;

    /**
     * @notice Returns the project with the given id.
     * @param _projectId The id of the project.
     * @return The project with the given id.
     */
    function searchForProject(
        uint256 _projectId
    ) external view returns (Project memory);

    /**
     * @notice Returns the amount of ether contributed by the given contributor to
     * the project with the given id.
     * @param _contributor The address of the contributor.
     * @param _projectId The id of the project.
     * @return The amount of ether contributed by the given contributor to the
     * project with the given id.
     */
    function retrieveContributions(
        address _contributor,
        uint256 _projectId
    ) external view returns (uint256);

    /**
     * @notice Withdraws the funds of the project with the given id. The caller
     * must be the owner of the project.
     * @param _projectId The id of the project.
     */
    function withdrawlFunds(uint256 _projectId) external;
}