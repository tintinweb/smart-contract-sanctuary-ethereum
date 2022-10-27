// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;
import "./LibAdmin.sol";
import {LibMeta} from "./../../shared/libraries/LibMeta.sol";
import {LibDiamond} from "../../shared/libraries/LibDiamond.sol";

/// @title GovWorld Admin Registry Contract
/// @dev using this contract for all the access controls in Gov Loan Builder

contract AdminRegistryFacet {
    /***********************************|
   |events emited in init not in orginal|
   |__________________________________ */

    // access-modifier for adding gov admin
    modifier onlyAddGovAdminRole(address _admin) {
        LibAdminStorage.AdminStorage storage s = LibAdminStorage
            .adminRegistryStorage();
        require(
            s.approvedAdminRoles[_admin].addGovAdmin,
            "GAR: not add or edit admin role"
        );
        _;
    }

    // access-modifier for editing gov admin
    modifier onlyEditGovAdminRole(address _admin) {
        LibAdminStorage.AdminStorage storage s = LibAdminStorage
            .adminRegistryStorage();
        require(
            s.approvedAdminRoles[_admin].editGovAdmin,
            "GAR: not edit admin role"
        );
        _;
    }

    /// @dev initializing the admin facet to add superadmin and three other admins as a default approved
    /// @param _superAdmin the superAdmin control all the setter functions like Platform Fee, AutoSell Fee
    /// @param _admin1 default admin 1
    /// @param _admin2 default admin 2
    /// @param _admin3 default admin 3
    function adminRegistryInit(
        address _superAdmin,
        address _admin1,
        address _admin2,
        address _admin3
    ) external {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        require(
            LibMeta.msgSender() == ds.contractOwner,
            "Must own the contract."
        );

        LibAdminStorage.AdminStorage storage es = LibAdminStorage
            .adminRegistryStorage();
        require(es.allApprovedAdmins.length == 0, "Already Initialized Admins");
        es.pendingAdminKeys = new address[][](3);

        //owner becomes the default admin.
        LibAdmin._makeDefaultApproved(
            _superAdmin,
            LibAdminStorage.AdminAccess(
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

        LibAdmin._makeDefaultApproved(
            _admin1,
            LibAdminStorage.AdminAccess(
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
        LibAdmin._makeDefaultApproved(
            _admin2,
            LibAdminStorage.AdminAccess(
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
        LibAdmin._makeDefaultApproved(
            _admin3,
            LibAdminStorage.AdminAccess(
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
        es.superAdmin = _superAdmin;

        es.PENDING_ADD_ADMIN_KEY = 0;
        es.PENDING_EDIT_ADMIN_KEY = 1;
        es.PENDING_REMOVE_ADMIN_KEY = 2;
        //  ADD,EDIT,REMOVE
        es.PENDING_KEYS = [0, 1, 2];

        emit LibAdmin.NewAdminApprovedByAll(
            _superAdmin,
            es.approvedAdminRoles[_superAdmin]
        );
        emit LibAdmin.NewAdminApprovedByAll(
            _admin1,
            es.approvedAdminRoles[_admin1]
        );
        emit LibAdmin.NewAdminApprovedByAll(
            _admin2,
            es.approvedAdminRoles[_admin2]
        );
        emit LibAdmin.NewAdminApprovedByAll(
            _admin3,
            es.approvedAdminRoles[_admin3]
        );
    }

    /// @dev function to transfer super admin roles to the other new admin
    /// @param _newSuperAdmin address from the existing approved admins
    function transferSuperAdmin(address _newSuperAdmin)
        external
        returns (bool)
    {
        LibAdminStorage.AdminStorage storage es = LibAdminStorage
            .adminRegistryStorage();
        require(_newSuperAdmin != address(0), "invalid address");
        require(_newSuperAdmin != es.superAdmin, "already designated");
        require(LibMeta.msgSender() == es.superAdmin, "not super admin");

        uint256 lengthofApprovedAdmins = es.allApprovedAdmins.length;
        for (uint256 i = 0; i < lengthofApprovedAdmins; i++) {
            if (es.allApprovedAdmins[i] == _newSuperAdmin) {
                es.approvedAdminRoles[_newSuperAdmin].superAdmin = true;
                es.approvedAdminRoles[es.superAdmin].superAdmin = false;
                es.superAdmin = _newSuperAdmin;

                emit LibAdmin.SuperAdminOwnershipTransfer(
                    _newSuperAdmin,
                    es.approvedAdminRoles[_newSuperAdmin]
                );
                return true;
            }
        }
        revert("Only admin can become super admin");
    }

    /// @dev Checks if a given _newAdmin is approved by all other already approved admins
    /// @param _newAdmin Address of the new admin
    /// @param _key specify the add, edit or remove key

    function isDoneByAll(address _newAdmin, uint8 _key)
        external
        view
        returns (bool)
    {
        LibAdminStorage.AdminStorage storage es = LibAdminStorage
            .adminRegistryStorage();

        //following two loops check if all currenctly
        //approvedAdminRoles are present in approvebyAdmins of the _newAdmin
        //loop all existing admins approvedBy array
        address[] memory _areByAdmins = es.areByAdmins[_key][_newAdmin];

        uint256 presentCount = 0;
        uint256 allCount = 0;
        //get All admins with add govAdmin rights
        uint256 lengthAllApprovedAdmins = es.allApprovedAdmins.length;
        for (uint256 i = 0; i < lengthAllApprovedAdmins; i++) {
            if (
                _key == es.PENDING_ADD_ADMIN_KEY &&
                es.approvedAdminRoles[es.allApprovedAdmins[i]].addGovAdmin &&
                es.allApprovedAdmins[i] != _newAdmin
            ) {
                allCount = allCount + 1;
                for (uint256 j = 0; j < _areByAdmins.length; j++) {
                    if (_areByAdmins[j] == es.allApprovedAdmins[i]) {
                        presentCount = presentCount + 1;
                    }
                }
            }
            if (
                _key == es.PENDING_REMOVE_ADMIN_KEY &&
                es.approvedAdminRoles[es.allApprovedAdmins[i]].editGovAdmin &&
                es.allApprovedAdmins[i] != _newAdmin
            ) {
                allCount = allCount + 1;
                for (uint256 j = 0; j < _areByAdmins.length; j++) {
                    if (_areByAdmins[j] == es.allApprovedAdmins[i]) {
                        presentCount = presentCount + 1;
                    }
                }
            }
            if (
                _key == es.PENDING_EDIT_ADMIN_KEY &&
                es.approvedAdminRoles[es.allApprovedAdmins[i]].editGovAdmin &&
                es.allApprovedAdmins[i] != _newAdmin //all but yourself.
            ) {
                allCount = allCount + 1;
                //needs to check availability for all allowed admins to approve in editByAdmins.
                for (uint256 j = 0; j < _areByAdmins.length; j++) {
                    if (_areByAdmins[j] == es.allApprovedAdmins[i]) {
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

    function addAdmin(
        address _newAdmin,
        LibAdminStorage.AdminAccess memory _adminAccess
    ) external onlyAddGovAdminRole(LibMeta.msgSender()) {
        LibAdminStorage.AdminStorage storage es = LibAdminStorage
            .adminRegistryStorage();

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
        require(
            es.pendingAdminKeys[es.PENDING_ADD_ADMIN_KEY].length == 0 &&
                es.pendingAdminKeys[es.PENDING_EDIT_ADMIN_KEY].length == 0 &&
                es.pendingAdminKeys[es.PENDING_REMOVE_ADMIN_KEY].length == 0,
            "GAR: only one admin can be add, edit, remove at once"
        );
        require(_newAdmin != address(0), "invalid address");
        require(_newAdmin != LibMeta.msgSender(), "GAR: call for self"); //the GovAdmin cannot add himself as admin again

        require(
            !LibAdmin._addressExists(_newAdmin, es.allApprovedAdmins),
            "GAR: cannot add again"
        );
        require(!_adminAccess.superAdmin, "GAR: superadmin assign error");

        if (es.allApprovedAdmins.length == 1) {
            //this admin is now approved just by one admin
            LibAdmin._makeDefaultApproved(_newAdmin, _adminAccess);
            emit LibAdmin.NewAdminApprovedByAll(_newAdmin, _adminAccess);
        } else {
            //this admin is now in the pending list.
            LibAdmin._makePendingForAddEdit(
                _newAdmin,
                _adminAccess,
                es.PENDING_ADD_ADMIN_KEY
            );
            emit LibAdmin.NewAdminApproved(
                _newAdmin,
                LibMeta.msgSender(),
                es.PENDING_ADD_ADMIN_KEY
            );
        }
    }

    /// @dev call approved the admin which is already added to pending by other admin
    /// @dev if all current admins call approveAddedAdmin are complete the admin auto becomes the approved admin
    /// @param _newAdmin Address of the new admin

    function approveAddedAdmin(address _newAdmin)
        external
        onlyAddGovAdminRole(LibMeta.msgSender())
    {
        LibAdminStorage.AdminStorage storage es = LibAdminStorage
            .adminRegistryStorage();

        require(
            isPending(LibMeta.msgSender()),
            "GAR: caller already in pending"
        );
        require(_newAdmin != LibMeta.msgSender(), "GAR: cannot self approve");
        //the admin that is adding _newAdmin must not already have approved.
        require(
            LibAdmin._notAvailable(
                _newAdmin,
                LibMeta.msgSender(),
                es.PENDING_ADD_ADMIN_KEY
            ),
            "GAR: already approved"
        );
        require(
            LibAdmin._addressExists(
                _newAdmin,
                es.pendingAdminKeys[es.PENDING_ADD_ADMIN_KEY]
            ),
            "GAR: nonpending error"
        );

        es.areByAdmins[es.PENDING_ADD_ADMIN_KEY][_newAdmin].push(
            LibMeta.msgSender()
        );
        emit LibAdmin.NewAdminApproved(
            _newAdmin,
            LibMeta.msgSender(),
            es.PENDING_ADD_ADMIN_KEY
        );

        //if the _newAdmin is approved by all other admins
        if (this.isDoneByAll(_newAdmin, es.PENDING_ADD_ADMIN_KEY)) {
            //making this admin approved.
            LibAdmin._makeApproved(
                _newAdmin,
                es.pendingAdminRoles[es.PENDING_ADD_ADMIN_KEY][_newAdmin]
            );
            //no  need  for pending  role now
            delete es.pendingAdminRoles[es.PENDING_ADD_ADMIN_KEY][_newAdmin];

            emit LibAdmin.NewAdminApprovedByAll(
                _newAdmin,
                es.approvedAdminRoles[_newAdmin]
            );
        }
    }

    /// @dev function to check if the address is already in pending or not
    /// @param _sender is the caller of the approve, edit or remove functions
    function isPending(address _sender) internal view returns (bool) {
        LibAdminStorage.AdminStorage storage es = LibAdminStorage
            .adminRegistryStorage();

        return (!LibAdmin._addressExists(
            _sender,
            es.pendingAdminKeys[es.PENDING_ADD_ADMIN_KEY]
        ) &&
            !LibAdmin._addressExists(
                _sender,
                es.pendingAdminKeys[es.PENDING_EDIT_ADMIN_KEY]
            ) &&
            !LibAdmin._addressExists(
                _sender,
                es.pendingAdminKeys[es.PENDING_REMOVE_ADMIN_KEY]
            ));
    }

    /// @dev any admin can reject the pending admin during the approval process and one rejection means
    //  not pending anymore.
    /// @param _admin Address of the new admin

    function rejectAdmin(address _admin, uint8 _key)
        external
        onlyEditGovAdminRole(LibMeta.msgSender())
    {
        LibAdminStorage.AdminStorage storage es = LibAdminStorage
            .adminRegistryStorage();

        require(
            isPending(LibMeta.msgSender()),
            "GAR: caller already in pending"
        );
        require(_admin != LibMeta.msgSender(), "GAR: call for self");
        require(
            _key == es.PENDING_ADD_ADMIN_KEY ||
                _key == es.PENDING_EDIT_ADMIN_KEY ||
                _key == es.PENDING_REMOVE_ADMIN_KEY,
            "GAR: wrong key inserted"
        );
        require(
            LibAdmin._addressExists(_admin, es.pendingAdminKeys[_key]),
            "GAR: nonpending error"
        );

        //the admin that is adding _newAdmin must not already have approved.
        require(
            LibAdmin._notAvailable(_admin, LibMeta.msgSender(), _key),
            "GAR: already approved"
        );
        //only with the reject of one admin call delete roles from mapping
        delete es.pendingAdminRoles[_key][_admin];
        uint256 length = es.areByAdmins[_key][_admin].length;
        for (uint256 i = 0; i < length; i++) {
            es.areByAdmins[_key][_admin].pop();
        }
        LibAdmin._removePendingIndex(
            LibAdmin._getIndex(_admin, es.pendingAdminKeys[_key]),
            _key
        );
        //delete admin roles from approved mapping
        delete es.areByAdmins[_key][_admin];
        emit LibAdmin.AddAdminRejected(_admin, LibMeta.msgSender());
    }

    /// @dev Get all Approved Admins
    /// @return address[] returns the all approved admins
    function getAllApproved() external view returns (address[] memory) {
        LibAdminStorage.AdminStorage storage es = LibAdminStorage
            .adminRegistryStorage();

        return es.allApprovedAdmins;
    }

    /// @dev Get all Pending Added Admin Keys
    /// @return address[] returns the addresses of the pending added adins

    function getAllPendingAddedAdminKeys()
        external
        view
        returns (address[] memory)
    {
        LibAdminStorage.AdminStorage storage es = LibAdminStorage
            .adminRegistryStorage();

        return es.pendingAdminKeys[es.PENDING_ADD_ADMIN_KEY];
    }

    /// @dev Get all Pending Edit Admin Keys
    /// @return address[] returns the addresses of the pending edit adins

    function getAllPendingEditAdminKeys()
        external
        view
        returns (address[] memory)
    {
        LibAdminStorage.AdminStorage storage es = LibAdminStorage
            .adminRegistryStorage();

        return es.pendingAdminKeys[es.PENDING_EDIT_ADMIN_KEY];
    }

    /// @dev Get all Pending Removed Admin Keys
    /// @return address[] returns the addresses of the pending removed adins
    function getAllPendingRemoveAdminKeys()
        external
        view
        returns (address[] memory)
    {
        LibAdminStorage.AdminStorage storage es = LibAdminStorage
            .adminRegistryStorage();

        return es.pendingAdminKeys[es.PENDING_REMOVE_ADMIN_KEY];
    }

    /// @dev Get all admin addresses which approved the address in the parameter
    /// @param _addedAdmin address of the approved/proposed added admin.
    /// @return address[] address array of the admin which approved the added admin
    function getApprovedByAdmins(address _addedAdmin)
        external
        view
        returns (address[] memory)
    {
        LibAdminStorage.AdminStorage storage es = LibAdminStorage
            .adminRegistryStorage();

        return es.areByAdmins[es.PENDING_ADD_ADMIN_KEY][_addedAdmin];
    }

    /// @dev Get all edit by admins addresses
    /// @param _editAdminAddress address of the edit admin
    /// @return address[] address array of the admin which approved the edit admin
    function getEditbyAdmins(address _editAdminAddress)
        external
        view
        returns (address[] memory)
    {
        LibAdminStorage.AdminStorage storage es = LibAdminStorage
            .adminRegistryStorage();

        return es.areByAdmins[es.PENDING_EDIT_ADMIN_KEY][_editAdminAddress];
    }

    /// @dev Get all admin addresses which approved the address in the parameter
    /// @param _removedAdmin address of the approved/proposed added admin.
    /// @return address[] returns the array of the admins which approved the removed admin request
    function getRemovedByAdmins(address _removedAdmin)
        external
        view
        returns (address[] memory)
    {
        LibAdminStorage.AdminStorage storage es = LibAdminStorage
            .adminRegistryStorage();

        return es.areByAdmins[es.PENDING_REMOVE_ADMIN_KEY][_removedAdmin];
    }

    /// @dev Get pending add admin roles
    /// @param _addAdmin address of the pending added admin
    /// @return AdminAccess roles of the pending added admin
    function getpendingAddedAdminRoles(address _addAdmin)
        external
        view
        returns (LibAdminStorage.AdminAccess memory)
    {
        LibAdminStorage.AdminStorage storage es = LibAdminStorage
            .adminRegistryStorage();

        return es.pendingAdminRoles[es.PENDING_ADD_ADMIN_KEY][_addAdmin];
    }

    /// @dev Get pending edit admin roles
    /// @param _addAdmin address of the pending edit admin
    /// @return AdminAccess roles of the pending edit admin

    function getpendingEditedAdminRoles(address _addAdmin)
        external
        view
        returns (LibAdminStorage.AdminAccess memory)
    {
        LibAdminStorage.AdminStorage storage es = LibAdminStorage
            .adminRegistryStorage();

        return es.pendingAdminRoles[es.PENDING_EDIT_ADMIN_KEY][_addAdmin];
    }

    /// @dev Get pending remove admin roles
    /// @param _addAdmin address of the pending removed admin
    /// @return AdminAccess returns the roles of the pending removed admin
    function getpendingRemovedAdminRoles(address _addAdmin)
        external
        view
        returns (LibAdminStorage.AdminAccess memory)
    {
        LibAdminStorage.AdminStorage storage es = LibAdminStorage
            .adminRegistryStorage();

        return es.pendingAdminRoles[es.PENDING_REMOVE_ADMIN_KEY][_addAdmin];
    }

    /// @dev Initiate process of removal of admin,
    // in case there is only one admin removal is done instantly.
    // If there are more then one admin all must call removePendingAdmin.
    /// @param _admin Address of the admin requested to be removed

    function removeAdmin(address _admin)
        external
        onlyEditGovAdminRole(LibMeta.msgSender())
    {
        LibAdminStorage.AdminStorage storage es = LibAdminStorage
            .adminRegistryStorage();

        require(
            es.pendingAdminKeys[es.PENDING_ADD_ADMIN_KEY].length == 0 &&
                es.pendingAdminKeys[es.PENDING_EDIT_ADMIN_KEY].length == 0 &&
                es.pendingAdminKeys[es.PENDING_REMOVE_ADMIN_KEY].length == 0,
            "GAR: only one admin can be add, edit, remove at once"
        );

        require(_admin != address(0), "GAR: invalid address");
        require(_admin != es.superAdmin, "GAR: cannot remove superadmin");
        require(_admin != LibMeta.msgSender(), "GAR: call for self");

        require(
            LibAdmin._addressExists(_admin, es.allApprovedAdmins),
            "GAR: not an admin"
        );

        //this admin is now in the pending list.
        LibAdmin._makePendingForRemove(_admin, es.PENDING_REMOVE_ADMIN_KEY);

        emit LibAdmin.NewAdminApproved(
            _admin,
            LibMeta.msgSender(),
            es.PENDING_REMOVE_ADMIN_KEY
        );
    }

    /// @dev call approved the admin which is already added to pending by other admin
    // if all current admins call approveAddedAdmin are complete the admin auto becomes the approved admin
    /// @param _admin Address of the new admin

    function approveRemovedAdmin(address _admin)
        external
        onlyEditGovAdminRole(LibMeta.msgSender())
    {
        LibAdminStorage.AdminStorage storage es = LibAdminStorage
            .adminRegistryStorage();

        require(
            isPending(LibMeta.msgSender()),
            "GAR: caller already in pending"
        );
        require(_admin != LibMeta.msgSender(), "GAR: cannot call for self");
        //the admin that is adding _admin must not already have approved.
        require(
            LibAdmin._notAvailable(
                _admin,
                LibMeta.msgSender(),
                es.PENDING_REMOVE_ADMIN_KEY
            ),
            "GAR: already approved"
        );
        require(
            LibAdmin._addressExists(
                _admin,
                es.pendingAdminKeys[es.PENDING_REMOVE_ADMIN_KEY]
            ),
            "GAR: nonpending admin error"
        );

        es.areByAdmins[es.PENDING_REMOVE_ADMIN_KEY][_admin].push(
            LibMeta.msgSender()
        );

        //if the _admin is approved by all other admins for removal
        if (this.isDoneByAll(_admin, es.PENDING_REMOVE_ADMIN_KEY)) {
            // _admin is now been removed
            LibAdmin._removeAdmin(_admin);
            emit LibAdmin.AdminRemovedByAll(_admin, LibMeta.msgSender());
        } else {
            emit LibAdmin.NewAdminApproved(
                _admin,
                LibMeta.msgSender(),
                es.PENDING_REMOVE_ADMIN_KEY
            );
        }
    }

    /// @dev Initiate process of edit of an admin,
    // If there are more then one admin all must call approveEditAdmin
    /// @param _admin Address of the admin requested to be removed

    function editAdmin(
        address _admin,
        LibAdminStorage.AdminAccess memory _adminAccess
    ) external onlyEditGovAdminRole(LibMeta.msgSender()) {
        LibAdminStorage.AdminStorage storage es = LibAdminStorage
            .adminRegistryStorage();

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
        require(
            es.pendingAdminKeys[es.PENDING_ADD_ADMIN_KEY].length == 0 &&
                es.pendingAdminKeys[es.PENDING_EDIT_ADMIN_KEY].length == 0 &&
                es.pendingAdminKeys[es.PENDING_REMOVE_ADMIN_KEY].length == 0,
            "GAR: only one admin can be add, edit, remove at once"
        );
        require(_admin != LibMeta.msgSender(), "GAR: self edit error");
        require(_admin != es.superAdmin, "GAR: superadmin error");

        require(
            LibAdmin._addressExists(_admin, es.allApprovedAdmins),
            "GAR: not admin"
        );

        require(!_adminAccess.superAdmin, "GAR: cannot assign super admin");

        //this admin is now in the pending list.
        LibAdmin._makePendingForAddEdit(
            _admin,
            _adminAccess,
            es.PENDING_EDIT_ADMIN_KEY
        );

        emit LibAdmin.NewAdminApproved(
            _admin,
            LibMeta.msgSender(),
            es.PENDING_EDIT_ADMIN_KEY
        );
    }

    /// @dev call approved the admin which is already added to pending by other admin
    // if all current admins call approveEditAdmin are complete the admin edits become active
    /// @param _admin Address of the new admin

    function approveEditAdmin(address _admin)
        external
        onlyEditGovAdminRole(LibMeta.msgSender())
    {
        LibAdminStorage.AdminStorage storage es = LibAdminStorage
            .adminRegistryStorage();

        require(
            isPending(LibMeta.msgSender()),
            "GAR: caller already in pending"
        );
        require(_admin != LibMeta.msgSender(), "GAR: call for self");

        //the admin that is adding _admin must not already have approved.
        require(
            LibAdmin._notAvailable(
                _admin,
                LibMeta.msgSender(),
                es.PENDING_EDIT_ADMIN_KEY
            ),
            "GAR: already approved"
        );

        require(
            LibAdmin._addressExists(
                _admin,
                es.pendingAdminKeys[es.PENDING_EDIT_ADMIN_KEY]
            ),
            "GAR: nonpending admin error"
        );

        es.areByAdmins[es.PENDING_EDIT_ADMIN_KEY][_admin].push(
            LibMeta.msgSender()
        );

        //if the _admin is approved by all other admins for removal
        if (this.isDoneByAll(_admin, es.PENDING_EDIT_ADMIN_KEY)) {
            // _admin is now an approved admin.
            LibAdmin._editAdmin(_admin);
            emit LibAdmin.AdminEditedApprovedByAll(
                _admin,
                es.approvedAdminRoles[_admin]
            );
        } else {
            emit LibAdmin.NewAdminApproved(
                _admin,
                LibMeta.msgSender(),
                es.PENDING_EDIT_ADMIN_KEY
            );
        }
    }

    function isAddGovAdminRole(address admin) external view returns (bool) {
        LibAdminStorage.AdminStorage storage es = LibAdminStorage
            .adminRegistryStorage();

        return es.approvedAdminRoles[admin].addGovAdmin;
    }

    /// @dev using this function externally in Gov Tier Level Smart Contract
    function isEditAdminAccessGranted(address admin)
        external
        view
        returns (bool)
    {
        LibAdminStorage.AdminStorage storage es = LibAdminStorage
            .adminRegistryStorage();

        return es.approvedAdminRoles[admin].editGovAdmin;
    }

    /// @dev using this function externally in other Smart Contracts
    function isAddTokenRole(address admin) external view returns (bool) {
        LibAdminStorage.AdminStorage storage es = LibAdminStorage
            .adminRegistryStorage();

        return es.approvedAdminRoles[admin].addToken;
    }

    /// @dev using this function externally in other Smart Contracts
    function isEditTokenRole(address admin) external view returns (bool) {
        LibAdminStorage.AdminStorage storage es = LibAdminStorage
            .adminRegistryStorage();

        return es.approvedAdminRoles[admin].editToken;
    }

    /// @dev using this function externally in other Smart Contracts
    function isAddSpAccess(address admin) external view returns (bool) {
        LibAdminStorage.AdminStorage storage es = LibAdminStorage
            .adminRegistryStorage();

        return es.approvedAdminRoles[admin].addSp;
    }

    /// @dev using this function externally in other Smart Contracts
    function isEditSpAccess(address admin) external view returns (bool) {
        LibAdminStorage.AdminStorage storage es = LibAdminStorage
            .adminRegistryStorage();

        return es.approvedAdminRoles[admin].editSp;
    }

    /// @dev using this function in loan smart contracts to withdraw network balance
    function isSuperAdminAccess(address admin) external view returns (bool) {
        LibAdminStorage.AdminStorage storage es = LibAdminStorage
            .adminRegistryStorage();

        return es.approvedAdminRoles[admin].superAdmin;
    }

    /// @dev Get approved admin roles
    /// @param _approvedAdmin address of the approved admin
    /// @return AdminAccess returns the roles of the approved admin
    function getApprovedAdminRoles(address _approvedAdmin)
        external
        view
        returns (LibAdminStorage.AdminAccess memory)
    {
        LibAdminStorage.AdminStorage storage es = LibAdminStorage
            .adminRegistryStorage();

        return es.approvedAdminRoles[_approvedAdmin];
    }

    function getPendingAdmins(uint256 _key)
        external
        view
        returns (address[] memory)
    {
        LibAdminStorage.AdminStorage storage es = LibAdminStorage
            .adminRegistryStorage();
        return es.pendingAdminKeys[_key];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

import {LibMeta} from "./../../shared/libraries/LibMeta.sol";
import {LibAdminStorage} from "./LibAdminStorage.sol";

library LibAdmin {
    event NewAdminApproved(
        address indexed _newAdmin,
        address indexed _addByAdmin,
        uint8 indexed _key
    );
    event NewAdminApprovedByAll(
        address indexed _newAdmin,
        LibAdminStorage.AdminAccess _adminAccess
    );
    event AdminRemovedByAll(
        address indexed _admin,
        address indexed _removedByAdmin
    );
    event AdminEditedApprovedByAll(
        address indexed _admin,
        LibAdminStorage.AdminAccess _adminAccess
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
        LibAdminStorage.AdminAccess _adminAccess
    );

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
        LibAdminStorage.AdminStorage storage s = LibAdminStorage
            .adminRegistryStorage();

        uint256 pendingKeyslength = s.PENDING_KEYS.length;
        for (uint256 k = 0; k < pendingKeyslength; k++) {
            if (_key == s.PENDING_KEYS[k]) {
                uint256 approveByAdminsLength = s
                .areByAdmins[_key][_newAdmin].length;
                for (uint256 i = 0; i < approveByAdminsLength; i++) {
                    if (s.areByAdmins[_key][_newAdmin][i] == _by) {
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
        LibAdminStorage.AdminAccess memory _adminAccess
    ) internal {
        LibAdminStorage.AdminStorage storage s = LibAdminStorage
            .adminRegistryStorage();

        //no need for approved by admin for the new  admin anymore.
        delete s.areByAdmins[s.PENDING_ADD_ADMIN_KEY][_newAdmin];
        // _newAdmin is now an approved admin.
        s.approvedAdminRoles[_newAdmin] = _adminAccess;
        //new key for mapping approvedAdminRoles
        s.allApprovedAdmins.push(_newAdmin);
    }

    /// @dev makes _newAdmin an approved admin and emits the event
    /// @param _newAdmin Address of the new admin
    /// @param _adminAccess access variables for _newadmin

    function _makeApproved(
        address _newAdmin,
        LibAdminStorage.AdminAccess memory _adminAccess
    ) internal {
        LibAdminStorage.AdminStorage storage s = LibAdminStorage
            .adminRegistryStorage();

        //no need for approved by admin for the new  admin anymore.
        delete s.areByAdmins[s.PENDING_ADD_ADMIN_KEY][_newAdmin];
        // _newAdmin is now an approved admin.
        s.approvedAdminRoles[_newAdmin] = _adminAccess;
        //new key for mapping approvedAdminRoles
        s.allApprovedAdmins.push(_newAdmin);
        _removePendingIndex(
            _getIndex(_newAdmin, s.pendingAdminKeys[s.PENDING_ADD_ADMIN_KEY]),
            s.PENDING_ADD_ADMIN_KEY
        );
    }

    /// @dev makes _newAdmin a pending admin for approval to be given by all current admins
    /// @param _newAdmin Address of the new admin
    /// @param _adminAccess access variables for _newadmin

    function _makePendingForAddEdit(
        address _newAdmin,
        LibAdminStorage.AdminAccess memory _adminAccess,
        uint8 _key
    ) internal {
        LibAdminStorage.AdminStorage storage s = LibAdminStorage
            .adminRegistryStorage();

        //the admin who is adding the new admin is approving _newAdmin by default
        s.areByAdmins[_key][_newAdmin].push(LibMeta.msgSender());
        //add _newAdmin to pendingAddedAdminRoles for approval  by all other current.
        s.pendingAdminRoles[_key][_newAdmin] = _adminAccess;
        s.pendingAdminKeys[_key].push(_newAdmin);
    }

    /// @dev remove _admin by the approved admins
    /// @param _admin Address of the approved admin

    function _removeAdmin(address _admin) internal {
        LibAdminStorage.AdminStorage storage s = LibAdminStorage
            .adminRegistryStorage();

        // _admin is now a removed admin.
        delete s.approvedAdminRoles[_admin];
        delete s.areByAdmins[s.PENDING_REMOVE_ADMIN_KEY][_admin];
        delete s.areByAdmins[s.PENDING_EDIT_ADMIN_KEY][_admin];
        delete s.areByAdmins[s.PENDING_ADD_ADMIN_KEY][_admin];
        delete s.pendingAdminRoles[s.PENDING_ADD_ADMIN_KEY][_admin];
        delete s.pendingAdminRoles[s.PENDING_EDIT_ADMIN_KEY][_admin];
        delete s.pendingAdminRoles[s.PENDING_REMOVE_ADMIN_KEY][_admin];

        //remove key for mapping approvedAdminRoles
        _removeIndex(_getIndex(_admin, s.allApprovedAdmins));
        _removePendingIndex(
            _getIndex(_admin, s.pendingAdminKeys[s.PENDING_REMOVE_ADMIN_KEY]),
            s.PENDING_REMOVE_ADMIN_KEY
        );
    }

    /// @dev edit admin roles of the approved admin
    /// @param _admin address which is going to be edited

    function _editAdmin(address _admin) internal {
        LibAdminStorage.AdminStorage storage s = LibAdminStorage
            .adminRegistryStorage();

        s.approvedAdminRoles[_admin] = s.pendingAdminRoles[
            s.PENDING_EDIT_ADMIN_KEY
        ][_admin];

        delete s.areByAdmins[s.PENDING_EDIT_ADMIN_KEY][_admin];
        delete s.pendingAdminRoles[s.PENDING_EDIT_ADMIN_KEY][_admin];
        _removePendingIndex(
            _getIndex(_admin, s.pendingAdminKeys[s.PENDING_EDIT_ADMIN_KEY]),
            s.PENDING_EDIT_ADMIN_KEY
        );
    }

    /// @dev remove the index of the approved admin address
    function _removeIndex(uint256 index) internal {
        LibAdminStorage.AdminStorage storage s = LibAdminStorage
            .adminRegistryStorage();

        uint256 length = s.allApprovedAdmins.length;
        for (uint256 i = index; i < length - 1; i++) {
            s.allApprovedAdmins[i] = s.allApprovedAdmins[i + 1];
        }
        s.allApprovedAdmins.pop();
    }

    /// @dev remove the pending admin index for that specific key
    function _removePendingIndex(uint256 index, uint8 key) internal {
        LibAdminStorage.AdminStorage storage s = LibAdminStorage
            .adminRegistryStorage();

        uint256 length = s.pendingAdminKeys[key].length;
        for (uint256 i = index; i < length - 1; i++) {
            s.pendingAdminKeys[key][i] = s.pendingAdminKeys[key][i + 1];
        }
        s.pendingAdminKeys[key].pop();
    }

    /// @dev makes _admin a pending admin for approval to be given by
    /// @dev all current admins for removing this admnin.
    /// @param _admin address of the new admin which is going pending for remove

    function _makePendingForRemove(address _admin, uint8 _key) internal {
        LibAdminStorage.AdminStorage storage s = LibAdminStorage
            .adminRegistryStorage();

        //the admin who is adding the new admin is approving _newAdmin by default
        s.areByAdmins[_key][_admin].push(LibMeta.msgSender());
        s.pendingAdminKeys[_key].push(_admin);
        //add _newAdmin to pendingAddedAdminRoles for approval  by all other current.
        s.pendingAdminRoles[_key][_admin] = s.approvedAdminRoles[_admin];
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
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

library LibMeta {
    function msgSender() internal view returns (address sender_) {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender_ := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender_ = msg.sender;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamond Standard: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

import {IDiamondCut} from "../interfaces/IDiamondCut.sol";
import {IDiamondLoupe} from "../interfaces/IDiamondLoupe.sol";
import {IERC165} from "../interfaces/IERC165.sol";
import {IERC173} from "../interfaces/IERC173.sol";
import {LibMeta} from "./LibMeta.sol";

library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION =
        keccak256("diamond.standard.diamond.storage");

    struct FacetAddressAndPosition {
        address facetAddress;
        uint16 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint16 facetAddressPosition; // position of facetAddress in facetAddresses array
    }

    struct DiamondStorage {
        // maps function selector to the facet address and
        // the position of the selector in the facetFunctionSelectors.selectors array
        mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
        // maps facet addresses to function selectors
        mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
        // facet addresses
        address[] facetAddresses;
        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;
        // owner of the contract
        address contractOwner;
    }

    function diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event OwnershipTransferredDiamond(
        address indexed previousOwner,
        address indexed newOwner
    );

    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferredDiamond(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    function enforceIsContractOwner() internal view {
        require(
            LibMeta.msgSender() == diamondStorage().contractOwner,
            "LibDiamond: Must be contract owner"
        );
    }

    event DiamondCut(
        IDiamondCut.FacetCut[] _diamondCut,
        address _init,
        bytes _calldata
    );

    function addDiamondFunctions(
        address _diamondCutFacet,
        address _diamondLoupeFacet,
        address _ownershipFacet
    ) internal {
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](3);
        bytes4[] memory functionSelectors = new bytes4[](1);
        functionSelectors[0] = IDiamondCut.diamondCut.selector;
        cut[0] = IDiamondCut.FacetCut({
            facetAddress: _diamondCutFacet,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: functionSelectors
        });
        functionSelectors = new bytes4[](5);
        functionSelectors[0] = IDiamondLoupe.facets.selector;
        functionSelectors[1] = IDiamondLoupe.facetFunctionSelectors.selector;
        functionSelectors[2] = IDiamondLoupe.facetAddresses.selector;
        functionSelectors[3] = IDiamondLoupe.facetAddress.selector;
        functionSelectors[4] = IERC165.supportsInterface.selector;
        cut[1] = IDiamondCut.FacetCut({
            facetAddress: _diamondLoupeFacet,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: functionSelectors
        });
        functionSelectors = new bytes4[](2);
        functionSelectors[0] = IERC173.transferOwnership.selector;
        functionSelectors[1] = IERC173.owner.selector;
        cut[2] = IDiamondCut.FacetCut({
            facetAddress: _ownershipFacet,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: functionSelectors
        });
        diamondCut(cut, address(0), "");
    }

    // Internal function version of diamondCut
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (
            uint256 facetIndex;
            facetIndex < _diamondCut.length;
            facetIndex++
        ) {
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
            } else if (action == IDiamondCut.FacetCutAction.Replace) {
                replaceFunctions(
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
            } else if (action == IDiamondCut.FacetCutAction.Remove) {
                removeFunctions(
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
            } else {
                revert("LibDiamondCut: Incorrect FacetCutAction");
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        require(
            _functionSelectors.length > 0,
            "LibDiamondCut: No selectors in facet to cut"
        );
        DiamondStorage storage ds = diamondStorage();
        // uint16 selectorCount = uint16(diamondStorage().selectors.length);
        require(
            _facetAddress != address(0),
            "LibDiamondCut: Add facet can't be address(0)"
        );
        uint16 selectorPosition = uint16(
            ds.facetFunctionSelectors[_facetAddress].functionSelectors.length
        );
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            enforceHasContractCode(
                _facetAddress,
                "LibDiamondCut: New facet has no code"
            );
            ds
                .facetFunctionSelectors[_facetAddress]
                .facetAddressPosition = uint16(ds.facetAddresses.length);
            ds.facetAddresses.push(_facetAddress);
        }
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds
                .selectorToFacetAndPosition[selector]
                .facetAddress;
            require(
                oldFacetAddress == address(0),
                "LibDiamondCut: Can't add function that already exists"
            );
            ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(
                selector
            );
            ds
                .selectorToFacetAndPosition[selector]
                .facetAddress = _facetAddress;
            ds
                .selectorToFacetAndPosition[selector]
                .functionSelectorPosition = selectorPosition;
            selectorPosition++;
        }
    }

    function replaceFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        require(
            _functionSelectors.length > 0,
            "LibDiamondCut: No selectors in facet to cut"
        );
        DiamondStorage storage ds = diamondStorage();
        require(
            _facetAddress != address(0),
            "LibDiamondCut: Add facet can't be address(0)"
        );
        uint16 selectorPosition = uint16(
            ds.facetFunctionSelectors[_facetAddress].functionSelectors.length
        );
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            enforceHasContractCode(
                _facetAddress,
                "LibDiamondCut: New facet has no code"
            );
            ds
                .facetFunctionSelectors[_facetAddress]
                .facetAddressPosition = uint16(ds.facetAddresses.length);
            ds.facetAddresses.push(_facetAddress);
        }
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds
                .selectorToFacetAndPosition[selector]
                .facetAddress;
            require(
                oldFacetAddress != _facetAddress,
                "LibDiamondCut: Can't replace function with same function"
            );
            removeFunction(oldFacetAddress, selector);
            // add function
            ds
                .selectorToFacetAndPosition[selector]
                .functionSelectorPosition = selectorPosition;
            ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(
                selector
            );
            ds
                .selectorToFacetAndPosition[selector]
                .facetAddress = _facetAddress;
            selectorPosition++;
        }
    }

    function removeFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        require(
            _functionSelectors.length > 0,
            "LibDiamondCut: No selectors in facet to cut"
        );
        DiamondStorage storage ds = diamondStorage();
        // if function does not exist then do nothing and return
        require(
            _facetAddress == address(0),
            "LibDiamondCut: Remove facet address must be address(0)"
        );
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds
                .selectorToFacetAndPosition[selector]
                .facetAddress;
            removeFunction(oldFacetAddress, selector);
        }
    }

    function removeFunction(address _facetAddress, bytes4 _selector) internal {
        DiamondStorage storage ds = diamondStorage();
        require(
            _facetAddress != address(0),
            "LibDiamondCut: Can't remove function that doesn't exist"
        );
        // an immutable function is a function defined directly in a diamond
        require(
            _facetAddress != address(this),
            "LibDiamondCut: Can't remove immutable function"
        );
        // replace selector with last selector, then delete last selector
        uint256 selectorPosition = ds
            .selectorToFacetAndPosition[_selector]
            .functionSelectorPosition;
        uint256 lastSelectorPosition = ds
            .facetFunctionSelectors[_facetAddress]
            .functionSelectors
            .length - 1;
        // if not the same then replace _selector with lastSelector
        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = ds
                .facetFunctionSelectors[_facetAddress]
                .functionSelectors[lastSelectorPosition];
            ds.facetFunctionSelectors[_facetAddress].functionSelectors[
                    selectorPosition
                ] = lastSelector;
            ds
                .selectorToFacetAndPosition[lastSelector]
                .functionSelectorPosition = uint16(selectorPosition);
        }
        // delete the last selector
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.pop();
        delete ds.selectorToFacetAndPosition[_selector];

        // if no more selectors for facet address then delete the facet address
        if (lastSelectorPosition == 0) {
            // replace facet address with last facet address and delete last facet address
            uint256 lastFacetAddressPosition = ds.facetAddresses.length - 1;
            uint256 facetAddressPosition = ds
                .facetFunctionSelectors[_facetAddress]
                .facetAddressPosition;
            if (facetAddressPosition != lastFacetAddressPosition) {
                address lastFacetAddress = ds.facetAddresses[
                    lastFacetAddressPosition
                ];
                ds.facetAddresses[facetAddressPosition] = lastFacetAddress;
                ds
                    .facetFunctionSelectors[lastFacetAddress]
                    .facetAddressPosition = uint16(facetAddressPosition);
            }
            ds.facetAddresses.pop();
            delete ds
                .facetFunctionSelectors[_facetAddress]
                .facetAddressPosition;
        }
    }

    function initializeDiamondCut(address _init, bytes memory _calldata)
        internal
    {
        if (_init == address(0)) {
            require(
                _calldata.length == 0,
                "LibDiamondCut: _init is address(0) but_calldata is not empty"
            );
        } else {
            require(
                _calldata.length > 0,
                "LibDiamondCut: _calldata is empty but _init is not address(0)"
            );
            if (_init != address(this)) {
                enforceHasContractCode(
                    _init,
                    "LibDiamondCut: _init address has no code"
                );
            }
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (success == false) {
                if (error.length > 0) {
                    // bubble up the error
                    revert(string(error));
                } else {
                    revert("LibDiamondCut: _init function reverted");
                }
            }
        }
    }

    function enforceHasContractCode(
        address _contract,
        string memory _errorMessage
    ) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize != 0, _errorMessage);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

library LibAdminStorage {
    bytes32 constant ADMINREGISTRY_STORAGE_POSITION =
        keccak256("diamond.standard.ADMINREGISTRY.storage");

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

    struct AdminStorage {
        mapping(address => AdminAccess) approvedAdminRoles; // approve admin roles for each address
        mapping(uint8 => mapping(address => AdminAccess)) pendingAdminRoles; // mapping of admin role keys to admin addresses to admin access roles
        mapping(uint8 => mapping(address => address[])) areByAdmins; // list of admins approved by other admins, for the specific key
        //admin role keys
        uint8 PENDING_ADD_ADMIN_KEY;
        uint8 PENDING_EDIT_ADMIN_KEY;
        uint8 PENDING_REMOVE_ADMIN_KEY;
        uint8[] PENDING_KEYS; // ADD: 0, EDIT: 1, REMOVE: 2
        address[] allApprovedAdmins; //list of all approved admin addresses
        address[][] pendingAdminKeys; //list of pending addresses for each key
        address superAdmin;
    }

    function adminRegistryStorage()
        internal
        pure
        returns (AdminStorage storage es)
    {
        bytes32 position = ADMINREGISTRY_STORAGE_POSITION;
        assembly {
            es.slot := position
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

// A loupe is a small magnifying glass used to look at diamonds.
// These functions look at diamonds
interface IDiamondLoupe {
    /// These functions are expected to be called frequently
    /// by tools.

    struct Facet {
        address facetAddress;
        bytes4[] functionSelectors;
    }

    /// @notice Gets all facet addresses and their four byte function selectors.
    /// @return facets_ Facet
    function facets() external view returns (Facet[] memory facets_);

    /// @notice Gets all the function selectors supported by a specific facet.
    /// @param _facet The facet address.
    /// @return facetFunctionSelectors_
    function facetFunctionSelectors(address _facet)
        external
        view
        returns (bytes4[] memory facetFunctionSelectors_);

    /// @notice Get all the facet addresses used by a diamond.
    /// @return facetAddresses_
    function facetAddresses()
        external
        view
        returns (address[] memory facetAddresses_);

    /// @notice Gets the facet that supports the given selector.
    /// @dev If facet is not found return address(0).
    /// @param _functionSelector The function selector.
    /// @return facetAddress_ The facet address.
    function facetAddress(bytes4 _functionSelector)
        external
        view
        returns (address facetAddress_);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceId The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
/******************************************************************************/

interface IDiamondCut {
    enum FacetCutAction {
        Add,
        Replace,
        Remove
    }

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

/// @title ERC-173 Contract Ownership Standard
///  Note: the ERC-165 identifier for this interface is 0x7f5828d0
/* is ERC165 */
interface IERC173 {
    /// @notice Get the address of the owner
    /// @return owner_ The address of the owner.
    function owner() external view returns (address owner_);

    /// @notice Set the address of the new owner of the contract
    /// @dev Set _newOwner to address(0) to renounce any ownership.
    /// @param _newOwner The address of the new owner of the contract
    function transferOwnership(address _newOwner) external;
}