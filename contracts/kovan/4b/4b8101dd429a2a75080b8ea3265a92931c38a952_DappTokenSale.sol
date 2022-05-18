pragma solidity ^0.4.2;

import "./DappToken.sol";

contract DappTokenSale { 

	address admin;
	DappToken public tokenContract;
	uint256 public tokenPrice;
	uint256 public tokensSold;

	event Sell(
		address _buyer,
		uint256 _amount
	);

	//internal - can be called only from inside
	//pure - doesn't write data to the blockchain, doesn't create transaction
	//from ds-math
    function multiply(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }

	constructor(DappToken _tokenContract, uint256 _tokenPrice) public {
		admin = msg.sender;
		tokenContract = _tokenContract;
		tokenPrice = _tokenPrice;
	}

	function buyTokens(uint256 _numberOfTokens) public payable {
		require(msg.value == multiply(_numberOfTokens, tokenPrice));
		require(tokenContract.balanceOf(this) >= _numberOfTokens);
		require(tokenContract.transfer(msg.sender, _numberOfTokens)); //returns bool
		tokensSold += _numberOfTokens;

		emit Sell(msg.sender, _numberOfTokens);
	}

	function endSale() public {
		require(msg.sender == admin);

		//transfer remaining balance from this contract to admin
		require(tokenContract.transfer(admin, tokenContract.balanceOf(this))); 

		//destroy contract - it clears state variables
		selfdestruct(admin);
	}

}