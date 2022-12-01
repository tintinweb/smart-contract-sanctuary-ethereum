// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

/*
                                        
                 --.                    
               .*%@*=.                  
              .##++=***+:               
            :+*#%#**#*#%#+.             
          .+##+-#%###%%%%%+             
        :+#+:..-#%%%%%#*+++             
 .::---=##++*#%%%%#%%##*==*             
  :#%%%%%%%%%%%%%%%%####+*#-            
 -*==#%%%%%%%%%#***#####%##*.           
.: .=%%%%%%%%#****%%###%%%#**.          
   :-=%%%%%%*#**#%%%#%#%%%%#%*:         
     #%%%%%%+**%##%#=#%%%%%%%%*:        
     :.--+###*+-.::   *#%%#%%%#=.       
        .****.:::::::+#%%%%%%%#++       
...::::-*#**==++++++*%%%%%%%%%%##*=.    
.::----=##*===++++++*%%%%%%%%%%%%###*:  
::::::=##=----==++++*%%%%%%%%%%%%%%%#*. 
:-===*##+.     ..-=++*#%%%%%%%%%%%%*+.  
 .:-**+.            ...:--====-::..  
 *
 *
 *
 * This is a stateless instance for the purpose of the Hyperclone Transcendance campaign
 */
contract HyperwarpManager {

    function battlerHasUtility(uint256 _tokenId) public pure returns(bool) {
        return false;
    }

    function tryHyperwarp(uint256 _jumpClone, uint256 _assist) external pure returns(bool) {
        require(_jumpClone != _assist, "Jumpcloner and assist must be different");
        return true;
    }

    function tryManifest(uint256 _tokenId) external pure returns(bool) {
        return true;
    }
}