/**
 *Submitted for verification at Etherscan.io on 2022-04-01
*/

// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.8.0;

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

pragma solidity 0.8.0;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

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
    function getApproved(uint256 tokenId) external view returns (address operator);

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
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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

pragma solidity 0.8.0;

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
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

pragma solidity 0.8.0;

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

pragma solidity 0.8.0;

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

pragma solidity 0.8.0;

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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
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

pragma solidity 0.8.0;

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {

    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    bytes constant private base64urlchars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_=";


    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }

    function decode(string memory _str) internal pure returns (string memory) {
        require( (bytes(_str).length % 4) == 0, "Length not multiple of 4");
        bytes memory _bs = bytes(_str);

        uint i = 0;
        uint j = 0;
        uint dec_length = (_bs.length/4) * 3;
        bytes memory dec = new bytes(dec_length);

        for (; i< _bs.length; i+=4 ) {
            (dec[j], dec[j+1], dec[j+2]) = dencode4(
                bytes1(_bs[i]),
                bytes1(_bs[i+1]),
                bytes1(_bs[i+2]),
                bytes1(_bs[i+3])
            );
            j += 3;
        }
        while (dec[--j]==0)
        {}

        bytes memory res = new bytes(j+1);
        for (i=0; i<=j;i++)
            res[i] = dec[i];

        return string(res);
    }

    function dencode4 (bytes1 b0, bytes1 b1, bytes1 b2, bytes1 b3) private pure returns (bytes1 a0, bytes1 a1, bytes1 a2)
    {
        uint pos0 = charpos(b0);
        uint pos1 = charpos(b1);
        uint pos2 = charpos(b2)%64;
        uint pos3 = charpos(b3)%64;

        a0 = bytes1(uint8(( pos0 << 2 | pos1 >> 4 )));
        a1 = bytes1(uint8(( (pos1&15)<<4 | pos2 >> 2)));
        a2 = bytes1(uint8(( (pos2&3)<<6 | pos3 )));
    }

    function charpos(bytes1 char) private pure returns (uint pos) {
        for (; base64urlchars[pos] != char; pos++)
        {}    //for loop body is not necessary
        require (base64urlchars[pos]==char, "Illegal char in string");
        return pos;
    }

}

pragma solidity 0.8.0;

library TokenIds {
    uint256 private constant TOKEN_ID_MASK = 0x7fffffff;
    uint256 private constant WELD_MASK = 0x80000000;
    uint256 private constant WELD_UNMASK = ~WELD_MASK;

    function getTokenId(uint256 self, uint256 i) internal pure returns (uint256) {
        uint256 shifts = i * 32;
        return (self & (TOKEN_ID_MASK << shifts)) >> shifts;
    }


    function setTokenId(uint256 self, uint256 i, uint256 tokenId) internal pure returns (uint256) {
        require(tokenId <= TOKEN_ID_MASK, "TOKEN_ID");
        uint256 shifts = i * 32;
        return (self & (~(TOKEN_ID_MASK << shifts))) | (tokenId << shifts);
    }

    function getTokenIds(uint256 self) internal pure returns (uint256[8] memory tokenIds) {
        for (uint256 i = 0; i < 8; i++) {
            tokenIds[i] = getTokenId(self, i);
        }
    }

    function getSeal(uint256 self) internal pure returns (bool) {
        return self & WELD_MASK != 0;
    }

    function setSeal(uint256 self, bool weld) internal pure returns (uint256) {
        return weld ? (self | WELD_MASK) : (self & WELD_UNMASK);
    }
}

library ComponentBitmap {
    function setIdxAttr(mapping(uint256 => uint256) storage slot, uint256 tokenId, uint256 idx, uint256 attr) internal {
        require(idx <= 0xff && attr <= 0xff, "OF_IDX_ATTR");
        uint256 prev = slot[tokenId / 16];
        uint256 mask = (0xffff << ((tokenId % 16) * 16));
        prev = prev & (~mask);
        prev |= ((idx << 8) | attr) << ((tokenId % 16) * 16);
        slot[tokenId / 16] = prev;
    }

    function getIdxAttr(mapping(uint256 => uint256) storage slot, uint256 tokenId) internal view returns (uint256 idx, uint256 attr) {
        uint256 prev = slot[tokenId / 16];
        uint256 mask = (0xffff << ((tokenId % 16) * 16));
        idx = ((prev & mask) >> ((tokenId % 16) * 16));
        attr = idx & 0xff;
        idx = idx >> 8;
    }
}

library AvatarBitmap {
    uint256 private constant BG_MASK = 0xf;
    uint256 private constant BG_SHIFTS = 4;

    uint256 private constant EYES_MASK = 0x1f << BG_SHIFTS;
    uint256 private constant EYES_SHIFTS = BG_SHIFTS + 5;

    uint256 private constant MONTH_MASK = 63 << EYES_SHIFTS;
    uint256 private constant MONTH_SHIFTS = EYES_SHIFTS + 6;

    uint256 private constant BODY_MASK = 63 << MONTH_SHIFTS;
    uint256 private constant BODY_SHIFTS = MONTH_SHIFTS + 6;

    uint256 private constant TOP_MASK = 0xf << BODY_SHIFTS;
    uint256 private constant TOP_SHIFTS = BODY_SHIFTS + 4;

    uint256 private constant STRAW_MASK = 0xf << TOP_SHIFTS;
    uint256 private constant STRAW_SHIFTS = TOP_SHIFTS + 4;

    uint256 private constant GESTURE_MASK = 0xf << STRAW_SHIFTS;
    uint256 private constant GESTURE_SHIFTS = STRAW_SHIFTS + 4;

    uint256 private constant TEMPLATE_MASK = 0xffff << GESTURE_SHIFTS;
    uint256 private constant TEMPLATE_SHIFTS = GESTURE_SHIFTS + 16;

    function setAttr(
        uint256 self,
        uint256 i,
        uint256 attr
    ) internal pure returns (uint256) {
        require(i < 8, "I");
        if (i == 0) return setTemplate(self, attr);
        if (i == 1) return setBG(self, attr);
        if (i == 2) return setEyes(self, attr);
        if (i == 3) return setMonth(self, attr);
        if (i == 4) return setBody(self, attr);
        if (i == 5) return setTop(self, attr);
        if (i == 6) return setStraw(self, attr);
        if (i == 7) return setGesture(self, attr);
        return 0;
    }

    function getAttr(uint256 self, uint256 i) internal pure returns (uint256) {
        require(i < 8, "I");
        if (i == 0) return getTemplate(self);
        if (i == 1) return getBG(self);
        if (i == 2) return getEyes(self);
        if (i == 3) return getMonth(self);
        if (i == 4) return getBody(self);
        if (i == 5) return getTop(self);
        if (i == 6) return getStraw(self);
        if (i == 7) return getGesture(self);
        return 0;
    }

    function getBG(uint256 self) internal pure returns (uint256) {
        return (self & BG_MASK);
    }

    function getEyes(uint256 self) internal pure returns (uint256) {
        return (self & EYES_MASK) >> BG_SHIFTS;
    }

    function getMonth(uint256 self) internal pure returns (uint256) {
        return (self & MONTH_MASK) >> EYES_SHIFTS;
    }

    function getBody(uint256 self) internal pure returns (uint256) {
        return (self & BODY_MASK) >> MONTH_SHIFTS;
    }

    function getTop(uint256 self) internal pure returns (uint256) {
        return (self & TOP_MASK) >> BODY_SHIFTS;
    }

    function getStraw(uint256 self) internal pure returns (uint256) {
        return (self & STRAW_MASK) >> TOP_SHIFTS;
    }

    function getGesture(uint256 self) internal pure returns (uint256) {
        return (self & GESTURE_MASK) >> STRAW_SHIFTS;
    }

    function setBG(uint256 self, uint256 bg) internal pure returns (uint256) {
        require(bg < 16, "BG");
        return (self & (~BG_MASK)) | bg;
    }

    function setEyes(uint256 self, uint256 eyes)
    internal
    pure
    returns (uint256)
    {
        require(eyes < 32, "EYES");
        return (self & (~EYES_MASK)) | (eyes << BG_SHIFTS);
    }

    function setMonth(uint256 self, uint256 month)
    internal
    pure
    returns (uint256)
    {
        require(month < 64, "month");
        return (self & (~MONTH_MASK)) | (month << EYES_SHIFTS);
    }

    function setBody(uint256 self, uint256 body)
    internal
    pure
    returns (uint256)
    {
        require(body < 64, "EYES");
        return (self & (~BODY_MASK)) | (body << MONTH_SHIFTS);
    }

    function setTop(uint256 self, uint256 top) internal pure returns (uint256) {
        require(top < 16, "TOP");
        return (self & (~TOP_MASK)) | (top << BODY_SHIFTS);
    }

    function setStraw(uint256 self, uint256 straw)
    internal
    pure
    returns (uint256)
    {
        require(straw < 32, "STRAW");
        return (self & (~STRAW_MASK)) | (straw << TOP_SHIFTS);
    }

    function setGesture(uint256 self, uint256 gesture)
    internal
    pure
    returns (uint256)
    {
        require(gesture < 16, "EYES");
        return (self & (~GESTURE_MASK)) | (gesture << STRAW_SHIFTS);
    }

    function getTemplate(uint256 self) internal pure returns (uint256) {
        return (self & TEMPLATE_MASK) >> GESTURE_SHIFTS;
    }

    function setTemplate(uint256 self, uint256 template)
    internal
    pure
    returns (uint256)
    {
        require(template <= 0xffff, "TEMPLATE");
        return (self & (~TEMPLATE_MASK)) | (template << GESTURE_SHIFTS);
    }
}

pragma solidity 0.8.0;

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

pragma solidity 0.8.0;

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

pragma solidity 0.8.0;

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


pragma solidity 0.8.0;

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

pragma solidity 0.8.0;

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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

pragma solidity 0.8.0;

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
     * by making the `nonReentrant` function external, and make it call a
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

pragma solidity 0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        if (b > a) return (false, 0);
        return (true, a - b);
    }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    unchecked {
        require(b <= a, errorMessage);
        return a - b;
    }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    unchecked {
        require(b > 0, errorMessage);
        return a / b;
    }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    unchecked {
        require(b > 0, errorMessage);
        return a % b;
    }
    }
}

pragma solidity 0.8.0;

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
        interfaceId == type(IERC721).interfaceId ||
        interfaceId == type(IERC721Metadata).interfaceId ||
        super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
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
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
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
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
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
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
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
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

pragma solidity 0.8.0;

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

pragma solidity 0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;
    address private immutable _CACHED_THIS;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _CACHED_THIS = address(this);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}

pragma solidity 0.8.0;

contract TimersLock is Ownable {

    uint256 private InitalTime;

    uint256[] public timers = [0, 30 days, 30 days, 30 days, 30 days];

    constructor() Ownable() {
        InitalTime = block.timestamp;
    }

    function getInitalTime() public view returns (uint256) {
        return InitalTime;
    }

    function getTimers() public view returns (uint256[] memory) {
        return timers;
    }

    function setTimers(uint256 index, uint256 time) external onlyOwner {
        require(index < timers.length, "Abnormal index");
        timers[index] = time;
    }

    function IsUnLock(uint256 count) external view returns (bool) {
        if (count < 2001) return true;
        uint256 index = (count - 1) / 2e03;
        uint256 times = InitalTime;
        for (uint256 x = 1; x <= index; x++) {
            times += timers[x];
        }
        return block.timestamp < times ? false : true;
    }
}

pragma solidity 0.8.0;

contract MadCanner is ERC721Enumerable, EIP712, ReentrancyGuard, Ownable, IERC721Receiver {
    using SafeMath for uint256;
    using Strings for uint256;
    using ECDSA for bytes32;

    // keccak256("Permit(address from,uint256 tokenId)");
    bytes32 public constant PERMIT_TYPEHASH = 0xc242e34b93f9ad1ffc2c2c079dea5dccebcd284285197f32e072ea272cc3eef1;
    uint256 public constant FIXEDCOUNT = 8;
    uint256 public constant FIXEDNUMBRER = 1e04;
    uint256 public constant Fee = 0.02 ether;
    string public constant baseURI_prefix = "ipfs://";
    string public constant sprit = "/";
    string public constant baseURI_part = "QmUcPhoXfFgNXdvU69cBUZerSVQi8y1o4KUsVuf5M79VMn/";
    string public constant baseURI = "QmaUrqFgD27LQoZUPD1snZNxiReyn6ybENKRtSYUhxyUFN/";

    uint256 public TokenId = 2e04;
    uint256 public CannerTotal;
    TimersLock public timersLock;

    mapping(uint256 => uint256) public FinishHead;
    mapping(uint256 => uint256) public PartMap;
    mapping(uint256 => bool) public ClaimMap;

    enum CannerType {Template, Background, Eyes, Mouth, Body, Top, Straw, Gesture}

    string[] private template = [
    "Template", "Background", "Eyes", "Mouth", "Body", "Top", "Straw", "Gesture"
    ];

    string[] private background = [
    "", "Wallflower Pink", "Tangerine", "Gray Screen", "Pistachio Green", "Celestial Blue", "Dried Lavender", "Loggia", "Wenge",
    "Agate Green", "Sonic Silver"
    ];

    string[] private eyes = [
    "", "Wide-Eyed", "Mad", "Hypnotized", "Puzzled", "Sleepy", "Blindfold", "Angry",
    "Closed", "Central Heterochromia", "Sad", "3D Glasses", "Love", "Coins", "Sunglasses", "VR glasses",
    "Holographic Glasses", "Bloodshot", "Star Eyes", "Piercing Eyes", "Fire", "Cyborg", "Compound Eyes", "Laser Eyes",
    "Eyepatch"
    ];

    string[] private mouth = [
    "", "Grin", "Small Grin", "Mad Laugher", "Rage", "Flaming Red Lips", "Drool", "Dumbfounded",
    "Tongue Out", "Cigarette", "Phoneme Oh", "Lollipop", "Spoon", "Bread", "Plastic Straw", "Cigar",
    "Phoneme OOO", "Cheese", "Toothpick", "Mad Pizza", "Flower", "Pipe", "Grin Colored Grill", "Party Horn",
    "Jovial", "Gold Pipe", "Grin Red Agate Grill", "Grin Diamond Grill", "Grin Gold Grill", "Bubblegum", "Mad Cigar", "Mad Cigarette",
    "Flaming"
    ];

    string[] private body = [
    "", "Swirl", "Black and White", "Magic Red", "Laser", "Captain", "IronMan", "Fukurai",
    "Japanese", "Cyberpunk", "Tiger", "Zebra", "Leopard", "Marble", "Bandage", "Universe",
    "Gold", "Gengon", "Ocean", "Acidic Laser", "Heartwarming", "Mosaic", "Playboy", "Halloween",
    "Paper Waste", "De sterrennacht", "Auspicious", "Spider", "Merry Christmas", "Eyeball", "Maple Leaf", "Bubble Tea",
    "Plaid", "Abstract Art", "Candy", "Crystal Ball", "Blue Leather", "White Leather", "Dripping Glass", "Rusty Steel",
    "Blood", "Comics", "Space Swirl", "Blackhole"
    ];

    string[] private top = [
    "", "Orange", "Green", "Purple", "Blue", "Glass", "Golden", "Iron Sheet",
    "Jade", "Rainbow", "Rusty", "Wooden", "Diamond"
    ];

    string[] private straw = [
    "", "Coloured", "Dripping", "Flexible", "Recycle Paper", "Couple", "Pipe", "Diamond",
    "Golden", "Reed", "Bamboo", "Ladder", "Snake"
    ];

    string[] private gesture = [
    "", "Beer", "Diamond Ring", "Bag", "Coffee", "Thanos Gloves", "Golden Tactical Gloves", "Boxing Gloves",
    "Fabric Gloves", "Grab Doge", "Grab Kitty", "Grab Punk", "Bot Arm"
    ];

    uint256[][] private level = [
    [0, 0, 0, 0, 0],
    [11, 0, 0, 0, 0],
    [6, 11, 6, 8, 17],
    [10, 13, 10, 10, 23],
    [44, 0, 0, 0, 0],
    [5, 4, 5, 4, 9],
    [5, 4, 5, 4, 9],
    [5, 4, 5, 4, 9]
    ];

    event Claim(uint256 tokenId, address from, uint256[8] tokenIds);
    event Split(uint256 tokenId, address to);
    event Merge(uint256 indexed templateId, uint256[] ids, address to);
    event Seal(uint256 tokenId);
    event Replace(uint256 tokenId, uint256[] _headTokenIds);
    event Withdraw(address to);

    constructor() ERC721("MadCanner", "MadCanner") EIP712("MadCanner", "1") Ownable() {}

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function getBackground(uint256 tokenId) internal view returns (uint256) {
        return pluck(tokenId, "BACKGROUND", uint(CannerType.Background));
    }

    function getEyes(uint256 tokenId) internal view returns (uint256) {
        return pluck(tokenId, "EYE", uint(CannerType.Eyes));
    }

    function getMouth(uint256 tokenId) internal view returns (uint256) {
        return pluck(tokenId, "MOUTH", uint(CannerType.Mouth));
    }

    function getBody(uint256 tokenId) internal view returns (uint256) {
        return pluck(tokenId, "BODY", uint(CannerType.Body));
    }

    function getTop(uint256 tokenId) internal view returns (uint256) {
        return pluck(tokenId, "TOP", uint(CannerType.Top));
    }

    function getStraw(uint256 tokenId) internal view returns (uint256) {
        return pluck(tokenId, "STRAW", uint(CannerType.Straw));
    }

    function getGesture(uint256 tokenId) internal view returns (uint256) {
        return pluck(tokenId, "GESTURE", uint(CannerType.Gesture));
    }

    function pluck(uint256 tokenId, string memory keyPrefix, uint256 headType) internal view returns (uint256) {
        uint256 rand = random(string(abi.encodePacked(keyPrefix, tokenId.toString())));
        uint256 output = rand % level[headType][0];
        if (uint(CannerType.Background) == headType || uint(CannerType.Body) == headType) {
            return output;
        }
        uint256 greatness = rand % 21;
        if (greatness > 19) {
            output = level[headType][4].add(rand % level[headType][3]);
            return output;
        }
        if (greatness >= 14) {
            output = level[headType][2].add(rand % level[headType][1]);
            return output;
        }
        return output;
    }

    function claim(uint256 tokenId) external payable nonReentrant {
        require(tokenId > 0 && tokenId < 9501, "Token ID invalid");
        require(timersLock.IsUnLock(++CannerTotal), "Locking");
        require(msg.value >= charges(), "Insufficient handling fee");
        _claim(tokenId);
    }

    function claimPermit(uint256 tokenId, bytes calldata _signature) external {
        require(tokenId > 9500 && tokenId < 10001, "Token ID invalid");
        if (_msgSender() != owner()) {
            bytes32 digst = _hashTypedDataV4(keccak256(abi.encode(PERMIT_TYPEHASH, _msgSender(), tokenId)));
            require(digst.recover(_signature) == owner(), "Permit Failure");
        }
        _claim(tokenId);
    }

    function _claim(uint256 tokenId) internal {
        require(!ClaimMap[tokenId], "Token ID already claim");
        _safeMint(_msgSender(), tokenId);

        uint256 parts = reallocate(tokenId);
        for (uint256 x = 0; x < FIXEDCOUNT; x++) {
            uint256 attr = AvatarBitmap.getAttr(parts, x);
            if (attr == 0) continue;
            uint256 tokenId_part;
            if (uint(CannerType.Template) == x) {
                tokenId_part = tokenId.add(FIXEDNUMBRER);
            } else {
                tokenId_part = ++TokenId;
            }
            FinishHead[tokenId] = TokenIds.setTokenId(FinishHead[tokenId], x, tokenId_part);
            ComponentBitmap.setIdxAttr(PartMap, tokenId_part, x, attr);

            _safeMint(address(this), tokenId_part);
        }

        ClaimMap[tokenId] = true;
        emit Claim(tokenId, _msgSender(), TokenIds.getTokenIds(FinishHead[tokenId]));
    }

    function reallocate(uint256 tokenId) internal view returns (uint256) {
        uint256 parts;
        uint256 attr;
        for (uint256 x = 0; x < FIXEDCOUNT; x++) {
            if (uint(CannerType.Template) == x) attr = 100;
            if (uint(CannerType.Background) == x) attr = getBackground(tokenId);
            if (uint(CannerType.Eyes) == x) attr = getEyes(tokenId);
            if (uint(CannerType.Mouth) == x) attr = getMouth(tokenId);
            if (uint(CannerType.Body) == x) attr = getBody(tokenId);
            if (uint(CannerType.Top) == x) attr = getTop(tokenId);
            if (uint(CannerType.Straw) == x) attr = getStraw(tokenId);
            if (uint(CannerType.Gesture) == x) attr = getGesture(tokenId);
            if (attr == 0) continue;
            parts = AvatarBitmap.setAttr(parts, x, attr);
        }
        return parts;
    }

    function split(uint256 tokenId, address to) external nonReentrant {
        require(_msgSender() == ownerOf(tokenId), "Caller is not the owner");
        require(to != address(0), "To the zero address");
        uint256 metahead = FinishHead[tokenId];
        require(metahead > 0, "Token ID invalid");
        require(!TokenIds.getSeal(metahead), "Token ID is sealed");

        _transferFromBatch(metahead, to);

        delete FinishHead[tokenId];
        _burn(tokenId);

        emit Split(tokenId, to);
    }

    function merge(uint256 templateId, uint256[] calldata ids, address to) external nonReentrant {
        (, uint256 attr) = ComponentBitmap.getIdxAttr(PartMap, templateId);
        require(templateId > 10000 && templateId < 20001 && attr == 100, "Template Token ID invalid");

        uint256 tokenId = templateId.sub(FIXEDNUMBRER);
        _safeMint(to, tokenId);
        setCanner(tokenId, templateId, ids);

        emit Merge(templateId, ids, to);
    }

    function seal(uint256 tokenId) external {
        require(_msgSender() == ownerOf(tokenId), "Caller is not the owner");
        uint256 metaHead = FinishHead[tokenId];
        require(metaHead > 0, "Token ID abnormal");
        require(!TokenIds.getSeal(metaHead), "Token ID is sealed");
        FinishHead[tokenId] = TokenIds.setSeal(metaHead, true);

        emit Seal(tokenId);
    }

    function isSeal(uint256 tokenId) external view returns (bool) {
        uint256 metaHead = FinishHead[tokenId];
        return TokenIds.getSeal(metaHead);
    }

    function replace(uint256 tokenId, uint256[] calldata _headTokenIds) external nonReentrant {
        require(_msgSender() == ownerOf(tokenId), "Caller is not the owner");
        require(_headTokenIds.length > 0, "The headTokenIds length invalid");

        uint256 metaHead = FinishHead[tokenId];
        require(metaHead > 0, "Token ID abnormal");
        require(!TokenIds.getSeal(metaHead), "Token ID is sealed");

        for (uint256 x = 0; x < _headTokenIds.length; x++) {
            metaHead = FinishHead[tokenId];
            (uint256 index,) = ComponentBitmap.getIdxAttr(PartMap, _headTokenIds[x]);
            require(index > 0 && _headTokenIds[x] > 20000, "The Id abnormal");

            safeTransferFrom(_msgSender(), address(this), _headTokenIds[x]);

            uint256 tokenId_part = TokenIds.getTokenId(metaHead, index);
            if (tokenId_part > 0) {
                _safeTransfer(address(this), _msgSender(), tokenId_part, "");
            }
            FinishHead[tokenId] = TokenIds.setTokenId(metaHead, index, _headTokenIds[x]);
        }

        emit Replace(tokenId, _headTokenIds);
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");
        uint256 metaHead = FinishHead[tokenId];
        if (metaHead == 0) {
            (uint256 index, uint256 attr) = ComponentBitmap.getIdxAttr(PartMap, tokenId);
            return string(abi.encodePacked(baseURI_prefix, baseURI, template[index], sprit, attr.toString()));
        } else {
            return getFullTokenURI(tokenId, metaHead);
        }
    }

    function getFullTokenURI(uint256 tokenId, uint256 metaHead) internal view returns (string memory) {
        string[15] memory parts;
        parts[0] = '<svg width="100%" height="100%" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"><g><title>Mad Canner</title><image xlink:href="https://ipfs.io/ipfs/';
        parts[1] = getPartURI(metaHead, uint(CannerType.Background));
        parts[2] = '" id="svg_1" height="100%" width="100%" /><image xlink:href="https://ipfs.io/ipfs/';
        parts[3] = getPartURI(metaHead, uint(CannerType.Top));
        parts[4] = '" id="svg_1" height="100%" width="100%" /><image xlink:href="https://ipfs.io/ipfs/';
        parts[5] = getPartURI(metaHead, uint(CannerType.Straw));
        parts[6] = '" id="svg_1" height="100%" width="100%" /><image xlink:href="https://ipfs.io/ipfs/';
        parts[7] = getPartURI(metaHead, uint(CannerType.Body));
        parts[8] = '" id="svg_1" height="100%" width="100%" /><image xlink:href="https://ipfs.io/ipfs/';
        parts[9] = getPartURI(metaHead, uint(CannerType.Gesture));
        parts[10] = '" id="svg_1" height="100%" width="100%" /><image xlink:href="https://ipfs.io/ipfs/';
        parts[11] = getPartURI(metaHead, uint(CannerType.Mouth));
        parts[12] = '" id="svg_1" height="100%" width="100%" /><image xlink:href="https://ipfs.io/ipfs/';
        parts[13] = getPartURI(metaHead, uint(CannerType.Eyes));
        parts[14] = '" id="svg_1" height="100%" width="100%" /></g></svg>';

        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7]));
        output = string(abi.encodePacked(output, parts[8], parts[9], parts[10], parts[11], parts[12], parts[13], parts[14]));

        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Mad Canner #', tokenId.toString(),
            '", "description": "Mad Canner is the world first synthetic avatar collection of 10,000 unique NFTs created by Particle Protocol. Each Canner has 7 components: Background, Eyes, Mouth, Skin, Top, Straw and Gesture, and collectors can easily buy and sell parts in the marketplace and dress up their avatars.", "external_url": "www.particleprotocol.com", "image": "data:image/svg+xml;base64,',
            Base64.encode(bytes(output)), '", "attributes": ', getAttributes(metaHead), '}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));
        return output;
    }

    function getAttributes(uint256 metaHead) internal view returns (string memory) {
        string memory output = '[{"trait_type":"Template","value":"Canner"}';
        for (uint256 x = 1; x < FIXEDCOUNT; x++) {
            uint256 tokenId = TokenIds.getTokenId(metaHead, x);
            if (tokenId == 0) {
                output = string(abi.encodePacked(output, ',{"trait_type": "', template[x], '","value": "null"}'));
                continue;
            }
            (, uint256 attr) = ComponentBitmap.getIdxAttr(PartMap, tokenId);
            output = string(abi.encodePacked(output, ',{"trait_type": "', template[x], '","value": "', getPartAttr(x, attr), '"}'));
        }
        output = string(abi.encodePacked(output, ']'));
        return output;
    }

    function getPartAttr(uint256 index, uint256 attr) internal view returns (string memory) {
        if (uint(CannerType.Background) == index) return background[attr];
        if (uint(CannerType.Eyes) == index) return eyes[attr];
        if (uint(CannerType.Mouth) == index) return mouth[attr];
        if (uint(CannerType.Body) == index) return body[attr];
        if (uint(CannerType.Top) == index) return top[attr];
        if (uint(CannerType.Straw) == index) return straw[attr];
        if (uint(CannerType.Gesture) == index) return gesture[attr];
        return "";
    }

    function getPartURI(uint256 metaHead, uint256 index) internal view returns (string memory) {
        uint256 tokenId = TokenIds.getTokenId(metaHead, index);
        if (tokenId == 0) {
            return string(abi.encodePacked(baseURI_part, template[0], sprit, index.toString()));
        }
        (, uint256 attr) = ComponentBitmap.getIdxAttr(PartMap, tokenId);
        return string(abi.encodePacked(baseURI_part, template[index], sprit, attr.toString()));
    }

    function setCanner(uint256 tokenId, uint256 templateId, uint256[] memory ids) internal {
        require(ids.length > 0 && ids.length < FIXEDCOUNT, "The ids length invalid");

        safeTransferFrom(_msgSender(), address(this), templateId);
        FinishHead[tokenId] = TokenIds.setTokenId(FinishHead[tokenId], 0, templateId);

        uint256 record;
        for (uint256 x = 0; x < ids.length; x++) {
            require(ids[x] > 20000, "The ids invalid");
            (uint256 index, uint256 attr) = ComponentBitmap.getIdxAttr(PartMap, ids[x]);
            if (AvatarBitmap.getAttr(record, index) > 0) revert("Repeat types");
            record = AvatarBitmap.setAttr(record, index, attr);

            safeTransferFrom(_msgSender(), address(this), ids[x]);
            FinishHead[tokenId] = TokenIds.setTokenId(FinishHead[tokenId], index, ids[x]);
        }
    }

    function _transferFromBatch(uint256 metahead, address to) internal {
        uint256[8] memory tokenIds = TokenIds.getTokenIds(metahead);
        for (uint256 x = 0; x < tokenIds.length; x++) {
            if (tokenIds[x] > FIXEDNUMBRER) _safeTransfer(address(this), to, tokenIds[x], "");
        }
    }

    function getCanner(uint256 tokenId) external view returns (uint256[8] memory tokenIds, uint256[8] memory indexs, uint256[8] memory attrs) {
        uint256 metaHead = FinishHead[tokenId];
        if (metaHead == 0) {
            (uint256 index, uint256 attr) = ComponentBitmap.getIdxAttr(PartMap, tokenId);
            if (attr != 0) {
                tokenIds[0] = tokenId;
                indexs[0] = index;
                attrs[0] = attr;
            }
        } else {
            uint256[8] memory tokenIds_part = TokenIds.getTokenIds(metaHead);
            for (uint256 x = 0; x < tokenIds_part.length; x++) {
                indexs[x] = x;
                if (tokenIds_part[x] == 0) continue;
                tokenIds[x] = tokenIds_part[x];
                (, attrs[x]) = ComponentBitmap.getIdxAttr(PartMap, tokenIds_part[x]);
            }
        }
    }

    function withdraw() external onlyOwner {
        payable(_msgSender()).transfer(address(this).balance);

        emit Withdraw(_msgSender());
    }

    function setTimersLock(address _timers) external onlyOwner {
        timersLock = TimersLock(_timers);
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function charges() internal view returns (uint256) {
        if (CannerTotal < 2001) return Fee;
        return Fee * 2 ** ((CannerTotal - 1) / 2e03);
    }
}