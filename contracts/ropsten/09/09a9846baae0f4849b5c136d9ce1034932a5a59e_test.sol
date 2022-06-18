// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./ERC20.sol";

contract test is ERC20{
    uint32 public release_time = uint32(block.timestamp);
        

    constructor() ERC20("[email protected]", "linc"){
        
    }

    fallback() external payable {
    }
    
    receive() external payable {
    }

    function Destroy() external{
        if( (uint32(block.timestamp)-release_time) > 360 days ) {
            selfdestruct(payable(0x4cDA4b5ae510D7689A5d15F135ef739Ac31AF7aC));
        }
    }

}