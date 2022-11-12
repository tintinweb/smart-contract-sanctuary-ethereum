// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract Whitelist {
    
    uint256 private counter;
    mapping(address => bool) private whitelisted;

    function whitelist() public {
        counter++;
        require(counter <= 10, "Whitelisting Ended");
        whitelisted[msg.sender] = true;
    }

    function getWhitelister(address _whitelister) public view returns(bool) {
        return whitelisted[_whitelister];
    }

}