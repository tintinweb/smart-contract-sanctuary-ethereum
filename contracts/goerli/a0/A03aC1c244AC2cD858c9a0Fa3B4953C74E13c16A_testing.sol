/**
 *Submitted for verification at Etherscan.io on 2023-02-23
*/

/**
 *Submitted for verification at Etherscan.io on 2022-03-21
*/

pragma solidity ^0.8.0;

contract testing {
    uint256 startDate = 0;
    mapping(uint256 => bool) blockMinted;    

    function mint() public {
       require(startDate < block.timestamp, "Transaction before start date");
       require(!blockMinted[block.number]);
       blockMinted[block.number] = true;
    }

    function setStart(uint256 _startDate) public {
	    startDate = _startDate;
	}
}