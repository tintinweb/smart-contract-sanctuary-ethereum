// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./interfaces/INeptunity.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// ███    ██ ███████ ██████  ████████ ██    ██ ███    ██ ██ ████████ ██    ██
// ████   ██ ██      ██   ██    ██    ██    ██ ████   ██ ██    ██     ██  ██
// ██ ██  ██ █████   ██████     ██    ██    ██ ██ ██  ██ ██    ██      ████
// ██  ██ ██ ██      ██         ██    ██    ██ ██  ██ ██ ██    ██       ██
// ██   ████ ███████ ██         ██     ██████  ██   ████ ██    ██       ██

contract NeptunityMarketplace is AccessControl, ReentrancyGuard {
    using Counters for Counters.Counter; // counters for marketplace

    Counters.Counter private ordersCounter; // orders counter
    Counters.Counter private offersCounter; // offers counter
    // solhint-disable-next-line
    INeptunity private NeptunityERC721;

    bytes32 private constant MINTER_ROLE =
        0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6; //keccak256("MINTER_ROLE");
    bytes32 private constant MINTER_ROLE_MANAGER =
        0x3d56c6b2572263081c65bd5409e23369bba6fe5164eaf66eb49349dcd212d6d3; //keccak256("MINTER_ROLE_MANAGER");

    mapping(uint256 => Innovice) public orders; // mapping order id to invoice struct.
    mapping(uint256 => Innovice) private offers; // mapping offer id to invoice struct.

    /********************************/
    /*********** STRUCTS ************/
    /********************************/
    struct Innovice {
        uint256 tokenId; // is token id of nft
        uint256 price; // is reserve price or the highest bid for the auction
        address from; // is the creator of the the of order
    }
    struct TradeInnovice {
        uint256 tokenId;
        uint256 orderId;
        uint256 price;
        address from; // seller of the nft
        address to; // buyer of the nft
    }

    /********************************/
    /************ EVENTS ************/
    /********************************/

    /**
     * @notice Emitted when an NFT is listed for sale on fix price
     * @param from The address of the seller
     * @param orderId The id of the order that was created
     * @param tokenId The id of the NFT
     * @param price The sale price onf NFT
     */
    event Order(
        address indexed from,
        uint256 indexed orderId,
        uint256 indexed tokenId,
        uint256 price
    );

    /**
     * @notice Emitted when an listing is cancelled for sale on fix price
     * @param from The address of the seller
     * @param orderId The id of the order that was created
     * @param tokenId The id of the NFT
     */
    event OrderRemoved(
        address indexed from,
        uint256 indexed orderId,
        uint256 indexed tokenId
    );

    /**
     * @notice Emitted when an offer is made for an NFT
     * @param from The address of the offer maker
     * @param offerId The id of the offer that was created
     * @param tokenId The id of the NFT
     */
    event Offered(
        address indexed from,
        uint256 indexed offerId,
        uint256 indexed tokenId,
        uint256 price
    );

    /**
     * @notice Emitted when an listing is cancelled for sale on fix price
     * @param from The address of the seller
     * @param offerId The id of the order that was created
     * @param tokenId The id of the NFT
     */
    event OfferRemoved(
        address indexed from,
        uint256 indexed offerId,
        uint256 indexed tokenId
    );

    /**
     * @notice Emitted when an order is filled or offer is accpeted for NFT
       @param  tokenId is the id of NFT which has been traded       
       @param  orderId is the id of order if it is an order which has been filled. otherwise it will be 0
       @param  price is amount in wei for which the NFT has been traded
       @param  from is seller of the nft
       @param  to is buyer of the nft
     -
     */
    event Traded(
        address indexed from,
        address to,
        uint256 indexed tokenId,
        uint256 orderId,
        uint256 price
    );

    /********************************/
    /*********** MODIFERS ***********/
    /********************************/

    modifier isOrderOwner(uint256 _orderId) {
        // solhint-disable-next-line
        require(orders[_orderId].from == msg.sender);
        _;
    }

    modifier isOfferOwner(uint256 _offerId) {
        // solhint-disable-next-line
        require(offers[_offerId].from == msg.sender);
        _;
    }

    /********************************/
    /************ METHODS ***********/
    /********************************/

    /**
     * @dev mints a token
     * @param _tokenURI is URI of the NFT's metadata
     * @param _artistFee is bps value for percentage for NFT's secondary sale
     */
    function mint(string memory _tokenURI, uint24 _artistFee)
        external
        onlyRole(MINTER_ROLE)
    {
        NeptunityERC721.mint(_tokenURI, msg.sender, _artistFee);
    }

    function createOrder(uint256 _tokenId, uint256 _price) external {
        // solhint-disable-next-line
        require(_price > 0);

        NeptunityERC721.transferFrom(msg.sender, address(this), _tokenId); // transfer token to contract

        ordersCounter.increment();

        uint256 _orderId = ordersCounter.current();

        orders[_orderId] = Innovice(_tokenId, _price, msg.sender);

        emit Order(msg.sender, _orderId, _tokenId, _price);
    }

    function fillOrder(uint256 _orderId) external payable {
        Innovice memory _order = orders[_orderId];

        // solhint-disable-next-line
        require(msg.value >= _order.price);

        TradeInnovice memory _tradeInnovice = TradeInnovice(
            _order.tokenId,
            _orderId,
            _order.price,
            payable(_order.from),
            msg.sender
        );

        _trade(_tradeInnovice);
    }

    function modifyOrderPrice(uint256 _orderId, uint256 _updatedPrice)
        external
        isOrderOwner(_orderId)
    {
        // solhint-disable-next-line
        require(_updatedPrice > 0);
        Innovice storage _order = orders[_orderId];
        _order.price = _updatedPrice;

        emit Order(msg.sender, _orderId, _order.tokenId, _updatedPrice);
    }

    function removeOrder(uint256 _orderId) external isOrderOwner(_orderId) {
        Innovice memory _order = orders[_orderId];

        NeptunityERC721.transferFrom(
            address(this),
            _order.from,
            _order.tokenId
        ); // transfer token to owner

        delete orders[_orderId]; // mark order as cancelled

        emit OrderRemoved(_order.from, _orderId, _order.tokenId);
    }

    function createOffer(uint256 _tokenId) external payable {
        // solhint-disable-next-line
        require(msg.value > 0); // offer should be more than 0 wei

        offersCounter.increment(); // update counter
        uint256 _offerId = offersCounter.current();

        offers[_offerId] = Innovice(_tokenId, msg.value, msg.sender);

        emit Offered(msg.sender, _offerId, _tokenId, msg.value);
    }

    function fillOffer(uint256 _offerId, uint256 _orderId) external {
        Innovice memory _offer = offers[_offerId];

        // solhint-disable-next-line
        if (_orderId != 0) require(orders[_orderId].from == msg.sender);

        delete offers[_offerId]; // mark offer as complete

        TradeInnovice memory _tradeInnovice = TradeInnovice(
            _offer.tokenId,
            _orderId,
            _offer.price,
            payable(msg.sender),
            _offer.from
        );

        _trade(_tradeInnovice);
    }

    function modifyOfferPrice(uint256 _offerId)
        external
        payable
        isOfferOwner(_offerId)
        nonReentrant
    {
        // solhint-disable-next-line
        require(msg.value > 0);
        Innovice storage _offer = offers[_offerId];

        uint256 _oldOffer = _offer.price;

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = payable(msg.sender).call{value: _oldOffer}(""); // pay old offer amount
        // solhint-disable-next-line
        require(success);
        _offer.price = msg.value;

        emit Offered(msg.sender, _offerId, _offer.tokenId, msg.value);
    }

    function removeOffer(uint256 _offerId)
        external
        isOfferOwner(_offerId)
        nonReentrant
    {
        Innovice memory _offer = offers[_offerId];

        delete offers[_offerId]; // mark order as cancelled

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = payable(_offer.from).call{value: _offer.price}(""); // transfer the offer amount back to bidder
        // solhint-disable-next-line
        require(success);

        emit OfferRemoved(_offer.from, _offerId, _offer.tokenId);
    }

    /**
     * @dev to exchange the  NFT and amount
     */
    function _trade(TradeInnovice memory _tradeInnovice) private {
        if (_tradeInnovice.orderId != 0) {
            delete orders[_tradeInnovice.orderId]; // mark order as complete

            NeptunityERC721.transferFrom(
                address(this),
                _tradeInnovice.to,
                _tradeInnovice.tokenId
            );
        } else {
            NeptunityERC721.transferFrom(
                _tradeInnovice.from,
                _tradeInnovice.to,
                _tradeInnovice.tokenId
            );
        }

        // extract data from neptunity erc721
        (
            address marketplaceFeeWallet,
            bool isSecondarySale,
            uint24 artistFee,
            uint24 primaryPlatformBPs,
            uint24 secondaryPlatformBPs,
            address artist
        ) = NeptunityERC721.getStateInfo(_tradeInnovice.tokenId);

        uint256 sellerAmount = _tradeInnovice.price;
        uint256 platformFee;
        uint256 royaltiesFee;
        bool success;

        if (!isSecondarySale) {
            //  for primary sale pay primaryPlatformBPs
            platformFee = (sellerAmount * primaryPlatformBPs) / 10000;
            sellerAmount -= platformFee; // subtracting primaryfee amount
            // solhint-disable-next-line avoid-low-level-calls
            (success, ) = marketplaceFeeWallet.call{value: platformFee}(""); // pay marketplaceFee
            // solhint-disable-next-line
            require(success);

            NeptunityERC721.setSecondarySale(_tradeInnovice.tokenId);
        } else {
            //  for secondaryPlatformBPs precentages.
            platformFee = (sellerAmount * secondaryPlatformBPs) / 10000;
            sellerAmount -= platformFee; // subtracting secondary fee amount
            // solhint-disable-next-line avoid-low-level-calls
            (success, ) = marketplaceFeeWallet.call{value: platformFee}(""); // pay marketplaceFee
            // solhint-disable-next-line
            require(success);

            //  pay royalties to artist
            royaltiesFee = (sellerAmount * artistFee) / 10000; // Fee paid by the user that fills the order, a.k.a. msg.sender.
            sellerAmount -= royaltiesFee;

            // solhint-disable-next-line avoid-low-level-calls
            (success, ) = payable(artist).call{value: royaltiesFee}(""); // transfer secondary sale fees to fee artist
            // solhint-disable-next-line reason-string
            require(success);
        }

        // solhint-disable-next-line avoid-low-level-calls
        (success, ) = _tradeInnovice.from.call{value: sellerAmount}(""); // pay the seller fee (price - marketplaceFee )
        // solhint-disable-next-line
        require(success);

        emit Traded(
            _tradeInnovice.from,
            _tradeInnovice.to,
            _tradeInnovice.tokenId,
            _tradeInnovice.orderId,
            _tradeInnovice.price
        );
    }

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE` to the account that deploys the contract.
     */
    constructor(address neptunityERC721) {
        require(neptunityERC721 != address(0), "Invalid address");
        // default values
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender); // the deployer must have admin role. It is not possible if this role is not granted.
        _setRoleAdmin(MINTER_ROLE, MINTER_ROLE_MANAGER); // minter role manager can only assign minter role

        NeptunityERC721 = INeptunity(neptunityERC721);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface INeptunity {
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

    function mint(
        string memory _tokenURI,
        address _to,
        uint24 _artistFee
    ) external;

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function exists(uint256 tokenId) external view returns (bool);

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) external view returns (address);

    /**
     * @dev returns the artist wallet address for the token Id
     */
    function artists(uint256 _tokenId) external view returns (address);

    /**
     * @dev only either auction or marketplace contract can call it to set tokenId as secondary sale.
     */
    function setSecondarySale(uint256 _tokenId) external;

    /**
     * @dev returns basic information about the token, and marketplace*/
    function getStateInfo(uint256 _tokenId)
        external
        view
        returns (
            address,
            bool,
            uint24,
            uint24,
            uint24,
            address
        );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

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
     *
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleRevoked} event.
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
     *
     * May emit a {RoleRevoked} event.
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
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
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