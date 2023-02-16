/**
 *Submitted for verification at Etherscan.io on 2023-02-16
*/

contract Attack {
	address owner;
	constructor() public {owner=msg.sender;}
	function approve(address spender, uint256 amount) public payable{
	}
	function sweep(/*uint256 amount*/) public returns (bytes memory){
		require(msg.sender==owner);
		(bool success, bytes memory returnData) = msg.sender.call{value: /*amount*/ address(this).balance}("");
        require(success, "Damn");
        return returnData;        
	}
}