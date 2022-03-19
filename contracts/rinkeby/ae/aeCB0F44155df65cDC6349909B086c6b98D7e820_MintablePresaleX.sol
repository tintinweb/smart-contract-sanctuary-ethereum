//
// Made by: Omicron Blockchain Solutions
//          https://omicronblockchain.com
//



// SPDX-License-Identifier: MIT
pragma solidity =0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "../interfaces/IMintableERC721X.sol";

/**
 * @title Mintable Presale
 *
 * @notice Mintable Presale sales fixed amount of NFTs (tokens) for a fixed price in a fixed period of time;
 *      it can be used in a 10k sale campaign and the smart contract is generic and
 *      can sell any type of mintable NFT (see MintableERC721 interface)
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
 *         - MintableER721X deployed instance address
 *      2. Execute `initialize` function and set up the sale parameters;
 *         sale is not active until it's initialized
 *
 */
contract MintablePresaleX is Ownable {
  // Use Zeppelin MerkleProof Library to verify Merkle proofs
	using MerkleProof for bytes32[];

  // ----- SLOT.1 (192/256)
  /**
   * @dev Next token ID to mint;
   *      initially this is the first "free" ID which can be minted;
   *      at any point in time this should point to a free, mintable ID
   *      for the token
   *
   * @dev `nextId` cannot be zero, we do not ever mint NFTs with zero IDs
   *      This value must be the same as the one in ERC721X contract. !!!
   */
  uint32 public nextId = 1;

  /**
   * @dev Last token ID to mint;
   *      once `nextId` exceeds `finalId` the sale pauses
   */
  uint32 public finalId;

  /**
   * @notice Once set, limits the amount of tokens one address can buy for the duration of the sale;
   *       When unset (zero) the amount of tokens is limited only by the amount of tokens left for sale
   */
  uint32 public mintLimit;

  /**
   * @notice Counter of the tokens sold (minted) by this sale smart contract
   */
  uint32 public soldCounter;

  /**
   * @notice Merkle tree root to validate (address, cost, startDate, endDate)
   *         tuples
   */
  bytes32 public root;

  /**
	 * @dev Smart contract unique identifier, a random number
	 *
	 * @dev Should be regenerated each time smart contact source code is changed
	 *      and changes smart contract itself is to be redeployed
	 *
	 * @dev Generated using https://www.random.org/bytes/
	 */
	uint256 public constant UID = 0x3f38351a8d513731422d6b64f354f3cf6ea9ae952d15c73513da3b92754e778f;

  // ----- NON-SLOTTED
  /**
   * @dev Mintable ERC721 contract address to mint
   */
  address public immutable tokenContract;

  // ----- NON-SLOTTED
  /**
   * @dev Address of developer to receive withdraw fees
   */
  address public immutable developerAddress;

  // ----- NON-SLOTTED
  /**
   * @dev Number of mints performed by address
   */
  mapping(address => uint32) public mints;

  /**
   * @dev Fired in initialize()
   *
   * @param _by an address which executed the initialization
   * @param _nextId next ID of the token to mint
   * @param _finalId final ID of the token to mint
   * @param _mintLimit mint limit
   * @param _root merkle tree root
   */
  event Initialized(
    address indexed _by,
    uint32 _nextId,
    uint32 _finalId,
    uint32 _mintLimit,
    bytes32 _root
  );

  /**
   * @dev Fired in buy(), buyTo(), buySingle(), and buySingleTo()
   *
   * @param _by an address which executed and payed the transaction, probably a buyer
   * @param _to an address which received token(s) minted
   * @param _amount number of tokens minted
   * @param _value ETH amount charged
   */
  event Bought(address indexed _by, address indexed _to, uint256 _amount, uint256 _value);

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
  constructor(address _tokenContract, address _developerAddress) {
    // verify the input is set
    require(_tokenContract != address(0), "token contract is not set");
    require(_developerAddress != address(0), "developer is not set");

    // verify input is valid smart contract of the expected interfaces
    require(
      IERC165(_tokenContract).supportsInterface(type(IMintableERC721X).interfaceId)
      && IERC165(_tokenContract).supportsInterface(type(IMintableERC721X).interfaceId),
      "unexpected token contract type"
    );

    // assign the addresses
    tokenContract = _tokenContract;
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
  function itemsOnSale() public view returns(uint32) {
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
  function itemsAvailable() public view returns(uint32) {
    // delegate to itemsOnSale() if sale is active, return zero otherwise
    return isActive() ? itemsOnSale(): 0;
  }

  /**
   * @notice Active sale is an operational sale capable of minting and selling tokens
   *
   * @dev The sale is active when all the requirements below are met:
   *      1. `finalId` is not reached (`nextId <= finalId`)
   *
   * @dev Function is marked as virtual to be overridden in the helper test smart contract (mock)
   *      in order to test how it affects the sale process
   *
   * @return true if sale is active (operational) and can sell tokens, false otherwise
   */
  function isActive() public view virtual returns(bool) {
    // evaluate sale state based on the internal state variables and return
    return nextId <= finalId;
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
   *          0xFFFFFFFF,
   *          0xFFFFFFFF,
   *          10,
   *          0xFFFFFFFF
   *      )
   *
   * @dev Requires next ID to be greater than zero (strict): `_nextId > 0`
   *
   * @dev Requires transaction sender to have `ROLE_SALE_MANAGER` role
   *
   * @param _nextId next ID of the token to mint, will be increased
   *      in smart contract storage after every successful buy
   * @param _finalId final ID of the token to mint; sale is capable of producing
   *      `_finalId - _nextId + 1` tokens
   *      when current time is within _saleStart (inclusive) and _saleEnd (exclusive)
   * @param _mintLimit how many tokens is allowed to buy for the duration of the sale,
   *      set to zero to disable the limit
   * @param _root merkle tree root used to verify whether an address can mint
   */
  function initialize(
    uint32 _nextId,  // <<<--- keep type in sync with the body type(uint32).max !!!
    uint32 _finalId,  // <<<--- keep type in sync with the body type(uint32).max !!!
    uint32 _mintLimit,  // <<<--- keep type in sync with the body type(uint32).max !!!
    bytes32 _root  // <<<--- keep type in sync with the 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF !!!
  ) public onlyOwner {
    // verify the inputs
    require(_nextId > 0, "zero nextId");

    // no need to verify extra parameters - "incorrect" values will deactivate the sale

    // initialize contract state based on the values supplied
    // take into account our convention that value `-1` means "do not set"
    // 0xFFFFFFFFFFFFFFFF, 64 bits
    // 0xFFFFFFFF, 32 bits
    if(_nextId != type(uint32).max) {
      nextId = _nextId;
    }
    // 0xFFFFFFFF, 32 bits
    if(_finalId != type(uint32).max) {
      finalId = _finalId;
    }

    // 0xFFFFFFFF, 32 bits
    if(_mintLimit != type(uint32).max) {
      mintLimit = _mintLimit;
    }
    // 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF, 256 bits
    if(_root != 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF) {
      root = _root;
    }

    // emit an event - read values from the storage since not all of them might be set
    emit Initialized(
      msg.sender,
      nextId,
      finalId,
      mintLimit,
      root
    );
  }

  /**
   * @notice Buys two tokens in a batch.
   *      Accepts ETH as payment and mints a token
   */
  function buy(uint256 _price, uint256 _start, uint256 _end, bytes32[] memory _proof) public payable {
    // delegate to `buyTo` with the transaction sender set to be a recipient
    buyTo(msg.sender, _price, _start, _end, _proof);
  }

  /**
   * @notice Buys several (at least two) tokens in a batch to an address specified.
   *      Accepts ETH as payment and mints tokens
   *
   * @param _to address to mint tokens to
   */
  function buyTo(address _to, uint256 _price, uint256 _start, uint256 _end, bytes32[] memory _proof) public payable {
    // construct Merkle tree leaf from the inputs supplied
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _price, _start, _end));

    // verify proof
    require(_proof.verify(root, leaf), "invalid proof");

    // verify the inputs
    require(_to != address(0), "recipient not set");
    require(block.timestamp >= _start, "sale not yet started");
    require(block.timestamp <= _end, "sale ended");

    // verify mint limit
    if(mintLimit != 0) {
      require(mints[msg.sender] + 2 <= mintLimit, "mint limit reached");
    }

    // verify there is enough items available to buy the amount
    // verifies sale is in active state under the hood
    require(itemsAvailable() >= 2, "inactive sale or not enough items available");

    // calculate the total price required and validate the transaction value
    uint256 totalPrice = _price * 2;
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
  function buySingle(uint256 _price, uint256 _start, uint256 _end, bytes32[] memory _proof) public payable {
    // delegate to `buySingleTo` with the transaction sender set to be a recipient
    buySingleTo(msg.sender, _price, _start, _end, _proof);
  }

  /**
   * @notice Buys single token to an address specified.
   *      Accepts ETH as payment and mints a token
   *
   * @param _to address to mint token to
   */
  function buySingleTo(address _to, uint256 _price, uint256 _start, uint256 _end, bytes32[] memory _proof) public payable {
    // construct Merkle tree leaf from the inputs supplied
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _price, _start, _end));

    // verify proof
    require(_proof.verify(root, leaf), "invalid proof");

    // verify the inputs and transaction value
    require(_to != address(0), "recipient not set");
    require(msg.value >= _price, "not enough funds");
    require(block.timestamp >= _start, "sale not yet started");
    require(block.timestamp <= _end, "sale ended");

    // verify mint limit
    if(mintLimit != 0) {
      require(mints[msg.sender] + 1 <= mintLimit, "mint limit reached");
    }

    // verify sale is in active state
    require(isActive(), "inactive sale");

    // validate the funds sent for the tx to success
    require(msg.value >= _price, "not enough funds");

    // mint token to the recipient
    IMintableERC721X(tokenContract).mint(_to, false);

    // increment `nextId`
    nextId++;
    // increment `soldCounter`
    soldCounter++;
    // increment sender mints
    mints[msg.sender]++;

    // if ETH amount supplied exceeds the price
    if(msg.value > _price) {
      // send excess amount back to sender
      payable(msg.sender).transfer(msg.value - _price);
    }

    // emit en event
    emit Bought(msg.sender, _to, 1, _price);
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

    // Save the initial contract ETH value for event
    uint256 initialValue = address(this).balance;

    // verify sale balance is positive (non-zero)
    require(initialValue > 0, "zero balance");

    // ETH value of contract
    uint256 value = initialValue;

    // calculate developer fee (2%)
    uint256 developerFee = value / 50;

    // subtract the developer fee from the sale balance
    value -= developerFee;

    // send the sale balance minus the developer fee
    // to the withdrawer
    payable(_to).transfer(value);

    // send the developer fee to the developer
    payable(developerAddress).transfer(developerFee);

    // emit en event
    emit Withdrawn(msg.sender, _to, initialValue);
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
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }
        return computedHash;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

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
  function mint(address _to, bool _ammount) external;
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