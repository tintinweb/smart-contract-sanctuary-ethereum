/**
 *Submitted for verification at Etherscan.io on 2022-06-13
*/

pragma solidity ^0.8.0;


// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)
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

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)
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

// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)
/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)
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

// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)
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

// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)
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

interface IMTO is IERC721 {
  function mint(address to, uint256 quantity) external;
  function totalSupply() external view returns (uint256);
}

contract MintContract is Ownable, ReentrancyGuard {
  enum MintPeriod {NONE, PRESALE_OT, PRESALE_WL, PUBLICSALE, FREE_MINT}
  enum Role {NONE, OT, TL, WL}

	uint256 public constant MAX_PER_ADDRESS_OT = 4;
  uint256 public constant MAX_PER_ADDRESS_TL = 2;
  uint256 public constant MAX_PER_ADDRESS_WL = 2;
  uint256 public constant MAX_PER_ADDRESS_PUBLIC = 4;
  uint256 public constant MAX_PER_ADDRESS_FREE = 1;

  uint256 public constant COLLECTION_SIZE = 6666;

  uint256 public constant MINT_PRICE_OT = 0.04 ether;
  uint256 public constant MINT_PRICE_WL = 0.05 ether;
  uint256 public constant MINT_PRICE_PUBLIC = 0.06 ether;

  MintPeriod public currentMintPeriod = MintPeriod.NONE;

  IMTO public MTOContract;

  mapping(address => uint256) private mintAmountOT;
  mapping(address => uint256) private mintAmountTL;
  mapping(address => uint256) private mintAmountWL;
  mapping(address => uint256) private mintAmountFree;
  mapping(address => uint256) private mintAmountPublic;

  address private publicKey;
  uint256 freeMintAmount;

	struct Token {
		bytes32 r;
		bytes32 s;
		uint8 v;
	}

  event UpdateMintPeriod(MintPeriod _period);

  modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }

	function _isVerifiedToken(bytes32 digest, Token memory token) internal view returns (bool) {
		address signer = ecrecover(digest, token.v, token.r, token.s);
		require(signer != address(0), 'ECDSA: invalid signature');
		return signer == publicKey;
	}

  function presaleMint(uint256 quantity, Role role, Token memory token) external payable callerIsUser {
    require(currentMintPeriod == MintPeriod.PRESALE_OT, "presale has not begun yet");

    uint256 _totalSupply = MTOContract.totalSupply();
    require(_totalSupply + quantity * 2 + freeMintAmount < COLLECTION_SIZE, "reached max supply");
    require(role == Role.OT || role == Role.TL, "invalid role for this period");

    uint256 mintPrice;

    if (role == Role.OT){
      require(mintAmountOT[msg.sender] + quantity <= MAX_PER_ADDRESS_OT, "can not mint this many");
      mintPrice = MINT_PRICE_OT;
      mintAmountOT[msg.sender] += quantity;
    } else if (role == Role.TL){
      require(mintAmountTL[msg.sender] + quantity <= MAX_PER_ADDRESS_TL, "can not mint this many");
      mintPrice = MINT_PRICE_WL;
      mintAmountTL[msg.sender] += quantity;
    }

		bytes32 digest = keccak256(
      abi.encode(MintPeriod.PRESALE_OT, role, msg.sender)
    );

		require(_isVerifiedToken(digest, token), 'Invalid token'); // 4

    MTOContract.mint(msg.sender, quantity * 2);
    
    refundIfOver(mintPrice * quantity);
  }

  function presaleMintForWL(uint256 quantity, Token memory token) external payable callerIsUser {
    require(currentMintPeriod == MintPeriod.PRESALE_WL, "presaleWL has not begun yet");

    uint256 _totalSupply = MTOContract.totalSupply();
    require(_totalSupply + quantity * 2 + freeMintAmount < COLLECTION_SIZE, "reached max supply");

    require(mintAmountWL[msg.sender] + quantity <= MAX_PER_ADDRESS_WL, "can not mint this many");
    mintAmountWL[msg.sender] += quantity;

    uint256 mintPrice = MINT_PRICE_WL;

		bytes32 digest = keccak256(
      abi.encode(MintPeriod.PRESALE_WL, msg.sender)
    );

		require(_isVerifiedToken(digest, token), 'Invalid token');

    MTOContract.mint(msg.sender, quantity * 2);
    
    refundIfOver(mintPrice * quantity);
  }

  function publicSaleMint(uint256 quantity) external payable callerIsUser {
    require(currentMintPeriod == MintPeriod.PUBLICSALE, "public sale has not begun yet");

    uint256 _totalSupply = MTOContract.totalSupply();
    require(_totalSupply + quantity * 2 + freeMintAmount < COLLECTION_SIZE, "reached max supply");
    
    require(mintAmountPublic[msg.sender] + quantity <= MAX_PER_ADDRESS_PUBLIC, "can not mint this many");
    mintAmountPublic[msg.sender] += quantity;

    uint256 mintPrice = MINT_PRICE_PUBLIC;

    MTOContract.mint(msg.sender, quantity * 2);
    refundIfOver(mintPrice * quantity);
  }

  function freeMint(Token memory token) external payable callerIsUser {
    require(currentMintPeriod == MintPeriod.FREE_MINT, "free mint has not begun yet");

    uint256 _totalSupply = MTOContract.totalSupply();
    require(_totalSupply + 2 < COLLECTION_SIZE, "reached max supply");

    require(mintAmountFree[msg.sender] == 0, "can not mint this many");
    mintAmountFree[msg.sender] = 1;

		bytes32 digest = keccak256(
      abi.encode(MintPeriod.FREE_MINT, msg.sender)
    );

		require(_isVerifiedToken(digest, token), 'Invalid token');

    MTOContract.mint(msg.sender, 2);
  }

  function refundIfOver(uint256 amount) private {
    require(msg.value >= amount, "Need to send more ETH.");
    if (msg.value > amount) {
      payable(msg.sender).transfer(msg.value - amount);
    }
  }

  function setPublicKey(address publicKey_) external onlyOwner {
    publicKey = publicKey_;
  }
  
  // For marketing etc.
  function devMint(uint256 quantity, uint256 maxBatchSize) external onlyOwner {
    uint256 _totalSupply = MTOContract.totalSupply();
    require(
      _totalSupply + quantity <= COLLECTION_SIZE,
      "too many already minted before dev mint"
    );

    uint256 numChunks = quantity / maxBatchSize;

    for (uint256 i = 0; i < numChunks; i++) {
      MTOContract.mint(msg.sender, maxBatchSize);
    }

    uint256 remaining = quantity % maxBatchSize;
    if (remaining > 0) {
      MTOContract.mint(msg.sender, remaining);
    }
  }

  function withdrawMoney() external onlyOwner nonReentrant {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "Transfer failed.");
  }

  function setMTOContract(address _mtoContract) external onlyOwner {
    MTOContract = IMTO(_mtoContract);
  }

  function setCurrentMintPeriod(MintPeriod _period) external onlyOwner {
    currentMintPeriod = _period;
    emit UpdateMintPeriod(_period);
  }
}