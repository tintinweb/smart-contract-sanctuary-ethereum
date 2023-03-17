// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;


// Exchange Curve ---* Swap a stablecoin on Curve *--- //

contract ExchangeCurve {

    function exchangeStablecoin(
        address _onBehalf, 
        uint _amount,
        uint _leverage,
        bytes calldata _data
    ) 
        public 
        returns (bytes memory txData) 
    {
        (uint256 toSellId, uint256 toReceiveId) = abi.decode(_data,(uint256,uint256));
        txData = abi.encodePacked(uint8(0),0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7,uint256(0),uint256(132),abi.encodeWithSignature(
            "exchange(int128,int128,uint256,uint256)", toSellId, toReceiveId, _amount,0));
    }
}