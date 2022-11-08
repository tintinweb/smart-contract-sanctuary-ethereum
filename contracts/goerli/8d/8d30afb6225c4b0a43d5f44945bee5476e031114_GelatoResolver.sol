/**
 *Submitted for verification at Etherscan.io on 2022-11-07
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

interface IPrometheansLike {
    function currentEmber() external view returns (uint256);
    function mint() external payable;
}

contract GelatoResolver {
    IPrometheansLike public immutable prometheans;

    constructor(address _prom) {
        prometheans =IPrometheansLike(_prom);
    }

    function checker(uint256 ember_)
        external
        view
        returns (bool canExec, bytes memory execPayload)
    {
        uint256 currentEmber = prometheans.currentEmber();

        canExec = currentEmber == ember_;

        execPayload = abi.encode(IPrometheansLike.mint.selector);
    }
}