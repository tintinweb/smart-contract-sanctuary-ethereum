/*                                         .::::::.                                         
                                    :=**#%%%%%%%%%%*=:                                    
                                 :+%#=.  .#%%%%%%%+:      .                               
                               :*%%-       .         :**= -                               
                              +%%%%#-  .:-.           .=-#%*                              
                             #%%%%%%#      ::.     .:: :%%%%#.                            
                            #%%%%%%#             .:---:.+%%%%#                            
                           =%%%%%%%:           :#%%*%+%%--%%%%=                           
                           #%%%%%%#            +%%*-%-#%-:%%%%#                           
                           %%%%%%%#             -*#%%#+: *%%%%%                           
                           #%%%%%%%.           =*=.     *%%%%%#                           
                           +%%%%%%%#-                 -#%%%%%%+                           
                           .%%%%%%%+.                .*%%%%%%%.                           
                            :%%%%#.                    .=#%%%-                            
                             .#%*                    :.   :=:                             
                               =:    ..:-+:        -#:    .                               
                                 .        *:       %+    .                                
                                   .--.   :-       #%.  .                                 
                                    .+#   .         -:                                    
                                                                                          
                .==                                     =*=                               
                -%%                                     +#+                               
                -%%     :::.  . ...      .. ..  :::.    ...    .::.  ..   .::::.          
                -%%  .+%%**##%%:.#%-    *%+ *%#%**#%#-  +%=  =%%***%#%= .#%*++*%-         
                -%%  #%=    :%%: .#%=  *%=  *%+    .#%- +%= =%#     #%= -%#-:.            
                =%# .%%.     #%:   *%+#%-   *%:     +%+ +%= *%+     =%=  -+*##%#-         
         -*=:..-%%-  *%*:  .+%%:    *%%-    *%#:  .=%%. +%= :%%=...=%%=  :    =%%         
         .=*%%%#+:    -*#%%#=*#.   :%%:     *%+*#%%#=.  +#=   =*##*=*%= -*#%%%#+.         
                                  :%#.      *%-              ..    -%%:                   
                                 -%#.       *%-              +#%%%%#+.                 


*/

pragma solidity ^0.8.0;
/// @title Jaypigs
/// @author Youssefea - [email protected]
/// @notice You can use this contract for only the most basic simulation
/// @dev All function calls are currently implemented without side effects
/// @custom:experimental This is an experimental contract.



import {Address} from "./jaypigsTools.sol";
import "./jaypigsTools.sol";
import "./jaypigsStorage.sol";
import "./jaypigsRoyaltyManager.sol";
import "./jaypigsRewards.sol";

contract jaypigsMarket is IERC721Receiver,Ownable {

    //variables
    uint index;
    uint fee;
    address storageAddress;
    address royaltyManagerAddress;
    address rewardsAddress;
    
    //jaypigsStorage
    jaypigsStorage storageContract;

    //jaypigsRoyaltyManager
    jaypigsRoyaltyManager royaltyManagerContract;

    //jaypigsRewards
    jaypigsRewards rewardsContract;

    //events
     event Listed(address seller, address nftAddress, uint tokenID, uint price);
     event Unlisted(address nftAddress, uint tokenID);
     event Bought(address buyer, address nftAddress, uint tokenID);
     event OfferMade(address nftAddress, uint tokenID, address bidder, uint offer, uint offerIndex);
     event OfferAccepted(address nftAddress, uint tokenID, uint offerIndex );

    /**
     * @notice constructor
     * @dev Initializing all the necessary variables
     */

    constructor(){

         index=0;

         fee=10;

         storageAddress=address(0);
         royaltyManagerAddress=address(0);
         rewardsAddress=address(0);      


     }

    /**
     * @notice set the rewards address
     */
    function setRewards(address _rewardsAddress) external onlyOwner{
        rewardsAddress=_rewardsAddress;
        rewardsContract=jaypigsRewards(rewardsAddress);
    }    

    /**
     * @notice set the storage address
     */
    function setStorage(address _storageAddress) external onlyOwner{
        storageAddress=_storageAddress;
        storageContract=jaypigsStorage(storageAddress);
    }
    /**
     * @notice set the royalty manager address
     */
    function setRoyaltyManager(address _royaltyManagerAddress) external onlyOwner{
        royaltyManagerAddress=_royaltyManagerAddress;
        royaltyManagerContract=jaypigsRoyaltyManager(royaltyManagerAddress);
    }

    /**
     * @notice function to list/sell an NFT
     * @param nftAddress address of the collection
     * @param tokenID token ID for the item to list
     * @param price price of the item to be listed
     * @dev The commented part is to make the smart contract non custodial
     */

    function list(address nftAddress, uint256 tokenID, uint256 price) external  {

        //Require that the lister actually owns the NFT
        require(IERC721(nftAddress).ownerOf(tokenID)==msg.sender, "You do not own the token you are trying to list!");

        //the price can't be zero
        require(price>0, "The price can't be 0");

        //Requiring that the smart contract is approved to manage the depositer's assets
        require(IERC721(nftAddress).isApprovedForAll(msg.sender,address(this))==true, "You didn't approve the smart contract to manage your assets, please approve and come back");

        //Registering the price for the asset
        storageContract.setPrice(nftAddress,tokenID,price);

        //Transfering the asset from the depositor's wallet to the smart contract
        //IERC721(nftAddress).safeTransferFrom(msg.sender, address(this), _tokenID);

        //Updating the map
        storageContract.setDepositor(nftAddress,tokenID,msg.sender);

        //emiting the event
        emit Listed(msg.sender, nftAddress, tokenID, price);

    }

    /**
     * @notice function to buy an NFT
     * @param nftAddress address of the collection
     * @param tokenID token ID for the item to list
     * @dev The commented part is to make the smart contract non custodial
     */

    function buy(address nftAddress, uint256 tokenID) external payable {

        //Require that the price of the NFT is not zero
        require(storageContract.getPrice(nftAddress,tokenID)>0, "This NFT is not for sale");

        //Require that the price paid by the buyer is equal to the price demanded by the seller
        require(msg.value >= storageContract.getPrice(nftAddress,tokenID), "Please pay the right amount for this NFT");

        address seller;
        seller=storageContract.getDepositor(nftAddress,tokenID);

        //push sales volume in the array
        storageContract.pushVolumeSales(msg.value);

        //updating volumes
        storageContract.pushVolumes(seller,msg.value);

        //index concatenation
        index+=1;

        //mapping index of the sale to depositor address
        storageContract.pushIndex(seller,index-1);

        //updating total volume
        storageContract.updateTotalVolume(msg.value);
        storageContract.pushTotalVolume();

        //Sending ETH to the royalty receiver
        (address receiver, uint256 royaltyAmount)=royaltyManagerContract.getRoyaltyInfo(nftAddress, tokenID, storageContract.getPrice(nftAddress,tokenID));
        Address.sendValue(payable(receiver), royaltyAmount);

        //Sending eth to the person that deposited the asset
        Address.sendValue(payable(seller), ((100-fee)*msg.value-royaltyAmount)/100);

        //Sending the eth to the rewards contract
        Address.sendValue(payable(rewardsAddress),fee*msg.value/100);

        //updating total historical balance
        storageContract.updateTotalBalance(fee*msg.value/100);

        //transfering the asset to the buyer
        IERC721(nftAddress).safeTransferFrom(storageContract.getDepositor(nftAddress,tokenID), msg.sender, tokenID);

        emit Bought(msg.sender,nftAddress,tokenID);
    }

    /**
     * @notice function to delist an NFT
     * @param nftAddress address of the collection
     * @param tokenID token ID for the item to list
     * @dev This function sets the price to 0 which effectively delists the token from the marketplace
     */

    function unlist (address nftAddress, uint256 tokenID) external {

        //Checking if the contract holds the asset
        require(storageContract.getPrice(nftAddress,tokenID)!=0, "This asset is not for sale");

        //require that the address that wants to unlist the NFT is the depositor
        require(storageContract.getDepositor(nftAddress,tokenID)==msg.sender,"You are not the depositor of this NFT asset");

        //putting the price of the asset to zero so that the next claim doesnt pass
        storageContract.setPrice(nftAddress,tokenID,0);

        emit Unlisted(nftAddress, tokenID);

    }

    /**
     * @notice function to make an offer for an NFT
     * @param nftAddress address of the collection
     * @param tokenID token ID for the item to list
     * @param offer The amount of the offer in the lowest decimal of the chosen token (usually the token is weth, and lowest decimal currency for weth is wrapped WEI)
     * @param time This is the parameter to set the time in seconds to how much the user wishes to to keep the offer running
     * @dev This function sets the price to 0 which effectively delists the token from the marketplace
     */

    function makeOffer(address nftAddress, uint tokenID, uint offer, uint time) external {
        //requiring that the offer given is not 0
        require(offer>0, "Your offer can't be 0 and should be bigger than the last offer");
        // requiring that the offer has not expired
        require(IERC20(storageContract.getTokenForOffer()).allowance(msg.sender,address(this))>offer, "You must approve the contract to use your funds");

        //keeping track of the current timestamp
        uint offerTimestamp=block.timestamp;
        //keeping track of the offer index
        uint offerIndex;
        offerIndex=storageContract.pushOffer(nftAddress, tokenID, offer, msg.sender, offerTimestamp, time);

        //emiting the event
        emit OfferMade(nftAddress,tokenID,msg.sender,offer,offerIndex);
        

    }

    /**
     * @notice function to accept an offer for an NFT
     * @param nftAddress address of the collection
     * @param offerIndex index of the offer. For each nft, there are multiple offers that are submitted. The index is the number attached to each offer made to a certain nft
     * @dev This function accepts an offer for a specific offerIndex only, not necessarily the biggest offer
     */
    function acceptOffer(address nftAddress, uint tokenID, uint offerIndex) external {
        //getting the bidder & bid
        address bidder=storageContract.getOfferBidder(nftAddress,tokenID, offerIndex);
        uint bid=storageContract.getOfferBid(nftAddress,tokenID,offerIndex);

        //Requiring that the offer is not zero (=cancelled)
        require(bid>0, "This offer does not exist or has been cancelled");
        //requiring that the user still approved the allowance to move the tokens & that he still has the required tokens
        require(IERC20(storageContract.getTokenForOffer()).allowance(bidder,address(this))>=bid && IERC20(storageContract.getTokenForOffer()).balanceOf(bidder)>=bid , "Offer expired");
        //Requiring that the one accepting the offer still has the nft
        require(IERC721(nftAddress).ownerOf(tokenID)==msg.sender, "You do not own this token");
        //requiring that the contract is approved to handle the nft
        require(IERC721(nftAddress).isApprovedForAll(msg.sender,address(this))==true, "You didn't approve the smart contract to manage your assets, please approve and come back");
        //requiring that the offer has not expired in time
        require(block.timestamp-storageContract.getOfferStamp(nftAddress, tokenID, offerIndex)<=storageContract.getOfferTime(nftAddress,tokenID,offerIndex),"This offer has exmpired");

        address seller=msg.sender;

        //push sales volume in the array
        storageContract.pushVolumeSales(bid);

        //updating volumes
        storageContract.pushVolumes(seller,bid);

        //index concatenation
        index+=1;

        //mapping index of the sale to depositor address
        storageContract.pushIndex(seller,index-1);

        //updating total volume
        storageContract.updateTotalVolume(bid);
        storageContract.pushTotalVolume();

        //Sending ETH to the royalty receiver
        (address receiver, uint256 royaltyAmount)=royaltyManagerContract.getRoyaltyInfo(nftAddress, tokenID, bid);
        IERC20(storageContract.getTokenForOffer()).transferFrom(bidder,receiver,royaltyAmount);
        
        //Transfer the nft from seller to bidder
        IERC721(nftAddress).safeTransferFrom(msg.sender, bidder,tokenID);

        //Transfering the fungible tokens from bidder to seller
        IERC20(storageContract.getTokenForOffer()).transferFrom(bidder,msg.sender,bid*(100-fee)/100 - royaltyAmount);

        //updating total historical balance
        storageContract.updateTotalBalance(fee*bid/100);

        emit OfferAccepted(nftAddress, tokenID, offerIndex );

        
    }

    function cancelOffer(address nftAddress, uint tokenID, uint offerIndex) external {
        //getting the bidder & bid
        address bidder=storageContract.getOfferBidder(nftAddress,tokenID, offerIndex);
        uint bid=storageContract.getOfferBid(nftAddress,tokenID,offerIndex);

        //Requiring that the offer is not zero (=cancelled)
        require(bid>0, "This offer does not exist or has been cancelled");
        require(msg.sender==bidder, "You did not make this offer");

        //Setting offer bid to 0
        storageContract.setOfferBid(nftAddress, tokenID, offerIndex, 0);



    }

    

    //ERC721Receiver function
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    

}