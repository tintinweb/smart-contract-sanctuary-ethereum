// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                         //
//                                                                                                                                                         //
//       .;dkkkkkkkkkkkkkkkkkkd'      .:xkkkkkkkkd,           .:dk0XXXXXXXK0xdl,.    .lxkkkkkkkkkkkkkkkkkk:.,okkkkkkko.    .cxkkkkkkxc.      ;dkkkkkko.    //
//      ;xNMMMMMMMMMMMMMMMMMMMX:    .:kNWMMMMMMMMWx.        .l0NWWWWWMMMMMMMMMWNO;..lKWMMMMMMMMMMMMMMMMMMMKkKWMMMMMMMK,  .c0WMMMMMMMMX:   .;xXWMMMMMNo.    //
//    .,lddddddddddddddddxKMMMK;   .,lddddddx0WMMMX;      .;llc::;;::cox0XWMMMMMWXdcoddddddddddddddddONMW0ddddddxXMMMK, .:odddddONMMMMO' .,lddddd0WWd.     //
//    ..                 .dWWKl.   .         :XMMMWx.    ...            .,oKWMMMMWx.                 ,KMNc      .kMMM0, ..      .xWMMMWx'.      'kNk.      //
//    ..                 .dKo'    ..         .xWMMMK;  ..       .'..       ,OWWMMWx.                 ,Okc'      .kMMMK,  ..      ,0MMMMXl.     .dNO'       //
//    ..      .:ooo;......,'      .           :XMMMWd. .      .l0XXOc.      ;xKMWNo.      ,looc'......'...      .kMMMK,   ..      cXMMM0,     .oNK;        //
//    ..      '0MMMk.            ..           .kWMMMK,.'      ;KMMMWNo.     .;kNkc,.     .dWMMK:        ..      .kMMMK,    ..     .dWMXc      cXK:         //
//    ..      '0MMMXkxxxxxxxxd'  .     .:.     cXMMMWd,'      '0MMMMM0l;;;;;;:c;. ..     .dWMMW0xxxxxxxxx;      .kMMMK,     ..     'ONd.     :KXc          //
//    ..      '0MMMMMMMMMMMMMNc ..     :O:     .kMMMMK:.       'd0NWMWWWWWWWNXOl'...     .dWMMMMMMMMMMMMWl      .kMMMK,      .      :d'     ;0No.          //
//    ..      .lkkkkkkkkkKWMMNc .     .dNd.     cNMMMWo..        .':dOXWMMMMMMMWXk:.      :xkkkkkkkk0NMMWl      .kMMMK,       .      .     'ONd.           //
//    ..                .oNMXd...     '0M0'     .kMMMM0, ..           .;o0NMMMMMMWx.                ,0MN0:      .kMMMK,       ..          .kW0'            //
//    ..                 cKk,  .      lNMNl      cNMMMNo  .',..          .;xXWMMMWx.                'O0c'.      .kMMMK,        ..        .xWMO.            //
//    ..      .,ccc,.....,,.  ..     .kMMMk.     .OMMMW0;'d0XX0xc,.         :d0MMWx.      ':cc:'....';. ..      .kMMMK,         ..      .oNMMO.            //
//    ..      '0MMMk.         ..     ,kKKKk'      lNMMMN0KWWWMMMWNKl.         cXMWx.     .dWMMX:        ..      .kMMMK,         ..      .OMMMO.            //
//    ..      '0MMMk'..........       .....       'OMMKo:::::cxNMMMKl'.       .OMWx.     .dWMMXc..........      .kMMMK:.........,'      .OMMMO.            //
//    ..      '0MMMNXKKKKKKKKd.                    lNM0'      ;XMMMWN0c       .OMWd.     .dWMMWXKKKKKKKK0c      .kMMMWXKKKKKKKKK0:      .OMMMO.            //
//    ..      'OWWWWWWWWWWMMNc      'llc'   .      '0MNc      .kWMMMMX:       ,KXx:.     .oNWWWWWWWWWWMMWl      .xWWWWWWWWWWWMMMN:      .OMMMO.            //
//    ..       ,:::::::::cOWO.     .xWWO'   .       oNMO'      .lkOOx;.     .'cd,...      .::::::::::dXMWl       '::::::::::xWMMX:      .OMMWx.            //
//    ..                  dNl      ,0Xd.    ..      ,0MNo.        .        ..'.   ..                 ,0WK:                  :NWOo,      .OWKo.             //
//    .'                 .oO,     .co,       ..     .oOc....             ...      ..                 ,xo,..                 ckl..'.     'dd'               //
//     .............................         ..........       .   ..   .          .....................  .....................   .........                 //
//                                                                                                                                                         //
//                                                                                                                                                         //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * The contracts below implement a lazy-minted, multi-directory metadata storage version of ERC721.
 * It gives the creator flexibility to mint singular hashes at a time or entire batches of tokens under
 * a single token directory -- commonly an IPFS hash. Batching tokens together saves an immense amount of gas,
 * but the owner of this collection gives up some control over the tokenIds exact numbering.
 *
 * Each batch that the owner releases gets offset by the batchSize because doing so makes it possible
 * to enable the same benefits as ERC721A across multiple different releases separately. This functionality
 * makes it cheap for the contract creator to mint hundres of tokens and allow their full collection to
 * be shown on places like opensea without needing to be bought out first.
 *
 * Note: This batch minting is reserved only for the contract creator and not for external buyers.
 *
 * It has two main methods to lazy-mint, one allows the owner to set a price for a singular token in an
 * existing batch or set a price for a single new tokenURI that will get added to this collection.
 */

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

error CallerNotOwner();
error OwnerNotZero();

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
    address internal _owner;

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
        if (owner() != _msgSender()) revert CallerNotOwner();
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
        if (newOwner == address(0)) revert OwnerNotZero();
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

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

error AlreadySetBatchSize();
error AlreadySetSeqMintLimit();
error ApprovalCallerNotOwnerNorApproved();
error ApproveToCaller();
error ApprovalToCurrentOwner();
error BalanceQueryForZeroAddress();
error InvalidBatchAmount();
error MintToZeroAddress();
error MintExistingToken();
error NotBatchDirectory();
error NotSequentiallyMintable();
error OverBatchTokenLimit();
error OverReleaseLimit();
error TransferCallerNotOwnerNorApproved();
error TransferFromIncorrectOwner();
error TransferToNonERC721ReceiverImplementer();
error TransferToZeroAddress();
error QueryForNonexistentToken();

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 *
 * It mainly follows the practice of ERC721A in order to better handle multi-mint transactions. 
 
 It has two layers of optimization:
 *
 * First, it assumes tokens are sequentially minted within each block (defaults to 0, e.g. 0, 1, 2, 3..)
 * which allows for up to 5 times cheaper MINT gas fees, but does increase first time TRANSFER gas fees.
 * Because of this, methods have also been optimized to only call ownerOf() once as it is not a direct lookup.
 *
 * Additionally assumes the following:
 * that no more than 2**64 - 1 (max value of uint64) tokens can be batch minted
 * that no more than 2**64 - 1 (max value of uint64) tokens can be individually minted
 * that no more than 2**64 - 1 (max value of uint64) tokens can be burned
 * that no owner can have more than 2**64 - 1 (max value of uint64) of supply. 
 */
contract ERC721B is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Compiler will pack this into a single 256bit word.
    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Keeps track of the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
    }

    // Compiler will pack this into a single 256bit word.
    struct AddressData {
        // Realistically, 2**64-1 is more than enough.
        uint64 balance;
        // Keeps track of mint count with minimal overhead for tokenomics.
        uint64 numberMinted;
        // Keeps track of burn count with minimal overhead for tokenomics.
        uint64 numberBurned;
        // For miscellaneous variable(s) pertaining to the address
        // (e.g. number of whitelist mint slots used).
        // If there are multiple variables, please pack them into a uint64.
        uint64 aux;
    }

    // Compiler will pack this into a single 256bit word.
    struct BatchData {
        // Tracks if tokens can still use the savings from being sequenitally mintable
        bool isSequentiallyMintable;
        // Tracks total tokens in this batch
        uint64 batchSize;
        // Tracks total tokens minted sequentially from the start of the batch
        uint64 sequentialMints;
    }

    // Token name
    string internal _name;

    // Token symbol
    string internal _symbol;

    // Token Base URI
    string private baseURI;

    // Compiler will pack these units below together into a 256bit section
    // This returns the id header of the next batch
    uint64 internal _nextBatchId;
    // Track total minted tokens
    uint64 internal _batchMintedCount;
    // Will let us mint all individual tokens in the same batch
    uint64 internal _individualTokenIdBase;
    // Will let us know when we need to update the token base
    uint64 internal _individualTokensCount;

    // Compiler will pack these units below together into a 256bit section
    // Tracking total burned
    uint64 internal _totalBurned;
    // This ensures that ownerOf() can still run in constant time with a max runtime
    // of checking X values, but is up to X times cheaper on batch mints.
    uint32 internal constant DEFAULT_SEQ_MINT_LIMIT = 5;
    uint32 internal constant MAX_SEQ_MINT_LIMIT = 10;
    uint32 public seqMintLimit;

    // This is used to be able to quickly query tokenURI and other metadata of a batch
    uint32 internal constant DEFAULT_BATCH_SIZE = 1000;
    uint32 internal constant MAX_BATCH_SIZE = 100000;
    uint32 public batchSize;

    // Mapping from token ID to owner address
    mapping(uint256 => TokenOwnership) internal _ownerships;

    // Mapping owner address to token count
    mapping(address => AddressData) internal _addressData;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Mapping from batch ID to related batch data
    mapping(uint256 => BatchData) private _batchIdToData;

    // Mapping from batchId to tokenDirectory data
    mapping(uint256 => string) public batchDirectories;

    // Mapping from tokenId to tokenURI for a individual token
    mapping(uint256 => string) private _individualTokenMetadata;

    event NameChanged(string name);
    event SymbolChanged(string symbol);
    event BaseURIChanged(string baseURI);
    event TokenDirectoryReleased(string tokenDirectory, uint256 amount);

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
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner)
        public
        view
        virtual
        override
        returns (uint256)
    {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        return _addressData[owner].balance;
    }

    /**
     * Sets the auxillary data for `owner`. (e.g. number of whitelist mint slots used).
     * If there are multiple variables, please pack them into a uint64.
     */
    function _setBatchSize(uint256 newBatchSize) internal {
        if (batchSize != 0) revert AlreadySetBatchSize();
        if (newBatchSize == 0) {
            batchSize = DEFAULT_BATCH_SIZE;
        } else if (newBatchSize > MAX_BATCH_SIZE) {
            batchSize = MAX_BATCH_SIZE;
        } else {
            batchSize = uint32(newBatchSize);
        }
    }

    /**
     * Sets the auxillary data for `owner`. (e.g. number of whitelist mint slots used).
     * If there are multiple variables, please pack them into a uint64.
     */
    function _setSeqMintLimit(uint256 newSeqMintLimit) internal {
        if (seqMintLimit != 0) revert AlreadySetSeqMintLimit();
        if (newSeqMintLimit == 0) {
            seqMintLimit = DEFAULT_SEQ_MINT_LIMIT;
        } else if (newSeqMintLimit > MAX_SEQ_MINT_LIMIT) {
            seqMintLimit = MAX_SEQ_MINT_LIMIT;
        } else {
            seqMintLimit = uint32(newSeqMintLimit);
        }
    }

    // returns the batch ID for a token ID
    function _getBatchId(uint256 tokenId) internal view returns (uint256) {
        return tokenId / batchSize;
    }

    // Returns the index of a token ID within a batch
    function _getBatchIndex(uint256 tokenId) internal view returns (uint256) {
        return tokenId % batchSize;
    }

    // returns if this batch is reserved for individual token IDs or not
    function _isIndividual(BatchData memory batchData)
        internal
        pure
        returns (bool)
    {
        return batchData.batchSize == 0;
    }

    /**
     * Returns the number of tokens minted by `owner`.
     */
    function _numberMinted(address owner) internal view returns (uint256) {
        return uint256(_addressData[owner].numberMinted);
    }

    /**
     * Returns the number of tokens burned by or on behalf of `owner`.
     */
    function _numberBurned(address owner) internal view returns (uint256) {
        return uint256(_addressData[owner].numberBurned);
    }

    /**
     * Returns the auxillary data for `owner`. (e.g. number of whitelist mint slots used).
     */
    function _getAux(address owner) internal view returns (uint64) {
        return _addressData[owner].aux;
    }

    /**
     * Sets the auxillary data for `owner`. (e.g. number of whitelist mint slots used).
     * If there are multiple variables, please pack them into a uint64.
     */
    function _setAux(address owner, uint64 aux) internal {
        _addressData[owner].aux = aux;
    }

    /**
     * Updates the token name
     */
    function _setTokenName(string memory name_) internal {
        if (bytes(name_).length == 0) return;
        _name = name_;
        emit NameChanged(name_);
    }

    /**
     * Updates the token symbol
     */
    function _setTokenSymbol(string memory symbol_) internal {
        if (bytes(symbol_).length == 0) return;
        _symbol = symbol_;
        emit SymbolChanged(symbol_);
    }

    /**
     * Updates the base URI of the tokens
     */
    function _setBaseURI(string memory uri) internal {
        if (bytes(uri).length == 0) return;
        baseURI = uri;
        emit BaseURIChanged(uri);
    }

    /**
     * @dev adds another batch of NFTs that are all defined under the same token directory
     */
    function _addTokenDirectory(string memory tokenDirectory, uint256 amount)
        internal
    {
        if (amount > batchSize) revert OverReleaseLimit();

        batchDirectories[_nextBatchId] = tokenDirectory;
        _batchIdToData[_nextBatchId] = BatchData({
            isSequentiallyMintable: true,
            batchSize: uint64(amount),
            sequentialMints: 0
        });
        _nextBatchId += 1;
        emit TokenDirectoryReleased(tokenDirectory, amount);
    }

    /**
     * Returns a struct with the following information about a tokenId
     * 1. The address of the latest owner
     * 2. The timestamp of the latest transfer
     * 3. Whether or not the token was burned
     */
    function getOwnershipData(uint256 tokenId)
        external
        view
        returns (TokenOwnership memory)
    {
        return _ownershipOf(tokenId);
    }

    /**
     * Returns a struct with the following information about an address
     * 1. The balance of the address
     * 2. The number of tokens minted by the address
     * 3. The number of tokens burned by the address
     * 4. Any auxillary information stored in implementing contracts.
     */
    function getAddressData(address addr)
        external
        view
        returns (AddressData memory)
    {
        return _addressData[addr];
    }

    /**
     * Returns a struct with the following information about an address
     * 1. Is the batch still sequentially mintable and utilize 721A gas savings
     * 2. How make tokens are part of the batch
     * 3. How many tokens have been sequentially minted from this batch
     */
    function getBatchData(uint256 batchId)
        external
        view
        returns (BatchData memory)
    {
        return _batchIdToData[batchId];
    }

    /**
     * Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around in the collection over time.
     */
    function _ownershipOf(uint256 tokenId)
        internal
        view
        returns (TokenOwnership memory)
    {
        if (!_exists(tokenId)) revert QueryForNonexistentToken();

        uint256 curr = tokenId;
        TokenOwnership memory ownership = _ownerships[curr];
        // Invariant:
        // There will always be an ownership that has an address and is not burned
        // before an ownership that does not have an address and is not burned.
        // Hence, curr will not underflow.
        unchecked {
            while (true) {
                // Individual tokens will also return true here on the first loop
                if (ownership.addr != address(0)) {
                    return ownership;
                }
                curr--;
                ownership = _ownerships[curr];
            }
        }
        revert QueryForNonexistentToken();
    }

    /**
     * Gets the URI of the token based off of if it is part of a batch Directory
     * or if it is party of an individual token
     */
    function _getTokenURI(uint256 tokenId)
        internal
        view
        returns (string memory)
    {
        string memory uri = _baseURI();
        uint256 batchId = _getBatchId(tokenId);
        BatchData memory batchData = _batchIdToData[batchId];

        if (_isIndividual(batchData)) {
            return
                string(
                    abi.encodePacked(uri, _individualTokenMetadata[tokenId])
                );
        } else {
            return
                string(
                    abi.encodePacked(
                        uri,
                        batchDirectories[batchId],
                        "/",
                        (_getBatchIndex(tokenId)).toString()
                    )
                );
        }
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        return _ownershipOf(tokenId).addr;
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
        if (!_exists(tokenId)) revert QueryForNonexistentToken();
        return _getTokenURI(tokenId);
    }

    /**
     * @dev Returns the total current supply of the contract.
     */
    function totalSupply() public view virtual returns (uint256) {
        return _batchMintedCount + _individualTokensCount - _totalBurned;
    }

    /**
     * @dev Returns the total burned tokens from the contract.
     */
    function totalBurned() public view virtual returns (uint256) {
        return _totalBurned;
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return baseURI;
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        if (to == owner) revert ApprovalToCurrentOwner();
        if (_msgSender() != owner && !isApprovedForAll(owner, _msgSender())) {
            revert ApprovalCallerNotOwnerNorApproved();
        }

        _approve(to, tokenId, owner);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        if (!_exists(tokenId)) revert QueryForNonexistentToken();

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        if (operator == _msgSender()) revert ApproveToCaller();

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
    ) public virtual override {
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
        if (!_checkOnERC721Received(from, to, tokenId, _data)) {
            revert TransferToNonERC721ReceiverImplementer();
        }
    }

    /**
     * @dev This is for functions which already get the ownership of the tokenId because ownerOf() in 721A
     * is potentially an expensive function and should not be called twice if not needed to save gas.
     *
     * WARNING this internal method expects to get passed in the TokenOwnership of the tokenId and will not
     * verify if it really is. It also ignores checking the owner so tokens can be loanable
     */
    function _safeTransferWithOwnershipData(
        TokenOwnership memory tokenOwnership,
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transferWithOwnershipData(tokenOwnership, from, to, tokenId);
        if (!_checkOnERC721Received(from, to, tokenId, _data)) {
            revert TransferToNonERC721ReceiverImplementer();
        }
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
        if (_ownerships[tokenId].burned) return false;
        // Individual tokens will always return true here once minted
        if (_ownerships[tokenId].addr != address(0)) return true;

        // to save gas on multi-mints, _ownerships is not set on every batch mint token
        return _withinABatch(tokenId);
    }

    /**
     * @dev Returns whether a tokenId is part of a batch or has an individual URI
     */
    function _withinABatch(uint256 tokenId) internal view returns (bool) {
        return
            _batchIdToData[_getBatchId(tokenId)].sequentialMints >
            _getBatchIndex(tokenId);
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
        uint256 tokenId,
        address owner
    ) internal view virtual returns (bool) {
        if (!_exists(tokenId)) revert QueryForNonexistentToken();
        return (spender == owner ||
            getApproved(tokenId) == spender ||
            isApprovedForAll(owner, spender));
    }

    /**
     * @dev adds another batch of NFTs that are all defined under the same token directory
     */
    function _addTokenDirectoryRelease(
        string memory releaseTokenDirectory,
        uint256 releaseAmount
    ) internal {
        if (releaseAmount > batchSize) revert OverReleaseLimit();

        batchDirectories[_nextBatchId] = releaseTokenDirectory;
        _batchIdToData[_nextBatchId] = BatchData({
            isSequentiallyMintable: true,
            batchSize: uint64(releaseAmount),
            sequentialMints: 0
        });
        _nextBatchId += 1;
        emit TokenDirectoryReleased(releaseTokenDirectory, releaseAmount);
    }

    /**
     * @dev allows updating of the token metadata
     */
    function _updateTokenDirectory(
        string memory newTokenDirectory,
        uint256 identifier,
        bool isBatch
    ) internal {
        if (isBatch) {
            if (_batchIdToData[identifier].batchSize == 0) {
                revert NotBatchDirectory();
            }
            batchDirectories[identifier] = newTokenDirectory;
        } else {
            if (_ownerships[identifier].addr == address(0)) {
                revert QueryForNonexistentToken();
            }
            _individualTokenMetadata[identifier] = newTokenDirectory;
        }
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
        if (!_checkOnERC721Received(address(0), to, tokenId, _data)) {
            revert TransferToNonERC721ReceiverImplementer();
        }
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     * In order to save gas, _batchMintedCount is not updated here and needs to be updated when
     * extending this contract.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        if (to == address(0)) revert MintToZeroAddress();
        if (_exists(tokenId) || _ownerships[tokenId].burned) {
            revert MintExistingToken();
        }
        uint256 batchId = _getBatchId(tokenId);
        if (_getBatchIndex(tokenId) >= _batchIdToData[batchId].batchSize) {
            revert OverBatchTokenLimit();
        }

        _beforeTokenTransfer(address(0), to, tokenId);

        if (_batchIdToData[batchId].isSequentiallyMintable) {
            _batchIdToData[batchId].isSequentiallyMintable = false;
        }

        // Overflows are incredibly unrealistic.
        // balance or numberMinted overflow if current value of either + quantity > 1.8e19 (2**64) - 1
        // _batchMintedCount overflows if _batchMintedCount + 1 > 1.2e77 (2**256) - 1
        unchecked {
            _batchMintedCount += 1;
            _addressData[to].balance += 1;
            _addressData[to].numberMinted += 1;

            _ownerships[tokenId].addr = to;
            _ownerships[tokenId].startTimestamp = uint64(block.timestamp);
        }

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Mints from a batch's `sequentialMints` to `sequentialMints + quantity` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the amount does not mint past a batche's `batchSize`
     * - the amount cannot be over DEFAULT_BATCH_SIZE
     *
     * Emits a {Transfer} event.
     */
    function _sequentialMint(
        address recipient,
        uint256 amount,
        uint256 batchId
    ) internal {
        if (recipient == address(0)) revert MintToZeroAddress();
        BatchData storage batchData = _batchIdToData[batchId];
        if (amount > batchSize || amount > DEFAULT_BATCH_SIZE || amount == 0) {
            revert InvalidBatchAmount();
        }
        if (batchData.sequentialMints + amount > batchData.batchSize) {
            revert OverBatchTokenLimit();
        }
        // Batch mint only works assuming that no _owners[] have been set for
        // tokenIds in the batch. Which is tracked by the isBatchMintable flag
        if (!batchData.isSequentiallyMintable) revert NotSequentiallyMintable();

        // Overflows are incredibly unrealistic.
        // balance or numberMinted overflow if current value of either + quantity > 1.8e19 (2**64) - 1
        // _batchMintedCount overflows if _batchMintedCount + amount > 1.2e77 (2**256) - 1
        unchecked {
            uint256 firstNum = batchId * batchSize + batchData.sequentialMints;
            uint256 lastNum = firstNum + amount;
            uint64 timestamp = uint64(block.timestamp);
            // ensures ownerOf runs quickly even if user is minting a large number like 100
            for (uint256 i = firstNum; i < lastNum; i += seqMintLimit) {
                _ownerships[i].addr = recipient;
                _ownerships[i].startTimestamp = timestamp;
            }

            // gas is cheaper for two separate loops
            for (uint256 i = firstNum; i < lastNum; i++) {
                emit Transfer(address(0), recipient, i);
            }
            _addressData[recipient].balance += uint64(amount);
            _addressData[recipient].numberMinted += uint64(amount);
            _batchMintedCount += uint64(amount);

            batchData.sequentialMints += uint64(amount);
        }
    }

    /**
     * @dev mints an NFT from the individual block section with a given tokenURI
     * If the individual batch has reached full size, it will allocate
     * a new batch of token IDs for individual tokens.
     */
    function _mintIndividualURI(address recipient, string memory uri)
        internal
        returns (uint256)
    {
        if (recipient == address(0)) revert MintToZeroAddress();

        uint256 tokenBatchOffset = _individualTokensCount % batchSize;
        if (tokenBatchOffset == 0) {
            _individualTokenIdBase = _nextBatchId * batchSize;
            _nextBatchId += 1;
        }

        // Overflows are incredibly unrealistic.
        // balance or numberMinted overflow if current value of either + quantity > 1.8e19 (2**64) - 1
        // tokenId overflows if _nextBatchId * batchSize + tokenBatchOffset > 1.2e77 (2**256) - 1
        unchecked {
            uint256 tokenId = tokenBatchOffset + _individualTokenIdBase;
            _individualTokenMetadata[tokenId] = uri;

            _beforeTokenTransfer(address(0), recipient, tokenId);
            _individualTokensCount += 1;
            _addressData[recipient].balance += 1;
            _addressData[recipient].numberMinted += 1;

            _ownerships[tokenId].addr = recipient;
            _ownerships[tokenId].startTimestamp = uint64(block.timestamp);

            emit Transfer(address(0), recipient, tokenId);
            return tokenId;
        }
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
        _burnAndMint(tokenId, tokenId);
    }

    /**
     * Slightly modified to support the ability to burn and instantly mint a different offset tokenId.
     */
    function _burnAndMint(uint256 tokenId, uint256 mintId) internal virtual {
        TokenOwnership memory ownership = _ownershipOf(tokenId);
        address owner = ownership.addr;
        if (!_exists(tokenId)) revert QueryForNonexistentToken();

        bool burnAndMint = tokenId != mintId;
        if (burnAndMint && _exists(mintId)) revert MintExistingToken();

        if (!_isApprovedOrOwner(_msgSender(), tokenId, owner)) {
            revert TransferCallerNotOwnerNorApproved();
        }

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId, owner);

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // _totalBurned, _batchMintedCount overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            _addressData[owner].numberBurned += 1;
            if (burnAndMint) {
                _addressData[owner].numberMinted += 1;
                _batchMintedCount += 1;

                _ownerships[mintId].addr = owner;
                _ownerships[mintId].startTimestamp = uint64(block.timestamp);
                emit Transfer(address(0), owner, mintId);
            } else {
                _addressData[owner].balance -= 1;
            }

            _totalBurned += 1;
            _updateNextOwnershipIfUnset(tokenId, ownership);
        }
        _ownerships[tokenId].startTimestamp = uint64(block.timestamp);
        _ownerships[tokenId].burned = true;

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
        TokenOwnership memory ownership = _ownershipOf(tokenId);
        if (!_isApprovedOrOwner(_msgSender(), tokenId, from)) {
            revert TransferCallerNotOwnerNorApproved();
        }
        _transferWithOwnershipData(ownership, from, to, tokenId);
    }

    /**
     * @dev This is for functions which already get the ownership of the tokenId because ownerOf() in 721A
     * is potentially an expensive function and should not be called twice if not needed to save gas.
     *
     * WARNING this internal method expects to get passed in the TokenOwnership of the tokenId and will not
     * verify if it really is. It also ignores checking the owner so tokens can be loanable.
     */
    function _transferWithOwnershipData(
        TokenOwnership memory tokenOwnership,
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        if (to == address(0)) revert TransferToZeroAddress();
        if (tokenOwnership.addr != from) revert TransferFromIncorrectOwner();

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, from);

        _ownerships[tokenId].addr = to;
        _ownerships[tokenId].startTimestamp = uint64(block.timestamp);

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            _addressData[from].balance -= 1;
            _addressData[to].balance += 1;

            _updateNextOwnershipIfUnset(tokenId, tokenOwnership);
        }
        _ownerships[tokenId].addr = to;
        _ownerships[tokenId].startTimestamp = uint64(block.timestamp);

        emit Transfer(from, to, tokenId);
    }

    /**
     * To be called from a transfer or burn if it is within the tokens that were sequentially
     * minted. This is because to save initial mint gas we do not set the ownership of
     * all the tokenIds until it is explicitly needed.
     *
     * This will do nothing if token ID is from a batch set aside for individual tokens or if
     * a token was minted randomly from the middle of a batch. This is gauranted by checking the
     * next token ID against `sequentialMints` counter.
     */
    function _updateNextOwnershipIfUnset(
        uint256 tokenId,
        TokenOwnership memory ownership
    ) internal {
        BatchData memory batchData = _batchIdToData[_getBatchId(tokenId)];
        if (
            _getBatchIndex(tokenId) + 1 < batchData.sequentialMints &&
            _ownerships[tokenId + 1].addr == address(0)
        ) {
            _ownerships[tokenId + 1].addr = ownership.addr;
            _ownerships[tokenId + 1].startTimestamp = ownership.startTimestamp;
        }
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
    ) internal virtual {
        if (_tokenApprovals[tokenId] != to) {
            _tokenApprovals[tokenId] = to;
            emit Approval(owner, to, tokenId);
        }
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
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert TransferToNonERC721ReceiverImplementer();
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
        bytes32 s;
        uint8 v;
        assembly {
            s := and(
                vs,
                0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
            )
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
 * @dev Interface for the NFT Royalty Standard
 */
interface IERC2981 is IERC165 {
    /**
     * ERC165 bytes to add to interface array - set in parent contract
     * implementing this standard
     *
     * bytes4(keccak256("royaltyInfo(uint256,uint256)")) == 0x2a55205a
     * bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
     * _registerInterface(_INTERFACE_ID_ERC2981);
     */

    /**
     * @notice Called with the sale price to determine how much royalty
     *          is owed and to whom.
     * @param _tokenId - the NFT asset queried for royalty information
     * @param _salePrice - the sale price of the NFT asset specified by _tokenId
     * @return receiver - address of who should be sent the royalty payment
     * @return royaltyAmount - the royalty payment amount for _salePrice
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

/**
 * @dev External interface of the EaselyPayout contract
 */
interface IEaselyPayout {
    /**
     * @dev Takes in a payable amount and splits it among the given royalties.
     * Also takes a cut of the payable amount depending on the sender and the primaryPayout address.
     * Ensures that this method never splits over 100% of the payin amount.
     */
    function splitPayable(
        address primaryPayout,
        address[] memory royalties,
        uint256[] memory bps
    ) external payable;
}

error BeforeStartTime();
error InsufficientValue();
error InvalidStartEndPrices();
error InvalidStartEndTimes();
error InvalidVersion();
error LoansInactive();
error MustHaveDualSignature();
error MustHaveOwnerSignature();
error MustHaveTokenOwnerSignature();
error MustHaveVerifiedSignature();
error NotTokenLoaner();
error OverMaxRoyalties();
error SaleInactive();
error SellerNotOwner();
error TokenOnLoan();
error WithdrawSplitsTooHigh();

/**
 * @dev Extension of the ERC721 contract that integrates a marketplace so that simple lazy-sales
 * do not have to be done on another contract. This saves gas fees on secondary sales because
 * buyers will not have to pay a gas fee to setApprovalForAll for another marketplace contract after buying.
 *
 * Easely will help power the lazy-selling as well as lazy minting that take place on
 * directly on the collection, which is why we take a cut of these transactions. Our cut can
 * be publically seen in the connected EaselyPayout contract and cannot exceed 5%.
 *
 * Owners also set a dual signer which they can change at any time. This dual signer helps enable
 * sales for large batches of addresses without needing to manually sign hundreds or thousands of hashes.
 * It also makes phishing scams harder as both signatures need to be compromised before an unwanted sale can occur.
 *
 * Owner also has an option to allow token owners to loan their tokens to other users which makes the token
 * untradeable until the original owner reclaims the token.
 */
abstract contract ERC721Marketplace is ERC721B, Ownable, IERC2981 {
    using ECDSA for bytes32;
    using Strings for uint256;

    // Allows token owners to loan tokens to other addresses.
    bool public loaningActive;

    /* see {IEaselyPayout} for more */
    address public constant PAYOUT_CONTRACT_ADDRESS =
        0xa95850bB73459ADB9587A97F103a4A7CCe59B56E;
    uint256 internal constant TIME_PER_DECREMENT = 300;

    /* Basis points or BPS are 1/100th of a percent, so 10000 basis points accounts for 100% */
    uint256 internal constant BPS_TOTAL = 10000;
    /* Max basis points for the owner for secondary sales of this collection */
    uint256 internal constant MAX_SECONDARY_BPS = 1000;
    /* Default payout percent if there is no signature set */
    uint256 internal constant DEFAULT_PAYOUT_BPS = 500;
    /* Signer for initializing splits to ensure splits were agreed upon by both parties */
    address internal constant VERIFIED_CONTRACT_SIGNER =
        0x1BAAd9BFa20Eb279d2E3f3e859e3ae9ddE666c52;

    /*
     * Optional addresses to distribute referral commission for this collection
     *
     * Referral commission is taken from easely's cut
     */
    address public referralAddress;
    /*
     * Optional addresses to distribute partnership comission for this collection
     *
     * Partnership commission is taken in addition to easely's cut
     */
    address public partnershipAddress;
    /* Optional addresses to distribute revenue of primary sales of this collection */
    address public revenueShareAddress;

    /* Enables dual address signatures to lazy mint */
    address public dualSignerAddress;

    // Compiler will pack these units below together into a 256bit section
    /* Optional basis points for the owner for secondary sales of this collection */
    uint64 public ownerRoyaltyBPS;
    /* Basis points for easely's payout contract */
    uint64 public payoutBPS;
    /* Optional basis points for revenue sharing the owner wants to set up */
    uint64 public revenueShareBPS;
    /*
     * Optional basis points for collections that have been referred.
     *
     * Contracts with this will have a reduced easely's payout cut so that
     * the creator's cut is unaffected
     */
    uint32 public referralBPS;
    /*
     * Optional basis points for collections that require partnerships
     *
     * Contracts with this will have this fee on top of easely's payout cut because the partnership
     * will offer advanced web3 integration of this contract in some form beyond what easely provides.
     */
    uint32 public partnershipBPS;

    mapping(uint256 => address) internal _tokenOwnersOnLoan;
    /* Mapping to the active version for all signed transactions */
    mapping(address => uint256) internal _addressToActiveVersion;
    /* Cancelled or finalized sales by hash to determine buyabliity */
    mapping(bytes32 => bool) internal _cancelledOrFinalizedSales;

    // Events related to lazy selling
    event SaleCancelled(address indexed seller, bytes32 hash);
    event SaleCompleted(
        address indexed seller,
        address indexed buyer,
        uint256 indexed tokenId,
        uint256 price,
        bytes32 hash
    );

    // Events related to loaning
    event LoaningActive(bool active);
    event Loan(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );
    event LoanRetrieved(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    // Miscellaneous events
    event VersionChanged(address indexed seller, uint256 version);
    event DualSignerChanged(address newSigner);
    event BalanceWithdrawn(uint256 balance);
    event RoyaltyUpdated(uint256 bps);
    event WithdrawSplitsSet(
        address indexed revenueShareAddress,
        address indexed referralAddress,
        address indexed partnershipAddress,
        uint256 payoutBPS,
        uint256 revenueShareBPS,
        uint256 referralBPS,
        uint256 partnershipBPS
    );

    /**
     * @dev initializes all of the addresses and percentage of withdrawn funds that
     * each address will get. These addresses and BPS splits must be signed by both the
     * verified easely wallet and the creator of the contract. If a signature is missing
     * the contract has a default of 5% to the easely payout wallet.
     */
    function _initWithdrawSplits(
        address owner_,
        address revenueShareAddress_,
        address referralAddress_,
        address partnershipAddress_,
        uint256 payoutBPS_,
        uint256 ownerRoyaltyBPS_,
        uint256 revenueShareBPS_,
        uint256 referralBPS_,
        uint256 partnershipBPS_,
        bytes[2] memory signatures
    ) internal virtual {
        revenueShareAddress = revenueShareAddress_;
        if (ownerRoyaltyBPS_ > MAX_SECONDARY_BPS) revert OverMaxRoyalties();
        if (signatures[1].length == 0) {
            if (DEFAULT_PAYOUT_BPS + revenueShareBPS_ > BPS_TOTAL) {
                revert WithdrawSplitsTooHigh();
            }
            ownerRoyaltyBPS = uint64(ownerRoyaltyBPS_);
            payoutBPS = uint64(DEFAULT_PAYOUT_BPS);
            revenueShareBPS = uint64(revenueShareBPS_);
            emit WithdrawSplitsSet(
                revenueShareAddress_,
                address(0),
                address(0),
                DEFAULT_PAYOUT_BPS,
                revenueShareBPS_,
                0,
                0
            );
        } else {
            if (
                payoutBPS_ + referralBPS_ + partnershipBPS_ + revenueShareBPS_ >
                BPS_TOTAL
            ) {
                revert WithdrawSplitsTooHigh();
            }
            bytes memory encoded = abi.encode(
                "InitializeSplits",
                owner_,
                revenueShareAddress_,
                referralAddress_,
                partnershipAddress_,
                payoutBPS_,
                revenueShareBPS_,
                referralBPS_,
                partnershipBPS_
            );
            bytes32 hash = ECDSA.toEthSignedMessageHash(keccak256(encoded));
            if (hash.recover(signatures[0]) != owner_) {
                revert MustHaveOwnerSignature();
            }
            if (hash.recover(signatures[1]) != VERIFIED_CONTRACT_SIGNER) {
                revert MustHaveVerifiedSignature();
            }
            referralAddress = referralAddress_;
            partnershipAddress = partnershipAddress_;
            ownerRoyaltyBPS = uint64(ownerRoyaltyBPS_);
            payoutBPS = uint64(payoutBPS_);
            revenueShareBPS = uint64(revenueShareBPS_);
            referralBPS = uint32(referralBPS_);
            partnershipBPS = uint32(partnershipBPS_);
            emit WithdrawSplitsSet(
                revenueShareAddress_,
                referralAddress_,
                partnershipAddress_,
                payoutBPS_,
                revenueShareBPS_,
                referralBPS_,
                partnershipBPS_
            );
        }
        emit RoyaltyUpdated(ownerRoyaltyBPS_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721B, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(Ownable).interfaceId ||
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev see {IERC2981-supportsInterface}
     */
    function royaltyInfo(uint256, uint256 _salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        uint256 royalty = (_salePrice * ownerRoyaltyBPS) / BPS_TOTAL;
        return (owner(), royalty);
    }

    /**
     * @dev See {_currentPrice}
     */
    function getCurrentPrice(uint256[4] memory pricesAndTimestamps)
        external
        view
        returns (uint256)
    {
        return _currentPrice(pricesAndTimestamps);
    }

    /**
     * @dev Returns the current activeVersion of an address both used to create signatures
     * and to verify signatures of {buyToken} and {buyNewToken}
     */
    function getActiveVersion(address address_)
        external
        view
        returns (uint256)
    {
        return _addressToActiveVersion[address_];
    }

    /**
     * This function, while callable by anybody will always ONLY withdraw the
     * contract's balance to:
     *
     * the owner's account
     * the addresses the owner has set up for revenue share
     * the easely payout contract cut - capped at 5% but can be lower for some users
     *
     * This is callable by anybody so that Easely can set up automatic payouts
     * after a contract has reached a certain minimum to save creators the gas fees
     * involved in withdrawing balances.
     */
    function withdrawBalance(uint256 withdrawAmount) external {
        if (withdrawAmount > address(this).balance) {
            withdrawAmount = address(this).balance;
        }

        uint256 payoutBasis = withdrawAmount / BPS_TOTAL;
        if (revenueShareBPS > 0) {
            payable(revenueShareAddress).transfer(
                payoutBasis * revenueShareBPS
            );
        }
        if (referralBPS > 0) {
            payable(referralAddress).transfer(payoutBasis * referralBPS);
        }
        if (partnershipBPS > 0) {
            payable(partnershipAddress).transfer(payoutBasis * partnershipBPS);
        }
        payable(PAYOUT_CONTRACT_ADDRESS).transfer(payoutBasis * payoutBPS);

        uint256 remainingAmount = withdrawAmount -
            payoutBasis *
            (revenueShareBPS + partnershipBPS + referralBPS + payoutBPS);
        payable(owner()).transfer(remainingAmount);
        emit BalanceWithdrawn(withdrawAmount);
    }

    /**
     * @dev Allows the owner to change who the dual signer is
     */
    function setDualSigner(address alt) external onlyOwner {
        dualSignerAddress = alt;
        emit DualSignerChanged(alt);
    }

    /**
     * @dev see {_setSecondary}
     */
    function setRoyaltiesBPS(uint256 newBPS) external onlyOwner {
        if (newBPS > MAX_SECONDARY_BPS) revert OverMaxRoyalties();
        ownerRoyaltyBPS = uint64(newBPS);
        emit RoyaltyUpdated(newBPS);
    }

    /**
     * @dev Usable by any user to update the version that they want their signatures to check. This is helpful if
     * an address wants to mass invalidate their signatures without having to call cancelSale on each one.
     */
    function updateVersion(uint256 version) external {
        _addressToActiveVersion[_msgSender()] = version;
        emit VersionChanged(_msgSender(), version);
    }

    /**
     * @dev To be updated by contract owner to allow for the loan functionality to be toggled
     */
    function setLoaningActive(bool _loaningActive) public onlyOwner {
        loaningActive = _loaningActive;
        emit LoaningActive(_loaningActive);
    }

    /**
     * @dev Returns who is loaning the given tokenId
     */
    function tokenOwnerOnLoan(uint256 tokenId) external view returns (address) {
        if (!_exists(tokenId)) revert QueryForNonexistentToken();
        return _tokenOwnersOnLoan[tokenId];
    }

    /**
     * @notice Allow owner to loan their tokens to other addresses
     */
    function loan(uint256 tokenId, address receiver) external {
        address msgSender = _msgSender();
        if (!loaningActive) revert LoansInactive();

        // Transfer the token
        // _safeTransfer checks that msgSender is the tokenOwner
        _safeTransfer(msgSender, receiver, tokenId, "");

        // Add it to the mapping of originally loaned tokens
        _tokenOwnersOnLoan[tokenId] = msgSender;

        emit Loan(msgSender, receiver, tokenId);
    }

    /**
     * @notice Allow owner to loan their tokens to other addresses
     */
    function retrieveLoan(uint256 tokenId) external {
        TokenOwnership memory ownership = _ownershipOf(tokenId);
        address msgSender = _msgSender();
        if (_tokenOwnersOnLoan[tokenId] != msgSender) revert NotTokenLoaner();

        // Remove it from the array of loaned out tokens
        delete _tokenOwnersOnLoan[tokenId];

        // Transfer the token back
        _safeTransferWithOwnershipData(
            ownership,
            ownership.addr,
            msgSender,
            tokenId,
            ""
        );

        emit LoanRetrieved(ownership.addr, msgSender, tokenId);
    }

    /**
     * @dev helper method get ownerRoyalties into an array form
     */
    function _ownerRoyalties() internal view returns (address[] memory) {
        address[] memory ownerRoyalties = new address[](1);
        ownerRoyalties[0] = owner();
        return ownerRoyalties;
    }

    /**
     * @dev helper method get secondary BPS into array form
     */
    function _ownerBPS() internal view returns (uint256[] memory) {
        uint256[] memory ownerBPS = new uint256[](1);
        ownerBPS[0] = ownerRoyaltyBPS;
        return ownerBPS;
    }

    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     *
     * makes sure tokens on loan can't be transferred
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721B) {
        super._beforeTokenTransfer(from, to, tokenId);
        if (_tokenOwnersOnLoan[tokenId] != address(0)) revert TokenOnLoan();
    }

    /**
     * @dev Checks if an address is either the owner, or the approved alternate signer.
     */
    function _checkValidSigner(address signer) internal view {
        if (signer == owner()) return;
        if (dualSignerAddress == address(0)) revert MustHaveOwnerSignature();
        if (signer != dualSignerAddress) revert MustHaveDualSignature();
    }

    /**
     * @dev Hash an order, returning the hash that a client must sign, including the standard message prefix
     * @return Hash of message prefix and order hash per Ethereum format
     */
    function _hashForSale(
        address owner,
        uint256 version,
        uint256 nonce,
        uint256 tokenId,
        uint256[4] memory pricesAndTimestamps
    ) internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    address(this),
                    block.chainid,
                    owner,
                    version,
                    nonce,
                    tokenId,
                    pricesAndTimestamps
                )
            );
    }

    /**
     * @dev Hash an order, returning the hash that a client must sign, including the standard message prefix
     * @return Hash of message prefix and order hash per Ethereum format
     */
    function _hashToCheckForSale(
        address owner,
        uint256 version,
        uint256 nonce,
        uint256 tokenId,
        uint256[4] memory pricesAndTimestamps
    ) internal view returns (bytes32) {
        return
            ECDSA.toEthSignedMessageHash(
                _hashForSale(
                    owner,
                    version,
                    nonce,
                    tokenId,
                    pricesAndTimestamps
                )
            );
    }

    /**
     * @dev Current price for a sale which is calculated for the case of a descending sale. So
     * the ending price must be less than the starting price and the timestamp is active.
     * Standard single fare sales will have a matching starting and ending price.
     */
    function _currentPrice(uint256[4] memory pricesAndTimestamps)
        internal
        view
        returns (uint256)
    {
        uint256 startingPrice = pricesAndTimestamps[0];
        uint256 endingPrice = pricesAndTimestamps[1];
        uint256 startingTimestamp = pricesAndTimestamps[2];
        uint256 endingTimestamp = pricesAndTimestamps[3];

        uint256 currTime = block.timestamp;
        if (currTime < startingTimestamp) revert BeforeStartTime();
        if (startingTimestamp >= endingTimestamp) revert InvalidStartEndTimes();
        if (startingPrice < endingPrice) revert InvalidStartEndPrices();

        if (startingPrice == endingPrice || currTime > endingTimestamp) {
            return endingPrice;
        }

        uint256 diff = startingPrice - endingPrice;
        uint256 decrements = (currTime - startingTimestamp) /
            TIME_PER_DECREMENT;
        if (decrements == 0) {
            return startingPrice;
        }

        // decrements will equal 0 before totalDecrements does so we will not divide by 0
        uint256 totalDecrements = (endingTimestamp - startingTimestamp) /
            TIME_PER_DECREMENT;

        return startingPrice - (diff / totalDecrements) * decrements;
    }

    /**
     * @dev Checks if a hash has been signed by a signer, and if this contract has a dual signer,
     * that the dual signer has also signed the hash
     */
    function _checkHashAndSignatures(
        bytes32 hash,
        address signer,
        bytes memory signature,
        bytes memory dualSignature
    ) internal view {
        if (_cancelledOrFinalizedSales[hash]) revert SaleInactive();
        if (hash.recover(signature) != signer) revert MustHaveOwnerSignature();
        if (
            dualSignerAddress != address(0) &&
            hash.recover(dualSignature) != dualSignerAddress
        ) revert MustHaveDualSignature();
    }

    /**
     * @dev Usable by the owner of any token initiate a sale for their token. This does not
     * lock the tokenId and the owner can freely trade their token, but doing so will
     * invalidate the ability for others to buy.
     */
    function hashToSignToSellToken(
        uint256 version,
        uint256 nonce,
        uint256 tokenId,
        uint256[4] memory pricesAndTimestamps
    ) external view returns (bytes32) {
        if (_msgSender() != ownerOf(tokenId)) {
            revert MustHaveTokenOwnerSignature();
        }
        return
            _hashForSale(
                _msgSender(),
                version,
                nonce,
                tokenId,
                pricesAndTimestamps
            );
    }

    /**
     * @dev Usable to cancel hashes generated from {hashToSignToSellToken}
     */
    function cancelSale(
        uint256 version,
        uint256 nonce,
        uint256 tokenId,
        uint256[4] memory pricesAndTimestamps
    ) external {
        bytes32 hash = _hashToCheckForSale(
            _msgSender(),
            version,
            nonce,
            tokenId,
            pricesAndTimestamps
        );
        _cancelledOrFinalizedSales[hash] = true;
        emit SaleCancelled(_msgSender(), hash);
    }

    /**
     * @dev With a hash signed by the method {hashToSignToSellToken} any user sending enough value can buy
     * the token from the seller. Tokens not owned by the contract owner are all considered secondary sales and
     * will give a cut to the owner of the contract based on the secondaryOwnerBPS.
     */
    function buyToken(
        address seller,
        uint256 version,
        uint256 nonce,
        uint256 tokenId,
        uint256[4] memory pricesAndTimestamps,
        bytes memory signature,
        bytes memory dualSignature
    ) external payable {
        uint256 currentPrice = _currentPrice(pricesAndTimestamps);
        TokenOwnership memory ownership = _ownershipOf(tokenId);
        if (ownership.addr != seller) revert SellerNotOwner();
        if (_addressToActiveVersion[seller] != version) revert InvalidVersion();
        if (msg.value < currentPrice) revert InsufficientValue();

        bytes32 hash = _hashToCheckForSale(
            seller,
            version,
            nonce,
            tokenId,
            pricesAndTimestamps
        );
        _checkHashAndSignatures(hash, seller, signature, dualSignature);
        _cancelledOrFinalizedSales[hash] = true;

        emit SaleCompleted(seller, _msgSender(), tokenId, currentPrice, hash);
        _safeTransferWithOwnershipData(
            ownership,
            seller,
            _msgSender(),
            tokenId,
            ""
        );

        if (seller != owner()) {
            IEaselyPayout(PAYOUT_CONTRACT_ADDRESS).splitPayable{
                value: currentPrice
            }(seller, _ownerRoyalties(), _ownerBPS());
        }
        payable(_msgSender()).transfer(msg.value - currentPrice);
    }
}

error AlreadyInitiated();
error ChunkAlreadyProcessed();
error InvalidBurnToken();
error InvalidChunk();
error InvalidIndividualToken();
error NotBurnable();

/**
 * @dev This implements a lazy-minted, multi-directory metadata storage version of ERC721Marketplace.
 * It gives the creator flexibility to mint singular hashes at a time or entire batches of tokens under
 * a single token directory -- commonly an IPFS hash. Batching tokens together saves an immense amount of gas,
 * but the owner of this collection gives up some control over the tokenIds exact numbering.
 *
 * Each batch that the owner releases gets offset by the batchSize because doing so makes it possible
 * to enable the same benefits as ERC721A across multiple different releases separately. This functionality
 * makes it cheap for the contract creator to mint hundres of tokens and allow their full collection to
 * be shown on places like opensea without needing to be bought out first.
 *
 * Note: This batch minting is reserved only for the contract creator and not for external buyers.
 *
 * It has two main methods to lazy-mint, one allows the owner to set a price for a singular token in an
 * existing batch or set a price for a single new tokenURI that will get added to this collection.
 */
contract ERC721BatchableCollection is ERC721Marketplace {
    using ECDSA for bytes32;
    using Strings for uint256;

    bool private hasInit = false;

    bool public burnable;
    // returns if NFTs from this collection mint an NFT post burn
    bool public mintPostBurn;

    // Token IDs above this are reserved for post burn NFTs
    uint256 public constant MAX_TOKENS = 2**128;

    // So the owner does not repeat airdrops
    mapping(uint256 => bool) processedChunksForOwnerMint;

    event OwnerMinted(uint256 chunk);
    event TokenBought(
        address indexed buyer,
        uint256 indexed tokenId,
        uint256 price,
        string uri,
        bytes32 saleHash
    );

    /**
     * @dev Constructor function
     */
    constructor(
        bool[2] memory bools,
        address[4] memory addresses,
        uint256[8] memory uints,
        string[4] memory strings,
        bytes[2] memory signatures
    ) ERC721B(strings[0], strings[1]) {
        _init(bools, addresses, uints, strings, signatures);
    }

    function init(
        bool[2] memory bools,
        address[4] memory addresses,
        uint256[8] memory uints,
        string[4] memory strings,
        bytes[2] memory signatures
    ) external {
        _init(bools, addresses, uints, strings, signatures);
    }

    function _init(
        bool[2] memory bools,
        address[4] memory addresses,
        uint256[8] memory uints,
        string[4] memory strings,
        bytes[2] memory signatures
    ) internal {
        if (hasInit) revert AlreadyInitiated();
        hasInit = true;

        burnable = bools[0];
        mintPostBurn = bools[1];

        _owner = _msgSender();
        _initWithdrawSplits(
            _owner,
            addresses[0], // revenue share address
            addresses[1], // referral address
            addresses[2], // partnership address
            uints[0], // payout BPS
            uints[1], // owner secondary BPS
            uints[2], // revenue share BPS
            uints[3], // referral BPS
            uints[4], // partnership BPS
            signatures
        );
        _setSeqMintLimit(uints[5]);
        _setBatchSize(uints[6]);
        dualSignerAddress = addresses[3];

        _setBaseURI(strings[2]);
        if (uints[7] > 0 && bytes(strings[3]).length > 0) {
            _addTokenDirectoryRelease(strings[3], uints[7]);
        }
    }

    /**
     * @dev Method used if the creator wants to change their name and symbol later
     *
     * If the owner of the collection calls {lockTokenURI} the name and symbol may
     * no longer change.
     */
    function changeNameAndSymbol(
        string calldata _newName,
        string calldata _newSymbol
    ) external onlyOwner {
        _setTokenName(_newName);
        _setTokenSymbol(_newSymbol);
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     *
     * This collection's tokenURIs can be part of a batch or individual, and can
     * have a post_burn minted token. This function takes tokenId and finds the right
     * token directory saved for that token both for batch and individual tokens.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert QueryForNonexistentToken();
        if (tokenId < MAX_TOKENS) {
            return _getTokenURI(tokenId);
        }

        string memory preBurnURI = _getTokenURI(tokenId - MAX_TOKENS);
        return string(abi.encodePacked(preBurnURI, "/post_burn"));
    }

    /**
     * @dev see {_addTokenDirectoryRelease}
     */
    function addTokenDirectoryRelease(
        string memory tokenDirectory,
        uint256 releaseAmount
    ) external onlyOwner {
        _addTokenDirectoryRelease(tokenDirectory, releaseAmount);
    }

    /**
     * @dev see {_updateTokenDirectory}
     */
    function changeTokenDirectory(
        string memory newDirectory,
        uint256 identifier,
        bool isBatch
    ) external onlyOwner {
        _updateTokenDirectory(newDirectory, identifier, isBatch);
    }

    /**
     * @dev Only for NFTs that are already part of a defined batch
     */
    function ownerMint(
        address[] calldata recipients,
        uint256[] calldata amounts,
        uint256 batchId,
        uint256 chunk
    ) external onlyOwner {
        if (processedChunksForOwnerMint[chunk]) revert ChunkAlreadyProcessed();
        if (recipients.length != amounts.length) revert InvalidChunk();
        for (uint256 i; i < amounts.length; i++) {
            _sequentialMint(recipients[i], amounts[i], batchId);
        }
        processedChunksForOwnerMint[chunk] = true;
        emit OwnerMinted(chunk);
    }

    /**
     * @dev see {_createBatchNFT}
     */
    function giftBatchedNFT(address giftAddress, uint256 tokenId)
        external
        onlyOwner
    {
        _safeMint(giftAddress, tokenId);
    }

    /**
     * @dev see {_createIndividualNFT}
     */
    function giftIndividualNFT(address giftAddress, string memory uri)
        external
        onlyOwner
    {
        _mintIndividualURI(giftAddress, uri);
    }

    /**
     * @dev Hash an order, returning the hash that a client must sign, including the standard message prefix
     * @return Hash of message prefix and order hash per Ethereum format
     */
    function _hashForMintingIndividual(
        uint256 version,
        uint256 nonce,
        uint256[4] memory pricesAndTimestamps,
        string memory uri
    ) internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    address(this),
                    block.chainid,
                    owner(),
                    version,
                    nonce,
                    pricesAndTimestamps,
                    uri
                )
            );
    }

    /**
     * @dev Hash an order, returning the hash that a client must sign, including the standard message prefix
     * @return Hash of message prefix and order hash per Ethereum format
     */
    function _hashToCheckForMintingIndividual(
        uint256 version,
        uint256 nonce,
        uint256[4] memory pricesAndTimestamps,
        string memory uri
    ) internal view returns (bytes32) {
        return
            ECDSA.toEthSignedMessageHash(
                _hashForMintingIndividual(
                    version,
                    nonce,
                    pricesAndTimestamps,
                    uri
                )
            );
    }

    /**
     * @dev Usable by the owner of this collection to sell a new token. The owner can decide what
     * the tokenURI of it will be and if the token is claimable and what the claimable hash would be
     */
    function hashToSignToSellIndividualToken(
        uint256 version,
        uint256 nonce,
        uint256[4] memory pricesAndTimestamps,
        string memory uri
    ) external view returns (bytes32) {
        _checkValidSigner(_msgSender());
        if (bytes(uri).length == 0) revert InvalidIndividualToken();
        return
            _hashForMintingIndividual(version, nonce, pricesAndTimestamps, uri);
    }

    /**
     * @dev Usable to cancel hashes generated from both {hashToSignToSellNewToken} and {hashToSignToSellToken}
     */
    function cancelIndividualTokenSale(
        uint256 version,
        uint256 nonce,
        uint256[4] memory pricesAndTimestamps,
        string memory uri
    ) external {
        _checkValidSigner(_msgSender());
        bytes32 hash = _hashToCheckForMintingIndividual(
            version,
            nonce,
            pricesAndTimestamps,
            uri
        );

        _cancelledOrFinalizedSales[hash] = true;
        emit SaleCancelled(_msgSender(), hash);
    }

    /**
     * @dev With a hash signed by the method {hashToSignToSellIndividualToken} any user sending enough value can
     * mint the token from the contract. These are all considered primary sales and will give a cut to the
     * royalties defined in the contract.
     */
    function buyIndividualToken(
        uint256 version,
        uint256 nonce,
        uint256[4] memory pricesAndTimestamps,
        string memory uri,
        bytes memory signature,
        bytes memory dualSignature
    ) external payable {
        if (version != _addressToActiveVersion[owner()]) {
            revert InvalidVersion();
        }

        uint256 currentPrice = _currentPrice(pricesAndTimestamps);
        if (msg.value < currentPrice) revert InsufficientValue();

        bytes32 hash = _hashToCheckForMintingIndividual(
            version,
            nonce,
            pricesAndTimestamps,
            uri
        );
        _checkHashAndSignatures(hash, owner(), signature, dualSignature);
        _cancelledOrFinalizedSales[hash] = true;

        uint256 tokenId = _mintIndividualURI(_msgSender(), uri);
        emit TokenBought(_msgSender(), tokenId, currentPrice, uri, hash);
        payable(_msgSender()).transfer(msg.value - currentPrice);
    }

    /**
     * @dev Hash an order, returning the hash that a client must sign, including the standard message prefix
     * @return Hash of message prefix and order hash per Ethereum format
     */
    function _hashForMintingFromBatch(
        uint256 version,
        uint256 nonce,
        uint256[4] memory pricesAndTimestamps,
        uint256 tokenId
    ) internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    address(this),
                    block.chainid,
                    owner(),
                    version,
                    nonce,
                    pricesAndTimestamps,
                    tokenId
                )
            );
    }

    /**
     * @dev Hash an order, returning the hash that a client must sign, including the standard message prefix
     * @return Hash of message prefix and order hash per Ethereum format
     */
    function _hashToCheckForMintingFromBatch(
        uint256 version,
        uint256 nonce,
        uint256[4] memory pricesAndTimestamps,
        uint256 tokenId
    ) internal view returns (bytes32) {
        return
            ECDSA.toEthSignedMessageHash(
                _hashForMintingFromBatch(
                    version,
                    nonce,
                    pricesAndTimestamps,
                    tokenId
                )
            );
    }

    /**
     * @dev Usable by the owner of this collection to sell a new token. The owner can decide what
     * the tokenURI of it will be and if the token is claimable and what the claimable hash would be
     */
    function hashToSignToSellFromBatch(
        uint256 version,
        uint256 nonce,
        uint256[4] memory pricesAndTimestamps,
        uint256 tokenId
    ) external view returns (bytes32) {
        _checkValidSigner(_msgSender());
        if (_exists(tokenId) || _ownerships[tokenId].burned) {
            revert MintExistingToken();
        }

        return
            _hashForMintingFromBatch(
                version,
                nonce,
                pricesAndTimestamps,
                tokenId
            );
    }

    /**
     * @dev Usable to cancel hashes generated from both {hashToSignToSellIndividualToken} and {hashToSignToSellFromBatch}
     */
    function cancelTokenFromBatchSale(
        uint256 version,
        uint256 nonce,
        uint256[4] memory pricesAndTimestamps,
        uint256 tokenId
    ) external {
        bytes32 hash;
        hash = _hashToCheckForMintingFromBatch(
            version,
            nonce,
            pricesAndTimestamps,
            tokenId
        );
        _cancelledOrFinalizedSales[hash] = true;
        emit SaleCancelled(_msgSender(), hash);
    }

    /**
     * @dev With a hash signed by the method {hashToSignToSellFromBatch} any user sending enough value can
     * mint the token from the contract. These are all considered primary sales and will give a cut to the
     * royalties defined in the contract.
     */
    function buyTokenFromBatch(
        uint256 version,
        uint256 nonce,
        uint256[4] memory pricesAndTimestamps,
        uint256 tokenId,
        bytes memory signature,
        bytes memory dualSignature
    ) external payable {
        if (version != _addressToActiveVersion[owner()]) {
            revert InvalidVersion();
        }

        uint256 currentPrice = _currentPrice(pricesAndTimestamps);
        if (msg.value < currentPrice) revert InsufficientValue();

        bytes32 hash = _hashToCheckForMintingFromBatch(
            version,
            nonce,
            pricesAndTimestamps,
            tokenId
        );
        _checkHashAndSignatures(hash, owner(), signature, dualSignature);
        _cancelledOrFinalizedSales[hash] = true;

        _safeMint(_msgSender(), tokenId);
        emit TokenBought(
            _msgSender(),
            tokenId,
            currentPrice,
            batchDirectories[_getBatchId(tokenId)],
            hash
        );
        payable(_msgSender()).transfer(msg.value - currentPrice);
    }

    /**
     * @dev Callable by any user who owns a token from a buurnable collection. If the collection
     * gas mint on burn set, they will get a newly minted token with the burn hash metadata.
     *
     * Burned tokens may refer to off-chain benefits, but these are the responsibility
     * of the contract creator to deliver and not on this contract.
     */
    function burn(uint256 tokenId) external {
        if (!burnable) revert NotBurnable();
        if (tokenId >= MAX_TOKENS) revert InvalidBurnToken();

        if (mintPostBurn) {
            _burnAndMint(tokenId, tokenId + MAX_TOKENS);
        } else {
            _burn(tokenId);
        }
    }
}