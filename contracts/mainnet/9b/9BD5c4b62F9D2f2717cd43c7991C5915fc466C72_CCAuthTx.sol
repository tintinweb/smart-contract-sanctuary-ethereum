// SPDX-License-Identifier: MIT
// Author: ClubCards
// Developed by Max J. Rux
// Dev Twitter: @Rux_eth

pragma solidity ^0.8.0;

import "./ClubCards.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract CCAuthTx is ERC1155Receiver, Context, ReentrancyGuard {
    event AuthTx(address indexed _address, uint256 newNonce);
    mapping(address => uint256) private _authTxNonce;
    ClubCards public cc;

    constructor(ClubCards _cc) {
        cc = _cc;
    }

    function mint(
        uint256 numMints,
        uint256 waveId,
        uint256 nonce,
        uint256 timestamp,
        bytes calldata sig1,
        bytes calldata sig2
    ) external payable nonReentrant {
        address sender = tx.origin;
        address recovered = ECDSA.recover(
            ECDSA.toEthSignedMessageHash(
                keccak256(
                    abi.encode(sender, numMints, waveId, nonce, timestamp)
                )
            ),
            sig2
        );
        require(nonce == _authTxNonce[sender], "Incorrect nonce");
        require(
            recovered == cc.admin() || recovered == cc.owner(),
            "Sig doesnt recover to admin"
        );
        cc.whitelistMint{value: msg.value}(
            numMints,
            waveId,
            nonce,
            timestamp,
            sig1
        );
        emit AuthTx(sender, _authTxNonce[sender]);
        delete sender;
    }

    function claim(
        uint256[] memory tokenIds,
        uint256[] memory amounts,
        uint256 nonce,
        uint256 timestamp,
        bytes memory sig1,
        bytes memory sig2
    ) external nonReentrant {
        address sender = tx.origin;
        address recovered = ECDSA.recover(
            ECDSA.toEthSignedMessageHash(
                keccak256(
                    abi.encode(sender, tokenIds, amounts, nonce, timestamp)
                )
            ),
            sig2
        );
        require(tokenIds.length <= 10, "Too many ids at a time");
        require(nonce == _authTxNonce[sender], "Incorrect nonce");
        require(
            recovered == cc.admin() || recovered == cc.owner(),
            "Sig doesnt recover to admin"
        );
        cc.claim(tokenIds, amounts, nonce, timestamp, sig1);
        emit AuthTx(sender, _authTxNonce[sender]);
        delete sender;
    }

    function authTxNonce(address _address) public view returns (uint256) {
        return _authTxNonce[_address];
    }

    function onERC1155Received(
        address operator,
        address,
        uint256 id,
        uint256,
        bytes calldata data
    ) public virtual override returns (bytes4 response) {
        address origin = tx.origin;
        require(
            _msgSender() == address(cc),
            "CCAuthTx(onERC1155Received): 'from' is not CC address"
        );
        ++_authTxNonce[origin];
        cc.safeTransferFrom(operator, origin, id, 1, data);
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address operator,
        address,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) public virtual override returns (bytes4) {
        address origin = tx.origin;
        require(
            _msgSender() == address(cc),
            "CCAuthTx(onERC1155BatchReceived): 'from' is not CC address"
        );

        ++_authTxNonce[origin];
        cc.safeBatchTransferFrom(operator, origin, ids, values, data);
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
// Author: ClubCards
// Developed by Max J. Rux
// Dev Twitter: @Rux_eth

pragma solidity ^0.8.7;

// openzeppelin imports
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

// local imports
import "../interfaces/IClubCards.sol";
import "./CCEditions.sol";

contract ClubCards is ReentrancyGuard, CCEditions, IClubCards {
    using Address for address;
    using Strings for uint256;
    string public constant name = "ClubCards";
    string public constant symbol = "CC";
    string private conURI;

    uint256 private _maxMint = 10;

    bool private _allStatus = false;

    address private dev;

    constructor(address _dev) ERC1155("") {
        dev = _dev;
    }

    function mintCard(uint256 numMints, uint256 waveId)
        external
        payable
        override
        nonReentrant
    {
        prepMint(false, numMints, waveId);
        uint256 ti = totalSupply();
        if (numMints == 1) {
            _mint(_msgSender(), ti, 1, abi.encodePacked(waveId.toString()));
        } else {
            uint256[] memory mints = new uint256[](numMints);
            uint256[] memory amts = new uint256[](numMints);
            for (uint256 i = 0; i < numMints; i++) {
                mints[i] = ti + i;
                amts[i] = 1;
            }
            _mintBatch(
                _msgSender(),
                mints,
                amts,
                abi.encodePacked(waveId.toString())
            );
        }
        _checkReveal(waveId);
        delete ti;
    }

    function whitelistMint(
        uint256 numMints,
        uint256 waveId,
        uint256 nonce,
        uint256 timestamp,
        bytes calldata signature
    ) external payable override nonReentrant {
        prepMint(true, numMints, waveId);
        address sender = _msgSender();
        address recovered = ECDSA.recover(
            ECDSA.toEthSignedMessageHash(
                keccak256(
                    abi.encode(sender, numMints, waveId, nonce, timestamp)
                )
            ),
            signature
        );
        require(
            recovered == admin() || recovered == owner(),
            "Not authorized to mint"
        );
        uint256 ti = totalSupply();
        if (numMints == 1) {
            _mint(_msgSender(), ti, 1, abi.encodePacked((waveId.toString())));
        } else {
            uint256[] memory mints = new uint256[](numMints);
            uint256[] memory amts = new uint256[](numMints);
            for (uint256 i = 0; i < numMints; i++) {
                mints[i] = ti + i;
                amts[i] = 1;
            }
            _mintBatch(
                _msgSender(),
                mints,
                amts,
                abi.encodePacked(waveId.toString())
            );
        }
        _checkReveal(waveId);
        delete ti;
    }

    // claim txs will revert if any tokenids are not claimable
    function claim(
        uint256[] memory tokenIds,
        uint256[] memory amounts,
        uint256 nonce,
        uint256 timestamp,
        bytes memory signature
    ) external payable override nonReentrant {
        address sender = _msgSender();
        address recovered = ECDSA.recover(
            ECDSA.toEthSignedMessageHash(
                keccak256(
                    abi.encode(sender, tokenIds, amounts, nonce, timestamp)
                )
            ),
            signature
        );
        require(
            tokenIds.length > 0 && tokenIds.length == amounts.length,
            "Array lengths are invalid"
        );
        require(
            recovered == admin() || recovered == owner(),
            "Not authorized to claim"
        );

        _mintBatch(sender, tokenIds, amounts, "");
        delete recovered;
        delete sender;
    }

    function manualSetBlock(uint256 waveId) external onlyTeam {
        _setWaveStartIndexBlock(waveId);
    }

    function setAllStatus(bool newAllStatus) external onlyTeam {
        _allStatus = newAllStatus;
    }

    function setContractURI(string memory newContractURI) external onlyTeam {
        conURI = newContractURI;
    }

    function withdraw() external payable onlyOwner {
        uint256 _each = address(this).balance / 100;
        require(payable(owner()).send(_each * 85));
        require(payable(dev).send(_each * 15));
    }

    function allStatus() public view override returns (bool) {
        return _allStatus;
    }

    function uri(uint256 id)
        public
        view
        override(ERC1155, IClubCards)
        returns (string memory)
    {
        return _getURI(id);
    }

    function contractURI() public view override returns (string memory) {
        return conURI;
    }

    function prepMint(
        bool privateSale,
        uint256 numMints,
        uint256 waveId
    ) private {
        require(_waveExists(waveId), "Wave does not exist");
        (
            ,
            uint256 MAX_SUPPLY,
            ,
            uint256 price,
            ,
            ,
            bool status,
            bool whitelistStatus,
            uint256 circSupply,
            ,

        ) = getWave(waveId);
        require(whitelistStatus == privateSale, "Not authorized to mint");
        require(allStatus() && status, "Sale is paused");
        require(msg.value >= price * numMints, "Not enough ether sent");
        require(numMints <= _maxMint && numMints > 0, "Invalid mint amount");
        require(
            numMints + circSupply <= MAX_SUPPLY,
            "New mint exceeds maximum supply allowed for wave"
        );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/ECDSA.sol)

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
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
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
// Author: Club Cards
// Developed by Max J. Rux

pragma solidity ^0.8.7;

interface IClubCards {
    function mintCard(uint256 numMints, uint256 waveId) external payable;

    function whitelistMint(
        uint256 numMints,
        uint256 waveId,
        uint256 nonce,
        uint256 timestamp,
        bytes calldata signature
    ) external payable;

    function claim(
        uint256[] memory tokenIds,
        uint256[] memory amounts,
        uint256 nonce,
        uint256 timestamp,
        bytes memory signature
    ) external payable;

    function allStatus() external view returns (bool);

    function uri(uint256 id) external view returns (string memory);

    function contractURI() external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// Author: ClubCards
// Developed by Max J. Rux
// Dev Twitter: @Rux_eth

pragma solidity ^0.8.7;

// openzeppelin imports
import "./Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// local imports
import "../interfaces/ICCEditions.sol";

abstract contract CCEditions is ERC1155, Ownable, ICCEditions {
    using Strings for uint256;

    /*
     * Tracks waves.
     */
    mapping(uint256 => uint256) private _waves;
    /*
     * Tracks claims.
     */
    mapping(uint256 => uint72) private _claims;
    /*
     * Stores the provenance hash of each wave.
     *
     * Read about the importance of provenance hashes in
     * NFTs here: https://medium.com/coinmonks/the-elegance-of-the-nft-provenance-hash-solution-823b39f99473
     */
    mapping(uint256 => string) private waveProv;
    mapping(uint256 => string) private waveURI;
    mapping(uint256 => string) private claimURI;
    /*
     * Stores edition information for each tokenId
     *
     * Each index in tokens represents a tokenId.
     *
     * byte    1: Boolean to determine if a tokenId associates with a Wave
     *            or Claim.
     * bytes 2-3: EditionId(waveId/claimId)
     * bytes 4-5: TokenIdOfEdition
     */
    uint40[] private tokens;

    // track authorized transaction nonces
    mapping(address => uint256) private _authTxNonce;

    function setWaveStartIndex(uint256 waveId) external override {
        (
            ,
            uint256 MAX_SUPPLY,
            ,
            ,
            uint256 startIndex,
            uint256 startIndexBlock,
            ,
            ,
            ,
            ,

        ) = getWave(waveId);

        require(
            startIndexBlock != 0,
            "CCEditions: Starting index block not set"
        );
        require(startIndex == 0, "CCEditions: Starting index already set");
        bytes32 blockHash = blockhash(startIndexBlock);
        uint256 si = uint256(blockHash) % MAX_SUPPLY;
        if (blockHash == bytes32(0)) {
            si = uint256(blockhash(block.number - 1)) % MAX_SUPPLY;
        }
        if (si == 0) {
            si += 1;
        }
        _waves[waveId] = _waves[waveId] |= si << 144;

        emit WaveStartIndexSet(waveId, si);
        delete si;
        delete blockHash;
    }

    function setWave(
        uint256 waveId,
        uint256 MAX_SUPPLY,
        uint256 REVEAL_TIMESTAMP,
        uint256 price,
        bool status,
        bool whitelistStatus,
        string calldata provHash,
        string calldata _waveURI
    ) external onlyTeam {
        require(!_waveExists(waveId), "CCEditions: Wave already exists");
        require(
            waveId <= type(uint8).max &&
                MAX_SUPPLY <= type(uint16).max &&
                REVEAL_TIMESTAMP <= type(uint56).max &&
                price <= type(uint64).max,
            "CCEditions: Value is too big!"
        );
        uint256 wave = waveId;
        wave |= MAX_SUPPLY << 8;
        wave |= REVEAL_TIMESTAMP << 24;
        wave |= price << 80;
        wave |= uint256(status ? 1 : 0) << 224;
        wave |= uint256(whitelistStatus ? 1 : 0) << 232;
        _waves[waveId] = wave;
        waveProv[waveId] = provHash;
        waveURI[waveId] = _waveURI;
    }

    function setWavePrice(uint256 waveId, uint256 newPrice) external onlyTeam {
        require(_waveExists(waveId), "CCEditions: Wave does not exist");
        require(newPrice <= type(uint64).max, "CCEditions: Too high");
        (
            ,
            ,
            ,
            ,
            uint256 startIndex,
            uint256 startIndexBlock,
            bool status,
            bool whitelistStatus,
            uint256 supply,
            ,

        ) = getWave(waveId);

        uint256 wave = uint256(uint88(_waves[waveId]));
        wave |= newPrice << 80;
        wave |= startIndex << 144;
        wave |= startIndexBlock << 160;
        wave |= uint256(status ? 1 : 0) << 224;
        wave |= uint256(whitelistStatus ? 1 : 0) << 232;
        wave |= supply << 240;
        _waves[waveId] = wave;
    }

    function setWaveStatus(uint256 waveId, bool newStatus) external onlyTeam {
        require(_waveExists(waveId), "CCEditions: Wave does not exist");
        (
            ,
            ,
            ,
            uint256 price,
            uint256 startIndex,
            uint256 startIndexBlock,
            ,
            bool whitelistStatus,
            uint256 supply,
            ,

        ) = getWave(waveId);
        uint256 wave = uint256(uint88(_waves[waveId]));
        wave |= price << 80;
        wave |= startIndex << 144;
        wave |= startIndexBlock << 160;
        wave |= uint256(newStatus ? 1 : 0) << 224;
        wave |= uint256(whitelistStatus ? 1 : 0) << 232;
        wave |= supply << 240;
        _waves[waveId] = wave;
    }

    function setWaveWLStatus(uint256 waveId, bool newWLStatus)
        external
        onlyTeam
    {
        require(_waveExists(waveId), "CCEditions: Wave does not exist");
        (
            ,
            ,
            ,
            uint256 price,
            uint256 startIndex,
            uint256 startIndexBlock,
            bool status,
            ,
            uint256 supply,
            ,

        ) = getWave(waveId);
        uint256 wave = uint256(uint88(_waves[waveId]));
        wave |= price << 80;
        wave |= startIndex << 144;
        wave |= startIndexBlock << 160;
        wave |= uint256(status ? 1 : 0) << 224;
        wave |= uint256(newWLStatus ? 1 : 0) << 232;
        wave |= supply << 240;
        _waves[waveId] = wave;
    }

    function setWaveURI(uint256 waveId, string memory newURI)
        external
        onlyTeam
    {
        waveURI[waveId] = newURI;
    }

    function setClaimURI(uint256 claimId, string memory newURI)
        external
        onlyTeam
    {
        require(_claimExists(claimId), "ClaimId does not exist");
        require(claimId > 0, "ClaimId cannot be zero");
        claimURI[claimId] = newURI;
    }

    function setClaimStatus(uint256 claimId, bool newStatus) external onlyTeam {
        require(_claimExists(claimId), "ClaimId does not exist");
        require(claimId > 0, "ClaimId cannot be zero");
        (, , , uint256 supply, ) = getClaim(claimId);
        uint256 claim = uint40(_claims[claimId]);
        claim |= uint8(newStatus ? 1 : 0) << 40;
        claim |= supply << 48;
        _claims[claimId] = uint72(claim);
    }

    function setClaim(
        uint256 claimId,
        string memory uri,
        bool status
    ) external onlyTeam {
        require(!_claimExists(claimId), "CCEditions: Claim already exists");
        uint256 ti = totalSupply();
        require(
            claimId <= type(uint16).max && ti <= type(uint24).max,
            "CCEditions: Value is too big!"
        );
        uint256 claim = claimId;
        claim |= ti << 16;
        claim |= uint256(status ? 1 : 0) << 40;
        _claims[claimId] = uint72(claim);

        uint256 token = 1;
        token |= uint256(claimId << 8);
        tokens.push(uint40(token));
        claimURI[claimId] = uri;
        emit ClaimSet(ti, claimId);
    }

    function getClaim(uint256 claimId)
        public
        view
        override
        returns (
            uint256 CLAIM_INDEX,
            uint256 TOKEN_INDEX,
            bool status,
            uint256 supply,
            string memory uri
        )
    {
        require(_claimExists(claimId), "CCEditions: Claim does not exist");
        uint256 claim = _claims[claimId];
        CLAIM_INDEX = uint16(claim);
        TOKEN_INDEX = uint24(claim >> 16);
        status = uint8(claim >> 40) == 1;
        supply = uint24(claim >> 48);
        uri = claimURI[claimId];
    }

    function authTxNonce(address _address)
        public
        view
        override
        returns (uint256)
    {
        return _authTxNonce[_address];
    }

    function getToken(uint256 id)
        public
        view
        override
        returns (
            bool isClaim,
            uint256 editionId,
            uint256 tokenIdOfEdition
        )
    {
        require(_exists(id), "Token does not exist");
        (isClaim, editionId, tokenIdOfEdition) = _getToken(tokens[id]);
    }

    function totalSupply() public view override returns (uint256) {
        return tokens.length;
    }

    function getWave(uint256 waveId)
        public
        view
        override
        returns (
            uint256 WAVE_INDEX,
            uint256 MAX_SUPPLY,
            uint256 REVEAL_TIMESTAMP,
            uint256 price,
            uint256 startIndex,
            uint256 startIndexBlock,
            bool status,
            bool whitelistStatus,
            uint256 supply,
            string memory provHash,
            string memory _waveURI
        )
    {
        require(_waveExists(waveId), "CCEditions: Wave does not exist");
        uint256 wave = _waves[waveId];
        WAVE_INDEX = uint8(wave);
        MAX_SUPPLY = uint16(wave >> 8);
        REVEAL_TIMESTAMP = uint56(wave >> 24);
        price = uint64(wave >> 80);
        startIndex = uint16(wave >> 144);
        startIndexBlock = uint64(wave >> 160);
        status = uint8(wave >> 224) == 1;
        whitelistStatus = uint8(wave >> 232) == 1;
        supply = uint16(wave >> 240);
        provHash = waveProv[waveId];
        _waveURI = waveURI[waveId];
    }

    // check if tokenId exists
    function _exists(uint256 id) internal view returns (bool) {
        return id >= 0 && id < totalSupply();
    }

    function _setWaveStartIndexBlock(uint256 waveId) internal {
        (
            ,
            ,
            ,
            uint256 price,
            uint256 startIndex,
            uint256 startIndexBlock,
            bool status,
            bool whitelistStatus,
            uint256 supply,
            ,

        ) = getWave(waveId);

        if (startIndexBlock == 0) {
            uint256 bn = block.number;
            uint256 wave = uint256(uint88(_waves[waveId]));
            wave |= price << 80;
            wave |= startIndex << 144;
            wave |= bn << 160;
            wave |= uint256(status ? 1 : 0) << 224;
            wave |= uint256(whitelistStatus ? 1 : 0) << 232;
            wave |= supply << 240;
            _waves[waveId] = wave;

            emit WaveStartIndexBlockSet(waveId, bn);
        }
    }

    function _checkReveal(uint256 waveId) internal {
        (
            ,
            uint256 MAX_SUPPLY, // 16
            uint256 REVEAL_TIMESTAMP, // 64
            ,
            uint256 startIndex, // 8
            ,
            ,
            ,
            uint256 supply,
            ,

        ) = getWave(waveId);
        if (
            startIndex == 0 &&
            ((supply == MAX_SUPPLY) || block.timestamp >= REVEAL_TIMESTAMP)
        ) {
            _setWaveStartIndexBlock(waveId);
        }
    }

    function _getURI(uint256 id) internal view returns (string memory) {
        require(_exists(id), "CCEditions: TokenId does not exist");
        (bool isClaim, uint256 editionId, uint256 tokenIdOfEdition) = _getToken(
            tokens[id]
        );
        if (isClaim) {
            return claimURI[editionId];
        } else {
            return
                string(
                    abi.encodePacked(
                        waveURI[editionId],
                        tokenIdOfEdition.toString()
                    )
                );
        }
    }

    // check if a wave exists
    function _waveExists(uint256 waveId) internal view returns (bool) {
        return _waves[waveId] != 0;
    }

    // check if a claim exists
    function _claimExists(uint256 claimId) internal view returns (bool) {
        return _claims[claimId] != 0;
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
        if (from == address(0)) {
            uint256 edId = st2num(string(data));

            if (edId == 0) {
                for (uint256 i = 0; i < ids.length; i++) {
                    (bool isClaim, uint256 claimId, ) = _getToken(
                        tokens[ids[i]]
                    );
                    require(isClaim, "Token is not claimable");
                    _increaseClaimSupply(claimId, amounts[i]);
                }
                emit Claimed(to, _authTxNonce[to], ids, amounts);
            } else {
                for (uint256 i = 0; i < ids.length; i++) {
                    require(!_exists(ids[i]), "Token already exists");
                    require(amounts[i] == 1, "Invalid mint amount");
                }
                if (_increaseWaveSupply(edId, ids.length)) {
                    _authTxNonce[to]++;
                    emit WhitelistMinted(
                        to,
                        ids.length,
                        edId,
                        _authTxNonce[to]
                    );
                }
            }
        }
    }

    function _getToken(uint256 tokenData)
        private
        pure
        returns (
            bool isClaim,
            uint256 editionId,
            uint256 tokenIdOfEdition
        )
    {
        isClaim = uint8(tokenData) == 1;
        editionId = uint16(tokenData >> 8);
        tokenIdOfEdition = uint16(tokenData >> 24);
    }

    function _increaseClaimSupply(uint256 claimId, uint256 amount) private {
        (, , bool status, uint256 supply, ) = getClaim(claimId);
        require(status, "Claim is paused");
        uint256 temp = _claims[claimId];
        temp = uint256(uint48(temp));
        temp |= uint256(supply + amount) << 48;
        _claims[claimId] = uint72(temp);
    }

    function st2num(string memory numString) private pure returns (uint256) {
        uint256 val = 0;
        bytes memory stringBytes = bytes(numString);
        for (uint256 i = 0; i < stringBytes.length; i++) {
            uint256 exp = stringBytes.length - i;
            bytes1 ival = stringBytes[i];
            uint8 uval = uint8(ival);
            uint256 jval = uval - uint256(0x30);

            val += (uint256(jval) * (10**(exp - 1)));
        }
        return val;
    }

    function _increaseWaveSupply(uint256 waveId, uint256 numMints)
        private
        returns (bool)
    {
        (, , , , , , , bool whitelistStatus, uint256 supply, , ) = getWave(
            waveId
        );
        uint256 temp = _waves[waveId];
        temp = uint256(uint240(temp));
        _waves[waveId] = temp |= uint256(supply + numMints) << 240;
        for (uint256 i = 0; i < numMints; i++) {
            temp = 0;
            temp |= uint24(waveId << 8);
            temp |= uint40((supply + i) << 24);
            tokens.push(uint40(temp));
        }
        return whitelistStatus;
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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";

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
    address private _admin;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    event AdminChanged(address indexed previousAdmin, address indexed newAdmin);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
        _setAdmin(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    // returns the address of the current admin
    function admin() public view virtual returns (address) {
        return _admin;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    modifier onlyTeam() {
        require(
            msg.sender == _admin || msg.sender == owner(),
            "Not authorized"
        );
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    function setAdmin(address newAdmin) public virtual onlyOwner {
        require(
            newAdmin != address(0),
            "Ownable: new admin is the zero address"
        );
        _setAdmin(newAdmin);
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

    function _setAdmin(address newAdmin) internal virtual {
        address oldAdmin = _admin;
        _admin = newAdmin;
        emit AdminChanged(oldAdmin, newAdmin);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// SPDX-License-Identifier: MIT
// Author: Club Cards
// Developed by Max J. Rux

pragma solidity ^0.8.7;

interface ICCEditions {
    event Claimed(
        address indexed _address,
        uint256 authTxNonce,
        uint256[] ids,
        uint256[] amounts
    );
    event WhitelistMinted(
        address indexed _address,
        uint256 numMints,
        uint256 waveId,
        uint256 authTxNonce
    );
    event ClaimSet(uint256 indexed tokenIndex, uint256 indexed claimId);

    event WaveStartIndexBlockSet(
        uint256 indexed waveId,
        uint256 startIndexBlock
    );
    event WaveStartIndexSet(uint256 indexed waveId, uint256 startIndex);

    function setWaveStartIndex(uint256 waveId) external;

    function getClaim(uint256 claimId)
        external
        view
        returns (
            uint256 CLAIM_INDEX,
            uint256 TOKEN_INDEX,
            bool status,
            uint256 supply,
            string memory uri
        );

    function authTxNonce(address _address) external view returns (uint256);

    function getToken(uint256 id)
        external
        view
        returns (
            bool isClaim,
            uint256 editionId,
            uint256 tokenIdOfEdition
        );

    function totalSupply() external view returns (uint256);

    function getWave(uint256 waveId)
        external
        view
        returns (
            uint256 WAVE_INDEX,
            uint256 MAX_SUPPLY,
            uint256 REVEAL_TIMESTAMP,
            uint256 price,
            uint256 startIndex,
            uint256 startIndexBlock,
            bool status,
            bool whitelistStatus,
            uint256 supply,
            string memory provHash,
            string memory _waveURI
        );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
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

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
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