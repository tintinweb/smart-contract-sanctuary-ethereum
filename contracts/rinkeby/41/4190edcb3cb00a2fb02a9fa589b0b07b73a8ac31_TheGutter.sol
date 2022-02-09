/**
 *Submitted for verification at Etherscan.io on 2022-02-09
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;




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



/** 
 * @title TheGutter
 * @dev Marketplace contract for GutterPunk NFTs
 */
contract TheGutter is Ownable, IERC721Receiver  {
    
    event Withdrew(uint256 balance);
    event Purchased(uint16 tokenId, uint256 salePrice);
    event Listed(uint16 tokenId, uint256 listedPrice);
    event Delisted(uint16 tokenId);
    event Staked(uint16 tokenId);
    event Unstaked(uint16 tokenId);
    event StakingPayout(address payoutAddress, uint256 payoutAmount);
   
    address _contAddress = 0xf3303f102E2f1de5A8Bf2d582f9328884d38A750; 
    address[10000] listedBy;
    address[10000] stakedPunk;
    uint256[10000] listedPrice;
    bool[10000] listingActive;
    bool public _marketplaceOpen = false; 
    bool public _marketplacePermanentlyClosed = false; 
    uint8 public _royaltyFee = 50;
    GutterPunks gp = GutterPunks(_contAddress);

    constructor() { }
    
    /** 
     * @dev Toggles if market is open or closed.
     */
    function toggleMarketOpen() external onlyOwner {
        require(!_marketplacePermanentlyClosed, "The Gutter is permanently closed.");
        require(_contAddress != address(0x0), "GutterPunk contract address must be set to open.");
        _marketplaceOpen = !_marketplaceOpen;
    }
    
    /** 
     * @dev Toggles if market is open or closed.
     */
    function permanentlyClose() external onlyOwner {
        require(!_marketplaceOpen, "The Gutter must be closed to shutdown permanently.");
        _marketplacePermanentlyClosed = true;
    }

    function list(uint16[] calldata tokenId, uint256[] calldata listingPrice) external { 
        require(_marketplaceOpen, "The Gutter is currently closed.");
        require(tokenId.length == listingPrice.length, "Array sizes do not match.");
        for(uint16 i = 0;i < listingPrice.length;i++) {
            require(listingPrice[i] > 0, "Listing price must be greater than zero eth.");
        }

        for(uint16 i = 0;i < tokenId.length;i++) {
            require(msg.sender == gp.ownerOf(tokenId[i]), "You must own the GutterPunk to list.");
            require(gp.getApproved(tokenId[i]) == address(this) || gp.isApprovedForAll(gp.ownerOf(tokenId[i]), address(this)), "The Gutter is not approved to access this GutterPunk");

            listingActive[tokenId[i]] = true;
            listedBy[tokenId[i]] = msg.sender;
            listedPrice[tokenId[i]] = listingPrice[i];
            emit Listed(tokenId[i], listingPrice[i]);
        }
    }

    function delist(uint16[] calldata tokenId) external { 
        for(uint16 i = 0;i < tokenId.length;i++) {
            require(msg.sender == gp.ownerOf(tokenId[i]) || listedBy[tokenId[i]] == msg.sender, "You must own the GutterPunk to delist.");
            listingActive[tokenId[i]] = false;
            listedBy[tokenId[i]] = address(0x0);
            listedPrice[tokenId[i]] = 0;
            emit Delisted(tokenId[i]);
        }
    }

    function delistAll() external { 
        for(uint16 i = 0;i < listingActive.length;i++) {
            if(listingActive[i] && (msg.sender == gp.ownerOf(i) || listedBy[i] == msg.sender)) {
                listingActive[i] = false;
                listedBy[i] = address(0x0);
                listedPrice[i] = 0;
                emit Delisted(i);
            }
        }
    }

    /** 
     * @dev function used to purchase token from a seller
     * @param tokenId id of token to be purchased
     */
    function purchase(uint16[] calldata tokenId) external payable {
        require(_marketplaceOpen, "The Gutter is currently closed.");

        uint256 totalPayment = 0;
        uint256 tmpPurchasePrice = 0;
        for(uint16 i = 0;i < tokenId.length;i++) {
            totalPayment += listedPrice[tokenId[i]];
            require(listingActive[tokenId[i]], "GutterPunk is not listed.");
            require(listedPrice[tokenId[i]] > 0, "Listing price must be greater than zero.");
        }
        require(totalPayment == msg.value, "Payment amount is incorrect.");

        
        for(uint16 i = 0;i < tokenId.length;i++) {
            payable(listedBy[tokenId[i]]).transfer((listedPrice[tokenId[i]] * (1000 - _royaltyFee)/1000));
            gp.safeTransferFrom(gp.ownerOf(tokenId[i]), msg.sender, tokenId[i]);      
            tmpPurchasePrice = listedPrice[tokenId[i]];

            listingActive[tokenId[i]] = false;
            listedBy[tokenId[i]] = address(0x0);
            listedPrice[tokenId[i]] = 0;

            emit Purchased(tokenId[i], tmpPurchasePrice);
        }
    }

    /** 
     * @dev function used to stake a Punk
     * @param tokenId id of token to be staked
     */
    function stake(uint16[] calldata tokenId) external  {        
        for(uint16 i = 0;i < tokenId.length;i++) {
            gp.safeTransferFrom(gp.ownerOf(tokenId[i]), address(this), tokenId[i]);

            listingActive[tokenId[i]] = false;
            listedBy[tokenId[i]] = address(0x0);
            listedPrice[tokenId[i]] = 0;
            stakedPunk[tokenId[i]] = msg.sender;

            emit Staked(tokenId[i]);
        }
    }

    /** 
     * @dev function used to unstake a Punk
     * @param tokenId id of token to be unstaked
     */
    function unstake(uint16[] calldata tokenId) external  {        
        for(uint16 i = 0;i < tokenId.length;i++) {
            require(stakedPunk[tokenId[i]] == msg.sender, "This is not your GutterPunk.");
            gp.safeTransferFrom(address(this), msg.sender, tokenId[i]);

            stakedPunk[tokenId[i]] = address(0x0);

            emit Unstaked(tokenId[i]);
        }
    }

    /**
     * @notice Query all active listings.
     * Returns array of tokenIds and listedPrice 
     */
    function getListedTokens() external view returns(uint16[] memory) {
        uint16 activeListings = 0;
        for(uint16 i = 0;i < listingActive.length;i++) {
            if(listingActive[i] && (gp.getApproved(i) == address(this) || gp.isApprovedForAll(gp.ownerOf(i), address(this))) && listedBy[i] == gp.ownerOf(i)) {
                activeListings++;
            }
        }
        uint16[] memory listedTokens = new uint16[](activeListings);
        uint16 currentListing = 0;
        for(uint16 i = 0;i < listingActive.length;i++) {
            if(listingActive[i] && (gp.getApproved(i) == address(this) || gp.isApprovedForAll(gp.ownerOf(i), address(this))) && listedBy[i] == gp.ownerOf(i)) {
                listedTokens[currentListing] = i;
                currentListing++;
            }
        }
        return listedTokens;
    }

    /**
     * @notice Query all staked punks.
     * Returns array of tokenIds and listedPrice 
     */
    function getStakedTokens() external view returns(uint16[] memory) {
        uint16 activeStakes = 0;
        for(uint16 i = 0;i < stakedPunk.length;i++) {
            if(stakedPunk[i] != address(0x0)) {
                activeStakes++;
            }
        }
        uint16[] memory stakedTokens = new uint16[](activeStakes);
        uint16 currentStake = 0;
        for(uint16 i = 0;i < stakedPunk.length;i++) {
            if(stakedPunk[i] != address(0x0)) {
                stakedTokens[currentStake] = i;
                currentStake++;
            }
        }
        return stakedTokens;
    }

    /**
     * @notice Query all staked punks.
     * Returns array of tokenIds and listedPrice 
     */
    function getStakedTokensByOwner(address ownerAddress) external view returns(uint16[] memory) {
        uint16 activeStakes = 0;
        for(uint16 i = 0;i < stakedPunk.length;i++) {
            if(stakedPunk[i] == ownerAddress) {
                activeStakes++;
            }
        }
        uint16[] memory stakedTokens = new uint16[](activeStakes);
        uint16 currentStake = 0;
        for(uint16 i = 0;i < stakedPunk.length;i++) {
            if(stakedPunk[i] == ownerAddress) {
                stakedTokens[currentStake] = i;
                currentStake++;
            }
        }
        return stakedTokens;
    }

    /**
     * @notice Query all staked punks.
     * Returns array of tokenIds and listedPrice 
     */
    function getStakingAddresses() external view returns(address[] memory) {
        address[] memory tmpStakers = new address[](stakedPunk.length);
        uint tmpCurrentAddressInd = 0;
        for(uint16 i = 0;i < stakedPunk.length;i++) {
            if(stakedPunk[i] == address(0x0)) continue;
            for(uint16 k = 0;k < tmpStakers.length;k++) {
                if(tmpStakers[k] == stakedPunk[i]) break;
                if(tmpStakers[k] == address(0x0)) {
                    tmpStakers[k] = stakedPunk[i];
                    tmpCurrentAddressInd++;
                    break;
                }
            }
        }
        address[] memory activeStakers = new address[](tmpCurrentAddressInd+1);
        for(uint16 i = 0;i < tmpCurrentAddressInd;i++) {
            activeStakers[i] = tmpStakers[i];
        }
        return activeStakers;
    }

    /**
     * @notice Query listed price for tokenId
     * Returns listed price for token. 
     */
    function getListedPrice(uint16 tokenId) external view returns(uint256) {
        require(listingActive[tokenId] && listedPrice[tokenId] > 0 && (gp.getApproved(tokenId) == address(this) || gp.isApprovedForAll(gp.ownerOf(tokenId), address(this))) && listedBy[tokenId] == gp.ownerOf(tokenId), "This Gutter Punk is not listed for sale.");
        return listedPrice[tokenId];
    }


    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        uint256 stakedShare = balance / 2;
        uint256 totalStakingPayout = 0;
        uint256 stakingPayoutPerPunk = 0;

        uint16 stakedCount = 0;
        for(uint16 i = 0;i < stakedPunk.length;i++) {
            if(stakedPunk[i] != address(0x0)) {
                stakedCount++; 
            }
        }

        stakingPayoutPerPunk = stakedShare / stakedCount;
        totalStakingPayout = stakingPayoutPerPunk * stakedCount;
        
        address[] memory activeStakers = this.getStakingAddresses();
        uint16[] memory tmpStakedPunks;
        for(uint16 i = 0;i < activeStakers.length;i++) {
            tmpStakedPunks = this.getStakedTokensByOwner(activeStakers[i]);
            payable(activeStakers[i]).transfer(stakingPayoutPerPunk * tmpStakedPunks.length);
        }

        
        uint256 royaltyShare = balance - totalStakingPayout;
        payable(msg.sender).transfer(royaltyShare);

        emit Withdrew(balance);
    }

    function onERC721Received(address operator, address from, 
        uint256 tokenId, bytes calldata data) public override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}


abstract contract GutterPunks {
    function getApproved(uint256 tokenId) virtual public view returns (address operator);
    function safeTransferFrom(address from, address to, uint256 tokenId) virtual public;
    function ownerOf(uint256 tokenId) virtual public view returns (address);
    function isApprovedForAll(address owner, address operator) virtual public view returns (bool);
}