// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

/* solhint-disable avoid-low-level-calls */
/* solhint-disable no-inline-assembly */
/* solhint-disable reason-string */

import "./BaseWallet.sol";
import "./ACL.sol";
import "./helpers/Signatures.sol";
import "./helpers/Calldata.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/interfaces/IERC1271.sol";

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

/**
 * minimal wallet.
 *  this is sample minimal wallet.
 *  has execute, eth handling methods
 *  has a single signer that can send requests through the entryPoint.
 */
contract SmartWallet is BaseWallet, ACL, IERC1271 {

    using ECDSA for bytes32;
    using UserOperationLib for UserOperation;
    using Signatures for UserOperation;
    using Calldata for bytes;

    enum PendingRequestType {
        none,
        addGuardian,
        revokeGuardian
    }

    event PendingRequestEvent(
        address indexed account,
        PendingRequestType indexed pendingRequestType,
        uint256 effectiveAt
    );

    struct PendingRequest {
        PendingRequestType pendingRequestType;
        uint256 effectiveAt;
    }
    mapping(address => PendingRequest) public pendingGuardian;
    uint256 public guardianDelay = 1 ; // 1 sec for POC

    function isGuardianActionAllowed(UserOperation calldata op)
        internal
        pure
        returns (bool)
    {
        if (op.callData.length == 0) return false;
        return op.callData.isTransferOwner();
    }

    //explicit sizes of nonce, to fit a single storage cell with "owner"
    uint96 private _nonce;

    function nonce() public view virtual override returns (uint256) {
        return _nonce;
    }

    function entryPoint() public view virtual override returns (EntryPoint) {
        return _entryPoint;
    }

    EntryPoint private _entryPoint;

    event EntryPointChanged(
        address indexed oldEntryPoint,
        address indexed newEntryPoint
    );

    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}

    constructor(
        EntryPoint anEntryPoint,
        address anOwner,
        IERC20 token,
        address paymaster
    ) {
        _entryPoint = anEntryPoint;
        require(anOwner != address(0), "ACL: Owner cannot be zero");
        _setRoleAdmin(OWNER_ROLE, OWNER_ROLE);
        _grantRole(OWNER_ROLE, anOwner);

        // Then we set `OWNER_ROLE` as the admin role for `GUARDIAN_ROLE` as well.
        _setRoleAdmin(GUARDIAN_ROLE, OWNER_ROLE);

        // approve paymaster to transfer tokens from this wallet on deploy
        require(token.approve(paymaster, type(uint).max));
    }

    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    function _onlyOwner() internal view {
        //directly from EOA owner, or through the entryPoint (which gets redirected through execFromEntryPoint)
        require(
            hasRole(OWNER_ROLE, msg.sender) || msg.sender == address(this),
            "only owner"
        );
    }

    /**
     * transfer eth value to a destination address
     */
    function transfer(address payable dest, uint256 amount) external onlyOwner {
        dest.transfer(amount);
    }

    /**
     * execute a transaction (called directly from owner, not by entryPoint)
     */
    function exec(
        address dest,
        uint256 value,
        bytes calldata func
    ) external onlyOwner {
        _call(dest, value, func);
    }

    /**
     * execute a sequence of transaction
     */
    function execBatch(address[] calldata dest, bytes[] calldata func)
        external
        onlyOwner
    {
        require(dest.length == func.length, "wrong array lengths");
        for (uint256 i = 0; i < dest.length; i++) {
            _call(dest[i], 0, func[i]);
        }
    }

    /**
     * change entry-point:
     * a wallet must have a method for replacing the entryPoint, in case the the entryPoint is
     * upgraded to a newer version.
     */
    function _updateEntryPoint(address newEntryPoint) internal override {
        emit EntryPointChanged(address(_entryPoint), newEntryPoint);
        _entryPoint = EntryPoint(payable(newEntryPoint));
    }

    function _requireFromAdmin() internal view override {
        _onlyOwner();
    }

    /**
     * validate the userOp is correct.
     * revert if it doesn't.
     * - must only be called from the entryPoint.
     * - make sure the signature is of our supported signer.
     * - validate current nonce matches request nonce, and increment it.
     * - pay prefund, in case current deposit is not enough
     */
    modifier requireFromEntryPoint() {
        require(
            msg.sender == address(entryPoint()),
            "wallet: not from EntryPoint"
        );
        _;
    }

    // called by entryPoint, only after validateUserOp succeeded.
    function execFromEntryPoint(
        address dest,
        uint256 value,
        bytes calldata func
    ) external requireFromEntryPoint {
        _call(dest, value, func);
    }

    /// implement template method of BaseWallet
    function _validateAndUpdateNonce(UserOperation calldata userOp)
        internal
        override
    {
        require(_nonce++ == userOp.nonce, "wallet: invalid nonce");
    }

    /// implement template method of BaseWallet
    function _validateSignature(
        UserOperation calldata userOp,
        bytes32 requestId
    ) internal view override {
        SignatureData memory signatureData = userOp.decodeSignature();
        signatureData.mode == SignatureMode.owner
            ? _validateOwnerSignature(signatureData, requestId)
            : _validateGuardiansSignature(signatureData, userOp, requestId);
    }

    function _call(
        address target,
        uint256 value,
        bytes memory data
    ) internal {
        (bool success, bytes memory result) = target.call{value: value}(data);
        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }
    }

    /**
     * check current wallet deposit in the entryPoint
     */
    function getDeposit() public view returns (uint256) {
        return entryPoint().balanceOf(address(this));
    }

    /**
     * deposit more funds for this wallet in the entryPoint
     */
    function addDeposit() public payable {
        (bool req, ) = address(entryPoint()).call{value: msg.value}("");
        require(req);
    }

    function grantGuardianConfirmation(address account) external override {
        require(!isOwner(account), "ACL: Owner cannot be guardian");
        require(
            pendingGuardian[account].pendingRequestType ==
                PendingRequestType.addGuardian,
            "add guardian request not exist"
        );
        require(
            block.timestamp > pendingGuardian[account].effectiveAt,
            "time delay not pass"
        );
        _grantRole(GUARDIAN_ROLE, account);
        pendingGuardian[account].pendingRequestType = PendingRequestType.none;
    }

    function revokeGuardianConfirmation(address account) external override {
        require(
            pendingGuardian[account].pendingRequestType ==
                PendingRequestType.revokeGuardian,
            "revoke guardian request not exist"
        );
        require(
            block.timestamp > pendingGuardian[account].effectiveAt,
            "time delay not pass"
        );
        _revokeRole(GUARDIAN_ROLE, account);
        pendingGuardian[account].pendingRequestType = PendingRequestType.none;
    }

    function deleteGuardianRequest(address account)
        external
        override
        requireFromEntryPoint
    {
        require(
            pendingGuardian[account].pendingRequestType !=
                PendingRequestType.none,
            "request not exist"
        );
        pendingGuardian[account].pendingRequestType = PendingRequestType.none;
        emit PendingRequestEvent(account, PendingRequestType.none, 0);
    }

    function grantGuardianRequest(address account)
        external
        override
        requireFromEntryPoint
    {
        require(!isOwner(account), "ACL: Owner cannot be guardian");
        uint256 effectiveAt = block.timestamp + guardianDelay;
        pendingGuardian[account] = PendingRequest(
            PendingRequestType.addGuardian,
            effectiveAt
        );
        emit PendingRequestEvent(
            account,
            PendingRequestType.addGuardian,
            effectiveAt
        );
    }

    function revokeGuardianRequest(address account)
        external
        override
        requireFromEntryPoint
    {
        uint256 effectiveAt = block.timestamp + guardianDelay;
        pendingGuardian[account] = PendingRequest(
            PendingRequestType.revokeGuardian,
            effectiveAt
        );
        emit PendingRequestEvent(
            account,
            PendingRequestType.revokeGuardian,
            effectiveAt
        );
    }

    function transferOwner(address account)
        external
        override
        requireFromEntryPoint
    {
        require(account != address(0), "ACL: Owner cannot be zero");
        _revokeRole(OWNER_ROLE, getRoleMember(OWNER_ROLE, 0));
        _grantRole(OWNER_ROLE, account);
    }

    /**
     * withdraw value from the wallet's deposit
     * @param withdrawAddress target to send to
     * @param amount to withdraw
     */
    function withdrawDepositTo(address payable withdrawAddress, uint256 amount)
        public
        onlyOwner
    {
        entryPoint().withdrawTo(withdrawAddress, amount);
    }

    function _validateOwnerSignature(
        SignatureData memory signatureData,
        bytes32 requestId
    ) internal view {
        SignatureValue memory value = signatureData.values[0];
        _validateOwnerSignature(
            value.signer,
            requestId.toEthSignedMessageHash(),
            value.signature
        );
    }

    /**
     * @dev Internal function to validate guardians signatures
     */
    function _validateGuardiansSignature(
        SignatureData memory signatureData,
        UserOperation calldata op,
        bytes32 requestId
    ) internal view {
        require(getGuardiansCount() > 0, "Wallet: No guardians allowed");
        require(isGuardianActionAllowed(op), "Wallet: Invalid guardian action");
        require(
            signatureData.values.length >= getMinGuardiansSignatures(),
            "Wallet: Insufficient guardians"
        );
        // There cannot be an owner with address 0.
        address lastGuardian = address(0);
        address currentGuardian;

        for (uint256 i = 0; i < signatureData.values.length; i++) {
            SignatureValue memory value = signatureData.values[i];
            _validateGuardianSignature(
                value.signer,
                requestId.toEthSignedMessageHash(),
                value.signature
            );
            currentGuardian = value.signer;
            require(
                currentGuardian > lastGuardian,
                "Invalid guardian address provided"
            );
            lastGuardian = currentGuardian;
        }
    }

    function isValidSignature(bytes32 hash, bytes memory signature)
        external
        view
        override
        returns (bytes4)
    {
        require(isOwner(hash.recover(signature)), "ACL: Invalid signature");
        return IERC1271.isValidSignature.selector;
    }
}

pragma solidity ^0.8.12;

/* solhint-disable avoid-low-level-calls */
/* solhint-disable no-inline-assembly */
/* solhint-disable reason-string */

import "./IWallet.sol";
import "./EntryPoint.sol";

/**
 * Basic wallet implementation.
 * this contract provides the basic logic for implementing the IWallet interface  - validateUserOp
 * specific wallet implementation should inherit it and provide the wallet-specific logic
 */
abstract contract BaseWallet is IWallet {
    using UserOperationLib for UserOperation;

    /**
     * return the wallet nonce.
     * subclass should return a nonce value that is used both by _validateAndUpdateNonce, and by the external provider (to read the current nonce)
     */
    function nonce() public view virtual returns (uint256);

    /**
     * return the entryPoint used by this wallet.
     * subclass should return the current entryPoint used by this wallet.
     */
    function entryPoint() public view virtual returns (EntryPoint);

    /**
     * Validate user's signature and nonce.
     * subclass doesn't override this method. instead, it should override the specific internal validation methods.
     */
    function validateUserOp(
        UserOperation calldata userOp,
        bytes32 requestId,
        uint256 missingWalletFunds
    ) external override {
        _requireFromEntryPoint();
        _validateSignature(userOp, requestId);
        //during construction, the "nonce" field hold the salt.
        // if we assert it is zero, then we allow only a single wallet per owner.
        if (userOp.initCode.length == 0) {
            _validateAndUpdateNonce(userOp);
        }
        _payPrefund(missingWalletFunds);
    }

    /**
     * ensure the request comes from the known entrypoint.
     */
    function _requireFromEntryPoint() internal view virtual {
        require(
            msg.sender == address(entryPoint()),
            "wallet: not from EntryPoint"
        );
    }

    /**
     * validate the signature is valid for this message.
     * @param userOp validate the userOp.signature field
     * @param requestId convenient field: the hash of the request, to check the signature against
     *          (also hashes the entrypoint and chain-id)
     */
    function _validateSignature(
        UserOperation calldata userOp,
        bytes32 requestId
    ) internal view virtual;

    /**
     * validate the current nonce matches the UserOperation nonce.
     * then it should update the wallet's state to prevent replay of this UserOperation.
     * called only if initCode is empty (since "nonce" field is used as "salt" on wallet creation)
     * @param userOp the op to validate.
     */
    function _validateAndUpdateNonce(UserOperation calldata userOp)
        internal
        virtual;

    /**
     * sends to the entrypoint (msg.sender) the missing funds for this transaction.
     * subclass MAY override this method for better funds management
     * (e.g. send to the entryPoint more than the minimum required, so that in future transactions
     * it will not be required to send again)
     * @param missingWalletFunds the minimum value this method should send the entrypoint.
     *  this value MAY be zero, in case there is enough deposit, or the userOp has a paymaster.
     */
    function _payPrefund(uint256 missingWalletFunds) internal virtual {
        if (missingWalletFunds != 0) {
            //pay required prefund. make sure NOT to use the "gas" opcode, which is banned during validateUserOp
            // (and used by default by the "call")
            (bool success, ) = payable(msg.sender).call{
                value: missingWalletFunds,
                gas: type(uint256).max
            }("");
            (success);
            //ignore failure (its EntryPoint's job to verify, not wallet.)
        }
    }

    /**
     * expose an api to modify the entryPoint.
     * must be called by current "admin" of the wallet.
     * @param newEntryPoint the new entrypoint to trust.
     */
    function updateEntryPoint(address newEntryPoint) external {
        _requireFromAdmin();
        _updateEntryPoint(newEntryPoint);
    }

    /**
     * ensure the caller is allowed "admin" operations (such as changing the entryPoint)
     * default implementation trust the wallet itself (or any signer that passes "validateUserOp")
     * to be the "admin"
     */
    function _requireFromAdmin() internal view virtual {
        require(
            msg.sender == address(this) || msg.sender == address(entryPoint()),
            "not admin"
        );
    }

    /**
     * update the current entrypoint.
     * subclass should override and update current entrypoint
     */
    function _updateEntryPoint(address) internal virtual;
}

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";


abstract contract ACL is AccessControlEnumerable {
    using ECDSA for bytes32;

    // solhint-disable var-name-mixedcase
    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");
    bytes32 public constant GUARDIAN_ROLE = keccak256("GUARDIAN_ROLE");

    /**
     * @dev Tells whether an account is owner or not
     */
    function isOwner(address account) public view returns (bool) {
        return hasRole(OWNER_ROLE, account);
    }

    /**
     * @dev Tells the how many owners the wallet has
     */
    function getOwnersCount() external view returns (uint256) {
        return getRoleMemberCount(OWNER_ROLE);
    }

    /**
     * @dev Tells the address of an owner at a particular index
     */
    function getOwner(uint256 index) external view returns (address) {
        return getRoleMember(OWNER_ROLE, index);
    }

    /**
     * @dev Tells the how many guardians the wallet has
     */
    function isGuardian(address account) public view returns (bool) {
        return hasRole(GUARDIAN_ROLE, account);
    }

    /**
     * @dev Tells the how many guardians the wallet has
     */
    function getGuardiansCount() public view returns (uint256) {
        return getRoleMemberCount(GUARDIAN_ROLE);
    }

    /**
     * @dev Tells whether an account is guardian or not
     */
    function getGuardian(uint256 index) external view returns (address) {
        return getRoleMember(GUARDIAN_ROLE, index);
    }

    /**
     * @dev Tells the min number amount of guardians signatures in order for an op to approved
     */
    function getMinGuardiansSignatures() public view returns (uint256) {
        return Math.ceilDiv(getGuardiansCount(), 2);
    }

    /**
     * @dev Grants guardian permissions to an account confirmation
     */
    function grantGuardianConfirmation(address account) external virtual;

    /**
     * @dev Revokes guardian permissions to an account confirmation
     */
    function revokeGuardianConfirmation(address account) external virtual;

       /**
     * @dev Grants guardian permissions to an account reqeust
     */
    function grantGuardianRequest(address account) external virtual;

    /**
     * @dev delete Request
     */
    function deleteGuardianRequest(address account) external virtual;


      /**
     * @dev Revokes guardian permissions to an account request
     */
    function revokeGuardianRequest(address account) external virtual;

    /**
     * @dev Transfers owner permissions from the owner at index #0 to another account
     */
    function transferOwner(address account) external virtual;

    /**
     * @dev Internal function to validate owner's signatures
     */
    function _validateOwnerSignature(
        address signer,
        bytes32 hash,
        bytes memory signature
    ) internal view {
        require(
            SignatureChecker.isValidSignatureNow(signer, hash, signature),
            "ACL: Invalid owner sig"
        );
        require(isOwner(signer), "ACL: Signer not an owner");
    }

    /**
     * @dev Internal function to validate guardian's signatures
     */
    function _validateGuardianSignature(
        address signer,
        bytes32 hash,
        bytes memory signature
    ) internal view {
        require(
            SignatureChecker.isValidSignatureNow(signer, hash, signature),
            "ACL: Invalid guardian sig"
        );
        require(isGuardian(signer), "ACL: Signer not a guardian");
    }
}

pragma solidity ^0.8.12;

import "../UserOperation.sol";

/**
 * @dev Signatures layout used by the Paymasters and Wallets internally
 * @param mode whether it is an owner's or a guardian's signature
 * @param values list of signatures value to validate
 */
struct SignatureData {
    SignatureMode mode;
    SignatureValue[] values;
}

/**
 * @dev Signature's value layout used by the Paymasters and Wallets internally
 * @param signer address of the owner or guardian signing the data
 * @param signature data signed
 */
struct SignatureValue {
    address signer;
    bytes signature;
}

/**
 * @dev Signature mode to denote whether it is an owner's or a guardian's signature
 */
enum SignatureMode {
    owner,
    guardians
}

library Signatures {
    /**
     * @dev Decodes a user operation's signature assuming the expected layout defined by the Signatures library
     */
    function decodeSignature(UserOperation calldata op)
        internal
        pure
        returns (SignatureData memory)
    {
        return decodeSignature(op.signature);
    }

    /**
     * @dev Decodes a signature assuming the expected layout defined by the Signatures library
     */
    function decodeSignature(bytes memory signature)
        internal
        pure
        returns (SignatureData memory)
    {
        (SignatureMode mode, SignatureValue[] memory values) = abi.decode(
            signature,
            (SignatureMode, SignatureValue[])
        );
        return SignatureData(mode, values);
    }
}

pragma solidity ^0.8.12;

import "../ACL.sol";

library Calldata {
    /**
     * @dev Tells whether a calldata is calling to the ACL's transfer owner method
     */
    function isTransferOwner(bytes memory self) internal pure returns (bool) {
        return selector(self) == ACL.transferOwner.selector;
    }

    function selector(bytes memory self) internal pure returns (bytes4) {
        return bytes4(self);
    }
}

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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1271.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

import "./UserOperation.sol";

interface IWallet {

    /**
     * Validate user's signature and nonce
     * the entryPoint will make the call to the recipient only if this validation call returns successfuly.
     *
     * @dev Must validate caller is the entryPoint.
     *      Must validate the signature and nonce
     * @param userOp the operation that is about to be executed.
     * @param requestId hash of the user's request data. can be used as the basis for signature.
     * @param requiredPrefund the minimum amount to transfer to the sender(entryPoint) to be able to make the call.
     *      The excess is left as a deposit in the entrypoint, for future calls.
     *      can be withdrawn anytime using "entryPoint.withdrawTo()"
     *      In case there is a paymaster in the request (or the current deposit is high enough), this value will be zero.
     */
    function validateUserOp(UserOperation calldata userOp, bytes32 requestId, uint requiredPrefund) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

import "./StakeManager.sol";
import "./UserOperation.sol";
import "./IWallet.sol";
import "./IPaymaster.sol";

interface ICreate2Deployer {
    function deploy(bytes memory _initCode, bytes32 _salt) external returns (address);
}

contract EntryPoint is StakeManager {

    using UserOperationLib for UserOperation;

    enum PaymentMode {
        paymasterStake, // if paymaster is set, use paymaster's stake to pay.
        walletStake // pay with wallet deposit.
    }

    uint public immutable paymasterStake;
    address public immutable create2factory;

    event UserOperationEvent(bytes32 indexed requestId, address indexed sender, address indexed paymaster, uint nonce, uint actualGasCost, uint actualGasPrice, bool success);
    event UserOperationRevertReason(bytes32 indexed requestId, address indexed sender, uint nonce, bytes revertReason);

    //handleOps reverts with this error struct, to mark the offending op
    // NOTE: if simulateOp passes successfully, there should be no reason for handleOps to fail on it.
    // @param opIndex - index into the array of ops to the failed one (in simulateOp, this is always zero)
    // @param paymaster - if paymaster.validatePaymasterUserOp fails, this will be the paymaster's address. if validateUserOp failed,
    //      this value will be zero (since it failed before accessing the paymaster)
    // @param reason - revert reason
    //  only to aid troubleshooting of wallet/paymaster reverts
    error FailedOp(uint opIndex, address paymaster, string reason);

    /**
     * @param _create2factory - contract to "create2" wallets (not the EntryPoint itself, so that it can be upgraded)
     * @param _paymasterStake - locked stake of paymaster (actual value should also cover TX cost)
     * @param _unstakeDelaySec - minimum time (in seconds) a paymaster stake must be locked
     */
    constructor(address _create2factory, uint _paymasterStake, uint32 _unstakeDelaySec) StakeManager(_unstakeDelaySec) {
        create2factory = _create2factory;
        paymasterStake = _paymasterStake;
    }

    /**
     * Execute the given UserOperation.
     * @param op the operation to execute
     * @param beneficiary the address to receive the fees
     */
    function handleOp(UserOperation calldata op, address payable beneficiary) public {

        uint preGas = gasleft();

    unchecked {
        bytes32 requestId = getRequestId(op);
        (uint256 prefund, PaymentMode paymentMode, bytes memory context) = _validatePrepayment(0, op, requestId);
        UserOpInfo memory opInfo = UserOpInfo(
            requestId,
            prefund,
            paymentMode,
            0,
            preGas - gasleft() + op.preVerificationGas
        );

        uint actualGasCost;

        try this.internalHandleOp(op, opInfo, context) returns (uint _actualGasCost) {
            actualGasCost = _actualGasCost;
        } catch {
            uint actualGas = preGas - gasleft() + opInfo.preOpGas;
            actualGasCost = handlePostOp(0, IPaymaster.PostOpMode.postOpReverted, op, opInfo, context, actualGas);
        }

        compensate(beneficiary, actualGasCost);
    } // unchecked
    }

    function compensate(address payable beneficiary, uint amount) internal {
        (bool success,) = beneficiary.call{value : amount}("");
        require(success);
    }

    /**
     * Execute a batch of UserOperation.
     * @param ops the operations to execute
     * @param beneficiary the address to receive the fees
     */
    function handleOps(UserOperation[] calldata ops, address payable beneficiary) public {

        uint opslen = ops.length;
        UserOpInfo[] memory opInfos = new UserOpInfo[](opslen);

    unchecked {
        for (uint i = 0; i < opslen; i++) {
            uint preGas = gasleft();
            UserOperation calldata op = ops[i];

            bytes memory context;
            uint contextOffset;
            bytes32 requestId = getRequestId(op);
            uint prefund;
            PaymentMode paymentMode;
            (prefund, paymentMode, context) = _validatePrepayment(i, op, requestId);
            assembly {contextOffset := context}
            opInfos[i] = UserOpInfo(
                requestId,
                prefund,
                paymentMode,
                contextOffset,
                preGas - gasleft() + op.preVerificationGas
            );
        }

        uint collected = 0;

        for (uint i = 0; i < ops.length; i++) {
            uint preGas = gasleft();
            UserOperation calldata op = ops[i];
            UserOpInfo memory opInfo = opInfos[i];
            uint contextOffset = opInfo._context;
            bytes memory context;
            assembly {context := contextOffset}

            try this.internalHandleOp(op, opInfo, context) returns (uint _actualGasCost) {
                collected += _actualGasCost;
            } catch {
                uint actualGas = preGas - gasleft() + opInfo.preOpGas;
                collected += handlePostOp(i, IPaymaster.PostOpMode.postOpReverted, op, opInfo, context, actualGas);
            }
        }

        compensate(beneficiary, collected);
    } //unchecked
    }

    struct UserOpInfo {
        bytes32 requestId;
        uint prefund;
        PaymentMode paymentMode;
        uint _context;
        uint preOpGas;
    }

    function internalHandleOp(UserOperation calldata op, UserOpInfo calldata opInfo, bytes calldata context) external returns (uint actualGasCost) {
        uint preGas = gasleft();
        require(msg.sender == address(this));

        IPaymaster.PostOpMode mode = IPaymaster.PostOpMode.opSucceeded;
        if (op.callData.length > 0) {

            (bool success,bytes memory result) = address(op.getSender()).call{gas : op.callGas}(op.callData);
            if (!success) {
                if (result.length > 0) {
                    emit UserOperationRevertReason(opInfo.requestId, op.getSender(), op.nonce, result);
                }
                mode = IPaymaster.PostOpMode.opReverted;
            }
        }

    unchecked {
        uint actualGas = preGas - gasleft() + opInfo.preOpGas;
        return handlePostOp(0, mode, op, opInfo, context, actualGas);
    }
    }

    /**
     * generate a request Id - unique identifier for this request.
     * the request ID is a hash over the content of the userOp (except the signature).
     */
    function getRequestId(UserOperation calldata userOp) public view returns (bytes32) {
        return keccak256(abi.encode(userOp.hash(), address(this), block.chainid));
    }

    /**
    * Simulate a call to wallet.validateUserOp and paymaster.validatePaymasterUserOp.
    * Validation succeeds of the call doesn't revert.
    * @dev The node must also verify it doesn't use banned opcodes, and that it doesn't reference storage outside the wallet's data.
     *      In order to split the running opcodes of the wallet (validateUserOp) from the paymaster's validatePaymasterUserOp,
     *      it should look for the NUMBER opcode at depth=1 (which itself is a banned opcode)
     * @return preOpGas total gas used by validation (including contract creation)
     * @return prefund the amount the wallet had to prefund (zero in case a paymaster pays)
     */
    function simulateValidation(UserOperation calldata userOp) external returns (uint preOpGas, uint prefund) {
        uint preGas = gasleft();

        bytes32 requestId = getRequestId(userOp);
        (prefund,,) = _validatePrepayment(0, userOp, requestId);
        preOpGas = preGas - gasleft() + userOp.preVerificationGas;

        require(msg.sender == address(0), "must be called off-chain with from=zero-addr");
    }

    function _getPaymentInfo(UserOperation calldata userOp) internal view returns (uint requiredPrefund, PaymentMode paymentMode) {
        requiredPrefund = userOp.requiredPreFund();
        if (userOp.hasPaymaster()) {
            paymentMode = PaymentMode.paymasterStake;
        } else {
            paymentMode = PaymentMode.walletStake;
        }
    }

    // create the sender's contract if needed.
    function _createSenderIfNeeded(UserOperation calldata op) internal {
        if (op.initCode.length != 0) {
            // note that we're still under the gas limit of validate, so probably
            // this create2 creates a proxy account.
            // @dev initCode must be unique (e.g. contains the signer address), to make sure
            //   it can only be executed from the entryPoint, and called with its initialization code (callData)
            address sender1 = ICreate2Deployer(create2factory).deploy(op.initCode, bytes32(op.nonce));
            require(sender1 != address(0), "create2 failed");
            require(sender1 == op.getSender(), "sender doesn't match create2 address");
        }
    }

    /// Get counterfactual sender address.
    ///  Calculate the sender contract address that will be generated by the initCode and salt in the UserOperation.
    function getSenderAddress(bytes memory initCode, uint _salt) public view returns (address) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(create2factory),
                _salt,
                keccak256(initCode)
            )
        );

        // NOTE: cast last 20 bytes of hash to address
        return address(uint160(uint256(hash)));
    }

    //call wallet.validateUserOp, and validate that it paid as needed.
    // return actual value sent from wallet to "this"
    function _validateWalletPrepayment(uint opIndex, UserOperation calldata op, bytes32 requestId, uint requiredPrefund, PaymentMode paymentMode) internal returns (uint gasUsedByValidateUserOp, uint prefund) {
    unchecked {
        uint preGas = gasleft();
        _createSenderIfNeeded(op);
        uint missingWalletFunds = 0;
        address sender = op.getSender();
        if (paymentMode != PaymentMode.paymasterStake) {
            uint bal = balanceOf(sender);
            missingWalletFunds = bal > requiredPrefund ? 0 : requiredPrefund - bal;
        }
        try IWallet(sender).validateUserOp{gas : op.verificationGas}(op, requestId, missingWalletFunds) {
        } catch Error(string memory revertReason) {
            revert FailedOp(opIndex, address(0), revertReason);
        } catch {
            revert FailedOp(opIndex, address(0), "");
        }
        if (paymentMode != PaymentMode.paymasterStake) {
            if (requiredPrefund > balanceOf(sender)) {
                revert FailedOp(opIndex, address(0), "wallet didn't pay prefund");
            }
            internalDecrementDeposit(sender, requiredPrefund);
            prefund = requiredPrefund;
        } else {
            prefund = 0;
        }
        gasUsedByValidateUserOp = preGas - gasleft();
    }
    }

    //validate paymaster.validatePaymasterUserOp
    function _validatePaymasterPrepayment(uint opIndex, UserOperation calldata op, bytes32 requestId, uint requiredPreFund, uint gasUsedByValidateUserOp) internal view returns (bytes memory context) {
    unchecked {
        //validate a paymaster has enough stake (including for payment for this TX)
        // NOTE: when submitting a batch, caller has to make sure a paymaster has enough stake to cover
        // all its transactions in the batch.
        if (!isPaymasterStaked(op.paymaster, paymasterStake + requiredPreFund)) {
            revert FailedOp(opIndex, op.paymaster, "not enough stake");
        }
        //no pre-pay from paymaster
        uint gas = op.verificationGas - gasUsedByValidateUserOp;
        try IPaymaster(op.paymaster).validatePaymasterUserOp{gas : gas}(op, requestId, requiredPreFund) returns (bytes memory _context){
            context = _context;
        } catch Error(string memory revertReason) {
            revert FailedOp(opIndex, op.paymaster, revertReason);
        } catch {
            revert FailedOp(opIndex, op.paymaster, "");
        }
    }
    }

    function _validatePrepayment(uint opIndex, UserOperation calldata userOp, bytes32 requestId) private returns (uint prefund, PaymentMode paymentMode, bytes memory context){

        uint preGas = gasleft();
        uint maxGasValues = userOp.preVerificationGas | userOp.verificationGas |
        userOp.callGas | userOp.maxFeePerGas | userOp.maxPriorityFeePerGas;
        require(maxGasValues < type(uint120).max, "gas values overflow");
        uint gasUsedByValidateUserOp;
        uint requiredPreFund;
        (requiredPreFund, paymentMode) = _getPaymentInfo(userOp);

        (gasUsedByValidateUserOp, prefund) = _validateWalletPrepayment(opIndex, userOp, requestId, requiredPreFund, paymentMode);

        //a "marker" where wallet opcode validation is done, by paymaster opcode validation is about to start
        // (used only by off-chain simulateValidation)
        uint marker = block.number;
        (marker);

        if (paymentMode == PaymentMode.paymasterStake) {
            (context) = _validatePaymasterPrepayment(opIndex, userOp, requestId, requiredPreFund, gasUsedByValidateUserOp);
        } else {
            context = "";
        }
    unchecked {
        uint gasUsed = preGas - gasleft();

        if (userOp.verificationGas < gasUsed) {
            revert FailedOp(opIndex, userOp.paymaster, "Used more than verificationGas");
        }
    }
    }

    function handlePostOp(uint opIndex, IPaymaster.PostOpMode mode, UserOperation calldata op, UserOpInfo memory opInfo, bytes memory context, uint actualGas) private returns (uint actualGasCost) {
        uint preGas = gasleft();
        uint gasPrice = UserOperationLib.gasPrice(op);
    unchecked {
        actualGasCost = actualGas * gasPrice;
        if (opInfo.paymentMode != PaymentMode.paymasterStake) {
            if (opInfo.prefund < actualGasCost) {
                revert ("wallet prefund below actualGasCost");
            }
            uint refund = opInfo.prefund - actualGasCost;
            internalIncrementDeposit(op.getSender(), refund);
        } else {
            if (context.length > 0) {
                if (mode != IPaymaster.PostOpMode.postOpReverted) {
                    IPaymaster(op.paymaster).postOp{gas : op.verificationGas}(mode, context, actualGasCost);
                } else {
                    try IPaymaster(op.paymaster).postOp{gas : op.verificationGas}(mode, context, actualGasCost) {}
                    catch Error(string memory reason) {
                        revert FailedOp(opIndex, op.paymaster, reason);
                    }
                    catch {
                        revert FailedOp(opIndex, op.paymaster, "postOp revert");
                    }
                }
            }
            //paymaster pays for full gas, including for postOp
            actualGas += preGas - gasleft();
            actualGasCost = actualGas * gasPrice;
            //paymaster balance known to be high enough, and to be locked for this block
            internalDecrementDeposit(op.paymaster, actualGasCost);
        }
        bool success = mode == IPaymaster.PostOpMode.opSucceeded;
        emit UserOperationEvent(opInfo.requestId, op.getSender(), op.paymaster, op.nonce, actualGasCost, gasPrice, success);
    } // unchecked
    }


    function isPaymasterStaked(address paymaster, uint stake) public view returns (bool) {
        return isStaked(paymaster, stake, unstakeDelaySec);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

    struct UserOperation {

        address sender;
        uint256 nonce;
        bytes initCode;
        bytes callData;
        uint callGas;
        uint verificationGas;
        uint preVerificationGas;
        uint maxFeePerGas;
        uint maxPriorityFeePerGas;
        address paymaster;
        bytes paymasterData;
        bytes signature;
    }

library UserOperationLib {

    function getSender(UserOperation calldata userOp) internal pure returns (address ret) {
        assembly {ret := calldataload(userOp)}
    }

    //relayer/miner might submit the TX with higher priorityFee, but the user should not
    // pay above what he signed for.
    function gasPrice(UserOperation calldata userOp) internal view returns (uint) {
    unchecked {
        uint maxFeePerGas = userOp.maxFeePerGas;
        uint maxPriorityFeePerGas = userOp.maxPriorityFeePerGas;
        if (maxFeePerGas == maxPriorityFeePerGas) {
            //legacy mode (for networks that don't support basefee opcode)
            return min(tx.gasprice, maxFeePerGas);
        }
        return min(tx.gasprice, min(maxFeePerGas, maxPriorityFeePerGas + block.basefee));
    }
    }

    function requiredGas(UserOperation calldata userOp) internal pure returns (uint) {
    unchecked {
        //when using a Paymaster, the verificationGas is used also to cover the postOp call.
        // our security model might call postOp eventually twice
        uint mul = userOp.paymaster != address(0) ? 1 : 3;
        return userOp.callGas + userOp.verificationGas * mul + userOp.preVerificationGas;
    }
    }

    function requiredPreFund(UserOperation calldata userOp) internal view returns (uint prefund) {
    unchecked {
        return requiredGas(userOp) * gasPrice(userOp);
    }
    }

    function hasPaymaster(UserOperation calldata userOp) internal pure returns (bool) {
        return userOp.paymaster != address(0);
    }

    function pack(UserOperation calldata userOp) internal pure returns (bytes memory ret) {
        //lighter signature scheme. must match UserOp.ts#packUserOp
        bytes calldata sig = userOp.signature;
        assembly {
            let ofs := userOp
            let len := sub(sub(sig.offset, ofs), 32)
            ret := mload(0x40)
            mstore(0x40, add(ret, add(len, 32)))
            mstore(ret, len)
            calldatacopy(add(ret, 32), ofs, len)
        }
        return ret;
    }

    function hash(UserOperation calldata userOp) internal pure returns (bytes32) {
        return keccak256(pack(userOp));
    }

    function min(uint a, uint b) internal pure returns (uint) {
        return a < b ? a : b;
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8;

/**
 * manage deposit of sender or paymaster, to pay for gas.
 * paymaster must stake some of the deposit.
 */
contract StakeManager {

    /// minimum number of blocks to after 'unlock' before amount can be withdrawn.
    uint32 immutable public unstakeDelaySec;

    constructor(uint32 _unstakeDelaySec) {
        unstakeDelaySec = _unstakeDelaySec;
    }

    event Deposited(
        address indexed account,
        uint256 totalDeposit,
        uint256 unstakeDelaySec
    );


    /// Emitted once a stake is scheduled for withdrawal
    event DepositUnstaked(
        address indexed account,
        uint256 withdrawTime
    );

    event Withdrawn(
        address indexed account,
        address withdrawAddress,
        uint256 withdrawAmount
    );

    /// @param amount of ether deposited for this account
    /// @param unstakeDelaySec - time the deposit is locked, after calling unlock (or zero if deposit is not locked)
    /// @param withdrawTime - first block timestamp where 'withdrawTo' will be callable, or zero if not locked
    struct DepositInfo {
        uint112 amount;
        uint32 unstakeDelaySec;
        uint64 withdrawTime;
    }

    /// maps accounts to their deposits
    mapping(address => DepositInfo) public deposits;

    function getDepositInfo(address account) external view returns (DepositInfo memory info) {
        return deposits[account];
    }

    function balanceOf(address account) public view returns (uint) {
        return deposits[account].amount;
    }

    receive() external payable {
        depositTo(msg.sender);
    }

    function internalIncrementDeposit(address account, uint amount) internal {
        deposits[account].amount += uint112(amount);
    }

    function internalDecrementDeposit(address account, uint amount) internal {
        deposits[account].amount -= uint112(amount);
    }

    /**
     * add to the deposit of the given account
     */
    function depositTo(address account) public payable {
        internalIncrementDeposit(account, msg.value);
        DepositInfo storage info = deposits[account];
        emit Deposited(msg.sender, info.amount, info.unstakeDelaySec);
    }

    /**
     * stake the account's deposit.
     * any pending unstakeDeposit is first cancelled.
     * can also set (or increase) the deposit with call.
     * @param _unstakeDelaySec the new lock time before the deposit can be withdrawn.
     */
    function addStakeTo(address account, uint32 _unstakeDelaySec) public payable {
        DepositInfo storage info = deposits[account];
        require(_unstakeDelaySec >= info.unstakeDelaySec, "cannot decrease unstake time");
        uint112 amount = deposits[msg.sender].amount + uint112(msg.value);
        deposits[account] = DepositInfo(
            amount,
            _unstakeDelaySec,
            0);
        emit Deposited(account, amount, _unstakeDelaySec);
    }

    /**
     * attempt to unstake the deposit.
     * the value can be withdrawn (using withdrawTo) after the unstake delay.
     */
    function unstakeDeposit() external {
        DepositInfo storage info = deposits[msg.sender];
        require(info.withdrawTime == 0, "already unstaking");
        require(info.unstakeDelaySec != 0, "not staked");
        uint64 withdrawTime = uint64(block.timestamp) + info.unstakeDelaySec;
        info.withdrawTime = withdrawTime;
        emit DepositUnstaked(msg.sender, withdrawTime);
    }

    /**
     * withdraw from the deposit.
     * will fail if the deposit is already staked or too low.
     * after a paymaster unlocks and withdraws some of the value, it must call addStake() to stake the value again.
     * @param withdrawAddress the address to send withdrawn value.
     * @param withdrawAmount the amount to withdraw.
     */
    function withdrawTo(address payable withdrawAddress, uint withdrawAmount) external {
        DepositInfo memory info = deposits[msg.sender];
        if (info.unstakeDelaySec != 0) {
            require(info.withdrawTime > 0, "must call unstakeDeposit() first");
            require(info.withdrawTime <= block.timestamp, "Withdrawal is not due");
        }
        require(withdrawAmount <= info.amount, "Withdraw amount too large");

        // store the remaining value, with stake info cleared.
        deposits[msg.sender] = DepositInfo(
            info.amount - uint112(withdrawAmount),
            0,
            0);
        withdrawAddress.transfer(withdrawAmount);
        emit Withdrawn(msg.sender, withdrawAddress, withdrawAmount);
    }

    /**
     * check if the given account is staked and didn't unlock it yet.
     * @param account the account (paymaster) to check
     * @param requiredStake the minimum deposit
     * @param requiredDelaySec the minimum required stake time.
     */
    function isStaked(address account, uint requiredStake, uint requiredDelaySec) public view returns (bool) {
        DepositInfo memory info = deposits[account];
        return info.amount >= requiredStake &&
        info.unstakeDelaySec >= requiredDelaySec &&
        info.withdrawTime == 0;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

import "./UserOperation.sol";

/**
 * the interface exposed by a paymaster contract, who agrees to pay the gas for user's operations.
 * a paymaster must hold a stake to cover the required entrypoint stake and also the gas for the transaction.
 */
interface IPaymaster {

    /**
     * payment validation: check if paymaster agree to pay (using its stake)
     * revert to reject this request.
     * actual payment is done after postOp is called, by deducting actual call cost form the paymaster's stake.
     * @param userOp the user operation
     * @param requestId hash of the user's request data.
     * @param maxCost the maximum cost of this transaction (based on maximum gas and gas price from userOp)
     * @return context value to send to a postOp
     *  zero length to signify postOp is not required.
     */
    function validatePaymasterUserOp(UserOperation calldata userOp, bytes32 requestId, uint maxCost) external view returns (bytes memory context);

    /**
     * post-operation handler.
     * Must verify sender is the entryPoint
     * @param mode enum with the following options:
     *      opSucceeded - user operation succeeded.
     *      opReverted  - user op reverted. still has to pay for gas.
     *      postOpReverted - user op succeeded, but caused postOp (in mode=opSucceeded) to revert.
     *                       Now this is the 2nd call, after user's op was deliberately reverted.
     * @param context - the context value returned by validatePaymasterUserOp
     * @param actualGasCost - actual gas used so far (without this postOp call).
     */
    function postOp(PostOpMode mode, bytes calldata context, uint actualGasCost) external;

    enum PostOpMode {
        opSucceeded, // user op succeeded
        opReverted, // user op reverted. still has to pay for gas.
        postOpReverted //user op succeeded, but caused postOp to revert. Now its a 2nd call, after user's op was deliberately reverted.
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
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
     * @dev Returns the square root of a number. It the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`.
        // We also know that `k`, the position of the most significant bit, is such that `msb(a) = 2**k`.
        // This gives `2**k < a <= 2**(k+1)` → `2**(k/2) <= sqrt(a) < 2 ** (k/2+1)`.
        // Using an algorithm similar to the msb conmputation, we are able to compute `result = 2**(k/2)` which is a
        // good first aproximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1;
        uint256 x = a;
        if (x >> 128 > 0) {
            x >>= 128;
            result <<= 64;
        }
        if (x >> 64 > 0) {
            x >>= 64;
            result <<= 32;
        }
        if (x >> 32 > 0) {
            x >>= 32;
            result <<= 16;
        }
        if (x >> 16 > 0) {
            x >>= 16;
            result <<= 8;
        }
        if (x >> 8 > 0) {
            x >>= 8;
            result <<= 4;
        }
        if (x >> 4 > 0) {
            x >>= 4;
            result <<= 2;
        }
        if (x >> 2 > 0) {
            result <<= 1;
        }

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
        uint256 result = sqrt(a);
        if (rounding == Rounding.Up && result * result < a) {
            result += 1;
        }
        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlEnumerable.sol";
import "./AccessControl.sol";
import "../utils/structs/EnumerableSet.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view virtual override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view virtual override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account) internal virtual override {
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.1) (utils/cryptography/SignatureChecker.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";
import "../Address.sol";
import "../../interfaces/IERC1271.sol";

/**
 * @dev Signature verification helper that can be used instead of `ECDSA.recover` to seamlessly support both ECDSA
 * signatures from externally owned accounts (EOAs) as well as ERC1271 signatures from smart contract wallets like
 * Argent and Gnosis Safe.
 *
 * _Available since v4.1._
 */
library SignatureChecker {
    /**
     * @dev Checks if a signature is valid for a given signer and data hash. If the signer is a smart contract, the
     * signature is validated against that smart contract using ERC1271, otherwise it's validated using `ECDSA.recover`.
     *
     * NOTE: Unlike ECDSA signatures, contract signatures are revocable, and the outcome of this function can thus
     * change through time. It could return true at block N and false at block N+1 (or the opposite).
     */
    function isValidSignatureNow(
        address signer,
        bytes32 hash,
        bytes memory signature
    ) internal view returns (bool) {
        (address recovered, ECDSA.RecoverError error) = ECDSA.tryRecover(hash, signature);
        if (error == ECDSA.RecoverError.NoError && recovered == signer) {
            return true;
        }

        (bool success, bytes memory result) = signer.staticcall(
            abi.encodeWithSelector(IERC1271.isValidSignature.selector, hash, signature)
        );
        return (success &&
            result.length == 32 &&
            abi.decode(result, (bytes32)) == bytes32(IERC1271.isValidSignature.selector));
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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
}