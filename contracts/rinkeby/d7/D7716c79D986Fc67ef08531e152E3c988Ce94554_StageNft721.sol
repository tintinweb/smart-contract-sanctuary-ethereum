// Pending Tasks 
// Check if he want to bid anotherOne, then Add More from his wallet and reserve for next Bid
// Royalties on fixed price are Missing
// Testing of ERC 721
// Add _exists() Modifier
// resolve wei decimal bugs ERC 20- remaining Owner Balance should be seprate and Royalty balance should be seprate
// replace Indexing from loop 

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./ERC721.sol";
import "./Ownable.sol";
import "./ERC721URIStorage.sol";
import "./StageNft721Royalties.sol";
import "./StageNft721Auction.sol";

contract StageNft721 is ERC721, Ownable, ERC721URIStorage, Stage721Royalties, StageNft721Auction{
    modifier IsApprovedOrOwner(uint nftId) {
        require (_isApprovedOrOwner(_msgSender(), nftId), "Error! Only owner has Access");
        _;
    }
    modifier ActiveSale() {
        require (saleIsActive == true, "Sale is Not Active");
        _;
    }

    bool public saleIsActive = false;
    string public provenanceHashValue;
    mapping (uint=>uint) private NFT_Price;
    // NFT ID to 1st Minter Address  
    mapping (uint => address) MinterAddress; 
    constructor (string memory name, string memory symbol) ERC721(name, symbol){}
    
    function checkNftPrice(uint nftId) public view returns(uint){
        require(_exists(nftId), "Error! Token ID Does't Exist");
        return NFT_Price[nftId];
    }
    uint8 _serviceFee;
    function setServiceFee(uint8 serviceFee) external onlyOwner ActiveSale {
        require(serviceFee != _serviceFee, "Cannot set same Service Fee");
        _serviceFee = serviceFee;
    }
    function MintTo(address payable to, uint tokenId, string memory TokenURI , address payable localMinter, uint Percentage, uint NftPrice) public payable { 
        require(saleIsActive, "Error! Sale is Not Active");
        require(msg.value >= NftPrice , "Error! Insufficient Balance");
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, TokenURI);
        // Adding in Mapping to Struct through below .
        _setTokenRoyalty(tokenId, payable(localMinter), Percentage); // Setting Address of local minter for royalty on each transfer and Percentage what he has decided 
        //Storing NFT Price
        NFT_Price[tokenId]= msg.value;
        _royaltyAndDstageFee(NftPrice, Percentage, localMinter, localMinter, _serviceFee );
    }
    function changeNFTPrice(uint nftID, uint newPrice)  external {
        require(_exists(nftID) && _owners[nftID] == _msgSender(), "NFT not exist or you are not owner of this NFT");
        require(NFT_Price[nftID] != newPrice, "Cannot set same Price");
         NFT_Price[nftID] = newPrice;
    }
    function _simpleMint (uint tokenId, string memory tokenURI, uint minterPercentage) public { // , uint NftPrice  Add Nft Price Here
        require(saleIsActive, "Error! Sale is Not Active");
        require(minterPercentage <= 50, "Error! Maximum Minting Percentage is 50% ");
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, tokenURI);
        _setTokenRoyalty(tokenId, payable(msg.sender), minterPercentage);
        // NFT_Price[tokenId] = NftPrice;
    }
    function MintForTimedAuction (uint NftId, string memory tokenURI, uint minterPercentage, uint startTime, uint endTime, uint minimumAmount) public { // , uint NftPrice  Add Nft Price Here
        _simpleMint(NftId , tokenURI , minterPercentage);
        _putNftForTimedAuction(NftId, startTime, endTime, minimumAmount);
    }
    function MintForOpenBidding (uint NftId, string memory tokenURI, uint minterPercentage) public { // , uint NftPrice  Add Nft Price Here
        _simpleMint(NftId , tokenURI , minterPercentage);
        _placeNftForBids(NftId);
    }
    function MintForFixedPrice (uint NftId, string memory tokenURI, uint minterPercentage, uint fixedPrice) public { // , uint NftPrice  Add Nft Price Here
        _simpleMint(NftId , tokenURI , minterPercentage);
        PlaceNftForFixedPrice(NftId , fixedPrice );
    }
    function switchSaleState() public onlyOwner{
        if (saleIsActive == true){
            saleIsActive = false;
        }
        else{
            saleIsActive = true;
        }
    }
    function SafeTransferFromDstage (address payable from, address payable to, uint tokenId, bytes memory data) external {
        _safeTransferFromDstage(from, to, tokenId, data);
    }
    function _safeTransferFromDstage(address payable from, address payable to, uint tokenId, bytes memory data) internal {
        _updateNftPrice(tokenId);
        RoyaltyInfo memory royalties = _royalties[tokenId];
        _royaltyAndDstageFee(NFT_Price[tokenId], royalties.amount, royalties.recipient, payable(_owners[tokenId]), _serviceFee);
        _safeTransfer(from, to, tokenId, data);
    }
    
    function transferFromDstage(address payable from, address payable to, uint tokenId) payable external {
        _updateNftPrice( tokenId);
        RoyaltyInfo memory royalties = _royalties[tokenId];
        _royaltyAndDstageFee(NFT_Price[tokenId], royalties.amount, royalties.recipient, payable(_owners[tokenId]), _serviceFee);
        _transfer(from, to, tokenId);
        // NFT_Price[tokenId]=msg.value;
    }
    function _updateNftPrice(uint tokenId) internal  {
        require (msg.value >= NFT_Price[tokenId], "Amount is Less then NftPrice");
        NFT_Price[tokenId]=msg.value;
    }
    function getBalanceContract() public view onlyOwner returns(uint){
        return address(this).balance;
    }
    function BurnTokken(uint tokenID) IsApprovedOrOwner(tokenID) public {
       ERC721URIStorage._burn(tokenID);        
    }
    // Function Place NFT for Bidding
    function PlaceNftForOPenBidding(uint NftId) ActiveSale IsApprovedOrOwner(NftId) external  {
        _placeNftForBids(NftId);
    }
    function PlaceNftForTimedAuction(uint NftId, uint startTime,uint endTime, uint minimumAmount) ActiveSale IsApprovedOrOwner(NftId) external  {
        _putNftForTimedAuction(NftId, startTime, endTime, minimumAmount);
    }

    function AddOpenBids(uint nftId , uint _bidAmount) external payable {
        if (_deposits[msg.sender] < _bidAmount){
            _getBidBalance(payable(msg.sender), _bidAmount);
        }
        require(_bidAmount <= _deposits[msg.sender], "Error! Insufficient Balance");
        _addOpenBid( nftId, _bidAmount);
    }
    function AddAuctionBid(uint nftId, uint _bidAmount) public payable {
        require(Nft[nftId].hasBidden[msg.sender]==false, "Only 1 Bid is allowed per Wallet");
        if(Nft[nftId].bidAmount.length != 0)
            require(_bidAmount >= (Nft[nftId].bidAmount[Nft[nftId].index] + (Nft[nftId].bidAmount[Nft[nftId].index]*10)/100), "Bid Amount Must be greater than 10% of current Highest Bid");
        if (_deposits[msg.sender] < _bidAmount){
            _getBidBalance(payable(msg.sender), _bidAmount);
        }
        require( _bidAmount >= Nft[nftId].minimumPrice && _bidAmount <= _deposits[msg.sender], "Error! Insufficient Balance or Low Biding Amount");
        _addAuctionBid(nftId,_bidAmount);
    }
    /*************************************OPEN BIDDING************************************/
    function AcceptYourHighestBid (uint nftId) IsApprovedOrOwner(nftId) external  {
        _getIndexOfHighestBid(nftId);
        _deductBiddingAmount(Nft[nftId].bidAmount[Nft[nftId].index], Nft[nftId].bidderAddress[Nft[nftId].index]);   // Deduct Bidder Amount of Bidding 
        _royaltyAndDstageFee (Nft[nftId].bidAmount[Nft[nftId].index], _royalties[nftId].amount, _royalties[nftId].recipient, payable(ownerOf(nftId)) , _serviceFee);
        _transfer(_owners[nftId], Nft[nftId].bidderAddress[Nft[nftId].index], nftId);
        _setNftPrice(nftId, Nft[nftId].bidAmount[Nft[nftId].index]);
        _removeNftFromSale(nftId);
        _bidAccepted(nftId);
    }
    function _setNftPrice(uint nftId, uint nftPrice) internal {
        NFT_Price[nftId] = nftPrice;
    }
    function PlaceNftForFixedPrice(uint nftId , uint Fixedprice ) ActiveSale IsApprovedOrOwner(nftId) public {
        require(_exists(nftId), "Nft Does Not Exist");
        _putNftForFixedPrice( nftId , Fixedprice);
        NFT_Price[nftId] = Fixedprice;
    }
    function RemoveNftFromSale(uint nftId) IsApprovedOrOwner(nftId) external {
        _removeNftFromSale(nftId);
    }
    function _removeNftFromSale(uint nftId) internal {
        require(_exists(nftId), "Nft Does Not Exists");
        _removeFromSale(nftId);
        _releaseBiddingValue (nftId);
    }
    function PurchaseNftFromFixedPrice(uint nftId, address payable to , bytes memory data ) payable external{
        require(msg.value == NFT_Price[nftId], "Error! Insifficient Price" );
        _safeTransferFromDstage(payable(_owners[nftId]),  to, nftId, data);
        // Remove from Fixed Price
        _removeNftFromSale(nftId);
    }
    function WithDrawAmount(uint amount) external {
        require (amount <= _deposits[_msgSender()]-BidsAmount[_msgSender()], "Balance is low and reserved for Bids");
        _withdrawBalance(amount);
    } 
    function placeBidOnLazyMintedNFT(address lazyMinter, uint minimumAmount, uint bidAmount,  uint minterPercentage, uint tokenId, string memory tokenURI, uint startTime, uint endTime ) public payable {
        require(saleIsActive, "Error! Sale is Not Active");
        require(minterPercentage <= 50, "Error! Maximum Minting Percentage is 50% ");
        _safeMint(lazyMinter, tokenId);
        _setTokenURI(tokenId, tokenURI);
        _setTokenRoyalty(tokenId, payable(lazyMinter), minterPercentage);
        _putNftForTimedAuction(tokenId,startTime, endTime, minimumAmount);
        AddAuctionBid(tokenId, bidAmount);
    }
    function extendAuctionTime(uint nftId, uint endTime )  IsApprovedOrOwner(nftId) external{
        _extendAuctionTime(nftId, endTime);
    }
}