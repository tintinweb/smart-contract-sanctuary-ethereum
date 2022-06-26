//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./uniswap/IUniswapV2Router02.sol";
import "./ERC20/InterfaceERC20.sol";
import "./interfaces/IDAO.sol";

contract ACDMPlatform {
    enum RoundType { SELL, TRADE }

    address public owner;
    address public wethAddress;
    IUniswapV2Router02 public uniswapV2Router;

    // 5%
    uint public firstReferralSell = 5;
    // 3%
    uint public secondReferralSell = 3;
    // 2.5%
    uint public referralTrade = 25;
    
    Round public currentRound;
    uint public charity;
    // price of one ACDM wei in ETH wei
    uint public currectPrice;
    uint public numberToken;
    // trading volume
    uint public tradeValue;
    InterfaceERC20 private token;
    InterfaceERC20 private tokenCharity;
    IDAO private dao;
    mapping(address => User) private users;

    // account address to value of trade(acdm wei tokens)
    mapping(address => Trade) private trades;

    struct Round {
        RoundType round;
        uint startAt;
    }

    struct User {
        bool registrated;
        address referralFirst;
        address referralSecond;
    }

    struct Trade {
        uint numberWeiToken;
        uint priceOneWeiToken;
    }

    modifier SellRound(){
        require(currentRound.round == RoundType.SELL, "not sell round");
        require(currentRound.startAt + 3 days >= block.timestamp, "round already ended");
        _;
    }

    modifier TradeRound(){
        require(currentRound.round == RoundType.TRADE, "not trade round");
        require(currentRound.startAt + 3 days >= block.timestamp, "round already ended");
        _;
    }

    modifier onlyRegistrated() {
        require(users[msg.sender].registrated, "not registrated");
        _;
    }

    modifier onlyOwner(){
        require(msg.sender == owner, "not an owner");
        _;
    }

    modifier onlyDAO(){
        require(msg.sender == address(dao), "not DAO");
        _;
    }

    constructor(InterfaceERC20 _token, InterfaceERC20 _tokenCharity, IUniswapV2Router02 _uniswapV2Router, address _wethAddress){
        wethAddress = _wethAddress;
        owner = msg.sender;
        uniswapV2Router = _uniswapV2Router;
        tokenCharity = _tokenCharity;
        token = _token;
    }

    function DURATIONROUND() external pure returns(uint256) {
        return 3 days;
    }

    function startPatform() external onlyOwner {
        numberToken = 100000 * (10 ** token.decimals());
        token.mint(address(this), numberToken);
        currectPrice = 10 ** 7 wei;
        currentRound.round = RoundType.SELL;
        currentRound.startAt = block.timestamp;
        tradeValue = 0;
        charity = 0;
    }

    function setDAO(IDAO _dao) public onlyOwner {
        require(address(dao) == address(0), "already set");
        dao = _dao;
    }

    function registration(address referralFirst, address referralSecond) public {
        require(!users[msg.sender].registrated, "already registrated");
        require(referralFirst == address(0) || users[referralFirst].registrated, "first referral not registrated");
        require(referralSecond == address(0) || users[referralSecond].registrated, "second referral not registrated");
        users[msg.sender].registrated = true;
        if (referralFirst == address(0) && referralSecond != address(0)){
            referralFirst = referralSecond;
            referralSecond = address(0);
        }
        users[msg.sender].referralFirst = referralFirst;
        users[msg.sender].referralSecond = referralSecond;
    }

    function buyToken(uint amount) public payable SellRound onlyRegistrated{
        require(msg.value >= amount * currectPrice, "not enough funds");
        uint actualAmount = min(amount, numberToken);
        uint refund = msg.value - currectPrice * actualAmount;
        numberToken -= actualAmount;
        if (refund > 0) {
            payable(msg.sender).transfer(refund);
        }
        if (users[msg.sender].referralFirst != address(0)){
            payable(users[msg.sender].referralFirst).transfer((msg.value - refund) * firstReferralSell / 100);
        }
        if (users[msg.sender].referralSecond != address(0)){
            payable(users[msg.sender].referralSecond).transfer((msg.value - refund) * secondReferralSell / 100);
        }
        token.transfer(msg.sender, actualAmount);
        if (numberToken == 0){
            updateRound();
        }
    }

    function setTrade(uint numberWeiToken, uint priceOneWeiToken) public TradeRound onlyRegistrated{
        require(token.balanceOf(msg.sender) >= numberWeiToken, "not enough tokens");
        token.transferFrom(msg.sender, address(this), numberWeiToken);
        trades[msg.sender].priceOneWeiToken = priceOneWeiToken;
        trades[msg.sender].numberWeiToken += numberWeiToken;
    }

    function closeTrade() public TradeRound onlyRegistrated{
        uint numberTokenClose = trades[msg.sender].numberWeiToken;
        trades[msg.sender].numberWeiToken = 0;
        token.transfer(msg.sender, numberTokenClose);
    }

    function buyTrade(address seller, uint numberWeiToken) public payable TradeRound onlyRegistrated{
        require(trades[seller].numberWeiToken >= numberWeiToken, "not enough tokens");
        uint actualNumberWeiToken = min(numberWeiToken, msg.value / trades[seller].priceOneWeiToken);
        uint refund = msg.value - actualNumberWeiToken * trades[seller].priceOneWeiToken;
        if (refund > 0) {
            payable(msg.sender).transfer(refund);
        }
        tradeValue += msg.value - refund;
        token.transfer(msg.sender, actualNumberWeiToken);
        uint payed = (msg.value - refund) * 95 / 100;
        payable(seller).transfer((msg.value - refund) * 95 / 100);
        if (users[seller].referralFirst != address(0)) {
            payable(users[seller].referralFirst).transfer((msg.value - refund) * referralTrade / 1000);
            payed += (msg.value - refund) * referralTrade / 1000;
        }
        if (users[seller].referralSecond != address(0)) {
            payable(users[seller].referralSecond).transfer((msg.value - refund) * referralTrade / 1000);
            payed += (msg.value - refund) * referralTrade / 1000;
        }
        charity += msg.value - payed;
    }

    function updateRound() public onlyRegistrated{
        require(currentRound.startAt + 3 days <= block.timestamp || (currentRound.round == RoundType.SELL && numberToken == 0), "not ended yet");
        if (currentRound.round == RoundType.TRADE) {
            if (tradeValue == 0) {
                currentRound.startAt = block.timestamp;
            } else {
                currentRound.round = RoundType.SELL;
                currentRound.startAt = block.timestamp;
                tradeValue = 0;
                currectPrice = currectPrice * 103 / 100 + 4;
                numberToken = tradeValue / currectPrice * token.decimals();
                token.mint(address(this), tradeValue / currectPrice * token.decimals());
            }
        } else {
            token.burn(address(this), numberToken);
            currentRound.round = RoundType.TRADE;
            currentRound.startAt = block.timestamp;
        }
    }

    function changeFirstReferralSell(uint newFirstReferralSell) public onlyDAO {
        firstReferralSell = newFirstReferralSell;
    }

    function changeSecondReferralSell(uint newSecondReferralSell) public onlyDAO {
        secondReferralSell = newSecondReferralSell;
    }

    function changeReferralTrade(uint newReferralTrade) public onlyDAO {
        referralTrade = newReferralTrade;
    }
    
    // 0 means give it to owner
    // 1 means buy and burn XXX token
    function spendCharity(uint256 res) public onlyDAO {
        require(res == 0 || res == 1, "wrong value");
        if (res == 0) {
            payable(owner).transfer(charity);
        } else {
            address[] memory pair = new address[](2);
            pair[0] = wethAddress;
            pair[1] = address(tokenCharity);
            uint256[] memory actualAmount = uniswapV2Router.getAmountsOut(charity, pair);
            IUniswapV2Router02(uniswapV2Router).swapExactETHForTokens{ value: charity }( 
                actualAmount[1],
                pair,
                msg.sender,
                block.timestamp
            );
            tokenCharity.burn(address(this), tokenCharity.balanceOf(address(this)));
        }
        charity = 0;
    }

    function min(uint a, uint b) internal pure returns(uint){
        if (a <= b) {
            return a;
        } else{
            return b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface InterfaceERC20 is IERC20 {
    function giveAdminRole(address newAdmin) external;
    function name() external view returns(string memory);
    function symbol() external view returns(string memory);
    function decimals() external view returns(uint8);

    function burn(address account, uint256 amount) external;
    function mint(address account, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDAO {
    function getBalance() external view returns(uint256);

    function getFrozenBalance() external view returns(uint256);

    function addChairMan(address account) external;

    function addDAO(address account) external;

    function setMinimumQuorum(uint256 newMinimumQuorum) external;

    function setDebatingPeriodDuration(uint256 newDebatingPeriodDuration) external;

    function deposit(uint256 funds) external;

    function addProposal(bytes memory callData, address recipient, string memory description) external;

    function vote(uint256 votingId, bool voteValue) external;

    function finishProposal(uint256 votingId) external;

    function withdraw() external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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