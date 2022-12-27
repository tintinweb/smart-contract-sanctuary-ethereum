// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;


import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PlanetToken is  IERC20, IERC20Metadata,Context,Ownable{

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    address private Owner;
    bool private SeasonIsActive;

    event Tx(address indexed _from, address indexed _to, uint _amount);
    event BuyTokens(address indexed _from, uint _amount);

    constructor(
    string memory name_, 
    string memory symbol_, 
    address safeAccount,
    uint256 initialSupply) {
        _name = name_;
        _symbol = symbol_;
        Owner = safeAccount;
        _mint(safeAccount, initialSupply * (10 ** uint256(decimals())));
        _transferOwnership(safeAccount);
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }


    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

  
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

   
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        if(SeasonIsActive){
            address owner = _msgSender();
            _transfer(owner, to, amount);
            return true;
        }
        return false;
    }

   
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];

    }

    
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        if(SeasonIsActive){
            address owner = _msgSender();
            _approve(owner, spender, amount);
            return true;
        }
        return false;    
    }

   
    function transferFrom(
        address from,
        address to,
        uint256 amount
        ) public virtual override returns (bool) {
            if(SeasonIsActive){
                address spender = _msgSender();
                _spendAllowance(from, spender, amount);
                _transfer(from, to, amount);
                emit Tx(from,to,amount);
                return true;
            }
            return false;
        }

  
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        if(SeasonIsActive){
            address owner = _msgSender();
            _approve(owner, spender, allowance(owner, spender) + addedValue);
            return true;
        }
        return false;
    }

   
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        if(SeasonIsActive){
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
        }
        return  false;
    }

 
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        if(SeasonIsActive){
            require(from != address(0), "ERC20: transfer from the zero address");
            require(to != address(0), "ERC20: transfer to the zero address");

            _beforeTokenTransfer(from, to, amount);

            uint256 fromBalance = _balances[from];
            require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
            unchecked {
                _balances[from] = fromBalance - amount;
            }
            _balances[to] += amount;

            emit Transfer(from, to, amount);

            _afterTokenTransfer(from, to, amount);
        }

    }

 
    function _mint(address account, uint256 amount) public virtual {
        if(msg.sender == Owner){
            require(account != address(0), "ERC20: mint to the zero address");

            _beforeTokenTransfer(address(0), account, amount);

            _totalSupply += amount;
            _balances[account] += amount;
            emit Transfer(address(0), account, amount);

            _afterTokenTransfer(address(0), account, amount);
        }
    }
    
    
    function _burn(address account, uint256 amount) public virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        if(msg.sender == Owner){
            _beforeTokenTransfer(account, address(0), amount);

            uint256 accountBalance = _balances[account];
            require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
            unchecked {
                _balances[account] = accountBalance - amount;
            }
            _totalSupply -= amount;

            emit Transfer(account, address(0), amount);

            _afterTokenTransfer(account, address(0), amount);
        }
    }

  
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        if(SeasonIsActive){
            require(owner != address(0), "ERC20: approve from the zero address");
            require(spender != address(0), "ERC20: approve to the zero address");

            _allowances[owner][spender] = amount;
            emit Approval(owner, spender, amount);
        }
    }
    receive() external payable{
        uint tokensToBuy = msg.value;
        require(tokensToBuy > 0,"Error enough funds");
        require(SeasonIsActive = true,"Error season");
        require(balanceOf(address(this)) >= tokensToBuy,"Error enough tokens");

        transfer(msg.sender, tokensToBuy);
        emit BuyTokens(msg.sender, tokensToBuy);
    }


    fallback() external payable{
    }



    function withdraw(address payable _to, uint256 amount) external{
        require(msg.sender == Owner,"ERR NOT OWN!");
        transfer(_to,amount);
    }
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        if(SeasonIsActive){
            uint256 currentAllowance = allowance(owner, spender);
            if (currentAllowance != type(uint256).max) {
                require(currentAllowance >= amount, "ERC20: insufficient allowance");
                unchecked {
                    _approve(owner, spender, currentAllowance - amount);
                }
            }
        }
    }

    function StartSeason() public{
        if(msg.sender == Owner){
            SeasonIsActive = true;
        }
    }
    function EndSeason() public{
        if(msg.sender == Owner){
            SeasonIsActive = false;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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