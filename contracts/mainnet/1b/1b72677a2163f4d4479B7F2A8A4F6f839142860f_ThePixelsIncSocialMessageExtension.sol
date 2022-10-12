// SPDX-License-Identifier: MIT

// ______  __  __   ______       _____    __  __   _____    ______
// /\__  _\/\ \_\ \ /\  ___\     /\  __-. /\ \/\ \ /\  __-. /\  ___\
// \/_/\ \/\ \  __ \\ \  __\     \ \ \/\ \\ \ \_\ \\ \ \/\ \\ \  __\
//   \ \_\ \ \_\ \_\\ \_____\    \ \____- \ \_____\\ \____- \ \_____\
//    \/_/  \/_/\/_/ \/_____/     \/____/  \/_____/ \/____/  \/_____/
//

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import "./../../common/interfaces/IINT.sol";
import "./../../common/interfaces/IThePixelsIncExtensionStorageV2.sol";
import "./../../common/interfaces/ICoreRewarder.sol";
import "./../../common/interfaces/IThePixelsInc.sol";

contract ThePixelsIncSocialMessageExtension is AccessControl {
    uint256 public constant EXTENSION_ID = 2;

    uint256 public nextMessageId;
    mapping(uint256 => uint256) public messagePrices;

    address public immutable INTAddress;
    address public extensionStorageAddress;
    address public pixelRewarderAddress;
    address public dudesRewarderAddress;
    address public DAOAddress;

    bytes32 public constant MOD_ROLE = keccak256("MOD_ROLE");

    constructor(
        address _INTAddress,
        address _extensionStorageAddress,
        address _pixelRewarderAddress,
        address _dudesRewarderAddress,
        address _DAOAddress
    ) {
        INTAddress = _INTAddress;
        extensionStorageAddress = _extensionStorageAddress;
        pixelRewarderAddress = _pixelRewarderAddress;
        dudesRewarderAddress = _dudesRewarderAddress;
        DAOAddress = _DAOAddress;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MOD_ROLE, msg.sender);
    }

    function setExtensionStorageAddress(address _extensionStorageAddress)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        extensionStorageAddress = _extensionStorageAddress;
    }

    function setPixelRewarderAddress(address _rewarderAddress)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        pixelRewarderAddress = _rewarderAddress;
    }

    function setDudeRewarderAddress(address _rewarderAddress)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        dudesRewarderAddress = _rewarderAddress;
    }

    function setDAOAddress(address _DAOAddress)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        DAOAddress = _DAOAddress;
    }

    function grantModRole(address modAddress)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        grantRole(MOD_ROLE, modAddress);
    }

    function revokeModRole(address modAddress)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        revokeRole(MOD_ROLE, modAddress);
    }

    function setMessagePrice(uint256 collectionId, uint256 price)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        messagePrices[collectionId] = price;
    }

    function sendGlobalMessage(uint256 senderId, string memory message)
        public
        onlyRole(MOD_ROLE)
    {
        uint256 currentMessageId = nextMessageId;
        emit GlobalMessageSent(
            msg.sender,
            currentMessageId,
            senderId,
            message,
            block.timestamp
        );
        nextMessageId = currentMessageId + 1;
    }

    function updateGlobalMessageVisibility(
        uint256[] memory messageIds,
        uint256[] memory senderIds,
        bool[] memory isHiddens
    ) public onlyRole(MOD_ROLE) {
        for (uint256 i; i < messageIds.length; i++) {
            emit GlobalMessageVisibilityUpdated(
                msg.sender,
                messageIds[i],
                senderIds[i],
                isHiddens[i],
                block.timestamp
            );
        }
    }

    function updateGlobalTokenBlockStatus(
        uint256[] memory senderIds,
        uint256[] memory targetTokenIds,
        uint256[] memory collectionIds,
        bool[] memory isBlockeds
    ) public onlyRole(MOD_ROLE) {
        for (uint256 i; i < senderIds.length; i++) {
            emit GlobalTokenBlockStatusUpdated(
                msg.sender,
                senderIds[i],
                targetTokenIds[i],
                collectionIds[i],
                isBlockeds[i],
                block.timestamp
            );
        }
    }

    function enableSocialMessages(
        uint256[] memory tokenIds,
        uint256[] memory salts
    ) public {
        uint256 length = tokenIds.length;
        uint256[] memory variants = new uint256[](length);
        bool[] memory useCollection = new bool[](length);
        uint256[] memory collectionTokenIds = new uint256[](length);

        address _extensionStorageAddress = extensionStorageAddress;
        for (uint256 i = 0; i < length; i++) {
            uint256 currentVariant = IThePixelsIncExtensionStorageV2(
                _extensionStorageAddress
            ).currentVariantIdOf(EXTENSION_ID, tokenIds[i]);
            require(currentVariant == 0, "Token has no social extension");

            uint256 rnd = _rnd(tokenIds[i], salts[i]) % 100;
            uint256 variant;

            if (rnd >= 80 && rnd < 100) {
                variant = 3;
            } else if (rnd >= 50 && rnd < 80) {
                variant = 2;
            } else {
                variant = 1;
            }
            variants[i] = variant;
        }

        IThePixelsIncExtensionStorageV2(_extensionStorageAddress)
            .extendMultipleWithVariants(
                msg.sender,
                EXTENSION_ID,
                tokenIds,
                variants,
                useCollection,
                collectionTokenIds
            );
    }

    function sendMessages(
        uint256[] memory senderTokenIds,
        uint256[] memory targetTokenIds,
        uint256[] memory collectionIds,
        string[] memory messages
    ) public {
        uint256 currentMessageId = nextMessageId;
        uint256 totalPayment;

        address _extensionStorageAddress = extensionStorageAddress;
        address _pixelRewarderAddress = pixelRewarderAddress;
        address _dudeRewarderAddress = dudesRewarderAddress;

        uint256 pixelBalance;
        bool pixelBalanceChecked;

        for (uint256 i = 0; i < senderTokenIds.length; i++) {
            if (collectionIds[i] == 0) {
                require(
                    ICoreRewarder(_pixelRewarderAddress).isOwner(
                        msg.sender,
                        senderTokenIds[i]
                    ),
                    "Not authorised - Invalid owner"
                );

                uint256 currentVariant = IThePixelsIncExtensionStorageV2(
                    _extensionStorageAddress
                ).currentVariantIdOf(EXTENSION_ID, senderTokenIds[i]);
                require(currentVariant > 0, "Token has no social extension");

            } else if (collectionIds[i] == 1) {
                require(
                    ICoreRewarder(_dudeRewarderAddress).isOwner(
                        msg.sender,
                        senderTokenIds[i]
                    ),
                    "Not authorised - Invalid owner"
                );
                if (!pixelBalanceChecked) {
                    pixelBalance = ICoreRewarder(_pixelRewarderAddress).tokensOfOwner(
                        msg.sender
                    ).length;
                    pixelBalanceChecked = true;
                }
                require(
                    pixelBalance > 0,
                    "Not authorised - Not a the pixels inc owner"
                );
            } else {
                revert();
            }

            uint256 messagePrice = messagePrices[collectionIds[i]];
            totalPayment += messagePrice;

            emit MessageSent(
                msg.sender,
                currentMessageId,
                senderTokenIds[i],
                targetTokenIds[i],
                collectionIds[i],
                messages[i],
                block.timestamp
            );
            currentMessageId++;
        }
        nextMessageId = currentMessageId;
        if (totalPayment > 0) {
            payToDAO(msg.sender, totalPayment);
        }
    }

    function updateMessageVisibility(
        uint256[] memory senderTokenIds,
        uint256[] memory messageIds,
        bool[] memory isHiddens
    ) public {
        address _extensionStorageAddress = extensionStorageAddress;
        address _rewarderAddress = pixelRewarderAddress;
        for (uint256 i = 0; i < senderTokenIds.length; i++) {
            require(
                ICoreRewarder(_rewarderAddress).isOwner(
                    msg.sender,
                    senderTokenIds[i]
                ),
                "Not authorised - Invalid owner"
            );

            uint256 currentVariant = IThePixelsIncExtensionStorageV2(
                _extensionStorageAddress
            ).currentVariantIdOf(EXTENSION_ID, senderTokenIds[i]);
            require(currentVariant > 0, "Token has no social extension");

            emit MessageVisibilityUpdated(
                msg.sender,
                messageIds[i],
                senderTokenIds[i],
                isHiddens[i],
                block.timestamp
            );
        }
    }

    function updateTokenBlockStatus(
        uint256[] memory senderTokenIds,
        uint256[] memory targetTokenIds,
        uint256[] memory collectionIds,
        bool[] memory isBlockeds
    ) public {
        address _extensionStorageAddress = extensionStorageAddress;
        address _rewarderAddress = pixelRewarderAddress;
        for (uint256 i = 0; i < senderTokenIds.length; i++) {
            require(
                ICoreRewarder(_rewarderAddress).isOwner(
                    msg.sender,
                    senderTokenIds[i]
                ),
                "Not authorised - Invalid owner"
            );

            uint256 currentVariant = IThePixelsIncExtensionStorageV2(
                _extensionStorageAddress
            ).currentVariantIdOf(EXTENSION_ID, senderTokenIds[i]);
            require(currentVariant > 0, "Token has no social extension");

            emit TokenBlockStatusUpdated(
                msg.sender,
                senderTokenIds[i],
                targetTokenIds[i],
                collectionIds[i],
                isBlockeds[i],
                block.timestamp
            );
        }
    }

    function payToDAO(address owner, uint256 amount) internal {
        IINT(INTAddress).transferFrom(owner, DAOAddress, amount);
    }

    function _rnd(uint256 _tokenId, uint256 _salt)
        internal
        view
        returns (uint256)
    {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.timestamp,
                        msg.sender,
                        _tokenId,
                        _salt
                    )
                )
            );
    }

    event MessageSent(
        address owner,
        uint256 indexed id,
        uint256 indexed senderTokenId,
        uint256 indexed targetTokenId,
        uint256 collectionId,
        string message,
        uint256 dateCrated
    );

    event MessageVisibilityUpdated(
        address owner,
        uint256 indexed id,
        uint256 indexed senderTokenId,
        bool indexed isHidden,
        uint256 dateCrated
    );

    event TokenBlockStatusUpdated(
        address owner,
        uint256 indexed senderTokenId,
        uint256 indexed targetTokenId,
        uint256 collectionId,
        bool indexed isBlocked,
        uint256 dateCrated
    );

    event GlobalMessageSent(
        address owner,
        uint256 indexed id,
        uint256 indexed senderId,
        string message,
        uint256 dateCrated
    );

    event GlobalMessageVisibilityUpdated(
        address owner,
        uint256 indexed id,
        uint256 indexed senderId,
        bool indexed isHidden,
        uint256 dateCrated
    );

    event GlobalTokenBlockStatusUpdated(
        address owner,
        uint256 indexed senderId,
        uint256 indexed targetTokenId,
        uint256 collectionId,
        bool indexed isBlocked,
        uint256 dateCrated
    );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/AccessControl.sol)

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
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
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
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// ______  __  __   ______       _____    __  __   _____    ______
// /\__  _\/\ \_\ \ /\  ___\     /\  __-. /\ \/\ \ /\  __-. /\  ___\
// \/_/\ \/\ \  __ \\ \  __\     \ \ \/\ \\ \ \_\ \\ \ \/\ \\ \  __\
//   \ \_\ \ \_\ \_\\ \_____\    \ \____- \ \_____\\ \____- \ \_____\
//    \/_/  \/_/\/_/ \/_____/     \/____/  \/_____/ \/____/  \/_____/
//

interface IINT {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function mint(address to, uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;
}

// pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

// ______  __  __   ______       _____    __  __   _____    ______
// /\__  _\/\ \_\ \ /\  ___\     /\  __-. /\ \/\ \ /\  __-. /\  ___\
// \/_/\ \/\ \  __ \\ \  __\     \ \ \/\ \\ \ \_\ \\ \ \/\ \\ \  __\
//   \ \_\ \ \_\ \_\\ \_____\    \ \____- \ \_____\\ \____- \ \_____\
//    \/_/  \/_/\/_/ \/_____/     \/____/  \/_____/ \/____/  \/_____/
//

pragma solidity ^0.8.0;

interface IThePixelsIncExtensionStorageV2 {
    struct Variant {
        bool isOperatorExecution;
        bool isFreeForCollection;
        bool isEnabled;
        bool isDisabledForSpecialPixels;
        uint16 contributerCut;
        uint128 cost;
        uint128 supply;
        uint128 count;
        uint128 categoryId;
        address contributer;
        address collection;
    }

    struct Category {
        uint128 cost;
        uint128 supply;
    }

    struct VariantStatus {
        bool isAlreadyClaimed;
        uint128 cost;
        uint128 supply;
    }

    function extendWithVariant(
        address owner,
        uint256 extensionId,
        uint256 tokenId,
        uint256 variantId,
        bool useCollectionTokenId,
        uint256 collectionTokenId
    ) external;

    function extendMultipleWithVariants(
        address owner,
        uint256 extensionId,
        uint256[] memory tokenIds,
        uint256[] memory variantIds,
        bool[] memory useCollectionTokenId,
        uint256[] memory collectionTokenIds
    ) external;

    function detachVariant(
        address owner,
        uint256 extensionId,
        uint256 tokenId
    ) external;

    function detachVariants(
        address owner,
        uint256 extensionId,
        uint256[] memory tokenIds
    ) external;

    function variantDetail(
        address owner,
        uint256 extensionId,
        uint256 tokenId,
        uint256 variantId,
        bool useCollectionTokenId,
        uint256 collectionTokenId
    ) external view returns (Variant memory, VariantStatus memory);

    function variantDetails(
        address owner,
        uint256 extensionId,
        uint256[] memory tokenIds,
        uint256[] memory variantIds,
        bool[] memory useCollectionTokenIds,
        uint256[] memory collectionTokenIds
    ) external view returns (Variant[] memory, VariantStatus[] memory);

    function variantsOfExtension(
        uint256 extensionId,
        uint256[] memory variantIds
    ) external view returns (Variant[] memory);

    function transferExtensionVariant(
        address owner,
        uint256 extensionId,
        uint256 variantId,
        uint256 fromTokenId,
        uint256 toTokenId
    ) external;

    function pixelExtensions(uint256 tokenId) external view returns (uint256);

    function balanceOfToken(
        uint256 extensionId,
        uint256 tokenId,
        uint256[] memory variantIds
    ) external view returns (uint256);

    function currentVariantIdOf(uint256 extensionId, uint256 tokenId)
        external
        view
        returns (uint256);

    function currentVariantIdsOf(uint256 extensionId, uint256[] memory tokenIds)
        external
        view
        returns (uint256[] memory);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// ______  __  __   ______       _____    __  __   _____    ______
// /\__  _\/\ \_\ \ /\  ___\     /\  __-. /\ \/\ \ /\  __-. /\  ___\
// \/_/\ \/\ \  __ \\ \  __\     \ \ \/\ \\ \ \_\ \\ \ \/\ \\ \  __\
//   \ \_\ \ \_\ \_\\ \_____\    \ \____- \ \_____\\ \____- \ \_____\
//    \/_/  \/_/\/_/ \/_____/     \/____/  \/_____/ \/____/  \/_____/
//

interface ICoreRewarder {
    function stake(
        uint256[] calldata tokenIds
    ) external;

    function withdraw(
        uint256[] calldata tokenIds
    ) external;

    function claim(uint256[] calldata tokenIds) external;

    function earned(uint256[] memory tokenIds)
        external
        view
        returns (uint256);

    function lastClaimTimesOfTokens(uint256[] memory tokenIds)
        external
        view
        returns (uint256[] memory);

    function isOwner(address owner, uint256 tokenId)
        external
        view
        returns (bool);

    function tokensOfOwner(address _owner)
        external
        view
        returns (uint256[] memory);

    function stakedTokensOfOwner(address owner)
        external
        view
        returns (uint256[] memory);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// ______  __  __   ______       _____    __  __   _____    ______
// /\__  _\/\ \_\ \ /\  ___\     /\  __-. /\ \/\ \ /\  __-. /\  ___\
// \/_/\ \/\ \  __ \\ \  __\     \ \ \/\ \\ \ \_\ \\ \ \/\ \\ \  __\
//   \ \_\ \ \_\ \_\\ \_____\    \ \____- \ \_____\\ \____- \ \_____\
//    \/_/  \/_/\/_/ \/_____/     \/____/  \/_____/ \/____/  \/_____/
//

interface IThePixelsInc {
    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function tokensOfOwner(address _owner)
        external
        view
        returns (uint256[] memory);

    function updateDNAExtension(uint256 _tokenId) external;

    function pixelDNAs(uint256 _tokenId) external view returns (uint256);

    function pixelDNAExtensions(uint256 _tokenId)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.0 (access/IAccessControl.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/introspection/ERC165.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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