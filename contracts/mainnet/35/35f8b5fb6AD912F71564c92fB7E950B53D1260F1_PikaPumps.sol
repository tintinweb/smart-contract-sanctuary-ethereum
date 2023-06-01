/**
 *Submitted for verification at Etherscan.io on 2023-06-01
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

interface IToken {

    function transferFrom(address, address, uint256) external returns(bool);
}

interface IPool {

    function swap(uint256, uint256, address, bytes calldata) external;
}

contract PikaPumps {

    IToken PIKA;
    IToken WETH;

    IPool POOL;

    constructor() {

        PIKA = IToken(0xa9D54F37EbB99f83B603Cc95fc1a5f3907AacCfd);
        WETH = IToken(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

        POOL = IPool(0x132BC4EA9E5282889fDcfE7Bc7A91Ea901a686D6);
    }

    function pump(uint256 inputWETH, uint256 outputPIKA) external {

        WETH.transferFrom(msg.sender, address(POOL), inputWETH);

        POOL.swap(outputPIKA, 0, msg.sender, new bytes(0));
    }
}