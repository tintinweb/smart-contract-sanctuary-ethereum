// SPDX-License-Identifier: MIT
// Constraints for wei and Ethers in fixed amount and royalties
// Burn only owner // Open Bidding 
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;
import "./ERC1155.sol"; 
import "./ERC1155Burnable.sol";
import "./OnyxNft1155Royalties.sol";
import "./OnyxNft1155Auctions.sol";
contract OnyxNft1155 is ERC1155, ERC1155Burnable, OnyxNftErc20 ,OnyxNft1155Auction { 

    mapping (uint => bool) nftExists;
    mapping (uint=>string)TokenURI;
    
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

    function CheckNftPrice(address owner, uint id) public view returns(uint){
        return NFT_Price[owner][id];
    }

    modifier OnlyOwner {
        require(_msgSender() == Owner, "OnyxNft Owner can Access");
        _;
    }

    bool public IsPaused = true;
    address payable public  Owner;
    string private _name;
    
    constructor (string memory name){
        _name = name;
        Owner = payable(msg.sender);
    }

    /* Direct Minting on Blockchain 
    ** No Fee and Taxes on Minting
    ** Want to mint his own Address direct BVlockchain
    ** TokenURI is IPFS hash and will Get from Web3
    */
    function simpleMint (uint nftId, uint amount,  bytes memory data, string memory tokenURI, uint RoyaltyValueOfMinter ) contractIsNotPaused TokenNotExist(nftId) public {
        _mint(_msgSender(), nftId, amount, data);
        TokenURI[nftId] = tokenURI;
        _setTokenRoyalty(nftId, payable(_msgSender()), RoyaltyValueOfMinter);
        nftExists[nftId] = true;
        Nft[_msgSender()][nftId].Exists=true;
    }

    // localy Minted and Want to Mint directlty on Purchaser Address
    // Will Accept Payments For NFTs 
    // Deduct Royalties and OnyxNft Fee
    // Buyer Is Insiating Transaction himself
    // MinterAddress, RoyaltyValueOfMinter, NftPrice will get from Web3
    function LocalMintedNfts (address to, uint id, uint amount, bytes memory data, string memory tokenURI, uint NftPrice, address payable MinterAddress, uint RoyaltyValueOfMinter) public payable{
        require(IsPaused == false, "Contract is Paused");
        require(msg.value>=NftPrice*amount, "Error! Insufficient Balance ");
        _mint(to, id, amount, data);
        TokenURI[id] = tokenURI;
        NFT_Price[to][id]= NftPrice;
        _setTokenRoyalty(id,MinterAddress, RoyaltyValueOfMinter);
        //Send Amount to Local Minter
        // Deduct Royalties
        _royaltyAndOnyxNftFee(NftPrice*amount, RoyaltyValueOfMinter, MinterAddress, MinterAddress );
    }
    // Batch Minting Public Function
    // Direct minting on Blockchain 
    function MintBatch(address to, uint[] memory ids, uint[] memory amounts, string[] memory TokenUriArr, bytes memory data, uint[] memory RoyaltyValue) external{
        
        require(IsPaused == false, "Contract is Paused");
        require(ids.length == TokenUriArr.length, "TokenURI and Token ID Length Should be Same");
        _mintBatch(to, ids, amounts, TokenUriArr ,data, RoyaltyValue );
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

    function IncrementInExistingTokens(address Add, uint id, uint Amount, bytes memory data) public {
        //Check TokenID Already has Balance or Not
        require(balanceOf(Add,id)>0, "Error! Use Function With URI");
        //Only Owner of that Token can Increment check owner or token Now check Approved or not
        require(_msgSender() == Add || isApprovedForAll(Add, _msgSender()), "Only Owner and Approved Address can Increment");
        _mint(Add, id, Amount , data);
    }

    /*  function BuyerOfNft
    **  Will Transfer NFTs and Deduct Amount and Will forward to Addresses 
    **  Will just Pay royalties 
    **  Get minter Address from Struct recipient 
    **  Get NFT price
    */
    function OnyxNftsafeTransferFrom(address from, address to, uint id, uint amount, bytes memory data ) internal {
        _royaltyAndOnyxNftFee( ((NFT_Price[from][id])*amount), _royalties[id].amount, _royalties[id].recipient, payable(from));
        _safeTransferFrom(from, to, id, amount, data);
        delete NFT_Price[from][id];
        NFT_Price[to][id]= msg.value/amount;
        Nft[to][id].Exists = true;
    } 
    
    //Function To Switch Sale State in Bool
    function SwitchSaleState() public OnlyOwner {
        if (IsPaused == true){
            IsPaused = false;
        }
        else {
            IsPaused = true;
        }
    }

    //To WithDraw All Ammount from Contract to Owners Address 
    function withDraw(address payable to) public payable OnlyOwner {
        uint Balance = address(this).balance;
        require(Balance > 0 wei, "Error! No Balance to withdraw"); 
        to.transfer(Balance);
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
    function mintForOpenBidding (uint nftId, uint amount,  bytes memory data, string memory tokenURI, uint RoyaltyValueOfMinter ) contractIsNotPaused TokenNotExist(nftId) external{
        simpleMint (nftId,  amount,  data, tokenURI, RoyaltyValueOfMinter );
        _placeNftForBids(_msgSender(),nftId);
    }
    function mintForFixedPrice (uint nftId, uint amount,  bytes memory data, string memory tokenURI, uint RoyaltyValueOfMinter, uint fixPriceOfNft ) contractIsNotPaused TokenNotExist(nftId) external{
        simpleMint (nftId,  amount,  data, tokenURI, RoyaltyValueOfMinter );
        _placeNftForFixedPrice(_msgSender(), nftId , fixPriceOfNft);
        NFT_Price[_msgSender()][nftId] = fixPriceOfNft;

    }
    function placeNftForOpenBidding(uint nftId) external{
        _placeNftForBids(_msgSender(),nftId);        
    }
    function placeNftForFixedAmount(uint nftId, uint fixPriceOfNft ) external {
        _placeNftForFixedPrice( _msgSender() , nftId, fixPriceOfNft );
        NFT_Price[_msgSender()][nftId] = fixPriceOfNft;
    }
    function purchaseAgainstFixedPrice ( address from, address to, uint nftId, uint amountOfNft) external payable{
        if (deposits[_msgSender()] < NFT_Price[from][nftId]*amountOfNft){
            depositBidAmmount(_msgSender(), msg.value);
        }
        require(NFT_Price[from][nftId]*amountOfNft <= deposits[_msgSender()] && amountOfNft > 0, "Error while Purchasing" );
        deductAmount(_msgSender(), NFT_Price[from][nftId]*amountOfNft);
        OnyxNftsafeTransferFrom(from,  to,  nftId, amountOfNft, "Data");
    }
    function removeFromSale(uint nftId) external 
    {
        _removeFromSale(_msgSender(), nftId);
    }
    function addBid (address nftOwner, uint nftId, uint bidAmount, uint numOfCopies) external payable{
        if (deposits[_msgSender()] < bidAmount){
            depositBidAmmount(_msgSender(), msg.value);
        }
        require(deposits[_msgSender()] >= bidAmount && numOfCopies > 0 && nftExists[nftId] == true, "Error while Purchasing" );
        _pushBidingValues ( nftOwner,_msgSender(), nftId, bidAmount, numOfCopies);
    }
    function acceptBids (uint nftId,uint index ) external onBidding(_msgSender(), nftId) {
        // Check has enough number of copies 
        NftDetails memory obj = Nft[_msgSender()][nftId];
        require (obj.Exists == true && deposits[obj.bidderAddress[index]]>= obj.bidAmount[index], "Error while Accepting Bids" );
        deductAmount(obj.bidderAddress[index], obj.bidAmount[index]);
        OnyxNftsafeTransferFrom(_msgSender(), obj.bidderAddress[index], nftId,  obj.numOfCopies[index], "" ); 
    }

}