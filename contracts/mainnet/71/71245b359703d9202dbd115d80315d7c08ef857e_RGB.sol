/**
 *Submitted for verification at Etherscan.io on 2022-06-12
*/

// SPDX-License-Identifier: Apache2
// Ethertone — "The Official Register of Color Names"™, on the Blockchain™
// https://github.com/ctrlcctrlv/ethertone
pragma solidity ^0.8.0;
contract RGB {
    mapping(address => mapping(bytes4 => uint256)) public customers;
    mapping(address => mapping(bytes4 => bytes32)) public names;
    mapping(bytes4 => address) public owners;
    bytes3[] public named_colors;
    address payable public owner = payable(address(0xFffFfffFf8Ca986cDfA7A4189AB6f56621E51362));

    function get_color_name(bytes3 color_in) public view returns (bytes32) {
        bytes4 color = bytes3_to_color(color_in);
        return names[owners[color]][color];  
    }

    function set_owner(address new_owner) public {
        require(msg.sender==owner, "Only owner can change their address");
        owner = payable(new_owner);
    }
          
    function receive_eth(string calldata colorname, bytes3 color_in) external payable returns (uint256) {
        require(msg.value > 0, "Must pay");
        bytes4 color = bytes3_to_color(color_in);
        uint namelength = bytes(colorname).length;
        require(namelength != 0, "Name must be > 1 long");
        customers[msg.sender][color] += msg.value;
        names[msg.sender][color] = bytes32(bytes(colorname));
        uint cur_cost = customers[owners[color]][color];
        uint new_cost = customers[msg.sender][color];
        bool updated = new_cost > cur_cost;
        if (updated) {
            owners[color] = msg.sender;
            named_colors.push(color_in);
            return 0;
        } else {
            return cur_cost - new_cost;
        }
    }

    function cashout() public payable {
        require(msg.sender==owner, "Only owner can trigger cashouts");
        owner.transfer(msg.value+address(this).balance);
    }
    
    function bytes3_to_color(bytes3 color_in) private pure returns (bytes4) {
        bytes memory color_t = '\x00\x00\x00\xFF';
        color_t[0] = color_in[0];
        color_t[1] = color_in[1];
        color_t[2] = color_in[2];
        bytes4 color = bytes4(color_t);
        return color;
    }
}