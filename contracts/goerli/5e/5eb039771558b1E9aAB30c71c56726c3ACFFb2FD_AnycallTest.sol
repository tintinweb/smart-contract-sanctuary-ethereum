/**
 *Submitted for verification at Etherscan.io on 2023-01-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AnycallTest {
    event Echo(bytes data);

    function echo() external payable {
        // Call this contract back via anycall, paying fees here.
        IAnycallProxy(0x965f84D915a9eFa2dD81b653e3AE736555d945f4 /* anycall proxy */)
            .anyCall{value: msg.value}(address(this), "hi", block.chainid, 0, "");
    }

    function anyExecute(bytes memory data) external returns (bool success, bytes memory result) {
        emit Echo(data);
        success = true;
        result = "";
    }
}

interface IAnycallProxy {
    function executor() external view returns (address);

    function config() external view returns (address);

    function anyCall(
        address _to,
        bytes calldata _data,
        uint256 _toChainID,
        uint256 _flags,
        bytes calldata _extdata
    ) external payable;

    function anyCall(
        string calldata _to,
        bytes calldata _data,
        uint256 _toChainID,
        uint256 _flags,
        bytes calldata _extdata
    ) external payable;
}