// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;


// Approve ERC20 ---* Approve an ERC20 Token *--- //

contract Approve {

    function approveERC20(
        address _onBehalf, 
        uint _amount,
        uint _leverage,
        bytes calldata _data
    ) 
        public 
        returns (bytes memory txData) 
    {
        (address token, address to) = abi.decode(_data,(address,address));
        if (_amount>0){
            txData = abi.encodePacked(uint8(0),token,uint256(0),uint256(68),abi.encodeWithSignature(
            "approve(address,uint256)", to, _amount));
        } else {
            txData = abi.encodePacked(uint8(0),token,uint256(0),uint256(68),abi.encodeWithSignature(
            "approve(address,uint256)", to, type(uint256).max));
        }

        return txData;
    }
}