/**
 *Submitted for verification at Etherscan.io on 2022-03-29
*/

// SPDX-License-Identifier: MIT
pragma solidity >0.8.0;
pragma experimental ABIEncoderV2;

contract Owner {
   address owner;
   constructor() {
      owner = msg.sender;
   }
   modifier onlyOwner {
      require(msg.sender == owner);
      _;
   }
}

contract Oracle is Owner {
    uint maxAssets = 5;

    struct Assets {
        string symbol;
        int256 price;
        address assetAddress;
        int256 targetPercentage;
    }

    Assets[] public assets;
    mapping(string => int256) public symbolToPrice;
    mapping(string => address) public symbolToAssetAddress;
    mapping(string => int256) public symbolToTargetPercentage;

    function addAsset(string memory _symbol, int256 _price, address _assetAddress, int256 _targetPercentage) public onlyOwner {
        uint array_size = arrayLength();
        require(array_size < maxAssets, 'Too many assets');
        assets.push(Assets({symbol: _symbol,
        price: _price,
        assetAddress: _assetAddress,
        targetPercentage: _targetPercentage}));
        symbolToPrice[_symbol] = _price;
        symbolToAssetAddress[_symbol] = _assetAddress;
        symbolToTargetPercentage[_symbol] = _targetPercentage;
    }

    function updateAsset(uint256 asset, string memory _symbol, int256 _price, address _assetAddress, int256 _targetPercentage) public onlyOwner {
        assets[asset] = (Assets({symbol: _symbol,
        price: _price,
        assetAddress: _assetAddress,
        targetPercentage: _targetPercentage}));
        symbolToPrice[_symbol] = _price;
        symbolToAssetAddress[_symbol] = _assetAddress;
        symbolToTargetPercentage[_symbol] = _targetPercentage;
    }

    function retireveAssetDetail() external view returns(Assets[] memory) {
        return assets;
    }

    function arrayLength() public view returns(uint) {  
            uint x = assets.length;
            return x; 
        }
}