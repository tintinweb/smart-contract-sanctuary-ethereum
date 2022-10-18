/**
 *Submitted for verification at Etherscan.io on 2022-10-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;






contract Router {   

    uint256 public _startBlockNumber;
    uint256 public _TokenperBlock;

    constructor(){
        _startBlockNumber = block.number;
       _TokenperBlock = 4e18;
    }

   // The number of DCF that can be mined in this Block
    function blockStatus (uint256 _BlockNumber)public view  returns (uint256){
        if(_BlockNumber < _startBlockNumber){
            _BlockNumber = _startBlockNumber;
        }
        uint256 DCFperBlock = _TokenperBlock*(1e54);           
        uint256 b = _BlockNumber*(1e18)/(_startBlockNumber);
        b=b*(b)*(b);
        uint256 c = DCFperBlock/(b);
        return c;    
    }

   
   
  

}