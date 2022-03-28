/**
    1. SupraBridge will interact with Anchor contract.
    2. This contract knows current implementation contract through ProxyAdmin contract.
    3. ISupra :::: current implementation contract.
    4. IProxy :::: ProxyAdmin contract.

    Note :: Curently implementation contract(Supra, SupraV2) function => storeFeed is 
            callable by any address because in future only afer signature verification 
            the data can be updated in the smart contract.
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Anchor1 {

   function getResult(uint256 number) public pure virtual returns (uint256){               
        return bonus()*number;
   }

   function bonus() public pure returns(uint256){
       return 100;
    }


}