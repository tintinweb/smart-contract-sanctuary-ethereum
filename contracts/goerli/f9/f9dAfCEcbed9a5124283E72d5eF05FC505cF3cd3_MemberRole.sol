// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract MemberRole {
    /** Admin address */
    address owner;

    /**
    Struct defining the role for members of the community
    activationTime - The timestamp from which the role will be enabled
    isActive - if a role is active or not
    roleType - the role type through this custom business logic can be built
    */
    struct Role {
        uint256 activationTime;
        bool isActive;
        string roleType;
    }

    /** Dynamic array holding all the roles */
    string[] public roleTypes;

    /** Dynamic array holding users addresses */
    address[] public addresses;
    /** Relationship between users and their role */
    mapping(address => Role) public userRole;

    /** Total count of users that have a role */
    uint256 public membersCount;
    /** Total count of Jur Role Types **/
    uint256 public roleTypesCount;

    event StateChanged(address member, bool newRole, uint256 timestamp);
    event RoleAdded(address member, uint256 activationTime, string roleType);

    modifier onlyOwner() {
        require(msg.sender == owner, "Access not granted.");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    /**
    @dev addRole - allows Admin to assign a Role to a Member
    @param _member - the address of the member that will get the new role assigned
    @param _roleType - index of the role in the roleTypes array
    */
    function addRole(address _member, uint256 _roleType) public onlyOwner {
        require(_member != address(0), "Please provide a valid address.");
        userRole[_member] = Role(block.timestamp, true, roleTypes[_roleType]);
        addresses.push(_member);
        membersCount++;

        emit RoleAdded(_member, block.timestamp, roleTypes[_roleType]);
    }

    /**
    @dev changeRoleStatus - allows Admin to change the status of a Member
    @param _member - the address of the member whose status will toggle
    @param _newState -  activate or disable the role
    */
    function changeRoleStatus(address _member, bool _newState)
        public
        onlyOwner
    {
        require(_member != address(0), "Pleae provide a valid address.");
        require(
            userRole[_member].activationTime != 0,
            "This address is not a valid member"
        );
        require(
            userRole[_member].isActive != _newState,
            "The member is already in this state"
        );
        userRole[_member].isActive = _newState;

        emit StateChanged(_member, _newState, block.timestamp);
    }

    /**
    @dev addRoleType - allows Admin to add a new role that can be assigned to members
    logic.
    @param _roleType - the name for the new role
    */
    function addRoleType(string memory _roleType) public onlyOwner {
        require(
            bytes(_roleType).length != 0,
            "The name for the role cannot be blank"
        );
        roleTypesCount++;
        roleTypes.push(_roleType);
    }
}