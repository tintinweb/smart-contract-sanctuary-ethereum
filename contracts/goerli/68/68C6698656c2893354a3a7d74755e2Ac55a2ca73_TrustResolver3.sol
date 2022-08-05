// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

interface IDeployer {
    function getNations() external view returns (address[] memory);

    function getNationCount() external view returns (uint256);

    function deployNation(string memory name, string memory symbol, address citizenAlpha, address[] memory founders) external returns (address);

} 

interface INation {
    function getCitizenAlpha() external view returns (address);

    function hasRole(bytes32 role, address citizen) external view returns(bool);

    function metadata() external view returns(string memory, string memory, string memory);

    function roleStatus(bytes32 role) external view returns(bool);

    function getRoleMemberCount(bytes32 role) external view returns (uint256);

}

interface ICitizenAlpha1 {
    function ownerOf(uint256 _id) external view returns (address owner);

    function issue(address _citizen) external;

    function revoke(address _citizen) external;

    function getId(address citizen) external view returns (uint256);

    function getLink(address citizen) external view returns (address issuer);

    function hasRole(bytes32 role, address citizen) external view returns (bool);

    function isCitizen(address citizen) external view returns (bool status);

    function totalIssued() external view returns(uint256);

    function getMetadata() external view returns(address);
}


contract TrustResolver3 {

    address private immutable _deployer;

    struct NationRole {
        address nation;
        bytes32 role;
    }

    struct NationRoleMemberCount {
        bytes32 role;
        uint roleMemberCount;
    }

    struct NationDetails {
        string name;
        string symbol;
        string did;
        uint256 population;
        bytes32[] nationRoles;
        NationRoleMemberCount[] nationRoleMemberCount;
    }

    constructor(address _deployer_) {
        _deployer = _deployer_;
    }

    modifier _onlyValidNations(address _nation) {
        address[] memory nations = IDeployer(_deployer).getNations();
        uint count = nations.length;
        bool validNation = false;
        for (uint i = 0; i < count; i++){
            if (nations[i] == _nation) {
                validNation = true;
                break;
            }
        }
        require(validNation, "TrustResolver: nation does not exist");
        _;
    }

    function createNation(string memory name, string memory symbol, address[] memory founders) external returns (address) {
        address[] memory nations = IDeployer(_deployer).getNations();
        require(nations.length > 0, "First democracy should not be set from TrustResolver");
        address _citizenAlpha = INation(nations[0]).getCitizenAlpha();
        return IDeployer(_deployer).deployNation(name, symbol, _citizenAlpha, founders);
    }

    function getNationDetails(address _nation, bytes32[] memory _allRoles) public view _onlyValidNations(_nation) returns(NationDetails memory) {
        (string memory _name, string memory _symbol, string memory _did) = INation(_nation).metadata();
        address _citizenAlpha = INation(_nation).getCitizenAlpha();
        uint256 _population = ICitizenAlpha1(_citizenAlpha).totalIssued();
        bytes32[] memory _nationRoles = _getNationActiveRoles(_nation, _allRoles);
        NationRoleMemberCount[] memory _nationRolesMembersCount = getNationRolesMembersCount(_nation, _nationRoles);
        NationDetails memory nationDetails = NationDetails({name: _name, symbol: _symbol, did: _did, 
                        population: _population, nationRoles: _nationRoles, nationRoleMemberCount: _nationRolesMembersCount});
        return nationDetails;
    }

    function getNationRolesMembersCount(address _nation, bytes32[] memory _roles_) public view _onlyValidNations(_nation) returns(NationRoleMemberCount[] memory) {
        uint256 count = _roles_.length;
        NationRoleMemberCount[] memory result = new NationRoleMemberCount[](count);
        for (uint256 i=0; i<count; i++){
            bytes32 currentRole = _roles_[i];
            uint256 currentRoleMemberCount = INation(_nation).getRoleMemberCount(currentRole);
            NationRoleMemberCount memory temp = NationRoleMemberCount({role: currentRole, roleMemberCount: currentRoleMemberCount});
            result[i] = temp;
        }
        return result;
    } 

    function _getNationActiveRoles(address _nation, bytes32[] memory _allRoles) private view returns(bytes32[] memory) {
        uint allRolesCount = _allRoles.length;
        bytes32[] memory nationActiveRolesTemp = new bytes32[](allRolesCount);
        uint nationRolesCount = 0;
        for (uint256 i=0; i < allRolesCount; i++) {
            bytes32 currentRole = _allRoles[i];
            if (INation(_nation).roleStatus(currentRole)) {
                nationActiveRolesTemp[nationRolesCount] = currentRole;
                nationRolesCount++;
            }
        }
        if (nationRolesCount == 0) {
            return new bytes32[](0);
        }
        else {
            bytes32[] memory nationRoles = new bytes32[](nationRolesCount);
            for (uint256 i=0; i < nationRolesCount; i++) {
                nationRoles[i] = nationActiveRolesTemp[i];
            }
            return nationRoles;
        }
    } 

    function _getCitizenNationRoles(address citizen, address nation, bytes32[] memory _allRoles) private view returns(bytes32[] memory) {
        uint rolesCount = _allRoles.length;
        bytes32[] memory citizenRolesTemp = new bytes32[](rolesCount);
        uint256 citizenRolesCount = 0;
        for (uint256 i=0; i < rolesCount; i++) {
            bytes32 currentRole = _allRoles[i];
            if (INation(nation).hasRole(currentRole, citizen)) {
                citizenRolesTemp[citizenRolesCount] = currentRole;
                citizenRolesCount++;
            }
        }
        if (citizenRolesCount == 0) {
            return new bytes32[](0);
        }
        else {
            bytes32[] memory citizenRoles = new bytes32[](citizenRolesCount);
            for (uint256 i=0; i < citizenRolesCount; i++) {
                citizenRoles[i] = citizenRolesTemp[i];
            }
            return citizenRoles;
        }
    }

    function getCitizenNationRoles(address citizen, address nation, bytes32[] memory _allRoles) public view _onlyValidNations(nation) returns(bytes32[] memory) {
        return _getCitizenNationRoles(citizen, nation, _allRoles);
    }

    function getCitizenNationsRoles(address citizen, bytes32[] memory _allRoles) public view returns(NationRole[] memory) {
        uint nationsCount = IDeployer(_deployer).getNationCount();
        address[] memory nations = IDeployer(_deployer).getNations();
        uint rolesCount = _allRoles.length;
        NationRole[] memory resultsTemp = new NationRole[](nationsCount * rolesCount);
        uint256 count = 0;
        for (uint256 i = 0; i < nationsCount; i++) {
            address nationAddress = nations[i];
            bytes32[] memory citizenNationRolesTemp = _getCitizenNationRoles(citizen, nationAddress, _allRoles);
            for (uint256 j = 0; j < citizenNationRolesTemp.length; j++) {
                resultsTemp[count] = NationRole({nation: nationAddress, role: citizenNationRolesTemp[j]});
                count++;
            } 
        }
        if (count == 0) {
            return new NationRole[](0);
        }
        else {
            NationRole[] memory citizenNationsRoles = new NationRole[](count);
            for (uint i = 0; i < count; i ++) {
                citizenNationsRoles[i] = resultsTemp[i];
            }
            return citizenNationsRoles;
        }
    }

    function getDeployer() public view returns(address) {
        return _deployer;
    }

    function getCitizenNations(address citizen) public view returns(address[] memory) {
        uint count = IDeployer(_deployer).getNationCount();
        address[] memory citizenNationsTemp = new address[](count);
        address[] memory nations = IDeployer(_deployer).getNations();
        uint citizenNationsCount = 0;
        for (uint i = 0; i < count; i++) {
            address nationAddress = nations[i];
            if (isCitizenNation(citizen, nationAddress)) {
                citizenNationsTemp[citizenNationsCount] = nationAddress;
                citizenNationsCount++;
            }
        }
        if (citizenNationsCount == 0) {
            return new address[](0);
        }
        else {
            address[] memory citizenNations = new address[](citizenNationsCount);
            for (uint i = 0; i < citizenNationsCount; i++) {
                citizenNations[i] = citizenNationsTemp[i];
            }
            return citizenNations;
        }

    }

    function isCitizenNation(address citizen_, address nation_) public view returns(bool) {
        address citizenAlpha = INation(nation_).getCitizenAlpha();
        return ICitizenAlpha1(citizenAlpha).isCitizen(citizen_);
    }
}