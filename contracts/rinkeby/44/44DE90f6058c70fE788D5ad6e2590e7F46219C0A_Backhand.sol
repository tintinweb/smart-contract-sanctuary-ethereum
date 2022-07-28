// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

contract Backhand {
  uint256 numberOfRows;
  string CodeOfProduct;
  uint256 ProductCount;
  uint256 ProductCount2;

  struct ProductFeatures {
    uint256 doesItHaveUnderProduct;
    string CodeOfProduct;
    string NameOfProduct;
    uint256 BuyingCost;
    uint256 AverageCost;
    address TheAddressOfSeller;
  }

  struct UnderProductFeatures {
    uint256 codeOrUnderProduct;
    uint256 quantityOfProduct;
  }

  mapping(string => ProductFeatures) public stringToProductFeatures;

  ProductFeatures[] features;

  constructor() {}

  function getStarted(string memory _CodeOfProduct) public {
    ProductCount = 0;

    CodeOfProduct = _CodeOfProduct;
    addProduct(
      0,
      "0001",
      "sugar",
      14,
      20,
      0x0000000000000000000000000000000000000000
    );
    addProduct(
      1,
      "0002",
      "cake",
      80,
      100,
      0x0000000000000000000000000000000000000000
    );
    addProduct(
      0,
      "0003",
      "cacao",
      14,
      20,
      0x0000000000000000000000000000000000000000
    );
    addProduct(
      0,
      "0004",
      "milk",
      14,
      20,
      0x0000000000000000000000000000000000000000
    );
  }

  function addProduct(
    uint256 _DoesItHaveUnderProduct,
    string memory _CodeOfProduct,
    string memory _NameOfProduct,
    uint256 _BuyingCost,
    uint256 _AverageCost,
    address _TheAddressOfSeller
  ) public {
    stringToProductFeatures[_CodeOfProduct] = ProductFeatures(
      _DoesItHaveUnderProduct,
      _CodeOfProduct,
      _NameOfProduct,
      _BuyingCost,
      _AverageCost,
      _TheAddressOfSeller
    );
  }

  function getAddress() public view returns (address) {
    return address(this);
  }

  // function getProductFeatures(string memory _codeOfProduct)
  //   public
  //   view
  //   returns (struct)
  // {
  //   return stringToProductFeatures[_codeOfProduct];
  // }
  function printStruct(uint256 _featureId)
    public
    view
    returns (ProductFeatures memory)
  {
    return features[_featureId];
  }
}