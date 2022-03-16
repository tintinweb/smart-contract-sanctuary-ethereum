/**
 *Submitted for verification at Etherscan.io on 2022-03-16
*/

pragma solidity ^0.5.0;

contract ERC20 {
  function transferFrom( address from, address to, uint value)public returns (bool ok);
}


contract Multiplexer {

	function sendToken(address _tokenAddress, address[] memory _to, uint256 _value) public returns (bool) {
        
		ERC20 token = ERC20(_tokenAddress);
		for (uint256 i = 0; i < _to.length; i++) {
			assert(token.transferFrom(msg.sender, _to[i], _value) == true);
		}
		return true;
	}
}