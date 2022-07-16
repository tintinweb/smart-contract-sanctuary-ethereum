pragma solidity ^0.4.11;

import './interfaces/IOmgConverter.sol';
import './interfaces/IEcoinConverter.sol';
import './interfaces/ISmartToken.sol';
import './interfaces/IXYZToken.sol';
import './interfaces/IEcoinConverterExtensions.sol';
import './Owned.sol';
import './TokenHolder.sol';


contract GeneralConverter is Owned, TokenHolder {

    IOmgConverter public omgConverter;
    IEcoinConverter public ecoinConverter;
    ISmartToken private ecoin;
    IXYZToken private xyzToken;

    bool public conversionsEnabled = true;              // true if token conversions is enabled, false if not

    IEcoinConverterExtensions public extensions;       // ecoin converter extensions contract

    event OmgToEcoin(uint256 _omgAmount, uint256 _ecoinsAmount);
    event EcoinToOmg(uint256 _ecoinsAmount, uint256 _omgAmount);
    event EtherToOmg(uint256 _etherAmount, uint256 _omgAmount);
    event OmgToEther(uint256 _omgAmount, uint256 _etherAmount);
    event EcoinToOmgsh(uint256 _ecoinsAmount, uint256 _omgshAmount);
    event OmgshToEcoin(uint256 _omgshAmount, uint256 _ecoinsAmount);


    function GeneralConverter(IOmgConverter _omgConverter, IEcoinConverter _ecoinConverter, ISmartToken _ecoin, IXYZToken _xyzToken, IEcoinConverterExtensions _extensions)
    {
        omgConverter = _omgConverter;
        ecoinConverter = _ecoinConverter;
        ecoin = _ecoin;
        xyzToken = _xyzToken;
        extensions = _extensions;
    }

    modifier conversionsAllowed {
        assert(conversionsEnabled);
        _;
    }

    // verifies that the gas price is lower than the universal limit
    modifier validGasPrice() {
        assert(tx.gasprice <= extensions.gasPriceLimit().gasPrice());
        _;
    }

    function buyEcoinForOmg(uint256 _minReturn, uint256 _amount)
        public
        conversionsAllowed
        validGasPrice
        greaterThanZero(_minReturn)
        returns (uint256)
    {
        uint256 xyzCount = omgConverter.getXyz(_minReturn, _amount, msg.sender);
        ecoin.transfer(msg.sender, xyzCount);
        OmgToEcoin(_amount, xyzCount);
        return xyzCount;
    }

    function buyOmgForEcoin(uint256 _amount, uint256 _minReturn)
        public
        conversionsAllowed
        validGasPrice
        greaterThanZero(_minReturn)
        returns (uint256)
    {
        ecoinConverter.transferEcoin(msg.sender, _amount);
        uint256 omgCount = omgConverter.exchangeXyzToOmg(_minReturn, _amount, msg.sender);
        EcoinToOmg(_amount, omgCount);
        return omgCount;
    }

    function buyOmgForEther(uint256 _minReturn)
        public
        payable
        conversionsAllowed
        validGasPrice
        greaterThanZero(_minReturn)
        returns (uint256)
    {
        uint256 ecoinCount = ecoinConverter.buy.value(msg.value)(1);
        uint256 omgCount = omgConverter.exchangeXyzToOmg(_minReturn, ecoinCount, msg.sender);
        EtherToOmg(msg.value, omgCount);
        return omgCount;
    }

    function buyEtherForOmg(uint256 _minReturn, uint256 _amount) 
        public
        conversionsAllowed
        validGasPrice
        greaterThanZero(_minReturn)
        returns (uint256)
    {
        uint256 xyzCount = omgConverter.getXyz(1, _amount, msg.sender);
        uint256 ethCount = ecoinConverter.sell(xyzCount, _minReturn);
        msg.sender.transfer(ethCount);
        OmgToEther(_amount, ethCount);
        return ethCount;
    }

    function buyOmgshForEcoin(uint256 _amount, uint256 _minReturn)
        public
        conversionsAllowed
        validGasPrice
        greaterThanZero(_minReturn)
        returns (uint256)
    {
        ecoinConverter.transferEcoin(msg.sender, _amount);
        uint256 omgshCount = omgConverter.exchangeXyzToOmgsh(_minReturn, _amount, msg.sender);
        EcoinToOmgsh(_amount, omgshCount);
        return omgshCount;
    }

    function sellOmgshForEcoin(uint256 _amount, uint256 _minReturn)
        public
        conversionsAllowed
        validGasPrice
        greaterThanZero(_minReturn)
        returns (uint256)
    {
        uint256 xyzCount = omgConverter.exchangeOmgshToXyz(_minReturn, _amount, msg.sender);
        ecoin.transfer(msg.sender, xyzCount);
        OmgshToEcoin(_amount, xyzCount);
        return xyzCount;
    }
    
    function withdrawXyz(address _to, uint256 _amount)
        ownerOnly
        public
    {
        xyzToken.transfer(_to, _amount);
    }

    function withdrawEcoin(address _to, uint256 _amount)
        ownerOnly
        public
    {
        ecoin.transfer(_to, _amount);
    }

    /*
        @dev allows the owner to update the extensions contract address

        @param _extensions    address of a ecoin converter extensions contract
    */
    function setExtensions(IEcoinConverterExtensions _extensions)
        public
        ownerOnly
        notThis(_extensions)
    {
        extensions = _extensions;
    }

    function() payable {
    }

}

pragma solidity ^0.4.11;
import './IOwned.sol';
import './IERC20Token.sol';

/*
    XYZ Token interface
*/
contract IXYZToken is IOwned, IERC20Token {
    function disableTransfers(bool _disable) public;
    function issue(address _to, uint256 _amount) public;
    function destroy(address _from, uint256 _amount) public;
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

contract IOmgConverter {
    function getXyz(uint256 _minReturn, uint256 _amount, address _to) public returns (uint256);
    function exchangeXyzToOmg(uint256 _minReturn, uint256 _amount, address _to) public returns (uint256);
    function exchangeXyzToOmgsh(uint256 _minReturn, uint256 _amount, address _to) public returns (uint256);
    function exchangeOmgshToXyz(uint256 _minReturn, uint256 _amount, address _to) public returns (uint256);
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

contract IEcoinConverter {
    function buyOmgForEcoin(address _to, uint256 _amount) public;
    function buy(uint256 _minReturn) public payable returns (uint256);
    function exchangeEcoinToEther(uint256 _minReturn, uint256 _amount, address _to) public returns (uint256);
    function transferEcoin(address _from, uint256 _amount) public returns (uint256);
    function sell(uint256 _sellAmount, uint256 _minReturn) public returns (uint256);
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