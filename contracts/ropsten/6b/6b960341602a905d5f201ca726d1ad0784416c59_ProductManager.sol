//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Ownable.sol";

/*
 * @title Product Management Inventory on the Blockchain
 */

contract ProductManager is Ownable {

    enum ProductStatus{InStorage, InTransit, Delivered}

    struct Product {
        uint   m_ID;
        string m_name;
        uint   m_quantity;
    }

    struct ToDispatch {
        uint   m_ID;
        string m_selectedProduct;
        uint   m_selectedQty;
        string m_currentLocation;
        ProductManager.ProductStatus m_status;
    }

    // For efficiency, we will be using Mappings instead of Arrays; however the Map[key] will be an incrementing integer for each new element added to the list
    mapping(uint => Product)    public m_productList;
    mapping(uint => ToDispatch) public m_dispatchList;
    mapping(uint => ToDispatch) public m_dispatchLocations;

    // We use this to keep track of each product added to the list of products in Events, index value of the product
    uint public m_productCounter; // by default, initialized to 0;

    // We use this to keep track of each product added to the dispatch list of products
    uint public m_dispatchCounter; // already initialized to zero

    uint public m_locationIndex; // already initialized to zero

    // For permission purposes
    address payable m_owner;
    bool public     m_isPaused;

    event ProductAdded(uint indexCounter, string productName, uint64 creationTime);
    event QuantityChanged(string name, uint oldQty, uint newQty, uint64 timeChanged);
    event ProductDispatched(uint indexCounter, string productName, uint itemsLeft, uint64 dispatchTime);
    event LocationChanged(uint trackID, string productName, string formerLocation, string latestLocation, uint64 timeChanged);

    constructor() {
        m_owner = payable(msg.sender);
    }

    function setPaused(bool _paused) public onlyOwner {
        require(msg.sender == m_owner, "Invalid action, You are not the owner ");
        m_isPaused = _paused;
    }

    function addProduct(uint _id, string memory _name, uint _quantity) public onlyOwner  {
        require(m_isPaused == false, "This contract has been paused");
        uint productIndex = m_productCounter; // doing this for optimization purposes, we cache the data locally, so we can efficiently re-read it several times.
        m_productList[productIndex].m_ID = _id;
        m_productList[productIndex].m_name = _name; // ToDo: move this to Event chain
        m_productList[productIndex].m_quantity = _quantity;
        emit ProductAdded(productIndex, _name, uint64(block.timestamp));
        m_productCounter++; // update the state variable NOT the local variable, else it won't update the index properly.
    }

    function getProduct(uint _index) public view returns (Product memory){
        return m_productList[_index];
    }

    function updateQuantity(uint _index, uint _newQty) public onlyOwner {
        require(m_isPaused == false, "This contract has been paused");
        uint oldQty = m_productList[_index].m_quantity;
        m_productList[_index].m_quantity = _newQty;
        emit QuantityChanged(m_productList[_index].m_name, oldQty, _newQty, uint64(block.timestamp));
    }

    // Expects the ID of the item to be dispatched and the quantity of items to be dispatched
    // When a product is added to the dispatch list, it has a unique ID which is its index value
    function dispatchItem(uint _productIndex, uint _quantity, string memory _location) public onlyOwner {
        require(m_isPaused == false, "This contract has been paused");
        uint dispatchIndex = m_dispatchCounter; // optimizing this so I can have a local cache of the data, rather than reading from expensive storage each time.
        m_productList[_productIndex].m_quantity -= _quantity; // reduce quantity of product in the inventory by quantity value specified
        m_dispatchList[dispatchIndex].m_ID = m_productList[_productIndex].m_ID;  //m_dispatchCounter + 1;
        //m_dispatchList[dispatchIndex].m_ID = m_productList[_productIndex].m_ID; // We'll use the product ID not its index value to store & make ref to the product in the dispatch list.
        m_dispatchList[dispatchIndex].m_selectedProduct = m_productList[_productIndex].m_name;
        m_dispatchList[dispatchIndex].m_selectedQty = _quantity;
        m_dispatchList[dispatchIndex].m_currentLocation = "Warehouse"; 
        m_dispatchList[dispatchIndex].m_status = ProductStatus.InStorage; 
        emit ProductDispatched(dispatchIndex, m_productList[_productIndex].m_name, _quantity, uint64(block.timestamp));
        getDispatchID(m_dispatchList[dispatchIndex].m_ID);
        setLocation(dispatchIndex, _location); // We pass dispatchIndex so we know what index in m_dispatchList we need to ref in setLocation()
        m_dispatchCounter++;
    }

    function setLocation(uint _dispatchID, string memory _location) public onlyOwner {
        require(m_isPaused == false, "This contract has been paused");
        m_dispatchLocations[m_locationIndex].m_ID = m_dispatchList[m_locationIndex].m_ID; // first add the product to the list of delivery locations
        m_dispatchLocations[m_locationIndex].m_selectedProduct = m_dispatchList[m_locationIndex].m_selectedProduct;
        // I skipped the '.m_selectedQty' property to save on gas.  I do not need qty ordered to keep track of its location.
        string memory formerLocation = m_dispatchList[m_locationIndex].m_currentLocation;
        m_dispatchLocations[m_locationIndex].m_currentLocation = _location;
        m_dispatchLocations[m_locationIndex].m_status = ProductStatus.InTransit;
        emit LocationChanged(_dispatchID, m_dispatchLocations[m_locationIndex].m_selectedProduct, formerLocation, _location, uint64(block.timestamp));
        m_locationIndex++;
    }

    function getDispatchID(uint dispatchID) public pure returns (uint) {
        return dispatchID;
    }

}