/**
 *Submitted for verification at Etherscan.io on 2022-11-09
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Multicall  {

    function approve(address spender, uint256 amount, address token) external returns (bool){
        IERC20(token).approve(spender,amount);
        return true;
    }

    receive() external payable {}

    fallback() external payable {}

    struct Call {
        address target;
        bytes callData;
        uint receiveCantidad;
    }

    function multiple4(Call[] memory calls) public payable returns (uint256 blockNumber, bytes[] memory returnData) {
        blockNumber = block.number;
        returnData = new bytes[](calls.length);
        for(uint256 i = 0; i < calls.length; i++) {
            (bool success, bytes memory ret) = calls[i].target.call{value:calls[i].receiveCantidad,gas:block.gaslimit}(calls[i].callData);
            require(success);
            returnData[i] = ret;
        }
    }

    function getEthBalance(address addr) public view returns (uint256 balance) {
        balance = addr.balance;
    }

    function envioTransfer(address payable receiverAddr, uint receiverAmnt) public payable {
        receiverAddr.transfer(receiverAmnt);
    }

}