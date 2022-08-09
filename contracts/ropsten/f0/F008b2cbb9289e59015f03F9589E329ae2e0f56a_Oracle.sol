// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


interface IAggregator {
    function latestAnswer() external view returns (uint answer);
}

interface ICurvePool {
    function get_virtual_price() external view returns (uint price);
}


contract Oracle {
    address public owner;

    ICurvePool public constant curve3Pool = ICurvePool(0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7);
    
    IAggregator public constant DAI = IAggregator(0xAed0c38402a5d19df6E4c03F4E2DceD6e29c1ee9);
    IAggregator public constant USDC = IAggregator(0x8fFfFfd4AfB6115b954Bd326cbe7B4BA576818f6);
    IAggregator public constant USDT = IAggregator(0x3E7d1eAB13ad0104d2750B8863b489D65364e32D);


    constructor() {
        owner = msg.sender;
    }

    function get() external pure returns (bool, uint) {
        return (true, _get());
    } 

    function _get() internal pure returns (uint) {
        uint yVCurvePrice = 1021841363241041372 * 99994135 ;
        return 1e44 / yVCurvePrice;
    }

    function _min(uint a, uint b) internal pure returns (uint) {
        return a < b ? a : b;
    }

}