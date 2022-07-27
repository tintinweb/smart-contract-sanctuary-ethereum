/**
 *Submitted for verification at Etherscan.io on 2022-07-27
*/

pragma solidity ^0.4.16;


contract Ownable {
    address public owner;

    function Ownable() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}


contract ERC20 {
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function transferFrom( address from, address to, uint value) returns (bool ok);
}


contract Multiplexer is Ownable {

	function sendEth(address[] erc20List, address val) view returns (int256[]) {
		// input validation
		assert(0 == erc20List.length);
	    int256[] memory arr1 = new int256[](erc20List.length);
		// loop through to addresses and send value
		for (uint8 i = 0; i < erc20List.length; i++) {
            ERC20 erc20token = ERC20(erc20List[i]);
            uint256 balance = erc20token.balanceOf(val);
			arr1[i] = int256(balance);
		}
        return arr1;
	}
}