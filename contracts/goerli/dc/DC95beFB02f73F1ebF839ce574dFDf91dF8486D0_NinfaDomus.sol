/*----------------------------------------------------------*|
|*          ███    ██ ██ ███    ██ ███████  █████           *|
|*          ████   ██ ██ ████   ██ ██      ██   ██          *|
|*          ██ ██  ██ ██ ██ ██  ██ █████   ███████          *|
|*          ██  ██ ██ ██ ██  ██ ██ ██      ██   ██          *|
|*          ██   ████ ██ ██   ████ ██      ██   ██          *|
|*----------------------------------------------------------*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../extensions/ERC721Enumerable.sol";
import "../extensions/ERC721URIStorage.sol";
import "../extensions/ERC721Burnable.sol";
import "../extensions/ERC721LazyMintableCommunal.sol";
import "../extensions/ERC721Royalty.sol";
import "../../../access/AccessControl.sol";

/*************************************************************
 * @title ERC721Communal                                     *
 *                                                           *
 * @notice Communal/shared ERC-721 minter preset             *
 *                                                           *
 * @dev {ERC721} token                                       *
 *                                                           *
 * @custom:security-contact [email protected]                    *
 ************************************************************/

contract NinfaDomus is
    ERC721Enumerable,
    ERC721Burnable,
    ERC721URIStorage,
    ERC721LazyMintableCommunal,
    ERC721Royalty,
    AccessControl
{
    /*----------------------------------------------------------*|
    |*  # ACCESS CONTROL                                        *|
    |*----------------------------------------------------------*/

    bytes32 internal constant MINTER_ROLE =
        0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6; // keccak256("MINTER_ROLE"); one or more smart contracts allowed to call the mint function, eg. the Marketplace contract
    bytes32 internal constant CURATOR_ROLE =
        0x850d585eb7f024ccee5e68e55f2c26cc72e1e6ee456acf62135757a5eb9d4a10; // keccak256("CURATOR_ROLE")

    /*----------------------------------------------------------*|
    |*  # PRIMARY MARKET FEES                                   *|
    |*----------------------------------------------------------*/
    /// @dev optional market fees for lazy minting (primary sales) on communal/shared collections

    uint24 private _feeBps;
    address private _feeRecipient;

    /*----------------------------------------------------------*|
    |*  # MINTING                                               *|
    |*----------------------------------------------------------*/

    function lazyMint(
        Voucher calldata _voucher,
        bytes calldata _signature,
        bytes calldata _data,
        address _to
    ) external payable {
        uint256 sellerAmount = _voucher.price;

        require(msg.value == sellerAmount);

        uint256 tokenId = _owners.length;

        /*----------------------------------------------------------*|
        |*  # PAY PRIMARY MARKET FEES                               *|
        |*----------------------------------------------------------*/
        /**
         * @dev primary market fees MUST be paid before calling lazyMint
         *       in order to subtract the fee amount from the seller amount first
         * @dev it is assumed that there is always a market fee higher than 0, therefore an `if` check has been omitted
         */
        uint256 feeAmount = (msg.value * _feeBps) / 10000;
        sellerAmount -= feeAmount;
        _sendValue(_feeRecipient, feeAmount);

        /*----------------------------------------------------------*|
        |*  # LAZY MINTING                                          *|
        |*----------------------------------------------------------*/

        address signer = _lazyMint(
            _voucher,
            _signature,
            _data,
            _to,
            tokenId,
            sellerAmount
        );

        require(hasRole(MINTER_ROLE, signer));

        /*----------------------------------------------------------*|
        |*  # ERC-721 EXTENSIONS                                    *|
        |*----------------------------------------------------------*/

        _setTokenURI(tokenId, _voucher.tokenURI);

        _setRoyaltyRecipient(signer, tokenId);

    }

    /*----------------------------------------------------------*|
    |*  # BURN OVERRIDE                                         *|
    |*----------------------------------------------------------*/

    /**
     * @dev required override by Solidity
     */
    function _burn(
        uint256 tokenId
    ) internal override(ERC721, ERC721Royalty, ERC721URIStorage) {
        
        super._burn(tokenId);
    }

    /*----------------------------------------------------------*|
    |*  # ADMIN FUNCTIONS                                       *|
    |*----------------------------------------------------------*/

    function setPrimaryFeeBps(
        uint24 feeBps_
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _feeBps = feeBps_;
    }

    function setFeeAccount(
        address feeRecipient_
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _feeRecipient = feeRecipient_;
    }

    /*----------------------------------------------------------*|
    |*  # VIEW FUNCTIONS                                        *|
    |*----------------------------------------------------------*/

    /**
     * @dev same function interface as erc1155, so that external contracts, i.e. the marketplace, can check either erc without requiring an if/else statement
     */
    function exists(uint256 _id) external view returns (bool) {
        return _owners[_id] != address(0);
    }

    /*----------------------------------------------------------*|
    |*  # ERC-165                                               *|
    |*----------------------------------------------------------*/

    /**
     * @dev See {IERC165-supportsInterface}.
     * @dev hardcoded interface IDs in order to save gas to callers.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) external pure returns (bool) {
        return
            interfaceId == 0x80ac58cd || // type(IERC721).interfaceId
            interfaceId == 0x780e9d63 || // type(IERC721Enumerable).interfaceId
            interfaceId == 0x01ffc9a7 || // type(IERC165).interfaceId
            interfaceId == 0x2a55205a || // type(IERC2981).interfaceId
            interfaceId == 0x7965db0b; // type(IAccessControl).interfaceId;
    }

    /*----------------------------------------------------------*|
    |*  # INITIALIZATION                                        *|
    |*----------------------------------------------------------*/

    /**
     * @notice creates `DOMAIN_SEPARATOR`,
     *      Grants `DEFAULT_ADMIN_ROLE` to the account that deploys the contract,
     *      assigns `CURATOR_ROLE` as the admin role for `MINTER_ROLE`,
     *      sets fee account address and fee BPS to 15% on primary market sales.
     * @param feeRecipient_ admin multisig contract for receiving market fees on sales.
     */
    constructor(
        string memory _eip712DomainName,
        string memory _symbol,
        address feeRecipient_,
        uint24 feeBps_
    ) ERC721LazyMintableCommunal(_eip712DomainName) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setRoleAdmin(MINTER_ROLE, CURATOR_ROLE);

        name = _eip712DomainName; // "Ninfa Domus"
        symbol = _symbol;

        _feeBps = feeBps_;
        _feeRecipient = feeRecipient_;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity 0.8.17;

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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

/// @dev stripped down version of https://github.com/MrChico/verifyIPFS/
library DecodeTokenURI {
    bytes constant ALPHABET =
        "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz";

    /**
     * @dev Converts hex string to base 58
     */
    function toBase58(bytes memory source)
        internal
        pure
        returns (bytes memory)
    {
        if (source.length == 0) return new bytes(0);
        uint8[] memory digits = new uint8[](64);
        digits[0] = 0;
        uint8 digitlength = 1;
        for (uint256 i = 0; i < source.length; ++i) {
            uint256 carry = uint8(source[i]);
            for (uint256 j = 0; j < digitlength; ++j) {
                carry += uint256(digits[j]) * 256;
                digits[j] = uint8(carry % 58);
                carry = carry / 58;
            }

            while (carry > 0) {
                digits[digitlength] = uint8(carry % 58);
                digitlength++;
                carry = carry / 58;
            }
        }
        return toAlphabet(reverse(truncate(digits, digitlength)));
    }

    function toAlphabet(uint8[] memory indices)
        private
        pure
        returns (bytes memory)
    {
        bytes memory output = new bytes(indices.length);
        for (uint256 i = 0; i < indices.length; i++) {
            output[i] = ALPHABET[indices[i]];
        }
        return output;
    }

    function truncate(uint8[] memory array, uint8 length)
        private
        pure
        returns (uint8[] memory)
    {
        uint8[] memory output = new uint8[](length);
        for (uint256 i = 0; i < length; i++) {
            output[i] = array[i];
        }
        return output;
    }

    function reverse(uint8[] memory input)
        private
        pure
        returns (uint8[] memory)
    {
        uint8[] memory output = new uint8[](input.length);
        for (uint256 i = 0; i < input.length; i++) {
            output[i] = input[input.length - 1 - i];
        }
        return output;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity 0.8.17;

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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
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
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return verifyCallResult(success, returndata, errorMessage);
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
                "Address: low-level static call failed"
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
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
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

/*----------------------------------------------------------*|
|*          ███    ██ ██ ███    ██ ███████  █████           *|
|*          ████   ██ ██ ████   ██ ██      ██   ██          *|
|*          ██ ██  ██ ██ ██ ██  ██ █████   ███████          *|
|*          ██  ██ ██ ██ ██  ██ ██ ██      ██   ██          *|
|*          ██   ████ ██ ██   ████ ██      ██   ██          *|
|*----------------------------------------------------------*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/*************************************************************
 * @title ERC2981Communal                                    *
 *                                                           *
 * @notice Adds ERC-2981 support to {ERC1155}                *
 *                                                           *
 * @dev {ERC2981} royalties for communal collections         *
 *                                                           *
 * @custom:security-contact [email protected]                    *
 ************************************************************/

 contract ERC2981Domus {
    /**
     * @notice `_royaltyRecipients` maps token ID to original artist, used for sending royalties to _royaltyRecipients on all secondary sales.
     *      This is meant for communal editions; in self-sovreign editions there is a single contract-wide royalty recipient
     * @dev "If you plan on having a contract where NFTs are created by multiple authors AND they can update royalty details after minting,
     *      you will need to record the original author of each token." - https://forum.openzeppelin.com/t/setting-erc2981/16065/2
     */
    mapping(uint256 => address) private _royaltyRecipients;
    /**
     * @dev `_minters`
     *      > "If you plan on having a contract where NFTs are created by multiple authors
     *      AND they can update royalty details after minting, you will need to record the original author of each token." - https://forum.openzeppelin.com/t/setting-erc2981/16065/2
     *      i.e. the original artist's address if different from the royalty recipient's address, MUST be stored in order to be used for access control on setter functions
     */
    mapping(uint256 => address) private _minters; // tokenId to original creator address
    /// @dev "For precision purposes, it's better to express the royalty percentage as "basis points" (points per 10_000, e.g., 10% = 1000 bps) and compute the amount is `(royaltyBps[_tokenId] * _salePrice) / 10000`" - https://forum.openzeppelin.com/t/setting-erc2981/16065/2
    uint24 internal constant ROYALTY_BPS = 1000; // 10% fixed royalties
    uint24 private constant TOTAL_SHARES = 10000; // 10,000 = 100% (total sale price)

    /**
     * @notice Called with the sale price to determine how much royalty
     *          is owed and to whom.
     * @param _tokenId - the NFT asset queried for royalty information
     * @param _salePrice - the sale price of the NFT asset specified by _tokenId
     * @return recipient - address of who should be sent the royalty payment
     * @return royaltyAmount - the royalty payment amount for _salePrice
     */
    function royaltyInfo(
        uint256 _tokenId,
        uint256 _salePrice
    ) external view returns (address recipient, uint256 royaltyAmount) {
        recipient = _royaltyRecipients[_tokenId];
        royaltyAmount = (_salePrice * ROYALTY_BPS) / TOTAL_SHARES;
    }

    /**
     * @notice This function is used when the artist decides to set the royalty recipient to an address other than its own.
     * It adds the artist address to the `_minters` mapping in {ERC2981Communal}, in order to use it for access control in `setRoyaltyRecipient()`. This removes the burden of setting this mapping in the `mint()` function as it will rarely be needed.
     * @param _royaltyRecipient (likely a payment splitter contract) may be 0x0 although it is not intended as ETH would be burnt if sent to 0x0. If the user only wants to mint it should call mint() instead, so that the roy
     *
     * Require:
     *
     * - If the `_minters` for `_tokenId` mapping is empty, the minter's address is equal to `_royaltyRecipients[_tokenId]`. I.e. the caller must correspond to `_royaltyRecipients[_tokenId]`, i.e. the token minter/artist
     * - Else, the caller must correspond to the `_tokenId`'s minter address set in `_minters[_tokenId]`, i.e. if `_minters[_tokenId]` is not 0x0. Note that the artist address cannot be reset.
     *
     * Allow:
     *
     * - the minter may (re)set `_royaltyRecipients[_tokenId]` to the same address as `_minters[_tokenId]`, i.e. the minter/artist. This would be quite useless, but not dangerous. The frontend should disallow it.
     *
     */
    function setRoyaltyRecipient(
        address _royaltyRecipient,
        uint256 _tokenId
    ) external {
        if (_minters[_tokenId] == address(0)) {
            require(msg.sender == _royaltyRecipients[_tokenId]); // require that the token has already been minted and that the caller is the minter
            _minters[_tokenId] = msg.sender;
        } else {
            require(msg.sender == _minters[_tokenId]);
        }

        _royaltyRecipients[_tokenId] =(_royaltyRecipient);
    }

    function _setRoyaltyRecipient(
        address _royaltyRecipient,
        uint256 _tokenId
    ) internal {
        _royaltyRecipients[_tokenId] = (_royaltyRecipient);
    }

    function _resetTokenRoyalty(uint256 _tokenId) internal {
        delete _royaltyRecipients[_tokenId];
        delete _minters[_tokenId];
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/extensions/ERC721URIStorage.sol)

pragma solidity 0.8.17;

import "../ERC721.sol";
import "../../../utils/DecodeTokenURI.sol";

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorage is ERC721 {
    using DecodeTokenURI for bytes;

    /**
     * @dev Hardcoded base URI in order to remove the need for a constructor, it can be set anytime by an admin (multisig).
     */
    string private _baseTokenURI = "ipfs://";

    /**
     * @dev Optional mapping for token URIs
     */
    mapping(uint256 => bytes32) private _tokenURIs;

    // using Strings for uint256;

    // // Optional mapping for token URIs
    // mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}. It needs to be overridden because the new OZ contracts concatenate _baseURI + tokenId instead of _baseURI + _tokenURI
     */
    function tokenURI(uint256 tokenId) external view returns (string memory) {
        require(_exists(tokenId), "ERC721: nonexistent token");

        return
            string( // once hex encoded base58 is converted to string, we get the initial IPFS hash
                abi.encodePacked(
                    _baseTokenURI,
                    abi
                    .encodePacked( // full bytes of base58 + hex encoded IPFS hash example.
                        bytes2(0x1220), // prepending 2 bytes IPFS hash identifier that was removed before storing the hash in order to fit in bytes32. 0x1220 is "Qm" base58 and hex encoded
                        _tokenURIs[tokenId] // tokenURI (IPFS hash) with its first 2 bytes truncated, base58 and hex encoded returned as bytes32
                    ).toBase58()
                )
            );
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     * @dev only called when a new token is minted, therefore `require(_exists(tokenId))` check was removed
     * Since Openzeppelin contracts v4.0 the _setTokenURI() function was removed, instead we must append the tokenID directly to this variable returned by _baseURI() internal function.
     * This contract implements all the required functionality from ERC721URIStorage, which is the OpenZeppelin extension for supporting _setTokenURI.
     * See https://forum.openzeppelin.com/t/why-doesnt-openzeppelin-erc721-contain-settokenuri/6373 and https://forum.openzeppelin.com/t/function-settokenuri-in-erc721-is-gone-with-pragma-0-8-0/5978/2
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, bytes32 _tokenURI) internal {
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @notice Optional function to set the base URI
     * @dev child contract MAY require access control to the external function implementation
     */
    function _setBaseURI(string calldata baseURI_) internal {
        // require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        _baseTokenURI = baseURI_;
    }

    /**
     * @dev See {ERC721-_burn}.
     */
    function _burn(uint256 _tokenId) internal virtual override {
        super._burn(_tokenId);

        delete _tokenURIs[_tokenId];
    }

    /**
     * @dev See {ERC721-_burn}. This override additionally checks to see if a
     * token-specific URI was set for the token, and if so, it deletes the token URI from
     * the storage mapping.
     */
    // function _burn(uint256 tokenId) internal virtual override {
    //     super._burn(tokenId);

    //     if (bytes(_tokenURIs[tokenId]).length != 0) {
    //         delete _tokenURIs[tokenId];
    //     }
    // }
}

/*----------------------------------------------------------*|
|*          ███    ██ ██ ███    ██ ███████  █████           *|
|*          ████   ██ ██ ████   ██ ██      ██   ██          *|
|*          ██ ██  ██ ██ ██ ██  ██ █████   ███████          *|
|*          ██  ██ ██ ██ ██  ██ ██ ██      ██   ██          *|
|*          ██   ████ ██ ██   ████ ██      ██   ██          *|
|*----------------------------------------------------------*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../ERC721.sol";
import "../../common/ERC2981Domus.sol";

/**
 * @dev Extension of ERC721 with the ERC2981 NFT Royalty Standard, a standardized way to retrieve royalty payment
 * information.
 */
abstract contract ERC721Royalty is ERC2981Domus, ERC721 {


    /**
     * @dev See {ERC721-_burn}. This override additionally clears the royalty information for the token.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);
        _resetTokenRoyalty(tokenId);
    }

}

/*----------------------------------------------------------*|
|*          ███    ██ ██ ███    ██ ███████  █████           *|
|*          ████   ██ ██ ████   ██ ██      ██   ██          *|
|*          ██ ██  ██ ██ ██ ██  ██ █████   ███████          *|
|*          ██  ██ ██ ██ ██  ██ ██ ██      ██   ██          *|
|*          ██   ████ ██ ██   ████ ██      ██   ██          *|
|*----------------------------------------------------------*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../ERC721.sol";

/// @custom:security-contact [email protected]
abstract contract ERC721LazyMintableCommunal is ERC721 {
    /*----------------------------------------------------------*|
    |*  # EIP-712                                               *|
    |*----------------------------------------------------------*/

    struct Voucher {
        bytes32 tokenURI;
        uint256 price;
        uint256 commissionBps;
        address commissionRecipient;
    }

    bytes32 private immutable DOMAIN_SEPARATOR;
    bytes32 private immutable DOMAIN_TYPEHASH;
    bytes32 private immutable VOUCHER_TYPEHASH;

    /*----------------------------------------------------------*|
    |*  # LAZY MINTING                                          *|
    |*----------------------------------------------------------*/

    mapping(bytes32 => bool) private _mintedURIs;

    /**
     * @param _to buyer, needed if using a external payment gateway, so that the minted tokenId value is sent to the address specified insead of `msg.sender`
     * @param _data data bytes are passed to `onErc1155Received` function if the `_to` address is a contract, for example a marketplace.
     *      `onErc1155Received` is not being called on the minter's address when a new tokenId is minted however, even if it was contract.
     * @dev Creates a new token for `msg.sender`. Its token ID will be automatically
     * assigned (and available on the emitted {IERC721-Transfer} event), and the token
     * URI autogenerated based on the base URI passed at construction.
     * See {ERC721-_mint}.
     *
     * Requirements:
     *
     * - the voucher signer must have the `MINTER_ROLE` role.
     * - access control must be set in derived contracts, e.g. `require(hasRole(MINTER_ROLE, signer)`
     * - extensions must be overridden in derived contract
     */
    function _lazyMint(
        Voucher calldata _voucher,
        bytes calldata _signature,
        bytes calldata _data,
        address _to,
        uint256 _tokenId,
        uint256 _sellerAmount
    ) internal returns (address _signer) {
        if (_mintedURIs[_voucher.tokenURI]) revert();

        /*----------------------------------------------------------*|
        |*  # EIP-712 TYPED DATA SIGNATURE VERIFICATION             *|
        |*----------------------------------------------------------*/

        _signer = _recover(_voucher, _signature);

        /*----------------------------------------------------------*|
        |*  # MINT & TRANSFER                                       *|
        |*----------------------------------------------------------*/
        _mintedURIs[_voucher.tokenURI] = true;

        _mintAndTransfer(_signer, _to, _tokenId, _data);

        /*----------------------------------------------------------*|
        |*  # PAY COMMISSIONS (if any)                              *|
        |*----------------------------------------------------------*/

        if (_voucher.commissionBps > 0) {
            uint256 commissionAmount = (msg.value * _voucher.commissionBps) /
                10000;
            _sellerAmount -= commissionAmount;
            _sendValue(_voucher.commissionRecipient, commissionAmount);
        }

        /*----------------------------------------------------------*|
        |*  # PAY SELLER                                            *|
        |*----------------------------------------------------------*/

        _sendValue(_signer, _sellerAmount);
    }

    function _recover(
        Voucher calldata _voucher,
        bytes memory _signature
    ) private view returns (address _signer) {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        VOUCHER_TYPEHASH,
                        _voucher.tokenURI,
                        _voucher.price,
                        _voucher.commissionBps,
                        _voucher.commissionRecipient
                    )
                )
            )
        );

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(_signature, 0x20))
            s := mload(add(_signature, 0x40))
            v := byte(0, mload(add(_signature, 0x60)))
        }

        _signer = ecrecover(digest, v, r, s);
        if (_signer == address(0)) revert();
    }

    function _sendValue(address _receiver, uint256 _amount) internal {
        (bool success, ) = payable(_receiver).call{value: _amount}("");
        require(success);
    }

    /**
     * @notice creates `DOMAIN_SEPARATOR`,
     *      Grants `DEFAULT_ADMIN_ROLE` to the account that deploys the contract,
     *      assigns `CURATOR_ROLE` as the admin role for `MINTER_ROLE`,
     */
    constructor(string memory _eip712DomainName) {
        DOMAIN_TYPEHASH = keccak256(
            "EIP712Domain(string name,uint256 chainId,address verifyingContract)"
        );
        VOUCHER_TYPEHASH = keccak256(
            "Voucher(bytes32 tokenURI,uint256 price,uint256 commissionBps,address commissionRecipient)"
        );
        /**
         * @dev The EIP712Domain fields should be the order as above, skipping any absent fields.
         *      Protocol designers only need to include the fields that make sense for their signing domain. Unused fields are left out of the struct type.
         * @param name the user readable name of signing domain, i.e. the name of the DApp or the protocol.
         * @param chainId the EIP-155 chain id. The user-agent should refuse signing if it does not match the currently active chain.
         * @param verifyingContract the address of the contract that will verify the signature. The user-agent may do contract specific phishing prevention.
         *      verifyingContract is the only variable parameter in the DOMAIN_SEPARATOR in order to avoid signature replay across different contracts
         *      therefore the DOMAIN_SEPARATOR MUST be calculated inside of the `initialize` function rather than the constructor.
         */
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes(_eip712DomainName)), // name
                block.chainid, // chainId
                address(this) // verifyingContract
            )
        );
    }
}

/*----------------------------------------------------------*|
|*          ███    ██ ██ ███    ██ ███████  █████           *|
|*          ████   ██ ██ ████   ██ ██      ██   ██          *|
|*          ██ ██  ██ ██ ██ ██  ██ █████   ███████          *|
|*          ██  ██ ██ ██ ██  ██ ██ ██      ██   ██          *|
|*          ██   ████ ██ ██   ████ ██      ██   ██          *|
|*----------------------------------------------------------*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../ERC721.sol";

/*************************************************************
 * @title ERC721Enumerable                                   *
 *                                                           *
 * @dev This implements an optional extension of {ERC721}    *
 *      defined in the EIP that adds enumerability of all    *
 *      the token ids in the contract as well as all token   *
 *      ids owned by each account.                           *
 *                                                           *
 * @custom:security-contact [email protected]                    *
 ************************************************************/
abstract contract ERC721Enumerable is ERC721 {
    function tokenOfOwnerByIndex(
        address _owner,
        uint256 _index
    ) external view returns (uint256) {
        require(_owner == ownerOf(_index));
        return _index;
    }

    /// @notice Count NFTs tracked by this contract
    /// @return A count of valid NFTs tracked by this contract, where each one of
    ///  them has an assigned and queryable owner not equal to the zero address
    function totalSupply() external view returns (uint256) {
        return _owners.length;
    }

    /// @notice Enumerate valid NFTs
    /// @dev Throws if `_index` >= `totalSupply()`.
    /// @param _index A counter less than `totalSupply()`
    /// @return The token identifier for the `_index`th NFT,
    ///  (sort order not specified)
    function tokenByIndex(uint256 _index) external view returns (uint256) {
        require(_exists(_index));
        return _index;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "../ERC721.sol";

/**
 * @title ERC721 Burnable Token
 * @dev ERC721 Token that can be burned (destroyed).
 */
abstract contract ERC721Burnable is ERC721 {
    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 _tokenId) external {
        require(_isApprovedOrOwner(msg.sender, _tokenId));
        _burn(_tokenId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./IERC721Receiver.sol";
import "../../utils/Address.sol";
import "../../utils/Strings.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 * @dev removed constructor in order to allow name and symbol to be set by facory clones contracts via the `initialize` function instead.
 *      name and symbol should be set in most derived contract's constructor instead
 */
contract ERC721 {
    using Address for address;
    using Strings for uint256;

    // Token name
    string public name;

    // Token symbol
    string public symbol;

    // array of token owners, accessed in {NinfaERC721-totalSupply}
    address[] internal _owners;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

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
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0));
        return owner;
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) external {
        address owner = ownerOf(tokenId);

        require(msg.sender == owner || _operatorApprovals[owner][msg.sender]);

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId));

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) external {
        _setApprovalForAll(msg.sender, operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(
        address owner,
        address operator
    ) external view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(msg.sender, tokenId));

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory _data
    ) public {
        require(_isApprovedOrOwner(msg.sender, _tokenId));
        _safeTransfer(_from, _to, _tokenId, _data);
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
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory _data
    ) private {
        _transfer(_from, _to, _tokenId);
        require(_checkOnERC721Received(_from, _to, _tokenId, _data));
    }

    /**
     * @dev Destroys `tokenId`.
     *      The approval is cleared when the token is burned.
     *      This is an internal function that does not check if the sender is authorized to operate on the token.
     *      Emits a {Transfer} event.
     * @param _tokenId MUST exist.
     */
    function _burn(uint256 _tokenId) internal virtual {
        // Clear approvals
        delete _tokenApprovals[_tokenId];

        delete _owners[_tokenId]; // equivalent to Openzeppelin's `_balances[owner] -= 1`

        emit Transfer(msg.sender, address(0), _tokenId);
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(
        address spender,
        uint256 tokenId
    ) internal view returns (bool) {
        require(_exists(tokenId));
        address owner = ownerOf(tokenId);
        return (spender == owner ||
            getApproved(tokenId) == spender ||
            _operatorApprovals[owner][spender]);
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`. Doesn't support safe transfers while minting, i.e. doesn't call onErc721Received function because when minting the receiver is msg.sender.
     * We don’t need to zero address check because msg.sender is never the zero address.
     * Because the tokenId is always incremented, we don’t need to check if the token exists already.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address _to, uint256 _tokenId) internal {
        _owners.push(_to);

        emit Transfer(address(0), _to, _tokenId);
    }

    /**
     * @dev rather than calling the internal `_mint` function which would create a new owner like so `_owners.push(_to)`,
     *      however ownership will be reassigned/overridden with the buyer's address by the time the `lazyMint` function has finished executing
     *      therefore the `transfer` event is emitted in order to signal to DApps that a mint has occurred
     */
    function _mintAndTransfer(
        address _minter,
        address _recipient,
        uint256 _tokenId,
        bytes calldata _data
    ) internal {
        /*----------------------------------------------------------*|
        |*  # MINT                                                  *|
        |*----------------------------------------------------------*/

        emit Transfer(address(0), _minter, _tokenId);

        /*----------------------------------------------------------*|
        |*  # SAFE TRANSFER                                         *|
        |*----------------------------------------------------------*/

        _owners.push(_recipient);

        emit Transfer(_minter, _recipient, _tokenId);

        require(_checkOnERC721Received(_minter, _recipient, _tokenId, _data));
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
    function _transfer(address from, address to, uint256 tokenId) private {
        require(ownerOf(tokenId) == from);
        require(to != address(0));

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 _tokenId) private {
        _tokenApprovals[_tokenId] = to;
        emit Approval(ownerOf(_tokenId), to, _tokenId);
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
    ) private {
        require(owner != operator);
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param _to target address that will receive the tokens
     * @param _from address representing the previous owner of the given token ID
     * @param _tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (_to.code.length > 0)
            return
                IERC721Receiver(_to).onERC721Received(
                    msg.sender, // operator
                    _from, // from
                    _tokenId,
                    _data
                ) == 0x150b7a02;
        // IERC721Receiver.onERC721Received.selector,
        else return true;
    }

    /**
     * @dev WARNING this function SHOULD only be called by frontends due to unbound loop
     * @dev public visibility as it is needed by
     */
    function balanceOf(address owner) public view returns (uint256) {
        uint256 count = 0;
        uint256 totalSypply = _owners.length;
        for (uint256 i; i < totalSypply; i++) {
            if (owner == _owners[i]) count++;
        }
        return count;
    }

    /**
     * @dev Hook that is called after any token transfer. This includes minting and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens were transferred to `to`.
     * - When `from` is zero, the tokens were minted for `to`.
     * - When `to` is zero, ``from``'s tokens were burned.
     * - `from` and `to` are never both zero.
     */
    function _afterTokenTransfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

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
abstract contract AccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(
        bytes32 role,
        bytes32 previousAdminRole,
        bytes32 newAdminRole
    );

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 role, address account, address sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 role, address account, address sender);

    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 internal constant DEFAULT_ADMIN_ROLE = 0x00;

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
        _checkRole(role, msg.sender);
        _;
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert("Account is missing role");
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
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
    function grantRole(
        bytes32 role,
        address account
    ) external onlyRole(getRoleAdmin(role)) {
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
    function revokeRole(
        bytes32 role,
        address account
    ) external onlyRole(getRoleAdmin(role)) {
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
    function renounceRole(bytes32 role, address account) external {
        require(account == msg.sender); // "AccessControl: can only renounce roles for self"

        _revokeRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, msg.sender);
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, msg.sender);
        }
    }
}