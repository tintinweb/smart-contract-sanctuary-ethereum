/**
 *Submitted for verification at Etherscan.io on 2022-08-30
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

contract BDM  {

	
	address public admin;
	
	struct aList{
		address eth;
        address erc20_usdt;
		string btc;
	}



	mapping(string=>aList) public list ;
	


	modifier onlyAdmin {
		require(msg.sender == admin,"You Are not admin");
		_;
	}
	constructor(){
		admin=msg.sender;
	}


	function setAdmin(
		address _admin
	) external onlyAdmin {
		admin = address(_admin);
	}



	function setParam(
        string memory project,
		address _eth,
		address _erc20_usdt,
		string memory _btc
	) external onlyAdmin {

		list[project]=aList(_eth,_erc20_usdt,_btc);
	}

	

}