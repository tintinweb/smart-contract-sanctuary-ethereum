pragma solidity ^0.8.9;

contract Project {
    struct ProjectObj {
        uint id;
        uint userID;
        string name;
    }

    ProjectObj[] public projectsArray;

    mapping(uint => ProjectObj) public projectsMap;

    uint id = 1;

    function createProject(uint userID, string memory name) public {
        // Create new project object
        ProjectObj memory project = ProjectObj({id:id, userID:userID, name: name});

        // Add project to array
        projectsArray.push(project);

        // Add project to map
        projectsMap[id] = project;

        // Increment project ID
        id = id + 1;
    }

    function getProjects() public view returns(ProjectObj [] memory) {
        ProjectObj[] memory projects = new ProjectObj[](projectsArray.length);
        for (uint i = 0; i < projectsArray.length; i++) {
          ProjectObj storage project = projectsArray[i];
          projects[i] = project;
        }
        return projects;
    }

    function getProjectOwner(uint projectID) public view returns(uint) {
        return projectsMap[projectID].userID;
    }

    function getUserCreatedProjects(uint userID) public view returns(uint [] memory) {
        uint count = 0;

        for (uint i = 0; i < projectsArray.length; i++) {
            if (projectsArray[i].userID == userID) {
                count = count + 1;
            }
        }

        uint[] memory projectIDs = new uint[](count);
        uint tracker = 0;
        for (uint i = 0; i < projectsArray.length; i++) {
            if (projectsArray[i].userID == userID) {
                projectIDs[tracker] = i + 1;
                tracker = tracker + 1;
            }
        }

        return projectIDs;
    }
}