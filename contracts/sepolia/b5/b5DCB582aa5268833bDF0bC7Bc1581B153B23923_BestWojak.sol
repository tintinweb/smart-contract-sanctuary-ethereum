/**
 *Submitted for verification at Etherscan.io on 2023-06-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BestWojak {
    string public name = "BestWojak";
    string public symbol = "$BESTWOJAK";
    uint256 public totalSupply = 50000000000000;

    mapping(address => uint256) balances;

    constructor() {
        balances[0xf15C1BD5d1baD51E8Ef5881e561D45eDd2436Ab2] = totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }
}