// SPDX-License-Identifier: unlicensed

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./interfaces/IAvatar.sol";
import "./interfaces/IVault.sol";

error NotAdminRole();
error MaxCapReached();
error MintingPaused();
error ZeroAddressNotAllowed();
error UpgradedContractNotZero();
error AlreadyInDesiredState(bool pause);
error MaxMintLimitReached();
error InsufficientAvatarHoldersCost();
error InsufficientPublicMintCost();
error avatarHoldersMintTimeNotStartorEnded();
error PublicSaleNotStarted();
error NotEligibleForTwinVault();
error LengthMismatch();
error AlreadyCreatedTwinVault();

contract SecretVerseVaultDistributor is AccessControl {
    IVault vaultToken;
    IAvatar avatarToken;

    uint256 public avatarHoldersMintPrice = 0.05 ether;
    uint256 public publicMintPrice = 0.1 ether;
    uint256 public avatarHoldersSaleStartTime;
    uint256 public avatarHoldersSaleEndTime;
    uint256 public maxMintLimit = 5;

    mapping(address => uint256) public userMintedCount;
    mapping(address => bool) public whiteList;
    mapping(uint256 => bool) public isAvatarNFTUsed;

    address public withdrawWallet;
    address public upgradedToAddress = address(0);

    bool public mintingPause;

    event whiteListed(address indexed user, bool flag);
    event AddressMintCount(
        address indexed minterAddress,
        uint256 mintCount,
        uint256[] avaTokenIds,
        uint256[] vaultTokenIds
    );

    modifier onlyAdmin() {
        if (!hasRole(DEFAULT_ADMIN_ROLE, _msgSender())) {
            revert NotAdminRole();
        }
        _;
    }

    modifier notEmpty(address _address) {
        if (_address == address(0)) {
            revert ZeroAddressNotAllowed();
        }
        _;
    }

    modifier isEligible(uint _num) {
        if (mintingPause) {
            revert MintingPaused();
        }

        if (upgradedToAddress != address(0)) {
            revert UpgradedContractNotZero();
        }

        if (userMintedCount[msg.sender] + _num > maxMintLimit) {
            revert MaxMintLimitReached();
        }

        if (vaultToken.getCurrentTokenId() + _num> vaultToken.cap()) {
            revert MaxCapReached();
        }
        _;
    }

    modifier avatarHoldersMintCost(uint256 totalMints) {
        if (msg.value < (totalMints * avatarHoldersMintPrice)) {
            revert InsufficientAvatarHoldersCost();
        }
        _;
    }

    modifier isTimeForAvatarHoldersSale() {
        if (
            block.timestamp >
            avatarHoldersSaleStartTime + avatarHoldersSaleEndTime &&
            block.timestamp < avatarHoldersSaleStartTime
        ) {
            revert avatarHoldersMintTimeNotStartorEnded();
        }
        _;
    }

    modifier isTimeForPublicSale() {
        if (
            block.timestamp <=
            avatarHoldersSaleStartTime + avatarHoldersSaleEndTime
        ) {
            revert PublicSaleNotStarted();
        }
        _;
    }

    receive() external payable {}

    constructor(
        IAvatar _avatarToken,
        IVault _vaultToken,
        address _withdrawWallet
    ) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        withdrawWallet = _withdrawWallet;
        vaultToken = _vaultToken;
        avatarToken = _avatarToken;
    }

    /// @dev upgrade the contract to make minting methods unusable
    function upgrade(address _upgradedToAddress) external onlyAdmin {
        upgradedToAddress = _upgradedToAddress;
    }

    /// @dev method to be only called by the whitelist users
    /// @param _num number of vault nfts + userMintedCount <= maxMintLimit
    function avatarHolderMintVault(
        uint256 _num,
        uint256[] calldata _avatarTokenIds
    )
        external
        payable
        isEligible(_num)
        avatarHoldersMintCost(_num)
        isTimeForAvatarHoldersSale
        returns (bool)
    {
        if (_num != _avatarTokenIds.length) {
            revert LengthMismatch();
        }
        address user = _msgSender();

        isAvatarHolder(user, _avatarTokenIds);
        userMintedCount[user] += _num;
        uint256 currentTokenId = vaultToken.getCurrentTokenId();
        for (uint256 i; i < _num; i++) {

            vaultToken.mintNextToken(user);
        }

        emit AddressMintCount(
            user,
            _num,
            _avatarTokenIds,
            getTokenIdsArray(currentTokenId, _num)
        );
        return true;
    }

    function publicMintVault(uint256 _num, uint256[] calldata _avatarTokenIds)
        external
        payable
        isEligible(_num)
        isTimeForPublicSale
        returns (bool)
    {
        address user = _msgSender();

        uint256 mintPrice = publicMintPrice;

        if(avatarToken.balanceOf(user) > 0){        // means user wants to mint twin vault
            if (_num != _avatarTokenIds.length) {
                revert LengthMismatch();
        }
            isAvatarHolder(user, _avatarTokenIds);
            mintPrice = avatarHoldersMintPrice;
        }
        else if(_avatarTokenIds.length != 0 ){ // means user want to mint simple VAULT, not TWIN
            revert NotEligibleForTwinVault();
        }

        if (msg.value < mintPrice * _num) {
            revert InsufficientPublicMintCost();
        }

        userMintedCount[user] += _num;

        uint256 currentTokenId = vaultToken.getCurrentTokenId();
        for (uint256 i; i < _num; i++) {

            vaultToken.mintNextToken(user);
        }
        emit AddressMintCount(
            user,
            _num,
            _avatarTokenIds,
            getTokenIdsArray(currentTokenId, _num)
        );
        return true;
    }

    /// @dev returns tokenIds of tokens minted for the event in whitelist and public sale mint method
    /// @param _currentTokenId start of the token id
    /// @param _num number of total tokens minted in whitelist and public mint methods
    function getTokenIdsArray(uint256 _currentTokenId, uint256 _num)
        internal
        pure
        returns (uint256[] memory)
    {
        uint256[] memory tokenIds = new uint256[](_num);
        uint256 currentTokenId = _currentTokenId;
        for (uint256 i; i < _num; i++) {
            currentTokenId += 1;
            tokenIds[i] = currentTokenId;
        }
        return tokenIds;
    }

    /// @dev method to withdraw eth amount in this current, received from user in whitelist and public sale
    function withdrawEth() external onlyAdmin {
        uint256 balance = address(this).balance;
        payable(withdrawWallet).transfer(balance);
    }

    /// @dev method to update the new wallet which will received the eth amount
    /// @param _newWallet address of the new admin wallet
    function updateWithdrawWallet(address _newWallet) external onlyAdmin {
        withdrawWallet = _newWallet;
    }

    /// @dev method to update the minting state to true or false
    /// @param _pause new minting state to be updated
    function togglePause(bool _pause) external onlyAdmin {
        if (mintingPause == _pause) {
            revert AlreadyInDesiredState(_pause);
        }

        mintingPause = _pause;
    }

    /// @dev method to update the avatar holders minting price
    /// @param _avatarHoldersMintPrice new price of the avatar holders mint sale
    function updateAvatarHoldersMintPrice(uint256 _avatarHoldersMintPrice)
        external
        onlyAdmin
    {
        avatarHoldersMintPrice = _avatarHoldersMintPrice;
    }

    /// @dev method to update the public mint price
    /// @param _publicMintPrice new price of public mint sale
    function updatePublicMintPrice(uint256 _publicMintPrice)
        external
        onlyAdmin
    {
        publicMintPrice = _publicMintPrice;
    }

    /// @dev method to update the whitelist start time
    /// @param _newStartTime new whitelist start time
    function updateAvatarHoldersStartTime(uint256 _newStartTime)
        external
        onlyAdmin
    {
        avatarHoldersSaleStartTime = _newStartTime;
    }

    /// @dev method to update the avatar holders sale end time
    /// @param _newEndTime new End time for avatar holders
    function updateAvatarHoldersEndTime(uint256 _newEndTime)
        external
        onlyAdmin
    {
        avatarHoldersSaleEndTime = _newEndTime;
    }

    /// @dev method to check if user is the owner of the tokenId
    /// @dev check if avatar tokenId is already be used to make the twin vault or not
    /// @param user address of the user
    /// @param tokenIds token id of the avatar NFT
    /// @return return true if not revert occurred.
    function isAvatarHolder(address user, uint256[] calldata tokenIds)
        internal
        returns (bool)
    {
        for(uint i; i<tokenIds.length; i++){

            if (isAvatarNFTUsed[tokenIds[i]]) {
                revert AlreadyCreatedTwinVault();
            }

            if (avatarToken.ownerOf(tokenIds[i]) != user) {
                revert NotEligibleForTwinVault();
            }

            isAvatarNFTUsed[tokenIds[i]] = true;

        }

        return true;
    }

}

// SPDX-License-Identifier: unlicensed

pragma solidity ^0.8.7;

interface IVault {
    function mintNextToken(address _mintTo) external returns (bool);

    function cap() external view returns (uint256);

    function getCurrentTokenId() external view returns (uint256);
}

// SPDX-License-Identifier: unlicensed

pragma solidity ^0.8.7;

interface IAvatar {
    function mintNextToken(address _mintTo) external returns (bool);

    function cap() external view returns (uint256);

    function getCurrentTokenId() external view returns (uint256);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function balanceOf(address owner) external view returns (uint256 balance);
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