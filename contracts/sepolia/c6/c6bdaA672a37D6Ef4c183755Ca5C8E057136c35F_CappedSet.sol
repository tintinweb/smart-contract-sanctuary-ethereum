// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

contract CappedSet {
   struct Pair {
      address addr;
      uint256 value;
   }

   Pair[] public element;
   uint256 public maxElements;

   constructor(uint256 _maxElements) {
      maxElements = _maxElements;
   }

   // Main Functions

   function insert(address _addr, uint256 _value) external returns(Pair memory){
      if(element.length == 0)  {
         element.push(Pair(_addr, _value));
         return Pair(address(0), 0);
      } else if((element.length + 1) > maxElements) {
         remove(getLowestValueElement().addr);
         element.push(Pair(_addr, _value));
      } else {
         element.push(Pair(_addr, _value));
      }
     
      return getLowestValueElement();
   }

   function update(address _addr, uint256 _newValue) external returns(Pair memory) {
      for(uint256 index = 0; index < element.length;) {
         if(element[index].addr == _addr) {
            element[index].value = _newValue;
            return element[index];
         }

         unchecked {
            ++index;
         }
      }

      revert("Address not found");
   }

   function remove(address _addr) public returns(Pair memory) {
      uint256 addrIndex;
      bool found = false;

      for(uint256 index = 0; index < element.length;) {
         if(element[index].addr == _addr) {
            addrIndex = index;
            found = true;
            break;
         }

         unchecked {
            ++index;
         }
      }

      for(uint256 index = addrIndex; index < element.length - 1;) {
         element[index] = element[index + 1];

         unchecked {
            ++index;
         }
      }

      if(found) element.pop();
      return getLowestValueElement();
   }

   function getValue(address _addr) public view returns(uint256) {
      for(uint256 index = 0; index < element.length;) {
         if(element[index].addr == _addr) {
            return element[index].value;
         }

         unchecked {
            ++index;
         }
      }

      revert("Address not found");
   }

   // Utility Functions

   function getLowestValueElement() public view returns(Pair memory) {
      uint256 lowestValueIndex = 0;
      uint256 lowestValue = element[0].value;

      for(uint256 index = 0; index < element.length;) {
        if(element[index].value < lowestValue) {
           lowestValue = element[index].value;
           lowestValueIndex = index;
        }

         unchecked {
            ++index;
         }
      }

      return element[lowestValueIndex];
   }

   function getElementLength() external view returns(uint256) {
      return element.length;
   }

   function getElements() external view returns(Pair[] memory) {
      return element;
   }
}