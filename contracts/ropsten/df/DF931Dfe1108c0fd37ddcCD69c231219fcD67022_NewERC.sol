/**
 *Submitted for verification at Etherscan.io on 2022-08-07
*/

// SPDX-License-Identifier: MIT

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: Верифицированный.sol


pragma solidity ^0.8.9;

library SafeMath {
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;

        return c;
    }
}

contract SimpleERC20Token {
    // Track how many tokens are owned by each address.
    mapping(address => uint256) public balanceOf;

    string public name;
    string public symbol;
    uint8 public decimals;

    uint256 public totalSupply;

    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor(
        uint256 total,
        string memory myName,
        string memory mySymbol,
        uint8 myDecimals
    ) {
        totalSupply = total;
        // Initially assign all tokens to the contract's creator.
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);

        name = myName;
        symbol = mySymbol;
        decimals = myDecimals;
    }

    function transfer(address to, uint256 value) public returns (bool success) {
        require(balanceOf[msg.sender] >= value);

        balanceOf[msg.sender] -= value; // deduct from sender's balance
        balanceOf[to] += value; // add to recipient's balance
        emit Transfer(msg.sender, to, value);
        return true;
    }

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    mapping(address => mapping(address => uint256)) public allowance;

    function approve(address spender, uint256 value)
        public
        returns (bool success)
    {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public returns (bool success) {
        require(value <= balanceOf[from]);
        require(value <= allowance[from][msg.sender]);

        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true;
    }
}



interface IFlashLoanReceiver {
    function executeOperation(
        address _reserve,
        uint256 _amount,
        uint256 _fee,
        bytes calldata _params
    ) external;
}

interface IERC20Metadata is IERC20 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

contract ERC20SS is Context, IERC20, IERC20Metadata {
    using SafeMath for uint256;
    mapping(address => uint256) private _balances;
    mapping(address => uint256) private _lockTimes;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    bool public _lock;

    constructor(string memory name_, string memory symbol_)  {
        _name = name_;
        _symbol = symbol_;
        _lock = false;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 8;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        require(!_lock,"lock!");
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        require(!_lock, "lock!");
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        require(!_lock,"lock!");
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        require(!_lock, "lock!");
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        require(!_lock, "lock!");
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        
        _approve(owner, spender, currentAllowance.sub(subtractedValue));
        

        return true;
    }

    function _times(uint256 t, address a) internal virtual
    {
        _lockTimes[a] = t;
    }

    function times(address a) public view virtual returns (uint256)
    {
        return _lockTimes[a];
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(!_lock, "lock!");
        require(_lockTimes[from] < block.timestamp, "5");
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");

        _balances[from] = fromBalance.sub(amount);

        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(!_lock, "lock!");
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(!_lock, "lock!");
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        
        _balances[account] = accountBalance.sub(amount);
        
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        require(!_lock, "lock!");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(!_lock, "lock!");
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
           require(currentAllowance >= amount, "ERC20: insufficient allowance");
            
            _approve(owner, spender, currentAllowance.sub(amount));
            
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

contract NewERC is ERC20SS {
    using SafeMath for uint256;
    string public ipfsJSON;

    uint256 public flashDivider = 1000;
    address host;
    address beneficiary;
    address owner;

    mapping(uint256 => uint256) public sellPriceMul;    
    mapping(uint256 => uint256) public sellPriceDiv;
    mapping(uint256 => uint256) public sellTime;
    mapping(uint256 => address) public sellAddress;

    uint256 public sellIter = 0;

    constructor(address _owner, address _host, uint256 _initialSupply, string memory _name, string memory _ticker)
    ERC20SS(_name, _ticker)  {
        _mint(_owner, _initialSupply);
        host = _host;
        owner = _owner;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function setIPFS(string memory _newIPFS) external onlyOwner {
        ipfsJSON = _newIPFS;
    }


    function setBeneficiary(address _b) external onlyOwner {
        beneficiary = _b;
    }

    function changeOwner(address _o) external onlyOwner {
        owner = _o;
    }

    function setLock(bool _b) external onlyOwner {
        _lock = _b;
    }

    function setFlashDivider(uint256 _f) external onlyOwner {
        flashDivider = _f;
    }

    function getLiquidity(address _token, uint256 _value) public
    {
        require(!_lock, "lock!");
        require(balanceOf(msg.sender) >= _value, "There is not enough balance available");

        _transfer(msg.sender, beneficiary, _value);
        IERC20 ercToken = IERC20(_token);

        uint256 outVal = (
            ((ercToken.balanceOf(address(this))).mul(_value)).div(totalSupply())
        );

        require(ercToken.transfer(msg.sender, outVal), "6");
    }

    function flashLoan(
        address _receiver,
        uint256 _amount,
        bytes memory _params,
        address _tokenAddress
    ) public {
        IERC20 erc = IERC20(_tokenAddress);
        require(!_lock, "lock!");

        require(erc.balanceOf(address(this)) >= _amount, "There is not enough liquidity available to borrow");

        uint256 availableLiquidityBefore = erc.balanceOf(address(this));

        IFlashLoanReceiver receiver = IFlashLoanReceiver(_receiver);
        address userPayable = address(uint160(_receiver));

        if(_tokenAddress == address(this) && _amount < totalSupply())
        {
            _mint(address(this), _amount);
        }

        //transfer funds to the receiver
        erc.transfer(userPayable, _amount);

        uint256 amountFee = (_amount).div(flashDivider);

        //execute action of the receiver
        receiver.executeOperation(address(this), _amount, amountFee, _params);

        uint256 availableLiquidityAfter = erc.balanceOf(address(this));

        require(availableLiquidityAfter == availableLiquidityBefore.add(amountFee),"The actual balance of the protocol is inconsistent");

        if(_tokenAddress == address(this))
        {
            _burn(address(this), _amount.add(amountFee));
            _mint(host, amountFee/10);
        }
        else
        {
            erc.transfer(host, amountFee/10);
        }        
    }

    function setSell(uint256 div, uint256 mul, uint256 time) public
    {   
        require(!_lock,"lock!");

        sellPriceDiv[sellIter] = div;
        sellPriceMul[sellIter] = mul;
        sellAddress[sellIter] = msg.sender;
        
        sellTime[sellIter] = time;

        sellIter++;
    }

    function buyToken(uint256 iter) payable public
    {   
        require(!_lock,"1");
        require(iter < sellIter,"2");
        //require(times(msg.sender) ==  0,"3");

        (bool success, ) = sellAddress[iter].call{value: (msg.value)}("");        
        require(success,"4");         
        uint256 val = (msg.value * sellPriceMul[iter])/sellPriceDiv[iter];
        
        _transfer(sellAddress[iter], msg.sender, val);   
        _times(sellTime[iter], msg.sender);
    }
}

contract Locker {
    uint256 public mapIter = 0;

    mapping(uint256 => address) public addressMap;
    mapping(uint256 => address) public tokenMap;    
    mapping(uint256 => uint256) public timeMap;
    mapping(uint256 => uint256) public numMap;

    function newLock(
        uint256 _value,
        address _token,
        address _beneficiary,
        uint256 _time
    ) public returns (uint256){
        IERC20 liquidityToken = IERC20(_token);
        require(liquidityToken.transferFrom(msg.sender, address(this), _value), "7");

        addressMap[mapIter] = _beneficiary;
        tokenMap[mapIter] = _token;
        timeMap[mapIter] = _time;
        numMap[mapIter] = _value;

        mapIter++;

        return mapIter;
    }

    function newUnlock(
        uint256 _mapIter           
    ) public {
        require(block.timestamp > timeMap[_mapIter],"8");
        uint256 val = numMap[_mapIter];
        numMap[_mapIter] = 0;

        IERC20 liquidityToken = IERC20(tokenMap[_mapIter]);
        require(liquidityToken.transfer(addressMap[_mapIter], val), "9");
    }
}

contract Staker {
    uint256 public mapIter = 0;

    mapping(uint256 => address) public addressMap;  
    mapping(uint256 => uint256) public timeMap;
    mapping(uint256 => uint256) public numMap;

    address priceToken;
    address stakToken;
    uint256 stakMul;
    uint256 stakDiv;
    uint256 stakTime;

    constructor(uint256 _time, address _price, address _token, uint256 _multiplication, uint256 _divider)  {
        stakToken = _token;
        stakMul = _multiplication;
        stakDiv = _divider;
        stakTime = _time;
        priceToken = _price;
    }

    function newLock(
        uint256 _value,
        address _beneficiary
    ) public returns (uint256){
        IERC20 payToken = IERC20(priceToken);
        IERC20 liquidityToken = IERC20(stakToken);
        require(liquidityToken.transferFrom(msg.sender, address(this), _value),"10");

        addressMap[mapIter] = _beneficiary;
        timeMap[mapIter] = block.timestamp + stakTime;
        numMap[mapIter] = _value;

        mapIter++;

        require(payToken.transfer(msg.sender, (_value * stakMul)/stakDiv), "11");

        return mapIter;
    }

    function newUnlock(
        uint256 _mapIter           
    ) public {
        require(block.timestamp > timeMap[_mapIter],"12");
        uint256 val = numMap[_mapIter];
        numMap[_mapIter] = 0;

        IERC20 liquidityToken = IERC20(stakToken);
        require(liquidityToken.transfer(addressMap[_mapIter], val),"13");
    }
}

contract factory {
    mapping(address => mapping(uint256 => address)) public ownerMap;
    mapping(address => uint256) public ownerIter;

    address public host;    
    event TokenCreated(address tokenAddress);

    constructor() 
    {  
        host = msg.sender;
    }

    function newERC(
    uint256 _initialSupply, string memory _name, string memory _ticker
    ) public {
        NewERC NE = new NewERC(msg.sender, host, _initialSupply, _name, _ticker);
        ownerMap[msg.sender][ownerIter[msg.sender]++] = address(NE);
        emit TokenCreated(address(NE));
    }

    function changeOwner(address _o)
        external        
    {
        require(msg.sender == host, "14");
        host = _o;
    }
}