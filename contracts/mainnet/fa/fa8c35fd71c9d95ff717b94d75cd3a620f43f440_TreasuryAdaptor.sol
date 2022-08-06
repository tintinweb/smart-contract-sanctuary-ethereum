// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import "./ERC20.sol";
import "./CErc20.sol";
import "./Comptroller.sol";
import "openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";

contract TreasuryAdaptor {
    /** Custom errors **/

    error Unauthorized();
    error ReusedKnownNonce();
    error NotEnoughSigners();
    error NotActiveWithdrawalAddress();
    error NotActiveOperator();
    error DuplicateSigners();
    error SignatureExpired();
    error DuplicatedAddress();
    error Erc20TransferError();
    /// @dev RedeemError to indicate if CErc20(cUsdc).redeemUnderlying(amount) is
    /// successful, otherwise revert with the error code which is specified in ErrorReporter.sol of CErc20 repo
    /// (https://github.com/compound-finance/compound-protocol/blob/master/contracts/ErrorReporter.sol)
    error CErc20RedeemError(uint256 errorCode);
    /// @dev CErc20MintError to indicate if CErc20(cUsdc).mint(amount) is
    /// successful, otherwise revert with the error code which is specified in ErrorReporter.sol of CErc20 repo
    /// (https://github.com/compound-finance/compound-protocol/blob/master/contracts/ErrorReporter.sol)
    error CErc20MintError(uint256 errorCode);

    /** Custom events */
    event Pushed(uint256 amount);
    event AddedNewOperator(address indexed addr, uint256 timelock);
    event RemovedOperator(address indexed addr, uint256 timelock);
    event AddedNewWithdrawalAddress(address indexed addr, uint256 timelock);
    event RemovedWithdrawalAddress(address indexed addr, uint256 timelock);
    event WithdrewFundsTo(uint256 amount, address indexed dest);
    event WithdrewCompTo(uint256 amount, address indexed dest);

    /** Public constants **/

    /// @notice The address of the USDC contract
    address public immutable usdc;

    /// @notice The address of the cUSDC contract
    address public immutable cUsdc;

    /// @notice The address of the COMP contract
    address public immutable comp;

    /// @notice The address of the Comptroller contract
    address public immutable comptroller;

    /// @notice Operational user mapping
    /// Operational users can transfer back to the withdrawal address with a threshold of operatorThreshold
    mapping(address => uint256) public operators;

    /// @notice The Operator block list
    /// Will be unavailable delay after set by admin
    mapping(address => uint256) public operatorsBlocklist;

    /// @notice Admin for changing the operators in an emergency
    address public immutable admin;

    /// @notice The withdrawal address set by admin
    /// Circle Withdrawal wallet, with availability for further use during a migration
    /// Available delay after Admin listing
    mapping(address => uint256) public withdrawalAddresses;

    /// @notice The Withdrawal Address block list
    /// Unavailable delay after set by admin
    mapping(address => uint256) public withdrawalAddressesBlocklist;

    /// @notice The used nonces record mapping
    /// Just need to make sure the same nonce never get used twice
    mapping(bytes32 => uint256) public knownNonces;

    /// @notice Threshold for executing operator command of withdrawing to withdrawal address
    uint256 public immutable operatorThreshold;

    /// @notice inline delay
    uint256 public immutable delay;

    /// --- Below is parameters need to make signing process of this contract to compatible with EIP-712 ---
    /// @notice The name of this contract
    string public constant name = "Treasury Adaptor";

    /// @notice The major version of this contract
    string public constant version = "0";

    /** Internal constants **/

    /// @dev The EIP-712 typehash for the contract's domain
    bytes32 internal constant DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );

    /// @dev The EIP-712 typehash for operator authorization
    /// amount, destination address, and nonce
    bytes32 internal constant AUTHORIZATION_TYPEHASH =
        keccak256(
            "Authorization(uint256 amount,address destination,uint256 expiry,bytes32 nonce)"
        );

    /// @notice Construct of TreasusryAdaptor
    /// @param cUsdcAddr The address of cToken of USDC that's supported by compound protocol
    /// @param compAddr The address of COMP token
    /// @param adminMultisig The address of the admin multi sig wallet
    /// @param initialOperators list of initial operator addresses
    /// @param initialWithdrawalAddresses list of initial withdrawal addresses
    /// @param opThreshold number of operators required to trigger withdraw actions
    /// @param delayTime time delay required for admin changes
    constructor(
        address cUsdcAddr,
        address compAddr,
        address adminMultisig,
        address[] memory initialOperators,
        address[] memory initialWithdrawalAddresses,
        uint256 opThreshold,
        uint256 delayTime
    ) {
        admin = adminMultisig;
        cUsdc = cUsdcAddr;
        comptroller = address(CErc20(cUsdc).comptroller());
        comp = compAddr;
        usdc = CErc20(cUsdc).underlying();
        ERC20(usdc).approve(cUsdc, type(uint256).max);
        operatorThreshold = opThreshold;
        delay = delayTime;

        // Add initial operators and withdrawal addresses
        for (uint256 i = 0; i < initialOperators.length; i++) {
            operators[initialOperators[i]] = block.timestamp;
            emit AddedNewOperator(initialOperators[i], block.timestamp);
        }
        for (uint256 i = 0; i < initialWithdrawalAddresses.length; i++) {
            withdrawalAddresses[initialWithdrawalAddresses[i]] = block
                .timestamp;
            emit AddedNewWithdrawalAddress(
                initialWithdrawalAddresses[i],
                block.timestamp
            );
        }
    }

    /// @notice Push fund that this contract holds to compound protocol
    /// Anyone can invoke this function, since it won't have risk to be called by other people
    function push() external {
        uint256 amount = ERC20(usdc).balanceOf(address(this));
        uint256 code = CErc20(cUsdc).mint(amount);
        if (code != 0) revert CErc20MintError(code);
        emit Pushed(amount);
    }

    /// @notice Add oeprator to the list by adding the address to operators list
    /// @param newOperator new operator address to add
    function addOperator(address newOperator) external {
        if (msg.sender != admin) revert Unauthorized();
        if (operators[newOperator] != 0) revert DuplicatedAddress();
        uint256 timestamp = block.timestamp + delay;
        operators[newOperator] = timestamp;
        emit AddedNewOperator(newOperator, timestamp);
    }

    /// @notice Remove operator from the list by adding the address to operatorsBlocklist
    /// @param oldOperator operator address to remove
    function removeOperator(address oldOperator) external {
        if (msg.sender != admin) revert Unauthorized();
        if (operatorsBlocklist[oldOperator] != 0) revert DuplicatedAddress();
        uint256 timestamp = operators[oldOperator] >= block.timestamp
            ? block.timestamp // Set timelock delay timestamp to now, to block the pending active address right away
            : block.timestamp + delay;
        operatorsBlocklist[oldOperator] = timestamp;
        emit RemovedOperator(oldOperator, timestamp);
    }

    /// @notice Withdraw fund from compound protocol
    /// Required at least <operatorThreshold> operators signatures to proceed
    /// Withdrawal fund will be sent to destination address
    /// Destination address has to been added and active in withdrawalAddresses list
    /// @param amount amount of fund to withdraw
    /// @param destination destination address to withdraw to, the address has to be added to withdrawal address list
    /// @param signatures signatures that operator signed with their key
    /// @param expiry expiration of the signature
    /// @param nonce nonce of the signature, to prevent replay attack
    function withdraw(
        uint256 amount,
        address destination,
        uint256 expiry,
        bytes32 nonce,
        bytes[] memory signatures
    ) external {
        if (knownNonces[nonce] != 0) revert ReusedKnownNonce();
        if (block.timestamp >= expiry) revert SignatureExpired();
        if (signatures.length < operatorThreshold) revert NotEnoughSigners();
        if (
            !isActive(
                withdrawalAddresses[destination],
                withdrawalAddressesBlocklist[destination]
            )
        ) revert NotActiveWithdrawalAddress();
        bytes32 digest = createDigestMessage(
            amount,
            destination,
            expiry,
            nonce
        );
        // Verify address are unique
        // Address recovered from signatures must be strictly increasing, in order to prevent duplicates
        address lastSignerAddr = address(0); // cannot have address(0) as an ownerx
        for (uint256 i = 0; i < signatures.length; i++) {
            address recoveredSigner = ECDSA.recover(digest, signatures[i]);
            if (recoveredSigner <= lastSignerAddr) revert DuplicateSigners();
            if (
                !isActive(
                    operators[recoveredSigner],
                    operatorsBlocklist[recoveredSigner]
                )
            ) revert NotActiveOperator();
            lastSignerAddr = recoveredSigner;
        }
        // Mark nonce with block.timestamp
        knownNonces[nonce] = block.timestamp;
        uint256 code = CErc20(cUsdc).redeemUnderlying(amount);
        if (code != 0) revert CErc20RedeemError(code);
        bool success = ERC20(usdc).transfer(destination, amount);
        if (!success) revert Erc20TransferError();
        emit WithdrewFundsTo(amount, destination);
    }

    /// @notice Generage digest message with EIP-712 typehash info
    /// @param amount the amount to withdraw
    /// @param destination withdrawal address
    /// @param expiry expiration of the signature
    /// @param nonce current nonce of the contract
    /// @return message to sign later on
    function createDigestMessage(
        uint256 amount,
        address destination,
        uint256 expiry,
        bytes32 nonce
    ) public view returns (bytes32) {
        bytes32 domainSeparator = keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes(name)),
                keccak256(bytes(version)),
                block.chainid,
                address(this)
            )
        );
        bytes32 structHash = keccak256(
            abi.encode(
                AUTHORIZATION_TYPEHASH,
                amount,
                destination,
                expiry,
                nonce
            )
        );
        return
            keccak256(
                abi.encodePacked("\x19\x01", domainSeparator, structHash)
            );
    }

    /// @notice Withdraw comp to admin wallet
    /// There is no risk for anyone calling it, since it only withdraw comp to admin's wallet
    /// So it won't check on the authorization on the caller
    function withdrawComp() external {
        Comptroller(comptroller).claimComp(address(this));
        uint256 amount = ERC20(comp).balanceOf(address(this));
        bool success = ERC20(comp).transfer(admin, amount);
        if (!success) revert Erc20TransferError();
        emit WithdrewCompTo(amount, admin);
    }

    /// @notice Add withdrawal address to allow list with delay activation timestamp
    /// The address will only be usable after the specified delay elapsed
    /// Only admin can proceed this action
    /// @param recipient the address to add
    function addWithdrawalAddress(address recipient) external {
        if (msg.sender != admin) revert Unauthorized();
        if (withdrawalAddresses[recipient] != 0) revert DuplicatedAddress();
        uint256 timestamp = block.timestamp + delay;
        withdrawalAddresses[recipient] = timestamp;
        emit AddedNewWithdrawalAddress(recipient, timestamp);
    }

    /// @dev Remove withdrawal address via adding it to block list with delay activation timestamp
    /// The address will only be blocked after the specified delay elapsed
    /// Only admin can proceed this action
    /// @param recipient address to remove from the list
    function removeWithdrawalAddress(address recipient) external {
        if (msg.sender != admin) revert Unauthorized();
        if (withdrawalAddressesBlocklist[recipient] != 0)
            revert DuplicatedAddress();
        uint256 timestamp = withdrawalAddresses[recipient] >= block.timestamp
            ? block.timestamp // Set timelock delay timestamp to now, to block the pending active address right away
            : block.timestamp + delay;
        withdrawalAddressesBlocklist[recipient] = timestamp;
        emit RemovedWithdrawalAddress(recipient, timestamp);
    }

    /// @dev Check if the target address is active or not by comparing the timestamp in allow list and block list
    /// Active means when the address has been added to the allow list and has not been blocked yet
    /// @param allowlistTimestamp timestamp in allow list
    /// @param blocklistTimestamp timestamp in block list
    /// @return boolean to indicate if the address is active (completedTimelock(allow_list) && !completedTimelock(block_list))
    function isActive(uint256 allowlistTimestamp, uint256 blocklistTimestamp)
        public
        view
        returns (bool)
    {
        return
            completedTimelock(allowlistTimestamp) &&
            !completedTimelock(blocklistTimestamp);
    }

    /// @dev Helper function to check if the current timestamp has pass the specified timestamp or not
    /// @param timestamp timestamp to check if it has passed the block.timestamp or not
    /// @return bool to show if timestamp has passed the block.timestamp
    function completedTimelock(uint256 timestamp) private view returns (bool) {
        return timestamp != 0 && timestamp < block.timestamp;
    }

    /// @dev Helper function to check if address is operator or not
    /// @param addr address to check
    /// @return bool to indicate if the address is active oeprator or not
    function isOperator(address addr) external view returns (bool) {
        return isActive(operators[addr], operatorsBlocklist[addr]);
    }

    /// @dev Helper function to check if addres is withdrawal address
    /// @param addr address to check
    /// @return bool to indicate if the address is active withdrawal address or not
    function isWithdrawalAddress(address addr) external view returns (bool) {
        return
            isActive(
                withdrawalAddresses[addr],
                withdrawalAddressesBlocklist[addr]
            );
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.15;

/**
 * @title ERC 20 Token Standard Interface
 *  https://eips.ethereum.org/EIPS/eip-20
 */
interface ERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    /**
     * @notice Get the total number of tokens in circulation
     * @return The supply of tokens
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Gets the balance of the specified address
     * @param owner The address from which the balance will be retrieved
     * @return The balance
     */
    function balanceOf(address owner) external view returns (uint256);

    /**
     * @notice Transfer `amount` tokens from `msg.sender` to `dst`
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transfer(address dst, uint256 amount) external returns (bool);

    /**
     * @notice Transfer `amount` tokens from `src` to `dst`
     * @param src The address of the source account
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transferFrom(
        address src,
        address dst,
        uint256 amount
    ) external returns (bool);

    /**
     * @notice Approve `spender` to transfer up to `amount` from `src`
     * @dev This will overwrite the approval amount for `spender`
     *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
     * @param spender The address of the account which may transfer tokens
     * @param amount The number of tokens that are approved (-1 means infinite)
     * @return Whether or not the approval succeeded
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @notice Get the current allowance from `owner` for `spender`
     * @param owner The address of the account which owns the tokens to be spent
     * @param spender The address of the account which may transfer tokens
     * @return The number of tokens allowed to be spent (-1 means infinite)
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.15;
import "./Comptroller.sol";

interface CErc20 {
    /*** User Interface ***/
    function comptroller() external returns (ComptrollerInterface);

    function underlying() external returns (address);

    function mint(uint256 mintAmount) external returns (uint256);

    function redeem(uint256 redeemTokens) external returns (uint256);

    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

    function balanceOf(address owner) external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.15;

interface Comptroller {
    function claimComp(address holder) external;
}

/// @dev Empty interface for retrieving comptroller address of CErc20
/// since we won't invoke any ComptrollerInterface functions but just
/// getting its address
abstract contract ComptrollerInterface {

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/ECDSA.sol)

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
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
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
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
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