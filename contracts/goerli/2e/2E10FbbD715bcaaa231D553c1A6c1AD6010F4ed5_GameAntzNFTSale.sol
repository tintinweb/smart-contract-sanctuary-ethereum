// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "../interfaces/IGameAntzCardsFeatures.sol";

interface IGameAntzNFT is IGameAntzCardsFeatures {
  function mintBatch(
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) external;

  function mint(
    address to,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) external;
}

contract GameAntzNFTSale is Ownable {
  struct Multiplier {
    uint256 value;
    uint256 weight;
    uint256 quantity;
  }

  uint256 nonce;
  uint256 maxWeight;
  uint256 public nextTokenId;
  mapping(address => uint256) mintedCount;

  IGameAntzNFT public nft;
  uint256 public price;
  address payable public paymentRecipient;
  uint256 public constant maxMintPerWallet = 5;
  bool public enabled;

  Multiplier[] public multipliers;

  event Minted(address indexed account, uint256 indexed tokenId, uint256 amount, uint256 multiplier);
  event MultiplierAdded(uint256 indexed multiplier, uint256 weight, uint256 quantity);

  constructor(
    IGameAntzNFT _nft,
    address payable _paymentRecipient,
    uint256 _price,
    Multiplier[] memory _multipliers
  ) {
    nft = _nft;
    paymentRecipient = _paymentRecipient;
    price = _price;
    enabled = true;

    for (uint256 i = 0; i < _multipliers.length; i++) {
      multipliers.push(_multipliers[i]);
      maxWeight += _multipliers[i].weight;
      emit MultiplierAdded(_multipliers[i].value, _multipliers[i].weight, _multipliers[i].quantity);
    }
  }

  function mint(uint256 quantity) external payable {
    require(enabled, "Mint disabled");

    require(quantity > 0, "Invalid quantity");

    uint256 payment = quantity * price;
    require(msg.value == payment, "Invalid payment");

    mintedCount[msg.sender] += quantity;
    require(mintedCount[msg.sender] <= maxMintPerWallet, "Max mint per wallet reached");

    paymentRecipient.transfer(msg.value);

    for (uint256 i = 0; i < quantity; i++) {
      uint256 multiplier = getMultiplier();
      nft.mint(msg.sender, nextTokenId, 1, "");
      nft.addMultiplierCard(nextTokenId, multiplier);
      emit Minted(msg.sender, nextTokenId++, 1, multiplier);
    }
  }

  function getRandomMultiplierIndex() internal returns (uint256) {
    require(multipliers.length != 0, "Minting is finished!");

    uint256 random = getRandomNumber(0, maxWeight);
    uint256 s = 0;
    uint256 lastIndex = multipliers.length - 1;

    for (uint256 i = 0; i < lastIndex; ++i) {
      s += multipliers[i].weight;
      if (random < s) {
        return i;
      }
    }

    return lastIndex;
  }

  function getMultiplier() internal returns (uint256 multiplier) {
    uint256 i = getRandomMultiplierIndex();
    multiplier = multipliers[i].value;
    multipliers[i].quantity--;
    if (multipliers[i].quantity == 0) {
      maxWeight -= multipliers[i].weight;
      multipliers[i] = multipliers[multipliers.length - 1];
      multipliers.pop();
    }
  }

  function getRandomNumber(uint256 min, uint256 max) internal returns (uint256) {
    if (max == 0) return 0;
    return (uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, msg.sender, nonce++))) % max) + min;
  }

  function setPrice(uint256 _price) external onlyOwner {
    price = _price;
  }

  function setPaymentRecipient(address payable _paymentRecipient) external onlyOwner {
    paymentRecipient = _paymentRecipient;
  }

  function setEnabled(bool _enabled) external onlyOwner {
    enabled = _enabled;
  }

  function addMultiplier(Multiplier memory _multiplier) external onlyOwner {
    multipliers.push(_multiplier);
    emit MultiplierAdded(_multiplier.value, _multiplier.weight, _multiplier.quantity);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IGameAntzCardsFeatures {
  function addHarvestReliefCard(uint256 _tokenId, uint256 _harvestRelief) external;

  function addFeeDiscountCard(uint256 _tokenId, uint256 _feeDiscount) external;

  function addMultiplierCard(uint256 _tokenId, uint256 _multiplier) external;

  function removeHarvestReliefCard(uint256 _tokenId) external;

  function removeFeeDiscountCard(uint256 _tokenId) external;

  function removeMultiplierCard(uint256 _tokenId) external;

  function getHarvestReliefCards() external view returns (uint256[] memory);

  function getFeeDiscountCards() external view returns (uint256[] memory);

  function getMultiplierCards() external view returns (uint256[] memory);

  function getHarvestRelief(uint256 id) external returns (uint256);

  function getFeeDiscount(uint256 id) external returns (uint256);

  function getMultiplier(uint256 id) external returns (uint256);
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