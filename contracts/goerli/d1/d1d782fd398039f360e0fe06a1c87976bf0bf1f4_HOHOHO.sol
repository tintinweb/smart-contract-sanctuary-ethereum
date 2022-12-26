// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: WHO WHO
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//    /**                                                                                                                         //
//     *Submitted for verification at Etherscan.io on 2020-05-05                                                                  //
//    */                                                                                                                          //
//                                                                                                                                //
//    // File: contracts/interfaces/IUniswapV2Pair.sol                                                                            //
//                                                                                                                                //
//    pragma solidity >=0.5.0;                                                                                                    //
//                                                                                                                                //
//    interface IUniswapV2Pair {                                                                                                  //
//        event Approval(address indexed owner, address indexed spender, uint value);                                             //
//        event Transfer(address indexed from, address indexed to, uint value);                                                   //
//                                                                                                                                //
//        function name() external pure returns (string memory);                                                                  //
//        function symbol() external pure returns (string memory);                                                                //
//        function decimals() external pure returns (uint8);                                                                      //
//        function totalSupply() external view returns (uint);                                                                    //
//        function balanceOf(address owner) external view returns (uint);                                                         //
//        function allowance(address owner, address spender) external view returns (uint);                                        //
//                                                                                                                                //
//        function approve(address spender, uint value) external returns (bool);                                                  //
//        function transfer(address to, uint value) external returns (bool);                                                      //
//        function transferFrom(address from, address to, uint value) external returns (bool);                                    //
//                                                                                                                                //
//        function DOMAIN_SEPARATOR() external view returns (bytes32);                                                            //
//        function PERMIT_TYPEHASH() external pure returns (bytes32);                                                             //
//        function nonces(address owner) external view returns (uint);                                                            //
//                                                                                                                                //
//        function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;     //
//                                                                                                                                //
//        event Mint(address indexed sender, uint amount0, uint amount1);                                                         //
//        event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);                                     //
//        event Swap(                                                                                                             //
//            address indexed sender,                                                                                             //
//            uint amount0In,                                                                                                     //
//            uint amount1In,                                                                                                     //
//            uint amount0Out,                                                                                                    //
//            uint amount1Out,                                                                                                    //
//            address indexed to                                                                                                  //
//        );                                                                                                                      //
//        event Sync(uint112 reserve0, uint112 reserve1);                                                                         //
//                                                                                                                                //
//        function MINIMUM_LIQUIDITY() external pure returns (uint);                                                              //
//        function factory() external view returns (address);                                                                     //
//        function token0() external view returns (address);                                                                      //
//        function token1() external view returns (address);                                                                      //
//        function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);           //
//        function price0CumulativeLast() external view returns (uint);                                                           //
//        function price1CumulativeLast() external view returns (uint);                                                           //
//        function kLast() external view returns (uint);                                                                          //
//                                                                                                                                //
//        function mint(address to) external returns (uint liquidity);                                                            //
//        function burn(address to) external returns (uint amount0, uint amount1);                                                //
//        function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;                              //
//        function skim(address to) external;                                                                                     //
//        function sync() external;                                                                                               //
//                                                                                                                                //
//        function initialize(address, address) external;                                                                         //
//    }                                                                                                                           //
//                                                                                                                                //
//    // File: contracts/interfaces/IUniswapV2ERC20.sol                                                                           //
//                                                                                                                                //
//    pragma solidity >=0.5.0;                                                                                                    //
//                                                                                                                                //
//    interface IUniswapV2ERC20 {                                                                                                 //
//        event Approval(address indexed owner, address indexed spender, uint value);                                             //
//        event Transfer(address indexed from, address indexed to, uint value);                                                   //
//                                                                                                                                //
//        function name() external pure returns (string memory);                                                                  //
//        function symbol() external pure returns (string memory);                                                                //
//        function decimals() external pure returns (uint8);                                                                      //
//        function totalSupply() external view returns (uint);                                                                    //
//        function balanceOf(address owner) external view returns (uint);                                                         //
//        function allowance(address owner, address spender) external view returns (uint);                                        //
//                                                                                                                                //
//        function approve(address spender, uint value) external returns (bool);                                                  //
//        function transfer(address to, uint value) external returns (bool);                                                      //
//        function transferFrom(address from, address to, uint value) external returns (bool);                                    //
//                                                                                                                                //
//        function DOMAIN_SEPARATOR() external view returns (bytes32);                                                            //
//        function PERMIT_TYPEHASH() external pure returns (bytes32);                                                             //
//        function nonces(address owner) external view returns (uint);                                                            //
//                                                                                                                                //
//        function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;     //
//    }                                                                                                                           //
//                                                                                                                                //
//    // File: contracts/libraries/SafeMath.sol                                                                                   //
//                                                                                                                                //
//    pragma solidity =0.5.16;                                                                                                    //
//                                                                                                                                //
//    // a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)                    //
//                                                                                                                                //
//    library SafeMath {                                                                                                          //
//        function add(uint x, uint y) internal pure returns (uint z) {                                                           //
//            require((z = x + y) >= x, 'ds-math-add-overflow');                                                                  //
//        }                                                                                                                       //
//                                                                                                                                //
//        function sub(uint x, uint y) internal pure returns (uint z) {                                                           //
//            require((z = x - y) <= x, 'ds-math-sub-underflow');                                                                 //
//        }                                                                                                                       //
//                                                                                                                                //
//        function mul(uint x, uint y) internal pure returns (uint z) {                                                           //
//            require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');                                                    //
//        }                                                                                                                       //
//    }                                                                                                                           //
//                                                                                                                                //
//    // File: contracts/UniswapV2ERC20.sol                                                                                       //
//                                                                                                                                //
//    pragma solidity =0.5.16;                                                                                                    //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//    contract UniswapV2ERC20 is IUniswapV2ERC20 {                                                                                //
//        using SafeMath for uint;                                                                                                //
//                                                                                                                                //
//        string public constant name = 'Uniswap V2';                                                                             //
//        string public constant symbol = 'UNI-V2';                                                                               //
//        uint8 public constant decimals = 18;                                                                                    //
//        uint  public totalSupply;                                                                                               //
//        mapping(address => uint) public balanceOf;                                                                              //
//        mapping(address => mapping(address => uint)) public allowance;                                                          //
//                                                                                                                                //
//        bytes32 public DOMAIN_SEPARATOR;                                                                                        //
//        // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");                     //
//        bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;           //
//        mapping(address => uint) public nonces;                                                                                 //
//                                                                                                                                //
//        event Approval(address indexed owner, address indexed spender, uint value);                                             //
//        event Transfer(address indexed from, address indexed to, uint value);                                                   //
//                                                                                                                                //
//        constructor() public {                                                                                                  //
//            uint chainId;                                                                                                       //
//            assembly {                                                                                                          //
//                chainId := chainid                                                                                              //
//            }                                                                                                                   //
//            DOMAIN_SEPARATOR = keccak256(                                                                                       //
//                abi.encode(                                                                                                     //
//                    keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),            //
//                    keccak256(bytes(name)),                                                                                     //
//                    keccak256(bytes('1')),                                                                                      //
//                    chainId,                                                                                                    //
//                    address(this)                                                                                               //
//                )                                                                                                               //
//            );                                                                                                                  //
//        }                                                                                                                       //
//                                                                                                                                //
//        function _mint(address to, uint value) internal {                                                                       //
//            totalSupply = totalSupply.add(value);                                                                               //
//            balanceOf[to] = balanceOf[to].add(value);                                                                           //
//            emit Transfer(address(0), to, value);                                                                               //
//        }                                                                                                                       //
//                                                                                                                                //
//        function _burn(address from, uint value) internal {                                                                     //
//            balanceOf[from] = balanceOf[from].sub(value);                                                                       //
//            totalSupply = totalSupply.sub(value);                                                                               //
//            emit Transfer(from, address(0), value);                                                                             //
//        }                                                                                                                       //
//                                                                                                                                //
//        function _approve(address owner, address spender, uint value) private {                                                 //
//            allowance[owner][spender] = value;                                                                                  //
//            emit Approval(owner, spender, value);                                                                               //
//        }                                                                                                                       //
//                                                                                                                                //
//        function _transfer(address from, address to, uint value) private {                                                      //
//            balanceOf[from] = balanceOf[from].sub(value);                                                                       //
//            balanceOf[to] = balanceOf[to].add(value);                                                                           //
//            emit Transfer(from, to, value);                                                                                     //
//        }                                                                                                                       //
//                                                                                                                                //
//        function approve(address spender, uint value) external returns (bool) {                                                 //
//            _approve(msg.sender, spender, value);                                                                               //
//            return true;                                                                                                        //
//        }                                                                                                                       //
//                                                                                                                                //
//        function transfer(address to, uint value) external returns (bool) {                                                     //
//            _transfer(msg.sender, to, value);                                                                                   //
//            return true;                                                                                                        //
//        }                                                                                                                       //
//                                                                                                                                //
//        function transferFrom(address from, address to, uint value) external returns (bool) {                                   //
//            if (allowance[from][msg.sender] != uint(-1)) {                                                                      //
//                allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);                                           //
//            }                                                                                                                   //
//            _transfer(from, to, value);                                                                                         //
//            return true;                                                                                                        //
//        }                                                                                                                       //
//                                                                                                                                //
//        function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external {    //
//            require(deadline >= block.timestamp, 'UniswapV2: EXPIRED');                                                         //
//            bytes32 digest = keccak256(                                                                                         //
//                abi.encodePacked(                                                                                               //
//                    '\x19\x01',                                                                                                 //
//                    DOMAIN_SEPARATOR,                                                                                           //
//                    keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))                    //
//                )                                                                                                               //
//            );                                                                                                                  //
//            address recoveredAddress = ecrecover(digest, v, r, s);                                                              //
//            require(recoveredAddress != address(0) && recoveredAddress == owner, 'UniswapV2: INVALID_SIGNATURE');               //
//            _approve(owner, spender, value);                                                                                    //
//        }                                                                                                                       //
//    }                                                                                                                           //
//                                                                                                                                //
//    // File: contracts/libraries/Math.sol                                                                                       //
//                                                                                                                                //
//    pragma solidity =0.5.16;                                                                                                    //
//                                                                                                                                //
//    // a library for performing various math operations                                                                         //
//                                                                                                                                //
//    library Math {                                                                                                              //
//        function min(uint x, uint y) internal pure returns (uint z) {                                                           //
//            z = x < y ? x : y;                                                                                                  //
//        }                                                                                                                       //
//                                                                                                                                //
//        // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)                //
//        function sqrt(uint y) internal pure returns (uint z) {                                                                  //
//            if (y > 3) {                                                                                                        //
//                z = y;                                                                                                          //
//                uint x = y / 2 + 1;                                                                                             //
//                while (x < z) {                                                                                                 //
//                    z = x;                                                                                                      //
//                    x = (y / x + x) / 2;                                                                                        //
//                }                                                                                                               //
//            } else if (y != 0) {                                                                                                //
//                z = 1;                                                                                                          //
//            }                                                                                                                   //
//        }                                                                                                                       //
//    }                                                                                                                           //
//                                                                                                                                //
//    // File: contracts/libraries/UQ112x112.sol                                                                                  //
//                                                                                                                                //
//    pragma solidity =0.5.16;                                                                                                    //
//                                                                                                                                //
//    // a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))                      //
//                                                                                                                                //
//    // range: [0, 2**112 - 1]                                                                                                   //
//    // resolution: 1 / 2**112                                                                                                   //
//                                                                                                                                //
//    library UQ112x112 {                                                                                                         //
//        uint224 constant Q112 = 2**112;                                                                                         //
//                                                                                                                                //
//        // encode a uint112 as a UQ112x112                                                                                      //
//        function encode(uint112 y) internal pure returns (uint224 z) {                                                          //
//            z = uint224(y) * Q112; // never overflows                                                                           //
//        }                                                                                                                       //
//                                                                                                                                //
//        // divide a UQ112x112 by a uint112, returning a UQ112x112                                                               //
//        function uqdiv(uint224 x, uint112 y) internal pure returns (uint224 z) {                                                //
//            z = x / uint224(y);                                                                                                 //
//        }                                                                                                                       //
//    }                                                                                                                           //
//                                                                                                                                //
//    // File: contracts/interfaces/IERC20.sol                                                                                    //
//                                                                                                                                //
//    pragma solidity >=0.5.0;                                                                                                    //
//                                                                                                                                //
//    interface IERC20 {                                                                                                          //
//        event Approval(address indexed owner, address indexed spender, uint value);                                             //
//        event Transfer(address indexed from, address indexed to, uint value);                                                   //
//                                                                                                                                //
//        function name() external view returns (string memory);                                                                  //
//        function symbol() external view returns (string memory);                                                                //
//        function decimals() external view returns (uint8);                                                                      //
//        function totalSupply() external view returns (uint);                                                                    //
//        function balanceOf(address owner) external view returns (uint);                                                         //
//        function allowance(address owner, address spender) external view returns (uint);                                        //
//                                                                                                                                //
//        function approve(address spender, uint value) external returns (bool);                                                  //
//        function transfer(address to, uint value) external returns (bool);                                                      //
//        function transferFrom(address from, address to, uint value) external returns (bool);                                    //
//    }                                                                                                                           //
//                                                                                                                                //
//    // File: contracts/interfaces/IUniswapV2Factory.sol                                                                         //
//                                                                                                                                //
//    pragma solidity >=0.5.0;                                                                                                    //
//                                                                                                                                //
//    interface IUniswapV2Factory {                                                                                               //
//        event PairCreated(address indexed token0, address indexed token1, address pair, uint);                                  //
//                                                                                                                                //
//        function feeTo() external view returns (address);                                                                       //
//        function feeToSetter() external view returns (address);                                                                 //
//                                                                                                                                //
//        function getPair(address tokenA, address tokenB) external view returns (address pair);                                  //
//        function allPairs(uint) external view returns (address pair);                                                           //
//        function allPairsLength() external view returns (uint);                                                                 //
//                                                                                                                                //
//        function createPair(address tokenA, address tokenB) external returns (address pair);                                    //
//                                                                                                                                //
//        function setFeeTo(address) external;                                                                                    //
//        function setFeeToSetter(address) external;                                                                              //
//    }                                                                                                                           //
//                                                                                                                                //
//    // File: contracts/interfaces/IUniswapV2Callee.sol                                                                          //
//                                                                                                                                //
//    pragma solidity >=0.5.0;                                                                                                    //
//                                                                                                                                //
//    interface IUniswapV2Callee {                                                                                                //
//        function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external;                       //
//    }                                                                                                                           //
//                                                                                                                                //
//    // File: contracts/UniswapV2Pair.sol                                                                                        //
//                                                                                                                                //
//    pragma solidity =0.5.16;                                                                                                    //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//    contract UniswapV2Pair is IUniswapV2Pair, UniswapV2ERC20 {                                                                  //
//        using SafeMath  for uint;                                                                                               //
//        using UQ112x112 for uint224;                                                                                            //
//                                                                                                                                //
//        uint public constant MINIMUM_LIQUIDITY = 10**3;                                                                         //
//        bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));                               //
//                                                                                                                                //
//        address public factory;                                                                                                 //
//        address public token0;                                                                                                  //
//        address public token1;                                                                                                  //
//                                                                                                                                //
//        uint112 private reserve0;           // uses single storage slot, accessible via getReserves                             //
//        uint112 private reserve1;           // uses single storage slot, accessible via getReserves                             //
//        uint32  private blockTimestampLast; // uses single storage slot, accessible via getReserves                             //
//                                                                                                                                //
//        uint public price0CumulativeLast;                                                                                       //
//        uint public price1CumulativeLast;                                                                                       //
//        uint public kLast; // reserve0 * reserve1, as of immediately after the most recent liquidity event                      //
//                                                                                                                                //
//        uint private unlocked = 1;                                                                                              //
//        modifier lock() {                                                                                                       //
//            require(unlocked == 1, 'UniswapV2: LOCKED');                                                                        //
//            unlocked = 0;                                                                                                       //
//            _;                                                                                                                  //
//            unlocked = 1;                                                                                                       //
//        }                                                                                                                       //
//                                                                                                                                //
//        function getReserves() public view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) {         //
//            _reserve0 = reserve0;                                                                                               //
//            _reserve1 = reserve1;                                                                                               //
//            _blockTimestampLast = blockTimestampLast;                                                                           //
//        }                                                                                                                       //
//                                                                                                                                //
//        function _safeTransfer(address token, address to, uint value) private {                                                 //
//            (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));                        //
//            require(success && (data.length == 0 || abi.decode(data, (bool))), 'UniswapV2: TRANSFER_FAILED');                   //
//        }                                                                                                                       //
//                                                                                                                                //
//        event Mint(address indexed sender, uint amount0, uint amount1);                                                         //
//        event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);                                     //
//        event Swap(                                                                                                             //
//            address indexed sender,                                                                                             //
//            uint amount0In,                                                                                                     //
//            uint amount1In,                                                                                                     //
//            uint amount0Out,                                                                                                    //
//            uint amount1Out,                                                                                                    //
//            address indexed to                                                                                                  //
//        );                                                                                                                      //
//        event Sync(uint112 reserve0, uint112 reserve1);                                                                         //
//                                                                                                                                //
//        constructor() public {                                                                                                  //
//            factory = msg.sender;                                                                                               //
//        }                                                                                                                       //
//                                                                                                                                //
//        // called once by the factory at time of deployment                                                                     //
//        function initialize(address _token0, address _token1) external {                                                        //
//            require(msg.sender == factory, 'UniswapV2: FORBIDDEN'); // sufficient check                                         //
//            token0 = _token0;                                                                                                   //
//            token1 = _token1;                                                                                                   //
//        }                                                                                                                       //
//                                                                                                                                //
//        // update reserves and, on the first call per block, price accumulators                                                 //
//        function _update(uint balance0, uint balance1, uint112 _reserve0, uint112 _reserve1) private {                          //
//            require(balance0 <= uint112(-1) && balance1 <= uint112(-1), 'UniswapV2: OVERFLOW');                                 //
//            uint32 blockTimestamp = uint32(block.timestamp % 2**32);                                                            //
//            uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired                                    //
//            if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {                                                          //
//                // * never overflows, and + overflow is desired                                                                 //
//                price0CumulativeLast += uint(UQ112x112.encode(_reserve1).uqdiv(_reserve0)) * timeElapsed;                       //
//                price1CumulativeLast += uint(UQ112x112.encode(_reserve0).uqdiv(_reserve1)) * timeElapsed;                       //
//            }                                                                                                                   //
//            reserve0 = uint112(balance0);                                                                                       //
//            reserve1 = uint112(balance1);                                                                                       //
//            blockTimestampLast = blockTimestamp;                                                                                //
//            emit Sync(reserve0, reserve1);                                                                                      //
//        }                                                                                                                       //
//                                                                                                                                //
//        // if fee is on, mint liquidity equivalent to 1/6th of the growth in sqrt(k)                                            //
//        function _mintFee(uint112 _reserve0, uint112 _reserve1) private returns (bool feeOn) {                                  //
//            address feeTo = IUniswapV2Factory(factory).feeTo();                                                                 //
//            feeOn = feeTo != address(0);                                                                                        //
//            uint _kLast = kLast; // gas savings                                                                                 //
//            if (feeOn) {                                                                                                        //
//                if (_kLast != 0) {                                                                                              //
//                    uint rootK = Math.sqrt(uint(_reserve0).mul(_reserve1));                                                     //
//                    uint rootKLast = Math.sqrt(_kLast);                                                                         //
//                    if (rootK > rootKLast) {                                                                                    //
//                        uint numerator = totalSupply.mul(rootK.sub(rootKLast));                                                 //
//                        uint denominator = rootK.mul(5).add(rootKLast);                                                         //
//                        uint liquidity = numerator / denominator;                                                               //
//                        if (liquidity > 0) _mint(feeTo, liquidity);                                                             //
//                    }                                                                                                           //
//                }                                                                                                               //
//            } else if (_kLast != 0) {                                                                                           //
//                kLast = 0;                                                                                                      //
//            }                                                                                                                   //
//        }                                                                                                                       //
//                                                                                                                                //
//        // this low-level function should be called from a                                                                      //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract HOHOHO is ERC721Creator {
    constructor() ERC721Creator("WHO WHO", "HOHOHO") {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/proxy/Proxy.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";

contract ERC721Creator is Proxy {
    
    constructor(string memory name, string memory symbol) {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = 0xEB067AfFd7390f833eec76BF0C523Cf074a7713C;
        Address.functionDelegateCall(
            0xEB067AfFd7390f833eec76BF0C523Cf074a7713C,
            abi.encodeWithSignature("initialize(string,string)", name, symbol)
        );
    }
        
    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Returns the current implementation address.
     */
     function implementation() public view returns (address) {
        return _implementation();
    }

    function _implementation() internal override view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }    

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/Proxy.sol)

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overridden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overridden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}