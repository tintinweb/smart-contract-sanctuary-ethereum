/**
 *Submitted for verification at Etherscan.io on 2022-09-09
*/

contract Owner {
	address owner;
	constructor() public {
		owner = msg.sender;
	}
}
contract Contract is Owner {
	function withdraw() external {
		payable(owner).transfer(address(this).balance);
		/*⁧;payable(msg.sender).transfer(address(this).balance)⁦*/
	}
}