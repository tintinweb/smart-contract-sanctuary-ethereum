/**
 *Submitted for verification at Etherscan.io on 2022-07-21
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

contract Sourc3 {
    uint64 lastRepoId_ = 1;
    uint64 lastOrganizationId_ = 1;
    uint64 lastProjectId_ = 1;

    struct Organization {
        string name_;
        address creator_;
        uint64 projectsNumber_;

        mapping (address => uint8) memberInfo_;
    }

    struct Project {
        string name_;
        address creator_;
        uint64 organizationId_;
        uint64 reposNumber_;

        mapping (address => uint8) memberInfo_;
    }

    struct Repo {
        string name_;
        address creator_;
        uint64 projectId_;
        uint64 curObjsNumber_;
        uint64 curMetasNumber_;
        bytes32 nameHash_;
        string state_;

        mapping (address => uint8) memberInfo_;
    }

    uint64 organizationsNumber_ = 0;
    uint64 projectsNumber_ = 0;
    uint64 reposNumber_ = 0;
    
    mapping (uint64 => Organization) organizations_;
    mapping (uint64 => Project) projects_;
    mapping (uint64 => Repo) repos_;

    function createOrganization(string memory name) public {
        // TODO maybe check organization name
        uint64 id = lastOrganizationId_++;
        organizations_[id].name_ = name; 
        organizations_[id].creator_ = msg.sender;
        // TODO check this
        organizations_[id].memberInfo_[msg.sender] = 1; // all permissions

        organizationsNumber_++;
    }

    function modifyOrganization(uint64 organizationId, string memory name) public {
        require(organizationId < lastOrganizationId_ && organizations_[organizationId].creator_ != address(0), "Unknown organization");
        // TODO check permissions
        organizations_[organizationId].name_ = name;
    }

    function removeOrganization(uint64 organizationId) public {
        require(organizationId < lastOrganizationId_ && organizations_[organizationId].creator_ != address(0), "Unknown organization");
        // TODO check permissions
        require(organizations_[organizationId].projectsNumber_ == 0);
        delete organizations_[organizationId];
        organizationsNumber_--;
    }

    function createProject(string memory name, uint64 organizationId) public {
        require(organizationId < lastOrganizationId_ && organizations_[organizationId].creator_ != address(0), "Organization should be specified");
        uint64 id = lastProjectId_++;
        projects_[id].name_ = name;
        projects_[id].creator_ = msg.sender;
        projects_[id].organizationId_ = organizationId;
        // TODO check this
        projects_[id].memberInfo_[msg.sender] = 1; // all permissions

        projectsNumber_++;
        organizations_[organizationId].projectsNumber_++;
    }

    function modifyProject(uint64 projectId, string memory name) public {
        require(projectId < lastProjectId_ && projects_[projectId].creator_ != address(0), "Unknown project");
        // TODO check permissions
        projects_[projectId].name_ = name;
    }

    function removeProject(uint64 projectId) public {
        require(projectId < lastProjectId_ && projects_[projectId].creator_ != address(0), "Unknown project");
        // TODO check permissions
        require(projects_[projectId].reposNumber_ == 0);
        // TODO check order of commands
        organizations_[projects_[projectId].organizationId_].projectsNumber_--;
        delete projects_[projectId];
        projectsNumber_--;
    }

    function createRepo(string memory name, uint64 projectId) public {
        require(projectId < lastProjectId_ && projects_[projectId].creator_ != address(0), "Project should be specified");
        uint64 id = lastRepoId_++;
        repos_[id].name_ = name;
        repos_[id].creator_ = msg.sender;
        repos_[id].projectId_ = projectId;
        repos_[id].curObjsNumber_ = 0;
        // TODO check this
        repos_[id].memberInfo_[msg.sender] = 1; // all permissions

        reposNumber_++;
        projects_[projectId].reposNumber_++;
    }

    function modifyRepo(uint64 repoId, string memory name) public {
        require(repoId < lastRepoId_ && repos_[repoId].creator_ != address(0), "Unknown repository");
        // TODO check permissions
        repos_[repoId].name_ = name;
    }

    function removeRepo(uint64 repoId) public {
        require(repoId < lastRepoId_ && repos_[repoId].creator_ != address(0), "Unknown repository");
        // TODO check permissions
        // TODO check order of commands
        projects_[repos_[repoId].projectId_].reposNumber_--;
        delete repos_[repoId];
        reposNumber_--;
    }

    //

    function pushState(uint64 repoId, uint64 objsCount, uint64 metasCount, string memory expectedState, string memory state) public {
        // require(repoId < lastRepoId_ && repos_[repoId].projectId_ > 1);
        // TODO check permissions
        // require(isStringEqual(expectedState, repos_[repoId].state_));
        repos_[repoId].curObjsNumber_ += objsCount;
        repos_[repoId].curMetasNumber_ += metasCount;
        repos_[repoId].state_ = state;
    }

    function loadState(uint64 repoId) view public returns (string memory state, uint64 curObjects, uint64 curMetas) {
        // require(repoId < lastRepoId_ && repos_[repoId].projectId_ > 1);
        state = repos_[repoId].state_;
        curObjects = repos_[repoId].curObjsNumber_;
        curMetas = repos_[repoId].curMetasNumber_;
    }

    // Repo member

    function addRepoMember(uint64 repoId, address member, uint8 permissions) public {
        require(repoId < lastRepoId_ && repos_[repoId].projectId_ > 1);
        // TODO check permissions
        require(repos_[repoId].memberInfo_[member] == 0);
        repos_[repoId].memberInfo_[member] = permissions;
    }

    function modifyRepoMember(uint64 repoId, address member, uint8 permissions) public {
        require(repoId < lastRepoId_ && repos_[repoId].projectId_ > 1);
        // TODO check permissions
        require(repos_[repoId].memberInfo_[member] != 0);
        repos_[repoId].memberInfo_[member] = permissions;
    }

    function removeRepoMeber(uint64 repoId, address member) public {
        require(repoId < lastRepoId_ && repos_[repoId].projectId_ > 1);
        // TODO check permissions
        require(repos_[repoId].memberInfo_[member] != 0);
        delete repos_[repoId].memberInfo_[member];
    }

    // project member

    function addProjectMember(uint64 projectId, address member, uint8 permissions) public {
        require(projectId < lastRepoId_ && projects_[projectId].organizationId_ > 0);
        // TODO check permissions
        require(projects_[projectId].memberInfo_[member] == 0);
        projects_[projectId].memberInfo_[member] = permissions;
    }

    function modifyProjectMember(uint64 projectId, address member, uint8 permissions) public {
        require(projectId < lastRepoId_ && projects_[projectId].organizationId_ > 0);
        // TODO check permissions
        require(projects_[projectId].memberInfo_[member] != 0);
        projects_[projectId].memberInfo_[member] = permissions;
    }

    function removeProjectMember(uint64 projectId, address member) public {
        require(projectId < lastRepoId_ && projects_[projectId].organizationId_ > 0);
        // TODO check permissions
        require(projects_[projectId].memberInfo_[member] != 0);
        delete projects_[projectId].memberInfo_[member];
    }

    // organization member
    function addOrganizationMember(uint64 organizationId, address member, uint8 permissions) public {
        require(organizationId < lastOrganizationId_ && organizations_[organizationId].creator_ != address(0));
        // TODO check permissions
        require( organizations_[organizationId].memberInfo_[member] == 0);
        organizations_[organizationId].memberInfo_[member] = permissions;
    }

    function modifyOrganizationMember(uint64 organizationId, address member, uint8 permissions) public {
        require(organizationId < lastOrganizationId_ && organizations_[organizationId].creator_ != address(0));
        // TODO check permissions
        require( organizations_[organizationId].memberInfo_[member] != 0);
        organizations_[organizationId].memberInfo_[member] = permissions;
    }

    function removeOrganizationMember(uint64 organizationId, address member) public {
        require(organizationId < lastOrganizationId_ && organizations_[organizationId].creator_ != address(0));
        // TODO check permissions
        require( organizations_[organizationId].memberInfo_[member] == 0);
        delete organizations_[organizationId].memberInfo_[member];
    }

    /////////////////////////////////////////////////////////////////
    function getMyRepos() public view returns (uint64[] memory ids, string[] memory names) {
        uint64 count = 0;
        for (uint64 i = 1; i < lastRepoId_; i++) {
            if (repos_[i].creator_ == msg.sender) {
                count++;
            }
        }

        ids = new uint64[](count);
        names = new string[](count);
        uint j = 0;
        for (uint64 i = 1; i < lastRepoId_; i++) {
            if (repos_[i].creator_ == msg.sender) {
                ids[j] = i;
                names[j] = repos_[i].name_;
                ++j;
            }
        }
    }

    function getReposList() public view returns (uint64[] memory ids, string[] memory names, uint64[] memory projectIds, uint64[] memory curObjcts, address[] memory creators) {
        ids = new uint64[](reposNumber_);
        names = new string[](reposNumber_);
        projectIds = new uint64[](reposNumber_);
        curObjcts = new uint64[](reposNumber_);
        creators = new address[](reposNumber_);

        uint64 j = 0;
        for (uint64 i = 1; i < lastRepoId_; i++) {
            if (repos_[i].creator_ != address(0)) {
                ids[j] = i;
                names[j] = repos_[i].name_;
                projectIds[j] = repos_[i].projectId_;
                curObjcts[j] = repos_[i].curObjsNumber_;
                creators[j] = repos_[i].creator_;
                j++;
            }
        }
    }

    function getRepo(uint64 id) public view returns (string memory, address, uint64, uint64, uint64, string memory) {
        require(id < lastRepoId_ && repos_[id].creator_ != address(0));

        return (repos_[id].name_, repos_[id].creator_, repos_[id].projectId_, repos_[id].curObjsNumber_, repos_[id].curMetasNumber_, repos_[id].state_);
    }

    function getProject(uint64 id) public view returns (string memory, address, uint64) {
        require(id < lastProjectId_ && projects_[id].creator_ != address(0));

        return (projects_[id].name_, projects_[id].creator_, projects_[id].organizationId_);
    }

    function getOrganization(uint64 id) public view returns (string memory, address) {
        require(id < lastOrganizationId_ && organizations_[id].creator_ != address(0));

        return (organizations_[id].name_, organizations_[id].creator_);
    }

    function getRepoId(address owner, string memory name) public view returns (uint64) {
        for (uint64 id = 1; id < lastRepoId_; id++) {
            if (repos_[id].creator_ == owner && isStringEqual(repos_[id].name_, name)) {
                return id;
            }
        }
        return 0;
    }

    function getProjectId(address owner, string memory name) public view returns (uint64) {
        for (uint64 id = 1; id < lastProjectId_; id++) {
            if (projects_[id].creator_ == owner && isStringEqual(projects_[id].name_, name)) {
                return id;
            }
        }
        return 0;
    }

    function getOrganizationId(address owner, string memory name) public view returns (uint64) {
        for (uint64 id = 1; id < lastOrganizationId_; id++) {
            if (organizations_[id].creator_ == owner && isStringEqual(organizations_[id].name_, name)) {
                return id;
            }
        }
        return 0;
    }

    function getProjectsList() public view returns (uint64[] memory ids, uint64[] memory orgIds, string[] memory names, address[] memory creators) {
        ids = new uint64[](projectsNumber_);
        orgIds = new uint64[](projectsNumber_);
        names = new string[](projectsNumber_);
        creators = new address[](projectsNumber_);

        uint64 j = 0;
        for (uint64 i = 1; i < lastProjectId_; i++) {
            if (projects_[i].creator_ != address(0)) {
                ids[j] = i;
                orgIds[j] = projects_[i].organizationId_;
                names[j] = projects_[i].name_;
                creators[j] = projects_[i].creator_;
                j++;
            }
        }
    }

    function getReposListOfProject(uint64 projectId) public view returns (uint64[] memory ids, string[] memory names, uint64[] memory curObjsNumbers, uint64[] memory curMetasNumbers, address[] memory creators) {
        require(projectId < lastProjectId_ && projects_[projectId].creator_ != address(0));
        ids = new uint64[](projects_[projectId].reposNumber_);
        names = new string[](projects_[projectId].reposNumber_);
        curObjsNumbers = new uint64[](projects_[projectId].reposNumber_);
        curMetasNumbers = new uint64[](projects_[projectId].reposNumber_);
        creators = new address[](projects_[projectId].reposNumber_);

        uint64 j = 0;
        for (uint64 i = 1; i < lastRepoId_; i++) {
            if (repos_[i].projectId_ == projectId) {
                ids[j] = i;
                names[j] = repos_[i].name_;
                curObjsNumbers[j] = repos_[i].curObjsNumber_;
                curMetasNumbers[j] = repos_[i].curMetasNumber_;
                creators[j] = repos_[i].creator_;
                j++;
            }
        }
    }

    function getMembersListOfProject(uint64 projectId) public view {} // address, permissions

    function getOrganizationsList() public view returns (uint64[] memory ids, string[] memory names, address[] memory creators) {
        ids = new uint64[](organizationsNumber_);
        names = new string[](organizationsNumber_);
        creators = new address[](organizationsNumber_);
        uint64 j = 0;
        for (uint64 i = 1; i < lastOrganizationId_; i++) {
            if (organizations_[i].creator_ != address(0)) {
                ids[j] = i;
                names[j] = organizations_[i].name_;
                creators[j] = organizations_[i].creator_;
                j++;
            }
        }
    }

    function getProjectsListOfOrganization(uint64 organizationId) public view returns (uint64[] memory ids, string[] memory names, address[] memory creators) {
        require(organizationId < lastOrganizationId_ && organizations_[organizationId].creator_ != address(0));
        ids = new uint64[](organizations_[organizationId].projectsNumber_);
        names = new string[](organizations_[organizationId].projectsNumber_);
        creators = new address[](organizations_[organizationId].projectsNumber_);

        uint64 j = 0;
        for (uint64 i = 1; i < lastProjectId_; i++) {
            if (projects_[i].organizationId_ == organizationId) {
                ids[j] = i;
                names[j] = organizations_[i].name_;
                creators[j] = organizations_[i].creator_;
                j++;
            }
        }
    }

    function getMembersListOfOrganization(uint64 organizationId) public view {} // address, permissions

    function isStringEqual(string memory first,string memory second) private pure returns (bool) {
        return (keccak256(bytes(first)) == keccak256(bytes(second)));
    }
}