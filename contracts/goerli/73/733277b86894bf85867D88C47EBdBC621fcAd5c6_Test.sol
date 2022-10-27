//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.17;

contract Test{
    uint[] public arr = [55,22,88,45,0,3,528,29];
    event maxx(address indexed  address1 );

    function reorder(uint[] memory arr) public   returns(uint[] memory){
        uint[] memory mod_array = arr;
   
        for (uint j = 0; j < arr.length - 1; j++) {
            for (uint i = 0; i < arr.length - 1 ; i++) {

                if (mod_array[i] > mod_array[i + 1]) {
                    uint arr_of1 = mod_array[i];
                    mod_array[i] = mod_array[i+1];
                    mod_array[i+1] = arr_of1;
                }
            }    
        } 
        emit maxx({address1 : msg.sender});

 
        return mod_array;
    }
}