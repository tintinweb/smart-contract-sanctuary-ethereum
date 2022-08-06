/**
 *Submitted for verification at Etherscan.io on 2022-08-06
*/

//SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;


abstract contract Auth {
   address internal owner;
   mapping (address => bool) internal authorizations;
 
   constructor(address _owner) {
       owner = _owner;
       authorizations[_owner] = true;
   }
}
interface IERC20 {
    // event Approval(address indexed owner, address indexed spender, uint value);
    // event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    // function totalSupply() external view returns (uint);
    // function balanceOf(address owner) external view returns (uint);
    // function allowance(address owner, address spender) external view returns (uint);

    // function approve(address spender, uint value) external returns (bool);
    // function transfer(address to, uint value) external returns (bool);
    // function transferFrom(address from, address to, uint value) external returns (bool);
}


contract CREATEYO is IERC20{
    string constant _name = "YoYo";
    string constant _symbol = "YO";
    uint8 constant _decimals = 9;


    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
}