/**
 *Submitted for verification at Etherscan.io on 2022-11-16
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

interface IPrometheansLike {
    function currentEmber() external view returns (uint256);
    function mintTo(address destination_) external payable;
}

contract GelatoResolver {
    function checker(address prometheans, uint256 tokenReceiver, uint256 ember_)
        external
        view
        returns (bool canExec, bytes memory execPayload)
    {
        uint256 currentEmber = IPrometheansLike(prometheans).currentEmber();

        canExec = currentEmber <= ember_;

        execPayload = abi.encodeWithSelector(IPrometheansLike.mintTo.selector, tokenReceiver);
    }
}