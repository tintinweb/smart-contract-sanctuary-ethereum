/**
 *Submitted for verification at Etherscan.io on 2023-06-01
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


contract SupplychainManagement{
    struct ProductSupply{
       string productId;
       string productSerialNumber;
       string productName;
       string source;
       string destination;
       uint256 timeStamp;
       string remarks;
       string status;
       address accountAddress;  
    }
    mapping(bytes32 => ProductSupply[]) productSupplyDetails;
    event Product(bytes32 productHash);
    event SupplyChainAdded(ProductSupply product);
    function generateProductHash(string memory _name,string memory description, string memory productId) pure internal returns(bytes32){
       return keccak256(abi.encode(_name,description,productId));
    }

    function registerProduct(string memory _name,string memory description, string memory productId,string memory productSerialNumber) external returns(bytes32){
        bytes32 productHash = generateProductHash(_name,description,productId);
        ProductSupply memory product;
        product.productId = productId;
        product.productSerialNumber = productSerialNumber;
        product.productName = _name;
        product.source = "Manufacturer";
        product.destination = "Manufacturer";
        product.timeStamp = block.timestamp;
        product.status = "";
        product.remarks = "Product manufactured";
        product.accountAddress = msg.sender;

        productSupplyDetails[productHash].push(product);
        emit Product(productHash);
        return productHash;
    }

    function getSupplyDetails(bytes32 productHash) external view returns(ProductSupply[] memory){
       return productSupplyDetails[productHash];
    }

    function addSupplyChainDetails(bytes32 productHash, string memory _name, string memory productId,string memory productSerialNumber,string memory source, string memory destination, string memory remarks,string memory status) external returns(ProductSupply memory){
         ProductSupply memory productSupply;
         productSupply.productId = productId;
         productSupply.productSerialNumber = productSerialNumber;
         productSupply.productName = _name;
         productSupply.source = source;
         productSupply.destination = destination;
         productSupply.timeStamp = block.timestamp;
         productSupply.remarks = remarks;
         productSupply.status = status;
         productSupply.accountAddress = msg.sender;

         productSupplyDetails[productHash].push(productSupply);
         emit SupplyChainAdded(productSupply);
         return productSupply;

    }


   
}