// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;


contract Pizza {
   uint256 internal slices;


   event SlicesLeft(uint256 left);


   function initialize(uint256 _slices) public {
       slices = _slices;
   }


   function eatSlices(uint256 _n) external {
       require(slices >= 1, "No slices left.");
       require(_n <= slices, "Cannot eat more slices.");
       slices -= _n;
       emit SlicesLeft(slices);
   }


   function slicesLeft() external view returns (uint256) {
       return slices;
   }


   function refillSlices(uint256 _n) external {
       slices += _n;
   }
}