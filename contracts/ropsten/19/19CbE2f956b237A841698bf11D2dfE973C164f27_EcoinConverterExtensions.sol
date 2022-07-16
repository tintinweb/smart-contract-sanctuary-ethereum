pragma solidity ^0.4.11;
import './TokenHolder.sol';
import './interfaces/IEcoinConverterExtensions.sol';

/**
    @dev the EcoinConverterExtensions contract is an owned contract that serves as a single point of access
    to the EcoinFormula, EcoinGasPriceLimit and EcoinQuickConverter contracts from all EcoinConverter contract instances.
    it allows upgrading these contracts without the need to update each and every
    EcoinConverter contract instance individually.
*/
contract EcoinConverterExtensions is IEcoinConverterExtensions, TokenHolder {
    IEcoinFormula public formula;  // bancor calculation formula contract
    IEcoinGasPriceLimit public gasPriceLimit; // bancor universal gas price limit contract
    IEcoinQuickConverter public quickConverter; // bancor quick converter contract

    /**
        @dev constructor

        @param _formula         address of a bancor formula contract
        @param _gasPriceLimit   address of a bancor gas price limit contract
        @param _quickConverter  address of a bancor quick converter contract
    */
    function EcoinConverterExtensions(IEcoinFormula _formula, IEcoinGasPriceLimit _gasPriceLimit, IEcoinQuickConverter _quickConverter)
        validAddress(_formula)
        validAddress(_gasPriceLimit)
        validAddress(_quickConverter)
    {
        formula = _formula;
        gasPriceLimit = _gasPriceLimit;
        quickConverter = _quickConverter;
    }

    /*
        @dev allows the owner to update the formula contract address

        @param _formula    address of a bancor formula contract
    */
    function setFormula(IEcoinFormula _formula)
        public
        ownerOnly
        validAddress(_formula)
        notThis(_formula)
    {
        formula = _formula;
    }

    /*
        @dev allows the owner to update the gas price limit contract address

        @param _gasPriceLimit   address of a bancor gas price limit contract
    */
    function setGasPriceLimit(IEcoinGasPriceLimit _gasPriceLimit)
        public
        ownerOnly
        validAddress(_gasPriceLimit)
        notThis(_gasPriceLimit)
    {
        gasPriceLimit = _gasPriceLimit;
    }

    /*
        @dev allows the owner to update the quick converter contract address

        @param _quickConverter  address of a bancor quick converter contract
    */
    function setQuickConverter(IEcoinQuickConverter _quickConverter)
        public
        ownerOnly
        validAddress(_quickConverter)
        notThis(_quickConverter)
    {
        quickConverter = _quickConverter;
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
import './IERC20Token.sol';

/*
    Ecoin Quick Converter interface
*/
contract IEcoinQuickConverter {
    function convert(IERC20Token[] _path, uint256 _amount, uint256 _minReturn) public payable returns (uint256);
    function convertFor(IERC20Token[] _path, uint256 _amount, uint256 _minReturn, address _for) public payable returns (uint256);
}

pragma solidity ^0.4.11;

/*
    Ecoin Gas Price Limit interface
*/
contract IEcoinGasPriceLimit {
    function gasPrice() public constant returns (uint256) {}
}

pragma solidity ^0.4.11;

/*
    Ecoin Formula interface
*/
contract IEcoinFormula {
    function calculatePurchaseReturn(uint256 _supply, uint256 _connectorBalance, uint32 _connectorWeight, uint256 _depositAmount) public constant returns (uint256);
    function calculateSaleReturn(uint256 _supply, uint256 _connectorBalance, uint32 _connectorWeight, uint256 _sellAmount) public constant returns (uint256);
}

pragma solidity ^0.4.11;
import './IEcoinFormula.sol';
import './IEcoinGasPriceLimit.sol';
import './IEcoinQuickConverter.sol';

/*
    Ecoin Converter Extensions interface
*/
contract IEcoinConverterExtensions {
    function formula() public constant returns (IEcoinFormula) {}
    function gasPriceLimit() public constant returns (IEcoinGasPriceLimit) {}
    function quickConverter() public constant returns (IEcoinQuickConverter) {}
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