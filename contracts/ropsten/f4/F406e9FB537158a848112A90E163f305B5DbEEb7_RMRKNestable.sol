/**
 *Submitted for verification at Etherscan.io on 2022-05-12
*/

// Sources flattened with hardhat v2.7.1 https://hardhat.org

// File contracts/RMRK/IRMRKCore.sol

// SPDX-License-Identifier: GNU GPL

pragma solidity ^0.8.0;

//import "./IERC721.sol";

interface IRMRKCore {
  function setChild(IRMRKCore childAddress, uint tokenId, uint childTokenId, bool pending) external;
  function nftOwnerOf(uint256 tokenId) external view returns (address, uint256);
  function ownerOf(uint256 tokenId) external view returns(address);
  function isRMRKCore() external pure returns(bool);
  function findRootOwner(uint id) external view returns(address);
  function isApprovedOrOwner(address addr, uint id) external view returns(bool);
  function removeChild(uint256 tokenId, address childAddress, uint256 childTokenId) external;

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

  event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
  event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
}


// File contracts/RMRK/IERC721Receiver.sol

// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721Receiver.sol)

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


// File contracts/RMRK/extensions/IERC721Metadata.sol

// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;
/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata{
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


// File contracts/RMRK/utils/Address.sol

// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

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


// File contracts/RMRK/utils/Context.sol

// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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


// File contracts/RMRK/utils/Strings.sol

// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)

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


// File contracts/RMRK/utils/introspection/IERC165.sol

// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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


// File contracts/RMRK/utils/introspection/ERC165.sol

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
    function supportsInterface(bytes4 interfaceId) public view override virtual returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}


// File contracts/RMRK/access/IssuerControl.sol

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)
// Reworked to match RMRK nomenclature of owner-issuer.

pragma solidity ^0.8.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferIssuer}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyIssuer`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract IssuerControl is Context {
    address private _issuer;

    event IssuerTransferred(address indexed previousIssuer, address indexed newIssuer);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferIssuer(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function issuer() public view virtual returns (address) {
        return _issuer;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyIssuer() {
        require(issuer() == _msgSender(), "Issuer: caller is not the issuer");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyIssuer` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceIssuer() public virtual onlyIssuer {
        _transferIssuer(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newIssuer`).
     * Can only be called by the current owner.
     */
    function transferIssuer(address newIssuer) public virtual onlyIssuer {
        require(newIssuer != address(0), "Issuer: new issuer is the zero address");
        _transferIssuer(newIssuer);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newIssuer`).
     * Internal function without access restriction.
     */
    function _transferIssuer(address newIssuer) internal virtual {
        address oldIssuer = _issuer;
        _issuer = newIssuer;
        emit IssuerTransferred(oldIssuer, newIssuer);
    }
}


// File contracts/RMRK/RMRKNestable.sol


pragma solidity ^0.8.9;
contract RMRKNestable is Context, ERC165, IRMRKCore, IssuerControl  {
  using Address for address;
  using Strings for uint256;

  struct Child {
    address contractAddress;
    uint256 tokenId;
    address baseAddr;
    bytes8 equipSlot;
    bool pending;
  }

  struct NftOwner {
    address contractAddress;
    uint256 tokenId;
  }

  struct RoyaltyData {
    address royaltyAddress;
    uint32 numerator;
    uint32 denominator;
  }

  string private _name;

  string private _symbol;

  string private _tokenURI;

  address private _issuer;

  bytes32 private _nestFlag = keccak256(bytes("NEST"));

  RoyaltyData private _royalties;

  mapping(uint256 => address) private _owners;

  mapping(address => uint256) private _balances;

  mapping(uint256 => address) private _tokenApprovals;

  mapping(uint256 => address) private _nestApprovals;

  mapping(uint256 => NftOwner) private _nftOwners;

  mapping(uint256 => Child[]) private _children;

  event ParentRemoved(address parentAddress, uint parentTokenId, uint childTokenId);

  event ChildRemoved(address childAddress, uint parentTokenId, uint childTokenId);

  constructor(string memory name_, string memory symbol_) {
    _name = name_;
    _symbol = symbol_;
    _issuer = msg.sender;
  }

   function tokenURI(uint256 tokenId) public virtual view returns(string memory){
     return _tokenURI;
   }

   /*
   TODOS:
   abstract "transfer caller is not owner nor approved" to modifier
   Isolate _transfer() branches in own functions
   Update functions that take address and use as interface to take interface instead
   double check (this) in setChild() call functions appropriately

   VULNERABILITY CHECK NOTES:
   External calls:
    ownerOf() during _transfer
    setChild() during _transfer()

   Vulnerabilities to test:
    Greif during _transfer via setChild reentry?

   VERIFY w/ YURI/BRUNO:
   Presence of _issuer field, since _issuer as rote in RMRK substrate sets minting perms; Standard for EVM is to gate
   minting behind requirement. Consider change in nomenclature to 'owner' to match EVM standards.

   EVENTUALLY:
   Create minimal contract that relies on on-chain libraries for gas savings

   */
   // change to ERC 165 implementation of IRMRKCore
   function isRMRKCore() public pure returns (bool){
     return true;
   }

   function findRootOwner(uint id) public view returns(address) {
   //sloads up the chain, each sload operation is 2.1K gas, not great
   //returns entry in 'owner' field in the event 'owner' does not implement isRMRKCore()
   //Currently not really functional, will probably be scrapped.
   //Currently returns `ownerOf` if 'owner' in struct is 0
     address root;
     address ownerAdd;
     uint ownerId;
     (ownerAdd, ownerId) = nftOwnerOf(id);

     if(ownerAdd == address(0)) {
       return ownerOf(id);
     }

     IRMRKCore nft = IRMRKCore(ownerAdd);

     try nft.isRMRKCore() {
       nft.findRootOwner(id);
     }

     catch (bytes memory) {
       root = ownerAdd;
     }

     return root;
   }

  /**
  @dev Returns all children, even pending
  */

  function childrenOf (uint256 parentTokenId) public view returns (Child[] memory) {
    Child[] memory children = _children[parentTokenId];
    return children;
  }

  /**
  @dev Removes an NFT from its parent, removing the nftOwnerOf entry.
  */

  function removeParent(uint256 tokenId) public {
    require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

    delete(_nftOwners[tokenId]);
    (address owner, uint parentTokenId) = nftOwnerOf(tokenId);

    IRMRKCore(owner).removeChild(parentTokenId, address(this), tokenId);

    emit ParentRemoved(owner, parentTokenId, tokenId);
  }

  /**
  @dev Removes a child NFT from children[].
  * Designed to be called by the removeParent function on an IRMRKCore contract to manage child[] array.
  * Iterates over an array. Innefficient, consider another pattern.
  * TODO: Restrict to contracts first called by approved owner. Must implement pattern for this.
  * Option: Find some way to identify child -- abi.encodePacked? Is more gas efficient than sloading the struct?
  */

  function removeChild(uint256 tokenId, address childAddress, uint256 childTokenId) public {
    Child[] memory children = childrenOf(tokenId);
    uint i;
    while (i<children.length) {
      if (children[i].contractAddress == childAddress && children[i].tokenId == childTokenId) {
        //Remove item from array, does not preserve order.
        //Double check this, hacky-feeling set to array storage from array memory.
        _children[tokenId][i] = children[children.length-1];
        _children[tokenId].pop();
      }
      i++;
    }

    emit ChildRemoved(childAddress, tokenId, childTokenId);

  }

  /**
  @dev Accepts a child, setting pending to false.
  * Storing children as an array seems inefficient, consider keccak256(abi.encodePacked(parentAddr, tokenId)) as key for mapping(childKey => childObj)))
  * This operation can make getChildren() operation wacky racers, test it
  * mappings rule, iterating through arrays drools
  * SSTORE and SLOAD are basically the same gas cost anyway
  */

  function acceptChild(uint256 tokenId, address childAddress, uint256 childTokenId) public {
      require(_isApprovedOrOwner(_msgSender(), tokenId), "RMRKCore: Attempting to accept a child in non-owned NFT");
      Child[] memory children = childrenOf(tokenId);
      uint i = 0;
      while (i<children.length) {
        if (children[i].contractAddress == childAddress && children[i].tokenId == childTokenId) {
          _children[tokenId][i].pending = false;
        }
        i++;
    }
  }

  /**
  @dev Returns NFT owner for a nested NFT.
  * Returns a tuple of (address, uint), which is the address and token ID of the NFT owner.
  */

  function nftOwnerOf(uint256 tokenId) public view virtual returns (address, uint256) {
    NftOwner memory owner = _nftOwners[tokenId];
    require(owner.contractAddress != address(0), "ERC721: owner query for nonexistent token");
    return (owner.contractAddress, owner.tokenId);
  }

  /**
  @dev Returns root owner of token. Can be an ETH address with our without contract data.
  */

  function ownerOf(uint256 tokenId) public view virtual override returns (address) {
    address owner = _owners[tokenId];
    require(owner != address(0), "ERC721: owner query for nonexistent token");
    return owner;
  }

  /**
  @dev Returns balance of tokens owner by a given rootOwner.
  */

  function balanceOf(address owner) public view virtual returns (uint256) {
      require(owner != address(0), "ERC721: balance query for the zero address");
      return _balances[owner];
  }

  /**
  @dev Returns name of NFT collection.
  */

  function name() public view virtual returns (string memory) {
      return _name;
  }

  /**
  @dev Returns symbol of NFT collection.
  */

  function symbol() public view virtual returns (string memory) {
      return _symbol;
  }

  /**
  @dev Mints an NFT.
  * Can mint to a root owner or another NFT.
  * If 'NEST' is passed via _data parameter, token is minted into another NFT if target contract implemnts RMRKCore (Latter not implemented)
  *
  */

  function mint(address to, uint256 tokenId, uint256 destId, string memory _data) public virtual {

    //Gas saving here from string > bytes?
    if (keccak256(bytes(_data)) == keccak256(bytes("NEST"))) {
      _mintNest(to, tokenId, destId);
    }
    else{
      _mint(to, tokenId);
    }
  }

  function _mintNest(address to, uint256 tokenId, uint256 destId) internal virtual {
      require(to != address(0), "ERC721: mint to the zero address");
      require(!_exists(tokenId), "ERC721: token already minted");
      require(to.isContract(), "Is not contract");
      IRMRKCore destContract = IRMRKCore(to);
      /* require(destContract.isRMRKCore(), "Not RMRK Core"); */ //Implement supportsInterface RMRKCore

      _beforeTokenTransfer(address(0), to, tokenId);
      address rootOwner = destContract.ownerOf(destId);
      _balances[rootOwner] += 1;
      _owners[tokenId] = rootOwner;

      _nftOwners[tokenId] = NftOwner({
        contractAddress: to,
        tokenId: destId
        });

      bool pending = !destContract.isApprovedOrOwner(msg.sender, destId);

      destContract.setChild(this, destId, tokenId, pending);

      emit Transfer(address(0), to, tokenId);

      _afterTokenTransfer(address(0), to, tokenId);
  }

  function _mint(address to, uint256 tokenId) internal virtual {
      require(to != address(0), "ERC721: mint to the zero address");
      require(!_exists(tokenId), "ERC721: token already minted");

      _beforeTokenTransfer(address(0), to, tokenId);

      _balances[to] += 1;
      _owners[tokenId] = to;

      emit Transfer(address(0), to, tokenId);

      _afterTokenTransfer(address(0), to, tokenId);
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
      address owner = this.ownerOf(tokenId);

      _beforeTokenTransfer(owner, address(0), tokenId);

      // Clear approvals
      _approve(address(0), tokenId);

      _balances[owner] -= 1;
      delete _owners[tokenId];
      delete _nftOwners[tokenId];

      emit Transfer(owner, address(0), tokenId);

      _afterTokenTransfer(owner, address(0), tokenId);
  }

  /**
   * @dev See {IERC721-transferFrom}.
   */
  function transferFrom(
      address from,
      address to,
      uint256 tokenId,
      uint256 destId,
      string memory _data
  ) public virtual {
      //solhint-disable-next-line max-line-length
      require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
      _transfer(from, to, tokenId, destId, _data);
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

  //Convert string to bytes in calldata for gas saving
  //Double check to make sure nested transfers update balanceOf correctly. Maybe add condition if rootOwner does not change for gas savings.
  function _transfer(
      address from,
      address to,
      uint256 tokenId,
      uint256 destId,
      string memory _data
  ) internal virtual {
      require(this.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
      require(to != address(0), "ERC721: transfer to the zero address");

      _beforeTokenTransfer(from, to, tokenId);

      if (keccak256(bytes(_data)) == _nestFlag) {
        _nftOwners[tokenId] = NftOwner({
          contractAddress: to,
          tokenId: destId
          });

        IRMRKCore destContract = IRMRKCore(to);
        bool pending = !destContract.isApprovedOrOwner(msg.sender, destId);
        address rootOwner = destContract.ownerOf(destId);

        _balances[from] -= 1;
        _balances[rootOwner] += 1;
        _owners[tokenId] = rootOwner;

        destContract.setChild(this, destId, tokenId, pending);

      }

      else {
        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;
      }

      // Clear approvals from the previous owner
      _approve(address(0), tokenId);

      emit Transfer(from, to, tokenId);

      _afterTokenTransfer(from, to, tokenId);
  }

  function _beforeTokenTransfer(
      address from,
      address to,
      uint256 tokenId
  ) internal virtual {}

  /**
   * @dev Hook that is called after any transfer of tokens. This includes
   * minting and burning.
   *
   * Calling conditions:
   *
   * - when `from` and `to` are both non-zero.
   * - `from` and `to` are never both zero.
   *
   * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
   */
  function _afterTokenTransfer(
      address from,
      address to,
      uint256 tokenId
  ) internal virtual {}

    /**
     * @dev Function designed to be used by other instances of RMRK-Core contracts to update children.
     * param1 childAddress is the address of the child contract as an IRMRKCore instance
     * param2 parentTokenId is the tokenId of the parent token on (this).
     * param3 childTokenId is the tokenId of the child instance
     */
  function setChild(IRMRKCore childAddress, uint parentTokenId, uint childTokenId, bool isPending) public virtual {
    (address parent, ) = childAddress.nftOwnerOf(childTokenId);
    require(parent == address(this), "Parent-child mismatch");

    //if parent token Id is same root owner as child
    Child memory child = Child({
        contractAddress: address(childAddress),
        tokenId: childTokenId,
        baseAddr: address(0),
        equipSlot: bytes8(0),
        pending: isPending
      });
    _children[parentTokenId].push(child);
  }

  function _exists(uint256 tokenId) internal view virtual returns (bool) {
      return _owners[tokenId] != address(0);
  }

  function approve(address to, uint256 tokenId) public virtual {
      address owner = this.ownerOf(tokenId);
      require(to != owner, "ERC721: approval to current owner");

      require(
          _msgSender() == owner,
          "ERC721: approve caller is not owner"
      );

      _approve(to, tokenId);
  }

  function _approve(address to, uint256 tokenId) internal virtual {
      _tokenApprovals[tokenId] = to;
      emit Approval(ownerOf(tokenId), to, tokenId);
  }

  function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
      address owner = this.ownerOf(tokenId);
      return (spender == owner || getApproved(tokenId) == spender);
  }

  //re-implement isApprovedForAll
  function isApprovedOrOwner(address spender, uint256 tokenId) public view virtual returns (bool) {
    bool res = _isApprovedOrOwner(spender, tokenId);
    return res;
  }

  function getApproved(uint256 tokenId) public view virtual returns (address) {
      require(_exists(tokenId), "ERC721: approved query for nonexistent token");

      return _tokenApprovals[tokenId];
  }

  //big dumb stupid hack, fix
  function supportsInterface() public returns (bool) {
    return true;
  }

    /**
    * @dev Returns contract royalty data.
    * Returns a numerator and denominator for percentage calculations, as well as a desitnation address.
    */
  function getRoyaltyData() public view returns(address royaltyAddress, uint256 numerator, uint256 denominator) {
   RoyaltyData memory data = _royalties;
   return(data.royaltyAddress, uint256(data.numerator), uint256(data.denominator));
  }

   /**
   * @dev Setter for contract royalty data, percentage stored as a numerator and denominator.
   * Recommended values are in Parts Per Million, E.G:
   * A numerator of 1*10**5 and a denominator of 1*10**6 is equal to 10 percent, or 100,000 parts per 1,000,000.
   */
   //TODO: Decide on default visiblity
  function setRoyaltyData(address _royaltyAddress, uint32 _numerator, uint32 _denominator) external virtual {
   _royalties = RoyaltyData ({
       royaltyAddress: _royaltyAddress,
       numerator: _numerator,
       denominator: _denominator
     });
  }

}