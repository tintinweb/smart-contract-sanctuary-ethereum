/**
 *Submitted for verification at Etherscan.io on 2023-02-04
*/

/*
    Website: https://treschain.com
    Contract Name: Tres LP Factory 
    Instagram: https://www.instagram.com/treslecheschain
    Twitter: https://twitter.com/treslecheschain
    Telegram: https://t.me/Treschain
    Contract Version: 3.1

*/
//SPDX-License-Identifier: UNLICENSED


pragma solidity =0.8.18;

contract SwapsERC20 {

    string public constant name = "Tres Swap";
    string public constant symbol = "TRES-LP";
    uint8 public constant decimals = 18;

    address constant ZERO_ADDRESS = address(0);
    uint256 constant UINT256_MAX = type(uint256).max;

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => uint256) public nonces;

    bytes32 public immutable DOMAIN_SEPARATOR;
    bytes32 public constant PERMIT_TYPEHASH = keccak256(
        "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    constructor() {
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );
    }

    function _mint(
        address _to,
        uint256 _value
    )
        internal
    {
        totalSupply =
        totalSupply + _value;

        unchecked {
            balanceOf[_to] =
            balanceOf[_to] + _value;
        }

        emit Transfer(
            ZERO_ADDRESS,
            _to,
            _value
        );
    }

    function _burn(
        address _from,
        uint256 _value
    )
        internal
    {
        unchecked {
            totalSupply =
            totalSupply - _value;
        }

        balanceOf[_from] =
        balanceOf[_from] - _value;

        emit Transfer(
            _from,
            ZERO_ADDRESS,
            _value
        );
    }

    function _approve(
        address _owner,
        address _spender,
        uint256 _value
    )
        private
    {
        allowance[_owner][_spender] = _value;

        emit Approval(
            _owner,
            _spender,
            _value
        );
    }

    function _transfer(
        address _from,
        address _to,
        uint256 _value
    )
        private
    {
        balanceOf[_from] =
        balanceOf[_from] - _value;

        unchecked {
            balanceOf[_to] =
            balanceOf[_to] + _value;
        }

        emit Transfer(
            _from,
            _to,
            _value
        );
    }

    function approve(
        address _spender,
        uint256 _value
    )
        external
        returns (bool)
    {
        _approve(
            msg.sender,
            _spender,
            _value
        );

        return true;
    }

    function transfer(
        address _to,
        uint256 _value
    )
        external
        returns (bool)
    {
        _transfer(
            msg.sender,
            _to,
            _value
        );

        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
        external
        returns (bool)
    {
        if (allowance[_from][msg.sender] != UINT256_MAX) {
            allowance[_from][msg.sender] -= _value;
        }

        _transfer(
            _from,
            _to,
            _value
        );

        return true;
    }

    function permit(
        address _owner,
        address _spender,
        uint256 _value,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    )
        external
    {
        require(
            _deadline >= block.timestamp,
            "TresSwapsERC20: PERMIT_CALL_EXPIRED"
        );

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        PERMIT_TYPEHASH,
                        _owner,
                        _spender,
                        _value,
                        nonces[_owner]++,
                        _deadline
                    )
                )
            )
        );

        if (uint256(_s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            revert("TresSwapsERC20: INVALID_SIGNATURE");
        }

        address recoveredAddress = ecrecover(
            digest,
            _v,
            _r,
            _s
        );

        require(
            recoveredAddress != ZERO_ADDRESS &&
            recoveredAddress == _owner,
            "TresSwapsERC20: INVALID_SIGNATURE"
        );

        _approve(
            _owner,
            _spender,
            _value
        );
    }
}

// File: contracts/swap/ISwapsCallee.sol


interface ISwapsCallee {

    function swapsCall(
        address _sender,
        uint256 _amount0,
        uint256 _amount1,
        bytes calldata _data
    )
        external;
}

// File: contracts/swap/ISwapsFactory.sol


interface ISwapsFactory {

    function feeTo()
        external
        view
        returns (address);

    function feeToSetter()
        external
        view
        returns (address);

    function getPair(
        address _tokenA,
        address _tokenB
    )
        external
        view
        returns (address pair);

    function allPairs(uint256)
        external
        view
        returns (address pair);

    function allPairsLength()
        external
        view
        returns (uint256);

    function createPair(
        address _tokenA,
        address _tokenB
    )
        external
        returns (address pair);

    function setFeeTo(
        address
    )
        external;

    function setFeeToSetter(
        address
    )
        external;

    function cloneTarget()
        external
        view
        returns (address target);
}

// File: contracts/swap/IERC20.sol


interface IERC20 {

    function balanceOf(
        address _owner
    )
        external
        view
        returns (uint256);
}

// File: contracts/swap/SwapsPair.sol






contract TRESSwapPair is SwapsERC20 {

    uint224 constant Q112 = 2 ** 112;
    uint112 constant UINT112_MAX = type(uint112).max;
    uint256 public constant MINIMUM_LIQUIDITY = 10 ** 3;

    bytes4 private constant SELECTOR = bytes4(
        keccak256(bytes('transfer(address,uint256)'))
    );

    address public factory;
    address public token0;
    address public token1;

    uint112 private reserve0;
    uint112 private reserve1;
    uint32  private blockTimestampLast;

    uint256 public price0CumulativeLast;
    uint256 public price1CumulativeLast;

    uint256 public kLast;
    uint256 private unlocked;

    modifier lock() {
        require(
            unlocked == 1,
            "TRESSwapPair: LOCKED"
        );
        unlocked = 0;
        _;
        unlocked = 1;
    }

    event Mint(
        address indexed sender,
        uint256 amount0,
        uint256 amount1
    );

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

    event Sync(
        uint112 reserve0,
        uint112 reserve1
    );

    function initialize(
        address _token0,
        address _token1
    )
        external
    {
        require(
            factory == ZERO_ADDRESS,
            "TRESSwapPair: ALREADY_INITIALIZED"
        );

        token0 = _token0;
        token1 = _token1;
        factory = msg.sender;
        unlocked = 1;
    }

    function getReserves()
        public
        view
        returns (
            uint112,
            uint112,
            uint32
        )
    {
        return (
            reserve0,
            reserve1,
            blockTimestampLast
        );
    }

    function _update(
        uint256 _balance0,
        uint256 _balance1,
        uint112 _reserve0,
        uint112 _reserve1
    )
        private
    {
        require(
            _balance0 <= UINT112_MAX &&
            _balance1 <= UINT112_MAX,
            "TRESSwapPair: OVERFLOW"
        );

        uint32 blockTimestamp = uint32(block.timestamp % 2 ** 32);

        unchecked {
            uint32 timeElapsed = blockTimestamp - blockTimestampLast;
            if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
                price0CumulativeLast += uint256(uqdiv(encode(_reserve1), _reserve0)) * timeElapsed;
                price1CumulativeLast += uint256(uqdiv(encode(_reserve0), _reserve1)) * timeElapsed;
            }
        }

        reserve0 = uint112(_balance0);
        reserve1 = uint112(_balance1);

        blockTimestampLast = blockTimestamp;

        emit Sync(
            reserve0,
            reserve1
        );
    }

    function _mintFee(
        uint112 _reserve0,
        uint112 _reserve1,
        uint256 _kLast
    )
        private
    {
        if (_kLast == 0) return;

        uint256 rootK = sqrt(uint256(_reserve0) * _reserve1);
        uint256 rootKLast = sqrt(_kLast);

        if (rootK > rootKLast) {

            uint256 liquidity = totalSupply
                * (rootK - rootKLast)
                / (rootK * 5 + rootKLast);

            if (liquidity == 0) return;

            _mint(
                ISwapsFactory(factory).feeTo(),
                liquidity
            );
        }
    }

    function mint(
        address _to
    )
        external
        lock
        returns (uint256 liquidity)
    {
        (
            uint112 _reserve0,
            uint112 _reserve1,

        ) = getReserves();

        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));

        uint256 amount0 = balance0 - _reserve0;
        uint256 amount1 = balance1 - _reserve1;

        _mintFee(
            _reserve0,
            _reserve1,
            kLast
        );

        uint256 _totalSupply = totalSupply;

        if (_totalSupply == 0) {

            liquidity = sqrt(
                amount0 * amount1
            ) - MINIMUM_LIQUIDITY;

            _mint(
               ZERO_ADDRESS,
               MINIMUM_LIQUIDITY
            );

        } else {

            liquidity = min(
                amount0 * _totalSupply / _reserve0,
                amount1 * _totalSupply / _reserve1
            );
        }

        require(
            liquidity > 0,
            "INSUFFICIENT_LIQUIDITY_MINTED"
        );

        _mint(
            _to,
            liquidity
        );

        _update(
            balance0,
            balance1,
            _reserve0,
            _reserve1
        );

        kLast = uint256(reserve0) * reserve1;

        emit Mint(
            msg.sender,
            amount0,
            amount1
        );
    }

    function burn(
        address _to
    )
        external
        lock
        returns (
            uint256 amount0,
            uint256 amount1
        )
    {
        (
            uint112 _reserve0,
            uint112 _reserve1,

        ) = getReserves();

        address _token0 = token0;
        address _token1 = token1;

        uint256 balance0 = IERC20(_token0).balanceOf(address(this));
        uint256 balance1 = IERC20(_token1).balanceOf(address(this));

        uint256 liquidity = balanceOf[address(this)];

        _mintFee(
            _reserve0,
            _reserve1,
            kLast
        );

        uint256 _totalSupply = totalSupply;

        amount0 = liquidity * balance0 / _totalSupply;
        amount1 = liquidity * balance1 / _totalSupply;

        require(
            amount0 > 0 &&
            amount1 > 0,
            "INSUFFICIENT_LIQUIDITY_BURNED"
        );

        _burn(
            address(this),
            liquidity
        );

        _safeTransfer(
            _token0,
            _to,
            amount0
        );

        _safeTransfer(
            _token1,
            _to,
            amount1
        );

        balance0 = IERC20(_token0).balanceOf(address(this));
        balance1 = IERC20(_token1).balanceOf(address(this));

        _update(
            balance0,
            balance1,
            _reserve0,
            _reserve1
        );

        kLast = uint256(reserve0) * reserve1;

        emit Burn(
            msg.sender,
            amount0,
            amount1,
            _to
        );
    }

    function swap(
        uint256 _amount0Out,
        uint256 _amount1Out,
        address _to,
        bytes calldata _data
    )
        external
        lock
    {
        require(
            _amount0Out > 0 ||
            _amount1Out > 0,
            "INSUFFICIENT_OUTPUT_AMOUNT"
        );

        (
            uint112 _reserve0,
            uint112 _reserve1,

        ) = getReserves();

        require(
            _amount0Out < _reserve0 &&
            _amount1Out < _reserve1,
            "INSUFFICIENT_LIQUIDITY"
        );

        uint256 balance0;
        uint256 balance1;

        {
            address _token0 = token0;
            address _token1 = token1;

            if (_amount0Out > 0) _safeTransfer(_token0, _to, _amount0Out);
            if (_amount1Out > 0) _safeTransfer(_token1, _to, _amount1Out);

            if (_data.length > 0) ISwapsCallee(_to).swapsCall(
                msg.sender,
                _amount0Out,
                _amount1Out,
                _data
            );

            balance0 = IERC20(_token0).balanceOf(address(this));
            balance1 = IERC20(_token1).balanceOf(address(this));
        }

        uint256 _amount0In =
            balance0 > _reserve0 - _amount0Out ?
            balance0 - (_reserve0 - _amount0Out) : 0;

        uint256 _amount1In =
            balance1 > _reserve1 - _amount1Out ?
            balance1 - (_reserve1 - _amount1Out) : 0;

        require(
            _amount0In > 0 ||
            _amount1In > 0,
            "INSUFFICIENT_INPUT_AMOUNT"
        );

        {
            uint256 balance0Adjusted = balance0 * 1000 - (_amount0In * 3);
            uint256 balance1Adjusted = balance1 * 1000 - (_amount1In * 3);

            require(
                balance0Adjusted * balance1Adjusted >=
                uint256(_reserve0)
                    * _reserve1
                    * (1000 ** 2)
            );
        }

        _update(
            balance0,
            balance1,
            _reserve0,
            _reserve1
        );

        emit Swap(
            msg.sender,
            _amount0In,
            _amount1In,
            _amount0Out,
            _amount1Out,
            _to
        );
    }

    function skim()
        external
        lock
    {
        address _token0 = token0;
        address _token1 = token1;
        address _feesTo = ISwapsFactory(factory).feeTo();

        _safeTransfer(
            _token0,
            _feesTo,
            IERC20(_token0).balanceOf(address(this)) - reserve0
        );

        _safeTransfer(
            _token1,
            _feesTo,
            IERC20(_token1).balanceOf(address(this)) - reserve1
        );
    }

    function sync()
        external
        lock
    {
        _update(
            IERC20(token0).balanceOf(address(this)),
            IERC20(token1).balanceOf(address(this)),
            reserve0,
            reserve1
        );
    }

    function encode(
        uint112 _y
    )
        pure
        internal
        returns (uint224 z)
    {
        unchecked {
            z = uint224(_y) * Q112;
        }
    }

    function uqdiv(
        uint224 _x,
        uint112 _y
    )
        pure
        internal
        returns (uint224 z)
    {
        unchecked {
            z = _x / uint224(_y);
        }
    }

    function min(
        uint256 _x,
        uint256 _y
    )
        internal
        pure
        returns (uint256 z)
    {
        z = _x < _y ? _x : _y;
    }

    function sqrt(
        uint256 _y
    )
        internal
        pure
        returns (uint256 z)
    {
        unchecked {
            if (_y > 3) {
                z = _y;
                uint256 x = _y / 2 + 1;
                while (x < z) {
                    z = x;
                    x = (_y / x + x) / 2;
                }
            } else if (_y != 0) {
                z = 1;
            }
        }
    }

    function _safeTransfer(
        address _token,
        address _to,
        uint256 _value
    )
        internal
    {
        (bool success, bytes memory data) = _token.call(
            abi.encodeWithSelector(
                SELECTOR,
                _to,
                _value
            )
        );

        require(
            success && (
                data.length == 0 || abi.decode(
                    data, (bool)
                )
            ),
            "TRESSwapPair: TRANSFER_FAILED"
        );
    }
}

// File: contracts/swap/ISwapsERC20.sol


interface ISwapsERC20 {

    function name()
        external
        pure
        returns (string memory);

    function symbol()
        external
        pure
        returns (string memory);

    function decimals()
        external
        pure
        returns (uint8);

    function totalSupply()
        external
        view
        returns (uint256);

    function balanceOf(
        address _owner
    )
        external
        view
        returns (uint256);

    function allowance(
        address _owner,
        address _spender
    )
        external
        view
        returns (uint256);

    function approve(
        address _spender,
        uint256 _value
    )
        external
        returns (bool);

    function transfer(
        address _to,
        uint256 _value
    )
        external
        returns (bool);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
        external
        returns (bool);

    function DOMAIN_SEPARATOR()
        external
        view
        returns (bytes32);

    function PERMIT_TYPEHASH()
        external
        pure
        returns (bytes32);

    function nonces(
        address _owner
    )
        external
        view
        returns (uint256);

    function permit(
        address _owner,
        address _spender,
        uint256 _value,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    )
        external;
}

// File: contracts/swap/ISwapsPair.sol


interface ISwapsPair is ISwapsERC20 {

    function MINIMUM_LIQUIDITY()
        external
        pure
        returns (uint256);

    function factory()
        external
        view
        returns (address);

    function token0()
        external
        view
        returns (address);

    function token1()
        external
        view
        returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast()
        external
        view
        returns (uint256);

    function price1CumulativeLast()
        external
        view
        returns (uint256);

    function kLast()
        external
        view
        returns (uint256);

    function mint(
        address _to
    )
        external
        returns (uint256 liquidity);

    function burn(
        address _to
    )
        external
        returns (
            uint256 amount0,
            uint256 amount1
        );

    function swap(
        uint256 _amount0Out,
        uint256 _amount1Out,
        address _to,
        bytes calldata _data
    )
        external;

    function skim()
        external;

    function initialize(
        address,
        address
    )
        external;
}

// File: contracts/swap/SwapsFactory.sol


contract TRESSwapFactory {

    address public feeTo;
    address public feeToSetter;
    address public immutable cloneTarget;
    address constant ZERO_ADDRESS = address(0);

    address[] public allPairs;

    mapping(address => mapping(address => address)) public getPair;

    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    constructor(
        address _feeToSetter
    ) {
        if (_feeToSetter == ZERO_ADDRESS) {
            revert("TRESSwapFactory: INVALID_INPUT");
        }

        feeToSetter = _feeToSetter;
        feeTo = _feeToSetter;

        bytes32 salt;
        address pair;

        bytes memory bytecode = type(TRESSwapPair).creationCode;

        assembly {
            pair := create2(
                0,
                add(bytecode, 32),
                mload(bytecode),
                salt
            )
        }

        cloneTarget = pair;
    }

    function allPairsLength()
        external
        view
        returns (uint256)
    {
        return allPairs.length;
    }

    function createPair(
        address _tokenA,
        address _tokenB
    )
        external
        returns (address pair)
    {
        require(
            _tokenA != _tokenB,
            "TRESSwapFactory: IDENTICAL"
        );

        (address token0, address token1) = _tokenA < _tokenB
            ? (_tokenA, _tokenB)
            : (_tokenB, _tokenA);

        require(
            token0 != ZERO_ADDRESS,
            "TRESSwapFactory: ZERO_ADDRESS"
        );

        require(
            getPair[token0][token1] == ZERO_ADDRESS,
            "TRESSwapFactory: PAIR_ALREADY_EXISTS"
        );

        bytes32 salt = keccak256(
            abi.encodePacked(
                token0,
                token1
            )
        );

        bytes20 targetBytes = bytes20(
            cloneTarget
        );

        assembly {

            let clone := mload(0x40)

            mstore(
                clone,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )

            mstore(
                add(clone, 0x14),
                targetBytes
            )

            mstore(
                add(clone, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )

            pair := create2(0, clone, 0x37, salt)
        }

        ISwapsPair(pair).initialize(
            token0,
            token1
        );

        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair;

        allPairs.push(pair);

        emit PairCreated(
            token0,
            token1,
            pair,
            allPairs.length
        );
    }

    function setFeeTo(
        address _feeTo
    )
        external
    {
        require(
            msg.sender == feeToSetter,
            "TRESSwapFactory: FORBIDDEN"
        );

        require(
            _feeTo != ZERO_ADDRESS,
            "TRESSwapFactory: ZERO_ADDRESS"
        );

        feeTo = _feeTo;
    }

    function setFeeToSetter(
        address _feeToSetter
    )
        external
    {
        require(
            msg.sender == feeToSetter,
            "TRESSwapFactory: FORBIDDEN"
        );

        require(
            _feeToSetter != ZERO_ADDRESS,
            "TRESSwapFactory: ZERO_ADDRESS"
        );

        feeToSetter = _feeToSetter;
    }
}

contract FactoryCodeCheck {

    function factoryCodeHash()
        external
        pure
        returns (bytes32)
    {
        return keccak256(
            type(TRESSwapFactory).creationCode
        );
    }

    function pairCodeHash()
        external
        pure
        returns (bytes32)
    {
        return keccak256(
            type(TRESSwapPair).creationCode
        );
    }
}