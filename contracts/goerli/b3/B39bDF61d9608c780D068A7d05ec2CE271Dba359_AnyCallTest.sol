/**
 *Submitted for verification at Etherscan.io on 2023-01-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AnyCallTest {
    event Echo(bytes data);

    /// The AnycallProxy on the Sapphire Testnet.
    address public constant _anycall = 0x965f84D915a9eFa2dD81b653e3AE736555d945f4;

    function echo() external payable {
        // Call this contract via anycall, paying fees inline.
        CallProxy(_anycall).anyCall{value: msg.value}(address(this), "hi", 5, 0, "");
    }

    function anyExecute(bytes memory data) external returns (bool success, bytes memory result) {
        emit Echo(data);
        success = true;
        result = "";
    }
}

interface CallProxy {
    function anyCall(
        address _to,
        bytes calldata _data,
        uint256 _toChainID,
        uint256 _flags,
        bytes calldata _extdata
    ) external payable;

    function config() external view returns (address);

    function context()
        external
        view
        returns (
            address from,
            uint256 fromChainID,
            uint256 nonce
        );

    function executor() external view returns (address executor);
}