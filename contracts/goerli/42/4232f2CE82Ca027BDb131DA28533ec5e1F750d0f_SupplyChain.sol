// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/* Errors */
error SupplyChain__ProductIdIsNotValid();
error SupplyChain__OnlyOwnerCanChangeOwnibility();

/**@title A sample SupplyChain Contract
 * @author Mehdi Fadaei
 * @notice This contract is for creating a SupplyChain
 */

contract SupplyChain {

  uint256 private prodId = 0;

  struct OwnState {
    address owner;
    uint256 timeOwned;
  }

  struct CostState {
    uint256 cost;
    uint256 timeCosted;
  }

  struct Product {
    uint256 id;
    string productName;
    uint256 timeCreated;
    string description;
    OwnState[] owners;
    CostState[] costs;
  }


  event Added(uint256 indexed itemId, string indexed itemName);
  event OwnerStateAdded(uint256 indexed itemId, address indexed ownStateId);
  event CostStateAdded(uint256 indexed itemId, uint256 indexed ownStateId);

  mapping(uint256 => Product) public s_allProducts;

  // for track each address how many Product have?
  

  modifier onlyOwner(uint256 _prodId) {
    address lastOwner = OwnerOf(_prodId);
    if (msg.sender != lastOwner) revert SupplyChain__OnlyOwnerCanChangeOwnibility();
    _;
  }

  /////////////////////
  // Main Functions //
  /////////////////////

  function createItem(string memory _productName, uint256 _cost, string memory _descripton) public returns (uint256) {
    Product storage newProduct = s_allProducts[prodId];

    newProduct.id = prodId;
    newProduct.productName = _productName;
    newProduct.timeCreated = block.timestamp;
    newProduct.description = _descripton;

    CostState memory newCost = CostState(_cost, block.timestamp);

    OwnState memory newOwner = OwnState(msg.sender, block.timestamp);

    newProduct.costs.push(newCost);
    newProduct.owners.push(newOwner);

    emit Added(prodId, _productName);

    prodId ++;

    return prodId-1;
  }

  function addNewOwner(
    uint256 _prodId,
    address _newOwner
  ) public onlyOwner(_prodId) returns (bool) {
    if (!(_prodId <= prodId)) {
      revert SupplyChain__ProductIdIsNotValid();
    }
    Product storage newProduct = s_allProducts[_prodId];

    OwnState memory newOwner = OwnState(_newOwner, block.timestamp);

    newProduct.owners.push(newOwner);

    emit OwnerStateAdded(_prodId, _newOwner);

    return true;
  }

  function addNewCost(
    uint256 _prodId,
    uint256 _cost
  ) public onlyOwner(_prodId) returns (bool) {
    if (!(_prodId <= prodId)) {
      revert SupplyChain__ProductIdIsNotValid();
    }

    Product storage newProduct = s_allProducts[_prodId];

    CostState memory newCost = CostState(_cost, block.timestamp);

    newProduct.costs.push(newCost);

    emit CostStateAdded(_prodId, _cost);

    return true;
  }

  /////////////////////
  // Getter Functions //
  /////////////////////

  
  // get the last owner of specific product
  function OwnerOf(uint256 _prodId) public view returns (address) {
    if (!(_prodId <= prodId)) {
      revert SupplyChain__ProductIdIsNotValid();
    }

    uint256 index = s_allProducts[_prodId].owners.length - 1;


    return s_allProducts[_prodId].owners[index].owner;
  }

  // return last time for item when his owner changed
  function CostOf(uint256 _prodId) public view returns (uint256) {
    if (!(_prodId <= prodId)) {
      revert SupplyChain__ProductIdIsNotValid();
    }
    
    uint256 index = s_allProducts[_prodId].costs.length - 1;

    return s_allProducts[_prodId].costs[index].cost;
  }


  // getCurrent prodId or how much Product we have now
  function getProdId() public view returns (uint256) {
    return prodId;
  }

  // get specific product detail with prodId
  function getProduct(uint256 _prodId) public view returns (Product memory) {
    if (!(_prodId <= prodId)) {
      revert SupplyChain__ProductIdIsNotValid();
    }

    return s_allProducts[_prodId];
  }

  // get how many owners this item with this prodId have
  function getNumberOfOwners(uint256 _prodId) public view returns (uint256) {
        if (!(_prodId <= prodId)) {
      revert SupplyChain__ProductIdIsNotValid();
    }

    
    return s_allProducts[_prodId].owners.length;
  }

  // get how many costs this item with this prodId have
  function getNumberOfCosts(uint256 _prodId) public view returns (uint256) {
        if (!(_prodId <= prodId)) {
      revert SupplyChain__ProductIdIsNotValid();
    }

    
    return s_allProducts[_prodId].costs.length;
  }

  // get _stateTH owner of product with id _prodId
  function getSpecificOwner(uint256 _prodId, uint256 _state) public view returns (OwnState memory) {
        if (!(_prodId <= prodId)) {
      revert SupplyChain__ProductIdIsNotValid();
    }

    
    return s_allProducts[_prodId].owners[_state];
  }

  // get witch item and ther own costPrice at that state
  function getSpecificCost(uint256 _prodId, uint256 _state) public view returns (CostState memory) {
        if (!(_prodId <= prodId)) {
      revert SupplyChain__ProductIdIsNotValid();
    }

    
    return s_allProducts[_prodId].costs[_state];
  }


  // get history of owners of product with _id
  function getOwnersOf(uint256 _id)public view returns(OwnState[] memory){
        if (!(_id <= prodId)) {
      revert SupplyChain__ProductIdIsNotValid();
    }

    
    return s_allProducts[_id].owners;
  }

  // get history of costs of product with _id
  function getCostsOf(uint256 _id)public view returns(CostState[] memory){
        if (!(_id <= prodId)) {
      revert SupplyChain__ProductIdIsNotValid();
    }

    
    return s_allProducts[_id].costs;
  }

  // returns Products with address of their owners
  function getProdWithAddress(address _address) public view returns(Product[] memory){

    Product[] memory result = new Product[](5);
    uint256 index = 0;
    for(uint256 j=0;j<prodId;j++){
      if(OwnerOf(j)== _address){
        result[index].id = s_allProducts[j].id;
        result[index].productName = s_allProducts[j].productName;
        result[index].timeCreated = s_allProducts[j].timeCreated;
        result[index].description = s_allProducts[j].description;
        result[index].owners = s_allProducts[j].owners;
        result[index].costs = s_allProducts[j].costs;
        index++;
      }
    }

    return result;
  }
}