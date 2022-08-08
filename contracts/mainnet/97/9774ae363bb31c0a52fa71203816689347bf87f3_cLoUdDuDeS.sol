/**
 *Submitted for verification at Etherscan.io on 2022-08-08
*/

/**
 *Submitted for verification at Etherscan.io on 2022-08-08
*/

// SPDX-License-Identifier: MIT

// CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS
//       CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS       CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS
// CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS       CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS
//       CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS       CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS
// CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS       CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS
//       CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS       CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS
// CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS       CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS
//       CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS       CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS
// CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS       CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS
//       CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS       CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS
// CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS       CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS
//       CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS       CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS
// CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS       CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS
//       CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS       CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS
// CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS       CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS
//       CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS       CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS
// CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS       CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS
//       CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS       CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS
//
//          Wow, hey Clouds!
// SOCIALS:
//   Cloudsite: https://clouddudesnft.com/
//   Twitter: https://twitter.com/CloudDudes_NFT
//   Instagram: https://www.instagram.com/clouddudesnft/
//   Cloudcord: https://discord.gg/rJk73yB3Ga
//===================================================================================================================

//GO TO Cloud World!



pragma solidity ^0.8.0;

// ############################################################
//                   STRING OPERATIONS
// ############################################################


library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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

// ############################################################
//                        CONTEXT
// ############################################################

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

// ############################################################
//                        ADDRESS
// ############################################################

pragma solidity ^0.8.0;

library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     *  CLOUD ALERT
     * ========================================================================
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
     * ========================================================================
     *
     * CLOUD ALERT
     * ========================================================================
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ========================================================================
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
        require(address(this).balance >= amount, "Address: There are not enough funds in the wallet!");

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
    function functionCall(
        address target, 
        
        bytes memory data) 
        
    internal returns (
        bytes memory
    ) 
    {
         return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(   address target,
    
    bytes memory data,
        
    string memory errorMessage
    ) 
    internal returns (bytes memory) {
        
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
    function functionCallWithValue(   address target,
        
        bytes memory data,
        
        uint256 value
    ) 
    internal returns (bytes memory) {
       
        return functionCallWithValue(target, data, value, "Address: low-level call with Value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(   address target,
        
        bytes memory data,
        
        uint256 value,
        
        string memory errorMessage
    ) 
    internal returns (bytes memory) {
        
        require(address(this).balance >= value, "Address: There are not enough funds in the wallet for call!");
        require(isContract(target), "Address: call to non-contract!");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target, 
        
        bytes memory data) 
        
        internal view returns (
        
        bytes memory)
         {
       
       return functionStaticCall(target, data, "Address: low-level Static Call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(   address target,
        
        bytes memory data,
        
        string memory errorMessage
    ) 
    internal view returns (bytes memory) {
        
        require(isContract(target), "Address: Static Call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target, 
        bytes memory data) 
        
        internal returns (
        bytes memory) {
        
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(   address target,
        
        bytes memory data,
        
        string memory errorMessage
    ) 
    internal returns (bytes memory) {
        
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
    function verifyCallResult(   bool success,
        
        bytes memory returndata,
        
        string memory errorMessage
    ) 
    internal pure returns (bytes memory) {
        
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



// ############################################################
//                 INTERFACE IERC721RECEIVER
// ############################################################

pragma solidity ^0.8.0;

interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(   address operator,   address from,   uint256 tokenId,
        
        bytes calldata data
    ) 
    external returns (bytes4);
}

// ############################################################
//                    INTERFACE IERC165
// ############################################################

pragma solidity ^0.8.0;

interface IERC165 {

    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// ############################################################
//                         ERC165
// ############################################################

pragma solidity ^0.8.0;

abstract contract ERC165 is IERC165 {
    
//@dev See {IERC165-supportsInterface}.
     
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// ############################################################
//                    INTERFACE IERC721
// ############################################################

pragma solidity ^0.8.0;

interface IERC721 is IERC165 {
   
    event Transfer(address indexed From, address indexed To, uint256 indexed tokenId);

   
    event Approval(address indexed Owner, address indexed Approved, uint256 indexed tokenId);


    event ApprovalForAll(address indexed Owner, address indexed Operator, bool Approved);

    function balanceOf(address Owner) external view returns (uint256 WalletBalance);

    
// @dev Returns the owner of the `tokenId` token.
   
    function ownerOf(uint256 tokenId) external view returns (address Owner);

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
    function safeTransferFrom(   address from,  address to,   uint256 tokenId,
        
        bytes calldata data
    ) 
    external;

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
    function safeTransferFrom(   address from,   address to,   uint256 tokenId
    ) 
    external;

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
    function transferFrom(   address from,   address to,   uint256 tokenId
    ) 
    external;

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
    function approve(address To, uint256 tokenId) external;

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
    function setApprovalForAll(address Operator, bool _Approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address Owner, address Operator) external view returns (bool);
}


// ############################################################
//                 INTERFACE IERC721ENUMERABLE
// ############################################################

pragma solidity ^0.8.0;


/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {

    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address Owner, uint256 Index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// ############################################################
//                INTERFACE IERC721METADATA
// ############################################################

pragma solidity ^0.8.0;


/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    
    function name() external view returns (string memory);

   
    function symbol() external view returns (string memory);


    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// ############################################################
//                     CONTRACT ERC721
// ############################################################

pragma solidity ^0.8.0;

contract ERC721A is Context, ERC165, IERC721, IERC721Metadata, IERC721Enumerable {
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

    uint256 internal currentIndex = 1;

// ############################################################
//                       ABOUT TOKEN
// ############################################################
   

    string private _name;

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

    constructor(
        string memory name_, 
        string memory symbol_) {
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
    function tokenByIndex(uint256 Index) public view override returns (uint256) {
        require(Index < totalSupply(), "ERC721A ERROR! The index cannot be larger than the Total Supply! LOL 0-0!");
        return Index;
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     * This read function is O(totalSupply). If calling from a separate contract, be sure to test gas first.
     * It may also degrade with extremely large collection sizes (e.g >> 10000), test for your use case.
     */
    function tokenOfOwnerByIndex(address Owner, uint256 Index) public view override returns (uint256) {
        require(Index < balanceOf(Owner), "ERC721A ERROR! Owner index out of bounds! LOL 0-0!");
        uint256 numMintedSoFar = totalSupply();
        uint256 tokenIdsIdx;
        address OwnersAddressNow;

        unchecked {
            for (uint256 i; i < numMintedSoFar; i++) {
                TokenOwnership memory ownership = _ownerships[i];
                if (ownership.addr != address(0)) {
                    OwnersAddressNow = ownership.addr;
                }
                if (OwnersAddressNow == Owner) {
                    if (tokenIdsIdx == Index) {
                        return i;
                    }
                    tokenIdsIdx++;
                }
            }
        }

        revert("ERC721A ERROR! Unable to get Cloud Token of owner by index! LOL 0-0!");
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC721Enumerable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */

    function balanceOf(address Owner) public view override returns (uint256) {
        require(Owner != address(0), "ERC721A ERROR! Balance query for the zero address! LOL 0-0!");
        return uint256(_addressData[Owner].balance);
    }

    function _numberMinted(address Owner) internal view returns (uint256) {
        require(Owner != address(0), "ERC721A ERROR! Number minted query for the zero address! LOL 0-0!");
        return uint256(_addressData[Owner].numberMinted);
    }

    function ownershipOf(uint256 tokenId) internal view returns (TokenOwnership memory) {
        require(_exists(tokenId), "ERC721A ERROR! Owner query for nonexistent token! LOL 0-0!");

        unchecked {
            for (uint256 CloudCurr = tokenId; CloudCurr >= 0; CloudCurr--) {
                TokenOwnership memory ownership = _ownerships[CloudCurr];
                if (ownership.addr != address(0)) {
                    return ownership;
                }
            }
        }

        revert("ERC721A ERROR! Unable to determine the Owner of Cloud Token! LOL 0-0!");
    }

// ############################################################
//                      SOME FUNCTIONS 
// ############################################################

    function ownerOf(uint256 tokenId) public view override returns (address) {
        return ownershipOf(tokenId).addr;
    }


    function name() public view virtual override returns (string memory) {
        return _name;
    }


    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

// ############################################################
//            METADATA and TOKEN URI and BASE URI
// ############################################################

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent Cloud Token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
 
    function _baseURI() internal view virtual returns (string memory) {
        return '';
    }

// ############################################################
//                           APPROVE
// ############################################################

    function approve(address To, uint256 tokenId) public override {
        address CloudOwner = ERC721A.ownerOf(tokenId);
        require(To != CloudOwner, "ERC721A ERROR! Approval to current Cloud Owner! LOL 0-0!");

        require(
            _msgSender() == CloudOwner || isApprovedForAll(CloudOwner, _msgSender()),
            "ERC721A: ERROR! Approve caller is not Cloud Owner nor approved for all! LOL 0-0!"
        );

        _approve(To, tokenId, CloudOwner);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view override returns (address) {
        require(_exists(tokenId), "ERC721A: ERROR! Approved query for nonexistent Cloud Token! LOL 0-0!");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address CloudOperator, bool Approved) public override {
        require(CloudOperator != _msgSender(), 'ERC721A: approve to caller');

        _operatorApprovals[_msgSender()][CloudOperator] = Approved;
        emit ApprovalForAll(_msgSender(), CloudOperator, Approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address CloudOwner, address CloudOperator) public view virtual override returns (bool) {
        return _operatorApprovals[CloudOwner][CloudOperator];
    }

// ############################################################
//                         TRANSFERS
// ############################################################
   
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

// ############################################################
//                           MINT
// ############################################################
    
    function _exists(uint256 tokenId) internal view returns (bool) {
        return tokenId < currentIndex;
    }

    function _safeMint(address to, uint256 QuantityClouds) internal {
        _safeMint(to, QuantityClouds, '');
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
        uint256 QuantityClouds,
        bytes memory _data
    ) internal {
        _mint(to, QuantityClouds, _data, true);
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
        uint256 QuantityClouds,
        bytes memory _data,
        bool safe
    ) internal {
        uint256 startTokenId = currentIndex;
        require(to != address(0), "ERC721A: ERROR! Mint to the zero address! LOL 0-0!");
        require(QuantityClouds != 0, "ERC721A: ERROR! Quantity Clouds must be greater than 0! LOL 0-0!");

        _beforeTokenTransfers(address(0), to, startTokenId, QuantityClouds);

        // Overflows are incredibly unrealistic.
        // balance or numberMinted overflow if current value of either + quantity > 3.4e38 (2**128) - 1
        // updatedIndex overflows if currentIndex + quantity > 1.56e77 (2**256) - 1
        unchecked {
            _addressData[to].balance += uint128(QuantityClouds);
            _addressData[to].numberMinted += uint128(QuantityClouds);

            _ownerships[startTokenId].addr = to;
            _ownerships[startTokenId].startTimestamp = uint64(block.timestamp);

            uint256 updatedIndex = startTokenId;

            for (uint256 i; i < QuantityClouds; i++) {
                emit Transfer(address(0), to, updatedIndex);
                if (safe) {
                    require(
                        _checkOnERC721Received(address(0), to, updatedIndex, _data),
                        "ERC721A: ERROR! transfer to non ERC721Receiver implementer!"
                    );
                }

                updatedIndex++;
            }

            currentIndex = updatedIndex;
        }

        _afterTokenTransfers(address(0), to, startTokenId, QuantityClouds);
    }

// ############################################################
//                    SOME FUNCTIONS
// ############################################################
  
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) private {
        TokenOwnership memory prevOwnership = ownershipOf(tokenId);

        bool isApprovedOrOwner = (_msgSender() == prevOwnership.addr ||
            getApproved(tokenId) == _msgSender() ||
            isApprovedForAll(prevOwnership.addr, _msgSender()));

        require(isApprovedOrOwner, "ERC721A: ERROR! transfer caller is not owner nor approved!");

        require(prevOwnership.addr == from, "ERC721A: ERROR! transfer from incorrect owner!");
        require(to != address(0), "ERC721A: ERROR! transfer to the zero address!");

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
                    _ownerships[nextTokenId].startTimestamp = prevOwnership.startTimestamp;
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
        address ClodOwner
    ) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(ClodOwner, to, tokenId);
    }

// ############################################################
//                CHECK ON ERC721 RECEIVED
// ############################################################
    
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
                    revert('ERC721A: transfer to non ERC721Receiver implementer');
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

// ############################################################
//                   CLOUD TOKEN TRANSFERS
// ############################################################
    
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
//BEFORE
    function _beforeTokenTransfers(   address from,   address to,   uint256 startTokenId,   uint256 QuantityClouds
    ) 
    internal virtual {}

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
//AFTER
    function _afterTokenTransfers(   address from,   address to,   uint256 startTokenId,   uint256 quantity
    ) 
    internal virtual {}
}

// ############################################################
//                        PAUSABLE
// ############################################################


pragma solidity ^0.8.0;

abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address CloudAccount);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address CloudAccount);

     bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() private view returns (bool) {
        return _paused;
    }

// WHEN NOT PAUSED
   
   modifier ContractNotPaused() {
        require(!paused(), "Pausable: paused - yes!");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier ContractPaused() {
        require(paused(), "Pausable: paused - no!");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual ContractNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual ContractPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// ############################################################
//                         OWNABLE
// ############################################################

pragma solidity ^0.8.0;

abstract contract Ownable is Context {
    address private _ContractOwner;

    event OwnershipTransferred(   address indexed nowOwner,   address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function CloudOwner() public view virtual returns (address) {
        return  _ContractOwner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(CloudOwner() == _msgSender(), "Ownable: ERROR! caller is not the Contract Owner!");
        _;
    }

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
            "Ownable: ERROR! new Contract Owner is the zero address!"
        );
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner =  _ContractOwner;
         _ContractOwner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

pragma solidity ^0.8.0;

// ############################################################
//                     REENTRANCY GUARD
// ############################################################

//@dev Contract module that helps prevent reentrant calls to a function.
 
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

// ############################################################
//                         CONRACT 
// ############################################################

pragma solidity ^0.8.0;

contract cLoUdDuDeS is ERC721A, Ownable, Pausable, ReentrancyGuard {
    using Strings for uint256;
    string public baseURI;
    uint256 public maxSupplyClouds = 10010;
    uint256 public FreeSupplyClouds = 2000;
    uint256 public MaxCloudsPerAddress = 11;
    uint256 public MaxCloudsPerAddrFree = 1;
    uint256 public CloudPrice = 0.0095 ether;
    bool private IsMintingONReverse = false;
    bool private IsFreeMintingONReverse = false;
    uint256 public FreeCloudsPerAddress = 1;
    bool public Contractpaused = false;

    bool public isMintedSuspend;


    mapping(address => uint256) public HowManyCloudsOnAddress;
    mapping(address => bool) private freeMinted;
 
    constructor () ERC721A("cLoUd DuDeS NfT CoMmUnItY", "CDNC") {
        _safeMint(msg.sender, 99);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function CloudDonate() external payable {
        // Thank you, Mate! ;)
    }
    
    modifier isNotContract() {
        require(tx.origin == msg.sender,"OOPSS! Contract is not allowed to operate! LOL 0-0");
        _;
    }

    modifier notMintSuspend(){
        require(!isMintedSuspend, "Cloud Free Mint has been suspended!");
        _;
    }

        modifier FreeMintClouds(uint256 numberOfTokens) {
        require(numberOfTokens > 0,"Mint count must be greater than 0!");
        require(
            totalSupply() + numberOfTokens <=
                maxSupplyClouds,
            "Too much Clouds! 0-0"
        );
        _;
    }

    function CloudFreeMint()
    external
    nonReentrant
    isNotContract
    notMintSuspend
    FreeMintClouds(MaxCloudsPerAddrFree)
    {
        require(!IsFreeMintingONReverse, "Cloud Free minting paused, more in Twitter! 0-0");
        require(totalSupply() + MaxCloudsPerAddrFree <= FreeSupplyClouds,"Exceed maximum free mint quantity.");
        require(!freeMinted[msg.sender],"You have mint best by free,please try other mint method.");
        freeMinted[msg.sender] = true;

        _safeMint(msg.sender,MaxCloudsPerAddrFree);
    }

    function CloudMint(uint256 _CloudsAmount) public payable nonReentrant {
        
        
        uint256 AllCloudsSupply = totalSupply();
        require(!IsMintingONReverse, "Cloud minting paused, more in Twitter! 0-0");

        require(_CloudsAmount > 0, "You can't mint 0 Clouds! LOL 0-0!");
        require(_CloudsAmount <= MaxCloudsPerAddress, "You can't mint more Clouds than Clouds Per Address! LOL 0-0!" );
        require(AllCloudsSupply + _CloudsAmount <= maxSupplyClouds, "You can't exceed Clouds supply! LOL 0-0!");
        require(msg.value >= CloudPrice * _CloudsAmount, "Check the Cloud Price - calculate correctly! LOL 0-0! ");
        require(msg.value >= _CloudsAmount * CloudPrice, "Check the Cloud Price - calculate correctly! LOL 0-0! x2");
        _safeMint(msg.sender, _CloudsAmount);
        delete AllCloudsSupply;
 }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked("https://ipfs.io/ipfs/QmSS1YP2yNg8yTw5PKvdJT8PbNmpLa2TriXR5RTV5rrsmz/", tokenId.toString(), ".json"));
    } 

// ############################################################
//                        ONLY OWNER 
// ############################################################

    function setPaused(bool _state) public onlyOwner {
        Contractpaused = _state;
    }

    function setMintingON(bool _State) public onlyOwner {
        IsMintingONReverse = _State;
    }

    function setFreeMintingONReverse(bool _Sstate) public onlyOwner {
        IsMintingONReverse = _Sstate;
    }

    function setPriceClouds(uint256 _newPriceCloud) public onlyOwner {
        CloudPrice = _newPriceCloud;
    }

    function SetMaxClouds(uint256 _NewMaxClouds) public onlyOwner {
        require(_NewMaxClouds <= maxSupplyClouds, "Cannot increase Max Clouds Supply! LOL 0-0!");
        maxSupplyClouds = _NewMaxClouds;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function SetMaxCloudsPerPublicMint(uint256 _AmountCloud) public onlyOwner {
        MaxCloudsPerAddress = _AmountCloud;
    }

    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }
}

// CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS
//       CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS       CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS
// CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS       CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS
//       CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS       CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS
// CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS       CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS
//       CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS       CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS
// CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS       CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS
//       CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS       CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS
// CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS       CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS
//       CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS       CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS
// CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS       CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS
//       CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS       CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS
// CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS       CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS
//       CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS       CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS
// CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS       CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS
//       CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS       CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS
// CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS       CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS
//       CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS       CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS
// CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS       CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS
//       CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS       CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS
// CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS       CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS
//       CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS       CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS
// CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS       CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS
//       CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS       CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS
// CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS       CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS
//       CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS       CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS      CLOUDS