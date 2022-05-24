/**
 *Submitted for verification at Etherscan.io on 2022-05-24
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8;

contract Test {

    
    address public immutable  factory;
    address public immutable  WETH;

    constructor(address _fac, address _WETH) {
        factory = _fac;
        WETH = _WETH;
    }

    event Failed(string reasonString, bytes reason);

    function del(address con, bytes memory data) external payable {
        (bool success, bytes memory message) = con.delegatecall(data);
        if(!success) {
            emit Failed(string(message), message);
        }
        require(success, "Failed");
    }

    receive() external payable {}
}