/**
 *Submitted for verification at Etherscan.io on 2022-07-25
*/

/// SPDX-License-Identifier: AGPL-3.0
/// Original credit https://github.com/packzone/packzone
pragma solidity 0.8.13;

interface Dmap {
    error LOCKED();
    event Set(
        address indexed zone,
        bytes32 indexed name,
        bytes32 indexed meta,
        bytes32 indexed data
    ) anonymous;

    function set(bytes32 name, bytes32 meta, bytes32 data) external;
    function get(bytes32 slot) external view returns (bytes32 meta, bytes32 data);
}

contract SimpleNameZone {
    Dmap immutable public dmap;
    address public auth;

    event Give(address indexed giver, address indexed heir);

    error ErrAuth();

    constructor(Dmap _dmap_) {
        dmap = _dmap_;
        auth = msg.sender;
    }

    function stow(bytes32 name, bytes32 meta, bytes32 data) external {
        if (msg.sender != auth) revert ErrAuth();
        dmap.set(name, meta, data);
    }

    function give(address heir) external {
        if (msg.sender != auth) revert ErrAuth();
        auth = heir;
        emit Give(msg.sender, heir);
    }

    function read(bytes32 name) external view returns (bytes32 meta, bytes32 data) {
        bytes32 slot = keccak256(abi.encode(address(this), name));
        (meta, data) = dmap.get(slot);
        return (meta, data);

    }
}

contract SimpleNameZoneFactory {
    Dmap immutable public dmap;
    mapping(address=>bool) public made;

    event Make(address indexed caller, address indexed zone);

    constructor(Dmap _dmap_) {
        dmap = _dmap_;
    }

    function make() payable external returns (SimpleNameZone) {
        SimpleNameZone zone = new SimpleNameZone(dmap);
        made[address(zone)] = true;
        zone.give(msg.sender);
        emit Make(msg.sender, address(zone));
        return zone;
    }
}