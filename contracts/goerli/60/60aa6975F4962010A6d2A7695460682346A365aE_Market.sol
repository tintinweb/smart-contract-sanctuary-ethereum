// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

interface IOutbox {
  function dispatch(
    uint32 _destinationDomain,
    bytes32 _recipientAddress,
    bytes calldata _messageBody
  ) external returns (uint256);
}

interface IMessageRecipient {
  function handle(
    uint32 _origin,
    bytes32 _sender,
    bytes calldata _messageBody
  ) external;
}

contract Market is IMessageRecipient, Ownable {
  constructor(address _outbox) {
    outbox = _outbox;
  }
  AggregatorV3Interface internal priceFeed;

  address public outbox;
  mapping(bytes32=>address) public sellerAddress;
  mapping(bytes32 => uint256) public listedPrice;
  mapping(bytes32 => uint32) public listedCurrency;
  mapping(uint32 => bytes32) public domainToContractAddress;
  mapping(uint32 => address) public currencyIdToChainlinkContract;

  event Listed(address nftContractAddress, uint256 tokenId, address seller, uint256 price);
  event Bought(address nftContractAddress, uint256 tokenId, address seller, uint256 price);

  modifier onlyResisterdContract(uint32 _origin, bytes32 _sender) {
    bool resistered = false;

    bytes32 resisteredAddress = domainToContractAddress[_origin];
    if (_sender == resisteredAddress) {
      resistered = true;
    }
    _;
  }

  function setContract(uint32 domainId, address contractAddress) public onlyOwner {
    domainToContractAddress[domainId] = addressToBytes32(contractAddress);
  }

  function setChainlinkContract(uint32 currencyId, address contractAddress) public onlyOwner {
    currencyIdToChainlinkContract[currencyId] = contractAddress;
  }

  function getResisteredContract(uint32 domainId) public view returns(address) {
    return bytes32ToAddress(domainToContractAddress[domainId]);
  }

  function buy(uint32 domainId, address contractAddress, address nftContractAddress, uint256 tokenId, address payable seller, uint32 currencyId)public payable {
    bytes32 key = keccak256(abi.encodePacked(domainId, nftContractAddress, tokenId, seller));
    if(currencyId == listedCurrency[key]){
    // Check transferred amount is match to the listedPrice
      require(listedPrice[key] <= msg.value);
      seller.transfer(listedPrice[key]);

    // Send message to the other chain 
      _sendMessage(domainId, contractAddress, abi.encode("Trading", nftContractAddress, tokenId, msg.sender, listedPrice[key], 0,0));
    }else{
    // Multipy currency * price both listed and used payment
      address chainlinkContractAddress = currencyIdToChainlinkContract[currencyId];
      address listedChainlinkContractAddress = currencyIdToChainlinkContract[listedCurrency[key]];
      ( , int256 CurrencyPrice, , , ) = AggregatorV3Interface(chainlinkContractAddress).latestRoundData();
      ( , int256 listedCurrencyPrice, , , ) = AggregatorV3Interface(listedChainlinkContractAddress).latestRoundData();
      require(uint256(listedCurrencyPrice) * listedPrice[key] <= uint256(CurrencyPrice) * msg.value);
      seller.transfer(listedPrice[key]);
      // Send message to the other chain 
      _sendMessage(domainId, contractAddress, abi.encode("Trading", nftContractAddress, tokenId, msg.sender, listedPrice[key], 0,0));
    }
    emit Bought(nftContractAddress, tokenId, seller, listedPrice[key]);
  }


  function list(address nftContractAddress, uint256 tokenId, uint256 price, uint32 currencyId, uint32 domainIdTo, address ourContractAddress)public {
    // Transfer NFT to our contract
    IERC721(nftContractAddress).transferFrom(msg.sender, address(this), tokenId);
    sellerAddress[keccak256(abi.encodePacked(nftContractAddress, tokenId))] = msg.sender;

    // Send Message via Hyperlane
    _sendMessage(domainIdTo, ourContractAddress, abi.encode("Listing", nftContractAddress, tokenId, msg.sender, price, currencyId));

    emit Listed(nftContractAddress, tokenId, msg.sender, price);
  }

  function cancelListing(address nftContractAddress, uint256 tokenId) public {
    bytes32 key = keccak256(abi.encodePacked(nftContractAddress, tokenId));
    require(msg.sender == sellerAddress[key]);
    IERC721(nftContractAddress).transferFrom(address(this), msg.sender, tokenId);
    sellerAddress[key] == address(0);
  }


  function handle(uint32 _origin, bytes32 _sender, bytes calldata _messageBody) external override onlyResisterdContract(_origin, _sender) {
    // Branch, according to the message
    (string memory messageType, address nftContractAddress, uint256 tokenId, address messageSender, uint256 price, uint32 currencyId) = abi.decode(_messageBody, (string, address, uint256, address, uint256, uint32));
    // case Listing
    // Upgrade the mapping price
    if (compareStrings(messageType, "Listing")) {
        bytes32 key = keccak256(abi.encodePacked(_origin, nftContractAddress, tokenId, messageSender));
        listedPrice[key] = price;
        listedCurrency[key] = currencyId;
    }

    // case Selling
    // Transfer NFTs to the buyer 
    if (compareStrings(messageType, "Trading")) {
        IERC721(nftContractAddress).transferFrom(address(this),messageSender,tokenId);
        sellerAddress[keccak256(abi.encodePacked(nftContractAddress, tokenId))] = address(0);
    }

  }

  function getPrice(uint32 domainId, address nftContractAddress, uint256 tokenId, address seller) public view returns(uint256){
    bytes32 key = keccak256(abi.encodePacked(domainId, nftContractAddress, tokenId, seller));
    return listedPrice[key];
  }

  function _sendMessage (uint32 _destinationDomain, address _receipient, bytes memory _callData) internal {
    IOutbox(outbox).dispatch(_destinationDomain, addressToBytes32(_receipient), _callData);
  }


  function addressToBytes32(address _addr) internal pure returns (bytes32) {
    return bytes32(uint256(uint160(_addr)));
  }

  function bytes32ToAddress(bytes32 _buf) internal pure returns (address) {
    return address(uint160(uint256(_buf)));
  }

  function compareStrings(string memory a, string memory b) internal pure returns (bool) {
    return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
  }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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