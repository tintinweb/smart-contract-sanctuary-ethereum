/**
 *Submitted for verification at Etherscan.io on 2022-04-26
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

pragma experimental ABIEncoderV2;

contract MultiCall {
    address private immutable owner;
    address private immutable executor;

    modifier onlyExecutor() {
        require(msg.sender == executor);
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor(address _executor) payable {
        owner = msg.sender;
        executor = _executor;
    }

    receive() external payable {
    }

    function multicall(address[] memory _targets, bytes[] memory _payloads) external onlyExecutor payable {
        for (uint256 i = 0; i < _targets.length; i++) {
            (bool _success, bytes memory _response) = _targets[i].call(_payloads[i]);
            require(_success); _response;
        }
    }
}