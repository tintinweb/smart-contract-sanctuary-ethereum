/**
 *Submitted for verification at Etherscan.io on 2022-07-27
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

interface IDeployer {
    function getNations() external view returns (address[] memory);

    function getNationCount() external view returns (uint256);
} 

interface INation {
    function getCitizenAlpha() external view returns (address);
}

interface ICitizenAlpha1 {
    function ownerOf(uint256 _id) external view returns (address owner);

    function issue(address _citizen) external;

    function revoke(address _citizen) external;

    function getId(address citizen) external view returns (uint256);

    function getLink(address citizen) external view returns (address issuer);

    function hasRole(bytes32 role, address citizen) external view returns (bool);

    function isCitizen(address citizen) external view returns (bool status);
}


contract TrustResolver1 {

    address private immutable _deployer;

    constructor(address _deployer_) {
        _deployer = _deployer_;
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