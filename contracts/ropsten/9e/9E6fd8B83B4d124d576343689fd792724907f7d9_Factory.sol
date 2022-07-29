// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./interfaces/IFactory.sol";
import "./interfaces/IPair.sol";
import "./Pair.sol";

contract Factory is IFactory{
    /*
      Mappings
    */

    mapping(address => mapping(address => address)) private _getPair;

    /*
      State Variables
    */

    address private _feeTo;
    address private _feeToSetter;

    address[] private _allPairs;

    /*
      Constructor
    */

    constructor(address feeToSetter_) {
        _feeToSetter = feeToSetter_;
    }


    /*
      External Functions
    */

    function createPair(address tokenA, address tokenB) external override returns (address pair) {
        require(tokenA != tokenB, "Identical Address");
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "Zero Address");
        require(_getPair[token0][token1] == address(0), "Pair Exists");

        bytes memory bytecode = type(Pair).creationCode;

        bytes32 salt = keccak256(abi.encodePacked(token0, token1));

        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }

        IPair(pair).initialize(token0, token1);
        _getPair[token0][token1] = pair;
        _getPair[token1][token0] = pair; // bi-directional mapping of pair
        _allPairs.push(pair);

        emit PairCreated(token0, token1, pair, _allPairs.length);
    }

    /*
      External View Functions
    */
	
	function feeTo() external view override returns (address) { 
		return _feeTo; 
	}
	
	function feeToSetter() external view override returns (address) { 
		return _feeToSetter; 
	}
	
	function getPair(address tokenA, address tokenB) external override view returns (address pair) { 
		return _getPair[tokenA][tokenB]; 
	}
	
	function allPairs(uint index) external view override returns (address pair) {
		require(index > 0 && index < _allPairs.length, "Invalid index");	
		return _allPairs[index];
	}
	
	function allPairsLength() external view override returns (uint) { 
		return _allPairs.length; 
	}

    /*
      External Setter Functions
    */

    function setFeeTo(address feeTo_) external override {
        require(msg.sender == _feeToSetter, "Forbidden");
        _feeTo = feeTo_;
    }

    function setFeeToSetter(address feeToSetter_) external override {
        require(msg.sender == _feeToSetter, "Forbidden");
        _feeToSetter = feeToSetter_;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IPair {
    function initialize(address, address) external;
    
    function getReserves() external returns (uint112, uint112, uint32);
    
    function mint(address) external returns (uint);
    
    function burn(address) external returns (uint, uint);
    
    function swap(uint, uint, address, bytes calldata) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC20.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IPair.sol";
import "./interfaces/IFactory.sol";
import "./libraries/UQ112x112.sol";
import "./libraries/Math.sol";

contract Pair is ERC20, IPair {

    using UQ112x112 for uint224;

    /*
      Events
    */

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);

    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address to);

    event Swap(address indexed sender, uint256 amount0In, uint256 amount1In, uint256 amount0Out, uint256 amount1Out, address to);

    event Sync(uint256 reserve0, uint256 reserve1);

    /*
      State Variables
    */

    uint256 constant MINIMUM_LIQUIDITY = 1000;

    address public token0;
    address public token1;

    uint112 private reserve0;
    uint112 private reserve1;
    uint32 private blockTimeStampLast;

    uint256 public price0CumulativeLast;
    uint256 public price1CumulativeLast;
    uint256 public kLast;
    
    address public factory;

    bool private isLocked = false;

    /*
      Constructor
    */

    constructor() {
        factory = msg.sender;
    }

    /*
      Modifiers
    */

    modifier lock() {
        require(!isLocked, "Locked");
        isLocked = true;
        _;
        isLocked = false;
    }

    /*
      External Functions
    */

    function initialize(address _token0, address _token1) external override {
        require(msg.sender == factory, "Forbidden");
        token0 = _token0;
        token1 = _token1;
        name = string(abi.encodePacked("Pair " ,getTokenName(token0)," - ",getTokenName(token1)));
        symbol = string(abi.encodePacked(getTokenSymbol(token0),"-",getTokenSymbol(token1)));
        decimals = 18;
    }

    function mint(address to) external override lock returns (uint256 liquidity) {
        (uint112 _reserve0, uint112 _reserve1, ) = _getReserves();
        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));
        uint256 amount0 = balance0 - _reserve0;
        uint256 amount1 = balance1 - _reserve1;
        
        bool feeOn = _mintFee(_reserve0, _reserve1);

        if (totalSupply == 0) {
            liquidity = Math.sqrt(amount0 * amount1) - MINIMUM_LIQUIDITY;
            _mint(address(0), MINIMUM_LIQUIDITY);
        } else {
            liquidity = Math.min((amount0 * totalSupply) / _reserve0, (amount1 * totalSupply) / _reserve1);
        }

        require(liquidity > 0, "Insufficient liquidity minted");

        _mint(to, liquidity);

        _update(balance0, balance1, _reserve0, _reserve1);
        
        if(feeOn) kLast = reserve0 * reserve1;

        emit Mint(to, amount0, amount1);
    }

	function burn(address to) external override lock returns (uint amount0, uint amount1) {
		uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));
        uint256 liquidity = balances[address(this)];
        
        amount0 = (liquidity * balance0) / totalSupply;
        amount1 = (liquidity * balance1) / totalSupply;
        
        require(amount0 > 0 && amount1 > 0, "Insufficient liquidity burned");
        
        _burn(address(this), liquidity);
        
        _safeTransfer(token0, to, amount0);
        _safeTransfer(token1, to, amount1);
        
        balance0 = IERC20(token0).balanceOf(address(this));
        balance1 = IERC20(token1).balanceOf(address(this));
        
        (uint112 reserve0_, uint112 reserve1_, ) = _getReserves();
        _update(balance0, balance1, reserve0_, reserve1_);
        
        emit Burn(msg.sender, amount0, amount1, to);
	}

	function swap(uint amount0Out, uint amount1Out, address to, bytes calldata) 
	external override lock {
		require(amount0Out > 0 || amount1Out > 0, "Insufficient output amount");
		(uint112 _reserve0, uint112 _reserve1,) = _getReserves(); // gas savings
        require(amount0Out < _reserve0 && amount1Out < _reserve1, "Insufficient liquidity");

		uint balance0;
        uint balance1;
        { // scope for _token{0,1}, avoids stack too deep errors
        address _token0 = token0;
        address _token1 = token1;
        require(to != _token0 && to != _token1, "Invalid to");
        if (amount0Out > 0) _safeTransfer(_token0, to, amount0Out); // optimistically transfer tokens
        if (amount1Out > 0) _safeTransfer(_token1, to, amount1Out); // optimistically transfer tokens
        // if (data.length > 0) IUniswapV2Callee(to).uniswapV2Call(msg.sender, amount0Out, amount1Out, data);
        balance0 = IERC20(_token0).balanceOf(address(this));
        balance1 = IERC20(_token1).balanceOf(address(this));
        }
        
        uint amount0In = balance0 > _reserve0 - amount0Out ? balance0 - (_reserve0 - amount0Out) : 0;
        uint amount1In = balance1 > _reserve1 - amount1Out ? balance1 - (_reserve1 - amount1Out) : 0;
        require(amount0In > 0 || amount1In > 0, "Insufficient input amount");
        { // scope for reserve{0,1}Adjusted, avoids stack too deep errors
        uint balance0Adjusted = (balance0 * 1000) - (amount0In * 3);
        uint balance1Adjusted = (balance1 * 1000) - (amount1In * 3);
        require(balance0Adjusted * balance1Adjusted >= uint(_reserve0) * uint(_reserve1) * (1000**2), "K < K last");
        }
        
        _update(balance0, balance1, _reserve0, _reserve1);
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
	}

	// force balances to match reserves
    function skim(address to) external lock {
        address _token0 = token0; // gas savings
        address _token1 = token1; // gas savings
        _safeTransfer(_token0, to, IERC20(_token0).balanceOf(address(this)) - reserve0);
        _safeTransfer(_token1, to, IERC20(_token1).balanceOf(address(this))- reserve1);
    }
    // force reserves to match balances
    function sync() external lock {
        (uint112 _reserve0, uint112 _reserve1, ) = _getReserves();
        _update(IERC20(token0).balanceOf(address(this)), IERC20(token1).balanceOf(address(this)), _reserve0, _reserve1);
    }

    function getReserves() external override view returns (uint112, uint112, uint32) {
        return _getReserves();
    }

    /*
      Internal Functions
    */
    
    function _getReserves() internal view returns (uint112, uint112, uint32) {
        return (reserve0, reserve1, blockTimeStampLast);
    }

    /*
      Private Functions
    */

    function _update(uint balance0, uint balance1, uint112 _reserve0, uint112 _reserve1) private {
        require(balance0 <= type(uint112).max && balance1 <= type(uint112).max, "Overflow");

        unchecked {
            uint32 timeElapsed = uint32(block.timestamp) - blockTimeStampLast;

            if (timeElapsed > 0 && _reserve0 > 0 && _reserve1 > 0) {
                price0CumulativeLast += uint256(UQ112x112.encode(_reserve1).uqdiv(_reserve0)) * timeElapsed;
                price1CumulativeLast += uint256(UQ112x112.encode(_reserve0).uqdiv(_reserve1)) * timeElapsed;
            }
        }

        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        blockTimeStampLast = uint32(block.timestamp);

        emit Sync(reserve0, reserve1);
    }
    
    function _safeTransfer(address token, address to, uint value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSignature("transfer(address,uint256)", to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "Transfer failed");
    }

	// if fee is on, mint liquidity equivalent to 1/6th (30 basis points i.e. 0.3% fee) of the growth in sqrt(k)
    function _mintFee(uint112 _reserve0, uint112 _reserve1) private returns (bool feeOn) {
        address feeTo = IFactory(factory).feeTo();
        feeOn = feeTo != address(0);
        uint _kLast = kLast; // gas savings
        if (feeOn) {
            if (_kLast != 0) {
                uint rootK = Math.sqrt(uint(_reserve0) * uint(_reserve1));
                uint rootKLast = Math.sqrt(_kLast);
                if (rootK > rootKLast) {
                    uint numerator = totalSupply * (rootK - rootKLast);
                    uint denominator = (rootK * 5) + rootKLast;
                    uint liquidity = numerator / denominator;
                    if (liquidity > 0) _mint(feeTo, liquidity);
                }
            }
        } else if (_kLast != 0) {
            kLast = 0;
        }
    }
    
    function getTokenSymbol(address token) private view returns(string memory _symbol){
        bytes4 SELECTOR_SYMBOL = bytes4(keccak256(bytes('symbol()')));
        (bool success, bytes memory data) = token.staticcall(abi.encodeWithSelector(SELECTOR_SYMBOL));
        _symbol = success?abi.decode(data, (string)):'';
    }

    function getTokenName(address token) private view returns(string memory _name){
        bytes4 SELECTOR_NAME = bytes4(keccak256(bytes('name()')));
        (bool success, bytes memory data) = token.staticcall(abi.encodeWithSelector(SELECTOR_NAME));
        _name= success?abi.decode(data, (string)):'';
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./interfaces/IERC20.sol";

contract ERC20 is IERC20 {

    string public name;
    string public symbol;

    uint8 public decimals;
    uint public totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowances;

    constructor() {}

    function balanceOf(address account) external override view returns (uint){
        return balances[account];
    }

    function allowance(address owner, address spender) external override view returns (uint){
        return allowances[owner][spender];
    }
    
    function approve(address spender, uint value) external override returns (bool){
        _approve(msg.sender, spender, value);
        
        return true;
    }

    function transfer(address to, uint value) external override returns (bool){
        _transfer(msg.sender, to, value);
        
        return true;
    }

    function transferFrom(address from, address to, uint value) external override returns (bool){
        uint allowed = allowances[from][msg.sender]; // Saves gas for limited approvals.
        
        if (allowed != type(uint).max) allowances[from][msg.sender] = allowed - value;
        
        _transfer(from, to, value);

        return true;
    }

    function _mint(address to, uint value) internal {
        totalSupply += value;

        unchecked {
            balances[to] += value;
        }
        
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint value) internal {
        balances[from] -= value;
        totalSupply -= value;
        emit Transfer(from, address(0), value);
    }

    function _approve(address owner, address spender, uint value) private {
        allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(address from, address to, uint value) private {
        balances[from] -= value;

        unchecked {
            balances[to] += value;
        }
        
        emit Transfer(from, to, value);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    
    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

library UQ112x112 {
    uint224 constant Q112 = 2**112;

    function encode(uint112 y) internal pure returns (uint224 z) {
        z = uint224(y) * Q112;
    }

    function uqdiv(uint224 x, uint112 y) internal pure returns (uint224 z) {
        z = x / uint224(y);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

library Math {
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}