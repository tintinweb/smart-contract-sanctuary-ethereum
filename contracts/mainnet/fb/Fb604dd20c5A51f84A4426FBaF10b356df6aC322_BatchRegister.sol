/**
 *Submitted for verification at Etherscan.io on 2023-03-10
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.17;

interface Register {
    function available(string memory name) external view returns (bool);

    function rentPrice(
        string memory name,
        uint duration
    ) external view returns (uint);

    function commit(bytes32 c) external;

    function registerWithConfig(
        string memory name,
        address owner,
        uint duration,
        bytes32 secret,
        address resolver,
        address addr
    ) external payable;

    function renew(string calldata name, uint duration) external payable;
}

interface Base {
    function nameExpires(uint256 id) external view returns (uint);
}

interface ENS {
    function resolver(bytes32 node) external view returns (address);
}

interface Resolver {
    function addr(
        bytes32 node,
        uint256 coinType
    ) external view returns (bytes memory);
}

contract BatchRegister {
    Register register;

    constructor(address addr) {
        register = Register(addr);
    }

    function batch_available(
        string[] calldata name_list
    ) external view returns (bool[] memory) {
        bool[] memory ret = new bool[](name_list.length);
        for (uint i = 0; i < name_list.length; i++) {
            ret[i] = register.available(name_list[i]);
        }
        return ret;
    }

    function batch_commit(bytes32[] calldata c_list) external {
        for (uint i = 0; i < c_list.length; i++) {
            register.commit(c_list[i]);
        }
    }

    function batch_renew(
        string[] calldata name_list,
        uint[] calldata duration_list
    ) external payable {
        uint cost = 0;
        for (uint i = 0; i < name_list.length; i++) {
            string memory name = name_list[i];
            uint duration = duration_list[i];
            uint price = register.rentPrice(name, duration);
            register.renew{value: price}(name, duration);
            cost += price;
        }

        if (msg.value > cost) {
            payable(msg.sender).transfer(msg.value - cost);
        }
    }

    function batch_registerWithConfig(
        string[] calldata name_list,
        address[] calldata owner_list,
        uint[] calldata duration_list,
        bytes32[] calldata secret_list,
        address[] calldata resolver_list,
        address[] calldata addr_list
    ) external payable {
        uint cost = 0;
        for (uint i = 0; i < name_list.length; i++) {
            string memory name = name_list[i];
            address owner = owner_list[i];
            uint duration = duration_list[i];
            bytes32 secret = secret_list[i];
            address resolver = resolver_list[i];
            address addr = addr_list[i];
            uint price = register.rentPrice(name, duration);
            register.registerWithConfig{value: price}(
                name,
                owner,
                duration,
                secret,
                resolver,
                addr
            );
            cost += price;
        }

        if (msg.value > cost) {
            payable(msg.sender).transfer(msg.value - cost);
        }
    }

    // base         0x57f1887a8BF19b14fC0dF6Fd9B2acc9Af147eA85
    function batch_expires(
        address addr,
        uint256[] calldata id_list
    ) external view returns (uint[] memory) {
        Base base = Base(addr);
        uint[] memory ret = new uint[](id_list.length);
        for (uint i = 0; i < id_list.length; i++) {
            ret[i] = base.nameExpires(id_list[i]);
        }
        return ret;
    }

    // ens: 0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e
    // coinTypes: [367, 1815, 457, 55, 425, 283, 472, 9001, 16754, 111, 118, 9000, 9005, 999, 145, 204, 570, 714, 576, 519, 9006, 236, 0, 156, 153, 308, 489, 571, 52752, 309, 820, 394, 5, 42, 20, 301, 3, 354, 2305, 194, 61, 60, 415, 246, 461, 235, 539, 1007, 6060, 592, 17, 2303, 5353, 904, 74, 291, 4218, 304, 566, 459, 141, 434, 192, 568, 134, 2, 330, 966, 22, 326, 256, 2718, 397, 888, 242, 7, 9797, 8964, 270, 1023, 1024, 178, 6, 2301, 4, 931, 175, 1991, 569, 501, 573, 135, 105, 9004, 5757, 57, 589, 500, 889, 195, 1001, 818, 14, 5655640, 360, 5718350, 5741564, 99999, 15, 8444, 43, 535, 148, 128, 144, 1729, 77, 133, 121, 313]
    function search_bind_addr(
        address ens,
        bytes32 node,
        uint256[] calldata coinTypes
    ) external view returns (bytes[] memory) {
        Resolver resolver = Resolver(ENS(ens).resolver(node));
        bytes[] memory ret = new bytes[](coinTypes.length);
        for (uint i = 0; i < coinTypes.length; i++) {
            ret[i] = resolver.addr(node, coinTypes[i]);
        }
        return ret;
    }
}