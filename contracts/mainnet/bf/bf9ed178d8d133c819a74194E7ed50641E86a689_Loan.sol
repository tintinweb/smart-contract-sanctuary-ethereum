/**
 *Submitted for verification at Etherscan.io on 2022-10-19
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

contract Loan is Ownable {
    using SafeMath for uint256;
    uint256 public totalLiquidity;
    uint256 public nativeTokenMin;
    address public nativeTokenAddress;
    address public operator;

    struct LoanPool {
        uint256 loanDuration;
        uint256 loanLimit;
        uint256 loanLimitNative;
        uint256 repayRate;
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
    mapping(address => uint256) public userLoansCount;
    mapping(address => mapping(uint256 => LoanRequest)) public loans;

    address[] public collateralTokens;
    address[] public loanUsers;
    uint256 public loanUsersCount;
    mapping(address => uint256) public loanPoolLength;
    mapping(address => mapping(uint256 => LoanPool)) public loanPools;

    IUniswapV2Router02 public immutable uniswapV2Router;

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

    constructor(
        address _nativeTokenAddress,
        address _routerAddress,
        uint256 _nativeMin
    ) {
        totalLiquidity = 0;
        nativeTokenMin = 0;
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

    function init() public payable {
        require(totalLiquidity == 0);
        totalLiquidity = address(this).balance;
    }

    function addLoanPool(
        address _collateralToken,
        uint256 _loanDuration,
        uint256 _loanLimit,
        uint256 _loanLimitNative,
        uint256 _repayRate
    ) public onlyOwner {
        require(
            _collateralToken != address(0),
            "update: Zero collateral address"
        );
        require(_loanLimit < 100, "add: Can't over 100% limit");
        require(_loanLimitNative < 100, "add: Can't over 100% limit");
        require(_repayRate >= 100, "add: shold be over 100%");

        bool isCollateralToken = false;
        for (uint256 i = 0; i < collateralTokens.length; i++) {
            if (_collateralToken == collateralTokens[i]) {
                isCollateralToken = true;
                break;
            }
        }
        if (!isCollateralToken) {
            collateralTokens.push(_collateralToken);
        }
        LoanPool memory newLoanPool;
        newLoanPool.loanDuration = _loanDuration;
        newLoanPool.loanLimit = _loanLimit;

        newLoanPool.loanLimitNative = _loanLimitNative;
        newLoanPool.repayRate = _repayRate;
        uint256 loanPoolLen = loanPoolLength[_collateralToken];

        loanPools[_collateralToken][loanPoolLen] = newLoanPool;
        loanPoolLength[_collateralToken]++;
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

    function isNativeTokenHolder(address _user) public view returns (bool) {
        uint256 balance = IERC20(nativeTokenAddress).balanceOf(_user);
        if (balance > nativeTokenMin) {
            return true;
        }
        return false;
    }

    function updateNativeTokenMin(uint256 _min) public onlyOwner {
        nativeTokenMin = _min;
    }

    function updateNativeToken(address _tokenAddress) public onlyOwner {
        require(_tokenAddress != address(0), "native: zero token address");
        nativeTokenAddress = _tokenAddress;
    }

    // calculate require colleteral token amount by passing ether amount
    function countCollateralFromEther(
        address _collateralToken,
        uint256 _limit,
        uint256 _amount
    ) public view returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = address(_collateralToken);
        path[1] = uniswapV2Router.WETH();

        uint256[] memory amounts = new uint256[](path.length);
        amounts = uniswapV2Router.getAmountsIn(_amount, path);

        uint256 result = (amounts[0]).div(_limit).mul(100);
        return result;
    }

    // calculate require ether amount by passing collateral amount
    function countEtherFromCollateral(
        address _collateralToken,
        uint256 _limit,
        uint256 _tokenAmount
    ) public view returns (uint256) {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(_collateralToken);
        path[1] = uniswapV2Router.WETH();

        uint256[] memory amounts = new uint256[](path.length);
        amounts = uniswapV2Router.getAmountsOut(_tokenAmount, path);

        uint256 result = (amounts[path.length - 1]).mul(_limit).div(100);
        return result;
    }

    function checkEnoughLiquidity(uint256 _amount) public view returns (bool) {
        if (_amount > totalLiquidity) {
            return false;
        } else {
            return true;
        }
    }

    function loanEther(
        address _collateralToken,
        uint256 _loanPoolId,
        uint256 _tokenAmount
    ) public {
        uint256 balance = IERC20(_collateralToken).balanceOf(msg.sender);
        bool isHolder = isNativeTokenHolder(msg.sender);
        uint256 limit = !isHolder
            ? loanPools[_collateralToken][_loanPoolId].loanLimit
            : loanPools[_collateralToken][_loanPoolId].loanLimitNative;
        uint256 ethAmount = countEtherFromCollateral(
            _collateralToken,
            limit,
            _tokenAmount
        );
        uint256 loanPoolLen = loanPoolLength[_collateralToken];
        bool isOldUser = false;
        for (uint256 i = 0; i < loanUsers.length; i++) {
            if (loanUsers[i] == msg.sender) {
                isOldUser = true;
                break;
            }
        }
        if (isOldUser == false) {
            loanUsers.push(msg.sender);
            loanUsersCount++;
        }
        require(balance > _tokenAmount, "loanEther: not enough token balance");
        require(
            checkEnoughLiquidity(ethAmount),
            "loanEther: not enough liquidity"
        );
        require(loanPoolLen > _loanPoolId, "loanEther: no valid loan Id");

        LoanRequest memory newLoan;
        newLoan.borrower = msg.sender;
        newLoan.loanAmount = ethAmount;
        newLoan.collateralAmount = _tokenAmount;
        newLoan.loanId = userLoansCount[msg.sender];
        newLoan.isPayback = false;
        newLoan.token = _collateralToken;

        uint256 repayRate = loanPools[_collateralToken][_loanPoolId].repayRate;
        uint256 loanDuration = loanPools[_collateralToken][_loanPoolId]
            .loanDuration;
        newLoan.paybackAmount = ethAmount.mul(repayRate).div(100);
        newLoan.loanDueDate = block.timestamp + loanDuration;
        newLoan.duration = loanDuration;

        require(
            IERC20(_collateralToken).transferFrom(
                msg.sender,
                address(this),
                newLoan.collateralAmount
            ),
            "loanEther: Transfer token from user to contract failed"
        );
        loans[msg.sender][userLoansCount[msg.sender]] = newLoan;
        userLoansCount[msg.sender]++;
        totalLiquidity = totalLiquidity.sub(ethAmount);
        payable(msg.sender).transfer(ethAmount);
        emit NewLoanEther(
            msg.sender,
            newLoan.loanAmount,
            newLoan.collateralAmount,
            newLoan.paybackAmount,
            newLoan.loanDueDate,
            newLoan.duration
        );
    }

    function payback(address _collateralToken, uint256 _id) public payable {
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
        require(
            IERC20(_collateralToken).transfer(
                msg.sender,
                loanReq.collateralAmount
            ),
            "payback: Transfer collateral from contract to user failed"
        );
        loanReq.isPayback = true;
        totalLiquidity = totalLiquidity.add(msg.value);
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

    function countSwapAmount(address _token) private view returns (uint256) {
        uint256 tokenSwapAmount;
        for (uint256 k = 0; k < loanUsersCount; k++) {
            address user = loanUsers[k];
            LoanRequest[] memory loanUser = getUserOverdueLoansFrom(
                user,
                lastSwapTs
            );
            for (uint256 i = 0; i < loanUser.length; i++) {
                if (_token == loanUser[i].token) {
                    tokenSwapAmount = tokenSwapAmount.add(loanUser[i].collateralAmount);
                }
            }
        }
        return tokenSwapAmount;
    }

    function isSwappable() public view returns(bool) {
        uint256 totalSwapAmount = 0;
        bool isEnable;
        for(uint256 i = 0; i < collateralTokens.length; i++) {
            uint256 tokenAmount = countSwapAmount(collateralTokens[i]);
            totalSwapAmount = totalSwapAmount.add(tokenAmount);
        }
        if(totalSwapAmount > 0) {
            isEnable = true;
        }
        return isEnable;
    }

    function swapAssets() public onlyOperator {
        for(uint256 i = 0; i < collateralTokens.length; i++) {
            uint256 tokenAmount = countSwapAmount(collateralTokens[i]);
            if(tokenAmount > 0) {
                IERC20(collateralTokens[i]).transfer(msg.sender, tokenAmount);
            }
        }
        lastSwapTs = block.timestamp;
    }

    function transferOperator(address _opeator) public onlyOwner {
        require(_opeator != address(0), "operator: Zero Address");
        operator = _opeator;
    }

    function updateTotalLiquidity() public onlyOwnerOrOperator {
        totalLiquidity = address(this).balance;
    }

    function withdrawEth(uint256 _amount) external onlyOwnerOrOperator {
        require(
            _amount < totalLiquidity,
            "withdraw: Can't exceed more than totalLiquidity"
        );
        address payable _owner = payable(owner());
        totalLiquidity = totalLiquidity.sub(_amount);
        _owner.transfer(_amount);
    }

    function recoverERC20(address _token) public onlyOperator {
        bool isCollateralToken = false;
        for (uint256 i = 0; i < collateralTokens.length; i++) {
            if (_token == collateralTokens[i]) {
                isCollateralToken = true;
                break;
            }
        }
        if (!isCollateralToken) {
            uint256 balance = IERC20(_token).balanceOf(address(this));
            IERC20(_token).transfer(msg.sender, balance);
        }
    }

    function getCollateralLen() public view returns(uint256) {
        return collateralTokens.length;
    }
}