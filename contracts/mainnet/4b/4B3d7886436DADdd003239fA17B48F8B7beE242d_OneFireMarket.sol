// SPDX-License-Identifier: MIT
/*
 $$$$$$\                      $$$$$$$$\ $$\                     
$$  __$$\                     $$  _____|\__|                    
$$ /  $$ |$$$$$$$\   $$$$$$\  $$ |      $$\  $$$$$$\   $$$$$$\  
$$ |  $$ |$$  __$$\ $$  __$$\ $$$$$\    $$ |$$  __$$\ $$  __$$\ 
$$ |  $$ |$$ |  $$ |$$$$$$$$ |$$  __|   $$ |$$ |  \__|$$$$$$$$ |
$$ |  $$ |$$ |  $$ |$$   ____|$$ |      $$ |$$ |      $$   ____|
 $$$$$$  |$$ |  $$ |\$$$$$$$\ $$ |      $$ |$$ |      \$$$$$$$\ 
 \______/ \__|  \__| \_______|\__|      \__|\__|       \_______|                                             
                                                     
*/
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract OneFireMarket is ERC721URIStorage, ReentrancyGuard {
    //counter for counting the number of tokenId's minted
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    //the commission OneFire earn's from every sale on the platform.
    uint256 commissionPercentage = 3;
    //this is the listing fee OneFire take's when minting an item.
    //NOTE: the listing fee is only taken when minting, when you are relisting no fee is taken & this may go to 0 in the future.
    uint256 listingPrice = 0;
    uint256 minbidincrement = 0.0078 ether; //min incr for a bid.
    address payable master; //address of the contract owner.

    //this is were all nft in the market is stored,
    //it's keeps track of every nft minted.
    mapping(uint256 => MarketItem) public idToMarketItem;

    //this is the structure of how every nft is stored in the mapping up there.
    struct MarketItem {
        uint256 tokenId; //the item token id.
        address payable artist; //the artist who created the item.
        address payable seller; //who put up the nft for sale.
        address payable maxBidder; //the highest bidder for this item.
        uint256 maxBid; //the highest bid for this item.
        uint256 price; //the price of the nft.
        bool sold; //checks if it's sold or not.
        bool listed; //checks if it's listed or not.
        bool offer; //checks if the item has offer.
        uint256 artistPercentage; //the peercentage each item over take's
        uint256 expiration; //when the auction will close/timeout.
        bool bid; //checks if there is a bid.
    }

    //this is event is logged whenever an item is minted.
    event MarketItemCreated(
        uint256 indexed tokenId,
        address artist,
        address seller,
        address maxBidder,
        uint256 maxBid,
        uint256 price,
        bool sold,
        bool listed
    );

    constructor() ERC721("OneFire", "Fire") {
        master = payable(msg.sender);
    }

    //Updates the listing price of the contract
    ///Only owner of this contract can call this function,
    ///this is the function to update the listing fee that the market takes for listing nft.
    function updateListingPrice(uint256 _listingPrice) public payable {
        require(master == msg.sender);
        listingPrice = _listingPrice;
    }

    //the minbidincrement is the minimum amount you can increase at a time of bid.
    ///Only the owner can call the function,
    ///this function is to update the min bid incr of the platform
    function updateMinbidincrement(uint256 _Minbidincrement) public payable {
        require(master == msg.sender);
        minbidincrement = _Minbidincrement;
    }

    //this is a function to get the current listing fee of the platform.
    function getListingPrice() public view returns (uint256) {
        return listingPrice;
    }

    //this function updates the artist of any nft.
    function updateArtist(address newartist, uint256 tokenId) public payable {
        require(idToMarketItem[tokenId].artist == msg.sender);
        idToMarketItem[tokenId].artist = payable(newartist);
    }

    //this function updates the artist percentage of the any nft.
    function updateArtistPercent(uint256 _percent, uint256 tokenId)
        public
        payable
    {
        require(idToMarketItem[tokenId].artist == msg.sender);
        require(_percent < 11);
        idToMarketItem[tokenId].artistPercentage = _percent;
    }

    //this is a function to get the artist for any nft.
    function getArtist(uint256 tokenId) public view returns (address) {
        return idToMarketItem[tokenId].artist;
    }

    //this is a function to get the artist percent.
    function getArtistPercent(uint256 tokenId) public view returns (uint256) {
        return idToMarketItem[tokenId].artistPercentage;
    }

    //this is the function to mint a new nft on OneFire.
    ///You can decide to list the item as you mint or mint before listing it's up to you.
    function createToken(
        string memory tokenURI,
        uint256 price,
        bool listed,
        uint256 artistPercentage
    ) public payable returns (uint256) {
        _tokenIds.increment(); //increase's the total item minted by 1
        uint256 newTokenId = _tokenIds.current();
        _mint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, tokenURI);
        //calls the creatmarketitm and passes the data to it.
        createMarketItem(newTokenId, price, listed, artistPercentage);
        //returns the tokenId of the newly minted nft.
        return newTokenId;
    }

    //grabs all the data from above function and then proceed with it.
    function createMarketItem(
        uint256 tokenId,
        uint256 price,
        bool listed,
        uint256 artistPercentage
    ) private nonReentrant {
        require(artistPercentage < 11); //require's that the percentage an artist take is not more than 10.
        require(price > 0 ether); //require's that you can list an nft for 0 ether.
        require(msg.value >= listingPrice); //require's the person who is minting to pay the listing fee to the platform.
        payable(master).transfer(msg.value); //send's listing fee to the contract owner.

        //checks if the msg.sender wants to list the nft or not,
        //if true it save's this to the mapping if not it save's the listed == false.
        if (listed == true) {
            idToMarketItem[tokenId] = MarketItem(
                tokenId,
                payable(msg.sender), //sets the the caller to the artist.
                payable(msg.sender), //sets the caller to the seller.
                payable(address(0)),
                0,
                price,
                false,
                listed,
                false,
                artistPercentage,
                0,
                false
            );
        } else if (listed == false) {
            idToMarketItem[tokenId] = MarketItem(
                tokenId,
                payable(msg.sender), //sets the the caller to the artist.
                payable(msg.sender), //sets the the caller to the seller.
                payable(address(0)),
                0,
                price,
                false,
                listed,
                false,
                artistPercentage,
                0,
                false
            );
        }

        //if an item is listed it emit this  if its not it emit the listed == false.
        if (listed == true) {
            _transfer(msg.sender, address(this), tokenId);
            emit MarketItemCreated(
                tokenId,
                msg.sender,
                msg.sender,
                address(0),
                0,
                price,
                false,
                listed
            );
        }

        if (listed == false) {
            emit MarketItemCreated(
                tokenId,
                msg.sender,
                msg.sender,
                address(0),
                0,
                price,
                false,
                listed
            );
        }
    }

    //this function is simple it simply allow's you to relist your owned asset/nft.
    ///the market doesn't charge anythin to relist an nft,
    ///when an nft is relisted it is automatically is put up for both auction an buy,
    ///after relisted anyone can place a bid or buy the item.
    function resellToken(uint256 tokenId, uint256 price)
        public
        payable
        nonReentrant
    {
        require(price > 0);
        require(ownerOf(tokenId) == msg.sender);
        address lastHightestBidder = idToMarketItem[tokenId].maxBidder;
        uint256 lastHighestBid = idToMarketItem[tokenId].maxBid;
        if (lastHighestBid != 0) {
            idToMarketItem[tokenId].maxBid = 0;
            idToMarketItem[tokenId].maxBidder = payable(address(0));
            idToMarketItem[tokenId].offer = false;
            payable(address(lastHightestBidder)).transfer(lastHighestBid);
        }
        idToMarketItem[tokenId].sold = false;
        idToMarketItem[tokenId].listed = true;
        idToMarketItem[tokenId].price = price;
        idToMarketItem[tokenId].seller = payable(msg.sender);
        _transfer(msg.sender, address(this), tokenId);
    }

    //this function allows you cancel a listed nft for sale/auction..
    ///only the seller of this token can call this function.
    function cancelSale(uint256 tokenId) public nonReentrant {
        //checks and make sure that there is no bid for this item.
        require(idToMarketItem[tokenId].bid != true);
        //checks if the owner is the caller.
        require(idToMarketItem[tokenId].seller == msg.sender);
        //make's sure the item is listed we don't people unlisting an item that is not on sale.
        require(ownerOf(tokenId) == payable(address(this)));
        //transfer the item from the escrow which is were it is heard back to the owner address
        _transfer(address(this), msg.sender, tokenId);
        //do some important change's on the id struct in the mapping.
        idToMarketItem[tokenId].sold = false;
        idToMarketItem[tokenId].listed = false;
    }

    //this is to buy an item listed for sale.
    /// You may buy this item with the value sent
    /// along with this transaction.
    function createMarketSale(uint256 tokenId) public payable nonReentrant {
        uint256 price = idToMarketItem[tokenId].price; //gets the nft price.
        uint256 artistPercentage = idToMarketItem[tokenId].artistPercentage; //artist percentage.
        address seller = idToMarketItem[tokenId].seller; //gets the nft seller.
        address artist = idToMarketItem[tokenId].artist; //gets the artis who created the item.
        require(idToMarketItem[tokenId].bid != true); //make's sure there is no bid
        require(ownerOf(tokenId) == payable(address(this))); //make's sure the item is listed
        require(msg.sender != idToMarketItem[tokenId].seller); //make sure the seller does not buy his/her nft
        require(msg.value == price); // makes sure the buyer is paying the asking price
        require(idToMarketItem[tokenId].listed == true); //make's sure again that the item is listed before continuing.
        idToMarketItem[tokenId].sold = true; //set the sold to true
        idToMarketItem[tokenId].listed = false; //unlist iem.

        //this function splits the funds between parties.
        uint256 commissionAmount = (msg.value * commissionPercentage) / 100;
        uint256 artistAmount = (msg.value * artistPercentage) / 100;
        uint256 amountToTransferToTokenOwner = msg.value -
            commissionAmount -
            artistAmount;

        bool success;
        //sends 3% to the funds contract owner
        (success, ) = payable(master).call{value: commissionAmount}("");
        require(success);

        //sends the 90% of the funds to the seller
        (success, ) = seller.call{value: amountToTransferToTokenOwner}("");
        require(success);

        //send's 7% of the funds to the artist who created the nft.
        (success, ) = artist.call{value: artistAmount}("");
        require(success);

        //then before transfering the nft to the buyer.
        _transfer(address(this), msg.sender, tokenId);
    }

    //this is a function to placebid for an item
    ///the bid amount will be sent along side this transaction,
    ///the only way you will get your ETH back is if you get outbided,
    ///if you place a bid when the timer is 15min or less the timer resets itself back to 15min.
    function placebid(uint256 tokenId) public payable nonReentrant {
        require(idToMarketItem[tokenId].listed == true); //make's sure the item is listed for auction/sale.
        require(msg.value > idToMarketItem[tokenId].price + minbidincrement); //make's sure the bid is higher than the price.
        uint256 duration = 24 hours; //The duration set for the bid
        uint256 expiration = block.timestamp + duration; // Timeout
        if (idToMarketItem[tokenId].expiration > 0) {
            //checks if this is the first bid.
            require(block.timestamp <= idToMarketItem[tokenId].expiration);
        }
        uint256 durationend = 15 minutes; //The duration set for the bid
        uint256 expirationend = block.timestamp + durationend; // Timeout
        if (
            idToMarketItem[tokenId].expiration <= block.timestamp + durationend
        ) {
            //checks if the time is less than 15 min.
            idToMarketItem[tokenId].expiration = expirationend; //sets the timer back to 15mins.
        }
        require(idToMarketItem[tokenId].seller != msg.sender); //make's sure the seller is not trying to bid.
        require(msg.value > idToMarketItem[tokenId].maxBid + minbidincrement); //checks if the bid is higher than the last bid
        if (idToMarketItem[tokenId].bid == false) {
            //if this is the first bid then the timer will start and the auction will last for 24hours.
            idToMarketItem[tokenId].expiration = expiration;
        }
        address lastHightestBidder = idToMarketItem[tokenId].maxBidder;
        uint256 lastHighestBid = idToMarketItem[tokenId].maxBid;
        idToMarketItem[tokenId].bid = true;
        idToMarketItem[tokenId].maxBid = msg.value;
        idToMarketItem[tokenId].maxBidder = payable(msg.sender);
        if (lastHighestBid != 0) {
            //check if there is a bid is there is one the it transfer the bid back to its bidder.
            payable(address(lastHightestBidder)).transfer(lastHighestBid);
        }
    }

    //this is the function to finalize bid after the timer has expired or ended.
    /// By doing this you are finilizing the auction for this nft,
    ///alongside you are earning 2% of this sale,
    ///any bid you finalize you earn two percent.
    function finilizeBid(uint256 tokenId) public nonReentrant {
        require(idToMarketItem[tokenId].bid == true); //check if bid is true
        require(block.timestamp >= idToMarketItem[tokenId].expiration); //check if the bid as expired or not.
        uint256 finilizerPercentage = 2; //the percent to send to whoever finalize this bid
        uint256 artistPercentage = idToMarketItem[tokenId].artistPercentage; //artist percentage.
        uint256 maxBid = idToMarketItem[tokenId].maxBid; //get the highest bid
        address seller = idToMarketItem[tokenId].seller; //gets seller
        address artist = idToMarketItem[tokenId].artist; //gets artist
        address maxBidder = idToMarketItem[tokenId].maxBidder; //get highest bidder
        address finilizer = msg.sender; //whoever finalized the auction/bid
        //does some changes for this tokenId
        idToMarketItem[tokenId].maxBid = 0;
        idToMarketItem[tokenId].price = maxBid;
        idToMarketItem[tokenId].bid = false;
        idToMarketItem[tokenId].expiration = 0;
        uint256 commissionAmount = (maxBid * commissionPercentage) / 100;
        uint256 artistAmount = (maxBid * artistPercentage) / 100;
        uint256 finalAmount = (maxBid * finilizerPercentage) / 100;
        uint256 amountToTransferToTokenOwner = maxBid -
            commissionAmount -
            artistAmount -
            finalAmount;

        bool success;
        //sends 3% of the funds contract owner
        (success, ) = payable(master).call{value: commissionAmount}("");
        require(success);

        //sends the 90% of the funds to the seller
        (success, ) = seller.call{value: amountToTransferToTokenOwner}("");
        require(success);

        //send's 7% of the funds to the artist who created the nft.
        (success, ) = artist.call{value: artistAmount}("");
        require(success);
        //send's 2% of the sale to whoever finalized the deal/bid.
        (success, ) = finilizer.call{value: finalAmount}("");
        require(success);
        //transer the nft to the winner of the auction.
        _transfer(address(this), maxBidder, tokenId);
        //do some changes to the tokenid,
        idToMarketItem[tokenId].listed = false;
        idToMarketItem[tokenId].sold = true;
    }

    //this function is to create an offer
    ///this is a function to create an offer
    ///you can only make an offer if the item is unlisted if listed please place a bid instead.
    function createOffer(uint256 tokenId) public payable nonReentrant {
        require(idToMarketItem[tokenId].listed == false); //make's sure the item is not listed.
        require(ownerOf(tokenId) != msg.sender); //make's sure the only is not the one offering the price.
        require(msg.value > idToMarketItem[tokenId].maxBid); //your offer must be higher than the last one.
        address lastHightestBidder = idToMarketItem[tokenId].maxBidder; //last highset bidder/offerer.
        uint256 lastHighestBid = idToMarketItem[tokenId].maxBid; //last highest offer
        idToMarketItem[tokenId].maxBid = msg.value; //make''s this the new highest offer.
        idToMarketItem[tokenId].maxBidder = payable(msg.sender); //make's the msg.sender the new highest offerer
        if (lastHighestBid != 0) {
            payable(address(lastHightestBidder)).transfer(lastHighestBid);
        } //check's if there was an offer and send's the fund back to the respective owner.
        idToMarketItem[tokenId].offer = true; //set offer to true
    }

    //cancel an offer that was made.
    ///if there is an offer on this tokenid and you are the one who made it you can cancel it by calling this function.
    function cancelOffer(uint256 tokenId) public nonReentrant {
        require(idToMarketItem[tokenId].offer == true); //make's sure there is an offer.
        //sets some uint and address that will be used later
        uint256 maxBid = idToMarketItem[tokenId].maxBid;
        address maxBidder = idToMarketItem[tokenId].maxBidder;
        //make's sure the one who made the offer is the one calling this function.
        require(idToMarketItem[tokenId].maxBidder == msg.sender);
        idToMarketItem[tokenId].maxBid = 0; //set's highest offer to '0'
        idToMarketItem[tokenId].maxBidder = payable(address(0)); //set the offerer to '0' address.
        idToMarketItem[tokenId].offer = false; //set  offer to false.
        payable(address(maxBidder)).transfer(maxBid); //transfer money back to the offerer.
    }

    //function to accept offer
    ///if you own this tokenId you will be able to call this function and accept the offer on it..
    function acceptOffer(uint256 tokenId) public nonReentrant {
        require(idToMarketItem[tokenId].offer == true); //make's sure there is an offer
        require(ownerOf(tokenId) == msg.sender); //make's sure you are the owner.
        uint256 artistPercentage = idToMarketItem[tokenId].artistPercentage; //artist percentage.
        //set some uint and address to be used later.
        uint256 maxBid = idToMarketItem[tokenId].maxBid;
        address owner = ownerOf(tokenId);
        address artist = idToMarketItem[tokenId].artist;
        address maxBidder = idToMarketItem[tokenId].maxBidder;
        idToMarketItem[tokenId].maxBid = 0; //set highest bid to '0'.
        idToMarketItem[tokenId].price = maxBid; //set price to highest bid.
        idToMarketItem[tokenId].maxBidder = payable(address(0)); //make's  the highest bidder the '0' address.

        //set some uint to be used later.
        uint256 commissionAmount = (maxBid * commissionPercentage) / 100;
        uint256 artistAmount = (maxBid * artistPercentage) / 100;
        uint256 amountToTransferToTokenOwner = maxBid -
            commissionAmount -
            artistAmount;

        bool success;
        //sends 3% of the funds contract owner
        (success, ) = payable(master).call{value: commissionAmount}("");
        require(success);

        //sends 90% of the fund to the token owner
        (success, ) = owner.call{value: amountToTransferToTokenOwner}("");
        require(success);

        //sends 7% of the fund to the creator of the nft.
        (success, ) = artist.call{value: artistAmount}("");
        require(success);

        _transfer(msg.sender, maxBidder, tokenId); //transfer the ownership of the nft to the highest bidder

        idToMarketItem[tokenId].offer = false; //set offer to false.
    }

    /*
       @dev Allows the current owner to transfer control of the contract to a newOwner.
       @param _newOwner The address to transfer ownership to.
      */
    function transferOwnership(address _newOwner) public {
        require(msg.sender == master);
        master = payable(_newOwner);
    }

    ///get's the current number of tokens on the market
    function totalSupply() public view returns (uint256) {
        return _tokenIds.current();
    }

    //this gets all the current item on the OneFire market place
    ///returns a list of all the nft that a currently in the market.
    function fetchMarketItems() public view returns (MarketItem[] memory) {
        uint256 itemCount = _tokenIds.current();
        uint256 unsoldItemCount = _tokenIds.current();
        uint256 currentIndex = 0;

        MarketItem[] memory items = new MarketItem[](unsoldItemCount);
        for (uint256 i = 0; i < itemCount; i++) {
            if (
                idToMarketItem[i + 1].listed == true ||
                idToMarketItem[i + 1].listed == false ||
                idToMarketItem[i + 1].sold == true ||
                idToMarketItem[i + 1].sold == false
            ) {
                uint256 currentId = i + 1;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    ///this is to fetch the nft that any address holds that is from this contract/marketplace.
    function fetchHisNFTs(address _address)
        public
        view
        returns (MarketItem[] memory)
    {
        uint256 totalItemCount = _tokenIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalItemCount; i++) {
            if (
                ownerOf(i + 1) == address(_address) ||
                idToMarketItem[i + 1].maxBidder == address(_address)
            ) {
                itemCount += 1;
            } else if (
                idToMarketItem[i + 1].seller == address(_address) &&
                idToMarketItem[i + 1].sold == false &&
                idToMarketItem[i + 1].listed == true
            ) {
                itemCount += 1;
            }
        }

        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint256 i = 0; i < totalItemCount; i++) {
            if (
                ownerOf(i + 1) == address(_address) ||
                idToMarketItem[i + 1].maxBidder == address(_address)
            ) {
                uint256 currentId = i + 1;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            } else if (
                idToMarketItem[i + 1].seller == address(_address) &&
                idToMarketItem[i + 1].sold == false &&
                idToMarketItem[i + 1].listed == true
            ) {
                uint256 currentId = i + 1;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    ///this is to fetch a specific nft.
    function fetchTokenDetails(uint256 _token)
        public
        view
        returns (MarketItem[] memory)
    {
        uint256 totalItemCount = _tokenIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].tokenId == _token) {
                itemCount += 1;
            }
        }
        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].tokenId == _token) {
                uint256 currentId = i + 1;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    ///this function enables admin to change the url of any token
    function setUserUrl(uint256 tokenId, string memory Url_) public {
        require(msg.sender == master);
        _setTokenURI(tokenId, Url_);
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/extensions/ERC721URIStorage.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorage is ERC721 {
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev See {ERC721-_burn}. This override additionally checks to see if a
     * token-specific URI was set for the token, and if so, it deletes the token URI from
     * the storage mapping.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
                /// @solidity memory-safe-assembly
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