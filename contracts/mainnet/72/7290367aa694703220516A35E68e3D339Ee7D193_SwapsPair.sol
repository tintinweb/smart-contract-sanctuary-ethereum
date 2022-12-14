// SPDX-License-Identifier: BCOM

pragma solidity =0.8.14;

import "./IERC20.sol";
import "./ISwapsFactory.sol";
import "./ISwapsCallee.sol";
import "./SwapsERC20.sol";

contract SwapsPair is SwapsERC20 {

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
            "SwapsPair: LOCKED"
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
            "SwapsPair: ALREADY_INITIALIZED"
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
            "SwapsPair: OVERFLOW"
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
            "SwapsPair: TRANSFER_FAILED"
        );
    }
}