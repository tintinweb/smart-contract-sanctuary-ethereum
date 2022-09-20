/**
 *Submitted for verification at Etherscan.io on 2022-09-20
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity = 0.8.15;

contract Auction {
    struct Asset {
        string AssetName;
        uint AssetSP;
        address Owner;
    }

    struct AuctDetail {
        uint bidPrice;
        address bidderId;
    }

    mapping(address => string) public Users;
    mapping(uint => Asset) public Assets;
    mapping(uint => AuctDetail[]) public AuctDetails;
    

    function addUser(string memory Name) public returns (string memory, address) {
        Users[msg.sender] = Name;
        return (Name, msg.sender);
    }

    function addAsset(uint Id, string memory Name, uint Price) public returns (uint, string memory, uint) {
        Assets[Id] = Asset(Name, Price, msg.sender);
        return (Id, Name, Price);
    }        
    
    function Bidding(uint AssetId, uint bidPrice) public {
        AuctDetails[AssetId].push(AuctDetail(bidPrice, msg.sender));
    }

    function Result(uint ID) public payable returns (address, uint) {
        uint Price = 0;
        address OwnerId;
        for(uint j = 0; j < AuctDetails[ID].length ; j++) {
            if (AuctDetails[ID][j].bidPrice > Price) {
                Price = AuctDetails[ID][j].bidPrice;
                OwnerId = AuctDetails[ID][j].bidderId;
            }                       
        }
        return (OwnerId, Price);
    }
}