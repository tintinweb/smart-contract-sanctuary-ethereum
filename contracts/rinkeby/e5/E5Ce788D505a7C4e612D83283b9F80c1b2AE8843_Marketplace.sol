//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./interfaces/IGunGirls1155.sol";
import "./interfaces/IGunGirls721.sol";
import "./interfaces/IQoukkaToken.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract Data {
    address internal ERC721address;
    address internal ERC1155address;
    address internal ERC20address;
    address internal creator;
    bytes32 internal constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    enum Status{Owned, OnSale, OnAuction}

    mapping (uint => Info721) public tokenId721;
    mapping (uint => uint) internal numberOfBids721;

    struct Info721 {
        address owner;
        address bestBider;
        uint bestOffer;
        uint auctionDeadline;
        Status tokenStatus;
    }

    mapping (uint => mapping (address => Info1155)) public tokenId1155;

    struct Info1155 {
        uint amount;
        address owner;
        address bestBider;
        uint bestOffer;
        uint auctionDeadline;
        uint numberOfBids1155;
        Status tokenStatus;
    }
}

contract Marketplace is Data, AccessControl {
    constructor(address erc721, address erc1155, address erc20) {
        creator = msg.sender;
        ERC721address = erc721;
        ERC1155address = erc1155;
        ERC20address = erc20;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
    }

    function _onlyCreator() private view {
        require(msg.sender == creator, "Not Creator");
    }

    function _isAdmin() private view {
        require(hasRole(ADMIN_ROLE, msg.sender), "Not Admin");
    }

    function giveAdminRights (address account) external {
        _onlyCreator();
        _grantRole(ADMIN_ROLE, account);
    }

    function revokeAdminRights (address account) external {
        _onlyCreator();
        _revokeRole(ADMIN_ROLE, account);
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public pure returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function listItem721(uint tokenId, uint priceQTN) external {
        require(tokenId721[tokenId].tokenStatus == Status.Owned, "Status not Owned");

        IGunGirls721(ERC721address).safeTransferFrom(msg.sender, address(this), tokenId);

        tokenId721[tokenId].owner = msg.sender;
        tokenId721[tokenId].bestOffer = priceQTN;
        tokenId721[tokenId].tokenStatus = Status.OnSale;
    }
    

    function buyItem721(uint tokenId) external {
        require(tokenId721[tokenId].tokenStatus == Status.OnSale, "Not on sale");

        IQoukkaToken(ERC20address).transferFrom(
            msg.sender,
            tokenId721[tokenId].owner,
            tokenId721[tokenId].bestOffer
            );

        IGunGirls721(ERC721address).transferFrom(address(this), msg.sender, tokenId);

        tokenId721[tokenId].owner = msg.sender;
        tokenId721[tokenId].bestOffer = 0;
        tokenId721[tokenId].tokenStatus = Status.Owned;
    }

    function cancelList721(uint tokenId) external {
        require(msg.sender == tokenId721[tokenId].owner, "Not owner");
        require(tokenId721[tokenId].tokenStatus == Status.OnSale, "Not on sale");

        IGunGirls721(ERC721address).transferFrom(address(this), tokenId721[tokenId].owner, tokenId);

        tokenId721[tokenId].owner = msg.sender;
        tokenId721[tokenId].bestOffer = 0;
        tokenId721[tokenId].tokenStatus = Status.Owned;
    }

    function createItem721(address recipient) external {
        _isAdmin();
        IGunGirls721(ERC721address).mintTo(recipient);
    }

    function createItem1155(address recipient, uint id, uint amount) external {
        _isAdmin();
        IGunGirls1155(ERC1155address).mint(recipient, id, amount, bytes("0"));
    }

    function listItem1155(uint tokenId, uint amount, uint priceQTN) external {
        require(tokenId1155[tokenId][msg.sender].tokenStatus == Status.Owned, "Status not Owned");

        IGunGirls1155(ERC1155address).safeTransferFrom(
            msg.sender, address(this),
            tokenId,
            amount,
            bytes("0")
        );

        tokenId1155[tokenId][msg.sender].owner = msg.sender;
        tokenId1155[tokenId][msg.sender].amount = amount;
        tokenId1155[tokenId][msg.sender].bestOffer = priceQTN;
        tokenId1155[tokenId][msg.sender].tokenStatus = Status.OnSale;
    }

    function buyItem1155(uint tokenId, address seller) external {
        require(tokenId1155[tokenId][seller].tokenStatus == Status.OnSale, "Not on sale");

        IQoukkaToken(ERC20address).transferFrom(
            msg.sender,
            tokenId1155[tokenId][seller].owner,
            tokenId1155[tokenId][seller].bestOffer
            );

        IGunGirls1155(ERC1155address).safeTransferFrom(
            address(this),
            msg.sender,
            tokenId,
            tokenId1155[tokenId][seller].amount,
            bytes("0")
            ); 

        tokenId1155[tokenId][msg.sender].owner = msg.sender;
        tokenId1155[tokenId][msg.sender].amount += tokenId1155[tokenId][seller].amount;

        tokenId1155[tokenId][seller].amount = 0;   
    }

    function cancelList1155(uint tokenId) external {
        require(msg.sender == tokenId1155[tokenId][msg.sender].owner, "Not owner");
        require(tokenId1155[tokenId][msg.sender].tokenStatus == Status.OnSale, "Not on sale");

        IGunGirls1155(ERC1155address).safeTransferFrom(
            address(this),
            msg.sender,
            tokenId,
            tokenId1155[tokenId][msg.sender].amount,
            bytes("0")
            );

        tokenId1155[tokenId][msg.sender].owner = msg.sender;
        tokenId1155[tokenId][msg.sender].bestOffer = 0;
        tokenId1155[tokenId][msg.sender].tokenStatus = Status.Owned;
    }

    function listOnAuction721(uint tokenId, uint startPriceQTN) external {
        require(tokenId721[tokenId].tokenStatus == Status.Owned, "Status not Owned");

        IGunGirls721(ERC721address).safeTransferFrom(msg.sender, address(this), tokenId);

        tokenId721[tokenId].owner = msg.sender;
        tokenId721[tokenId].bestOffer = startPriceQTN;
        tokenId721[tokenId].tokenStatus = Status.OnAuction;
        tokenId721[tokenId].auctionDeadline = block.timestamp + 3 days;
    }

    function makeBid721(uint tokenId, uint amountQTN) external {
        require(tokenId721[tokenId].tokenStatus == Status.OnAuction, "Not on auction");
        require(amountQTN > tokenId721[tokenId].bestOffer, "Best offer is higher");
        require(block.timestamp < tokenId721[tokenId].auctionDeadline, "Auction ended");

        IQoukkaToken(ERC20address).transferFrom(
            msg.sender,
            address(this),
            amountQTN
        );

        if (numberOfBids721[tokenId] == 0) {
            tokenId721[tokenId].bestOffer = amountQTN;
            tokenId721[tokenId].bestBider = msg.sender;
        } else {
            IQoukkaToken(ERC20address).transfer(
                tokenId721[tokenId].bestBider,
                tokenId721[tokenId].bestOffer
            );
            tokenId721[tokenId].bestOffer = amountQTN;
            tokenId721[tokenId].bestBider = msg.sender;
        }

        numberOfBids721[tokenId] += 1;
    }

    function finishAuction721(uint tokenId) external {
        require(tokenId721[tokenId].tokenStatus == Status.OnAuction, "Not on auction");  
        require(block.timestamp > tokenId721[tokenId].auctionDeadline, "Auction is not ended");

        if (numberOfBids721[tokenId] > 2) {
            IQoukkaToken(ERC20address).transfer(
                tokenId721[tokenId].owner,
                tokenId721[tokenId].bestOffer
            );

            IGunGirls721(ERC721address).transferFrom(
                address(this),
                tokenId721[tokenId].bestBider,
                tokenId
            );

            tokenId721[tokenId].owner = tokenId721[tokenId].bestBider;
        } else {
            IQoukkaToken(ERC20address).transfer(
                tokenId721[tokenId].bestBider,
                tokenId721[tokenId].bestOffer
            );

            IGunGirls721(ERC721address).transferFrom(
                address(this),
                tokenId721[tokenId].owner,
                tokenId
            );
        }
        tokenId721[tokenId].bestBider = address(0);
        tokenId721[tokenId].tokenStatus = Status.Owned;
        tokenId721[tokenId].auctionDeadline = 0;

        numberOfBids721[tokenId] = 0;
    }

    function listOnAuction1155 (uint tokenId, uint amount, uint startPriceQTN) external {
        require(tokenId1155[tokenId][msg.sender].tokenStatus == Status.Owned, "Status not Owned");

        IGunGirls1155(ERC1155address).safeTransferFrom(
            msg.sender,
            address(this),
            tokenId,
            amount,
            bytes("0")
        );

        tokenId1155[tokenId][msg.sender].amount = amount;
        tokenId1155[tokenId][msg.sender].owner = msg.sender;
        tokenId1155[tokenId][msg.sender].bestOffer = startPriceQTN;
        tokenId1155[tokenId][msg.sender].tokenStatus = Status.OnAuction;
        tokenId1155[tokenId][msg.sender].auctionDeadline = block.timestamp + 3 days;
    }

    function makeBid1155 (uint tokenId, address seller,uint amountQTN) external {
        require(tokenId1155[tokenId][seller].tokenStatus == Status.OnAuction, "Not on auction");
        require(amountQTN > tokenId1155[tokenId][seller].bestOffer, "Best offer is higher");
        require(block.timestamp < tokenId1155[tokenId][seller].auctionDeadline, "Auction ended");

        IQoukkaToken(ERC20address).transferFrom(
            msg.sender,
            address(this),
            amountQTN
        );

        if (tokenId1155[tokenId][seller].numberOfBids1155 == 0) {
            tokenId1155[tokenId][seller].bestOffer = amountQTN;
            tokenId1155[tokenId][seller].bestBider = msg.sender;
        } else {
            IQoukkaToken(ERC20address).transfer(
                tokenId1155[tokenId][seller].bestBider,
                tokenId1155[tokenId][seller].bestOffer
            );
            tokenId1155[tokenId][seller].bestOffer = amountQTN;
            tokenId1155[tokenId][seller].bestBider = msg.sender;
        }

        tokenId1155[tokenId][seller].numberOfBids1155 += 1;
    }

    function finishAuction1155(uint tokenId, address seller) external {
        require(tokenId1155[tokenId][seller].tokenStatus == Status.OnAuction, "Not on auction");  
        require(block.timestamp > tokenId1155[tokenId][seller].auctionDeadline, "Auction is not ended");

        if (tokenId1155[tokenId][seller].numberOfBids1155 > 2) {
            IQoukkaToken(ERC20address).transfer(
                tokenId1155[tokenId][seller].owner,
                tokenId1155[tokenId][seller].bestOffer
            );

            IGunGirls1155(ERC1155address).safeTransferFrom(
                address(this),
                tokenId1155[tokenId][seller].bestBider,
                tokenId,
                tokenId1155[tokenId][seller].amount,
                bytes("0")
            );

            tokenId1155[tokenId][msg.sender].owner = msg.sender;
            tokenId1155[tokenId][msg.sender].amount += tokenId1155[tokenId][seller].amount;
            tokenId1155[tokenId][msg.sender].bestOffer += tokenId1155[tokenId][seller].bestOffer;
        } else {
            IQoukkaToken(ERC20address).transfer(
                tokenId1155[tokenId][seller].bestBider,
                tokenId1155[tokenId][seller].bestOffer
            );

            IGunGirls1155(ERC1155address).safeTransferFrom(
                address(this),
                tokenId1155[tokenId][seller].owner,
                tokenId,
                tokenId1155[tokenId][seller].amount,
                bytes("0")
            );
        }
        tokenId1155[tokenId][seller].amount = 0;   
        tokenId1155[tokenId][seller].bestBider = address(0);
        tokenId1155[tokenId][seller].tokenStatus = Status.Owned;
        tokenId1155[tokenId][seller].auctionDeadline = 0;
        tokenId1155[tokenId][seller].numberOfBids1155 = 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface IGunGirls1155 is IERC1155 {
    function mint(address account, uint256 id, uint256 amount, bytes calldata data) external;

    function burn(address account, uint256 id, uint256 amount) external;

    function giveAdminRights (address newChanger) external;

    function revokeAdminRights (address newChanger) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IGunGirls721 is IERC721 {
  function mintTo(address recepient) external returns (uint256);

  function burn(uint256 tokenId) external;

  function giveAdminRights (address newChanger) external;

  function revokeAdminRights (address newChanger) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IQoukkaToken {
  function transfer(address to, uint tokens) external returns(bool);

  function balanceOf(address tokenOwner) external view returns(uint balance);

  function approve(address spender, uint tokens) external returns(bool);

  function transferFrom(address from, address to, uint tokens) external returns(bool);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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