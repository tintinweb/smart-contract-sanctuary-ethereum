/**
 *Submitted for verification at Etherscan.io on 2022-08-14
*/

// SPDX-License-Identifier: GPL-3.0
// 0x281725fc1AD9AEDeFb8ADb1f4572E97CA918ED00

pragma solidity >=0.7.0 <0.9.0;

contract Storage {

    mapping(address => uint) private map_addr;
    bool use_whitelist = true;
    uint count = 0;
    
    constructor() {
        address a = 0x6b3323b9671447bB3B51dCcC8Dd2f189254E0939;
        add_whitelist(a);
    }

    function is_whitelist(address addr) public view returns(uint) {
        return map_addr[addr];
    }

    function is_whitelist_2() public view returns(uint) {
        return map_addr[msg.sender];
    }

    function add_whitelist(address a) public {
        require(map_addr[a] == 0);

        map_addr[a] = 1;
    }
    
    function del_whitelist(address a) public {
        require(map_addr[a] != 0);

        // map_data[a] = 0;
        delete map_addr[a];
    }

    function set_use_whitelist(bool b) public {
        use_whitelist = b;
    }
    
    function mint_a() public {
        if(use_whitelist) {
            require(is_whitelist_2() != 0);
        }

        count++;
        // _mint(no, link);
    }
}