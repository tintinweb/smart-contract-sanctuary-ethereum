/**
 *Submitted for verification at Etherscan.io on 2023-03-01
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

contract PheaseDonate {
    struct Project {
        string name;
        string description;
        uint256 amountCollected;
        string associationName;
        address associationAddress;
    }
    event Donation(
        address indexed donator,
        uint256 amount,
        uint256 date,
        uint256 indexed projectIndex
    );
    event AssociationAddressUpdated(
        uint256 indexed projectIndex,
        address indexed oldAssociationAddress,
        address indexed newAssociationAddress
    );

    address payable public manager;
    address public factoryContractAddress;
    Project[] public projects;
    uint256 public commission;
    uint256 public donatorsCount;
    mapping(address => bool) public isDonator;

    modifier isOwner() {
        require(msg.sender == manager, "Caller is not owner");
        _;
    }

    constructor() {
        manager = payable(msg.sender);
        donatorsCount = 0;
        commission = 25; // 2.5% commissions
    }

    /**
     * IS OWNER
     */
    function createProject(
        string memory _name,
        string memory _description,
        string memory _associationName,
        address _associationAddress
    ) public {
        require(
            msg.sender == manager || msg.sender == factoryContractAddress,
            "Caller is not owner or is not the factory contract connected to it"
        );
        Project memory project = Project({
            name: _name,
            description: _description,
            amountCollected: 0,
            associationName: _associationName,
            associationAddress: _associationAddress
        });
        projects.push(project);
    }

    function setCommission(uint256 _commission) public isOwner {
        commission = _commission;
    }

    function setFactoryContractAddress(
        address _factoryContractAddress
    ) public isOwner {
        factoryContractAddress = _factoryContractAddress;
    }

    function updateProjectAssociationAddress(
        uint256 _projectIndex,
        address _associationAddress
    ) public isOwner {
        emit AssociationAddressUpdated(
            _projectIndex,
            projects[_projectIndex].associationAddress,
            _associationAddress
        );
        projects[_projectIndex].associationAddress = _associationAddress;
    }

    /**
     * PUBLIC FUNCTIONS
     */
    function donate(uint256 _projectIndex) public payable {
        require(msg.value > 0, "Amount must be greater than 0");
        require(
            _projectIndex < projects.length,
            "The project you are trying to donate to does not exist"
        );
        uint256 commissionAmount = (msg.value * commission) / 1000;
        uint256 amountToProject = msg.value - commissionAmount;
        projects[_projectIndex].amountCollected +=
            amountToProject +
            commissionAmount;
        if (!isDonator[msg.sender]) {
            isDonator[msg.sender] = true;
            donatorsCount++;
        }
        emit Donation(msg.sender, msg.value, block.timestamp, _projectIndex);
        payable(manager).transfer(commissionAmount);
        payable(projects[_projectIndex].associationAddress).transfer(
            amountToProject
        );
    }

    function getProjectLength() public view returns (uint256) {
        return projects.length;
    }

    function getProject(
        uint256 _projectIndex
    ) public view returns (Project memory) {
        return projects[_projectIndex];
    }
}