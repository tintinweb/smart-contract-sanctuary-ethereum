//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./AclRentalLogic.sol";

// solhint-disable no-empty-blocks
contract GeneralRentalLogic is AclRentalLogic {
    bytes32 public constant RENTAL_ID = keccak256("GeneralRentalLogic");

    constructor(AbstractContractControlList contractControlList)
        AclRentalLogic(contractControlList)
    {}

    function execute(
        address to,
        uint256 tokenId,
        uint64 expires,
        address,
        bytes memory signature,
        bytes memory data
    ) external payable virtual override returns (TokenAction memory) {
        bytes32 executationHash = getExecutionHash(
            RENTAL_ID,
            to,
            tokenId,
            expires,
            data
        );
        address signer = _getSigner(executationHash, signature);
        ensureHasRentalExecutorRole(signer);
        handlePaymentfromBytes(data, to);

        emit RentalExecuted(RENTAL_ID, tokenId, expires, data);

        return handleExecute(RENTAL_ID, to, tokenId, expires, data);
    }

    // solhint-disable no-unused-vars
    function handleExecute(
        bytes32,
        address to,
        uint256 tokenId,
        uint64 expires,
        bytes memory
    ) internal pure override returns (TokenAction memory) {
        return executeRent(to, tokenId, expires);
    }

    function executeRent(
        address to,
        uint256 tokenId,
        uint64 expires
    ) internal pure returns (TokenAction memory) {
        return
            // solhint-disable not-rely-on-time
            TokenAction(TokenActionType.MOVE_WRAPPED, expires, to, tokenId);
    }

    // solhint-disable no-unused-vars
    function configure(bytes memory, bytes memory)
        external
        view
        virtual
        override
        returns (bool, string memory)
    {
        return _configureNotAvailable();
    }

    function rentalId() external pure override returns (bytes32) {
        return RENTAL_ID;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../interfaces/IRentalLogic.sol";
import "../interfaces/IPaymentsModule.sol";
import "../ContractControlList.sol";
import {EIP712_DOMAIN_HASH} from "../meta/EIP712Domain.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract AclRentalLogic is IRentalLogic, IPaymentsModule {
    using ECDSA for bytes32;

    AbstractContractControlList internal ccl;

    constructor(AbstractContractControlList contractControlList) {
        ccl = contractControlList;
    }

    function ensureHasRentalExecutorRole(address addr) public view {
        // solhint-disable-next-line reason-string
        require(
            ccl.hasRentalExecutorRole(addr),
            "AclRentalLogic: addr doesn't have RENTAL_EXECUTOR_ROLE"
        );
    }

    function ensureHasRentalConfiguratorRole(address addr) public view {
        // solhint-disable-next-line reason-string
        require(
            ccl.hasRentalConfiguratorRole(addr),
            "AclRentalLogic: addr doesn't have RENTAL_CONFIGURATOR_ROLE"
        );
    }

    modifier onlyRentalExecutorRole(address addr) {
        ensureHasRentalExecutorRole(addr);
        _;
    }

    modifier onlyRentalConfiguratorRole(address addr) {
        ensureHasRentalConfiguratorRole(addr);
        _;
    }

    function getExecutionHash(
        bytes32 rental,
        address to,
        uint256 tokenId,
        uint64 expires,
        bytes memory data
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    uint16(0x1901),
                    EIP712_DOMAIN_HASH,
                    keccak256(
                        abi.encode(
                            keccak256(
                                "handleExecute(bytes32 rental,address to,uint256 tokenId,uint64 expires,bytes memory data)"
                            ),
                            rental,
                            to,
                            tokenId,
                            expires,
                            data
                        )
                    )
                )
            );
    }

    function getConfigurationHash(bytes32 rental, bytes memory data)
        public
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    uint16(0x1901),
                    EIP712_DOMAIN_HASH,
                    keccak256(
                        abi.encode(
                            keccak256(
                                "handleConfigure(bytes32 rentalId, bytes memory data)"
                            ),
                            rental,
                            data
                        )
                    )
                )
            );
    }

    function _getSigner(bytes32 messageHash_, bytes memory signature_)
        internal
        pure
        returns (address)
    {
        return messageHash_.toEthSignedMessageHash().recover(signature_);
    }

    function _configureNotAvailable()
        internal
        pure
        returns (bool, string memory)
    {
        return (false, "Rental logic doesn't have configuration option");
    }

    /// @notice Function responsible for applying rental logic.
    /// @param rentalId Id of of the rental method.
    /// @param to User that will get a token.
    /// @param tokenId Id of token.
    /// @param expires Point of time when the rental will not be relevant anymore.
    /// @param data Additional data used for rental logic execution.
    function handleExecute(
        bytes32 rentalId,
        address to,
        uint256 tokenId,
        uint64 expires,
        bytes memory data
    ) internal virtual returns (TokenAction memory);

    //TODO: IT IS MUST BE VIRTUAL?
    /// @notice Function responsible for handle payment.
    /// @param data Payment data to decode.
    function handlePaymentfromBytes(bytes memory data, address from)
        internal
        virtual
    {
        if (data.length > 0) {
            Payment memory payment = abi.decode(data, (Payment));
            handlePayment(payment, from);
        }
    }

    function handlePayment(Payment memory payment, address from)
        public
        payable
        virtual
    {
        uint256 currentValue = 0;
        if (payment.data.paymentType == PaymentType.NATIVE) {
            // solhint-disable-next-line reason-string
            require(
                payment.data.value == msg.value,
                "Payment value should be equal to message value"
            );
            for (uint256 i = 0; i < payment.parts.length; i++) {
                uint256 transferValue = (payment.data.value *
                    payment.parts[i].part) / payment.resolution;
                currentValue += transferValue;
                payable(payment.parts[i].addr).transfer(transferValue);
            }
        } else {
            for (uint256 i = 0; i < payment.parts.length; i++) {
                uint256 transferValue = (payment.data.value *
                    payment.parts[i].part) / payment.resolution;
                currentValue += transferValue;
                IERC20(payment.data.erc20Address).transferFrom(
                    from,
                    payment.parts[i].addr,
                    transferValue
                );
            }
        }
        require(currentValue == payment.data.value, "Payment failed");
        emit Paid(from, payment);
    }

    function encodePayment(Payment memory payment)
        external
        pure
        virtual
        returns (bytes memory)
    {
        return abi.encode(payment);
    }

    function handleConfigure(bytes32, bytes memory)
        internal
        virtual
        returns (bool, string memory)
    {
        return _configureNotAvailable();
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

/// @title IRentalLogic
/// @author Blocklabs
/// @notice Interface is base for all implemented rental logics.
interface IRentalLogic {
    /// @notice Action type that should be executed on an IERC712RentableWrapper
    enum TokenActionType {
        NONE,
        MOVE_WRAPPED,
        MOVE,
        TERMINATE_RENTAL
    }

    /// @notice Action that informs an IERC712RentableWrapper about action that should be executed.
    struct TokenAction {
        TokenActionType actionType;
        uint64 expires;
        address user;
        uint256 tokenId;
    }

    /// @notice Event informs about configuration change of the particular supported rental logic.
    /// @dev Event should be emitted only in case of success configuration of the contract.
    /// @param rentalId Id of the rentalLogic. This id is created from keccak256 of the logic name.
    /// @param data Additional data used to configure the contract. RentalLogic is responsible for implementing the deserialisation of additional data
    event RentalConfigured(bytes32 indexed rentalId, bytes data);

    /// @notice Event informs about successfully executing of the rental logic.
    /// @dev Event should be emitted only in case of success rental execution via logic.
    /// @param rentalId Id of the rentalLogic. This id is created from keccak256 of the logic name.
    /// @param tokenId Id of the token which will be rented.
    /// @param expires UNIX timestamp - information about the expiration of the token renting.
    /// @param data Additional data used to execute the rental logic. RentalLogic is responsible for implementing the deserialisation of additional data.
    event RentalExecuted(
        bytes32 indexed rentalId,
        uint256 indexed tokenId,
        uint64 expires,
        bytes data
    );

    /// @notice Main functon used to executing rental logic.
    /// @dev Function redirected from IERC712RentableWrapper execute function.
    /// @param to User trying to borrow a token.
    /// @param tokenId Id of the token.
    /// @param expires Point of time when the rental is not relevant anymore.
    /// @param signature Signed message of the rental parameters needed by logic. Signature is created based on EIP721 domain spec.
    /// @param data Additional data used by logic execution
    function execute(
        address to,
        uint256 tokenId,
        uint64 expires,
        address collection,
        bytes memory signature,
        bytes memory data
    ) external payable returns (TokenAction memory);

    /// @notice Main functon used to configuration of the rental logic.
    /// @param signature Signed message of the rental parameters needed by the logic. Signature is created based on EIP721 domain spec.
    /// @param data Additional data used by logic execution
    function configure(bytes memory signature, bytes memory data)
        external
        returns (bool, string memory);

    /// @notice Function returns the id of the rental logic.
    /// @return keccak256 of the rental logic name.
    function rentalId() external view returns (bytes32);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IPaymentsModule {
    enum PaymentType {
        NATIVE,
        ERC20
    }

    /// @notice PaymentData struct has all infomation related to payment.
    /// @param erc20Address address of erc20 payment token.
    /// @param value of the payment.
    /// @param paymentType type of the payment
    struct PaymentData {
        PaymentType paymentType;
        address erc20Address;
        uint256 value;
    }

    /// @notice PaymentPercentage struct has all infomation about percentage of the payment.
    /// @param addr address of the account where amount will be send.
    /// @param part part of the whole amount of token that will be send.
    struct PaymentPercentage {
        address addr;
        uint256 part;
    }

    /// @notice Payment struct has all infomation about  payment.
    /// @param data of the payment.
    /// @param parts information about all addresses where the value is going to be send.
    /// @param resolution use to calculate part of the value.
    struct Payment {
        PaymentData data;
        PaymentPercentage[] parts;
        uint256 resolution;
    }

    /// @notice Paid is emitted after successfully exectution of the payment.
    /// @param payer address of the payer.
    /// @param payment information about payment.
    event Paid(address indexed payer, Payment payment);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./AbstractContractControlList.sol";

contract ContractControlList is AccessControl, AbstractContractControlList {
    constructor(address admin) {
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _setupRole(RENTAL_EXECUTOR_ROLE, admin);
        _setupRole(RENTAL_CONFIGURATOR_ROLE, admin);
        _setupRole(RENTAL_REGISTRATION_ROLE, admin);
        _setupRole(COLLECTION_OWNER_SETTER_ROLE, admin);
    }

    function hasRentalConfiguratorRole(address addr)
        external
        view
        override
        returns (bool)
    {
        return hasRole(RENTAL_CONFIGURATOR_ROLE, addr);
    }

    function hasRentalRegistrationRole(address addr)
        external
        view
        override
        returns (bool)
    {
        return hasRole(RENTAL_REGISTRATION_ROLE, addr);
    }

    function hasRentalExecutorRole(address addr)
        external
        view
        override
        returns (bool)
    {
        return hasRole(RENTAL_EXECUTOR_ROLE, addr);
    }

    function hasCollectionOwnerSetterRole(address addr)
        external
        view
        override
        returns (bool)
    {
        return hasRole(COLLECTION_OWNER_SETTER_ROLE, addr);
    }

    function hasTokenActionProvider(address addr)
        external
        view
        override
        returns (bool)
    {
        return hasRole(TOKEN_ACTION_PROVIDER, addr);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

bytes32 constant EIP712_DOMAIN_HASH = keccak256(
    abi.encode(
        keccak256(
            "EIP712Domain(string name, string version, address verifyingContract, uint256 signedAt)"
        )
    )
);

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.3) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

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
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/IAccessControl.sol";

abstract contract AbstractContractControlList is IAccessControl {
    bytes32 public constant RENTAL_EXECUTOR_ROLE =
        keccak256("RENTAL_EXECUTOR_ROLE");

    bytes32 public constant RENTAL_CONFIGURATOR_ROLE =
        keccak256("RENTAL_CONFIGURATOR_ROLE");

    bytes32 public constant RENTAL_REGISTRATION_ROLE =
        keccak256("RENTAL_REGISTRATION_ROLE");

    bytes32 public constant COLLECTION_OWNER_SETTER_ROLE =
        keccak256("COLLECTION_OWNER_SETTER_ROLE");

    bytes32 public constant TOKEN_ACTION_PROVIDER =
        keccak256("TOKEN_ACTION_PROVIDER");

    function hasRentalConfiguratorRole(address addr)
        external
        view
        virtual
        returns (bool);

    function hasRentalRegistrationRole(address addr)
        external
        view
        virtual
        returns (bool);

    function hasRentalExecutorRole(address addr)
        external
        view
        virtual
        returns (bool);

    function hasCollectionOwnerSetterRole(address addr)
        external
        view
        virtual
        returns (bool);

    function hasTokenActionProvider(address addr)
        external
        view
        virtual
        returns (bool);
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