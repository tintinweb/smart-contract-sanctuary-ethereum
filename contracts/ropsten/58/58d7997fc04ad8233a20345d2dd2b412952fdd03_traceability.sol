/**
 *Submitted for verification at Etherscan.io on 2022-04-22
*/

// File: contracts/Traceability_2.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;

/**
 * @title traceability
 * @dev Contract with abstraction for traceability in a supply chain
 */
 
contract traceability {
  /**
  * @dev Define the structure for a basic product
  */
  struct Product {
    string FinalProd;
    string description;
    string location;
    string Producer;
    string Manager;
    uint256 CreationDate;
    bool exist;
  }

  /**
  * @dev Mapping that define the storage of a product
  */
  mapping(string  => Product) private StorageProduct;
  mapping(address => mapping(string => bool)) private wallet;


    /**
  * @dev Declare events according the supply chain operations:
  */
  event CreateProduct(address addressProducer, string id, string Producer, uint256 CreationDate);
  event TransferProduct(address from, address to, string id);
  //event setPrice(string id, string Manager);
  event TransferReject(address from, address to, string id, string RejectMessage);
  event CreationReject(address addressProducer, string id, string RejectMessage);

  /**
  * @dev Function that create the Product:
  */
  function creationProduct(string memory FinalProd, string memory description, string memory id, string memory Producer, string memory location,  string memory Manager) public {
 
    if(StorageProduct[id].exist) {
        emit CreationReject(msg.sender, id, "Product con this id already exist");
        return;
      }
 
      StorageProduct[id] = Product(FinalProd, description, location, Producer, Manager, now, true);
      wallet[msg.sender][id] = true;
      emit CreateProduct(msg.sender, id, Producer, now);
    }

  /**
  * @dev Function that makes the transfer of ownership of a Product:
  */
  function transfProduct(address to, string memory id) public{
 
    if(!StorageProduct[id].exist) {
        emit TransferReject(msg.sender, to, id, "It does not exist a Product with this id");
        return;
    }
 
    if(!wallet[msg.sender][id]) {
        emit TransferReject(msg.sender, to, id, "user is not the owner of this Product.");
        return;
    }
 
    wallet[msg.sender][id] = false;
    wallet[to][id] = true;
    emit TransferProduct (msg.sender, to, id);
  }

  /**
  * @dev Getter of the characteristic of a product:
  */
  function getProduct(string memory id) public view returns  (string memory, string memory, string memory, string memory, string memory, uint256) {
 
    return (StorageProduct[id].FinalProd, StorageProduct[id].description, StorageProduct[id].Producer, StorageProduct[id].location, StorageProduct[id].Manager, StorageProduct[id].CreationDate);
  }

  /**
  * @dev Funcion to check the ownership of a product:
  */
  function isOwner(address owner, string memory id) public view returns (bool) {
 
    if(wallet[owner][id]) {
        return true;
    }
 
    return false;
  }
}