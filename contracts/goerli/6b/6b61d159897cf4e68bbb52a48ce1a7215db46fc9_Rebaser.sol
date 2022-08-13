/**
 *Submitted for verification at Etherscan.io on 2022-08-13
*/

pragma solidity 0.5.0;

/* 

    Rebaser.sol

    
    
    Elastic Supply ERC20 Token with randomized rebasing.
    
    Forked from Ampleforth: https://github.com/ampleforth/uFragments
    
    GPL 3.0 license.
    
    RMPL.sol - Basic ERC20 Token with rebase functionality
    Rebaser.sol - Handles decentralized, autonomous, random rebasing on-chain. 
    
    Rebaser.sol will be upgraded as the project progresses. Ownership of RMPL.sol can be changed to new versions of Rebaser.sol as they are released.
    
    See github for more info and latest versions: https://github.com/rmpldefiteam
    
    Once a final version has been agreed, owner address of RMPL.sol will be locked to ensure completely decentralised operation forever.
  
    Current work in progress BEFORE deploying:
    
    - Research into different random distributions for the maximum 48hr rebase period, to average closer to 24hrs with smaller deviations.
    - Multiple methods to generate randomness, optimised for gas costs (smaller blockhash matching intervals combined with 2nd layer oracle call).
    - Oraclize US CPI inflation figure for price target.
    - Use TWAP Price from Uniswap.
    - Gas optimizations.
    - Code audit.
    
    Version: 0.8.0
    
*/

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}


library UniswapV2Library {
    using SafeMath for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
            ))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'UniswapV2Library: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

contract Initializable {

  bool private initialized;
  bool private initializing;

  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool wasInitializing = initializing;
    initializing = true;
    initialized = true;

    _;

    initializing = wasInitializing;
  }

  function isConstructor() private view returns (bool) {
    uint256 cs;
    assembly { cs := extcodesize(address) }
    return cs == 0;
  }

  uint256[50] private ______gap;
}

contract Ownable is Initializable {

  address private _owner;
  uint256 private _ownershipLocked;

  event OwnershipLocked(address lockedOwner);
  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  function initialize(address sender) internal initializer {
    _owner = sender;
	_ownershipLocked = 0;
  }

  function owner() public view returns(address) {
    return _owner;
  }

  modifier onlyOwner() {
    require(isOwner());
    _;
  }

  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  function _transferOwnership(address newOwner) internal {
    require(_ownershipLocked == 0);
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
  
  function lockOwnership() public onlyOwner {
	require(_ownershipLocked == 0);
	emit OwnershipLocked(_owner);
    _ownershipLocked = 1;
  }

  uint256[50] private ______gap;
}

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

/*
MIT License

Copyright (c) 2018 requestnetwork
Copyright (c) 2018 Fragments, Inc.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/


library SafeMathInt {

    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

    function mul(int256 a, int256 b)
        internal
        pure
        returns (int256)
    {
        int256 c = a * b;

        // Detect overflow when multiplying MIN_INT256 with -1
        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }

    function div(int256 a, int256 b)
        internal
        pure
        returns (int256)
    {
        // Prevent overflow when dividing MIN_INT256 by -1
        require(b != -1 || a != MIN_INT256);

        // Solidity already throws when dividing by 0.
        return a / b;
    }

    function sub(int256 a, int256 b)
        internal
        pure
        returns (int256)
    {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }

    function add(int256 a, int256 b)
        internal
        pure
        returns (int256)
    {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }

    function abs(int256 a)
        internal
        pure
        returns (int256)
    {
        require(a != MIN_INT256);
        return a < 0 ? -a : a;
    }
}

library UInt256Lib {

    uint256 private constant MAX_INT256 = ~(uint256(1) << 255);

    /**
     * @dev Safely converts a uint256 to an int256.
     */
    function toInt256Safe(uint256 a)
        internal
        pure
        returns (int256)
    {
        require(a <= MAX_INT256);
        return int256(a);
    }
}

interface IRMPL {

    event TransactionFailed(address indexed destination, uint index, bytes data);
    event LogRebase(uint256 indexed epoch, uint256 totalSupply);

    function rebase(int256 supplyDelta) external returns (uint256);
    function totalSupply() external returns (uint256);
    function balanceOf(address who) external returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);
    function allowance(address owner_, address spender) external returns (uint256);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);
    function addTransaction(address destination, bytes calldata data) external;
    function removeTransaction(uint index) external;
    function setTransactionEnabled(uint index, bool enabled) external;
    function transactionsSize() external returns (uint256);
    
    function transferOwnership(address newOwner) external;
    function lockOwnership() external;
    
}

contract Rebaser is Ownable {

    using SafeMath for uint256;
    using SafeMathInt for int256;
	using UInt256Lib for uint256;
	
	// Log rebase event
	
	event LogRebase(uint256 block, bytes32 blockHash, uint256 lagFactor, uint256 price, int256 delta, uint256 totalSupply);
	event LogRecalcAverageBlocks(uint256 blockNumber, uint256 blockTimestamp, uint256 averageBlocks);
	
	event LogUINT(uint256 num);
	event LogINT(int256 num);
	
	// Reference to RMPL ERC20 token contract
	
	IRMPL private _rmpl;
	
	// Uniswap V2 Pairs fpr ETH-RMPL and USDC-ETH to calculate 

	IUniswapV2Pair private _pairRMPL;
	IUniswapV2Pair private _pairUSD;
	
	// Last block checked
	
	uint256 private _blockLast;
	
	// Average Blocks - average number of blocks for max rebase duration (48hrs) to account for change in block mining rate
	
	uint256 private _averageBlocks;
	
	// Recalculate average blocks every 1hr
	
	uint256 private constant AVERAGE_BLOCKS_RECALC_SECONDS = 3600;
	
	// Block and timestamp of last recalc
	
	uint256 private _averageBlocksRecalcBlock = 0;
	uint256 private _averageBlocksRecalcTimestamp = 0;
	
	// Precision to recalculate average blocks
	uint256 private constant BLOCK_SECONDS_PRECISION = 10**8;
	
	// Last rebase stats
	
	uint256 private _rebaseBlock;
	bytes32 private _rebaseBlockHash;
	uint256 private _rebaseLagFactor;
	uint256 private _rebasePrice;
	int256 private _rebaseDelta;
	uint256 private _rebaseTotalSupply;
	
	// Price Target $1 USD inflation adjusted
	
	uint256 private _priceTarget;

    uint256 private constant RMPL_DECIMALS = 9;
    uint256 private constant ETH_DECIMALS = 18;
    
    //Currently using USDC
    
    uint256 private constant USD_DECIMALS = 8;
    
    
	uint256 private constant PRICE_PRECISION = 10**8;
	
	uint256 private PRICE_THRESHOLD_DEVIATION = 5 * 10**6;
	
	uint256 private _priceThresholdMax = 105 * 10**6;
	uint256 private _priceThresholdMin = 95 * 10**6;
	
	uint256 private constant MAX_REBASE_SECS = 600; // Maximum rebase duration in seconds (48hrs = 172800)
	
	int256 private constant LAG_PRECISION = 10**2;
	
	constructor() public {
	
		Ownable.initialize(msg.sender);
		
		_blockLast = 0;
		
		//initial price Target in $ (USD), CPI
		
		_priceTarget = 100 * 10**6;
		_priceThresholdMax = _priceTarget.add(PRICE_THRESHOLD_DEVIATION);
		_priceThresholdMin = _priceTarget.sub(PRICE_THRESHOLD_DEVIATION);
		
		_averageBlocksRecalcBlock = block.number;
		_averageBlocksRecalcTimestamp = block.timestamp;
		
		//Average blocks per max rebase duration (48hrs), assume 12 seconds per block initially
		
		_averageBlocks = MAX_REBASE_SECS.div(12);
		
		/*
		
		 SET LAST REBASE VALUES WHEN LIVE
		
		_rebaseBlock
		_rebaseBlockHash
		_rebaseLagFactor
		_rebasePrice
		_rebaseDelta
		_rebaseTotalSupply
		
		*/
		
    }
    
    // returns average number of blocks in a max rebase duration eg. 48hrs
    
    function getAverageBlocks()
        external
        view
        returns (uint256)
    {
        return _averageBlocks;
    }
    
    // return last rebase stats for automated reporting
    
    function getRebaseLastStats()
        external
        view
        returns (uint256, bytes32, uint256, uint256, int256, uint256)
    {
        return (_rebaseBlock, _rebaseBlockHash, _rebaseLagFactor, _rebasePrice, _rebaseDelta, _rebaseTotalSupply) ;
    }
    
    // change RMPL owner address, to allow for Rebaser.sol 
    
	function transferRMPLOwner(address newOwner)
        external
        onlyOwner
    {
        require(address(_rmpl) != address(0));
        _rmpl.transferOwnership(newOwner);
    }
    
    // lock RMPL owner on final Rebaser version
    
    function lockRMPLOwner()
        external
        onlyOwner
    {
        require(address(_rmpl) != address(0));
        _rmpl.lockOwnership();
    }
    
    //set reference to RMPL contract
    
    function setRMPL(IRMPL rmpl)
        external
        onlyOwner
    {
        _rmpl = IRMPL(rmpl);
    }
    
    //set price target ($1.00 with US CPI)
	
	function setPriceTarget(uint256 priceTarget)
        external
        onlyOwner
    {
        _priceTarget = priceTarget;
        
        _priceThresholdMax = _priceTarget.add(PRICE_THRESHOLD_DEVIATION);
		_priceThresholdMin = _priceTarget.sub(PRICE_THRESHOLD_DEVIATION);
    }
    
    //set Uniswap V2 pair ETH-RMPL

	function setPairRMPL(address factory, address token0, address token1)
        external
        onlyOwner
    {
		_pairRMPL = IUniswapV2Pair(UniswapV2Library.pairFor(factory, token0, token1));
		
    }
    
    //set Uniswap V2 pair USDC-ETH
    
    function setPairUSD(address factory, address token0, address token1)
        external
        onlyOwner
    {
		_pairUSD = IUniswapV2Pair(UniswapV2Library.pairFor(factory, token0, token1));
    }
	
	
	/*
	
	    Main rebase function
	    
	    - can be called by anyone
	    - can only be called once per block
	    - will check last 250 blocks / blocks since last call
	    - the hash that triggers a rebase can be observed off chain, so any address can then call rebase on the contract upto 250 blocks after to trigger it.
	    - RMPL team will have a server calling rebase, but RMPL holders will also have an incentive to call rebase, in effect decentralising the process.
	    
	    
	*/
	
    function rebase()
        external
        returns (int256)
    {
        
        // require RMPL and Uniswap pair references
        
        require(address(_rmpl) != address(0));
        require(address(_pairRMPL) != address(0));
        require(address(_pairUSD) != address(0));
        
        int256 supplyDelta = 0;
        
		bytes32 bhLast = blockhash(block.number - 1);
		
		uint blocksSinceLastCall = block.number - _blockLast;
        
        // can only call rebase once per block
        
        if (blocksSinceLastCall == 0) {
			return supplyDelta;
		}
		
		_blockLast = block.number;
		
		// loop through last 250 blocks, OR since last call
		
		for (uint i = 1; i < (blocksSinceLastCall >= 250 ? 250 : blocksSinceLastCall); i++) {
		    
		    uint256 bn = block.number - i;
		    bytes32 bh = blockhash(bn);
		    
		    // for prior block, calculate random number from hash, in 0 to (average blocks for 4hrs)
		    
		    uint256 bhRandInt = getHashRandom(bh, 0, _averageBlocks);
		    
		    uint256 blocksSinceRebase = bn - _rebaseBlock;
		    
		    if (bhRandInt < blocksSinceRebase) {
		        
		        //calculate RMPL-USD price from Uniswap v2 in current block

    		    uint256 price = getPriceRMPL_USD();
    		    
    		    if (price < _priceThresholdMin || price > _priceThresholdMax) {
    		        
    		        uint256 totalSupply = _rmpl.totalSupply();
    		        
    		        // Calcluate new supply delta
            			
            		supplyDelta = totalSupply.toInt256Safe().mul(price.toInt256Safe().sub(_priceTarget.toInt256Safe())).div(_priceTarget.toInt256Safe());
            		
            		uint256 lagFactor = getLagFactor(bhLast, totalSupply);
            		
            		// Apply random lag factor
            		
            		supplyDelta = supplyDelta.mul(LAG_PRECISION).div(lagFactor.toInt256Safe());
            		
            		// Rebase RMPL token
            		
            		uint256 totalSupplyNew = _rmpl.rebase(supplyDelta);
            		
            		// Update rebase stats
            		
            		_rebaseBlock = bn;
            		_rebaseBlockHash = bh;
            		_rebaseLagFactor = lagFactor;
            		_rebasePrice = price;
            		_rebaseDelta = supplyDelta;
            		_rebaseTotalSupply = totalSupplyNew;
            		
            		emit LogRebase(_rebaseBlock, _rebaseBlockHash, _rebaseLagFactor, _rebasePrice, _rebaseDelta, _rebaseTotalSupply);
            		emit LogUINT(bhRandInt);
            		emit LogUINT(blocksSinceRebase);
            		
            		break;
            		
    		    }
    		    
		    }
		    
        }
        
        // Recalculate average blocks if AVERAGE_BLOCKS_RECALC_SECONDS has elapsed
        
        uint256 diffSeconds = block.timestamp - _averageBlocksRecalcTimestamp;
        
        if (diffSeconds >= AVERAGE_BLOCKS_RECALC_SECONDS) {
            
            uint256 diffBlocks = block.number - _averageBlocksRecalcBlock;
            
            _averageBlocks = diffBlocks.mul(BLOCK_SECONDS_PRECISION).div(diffSeconds).mul(AVERAGE_BLOCKS_RECALC_SECONDS).div(BLOCK_SECONDS_PRECISION);
            
            _averageBlocksRecalcBlock = block.number;
            _averageBlocksRecalcTimestamp = block.timestamp;
            
            emit LogRecalcAverageBlocks(_averageBlocksRecalcBlock, _averageBlocksRecalcTimestamp, _averageBlocks);
            
        }
		
        return supplyDelta;
    }
	
	function getPriceRMPL_ETH() internal returns (uint256) {
	    
	    require(address(_pairRMPL) != address(0));
	 
	    (uint256 reserves0, uint256 reserves1,) = _pairRMPL.getReserves();
	    
	    // reserves0 = ETH (18 decimals)
	    // reserves1 = RMPL (9 decimals)
	    
	    // multiply to equate decimals, multiply up to PRICE_PRECISION
	    
        uint256 price = reserves1.mul(10**(18-RMPL_DECIMALS)).mul(PRICE_PRECISION).div(reserves0);
        
        return price;
    }
    
    function getPriceETH_USD() internal returns (uint256) {
        
        require(address(_pairUSD) != address(0));
        
	    (uint256 reserves0, uint256 reserves1,) = _pairUSD.getReserves();
	    
	    // reserves0 = USDC (8 decimals)
	    // reserves1 = ETH (18 decimals)
	    
	    // multiply to equate decimals, multiply up to PRICE_PRECISION
	    
        uint256 price = reserves0.mul(10**(18-USD_DECIMALS)).mul(PRICE_PRECISION).div(reserves1);
    
        return price;
    }
    
    function getPriceRMPL_USD() public returns (uint256) {
        
        require(address(_pairRMPL) != address(0));
        require(address(_pairUSD) != address(0));
        
        uint256 priceRMPL_ETH = getPriceRMPL_ETH();
        uint256 priceETH_USD = getPriceETH_USD();
        
	    uint256 priceRMPL_USD = priceRMPL_ETH.mul(priceETH_USD).div(PRICE_PRECISION);
	    
        return priceRMPL_USD;
    }
    
    /*
    
        Lag Factor:
        
        calculate a range initially based on total supply
        
        when supply is > 10M and < 100M, apply a function to accelerate quicker to 100M
    
    */
	
	function getLagFactor(bytes32 hash, uint256 totalSupply) internal pure returns (uint256) {

	    uint256 supply10M = 10 * 10**6 * 10 ** RMPL_DECIMALS;
        uint256 supply90M = 90 * 10**6 * 10 ** RMPL_DECIMALS;
        
	    uint256 min = 1000;
	    uint256 max = 1400;
	    
	    if (totalSupply <= (10 * 10**6 * RMPL_DECIMALS)) {
	        min = 600;
	    } else {
	        if (totalSupply >= (100 * 10**6 * RMPL_DECIMALS)) {
	            min = 800;
	        } else {
                min = uint256(totalSupply.toInt256Safe().sub(supply10M.toInt256Safe()).mul(100).div(supply90M.toInt256Safe())) ** 2;
                min = min.mul(200).div(100 ** 2).add(600);
	        }
	    }

	    if (totalSupply <= (10 * 10**6 * RMPL_DECIMALS)) {
	        max = 1000;
	    } else {
	        if (totalSupply >= (100 * 10**6 * RMPL_DECIMALS)) {
	            max = 1400;
	        } else {
	            max = uint256(totalSupply.toInt256Safe().sub(supply10M.toInt256Safe()).mul(100).div(supply90M.toInt256Safe())) ** 2;
                max = max.mul(400).div(100 ** 2).add(800);
	        }
	    }
	    
        return getHashRandom(hash, min, max);
    }

    // calculate random number from hash (Future versions will be a combination of blockhash and oracles, to offer more robust randomness whilst being gas efficient)
	
	function getHashRandom(bytes32 hash, uint256 min, uint256 max) internal pure returns (uint256) {		
	    uint256 hashInt = uint256(hash);
	    uint256 randMod = hashInt % (max - min);
        return randMod + min;
    }

}