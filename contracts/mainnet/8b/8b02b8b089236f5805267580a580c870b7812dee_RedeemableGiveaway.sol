// SPDX-License-Identifier: MIT
pragma solidity =0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "../interfaces/IMintableERC721.sol";

/**
 * @title Reedemable ERC721 Giveaway
 *
 * @notice Reedemable ERC721 Giveaway is a smart contract that allow accounts that own a specific ERC721 token
 *         to get another ERC721 token for free, in a fixed period of time; the smart contract
 *         is generic and can support any type of mintable NFT (see MintableERC721 interface).
 *         For instance, suppose that users already own NFTs named A. Then, for each minted NFT A, the owner
 *         can also mint another NFT called B. The releationship is one-to-one and it can be only one NFT of type B
 *         minted for a distinct NFT of type A.
 *
 * @dev All the "fixed" parameters can be changed on the go after smart contract is deployed
 *      and operational, but this ability is reserved for quick fix-like adjustments, and to provide
 *      an ability to restart and run a giveaway after the previous one ends.
 *
 *      Note that both the `giveawayTokenContract` and `baseTokenContract` contracts must be mintble NFTS
 *      for this to work.
 *
 *      When redeem an NFT token by this contract, the token is minted by the recipient.
 *
 *      To successfully redeem a token, the caller must:
 *        1) Own NFTs minted using the `baseTokenContract`
 *        2) The NFTs minted using the `baseTokenContract` should already not been used to redeem NFTs
 *           of the `giveawayTokenContract`.
 *
 *      Deployment and setup:
 *      1. Deploy smart contract, specify the giveawat smart contract address during the deployment:
 *         - Mintable ER721 deployed instance address
 *      2. Execute `initialize` function and set up the giveaway parameters;
 *         giveaway is not active until it's initialized and a valid `baseTokenContract` address is provided.
 */
contract RedeemableGiveaway is Ownable {
  /**
   * @dev Next token ID to mint;
   *      initially this is the first available ID which can be minted;
   *      at any point in time this should point to a available, mintable ID
   *      for the token.
   *
   *      `nextId` cannot be zero, we do not ever mint NFTs with zero IDs.
   */
  uint256 public nextId = 1;

  /**
   * @dev Last token ID to mint;
   *      once `nextId` exceeds `finalId` the giveaway pauses.
   */
  uint256 public finalId;

  // ----- SLOT.1 (96/256)
  /**
   * @notice Giveaway start at unix timestamp; the giveaway is active after the start (inclusive)
   */
  uint32 public giveawayStart;

  /**
   * @notice Giveaway end unix timestamp; the giveaway is active before the end (exclusive)
   */
  uint32 public giveawayEnd;

  /**
   * @notice Counter of the tokens gifted (minted) by this sale smart contract.
   */
  uint32 public giveawayCounter;

  /**
   * @notice The contract address of the giveaway token.
   */
  address public immutable giveawayTokenContract;

  /**
   * @notice The contract address of the base token.
   */
  address public baseTokenContract;

  /**
   * @notice Track redeemed base tokens.
   * @dev This is usefull to prevent same tokens to be used again after redeem.
   */
  mapping(uint256 => bool) redeemedBaseTokens;

  /**
   * @dev Fired in initialize()
   *
   * @param _by an address which executed the initialization
   * @param _nextId next ID of the giveaway token to mint
   * @param _finalId final ID of the giveaway token to mint
   * @param _giveawayStart start of the giveaway, unix timestamp
   * @param _giveawayEnd end of the giveaway, unix timestamp
   * @param _baseTokenContract base token contract address used for redeeming
   */
  event Initialized(
    address indexed _by,
    uint256 _nextId,
    uint256 _finalId,
    uint32 _giveawayStart,
    uint32 _giveawayEnd,
    address _baseTokenContract
  );

  /**
   * @dev Fired in redeem(), redeemTo(), redeemSingle(), and redeemSingleTo()
   *
   * @param _by an address which executed the transaction, probably a base NFT owner
   * @param _to an address which received token(s) minted
   * @param _giveawayTokens array with IDS of the minted tokens
   */
  event Redeemed(address indexed _by, address indexed _to, uint256[] _giveawayTokens);

  /**
   * @dev Creates/deploys RedeemableERC721Giveaway and binds it to Mintable ERC721
   *      smart contract on construction
   *
   * @param _giveawayTokenContract deployed Mintable ERC721 smart contract; giveaway will mint ERC721
   *      tokens of that type to the recipient
   */
  constructor(address _giveawayTokenContract) {
    // Verify the input is set.
    require(_giveawayTokenContract != address(0), "giveaway token contract is not set");

    // Verify input is valid smart contract of the expected interfaces.
    require(
      IERC165(_giveawayTokenContract).supportsInterface(type(IMintableERC721).interfaceId) &&
        IERC165(_giveawayTokenContract).supportsInterface(type(IMintableERC721).interfaceId),
      "unexpected token contract type"
    );

    // Assign the addresses.
    giveawayTokenContract = _giveawayTokenContract;
  }

  /**
   * @notice Number of tokens left on giveaway.
   *
   * @dev Doesn't take into account if giveway is active or not,
   *      if `nextId - finalId < 1` returns zero.
   *
   * @return Number of tokens left on giveway.
   */
  function itemsOnGiveaway() public view returns (uint256) {
    // Calculate items left on givewaway, taking into account that
    // `finalId` is givewaway (inclusive bound).
    return finalId >= nextId ? finalId + 1 - nextId : 0;
  }

  /**
   * @notice Number of tokens available on giveaway.
   *
   * @dev Takes into account if giveaway is active or not, doesn't throw,
   *      returns zero if giveaway is inactive
   *
   * @return Number of tokens available on giveaway.
   */
  function itemsAvailable() public view returns (uint256) {
    // Delegate to itemsOnSale() if giveaway is active, returns zero otherwise.
    return isActive() ? itemsOnGiveaway() : 0;
  }

  /**
   * @notice Active giveaway is an operational giveaway capable of minting tokens.
   *
   * @dev The giveaway is active when all the requirements below are met:
   *      1. `baseTokenContract` is set
   *      2. `finalId` is not reached (`nextId <= finalId`)
   *      3. current timestamp is between `giveawayStart` (inclusive) and `giveawayEnd` (exclusive)
   *
   *      Function is marked as virtual to be overridden in the helper test smart contract (mock)
   *      in order to test how it affects the giveaway process
   *
   * @return true if giveaway is active (operational) and can mint tokens, false otherwise.
   */
  function isActive() public view virtual returns (bool) {
    // Evaluate giveaway state based on the internal state variables and return.
    return
      baseTokenContract != address(0) &&
      nextId <= finalId &&
      giveawayStart <= block.timestamp &&
      giveawayEnd > block.timestamp;
  }

  /**
   * @dev Restricted access function to set up giveaway parameters, all at once,
   *      or any subset of them.
   *
   *      To skip parameter initialization, set it to the biggest number for the corresponding type;
   *      for `_baseTokenContract`, use address(0) or '0x0000000000000000000000000000000000000000' from Javascript.
   *
   *      Example: The following initialization will update only _giveawayStart and _giveawayEnd,
   *      leaving the rest of the fields unchanged:
   *
   *      initialize(
   *          type(uint256).max,
   *          type(uint256).max,
   *          1637080155850,
   *          1639880155950,
   *          address(0)
   *      )
   *
   *      Requires next ID to be greater than zero (strict): `_nextId > 0`
   *
   *      Requires transaction sender to be the deployer of this contract.
   *
   * @param _nextId next ID of the token to mint, will be increased
   *      in smart contract storage after every successful giveaway
   * @param _finalId final ID of the token to mint; giveaway is capable of producing
   *      `_finalId - _nextId + 1` tokens
   * @param _giveawayStart start of the giveaway, unix timestamp
   * @param _giveawayEnd end of the giveaway, unix timestamp; sale is active only
   *      when current time is within _giveawayStart (inclusive) and _giveawayEnd (exclusive)
   * @param _baseTokenContract end of the sale, unix timestamp; sale is active only
   *      when current time is within _giveawayStart (inclusive) and _giveawayEnd (exclusive)
   */
  function initialize(
    uint256 _nextId, // <<<--- keep type in sync with the body type(uint256).max !!!
    uint256 _finalId, // <<<--- keep type in sync with the body type(uint256).max !!!
    uint32 _giveawayStart, // <<<--- keep type in sync with the body type(uint32).max !!!
    uint32 _giveawayEnd, // <<<--- keep type in sync with the body type(uint32).max !!!
    address _baseTokenContract // <<<--- keep type in sync with the body address(0) !!!
  ) public onlyOwner {
    // Verify the inputs.
    // No need to verify extra parameters - "incorrect" values will deactivate the sale.

    require(_nextId > 0, "zero nextId");

    // Initialize contract state based on the values supplied.
    // Take into account our convention that value `-1` means "do not set"

    if (_nextId != type(uint256).max) {
      nextId = _nextId;
    }

    if (_finalId != type(uint256).max) {
      finalId = _finalId;
    }

    if (_giveawayStart != type(uint32).max) {
      giveawayStart = _giveawayStart;
    }

    if (_giveawayEnd != type(uint32).max) {
      giveawayEnd = _giveawayEnd;
    }

    if (_baseTokenContract != address(0)) {
      // The base contract must implement the Mintable NFT interface.
      require(
        IERC165(_baseTokenContract).supportsInterface(type(IMintableERC721).interfaceId) &&
          IERC165(_baseTokenContract).supportsInterface(type(IMintableERC721).interfaceId),
        "unexpected token contract type"
      );

      baseTokenContract = _baseTokenContract;
    }

    // Emit initialize event - read values from the storage since not all of them might be set.
    emit Initialized(msg.sender, nextId, finalId, giveawayStart, giveawayEnd, baseTokenContract);
  }

  /**
   * @notice Given an array of base tokens, check if any of the tokens were previously redeemed.
   * @param _baseTokens Array with base tokens ID.
   * @return true if any base token was previously redeemed, false otherwise.
   */
  function areRedeemed(uint256[] calldata _baseTokens) external view returns (bool[] memory) {
    bool[] memory redeemed = new bool[](_baseTokens.length);
    
    for (uint256 i = 0; i < _baseTokens.length; i++) {
      redeemed[i] = redeemedBaseTokens[_baseTokens[i]];
    }

    return redeemed;
  }

  /**
   * @notice Redeem several tokens using the caller address. This function will fail if the provided `_baseTokens`
   *         are not owned by the caller or have previously redeemed.
   *
   * @param _baseTokens Array with base tokens ID.
   */
  function redeem(uint256[] memory _baseTokens) public {
    redeemTo(msg.sender, _baseTokens);
  }

  /**
   * @notice Redeem several tokens into the address specified by `_to`. This function will fail
   *         if the provided `_baseTokens` are not owned by the caller or have previously redeemed.
   *
   * @param _to Address where the minted tokens will be assigned.
   * @param _baseTokens Array with base tokens ID.
   */
  function redeemTo(address _to, uint256[] memory _baseTokens) public {
    // Verify the recipient's address.
    require(_to != address(0), "recipient not set");

    // Verify more than 1 tokens were provided, else the caller can use
    // the single variants of the redeem functions.
    require(_baseTokens.length > 1, "incorrect amount");

    // Verify that all the specified base tokens IDs are owned by the transaction caller
    // and does not have already been redeemed.
    for (uint256 i = 0; i < _baseTokens.length; i++) {
      require(IERC721(baseTokenContract).ownerOf(_baseTokens[i]) == msg.sender, "wrong owner");
      require(!redeemedBaseTokens[_baseTokens[i]], "token already redeemed");
    }


    // Verify there is enough items available to giveaway.
    // Verifies giveaway is in active state under the hood.
    require(itemsAvailable() >= _baseTokens.length, "inactive giveaway or not enough items available");

    // Store the minted giveaway tokens.
    uint256[] memory giveawayTokens = new uint256[](_baseTokens.length);

    // For each base token provided, mint a giveaway token.
    for (uint256 i = 0; i < _baseTokens.length; i++) {
      // Mint token to to the recipient.
      IMintableERC721(giveawayTokenContract).mint(_to, nextId);

      // Save the minted token ID.
      giveawayTokens[i] = nextId;

      // Set the next token ID to mint.
      nextId += 1;

      // Increase the giveaway counter.
      giveawayCounter += 1;

      // Record the base token, so that it cannot be used again for redeeming.
      redeemedBaseTokens[_baseTokens[i]] = true;
    }

    // All the tokens were redeemed, emit the corresponding event.
    emit Redeemed(msg.sender, _to, giveawayTokens);
  }

  /**
   * @notice Redeem a single token using the caller address. This function will fail if the provided `_baseToken`
   *         is not owned by the caller or have previously redeemed.
   *
   * @param _baseToken Base token ID to redeem.
   */
  function redeemSingle(uint256 _baseToken) public {
    redeemSingleTo(msg.sender, _baseToken);
  }

  /**
   * @notice Redeem a single token into the address specified by `_to`. This function will fail
   *         if the provided `_baseToken` is not owned by the caller or have previously redeemed.
   *
   * @param _to Address where the minted token will be assigned.
   * @param _baseToken Base token ID to redeem.
   */
  function redeemSingleTo(address _to, uint256 _baseToken) public {
    // Verify the recipient's address.
    require(_to != address(0), "recipient not set");

    // Verify that the specified base tokens ID is owned by the transaction caller
    // and does not have already been redeemed.
    require(IERC721(baseTokenContract).ownerOf(_baseToken) == msg.sender, "wrong owner");
    require(!redeemedBaseTokens[_baseToken], "token already redeemed");

    // Verify there is enough items available to giveaway.
    // Verifies giveaway is in active state under the hood.
    require(itemsAvailable() >= 1, "inactive giveaway or not enough items available");

    // Store the minted giveaway token.
    uint256[] memory giveawayTokens = new uint256[](1);

    // Mint token to to the recipient.
    IMintableERC721(giveawayTokenContract).mint(_to, nextId);

    // Save the minted token ID.
    giveawayTokens[0] = nextId;

    // Set the next token ID to mint.
    nextId += 1;

    // Increase the giveaway counter.
    giveawayCounter += 1;

    // Record the base token, so that it cannot be used again for redeeming.
    redeemedBaseTokens[_baseToken] = true;

    // All the tokens were redeemed, emit the corresponding event.
    emit Redeemed(msg.sender, _to, giveawayTokens);
  }
}

// SPDX-License-Identifier: MIT

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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721.sol";

// SPDX-License-Identifier: MIT
pragma solidity =0.8.14;

/**
 * @notice ERC721-compliant interface with added
 *         function for minting new NFTs to addresses
 *
 * See {IERC721}
 */
interface IMintableERC721 {
  /**
   * @notice Checks if specified token exists
   *
   * @dev Returns whether the specified token ID has an ownership
   *      information associated with it
   *
   * @param _tokenId ID of the token to query existence for
   * @return whether the token exists (true - exists, false - doesn't exist)
   */
  function exists(uint256 _tokenId) external view returns (bool);

  /**
   * @dev Creates new token with token ID specified
   *      and assigns an ownership `_to` for this token
   *
   * @dev Unsafe: doesn't execute `onERC721Received` on the receiver.
   *      Prefer the use of `saveMint` instead of `mint`.
   *
   * @dev Should have a restricted access handled by the implementation
   *
   * @param _to an address to mint token to
   * @param _tokenId ID of the token to mint
   */
  function mint(address _to, uint256 _tokenId) external;

  /**
   * @dev Creates new tokens starting with token ID specified
   *      and assigns an ownership `_to` for these tokens
   *
   * @dev Token IDs to be minted: [_tokenId, _tokenId + n)
   *
   * @dev n must be greater or equal 2: `n > 1`
   *
   * @dev Unsafe: doesn't execute `onERC721Received` on the receiver.
   *      Prefer the use of `saveMintBatch` instead of `mintBatch`.
   *
   * @dev Should have a restricted access handled by the implementation
   *
   * @param _to an address to mint tokens to
   * @param _tokenId ID of the first token to mint
   * @param _n how many tokens to mint, sequentially increasing the _tokenId
   */
  function mintBatch(
    address _to,
    uint256 _tokenId,
    uint256 _n
  ) external;

  /**
   * @dev Creates new token with token ID specified
   *      and assigns an ownership `_to` for this token
   *
   * @dev Checks if `_to` is a smart contract (code size > 0). If so, it calls
   *      `onERC721Received` on `_to` and throws if the return value is not
   *      `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
   *
   * @dev Should have a restricted access handled by the implementation
   *
   * @param _to an address to mint token to
   * @param _tokenId ID of the token to mint
   */
  function safeMint(address _to, uint256 _tokenId) external;

  /**
   * @dev Creates new token with token ID specified
   *      and assigns an ownership `_to` for this token
   *
   * @dev Checks if `_to` is a smart contract (code size > 0). If so, it calls
   *      `onERC721Received` on `_to` and throws if the return value is not
   *      `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
   *
   * @dev Should have a restricted access handled by the implementation
   *
   * @param _to an address to mint token to
   * @param _tokenId ID of the token to mint
   * @param _data additional data with no specified format, sent in call to `_to`
   */
  function safeMint(
    address _to,
    uint256 _tokenId,
    bytes memory _data
  ) external;

  /**
   * @dev Creates new tokens starting with token ID specified
   *      and assigns an ownership `_to` for these tokens
   *
   * @dev Token IDs to be minted: [_tokenId, _tokenId + n)
   *
   * @dev n must be greater or equal 2: `n > 1`
   *
   * @dev Checks if `_to` is a smart contract (code size > 0). If so, it calls
   *      `onERC721Received` on `_to` and throws if the return value is not
   *      `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
   *
   * @dev Should have a restricted access handled by the implementation
   *
   * @param _to an address to mint token to
   * @param _tokenId ID of the token to mint
   * @param _n how many tokens to mint, sequentially increasing the _tokenId
   */
  function safeMintBatch(
    address _to,
    uint256 _tokenId,
    uint256 _n
  ) external;

  /**
   * @dev Creates new tokens starting with token ID specified
   *      and assigns an ownership `_to` for these tokens
   *
   * @dev Token IDs to be minted: [_tokenId, _tokenId + n)
   *
   * @dev n must be greater or equal 2: `n > 1`
   *
   * @dev Checks if `_to` is a smart contract (code size > 0). If so, it calls
   *      `onERC721Received` on `_to` and throws if the return value is not
   *      `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
   *
   * @dev Should have a restricted access handled by the implementation
   *
   * @param _to an address to mint token to
   * @param _tokenId ID of the token to mint
   * @param _n how many tokens to mint, sequentially increasing the _tokenId
   * @param _data additional data with no specified format, sent in call to `_to`
   */
  function safeMintBatch(
    address _to,
    uint256 _tokenId,
    uint256 _n,
    bytes memory _data
  ) external;
}

// SPDX-License-Identifier: MIT

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