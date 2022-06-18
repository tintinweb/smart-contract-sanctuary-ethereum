// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;
import "./AdminBase.sol";

/// @title GovWorld Admin Registry Contract
/// @dev using this contract for all the access controls in Gov Loan Builder

contract AdminRegistry is AdminBase {
    address public superAdmin; //it should be private

    /// @dev using upgradeable contract inherited in the AdminBase Contract
    /// @param _superAdmin the superAdmin control all the setter functions like Platform Fee, AutoSell Fee
    /// @param _admin1 default admin 1
    /// @param _admin2 default admin 2
    /// @param _admin3 default admin 3
    function initialize(
        address _superAdmin,
        address _admin1,
        address _admin2,
        address _admin3
    ) external initializer {
        __Ownable_init();
        pendingAdminKeys = new address[][](3);

        //owner becomes the default admin.
        _makeDefaultApproved(
            _superAdmin,
            AdminAccess(
                true,
                true,
                true,
                true,
                true,
                true,
                true,
                true,
                true,
                true,
                true,
                true,
                true
            )
        );

        _makeDefaultApproved(
            _admin1,
            AdminAccess(
                true,
                true,
                true,
                true,
                true,
                true,
                true,
                true,
                true,
                true,
                true,
                true,
                false
            )
        );
        _makeDefaultApproved(
            _admin2,
            AdminAccess(
                true,
                true,
                true,
                true,
                true,
                true,
                true,
                true,
                true,
                true,
                true,
                true,
                false
            )
        );
        _makeDefaultApproved(
            _admin3,
            AdminAccess(
                true,
                true,
                true,
                true,
                true,
                true,
                true,
                true,
                true,
                true,
                true,
                true,
                false
            )
        );
        superAdmin = _superAdmin;

        PENDING_ADD_ADMIN_KEY = 0;
        PENDING_EDIT_ADMIN_KEY = 1;
        PENDING_REMOVE_ADMIN_KEY = 2;
        //  ADD,EDIT,REMOVE
        PENDING_KEYS = [0, 1, 2];
    }

    /// @dev function to transfer super admin roles to the other new admin
    /// @param _newSuperAdmin address from the existing approved admins
    function transferSuperAdmin(address _newSuperAdmin) public {
        require(_newSuperAdmin != address(0), "invalid newSuperAdmin");
        require(_newSuperAdmin != superAdmin, "already designated");
        require(msg.sender == superAdmin, "not super admin");

        uint256 lengthofApprovedAdmins = allApprovedAdmins.length;
        for (uint256 i = 0; i < lengthofApprovedAdmins; i++) {
            if (allApprovedAdmins[i] == _newSuperAdmin) {
                approvedAdminRoles[_newSuperAdmin].superAdmin = true;
                approvedAdminRoles[superAdmin].superAdmin = false;
                superAdmin = _newSuperAdmin;

                emit SuperAdminOwnershipTransfer(
                    _newSuperAdmin,
                    approvedAdminRoles[_newSuperAdmin]
                );
                break;
            }
        }
    }

    /// @dev Checks if a given _newAdmin is approved by all other already approved amins
    /// @param _newAdmin Address of the new admin
    /// @param _key specify the add, edit or remove key

    function isDoneByAll(address _newAdmin, uint8 _key)
        external
        view
        returns (bool)
    {
        //following two loops check if all currenctly
        //approvedAdminRoles are present in approvebyAdmins of the _newAdmin
        //loop all existing admins approvedBy array
        address[] memory _areByAdmins = areByAdmins[_key][_newAdmin];

        uint256 presentCount = 0;
        uint256 allCount = 0;
        //get All admins with add govAdmin rights
        uint256 lengthAllApprovedAdmins = allApprovedAdmins.length;
        for (uint256 i = 0; i < lengthAllApprovedAdmins; i++) {
            if (
                _key == PENDING_ADD_ADMIN_KEY &&
                approvedAdminRoles[allApprovedAdmins[i]].addGovAdmin &&
                allApprovedAdmins[i] != _newAdmin
            ) {
                allCount = allCount + 1;
                for (uint256 j = 0; j < _areByAdmins.length; j++) {
                    if (_areByAdmins[j] == allApprovedAdmins[i]) {
                        presentCount = presentCount + 1;
                    }
                }
            }
            if (
                _key == PENDING_REMOVE_ADMIN_KEY &&
                approvedAdminRoles[allApprovedAdmins[i]].editGovAdmin &&
                allApprovedAdmins[i] != _newAdmin
            ) {
                allCount = allCount + 1;
                for (uint256 j = 0; j < _areByAdmins.length; j++) {
                    if (_areByAdmins[j] == allApprovedAdmins[i]) {
                        presentCount = presentCount + 1;
                    }
                }
            }
            if (
                _key == PENDING_EDIT_ADMIN_KEY &&
                approvedAdminRoles[allApprovedAdmins[i]].editGovAdmin &&
                allApprovedAdmins[i] != _newAdmin //all but yourself.
            ) {
                allCount = allCount + 1;
                //needs to check availability for all allowed admins to approve in editByAdmins.
                for (uint256 j = 0; j < _areByAdmins.length; j++) {
                    if (_areByAdmins[j] == allApprovedAdmins[i]) {
                        presentCount = presentCount + 1;
                    }
                }
            }
        }
        // standard multi-sig 51 % approvals needed to perform
        if (presentCount >= (allCount / 2) + 1) return true;
        else return false;
    }

    /// @dev makes _newAdmin an approved admin if there is only one curernt admin _newAdmin becomes
    /// @dev becomes approved as it is and if currently more then 1 admins then approveAddedAdmin needs to be
    /// @dev called  by all current admins
    /// @param _newAdmin Address of the new admin
    /// @param _adminAccess access variables for _newadmin

    function addAdmin(address _newAdmin, AdminAccess memory _adminAccess)
        external
        onlyAddGovAdminRole(msg.sender)
    {
        require(
            _adminAccess.addGovIntel ||
                _adminAccess.editGovIntel ||
                _adminAccess.addToken ||
                _adminAccess.editToken ||
                _adminAccess.addSp ||
                _adminAccess.editSp ||
                _adminAccess.addGovAdmin ||
                _adminAccess.editGovAdmin ||
                _adminAccess.addBridge ||
                _adminAccess.editBridge ||
                _adminAccess.addPool ||
                _adminAccess.editPool,
            "GAR: admin roles error"
        );
        require(isPending(msg.sender), "GAR: caller already in pending");
        require(_newAdmin != address(0), "invalid address");
        require(_newAdmin != msg.sender, "GAR: call for self"); //the GovAdmin cannot add himself as admin again
        require(
            allApprovedAdmins.length > 0,
            "GAR: addDefaultAdmin as owner first. "
        );
        require(
            _notAvailable(_newAdmin, msg.sender, PENDING_ADD_ADMIN_KEY),
            "GAR: already approved"
        );
        require(
            !_addressExists(_newAdmin, pendingAdminKeys[PENDING_ADD_ADMIN_KEY]),
            "GAR: already in pending"
        );
        require(
            !_addressExists(_newAdmin, allApprovedAdmins),
            "GAR: cannot add again"
        );
        require(!_adminAccess.superAdmin, "GAR: superadmin assign error");

        if (allApprovedAdmins.length == 1) {
            //this admin is now approved just by one admin
            _makeDefaultApproved(_newAdmin, _adminAccess);
        } else {
            //this admin is now in the pending list.
            _makePendingForAddEdit(
                _newAdmin,
                _adminAccess,
                PENDING_ADD_ADMIN_KEY
            );
        }
        performPendingActions();
    }

    /// @dev call approved the admin which is already added to pending by other admin
    /// @dev if all current admins call approveAddedAdmin are complete the admin auto becomes the approved admin
    /// @param _newAdmin Address of the new admin

    function approveAddedAdmin(address _newAdmin)
        external
        onlyAddGovAdminRole(msg.sender)
    {
        require(isPending(msg.sender), "GAR: caller already in pending");
        require(_newAdmin != msg.sender, "GAR: cannot self approve");
        //the admin that is adding _newAdmin must not already have approved.
        require(
            _notAvailable(_newAdmin, msg.sender, PENDING_ADD_ADMIN_KEY),
            "GAR: already approved"
        );
        require(
            _addressExists(_newAdmin, pendingAdminKeys[PENDING_ADD_ADMIN_KEY]),
            "GAR: nonpending error"
        );

        areByAdmins[PENDING_ADD_ADMIN_KEY][_newAdmin].push(msg.sender);
        emit NewAdminApproved(_newAdmin, msg.sender, PENDING_ADD_ADMIN_KEY);

        //if the _newAdmin is approved by all other admins
        if (this.isDoneByAll(_newAdmin, PENDING_ADD_ADMIN_KEY)) {
            //no need for approvedby anymore
            delete areByAdmins[PENDING_ADD_ADMIN_KEY][_newAdmin];
            //making this admin approved.
            _makeApproved(
                _newAdmin,
                pendingAdminRoles[PENDING_ADD_ADMIN_KEY][_newAdmin]
            );
            //no  need  for pending  role now
            delete pendingAdminRoles[PENDING_ADD_ADMIN_KEY][_newAdmin];

            emit NewAdminApprovedByAll(
                _newAdmin,
                approvedAdminRoles[_newAdmin]
            );
        }
    }

    /// @dev function to check if the address is already in pending or not
    /// @param _sender is the caller of the approve, edit or remove functions
    function isPending(address _sender) internal view returns (bool) {
        return (!_addressExists(
            _sender,
            pendingAdminKeys[PENDING_ADD_ADMIN_KEY]
        ) &&
            !_addressExists(
                _sender,
                pendingAdminKeys[PENDING_EDIT_ADMIN_KEY]
            ) &&
            !_addressExists(
                _sender,
                pendingAdminKeys[PENDING_REMOVE_ADMIN_KEY]
            ));
    }

    /// @dev any admin can reject the pending admin during the approval process and one rejection means
    //  not pending anymore.
    /// @param _admin Address of the new admin

    function rejectAdmin(address _admin, uint8 _key)
        external
        onlyAddGovAdminRole(msg.sender)
    {
        require(isPending(msg.sender), "GAR: caller already in pending");
        require(_admin != msg.sender, "GAR: call for self");
        require(
            _key == PENDING_ADD_ADMIN_KEY ||
                _key == PENDING_EDIT_ADMIN_KEY ||
                _key == PENDING_REMOVE_ADMIN_KEY,
            "GAR: wrong key inserted"
        );
        require(
            _addressExists(_admin, pendingAdminKeys[_key]),
            "GAR: nonpending error"
        );
       

        require(
            areByAdmins[_key][_admin].length > 0,
            "GAR: not available for rejection"
        );

        //the admin that is adding _newAdmin must not already have approved.
        require(
            _notAvailable(_admin, msg.sender, _key),
            "GAR: already approved"
        );
        //only with the reject of one admin call delete roles from mapping
        delete pendingAdminRoles[_key][_admin];
        uint256 length = areByAdmins[_key][_admin].length;
        for (uint256 i = 0; i < length; i++) {
            areByAdmins[_key][_admin].pop();
        }
        _removePendingIndex(_getIndex(_admin, pendingAdminKeys[_key]), _key);
        //delete admin roles from approved mapping
        delete areByAdmins[_key][_admin];
        emit AddAdminRejected(_admin, msg.sender);
    }

    /// @dev Get all Approved Admins
    /// @return address[] returns the all approved admins
    function getAllApproved() public view returns (address[] memory) {
        return allApprovedAdmins;
    }

    /// @dev Get all Pending Added Admin Keys
    /// @return address[] returns the addresses of the pending added adins

    function getAllPendingAddedAdminKeys()
        public
        view
        returns (address[] memory)
    {
        return pendingAdminKeys[PENDING_ADD_ADMIN_KEY];
    }

    /// @dev Get all Pending Edit Admin Keys
    /// @return address[] returns the addresses of the pending edit adins

    function getAllPendingEditAdminKeys()
        public
        view
        returns (address[] memory)
    {
        return pendingAdminKeys[PENDING_EDIT_ADMIN_KEY];
    }

    /// @dev Get all Pending Removed Admin Keys
    /// @return address[] returns the addresses of the pending removed adins
    function getAllPendingRemoveAdminKeys()
        public
        view
        returns (address[] memory)
    {
        return pendingAdminKeys[PENDING_REMOVE_ADMIN_KEY];
    }

    /// @dev Get all admin addresses which approved the address in the parameter
    /// @param _addedAdmin address of the approved/proposed added admin.
    /// @return address[] address array of the admin which approved the added admin
    function getApprovedByAdmins(address _addedAdmin)
        public
        view
        returns (address[] memory)
    {
        return areByAdmins[PENDING_ADD_ADMIN_KEY][_addedAdmin];
    }

    /// @dev Get all edit by admins addresses
    /// @param _editAdmin address of the edit admin
    /// @return address[] address array of the admin which approved the edit admin
    function getEditbyAdmins(address _editAdmin)
        public
        view
        returns (address[] memory)
    {
        return areByAdmins[PENDING_EDIT_ADMIN_KEY][_editAdmin];
    }

    /// @dev Get all admin addresses which approved the address in the parameter
    /// @param _removedAdmin address of the approved/proposed added admin.
    /// @return address[] returns the array of the admins which approved the removed admin request
    function getRemovedByAdmins(address _removedAdmin)
        public
        view
        returns (address[] memory)
    {
        return areByAdmins[PENDING_REMOVE_ADMIN_KEY][_removedAdmin];
    }

    /// @dev Get pending add admin roles
    /// @param _addAdmin address of the pending added admin
    /// @return AdminAccess roles of the pending added admin
    function getpendingAddedAdminRoles(address _addAdmin)
        public
        view
        returns (AdminAccess memory)
    {
        return pendingAdminRoles[PENDING_ADD_ADMIN_KEY][_addAdmin];
    }

    /// @dev Get pending edit admin roles
    /// @param _addAdmin address of the pending edit admin
    /// @return AdminAccess roles of the pending edit admin

    function getpendingEditedAdminRoles(address _addAdmin)
        public
        view
        returns (AdminAccess memory)
    {
        return pendingAdminRoles[PENDING_EDIT_ADMIN_KEY][_addAdmin];
    }

    /// @dev Get pending remove admin roles
    /// @param _addAdmin address of the pending removed admin
    /// @return AdminAccess returns the roles of the pending removed admin
    function getpendingRemovedAdminRoles(address _addAdmin)
        public
        view
        returns (AdminAccess memory)
    {
        return pendingAdminRoles[PENDING_REMOVE_ADMIN_KEY][_addAdmin];
    }

    /// @dev Initiate process of removal of admin,
    // in case there is only one admin removal is done instantly.
    // If there are more then one admin all must call removePendingAdmin.
    /// @param _admin Address of the admin requested to be removed

    function removeAdmin(address _admin)
        external
        onlyEditGovAdminRole(msg.sender)
    {
        // important! this statement checks if msg.sender is already in pending, so that he cannot place new requrest until his pending request is approved or rejected
        require(isPending(msg.sender), "GAR: caller already in pending");

        require(_admin != address(0), "invalid address");
        require(_admin != superAdmin, "GAR: cannot remove superadmin");
        require(_admin != msg.sender, "GAR: call for self");
        //the admin that is removing _admin must not already have approved.
        require(
            _notAvailable(_admin, msg.sender, PENDING_REMOVE_ADMIN_KEY),
            "GAR: already removed"
        );
        require(allApprovedAdmins.length > 0, "cannot remove last admin");
        require(
            !_addressExists(_admin, pendingAdminKeys[PENDING_REMOVE_ADMIN_KEY]),
            "GAR: already in pending"
        );
        require(_addressExists(_admin, allApprovedAdmins), "GAR: not an admin");

        //if length is 1 there is only one admin and he/she is removing another admin
        if (allApprovedAdmins.length == 1) {
            //this admin is now approved just by one admin
            _removeAdmin(_admin);
        } else {
            //this admin is now in the pending list.
            _makePendingForRemove(_admin, PENDING_REMOVE_ADMIN_KEY);
        }
        performPendingActions();
    }

    /// @dev call approved the admin which is already added to pending by other admin
    // if all current admins call approveAddedAdmin are complete the admin auto becomes the approved admin
    /// @param _admin Address of the new admin

    function approveRemovedAdmin(address _admin)
        external
        onlyEditGovAdminRole(msg.sender)
    {
        require(isPending(msg.sender), "GAR: caller already in pending");
        require(_admin != msg.sender, "GAR: cannot call for self");
        //the admin that is adding _admin must not already have approved.
        require(
            _notAvailable(_admin, msg.sender, PENDING_REMOVE_ADMIN_KEY),
            "GAR: already approved"
        );
        require(
            _addressExists(_admin, pendingAdminKeys[PENDING_REMOVE_ADMIN_KEY]),
            "GAR: nonpending admin error"
        );

        areByAdmins[PENDING_REMOVE_ADMIN_KEY][_admin].push(msg.sender);

        //if the _admin is approved by all other admins for removal
        if (this.isDoneByAll(_admin, PENDING_REMOVE_ADMIN_KEY)) {
            // _admin is now been removed
            _removeAdmin(_admin);
        } else {
            emit NewAdminApproved(_admin, msg.sender, PENDING_REMOVE_ADMIN_KEY);
        }
        performPendingActions();
    }

    /// @dev internal function call to execute the final approval, removal or editing of the admin roles
    function performPendingActions() internal {
        uint256 length = PENDING_KEYS.length;
        for (uint256 x = 0; x < length; x++) {
            for (uint256 i = 0; i < pendingAdminKeys[x].length; i++) {
                if (this.isDoneByAll(pendingAdminKeys[x][i], PENDING_KEYS[x])) {
                    if (PENDING_KEYS[x] == PENDING_ADD_ADMIN_KEY)
                        _makeApproved(
                            pendingAdminKeys[x][i],
                            pendingAdminRoles[PENDING_ADD_ADMIN_KEY][
                                pendingAdminKeys[PENDING_ADD_ADMIN_KEY][i]
                            ]
                        );
                    if (PENDING_KEYS[x] == PENDING_EDIT_ADMIN_KEY)
                        _editAdmin(pendingAdminKeys[x][i]);
                    if (PENDING_KEYS[x] == PENDING_REMOVE_ADMIN_KEY)
                        _removeAdmin(pendingAdminKeys[x][i]);
                    performPendingActions();
                }
            }
        }
    }

    /// @dev Initiate process of edit of an admin,
    // If there are more then one admin all must call approveEditAdmin
    /// @param _admin Address of the admin requested to be removed

    function editAdmin(address _admin, AdminAccess memory _adminAccess)
        external
        onlyEditGovAdminRole(msg.sender)
    {
        require(
            _adminAccess.addGovIntel ||
                _adminAccess.editGovIntel ||
                _adminAccess.addToken ||
                _adminAccess.editToken ||
                _adminAccess.addSp ||
                _adminAccess.editSp ||
                _adminAccess.addGovAdmin ||
                _adminAccess.editGovAdmin ||
                _adminAccess.addBridge ||
                _adminAccess.editBridge ||
                _adminAccess.addPool ||
                _adminAccess.editPool,
            "GAR: admin right error"
        );
        require(isPending(msg.sender), "GAR: caller already in pending");
        require(_admin != msg.sender, "GAR: self edit error");
        require(_admin != superAdmin, "GAR: superadmin error");
        require(allApprovedAdmins.length > 0, "GAR: cannot edit");
        //the admin that is removing _admin must not already have approved.
        require(
            _notAvailable(_admin, msg.sender, PENDING_EDIT_ADMIN_KEY),
            "GAR: already approve for edit"
        );
        require(
            !_addressExists(_admin, pendingAdminKeys[PENDING_EDIT_ADMIN_KEY]),
            "GAR: already pending for edit"
        );
        require(_addressExists(_admin, allApprovedAdmins), "GAR: not admin");

        require(!_adminAccess.superAdmin, "GAR: cannot assign super admin");

        if (allApprovedAdmins.length == 1) {
            _editAdmin(_admin);
        } else {
            //this admin is now in the pending list.
            _makePendingForAddEdit(
                _admin,
                _adminAccess,
                PENDING_EDIT_ADMIN_KEY
            );
        }
        performPendingActions();
    }

    /// @dev call approved the admin which is already added to pending by other admin
    // if all current admins call approveEditAdmin are complete the admin edits become active
    /// @param _admin Address of the new admin

    function approveEditAdmin(address _admin)
        external
        onlyEditGovAdminRole(msg.sender)
    {
        require(isPending(msg.sender), "GAR: caller already in pending");
        require(_admin != msg.sender, "GAR: call for self");
        require(
            _addressExists(_admin, pendingAdminKeys[PENDING_EDIT_ADMIN_KEY]),
            "GAR: nonpending admin error"
        );
        //the admin that is adding _admin must not already have approved.
        require(
            _notAvailable(_admin, msg.sender, PENDING_EDIT_ADMIN_KEY),
            "GAR: already approved"
        );
        areByAdmins[PENDING_EDIT_ADMIN_KEY][_admin].push(msg.sender);

        //if the _admin is approved by all other admins for removal
        if (this.isDoneByAll(_admin, PENDING_EDIT_ADMIN_KEY)) {
            // _admin is now an approved admin.
            _editAdmin(_admin);
        } else {
            emit NewAdminApproved(_admin, msg.sender, PENDING_EDIT_ADMIN_KEY);
        }
        performPendingActions();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;
import "../admin/interfaces/IAdminRegistry.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract AdminBase is OwnableUpgradeable, IAdminRegistry {
    //admin role keys
    uint8 public PENDING_ADD_ADMIN_KEY;
    uint8 public PENDING_EDIT_ADMIN_KEY;
    uint8 public PENDING_REMOVE_ADMIN_KEY;
    //ADD,EDIT,REMOVE
    uint8[] public PENDING_KEYS;

    /// @dev approve admin roles for each address
    /// @dev Stores the key address for roles
    mapping(address => AdminAccess) public approvedAdminRoles;

    //list of all approved admin addresses 
    address[] public allApprovedAdmins;

    /// mapping of admin role keys to admin addresses to admin access roles
    mapping(uint8 => mapping(address => AdminAccess)) public pendingAdminRoles;
    //keys of admin role keys to admin addresses
    address[][] public pendingAdminKeys;

    /// @dev list of admins approved by other admins, for the specific key
    mapping(uint8 => mapping(address => address[])) public areByAdmins;
    event NewAdminApproved(
        address indexed _newAdmin,
        address indexed _addByAdmin,
        uint8 indexed _key
    );
    event NewAdminApprovedByAll(
        address indexed _newAdmin,
        AdminAccess _adminAccess
    );
    event AdminRemovedByAll(
        address indexed _admin,
        address indexed _removedByAdmin
    );
    event AdminEditedApprovedByAll(
        address indexed _admin,
        AdminAccess _adminAccess
    );
    event AddAdminRejected(
        address indexed _newAdmin,
        address indexed _rejectByAdmin
    );
    event EditAdminRejected(
        address indexed _newAdmin,
        address indexed _rejectByAdmin
    );
    event RemoveAdminRejected(
        address indexed _newAdmin,
        address indexed _rejectByAdmin
    );
    event SuperAdminOwnershipTransfer(
        address indexed _superAdmin,
        AdminAccess _adminAccess
    );

    // access-modifier for adding gov admin
    modifier onlyAddGovAdminRole(address _admin) {
        require(
            approvedAdminRoles[_admin].addGovAdmin,
            "GAR: not add admin role"
        );
        _;
    }

    // access-modifier for editing gov admin
    modifier onlyEditGovAdminRole(address _admin) {
        require(
            approvedAdminRoles[_admin].editGovAdmin,
            "GAR: not edit admin role"
        );
        _;
    }

    /// @dev Checks if a given _newAdmin is not approved by the _approvedBy admin.
    /// @param _newAdmin Address of the new admin
    /// @param _by Address of the existing admin that may have approved/edited/removed _newAdmin already.
    /// @param _key Address of the existing admin that may have approved/edited/removed _newAdmin already.
    /// @return bool returns true or false value

    function _notAvailable(
        address _newAdmin,
        address _by,
        uint8 _key
    ) internal view returns (bool) {
        uint256 pendingKeyslength = PENDING_KEYS.length;
        for (uint256 k = 0; k < pendingKeyslength; k++) {
            if (_key == PENDING_KEYS[k]) {
                uint256 approveByAdminsLength = areByAdmins[_key][_newAdmin]
                    .length;
                for (uint256 i = 0; i < approveByAdminsLength; i++) {
                    if (areByAdmins[_key][_newAdmin][i] == _by) {
                        return false; //approved/edited/removed
                    }
                }
            }
        }
        return true; //not approved/edited/removed
    }

    /// @dev makes _newAdmin an approved admin and emits the event
    /// @param _newAdmin Address of the new admin
    /// @param _adminAccess access variables for _newadmin

    function _makeDefaultApproved(
        address _newAdmin,
        AdminAccess memory _adminAccess
    ) internal {
        //no need for approved by admin for the new  admin anymore.
        delete areByAdmins[PENDING_ADD_ADMIN_KEY][_newAdmin];
        // _newAdmin is now an approved admin.
        approvedAdminRoles[_newAdmin] = _adminAccess;
        //new key for mapping approvedAdminRoles
        allApprovedAdmins.push(_newAdmin);
        emit NewAdminApprovedByAll(_newAdmin, _adminAccess);
    }

    /// @dev makes _newAdmin an approved admin and emits the event
    /// @param _newAdmin Address of the new admin
    /// @param _adminAccess access variables for _newadmin

    function _makeApproved(address _newAdmin, AdminAccess memory _adminAccess)
        internal
    {
        //no need for approved by admin for the new  admin anymore.
        delete areByAdmins[PENDING_ADD_ADMIN_KEY][_newAdmin];
        // _newAdmin is now an approved admin.
        approvedAdminRoles[_newAdmin] = _adminAccess;
        //new key for mapping approvedAdminRoles
        allApprovedAdmins.push(_newAdmin);
        _removePendingIndex(
            _getIndex(_newAdmin, pendingAdminKeys[PENDING_ADD_ADMIN_KEY]),
            PENDING_ADD_ADMIN_KEY
        );
    }

    /// @dev makes _newAdmin a pending admin for approval to be given by all current admins
    /// @param _newAdmin Address of the new admin
    /// @param _adminAccess access variables for _newadmin

    function _makePendingForAddEdit(
        address _newAdmin,
        AdminAccess memory _adminAccess,
        uint8 _key
    ) internal {
        //the admin who is adding the new admin is approving _newAdmin by default
        areByAdmins[_key][_newAdmin].push(msg.sender);
        //add _newAdmin to pendingAddedAdminRoles for approval  by all other current.
        pendingAdminRoles[_key][_newAdmin] = _adminAccess;
        pendingAdminKeys[_key].push(_newAdmin);
        emit NewAdminApproved(_newAdmin, msg.sender, _key);
    }

    /// @dev remove _admin by the approved admins
    /// @param _admin Address of the approved admin

    function _removeAdmin(address _admin) internal {
        // _admin is now a removed admin.
        delete approvedAdminRoles[_admin];
        delete areByAdmins[PENDING_REMOVE_ADMIN_KEY][_admin];
        delete areByAdmins[PENDING_EDIT_ADMIN_KEY][_admin];
        delete areByAdmins[PENDING_ADD_ADMIN_KEY][_admin];
        delete pendingAdminRoles[PENDING_ADD_ADMIN_KEY][_admin];
        delete pendingAdminRoles[PENDING_EDIT_ADMIN_KEY][_admin];
        delete pendingAdminRoles[PENDING_REMOVE_ADMIN_KEY][_admin];

        //remove key for mapping approvedAdminRoles
        _removeIndex(_getIndex(_admin, allApprovedAdmins));
        _removePendingIndex(
            _getIndex(_admin, pendingAdminKeys[PENDING_REMOVE_ADMIN_KEY]),
            PENDING_REMOVE_ADMIN_KEY
        );

        emit AdminRemovedByAll(_admin, msg.sender);
    }

    /// @dev edit admin roles of the approved admin
    /// @param _admin address which is going to be edited

    function _editAdmin(address _admin) internal {
        approvedAdminRoles[_admin] = pendingAdminRoles[PENDING_EDIT_ADMIN_KEY][
            _admin
        ];

        delete areByAdmins[PENDING_EDIT_ADMIN_KEY][_admin];
        delete pendingAdminRoles[PENDING_EDIT_ADMIN_KEY][_admin];
        _removePendingIndex(
            _getIndex(_admin, pendingAdminKeys[PENDING_EDIT_ADMIN_KEY]),
            PENDING_EDIT_ADMIN_KEY
        );

        emit AdminEditedApprovedByAll(_admin, approvedAdminRoles[_admin]);
    }

    /// @dev remove the index of the approved admin address
    function _removeIndex(uint256 index) internal {
        uint256 length = allApprovedAdmins.length;
        for (uint256 i = index; i < length - 1; i++) {
            allApprovedAdmins[i] = allApprovedAdmins[i + 1];
        }
        allApprovedAdmins.pop();
    }

    /// @dev remove the pending admin index for that specific key
    function _removePendingIndex(uint256 index, uint8 key) internal {
        uint256 length = pendingAdminKeys[key].length;
        for (uint256 i = index; i < length - 1; i++) {
            pendingAdminKeys[key][i] = pendingAdminKeys[key][i + 1];
        }
        pendingAdminKeys[key].pop();
    }

    /// @dev makes _admin a pending admin for approval to be given by
    /// @dev all current admins for removing this admnin.
    /// @param _admin address of the new admin which is going pending for remove

    function _makePendingForRemove(address _admin, uint8 _key) internal {
        //the admin who is adding the new admin is approving _newAdmin by default
        areByAdmins[_key][_admin].push(msg.sender);
        pendingAdminKeys[_key].push(_admin);
        //add _newAdmin to pendingAddedAdminRoles for approval  by all other current.
        pendingAdminRoles[_key][_admin] = approvedAdminRoles[_admin];
        emit NewAdminApproved(_admin, msg.sender, _key);
    }

    function _getIndex(address _valueToFindAndRemove, address[] memory from)
        internal
        pure
        returns (uint256 index)
    {
        uint256 length = from.length;
        for (uint256 i = 0; i < length; i++) {
            if (from[i] == _valueToFindAndRemove) {
                return i;
            }
        }
    }

    /// @dev check if the address exist in the pending admins array
    function _addressExists(address _valueToFind, address[] memory from)
        internal
        pure
        returns (bool)
    {
        uint256 length = from.length;
        for (uint256 i = 0; i < length; i++) {
            if (from[i] == _valueToFind) {
                return true;
            }
        }
        return false;
    }

    function isAddGovAdminRole(address admin)
        external
        view
        override
        returns (bool)
    {
        return approvedAdminRoles[admin].addGovAdmin;
    }

    /// @dev using this function externally in Gov Tier Level Smart Contract
    function isEditAdminAccessGranted(address admin)
        external
        view
        override
        returns (bool)
    {
        return approvedAdminRoles[admin].editGovAdmin;
    }

    /// @dev using this function externally in other Smart Contracts
    function isAddTokenRole(address admin)
        external
        view
        override
        returns (bool)
    {
        return approvedAdminRoles[admin].addToken;
    }

    /// @dev using this function externally in other Smart Contracts
    function isEditTokenRole(address admin)
        external
        view
        override
        returns (bool)
    {
        return approvedAdminRoles[admin].editToken;
    }

    /// @dev using this function externally in other Smart Contracts
    function isAddSpAccess(address admin)
        external
        view
        override
        returns (bool)
    {
        return approvedAdminRoles[admin].addSp;
    }

    /// @dev using this function externally in other Smart Contracts
    function isEditSpAccess(address admin)
        external
        view
        override
        returns (bool)
    {
        return approvedAdminRoles[admin].editSp;
    }

    /// @dev using this function externally in other smart contracts
    function isEditAPYPerAccess(address admin)
        external
        view
        override
        returns (bool)
    {
        return approvedAdminRoles[admin].addGovAdmin;
    }

    /// @dev using this function in loan smart contracts to withdraw network balance
    function isSuperAdminAccess(address admin)
        external
        view
        override
        returns (bool)
    {
        return approvedAdminRoles[admin].superAdmin;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

interface IAdminRegistry {
    struct AdminAccess {
        //access-modifier variables to add projects to gov-intel
        bool addGovIntel;
        bool editGovIntel;
        //access-modifier variables to add tokens to gov-world protocol
        bool addToken;
        bool editToken;
        //access-modifier variables to add strategic partners to gov-world protocol
        bool addSp;
        bool editSp;
        //access-modifier variables to add gov-world admins to gov-world protocol
        bool addGovAdmin;
        bool editGovAdmin;
        //access-modifier variables to add bridges to gov-world protocol
        bool addBridge;
        bool editBridge;
        //access-modifier variables to add pools to gov-world protocol
        bool addPool;
        bool editPool;
        //superAdmin role assigned only by the super admin
        bool superAdmin;
    }

    function isAddGovAdminRole(address admin) external view returns (bool);

    //using this function externally in Gov Tier Level Smart Contract
    function isEditAdminAccessGranted(address admin)
        external
        view
        returns (bool);

    //using this function externally in other Smart Contracts
    function isAddTokenRole(address admin) external view returns (bool);

    //using this function externally in other Smart Contracts
    function isEditTokenRole(address admin) external view returns (bool);

    //using this function externally in other Smart Contracts
    function isAddSpAccess(address admin) external view returns (bool);

    //using this function externally in other Smart Contracts
    function isEditSpAccess(address admin) external view returns (bool);

    //using this function externally in other Smart Contracts
    function isEditAPYPerAccess(address admin) external view returns (bool);

    //using this function in loan smart contracts to withdraw network balance
    function isSuperAdminAccess(address admin) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}