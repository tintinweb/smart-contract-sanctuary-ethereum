/**
 *Submitted for verification at Etherscan.io on 2022-08-31
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13; 

contract Ownable {

    address payable m_owner_;

    constructor () { 
        m_owner_ = payable(msg.sender);
    }

    /**
    * @dev Throws if called by any account other than the owner. 
    */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: Only owner can call this fxn"); _;
    }

    /**
    * @dev Returns true if the caller is the current owner. 
    */
    function isOwner() public view returns (bool) { 
        return (msg.sender == m_owner_);
    }

}