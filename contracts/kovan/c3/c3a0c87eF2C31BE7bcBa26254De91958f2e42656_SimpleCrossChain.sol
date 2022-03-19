// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@routerprotocol/router-sdk/contracts/router-sdk/nonupgradeable/RouterCrossTalk.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract SimpleCrossChain is AccessControl, RouterCrossTalk {

    uint256 private value;

    constructor( address _genericHandler ) RouterCrossTalk(_genericHandler) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function setLinker ( address _linker ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        setLink(_linker);
    }

    function ExternalSend(uint8 _chainID , uint256 _value) public returns( bool ) {
        bytes memory data = abi.encode( _value);
        bytes4 _interface = bytes4(keccak256("InternalSet(uint256)"));
        bool success = routerSend(_chainID, _interface, data);
        return success;
    }

    function _routerSyncHandler( bytes4 _interface , bytes memory _data ) internal virtual override  returns ( bool , bytes memory ){
        (uint256 _v) = abi.decode(_data, ( uint256 ));
        (bool success, bytes memory returnData) = address(this).call( abi.encodeWithSelector(_interface, _v) );
        return (success, returnData);
    }

    function fetchI() external pure returns ( bytes4 ) {
        return bytes4(keccak256("InternalSet(uint256)"));
    }

    function InternalSet( uint256 _value ) external isSelf  {
        value = _value;
    }

    function fetchValue() external view returns (uint256) {
        return value;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "../../interfaces/iGenericHandler.sol";
import "./iRouterCrossTalk.sol";

abstract contract RouterCrossTalk is Context , iRouterCrossTalk, ERC165 {

    iGenericHandler handler;

    address private linkSetter;

    mapping ( uint8 => address ) private Chain2Addr; // CHain ID to Address

    modifier isHandler(){
        require(_msgSender() == address(handler) , "RouterCrossTalk : Only GenericHandler can call this function" );
        _;
    }

    modifier isLinkSet(uint8 _chainID){
        require(Chain2Addr[_chainID] == address(0) , "RouterCrossTalk : Cross Chain Contract to Chain ID set" );
        _;
    }

    modifier isLinkSync( uint8 _srcChainID, address _srcAddress ){
        require(Chain2Addr[_srcChainID] == _srcAddress , "RouterCrossTalk : Source Address Not linked" );
        _;
    }

    modifier isSelf(){
        require(_msgSender() == address(this) , "RouterCrossTalk : Can only be called by Current Contract" );
        _;
    }

    constructor( address _handler )  {
        handler = iGenericHandler(_handler);
    }

    /*
    * @notice Used to set linker address, this function is internal and can only be set by contract owner or admins
    * @param _addr Address of linker.
    */
    function setLink( address _addr ) internal {
        linkSetter = _addr;
    }

    function fetchHandler( ) external override view returns ( address ) {
        return address(handler);
    }

    function fetchLinkSetter( ) external override view returns( address) {
        return linkSetter;
    }

    function fetchLink( uint8 _chainID ) external override view returns( address) {
        return Chain2Addr[_chainID];
    }

    /*
    * @notice routerSend This is internal function to generate a cross chain communication request.
    * @param _destChainId Destination ChainID.
    * @param _selector Selector to interface on destination side.
    * @param _data Data to be sent on Destination side.
    */
    function routerSend( uint8 destChainId , bytes4 _selector , bytes memory _data ) internal returns (bool success) {
        uint8 cid = handler.fetch_chainID();
        bytes32 hash = _hash(address(this),Chain2Addr[destChainId],destChainId, _selector, _data);
        handler.genericDeposit(destChainId , _selector , _data, hash );
        emit CrossTalkSend( cid , destChainId , address(this), Chain2Addr[destChainId] ,_selector, _data , hash );
        return true;
    }

    function routerSync(uint8 srcChainID , address srcAddress , bytes4 _selector , bytes memory _data , bytes32 hash ) external override isLinkSync( srcChainID , srcAddress ) isHandler returns ( bool , bytes memory ) {
        uint8 cid = handler.fetch_chainID();
        bytes32 Dhash = _hash(Chain2Addr[srcChainID],address(this),cid, _selector, _data);
        require( Dhash == hash , "RouterSync : Valid Hash" );
        ( bool success , bytes memory _returnData ) = _routerSyncHandler( _selector , _data );
        emit CrossTalkReceive( srcChainID , cid , srcAddress , address(this), _selector, _data , hash );
        return ( success , _returnData );
    }

    /*
    * @notice _hash This is internal function to generate the hash of all data sent or received by the contract.
    * @param _srcAddres Source Address.
    * @param _destAddress Destination Address.
    * @param _destChainId Destination ChainID.
    * @param _selector Selector to interface on destination side.
    * @param _data Data to interface on Destination side.
    */
    function _hash(address _srcAddres , address _destAddress , uint8 _destChainId , bytes4 _selector , bytes memory _data) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            _srcAddres,
            _destAddress,
            _destChainId,
            _selector,
            keccak256(_data)
        ));
    }

    function Link(uint8 _chainID , address _linkedContract) external override isHandler isLinkSet(_chainID) {
        Chain2Addr[_chainID] = _linkedContract;
        emit Linkevent( _chainID , _linkedContract );
    }

    function Unlink(uint8 _chainID ) external override isHandler {
        emit Unlinkevent( _chainID , Chain2Addr[_chainID] );
        Chain2Addr[_chainID] = address(0);
    }

    /*
    * @notice _routerSyncHandler This is internal function to control the handling of various selectors and its corresponding .
    * @param _selector Selector to interface.
    * @param _data Data to be handled.
    */
    function _routerSyncHandler( bytes4 _selector , bytes memory _data ) internal virtual returns ( bool ,bytes memory );
    uint256[100] private __gap;

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface iGenericHandler {

    struct RouterLinker {
        address _rSyncContract;
        uint8 _chainID;
        address _linkedContract;
        uint8 linkerType;
    }

    /*
    * @notic UnMapContract Unmaps the contract from the RouterCrossTalk Contract
    * @param linker The Data object consisting of target Contract , CHainid , Contract to be Mapped and linker type.
    * @param _sign Signature of Linker data object signed by linkerSetter address.
    */
    function MapContract( RouterLinker calldata linker , bytes memory _sign ) external;

    /*
    * @notic UnMapContract Unmaps the contract from the RouterCrossTalk Contract
    * @param linker The Data object consisting of target Contract , CHainid , Contract to be unMapped and linker type.
    * @param _sign Signature of Linker data object signed by linkerSetter address.
    */
    function UnMapContract(RouterLinker calldata linker , bytes memory _sign ) external;

    /*
    * @notic generic deposit on generic handler contract
    * @param _chainid Chain id to be transacted
    * @param _selector Selector for the crosschain interface
    * @param _data Data to be transferred
    * @param _hash Hash of the data sent to the contract
    */
    function genericDeposit( uint8 _chainid, bytes4 _selector, bytes memory _data, bytes32 _hash ) external;


    /*
    * @notic fetches ChainID for the native chain
    */
    function fetch_chainID( ) external view returns ( uint8 );

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface iRouterCrossTalk is IERC165 {

    /*
    * @notice Link event is emitted when a new link is created.
    * @param _chainid Chain id the contract is linked to.
    * @param linkedContract Contract address linked to.
    */
    event Linkevent( uint8 indexed ChainID , address indexed linkedContract );

    /*
    * @notice UnLink event is emitted when a link is removed.
    * @param _chainid Chain id the contract is unlinked to.
    * @param linkedContract Contract address unlinked to.
    */
    event Unlinkevent( uint8 indexed ChainID , address indexed linkedContract );

    /*
    * @notice CrossTalkSend Event is emited when a request is generated in soruce side when cross chain request is generated.
    * @param sourceChain Source ChainID.
    * @param destChain Destination ChainID.
    * @param sourceAddress Source Address.
    * @param destinationAddress Destination Address.
    * @param _selector Selector to interface on destination side.
    * @param _data Data to interface on Destination side.
    * @param _hash Hash of the data sent.
    */
    event CrossTalkSend(uint8 indexed sourceChain , uint8 indexed destChain , address sourceAddress , address destinationAddress ,bytes4 indexed _selector, bytes _data , bytes32 _hash );

    /*
    * @notice CrossTalkReceive Event is emited when a request is recived in destination side when cross chain request accepted by contract.
    * @param sourceChain Source ChainID.
    * @param destChain Destination ChainID.
    * @param sourceAddress Source Address.
    * @param destinationAddress Destination Address.
    * @param _selector Selector to interface on destination side.
    * @param _data Data to interface on Destination side.
    * @param _hash Hash of the data sent.
    */
    event CrossTalkReceive(uint8 indexed sourceChain , uint8 indexed destChain , address sourceAddress , address destinationAddress ,bytes4 indexed _selector, bytes _data , bytes32 _hash );

    /*
    * @notice routerSync This is a public function and can only be called by Generic Handler of router infrastructure
    * @param srcChainID Source ChainID.
    * @param srcAddress Destination ChainID.
    * @param _selector Selector to interface on destination side.
    * @param _data Data to interface on Destination side.
    * @param _hash Hash of the data sent.
    */
    function routerSync(uint8 srcChainID , address srcAddress , bytes4 _selector , bytes calldata _data , bytes32 hash ) external returns ( bool , bytes memory );

    /*
    * @notice Link This is a public function and can only be called by Generic Handler of router infrastructure
    * @notice This function links contract on other chain ID's.
    * @notice This is an administrative function and can only be initiated by linkSetter address.
    * @param _chainID network Chain ID linked Contract linked to.
    * @param _linkedContract Linked Contract address.
    */
    function Link(uint8 _chainID , address _linkedContract) external;

    /*
    * @notice UnLink This is a public function and can only be called by Generic Handler of router infrastructure
    * @notice This function unLinks contract on other chain ID's.
    * @notice This is an administrative function and can only be initiated by linkSetter address.
    * @param _chainID network Chain ID linked Contract linked to.
    */
    function Unlink(uint8 _chainID ) external;

    /*
    * @notice fetchLinkSetter This is a public function and fetches the linksetter address.
    */
    function fetchLinkSetter( ) external view returns( address);

    /*
    * @notice fetchLinkSetter This is a public function and fetches the address the contract is linked to.
    * @param _chainID Chain ID information.
    */
    function fetchLink( uint8 _chainID ) external view returns( address);

    /*
    * @notice fetchLinkSetter This is a public function and fetches the generic handler address.
    */
    function fetchHandler( ) external view returns ( address );

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}