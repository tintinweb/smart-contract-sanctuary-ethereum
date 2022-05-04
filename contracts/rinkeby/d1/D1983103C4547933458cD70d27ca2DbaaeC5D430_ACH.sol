// File: ACH.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "./Ownable.sol";
import "./SafeMath.sol";

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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

// File: extensions/IERC20Metadata.sol



/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// File: ERC20.sol

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
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 */
contract ACH is Context, IERC20, IERC20Metadata, Ownable {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;


    uint256 private _totalSupply;
    uint256 public exchangeRate;

    string private _name = "AI-CELL Health";
    string private _symbol = "AICH";
    uint8 private _decimals = 18;

    // Events 
    event AuthorizedCaller(address _caller);
    event DeAuthorizedCaller(address _caller);
    event UpdateExchangeRate(string _phasename,uint256 _rate);
    event VestingPeriodUpdated(address _wallet, uint256 _endDate);
    event PhaseUpdated(string _phaseId, uint256 _startDate, uint256 _endDate, bool _whitelistRequired,uint256 _exchangeRate);
    event WhitelistingUpdated(address _wallet, bool _status);
    event UpdateAdminCommission(string _admin, uint256 _commission);

    // List of authorizedCaller with escalated permissions
    mapping(address => bool) public authorizedCaller;

    address ADMIN_WALLET_1 = 0xB40d84bCd166BeB8df9b74c8a1C22458d1FC6dDC; //2a10059cfa01d76b561f9134e9665b6afdba1eb4e791e5b28e8f1b176cda40c7
    address ADMIN_WALLET_2 = 0xf22A1a6624747e6a02E836Ee63647862B45f8418; //95199a860f584e9e332879993e12d6fc7c18b3b16d382b03d4a1a5937811ad04
    address ADMIN_WALLET_3 = 0x87aa1aE39e635460e349757C79b0884a93Ad3120; //7639c933ef4dda4ce3f61bb6e9df448a11087748a648d2c59180eeb5f666efc4

    address PUBLIC_OFFERING_ADDRESS = 0x603f058748d24380f40B650255C0152cC7CCE8b6; //1174d2e33ea0d8c81850e6cab8d586e3556746d166720eb6447729b3de66673a
    address OWNER_ADDRESS = 0xbC86bBE7a2e4c5e12aFfbC5839D2E3962BE8E628; //e44e0041d635b655753e60f696392f97446ab2a9c89645da9450acd50d952a75
    address DEVELOPMENT_ADDRESS = 0x0133f375c939dF1261eab00aB500C38E485611e2; //0x0133f375c939dF1261eab00aB500C38E485611e2; //6f9ec3f25d7d4a2214dc22068c4e39bfefb906916eb578763889f2d5354a8d7b
    address MARKETING_ADDRESS = 0x14a4A4F8448099D281e4eD134095419fe4AE7c8e; //584abf7291d0fd7a22d41fd53447cd96811730f331914bb4a955ac16047327ad
    address PRIVATE_INVESTORS_ADDRESS = 0xCE10e21e947f5f3f0341F6fca7B2C102Bdf120B3; //3c6a3c9ac0064c83c8b2723baf7db4b00603674c8ad1f5801155fdb7193f74b1

    mapping(address => uint256) public vestingAddressPeriod;
    uint256 public timestampDeployment;


    struct Phase{
        uint256 _startDate;
        uint256 _endDate;
        uint256 _totalAllocation;
        uint256 _remainingAllocation;
        bool _whitelistRequired;
        uint256 _exchangeRate; 
    }

    struct Admin{
        address payable adminWallet;
        uint256 adminCommission;
    }

    mapping(string => Phase) public phaseDetails;

    mapping(string => Admin) public adminDetails;

    string[] public phaseLiterals = ['PHASE_1','PHASE_2','PHASE_3'];

    mapping(address => bool) public walletWhitelisting;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor() {

        timestampDeployment = block.timestamp;
        // Total Supply;
        _mint(address(this),30000000000 * 1e18);

        // Transfer According reservations 
        
        // Public Offering 45%
        _transfer(address(this),PUBLIC_OFFERING_ADDRESS,13500000000 * 1e18);

        // Owner 10%
        _transfer(address(this),OWNER_ADDRESS,3000000000 * 1e18);

        // Development 10%
        _transfer(address(this),DEVELOPMENT_ADDRESS,3000000000 * 1e18);

        // Add Vesting Period to Development 12 months
        updateAddressVestingPeriod(DEVELOPMENT_ADDRESS, block.timestamp + 31536000);

        // Marketing 5%
        _transfer(address(this),MARKETING_ADDRESS,1500000000 * 1e18);

        // Private Investors 10%
        // _transfer(address(this),PRIVATE_INVESTORS_ADDRESS,3000000000 * 1e18);

        // Phase declaration
       
        // Private 
        phaseDetails['PHASE_1'] = Phase(1649721600,1651320000,3000000000 * 1e18,3000000000 * 1e18,false,1); 
        // Presale 
        phaseDetails['PHASE_2'] = Phase(1651363200,1653004800,3000000000 * 1e18,3000000000 * 1e18,false,1);  
        // ICO
        phaseDetails['PHASE_3'] = Phase(1654041600,1655683200,3000000000 * 1e18,3000000000 * 1e18,false,1);  

        
        adminDetails['ADMIN_1'] = Admin(payable(ADMIN_WALLET_1),30);
        adminDetails['ADMIN_2'] = Admin(payable(ADMIN_WALLET_2),20);
        adminDetails['ADMIN_3'] = Admin(payable(ADMIN_WALLET_3),40);
    }


     modifier onlyAuthorized() {
        require(
            authorizedCaller[msg.sender] == true || msg.sender == owner,
            "Only Authorized and Owner can perform this action"
        );
        _;
    }

    // Get Active Phase
    function getActivePhase() view public returns (string memory){

        uint256 _currentLength = phaseLiterals.length;
        // uint256 _currentTimestamp = block.timestamp;

        for(uint8 idx = 0; idx < _currentLength; idx++){
            string memory _phaseLiteral = phaseLiterals[idx];
            Phase memory _currentPhase =  phaseDetails[_phaseLiteral];

            if(block.timestamp >= _currentPhase._startDate && block.timestamp <= _currentPhase._endDate)
            {
                return _phaseLiteral;
            }
        }

        return 'NO_ACTIVE_PHASE';
    }   

    // Update Phase details
    function updatePhaseDetails(string memory _phaseId, uint256 _startDate, uint256 _endDate, bool _whitelistRequired,uint256 _exchangeRate) public onlyAuthorized returns(bool){

        Phase memory _phase = phaseDetails[_phaseId];
        _phase._startDate = _startDate;
        _phase._endDate = _endDate;
        _phase._whitelistRequired = _whitelistRequired;
        _phase._exchangeRate = _exchangeRate;
        
        
        phaseDetails[_phaseId] = _phase;

        emit PhaseUpdated(_phaseId,_startDate,_endDate,_whitelistRequired,_exchangeRate);

        return true;
    }

    // To Update Vesting Period of Address 
    function updateAddressVestingPeriod(address _wallet,uint256 _endDate) onlyAuthorized public
    {
        vestingAddressPeriod[_wallet] = _endDate;
        emit VestingPeriodUpdated(_wallet,_endDate);
    }

    // Authorize given address for admin access
    function authorizeCaller(address _caller) public onlyOwner returns (bool) {
        authorizedCaller[_caller] = true;
        emit AuthorizedCaller(_caller);
        return true;
    }

    // Deauthorize given address for admin access
    function deAuthorizeCaller(address _caller)
        public
        onlyOwner
        returns (bool)
    {
        authorizedCaller[_caller] = false;
        emit DeAuthorizedCaller(_caller);
        return true;
    }

    // Whitelisting updation for msg.sender address
    function updateWhitelisting(bool _status) public returns(bool){
        walletWhitelisting[msg.sender] = _status;

        emit WhitelistingUpdated(msg.sender,_status);
        return true;
    }

    // Whitelisting updation for arbitary address only applicable for authorized users
    function updateWhitelistingForAdmin(address _wallet, bool _status) public onlyAuthorized returns(bool){
        walletWhitelisting[_wallet] = _status;

        emit WhitelistingUpdated(_wallet,_status);
        return true;
    }



    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        require(block.timestamp > vestingAddressPeriod[_msgSender()], "Cannot withdraw before vesting period." );

        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        // _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        // _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        // _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        // _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        // _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        // _afterTokenTransfer(account, address(0), amount);
    }

    /*Set admin commission */
    function setAdminCommission(string memory _adminLiteral,uint256 _adminCommission) public onlyAuthorized returns(bool)
    {
        Admin memory _selectedAdmin =  adminDetails[_adminLiteral];
        
        // Update selected admin commission
        _selectedAdmin.adminCommission = _adminCommission;

        adminDetails[_adminLiteral] = _selectedAdmin;

        emit UpdateAdminCommission(_adminLiteral, _adminCommission);
        
        return true;
    }

    /*Set exchange rate - ratePerBNB in wei */
    function setExchangeRate(string memory _phaseLiteral,uint256 _ratePerBNB) public onlyAuthorized returns(bool)
    {
        Phase memory _selectedPhase =  phaseDetails[_phaseLiteral];
        
        // Update selected phase exchange rate
        _selectedPhase._exchangeRate = _ratePerBNB;

        phaseDetails[_phaseLiteral] = _selectedPhase;

        emit UpdateExchangeRate(_phaseLiteral, _ratePerBNB);
        
        return true;
    }

    /* Buy BNB */
    function buyACHToken() external payable returns(bool)
    {
        // Get Active Phase
        string memory _phaseLiteral = getActivePhase();
        
        // Check if Any Active Phase ongoing
        require(strCompare(_phaseLiteral, "NO_ACTIVE_PHASE") == false,"Currently no active phase found");
        
        Phase memory activePhase = phaseDetails[_phaseLiteral];

        // Check if Whitelisting required for current phase
        if(activePhase._whitelistRequired == true)
        {
            require(walletWhitelisting[msg.sender] == true , "Address not whitelisted.");
        }

        //Calculate admin commission and apply Active phase exchange rate
        
        Admin memory _admin_commission_1 =  adminDetails['ADMIN_1'];
        Admin memory _admin_commission_2 =  adminDetails['ADMIN_2'];
        Admin memory _admin_commission_3 =  adminDetails['ADMIN_3'];
        
        uint256 amount = msg.value; 
       
        uint256 _admincommission_1 = amount.mul(_admin_commission_1.adminCommission).div(100);
        uint256 _admincommission_2 = amount.mul(_admin_commission_2.adminCommission).div(100);
        uint256 _admincommission_3 = amount.mul(_admin_commission_3.adminCommission).div(100);
        
        
        _admin_commission_1.adminWallet.transfer(_admincommission_1);
        _admin_commission_2.adminWallet.transfer(_admincommission_2);
        _admin_commission_3.adminWallet.transfer(_admincommission_3);
        
        uint256 _grossValue = amount.sub(_admincommission_1);
         _grossValue = _grossValue.sub(_admincommission_2);
         _grossValue = _grossValue.sub(_admincommission_3);

        uint256 _userTransfer = _grossValue.mul(activePhase._exchangeRate);                

        activePhase._remainingAllocation =  activePhase._remainingAllocation.sub(amount);

        phaseDetails[_phaseLiteral] = activePhase;        

        _transfer(address(this), msg.sender, _userTransfer); 

        return true;
    }

    /* Withdraw Deposited BNB*/
    function withdrawAllBNB() external onlyOwner returns(bool)
    {
        address payable _receiver = payable(msg.sender);
        _receiver.transfer(address(this).balance);

        return true;
    }

    function strCompare(string memory a, string memory b) pure internal returns (bool) {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    } 
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

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

/**
 *Submitted for verification at BscScan.com on 2021-09-30
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner,"Caller is Not owner");
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }
}