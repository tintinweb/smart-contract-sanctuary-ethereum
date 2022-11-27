// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./IThisabled1155.sol";

contract Thisabled1155Storefront is IThisabled1155, AccessControl {
    bytes32 public constant ACCOUNTANT_ROLE = keccak256("ACCOUNTANT_ROLE");
    bytes32 public constant CURATOR_ROLE = keccak256("CURATOR_ROLE");

    address public nftContractAddress;
    IThisabled1155 private thisabled1155Contract;

    uint256[] private forSaleList;
    mapping(uint256 => Artwork) private idToArtwork;

    struct Artwork {
        bool valid;
        bool paused;
        uint256 price;
    }

    struct ArtworkForSale {
        uint256 tokenId;
        string uri;
        uint256 availablePrints;
        uint256 maxPrints;
        uint256 price;
        bool paused;
    }

    event ArtworkAddedToStorefront(
        uint256 indexed tokenId,
        uint256 prints,
        uint256 price
    );

    event ArtworkRemovedFromStorefront(uint256 indexed tokenId);

    event ArtworkSalePaused(uint256 indexed tokenId);

    event ArtworkSaleUnpaused(uint256 indexed tokenId);

    event PrintSold(uint256 indexed tokenId, uint256 price, address buyer);

    constructor(address _nftContractAddress) {
        nftContractAddress = _nftContractAddress;
        thisabled1155Contract = IThisabled1155(_nftContractAddress);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    modifier validArtworkId(uint256 tokenId) {
        require(idToArtwork[tokenId].valid, "Invalid Token ID");
        _;
    }

    function checkSalePaused(uint256 tokenId)
        public
        view
        validArtworkId(tokenId)
        returns (bool)
    {
        return idToArtwork[tokenId].paused;
    }

    function pauseSale(uint256 tokenId)
        public
        onlyRole(CURATOR_ROLE)
        validArtworkId(tokenId)
    {
        require(!idToArtwork[tokenId].paused, "Artwork sale already paused");
        idToArtwork[tokenId].paused = true;
        emit ArtworkSalePaused(tokenId);
    }

    function unpauseSale(uint256 tokenId)
        public
        onlyRole(CURATOR_ROLE)
        validArtworkId(tokenId)
    {
        require(idToArtwork[tokenId].paused, "Artwork sale not paused");
        idToArtwork[tokenId].paused = false;
        emit ArtworkSaleUnpaused(tokenId);
    }

    function getPrice(uint256 tokenId)
        public
        view
        validArtworkId(tokenId)
        returns (uint256)
    {
        return idToArtwork[tokenId].price;
    }

    function updatePrice(uint256 tokenId, uint256 newPrice)
        public
        onlyRole(CURATOR_ROLE)
        validArtworkId(tokenId)
    {
        idToArtwork[tokenId].price = newPrice;
    }

    function getBalance()
        public
        view
        onlyRole(ACCOUNTANT_ROLE)
        returns (uint256)
    {
        return address(this).balance;
    }

    function withdrawETH(uint256 amount)
        public
        onlyRole(ACCOUNTANT_ROLE)
    {
        address payable to = payable(msg.sender);
        withdrawETHTo(to, amount);
    }

    function withdrawETHTo(address payable to, uint256 amount)
        public
        onlyRole(ACCOUNTANT_ROLE)
    {
        require(amount <= getBalance(), "Insufficent funds");
        to.transfer(amount);
    }

    function addArtworkToStorefront(string memory uri, uint256 prints, uint256 price, bool salePaused)
        public
        onlyRole(CURATOR_ROLE)
        returns (uint256)
    {
        require(prints > 0, "Print count must be non-zero");
        uint256 tokenId = thisabled1155Contract.addArtwork(uri, prints);
        idToArtwork[tokenId] = Artwork(true, salePaused, price);
        forSaleList.push(tokenId);
        emit ArtworkAddedToStorefront(tokenId, prints, price);
        if(salePaused){
            emit ArtworkSalePaused(tokenId);
        }
        return tokenId;
    }

    function batchAddArtworkToStorefront(string[] memory uris, uint256[] memory printCounts, uint256[] memory prices, bool[] memory salePausedList)
        public
        onlyRole(CURATOR_ROLE)
        returns (uint256[] memory)
    {
        require(uris.length == printCounts.length, "Every artwork must have a print count");
        require(uris.length == prices.length, "Every artwork must have a price");
        require(uris.length == salePausedList.length, "Every artwork must have a paused status");
        uint256 index;
        for(index = 0; index < uris.length; index++){
            require(printCounts[index] > 0, "Print count must be non-zero");
        }
        uint256[] memory tokenIds = thisabled1155Contract.batchAddArtwork(uris, printCounts);
        for(index = 0; index < tokenIds.length; index++){
            idToArtwork[tokenIds[index]] = Artwork(true, salePausedList[index], prices[index]);
            forSaleList.push(tokenIds[index]);
            emit ArtworkAddedToStorefront(
                tokenIds[index],
                printCounts[index],
                prices[index]
            );
            if(salePausedList[index]){
              emit ArtworkSalePaused(tokenIds[index]);
            }
        }
        return tokenIds;
    }

    function removeArtworkFromStorefront(uint256 tokenId)
        public
        onlyRole(CURATOR_ROLE)
        validArtworkId(tokenId)
    {
        delete idToArtwork[tokenId];
        //Remove token ID from artwork for sale listing
        for(uint256 i = 0; i < forSaleList.length; i++){
            if(forSaleList[i] == tokenId){
                forSaleList[i] = forSaleList[forSaleList.length - 1];
                forSaleList.pop();
                break;
            }
        }
        emit ArtworkRemovedFromStorefront(tokenId);
    }

    function getArtwork(uint256 tokenId)
        public
        view
        validArtworkId(tokenId)
        returns (ArtworkForSale memory)
    {
        string memory uri = thisabled1155Contract.tokenURI(tokenId);
        uint256 availablePrints = thisabled1155Contract.getAvailablePrints(tokenId);
        uint256 maxPrints = thisabled1155Contract.getMaxPrints(tokenId);
        ArtworkForSale memory artworkForSale = ArtworkForSale(
            tokenId,
            uri,
            availablePrints,
            maxPrints,
            idToArtwork[tokenId].price,
            idToArtwork[tokenId].paused
        );
        return artworkForSale;
    }

    function getAllArtwork()
        public
        view
        returns (ArtworkForSale[] memory)
    {
        ArtworkForSale[] memory artworkForSale = new ArtworkForSale[](forSaleList.length);
        uint256 tokenId;
        string memory uri;
        uint256 availablePrints;
        uint256 maxPrints;
        for(uint256 i = 0; i < forSaleList.length; i++){
            tokenId = forSaleList[i];
            uri = thisabled1155Contract.tokenURI(tokenId);
            availablePrints = thisabled1155Contract.getAvailablePrints(tokenId);
            maxPrints = thisabled1155Contract.getMaxPrints(tokenId);
            artworkForSale[i] = ArtworkForSale(
                tokenId,
                uri,
                availablePrints,
                maxPrints,
                idToArtwork[tokenId].price,
                idToArtwork[tokenId].paused
            );
        }
        return artworkForSale;
    }

    function mintArtwork(uint256 tokenId)
        public
        payable
        validArtworkId(tokenId)
    {
        require(!idToArtwork[tokenId].paused, "Artwork sale paused");
        require(msg.value == idToArtwork[tokenId].price, "Wrong price");
        require(thisabled1155Contract.getAvailablePrints(tokenId) > 0, "Artwork sold out");

        thisabled1155Contract.mint(msg.sender, tokenId, 1);
        emit PrintSold(tokenId, msg.value, msg.sender);
    }

    function batchMintArtwork(uint256[] memory tokenIds, uint256[] memory amounts)
        public
        payable
    {
        require(tokenIds.length == amounts.length, "Every token ID must have an amount");
        uint256 totalPrice;
        uint256 index;
        for(index = 0; index < tokenIds.length; index++){
          require(idToArtwork[tokenIds[index]].valid, "Invalid Token ID");
          require(!idToArtwork[tokenIds[index]].paused, "Artwork sale paused");
          require(thisabled1155Contract.getAvailablePrints(tokenIds[index]) - amounts[index] >= 0, "Amount requested exceeds available prints");
          totalPrice += idToArtwork[tokenIds[index]].price * amounts[index];
        }
        thisabled1155Contract.mintBatch(msg.sender, tokenIds, amounts);
        for(index = 0; index < tokenIds.length; index++){
          for(uint256 i = 0; i < amounts[index]; i++){
            emit PrintSold(tokenIds[index], idToArtwork[tokenIds[index]].price, msg.sender);
          }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

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
        _checkRole(role);
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
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
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
pragma solidity ^0.8.4;

abstract contract IThisabled1155{
	function addArtwork(string memory _uri, uint256 printCount) public virtual returns (uint256) {}
	function batchAddArtwork(string[] memory uris, uint256[] memory printCounts) public virtual	returns (uint256[] memory) {}
	function mint(address account, uint256 id, uint256 amount) public virtual {}
	function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts) public virtual {}
	function tokenURI(uint256 tokenId) public view virtual returns (string memory) {}
	function getMaxPrints(uint256 tokenId) public view virtual returns (uint256) {}
	function getAvailablePrints(uint256 tokenId) public view virtual returns (uint256) {}
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