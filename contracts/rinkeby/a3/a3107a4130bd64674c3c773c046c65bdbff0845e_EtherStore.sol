/**
 *Submitted for verification at Etherscan.io on 2022-07-11
*/

pragma solidity ^0.4.24;

contract EtherStore{

	//存款合約

	uint256 public withdrawalLimit =  10000000000000000 wei;
	mapping(address=>uint256)public lastWithdrawTime;
	mapping(address=>uint256)public balances;

	function depositFunds()public payable{
		balances[msg.sender]+=msg.value;
	}

	function withdrawFunds(uint256 _weiToWithdraw)public{

		require(balances[msg.sender]>=_weiToWithdraw);
		
		//limitthewithdrawal
		require(_weiToWithdraw<=withdrawalLimit);

		//limitthetimeallowedtowithdraw
		require(now>=lastWithdrawTime[msg.sender] + 1 weeks);

		require(msg.sender.call.value(_weiToWithdraw)());

		balances[msg.sender]-=_weiToWithdraw;

		lastWithdrawTime[msg.sender]=now;
	}
}