// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.5.0;

interface ISCRYCallee {
    function SCRYCall(address sender, uint amount0, uint amount1, bytes calldata data) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.5.0;

interface ISCRYERC20 {
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.5.0;

import './ISCRYERC20.sol';

interface ISCRYERC20Permit is ISCRYERC20 {
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.5.0;

interface ISCRYFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);
    function oldMajor() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.5.0;

import './ISCRYERC20Permit.sol';

interface ISCRYPair is ISCRYERC20Permit {
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

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function burnUnbalanced(address to, uint token0Min, uint token1Min) external returns (uint amount0, uint amount1);
    function burnUnbalancedForExactToken(address to, address exactToken, uint amountExactOut) external returns (uint, uint);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function sync() external;

    function initialize(address, address, address) external;

    function setIsFlashSwapEnabled(bool _isFlashSwapEnabled) external;
    function setFeeToAddresses(address _feeTo0, address _feeTo1) external;
    function setRouter(address _router) external;
    function getSwapFee() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.5.0;

interface ISCRYPairDelegate {
    function updatePoolFeeAmount(address tokenA, address tokenB, uint256 feeAmountA, uint256 feeAmountB) external;
    function feeToAddresses(address tokenA, address tokenB) external view returns (address feeToA, address feeToB);
    function swapFee(address lpToken) external view returns (uint256);
    function router() external view returns (address);
    function isFlashSwapEnabled() external view returns (bool);
}

pragma solidity >=0.5.0;

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

pragma solidity >=0.5.0;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}

pragma solidity >=0.5.0;

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

// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.6.12;

import './interfaces/ISCRYERC20Permit.sol';
import './libraries/SafeMath.sol';

contract SCRYERC20 is ISCRYERC20Permit {
    using SafeMath for uint;

    string public override constant name = 'ScurrySwap LP';
    string public override constant symbol = 'SCRY-LP';
    uint8 public override constant decimals = 18;
    uint  public override totalSupply;
    mapping(address => uint) public override balanceOf;
    mapping(address => mapping(address => uint)) public override allowance;

    bytes32 public override DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public override constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint) public override nonces;

    constructor() public {
        uint chainId;
        assembly {
            chainId := chainid()
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

    function approve(address spender, uint value) external override returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint value) external override returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) external override returns (bool) {
        if (allowance[from][msg.sender] != 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        }
        _transfer(from, to, value);
        return true;
    }

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external override {
        require(deadline >= block.timestamp, 'SCRY: EXPIRED');
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, 'SCRY: INVALID_SIGNATURE');
        _approve(owner, spender, value);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.6.12;

import './interfaces/ISCRYFactory.sol';
import './SCRYPair.sol';

contract SCRYFactory is ISCRYFactory {
    address override public oldMajor;

    mapping(address => mapping(address => address)) override public getPair;
    address[] override public allPairs;

    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    constructor(address _oldMajor) public {
        oldMajor = _oldMajor;
    }

    function allPairsLength() external override view returns (uint) {
        return allPairs.length;
    }

    function createPair(address tokenA, address tokenB) external override returns (address pair) {
        require(tokenA != tokenB, 'SCRY: IDENTICAL_ADDRESSES');
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'SCRY: ZERO_ADDRESS');
        require(getPair[token0][token1] == address(0), 'SCRY: PAIR_EXISTS');
        bytes memory bytecode = type(SCRYPair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        ISCRYPair(pair).initialize(token0, token1, oldMajor);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.6.12;

import './interfaces/ISCRYPair.sol';
import './SCRYERC20.sol';
import './libraries/Math.sol';
import './libraries/UQ112x112.sol';
import './interfaces/ISCRYERC20.sol';
import './interfaces/ISCRYPairDelegate.sol';
import './interfaces/ISCRYCallee.sol';

contract SCRYPair is ISCRYPair, SCRYERC20 {
    using SafeMath for uint;
    using UQ112x112 for uint224;

    uint public override constant MINIMUM_LIQUIDITY = 10**3;
    uint internal constant DEFAULT_SWAP_FEE = 20;
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));
    uint256 internal constant MAX_FEE = 10000;
    uint256 internal constant PROTOCOL_FEE_DIVISOR = 5;

    address public override factory;
    address private pairDelegate;
    address public override token0;
    address public override token1;
 
    uint112 private reserve0;           // uses single storage slot, accessible via getReserves
    uint112 private reserve1;           // uses single storage slot, accessible via getReserves
    uint32  private blockTimestampLast; // uses single storage slot, accessible via getReserves

    uint public override price0CumulativeLast;
    uint public override price1CumulativeLast;

    address private feeTo0;
    address private feeTo1;
    address private router;

    bool private isFlashSwapEnabled;

    // used to ensure that a contract can only swap once per block. 
    mapping (address => uint) lastSwapMap;
    modifier oncePerBlock() {
      if (router == address(0) || msg.sender == router) {
        _;
      } else {
        require(lastSwapMap[tx.origin] != block.number, 'SCRY: LOCKED');
        lastSwapMap[tx.origin] = block.number;
        _;
      }
    }

    function getReserves() public override view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }

    function _safeTransfer(address token, address to, uint value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SCRY: TRANSFER_FAILED');
    }

    event Value(uint value);
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

    constructor() public {
        factory = msg.sender;
    }

    // called once by the factory at time of deployment
    function initialize(address _token0, address _token1, address _pairDelegate) external override {
        require(msg.sender == factory, 'SCRY: FORBIDDEN'); // sufficient check
        token0 = _token0;
        token1 = _token1;
        pairDelegate = _pairDelegate;
        if (pairDelegate != address(0)) {
          (feeTo0, feeTo1) = ISCRYPairDelegate(pairDelegate).feeToAddresses(_token0, _token1);
          router = ISCRYPairDelegate(pairDelegate).router();
          isFlashSwapEnabled = ISCRYPairDelegate(pairDelegate).isFlashSwapEnabled();
        }
    }

    // update reserves and, on the first call per block, price accumulators
    function _update(uint balance0, uint balance1, uint112 _reserve0, uint112 _reserve1) private {
        require(balance0 <= uint112(-1) && balance1 <= uint112(-1), 'SCRY: OVERFLOW');
        uint32 blockTimestamp = uint32(block.timestamp % 2**32);
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired
        if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
            // * never overflows, and + overflow is desired
            price0CumulativeLast += uint(UQ112x112.encode(_reserve1).uqdiv(_reserve0)) * timeElapsed;
            price1CumulativeLast += uint(UQ112x112.encode(_reserve0).uqdiv(_reserve1)) * timeElapsed;
        }
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        blockTimestampLast = blockTimestamp;
        emit Sync(reserve0, reserve1);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function mint(address to) external override oncePerBlock returns (uint liquidity) {
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings

        uint balance0 = ISCRYERC20(token0).balanceOf(address(this));
        uint balance1 = ISCRYERC20(token1).balanceOf(address(this));

        uint _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee

        if (_totalSupply == 0) {
            liquidity = Math.sqrt(balance0.sub(_reserve0).mul(balance1.sub(_reserve1))).sub(MINIMUM_LIQUIDITY);
            _mint(address(0), MINIMUM_LIQUIDITY); // permanently lock the first MINIMUM_LIQUIDITY tokens
            _update(balance0, balance1, _reserve0, _reserve1);
        } else {
          uint GAMMA = MAX_FEE - getSwapFee();
          if (balance1.sub(_reserve1).mul(balance0) < balance0.sub(_reserve0).mul(balance1)) {
            // case: swapping token0 for token1            
            uint numerator = balance0.sub(_reserve0).mul(balance1).sub(balance1.sub(_reserve1).mul(balance0));
            uint amt0In = numerator.mul(MAX_FEE) / balance1.mul(MAX_FEE + GAMMA);
            uint amt1Out = numerator.mul(GAMMA) / balance0.mul(MAX_FEE + GAMMA);
            liquidity = Math.min(
              (_totalSupply).mul(balance0.sub(_reserve0).sub(amt0In)) / amt0In.add(_reserve0),
              (_totalSupply).mul(balance1.add(amt1Out).sub(_reserve1)) / uint(_reserve1).sub(amt1Out));
            (uint feeAmount0, uint feeAmount1) = calculateAndTransferFees(token0, token1, amt0In, 0, _reserve0, _reserve1);
            _update(balance0.sub(feeAmount0), balance1.sub(feeAmount1), _reserve0, _reserve1);
          } else {
            // case: swapping token1 for token0
            uint numerator = balance1.sub(_reserve1).mul(balance0).sub(balance0.sub(_reserve0).mul(balance1));
            uint amt1In = numerator.mul(MAX_FEE) / balance0.mul(MAX_FEE + GAMMA);
            uint amt0Out = numerator.mul(GAMMA) / balance1.mul(MAX_FEE + GAMMA);
            liquidity = Math.min(
              (_totalSupply).mul(balance1.sub(_reserve1).sub(amt1In)) / amt1In.add(_reserve1),
              (_totalSupply).mul(balance0.add(amt0Out).sub(_reserve0)) / uint(_reserve0).sub(amt0Out));
            (uint feeAmount0, uint feeAmount1) = calculateAndTransferFees(token0, token1, 0, amt1In, _reserve0, _reserve1);
            _update(balance0.sub(feeAmount0), balance1.sub(feeAmount1), _reserve0, _reserve1);
          }
        }
        require(liquidity > 0, 'SCRY: INSUFFICIENT_LIQUIDITY_MINTED');
        _mint(to, liquidity);
        // mint event needs to emit after _mint for subgraph to work properly
        emit Mint(msg.sender, balance0.sub(_reserve0), balance1.sub(_reserve1));
    }

    function burnTransferAndUpdate(address to, address _token0, address _token1, uint balance0, uint balance1, uint amount0, uint amount1) private {
        require(balance0 <= uint112(-1) && balance1 <= uint112(-1), 'SCRY: OVERFLOW');
        _safeTransfer(_token0, to, amount0);
        _safeTransfer(_token1, to, amount1);
        _update(ISCRYERC20(_token0).balanceOf(address(this)), ISCRYERC20(_token1).balanceOf(address(this)), uint112(balance0), uint112(balance1));
        emit Burn(msg.sender, amount0, amount1, to);
    }

    // this low-level function should be called from a contract which performs important safety checks
    // this burns the deposited lp tokens and returns equal amounts of each token
    function burn(address to) external override oncePerBlock returns (uint amount0, uint amount1) {
        address _token0 = token0; // gas savings
        address _token1 = token1; // gas savings
        uint balance0 = ISCRYERC20(_token0).balanceOf(address(this));
        uint balance1 = ISCRYERC20(_token1).balanceOf(address(this));
        uint liquidity = balanceOf[address(this)];

        uint _totalSupply = totalSupply; // gas savings
        amount0 = liquidity.mul(balance0) / _totalSupply; // using balances ensures pro-rata distribution
        amount1 = liquidity.mul(balance1) / _totalSupply; // using balances ensures pro-rata distribution
        require(amount0 > 0 && amount1 > 0, 'SCRY: INSUFFICIENT_LIQUIDITY');
        _burn(address(this), liquidity);

        burnTransferAndUpdate(to, _token0, _token1, balance0, balance1, amount0, amount1);
    }

    // After burning lp tokens, swaps one token for the other to get the exact amount out
    function burnUnbalancedForExactToken(address to, address exactToken, uint amountExactOut) external override oncePerBlock returns (uint amount0, uint amount1) {
        address _token0 = token0; // gas savings
        address _token1 = token1; // gas savings
        // address otherToken;
        uint token0Balance = ISCRYERC20(_token0).balanceOf(address(this));
        uint token1Balance = ISCRYERC20(_token1).balanceOf(address(this));

        {
          uint liquidity = balanceOf[address(this)];
          uint _totalSupply = totalSupply;                             // gas savings
          uint token0LV = liquidity.mul(token0Balance) / _totalSupply; // using balances ensures pro-rata distribution
          uint token1LV = liquidity.mul(token1Balance) / _totalSupply; // using balances ensures pro-rata distribution

          require(token0LV > 0 && token1LV > 0, 'SCRY: INSUFFICIENT_LIQUIDITY');
          _burn(address(this), liquidity);

          if (exactToken == _token0) {
            amount0 = amountExactOut;
            amount1 = burnUnbalancedAmountOtherOut(amount0, token0LV, token0Balance, token1Balance, liquidity, _totalSupply);
            calculateAndTransferFees(
              _token0, _token1, 
              (token0LV > amount0) ? token0LV.sub(amount0) : 0, 
              (token1LV > amount1) ? token1LV.sub(amount1) : 0, 
              token0Balance.sub(token0LV), token1Balance.sub(token1LV));
          } else if (exactToken == _token1) {
            amount1 = amountExactOut;
            amount0 = burnUnbalancedAmountOtherOut(amount1, token1LV, token1Balance, token0Balance, liquidity, _totalSupply);
            calculateAndTransferFees(
              _token0, _token1, 
              (token0LV > amount0) ? token0LV.sub(amount0) : 0, 
              (token1LV > amount1) ? token1LV.sub(amount1) : 0, 
              token0Balance.sub(token0LV), token1Balance.sub(token1LV)); 
          } else {
            require(false, 'SCRY: INVALID_TOKEN');
          }       
        }

        burnTransferAndUpdate(to, _token0, _token1, token0Balance, token1Balance, amount0, amount1);
    }

    // helper for burnUnbalancedForExactToken
    function burnUnbalancedAmountOtherOut(uint amountExactOut, uint exactTokenLV, uint exactTokenBalance, uint otherTokenBalance, uint liquidity, uint _totalSupply) 
      private view returns (uint amountOtherOut) {
        uint GAMMA = MAX_FEE - getSwapFee();

        if (amountExactOut <= exactTokenLV) {
          // swap excess exactToken for otherToken
          amountOtherOut = otherTokenBalance.mul(exactTokenBalance.mul(liquidity).mul(MAX_FEE + GAMMA).sub(amountExactOut.mul(liquidity.mul(MAX_FEE).add(_totalSupply.mul(GAMMA))))) / 
            exactTokenBalance.mul(_totalSupply.mul(MAX_FEE).add(liquidity.mul(GAMMA))).sub(amountExactOut.mul(_totalSupply).mul(MAX_FEE + GAMMA));
        } else {
          // swap otherToken for exactToken
          amountOtherOut = otherTokenBalance.mul(exactTokenBalance.mul(liquidity).mul(MAX_FEE + GAMMA).sub(amountExactOut.mul(_totalSupply.mul(MAX_FEE).add(liquidity.mul(GAMMA))))) / 
            exactTokenBalance.mul(liquidity.mul(MAX_FEE).add(_totalSupply.mul(GAMMA))).sub(amountExactOut.mul(_totalSupply).mul(MAX_FEE + GAMMA));
        }
    }

    // Burns lp tokens and minimizes slippage given minimum token conditions
    function burnUnbalanced(address to, uint token0Min, uint token1Min) external override oncePerBlock returns (uint, uint) {
        uint balance0 = ISCRYERC20(token0).balanceOf(address(this));
        uint balance1 = ISCRYERC20(token1).balanceOf(address(this));

        uint amount0LV;
        uint amount1LV;
        {
          uint liquidity = balanceOf[address(this)];
          uint _totalSupply = totalSupply;                    // gas savings
          amount0LV = liquidity.mul(balance0) / _totalSupply; // using balances ensures pro-rata distribution
          amount1LV = liquidity.mul(balance1) / _totalSupply; // using balances ensures pro-rata distribution
          require(amount0LV > 0 && amount1LV > 0, 'SCRY: INSUFFICIENT_LIQUIDITY');
          _burn(address(this), liquidity);
        }

        (uint amount0, uint amount1) = burnSwapAmount(balance0, balance1, amount0LV, amount1LV, token0Min, token1Min);
        address _token0 = token0; // gas savings
        address _token1 = token1; // gas savings
        calculateAndTransferFees(_token0, _token1, 
          amount0LV >= amount0 ? amount0LV.sub(amount0) : 0, 
          amount1LV >= amount1 ? amount1LV.sub(amount1) : 0, 
          balance0 - amount0LV, balance1 - amount1LV);
        burnTransferAndUpdate(to, _token0, _token1, balance0, balance1, amount0, amount1);
        return (amount0, amount1);
    }

    // Helper for burnUnbalanced
    // returns amount of each token the LP should receive
    function burnSwapAmount(uint balance0, uint balance1, uint amount0, uint amount1, uint token0Min, uint token1Min) private view 
      returns (uint, uint) {
        if (amount0 < token0Min && amount1 < token1Min) {
          require(false, 'SCRY: INSUFFICIENT_LIQUIDITY');
        } 

        uint SWAP_FEE = getSwapFee();
        
        // check to see if one of the amounts if less than minimum, if so, we need to swap
        if (amount0 < token0Min) {
          // swap token1 for token0
          // uint swapAmt0Out = token0Min.sub(amount0);
          uint swapAmt1In = token0Min.sub(amount0).mul(balance1.sub(amount1)).mul(MAX_FEE) / balance0.sub(amount0).mul(MAX_FEE - SWAP_FEE).sub(token0Min.sub(amount0).mul(2 * MAX_FEE - SWAP_FEE));
          //  add 1 for rounding
          swapAmt1In = swapAmt1In.add(1);
          // amount1Out = amount1.sub(swapAmt1In);
          require(amount1.sub(swapAmt1In) >= token0Min, 'SCRY: INSUFFICIENT_TOKEN0');
          // amount0Out = token0Min;
          return (token0Min, amount1.sub(swapAmt1In));
        } else if (amount1 < token1Min) {
          // swap token0 for token1
          // uint swapAmt1Out = token1Min.sub(amount1);
          uint swapAmt0In = token1Min.sub(amount1).mul(balance0.sub(amount0)).mul(MAX_FEE) / balance1.sub(amount1).mul(MAX_FEE - SWAP_FEE).sub(token1Min.sub(amount1).mul(2 * MAX_FEE - SWAP_FEE));
          swapAmt0In = swapAmt0In.add(1);
          // amount0Out = amount0.sub(swapAmt0In);
          require(amount0.sub(swapAmt0In) >= token0Min, 'SCRY: INSUFFICIENT_TOKEN1');
          // amount1Out = token1Min;
          return (amount0.sub(swapAmt0In), token1Min);
        } else {
          // no swapping required
          return (amount0, amount1);
        }
    }

    // this low-level function should be called from a contract which performs important safety checks
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external override oncePerBlock {
        require(amount0Out > 0 || amount1Out > 0, 'SCRY: INSUFFICIENT_OUTPUT');
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        require(amount0Out < _reserve0 && amount1Out < _reserve1, 'SCRY: INSUFFICIENT_LIQUIDITY');

        uint balance0;
        uint balance1;
        uint amount0In;
        uint amount1In;

        { // scope for _token{0,1}, avoids stack too deep errors
        address _token0 = token0;
        address _token1 = token1;
        require(to != _token0 && to != _token1, 'SCRY: INVALID_TO');
        if (amount0Out > 0) _safeTransfer(_token0, to, amount0Out); // optimistically transfer tokens
        if (amount1Out > 0) _safeTransfer(_token1, to, amount1Out); // optimistically transfer tokens
        if (data.length > 0 && isFlashSwapEnabled) ISCRYCallee(to).SCRYCall(msg.sender, amount0Out, amount1Out, data);
        balance0 = ISCRYERC20(_token0).balanceOf(address(this));
        balance1 = ISCRYERC20(_token1).balanceOf(address(this));
        // already checked for overflow
        amount0In = balance0 > _reserve0 - amount0Out ? balance0 - (_reserve0 - amount0Out) : 0;
        amount1In = balance1 > _reserve1 - amount1Out ? balance1 - (_reserve1 - amount1Out) : 0;
        require(amount0In > 0 || amount1In > 0, 'SCRY: INSUFFICIENT_INPUT');
        (uint feeAmount0, uint feeAmount1) = calculateAndTransferFees(_token0, _token1, amount0In, amount1In, _reserve0, _reserve1);
        _update(balance0 - feeAmount0, balance1 - feeAmount1, _reserve0, _reserve1);
        }
        {
        uint GAMMA = MAX_FEE - getSwapFee();

        // derivation requires some algebra, basically ensures swap is profitable for LPs. check whitepaper for details
        require((balance0.mul(MAX_FEE**2 + MAX_FEE*GAMMA)).sub(amount0In.mul(MAX_FEE**2 - GAMMA**2)).sub(uint(_reserve0).mul(MAX_FEE**2))
          .mul((balance1.mul(MAX_FEE**2 + MAX_FEE*GAMMA)).sub(amount1In.mul(MAX_FEE**2 - GAMMA**2)).sub(uint(_reserve1).mul(MAX_FEE**2))) >=
          uint(_reserve0).mul(_reserve1).mul(GAMMA**2 * MAX_FEE**2), 'SCRY: INVALID_SWAP');
        }

        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }

    // tokenA, tokenB should always be token0, token1 respectively
    function calculateAndTransferFees(address tokenA, address tokenB, uint amountAIn, uint amountBIn, uint _reserveA, uint _reserveB) private returns(uint feeAmountA, uint feeAmountB) {
      uint SWAP_FEE = getSwapFee();

      address _feeToA = feeTo0; // gas savings
      address _feeToB = feeTo1;
      if (_feeToA != address(0) && _feeToB != address(0)) {
        // if both tokens have fee addresses, we just take fee from both inputs
        feeAmountA = amountAIn.mul(SWAP_FEE) / MAX_FEE.mul(PROTOCOL_FEE_DIVISOR);
        feeAmountB = amountBIn.mul(SWAP_FEE) / MAX_FEE.mul(PROTOCOL_FEE_DIVISOR);
        if (feeAmountA > 0) { _safeTransfer(tokenA, _feeToA, feeAmountA); }
        if (feeAmountB > 0) { _safeTransfer(tokenB, _feeToB, feeAmountB); }
        ISCRYPairDelegate(pairDelegate).updatePoolFeeAmount(tokenA, tokenB, feeAmountA, feeAmountB);
      } else if (_feeToA != address(0)) {
        // convert the fee for amountBIn into tokenA terms
        // inputFeeA = amountAIn.mul(SWAP_FEE) / MAX_FEE.mul(PROTOCOL_FEE_DIVISOR);
        // contribution from other input amount is
        // inputFeeB = outputFromB * 0.002 / 0.998 * 1 / 5
        // feeAmountA = inputFeeA + inputFeeB
        feeAmountA = (amountAIn.mul(SWAP_FEE) / MAX_FEE).add(
          amountBIn.mul(_reserveA).mul(SWAP_FEE) / _reserveB.mul(MAX_FEE).add(amountBIn.mul(2 * MAX_FEE - SWAP_FEE))) / PROTOCOL_FEE_DIVISOR;
        if (feeAmountA > 0) { _safeTransfer(tokenA, _feeToA, feeAmountA); }
        ISCRYPairDelegate(pairDelegate).updatePoolFeeAmount(tokenA, tokenB, feeAmountA, feeAmountB);
      } else if (_feeToB != address(0)) {
        feeAmountB = (amountBIn.mul(SWAP_FEE) / MAX_FEE).add(
          amountAIn.mul(_reserveB).mul(SWAP_FEE) / _reserveA.mul(MAX_FEE).add(amountAIn.mul(2 * MAX_FEE - SWAP_FEE))) / PROTOCOL_FEE_DIVISOR;
        if (feeAmountB > 0) { _safeTransfer(tokenB, _feeToB, feeAmountB); }
        ISCRYPairDelegate(pairDelegate).updatePoolFeeAmount(tokenA, tokenB, feeAmountA, feeAmountB);
      }
    }

    // force reserves to match balances
    function sync() external override {
        _update(ISCRYERC20(token0).balanceOf(address(this)), ISCRYERC20(token1).balanceOf(address(this)), reserve0, reserve1);
    }

    function getSwapFee() public view override returns (uint256 swapFee) {
      if (pairDelegate == address(0)) { 
        return DEFAULT_SWAP_FEE;
      }
      swapFee = ISCRYPairDelegate(pairDelegate).swapFee(address(this));
      // 5% max fee
      require(swapFee < 500, "SCRY: INVALID_FEE");
    }

    function setFeeToAddresses(address _feeTo0, address _feeTo1) external override {
      require(msg.sender == pairDelegate, 'SCRY: FORBIDDEN');
      feeTo0 = _feeTo0;
      feeTo1 = _feeTo1;
    }

    function setRouter(address _router) external override {
      require(msg.sender == pairDelegate, 'SCRY: FORBIDDEN');
      router = _router;
    }

    function setIsFlashSwapEnabled(bool _isFlashSwapEnabled) external override {
      require(msg.sender == pairDelegate, 'SCRY: FORBIDDEN');
      isFlashSwapEnabled = _isFlashSwapEnabled;
    }
}