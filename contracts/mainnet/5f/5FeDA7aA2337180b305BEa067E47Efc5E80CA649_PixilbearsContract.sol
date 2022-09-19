/**
 *Submitted for verification at Etherscan.io on 2022-09-19
*/

//*********************************************************************//
//*********************************************************************//
//
//
//            _      _ __   ____                 
//     ____  (_)  __(_) /  / __ )___  ____ ______
//    / __ \/ / |/_/ / /  / __  / _ \/ __ `/ ___/
//   / /_/ / />  </ / /  / /_/ /  __/ /_/ / /    
//  / .___/_/_/|_/_/_/  /_____/\___/\__,_/_/     
// /_/                                           
//
//
//*********************************************************************//
//*********************************************************************//
  
//-------------DEPENDENCIES--------------------------//

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if account is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, isContract will return false for the following
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
     * You shouldn't rely on isContract to protect against flash loan attacks!
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
     * @dev Replacement for Solidity's transfer: sends amount wei to
     * recipient, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by transfer, making them unable to receive funds via
     * transfer. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to recipient, care must be
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
     * @dev Performs a Solidity function call using a low level call. A
     * plain call is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If target reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[abi.decode].
     *
     * Requirements:
     *
     * - target must be a contract.
     * - calling target with data must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[functionCall], but with
     * errorMessage as a fallback revert reason when target reverts.
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[functionCall],
     * but also transferring value wei to target.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least value.
     * - the called Solidity function must be payable.
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
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[functionCallWithValue], but
     * with errorMessage as a fallback revert reason when target reverts.
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[functionCall],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[functionCall],
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[functionCall],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[functionCall],
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
     * @dev Whenever an {IERC721} tokenId token is transferred to this contract via {IERC721-safeTransferFrom}
     * by operator from from, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with IERC721.onERC721Received.selector.
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
     * interfaceId. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;


/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * 
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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when tokenId token is transferred from from to to.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when owner enables approved to manage the tokenId token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when owner enables or disables (approved) operator to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in owner's account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the tokenId token.
     *
     * Requirements:
     *
     * - tokenId must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers tokenId token from from to to, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - from cannot be the zero address.
     * - to cannot be the zero address.
     * - tokenId token must exist and be owned by from.
     * - If the caller is not from, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If to refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers tokenId token from from to to.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - from cannot be the zero address.
     * - to cannot be the zero address.
     * - tokenId token must be owned by from.
     * - If the caller is not from, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to to to transfer tokenId token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - tokenId must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for tokenId token.
     *
     * Requirements:
     *
     * - tokenId must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove operator as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The operator cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the operator is allowed to manage all of the assets of owner.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers tokenId token from from to to.
     *
     * Requirements:
     *
     * - from cannot be the zero address.
     * - to cannot be the zero address.
     * - tokenId token must exist and be owned by from.
     * - If the caller is not from, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If to refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
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

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

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
     * @dev Returns a token ID owned by owner at a given index of its token list.
     * Use along with {balanceOf} to enumerate all of owner's tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given index of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
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
     * @dev Returns the Uniform Resource Identifier (URI) for tokenId token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// File: @openzeppelin/contracts/utils/Strings.sol


// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a uint256 to its ASCII string decimal representation.
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
     * @dev Converts a uint256 to its ASCII string hexadecimal representation.
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
     * @dev Converts a uint256 to its ASCII string hexadecimal representation with fixed length.
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

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from ReentrancyGuard will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single nonReentrant guard, functions marked as
 * nonReentrant may not call one another. This can be worked around by making
 * those functions private, and then adding external nonReentrant entry
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
     * Calling a nonReentrant function from another nonReentrant
     * function is not supported. It is possible to prevent this from happening
     * by making the nonReentrant function external, and making it call a
     * private function that does the actual work.
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

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
 * onlyOwner, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
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
     * onlyOwner functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (newOwner).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (newOwner).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
//-------------END DEPENDENCIES------------------------//


  
// Rampp Contracts v2.1 (Teams.sol)

pragma solidity ^0.8.0;

/**
* Teams is a contract implementation to extend upon Ownable that allows multiple controllers
* of a single contract to modify specific mint settings but not have overall ownership of the contract.
* This will easily allow cross-collaboration via Mintplex.xyz.
**/
abstract contract Teams is Ownable{
  mapping (address => bool) internal team;

  /**
  * @dev Adds an address to the team. Allows them to execute protected functions
  * @param _address the ETH address to add, cannot be 0x and cannot be in team already
  **/
  function addToTeam(address _address) public onlyOwner {
    require(_address != address(0), "Invalid address");
    require(!inTeam(_address), "This address is already in your team.");
  
    team[_address] = true;
  }

  /**
  * @dev Removes an address to the team.
  * @param _address the ETH address to remove, cannot be 0x and must be in team
  **/
  function removeFromTeam(address _address) public onlyOwner {
    require(_address != address(0), "Invalid address");
    require(inTeam(_address), "This address is not in your team currently.");
  
    team[_address] = false;
  }

  /**
  * @dev Check if an address is valid and active in the team
  * @param _address ETH address to check for truthiness
  **/
  function inTeam(address _address)
    public
    view
    returns (bool)
  {
    require(_address != address(0), "Invalid address to check.");
    return team[_address] == true;
  }

  /**
  * @dev Throws if called by any account other than the owner or team member.
  */
  modifier onlyTeamOrOwner() {
    bool _isOwner = owner() == _msgSender();
    bool _isTeam = inTeam(_msgSender());
    require(_isOwner || _isTeam, "Team: caller is not the owner or in Team.");
    _;
  }
}


  
  
/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata and Enumerable extension. Built to optimize for lower gas during batch mints.
 *
 * Assumes serials are sequentially minted starting at _startTokenId() (defaults to 0, e.g. 0, 1, 2, 3..).
 * 
 * Assumes the number of issuable tokens (collection size) is capped and fits in a uint128.
 *
 * Does not support burning tokens to address(0).
 */
contract ERC721A is
  Context,
  ERC165,
  IERC721,
  IERC721Metadata,
  IERC721Enumerable,
  Teams
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

  uint256 private currentIndex;

  uint256 public immutable collectionSize;
  uint256 public maxBatchSize;

  // Token name
  string private _name;

  // Token symbol
  string private _symbol;

  // Mapping from token ID to ownership details
  // An empty struct value does not necessarily mean the token is unowned. See ownershipOf implementation for details.
  mapping(uint256 => TokenOwnership) private _ownerships;

  // Mapping owner address to address data
  mapping(address => AddressData) private _addressData;

  // Mapping from token ID to approved address
  mapping(uint256 => address) private _tokenApprovals;

  // Mapping from owner to operator approvals
  mapping(address => mapping(address => bool)) private _operatorApprovals;

  /* @dev Mapping of restricted operator approvals set by contract Owner
  * This serves as an optional addition to ERC-721 so
  * that the contract owner can elect to prevent specific addresses/contracts
  * from being marked as the approver for a token. The reason for this
  * is that some projects may want to retain control of where their tokens can/can not be listed
  * either due to ethics, loyalty, or wanting trades to only occur on their personal marketplace.
  * By default, there are no restrictions. The contract owner must deliberatly block an address 
  */
  mapping(address => bool) public restrictedApprovalAddresses;

  /**
   * @dev
   * maxBatchSize refers to how much a minter can mint at a time.
   * collectionSize_ refers to how many tokens are in the collection.
   */
  constructor(
    string memory name_,
    string memory symbol_,
    uint256 maxBatchSize_,
    uint256 collectionSize_
  ) {
    require(
      collectionSize_ > 0,
      "ERC721A: collection must have a nonzero supply"
    );
    require(maxBatchSize_ > 0, "ERC721A: max batch size must be nonzero");
    _name = name_;
    _symbol = symbol_;
    maxBatchSize = maxBatchSize_;
    collectionSize = collectionSize_;
    currentIndex = _startTokenId();
  }

  /**
  * To change the starting tokenId, please override this function.
  */
  function _startTokenId() internal view virtual returns (uint256) {
    return 1;
  }

  /**
   * @dev See {IERC721Enumerable-totalSupply}.
   */
  function totalSupply() public view override returns (uint256) {
    return _totalMinted();
  }

  function currentTokenId() public view returns (uint256) {
    return _totalMinted();
  }

  function getNextTokenId() public view returns (uint256) {
      return _totalMinted() + 1;
  }

  /**
  * Returns the total amount of tokens minted in the contract.
  */
  function _totalMinted() internal view returns (uint256) {
    unchecked {
      return currentIndex - _startTokenId();
    }
  }

  /**
   * @dev See {IERC721Enumerable-tokenByIndex}.
   */
  function tokenByIndex(uint256 index) public view override returns (uint256) {
    require(index < totalSupply(), "ERC721A: global index out of bounds");
    return index;
  }

  /**
   * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
   * This read function is O(collectionSize). If calling from a separate contract, be sure to test gas first.
   * It may also degrade with extremely large collection sizes (e.g >> 10000), test for your use case.
   */
  function tokenOfOwnerByIndex(address owner, uint256 index)
    public
    view
    override
    returns (uint256)
  {
    require(index < balanceOf(owner), "ERC721A: owner index out of bounds");
    uint256 numMintedSoFar = totalSupply();
    uint256 tokenIdsIdx = 0;
    address currOwnershipAddr = address(0);
    for (uint256 i = 0; i < numMintedSoFar; i++) {
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
    revert("ERC721A: unable to get token of owner by index");
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
    require(owner != address(0), "ERC721A: balance query for the zero address");
    return uint256(_addressData[owner].balance);
  }

  function _numberMinted(address owner) internal view returns (uint256) {
    require(
      owner != address(0),
      "ERC721A: number minted query for the zero address"
    );
    return uint256(_addressData[owner].numberMinted);
  }

  function ownershipOf(uint256 tokenId)
    internal
    view
    returns (TokenOwnership memory)
  {
    uint256 curr = tokenId;

    unchecked {
        if (_startTokenId() <= curr && curr < currentIndex) {
            TokenOwnership memory ownership = _ownerships[curr];
            if (ownership.addr != address(0)) {
                return ownership;
            }

            // Invariant:
            // There will always be an ownership that has an address and is not burned
            // before an ownership that does not have an address and is not burned.
            // Hence, curr will not underflow.
            while (true) {
                curr--;
                ownership = _ownerships[curr];
                if (ownership.addr != address(0)) {
                    return ownership;
                }
            }
        }
    }

    revert("ERC721A: unable to determine the owner of token");
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
    string memory baseURI = _baseURI();
    return
      bytes(baseURI).length > 0
        ? string(abi.encodePacked(baseURI, tokenId.toString()))
        : "";
  }

  /**
   * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
   * token will be the concatenation of the baseURI and the tokenId. Empty
   * by default, can be overriden in child contracts.
   */
  function _baseURI() internal view virtual returns (string memory) {
    return "";
  }

  /**
   * @dev Sets the value for an address to be in the restricted approval address pool.
   * Setting an address to true will disable token owners from being able to mark the address
   * for approval for trading. This would be used in theory to prevent token owners from listing
   * on specific marketplaces or protcols. Only modifible by the contract owner/team.
   * @param _address the marketplace/user to modify restriction status of
   * @param _isRestricted restriction status of the _address to be set. true => Restricted, false => Open
   */
  function setApprovalRestriction(address _address, bool _isRestricted) public onlyTeamOrOwner {
    restrictedApprovalAddresses[_address] = _isRestricted;
  }

  /**
   * @dev See {IERC721-approve}.
   */
  function approve(address to, uint256 tokenId) public override {
    address owner = ERC721A.ownerOf(tokenId);
    require(to != owner, "ERC721A: approval to current owner");
    require(restrictedApprovalAddresses[to] == false, "ERC721RestrictedApproval: Address to approve has been restricted by contract owner and is not allowed to be marked for approval");

    require(
      _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
      "ERC721A: approve caller is not owner nor approved for all"
    );

    _approve(to, tokenId, owner);
  }

  /**
   * @dev See {IERC721-getApproved}.
   */
  function getApproved(uint256 tokenId) public view override returns (address) {
    require(_exists(tokenId), "ERC721A: approved query for nonexistent token");

    return _tokenApprovals[tokenId];
  }

  /**
   * @dev See {IERC721-setApprovalForAll}.
   */
  function setApprovalForAll(address operator, bool approved) public override {
    require(operator != _msgSender(), "ERC721A: approve to caller");
    require(restrictedApprovalAddresses[operator] == false, "ERC721RestrictedApproval: Operator address has been restricted by contract owner and is not allowed to be marked for approval");

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
  ) public override {
    _transfer(from, to, tokenId);
    require(
      _checkOnERC721Received(from, to, tokenId, _data),
      "ERC721A: transfer to non ERC721Receiver implementer"
    );
  }

  /**
   * @dev Returns whether tokenId exists.
   *
   * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
   *
   * Tokens start existing when they are minted (_mint),
   */
  function _exists(uint256 tokenId) internal view returns (bool) {
    return _startTokenId() <= tokenId && tokenId < currentIndex;
  }

  function _safeMint(address to, uint256 quantity, bool isAdminMint) internal {
    _safeMint(to, quantity, isAdminMint, "");
  }

  /**
   * @dev Mints quantity tokens and transfers them to to.
   *
   * Requirements:
   *
   * - there must be quantity tokens remaining unminted in the total collection.
   * - to cannot be the zero address.
   * - quantity cannot be larger than the max batch size.
   *
   * Emits a {Transfer} event.
   */
  function _safeMint(
    address to,
    uint256 quantity,
    bool isAdminMint,
    bytes memory _data
  ) internal {
    uint256 startTokenId = currentIndex;
    require(to != address(0), "ERC721A: mint to the zero address");
    // We know if the first token in the batch doesn't exist, the other ones don't as well, because of serial ordering.
    require(!_exists(startTokenId), "ERC721A: token already minted");

    // For admin mints we do not want to enforce the maxBatchSize limit
    if (isAdminMint == false) {
        require(quantity <= maxBatchSize, "ERC721A: quantity to mint too high");
    }

    _beforeTokenTransfers(address(0), to, startTokenId, quantity);

    AddressData memory addressData = _addressData[to];
    _addressData[to] = AddressData(
      addressData.balance + uint128(quantity),
      addressData.numberMinted + (isAdminMint ? 0 : uint128(quantity))
    );
    _ownerships[startTokenId] = TokenOwnership(to, uint64(block.timestamp));

    uint256 updatedIndex = startTokenId;

    for (uint256 i = 0; i < quantity; i++) {
      emit Transfer(address(0), to, updatedIndex);
      require(
        _checkOnERC721Received(address(0), to, updatedIndex, _data),
        "ERC721A: transfer to non ERC721Receiver implementer"
      );
      updatedIndex++;
    }

    currentIndex = updatedIndex;
    _afterTokenTransfers(address(0), to, startTokenId, quantity);
  }

  /**
   * @dev Transfers tokenId from from to to.
   *
   * Requirements:
   *
   * - to cannot be the zero address.
   * - tokenId token must be owned by from.
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
      "ERC721A: transfer caller is not owner nor approved"
    );

    require(
      prevOwnership.addr == from,
      "ERC721A: transfer from incorrect owner"
    );
    require(to != address(0), "ERC721A: transfer to the zero address");

    _beforeTokenTransfers(from, to, tokenId, 1);

    // Clear approvals from the previous owner
    _approve(address(0), tokenId, prevOwnership.addr);

    _addressData[from].balance -= 1;
    _addressData[to].balance += 1;
    _ownerships[tokenId] = TokenOwnership(to, uint64(block.timestamp));

    // If the ownership slot of tokenId+1 is not explicitly set, that means the transfer initiator owns it.
    // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
    uint256 nextTokenId = tokenId + 1;
    if (_ownerships[nextTokenId].addr == address(0)) {
      if (_exists(nextTokenId)) {
        _ownerships[nextTokenId] = TokenOwnership(
          prevOwnership.addr,
          prevOwnership.startTimestamp
        );
      }
    }

    emit Transfer(from, to, tokenId);
    _afterTokenTransfers(from, to, tokenId, 1);
  }

  /**
   * @dev Approve to to operate on tokenId
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

  uint256 public nextOwnerToExplicitlySet = 0;

  /**
   * @dev Explicitly set owners to eliminate loops in future calls of ownerOf().
   */
  function _setOwnersExplicit(uint256 quantity) internal {
    uint256 oldNextOwnerToSet = nextOwnerToExplicitlySet;
    require(quantity > 0, "quantity must be nonzero");
    if (currentIndex == _startTokenId()) revert('No Tokens Minted Yet');

    uint256 endIndex = oldNextOwnerToSet + quantity - 1;
    if (endIndex > collectionSize - 1) {
      endIndex = collectionSize - 1;
    }
    // We know if the last one in the group exists, all in the group exist, due to serial ordering.
    require(_exists(endIndex), "not enough minted yet for this cleanup");
    for (uint256 i = oldNextOwnerToSet; i <= endIndex; i++) {
      if (_ownerships[i].addr == address(0)) {
        TokenOwnership memory ownership = ownershipOf(i);
        _ownerships[i] = TokenOwnership(
          ownership.addr,
          ownership.startTimestamp
        );
      }
    }
    nextOwnerToExplicitlySet = endIndex + 1;
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
        IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data)
      returns (bytes4 retval) {
        return retval == IERC721Receiver(to).onERC721Received.selector;
      } catch (bytes memory reason) {
        if (reason.length == 0) {
          revert("ERC721A: transfer to non ERC721Receiver implementer");
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
   * - When from and to are both non-zero, from's tokenId will be
   * transferred to to.
   * - When from is zero, tokenId will be minted for to.
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
   * - when from and to are both non-zero.
   * - from and to are never both zero.
   */
  function _afterTokenTransfers(
    address from,
    address to,
    uint256 startTokenId,
    uint256 quantity
  ) internal virtual {}
}



  
abstract contract Ramppable {
  address public RAMPPADDRESS = 0xa9dAC8f3aEDC55D0FE707B86B8A45d246858d2E1;

  modifier isRampp() {
      require(msg.sender == RAMPPADDRESS, "Ownable: caller is not RAMPP");
      _;
  }
}


  
  
interface IERC20 {
  function allowance(address owner, address spender) external view returns (uint256);
  function transfer(address _to, uint256 _amount) external returns (bool);
  function balanceOf(address account) external view returns (uint256);
  function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// File: WithdrawableV2
// This abstract allows the contract to be able to mint and ingest ERC-20 payments for mints.
// ERC-20 Payouts are limited to a single payout address. This feature 
// will charge a small flat fee in native currency that is not subject to regular rev sharing.
// This contract also covers the normal functionality of accepting native base currency rev-sharing
abstract contract WithdrawableV2 is Teams, Ramppable {
  struct acceptedERC20 {
    bool isActive;
    uint256 chargeAmount;
  }

  
  mapping(address => acceptedERC20) private allowedTokenContracts;
  address[] public payableAddresses = [RAMPPADDRESS,0x5cCa867939aA9CBbd8757339659bfDbf3948091B,0x92BdA736aD0c8be95e0a0930d840e8da198Be041];
  address[] public surchargePayableAddresses = [RAMPPADDRESS];
  address public erc20Payable = 0x92BdA736aD0c8be95e0a0930d840e8da198Be041;
  uint256[] public payableFees = [1,4,95];
  uint256[] public surchargePayableFees = [100];
  uint256 public payableAddressCount = 3;
  uint256 public surchargePayableAddressCount = 1;
  uint256 public ramppSurchargeBalance = 0 ether;
  uint256 public ramppSurchargeFee = 0.001 ether;
  bool public onlyERC20MintingMode = false;
  

  /**
  * @dev Calculates the true payable balance of the contract as the
  * value on contract may be from ERC-20 mint surcharges and not 
  * public mint charges - which are not eligable for rev share & user withdrawl
  */
  function calcAvailableBalance() public view returns(uint256) {
    return address(this).balance - ramppSurchargeBalance;
  }

  function withdrawAll() public onlyTeamOrOwner {
      require(calcAvailableBalance() > 0);
      _withdrawAll();
  }
  
  function withdrawAllRampp() public isRampp {
      require(calcAvailableBalance() > 0);
      _withdrawAll();
  }

  function _withdrawAll() private {
      uint256 balance = calcAvailableBalance();
      
      for(uint i=0; i < payableAddressCount; i++ ) {
          _widthdraw(
              payableAddresses[i],
              (balance * payableFees[i]) / 100
          );
      }
  }
  
  function _widthdraw(address _address, uint256 _amount) private {
      (bool success, ) = _address.call{value: _amount}("");
      require(success, "Transfer failed.");
  }

  /**
  * @dev This function is similiar to the regular withdraw but operates only on the
  * balance that is available to surcharge payout addresses. This would be Rampp + partners
  **/
  function _withdrawAllSurcharges() private {
    uint256 balance = ramppSurchargeBalance;
    if(balance == 0) { return; }
    
    for(uint i=0; i < surchargePayableAddressCount; i++ ) {
        _widthdraw(
            surchargePayableAddresses[i],
            (balance * surchargePayableFees[i]) / 100
        );
    }
    ramppSurchargeBalance = 0 ether;
  }

  /**
  * @dev Allow contract owner to withdraw ERC-20 balance from contract
  * in the event ERC-20 tokens are paid to the contract for mints. This will
  * send the tokens to the payout as well as payout the surcharge fee to Rampp
  * @param _tokenContract contract of ERC-20 token to withdraw
  * @param _amountToWithdraw balance to withdraw according to balanceOf of ERC-20 token in wei
  */
  function withdrawERC20(address _tokenContract, uint256 _amountToWithdraw) public onlyTeamOrOwner {
    require(_amountToWithdraw > 0);
    IERC20 tokenContract = IERC20(_tokenContract);
    require(tokenContract.balanceOf(address(this)) >= _amountToWithdraw, "WithdrawV2: Contract does not own enough tokens");
    tokenContract.transfer(erc20Payable, _amountToWithdraw); // Payout ERC-20 tokens to recipient
    _withdrawAllSurcharges();
  }

  /**
  * @dev Allow Rampp to be able to withdraw only its ERC-20 payment surcharges from the contract.
  */
  function withdrawRamppSurcharges() public isRampp {
    require(ramppSurchargeBalance > 0, "WithdrawableV2: No Rampp surcharges in balance.");
    _withdrawAllSurcharges();
  }

   /**
  * @dev Helper function to increment Rampp surcharge balance when ERC-20 payment is made.
  */
  function addSurcharge() internal {
    ramppSurchargeBalance += ramppSurchargeFee;
  }
  
  /**
  * @dev Helper function to enforce Rampp surcharge fee when ERC-20 mint is made.
  */
  function hasSurcharge() internal returns(bool) {
    return msg.value == ramppSurchargeFee;
  }

  /**
  * @dev Set surcharge fee for using ERC-20 payments on contract
  * @param _newSurcharge is the new surcharge value of native currency in wei to facilitate ERC-20 payments
  */
  function setRamppSurcharge(uint256 _newSurcharge) public isRampp {
    ramppSurchargeFee = _newSurcharge;
  }

  /**
  * @dev check if an ERC-20 contract is a valid payable contract for executing a mint.
  * @param _erc20TokenContract address of ERC-20 contract in question
  */
  function isApprovedForERC20Payments(address _erc20TokenContract) public view returns(bool) {
    return allowedTokenContracts[_erc20TokenContract].isActive == true;
  }

  /**
  * @dev get the value of tokens to transfer for user of an ERC-20
  * @param _erc20TokenContract address of ERC-20 contract in question
  */
  function chargeAmountForERC20(address _erc20TokenContract) public view returns(uint256) {
    require(isApprovedForERC20Payments(_erc20TokenContract), "This ERC-20 contract is not approved to make payments on this contract!");
    return allowedTokenContracts[_erc20TokenContract].chargeAmount;
  }

  /**
  * @dev Explicity sets and ERC-20 contract as an allowed payment method for minting
  * @param _erc20TokenContract address of ERC-20 contract in question
  * @param _isActive default status of if contract should be allowed to accept payments
  * @param _chargeAmountInTokens fee (in tokens) to charge for mints for this specific ERC-20 token
  */
  function addOrUpdateERC20ContractAsPayment(address _erc20TokenContract, bool _isActive, uint256 _chargeAmountInTokens) public onlyTeamOrOwner {
    allowedTokenContracts[_erc20TokenContract].isActive = _isActive;
    allowedTokenContracts[_erc20TokenContract].chargeAmount = _chargeAmountInTokens;
  }

  /**
  * @dev Add an ERC-20 contract as being a valid payment method. If passed a contract which has not been added
  * it will assume the default value of zero. This should not be used to create new payment tokens.
  * @param _erc20TokenContract address of ERC-20 contract in question
  */
  function enableERC20ContractAsPayment(address _erc20TokenContract) public onlyTeamOrOwner {
    allowedTokenContracts[_erc20TokenContract].isActive = true;
  }

  /**
  * @dev Disable an ERC-20 contract as being a valid payment method. If passed a contract which has not been added
  * it will assume the default value of zero. This should not be used to create new payment tokens.
  * @param _erc20TokenContract address of ERC-20 contract in question
  */
  function disableERC20ContractAsPayment(address _erc20TokenContract) public onlyTeamOrOwner {
    allowedTokenContracts[_erc20TokenContract].isActive = false;
  }

  /**
  * @dev Enable only ERC-20 payments for minting on this contract
  */
  function enableERC20OnlyMinting() public onlyTeamOrOwner {
    onlyERC20MintingMode = true;
  }

  /**
  * @dev Disable only ERC-20 payments for minting on this contract
  */
  function disableERC20OnlyMinting() public onlyTeamOrOwner {
    onlyERC20MintingMode = false;
  }

  /**
  * @dev Set the payout of the ERC-20 token payout to a specific address
  * @param _newErc20Payable new payout addresses of ERC-20 tokens
  */
  function setERC20PayableAddress(address _newErc20Payable) public onlyTeamOrOwner {
    require(_newErc20Payable != address(0), "WithdrawableV2: new ERC-20 payout cannot be the zero address");
    require(_newErc20Payable != erc20Payable, "WithdrawableV2: new ERC-20 payout is same as current payout");
    erc20Payable = _newErc20Payable;
  }

  /**
  * @dev Reset the Rampp surcharge total to zero regardless of value on contract currently.
  */
  function resetRamppSurchargeBalance() public isRampp {
    ramppSurchargeBalance = 0 ether;
  }

  /**
  * @dev Allows Rampp wallet to update its own reference as well as update
  * the address for the Rampp-owed payment split. Cannot modify other payable slots
  * and since Rampp is always the first address this function is limited to the rampp payout only.
  * @param _newAddress updated Rampp Address
  */
  function setRamppAddress(address _newAddress) public isRampp {
    require(_newAddress != RAMPPADDRESS, "WithdrawableV2: New Rampp address must be different");
    RAMPPADDRESS = _newAddress;
    payableAddresses[0] = _newAddress;
  }
}


  
  
// File: EarlyMintIncentive.sol
// Allows the contract to have the first x tokens have a discount or
// zero fee that can be calculated on the fly.
abstract contract EarlyMintIncentive is Teams, ERC721A {
  uint256 public PRICE = 0.0009 ether;
  uint256 public EARLY_MINT_PRICE = 0 ether;
  uint256 public earlyMintTokenIdCap = 2500;
  bool public usingEarlyMintIncentive = true;

  function enableEarlyMintIncentive() public onlyTeamOrOwner {
    usingEarlyMintIncentive = true;
  }

  function disableEarlyMintIncentive() public onlyTeamOrOwner {
    usingEarlyMintIncentive = false;
  }

  /**
  * @dev Set the max token ID in which the cost incentive will be applied.
  * @param _newTokenIdCap max tokenId in which incentive will be applied
  */
  function setEarlyMintTokenIdCap(uint256 _newTokenIdCap) public onlyTeamOrOwner {
    require(_newTokenIdCap <= collectionSize, "Cannot set incentive tokenId cap larger than totaly supply.");
    require(_newTokenIdCap >= 1, "Cannot set tokenId cap to less than the first token");
    earlyMintTokenIdCap = _newTokenIdCap;
  }

  /**
  * @dev Set the incentive mint price
  * @param _feeInWei new price per token when in incentive range
  */
  function setEarlyIncentivePrice(uint256 _feeInWei) public onlyTeamOrOwner {
    EARLY_MINT_PRICE = _feeInWei;
  }

  /**
  * @dev Set the primary mint price - the base price when not under incentive
  * @param _feeInWei new price per token
  */
  function setPrice(uint256 _feeInWei) public onlyTeamOrOwner {
    PRICE = _feeInWei;
  }

  function getPrice(uint256 _count) public view returns (uint256) {
    require(_count > 0, "Must be minting at least 1 token.");

    // short circuit function if we dont need to even calc incentive pricing
    // short circuit if the current tokenId is also already over cap
    if(
      usingEarlyMintIncentive == false ||
      currentTokenId() > earlyMintTokenIdCap
    ) {
      return PRICE * _count;
    }

    uint256 endingTokenId = currentTokenId() + _count;
    // If qty to mint results in a final token ID less than or equal to the cap then
    // the entire qty is within free mint.
    if(endingTokenId  <= earlyMintTokenIdCap) {
      return EARLY_MINT_PRICE * _count;
    }

    // If the current token id is less than the incentive cap
    // and the ending token ID is greater than the incentive cap
    // we will be straddling the cap so there will be some amount
    // that are incentive and some that are regular fee.
    uint256 incentiveTokenCount = earlyMintTokenIdCap - currentTokenId();
    uint256 outsideIncentiveCount = endingTokenId - earlyMintTokenIdCap;

    return (EARLY_MINT_PRICE * incentiveTokenCount) + (PRICE * outsideIncentiveCount);
  }
}

  
  
abstract contract RamppERC721A is 
    Ownable,
    Teams,
    ERC721A,
    WithdrawableV2,
    ReentrancyGuard 
    , EarlyMintIncentive 
     
    
{
  constructor(
    string memory tokenName,
    string memory tokenSymbol
  ) ERC721A(tokenName, tokenSymbol, 10, 5555) { }
    uint8 public CONTRACT_VERSION = 2;
    string public _baseTokenURI = "ipfs://bafybeidmkwlcaiigthua5xwotvbidptwdqrjn3sutdnb3czeclhyef22im/";

    bool public mintingOpen = false;
    bool public isRevealed = false;
    
    uint256 public MAX_WALLET_MINTS = 20;

  
    /////////////// Admin Mint Functions
    /**
     * @dev Mints a token to an address with a tokenURI.
     * This is owner only and allows a fee-free drop
     * @param _to address of the future owner of the token
     * @param _qty amount of tokens to drop the owner
     */
     function mintToAdminV2(address _to, uint256 _qty) public onlyTeamOrOwner{
         require(_qty > 0, "Must mint at least 1 token.");
         require(currentTokenId() + _qty <= collectionSize, "Cannot mint over supply cap of 5555");
         _safeMint(_to, _qty, true);
     }

  
    /////////////// GENERIC MINT FUNCTIONS
    /**
    * @dev Mints a single token to an address.
    * fee may or may not be required*
    * @param _to address of the future owner of the token
    */
    function mintTo(address _to) public payable {
        require(onlyERC20MintingMode == false, "Only minting with ERC-20 tokens is enabled.");
        require(getNextTokenId() <= collectionSize, "Cannot mint over supply cap of 5555");
        require(mintingOpen == true, "Minting is not open right now!");
        
        require(canMintAmount(_to, 1), "Wallet address is over the maximum allowed mints");
        require(msg.value == getPrice(1), "Value needs to be exactly the mint fee!");
        
        _safeMint(_to, 1, false);
    }

    /**
    * @dev Mints tokens to an address in batch.
    * fee may or may not be required*
    * @param _to address of the future owner of the token
    * @param _amount number of tokens to mint
    */
    function mintToMultiple(address _to, uint256 _amount) public payable {
        require(onlyERC20MintingMode == false, "Only minting with ERC-20 tokens is enabled.");
        require(_amount >= 1, "Must mint at least 1 token");
        require(_amount <= maxBatchSize, "Cannot mint more than max mint per transaction");
        require(mintingOpen == true, "Minting is not open right now!");
        
        require(canMintAmount(_to, _amount), "Wallet address is over the maximum allowed mints");
        require(currentTokenId() + _amount <= collectionSize, "Cannot mint over supply cap of 5555");
        require(msg.value == getPrice(_amount), "Value below required mint fee for amount");

        _safeMint(_to, _amount, false);
    }

    /**
     * @dev Mints tokens to an address in batch using an ERC-20 token for payment
     * fee may or may not be required*
     * @param _to address of the future owner of the token
     * @param _amount number of tokens to mint
     * @param _erc20TokenContract erc-20 token contract to mint with
     */
    function mintToMultipleERC20(address _to, uint256 _amount, address _erc20TokenContract) public payable {
      require(_amount >= 1, "Must mint at least 1 token");
      require(_amount <= maxBatchSize, "Cannot mint more than max mint per transaction");
      require(getNextTokenId() <= collectionSize, "Cannot mint over supply cap of 5555");
      require(mintingOpen == true, "Minting is not open right now!");
      
      require(canMintAmount(_to, 1), "Wallet address is over the maximum allowed mints");

      // ERC-20 Specific pre-flight checks
      require(isApprovedForERC20Payments(_erc20TokenContract), "ERC-20 Token is not approved for minting!");
      uint256 tokensQtyToTransfer = chargeAmountForERC20(_erc20TokenContract) * _amount;
      IERC20 payableToken = IERC20(_erc20TokenContract);

      require(payableToken.balanceOf(_to) >= tokensQtyToTransfer, "Buyer does not own enough of token to complete purchase");
      require(payableToken.allowance(_to, address(this)) >= tokensQtyToTransfer, "Buyer did not approve enough of ERC-20 token to complete purchase");
      require(hasSurcharge(), "Fee for ERC-20 payment not provided!");
      
      bool transferComplete = payableToken.transferFrom(_to, address(this), tokensQtyToTransfer);
      require(transferComplete, "ERC-20 token was unable to be transferred");
      
      _safeMint(_to, _amount, false);
      addSurcharge();
    }

    function openMinting() public onlyTeamOrOwner {
        mintingOpen = true;
    }

    function stopMinting() public onlyTeamOrOwner {
        mintingOpen = false;
    }

  

  
    /**
    * @dev Check if wallet over MAX_WALLET_MINTS
    * @param _address address in question to check if minted count exceeds max
    */
    function canMintAmount(address _address, uint256 _amount) public view returns(bool) {
        require(_amount >= 1, "Amount must be greater than or equal to 1");
        return (_numberMinted(_address) + _amount) <= MAX_WALLET_MINTS;
    }

    /**
    * @dev Update the maximum amount of tokens that can be minted by a unique wallet
    * @param _newWalletMax the new max of tokens a wallet can mint. Must be >= 1
    */
    function setWalletMax(uint256 _newWalletMax) public onlyTeamOrOwner {
        require(_newWalletMax >= 1, "Max mints per wallet must be at least 1");
        MAX_WALLET_MINTS = _newWalletMax;
    }
    

  
    /**
     * @dev Allows owner to set Max mints per tx
     * @param _newMaxMint maximum amount of tokens allowed to mint per tx. Must be >= 1
     */
     function setMaxMint(uint256 _newMaxMint) public onlyTeamOrOwner {
         require(_newMaxMint >= 1, "Max mint must be at least 1");
         maxBatchSize = _newMaxMint;
     }
    

  
    function unveil(string memory _updatedTokenURI) public onlyTeamOrOwner {
        require(isRevealed == false, "Tokens are already unveiled");
        _baseTokenURI = _updatedTokenURI;
        isRevealed = true;
    }
    

  function _baseURI() internal view virtual override returns(string memory) {
    return _baseTokenURI;
  }

  function baseTokenURI() public view returns(string memory) {
    return _baseTokenURI;
  }

  function setBaseURI(string calldata baseURI) external onlyTeamOrOwner {
    _baseTokenURI = baseURI;
  }

  function getOwnershipData(uint256 tokenId) external view returns(TokenOwnership memory) {
    return ownershipOf(tokenId);
  }
}


  
// File: contracts/PixilbearsContract.sol
//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract PixilbearsContract is RamppERC721A {
    constructor() RamppERC721A("pixil bears", "plb"){}
}
  
//*********************************************************************//
//*********************************************************************//  
//                       Mintplex v2.1.0
//
//         This smart contract was generated by mintplex.xyz.
//            Mintplex allows creators like you to launch 
//             large scale NFT communities without code!
//
//    Mintplex is not responsible for the content of this contract and
//        hopes it is being used in a responsible and kind way.  
//       Mintplex is not associated or affiliated with this project.                                                    
//             Twitter: @MintplexNFT ---- mintplex.xyz
//*********************************************************************//                                                     
//*********************************************************************//