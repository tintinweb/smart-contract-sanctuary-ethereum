// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface ISWAP {
    function marketTransfer(
        address from,
        address to,
        uint256 id,
        uint256 amount
    ) external;
}

contract RTLOLMarket is AccessControl, ReentrancyGuard {
    string public constant name = "RTLOL Market";
    bytes32 public EIP712_DOMAIN_HASH;
    bytes32 public SWAP_HASH;
    bytes32 public ITEM_TYPEHASH;
    address public officialSigner;

    enum TokenType {
        INVALID,
        ERC20,
        ERC721,
        ERC1155
    }

    struct SwapParams {
        address listerAddress;
        Item sellerItem;
        Item currency;
        uint256 pricePerToken;
        uint256 listingDeadline;
        bool isOffer;
        uint256 purchaseQuantity;
        uint256 swapDeadline;
        bytes signature;
    }
    // contract type: 20 = erc20, 721 = erc721, 1155 = erc1155
    struct ItemContract {
        address contractAddr;
        TokenType tokenType;
    }

    struct Item {
        address contractAddr;
        uint256 itemId;
    }

    mapping(address => ItemContract) public itemContracts;
    // mapping(uint256 => bool) public usedNonces;
    mapping(address => uint256) public userNonces;
    // mapping(listingHash => quanitityRemaining)
    mapping(bytes32 => uint256) public listingQuantities;

    /// Events
    event ListingOfferCreated(
        address indexed userAddress,
        bytes32 listingHash,
        uint256 maxQuantity
    );
    event Swap(
        address indexed sellerAddress,
        address indexed buyerAddress,
        bytes32 listingHash,
        bool isOffer,
        uint256 userNonce
    );

    constructor(address admin) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        officialSigner = admin;
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        EIP712_DOMAIN_HASH = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes(name)),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );
        SWAP_HASH = keccak256(
            "Swap(address user,address listerAddress,Item sellerItem,Item currency,uint256 pricePerToken,uint256 listingDeadline,bool isOffer,uint256 purchaseQuantity,uint256 swapDeadline,uint256 userNonce)Item(address contractAddr,uint256 itemId)"
        );
        ITEM_TYPEHASH = keccak256("Item(address contractAddr,uint256 itemId)");
    }

    modifier onlyOwner() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        _;
    }

    // stores a listing hash verified by the official signer into listingQuantities mapping
    // listingHash is the keccak256 hash of the listing data:
    // bytes32 listingHash = keccak256(address userAddress, Item sellerItem, Item currency, uint256 pricePerToken, uint256 listingDeadline, bool isOffer);
    // ^ will modify this later to allow for partial purchases, and allow only fixed currencies
    // todo: how to handle user nonces when create listing?or do we need to?
    function createListingOffer(
        bytes32 listingHash,
        uint256 maxQuantity,
        bytes memory signature
    ) external {
        // signature verificiation:
        bytes32 message = keccak256(abi.encode(listingHash, maxQuantity));
        address recoveredSigner = recoverSigner(message, signature);
        require(
            recoveredSigner != address(0) && recoveredSigner == officialSigner,
            "Invalid signature"
        );
        // check if listing already exists
        require(listingQuantities[listingHash] == 0, "Listing already exists");
        listingQuantities[listingHash] = maxQuantity;
        emit ListingOfferCreated(msg.sender, listingHash, maxQuantity);
    }

    function validateListingOffer(
        address listerAddress,
        Item memory sellerItem,
        Item memory currency,
        uint256 pricePerToken,
        uint256 listingDeadline,
        bool isOffer,
        uint256 purchaseQuantity
    ) internal view returns (bytes32 listingHash) {
        // check listingDeadline:
        require(
            listingDeadline >= block.timestamp,
            "listingDeadline has already passed"
        );
        // signature verificiation:
        listingHash = keccak256(
            abi.encode(
                listerAddress,
                sellerItem.contractAddr,
                sellerItem.itemId,
                currency.contractAddr,
                currency.itemId,
                pricePerToken,
                listingDeadline,
                isOffer
            )
        );
        require(
            listingQuantities[listingHash] != 0, // check if listing exists
            "Listing does not exist"
        );
        // check quanitity here too, need to modify format of listingHash
        require(
            listingQuantities[listingHash] >= purchaseQuantity,
            "Not enough quantity remaining"
        );
        return listingHash;
    }

    // params:
    // address listerAddress,
    // Item memory sellerItem,
    // Item memory currency,
    // uint256 pricePerToken,
    // uint256 listingDeadline,
    // bool isOffer, //0 = buy (msg.sender = buyer), 1 = accept offer (msg.sender = seller)
    // uint256 purchaseQuantity,
    // bytes memory signature
    function swap(SwapParams memory _params) external nonReentrant {
        require(
            _params.swapDeadline >= block.timestamp,
            "swapDeadline has already passed"
        );
        uint256 currNonce = userNonces[msg.sender];
        bytes32 message = getMessage(
            keccak256(
                abi.encode(
                    SWAP_HASH,
                    msg.sender,
                    _params.listerAddress,
                    hashItem(_params.sellerItem),
                    hashItem(_params.currency),
                    _params.pricePerToken,
                    _params.listingDeadline,
                    _params.isOffer,
                    _params.purchaseQuantity,
                    _params.swapDeadline,
                    userNonces[msg.sender]++
                )
            )
        );
        address recoveredSigner = recoverSigner(message, _params.signature);
        require(
            recoveredSigner != address(0) && recoveredSigner == officialSigner,
            "Invalid signature"
        );
        // check if listing already exists and if it has enough quantity
        bytes32 listingHash = validateListingOffer(
            _params.listerAddress,
            _params.sellerItem,
            _params.currency,
            _params.pricePerToken,
            _params.listingDeadline,
            _params.isOffer,
            _params.purchaseQuantity
        );
        // decrement listing quantity in mapping
        listingQuantities[listingHash] -= _params.purchaseQuantity;
        //do tranfers here
        address sellerAddress = _params.isOffer
            ? msg.sender
            : _params.listerAddress;
        address buyerAddress = !_params.isOffer
            ? msg.sender
            : _params.listerAddress;
        // transfer sellerItem to buyer
        // If offchain, skip transfer
        if (_params.sellerItem.contractAddr != address(0)) {
            ItemContract memory sellerItemContract = itemContracts[
                _params.sellerItem.contractAddr
            ];
            require(
                sellerItemContract.tokenType == TokenType.ERC721 ||
                    sellerItemContract.tokenType == TokenType.ERC1155,
                "Invalid seller item contract"
            );
            //ERC721 or ERC1155
            ISWAP(sellerItemContract.contractAddr).marketTransfer(
                sellerAddress,
                buyerAddress,
                _params.sellerItem.itemId,
                _params.purchaseQuantity
            );
        }
        // transfer currency to buyer
        // If offchain, skip transfer
        if (_params.currency.contractAddr != address(0)) {
            ItemContract memory currencyContract = itemContracts[
                _params.currency.contractAddr
            ];
            require(
                currencyContract.tokenType == TokenType.ERC20,
                "ERC20 currency required"
            );
            // erc20
            ISWAP(currencyContract.contractAddr).marketTransfer(
                buyerAddress,
                sellerAddress,
                0,
                _params.purchaseQuantity * _params.pricePerToken
            );
        }
        emit Swap(
            sellerAddress,
            buyerAddress,
            listingHash,
            _params.isOffer,
            currNonce
        );
    }

    function addContract(address contractAddr, TokenType tokenType)
        external
        onlyOwner
    {
        require(
            tokenType == TokenType.ERC20 ||
                tokenType == TokenType.ERC721 ||
                tokenType == TokenType.ERC1155,
            "Invalid contract type"
        );

        require(
            itemContracts[contractAddr].contractAddr == address(0),
            "Contract already added"
        );
        itemContracts[contractAddr] = ItemContract(contractAddr, tokenType);
    }

    function removeContract(address contractAddr) external onlyOwner {
        require(
            itemContracts[contractAddr].contractAddr != address(0),
            "Contract not found"
        );
        itemContracts[contractAddr] = ItemContract(
            address(0),
            TokenType.INVALID
        );
    }

    function setOfficialSigner(address _officialSigner) external onlyOwner {
        officialSigner = _officialSigner;
    }

    /// signature methods.

    function hashItem(Item memory item) internal view returns (bytes32) {
        bytes32 itemHash = keccak256(
            abi.encode(ITEM_TYPEHASH, item.contractAddr, item.itemId)
        );
        return itemHash;
    }

    function splitSignature(bytes memory sig)
        internal
        pure
        returns (
            uint8 v,
            bytes32 r,
            bytes32 s
        )
    {
        require(sig.length == 65);

        assembly {
            // first 32 bytes, after the length prefix.
            r := mload(add(sig, 32))
            // second 32 bytes.
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes).
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }

    function recoverSigner(bytes32 message, bytes memory sig)
        internal
        pure
        returns (address)
    {
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(sig);

        return ecrecover(message, v, r, s);
    }

    /// builds a prefixed hash to mimic the behavior of eth_signTypedData of EIP712.
    function getMessage(bytes32 hash) internal view returns (bytes32) {
        return
            keccak256(abi.encodePacked("\x19\x01", EIP712_DOMAIN_HASH, hash));
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
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