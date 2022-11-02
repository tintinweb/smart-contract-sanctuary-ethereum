pragma solidity =0.5.16;

import "./NOVAProtocolV2Pair.sol";
import "./interfaces/INOVAProtocolFactory.sol";

contract NOVAProtocolV2Factory is INOVAProtocolFactory {
    address public feeTo;
    address public setter;
    address public boostToken;
    uint256 public boostSlotsRatio;
    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );
    constructor(address _setter) public {
        setter = _setter;
    }
    function allPairsLength() external view returns (uint256) {
        return allPairs.length;
    }
    /*function createPair(address tokenA, address tokenB)
        external
        returns (address pair)
    {
        require(tokenA != tokenB, "NOVAProtocol: IDENTICAL_ADDRESSES");
        (address token0, address token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        require(token0 != address(0), "NOVAProtocol: ZERO_ADDRESS");
        require(
            getPair[token0][token1] == address(0),
            "NOVAProtocol: PAIR_EXISTS"
        ); // single check is sufficient
        bytes memory bytecode = type(NOVAProtocolV2Pair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        INOVAProtocolPair(pair).initialize(token0, token1);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }*/
    function setFeeTo(address _feeTo) external {
        require(msg.sender == setter, "NOVAProtocol: FORBIDDEN");
        feeTo = _feeTo;
    }
    function setSetter(address _setter) external {
        require(msg.sender == setter, "NOVAProtocol: FORBIDDEN");
        setter = _setter;
    }
    function setBoostToken(address _boostToken) external {
        require(msg.sender == setter, "NOVAProtocol: FORBIDDEN");
        boostToken = _boostToken;
    }
    function setBoostSlotsRatio(uint256 _boostSlotsRatio) external {
        require(msg.sender == setter, "NOVAProtocol: FORBIDDEN");
        require(_boostSlotsRatio >= 75, "Ratio must be 75 at least");
        boostSlotsRatio = _boostSlotsRatio;
    }
    function set30daysPR(address _pair, uint256 _30daysPR) external { //Entra en tant per cent
        //S'ha d'arreglar aquest i el parell afectat
        require(msg.sender == setter, "NOVAProtocol: FORBIDDEN");
        bool _pairMatched = false;
        for (uint256 i = 0; i < allPairs.length && _pairMatched == false; i++) {
            if (allPairs[i] == _pair) {
                _pairMatched = true;
            }
        }
        require(_pairMatched == true, "Pair not found");
        INOVAProtocolPair(_pair).updateDays30PR(_30daysPR); //Entra en tant per cent
    }
    function setSwapFees(address _pair, uint256 _swapFees) external { //Entren en tant per cent
        //S'ha d'arreglar aquest i el parell afectat
        require(msg.sender == setter, "NOVAProtocol: FORBIDDEN");
        bool _pairMatched = false;
        for (uint256 i = 0; i < allPairs.length && _pairMatched == false; i++) {
            if (allPairs[i] == _pair) {
                _pairMatched = true;
            }
        }
        require(_pairMatched == true, "Pair not found");
        INOVAProtocolPair(_pair).updateSwapFees(_swapFees); //Es registren en tant per mil
    }
    function setTheraFees(address _pair, uint256 _theraFees) external { //Entren en tant per cent
        require(msg.sender == setter, "NOVAProtocol: FORBIDDEN");
        bool _pairMatched = false;
        for (uint256 i = 0; i < allPairs.length && _pairMatched == false; i++) {
            if (allPairs[i] == _pair) {
                _pairMatched = true;
            }
        }
        require(_pairMatched == true, "Pair not found");
        INOVAProtocolPair(_pair).updateTheraFees(_theraFees); //Es registren en tant per cent
    }
    function setRatioPublicPrivateFees(address _pair, uint256 _ratioPublicPrivateFees) external { //Entren en tant per cent
        require(msg.sender == setter, "NOVAProtocol: FORBIDDEN");
        bool _pairMatched = false;
        for (uint256 i = 0; i < allPairs.length && _pairMatched == false; i++) {
            if (allPairs[i] == _pair) {
                _pairMatched = true;
            }
        }
        require(_pairMatched == true, "Pair not found");
        INOVAProtocolPair(_pair).updateRatioPublicPrivateFees(_ratioPublicPrivateFees); //Es registren en tant per cent
    }
}

pragma solidity =0.5.16;

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

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.5.16;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeTransfer: transfer failed"
        );
    }
}

pragma solidity =0.5.16;

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

pragma solidity =0.5.16;

// a library for performing various math operations

library Math {
    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    function max(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x >= y ? x : y;
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

pragma solidity >=0.5.0;

interface INOVAProtocolPair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event ApprovalLBooster(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event TransferLBooster(
        address indexed from,
        address indexed to,
        uint256 value
    );

    function nameLBooster() external pure returns (string memory);

    function symbolLBooster() external pure returns (string memory);

    function decimalsLBooster() external pure returns (uint8);

    function totalSupplyLBooster() external view returns (uint256);

    function balanceOfLBooster(address owner) external view returns (uint256);

    function allowanceLBooster(address owner, address spender)
        external
        view
        returns (uint256);

    function lockTime(address owner) external view returns (uint256);

    function lBoosterAddress() external view returns (address);

    function approveLBooster(address spender, uint256 value)
        external
        returns (bool);

    function transferLBooster(address to, uint256 value)
        external
        returns (bool);

    function transferFromLBooster(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR_LBooster() external view returns (bytes32);

    function PERMIT_TYPEHASH_LBooster() external pure returns (bytes32);

    function nonces_LBooster(address owner) external view returns (uint256);

    function permitLBooster(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function lPAddress() external view returns (address);

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

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function days30PR() external view returns (uint112);

    function getBalances()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast,
            uint112 privateFees0,
            uint112 privateFees1
        );

    function getSlots()
        external
        view
        returns (uint112 liquiditySlots, uint112 fullSlots);

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    /*
    function mintLNOVA(
        address to,
        uint256 amountBooster,
        uint256 liquidity
    ) external;

    function burnLNOVA(uint256 amountlBooster, uint256 liquidity) external;
    */

    function skim(address to) external;

    function sync() external;

    function updateDays30PR(uint256) external;

    function updateSwapFees(uint256) external;

    function updateTheraFees(uint256) external;

    function updateRatioPublicPrivateFees(uint256) external;

    function updateLiquiditySlots() external;

    function quoteLiquidity()
        external
        view
        returns (uint112 liquidityQuote0, uint112 liquidityQuote1);

    function initialize(address, address) external;
}

pragma solidity >=0.5.0;

interface INOVAProtocolFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256); 
    function feeTo() external view returns (address);
    function setter() external view returns (address);
    function boostToken() external view returns (address);
    function boostSlotsRatio() external view returns (uint256);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint256) external view returns (address pair);
    function allPairsLength() external view returns (uint256);
    /*function createPair(address tokenA, address tokenB) external returns (address pair);*/
    function setFeeTo(address) external;
    function setSetter(address) external;
    function setBoostToken(address) external;
    function setBoostSlotsRatio(uint256) external;
    function set30daysPR(address, uint256) external;
    function setSwapFees(address, uint256) external;
    function setTheraFees(address, uint256) external;
    function setRatioPublicPrivateFees(address, uint256) external;
}

pragma solidity >=0.5.0;

interface INOVAProtocolERC20 {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

pragma solidity >=0.5.0;

interface INOVAProtocolCallee {
    function NOVAProtocolCall(address sender, uint amount0, uint amount1, bytes calldata data) external;
}

pragma solidity >=0.5.0;

interface ILOCKEDNOVAERC20 {
    event ApprovalLBooster(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event TransferLBooster(
        address indexed from,
        address indexed to,
        uint256 value
    );

    function nameLBooster() external pure returns (string memory);

    function symbolLBooster() external pure returns (string memory);

    function decimalsLBooster() external pure returns (uint8);

    function totalSupplyLBooster() external view returns (uint256);

    function balanceOfLBooster(address owner) external view returns (uint256);

    function allowanceLBooster(address owner, address spender)
        external
        view
        returns (uint256);

    function lockTime(address owner) external view returns (uint256);

    function lBoosterAddress() external view returns (address);

    function approveLBooster(address spender, uint256 value)
        external
        returns (bool);

    function transferLBooster(address to, uint256 value)
        external
        returns (bool);

    function transferFromLBooster(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR_LBooster() external view returns (bytes32);

    function PERMIT_TYPEHASH_LBooster() external pure returns (bytes32);

    function nonces_LBooster(address owner) external view returns (uint256);

    function permitLBooster(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

pragma solidity >=0.5.0;

interface IERC20 {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function lockTime(address owner) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

pragma solidity =0.5.16;

import "./NOVAProtocolV2ERC20.sol";
import "./LOCKEDNOVAERC20.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/INOVAProtocolCallee.sol";
import "./interfaces/INOVAProtocolFactory.sol";
import "./interfaces/INOVAProtocolPair.sol";
import "./libraries/Math.sol";
import "./libraries/TransferHelper.sol";
import "./libraries/UQ112x112.sol";

contract NOVAProtocolV2Pair is
    INOVAProtocolPair,
    NOVAProtocolV2ERC20,
    LOCKEDNOVAERC20
{
    using SafeMath for uint256;
    using UQ112x112 for uint224;

    uint256 public constant MINIMUM_LIQUIDITY = 10**3;
    bytes4 private constant SELECTOR =
        bytes4(keccak256(bytes("transfer(address,uint256)")));

    address public factory;
    address public token0;
    address public token1;
    //address public lBooster; //Pendent

    uint256 public days30PR=5; //Tant per cent

    uint256 public swapFees=3; //Tant per mil
    uint256 public theraFees=20; //Tant per cent;
    uint256 public ratioPublicPrivateFees=25; //Tant per cent

    uint112 private reserve0; // uses single storage slot, accessible via getBalances
    uint112 private reserve1; // uses single storage slot, accessible via getBalances
    uint32 private blockTimestampLast; // uses single storage slot, accessible via getBalances
    uint112 private privateFees0; // uses single storage slot, accessible via getBalances
    uint112 private privateFees1; // uses single storage slot, accessible via getBalances

    uint256[] private privateFeesTab0;
    uint256[] private privateFeesTab1;
    uint256 private lastPrivateFees0;
    uint256 private lastPrivateFees1;

    uint256 private day;
    //uint256 private date; //Pendent
    bool private ramp;

    uint112 public liquiditySlots;
    uint112 public fullSlots;

    uint256 public price0CumulativeLast;
    uint256 public price1CumulativeLast;
    uint256 public kLast; // reserve0 * reserve1, as of immediately after the most recent liquidity event

    uint256 private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, "NOVAProtocol: LOCKED");
        unlocked = 0;
        _;
        unlocked = 1;
    }

    function getBalances()
        public
        view
        returns (
            uint112 _reserve0,
            uint112 _reserve1,
            uint32 _blockTimestampLast,
            uint112 _privateFees0,
            uint112 _privateFees1
        )
    {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
        _privateFees0 = privateFees0;
        _privateFees1 = privateFees1;
    }

    function getSlots()
        public
        view
        returns (uint112 _liquiditySlots, uint112 _fullSlots)
    {
        _liquiditySlots = liquiditySlots;
        _fullSlots = fullSlots;
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
            "NOVAProtocol: TRANSFER_FAILED"
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
        require(msg.sender == factory, "NOVAProtocol: FORBIDDEN"); // sufficient check
        token0 = _token0;
        token1 = _token1;
    }

    // update reserves and private fees, on the first call per block, price accumulators
    function _update(
        uint256 balance0,
        uint256 balance1,
        uint112 _reserve0,
        uint112 _reserve1
    ) private {
        require(
            balance0 <= uint112(-1) && balance1 <= uint112(-1),
            "NOVAProtocol: OVERFLOW"
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
        if (balance0 > uint256(_reserve0) && balance1 < uint256(_reserve1)) { //Swap0
            privateFees0 = updatePrivateFees(balance0, _reserve0, privateFees0);
        } else if (balance1 > uint256(_reserve1) && balance0 < uint256(_reserve0)) { //Swap1
            privateFees1 = updatePrivateFees(balance1, _reserve1, privateFees1);
        }
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        blockTimestampLast = blockTimestamp;
        emit Sync(reserve0, reserve1);
    }

    function _mintFee(uint112 _reserve0, uint112 _reserve1)
        private
        returns (bool feeOn)
    {
        address feeTo = INOVAProtocolFactory(factory).feeTo();
        feeOn = feeTo != address(0);
        uint256 _kLast = kLast; // gas savings
        if (feeOn) {
            if (_kLast != 0) {
                uint256 rootK = Math.sqrt(uint256(_reserve0).mul(_reserve1));
                uint256 rootKLast = Math.sqrt(_kLast);
                if (rootK > rootKLast) {
                    uint256 numerator = totalSupply.mul(rootK.sub(rootKLast));
                    uint256 denominator = rootKLast.add(rootK.mul((1/theraFees).sub(1)));
                    uint256 liquidity = numerator / denominator;
                    if (liquidity > 0) _mint(feeTo, liquidity); //LP provided, not fees directly
                }
            }
        } else if (_kLast != 0) {
            kLast = 0;
        }
    }

    // this low-level function should be called from a contract which performs important safety checks
    function mint(address to) external lock returns (uint256 liquidity) {
        (
            uint112 _reserve0,
            uint112 _reserve1,
            ,
            uint112 _privateFees0,
            uint112 _privateFees1
        ) = getBalances(); // gas savings
        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));
        uint256 amount0 = balance0.sub(uint256(_reserve0));
        uint256 amount1 = balance1.sub(uint256(_reserve1));

        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint256 _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        if (_totalSupply == 0) {
            liquidity = Math.sqrt(amount0.mul(amount1)).sub(MINIMUM_LIQUIDITY);
            _mint(address(0), MINIMUM_LIQUIDITY); // permanently lock the first MINIMUM_LIQUIDITY tokens
        } else {
            liquidity = Math.min(
                amount0.mul(_totalSupply) /
                    uint256(_reserve0).sub(uint256(_privateFees0)),
                amount1.mul(_totalSupply) /
                    uint256(_reserve1).sub(uint256(_privateFees1))
            );
        }
        require(liquidity > 0, "NOVAProtocol: INSUFFICIENT_LIQUIDITY_MINTED");
        _mint(to, liquidity);
        _update(
            balance0,
            balance1,
            _reserve0,
            _reserve1
        );
        if (feeOn) kLast = uint256(reserve0).mul(uint256(reserve1)); // reserve0 and reserve1 are up-to-date
        emit Mint(msg.sender, amount0, amount1);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function burn(address to)
        external
        lock
        returns (uint256 amount0, uint256 amount1)
    {
        (
            uint112 _reserve0,
            uint112 _reserve1,
            ,
            uint112 _privateFees0,
            uint112 _privateFees1
        ) = getBalances(); // gas savings
        address _token0 = token0; // gas savings
        address _token1 = token1; // gas savings
        uint256 balance0 = IERC20(_token0).balanceOf(address(this));
        uint256 balance1 = IERC20(_token1).balanceOf(address(this));
        uint256 liquidity = balanceOf[address(this)];
        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint256 _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        amount0 =
            liquidity.mul(balance0.sub(uint256(_privateFees0))) /
            _totalSupply; // using balances ensures pro-rata distribution
        amount1 =
            liquidity.mul(balance1.sub(uint256(_privateFees1))) /
            _totalSupply; // using balances ensures pro-rata distribution
        require(
            amount0 > 0 && amount1 > 0,
            "NOVAProtocol: INSUFFICIENT_LIQUIDITY_BURNED"
        );
        _burn(address(this), liquidity);
        _safeTransfer(_token0, to, amount0);
        _safeTransfer(_token1, to, amount1);
        balance0 = IERC20(_token0).balanceOf(address(this));
        balance1 = IERC20(_token1).balanceOf(address(this));
        _update(
            balance0,
            balance1,
            _reserve0,
            _reserve1
        );
        if (feeOn) kLast = uint256(reserve0).mul(uint256(reserve1)); // reserve0 and reserve1 are up-to-date
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
            "NOVAProtocol: INSUFFICIENT_OUTPUT_AMOUNT"
        );
        (uint112 _reserve0, uint112 _reserve1, , , ) = getBalances(); // gas savings
        require(
            amount0Out < _reserve0 && amount1Out < _reserve1,
            "NOVAProtocol: INSUFFICIENT_LIQUIDITY"
        );
        uint256 balance0;
        uint256 balance1;
        {
            // scope for _token{0,1}, avoids stack too deep errors
            address _token0 = token0;
            address _token1 = token1;
            require(to != _token0 && to != _token1, "NOVAProtocol: INVALID_TO");
            if (amount0Out > 0) _safeTransfer(_token0, to, amount0Out); // optimistically transfer tokens
            if (amount1Out > 0) _safeTransfer(_token1, to, amount1Out); // optimistically transfer tokens
            if (data.length > 0)
                INOVAProtocolCallee(to).NOVAProtocolCall(
                    msg.sender,
                    amount0Out,
                    amount1Out,
                    data
                );
            balance0 = IERC20(_token0).balanceOf(address(this));
            balance1 = IERC20(_token1).balanceOf(address(this));
        }
        uint256 amount0In = balance0 > uint256(_reserve0) - amount0Out
            ? balance0 - (uint256(_reserve0) - amount0Out)
            : 0;
        uint256 amount1In = balance1 > uint256(_reserve1) - amount1Out
            ? balance1 - (uint256(_reserve1) - amount1Out)
            : 0;
        require(
            amount0In > 0 || amount1In > 0,
            "NOVAProtocol: INSUFFICIENT_INPUT_AMOUNT"
        );
        {
            // scope for reserve{0,1}Adjusted, avoids stack too deep errors
            uint256 balance0Adjusted = balance0.mul(1000).sub(amount0In.mul(swapFees));
            uint256 balance1Adjusted = balance1.mul(1000).sub(amount1In.mul(swapFees));
            require(
                balance0Adjusted.mul(balance1Adjusted) >=
                    uint256(_reserve0).mul(uint256(_reserve1)).mul(1000**2),
                "NOVAProtocol: K"
            );
        }

        _update(
            balance0,
            balance1,
            _reserve0,
            _reserve1
        );
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }

    function mintlNOVA(
        address to,
        uint256 amountBooster,
        uint256 liquidity
    ) external lock {
        require(liquidity > 0, "NOVAProtocol: INSUFFICIENT_LIQUIDITY_MINTED");
        _mintlNOVA(to, amountBooster);
        fullSlots = uint112(uint256(fullSlots).add(liquidity));
    }

    function burnlNOVA(uint256 lockedBooster, uint256 liquidity) public lock {
        require(liquidity > 0, "NOVAProtocol: INSUFFICIENT_LIQUIDITY_BURNED");
        _burnlNOVA(address(this), lockedBooster);
        fullSlots = uint112(uint256(fullSlots).sub(liquidity));
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
            //_privateFees0, PENDENT ACTUALITZAR UPDATE
            //_privateFees1 PENDENT ACTUALITZAR UPDATE
        );
    }

    function updateDays30PR(uint256 _days30PR) external lock {
        days30PR = _days30PR;
    }

    function updateSwapFees(uint256 _swapFees) external lock {
        swapFees = _swapFees;
    }

    function updateTheraFees(uint256 _theraFees) external lock {
        theraFees = _theraFees;
    }

    function updateRatioPublicPrivateFees(uint256 _ratioPublicPrivateFees) external lock {
        ratioPublicPrivateFees = _ratioPublicPrivateFees;
    }

    function updateLiquiditySlots() external lock {
        //Called on update Balances every day
        day++;
        (, , , uint256 _privateFees0, uint256 _privateFees1) = getBalances();
        (uint112 _liquidityQuote0, uint112 _liquidityQuote1) = quoteLiquidity();
        privateFeesTab0[day] = _privateFees0.sub(lastPrivateFees0);
        privateFeesTab1[day] = _privateFees1.sub(lastPrivateFees1);
        uint256 _days30Fees0;
        uint256 _days30Fees1;
        uint256 _liquiditySlots;
        for (uint256 i = 1; i <= 30; i++) {
            _days30Fees0 = _days30Fees0.add(privateFeesTab0[i]);
            _days30Fees1 = _days30Fees1.add(privateFeesTab1[i]);
        }
        if (ramp) {
            uint256 _30daysExpectedFees0 = _days30Fees0.mul(30) / day;
            uint256 _30daysExpectedFees1 = _days30Fees1.mul(30) / day;
            uint256 _dayRatio = (
                (INOVAProtocolFactory(factory).boostSlotsRatio()).sub(50)
            ).mul(day) / 3000;
            _liquiditySlots = Math.min(
                _30daysExpectedFees0.mul(_dayRatio) /
                    (days30PR/100).mul(_liquidityQuote0),
                _30daysExpectedFees1.mul(_dayRatio) /
                    (days30PR/100).mul(_liquidityQuote1)
            );
        } else {
            _liquiditySlots = Math.min(
                _days30Fees0.mul(
                    INOVAProtocolFactory(factory).boostSlotsRatio()
                ) / (days30PR/100).mul(_liquidityQuote0),
                _days30Fees1.mul(
                    INOVAProtocolFactory(factory).boostSlotsRatio()
                ) / (days30PR/100).mul(_liquidityQuote1)
            );
        }
        liquiditySlots = uint112(_liquiditySlots);
        lastPrivateFees0 = _privateFees0;
        lastPrivateFees1 = _privateFees1;
        if (day == 30) {
            day = 0;
            ramp = false;
        }
    }

    function quoteLiquidity()
        public
        view
        returns (uint112 liquidityQuote0, uint112 liquidityQuote1)
    {
        (uint112 _reserve0, uint112 _reserve1, , , ) = getBalances();
        uint112 _totalSupply = uint112(totalSupply);
        liquidityQuote0 = _reserve0 / _totalSupply;
        liquidityQuote1 = _reserve1 / _totalSupply;
    }

    function endBoosterTransfer(uint256 amountlBooster, address to) internal {
        (
            uint256 _reserve0,
            uint256 _reserve1,
            ,
            uint256 _privateFees0,
            uint256 _privateFees1
        ) = getBalances();
        uint256 gainedFees0 = amountlBooster.mul(_privateFees0) /
            totalSupplyLBooster;
        uint256 gainedFees1 = amountlBooster.mul(_privateFees1) /
            totalSupplyLBooster;
        uint256 liquidity = 100 * amountlBooster; //s'haurà d'ajustar el ratio quan es probi a testnet
        TransferHelper.safeTransfer(
            INOVAProtocolFactory(factory).boostToken(),
            to,
            amountlBooster
        );
        TransferHelper.safeTransfer(lPAddress, to, liquidity);
        TransferHelper.safeTransfer(token0, to, gainedFees0);
        TransferHelper.safeTransfer(token1, to, gainedFees1);
        reserve0 = uint112((_reserve0).sub(gainedFees0));
        reserve1 = uint112((_reserve1).sub(gainedFees1));
        privateFees0 = uint112((_privateFees0).sub(gainedFees0));
        privateFees1 = uint112((_privateFees1).sub(gainedFees1));
        burnlNOVA(amountlBooster, liquidity);
    }

    function updatePrivateFees (uint256 balance, uint256 _reserve, uint112 _privateFees) internal returns (uint112 privateFees) {
        uint256 i_max = Math.max(lockedAdressesA_i, lockedAdressesB_i);
        for (uint256 i = 0; i < i_max; i++) {
            autoEndBooster (lockedAdressesA[i], lockedBoosterA[i]);
            autoEndBooster (lockedAdressesB[i], lockedBoosterB[i]);
        }
        uint256 swapFee = (balance.sub(uint256(_reserve))).mul(swapFees) / 1000;
        privateFees = uint112(uint256(_privateFees).add(swapFee.mul(ratioPublicPrivateFees/100)));
    }

    function autoEndBooster (address lockedAddress, uint256 lockedBooster) internal {
        if (block.timestamp > lockTime[lockedAddress] && lockedAddress != address(0)) {
            endBoosterTransfer(lockedBooster, lockedAddress);
            lockedAddress = address(0);
        }
    }
    
}

pragma solidity =0.5.16;

import "./interfaces/INOVAProtocolERC20.sol";
import "./libraries/SafeMath.sol";

contract NOVAProtocolV2ERC20 is INOVAProtocolERC20 {
    using SafeMath for uint256;

    string public constant name = "NOVAProtocolLPV2";
    string public constant symbol = "NLPV2";
    uint8 public constant decimals = 18;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    address public lPAddress;

    bytes32 public DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH =
        0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint256) public nonces;

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor() public {
        uint256 chainId;
        assembly {
            chainId := chainid
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes(name)),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );
        lPAddress = address(this);
    }

    function _mint(address to, uint256 value) internal {
        totalSupply = totalSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint256 value) internal {
        totalSupply = totalSupply.sub(value);
        balanceOf[from] = balanceOf[from].sub(value);
        emit Transfer(from, address(0), value);
    }

    function _approve(
        address owner,
        address spender,
        uint256 value
    ) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(
        address from,
        address to,
        uint256 value
    ) private {
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint256 value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint256 value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool) {
        if (allowance[from][msg.sender] != uint256(-1)) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(
                value
            );
        }
        _transfer(from, to, value);
        return true;
    }

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(deadline >= block.timestamp, "NOVAProtocol: EXPIRED");
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        PERMIT_TYPEHASH,
                        owner,
                        spender,
                        value,
                        nonces[owner]++,
                        deadline
                    )
                )
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(
            recoveredAddress != address(0) && recoveredAddress == owner,
            "NOVAProtocol: INVALID_SIGNATURE"
        );
        _approve(owner, spender, value);
    }
}

pragma solidity =0.5.16;

import "./interfaces/ILOCKEDNOVAERC20.sol";
import "./libraries/SafeMath.sol";

contract LOCKEDNOVAERC20 is ILOCKEDNOVAERC20 {
    using SafeMath for uint256;

    string public constant nameLBooster = "LOCKED NOVA";
    string public constant symbolLBooster = "LNOVA";
    uint8 public constant decimalsLBooster = 18;
    uint256 public totalSupplyLBooster;
    mapping(address => uint256) public balanceOfLBooster;
    mapping(address => mapping(address => uint256)) public allowanceLBooster;

    mapping(address => uint256) public lockTime;
    address[] public lockedAdressesA;
    address[] public lockedAdressesB;
    uint256[] public lockedBoosterA;
    uint256[] public lockedBoosterB;
    uint256 lockedAdressesA_i;
    uint256 lockedAdressesB_i;
    bool activeA = true;

    address public lBoosterAddress;

    bytes32 public DOMAIN_SEPARATOR_LBooster;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH_LBooster =
        0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint256) public nonces_LBooster;

    event ApprovalLBooster(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event TransferLBooster(
        address indexed from,
        address indexed to,
        uint256 value
    );

    constructor() public {
        uint256 chainId;
        assembly {
            chainId := chainid
        }
        DOMAIN_SEPARATOR_LBooster = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes(nameLBooster)),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );
        lBoosterAddress = address(this);
    }

    function _mintlNOVA(address to, uint256 value) internal {
        totalSupplyLBooster = totalSupplyLBooster.add(value);
        balanceOfLBooster[to] = balanceOfLBooster[to].add(value);
        emit TransferLBooster(address(0), to, value);
    }

    function _burnlNOVA(address from, uint256 value) internal {
        totalSupplyLBooster = totalSupplyLBooster.sub(value);
        balanceOfLBooster[from] = balanceOfLBooster[from].sub(value);
        emit TransferLBooster(from, address(0), value);
    }

    function _approve(
        address owner,
        address spender,
        uint256 value
    ) private {
        allowanceLBooster[owner][spender] = value;
        emit ApprovalLBooster(owner, spender, value);
    }

    function _transfer(
        address from,
        address to,
        uint256 value
    ) private {
        balanceOfLBooster[from] = balanceOfLBooster[from].sub(value);
        balanceOfLBooster[to] = balanceOfLBooster[to].add(value);
        emit TransferLBooster(from, to, value);
    }

    function approveLBooster(address spender, uint256 value)
        external
        returns (bool)
    {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transferLBooster(address to, uint256 value)
        external
        returns (bool)
    {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFromLBooster(
        address from,
        address to,
        uint256 value
    ) external returns (bool) {
        if (allowanceLBooster[from][msg.sender] != uint256(-1)) {
            allowanceLBooster[from][msg.sender] = allowanceLBooster[from][
                msg.sender
            ].sub(value);
        }
        _transfer(from, to, value);
        return true;
    }

    function permitLBooster(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(deadline >= block.timestamp, "NOVAProtocol: EXPIRED");
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR_LBooster,
                keccak256(
                    abi.encode(
                        PERMIT_TYPEHASH_LBooster,
                        owner,
                        spender,
                        value,
                        nonces_LBooster[owner]++,
                        deadline
                    )
                )
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(
            recoveredAddress != address(0) && recoveredAddress == owner,
            "NOVAProtocol: INVALID_SIGNATURE"
        );
        _approve(owner, spender, value);
    }

    function updateTimeLock(address sender, uint256 amountBooster) external {
        lockTime[sender] = block.timestamp + 30 days;
        if (activeA) {
            if (lockedAdressesA_i == 0) {
                lockedAdressesB_i = 0;
            }
            lockedAdressesA_i++;
            lockedAdressesA[lockedAdressesA_i] = sender;
            lockedBoosterA[lockedAdressesA_i] = amountBooster;
        } else {
            if (lockedAdressesB_i == 0) {
                lockedAdressesA_i = 0;
            }
            lockedAdressesB_i++;
            lockedAdressesB[lockedAdressesB_i] = sender;
            lockedBoosterB[lockedAdressesB_i] = amountBooster;
        }
    }
}