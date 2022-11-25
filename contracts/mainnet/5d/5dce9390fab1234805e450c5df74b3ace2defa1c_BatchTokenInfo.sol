/**
 *Submitted for verification at Etherscan.io on 2022-11-25
*/

pragma solidity 0.8.13;

interface IERC20 {
    function totalSupply() external view returns (uint256);
	
    function balanceOf(address account) external view returns (uint256);	
}

interface IERC20Detailed is IERC20 {
	function decimals() external view returns (uint8);
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
	
    function allPairs(uint) external view returns (address pair);
	
    function allPairsLength() external view returns (uint);
}

interface IUniswapV2Router02 {
    function WETH() external pure returns (address);
	
	function factory() external pure returns (address);

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);
}

interface IUniswapV2Pair {
    function token0() external view returns (address);
    
	function token1() external view returns (address);    
}

contract BatchTokenInfo {
	IUniswapV2Router02 private router;
	address private weth;
	address private usdt;
	address[] private _burns;
	
	constructor(address _router, address _weth, address _usdt) {
		router = IUniswapV2Router02(_router);
		weth = _weth;
		usdt = _usdt;
		_burns.push(0xdEAD000000000000000042069420694206942069);
		_burns.push(0x000000000000000000000000000000000000dEaD);
		_burns.push(0x0000000000000000000000000000000000000000);
    }
	
	function getTokenPricesInToken(address[] memory _tokens, uint256[] memory _amounts, address _out) public view returns (uint256[] memory) {
		require(_tokens.length == _amounts.length, "Token and amount count doesn't match");
		uint256[] memory prices = new uint256[](_tokens.length);
		if(router.WETH() != _out) {
			address[] memory path = new address[](3);
			path[1] = router.WETH();
			path[2] = _out;
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
	
	function getTokenPricesInEth(address[] memory _tokens, uint256[] memory _amounts) public view returns (uint256[] memory) {
		return getTokenPricesInToken(_tokens, _amounts, weth);
    }
	
	function getTokenPricesInUsdt(address[] memory _tokens, uint256[] memory _amounts) public view returns (uint256[] memory) {
		return getTokenPricesInToken(_tokens, _amounts, usdt);
    }
	
	function getTokenDecimals(address[] memory _tokens) public view returns (uint8[] memory) {
		uint8[] memory decimals = new uint8[](_tokens.length);
		for(uint256 i = 0; i < _tokens.length; i++) {
			decimals[i] = IERC20Detailed(_tokens[i]).decimals();
		}
		return decimals;
    }
	
	function getTokenSuppliesIncludesDecimal(address[] memory _tokens) public view returns (uint256[] memory) {
		uint256[] memory supplies = new uint256[](_tokens.length);
		for(uint256 i = 0; i < _tokens.length; i++) {
			supplies[i] = IERC20(_tokens[i]).totalSupply();
		}
		return supplies;
    }
	
	function getTokensBurnedIncludesDecimal(address[] memory _tokens) public view returns (uint256[] memory) {
		uint256[] memory burned = new uint256[](_tokens.length);
		for(uint256 i = 0; i < _tokens.length; i++) {
			uint256 burn = 0;
			for(uint256 j = 0; j < _burns.length; j++) {
				burn += IERC20(_tokens[i]).balanceOf(_burns[j]);
			}
			burned[i] = burn;
		}
		return burned;
    }
	
	function getTokensBurnedIncludesDecimal(address[] memory _tokens, address[][] memory _burnaddresses) public view returns (uint256[] memory) {
		require(_tokens.length == _burnaddresses.length, "Token and burn address count doesn't match");
		uint256[] memory burned = new uint256[](_tokens.length);
		for(uint256 i = 0; i < _tokens.length; i++) {
			uint256 burn = 0;
			for(uint256 j = 0; j < _burnaddresses[i].length; j++) {
				burn += IERC20(_tokens[i]).balanceOf(_burnaddresses[i][j]);
			}
			burned[i] = burn;
		}
		return burned;
    }
	
	function _calculateTokenMCInEth(address _token, address[] memory _burnaddresses) private view returns (uint256) {
		uint256 price = 0;
		IERC20Detailed erc20 = IERC20Detailed(_token);
		uint256 amount = 10 ** erc20.decimals();
		if(router.WETH() != weth) {				
			address[] memory path = new address[](3);
			path[0] = _token;
			path[1] = router.WETH();
			path[2] = weth;
			price = router.getAmountsOut(amount, path)[2];
		} else {
			address[] memory path = new address[](2);
			path[0] = _token;
			path[1] = router.WETH();		
			price = router.getAmountsOut(amount, path)[1];	
		}
		if(_burnaddresses.length > 0) {
			uint256 burn = 0;
			for(uint256 i = 0; i < _burnaddresses.length; i++) {
				burn += erc20.balanceOf(_burnaddresses[i]);
			}
			return (price * (erc20.totalSupply() - burn)) / amount;
		}
		return (price * erc20.totalSupply()) / amount;
	}
	
	function getTokenDilutedMarketCapsInEth(address[] memory _tokens) public view returns (uint256[] memory) {
		uint256[] memory marketcaps = new uint256[](_tokens.length);
		address[] memory _burnaddresses = new address[](0);
		for(uint256 i = 0; i < _tokens.length; i++) {
			marketcaps[i] = _calculateTokenMCInEth(_tokens[i], _burnaddresses);
		}
		return marketcaps;
    }
	
	function getTokenCirculatingMarketCapsInEth(address[] memory _tokens) public view returns (uint256[] memory) {
		uint256[] memory marketcaps = new uint256[](_tokens.length);
		for(uint256 i = 0; i < _tokens.length; i++) {
			marketcaps[i] = _calculateTokenMCInEth(_tokens[i], _burns);
		}
		return marketcaps;
    }
	
	function getTokenCirculatingMarketCapsInEth(address[] memory _tokens, address[][] memory _burnaddresses) public view returns (uint256[] memory) {
		require(_tokens.length == _burnaddresses.length, "Token and burn address count doesn't match");
		uint256[] memory marketcaps = new uint256[](_tokens.length);
		for(uint256 i = 0; i < _tokens.length; i++) {
			marketcaps[i] = _calculateTokenMCInEth(_tokens[i], _burnaddresses[i]);
		}
		return marketcaps;
    }
	
	function getAllPairsLength() external view returns (uint) {
		return IUniswapV2Factory(router.factory()).allPairsLength();
	}
	
	function getAllPairs(uint _startIndex, uint _endIndex) external view returns (address[] memory) {
		require(_endIndex >= _startIndex, "_startIndex greater than _endIndex");
		IUniswapV2Factory factory = IUniswapV2Factory(router.factory());
		require(factory.allPairsLength() >= _endIndex, "_endIndex greater than total pair count");
		address[] memory pairs = new address[](_endIndex - _startIndex);
		uint256 index = 0;
		for(uint256 i = _startIndex; i < _endIndex; i++) {
			pairs[index++] = factory.allPairs(i);
		}
		return pairs;
	}
	
	function getAllPairsToken0(uint _startIndex, uint _endIndex) external view returns (address[] memory) {
		require(_endIndex >= _startIndex, "_startIndex greater than _endIndex");
		IUniswapV2Factory factory = IUniswapV2Factory(router.factory());
		require(factory.allPairsLength() >= _endIndex, "_endIndex greater than total pair count");
		address[] memory token0s = new address[](_endIndex - _startIndex);
		uint256 index = 0;
		for(uint256 i = _startIndex; i < _endIndex; i++) {
			token0s[index++] = IUniswapV2Pair(factory.allPairs(i)).token0();
		}
		return token0s;
	}
	
	function getAllPairsToken1(uint _startIndex, uint _endIndex) external view returns (address[] memory) {
		require(_endIndex >= _startIndex, "_startIndex greater than _endIndex");
		IUniswapV2Factory factory = IUniswapV2Factory(router.factory());
		require(factory.allPairsLength() >= _endIndex, "_endIndex greater than total pair count");
		address[] memory token1s = new address[](_endIndex - _startIndex);
		uint256 index = 0;
		for(uint256 i = _startIndex; i < _endIndex; i++) {
			token1s[index++] = IUniswapV2Pair(factory.allPairs(i)).token1();
		}
		return token1s;
	}
}