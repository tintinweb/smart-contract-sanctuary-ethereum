/**
 *Submitted for verification at Etherscan.io on 2022-02-10
*/

/**
 *Submitted for verification at Etherscan.io on 2019-06-14
*/

// @dev ERC20 compliance requires syntax of solidity 0.4.17 or above (previous token contract is at ^0.4.8). 
pragma solidity 0.4.24;

// @dev unchanged
contract Owned {
    address public owner;

    function changeOwner(address _addr) onlyOwner {
        if (_addr == 0x0) throw;
        owner = _addr;
    }

    modifier onlyOwner {
        if (msg.sender != owner) throw;
        _;
    }
}

// @dev unchanged
contract Mutex is Owned {
    bool locked = false;
    modifier mutexed {
        if (locked) throw;
        locked = true;
        _;
        locked = false;
    }

    function unMutex() onlyOwner {
        locked = false;
    }
}

/**
 * @title SafeMath
 * @author OpenZeppelin
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

contract Token is Owned, Mutex {
    // @dev using OpenZeppelin's SafeMath library
    using SafeMath for uint256;

    Ledger public ledger;

    uint256 public lockedSupply = 0;

    string public name;
    uint8 public decimals; 
    string public symbol;

    string public version = '0.2'; 
    bool public transfersOn = true;

    // @notice Constructs a Token
    // @dev changed to comply with 0.4.17 and above syntax,
    // but later versions could use 'constructor(...)' syntax
    // @param _owner Intended owner of the Token contract
    // @param _tokenName Intended name of the Token
    // @param _decimals Intended precision of the Token
    // @param _symbol Intended symbol of the Token
    // @param _ledger Intended address of the Ledger
    constructor(address _owner, string _tokenName, uint8 _decimals,
                string _symbol, address _ledger) public {
        require(_owner != address(0), "address cannot be null");
        owner = _owner;

        name = _tokenName;
        decimals = _decimals;
        symbol = _symbol;

        ledger = Ledger(_ledger);
    }

    /*
    *   Bookkeeping and Admin Functions
    */

    // @notice Event emitted when the Ledger is updated
    // @param _from Address that updates the Ledger
    // @param _ledger Address of the Ledger
    event LedgerUpdated(address _from, address _ledger);



    // @notice Allow the owner to change the address of the Ledger
    // @param _addr Intended new address of the Ledger
    function changeLedger(address _addr) onlyOwner public {
        require(_addr != address(0), "address cannot be null");
        ledger = Ledger(_addr);
    
        emit LedgerUpdated(msg.sender, _addr);
    }

    /*
    * Locking is a feature that turns a user's balances into
    * un-issued tokens, taking them out of an account and reducing the supply.
    * Diluting is so named to remind the caller that they are changing the money supply.
    */

    // @notice Allows owner to lock the balance of an address,
    // reducing the total circulating supply by the balance of that address
    // and increasing the locked supply of Tokens
    // @param _seizeAddr Intended address whose account balance is to be frozen
    function lock(address _seizeAddr) onlyOwner mutexed public {
        require(_seizeAddr != address(0), "address cannot be null");

        uint256 myBalance = ledger.balanceOf(_seizeAddr);
        lockedSupply = lockedSupply.add(myBalance);
        ledger.setBalance(_seizeAddr, 0);
    }

    // @notice Event that marks a "dilution" to a target address and the amount
    // @param _destAddr Intended address of the Token "dilution"
    // @param _amount Intended amount to be given to _destAddr
    event Dilution(address _destAddr, uint256 _amount);

    // @notice Allows the owner to unlock some of the locked supply
    // and give it to another address, increasing the circulating Token supply
    // (not exactly a true dilution of the current Token supply)
    // @param _destAddr Intended address of the recipient of the unlocked amount
    // @param amount Intended amount to be given to _destAddr
    function dilute(address _destAddr, uint256 amount) onlyOwner public {
        require(amount <= lockedSupply, "amount greater than lockedSupply");

        lockedSupply = lockedSupply.sub(amount);

        uint256 curBalance = ledger.balanceOf(_destAddr);
        curBalance = curBalance.add(amount);
        ledger.setBalance(_destAddr, curBalance);

        emit Dilution(_destAddr, amount);
    }

    // @notice Allow the owner to pause arbitrary transfers of Tokens
    function pauseTransfers() onlyOwner public {
        transfersOn = false;
    }

    // @notice Allow the owner to resume arbitrary transfers of Tokens
    function resumeTransfers() onlyOwner public {
        transfersOn = true;
    }

    /*
    * Burning -- We allow any user to burn tokens.
    *
     */

    // @notice Allows any arbitrary user to burn their Tokens
    // @param _amount Number of Tokens a user wants to burn
    function burn(uint256 _amount) public {
        uint256 balance = ledger.balanceOf(msg.sender);
        require(_amount <= balance, "not enough balance");
        ledger.setBalance(msg.sender, balance.sub(_amount));
        emit Transfer(msg.sender, 0, _amount);
    }

    /*
    Entry
    */

    // @notice Event for transfer of Tokens
    // @param _from Address from which the Tokens were transferred
    // @param _to Address to which the Tokens were transferred
    // @param _value Amount of Tokens transferred
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    // @notice Event for approval of Tokens for some other user
    // @param _owner Owner of the Tokens
    // @param _spender Address that the owner approved for spending Tokens
    // @param _value Amount of Tokens allocated for spending
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    // @notice Function to view the total circulating supply of Token
    // @dev Needs to interact with Ledger
    function totalSupply() public view returns(uint256) {
        return ledger.totalSupply();
    }

    // @notice Transfers Tokens to another user
    // @dev Needs to interact with Ledger
    function transfer(address _to, uint256 _value) public returns(bool) {
        require(transfersOn || msg.sender == owner, "transferring disabled");
        require(ledger.tokenTransfer(msg.sender, _to, _value), "transfer failed");

        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    // @notice Transfers Tokens from one user to another via an approved third party
    // @dev Needs to interact with Ledger
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(transfersOn || msg.sender == owner, "transferring disabled");
        require(ledger.tokenTransferFrom(msg.sender, _from, _to, _value), "transferFrom failed");

        emit Transfer(_from, _to, _value);
        uint256 allowed = allowance(_from, msg.sender);
        emit Approval(_from, msg.sender, allowed);
        return true;
    }

    // @notice Views the allowance of a third party given by an owner of Tokens
    // @dev Needs to interact with Ledger
    function allowance(address _owner, address _spender) public view returns(uint256) {
        return ledger.allowance(_owner, _spender); 
    }

    // @notice Allows a user to approve another user to spend an amount of Tokens on their behalf
    // @dev Needs to interact with Ledger
    function approve(address _spender, uint256 _value) public returns (bool) {
        require(ledger.tokenApprove(msg.sender, _spender, _value), "approve failed");
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    // @notice Views the Token balance of a user
    // @dev Needs to interact with Ledger
    function balanceOf(address _addr) public view returns(uint256) {
        return ledger.balanceOf(_addr);
    }
}

contract Ledger is Owned {
    mapping (address => uint) balances;
    mapping (address => uint) usedToday;

    mapping (address => bool) seenHere;
    address[] public seenHereA;

    mapping (address => mapping (address => uint256)) allowed;
    address token;
    uint public totalSupply = 0;

    function Ledger(address _owner, uint _preMined, uint ONE) {
        if (_owner == 0x0) throw;
        owner = _owner;

        seenHere[_owner] = true;
        seenHereA.push(_owner);

        totalSupply = _preMined *ONE;
        balances[_owner] = totalSupply;
    }

    modifier onlyToken {
        if (msg.sender != token) throw;
        _;
    }

    modifier onlyTokenOrOwner {
        if (msg.sender != token && msg.sender != owner) throw;
        _;
    }


    function tokenTransfer(address _from, address _to, uint amount) onlyToken returns(bool) {
        if (amount > balances[_from]) return false;
        if ((balances[_to] + amount) < balances[_to]) return false;
        if (amount == 0) { return false; }

        balances[_from] -= amount;
        balances[_to] += amount;

        if (seenHere[_to] == false) {
            seenHereA.push(_to);
            seenHere[_to] = true;
        }

        return true;
    }

    function tokenTransferFrom(address _sender, address _from, address _to, uint amount) onlyToken returns(bool) {
        if (allowed[_from][_sender] <= amount) return false;
        if (amount > balanceOf(_from)) return false;
        if (amount == 0) return false;

        if ((balances[_to] + amount) < amount) return false;

        balances[_from] -= amount;
        balances[_to] += amount;
        allowed[_from][_sender] -= amount;

        if (seenHere[_to] == false) {
            seenHereA.push(_to);
            seenHere[_to] = true;
        }

        return true;
    }


    function changeUsed(address _addr, int amount) onlyToken {
        int myToday = int(usedToday[_addr]) + amount;
        usedToday[_addr] = uint(myToday);
    }

    function resetUsedToday(uint8 startI, uint8 numTimes) onlyTokenOrOwner returns(uint8) {
        uint8 numDeleted;
        for (uint i = 0; i < numTimes && i + startI < seenHereA.length; i++) {
            if (usedToday[seenHereA[i+startI]] != 0) { 
                delete usedToday[seenHereA[i+startI]];
                numDeleted++;
            }
        }
        return numDeleted;
    }

    function balanceOf(address _addr) constant returns (uint) {
        // don't forget to subtract usedToday
        if (usedToday[_addr] >= balances[_addr]) { return 0;}
        return balances[_addr] - usedToday[_addr];
    }

    event Approval(address, address, uint);

    function tokenApprove(address _from, address _spender, uint256 _value) onlyToken returns (bool) {
        allowed[_from][_spender] = _value;
        Approval(_from, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    function changeToken(address _token) onlyOwner {
        token = Token(_token);
    }

    function reduceTotalSupply(uint amount) onlyToken {
        if (amount > totalSupply) throw;

        totalSupply -= amount;
    }

    function setBalance(address _addr, uint amount) onlyTokenOrOwner {
        if (balances[_addr] == amount) { return; }
        if (balances[_addr] < amount) {
            // increasing totalSupply
            uint increase = amount - balances[_addr];
            totalSupply += increase;
        } else {
            // decreasing totalSupply
            uint decrease = balances[_addr] - amount;
            //TODO: safeSub
            totalSupply -= decrease;
        }
        balances[_addr] = amount;
    }

}