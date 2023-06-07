/**
 *Submitted for verification at Etherscan.io on 2023-06-07
*/

pragma solidity >=0.4.22 <0.9.0;

contract MyContract {
    mapping (address => uint256) public tokensPurchased;
    address owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function recordPurchases(address[] memory buyers, uint256[] memory amounts) public onlyOwner {
        require(buyers.length == amounts.length, "Array lengths must match");

        for (uint i = 0; i < buyers.length; i++) {
            tokensPurchased[buyers[i]] = amounts[i];
        }
    }
}