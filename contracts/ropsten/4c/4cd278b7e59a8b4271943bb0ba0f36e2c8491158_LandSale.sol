/**
 *Submitted for verification at Etherscan.io on 2022-08-29
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
contract LandSale{
    struct SellerDetails{
        string sellerName;
        address sellerAddr;
    }
    SellerDetails public seller;
    constructor(string memory _name,address _addr){
        seller=SellerDetails(_name,_addr);
    }
    enum lands{available,sold}
    struct BuyerDetails{
        string buyerName;
        address buyerAddr;
    }
    mapping(address => BuyerDetails) public buyer;
    struct LandDetails{
        uint id;
        uint price;
        lands landStatus;
    }
    mapping(uint => LandDetails) public land;
    function addLand(uint _id, uint _price)public{
        land[_id]=LandDetails(_id,_price,lands.available);
    }
    function delLand(uint _id) public{
        delete land[_id];
        land[_id].landStatus=lands.sold;
    }
    function Buy(uint _landID, string calldata _buyerName, address _buyerAddr) public {
        buyer[_buyerAddr]=BuyerDetails(_buyerName,_buyerAddr);
        require(land[_landID].landStatus==lands.available,"Land Sold");
        seller=SellerDetails(_buyerName,_buyerAddr);   
        delLand(_landID);
    }
}