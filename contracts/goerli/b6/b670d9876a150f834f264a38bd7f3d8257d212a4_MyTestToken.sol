/**
 *Submitted for verification at Etherscan.io on 2022-11-22
*/

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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: contracts/MyTestToken.sol


pragma solidity ^0.8.0;


contract MyTestToken is Ownable {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public _tokenSupply;
    uint256 public _totalSupply;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    event Transfer(address indexed owner, address indexed to, uint256 tokens);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 tokens
    );

    constructor(uint256 _newTokenSupply) {
        name = "MyTestToken";
        symbol = "MTN";
        decimals = 18;
        _tokenSupply = _newTokenSupply;
        _totalSupply = _tokenSupply * 10**decimals;

        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function totalSupply() public view returns (uint256 tokens) {
        return _totalSupply;
    }

    function balanceOf(address _address) public view returns (uint256 tokens) {
        return balances[_address];
    }

    function transfer(address _to, uint256 _tokens)
        public
        onlyOwner
        returns (bool success)
    {
        require(
            _tokens <= balances[msg.sender],
            "You have insufficient balance"
        );
        balances[msg.sender] = balances[msg.sender] - _tokens;
        balances[_to] = balances[_to] + _tokens;
        emit Transfer(msg.sender, _to, _tokens);
        return true;
    }

    function approve(address _spender, uint256 _tokens)
        public
        onlyOwner
        returns (bool success)
    {
        allowed[msg.sender][_spender] = _tokens;
        emit Approval(msg.sender, _spender, _tokens);
        return true;
    }

    function transferFrom(
        address _owner,
        address _to,
        uint256 _tokens
    ) public onlyOwner returns (bool success) {
        require(_tokens <= balances[_owner], "insufficient Tokens");
        require(
            _tokens <= allowed[_owner][msg.sender],
            "Your allowance limit exausted"
        );
        balances[_owner] = balances[_owner] - _tokens;
        balances[_to] = balances[_to] + _tokens;
        allowed[_owner][msg.sender] = allowed[_owner][msg.sender] - _tokens;
        emit Transfer(_owner, _to, _tokens);
        return true;
    }

    function allowance(address _owner, address _spender)
        public
        view
        onlyOwner
        returns (uint256 remainingTokens)
    {
        return allowed[_owner][_spender];
    }

    function addTokenSupply(uint256 _newTokenSupply) public onlyOwner {
        _tokenSupply += _newTokenSupply;
        _totalSupply = _tokenSupply * 10**decimals;
        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
}