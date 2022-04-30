/**
 *Submitted for verification at Etherscan.io on 2022-04-30
*/

// File: contracts/TallySwapFactory.sol

pragma solidity 0.8.12;








interface ITallyswapFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function INIT_CODE_HASH() external view returns (bytes32);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
    function setDevFee(address pair, uint8 _devFee) external;
    function setSwapFee(address pair, uint32 swapFee) external;
}









interface ITallyswapPair {
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
    function swapFee() external view returns (uint32);
    function devFee() external view returns (uint32);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
    function setSwapFee(uint32) external;
    function setDevFee(uint32) external;
}









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



// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))

// range: [0, 2**112 - 1]
// resolution: 1 / 2**112

library UQ112x112 {
    uint224 constant Q112 = 2**112;

    // encode a uint112 as a UQ112x112
    function encode(uint112 y) internal pure returns (uint224 z) {
        z = uint224(y) * Q112; // never overflows
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function uqdiv(uint224 x, uint112 y) internal pure returns (uint224 z) {
        z = x / uint224(y);
    }
}



interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}



interface ITallyswapCallee {
    function TallyswapCall(address sender, uint amount0, uint amount1, bytes calldata data) external;
}


interface ITallyswapERC20 {
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
}



// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }
}
contract TallyswapERC20 is ITallyswapERC20 {
    using SafeMath for uint;

    string public constant name = 'Tallyswap LPs';
    string public constant symbol = 'TALLY-LP';
    uint8 public constant decimals = 18;
    uint  public totalSupply;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    bytes32 public DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint) public nonces;

    // event Approval(address indexed owner, address indexed spender, uint value);
    // event Transfer(address indexed from, address indexed to, uint value);

    constructor() public {
        uint chainId;
        assembly {
            chainId := 97
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes(name)),
                keccak256(bytes('1')),
                chainId,
                address(this)
            )
        );
    }

    function _mint(address to, uint value) internal {
        totalSupply = totalSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint value) internal {
        balanceOf[from] = balanceOf[from].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }

    function _approve(address owner, address spender, uint value) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(address from, address to, uint value) private {
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) external returns (bool) {
        if (allowance[from][msg.sender] != type(uint).max) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        }
        _transfer(from, to, value);
        return true;
    }

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
        require(deadline >= block.timestamp, 'Tallyswap: EXPIRED');
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, 'Tallyswap: INVALID_SIGNATURE');
        _approve(owner, spender, value);
    }
}
contract TallyswapPair is TallyswapERC20 {
    using SafeMath for uint256;
    using UQ112x112 for uint224;

    uint256 public constant MINIMUM_LIQUIDITY = 10**3;
    bytes4 private constant SELECTOR =
        bytes4(keccak256(bytes("transfer(address,uint256)")));

    address public factory;
    address public token0;
    address public token1;

    uint112 private reserve0; // uses single storage slot, accessible via getReserves
    uint112 private reserve1; // uses single storage slot, accessible via getReserves
    uint32 private blockTimestampLast; // uses single storage slot, accessible via getReserves

    uint256 public price0CumulativeLast;
    uint256 public price1CumulativeLast;
    uint256 public kLast; // reserve0 * reserve1, as of immediately after the most recent liquidity event
    // swap fee 0.4%
    uint32 public swapFee = 400; // uses 0.1% default
    uint32 public devFee = 5; // uses 0.5% default from swap fee

    // marketingFee + operationsFee + artisticFee + technicalFee + tallyBackFee + liquidityProviderFee = 0.4%
    uint32 public marketingFee = 70; // uses 0.07%
    uint32 public secondaryMarketFee= 30; // 0.03
    uint32 public operationsFee = 76; // uses 0.076%
    uint32 public artisticFee = 16; // uses 0.016%
    uint32 public technicalFee = 8; // uses 0.008%
    uint32 public tallyBackFee = 30; // uses 0.03%
    uint32 public liquidityProviderFee = 170; // uses 0.17%

    address public marketingAddr = 0xFD4C39E30D90CFc0709DdF3Ef9bAf936f4c9CbBa;
    address public secondaryMarketingAddr = 0xdD63a94A6B33cDA34d62eE3299B92CBFa541092f;
    address public operationsAddr = 0x9eCa53cf9F2F540daADf9B1B890455bdc43f3804;
    address public artisticAddr = 0x5a2674365E53B41FB189b575dF91968f6dA11907;
    address public technicalAddr = 0xB8a3D315D6D0d8655014F3fA87fA227bcbB69CC4;

    // address public tallyBackAddr =
    // address public liquidityProviderAddr =

    uint256 private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, "Tallyswap: LOCKED");
        unlocked = 0;
        _;
        unlocked = 1;
    }

    function getReserves()
        public
        view
        returns (
            uint112 _reserve0,
            uint112 _reserve1,
            uint32 _blockTimestampLast
        )
    {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }

    function _safeTransfer(
        address token,
        address to,
        uint256 value
    ) private {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(SELECTOR, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "Tallyswap: TRANSFER_FAILED"
        );
    }

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    constructor() public {
        factory = msg.sender;
    }

    // called once by the factory at time of deployment
    function initialize(address _token0, address _token1) external {
        require(msg.sender == factory, "Tallyswap: FORBIDDEN"); // sufficient check
        token0 = _token0;
        token1 = _token1;
    }

    function setSwapFee(uint32 _swapFee) external {
        require(_swapFee > 0, "TallyswapPair: lower then 0");
        require(msg.sender == factory, "TallyswapPair: FORBIDDEN");
        require(_swapFee <= 1000, "TallyswapPair: FORBIDDEN_FEE");
        swapFee = _swapFee;
    }

    function setDevFee(uint32 _devFee) external {
        require(_devFee > 0, "TallyswapPair: lower then 0");
        require(msg.sender == factory, "TallyswapPair: FORBIDDEN");
        require(_devFee <= 500, "TallyswapPair: FORBIDDEN_FEE");
        devFee = _devFee;
    }

	// marketingFee + operationsFee + artisticFee + technicalFee + tallyBackFee + liquidityProviderFee = 0.4% Setter Fee.

   function setMarketingFee(uint32 _fee) external {

        require(_fee > 0 && swapFee>0, "TallyswapPair: lower then 0");
        require(msg.sender == factory, "TallyswapPair: FORBIDDEN");

	uint32 allFee=_fee+secondaryMarketFee+operationsFee+artisticFee+technicalFee+tallyBackFee+liquidityProviderFee;
	require(allFee <= swapFee, "TallyswapPair: FORBIDDEN_FEE");
	marketingFee=_fee;

   }


   function setSecondaryMarketFee(uint32 _fee) external {

        require(_fee > 0 && swapFee>0, "TallyswapPair: lower then 0");
        require(msg.sender == factory, "TallyswapPair: FORBIDDEN");

	uint32 allFee=_fee+marketingFee+operationsFee+artisticFee+technicalFee+tallyBackFee+liquidityProviderFee;
	require(allFee <= swapFee, "TallyswapPair: FORBIDDEN_FEE");
	secondaryMarketFee=_fee;

   }

   function setOperationsFee(uint32 _fee) external {

        require(_fee > 0 && swapFee>0, "TallyswapPair: lower then 0");
        require(msg.sender == factory, "TallyswapPair: FORBIDDEN");

	uint32 allFee=_fee+marketingFee+secondaryMarketFee+artisticFee+technicalFee+tallyBackFee+liquidityProviderFee;
	require(allFee <= swapFee, "TallyswapPair: FORBIDDEN_FEE");
	operationsFee=_fee;

   }

   function setArtisticFee(uint32 _fee) external {

        require(_fee > 0 && swapFee>0, "TallyswapPair: lower then 0");
        require(msg.sender == factory, "TallyswapPair: FORBIDDEN");

	uint32 allFee=_fee+marketingFee+secondaryMarketFee+operationsFee+technicalFee+tallyBackFee+liquidityProviderFee;
	require(allFee <= swapFee, "TallyswapPair: FORBIDDEN_FEE");
	artisticFee=_fee;

   }


   function setTechnicalFee(uint32 _fee) external {

        require(_fee > 0 && swapFee>0, "TallyswapPair: lower then 0");
        require(msg.sender == factory, "TallyswapPair: FORBIDDEN");

	uint32 allFee=_fee+marketingFee+secondaryMarketFee+operationsFee+artisticFee+tallyBackFee+liquidityProviderFee;
	require(allFee <= swapFee, "TallyswapPair: FORBIDDEN_FEE");
	technicalFee=_fee;

   }


   function setTallyBackFee(uint32 _fee) external {

        require(_fee > 0 && swapFee>0, "TallyswapPair: lower then 0");
        require(msg.sender == factory, "TallyswapPair: FORBIDDEN");

	uint32 allFee=_fee+marketingFee+secondaryMarketFee+operationsFee+artisticFee+technicalFee+liquidityProviderFee;
	require(allFee <= swapFee, "TallyswapPair: FORBIDDEN_FEE");
	tallyBackFee=_fee;

   }


   function setLiquidityProviderFee(uint32 _fee) external {

        require(_fee > 0 && swapFee>0, "TallyswapPair: lower then 0");
        require(msg.sender == factory, "TallyswapPair: FORBIDDEN");

	uint32 allFee=_fee+marketingFee+secondaryMarketFee+operationsFee+artisticFee+technicalFee+tallyBackFee;
	require(allFee <= swapFee, "TallyswapPair: FORBIDDEN_FEE");
	liquidityProviderFee=_fee;

   }


  function setMarketingAddr(address _addr) external {

   require(msg.sender == factory, "TallyswapPair: FORBIDDEN");
   marketingAddr=_addr;

  }


  function setSecondaryMarketingAddr(address _addr) external {

   require(msg.sender == factory, "TallyswapPair: FORBIDDEN");
   secondaryMarketingAddr=_addr;

  }

  function setOperationsAddr(address _addr) external {

   require(msg.sender == factory, "TallyswapPair: FORBIDDEN");
   operationsAddr=_addr;

  }


  function setArtisticAddr(address _addr) external {

   require(msg.sender == factory, "TallyswapPair: FORBIDDEN");
   artisticAddr=_addr;

  }

  function setTechnicalAddr(address _addr) external {

   require(msg.sender == factory, "TallyswapPair: FORBIDDEN");
   technicalAddr=_addr;

  }


    // update reserves and, on the first call per block, price accumulators
    function _update(
        uint256 balance0,
        uint256 balance1,
        uint112 _reserve0,
        uint112 _reserve1
    ) private {
        require(
            balance0 <= type(uint112).max && balance1 <= type(uint112).max,
            "Tallyswap: OVERFLOW"
        );
        uint32 blockTimestamp = uint32(block.timestamp % 2**32);
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired
        if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
            // * never overflows, and + overflow is desired
            price0CumulativeLast +=
                uint256(UQ112x112.encode(_reserve1).uqdiv(_reserve0)) *
                timeElapsed;
            price1CumulativeLast +=
                uint256(UQ112x112.encode(_reserve0).uqdiv(_reserve1)) *
                timeElapsed;
        }
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        blockTimestampLast = blockTimestamp;
        emit Sync(reserve0, reserve1);
    }

    // if fee is on, mint liquidity equivalent to 1/6th of the growth in sqrt(k)
    function _mintFee(uint112 _reserve0, uint112 _reserve1)
        private
        returns (bool feeOn)
    {
        address feeTo = ITallyswapFactory(factory).feeTo();
        feeOn = feeTo != address(0);
        uint256 _kLast = kLast; // gas savings
        if (feeOn) {
            if (_kLast != 0) {
                uint256 rootK = Math.sqrt(uint256(_reserve0).mul(_reserve1));
                uint256 rootKLast = Math.sqrt(_kLast);
                if (rootK > rootKLast) {
                    // uint numerator = totalSupply.mul(rootK.sub(rootKLast));
                    // uint denominator = rootK.mul(devFee).add(rootKLast);
                    // uint liquidity = numerator / denominator;
                    // if (liquidity > 0) _mint(feeTo, liquidity);

                    if (swapFee > 0) {

			// conditions for 0 fee

      			uint Divider = 100000; // BASIS POINT VALUE

			if(marketingFee>0 && marketingAddr!=address(0) ){

			    uint256 marketingFeeAmount = uint256(swapFee).mul(marketingFee).div(Divider);
                            _mint(marketingAddr, marketingFeeAmount);
			}

			if(secondaryMarketFee>0 && secondaryMarketingAddr!=address(0) ){

			    uint256 smarketingFeeAmount = uint256(swapFee).mul(secondaryMarketFee).div(Divider);
                            _mint(secondaryMarketingAddr, smarketingFeeAmount);
			}

			if(operationsFee>0 && operationsAddr!=address(0) ){

			    uint256 operationsFeeAmount = uint256(swapFee).mul(operationsFee).div(Divider);
                            _mint(operationsAddr, operationsFeeAmount);
			}

			if(artisticFee>0 && artisticAddr!=address(0) ){

			    uint256 artisticFeeAmount = uint256(swapFee).mul(artisticFee).div(Divider);
                            _mint(artisticAddr, artisticFeeAmount);
			}

			if(technicalFee>0 && technicalAddr!=address(0) ){

			    uint256 technicalFeeAmount = uint256(swapFee).mul(technicalFee).div(Divider);
                            _mint(technicalAddr, technicalFeeAmount);
			}


                    }
                }
            }
        } else if (_kLast != 0) {
            kLast = 0;
        }
    }

    // this low-level function should be called from a contract which performs important safety checks
    function mint(address to) external lock returns (uint256 liquidity) {
        (uint112 _reserve0, uint112 _reserve1, ) = getReserves(); // gas savings
        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));
        uint256 amount0 = balance0.sub(_reserve0);
        uint256 amount1 = balance1.sub(_reserve1);

        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint256 _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        if (_totalSupply == 0) {
            liquidity = Math.sqrt(amount0.mul(amount1)).sub(MINIMUM_LIQUIDITY);
            _mint(address(0), MINIMUM_LIQUIDITY); // permanently lock the first MINIMUM_LIQUIDITY tokens
        } else {
            liquidity = Math.min(
                amount0.mul(_totalSupply) / _reserve0,
                amount1.mul(_totalSupply) / _reserve1
            );
        }
        require(liquidity > 0, "Tallyswap: INSUFFICIENT_LIQUIDITY_MINTED");
        _mint(to, liquidity);

        _update(balance0, balance1, _reserve0, _reserve1);
        if (feeOn) kLast = uint256(reserve0).mul(reserve1); // reserve0 and reserve1 are up-to-date
        emit Mint(msg.sender, amount0, amount1);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function burn(address to)
        external
        lock
        returns (uint256 amount0, uint256 amount1)
    {
        (uint112 _reserve0, uint112 _reserve1, ) = getReserves(); // gas savings
        address _token0 = token0; // gas savings
        address _token1 = token1; // gas savings
        uint256 balance0 = IERC20(_token0).balanceOf(address(this));
        uint256 balance1 = IERC20(_token1).balanceOf(address(this));
        uint256 liquidity = balanceOf[address(this)];

        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint256 _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        amount0 = liquidity.mul(balance0) / _totalSupply; // using balances ensures pro-rata distribution
        amount1 = liquidity.mul(balance1) / _totalSupply; // using balances ensures pro-rata distribution
        require(
            amount0 > 0 && amount1 > 0,
            "Tallyswap: INSUFFICIENT_LIQUIDITY_BURNED"
        );
        _burn(address(this), liquidity);
        _safeTransfer(_token0, to, amount0);
        _safeTransfer(_token1, to, amount1);
        balance0 = IERC20(_token0).balanceOf(address(this));
        balance1 = IERC20(_token1).balanceOf(address(this));

        _update(balance0, balance1, _reserve0, _reserve1);
        if (feeOn) kLast = uint256(reserve0).mul(reserve1); // reserve0 and reserve1 are up-to-date
        emit Burn(msg.sender, amount0, amount1, to);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external lock {
        require(
            amount0Out > 0 || amount1Out > 0,
            "Tallyswap: INSUFFICIENT_OUTPUT_AMOUNT"
        );
        (uint112 _reserve0, uint112 _reserve1, ) = getReserves(); // gas savings
        require(
            amount0Out < _reserve0 && amount1Out < _reserve1,
            "Tallyswap: INSUFFICIENT_LIQUIDITY"
        );

        uint256 balance0;
        uint256 balance1;
        {
            // scope for _token{0,1}, avoids stack too deep errors
            address _token0 = token0;
            address _token1 = token1;
            require(to != _token0 && to != _token1, "Tallyswap: INVALID_TO");

            if (amount0Out > 0) _safeTransfer(_token0, to, amount0Out); // optimistically transfer tokens
            if (amount1Out > 0) _safeTransfer(_token1, to, amount1Out); // optimistically transfer tokens
            if (data.length > 0)
                ITallyswapCallee(to).TallyswapCall(
                    msg.sender,
                    amount0Out,
                    amount1Out,
                    data
                );
            balance0 = IERC20(_token0).balanceOf(address(this));
            balance1 = IERC20(_token1).balanceOf(address(this));
        }
        uint256 amount0In = balance0 > _reserve0 - amount0Out
            ? balance0 - (_reserve0 - amount0Out)
            : 0;
        uint256 amount1In = balance1 > _reserve1 - amount1Out
            ? balance1 - (_reserve1 - amount1Out)
            : 0;
        require(
            amount0In > 0 || amount1In > 0,
            "Tallyswap: INSUFFICIENT_INPUT_AMOUNT"
        );
        {
            // scope for reserve{0,1}Adjusted, avoids stack too deep errors
            uint256 _swapFee = swapFee;
            uint256 balance0Adjusted = balance0.mul(1000).sub(
                amount0In.mul(_swapFee)
            );
            uint256 balance1Adjusted = balance1.mul(1000).sub(
                amount1In.mul(_swapFee)
            );
            require(
                balance0Adjusted.mul(balance1Adjusted) >=
                    uint256(_reserve0).mul(_reserve1).mul(1000**2),
                "Tallyswap: K"
            );
        }

        _update(balance0, balance1, _reserve0, _reserve1);
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }

    // force balances to match reserves
    function skim(address to) external lock {
        address _token0 = token0; // gas savings
        address _token1 = token1; // gas savings
        _safeTransfer(
            _token0,
            to,
            IERC20(_token0).balanceOf(address(this)).sub(reserve0)
        );
        _safeTransfer(
            _token1,
            to,
            IERC20(_token1).balanceOf(address(this)).sub(reserve1)
        );
    }

    // force reserves to match balances
    function sync() external lock {
        _update(
            IERC20(token0).balanceOf(address(this)),
            IERC20(token1).balanceOf(address(this)),
            reserve0,
            reserve1
        );
    }
}
contract TallyswapFactory is ITallyswapFactory {
    address public feeTo;
    address public feeToSetter;
    bytes32 public INIT_CODE_HASH = keccak256(abi.encodePacked(type(TallyswapPair).creationCode));

    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;

    // event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    constructor(address _feeToSetter) public {
        feeToSetter = _feeToSetter;
    }

    function allPairsLength() external view returns (uint) {
        return allPairs.length;
    }

    function createPair(address tokenA, address tokenB) external returns (address pair) {
        require(tokenA != tokenB, 'Tallyswap: IDENTICAL_ADDRESSES');
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'Tallyswap: ZERO_ADDRESS');
        require(getPair[token0][token1] == address(0), 'Tallyswap: PAIR_EXISTS'); // single check is sufficient
        bytes memory bytecode = type(TallyswapPair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        ITallyswapPair(pair).initialize(token0, token1);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function setFeeTo(address _feeTo) external {
        require(msg.sender == feeToSetter, 'Tallyswap: FORBIDDEN');
        feeTo = _feeTo;
    }

    function setFeeToSetter(address _feeToSetter) external {
        require(msg.sender == feeToSetter, 'Tallyswap: FORBIDDEN');
        feeToSetter = _feeToSetter;
    }

    function setDevFee(address _pair, uint8 _devFee) external {
        require(msg.sender == feeToSetter, 'Tallyswap: FORBIDDEN');
        require(_devFee > 0, 'Tallyswap: FORBIDDEN_FEE');
        TallyswapPair(_pair).setDevFee(_devFee);
    }

    function setSwapFee(address _pair, uint32 _swapFee) external {
        require(msg.sender == feeToSetter, 'Tallyswap: FORBIDDEN');
        TallyswapPair(_pair).setSwapFee(_swapFee);
    }
}