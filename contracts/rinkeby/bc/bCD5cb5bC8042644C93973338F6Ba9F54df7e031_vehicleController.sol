// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./interfaces/IERC20.sol";
import "./interfaces/Context.sol";
import "./lib/SafeMath.sol";

contract vehicleController is Context,IERC20 {

    using SafeMath for uint256;
    Vehicle[] private _vehicles;
    address public factory;
    mapping(address => uint) _vehicles_address;

    uint constant private cost_per_km = 19;
    uint constant private reservation_Fee = 100;


    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    event StatusChange(address indexed _from, uint indexed _id, State _state);

    struct Vehicle  {
        address owner;
        address user;
        uint256  mileageAtStart;
        uint payment;
        uint balance;
        uint lat;
        uint lan;
        State status;

    }

    enum State { free, reserved, inUse, afterUse, paused, maintenance } //after use fällt raus
    State vehicleStatus = State.afterUse;

    modifier onlyOwner(address vehicleOwner) {
        require(msg.sender == vehicleOwner, "You're not the owner of the Vehicle");
        _;
    }

    modifier onlyFactory() {
        require(msg.sender == factory, "You need to use the factory");
        _;
    }

    constructor() {
        factory = msg.sender;
        _name = "M4A-Token";
        _symbol = "M4$";
        _decimals = 2;
        _mint(factory,2000000);
    }

    /* Create a new Vehicle */
    function createVehicle(uint _mileageAtStart, uint _lan , uint _lat  ) external returns(uint) {

        _vehicles.push(Vehicle({
        owner:msg.sender,
        user:payable(address(0)),
        mileageAtStart:_mileageAtStart,
        lat:_lat,
        lan:_lan,
        payment:0,
        balance:0,
        status: State.maintenance
            }));
            uint id = _vehicles.length  - 1 ;
            return id;
        }

    /* Show all Vehicles with Status free */
    function getFreeVehicles() view external returns(uint[] memory){
        uint256 _length = 0;
        uint256 _index = 0;
        for (uint i=0; i<_vehicles.length; i++) {
            if(_vehicles[i].status == State.free ){
                _length++;
            }
        }
        uint[] memory ret = new uint[](_length) ;

        for (uint i=0; i<_vehicles.length; i++) {
            if(_vehicles[i].status == State.free ){
                ret[_index]= i;
                _index++;
            }
        }

        return ret;
    }

    /* return all Vehicles ids iam owner off */
    function getVehiclesOwnedByMe() view external returns (uint[] memory){
        uint256 _length = 0;
        uint256 _index = 0;
        for (uint i=0; i<_vehicles.length; i++) {
            if(_vehicles[i].owner == msg.sender ){
                _length++;
            }
        }
        uint[] memory ret = new uint[](_length) ;

        for (uint i=0; i<_vehicles.length; i++) {
            if(_vehicles[i].owner == msg.sender ){
                ret[_index]= i;
                _index++;
            }
        }

        return ret;
    }

    /* return Vehicle status */
    function  getStatus(uint _id)  public view  returns  (State) {
        return _vehicles[_id].status;
    }

    /* gets called from Vehicle to change status */
    function setStatus(uint _id, State _new_state) external onlyOwner(_vehicles[_id].owner){
        if(_vehicles[_id].status == State.inUse || _vehicles[_id].status == State.reserved){
            _vehicles[_id].user = address(0);
        }
        _vehicles[_id].status=_new_state;
        emit StatusChange(_vehicles[_id].owner, _id, _vehicles[_id].status);
    }

    /* gets called from user to reserve Vehicle*/
    function reserve(uint _id) external {
        require(_vehicles[_id].status == State.free,"Vehicle not free");
        approve(_vehicles[_id].owner,5000);
        transfer(_vehicles[_id].owner,reservation_Fee);
        _vehicles[_id].status = State.reserved;
        _vehicles[_id].user = msg.sender;
        emit StatusChange(_vehicles[_id].owner, _id, _vehicles[_id].status);
    }

    /* gets called from user to cancle reservation*/
    function cancel_reserve(uint _id) external {
        require(_vehicles[_id].status == State.reserved,"Vehicle not reserved");
        require(msg.sender == _vehicles[_id].user,"Vehicle not reserved by u");
        _vehicles[_id].status = State.free;
        _vehicles[_id].user = address(0);
        emit StatusChange(_vehicles[_id].owner, _id, _vehicles[_id].status);
    }

    /* is called form Vehicle then Drive started */
    function startRide(uint _id,uint _mileage) external onlyOwner(_vehicles[_id].owner){
        _vehicles[_id].mileageAtStart = _mileage;
        _vehicles[_id].status = State.inUse;
        emit StatusChange(_vehicles[_id].owner, _id, _vehicles[_id].status);
    }

    /* is called form Vehicle then Drive ended */
    function EndRide(uint _id,uint _mileage,uint _lan , uint _lat) external onlyOwner(_vehicles[_id].owner) {
        uint diff =  _mileage-_vehicles[_id].mileageAtStart;
        _vehicles[_id].mileageAtStart = _mileage;
        _vehicles[_id].lat=_lat;
        _vehicles[_id].lan=_lan;
        _vehicles[_id].status = State.free;
        uint price =  ((diff/200) * cost_per_km); //änderung Umrechungsfaktor
        transferFrom(_vehicles[_id].user,_vehicles[_id].owner,price);
        _vehicles[_id].user = address(0);
        emit StatusChange(_vehicles[_id].owner, _id, _vehicles[_id].status);
    }

    /* get Balance of Vehicle */
    function getBalance(uint _id) external view onlyFactory returns(uint) {
        return _vehicles[_id].balance;
    }

    /* get Vehicle data by id */
    function getVehicleById(uint id) external view  returns(Vehicle memory) {
        return  _vehicles[id];
    }

    /* called from user to see which vehicles are booked */
    function getBookedVehicles() external view returns(uint[] memory){

        uint256 _length = 0;
        uint256 _index = 0;

        for (uint i=0; i<_vehicles.length; i++) {
            if(_vehicles[i].user == msg.sender ){
                _length++;
            }
        }

        uint[] memory ret = new uint[](_length) ;

        for (uint i=0; i<_vehicles.length; i++) {
            if(_vehicles[i].user == msg.sender ){
                ret[_index]=i;
                _index++;

            }
        }
        return ret;

    }

    /* send tokens from owner to user */
    function exchange(address recipient, uint256 amount) external onlyFactory returns (bool){
        require(balanceOf(factory)>0,"not enouth tokens in account");
        require(recipient != address(0),"provide valid address");
        _transfer(factory,recipient,amount);
        return true;
    }

    /* send tokens from user to owner*/
    function return_exchange(address recipient, uint256 amount) external onlyFactory returns (bool){
            require(balanceOf(recipient)>=amount,"not enouth tokens in account");
            require(recipient != address(0),"provide valid address");
            _transfer(recipient,factory,amount);
            return true;
        }


    /*IERC20*/
    function name() public view returns (string memory) {
        return _name;
    }


    function symbol() public view returns (string memory) {
        return _symbol;
    }


    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

      function transferFrom(address sender, address recipient, uint256 amount) public virtual
                                                override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount,
             "ERC20: transfer amount exceeds allowance"));
        return true;
    }
     function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
     function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue,
                "ERC20: decreased allowance below zero"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        _beforeTokenTransfer(sender, recipient, amount);
        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _beforeTokenTransfer(address(0), account, amount);
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
         emit Approval(owner, spender, amount);
    }
 function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }


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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

/*
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
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