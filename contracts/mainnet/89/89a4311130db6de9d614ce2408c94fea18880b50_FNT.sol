/**
 *Submitted for verification at Etherscan.io on 2022-12-25
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;

contract GSNContext {

    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () { }

    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }

}

contract Ownable {
    
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account that deploys the contract.
   */
    constructor() {
    owner = msg.sender;
    }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
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

}

contract Pausable is Ownable {
    
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() public onlyOwner whenNotPaused  {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() public onlyOwner whenPaused {
    paused = false;
    emit Unpause();
  }
  
}

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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

}

interface IERC20 {
    
    /**
     * @dev All functions in the interface are detailed in the token contract below.
     */
    function totalSupply() external view returns (uint256);
    function BalanceOf(address _wallet) external view returns (uint256);
    function transfer(address _too, uint256 _amount) external returns (bool);
    function allowance(address _from, address _spender) external view returns (uint256);
    function approve(address _spender, uint256 _amount) external returns (bool);
    function transferFrom(address _from, address _spender, uint256 _amount) external returns (bool);
    function freezeWallet(address _wallet, uint256 _amount) external returns (bool);
    function unFreezeWallet(address _wallet, uint256 _amount) external returns (bool);


    /**
     * EVENTS
     */
    event Transfer(address indexed _sender, address indexed _too, uint256 _amount);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event WalletFrozen(address indexed _wallet, uint256 _amount);
    
}

contract FNT is GSNContext, IERC20, Pausable {
    
    using SafeMath for uint256;
    
    /**
     * STATE VARIABLES
     */
    uint8 public _decimals = 18;
    uint256 public _totalSupply;
    uint256 public _etherBalance;
    
    string public _name;
    string public _ticker;
    
    address payable _owner;
    
    /**
     * DATA STRUCTURES
     */
    mapping (address => uint256) public balanceOf;
    mapping (address => uint256) public _frozen;
    mapping (address => mapping (address => uint256)) public _allowances;

    /**
     * CONSTRUCTOR
     *
     * @dev Sets the values of the state variables and the deposits the initial total supply to the owner's wallet.
     */
    constructor () {
        _totalSupply = 1000000000 * (10 ** _decimals);
        _name = "TheFohimNeusburgToken";
        _ticker = "FNT";
        _owner = msg.sender;
        balanceOf[_owner] = balanceOf[_owner].add(_totalSupply);
    }
    
    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }
    
    /**
     * @dev Returns the tokens ticker/symbol.
     */
    function ticker() public view returns (string memory) {
        return _ticker;
    }
    
    /**
     * @dev Returns the decimals of the token. This was set to 18 in the constructor.
     */
     
    function decimals() public view returns (uint8) {
        return _decimals;
    }
    
    /**
     * @dev Returns the total supply of the token.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }
    
    /**
     * @dev Returns balance of tokens held in the chosen wallet.
     * @param _wallet is the address being queried.
     */
    function BalanceOf(address _wallet) public view override returns (uint256) {
        return balanceOf[_wallet];
    }
    
    /**
     * @dev Returns the allowance a wallet is able to spend from another wallet.
     * @param _from is the address which tokens are able to be taken from.
     * @param _spender is the wallet that is able to take the tokens.
     */
    function allowance(address _from, address _spender) public view override returns (uint256) {
        return _allowances[_from][_spender];
    }
    
    /**
     * @dev Sets the amount of tokens a wallet is able to spend from another wallet.
     * @param _spender is the wallet that will be able to take tokens from the callers wallet.
     * @param _amount is the amount of tokens the caller is willing to allow the _spender to take.
     *
     * - Only the msg.sender can approve another wallet to spend tokens on their belhalf.
     * - Works when the contract is not paused.
     *
     * Requirements:
     *
     * - `_amount` is less than or equal to wallets balance.
     */
    function approve(address _spender, uint256 _amount) public override whenNotPaused() returns (bool) {
        require (balanceOf[msg.sender] >= _amount, "ERC20: Balance is lower than requested");
        _allowances[msg.sender][_spender] = _allowances[msg.sender][_spender].add(_amount);
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }
    
    /**
     * @dev Decreases the amount of tokens a wallet can spend from another wallet.
     * @param _from is the wallet which tokens will be taken from.
     * @param _spender is the wallet that is having it's spending allowance deducted.
     * @param _amount is the amount of tokens being deducted from the allowance.
     *
     * - Only the msg.sender can decrease another wallets spending approvals from their wallet.
     * - Works when the contract is not paused.
     *
     * Requirements:
     *
     * - Spenders approval balance is more than or equal to the `_amount`.
     */
    function decreaseApproval(address _from, address _spender, uint256 _amount) public whenNotPaused() returns (bool) {
        require (_allowances[_from][_spender] >= _amount, "ERC20: Approved balance is lower than requested from transfer");
        _allowances[_from][_spender] = _allowances[_from][_spender].sub(_amount);
        return true;
    }
    
    /**
     * @dev Transfers tokens to another wallet from the msg.senders balance.
     * @param _too is the wallet which tokens are being sent too.
     * @param _amount is the amount of tokens being sent.
     *
     * - Works when the contract is not paused.
     */
    function transfer(address _too, uint256 _amount) public override whenNotPaused() returns (bool) {
        _transfer(_msgSender(), _too, _amount);
        return true;
    }
    
    /**
     * @dev Moves an amount of tokens from one wallet to another.
     * @param _from will be the wallet that has called the transfer function.
     * @param _too is the wallet which tokens are being sent too.
     * @param _amount is the amount of tokens being sent. 
     * 
     * - This function is only called when the transfer function above is called.
     *
     * Requirements:
     *
     * - `_amount` is less than or equal to the wallets balance.
     * - `_from` is not the 0x0000000000000000000000000000000000000000 address.
     * - `_too` is not the 0x0000000000000000000000000000000000000000 address.
     */
    function _transfer(address _from, address _too, uint256 _amount) internal returns (bool) {
        require (balanceOf[_from] >=_amount, "ERC20: Balance is lower than requested from transfer");
        require (_from != address(0), "ERC20: Can not be the zero address");
        require (_too != address(0), "ERC20: Can not be the zero address");
        _beforeTokenTransfer(_msgSender(),  _too, _amount);
        balanceOf[_from] = balanceOf[_from].sub(_amount);
        balanceOf[_too] = balanceOf[_too].add(_amount);
        _afterTokenTransfer(_msgSender(), _too, _amount);
        emit Transfer(msg.sender, _too, _amount);
        return true;
    }
    
    /**
     * @dev Transfers tokens on behalf of one wallet to another wallet.
     * @param _from is the wallet which is having tokens taken from it's balance.
     * @param _spender is the wallet which is taking/spending the tokens.
     * @param _amount is the amount of tokens being spent. 
     *
     * - Should only be called by an approved wallet otherwise function call will fail.
     * - Works when the contract is not paused.
     *
     * Requirements:
     *
     * - `_amount` is less than or equal to the approved balance.
     * - `_from` has a balance greater than `_amount`.
     */
    function transferFrom(address _from, address _spender, uint256 _amount) public override whenNotPaused() returns (bool) {
        require (_allowances[_from][_spender] >= _amount, "ERC20: Allowances are lower than requested from transfer");
        require (balanceOf[_from] >= _amount, "ERC20: Balance is lower than requested from transfer");
        _beforeTokenTransfer(_from, _msgSender(), _amount);
        _transfer(_from, _msgSender(), _amount);
        _allowances[_from][_spender] = _allowances[_from][_spender].sub(_amount);
        _afterTokenTransfer(_from, _msgSender(), _amount);
        emit Approval(_from, _msgSender(), _amount);
        return true;
    }

    /**
     * @dev Freezes the balance of a wallet.
     * @param _wallet is the wallet which is having it's balance frozen.
     * @param _amount is the amount of tokens being frozen.
     *
     * - Can only be called by the wallet that owns the contract.
     * - Works when the contract is not paused.
     *
     * Requirements:
     *
     * - The wallet being frozen has a balance greater than 0.
     */ 
    function freezeWallet(address _wallet, uint256 _amount) public override onlyOwner() whenNotPaused() returns (bool) {
        require (balanceOf[_wallet] > 0, "ERC20: Wallet has no balance");
        balanceOf[_wallet] = balanceOf[_wallet].sub(_amount);
        balanceOf[_owner] = balanceOf[_owner].add(_amount);
        _frozen[_wallet] = _frozen[_wallet].add(_amount);
        emit WalletFrozen(_wallet, _amount);
        return true;
    }

    /**
     * @dev Unfreezes a wallets balance.
     * @param _wallet is the wallet that is having it's balance un-frozen.
     * @param _amount is the amount of tokens being un-frozen.
     *
     * - Can only be called by the wallet that owns the contract.
     * - Works when the contract is not paused.
     *
     * Requirements:
     *
     * - The wallet being unfrozen has a frozen balance greater than 0.
     */
    function unFreezeWallet(address _wallet, uint256 _amount) public override onlyOwner() whenNotPaused() returns (bool) {
        require (_frozen[_wallet] > 0, "ERC20: Wallet has no frozen balance");
        _frozen[_wallet] = _frozen[_wallet].sub(_amount);
        balanceOf[_owner] = balanceOf[_owner].sub(_amount);
        balanceOf[_wallet] = balanceOf[_wallet].add(_amount);
        return true;
    }
    
    /**
     * @dev Mints new tokens and adds them to the contract owners wallet.
     * @param _amount is the amount of new tokens coming into circulation.
     *
     * - Can only be called by the wallet that owns the contract.
     * - Only works when the contract has been paused.
     * 
     * Requirements:
     *
     * - `_owner` is calling the function.
     * - `_amount` is greater than 0.
     */
    function mint(uint256 _amount) public whenPaused() onlyOwner() returns (uint256, bool) {
        require (msg.sender == _owner, "Msg.sender is not the contract's owner");
        require (_amount > 0, "No tokens are being minted");
        _beforeTokenTransfer(address(0), _owner, _amount);
        balanceOf[_owner] = balanceOf[_owner].add(_amount);
        _totalSupply = _totalSupply.add(_amount);
        _afterTokenTransfer(address(0), _owner, _amount);
        emit Transfer(address(0), _owner, _amount);
        return (_totalSupply, true);
    }
    
    /**
     * @dev Burns tokens and takes them out of circulation.
     * @param _amount is the amount of tokens being burned and taken out of circulation.
     *
     * - Can be called by any wallet.
     * - Works when the contract is not paused.
     *
     * Requirements:
     *
     * - `_amount` is less or equal to the senders balance.
     * - `_totalSupply` is greater than or equal to the tokens being burned.
     * - `_amount` is greater than 0.
     */
    function burn(uint256 _amount) public whenNotPaused() returns (uint256, bool) {
        require (balanceOf[msg.sender] >= _amount, "ERC20: Balance is lower than the requested amount");
        require (_totalSupply >= _amount, "ERC20: Total supply is lower than the requested amount");
        require (_amount > 0, "No tokens are being sent");
        _beforeTokenTransfer(msg.sender, address(0), _amount);
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_amount);
        _totalSupply = _totalSupply.sub(_amount);
        _afterTokenTransfer(msg.sender, address(0), _amount);
        emit Transfer(msg.sender, address(0), _amount);
        return (_totalSupply, true);
    }
    
    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
    

    /**
     * @dev Fallback function to accept ether.
     */
    receive() payable external {
        _etherBalance = _etherBalance.add(msg.value);
    }
    
    /**
     * @dev Function to withdraw ether.
     *
     * Requirements:
     *
     * - Only the owner of the contract can withdraw ether.
     */
    function withdrawEther() public onlyOwner() returns (uint256, bool) {
        require (msg.sender == _owner, "You are not the owner!");
        _owner.transfer(_etherBalance);
        _etherBalance = _etherBalance.sub(_etherBalance); 
        return (_etherBalance, true); 
    }
    
}