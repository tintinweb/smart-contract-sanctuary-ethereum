// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./interface/IDiamondDawnMine.sol";
import "./interface/IDiamondDawnMineAdmin.sol";
import "./objects/MineObjects.sol";
import "./objects/DiamondObjects.sol";
import "./utils/NFTMetadataUtils.sol";
import "./utils/StringUtils.sol";
import "./utils/RandomUtils.sol";
import "./objects/MineObjects.sol";
import "./objects/MineObjects.sol";
import "./objects/MineObjects.sol";

/**
 * @title DiamondDawnMine NFT Contract
 * @author Diamond Dawn
 */
contract DiamondDawnMine is
    AccessControl,
    IDiamondDawnMine,
    IDiamondDawnMineAdmin
{
    bool public isOpen; // mine is closed until it's initialized.
    uint16 public maxDiamonds; // 333 max
    uint16 public diamondCount; // 333 max
    address public diamondDawn;
    mapping(uint => mapping(uint => string)) public typeToShapeVideo;

    // Carat loss of ~35% to ~65% from rough stone to the polished diamond.
    uint8 private constant MIN_ROUGH_EXTRA_POINTS = 37;
    uint8 private constant MAX_ROUGH_EXTRA_POINTS = 74;
    // Carat loss of ~2% to ~8% in the polish process.
    uint8 private constant MIN_POLISH_EXTRA_POINTS = 1;
    uint8 private constant MAX_POLISH_EXTRA_POINTS = 4;

    uint16 private _randNonce = 0; // 999 max
    Certificate[] private _mine;
    mapping(uint => Metadata) private _metadata;

    constructor(address[] memory adminAddresses) {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        // TODO: remove admins after testing
        for (uint i = 0; i < adminAddresses.length; i++) {
            _grantRole(DEFAULT_ADMIN_ROLE, adminAddresses[i]);
        }
    }

    /**********************     Modifiers     ************************/
    modifier onlyDiamondDawn() {
        require(msg.sender == diamondDawn, "Only DD");
        _;
    }

    modifier exists(uint tokenId) {
        require(_metadata[tokenId].type_ != Type.NO_TYPE, "Don't exist");
        _;
    }

    modifier onlyType(uint tokenId, Type diamondDawnType) {
        require(diamondDawnType == _metadata[tokenId].type_, "Wrong type");
        _;
    }

    modifier isMineOpen(bool isOpen_) {
        require(
            isOpen == isOpen_,
            string.concat("Mine ", isOpen ? "Open" : "Closed")
        );
        _;
    }

    modifier mineOverflow(uint cnt) {
        require((diamondCount + cnt) <= maxDiamonds, "Mine overflow");
        _;
    }

    modifier mineNotDry() {
        require(_mine.length > 0, "Dry mine");
        _;
    }

    /**********************     External Functions     ************************/

    function enter(uint tokenId)
        external
        onlyDiamondDawn
        isMineOpen(true)
        onlyType(tokenId, Type.NO_TYPE)
    {
        _metadata[tokenId].type_ = Type.ENTER_MINE;
    }

    function mine(uint tokenId)
        external
        onlyDiamondDawn
        isMineOpen(true)
        mineNotDry
        onlyType(tokenId, Type.ENTER_MINE)
    {
        uint extraPoints = _getRandomBetween(
            MIN_ROUGH_EXTRA_POINTS,
            MAX_ROUGH_EXTRA_POINTS
        );
        Metadata storage metadata = _metadata[tokenId];
        metadata.type_ = Type.ROUGH;
        metadata.rough = RoughMetadata({
            shape: extraPoints % 2 == 0
                ? RoughShape.MAKEABLE_1
                : RoughShape.MAKEABLE_2,
            extraPoints: extraPoints
        });
        metadata.certificate = _mineDiamond();
    }

    function cut(uint256 tokenId)
        external
        onlyDiamondDawn
        isMineOpen(true)
        onlyType(tokenId, Type.ROUGH)
    {
        uint extraPoints = _getRandomBetween(
            MIN_POLISH_EXTRA_POINTS,
            MAX_POLISH_EXTRA_POINTS
        );
        Metadata storage diamondDawnMetadata = _metadata[tokenId];
        diamondDawnMetadata.cut.extraPoints = extraPoints;
        diamondDawnMetadata.type_ = Type.CUT;
    }

    function polish(uint256 tokenId)
        external
        onlyDiamondDawn
        isMineOpen(true)
        onlyType(tokenId, Type.CUT)
    {
        _metadata[tokenId].type_ = Type.POLISHED;
    }

    function rebirth(uint256 tokenId)
        external
        onlyDiamondDawn
        onlyType(tokenId, Type.POLISHED)
    {
        _metadata[tokenId].type_ = Type.REBORN;
    }

    function initialize(address diamondDawn_, uint16 maxDiamonds_)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        diamondDawn = diamondDawn_;
        maxDiamonds = maxDiamonds_;
        isOpen = true;
    }

    function eruption(Certificate[] calldata diamonds)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        mineOverflow(diamonds.length)
    {
        for (uint i = 0; i < diamonds.length; i++) {
            _mine.push(diamonds[i]);
        }
        diamondCount += uint16(diamonds.length);
    }

    function lostShipment(uint tokenId, Certificate calldata diamond)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        Metadata storage metadata = _metadata[tokenId];
        require(
            metadata.type_ == Type.POLISHED || metadata.type_ == Type.REBORN,
            "Wrong type"
        );
        metadata.certificate = diamond;
    }

    function setOpen(bool isOpen_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        isOpen = isOpen_;
    }

    function setTypeVideos(Type type_, ShapeVideo[] calldata shapeVideos)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(type_ != Type.NO_TYPE);
        for (uint i = 0; i < shapeVideos.length; i++) {
            require(bytes(shapeVideos[i].video).length > 0);
            _setVideo(type_, shapeVideos[i].shape, shapeVideos[i].video);
        }
    }

    function lockMine()
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        isMineOpen(false)
    {
        // lock mine forever
        renounceRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function getMetadata(uint tokenId)
        external
        view
        onlyDiamondDawn
        exists(tokenId)
        returns (string memory)
    {
        Metadata memory metadata = _metadata[tokenId];
        string memory videoURI = _getVideoURI(metadata);
        string memory base64Json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        _getMetadataJson(tokenId, metadata, videoURI)
                    )
                )
            )
        );

        return
            string(
                abi.encodePacked("data:application/json;base64,", base64Json)
            );
    }

    function isMineReady(Type type_) external view returns (bool) {
        if (type_ == Type.ENTER_MINE || type_ == Type.REBORN)
            return _isVideoExist(type_, 0);
        if (type_ == Type.ROUGH && diamondCount != maxDiamonds) return false;
        uint maxShape = type_ == Type.ROUGH
            ? uint(type(RoughShape).max)
            : uint(type(Shape).max);
        for (uint i = 1; i <= maxShape; i++) {
            // skipping 0 - no shape
            if (!_isVideoExist(type_, maxShape)) return false;
        }
        return true;
    }

    /**********************     Private Functions     ************************/

    function _mineDiamond() private returns (Certificate memory) {
        assert(_mine.length > 0);
        uint index = _getRandomBetween(0, _mine.length - 1);
        Certificate memory diamond = _mine[index];
        _mine[index] = _mine[_mine.length - 1]; // swap last diamond with mined diamond
        _mine.pop();
        return diamond;
    }

    function _getRandomBetween(uint min, uint max) private returns (uint) {
        _randNonce++;
        return getRandomInRange(min, max, _randNonce);
    }

    function _setVideo(
        Type type_,
        uint shape,
        string memory videoUrl
    ) private {
        typeToShapeVideo[uint(type_)][shape] = videoUrl;
    }

    function _getVideoURI(Metadata memory metadata)
        private
        view
        returns (string memory)
    {
        string memory videoUrl = _getVideo(
            metadata.type_,
            _getShapeNumber(metadata)
        );
        return string.concat(_videoBaseURI(), videoUrl);
    }

    function _isVideoExist(Type type_, uint shape) private view returns (bool) {
        return bytes(_getVideo(type_, shape)).length > 0;
    }

    function _getVideo(Type type_, uint shape)
        private
        view
        returns (string memory)
    {
        return typeToShapeVideo[uint(type_)][shape];
    }

    function _getMetadataJson(
        uint tokenId,
        Metadata memory metadata,
        string memory videoURI
    ) private pure returns (string memory) {
        // TODO: Add real description
        NFTMetadata memory nftMetadata = NFTMetadata({
            name: string(
                abi.encodePacked("Diamond #", Strings.toString(tokenId))
            ),
            description: "description",
            createdBy: "dd",
            image: videoURI,
            attributes: _getJsonAttributes(metadata)
        });
        return toJsonMetadata(nftMetadata);
    }

    function _getJsonAttributes(Metadata memory metadata)
        private
        pure
        returns (Attribute[] memory)
    {
        Type type_ = metadata.type_;
        Attribute[] memory attributes = new Attribute[](
            _getNumAttributes(type_)
        );
        attributes[0] = getStringAttribute("Type", toTypeString(type_));
        if (type_ == Type.ENTER_MINE) {
            return attributes;
        }

        attributes[1] = getStringAttribute("Origin", "Metaverse");
        attributes[2] = getStringAttribute("Identification", "Natural");
        attributes[3] = getAttribute(
            "Carat",
            getCaratString(_getPoints(metadata)),
            "",
            false
        );
        if (type_ == Type.ROUGH) {
            attributes[4] = getStringAttribute("Color", "Cape");
            attributes[5] = getStringAttribute(
                "Shape",
                toRoughShapeString(metadata.rough.shape)
            );
            attributes[6] = getStringAttribute("Mine", "Underground");
            return attributes;
        }

        Certificate memory certificate = metadata.certificate;
        if (uint(Type.CUT) <= uint(type_)) {
            attributes[4] = getStringAttribute(
                "Color",
                toColorString(certificate.color)
            );
            attributes[5] = getStringAttribute(
                "Cut",
                toGradeString(certificate.cut)
            );
            attributes[6] = getStringAttribute(
                "Fluorescence",
                toFluorescenceString(certificate.fluorescence)
            );
            attributes[7] = getStringAttribute(
                "Measurements",
                certificate.measurements
            );
            attributes[8] = getStringAttribute(
                "Shape",
                toShapeString(certificate.shape)
            );
        }
        if (uint(Type.POLISHED) <= uint(type_)) {
            attributes[9] = getStringAttribute(
                "Clarity",
                toClarityString(certificate.clarity)
            );
            attributes[10] = getStringAttribute(
                "Polish",
                toGradeString(certificate.polish)
            );
            attributes[11] = getStringAttribute(
                "Symmetry",
                toGradeString(certificate.symmetry)
            );
        }
        if (uint(Type.REBORN) <= uint(type_)) {
            attributes[12] = getStringAttribute("Laboratory", "GIA");
            attributes[13] = getAttribute(
                "Report Date",
                Strings.toString(certificate.date),
                "date",
                false
            );
            attributes[14] = getAttribute(
                "Report Number",
                Strings.toString(certificate.number),
                "",
                false
            );
        }
        return attributes;
    }

    function _videoBaseURI() private pure returns (string memory) {
        // TODO: in production we'll get the full ipfs/arweave url - base URI will change.
        // TODO: galk to check what's the best approach
        return
            "https://tweezers-public.s3.amazonaws.com/diamond-dawn-nft-mocks/";
    }

    function _getShapeNumber(Metadata memory metadata)
        private
        pure
        returns (uint)
    {
        Type type_ = metadata.type_;
        if (type_ == Type.CUT || type_ == Type.POLISHED)
            return uint(metadata.certificate.shape);
        if (type_ == Type.ROUGH) return uint(metadata.rough.shape);
        if (type_ == Type.ENTER_MINE || type_ == Type.REBORN) return 0;
        revert();
    }

    function _getNumAttributes(Type type_) private pure returns (uint) {
        if (type_ == Type.ENTER_MINE) return 1;
        else if (type_ == Type.ROUGH) return 7;
        else if (type_ == Type.CUT) return 9;
        else if (type_ == Type.POLISHED) return 12;
        else if (type_ == Type.REBORN) return 15;
        revert();
    }

    function _getPoints(Metadata memory metadata) private pure returns (uint) {
        assert(metadata.certificate.points > 0);
        if (metadata.type_ == Type.ROUGH) {
            assert(metadata.rough.extraPoints > 0);
            return metadata.certificate.points + metadata.rough.extraPoints;
        } else if (metadata.type_ == Type.CUT) {
            assert(metadata.cut.extraPoints > 0);
            return metadata.certificate.points + metadata.cut.extraPoints;
        } else if (
            metadata.type_ == Type.POLISHED || metadata.type_ == Type.REBORN
        ) return metadata.certificate.points;
        revert();
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
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
pragma solidity ^0.8.15;

import "../objects/MineObjects.sol";

interface IDiamondDawnMine {
    function enter(uint tokenId) external;

    function mine(uint tokenId) external;

    function cut(uint tokenId) external;

    function polish(uint tokenId) external;

    function rebirth(uint tokenId) external;

    function getMetadata(uint tokenId) external view returns (string memory);

    function isMineReady(Type type_) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "../objects/DiamondObjects.sol";
import "../objects/MineObjects.sol";

interface IDiamondDawnMineAdmin {
    function initialize(address diamondDawn, uint16 maxDiamond) external;

    function eruption(Certificate[] calldata diamonds) external;

    function lockMine() external;

    function lostShipment(uint tokenId, Certificate calldata diamond) external;

    function setOpen(bool isOpen) external;

    function setTypeVideos(Type type_, ShapeVideo[] calldata shapeVideos)
        external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./DiamondObjects.sol";

enum RoughShape {
    NO_SHAPE,
    MAKEABLE_1,
    MAKEABLE_2
}

struct RoughMetadata {
    RoughShape shape;
    uint extraPoints;
}

struct CutMetadata {
    uint extraPoints;
}

enum Type {
    NO_TYPE,
    ENTER_MINE,
    ROUGH,
    CUT,
    POLISHED,
    REBORN
}

struct Metadata {
    Type type_;
    RoughMetadata rough;
    CutMetadata cut;
    Certificate certificate;
}

struct ShapeVideo {
    uint8 shape;
    string video;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

enum Shape {
    NO_SHAPE,
    PEAR,
    ROUND,
    OVAL,
    RADIANT
}

enum Grade {
    NO_GRADE,
    GOOD,
    VERY_GOOD,
    EXCELLENT
}

enum Clarity {
    NO_CLARITY,
    VS2,
    VS1,
    VVS2,
    VVS1,
    IF,
    FL
}

enum Fluorescence {
    NO_FLUORESCENCE,
    FAINT,
    NONE
}

enum Color {
    NO_COLOR,
    M,
    N,
    O,
    P,
    Q,
    R,
    S,
    T,
    U,
    V,
    W,
    X,
    Y,
    Z
}

struct Certificate {
    uint64 date;
    uint64 number;
    uint8 points;
    string measurements;
    Clarity clarity;
    Color color;
    Grade cut;
    Grade symmetry;
    Grade polish;
    Fluorescence fluorescence;
    Shape shape;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

struct NFTMetadata {
    string name;
    string description;
    string createdBy;
    string image;
    Attribute[] attributes;
}

struct Attribute {
    string traitType;
    string value;
    string displayType;
    bool isValueAString;
}

function getStringAttribute(string memory traitType, string memory value)
    pure
    returns (Attribute memory)
{
    return getAttribute(traitType, value, "", true);
}

function getAttribute(
    string memory traitType,
    string memory value,
    string memory displayType,
    bool isValueAString
) pure returns (Attribute memory) {
    return
        Attribute({
            isValueAString: isValueAString,
            displayType: displayType,
            traitType: traitType,
            value: value
        });
}

function toJsonMetadata(NFTMetadata memory metadata)
    pure
    returns (string memory)
{
    bytes memory byteString;
    byteString = abi.encodePacked(byteString, _openObject());
    byteString = abi.encodePacked(
        byteString,
        _pushStringAttribute("name", metadata.name, true)
    );
    byteString = abi.encodePacked(
        byteString,
        _pushStringAttribute("description", metadata.description, true)
    );
    byteString = abi.encodePacked(
        byteString,
        _pushStringAttribute("created_by", metadata.createdBy, true)
    );
    byteString = abi.encodePacked(
        byteString,
        _pushStringAttribute("image", metadata.image, true)
    );
    byteString = abi.encodePacked(
        byteString,
        _pushComplexAttribute(
            "attributes",
            _getAttributes(metadata.attributes),
            false
        )
    );
    byteString = abi.encodePacked(byteString, _closeObject());

    return string(byteString);
}

function _getAttributes(Attribute[] memory attributes)
    pure
    returns (string memory)
{
    bytes memory byteString;
    byteString = abi.encodePacked(byteString, _openArray());
    for (uint i = 0; i < attributes.length; i++) {
        Attribute memory attribute = attributes[i];
        byteString = abi.encodePacked(
            byteString,
            _pushArrayElement(
                _getAttribute(attribute),
                i < (attributes.length - 1)
            )
        );
    }
    byteString = abi.encodePacked(byteString, _closeArray());
    return string(byteString);
}

function _getAttribute(Attribute memory attribute)
    pure
    returns (string memory)
{
    bytes memory byteString;

    byteString = abi.encodePacked(byteString, _openObject());

    if (bytes(attribute.displayType).length > 0) {
        byteString = abi.encodePacked(
            byteString,
            _pushStringAttribute("display_type", attribute.displayType, true)
        );
    }
    byteString = abi.encodePacked(
        byteString,
        _pushStringAttribute("trait_type", attribute.traitType, true)
    );

    byteString = attribute.isValueAString
        ? abi.encodePacked(
            byteString,
            _pushStringAttribute("value", attribute.value, false)
        )
        : abi.encodePacked(
            byteString,
            _pushNonStringAttribute("value", attribute.value, false)
        );

    byteString = abi.encodePacked(byteString, _closeObject());

    return string(byteString);
}

function _openObject() pure returns (string memory) {
    return string(abi.encodePacked("{"));
}

function _closeObject() pure returns (string memory) {
    return string(abi.encodePacked("}"));
}

function _openArray() pure returns (string memory) {
    return string(abi.encodePacked("["));
}

function _closeArray() pure returns (string memory) {
    return string(abi.encodePacked("]"));
}

function _pushStringAttribute(
    string memory key,
    string memory value,
    bool insertComma
) pure returns (string memory) {
    return
        string(
            abi.encodePacked(
                '"',
                key,
                '": "',
                value,
                '"',
                insertComma ? "," : ""
            )
        );
}

function _pushNonStringAttribute(
    string memory key,
    string memory value,
    bool insertComma
) pure returns (string memory) {
    return
        string(
            abi.encodePacked('"', key, '": ', value, insertComma ? "," : "")
        );
}

function _pushComplexAttribute(
    string memory key,
    string memory value,
    bool insertComma
) pure returns (string memory) {
    return
        string(
            abi.encodePacked('"', key, '": ', value, insertComma ? "," : "")
        );
}

function _pushArrayElement(string memory value, bool insertComma)
    pure
    returns (string memory)
{
    return string(abi.encodePacked(value, insertComma ? "," : ""));
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/Strings.sol";
import "../objects/DiamondObjects.sol";
import "../objects/MineObjects.sol";

function toColorString(Color color) pure returns (string memory) {
    if (color == Color.M) return "M";
    if (color == Color.N) return "N";
    if (color == Color.O) return "O";
    if (color == Color.P) return "P";
    if (color == Color.Q) return "Q";
    if (color == Color.R) return "R";
    if (color == Color.S) return "S";
    if (color == Color.T) return "T";
    if (color == Color.U) return "U";
    if (color == Color.V) return "V";
    if (color == Color.W) return "W";
    if (color == Color.X) return "X";
    if (color == Color.Y) return "Y";
    if (color == Color.Z) return "Z";
    revert();
}

function toGradeString(Grade grade) pure returns (string memory) {
    if (grade == Grade.GOOD) return "Good";
    if (grade == Grade.VERY_GOOD) return "Very Good";
    if (grade == Grade.EXCELLENT) return "Excellent";
    revert();
}

function toClarityString(Clarity clarity) pure returns (string memory) {
    if (clarity == Clarity.VS2) return "VS2";
    if (clarity == Clarity.VS1) return "VS1";
    if (clarity == Clarity.VVS2) return "VVS2";
    if (clarity == Clarity.VVS1) return "VVS1";
    if (clarity == Clarity.IF) return "IF";
    if (clarity == Clarity.FL) return "FL";
    revert();
}

function toFluorescenceString(Fluorescence fluorescence)
    pure
    returns (string memory)
{
    if (fluorescence == Fluorescence.FAINT) return "Faint";
    if (fluorescence == Fluorescence.NONE) return "None";
    revert();
}

function toShapeString(Shape shape) pure returns (string memory) {
    if (shape == Shape.PEAR) return "Pear";
    if (shape == Shape.ROUND) return "Round";
    if (shape == Shape.OVAL) return "Oval";
    if (shape == Shape.RADIANT) return "Radiant";
    revert();
}

function toRoughShapeString(RoughShape shape) pure returns (string memory) {
    if (shape == RoughShape.MAKEABLE_1) return "Makeable 1";
    if (shape == RoughShape.MAKEABLE_2) return "Makeable 2";
    revert();
}

function getCaratString(uint points) pure returns (string memory) {
    uint remainder = points % 100;
    string memory caratRemainder = remainder < 10
        ? string.concat("0", Strings.toString(remainder))
        : Strings.toString(remainder);
    string memory carat = Strings.toString(points / 100);
    return string.concat(carat, ".", caratRemainder);
}

function toTypeString(Type type_) pure returns (string memory) {
    if (type_ == Type.ENTER_MINE) return "Mine Entrance";
    if (type_ == Type.ROUGH) return "Rough";
    if (type_ == Type.CUT) return "Cut";
    if (type_ == Type.POLISHED) return "Polished";
    if (type_ == Type.REBORN) return "Reborn";
    revert();
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

function getRandomInRange(
    uint min,
    uint max,
    uint nonce
) view returns (uint) {
    uint rand = _rand(nonce);
    uint range = max - min + 1;
    return (rand % range) + min;
}

function _rand(uint nonce) view returns (uint) {
    return
        uint(
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    block.difficulty,
                    tx.origin,
                    nonce
                )
            )
        );
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