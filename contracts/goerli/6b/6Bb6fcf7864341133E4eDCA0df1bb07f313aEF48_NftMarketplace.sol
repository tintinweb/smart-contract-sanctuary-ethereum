// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

error NftMarketPlace__PriceMustBeAboveZero();
error NftMarketPlace__NotApprovedForMarketplace();
error NftMarketPlace__AlreadyListed(address nftAddress, uint256 tokenId);
error NftMarketPlace__NotOwner();
error NftMarketPlace__NotListed(address nftAddress, uint256 tokenId);
error NftMarketPlace__PriceNotMet(address nftAddress, uint256 tokenId, uint256 price);
error NftMarketPlace__NoProceeds();
error NftMarketPlace__TransferFailed();

contract NftMarketplace is ReentrancyGuard {
  //這個struct物件用於mapping
  struct Listing {
    uint256 price;
    address seller;
  }

  //此event會在NFT上架後觸發,列出以下資訊
  event ItemListed(
    address indexed seller,
    address indexed nftAddress,
    uint256 indexed tokenId,
    uint256 price
  );

  //此event會在上架的NFT被購買之後觸發
  event ItemBought(
    address indexed buyer,
    address indexed nftAddress,
    uint256 indexed tokenId,
    uint256 price
  );

  //此event會在已上架的NFT被取消之後觸發
  event ItemCanceled(address indexed seller, address indexed nftAddress, uint256 indexed tokenId);

  //    nft地址      合約中的tokenId   (賣家,賣多少錢)
  mapping(address => mapping(uint256 => Listing)) private s_listings;
  //這個mapping用於,當上架的NFT被買家買走之後, 賣家會獲得多少錢
  //      賣家地址    賺多少錢
  mapping(address => uint256) private s_proceeds;

  //建立一個modifier,用於檢查NFT是否已經上架過了
  modifier notListed(
    address nftAddress,
    uint256 tokenId,
    address owner
  ) {
    //這是一個struct物件listing,是由mapping組成,若此物件mapping中的price價格大於0,意味著此NFT已經上架過了
    Listing memory listing = s_listings[nftAddress][tokenId];
    if (listing.price > 0) {
      revert NftMarketPlace__AlreadyListed(nftAddress, tokenId);
    }
    _;
  }

  //此modifier用於檢查,當用戶購買NFT時,該NFT是已經上架的狀態(價格必須大於0)
  modifier isListed(address nftAddress, uint256 tokenId) {
    Listing memory listing = s_listings[nftAddress][tokenId];
    if (listing.price <= 0) {
      revert NftMarketPlace__NotListed(nftAddress, tokenId);
    }
    _;
  }

  //此modifier用於檢查該用戶是否為NFT的擁有者
  modifier isOwner(
    address nftAddress,
    uint256 tokenId,
    address spender
  ) {
    //使用ERC721合約的interface,因為要用其中的ownerOf function,來檢查NFT的擁有者
    IERC721 nft = IERC721(nftAddress);
    //傳入tokenId,列出該NFT的擁有者
    address owner = nft.ownerOf(tokenId);
    //若該用戶不是NFT的所有者,則revert
    if (spender != owner) {
      revert NftMarketPlace__NotOwner();
    }
    _;
  }

  //前端 => 上傳圖檔(得到IPFS) 設定金額
  //從前端呼叫,輸入tokenUri並鑄造NFT,紀錄tokenId跟錢包地址的對應
  function listItem(
    address nftAddress,
    uint256 tokenId,
    uint256 price // notListed(nftAddress, _tokenId, msg.sender)
  )
    external
    notListed(nftAddress, tokenId, msg.sender)
    isOwner(nftAddress, tokenId, msg.sender)
  // isOwner(nftAddress, _tokenId, msg.sender) 想一下有沒有必要加入, tokenId是內部抓取,如果沒有鑄造則0
  // 也沒辦法亂塞已有的tokenId,不是owner?,呼叫此function就會成為owner鑄造NFT
  // tokenUri亂塞,就等於沒有圖片,或是奇怪的ipfs hash
  // nftAddress 亂給的話授權該NFTapprove,設定價格
  {
    //price必須大於0
    if (price <= 0) {
      revert NftMarketPlace__PriceMustBeAboveZero();
    }
    //因為要使用ERC721的getApproved function,所以使用interface+合約地址
    IERC721 nft = IERC721(nftAddress);

    //若該NFT沒有授權給此marketplace,則revert
    if (nft.getApproved(tokenId) != address(this)) {
      revert NftMarketPlace__NotApprovedForMarketplace();
    }

    //當使用者上架要販售的NFT時,資訊會寫在mapping內,例如: s_listings[0xaa123][77] = Listing(0.1,kira);
    s_listings[nftAddress][tokenId] = Listing(price, msg.sender);
    //由於被買走 或是下架了 此Listing的mapping會解除
    //如果要列出特定買家賣了哪些NFT則用外部DB做,紀錄價格 賣家和 tokenId 就可以filter
    emit ItemListed(msg.sender, nftAddress, tokenId, price);
  }

  //此function用在用戶購買NFT,
  //modifier用於檢查該NFT是已經上架的狀態才可以購買
  function buyItem(
    address nftAddress,
    uint256 tokenId
  ) external payable nonReentrant isListed(nftAddress, tokenId) {
    //先抓取準備要購買的NFT的mapping資訊
    Listing memory listedItem = s_listings[nftAddress][tokenId];
    //如果用戶付的錢小於該上架的NFT售價,則revert,因為錢不夠不能買
    if (msg.value < listedItem.price) {
      revert NftMarketPlace__PriceNotMet(nftAddress, tokenId, listedItem.price);
    }
    //當上架的NFT被購買時,使用mapping紀錄賣家會獲得多少錢
    s_proceeds[listedItem.seller] += msg.value;
    //因為上架的NFT已經被買走了,所以要刪除mapping,去掉原有的seller和price,這時候如果在呼叫listItem function就不會看到此NFT,因為沒有價格
    delete (s_listings[nftAddress][tokenId]);
    //使用ERC721 interface,將該NFT轉移,        from,        to       ,  tokenId
    IERC721(nftAddress).safeTransferFrom(listedItem.seller, msg.sender, tokenId);
    emit ItemBought(msg.sender, nftAddress, tokenId, listedItem.price);
  }

  //此function的用意是,將賣家上架的NFT取消,觸發此function的人必須是該NFT的擁有者,且該NFT是處於上架的狀態
  function cancelListing(
    address nftAddress,
    uint256 tokenId
  ) external isOwner(nftAddress, tokenId, msg.sender) isListed(nftAddress, tokenId) {
    //使用delete去掉mapping,就不會有seller和price,這時候如果在呼叫listItem function就不會看到此NFT,因為沒有價格
    delete (s_listings[nftAddress][tokenId]);
    emit ItemCanceled(msg.sender, nftAddress, tokenId);
  }

  //此function的用意是,賣家上架NFT之後,需要更新價格時,呼叫此function,賣家必須是NFT的擁有者,且該NFT已上架
  function updateListing(
    address nftAddress,
    uint256 tokenId,
    uint256 newPrice
  ) external isOwner(nftAddress, tokenId, msg.sender) isListed(nftAddress, tokenId) {
    s_listings[nftAddress][tokenId].price = newPrice;
    //直接觸發ItemListed即可,因為更新價格後也算是上架
    emit ItemListed(msg.sender, nftAddress, tokenId, newPrice);
  }

  //此function的用意是,當賣家上架的NFT賣出之後,賣家可以呼叫此function領錢
  function withdrawProceeds() external nonReentrant {
    //若賣家上架的NFT已被購買,則在buyItem的function內,會更新賣家能夠獲得多少錢
    uint256 proceeds = s_proceeds[msg.sender];
    if (proceeds <= 0) {
      revert NftMarketPlace__NoProceeds();
    }
    //要領錢之前,先將proceeds歸0避免重入攻擊
    s_proceeds[msg.sender] = 0;
    (bool success, ) = payable(msg.sender).call{value: proceeds}("");
    if (!success) {
      revert NftMarketPlace__TransferFailed();
    }
  }

  //列出目前已上架的NFT,因為有mapping的價格,代表已上架
  function getListing(
    address sellerAddress,
    uint256 tokenId
  ) external view returns (Listing memory) {
    return s_listings[sellerAddress][tokenId];
  }

  //列出已賣出NFT的賣家目前能夠領多少錢
  function getProceeds(address seller) external view returns (uint256) {
    return s_proceeds[seller];
  }
}