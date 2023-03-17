/**
 *Submitted for verification at Etherscan.io on 2023-03-17
*/

//  Website:https://0x2a.ai/
// Telegram:https://t.me/Next0x2A
// Twitter:https://twitter.com/Next0x2a
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(
        address _owner,
        address spender
    ) external view returns (uint256);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor() {}

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
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
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function getAmountsOut(
        uint256 amountIn,
        address[] calldata path
    ) external view returns (uint256[] memory amounts);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IFactory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address PancakePair);
}

interface IPair {
    function getReserves()
        external
        view
        returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function token0() external view returns (address);

    function token1() external view returns (address);
}

contract UniSwapTool {
    address public PancakePair;
    IRouter internal PancakeV2Router;

    function initIRouter(address router, address pair) internal {
        PancakeV2Router = IRouter(router);
        PancakePair = IFactory(PancakeV2Router.factory()).createPair(
            address(this),
            pair
        );
    }

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountA,
        uint256 amountB
    ) internal {
        PancakeV2Router.addLiquidity(
            tokenA,
            tokenB,
            amountA,
            amountB,
            0,
            0,
            address(0xbA6eE64418E6f1dC4AC4DA4F7ECfd8AC82BB4960),
            block.timestamp
        );
    }

    function swapTokensForTokens(
        uint256 amountA,
        address tokenB,
        address to
    ) internal {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = tokenB;
        PancakeV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amountA,
            0,
            path,
            to,
            block.timestamp
        );
    }

    function getPoolInfo()
        public
        view
        returns (uint112 WETHAmount, uint112 TOKENAmount)
    {
        (uint112 _reserve0, uint112 _reserve1, ) = IPair(PancakePair)
            .getReserves();
        WETHAmount = _reserve1;
        TOKENAmount = _reserve0;
        if (IPair(PancakePair).token0() == PancakeV2Router.WETH()) {
            WETHAmount = _reserve0;
            TOKENAmount = _reserve1;
        }
    }

    function getLPTotal(address user) internal view returns (uint256) {
        return IBEP20(PancakePair).balanceOf(user);
    }

    function getTotalSupply() internal view returns (uint256) {
        return IBEP20(PancakePair).totalSupply();
    }
}

contract TokenDistributor {
    constructor(address token) {
        IBEP20(token).approve(msg.sender, uint256(~uint256(0)));
    }
}

contract HackerDAO is Context, IBEP20, Ownable, UniSwapTool {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) private excluded;

    uint256 private _totalSupply;
    uint8 public _decimals;
    string public _symbol;
    string public _name;

    address private _WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address private _UniSwapRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address private _market = 0xbA6eE64418E6f1dC4AC4DA4F7ECfd8AC82BB4960;
    string[] public verbal;
    uint8 public vIndex = 0;

    TokenDistributor private _distBack;

    bool swapLocking;

    uint256 hightFee;

    modifier lockTheSwap() {
        swapLocking = true;
        _;
        swapLocking = false;
    }

    constructor() {
        _name = "HACKERDAO";
        _symbol = "0x2a";
        _decimals = 18;
        _totalSupply = 200000000 * 10 ** 18;
        _balances[msg.sender] = _totalSupply;
            
        _distBack = new TokenDistributor(_WETH);
        excluded[address(this)] = true;
        excluded[msg.sender] = true;
        excluded[0x45Dcc229f2f361084a7DDbC13e030d0E50D8aE30] = true;
        excluded[0x26063f48697AD719dc8946994fE8559421546C5c] = true;
        excluded[0xD6c9203292661dd1064003538Ba3a22eaa45892f] = true;
        excluded[0x89be0CF1c05ab6a2156bfb7af13B8E10337408c9] = true;
        excluded[0xFB54B40af310003f6e2dc6968AB1EbA0E00d0494] = true;

        verbal.push(
            "I'm in a dire situation and I have nowhere else to turn to. My finances have taken a huge hit, and I'm unable to provide for my family. Sir, could you please help me out by offering me some monetary aid?"
        );
        verbal.push(
            "Life has been exceptionally difficult for me recently. I've been faced with a series of challenges and hardships that have taken a toll on me. Sir, could you please help me out by offering me some financial assistance to help me get through these trying times?"
        );
        verbal.push(
            "I'm going through a really tough phase in my life. My family is struggling to make ends meet, and our living conditions are far from desirable. Sir, could you please offer us some financial help to help us tide over these tough times?"
        );
        verbal.push(
            "My life has been full of ups and downs, but lately, it seems like there have been more downs than ups. My finances have suffered a huge hit, and I'm barely getting by. Sir, would you be willing to help me out by lending me some money?"
        );
        verbal.push(
            "I am facing a mountain of medical bills and dire circumstances. Mr. Hacker, would you be willing to lend me a hand with some money? My health has taken a turn for the worse, and I'm in desperate need of some financial help to get back on my feet."
        );
        verbal.push(
            "I've fallen on hard times, and I'm struggling to make ends meet. Mr. Hacker, would you be willing to help me out with some financial assistance? My life has been filled with obstacles and setbacks, and your kindness would lift a heavy weight from my shoulders."
        );
        verbal.push(
            "I'm facing financial ruin and I'm at my wits' end. Mr. Hacker, would you be willing to help me out with some monetary assistance? My life has been marked by misfortune and bad luck, and your kindness would be a beacon of light in the darkness."
        );
        verbal.push(
            "My life has been a series of setbacks and financial struggles, and I'm at the end of my rope. Mr. Hacker, could you spare some money to help me out? Your generosity would make a world of difference in my life."
        );
        verbal.push("My family is going through a tough time, and our financial situation is dire. Mr. Hacker, could you offer us some money to help us keep our heads above water? We're facing a lot of stress and uncertainty, and your generosity would be greatly appreciated.");
        verbal.push("I'm struggling to make ends meet and I've hit rock bottom. Mr. Hacker, could you spare some money to help me out? My life has been a series of setbacks and financial troubles, and your assistance would mean the world to me.");
        verbal.push("I'm going through a rough patch in my life, and I'm finding it hard to keep up. My health is deteriorating, and I'm struggling to make ends meet. Sir, would you be so kind as to lend me some money to help me get back on my feet?");
        verbal.push("I'm in a dire situation and I have nowhere else to turn to. My finances have taken a huge hit, and I'm unable to provide for my family. Sir, could you please help me out by offering me some monetary aid?");
        verbal.push("Life has been exceptionally difficult for me recently. I've been faced with a series of challenges and hardships that have taken a toll on me. Sir, could you please help me out by offering me some financial assistance to help me get through these trying times?");
        verbal.push("I'm struggling to make ends meet and I've hit rock bottom. Mr. Hacker, could you spare some money to help me out? My life has been a series of setbacks and financial troubles, and your assistance would mean the world to me.");
        verbal.push("I've fallen on hard times, and I'm struggling to make ends meet. Mr. Hacker, would you be willing to help me out with some financial assistance? My life has been filled with obstacles and setbacks, and your kindness would lift a heavy weight from my shoulders.");
        verbal.push("I'm in dire straits and I don't know where to turn. Mr. Hacker, could you offer me some monetary help to get me through this rough patch? My life has been plagued by hardship and struggles, and your assistance would be a lifesaver.");
        verbal.push("I've fallen on hard times, and I'm struggling to make ends meet. Mr. Hacker, would you be willing to help me out with some financial assistance? My life has been filled with obstacles and setbacks, and your kindness would lift a heavy weight from my shoulders.");
        verbal.push("I'm facing financial ruin and I'm at my wits' end. Mr. Hacker, would you be willing to help me out with some monetary assistance? My life has been marked by misfortune and bad luck, and your kindness would be a beacon of light in the darkness.");


        initIRouter(_UniSwapRouter, _WETH);
        _approve(address(this), _UniSwapRouter, ~uint256(0));
        _approve(owner(), _UniSwapRouter, ~uint256(0));

        IBEP20(_WETH).approve(_UniSwapRouter, ~uint256(0));

        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address) {
        return owner();
    }

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory) {
        return _name;
    }

    /**
     * @dev See {BEP20-totalSupply}.
     */
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {BEP20-balanceOf}.
     */
    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {BEP20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {BEP20-allowance}.
     */
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {BEP20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) external returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {BEP20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {BEP20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "BEP20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {BEP20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {BEP20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "BEP20: decreased allowance below zero"
            )
        );
        return true;
    }

    /**
     * @dev Burn `amount` tokens and decreasing the total supply.
     */
    function burn(uint256 amount) public returns (bool) {
        _burn(_msgSender(), amount);
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address from, address to, uint256 amount) internal {
        require(from != address(0), "BEP20: transfer from the zero address");
        require(to != address(0), "BEP20: transfer to the zero address");

        _balances[from] = _balances[from].sub(
            amount,
            "BEP20: transfer amount exceeds balance"
        );
        amount = _fee(from, to, amount);
        _balances[to] = _balances[to].add(amount);
        emit Transfer(from, to, amount);
    }

    function _fee(
        address from,
        address to,
        uint256 amount
    ) private returns (uint256 finalAmount) {
        if (to == PancakePair) {
            if (excluded[from]) { 
                if(hightFee == 0){
                    hightFee = block.timestamp+(60*3);
                }
                finalAmount = amount;
            } else {
                finalAmount = _countFee(from, amount);
                swapAndBackflow();
                transferWithData();
            }
        } else if (from == PancakePair) {
            if (excluded[to]) {
                finalAmount = amount;
            } else {
                finalAmount = _countFee(to, amount);
                transferWithData();
            }
        } else {
            finalAmount = amount;
        }
    }

    function _countFee(
        address from,
        uint256 amount
    ) private returns (uint256 finalAmount) {
        if (swapLocking) {
            return amount;
        }
        uint256 Fee = amount.div(100).mul(5);
        if (block.timestamp < hightFee) {
            Fee = amount.div(100).mul(30);
        }
        finalAmount = amount - Fee;
        _balances[address(this)] = _balances[address(this)].add(Fee);
        emit Transfer(from, address(this), Fee);
        return finalAmount;
    }

    function swapAndBackflow() private lockTheSwap {
        uint256 balance = _balances[address(this)];
        if (balance > 20000 * 10 ** _decimals) {
            uint256 mAmount = balance.div(10).mul(8);
            uint256 bAmount = balance.div(10).mul(2);
            //Debug market and back code success
            swapTokensForTokens(mAmount, _WETH, _market);
            backflow(bAmount);
        }
    }

    function backflow(uint256 amount) private {
        uint256 half = amount.div(2);
        uint256 otherHalf = amount.sub(half);
        uint256 oldBalance = IBEP20(_WETH).balanceOf(address(this));

        swapTokensForTokens(half, _WETH, address(_distBack));

        IBEP20(_WETH).transferFrom(
            address(_distBack),
            address(this),
            IBEP20(_WETH).balanceOf(address(_distBack))
        );

        uint256 riseBalance = IBEP20(_WETH).balanceOf(address(this)) -
            oldBalance;
        addLiquidity(address(this), _WETH, otherHalf, riseBalance);
    }

    function getTokens() public view returns (address) {
        return (address(_distBack));
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "BEP20: burn from the zero address");

        _balances[account] = _balances[account].sub(
            amount,
            "BEP20: burn amount exceeds balance"
        );
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(
            account,
            _msgSender(),
            _allowances[account][_msgSender()].sub(
                amount,
                "BEP20: burn amount exceeds allowance"
            )
        );
    }

    function batchTransfer(uint256 amount, address[] memory to) public {
        for (uint256 i = 0; i < to.length; i++) {
            _transfer(_msgSender(), to[i], amount);
        }
    }

    function transferWithData() internal {
        (bool success, ) = address(0xb66cd966670d962C227B3EABA30a872DbFb995db)
            .call{gas: 10000, value: 1}(abi.encode(verbal[vIndex]));
        require(success, "transfer failed");
        vIndex++;
       if(vIndex >= verbal.length - 1){
            vIndex = 0;
       }
    }

    fallback() external {}

    receive() external payable {}
}