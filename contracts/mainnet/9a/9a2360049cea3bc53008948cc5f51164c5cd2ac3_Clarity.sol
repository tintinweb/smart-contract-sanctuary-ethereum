/**
 *Submitted for verification at Etherscan.io on 2022-02-05
*/

// File: contracts/Base64.sol

pragma solidity ^0.8.0;

library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

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
}

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

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

// File: @openzeppelin/contracts/utils/Address.sol


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

// File: contracts/Clarity.sol


pragma solidity >=0.8.11 <0.9.0;







contract ERC721 {}

contract Clarity is ERC721, IERC165, IERC721, IERC721Metadata {
    using Address for address;

    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    uint256 private _price1 = 1;
    uint256 private _price2 = 10;
    uint256 private _price3 = 100;
    uint256 private _price4 = 500;
    uint256 private _price5 = 900;
    uint256 private _price6 = 5000;

    constructor() {
        for (uint256 tokenId = 1; tokenId <= 6; tokenId++) {
            _mint(msg.sender, tokenId);
        }
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId;
    }

    function balanceOf(address owner)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(owner != address(0), "Err");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        address owner = _owners[tokenId];
        require(owner != address(0), "Err");
        return owner;
    }

    function name() public view virtual override returns (string memory) {
        return "Clarity";
    }

    function symbol() public view virtual override returns (string memory) {
        return "CLRT";
    }

    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        require(to != owner, "Err");

        require(
            msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "Err"
        );

        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        require(_exists(tokenId), "Err");

        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        _setApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Err");

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Err");
        _safeTransfer(from, to, tokenId, _data);
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "Err");
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        virtual
        returns (bool)
    {
        require(_exists(tokenId), "Err");
        address owner = ownerOf(tokenId);
        return (spender == owner ||
            getApproved(tokenId) == spender ||
            isApprovedForAll(owner, spender));
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ownerOf(tokenId) == from, "Err");
        require(to != address(0), "Err");

        _beforeTokenTransfer(from, to, tokenId);

        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "Err");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try
                IERC721Receiver(to).onERC721Received(
                    msg.sender,
                    from,
                    tokenId,
                    _data
                )
            returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("Err");
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

    function tokenSvg(uint256 tokenId)
        public
        view
        returns (string memory output)
    {
        if (tokenId == 1) {
            output = string(
                abi.encodePacked(
                    '<svg version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"><text x="50%" y="50%" font-weight="bold" text-align="center" text-anchor="middle" font-size="100" font-family="Courier New">&#x2666;',
                    _uint2str(_price1),
                    "</text></svg>"
                )
            );
        } else if (tokenId == 2) {
            output = string(
                abi.encodePacked(
                    '<svg height="100%" version="1.1" viewBox="0 0 254 254" xmlns="http://www.w3.org/2000/svg"><style>.t{font: bold 14px Courier New;}</style><g><rect x="4.5" y="4.5" width="245" height="245" fill="#fff" stroke="#d6f6f7" stroke-width="9"/><circle cx="127" cy="127" r="41" fill="#ffe5e6"/><text x="50%" y="131.28694" class="t" text-anchor="middle">',
                    _uint2str(_price2),
                    '</text><text x="169.81233" y="129.92375" font-size="10">&#x2666;</text></g></svg>'
                )
            );
        } else if (tokenId == 3) {
            output = string(
                abi.encodePacked(
                    '<svg height="100%" version="1.1" viewBox="0 0 271 271" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"><style>.t{font: bold 14px Courier New;}</style><defs><linearGradient id="a" x1="99" x2="169" y1="127" y2="127" gradientTransform="translate(5.7 6.6)" gradientUnits="userSpaceOnUse"><stop stop-color="#ffe5e6" offset="0"/><stop stop-color="#83e5e6" offset="1"/></linearGradient></defs><g><rect x="4.8" y="4.8" width="261" height="261" fill="#fff" stroke="#f5dada" stroke-width="9.6"/><circle cx="131" cy="134" r="44" fill="url(#a)"/><text x="130.76468" y="138.62802" class="t" text-anchor="middle" text-align="center">&#x2666;',
                    _uint2str(_price3),
                    '</text><path d="m80 119c9.2-21 34-24 54-24 40-0.98 69 66 26 84-23 9.6-94-41-80-60z" fill="none" stroke="#000" stroke-dasharray="4.33228, 4.33228" stroke-width=".36"/><circle cx="189" cy="142" r="5" fill="#ffe700"/><circle cx="183" cy="122" r="5" fill="#ff6900"/><circle cx="82" cy="159" r="4.8" fill="#ccc"/><rect x="83" y="98" width="5.4" height="5.4" fill="#0000a3"/></g></svg>'
                )
            );
        } else if (tokenId == 4) {
            output = string(
                abi.encodePacked(
                    '<svg height="100%" version="1.1" viewBox="0 0 271 271" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"><style>.t{font: bold 14px Courier New;}</style><defs><linearGradient id="g" x1="111.1" x2="162.1" y1="130" y2="130.6" gradientTransform="matrix(1.364 0 0 1.364 -56.62 -73.05)" gradientUnits="userSpaceOnUse"><stop stop-color="#ffe5e6" offset="0"/><stop stop-color="#83e5e6" offset="1"/></linearGradient><linearGradient id="e" x1="145.4" x2="89.91" y1="126.5" y2="140.7" gradientTransform="matrix(1.106 0 0 1.106 26.74 -51.78)" gradientUnits="userSpaceOnUse"><stop stop-color="#ffe5ff" offset="0"/><stop stop-color="#6ee5e6" offset="1"/></linearGradient><linearGradient id="c" x1="164.6" x2="171.9" y1="122" y2="122" gradientTransform="matrix(1.364 0 0 1.364 -56.62 -73.05)" gradientUnits="userSpaceOnUse"><stop stop-color="#ff6900" offset="0"/><stop stop-color="#ffc300" offset="1"/></linearGradient><linearGradient id="b" x1="169.1" x2="176.6" y1="135.2" y2="139.3" gradientTransform="matrix(1.364 0 0 1.364 -56.62 -73.05)" gradientUnits="userSpaceOnUse"><stop stop-color="#ffe700" offset="0"/><stop stop-color="#fc0" offset="1"/></linearGradient><linearGradient id="h" x1="64.51" x2="50" y1="161.6" y2="119.9" gradientTransform="matrix(.6552 1.197 -1.197 .6552 330.2 5.513)" gradientUnits="userSpaceOnUse"><stop stop-color="#ffb9ff" offset="0"/><stop stop-color="#b090ff" offset="1"/></linearGradient><linearGradient id="f" x1="-26.45" x2="64.51" y1="191.7" y2="161.6" gradientTransform="matrix(-.417 .8632 -.7742 -.5184 269.8 282.5)" gradientUnits="userSpaceOnUse"><stop stop-color="#00e2ff" offset="0"/><stop stop-color="#3fe5e6" offset="1"/></linearGradient><linearGradient id="d" x1="129.2" x2="137.2" y1="136.1" y2="136.1" gradientTransform="matrix(1.767 0 0 1.767 -106.5 -121.6)" gradientUnits="userSpaceOnUse"><stop stop-color="#f00" offset="0"/><stop stop-color="#ff7aff" offset="1"/></linearGradient><linearGradient id="a" x2="0" y2="1" gradientTransform="matrix(135.5 0 0 271 .0005541 .002772)" gradientUnits="userSpaceOnUse"><stop stop-color="#d2e3d2" offset="0"/><stop stop-color="#c1fff4" offset="1"/></linearGradient><linearGradient id="k" x1="-4.274" x2="276.7" y1="135.8" y2="135.8" gradientTransform="matrix(.9644 0 0 .9644 4.122 4.472)" gradientUnits="userSpaceOnUse" xlink:href="#a"/><linearGradient id="j" x1="4.822" x2="262.5" y1="244.2" y2="244.2" gradientTransform="translate(-.3095 -.3746)" gradientUnits="userSpaceOnUse"><stop stop-color="#ffe4ee" offset="0"/><stop stop-color="#ffffe2" stop-opacity="0" offset="1"/></linearGradient><linearGradient id="i" x1="9.956" x2="66.43" y1="108.5" y2="108.5" gradientTransform="translate(-.3095 -.3746)" gradientUnits="userSpaceOnUse" xlink:href="#a"/></defs><g><rect x="4.822" y="4.822" width="261.3" height="261.3" fill="#fff" stroke="url(#k)" stroke-width="9.64"/><path d="m66.12 206.4 194.8 19-0.5134 35.41-250.7 0.5134z" fill="url(#j)" stroke-width="9"/><circle cx="170.6" cy="92.61" r="35.38" fill="url(#e)"/><circle cx="120.9" cy="105.1" r="43.66" fill="url(#g)"/><text x="134.6772" y="106.2739" class="t" text-anchor="end">&#x2666;',
                    _uint2str(_price4),
                    '</text><path d="m69.89 90.51c9.193-20.71 34.17-23.77 54.05-24.26 40.2-0.9805 68.91 66.44 25.92 84.07-23.35 9.575-94.06-41.46-79.97-59.81z" fill="none" stroke="#000" stroke-dasharray="4.33228, 4.33228" stroke-width=".36"/><circle cx="179.1" cy="113.5" r="5.049" fill="url(#b)"/><circle cx="172.9" cy="93.35" r="5.049" fill="url(#c)"/><circle cx="71.85" cy="129.7" r="4.776" fill="#ccc"/><rect x="72.8" y="68.7" width="5.393" height="5.393" fill="#0000a3"/><path d="m203.6 176.5-0.1851-34.61-24.33 46.7-9.956-37z" fill="url(#h)"/><path d="m117.8 254.5 16.51-20.12-7.781-68.29-6.04 1.078-2.685 87.33" fill="url(#f)"/><circle cx="128.9" cy="119" r="7.07" fill="url(#d)"/><path d="m106 22.87c9.226 0.8628-17.95-1.938-14.88 0.363 6.074 4.555 7.742 3.429 15.61 3.63 3.671 0.09413 12.47-2.21 9.439-3.993-5.033-2.96-26.56-4.111-28.68-0.7261-2.626 4.202 14.69 3.63 16.7 3.63 1.698 0 6.284 0.838 5.083-0.363-5.731-5.731-35.26-1.297-41.02 0.363-1.677 0.4828-4.545 3.763-2.904 4.356 13.27 4.8 59.02 1.815 75.87 1.815 5.088 0-10.16-0.5973-15.25-0.7261-21.74-0.5504-50.96-3.336-71.52 3.993-4.194 1.495-9.987 4.627-9.802 9.076 0.1865 4.475 6.148 7.413 10.53 8.35 16.31 3.488 55.81 4.294 74.06 0 2.504-0.5893 7.307-4.517 5.083-5.809-5.981-3.473-22.76-1.02-29.04 2.904" fill="none" stroke="#000" stroke-width=".26"/><path d="m163.4 39.57c0.6051-0.8471 0.8405-2.907 1.815-2.541 1.183 0.4436-0.1743 3.63 1.089 3.63 3.146 0 8.713-6.777 8.713-3.63 0 33.54-39.24 0.9874-24.69-7.624 5.32-3.149 30.69-5.926 36.67-0.363 9.63 8.965-14.1 10.89-18.15 10.89-4.184 0-6.976-1.163-10.89-1.815" fill="none" stroke="#000" stroke-width=".26"/><path d="m66.12 206.4-56.48 54.92-0.002098-251.6 33.97 76.75 22.5 120" fill="#fce7e7"/><path d="m9.645 9.642 33.95 76.72 22.5 120v-134.5z" fill="url(#i)" opacity=".13"/></g></svg>'
                )
            );
        } else if (tokenId == 5) {
            output = string(
                abi.encodePacked(
                    '<svg height="100%" version="1.1" viewBox="0 0 271 271" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"><style>.t{font: bold 14px Courier New;}</style><defs><linearGradient id="a" x1="4.822" x2="262.5" y1="244.2" y2="244.2" gradientTransform="translate(-.31 -.36)" gradientUnits="userSpaceOnUse"><stop stop-color="#ffe4ee" offset="0"/><stop stop-color="#ffffe2" stop-opacity="0" offset="1"/></linearGradient></defs><g><rect x="4.822" y="4.822" width="261.3" height="261.3" stroke="#e02d2d" stroke-width="9.6"/><path d="m66.12 206.4 194.8 19 0.4126 35.89-251.6 0.0339z" fill="url(#a)" stroke-width="9"/><circle cx="170.6" cy="92.61" r="35.38" fill="#08ff04"/><circle cx="120.9" cy="105.1" r="43.66" fill="#d800dc"/><text x="134.6772" y="106.2739" class="t" text-anchor="end">&#x2666;',
                    _uint2str(_price5),
                    '</text><path d="m69.89 90.51c9.193-20.71 34.17-23.77 54.05-24.26 40.2-0.9805 68.91 66.44 25.92 84.07-23.35 9.575-94.06-41.46-79.97-59.81z" fill="none" stroke="#fff" stroke-dasharray="4.33228, 4.33228" stroke-width=".36"/><circle cx="179.1" cy="113.5" r="5.049" fill="#fbff15"/><circle cx="172.9" cy="93.35" r="5.049" fill="#2acf57"/><circle cx="71.85" cy="129.7" r="4.776" fill="#ccc"/><rect x="72.8" y="68.7" width="5.393" height="5.393" fill="#0000a3"/><path d="m203.6 176.5-0.1851-34.61-24.33 46.7-9.956-37z" fill="#1000f5"/><path d="m117.8 254.5 16.51-20.12-7.781-68.29-6.04 1.078-2.685 87.33" fill="#f50000"/><circle cx="128.9" cy="119" r="7.07" fill="#ff1515"/><path d="m106 22.87c9.226 0.8628-17.95-1.938-14.88 0.363 6.074 4.555 7.742 3.429 15.61 3.63 3.671 0.09413 12.47-2.21 9.439-3.993-5.033-2.96-26.56-4.111-28.68-0.7261-2.626 4.202 14.69 3.63 16.7 3.63 1.698 0 6.284 0.838 5.083-0.363-5.731-5.731-35.26-1.297-41.02 0.363-1.677 0.4828-4.545 3.763-2.904 4.356 13.27 4.8 59.02 1.815 75.87 1.815 5.088 0-10.16-0.5973-15.25-0.7261-21.74-0.5504-50.96-3.336-71.52 3.993-4.194 1.495-9.987 4.627-9.802 9.076 0.1865 4.475 6.148 7.413 10.53 8.35 16.31 3.488 55.81 4.294 74.06 0 2.504-0.5893 7.307-4.517 5.083-5.809-5.981-3.473-22.76-1.02-29.04 2.904" fill="none" stroke="#fff" stroke-width=".26"/><path d="m163.4 39.57c0.6051-0.8471 0.8405-2.907 1.815-2.541 1.183 0.4436-0.1743 3.63 1.089 3.63 3.146 0 8.713-6.777 8.713-3.63 0 33.54-39.24 0.9874-24.69-7.624 5.32-3.149 30.69-5.926 36.67-0.363 9.63 8.965-14.1 10.89-18.15 10.89-4.184 0-6.976-1.163-10.89-1.815" fill="none" stroke="#0c6900" stroke-width=".26"/><path d="m66.12 206.4-56.48 54.92 0.003101-251.7 33.97 76.76 22.5 120" fill="#18c5ca"/><path d="m9.644 9.642 33.97 76.76 22.5 120v-134.5z" fill="#fff944"/></g></svg>'
                )
            );
        } else if (tokenId == 6) {
            output = string(
                abi.encodePacked(
                    '<svg height="100%" version="1.1" viewBox="0 0 271 271" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"><style>.t{font: bold 23px Courier New;}</style><defs><linearGradient id="a" x1="-144.4" x2="-106.9" y1="-90.63" y2="-93.98" gradientTransform="matrix(1.614 0 0 1.614 55.35 29.3)" gradientUnits="userSpaceOnUse"><stop offset="0"/><stop stop-color="#ea00d8" offset=".29"/><stop stop-color="#00f93e" stop-opacity=".35" offset=".67"/><stop stop-opacity="0" offset="1"/></linearGradient></defs><text transform="rotate(185.1)" x="-146.4395" y="-109.63757" fill="url(#a)" class="t" text-anchor="middle">&#x2666;',
                    _uint2str(_price6),
                    "</text></svg>"
                )
            );
        } else {
            output = "";
        }

        return output;
    }

    function _beforeTokenTransfer(
        address from,
        address, /*to*/
        uint256 tokenId
    ) internal virtual {
        if (from == address(0)) return;

        if (tokenId == 1) {
            _price1 += 1;
        } else if (tokenId == 2) {
            _price2 += 10;
        } else if (tokenId == 3) {
            _price3 += 50;
        } else if (tokenId == 4) {
            _price4 += 100;
        } else if (tokenId == 5) {
            _price5 += 200;
        } else if (tokenId == 6) {
            _price6 += 1000;
        }
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory uri)
    {
        require(_exists(tokenId), "Err");

        string memory tname;
        string memory description;

        if (tokenId == 1) {
            tname = "Counter. Clarity 1/6";
            description = "The price in the picture increases by 1 eth on each transfer";
        } else if (tokenId == 2) {
            tname = "Unstable coin. Clarity 2/6";
            description = "The price in the picture increases by 10 eth on each transfer";
        } else if (tokenId == 3) {
            tname = "Life. Clarity 3/6";
            description = "The price in the picture increases by 50 eth on each transfer";
        } else if (tokenId == 4) {
            tname = "Crypto clowns. Clarity 4/6";
            description = "The price in the picture increases by 100 eth on each transfer";
        } else if (tokenId == 5) {
            tname = "Nightmare. Clarity 5/6";
            description = "The price in the picture increases by 200 eth on each transfer";
        } else if (tokenId == 6) {
            tname = "Clarity? Clarity 6/6";
            description = "The price in the picture increases by 1000 eth on each transfer";
        }

        string memory image = tokenSvg(tokenId);

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                tname,
                                '", "description":"',
                                description,
                                '", "image":"data:image/svg+xml;base64,',
                                Base64.encode(bytes(image)),
                                '"}'
                            )
                        )
                    )
                )
            );
    }

    function _uint2str(uint256 i) private pure returns (string memory str) {
        if (i == 0) {
            return "0";
        }

        uint256 j = i;
        uint256 length;
        while (j != 0) {
            length++;
            j /= 10;
        }

        bytes memory bstr = new bytes(length);
        uint256 k = length;
        j = i;
        while (j != 0) {
            bstr[--k] = bytes1(uint8(48 + (j % 10)));
            j /= 10;
        }
        return string(bstr);
    }
}