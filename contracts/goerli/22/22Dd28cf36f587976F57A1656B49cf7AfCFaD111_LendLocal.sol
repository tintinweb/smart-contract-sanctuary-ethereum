// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.9.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// TODO(zx): Replace all instances of SafeMath with OZ implementation
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        assert(a == b * c + (a % b)); // There is no case in which this doesn't hold

        return c;
    }

    // Only used in the  BondingCalculator.sol
    function sqrrt(uint256 a) internal pure returns (uint256 c) {
        if (a > 3) {
            c = a;
            uint256 b = add(div(a, 2), 1);
            while (b < c) {
                c = b;
                b = div(add(div(a, b), b), 2);
            }
        } else if (a != 0) {
            c = 1;
        }
    }
}

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    bytes internal constant TABLE_DECODE =
        hex"0000000000000000000000000000000000000000000000000000000000000000"
        hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
        hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
        hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {

            } lt(dataPtr, endPtr) {

            } {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(
                    resultPtr,
                    mload(add(tablePtr, and(shr(18, input), 0x3F)))
                )
                resultPtr := add(resultPtr, 1)
                mstore8(
                    resultPtr,
                    mload(add(tablePtr, and(shr(12, input), 0x3F)))
                )
                resultPtr := add(resultPtr, 1)
                mstore8(
                    resultPtr,
                    mload(add(tablePtr, and(shr(6, input), 0x3F)))
                )
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {

            } lt(dataPtr, endPtr) {

            } {
                // read 4 characters
                dataPtr := add(dataPtr, 4)
                let input := mload(dataPtr)

                // write 3 bytes
                let output := add(
                    add(
                        shl(
                            18,
                            and(
                                mload(add(tablePtr, and(shr(24, input), 0xFF))),
                                0xFF
                            )
                        ),
                        shl(
                            12,
                            and(
                                mload(add(tablePtr, and(shr(16, input), 0xFF))),
                                0xFF
                            )
                        )
                    ),
                    add(
                        shl(
                            6,
                            and(
                                mload(add(tablePtr, and(shr(8, input), 0xFF))),
                                0xFF
                            )
                        ),
                        and(mload(add(tablePtr, and(input, 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}

interface IERC20 {
    function increaseAllowance(address spender, uint256 addedValue)
        external
        returns (bool);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

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

interface IUniswapV2Pair {
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

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

contract LendLocal is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    uint256 public FEEDEN = 10000;

    address public operator;
    address public ETHER;
    string public tempWithdrawalCode;
    struct LoanRequest {
        address borrower;
        address collateralToken;
        uint256 kiosk;
        uint256 fiatPoolId;
        uint256 loanAmount;
        uint256 collateralAmount;
        uint256 loanDueDate;
        uint256 duration;
        uint32 loanId;
        string withdrawCode;
        string returnCode;
        bool isPayback;
        bool isFiatPaid;
    }

    struct LoanPool {
        uint256 loanDuration;
        uint256 loanLimit;
        bool closed;
    }

    struct FiatPool {
        bool closed;
        address priceFeed;
    }

    uint256 public lastSwapTs;
    mapping(address => address[]) public swapPaths;
    mapping(address => uint32) public userLoansCount;
    mapping(address => LoanPool) public loanPools;
    mapping(address => mapping(uint256 => LoanRequest)) public loans;

    address[] public loanUsers;
    address[] public collateralTokens;
    FiatPool[] public fiatPools;

    IUniswapV2Router02 public immutable uniswapV2Router;

    event NewAddLoanPool(
        address collateralToken,
        uint256 loanDuration,
        uint256 loanLimit,
        address[] path
    );

    event NewUpdateLoanPool(
        address collateralToken,
        uint256 loanDuration,
        uint256 loanLimit
    );

    event NewLoanEther(
        address indexed borrower,
        address collateralToken,
        uint256 collateralAmount,
        uint256 kiosk,
        uint256 fiatPoolId,
        uint256 loanAmount,
        uint256 loanDueDate,
        uint256 duration,
        uint256 loanId
    );

    event PayBack(
        address borrower,
        bool paybackSuccess,
        uint256 paybackTime,
        uint256 collateralAmount
    );

    event Received(address, uint256);
    event NewAddFiatPool(address priceFeed);
    event NewRemoveFiatPool(uint256 id);
    event NewUpdatePriceFeed(uint256 id, address priceFeed);
    event NewCloseFiatPool(uint256 id, bool closed);
    event NewUpdateSwapPath(address collateralToken, address[] swapPath);

    constructor(address _routerAddress, address _weth) {
        require(_weth != address(0), "zero weth address");
        operator = msg.sender;
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            _routerAddress
        );
        uniswapV2Router = _uniswapV2Router;
        ETHER = _weth;
    }

    // Operator CAN do modifier
    modifier onlyOperator() {
        require(operator == msg.sender, "operator: caller is not the operator");
        _;
    }

    modifier onlyOwnerOrOperator() {
        require(
            (msg.sender == owner()) || (msg.sender == operator),
            "Not owner or operator"
        );
        _;
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    function isCollateralToken(address _colToken) public view returns (bool) {
        uint256 len = collateralTokens.length;
        bool isColToken = false;
        for (uint256 i = 0; i < len; i++) {
            if (_colToken == collateralTokens[i]) {
                isColToken = true;
                break;
            }
        }
        return isColToken;
    }

    function addLoanPool(
        address _collateralToken,
        uint256 _loanDuration,
        uint256 _loanLimit,
        address[] memory _path
    ) public onlyOwner {
        require(
            _collateralToken != address(0),
            "addLoan: Zero collateral address"
        );
        require(_loanLimit < FEEDEN, "addLoan: Can't exceed 100%");
        bool isColToken = isCollateralToken(_collateralToken);
        if (!isColToken) {
            collateralTokens.push(_collateralToken);
            swapPaths[_collateralToken] = _path;
        }
        LoanPool memory newLoanPool;
        newLoanPool.loanDuration = _loanDuration;
        newLoanPool.loanLimit = _loanLimit;
        newLoanPool.closed = false;
        loanPools[_collateralToken] = newLoanPool;
        emit NewAddLoanPool(_collateralToken, _loanDuration, _loanLimit, _path);
    }

    function updateLoanPool(
        address _collateralToken,
        uint256 _loanDuration,
        uint256 _loanLimit
    ) public onlyOwner {
        bool isColToken = isCollateralToken(_collateralToken);
        require(isColToken, "updateLoan: No collateral token");
        require(_loanLimit < FEEDEN, "updateLoan: Can't exceed 100% limit");
        loanPools[_collateralToken].loanDuration = _loanDuration;
        loanPools[_collateralToken].loanLimit = _loanLimit;
        emit NewUpdateLoanPool(_collateralToken, _loanDuration, _loanLimit);
    }

    function updateSwapPath(address _collateralToken, address[] memory _path)
        public
        onlyOwner
    {
        bool isColToken = isCollateralToken(_collateralToken);
        require(isColToken, "updateSwap: No collateral token");
        swapPaths[_collateralToken] = _path;
        emit NewUpdateSwapPath(_collateralToken, _path);
    }

    function addFiatPool(address _priceFeed) public onlyOwner {
        require(_priceFeed != address(0), "addFiat:: zero price feed address");
        FiatPool memory newFiatPool;
        newFiatPool.priceFeed = _priceFeed;
        newFiatPool.closed = false;
        fiatPools.push(newFiatPool);
        emit NewAddFiatPool(_priceFeed);
    }

    function removeFiatPool(uint256 _id) public onlyOwner {
        uint256 len = fiatPools.length;
        require(_id != 0, "removeFiat:: can't remove base fiat pool");
        require(_id < len, "removeFiat:: exceed length");
        fiatPools[_id] = fiatPools[len - 1];
        fiatPools.pop();
        emit NewRemoveFiatPool(_id);
    }

    function updatePriceFeed(uint256 _id, address _priceFeed) public onlyOwner {
        require(
            _priceFeed != address(0),
            "updateFiat:: zero price feed address"
        );
        uint256 len = fiatPools.length;
        require(_id < len, "updateFiat:: exceed length");
        fiatPools[_id].priceFeed = _priceFeed;
        emit NewUpdatePriceFeed(_id, _priceFeed);
    }

    function closeFiatPool(uint256 _id, bool _closed) public onlyOwner {
        uint256 len = fiatPools.length;
        require(_id < len, "closeFiat:: exceed length");
        fiatPools[_id].closed = _closed;
        emit NewCloseFiatPool(_id, _closed);
    }

    function uintToBytes(uint256 _value, uint256 _length)
        public
        pure
        returns (bytes memory)
    {
        bytes memory reversed = new bytes(_length);
        uint256 i = _length;
        while (_value != 0) {
            i--;
            bytes1 bb = bytes1(uint8(_value));
            _value >>= 4;
            reversed[i] = bb;
        }
        return reversed;
    }

    function getEncodeValue(bytes memory data)
        public
        pure
        returns (string memory)
    {
        string memory encodedValue = Base64.encode(data);
        return encodedValue;
    }

    function getDecodeValue(string memory data)
        public
        pure
        returns (bytes memory)
    {
        bytes memory decodedValue = Base64.decode(data);
        return decodedValue;
    }

    function getETHPrice() public view returns (uint256) {
        address priceFeedAddress = fiatPools[0].priceFeed;
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            priceFeedAddress
        );
        (
            ,
            /*uint80 roundID*/
            int256 price, /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/
            ,
            ,

        ) = priceFeed.latestRoundData();

        return uint256(price);
    }

    function getFiatInUSD(uint256 _id) public view returns (uint256) {
        address priceFeedAddress = fiatPools[_id].priceFeed;
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            priceFeedAddress
        );
        (
            ,
            /*uint80 roundID*/
            int256 price, /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/
            ,
            ,

        ) = priceFeed.latestRoundData();

        return uint256(price);
    }

    // calculate require colleteral token amount by passing fiat amount
    function countCollateralFromFiat(
        address _collateralToken,
        uint256 _fiatId,
        uint256 _limit,
        uint256 _fiatAmount
    ) public view returns (uint256) {
        uint256 ethPrice = getFiatInUSD(0);
        uint256 fiatPrice = getFiatInUSD(_fiatId);
        uint256 ethAmount = 0;
        if (_fiatId == 0) {
            ethAmount = _fiatAmount.mul(FEEDEN).mul(10**8).div(ethPrice).div(
                _limit
            ); // consider Fiat decimals 18
        } else {
            ethAmount = _fiatAmount
                .mul(FEEDEN)
                .mul(fiatPrice)
                .div(ethPrice)
                .div(_limit); // consider Fiat decimals 18
        }
        if (_collateralToken == ETHER) {
            return ethAmount;
        } else {
            address[] memory path = swapPaths[_collateralToken];
            uint256[] memory amounts = new uint256[](path.length);
            amounts = uniswapV2Router.getAmountsIn(ethAmount, path);
            uint256 result = amounts[0];
            return result;
        }
    }

    // calculate require fiat amount by passing collateral amount
    function countFiatFromCollateral(
        address _collateralToken,
        uint256 _fiatId,
        uint256 _limit,
        uint256 _colTokenAmount
    ) public view returns (uint256) {
        uint256 result = 0;
        if (_collateralToken == ETHER) {
            result = _colTokenAmount;
        } else {
            address[] memory path = swapPaths[_collateralToken];
            uint256[] memory amounts = new uint256[](path.length);
            amounts = uniswapV2Router.getAmountsOut(_colTokenAmount, path);
            result = amounts[path.length - 1];
        }
        uint256 ethPrice = getFiatInUSD(0);
        uint256 fiatPrice = getFiatInUSD(_fiatId);
        if (_fiatId == 0) {
            result = result.mul(ethPrice).mul(_limit).div(10**8).div(FEEDEN);
        } else {
            result = result.mul(ethPrice).mul(_limit).div(fiatPrice).div(
                FEEDEN
            );
        }
        return result;
    }

    function TokenTransfer(
        address _user,
        address _token,
        uint256 _tokenAmount
    ) private returns (bool) {
        bool transferred = IERC20(_token).transferFrom(
            _user,
            address(this),
            _tokenAmount
        );
        return transferred;
    }

    function loanToken(
        address _collateralToken,
        uint256 _kiosk,
        uint256 _fiatPoolId,
        uint256 _fiatAmount
    ) public nonReentrant {
        bool isColToken = isCollateralToken(_collateralToken);
        require(isColToken, "loanToken:: No collateral token");

        address collateralToken = _collateralToken;
        uint256 fiatPoolId = _fiatPoolId;
        uint256 fiatAmount = _fiatAmount;

        uint256 fiatPoolLen = fiatPools.length;
        require(fiatPoolId < fiatPoolLen, "loanToken:: No valid fiat Pool Id");
        require(
            !fiatPools[fiatPoolId].closed,
            "loanToken:: Fiat Pool is closed"
        );
        require(
            !loanPools[collateralToken].closed,
            "loanToken:: Loan Pool is closed"
        );

        uint256 limit = loanPools[collateralToken].loanLimit;
        uint256 collateralAmount = countCollateralFromFiat(
            collateralToken,
            fiatPoolId,
            limit,
            fiatAmount
        );

        uint256 beforeBalance = IERC20(collateralToken).balanceOf(
            address(this)
        );

        require(
            TokenTransfer(msg.sender, collateralToken, collateralAmount),
            "loanToken:: Transfer collateral token from user to contract failed"
        );

        uint256 collateralAmountReal = IERC20(collateralToken).balanceOf(
            address(this)
        ) - beforeBalance;

        uint256 fiatAmountReal = countFiatFromCollateral(
            collateralToken,
            fiatPoolId,
            limit,
            collateralAmountReal
        );

        bool isOldUser = false;
        for (uint256 i = 0; i < loanUsers.length; i++) {
            if (loanUsers[i] == msg.sender) {
                isOldUser = true;
                break;
            }
        }

        if (isOldUser == false) {
            loanUsers.push(msg.sender);
        }

        LoanRequest memory newLoan;
        newLoan.borrower = msg.sender;
        newLoan.collateralToken = collateralToken;
        newLoan.kiosk = _kiosk;
        newLoan.fiatPoolId = fiatPoolId;
        newLoan.loanAmount = fiatAmountReal;
        newLoan.collateralAmount = collateralAmountReal;
        newLoan.loanId = userLoansCount[msg.sender];
        newLoan.isPayback = false;
        newLoan.isFiatPaid = false;
        uint256 loanDuration = loanPools[collateralToken].loanDuration;
        newLoan.loanDueDate = block.timestamp + loanDuration;
        newLoan.duration = loanDuration;
        uint256 startTimestamp = newLoan.loanDueDate - loanDuration;

        bytes memory wTemp = uintToBytes(newLoan.loanId, 4);
        string memory wCode = getEncodeValue(wTemp);
        newLoan.withdrawCode = wCode;

        uint64 returnValue = getReturnValue(newLoan.loanId, startTimestamp);
        bytes memory rTemp = uintToBytes(returnValue, 8);
        string memory rCode = getEncodeValue(rTemp);
        newLoan.returnCode = rCode;

        loans[msg.sender][userLoansCount[msg.sender]] = newLoan;
        userLoansCount[msg.sender]++;

        emit NewLoanEther(
            newLoan.borrower,
            newLoan.collateralToken,
            newLoan.collateralAmount,
            newLoan.kiosk,
            newLoan.fiatPoolId,
            newLoan.loanAmount,
            newLoan.loanDueDate,
            newLoan.duration,
            userLoansCount[msg.sender] -1
        );
    }

    function loanEther(uint256 _kiosk, uint256 _fiatPoolId, uint256 _fiatAmount)
        public
        payable
        nonReentrant
    {
        address collateralToken = ETHER;
        uint256 fiatPoolId = _fiatPoolId;
        uint256 fiatAmount = _fiatAmount;

        uint256 fiatPoolLen = fiatPools.length;
        require(fiatPoolId < fiatPoolLen, "loanEther:: No valid fiat Pool Id");
        require(
            !fiatPools[fiatPoolId].closed,
            "loanEther:: Fiat Pool is closed"
        );
        require(
            !loanPools[collateralToken].closed,
            "loanEther:: Loan Pool is closed"
        );

        uint256 limit = loanPools[collateralToken].loanLimit;
        uint256 collateralAmount = countCollateralFromFiat(
            collateralToken,
            fiatPoolId,
            limit,
            fiatAmount
        );
        uint256 beforeBalance = address(this).balance;
        require(
            msg.value >= collateralAmount,
            "loanEther: no enough ETHER on wallet"
        );
        uint256 afterBalance = address(this).balance;
        uint256 collateralAmountReal = afterBalance - beforeBalance;
        uint256 fiatAmountReal = countFiatFromCollateral(
            collateralToken,
            fiatPoolId,
            limit,
            collateralAmountReal
        );
        bool isOldUser = false;
        for (uint256 i = 0; i < loanUsers.length; i++) {
            if (loanUsers[i] == msg.sender) {
                isOldUser = true;
                break;
            }
        }
        if (isOldUser == false) {
            loanUsers.push(msg.sender);
        }
        LoanRequest memory newLoan;
        newLoan.borrower = msg.sender;
        newLoan.collateralToken = collateralToken;
        newLoan.kiosk = _kiosk;
        newLoan.fiatPoolId = fiatPoolId;
        newLoan.loanAmount = fiatAmountReal;
        newLoan.collateralAmount = collateralAmountReal;
        newLoan.loanId = userLoansCount[msg.sender];
        newLoan.isPayback = false;
        newLoan.isFiatPaid = false;
        uint256 loanDuration = loanPools[collateralToken].loanDuration;
        newLoan.loanDueDate = block.timestamp + loanDuration;
        newLoan.duration = loanDuration;
        uint256 startTimestamp = newLoan.loanDueDate - loanDuration;

        bytes memory temp = uintToBytes(newLoan.loanId, 4);
        string memory wCode = getEncodeValue(temp);
        newLoan.withdrawCode = wCode;

        uint64 returnValue = getReturnValue(newLoan.loanId, startTimestamp);
        temp = uintToBytes(returnValue, 8);
        string memory rCode = getEncodeValue(temp);
        newLoan.returnCode = rCode;

        loans[msg.sender][userLoansCount[msg.sender]] = newLoan;
        userLoansCount[msg.sender]++;

        emit NewLoanEther(
            newLoan.borrower,
            newLoan.collateralToken,
            newLoan.collateralAmount,
            newLoan.kiosk,
            newLoan.fiatPoolId,
            newLoan.loanAmount,
            newLoan.loanDueDate,
            newLoan.duration,
            newLoan.loanId
        );
    }

    function payback(uint256 _id) public nonReentrant {
        LoanRequest storage loanReq = loans[msg.sender][_id];
        address collateralToken = loanReq.collateralToken;
        uint256 collateralAmount = loanReq.collateralAmount;
        bool isFiatPaid = loanReq.isFiatPaid;
        require(
            loanReq.borrower == msg.sender,
            "payback: Only borrower can payback"
        );
        require(!loanReq.isPayback, "payback: Payback already");
        require(
            block.timestamp <= loanReq.loanDueDate,
            "payback: Exceed due date"
        );
        require(isFiatPaid, "payback: Fiat is not paid");

        loanReq.isPayback = true;
        if (collateralToken == ETHER) {
            address payable to = payable(msg.sender);
            to.transfer(collateralAmount);
        } else {
            require(
                IERC20(collateralToken).transfer(
                    msg.sender,
                    loanReq.collateralAmount
                ),
                "payback: Transfer collateral from contract to user failed"
            );
        }

        emit PayBack(
            msg.sender,
            loanReq.isPayback,
            block.timestamp,
            loanReq.collateralAmount
        );
    }

    function setFiatPaid(address _user, uint256 _id)
        public
        onlyOwnerOrOperator
    {
        LoanRequest storage loanReq = loans[_user][_id];
        require(loanReq.borrower == _user, "setFiat: Invalid user address");
        loanReq.isFiatPaid = true;
    }

    function getReturnValue(uint32 _loanId, uint256 _startTimestamp)
        public
        pure
        returns (uint64)
    {
        uint64 tempTimestamp = uint64(_startTimestamp);
        return uint64(_loanId << 32) | tempTimestamp;
    }

    function getAllUserLoans(address _user)
        public
        view
        returns (LoanRequest[] memory)
    {
        LoanRequest[] memory requests = new LoanRequest[](
            userLoansCount[_user]
        );
        for (uint256 i = 0; i < userLoansCount[_user]; i++) {
            requests[i] = loans[_user][i];
        }
        return requests;
    }

    function getUserOngoingLoans(address _user)
        public
        view
        returns (LoanRequest[] memory)
    {
        LoanRequest[] memory ongoing = new LoanRequest[](userLoansCount[_user]);
        for (uint256 i = 0; i < userLoansCount[_user]; i++) {
            LoanRequest memory req = loans[_user][i];
            if (!req.isPayback && req.loanDueDate > block.timestamp) {
                ongoing[i] = req;
            }
        }
        return ongoing;
    }

    function getUserOverdueLoans(address _user)
        public
        view
        returns (LoanRequest[] memory)
    {
        LoanRequest[] memory overdue = new LoanRequest[](userLoansCount[_user]);
        for (uint256 i = 0; i < userLoansCount[_user]; i++) {
            LoanRequest memory req = loans[_user][i];
            if (!req.isPayback && req.loanDueDate < block.timestamp) {
                overdue[i] = req;
            }
        }
        return overdue;
    }

    function getUserOverdueLoansFrom(address _user, uint256 _from)
        public
        view
        returns (LoanRequest[] memory)
    {
        LoanRequest[] memory overdue = new LoanRequest[](userLoansCount[_user]);
        for (uint256 i = 0; i < userLoansCount[_user]; i++) {
            LoanRequest memory req = loans[_user][i];
            if (
                !req.isPayback &&
                req.loanDueDate < block.timestamp &&
                _from < req.loanDueDate
            ) {
                overdue[i] = req;
            }
        }
        return overdue;
    }

    function countSwapAmount(address _token) public view returns (uint256) {
        uint256 tokenSwapAmount;
        for (uint256 k = 0; k < loanUsers.length; k++) {
            address user = loanUsers[k];
            LoanRequest[] memory loanUser = getUserOverdueLoansFrom(
                user,
                lastSwapTs
            );
            for (uint256 i = 0; i < loanUser.length; i++) {
                if (_token == loanUser[i].collateralToken) {
                    tokenSwapAmount = tokenSwapAmount.add(
                        loanUser[i].collateralAmount
                    );
                }
            }
        }
        return tokenSwapAmount;
    }

    function isSwappable() public view returns (bool) {
        uint256 totalSwapAmount = 0;
        bool isEnable;
        for (uint256 i = 0; i < collateralTokens.length; i++) {
            uint256 tokenAmount = countSwapAmount(collateralTokens[i]);
            totalSwapAmount = totalSwapAmount.add(tokenAmount);
        }
        if (totalSwapAmount > 0) {
            isEnable = true;
        }
        return isEnable;
    }

    function transferOperator(address _opeator) public onlyOwner {
        require(_opeator != address(0), "operator: Zero Address");
        operator = _opeator;
    }

    function withdrawEth(uint256 _amount) external onlyOwnerOrOperator {
        uint256 totalEth = address(this).balance;
        require(
            _amount <= totalEth,
            "withdraw: Can't exceed more than totalLiquidity"
        );
        address payable _owner = payable(msg.sender);
        _owner.transfer(_amount);
    }

    function emergencyWithdrawToken(address _token, uint256 _amount)
        external
        onlyOwnerOrOperator
    {
        IERC20(_token).transfer(msg.sender, _amount);
    }

    function recoverERC20(address _token) public onlyOperator {
        bool isColToken = isCollateralToken(_token);
        if (!isColToken) {
            uint256 balance = IERC20(_token).balanceOf(address(this));
            IERC20(_token).transfer(msg.sender, balance);
        }
    }

    function getCollateralLen() public view returns (uint256) {
        return collateralTokens.length;
    }

    function getFiatPoolsLen() public view returns (uint256) {
        return fiatPools.length;
    }

    function getTotalLoanedUsers() public view returns (uint256) {
        return loanUsers.length;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}