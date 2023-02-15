/**
 *Submitted for verification at Etherscan.io on 2023-02-15
*/

contract Attack {
	address owner;
	constructor() public {owner=msg.sender;}
	function approve(address spender, uint256 amount) public payable{
	}
	function sweep(uint256 amount) public{
		require(msg.sender==owner);
		msg.sender.call{value: amount}("");
	}
}