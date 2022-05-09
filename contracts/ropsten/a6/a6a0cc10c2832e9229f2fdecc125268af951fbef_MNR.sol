/**
 *Submitted for verification at Etherscan.io on 2022-05-09
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;



/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     */
    function supportsInterface(bytes4 _interfaceId) external view returns (bool);
}


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 {
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
    function balanceOf(address _owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `_tokenId` token.
     *
     * Requirements:
     *
     * - `_tokenId` must exist.
     */
    function ownerOf(uint256 _tokenId) external view returns (address _owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `_from` cannot be the zero address.
     * - `_to` cannot be the zero address.
     * - `_tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `_from` cannot be the zero address.
     * - `_to` cannot be the zero address.
     * - `_tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `_from` cannot be the zero address.
     * - `_to` cannot be the zero address.
     * - `_tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address _from, address _to, uint256 _tokenId) external;

    /**
     * @dev Gives permission to `_to` to transfer `_tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `_tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address _to, uint256 _tokenId) external;

    /**
     * @dev Approve or remove `_operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `_operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address _operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `_tokenId` token.
     *
     * Requirements:
     *
     * - `_tokenId` must exist.
     */
    function getApproved(uint256 _tokenId) external view returns (address _operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}


/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata {
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
    function tokenURI(uint256 _tokenId) external view returns (string memory);
}


/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `_tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `_operator` from `_from`, this function is called.
     *
     * @return result 
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
     /// @param _operator operator address
     /// @param _from from address
     /// @param _tokenId token id
     /// @param _data calldata
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external returns (bytes4 result);
}


/**
 * @title The ERC165 impl
 * @author NathanCho [email protected]
 * @notice Explain to an end user what this does
 * @dev ERC165 인터페이스 검증 구현
 */
abstract contract ERC165 is IERC165 {
    
    /// @dev ERC165 supportsInterface(bytes4) function override
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165) returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
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


    function toString(address x) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2*i] = char(hi);
            s[2*i+1] = char(lo);            
        }
        return string(s);
    }

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }    
}


/**
 * @title v
 * @author NathanCho [email protected]
 * @notice Explain to an end user what this does
 * @dev Smart Contract 내 공유 목적으로 사용
 */
abstract contract Context {
    enum OperatorType {
        MINT,
        BURN
    }

    enum OperatorActionType {
        PERMIT,
        DENY
    }

    address private contractOwner;

    mapping(address => bool) private operatorMint;

    mapping(address => bool) private operatorBurn;

    modifier checkContractOwnerOnly(address _contractOwner, string memory _errorMessage) {
        require(contractOwner == _contractOwner, _errorMessage);
        _;
    }
    modifier checkOperatorOnly(OperatorType _operatorType, address _operator, string memory _errorMessage) {
        if(_operatorType == OperatorType.MINT) {
            require(operatorMint[_operator], _errorMessage);
        }
        _;
    }

    event logOperator(OperatorType _opertatorType, address _from, address _to, OperatorActionType _operatorActionType);

    constructor(address _contractOwner) {
        contractOwner = _contractOwner;
    }

    function isOperator(OperatorType _operatorType, address _mintOperator) internal view returns(bool) {
        if(_operatorType == OperatorType.MINT) {
            return operatorMint[_mintOperator];
        } else if(_operatorType == OperatorType.BURN) {
            return operatorBurn[_mintOperator];
        }
        return false;
    }

    function modifyOperator(OperatorType _operatorType, address _from, address _to, OperatorActionType _operatorActionType) public checkContractOwnerOnly(msg.sender, "Context: modify operator contract owner only service") {
        if(_operatorType == OperatorType.MINT) {
            if(_operatorActionType == OperatorActionType.PERMIT) {
                require(operatorMint[_to] == false, "already registerd operator");
                operatorMint[_to] = true;
                emit logOperator(_operatorType, _from, _to, _operatorActionType);
            } else if(_operatorActionType == OperatorActionType.DENY) {
                require(operatorMint[_to] == true, "not registerd operator");
                operatorMint[_to] = false;
                emit logOperator(_operatorType, _from, _to, _operatorActionType);
            }
        } else if(_operatorType == OperatorType.BURN) {
            if(_operatorActionType == OperatorActionType.PERMIT) {
                require(operatorBurn[_to] == false, "already registerd operator");
                operatorBurn[_to] = true;
                emit logOperator(_operatorType, _from, _to, _operatorActionType);
            } else if(_operatorActionType == OperatorActionType.DENY) {
                require(operatorBurn[_to] == true, "not registerd operator");
                operatorBurn[_to] = false;
                emit logOperator(_operatorType, _from, _to, _operatorActionType);
            }
        }
    }

    function addOperatorForMint(address _to) external {
        modifyOperator(OperatorType.MINT, msg.sender, _to, OperatorActionType.PERMIT);
    }
    function removeOperatorForMint(address _to) external {
        modifyOperator(OperatorType.MINT, msg.sender, _to, OperatorActionType.DENY);
    }
    function addOperatorForBurn(address _to) external {
        modifyOperator(OperatorType.BURN, msg.sender, _to, OperatorActionType.PERMIT);
    }
    function removeOperatorForBurn(address _to) external {
        modifyOperator(OperatorType.BURN, msg.sender, _to, OperatorActionType.DENY);
    }

    /// @notice Token ID 존재여부 확인
    /// @dev 관련 Contract(ERC721)으로 위임하여 처리
    /// @param _tokenId 조회할 Token ID
    /// @return Token 존재여부
    function deligateIsTokenIdExist(uint256 _tokenId) internal view virtual returns (bool);

}


/**
 * @title The ERC721 metadata impl
 * @author NathanCho [email protected]
 * @notice Explain to an end user what this does
 * @dev ERC721 metadata 인터페이스 구현
 */
abstract contract ERC721Metadata is Context, IERC165, IERC721Metadata {
    using Strings for uint256;

    constructor(string memory _name, string memory _symbol) {
        tokenName = _name;
        tokenSymbol = _symbol;
    }

    // Token name
    string private tokenName;

    // Token symbol
    string private tokenSymbol;

    // Token Base URI
    // tokenURI = ${tokenBaseURI} + {tokenId}
    string private tokenBaseURI = "";

    // Token URI
    mapping(uint256 => string) private tokenURIs;

    /// @dev IERC721Metadata name() function implementation
    /// @return name the token collection name
    function name() external view override returns (string memory) {
        return tokenName;
    }

    /// @dev IERC721Metadata symbol() function implementation
    /// @return Returns the token collection symbol
    function symbol() external view override returns (string memory) {
        return tokenSymbol;
    }

    /// @dev IERC721Metadata tokenURI(uint256) function implementation
    /// @param tokenId 확인하려는 Token ID
    /// @return Returns the Uniform Resource Identifier (URI) for `tokenId` token
    function tokenURI(uint256 tokenId) external view override returns (string memory) {
        require(deligateIsTokenIdExist(tokenId), "ERC721Metadata: non-existent token");
        return bytes(tokenBaseURI).length > 0 ? string(abi.encodePacked(tokenBaseURI, tokenId.toString())) : "";
    }

    function setTokenBaseURI(string memory _tokenBaseURI) public checkContractOwnerOnly(msg.sender, "ERC721Metadata: set token base URI only contract owner service") {
        tokenBaseURI = _tokenBaseURI;
    }

    function getTokenBaseURI() public view checkContractOwnerOnly(msg.sender, "ERC721Metadata: get token base URI only contract owner service")  returns(string memory) {
        return tokenBaseURI;
    }

    /// @dev ERC165 supportsInterface(bytes4) function override
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165) returns (bool) {
        return interfaceId == type(IERC721Metadata).interfaceId;
    }
}


/**
 * @title The ERC721 impl
 * @author NathanCho [email protected]
 * @notice Explain to an end user what this does
 * @dev ERC721 구현
 */
abstract contract ERC721 is Context, IERC165, IERC721 {
    using Strings for address;
    using Address for address;
    using Strings for uint256;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private tokenOwners;

    mapping(uint256 => bool) private tokenBurns;

    // Mapping owner address to token count
    mapping(address => uint256) private tokenBalances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private operatorApprovals;

    /// @dev IERC721 balanceOf(address) function implementation
    function balanceOf(address _ownerAddress) override external view returns (uint256 balance) {
        require(_ownerAddress != address(0), "ERC721: address zero is not a valid owner");
        return tokenBalances[_ownerAddress];
    }

    /// @dev IERC721 ownerOf(uint256) function implementation
    function ownerOf(uint256 _tokenId) override public view returns (address) {
        address tokenOwner = tokenOwners[_tokenId];
        require(tokenOwner != address(0), "ERC721: non-existent token");
        return tokenOwner;
    }

    /// @dev IERC721 safeTransferFrom(address, address, uint256, bytes calldata) function implementation
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory _data) override  public {
        require(isApprovedOrOwner(msg.sender, _tokenId), "ERC721: transfer caller is not owner nor approved");
        doSafeTransfer(_from, _to, _tokenId, _data);
    }

    /// @dev IERC721 safeTransferFrom(address, address, uint256) function implementation
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) override  public {
        safeTransferFrom(_from, _to, _tokenId, "");
    }

    /// @dev IERC721 transferFrom(address, address, uint256) function implementation
    function transferFrom(address _from, address _to, uint256 _tokenId) override public {
        require(isApprovedOrOwner(msg.sender, _tokenId), "ERC721: transfer caller is not owner nor approved");
        doTransfer(_from, _to, _tokenId);
    }

    function doSafeTransfer(address _from, address _to, uint256 _tokenId, bytes memory _data) internal virtual {
        doTransfer(_from, _to, _tokenId);
        require(doCheckOnERC721Received(_from, _to, _tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function doTransfer(address _from, address _to, uint256 _tokenId) internal virtual {
        require(ownerOf(_tokenId) == _from, "ERC721: transfer from incorrect owner");
        require(_to != address(0), "ERC721: transfer to the zero address");

        // before transfer token check
        doBeforeTokenTransfer(_from, _to, _tokenId);

        // 기존 승인 제거
        doApprovalsClear(address(0), _tokenId);

        // 토큰 이체 및 주인변경
        tokenBalances[_from] -= 1;
        tokenBalances[_to] += 1;
        tokenOwners[_tokenId] = _to;

        // Transfer logging
        emit Transfer(_from, _to, _tokenId);

        // after transfer token check
        doAfterTokenTransfer(_from, _to, _tokenId);
    }

    /// @dev IERC721 approve(address, uint256) function implementation
    function approve(address _to, uint256 _tokenId) override public {
        address tokenOwner = ownerOf(_tokenId);
        require(_to != tokenOwner, "ERC721: approval to current token owner");
        require(msg.sender == tokenOwner || isApprovedForAll(tokenOwner, msg.sender), "ERC721: approve caller is not owner nor approved for all");

        doApprove(_to, _tokenId);
    }

    function doApprove(address _to, uint256 _tokenId) internal {
        tokenApprovals[_tokenId] = _to;
        emit Approval(ownerOf(_tokenId), _to, _tokenId);
    }

    /// @dev IERC721 setApprovalForAll(address, bool) function implementation
    function setApprovalForAll(address _operator, bool _approved) override public {
        doSetApprovalForAll(msg.sender, _operator, _approved);
    }

    function doSetApprovalForAll(address _tokenOwner, address _operator, bool _approved) internal {
        require(_tokenOwner != _operator, "ERC721: token owner is MUST NOT equal to operator");
        operatorApprovals[_tokenOwner][_operator] = _approved;
        emit ApprovalForAll(_tokenOwner, _operator, _approved);
    }    

    /// @dev IERC721 getApproved(uint256 tokenId) function implementation
    function getApproved(uint256 _tokenId) override public view returns (address _operator) {
        return tokenApprovals[_tokenId];
    }

    /// @dev IERC721 isApprovedForAll(address, address) function implementation
    function isApprovedForAll(address _tokenOwner, address _operator) override public view returns (bool) {
        return operatorApprovals[_tokenOwner][_operator];
    }

    /// @dev ERC165 supportsInterface(bytes4) function override
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165) returns (bool) {
        return interfaceId == type(IERC721).interfaceId;
    }

    function getTokenOwnerAddress(uint256 _tokenId) internal view returns(address) {
        return tokenOwners[_tokenId];
    }

    function isTokenIdExist(uint256 _tokenId) internal view virtual returns (bool) {
        return tokenOwners[_tokenId] != address(0);
    }

    function isApprovedOrOwner(address _spender, uint256 _tokenId) internal view returns (bool) {
        require(isTokenIdExist(_tokenId), "ERC721: operator query for nonexistent token");
        address tokenOwner = ownerOf(_tokenId);
        return (_spender == tokenOwner || isApprovedForAll(tokenOwner, _spender) || getApproved(_tokenId) == _spender);
    }

    function doTokenSafeMint(address _to, uint256 _tokenId) public {
        doTokenSafeMint(_to, _tokenId, "");
    }

    function doTokenSafeMint(address _to, uint256 _tokenId, bytes memory _data) public {
        doTokenMint(_to, _tokenId);
        require(doCheckOnERC721Received(address(0), _to, _tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function doTokenMint(address _to, uint256 _tokenId) public checkOperatorOnly(OperatorType.MINT, msg.sender, "ERC721: doTokenMint: operator only service") {
        require(_to != address(0), "ERC721: mint to the zero address");
        require(isTokenIdExist(_tokenId) == false, "ERC721: token already minted");

        // before transfer token check
        doBeforeTokenTransfer(address(0), _to, _tokenId);

        // 토큰 transfer
        tokenBalances[_to] += 1;
        tokenOwners[_tokenId] = _to;

        // Transfer logging
        emit Transfer(address(0), _to, _tokenId);

        // after transfer token check
        doAfterTokenTransfer(address(0), _to, _tokenId);
    }

    function doTokenBurn(uint256 _tokenId) public checkOperatorOnly(OperatorType.MINT, msg.sender, "ERC721: doTokenBurn: operator only service") {
        address tokenOwner = ownerOf(_tokenId);

        // before burn token check
        doBeforeTokenTransfer(tokenOwner, address(0), _tokenId);

        // 기존 승인 제거
        doApprovalsClear(address(0), _tokenId);

        // 토큰 제거
        tokenBalances[tokenOwner] -= 1;
        delete tokenOwners[_tokenId];
        tokenBurns[_tokenId] = true;

        // Transfer logging
        emit Transfer(tokenOwner, address(0), _tokenId);

        // after burn token check
        doAfterTokenTransfer(tokenOwner, address(0), _tokenId);
    }

    function doApprovalsClear(address _to, uint256 _tokenId) internal {
        tokenApprovals[_tokenId] = _to;
        emit Approval(ownerOf(_tokenId), _to, _tokenId);
    }

function doCheckOnERC721Received(address _from, address _to, uint256 _tokenId, bytes memory _data) internal virtual returns (bool) {
        if (_to.isContract()) {
            try IERC721Receiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721Receiver: transfer to non ERC721Receiver implementer");
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

    function doBeforeTokenTransfer(address _from, address _to, uint256 _tokenId) view internal {
        require(_from != address(0) || _to != address(0), string(abi.encodePacked("ERC721: doBeforeTokenTransfer: not allow addresses('", _from.toString(), ", ", _to.toString() , " ) both zero")));
        require(tokenOwners[_tokenId] == _from, string(abi.encodePacked("ERC721: doBeforeTokenTransfer: '", _from.toString(), "' address is not owner of '", _tokenId.toString(), "'")));
        require(tokenBurns[_tokenId] == false, string(abi.encodePacked("ERC721: doBeforeTokenTransfer: the tokenId('", _tokenId.toString(), "') is already burned")));
    }

    function doAfterTokenTransfer(address _from, address _to, uint256 _tokenId) view internal {
        require(_from != address(0) || _to != address(0), string(abi.encodePacked("ERC721: doAfterTokenTransfer: not allow addresses('", _from.toString(), ", ", _to.toString() , " ) both zero")));
        require(tokenOwners[_tokenId] == _to, string(abi.encodePacked("ERC721: doAfterTokenTransfer: the tokenId('", _tokenId.toString(), "') NOT transfer to '", _to.toString(), "' address")));
        require(tokenApprovals[_tokenId] == address(0), string(abi.encodePacked("ERC721: doAfterTokenTransfer: the tokenId('", _tokenId.toString(), "') approval is not clear after transfer")));
    }
}






/**
 * @title The Metaverse NFT Research(MNR Token)
 * @author NathanCho [email protected]
 * @notice Explain to an end user what this does
 * @dev 메타버스 NFT 리서치
 */
contract MNR is Context, ERC165, ERC721, ERC721Metadata {

    constructor(string memory _tokenName, string memory _tokenSymbol) 
        Context(msg.sender)
        ERC721Metadata(_tokenName, _tokenSymbol)
    {}

    /// @dev supportsInterface(bytes4) function override
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, ERC721, ERC721Metadata) returns (bool) {
        return
            ERC165.supportsInterface(interfaceId) ||
            ERC721.supportsInterface(interfaceId) ||
            ERC721Metadata.supportsInterface(interfaceId)
            ;
    }
    
    function deligateIsTokenIdExist(uint256 _tokenId) internal view override(Context) returns (bool) {
        return ERC721.getTokenOwnerAddress(_tokenId) != address(0);
    }

}