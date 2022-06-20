pragma solidity ^0.8.8;

// SPDX-License-Identifier: MIT


import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./lib/ERC721.sol";

/**
 * This contract acts as a vault for ERC721 contracts and allows people to either purchase for ETH
 * or lets external contract executor entity to transfer token via API
 */
contract Distributor is IERC721Receiver, Ownable {
  struct Distributable {
    uint256[] supply;
    uint256 price;
  }

  string constant NOT_TRACKED = "007001";
  string constant TRACKED = "007002";
  string constant SUPPLY_DEPLETED = "007003";
  string constant FUNDS_MISMATCH = "007004";
  string constant TRANSFER_FAILED = "007005";
  string constant SLIPPAGE_TOO_LOW = "007006";
  string constant SLIPPAGE_TOO_HIGH = "007007";
  string constant PRICE_SLIPPED = "007008";

  AggregatorV3Interface internal priceFeed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);

  mapping(ERC721 => Distributable) private _supply;
  ERC721[] private _tracked;
  address private _vault;

  constructor(address vault) Ownable() {
    _vault = vault;
  }

  /**
   * Add ERC721 contract to the watchlist
   */
  function addERC721(ERC721 erc721, uint256 price) public onlyOwner {
    require(!_isContractTracked(erc721), TRACKED);


    uint256[] memory _ids;
    _supply[erc721] = Distributable(_ids, price);
    _tracked.push(erc721);
  }

  /**
   * Update price
   */
  function updatePrice(ERC721 erc721, uint256 price) public onlyOwner {
    require(_isContractTracked(erc721), TRACKED);
    _supply[erc721].price = price;
  }

  /**
   * Retrieve available supply for the contract
   */
  function supply(ERC721 erc721) public view returns (uint256) {
    require(_isContractTracked(erc721), NOT_TRACKED);
    return _supply[erc721].supply.length;
  }

  /**
   * Requested estimated token price in wei
   *
   * @param erc721 address of the tracked ERC721 contract
   */
  function estimatePrice(ERC721 erc721) public view returns (int) {
    require(_isContractTracked(erc721), NOT_TRACKED);

    uint8 decimals = priceFeed.decimals();

    (
    /*uint80 roundID*/,
    int exchangeRate,
    /*uint startedAt*/,
    uint timeStamp,
    /*uint80 answeredInRound*/
    ) = priceFeed.latestRoundData();
//    require(timeStamp > 0, 'No data');

    int tokenPrice = scalePrice(int(_supply[erc721].price), 0, 8);

    return scalePrice(tokenPrice * 100000000 / exchangeRate, 8, 18);
  }

  /**
   * Any external public entity can send ETH to the contract and retrieve and NFT token
   *
   * @param erc721 Address of the contract to interact with
   * @param to Address of the user to receive the token
   * @param slippage Tolerated rate slippage with with two decimals. E.g. 100 means 1% slippage.
   * Slippage cannot be higher than 5% (or 500)
   */
  function retrieve(ERC721 erc721, address to, uint8 slippage) public payable {
    require(_isContractTracked(erc721), NOT_TRACKED);

    require(msg.value > 0, FUNDS_MISMATCH);

    require(slippage < 500, SLIPPAGE_TOO_HIGH);
    require(slippage > 0, SLIPPAGE_TOO_LOW);

    uint256[] memory currentSupply = _supply[erc721].supply;
    require(currentSupply.length > 0, SUPPLY_DEPLETED);

    // Calculate price difference
    uint256 estimate = uint(estimatePrice(erc721));
    uint256 diff = (uint(msg.value - estimate) * 100 / msg.value) * 100;

    require(diff <= slippage, PRICE_SLIPPED);

    uint256 tokenId = currentSupply[currentSupply.length - 1];
    _supply[erc721].supply.pop();

    erc721.safeTransferFrom(address(this), to, tokenId);

    (bool sent,) = _vault.call{value : msg.value}("");
    require(sent, TRANSFER_FAILED);
  }

  /**
   * An entity w/ contract executor role can transfer token w/o sending payment
   *
   * Can be used to connect w/ Stripe or any other fiat payment gateway
   */
  function transfer(ERC721 erc721, address to) public onlyOwner {
    require(_isContractTracked(erc721), NOT_TRACKED);

    uint256[] memory currentSupply = _supply[erc721].supply;

    require(currentSupply.length > 0, SUPPLY_DEPLETED);

    uint256 tokenId = currentSupply[currentSupply.length - 1];
    _supply[erc721].supply.pop();

    erc721.transferFrom(address(this), to, tokenId);
  }

  function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4) {
    require(_isContractTracked(ERC721(operator)), NOT_TRACKED);

    _supply[ERC721(operator)].supply.push(tokenId);

    return bytes4(IERC721Receiver.onERC721Received.selector);
  }

  /**
   * Send the remaining supply to the vault and destroy the contract
   */
  function arrivederci() public onlyOwner {
    for (uint i = 0; i < _tracked.length; i++) {
      for (uint j = 0; j < _supply[_tracked[i]].supply.length; j++) {
        ERC721(_tracked[i]).transferFrom(address(this), _vault, _supply[_tracked[i]].supply[j]);
      }
    }

    selfdestruct(payable(_vault));
  }


  /**
   * Private
   */
  function _isContractTracked(ERC721 erc721) private view returns (bool) {
    return _supply[erc721].price > 0;
  }

  function scalePrice(int256 _price, uint8 _priceDecimals, uint8 _decimals) internal pure returns (int256) {
    if (_priceDecimals < _decimals) {
      return _price * int256(10 ** uint256(_decimals - _priceDecimals));
    } else if (_priceDecimals > _decimals) {
      return _price / int256(10 ** uint256(_priceDecimals - _decimals));
    }

    return _price;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

pragma solidity ^0.8.8;

// SPDX-License-Identifier: MIT


import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";


// solhint-disable-next-line indent
abstract contract ERC721 is IERC721Metadata, IERC721Enumerable, Context {
  using Address for address;

  mapping(uint256 => address) internal _owners;
  mapping (uint256 => address) internal _idToApproval;
  mapping (address => mapping (address => bool)) internal _ownerToOperators;

  uint256 internal _maxTokenId;

  /**
   * @dev List of revert message codes. Implementing dApp should handle showing the correct message.
   * Based on 0xcert framework error codes.
   */
  string constant ZERO_ADDRESS = "003001";
  string constant NOT_VALID_NFT = "003002";
  string constant NOT_OWNER_OR_OPERATOR = "003003";
  string constant NOT_OWNER_APPROVED_OR_OPERATOR = "003004";
  string constant NOT_ABLE_TO_RECEIVE_NFT = "003005";
  string constant NFT_ALREADY_EXISTS = "003006";
  string constant NOT_OWNER = "003007";
  string constant IS_OWNER = "003008";

  /**
 * @dev Magic value of a smart contract that can receive NFT.
   * Equal to: bytes4(keccak256("onERC721Received(address,address,uint256,bytes)")).
   */
  bytes4 internal constant MAGIC_ON_ERC721_RECEIVED = 0x150b7a02;

  constructor() {}

  /// @notice MARK: Useful modifiers

  /**
   * @dev Guarantees that the _msgSender() is an owner or operator of the given NFT.
   * @param tokenId ID of the NFT to validate.
   */
  modifier canOperate(uint256 tokenId) {
    address tokenOwner = _owners[tokenId];
    require(
      tokenOwner == _msgSender() || _ownerToOperators[tokenOwner][_msgSender()],
      NOT_OWNER_OR_OPERATOR
    );
    _;
  }

  /**
   * @dev Guarantees that the _msgSender() is allowed to transfer NFT.
   * @param tokenId ID of the NFT to transfer.
   */
  modifier canTransfer(uint256 tokenId) {
    address tokenOwner = _owners[tokenId];

    require(
      tokenOwner == _msgSender()
      || _idToApproval[tokenId] == _msgSender()
      || _ownerToOperators[tokenOwner][_msgSender()],
      NOT_OWNER_APPROVED_OR_OPERATOR
    );
    _;
  }

  /**
   * @dev Guarantees that _tokenId is a valid Token.
   * @param tokenId ID of the NFT to validate.
   */
  modifier validNFToken(uint256 tokenId) {
    require(_exists(tokenId), NOT_VALID_NFT);
    _;
  }

  /// @notice Returns a number of decimal points
  /// @return Number of decimal points
  function decimals() public pure virtual returns (uint256) {
    return 0;
  }

  /// @notice MARK: ERC721 Implementation

  /// @notice Count all NFTs assigned to an owner
  /// @dev NFTs assigned to the zero address are considered invalid, and this
  ///  function throws for queries about the zero address.
  /// @param owner An address for whom to query the balance
  /// @return balance The number of NFTs owned by `owner`, possibly zero
  function balanceOf(address owner) public view virtual returns (uint256 balance) {
    require(owner != address(0),  ZERO_ADDRESS);

    for (uint256 i; i <= _maxTokenId; i++) {
      if (_owners[i] == owner) {
        balance++;
      }
    }

    return balance;
  }

  /// @notice Find the owner of an NFT
  /// @dev NFTs assigned to zero address are considered invalid, and queries
  ///  about them do throw.
  /// @param tokenId The identifier for an NFT
  /// @return owner The address of the owner of the NFT
  function ownerOf(uint256 tokenId) external view returns (address owner) {
    owner = _owners[tokenId];
    require(owner != address(0), NOT_VALID_NFT);
  }

  /// @notice Change or reaffirm the approved address for an NFT
  /// @dev The zero address indicates there is no approved address.
  ///  Throws unless `_msgSender()` is the current NFT owner, or an authorized
  ///  operator of the current owner.
  /// @param approved The new approved NFT controller
  /// @param tokenId The NFT to approve
  function approve(address approved, uint256 tokenId) external canOperate(tokenId) validNFToken(tokenId) {
    address tokenOwner = _owners[tokenId];
    require(approved != tokenOwner, IS_OWNER);

    _idToApproval[tokenId] = approved;
    emit Approval(tokenOwner, approved, tokenId);
  }

  /// @notice Get the approved address for a single NFT
  /// @dev Throws if `tokenId` is not a valid NFT.
  /// @param tokenId The NFT to find the approved address for
  /// @return The approved address for this NFT, or the zero address if there is none
  function getApproved(uint256 tokenId) external view validNFToken(tokenId) returns (address) {
    return _idToApproval[tokenId];
  }

  /// @notice Enable or disable approval for a third party ("operator") to manage
  ///  all of `_msgSender()`'s assets
  /// @dev Emits the ApprovalForAll event. The contract MUST allow
  ///  multiple operators per owner.
  /// @param operator Address to add to the set of authorized operators
  /// @param approved True if the operator is approved, false to revoke approval
  function setApprovalForAll(address operator, bool approved) external {
    _ownerToOperators[_msgSender()][operator] = approved;
    emit ApprovalForAll(_msgSender(), operator, approved);
  }

  /// @notice Query if an address is an authorized operator for another address
  /// @param owner The address that owns the NFTs
  /// @param operator The address that acts on behalf of the owner
  /// @return True if `operator` is an approved operator for `owner`, false otherwise
  function isApprovedForAll(address owner, address operator) public view virtual returns (bool) {
    return _ownerToOperators[owner][operator];
  }

  /// @notice Transfers the ownership of an NFT from one address to another address
  /// @dev This works identically to the other function with an extra data parameter,
  ///  except this function just sets data to "".
  /// @param from The current owner of the NFT
  /// @param to The new owner
  /// @param tokenId The NFT to transfer
  function safeTransferFrom(address from, address to, uint256 tokenId) external virtual {
    _safeTransferFrom(from, to, tokenId, '');
  }

  /// @notice Transfers the ownership of an NFT from one address to another address
  /// @dev Throws unless `_msgSender()` is the current owner, an authorized
  ///  operator, or the approved address for this NFT. Throws if `from` is
  ///  not the current owner. Throws if `to` is the zero address. Throws if
  ///  `tokenId` is not a valid NFT. When transfer is complete, this function
  ///  checks if `to` is a smart contract (code size > 0). If so, it calls
  ///  `onERC721Received` on `to` and throws if the return value is not
  ///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
  /// @param from The current owner of the NFT
  /// @param to The new owner
  /// @param tokenId The NFT to transfer
  /// @param data Additional data with no specified format, sent in call to `to`
  function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external canTransfer(tokenId) validNFToken(tokenId) {
    _safeTransferFrom(from, to, tokenId, data);
  }

  /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
  ///  TO CONFIRM THAT `to` IS CAPABLE OF RECEIVING NFTS OR ELSE
  ///  THEY MAY BE PERMANENTLY LOST
  /// @dev Throws unless `_msgSender()` is the current owner, an authorized
  ///  operator, or the approved address for this NFT. Throws if `from` is
  ///  not the current owner. Throws if `to` is the zero address. Throws if
  ///  `tokenId` is not a valid NFT.
  /// @param from The current owner of the NFT
  /// @param to The new owner
  /// @param tokenId The NFT to transfer
  function transferFrom(address from, address to, uint256 tokenId) external canTransfer(tokenId) validNFToken(tokenId) {
    address tokenOwner = _owners[tokenId];
    require(tokenOwner == from, NOT_OWNER);
    require(to != address(0), ZERO_ADDRESS);

    _transfer(to, tokenId);
  }

  /// @notice MARK: ERC721Enumerable

  /// @notice Count NFTs tracked by this contract
  /// @return total A count of valid NFTs tracked by this contract, where each one of
  ///  them has an assigned and queryable owner not equal to the zero address
  function totalSupply() public view returns (uint256 total) {
    for (uint256 i; i <= _maxTokenId; i++) {
      if (_owners[i] != address(0)) {
        total++;
      }
    }

    return total;
  }

  /// @notice Enumerate NFTs assigned to an owner
  /// @dev Throws if `index` >= `balanceOf(owner)` or if
  ///  `owner` is the zero address, representing invalid NFTs.
  /// @param owner An address where we are interested in NFTs owned by them
  /// @param index A counter less than `balanceOf(owner)`
  /// @return The token identifier for the `index`th NFT assigned to `owner`,
  ///   (sort order not specified)
  function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256) {
    uint256 balance = balanceOf(owner);

    uint256[] memory tokens = new uint256[](balance);
    uint256 idx;

    for (uint256 i; i <= _maxTokenId; i++) {
      if (_owners[i] == owner) {
        tokens[idx] = i;
        idx++;
      }
    }

    return tokens[index];
  }

  /// @notice Enumerate valid NFTs
  /// @dev Throws if `index` >= `totalSupply()`.
  /// @param index A counter less than `totalSupply()`
  /// @return The token identifier for the `index`th NFT,
  ///  (sort order not specified)
  function tokenByIndex(uint256 index) external view returns (uint256) {
    uint256 supply = totalSupply();

    uint256[] memory tokens = new uint256[](supply);
    uint256 idx;
    for (uint256 i; i <= _maxTokenId; i++) {
      if (_owners[i] != address(0)) {
        tokens[idx] = i;
        idx++;
      }
    }

    return tokens[index];
  }

  /// @notice MARK: ERC165 Implementation

  /// @notice Query if a contract implements an interface
  /// @param interfaceId The interface identifier, as specified in ERC-165
  /// @dev Interface identification is specified in ERC-165. This function
  ///  uses less than 30,000 gas.
  /// @return `true` if the contract implements `interfaceID` and
  ///  `interfaceId` is not 0xffffffff, `false` otherwise
  function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
    if (interfaceId == 0xffffffff) {
      return false;
    }

    return
      interfaceId == type(IERC721).interfaceId ||
      interfaceId == type(IERC721Receiver).interfaceId ||
      interfaceId == type(IERC721Metadata).interfaceId ||
      interfaceId == type(IERC721Enumerable).interfaceId;
  }

  /// MARK: Private methods
  function _mint(address to, uint256 tokenId) internal {
    require(to != address(0), ZERO_ADDRESS);
    require(!_exists(tokenId), NFT_ALREADY_EXISTS);

    _owners[tokenId] = to;

    if (tokenId > _maxTokenId) {
      _maxTokenId = tokenId;
    }

    emit Transfer(address(0), to, tokenId);

    if (to.isContract()) {
      bytes4 retval = IERC721Receiver(to).onERC721Received(address(this), address(0), tokenId, "");
      require(retval == MAGIC_ON_ERC721_RECEIVED, NOT_ABLE_TO_RECEIVE_NFT);
    }
  }

  function _burn(uint256 tokenId) internal virtual validNFToken(tokenId) canTransfer(tokenId) {
    address tokenOwner = _owners[tokenId];

    _clearApproval(tokenId);
    delete _owners[tokenId];

    emit Transfer(tokenOwner, address(0), tokenId);
  }

  function _exists(uint256 tokenId) internal view returns (bool) {
    return _owners[tokenId] != address(0);
  }

  function _clearApproval(uint256 tokenId) private {
    delete _idToApproval[tokenId];
  }

  /**
   * @dev Actually perform the safeTransferFrom.
   * @param _from The current owner of the NFT.
   * @param _to The new owner.
   * @param _tokenId The NFT to transfer.
   * @param _data Additional data with no specified format, sent in call to `_to`.
   */
  function _safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes memory _data
  )
  private
  canTransfer(_tokenId)
  validNFToken(_tokenId)
  {
    address tokenOwner = _owners[_tokenId];
    require(tokenOwner == _from, NOT_OWNER);
    require(_to != address(0), ZERO_ADDRESS);

    _transfer(_to, _tokenId);

    if (_to.isContract()) {
      bytes4 retval = IERC721Receiver(_to).onERC721Received(_msgSender(), _from, _tokenId, _data);
      require(retval == MAGIC_ON_ERC721_RECEIVED, NOT_ABLE_TO_RECEIVE_NFT);
    }
  }

  function _transfer(address to, uint256 tokenId) internal virtual {
    address from = _owners[tokenId];

    _beforeTransfer(from, to, tokenId);

    _clearApproval(tokenId);
    _owners[tokenId] = to;

    emit Transfer(from, to, tokenId);
  }

  function _beforeTransfer(address from, address to, uint256 tokenId) internal virtual {}
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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