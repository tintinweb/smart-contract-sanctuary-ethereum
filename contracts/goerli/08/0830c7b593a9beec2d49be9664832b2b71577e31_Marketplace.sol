// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./Ownable.sol";

contract Marketplace is Ownable {

    address OIL_CONTRACT;

    IERC20 public OIL;

    address public ruler;

    struct Project {
        uint id;
        uint cost;
        uint qty;
        bool filled;
        uint publishAt;
        uint[] entries;
    }
    
    event ProjectEntryPurchased(address indexed sender, uint projectId, uint entryId);
    event ProjectAdded(address sender, uint cost, uint qty, uint publishAt);

    modifier onlyAdmin {
         require(checkAdmin(_msgSender()), "Caller is not an admin");
         _;
    }

    modifier onlyRuler {
        require(msg.sender == ruler, "caller is not a ruler");
        _;
    }

    modifier validEntry(uint _projectId, uint _entryId) {
        validateEntry(_projectId, _entryId);
        _;
    }

    // if the marketplace is down
    bool public marketplaceActive;

    // holds a mapping between projects ids and their references
    mapping(uint => Project) private projects;

    // admins for the marketplace
    mapping(address => bool) admins;

    /********************************************
                RULER FUNCTIONS
     ********************************************/
    function setAdmin(address _address, bool _isAdmin) public onlyRuler {
        admins[_address] = _isAdmin;
    }

    function setOilContract(address _oilContract) public onlyRuler {
        OIL_CONTRACT = _oilContract;
        OIL = IERC20(OIL_CONTRACT);
    }

    function setMarketplaceActive(bool _isActive) public onlyRuler {
        marketplaceActive = _isActive;
    }

    function setup(address _oilContract) external {
        require(ruler == address(0), "Already initialized");
        ruler = msg.sender;
        OIL_CONTRACT = _oilContract;
        OIL = IERC20(OIL_CONTRACT);
    }

    function setRuler(address _ruler) onlyRuler public {
        ruler = _ruler;
    }

    /********************************************
                    ADMIN FUNCTIONS
     ********************************************/

    function addProject(uint _projectId, uint _cost, uint _qty, uint _publishAt) public onlyAdmin {

        // project ID should be > 0
        require(_projectId > 0, "Project ID can not be 0");

        // make sure project ID is unique
        require(!isProjectExists(_projectId), "Project ID already being used");

        // validate the quantity
        require(_qty > 0, "Quantity can not be 0");

        Project memory project = projects[_projectId];

        // add the project to the map
        project.id = _projectId;
        project.cost = _cost;
        project.qty = _qty;
        project.publishAt = _publishAt;

        projects[_projectId] = project;

        // emit an event
        emit ProjectAdded(msg.sender, _cost, _qty, _publishAt);
    }

    function updateProject(uint _projectId, uint _cost, uint _qty, bool _filled, uint _publishAt) public onlyAdmin {

        requireProjectExists(_projectId);
        Project storage project = projects[_projectId];

        // validate the quantity
        require(_qty > 0, "Quantity can not be 0");

        if ( project.cost != _cost)
            project.cost = _cost;

        if ( project.qty != _qty)
            project.qty = _qty;

        if ( project.filled != _filled)
            project.filled = _filled;

        if ( project.publishAt != _publishAt)
            project.publishAt = _publishAt;
    }

    /********************************************
                    USERS FUNCTIONS
     ********************************************/

    function addProjectEntry(uint _projectId, uint _referenceId) validEntry(_projectId, _referenceId) public  {

        Project storage project = projects[_projectId];

        // get the value only once
        address sender = _msgSender();

        // make sure wallet has enough $OIL
        require(OIL.balanceOf(sender) >= project.cost, "Not enough $OIL balance");

        // transfer OIL to OIL contract
        OIL.transferFrom(sender, OIL_CONTRACT, project.cost);

        //TODO: BURN $OIL ?

        // add the entry to the entries list
        project.entries.push(_referenceId);

        // emit an event
        emit ProjectEntryPurchased(msg.sender, _projectId, _referenceId);
    }

    function validateEntry(uint _projectId, uint _referenceId) internal view {

        require(marketplaceActive, "Marketplace is currently offline, try again later!");

        requireProjectExists(_projectId);

        Project memory project = projects[_projectId];

        require(_referenceId > 0, "Reference ID can not be 0");
        require(!project.filled, "Sold out");
        require(project.entries.length + 1 <= project.qty , "Sold out");
        require(block.timestamp >= project.publishAt, "Project is not live yet");

        bool referenceExists;

        for (uint i = 0; i < project.entries.length;) {
            if (project.entries[i] == _referenceId) {
                referenceExists = true;
                break;
            }
            unchecked {
                ++i;
            }
        }

        require(!referenceExists, "Reference ID already being used");
    }

    /********************************************
                    COMMON FUNCTIONS
     ********************************************/

    function checkAdmin(address _address) public view returns (bool) {
        return admins[_address] || _address == owner() || _address == ruler;
    }

    function isProjectExists(uint _id) public view returns (bool) {
       return projects[_id].id > 0;
    }

    function getProjectEntries(uint _projectId) public view returns (uint[] memory) {
        requireProjectExists(_projectId);
        return projects[_projectId].entries;
    }

    function requireProjectExists(uint _projectId) private view {
        require(isProjectExists(_projectId), "Project does not exist");
    }

    function getProjects(uint[] calldata _projectsIds) public view returns (Project[] memory) {
        
        Project[] memory projectsArray = new Project[](_projectsIds.length);
        uint existedProjectsCount = 0;

        for(uint i = 0; i < _projectsIds.length;) {
            uint projectId = _projectsIds[i];
            if ( isProjectExists(projectId) ) {
                projectsArray[existedProjectsCount] = projects[projectId]; 
                existedProjectsCount += 1;
            }
            unchecked {
                ++i;
            }
        }

        Project[] memory existedProjectsArray = new Project[](existedProjectsCount);
        for(uint i = 0; i < existedProjectsCount;) {
            existedProjectsArray[i] = projectsArray[i];
            unchecked {
                ++i;
            }
        }
        return existedProjectsArray;
    }
}

interface IERC20 {
    function transferFrom(address from, address to, uint amount) external;
    function transfer(address to, uint amount) external;
    function balanceOf(address account) external view returns(uint);
}