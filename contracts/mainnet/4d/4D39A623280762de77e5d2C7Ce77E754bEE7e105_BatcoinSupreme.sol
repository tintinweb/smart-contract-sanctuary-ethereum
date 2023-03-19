/**
 *Submitted for verification at Etherscan.io on 2023-03-19
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;





//Initial Contracthttps://remix.ethereum.org/#lang=en&optimize=true&runs=200&evmVersion=null&version=soljson-v0.8.19+commit.7dd6d404.js
//Audit report: https://github.com/Bat0shi/Batcoin-Supreme_Smart-Contract/blob/main/BatcoinSupreme_AuditReport_InterFi.pdf
//Modified Contract; Audit report https://github.com/Bat0shi/Batcoin-Supreme_Smart-Contract/blob/main/BatcoinSupreme_AuditReport_InterFi%20(1).pdf

//                                                 𝟑𝟏𝟎𝟎𝟎𝟎𝟎𝟎

//            8888808D         A8808A     B8888888888   d88880N    A80808bA     888   N88A   NNN
//            888   88B       A8Y  Y8A        888      888        888    888    III   M888A  NNN
//            8888888K       8888O88889       888      888        888    888    808   M88 88VANM
//            888   88B     888      888      888      888        688    888    808   N88  888NN
//            8888880D     888        888     888       988880P    V980808V     B88   NNN   VMMM

//                                               🅢🅤🅟🅡🅔🅜🅔

// 𝙊𝙛𝙛𝙞𝙘𝙞𝙖𝙡 𝙒𝙚𝙗𝙨𝙞𝙩𝙚: 𝙬𝙬𝙬.𝙗𝙖𝙩𝙘𝙤𝙞𝙣𝙨𝙪𝙥𝙧𝙚𝙢𝙚.𝙘𝙤𝙢
// 𝘼𝙦𝙪𝙞𝙧𝙚𝙙 𝙛𝙤𝙧 𝙙𝙚𝙫𝙚𝙡𝙤𝙥𝙢𝙚𝙣𝙩 𝙙𝙤𝙢𝙖𝙞𝙣; 𝙬𝙬𝙬.𝙗𝙖𝙩𝙘𝙤𝙞𝙣𝙨𝙪𝙥𝙧𝙚𝙢𝙚.𝙤𝙧𝙜 𝙬𝙬𝙬.𝙗𝙖𝙩𝙘𝙤𝙞𝙣𝙨𝙪𝙥𝙧𝙚𝙢𝙚.𝙣𝙚𝙩

// Ŗ̷͇̙̰̭̪̟̺̲̜̹͔̎̍́ͅi̶̡̹͈͎̳̞͙͖̾̂̀͑̀͆̑̓̽̉͐͘͘ͅs̴̹̀̎̇͗̍͗̾̋̏̈͐͒̕͠͠ͅë̸͓̮͉͈͇͍̖͎̩̞͈́́́̋̇̾͋̈́̾͆͑͘͘͜͠͝ f̵̢̻͈̫̬̻͔̘̞͈̆̇̍̈̌͊ͅr̵̡͕͈͚͍͍̼͕̍̀̈́̽̎̍͗̍́̏̚͜͠ŏ̸̡̼̺̫̥̻͈̞̍͆̏̓́͜͝ͅm̵̢͕̫̓̔͑̊̈ Ḑ̷̮̳̣̟͉͋͗̓̕͜ǎ̴̯̀͠r̵̡͕͈͚͍͍̼͕̍̀̈́̽̎̍͗̍́̏̚͜͠k̵̘̺̦͉͖̪̪͖͉͊̆̔́̈́̍̃̈́͒̂̑̀̚͜͝ǹ̷̨͍̮̥̹̘͙̗̻̬̬̜̥̮̃̒̈́̽͗̿̍̄̂̏͆͠͝ë̸͓̮͉͈͇͍̖͎̩̞͈́́́̋̇̾͋̈́̾͆͑͘͘͜͠͝s̴̹̀̎̇͗̍͗̾̋̏̈͐͒̕͠͠ͅs̴̹̀̎̇͗̍͗̾̋̏̈͐͒̕͠͠ͅ.Ȩ̸̪̯̗̘̥̣̲̣̣͍͚͙̥̩́̀̈̆͑t̸̫̫̤͕̳̻̰̣̭́̌̉͝ͅë̸͓̮͉͈͇͍̖͎̩̞͈́́́̋̇̾͋̈́̾͆͑͘͘͜͠͝r̵̡͕͈͚͍͍̼͕̍̀̈́̽̎̍͗̍́̏̚͜͠ǹ̷̨͍̮̥̹̘͙̗̻̬̬̜̥̮̃̒̈́̽͗̿̍̄̂̏͆͠͝i̶̡̹͈͎̳̞͙͖̾̂̀͑̀͆̑̓̽̉͐͘͘ͅt̸̫̫̤͕̳̻̰̣̭́̌̉͝ͅy̶͔͗ B̶̨̛̺̤̱̾̀́̋̔̆̏̎͘͘ë̸͓̮͉͈͇͍̖͎̩̞͈́́́̋̇̾͋̈́̾͆͑͘͘͜͠͝ǧ̷̡̟̲̹̩̱͉̮̭͇͚̮̖̟̽̓͊̔̓̕i̶̡̹͈͎̳̞͙͖̾̂̀͑̀͆̑̓̽̉͐͘͘ͅǹ̷̨͍̮̥̹̘͙̗̻̬̬̜̥̮̃̒̈́̽͗̿̍̄̂̏͆͠͝s̴̹̀̎̇͗̍͗̾̋̏̈͐͒̕͠͠ͅ.



// ̸͖͓̯͓ B̠̬̲͉̱̠̌̅͠a̷̙̬͍̪̗̝̤̪͗̀ͫ̂͏̨̯̲̭͞t̵̡̠̘̙̮̥̯̰͈̼̯̜̄͋̔͆͂̇͝ͅo͇̬͎̪̻͉̞̞̗̠ͦ̎͂̃̑ͧ͘͜s̸̷͖̖̹̝̦̮̹̫̭̲͔̑͒ͭ̓̂̈̏͋̇̂̾h͚̬̲̘̥̮̘̣̭̰͓̖̗͐͋̒ͣ̆͗̊ͮ̏̑ͯ̈̉͟͢͢͞i̓͏͙̬̝ ̰͎̰͗ͩ̌̽̿̎̂N͚̘̖̻̓́a̷̷̙̬͍̪̗̝̤̪̺̺͙͗̀͐ͫͫ̃͟k͛ͨ̉̚a̷̙̬͍̪̗̝̤̪͕̩̠̬̪̟͗̀ͦ̎̂̄͂m̷̡̤̲̣̻̮̞̱͕̲̖ͧ̂͛̓̌͑ͬ̋̊̃͂͗̚͜ų̵̘͔͎̖͍͍̞͕̺ͫ̀ͮ̀̚͢͜ͅͅr̨̲̦̰̪̿̅̓̇̀̒̐͜͟a̷̙̬͍̪̗̝̤̪͗̀


/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    // function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDEXRouter {
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

interface IDividendDistributor {
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external;
    function setShare(address shareholder, uint256 amount) external;
    function deposit() external payable;
    function process(uint256 gas) external;
}

contract DividendDistributor is IDividendDistributor {
    using SafeMath for uint256;

    address _token;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    IBEP20 REWARDS = IBEP20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48); //Uses IBEP20 ERC20 Implementation Standard Contract
    address NATIVE = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    IDEXRouter router;

    address[] shareholders;
    mapping (address => uint256) shareholderIndexes;
    mapping (address => uint256) shareholderClaims;

    mapping (address => Share) public shares;

    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor = 10 ** 12;

    uint256 public minPeriod = 0 minutes;
    uint256 public minDistribution = 1* 10 ** 6;

    uint256 currentIndex;

    bool initialized;
    modifier initialization() {
        require(!initialized);
        _;
        initialized = true;
    }

    modifier onlyToken() {
        require(msg.sender == _token); _;
    }

    constructor (address _router) {
        router = _router != address(0)
            ? IDEXRouter(_router)
            : IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _token = msg.sender;
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external override onlyToken {
        minPeriod = _minPeriod;
        minDistribution = _minDistribution;
    }

    function setShare(address shareholder, uint256 amount) external override onlyToken {
        if(shares[shareholder].amount > 0){
            distributeDividend(shareholder);
        }

        if(amount > 0 && shares[shareholder].amount == 0){
            addShareholder(shareholder);
        }else if(amount == 0 && shares[shareholder].amount > 0){
            removeShareholder(shareholder);
        }

        totalShares = totalShares.sub(shares[shareholder].amount).add(amount);
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
    }

    function deposit() external payable override onlyToken {
        uint256 balanceBefore = REWARDS.balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = NATIVE;
        path[1] = address(REWARDS);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amount = REWARDS.balanceOf(address(this)).sub(balanceBefore);

        totalDividends = totalDividends.add(amount);
        dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(amount).div(totalShares));
    }

    function process(uint256 gas) external override onlyToken {
        uint256 shareholderCount = shareholders.length;

        if(shareholderCount == 0) { return; }

        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();

        uint256 iterations = 0;

        while(gasUsed < gas && iterations < shareholderCount) {
            if(currentIndex >= shareholderCount){
                currentIndex = 0;
            }

            if(shouldDistribute(shareholders[currentIndex])){
                distributeDividend(shareholders[currentIndex]);
            }

            gasUsed = gasUsed.add(gasLeft.sub(gasleft()));
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }
    }
    
    function shouldDistribute(address shareholder) internal view returns (bool) {
        return shareholderClaims[shareholder] + minPeriod < block.timestamp
                && getUnpaidEarnings(shareholder) > minDistribution;
    }

    function distributeDividend(address shareholder) internal {
        if(shares[shareholder].amount == 0){ return; }

        uint256 amount = getUnpaidEarnings(shareholder);
        if(amount > 0){
            totalDistributed = totalDistributed.add(amount);
            REWARDS.transfer(shareholder, amount);
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised = shares[shareholder].totalRealised.add(amount);
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
        }
    }
    
    function claimDividend() external {
        distributeDividend(msg.sender);
    }

    function getUnpaidEarnings(address shareholder) public view returns (uint256) {
        if(shares[shareholder].amount == 0){ return 0; }

        uint256 shareholderTotalDividends = getCumulativeDividends(shares[shareholder].amount);
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;

        if(shareholderTotalDividends <= shareholderTotalExcluded){ return 0; }

        return shareholderTotalDividends.sub(shareholderTotalExcluded);
    }

    function getCumulativeDividends(uint256 share) internal view returns (uint256) {
        return share.mul(dividendsPerShare).div(dividendsPerShareAccuracyFactor);
    }

    function addShareholder(address shareholder) internal {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

    function removeShareholder(address shareholder) internal {
        shareholders[shareholderIndexes[shareholder]] = shareholders[shareholders.length-1];
        shareholderIndexes[shareholders[shareholders.length-1]] = shareholderIndexes[shareholder];
        shareholders.pop();
    }
}

contract BatcoinSupreme is IBEP20, Ownable {
    using SafeMath for uint256; //contract uses both erc20 and bep20 implementation standard

    address REWARDS = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address NATIVE = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    string constant _name = "Batcoin Supreme";
    string constant _symbol = "Batcoin";
    uint8 constant _decimals = 8;
    uint256 _totalSupply = 31 * 10**6 * (10 ** _decimals);
    uint256 public _maxTxAmount = ( _totalSupply * 3 ) / 100;
    uint256 public _maxWalletToken = ( _totalSupply * 3 ) / 100;

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;
    mapping (address => bool) authorizations;

    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;
    mapping (address => bool) isTimelockExempt;
    mapping (address => bool) isDividendExempt;
    mapping (address => bool) isMaxWalletExempt;
    mapping (address => bool) isUtilityContract;

    uint256 liquidityFee    = 1;
    uint256 reflectionFee   = 1;
    uint256 marketingFee    = 4;
    uint256 public totalFee = 6;
    uint256 feeDenominator  = 100;

    address public autoLiquidityReceiver;
    address public marketingFeeReceiver;

    uint256 targetLiquidity = 10;
    uint256 targetLiquidityDenominator = 100;

    IDEXRouter public router;
    address public pair;

    uint256 public launchedAt;
    bool public tradingOpen = true;

    DividendDistributor distributor;
    uint256 distributorGas = 500000;

    bool public swapEnabled = true;
    uint256 public swapThreshold = _totalSupply / 10000;
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    constructor () {
        router = IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        pair = IDEXFactory(router.factory()).createPair(NATIVE, address(this));
        _allowances[address(this)][address(router)] = type(uint128).max;

        address _owner = msg.sender;
        
        authorizations[_owner] = true;
        distributor = new DividendDistributor(address(router));

        isFeeExempt[_owner] = true;
        isTxLimitExempt[_owner] = true;
        isMaxWalletExempt[_owner] =  true;

        isTimelockExempt[_owner] = true;
        isTimelockExempt[DEAD] = true;
        isTimelockExempt[address(this)] = true;

        isDividendExempt[pair] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[DEAD] = true;

        autoLiquidityReceiver = _owner;
        marketingFeeReceiver = _owner;

        _balances[_owner] = _totalSupply;
        emit Transfer(address(0), _owner, _totalSupply);
    }

    receive() external payable { }

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    // function getOwner() external view override returns (address) { return owner; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != type(uint128).max){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "You don't have enough allowance.");
        }

        return _transferFrom(sender, recipient, amount);
    }

     function setMaxWalletPercent(uint256 maxWallPercent) external onlyOwner() {
        _maxWalletToken = (_totalSupply * maxWallPercent ) / 100;
    }

    function setIsUtilityContract(address _address, bool _trueorfalse) external onlyOwner(){
        isUtilityContract[_address] = _trueorfalse;
        isMaxWalletExempt[_address] = _trueorfalse;
        isTxLimitExempt[_address] = _trueorfalse;
        isFeeExempt[_address] = _trueorfalse;
        isDividendExempt[_address] = _trueorfalse;
    }

    function setIsMaxWalletExepmt(address _address, bool _trueorfalse) external onlyOwner(){
        isMaxWalletExempt[_address] = _trueorfalse;
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {

        if(inSwap){ return _basicTransfer(sender, recipient, amount); }

        if(!authorizations[sender] && !authorizations[recipient]){
            require(tradingOpen,"Trading not open yet");
        }

        if (!authorizations[sender] && !isMaxWalletExempt[recipient] && !isUtilityContract[sender] && recipient != address(this) && recipient != address(DEAD) && recipient != pair && recipient != marketingFeeReceiver && recipient != autoLiquidityReceiver){
            uint256 heldTokens = balanceOf(recipient);
            require((heldTokens + amount) <= _maxWalletToken,"Recipient can't hold more than Max Wallet!");}

        checkTxLimit(sender, amount);

        if(shouldSwapBack()){ swapBack(); }

        _balances[sender] = _balances[sender].sub(amount, "You don't have enough tokens.");

        uint256 amountReceived = shouldTakeFee(sender, recipient) ? takeFee(sender, amount) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);

        if(!isDividendExempt[sender]) {
            try distributor.setShare(sender, _balances[sender]) {} catch {}
        }

        if(!isDividendExempt[recipient]) {
            try distributor.setShare(recipient, _balances[recipient]) {} catch {} 
        }

        try distributor.process(distributorGas) {} catch {}

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }
    
    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "You don't have enough tokens.");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function checkTxLimit(address sender, uint256 amount) internal view {
        require(amount <= _maxTxAmount || isTxLimitExempt[sender], "You can't transfer more than Tx Limit.");
    }

    function shouldTakeFee(address sender, address recipient) internal view returns (bool) {
        if(isUtilityContract[recipient]){
            return false;
        }else{
            return !isFeeExempt[sender];
        }
    }

    function takeFee(address sender, uint256 amount) internal returns (uint256) {
        uint256 feeAmount = amount.mul(totalFee).div(feeDenominator);

        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);

        return amount.sub(feeAmount);
    }

    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != pair
        && !inSwap
        && swapEnabled
        && _balances[address(this)] >= swapThreshold;
    }

    function clearStuckBalance(uint256 amountPercentage) external onlyOwner {
        uint256 amountNATIVE = address(this).balance;
        payable(marketingFeeReceiver).transfer(amountNATIVE * amountPercentage / 100);
    }

    function tradingStatus(bool _status) public onlyOwner {
        tradingOpen = _status;
    }

    function swapBack() internal swapping {
        uint256 dynamicLiquidityFee = isOverLiquified(targetLiquidity, targetLiquidityDenominator) ? 0 : liquidityFee;
        uint256 amountToLiquify = swapThreshold.mul(dynamicLiquidityFee).div(totalFee).div(2);
        uint256 amountToSwap = swapThreshold.sub(amountToLiquify);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = NATIVE;

        uint256 balanceBefore = address(this).balance;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountNATIVE = address(this).balance.sub(balanceBefore);

        uint256 totalNATIVEFee = totalFee.sub(dynamicLiquidityFee.div(2));
        
        uint256 amountNATIVELiquidity = amountNATIVE.mul(dynamicLiquidityFee).div(totalNATIVEFee).div(2);
        uint256 amountNATIVEReflection = amountNATIVE.mul(reflectionFee).div(totalNATIVEFee);
        uint256 amountNATIVEMarketing = amountNATIVE.mul(marketingFee).div(totalNATIVEFee);

        try distributor.deposit{value: amountNATIVEReflection}() {} catch {}
        (bool tmpSuccess,) = payable(marketingFeeReceiver).call{value: amountNATIVEMarketing, gas: 30000}("");
        tmpSuccess = false;

        if(amountToLiquify > 0){
            router.addLiquidityETH{value: amountNATIVELiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                autoLiquidityReceiver,
                block.timestamp
            );
            
            emit AutoLiquify(amountNATIVELiquidity, amountToLiquify);
        }
    }

    function setTxLimit(uint256 amount) external onlyOwner {
        _maxTxAmount = amount;
    }

    function setIsDividendExempt(address holder, bool exempt) external onlyOwner {
        require(holder != address(this) && holder != pair);
        isDividendExempt[holder] = exempt;
        if(exempt){
            distributor.setShare(holder, 0);
        }else{
            distributor.setShare(holder, _balances[holder]);
        }
    }

    function setIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
    }

    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) external onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            isFeeExempt[accounts[i]] = excluded;
        }
    }

    function setIsTxLimitExempt(address holder, bool exempt) external onlyOwner {
        isTxLimitExempt[holder] = exempt;
    }

    function setIsTimelockExempt(address holder, bool exempt) external onlyOwner {
        isTimelockExempt[holder] = exempt;
    }

    function setFees(uint256 _liquidityFee, uint256 _reflectionFee, uint256 _marketingFee, uint256 _feeDenominator) external onlyOwner {
        liquidityFee = _liquidityFee;
        reflectionFee = _reflectionFee;
        marketingFee = _marketingFee;
        totalFee = _liquidityFee.add(_reflectionFee).add(_marketingFee);
        feeDenominator = _feeDenominator;
        require(totalFee < feeDenominator/4);
    }

    function setFeeReceivers(address _autoLiquidityReceiver, address _marketingFeeReceiver) external onlyOwner {
        autoLiquidityReceiver = _autoLiquidityReceiver;
        marketingFeeReceiver = _marketingFeeReceiver;
    }

    function setSwapBackSettings(bool _enabled, uint256 _amount) external onlyOwner {
        swapEnabled = _enabled;
        swapThreshold = _amount;
    }

    function setTargetLiquidity(uint256 _target, uint256 _denominator) external onlyOwner {
        targetLiquidity = _target;
        targetLiquidityDenominator = _denominator;
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external onlyOwner {
        distributor.setDistributionCriteria(_minPeriod, _minDistribution);
    }

    function setDistributorSettings(uint256 gas) external onlyOwner {
        require(gas < 750000);
        distributorGas = gas;
    }
    
    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }

    function getLiquidityBacking(uint256 accuracy) public view returns (uint256) {
        return accuracy.mul(balanceOf(pair).mul(2)).div(getCirculatingSupply());
    }

    function isOverLiquified(uint256 target, uint256 accuracy) public view returns (bool) {
        return getLiquidityBacking(accuracy) > target;
    }

    event AutoLiquify(uint256 amountNATIVE, uint256 amountNAME);
}

// 8080808080808080808080808080808080808080808080 LEGAL DISCLAIMER 0808080808080808080808080808080808080808080808080
// This is a decentralzed development project and open to any posibilities. When trading is open, this will be 
// highly volatile and must trade at your own risk. You agree that you are not purchasing batcoin token a security 
// or investment. The Batcoin Supreme Core cannot be held liable for any losses or taxes you may incur. You also agree that 
// the Core is presenting the token smart contract as it was launched with burned liquidity and audited, but not renounced.
// This project aspire for development, where ideas and contributions will change over time, Conduct your own due diligence 
// and consult your financial advisor before making any investment and decisions. The platform and team will not and do not 
// intend to make any representations, guarantees, and commitments to any entity or individual and hereby assume no responsibility 
// (including but not limited to the accuracy, completeness, timeliness, and reliability of the smart contract code, future dapp, 
// content and any other material content published on the platform).
// 101010101010101010101010101010101001010🅑🅐🅣🅒🅞🅘🅝010🅢🅤🅟🅡🅔🅜🅔010🅒🅞🅡🅔1010101001101101000101001010110001101010101010110101010110