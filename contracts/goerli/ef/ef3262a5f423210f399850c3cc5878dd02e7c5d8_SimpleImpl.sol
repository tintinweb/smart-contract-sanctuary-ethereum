/**
 *Submitted for verification at Etherscan.io on 2023-01-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
contract SimpleImpl {
    address public implementation; 
    address public admin; 
    uint public ff;

    event ffevent(uint ff);

    function increase() public{
        ff++;
        emit ffevent(ff);
    }

    function decrease() public{
        ff--;
        emit ffevent(ff);
    }
    
    function upgrade(address newImplementation) external {
        require(msg.sender == admin);
        implementation = newImplementation;
    }

    function value() public view returns (uint) {
        uint xx = ff;
        return xx;
    }
}