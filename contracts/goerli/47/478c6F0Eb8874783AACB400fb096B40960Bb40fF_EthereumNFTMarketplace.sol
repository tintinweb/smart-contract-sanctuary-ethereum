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

// SPDX-License-Identifier: MTI
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";


contract EthereumNFTMarketplace is ReentrancyGuard {
    address private nftvaultaddress;
    AggregatorV3Interface internal priceFeed;
    uint256  marketitemscount;
    uint256  solditems;
    address payable  withdrawfeesaccount; //owner to withdraw fees
    uint256  marketfeespercentage;
    mapping (address => uint256 []) mypurchasednft;

    struct nftmarketitem{
        uint256 itemid;
        address nftcontractaddress;
        uint256 tokenid;
        address payable seller;
        address payable holder;
        uint256 price;
        uint256 issold; // 1 or 0
        uint256 islisted; // 1 or 0 
        uint256 istransferred; // 1 or 0 
    }
    mapping (uint256 => nftmarketitem) NFTMarketItems;


    constructor (uint256 _feespercentage, address _nftvaultaddress) {
        marketfeespercentage = _feespercentage;
        withdrawfeesaccount = payable(msg.sender);
        priceFeed = AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);
        nftvaultaddress = _nftvaultaddress;

    }
     function getLatestPriceOfMaticVsUSD() public view returns (int) {
        (
            ,
            /*uint80 roundID*/ int price /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/,
            ,
            ,

        ) = priceFeed.latestRoundData();
        return price;
    }

    // list function (sell nft) 
    function listnft (address nftcontractaddress, uint256 tokenid, uint256 price) external nonReentrant {
        require(price > 0 , "price should greater than 0");
        marketitemscount ++;
      
        nftmarketitem memory newnftmarketitem = nftmarketitem (marketitemscount,nftcontractaddress,tokenid,payable(msg.sender),payable(address(0)),price,0,1,0);
        NFTMarketItems[marketitemscount] = newnftmarketitem;
        for (uint256 i = 0; i < marketitemscount; i++) {
            if (NFTMarketItems[i].tokenid == tokenid) {
                
                NFTMarketItems[i].islisted = 1;

            }
        }
        IERC721(nftcontractaddress).transferFrom(msg.sender, address(this), tokenid);
    
    } 

       //Function to apply market fees (1%)
    function totalpricewith_marketfees (uint256 marketitemid) public view returns (uint256) {
        uint256 totalprice= NFTMarketItems[marketitemid].price ;
        uint256 totalpricewithfees = totalprice* (100+marketfeespercentage);
        return totalpricewithfees/100;
    }
    // Buy NFT function

    function buynft (uint256 marketitemid) external payable nonReentrant {
        require (marketitemid >0 && marketitemid<= marketitemscount , "invalid market item id");
        uint256 priceofnft = NFTMarketItems[marketitemid].price;
        address nftcontractaddress = NFTMarketItems[marketitemid].nftcontractaddress;
         uint256 nfttokenid = NFTMarketItems[marketitemid].tokenid;

        uint256 nfttotalprice = totalpricewith_marketfees(marketitemid);


        require (msg.value == nfttotalprice , "Pay what seller requires");
        NFTMarketItems[marketitemid].seller.transfer(priceofnft);
        IERC721(nftcontractaddress).transferFrom( address(this) ,msg.sender, nfttokenid);
        withdrawfeesaccount.transfer(nfttotalprice - priceofnft);

         NFTMarketItems[marketitemid].holder = payable(msg.sender);
         NFTMarketItems[marketitemid].issold = 1;
         NFTMarketItems[marketitemid].islisted = 0;
         solditems++;

    }

    function getmypurchasednfts () public view returns (nftmarketitem [] memory){
        uint totalitemscount = marketitemscount;
        uint myitemcount = 0;
        uint currentindex = 0;
        for (uint i = 0; i < totalitemscount; i++) {
            if (NFTMarketItems[i + 1].holder  == msg.sender) {
                myitemcount += 1;
            }
        }

        nftmarketitem[] memory mynftitems = new nftmarketitem[](myitemcount);
        for (uint256 i = 0 ; i<marketitemscount;i++){
            if(NFTMarketItems[i+1].holder == msg.sender){
                uint256 currentId  = i+1;
                nftmarketitem storage currentItem = NFTMarketItems[currentId];
                mynftitems[currentindex] = currentItem;
                currentindex += 1;

            }
        }
        return mynftitems;
    }


    function getnotsoldnfts() public view returns (nftmarketitem[] memory) {
        uint itemCount = marketitemscount;
        uint unsolditemscount = marketitemscount- solditems;
        uint currentIndex = 0;

        nftmarketitem[] memory notsolditems = new nftmarketitem[](unsolditemscount);
        for (uint256 i = 0; i < itemCount; i++) {
            if (NFTMarketItems[i + 1].holder == address(0)) {
                uint currentId = i + 1;
                nftmarketitem storage currentItem = NFTMarketItems[currentId];
                notsolditems[currentIndex] = currentItem;
                currentIndex += 1;
      }
    }
    return notsolditems;
  }

    
      // For NFT Bridge 

  function transfernfts (uint256 _tokenid) public {
    uint itemCount = marketitemscount;
    for (uint256 i = 0; i < itemCount; i++) {
        if (NFTMarketItems[i].holder == msg.sender) {
            IERC721(NFTMarketItems[i].nftcontractaddress).transferFrom( msg.sender,nftvaultaddress, _tokenid);
            NFTMarketItems[i].istransferred = 1;

        }
    }
  }

}