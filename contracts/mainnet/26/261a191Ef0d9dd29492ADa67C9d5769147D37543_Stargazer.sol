// SPDX-License-Identifier: MIT

/**
 * No Branding Clause:
 * The Artwork shall never be used, or authorized for use, as a logo or brand.
 * The Artwork shall never be displayed on “branded” material, in any medium now know or hereafter devised,
 * including without limitation any merchandise, products, or printed or electronic material, that features
 * a trademark, service mark, trade name, tagline, logo, or other indicia identifying a person or entity except
 * for Kristen Visbal or State Street Global Advisors or its affiliates.
 * Purchase for a financial institution:  Your Fearless Girl NFT Image or sculpture may not be used on behalf of
 * any financial institution for commercial or corporate purpose.  A maximum of 20 of the miniatures may be purchased
 * to be used as award for a financial.
 * Purchase for political parties, politicians, activists, or activist groups:  Your Fearless Girl NFT or sculpture may
 * not be used to promote a politician, political party, activist group or used for political purpose.
 */
pragma solidity ^0.8.11;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';

import './common/libraries/AssemblyMath.sol';
import './common/token/ERC721/ERC721Enumerable.sol';

/// @title Stargazer
contract Stargazer is ERC721Enumerable, Ownable {
  using Strings for uint256;

  // URIs
  string public baseURI =
    'ipfs://QmZWKbE2oxvLV8eS2skCdMRKxXh2y9JoFthW2ZArdpixrt/';

  // Mint costs
  uint256 public publicCost = 0.2 ether;
  uint256 public allowlistCost = 0.16 ether;

  // Sale State
  bool public mintIsActive = true;

  // Allowlist Root
  bytes32 public allowlistMerkleRoot =
    0x6ef44377e05a71a0e02a1b72ae3b41b668ed2498e059ceb91d2505465c1192a6;

  // Treasury wallet
  address public treasury = 0x889F91b971fc6eFB0d0f1a0a3F8C77e718bbdCcd;

  // Supply limits
  uint256 public constant SUPPLY_STRICT_UPPER_BOUND = 5251;
  uint256 public STOCK_STRICT_UPPER_BOUND = 701;

  /**********************************************************************************************/
  /***************************************** EVENTS *********************************************/
  /**********************************************************************************************/
  /**
   * @param allowlist Whether or not cost was associated to the allowlist.
   * @param cost The mew cost of the mint.
   */
  event CostUpdated(bool allowlist, uint256 cost);

  /**
   * @param beneficiary The beneficiary of the tokens.
   * @param tokenId The token identifier.
   */
  event Minted(address indexed beneficiary, uint256 indexed tokenId);

  // Constructor
  constructor() ERC721('Fearless Girl: Stargazer Collection', 'STRGZR') {}

  /*************************************************************************/
  /****************************** MODIFIERS ********************************/
  /*************************************************************************/
  /**
   * @param msgValue Total amount of ether provided by caller.
   * @param numberOfTokens Number of tokens to be minted.
   * @param unitCost Cost per single token.
   * @dev Reverts if incorrect amount provided.
   */
  modifier correctCost(
    uint256 msgValue,
    uint256 numberOfTokens,
    uint256 unitCost
  ) {
    require(
      numberOfTokens * unitCost == msgValue,
      'Stargazer: Incorrect ether amount provided.'
    );
    _;
  }

  /**
   * @param tokenId Token identifier.
   * @dev Reverts if invalid token ID.
   */
  modifier meetsExistence(uint256 tokenId) {
    require(_exists(tokenId), 'Stargazer: Nonexistent token.');
    _;
  }

  /**
   * @dev Reverts if mint is not active.
   */
  modifier mintActive() {
    require(mintIsActive, 'Stargazer: Mint is not active.');
    _;
  }

  /**
   *  @param couponCode Coupon code.
   *  @param proof Merkle proof.
   *  @dev Reverts if coupon code is invalid.
   */
  modifier validCouponCode(string memory couponCode, bytes32[] calldata proof) {
    require(
      MerkleProof.verify(
        proof,
        allowlistMerkleRoot,
        keccak256(abi.encodePacked(couponCode))
      ),
      'Stargazer: Invalid coupon code.'
    );
    _;
  }

  modifier validStockAmount(uint256 amount) {
    require(
      amount + totalSupply() <= SUPPLY_STRICT_UPPER_BOUND,
      'Stargazer: Stock would exceed supply bound.'
    );
    _;
  }

  /**
   * @param count Number of tokens to be minted.
   * @dev Reverts if insufficient supply.
   */
  modifier meetsSupplyConditions(uint256 count) {
    // Ensure meets total supply restrictions.
    require(
      count + totalSupply() < SUPPLY_STRICT_UPPER_BOUND,
      'Stargazer: Supply limit reached.'
    );

    // Ensure meets card type supply restrictions.
    require(
      count < STOCK_STRICT_UPPER_BOUND,
      'Stargazer: Stock limit reached.'
    );
    _;
  }

  /*************************************************************************/
  /****************************** QUERIES **********************************/
  /*************************************************************************/
  /**
   * @param tokenId Token identifier.
   * @return tokenURI uri of the given token ID
   */
  function tokenURI(uint256 tokenId)
    external
    view
    override
    meetsExistence(tokenId)
    returns (string memory)
  {
    return string(abi.encodePacked(baseURI, Strings.toString(tokenId)));
  }

  /**
   * @param tokenOwner Wallet address
   * @return tokenIds list of tokens owned by the given address.
   */
  function walletOfOwner(address tokenOwner)
    external
    view
    returns (uint256[] memory)
  {
    uint256 tokenCount = balanceOf(tokenOwner);
    if (tokenCount == 0) return new uint256[](0);

    uint256[] memory tokenIds = new uint256[](tokenCount);
    for (uint256 i; i < tokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(tokenOwner, i);
    }
    return tokenIds;
  }

  /**
   * @param account Address checking ownership for.
   * @param tokenIds IDs of tokens we are checking ownership over.
   * @return isOwnerOf regarding whether or not address owns all listed tokens.
   */
  function isOwnerOf(address account, uint256[] calldata tokenIds)
    external
    view
    returns (bool)
  {
    for (uint256 i; i < tokenIds.length; ++i) {
      if (tokenOwners[tokenIds[i]] != account) return false;
    }

    return true;
  }

  /*************************************************************************/
  /*************************** STATE CHANGERS ******************************/
  /*************************************************************************/
  /**
   * @notice Activates/deactivates the public mint.
   * @dev Can only be called by contract owner.
   */
  function flipMintState() external onlyOwner {
    mintIsActive = !mintIsActive;
  }

  /**
   * @param cost New collection cost for allowlist
   * @notice Amount to mint one token
   * @dev Only contract owner can call this function.
   */
  function setAllowlistCost(uint256 cost) external onlyOwner {
    allowlistCost = cost;
    emit CostUpdated(true, cost);
  }

  /**
   * @param newAllowlistMerkleRoot The new merkle root of the allowlist.
   * @notice Sets the new root of the merkle tree for the allowlist.
   * @dev Only contract owner can call this function.
   */
  function setAllowlistMerkleRoot(bytes32 newAllowlistMerkleRoot)
    external
    onlyOwner
  {
    allowlistMerkleRoot = newAllowlistMerkleRoot;
  }

  /**
   * @param newUri new base uri.
   * @notice Sets the value of the base URI.
   * @dev Only contract owner can call this function.
   */
  function setBaseURI(string memory newUri) external onlyOwner {
    baseURI = newUri;
  }

  /**
   * @param cost New collection cost for public mint
   * @notice Amount to mint one token
   * @dev Only contract owner can call this function.
   */
  function setPublicCost(uint256 cost) external onlyOwner {
    publicCost = cost;
    emit CostUpdated(false, cost);
  }

  /**
   * @param newStock New stock of the card.
   * @notice Sets the new stock of the card.
   * @dev Only contract owner can call this function.
   */
  function setStock(uint256 newStock)
    external
    onlyOwner
    validStockAmount(newStock)
  {
    STOCK_STRICT_UPPER_BOUND = newStock;
  }

  /**
   * @param newTreasury new treasury address.
   * @notice Sets the address of the treasury.
   * @dev Only contract owner can call this function.
   */
  function setTreasuryWallet(address newTreasury) external onlyOwner {
    require(newTreasury != address(0), 'Stargazer: Invalid treasury address.');
    treasury = newTreasury;
  }

  /*************************************************************************/
  /****************************** MINTING **********************************/
  /*************************************************************************/
  /**
   * @param to Address to mint to.
   * @param tokenId ID of token to be minted.
   * @dev Internal function for minting.
   */
  function _mint(address to, uint256 tokenId) internal virtual override {
    tokenOwners.push(to);

    emit Transfer(address(0), to, tokenId);
  }

  /**
   * @param count Number of tokens of the option to mint.
   * @param couponCode Coupon code.
   * @param proof Merkle proof of allowlisted status.
   * @notice Mint function for allowlist addresses for option one.
   */
  function allowlistMint(
    uint256 count,
    string memory couponCode,
    bytes32[] calldata proof
  )
    external
    payable
    mintActive
    validCouponCode(couponCode, proof)
    correctCost(msg.value, count, allowlistCost)
    meetsSupplyConditions(count)
  {
    internalMint(_msgSender(), count);

    // Update stock.
    STOCK_STRICT_UPPER_BOUND -= count;
  }

  /**
   * @param to Address to mint to.
   * @param count Number of tokens of the option to mint.
   */
  function internalMint(address to, uint256 count) internal {
    uint256 numTokens = totalSupply();

    for (uint256 i = 0; i < count; i++) {
      _mint(to, numTokens + i);

      emit Minted(to, numTokens + i);
    }

    delete numTokens;
  }

  /**
   * @param count Number of tokens to mint.
   * @notice Mints the given number of tokens.
   * @dev Sale must be active.
   * @dev Cannot mint more than total supply limit.
   * @dev Cannot mint more than current stock for given card type.
   * @dev Cannot mint more than hard supply cap for given card type.
   * @dev Correct cost amount must be supplied.
   */
  function publicMint(uint256 count)
    external
    payable
    mintActive
    correctCost(msg.value, count, publicCost)
    meetsSupplyConditions(count)
  {
    internalMint(_msgSender(), count);

    // Update stock.
    STOCK_STRICT_UPPER_BOUND -= count;
  }

  /*************************************************************************/
  /****************************** ADMIN **********************************/
  /*************************************************************************/
  /**
   * @notice Withdraw function for contract ethereum.
   * @dev Can only be called by contract owner.
   */
  function withdraw() external onlyOwner {
    payable(treasury).transfer(address(this).balance);
  }

  /**
   * @param amt Array of amounts to mint.
   * @param to Associated array of addresses to mint to.
   * @notice Admin minting function.
   * @dev Cannot mint more than total supply limit.
   * @dev Cannot mint more than current stock for given card type.
   * @dev Cannot mint more than hard supply cap for given card type.
   * @dev Correct cost amount must be supplied.
   * @dev Same lengths for amount and to arrays must be given.
   * @dev Can only be called by contract owner.
   */
  function reserve(uint256[] calldata amt, address[] calldata to)
    external
    onlyOwner
  {
    require(
      amt.length == to.length,
      'Stargazer: Amount array length does not match recipient array or option length.'
    );

    uint256 s = totalSupply();
    uint256 t = AssemblyMath.arraySumAssembly(amt);

    // Can't mint more than total supply limit.
    require(
      t + s < SUPPLY_STRICT_UPPER_BOUND,
      'Stargazer: Cannot mint more than supply limit.'
    );

    // Can't mint more than current stock limit.
    require(
      t < STOCK_STRICT_UPPER_BOUND,
      'Stargazer: Cannot mint more than current stock limit.'
    );

    for (uint256 i = 0; i < to.length; ++i) {
      internalMint(to[i], amt[i]);
    }
    delete s;

    // Update stock.
    STOCK_STRICT_UPPER_BOUND -= t;

    delete t;
  }

  /*************************************************************************/
  /************************ BATCH TRANSFERS ********************************/
  /*************************************************************************/
  /**
   * @param fromAddress Address transferring from.
   * @param toAddress Address transferring to.
   * @param tokenIds IDs of tokens to be transferred.
   * @param data_ Call data argument.
   * @notice Safe variant of batch token transfer function
   */
  function batchSafeTransferFrom(
    address fromAddress,
    address toAddress,
    uint256[] memory tokenIds,
    bytes memory data_
  ) external {
    for (uint256 i = 0; i < tokenIds.length; i++) {
      safeTransferFrom(fromAddress, toAddress, tokenIds[i], data_);
    }
  }

  /**
   * @param fromAddress Address transferring from.
   * @param toAddress Address transferring to.
   * @param tokenIds IDs of tokens to be transferred.
   * @notice Batch token transfer function
   */
  function batchTransferFrom(
    address fromAddress,
    address toAddress,
    uint256[] memory tokenIds
  ) external {
    for (uint256 i = 0; i < tokenIds.length; i++) {
      transferFrom(fromAddress, toAddress, tokenIds[i]);
    }
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/MerkleProof.sol)

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
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library AssemblyMath {
  function arraySumAssembly(uint256[] memory d)
    internal
    pure
    returns (uint256 sum)
  {
    assembly {
      let len := mload(d)
      let data := add(d, 0x20)
      for {
        let end := add(data, mul(len, 0x20))
      } lt(data, end) {
        data := add(data, 0x20)
      } {
        sum := add(sum, mload(data))
      }
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './ERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol';

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account but rips out the core of the gas-wasting processing that comes from OpenZeppelin.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(IERC165, ERC721)
    returns (bool)
  {
    return
      interfaceId == type(IERC721Enumerable).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  /**
   * @dev See {IERC721Enumerable-totalSupply}.
   */
  function totalSupply() public view virtual override returns (uint256) {
    return tokenOwners.length;
  }

  /**
   * @dev See {IERC721Enumerable-tokenByIndex}.
   */
  function tokenByIndex(uint256 index)
    public
    view
    virtual
    override
    returns (uint256)
  {
    require(
      index < tokenOwners.length,
      'ERC721Enumerable: global index out of bounds'
    );
    return index;
  }

  /**
   * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
   */
  function tokenOfOwnerByIndex(address owner, uint256 index)
    public
    view
    virtual
    override
    returns (uint256 tokenId)
  {
    require(
      index < balanceOf(owner),
      'ERC721Enumerable: owner index out of bounds'
    );

    uint256 count;
    for (uint256 i; i < tokenOwners.length; i++) {
      if (owner == tokenOwners[i]) {
        if (count == index) return i;
        else count++;
      }
    }

    revert('ERC721Enumerable: owner index out of bounds');
  }
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

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol';
import '@openzeppelin/contracts/utils/Context.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';
import '../../libraries/Address.sol';

abstract contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
  using Address for address;
  using Strings for uint256;

  string private _name;
  string private _symbol;

  // Mapping from token ID to owner address
  address[] internal tokenOwners;

  mapping(uint256 => address) private _tokenApprovals;
  mapping(address => mapping(address => bool)) private _operatorApprovals;

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
    require(owner != address(0), 'ERC721: balance query for the zero address');

    uint256 count;
    for (uint256 i; i < tokenOwners.length; ++i) {
      if (owner == tokenOwners[i]) ++count;
    }
    return count;
  }

  /**
   * @dev See {IERC721-ownerOf}.
   */
  function ownerOf(uint256 tokenId)
    public
    view
    virtual
    override
    returns (address)
  {
    address owner = tokenOwners[tokenId];
    require(owner != address(0), 'ERC721: owner query for nonexistent token');
    return owner;
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
   * @dev See {IERC721-approve}.
   */
  function approve(address to, uint256 tokenId) public virtual override {
    address owner = ERC721.ownerOf(tokenId);
    require(to != owner, 'ERC721: approval to current owner');

    require(
      _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
      'ERC721: approve caller is not owner nor approved for all'
    );

    _approve(to, tokenId);
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
    require(_exists(tokenId), 'ERC721: approved query for nonexistent token');

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
    require(operator != _msgSender(), 'ERC721: approve to caller');

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
    //solhint-disable-next-line max-line-length
    require(
      _isApprovedOrOwner(_msgSender(), tokenId),
      'ERC721: transfer caller is not owner nor approved'
    );

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
    safeTransferFrom(from, to, tokenId, '');
  }

  /**
   * @dev See {IERC721-safeTransferFrom}.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory d
  ) public virtual override {
    require(
      _isApprovedOrOwner(_msgSender(), tokenId),
      'ERC721: transfer caller is not owner nor approved'
    );
    _safeTransfer(from, to, tokenId, d);
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
    require(
      _checkOnERC721Received(from, to, tokenId, _data),
      'ERC721: transfer to non ERC721Receiver implementer'
    );
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
    return tokenId < tokenOwners.length && tokenOwners[tokenId] != address(0);
  }

  /**
   * @dev Returns whether `spender` is allowed to manage `tokenId`.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   */
  function _isApprovedOrOwner(address spender, uint256 tokenId)
    internal
    view
    virtual
    returns (bool)
  {
    require(_exists(tokenId), 'ERC721: operator query for nonexistent token');
    address owner = ERC721.ownerOf(tokenId);
    return (spender == owner ||
      getApproved(tokenId) == spender ||
      isApprovedForAll(owner, spender));
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
    _safeMint(to, tokenId, '');
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
    require(
      _checkOnERC721Received(address(0), to, tokenId, _data),
      'ERC721: transfer to non ERC721Receiver implementer'
    );
  }

  /**
   * @dev Mints `tokenId` and transfers it to `to`.
   *
   * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
   *
   * Requirements:
   *
   * - `tokenId` must not exist.
   * - `to` cannot be the zero address.
   *
   * Emits a {Transfer} event.
   */
  function _mint(address to, uint256 tokenId) internal virtual {
    require(to != address(0), 'ERC721: mint to the zero address');
    require(!_exists(tokenId), 'ERC721: token already minted');

    _beforeTokenTransfer(address(0), to, tokenId);
    tokenOwners.push(to);

    emit Transfer(address(0), to, tokenId);
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
    address owner = ERC721.ownerOf(tokenId);

    _beforeTokenTransfer(owner, address(0), tokenId);

    // Clear approvals
    _approve(address(0), tokenId);
    tokenOwners[tokenId] = address(0);

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
    require(
      ERC721.ownerOf(tokenId) == from,
      'ERC721: transfer of token that is not own'
    );
    require(to != address(0), 'ERC721: transfer to the zero address');

    _beforeTokenTransfer(from, to, tokenId);

    // Clear approvals from the previous owner
    _approve(address(0), tokenId);
    tokenOwners[tokenId] = to;

    emit Transfer(from, to, tokenId);
  }

  /**
   * @dev Approve `to` to operate on `tokenId`
   *
   * Emits a {Approval} event.
   */
  function _approve(address to, uint256 tokenId) internal virtual {
    _tokenApprovals[tokenId] = to;
    emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
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
        return retval == IERC721Receiver.onERC721Received.selector;
      } catch (bytes memory reason) {
        if (reason.length == 0) {
          revert('ERC721: transfer to non ERC721Receiver implementer');
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

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
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library Address {
  function isContract(address account) internal view returns (bool) {
    uint256 size;
    assembly {
      size := extcodesize(account)
    }
    return size > 0;
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