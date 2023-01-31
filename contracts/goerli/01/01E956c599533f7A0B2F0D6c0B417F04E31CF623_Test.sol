//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.7;

// Hello St Martin
contract Test {
    event Response(bool success, bytes data);

    address public Sushi = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;
    address public Uni = 0xE592427A0AEce92De3Edee1F18E0157C05861564;

    uint256 public sushiQuote;

    function testing() public payable {
        (bool success, bytes memory data) = Sushi.call{value:msg.value, gas: 5000}(
            
            abi.encodeWithSignature("quote(uint256,uint256,uint256)", 1,1,1)
        );

        emit Response(success, data);
    }

}