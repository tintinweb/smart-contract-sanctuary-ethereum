/**
 *Submitted for verification at Etherscan.io on 2022-06-12
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;



// Part: IERC20

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function symbol() external view returns (string memory);
    
}

// Part: IPhutureIndex

interface IPhutureIndex{
    function anatomy() external view returns (address[] memory _assets, uint8[] memory _weights);
    function symbol() external view returns (string memory);
    function vTokenFactory() external view returns(address);
    function inactiveAnatomy() external view returns (address[] memory);
    }

// Part: IVTokenFactory

interface IVTokenFactory{
    function vTokenOf(address) external view returns(address);
}

// File: indexComponents.sol

contract IndexComponents {

    struct componentStruct {
        address assetAddress;
        uint256 balance;
    }


    function callActiveAndInactiveAnatomy(address index) internal view returns(address[] memory){
        IPhutureIndex indexContract = IPhutureIndex(index);
        (address[] memory allAssets,) = indexContract.anatomy();
        address[] memory inactiveAssets = indexContract.inactiveAnatomy();
        if (inactiveAssets.length == 0){
            return allAssets;
        }
        else {
        for(uint i = 0; i < inactiveAssets.length;i++){
            allAssets[i+allAssets.length] = inactiveAssets[i];
        }
            return allAssets;
        }
        
    }

    function getVTokenFactory(address index) internal view returns (address){
        IPhutureIndex indexContract = IPhutureIndex(index);
        return indexContract.vTokenFactory();
    }

    function getVTokenOf(address index, address asset) internal view returns(address){
        IVTokenFactory vTokenFactory = IVTokenFactory(getVTokenFactory(index));
        return vTokenFactory.vTokenOf(asset);
    }

    function getComponents(address index) public view returns(componentStruct[] memory){
        address[] memory underlyingAssetAddresses = callActiveAndInactiveAnatomy(index);
        componentStruct[] memory components = new componentStruct[](underlyingAssetAddresses.length);
        
        for (uint i=0;i<underlyingAssetAddresses.length;i++){
            address _vTokenasset = getVTokenOf(index, underlyingAssetAddresses[i]);
            uint256 _vTokenBalance = IERC20(underlyingAssetAddresses[i]).balanceOf(_vTokenasset);
            components[i] =  componentStruct({
                assetAddress:underlyingAssetAddresses[i],
                balance:_vTokenBalance});  
        }
        return components;
    }
    }