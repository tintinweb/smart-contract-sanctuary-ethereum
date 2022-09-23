/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

/**
 *Submitted for verification at Etherscan.io on 2022-08-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IBEP20 {

        function balanceOf(address account) external view returns (uint256);
        function transferFrom(address sender,address recipient,uint256 amount) external returns (bool);
        function allowance(address owner, address spender) external view returns(uint256);
    }


contract AirDrop{
    
    address public owner;
    
    constructor(){
        
        owner = msg.sender;
    }
    
    function doAirDrop(IBEP20 _token, address[] memory _to, uint256[] memory _amount)  public returns(bool) {
    
        require(_to.length == _amount.length, "addresses & amounts length should be same.");
        
        for (uint256 i = 0; i < _to.length; i++){
            
            _token.transferFrom(msg.sender, _to[i], _amount[i]);
        }
        
        return true;
    }

}