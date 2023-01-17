// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract simpleTrade{

    function swap(bytes[] memory _data)public payable{

        for(uint256 i=0; i<_data.length;i++){

            (address target, bytes memory callData,uint256 tokenValue) = abi.decode(_data[i],(address,bytes,uint256));
            (bool success,) = target.call{value: tokenValue}(callData);
            require(success,"failed");
        }
    }

    receive() external payable{}

}