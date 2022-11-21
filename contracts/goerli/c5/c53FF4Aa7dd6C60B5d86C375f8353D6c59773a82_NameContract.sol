//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;


contract NameContract  {

    uint256 public var1 = 12;




    function returner1() public view returns(uint256) {
        return 5;
    }

     function returner2(uint256 _intvar1) public view returns(uint256) {
        return _intvar1;
    }

    function returner3() public view returns(uint256 var2) {
        var2 =5;
        return var2;
    }

    function storageChanger() public {
        var1 = 14;
    }

    function blockReader() public returns(uint256) {
       // return block.number > block.number -5; //to use ethers in test. may be diffrerent utils etc.

    }

    function memoryReader(string memory _name) public returns(string memory) {
        return _name; //can we test what is in memory? read slots etc?
    }








    
    

}