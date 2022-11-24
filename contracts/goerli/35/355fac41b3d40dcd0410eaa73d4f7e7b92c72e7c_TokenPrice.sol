/**
 *Submitted for verification at Etherscan.io on 2022-11-24
*/

pragma solidity 0.8.13;

interface IUniswapV2Router02 {
    function WETH() external pure returns (address);    

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);
}

contract TokenPrice {
	IUniswapV2Router02 public router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
	address public weth = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6;
	
	function getTokenPrices(address[] memory _tokens, uint256[] memory _amounts) public view returns (uint256[] memory) {
		uint256[] memory prices = new uint256[](_tokens.length);
		if(router.WETH() != weth) {
			address[] memory path = new address[](3);
			path[1] = router.WETH();
			path[2] = weth;
			for(uint256 i = 0; i < _tokens.length; i++) {
				path[0] = _tokens[i];
				prices[i] = router.getAmountsOut(_amounts[i], path)[2];
			}	
		} else {
			address[] memory path = new address[](2);
			path[1] = router.WETH();		
			for(uint256 i = 0; i < _tokens.length; i++) {
				path[0] = _tokens[i];
				prices[i] = router.getAmountsOut(_amounts[i], path)[1];
			}	
		}
        return prices;
    }
}