/*
	@Onda.fi
	@verison v1.0 
	@notice DAI/USDT Pool 
	@network ROPSTEN
*/
pragma solidity >=0.8.0;

import "./interface/IERC20.sol";
import "./interface/TransferHelper.sol";
import "./interface/Math.sol";
contract SwapPool {

	address private owner;

	address public token0;
	address public token1;
	address public lp;

	uint public k;
	uint private key = 0;
	uint public reserve0;
	uint public reserve1;
	uint public price0;
	uint public price1;
	uint public totalSupply;
	uint private fee;
	uint public constant min_liq = 10**2;

	bytes4 private constant TRANSFER_ACTION = bytes4(keccak256(bytes('_transfer(address,uint256)')));
	bytes4 private constant TRANSFERFROM_ACTION = bytes4(keccak256(bytes('_transferFrom(address,address,uint256)')));
	bytes4 private constant MINT_ACTION = bytes4(keccak256(bytes('mint(address,uint256)')));
	bytes4 private constant BURN_ACTION = bytes4(keccak256(bytes('burn(address,uint256)')));

	event AddLiquidity(address token0, address token1, uint amount0, uint amount1);
	event DeleteLiquidity(address token0, address token1, uint amount0, uint amount1, uint liquidity);
	event SwapToken(address token0, address token1, address _to, uint amount0, uint amount1);
	event SyncStorage(address token0, address token1, uint newBalance0, uint newBalance1);

	constructor(address _token0, address _token1, address _lp, uint _fee) {
		owner = msg.sender;
		token0 = _token0;
		token1 = _token1;
		lp = _lp;
		fee = _fee;
	}

	function getBalancePair() private returns (uint balance0, uint balance1) {
		balance0 = reserve0;
		balance1 = reserve1;
	}

	function transfer(address to, address token, uint amount) private {
		(bool status, bytes memory data) = token.call(abi.encodeWithSelector(TRANSFER_ACTION, to, amount));
        require(status && (data.length == 0 || abi.decode(data, (bool))), 'FAILED Transfer');
	}

	function transferFrom(address to, address token, uint amount) private {
		(bool status, bytes memory data) = token.call(abi.encodeWithSelector(TRANSFERFROM_ACTION, to, amount));
        require(status && (data.length == 0 || abi.decode(data, (bool))), 'FAILED Transfer');
	}

    function mint(address lp, address to, uint amount) private {
		(bool status, bytes memory data) = lp.call(abi.encodeWithSelector(MINT_ACTION, to, amount));
        require(status && (data.length == 0 || abi.decode(data, (bool))), 'FAILED Mint');
	}

	function burn(address lp, address to, uint amount) private {
		(bool status, bytes memory data) = lp.call(abi.encodeWithSelector(BURN_ACTION, to, amount));
        require(status && (data.length == 0 || abi.decode(data, (bool))), 'FAILED Burn');
	}

	function _updateStorage(address _token0, address _token1, uint256 balanceContract0, uint256 balanceContract1) private {
		require((balanceContract0 >= 0) && (balanceContract1 >= 0), '0 number');
		if(balanceContract0 != 0 && balanceContract1 != 0) {
			price0 = (balanceContract1 * 1000000) / (balanceContract0);
			price1 = (balanceContract0 * 1000000) / (balanceContract1);
        } else if((balanceContract0 == 0) && (balanceContract1 == 0)) {
        	price0 = 0;
        	price1 = 0;
        }

        reserve0 = balanceContract0;
        reserve1 = balanceContract1;
        emit SyncStorage(_token0, _token1, reserve0, reserve1);
	}

	function updateK(address _token0, address _token1) private returns (uint) {
		uint balance0 = IERC20(_token0).balanceOf(address(this));
        uint balance1 = IERC20(_token1).balanceOf(address(this));
		if(key == 0) {
			k = balance0 * balance1;
			key = 1;
		}
		return k;
	}

	function _addLiquidity(address _token0, address _token1, uint amount0, uint amount1) public returns (bool) {
		(uint balanceContract0, uint balanceContract1) = getBalancePair();
		require(_token0 == token0 && _token1 == token1, 'Not used address');
		require(amount0 == amount1, 'Not equal');
		TransferHelper.safeTransferFrom(_token0, msg.sender, address(this), amount0);
        TransferHelper.safeTransferFrom(_token1, msg.sender, address(this), amount1);

        uint _balance0 = IERC20(_token0).balanceOf(address(this));
	    uint _balance1 = IERC20(_token1).balanceOf(address(this));

        uint liquidity;
        if (totalSupply == 0) {
	        liquidity = Math.sqrt(((_balance0 - balanceContract0) * (_balance1 - balanceContract1)) - min_liq);
	        require(liquidity > 0, 'Minus liquidity');
	        mint(lp, msg.sender, liquidity);
	        updateK(_token0, _token1);
	    } else {
	        liquidity = Math.min(((_balance0 - balanceContract0) * totalSupply) / balanceContract0, ((_balance1 - balanceContract1) * totalSupply) / balanceContract1);
	        require(liquidity > 0, 'Minus liquidity');
	        mint(lp, msg.sender, liquidity);
	    }
	    totalSupply+=liquidity;
        uint256 balance0 = IERC20(_token0).balanceOf(address(this));
        uint256 balance1 = IERC20(_token1).balanceOf(address(this));
        _updateStorage(_token0, _token1, balance0, balance1);
        emit AddLiquidity(_token0, _token1, amount0, amount1);
        return true;
	}

	function _deleteLiquidity(address _token0, address _token1, address _to, uint liquidity, uint amount0, uint amount1) public returns (bool) {
		(uint balanceContract0, uint balanceContract1) = getBalancePair();
		require(_token0 == token0 && _token1 == token1, 'Not used address');
		require(amount0 == amount1, 'Not equal');

	    uint amountDelLiq0 = (liquidity * balanceContract0) / totalSupply;
	    uint amountDelLiq1 = (liquidity * balanceContract1) / totalSupply;

	    require(amountDelLiq0 > 0 && amountDelLiq1 > 0, 'Minus amount');
	    burn(lp, _to, liquidity);
	   	TransferHelper.safeTransferFrom(_token0, address(this), _to, amountDelLiq0);
	   	TransferHelper.safeTransferFrom(_token1, address(this), _to, amountDelLiq1);

	    totalSupply -= liquidity;
	    uint newBalance0 = IERC20(_token0).balanceOf(address(this));
		uint newBalance1 = IERC20(_token1).balanceOf(address(this));
	    _updateStorage(_token0, _token1, newBalance0, newBalance1);
	    emit DeleteLiquidity(_token0, _token1, balanceContract0, balanceContract1, liquidity);
	    return true;
	}

	function _swap(address _token0, address _token1, address _to, uint amount0, uint amount1) public returns (bool) {
		(uint balanceContract0, uint balanceContract1) = getBalancePair();
		require(_token0 == token0 && _token1 == token1, 'Not used address');
		require(amount0 > 0 || amount1 > 0, 'Zero amount');
		require(amount0 == 0 || amount1 == 0, 'Zero amount');
		require(_to != _token0 && _to != _token1, 'Not used address');
		uint fee_token0 = (amount0 * fee) / 1000;
		uint fee_token1 = (amount1 * fee) / 1000;
		if (amount0 > 0 && amount1 == 0) {
			TransferHelper.safeTransferFrom(_token1, msg.sender, address(this), ((amount0 + fee_token0)*price0) / 1000000);
			TransferHelper.safeTransfer(_token0, _to, amount0);
		}
        if (amount1 > 0 && amount0 == 0) {
        	TransferHelper.safeTransferFrom(_token0, msg.sender, address(this), ((amount1 + fee_token1)*price1) / 1000000);
        	TransferHelper.safeTransfer(_token1, _to, amount1);
        }
        uint newBalance0 = IERC20(_token0).balanceOf(address(this));
		uint newBalance1 = IERC20(_token1).balanceOf(address(this));
	    _updateStorage(_token0, _token1, newBalance0, newBalance1);
        emit SwapToken(_token0, _token1, _to, amount0, amount1);
        return true;
	}

}

pragma solidity ^0.8.0;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function balanceOf(address account) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        bytes4 TRANSFER_from_ACTION = bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(TRANSFER_from_ACTION, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}

pragma solidity >=0.8.0;

// a library for performing various math operations

library Math {
    function min(uint x, uint y) internal pure returns (uint z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}