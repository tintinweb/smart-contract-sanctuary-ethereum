/**
 *Submitted for verification at Etherscan.io on 2022-09-18
*/

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = '0123456789abcdef';

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return '0';
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
            return '0x00';
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
        buffer[0] = '0';
        buffer[1] = 'x';
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, 'Strings: hex length insufficient');
        return string(buffer);
    }
}
// File: ECDSA.sol

// OpenZeppelin Contracts v4.4.1 (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

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
            revert('ECDSA: invalid signature');
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert('ECDSA: invalid signature length');
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
                abi.encodePacked('\x19Ethereum Signed Message:\n32', hash)
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
                    '\x19Ethereum Signed Message:\n',
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
                abi.encodePacked('\x19\x01', domainSeparator, structHash)
            );
    }
}
// File: Context.sol

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
// File: Ownable.sol

pragma solidity ^0.8.0;

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
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
        require(owner() == _msgSender(), 'Ownable: caller is not the owner');
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            'Ownable: new owner is the zero address'
        );
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
// File: Address.sol

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
        require(
            address(this).balance >= amount,
            'Address: insufficient balance'
        );

        (bool success, ) = recipient.call{value: amount}('');
        require(
            success,
            'Address: unable to send value, recipient may have reverted'
        );
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, 'Address: low-level call failed');
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                'Address: low-level call with value failed'
            );
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
        require(
            address(this).balance >= value,
            'Address: insufficient balance for call'
        );
        require(isContract(target), 'Address: call to non-contract');

        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                'Address: low-level static call failed'
            );
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
        require(isContract(target), 'Address: static call to non-contract');

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                'Address: low-level delegate call failed'
            );
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
        require(isContract(target), 'Address: delegate call to non-contract');

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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
// File: Payment.sol

// OpenZeppelin Contracts v4.4.1 (finance/PaymentSplitter.sol)

pragma solidity ^0.8.0;

/**
 * @title PaymentSplitter
 * @dev This contract allows to split Ether payments among a group of accounts. The sender does not need to be aware
 * that the Ether will be split in this way, since it is handled transparently by the contract.
 *
 * The split can be in equal parts or in any other arbitrary proportion. The way this is specified is by assigning each
 * account to a number of shares. Of all the Ether that this contract receives, each account will then be able to claim
 * an amount proportional to the percentage of total shares they were assigned.
 *
 * `PaymentSplitter` follows a _pull payment_ model. This means that payments are not automatically forwarded to the
 * accounts but kept in this contract, and the actual transfer is triggered as a separate step by calling the {release}
 * function.
 *
 * NOTE: This contract assumes that ERC20 tokens will behave similarly to native tokens (Ether). Rebasing tokens, and
 * tokens that apply fees during transfers, are likely to not be supported as expected. If in doubt, we encourage you
 * to run tests before sending real value to this contract.
 */
contract Payment is Context {
    event PayeeAdded(address account, uint256 shares);
    event PaymentReleased(address to, uint256 amount);
    event PaymentReceived(address from, uint256 amount);

    uint256 private _totalShares;
    uint256 private _totalReleased;

    mapping(address => uint256) private _shares;
    mapping(address => uint256) private _released;
    address[] private _payees;

    /**
     * @dev Creates an instance of `PaymentSplitter` where each account in `payees` is assigned the number of shares at
     * the matching position in the `shares` array.
     *
     * All addresses in `payees` must be non-zero. Both arrays must have the same non-zero length, and there must be no
     * duplicates in `payees`.
     */
    constructor(address[] memory payees, uint256[] memory shares_) payable {
        require(
            payees.length == shares_.length,
            'PaymentSplitter: payees and shares length mismatch'
        );
        require(payees.length > 0, 'PaymentSplitter: no payees');

        for (uint256 i = 0; i < payees.length; i++) {
            _addPayee(payees[i], shares_[i]);
        }
    }

    /**
     * @dev The Ether received will be logged with {PaymentReceived} events. Note that these events are not fully
     * reliable: it's possible for a contract to receive Ether without triggering this function. This only affects the
     * reliability of the events, and not the actual splitting of Ether.
     *
     * To learn more about this see the Solidity documentation for
     * https://solidity.readthedocs.io/en/latest/contracts.html#fallback-function[fallback
     * functions].
     */
    receive() external payable virtual {
        emit PaymentReceived(_msgSender(), msg.value);
    }

    /**
     * @dev Getter for the total shares held by payees.
     */
    function totalShares() public view returns (uint256) {
        return _totalShares;
    }

    /**
     * @dev Getter for the total amount of Ether already released.
     */
    function totalReleased() public view returns (uint256) {
        return _totalReleased;
    }

    /**
     * @dev Getter for the amount of shares held by an account.
     */
    function shares(address account) public view returns (uint256) {
        return _shares[account];
    }

    /**
     * @dev Getter for the amount of Ether already released to a payee.
     */
    function released(address account) public view returns (uint256) {
        return _released[account];
    }

    /**
     * @dev Getter for the address of the payee number `index`.
     */
    function payee(uint256 index) public view returns (address) {
        return _payees[index];
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of Ether they are owed, according to their percentage of the
     * total shares and their previous withdrawals.
     */
    function release(address payable account) public virtual {
        require(_shares[account] > 0, 'PaymentSplitter: account has no shares');

        uint256 totalReceived = address(this).balance + totalReleased();
        uint256 payment = _pendingPayment(
            account,
            totalReceived,
            released(account)
        );

        require(payment != 0, 'PaymentSplitter: account is not due payment');

        _released[account] += payment;
        _totalReleased += payment;

        Address.sendValue(account, payment);
        emit PaymentReleased(account, payment);
    }

    /**
     * @dev internal logic for computing the pending payment of an `account` given the token historical balances and
     * already released amounts.
     */
    function _pendingPayment(
        address account,
        uint256 totalReceived,
        uint256 alreadyReleased
    ) private view returns (uint256) {
        return
            (totalReceived * _shares[account]) / _totalShares - alreadyReleased;
    }

    /**
     * @dev Add a new payee to the contract.
     * @param account The address of the payee to add.
     * @param shares_ The number of shares owned by the payee.
     */
    function _addPayee(address account, uint256 shares_) private {
        require(
            account != address(0),
            'PaymentSplitter: account is the zero address'
        );
        require(shares_ > 0, 'PaymentSplitter: shares are 0');
        require(
            _shares[account] == 0,
            'PaymentSplitter: account already has shares'
        );

        _payees.push(account);
        _shares[account] = shares_;
        _totalShares = _totalShares + shares_;
        emit PayeeAdded(account, shares_);
    }
}
// File: IERC721Receiver.sol

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}
// File: IERC165.sol

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
// File: ERC165.sol

pragma solidity ^0.8.0;

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
// File: IERC721.sol

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}
// File: IERC721Enumerable.sol

pragma solidity ^0.8.0;

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}
// File: IERC721Metadata.sol

pragma solidity ^0.8.0;

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}
// File: ERC721A.sol

pragma solidity ^0.8.0;

contract ERC721A is
    Context,
    ERC165,
    IERC721,
    IERC721Metadata,
    IERC721Enumerable
{
    using Address for address;
    using Strings for uint256;

    struct TokenOwnership {
        address addr;
        uint64 startTimestamp;
    }

    struct AddressData {
        uint128 balance;
        uint128 numberMinted;
    }

    uint256 internal currentIndex;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to ownership details
    // An empty struct value does not necessarily mean the token is unowned. See ownershipOf implementation for details.
    mapping(uint256 => TokenOwnership) internal _ownerships;

    // Mapping owner address to address data
    mapping(address => AddressData) private _addressData;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return currentIndex;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index)
        public
        view
        override
        returns (uint256)
    {
        require(index < totalSupply(), 'ERC721A: global index out of bounds');
        return index;
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     * This read function is O(totalSupply). If calling from a separate contract, be sure to test gas first.
     * It may also degrade with extremely large collection sizes (e.g >> 10000), test for your use case.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index)
        public
        view
        override
        returns (uint256)
    {
        require(index < balanceOf(owner), 'ERC721A: owner index out of bounds');
        uint256 numMintedSoFar = totalSupply();
        uint256 tokenIdsIdx;
        address currOwnershipAddr;

        // Counter overflow is impossible as the loop breaks when uint256 i is equal to another uint256 numMintedSoFar.
        unchecked {
            for (uint256 i; i < numMintedSoFar; i++) {
                TokenOwnership memory ownership = _ownerships[i];
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                if (currOwnershipAddr == owner) {
                    if (tokenIdsIdx == index) {
                        return i;
                    }
                    tokenIdsIdx++;
                }
            }
        }

        revert('ERC721A: unable to get token of owner by index');
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC721Enumerable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view override returns (uint256) {
        require(
            owner != address(0),
            'ERC721A: balance query for the zero address'
        );
        return uint256(_addressData[owner].balance);
    }

    function _numberMinted(address owner) internal view returns (uint256) {
        require(
            owner != address(0),
            'ERC721A: number minted query for the zero address'
        );
        return uint256(_addressData[owner].numberMinted);
    }

    /**
     * Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around in the collection over time.
     */
    function ownershipOf(uint256 tokenId)
        internal
        view
        returns (TokenOwnership memory)
    {
        require(_exists(tokenId), 'ERC721A: owner query for nonexistent token');

        unchecked {
            for (uint256 curr = tokenId; curr >= 0; curr--) {
                TokenOwnership memory ownership = _ownerships[curr];
                if (ownership.addr != address(0)) {
                    return ownership;
                }
            }
        }

        revert('ERC721A: unable to determine the owner of token');
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        return ownershipOf(tokenId).addr;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            'ERC721Metadata: URI query for nonexistent token'
        );

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length != 0
                ? string(abi.encodePacked(baseURI, tokenId.toString()))
                : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return '';
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public override {
        address owner = ERC721A.ownerOf(tokenId);
        require(to != owner, 'ERC721A: approval to current owner');

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            'ERC721A: approve caller is not owner nor approved for all'
        );

        _approve(to, tokenId, owner);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId)
        public
        view
        override
        returns (address)
    {
        require(
            _exists(tokenId),
            'ERC721A: approved query for nonexistent token'
        );

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved)
        public
        override
    {
        require(operator != _msgSender(), 'ERC721A: approve to caller');

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        safeTransferFrom(from, to, tokenId, '');
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public override {
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, _data),
            'ERC721A: transfer to non ERC721Receiver implementer'
        );
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return tokenId < currentIndex;
    }

    function _safeMint(address to, uint256 quantity) internal {
        _safeMint(to, quantity, '');
    }

    /**
     * @dev Safely mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called for each safe transfer.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal {
        _mint(to, quantity, _data, true);
    }

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event.
     */
    function _mint(
        address to,
        uint256 quantity,
        bytes memory _data,
        bool safe
    ) internal {
        uint256 startTokenId = currentIndex;
        require(to != address(0), 'ERC721A: mint to the zero address');
        require(quantity != 0, 'ERC721A: quantity must be greater than 0');

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // balance or numberMinted overflow if current value of either + quantity > 3.4e38 (2**128) - 1
        // updatedIndex overflows if currentIndex + quantity > 1.56e77 (2**256) - 1
        unchecked {
            _addressData[to].balance += uint128(quantity);
            _addressData[to].numberMinted += uint128(quantity);

            _ownerships[startTokenId].addr = to;
            _ownerships[startTokenId].startTimestamp = uint64(block.timestamp);

            uint256 updatedIndex = startTokenId;

            for (uint256 i; i < quantity; i++) {
                emit Transfer(address(0), to, updatedIndex);
                if (safe) {
                    require(
                        _checkOnERC721Received(
                            address(0),
                            to,
                            updatedIndex,
                            _data
                        ),
                        'ERC721A: transfer to non ERC721Receiver implementer'
                    );
                }

                updatedIndex++;
            }

            currentIndex = updatedIndex;
        }

        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     * This is an internal function that does not check if the sender is authorized to operate on the token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721A.ownerOf(tokenId);

        _beforeTokenTransfers(owner, address(0), tokenId,1);

        // Update ownership in case tokenId was transferred by `_beforeTokenTransfers` hook
        owner = ERC721A.ownerOf(tokenId);

        // Clear approvals
        delete _tokenApprovals[tokenId];

        unchecked {
            // Cannot overflow, as that would require more tokens to be burned/transferred
            // out than the owner initially received through minting and transferring in.
            _addressData[owner].balance -= 1;
            _ownerships[tokenId].addr = address(0);
        }

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfers(owner, address(0), tokenId,1);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) private {
        TokenOwnership memory prevOwnership = ownershipOf(tokenId);

        bool isApprovedOrOwner = (_msgSender() == prevOwnership.addr ||
            getApproved(tokenId) == _msgSender() ||
            isApprovedForAll(prevOwnership.addr, _msgSender()));

        require(
            isApprovedOrOwner,
            'ERC721A: transfer caller is not owner nor approved'
        );

        require(
            prevOwnership.addr == from,
            'ERC721A: transfer from incorrect owner'
        );
        require(to != address(0), 'ERC721A: transfer to the zero address');

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, prevOwnership.addr);

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            _addressData[from].balance -= 1;
            _addressData[to].balance += 1;

            _ownerships[tokenId].addr = to;
            _ownerships[tokenId].startTimestamp = uint64(block.timestamp);

            // If the ownership slot of tokenId+1 is not explicitly set, that means the transfer initiator owns it.
            // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
            uint256 nextTokenId = tokenId + 1;
            if (_ownerships[nextTokenId].addr == address(0)) {
                if (_exists(nextTokenId)) {
                    _ownerships[nextTokenId].addr = prevOwnership.addr;
                    _ownerships[nextTokenId].startTimestamp = prevOwnership
                        .startTimestamp;
                }
            }
        }

        emit Transfer(from, to, tokenId);
        _afterTokenTransfers(from, to, tokenId, 1);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(
        address to,
        uint256 tokenId,
        address owner
    ) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try
                IERC721Receiver(to).onERC721Received(
                    _msgSender(),
                    from,
                    tokenId,
                    _data
                )
            returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert(
                        'ERC721A: transfer to non ERC721Receiver implementer'
                    );
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before a set of serially-ordered token ids are about to be transferred. This includes minting.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Hook that is called after a set of serially-ordered token ids have been transferred. This includes
     * minting.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     */
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}
}

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
        require(_status != _ENTERED, 'ReentrancyGuard: reentrant call');

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

pragma solidity ^0.8.0;

/**********************************************************\
* Author: alxi <[email protected]> (https://twitter.com/0xalxi)
* EIP-5050 Token Interaction Standard: [tbd]
*
* Implementation of an interactive token protocol.
/**********************************************************/

/// @title ERC-5050 Token Interaction Standard
/// @dev See https://eips.ethereum.org/EIPS/eip-xxx
interface IERC5050Sender {
    /// @notice Send an action to the target address
    /// @dev The action's `fromContract` is automatically set to `address(this)`,
    /// and the `from` parameter is set to `msg.sender`.
    /// @param action The action to send
    function sendAction(Action memory action) external payable;

    /// @notice Check if an action is valid based on its hash and nonce
    /// @dev When an action passes through all three possible contracts
    /// (`fromContract`, `to`, and `state`) the `state` contract validates the
    /// action with the initating `fromContract` using a nonced action hash.
    /// This hash is calculated and saved to storage on the `fromContract` before
    /// action handling is initiated. The `state` contract calculates the hash
    /// and verifies it and nonce with the `fromContract`.
    /// @param _hash The hash to validate
    /// @param _nonce The nonce to validate
    function isValid(bytes32 _hash, uint256 _nonce) external returns (bool);

    /// @notice Retrieve list of actions that can be sent.
    /// @dev Intended for use by off-chain applications to query compatible contracts,
    /// and to advertise functionality in human-readable form.
    function sendableActions() external view returns (string[] memory);

    /// @notice Change or reaffirm the approved address for an action
    /// @dev The zero address indicates there is no approved address.
    ///  Throws unless `msg.sender` is the `_account`, or an authorized
    ///  operator of the `_account`.
    /// @param _account The account of the account-action pair to approve
    /// @param _action The action of the account-action pair to approve
    /// @param _approved The new approved account-action controller
    function approveForAction(
        address _account,
        bytes4 _action,
        address _approved
    ) external returns (bool);

    /// @notice Enable or disable approval for a third party ("operator") to conduct
    ///  all actions on behalf of `msg.sender`
    /// @dev Emits the ApprovalForAll event. The contract MUST allow
    ///  an unbounded number of operators per owner.
    /// @param _operator Address to add to the set of authorized operators
    /// @param _approved True if the operator is approved, false to revoke approval
    function setApprovalForAllActions(address _operator, bool _approved)
        external;

    /// @notice Get the approved address for an account-action pair
    /// @dev Throws if `_tokenId` is not a valid NFT.
    /// @param _account The account of the account-action to find the approved address for
    /// @param _action The action of the account-action to find the approved address for
    /// @return The approved address for this account-action, or the zero address if
    ///  there is none
    function getApprovedForAction(address _account, bytes4 _action)
        external
        view
        returns (address);

    /// @notice Query if an address is an authorized operator for another address
    /// @param _account The address on whose behalf actions are performed
    /// @param _operator The address that acts on behalf of the account
    /// @return True if `_operator` is an approved operator for `_account`, false otherwise
    function isApprovedForAllActions(address _account, address _operator)
        external
        view
        returns (bool);

    /// @dev This emits when an action is sent (`sendAction()`)
    event SendAction(
        bytes4 indexed name,
        address _from,
        address indexed _fromContract,
        uint256 _tokenId,
        address indexed _to,
        uint256 _toTokenId,
        address _state,
        bytes _data
    );

    /// @dev This emits when the approved address for an account-action pair
    ///  is changed or reaffirmed. The zero address indicates there is no
    ///  approved address.
    event ApprovalForAction(
        address indexed _account,
        bytes4 indexed _action,
        address indexed _approved
    );

    /// @dev This emits when an operator is enabled or disabled for an account.
    ///  The operator can conduct all actions on behalf of the account.
    event ApprovalForAllActions(
        address indexed _account,
        address indexed _operator,
        bool _approved
    );
}

interface IERC5050Receiver {
    /// @notice Handle an action
    /// @dev Both the `to` contract and `state` contract are called via
    /// `onActionReceived()`.
    /// @param action The action to handle
    function onActionReceived(Action calldata action, uint256 _nonce)
        external
        payable;

    /// @notice Retrieve list of actions that can be received.
    /// @dev Intended for use by off-chain applications to query compatible contracts,
    /// and to advertise functionality in human-readable form.
    function receivableActions() external view returns (string[] memory);

    /// @dev This emits when a valid action is received.
    event ActionReceived(
        bytes4 indexed name,
        address _from,
        address indexed _fromContract,
        uint256 _tokenId,
        address indexed _to,
        uint256 _toTokenId,
        address _state,
        bytes _data
    );
}

/// @param _address The address of the interactive object
/// @param tokenId The token that is interacting (optional)
struct Object {
    address _address;
    uint256 _tokenId;
}

/// @param selector The bytes4(keccack256()) encoding of the action string
/// @param user The address of the sender
/// @param from The initiating object
/// @param to The receiving object
/// @param state The state contract
/// @param data Additional data with no specified format
struct Action {
    bytes4 selector;
    address user;
    Object from;
    Object to;
    address state;
    bytes data;
}

// Barely modified version of OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

library ActionsSet {
    struct Set {
        // Storage of action names
        string[] _names;
        // Storage of action selectors
        bytes4[] _selectors;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes4 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Set storage set, string memory name) internal returns (bool) {
        bytes4 selector = bytes4(keccak256(bytes(name)));
        if (!contains(set, selector)) {
            set._selectors.push(selector);
            set._names.push(name);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[selector] = set._selectors.length;
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
    function remove(Set storage set, bytes4 value) internal returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _selectors array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._selectors.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes4 lastValue = set._selectors[lastIndex];

                // Move the last value to the index where the value to delete is
                set._selectors[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._selectors.pop();

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
    function contains(Set storage set, bytes4 value)
        internal
        view
        returns (bool)
    {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(Set storage set) internal view returns (uint256) {
        return set._selectors.length;
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
    function at(Set storage set, uint256 index) internal view returns (bytes4) {
        return set._selectors[index];
    }

    /**
     * @dev Return the entire set of action names
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function names(Set storage set) internal view returns (string[] memory) {
        return set._names;
    }

    /**
     * @dev Return the entire set of action selectors
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function selectors(Set storage set)
        internal
        view
        returns (bytes4[] memory)
    {
        return set._selectors;
    }
}

pragma solidity ^0.8.0;

/**********************************************************\
* Author: alxi <[email protected]> (https://twitter.com/0xalxi)
* EIP-5050 Token Interaction Standard: [tbd]
*
* Implementation of an interactive token protocol.
/**********************************************************/

interface IControllable {
    event ControllerApproval(
        address indexed _controller,
        bytes4 indexed _action
    );

    event ControllerApprovalForAll(address indexed _controller, bool _approved);

    function approveController(address _controller, bytes4 _action) external;

    function setControllerApprovalForAll(address _controller, bool _approved)
        external;

    function isApprovedController(address _controller, bytes4 _action)
        external
        view
        returns (bool);
}

pragma solidity ^0.8.0;

/**********************************************************\
* Author: alxi <[email protected]> (https://twitter.com/0xalxi)
* EIP-5050 Token Interaction Standard: [tbd]
*
* Implementation of an interactive token protocol.
/**********************************************************/

contract Controllable is IControllable {
    mapping(address => mapping(bytes4 => bool)) private _actionControllers;
    mapping(address => bool) private _universalControllers;

    function approveController(address _controller, bytes4 _action)
        external
        virtual
    {
        _actionControllers[_controller][_action] = true;
        emit ControllerApproval(_controller, _action);
    }

    function setControllerApprovalForAll(address _controller, bool _approved)
        external
        virtual
    {
        _universalControllers[_controller] = _approved;
        emit ControllerApprovalForAll(_controller, _approved);
    }

    function isApprovedController(address _controller, bytes4 _action)
        external
        view
        returns (bool)
    {
        return _isApprovedController(_controller, _action);
    }

    function _isApprovedController(address _controller, bytes4 _action)
        internal
        view
        returns (bool)
    {
        if (_universalControllers[_controller]) {
            return true;
        }
        return _actionControllers[_controller][_action];
    }
}

pragma solidity ^0.8.0;

/**********************************************************\
* Author: alxi <[email protected]> (https://twitter.com/0xalxi)
* EIP-5050 Token Interaction Standard: [tbd]
*
* Implementation of an interactive token protocol.
/**********************************************************/

contract ERC5050Sender is Controllable, IERC5050Sender {
    using Address for address;
    using ActionsSet for ActionsSet.Set;

    ActionsSet.Set _sendableActions;

    uint256 private _nonce;
    bytes32 private _hash;

    mapping(address => mapping(bytes4 => address)) actionApprovals;
    mapping(address => mapping(address => bool)) operatorApprovals;

    function sendAction(Action memory action)
        external
        payable
        virtual
        override
    {
        _sendAction(action);
    }

    function isValid(bytes32 actionHash, uint256 nonce)
        external
        view
        returns (bool)
    {
        return actionHash == _hash && nonce == _nonce;
    }

    function sendableActions() external view returns (string[] memory) {
        return _sendableActions.names();
    }

    modifier onlySendableAction(Action memory action) {
        if (_isApprovedController(msg.sender, action.selector)) {
            return;
        }
        require(
            _sendableActions.contains(action.selector),
            'ERC5050: invalid action'
        );
        require(
            _isApprovedOrSelf(action.user, action.selector),
            'ERC5050: unapproved sender'
        );
        _;
    }

    function approveForAction(
        address _account,
        bytes4 _action,
        address _approved
    ) public virtual override returns (bool) {
        require(_approved != _account, 'ERC5050: approve to caller');

        require(
            msg.sender == _account ||
                isApprovedForAllActions(_account, msg.sender),
            'ERC5050: approve caller is not account nor approved for all'
        );

        actionApprovals[_account][_action] = _approved;
        emit ApprovalForAction(_account, _action, _approved);

        return true;
    }

    function setApprovalForAllActions(address _operator, bool _approved)
        public
        virtual
        override
    {
        require(msg.sender != _operator, 'ERC5050: approve to caller');

        operatorApprovals[msg.sender][_operator] = _approved;

        emit ApprovalForAllActions(msg.sender, _operator, _approved);
    }

    function getApprovedForAction(address _account, bytes4 _action)
        public
        view
        returns (address)
    {
        return actionApprovals[_account][_action];
    }

    function isApprovedForAllActions(address _account, address _operator)
        public
        view
        returns (bool)
    {
        return operatorApprovals[_account][_operator];
    }

    function _sendAction(Action memory action) internal {
        if (!_isApprovedController(msg.sender, action.selector)) {
            action.from._address = address(this);
            bool toIsContract = action.to._address.isContract();
            bool stateIsContract = action.state.isContract();
            address next;
            if (toIsContract) {
                next = action.to._address;
            } else if (stateIsContract) {
                next = action.state;
            }
            uint256 nonce;
            if (toIsContract && stateIsContract) {
                _validate(action);
                nonce = _nonce;
            }
            if (next.isContract()) {
                try
                    IERC5050Receiver(next).onActionReceived{value: msg.value}(
                        action,
                        nonce
                    )
                {} catch Error(string memory err) {
                    revert(err);
                } catch (bytes memory returnData) {
                    if (returnData.length > 0) {
                        revert(string(returnData));
                    }
                }
            }
        }
        emit SendAction(
            action.selector,
            action.user,
            action.from._address,
            action.from._tokenId,
            action.to._address,
            action.to._tokenId,
            action.state,
            action.data
        );
    }

    function _validate(Action memory action) internal {
        ++_nonce;
        _hash = bytes32(
            keccak256(
                abi.encodePacked(
                    action.selector,
                    action.user,
                    action.from._address,
                    action.from._tokenId,
                    action.to._address,
                    action.to._tokenId,
                    action.state,
                    action.data,
                    _nonce
                )
            )
        );
    }

    function _isApprovedOrSelf(address account, bytes4 action)
        internal
        view
        returns (bool)
    {
        return (msg.sender == account ||
            isApprovedForAllActions(account, msg.sender) ||
            getApprovedForAction(account, action) == msg.sender);
    }

    function _registerSendable(string memory action) internal {
        _sendableActions.add(action);
    }
}

pragma solidity ^0.8.0;

/**********************************************************\
* Author: alxi <[email protected]> (https://twitter.com/0xalxi)
* EIP-5050 Token Interaction Standard: [tbd]
*
* Implementation of an interactive token protocol.
/**********************************************************/

contract ERC5050Receiver is Controllable, IERC5050Receiver {
    using Address for address;
    using ActionsSet for ActionsSet.Set;

    ActionsSet.Set _receivableActions;

    modifier onlyReceivableAction(Action calldata action, uint256 nonce) {
        if (_isApprovedController(msg.sender, action.selector)) {
            return;
        }
        require(
            action.to._address == address(this),
            'ERC5050: invalid receiver'
        );
        require(
            _receivableActions.contains(action.selector),
            'ERC5050: invalid action'
        );
        require(
            action.from._address == address(0) ||
                action.from._address == msg.sender,
            'ERC5050: invalid sender'
        );
        require(
            (action.from._address != address(0) && action.user == tx.origin) ||
                action.user == msg.sender,
            'ERC5050: invalid sender'
        );
        _;
    }

    function receivableActions() external view returns (string[] memory) {
        return _receivableActions.names();
    }

    function onActionReceived(Action calldata action, uint256 nonce)
        external
        payable
        virtual
        override
        onlyReceivableAction(action, nonce)
    {
        _onActionReceived(action, nonce);
    }

    function _onActionReceived(Action calldata action, uint256 nonce)
        internal
        virtual
    {
        if (!_isApprovedController(msg.sender, action.selector)) {
            if (action.state != address(0)) {
                require(action.state.isContract(), 'ERC5050: invalid state');
                try
                    IERC5050Receiver(action.state).onActionReceived{
                        value: msg.value
                    }(action, nonce)
                {} catch (bytes memory reason) {
                    if (reason.length == 0) {
                        revert('ERC5050: call to non ERC5050Receiver');
                    } else {
                        revert('Error 432');
                    }
                }
            }
        }
        emit ActionReceived(
            action.selector,
            action.user,
            action.from._address,
            action.from._tokenId,
            action.to._address,
            action.to._tokenId,
            action.state,
            action.data
        );
    }

    function _registerReceivable(string memory action) internal {
        _receivableActions.add(action);
    }
}

pragma solidity ^0.8.0;

/**********************************************************\
* Author: alxi <[email protected]> (https://twitter.com/0xalxi)
* EIP-5050 Token Interaction Standard: [tbd]
*
* Implementation of an interactive token protocol.
/**********************************************************/

contract ERC5050 is ERC5050Sender, ERC5050Receiver {
    function _registerAction(string memory action) internal {
        _registerReceivable(action);
        _registerSendable(action);
    }
}

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Base64.sol)

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
    string internal constant _TABLE =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return '';

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        /// @solidity memory-safe-assembly
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

                mstore8(
                    resultPtr,
                    mload(add(tablePtr, and(shr(18, input), 0x3F)))
                )
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(
                    resultPtr,
                    mload(add(tablePtr, and(shr(12, input), 0x3F)))
                )
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(
                    resultPtr,
                    mload(add(tablePtr, and(shr(6, input), 0x3F)))
                )
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

pragma solidity ^0.8.2;

interface IToken {
    function balanceOf(address) external view returns (uint256);
}

interface IDojoji {
    function openDojoji() external returns (bool);
}

contract DojojiBell is ERC721A, ERC5050, Ownable, ReentrancyGuard {

   
    string public universalCode = unicode'⛩️';
    using Strings for uint256;
    bool public TempleOpened = true;
    uint256 public bells = 3333;
    uint256 public _maxEnligthened = 333;
    uint256 public _enligthenedBells = 0;
    uint256 public MaxRing = 2;
    uint256 public bellsMintLimit = 1;
    bool public teamMinted = false;
    bool public openERC20 = false;

    uint256 public _totalRings = 0;
    uint256 public _totalpray = 0;
    uint256 public _ringsToEnlight = 6;
    uint256 public _prayTime = 6 hours;

    mapping(uint256 => uint256) public userTotalRings;
    mapping(uint256 => uint256) public userTotalPrays;
    mapping(uint256 => uint256) public userPraySinceRing;
    mapping(address => bool) public claimStatuses;
    mapping(address => bool) public hasBell;
    mapping(address => uint256) public bellCounter;
    mapping(address => uint256) public originalRinger;
    mapping(uint256 => uint256) public prayCooldown;
    mapping(uint256 => bool) public _isEnlightened;
    mapping(address => bool) public _hasBurned;

    address dojojiERC20;
    bytes public constant DATA = hex'001011';
    bytes4 public constant RING_SELECTOR = bytes4(keccak256('ring'));
    bytes4 public constant PRAY_SELECTOR = bytes4(keccak256('pray'));
    bytes4 public constant CAST_SELECTOR = bytes4(keccak256('cast'));
    mapping(address => bool) public _isAdmin;

    uint256 public FREN_PRICE = 0.0222 ether;
    uint256 public BELL_PRICE = 0.0333 ether;
    uint256 public ENGLIGHTENED_PRICE = 3.33 ether;

    uint256 public _burnReward = 100 ether;

    Action public _ring;
    Action public _pray;
    Object public userfrom;
    Object public userto;
    string public _enlightenedURI;
    string public _tokenURI;
    event MushroomEaten(uint256 bellId);

    constructor(string memory _baseuri,string memory _enlighturi) ERC721A('Dojoji Bell', 'BELL') {
        _registerReceivable('pray');
        _registerReceivable('ring');
        _registerReceivable('cast');
        _tokenURI=_baseuri;
        _enlightenedURI=_enlighturi;
    }

    address internal constant dojoji_grave =
        0x000000000000000000000000000000000000dEaD;
    address internal constant oxmon_address =
        0x3aaDA3e213aBf8529606924d8D1c55CbDc70Bf74;
    address internal constant goblintown_address =
        0xbCe3781ae7Ca1a5e050Bd9C4c77369867eBc307e;
    address internal constant saudis_address =
        0xe21EBCD28d37A67757B9Bc7b290f4C4928A430b1;
    address internal constant spells_address =
        0x7fef3f3364C7d8B9BFabB1b24D5CE92A402c6Bd3;
    address internal constant tsuka_address =
        0xc5fB36dd2fb59d3B98dEfF88425a3F425Ee469eD;
   address internal constant suzume_address =
        0x0B452278223D3954F4AC050949D7998e373e7E43;

    function _baseURI() internal view virtual override returns (string memory) {
        return _tokenURI;
    }

    function _enlightenmentURI() internal view virtual returns (string memory) {
        return _enlightenedURI;
    }

    function claimBell() external payable nonReentrant {
        uint256 bellId = totalSupply();
        require(TempleOpened, "The temple isn't opened");
        require(bellId < bells, 'No bells left...');
        require(msg.sender == tx.origin);
        require(!claimStatuses[msg.sender], 'Bell already claimed');
        require(
            IToken(goblintown_address).balanceOf(msg.sender) > 0 ||
                IToken(saudis_address).balanceOf(msg.sender) > 0 ||
                IToken(spells_address).balanceOf(msg.sender) > 0 ||
                IToken(oxmon_address).balanceOf(msg.sender) > 0 ||
                IToken(tsuka_address).balanceOf(msg.sender) > 0 ||
                IToken(suzume_address).balanceOf(msg.sender) > 0
        );
        require(
            msg.value >= FREN_PRICE,
            "pls attach 0.0222 ether per bell"
        );
        _safeMint(msg.sender, 1);
        _totalRings++;
        userTotalRings[bellId]++;
        hasBell[msg.sender] = true;
        originalRinger[msg.sender] = bellId;
        claimStatuses[msg.sender] = true;
    }

    //  🙏🏻🙏🙏🏻
    function mintBell() external payable nonReentrant mintConditions(1) {
        uint256 bellId = totalSupply();
        require(TempleOpened, "The Quest for enlightment han't begun");
        require(!hasBell[msg.sender], 'User already has a Bell');
        require(
            msg.value >= BELL_PRICE,
            unicode'Wow, pls attach 0.0333 ether per bell'
        );
        _safeMint(msg.sender, 1);
        _totalRings++;
        userTotalRings[bellId]++;
        hasBell[msg.sender] = true;
        originalRinger[msg.sender] = bellId;

        if (_totalRings >= MaxRing && !openERC20) {
            IDojoji(dojojiERC20).openDojoji();
            openERC20 = true;
        }
    }

    //
    function mintEnlightened() external payable nonReentrant {
        uint256 bellId = totalSupply();
        require(TempleOpened, "The Quest for enlightment han't begun");
        require(
            _maxEnligthened > 0,
            'The enligthened Ones have reached te maximum'
        );
        require(bellId < bells, 'No bells left...');
        require(msg.sender == tx.origin);
        require(
            msg.value >= ENGLIGHTENED_PRICE,
            unicode'ENGLIGHTENED Bells requiring 0.333 ether'
        );
        _safeMint(msg.sender, 1);
        _totalRings++;
        userTotalRings[bellId]++;
        _maxEnligthened -= 1;
        _enligthenedBells++;
        hasBell[msg.sender] = true;
        originalRinger[msg.sender] = bellId;
        _isEnlightened[bellId] = true;
    }

    function ringBell() external payable {
        userfrom = Object({
            _address: msg.sender,
            _tokenId: originalRinger[msg.sender]
        });
        userto = Object({
            _address: address(this),
            _tokenId: originalRinger[msg.sender]
        });

        _ring = Action({
            selector: RING_SELECTOR,
            user: msg.sender,
            from: userfrom,
            to: userto,
            state: address(this),
            data: DATA
        });

        _sendAction(_ring);
    }

    function pray() external payable {
        userfrom = Object({
            _address: msg.sender,
            _tokenId: originalRinger[msg.sender]
        });
        userto = Object({
            _address: address(this),
            _tokenId: originalRinger[msg.sender]
        });

        _pray = Action({
            selector: PRAY_SELECTOR,
            user: msg.sender,
            from: userfrom,
            to: userto,
            state: address(this),
            data: DATA
        });

        _sendAction(_pray);
    }

    function sendAction(Action memory action)
        external
        payable
        override
        onlySendableAction(action)
    {
        require(
            msg.sender == ownerOf(action.from._tokenId),
            'Spells: invalid sender'
        );
        _sendAction(action);
    }

    function _canRing(address _user) public view returns (bool) {
        uint256 tokenID = originalRinger[_user];
        if (userPraySinceRing[tokenID] > 2) return true;
        else return false;
    }

    function _canPray(address _user) public view returns (bool) {
        uint256 tokenID = originalRinger[_user];
        if (prayCooldown[tokenID] < block.timestamp) return true;
        else return false;
    }

    // 🔮
    function onActionReceived(Action calldata action, uint256 _nonce)
        external
        payable
        override
        onlyReceivableAction(action, _nonce)
    {
        require(
            action.selector == RING_SELECTOR ||
                action.selector == PRAY_SELECTOR,
            'Dojoji: invalid action.selector'
        );
        if (action.selector == RING_SELECTOR) {
            require(
                action.user == ownerOf(action.to._tokenId),
                'Dojoji: sender not owner of this bell'
            );

            require(_canRing(action.user), 'Sender must pray more');

            _totalRings++;
            userTotalRings[action.to._tokenId]++;
            userPraySinceRing[action.to._tokenId] -= 3;

            if (
                userTotalRings[action.to._tokenId] > _ringsToEnlight &&
                _maxEnligthened > 0
            ) {
                _isEnlightened[action.to._tokenId] = true;
                _maxEnligthened -= 1;
            }

            if (_totalRings >= MaxRing && !openERC20) {
                IDojoji(dojojiERC20).openDojoji();
                openERC20 = true;
            }
        }
        if (action.selector == PRAY_SELECTOR) {
            require(
                action.user == ownerOf(action.to._tokenId),
                'Dojoji: sender not owner of this bell'
            );
            require(_canPray(action.user), 'Must wait 3 hours before pray');

            userPraySinceRing[action.to._tokenId]++;
            userTotalPrays[action.to._tokenId]++;
            _totalpray++;
            prayCooldown[action.to._tokenId] = block.timestamp + _prayTime;
        }
        if (action.selector == CAST_SELECTOR) {
            require(
                action.user == ownerOf(action.to._tokenId),
                'Dojoji: sender not owner of this bell'
            );
            require(
                this.isEnlightened(action.user),
                'You must Ring and Pray more'
            );

            require(
                !_hasBurned[action.user],
                'You Have already melted your bell'
            );
            _burn(action.to._tokenId);
            _hasBurned[action.user] = true;

            require(
                IERC20(dojojiERC20).balanceOf(address(this)) > _burnReward,
                'No more $Dojoji to give'
            );
            IERC20(dojojiERC20).transfer(action.user, _burnReward);
        }
    }

    function meltBell() public nonReentrant {
        uint256 bellId = originalRinger[msg.sender];

        require(this.isEnlightened(msg.sender), 'You must Ring and Pray more');

        require(!_hasBurned[msg.sender], 'You Have already melted your bell');
        _burn(bellId);
        _hasBurned[msg.sender] = true;

        require(
            IERC20(dojojiERC20).balanceOf(address(this)) > _burnReward,
            'No more $Dojoji to give'
        );
        IERC20(dojojiERC20).transfer(msg.sender, _burnReward);
    }

    function isEnlightened(address user) external view returns (bool) {
        uint256 bellId = originalRinger[user];
        return _isEnlightened[bellId];
    }

    function broadcastEnlightenedMessage(
        uint256 bellId,
        string calldata message
    ) public {
        require(msg.sender == ownerOf(bellId), 'Mushrooms: sender not owner');
        require(_isEnlightened[bellId], "Bell isn't Enlightened");
        universalCode = message;
    }

    // 🔔
    function teamMinting(address _address, uint256 _bell) public onlyOwner {

        uint256 totalmushrooms = totalSupply();
        require(totalmushrooms + _bell <= bells);
        _safeMint(_address, _bell);
        _totalRings = _totalRings + _bell;
       
    }

    function openTemple(bool _open) external onlyOwner {
        TempleOpened = _open;
    }

    function dojojifundus() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }('');
        require(success);
    }

    function somethingAboutTokens(address token) external onlyOwner {
        uint256 balance = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(msg.sender, balance);
    }

    function setDojojiAddress(address _dojoji) external onlyOwner {
        dojojiERC20 = _dojoji;
    }

    function setBaseUri(string memory uri) external onlyOwner {
        _tokenURI = uri;
    }

    function setEnlightenedUri(string memory uri) external onlyOwner {
        _enlightenedURI = uri;
    }

    function updateprayTime(uint256 praytime) external onlyOwner {
        _prayTime = praytime;
    }

    function updateRingsToEnlight(uint256 ringsToEnlight) external onlyOwner {
        _ringsToEnlight = ringsToEnlight;
    }

    function updatePrices(
        uint256 _frenPrice,
        uint256 _bellPrice,
        uint256 _enlightenedPrice
    ) external onlyOwner {
        FREN_PRICE = _frenPrice;
        BELL_PRICE = _bellPrice;
        ENGLIGHTENED_PRICE = _enlightenedPrice;
    }

    function setAdmin(address _dojoji) external onlyOwner {
        _isAdmin[_dojoji] = true;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        string memory url;
        if (_isEnlightened[tokenId]) {
            url = _enlightenmentURI();
        } else {
            url = _baseURI();
        }
        
        return url;
    }

    modifier mintConditions(uint256 _bell) {
        require(TempleOpened, 'Patience is key');
        require(totalSupply() + _bell <= bells, 'No bells left...');
        require(
            tx.origin == msg.sender,
            unicode'no bots and shady automations'
        );
        _;
    }
    modifier onlyAdmins() {
        require(
            owner() == _msgSender() || _isAdmin[_msgSender()],
            'Ownable: caller is not the owner'
        );
        _;
    }
}