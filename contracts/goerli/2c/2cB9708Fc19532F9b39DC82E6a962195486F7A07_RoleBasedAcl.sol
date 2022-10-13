//SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;


/**
 * @title RoleBasedAcl (Roles-based access control)
 * @dev Contract managing addressed role based access control
 */

contract RoleBasedAcl {
    enum Roles {SUPER_ADMIN, NOTARY, LAST_INDEX} //SUPER_ADMIN: 0, NOTARY: 1, LAST: number value of enum
    mapping(address => mapping(uint8 => bool)) roles; //address => Role(uint8) => bool
    // For read all user role in contract
    address[] public userAddress;
    mapping(address => uint256) public userAddressIndexes;
    // event add and remove role
    event RoleAdded(address indexed account, Roles role);
    event RoleRemoved(address indexed account, Roles role);

    constructor() public {
        roles[msg.sender][0] = true; // set deployer is 'superadmin'
    }

    /**
     * @notice Assign a role to address
     * @dev require msg.sender is superadmin && account is empty role
     * @param _account address
     * @param _role the name of the role
     */
    function addRole(address _account, Roles _role)
        external
        onlyRole(0)
        emptyRole(_account)
    {
        roles[_account][uint8(_role)] = true;
        uint256 id = userAddress.length;
        userAddressIndexes[_account] = id;
        userAddress.push(_account);
        emit RoleAdded(_account, _role);
    }

    /**
     * @notice remove a role from an address
     * @dev require msg.sender = superadmin
     * @param _account address
     * @param _role the name of the role
     */
    function removeRole(address _account, Roles _role) external onlyRole(0) {
        require(
            _account != msg.sender,
            "Roles: Unable to remove superadmin role itself"
        );
        require(
            hasRole(_account, uint8(_role)),
            "Roles: Account doesn't have role"
        );
        roles[_account][uint8(_role)] = false;
        uint256 id = userAddressIndexes[_account];
        for (uint256 i = id; i < userAddress.length - 1; i++) {
            userAddress[i] = userAddress[i + 1];
            userAddressIndexes[userAddress[i]] = i;
        }
        userAddress.pop();
        emit RoleRemoved(_account, _role);
    }

    /**
     * @dev determine if addr has role
     * @param _account address
     * @param _role the name of the role
     * @return bool
     */
    function hasRole(address _account, uint8 _role) public view returns (bool) {
        require(_account != address(0), "Roles: account is the zero address");
        return roles[_account][_role];
    }

    /**
     * @dev modifier to scope access to a single role (uses msg.sender as addr)
     * @param _role the name of the role
     */
    modifier onlyRole(uint8 _role) {
        require(hasRole(msg.sender, _role), "Roles: Account not allowed");
        _;
    }

    modifier emptyRole(address _address) {
        require(
            !hasRole(_address, 0) && !hasRole(_address, 1),
            "Roles: An account should have only one role"
        );
        _;
    }

    /**
     * @notice Get list user and role
     * @return address[], uint8[]
     */
    function getAllAddressAndRole()
        external
        view
        returns (address[] memory, uint8[] memory)
    {
        uint8[] memory listRole = new uint8[](userAddress.length);
        uint256 amountRoles = uint8(Roles.LAST_INDEX);
        for (uint8 i = 0; i < userAddress.length; i++) {
            for (uint8 j = 0; j < amountRoles; j++) {
                // number roles 2 = {SUPER_ADMIN, NOTARY}
                if (roles[userAddress[i]][j]) {
                    listRole[i] = j;
                    break;
                }
            }
        }
        return (userAddress, listRole);
    }
}