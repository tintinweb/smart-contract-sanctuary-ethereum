// SPDX-License-Identifier: MIT
 
/*
                                                                                               
 .oooooooo oooo d8b  .oooo.    .ooooo.  oooo    ooo 
888' `88b  `888""8P `P  )88b  d88' `"Y8  `88.  .8'  
888   888   888      .oP"888  888         `88..8'   
`88bod8P'   888     d8(  888  888   .o8    `888'    
`8oooooo.  d888b    `Y888""8o `Y8bod8P'     .8'     
d"     YD                               .o..P'      
"Y88888P'                               `Y8P'       
                                                    

*/
 
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";

contract GRACY is Ownable, ERC20 {
    constructor(uint256 initialSupply) ERC20("Gracy Token", "GRACY") {
        _mint(msg.sender, initialSupply);
    }
}