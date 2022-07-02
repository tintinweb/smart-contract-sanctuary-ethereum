// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./TexavieCoin.sol";

contract Agent {

    struct User {
        string email;
        address _address;
        uint256 balance;
    }

    address admin;
    TexavieCoin private tokenContract;
    uint256 private numCoinsRewarded;
    address[] private usersAddressesPool;

    mapping(address => User) private userInfoFromAddress;
    mapping(string => address) private userAddressFromEmail;

    event CoinsRewarded(address userAddress, uint256 value, uint256 balance);
    event CoinsDeducted(address userAddress, uint256 value, uint256 balance);

    modifier existingUserCheck(string memory _email) {
        require(bytes(_email).length > 0, "Email is empty");
        require(
            userAddressFromEmail[_email] != address(0),
            "No user for this email"
        );
        _;
    }

    modifier onlyAdmin() {
        require(
            msg.sender == admin,
            "Only the admin of the Agent Contract can call this function"
        );
        _;
    }

    constructor(TexavieCoin _tokenContract) {
        tokenContract = _tokenContract;
        admin = msg.sender;
    }

    /**
     * @dev Function to get a user's Texavie Coin balance by email
     * @param _email User's email address used to sign into the ios app
     */
    function getUserBalanceByEmail(string memory _email)
        public
        view
        existingUserCheck(_email)
        returns (uint256)
    {
        address userAddress = userAddressFromEmail[_email];
        return userInfoFromAddress[userAddress].balance;
    }

    /**
     * @dev Function to get the totoal number of Texavie Coins that have been rewarded to users.
     * @return Totoal number of Texavie Coins that have been rewarded to users.
     */
    function getNumCoinsRewarded() public view returns (uint256) {
        return numCoinsRewarded;
    }

    /**
     * @dev Function to reward Texavie Coins to a user.
     */
    function rewardCoinsToUser(
        address _userAddress,
        string memory _email,
        uint256 _numberOfCoins
    ) public onlyAdmin {
        require(_userAddress != address(0), "User address is 0");
        require(bytes(_email).length > 0, "Email is empty");
        require(
            tokenContract.balanceOf(address(this)) >= _numberOfCoins,
            "Insufficienet balance in agent contract"
        );
        require(
            tokenContract.transfer(_userAddress, _numberOfCoins),
            "Unsuccessful transfer"
        );

        numCoinsRewarded += _numberOfCoins;

        if (userAddressFromEmail[_email] == address(0)) {
            User memory newUser = User(_email, _userAddress, _numberOfCoins);
            userInfoFromAddress[_userAddress] = newUser;
            userAddressFromEmail[_email] = _userAddress;
        } else {
            userInfoFromAddress[_userAddress].balance += _numberOfCoins;
        }
        emit CoinsRewarded(_userAddress, _numberOfCoins,  userInfoFromAddress[_userAddress].balance);
    }


    /**
     * @dev Function to deduct Texavie Coins from a user.
     */
    function deductCoinsFromUser(
        address _userAddress,
        string memory _email,
        uint256 _numberOfCoins
    ) public payable existingUserCheck(_email) {
        require(_userAddress != address(0), "User address is 0");
        require(tokenContract.balanceOf(_userAddress) >= _numberOfCoins, "Insufficient balance in user's account");
        require(tokenContract.transferFrom(_userAddress, address(this), _numberOfCoins), "Unsuccessful transaction");

        userInfoFromAddress[_userAddress].balance -= _numberOfCoins;
        numCoinsRewarded += _numberOfCoins;

        emit CoinsDeducted(_userAddress, _numberOfCoins,  userInfoFromAddress[_userAddress].balance);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;
import "./IERC20.sol";
import "./Ownable.sol";
import "./Pausable.sol";

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    /**
     * @dev Multiplies two numbers, throws on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
     * @dev Integer division of two numbers, truncating the quotient.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
     * @dev Adds two numbers, throws on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

contract TexavieCoin is IERC20, Ownable, Pausable {
    using SafeMath for uint256;

    string private constant name = "TEXAVIE COIN";
    string private constant symbol = "TEXAVIE";
    uint256 private constant decimals = 18;
    uint256 private totalSupply_ = 1000000000 * 10**6 * 10**9;
    bool private mintingFinished = false;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) internal allowed;

    event Mint(address indexed to, uint256 amount);
    event MintFinished();
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    modifier canMint() {
        require(!mintingFinished);
        _;
    }

    constructor() {
        balances[msg.sender] = totalSupply_;
    }

    /**
     * @dev Function to mint tokens
     * @param _to The address that will receive the minted tokens.
     * @param _amount The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(address _to, uint256 _amount)
        public
        onlyOwner
        canMint
        returns (bool)
    {
        totalSupply_ = totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
        return true;
    }

    /**
     * @dev Function to stop minting new tokens.
     * @return True if the operation was successful.
     */
    function finishMinting() public onlyOwner canMint returns (bool) {
        mintingFinished = true;
        emit MintFinished();
        return true;
    }

    /**
     * @dev total number of tokens in existence
     */
    function totalSupply() public view override returns (uint256) {
        return totalSupply_;
    }

    /**
     * @dev Gets the balance of the specified address.
     * @param _owner The address to query the the balance of.
     * @return An uint256 representing the amount owned by the passed address.
     */
    function balanceOf(address _owner) public view override returns (uint256) {
        return balances[_owner];
    }

    /**
     * @dev transfer token for a specified address
     * @param _to The address to transfer to.
     * @param _value The amount to be transferred.
     */
    function transfer(address _to, uint256 _value)
        public
        override
        whenNotPaused
        returns (bool)
    {
        require(_to != address(0), "to address is not valid");
        require(_value <= balances[msg.sender], "insufficient balance");

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public override whenNotPaused returns (bool) {
        require(_from != address(0), "ERC20: from address is not valid");
        require(_to != address(0), "to address is not valid");
        require(_value <= balances[_from], "insufficient balance");
        require(
            _value <= allowed[_from][msg.sender],
            "transfer from value not allowed"
        );

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * @param _spender The address which will spend the funds.
     * @param _value The amount of tokens to be spent.
     */
    function approve(address _spender, uint256 _value)
        public
        override
        whenNotPaused
        returns (bool)
    {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param _owner address The address which owns the funds.
     * @param _spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address _owner, address _spender)
        public
        view
        override
        returns (uint256)
    {
        return allowed[_owner][_spender];
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     *
     * approve should be called when allowed[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * @param _spender The address which will spend the funds.
     * @param _addedValue The amount of tokens to increase the allowance by.
     */
    function increaseApproval(address _spender, uint256 _addedValue)
        public
        whenNotPaused
        returns (bool success)
    {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(
            _addedValue
        );
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     *
     * approve should be called when allowed[_spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * @param _spender The address which will spend the funds.
     * @param _subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseApproval(address _spender, uint256 _subtractedValue)
        public
        whenNotPaused
        returns (bool success)
    {
        uint256 oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IERC20 {
    function balanceOf(address who) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address private owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), owner);
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./Ownable.sol";

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
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
    function pause() public onlyOwner whenNotPaused {
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