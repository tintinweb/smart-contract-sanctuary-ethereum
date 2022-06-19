//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract balanceManager 
{ 
    mapping(uint256 => int256) public positionCollateral;
    mapping(uint256 => int256) public marginWillRequired;

 

    function getPositionCollateralValue(uint positionId)
        external
        view 
        returns(int256 positionCollateralValue){
           positionCollateralValue  = positionCollateral[positionId];
        }

    function getMarginRequirementForPositionLiquidation(uint256 positionId) external view returns(int256 marginRequired){
        marginRequired  = marginWillRequired[positionId];
    }

    function update(uint256 _id, int256 _collateral, int256 _margin) external {
        positionCollateral[_id] = _collateral;
        marginWillRequired[_id] = _margin;
    } 


}