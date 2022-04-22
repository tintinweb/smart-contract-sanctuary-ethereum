// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @dev All function calls are currently implemented without side effects
contract AccessControl {

     /** 
     @param role Admin right to be granted
     @param account acoount given admin right
    */
    event GrantRoles(bytes32 indexed role, address indexed account);
    event RemoveRoles(bytes32 indexed role, address indexed account);

    mapping(bytes32 => mapping(address => bool)) public roles;
    
    /// @dev Generates an hash for the Chairman
    //0x76dfba581cd3b5e02cf3469ec59636d3b2bc677066188c2346f32f81a159710
    bytes32 public constant Chairman = keccak256("Chairman");
    
    /// @dev Generates an hash for the Board
    // 0x440f0b4326c1ea763c9f96608623635c8105d5cc0e4b4f20a4e4fe0546b15eeb
    bytes32 public constant Board = keccak256("Board of directors");

    /// @dev Generates an hash for the Teachers
    // 0x24428a7c8016b6f2b3148e1c17f4bed00ad0f5ab53b599683050e4e0aced359b
    bytes32 public constant Teachers = keccak256("Teachers");

    /// @dev Generates an hash for the Students
    // 0x6d7942b32c5633723435ccc7414ccb4e054f91ce4a595460bedf2f56bb0f5a5a
    bytes32 public constant Students = keccak256("Students");

    /// @dev allows execution by the owner only
    modifier onlyRole(bytes32 _role) {
        require(roles[_role][msg.sender], "not authorized");
        _;
    }

    modifier isChairOrTeach() {
        require(roles[Chairman][msg.sender] || roles[Teachers][msg.sender]);
        _;
    }


    /// @notice admin rights are given to the deployer address
    constructor() {
        _grantRole(Chairman, msg.sender);
    }

    /// @notice Internal function for granting roles
    function _grantRole(bytes32 _role, address _account) internal {
        roles[_role][_account] = true; // grant role to the inputed address
        emit GrantRoles(_role, _account);

    }

    /**
     *  @dev Granting an address certain rights.
     *  @param _account  address to be granted _role rights.
     *  @param _role hash for role.
     */
    function grantRole(bytes32 _role, address _account) external onlyRole(Chairman) {
        _grantRole(_role, _account);
    }

    /// @dev verify if an address has chairman rights
    function isChairman(address _address) public view returns (bool) {
        return roles[Chairman][_address];
    }

    /// @dev verify if an address has Board member rights
    function isBoard(address _address) public view returns (bool) {
        return roles[Board][_address];
    }

    /// @dev verify if an address has Teachers rights
    function isTeacher(address _address) public view returns (bool) {
        return roles[Teachers][_address];
    }

    /// @dev verify if an address is a student 
    function isStudent(address _address) public view returns (bool) {
        return roles[Students][_address];
    }
    /// @notice verify if an address is an admin
    function getUserRole(address _address) public view returns (string memory) {
        if (roles[Chairman][_address]) return "Chairman";

        if (roles[Board][_address]) return "Board";

        if (roles[Teachers][_address]) return "Teachers";

        if (roles[Students][_address]) return "Students";
        return "not registered";
    }

    /** 
        @dev allows removal of roles 
        can only be called by the contract owner
        @param _account   address to be removed 
        @param _role hash for role
*/
    function removeRole(bytes32 _role, address _account) external onlyRole(Chairman) {
        roles[_role][_account] = false; // remove role to the inputed address
        emit RemoveRoles(_role, _account);
    }

}