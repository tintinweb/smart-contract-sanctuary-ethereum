/**
 *Submitted for verification at Etherscan.io on 2022-06-04
*/

//SPDX-License-Identifier:MIT
pragma solidity ^0.8.13;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function decimals() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

interface INfmController {
    function _checkWLSC(address Controller, address Client)
        external
        pure
        returns (bool);

    function _getController() external pure returns (address);

    function _getNFM() external pure returns (address);

    function _getTimer() external pure returns (address);

    function _getDistribute() external pure returns (address);
}

interface IUniswapV2Pair {
    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);
}

/// @title Exchange Contract for NFM Coin against unlimited Coins with integrated OnChain Oracle depending on 2 more Oracles (Uniswap and offchain Oracle)
/// @author Fernando Viktor Seidl E-mail: [email protected]
/// @notice This Interface is able, to add all Tokens with an ERC-20 Standard to be exchanged against NFM. This Interface also supports PresaleMode and Fixed Price Sales.
/// @dev To deploy Contract, is necessary Controller Interface and USDC Token Address. USDC will be used as StableCoin for Calculations and can also be exchanged.
/*
1- Deploy Contract with Controller Address + USDC Address
2- Set Token Price usdc min 10 Prices ["1000000000000000000",...] 18 Digits format
3- Set Fixed exchange Price against USD 1 NFM = 752300000000000000 usdc
4- Set Min and Max Amount to buy once. This Price should be in usdc. like 50 usdc should be 50000000000000000000
5- Now add all Coins to be exchanged against NFM with function ADDORDISABLECOIN() and add Prices minimum 10 in 18 Digitsformat on function SETPRICEORACLE() 
6- Once all Coins wanted are added, you can initialise PreSale Mode. Buy and Sell will only be possible between start an end time.
7- Send NFM Amount to Contract Address (if Presale is aktivated, Amount should be equal to PresaleDexAmount otherwise calculations will fail)
8- Once Presale is over, Owner can withdraw funds on withdraw function or distribute directly by Percentage to each account.
9- Contract can be reactivated infinite Time with onOffPresale function.
 */
contract NFMExchange {
    using SafeMath for uint256;
    INfmController private _Controller;
    address private _SController;
    address private _Owner;

    bool private _isFixedPrice = false;
    uint256 private _PriceVsUSD;
    uint256 private _OracleTimer;
    //For Presale Events
    bool private _PreSaleMode = false;
    uint256 private _PreSaleStart;
    uint256 private _PreSaleEnd;
    uint256 private _PreSaleDexAmount;
    uint256 private _CurrencyCounter;
    address[] private _CurrencyArray;
    address private _USDC;
    //is deployed on Ethereum, Ropsten,... under / 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f
    address private _UniswapFactory =
        0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    uint256 private _MinUSD;
    uint256 private _MaxUSD;

    mapping(address => bool) public _isCurrencyAllowed;
    mapping(address => uint256[]) public _Oracle;

    event Trade(
        address indexed Sender,
        address indexed Coin,
        uint256 Amount,
        uint256 NFM,
        uint256 Time
    );
    modifier onlyOwner() {
        require(
            _Controller._checkWLSC(_SController, msg.sender) == true ||
                _Owner == msg.sender,
            "oO"
        );
        require(msg.sender != address(0), "0A");
        _;
    }

    constructor(address Controller, address USDC) {
        _Owner = msg.sender;
        INfmController _Cont = INfmController(address(Controller));
        _SController = Controller;
        _Controller = _Cont;
        _USDC = USDC;
        _CurrencyArray.push(USDC);
        _CurrencyCounter++;
        _isCurrencyAllowed[USDC] = true;
        _OracleTimer = block.timestamp+3600;
    }

    //USD Price against NFM needs to be in 18 digits format on fixedPrice NFM=USD...
    function setFixedPrice(uint256 FixedUSDPrice, bool OnOff)
        public
        onlyOwner
        returns (bool)
    {
        _isFixedPrice = OnOff;
        _PriceVsUSD = FixedUSDPrice;
        return true;
    }

    //Return Bool if Currency is already allowed
    function returnAllowedCurrencies(address Coin) public view returns (bool) {
        return _isCurrencyAllowed[Coin];
    }

    //Return Currencies Array for the Uniswap Interface
    function returnCurrenciesArray()
        public
        view
        returns (address[] memory Arr)
    {
        return _CurrencyArray;
    }

    //Set Mode True or False, StartDays, when it should Start, EndDays Days to wait until it ends after start, Presale Amount showing on balance
    function onOffPresale(
        bool Mode,
        uint256 DaysStart,
        uint256 DaysEnd,
        uint256 PresaleAmount
    ) public onlyOwner returns (bool) {
        if (Mode == true) {
            _PreSaleMode = Mode;
            _PreSaleStart = block.timestamp + (3600 * 24 * DaysStart);
            _PreSaleEnd = block.timestamp + (3600 * 24 * (DaysEnd + DaysStart));
            _PreSaleDexAmount = PresaleAmount;
        } else {
            _PreSaleMode = Mode;
            _PreSaleStart = 0;
            _PreSaleEnd = 0;
            _PreSaleDexAmount = 0;
        }
        return true;
    }

    //Return Presale remaining Amount
    function returnRemainPresaleAmount() public view returns (uint256, bool) {
        if (_PreSaleMode == true) {
            return (
                IERC20(address(_Controller._getNFM())).balanceOf(address(this)),
                true
            );
        } else {
            return (0, false);
        }
    }

    //Return inicial PresaleAmount + Sold NFM Amount
    function returnInicialandSold()
        public
        view
        returns (
            uint256 Inicial,
            uint256 Sold,
            bool
        )
    {
        if (_PreSaleMode == true) {
            return (
                _PreSaleDexAmount,
                SafeMath.sub(
                    _PreSaleDexAmount,
                    IERC20(address(_Controller._getNFM())).balanceOf(
                        address(this)
                    )
                ),
                true
            );
        } else {
            return (0, 0, false);
        }
    }

    //Return PresaleTimers
    function returnPresaleTimers()
        public
        view
        returns (
            uint256 Start,
            uint256 End,
            bool Check
        )
    {
        if (_PreSaleMode == false) {
            return (0, 0, false);
        } else {
            return (_PreSaleStart, _PreSaleEnd, true);
        }
    }

    //need to be set in 18 digits format
    function setMinMaxUSD(uint256 Min, uint256 Max)
        public
        onlyOwner
        returns (bool)
    {
        _MinUSD = Min;
        _MaxUSD = Max;
        return true;
    }

    //Needs Coin Address and true if Coin should be allowed to trade to disable Exchange just provide address coin and false
    function addOrDisableCoin(address Coin, bool Allow)
        public
        onlyOwner
        returns (bool)
    {
        if (Allow == false) {
            _isCurrencyAllowed[Coin] = false;
        } else {
            _CurrencyArray.push(Coin);
            _CurrencyCounter++;
            _isCurrencyAllowed[Coin] = true;
        }
        return true;
    }

    //if NFM USDC PAIR exists on Uniswap, then FixedPrice can be dynamic by the 3 Oracles
    function updateSetFixedPrice() internal onlyOwner returns (bool) {
        uint256 O2Price = checkOracle2Price(address(_Controller._getNFM()));
        uint256 MinPus = SafeMath.sub(
            _PriceVsUSD,
            SafeMath.div(SafeMath.mul(_PriceVsUSD, 3), 100)
        );
        uint256 MaxPus = SafeMath.add(
            _PriceVsUSD,
            SafeMath.div(SafeMath.mul(_PriceVsUSD, 3), 100)
        );
        if(O2Price!=0){
        if (O2Price > MaxPus) {
            _PriceVsUSD = MaxPus;
        } else if (O2Price < MinPus) {
            _PriceVsUSD = MinPus;
        } else {
            _PriceVsUSD = O2Price;
        }
        }
        return true;
        
    }

    //On Chain Oracle will be managed by the Exchange itself every two hours will be added new price to the array
    function checkOracle1Price(address Coin) public view returns (uint256) {
        uint256 Prounds = _Oracle[Coin].length;
        uint256 RoundCount = 0;
        uint256 sum = 0;
        if (Prounds > 30) {
            for (uint256 i = Prounds - 30; i < Prounds; i++) {
                sum += _Oracle[Coin][i];
                RoundCount++;
            }
        } else {
            for (uint256 i = 0; i < Prounds; i++) {
                sum += _Oracle[Coin][i];
                RoundCount++;
            }
        }
        sum = SafeMath.div(sum, RoundCount);

        return sum;
    }

    //Uniswap Oracle managed by Uniswap, Prices show USD amount per coin
    function checkOracle2Price(address Coin) public view returns (uint256) {
        address UniPair = IUniswapV2Factory(_UniswapFactory).getPair(
            Coin,
            _USDC
        );
        if(UniPair!=address(0)){
        IUniswapV2Pair pair = IUniswapV2Pair(UniPair);
        IERC20 token1 = IERC20(pair.token1());
        (uint256 Res0, uint256 Res1, ) = pair.getReserves();
        // decimals
        uint256 res0 = Res0 * (10**token1.decimals());
        uint256 make = SafeMath.mul(SafeMath.div(res0, Res1), 10**12);
        
        return make;
        }else{
            return 0;
        }
    }

    //Save new MedianPrice To Exchange Oracle
    //oracle prices are always stored in 18 digits format
    function setPriceOracle(address Coin, uint256[] memory Price)
        public
        onlyOwner
        returns (bool)
    {
        if (Price.length > 1) {
            _Oracle[Coin] = Price;
        } else {
            _Oracle[Coin].push(Price[0]);
        }
        return true;
    }

    //offchainOracle must be with 6 digits
    //amount must be in coin format like usdc has 6 decimals, bitcoin has 9,...
    function calcNFMAmount(
        address Coin,
        uint256 amount,
        uint256 offchainOracle
    )
        public
        view
        returns (
            bool check,
            uint256 NFMsAmount,
            uint256 MedianPrice,
            bool MaxPrice,
            bool MinPrice
        )
    {
        uint256 NFMs;
        uint256 CoinDecimals = IERC20(address(Coin)).decimals();
        if (CoinDecimals < 18) {
            amount = amount * 10**(SafeMath.sub(18, CoinDecimals));
        }
        offchainOracle = offchainOracle * 10**12;
        uint256 Oracle2;
        if (Coin == _USDC) {
            Oracle2 = 1 * 10**18;
        } else {
            Oracle2 = checkOracle2Price(Coin);
        }

        uint256 Oracle = checkOracle1Price(Coin);
        //Calculate pricerange
        uint256 median;
        if (offchainOracle == 0 && Oracle2 == 0) {
            median = Oracle;
        } else if (offchainOracle == 0 && Oracle2 > 0) {
            median = SafeMath.div(SafeMath.add(Oracle2, Oracle), 2);
        } else {
            median = SafeMath.div(
                SafeMath.add(SafeMath.add(offchainOracle, Oracle2), Oracle),
                3
            );
        }
        //Allow max 3% Price Change downside
        uint256 MinRange = SafeMath.sub(
            Oracle,
            SafeMath.div(SafeMath.mul(Oracle, 3), 100)
        );
        //Allow max 3% Price Change upside
        uint256 MaxRange = SafeMath.add(
            Oracle,
            SafeMath.div(SafeMath.mul(Oracle, 3), 100)
        );

        //Check if MedianPrice is in Range
        if (median > MaxRange) {
            median = MaxRange;
        } else if (median < MinRange) {
            median = MinRange;
        } else {
            median = median;
        }
        uint256 MulAmount = SafeMath.mul(amount, median);
        //Calculate NFM Amount on USD Price;
        uint256 FullUSDAmount = SafeMath.div(MulAmount, 10**18);
        bool MaxVal = true;
        bool MinVal = true;
        if (FullUSDAmount > _MaxUSD) {
            MaxVal = false;
        }
        if (FullUSDAmount < _MinUSD) {
            MinVal = false;
        }
        NFMs = SafeMath.div(SafeMath.mul(FullUSDAmount, 10**18), _PriceVsUSD);

        return (true, NFMs, median, MaxVal, MinVal);
        ///NOW TRANSFER
    }

    //Function to exchange NFM against Coin (provide address Coin, amount in coin format, offchainOracle needs to be 6 digit format)
    //Amount must be allowed to this contract first before this function can be called
    function SwapCoinVsNFM(
        address Coin,
        uint256 amount,
        uint256 offchainOracle
    ) public returns (bool) {
        require(_isCurrencyAllowed[Coin] == true, "!C");
        if (_PreSaleMode == true) {
            require(
                _PreSaleStart < block.timestamp &&
                    _PreSaleEnd > block.timestamp,
                "OoT"
            );
        }
        require(
            IERC20(address(Coin)).allowance(msg.sender,address(this)) >=
                amount,
            "<A"
        );

        (
            ,
            uint256 NFMsAmount,
            uint256 MedianPrice,
            bool MaxPrice,
            bool MinPrice
        ) = calcNFMAmount(Coin, amount, offchainOracle);
        require(MaxPrice == true, ">EA");
        require(MinPrice == true, "<EA");
        require(
            NFMsAmount <=
                IERC20(address(_Controller._getNFM())).balanceOf(address(this)),
            "<NFM"
        );
        if (block.timestamp > _OracleTimer) {
            
            _Oracle[Coin].push(MedianPrice);
            _OracleTimer = _OracleTimer + 3600;
            
            if (_isFixedPrice == false) {
                updateSetFixedPrice();
            }
        }
        require(
            IERC20(address(Coin)).transferFrom(
                msg.sender,
                address(this),
                amount
            ) == true,
            "<A"
        );
        require(
            IERC20(address(_Controller._getNFM())).transfer(
                msg.sender,
                NFMsAmount
            )
        );
        emit Trade(msg.sender, Coin, amount, NFMsAmount, block.timestamp);
        return true;
    }

    //Function to withdraw coins. amount can be percentage if bool percent is set as true. Then the function will only send x% of total value.
    //Otherwise if amount is set to 0 and bool percent is false, then function will send full coin balance. and if amount is not 0 and bool percent is false,
    //Then function will send only amount provided
    function withdraw(
        address Coin,
        address To,
        uint256 amount,
        bool percent
    ) public onlyOwner returns (bool) {
        require(To != address(0), "0A");
        uint256 CoinAmount = IERC20(address(Coin)).balanceOf(address(this));
        if (percent == true) {
            //makeCalcs on Percentatge
            uint256 AmountToSend = SafeMath.div(
                SafeMath.mul(CoinAmount, amount),
                100
            );
            IERC20(address(Coin)).transfer(To, AmountToSend);
            return true;
        } else {
            if (amount == 0) {
                IERC20(address(Coin)).transfer(To, CoinAmount);
            } else {
                IERC20(address(Coin)).transfer(To, amount);
            }
            return true;
        }
    }
}