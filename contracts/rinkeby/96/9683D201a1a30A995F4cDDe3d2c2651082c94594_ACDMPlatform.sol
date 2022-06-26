//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/IERC20Mintable.sol";
import "./interfaces/IUniswapV2Router02.sol";

contract ACDMPlatform {

    event AddLot(uint256 indexed _amount, uint256 indexed _price, uint256 indexed _index);
    event EditLot(uint256 indexed _amount, uint256 indexed _index);
    event DelLot(uint256 indexed _index);

    enum Status {sale, trade}

    // Sale =======================
    uint256 public salePrice;
    uint256 public salePool;
    uint256[2] public saleReferralPercents;
    // ============================

    // Trade =======================
    struct Trade {
        address trader;
        uint256 amount;
        uint256 price;
    }
    mapping(uint256 => Trade) public lots;
    uint256 public lotIndex;
    uint256 public tradeReferralPercent;
    uint256 public tradesPool;
    // ============================

    // Other ======================
    address public immutable owner;
    address public immutable dao;
    IERC20Mintable public immutable token;
    IUniswapV2Router02 public immutable uniswap;

    mapping(address => address[]) public referrals;
    mapping(address => bool) public registered;

    uint256 constant public DURATION = 3 days;
    uint256 public endTime;
    Status public status;

    address[] public path;
    // ============================
    
    constructor(address _token, address _dao, address _uniswap, address _xxxtoken) {
        owner = msg.sender;
        dao = _dao;
        uniswap = IUniswapV2Router02(_uniswap);
        token = IERC20Mintable(_token);

        salePool = 1e11;
        salePrice = 1e7;
        saleReferralPercents = [50, 30];
        tradeReferralPercent = 25;
        endTime = DURATION + block.timestamp;

        path.push(IUniswapV2Router02(_uniswap).WETH());
        path.push(_xxxtoken);
    }   

    modifier eventOnly(Status _event) {
        require(status == _event, "Not active");
        require(endTime > block.timestamp, "Event closed");
        _;
    }

    modifier onlyDAO {
        require(msg.sender == dao, "DAO only");
        _;
    }

    modifier registeredOnly() {
        require(registered[msg.sender], "You are not registered");
        _;
    }

    function register() external {
        require(!registered[msg.sender], "Already registered");
        registered[msg.sender] = true;
    }

    function register(address[] memory _referrals) external {
        require(!registered[msg.sender], "Already registered");
        require(_referrals.length < 3, "Incorrect referrals count");
        
        for (uint256 i; i < _referrals.length; i++) {
            require(registered[_referrals[i]], "Referral not found");
            referrals[msg.sender].push(_referrals[i]);
        }

        registered[msg.sender] = true;
    }

    function buy(uint256 _amount) external payable registeredOnly eventOnly(Status.sale) {
        require(salePrice * _amount == msg.value, "Incorrect ETH value");
        require(_amount <= salePool, "Amount exceeds allowed pool");

        salePool -= _amount;
        token.mint(msg.sender, _amount);
        for (uint256 i; i < referrals[msg.sender].length; i++)
            _transfer(referrals[msg.sender][i], msg.value * saleReferralPercents[i] / 1000);
        
        if (salePool == 0) _swithTrade();
    }

    function _transfer(address _to, uint256 _amount) internal {
        (bool success, ) = _to.call{value: _amount}("");
        require(success, "ETH transfer failed");
    }

    function list(uint256 _amount, uint256 _price) external registeredOnly eventOnly(Status.trade) {
        require(_price > 0, "Price cant be null");
        require(_amount > 0, "Amount cant be null");

        token.transferFrom(msg.sender, address(this), _amount);
        lots[lotIndex] = Trade({
            trader: msg.sender,
            amount: _amount,
            price: _price
        });

        emit AddLot(_amount, _price, lotIndex++);
    }

    function cancel(uint256 _index) external registeredOnly {
        require(lots[_index].trader == msg.sender, "You are not an owner");
        
        uint256 _amount = lots[_index].amount;

        delete lots[_index];
        token.transfer(msg.sender, _amount);
        emit DelLot(_index);
    }

    function buy(uint256 _amount, uint256 _index) external payable registeredOnly eventOnly(Status.trade) {
        require(lots[_index].trader != address(0), "Cant find lot");
        require(_amount <= lots[_index].amount, "Amount exceeds allowed");
        require(msg.value == _amount * lots[_index].price, "Inctorrect ETH value");

        lots[_index].amount -= _amount;
        tradesPool += _amount;

        token.transfer(msg.sender, _amount);
        uint256 value = msg.value;
        for (uint256 i; i < 2; i++) {
            uint256 comission = msg.value * tradeReferralPercent / 1000;
            value -= comission;
            if (referrals[msg.sender].length > i) _transfer(referrals[msg.sender][i], comission);
        }
        _transfer(lots[_index].trader, value);

        if (lots[_index].amount == 0) {
            delete lots[_index];
            emit DelLot(_index);
        } else emit EditLot(lots[_index].amount, _index);
    }

    function _swithTrade() internal {
        status = Status.trade;
        endTime = block.timestamp + DURATION;
    }

    function swithEvent() external {
        require(endTime < block.timestamp, "Cant switch yet");
        if (status == Status.sale) _swithTrade();
        else {
            status = Status.sale;
            salePrice = salePrice * 103 / 100 + 4e6;
            salePool = tradesPool / salePrice;
            tradesPool = 0;
            endTime = block.timestamp + DURATION;
        }
    }

    function changeSaleRefPercents(uint256[2] memory _percents) external onlyDAO {
        require(_percents[0] + _percents[1] + 500 < 1000, "Incorrect values");
        saleReferralPercents = _percents;
    }

    function changeTradeRefPercent(uint256 _percent) external onlyDAO {
        require(_percent < 250, "Incorrect value");
        tradeReferralPercent = _percent;
    }

    function getComission(bool _agreement) external onlyDAO {
        if (_agreement) _transfer(owner, address(this).balance);
        else {
            uniswap.swapExactETHForTokens{ value: address(this).balance }(
                0,
                path,
                address(this),
                block.timestamp + 1e5
            );
        }
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20Mintable is IERC20 {
    function mint(address _account, uint _amount) external;
    function burn(address _account, uint _amount) external;
}

//SPDX-License-Identifier: MIT

pragma solidity >=0.6.2;

import "./IUniswapV2Router01.sol";

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

//SPDX-License-Identifier: MIT

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}