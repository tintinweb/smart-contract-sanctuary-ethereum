// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
//pragma experimental ABIEncoderV2;

import "./VcgExchangeBase.sol";

enum TokenType {ETH, ERC20}
enum StandType {ERC721,ERC1155}
enum BaseContractType {Contract721,Contract1155,Contract20}


contract ExchangeVcgSale is Authentication,Commission,ReentrancyGuardUpgradeable{
    using Strings for string;
    using Address for address;    
    using SafeMath for *;

    string constant public _name = "Exchange contract as ERC721 NFT exchange with ETH or Vcg ERC20 version 1.1";    
    
    struct NftGoods {
        address _nftContractAddress;
        StandType _contractType;
        uint256 _tokenID;
        uint256 _values;
        address payable _sellerAddress;
        uint256 _expectedAmount;
        uint256 _startTime;
    }
    
    mapping(uint256 => NftGoods) private _saleGoodsAddr;//token ID对应的商品合约地址

    event SellAmountDetail(uint256 indexed goodsID,
            uint256 indexed sellerReceived,
            uint256 indexed creatorReceived,
            uint256  platformReceived);
    
    function _onBuy(NftGoods storage goods, uint256 saleTokenID, uint256 value) internal
            returns(bool) {
        require((saleTokenID == goods._tokenID) 
        && (block.timestamp >= goods._startTime) && (goods._values >= value), "Buy Error.");
        goods._values = goods._values.sub(value);//It worked?
        return _isOnSale(goods);
    }
    function _isOnSale(NftGoods memory goods) internal view returns(bool) {
        return((block.timestamp >= goods._startTime)
        && (goods._values > 0) 
        );
    }
    function _isApprovedOrOwner(address nftContractAddress, StandType contractType, address seller, 
        uint256 tokenId, uint256 value) internal view 
        returns (bool) {
        
        if(contractType == StandType.ERC721)
        {
            address owner = IERC721(nftContractAddress).ownerOf(tokenId);   
            return (seller == owner || 
                IERC721(nftContractAddress).getApproved(tokenId) == seller || 
                IERC721(nftContractAddress).isApprovedForAll(owner, seller));
        }
        else if(contractType == StandType.ERC1155)
        {
            return IVcgERC1155Token(nftContractAddress).isApprovedOrOwner(address(0),seller,tokenId,value);
        }
        else
        {
            revert();
        }
    }
    function _offSale(NftGoods memory goods) internal pure { 
        goods._tokenID = 0;
        goods._values = 0;
        goods._sellerAddress = payable(address(0));
        goods._expectedAmount = 0;
        goods._startTime = 0;        
    }
    
    function _onSale(NftGoods storage goods,address ContractAddress,
        uint256 saleTokenID, uint256 value,address payable sellerAddress,
        uint256 amount, uint256 startTime) internal returns (bool) {  
        require(true == Address.isContract(ContractAddress), 
            "ContractAddress is not a contract address!");

        //set _nftContractAddress if the address is a ERC721 token address.
        if(IERC721(ContractAddress).supportsInterface(0x80ac58cd))
        {
            goods._nftContractAddress = ContractAddress;
            goods._contractType = StandType.ERC721;
        }
        else if(IERC1155(ContractAddress).supportsInterface(0x0e89341c))
        {
            goods._nftContractAddress = ContractAddress;
            goods._contractType = StandType.ERC1155;
        }
        else
        {
            revert();
        }
        if(sellerAddress == address(0))
        {
            return false;
        }
        if(goods._contractType == StandType.ERC721){
            require(1 == value, "721 Asset value MUST be 1.");
        }

        if(!_isApprovedOrOwner(goods._nftContractAddress,goods._contractType,
            sellerAddress,saleTokenID,value)) 
        {
            return false;
        }   

        goods._tokenID = saleTokenID;
        goods._values = value;
        goods._sellerAddress = sellerAddress;
        goods._expectedAmount = amount;
        goods._startTime = startTime;      

        return true;
    }  


    function isOnSale(address nftContractaddr,uint256 goodsID) public view returns(bool) {
        NftGoods memory goodsAddress = _saleGoodsAddr[goodsID];
        if( address(0) != goodsAddress._nftContractAddress && _isOnSale(goodsAddress) )
        {
            return true;
        }
        require(goodsAddress._nftContractAddress == nftContractaddr, "nftContractAddr mismatch Goods.");
        return false;
    }   

    function getSaleGoodsInfo(address nftContractaddr,uint256 goodsID) external view 
    returns (address nftContractAddress, StandType, uint256 tokenid, uint256 values,
        TokenType expectedTokenType,address sellerAddress,address expectedTokenAddress,
        uint256 expectedAmount,uint startTime,bool isForSale) {
        NftGoods memory goodsAddress = _saleGoodsAddr[goodsID];
        require(address(0) != goodsAddress._nftContractAddress, "It's not an invalid goods.");
        require(goodsAddress._nftContractAddress == nftContractaddr, "nftContractAddr mismatch Goods.");
        //return( _getGoodsInfo(goodsAddress) );
        return (goodsAddress._nftContractAddress,goodsAddress._contractType,
        goodsAddress._tokenID,goodsAddress._values,
        TokenType.ETH,address(0),
        goodsAddress._sellerAddress,goodsAddress._expectedAmount,goodsAddress._startTime,true);
    }    

   
    function hasRightToSale(address nftContractaddr,StandType stand,address owner, 
    address targetAddr, uint256 tokenId,uint256 value) public view returns(bool) {
  
        if(stand == StandType.ERC721)
            return (IVcgERC721TokenWithRoyalty(nftContractaddr).isApprovedOrOwner(targetAddr, tokenId));
        else if(stand == StandType.ERC1155)
            return (IVcgERC1155Token(nftContractaddr).isApprovedOrOwner(owner,targetAddr, tokenId,value));
        else
            return false;
    }

    function IsTokenOwner(address nftContractaddr,StandType stand,address targetAddr, uint256 tokenId) public view returns(bool) {
        if(stand == StandType.ERC721){

            if(!IVcgERC721TokenWithRoyalty(nftContractaddr).exists(tokenId)){
                return false;
            }
            
            return (targetAddr == IVcgERC721TokenWithRoyalty(nftContractaddr).ownerOf(tokenId) );
        }
        else if(stand == StandType.ERC1155){
            return IVcgERC1155Token(nftContractaddr).isOwner(targetAddr,tokenId);
        }
        else
            return false;       
    }

 
    function hasEnoughTokenToBuy(address nftContractaddr,address buyer, 
    uint256 goodsID, uint256 value) public view returns(bool) {
        
        if( (address(0) == buyer) 
        //|| (!IVcgERC721TokenWithRoyalty(nftContractaddr).exists(tokenId))
        )
        {
            return false;
        }

        NftGoods memory goodsAddress = _saleGoodsAddr[goodsID];
        //address goodsAddress = _saleGoodsAddr[goodsID];
        if(address(0) == goodsAddress._nftContractAddress)
        {
            return false;
        }
        require(goodsAddress._nftContractAddress == nftContractaddr, "nftContractAddr mismatch Goods.");
        if(goodsAddress._contractType == StandType.ERC721)
            return buyer.balance >= goodsAddress._expectedAmount;
        else if(goodsAddress._contractType == StandType.ERC1155)
            return buyer.balance >= goodsAddress._expectedAmount*value;
        else
            return false;
    }

    
    function sellNFT(address nftContractAddr,StandType stand,uint256 goodsID,uint256 saleTokenID, 
        uint256 value, TokenType expectedTokenType, address tokenAddress, 
        uint256 amount, uint256 startTime) external {
        bool result;
        //require(!Address.isContract(msg.sender),"the sender should be a person, not a contract!");

        require(IsTokenOwner(nftContractAddr,stand,msg.sender, saleTokenID),"the sender isn't the owner of the token id nft!");

        require((expectedTokenType == TokenType.ETH) || (expectedTokenType == TokenType.ERC20),
                "expectedTokenType must be ETH or ERC20 in this version!");

        
        /*2021.8.18 如果提交上架时间早于块当前时间，以块上时间作为上架时间。
        require((startTime >= block.timestamp), "startTime for sale must be bigger than now.");
        */
        if(startTime < block.timestamp)
        {
            startTime = block.timestamp;
        }
        
        require(hasRightToSale(nftContractAddr,stand,msg.sender,address(this), 
            saleTokenID,value),"the exchange contracct is not the approved of the TOKEN.");

        if( address(0) != _saleGoodsAddr[goodsID]._nftContractAddress )
        {
            require(_saleGoodsAddr[goodsID]._nftContractAddress == nftContractAddr, "nftContractAddr mismatch Goods.");  
            //result = goods.onSale(saleTokenID,value,payable(msg.sender),amount, startTime);
            //require(result, "reset goods on sale is failed.");
            _saleGoodsAddr[goodsID]._expectedAmount = amount;
        }
        else
        {
            NftGoods storage goodsAddress = _saleGoodsAddr[goodsID];
            result = _onSale(goodsAddress,nftContractAddr,saleTokenID,value, payable(msg.sender), 
                amount, startTime);
            require(result, "set goods on sale is failed.");           
            //_saleGoodsAddr[goodsID] = address(goods);
        }
    }    

    function cancelSell(address nftContractAddr,uint256 goodsID) external {
        //require(!Address.isContract(msg.sender),"the sender should be a person, not a contract!");
        
        //address goodsAddress = _saleGoodsAddr[goodsID];
        NftGoods memory goodsAddress = _saleGoodsAddr[goodsID];
        require(address(0) != goodsAddress._nftContractAddress,"Must be a vaild goods");
        require(goodsAddress._nftContractAddress == nftContractAddr, "nftContractAddr mismatch Goods.");
        require(isOwner()||
        isManager(msg.sender)||
        (goodsAddress._sellerAddress == msg.sender),
        "the sender isn't the owner of the token id nft!");

        delete _saleGoodsAddr[goodsID];
    } 

    function buyNFT(address nftContractAddr,uint256 goodsID,uint256 value) payable external nonReentrant {   
        require(isOnSale(nftContractAddr,goodsID),"The nft token(tokenID) is not on sale.");

        //当前发起者是否有足够的余额购买,这里判断是有问题的，msg.sender.balance是要减去msg.value的
        //require(hasEnoughTokenToBuy(nftContractAddr,msg.sender, goodsID, value), "No enough token to buy the NFT(tokenID)");
        
        NftGoods storage goodsAddress = _saleGoodsAddr[goodsID];

        require(0 != goodsAddress._tokenID, "The token ID isn't on sale status!");
        require(goodsAddress._nftContractAddress == nftContractAddr, "nftContractAddr mismatch Goods.");
        require(msg.sender != goodsAddress._sellerAddress, "the buyer can't be same to the seller.");
        require(hasRightToSale(nftContractAddr,goodsAddress._contractType,
        goodsAddress._sellerAddress,
        address(this), goodsAddress._tokenID,value),
        "the exchange contracct is not the approved of the TOKEN.");

        if(goodsAddress._contractType == StandType.ERC721){
            IVcgERC721TokenWithRoyalty(nftContractAddr).safeTransferFrom(goodsAddress._sellerAddress, msg.sender, goodsAddress._tokenID);

            uint256 amount = goodsAddress._expectedAmount;
            (address creator,uint256 royalty) = IVcgERC721TokenWithRoyalty(nftContractAddr).royaltyInfo(goodsAddress._tokenID,amount);
            (address platform,uint256 fee) = calculateFee(amount);
            //FIXME:the require raise abnormal gas used , why?
            require(msg.value == amount, "No enough send token to buy the NFT(tokenID)");
            require(amount > royalty + fee,"No enough Amount to pay except royalty and platform fee");
                
            if(creator != address(0) && royalty >0 && royalty < amount)
            {
                payable(creator).transfer(royalty);
                amount = amount.sub(royalty);
            }      
            if(fee > 0 && fee < amount)
            {
                //payable(platform).transfer(fee);
                //(bool sent, bytes memory data) = platform.call{value: fee}("");
                //require(sent, "Failed to send Ether to platform");
                Address.sendValue(payable(platform),fee);
                amount = amount.sub(fee);
            }
            goodsAddress._sellerAddress.transfer(amount);

            emit SellAmountDetail(goodsID,amount,royalty,fee);
            
            //_saleGoodsAddr[goodsID] = address(0x0);
            delete _saleGoodsAddr[goodsID];
        }
        else if(goodsAddress._contractType == StandType.ERC1155){
            IVcgERC1155Token(nftContractAddr).safeTransferFrom(goodsAddress._sellerAddress, 
            msg.sender, goodsAddress._tokenID,value,"");

            uint256 amount = goodsAddress._expectedAmount.mul(value);
            (address creator,uint256 royalty) = IVcgERC1155TokenWithRoyalty(nftContractAddr).royaltyInfo(goodsAddress._tokenID,amount);
            (address platform,uint256 fee) = calculateFee(amount);
        //FIXME: the require raise abnormal gas used , why?
            require(msg.value == amount, "No enough send token to buy the NFT(tokenID)");
            //require(amount > fee,"No enough Amount to pay except platform fee");
            require(amount > royalty + fee,"No enough Amount to pay except royalty and platform fee");
                
            if(creator != address(0) && royalty >0 && royalty < amount)
            {
                //payable(creator).transfer(royalty);
                Address.sendValue(payable(creator),royalty);
                amount = amount.sub(royalty);
            } 

            if(fee > 0 && fee < amount)
            {
                //payable(platform).transfer(fee);
                //(bool sent, bytes memory data) = platform.call{value: fee}("");
                //require(sent, "Failed to send Ether to platform");
                Address.sendValue(payable(platform),fee);
                amount = amount.sub(fee);
            }
            goodsAddress._sellerAddress.transfer(amount);
            emit SellAmountDetail(goodsID,amount,royalty,fee);
            
            bool onSale = _onBuy(goodsAddress,goodsAddress._tokenID,value);
            if(!onSale)
            {
                //_saleGoodsAddr[goodsID] = address(0x0);
                delete _saleGoodsAddr[goodsID];
            }
        }
    }       

    function destroyContract() external onlyOwner {
        selfdestruct(payable(owner()));
    } 
}