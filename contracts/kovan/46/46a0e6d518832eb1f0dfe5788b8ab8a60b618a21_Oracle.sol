/**
 *Submitted for verification at Etherscan.io on 2022-04-04
*/

// SPDX-License-Identifier: MIT
pragma solidity >0.8.0;

interface OracleInterface {
    function retireveTargetAssets()
        external
        view
        returns (
            string[] memory
        );
}

contract Owner {
    address owner;
    constructor() {
        owner = msg.sender;
    }
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}

contract Oracle is Owner {
    string[] public targetAssets = ['WETH','WBTC','NMN','FRO','DAI'];

    function retireveTargetAssets()
        external
        view
        returns (
            string[] memory
        )
    {
        return (
            targetAssets
        );
    }
}