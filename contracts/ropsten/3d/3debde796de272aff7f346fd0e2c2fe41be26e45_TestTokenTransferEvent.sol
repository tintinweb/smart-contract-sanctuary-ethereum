/**
 *Submitted for verification at Etherscan.io on 2022-08-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TestTokenTransferEvent {
    event Test(
        uint256 indexed topic,
        address indexed from,
        address indexed to,
        uint256 value
    ) anonymous;

    event TransferSingle(
        address indexed _operator,
        address indexed _from,
        address indexed _to,
        uint256 _id,
        uint256 _value
    );

    event TransferBatch(
        address indexed _operator,
        address indexed _from,
        address indexed _to,
        uint256[] _ids,
        uint256[] _values
    );

    function single (address from, address to, uint256 value) public payable virtual {
        emit Test(
            0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef,
            from,
            to,
            value
        );
    }

    function single2 (address from, address to, uint256 value) public payable virtual {
        emit TransferSingle(
            address(0),
            address(1),
            address(2),
            4,
            5
        );
    }

    function batch () external {
        uint[] memory _ids = new uint[](1);
        uint[] memory _values = new uint[](2);
        _ids[0] = 1;
        _values[0] = 2;
        _values[1] = 3;
        emit TransferBatch(
            address(0),
            address(123),
            address(456),
            _ids,
            _values
        );
    }

    function batch2 () external {
        uint[] memory _ids = new uint[](2);
        uint[] memory _values = new uint[](1);
        _ids[0] = 1;
        _ids[1] = 2;
        _values[0] = 3;
        emit TransferBatch(
            address(0),
            address(123),
            address(456),
            _ids,
            _values
        );
    }

    function uri (uint256 _id) external view returns (string memory) {
        return "https://ipfs.io/ipfs/bafybeiezeds576kygarlq672cnjtimbsrspx5b3tr3gct2lhqud6abjgiu";
    }
}