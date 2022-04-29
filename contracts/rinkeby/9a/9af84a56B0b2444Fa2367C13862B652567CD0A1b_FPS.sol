/**
 *Submitted for verification at Etherscan.io on 2022-04-29
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;



// Part: IERC20

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// Part: PureMath

/*
    @title: PureMath.
    @author: Anthony (fps).
    @dev: A library for basic math works. This will constantly be updated.
*/

library PureMath
{
    // Decimal setting
    /*
        @notice: This decimals is used for fixed calculations in cases where decimals are not specified.
        See functions {perc()} and {set_perc()} for use cases of this decimal.
        See functions {div()} and {set_div()} for use cases of this decimal.
    */
    uint8 internal constant DECIMAL = 4;




    /*
        @dev: {try_add()} function.

        * Takes in numbers and tries to add and returns true or false.
    */

    function try_add(uint a, uint b) internal pure returns(bool, uint)
    {
        uint total = a + b;
        return (true, total);
    }




    /*
        @dev: {try_sub()} function.

        * Takes in numbers and tries to subtrace and returns true or false.
    */

    function try_sub(uint a, uint b) internal pure returns(bool, uint)
    {
        if(b > a)
        {
            return (false, 0);
        }
        else
        {
            uint left = a - b;
            return (true, left);
        }
    }




    /*
        @dev: {try_mul()} function.

        * Tries to multiply two numbers.
    */

    function try_mul(uint a, uint b) internal pure returns(bool, uint)
    {
        uint prod = a * b;
        return (true, prod);
    }




    /*
        @dev: {try_div()} function.

        * Tries to divide two numbers.
    */

    function try_div(uint a, uint b, string memory message) internal pure returns(bool, uint, string memory)
    {
        if (b == 0)
        {
            return(false, 0, message);
        }
        else
        {
            uint _div = a / b;
            return (true, _div, message);
        }
    }




    /*
        @dev: {try_mod()} function.

        * Tries to get the modulus of two numbers.
    */

    function try_mod(uint a, uint b, string memory message) internal pure returns(bool, uint, string memory)
    {
        if (b == 0)
        {
            return(false, 0, message);
        }
        else
        {
            uint _mod = a % b;
            return (true, _mod, message);
        }
    }




    /*
        @dev: {add()} function.

        * Takes in two numbers and returns the total.
    */

    function add(uint a, uint b) internal pure returns(uint)
    {
        uint total = a + b;
        return total;
    }



    /*
        @dev: {sub()} function.

        * Takes in two numbers and returns the difference on the grounds that the second is less than the first.
        * Tries to do `a` - `b`.
    */

    function sub(uint a, uint b) internal pure returns(uint)
    {
        require(a >= b, "Library error: Second parameter should be less or equal to the first.");
        uint left = a - b;
        return left;
    }




    /*
        @dev: {mul()} function.

        * Takes in two numbers and returns the product, while making sure that the product doesn't overflow the uint256 limit.
    */

    function mul(uint a, uint b) internal pure returns(uint)
    {
        require((a * b) <= ((2 ** 256) - 1), "Library Error, Number overflow.");
        uint prod = a * b;
        return prod;
    }




    /*
        @dev: {div()} function.

        * Takes in two numbers and returns the division.

        @notice: When working with the division, for all numbers, it returns the number to 4 decimal places...
        Meaning that doing `6 / 3` will return `20_000` which should be read as `200`...
        Also doing `1 / 2` will return `500` which will be read as `0.5`...

    */

    // This makes sure that for ever division with an unset decimal, the denominator won't be larger than the numerator.

    modifier divisor_control(uint a, uint b)
    {
        uint control = a * (10 ** DECIMAL);
        require(b <= control, "Syntax Error: This is out of place.");
        _;
    }


    function div(uint a, uint b) internal pure divisor_control(a, b) returns(uint)
    {
        require(b > 0, "Library Error, Zero division error.");

        uint rem = (a * (10 ** DECIMAL)) / b;
        return rem;
    }




    /*
        @dev: {set_div()} function.

        * Takes in two numbers and its decimal place that is desired to be returned in and returns the boolean division.
        * It applies the same algorithm as {div()} function.

    */
    
    // This makes sure that for ever division with an set decimal, the denominator won't be larger than the numerator.

    modifier set_divisor_control(uint a, uint b, uint _d)
    {
        uint control = a * (10 ** _d);
        require(b <= control, "Syntax Error: This decimal is out of place.");
        _;
    }


    function set_div(uint a, uint b, uint _decimal) internal pure set_divisor_control(a, b, _decimal) returns(bool, uint)
    {
        require(b > 0, "Library Error, Zero division error.");
        require(_decimal > 0, "Library Error, Decimal place error.");

        uint rem = (a * (10 ** _decimal)) / b;
        return (true, rem);
    }




    
    /*
        @dev: {exp()} function.

        * Takes in two numbers and returns the exponent.
    */

    function exp(uint a, uint b) internal pure returns(uint)
    {
        require((a ** b) <= ((2 ** 256) - 1), "Library Error, Number overflow.");
        uint prod = a ** b;
        return prod;
    }

    
    /*
        @dev: {mod()} function.

        * Takes in two numbers and returns the remainder gotten when the first is divided by the second.
        * Does `a` mod `b`.
    */

    function mod(uint a, uint b) internal pure returns(uint)
    {
        require(b > 0, "Library Error, Zero division error.");

        //if b > a, logically, 3 % 4 == 3.

        if(b > a)
        {
            return a;
        }
        else
        {
            uint modulus = a % b;
            return modulus;
        }
    }



    
    /*
        @dev: {add_arr()} function.

        * Takes in an array of numbers and adds them and returns the cumultative total
    */

    function add_arr(uint[] memory arr) internal pure returns(uint)
    {
        uint total = 0;
        for (uint i = 0; i < arr.length; i++)
        {
            total += arr[i];
        }

        return total;
    }




    /*
        @dev: {mul_arr()} function.

        * Takes in an array of numbers and adds them and returns the cumultatve product.
    */

    function mul_arr(uint[] memory arr) internal pure returns(uint)
    {
        uint prod = 1;

        for (uint i = 0; i < arr.length; i++)
        {
            prod *= arr[i];
        }

        return prod;
    }




    /*
        @dev: {perc()} function.

        * Calculates the a% of b i.e (a*b / 100) but it returns in the default 4 decimal places with a modifier in place to make sure that the numerator...
        * Does not overflow the denominator.
    */

    modifier valid_percentage()
    {
        require(DECIMAL >= 2, "Syntax Error: This is out of place.");
        _;
    }

    function perc(uint a, uint b) internal pure valid_percentage() returns(uint)
    {
        require(b > 0, "Library Error, Zero division error.");
        
        uint perc_val = (a * b * (10 ** DECIMAL)) / 100;
        return perc_val;
    }




    /*
        @dev: {set_perc()} function.

        * Calculates the a% of b i.e (a*b / 100) but it returns in the decimal place passed with a modifier in place to make sure that the numerator...
        *
        *
        *
        *
        * This should be used when calculating decimal percentages of whole numbers e.g 1.5% of 8.
        *
        * Solution: This should return `0.12` on a normal calculator, but Solidity is different.
        *
        * 1. Pick the decimal places you want to return it in, say 5. 
        * 2. To get 1.55 to the nearest whole integer == 1.55 * 100. Take note, 100 == 10 ** 2.
        * 3. The function will return the solution, in the decimal place of 5 + (the power of 10 that makes the decimal a nearest whole, i.e, 2) == 7;
        * 4. Answer is in 7 dp.
        * 4. 1200000 divided by 10 ** 7 == 0.12, there you go.
        *
        *
        * Does not overflow the denominator.
    */
    

    modifier set_valid_percentage(uint _d)
    {
        require(_d >= 2, "Syntax Error: This is out of place.");
        _;
    }

    function set_perc(uint a, uint b, uint _decimal) internal pure set_valid_percentage(_decimal) returns(uint)
    {
        require(b > 0, "Library Error, Zero division error.");
        
        uint perc_val = (a * b * (10 ** _decimal)) / 100;
        return perc_val;
    }
}

// File: FPS.sol

/*
 * @title: FPS ($FPS) An re-write of the ERC-20 token, $FPS.
 * @author: Anthony (fps) https://github.com/fps8k .
 * @dev: 
*/


contract FPS is IERC20
{
    using PureMath for uint256;


    // Token data.

    string private _name;                                                               // FPS.
    string private _symbol;                                                             // $FPS.
    uint256 private _totalSupply;                                                      // 1_000_000.
    uint8 private _decimals;                                                            // 18.


    // Owner address and a mapping of owners that can perform actions with the token.

    address private _owner = 0x5e078E6b545cF88aBD5BB58d27488eF8BE0D2593;            	  // My Ethereum wallet address for production.
    // address private _owner = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;               // My Fake Remix wallet address for development.
    
    mapping(address => bool) private _approved_owners;


    // Token holders and allowances.

    mapping(address => uint256) private _balances;                                       // Change to private on production.
    
    mapping(address => mapping(address => uint256)) private _allowances;


    // Events

    event Create(address, uint256, string, uint256);                                    // Address, time, name, supply.
    event Mint(address, uint256, uint256);                                              // Address, time, supply.
    event Burn(address, uint256, uint256);                                              // Address, time, supply.
    event Change(address, uint256, address);                                            // Old address, time, new address.




    // Constructor

    constructor()
    {
        _name = "FPS";
        _symbol = "$FPS";
        _decimals = 18;
        _totalSupply = 1000000000 * (10 ** _decimals);


        // Give the owner all the token.

        _balances[_owner] = _totalSupply;
        _approved_owners[_owner] = true;

        emit Create(_owner, block.timestamp, _name, _totalSupply);
    }




    function name() public view returns (string memory __name)
    {
        __name = _name;
    }




    function symbol() public view returns(string memory __symbol)
    {
        __symbol = _symbol;
    }




    function decimals() public view returns(uint8 __decimals)
    {
        __decimals = _decimals;
    }




    function totalSupply() public view override returns(uint256 __totalSupply)
    {
        __totalSupply = _totalSupply;
    }




    function exists(address _account) private view returns(bool)
    {
        return _approved_owners[_account];
    }




    /*
    * @dev Returns the amount of tokens owned by `account`.
    */

    function balanceOf(address account) public view override returns(uint256)
    {
        // require(msg.sender != address(0), "!Address");
        require(exists(account), "Account !Exists");

        uint256 _balance_of = _balances[account];
        return _balance_of;
    }




    function isOneOfTheTwo(address __owner, address __spender) private view returns(bool)
    {
        return((msg.sender == __owner) || msg.sender == __spender);
    }





    /**
    * @dev Moves `amount` tokens from the caller's account to `to`.
    *
    * Returns a boolean value indicating whether the operation succeeded.
    *
    * Emits a {Transfer} event.
    */

    function transfer(address to, uint256 amount) public override returns(bool)
    {
        require(msg.sender != address(0), "!Address");                              // Sender's address is not 0 address.
        require(exists(msg.sender), "Account !Exists");                             // Sender exists in the records, even if he has 0 tokens.
        require(to != address(0), "Receiver !Address");                             // Receiver isn't 0 address.
        require(amount > 0, "Amount == 0");                                         // Can't send empty token.
        require(_balances[msg.sender] >= amount, "Wallet funds < amount");          // Sender has more than he can send.

        _balances[msg.sender] = _balances[msg.sender].sub(amount);                  // Subtract from sender.
        _balances[to] = _balances[to].add(amount);                                  // Add to receiver.

        _approved_owners[to] = true;

        emit Transfer(msg.sender, to, amount);

        return true;
    }




    /**
    * @dev Returns the remaining number of tokens that `spender` will be
    * allowed to spend on behalf of `owner` through {transferFrom}. This is
    * zero by default.
    *
    * This value changes when {approve} or {transferFrom} are called.
    */

    function allowance(address owner, address spender) public view override returns(uint256)
    {
        require(msg.sender != address(0), "!Address");
        require(owner != address(0), "!Owner");
        require(spender != address(0), "!Spender");
        require(exists(owner), "!Owner");
        require(exists(spender), "!Spender");
        require(isOneOfTheTwo(owner, spender), "!Owner && !Spender)");

        uint256 _allowance = _allowances[owner][spender];
        return _allowance;
    }




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

    function approve(address spender, uint256 amount) public override returns(bool)
    {
        // msg.sender == the address of the caller.

        require(msg.sender != address(0), "!Address");
        require(spender != address(0), "!Spender");
        require(exists(msg.sender), "!Account Exists");
        require(msg.sender != spender, "Caller == Spender");
        require(_balances[msg.sender] >= amount, "Balance < Amount");

        _allowances[msg.sender][spender] += amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }





    /**
    * @dev Moves `amount` tokens from `from` to `to` using the
    * allowance mechanism. `amount` is then deducted from the caller's
    * allowance.
    *
    * Returns a boolean value indicating whether the operation succeeded.
    *
    * The person calling transferFrom doesn't need to own tokens.
    *
    * Emits a {Transfer} event.
    */

    function transferFrom(address from, address to, uint256 amount) public override returns(bool)
    {
        require(msg.sender != address(0), "!Address");
        require(from != address(0), "!From");
        require(to != address(0), "!To");
        require(exists(from), "From !Exists");
        require(_allowances[from][msg.sender] >= amount, "Balance < Amount");

        _balances[from] = _balances[from].sub(amount);
        _balances[to] = _balances[to].add(amount);
        _allowances[from][msg.sender] = _allowances[from][msg.sender].sub(amount);
		
		_approved_owners[to] = true;

        emit Transfer(from, to, amount);

        return true;
    }




    /*
    * @dev: {mint()} adds more tokens to the `_totalSupply`.
    */

    function mint(uint256 amount) public
    {
        require(msg.sender == _owner, "!Owner");
        uint256 _supply = amount * (10 ** _decimals);

        _totalSupply = _totalSupply.add(_supply);

        emit Mint(msg.sender, block.timestamp, _supply);
    }




    /*
    * @dev: burn() removes from the token
    */

    function burn(uint256 amount) public
    {
        require(msg.sender == _owner, "!Owner");
        uint256 _supply = amount * (10 ** _decimals);

        _totalSupply = _totalSupply.sub(_supply);

        emit Burn(msg.sender, block.timestamp, _supply);
    }




    /*
    * @dev: {changeOwner()} changes owner of token
    */

    function changeOwner(address new_owner) public
    {
        require(msg.sender == _owner, "!Owner");
        require(new_owner != _owner, "New Owner == Old owner");

        _owner = new_owner;

        emit Change(msg.sender, block.timestamp, new_owner);
    }
}