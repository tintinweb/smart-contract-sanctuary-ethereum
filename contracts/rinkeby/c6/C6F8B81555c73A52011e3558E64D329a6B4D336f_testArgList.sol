// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "Random.sol";
import "DateTime.sol";

contract testArgList{
    struct City{
        string[] names;
        uint256 size;
        uint8[] translate;
    }

    City[] public cities;
    uint256 public index=0;
    uint8 public degree;
    uint256 public size;

    uint256 public h;
    uint256 public m;
    uint256 public geth;
    uint256 public getm;
    int public diff;

    constructor(){
    }

    function feed(int _diff) public{
        geth= DateTime.getHour();
        getm= DateTime.getMinute();

        diff= int(DateTime.getHour()*60+ DateTime.getMinute())+ _diff;

        if(diff<0){
            diff+= 1440; //24 hours = 1440 mins
        }
            
        h= uint256(diff)/60;
        m= uint256(diff)%60;
    }

    function check(uint256 no) public returns (string memory){
        string memory info="";

        for(uint8 i=0; i< cities[no].names.length; i++){
            info= string(abi.encodePacked(info, cities[no].names[i]));
        }
        size= bytes(cities[no].names[0]).length;
        return info;
    }

    function tt() public {
        uint256 nowHour= 23; // Local time in hour 0-23
        degree= uint8(nowHour*100/23);
    }

    function rand(uint256 seed) view public returns (uint256){
        return Random.randrange(360, seed);
    }
  function _copy(bytes memory a, uint256 from, bytes memory b) pure internal{
    for(uint256 i=0; i< b.length; i++){
        a[i+from]= b[i];
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
/*
          _____                    _____                _____                _____          
         /\    \                  /\    \              /\    \              |\    \         
        /::\    \                /::\    \            /::\    \             |:\____\        
       /::::\    \               \:::\    \           \:::\    \            |::|   |        
      /::::::\    \               \:::\    \           \:::\    \           |::|   |        
     /:::/\:::\    \               \:::\    \           \:::\    \          |::|   |        
    /:::/  \:::\    \               \:::\    \           \:::\    \         |::|   |        
   /:::/    \:::\    \              /::::\    \          /::::\    \        |::|   |        
  /:::/    / \:::\    \    ____    /::::::\    \        /::::::\    \       |::|___|______  
 /:::/    /   \:::\    \  /\   \  /:::/\:::\    \      /:::/\:::\    \      /::::::::\    \ 
/:::/____/     \:::\____\/::\   \/:::/  \:::\____\    /:::/  \:::\____\    /::::::::::\____\
\:::\    \      \::/    /\:::\  /:::/    \::/    /   /:::/    \::/    /   /:::/~~~~/~~      
 \:::\    \      \/____/  \:::\/:::/    / \/____/   /:::/    / \/____/   /:::/    /         
  \:::\    \               \::::::/    /           /:::/    /           /:::/    /          
   \:::\    \               \::::/____/           /:::/    /           /:::/    /           
    \:::\    \               \:::\    \           \::/    /            \::/    /            
     \:::\    \               \:::\    \           \/____/              \/____/             
      \:::\    \               \:::\    \                                                   
       \:::\____\               \:::\____\                                                  
        \::/    /                \::/    /                                                  
         \/____/                  \/____/                                                   
                                                                                            
*/
library Random {
    function randrange(uint256 max, uint256 seed) view internal returns (uint256){
        if(max<=1){
            return 0;
        }
        return uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, seed))) % max;
    }

    function randrange(uint256 min, uint256 max, uint256 seed) view internal returns(uint256){
        if(min> max){
            revert("Min > Max");
        }
        return min+ randrange(max-min, seed);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
          _____                    _____                _____                _____          
         /\    \                  /\    \              /\    \              |\    \         
        /::\    \                /::\    \            /::\    \             |:\____\        
       /::::\    \               \:::\    \           \:::\    \            |::|   |        
      /::::::\    \               \:::\    \           \:::\    \           |::|   |        
     /:::/\:::\    \               \:::\    \           \:::\    \          |::|   |        
    /:::/  \:::\    \               \:::\    \           \:::\    \         |::|   |        
   /:::/    \:::\    \              /::::\    \          /::::\    \        |::|   |        
  /:::/    / \:::\    \    ____    /::::::\    \        /::::::\    \       |::|___|______  
 /:::/    /   \:::\    \  /\   \  /:::/\:::\    \      /:::/\:::\    \      /::::::::\    \ 
/:::/____/     \:::\____\/::\   \/:::/  \:::\____\    /:::/  \:::\____\    /::::::::::\____\
\:::\    \      \::/    /\:::\  /:::/    \::/    /   /:::/    \::/    /   /:::/~~~~/~~      
 \:::\    \      \/____/  \:::\/:::/    / \/____/   /:::/    / \/____/   /:::/    /         
  \:::\    \               \::::::/    /           /:::/    /           /:::/    /          
   \:::\    \               \::::/____/           /:::/    /           /:::/    /           
    \:::\    \               \:::\    \           \::/    /            \::/    /            
     \:::\    \               \:::\    \           \/____/              \/____/             
      \:::\    \               \:::\    \                                                   
       \:::\____\               \:::\____\                                                  
        \::/    /                \::/    /                                                  
         \/____/                  \/____/                                                   
                                                                                            
*/

library DateTime {

    uint constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint constant SECONDS_PER_HOUR = 60 * 60;
    uint constant SECONDS_PER_MINUTE = 60;

    function getHour() internal view returns (uint hour) {
        uint secs = block.timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
    }
    function getMinute() internal view returns (uint minute) {
        uint secs = block.timestamp % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
    }
}