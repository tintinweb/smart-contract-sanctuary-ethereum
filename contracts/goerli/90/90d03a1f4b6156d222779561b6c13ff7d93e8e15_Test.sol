/**
 *Submitted for verification at Etherscan.io on 2022-10-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IFxBridge {
    function sendToFx(address _tokenContract, bytes32 _destination, bytes32 _targetIBC, uint256 _amount) external;
}

interface IERC20 {
    function transferFrom(address from, address to, uint value) external;

    function approve(address spender, uint value) external;
}

contract Test {
    
    address public fxBridge = 0xB1B68DFC4eE0A3123B897107aFbF43CEFEE9b0A2;

    constructor () {}

    function sendToFx(address _tokenContract, bytes32 _destination, bytes32 _targetIBC, uint256 _amount) external {
        IERC20(_tokenContract).transferFrom(msg.sender, address(this), _amount);
        IERC20(_tokenContract).approve(fxBridge, _amount);
        IFxBridge(fxBridge).sendToFx(_tokenContract, _destination, _targetIBC, _amount);
    }
}