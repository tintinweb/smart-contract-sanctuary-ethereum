//
// Made by: Omicron Blockchain Solutions
//          https://omicronblockchain.com
//



// SPDX-License-Identifier: MIT
pragma solidity =0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "../interfaces/IMintableERC721X.sol";

/**
 * @title Mintable Sale X
 *
 * @notice Mintable Sale X sales fixed amount of NFTs (tokens) for a fixed price in a fixed period of time;
 *      it can be used in a 10k sale campaign and the smart contract is generic and
 *      can sell any type of mintable NFT (see IMintableERC721X interface)
 *
 * @dev Technically, all the "fixed" parameters can be changed on the go after smart contract is deployed
 *      and operational, but this ability is reserved for quick fix-like adjustments, and to provide
 *      an ability to restart and run a similar sale after the previous one ends
 *
 * @dev When buying a token from this smart contract, next token is minted to the recipient
 *
 * @dev Supports functionality to limit amount of tokens that can be minted to each address
 *
 * @dev Deployment and setup:
 *      1. Deploy smart contract, specify smart contract address during the deployment:
 *         - Mintable ER721 X deployed instance address
 *      2. Execute `initialize` function and set up the sale parameters;
 *         sale is not active until it's initialized
 *
 */
contract MintableSaleX is Ownable {
  /**
   * @dev Next token ID to mint;
   *      initially this is the first "free" ID which can be minted;
   *      at any point in time this should point to a free, mintable ID
   *      for the token
   *
   * @dev `nextId` cannot be zero, we do not ever mint NFTs with zero IDs
   */
  uint256 public nextId = 1;

  /**
   * @dev Last token ID to mint;
   *      once `nextId` exceeds `finalId` the sale pauses
   */
  uint256 public finalId;

  // ----- SLOT.1 (224/256)
  /**
   * @notice Price of a single item (token) minted
   *      When buying several tokens at once the price accumulates accordingly, with no discount
   *
   * @dev Maximum item price is ~18.44 ETH
   */
  uint64 public itemPrice;

  /**
   * @notice Sale start unix timestamp; the sale is active after the start (inclusive)
   */
  uint32 public saleStart;

  /**
   * @notice Sale end unix timestamp; the sale is active before the end (exclusive)
   */
  uint32 public saleEnd;

  /**
   * @notice Once set, limits the amount of tokens one address can buy for the duration of the sale;
   *       When unset (zero) the amount of tokens is limited only by the amount of tokens left for sale
   */
  uint32 public mintLimit;

  /**
   * @notice Counter of the tokens sold (minted) by this sale smart contract
   */
  uint32 public soldCounter;

  // ----- NON-SLOTTED
  /**
   * @dev Mintable ERC721 contract address to mint
   */
  address public immutable tokenContract;

  // ----- NON-SLOTTED
  /**
   * @dev Developer fee
   */
  uint256 public immutable developerFee;

  // ----- NON-SLOTTED
  /**
   * @dev Address of developer to receive withdraw fees
   */
  address public immutable developerAddress;

  // ----- NON-SLOTTED
  /**
   * @dev Number of mints performed by address
   */
  mapping(address => uint32) mints;

  /**
	 * @dev Smart contract unique identifier, a random number
	 *
	 * @dev Should be regenerated each time smart contact source code is changed
	 *      and changes smart contract itself is to be redeployed
	 *
	 * @dev Generated using https://www.random.org/bytes/
	 */
	uint256 public constant UID = 0x3f38351a8d513631432d6b64f354f3cf3ea9ae952915c73513da3b92754e878f;

  /**
   * @dev Fired in initialize()
   *
   * @param _by an address which executed the initialization
   * @param _itemPrice price of one token created
   * @param _nextId next ID of the token to mint
   * @param _finalId final ID of the token to mint
   * @param _saleStart start of the sale, unix timestamp
   * @param _saleEnd end of the sale, unix timestamp
   * @param _limit mint limit
   */
  event Initialized(
    address indexed _by,
    uint64 _itemPrice,
    uint256 _nextId,
    uint256 _finalId,
    uint32 _saleStart,
    uint32 _saleEnd,
    uint32 _limit
  );

  /**
   * @dev Fired in buy(), buyTo(), buySingle(), and buySingleTo()
   *
   * @param _by an address which executed and payed the transaction, probably a buyer
   * @param _to an address which received token(s) minted
   * @param _amount number of tokens minted
   * @param _value ETH amount charged
   */
  event Bought(address indexed _by, address indexed _to, uint32 _amount, uint256 _value);

  /**
   * @dev Fired in withdraw() and withdrawTo()
   *
   * @param _by an address which executed the withdrawal
   * @param _to an address which received the ETH withdrawn
   * @param _value ETH amount withdrawn
   */
  event Withdrawn(address indexed _by, address indexed _to, uint256 _value);

  /**
   * @dev Creates/deploys MintableSale and binds it to Mintable ERC721
   *      smart contract on construction
   *
   * @param _tokenContract deployed Mintable ERC721 smart contract; sale will mint ERC721
   *      tokens of that type to the recipient
   */
  constructor(address _tokenContract, uint256 _developerFee, address _developerAddress) {
    // verify the input is set
    require(_tokenContract != address(0), "token contract is not set");

    // verify that developer address is correct
    require(_developerAddress != address(0), "developer address is not set");

    // verify input is valid smart contract of the expected interfaces
    require(
      IERC165(_tokenContract).supportsInterface(type(IMintableERC721X).interfaceId)
      && IERC165(_tokenContract).supportsInterface(type(IMintableERC721X).interfaceId),
      "unexpected token contract type"
    );

    // assign the addresses
    tokenContract = _tokenContract;
    
    // assign the developer fee
    developerFee = _developerFee;

    // assign the developer address
    developerAddress = _developerAddress;
  }

  /**
   * @notice Number of tokens left on sale
   *
   * @dev Doesn't take into account if sale is active or not,
   *      if `nextId - finalId < 1` returns zero
   *
   * @return number of tokens left on sale
   */
  function itemsOnSale() public view returns(uint256) {
    // calculate items left on sale, taking into account that
    // finalId is on sale (inclusive bound)
    return finalId >= nextId? finalId + 1 - nextId: 0;
  }

  /**
   * @notice Number of tokens available on sale
   *
   * @dev Takes into account if sale is active or not, doesn't throw,
   *      returns zero if sale is inactive
   *
   * @return number of tokens available on sale
   */
  function itemsAvailable() public view returns(uint256) {
    // delegate to itemsOnSale() if sale is active, return zero otherwise
    return isActive()? itemsOnSale(): 0;
  }

  /**
   * @notice Active sale is an operational sale capable of minting and selling tokens
   *
   * @dev The sale is active when all the requirements below are met:
   *      1. Price is set (`itemPrice` is not zero)
   *      2. `finalId` is not reached (`nextId <= finalId`)
   *      3. current timestamp is between `saleStart` (inclusive) and `saleEnd` (exclusive)
   *
   * @dev Function is marked as virtual to be overridden in the helper test smart contract (mock)
   *      in order to test how it affects the sale process
   *
   * @return true if sale is active (operational) and can sell tokens, false otherwise
   */
  function isActive() public view virtual returns(bool) {
    // evaluate sale state based on the internal state variables and return
    return itemPrice > 0 && nextId <= finalId && saleStart <= block.timestamp && saleEnd > block.timestamp;
  }

  /**
   * @dev Restricted access function to set up sale parameters, all at once,
   *      or any subset of them
   *
   * @dev To skip parameter initialization, set it to `-1`,
   *      that is a maximum value for unsigned integer of the corresponding type;
   *      `_aliSource` and `_aliValue` must both be either set or skipped
   *
   * @dev Example: following initialization will update only _itemPrice and _batchLimit,
   *      leaving the rest of the fields unchanged
   *      initialize(
   *          100000000000000000,
   *          0xFFFFFFFF,
   *          0xFFFFFFFF,
   *          0xFFFFFFFF,
   *          0xFFFFFFFF,
   *          10
   *      )
   *
   * @dev Requires next ID to be greater than zero (strict): `_nextId > 0`
   *
   * @dev Requires transaction sender to have `ROLE_SALE_MANAGER` role
   *
   * @param _itemPrice price of one token created;
   *      setting the price to zero deactivates the sale
   * @param _nextId next ID of the token to mint, will be increased
   *      in smart contract storage after every successful buy
   * @param _finalId final ID of the token to mint; sale is capable of producing
   *      `_finalId - _nextId + 1` tokens
   * @param _saleStart start of the sale, unix timestamp
   * @param _saleEnd end of the sale, unix timestamp; sale is active only
   *      when current time is within _saleStart (inclusive) and _saleEnd (exclusive)
   * @param _mintLimit how many tokens is allowed to buy for the duration of the sale,
   *      set to zero to disable the limit
   */
  function initialize(
    uint64 _itemPrice,  // <<<--- keep type in sync with the body type(uint64).max !!!
    uint256 _nextId,  // <<<--- keep type in sync with the body type(uint256).max !!!
    uint256 _finalId,  // <<<--- keep type in sync with the body type(uint256).max !!!
    uint32 _saleStart,  // <<<--- keep type in sync with the body type(uint32).max !!!
    uint32 _saleEnd,  // <<<--- keep type in sync with the body type(uint32).max !!!
    uint32 _mintLimit  // <<<--- keep type in sync with the body type(uint32).max !!!
  ) public onlyOwner {
    // verify the inputs
    require(_nextId > 0, "zero nextId");

    // no need to verify extra parameters - "incorrect" values will deactivate the sale

    // initialize contract state based on the values supplied
    // take into account our convention that value `-1` means "do not set"
    // 0xFFFFFFFFFFFFFFFF, 64 bits
    if(_itemPrice != type(uint64).max) {
      itemPrice = _itemPrice;
    }
    // 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF, 256 bits
    if(_nextId != type(uint256).max) {
      nextId = _nextId;
    }
    // 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF, 256 bits
    if(_finalId != type(uint256).max) {
      finalId = _finalId;
    }
    // 0xFFFFFFFF, 32 bits
    if(_saleStart != type(uint32).max) {
      saleStart = _saleStart;
    }
    // 0xFFFFFFFF, 32 bits
    if(_saleEnd != type(uint32).max) {
      saleEnd = _saleEnd;
    }
    // 0xFFFFFFFF, 32 bits
    if(_mintLimit != type(uint32).max) {
      mintLimit = _mintLimit;
    }

    // emit an event - read values from the storage since not all of them might be set
    emit Initialized(
      msg.sender,
      itemPrice,
      nextId,
      finalId,
      saleStart,
      saleEnd,
      mintLimit
    );
  }

  /**
   * @notice Buys two tokens in a batch.
   *      Accepts ETH as payment and mints a token
   */
  function buy() public payable {
    // delegate to `buyTo` with the transaction sender set to be a recipient
    buyTo(msg.sender);
  }

  /**
   * @notice Buys two tokens in a batch to an address specified.
   *      Accepts ETH as payment and mints tokens
   *
   * @param _to address to mint tokens to
   */
  function buyTo(address _to) public payable {
    // verify the inputs
    require(_to != address(0), "recipient not set");

    // verify mint limit
    if(mintLimit != 0) {
      require(mints[msg.sender] + 2 <= mintLimit, "mint limit reached");
    }

    // verify there is enough items available to buy the amount
    // verifies sale is in active state under the hood
    require(itemsAvailable() >= 2, "inactive sale or not enough items available");

    // calculate the total price required and validate the transaction value
    uint256 totalPrice = uint256(itemPrice) * 2;
    require(msg.value >= totalPrice, "not enough funds");

    // mint token to to the recipient
    IMintableERC721X(tokenContract).mint(_to, true);

    // increment `nextId`
    nextId += 2;
    // increment `soldCounter`
    soldCounter += 2;
    // increment sender mints
    mints[msg.sender] += 2;

    // if ETH amount supplied exceeds the price
    if(msg.value > totalPrice) {
      // send excess amount back to sender
      payable(msg.sender).transfer(msg.value - totalPrice);
    }

    // emit en event
    emit Bought(msg.sender, _to, 2, totalPrice);
  }

  /**
   * @notice Buys single token.
   *      Accepts ETH as payment and mints a token
   */
  function buySingle() public payable {
    // delegate to `buySingleTo` with the transaction sender set to be a recipient
    buySingleTo(msg.sender);
  }

  /**
   * @notice Buys single token to an address specified.
   *      Accepts ETH as payment and mints a token
   *
   * @param _to address to mint token to
   */
  function buySingleTo(address _to) public payable {
    // verify the inputs and transaction value
    require(_to != address(0), "recipient not set");
    require(msg.value >= itemPrice, "not enough funds");

    // verify mint limit
    if(mintLimit != 0) {
      require(mints[msg.sender] + 1 <= mintLimit, "mint limit reached");
    }

    // verify sale is in active state
    require(isActive(), "inactive sale");

    // mint token to the recipient
    IMintableERC721X(tokenContract).mint(_to, false);

    // increment `nextId`
    nextId++;
    // increment `soldCounter`
    soldCounter++;
    // increment sender mints
    mints[msg.sender]++;

    // if ETH amount supplied exceeds the price
    if(msg.value > itemPrice) {
      // send excess amount back to sender
      payable(msg.sender).transfer(msg.value - itemPrice);
    }

    // emit en event
    emit Bought(msg.sender, _to, 1, itemPrice);
  }

  /**
   * @dev Restricted access function to withdraw ETH on the contract balance,
   *      sends ETH back to transaction sender
   */
  function withdraw() public {
    // delegate to `withdrawTo`
    withdrawTo(msg.sender);
  }

  /**
   * @dev Restricted access function to withdraw ETH on the contract balance,
   *      sends ETH to the address specified
   *
   * @param _to an address to send ETH to
   */
  function withdrawTo(address _to) public onlyOwner {
    // verify withdrawal address is set
    require(_to != address(0), "address not set");

    // ETH value to send
    uint256 _value = address(this).balance;
    
    uint256 computedDevFee = _value * developerFee / 100;
    
    _value -= computedDevFee;

    // verify sale balance is positive (non-zero)
    require(_value > 0, "zero balance");

    // send the entire balance to the transaction sender
    payable(_to).transfer(_value);
    payable(developerAddress).transfer(computedDevFee);

    // emit en event
    emit Withdrawn(msg.sender, _to, _value);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721.sol";

//
// Made by: Omicron Blockchain Solutions
//          https://omicronblockchain.com
//



// SPDX-License-Identifier: MIT
pragma solidity =0.8.12;

interface IMintableERC721X {
  /**
   * @dev Returns whether `tokenId` exists.
   *
   * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
   *
   * Tokens start existing when they are minted (`_mint`).
   */
  function exists(uint256 _tokenId) external view returns (bool);

  /**
   * @dev Safely mints the token with next consecutive ID and transfers it to `to`. Setting
   *      `amount` to `true` will mint another nft.
   *
   * Requirements:
   *
   * - `tokenId` must not exist.
   * - `maxTotalSupply` maximum total supply has not been reached
   * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
   *
   * Emits a {Transfer} event.
   */
  function safeMint(address _to, bool _amount) external;

  /**
   * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
   * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
   */
  function safeMint(
    address _to,
    bool _amount,
    bytes memory _data
  ) external;

  /**
   * @dev Mints the token with next consecutive ID and transfers it to `to`. Setting
   *      `amount` to `true` will mint another nft.
   *
   * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
   *
   * Requirements:
   *
   * - `to` cannot be the zero address.
   * - `maxTotalSupply` maximum total supply has not been reached
   *
   * Emits a {Transfer} event.
   */
  function mint(address _to, bool _amount) external;
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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