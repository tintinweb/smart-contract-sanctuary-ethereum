/**
 *Submitted for verification at Etherscan.io on 2023-01-19
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7;

// Created AccessControl contract which will be inherited later by Leaderboard
contract AccessControl {
    // indexing allows us to filter through the logs faster
    event GrantRole(bytes32 indexed role, address indexed account);
    event RevokeRole(bytes32 indexed role, address indexed account);

    mapping(bytes32 => mapping(address => bool)) public roles;

    // private is cheaper, but public allows us to see the hash for the role
    bytes32 public constant ADMIN = keccak256(abi.encodePacked("ADMIN"));

    // owner gets the ADMIN role
    constructor() {
        _grantRole(ADMIN, msg.sender);
    }

    // if a contract inherits AccessControl, it will be able to call _grantRole (internal)
    function _grantRole(bytes32 _role, address _account) internal {
        // roles[_role] returns mapping(address => bool)
        // and if we access that one:
        // roles[_role][_account], we will get access to the boolean
        roles[_role][_account] = true;
        emit GrantRole(_role, _account);
    }

    function hasRole(bytes32 _role, address _account)
        public
        view
        virtual
        returns (bool)
    {
        return roles[_role][_account];
    }

    function bytes32ToStr(bytes32 _bytes32)
        public
        pure
        returns (string memory resultingString)
    {
        uint8 i = 0;
        uint8 j;
        while (i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (j = 0; j < i; j++) {
            bytesArray[j] = _bytes32[j];
        }
        return string(bytesArray);
    }

    modifier onlyRole(bytes32 _role) {
        require(roles[_role][msg.sender], "Unauthorized: Role not present");
        if (!hasRole(_role, msg.sender)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: missing role",
                        bytes32ToStr(_role)
                    )
                )
            );
        }
        _;
    }

    function grantRole(bytes32 _role, address _account)
        external
        onlyRole(ADMIN)
    {
        _grantRole(_role, _account);
    }

    function revokeRole(bytes32 _role, address _account)
        external
        onlyRole(ADMIN)
    {
        roles[_role][_account] = false;
        emit RevokeRole(_role, _account);
    }
}