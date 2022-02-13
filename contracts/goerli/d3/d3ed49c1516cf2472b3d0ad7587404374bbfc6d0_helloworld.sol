/**
 *Submitted for verification at Etherscan.io on 2022-02-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract helloworld {
    string name;
    bool public saleIsActive = false;
    uint256 public n_state = 1;
    uint256 public publicTokenPrice = 0.0269 ether;

    function changeState(uint256 newState) public {
        n_state = newState;
    }

    event e_mint(address indexed_from, uint numberOfTokens);
    function mint(uint numberOfTokens) external payable {
        n_state = numberOfTokens;
        emit e_mint(msg.sender, numberOfTokens);
    }

    function get_name() public view returns (string memory) {
        return name;
    }
    
    event Set_name(address indexed_from, string n);
    function set_name(string memory n) public {
        name = n;
        emit Set_name(msg.sender, n);
    }

    function add(uint256 count) public {
        n_state = count + n_state;
    }
}