// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";

contract Marketplace is IERC721Receiver {
    // Name of the marketplace
    string public name;

    // Index of auctions
    uint256 private auctionIndex = 0;

    // Index of sales
    uint256 private saleIndex = 0;

    // Structure to define auction properties
    struct Auction {
        uint256 auctionIndex; // Auction Index
        address addressNFTCollection; // Address of the ERC721 NFT Collection contract
        address addressPaymentToken; // Address of the ERC20 Payment Token contract
        uint256 nftId; // NFT Id
        address creator; // Creator of the Auction
        address payable currentBidOwner; // Address of the highest bider
        uint256 currentBidPrice; // Current highest bid for the auction
        uint256 endAuction; // Timestamp for the end day&time of the auction
        uint256 bidCount; // Number of bid placed on the auction
        bool isAuctionOn;
        bool isCurrentBidCancelled;
        uint256 reservePrice;
    }

    mapping(uint256 => mapping(address => Auction)) public nftAuctionData;

    // Structure to define Sale properties
    struct Sale {
        uint256 saleIndex;
        address addressNFTCollection; // Address of the ERC721 NFT Collection contract
        address addressPaymentToken; // Address of the ERC20 Payment Token contract
        uint256 nftId; // NFT Id
        address creator; // Creator of the Sale
        uint256 nftPrice;
        uint256 amount;
        uint256 nftCount; // count for nft that has been sale
        bool isOnSale;
    }


    mapping(uint256 => mapping(address => Sale)) public nftSaleData;

    // Array will store all auctions
    Auction[] private allAuctions;

    // Array will store all sales
    Sale[] private allSales;

    // Public event to notify that a new auction has been created
    event NewAuction(
        uint256 auctionIndex,
        address addressNFTCollection,
        address addressPaymentToken,
        uint256 nftId,
        address mintedBy,
        address currentBidOwner,
        uint256 currentBidPrice,
        uint256 endAuction,
        uint256 bidCount,
        bool isAuctionOn,
        uint256 reservePrice
    );

    // Public event to notify that a new sale has been created
    event NewSale(
        uint256 saleIndex,
        address addressNFTCollection,
        address addressPaymentToken,
        uint256 nftId,
        address mintedBy,
        uint256 nftPrice
    );

    event NewSaleBatch(
        uint256 saleIndex,
        address addressNFTCollection,
        address addressPaymentToken,
        uint256 nftId,
        address mintedBy,
        uint256 nftPrice,
        uint256 nftAmount
    );


    // Public event to notify that a new bid has been placed
    event NewBidOnAuction(
        address _newBidOwner,
        uint256 _newBid,
        uint256 _nftId,
        address _nftCollection
    );

    // Public event to notify that winner of an
    // auction claimed his reward
    event NFTClaimed(
        address _nftCollection,
        uint256 _nftId,
        address _claimedBy,
        address _OwnedBy,
        uint256 _bidPrice
    );

    // Public event to notify that a buyer bought an NFT
    event BoughtNFT(
        address collectionAddress,
        uint256 nftId,
        address soldBy,
        address boughtBy,
        uint256 price
    );

    event BoughtNFTBatch(
        address collectionAddress,
        uint256 nftId,
        address soldBy,
        address boughtBy,
        uint256 price,
        uint256 amounts
    );

    // Public event to notify that the creator of
    // an auction claimed for his money(Tokens)
    event TokensClaimed(
        address _nftCollection,
        uint256 _nftId,
        address _claimedBy,
        address _OwnedBy,
        uint256 _bidPrice
    );

    // Public event to notify that an NFT has been refunded to the
    // creator of an auction
    event NFTRefunded(
        address _nftCollection,
        uint256 _nftId,
        address _claimedBy
    );

    event tokenTransferEvent(
        address collectionAddress,
        uint256 nftId,
        address soldBy,
        address boughtBy,
        uint256 price,
        uint256 amounts
    );

    function isAuctionOn(bool status) internal pure {
        require(!status, "Already auction created for this NFT!");
    }

    function isSaleOn(bool status) internal pure {
        require(!status, "Already sale created for this NFT!");
    }

    // constructor of the contract
    constructor(string memory _name) {
        name = _name;
    }

    /**
     * Check if a specific address is
     * a contract address
     * @param _addr: address to verify
    */
    
    function isContract(address _addr) private view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(_addr)
        }
        return size > 0;
    }

    /**
     * Create a new auction of a specific NFT
     * @param _addressNFTCollection address of the ERC721 NFT collection contract
     * @param _addressPaymentToken address of the ERC20 payment token contract
     * @param _nftId Id of the NFT for sale
     * @param _initialBid Inital bid decided by the creator of the auction
     * @param _endAuction Timestamp with the end date and time of the auction
    */

    function createAuction(
        address _addressNFTCollection,
        address _addressPaymentToken,
        uint256 _nftId,
        uint256 _initialBid,
        uint256 _endAuction,
        uint256 _reservePrice
    ) external returns (uint256) {
        isSaleOn(nftSaleData[_nftId][_addressNFTCollection].isOnSale);
        isAuctionOn(nftAuctionData[_nftId][_addressNFTCollection].isAuctionOn);
        //Check is addresses are valid
        require(isContract(_addressNFTCollection),"Invalid NFT Collection contract address");

        require(isContract(_addressPaymentToken),"Invalid Payment Token contract address");

        // Check if the endAuction time is valid
        require(_endAuction > block.timestamp, "Invalid end date for auction");

        // Check if the initial bid price is > 0
        require(_initialBid > 0, "Invalid initial bid price");

        // Get NFT collection contract
        // NFTCollection nftCollection = NFTCollection(_addressNFTCollection);
        IERC721Upgradeable nftCollection = IERC721Upgradeable(_addressNFTCollection);

        // Make sure the sender that wants to create a new auction
        // for a specific NFT is the owner of this NFT
        require(nftCollection.ownerOf(_nftId) == msg.sender,"Caller is not the owner of the NFT");

        // Need to call APPROVE in the NFT collection contract

        // Make sure the owner of the NFT approved that the MarketPlace contract
        // is allowed to change ownership of the NFT
        require(nftCollection.getApproved(_nftId) == address(this),"Require NFT ownership transfer approval");

        // Need to call TRANSFER_NFT in the NFT collection contract

        // Lock NFT in Marketplace contract
        nftCollection.safeTransferFrom(msg.sender, address(this), _nftId);
        // require(
        //     nftCollection.transferNFTFrom(msg.sender, address(this), _nftId)
        // );

        //Casting from address to address payable
        address payable currentBidOwner = payable(address(0));

        // Create new Auction object
        Auction memory newAuction = Auction({
            auctionIndex: auctionIndex,
            addressNFTCollection: _addressNFTCollection,
            addressPaymentToken: _addressPaymentToken,
            nftId: _nftId,
            creator: msg.sender,
            currentBidOwner: currentBidOwner,
            currentBidPrice: _initialBid,
            endAuction: _endAuction,
            bidCount: 0,
            isAuctionOn: true,
            isCurrentBidCancelled:false,
            reservePrice:_reservePrice
        });

        //update list
        allAuctions.push(newAuction);
        nftAuctionData[_nftId][_addressNFTCollection] = newAuction;

        // increment auction sequence
        auctionIndex++;

        // Trigger event and return index of new auction
        emit NewAuction(
            auctionIndex,
            _addressNFTCollection,
            _addressPaymentToken,
            _nftId,
            msg.sender,
            currentBidOwner,
            _initialBid,
            _endAuction,
            0,
            true,
            _reservePrice
        );
        return auctionIndex;
    }

    // function createSale(
    //     address _addressNFTCollection,
    //     address _addressPaymentToken,
    //     uint256 _nftId,
    //     uint256 _nftAmount,
    //     uint256 _nftPrice
    // ) external returns (uint256) {
    //     isAuctionOn(nftAuctionData[_nftId][_addressNFTCollection].isAuctionOn);
    //     isSaleOn(nftSaleData[_nftId][_addressNFTCollection].isOnSale);

    //     //Check is addresses are valid
    //     require(isContract(_addressNFTCollection),"Invalid NFT Collection contract address");
    //     require(isContract(_addressPaymentToken),"Invalid Payment Token contract address");

    //     require(_nftPrice > 0 && _nftAmount >0,"Invalid NFT price or amount");

    //     // Get NFT collection contract
    //     // NFTCollection nftCollection = NFTCollection(_addressNFTCollection);
    //     if(_nftAmount ==1){
            
    //         IERC721Upgradeable nftCollection = IERC721Upgradeable(_addressNFTCollection);
    //         // Make sure the sender is the owner of this NFT
    //         require(nftCollection.ownerOf(_nftId) == msg.sender,"Caller is not the owner of the NFT");
    //         require(nftCollection.getApproved(_nftId) == address(this),"Require NFT ownership transfer approval");

    //         // Need to call TRANSFER_NFT in the NFT collection contract
    //         // Lock NFT in Marketplace contract


    //         nftCollection.safeTransferFrom(msg.sender, address(this), _nftId);
    //         // require(
    //         //     nftCollection.transferNFTFrom(msg.sender, address(this), _nftId)
    //         // );
    //     }

    //     // create new sale object
    //     Sale memory newSale = Sale({
    //         saleIndex: saleIndex,
    //         addressNFTCollection: _addressNFTCollection,
    //         addressPaymentToken: _addressPaymentToken,
    //         nftId: _nftId,
    //         creator: msg.sender,
    //         nftPrice: _nftPrice,
    //         amount:_nftAmount,
    //         isOnSale: true
    //     });

    //     allSales.push(newSale);
    //     nftSaleData[_nftId][_addressNFTCollection] = newSale;

    //     saleIndex++;

    //     emit NewSale(
    //         saleIndex,
    //         _addressNFTCollection,
    //         _addressPaymentToken,
    //         _nftId,
    //         msg.sender,
    //         _nftPrice,
    //         _nftAmount
    //     );
    //     return saleIndex;
    // }

    //contract 
    function createSale(
        address _addressNFTCollection,
        address _addressPaymentToken,
        uint256 _nftId,
        uint256 _nftPrice
    ) external returns (uint256) {
        isAuctionOn(nftAuctionData[_nftId][_addressNFTCollection].isAuctionOn);
        isSaleOn(nftSaleData[_nftId][_addressNFTCollection].isOnSale);

        //Check is addresses are valid
        require(isContract(_addressNFTCollection),"Invalid NFT Collection contract address");

        require(isContract(_addressPaymentToken),"Invalid Payment Token contract address");

        // require(_nftPrice > 0, "Invalid nft price");
        // Get NFT collection contract
        // NFTCollection nftCollection = NFTCollection(_addressNFTCollection);
        IERC721Upgradeable nftCollection = IERC721Upgradeable(_addressNFTCollection);


        // Make sure the sender is the owner of this NFT
        require(
            nftCollection.ownerOf(_nftId) == msg.sender,
            "Caller is not the owner of the NFT"
        );
        require(
            nftCollection.getApproved(_nftId) == address(this),
            "Require NFT ownership transfer approval"
        );

        // Need to call TRANSFER_NFT in the NFT collection contract
        // Lock NFT in Marketplace contract
        nftCollection.safeTransferFrom(msg.sender, address(this), _nftId);
        // require(
        //     nftCollection.transferNFTFrom(msg.sender, address(this), _nftId)
        // );

        // create new sale object
        Sale memory newSale = Sale({
            saleIndex: saleIndex,
            addressNFTCollection: _addressNFTCollection,
            addressPaymentToken: _addressPaymentToken,
            nftId: _nftId,
            creator: msg.sender,
            nftPrice: _nftPrice,
            amount:0,
            nftCount:0,
            isOnSale: true
        });

        allSales.push(newSale);
        nftSaleData[_nftId][_addressNFTCollection] = newSale;

        saleIndex++;

        emit NewSale(
            saleIndex,
            _addressNFTCollection,
            _addressPaymentToken,
            _nftId,
            msg.sender,
            _nftPrice
        );
        return saleIndex;
    }


    function enableReAuction(address _addressNFTCollection,
            address _addressPaymentToken,
            uint256 _nftId,
            uint256 _initialBid,
            uint256 _endAuction,
            uint256 _reservePrice) external{

            isSaleOn(nftSaleData[_nftId][_addressNFTCollection].isOnSale);
            isAuctionOn(nftAuctionData[_nftId][_addressNFTCollection].isAuctionOn);
            //Check is addresses are valid
            require(isContract(_addressNFTCollection),"Invalid NFT Collection contract address");

            require(isContract(_addressPaymentToken),"Invalid Payment Token contract address");

            // Check if the endAuction time is valid
            require(_endAuction > block.timestamp, "Invalid end date for auction");

            // Check if the initial bid price is > 0
            require(_initialBid > 0, "Invalid initial bid price");

            // Get NFT collection contract
            // NFTCollection nftCollection = NFTCollection(_addressNFTCollection);
            IERC721Upgradeable nftCollection = IERC721Upgradeable(_addressNFTCollection);

            // Make sure the sender that wants to create a new auction
            // for a specific NFT is the owner of this NFT
            require(nftCollection.ownerOf(_nftId) == msg.sender,"Caller is not the owner of the NFT");

            require(nftCollection.getApproved(_nftId) == address(this),"Require NFT ownership transfer approval");

            nftCollection.safeTransferFrom(msg.sender, address(this), _nftId);
            
            address payable _currentBidOwner = payable(address(0));

           
            nftAuctionData[_nftId][_addressNFTCollection].addressPaymentToken = _addressPaymentToken;
            nftAuctionData[_nftId][_addressNFTCollection].currentBidPrice = _initialBid;
            nftAuctionData[_nftId][_addressNFTCollection].isAuctionOn = true;
            nftAuctionData[_nftId][_addressNFTCollection].endAuction = _endAuction;
            nftAuctionData[_nftId][_addressNFTCollection].reservePrice = _reservePrice;
            nftAuctionData[_nftId][_addressNFTCollection].currentBidOwner = _currentBidOwner;

    }
    

    function createSaleForBatch(
        address _addressNFTCollection,
        address _addressPaymentToken,
        uint256 _nftId,
        uint256 _nftAmount,
        uint256 _nftPrice) 
    external returns (uint256){
        isAuctionOn(nftAuctionData[_nftId][_addressNFTCollection].isAuctionOn);
        isSaleOn(nftSaleData[_nftId][_addressNFTCollection].isOnSale);

        //Check is addresses are valid
        require(isContract(_addressNFTCollection),"Invalid NFT Collection contract address");
        require(isContract(_addressPaymentToken),"Invalid Payment Token contract address");

        // Make sure the sender is the owner of this NFT
        // require(nftCollection.owner(_nftId) == msg.sender,"Caller is not the owner of the NFT");
        // nftCollection.safeTransferFrom(msg.sender,address(this),_nftId,_nftAmount,"0x00");

        Sale memory newSale = Sale({
            saleIndex: saleIndex,
            addressNFTCollection: _addressNFTCollection,
            addressPaymentToken: _addressPaymentToken,
            nftId: _nftId,
            creator: msg.sender,
            nftPrice: _nftPrice,
            amount:_nftAmount,
            nftCount:0,
            isOnSale: true
        });

        allSales.push(newSale);
        nftSaleData[_nftId][_addressNFTCollection] = newSale;

        saleIndex++;

        emit NewSaleBatch(
            saleIndex,
            _addressNFTCollection,
            _addressPaymentToken,
            _nftId,
            msg.sender,
            _nftPrice,
            _nftAmount
        );
        return saleIndex;
    }

    // function buyNFT(uint256 _nftId, address _addressNFTCollection,uint256 _price,uint256 _nftAmount) external {
    //         require(isNFTOnSale(_nftId, _addressNFTCollection),"NFT is not on sale");
    //         Sale storage sale = nftSaleData[_nftId][_addressNFTCollection];

    //         require(_price >= sale.nftPrice && _nftAmount >0,"Invalid NFT price or amount");
    //         require(sale.creator != msg.sender,"Caller shouldn't be the owner of the NFT");

    //         if(_nftAmount==1){
    //             // Get NFT collection contract
    //             // NFTCollection nftCollection = NFTCollection(sale.addressNFTCollection);
    //             IERC721Upgradeable nftCollection = IERC721Upgradeable(sale.addressNFTCollection);

    //             // Make sure the sender is the owner of this NFT
    //             require(nftCollection.ownerOf(sale.nftId) != msg.sender,"Caller shouldn't be the owner of the NFT");

    //             // check the contract wheather it has the NFT....
    //             // require(nftCollection.balanceOf(address(this))>0, "Insufficient NFT balance");

    //             // Transfer NFT from marketplace contract to the buyer address
    //             nftCollection.safeTransferFrom(address(this), msg.sender, sale.nftId);
    //             // nftCollection.transferNFTFrom(address(this), msg.sender, sale.nftId);
    //         }

    //         if(_nftAmount>1){
                
    //             IERC1155Upgradeable nftCollection = IERC1155Upgradeable(_addressNFTCollection);
    //             nftCollection.safeTransferFrom(sale.creator, msg.sender, _nftId, _nftAmount, "0x00");
    //         }


    //         // Get ERC20 Payment token contract
    //         ERC20Upgradeable paymentToken = ERC20Upgradeable(sale.addressPaymentToken);

    //         uint256 decimals = paymentToken.decimals();

    //         // Transfer tokens to NFT Owner
    //         // paymentToken.transferFrom(msg.sender,sale.creator, _price*10**decimals);
    //         paymentToken.transferFrom(msg.sender,sale.creator,(sale.nftPrice*_nftAmount)*10**decimals);
            
    //         sale.isOnSale = false;
    //         emit BoughtNFT(
    //             sale.addressNFTCollection,
    //             sale.nftId,
    //             sale.creator,
    //             msg.sender,
    //             sale.nftPrice*_nftAmount,
    //             _nftAmount
    //         );
    // }

    // contract 

    function buyNFT(uint256 _nftId, address _addressNFTCollection,uint256 _price) external {
        require(
            isNFTOnSale(_nftId, _addressNFTCollection),
            "NFT is not on sale"
        );

        Sale storage sale = nftSaleData[_nftId][_addressNFTCollection];

        require(_price >= sale.nftPrice,"Invalid NFT price");
        require(sale.creator != msg.sender,
            "Caller shouldn't be the owner of the NFT");

        // Get NFT collection contract
        // NFTCollection nftCollection = NFTCollection(sale.addressNFTCollection);
        IERC721Upgradeable nftCollection = IERC721Upgradeable(sale.addressNFTCollection);
        

        // Make sure the sender is the owner of this NFT
        require(
            nftCollection.ownerOf(sale.nftId) != msg.sender,
            "Caller shouldn't be the owner of the NFT"
        );

        // check the contract wheather it has the NFT....
        // require(nftCollection.balanceOf(address(this))>0, "Insufficient NFT balance");

        // Transfer NFT from marketplace contract to the buyer address
        nftCollection.safeTransferFrom(address(this), msg.sender, sale.nftId);
        // nftCollection.transferNFTFrom(address(this), msg.sender, sale.nftId);

        // Get ERC20 Payment token contract
        ERC20Upgradeable paymentToken = ERC20Upgradeable(sale.addressPaymentToken);

        uint256 decimals = paymentToken.decimals();

        // Transfer tokens to NFT Owner
        paymentToken.transferFrom(msg.sender,sale.creator, _price*10**decimals);
        sale.isOnSale = false;
        emit BoughtNFT(
            sale.addressNFTCollection,
            sale.nftId,
            sale.creator,
            msg.sender,
            _price
        );
    }

    function buyNftBatch(uint256 _nftId, address _addressNFTCollection,uint256 _nftAmount) external{
        
        require(isNFTOnSale(_nftId, _addressNFTCollection),"NFT is not on sale");
        Sale storage sale = nftSaleData[_nftId][_addressNFTCollection];

        require(sale.creator != msg.sender,"Caller shouldn't be the owner of the NFT");

        IERC1155Upgradeable nftCollection = IERC1155Upgradeable(_addressNFTCollection);

        nftCollection.safeTransferFrom(sale.creator, msg.sender, _nftId, _nftAmount, "0x00");
        
        ERC20Upgradeable paymentToken = ERC20Upgradeable(sale.addressPaymentToken);

        uint256 decimals = paymentToken.decimals();

        // Transfer tokens to NFT Owner
        paymentToken.transferFrom(msg.sender,sale.creator, (sale.nftPrice*_nftAmount)*10**decimals);
        sale.nftCount += _nftAmount;
        sale.isOnSale = sale.nftCount>= sale.amount?false:true;
        emit BoughtNFTBatch(
            sale.addressNFTCollection,
            sale.nftId,
            sale.creator,
            msg.sender,
            sale.nftPrice*_nftAmount,
            _nftAmount
        );

    }

    /**
    * Check if an auction is open
    */
    
    function checkAndCloseAuction(uint256 _nftId, address _nftCollection)
            internal
            returns (bool)
        {
            if (nftAuctionData[_nftId][_nftCollection].isAuctionOn) {
                if (block.timestamp >= nftAuctionData[_nftId][_nftCollection].endAuction) {
                    nftAuctionData[_nftId][_nftCollection].isAuctionOn = false;
                    return false;
                }
                return true;
            } else {
                return false;
            }
    }

    function isAuctionOpen(uint256 _nftId, address _nftCollection) public view returns(bool){
        return nftAuctionData[_nftId][_nftCollection].isAuctionOn;
    }

    function isNFTOnSale(uint256 _nftId, address _nftCollection)
        public
        view
        returns (bool)
    {
        return nftSaleData[_nftId][_nftCollection].isOnSale;
    }

    /**
    * Return the address of the current highest bider
    * for a specific auction
    */

    function getLatestBidOwner(uint256 _nftId, address _nftCollection)
        public
        view
        returns (address)
    {
        return nftAuctionData[_nftId][_nftCollection].currentBidOwner;
    }

    /**
    * Return the current highest bid price
    * for a specific auction
    */

    function getCurrentBid(uint256 _nftId, address _nftCollection)
        public
        view
        returns (uint256)
    {
        return nftAuctionData[_nftId][_nftCollection].currentBidPrice;
    }

    /**
    * Place new bid on a specific auction
    */

    function bid(
            uint256 _nftId,
            address _nftCollection,
            uint256 _newBid
        ) external returns (bool _bidStatus) {


            Auction storage auction = nftAuctionData[_nftId][_nftCollection];

            if(auction.reservePrice == 0){
            // check if auction is still open
            require(checkAndCloseAuction(_nftId, _nftCollection), "Auction is not open");

            // check if new bid price is higher than the current one
            require(
                _newBid > auction.currentBidPrice,
                "New bid price must be higher than the current bid"
            );

            // check if new bider is not the owner
            require(
                msg.sender != auction.creator,
                "Creator of the auction cannot place new bid"
            );

            // get ERC20 token contract
            ERC20Upgradeable paymentToken = ERC20Upgradeable(auction.addressPaymentToken);

            uint256 decimals = paymentToken.decimals();

            // if new bid is better than current bid!,
            // transfer token from new bider account to the marketplace account
            // to lock the tokens
            require(
                paymentToken.transferFrom(msg.sender, address(this), _newBid *10**decimals),
                "Tranfer of token failed"
            );


            // new bid is valid so must refund the current bid owner (if there is one!)
            if (auction.bidCount > 0 && !auction.isCurrentBidCancelled) {
                paymentToken.transfer(
                    auction.currentBidOwner,
                    auction.currentBidPrice *10**decimals
                );
            }

            // update auction info
            address payable newBidOwner = payable(msg.sender);
            auction.currentBidOwner = newBidOwner;
            auction.currentBidPrice = _newBid;
            auction.bidCount++;

            // Trigger public event
            emit NewBidOnAuction(newBidOwner, _newBid, _nftId, _nftCollection);

            return true;
            }

            if(auction.reservePrice != 0){
                // check if auction is still open
            require(checkAndCloseAuction(_nftId, _nftCollection), "Auction is not open");

            // check if new bid price is higher than the current one
            require(
                _newBid > auction.currentBidPrice,
                "New bid price must be higher than the current bid"
            );

            // check if new bider is not the owner
            require(
                msg.sender != auction.creator,
                "Creator of the auction cannot place new bid"
            );

            // get ERC20 token contract
            ERC20Upgradeable paymentToken = ERC20Upgradeable(auction.addressPaymentToken);

            uint256 decimals = paymentToken.decimals();

            // if new bid is better than current bid!,
            // transfer token from new bider account to the marketplace account
            // to lock the tokens
            require(
                paymentToken.transferFrom(msg.sender, address(this), _newBid *10**decimals),
                "Tranfer of token failed"
            );


            // new bid is valid so must refund the current bid owner (if there is one!)
            if (auction.bidCount > 0 && !auction.isCurrentBidCancelled) {
                paymentToken.transfer(
                    auction.currentBidOwner,
                    auction.currentBidPrice *10**decimals
                );
            }

            // update auction info
            address payable newBidOwner = payable(msg.sender);
            auction.currentBidOwner = newBidOwner;
            auction.currentBidPrice = _newBid;
            auction.bidCount++;

            if(_newBid >= auction.reservePrice){
                auction.isAuctionOn = false;
            }

            // Trigger public event
            emit NewBidOnAuction(newBidOwner, _newBid, _nftId, _nftCollection);

            return true;
            }
    }

    function cancelBid(uint256 _nftId, address _nftCollection) external {
            Auction storage auction = nftAuctionData[_nftId][_nftCollection];
            require(checkAndCloseAuction(_nftId, _nftCollection), "Auction is not open");
            require(
                msg.sender != auction.creator,
                "Creator of the auction cannot cancel the bid"
            );
            require(
                msg.sender == auction.currentBidOwner,
                "Current bid Owner can only cancel the bid"
            );

            ERC20Upgradeable paymentToken = ERC20Upgradeable(auction.addressPaymentToken);
            uint256 decimals = paymentToken.decimals();

            paymentToken.transfer(
                msg.sender,
                nftAuctionData[_nftId][_nftCollection].currentBidPrice*10**decimals
            );
            auction.isCurrentBidCancelled = true;
    }

    /**
    * Function used by the winner of an auction
    * to withdraw his NFT.
    * When the NFT is withdrawn, the creator of the
    * auction will receive the payment tokens in his wallet
    */

    function claimNFT(uint256 _nftId, address _nftCollection) external {
            // Check if the auction is closed
            require(!checkAndCloseAuction(_nftId, _nftCollection), "Auction is still open");

            // Get auction
            Auction storage auction = nftAuctionData[_nftId][_nftCollection];

            // Check if the caller is the winner of the auction
            require(
                auction.currentBidOwner == msg.sender,
                "NFT can be claimed only by the current bid owner"
            );

            // Get NFT collection contract
            // NFTCollection nftCollection = NFTCollection(
            //     auction.addressNFTCollection
            // );

            IERC721Upgradeable nftCollection = IERC721Upgradeable(auction.addressNFTCollection);

            

            // NEED TO call NFT TRANSFER BEFORE THIS FUNCTION CALL

            // Transfer NFT from marketplace contract to the winner address
            nftCollection.safeTransferFrom(address(this),
                    auction.currentBidOwner,
                    auction.nftId);

            // require(
            //     nftCollection.transferNFTFrom(
            //         address(this),
            //         auction.currentBidOwner,
            //         auction.nftId
            //     )
            // );

            // Get ERC20 Payment token contract
            ERC20Upgradeable paymentToken = ERC20Upgradeable(auction.addressPaymentToken);

            uint256 decimals = paymentToken.decimals();


            // Transfer locked token from the marketplace
            // contract to the auction creator address
            require(
                paymentToken.transfer(auction.creator, auction.currentBidPrice*10**decimals)
            );

            emit NFTClaimed(
                auction.addressNFTCollection,
                auction.nftId,
                auction.creator,
                auction.currentBidOwner,
                auction.currentBidPrice
            );
    }

    /**
    * Function used by the creator of an auction
    * to withdraw his tokens when the auction is closed
    * When the Token are withdrawn, the winned of the
    * auction will receive the NFT in his walled
    */

    function claimToken(uint256 _nftId, address _nftCollection) external {
            // Check if the auction is closed
            require(!checkAndCloseAuction(_nftId, _nftCollection), "Auction is still open");

            // Get auction
            Auction storage auction = nftAuctionData[_nftId][_nftCollection];

            // Check if the caller is the creator of the auction
            require(
                auction.creator == msg.sender,
                "Tokens can be claimed only by the creator of the auction"
            );

            // Get NFT Collection contract
            // NFTCollection nftCollection = NFTCollection(
            //     auction.addressNFTCollection
            // );

            IERC721Upgradeable nftCollection = IERC721Upgradeable(auction.addressNFTCollection);

            // Transfer NFT from marketplace contract
            // to the winned of the auction
            nftCollection.safeTransferFrom(address(this),
                auction.currentBidOwner,
                auction.nftId);
            // require(nftCollection.transferNFTFrom(
            //     address(this),
            //     auction.currentBidOwner,
            //     auction.nftId
            // ));

            // Get ERC20 Payment token contract
            ERC20Upgradeable paymentToken = ERC20Upgradeable(auction.addressPaymentToken);

            uint256 decimals = paymentToken.decimals();
            // Transfer locked tokens from the market place contract
            // to the wallet of the creator of the auction
            paymentToken.transfer(auction.creator, auction.currentBidPrice*10**decimals);
            emit TokensClaimed(
                auction.addressNFTCollection,
                auction.nftId,
                auction.creator,
                auction.currentBidOwner,
                auction.currentBidPrice
            );         

    }

    /**
    * Function used by the creator of an auction
    * to get his NFT back in case the auction is closed
    * but there is no bider to make the NFT won't stay locked
    * in the contract
    */

    function withdrawOnBidNFT(uint256 _nftId, address _nftCollection) external {
            // Check if the auction is closed
            require(!checkAndCloseAuction(_nftId, _nftCollection), "Auction is still open");

            // Get auction
            Auction storage auction = nftAuctionData[_nftId][_nftCollection];

            // Check if the caller is the creator of the auction
            require(auction.creator == msg.sender,"Tokens can be claimed only by the creator of the auction");

            require(auction.currentBidOwner == address(0),"Existing bider for this auction");

            // Get NFT Collection contract

            IERC721Upgradeable nftCollection = IERC721Upgradeable(auction.addressNFTCollection);

            nftCollection.safeTransferFrom(address(this),auction.creator, auction.nftId);
            
            emit NFTRefunded(auction.addressNFTCollection,auction.nftId, msg.sender);
    }

    function cancelSaleOrAuction(uint256 _nftId, address _nftCollection) external {

            require(isNFTOnSale(_nftId, _nftCollection) || checkAndCloseAuction(_nftId, _nftCollection), "Sale or Auction should be Opened!");
            if (isNFTOnSale(_nftId, _nftCollection)) {

                // NFTCollection nftCollection = NFTCollection(nftSaleData[_nftId][_nftCollection].addressNFTCollection);
                IERC721Upgradeable nftCollection = IERC721Upgradeable(nftSaleData[_nftId][_nftCollection].addressNFTCollection);

                Sale storage sale = nftSaleData[_nftId][_nftCollection];
                require(sale.creator == msg.sender,"Caller is not the owner of the NFT");
                // require(nftCollection.ownerOf(nftSaleData[_nftId][_nftCollection].nftId) == msg.sender,"Caller is not the owner of the NFT");

                // nftCollection.transferNFTFrom(
                //     address(this),
                //     msg.sender,
                //     nftSaleData[_nftId][_nftCollection].nftId
                // );
                nftCollection.safeTransferFrom(address(this),msg.sender,nftSaleData[_nftId][_nftCollection].nftId);
                nftSaleData[_nftId][_nftCollection].isOnSale = false;
            }
            else if(checkAndCloseAuction(_nftId, _nftCollection)){

                Auction storage auction = nftAuctionData[_nftId][_nftCollection];

                require(auction.creator == msg.sender,"Caller is not the owner of the NFT");


                // NFTCollection nftCollection = NFTCollection(nftAuctionData[_nftId][_nftCollection].addressNFTCollection);
                IERC721Upgradeable nftCollection = IERC721Upgradeable(nftAuctionData[_nftId][_nftCollection].addressNFTCollection);
                
                nftCollection.safeTransferFrom(
                    address(this),
                    msg.sender,
                    nftAuctionData[_nftId][_nftCollection].nftId
                );
                if(nftAuctionData[_nftId][_nftCollection].currentBidPrice >0 && nftAuctionData[_nftId][_nftCollection].currentBidOwner != address(0) ){
                    ERC20Upgradeable paymentToken = ERC20Upgradeable(nftAuctionData[_nftId][_nftCollection].addressPaymentToken);
                    uint256 decimals = paymentToken.decimals();

                    paymentToken.transfer(msg.sender,nftAuctionData[_nftId][_nftCollection].currentBidPrice*10**decimals);
                }
                nftAuctionData[_nftId][_nftCollection].isAuctionOn = false;
            }
    }

    function onERC721Received(
            address,
            address,
            uint256,
            bytes memory
        ) public virtual override returns (bytes4) {
            return this.onERC721Received.selector;
    }

    function tokenTransfer(address _addressNFTCollection,uint _nftId,address _creator,address _userAddress,uint _price ,uint _quantity,address _tokenAddress) public {

        ERC20Upgradeable paymentToken = ERC20Upgradeable(_tokenAddress);
        uint256 decimals = paymentToken.decimals();
        paymentToken.transferFrom(msg.sender,_userAddress, (_quantity>0?_quantity:1*_price)*10**decimals);
        emit tokenTransferEvent(
            _addressNFTCollection,
            _nftId,
            _creator,
            msg.sender,
            _price*_quantity,
            _quantity
        );
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
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

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
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
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
interface IERC165Upgradeable {
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