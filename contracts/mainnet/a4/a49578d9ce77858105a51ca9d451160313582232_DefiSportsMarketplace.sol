//SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./IERC20.sol";
import "./INFTContract.sol";
// import "./ConsoleLog.sol";


contract DefiSportsMarketplace is Ownable {
    using SafeMath for uint256;
    using Address for address;

    enum EOrderType{
        None,
        Fixed,
        Auction
    }

    enum EOrderStatus{
        None,
        OpenForTheMarket,
        MarketCancelled,
        MarketClosed
    }


    struct Market{
        address contractAddress;
        uint256 tokenId;
        EOrderType orderType;
        EOrderStatus orderStatus;
        uint256 askAmount;
        uint256 maxAskAmount;
        address payable currentOwner;
        address newOwner;
    } 


    IERC20 public _wrapToken;
    uint256 public _feePercentage;
    address  payable public _feeDestinationAddress;
    mapping (bytes32 => Market) public markets;


    constructor(address wrapToken,
                uint256 feePercentage,
                address payable feeDestinationAddress){
        _feePercentage = feePercentage;
        _feeDestinationAddress = feeDestinationAddress;
        _wrapToken = IERC20(wrapToken);
    }
    function setWrapToken(address wrapToken) external onlyOwner{
        _wrapToken = IERC20(wrapToken);
    }
    function getWrapToken() external view returns(address wrapToken){
        return address(_wrapToken);
    }
    function setFeePercentage (uint256 value) external onlyOwner{
        _feePercentage = value; 
    }

    function setFeeDestinationAddress (address payable value) external onlyOwner{
        _feeDestinationAddress = value; 
    }

    function getPrivateUniqueKey(address nftContractId, uint256 tokenId) private pure returns (bytes32){
        return keccak256(abi.encodePacked(nftContractId, tokenId));
    }

    function getMarketObj(address nftContractId, uint256 tokenId) public view returns (Market memory){
        bytes32 uniqueKey = getPrivateUniqueKey(nftContractId,tokenId);

        return markets[uniqueKey];
    }

    function openMarketForFixedType(address nftContractId, uint256 tokenId, uint256 price ) external{
        openMarket(nftContractId,tokenId,price,EOrderType.Fixed, 0);
    }

    function openMarketForAuctionType(address nftContractId, uint256 tokenId, uint256 price, uint256 maxPrice) external{
        openMarket(nftContractId,tokenId,price,EOrderType.Auction, maxPrice);
    }

    function openMarket(address nftContractId, uint256 tokenId, uint256 price, EOrderType orderType, uint256 maxPrice) private{
        bytes32 uniqueKey = getPrivateUniqueKey(nftContractId,tokenId);

        /// For update lisitng.
        if (markets[uniqueKey].orderStatus == EOrderStatus.OpenForTheMarket) {
            address nftCurrentOwner = INFTContract(nftContractId).ownerOf(
                tokenId );
            if ( nftCurrentOwner == msg.sender &&
                nftCurrentOwner != markets[uniqueKey].currentOwner) {
                markets[uniqueKey].orderType = orderType;
                markets[uniqueKey].askAmount = price;
                markets[uniqueKey].maxAskAmount = maxPrice;
                markets[uniqueKey].currentOwner = payable(nftCurrentOwner);
                return;
            } else if (nftCurrentOwner == markets[uniqueKey].currentOwner) {
                revert("Market order is already opened");
            } else {
                revert("Not authorized");
            }
        }
        if(price <= 0){
            revert ("Price Should be greater then 0");
        }

        if(orderType == EOrderType.Auction && price > maxPrice){
            revert ("end Price Should be greater then price");
        }

        markets[uniqueKey].orderStatus = EOrderStatus.OpenForTheMarket;
        markets[uniqueKey].orderType = orderType;
        markets[uniqueKey].askAmount = price;
        markets[uniqueKey].maxAskAmount = maxPrice;
        markets[uniqueKey].contractAddress = nftContractId;
        markets[uniqueKey].tokenId = tokenId;
        markets[uniqueKey].currentOwner = payable(msg.sender);
    }

    function closeMarketForFixedType(address nftContractId, uint256 tokenId ) external payable{ 
        bytes32 uniqueKey = getPrivateUniqueKey(nftContractId,tokenId);
        
        if(markets[uniqueKey].orderStatus == EOrderStatus.OpenForTheMarket){
        
            if(markets[uniqueKey].orderType == EOrderType.None){
                revert ("nft not opened");
            }
            else if(markets[uniqueKey].orderType == EOrderType.Fixed){
                if(markets[uniqueKey].askAmount < msg.value){
                    revert ("Value not matched");
                }
            }else if (markets[uniqueKey].orderType == EOrderType.Auction){
            if(markets[uniqueKey].maxAskAmount < msg.value){
                    revert ("Value not matched");
                }
            }


            INFTContract nftContract = INFTContract(markets[uniqueKey].contractAddress);

            //platform fee
            uint256 fee = getFeePercentage(msg.value, _feePercentage);

            require(address(this).balance >= fee, "Insufficient balance. FEE"); /// remove require

            _feeDestinationAddress.transfer(fee);

            // creator royality 
            (address creator, uint256 royality) = nftContract.getRoyalityDetails(tokenId);
            uint256 amtforCreator = getFeePercentage(msg.value,royality);

            require(address(this).balance >= amtforCreator, "Insufficient balance. Amount for creator"); /// remove require

            payable(creator).transfer(amtforCreator); 
            
            require(address(this).balance >= (msg.value.sub(fee+amtforCreator)), "Insufficient balance. currentOwner share"); /// remove require
            
            markets[uniqueKey].currentOwner.transfer(msg.value.sub(fee+amtforCreator));
            // transfer nft to new user 
            nftContract.safeTransferFrom(markets[uniqueKey].currentOwner, msg.sender, tokenId);

            // nft market close
            markets[uniqueKey].orderStatus = EOrderStatus.MarketClosed;
            markets[uniqueKey].newOwner = msg.sender;

        }else{
            revert ("Market order is not opened");
        }
    }

    function closeMarketForAuctionType(address nftContractId, uint256 tokenId, uint256 price, address buyerAccount ) external{
        bytes32 uniqueKey = getPrivateUniqueKey(nftContractId,tokenId);

        if(markets[uniqueKey].currentOwner != msg.sender){
            revert ("only for market operator");
        }    
        if(markets[uniqueKey].orderStatus == EOrderStatus.OpenForTheMarket){

            if(markets[uniqueKey].askAmount < price){
                INFTContract nftContract = INFTContract(markets[uniqueKey].contractAddress);

                //platform fee
                uint256 fee = getFeePercentage(price, _feePercentage);
                
                _wrapToken.transferFrom(buyerAccount,_feeDestinationAddress,fee);

                // Creator Royality 
                (address creator, uint256 royality) = nftContract.getRoyalityDetails(tokenId);
                uint256 amtforCreator = getFeePercentage(price,royality);
                _wrapToken.transferFrom(buyerAccount,creator,amtforCreator);
                //seller amouynt trans 
                _wrapToken.transferFrom(buyerAccount,markets[uniqueKey].currentOwner,price.sub(fee+amtforCreator));

                // transfer nft to new user 
                nftContract.safeTransferFrom(markets[uniqueKey].currentOwner, buyerAccount, tokenId);

                // nft market close
                markets[uniqueKey].orderStatus = EOrderStatus.MarketClosed;
                markets[uniqueKey].newOwner = buyerAccount;

            }else{
                revert ("Value not matched");
            }
        }else{
            revert ("Market order is not opened");
        }
    }

    function getFeePercentage(uint256 price, uint256 percent) private pure returns (uint256){
        return price.mul(percent).div(100);
    }

    function cancel(address nftContractId, uint256 tokenId) external {
        bytes32 uniqueKey = getPrivateUniqueKey(nftContractId, tokenId);

        if ( INFTContract(nftContractId).ownerOf(tokenId) == msg.sender || owner() == msg.sender ) {
            if (
                markets[uniqueKey].orderStatus == EOrderStatus.OpenForTheMarket
            ) {
                markets[uniqueKey].orderStatus = EOrderStatus.MarketCancelled;
            } else {
                revert("Market order is not opened");
            }
        } else {
            revert("Not authorized");
        }
    }
   /// payment 
    function getTokenBalance(address _tokenAddress) public view returns (uint256 _balance) {
        return IERC20(_tokenAddress).balanceOf(address(this));
    }

    function withdrawToken(address _tokenAddress, address _destionation, uint256 _amount) public onlyOwner{
        IERC20(_tokenAddress).transfer(_destionation, _amount);
    }

    function withdrawCurrency(address _destionation, uint256 _amount) public onlyOwner {
        payable(_destionation).transfer(_amount);
    }

    receive() external payable {
    }

    fallback() external payable {
    }
}