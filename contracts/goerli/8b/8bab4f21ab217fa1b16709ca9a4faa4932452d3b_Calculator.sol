// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Calculator{
    
     uint256 public result;

    function add(uint256 x, uint256 y) external{
        result = x+y;
    }

}

contract Mediator{

    address constant calculator = 0xabb59b45A108c61Edc74d4a69386C9B2A79bE00b;

    fallback() external{
        if (msg.data.length > 0) {
            calculator.call(msg.data);
        }
    }
}

contract MyContract{

    address constant mediator = 0xe2964e5532EdC2e4E236099BEfd827E1F43439Ea;
    bytes public data;

    function invokeFallback(uint256 x,uint256 y) external{
        data = abi.encodeWithSelector(bytes4(keccak256("add(uint256,uint256)")),x,y);

        mediator.call(data);
    }
}