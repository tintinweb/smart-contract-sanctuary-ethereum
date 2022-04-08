/**
 *Submitted for verification at Etherscan.io on 2022-04-07
*/

// Winding Tree
// Web:     https://windingtree.com/
// Discord: https://discord.gg/5Q3qde6Gr9
// File: @openzeppelin/contracts/math/SafeMath.sol

pragma solidity ^0.5.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/upgrades/contracts/Initializable.sol

pragma solidity >=0.4.24 <0.7.0;


/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

// File: contracts/ERC165/ERC165.sol

// SPDX-License-Identifier: MIT;
pragma solidity 0.5.17;

/**
 * @dev Custom implementation of the {IERC165} interface.
 * This is contract implemented by OpenZeppelin but extended with
 * _removeInterface function
 */
contract ERC165 {
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
     * @dev Interface of the ERC165 standard, as defined in the
     * https://eips.ethereum.org/EIPS/eip-165[EIP].
     * @param interfaceId Interface Id
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     * @param interfaceId Interface Id
     */
    function _registerInterface(bytes4 interfaceId) internal {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }

    /**
     * @dev Removes support of the interface
     * @param interfaceId Interface Id
     */
    function _removeInterface(bytes4 interfaceId) internal {
        require(_supportedInterfaces[interfaceId], "ERC165: unknown interface id");
        _supportedInterfaces[interfaceId] = false;
    }
}

// File: contracts/OwnablePatch.sol

// SPDX-License-Identifier: GPL-3.0-only;
pragma solidity 0.5.17;

/**
 * @title Ownable smart contract replacement.
 * Required for the saving of the order and composition of variables
 * in the OrgId storage due to upgrade to version 1.1.0
 */
contract OwnablePatch {
    address private _owner;
}

// File: contracts/OrgIdInterface.sol

// SPDX-License-Identifier: GPL-3.0-only;
pragma solidity 0.5.17;

/**
 * @title ORGiD Registry Smart Contract Interface
 */
contract OrgIdInterface {

    /**
     * @dev Create organization
     * @param salt Unique hash required for identifier creation
     * @param orgJsonHash ORG.JSON's keccak256 hash
     * @param orgJsonUri ORG.JSON URI (stored off-chain)
     * @param orgJsonUriBackup1 ORG.JSON URI backup (stored off-chain)
     * @param orgJsonUriBackup2 ORG.JSON URI backup (stored off-chain)
     * @return {
         "id": "ORGiD byte32 hash"
     }
     */
    function createOrganization(
        bytes32 salt,
        bytes32 orgJsonHash,
        string calldata orgJsonUri,
        string calldata orgJsonUriBackup1,
        string calldata orgJsonUriBackup2
    ) external returns (bytes32 id);

    /**
     * @dev Create organizational unit
     * @param salt Unique hash required for identifier creation
     * @param parentOrgId Parent ORGiD hash
     * @param director Unit director address
     * @param orgJsonHash ORG.JSON keccak256 hash
     * @param orgJsonUri Unit ORG.JSON URI
     * @param orgJsonUriBackup1 Unit ORG.JSON URI backup
     * @param orgJsonUriBackup2 Unit ORG.JSON URI backup
     */
    function createUnit(
        bytes32 salt,
        bytes32 parentOrgId,
        address director,
        bytes32 orgJsonHash,
        string calldata orgJsonUri,
        string calldata orgJsonUriBackup1,
        string calldata orgJsonUriBackup2
    )
        external
        returns (bytes32 newUnitOrgId);

    /**
     * @dev Toggle ORGiD's active/inactive state
     * @param orgId ORGiD hash
     */
    function toggleActiveState(bytes32 orgId) external;

    /**
     * @dev Accept director role
     * @param orgId Unit's ORGiD hash
     */
    function acceptDirectorship(bytes32 orgId) external;

    /**
     * @dev Transfer director role
     * @param orgId Unit's ORGiD hash
     * @param newDirector New director's address
     */
    function transferDirectorship(
        bytes32 orgId,
        address newDirector
    ) external;

    /**
     * @dev Unit directorship renounce
     * @param orgId Unit's ORGiD hash
     */
    function renounceDirectorship(bytes32 orgId)
        external;

    /**
     * @dev Ownership transfer
     * @param orgId ORGiD hash
     * @param newOwner New owner's address
     */
    function transferOrganizationOwnership(
        bytes32 orgId,
        address newOwner
    ) external;

    /**
     * @dev Shorthand method to change ORG.JSON URI and hash at once
     * @param orgId ORGiD hash
     * @param orgJsonHash New ORG.JSON's keccak256 hash
     * @param orgJsonUri New ORG.JSON URI
     * @param orgJsonUriBackup1 New ORG.JSON URI backup
     * @param orgJsonUriBackup2 New ORG.JSON URI backup
     */
    function setOrgJson(
        bytes32 orgId,
        bytes32 orgJsonHash,
        string calldata orgJsonUri,
        string calldata orgJsonUriBackup1,
        string calldata orgJsonUriBackup2
    ) external;

    /**
     * @dev Get all active organizations' ORGiD hashes
     * @param includeInactive Includes not active units into response
     * @return {
         "organizationsList": "Array of all active organizations' ORGiD hashes"
     }
     */
    function getOrganizations(bool includeInactive)
        external
        view
        returns (bytes32[] memory organizationsList);

    /**
     * @dev Get organization or unit's info by ORGiD hash
     * @param _orgId ORGiD hash
     * @dev Return parameters marked by (*) are only applicable to units
     * @return {
         "exists": "Returns `false` if ORGiD doesn't exist",
         "orgId": "ORGiD hash",
         "orgJsonHash": "ORG.JSON keccak256 hash",
         "orgJsonUri": "ORG.JSON URI",
         "orgJsonUriBackup1": "ORG.JSON URI backup",
         "orgJsonUriBackup2": "ORG.JSON URI backup",
         "parentOrgId": "Parent ORGiD (*)",
         "owner": "Owner's address",
         "director": "Unit director's address (*)",
         "isActive": "Indicates whether ORGiD is active",
         "isDirectorshipAccepted": "Indicates whether director accepted the role (*)"
     }
     */
    function getOrganization(bytes32 _orgId)
        external
        view
        returns (
            bool exists,
            bytes32 orgId,
            bytes32 orgJsonHash,
            string memory orgJsonUri,
            string memory orgJsonUriBackup1,
            string memory orgJsonUriBackup2,
            bytes32 parentOrgId,
            address owner,
            address director,
            bool isActive,
            bool isDirectorshipAccepted
        );

    /**
     * @dev Get all active organizational units of a particular ORGiD
     * @param parentOrgId Parent ORGiD hash
     * @param includeInactive Includes not active units into response
     * @return {
         "organizationsList": "Array of ORGiD hashes of active organizational units"
     }
     */
    function getUnits(bytes32 parentOrgId, bool includeInactive)
        external
        view
        returns (bytes32[] memory);
}

// File: contracts/OrgId.sol

// SPDX-License-Identifier: GPL-3.0-only;
pragma solidity 0.5.17;






/**
 * @title ORGiD Registry Smart Contract
 */
contract OrgId is OrgIdInterface, OwnablePatch, ERC165, Initializable {

    using SafeMath for uint256;

    /// @dev Organization structure
    struct Organization {
        bytes32 orgId;
        bytes32 orgJsonHash;
        string orgJsonUri;
        string orgJsonUriBackup1;
        string orgJsonUriBackup2;
        bytes32 parentOrgId;
        address owner;
        address director;
        bool isActive;
        bool isDirectorshipAccepted;
        bytes32[] units;
    }

    /// @dev Mapped list of Organizations
    mapping (bytes32 => Organization) internal organizations;

    /// @dev List of ORGiD hashes
    bytes32[] internal orgIds;

    /**
     * @dev Emits when new organization created
     */
    event OrganizationCreated(
        bytes32 indexed orgId,
        address indexed owner
    );

    /**
     * @dev Emits when new organizational unit created
     */
    event UnitCreated(
        bytes32 indexed parentOrgId,
        bytes32 indexed unitOrgId,
        address indexed director
    );

    /**
     * @dev Emits when organization active/inactive state changes
     */
    event OrganizationActiveStateChanged(
        bytes32 indexed orgId,
        bool previousState,
        bool newState
    );

    /**
     * @dev Emits when unit's directorship is accepted
     */
    event DirectorshipAccepted(
        bytes32 indexed orgId,
        address indexed director
    );

    /**
     * @dev Emits when unit's director changes
     */
    event DirectorshipTransferred(
        bytes32 indexed orgId,
        address indexed previousDirector,
        address indexed newDirector
    );

    /**
     * @dev Emits when ORGiD owner changes
     */
    event OrganizationOwnershipTransferred(
        bytes32 indexed orgId,
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Emits when ORG.JSON changes
     */
    event OrgJsonChanged(
        bytes32 indexed orgId,
        bytes32 indexed previousOrgJsonHash,
        string previousOrgJsonUri,
        string previousOrgJsonUriBackup1,
        string previousOrgJsonUriBackup2,
        bytes32 indexed newOrgJsonHash,
        string newOrgJsonUri,
        string newOrgJsonUriBackup1,
        string newOrgJsonUriBackup2
    );

    /**
     * @dev Throws if ORGiD does not exist
     */
    modifier orgIdMustExist(bytes32 orgId) {
        require(
            orgId != bytes32(0) &&
            organizations[orgId].orgId == orgId,
            "OrgId: Organization not found"
        );
        _;
    }

    /**
     * @dev Throws if called by non-owner
     */
    modifier mustBeCalledByOwner(bytes32 orgId) {
        require(
            organizations[orgId].owner == msg.sender,
            "OrgId: action not authorized (must be owner)"
        );
        _;
    }

    /**
     * @dev Throws if called by non-director
     */
    modifier mustBeCalledByOwnerOrDirector(bytes32 orgId) {
        require(
            organizations[orgId].owner == msg.sender ||
            organizations[orgId].director == msg.sender,
            "OrgId: action not authorized (must be owner or director)"
        );
        _;
    }

    /**
     * @dev Initializer for upgradeable contracts
     */
    function initialize() public initializer {
        _setInterfaces();
    }

    /**
     * @dev Initializer for the version 1.1.0
     */
    function initializeUpgrade110() public {
        // ownable interface has been removed in version 1.1.0
        _removeInterface(0x7f5828d0);
    }

    /**
     * @dev Create organization
     * @param salt Unique hash required for identifier creation
     * @param orgJsonHash ORG.JSON's keccak256 hash
     * @param orgJsonUri ORG.JSON URI (stored off-chain)
     * @param orgJsonUriBackup1 ORG.JSON URI backup (stored off-chain)
     * @param orgJsonUriBackup2 ORG.JSON URI backup (stored off-chain)
     * @return {
         "id": "ORGiD byte32 hash"
     }
     */
    function createOrganization(
        bytes32 salt,
        bytes32 orgJsonHash,
        string calldata orgJsonUri,
        string calldata orgJsonUriBackup1,
        string calldata orgJsonUriBackup2
    ) external returns (bytes32 id) {
        id = _createOrganization(
            salt,
            bytes32(0),
            address(0),
            orgJsonHash,
            orgJsonUri,
            orgJsonUriBackup1,
            orgJsonUriBackup2
        );
        emit OrganizationCreated(id, msg.sender);
    }

    /**
     * @dev Create organizational unit
     * @param salt Unique hash required for identifier creation
     * @param parentOrgId Parent ORGiD hash
     * @param director Unit director address
     * @param orgJsonHash ORG.JSON keccak256 hash
     * @param orgJsonUri Unit ORG.JSON URI
     * @param orgJsonUriBackup1 Unit ORG.JSON URI backup
     * @param orgJsonUriBackup2 Unit ORG.JSON URI backup
     */
    function createUnit(
        bytes32 salt,
        bytes32 parentOrgId,
        address director,
        bytes32 orgJsonHash,
        string calldata orgJsonUri,
        string calldata orgJsonUriBackup1,
        string calldata orgJsonUriBackup2
    )
        external
        orgIdMustExist(parentOrgId)
        mustBeCalledByOwner(parentOrgId)
        returns (bytes32 newUnitOrgId)
    {
        newUnitOrgId = _createOrganization(
            salt,
            parentOrgId,
            director,
            orgJsonHash,
            orgJsonUri,
            orgJsonUriBackup1,
            orgJsonUriBackup2
        );
        emit UnitCreated(parentOrgId, newUnitOrgId, director);

        // If parent ORGiD owner indicates their address as director,
        // their directorship is automatically accepted
        if (director == msg.sender) {
            emit DirectorshipAccepted(newUnitOrgId, msg.sender);
        }
    }

    /**
     * @dev Toggle ORGiD's active/inactive state
     * @param orgId ORGiD hash
     */
    function toggleActiveState(bytes32 orgId)
        external
        orgIdMustExist(orgId)
        mustBeCalledByOwner(orgId)
    {
        emit OrganizationActiveStateChanged(
            orgId,
            organizations[orgId].isActive,
            !organizations[orgId].isActive
        );
        organizations[orgId].isActive = !organizations[orgId].isActive;
    }

    /**
     * @dev Accept director role
     * @param orgId Unit's ORGiD hash
     */
    function acceptDirectorship(bytes32 orgId)
        external
        orgIdMustExist(orgId)
    {
        require(
            organizations[orgId].director == msg.sender,
            "OrgId: action not authorized (must be director)"
        );

        _acceptDirectorship(orgId);
    }

    /**
     * @dev Unit directorship transfer
     * @param orgId Unit's ORGiD hash
     * @param newDirector New director's address
     */
    function transferDirectorship(
        bytes32 orgId,
        address newDirector
    )
        external
        orgIdMustExist(orgId)
        mustBeCalledByOwner(orgId)
    {
        emit DirectorshipTransferred(
            orgId,
            organizations[orgId].director,
            newDirector
        );
        organizations[orgId].director = newDirector;

        if (newDirector == msg.sender) {
            organizations[orgId].isDirectorshipAccepted = true;
            emit DirectorshipAccepted(orgId, newDirector);
        } else {
            organizations[orgId].isDirectorshipAccepted = false;
        }
    }

    /**
     * @dev Unit directorship renounce
     * @param orgId Unit's ORGiD hash
     */
    function renounceDirectorship(bytes32 orgId)
        external
        orgIdMustExist(orgId)
        mustBeCalledByOwnerOrDirector(orgId)
    {
        emit DirectorshipTransferred(
            orgId,
            organizations[orgId].director,
            address(0)
        );

        organizations[orgId].director = address(0);
        organizations[orgId].isDirectorshipAccepted = false;
    }

    /**
     * @dev Ownership transfer
     * @param orgId ORGiD hash
     * @param newOwner New owner's address
     */
    function transferOrganizationOwnership(
        bytes32 orgId,
        address newOwner
    )
        external
        orgIdMustExist(orgId)
        mustBeCalledByOwner(orgId)
    {
        require(
            newOwner != address(0),
            "OrgId: Invalid owner address"
        );

        emit OrganizationOwnershipTransferred(
            orgId,
            organizations[orgId].owner,
            newOwner
        );
        organizations[orgId].owner = newOwner;
    }

    /**
     * @dev Shorthand method to change ORG.JSON URI and hash at once
     * @param orgId ORGiD hash
     * @param orgJsonHash New ORG.JSON's keccak256 hash
     * @param orgJsonUri New ORG.JSON URI
     * @param orgJsonUriBackup1 New ORG.JSON URI backup
     * @param orgJsonUriBackup2 New ORG.JSON URI backup
     */
    function setOrgJson(
        bytes32 orgId,
        bytes32 orgJsonHash,
        string calldata orgJsonUri,
        string calldata orgJsonUriBackup1,
        string calldata orgJsonUriBackup2
    )
        external
        orgIdMustExist(orgId)
        mustBeCalledByOwnerOrDirector(orgId)
    {
        require(
            orgJsonHash != bytes32(0),
            "OrgId: ORG.JSON hash cannot be zero"
        );
        require(
            bytes(orgJsonUri).length != 0,
            "OrgId: ORG.JSON URI cannot be empty"
        );

        if (msg.sender == organizations[orgId].director &&
            organizations[orgId].isDirectorshipAccepted == false) {
            _acceptDirectorship(orgId);
        }

        _updateOrgJson(
            orgId,
            orgJsonHash,
            orgJsonUri,
            orgJsonUriBackup1,
            orgJsonUriBackup2
        );
    }

    /**
     * @dev Get all active organizations' ORGiD hashes
     * @param includeInactive Includes not active organizations into response
     * @return {
         "organizationsList": "Array of all active organizations' ORGiD hashes"
     }
     */
    function getOrganizations(bool includeInactive)
        external
        view
        returns (bytes32[] memory)
    {
        return _getOrganizations(bytes32(0), includeInactive);
    }

    /**
     * @dev Get organization or unit's info by ORGiD hash
     * @param _orgId ORGiD hash
     * @dev Return parameters marked by (*) are only applicable to units
     * @return {
         "exists": "Returns `false` if ORGiD doesn't exist",
         "orgId": "ORGiD hash",
         "orgJsonHash": "ORG.JSON keccak256 hash",
         "orgJsonUri": "ORG.JSON URI",
         "orgJsonUriBackup1": "ORG.JSON URI backup",
         "orgJsonUriBackup2": "ORG.JSON URI backup",
         "parentOrgId": "Parent ORGiD (*)",
         "owner": "Owner's address",
         "director": "Unit director's address (*)",
         "isActive": "Indicates whether ORGiD is active",
         "isDirectorshipAccepted": "Indicates whether director accepted the role (*)"
     }
     */
    function getOrganization(bytes32 _orgId)
        external
        view
        returns (
            bool exists,
            bytes32 orgId,
            bytes32 orgJsonHash,
            string memory orgJsonUri,
            string memory orgJsonUriBackup1,
            string memory orgJsonUriBackup2,
            bytes32 parentOrgId,
            address owner,
            address director,
            bool isActive,
            bool isDirectorshipAccepted
        )
    {
        exists = _orgId != bytes32(0) && organizations[_orgId].orgId == _orgId;
        orgId = organizations[_orgId].orgId;
        orgJsonHash = organizations[_orgId].orgJsonHash;
        orgJsonUri = organizations[_orgId].orgJsonUri;
        orgJsonUriBackup1 = organizations[_orgId].orgJsonUriBackup1;
        orgJsonUriBackup2 = organizations[_orgId].orgJsonUriBackup2;
        parentOrgId = organizations[_orgId].parentOrgId;
        owner = organizations[_orgId].owner;
        director = organizations[_orgId].director;
        isActive = organizations[_orgId].isActive;
        isDirectorshipAccepted = organizations[_orgId].isDirectorshipAccepted;
    }

    /**
     * @dev Get all active organizational units of a particular ORGiD
     * @param parentOrgId Parent ORGiD hash
     * @param includeInactive Includes not active units into response
     * @return {
         "organizationsList": "Array of ORGiD hashes of active organizational units"
     }
     */
    function getUnits(bytes32 parentOrgId, bool includeInactive)
        external
        view
        orgIdMustExist(parentOrgId)
        returns (bytes32[] memory)
    {
        return _getOrganizations(parentOrgId, includeInactive);
    }

    /**
     * @dev Set supported contract interfaces
     */
    function _setInterfaces() internal {
        OrgIdInterface org;
        bytes4[3] memory interfaceIds = [
            // ERC165 interface: 0x01ffc9a7
            bytes4(0x01ffc9a7),

            // ORGiD interface: 0x0f4893ef
            org.createOrganization.selector ^
            org.toggleActiveState.selector ^
            org.transferOrganizationOwnership.selector ^
            org.setOrgJson.selector ^
            org.getOrganizations.selector ^
            org.getOrganization.selector,

            // hierarchy interface: 0x6af2fb27
            org.createUnit.selector ^
            org.acceptDirectorship.selector ^
            org.transferDirectorship.selector ^
            org.renounceDirectorship.selector ^
            org.getUnits.selector
        ];
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            _registerInterface(interfaceIds[i]);
        }
    }

    /**
     * @dev Create new organization and add it to storage
     * @param salt Unique hash required for identifier creation
     * @param parentOrgId Parent ORGiD hash (if applicable)
     * @param director Unit director address (if applicable)
     * @param orgJsonHash ORG.JSON keccak256 hash
     * @param orgJsonUri ORG.JSON URI
     * @param orgJsonUriBackup1 ORG.JSON URI backup
     * @param orgJsonUriBackup2 ORG.JSON URI backup
     * @return {
         "ORGiD": "New ORGiD hash"
     }
     */
    function _createOrganization(
        bytes32 salt,
        bytes32 parentOrgId,
        address director,
        bytes32 orgJsonHash,
        string memory orgJsonUri,
        string memory orgJsonUriBackup1,
        string memory orgJsonUriBackup2
    ) internal returns (bytes32) {
        require(
            parentOrgId == bytes32(0) ||
            (
                // If this is a unit...
                parentOrgId != bytes32(0) &&
                organizations[parentOrgId].orgId == parentOrgId
            ),
            "OrgId: Parent ORGiD not found"
        );

        // Organization unique Id creation
        bytes32 orgId = keccak256(
            abi.encodePacked(
                msg.sender,
                salt
            )
        );

        require(
            organizations[orgId].orgId == bytes32(0),
            "OrgId: Organizarion already exists"
        );

        organizations[orgId] = Organization(
            orgId,
            orgJsonHash,
            orgJsonUri,
            orgJsonUriBackup1,
            orgJsonUriBackup2,
            parentOrgId,
            msg.sender,
            director,
            true,
            director == msg.sender ||
                (parentOrgId != bytes32(0) && director == address(0)),
            new bytes32[](0)
        );
        orgIds.push(orgId);

        if (parentOrgId != bytes32(0)) {
            organizations[parentOrgId].units.push(orgId);
        }

        return orgId;
    }

    /**
     * @dev Get all active organizations' ORGiD hashes in the registry (if no input provided)
     * @dev OR, if input is a valid ORGiD, get all active units' ORGiD hashes
     * @param orgId ORGiD hash or zero bytes
     * @param includeInactive Includes not active organizations into response
     * @return {
         "organizationsList": "Array of ORGiD hashes"
     }
     */
    function _getOrganizations(bytes32 orgId, bool includeInactive)
        internal
        view
        returns (bytes32[] memory organizationsList)
    {
        bytes32[] memory source =
            orgId == bytes32(0)
            ? orgIds
            : organizations[orgId].units;
        organizationsList = new bytes32[](_getOrganizationsCount(orgId, includeInactive));
        uint256 index;

        for (uint256 i = 0; i < source.length; i++) {
            // If organization is active (OR  not active) AND
            // organization is top level (not unit) OR
            // organization is a unit AND directorship is accepted
            if ((
                    (!includeInactive && organizations[source[i]].isActive) ||
                    includeInactive
                ) &&
                (
                    (orgId == bytes32(0) && organizations[source[i]].parentOrgId == bytes32(0)) ||
                    orgId != bytes32(0)
                )) {

                organizationsList[index] = source[i];
                index += 1;
            }
        }
    }

    /**
     * @dev Get a number of active organizations in the registry (if input is zero bytes)
     * @dev OR, if input is a valid ORGiD, get a number of active organizational units
     * @param orgId ORGiD hash or zero bytes
     * @param includeInactive Includes not active organizations into response
     * @return {
         "count": "ORGiD count"
     }
     */
    function _getOrganizationsCount(bytes32 orgId, bool includeInactive)
        internal
        view
        returns (uint256 count)
    {
        bytes32[] memory source =
            orgId == bytes32(0)
            ? orgIds
            : organizations[orgId].units;

        for (uint256 i = 0; i < source.length; i++) {
            if ((
                    (!includeInactive && organizations[source[i]].isActive) ||
                    includeInactive
                ) &&
                (
                    (orgId == bytes32(0) && organizations[source[i]].parentOrgId == bytes32(0)) ||
                    orgId != bytes32(0)
                )) {

                count += 1;
            }
        }
    }

    /**
     * @dev Unit directorship acceptance
     * @param orgId ORGiD hash
     */
    function _acceptDirectorship(bytes32 orgId) internal {
        organizations[orgId].isDirectorshipAccepted = true;
        emit DirectorshipAccepted(orgId, msg.sender);
    }

    /**
     * @dev ORG.JSON storage update
     * @param orgId ORGiD hash
     * @param orgJsonHash ORG.JSON keccak256 hash
     * @param orgJsonUri ORG.JSON URI
     * @param orgJsonUriBackup1 ORG.JSON URI backup
     * @param orgJsonUriBackup2 ORG.JSON URI backup
     */
    function _updateOrgJson(
        bytes32 orgId,
        bytes32 orgJsonHash,
        string memory orgJsonUri,
        string memory orgJsonUriBackup1,
        string memory orgJsonUriBackup2
    ) internal {
        emit OrgJsonChanged(
            orgId,
            organizations[orgId].orgJsonHash,
            organizations[orgId].orgJsonUri,
            organizations[orgId].orgJsonUriBackup1,
            organizations[orgId].orgJsonUriBackup2,
            orgJsonHash,
            orgJsonUri,
            orgJsonUriBackup1,
            orgJsonUriBackup2
        );

        organizations[orgId].orgJsonHash = orgJsonHash;
        organizations[orgId].orgJsonUri = orgJsonUri;
        organizations[orgId].orgJsonUriBackup1 = orgJsonUriBackup1;
        organizations[orgId].orgJsonUriBackup2 = orgJsonUriBackup2;
    }
}