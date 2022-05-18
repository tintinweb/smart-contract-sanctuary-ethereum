/**
 *Submitted for verification at Etherscan.io on 2022-05-18
*/

// File: contracts/interfaces/IERC20.sol

//SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IERC20 {
    function balanceOf(address owner) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

// File: contracts/Swapper.sol
pragma solidity >=0.8.9;


contract SwitchParaswap {
    address private PARASWAP = 0xDEF171Fe48CF0115B1d80b88dc8eAB59176FEe57; // Paraswap swapper contract
    address private TokenTransferProxy = 0x216B4B4Ba9F3e719726886d34a177484278Bfcae; // Tranfert token contract

    function swap(address srcToken, uint256 amount, bytes memory callData) external payable {

        uint256 ethAmountToTransfert = 0;

        //Check if this contract have enough token or allowance
        if(srcToken == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE){
            require(address(this).balance >= amount, "ETH balance is insufficient");
            ethAmountToTransfert = amount;
        }else{
            if(IERC20(srcToken).balanceOf(address(this)) < amount){
                require(IERC20(srcToken).balanceOf(msg.sender) >= amount && IERC20(srcToken).allowance(msg.sender, address(this)) >= amount, "msg.sender srcToken allowance/balance is insufficient");
                IERC20(srcToken).transferFrom(msg.sender, address(this), amount); // transfert srcToken from caller to this contract
            }
            IERC20(srcToken).approve(TokenTransferProxy, amount); // allow TokenTransferProxy to spend srcToken of this contract
        }

        (bool success,) = PARASWAP.call{value: ethAmountToTransfert}(callData);
        require(success, "Paraswap execution failed");
    }
}