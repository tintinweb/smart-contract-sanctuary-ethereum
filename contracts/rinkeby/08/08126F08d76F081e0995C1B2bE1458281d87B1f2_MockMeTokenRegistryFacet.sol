// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

contract MockMeTokenRegistryFacet {
    mapping(address => address) public meTokenOwners;

    // all params kept from original MeTokenRegistry so that tests
    // using the registry vs. mock keep the same arguments
    function subscribe(
        string calldata, /* name */
        string calldata, /* symbol */
        uint256, /* hubId */
        uint256 /* assetsDeposited */
    ) external {
        meTokenOwners[msg.sender] = address(this);
    }

    function isOwner(address _owner) external view returns (bool) {
        return meTokenOwners[_owner] != address(0);
    }
}