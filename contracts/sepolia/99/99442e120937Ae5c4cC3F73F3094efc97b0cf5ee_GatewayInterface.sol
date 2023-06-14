// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;

contract GatewayInterface {
    
    string public aggr_score;
    string public off_chain;
    
    
    function get_on_chain() public view returns (string memory) {
        return aggr_score;
    }
    
    function get_off_chain() public view returns (string memory) {
        return off_chain;
    }
    
    function callback(string memory _aggr_score, string memory _off_chain) public {
        aggr_score = _aggr_score;
        off_chain = _off_chain;
    }
    
}