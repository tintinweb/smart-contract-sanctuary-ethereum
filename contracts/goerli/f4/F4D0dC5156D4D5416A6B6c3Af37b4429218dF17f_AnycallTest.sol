/**
 *Submitted for verification at Etherscan.io on 2023-01-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AnycallTest {
    event Echo(bytes data);

    bool public immutable payOnDest;

    constructor(bool _payOnDest) {
        payOnDest = _payOnDest;
    }

    function echo() external payable {
        // Call this contract back via anycall, paying fees on the destination chain.
        IAnycallProxy(anycallProxy()).anyCall{value: msg.value}(
            address(this),
            "echo",
            block.chainid,
            payOnDest ? 2 : 0,
            ""
        );
    }

    function anyExecute(bytes memory _data) external returns (bool success, bytes memory result) {
        emit Echo(_data);
        return (true, "");
    }

    function anycallProxy() public view returns (address) {
        if (block.chainid == 5) return 0x965f84D915a9eFa2dD81b653e3AE736555d945f4;
        if (block.chainid == 0x61) return 0xcBd52F7E99eeFd9cD281Ea84f3D903906BB677EC;
        if (block.chainid == 0x5aff) return 0x4792C1EcB969B036eb51330c63bD27899A13D84e;
        revert("unsupported chain");
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

interface IFeePool {
    function deposit(address _account) external payable;

    function withdraw(uint256 _amount) external;

    function executionBudget(address _account) external view returns (uint256);
}