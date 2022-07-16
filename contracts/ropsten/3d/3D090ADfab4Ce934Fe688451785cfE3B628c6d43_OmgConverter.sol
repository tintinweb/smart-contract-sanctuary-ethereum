pragma solidity ^0.4.11;
import './XYZTokenController.sol';
import './Managed.sol';
import './OmgToken.sol';
import './XYZToken.sol';
import './interfaces/IXYZToken.sol';
import './interfaces/IEcoinConverterExtensions.sol';
import './interfaces/ISmartToken.sol';
import './interfaces/IOMGSHToken.sol';
import './interfaces/IEcoinConverter.sol';

contract OmgConverter is XYZTokenController, Managed {
    uint32 private constant MAX_CONVERSION_FEE = 1000000;
    uint32 private constant MAX_WEIGHT = 1000000;
    uint32 public constant CONNECTOR_WEIGHT = 500000;

    string public version = '0.1';

    uint256 public connectorBasket = 0;
    uint256 public connectorBasketAdmin = 0;

    uint256 public initialConnectorBasket = 0;
    uint256 public initialConnectorBasketAdmin = 0;

    uint256 public conversionFeeBasket = 0;

    IEcoinConverterExtensions public extensions;       // bancor converter extensions contract
    uint32 private totalConnectorWeight = 0;            // used to efficiently prevent increasing the total connector weight above 100%
    uint32 public maxConversionFee = 0;                 // maximum conversion fee for the lifetime of the contract, represented in ppm, 0...1000000 (0 = no fee, 100 = 0.01%, 1000000 = 100%)
    uint32 public conversionFee = 0;                    // current conversion fee, represented in ppm, 0...maxConversionFee
    bool public conversionsEnabled = true;              // true if token conversions is enabled, false if not
    bool public tokenSupplyInitialized = false;       // true if initial token supply hasn't been done yet

    IERC20Token public omgTokenAddress;
    IOMGSHToken public omgshToken;
    ISmartToken public smartToken;
    address public generalConverter;

    // triggered when a conversion between two tokens occurs (TokenConverter event)
    event Conversion(bool _omgToXyz, address indexed _trader, uint256 _sentAmount, uint256 _return,
                     uint256 _currentPriceN, uint256 _currentPriceD);
    //triggered when initial token supply had happened
    event InitialTokenSupply(address _executor, uint256 _omgAmount, uint256 _ratio, uint256 _tokenReturn, uint256 _tokenIssued);
    event ConversionFee(uint256 _feeAmount);
    event OmgTransferred(uint256 _amount);
    event BuyOMGSH(uint256 _buyAmount, uint256 _connectorBasketUpdate);
    event SellOMGSH(uint256 _buyAmount, uint256 _connectorBasketUpdate);
    event Log(uint256 abc, uint256 b, uint256 cabc, uint256 d);

    function OmgConverter(IXYZToken _token, IEcoinConverterExtensions _extensions, ISmartToken _smartToken, IOMGSHToken _omgshToken, uint32 _maxConversionFee)
        XYZTokenController(_token)
        validAddress(_extensions)
        validMaxConversionFee(_maxConversionFee)
    {
        extensions = _extensions;
        maxConversionFee = _maxConversionFee;
        smartToken = _smartToken;
        omgshToken = _omgshToken;
    }

    // verifies that the gas price is lower than the universal limit
    modifier validGasPrice() {
        assert(tx.gasprice <= extensions.gasPriceLimit().gasPrice());
        _;
    }

    // validates maximum conversion fee
    modifier validMaxConversionFee(uint32 _conversionFee) {
        require(_conversionFee >= 0 && _conversionFee <= MAX_CONVERSION_FEE);
        _;
    }

    // validates conversion fee
    modifier validConversionFee(uint32 _conversionFee) {
        require(_conversionFee >= 0 && _conversionFee <= maxConversionFee);
        _;
    }

    // allows execution only when conversions aren't disabled
    modifier conversionsAllowed {
        assert(conversionsEnabled);
        _;
    }

    function setExtensions(IEcoinConverterExtensions _extensions)
        public
        ownerOnly
        validAddress(_extensions)
        notThis(_extensions)
    {
        extensions = _extensions;
    }

    function disableConversions(bool _disable) public managerOnly {
        conversionsEnabled = !_disable;
    }

    modifier initialTokenSupplyAllowed {
        require(tokenSupplyInitialized == false);
        _;
    }

    function setConversionFee(uint32 _conversionFee)
        public
        managerOnly
        validConversionFee(_conversionFee)
    {
        conversionFee = _conversionFee;
    }

    function getConversionFeeAmount(uint256 _amount) public constant returns (uint256) {
        return safeMul(_amount, conversionFee) / MAX_CONVERSION_FEE;
    }

    function initialTokenSupply(uint256 _ratio, uint256 _amount)
        ownerOnly
        initialTokenSupplyAllowed
    {
        require(token.owner() == address(this));
        uint256 amointwithCoin = _amount;
        require(omgTokenAddress.balanceOf(msg.sender) >= amointwithCoin);
        omgTokenAddress.transferFrom(msg.sender, address(this), amointwithCoin);
        uint256 connectorBalance = amointwithCoin;
        connectorBasket += connectorBalance / 2;
        connectorBasketAdmin += connectorBalance / 2;
        initialConnectorBasket = connectorBasket;
        initialConnectorBasketAdmin = connectorBasketAdmin;
        uint256 tokenAmount = amointwithCoin * _ratio;
        token.issue(msg.sender, tokenAmount);
        InitialTokenSupply(msg.sender, amointwithCoin, _ratio, tokenAmount, token.totalSupply());
        tokenSupplyInitialized = true;
    }

    function setOmgToken(address _omgToken)
        ownerOnly
        public
    {
        omgTokenAddress = IERC20Token(_omgToken);
        omgshToken.setOmgToken(_omgToken);
    }

    function withdrawOmgFromConvertionFeeBasket(uint256 _amount) ownerOnly {
        require(_amount > 0 && _amount <= conversionFeeBasket);
        conversionFeeBasket -= _amount;
        omgTokenAddress.transfer(msg.sender, _amount);
        OmgTransferred(_amount);
    }

    function getPurchaseReturn(uint256 _depositAmount, uint256 _connectorBalance)
        private
        constant
        returns (uint256, uint256)
    {
        //getting fee amount from deposited Omg 
        uint256 feeAmount = getConversionFeeAmount(_depositAmount);
        uint256 tokenSupply = token.totalSupply();
        uint256 v = safeSub(_depositAmount, feeAmount);
        uint256 amount = extensions.formula().calculatePurchaseReturn(tokenSupply, _connectorBalance, CONNECTOR_WEIGHT, v);
        // deduct the fee from the return amount
        // ConversionFee(feeAmount);
        return (amount, feeAmount);
    }

    function getPurchaseReturn(uint256 _depositAmount) public constant returns(uint256, uint256) {
        return getPurchaseReturn(_depositAmount, connectorBasket);
    }

    function getPurchaseReturnAdmin(uint256 _depositAmount) constant returns(uint256, uint256) {
        return getPurchaseReturn(_depositAmount, connectorBasketAdmin);
    }        

    function getPurchaseReturnOmgsh(uint256 _depositAmount) public constant returns(uint256, uint256) {
        var (amount, feeAmount) = getPurchaseReturn(_depositAmount, connectorBasket);
        return getSaleReturn(amount, token.totalSupply() + amount, connectorBasketAdmin);
    }

    function getSaleReturnAdmin(uint256 _sellAmount) constant returns (uint256, uint256) {
        return getSaleReturn(_sellAmount, token.totalSupply(), connectorBasketAdmin);
    }

    function getSaleReturn(uint256 _sellAmount) public constant returns (uint256, uint256) {
        return getSaleReturn(_sellAmount, token.totalSupply(), connectorBasket);
    }

    function getSaleReturnOmgsh(uint256 _sellAmount) public constant returns(uint256, uint256) {
        var (amount, feeAmount) = getPurchaseReturn(_sellAmount, connectorBasketAdmin);
        return getSaleReturn(amount, token.totalSupply() + amount, connectorBasket);
    }

    function acceptOmgshTokenOwnership() 
        public
        ownerOnly
    {
        omgshToken.acceptOwnership();
    }

    function setGeneralConverter(address _generalConverter)
        public
        ownerOnly
    {
        require(generalConverter != _generalConverter);
        generalConverter = _generalConverter;
    }


    function buyXyz(uint256 _minReturn, uint256 _amount, uint256 _connectorBasket)
        private
        returns (uint256,uint256)
    {
        var (amount, feeAmount) = getPurchaseReturn(_amount, _connectorBasket);
        assert(amount != 0 && amount >= _minReturn);

        token.issue(address(this), amount);

        uint256 connectorAmount = safeMul(_connectorBasket, MAX_WEIGHT);
        uint256 tokenAmount = safeMul(token.totalSupply(), CONNECTOR_WEIGHT);
        conversionFeeBasket += feeAmount;
        Conversion(true, msg.sender, _amount, amount, connectorAmount, tokenAmount);
        return (amount, feeAmount);
    }

    function sellXyz(uint256 _minReturn, uint256 _amount, uint256 _connectorBasket)
        private
        returns (uint256,uint256)
    {
        var (amount, feeAmount) = getSaleReturn(_amount, token.totalSupply(), _connectorBasket);
        assert(amount != 0 && amount >= _minReturn);
        uint256 tokenSupply = token.totalSupply();
        assert(amount < _connectorBasket || (amount == _connectorBasket && _amount == tokenSupply));
        token.destroy(address(this), _amount);
        conversionFeeBasket += feeAmount;
        uint256 connectorAmount = safeMul(_connectorBasket, MAX_WEIGHT);
        uint256 tokenAmount = safeMul(token.totalSupply(), CONNECTOR_WEIGHT);
        Conversion(false, msg.sender, _amount, amount, tokenAmount, connectorAmount);
        return (amount, feeAmount);
    }

    function buyOmgsh(uint256 _minReturn, uint256 _amount)
        public
        conversionsAllowed
        validGasPrice
        greaterThanZero(_minReturn)
        returns (uint256)
    {
        require(tokenSupplyInitialized == true);
        omgTokenAddress.transferFrom(msg.sender, address(this), _amount);
        // uint256 amountBuy = buyXyz(1, _amount, connectorBasket);
        var (amount, feeAmount) = buyXyz(1, _amount, connectorBasket);
        connectorBasket += (_amount - feeAmount);
        var (sellAmount, sellFeeAmount) = sellXyz(_minReturn, amount, connectorBasketAdmin);
        connectorBasketAdmin -= (sellAmount + sellFeeAmount);
        omgTokenAddress.transfer(address(omgshToken), sellAmount);
        omgshToken.deposit(msg.sender, sellAmount);
        BuyOMGSH(sellAmount, connectorBasketAdmin);
        return sellAmount;
    }

    function sellOmgsh(uint256 _minReturn, uint256 _amount)
        public
        conversionsAllowed
        validGasPrice
        greaterThanZero(_minReturn)
        returns (uint256)
    {
        require(tokenSupplyInitialized == true);
        omgshToken.withdrawTo(msg.sender, _amount);
        //uint256 amountBuy = buyXyz(1, _amount, connectorBasketAdmin);
        var (amountBuy, feeAmount) = buyXyz(1, _amount, connectorBasketAdmin);
        connectorBasketAdmin += (_amount - feeAmount);
        var (amountSell, sellFeeAmount) = sellXyz(_minReturn, amountBuy, connectorBasket);
        connectorBasket -= (amountSell + sellFeeAmount);
        omgTokenAddress.transfer(msg.sender, amountSell);
        SellOMGSH(amountSell, connectorBasket);
        return amountSell;
    }

    function getXyz(uint256 _minReturn, uint256 _amount, address _to)
        public
        returns (uint256)
    {
        require(tokenSupplyInitialized == true);
        require(msg.sender == generalConverter);
        omgTokenAddress.transferFrom(_to, address(this), _amount);
        //uint256 xyzCount = buyXyz(_minReturn, _amount, connectorBasket);
        var (xyzCount, feeAmount) = buyXyz(1, _amount, connectorBasket);
        connectorBasket += (_amount - feeAmount);
        token.transfer(msg.sender, xyzCount);
        return xyzCount;
    }

    function exchangeXyzToOmg(uint256 _minReturn, uint256 _amount, address _to) 
        public
        returns (uint256)
    {
        require(tokenSupplyInitialized == true);
        require(msg.sender == generalConverter);

        token.destroy(msg.sender, _amount);
        token.issue(address(this), _amount);

        var (omgAmount, feeAmount) = sellXyz(_minReturn, _amount, connectorBasket);
        connectorBasket -= (omgAmount + feeAmount);
        omgTokenAddress.transfer(_to, omgAmount);
        return omgAmount;
    }

    function exchangeXyzToOmgsh(uint256 _minReturn, uint256 _amount, address _to) 
        public
        returns (uint256)
    {
        require(tokenSupplyInitialized == true);
        require(msg.sender == generalConverter);

        token.destroy(msg.sender, _amount);
        token.issue(address(this), _amount);

        var (omgAmount, feeAmount) = sellXyz(_minReturn, _amount, connectorBasketAdmin);
        connectorBasketAdmin -= (omgAmount + feeAmount);
        omgTokenAddress.transfer(address(omgshToken), omgAmount);
        omgshToken.deposit(_to, omgAmount);
        return omgAmount;
    }

    function exchangeOmgshToXyz(uint256 _minReturn, uint256 _amount, address _to) 
        public
        returns (uint256)
    {
        require(tokenSupplyInitialized == true);
        require(msg.sender == generalConverter);
        omgshToken.withdrawTo(_to, _amount);
        //uint256 xyzCount = buyXyz(_minReturn, _amount, connectorBasketAdmin);
        var (xyzCount, feeAmount) = buyXyz(_minReturn, _amount, connectorBasketAdmin);
        connectorBasketAdmin += (_amount - feeAmount);
        token.transfer(msg.sender, xyzCount);
        return xyzCount;
    }

    function getSaleReturn(uint256 _sellAmount, uint256 _totalSupply, uint256 _connectorBalance)
        private
        constant
        greaterThanZero(_totalSupply)
        returns (uint256, uint256)
    {
        // uint256 connectorBalance = getConnectorBalance();
        uint256 amount = extensions.formula().calculateSaleReturn(_totalSupply, _connectorBalance, CONNECTOR_WEIGHT, _sellAmount);

        // deduct the fee from the return amount
        uint256 feeAmount = getConversionFeeAmount(amount);
        return (safeSub(amount, feeAmount), feeAmount);
    }

    function getConnectorBalance(IERC20Token _connectorToken)
        public
        constant
        returns (uint256)
    {
        return _connectorToken.balanceOf(this);
    }

    function() payable {
        require(tokenSupplyInitialized == true);
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
import './IOwned.sol';
import './IERC20Token.sol';

/*
    Omg Token interface
*/
contract IOmgToken is IOwned, IERC20Token {
    function disableTransfers(bool _disable) public;
    function issue(address _to, uint256 _amount) public;
    function destroy(address _from, uint256 _amount) public;
}

pragma solidity ^0.4.11;
import './ITokenHolder.sol';
import './IERC20Token.sol';

contract IOMGSHToken is ITokenHolder, IERC20Token {
    function deposit(address _from, uint256 _amount) public;
    function withdrawTo(address _to, uint256 _amount);
    function issue(address _to, uint256 _amount) public;
    function destroy(address _from, uint256 _amount) public;
    function setOmgToken(address _omgToken) public;
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
import './TokenHolder.sol';
import './interfaces/IXYZToken.sol';

contract XYZTokenController is TokenHolder {
    IXYZToken public token;

    /**
        @dev constructor
    */
    function XYZTokenController(IXYZToken _token)
        validAddress(_token)
    {
        token = _token;
    }

    // ensures that the controller is the token's owner
    modifier active() {
        assert(token.owner() == address(this));
        _;
    }

    // ensures that the controller is not the token's owner
    modifier inactive() {
        assert(token.owner() != address(this));
        _;
    }

    function acceptTokenOwnership() public ownerOnly {
        token.acceptOwnership();
    }

    /**
        @dev withdraws tokens held by the token and sends them to an account
        can only be called by the owner

        @param _token   ERC20 token contract address
        @param _to      account to receive the new amount
        @param _amount  amount to withdraw
    */
    function withdrawFromToken(ISmartToken _token, address _to, uint256 _amount) public ownerOnly {
        ITokenHolder(token).withdrawTokens(_token, _to, _amount);
    }
}

pragma solidity ^0.4.11;
import './ERC20Token.sol';
import './TokenHolder.sol';
import './Owned.sol';
import './interfaces/IXYZToken.sol';

/*
    XYZToken v0.3

    'Owned' is specified here for readability reasons
*/
contract XYZToken is IXYZToken, Owned, ERC20Token, TokenHolder {
    string public version = '0.1';

    bool public transfersEnabled = true;    // true if transfer/transferFrom are enabled, false if not

    // triggered when a XYZ token is deployed - the _token address is defined for forward compatibility, in case we want to trigger the event from a factory
    event NewXYZToken(address _token);
    // triggered when the total supply is increased
    event Issuance(uint256 _amount);
    // triggered when the total supply is decreased
    event Destruction(uint256 _amount);

    /**
        @dev constructor

        @param _name       token name
        @param _symbol     token short symbol, minimum 1 character
        @param _decimals   for display purposes only
    */
    function XYZToken(string _name, string _symbol, uint8 _decimals)
        ERC20Token(_name, _symbol, _decimals)
    {
        NewXYZToken(address(this));
    }

    // allows execution only when transfers aren't disabled
    modifier transfersAllowed {
        assert(transfersEnabled);
        _;
    }

    /**
        @dev disables/enables transfers
        can only be called by the contract owner

        @param _disable    true to disable transfers, false to enable them
    */
    function disableTransfers(bool _disable) public ownerOnly {
        transfersEnabled = !_disable;
    }

    /**
        @dev increases the token supply and sends the new tokens to an account
        can only be called by the contract owner
        
        @param _to         account to receive the new amount
        @param _amount     amount to increase the supply by
    */
    function issue(address _to, uint256 _amount)
        public
        ownerOnly
        validAddress(_to)
        notThis(_to)
    {
        totalSupply = safeAdd(totalSupply, _amount);
        balanceOf[_to] = safeAdd(balanceOf[_to], _amount);

        Issuance(_amount);
        Transfer(this, _to, _amount);
    }

    /**
        @dev removes tokens from an account and decreases the token supply
        can be called by the contract owner to destroy tokens from any account or by any holder to destroy tokens from his/her own account

        @param _from       account to remove the amount from
        @param _amount     amount to decrease the supply by
    */
    function destroy(address _from, uint256 _amount) ownerOnly {
        balanceOf[_from] = safeSub(balanceOf[_from], _amount);
        totalSupply = safeSub(totalSupply, _amount);

        Transfer(_from, this, _amount);
        Destruction(_amount);
    }


    // ERC20 standard method overrides with some extra functionality

    /**
        @dev send coins
        throws on any error rather then return a false flag to minimize user errors
        in addition to the standard checks, the function throws if transfers are disabled

        @param _to      target address
        @param _value   transfer amount

        @return true if the transfer was successful, false if it wasn't
    */
    function transfer(address _to, uint256 _value) public transfersAllowed returns (bool success) {
        assert(super.transfer(_to, _value));
        return true;
    }

    /**
        @dev an account/contract attempts to get the coins
        throws on any error rather then return a false flag to minimize user errors
        in addition to the standard checks, the function throws if transfers are disabled

        @param _from    source address
        @param _to      target address
        @param _value   transfer amount

        @return true if the transfer was successful, false if it wasn't
    */
    function transferFrom(address _from, address _to, uint256 _value) public transfersAllowed returns (bool success) {
        assert(super.transferFrom(_from, _to, _value));
        return true;
    }
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

pragma solidity ^0.4.11;
import './ERC20Token.sol';
import './TokenHolder.sol';
import './Owned.sol';
import './interfaces/IOmgToken.sol';

/*
    Smart Token v0.3

    'Owned' is specified here for readability reasons
*/
contract OmgToken is IOmgToken, Owned, ERC20Token, TokenHolder {
    string public version = '0.1';

    bool public transfersEnabled = true;    // true if transfer/transferFrom are enabled, false if not

    // triggered when a smart token is deployed - the _token address is defined for forward compatibility, in case we want to trigger the event from a factory
    event NewOmgToken(address _token);
    // triggered when the total supply is increased
    event Issuance(uint256 _amount);
    // triggered when the total supply is decreased
    event Destruction(uint256 _amount);

    /**
        @dev constructor

        @param _name       token name
        @param _symbol     token short symbol, minimum 1 character
        @param _decimals   for display purposes only
    */
    function OmgToken(string _name, string _symbol, uint8 _decimals)
        ERC20Token(_name, _symbol, _decimals)
    {
        NewOmgToken(address(this));
    }

    // allows execution only when transfers aren't disabled
    modifier transfersAllowed {
        assert(transfersEnabled);
        _;
    }

    /**
        @dev disables/enables transfers
        can only be called by the contract owner

        @param _disable    true to disable transfers, false to enable them
    */
    function disableTransfers(bool _disable) public ownerOnly {
        transfersEnabled = !_disable;
    }

    /**
        @dev increases the token supply and sends the new tokens to an account
        can only be called by the contract owner
        
        @param _to         account to receive the new amount
        @param _amount     amount to increase the supply by
    */
    function issue(address _to, uint256 _amount)
        public
        ownerOnly
        validAddress(_to)
        notThis(_to)
    {
        totalSupply = safeAdd(totalSupply, _amount);
        balanceOf[_to] = safeAdd(balanceOf[_to], _amount);

        Issuance(_amount);
        Transfer(this, _to, _amount);
    }

    /**
        @dev removes tokens from an account and decreases the token supply
        can be called by the contract owner to destroy tokens from any account or by any holder to destroy tokens from his/her own account

        @param _from       account to remove the amount from
        @param _amount     amount to decrease the supply by
    */
    function destroy(address _from, uint256 _amount) ownerOnly {
        balanceOf[_from] = safeSub(balanceOf[_from], _amount);
        totalSupply = safeSub(totalSupply, _amount);

        Transfer(_from, this, _amount);
        Destruction(_amount);
    }


    // ERC20 standard method overrides with some extra functionality

    /**
        @dev send coins
        throws on any error rather then return a false flag to minimize user errors
        in addition to the standard checks, the function throws if transfers are disabled

        @param _to      target address
        @param _value   transfer amount

        @return true if the transfer was successful, false if it wasn't
    */
    function transfer(address _to, uint256 _value) public transfersAllowed returns (bool success) {
        assert(super.transfer(_to, _value));
        return true;
    }

    /**
        @dev an account/contract attempts to get the coins
        throws on any error rather then return a false flag to minimize user errors
        in addition to the standard checks, the function throws if transfers are disabled

        @param _from    source address
        @param _to      target address
        @param _value   transfer amount

        @return true if the transfer was successful, false if it wasn't
    */
    function transferFrom(address _from, address _to, uint256 _value) public transfersAllowed returns (bool success) {
        assert(super.transferFrom(_from, _to, _value));
        return true;
    }
}

pragma solidity ^0.4.11;

/*
    Provides support and utilities for contract management
*/
contract Managed {
    address public manager;
    address public newManager;

    event ManagerUpdate(address _prevManager, address _newManager);

    /**
        @dev constructor
    */
    function Managed() {
        manager = msg.sender;
    }

    // allows execution by the manager only
    modifier managerOnly {
        assert(msg.sender == manager);
        _;
    }

    /**
        @dev allows transferring the contract management
        the new manager still needs to accept the transfer
        can only be called by the contract manager

        @param _newManager    new contract manager
    */
    function transferManagement(address _newManager) public managerOnly {
        require(_newManager != manager);
        newManager = _newManager;
    }

    /**
        @dev used by a new manager to accept a management transfer
    */
    function acceptManagement() public {
        require(msg.sender == newManager);
        ManagerUpdate(manager, newManager);
        manager = newManager;
        newManager = 0x0;
    }
}

pragma solidity ^0.4.11;
import './Utils.sol';
import './interfaces/IERC20Token.sol';

/**
    ERC20 Standard Token implementation
*/
contract ERC20Token is IERC20Token, Utils {
    string public standard = 'Token 0.1';
    string public name = '';
    string public symbol = '';
    uint8 public decimals = 0;
    uint256 public totalSupply = 0;
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    /**
        @dev constructor

        @param _name        token name
        @param _symbol      token symbol
        @param _decimals    decimal points, for display purposes
    */
    function ERC20Token(string _name, string _symbol, uint8 _decimals) {
        require(bytes(_name).length > 0 && bytes(_symbol).length > 0); // validate input

        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    /**
        @dev send coins
        throws on any error rather then return a false flag to minimize user errors

        @param _to      target address
        @param _value   transfer amount

        @return true if the transfer was successful, false if it wasn't
    */
    function transfer(address _to, uint256 _value)
        public
        validAddress(_to)
        returns (bool success)
    {
        balanceOf[msg.sender] = safeSub(balanceOf[msg.sender], _value);
        balanceOf[_to] = safeAdd(balanceOf[_to], _value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
        @dev an account/contract attempts to get the coins
        throws on any error rather then return a false flag to minimize user errors

        @param _from    source address
        @param _to      target address
        @param _value   transfer amount

        @return true if the transfer was successful, false if it wasn't
    */
    function transferFrom(address _from, address _to, uint256 _value)
        public
        validAddress(_from)
        validAddress(_to)
        returns (bool success)
    {
        allowance[_from][msg.sender] = safeSub(allowance[_from][msg.sender], _value);
        balanceOf[_from] = safeSub(balanceOf[_from], _value);
        balanceOf[_to] = safeAdd(balanceOf[_to], _value);
        Transfer(_from, _to, _value);
        return true;
    }

    /**
        @dev allow another account/contract to spend some tokens on your behalf
        throws on any error rather then return a false flag to minimize user errors

        also, to minimize the risk of the approve/transferFrom attack vector
        (see https://docs.google.com/document/d/1YLPtQxZu1UAvO9cZ1O2RPXBbT0mooh4DYKjA_jp-RLM/), approve has to be called twice
        in 2 separate transactions - once to change the allowance to 0 and secondly to change it to the new allowance value

        @param _spender approved address
        @param _value   allowance amount

        @return true if the approval was successful, false if it wasn't
    */
    function approve(address _spender, uint256 _value)
        public
        validAddress(_spender)
        returns (bool success)
    {
        // if the allowance isn't 0, it can only be updated to 0 to prevent an allowance change immediately after withdrawal
        require(_value == 0 || allowance[msg.sender][_spender] == 0);

        allowance[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }
}