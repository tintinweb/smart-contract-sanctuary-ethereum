pragma solidity ^0.4.11;
import './TokenHolder.sol';
import './Owned.sol';
import './Utils.sol';
import './interfaces/ISmartToken.sol';

/*
    EcoinPriceFloor v0.1

    The bancor price floor contract is a simple contract that allows selling smart tokens for a constant ETH price

    'Owned' is specified here for readability reasons
*/
contract EcoinPriceFloor is Owned, TokenHolder {
    uint256 public constant TOKEN_PRICE_N = 1;      // crowdsale price in wei (numerator)
    uint256 public constant TOKEN_PRICE_D = 100;    // crowdsale price in wei (denominator)

    string public version = '0.1';
    ISmartToken public token; // smart token the contract allows selling

    /**
        @dev constructor

        @param _token   smart token the contract allows selling
    */
    function EcoinPriceFloor(ISmartToken _token)
        validAddress(_token)
    {
        token = _token;
    }

    /**
        @dev sells the smart token for ETH
        note that the function will sell the full allowance amount

        @return ETH sent in return
    */
    function sell() public returns (uint256 amount) {
        uint256 allowance = token.allowance(msg.sender, this); // get the full allowance amount
        assert(token.transferFrom(msg.sender, this, allowance)); // transfer all tokens from the sender to the contract
        uint256 etherValue = safeMul(allowance, TOKEN_PRICE_N) / TOKEN_PRICE_D; // calculate ETH value of the tokens
        msg.sender.transfer(etherValue); // send the ETH amount to the seller
        return etherValue;
    }

    /**
        @dev withdraws ETH from the contract

        @param _amount  amount of ETH to withdraw
    */
    function withdraw(uint256 _amount) public ownerOnly {
        msg.sender.transfer(_amount); // send the amount
    }

    /**
        @dev deposits ETH in the contract
    */
    function() public payable {
    }
}

pragma solidity ^0.4.11;
import './IOwned.sol';
import './ISmartToken.sol';

/*
    Token Holder interface
*/
contract ITokenHolder is IOwned {
    function withdrawTokens(ISmartToken _token, address _to, uint256 _amount) public;
}

pragma solidity ^0.4.11;
import './IOwned.sol';
import './IERC20Token.sol';

/*
    Smart Token interface
*/
contract ISmartToken is IOwned, IERC20Token {
    function disableTransfers(bool _disable) public;
    function issue(address _to, uint256 _amount) public;
    function destroy(address _from, uint256 _amount) public;
}

pragma solidity ^0.4.11;

/*
    Owned contract interface
*/
contract IOwned {
    // this function isn't abstract since the compiler emits automatically generated getter functions as external
    function owner() public constant returns (address) {}

    function transferOwnership(address _newOwner) public;
    function acceptOwnership() public;
}

pragma solidity ^0.4.11;

/*
    ERC20 Standard Token interface
*/
contract IERC20Token {
    // these functions aren't abstract since the compiler emits automatically generated getter functions as external
    function name() public constant returns (string) {}
    function symbol() public constant returns (string) {}
    function decimals() public constant returns (uint8) {}
    function totalSupply() public constant returns (uint256) {}
    function balanceOf(address _owner) public constant returns (uint256) { _owner; }
    function allowance(address _owner, address _spender) public constant returns (uint256) { _owner; _spender; }

    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
}

pragma solidity ^0.4.11;

/*
    Utilities & Common Modifiers
*/
contract Utils {
    /**
        constructor
    */
    function Utils() {
    }

    // verifies that an amount is greater than zero
    modifier greaterThanZero(uint256 _amount) {
        require(_amount > 0);
        _;
    }

    // validates an address - currently only checks that it isn't null
    modifier validAddress(address _address) {
        require(_address != 0x0);
        _;
    }

    // verifies that the address is different than this contract address
    modifier notThis(address _address) {
        require(_address != address(this));
        _;
    }

    // Overflow protected math functions

    /**
        @dev returns the sum of _x and _y, asserts if the calculation overflows

        @param _x   value 1
        @param _y   value 2

        @return sum
    */
    function safeAdd(uint256 _x, uint256 _y) internal returns (uint256) {
        uint256 z = _x + _y;
        assert(z >= _x);
        return z;
    }

    /**
        @dev returns the difference of _x minus _y, asserts if the subtraction results in a negative number

        @param _x   minuend
        @param _y   subtrahend

        @return difference
    */
    function safeSub(uint256 _x, uint256 _y) internal returns (uint256) {
        assert(_x >= _y);
        return _x - _y;
    }

    /**
        @dev returns the product of multiplying _x by _y, asserts if the calculation overflows

        @param _x   factor 1
        @param _y   factor 2

        @return product
    */
    function safeMul(uint256 _x, uint256 _y) internal returns (uint256) {
        uint256 z = _x * _y;
        assert(_x == 0 || z / _x == _y);
        return z;
    }
}

pragma solidity ^0.4.11;
import './Owned.sol';
import './Utils.sol';
import './interfaces/ISmartToken.sol';
import './interfaces/ITokenHolder.sol';

/*
    We consider every contract to be a 'token holder' since it's currently not possible
    for a contract to deny receiving tokens.

    The TokenHolder's contract sole purpose is to provide a safety mechanism that allows
    the owner to send tokens that were sent to the contract by mistake back to their sender.
*/
contract TokenHolder is ITokenHolder, Owned, Utils {
    /**
        @dev constructor
    */
    function TokenHolder() {
    }

    /**
        @dev withdraws tokens held by the contract and sends them to an account
        can only be called by the owner

        @param _token   ERC20 token contract address
        @param _to      account to receive the new amount
        @param _amount  amount to withdraw
    */
    function withdrawTokens(ISmartToken _token, address _to, uint256 _amount)
        public
        ownerOnly
        validAddress(_token)
        validAddress(_to)
        notThis(_to)
    {
        assert(_token.transfer(_to, _amount));
    }
}

pragma solidity ^0.4.11;
import './interfaces/IOwned.sol';

/*
    Provides support and utilities for contract ownership
*/
contract Owned is IOwned {
    address public owner;
    address public newOwner;

    event OwnerUpdate(address _prevOwner, address _newOwner);

    /**
        @dev constructor
    */
    function Owned() {
        owner = msg.sender;
    }

    // allows execution by the owner only
    modifier ownerOnly {
        assert(msg.sender == owner);
        _;
    }

    /**
        @dev allows transferring the contract ownership
        the new owner still needs to accept the transfer
        can only be called by the contract owner

        @param _newOwner    new contract owner
    */
    function transferOwnership(address _newOwner) public ownerOnly {
        require(_newOwner != owner);
        newOwner = _newOwner;
    }

    /**
        @dev used by a new owner to accept an ownership transfer
    */
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        OwnerUpdate(owner, newOwner);
        owner = newOwner;
        newOwner = 0x0;
    }
}