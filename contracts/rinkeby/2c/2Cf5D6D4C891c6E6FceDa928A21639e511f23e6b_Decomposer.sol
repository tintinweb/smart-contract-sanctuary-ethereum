pragma solidity ^0.5.0;
import "./Folia.sol";

/*
     _                                                    
    | |                                                   
  __| | ___  ___ ___  _ __ ___  _ __   ___  ___  ___ _ __ 
 / _` |/ _ \/ __/ _ \| '_ ` _ \| '_ \ / _ \/ __|/ _ \ '__|
| (_| |  __/ (_| (_) | | | | | | |_) | (_) \__ \  __/ |   
 \__,_|\___|\___\___/|_| |_| |_| .__/ \___/|___/\___|_|   
                               | |                        
                               |_|                        
By Oliver Laric
Produced by Folia.app
*/

contract Decomposer is Folia {
    constructor(address _metadata) public Folia("Decomposer", "DCMP", _metadata){}
}