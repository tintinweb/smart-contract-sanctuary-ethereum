// SPDX-License-Identifier: No-License
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract ERC20 is Ownable {
    string private _name = "MyToken";

    string private _symbol = "MTN";

    uint8 private _decimals = 18;

    uint256 private _totalSupply;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    event Deprival(address indexed _owner, address indexed _spender, uint256 _value);

    constructor() {
        mint(msg.sender, 1e18);
    }

    function name() public view returns(string memory) {
        return _name;
    }

    function symbol() public view returns(string memory) {
        return _symbol;
    }

    function decimals() public view returns(uint8) {
        return _decimals;
    }

    function totalSupply() public view returns(uint256) {
        return _totalSupply;
    }

    function balanceOf(address _owner) public view returns(uint256 balance) {
        return _balances[_owner];
    }

    function transfer(address _to, uint256 _value) public returns(bool success) {
        require(_balances[msg.sender] >= _value, "not enough balance");
        
        _balances[msg.sender] -= _value;
        _balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        success = true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns(bool success) {
        require(_balances[_from] >= _value, "not enough balance");
        require(allowance(_from, _to) >= _value, "access denied");
        _balances[_from] -= _value;
        _balances[_to] += _value;
        _allowances[_from][_to] -= _value;
        emit Transfer(_from, _to, _value);
        success = true;
    }

    function approve(address _spender, uint256 _value) public returns(bool success) {
        _allowances[msg.sender][_spender] = _value;        
        emit Approval(msg.sender, _spender, _value);
        success = true;
    }

    function increaseAllowance(address _spender, uint256 _value) public returns(bool success) {
        require(_balances[msg.sender] >= _value, "not enough balance");
        _allowances[msg.sender][_spender] += _value;
        emit Approval(msg.sender, _spender, _value);
        success = true;
    }

    function deprive(address _spender, uint _value) public returns(bool success) {
        require(allowance(msg.sender, _spender) >= _value, "deprived value is too huge");
        _allowances[msg.sender][_spender] -= _value;
        emit Deprival(msg.sender, _spender, _value);
        success = true;
    }

    function allowance(address _owner, address _spender) public view returns(uint256 remaining) {
        remaining = _allowances[_owner][_spender];
    }

    function mint(address _to, uint256 _value) public onlyOwner returns(bool success) {
        _totalSupply += _value;
        _balances[_to] += _value;
        emit Transfer(address(0), _to, _value);
        success = true;
    }

    function burn(address _from, uint _value) public onlyOwner returns(bool success) {
        require(_balances[_from] >= _value, "not enough tokens to burn");
        _totalSupply -= _value;
        _balances[_from] -= _value;
        
        emit Transfer(_from, address(0), _value);
        success = true;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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