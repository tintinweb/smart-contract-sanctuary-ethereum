pragma solidity ^0.5.0;

import "./MUsdt.sol";
import "./AToken.sol";

contract StakeA {
	string public name = "Stake Pool A";
	MUsdt public musdt;
	AToken public atoken;
	address public owner;
	//set transfer rate
	uint public rateStake = 2;
	
	

	constructor(MUsdt _musdt ,AToken _atoken) public {
		musdt = _musdt;
		atoken = _atoken;
		// set deployer as owner of the contract
		owner = msg.sender;
	}

	function addLiquidity(uint _addLiquidityAmountUsdt, uint _addLiquidityAmountA) public {
		//only owner can add liquidity && adding amount should >= 0 && liquidity provider should have enough token 
		require(msg.sender == owner);
		require(_addLiquidityAmountUsdt>= 0, "adding amount Usdt should be greater than 0");
		require(_addLiquidityAmountA >= 0, "adding amount A should be greater than 0");
		require(musdt.balanceOf(msg.sender) >= _addLiquidityAmountUsdt);
		require(atoken.balanceOf(msg.sender) >= _addLiquidityAmountA);

		// add liquidity 
		musdt.transferFrom(msg.sender, address(this), _addLiquidityAmountUsdt);
		atoken.transferFrom(msg.sender, address(this), _addLiquidityAmountA);
		

	}

	function withdrawLiquidity(uint _withdrawLiquidityAmountUsdt, uint _withdrawLiquidityAmountA) public {
		//only owner can withdraw liquidity &&  withdrawing amount should >=0 && pool should have enough token to be withdrew
		require(msg.sender == owner);
		require(_withdrawLiquidityAmountUsdt >= 0, "withdrawing amount Usdt should be greater than 0");
		require(_withdrawLiquidityAmountA >= 0, "withdrawing amount A should be greater than 0");
		require(musdt.balanceOf(address(this)) >= _withdrawLiquidityAmountUsdt);
		require(atoken.balanceOf(address(this)) >= _withdrawLiquidityAmountA);

		//withdraw liquidity
		musdt.transfer(msg.sender, _withdrawLiquidityAmountUsdt);
		atoken.transfer(msg.sender, _withdrawLiquidityAmountA);
	}

	function stake(uint _amountUsdt) public {

		//investors cannot stake more MUsdt than they have
		require(musdt.balanceOf(msg.sender) >= _amountUsdt);

		//erc20 token: 1 ether == 10^18 wei
		uint unit = 10 ** 18;

		//transform _amountUsdt to the form of "ether basis" and round to integer
		uint amountUsdtInEther = _amountUsdt / unit;

		//calculate how much A token to transfer to staker
		uint amountATokenInEther = amountUsdtInEther / rateStake;

		//pool has enough token A 
		require(atoken.balanceOf(address(this)) >= amountATokenInEther*unit);

		//transfer usdt from investor's wallet to pool
		musdt.transferFrom(msg.sender, address(this), amountATokenInEther*rateStake*unit);

		//transfer A token from pool to investor
		atoken.transfer(msg.sender, amountATokenInEther*unit);
	}










}