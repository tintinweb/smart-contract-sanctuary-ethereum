// SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;

/**
 * Standard SafeMath, stripped down to just add/sub/mul/div
 */
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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: APPROVE_FAILED");
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: TRANSFER_FAILED");
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: TRANSFER_FROM_FAILED");
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, "TransferHelper: ETH_TRANSFER_FAILED");
    }
}

interface IDEXPair {
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

interface IDEXFactory {
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

interface IDEXRouter {
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

/**
 * BEP20 standard interface.
 */
interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IWBNB {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

/**
 * Provides ownable & authorized contexts
 */
abstract contract KlardaAuth {
    address owner;
    mapping (address => bool) private authorizations;

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }

    /**
     * Function modifier to require caller to be contract owner
     */
    modifier onlyOwner() {
        require(isOwner(msg.sender)); _;
    }

    /**
     * Function modifier to require caller to be authorized
     */
    modifier authorized() {
        require(isAuthorized(msg.sender)); _;
    }

    /**
     * Authorize address. Any authorized address
     */
    function authorize(address adr) public authorized {
        authorizations[adr] = true;
        emit Authorized(adr);
    }

    /**
     * Remove address' authorization. Owner only
     */
    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
        emit Unauthorized(adr);
    }

    /**
     * Check if address is owner
     */
    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    /**
     * Return address' authorization status
     */
    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    /**
     * Transfer ownership to new address. Caller must be owner.
     */
    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
    event Authorized(address adr);
    event Unauthorized(address adr);
}

contract KlardaAggregator_ETH is KlardaAuth {
    using SafeMath for uint;

    struct DEX {
        string name;
        address factory;
        address router;
        bytes32 initHash;
        uint256 fee;
        bool enabled;
    }

    address private weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address private usdt =  0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address private usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    mapping (uint256 => DEX) public dexList;
    uint256 public dexCount;

    mapping (address => uint256) baseTokenIndex;
    address[] public baseTokens;

    constructor() KlardaAuth(msg.sender) {
        dexList[dexCount++] = DEX({
        name: "Uniswap V2",
        factory: 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f,
        router: 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D,
        initHash: hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f',
        fee: 9980,
        enabled: true
        });

        dexList[dexCount++] = DEX({
        name: "Sushiswap",
        factory: 0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac,
        router: 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F,
        initHash: hex'e18a34eb0e04b04f7a0ac29a6e80748dca96319b42c54d679cb821dca90c6303',
        fee: 9980,
        enabled: true
        });
    }

    function addDex(string memory name, address factory, address router, bytes32 initHash, uint256 fee) external authorized {
        dexList[dexCount++] = DEX({
        name: name,
        factory: factory,
        router: router,
        initHash: initHash,
        fee: fee,
        enabled: true
        });
    }

    function setDEXEnabled(uint256 dexID, bool enabled) external authorized {
        dexList[dexID].enabled = enabled;
    }

    function getBaseTokens() external view returns (address[] memory){
        return baseTokens;
    }

    function addBaseToken(address token) external authorized {
        baseTokenIndex[token] = baseTokens.length;
        baseTokens.push(token);
    }

    function removeBaseToken(address token) external authorized {
        baseTokens[baseTokenIndex[token]] = baseTokens[baseTokens.length - 1];
        baseTokenIndex[baseTokens[baseTokenIndex[token]]] = baseTokenIndex[token];
        baseTokens.pop();
    }

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) public pure returns (address token0, address token1) {
        require(tokenA != tokenB, "KlardaDEXUtils: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "KlardaDEXUtils: ZERO_ADDRESS");
    }

    // calculates the CREATE2 address for a pancakeswap v1 pair without making any external calls
    function pairFor(uint256 dexID, address tokenA, address tokenB) public view returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                dexList[dexID].factory,
                keccak256(abi.encodePacked(token0, token1)),
                dexList[dexID].initHash // init code hash
            ))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(uint256 dexID, address tokenA, address tokenB) public view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        pairFor(dexID, tokenA, tokenB);
        uint256 balanceA = IBEP20(tokenA).balanceOf(pairFor(dexID, tokenA, tokenB));
        uint256 balanceB = IBEP20(tokenB).balanceOf(pairFor(dexID, tokenA, tokenB));
        if (balanceA == 0 && balanceB == 0) {
            (reserveA, reserveB) = (0, 0);
        } else {
            (uint reserve0, uint reserve1,) = IDEXPair(pairFor(dexID, tokenA, tokenB)).getReserves();
            (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);            
        }
    }

    function getETHPrice() public view returns (uint256 _ethPrice) {
        // get reserves 
        (uint256 reserveETH, uint256 reserveUSDT) = getReserves(0, weth, usdt);
        _ethPrice = (reserveUSDT/10**6)/(reserveETH/10**18);
    }

    function calculateTotalLPValue(address token) public view returns (uint256 lpValue) {      
        lpValue = 0;

        for(uint256 i=0; i<dexCount; i++){
            if(!dexList[i].enabled){ continue; }
            address nextFactory = dexList[i].factory;

            for(uint256 n=0; n<baseTokens.length; n++) {
                address nextPair = IDEXFactory(nextFactory).getPair(token, baseTokens[n]);
                if(nextPair != address(0)) {
                    if (n == 0) {
                        uint256 bnbAmount = IBEP20(weth).balanceOf(nextPair);
                        lpValue += bnbAmount*getETHPrice()*2;
                    } else {
                        uint256 tokenAmount = IBEP20(baseTokens[n]).balanceOf(nextPair);
                        lpValue += tokenAmount*2*10**12;                        
                    }
                }
            }
        }
    }
}