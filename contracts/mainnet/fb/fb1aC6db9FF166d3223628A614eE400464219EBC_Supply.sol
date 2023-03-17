// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;


// Supply ---* Supply a token to Aave V2 *--- //

contract Supply {

    function supplyAaveV2(
        address _onBehalf, 
        uint _amount,
        uint _leverage,
        bytes calldata _data
    ) 
        public 
        returns (bytes memory txData) 
    {
        (address token, address lendingPool) = abi.decode(_data,(address,address));
        txData = abi.encodePacked(uint8(0),lendingPool,uint256(0),uint256(132),abi.encodeWithSignature(
                "deposit(address,uint256,address,uint16)", token, _amount ,_onBehalf,0));
    
        return txData;
    }
}