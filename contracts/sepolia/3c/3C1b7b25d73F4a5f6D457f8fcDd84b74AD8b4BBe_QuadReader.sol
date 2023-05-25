//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";

import "./interfaces/IQuadPassport.sol";
import "./interfaces/IQuadGovernance.sol";
import "./interfaces/IQuadReader.sol";
import "./interfaces/IQuadPassportStore.sol";
import "./storage/QuadReaderStoreV2.sol";

/// @title Data Reader Contract for Quadrata Passport
/// @author Fabrice Cheng
/// @notice All accessor functions for reading and pricing quadrata attributes
 contract QuadReader is IQuadReader, UUPSUpgradeable, QuadReaderStoreV2 {
    constructor() initializer {
        // used to prevent logic contract self destruct take over
    }

    /// @dev initializer (constructor)
    /// @param _governance address of the IQuadGovernance contract
    /// @param _passport address of the IQuadPassport contract
    function initialize(
        address _governance,
        address _passport
    ) public initializer {
        require(_governance != address(0), "GOVERNANCE_ADDRESS_ZERO");
        require(_passport != address(0), "PASSPORT_ADDRESS_ZERO");

        governance = IQuadGovernance(_governance);
        passport = IQuadPassport(_passport);
    }

    /// @notice Retrieve a single attribute being issued about a wallet
    /// @param _account address of user
    /// @param _attribute attribute to get respective value from
    /// @return attribute Attribute struct (values, verifiedAt, issuer)
    function getAttribute(
        address _account, bytes32 _attribute
    ) external payable override returns(IQuadPassportStore.Attribute memory attribute) {
        require(_account != address(0), "ACCOUNT_ADDRESS_ZERO");
        bool hasPreapproval = governance.preapproval(msg.sender);
        require(hasPreapproval, "SENDER_NOT_AUTHORIZED");

        attribute = passport.attribute(_account, _attribute);
        emit QueryEvent(_account, msg.sender, _attribute);
    }

    /// @notice Retrieve all attestations for a specific attribute being issued about a wallet
    /// @param _account address of user
    /// @param _attribute attribute to get respective value from
    /// @return attributes array of Attributes struct (values, verifiedAt, issuer)
    function getAttributes(
        address _account, bytes32 _attribute
    ) external payable override returns(IQuadPassportStore.Attribute[] memory attributes) {
        require(_account != address(0), "ACCOUNT_ADDRESS_ZERO");
        bool hasPreapproval = governance.preapproval(msg.sender);
        require(hasPreapproval, "SENDER_NOT_AUTHORIZED");

        attributes = passport.attributes(_account, _attribute);
        emit QueryEvent(_account, msg.sender, _attribute);
    }

    /// @notice Retrieve all attestations for a specific attribute being issued about a wallet (Legacy verson)
    /// @dev For support for older version of solidity
    /// @param _account address of user
    /// @param _attribute attribute to get respective value from
    /// @return values Array of Attribute values
    /// @return epochs Array of Attribute's verifiedAt
    /// @return issuers Array of Attribute's issuers
    function getAttributesLegacy(
        address _account, bytes32 _attribute
    ) public payable override returns(bytes32[] memory values, uint256[] memory epochs, address[] memory issuers) {
        require(_account != address(0), "ACCOUNT_ADDRESS_ZERO");
        bool hasPreapproval = governance.preapproval(msg.sender);
        require(hasPreapproval, "SENDER_NOT_AUTHORIZED");

        IQuadPassportStore.Attribute[] memory attributes = passport.attributes(_account, _attribute);
        values = new bytes32[](attributes.length);
        epochs = new uint256[](attributes.length);
        issuers = new address[](attributes.length);

        for (uint256 i = 0; i < attributes.length; i++) {
            values[i] = attributes[i].value;
            epochs[i] = attributes[i].epoch;
            issuers[i] = attributes[i].issuer;
        }
        emit QueryEvent(_account, msg.sender, _attribute);
    }

    /// @notice Retrieve all attestations for a batch of attributes being issued about a wallet
    /// @notice This will only retrieve the first available value for each attribute
    /// @param _account address of user
    /// @param _attributes List of attributes to get respective value from
    /// @return attributes array of Attributes struct (values, verifiedAt, issuer)
    function getAttributesBulk(
        address _account, bytes32[] calldata _attributes
    ) external payable override returns(IQuadPassportStore.Attribute[] memory attributes) {
        require(_account != address(0), "ACCOUNT_ADDRESS_ZERO");
        bool hasPreapproval = governance.preapproval(msg.sender);
        require(hasPreapproval, "SENDER_NOT_AUTHORIZED");

        attributes = new IQuadPassportStore.Attribute[](_attributes.length);

        for (uint256 i = 0; i < _attributes.length; i++) {
            attributes[i] = passport.attribute(_account, _attributes[i]);
        }
        emit QueryBulkEvent(_account, msg.sender, _attributes);
    }


    /// @notice Retrieve all attestations for a batch of attributes being issued about a wallet
    /// @notice This will only retrieve the first available value for each attribute
    /// @dev For support for older version of solidity
    /// @param _account address of user
    /// @param _attributes List of attributes to get respective value from
    /// @return values Array of Attribute values
    /// @return epochs Array of Attribute's verifiedAt
    /// @return issuers Array of Attribute's issuers
    function getAttributesBulkLegacy(
        address _account, bytes32[] calldata _attributes
    ) external payable override returns(bytes32[] memory values, uint256[] memory epochs, address[] memory issuers) {
        require(_account != address(0), "ACCOUNT_ADDRESS_ZERO");
        bool hasPreapproval = governance.preapproval(msg.sender);
        require(hasPreapproval, "SENDER_NOT_AUTHORIZED");

        values = new bytes32[](_attributes.length);
        epochs = new uint256[](_attributes.length);
        issuers = new address[](_attributes.length);

        for (uint256 i = 0; i < _attributes.length; i++) {
            IQuadPassportStore.Attribute memory attr = passport.attribute(_account, _attributes[i]);
                values[i] = attr.value;
                epochs[i] = attr.epoch;
                issuers[i] = attr.issuer;

        }
        emit QueryBulkEvent(_account, msg.sender, _attributes);
    }


    /// @dev stub for compatibility with older versions
    function queryFee(
        address,
        bytes32
    ) public override view returns(uint256) {
        return 0;
    }

    /// @dev stub for compatibility with older versions
    function queryFeeBulk(
        address,
        bytes32[] calldata
    ) public override view returns(uint256) {
       return 0;
    }


    /// @dev (DEPRECATED) Returns the number of attestations for an attribute about a Passport holder
    /// @param _account account getting requested for attributes
    /// @param _attribute keccak256 of the attribute type (ex: keccak256("COUNTRY"))
    /// @return the amount of existing attributes
    function balanceOf(address _account, bytes32 _attribute) public view override returns(uint256) {
       return passport.attributes(_account, _attribute).length;
    }

    /// @dev (DEPRECATED) Returns the number of attestations for an attribute about a Passport holder
    /// @param _account account getting requested for attributes
    /// @param _attribute keccak256 of the attribute type (ex: keccak256("COUNTRY"))
    /// @return the amount of existing attributes
    function balancePerAttribute(address _account, bytes32 _attribute) public view returns(uint256) {
       return passport.attributes(_account, _attribute).length;
    }

    /// @dev Withdraw to  an issuer's treasury or the Quadrata treasury
    /// @notice Restricted behind a TimelockController
    /// @param _to address of either an issuer's treasury or the Quadrata treasury
    /// @param _amount amount to withdraw
    function withdraw(address payable _to, uint256 _amount) external override {
        require(
            IAccessControlUpgradeable(address(governance)).hasRole(GOVERNANCE_ROLE, msg.sender),
            "INVALID_ADMIN"
        );
        require(passport.passportPaused() == false, "Pausable: paused");
        bool isValid = false;
        address issuerOrProtocol;

        if (_to == governance.treasury()) {
            isValid = true;
            issuerOrProtocol = address(this);
        }

        if (!isValid) {
            address[] memory issuers = governance.getIssuers();
            for (uint256 i = 0; i < issuers.length; i++) {
                if (_to == governance.issuersTreasury(issuers[i])) {
                    isValid = true;
                    issuerOrProtocol = issuers[i];
                    break;
                }
            }
        }

        require(isValid, "WITHDRAWAL_ADDRESS_INVALID");
        require(_to != address(0), "WITHDRAW_ADDRESS_ZERO");
        require(_amount <= address(this).balance, "INSUFFICIENT_BALANCE");
        (bool sent,) = _to.call{value: _amount}("");
        require(sent, "FAILED_TO_TRANSFER_NATIVE_ETH");

        emit WithdrawEvent(issuerOrProtocol, _to, _amount);
    }


    function _authorizeUpgrade(address) internal view override {
        require(IAccessControlUpgradeable(address(governance)).hasRole(GOVERNANCE_ROLE, msg.sender), "INVALID_ADMIN");
    }

    /// @dev Returns if a user's data is greater than or equal to (GTE) a certain threshold
    /// @param _account user whose data is being checked
    /// @param _attribute keccak256 of the attribute type (ex: keccak256("TU_CREDIT_SCORE"))
    /// @param _verifiedAt timestamp of whewn data was issued
    /// @param _threshold threshold to compare the data to
    /// @param _flashSig signature of the flash query
    /// @return true if the data is GTE to the threshold, false otherwise
    function getFlashAttributeGTE(
        address _account,
        bytes32 _attribute,
        uint256 _verifiedAt,
        uint256 _threshold,
        bytes calldata _flashSig
    ) public payable override returns(bool) {
        if (_validateFlashAttrSignature(_account, _attribute, _verifiedAt, _threshold, _flashSig, keccak256('TRUE'))) {
            return true;
        }
        if (_validateFlashAttrSignature(_account, _attribute, _verifiedAt, _threshold, _flashSig, keccak256('FALSE'))) {
            return false;
        }

        revert("INVALID_ISSUER_OR_PARAMS");
    }

    /// @dev Returns true if the signature is valid
    /// @param _account user whose data is being checked
    /// @param _attribute keccak256 of the attribute type (ex: keccak256("TU_CREDIT_SCORE"))
    /// @param _verifiedAt timestamp of whewn data was issued
    /// @param _threshold threshold to compare the data to
    /// @param _flashSig signature of the flash query
    /// @param _expectedValue value of the flash query
    /// @return true if the signature is valid
    function _validateFlashAttrSignature(
        address _account,
        bytes32 _attribute,
        uint256 _verifiedAt,
        uint256 _threshold,
        bytes calldata _flashSig,
        bytes32 _expectedValue
    ) internal returns(bool) {
        bytes32 extractionHash = keccak256(abi.encode(_account, msg.sender, _attribute, _verifiedAt, _threshold, msg.value, _expectedValue, block.chainid));
        require(!_usedFlashSigHashes[extractionHash], "SIGNATURE_ALREADY_USED");

        bytes32 signedMsg = ECDSAUpgradeable.toEthSignedMessageHash(extractionHash);
        address signer = ECDSAUpgradeable.recover(signedMsg, _flashSig);

        if(IAccessControlUpgradeable(address(governance)).hasRole(ISSUER_ROLE, signer)) {
            require(governance.getIssuerStatus(signer), 'ISSUER_NOT_ACTIVE');
            require(governance.eligibleAttributes(_attribute), 'INVALID_ATTRIBUTE');
            require(governance.getIssuerAttributePermission(signer, _attribute), 'INVALID_ISSUER_ATTR_PERMISSION');

            emit FlashQueryEvent(_account, msg.sender, _attribute, msg.value);
            _usedFlashSigHashes[extractionHash] = true;
            (bool sent,) = payable(governance.issuersTreasury(signer)).call{value: msg.value}("");
            require(sent, "FAILED_TO_TRANSFER_NATIVE_ETH");
            return true;
        }
        return false;

    }

    /// @dev Returns boolean indicating whether an attribute has been attested to a wallet for a given issuer.
    /// @param _account account getting requested for attributes
    /// @param _attribute keccak256 of the attribute type (ex: keccak256("COUNTRY"))
    /// @param _issuer address of issuer
    /// @return boolean
    function hasPassportByIssuer(address _account, bytes32 _attribute, address _issuer) public view override returns(bool) {
        IQuadPassportStore.Attribute[] memory attributes = passport.attributes(_account, _attribute);
        for (uint256 i = 0; i < attributes.length; i++) {
            if (attributes[i].issuer == _issuer){
                return true;
            }
        }
        return false;
    }
 }

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate the implementation's compatibility when performing an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../StringsUpgradeable.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV // Deprecated in v4.8
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
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
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
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
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
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
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
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
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
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", StringsUpgradeable.toString(s.length), s));
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
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "./IQuadPassportStore.sol";
import "./IQuadSoulbound.sol";

interface IQuadPassport is IQuadSoulbound {
    event GovernanceUpdated(address indexed _oldGovernance, address indexed _governance);
    event SetPendingGovernance(address indexed _pendingGovernance);
    event SetAttributeReceipt(address indexed _account, address indexed _issuer, uint256 _fee, uint256 _tokenId);
    event BurnPassportsIssuer(address indexed _issuer, address indexed _account);
    event WithdrawEvent(address indexed _issuer, address indexed _treasury, uint256 _fee);

    function setAttributes(
        IQuadPassportStore.AttributeSetterConfig memory _config,
        bytes calldata _sigIssuer,
        bytes calldata _sigAccount
    ) external payable;

    function setAttributesBulk(
        IQuadPassportStore.AttributeSetterConfig[] memory _configs,
        bytes[] calldata _sigIssuers,
        bytes[] calldata _sigAccounts
    ) external payable;


    function setAttributesIssuer(
        address _account,
        IQuadPassportStore.AttributeSetterConfig memory _config,
        bytes calldata _sigIssuer
    ) external payable;

    function burnPassports(uint256 _tokenId) external;

    function burnPassportsIssuer(address _account, uint256 _tokenId) external;

    function setGovernance(address _governanceContract) external;

    function acceptGovernance() external;

    function attribute(address _account, bytes32 _attribute) external view returns (IQuadPassportStore.Attribute memory);

    function attributes(address _account, bytes32 _attribute) external view returns (IQuadPassportStore.Attribute[] memory);

    function withdraw(address payable _to, uint256 _amount) external;

    function passportPaused() external view returns(bool);

    function setTokenURI(uint256 _tokenId, string memory _uri) external;
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "../storage/QuadGovernanceStore.sol";

interface IQuadGovernance {
    event AttributePriceUpdatedFixed(bytes32 _attribute, uint256 _oldPrice, uint256 _price);
    event BusinessAttributePriceUpdatedFixed(bytes32 _attribute, uint256 _oldPrice, uint256 _price);
    event EligibleAttributeUpdated(bytes32 _attribute, bool _eligibleStatus);
    event EligibleAttributeByDIDUpdated(bytes32 _attribute, bool _eligibleStatus);
    event IssuerAdded(address indexed _issuer, address indexed _newTreasury);
    event IssuerDeleted(address indexed _issuer);
    event IssuerStatusChanged(address indexed issuer, bool newStatus);
    event IssuerAttributePermission(address indexed issuer, bytes32 _attribute,  bool _permission);
    event PassportAddressUpdated(address indexed _oldAddress, address indexed _address);
    event RevenueSplitIssuerUpdated(uint256 _oldSplit, uint256 _split);
    event TreasuryUpdated(address indexed _oldAddress, address indexed _address);
    event PreapprovalUpdated(address indexed _account, bool _status);

    function setTreasury(address _treasury) external;

    function setPassportContractAddress(address _passportAddr) external;

    function updateGovernanceInPassport(address _newGovernance) external;

    function setEligibleAttribute(bytes32 _attribute, bool _eligibleStatus) external;

    function setEligibleAttributeByDID(bytes32 _attribute, bool _eligibleStatus) external;

    function setTokenURI(uint256 _tokenId, string memory _uri) external;

    function setAttributePriceFixed(bytes32 _attribute, uint256 _price) external;

    function setBusinessAttributePriceFixed(bytes32 _attribute, uint256 _price) external;

    function setRevSplitIssuer(uint256 _split) external;

    function addIssuer(address _issuer, address _treasury) external;

    function deleteIssuer(address _issuer) external;

    function setIssuerStatus(address _issuer, bool _status) external;

    function setIssuerAttributePermission(address _issuer, bytes32 _attribute, bool _permission) external;

    function getEligibleAttributesLength() external view returns(uint256);

    function issuersTreasury(address) external view returns (address);

    function eligibleAttributes(bytes32) external view returns(bool);

    function eligibleAttributesByDID(bytes32) external view returns(bool);

    function eligibleAttributesArray(uint256) external view returns(bytes32);

    function setPreapprovals(address[] calldata, bool[] calldata) external;

    function preapproval(address) external view returns(bool);

    function pricePerAttributeFixed(bytes32) external view returns(uint256);

    function pricePerBusinessAttributeFixed(bytes32) external view returns(uint256);

    function revSplitIssuer() external view returns (uint256);

    function treasury() external view returns (address);

    function getIssuersLength() external view returns (uint256);

    function getAllIssuersLength() external view returns (uint256);

    function getIssuers() external view returns (address[] memory);

    function getAllIssuers() external view returns (address[] memory);

    function issuers(uint256) external view returns(address);

    function getIssuerStatus(address _issuer) external view returns(bool);

    function getIssuerAttributePermission(address _issuer, bytes32 _attribute) external view returns(bool);
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "../storage/QuadPassportStore.sol";

interface IQuadReader {
    event QueryEvent(address indexed _account, address indexed _caller, bytes32 _attribute);
    event QueryBulkEvent(address indexed _account, address indexed _caller, bytes32[] _attributes);
    event QueryFeeReceipt(address indexed _receiver, uint256 _fee);
    event WithdrawEvent(address indexed _issuer, address indexed _treasury, uint256 _fee);
    event FlashQueryEvent(address indexed _account, address indexed _caller, bytes32 _attribute, uint256 _fee);

    function queryFee(
        address _account,
        bytes32 _attribute
    ) external view returns(uint256);

    function queryFeeBulk(
        address _account,
        bytes32[] calldata _attributes
    ) external view returns(uint256);

    function getAttribute(
        address _account, bytes32 _attribute
    ) external payable returns(QuadPassportStore.Attribute memory attribute);

    function getAttributes(
        address _account, bytes32 _attribute
    ) external payable returns(QuadPassportStore.Attribute[] memory attributes);

    function getAttributesLegacy(
        address _account, bytes32 _attribute
    ) external payable returns(bytes32[] memory values, uint256[] memory epochs, address[] memory issuers);

    function getAttributesBulk(
        address _account, bytes32[] calldata _attributes
    ) external payable returns(QuadPassportStore.Attribute[] memory);

    function getAttributesBulkLegacy(
        address _account, bytes32[] calldata _attributes
    ) external payable returns(bytes32[] memory values, uint256[] memory epochs, address[] memory issuers);

    function balanceOf(address _account, bytes32 _attribute) external view returns(uint256);

    function withdraw(address payable _to, uint256 _amount) external;

    function getFlashAttributeGTE(
        address _account,
        bytes32 _attribute,
        uint256 _issuedAt,
        uint256 _threshold,
        bytes calldata _flashSig
    ) external payable returns(bool);

    function hasPassportByIssuer(address _account, bytes32 _attribute, address _issuer) external view returns(bool);
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

interface IQuadPassportStore {

    /// @dev Attribute store infomation as it relates to a single attribute
    /// `attrKeys` Array of keys defined by (wallet address/DID + data Type)
    /// `value` Attribute value
    /// `epoch` timestamp when the attribute has been verified by an Issuer
    /// `issuer` address of the issuer issuing the attribute
    struct Attribute {
        bytes32 value;
        uint256 epoch;
        address issuer;
    }

    /// @dev AttributeSetterConfig contains configuration for setting attributes for a Passport holder
    /// @notice This struct is used to abstract setAttributes function parameters
    /// `attrKeys` Array of keys defined by (wallet address/DID + data Type)
    /// `attrValues` Array of attributes values
    /// `attrTypes` Array of attributes types (ex: [keccak256("DID")]) used for validation
    /// `did` did of entity
    /// `tokenId` tokenId of the Passport
    /// `issuedAt` epoch when the passport has been issued by the Issuer
    /// `verifiedAt` epoch when the attribute has been attested by the Issuer
    /// `fee` Fee (in Native token) to pay the Issuer
    struct AttributeSetterConfig {
        bytes32[] attrKeys;
        bytes32[] attrValues;
        bytes32[] attrTypes;
        bytes32 did;
        uint256 tokenId;
        uint256 verifiedAt;
        uint256 issuedAt;
        uint256 fee;
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "../interfaces/IQuadPassport.sol";
import "../interfaces/IQuadGovernance.sol";

import "./QuadReaderStore.sol";

contract QuadReaderStoreV2 is QuadReaderStore{
    // SignatureHash => bool
    mapping(bytes32 => bool) internal _usedFlashSigHashes;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.3) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/IERC1967Upgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable, IERC1967Upgradeable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.3) (interfaces/IERC1967.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC-1967: Proxy Storage Slots. This interface contains the events defined in the ERC.
 *
 * _Available since v4.9._
 */
interface IERC1967Upgradeable {
    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Emitted when the beacon is changed.
     */
    event BeaconUpgraded(address indexed beacon);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/MathUpgradeable.sol";

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = MathUpgradeable.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, MathUpgradeable.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

interface IQuadSoulbound  {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    function uri(uint256 _tokenId) external view returns (string memory);

    /**
     * @dev ERC1155 balanceOf implementation
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
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "../interfaces/IQuadPassport.sol";

import "./QuadConstant.sol";

contract QuadGovernanceStore is QuadConstant {
    // Attributes
    bytes32[] internal _eligibleAttributesArray; // only stores account-level attributes
    mapping(bytes32 => bool) internal _eligibleAttributes;
    mapping(bytes32 => bool) internal _eligibleAttributesByDID;

    // TokenId
    mapping(uint256 => bool) internal _eligibleTokenId; // deprecated

    // Pricing
    mapping(bytes32 => uint256) internal _pricePerBusinessAttributeFixed;
    mapping(bytes32 => uint256) internal _pricePerAttributeFixed;

    // Issuers
    mapping(address => address) internal _issuerTreasury;
    mapping(address => bool) internal _issuerStatus;
    mapping(bytes32 => bool) internal _issuerAttributePermission;
    address[] internal _issuers;

    // Others
    uint256 internal _revSplitIssuer; // 50 means 50%;
    uint256 internal _maxEligibleTokenId; // deprecated
    IQuadPassport internal _passport;
    address internal _treasury;
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

contract QuadConstant {
    bytes32 public constant ISSUER_ROLE = keccak256("ISSUER_ROLE");
    bytes32 public constant GOVERNANCE_ROLE = keccak256("GOVERNANCE_ROLE");
    bytes32 public constant READER_ROLE = keccak256("READER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    bytes32 public constant DIGEST_TO_SIGN = 0x37937bf5ff1ecbf00bbd389ab7ca9a190d7e8c0a084b2893ece7923be1d2ec85;
    bytes32 internal constant ATTRIBUTE_DID = 0x09deac0378109c72d82cccd3c343a90f7020f0f1af78dcd4fc949c6301aa9488;
    bytes32 internal constant ATTRIBUTE_IS_BUSINESS = 0xaf369ce728c816785c72f1ff0222ca9553b2cb93729d6a803be6af0d2369239b;
    bytes32 internal constant ATTRIBUTE_COUNTRY = 0xc4713d2897c0d675d85b414a1974570a575e5032b6f7be9545631a1f922b26ef;
    bytes32 internal constant ATTRIBUTE_AML = 0xaf192d67680c4285e52cd2a94216ce249fb4e0227d267dcc01ea88f1b020a119;

    uint256[47] private __gap;
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "../interfaces/IQuadPassportStore.sol";
import "../interfaces/IQuadGovernance.sol";

import "./QuadConstant.sol";

contract QuadPassportStore is IQuadPassportStore, QuadConstant {

    IQuadGovernance public governance;
    address public pendingGovernance;

    // SignatureHash => bool
    mapping(bytes32 => bool) internal _usedSigHashes;

    string public symbol;
    string public name;

    // @deprecated (_attributesv2 should be used instead)
    mapping(bytes32 => Attribute[]) internal _attributes;

    // @deprecated
    mapping(bytes32 => uint256) internal _position;
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "../interfaces/IQuadPassport.sol";
import "../interfaces/IQuadGovernance.sol";

import "./QuadConstant.sol";

contract QuadReaderStore is QuadConstant{
    IQuadGovernance public governance;
    IQuadPassport public passport;
}