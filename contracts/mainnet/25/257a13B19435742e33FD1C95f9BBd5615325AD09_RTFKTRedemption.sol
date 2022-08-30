/**
 *Submitted for verification at Etherscan.io on 2022-08-30
*/

// File: contracts/redemption.sol


//          [email protected]@@                                                                  
//               ,@@@@@@@&,                  #@@%                                  
//                    @@@@@@@@@@@@@@.          @@@@@@@@@                           
//                        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                      
//                            @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                   
//                                @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@.                 
//                                    @@@@@@@    &@@@@@@@@@@@@@@@@@                
//                                        @@@/        &@@@@@@@@@@@@@,              
//                                            @            @@@@@@@@@@@             
//                                                             /@@@@@@@#           
//                                                                  @@@@@          
//                                                                      *@&   
//         RTFKT Studios (https://twitter.com/RTFKT)
//         Redemption Contract (made by @CardilloSamuel)

pragma solidity ^0.8.7;

abstract contract redeemableCollection {
    function redeemBatch(address owner, address initialCollection, uint256[] calldata cloneXIds, uint256[] calldata wearableIds, uint256[] calldata amount) public virtual;
}

contract RTFKTRedemption {
    mapping (address => bool) authorizedOwners;
    mapping (address => bool) authorizedContract;
    mapping (uint256 => uint256) public redeemPrice;

    constructor() {
        authorizedOwners[msg.sender] = true;
    }

    /** 
        MODIFIER 
    **/

    modifier isAuthorizedOwner() {
        require(authorizedOwners[msg.sender], "You are not authorized to perform this action");
        _;
    }

    /**
        MAIN FUNCTION
    **/

    function redeemBatch(address newCollection, address initialCollection, uint256[] calldata cloneXIds, uint256[] calldata wearableIds, uint256[] calldata amount) public payable {
        require(tx.origin == msg.sender, "No contracts allowed");
        require(cloneXIds.length == wearableIds.length, "Mismatch of length");
        require(cloneXIds.length == amount.length, "Mismatch of length");
        require(authorizedContract[newCollection], "This contract is not authorized");

        uint256 amountToReceive = 0;
        for(uint256 i = 0; i < wearableIds.length; ++i) {
            amountToReceive = amountToReceive + (redeemPrice[wearableIds[i]] * amount[i]);
        }
        require(msg.value == amountToReceive, "Not enough money sent");
        redeemableCollection externalContract = redeemableCollection(newCollection);
        
        externalContract.redeemBatch(msg.sender, initialCollection, cloneXIds, wearableIds, amount);
    }

    /** 
        CONTRACT MANAGEMENT FUNCTIONS 
    **/ 

    function changeRedeemPrice(uint256 tokenId, uint256 newPrice) public isAuthorizedOwner {
        redeemPrice[tokenId] = newPrice;
    }

    function toggleAuthorizedContract(address redeemableContract) public isAuthorizedOwner {
        authorizedContract[redeemableContract] = !authorizedContract[redeemableContract];
    }

    function toggleAuthorizedOwner(address newAddress) public isAuthorizedOwner {
        require(msg.sender != newAddress, "You can't revoke your own access");

        authorizedOwners[newAddress] = !authorizedOwners[newAddress];
    }

    function withdrawFunds(address withdrawalAddress) public isAuthorizedOwner {
        payable(withdrawalAddress).transfer(address(this).balance);
    }

}