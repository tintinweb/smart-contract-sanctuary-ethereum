// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.13;

import './interfaces/IAmmalgamFactory.sol';
import './AmmalgamPair.sol';

contract AmmalgamFactory is IAmmalgamFactory, IAmmalgamFactoryCallback {
    address public feeTo;
    address public feeToSetter;

    struct Tokens {
        address tokenX;
        address tokenY;
    }

    Tokens public override tokens;

    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;

    constructor(address _feeToSetter) {
        feeToSetter = _feeToSetter;
    }

    function allPairsLength() external view returns (uint256) {
        return allPairs.length;
    }

    function createPair(address tokenA, address tokenB) external returns (address pair) {
        require(tokenA != tokenB, 'Ammalgam: IDENTICAL_ADDRESSES');
        (address tokenX, address tokenY) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(tokenX != address(0), 'Ammalgam: ZERO_ADDRESS');
        require(getPair[tokenX][tokenY] == address(0), 'Ammalgam: PAIR_EXISTS'); // single check is sufficient
        bytes memory bytecode = type(AmmalgamPair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(tokenX, tokenY));

        tokens = Tokens({tokenX: tokenX, tokenY: tokenY});
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        delete tokens;

        getPair[tokenX][tokenY] = pair;
        getPair[tokenY][tokenX] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(tokenX, tokenY, pair, allPairs.length);
    }

    function setFeeTo(address _feeTo) external {
        require(msg.sender == feeToSetter, 'Ammalgam: FORBIDDEN');
        feeTo = _feeTo;
    }

    function setFeeToSetter(address _feeToSetter) external {
        require(msg.sender == feeToSetter, 'Ammalgam: FORBIDDEN');
        feeToSetter = _feeToSetter;
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.5.0;

interface IAmmalgamFactory {
    event PairCreated(address indexed tokenX, address indexed tokenY, address pair, uint256);

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.13;

import './interfaces/IAmmalgamPair.sol';
import './AmmalgamERC1155.sol';
import './libraries/Math.sol';
import './libraries/UQ112x112.sol';
import './interfaces/IERC20.sol';
import './interfaces/IAmmalgamFactory.sol';
import './interfaces/IAmmalgamCallee.sol';
import './interfaces/IAmmalgamFactoryCallback.sol';

contract AmmalgamPair is IAmmalgamPair, AmmalgamERC1155, IERC1155Receiver {
    using UQ112x112 for uint224;

    uint256 public constant TOKEN_ID_LIQUIDITY = 1;
    uint256 public constant TOKEN_ID_DEPOSIT_X = 2;
    uint256 public constant TOKEN_ID_DEPOSIT_Y = 3;
    uint256 public constant TOKEN_ID_BORROW_X = 4;
    uint256 public constant TOKEN_ID_BORROW_Y = 5;
    uint256 public constant TOKEN_ID_BORROW_L = 6;
    uint256 public constant MINIMUM_LIQUIDITY = 10**3;
    bytes4 private constant TRANSFER = bytes4(keccak256(bytes('transfer(address,uint256)')));
    bytes4 private constant TRANSFER_FROM = bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));

    address public immutable factory;
    address public immutable tokenX;
    address public immutable tokenY;

    uint112 private reserveX; // uses single storage slot, accessible via getReserves
    uint112 private reserveY; // uses single storage slot, accessible via getReserves
    uint32 private blockTimestampLast; // uses single storage slot, accessible via getReserves

    uint112 private depositX;
    uint112 private depositY;

    uint112 private borrowX;
    uint112 private borrowY;

    uint256 public priceXCumulativeLast;
    uint256 public priceYCumulativeLast;
    uint256 public kLast; // reserveX * reserveY, as of immediately after the most recent liquidity event

    uint256 private unlocked = 1;

    modifier lock() {
        require(unlocked == 1, 'Ammalgam: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    constructor() AmmalgamERC1155('AmmURI.example') {
        factory = msg.sender;
        (tokenX, tokenY) = IAmmalgamFactoryCallback(msg.sender).tokens();
    }

    // this low-level function should be called from a contract which performs important safety checks
    function mint(address to) external lock returns (uint256 liquidity) {
        (uint112 _reserveX, uint112 _reserveY, ) = getReserves(); // gas savings

        uint256 balanceX = IERC20(tokenX).balanceOf(address(this)) - depositX + borrowX;
        uint256 balanceY = IERC20(tokenY).balanceOf(address(this)) - depositY + borrowY;

        uint256 amountX = balanceX - _reserveX;
        uint256 amountY = balanceY - _reserveY;

        bool feeOn = _mintFee(_reserveX, _reserveY);
        uint256 _totalSupply = totalSupply(TOKEN_ID_LIQUIDITY); // gas savings, must be defined here since totalSupply can update in _mintFee
        if (_totalSupply == 0) {
            liquidity = Math.sqrt(amountX * amountY) - MINIMUM_LIQUIDITY;
            _mint(address(0), TOKEN_ID_LIQUIDITY, MINIMUM_LIQUIDITY, ''); // permanently lock the first MINIMUM_LIQUIDITY tokens
        } else {
            uint256 totalSupplyAdj = _totalSupply - totalSupply(TOKEN_ID_BORROW_L);
            liquidity = Math.min((amountX * totalSupplyAdj) / _reserveX, (amountY * totalSupplyAdj) / _reserveY);
        }
        require(liquidity > 0, 'Ammalgam: INSUFFICIENT_LIQUIDITY_MINTED');
        _mint(to, TOKEN_ID_LIQUIDITY, liquidity, '');

        _update(balanceX, balanceY, _reserveX, _reserveY);
        if (feeOn) kLast = uint256(reserveX) * uint256(reserveY); // reserveX and reserveY are up-to-date
        emit Mint(msg.sender, amountX, amountY);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function burn(address to) external lock returns (uint256 amountX, uint256 amountY) {
        validateDebt();
        (uint112 _reserveX, uint112 _reserveY, ) = getReserves(); // gas savings
        address _tokenX = tokenX; // gas savings
        address _tokenY = tokenY; // gas savings
        uint112 _depositX = depositX;
        uint112 _depositY = depositY;
        uint112 _borrowX = borrowX;
        uint112 _borrowY = borrowY;
        uint256 balanceX;
        uint256 balanceY;
        bool feeOn;

        {
            // scope for _borrowX and _borrowY to avoids stack too deep errors
            balanceX = IERC20(_tokenX).balanceOf(address(this)) - _depositX + _borrowX;
            balanceY = IERC20(_tokenY).balanceOf(address(this)) - _depositY + _borrowY;
            uint256 liquidity = balanceOf(address(this), TOKEN_ID_LIQUIDITY);

            feeOn = _mintFee(_reserveX, _reserveY);
            // gas savings, must be defined here since totalSupply can update in _mintFee
            uint256 totalSupplyAdj = totalSupply(TOKEN_ID_LIQUIDITY) - totalSupply(TOKEN_ID_BORROW_L);
            amountX = (liquidity * balanceX) / totalSupplyAdj; // using balances ensures pro-rata distribution
            amountY = (liquidity * balanceY) / totalSupplyAdj; // using balances ensures pro-rata distribution
            require(amountX > 0 && amountY > 0, 'Ammalgam: INSUFFICIENT_LIQUIDITY_BURNED');

            _burn(address(this), TOKEN_ID_LIQUIDITY, liquidity);
        }

        _safeTransfer(_tokenX, to, amountX);
        _safeTransfer(_tokenY, to, amountY);
        balanceX = IERC20(_tokenX).balanceOf(address(this)) - _depositX + _borrowX;
        balanceY = IERC20(_tokenY).balanceOf(address(this)) - _depositY + _borrowY;

        _update(balanceX, balanceY, _reserveX, _reserveY);
        if (feeOn) kLast = uint256(reserveX) * uint256(reserveY); // reserveX and reserveY are up-to-date
        emit Burn(msg.sender, amountX, amountY, to);
    }

    // borrow x and y
    function borrow(
        address onBehalfOf,
        uint256 amountX,
        uint256 amountY
    ) external lock {
        validateBorrowXY(onBehalfOf, amountX, amountY);

        if (amountX > 0) {
            _mint(onBehalfOf, TOKEN_ID_BORROW_X, amountX, '');
            borrowX += uint112(amountX);
            _safeTransfer(tokenX, msg.sender, amountX);
        }
        if (amountY > 0) {
            _mint(onBehalfOf, TOKEN_ID_BORROW_Y, amountY, '');
            borrowY += uint112(amountY);
            _safeTransfer(tokenY, msg.sender, amountY);
        }
    }

    function borrowLiquidity(address onBehalfOf, uint256 borrowAmountL) external lock returns (uint256, uint256) {
        require(onBehalfOf == msg.sender, 'Ammalgam: Invalid onBehalfOf');

        (uint112 _reserveX, uint112 _reserveY, ) = getReserves();

        uint256 totalSupplyAdj = totalSupply(TOKEN_ID_LIQUIDITY) - totalSupply(TOKEN_ID_BORROW_L);

        validateBorrowLiquidity(onBehalfOf, borrowAmountL, totalSupplyAdj, _reserveX, _reserveY);

        _mint(onBehalfOf, TOKEN_ID_BORROW_L, borrowAmountL, '');

        // calculate borrowedLx and borrowedLy based on the reserves
        uint256 borrowedLx = (borrowAmountL * _reserveX) / totalSupplyAdj;
        uint256 borrowedLy = (borrowAmountL * _reserveY) / totalSupplyAdj;
        _safeTransfer(tokenX, msg.sender, borrowedLx);
        _safeTransfer(tokenY, msg.sender, borrowedLy);

        // Reserves are updated to reflect the borrowed L that can no longer be used for trading.
        _update(_reserveX - borrowedLx, _reserveY - borrowedLy, _reserveX, _reserveY);

        return (borrowedLx, borrowedLy);
    }

    /**
        withdraw X and/or Y
    */
    function withdraw(
        address to,
        uint256 amountX,
        uint256 amountY
    ) external lock {
        // do not need to check whether amountX/Y <= balanceX/Y
        // because there's duplicated checks in ERC1155 _burn()

        validateDebt();

        if (amountX > 0) {
            _burn(msg.sender, TOKEN_ID_DEPOSIT_X, amountX);
            depositX -= uint112(amountX);
            _safeTransfer(tokenX, to, amountX);
        }
        if (amountY > 0) {
            _burn(msg.sender, TOKEN_ID_DEPOSIT_Y, amountY);
            depositY -= uint112(amountY);
            _safeTransfer(tokenY, to, amountY);
        }

        emit Withdraw(to, amountX, amountY);
    }

    function deposit(address to) external lock {
        (uint256 amountX, uint256 amountY) = getNetAmounts();

        require(amountX <= type(uint112).max && amountY <= type(uint112).max, 'Ammalgam: Deposit Overflow');

        if (amountX > 0) {
            _mint(to, TOKEN_ID_DEPOSIT_X, amountX, '');
            depositX += uint112(amountX);
        }
        if (amountY > 0) {
            _mint(to, TOKEN_ID_DEPOSIT_Y, amountY, '');
            depositY += uint112(amountY);
        }
        emit Deposit(msg.sender, amountX, amountY);
    }

    function repay(address onBehalfOf) public lock {
        validateRepay(onBehalfOf);
        (uint256 amountX, uint256 amountY) = getNetAmounts();

        if (amountX > 0) {
            _burn(onBehalfOf, TOKEN_ID_BORROW_X, amountX);
            borrowX -= uint112(amountX);
        }

        if (amountY > 0) {
            _burn(onBehalfOf, TOKEN_ID_BORROW_Y, amountY);
            borrowY -= uint112(amountY);
        }
    }

    function repayLiquidity(address onBehalfOf)
        public
        lock
        returns (
            uint256 amountX,
            uint256 amountY,
            uint256 repayAmountL
        )
    {
        validateRepayLiquidity(onBehalfOf);

        (amountX, amountY) = getNetAmounts();

        (uint112 _reserveX, uint112 _reserveY, ) = getReserves();

        uint256 totalSupplyAdj = totalSupply(TOKEN_ID_LIQUIDITY) - totalSupply(TOKEN_ID_BORROW_L);

        // round up one
        repayAmountL = Math.min(
            Math.ceilDiv((amountX * totalSupplyAdj), _reserveX),
            Math.ceilDiv((amountY * totalSupplyAdj), _reserveY)
        );

        require(repayAmountL > 0, 'Ammalgam: INSUFFICIENT_REPAY_LIQUIDITY');

        if (repayAmountL > balanceOf(onBehalfOf, TOKEN_ID_BORROW_L)) {
            repayAmountL = balanceOf(onBehalfOf, TOKEN_ID_BORROW_L);
        }

        _burn(onBehalfOf, TOKEN_ID_BORROW_L, repayAmountL);

        // Reserves are updated to reflect the repaid L.
        _update(_reserveX + amountX, _reserveY + amountY, _reserveX, _reserveY);

        emit RepayLiquidity(msg.sender, onBehalfOf, amountX, amountY);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function swap(
        uint256 amountXOut,
        uint256 amountYOut,
        address to,
        bytes calldata data
    ) external lock {
        require(amountXOut > 0 || amountYOut > 0, 'Ammalgam: INSUFFICIENT_OUTPUT_AMOUNT');
        (uint112 _reserveX, uint112 _reserveY, ) = getReserves(); // gas savings
        require(amountXOut < _reserveX && amountYOut < _reserveY, 'Ammalgam: INSUFFICIENT_LIQUIDITY');
        uint256 balanceX;
        uint256 balanceY;

        {
            // scope for _token{0,1}, avoids stack too deep errors
            address _tokenX = tokenX;
            address _tokenY = tokenY;

            require(to != _tokenX && to != _tokenY, 'Ammalgam: INVALID_TO');
            if (amountXOut > 0) _safeTransfer(_tokenX, to, amountXOut); // optimistically transfer tokens
            if (amountYOut > 0) _safeTransfer(_tokenY, to, amountYOut); // optimistically transfer tokens
            if (data.length > 0) IAmmalgamCallee(to).swapCall(msg.sender, amountXOut, amountYOut, data);

            balanceX = IERC20(_tokenX).balanceOf(address(this)) - depositX + borrowX;
            balanceY = IERC20(_tokenY).balanceOf(address(this)) - depositY + borrowY;
        }

        uint256 amountXIn = balanceX > _reserveX - amountXOut ? balanceX - (_reserveX - amountXOut) : 0;
        uint256 amountYIn = balanceY > _reserveY - amountYOut ? balanceY - (_reserveY - amountYOut) : 0;

        require(amountXIn > 0 || amountYIn > 0, 'Ammalgam: INSUFFICIENT_INPUT_AMOUNT');
        {
            // scope for reserve{0,1}Adjusted, avoids stack too deep errors
            uint256 balanceXAdjusted = balanceX * 1000 - amountXIn * 3;
            uint256 balanceYAdjusted = balanceY * 1000 - amountYIn * 3;
            require(
                //after swap K should be >= K before swap
                balanceXAdjusted * balanceYAdjusted >= uint256(_reserveX) * uint256(_reserveY) * 1000**2,
                'Ammalgam: K'
            );
        }

        _update(balanceX, balanceY, _reserveX, _reserveY);
        emit Swap(msg.sender, amountXIn, amountYIn, amountXOut, amountYOut, to);
    }

    // force balances to match reserves
    function skim(address to) external lock {
        address _tokenX = tokenX; // gas savings
        address _tokenY = tokenY; // gas savings

        _safeTransfer(_tokenX, to, IERC20(_tokenX).balanceOf(address(this)) - depositX + borrowX - reserveX);
        _safeTransfer(_tokenY, to, IERC20(_tokenY).balanceOf(address(this)) - depositY + borrowY - reserveY);
    }

    // force reserves to match balances
    function sync() external lock {
        _update(
            IERC20(tokenX).balanceOf(address(this)) - depositX + borrowX,
            IERC20(tokenY).balanceOf(address(this)) - depositY + borrowY,
            reserveX,
            reserveY
        );
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    /**
     * @dev Total amount of tokens in with a given id.
     */
    function totalSupply(uint256 id) public view virtual override(IAmmalgamERC1155, ERC1155Supply) returns (uint256) {
        return super.totalSupply(id);
    }

    function getReserves()
        public
        view
        returns (
            uint112 _reserveX,
            uint112 _reserveY,
            uint32 _blockTimestampLast
        )
    {
        _reserveX = reserveX;
        _reserveY = reserveY;
        _blockTimestampLast = blockTimestampLast;
    }

    function _safeTransfer(
        address token,
        address to,
        uint256 value
    ) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(TRANSFER, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'Ammalgam: TRANSFER_FAILED');
    }

    function _safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(TRANSFER_FROM, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'Ammalgam: TRANSFER_FAILED_FROM');
    }

    // update reserves and, on the first call per block, price accumulators
    function _update(
        uint256 balanceX,
        uint256 balanceY,
        uint112 _reserveX,
        uint112 _reserveY
    ) private {
        require(balanceX <= type(uint112).max && balanceY <= type(uint112).max, 'Ammalgam: OVERFLOW');
        uint32 blockTimestamp = uint32(block.timestamp % 2**32);
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired
        if (timeElapsed > 0 && _reserveX != 0 && _reserveY != 0) {
            // * never overflows, and + overflow is desired
            priceXCumulativeLast += uint256(UQ112x112.encode(_reserveY).uqdiv(_reserveX)) * timeElapsed;
            priceYCumulativeLast += uint256(UQ112x112.encode(_reserveX).uqdiv(_reserveY)) * timeElapsed;
        }
        reserveX = uint112(balanceX);
        reserveY = uint112(balanceY);
        blockTimestampLast = blockTimestamp;
        emit Sync(reserveX, reserveY);
    }

    // if fee is on, mint liquidity equivalent to 1/6th of the growth in sqrt(k)
    function _mintFee(uint112 _reserveX, uint112 _reserveY) private returns (bool feeOn) {
        address feeTo = IAmmalgamFactory(factory).feeTo();
        feeOn = feeTo != address(0);
        uint256 _kLast = kLast; // gas savings
        if (feeOn) {
            if (_kLast != 0) {
                uint256 rootK = Math.sqrt(uint256(_reserveX) * uint256(_reserveY));
                uint256 rootKLast = Math.sqrt(_kLast);
                if (rootK > rootKLast) {
                    uint256 numerator = totalSupply(TOKEN_ID_LIQUIDITY) * (rootK - rootKLast);
                    uint256 denominator = rootK * 5 + rootKLast;
                    uint256 liquidity = numerator / denominator;
                    if (liquidity > 0) _mint(feeTo, TOKEN_ID_LIQUIDITY, liquidity, '');
                }
            }
        } else if (_kLast != 0) {
            kLast = 0;
        }
    }

    function getNetAmounts() private view returns (uint256 amountX, uint256 amountY) {
        uint256 balanceX = IERC20(tokenX).balanceOf(address(this)) - depositX + borrowX;
        uint256 balanceY = IERC20(tokenY).balanceOf(address(this)) - depositY + borrowY;

        amountX = balanceX - reserveX;
        amountY = balanceY - reserveY;
    }

    //todo: to deal with more complicated scenarios
    function validateDebt() private view {
        require(
            balanceOf(msg.sender, TOKEN_ID_BORROW_X) == 0 &&
                balanceOf(msg.sender, TOKEN_ID_BORROW_Y) == 0 &&
                balanceOf(msg.sender, TOKEN_ID_BORROW_L) == 0,
            'Ammalgam: Debt has not been repaid'
        );
    }

    function validateBorrowXY(
        address onBehalfOf,
        uint256 borrowAmountX,
        uint256 borrowAmountY
    ) private view {
        uint256 _totalSupply = totalSupply(TOKEN_ID_LIQUIDITY);
        (uint112 _reserveX, uint112 _reserveY, ) = getReserves();
        uint256 borrowInX = borrowAmountX + ((borrowAmountY * _reserveX) / _reserveY);
        validateBorrow(onBehalfOf, borrowInX, _reserveX, _reserveY, _totalSupply);
    }

    function validateBorrowLiquidity(
        address onBehalfOf,
        uint256 borrowAmountL,
        uint256 _totalSupply,
        uint112 _reserveX,
        uint112 _reserveY
    ) private view {
        uint256 borrowLx = (borrowAmountL * _reserveX) / _totalSupply;
        uint256 borrowLy = (borrowAmountL * _reserveY) / _totalSupply;
        uint256 borrowValueInX = borrowLx + ((borrowLy * _reserveX) / _reserveY);
        validateBorrow(onBehalfOf, borrowValueInX, _reserveX, _reserveY, _totalSupply);
    }

    function validateBorrow(
        address onBehalfOf,
        uint256 borrowAmountInX,
        uint256 _reserveX,
        uint256 _reserveY,
        uint256 _totalSupply
    ) private view {
        require(onBehalfOf == msg.sender, 'Ammalgam: Invalid onBehalfOf');

        uint256 _depositX = balanceOf(onBehalfOf, TOKEN_ID_DEPOSIT_X);
        uint256 _depositY = balanceOf(onBehalfOf, TOKEN_ID_DEPOSIT_Y);
        uint256 depositL = balanceOf(onBehalfOf, TOKEN_ID_LIQUIDITY);

        uint256 depositLx = (depositL * _reserveX) / _totalSupply;
        uint256 depositLy = (depositL * _reserveY) / _totalSupply;

        uint256 depositInX = _depositX +
            ((_depositY * _reserveX) / _reserveY) +
            depositLx +
            ((depositLy * _reserveX) / _reserveY);

        bool validated = false;
        validated = (depositInX > borrowAmountInX);
        require(validated, 'Ammalgam: Insufficient deposit');
    }

    function validateRepay(address onBehalfOf) private view {
        require(onBehalfOf == msg.sender, 'Ammalgam: Invalid onBehalfOf');
    }

    function validateRepayLiquidity(address onBehalfOf) private view {
        require(onBehalfOf == msg.sender, 'Ammalgam: Invalid onBehalfOf');
        require(balanceOf(onBehalfOf, TOKEN_ID_BORROW_L) > 0, 'Ammalgam: No debt needs repay');
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.8.13;

import './IAmmalgamERC1155.sol';

interface IAmmalgamPair is IAmmalgamERC1155 {
    event Mint(address indexed sender, uint256 amountX, uint256 amountY);
    event Burn(address indexed sender, uint256 amountX, uint256 amountY, address indexed to);
    event Deposit(address indexed sender, uint256 amountX, uint256 amountY);
    event Withdraw(address indexed sender, uint256 amountX, uint256 amountY);
    event Swap(
        address indexed sender,
        uint256 amountXIn,
        uint256 amountYIn,
        uint256 amountXOut,
        uint256 amountYOut,
        address indexed to
    );
    event Sync(uint112 reserveX, uint112 reserveY);

    event RepayLiquidity(address indexed sender, address indexed onBehalfOf, uint256 amountLx, uint256 amountLy);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function tokenX() external view returns (address);

    function tokenY() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserveX,
            uint112 reserveY,
            uint32 blockTimestampLast
        );

    function priceXCumulativeLast() external view returns (uint256);

    function priceYCumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to) external returns (uint256 amountX, uint256 amountY);

    function borrow(
        address onBehalfOf,
        uint256 amountX,
        uint256 amountY
    ) external;

    function borrowLiquidity(address onBehalfOf, uint256 borrowAmountL) external returns (uint256, uint256);

    function withdraw(
        address to,
        uint256 _amountX,
        uint256 _amountY
    ) external;

    function deposit(address to) external;

    function swap(
        uint256 amountXOut,
        uint256 amountYOut,
        address to,
        bytes calldata data
    ) external;

    function repay(address onBehalfOf) external;

    function repayLiquidity(address onBehalfOf)
        external
        returns (
            uint256 amountX,
            uint256 amountY,
            uint256 repayAmountL
        );

    function skim(address to) external;

    function sync() external;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.13;

import '@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol';
import '@openzeppelin/contracts/token/ERC1155/ERC1155.sol';

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract AmmalgamERC1155 is ERC1155, ERC1155Supply {
    constructor(string memory uri) ERC1155(uri) {}

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.13;

// a library for performing various math operations

library Math {
    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        unchecked { // designed to be used with pragma solidity =0.5.16 prior to safe math getting added
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

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }    
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.13;

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

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.5.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.5.0;

interface IAmmalgamCallee {
    function swapCall(
        address sender,
        uint256 amountX,
        uint256 amountY,
        bytes calldata data
    ) external;

    function borrowCall(
        address sender,
        uint256 amountX,
        uint256 amountY,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.5.0;


interface IAmmalgamFactoryCallback {
    function tokens()
        external
        view
        returns (
            address tokenX,
            address tokenY
        );
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.8.13;

import '@openzeppelin/contracts/token/ERC1155/IERC1155.sol';

interface IAmmalgamERC1155 is IERC1155 {
    function TOKEN_ID_LIQUIDITY() external pure returns (uint256);

    function TOKEN_ID_DEPOSIT_X() external pure returns (uint256);

    function TOKEN_ID_DEPOSIT_Y() external pure returns (uint256);

    function TOKEN_ID_BORROW_X() external pure returns (uint256);

    function TOKEN_ID_BORROW_Y() external pure returns (uint256);

    function TOKEN_ID_BORROW_L() external pure returns (uint256);

    function totalSupply(uint256 id) external returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC1155/extensions/ERC1155Supply.sol)

pragma solidity ^0.8.0 ;

import "../ERC1155.sol";

/**
 * @dev Extension of ERC1155 that adds tracking of total supply per id.
 *
 * Useful for scenarios where Fungible and Non-fungible tokens have to be
 * clearly identified. Note: While a totalSupply of 1 might mean the
 * corresponding is an NFT, there is no guarantees that no other token with the
 * same id are not going to be minted.
 */
abstract contract ERC1155Supply is ERC1155 {
    mapping(uint256 => uint256) private _totalSupply;

    /**
     * @dev Total amount of tokens in with a given id.
     */
    function totalSupply(uint256 id) public view virtual returns (uint256) {
        return _totalSupply[id];
    }

    /**
     * @dev Indicates whether any token exist with a given id, or not.
     */
    function exists(uint256 id) public view virtual returns (bool) {
        return ERC1155Supply.totalSupply(id) > 0;
    }

    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        if (from == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                _totalSupply[ids[i]] += amounts[i];
            }
        }

        /*
            if it's mint, first time it requires to == 0x
            if it's burn, requires to == 0x
            problem is caller is unknown here. using the data variable?
            cannot just check _firstMint because it will skip the burn function

            solution: combine checking from , to and _firstMint to determin it's a mint to 0 call.
        */

        if (from == address(0) && to == address(0) && _firstMint == true) {
            return;
        }
        if (to == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                uint256 id = ids[i];
                uint256 amount = amounts[i];
                uint256 supply = _totalSupply[id];
                require(supply >= amount, "ERC1155: burn amount exceeds totalSupply");
                unchecked {
                    /* minted to 0x0, amount get deducted here , cause the fail in testMint */
                    _totalSupply[id] = supply - amount;
                }
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    // Implementation specific flag to allow for the first mint to transfer to the zero address.
    bool internal _firstMint = true;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: address zero is not a valid owner");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {

        bool _firstMint_ = _firstMint;      // saving gas
        // implementation specific change to allow minting of MINIMUM_LIQUIDITY to zero address
        if ( to == address(0) ) {
            if ( !_firstMint_ ) {
                revert("ERC1155: mint to the zero address");
            }
        }

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);
        if ( _firstMint_ ) {
            _firstMint = false;
        }
        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `ids` and `amounts` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}