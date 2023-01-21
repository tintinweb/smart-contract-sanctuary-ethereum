// SPDX-License-Identifier: MIT
//for auditability all custom code added ontop pancakeswap code is contained between /*************/ CODE /*************/

pragma solidity =0.5.16;

interface ICrossFactory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    /*************/
    function isPairDelisted(address _address) external view returns (bool);

    function isDAOAdmin(address _address) external view returns (bool);

    function killswitch() external;

    function changePairListingStatus(address _address, bool _value) external;

    function changeDexFeeStatus(
        address _address,
        address _pairAddress,
        uint256 _amount
    ) external;

    function dexFee(address _address, address _pairAddress)
        external
        view
        returns (uint256);

    function isTradingHalted() external view returns (bool);

    function canSwap(address _address) external view returns (bool);

    /*************/

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

interface ICrossPair {
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

    /*************/
    function CRSSPricecheckStatus(
        bool _isActive0,
        bool _isActive1,
        bool _isActiveL
    ) external;

    /*************/
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

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

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

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

interface ICrossERC20 {
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
}

contract CrossERC20 is ICrossERC20 {
    using SafeMath for uint256;

    string public constant name = "Cross LPs";
    string public constant symbol = "Cross-LP";
    uint8 public constant decimals = 18;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

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
    }

    function _mint(address to, uint256 value) internal {
        totalSupply = totalSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint256 value) internal {
        balanceOf[from] = balanceOf[from].sub(value);
        totalSupply = totalSupply.sub(value);
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
        require(deadline >= block.timestamp, "Cross: EXPIRED");
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
            "Cross: INVALID_SIGNATURE"
        );
        _approve(owner, spender, value);
    }
}

// a library for performing various math operations
library Math {
    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
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

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

interface ICrossCallee {
    function CrossCall(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;
}

/*************/
interface IControlCenter {
    function _getCLPoolValue(
        address token0,
        address token1,
        uint256 balance0,
        uint256 balance1
    ) external view returns (uint256 poolValue0, uint256 deviation0);

    function _getStateVariables()
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    function _updateSession() external;
}

/*************/
contract CrossPair is ICrossPair, CrossERC20 {
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
    /*************/
    mapping(address => bool) public s_whitelisted;
    uint256 public currentSessionRatio;
    uint256 public currentSessionLPValue;

    //Session global variables + CC
    address public controlCenter = 0x38d4aE07376eb7261008f9B5f19E6A7C0bE935D0;
    bool private liquidityGuardActive;
    bool private crossPriceCheckActive;
    bool private chainlinkPriceCheckActive;
    uint256 public liqMaxPercentageChange;

    /*************/
    uint256 public price0CumulativeLast;
    uint256 public price1CumulativeLast;
    uint256 public kLast; // reserve0 * reserve1, as of immediately after the most recent liquidity event
    uint256 private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, "Cross: LOCKED");
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
            "Cross: TRANSFER_FAILED"
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
    /****** */
    event AddressFeeExclusionUpdated(address target, bool value);

    modifier onlyControlCenter() {
        require(msg.sender == controlCenter, "Only control center");
        _;
    }

    /****** */
    constructor() public {
        factory = msg.sender;
    }

    // called once by the factory at time of deployment
    function initialize(address _token0, address _token1) external {
        require(msg.sender == factory, "Cross: FORBIDDEN"); // sufficient check
        token0 = _token0;
        token1 = _token1;
        crossPriceCheckActive = true;
    }

    // update reserves and, on the first call per block, price accumulators
    function _update(
        uint256 balance0,
        uint256 balance1,
        uint112 _reserve0,
        uint112 _reserve1
    ) private {
        require(
            balance0 <= uint112(-1) && balance1 <= uint112(-1),
            "Cross: OVERFLOW"
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

    // if fee is on, mint liquidity equivalent to 8/25 of the growth in sqrt(k)
    function _mintFee(uint112 _reserve0, uint112 _reserve1)
        private
        returns (bool feeOn)
    {
        address feeTo = ICrossFactory(factory).feeTo();
        feeOn = feeTo != address(0);
        uint256 _kLast = kLast; // gas savings
        if (feeOn) {
            if (_kLast != 0) {
                uint256 rootK = Math.sqrt(uint256(_reserve0).mul(_reserve1));
                uint256 rootKLast = Math.sqrt(_kLast);
                if (rootK > rootKLast) {
                    uint256 numerator = totalSupply
                        .mul(rootK.sub(rootKLast))
                        .mul(8);
                    uint256 denominator = rootK.mul(17).add(rootKLast.mul(8));
                    uint256 liquidity = numerator / denominator;
                    if (liquidity > 0) _mint(feeTo, liquidity);
                }
            }
        } else if (_kLast != 0) {
            kLast = 0;
        }
    }

    /* function _mintFee1(uint112 _reserve0, uint112 _reserve1)
        private
        returns (bool feeOn)
    {
        address feeTo = IUniswapV2Factory(factory).feeTo();
        feeOn = feeTo != address(0);
        uint256 _kLast = kLast; // gas savings
        if (feeOn) {
            if (_kLast != 0) {
                uint256 rootK = Math.sqrt(uint256(_reserve0).mul(_reserve1));
                uint256 rootKLast = Math.sqrt(_kLast);
                if (rootK > rootKLast) {
                    uint256 numerator = totalSupply.mul(rootK.sub(rootKLast));
                    uint256 denominator = rootK.mul(5).add(rootKLast);
                    uint256 liquidity = numerator / denominator;
                    if (liquidity > 0) _mint(feeTo, liquidity);
                }
            }
        } else if (_kLast != 0) {
            kLast = 0;
        }
    }*/

    // this low-level function should be called from a contract which performs important safety checks
    function mint(address to) external lock returns (uint256 liquidity) {
        require(
            ICrossFactory(factory).isPairDelisted(address(this)) != true,
            "Cross:Pair delisted"
        );
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
        require(liquidity > 0, "Cross: INSUFFICIENT_LIQUIDITY_MINTED");
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
            "Cross: INSUFFICIENT_LIQUIDITY_BURNED"
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
        /*************/

        require(
            ICrossFactory(factory).canSwap(address(this)),
            "Pair unlisted or trading is halted"
        );
        /*************/
        require(
            amount0Out > 0 || amount1Out > 0,
            "Cross: INSUFFICIENT_OUTPUT_AMOUNT"
        );
        (uint112 _reserve0, uint112 _reserve1, ) = getReserves(); // gas savings
        require(
            amount0Out < _reserve0 && amount1Out < _reserve1,
            "Cross: INSUFFICIENT_LIQUIDITY"
        );

        uint256 balance0;
        uint256 balance1;
        {
            // scope for _token{0,1}, avoids stack too deep errors
            address _token0 = token0;
            address _token1 = token1;
            require(to != _token0 && to != _token1, "Cross: INVALID_TO");
            if (amount0Out > 0) _safeTransfer(_token0, to, amount0Out); // optimistically transfer tokens
            if (amount1Out > 0) _safeTransfer(_token1, to, amount1Out); // optimistically transfer tokens
            if (data.length > 0)
                ICrossCallee(to).CrossCall(
                    msg.sender,
                    amount0Out,
                    amount1Out,
                    data
                );
            balance0 = IERC20(_token0).balanceOf(address(this));
            balance1 = IERC20(_token1).balanceOf(address(this));
        }

        /*************  */
        //had to change sequence and calc amountIns manually to avoid 'stack too deep' error
        emit Swap(
            msg.sender,
            balance0 > _reserve0 - amount0Out
                ? balance0 - (_reserve0 - amount0Out)
                : 0,
            balance1 > _reserve1 - amount1Out
                ? balance1 - (_reserve1 - amount1Out)
                : 0,
            amount0Out,
            amount1Out,
            to
        );
        /*************/
        uint256 amount0In = balance0 > _reserve0 - amount0Out
            ? balance0 - (_reserve0 - amount0Out)
            : 0;
        uint256 amount1In = balance1 > _reserve1 - amount1Out
            ? balance1 - (_reserve1 - amount1Out)
            : 0;

        require(
            amount0In > 0 || amount1In > 0,
            "Pancake: INSUFFICIENT_INPUT_AMOUNT"
        );
        /*************/
        uint256 userFee = ICrossFactory(factory).dexFee(
            tx.origin,
            address(this)
        );
        if (userFee == 10000) {
            // scope for reserve{0,1}Adjusted, avoids stack too deep errors
            {
                require(
                    balance0.mul(balance1) >=
                        uint256(_reserve0).mul(uint256(_reserve1)),
                    "Pancake: K"
                );
            }
            /* _update(balance0, balance1, _reserve0, _reserve1);
            emit Swap(
                msg.sender,
                amount0In,
                amount1In,
                amount0Out,
                amount1Out,
                to
            );

            return;*/
        } else {
            {
                uint256 adjustedFee = userFee == 0 ? 25 : userFee;
                //balance0Adjusted = balance0 - (amount0In*adjustedFee)
                // scope for reserve{0,1}Adjusted, avoids stack too deep errors
                uint256 balance0Adjusted = (
                    balance0.mul(10000).sub(amount0In.mul(adjustedFee))
                );
                uint256 balance1Adjusted = (
                    balance1.mul(10000).sub(amount1In.mul(adjustedFee))
                );
                require(
                    balance0Adjusted.mul(balance1Adjusted) >=
                        uint256(_reserve0).mul(_reserve1).mul(10000**2),
                    "Pancake: K"
                );
            }
            {
                //this will update once per session length in a random swap that occurs in any of the pairs within the protocol
                IControlCenter(controlCenter)._updateSession();
                //creates another scope to avoid stack too deep errors

                //from here we fetch global modifiable variables required by the two different price checks
                //the variables need to be stored and updated in a separate contract in order not to exceed contract's max state variable limit and
                //standardize price checks and session througout the DEX

                (
                    uint256 maxSessionPriceChange,
                    uint256 maxSessionLPValueChange,
                    uint256 currentSessionTimestamp
                ) = IControlCenter(controlCenter)._getStateVariables();
                //for testing
                // require(maxSessionPriceChange != 0 && maxSessionLPValueChange != 0);

                if (crossPriceCheckActive == true) {
                    uint256 currentTokenRatio = ((balance0 + amount0In) *
                        10**18) / (balance1 + amount1In);
                    //this is where the last session token pool ratio is recorded based on its corresponding session timestamp

                    //measures current ratio against saved ratio of current session, fails if current ratio deviates from the original more than allowed
                    uint256 maxSessionChange = (currentSessionRatio *
                        maxSessionPriceChange) / 10000;
                    //compare current pool token ratio to saved ratio of current session
                    require(
                        currentSessionRatio - maxSessionChange <=
                            currentTokenRatio &&
                            currentTokenRatio <=
                            currentSessionRatio + maxSessionChange,
                        "Cross:Token ratio out of range"
                    );
                    if (currentSessionTimestamp == block.timestamp) {
                        currentSessionRatio = currentTokenRatio;
                    }
                }

                if (chainlinkPriceCheckActive == true) {
                    (
                        uint256 poolValue,
                        uint256 chainlinkPriceDeviation
                    ) = IControlCenter(controlCenter)._getCLPoolValue(
                            token0,
                            token1,
                            balance0 - amount0In,
                            balance1 - amount1In
                        );
                    //continues only if one of the tokens has a registered and functioning CL proxy
                    if (poolValue > 0) {
                        //updates session LP value if new session has begun
                        if (currentSessionTimestamp == block.timestamp) {
                            currentSessionLPValue = poolValue;
                        }
                        //accounts for recorded CL price deviations
                        uint256 maxPoolValueRange = (poolValue *
                            chainlinkPriceDeviation) / 10000;

                        uint256 maxPoolValueChange = maxPoolValueRange +
                            (currentSessionLPValue * maxSessionLPValueChange) /
                            10000;
                        require(
                            currentSessionLPValue - maxPoolValueChange <=
                                poolValue &&
                                poolValue <=
                                currentSessionLPValue + maxPoolValueChange,
                            "Cross:CLToken ratio out of range"
                        );
                    }
                }
            }
        }
        /*************/
        _update(balance0, balance1, _reserve0, _reserve1);
    }

    /*************/
    // this low-level function should be called from a contract which performs important safety checks
    /* function safeSwap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external lock {
        /*************/
    /*uint256 partnerFee = ICrossFactory(factory).dexFee(
            tx.origin,
            address(this)
        );*/
    /* require(
            ICrossFactory(factory).dexFee(tx.origin, address(this)) > 0 ||
                ICrossFactory(factory).isDAOAdmin(tx.origin) == true,
            "CRSS:Restricted access"
        );
        /*************/
    /*
        require(
            amount0Out > 0 || amount1Out > 0,
            "Pancake: INSUFFICIENT_OUTPUT_AMOUNT"
        );
        (uint112 _reserve0, uint112 _reserve1, ) = getReserves(); // gas savings
        require(
            amount0Out < _reserve0 && amount1Out < _reserve1,
            "Pancake: INSUFFICIENT_LIQUIDITY"
        );

        uint256 balance0;
        uint256 balance1;
        {
            // scope for _token{0,1}, avoids stack too deep errors
            address _token0 = token0;
            address _token1 = token1;
            require(to != _token0 && to != _token1, "Pancake: INVALID_TO");
            if (amount0Out > 0) _safeTransfer(_token0, to, amount0Out); // optimistically transfer tokens
            if (amount1Out > 0) _safeTransfer(_token1, to, amount1Out); // optimistically transfer tokens
            if (data.length > 0)
                ICrossCallee(to).CrossCall(
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
            "Pancake: INSUFFICIENT_INPUT_AMOUNT"
        );
        /****** */
    /*

        uint256 userFee = ICrossFactory(factory).dexFee(
            tx.origin,
            address(this)
        );
        uint256 adjustedFee = userFee == 0 ? 25 : userFee;
        {
            // scope for reserve{0,1}Adjusted, avoids stack too deep errors
            uint256 balance0Adjusted = (
                balance0.mul(10000).sub(amount0In.mul(adjustedFee))
            );
            uint256 balance1Adjusted = (
                balance1.mul(10000).sub(amount1In.mul(adjustedFee))
            );
            require(
                balance0Adjusted.mul(balance1Adjusted) >=
                    uint256(_reserve0).mul(_reserve1).mul(10000**2),
                "Pancake: K"
            );
        } /*************/

    /*     _update(balance0, balance1, _reserve0, _reserve1);
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }*/

    /*************/
    //restricted for owner only, ideally governed by a DAO voting mechanism
    function CRSSPricecheckStatus(
        bool _isActive0,
        bool _isActive1,
        bool _isActiveL
    ) external onlyControlCenter {
        crossPriceCheckActive = _isActive0;
        chainlinkPriceCheckActive = _isActive1;
        liquidityGuardActive = _isActiveL;
    }

    /*************/
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

contract CrossFactory is ICrossFactory {
    bytes32 public constant INIT_CODE_PAIR_HASH =
        keccak256(abi.encodePacked(type(CrossPair).creationCode));

    /*************/
    mapping(address => bool) public DAOAdmin;
    mapping(address => bool) private delistedPair;
    mapping(address => mapping(address => uint256)) public partnerDexFee;
    bool private tradingHalted;
    /*************/
    address public feeTo;
    address public feeToSetter;
    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;

    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );
    /*************/
    event TradingHalted(uint256 timestamp);
    event TradingResumed(uint256 timestamp);

    /*************/
    constructor(address _feeToSetter) public {
        feeToSetter = _feeToSetter;
    }

    /*************/
    function isPairDelisted(address _address) public view returns (bool) {
        return delistedPair[_address];
    }

    function canSwap(address _address) public view returns (bool) {
        return !delistedPair[_address] && !tradingHalted;
    }

    function isDAOAdmin(address _address) public view returns (bool) {
        return DAOAdmin[_address];
    }

    function changePairListingStatus(address _address, bool _value) external {
        require(msg.sender == feeToSetter);
        delistedPair[_address] = _value;
    }

    function changeBotExclusionStatus(address _address, bool _value) external {
        require(msg.sender == feeToSetter);
        DAOAdmin[_address] = _value;
    }

    function changeDexFeeStatus(
        address _address,
        address _pairAddress,
        uint256 _amount
    ) public {
        require(msg.sender == feeToSetter);
        partnerDexFee[_pairAddress][_address] = _amount;
    }

    function dexFee(address _address, address _pairAddress)
        public
        view
        returns (uint256)
    {
        return partnerDexFee[_pairAddress][_address];
    }

    /*************/
    function allPairsLength() external view returns (uint256) {
        return allPairs.length;
    }

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair)
    {
        require(msg.sender == feeToSetter);
        require(tokenA != tokenB, "Cross: IDENTICAL_ADDRESSES");
        (address token0, address token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        require(token0 != address(0), "Cross: ZERO_ADDRESS");
        require(getPair[token0][token1] == address(0), "Cross: PAIR_EXISTS"); // single check is sufficient
        bytes memory bytecode = type(CrossPair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        /*************/
        require(delistedPair[pair] != true, "Cross: UNLISTED_TOKEN");
        /*************/
        ICrossPair(pair).initialize(token0, token1);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function setFeeTo(address _feeTo) external {
        require(msg.sender == feeToSetter, "Cross: FORBIDDEN");
        feeTo = _feeTo;
    }

    function setFeeToSetter(address _feeToSetter) external {
        require(msg.sender == feeToSetter, "Cross: FORBIDDEN");
        feeToSetter = _feeToSetter;
    }

    /*************/
    function killswitch() public {
        require(msg.sender == feeToSetter, "sCRSS:Only control center");
        bool isHalted = tradingHalted;
        if (isHalted == false) {
            isHalted = true;
            emit TradingHalted(block.timestamp);
        } else {
            isHalted = false;
            emit TradingResumed(block.timestamp);
        }
    }

    function isTradingHalted() public view returns (bool) {
        return tradingHalted;
    }
    /*************/
}