/**
 *Submitted for verification at Etherscan.io on 2023-02-21
*/

// https://gmcoin.wtf
// https://t.me/gmcoin_wtf
// https://discord.gg/QmHJ75ftB7
// https://twitter.com/gmcoin_wtf
// https://medium.com/@gm_59437
// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/utils/Context.sol
//     ______  ____    ____  
//   .' ___  ||_   \  /   _| 
//  / .'   \_|  |   \/   |   
//  | |   ____  | |\  /| |   
//  \ `.___]  |_| |_\/_| |_  
//   `._____.'|_____||_____| 
                         

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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

contract GM is Context, Ownable {
    using SafeMath for uint256;

    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => uint256) private _balances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcludedFromLimits;


    address payable private _feeWallet;
    address payable private _devWallet;
    address private _uniswapV2Pair;

    bool private _forceGM = false;
    bool private _inSwap = false;
    bool private _gm = false;

    string private constant _name = unicode"GM";
    string private constant _symbol = unicode"GM ☕";

    int8 private _timezone = -5;

    IUniswapV2Router02 private _uniswapV2Router;

    uint256 private _currentTaxPercent = 4;
    uint256 private _decimals = 8;
    uint256 private _devTaxPercent = 1;
    uint256 private _daytimeTaxPercent = 3;
    uint256 private _gmTaxPercent = 0;
    uint256 private _gmHourStart = 9;
    uint256 private _gmHourEnd = 11;
  
    
    uint256 private _currentTimestamp;
    uint256 private _tSupply = 100_000_000 * 10**_decimals;
  
    event GMUpdated(bool on);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);


    modifier lockTheSwap {
        _inSwap = true;
        _;
        _inSwap = false;
    }

    constructor () {

        // used to be in openTrading()
        _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(_uniswapV2Router), _tSupply);
        _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());

        _currentTimestamp                       = block.timestamp;
        _feeWallet                              = payable(0xD63117E111fD4e1AF8C41dDA991B19D2Cca80844);
        _devWallet                              = payable(0xD63117E111fD4e1AF8C41dDA991B19D2Cca80844);

        _balances[_msgSender()]                 = _tSupply;

        _isExcludedFromFee[owner()]             = true;
        _isExcludedFromFee[address(this)]       = true;
        _isExcludedFromFee[_feeWallet]          = true;
        _isExcludedFromFee[_devWallet]          = true;

        _isExcludedFromLimits[owner()]          = true;
        _isExcludedFromLimits[address(this)]    = true;
        _isExcludedFromLimits[_feeWallet]       = true;
        _isExcludedFromLimits[address(_uniswapV2Router)] = true;
        _isExcludedFromLimits[_uniswapV2Pair] = true;
        _isExcludedFromLimits[_devWallet] = true;

        

        _setTaxes();
       
        
        emit Transfer(address(0), _msgSender(), _tSupply);
    }
    // ~~~~~~~~~~~~ accessors ~~~~~~~~~~~~ \\

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint256) {
        return _decimals;
    }

    function totalSupply() public view returns (uint256) {
        return _tSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function feeWallet() public view returns (address) {
        return _feeWallet;
    }

    function gm() public view returns (bool) {
        return _gm;
    }

    function timezone() public view returns (int8) {
        return _timezone;
    }

    function currentTimestamp() public view returns (uint256) {
        return _currentTimestamp;
    }

    function taxPercent() public view returns (uint256) {
        return _currentTaxPercent;
    }


    function isExcludedFromFees(address a) public view returns (bool) {
        return _isExcludedFromFee[a];
    }

    function isExcludedFromLimits(address a) public view returns (bool) {
        return _isExcludedFromLimits[a];
    }

    function gmHourStart() public view returns (uint256) {
        return _gmHourStart;
    }

    function gmHourEnd() public view returns (uint256) {
        return _gmHourEnd;
    }

    function getOwner() public view returns (address) {
        return this.owner();
    }

    function getDevWallet() public view returns (address) {
        return _devWallet;
    }

    // ~~~~~~~~~~~~ mutators ~~~~~~~~~~~~ \\

    function setFeeWallet(address payable w) external {
        require(
            _msgSender() == _feeWallet || 
            _msgSender() == owner() ||
            _msgSender() == _devWallet);

        require(w != address(0), "Can't set fee wallet to burn addr.");
        _feeWallet = w;
    }

    function setDevWallet(address payable w) external {
        require(
            _msgSender() == _feeWallet || 
            _msgSender() == owner() ||
            _msgSender() == _devWallet);
        require(w != address(0), "Can't set dev wallet to burn addr.");
        _devWallet = w;
    }

    function setTimezone(int8 tz) external onlyOwner {
        /* changes the timezone where tz is interpreted as UTC-<tz>.
            parameters:
                tx (int8): a signed 8-bit int, used to represent when "morning" is.  
            
            returns:
                none
        */
        require(-12 < tz && tz < 13, "Timezone not recognized.");
        _timezone = tz;
    }

    function setTaxPercent(uint256 percent) external onlyOwner {
        /* sets the tax during the daytime (non-gm) period.
            parameters:
                percent (uint256): represents the % of the transaction given to the contract as taxes.
            
            returns:
                none
        */
        require(percent <= 3, "Maximum tax of 3%.");
        _daytimeTaxPercent = percent;
    }

    function setDevTaxPercent(uint256 percent) external onlyOwner {
        /* sets the dev tax pecent.
            parameters:
                percent (uint256): represents the % of the transaction given to the contract as taxes.
            
            returns:
                none
        */
        require(percent <= 2, "Maximum tax of 2%.");
        _devTaxPercent = percent;
    }

    function setGMHourStart(uint256 hour) external onlyOwner {
        /* sets the hour that gm mode starts at.
            parameters:
                hour (uint256): the hour to change the gm start time to.
            
            returns:
                none
        */
        require(hour < _gmHourEnd, "GM mode has to start before it ends.");
        _gmHourStart = hour;
    }

    function setGMHourEnd(uint256 hour) external onlyOwner {
        /* sets the hour that gm mode ends at.
            parameters:
                hour (uint256): the hour to change the gm end time to.
            returns:
                none
        */
        require(hour > _gmHourStart, "GM mode has to end after it starts.");
        _gmHourEnd = hour;
    }

    function setForceGM(bool on) external onlyOwner {
        /* set the _forceGM mode flag.
            parameters:
                on (bool): whether we want _forceGM mode active or not.
            returns:
                none
        */
        _forceGM = on;
    }

    
    // ~~~~~~~~~~~~ ierc20 functions ~~~~~~~~~~~~ \\

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }


    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    // ~~~~~~~~~~~~ custom functions ~~~~~~~~~~~~ \\

    function multisendToken( address[] memory addresses, uint256[] memory balances) external onlyOwner {
        
        for (uint8 i=0;i < addresses.length; i++) {
            _transferFeeless(owner(), addresses[i], balances[i]);
        }
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transferFeeless(address sender, address recipient, uint256 amount) private {
        /* transfers tokens without taking fees.
            parameters:
                sender (address):
                recipient (address):
                amount (uint256): the amount of tokens (keep in mind theres _decimals more digits than you think).
            returns:
                none
        */
        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _transferSupportingFee(address sender, address recipient, uint256 amount) private {
        /* transfers tokens while taking fees.
            parameters:
                sender (address):
                recipient (address):
                amount (uint256):
            returns:
                none
        */
        uint256 taxedTokens = amount.mul(_currentTaxPercent).div(100);
        uint256 amountRecieved = amount.sub(taxedTokens);

        // subtract amt from sender and add to recipient
        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amountRecieved);

        // handle taxes
        _balances[address(this)] = _balances[address(this)].add(taxedTokens);

        emit Transfer(sender, recipient, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) private {
        /* runs checks to ensure a valid transfer, then executes.
            first group of statements check that the zero address is not involved, and that the transfer amount is > 0.
            second group checks that a bot isn't involved (they aren't allowed to trade), and ensures trading has started.
            third group only applies when Uniswap is involved (buy/sell, not transfer) and when the involved addresses are not exempt from fees.
            the taxes are then set, which does the time check and sets the `_gm` flag.
            if: GM mode or there is an address exempt from fees involved,
                The helper function to transfer without fees is called.
            else:
                The contract balance of tokens is checked (using the ERC20.sol function balanceOf()), if its > 0, sell tokens.
                The helper function to transfer with fees is called.
            parameters:
                sender (address):
                recipient (address):
                amount (uint256):
            returns:
                none
        */


        // checks base transaction requirements
        require(sender != address(0), "ERC20: transfer from the zero address.");
        require(recipient != address(0), "ERC20: transfer to the zero address.");
        require(amount > 0, "Transfer amount must be greater than zero.");

      

        _setTaxes();
        
        //TODO: ensure an address cannot map to both bots and exemptfromfee.
        // if sender/reciever is excluded from fees or it is GM mode.
        if ((_isExcludedFromFee[sender] || _isExcludedFromFee[recipient]) || _gm) {
            _transferFeeless(sender, recipient, amount);
            return;
        }

        // ensure no transfer tax between addresses.
        if ((sender != _uniswapV2Pair && sender != address(_uniswapV2Router)) &&
            (recipient != _uniswapV2Pair && recipient != (address)(_uniswapV2Router))){
                _transferFeeless(sender, recipient, amount);
                return;
        }

        // handles the contract collecting fees.
        uint256 contractTokenBalance = balanceOf(address(this));
        if (!_inSwap && sender != _uniswapV2Pair && contractTokenBalance > 0) {
            swapTokensForEth(contractTokenBalance);
            uint256 contractETHBalance = address(this).balance;
            if (contractETHBalance > 0) {
                uint256 _feeAmt = contractETHBalance.mul(_currentTaxPercent.sub(_devTaxPercent)).div(_currentTaxPercent);
                uint256 _devAmt = contractETHBalance.mul(_devTaxPercent).div(_currentTaxPercent);
                _feeWallet.transfer(_feeAmt);
                _devWallet.transfer(_devAmt);
            }
        }


        // send the tokens
        _transferSupportingFee(sender, recipient, amount);
    }

    function _setTaxes() private {
        // sets GM mode and consequently, the tax rate.
        bool gmChanged = _setGM();

        if (gmChanged) {
            _currentTaxPercent = _gm ? (_gmTaxPercent + _devTaxPercent) : (_daytimeTaxPercent + _devTaxPercent);
        }
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniswapV2Router.WETH();
        _approve(address(this), address(_uniswapV2Router), tokenAmount);
        _uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function manualSwap() external {
        require(
            _msgSender() == _feeWallet || 
            _msgSender() == owner() ||
            _msgSender() == _devWallet);
        swapTokensForEth(balanceOf(address(this)));
    }

    function manualSend() external {
        require(
            _msgSender() == _feeWallet || 
            _msgSender() == owner() ||
            _msgSender() == _devWallet);

        _feeWallet.transfer(address(this).balance);
    }

    function forceGM(bool g) external onlyOwner {
        _gm = g;
    }



  
  
    function _setGM() private returns (bool) {
        _currentTimestamp = block.timestamp;
        uint256 hour = uint256(int(_currentTimestamp.div(3600))+_timezone).mod(24);

        // checks whether we are currently between the hours of GM.
        bool newGM = (_gmHourStart <= hour  && hour < _gmHourEnd);

        // if the _gm value changes, we emit an event and return true
        if (_gm != newGM) {
            _gm = newGM;
            emit GMUpdated(newGM);
            return true;
        }
        return false;
    }
    
    receive() external payable {}
}