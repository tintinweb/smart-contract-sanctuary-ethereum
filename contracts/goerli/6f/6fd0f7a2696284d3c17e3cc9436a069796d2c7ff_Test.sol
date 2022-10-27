/**
 *Submitted for verification at Etherscan.io on 2022-10-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IFxBridge {
    function sendToFx(address _tokenContract, bytes32 _destination, bytes32 _targetIBC, uint256 _amount) external;
}

interface IERC20 {
    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
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