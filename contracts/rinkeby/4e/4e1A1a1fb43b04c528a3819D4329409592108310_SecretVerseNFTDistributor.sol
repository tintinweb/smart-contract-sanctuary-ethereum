/**
 *Submitted for verification at Etherscan.io on 2021-10-27
 */

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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
    function toHexString(uint256 value, uint256 length)
        internal
        pure
        returns (string memory)
    {
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

// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature)
        internal
        pure
        returns (address, RecoverError)
    {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature)
        internal
        pure
        returns (address)
    {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs &
            bytes32(
                0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
            );
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (
            uint256(s) >
            0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0
        ) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash)
        internal
        pure
        returns (bytes32)
    {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            );
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n",
                    Strings.toString(s.length),
                    s
                )
            );
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked("\x19\x01", domainSeparator, structHash)
            );
    }
}

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
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return interfaceId == type(IERC165).interfaceId;
    }
}

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    function hasRole(bytes32 role, address account)
        external
        view
        returns (bool);

    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    function grantRole(bytes32 role, address account) external;

    function revokeRole(bytes32 role, address account) external;

    function renounceRole(bytes32 role, address account) external;
}

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
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(
        bytes32 indexed role,
        bytes32 indexed previousAdminRole,
        bytes32 indexed newAdminRole
    );

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
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
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IAccessControl).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account)
        public
        view
        override
        returns (bool)
    {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
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
    function grantRole(bytes32 role, address account)
        public
        virtual
        override
        onlyRole(getRoleAdmin(role))
    {
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
    function revokeRole(bytes32 role, address account)
        public
        virtual
        override
        onlyRole(getRoleAdmin(role))
    {
        _revokeRole(role, account);
    }

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
    function renounceRole(bytes32 role, address account)
        public
        virtual
        override
    {
        require(
            account == _msgSender(),
            "AccessControl: can only renounce roles for self"
        );

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
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

interface SecretVerseIF {
    function mintNextToken(address _mintTo) external returns (bool);

    function mint(address _mintTo, uint256 _tokenId) external returns (bool);

    function getCurrentTokenId() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function cap() external view returns (uint256);
}

interface IERC721 {
    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);
}

contract SecretVerseNFTDistributor is AccessControl {
    SecretVerseIF cbToken;

    uint256 public tokenPrice = uint256(9 * (10**16)); // = 0.09 ETH
    uint256 public usersMintCount; // 9650 for users
    uint256 public adminMintCount; // 350 for admin
    address public withdrawWallet;

    // 'PRE-REQ' NFTS Contract addresses of NFTS to hold to mint in Whitelisting phase if not whitelisted
    address[4] public holdedNfts = [
        0xFF9C1b15B16263C61d017ee9F65C50e4AE0113D7,
        0x8a90CAb2b38dba80c64b7734e58Ee1dB38B8992e,
        0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D,
        0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB
    ];

    bytes32 public constant TOGGLE_MINTING_ROLE =
        keccak256("TOGGLE_MINTING_ROLE");
    bool public _mintingPaused = false;

    address public upgradedToAddress = address(0);

    mapping(address => bool) public whiteList;
    bool public whitelistOnly = true;

    mapping(address => uint256) public totalMintsPerAddress;

    // events
    event whiteListed(address indexed user, bool flag); // address to status shows is whitelisted or not
    event AddressMintCount(
        address indexed minterAddress,
        uint256 mintCount,
        uint256[] tokenIds
    ); // address to mintCount and minted token IDS

    constructor(SecretVerseIF _cbToken) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(TOGGLE_MINTING_ROLE, msg.sender);

        withdrawWallet = msg.sender;

        cbToken = _cbToken;
    }

    function upgrade(address _upgradedToAddress) public {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Caller is not a admin"
        );

        upgradedToAddress = _upgradedToAddress;
    }

    function mint(uint256 _num) public payable returns (bool) {
        require(
            address(0) == upgradedToAddress,
            "SecretVerseNftDistributor: Contract has been upgraded to a new address"
        );
        require(
            usersMintCount + _num <= 9650,
            "SecretVerseNftDistributor: Total Cap reached"
        );
        require(
            whiteList[msg.sender] || !whitelistOnly || doesHoldNfts(),
            "SecretVerseNftDistributor: ONLY WHITELIST or SHOULD HOLD PRE-REQ NFTS"
        ); //either on whitelist or holds PRE-REQ NFTS or whitelist is false

        require(
            whitelistOnly ||
                (!whitelistOnly &&
                    totalMintsPerAddress[msg.sender] + _num <= 5),
            "SecretVerseNftDistributor: You can mint a maximum of 5"
        ); //whitelist is false, and you can max mint 5
        require(
            !whitelistOnly ||
                (whitelistOnly && totalMintsPerAddress[msg.sender] + _num <= 5),
            "SecretVerseNftDistributor: You can mint a maximum of 5 when whitelist enabled"
        ); //whitelist is true, and you can max mint 20 per address

        require(
            msg.value >= (tokenPrice * _num),
            "SecretVerseNftDistributor: Insufficient amount provided"
        );
        require(!_mintingPaused, "SecretVerseNftDistributor: Minting paused");

        require(
            cbToken.getCurrentTokenId() + _num <= 10000,
            "SecretVerseNftDistributor: Maximum cap of 10k mints reached"
        );

        totalMintsPerAddress[msg.sender] += _num; //log the total mints per address
        usersMintCount += _num;
        uint256 currentTokenId = cbToken.getCurrentTokenId();
        for (uint256 i; i < _num; i++) {
            cbToken.mintNextToken(msg.sender); //, tokenId + i + 1
        }
        emit AddressMintCount(
            msg.sender,
            _num,
            getTokenIdsArray(currentTokenId, _num)
        );
        return true;
    }

    // returns tokenIds of tokens minted for event
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

    // for admin to mint team tokens
    function adminMint(address _to, uint256 _quantity) public returns (bool) {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Caller is not an admin"
        );
        require(adminMintCount + _quantity <= 350, "Can't mint more than 350");
        adminMintCount += _quantity;
        uint256 currentTokenId = cbToken.getCurrentTokenId();
        for (uint256 i; i < _quantity; i++) {
            cbToken.mintNextToken(_to);
        }
        emit AddressMintCount(
            _to,
            _quantity,
            getTokenIdsArray(currentTokenId, _quantity)
        );
        return true;
    }

    // checks whether user holds one of the NFTS of "holdedNfts" contract address
    function doesHoldNfts() internal view returns (bool) {
        for (uint256 i; i < 4; i++) {
            if (IERC721(holdedNfts[i]).balanceOf(msg.sender) > 0) {
                return true;
            }
        }
        return false;
    }

    function giveAway(address _to, uint256 _amount) external {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Caller is not a admin"
        );

        require(
            usersMintCount + _amount <= 9650,
            "Cap reached, maximum 9650 mints possible"
        );
        usersMintCount += _amount;
        uint256 currentTokenId = cbToken.getCurrentTokenId();
        for (uint256 i; i < _amount; i++) {
            cbToken.mintNextToken(_to);
        }
        emit AddressMintCount(
            _to,
            _amount,
            getTokenIdsArray(currentTokenId, _amount)
        );
    }

    fallback() external payable {}

    receive() external payable {}

    // admin functions
    function withdrawAll() public {
        uint256 _each = address(this).balance;
        require(payable(withdrawWallet).send(_each));
    }

    function updateWithdrawWallet(address _newWallet) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not admin");

        withdrawWallet = _newWallet;
    }

    function togglePause(bool _pause) public {
        require(
            hasRole(TOGGLE_MINTING_ROLE, msg.sender),
            "Caller is not TOGGLE_MINTING_ROLE"
        );
        require(_mintingPaused != _pause, "Already in desired pause state");

        _mintingPaused = _pause;
    }

    // updates token minting price
    function updatePrice(uint256 _newPrice) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not admin");

        tokenPrice = _newPrice;
    }

    //for admin to whitelist
    function addToWhiteList(address[] calldata entries) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not admin");

        address entry;
        uint256 length = entries.length;
        for (uint256 i; i < length; i++) {
            entry = entries[i];
            require(entry != address(0), "Cannot add zero address");
            require(!whiteList[entry], "Cannot add duplicate address");

            whiteList[entry] = true;
            emit whiteListed(entry, true);
        }
    }

    // removes users from whitelist
    function removeFromWhiteList(address[] calldata entries) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not admin");

        address entry;
        uint256 length = entries.length;
        for (uint256 i; i < length; i++) {
            entry = entries[i];
            require(entry != address(0), "Cannot remove zero address");

            whiteList[entry] = false;
            emit whiteListed(entry, false);
        }
    }

    function toggleWhiteListOnly(bool _whitelistOnly) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not admin");
        require(
            whitelistOnly != _whitelistOnly,
            "Already in desired pause state"
        );
        whitelistOnly = _whitelistOnly;
    }

    // for user to call from APP front end to get whitelisted
    function whitelistUser(
        address wallet,
        uint256 _canMintTotal,
        uint256 _timestamp,
        bytes memory _signature
    ) public returns (bool) {
        require(!whiteList[wallet], "User already whitelisted");

        address signerOwner = signatureWallet(
            wallet,
            _canMintTotal,
            _timestamp,
            _signature
        );
        require(
            hasRole(DEFAULT_ADMIN_ROLE, signerOwner),
            "SecretVerseNftDistributor: Not authorized to Whitelist"
        );

        whiteList[wallet] = true;
        emit whiteListed(wallet, true);
        return true;
    }

    function isOnWhiteList(address addr) external view returns (bool) {
        return whiteList[addr];
    }

    function signatureWallet(
        address wallet,
        uint256 _canMintTotal,
        uint256 _timestamp,
        bytes memory _signature
    ) public pure returns (address) {
        return
            ECDSA.recover(
                keccak256(abi.encode(wallet, _canMintTotal, _timestamp)),
                _signature
            );
    }
}