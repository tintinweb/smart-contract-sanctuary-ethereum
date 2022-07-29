// SPDX-License-Identifier: MIT
// Constraints for wei and Ethers in fixed amount and royalties
// Burn only owner // Open Bidding 
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;
import "./ERC1155.sol"; 
import "./ERC1155Burnable.sol";
import "./StageNft1155Royalties.sol";
import "./StageNft1155Auctions.sol";

contract StageNFT1155 is ERC1155, ERC1155Burnable, StageNftErc20 , StageNft1155Auction { 

    mapping (uint => bool) nftExists;
    mapping (uint=>string)TokenURI;
    mapping (uint => uint) totalNFTsMinted;
    // NFT ID to Price
    mapping (address=>mapping(uint=>uint)) NFT_Price;

    // Too Check token Exixtance
    
    modifier TokenNotExist( uint nftId){
        require(nftExists[nftId]==false , "Token Already Exists");
        _;
    }
    modifier contractIsNotPaused(){
        require (IsPaused == false, "Contract is Paused" );
        _;
    }
    //Price of 1 copy of NFT will be returned
    function CheckNftPrice(address owner, uint id) public view returns(uint){
        return NFT_Price[owner][id];
    }

    modifier OnlyOwner {
        require(_msgSender() == Owner, "StageNFT Owner can Access");
        _;
    }

    bool public IsPaused = true;
    address payable public  Owner;
    // string public _name;
    
    constructor (){
        // _name = name;
        Owner = payable(msg.sender);
    }
    function name() public pure returns (string memory){
        return "DStageNFT_1155";
    }

    function symbol() public pure returns (string memory){
        return "Stage_1155_NFT";
    }

    /* Direct Minting on Blockchain 
    ** No Fee and Taxes on Minting
    ** Want to mint his own Address direct BVlockchain
    ** TokenURI is IPFS hash and will Get from Web3
    */

    uint8 _serviceFee;
    function setServiceFee(uint8 serviceFee) external OnlyOwner contractIsNotPaused {
        require(serviceFee != _serviceFee, "Cannot set same Service Fee");
        _serviceFee = serviceFee;
    }
    function simpleMint (uint nftId, uint numOfCopies,  bytes memory data, string memory tokenURI, uint RoyaltyValueOfMinter ) contractIsNotPaused TokenNotExist(nftId) public {
        _mint(_msgSender(), nftId, numOfCopies, data);
        TokenURI[nftId] = tokenURI;
        //Royalties must be < 50%
        //We should discuss how much minimum Royalities should be allowed
        //Please note this in Spread Sheet
        _setTokenRoyalty(nftId, payable(_msgSender()), RoyaltyValueOfMinter);
        nftExists[nftId] = true;
        Nft[_msgSender()][nftId].Exists=true;
        totalNFTsMinted[nftId]+=numOfCopies;
    }
    function changeNFTPrice(uint nftID, uint newPrice)  external {
        require(Nft[_msgSender()][nftID].Exists==true, "NFT not exist or you are not owner of this NFT");
        require(NFT_Price[_msgSender()][nftID] != newPrice, "Cannot set same Price");
        NFT_Price[_msgSender()][nftID]= newPrice;
    }
    // localy Minted and Want to Mint directly on Purchaser Address
    // Will Accept Payments For NFTs 
    // Deduct Royalties and StageNFT Fee
    // Buyer Is Initiating Transaction himself
    // MinterAddress, RoyaltyValueOfMinter, NftPrice will get from Web3
    //Creator has lazy minted the NFTs... Now buyer wants to mint it
    function mintLazyMintedNfts (address to, uint tokenID, uint numOfCopies, bytes memory data, string memory tokenURI, uint NftPrice, address payable MinterAddress, uint RoyaltyValueOfMinter) contractIsNotPaused public payable{
        // require(IsPaused == false, "Contract is Paused");
        // if local minter is the bChain minter than no fee should be charged to him
        if(to == MinterAddress)
        {
            _mint(to, tokenID, numOfCopies, data);    
            TokenURI[tokenID] = tokenURI;
            NFT_Price[to][tokenID]= NftPrice;
            _setTokenRoyalty(tokenID,MinterAddress, RoyaltyValueOfMinter);
            totalNFTsMinted[tokenID]+=numOfCopies;
            Nft[to][tokenID].Exists = true;
        }
        else
        {        
        require(msg.value>=NftPrice*numOfCopies, "Error! Insufficient Balance ");
        _mint(to, tokenID, numOfCopies, data);
        TokenURI[tokenID] = tokenURI;
        NFT_Price[to][tokenID]= NftPrice;
        _setTokenRoyalty(tokenID,MinterAddress, RoyaltyValueOfMinter);
        //Send Amount to Local Minter
        // Deduct Royalties
        _royaltyAndStageNFTFee(NftPrice*numOfCopies, RoyaltyValueOfMinter, MinterAddress, MinterAddress, _serviceFee );
        totalNFTsMinted[tokenID]+=numOfCopies;
        Nft[to][tokenID].Exists = true;
        }
    }
    function getTotalMintedNfts(uint nftId) external view returns (uint){
        return totalNFTsMinted[nftId];
    }
    // Batch Minting Public Function
    // Direct minting on Blockchain 
    function MintBatch(address to, uint[] memory tokenIds, uint[] memory numOfCopies, string[] memory TokenUriArr, bytes memory data, uint[] memory RoyaltyValue) external contractIsNotPaused{
        //require(IsPaused == false, "Contract is Paused");
        require((tokenIds.length == TokenUriArr.length) && (TokenUriArr.length == RoyaltyValue.length), "TokenURI and Token ID Length Should be Same");
        _mintBatch(to, tokenIds, numOfCopies, TokenUriArr ,data, RoyaltyValue );
    }

    //Batch Minting Direct on Blockchain Internal Function
    function _mintBatch(address to,uint256[] memory ids,uint256[] memory amounts,string[] memory Uri,bytes memory data, uint[] memory RoyaltyValue) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        address operator = _msgSender();
        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);
        //Add check that he is only able to Add tokens in his own NFts if ID exists already
        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
            TokenURI[ids[i]] = Uri[i];
            _setTokenRoyalty(ids[i], payable(_msgSender()), RoyaltyValue[i]);
        }
        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    function IncrementInExistingTokens(address minterAddress, uint nftId, uint numOfCopies, bytes memory data) public {
        //Check TokenID Already has Balance or Not
        //Returns the amount of tokens of token type `id` owned by `account`.
        require(balanceOf(minterAddress,nftId)>0, "Error! Use Function With URI");
        //Only Owner of that Token can Increment check owner or token Now check Approved or not
        require(_msgSender() == minterAddress || isApprovedForAll(minterAddress, _msgSender()), "Only Owner and Approved Address can Increment");
        _mint(minterAddress, nftId, numOfCopies , data);
    }

    /*  function BuyerOfNft
    **  Will Transfer NFTs anxd Deduct Amount and Will forward to Addresses 
    **  Will just Pay royalties 
    **  Get minter Address from Struct recipient 
    **  Get NFT price
    */
    function SafeTransferFromDstage1155 (address payable from, address payable to, uint tokenId, uint numOfCopies, bytes memory data) external {
        StageNFTsafeTransferFrom( from,  to,  tokenId,  numOfCopies,   data );
    }
    function StageNFTsafeTransferFrom(address from, address to, uint id, uint numOfCopies, bytes memory data ) internal {
        _royaltyAndStageNFTFee( ((NFT_Price[from][id])*numOfCopies), _royalties[id].percentage, _royalties[id].recipient, payable(from),_serviceFee);
        _safeTransferFrom(from, to, id, numOfCopies, data);
        //delete NFT_Price[from][id];
        NFT_Price[to][id]= msg.value/numOfCopies;  
    } 
    function getMyBalance() public view returns (uint){
        return deposits[_msgSender()];
    }
    //Function To Switch Sale State in Bool
    function switchSaleState() public OnlyOwner {
        if (IsPaused == true){
            IsPaused = false;
        }
        else {
            IsPaused = true;
        }
    }

    //To WithDraw Ammount from Contract to Owners Address 
    function withDraw(address payable to, uint amount) public payable OnlyOwner {
        uint Balance = address(this).balance;
        require(amount < Balance,"Not enough Balance Available");
        to.transfer(amount);
    }   

    //To Check Contract Balance in Wei
    function ContractBalance() public view OnlyOwner returns (uint){
        return address(this).balance;
    }
    //Return Tokens IPFS URI against Address and ID
    function TokenUri(uint id) public view returns(string memory){
        require(bytes(TokenURI[id]).length != 0, "Token ID Does Not Exist");
        return TokenURI[id];
    }

    //Extra Function For Testing
    function checkFirstMinter( uint t_id ) view public returns(royaltyInfo memory){
        royaltyInfo memory object = _royalties[t_id]; 
        return object;
    }
    function mintForOpenBidding (uint nftId, uint numOfCopies,  bytes memory data, string memory tokenURI, uint RoyaltyValueOfMinter ) contractIsNotPaused TokenNotExist(nftId) external{
        simpleMint (nftId,  numOfCopies,  data, tokenURI, RoyaltyValueOfMinter );
        _placeNftForBids(_msgSender(),nftId);
    }
    function mintForFixedPrice (uint nftId, uint numOfCopies,  bytes memory data, string memory tokenURI, uint RoyaltyValueOfMinter, uint fixPriceOfNft ) contractIsNotPaused TokenNotExist(nftId) external{
        simpleMint (nftId,  numOfCopies,  data, tokenURI, RoyaltyValueOfMinter );
        //_placeNftForFixedPrice(_msgSender(), nftId , fixPriceOfNft);
        NFT_Price[_msgSender()][nftId] = fixPriceOfNft;
        Nft[_msgSender()][nftId].salestatus = status.OnfixedPrice;
        Nft[_msgSender()][nftId].minimumPrice = fixPriceOfNft;

    }
    function placeNftForFixedAmount(uint nftId, uint fixPriceOfNft ) external {
        _placeNftForFixedPrice( _msgSender() , nftId, fixPriceOfNft );
        NFT_Price[_msgSender()][nftId] = fixPriceOfNft;
    }
    function purchaseAgainstFixedPrice ( address from, address to, uint nftId, uint numOfCopies) external payable onFixedPrice(from,nftId){
        require(msg.value==(NFT_Price[from][nftId])*numOfCopies, "Not Enough amount Provided");
         if (deposits[_msgSender()] < Nft[from][nftId].minimumPrice*numOfCopies){
             depositAmount(_msgSender(), msg.value);
         }
        require(numOfCopies > 0, "numOfCopies > 0" );
        deductAmount(_msgSender(), NFT_Price[from][nftId]*numOfCopies);
        StageNFTsafeTransferFrom(from,  to,  nftId, numOfCopies, "Data");
        Nft[to][nftId].Exists = true;
        //Nft[to][nftId].salestatus = status.notOnfixedPrice;
        
    }
    function placeNftForOpenBidding(uint nftId) external{
        _placeNftForBids(_msgSender(),nftId);        
    }
    //function for testing
    function removeFromFixedPrice(uint nftId) external 
    {
        _removeFromFixedPrice(_msgSender(), nftId);
    }
    function addBid (address nftOwner, uint nftId, uint bidAmount, uint numOfCopies) external payable{
        if (deposits[_msgSender()] < bidAmount){
            depositAmount(_msgSender(), msg.value);
        }
        require(deposits[_msgSender()] >= bidAmount && numOfCopies > 0 && nftExists[nftId] == true, "Error while Purchasing" );
        _pushBidingValues ( nftOwner,_msgSender(), nftId, bidAmount, numOfCopies);
    }
    function acceptBids (uint nftId,uint index ) external onBidding(_msgSender(), nftId) {
        // Check has enough number of copies 
        NftDetails memory obj = Nft[_msgSender()][nftId];
        require (obj.Exists == true && deposits[obj.bidderAddress[index]]>= obj.bidAmount[index], "Error while Accepting Bids" );
        deductAmount(obj.bidderAddress[index], obj.bidAmount[index]);
        StageNFTsafeTransferFrom(_msgSender(), obj.bidderAddress[index], nftId,  obj.numOfCopies[index], "" ); 
    }

}