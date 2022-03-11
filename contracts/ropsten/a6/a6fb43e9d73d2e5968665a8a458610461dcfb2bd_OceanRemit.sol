/**
 *Submitted for verification at Etherscan.io on 2022-03-10
*/

/**
 *Submitted for verification at Etherscan.io on 2020-05-13
*/

/**
 *Submitted for verification at Etherscan.io on 2018-10-11
*/

pragma solidity ^0.4.24;

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
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


// File: openzeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    /**
     * @dev Multiplies two numbers, throws on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
     * @dev Integer division of two numbers, truncating the quotient.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
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
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}


// File: contracts/OceanRemit.sol

contract OceanRemit is Ownable {
    using SafeMath for uint256;
    
    string public name = "Ocean Remit Token";
    string public symbol = "OCT";
    uint8 public constant decimals = 8;
    uint256 public totalSupply = 0;
    
    mapping(address => uint256) internal balances;
    mapping(address => mapping (address => uint256)) internal allowed;

    mapping(address => bool) public canReceiveMintWhiteList;
    mapping(address => bool) public canBurnWhiteList;
    mapping(address => bool) public blackList;
    address public staker;

    uint256 public burnMin = 1000 * 10 ** uint256(decimals);
    uint256 public burnMax = 20000000 * 10 ** uint256(decimals);

    uint80 public transferFeeNumerator = 8;
    uint80 public transferFeeDenominator = 10000;
    uint80 public mintFeeNumerator = 0;
    uint80 public mintFeeDenominator = 10000;
    uint256 public mintFeeFlat = 0;
    uint80 public burnFeeNumerator = 0;
    uint80 public burnFeeDenominator = 10000;
    uint256 public burnFeeFlat = 0;
    bool public isTransferable;

    event ChangeBurnBoundsEvent(uint256 newMin, uint256 newMax);
    event Mint(address indexed to, uint256 amount);
    event Burn(uint256 amount);
    event WipedAccount(address indexed account, uint256 balance);
    event ModifyMintWhiteList(address mintAddress, bool isWhiteListed);
    event ModifyBurnWhiteList(address burnAddress, bool isWhiteListed);
    event ModifyBlackList(address blackAddress, bool isBlackListed);
    event Approval(address indexed owner, address indexed spender, uint256 value); // ERC20 standard event
    event Transfer(address indexed from, address indexed to, uint256 value); // ERC20 standard event
    
    constructor() public {
        totalSupply = 0;
    }

    function changeName(string _name, string _symbol) onlyOwner public {
        name = _name;
        symbol = _symbol;
    }
    
    // Modify mint white list
    function modifyMintWhiteList(address[] _mintAddrs, bool _isWhiteListed) onlyOwner public returns(bool) {
        for (uint256 i = 0; i < _mintAddrs.length; i++) {
            canReceiveMintWhiteList[_mintAddrs[i]] = _isWhiteListed;
            emit ModifyMintWhiteList(_mintAddrs[i], _isWhiteListed);
        }
        return true;
    }
    
    modifier transferable() {
        require(isTransferable == true);
        _;
    }
    
    // Modify burn white list
    function modifyBurnWhiteList(address[] _burnAddrs, bool _isWhiteListed) onlyOwner public returns(bool) {
        for (uint256 i = 0; i < _burnAddrs.length; i++) {
            canBurnWhiteList[_burnAddrs[i]] = _isWhiteListed;
            emit ModifyBurnWhiteList(_burnAddrs[i], _isWhiteListed);
        }
        return true;
    }
    
    // Modify black list
    function modifyBlackList(address[] _blackAddrs, bool _isBlackListed) onlyOwner public returns(bool) {
        for (uint256 i = 0; i < _blackAddrs.length; i++) {
            blackList[_blackAddrs[i]] = _isBlackListed;
            emit ModifyBlackList(_blackAddrs[i], _isBlackListed);
        }
        return true;
    }
    
    // ERC20 standard function
    function transfer(address _to, uint256 _value) external transferable returns (bool) {
        require(_to != address(0));
        require(_value > 0);
        bool isBlack = blackList[_to];
        require(!isBlack);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    // ERC20 standard function
    function transferFrom(address _from, address _to, uint256 _value) external transferable returns (bool) {
        require(_to != address(0));
        require(_from != address(0));
        require(_value > 0);
        bool isBlackFrom = blackList[_from];
        require(!isBlackFrom);
        bool isBlackTo = blackList[_to];
        require(!isBlackTo);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    // ERC20 standard function
    function approve(address _spender, uint256 _value) external transferable returns (bool) {
        require(_spender != address(0));
        require(_value > 0);
		
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
     // ERC20 standard function
    function allowance(address _owner, address _spender) external constant returns (uint256) {
        return allowed[_owner][_spender];
    }

    // ERC20 standard function
    function balanceOf(address _owner) external constant returns (uint256 balance) {
        return balances[_owner];
    }

    // Burning functions as withdrawing money from the system. The platform will keep track of who burns coins,
    // and will send them back the equivalent amount of money (rounded down to the nearest cent).
    function burn(uint256 _value) public {
        bool isBurn = canBurnWhiteList[msg.sender];
        require(isBurn);
        require(_value >= burnMin);
        require(_value <= burnMax);
        uint256 remaining = _value;
        totalSupply = totalSupply.sub(remaining);
        emit Burn(remaining);
    }

    // Create _amount new tokens and transfer them to _to.
    // Based on code by OpenZeppelin: https://github.com/OpenZeppelin/zeppelin-solidity/blob/master/contracts/token/MintableToken.sol
    function mint(address _to, uint256 _amount) onlyOwner public {
        bool isMint = canReceiveMintWhiteList[_to];
        require(isMint);
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
        
    }

    // Change the minimum and maximum amount that can be burned at once. Burning
    // may be disabled by setting both to 0 (this will not be done under normal
    // operation, but we can't add checks to disallow it without losing a lot of
    // flexibility since burning could also be as good as disabled
    // by setting the minimum extremely high, and we don't want to lock
    // in any particular cap for the minimum)
    function changeBurnBounds(uint newMin, uint newMax) onlyOwner public {
        require(newMin <= newMax);
        burnMin = newMin;
        burnMax = newMax;
        emit ChangeBurnBoundsEvent(newMin, newMax);
    }

    
    // Enable transfer feature of tokens
    function enableTokenTransfer() external onlyOwner {
        isTransferable = true;
    }

    function wipeBlacklistedAccount(address account) public onlyOwner {
        bool isBlack = blackList[account];
        require(isBlack);
        uint256 oldValue = balances[account];
        balances[account] = 0;
        totalSupply = totalSupply.sub(oldValue);
        emit WipedAccount(account, oldValue);
    }

}