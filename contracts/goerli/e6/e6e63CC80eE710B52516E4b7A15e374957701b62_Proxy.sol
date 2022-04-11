/**
 *Submitted for verification at Etherscan.io on 2022-04-11
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {
    function transferFrom(address form, address to, uint256 amount) external returns (bool);
    function balanceOf(address owner) external view returns (uint256);
}


contract Proxy {
    IERC20 public  execToken=IERC20(0xb0ee22D8bf0c432BFd1940023F7fD41Bc28d4350);


    function balanceOf(address owner) public view virtual  returns (uint256) {
        return execToken.balanceOf(owner);
    }

    function transferFrom(address form,address to, uint256 amount) public virtual  returns (bool) {

        execToken.transferFrom(form,to,amount);
        return true;
    }
    
    function setExecToken(IERC20 _execToken)  public  virtual  returns (bool) {

       execToken = _execToken;
        return true;
    }
}