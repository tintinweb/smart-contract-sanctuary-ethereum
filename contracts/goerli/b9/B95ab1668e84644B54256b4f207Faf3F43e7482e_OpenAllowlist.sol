pragma solidity >=0.8.0 <0.9.0;
// SPDX-License-Identifier: MIT
import "../interfaces/allowlist/IAllowlistManager.sol";
  

contract OpenAllowlist is IAllowlistManager  {
 
    event UpdatedAllowList(uint256 commitmentId); 

    constructor( ){  
        
    }

    function addressIsAllowed(uint256, address) public virtual returns (bool) {
        return true;
    }

     
}

interface IAllowlistManager {

 
    function addressIsAllowed(uint256 _commitmentId,address _account) external returns (bool allowed_) ;
 
}