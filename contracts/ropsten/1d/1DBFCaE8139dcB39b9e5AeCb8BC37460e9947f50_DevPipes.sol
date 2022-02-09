// SPDX-License-Identifier: MIT
// Solidity files have to start with this pragma.
// It will be used by the Solidity compiler to validate its version.
pragma solidity ^0.8.0;


// This is the main building block for smart contracts.
contract DevPipes {
    // Some string type variables to identify the token.
    // The `public` modifier makes a variable readable from outside the contract.
    string public name;
    string public symbol;
    uint256 public balance;

    uint256 public projectIndex;
    uint256 public applicationIndex;
    uint256 public paymentsIndex;

    struct Payment {
        uint256 id;
        address user;
        uint256 amount;
        uint8 status;
    }

    struct Project {
        uint256 id;
        uint256 parentId;
        uint256 rootId;
        address creator;
        string name;
        string description;
        string uri;
        string tags;
        uint256 dueDate;
        uint256 budget;
        uint8 status;
    }

    struct Application {
        uint256 id;
        address applicant;
        uint256 projectID;
        string details1;
        string details2;
        bool accepted;
        uint8 status;
    }

    // An address type variable is used to store ethereum accounts.
    address public owner;

    Project[] public projects;
    mapping(uint256 => uint256[]) public subProjects;

    Application[] public applications;
    Payment[] public royalties;
    mapping(address => uint256[]) public userProjects;
    mapping(uint256 => uint256[]) public projectRoyalties;
    mapping(uint256 => uint256[]) public projectApplications;

    event ProjectCreated(address indexed _creator, uint256 _id);
    event ProjectEdited(address indexed _editor, uint256 indexed _id);
    event SubProjectCreated(address indexed _creator, uint256 indexed _id, uint256 indexed rootId, uint256 parentId);
    event ProjectPublished(uint256 indexed _id);

    function init() public {
        if(owner == address(0)) {
            owner = msg.sender;
            name = "Dev Pipes";
            symbol = "PIPES";
            balance = 0;
            projects.push(Project(0, 0, 0, address(0), "", "", "", "", 0, 0, 0));
            projectIndex = 1;
            applications.push(Application(0, address(0), 0, "", "", false, 0));
            applicationIndex = 1;
            royalties.push(Payment(0, address(0), 0, 0));
            paymentsIndex = 1;
        }
    }

    function createProject(string memory projectName, string memory description, string memory uri, 
                           string memory tags, uint256 dueDate, uint256 budget) public {

        Project memory project = Project(
            projectIndex, 0, 0, msg.sender, projectName, description, uri, tags, dueDate, budget, 0 
        );

        projects.push(project);
        userProjects[msg.sender].push(projectIndex);

        emit ProjectCreated(msg.sender, projectIndex);

        projectIndex++;
    }

    function editProject(uint256 projectId, string memory projectName, string memory description, string memory uri, 
                           string memory tags, uint256 dueDate, uint256 budget) public {

        assertProjectExists(projectId);
        Project storage proj = projects[projectId];
        require(proj.creator == msg.sender, "error_only_project_creator_can_edit");
        // require(proj.status == 0, "error_published_projects_cannot_be_edited"); 

        proj.name = projectName;
        proj.description = description;
        proj.uri = uri;
        proj.tags = tags;
        proj.dueDate = dueDate;
        proj.budget = budget;

        emit ProjectEdited(msg.sender, projectId);
    }

    function assertProjectExists(uint256 projectId) internal view {
        require(projectId <= projectIndex - 1, "error_project_does_not_exist");
    }

    function createSubProject(uint256 parentId, string memory projectName, string memory description, string memory uri, 
                              string memory tags, uint256 dueDate, uint256 budget) public {

        assertProjectExists(parentId);
        Project memory proj = projects[parentId];
        uint256 rootId = proj.rootId;
        
        if(rootId == 0) {
            rootId = parentId;
        }

        Project memory project = Project(
            projectIndex, parentId, rootId, msg.sender, projectName, description, uri, tags, dueDate, budget, 0
        );

        projects.push(project);
        subProjects[rootId].push(projectIndex);
        userProjects[msg.sender].push(projectIndex);

        emit SubProjectCreated(msg.sender, projectIndex, rootId, parentId);
        projectIndex++;
    }

    function applyForProject(address applicant, uint256 projectId, string memory details1, string memory details2) public {
        assertProjectExists((projectId));
        Project memory proj = projects[projectId];
        uint256 blockTS = block.timestamp * 1000;
        require(blockTS < proj.dueDate, "error_project_expired");
        require(proj.status > 0, "");

        Application memory application = Application(
            applicationIndex, applicant, projectId, details1, details2, false, 0
        );

        applications.push(application);
        projectApplications[projectId].push(applicationIndex);
        applicationIndex++;
    }

    function withdrawApplication(uint256 applicationId) public {
        Application storage application = applications[applicationId];
        require(application.applicant == msg.sender, "error_only_application_creator_can_edit");
        application.status = 1;
    }

    function addRoyalty(uint256 projectId, address user, uint256 amount) public {
        assertProjectExists((projectId));
        Project memory proj = projects[projectId];

        require(proj.creator == msg.sender, "error_only_project_creator_can_edit");

        uint256 total = this.getRoyaltiesTotal(projectId);

        require(total + amount <= proj.budget, "error_royalties_exceed_total_available");

        Payment memory payment = Payment(paymentsIndex, user, amount, 0);

        royalties.push(payment);
        projectRoyalties[projectId].push(paymentsIndex);

        paymentsIndex++;
    }

    function publish(uint256 projectId) public {
        assertProjectExists((projectId));
        Project storage proj = projects[projectId];
        require(proj.creator == msg.sender, "error_only_project_creator_can_edit");
        proj.status = 1;
        emit ProjectPublished(projectId);
    } 

    function getRoyaltiesTotal(uint256 projectId) public view returns(uint256) {
        assertProjectExists(projectId);
        uint256 total = 0;

        for(uint256 i = 0; i < projectRoyalties[projectId].length; i++) {
            uint256 childId = projectRoyalties[projectId][i];
            Payment memory royalty = royalties[childId];
            total += royalty.amount;
        }

        return total;
    }

    function getProjectsForUser(address user) external view returns(Project[] memory) {
        uint256 numUserProjects = userProjects[user].length;
        Project[] memory projectList = new Project[](numUserProjects);

        for(uint256 i; i < numUserProjects; i++) {
            uint256 projId = userProjects[user][i];
            projectList[i] = projects[projId];
        }
        return projectList;
    }

    function getProjectIdsForUser(address user) external view returns(uint256[] memory) {
        return userProjects[user];
    }
    
    function getAllProjects() external view returns(Project[] memory) {
        return projects;
    }
}