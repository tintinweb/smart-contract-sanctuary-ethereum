// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library CollectionArray{
    using CollectionArray for users;

    struct users{
        address[] array;
    }


    function add(users storage self, address _address) external {
        if (!exists(self, _address)){
            self.array.push(_address);
        }
    }

    function exists(users storage self, address _address) internal view returns(bool){
        for(uint256 i = 0; i < self.array.length; i++){
            if (self.array[i] == _address){
                return true;
            }
      }
      return false;
    }

}