pragma solidity ^0.5.0;

import "../Contract/ERCXMintable.sol";
import "../Contract/ERCXBurnable.sol";

/**
 * @title ERCXFullmock
 * This mock just provides a public safeMint, mint, and burn functions for testing purposes
 */
contract ERCXTEST is ERCXMintable, ERCXBurnable {
    constructor(string memory name, string memory symbol)
        public
        ERCXMintable(name, symbol)
    {}

    function exists(uint256 itemId) public view returns (bool) {
        return _exists(itemId, 1);
    }

    function setItemURI(uint256 itemId, string memory uri) public onlyMinter {
        _setItemURI(itemId, uri);
    }

    function setBaseURI(string memory uri) public onlyMinter {
        _setBaseURI(uri);
    }

}

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
}

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

pragma solidity ^0.5.0;

import "../../introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
contract IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of NFTs in `owner`'s account.
     */
    function balanceOf(address owner) public view returns (uint256 balance);

    /**
     * @dev Returns the owner of the NFT specified by `tokenId`.
     */
    function ownerOf(uint256 tokenId) public view returns (address owner);

    /**
     * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
     * another (`to`).
     *
     * 
     *
     * Requirements:
     * - `from`, `to` cannot be zero.
     * - `tokenId` must be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this
     * NFT by either `approve` or `setApproveForAll`.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public;
    /**
     * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
     * another (`to`).
     *
     * Requirements:
     * - If the caller is not `from`, it must be approved to move this NFT by
     * either `approve` or `setApproveForAll`.
     */
    function transferFrom(address from, address to, uint256 tokenId) public;
    function approve(address to, uint256 tokenId) public;
    function getApproved(uint256 tokenId) public view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) public;
    function isApprovedForAll(address owner, address operator) public view returns (bool);


    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public;
}

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
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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

pragma solidity ^0.5.0;

import "./IERC165.sol";

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

pragma solidity ^0.5.0;

import "../math/SafeMath.sol";

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

pragma solidity ^0.5.0;

/**
 * @title ERCX token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERCX asset contracts.
 */
contract IERCXReceiver {
    /**
    * @notice Handle the receipt of an NFT
    * @dev The ERCX smart contract calls this function on the recipient
    * after a {IERCX-safeTransferFrom}. This function MUST return the function selector,
    * otherwise the caller will revert the transaction. The selector to be
    * returned can be obtained as `this.onERCXReceived.selector`. This
    * function MAY throw to revert and reject the transfer.
    * Note: the ERCX contract address is always the message sender.
    * @param operator The address which called `safeTransferFrom` function
    * @param from The address which previously owned the token
    * @param itemId The NFT identifier which is being transferred
    * @param data Additional data with no specified format
    * @return bytes4 `bytes4(keccak256("onERCXReceived(address,address,uint256,uint256,bytes)"))`
    */
    function onERCXReceived(
        address operator,
        address from,
        uint256 itemId,
        uint256 layer,
        bytes memory data
    ) public returns (bytes4);
}

pragma solidity ^0.5.0;

import './IERCX.sol';
contract IERCXMetadata is IERCX {
  function itemURI(uint256 itemId) public view returns (string memory);
  function name() external view returns (string memory);
  function symbol() external view returns (string memory);
}

pragma solidity ^0.5.0;

import "./IERCX.sol";

contract IERCXEnumerable is IERCX {
    function totalNumberOfItems() public view returns (uint256);
    function itemOfUserByIndex(address owner, uint256 index)
        public
        view
        returns (uint256 itemId);
    function itemOfOwnerByIndex(address owner, uint256 index)
        public
        view
        returns (uint256 itemId);
    function itemByIndex(uint256 index) public view returns (uint256);

}

pragma solidity ^0.5.0;

import "../../Libraries/introspection/IERC165.sol";

contract IERCX is IERC165 {
    event TransferUser(
        address indexed from,
        address indexed to,
        uint256 indexed itemId,
        address operator
    );
    event ApprovalForUser(
        address indexed user,
        address indexed approved,
        uint256 itemId
    );
    event TransferOwner(
        address indexed from,
        address indexed to,
        uint256 indexed itemId,
        address operator
    );
    event ApprovalForOwner(
        address indexed owner,
        address indexed approved,
        uint256 itemId
    );
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );
    event LienApproval(address indexed to, uint256 indexed itemId);
    event TenantRightApproval(address indexed to, uint256 indexed itemId);
    event LienSet(address indexed to, uint256 indexed itemId, bool status);
    event TenantRightSet(
        address indexed to,
        uint256 indexed itemId,
        bool status
    );

    function balanceOfOwner(address owner) public view returns (uint256);

    function balanceOfUser(address user) public view returns (uint256);

    function userOf(uint256 itemId) public view returns (address);

    function ownerOf(uint256 itemId) public view returns (address);

    function safeTransferOwner(address from, address to, uint256 itemId) public;
    function safeTransferOwner(
        address from,
        address to,
        uint256 itemId,
        bytes memory data
    ) public;

    function safeTransferUser(address from, address to, uint256 itemId) public;
    function safeTransferUser(
        address from,
        address to,
        uint256 itemId,
        bytes memory data
    ) public;

    function approveForOwner(address to, uint256 itemId) public;
    function getApprovedForOwner(uint256 itemId) public view returns (address);

    function approveForUser(address to, uint256 itemId) public;
    function getApprovedForUser(uint256 itemId) public view returns (address);

    function setApprovalForAll(address operator, bool approved) public;
    function isApprovedForAll(address requester, address operator)
        public
        view
        returns (bool);

    function approveLien(address to, uint256 itemId) public;
    function getApprovedLien(uint256 itemId) public view returns (address);
    function setLien(uint256 itemId) public;
    function getCurrentLien(uint256 itemId) public view returns (address);
    function revokeLien(uint256 itemId) public;

    function approveTenantRight(address to, uint256 itemId) public;
    function getApprovedTenantRight(uint256 itemId)
        public
        view
        returns (address);
    function setTenantRight(uint256 itemId) public;
    function getCurrentTenantRight(uint256 itemId)
        public
        view
        returns (address);
    function revokeTenantRight(uint256 itemId) public;
}

pragma solidity ^0.5.0;

library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

  /**
   * @dev give an account access to this role
   */
  function add(Role storage role, address account) internal {
    require(account != address(0));
    role.bearer[account] = true;
  }

  /**
   * @dev remove an account's access to this role
   */
  function remove(Role storage role, address account) internal {
    require(account != address(0));
    role.bearer[account] = false;
  }

  /**
   * @dev check if an account has this role
   * @return bool
   */
  function has(Role storage role, address account)
    internal
    view
    returns (bool)
  {
    require(account != address(0));
    return role.bearer[account];
  }
}

pragma solidity ^0.5.0;

import './Roles.sol';

contract MinterRole {
  using Roles for Roles.Role;

  event MinterAdded(address indexed account);
  event MinterRemoved(address indexed account);

  Roles.Role private minters;

  constructor() public {
    minters.add(msg.sender);
  }

  modifier onlyMinter() {
    require(isMinter(msg.sender));
    _;
  }

  function isMinter(address account) public view returns (bool) {
    return minters.has(account);
  }

  function addMinter(address account) public onlyMinter {
    minters.add(account);
    emit MinterAdded(account);
  }

  function renounceMinter() public {
    minters.remove(msg.sender);
  }

  function _removeMinter(address account) internal {
    minters.remove(account);
    emit MinterRemoved(account);
  }
}

pragma solidity ^0.5.0;

import './MinterRole.sol';
import './ERCXFull.sol';

contract ERCXMintable is ERCXFull, MinterRole {
  event MintingFinished();

  bool private _mintingFinished = false;

  modifier onlyBeforeMintingFinished() {
    require(!_mintingFinished);
    _;
  }

  constructor(string memory name, string memory symbol) ERCXFull(name, symbol)
    public
  {
  }

  /**
   * @return true if the minting is finished.
   */
  function mintingFinished() public view returns(bool) {
    return _mintingFinished;
  }

  /**
   * @dev Function to mint items
   * @param to The address that will receive the minted items.
   * @param itemId The item id to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(
    address to,
    uint256 itemId
  )
    public
    onlyMinter
    onlyBeforeMintingFinished
    returns (bool)
  {
    _mint(to, itemId);
    return true;
  }

  function mintWithItemURI(
    address to,
    uint256 itemId,
    string memory itemURI
  )
    public
    onlyMinter
    onlyBeforeMintingFinished
    returns (bool)
  {
    mint(to, itemId);
    _setItemURI(itemId, itemURI);
    return true;
  }

  /**
   * @dev Function to stop minting new items.
   * @return True if the operation was successful.
   */
  function finishMinting()
    public
    onlyMinter
    onlyBeforeMintingFinished
    returns (bool)
  {
    _mintingFinished = true;
    emit MintingFinished();
    return true;
  }
}

pragma solidity ^0.5.0;

import './ERCX.sol';
import '../Interface/IERCXMetadata.sol';

contract ERCXMetadata is ERC165, ERCX, IERCXMetadata {
  // item name
  string internal _name;

  // item symbol
  string internal _symbol;

  // Base URI
  string private _baseURI;

  // Optional mapping for item URIs
  mapping(uint256 => string) private _itemURIs;

  bytes4 private constant InterfaceId_ERCXMetadata =
    bytes4(keccak256('name()')) ^
    bytes4(keccak256('symbol()')) ^
    bytes4(keccak256('itemURI(uint256)'));

  /**
   * @dev Constructor function
   */
  constructor(string memory name, string memory symbol) public {
    _name = name;
    _symbol = symbol;

    // register the supported interfaces to conform to ERCX via ERC165
    _registerInterface(InterfaceId_ERCXMetadata);
  }

  /**
   * @dev Gets the item name
   * @return string representing the item name
   */
  function name() external view returns (string memory) {
    return _name;
  }

  /**
   * @dev Gets the item symbol
   * @return string representing the item symbol
   */
  function symbol() external view returns (string memory) {
    return _symbol;
  }

  /**
   * @dev Returns an URI for a given item ID
   * Throws if the item ID does not exist. May return an empty string.
   * @param itemId uint256 ID of the item to query
   */
  function itemURI(uint256 itemId) public view returns (string memory) {
    require(
      _exists(itemId,1),
      "URI query for nonexistent item");

    string memory _itemURI = _itemURIs[itemId];

    // Even if there is a base URI, it is only appended to non-empty item-specific URIs
    if (bytes(_itemURI).length == 0) {
        return "";
    } else {
        // abi.encodePacked is being used to concatenate strings
        return string(abi.encodePacked(_baseURI, _itemURI));
    }

  }

  /**
  * @dev Returns the base URI set via {_setBaseURI}. This will be
  * automatically added as a preffix in {itemURI} to each item's URI, when
  * they are non-empty.
  */
  function baseURI() external view returns (string memory) {
      return _baseURI;
  }

  /**
   * @dev Internal function to set the item URI for a given item
   * Reverts if the item ID does not exist
   * @param itemId uint256 ID of the item to set its URI
   * @param uri string URI to assign
   */
  function _setItemURI(uint256 itemId, string memory uri) internal {
    require(_exists(itemId,1));
    _itemURIs[itemId] = uri;
  }

  /**
    * @dev Internal function to set the base URI for all item IDs. It is
    * automatically added as a prefix to the value returned in {itemURI}.
    *
    * _Available since v2.5.0._
    */
  function _setBaseURI(string memory baseUri) internal {
      _baseURI = baseUri;
  }

  /**
   * @dev Internal function to burn a specific item
   * Reverts if the item does not exist
   * @param itemId uint256 ID of the item being burned by the msg.sender
   */
  function _burn(uint256 itemId) internal {
    super._burn(itemId);

    // Clear metadata (if any)
    if (bytes(_itemURIs[itemId]).length != 0) {
      delete _itemURIs[itemId];
    }

  }
}

pragma solidity ^0.5.0;

import './ERCX.sol';
import './ERCXEnumerable.sol';
import './ERCXMetadata.sol';
import './ERCX721fier.sol';


contract ERCXFull is ERCX, ERCXEnumerable, ERCXMetadata, ERCX721fier {
  constructor(string memory name, string memory symbol) ERCXMetadata(name, symbol)
    public
  {
  }
}

pragma solidity ^0.5.0;

import "./ERCX.sol";
import "../Interface/IERCXEnumerable.sol";

contract ERCXEnumerable is ERC165, ERCX, IERCXEnumerable {
    // Mapping from layer to owner to list of owned item IDs
    mapping(uint256 => mapping(address => uint256[])) private _ownedItems;

    // Mapping from layer to item ID to index of the owner items list
    mapping(uint256 => mapping(uint256 => uint256)) private _ownedItemsIndex;

    // Array with all item ids, used for enumeration
    uint256[] private _allItems;

    // Mapping from item id to position in the allItems array
    mapping(uint256 => uint256) private _allItemsIndex;

    bytes4 private constant _InterfaceId_ERCXEnumerable = bytes4(
        keccak256("totalNumberOfItems()")
    ) ^
        bytes4(keccak256("itemOfOwnerByIndex(address,uint256,uint256)")) ^
        bytes4(keccak256("itemByIndex(uint256)"));

    /**
   * @dev Constructor function
   */
    constructor() public {
        // register the supported interface to conform to ERCX via ERC165
        _registerInterface(_InterfaceId_ERCXEnumerable);
    }

    /**
   * @dev Gets the item ID at a given index of the items list of the requested user
   * @param user address owning the items list to be accessed
   * @param index uint256 representing the index to be accessed of the requested items list
   * @return uint256 item ID at the given index of the items list owned by the requested address
   */

    function itemOfUserByIndex(address user, uint256 index)
        public
        view
        returns (uint256)
    {
        require(index < balanceOfUser(user));
        return _ownedItems[1][user][index];
    }

    /**
   * @dev Gets the item ID at a given index of the items list of the requested owner
   * @param owner address owning the items list to be accessed
   * @param index uint256 representing the index to be accessed of the requested items list
   * @return uint256 item ID at the given index of the items list owned by the requested address
   */

    function itemOfOwnerByIndex(address owner, uint256 index)
        public
        view
        returns (uint256)
    {
        require(index < balanceOfOwner(owner));
        return _ownedItems[2][owner][index];
    }

    /**
   * @dev Gets the total amount of items stored by the contract
   * @return uint256 representing the total amount of items
   */
    function totalNumberOfItems() public view returns (uint256) {
        return _allItems.length;
    }

    /**
   * @dev Gets the item ID at a given index of all the items in this contract
   * Reverts if the index is greater or equal to the total number of items
   * @param index uint256 representing the index to be accessed of the items list
   * @return uint256 item ID at the given index of the items list
   */
    function itemByIndex(uint256 index) public view returns (uint256) {
        require(index < totalNumberOfItems());
        return _allItems[index];
    }

    /**
    * @dev Internal function to transfer ownership of a given item ID to another address.
    * As opposed to transfer, this imposes no restrictions on msg.sender.
    * @param from current owner of the item
    * @param to address to receive the ownership of the given item ID
    * @param itemId uint256 ID of the item to be transferred
    * @param layer uint256 number to specify the layer
    */
    function _transfer(address from, address to, uint256 itemId, uint256 layer)
        internal
    {
        super._transfer(from, to, itemId, layer);
        _removeItemFromOwnerEnumeration(from, itemId, layer);
        _addItemToOwnerEnumeration(to, itemId, layer);
    }

    /**
    * @dev Internal function to mint a new item.
    * Reverts if the given item ID already exists.
    * @param to address the beneficiary that will own the minted item
    * @param itemId uint256 ID of the item to be minted
    */
    function _mint(address to, uint256 itemId) internal {
        super._mint(to, itemId);

        _addItemToOwnerEnumeration(to, itemId, 1);
        _addItemToOwnerEnumeration(to, itemId, 2);

        _addItemToAllItemsEnumeration(itemId);
    }

    /**
    * @dev Internal function to burn a specific item.
    * Reverts if the item does not exist.
    * Deprecated, use {ERCX-_burn} instead.
    * @param itemId uint256 ID of the item being burned
    */
    function _burn(uint256 itemId) internal {
        address user = userOf(itemId);
        address owner = ownerOf(itemId);

        super._burn(itemId);

        _removeItemFromOwnerEnumeration(user, itemId, 1);
        _removeItemFromOwnerEnumeration(owner, itemId, 2);

        // Since itemId will be deleted, we can clear its slot in _ownedItemsIndex to trigger a gas refund
        _ownedItemsIndex[1][itemId] = 0;
        _ownedItemsIndex[2][itemId] = 0;

        _removeItemFromAllItemsEnumeration(itemId);

    }

    /**
    * @dev Private function to add a item to this extension's ownership-tracking data structures.
    * @param to address representing the new owner of the given item ID
    * @param itemId uint256 ID of the item to be added to the items list of the given address
    */
    function _addItemToOwnerEnumeration(
        address to,
        uint256 itemId,
        uint256 layer
    ) private {
        _ownedItemsIndex[layer][itemId] = _ownedItems[layer][to].length;
        _ownedItems[layer][to].push(itemId);
    }

    /**
    * @dev Private function to add a item to this extension's item tracking data structures.
    * @param itemId uint256 ID of the item to be added to the items list
    */
    function _addItemToAllItemsEnumeration(uint256 itemId) private {
        _allItemsIndex[itemId] = _allItems.length;
        _allItems.push(itemId);
    }

    /**
    * @dev Private function to remove a item from this extension's ownership-tracking data structures. Note that
    * while the item is not assigned a new owner, the `_ownedItemsIndex` mapping is _not_ updated: this allows for
    * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
    * This has O(1) time complexity, but alters the order of the _ownedItems array.
    * @param from address representing the previous owner of the given item ID
    * @param itemId uint256 ID of the item to be removed from the items list of the given address
    */
    function _removeItemFromOwnerEnumeration(
        address from,
        uint256 itemId,
        uint256 layer
    ) private {
        // To prevent a gap in from's items array, we store the last item in the index of the item to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastItemIndex = _ownedItems[layer][from].length.sub(1);
        uint256 itemIndex = _ownedItemsIndex[layer][itemId];

        // When the item to delete is the last item, the swap operation is unnecessary
        if (itemIndex != lastItemIndex) {
            uint256 lastItemId = _ownedItems[layer][from][lastItemIndex];

            _ownedItems[layer][from][itemIndex] = lastItemId; // Move the last item to the slot of the to-delete item
            _ownedItemsIndex[layer][lastItemId] = itemIndex; // Update the moved item's index
        }

        // This also deletes the contents at the last position of the array
        _ownedItems[layer][from].length--;

        // Note that _ownedItemsIndex[itemId] hasn't been cleared: it still points to the old slot (now occupied by
        // lastItemId, or just over the end of the array if the item was the last one).

    }

    /**
    * @dev Private function to remove a item from this extension's item tracking data structures.
    * This has O(1) time complexity, but alters the order of the _allItems array.
    * @param itemId uint256 ID of the item to be removed from the items list
    */
    function _removeItemFromAllItemsEnumeration(uint256 itemId) private {
        // To prevent a gap in the items array, we store the last item in the index of the item to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastItemIndex = _allItems.length.sub(1);
        uint256 itemIndex = _allItemsIndex[itemId];

        // When the item to delete is the last item, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted item is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeItemFromOwnerEnumeration)
        uint256 lastItemId = _allItems[lastItemIndex];

        _allItems[itemIndex] = lastItemId; // Move the last item to the slot of the to-delete item
        _allItemsIndex[lastItemId] = itemIndex; // Update the moved item's index

        // This also deletes the contents at the last position of the array
        _allItems.length--;
        _allItemsIndex[itemId] = 0;
    }
}

pragma solidity ^0.5.0;

import "./ERCXFull.sol";

/**
 * @title ERC721 Burnable Token
 * @dev ERC721 Token that can be irreversibly burned (destroyed).
 */
contract ERCXBurnable is ERCXFull {
  /**
    * @dev Burns a specific ERCX item.
    * @param itemId uint256 id of the ERCXFull item to be burned.
    */
  function burn(uint256 itemId) public {
      _burn(itemId);
  }
}

pragma solidity ^0.5.0;

import "./ERCX.sol";
import "../../Libraries/token/ERC721/IERC721.sol";
import "../../Libraries/token/ERC721/IERC721Receiver.sol";


/**
 * @title ERC721 Non-Fungible Token Standard compatible layer
 * Each items here represents owner of the item set.
 * By implementing this contract set, ERCX can pretend to be an ERC721 contrtact set.
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
contract ERCX721fier is ERC165, IERC721, ERCX {
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    constructor() public {
        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721);
    }

    function balanceOf(address owner) public view returns (uint256) {
        return balanceOfOwner(owner);
    }

    function ownerOf(uint256 itemId) public view returns (address) {
        return super.ownerOf(itemId);
    }

    function approve(address to, uint256 itemId) public {
        approveForOwner(to, itemId);
        address owner = ownerOf(itemId);
        emit Approval(owner, to, itemId);
    }

    function getApproved(uint256 itemId) public view returns (address) {
        return getApprovedForOwner(itemId);
    }

    function transferFrom(address from, address to, uint256 itemId) public {
        require(_isEligibleForTransfer(msg.sender, itemId, 2));
        if (getCurrentTenantRight(itemId) == address(0)) {
            _transfer(from, to, itemId, 1);
            _transfer(from, to, itemId, 2);
        } else {
            _transfer(from, to, itemId, 2);
        }
        emit Transfer(from, to, itemId);
    }

    function safeTransferFrom(address from, address to, uint256 itemId) public {
        safeTransferFrom(from, to, itemId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 itemId,
        bytes memory data
    ) public {
        transferFrom(from, to, itemId);
        require(
            _checkOnERC721Received(from, to, itemId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 itemId,
        bytes memory data
    ) internal returns (bool) {
        if (!to.isContract()) {
            return true;
        }

        bytes4 retval = IERC721Receiver(to).onERC721Received(
            msg.sender,
            from,
            itemId,
            data
        );
        return (retval == _ERC721_RECEIVED);
    }
}

pragma solidity ^0.5.0;

import "../../Libraries/introspection/ERC165.sol";
import "../Interface/IERCX.sol";
import "../../Libraries/utils/Address.sol";
import "../../Libraries/math/SafeMath.sol";
import "../../Libraries/drafts/Counters.sol";
import "../Interface/IERCXReceiver.sol";

contract ERCX is ERC165, IERCX {
    using SafeMath for uint256;
    using Address for address;
    using Counters for Counters.Counter;

    bytes4 private constant _ERCX_RECEIVED = 0x11111111;
    //bytes4(keccak256("onERCXReceived(address,address,uint256,bytes)"));

    // Mapping from item ID to layer to owner
    mapping(uint256 => mapping(uint256 => address)) private _itemOwner;

    // Mapping from item ID to layer to approved address
    mapping(uint256 => mapping(uint256 => address)) private _transferApprovals;

    // Mapping from owner to layer to number of owned item
    mapping(address => mapping(uint256 => Counters.Counter)) private _ownedItemsCount;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Mapping from item ID to approved address of setting lien
    mapping(uint256 => address) private _lienApprovals;

    // Mapping from item ID to contract address of lien
    mapping(uint256 => address) private _lienAddress;

    // Mapping from item ID to approved address of setting tenant right agreement
    mapping(uint256 => address) private _tenantRightApprovals;

    // Mapping from item ID to contract address of TenantRight
    mapping(uint256 => address) private _tenantRightAddress;

    bytes4 private constant _InterfaceId_ERCX = bytes4(
        keccak256("balanceOfOwner(address)")
    ) ^
        bytes4(keccak256("balanceOfUser(address)")) ^
        bytes4(keccak256("ownerOf(uint256)")) ^
        bytes4(keccak256("userOf(uint256)")) ^
        bytes4(keccak256("safeTransferOwner(address, address, uint256)")) ^
        bytes4(
            keccak256("safeTransferOwner(address, address, uint256, bytes)")
        ) ^
        bytes4(keccak256("safeTransferUser(address, address, uint256)")) ^
        bytes4(
            keccak256("safeTransferUser(address, address, uint256, bytes)")
        ) ^
        bytes4(keccak256("approveForOwner(address, uint256)")) ^
        bytes4(keccak256("getApprovedForOwner(uint256)")) ^
        bytes4(keccak256("approveForUser(address, uint256)")) ^
        bytes4(keccak256("getApprovedForUser(uint256)")) ^
        bytes4(keccak256("setApprovalForAll(address, bool)")) ^
        bytes4(keccak256("isApprovedForAll(address, address)")) ^
        bytes4(keccak256("approveLien(address, uint256)")) ^
        bytes4(keccak256("getApprovedLien(uint256)")) ^
        bytes4(keccak256("setLien(uint256)")) ^
        bytes4(keccak256("getCurrentLien(uint256)")) ^
        bytes4(keccak256("revokeLien(uint256)")) ^
        bytes4(keccak256("approveTenantRight(address, uint256)")) ^
        bytes4(keccak256("getApprovedTenantRight(uint256)")) ^
        bytes4(keccak256("setTenantRight(uint256)")) ^
        bytes4(keccak256("getCurrentTenantRight(uint256)")) ^
        bytes4(keccak256("revokeTenantRight(uint256)"));

    constructor() public {
        // register the supported interfaces to conform to ERCX via ERC165
        _registerInterface(_InterfaceId_ERCX);
    }

    /**
   * @dev Gets the balance of the specified address
   * @param owner address to query the balance of
   * @return uint256 representing the amount of items owned by the passed address in the specified layer
   */
    function balanceOfOwner(address owner) public view returns (uint256) {
        require(owner != address(0));
        uint256 balance = _ownedItemsCount[owner][2].current();
        return balance;
    }

    /**
   * @dev Gets the balance of the specified address
   * @param user address to query the balance of
   * @return uint256 representing the amount of items owned by the passed address
   */
    function balanceOfUser(address user) public view returns (uint256) {
        require(user != address(0));
        uint256 balance = _ownedItemsCount[user][1].current();
        return balance;
    }

    /**
   * @dev Gets the user of the specified item ID
   * @param itemId uint256 ID of the item to query the user of
   * @return owner address currently marked as the owner of the given item ID
   */
    function userOf(uint256 itemId) public view returns (address) {
        address user = _itemOwner[itemId][1];
        require(user != address(0));
        return user;
    }

    /**
   * @dev Gets the owner of the specified item ID
   * @param itemId uint256 ID of the item to query the owner of
   * @return owner address currently marked as the owner of the given item ID
   */
    function ownerOf(uint256 itemId) public view returns (address) {
        address owner = _itemOwner[itemId][2];
        require(owner != address(0));
        return owner;
    }

    /**
   * @dev Approves another address to transfer the user of the given item ID
   * The zero address indicates there is no approved address.
   * There can only be one approved address per item at a given time.
   * Can only be called by the item owner or an approved operator.
   * @param to address to be approved for the given item ID
   */
    function approveForUser(address to, uint256 itemId) public {
        address user = userOf(itemId);
        address owner = ownerOf(itemId);

        require(to != owner && to != user);
        require(
            msg.sender == user ||
                msg.sender == owner ||
                isApprovedForAll(user, msg.sender) ||
                isApprovedForAll(owner, msg.sender)
        );
        if (msg.sender == owner || isApprovedForAll(owner, msg.sender)) {
            require(getCurrentTenantRight(itemId) == address(0));
        }
        _transferApprovals[itemId][1] = to;
        emit ApprovalForUser(user, to, itemId);
    }

    /**
   * @dev Gets the approved address for the user of the item ID, or zero if no address set
   * Reverts if the item ID does not exist.
   * @param itemId uint256 ID of the item to query the approval of
   * @return address currently approved for the given item ID
   */
    function getApprovedForUser(uint256 itemId) public view returns (address) {
        require(_exists(itemId, 1));
        return _transferApprovals[itemId][1];
    }

    /**
   * @dev Approves another address to transfer the owner of the given item ID
   * The zero address indicates there is no approved address.
   * There can only be one approved address per item at a given time.
   * Can only be called by the item owner or an approved operator.
   * @param to address to be approved for the given item ID
   * @param itemId uint256 ID of the item to be approved
   */
    function approveForOwner(address to, uint256 itemId) public {
        address owner = ownerOf(itemId);

        require(to != owner);
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender));
        _transferApprovals[itemId][2] = to;
        emit ApprovalForOwner(owner, to, itemId);

    }

    /**
   * @dev Gets the approved address for the of the item ID, or zero if no address set
   * Reverts if the item ID does not exist.
   * @param itemId uint256 ID of the item to query the approval o
   * @return address currently approved for the given item ID
   */
    function getApprovedForOwner(uint256 itemId) public view returns (address) {
        require(_exists(itemId, 2));
        return _transferApprovals[itemId][2];
    }

    /**
   * @dev Sets or unsets the approval of a given operator
   * An operator is allowed to transfer all items of the sender on their behalf
   * @param to operator address to set the approval
   * @param approved representing the status of the approval to be set
   */
    function setApprovalForAll(address to, bool approved) public {
        require(to != msg.sender);
        _operatorApprovals[msg.sender][to] = approved;
        emit ApprovalForAll(msg.sender, to, approved);
    }

    /**
   * @dev Tells whether an operator is approved by a given owner
   * @param owner owner address which you want to query the approval of
   * @param operator operator address which you want to query the approval of
   * @return bool whether the given operator is approved by the given owner
   */
    function isApprovedForAll(address owner, address operator)
        public
        view
        returns (bool)
    {
        return _operatorApprovals[owner][operator];
    }

    /**
   * @dev Approves another address to set lien contract for the given item ID
   * The zero address indicates there is no approved address.
   * There can only be one approved address per item at a given time.
   * Can only be called by the item owner or an approved operator.
   * @param to address to be approved for the given item ID
   * @param itemId uint256 ID of the item to be approved
   */
    function approveLien(address to, uint256 itemId) public {
        address owner = ownerOf(itemId);
        require(to != owner);
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender));
        _lienApprovals[itemId] = to;
        emit LienApproval(to, itemId);
    }

    /**
   * @dev Gets the approved address for setting lien for a item ID, or zero if no address set
   * Reverts if the item ID does not exist.
   * @param itemId uint256 ID of the item to query the approval of
   * @return address currently approved for the given item ID
   */
    function getApprovedLien(uint256 itemId) public view returns (address) {
        require(_exists(itemId, 2));
        return _lienApprovals[itemId];
    }
    /**
   * @dev Sets lien agreements to already approved address
   * The lien address is allowed to transfer all items of the sender on their behalf
   * @param itemId uint256 ID of the item
   */
    function setLien(uint256 itemId) public {
        require(msg.sender == getApprovedLien(itemId));
        _lienAddress[itemId] = msg.sender;
        _clearLienApproval(itemId);
        emit LienSet(msg.sender, itemId, true);
    }

    /**
   * @dev Gets the current lien agreement address, or zero if no address set
   * Reverts if the item ID does not exist.
   * @param itemId uint256 ID of the item to query the lien address
   * @return address of the lien agreement address for the given item ID
   */
    function getCurrentLien(uint256 itemId) public view returns (address) {
        require(_exists(itemId, 2));
        return _lienAddress[itemId];
    }

    /**
   * @dev Revoke the lien agreements. Only the lien address can revoke.
   * @param itemId uint256 ID of the item
   */
    function revokeLien(uint256 itemId) public {
        require(msg.sender == getCurrentLien(itemId));
        _lienAddress[itemId] = address(0);
        emit LienSet(address(0), itemId, false);
    }

    /**
   * @dev Approves another address to set tenant right agreement for the given item ID
   * The zero address indicates there is no approved address.
   * There can only be one approved address per item at a given time.
   * Can only be called by the item owner or an approved operator.
   * @param to address to be approved for the given item ID
   * @param itemId uint256 ID of the item to be approved
   */
    function approveTenantRight(address to, uint256 itemId) public {
        address owner = ownerOf(itemId);
        require(to != owner);
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender));
        _tenantRightApprovals[itemId] = to;
        emit TenantRightApproval(to, itemId);
    }

    /**
   * @dev Gets the approved address for setting tenant right for a item ID, or zero if no address set
   * Reverts if the item ID does not exist.
   * @param itemId uint256 ID of the item to query the approval of
   * @return address currently approved for the given item ID
   */
    function getApprovedTenantRight(uint256 itemId)
        public
        view
        returns (address)
    {
        require(_exists(itemId, 2));
        return _tenantRightApprovals[itemId];
    }
    /**
   * @dev Sets the tenant right agreement to already approved address
   * The lien address is allowed to transfer all items of the sender on their behalf
   * @param itemId uint256 ID of the item
   */
    function setTenantRight(uint256 itemId) public {
        require(msg.sender == getApprovedTenantRight(itemId));
        _tenantRightAddress[itemId] = msg.sender;
        _clearTenantRightApproval(itemId);
        _clearTransferApproval(itemId, 1); //Reset transfer approval
        emit TenantRightSet(msg.sender, itemId, true);
    }

    /**
   * @dev Gets the current tenant right agreement address, or zero if no address set
   * Reverts if the item ID does not exist.
   * @param itemId uint256 ID of the item to query the tenant right address
   * @return address of the tenant right agreement address for the given item ID
   */
    function getCurrentTenantRight(uint256 itemId)
        public
        view
        returns (address)
    {
        require(_exists(itemId, 2));
        return _tenantRightAddress[itemId];
    }

    /**
   * @dev Revoke the tenant right agreement. Only the lien address can revoke.
   * @param itemId uint256 ID of the item
   */
    function revokeTenantRight(uint256 itemId) public {
        require(msg.sender == getCurrentTenantRight(itemId));
        _tenantRightAddress[itemId] = address(0);
        emit TenantRightSet(address(0), itemId, false);
    }

    /**
   * @dev Safely transfers the user of a given item ID to another address
   * If the target address is a contract, it must implement `onERCXReceived`,
   * which is called upon a safe transfer, and return the magic value
   * `bytes4(keccak256("onERCXReceived(address,address,uint256,bytes)"))`; otherwise,
   * the transfer is reverted.
   *
   * Requires the msg sender to be the owner, approved, or operator
   * @param from current owner of the item
   * @param to address to receive the ownership of the given item ID
   * @param itemId uint256 ID of the item to be transferred

  */
    function safeTransferUser(address from, address to, uint256 itemId) public {
        // solium-disable-next-line arg-overflow
        safeTransferUser(from, to, itemId, "");
    }

    /**
   * @dev Safely transfers the user of a given item ID to another address
   * If the target address is a contract, it must implement `onERCXReceived`,
   * which is called upon a safe transfer, and return the magic value
   * `bytes4(keccak256("onERCXReceived(address,address,uint256,bytes)"))`; otherwise,
   * the transfer is reverted.
   * Requires the msg sender to be the owner, approved, or operator
   * @param from current owner of the item
   * @param to address to receive the ownership of the given item ID
   * @param itemId uint256 ID of the item to be transferred
   * @param data bytes data to send along with a safe transfer check
   */
    function safeTransferUser(
        address from,
        address to,
        uint256 itemId,
        bytes memory data
    ) public {
        require(_isEligibleForTransfer(msg.sender, itemId, 1));
        _safeTransfer(from, to, itemId, 1, data);
    }

    /**
   * @dev Safely transfers the ownership of a given item ID to another address
   * If the target address is a contract, it must implement `onERCXReceived`,
   * which is called upon a safe transfer, and return the magic value
   * `bytes4(keccak256("onERCXReceived(address,address,uint256,bytes)"))`; otherwise,
   * the transfer is reverted.
   *
   * Requires the msg sender to be the owner, approved, or operator
   * @param from current owner of the item
   * @param to address to receive the ownership of the given item ID
   * @param itemId uint256 ID of the item to be transferred
  */
    function safeTransferOwner(address from, address to, uint256 itemId)
        public
    {
        // solium-disable-next-line arg-overflow
        safeTransferOwner(from, to, itemId, "");
    }

    /**
   * @dev Safely transfers the ownership of a given item ID to another address
   * If the target address is a contract, it must implement `onERCXReceived`,
   * which is called upon a safe transfer, and return the magic value
   * `bytes4(keccak256("onERCXReceived(address,address,uint256,bytes)"))`; otherwise,
   * the transfer is reverted.
   * Requires the msg sender to be the owner, approved, or operator
   * @param from current owner of the item
   * @param to address to receive the ownership of the given item ID
   * @param itemId uint256 ID of the item to be transferred
   * @param data bytes data to send along with a safe transfer check
   */
    function safeTransferOwner(
        address from,
        address to,
        uint256 itemId,
        bytes memory data
    ) public {
        require(_isEligibleForTransfer(msg.sender, itemId, 2));
        _safeTransfer(from, to, itemId, 2, data);
    }

    /**
    * @dev Safely transfers the ownership of a given item ID to another address
    * If the target address is a contract, it must implement `onERCXReceived`,
    * which is called upon a safe transfer, and return the magic value
    * `bytes4(keccak256("onERCXReceived(address,address,uint256,bytes)"))`; otherwise,
    * the transfer is reverted.
    * Requires the msg.sender to be the owner, approved, or operator
    * @param from current owner of the item
    * @param to address to receive the ownership of the given item ID
    * @param itemId uint256 ID of the item to be transferred
    * @param layer uint256 number to specify the layer
    * @param data bytes data to send along with a safe transfer check
    */
    function _safeTransfer(
        address from,
        address to,
        uint256 itemId,
        uint256 layer,
        bytes memory data
    ) internal {
        _transfer(from, to, itemId, layer);
        require(
            _checkOnERCXReceived(from, to, itemId, layer, data),
            "ERCX: transfer to non ERCXReceiver implementer"
        );
    }

    /**
    * @dev Returns whether the given spender can transfer a given item ID.
    * @param spender address of the spender to query
    * @param itemId uint256 ID of the item to be transferred
    * @param layer uint256 number to specify the layer
    * @return bool whether the msg.sender is approved for the given item ID,
    * is an operator of the owner, or is the owner of the item
    */
    function _isEligibleForTransfer(
        address spender,
        uint256 itemId,
        uint256 layer
    ) internal view returns (bool) {
        require(_exists(itemId, layer));
        if (layer == 1) {
            address user = userOf(itemId);
            address owner = ownerOf(itemId);
            require(
                spender == user ||
                    spender == owner ||
                    isApprovedForAll(user, spender) ||
                    isApprovedForAll(owner, spender) ||
                    spender == getApprovedForUser(itemId) ||
                    spender == getCurrentLien(itemId)
            );
            if (spender == owner || isApprovedForAll(owner, spender)) {
                require(getCurrentTenantRight(itemId) == address(0));
            }
            return true;
        }

        if (layer == 2) {
            address owner = ownerOf(itemId);
            require(
                spender == owner ||
                    isApprovedForAll(owner, spender) ||
                    spender == getApprovedForOwner(itemId) ||
                    spender == getCurrentLien(itemId)
            );
            return true;
        }
    }

    /**
   * @dev Returns whether the specified item exists
   * @param itemId uint256 ID of the item to query the existence of
   * @param layer uint256 number to specify the layer
   * @return whether the item exists
   */
    function _exists(uint256 itemId, uint256 layer)
        internal
        view
        returns (bool)
    {
        address owner = _itemOwner[itemId][layer];
        return owner != address(0);
    }

    /**
    * @dev Internal function to safely mint a new item.
    * Reverts if the given item ID already exists.
    * If the target address is a contract, it must implement `onERCXReceived`,
    * which is called upon a safe transfer, and return the magic value
    * `bytes4(keccak256("onERCXReceived(address,address,uint256,bytes)"))`; otherwise,
    * the transfer is reverted.
    * @param to The address that will own the minted item
    * @param itemId uint256 ID of the item to be minted
    */
    function _safeMint(address to, uint256 itemId) internal {
        _safeMint(to, itemId, "");
    }

    /**
    * @dev Internal function to safely mint a new item.
    * Reverts if the given item ID already exists.
    * If the target address is a contract, it must implement `onERCXReceived`,
    * which is called upon a safe transfer, and return the magic value
    * `bytes4(keccak256("onERCXReceived(address,address,uint256,bytes)"))`; otherwise,
    * the transfer is reverted.
    * @param to The address that will own the minted item
    * @param itemId uint256 ID of the item to be minted
    * @param data bytes data to send along with a safe transfer check
    */
    function _safeMint(address to, uint256 itemId, bytes memory data) internal {
        _mint(to, itemId);
        require(_checkOnERCXReceived(address(0), to, itemId, 1, data));
        require(_checkOnERCXReceived(address(0), to, itemId, 2, data));
    }

    /**
    * @dev Internal function to mint a new item.
    * Reverts if the given item ID already exists.
    * A new item iss minted with all three layers.
    * @param to The address that will own the minted item
    * @param itemId uint256 ID of the item to be minted
    */
    function _mint(address to, uint256 itemId) internal {
        require(to != address(0), "ERCX: mint to the zero address");
        require(!_exists(itemId, 1), "ERCX: item already minted");

        _itemOwner[itemId][1] = to;
        _itemOwner[itemId][2] = to;
        _ownedItemsCount[to][1].increment();
        _ownedItemsCount[to][2].increment();

        emit TransferUser(address(0), to, itemId, msg.sender);
        emit TransferOwner(address(0), to, itemId, msg.sender);

    }

    /**
    * @dev Internal function to burn a specific item.
    * Reverts if the item does not exist.
    * @param itemId uint256 ID of the item being burned
    */
    function _burn(uint256 itemId) internal {
        address user = userOf(itemId);
        address owner = ownerOf(itemId);
        require(user == msg.sender && owner == msg.sender);

        _clearTransferApproval(itemId, 1);
        _clearTransferApproval(itemId, 2);

        _ownedItemsCount[user][1].decrement();
        _ownedItemsCount[owner][2].decrement();
        _itemOwner[itemId][1] = address(0);
        _itemOwner[itemId][2] = address(0);

        emit TransferUser(user, address(0), itemId, msg.sender);
        emit TransferOwner(owner, address(0), itemId, msg.sender);
    }

    /**
    * @dev Internal function to transfer ownership of a given item ID to another address.
    * As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
    * @param from current owner of the item
    * @param to address to receive the ownership of the given item ID
    * @param itemId uint256 ID of the item to be transferred
    * @param layer uint256 number to specify the layer
    */
    function _transfer(address from, address to, uint256 itemId, uint256 layer)
        internal
    {
        if (layer == 1) {
            require(userOf(itemId) == from);
        } else {
            require(ownerOf(itemId) == from);
        }
        require(to != address(0));

        _clearTransferApproval(itemId, layer);

        if (layer == 2) {
            _clearLienApproval(itemId);
            _clearTenantRightApproval(itemId);
        }

        _ownedItemsCount[from][layer].decrement();
        _ownedItemsCount[to][layer].increment();

        _itemOwner[itemId][layer] = to;

        if (layer == 1) {
            emit TransferUser(from, to, itemId, msg.sender);
        } else {
            emit TransferOwner(from, to, itemId, msg.sender);
        }

    }

    /**
    * @dev Internal function to invoke {IERCXReceiver-onERCXReceived} on a target address.
    * The call is not executed if the target address is not a contract.
    *
    * This is an internal detail of the `ERCX` contract and its use is deprecated.
    * @param from address representing the previous owner of the given item ID
    * @param to target address that will receive the items
    * @param itemId uint256 ID of the item to be transferred
    * @param layer uint256 number to specify the layer
    * @param data bytes optional data to send along with the call
    * @return bool whether the call correctly returned the expected magic value
    */
    function _checkOnERCXReceived(
        address from,
        address to,
        uint256 itemId,
        uint256 layer,
        bytes memory data
    ) internal returns (bool) {
        if (!to.isContract()) {
            return true;
        }

        bytes4 retval = IERCXReceiver(to).onERCXReceived(
            msg.sender,
            from,
            itemId,
            layer,
            data
        );
        return (retval == _ERCX_RECEIVED);
    }

    /**
    * @dev Private function to clear current approval of a given item ID.
    * @param itemId uint256 ID of the item to be transferred
    * @param layer uint256 number to specify the layer
    */
    function _clearTransferApproval(uint256 itemId, uint256 layer) private {
        if (_transferApprovals[itemId][layer] != address(0)) {
            _transferApprovals[itemId][layer] = address(0);
        }
    }

    function _clearTenantRightApproval(uint256 itemId) private {
        if (_tenantRightApprovals[itemId] != address(0)) {
            _tenantRightApprovals[itemId] = address(0);
        }
    }

    function _clearLienApproval(uint256 itemId) private {
        if (_lienApprovals[itemId] != address(0)) {
            _lienApprovals[itemId] = address(0);
        }
    }

}