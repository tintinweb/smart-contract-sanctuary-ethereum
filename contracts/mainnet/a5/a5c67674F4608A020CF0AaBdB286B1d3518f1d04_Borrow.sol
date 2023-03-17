// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;


// Borrow ---* Borrow a token on Aave V2 *--- //

contract Borrow {

    function borrowAaveV2(
        address _onBehalf, 
        uint _amount,
        uint _leverage,
        bytes calldata _data
    ) 
        public 
        returns (bytes memory txData) 
    {
       (address token, address lendingPool) = abi.decode(_data,(address,address));
        txData = abi.encodePacked(uint8(0),lendingPool,uint256(0),uint256(164),abi.encodeWithSignature(
                "borrow(address,uint256,uint256,uint16,address)", token, _amount,2,0,_onBehalf));
            
        return txData;
    }
}