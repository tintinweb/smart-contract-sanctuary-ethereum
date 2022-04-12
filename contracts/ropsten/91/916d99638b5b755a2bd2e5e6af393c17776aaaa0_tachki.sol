/**
 *Submitted for verification at Etherscan.io on 2022-04-11
*/

pragma solidity>=0.4.16<0.8.0;

contract tachki {    
    Tachka[] public tachka;           
    uint64 public tachkaCount;    

    struct Tachka {                
      bool usage;
      uint8 doors;
      string brand;
      string colour; 
      uint32 km;
      int32 price; 
    } 

    function add(bool usage, uint8 doors, string memory brand, string memory colour, uint32 km, int32  price ) public {   
      tachkaCount+=1; 
      tachka.push(Tachka( usage, doors, brand, colour, km, price)); 

    }

    function show() public view returns(uint64) {   
        return tachkaCount;
    }
}