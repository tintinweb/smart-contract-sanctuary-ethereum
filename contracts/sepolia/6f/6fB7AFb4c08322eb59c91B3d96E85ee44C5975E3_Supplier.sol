/**
 *Submitted for verification at Etherscan.io on 2023-05-25
*/

// File: Optimized Amira Code v2/Library.sol


pragma solidity >=0.4.25 <0.9.0;

library Types {
   
   enum StakeHolder {      //currently we have only 2 stakeholder so, that's why I'm using  
        Producer, //0 for producer.
        ManuFacturer, // 1 for manfacturer at the registeration time.
        distributors, // 2
        retailers, // 3
        supplier//4
    }

    enum productAvailablity {
        PRODUCED,
        ready_to_ship,
        pre_bookable, 
        READY_FOR_PICKUP, 
        PICKED_UP, 
        SHIPMENT_RELEASED, 
        RECEIVED_SHIPMENT, 
        READY_FOR_SALE, 
        PAID,
        SOLD
    }

        //stakeholder details
    struct Stakeholder {
        StakeHolder role;
        address id_;
        string name;
        string email;
        uint256 MobNo;
        bool IsRegistered;
        string country;
        string city;
    }

    //Product => RawMaterial
    struct Product {
        uint256 ArrayIndex; //flag for checking the availablity
        bytes32 PId; // => now we created an auto genrated uid for each product using product name!
        string MaterialName;
        uint256 AvailableDate;
        uint256 Quantity;
        uint256 ExpiryDate;
        uint256 Price;
        bool IsAdded; //flag for checking the availablity
        productAvailablity status;
    }

    struct manfProduct { 
        uint256 ArrIndex;        
        string name;
        bytes32 PId;
        string description;
        uint256 expDateEpoch;
        string barcodeId;
        uint256 quantity;
        uint256 price;
        uint256 weights;
        uint256 manDateEpoch;       //available date
        productAvailablity status;
    }

    struct UserHistory {
        address id_;
        manfProduct Product_;
        uint256 orderTime_;  
    }

    struct productAvailableManuf {
        address id;
        string  productName;
        bytes32 productID;
        uint256 quantity;
        uint256 price;
        uint256 availableDate;
        uint256 weights;
        uint256 expDateEpoch;
    }

    struct SupplierWithMaterialID  {
        address id_; // account Id of the user
        bytes32 productId_;// Added, Purchased date in epoch in UTC timezone
        uint256 price_;
    }

    struct PurchaseOrderHistory {
        address _id;
        Product _product;
        uint256 _quantity;
        uint256 _orderTime;  
    }

    struct ProductHistory {
        PurchaseOrderHistory[] manufacturer;
    }            
    
    // //not in used
    // struct OrderPlaced {
    //     uint256 orderSrNo;
    //     address ManufAdd;
    //     bytes32 PId;
    //     string Materialname;
    //     uint256 Qty;
    //     uint256 PreOrderQty; //Not yet Placed That Why Inventory Not Deducted Total Quantity when Available Time Is Coming we can updated.
    //     uint256 ExpiryDate;
    //     bool IsOrderPlaced;
    // }
}
// File: Optimized Amira Code v2/Supplier.sol


pragma solidity ^0.8.15;


contract Supplier {
    Types.SupplierWithMaterialID[] internal supplierWithMaterialID;
    mapping(bytes32 => Types.SupplierWithMaterialID[]) internal supplierPrices;

    event supplierSet(
        address id_, // account Id of the user
        bytes32 productid_,
        uint256 orderTime_
    );

    function supplierSetMaterialIDandPrice(bytes32 productid_, uint256 Cprice_)
        public
    {
        Types.SupplierWithMaterialID memory supplierMaterialID_ = Types
            .SupplierWithMaterialID({
                id_: msg.sender,
                productId_: productid_,
                price_: Cprice_
            });
        supplierWithMaterialID.push(supplierMaterialID_);
        supplierPrices[productid_].push(supplierMaterialID_);
        emit supplierSet(msg.sender, productid_, Cprice_);
    }
}