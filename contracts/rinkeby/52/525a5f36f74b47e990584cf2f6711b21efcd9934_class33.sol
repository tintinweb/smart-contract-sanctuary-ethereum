/**
 *Submitted for verification at Etherscan.io on 2022-02-16
*/

pragma solidity ^0.4.24;
contract class33{
    //函數外面的參數，默認為storage
   uint x;
   uint y = 10;
       
    struct fruit{
        uint id;
        string name;
   }
    
   fruit[12] public fruitarray;
   mapping(address => fruit) public fruitmapping;

   function example1(uint i,string n)public{
        fruit storage fruit1= fruitmapping[0];
        fruit1.id = i;
        fruit1.name = n;
        
        fruit storage fruit2 = fruitmapping[0x5B38Da6a701c568545dCfcB03FcB875f56beddC4];
        fruit2.name=n;
    }
    
    function example2(uint i,string n)public view{
        //不會改變鏈上資訊
        fruit memory fruit1 = fruitarray[0];
        fruit1.id = i;
        fruit1.name = n;
    }
}