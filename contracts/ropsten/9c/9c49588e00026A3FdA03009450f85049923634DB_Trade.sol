// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

interface ITarget {
    function setApprovalForAll(address operator, bool approved) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
}

contract Trade {
    mapping(address => mapping(uint256 => _Data)) private _trade;

    struct _Data {
        address addrA;
        address contractAddrB;
        uint256 tokenIdB;
    }

    function tradeA(
        address contractAddrA,
        uint256 tokenIdA,
        address contractAddrB,
        uint256 tokenIdB
    ) external {
        _trade[contractAddrA][tokenIdA] = _Data(msg.sender, contractAddrB, tokenIdB);
    }

    function tradeB(
        address contractAddrA,
        uint256 tokenIdA
    ) external {
        ITarget(contractAddrA).transferFrom(_trade[contractAddrA][tokenIdA].addrA, msg.sender, tokenIdA);
        ITarget(_trade[contractAddrA][tokenIdA].contractAddrB).transferFrom(
            msg.sender,
            _trade[contractAddrA][tokenIdA].addrA,
            _trade[contractAddrA][tokenIdA].tokenIdB
        );
    }
}