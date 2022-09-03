/**
 *Submitted for verification at Etherscan.io on 2022-09-03
*/

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.7;

// import "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts/utils/Context.sol";
// import "@openzeppelin/contracts/utils/math/SafeMath.sol";
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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

contract Krishit is Context {

    event Transfer(
        address indexed from, 
        address indexed to, 
        uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 public _decimals = 18;
    string public _symbol = "Krishit";
    string public _name = "KrishERC20";

    uint256 public _totalSupply;
    uint256 public _airdrop;
    uint256 public _rosterMint;
    uint256 public deployTime;
    
    uint256 private MAX = 100 * 10**6 * 10**18;
    uint256 private AIRDROP_MAX = 5 * 10**6 * 10**18;
    uint256 private ROSTER_MAX = 20 * 10**6 * 10**18;

    address private _admin;
 
    address private FOUNDER_1_ADDRESS = 0x3A485db9064Be4aB67b6AF8CC7EeEC7d2d9f36b7;
    address private FOUNDER_2_ADDRESS = 0x3A485db9064Be4aB67b6AF8CC7EeEC7d2d9f36b7;
    address private FOUNDER_3_ADDRESS = 0x3A485db9064Be4aB67b6AF8CC7EeEC7d2d9f36b7;
    address private FOUNDER_4_ADDRESS = 0x3A485db9064Be4aB67b6AF8CC7EeEC7d2d9f36b7;
    address private TREASURY_WALLET   = 0x3A485db9064Be4aB67b6AF8CC7EeEC7d2d9f36b7;
    address private MARKETING_ADDRESS = 0x3A485db9064Be4aB67b6AF8CC7EeEC7d2d9f36b7;

    mapping (address => mapping ( address => mapping (uint256 => bool))) private checkTransfer;
    mapping (address => mapping (uint256 => bool)) completeTransfer;
    mapping (address => uint256 ) private vestedTime;
    
  
    constructor()  {

        deployTime = block.timestamp;

        _balances[FOUNDER_1_ADDRESS] = MAX * 1/100 /4;
        _balances[FOUNDER_2_ADDRESS] = MAX * 1/100 /4;
        _balances[FOUNDER_3_ADDRESS] = MAX * 1/100 /4;
        _balances[FOUNDER_4_ADDRESS] = MAX * 1/100 /4;
        _balances[TREASURY_WALLET]   = MAX * 15/100;
        _balances[MARKETING_ADDRESS] = MAX * 5/100;

        vestedTime[FOUNDER_1_ADDRESS] = deployTime;
        vestedTime[FOUNDER_2_ADDRESS] = deployTime;
        vestedTime[FOUNDER_3_ADDRESS] = deployTime;
        vestedTime[FOUNDER_4_ADDRESS] = deployTime;
        
        _admin = msg.sender;
        _totalSupply = MAX * (1+15+5)/100;
    }

    ///////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////--------  Rostered Kongs Distribution  --------////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////////////////////////////
    function rosterTransfer(address _receiver, uint256 _amount) external onlyAdmin {
        require(_rosterMint + _amount <= ROSTER_MAX, "Roster Kongs Exceed");
        _rosterMint += _amount;
        _mint(_receiver, _amount);
    }


    ///////////////////////////////////////////////////////////////////////////////////////////////////
    /////////////////////////--------  TREASURY Distribution  --------/////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////////////////////////////
    function checkTx(address _receiver, uint256 _amount) external {
        require(msg.sender == FOUNDER_1_ADDRESS || msg.sender == FOUNDER_2_ADDRESS || msg.sender == FOUNDER_3_ADDRESS || msg.sender == FOUNDER_4_ADDRESS, "Not Founder");
        checkTransfer[msg.sender][_receiver][_amount] = true;
    }
    function transferFromTreasury(address to, uint256 amount) public {
        require(msg.sender == FOUNDER_1_ADDRESS || msg.sender == FOUNDER_2_ADDRESS || msg.sender == FOUNDER_3_ADDRESS || msg.sender == FOUNDER_4_ADDRESS, "Not Founder");
    
        require(completeTransfer[to][amount] == false, "Completed Transfer!");

        uint checkNum;
        if (checkTransfer[FOUNDER_1_ADDRESS][to][amount] == true) checkNum++;
        if (checkTransfer[FOUNDER_2_ADDRESS][to][amount] == true) checkNum++;
        if (checkTransfer[FOUNDER_3_ADDRESS][to][amount] == true) checkNum++;
        if (checkTransfer[FOUNDER_4_ADDRESS][to][amount] == true) checkNum++;

        if (checkNum > 3) {
            _transfer(TREASURY_WALLET, to, amount);
        }
    }


    ///////////////////////////////////////////////////////////////////////////////////////////////////
    /////////////////////////--------  Staking Distribution  --------//////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////////////////////////////
    function sendToStaking(address _stakingContract) external onlyAdmin{
        uint256 stakingAmount = MAX * 30/100;
        _mint(_stakingContract, stakingAmount);
    }


    ///////////////////////////////////////////////////////////////////////////////////////////////////
    /////////////////////////--------  Liquidity Distribution  --------////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////////////////////////////
    function sendToLiquidity(address _liquidityAddress) external onlyAdmin{
        uint256 liquidityAmount = MAX * 15/100;
        _mint(_liquidityAddress, liquidityAmount);
    }
 
    ///////////////////////////////////////////////////////////////////////////////////////////////////
    /////////////////////////--------  AIRDROP Distribution  --------//////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////////////////////////////
    function airdrop(address _receiver, uint256 _amount) external onlyAdmin{
        require(_airdrop + _amount <= AIRDROP_MAX, "Airdrop Exceed");
        _airdrop += _amount;
        _mint(_receiver, _amount);
    }

    ///////////////////////////////////////////////////////////////////////////////////////////////////
    /////////////////////////--------  Founder Distribution  --------//////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////////////////////////////
    function founderInvest() external {
        require(msg.sender == FOUNDER_1_ADDRESS || msg.sender == FOUNDER_2_ADDRESS || msg.sender == FOUNDER_3_ADDRESS || msg.sender == FOUNDER_4_ADDRESS, "Not Founder");
        require(vestedTime[msg.sender] + 30 days < block.timestamp, "Not yet vesting time");
        
        uint256 times_ = (block.timestamp - vestedTime[msg.sender])/(30 days); 
        uint256 vestingAmount_ = times_ * MAX * 9/100 / 24 /4;
        _mint(msg.sender, vestingAmount_);
        
        vestedTime[msg.sender] += times_ * 30 days;
    }

    ///////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////--------  IERC-20 Interface  --------////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////////////////////////////
     /**
     * @dev See `IERC20.totalSupply`.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See `IERC20.balanceOf`.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See `IERC20.transfer`.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public returns (bool) {
        if (msg.sender == TREASURY_WALLET) transferFromTreasury(recipient, amount);
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @dev See `IERC20.allowance`.
     */
    function allowance(address owner, address spender)
        public
        view
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev See `IERC20.approve`.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev See `IERC20.transferFrom`.
     *
     * Emits an `Approval` event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of `ERC20`;
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `value`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            msg.sender,
            _allowances[sender][msg.sender].sub(amount)
        );
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to `approve` that can be used as a mitigation for
     * problems described in `IERC20.approve`.
     *
     * Emits an `Approval` event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue)
        public
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].add(addedValue)
        );
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to `approve` that can be used as a mitigation for
     * problems described in `IERC20.approve`.
     *
     * Emits an `Approval` event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].sub(subtractedValue)
        );
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to `transfer`, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a `Transfer` event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a `Transfer` event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a `Transfer` event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an `Approval` event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 value
    ) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    /**
     * @dev Destoys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See `_burn` and `_approve`.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(
            account,
            msg.sender,
            _allowances[account][msg.sender].sub(amount)
        );
    }

    ///////////////////////////////////////////////////////////////////////////////////////////////

    modifier onlyAdmin() {
        require(msg.sender == _admin, "Ownable: caller is not the owner");
        _;
    }

    function setAdmin(address _newAddress) external onlyAdmin {
        _admin = _newAddress;
    }

}