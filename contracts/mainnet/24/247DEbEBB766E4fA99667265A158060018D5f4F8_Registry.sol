/**
 *Submitted for verification at Etherscan.io on 2022-02-11
*/

// File: node_modules\@openzeppelin\contracts\introspection\IERC165.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: @openzeppelin\contracts\introspection\ERC165.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;


/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

// File: contracts\IRegistry.sol

pragma solidity ^0.6.0;

/**
  * @title Open registry for management of AI services run on SingularityNET
  * @author SingularityNET
  *
  */
interface IRegistry {

    //    ___                        _          _   _                   __  __                 _
    //   / _ \ _ __ __ _  __ _ _ __ (_)______ _| |_(_) ___  _ __       |  \/  | __ _ _ __ ___ | |_
    //  | | | | '__/ _` |/ _` | '_ \| |_  / _` | __| |/ _ \| '_ \      | |\/| |/ _` | '_ ` _ \| __|
    //  | |_| | | | (_| | (_| | | | | |/ / (_| | |_| | (_) | | | |     | |  | | (_| | | | | | | |_
    //   \___/|_|  \__, |\__,_|_| |_|_/___\__,_|\__|_|\___/|_| |_|     |_|  |_|\__, |_| |_| |_|\__|
    //             |___/                                                       |___/

    event OrganizationCreated (bytes32 indexed orgId);
    event OrganizationModified(bytes32 indexed orgId);
    event OrganizationDeleted (bytes32 indexed orgId);

    /**
      * @dev Adds a new organization that hosts SingularityNET services to the registry.
      *      Reverts if the given organization Id has already been registered.
      *
      * @param orgId    Id of organization to create, must be unique registry-wide.
      * @param orgMetadataURI  MetadataURI of organization to create, must be unique registry-wide.
      * @param members  Array of member addresses to seed the organization with.
      */
    function createOrganization(bytes32 orgId, bytes calldata orgMetadataURI, address[] calldata members) external;

    /**
      * @dev Updates the owner of the organization.
      *      Only the organization owner can invoke this method.
      *      Reverts if the given organization Id is unregistered.
      *
      * @param orgId     Id of organization to update.
      * @param newOwner  Address of new owner.
      */
    function changeOrganizationOwner(bytes32 orgId, address newOwner) external;

    /**
      * @dev Updates the name of the organization.
      *      Only the organization owner can invoke this method.
      *      Reverts if the given organization Id is unregistered.
      *
      * @param orgId     Id of organization to update.
      * @param orgMetadataURI   Name of the organization.
      */
    function changeOrganizationMetadataURI(bytes32 orgId, bytes calldata orgMetadataURI) external;

    /**
      * @dev Updates an organization to add members.
      *      Only an organization member can invoke this method.
      *      Reverts if the given organization Id is unregistered.
      *
      * @param orgId     Id of organization to update.
      * @param newMembers  Array of member addresses to add to an organization.
      */
    function addOrganizationMembers(bytes32 orgId, address[] calldata newMembers) external;

    /**
      * @dev Updates an organization to remove members.
      *      Only an organization member can invoke this method.
      *      Reverts if the given organization Id is unregistered.
      *
      * @param orgId          Id of organization to update.
      * @param existingMembers  Array of member addresses to remove from an organization.
      */
    function removeOrganizationMembers(bytes32 orgId, address[] calldata existingMembers) external;

    /**
      * @dev Removes an organization from the registry.
      *      Only the organization owner can invoke this method.
      *      Reverts if the given organization Id is unregistered
      *
      * @param orgId               Id of organization to remove.
      */
    function deleteOrganization(bytes32 orgId) external;


    //   ____                  _                __  __                 _
    //  / ___|  ___ _ ____   ___) ___ ___      |  \/  | __ _ _ __ ___ | |_
    //  \___ \ / _ \ '__\ \ / / |/ __/ _ \     | |\/| |/ _` | '_ ` _ \| __|
    //   ___) |  __/ |   \ V /| | (__  __/     | |  | | (_| | | | | | | |_
    //  |____/ \___|_|    \_/ |_|\___\___|     |_|  |_|\__, |_| |_| |_|\__|
    //                                                 |___/

    event ServiceCreated         (bytes32 indexed orgId, bytes32 indexed serviceId, bytes metadataURI);
    event ServiceMetadataModified(bytes32 indexed orgId, bytes32 indexed serviceId, bytes metadataURI);
    event ServiceTagsModified    (bytes32 indexed orgId, bytes32 indexed serviceId);
    event ServiceDeleted         (bytes32 indexed orgId, bytes32 indexed serviceId);

    /**
      * @dev Adds a new service to the registry.
      *      Only a member of the given organization can invoke this method.
      *      Reverts if the given organization does not exist or if the given service id has already been registered.
      *
      * @param orgId         Id of SingularityNET organization that owns this service.
      * @param serviceId     Id of the service to create, must be unique organization-wide.
      * @param metadataURI   Service metadata. metadataURI should contain information for data consistency 
      *                      validation (for example hash). We support: IPFS URI.
      */
    function createServiceRegistration(bytes32 orgId, bytes32 serviceId, bytes calldata metadataURI) external;

    /**
      * @dev Updates a service registration record.
      *      Only a member of the given organization can invoke this method.
      *      Reverts if the given organization or service does not exist.
      *
      * @param orgId          Id of SingularityNET organization that owns this service.
      * @param serviceId     Id of the service to update.
      * @param metadataURI   Service metadata URI
      */
    function updateServiceRegistration(bytes32 orgId, bytes32 serviceId, bytes calldata metadataURI) external;


    /**
      * @dev Removes a service from the registry.
      *      Only the owner of the given organization can invoke this method.
      *      Reverts if the given organization or service does not exist.
      *
      * @param orgId       Id of SingularityNET organization that owns this service.
      * @param serviceId   Id of the service to remove.
      */
    function deleteServiceRegistration(bytes32 orgId, bytes32 serviceId) external;


    //    ____      _   _
    //   / ___| ___| |_| |_ ___ _ __ ___
    //  | |  _ / _ \ __| __/ _ \ '__/ __|
    //  | |_| |  __/ |_| |_  __/ |  \__ \
    //   \____|\___|\__|\__\___|_|  |___/
    //

    /**
      * @dev Returns an array of Ids of all registered organizations.
      *
      * @return orgIds Array of Ids of all registered organizations.
      */
    function listOrganizations() external view returns (bytes32[] memory orgIds);

    /**
      * @dev Retrieves the detailed registration information of a single organization.
      *
      * @param orgId            Id of the organization to look up.
      * @return found           true if an organization with this id exists, false otherwise. If false, all other
      *                         returned fields should be ignored.
      * @return id              Id of organization, should be the same as the orgId parameter.
      * @return orgMetadataURI  Organization Metadata URI
      * @return owner           Address of the owner of the organization.
      * @return members         Array of addresses of the members of this organization.
      * @return serviceIds      Array of ids of services owned by the organization.
      */
    function getOrganizationById(bytes32 orgId) external view
            returns (bool found, bytes32 id, bytes memory orgMetadataURI, address owner, address[] memory members, bytes32[] memory serviceIds);

    /**
      * @dev Returns an array of ids of all services owned by a given organization.
      *
      * @param orgId          Id of the organization whose services to list.
      *
      * @return found         true if an organization with this id exists, false otherwise. If false, all other
      *                       returned fields should be ignored.
      * @return serviceIds    Array of ids of all services owned by this organization.
      */
    function listServicesForOrganization(bytes32 orgId) external view returns (bool found, bytes32[] memory serviceIds);

    /**
      * @dev Retrieves the detailed registration information of a single service.
      *
      * @param orgId         Id of the organization that owns the service to look up.
      * @param serviceId     Id of the service to look up.
      *
      * @return found        true if an organization and service with these ids exists, false otherwise. If false, all other
      *                      returned fields should be ignored.
      * @return id           Id of the service, should be the same as the serviceId parameter.
      * @return metadataURI  Service metadata URI
      */
    function getServiceRegistrationById(bytes32 orgId, bytes32 serviceId) external view
            returns (bool found, bytes32 id, bytes memory metadataURI);

}

// File: contracts\Registry.sol

pragma solidity ^0.6.0;



contract Registry is IRegistry, ERC165 {

    struct OrganizationRegistration {
        bytes32 organizationId;
        bytes orgMetadataURI;
        address owner;

        // member indexing note:
        // case (members[someAddress]) of
        //   0 -> not a member of this org
        //   n -> member of this org, and memberKeys[n-1] == someAddress
        address[] memberKeys;
        mapping(address => uint) members;

        bytes32[] serviceKeys;
        mapping(bytes32 => ServiceRegistration) servicesById;

        uint globalOrgIndex;
    }

    struct ServiceRegistration {
        bytes32 serviceId;
        bytes   metadataURI;   //Service metadata. metadataURI should contain information for data consistency 
                               //validation (for example hash). We support: IPFS URI.

        uint orgServiceIndex;
    }

    bytes32[] orgKeys;
    mapping(bytes32 => OrganizationRegistration) orgsById;

    constructor ()
    public
    {
        //ERC165: https://eips.ethereum.org/EIPS/eip-165
        _registerInterface(0x3f2242ea);

    }


    /**
      * @dev Guard function that forces a revert if the tx sender is unauthorized.
      *      Always authorizes org owner. Can also authorize org members.
      *
      * @param membersAllowed if true, revert when sender is non-owner and non-member, else revert when sender is non-owner
      */
    function requireAuthorization(bytes32 orgId, bool membersAllowed) internal view {
        require(msg.sender == orgsById[orgId].owner || (membersAllowed && orgsById[orgId].members[msg.sender] > 0)
            , "unauthorized invocation");
    }

    /**
      * @dev Guard function that forces a revert if the referenced org does not meet an existence criteria.
      *
      * @param exists if true, revert when org does not exist, else revert when org exists
      */
    function requireOrgExistenceConstraint(bytes32 orgId, bool exists) internal view {
        if (exists) {
            require(orgsById[orgId].organizationId != bytes32(0x0), "org does not exist");
        } else {
            require(orgsById[orgId].organizationId == bytes32(0x0), "org already exists");
        }
    }

    /**
      * @dev Guard function that forces a revert if the referenced service does not meet an existence criteria.
      *
      * @param exists if true, revert when service does not exist, else revert when service exists
      */
    function requireServiceExistenceConstraint(bytes32 orgId, bytes32 serviceId, bool exists) internal view {
        if (exists) {
            require(orgsById[orgId].servicesById[serviceId].serviceId != bytes32(0x0), "service does not exist");
        } else {
            require(orgsById[orgId].servicesById[serviceId].serviceId == bytes32(0x0), "service already exists");
        }
    }

    //    ___                        _          _   _                   __  __                 _
    //   / _ \ _ __ __ _  __ _ _ __ (_)______ _| |_(_) ___  _ __       |  \/  | __ _ _ __ ___ | |_
    //  | | | | '__/ _` |/ _` | '_ \| |_  / _` | __| |/ _ \| '_ \      | |\/| |/ _` | '_ ` _ \| __|
    //  | |_| | | | (_| | (_| | | | | |/ / (_| | |_| | (_) | | | |     | |  | | (_| | | | | | | |_
    //   \___/|_|  \__, |\__,_|_| |_|_/___\__,_|\__|_|\___/|_| |_|     |_|  |_|\__, |_| |_| |_|\__|
    //             |___/                                                       |___/

    function createOrganization(bytes32 orgId, bytes calldata orgMetadataURI, address[] calldata members) external override {

        requireOrgExistenceConstraint(orgId, false);

        OrganizationRegistration memory organization;
        orgsById[orgId] = organization;
        orgsById[orgId].organizationId = orgId;
        orgsById[orgId].orgMetadataURI = orgMetadataURI;
        orgsById[orgId].owner = msg.sender;
        orgsById[orgId].globalOrgIndex = orgKeys.length;
        orgKeys.push(orgId);

        addOrganizationMembersInternal(orgId, members);

        emit OrganizationCreated(orgId);
    }

    function changeOrganizationOwner(bytes32 orgId, address newOwner) external override {

        requireOrgExistenceConstraint(orgId, true);
        requireAuthorization(orgId, false);

        orgsById[orgId].owner = newOwner;

        emit OrganizationModified(orgId);
    }

    function changeOrganizationMetadataURI(bytes32 orgId, bytes calldata orgMetadataURI) external override {

        requireOrgExistenceConstraint(orgId, true);
        requireAuthorization(orgId, false);

        orgsById[orgId].orgMetadataURI = orgMetadataURI;

        emit OrganizationModified(orgId);
    }

    function addOrganizationMembers(bytes32 orgId, address[] calldata newMembers) external override {

        requireOrgExistenceConstraint(orgId, true);
        requireAuthorization(orgId, true);

        addOrganizationMembersInternal(orgId, newMembers);

        emit OrganizationModified(orgId);
    }

    function addOrganizationMembersInternal(bytes32 orgId, address[] memory newMembers) internal {
        for (uint i = 0; i < newMembers.length; i++) {
            if (orgsById[orgId].members[newMembers[i]] == 0) {
                orgsById[orgId].memberKeys.push(newMembers[i]);
                orgsById[orgId].members[newMembers[i]] = orgsById[orgId].memberKeys.length;
            }
        }
    }

    function removeOrganizationMembers(bytes32 orgId, address[] calldata existingMembers) external override {

        requireOrgExistenceConstraint(orgId, true);
        requireAuthorization(orgId, true);

        for (uint i = 0; i < existingMembers.length; i++) {
            removeOrganizationMemberInternal(orgId, existingMembers[i]);
        }

        emit OrganizationModified(orgId);
    }

    function removeOrganizationMemberInternal(bytes32 orgId, address existingMember) internal {
        // see "member indexing note"
        if (orgsById[orgId].members[existingMember] != 0) {
            uint storedIndexToRemove = orgsById[orgId].members[existingMember];
            address memberToMove = orgsById[orgId].memberKeys[orgsById[orgId].memberKeys.length - 1];

            // no-op if we are deleting the last entry
            if (orgsById[orgId].memberKeys[storedIndexToRemove - 1] != memberToMove) {
                // swap lut entries
                orgsById[orgId].memberKeys[storedIndexToRemove - 1] = memberToMove;
                orgsById[orgId].members[memberToMove] = storedIndexToRemove;
            }

            // shorten keys array
            orgsById[orgId].memberKeys.pop();

            // delete the mapping entry
            delete orgsById[orgId].members[existingMember];
        }
    }

    function deleteOrganization(bytes32 orgId) external override {

        requireOrgExistenceConstraint(orgId, true);
        requireAuthorization(orgId, false);

        for (uint serviceIndex = orgsById[orgId].serviceKeys.length; serviceIndex > 0; serviceIndex--) {
            deleteServiceRegistrationInternal(orgId, orgsById[orgId].serviceKeys[serviceIndex-1]);
        }

        for (uint memberIndex = orgsById[orgId].memberKeys.length; memberIndex > 0; memberIndex--) {
            removeOrganizationMemberInternal(orgId, orgsById[orgId].memberKeys[memberIndex-1]);
        }

        // swap lut entries
        uint    indexToUpdate = orgsById[orgId].globalOrgIndex;
        bytes32 orgToUpdate   = orgKeys[orgKeys.length-1];

        if (orgKeys[indexToUpdate] != orgToUpdate) {
            orgKeys[indexToUpdate] = orgToUpdate;
            orgsById[orgToUpdate].globalOrgIndex = indexToUpdate;
        }

        // shorten keys array
        orgKeys.pop();

        // delete contents of organization registration
        delete orgsById[orgId];

        emit OrganizationDeleted(orgId);
    }

    //   ____                  _                __  __                 _
    //  / ___|  ___ _ ____   ___) ___ ___      |  \/  | __ _ _ __ ___ | |_
    //  \___ \ / _ \ '__\ \ / / |/ __/ _ \     | |\/| |/ _` | '_ ` _ \| __|
    //   ___) |  __/ |   \ V /| | (__  __/     | |  | | (_| | | | | | | |_
    //  |____/ \___|_|    \_/ |_|\___\___|     |_|  |_|\__, |_| |_| |_|\__|
    //                                                 |___/

    function createServiceRegistration(bytes32 orgId, bytes32 serviceId, bytes calldata metadataURI) external override {

        requireOrgExistenceConstraint(orgId, true);
        requireAuthorization(orgId, true);
        requireServiceExistenceConstraint(orgId, serviceId, false);

        ServiceRegistration memory service;
        service.serviceId     = serviceId;
        service.metadataURI     = metadataURI;
        service.orgServiceIndex = orgsById[orgId].serviceKeys.length;
        orgsById[orgId].servicesById[serviceId] = service;
        orgsById[orgId].serviceKeys.push(serviceId);

        emit ServiceCreated(orgId, serviceId, metadataURI);
    }

    function updateServiceRegistration(bytes32 orgId, bytes32 serviceId, bytes calldata metadataURI) external override {

        requireOrgExistenceConstraint(orgId, true);
        requireAuthorization(orgId, true);
        requireServiceExistenceConstraint(orgId, serviceId, true);

        orgsById[orgId].servicesById[serviceId].metadataURI = metadataURI;

        emit ServiceMetadataModified(orgId, serviceId, metadataURI);
    }

    function deleteServiceRegistration(bytes32 orgId, bytes32 serviceId) external override {

        requireOrgExistenceConstraint(orgId, true);
        requireAuthorization(orgId, true);
        requireServiceExistenceConstraint(orgId, serviceId, true);

        deleteServiceRegistrationInternal(orgId, serviceId);

        emit ServiceDeleted(orgId, serviceId);
    }

    function deleteServiceRegistrationInternal(bytes32 orgId, bytes32 serviceId) internal {

        // swap lut entries
        uint    indexToUpdate   = orgsById[orgId].servicesById[serviceId].orgServiceIndex;
        bytes32 serviceToUpdate = orgsById[orgId].serviceKeys[orgsById[orgId].serviceKeys.length-1];

        if (orgsById[orgId].serviceKeys[indexToUpdate] != serviceToUpdate) {
            orgsById[orgId].serviceKeys[indexToUpdate] = serviceToUpdate;
            orgsById[orgId].servicesById[serviceToUpdate].orgServiceIndex = indexToUpdate;
        }

        orgsById[orgId].serviceKeys.pop();

        // delete contents of service registration
        delete orgsById[orgId].servicesById[serviceId];
    }

    //    ____      _   _
    //   / ___| ___| |_| |_ ___ _ __ ___
    //  | |  _ / _ \ __| __/ _ \ '__/ __|
    //  | |_| |  __/ |_| |_  __/ |  \__ \
    //   \____|\___|\__|\__\___|_|  |___/
    //

    function listOrganizations() external override view returns (bytes32[] memory orgIds) {
        return orgKeys;
    }

    function getOrganizationById(bytes32 orgId) external override view
            returns(bool found, bytes32 id, bytes memory orgMetadataURI, address owner, address[] memory members, bytes32[] memory serviceIds) {

        // check to see if this organization exists
        if(orgsById[orgId].organizationId == bytes32(0x0)) {
            found = false;
        } 
        else {
            found = true;
            id = orgsById[orgId].organizationId;
            orgMetadataURI = orgsById[orgId].orgMetadataURI;
            owner = orgsById[orgId].owner;
            members = orgsById[orgId].memberKeys;
            serviceIds = orgsById[orgId].serviceKeys;
        }


    }

    function listServicesForOrganization(bytes32 orgId) external override view returns (bool found, bytes32[] memory serviceIds) {

        // check to see if this organization exists
        if(orgsById[orgId].organizationId == bytes32(0x0)) {
            found = false;
        }
        else {
            found = true;
            serviceIds = orgsById[orgId].serviceKeys;
        }
    }

    function getServiceRegistrationById(bytes32 orgId, bytes32 serviceId) external override view
            returns (bool found, bytes32 id, bytes memory metadataURI) {

        // check to see if this organization exists
        if(orgsById[orgId].organizationId == bytes32(0x0)) {
            found = false;
        } 
        else if(orgsById[orgId].servicesById[serviceId].serviceId == bytes32(0x0)) {
            // check to see if this repo exists
            found = false;
        }
        else {
            found        = true;
            id           = orgsById[orgId].servicesById[serviceId].serviceId;
            metadataURI  = orgsById[orgId].servicesById[serviceId].metadataURI;
        }

    }

    // ERC165: https://eips.ethereum.org/EIPS/eip-165
    //function supportsInterface(bytes4 interfaceID) external view returns (bool) {
    //    return
    //        interfaceID == this.supportsInterface.selector || // ERC165
    //        interfaceID == 0x3f2242ea; // IRegistry
    //}
}