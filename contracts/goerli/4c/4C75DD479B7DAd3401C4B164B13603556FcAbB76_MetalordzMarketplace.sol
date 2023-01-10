// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract MetalordzMarketplace is ReentrancyGuard, Ownable {
    using SafeMath for uint256;

    mapping(address => bool) public allowedContracts;
    IERC20 public token;
    uint256 public fee; //in bips
    address public feeWallet;

    uint256 private listingIndex;

    struct listing {
        uint256 tokenId;
        IERC721 nftContract;
        address listerAddress;
        uint256 price;
        uint256 validTill;
        uint256 status; // 0 -active, 1 - completed, 2 - revoked
    }

    // listingId => struct
    mapping(uint256 => listing) public listingDetails;

    uint256 private bidIndex;

    struct bid {
        uint256 tokenId;
        IERC721 nftContract;
        address bidderAddress;
        uint256 offerPrice;
        uint256 validTill;
        uint256 status; // 0 - active, 1 - accepted, 2 - revoked
    }

    // bidId => bidDetails
    mapping(uint256 => bid) public bidDetails;

    uint256 private bundleIndex;

    struct bundleListing {
        uint256[] tokenId;
        IERC721[] nftContract;
        address listerAddress;
        uint256 price;
        uint256 validTill;
        uint256 status; // 0 -active, 1 - completed, 2 - revoked
    }

    // bundleId => struct
    mapping(uint256 => bundleListing) private bundleListingDetails;

    struct bidOnBundle {
        uint256 bundleId;
        address bidderAddress;
        uint256 offerPrice;
        uint256 validTill;
        uint256 status; // 0 - active, 1 - accepted, 2 - revoked
    }

    // bundleId => bid(s) on listing
    mapping(uint256 => bidOnBundle[]) private bidOnBundleDetails;

    struct bundle {
        uint256 tokenId;
        address nftContractAddress;
    }

    // EVENTS // ------------------------------------ //

    event listedForSale(uint256 listingId, uint256 tokenId, IERC721 tokenContract, address listerAddress, uint256 price, uint256 validTill);
    event listingPriceUpdated(uint256 listingId, uint256 price);
    event listingDurationUpdated(uint256 listingId, uint256 validTill);
    event listingRevoked(uint256 listingId);
    event offerMade(uint256 bidId, uint256 tokenId, IERC721 tokenContract, address listerAddress, uint256 price, uint256 validTill);
    event bidRevoked(uint256 bidId);
    event bundleListedForSale(uint256 bundleId, address listerAddress, uint256 price, uint256 validTill);
    event bundlePriceUpdated(uint256 bundleId, uint256 price);
    event bundleDurationUpdated(uint256 bundleId, uint256 validTill);
    event bundleRevoked(uint256 bundleId);
    event offerMadeForBundle(uint256 bundleId, uint256 offerIndex, address bidderAddress, uint256 price, uint256 validTill);
    event bidRevokedForBundle(uint256 bundleId, uint256 offerIndex);
    event sold(IERC721 tokenContract, uint256 tokenId, address from, address to, uint256 price);

    receive() external payable {}

    // ADMIN FUNCTIONS // ------------------------------------ //

    function addNFTContract(address _contractAddress) external onlyOwner {
        allowedContracts[_contractAddress] = true;
    }

    function setPaymentToken(address _contractAddress) external onlyOwner {
        token = IERC20(_contractAddress);
    }

    function setFee(uint256 _fee) external onlyOwner {
        fee = _fee;
    }

    function setFeeWallet(address _walletAddress) external onlyOwner {
        feeWallet = _walletAddress;
    }

    function withdrawFunds() external onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, "Insufficient funds to withdraw");
        require(feeWallet != address(0), "Fee Wallet not set");

        token.transfer(feeWallet, balance);
    }

    // SELLER FUNCTIONS // ------------------------------------ //

    // requires approval as a pre-condition
    function createListing(uint256 _tokenId, address _nftContractAddress, uint256 _price, uint256 _duration) external {
        require(allowedContracts[_nftContractAddress] == true, "Not an allowed contract");
        IERC721 nftContract = IERC721(_nftContractAddress);
        require(nftContract.ownerOf(_tokenId) == msg.sender, "user not owner of token Id");
        require(nftContract.isApprovedForAll(msg.sender, address(this)),"Allowance to transfer NFT not provided");
        uint256 validTill = block.timestamp.add(_duration);
        listingDetails[listingIndex].tokenId = _tokenId;
        listingDetails[listingIndex].nftContract = nftContract;
        listingDetails[listingIndex].listerAddress = msg.sender;
        listingDetails[listingIndex].price = _price;
        listingDetails[listingIndex].validTill = validTill;

        emit listedForSale(listingIndex, _tokenId, nftContract, msg.sender, _price, validTill);
        listingIndex+=1;
    }

    function updateListingPrice(uint256 _listingId, uint256 _price) external {
        require(isValidListing(_listingId), "Invalid listing");
        require(listingDetails[_listingId].listerAddress == msg.sender, "Caller did not create this listing");
        require(listingDetails[_listingId].nftContract.ownerOf(listingDetails[_listingId].tokenId) == msg.sender, "Caller not owner of token Id");

        listingDetails[listingIndex].price = _price;     
        emit listingPriceUpdated(_listingId, _price);   
    }

    function extendListing(uint256 _listingId, uint256 _duration) external {
        require(isValidListing(_listingId), "Invalid listing");
        require(listingDetails[_listingId].listerAddress == msg.sender, "Caller did not create this listing");
        require(IERC721(listingDetails[_listingId].nftContract).ownerOf(listingDetails[_listingId].tokenId) == msg.sender, "user not owner of token Id");

        uint256 validTill = block.timestamp.add(_duration);
        listingDetails[_listingId].validTill = validTill;
        emit listingDurationUpdated(_listingId, validTill);
    }

    function revokeListing(uint256 _listingId) external {
        require(isValidListing(_listingId), "Invalid listing");
        require(listingDetails[_listingId].listerAddress == msg.sender, "Caller did not create this listing");
        require(IERC721(listingDetails[_listingId].nftContract).ownerOf(listingDetails[_listingId].tokenId) == msg.sender, "user not owner of token Id");

        listingDetails[_listingId].status = 2;
        emit listingRevoked(_listingId);
    }

    function acceptOffer(uint256 _bidId) external nonReentrant {
        require(isValidBid(_bidId), "Invalid bid");
        uint256 price = bidDetails[_bidId].offerPrice;
        address bidderAddress = bidDetails[_bidId].bidderAddress;
        uint256 allowance = token.allowance(bidderAddress, address(this));
        require(allowance > price, "Insufficient allowance");
        require(token.balanceOf(bidderAddress) > price, "Insufficient balance");
        IERC721 nftContract = bidDetails[_bidId].nftContract;
        uint256 tokenId = bidDetails[_bidId].tokenId;
        require(nftContract.ownerOf(tokenId) == msg.sender,"Caller is not the owner of NFT");
        require(nftContract.isApprovedForAll(msg.sender, address(this)),"Allowance to transfer NFT not provided");
        uint256 applicableFee = price.mul(fee).div(10000);
        bidDetails[_bidId].status = 1;
        token.transferFrom(bidderAddress, msg.sender, price.sub(applicableFee));
        token.transferFrom(bidderAddress, address(this), applicableFee);
        nftContract.safeTransferFrom(msg.sender, bidderAddress, tokenId);

        emit sold(nftContract, tokenId, msg.sender, bidderAddress, price);

    }


    // requires approval as a pre-condition
    function createBundleListing(bundle[] memory _bundle, uint256 _price, uint256 _duration) external {
        for( uint i=0; i< _bundle.length; i++) {
            IERC721 nftContract = IERC721(_bundle[i].nftContractAddress);
            uint256 tokenId = _bundle[i].tokenId;
            require(allowedContracts[_bundle[i].nftContractAddress] == true, "Not an allowed contract");
            require(nftContract.ownerOf(tokenId) == msg.sender, "user not owner of token Id");
            require(nftContract.isApprovedForAll(msg.sender, address(this)),"Allowance to transfer NFT not provided");

            bundleListingDetails[bundleIndex].tokenId.push() = tokenId;
            bundleListingDetails[bundleIndex].nftContract.push() = nftContract;
        }
                
        uint256 validTill = block.timestamp.add(_duration);       
        bundleListingDetails[bundleIndex].listerAddress = msg.sender;
        bundleListingDetails[bundleIndex].price = _price;
        bundleListingDetails[bundleIndex].validTill = validTill;

        emit bundleListedForSale(bundleIndex, msg.sender, _price, validTill);
        bundleIndex+=1;
    }

    function updateBundlePrice(uint256 _bundleId, uint256 _price) external {
        require(isValidBundle(_bundleId), "Invalid bundle");
        require(bundleListingDetails[_bundleId].listerAddress == msg.sender, "Caller did not create this bundle");

        bundleListingDetails[_bundleId].price = _price;     
        emit bundlePriceUpdated(_bundleId, _price);   
    }

    function extendBundle(uint256 _bundleId, uint256 _duration) external {
        require(isValidBundle(_bundleId), "Invalid bundle");
        require(bundleListingDetails[_bundleId].listerAddress == msg.sender, "Caller did not create this bundle");

        uint256 validTill = bundleListingDetails[_bundleId].validTill.add(_duration);
        bundleListingDetails[_bundleId].validTill = validTill;
        emit bundleDurationUpdated(_bundleId, validTill);
    }

    function revokeBundle(uint256 _bundleId) external {
        require(isValidBundle(_bundleId), "Invalid bundle");
        require(bundleListingDetails[_bundleId].listerAddress == msg.sender, "Caller did not create this bundle");

        bundleListingDetails[_bundleId].status = 2;
        emit bundleRevoked(_bundleId);
    }

    function acceptOfferForBundle(uint256 _bundleId, uint256 offerIndex) external nonReentrant {
        require(isValidBundle(_bundleId), "Invalid bundle");
        require(bundleListingDetails[_bundleId].listerAddress == msg.sender, "Caller did not create this bundle");

        require(isValidBidForBundle(_bundleId, offerIndex), "Invalid bid");

        uint256 price = bidOnBundleDetails[_bundleId][offerIndex].offerPrice;
        address bidderAddress = bidOnBundleDetails[_bundleId][offerIndex].bidderAddress;
        uint256 allowance = token.allowance(bidderAddress, address(this));
        require(allowance > price, "Insufficient allowance");
        require(token.balanceOf(bidderAddress) > price, "Insufficient balance");

        bidOnBundleDetails[_bundleId][offerIndex].status = 1;
        bundleListingDetails[_bundleId].status = 1;
        uint256 applicableFee = price.mul(fee).div(10000);
        token.transferFrom(bidderAddress, msg.sender, price.sub(applicableFee));
        token.transferFrom(bidderAddress, address(this), applicableFee);

        for (uint i=0; i< bundleListingDetails[_bundleId].tokenId.length; i++) {
            IERC721 nftContract = bundleListingDetails[_bundleId].nftContract[i];
            uint256 tokenId = bundleListingDetails[_bundleId].tokenId[i];
            require(nftContract.isApprovedForAll(msg.sender, address(this)),"Allowance to transfer NFT revoked by lister");
            require(nftContract.ownerOf(tokenId) == msg.sender,"Lister is not the owner of NFT anymore");

            nftContract.safeTransferFrom(msg.sender, bidderAddress, tokenId);
            emit sold(nftContract, tokenId, msg.sender, bidderAddress, 0); // price passed as 0 becuase sold as part of a bundle
        }
        
    }

    // BUYER FUNCTIONS // ------------------------------------ //

    // requires approving this contract's address as operator on token contract for 'sufficient' amount as a pre-condition
    function buy(uint256 _listingId) external nonReentrant {
        require(isValidListing(_listingId), "Invalid listing");
        address listerAddress = listingDetails[_listingId].listerAddress;
        IERC721 nftContract = listingDetails[_listingId].nftContract;
        uint256 tokenId = listingDetails[_listingId].tokenId;
        require(nftContract.isApprovedForAll(listerAddress, address(this)),"Allowance to transfer NFT revoked by lister");
        require(nftContract.ownerOf(tokenId) == listerAddress,"Lister is not the owner of NFT anymore");
        uint256 price = listingDetails[_listingId].price;
        uint256 allowance = token.allowance(msg.sender, address(this));
        require(allowance > price, "Insufficient allowance");
        require(token.balanceOf(msg.sender) > price, "Insufficient balance");
        uint256 applicableFee = price.mul(fee).div(10000);
        listingDetails[_listingId].status = 1;
        token.transferFrom(msg.sender, listerAddress, price.sub(applicableFee));
        token.transferFrom(msg.sender, address(this), applicableFee);
        nftContract.safeTransferFrom(listerAddress, msg.sender, tokenId);

        emit sold(nftContract, tokenId, listerAddress, msg.sender, price);
    }

    // requires approving this contract's address as operator on token contract for 'sufficient' amount as a pre-condition
    function makeOffer(uint256 _tokenId, address _nftContractAddress, uint256 _price, uint256 _duration) external {
        require(allowedContracts[_nftContractAddress] == true, "Not an allowed contract");
        uint256 allowance = token.allowance(msg.sender, address(this));
        require(allowance > _price, "Insufficient allowance");
        require(token.balanceOf(msg.sender) > _price, "Insufficient balance");
        uint256 validTill = block.timestamp.add(_duration);
        IERC721 nftContract = IERC721(_nftContractAddress);
        bidDetails[bidIndex].tokenId = _tokenId;
        bidDetails[bidIndex].nftContract = nftContract;
        bidDetails[bidIndex].bidderAddress = msg.sender;
        bidDetails[bidIndex].offerPrice = _price;
        bidDetails[bidIndex].validTill = validTill;

        emit offerMade(bidIndex, _tokenId, nftContract, msg.sender, _price, validTill);
        bidIndex+=1;
    }    

    function revokeOffer(uint256 _bidId) external {
        require(_bidId < bidIndex, "Invalid bid id");
        require(bidDetails[_bidId].status == 0 && bidDetails[_bidId].validTill > block.timestamp, "Inactive bid");
        require(bidDetails[_bidId].bidderAddress == msg.sender, "Caller did not create this bid");

        bidDetails[_bidId].status = 2;
        emit bidRevoked(_bidId);
    }

    // requires approving this contract's address as operator on token contract for 'sufficient' amount as a pre-condition
    function buyBundle(uint256 _bundleId) external nonReentrant {
        require(isValidBundle(_bundleId), "Invalid bundle");
        address listerAddress = bundleListingDetails[_bundleId].listerAddress;

        uint256 price = bundleListingDetails[_bundleId].price;
        uint256 allowance = token.allowance(msg.sender, address(this));
        require(allowance > price, "Insufficient allowance");
        require(token.balanceOf(msg.sender) > price, "Insufficient balance");
        uint256 applicableFee = price.mul(fee).div(10000);
        bundleListingDetails[_bundleId].status = 1;
        token.transferFrom(msg.sender, listerAddress, price.sub(applicableFee));
        token.transferFrom(msg.sender, address(this), applicableFee);

        for (uint i=0; i< bundleListingDetails[_bundleId].tokenId.length; i++) {
            IERC721 nftContract = bundleListingDetails[_bundleId].nftContract[i];
            uint256 tokenId = bundleListingDetails[_bundleId].tokenId[i];
            require(nftContract.isApprovedForAll(listerAddress, address(this)),"Allowance to transfer NFT revoked by lister");
            require(nftContract.ownerOf(tokenId) == listerAddress,"Lister is not the owner of NFT anymore");

            nftContract.safeTransferFrom(listerAddress, msg.sender, tokenId);
            emit sold(nftContract, tokenId, listerAddress, msg.sender, 0); // price passed as 0 because sold as part of a bundle
        } 
    
    }

    function makeOfferForBundle(uint256 _bundleId, uint256 _price, uint256 _duration) external {
        require(isValidBundle(_bundleId), "Invalid bundle");
        uint256 allowance = token.allowance(msg.sender, address(this));
        require(allowance > _price, "Insufficient allowance");
        require(token.balanceOf(msg.sender) > _price, "Insufficient balance");
        uint256 validTill = block.timestamp.add(_duration);
        bidOnBundle memory newBidOnBundle;

        newBidOnBundle.bundleId = _bundleId;
        newBidOnBundle.bidderAddress = msg.sender;
        newBidOnBundle.offerPrice = _price;
        newBidOnBundle.validTill = validTill;
        uint256 offerIndex = bidOnBundleDetails[_bundleId].length;
        bidOnBundleDetails[_bundleId].push() = newBidOnBundle;

        emit offerMadeForBundle(_bundleId, offerIndex, msg.sender, _price, validTill);
    }    

    function revokeOfferForBundle(uint256 _bundleId, uint256 offerIndex) external {
        require(isValidBundle(_bundleId), "Invalid bundle");
        require(isValidBidForBundle(_bundleId, offerIndex), "Invalid bid");
        require(bidOnBundleDetails[_bundleId][offerIndex].bidderAddress == msg.sender, "Bid not made by the caller");

        bidOnBundleDetails[_bundleId][offerIndex].status = 2;
        emit bidRevokedForBundle(_bundleId, offerIndex);
    }

    // READ FUNCTIONS // ------------------------------------ //

    function getAllBidsOnBundle(uint256 _bundleId) public view returns(bidOnBundle[] memory bidsOnBundle) {
        uint length = bidOnBundleDetails[_bundleId].length;
        bidOnBundle[] memory _bidsOnBundle = new bidOnBundle[](length);

        for (uint i=0; i<length; i++) {
            _bidsOnBundle[i].bundleId = bidOnBundleDetails[_bundleId][i].bundleId;
            _bidsOnBundle[i].bidderAddress = bidOnBundleDetails[_bundleId][i].bidderAddress;
            _bidsOnBundle[i].offerPrice = bidOnBundleDetails[_bundleId][i].offerPrice;
            _bidsOnBundle[i].validTill = bidOnBundleDetails[_bundleId][i].validTill;
            _bidsOnBundle[i].status = bidOnBundleDetails[_bundleId][i].status;

        }

        return _bidsOnBundle;

    }

    function getBundleDetails(uint256 _bundleId) public view returns(bundle[] memory tokens, address listerAddress, uint256 price, uint256 validTill, uint256 status) {
        uint length = bundleListingDetails[_bundleId].tokenId.length;
        bundle[] memory _tokens = new bundle[](length);

        for (uint i=0; i< length; i++) {
            _tokens[i].tokenId = bundleListingDetails[_bundleId].tokenId[i];
            _tokens[i].nftContractAddress = address(bundleListingDetails[_bundleId].nftContract[i]);
        }

        return(_tokens, bundleListingDetails[_bundleId].listerAddress, bundleListingDetails[_bundleId].price, bundleListingDetails[_bundleId].validTill, bundleListingDetails[_bundleId].status);
               
    }

    // INTERNAL FUNCTIONS //------------------------------------------------/

    function isValidListing(uint256 _listingId) internal view returns(bool) {
        if(_listingId < listingIndex && listingDetails[_listingId].status == 0 && listingDetails[_listingId].validTill > block.timestamp) return true; else return false;
    }

    function isValidBundle(uint256 _bundleId) internal view returns(bool) {
        if(_bundleId < bundleIndex && bundleListingDetails[_bundleId].status == 0 && bundleListingDetails[_bundleId].validTill > block.timestamp) return true; else return false;
    }

    function isValidBid(uint256 _bidId) internal view returns(bool) {
        if(_bidId < bidIndex && bidDetails[_bidId].status == 0 && bidDetails[_bidId].validTill > block.timestamp) return true; else return false;
    }

    function isValidBidForBundle(uint256 _bundleId, uint256 offerIndex) internal view returns(bool) {
        if(bidOnBundleDetails[_bundleId][offerIndex].bundleId == _bundleId && bidOnBundleDetails[_bundleId][offerIndex].status == 0 && bidOnBundleDetails[_bundleId][offerIndex].validTill > block.timestamp) return true; else return false;
    } 

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
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