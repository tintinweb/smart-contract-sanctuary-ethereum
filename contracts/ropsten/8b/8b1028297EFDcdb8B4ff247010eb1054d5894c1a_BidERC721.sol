/**
 *Submitted for verification at Etherscan.io on 2022-07-02
*/

/** 
 *  SourceUnit: /home/mohammadreza/Downloads/SC (2)/Market/BidERC721.sol
*/
            
pragma solidity ^0.5.4;
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
contract Ownable {
    address payable owner;
    
    modifier isOwner {
        require(owner == msg.sender, "You should be owner to call this function.");
        _;
    }
    
    constructor() public {
        owner = msg.sender;
    }

    function changeOwner(address payable _owner) public isOwner {
        require(owner != _owner, "You must enter a new value.");
        owner = _owner;
    }

    function getOwner() public view returns(address) {
        return(owner);
    }
    
}



/** 
 *  SourceUnit: /home/mohammadreza/Downloads/SC (2)/Market/BidERC721.sol
*/
            
pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * [EIP](https://eips.ethereum.org/EIPS/eip-165).
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others (`ERC165Checker`).
 *
 * For an implementation, see `ERC165`.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}




/** 
 *  SourceUnit: /home/mohammadreza/Downloads/SC (2)/Market/BidERC721.sol
*/
            
pragma solidity ^0.5.0;

////import "./IERC165.sol";

/**
 * @dev Implementation of the `IERC165` interface.
 *
 * Contracts may inherit from this and call `_registerInterface` to declare
 * their support of an interface.
 */
contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See `IERC165.supportsInterface`.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See `IERC165.supportsInterface`.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}




/** 
 *  SourceUnit: /home/mohammadreza/Downloads/SC (2)/Market/BidERC721.sol
*/
            
pragma solidity ^0.5.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}




/** 
 *  SourceUnit: /home/mohammadreza/Downloads/SC (2)/Market/BidERC721.sol
*/
            
pragma solidity ^0.5.0;

////import "./SafeMath.sol";

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 * Since it is not possible to overflow a 256 bit integer with increments of one, `increment` can skip the SafeMath
 * overflow check, thereby saving gas. This does assume however correct usage, in that the underlying `_value` is never
 * directly accessed.
 */
library Counters {
    using SafeMath for uint256;

    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}




/** 
 *  SourceUnit: /home/mohammadreza/Downloads/SC (2)/Market/BidERC721.sol
*/
            
pragma solidity ^0.5.0;

/**
 * @dev Collection of functions related to the address type,
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * > It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }
}




/** 
 *  SourceUnit: /home/mohammadreza/Downloads/SC (2)/Market/BidERC721.sol
*/
            
pragma solidity ^0.5.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
contract IERC721Receiver {
    /**
     * @notice Handle the receipt of an NFT
     * @dev The ERC721 smart contract calls this function on the recipient
     * after a `safeTransfer`. This function MUST return the function selector,
     * otherwise the caller will revert the transaction. The selector to be
     * returned can be obtained as `this.onERC721Received.selector`. This
     * function MAY throw to revert and reject the transfer.
     * Note: the ERC721 contract address is always the message sender.
     * @param operator The address which called `safeTransferFrom` function
     * @param from The address which previously owned the token
     * @param tokenId The NFT identifier which is being transferred
     * @param data Additional data with no specified format
     * @return bytes4 `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data)
    public returns (bytes4);
}




/** 
 *  SourceUnit: /home/mohammadreza/Downloads/SC (2)/Market/BidERC721.sol
*/
            
pragma solidity ^0.5.0;

//////import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
contract IERC721Metadata /*is IERC721*/ {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}




/** 
 *  SourceUnit: /home/mohammadreza/Downloads/SC (2)/Market/BidERC721.sol
*/
            
pragma solidity ^0.5.0;

///////import "./IERC721.sol";
////import "./IERC721Receiver.sol";
////import "./SafeMath.sol";
////import "./Address.sol";
////import "./Counters.sol";
////import "./ERC165.sol";

/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
contract ERC721 is ERC165 /* IERC721*/ {
    using SafeMath for uint256;
    using Address for address;
    using Counters for Counters.Counter;

    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    // Mapping from token ID to owner
    mapping (uint256 => address) private _tokenOwner;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to number of owned token
    mapping (address => Counters.Counter) private _ownedTokensCount;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    /*
     *     bytes4(keccak256('balanceOf(address)')) == 0x70a08231
     *     bytes4(keccak256('ownerOf(uint256)')) == 0x6352211e
     *     bytes4(keccak256('approve(address,uint256)')) == 0x095ea7b3
     *     bytes4(keccak256('getApproved(uint256)')) == 0x081812fc
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c
     *     bytes4(keccak256('transferFrom(address,address,uint256)')) == 0x23b872dd
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) == 0x42842e0e
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)')) == 0xb88d4fde
     *
     *     => 0x70a08231 ^ 0x6352211e ^ 0x095ea7b3 ^ 0x081812fc ^
     *        0xa22cb465 ^ 0xe985e9c ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde == 0x80ac58cd
     */
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    constructor () public {
        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721);
    }
    /// @dev This emits when ownership of any NFT changes by any mechanism.
    ///  This event emits when NFTs are created (`from` == 0) and destroyed
    ///  (`to` == 0). Exception: during contract creation, any number of NFTs
    ///  may be created and assigned without emitting Transfer. At the time of
    ///  any transfer, the approved address for that NFT (if any) is reset to none.
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    /// @dev This emits when the approved address for an NFT is changed or
    ///  reaffirmed. The zero address indicates there is no approved address.
    ///  When a Transfer event emits, this also indicates that the approved
    ///  address for that NFT (if any) is reset to none.
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

    /// @dev This emits when an operator is enabled or disabled for an owner.
    ///  The operator can manage all NFTs of the owner.
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    /**
     * @dev Gets the balance of the specified address.
     * @param owner address to query the balance of
     * @return uint256 representing the amount owned by the passed address
     */
    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");

        return _ownedTokensCount[owner].current();
    }

    /**
     * @dev Gets the owner of the specified token ID.
     * @param tokenId uint256 ID of the token to query the owner of
     * @return address currently marked as the owner of the given token ID
     */
    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _tokenOwner[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");

        return owner;
    }

    /**
     * @dev Approves another address to transfer the given token ID
     * The zero address indicates there is no approved address.
     * There can only be one approved address per token at a given time.
     * Can only be called by the token owner or an approved operator.
     * @param to address to be approved for the given token ID
     * @param tokenId uint256 ID of the token to be approved
     */
    function approve(address to, uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    /**
     * @dev Gets the approved address for a token ID, or zero if no address set
     * Reverts if the token ID does not exist.
     * @param tokenId uint256 ID of the token to query the approval of
     * @return address currently approved for the given token ID
     */
    function getApproved(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev Sets or unsets the approval of a given operator
     * An operator is allowed to transfer all tokens of the sender on their behalf.
     * @param to operator address to set the approval
     * @param approved representing the status of the approval to be set
     */
    function setApprovalForAll(address to, bool approved) public {
        require(to != msg.sender, "ERC721: approve to caller");

        _operatorApprovals[msg.sender][to] = approved;
        emit ApprovalForAll(msg.sender, to, approved);
    }

    /**
     * @dev Tells whether an operator is approved by a given owner.
     * @param owner owner address which you want to query the approval of
     * @param operator operator address which you want to query the approval of
     * @return bool whether the given operator is approved by the given owner
     */
    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev Transfers the ownership of a given token ID to another address.
     * Usage of this method is discouraged, use `safeTransferFrom` whenever possible.
     * Requires the msg.sender to be the owner, approved, or operator.
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     */
    function transferFrom(address from, address to, uint256 tokenId) public {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");

        _transferFrom(from, to, tokenId);
    }

    /**
     * @dev Safely transfers the ownership of a given token ID to another address
     * If the target address is a contract, it must implement `onERC721Received`,
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * Requires the msg.sender to be the owner, approved, or operator
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev Safely transfers the ownership of a given token ID to another address
     * If the target address is a contract, it must implement `onERC721Received`,
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * Requires the msg.sender to be the owner, approved, or operator
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes data to send along with a safe transfer check
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public {
        transferFrom(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether the specified token exists.
     * @param tokenId uint256 ID of the token to query the existence of
     * @return bool whether the token exists
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        address owner = _tokenOwner[tokenId];
        return owner != address(0);
    }

    /**
     * @dev Returns whether the given spender can transfer a given token ID.
     * @param spender address of the spender to query
     * @param tokenId uint256 ID of the token to be transferred
     * @return bool whether the msg.sender is approved for the given token ID,
     * is an operator of the owner, or is the owner of the token
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Internal function to mint a new token.
     * Reverts if the given token ID already exists.
     * @param to The address that will own the minted token
     * @param tokenId uint256 ID of the token to be minted
     */
    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _tokenOwner[tokenId] = to;
        _ownedTokensCount[to].increment();

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Internal function to burn a specific token.
     * Reverts if the token does not exist.
     * Deprecated, use _burn(uint256) instead.
     * @param owner owner of the token to burn
     * @param tokenId uint256 ID of the token being burned
     */
    function _burn(address owner, uint256 tokenId) internal {
        require(ownerOf(tokenId) == owner, "ERC721: burn of token that is not own");

        _clearApproval(tokenId);

        _ownedTokensCount[owner].decrement();
        _tokenOwner[tokenId] = address(0);

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Internal function to burn a specific token.
     * Reverts if the token does not exist.
     * @param tokenId uint256 ID of the token being burned
     */
    function _burn(uint256 tokenId) internal {
        _burn(ownerOf(tokenId), tokenId);
    }

    /**
     * @dev Internal function to transfer ownership of a given token ID to another address.
     * As opposed to transferFrom, this imposes no restrictions on msg.sender.
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     */
    function _transferFrom(address from, address to, uint256 tokenId) internal {
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _clearApproval(tokenId);

        _ownedTokensCount[from].decrement();
        _ownedTokensCount[to].increment();

        _tokenOwner[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Internal function to invoke `onERC721Received` on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * This function is deprecated.
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        internal returns (bool)
    {
        if (!to.isContract()) {
            return true;
        }

        bytes4 retval = IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data);
        return (retval == _ERC721_RECEIVED);
    }

    /**
     * @dev Private function to clear current approval of a given token ID.
     * @param tokenId uint256 ID of the token to be transferred
     */
    function _clearApproval(uint256 tokenId) private {
        if (_tokenApprovals[tokenId] != address(0)) {
            _tokenApprovals[tokenId] = address(0);
        }
    }
}




/** 
 *  SourceUnit: /home/mohammadreza/Downloads/SC (2)/Market/BidERC721.sol
*/
            
pragma solidity ^0.5.0;

//////import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
contract IERC721Enumerable /*is IERC721*/ {
    function totalSupply() public view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256 tokenId);

    function tokenByIndex(uint256 index) public view returns (uint256);
}




/** 
 *  SourceUnit: /home/mohammadreza/Downloads/SC (2)/Market/BidERC721.sol
*/
            
pragma solidity ^0.5.0;

////import "./ERC721.sol";
////import "./IERC721Metadata.sol";
////import "./ERC165.sol";

contract ERC721Metadata is ERC165, ERC721, IERC721Metadata {
    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /*
     *     bytes4(keccak256('name()')) == 0x06fdde03
     *     bytes4(keccak256('symbol()')) == 0x95d89b41
     *     bytes4(keccak256('tokenURI(uint256)')) == 0xc87b56dd
     *
     *     => 0x06fdde03 ^ 0x95d89b41 ^ 0xc87b56dd == 0x5b5e139f
     */
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

    /**
     * @dev Constructor function
     */
    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;

        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
    }

    /**
     * @dev Gets the token name.
     * @return string representing the token name
     */
    function name() external view returns (string memory) {
        return _name;
    }

    /**
     * @dev Gets the token symbol.
     * @return string representing the token symbol
     */
    function symbol() external view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns an URI for a given token ID.
     * Throws if the token ID does not exist. May return an empty string.
     * @param tokenId uint256 ID of the token to query
     */
    function tokenURI(uint256 tokenId) external view returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return _tokenURIs[tokenId];
    }

    /**
     * @dev Internal function to set the token URI for a given token.
     * Reverts if the token ID does not exist.
     * @param tokenId uint256 ID of the token to set its URI
     * @param uri string URI to assign
     */
    function _setTokenURI(uint256 tokenId, string memory uri) internal {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = uri;
    }

    /**
     * @dev Internal function to burn a specific token.
     * Reverts if the token does not exist.
     * Deprecated, use _burn(uint256) instead.
     * @param owner owner of the token to burn
     * @param tokenId uint256 ID of the token being burned by the msg.sender
     */
    function _burn(address owner, uint256 tokenId) internal {
        super._burn(owner, tokenId);

        // Clear metadata (if any)
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}




/** 
 *  SourceUnit: /home/mohammadreza/Downloads/SC (2)/Market/BidERC721.sol
*/
            
pragma solidity ^0.5.0;

////import "./IERC721Enumerable.sol";
////import "./ERC721.sol";
////import "./ERC165.sol";

/**
 * @title ERC-721 Non-Fungible Token with optional enumeration extension logic
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
contract ERC721Enumerable is ERC165, ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => uint256[]) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /*
     *     bytes4(keccak256('totalSupply()')) == 0x18160ddd
     *     bytes4(keccak256('tokenOfOwnerByIndex(address,uint256)')) == 0x2f745c59
     *     bytes4(keccak256('tokenByIndex(uint256)')) == 0x4f6ccce7
     *
     *     => 0x18160ddd ^ 0x2f745c59 ^ 0x4f6ccce7 == 0x780e9d63
     */
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;

    /**
     * @dev Constructor function.
     */
    constructor () public {
        // register the supported interface to conform to ERC721Enumerable via ERC165
        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
    }

    /**
     * @dev Gets the token ID at a given index of the tokens list of the requested owner.
     * @param owner address owning the tokens list to be accessed
     * @param index uint256 representing the index to be accessed of the requested tokens list
     * @return uint256 token ID at the given index of the tokens list owned by the requested address
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) {
        require(index < balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev Gets the total amount of tokens stored by the contract.
     * @return uint256 representing the total amount of tokens
     */
    function totalSupply() public view returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev Gets the token ID at a given index of all the tokens in this contract
     * Reverts if the index is greater or equal to the total number of tokens.
     * @param index uint256 representing the index to be accessed of the tokens list
     * @return uint256 token ID at the given index of the tokens list
     */
    function tokenByIndex(uint256 index) public view returns (uint256) {
        require(index < totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Internal function to transfer ownership of a given token ID to another address.
     * As opposed to transferFrom, this imposes no restrictions on msg.sender.
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     */
    function _transferFrom(address from, address to, uint256 tokenId) internal {
        super._transferFrom(from, to, tokenId);

        _removeTokenFromOwnerEnumeration(from, tokenId);

        _addTokenToOwnerEnumeration(to, tokenId);
    }

    /**
     * @dev Internal function to mint a new token.
     * Reverts if the given token ID already exists.
     * @param to address the beneficiary that will own the minted token
     * @param tokenId uint256 ID of the token to be minted
     */
    function _mint(address to, uint256 tokenId) internal {
        super._mint(to, tokenId);

        _addTokenToOwnerEnumeration(to, tokenId);

        _addTokenToAllTokensEnumeration(tokenId);
    }

    /**
     * @dev Internal function to burn a specific token.
     * Reverts if the token does not exist.
     * Deprecated, use _burn(uint256) instead.
     * @param owner owner of the token to burn
     * @param tokenId uint256 ID of the token being burned
     */
    function _burn(address owner, uint256 tokenId) internal {
        super._burn(owner, tokenId);

        _removeTokenFromOwnerEnumeration(owner, tokenId);
        // Since tokenId will be deleted, we can clear its slot in _ownedTokensIndex to trigger a gas refund
        _ownedTokensIndex[tokenId] = 0;

        _removeTokenFromAllTokensEnumeration(tokenId);
    }

    /**
     * @dev Gets the list of token IDs of the requested owner.
     * @param owner address owning the tokens
     * @return uint256[] List of token IDs owned by the requested address
     */
    function _tokensOfOwner(address owner) internal view returns (uint256[] storage) {
        return _ownedTokens[owner];
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        _ownedTokensIndex[tokenId] = _ownedTokens[to].length;
        _ownedTokens[to].push(tokenId);
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
     * while the token is not assigned a new owner, the _ownedTokensIndex mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _ownedTokens[from].length.sub(1);
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        _ownedTokens[from].length--;

        // Note that _ownedTokensIndex[tokenId] hasn't been cleared: it still points to the old slot (now occupied by
        // lastTokenId, or just over the end of the array if the token was the last one).
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length.sub(1);
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        _allTokens.length--;
        _allTokensIndex[tokenId] = 0;
    }
}




/** 
 *  SourceUnit: /home/mohammadreza/Downloads/SC (2)/Market/BidERC721.sol
*/
            
pragma solidity ^0.5.4;
////import "./Ownable.sol";
////import "./ERC165.sol";

contract Royalty is Ownable, ERC165 {

//****************************************************************************
//* Data
//****************************************************************************
//    uint16 RoyaltyFee = 200; // 2% 
    mapping(uint => address) RoyaltyOwner;

//****************************************************************************
//* Main Functions
//****************************************************************************
    constructor() public {
        _registerInterface(this.getRoyaltyOwner.selector);
    }

/*
    function getRoyaltyFee() public view returns(uint16) {
        return(RoyaltyFee);
    }
*/

    function getRoyaltyOwner(uint _itemId) public view returns(address) {
        return RoyaltyOwner[_itemId];
    }

//****************************************************************************
//* Owner Functions
//****************************************************************************
/*
    function setRoyaltyFee(uint16 _royaltyFee) public isOwner {
        require(_royaltyFee != RoyaltyFee,"New value required.");
        require(_royaltyFee < 1e4);
        RoyaltyFee = _royaltyFee;
    }
*/
//****************************************************************************
//* Internal Functions
//****************************************************************************
    function _mintItem(address _royaltyOwner, uint _itemId) internal {
        RoyaltyOwner[_itemId] = _royaltyOwner;
    }
}



/** 
 *  SourceUnit: /home/mohammadreza/Downloads/SC (2)/Market/BidERC721.sol
*/
            
pragma solidity ^0.5.4;
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
contract MyUtils {
    function uintToString(uint _i) internal pure returns (string memory str) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (_i != 0) {
            bstr[k--] = byte(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }

    function strConcat(string memory _a, string memory _b) internal pure returns (string memory _concatenatedString) {
        return strConcat(_a, _b, "", "", "");
    }

    function strConcat(string memory _a, string memory _b, string memory _c) internal pure returns (string memory _concatenatedString) {
        return strConcat(_a, _b, _c, "", "");
    }

    function strConcat(string memory _a, string memory _b, string memory _c, string memory _d) internal pure returns (string memory _concatenatedString) {
        return strConcat(_a, _b, _c, _d, "");
    }

    function strConcat(string memory _a, string memory _b, string memory _c, string memory _d, string memory _e) internal pure returns (string memory _concatenatedString) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory _bc = bytes(_c);
        bytes memory _bd = bytes(_d);
        bytes memory _be = bytes(_e);
        string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
        bytes memory babcde = bytes(abcde);
        uint k = 0;
        uint i = 0;
        for (i = 0; i < _ba.length; i++) {
            babcde[k++] = _ba[i];
        }
        for (i = 0; i < _bb.length; i++) {
            babcde[k++] = _bb[i];
        }
        for (i = 0; i < _bc.length; i++) {
            babcde[k++] = _bc[i];
        }
        for (i = 0; i < _bd.length; i++) {
            babcde[k++] = _bd[i];
        }
        for (i = 0; i < _be.length; i++) {
            babcde[k++] = _be[i];
        }
        return string(babcde);
    }
    
}



/** 
 *  SourceUnit: /home/mohammadreza/Downloads/SC (2)/Market/BidERC721.sol
*/
            
pragma solidity ^0.5.0;

////import "./ERC721.sol";
////import "./ERC721Enumerable.sol";
////import "./ERC721Metadata.sol";

/**
 * @title Full ERC721 Token
 * This implementation includes all the required and some optional functionality of the ERC721 standard
 * Moreover, it includes approve all functionality using operator terminology
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
contract ERC721Full is ERC721, ERC721Enumerable, ERC721Metadata {
    constructor (string memory name, string memory symbol) public ERC721Metadata(name, symbol) {
        // solhint-disable-previous-line no-empty-blocks
    }
}




/** 
 *  SourceUnit: /home/mohammadreza/Downloads/SC (2)/Market/BidERC721.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity ^0.5.10;

////import "./IERC721Enumerable.sol";
////import "./IERC721Metadata.sol";
/*
interface IERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceID The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}
*/
/// @dev Note: the ERC-165 identifier for this interface is 0x150b7a02.
interface IERC721TokenReceiver {
    /// @notice Handle the receipt of an NFT
    /// @dev The ERC721 smart contract calls this function on the recipient
    ///  after a `transfer`. This function MAY throw to revert and reject the
    ///  transfer. Return of other than the magic value MUST result in the
    ///  transaction being reverted.
    ///  Note: the contract address is always the message sender.
    /// @param _operator The address which called `safeTransferFrom` function
    /// @param _from The address which previously owned the token
    /// @param _tokenId The NFT identifier which is being transferred
    /// @param _data Additional data with no specified format
    /// @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    ///  unless throwing
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external returns(bytes4);
}

/// @title ERC-721 Non-Fungible Token Standard, optional metadata extension
/// @dev See https://eips.ethereum.org/EIPS/eip-721
///  Note: the ERC-165 identifier for this interface is 0x5b5e139f.

//interface IERC721Metadata /* is ERC721 */ {
/*
    /// @notice A descriptive name for a collection of NFTs in this contract
    function name() external view returns (string memory _name);

    /// @notice An abbreviated name for NFTs in this contract
    function symbol() external view returns (string memory _symbol);

    /// @notice A distinct Uniform Resource Identifier (URI) for a given asset.
    /// @dev Throws if `_tokenId` is not a valid NFT. URIs are defined in RFC
    ///  3986. The URI may point to a JSON file that conforms to the "ERC721
    ///  Metadata JSON Schema".
    function tokenURI(uint256 _tokenId) external view returns (string memory);
}
*/

/// @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
/// @dev See https://eips.ethereum.org/EIPS/eip-721
///  Note: the ERC-165 identifier for this interface is 0x780e9d63.
//interface IERC721Enumerable /* is ERC721 */ {
/*
    /// @notice Count NFTs tracked by this contract
    /// @return A count of valid NFTs tracked by this contract, where each one of
    ///  them has an assigned and queryable owner not equal to the zero address
    function totalSupply() external view returns (uint256);

    /// @notice Enumerate valid NFTs
    /// @dev Throws if `_index` >= `totalSupply()`.
    /// @param _index A counter less than `totalSupply()`
    /// @return The token identifier for the `_index`th NFT,
    ///  (sort order not specified)
    function tokenByIndex(uint256 _index) external view returns (uint256);

    /// @notice Enumerate NFTs assigned to an owner
    /// @dev Throws if `_index` >= `balanceOf(_owner)` or if
    ///  `_owner` is the zero address, representing invalid NFTs.
    /// @param _owner An address where we are interested in NFTs owned by them
    /// @param _index A counter less than `balanceOf(_owner)`
    /// @return The token identifier for the `_index`th NFT assigned to `_owner`,
    ///   (sort order not specified)
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256);
}
*/
interface IRoyalty {
//    function getRoyaltyFee() external view returns(uint16);

    function getRoyaltyOwner(uint _itemId) external view returns(address payable);

}

/// @title ERC-721 Non-Fungible Token Standard
/// @dev See https://eips.ethereum.org/EIPS/eip-721
///  Note: the ERC-165 identifier for this interface is 0x80ac58cd.
contract IERC721 is /*IERC165,*/ IERC721TokenReceiver, IERC721Metadata, IERC721Enumerable, IRoyalty {
    /// @dev This emits when ownership of any NFT changes by any mechanism.
    ///  This event emits when NFTs are created (`from` == 0) and destroyed
    ///  (`to` == 0). Exception: during contract creation, any number of NFTs
    ///  may be created and assigned without emitting Transfer. At the time of
    ///  any transfer, the approved address for that NFT (if any) is reset to none.
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    /// @dev This emits when the approved address for an NFT is changed or
    ///  reaffirmed. The zero address indicates there is no approved address.
    ///  When a Transfer event emits, this also indicates that the approved
    ///  address for that NFT (if any) is reset to none.
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

    /// @dev This emits when an operator is enabled or disabled for an owner.
    ///  The operator can manage all NFTs of the owner.
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    /// @notice Count all NFTs assigned to an owner
    /// @dev NFTs assigned to the zero address are considered invalid, and this
    ///  function throws for queries about the zero address.
    /// @param _owner An address for whom to query the balance
    /// @return The number of NFTs owned by `_owner`, possibly zero
    function balanceOf(address _owner) external view returns (uint256);

    /// @notice Find the owner of an NFT
    /// @dev NFTs assigned to zero address are considered invalid, and queries
    ///  about them do throw.
    /// @param _tokenId The identifier for an NFT
    /// @return The address of the owner of the NFT
    function ownerOf(uint256 _tokenId) external view returns (address);

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT. When transfer is complete, this function
    ///  checks if `_to` is a smart contract (code size > 0). If so, it calls
    ///  `onERC721Received` on `_to` and throws if the return value is not
    ///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    /// @param data Additional data with no specified format, sent in call to `_to`
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata data) external payable;

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev This works identically to the other function with an extra data parameter,
    ///  except this function just sets data to "".
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;

    /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
    ///  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
    ///  THEY MAY BE PERMANENTLY LOST
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;

    /// @notice Change or reaffirm the approved address for an NFT
    /// @dev The zero address indicates there is no approved address.
    ///  Throws unless `msg.sender` is the current NFT owner, or an authorized
    ///  operator of the current owner.
    /// @param _approved The new approved NFT controller
    /// @param _tokenId The NFT to approve
    function approve(address _approved, uint256 _tokenId) external payable;

    /// @notice Enable or disable approval for a third party ("operator") to manage
    ///  all of `msg.sender`'s assets
    /// @dev Emits the ApprovalForAll event. The contract MUST allow
    ///  multiple operators per owner.
    /// @param _operator Address to add to the set of authorized operators
    /// @param _approved True if the operator is approved, false to revoke approval
    function setApprovalForAll(address _operator, bool _approved) external;

    /// @notice Get the approved address for a single NFT
    /// @dev Throws if `_tokenId` is not a valid NFT.
    /// @param _tokenId The NFT to find the approved address for
    /// @return The approved address for this NFT, or the zero address if there is none
    function getApproved(uint256 _tokenId) external view returns (address);

    /// @notice Query if an address is an authorized operator for another address
    /// @param _owner The address that owns the NFTs
    /// @param _operator The address that acts on behalf of the owner
    /// @return True if `_operator` is an approved operator for `_owner`, false otherwise
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}




/** 
 *  SourceUnit: /home/mohammadreza/Downloads/SC (2)/Market/BidERC721.sol
*/
            
pragma solidity ^0.5.10;
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

////import "./IERC721.sol";

interface NFTAllowance {
//****************************************************************************
//* External Functions
//****************************************************************************
    function isAllowed(address _nftContract) external view returns(bool);

    function isRegistered(address _nftContract) external view returns(bool);

    function getNftContractsCount() external view returns(uint);
    
    function getNftContract(uint _index) external view returns(
        address _address,
        string memory _name,
        string memory _symbol,
        bool _allowed,
        bool _registered
        );

    function getPrimaryTokenContract() external view returns(address);

    function newNftContract(address _tokenContract) external;
    
    function isUserAuthorized(address _user) external view returns(bool);
    
}



/** 
 *  SourceUnit: /home/mohammadreza/Downloads/SC (2)/Market/BidERC721.sol
*/
            
pragma solidity ^0.5.10;
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
//////import "./IERC20.sol";
////import "./IERC721.sol";
////import "./INFTAllowance.sol";
//////import "./IERC721.sol";

contract BidERC721Data {
//****************************************************************************
//* Data
//****************************************************************************
    struct Auction {
        address nftTokenContract;
        uint itemId;
        uint baseValue;
        uint maxBidValue;
        address payable tokenSeller;
        address payable tokenBidder;
        uint40 bidTimeStart;
        uint40 bidTimeEnd;
        uint8 auctionStatus; // 1: Auction set, 2: Bid set, 3: Returned to seller, 4: paid to bidder 5: Cancelled
//        bytes12 collectionId;
    }
    struct History {
        mapping(uint => uint) history; // [index] => [Auction index]
        uint historyCount;
    }
    Auction[] auctions;
    mapping(address => uint[]) userAuctions;
    mapping(address => uint[]) myBids;
    mapping(address => mapping(uint => uint)) activeAuction ;
    mapping(address => mapping(uint => History)) nftTokenHistory;
//    mapping(address => Token) nftTokens;
//    address[] nftTokensArray;
//    mapping(bytes12 => uint[]) collectionAuctions;
//    bytes12[] collectionIds;
    uint[] activeAuctions;
    uint40 maxBidStartGap;
    uint40 maxBidDuration;
    uint16 winnerCommission = 50; // 50/1e4 => 0.5%
    uint16 primaryCreatorCommission = 1000; // 1000/1e4 => 10%
    uint16 secondaryCreatorCommission = 700; // 700/1e4 => 7%
    bool limitedToken = true;
    NFTAllowance NFTAllowanceContract;

//****************************************************************************
//* Modifiers
//****************************************************************************
    modifier nftContractAllowed(address _nftContract, uint _tokenId) {
        require(NFTAllowanceContract.isAllowed(_nftContract),"NFT contract is not allowed.");
        IERC721 erc721Token = IERC721(_nftContract);
        require(_tokenId <= erc721Token.totalSupply(),"Invalid NFT token id.");
        _;
    }

    modifier nftContractRegistered(address _nftContract) {
        require(NFTAllowanceContract.isRegistered(_nftContract),"NFT Contract is not registered.");
        _;
    }

    modifier validAuction(uint _index) {
        require(_index > 0 && _index < auctions.length,"Invalid auction index.");
        _;
    }

    modifier activeToken(address _tokenContract, uint _tokenId) {
        require(activeAuction[_tokenContract][_tokenId] > 0,"Inactive or invalid token.");
        _;
    }

//****************************************************************************
//* Events
//****************************************************************************
    event AuctionSet(address payable indexed _user, address indexed _nftContract, uint indexed _itemId);
    event BidSet(address payable indexed _user, uint indexed _index, uint _amount);
    event AuctionCancelled(address payable indexed _user, uint indexed _index);
    event BidWon(address payable indexed _user, uint indexed _index);
    event BidFailed(address payable indexed _user, uint indexed _index, uint _amount);
    event NoBid(address payable indexed _user, uint indexed _index);

}



/** 
 *  SourceUnit: /home/mohammadreza/Downloads/SC (2)/Market/BidERC721.sol
*/
            
pragma solidity ^0.5.10;
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
////import "./Ownable.sol";

contract benefitable is Ownable {
    address payable beneficiary; //wallet owner
    constructor() public {
        beneficiary = msg.sender;
    }

    function setBeneficiary(address payable _beneficiary) public isOwner {
        require(_beneficiary != beneficiary,"You must enter a new value.");
        beneficiary = _beneficiary;
    }

    function getBeneficiary() public view isOwner returns(address) {
        return(beneficiary);
    }

}



/** 
 *  SourceUnit: /home/mohammadreza/Downloads/SC (2)/Market/BidERC721.sol
*/
            
pragma solidity ^0.5.10;
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
////import "./Ownable.sol";

contract Adminable is Ownable {
    address payable admin;
    modifier isAdmin {
        require(admin == msg.sender,"You should be admin to call this function.");
        _;
    }
    
    constructor() public {
        admin = msg.sender;
    }

    function changeAdmin(address payable _admin) public isOwner {
        require(admin != _admin,"You must enter a new value.");
        admin = _admin;
    }

    function getAdmin() public view returns(address) {
        return(admin);
    }
    
}



/** 
 *  SourceUnit: /home/mohammadreza/Downloads/SC (2)/Market/BidERC721.sol
*/
            
pragma solidity ^0.5.4;

////import "./ERC721Full.sol";
////import "./Counters.sol";
//////import "./iERC20.sol";
////import "./MyUtils.sol";
////import "./Address.sol";
//////import "./ownable.sol";
////import "./Royalty.sol";

contract SecondaryToken is ERC721Full, MyUtils, Royalty {
    using SafeMath for uint;
    using Counters for Counters.Counter;
    using Address for address;

//****************************************************************************
//* Data
//****************************************************************************
    Counters.Counter private tokenIds;
    uint fee;
    string baseURL;
    string contractURL;
    bool mintActive = true;
    address creator;
    string[] tokenHashes;

//****************************************************************************
//* Modifiers
//****************************************************************************
    modifier isMintActive() {
        require(mintActive, "Buy is not active.");
        _;
    }    

//****************************************************************************
//* Main Functions
//****************************************************************************
    constructor(string memory _baseUrl, string memory _contractUrl, address _creator, string memory _name, string memory _symbol) ERC721Full(_name, _symbol) Royalty() public {
        baseURL = _baseUrl;
        contractURL = _contractUrl;
        creator = _creator;
        _registerInterface(this.mintItem.selector ^
            this.contractURI.selector ^ this.tokenURI.selector ^ this.getFee.selector ^ 
            this.getBaseURL.selector ^ this.SafeMintItem.selector);
    }

    function mintItem(string memory _hash) public payable isMintActive returns (
        uint _newId,
        string memory _tokenHash, 
        uint _currentSupply, 
        string memory _uri
        ) {
        require(creator == tx.origin,"Invalid token creator.");
        require(msg.value == fee, "Invalid value provided.");
        tokenIds.increment();
        _newId = tokenIds.current();
        _mint(creator, _newId);
        _mintItem(creator, _newId);
        tokenHashes.push(_hash);
        _uri = strConcat(baseURL, _hash);
        _currentSupply = totalSupply();
        return (_newId, _hash, _currentSupply, _uri);
    }

    function SafeMintItem(string memory _hash) public payable isMintActive returns(
        uint _newId, 
        string memory _tokenHash, 
        uint _currentSupply, 
        string memory _uri
        ) {
            address _sender = tx.origin;
            require(! _sender.isContract(),"Sender is a contract");
            return(mintItem(_hash));
        }

//****************************************************************************
//* Owner Functions
//****************************************************************************
    function setBaseURL(string calldata _baseURL) external isOwner {
        baseURL = _baseURL;
    }

    function setContractURL(string calldata _contractURL) external isOwner {
        contractURL = _contractURL;
    }

    function setFee(uint _fee) external isOwner {
        fee = _fee;
    }

    function setMintActive(bool _active) external isOwner {
        mintActive = _active;
    }

    function getMintActive() external view returns(bool _isActive) {
        return(mintActive);
    }

    function transferETHFromContract(uint _value) external isOwner {
        require(_value <= address(this).balance, "Not enough tokens exists.");
        owner.transfer(_value);
    }

//****************************************************************************
//* Getter Functions
//****************************************************************************

    function contractURI() external view returns (string memory) {
        return contractURL;
    }

    function tokenURI(uint256 tokenId) external view returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return strConcat(baseURL, uintToString(tokenId));
    }

    function getFee() external view returns (uint){
        return fee;
    }

    function getBaseURL() external view returns (string memory){
        return baseURL;
    }

}



/** 
 *  SourceUnit: /home/mohammadreza/Downloads/SC (2)/Market/BidERC721.sol
*/
            
pragma solidity 0.5.10;
////import "./Ownable.sol";
contract Proxy is Ownable {
// Logic layer variable:
    address delegatedAddress;
    function setDelegatedAddress(address _delegatedAddress) public isOwner {
        require(delegatedAddress == address(0),"Delegated address is set before.");
        require(_delegatedAddress != address(0),"Invalid new address.");
        delegatedAddress = _delegatedAddress;
    }

    function getDelegatedAddress() public view returns(address) {
        return(delegatedAddress);
    }

    function () payable external {
        address target = delegatedAddress;
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize)
            let result := delegatecall(gas, target, ptr, calldatasize, 0, 0)
            let size := returndatasize
            returndatacopy(ptr, 0, size)
            switch result
            case 0 { revert(ptr, size) }
            case 1 { return(ptr, size) }
        }
    }
}



/** 
 *  SourceUnit: /home/mohammadreza/Downloads/SC (2)/Market/BidERC721.sol
*/
            
pragma solidity ^0.5.10;
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
////import "./SafeMath.sol";
////import "./benefitable.sol";
////import "./IERC721.sol";
////import "./BidERC721Data.sol";

contract BidERC721Base is BidERC721Data, benefitable {
    using SafeMath for uint;

    constructor() public {
        auctions.push(Auction({
            nftTokenContract: address(0),
            itemId: 0,
            baseValue: 0,
            maxBidValue: 0,
            tokenSeller: address(0),
            tokenBidder: address(0),
            bidTimeStart: 0,
            bidTimeEnd: 0,
            auctionStatus: 0
        }));
    }
    
//****************************************************************************
//* Main Functions
//****************************************************************************
    function setAuction(
        address _tokenContract, 
        uint _tokenId,
        bytes12 _collectionId,
        uint _baseValue,
        uint40 _bidTimeStart,
        uint40 _bidTimeEnd
        ) public nftContractAllowed(_tokenContract, _tokenId) {
        require(_bidTimeStart > now,"Auction time start is over.");
        require(_bidTimeStart <= now + maxBidStartGap,"Auction start time is too late.");
        require(_bidTimeEnd <= _bidTimeStart + maxBidDuration,"Auction end time is too late.");
        require(activeAuction[_tokenContract][_tokenId] == 0,"This NFT token is in an active auction yet.");
        IERC721 erc721Token = IERC721(_tokenContract);
        require (erc721Token.getApproved(_tokenId) == address(this),"NFT token must be approved to the market contract.");
        erc721Token.transferFrom(erc721Token.ownerOf(_tokenId), address(this), _tokenId);
        require(_collectionId != 0x0,"Invalid collection id.");
        uint _index = auctions.length;
        auctions.push(Auction({
            nftTokenContract: _tokenContract,
            itemId: _tokenId,
            baseValue: _baseValue,
            maxBidValue: 0,
            tokenSeller: msg.sender,
            tokenBidder: address(0),
            bidTimeStart: _bidTimeStart,
            bidTimeEnd: _bidTimeEnd,
            auctionStatus: 1 // 1: Auction set
        }));
//        collectionAuctions[_collectionId].push(_index);
//        if (!inArray(_collectionId, collectionIds))
//            collectionIds.push(_collectionId);
        userAuctions[msg.sender].push(_index);
        activeAuction[_tokenContract][_tokenId] = _index;
        History storage _history = nftTokenHistory[_tokenContract][_tokenId];
        _history.history[_history.historyCount] = _index;
        _history.historyCount++;
        activeAuctions.push(_index);
        emit AuctionSet(msg.sender, _tokenContract, _tokenId);
    }

    function cancelAuction(
            address _tokenContract, 
            uint _tokenId
        ) public activeToken(_tokenContract, _tokenId) {
        uint _index = activeAuction[_tokenContract][_tokenId];
        cancelAuctionById(_index);
    }

    function cancelAuctionById(
            uint _index
        ) public {
        Auction storage _auction = auctions[_index];
        require(_auction.auctionStatus == 1,"Aution is not cancellable.");
        require(_auction.tokenSeller == msg.sender,"You are not token seller.");
        _auction.auctionStatus = 5;
        _payErc721Token(_auction.nftTokenContract, _auction.itemId, msg.sender);
        _removeActiveAuctionsElement(_index);
        activeAuction[_auction.nftTokenContract][_auction.itemId] = 0;
        emit AuctionCancelled(msg.sender, _index);
    }
    
    function setBid(
            address _tokenContract, 
            uint _tokenId
        ) public payable activeToken(_tokenContract, _tokenId) {
        uint _index = activeAuction[_tokenContract][_tokenId];
        setBidById(_index);
    }
    
    function setBidById(
            uint _index
        ) public payable {
        Auction storage _auction = auctions[_index];
        require(_auction.auctionStatus < 3,"Invalid auction state.");
        require(now >= _auction.bidTimeStart && now <= _auction.bidTimeEnd,"Not auction time.");
        uint _value = msg.value;
        require(_auction.auctionStatus != 1 || _value > _auction.baseValue,"You must bid more than base value.");
        require(_auction.auctionStatus != 2 || _value > _auction.maxBidValue,"You must bid more than current bid.");
        if (_auction.auctionStatus == 1) {
            _auction.auctionStatus = 2;
        } else if (_auction.auctionStatus == 2) {
            _payToken(_auction.tokenBidder, _auction.maxBidValue);
            emit BidFailed(msg.sender, _index, _auction.maxBidValue);
        }
        _auction.maxBidValue = _value;
        _auction.tokenBidder = msg.sender;
        myBids[msg.sender].push(_index);
        emit BidSet(msg.sender, _index, _value);
    }
    
    function withdrawNft(
            address _tokenContract, 
            uint _tokenId
        ) public activeToken(_tokenContract, _tokenId) {
        uint _index = activeAuction[_tokenContract][_tokenId];
        withdrawNftById(_index);
    }
        
    function withdrawNftById(
            uint _index
        ) public {
        Auction storage _auction = auctions[_index];
        require(now > _auction.bidTimeEnd,"Bid time is not over.");
        require(_auction.auctionStatus == 1 || _auction.auctionStatus == 2,"Invalid auction status.");
        if (_auction.auctionStatus == 1) {
            require(msg.sender == _auction.tokenSeller,"You are not NFT token owner.");
            _auction.auctionStatus = 3;
            _payErc721Token(_auction.nftTokenContract, _auction.itemId, msg.sender);
            emit NoBid(msg.sender, _index);
        } else if (_auction.auctionStatus == 2) {
            require(msg.sender == _auction.tokenBidder || msg.sender == _auction.tokenSeller,"You are not NFT token buyer or bider.");
            IERC721 erc721Token = IERC721(_auction.nftTokenContract);
            address payable _royaltyOwner = erc721Token.getRoyaltyOwner(_auction.itemId);
            uint _commissionShare = _auction.maxBidValue.mul(winnerCommission)/1e4;
            uint16 creatorCommission;
            if (NFTAllowanceContract.getPrimaryTokenContract() == _auction.nftTokenContract)
                creatorCommission = primaryCreatorCommission;
            else
                creatorCommission = secondaryCreatorCommission;
            uint _royaltyOwnerShare = _auction.maxBidValue.mul(creatorCommission)/1e4;
            uint _sellerShare = _auction.maxBidValue.sub(_commissionShare).sub(_royaltyOwnerShare);
            if (_sellerShare != 0)
                _payToken(_auction.tokenSeller, _sellerShare);
            if (_royaltyOwnerShare != 0)
                _payToken(_royaltyOwner, _royaltyOwnerShare);
            if (winnerCommission != 0)
                _payToken(beneficiary, _commissionShare);
            _auction.auctionStatus = 4;
            _payErc721Token(_auction.nftTokenContract, _auction.itemId, _auction.tokenBidder);
            emit BidWon(msg.sender, _index);
        }
        _removeActiveAuctionsElement(_index);
        activeAuction[_auction.nftTokenContract][_auction.itemId] = 0;
    }

//****************************************************************************
//* Internal Functions
//****************************************************************************
    function _payToken(address payable _receiver, uint _amount) internal {
        _receiver.transfer(_amount);
    }
    
    function _payErc721Token(address _tokenContract, uint _tokenId, address payable _receiver) internal {
        IERC721 erc721Token = IERC721(_tokenContract);
        erc721Token.safeTransferFrom(address(this), _receiver, _tokenId);
    }
    
    function _removeActiveAuctionsElement(uint _index) internal {
        uint j;
        bool _found = false;
        for (uint i = 0; i < activeAuctions.length; i++) {
            if (activeAuctions[i] == _index) {
                j = i;
                _found = true;
                break;
            }
        }
        if (_found) {
            activeAuctions[j] = activeAuctions[activeAuctions.length -1];
            activeAuctions.length--;
            //activeAuctions[activeAuctions.length-1] = 0; // for upper Solidity versions.
        }
    }

    function inArray(bytes12 _needle, bytes12[] storage _hayStack) internal view returns(bool) {
        uint _len = _hayStack.length;
        for (uint i = 0; i < _len; i++) {
            if (_hayStack[i] == _needle)
                return(true);
        }
        return(false);
    }

}

/** 
 *  SourceUnit: /home/mohammadreza/Downloads/SC (2)/Market/BidERC721.sol
*/

pragma solidity ^0.5.10;
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

// BSC Testnet: 0x6759bf5F653DC225bCa99e54D154f13154ee9356

////import "./BidERC721Base.sol";
////import "./Proxy.sol";
//////import "./SecondaryToken/IERC721.sol";
////import "./SecondaryToken.sol";
////import "./Adminable.sol";
//////import "./BidERC721Getters.sol";

contract BidERC721 is BidERC721Base, Adminable, Proxy
//    , BidERC721Getters 
    {

//****************************************************************************
//* Setter Functions
//****************************************************************************
    function setMaxBidStartGap(uint40 _maxBidStartGap) public isOwner {
        require(maxBidStartGap != _maxBidStartGap,"Value is set before.");
        maxBidStartGap = _maxBidStartGap;
    }
    
    function setMaxBidDuration(uint40 _maxBidDuration) public isOwner {
        require(maxBidDuration != _maxBidDuration,"Value is set before.");
        maxBidDuration = _maxBidDuration;
    }
    
    function setWinnerCommission(uint16 _winnerCommission) public isOwner {
        require(winnerCommission != _winnerCommission,"Value is set before.");
        require(_winnerCommission < 1e4,"Invalid Value.");
        winnerCommission = _winnerCommission;
    }
    
    function setPrimaryCreatorCommission(uint16 _primaryCreatorCommission) public isOwner {
        require(primaryCreatorCommission != _primaryCreatorCommission,"Value is set before.");
        require(_primaryCreatorCommission < 1e4,"Invalid Value.");
        primaryCreatorCommission = _primaryCreatorCommission;
    }

    function setSecondaryCreatorCommission(uint16 _secondaryCreatorCommission) public isOwner {
        require(secondaryCreatorCommission != _secondaryCreatorCommission,"Value is set before.");
        require(_secondaryCreatorCommission < 1e4,"Invalid Value.");
        secondaryCreatorCommission = _secondaryCreatorCommission;
    }

    function setNFTAllowanceContract(address _nftAllowance) public isOwner {
        require(address(NFTAllowanceContract) == address(0));
        NFTAllowanceContract = NFTAllowance(_nftAllowance);
    }
    
//****************************************************************************
//* Getter Functions
//****************************************************************************
// Getter functions is moved to BidERC721Getters contract and the main contract 
// has access to it via proxy.

}