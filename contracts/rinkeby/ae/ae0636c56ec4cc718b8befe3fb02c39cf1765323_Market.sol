/**
 *Submitted for verification at Etherscan.io on 2022-02-09
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

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

    constructor () {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}


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
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

interface IERC721Ownable is IERC721Enumerable {
    function owner() external view returns(address);
}


contract Market is ReentrancyGuard {
    constructor(){ }
    
    event NftSold(uint256 price, address from, address to, address nftAddress, uint256 tokenId);

    event AuctionStarted(address nftAddress, uint256 tokenId, address payableAddress, uint256 auctionTimestamp);

    event FixedPriceStarted(address nftAddress, uint256 tokenId, address payableAddress, uint256 auctionTimestamp, uint256 price);

    event CollectionCreated(address nftAddress, address owner);

    event NftMinted(address nftAddress, uint256 initialTokenId, uint256 finalTokenId,address owner, string uri);
    
    mapping(address => mapping(uint256 => address)) public payableOption;

    mapping(address => mapping(uint256 => uint256)) public fixedPrice;

    mapping(address => mapping(uint256 => uint256)) public saleTime;

    mapping(address => bool) public isCollection;

    address[] public collectionsCreated;

    address public WETH = address(0);
    
    function recover(bytes32 hash, bytes memory signature) private pure returns(address){
      bytes32 r;
      bytes32 s;
      uint8 v;
      
      // check the signature length.
      if (signature.length != 65) {
          return (address(0));
      }
      
      assembly {
        r := mload(add(signature, 0x20))
        s := mload(add(signature, 0x40))
        v := byte(0, mload(add(signature, 0x60)))
      }
      
      if(v < 27) {
          v += 27;
      }
      
      if(v != 27 && v != 28){
          return address(0);
      }
      else{
          return ecrecover(hash, v, r, s);
      }
    }

    function collectionCreated() public nonReentrant  {
      require(msg.sender != tx.origin, "Caller origin validation failed");
      collectionsCreated.push(address(msg.sender));
      isCollection[msg.sender] = true;
      emit CollectionCreated(msg.sender, tx.origin);
    }

    function nftMinted(uint256 initialTokenId, uint256 finalTokenId, string memory uri) public {
      require(isCollection[msg.sender], "ERC721 validation failed");
      emit NftMinted(msg.sender, initialTokenId, finalTokenId,tx.origin, uri);
    }

    function purchaseAuction(uint256 bidAmount, address nftAddress, uint256 tokenId, bytes32 _hash, bytes memory approvedSignature) public payable nonReentrant {
      require(saleTime[nftAddress][tokenId] > block.timestamp, "Timeout for this sale");
      address owner = recover(_hash, approvedSignature);
      require(owner!=address(0),"owner can't be address zero");
      IERC721 nftInstance = IERC721(nftAddress);
      
      // Validating the NFT Instance.
      require(owner==nftInstance.ownerOf(tokenId), "Unable to validate the owner of this token Id");
      require(nftInstance.getApproved(tokenId)==address(this), "NFT is not approved by the owner");
      
      // Validating the Token Instance.
      address payableAddress = payableOption[nftAddress][tokenId];

      if(payableAddress == address(WETH)){
        require(msg.value >= bidAmount, "value must be higher or equal to bidAmount.");
        payable(owner).transfer(msg.value);
      }
      else {
        require(payableAddress!=address(0), "Payable address not set or Invalid");
        IERC20 payableInstance = IERC20(payableAddress);
        require(bidAmount <= payableInstance.allowance(address(msg.sender), address(this)), "Payable is not allowed by buyer");
        
        payableInstance.transferFrom(address(msg.sender), owner, bidAmount);
      }
      nftInstance.transferFrom(owner, address(msg.sender), tokenId);
      
      delete payableOption[nftAddress][tokenId];
      delete saleTime[nftAddress][tokenId];

      emit NftSold(bidAmount, owner, address(msg.sender), nftAddress, tokenId);
    }

    function purchaseWithFixedPrice(address to, address nftAddress, uint256 tokenId) public payable nonReentrant {
      require(saleTime[nftAddress][tokenId] > block.timestamp, "Timeout for this sale");
      require(payableOption[nftAddress][tokenId]!=address(0), "payable address not set or Invalid");
      require(fixedPrice[nftAddress][tokenId]!=0, "Price Not Set");
      
      // Nft Validations
      IERC721 nftInstance = IERC721(nftAddress);
      address owner = nftInstance.ownerOf(tokenId);
      require(nftInstance.getApproved(tokenId)==address(this), "Nft Not Approved By the owner");
      
      //  Payable Validations
      IERC20 payableInstance = IERC20(payableOption[nftAddress][tokenId]);
      uint256 price = fixedPrice[nftAddress][tokenId];
      if(address(payableInstance) == WETH){
        require(msg.value >= price, "Value must higher or equal to the price.");
        payable(owner).transfer(msg.value);
      }
      else {
        require(payableInstance.allowance(msg.sender, address(this)) >= price, "Payable is not allowed by buyer");

        payableInstance.transferFrom(msg.sender, owner, price);
      }
      nftInstance.transferFrom(owner, to, tokenId);

      delete payableOption[nftAddress][tokenId];
      delete fixedPrice[nftAddress][tokenId];
      delete saleTime[nftAddress][tokenId];

      emit NftSold(price, owner, to, nftAddress, tokenId);
    }

    function putOnAuction(address nftAddress, uint256 tokenId, address payableAddress, uint256 auctionTimestamp) public {
      require(auctionTimestamp > block.timestamp, "Time should be greater then current time");
      IERC721 nftInstance = IERC721(nftAddress);
      require(nftInstance.ownerOf(tokenId)==address(tx.origin), "sender is not the owner of this token Id");
      require(nftInstance.getApproved(tokenId)==address(this), "Nft not allowed by the owner");
      payableOption[nftAddress][tokenId] = payableAddress;
      saleTime[nftAddress][tokenId] = auctionTimestamp;

      emit AuctionStarted(nftAddress, tokenId, payableAddress, auctionTimestamp);
    }

    function cancelSale(address nftAddress, uint256 tokenId) public {
      IERC721 nftInstance = IERC721(nftAddress);
      require(address(nftInstance.ownerOf(tokenId)) == address(msg.sender), "You are not the owner of the nft.");
      delete payableOption[nftAddress][tokenId];
      delete fixedPrice[nftAddress][tokenId];
      delete saleTime[nftAddress][tokenId];
    }

    function putOnFixedPriceSale(address nftAddress, uint256 tokenId, address payableAddress, uint256 auctionTimestamp, uint256 price) public {
      require(auctionTimestamp > block.timestamp, "Time should be greater then current time");
      IERC721 nftInstance = IERC721(nftAddress);
      require(nftInstance.ownerOf(tokenId)==address(tx.origin), "sender is not the owner of this token Id");
      require(nftInstance.getApproved(tokenId)==address(this), "Nft not allowed by the owner");
      payableOption[nftAddress][tokenId] = payableAddress;
      saleTime[nftAddress][tokenId] = auctionTimestamp;
      fixedPrice[nftAddress][tokenId] = price;

      emit FixedPriceStarted(nftAddress, tokenId, payableAddress, auctionTimestamp, price);
    }
}