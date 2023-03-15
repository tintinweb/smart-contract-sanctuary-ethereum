pragma solidity ^0.8.17;

contract PubliclyFundedDeployer {
    struct Project {
        address payable creator;
        string description;
        uint256 targetFunding;
        uint256 deadline;
        uint256 receivedFunding;
        bool isFunded;
        bytes contractBytecode;
        bytes constructorArguments;
        address deployedContract;
    }

    mapping(uint256 => Project) public projects;
    uint256 public nextProjectId;

    event ProjectCreated(uint256 projectId, string description, uint256 targetFunding, uint256 deadline);
    event DonationReceived(uint256 projectId, address donor, uint256 amount);
    event ProjectFunded(uint256 projectId, address creator, uint256 receivedFunding, address deployedContract);

    function createProject(string memory description, uint256 targetFunding, uint256 deadline, bytes memory contractBytecode, bytes memory constructorArguments) public {
        require(targetFunding > 0, "Target funding must be greater than 0.");
        require(deadline > block.timestamp, "Deadline must be in the future.");

        uint256 projectId = nextProjectId++;
        Project storage project = projects[projectId];
        project.creator = payable(msg.sender);
        project.description = description;
        project.targetFunding = targetFunding;
        project.deadline = deadline;
        project.receivedFunding = 0;
        project.isFunded = false;
        project.contractBytecode = contractBytecode;
        project.constructorArguments = constructorArguments;
        project.deployedContract = address(0);

        emit ProjectCreated(projectId, description, targetFunding, deadline);
    }

    function donate(uint256 projectId) public payable {
        Project storage project = projects[projectId];
        require(project.creator != address(0), "Project does not exist.");
        require(project.deadline > block.timestamp, "Project deadline has passed.");
        require(!project.isFunded, "Project is already funded.");

        project.receivedFunding += msg.value;
        if (project.receivedFunding >= project.targetFunding) {
            project.isFunded = true;
            project.creator.transfer(project.receivedFunding);

            // Deploy the contract if the project is funded
            (bool success, address deployedContract) = _deployContract(project.contractBytecode, project.constructorArguments);
            require(success, "Contract deployment failed.");
            project.deployedContract = deployedContract;

            emit ProjectFunded(projectId, project.creator, project.receivedFunding, deployedContract);
        } else {
            emit DonationReceived(projectId, msg.sender, msg.value);
        }
    }

    function _deployContract(bytes memory contractBytecode, bytes memory constructorArguments) internal returns (bool, address) {
        address deployedContract;
        bytes memory deploymentBytecode = abi.encodePacked(contractBytecode, constructorArguments);
        assembly {
            deployedContract := create(0, add(deploymentBytecode, 0x20), mload(deploymentBytecode))
        }
        return (deployedContract != address(0), deployedContract);
    }
}