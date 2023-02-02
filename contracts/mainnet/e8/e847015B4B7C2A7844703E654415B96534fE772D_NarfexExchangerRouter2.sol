//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import './PancakeLibrary.sol';
import './INarfexOracle.sol';
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface INarfexFiat is IERC20 {
    function burnFrom(address _address, uint _amount) external;
    function mintTo(address _address, uint _amount) external;
}

interface INarfexExchangerPool {
    function getBalance() external view returns (uint);
    function approveRouter() external;
}

interface IWBNB {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

/// @title DEX Router for Narfex Fiats
/// @author Danil Sakhinov
/// @dev Allows to exchange between fiats and crypto coins
/// @dev Exchanges using USDT liquidity pool
/// @dev Uses Narfex oracle to get commissions and prices
/// @dev Supports tokens with a transfer fee
contract NarfexExchangerRouter2 is Ownable {
    using Address for address;

    /// Structures for solving the problem of limiting the number of variables

    struct ExchangeData {
        uint rate;
        int commission;
        uint inAmountClear;
        uint outAmountClear;
        uint inAmount;
        uint outAmount;
        address commToken;
        int commAmount;
        uint referReward;
        int profitUSDT;
    }

    struct SwapData {
        address[] path;
        uint[] amounts;
        bool isExactOut;
        uint amount;
        uint inAmount;
        uint inAmountMax;
        uint outAmount;
        uint outAmountMin;
        uint deadline;
        address refer;
    }

    struct Token {
        address addr;
        bool isFiat;
        int commission;
        uint price;
        uint reward;
        uint transferFee;
    }

    IERC20 public USDT;
    IWBNB public WBNB;
    INarfexOracle public oracle;
    INarfexExchangerPool public pool;

    uint constant PRECISION = 10**18;
    uint private USDT_PRECISION = 10**6;
    uint constant PERCENT_PRECISION = 10**4;
    uint constant MAX_INT = 2**256 - 1;

    /// @param _oracleAddress NarfexOracle address
    /// @param _poolAddress NarfexExchangerPool address
    /// @param _usdtAddress USDT address
    /// @param _wbnbAddress WrapBNB address
    constructor (
        address _oracleAddress,
        address _poolAddress,
        address _usdtAddress,
        address _wbnbAddress
    ) {
        oracle = INarfexOracle(_oracleAddress);
        USDT = IERC20(_usdtAddress);
        WBNB = IWBNB(_wbnbAddress);
        pool = INarfexExchangerPool(_poolAddress);
        if (block.chainid == 56 || block.chainid == 97) {
            USDT_PRECISION = 10**18;
        }
    }

    /// @notice Checking for an outdated transaction
    /// @param deadline Limit block timestamp
    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, "Transaction expired");
        _;
    }

    event SwapFiat(address indexed _account, address _fromToken, address _toToken, ExchangeData _exchange);
    event SwapDEX(address indexed _account, address _fromToken, address _toToken, uint inAmount, uint outAmount);
    event ReferralReward(address _token, uint _amount, address indexed _receiver);

    /// @notice Default function for BNB receive. Accepts BNB only from WBNB contract
    receive() external payable {
        assert(msg.sender == address(WBNB));
    }

    /// @notice Assigns token data from oracle to structure with token address
    /// @param addr Token address
    /// @param t Token data from the oracle
    /// @return New structure with addr
    function _assignTokenData(address addr, INarfexOracle.TokenData memory t)
        internal pure returns (Token memory)
    {
        return Token(addr, t.isFiat, t.commission, t.price, t.reward, t.transferFee);
    }

    /// @notice Returns the price of the token quantity in USDT equivalent
    /// @param _token Token address
    /// @param _amount Token amount
    /// @return USDT amount
    function _getUSDTValue(address _token, int _amount) internal view returns (int) {
        if (_amount == 0) return 0;
        uint uintValue = oracle.getPrice(_token) * uint(_amount) / USDT_PRECISION;
        return _amount >= 0
            ? int(uintValue)
            : -int(uintValue);
    }

    /// @notice Calculates prices and commissions when exchanging with fiat
    /// @param A First token
    /// @param B Second token
    /// @param _amount The amount of one of the tokens. Depends on _isExactOut
    /// @param _isExactOut Is the specified amount an output value
    /// @dev The last parameter shows the direction of the exchange
    function _getExchangeValues(Token memory A, Token memory B, uint _amount, bool _isExactOut)
        internal view returns (ExchangeData memory exchange)
    {
        /// Calculate price
        {
            uint priceA = A.addr == address(USDT) ? USDT_PRECISION : A.price;
            uint priceB = B.addr == address(USDT) ? USDT_PRECISION : B.price;
            exchange.rate = priceA * USDT_PRECISION / priceB;
        }

        /// Calculate commission
        {
            int unit = int(PERCENT_PRECISION);
            exchange.commission = (A.commission + unit) * (B.commission + unit) / unit - unit;
        }

        /// Calculate clear amounts
        exchange.inAmountClear = _isExactOut
            ? _amount * USDT_PRECISION / exchange.rate
            : _amount;
        exchange.outAmountClear = _isExactOut
            ? _amount
            : _amount * exchange.rate / USDT_PRECISION;

        /// Calculate amounts with commission
        if (_isExactOut) {
            exchange.inAmount = exchange.inAmountClear
                * uint(int(PERCENT_PRECISION) + exchange.commission)
                / PERCENT_PRECISION;
            exchange.outAmount = _amount;
        } else {
            exchange.inAmount = _amount;
            exchange.outAmount = exchange.outAmountClear
                * uint(int(PERCENT_PRECISION) - exchange.commission)
                / PERCENT_PRECISION;
        }

        /// Calculate commission and profit amount
        exchange.commToken = A.isFiat
            ? A.addr
            : B.addr;
        exchange.commAmount = int(A.isFiat ? exchange.inAmount : exchange.outAmount)
            * exchange.commission
            / int(PERCENT_PRECISION);
        exchange.profitUSDT = _getUSDTValue(exchange.commToken, exchange.commAmount);
    }

    /// @notice Sends the referral agent his reward
    /// @param A Reward token
    /// @param _amount Quantity from which the amount of the reward should be calculated
    /// @param _receiver Referral agent address
    function _sendReferReward(Token memory A, uint _amount, address _receiver)
        internal returns (uint)
    {
        if (_receiver != address(0)) {
            uint refPercent = A.reward;
            if (refPercent > 0) {
                uint refAmount = refPercent * _amount / PERCENT_PRECISION;
                INarfexFiat(A.addr).mintTo(_receiver, refAmount);
                emit ReferralReward(A.addr, refAmount, _receiver);
                return refAmount;
            }
        }  
        return 0;
    }

    /// @notice Only exchanges between fiats
    /// @param _accountAddress Recipient address
    /// @param A First token
    /// @param B Second token
    /// @param exchange Calculated values to exchange
    /// @param _refer Referral agent address
    function _swapFiats(
        address _accountAddress,
        Token memory A,
        Token memory B,
        ExchangeData memory exchange,
        address _refer
    ) private {
        require(INarfexFiat(A.addr).balanceOf(_accountAddress) >= exchange.inAmount, "Not enough balance");

        /// Exchange tokens
        INarfexFiat(A.addr).burnFrom(_accountAddress, exchange.inAmount);
        INarfexFiat(B.addr).mintTo(_accountAddress, exchange.outAmount);

        /// Send referral reward
        Token memory C = A.addr == exchange.commToken ? A : B;
        exchange.referReward = _sendReferReward(C, exchange.inAmountClear, _refer);
        exchange.profitUSDT -= _getUSDTValue(C.addr, int(exchange.referReward));

        emit SwapFiat(_accountAddress, A.addr, B.addr, exchange);
    }

    /// @notice Fiat and USDT Pair Exchange
    /// @param _accountAddress Recipient address
    /// @param A First token
    /// @param B Second token
    /// @param exchange Calculated values to exchange
    /// @param _refer Referral agent address
    /// @param _isItSwapWithDEX Cancels sending USDT to the user
    /// @dev The last parameter is needed for further or upcoming work with DEX
    function _swapFiatAndUSDT(
        address _accountAddress,
        Token memory A,
        Token memory B,
        ExchangeData memory exchange,
        address _refer,
        bool _isItSwapWithDEX
    ) private returns (uint usdtAmount) {
        Token memory C = A.addr == exchange.commToken ? A : B;

        if (A.addr == address(USDT)) {
            /// If conversion from USDT to fiat
            if (!_isItSwapWithDEX) { 
                /// Transfer from the account
                USDT.transferFrom(_accountAddress, address(pool), exchange.inAmount);
            } /// ELSE: USDT must be already transferred to the pool by DEX
            /// Mint fiat to the final account
            INarfexFiat(B.addr).mintTo(_accountAddress, exchange.outAmount);
            /// Send refer reward
            exchange.referReward = _sendReferReward(C, exchange.outAmountClear, _refer);
            exchange.profitUSDT -= _getUSDTValue(C.addr, int(exchange.referReward));
        } else {
            /// If conversion from fiat to usdt
            require(pool.getBalance() >= exchange.outAmount, "Not enough liquidity pool amount");
            /// Burn fiat from account
            INarfexFiat(A.addr).burnFrom(_accountAddress, exchange.inAmount);
            /// Send refer reward
            exchange.referReward = _sendReferReward(C, exchange.inAmountClear, _refer);
            exchange.profitUSDT -= _getUSDTValue(C.addr, int(exchange.referReward));
            /// Then transfer USDT
            if (!_isItSwapWithDEX) {
                /// Transfer USDT to the final account
                USDT.transferFrom(address(pool), _accountAddress, exchange.outAmount);
            }
            usdtAmount = exchange.outAmount;
        }

        emit SwapFiat(_accountAddress, A.addr, B.addr, exchange);
    }

    /// @notice Truncates the path, excluding the fiat from it
    /// @param _path An array of addresses representing the exchange path
    /// @param isFromFiat Indicates the direction of the route (Fiat>DEX of DEX>Fiat)
    function _getDEXSubPath(address[] memory _path, bool isFromFiat) internal pure returns (address[] memory) {
        address[] memory path = new address[](_path.length - 1);
        for (uint i = 0; i < path.length; i++) {
            path[i] = _path[isFromFiat ? i + 1 : i];
        }
        return path;
    }

    /// @notice Gets the reserves of tokens in the path and calculates the final value
    /// @param data Prepared swap data
    /// @dev Updates the data in the structure passed as a parameter
    function _processSwapData(SwapData memory data) internal view {
        if (data.isExactOut) {
            data.amounts = PancakeLibrary.getAmountsIn(data.outAmount, data.path);
            data.inAmount = data.amounts[0];
        } else {
            data.amounts = PancakeLibrary.getAmountsOut(data.inAmount, data.path);
            data.outAmount = data.amounts[data.amounts.length - 1];
        }
    }

    /// @notice Exchange only between crypto Сoins through liquidity pairs
    /// @param _account Recipient account address
    /// @param data Prepared swap data
    /// @param A Input token data
    /// @param B Output token data
    function _swapOnlyDEX(
        address payable _account,
        SwapData memory data,
        Token memory A,
        Token memory B
        ) private
    {
        uint transferInAmount;
        if (data.isExactOut) {
            /// Increase output amount by outgoing token fee for calculations
            data.outAmount = B.transferFee > 0
                ? data.amount * (PERCENT_PRECISION + B.transferFee) / PERCENT_PRECISION
                : data.amount;
        } else {
            transferInAmount = data.amount;
            /// Decrease input amount for calculations
            data.inAmount = A.transferFee > 0
                ? data.amount * (PERCENT_PRECISION - A.transferFee) / PERCENT_PRECISION
                : data.amount;
        }
        /// Calculate the opposite value
        _processSwapData(data);

        if (data.isExactOut) {
            /// Increase input amount by inbound token fee
            transferInAmount = A.transferFee > 0
                ? data.inAmount * (PERCENT_PRECISION + A.transferFee) / PERCENT_PRECISION
                : data.inAmount;
            require(data.inAmount <= data.inAmountMax, "Input amount is higher than maximum");
        } else {
            require(data.outAmount >= data.outAmountMin, "Output amount is lower than minimum");
        }
        address firstPair = PancakeLibrary.pairFor(data.path[0], data.path[1]);
        if (A.addr == address(WBNB)) {
            /// BNB insert
            require(msg.value >= transferInAmount, "BNB is not sended");
            WBNB.deposit{value: transferInAmount}();
            assert(WBNB.transfer(firstPair, transferInAmount));
            if (msg.value > transferInAmount) {
                /// Return unused BNB
                _account.transfer(msg.value - transferInAmount);
            }
        } else {
            /// Coin insert
            SafeERC20.safeTransferFrom(IERC20(data.path[0]), _account, firstPair, transferInAmount);
        }
        if (B.addr == address(WBNB)) {
            /// Send BNB after swap
            _swapDEX(data.amounts, data.path, address(this));
            WBNB.withdraw(data.outAmount);
            _account.transfer(data.outAmount);
        } else {
            /// Send Coin after swap
            _swapDEX(data.amounts, data.path, _account);
        }
        emit SwapDEX(_account, A.addr, B.addr, data.inAmount, data.outAmount);
    }

    /// @notice Exchange through liquidity pairs along the route
    /// @param amounts Pre-read reserves in liquidity pairs
    /// @param path An array of addresses representing the exchange path
    /// @param _to Address of the recipient
    function _swapDEX(uint[] memory amounts, address[] memory path, address _to) internal {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = PancakeLibrary.sortTokens(input, output);
            uint amountOut = amounts[i + 1];
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
            address to = i < path.length - 2 ? PancakeLibrary.pairFor(output, path[i + 2]) : _to;
            IPancakePair(PancakeLibrary.pairFor(input, output)).swap(
                amount0Out, amount1Out, to, new bytes(0)
            );
        }
    }

    /// @notice Fiat to crypto Coin exchange and vice versa
    /// @param _account Recipient address
    /// @param data Prepared swap data
    /// @param F Fiat token data
    /// @param C Coin token data
    /// @param isFromFiat Exchange direction
    /// @dev Takes into account tokens with transfer fees
    function _swapFiatWithDEX(
        address payable _account,
        SwapData memory data,
        Token memory F, // Fiat
        Token memory C, // Coin
        bool isFromFiat
        ) private
    {
        /// USDT token data
        Token memory U = _assignTokenData(address(USDT), oracle.getTokenData(address(USDT), false));
        uint lastIndex = data.path.length - 1;

        require((isFromFiat && data.path[0] == U.addr)
            || (!isFromFiat && data.path[lastIndex] == U.addr),
            "The exchange between fiat and crypto must be done via USDT");

        ExchangeData memory exchange;

        if (data.isExactOut) {
            /// If exact OUT
            if (isFromFiat) { /// FIAT > USDT > DEX > COIN!!
                /// Calculate other amounts from the start amount data
                data.outAmount = data.amount;
                if (C.transferFee > 0) {
                    /// Increasing the output amount offsets the loss from the fee
                    data.outAmount = data.outAmount * (PERCENT_PRECISION + C.transferFee) / PERCENT_PRECISION;
                }
                _processSwapData(data);
                exchange = _getExchangeValues(F, U, data.inAmount, true);
                require(exchange.inAmount <= data.inAmountMax, "Input amount is higher than maximum");
                /// Swap Fiat with USDT
                _swapFiatAndUSDT(_account, F, U, exchange, data.refer, true);
                /// Transfer USDT from the Pool to the first pair
                {
                    address firstPair = PancakeLibrary.pairFor(U.addr, data.path[1]);
                    SafeERC20.safeTransferFrom(USDT, address(pool), firstPair, data.inAmount);
                }
                /// Swap and send to the account
                if (C.addr == address(WBNB)) {
                    /// Swap with BNB out
                    _swapDEX(data.amounts, data.path, address(this));
                    WBNB.withdraw(data.outAmount);
                    _account.transfer(data.outAmount);
                } else {
                    /// Swap with coin out
                    _swapDEX(data.amounts, data.path, _account);
                }
                emit SwapDEX(_account, data.path[0], data.path[lastIndex], data.inAmount, data.outAmount);
            } else { /// COIN > DEX > USDT > FIAT!!
                /// Calculate other amounts from the start amount data
                exchange = _getExchangeValues(U, F, data.amount, true);
                data.outAmount = exchange.inAmount;
                _processSwapData(data);
                require(data.inAmount <= data.inAmountMax, "Input amount is higher than maximum");
                /// Transfer Coin from the account to the first pair
                {
                    address firstPair = PancakeLibrary.pairFor(C.addr, data.path[1]);
                    if (C.addr == address(WBNB)) {
                        /// BNB transfer
                        require(msg.value >= data.inAmount, "BNB is not sended");
                        WBNB.deposit{value: data.inAmount}();
                        assert(WBNB.transfer(firstPair, data.inAmount));
                        if (msg.value > data.inAmount) {
                            /// Return unused BNB
                            _account.transfer(msg.value - data.inAmount);
                        }
                    } else {
                        /// Send increased coin amount from the account to DEX
                        uint inAmountWithFee = C.transferFee > 0
                        ? data.inAmount * (PERCENT_PRECISION + C.transferFee) / PERCENT_PRECISION
                        : data.inAmount;
                        SafeERC20.safeTransferFrom(IERC20(C.addr), _account, firstPair, inAmountWithFee);
                    }
                }
                /// Swap and send USDT to the pool
                _swapDEX(data.amounts, data.path, address(pool));
                emit SwapDEX(_account, data.path[0], data.path[lastIndex], data.inAmount, data.outAmount);
                /// Swap USDT and Fiat
                _swapFiatAndUSDT(_account, U, F, exchange, data.refer, true);
            }
        } else {
            /// If exact IN
            if (isFromFiat) { /// FIAT!! > USDT > DEX > COIN
                /// Calculate other amounts from the start amount data
                exchange = _getExchangeValues(F, U, data.amount, false);
                data.inAmount = exchange.outAmount;
                _processSwapData(data);
                require(data.outAmount >= data.outAmountMin, "Output amount is lower than minimum");
                /// Swap Fiat with USDT
                _swapFiatAndUSDT(_account, F, U, exchange, data.refer, true);
                /// Transfer USDT from the Pool to the first pair
                {
                    address firstPair = PancakeLibrary.pairFor(U.addr, data.path[1]);
                    SafeERC20.safeTransferFrom(USDT, address(pool), firstPair, data.inAmount);
                    /// TransferFee only affects delivered amount
                }
                /// Swap and send to the account
                if (C.addr == address(WBNB)) {
                    /// Swap with BNB transfer
                    _swapDEX(data.amounts, data.path, address(this));
                    WBNB.withdraw(data.outAmount);
                    _account.transfer(data.outAmount);
                } else {
                    /// Swap with coin transfer
                    _swapDEX(data.amounts, data.path, _account);
                }
                emit SwapDEX(_account, data.path[0], data.path[lastIndex], data.inAmount, data.outAmount);
            } else { /// COIN!! > DEX > USDT > FIAT
                /// Calculate other amounts from the start amount data
                data.inAmount = data.amount;
                if (C.transferFee > 0) {
                    /// DEX swap with get a reduced value
                    data.inAmount = data.inAmount * (PERCENT_PRECISION - C.transferFee) / PERCENT_PRECISION;
                }
                _processSwapData(data);
                exchange = _getExchangeValues(U, F, data.outAmount, false);
                require(exchange.outAmount >= data.outAmountMin, "Output amount is lower than minimum");
                /// Transfer Coin from the account to the first pair
                {
                    address firstPair = PancakeLibrary.pairFor(C.addr, data.path[1]);
                    if (C.addr == address(WBNB)) {
                        /// BNB transfer
                        require(msg.value >= data.amount, "BNB is not sended");
                        WBNB.deposit{value: data.amount}();
                        assert(WBNB.transfer(firstPair, data.amount));
                    } else {
                        /// Coin transfer
                        SafeERC20.safeTransferFrom(IERC20(C.addr), _account, firstPair, data.amount); /// Full amount
                    }
                }
                /// Swap and send USDT to the pool
                _swapDEX(data.amounts, data.path, address(pool));
                emit SwapDEX(_account, data.path[0], data.path[lastIndex], data.inAmount, data.outAmount);
                /// Swap USDT and Fiat
                _swapFiatAndUSDT(_account, U, F, exchange, data.refer, true);
            }
        }
    }

    /// @notice Main Routing Exchange Function
    /// @param _account Recipient address
    /// @param data Prepared data for exchange
    function _swap(
        address payable _account,
        SwapData memory data
        ) private
    {
        require(data.path.length > 1, "Path length must be at least 2 addresses");
        uint lastIndex = data.path.length - 1;

        Token memory A; /// First token
        Token memory B; /// Last token
        {
            /// Get the oracle data for the first and last tokens
            address[] memory sideTokens = new address[](2);
            sideTokens[0] = data.path[0];
            sideTokens[1] = data.path[lastIndex];
            INarfexOracle.TokenData[] memory tokensData = oracle.getTokensData(sideTokens, true);
            A = _assignTokenData(sideTokens[0], tokensData[0]);
            B = _assignTokenData(sideTokens[1], tokensData[1]);
        }
        require(A.addr != B.addr, "Can't swap the same tokens");

        if (A.isFiat && B.isFiat)
        { /// If swap between fiats
            ExchangeData memory exchange = _getExchangeValues(A, B, data.amount, data.isExactOut);
            _swapFiats(_account, A, B, exchange, data.refer);
            return;
        }
        if (!A.isFiat && !B.isFiat)
        { /// Swap on DEX only
            _swapOnlyDEX(_account, data, A, B);
            return;
        }
        if ((A.isFiat && B.addr == address(USDT))
            || (B.isFiat && A.addr == address(USDT)))
        { /// If swap between fiat and USDT in the pool
            ExchangeData memory exchange = _getExchangeValues(A, B, data.amount, data.isExactOut);
            _swapFiatAndUSDT(_account, A, B, exchange, data.refer, false);
            return;
        }

        /// Swap with DEX and Fiats
        data.path = _getDEXSubPath(data.path, A.isFiat);
        _swapFiatWithDEX(_account, data, A.isFiat ? A : B, A.isFiat ? B : A, A.isFiat);  
    }

    /// @notice Set a new pool address
    /// @param _newPoolAddress Another pool address
    /// @param _decimals Pool token decimals
    function setPool(address _newPoolAddress, uint8 _decimals) public onlyOwner {
        pool = INarfexExchangerPool(_newPoolAddress);
        USDT_PRECISION = 10**_decimals;
    }

    /// @notice Set a new oracle address
    /// @param _newOracleAddress Another oracle address
    function setOracle(address _newOracleAddress) public onlyOwner {
        oracle = INarfexOracle(_newOracleAddress);
    }

    /// @notice Swap tokens public function
    /// @param path An array of addresses representing the exchange path
    /// @param isExactOut Is the amount an output value
    /// @param amountLimit Becomes the min output amount for isExactOut=true, and max input for false
    /// @param deadline The transaction must be completed no later than the specified time
    /// @param refer Referral agent address
    /// @dev If the user wants to get an exact amount in the output, isExactOut should be true
    /// @dev Fiat to crypto must be exchanged via USDT
    function swap(
        address[] memory path,
        bool isExactOut,
        uint amount,
        uint amountLimit,
        uint deadline,
        address refer) public payable ensure(deadline)
    {
        SwapData memory data;
        data.path = path;
        data.isExactOut = isExactOut;
        data.amount = amount;
        data.inAmount = isExactOut ? 0 : amount;
        data.inAmountMax = isExactOut ? amountLimit : MAX_INT;
        data.outAmount = isExactOut ? amount : 0;
        data.outAmountMin = isExactOut ? 0 : amountLimit;
        data.refer = refer;

        _swap(payable(msg.sender), data);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IPancakePair {
    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

library PancakeLibrary {

    /// @notice Returns sorted token addresses, used to handle return values from pairs sorted in this order
    /// @param tokenA First token address
    /// @param tokenB Second token address
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'PancakeLibrary: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'PancakeLibrary: ZERO_ADDRESS');
    }

    /// @notice Calculates address for a pair without making any external calls
    /// @param tokenA First token address
    /// @param tokenB Second token address
    function pairFor(address tokenA, address tokenB) internal view returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        /// ETH data
        bytes memory factory = hex'5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f';
        bytes memory initCodeHash = hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f';
        if (block.chainid == 56) { /// BSC
            factory = hex'cA143Ce32Fe78f1f7019d7d551a6402fC5350c73';
            initCodeHash = hex'00fb7f630766e6a796048ea87d01acd3068e8ff67d078148a3fa3f4a84f69bd5';
        }
        if (block.chainid == 97) { /// BSC testnet
            factory = hex'b7926c0430afb07aa7defde6da862ae0bde767bc';
            initCodeHash = hex'ecba335299a6693cb2ebc4782e74669b84290b6378ea3a3873c7231a8d7d1074';
        }
        pair = address(uint160(uint256(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                initCodeHash
            )))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        pairFor(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IPancakePair(pairFor(tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'PancakeLibrary: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'PancakeLibrary: INSUFFICIENT_LIQUIDITY');
        amountB = amountA * reserveB / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal view returns (uint amountOut) {
        require(amountIn > 0, 'PancakeLibrary: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'PancakeLibrary: INSUFFICIENT_LIQUIDITY');
        uint pancakeCommission = 9970; /// ETH commission
        if (block.chainid == 56) {
            pancakeCommission = 9975; /// BSC commission
        }
        if (block.chainid == 97) {
            pancakeCommission = 9980; /// BSC testnet commission
        }
        uint amountInWithFee = amountIn * pancakeCommission;
        uint numerator = amountInWithFee * reserveOut;
        uint denominator = reserveIn * 10000 + amountInWithFee;
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal view returns (uint amountIn) {
        require(amountOut > 0, 'PancakeLibrary: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'PancakeLibrary: INSUFFICIENT_LIQUIDITY');
        uint pancakeCommission = 9970; /// ETH commission
        if (block.chainid == 56) {
            pancakeCommission = 9975; /// BSC commission
        }
        if (block.chainid == 97) {
            pancakeCommission = 9980; /// BSC testnet commission
        }
        uint numerator = reserveIn * amountOut * 10000;
        uint denominator = (reserveOut - amountOut) * pancakeCommission;
        amountIn = (numerator / denominator) + 1;
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'PancakeLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'PancakeLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface INarfexOracle {

    struct Token {
        bool isFiat;
        bool isCustomCommission; // Use default commission on false
        bool isCustomReward; // Use defalt referral percent on false
        uint price; // USD price only for fiats
        uint reward; // Referral percent only for fiats
        int commission; // Commission percent. Can be lower than zero
        uint transferFee; // Token transfer fee with 1000 decimals precision (20 for NRFX is 2%)
    }

    /// Calculated Token data
    struct TokenData {
        bool isFiat;
        int commission;
        uint price;
        uint reward;
        uint transferFee;
    }

    function defaultFiatCommission() external pure returns (int);
    function defaultCryptoCommission() external pure returns (int);
    function defaultReward() external pure returns (uint);
    function tokens(address _address) external returns (Token memory);

    function getPrice(address _address) external view returns (uint);
    function getIsFiat(address _address) external view returns (bool);
    function getCommission(address _address) external view returns (int);
    function getReferralPercent(address _address) external view returns (uint);
    function getTokenTransferFee(address _address) external view returns (uint);

    function getTokenData(address _address, bool _skipCoinPrice) external view returns (TokenData memory tokenData);
    function getTokensData(address[] calldata _tokens, bool _skipCoinPrice) external view returns (TokenData[] memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
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