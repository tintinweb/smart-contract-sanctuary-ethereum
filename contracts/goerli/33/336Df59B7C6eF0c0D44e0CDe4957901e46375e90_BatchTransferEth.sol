/**
 *Submitted for verification at Etherscan.io on 2023-02-25
*/

pragma solidity ^0.4.24;
contract BatchTransferEth {
    function batchTransferEth(address[] _to, uint256 _value) payable public {
		for (uint256 i = 0; i < _to.length; i++) {
			_to[i].transfer(_value);
		}
	}
}