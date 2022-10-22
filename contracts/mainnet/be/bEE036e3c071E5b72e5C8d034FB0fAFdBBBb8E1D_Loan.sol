/**
 *Submitted for verification at Etherscan.io on 2022-10-22
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.9.0;

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

contract Loan is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    uint256 public ethLimit; // percentage: user can borrow eth limit
    uint256 public nativeTokenMin;
    address public nativeTokenAddress;
    address public operator;

    struct LoanPool {
        uint256 loanDuration;
        uint256 loanLimit;
        uint256 loanLimitNative;
        uint256 repayRate;
        bool closed;
    }

    struct LoanRequest {
        address borrower;
        address token;
        uint256 loanAmount;
        uint256 collateralAmount;
        uint256 paybackAmount;
        uint256 loanDueDate;
        uint256 duration;
        uint256 loanId;
        bool isPayback;
    }

    uint256 public lastSwapTs;
    mapping(address => address[]) public swapPaths;
    mapping(address => uint256) public userLoansCount;
    mapping(address => mapping(uint256 => LoanRequest)) public loans;

    address[] public collateralTokens;
    address[] public loanUsers;
    mapping(address => uint256) public loanPoolLength;
    mapping(address => mapping(uint256 => LoanPool)) public loanPools;

    IUniswapV2Router02 public immutable uniswapV2Router;

    event NewAddLoanPool(
        address collateralToken,
        uint256 loanDuration,
        uint256 loanLimit,
        uint256 loanLimitNative,
        uint256 repayRate
    );

    event NewLoanEther(
        address indexed borrower,
        uint256 loanAmount,
        uint256 collateralAmount,
        uint256 paybackAmount,
        uint256 loanDueDate,
        uint256 duration
    );

    event PayBack(
        address borrower,
        bool paybackSuccess,
        uint256 paybackTime,
        uint256 paybackAmount,
        uint256 returnCollateralAmount
    );

    event Received(address, uint256);

    event UpdatePairToken(address collateralToken, address[] swapPath);

    constructor(
        address _nativeTokenAddress,
        address _routerAddress,
        uint256 _nativeMin,
        uint256 _ethLimit
    ) {
        ethLimit = _ethLimit;
        nativeTokenMin = _nativeMin;
        nativeTokenAddress = _nativeTokenAddress;
        operator = msg.sender;
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            _routerAddress
        );
        uniswapV2Router = _uniswapV2Router;
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

    function addLoanPool(
        address _collateralToken,
        uint256 _loanDuration,
        uint256 _loanLimit,
        uint256 _loanLimitNative,
        uint256 _repayRate,
        address[] memory _path
    ) public onlyOwner {
        require(
            _collateralToken != address(0),
            "update: Zero collateral address"
        );
        require(_loanLimit < 100, "add: Can't over 100% limit");
        require(_loanLimitNative < 100, "add: Can't over 100% limit");
        require(_repayRate >= 100, "add: shold be over 100%");

        bool isColToken = isCollateralToken(_collateralToken);
        if (!isColToken) {
            collateralTokens.push(_collateralToken);
            swapPaths[_collateralToken] = _path;
        }
        LoanPool memory newLoanPool;
        newLoanPool.loanDuration = _loanDuration;
        newLoanPool.loanLimit = _loanLimit;

        newLoanPool.loanLimitNative = _loanLimitNative;
        newLoanPool.repayRate = _repayRate;
        newLoanPool.closed = false;
        uint256 loanPoolLen = loanPoolLength[_collateralToken];

        loanPools[_collateralToken][loanPoolLen] = newLoanPool;
        loanPoolLength[_collateralToken]++;

        emit NewAddLoanPool(
            _collateralToken,
            _loanDuration,
            _loanLimit,
            _loanLimitNative,
            _repayRate
        );
    }

    function updateLoanPool(
        address _collateralToken,
        uint256 _index,
        uint256 _loanDuration,
        uint256 _loanLimit,
        uint256 _loanLimitNative,
        uint256 _repayRate
    ) public onlyOwner {
        require(
            _collateralToken != address(0),
            "update: Zero collateral address"
        );
        bool isColToken = isCollateralToken(_collateralToken);
        require(isColToken, "update: No collateral token");
        uint256 loanIdLen = loanPoolLength[_collateralToken];
        require(_index < loanIdLen, "update: No valid index");
        require(_loanLimit < 100, "add: Can't over 100% limit");
        require(_loanLimitNative < 100, "add: Can't over 100% limit");
        require(_repayRate >= 100, "add: shold be over 100%");

        loanPools[_collateralToken][_index].loanDuration = _loanDuration;
        loanPools[_collateralToken][_index].loanLimit = _loanLimit;
        loanPools[_collateralToken][_index].loanLimitNative = _loanLimitNative;
        loanPools[_collateralToken][_index].repayRate = _repayRate;
    }

    function updateSwapPath(address _collateralToken, address[] memory _path)
        public
        onlyOwner
    {
        require(
            _collateralToken != address(0),
            "update: Zero collateral address"
        );
        bool isColToken = isCollateralToken(_collateralToken);
        require(isColToken, "update: No collateral token");
        swapPaths[_collateralToken] = _path;

        emit UpdatePairToken(_collateralToken, _path);
    }

    function setLoanPoolClose(
        address _collateralToken,
        uint256 _loanPoolId,
        bool _closed
    ) public onlyOwner {
        require(
            _collateralToken != address(0),
            "update: Zero collateral address"
        );
        bool isColToken = isCollateralToken(_collateralToken);
        require(isColToken, "update: No collateral token");
        uint256 loanIdLen = loanPoolLength[_collateralToken];
        require(_loanPoolId < loanIdLen, "set: No valid loan pool id");
        loanPools[_collateralToken][_loanPoolId].closed = _closed;
    }

    function isCollateralToken(address _addr) public view returns (bool) {
        uint256 len = collateralTokens.length;
        bool isToken = false;
        for (uint256 i = 0; i < len; i++) {
            if (_addr == collateralTokens[i]) {
                isToken = true;
                break;
            }
        }
        return isToken;
    }

    function isNativeTokenHolder(address _user) public view returns (bool) {
        uint256 balance = IERC20(nativeTokenAddress).balanceOf(_user);
        if (balance > nativeTokenMin) {
            return true;
        }
        return false;
    }

    function updateNativeToken(address _tokenAddress, uint256 _min)
        public
        onlyOwner
    {
        require(_tokenAddress != address(0), "native: zero token address");
        nativeTokenAddress = _tokenAddress;
        nativeTokenMin = _min;
    }

    function updateEthLimit(uint256 _ethLimit) public onlyOwner {
        require(ethLimit < 100, "update: Eth limit should be less than 100%");
        ethLimit = _ethLimit;
    }

    // calculate require colleteral token amount by passing ether amount
    function countCollateralFromEther(
        address _collateralToken,
        uint256 _limit,
        uint256 _amount
    ) public view returns (uint256) {
        address[] memory path = swapPaths[_collateralToken];
        uint256[] memory amounts = new uint256[](path.length);
        amounts = uniswapV2Router.getAmountsIn(_amount, path);
        uint256 result = amounts[0].div(_limit).mul(100);
        return result;
    }

    // calculate require ether amount by passing collateral amount
    function countEtherFromCollateral(
        address _collateralToken,
        uint256 _limit,
        uint256 _tokenAmount
    ) public view returns (uint256) {
        address[] memory path = swapPaths[_collateralToken];
        uint256[] memory amounts = new uint256[](path.length);
        amounts = uniswapV2Router.getAmountsOut(_tokenAmount, path);
        uint256 result = amounts[path.length - 1].mul(_limit).div(100);
        return result;
    }

    function checkMax(uint256 _amount) public view returns (bool) {
        uint256 totalEth = address(this).balance;
        uint256 loanMax = totalEth.mul(ethLimit).div(100);
        if (_amount > loanMax) {
            return false;
        } else {
            return true;
        }
    }

    function TokenTransfer(
        address _user,
        address _collateralToken,
        uint256 _tokenAmount
    ) private returns (bool) {
        bool transferred = IERC20(_collateralToken).transferFrom(
            _user,
            address(this),
            _tokenAmount
        );
        return transferred;
    }

    function loanEther(
        address _collateralToken,
        uint256 _loanPoolId,
        uint256 _tokenAmount
    ) public nonReentrant {
        require(
            !loanPools[_collateralToken][_loanPoolId].closed,
            "loanEther: Loan Pool is closed"
        );
        uint256 tokenAmount = _tokenAmount;
        address collateralToken = _collateralToken;
        uint256 loanPoolId = _loanPoolId;
        uint256 loanPoolLen = loanPoolLength[collateralToken];
        
        require(loanPoolLen > loanPoolId, "loanEther: no valid loan Id");
        
        uint256 balance = IERC20(collateralToken).balanceOf(msg.sender);
        
        require(balance > tokenAmount, "loanEther: not enough token balance");

        bool isHolder = isNativeTokenHolder(msg.sender);
        uint256 limit = !isHolder
            ? loanPools[collateralToken][loanPoolId].loanLimit
            : loanPools[collateralToken][loanPoolId].loanLimitNative;
        uint256 beforeBalance = IERC20(collateralToken).balanceOf(
            address(this)
        );

        require(
            TokenTransfer(msg.sender, collateralToken, tokenAmount),
            "loanEther: Transfer token from user to contract failed"
        );
        
        uint256 afterBalance = IERC20(collateralToken).balanceOf(address(this));
        uint256 tokenAmountReal = afterBalance - beforeBalance;
        uint256 ethAmountReal = countEtherFromCollateral(
            collateralToken,
            limit,
            tokenAmountReal
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
        require(
            checkMax(ethAmountReal),
            "loanEther: not enough liquidity or over max ETH amount"
        );
        LoanRequest memory newLoan;
        newLoan.borrower = msg.sender;
        newLoan.loanAmount = ethAmountReal;
        newLoan.collateralAmount = tokenAmountReal;
        newLoan.loanId = userLoansCount[msg.sender];
        newLoan.isPayback = false;
        newLoan.token = collateralToken;
        uint256 repayRate = loanPools[collateralToken][loanPoolId].repayRate;
        uint256 loanDuration = loanPools[collateralToken][loanPoolId]
            .loanDuration;
        newLoan.paybackAmount = ethAmountReal.mul(repayRate).div(100);
        newLoan.loanDueDate = block.timestamp + loanDuration;
        newLoan.duration = loanDuration;

        loans[msg.sender][userLoansCount[msg.sender]] = newLoan;
        userLoansCount[msg.sender]++;
        payable(msg.sender).transfer(ethAmountReal);
        emit NewLoanEther(
            msg.sender,
            newLoan.loanAmount,
            newLoan.collateralAmount,
            newLoan.paybackAmount,
            newLoan.loanDueDate,
            newLoan.duration
        );
    }

    function payback(address _collateralToken, uint256 _id)
        public
        payable
        nonReentrant
    {
        LoanRequest storage loanReq = loans[msg.sender][_id];
        require(
            loanReq.borrower == msg.sender,
            "payback: Only borrower can payback"
        );
        require(!loanReq.isPayback, "payback: payback already");
        require(
            block.timestamp <= loanReq.loanDueDate,
            "payback: exceed due date"
        );
        require(
            msg.value >= loanReq.paybackAmount,
            "payback: Not enough ether"
        );
        loanReq.isPayback = true;
        require(
            IERC20(_collateralToken).transfer(
                msg.sender,
                loanReq.collateralAmount
            ),
            "payback: Transfer collateral from contract to user failed"
        );
        emit PayBack(
            msg.sender,
            loanReq.isPayback,
            block.timestamp,
            loanReq.paybackAmount,
            loanReq.collateralAmount
        );
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
                if (_token == loanUser[i].token) {
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

    function swapAssets() public onlyOperator {
        for (uint256 i = 0; i < collateralTokens.length; i++) {
            uint256 tokenAmount = countSwapAmount(collateralTokens[i]);
            if (tokenAmount > 0) {
                IERC20(collateralTokens[i]).approve(
                    address(uniswapV2Router),
                    tokenAmount
                );
                address[] memory path = swapPaths[collateralTokens[i]];
                uniswapV2Router
                    .swapExactTokensForETHSupportingFeeOnTransferTokens(
                        tokenAmount,
                        0, // accept any amount of ETH
                        path,
                        address(this),
                        block.timestamp
                    );
            }
        }
        lastSwapTs = block.timestamp;
    }

    function transferOperator(address _opeator) public onlyOwner {
        require(_opeator != address(0), "operator: Zero Address");
        operator = _opeator;
    }

    function withdrawEth(uint256 _amount) external onlyOwnerOrOperator {
        uint256 totalEth = address(this).balance;
        require(
            _amount < totalEth,
            "withdraw: Can't exceed more than totalLiquidity"
        );
        address payable _owner = payable(owner());
        _owner.transfer(_amount);
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

    function getTotalLiquidity() public view returns (uint256) {
        return address(this).balance;
    }
}