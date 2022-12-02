// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./Ownable.sol";

contract Marketplace is Ownable {

    address OIL_CONTRACT = 0xf369eea446aBCE1AE5f1Eb41B58F5e1F7aDb11C2;

    IERC20 public OIL = IERC20(OIL_CONTRACT);

    struct Project {
        uint id;
        uint cost;
        uint qty;
        bool filled;
        uint publishAt;
        uint[] entries;
        uint total;
    }
    
    modifier onlyAdmin {
         require(checkAdmin(_msgSender()), "Only admins");
         _;
    }

    // if the marketplace is down
    bool public marketplaceActive = true;

    // if the contract is initialized
    bool public initialized = false;

    // holds a mapping between projects ids and their references
    mapping(uint => Project) public projects;

    // holds a mapping between the addresses and the projects entries for fast query
    mapping(address => uint[]) private addressesProjectEntries;

    // admins for the marketplace
    mapping(address => bool) admins;

    /********************************************
                OWNER FUNCTIONS
     ********************************************/
    function setAdmin(address addy, bool isAdmin) public onlyOwner {
        admins[addy] = isAdmin;
    }

    function setOilContract(address oilContract) public onlyOwner {
        OIL_CONTRACT = oilContract;
        OIL = IERC20(OIL_CONTRACT);
    }

    function setMarketplaceActive(bool active) public onlyOwner {
        marketplaceActive = active;
    }

    function initialize() external {
         require(!initialized, "Already initialized");
        _transferOwnership(_msgSender());
    }

    function setInitialized(bool _initialized) public onlyOwner {
        initialized = _initialized;
    }

    /********************************************
                    ADMIN FUNCTIONS
     ********************************************/
    function addProject(uint projectId, uint cost, uint qty) public payable onlyAdmin {
        addProject(projectId, cost, qty, block.timestamp);
    }

    function addProject(uint projectId, uint cost, uint qty, uint publishAt) public payable onlyAdmin {

        // project ID should be > 0
        require(projectId > 0, "Project ID can not be 0");

        // make sure project ID is unique
        require(!isProjectExists(projectId), "Project ID already being used");

         // validate the project
        validateProject(qty, publishAt);

        Project memory project = projects[projectId];

        // add the project to the map
        project.id = projectId;
        project.cost = cost;
        project.qty = qty;
        project.publishAt = publishAt;

        projects[projectId] = project;

        // TODO emit event
    }
    
    function validateProject(uint qty, uint publishAt) private view {
        require(qty > 0, "Quantity can not be 0");
        require(publishAt >= block.timestamp, "Publish at must be in future");
    }

    function updateProject(uint projectId, uint cost, uint qty, bool filled, uint publishAt) public payable onlyAdmin {

        requireProjectExists(projectId);
        Project storage project = projects[projectId];

        // validate the quantity
        require(qty > 0, "Quantity can not be 0");

        if ( project.cost != cost)
            project.cost = cost;

        if ( project.qty != qty)
            project.qty = qty;

        if ( project.filled != filled)
            project.filled = filled;

        if ( project.publishAt != publishAt)
            project.publishAt = publishAt;
    }

    /********************************************
                    USERS FUNCTIONS
     ********************************************/

    function addProjectEntry(uint projectId, uint referenceId) public payable {

        require(marketplaceActive, "Marketplace is currently offline, try again later!");

        requireProjectExists(projectId);
        
        Project storage project = projects[projectId];

        // validate the input
        validateEntry(project);

        // get the value only once
        address sender = _msgSender();

        // make sure wallet has enough $OIL
        require(OIL.balanceOf(sender) >= project.cost, "Not enough $OIL balance");

        // transfer OIL to OIL contract
        OIL.transferFrom(sender, OIL_CONTRACT, project.cost); // TODO transfer to this contract ?

        //TODO: BURN $OIL ?

        // add the entry to the entries list
        project.entries.push(referenceId);

        project.total += 1;

        // add the entry to the addesses-project entries map
        addressesProjectEntries[sender].push(projectId);

        // TODO emit event
    }

    function validateEntry(Project memory project) internal view {
        require(!project.filled, "Sold out");
        require(project.entries.length + 1 <= project.qty , "Sold out");
        require(block.timestamp >= project.publishAt, "Project isn't active yet");
    }

    /********************************************
                    COMMON FUNCTIONS
     ********************************************/

    function checkAdmin(address addy) public view returns (bool) {
        return admins[addy] || addy == owner();
    }

    function isProjectExists(uint id) public view returns (bool) {
       return projects[id].id > 0;
    }

    function getProjectEntries(uint projectId) public view returns (uint[] memory) {
        requireProjectExists(projectId);
        return projects[projectId].entries;
    }

    function requireProjectExists(uint projectId) private view {
        require(isProjectExists(projectId), "Project doesn't exist");
    }

    function getAddressProjectsEntries(address addy) public view returns (uint[] memory) {
        return addressesProjectEntries[addy];
    }

    function isAddressHasProjectEntry(address addy, uint projectId) public view returns (bool) {
        
        requireProjectExists(projectId);

        return getAddressProjectsEntries(addy)[projectId] > 0;
    }

    function getProjects(uint[] calldata projectsIds) public view returns (Project[] memory) {
        
        Project[] memory projectsArray = new Project[](projectsIds.length);
        uint existedProjectsCount = 0;

        for(uint i = 0; i < projectsIds.length;) {
            uint projectId = projectsIds[i];
            if ( isProjectExists(projectId) ) {
                projectsArray[existedProjectsCount] = projects[projectId]; 
                existedProjectsCount += 1;
            }
            unchecked {
                i++;
            }
        }

        Project[] memory existedProjectsArray = new Project[](existedProjectsCount);
        for(uint i = 0; i < existedProjectsCount;) {
            existedProjectsArray[i] = projectsArray[i];
            unchecked {
                    i++;
                }
        }
        return existedProjectsArray;
    }
}

interface IERC20{
    function transferFrom(address from, address to, uint amount) external;
    function transfer(address to, uint amount) external;
    function balanceOf(address account) external view returns(uint);
}