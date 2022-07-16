pragma solidity ^0.4.11;
import './SmartTokenController.sol';
import './Managed.sol';
import './interfaces/ISmartToken.sol';
import './interfaces/IEthshToken.sol';
import './interfaces/IEcoinConverterExtensions.sol';

/*
    Ecoin Converter v0.1

    The Ecoin version of the token converter, allows conversion between a smart token and ETH cryptocurrency and vice versa.
*/
contract EcoinConverter is SmartTokenController, Managed {
    uint32 private constant MAX_CONVERSION_FEE = 1000000;
    uint32 private constant MAX_WEIGHT = 1000000;
    uint32 public constant CONNECTOR_WEIGHT = 500000;

    string public version = '0.1';

    uint256 public connectorBasket = 0;
    uint256 public connectorBasketAdmin = 0;

    uint256 public initialConnectorBasket = 0;
    uint256 public initialConnectorBasketAdmin = 0;

    uint256 public conversionFeeBasket = 0;

    IEthshToken public ethshToken;
    IEcoinConverterExtensions public extensions;       // ecoin converter extensions contract
    uint32 private totalConnectorWeight = 0;            // used to efficiently prevent increasing the total connector weight above 100%
    uint32 public maxConversionFee = 0;                 // maximum conversion fee for the lifetime of the contract, represented in ppm, 0...1000000 (0 = no fee, 100 = 0.01%, 1000000 = 100%)
    uint32 public conversionFee = 0;                    // current conversion fee, represented in ppm, 0...maxConversionFee
    bool public conversionsEnabled = true;              // true if token conversions is enabled, false if not
    bool public tokenSupplyInitialized = false;       // true if initial token supply hasn't been done yet
    address public generalConverter;

    // triggered when a conversion between two tokens occurs (TokenConverter event)
    event Conversion(bool _etherToEcoin, address indexed _trader, uint256 _sentAmount, uint256 _return,
                     uint256 _currentPriceN, uint256 _currentPriceD);
    //triggered when initial token supply had happened
    event InitialTokenSupply(address _executor, uint256 _etherAmount, uint256 _ratio, uint256 _tokenReturn, uint256 _tokenIssued);
    event ConversionFee(uint256 _feeAmount);
    event EtherTransferred(uint256 _amount);
    event BuyETSH(uint256 _ecoinsGeneratedAmount,  uint256 _buyAmount, uint256 _connectorBasketUpdate, uint256 _sellAmount, uint256 _connectorBasketAdmin);
    event SellEcoinForETSH(uint256 _ecoinsAmount, uint256 _connectorBasketAdminUpdate, uint256 _etshAmount);
    /**
        @dev constructor

        @param  _token              smart token governed by the converter
        @param  _extensions         address of a ecoin converter extensions contract
        @param  _maxConversionFee   maximum conversion fee, represented in ppm
    */
    function EcoinConverter(ISmartToken _token, IEthshToken _ethshToken, IEcoinConverterExtensions _extensions, uint32 _maxConversionFee)
        SmartTokenController(_token, _ethshToken)
        validAddress(_extensions)
        validMaxConversionFee(_maxConversionFee)
    {
        extensions = _extensions;
        maxConversionFee = _maxConversionFee;
        ethshToken = _ethshToken;
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

    /*
        @dev allows the owner to update the extensions contract address

        @param _extensions    address of a ecoin converter extensions contract
    */
    function setExtensions(IEcoinConverterExtensions _extensions)
        public
        ownerOnly
        validAddress(_extensions)
        notThis(_extensions)
    {
        extensions = _extensions;
    }

    /**
        @dev disables the entire conversion functionality
        this is a safety mechanism in case of a emergency
        can only be called by the manager

        @param _disable true to disable conversions, false to re-enable them
    */

    function disableConversions(bool _disable) public managerOnly {
        conversionsEnabled = !_disable;
    }

    modifier initialTokenSupplyAllowed {
        require(tokenSupplyInitialized == false);
        _;
    }   

    /**
        @dev updates the current conversion fee
        can only be called by the manager

        @param _conversionFee new conversion fee, represented in ppm
    */
    function setConversionFee(uint32 _conversionFee)
        public
        managerOnly
        validConversionFee(_conversionFee)
    {
        conversionFee = _conversionFee;
    }

    /*
        @dev returns the conversion fee amount for a given return amount

        @return conversion fee amount
    */
    function getConversionFeeAmount(uint256 _amount) public constant returns (uint256) {
        return safeMul(_amount, conversionFee) / MAX_CONVERSION_FEE;
    }

    /*
        @dev used only once for initial Ecoin purchase by admin
    */
    function initialTokenSupply(uint256 _ratio)
        ownerOnly
        payable
        initialTokenSupplyAllowed
        {
            require(token.owner() == address(this));
            require(msg.value > 0);
            uint256 connectorBalance = msg.value;
            connectorBasket += connectorBalance / 2;
            connectorBasketAdmin += connectorBalance / 2;
            initialConnectorBasket = connectorBasket;
            initialConnectorBasketAdmin = connectorBasketAdmin;
            uint256 tokenAmount = msg.value * _ratio;
            token.issue(msg.sender, tokenAmount);
            InitialTokenSupply(msg.sender, msg.value, _ratio, tokenAmount, token.totalSupply());
            tokenSupplyInitialized = true;
    }

    function withdrawEthFromConvertionFeeBasket(uint256 _amount) ownerOnly {
        require(_amount > 0 && _amount <= conversionFeeBasket);
        conversionFeeBasket -= _amount;
        msg.sender.transfer(_amount);
        EtherTransferred(_amount);
    }

    /**
        @dev returns the expected return for buying the token for a connector token

        @param _depositAmount   amount to deposit (in ETH)

        @param _connectorBalance    amount of ETH on connector basket

        @return expected purchase return amount
    */
    function getPurchaseReturn(uint256 _depositAmount, uint256 _connectorBalance)
        private
        constant
        returns (uint256, uint256)
    {
        //getting fee amount from deposited ETH 
        uint256 feeAmount = getConversionFeeAmount(_depositAmount);
        uint256 tokenSupply = token.totalSupply();
        uint256 amount = extensions.formula().calculatePurchaseReturn(tokenSupply, _connectorBalance, CONNECTOR_WEIGHT, safeSub(_depositAmount, feeAmount));
        // deduct the fee from the return amount
        ConversionFee(feeAmount);
        return (amount, feeAmount);
    }

    function getPurchaseReturn(uint256 _depositAmount) public constant returns(uint256, uint256) {
        return getPurchaseReturn(_depositAmount, connectorBasket);
    }

    function getPurchaseReturnAdmin(uint256 _depositAmount) constant returns(uint256, uint256) {
        return getPurchaseReturn(_depositAmount, connectorBasketAdmin);
    }        

    function getPurchaseReturnGeneral(uint256 _depositAmount, uint256 _tokenSupply, uint256 _connectorBalance, uint32 _conversionFee) public constant returns(uint256, uint256)
    {
        uint256 _feeAmount = safeMul(_depositAmount, _conversionFee) / MAX_CONVERSION_FEE;
        //uint256 tokenSupply = token.totalSupply();
        uint256 amount = extensions.formula().calculatePurchaseReturn(_tokenSupply, _connectorBalance, CONNECTOR_WEIGHT, safeSub(_depositAmount, _feeAmount));
        return (amount, _feeAmount);
    }

    /**
        @dev returns the expected return for selling the token for one of its connector tokens

        @param _sellAmount      amount to sell (in the smart token)

        @return expected sale return amount
    */
    function getSaleReturnAdmin(uint256 _sellAmount) constant returns (uint256, uint256) {
        // return getSaleReturn(_sellAmount, token.totalSupply(), connectorBasketAdmin);
        return getSaleReturn(_sellAmount, connectorBasketAdmin);
    }

    function getSaleReturn(uint256 _sellAmount) public constant returns (uint256, uint256) {
        //return getSaleReturn(_sellAmount, token.totalSupply(), connectorBasket);
        return getSaleReturn(_sellAmount, connectorBasket);
    }

    /**
        @dev buys the token by depositing ETH

        @param _minReturn  if the conversion results in an amount smaller than the minimum return - it is cancelled, must be nonzero

        @return buy return amount
    */
    function buy(uint256 _minReturn, uint256 _connectorBasket, uint256 _value, address _address)
        private
        conversionsAllowed
        validGasPrice
        greaterThanZero(_minReturn)
        returns (uint256, uint256)
    {
        var (amount, feeAmount) = getPurchaseReturn(_value, _connectorBasket);
        assert(amount != 0 && amount >= _minReturn); // ensure the trade gives something in return and meets the minimum requested amount

        // issue new funds to the caller in the smart token
        token.issue(_address, amount);
        // calculate the new price using the simple price formula
        // price = connector balance / (supply * weight)
        // weight is represented in ppm, so multiplying by 1000000
        uint256 connectorAmount = safeMul(_connectorBasket, MAX_WEIGHT);
        uint256 tokenAmount = safeMul(token.totalSupply(), CONNECTOR_WEIGHT);
        conversionFeeBasket += feeAmount;
        Conversion(true, _address, _value, amount, connectorAmount, tokenAmount);
        return (amount, feeAmount);
    }

    /**
        @dev buys the token by depositing ETH (for for users)

        @param _minReturn  if the conversion results in an amount smaller than the minimum return - it is cancelled, must be nonzero

        @return buy return amount
    */
    function buy(uint256 _minReturn)
        public
        payable
        conversionsAllowed
        validGasPrice
        greaterThanZero(_minReturn)
        returns (uint256)
    { 
        require(tokenSupplyInitialized == true);
        var(amount, feeAmount) = buy(_minReturn, connectorBasket, msg.value, msg.sender);
        connectorBasket += (msg.value - feeAmount);
        return amount;
    }

    /**
        @dev buys the token by depositing ETH (for admin)

        @param _minReturn  if the conversion results in an amount smaller than the minimum return - it is cancelled, must be nonzero

        @return buy return amount
    */
    function buyForAdmin(uint256 _minReturn)
        public
        ownerOnly
        payable
        conversionsAllowed
        validGasPrice
        greaterThanZero(_minReturn)
        returns (uint256)
    {
        require(tokenSupplyInitialized == true);
        var (amount, feeAmount) = buy(_minReturn, connectorBasketAdmin, msg.value, msg.sender);
        connectorBasketAdmin += (msg.value - feeAmount);
        return amount;
    }

    /**
        @dev buys the ETSH token by depositing ETH

        @param _minReturn  if the conversion results in an amount smaller than the minimum return - it is cancelled, must be nonzero

        @return buy return amount
    */
    function buyETSH(uint256 _minReturn)
        public
        payable
        conversionsAllowed
        validGasPrice
        greaterThanZero(_minReturn)
        returns (uint256)
    {
        require(tokenSupplyInitialized == true);
        var (ecoinAmount, purchaseFeeAmount) = getPurchaseReturn(msg.value, connectorBasket);
        connectorBasket += (msg.value - purchaseFeeAmount);
        conversionFeeBasket += purchaseFeeAmount;
        var (sellAmount, saleFeeAmount) = getSaleReturnAdmin(ecoinAmount);
        connectorBasketAdmin -= sellAmount;
        conversionFeeBasket += saleFeeAmount;
        ethshToken.deposit.value(sellAmount)(msg.sender);
        BuyETSH(ecoinAmount, sellAmount, connectorBasket, 0, connectorBasketAdmin);
        return sellAmount;
    }


    /**
        @dev sells the token by withdrawing from one of its connector tokens

        @param _sellAmount      amount to sell (in the smart token)

        @param _minReturn  if the conversion results in an amount smaller than the minimum return - it is cancelled, must be nonzero

        @return sell return amount
    */
    function sell(uint256 _sellAmount, uint256 _minReturn, uint256 _connectorBasket, address _address)
        private
        conversionsAllowed
        validGasPrice
        greaterThanZero(_minReturn)
        returns (uint256,uint256)
    {
        require(_sellAmount <= token.balanceOf(_address)); // validate input

        //var (amount, feeAmount) = getSaleReturn(_sellAmount);
        //var (amount, feeAmount) = getSaleReturn(_sellAmount, token.totalSupply(), _connectorBasket);
        var (amount, feeAmount) = getSaleReturn(_sellAmount, _connectorBasket);
        
        assert(amount != 0 && amount >= _minReturn); // ensure the trade gives something in return and meets the minimum requested amount

        uint256 tokenSupply = token.totalSupply();
        // ensure that the trade will only deplete the connector if the total supply is depleted as well
        assert(amount < _connectorBasket || (amount == _connectorBasket && _sellAmount == tokenSupply));
        token.destroy(_address, _sellAmount);
        _address.transfer(amount);
        conversionFeeBasket += feeAmount;
        // calculate the new price using the simple price formula
        // price = connector balance / (supply * weight)
        // weight is represented in ppm, so multiplying by 1000000
        uint256 connectorAmount = safeMul(_connectorBasket, MAX_WEIGHT);
        uint256 tokenAmount = safeMul(token.totalSupply(), CONNECTOR_WEIGHT);
        Conversion(false, _address, _sellAmount, amount, tokenAmount, connectorAmount);
        return (amount, feeAmount);
    }

    function sell(uint256 _sellAmount, uint256 _minReturn)
        public
        conversionsAllowed
        validGasPrice
        greaterThanZero(_minReturn)
        returns (uint256)
    {
        require(tokenSupplyInitialized == true);
        var (amount, feeAmount) = sell(_sellAmount, _minReturn, connectorBasket, msg.sender);
        connectorBasket -= (amount + feeAmount);
        return amount;
    }

    /**
        @dev sells the token by withdrawing from one of its connector tokens (for admin)

        @param _sellAmount      amount to sell (in the smart token)

        @param _minReturn  if the conversion results in an amount smaller than the minimum return - it is cancelled, must be nonzero

        @return sell return amount
    */
    function sellForAdmin(uint256 _sellAmount, uint256 _minReturn)
        public
        ownerOnly
        conversionsAllowed
        validGasPrice
        greaterThanZero(_minReturn)
        returns (uint256)
    {
        require(tokenSupplyInitialized == true);
        var (amount, feeAmount) = sell(_sellAmount, _minReturn, connectorBasketAdmin, msg.sender); // ???????? connectorBasketAdmin
        connectorBasketAdmin -= (amount + feeAmount);
        return amount;
    }

    /**
        @dev sells the token for EtherToken (ETSH)

        @param _sellAmount      amount to sell (in the smart token)

        @param _minReturn  if the conversion results in an amount smaller than the minimum return - it is cancelled, must be nonzero

        @return sell return amount
    */
    function sellEcoinForEtsh(uint256 _sellAmount, uint256 _minReturn)
        public
        conversionsAllowed
        validGasPrice
        greaterThanZero(_minReturn)
        returns (uint256)
    {
        require(tokenSupplyInitialized == true);
        var (sellAmount, saleFeeAmount) = getSaleReturnAdmin(_sellAmount);
        assert(sellAmount != 0 && sellAmount >= _minReturn);
        token.destroy(msg.sender, _sellAmount);
        connectorBasketAdmin -= (sellAmount + saleFeeAmount);
        conversionFeeBasket += saleFeeAmount;
        ethshToken.deposit.value(sellAmount)(msg.sender);
        BuyETSH(_sellAmount, sellAmount, connectorBasket, 0, connectorBasketAdmin);
        return sellAmount;
    }

    function sellEtshForEcoin(uint256 _sellAmount, uint256 _minReturn)
        public
        conversionsAllowed
        validGasPrice
        greaterThanZero(_minReturn)
        returns (uint256)
    {
        require(tokenSupplyInitialized == true);
        ethshToken.withdrawFrom(msg.sender, address(this), _sellAmount);
        var (buyAmount, saleFeeAmount) = getPurchaseReturnAdmin(_sellAmount);
        connectorBasketAdmin += (_sellAmount - saleFeeAmount);
        conversionFeeBasket += saleFeeAmount;
        token.issue(msg.sender, buyAmount); 
        return buyAmount;
    }

    function transferEcoin(address _from, uint256 _amount)
        public
    {
        require(tokenSupplyInitialized == true);
        require(generalConverter == msg.sender);  
        token.destroy(_from, _amount);
        token.issue(msg.sender, _amount); 
    }

    function setGeneralConverter(address _generalConverter)
        public
        ownerOnly
    {
        require(generalConverter != _generalConverter);
        generalConverter = _generalConverter;
    }

    function exchangeEcoinToEther(uint256 _minReturn, uint256 _sellAmount, address _to)
        public
        returns (uint256)
    {
        require(tokenSupplyInitialized == true);
        require(msg.sender == generalConverter);
        var (amount, feeAmount) = sell(_sellAmount, _minReturn, connectorBasket, msg.sender);
        connectorBasket -= (amount + feeAmount);
        return amount;
    }

    /**
        @dev utility, returns the expected return for selling the token for ETH, given a total supply override

        @return sale return amount
    */
    function getSaleReturn(uint256 _sellAmount, uint256 _connectorBalance)
        private
        constant
        greaterThanZero(token.totalSupply())
        returns (uint256, uint256)
    {
        uint256 amount = extensions.formula().calculateSaleReturn(token.totalSupply(), _connectorBalance, CONNECTOR_WEIGHT, _sellAmount);

        // deduct the fee from the return amount
        uint256 feeAmount = getConversionFeeAmount(amount);
        return (safeSub(amount, feeAmount), feeAmount);
    }

    /**
        @dev fallback, buys the smart token with ETH
    */
    function() payable {
        require(tokenSupplyInitialized == true);
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
import './ITokenHolder.sol';
import './IERC20Token.sol';

/*
    Ether Token interface
*/
contract IEthshToken is ITokenHolder, IERC20Token {
    function deposit(address _from) public payable;
    function withdrawTo(address _to, uint256 _amount);
    function withdrawFrom(address _from, address _to, uint256 _amount);
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
import './TokenHolder.sol';
import './interfaces/ISmartToken.sol';
import './interfaces/IEthshToken.sol';

/*
    The smart token controller is an upgradable part of the smart token that allows
    more functionality as well as fixes for bugs/exploits.
    Once it accepts ownership of the token, it becomes the token's sole controller
    that can execute any of its functions.

    To upgrade the controller, ownership must be transferred to a new controller, along with
    any relevant data.

    The smart token must be set on construction and cannot be changed afterwards.
    Wrappers are provided (as opposed to a single 'execute' function) for each of the token's functions, for easier access.

    Note that the controller can transfer token ownership to a new controller that
    doesn't allow executing any function on the token, for a trustless solution.
    Doing that will also remove the owner's ability to upgrade the controller.
*/
contract SmartTokenController is TokenHolder {
    ISmartToken public token;   // smart token
    IEthshToken public ethshToken;

    /**
        @dev constructor
    */
    function SmartTokenController(ISmartToken _token, IEthshToken _ethshToken)
        validAddress(_token)
        validAddress(_ethshToken)
    {
        token = _token;
        ethshToken = _ethshToken;
    }

    // ensures that the controller is the token's owner
    modifier active() {
        assert(token.owner() == address(this));
        assert(ethshToken.owner() == address(this));
        _;
    }

    // ensures that the controller is not the token's owner
    modifier inactive() {
        assert(token.owner() != address(this));
        assert(ethshToken.owner() != address(this));
        _;
    }

    function acceptTokenOwnership() public ownerOnly {
        token.acceptOwnership();
    }

    function acceptEtshTokenOwnership() public ownerOnly {
        ethshToken.acceptOwnership();
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