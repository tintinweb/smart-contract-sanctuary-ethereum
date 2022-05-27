// SPDX-License-Identifier: MIT
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
    function redeem(address owner, address initialCollection, uint256 tokenId) public virtual returns(uint256);
    function hasBeenRedeem(address initialCollection, uint256 tokenId) public view virtual returns(address);
}

contract RTFKTRedemption {
    mapping (address => bool) authorizedOwners;
    mapping (address => bool) authorizedContract;
    mapping (address => uint256) public redeemPrice;

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

    function redeemToken(address newCollection, address initialCollection, uint256 tokenId) public payable { 
        require(authorizedContract[newCollection], "This contract is not authorized");
        require(msg.value == redeemPrice[newCollection], "Not enough money sent");
        redeemableCollection externalContract = redeemableCollection(newCollection);
        require(externalContract.hasBeenRedeem(initialCollection, tokenId) == 0x0000000000000000000000000000000000000000, "This token has been redeemed already");

        externalContract.redeem(msg.sender, initialCollection, tokenId);
    }

    function hasBeenRedeemed(address newCollection, address initialCollection, uint256 tokenId) public view returns(address) {
        redeemableCollection externalContract = redeemableCollection(newCollection);
        return externalContract.hasBeenRedeem(initialCollection, tokenId);
    }

    /** 
        CONTRACT MANAGEMENT FUNCTIONS 
    **/ 

    function changeRedeemPrice(address collectionAddress, uint256 newPrice) public isAuthorizedOwner {
        redeemPrice[collectionAddress] = newPrice;
    }

    function toggleAuthorizedContract(address redeemableContract) public isAuthorizedOwner {
        authorizedContract[redeemableContract] = !authorizedContract[redeemableContract];
    }

    function toggleAuthorizedOwner(address newAddress) public isAuthorizedOwner {
        require(msg.sender != newAddress, "You can't revoke your own access");

        authorizedOwners[msg.sender] = !authorizedOwners[msg.sender];
    }

    function withdrawFunds(address withdrawalAddress) public isAuthorizedOwner {
        payable(withdrawalAddress).transfer(address(this).balance);
    }

}