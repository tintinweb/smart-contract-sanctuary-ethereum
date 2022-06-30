/**
 *Submitted for verification at Etherscan.io on 2022-06-30
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

        mapping (address => uint8) memberInfo_;
    }

    struct Project {
        string name_;
        address creator_;
        uint64 organizationId_;

        mapping (address => uint8) memberInfo_;
    }

    struct GitRef {
        bytes20 commitHash_;
        string name_;
    }
    
    struct PackedObject {
        uint8 type_;
        bytes20 hash_;
        bytes data_;
    }

    struct Meta {
        //uint64 id_;
        uint8 type_;
        bytes20 hash_;
        uint32 dataSize_;
    }

    struct Repo {
        string name_;
        address creator_;
        uint64 projectId_;
        uint64 curObjsNumber_;
        bytes32 nameHash_;

        mapping (address => uint8) memberInfo_;
        GitRef[] refs_;
        Meta[] metas_;
        mapping (bytes20 => bytes) data_;
    }
    
    mapping (uint64 => Organization) organizations_;
    mapping (uint64 => Project) projects_;
    mapping (uint64 => Repo) repos_;

    //constructor() public {}

    function createOrganization(string memory name) public {
        uint64 id = lastOrganizationId_++;
        organizations_[id].name_ = name; 
        organizations_[id].creator_ = msg.sender;
        // TODO check this
        organizations_[id].memberInfo_[msg.sender] = 1; // all permissions
    }

    function modifyOrganization(uint64 organizationId, string memory name) public {
    }

    function removeOrganzation(uint64 organizationId) public {
    }

    function createProject(string memory name, uint64 organizationId) public {
        uint64 id = lastProjectId_++;
        projects_[id].name_ = name;
        projects_[id].creator_ = msg.sender;
        projects_[id].organizationId_ = organizationId;
        // TODO check this
        projects_[id].memberInfo_[msg.sender] = 1; // all permissions
    }

    function modifyProject(string memory name, uint64 organizationId, uint64 projectId) public {
    }

    function removeProject(uint64 projectId) public {
    }

    function createRepo(string memory name, uint64 projectId) public {
        uint64 id = lastRepoId_++;
        repos_[id].name_ = name;
        repos_[id].creator_ = msg.sender;
        repos_[id].projectId_ = projectId;
        repos_[id].curObjsNumber_ = 0;
        // TODO check this
        repos_[id].memberInfo_[msg.sender] = 1; // all permissions
    }

    function modifyRepo(string memory name, uint64 repoId) public {
    }

    function removeRepo(uint64 repoId) public {
    }

    //

    function pushRefs(uint64 repoId, GitRef[] memory refs) public {
        // TODO check permissions
        for (uint i = 0; i < refs.length; i++) {
            repos_[repoId].refs_.push(refs[i]);
        }
    }

    function pushObjects(uint64 repoId, PackedObject[] memory objects) public {
        // TODO check permissions
        for (uint i = 0; i < objects.length; i++) {
            Meta memory meta;

            meta.type_ = objects[i].type_;
            meta.hash_ = objects[i].hash_;
            meta.dataSize_ = uint32(objects[i].data_.length);

            repos_[repoId].metas_.push(meta);

            repos_[repoId].data_[objects[i].hash_] = objects[i].data_;
        }
    }

    // Repo member

    function addRepoMember(uint64 repoId, address member, uint8 permissions) public {}

    function modifyRepoMember(uint64 repoId, address member, uint8 permissions) public {}

    function removeRepoMeber(uint64 repoId, address member) public {}

    // project member

    function addProjectMember(uint64 projectId, address member, uint8 permissions) public {}

    function modifyProjectMember(uint64 projectId, address member, uint8 permissions) public {}

    function removeProjectMember(uint64 projectId, address member) public {}

    // organization member
    function addOrganizationMember(uint64 organizationId, address member, uint8 permissions) public {}

    function modifyOrganizationMember(uint64 organizationId, address member, uint8 permissions) public {}

    function removeOrganizationMember(uint64 organizationId, address member) public {}

    /////////////////////////////////////////////////////////////////
    function myRepos() public view {} //id, name of each repo

    function allRepos() public view {} //id, name, projectId, curObjects, repoOwner of each repo

    function refsList(uint64 repoId) public view returns (GitRef[] memory) {
        return repos_[repoId].refs_;
    } //name, commitHash

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

    function getRepoData(uint64 repoId, bytes20 objHash) public view returns (bytes memory) {
        return repos_[repoId].data_[objHash];
    }

    function getRepoMeta(uint64 repoId) public view returns (Meta[] memory) {
        return repos_[repoId].metas_;
    }

    function getCommits(uint64 repoId) public view {} // hash, size, type

    function getTrees(uint64 repoId) public view {} // hash, size, type

    function getProjectsList() public view returns (uint64[] memory ids, uint64[] memory orgIds, string[] memory names, address[] memory creators) {
        ids = new uint64[](lastProjectId_ - 1);
        orgIds = new uint64[](lastProjectId_ - 1);
        names = new string[](lastProjectId_ - 1);
        creators = new address[](lastProjectId_ - 1);
        for (uint64 i = 1; i < lastProjectId_; i++) {
            ids[i - 1] = i;
            orgIds[i - 1] = projects_[i].organizationId_;
            names[i - 1] = projects_[i].name_;
            creators[i - 1] = projects_[i].creator_;
        }
    } //id, organizationId, name, creator

    function getProjectReposList(uint64 projectId) public view {} // id, name, curObjects, creator or owner?

    function getProjectMembersList(uint64 projectId) public view {} // address, permissions

    function getOrganizationsList() public view returns (uint64[] memory ids, string[] memory names, address[] memory creators) {
        // TODO calculate count of organization and use instead of lastOrganizationId_ below
        ids = new uint64[](lastOrganizationId_ - 1);
        names = new string[](lastOrganizationId_ - 1);
        creators = new address[](lastOrganizationId_ - 1);
        for (uint64 i = 1; i < lastOrganizationId_; i++) {
            ids[i - 1] = i;
            names[i - 1] = organizations_[i].name_;
            creators[i - 1] = organizations_[i].creator_;
        }
    } // id, name, creator

    function getOrganizationProjectsList(uint64 organizationId) public view {} // id, name, creator

    function getOrganizationMembersList(uint64 organizationId) public view {} // address, permissions

    function isStringEqual(string memory first,string memory second) view public returns (bool) {
        return (keccak256(bytes(first)) == keccak256(bytes(second)));
    }
}