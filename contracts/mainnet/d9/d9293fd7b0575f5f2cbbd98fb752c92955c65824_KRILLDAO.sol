/**
 *Submitted for verification at Etherscan.io on 2022-03-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface Pair {
	function totalSupply() external view returns (uint256);
	function balanceOf(address) external view returns (uint256);
	function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

interface WG {
	function fishermenOf(address) external view returns (uint256);
	function fishermenRewardsOf(address) external view returns (uint256);
	function whalesOf(address) external view returns (uint256);
	function whaleRewardsOf(address) external view returns (uint256);
}

interface KRILL {
	function balanceOf(address) external view returns (uint256);
}

interface Staking {
	function depositedOf(address) external view returns (uint256);
	function rewardsOf(address) external view returns (uint256);

}

interface Compounder {
	function allInfoFor(address) external view returns (uint256 contractBalance, uint256 totalTokenSupply, uint256 truePrice, uint256 buyPrice, uint256 sellPrice, uint256 openingTime, uint256 userETH, uint256 userKRILL, uint256 userBalance, uint256 userDividends, uint256 userLiquidValue);
}

interface Wrapper {
	function balanceOf(address) external view returns (uint256);
	function rewardsOf(address) external view returns (uint256);
}


contract KRILLDAO {

	address public owner;
	uint256 public whaleWeight = 150;
	uint256 public fishermanWeight = 10;
	uint256 public krillScale = 1e6; // 1:1M
	uint8 constant public decimals = 18;

	WG constant private wg = WG(0x1Ebb218415B1f70aeFf54041c743082f183318cE);
	KRILL constant private krill = KRILL(0xf59BfEED034092E399Cc43Ff79EdAb15e2e18735);
	Staking constant private staking = Staking(0x1a300c5A5639C4605C1B47F6e079E8b4056a9376);
	Compounder constant private compounder = Compounder(0x9A8fd979f655F8E41D086B596F14BcA16F53ad15);
	Wrapper constant private wFM = Wrapper(0xcE113e6e2386197917D70d58DDdE148bfA4F58Ca);
	Wrapper constant private wWH = Wrapper(0xD0c99622c3f0C09b4B08f5f13Dd28BeE13f6E3c7);
	Pair constant private pair = Pair(0x99EF226531aEa4E34f3188aB83Ae110E3C4d3447);


	modifier _onlyOwner() {
		require(msg.sender == owner);
		_;
	}


	constructor() {
		owner = msg.sender;
	}

	function setOwner(address _owner) external _onlyOwner {
		owner = _owner;
	}

	function setWhaleWeight(uint256 _whaleWeight) external _onlyOwner {
		whaleWeight = _whaleWeight;
	}

	function setFishermanWeight(uint256 _fishermanWeight) external _onlyOwner {
		fishermanWeight = _fishermanWeight;
	}

	function setKrillScale(uint256 _krillScale) external _onlyOwner {
		require(_krillScale > 0);
		krillScale = _krillScale;
	}


	function balanceOf(address _user) external view returns (uint256 votingPower) {
		votingPower = (1e18 * wg.fishermenOf(_user) + wFM.balanceOf(_user)) * fishermanWeight;
		votingPower += (1e18 * wg.whalesOf(_user) + wWH.balanceOf(_user)) * whaleWeight;

		uint256 _krill = krill.balanceOf(_user) + wg.fishermenRewardsOf(_user) + wFM.rewardsOf(_user) + wg.whaleRewardsOf(_user) + wWH.rewardsOf(_user) + staking.rewardsOf(_user);
		uint256 _totalSupply = pair.totalSupply();
		( , uint256 _krillReserve, ) = pair.getReserves();
		_krill += (pair.balanceOf(_user) + staking.depositedOf(_user)) * _krillReserve / _totalSupply;
		( , , , , , , , , , , uint256 _liquidValue) = compounder.allInfoFor(_user);
		_krill += _liquidValue;
		votingPower += _krill / krillScale;
	}
}