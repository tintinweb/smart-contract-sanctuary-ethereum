/**
 *Submitted for verification at Etherscan.io on 2022-08-29
*/

// Sources flattened with hardhat v2.10.0 https://hardhat.org

// File @rari-capital/solmate/src/tokens/[email protected]

pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// File contracts/UsdXToken.sol

pragma solidity ^0.8.0;

contract UsdXToken is ERC20 {
    mapping(address => bool) public mintList;
    mapping(address => bool) public burnList;

    address public currentMinter;
    address public admin;

    event Governance(address _NewMinter);

    constructor() ERC20("USDx Token", "USDX", 6) {}

    function upDateContract(address _newContract) external {
        require(msg.sender == admin);
        mintList[currentMinter] = false;
        mintList[_newContract] = true;
        burnList[_newContract] = true;
        currentMinter = _newContract;
        emit Governance(_newContract);
    }

    function setSpecial(address _stableperp, address _VequityToken) external {
        require(admin == address(0x0), "Only once");
        mintList[_stableperp] = true;
        burnList[_stableperp] = true;
        currentMinter = _stableperp;
        admin = _VequityToken;
        emit Governance(_stableperp);
    }

    function mint(address _to, uint256 _value) external returns (bool) {
        require(mintList[msg.sender], "Only live contract can mint");
        _mint(_to, _value);
        return true;
    }

    function burn(address _from, uint256 _value) external returns (bool) {
        require(burnList[msg.sender], "only approved contracts can burn");
        _burn(_from, _value);
        return true;
    }
}

// File contracts/StablePerpConstants.sol

pragma solidity ^0.8.0;

// fees denominated in basis points need this as a divisor.
//One basis point equals one ten thousandth of a percent
int256 constant BASIS_PT_ADJ = 10000;
// withdrawal fee in basis points
int64 constant BPS_WD_FEE = 300; // 20 for real, 300 for tests
// withdrawal fee for internal stablecoin
int64 constant BPS_WD_FEE_X = 150; // 20 for real, 300 for tests
// total trade fee in basis points
int256 constant BPS_TRADE_FEE = 100; // 20 for real, 100 for tests
int256 constant BPS_SWAP_FEE = 100; // 30 for real, 100 for tests
// extra fee for removing USDC vs USDX from contract on eth in swap
int256 constant BPS_USDC_SWAP_FEE = 100; // 10 for real, 100 for tests
// the default fee is 5% of the notional eth position. 1/20 equals 5%
int256 constant DEFAULT_FEE = 20;
// LPs should extend liquidity for a minimum of 1 week.
// LPs pay $100 for violating this rule
int256 constant EARLY_WD_PENALTY = 10000;
// in timestamp seconds this represents 6 days. An LP withdrawing earlier than this
// pays a penalty to discourage LPs from providing flash-like liquidity
uint64 constant EARLY_WD_DEFINED = 0; // 518400 for real
// These two constants are needed when calculating the new price given eth sent to the pool
int256 constant DEC_PRC1 = 1e22;
int256 constant DEC_PRC2 = 1e11;
// used for translating usd and usdc from their 6 decimals to the
// internal accounting that uses 2 decimal
uint64 constant DEC_USD_ADJU64 = 1e4;
int64 constant DEC_USD_ADJ = 1e4;
int256 constant DEC_USD_ADJ256 = 1e4;
// this turns the  18 decimals used in ETH deposits into ETH as represented
// in this contract, which uses 5 decimals
uint256 constant DEC_ETH_ADJ = 1e13;
int256 constant DEC_ETH_ADJ_INT256 = 1e13;
// given the decimals used in this contract, this factor is applied when
// determining pool eth given liquidity and price
int256 constant DEC_POOL_ETH = 1e11;
// given the decimals used in this contract, this factor is applied when determining
// pool USD given liquidity and price
int256 constant DEC_POOL_USD = 1e10;
// given the decimals used in this contract, this number puts the eth notional
// value into USD, represented with 2 decimals
int256 constant DEC_ETHVAL_ADJ = 1e21;
// this is the factor  that turns eth notional into USD decimals,
// the required margin is 20%, or 1/5, while 1e-21 converts the number to USD
int256 constant DEC_REQM = 5e21;
// this removes precision from the last block price allowing it to be stored int48
int256 constant DEC_BLOK_PRICE = 1e4;
// LP fees are accumulated as the the sum of fee/liquidity' each time a fee is paid
// this is a number less than one,
//we multiply by this factor to avoid rounding it to zero.
//When fees collected by LPs attributed, this number is then used as the divisor
int256 constant FEE_PREC_FACTOR = 1e12;
// this allows the contract to use test eth, as it is difficult to get
// thus someone can send 0.01 eth on Rinkeby and it will show up as 10 eth
// when 1.0 eth is sent to the user, he will receive 0.0001 eth
// it will be removed on the mainnet
uint256 constant DEC_TEST_ETH = 1e4;
// When the market value, in USD, of the equity collateral reaches this number
// LP's no longer receive equity tokens as payment,but instead ETH and USD
int256 constant INSUR_USDVAL_TARGET = 1e9; // lower for tests of non-token state
// an LP's liquidity is constructed so that the price level will have to move
// approximately 10%  before the LP's initial ETH and USD deposit are deleted
// the liquidity corresponding to an LP ETH deposit equals
// 22 * price^0.5 * eth deposited  virtual ETH in the LP's pool is thus 22 times
// his actual add
int256 constant LIQ_ADD_22 = 22;
// a liquidated LP pays 1/100 times his pool value in a penalty
int256 constant LP_DEF_PENALTY = 100;
// during an LP add, after the liquidity number is determined, the amount of USD collateral needed
// is determined. it is USDCdeposit = liquidity * LIQ_ADD_19 / price^0.5
// virtual USD in the LP's pool is thus 19 times his actual add
int256 constant LIQ_ADD_19 = 19;
// this caps the inputs to prevent overflow errors, while allowing users to
// deposit $100 billion
int256 constant MAX_IN = 2**46 - 1;
uint64 constant MAX_IN_64 = 2**46 - 1;
// A user's account balance must be at least $100. The contract needs to prevent
// accounts that are so small that any default would imply a net loss to the contract after paying the liquidator
int256 constant MIN_REQ_MARGIN = 1e4;
uint64 constant MIN_IN_64 = 10000;
// an LP need to supply at least 1.0 eth to provide liquidity
int256 constant MIN_IN_POOL = 10000;
// an LP cannot input 1e9 eth to avoid overflow errors
int256 constant MAX_IN_POOL = 1e14;
// for monitoring the block of the last price update. It doesn't have to exactly correct
int256 constant MIN_ETH_LIQ = 100000;
// gives liquidators a minimum fee
int256 constant MIN_LIQ_FEE = 2000;
// for monitoring the block of the last price update. It doesn't have to exactly correct
// so taking the modulus of the block number divided by 65535
uint256 constant MOD16_DIV = 2**16 - 1;
// to prevent flash crashes the contract only allows the price to move by 5.0%
// as this is applied to the square root of price, the restriction is applied using a
// constant of 2.5%, which is approximately a 5% price change cap
int256 constant PRICE_FLOOR = 9750;
int256 constant PRICE_CAP = 10250;

// File contracts/StablePerpRinkeby.sol

pragma solidity ^0.8.0;

//SPDX-License-Identifier: BSL-1.1

contract StablePerpRinkeby {
    /// note: global trade params
    TradeParams public tradeParams;
    EquityBalances public equityBalances;
    //

    // token
    UsdXToken public usdxToken;
    UsdXToken public equityToken;
    ERC20 public usdcToken;

    mapping(address => LiqProviderAcct) public liqProviderAcct;
    mapping(address => TradeAccount) public tradeAccount;
    bool public tokenPayout = true;

    struct TradeAccount {
        int64 vUSD;
        int64 vETH;
        uint8 acctType;
        address tradeDelegate;
    }

    struct LiqProviderAcct {
        int64 liquidity;
        int64 usdFeeSnap;
        int64 ethFeeSnap;
        uint64 epoch;
        int64 initEth;
        int64 initUsd;
    }

    struct TradeParams {
        // these items all udpate on a trade
        int64 sqrtPrice;
        int64 totLiquidity;
        int64 usdFeeSum; // regular trade pays fee in USD
        int48 lastBlockPrice;
        uint16 lastBlockNum;
    }

    struct EquityBalances {
        int64 usd;
        int64 eth;
        int64 ethFeeSum; // updated when you do a withdrawal
        int48 emaSqrtPrice; // exponental moving average (exp of price - to prevent defaulting)
    }

    event Deposit(address indexed user, uint8 coin, uint256 amount);
    event DepositLiquidity(address indexed user, int256 amountUSD, int256 amountETH);
    event DepositInjection(address indexed user, int256 amountUSD, uint256 amountETH, uint256 tokensIssued);
    event Inactivated(address indexed user);
    event Liquidity(address indexed user, int256 liquidityAdd);
    event LiquidateLP(address indexed liquidator, address defaulter, int256 indivLiquidity);
    event Liquidate(address indexed liquidator, address defaulter, int256 ethLiquidated);
    event Redemption(address indexed user, int256 liquiditySubtract);
    event Swap(address indexed user, int256 liquidity, int256 usdToAccountDec2, int64 ethToAccountDec5, int256 newSqrtPrice);
    event Trade(
        address indexed user,
        address indexed trader,
        int256 liquidity,
        int256 usdToAccountDec2,
        int64 ethToAccountDec5,
        int256 newSqrtPrice
    );
    event Withdraw(address indexed user, uint8 coin, uint256 amount);

    constructor(
        int64 _sqrtp,
        address _usdxToken,
        address _equityToken,
        address _usdcToken
    ) {
        tradeParams.sqrtPrice = _sqrtp;
        tradeParams.lastBlockPrice = int48(_sqrtp) / 10000;
        equityBalances.emaSqrtPrice = int48(_sqrtp) / 10000;
        tokenPayout = false;
        usdxToken = UsdXToken(_usdxToken);
        equityToken = UsdXToken(_equityToken);
        usdcToken = ERC20(_usdcToken);
    }

    function mktValReqMargin(address _acctAddress) public view returns (int256 mktValue, int256 reqMargin) {
        int256 sqrtPrice = tradeParams.sqrtPrice;
        int256 ethPosition = tradeAccount[_acctAddress].vETH;
        int256 usdPosition = tradeAccount[_acctAddress].vUSD;
        if (tradeAccount[_acctAddress].acctType == 2) {
            int256 indivLiq = liqProviderAcct[_acctAddress].liquidity;
            int256 daiTxFees = (indivLiq * int256(tradeParams.usdFeeSum - liqProviderAcct[_acctAddress].usdFeeSnap)) / FEE_PREC_FACTOR;
            int256 ethTxFees = (indivLiq * int256(equityBalances.ethFeeSum - liqProviderAcct[_acctAddress].ethFeeSnap)) / FEE_PREC_FACTOR;
            ethPosition += (indivLiq * DEC_POOL_ETH) / sqrtPrice + ethTxFees;
            usdPosition += (indivLiq * sqrtPrice) / DEC_POOL_USD + daiTxFees;
        }
        mktValue = usdPosition + (sqrtPrice * sqrtPrice * ethPosition) / DEC_ETHVAL_ADJ;
        reqMargin = (ethPosition * (sqrtPrice**2)) / DEC_REQM;
        reqMargin = reqMargin > 0 ? reqMargin : -reqMargin;
        if (reqMargin < MIN_REQ_MARGIN) {
            if (reqMargin > 0) {
                reqMargin = MIN_REQ_MARGIN;
            } else {
                reqMargin = 0;
            }
        }
    }

    function fundUSDC(uint64 _UsdDec6) external returns (bool) {
        uint64 usdDec2 = _UsdDec6 / DEC_USD_ADJU64;
        require(usdDec2 >= MIN_IN_64 && usdDec2 < MAX_IN_64, "send amount wrong size");
        bool success = usdcToken.transferFrom(msg.sender, address(this), uint256(_UsdDec6));
        if (success) {
            tradeAccount[msg.sender].vUSD += int64(usdDec2);
            tradeAccount[msg.sender].acctType = 1;
            emit Deposit(msg.sender, 0, uint256(_UsdDec6));
        }
        return (success);
    }

    function fundUSDx(uint64 _UsdDec6) external returns (bool) {
        uint64 usdDec2 = _UsdDec6 / DEC_USD_ADJU64;
        require(usdDec2 >= MIN_IN_64 && usdDec2 < MAX_IN_64, "send amount wrong size");
        bool success = usdxToken.burn(msg.sender, uint256(_UsdDec6));
        if (success) {
            tradeAccount[msg.sender].vUSD += int64(usdDec2);
            tradeAccount[msg.sender].acctType = 1;
            emit Deposit(msg.sender, 2, uint256(_UsdDec6));
        }
        return (success);
    }

    function fundETH() external payable returns (bool) {
        uint64 amt = uint64((DEC_TEST_ETH * msg.value) / DEC_ETH_ADJ);
        require(amt >= MIN_IN_64 && amt < MAX_IN_64, "send amount wrong size");
        tradeAccount[msg.sender].acctType = 1;
        tradeAccount[msg.sender].vETH += int64(amt);
        emit Deposit(msg.sender, 1, msg.value);
        return true;
    }

    function withDrawUSDC(int256 _usdDec2) external returns (bool success) {
        require(_usdDec2 >= 0 && _usdDec2 < MAX_IN, "size amount illogical");
        int256 sqrtPrice = tradeParams.sqrtPrice;
        mktValReqMarginCheck(msg.sender, sqrtPrice, -_usdDec2, 0, true);
        tradeAccount[msg.sender].vUSD -= int64(_usdDec2);
        int256 totLiq = int256(tradeParams.totLiquidity);
        int256 usdFee = (_usdDec2 * BPS_WD_FEE) / BASIS_PT_ADJ;
        if (totLiq > 0) {
            tradeParams.usdFeeSum += int64((FEE_PREC_FACTOR * usdFee * 3) / (totLiq * 4));
        }
        equityBalances.usd += int64(usdFee / 4);
        _usdDec2 -= usdFee;
        success = usdcToken.transfer(msg.sender, uint256(_usdDec2 * DEC_USD_ADJ));
        require(success, "insufficient usdc in contract");
        if (tradeAccount[msg.sender].vUSD == 0 && tradeAccount[msg.sender].vETH == 0) {
            delete tradeAccount[msg.sender];
            emit Inactivated(msg.sender);
        }
        emit Withdraw(msg.sender, 0, uint256(_usdDec2 * DEC_USD_ADJ));
    }

    function withDrawUSDx(int256 _usdDec2) external returns (bool success) {
        require(_usdDec2 > 0 && _usdDec2 < MAX_IN, "size amount illogical");
        int256 sqrtPrice = tradeParams.sqrtPrice;
        mktValReqMarginCheck(msg.sender, sqrtPrice, -_usdDec2, 0, true);
        tradeAccount[msg.sender].vUSD -= int64(_usdDec2);
        int256 totLiq = int256(tradeParams.totLiquidity);
        if (totLiq > 0) {
            int256 usdFee = (_usdDec2 * BPS_WD_FEE_X) / BASIS_PT_ADJ;
            equityBalances.usd += int64(usdFee / 4);
            tradeParams.usdFeeSum += int64((FEE_PREC_FACTOR * usdFee * 3) / (totLiq * 4));
            _usdDec2 -= usdFee;
        }
        success = usdxToken.mint(msg.sender, uint256(_usdDec2 * DEC_USD_ADJ));
        require(success, "mint failed");
        if (tradeAccount[msg.sender].vUSD == 0 && tradeAccount[msg.sender].vETH == 0) {
            delete tradeAccount[msg.sender];
            emit Inactivated(msg.sender);
        }
        emit Withdraw(msg.sender, 2, uint256(_usdDec2 * DEC_USD_ADJ));
        return true;
    }

    function withDrawETH(int256 _ethDec5) external returns (bool success) {
        require(_ethDec5 >= 0 && _ethDec5 < MAX_IN, "size amount illogical");
        int256 sqrtPrice = tradeParams.sqrtPrice;
        mktValReqMarginCheck(msg.sender, sqrtPrice, 0, -_ethDec5, true);
        tradeAccount[msg.sender].vETH -= int64(_ethDec5);
        int256 totLiq = tradeParams.totLiquidity;
        int256 ethFee = (_ethDec5 * BPS_WD_FEE) / BASIS_PT_ADJ;
        if (totLiq > 0) {
            equityBalances.ethFeeSum += int64((FEE_PREC_FACTOR * ethFee * 3) / (totLiq * 4));
        }
        equityBalances.eth += int64(ethFee / 4);
        _ethDec5 -= ethFee;
        uint256 ethOut = ((uint256(_ethDec5) * DEC_ETH_ADJ) / DEC_TEST_ETH);
        require(address(this).balance >= ethOut, "insufficient eth or usdc in contract");
        payable(msg.sender).transfer(ethOut);

        if (tradeAccount[msg.sender].vUSD == 0 && tradeAccount[msg.sender].vETH == 0) {
            delete tradeAccount[msg.sender];
            emit Inactivated(msg.sender);
        }
        emit Withdraw(msg.sender, 1, ethOut);
        return true;
    }

    function updateTrader(address _tradeDelegate) external returns (bool success) {
        require(tradeAccount[msg.sender].acctType != 0);
        tradeAccount[msg.sender].tradeDelegate = _tradeDelegate;
        return true;
    }

    function addLiquidity() external payable returns (bool) {
        require(tradeAccount[msg.sender].acctType == 0, "must be new");
        int256 ethIn = int256((DEC_TEST_ETH * msg.value) / DEC_ETH_ADJ);
        require(ethIn > MIN_IN_POOL && ethIn < MAX_IN_POOL, "position too small/big");
        int256 sqrtPrice = tradeParams.sqrtPrice;
        int256 liqi = (LIQ_ADD_22 * ethIn * sqrtPrice) / DEC_POOL_ETH;
        int256 usdIn = (((liqi * sqrtPrice) / LIQ_ADD_19) / DEC_POOL_USD);
        bool success = usdcToken.transferFrom(msg.sender, address(this), uint256(usdIn * DEC_USD_ADJ));
        require(success, "token transfer fail");
        tradeParams.totLiquidity += int64(liqi);
        tradeAccount[msg.sender].vUSD += int64(usdIn - ((liqi * sqrtPrice) / DEC_POOL_USD));
        tradeAccount[msg.sender].vETH += int64(ethIn - ((liqi * DEC_POOL_ETH) / sqrtPrice));
        tradeAccount[msg.sender].acctType = 2;
        liqProviderAcct[msg.sender].usdFeeSnap = tradeParams.usdFeeSum;
        liqProviderAcct[msg.sender].ethFeeSnap = equityBalances.ethFeeSum;
        liqProviderAcct[msg.sender].epoch = uint64(block.timestamp);
        liqProviderAcct[msg.sender].liquidity = int64(liqi);
        liqProviderAcct[msg.sender].initEth = int64(ethIn);
        liqProviderAcct[msg.sender].initUsd = int64(usdIn);
        emit DepositLiquidity(msg.sender, usdIn, ethIn);
        emit Liquidity(msg.sender, liqi);
        return true;
    }

    function removeLiquidity() external returns (bool success) {
        int256 sqrtPrice = tradeParams.sqrtPrice;
        int256 indivLiquidity = liqProviderAcct[msg.sender].liquidity;
        int256 daiTxFees = (indivLiquidity * int256(tradeParams.usdFeeSum - liqProviderAcct[msg.sender].usdFeeSnap)) / FEE_PREC_FACTOR;
        int256 ethTxFees = (indivLiquidity * int256(equityBalances.ethFeeSum - liqProviderAcct[msg.sender].ethFeeSnap)) / FEE_PREC_FACTOR;
        int256 netUsd = (indivLiquidity * sqrtPrice) / DEC_POOL_USD + tradeAccount[msg.sender].vUSD;
        int256 netEth = (indivLiquidity * DEC_POOL_ETH) / sqrtPrice + tradeAccount[msg.sender].vETH;
        if ((liqProviderAcct[msg.sender].epoch + EARLY_WD_DEFINED) > block.timestamp) {
            int256 penaltyFee = (sqrtPrice * indivLiquidity) / DEC_POOL_USD / 100;
            tradeParams.usdFeeSum += int64((FEE_PREC_FACTOR * penaltyFee) / int256(tradeParams.totLiquidity));
            tradeAccount[msg.sender].vUSD -= int64(penaltyFee);
        }
        delete liqProviderAcct[msg.sender];
        if (tokenPayout) {
            int256 tokens = daiTxFees + ((ethTxFees * (sqrtPrice**2)) / DEC_ETHVAL_ADJ);
            success = equityToken.mint(msg.sender, uint256(tokens));
            require(success, "token mint failed");
            equityBalances.usd += int64(daiTxFees);
            equityBalances.eth += int64(ethTxFees);
            tradeAccount[msg.sender].vETH = int64(netEth);
            tradeAccount[msg.sender].vUSD = int64(netUsd);
        } else {
            tradeAccount[msg.sender].vUSD = int64(daiTxFees + netUsd);
            tradeAccount[msg.sender].vETH = int64(ethTxFees + netEth);
        }
        tradeAccount[msg.sender].acctType = 1;
        tradeParams.totLiquidity -= int64(indivLiquidity);
        emit Liquidity(msg.sender, -indivLiquidity);
    }

    function swap(
        int64 _ethD5ToTrader,
        int256 _sqrtPLimit,
        address _account
    ) external returns (bool success) {
        require(msg.sender == _account || msg.sender == tradeAccount[_account].tradeDelegate, "tradedelegate");
        int256 sqrtPrice = tradeParams.sqrtPrice;
        int256 liqTotal = tradeParams.totLiquidity;
        int48 lastBlockPrc = tradeParams.lastBlockPrice;
        if ((block.number % MOD16_DIV) != uint256(tradeParams.lastBlockNum)) {
            lastBlockPrc = int48(sqrtPrice / DEC_BLOK_PRICE);
            tradeParams.lastBlockPrice = lastBlockPrc;
            tradeParams.lastBlockNum = uint16(block.number % MOD16_DIV);
            equityBalances.emaSqrtPrice = lastBlockPrc / 5 + (4 * equityBalances.emaSqrtPrice) / 5;
        }
        int256 newsqrtPrice = DEC_PRC1 / ((DEC_PRC1 / sqrtPrice) - ((DEC_PRC2 * int256(_ethD5ToTrader)) / liqTotal));
        if (_ethD5ToTrader > 0) {
            _sqrtPLimit = _sqrtPLimit < (PRICE_CAP * int256(lastBlockPrc)) ? _sqrtPLimit : PRICE_CAP * int256(lastBlockPrc);
            require(newsqrtPrice <= _sqrtPLimit, "prcCap exceeded");
        } else {
            _sqrtPLimit = _sqrtPLimit > (PRICE_FLOOR * int256(lastBlockPrc)) ? _sqrtPLimit : PRICE_FLOOR * int256(lastBlockPrc);
            require(newsqrtPrice >= _sqrtPLimit, "prcFloor breached");
        }
        int256 usdToTrader = ((liqTotal * sqrtPrice) / DEC_POOL_USD) - ((liqTotal * newsqrtPrice) / DEC_POOL_USD);
        int256 fees = (BPS_TRADE_FEE * usdToTrader) / BASIS_PT_ADJ;
        fees = fees > 0 ? fees : -fees;
        usdToTrader -= fees;
        mktValReqMarginCheck(msg.sender, newsqrtPrice, usdToTrader, int256(_ethD5ToTrader), true);
        tradeAccount[_account].vUSD += int64(usdToTrader);
        tradeAccount[_account].vETH += _ethD5ToTrader;
        equityBalances.usd += int64(fees / 4);
        tradeParams.usdFeeSum += int64((FEE_PREC_FACTOR * fees * 3) / (liqTotal * 4));
        tradeParams.sqrtPrice = int64(newsqrtPrice);
        emit Trade(_account, msg.sender, liqTotal, usdToTrader, _ethD5ToTrader, newsqrtPrice);
        return true;
    }

    function swapE(int256 _sqrtPLimit, bool _isUSDC) external payable returns (bool success) {
        int256 ethIn = int256((DEC_TEST_ETH * msg.value) / DEC_ETH_ADJ);
        int256 sqrtPrice = tradeParams.sqrtPrice;
        int256 liqTotal = tradeParams.totLiquidity;
        int48 lastBlockPrc = tradeParams.lastBlockPrice;
        if ((block.number % MOD16_DIV) != uint256(tradeParams.lastBlockNum)) {
            lastBlockPrc = int48(sqrtPrice / DEC_BLOK_PRICE);
            tradeParams.lastBlockPrice = lastBlockPrc;
            tradeParams.lastBlockNum = uint16(block.number % MOD16_DIV);
            equityBalances.emaSqrtPrice = lastBlockPrc / 5 + (4 * equityBalances.emaSqrtPrice) / 5;
        }
        int256 newsqrtPrice = DEC_PRC1 / ((DEC_PRC1 / sqrtPrice) + ((DEC_PRC2 * int256(ethIn)) / liqTotal));

        _sqrtPLimit = _sqrtPLimit > (PRICE_FLOOR * int256(lastBlockPrc)) ? _sqrtPLimit : PRICE_FLOOR * int256(lastBlockPrc);
        require(newsqrtPrice >= _sqrtPLimit, "prcFloor breached");
        int256 usdToTrader = ((liqTotal * sqrtPrice) / DEC_POOL_USD) - ((liqTotal * newsqrtPrice) / DEC_POOL_USD);

        int256 fees = (BPS_SWAP_FEE * usdToTrader) / BASIS_PT_ADJ;
        if (_isUSDC) {
            fees += (BPS_USDC_SWAP_FEE * usdToTrader) / BASIS_PT_ADJ;
        }
        usdToTrader -= fees;
        if (_isUSDC) {
            success = usdcToken.transfer(msg.sender, uint256(usdToTrader * DEC_USD_ADJ));
        } else {
            success = usdxToken.mint(msg.sender, uint256(usdToTrader * DEC_USD_ADJ));
        }
        require(success, "insufficient usdc in contract");
        equityBalances.usd += int64(fees / 4);
        tradeParams.usdFeeSum += int64((FEE_PREC_FACTOR * fees * 3) / (liqTotal * 4));
        tradeParams.sqrtPrice = int64(newsqrtPrice);
        emit Swap(msg.sender, liqTotal, usdToTrader, int64(ethIn), newsqrtPrice);
    }

    function swapU(
        int256 _usdIn,
        int256 _sqrtPLimit,
        bool _isUSDC
    ) external returns (bool success) {
        if (_isUSDC) {
            success = usdcToken.transfer(msg.sender, uint256(_usdIn));
        } else {
            success = usdxToken.burn(msg.sender, uint256(_usdIn));
        }
        require(success && _usdIn > 1000);
        _usdIn = _usdIn / DEC_USD_ADJ256;
        int256 fees = (BPS_SWAP_FEE * _usdIn) / BASIS_PT_ADJ;
        _usdIn -= fees;
        int256 sqrtPrice = tradeParams.sqrtPrice;
        int256 liqTotal = tradeParams.totLiquidity;
        int256 newsqrtPrice = sqrtPrice + (DEC_POOL_USD * _usdIn) / liqTotal;
        int48 lastBlockPrc = tradeParams.lastBlockPrice;
        if ((block.number % MOD16_DIV) != uint256(tradeParams.lastBlockNum)) {
            lastBlockPrc = int48(tradeParams.sqrtPrice / DEC_BLOK_PRICE);
            tradeParams.lastBlockPrice = lastBlockPrc;
            tradeParams.lastBlockNum = uint16(block.number % MOD16_DIV);
            equityBalances.emaSqrtPrice = lastBlockPrc / 5 + (4 * equityBalances.emaSqrtPrice) / 5;
        }
        _sqrtPLimit = _sqrtPLimit < (PRICE_CAP * int256(lastBlockPrc)) ? _sqrtPLimit : PRICE_CAP * int256(lastBlockPrc);
        require(newsqrtPrice <= _sqrtPLimit, "prcCap exceeded");
        equityBalances.usd += int64(fees / 4);
        tradeParams.usdFeeSum += int64((FEE_PREC_FACTOR * fees * 3) / (liqTotal * 4));
        int256 _ethD5ToTrader = ((liqTotal * DEC_POOL_ETH) / sqrtPrice) - ((liqTotal * DEC_POOL_ETH) / newsqrtPrice);
        tradeParams.sqrtPrice = int64(newsqrtPrice);
        emit Swap(msg.sender, liqTotal, int64(_ethD5ToTrader), int64(_usdIn), newsqrtPrice);
        payable(msg.sender).transfer((uint256(_ethD5ToTrader) * DEC_ETH_ADJ) / DEC_TEST_ETH);
    }

    function liquidate(address _defaulter, int256 _ethTarget) external returns (bool success) {
        require(tradeAccount[msg.sender].acctType == 1 && tradeAccount[_defaulter].acctType == 1, "no LPs");
        int256 sqrtPrice = equityBalances.emaSqrtPrice;
        int256 ethPosition = tradeAccount[_defaulter].vETH;
        require((ethPosition * _ethTarget) > 0 && ((100 * _ethTarget) / ethPosition) <= 100, "illogical size");
        require(_ethTarget <= -MIN_ETH_LIQ || _ethTarget >= MIN_ETH_LIQ || _ethTarget == ethPosition, "leaves insufficient residual");
        mktValReqMarginCheck(_defaulter, sqrtPrice, 0, 0, false);
        int256 liqFee = (_ethTarget * (sqrtPrice**2)) / DEFAULT_FEE / DEC_ETHVAL_ADJ;
        liqFee = liqFee > 0 ? liqFee : -liqFee;
        if (liqFee < MIN_LIQ_FEE) liqFee = MIN_LIQ_FEE;
        tradeAccount[_defaulter].vUSD -= int64(2 * liqFee - (_ethTarget * sqrtPrice * sqrtPrice) / DEC_ETHVAL_ADJ);
        tradeAccount[_defaulter].vETH -= int64(_ethTarget);
        tradeAccount[msg.sender].vUSD += int64(liqFee - (_ethTarget * sqrtPrice * sqrtPrice) / DEC_ETHVAL_ADJ);
        tradeAccount[msg.sender].vETH += int64(_ethTarget);
        equityBalances.usd += int64(liqFee);
        if ((tradeAccount[_defaulter].vETH == 0) && (tradeAccount[_defaulter].vUSD < 0)) {
            equityBalances.usd += int64(tradeAccount[_defaulter].vUSD);
            delete tradeAccount[_defaulter];
            emit Inactivated(_defaulter);
        }
        emit Liquidate(msg.sender, _defaulter, _ethTarget);
        return true;
    }

    function liquidateLP(address _defaulter) external returns (bool success) {
        int256 indivLiquidity = liqProviderAcct[_defaulter].liquidity;
        require(indivLiquidity > 0 && tradeAccount[msg.sender].acctType == 1, "not for LPs");
        int256 sqrtPrice = equityBalances.emaSqrtPrice * 10000;
        int256 netETH = tradeAccount[_defaulter].vETH + (indivLiquidity * DEC_POOL_ETH) / sqrtPrice;
        int256 netUSD = tradeAccount[_defaulter].vUSD + ((indivLiquidity * sqrtPrice) / DEC_POOL_USD);
        require(
            netETH < -liqProviderAcct[_defaulter].initEth ||
                netUSD < -liqProviderAcct[_defaulter].initUsd ||
                ((netETH * sqrtPrice**2) / DEC_ETHVAL_ADJ + netUSD) < 1000,
            "LP not in default"
        );
        sqrtPrice = tradeParams.sqrtPrice;
        netETH = (indivLiquidity * DEC_POOL_ETH) / sqrtPrice;
        netUSD = ((indivLiquidity * sqrtPrice) / DEC_POOL_USD);
        int256 defaultFee = (indivLiquidity * sqrtPrice) / DEC_POOL_USD / LP_DEF_PENALTY;
        int256 daiTxFees = (indivLiquidity * (tradeParams.usdFeeSum - liqProviderAcct[_defaulter].usdFeeSnap)) / FEE_PREC_FACTOR;
        int256 ethTxFees = (indivLiquidity * (equityBalances.ethFeeSum - liqProviderAcct[_defaulter].ethFeeSnap)) / FEE_PREC_FACTOR;
        tradeAccount[msg.sender].vUSD += int64(defaultFee);
        tradeAccount[_defaulter].vUSD += int64(daiTxFees + netUSD - defaultFee);
        tradeAccount[_defaulter].vETH += int64(ethTxFees + netETH);
        tradeAccount[_defaulter].acctType = 1;
        tradeParams.totLiquidity -= int64(indivLiquidity);
        emit LiquidateLP(msg.sender, _defaulter, indivLiquidity);
        return true;
    }

    function redeemToken(int256 _token) external returns (bool success) {
        require(_token > 0 && _token < MAX_IN, "send amount nonPositive or too big");
        int256 mktValue = equityBalances.usd + (equityBalances.eth * int256(tradeParams.sqrtPrice)**2) / DEC_ETHVAL_ADJ;
        require(mktValue > 0, "equity account negative");
        int256 tokensOutstanding = int256(equityToken.totalSupply());
        int256 usdOut = (_token * int256(equityBalances.usd)) / tokensOutstanding;
        int256 ethOut = (_token * int256(equityBalances.eth)) / tokensOutstanding;
        success = equityToken.burn(msg.sender, uint256(_token));
        require(success, "user has insufficient tokens");
        tradeAccount[msg.sender].vUSD += int64(usdOut);
        equityBalances.usd -= int64(usdOut);
        equityBalances.eth -= int64(ethOut);
        tradeAccount[msg.sender].vETH += int64(ethOut);
        emit Redemption(msg.sender, _token);
    }

    function injectToken(int256 _usdDec6) external payable returns (bool success) {
        require(_usdDec6 >= 0 && (_usdDec6 / 1e4) < MAX_IN, "too big");
        int256 _ethIn = int256((msg.value * DEC_TEST_ETH) / DEC_ETH_ADJ);
        success = usdcToken.transferFrom(msg.sender, address(this), uint256(_usdDec6));
        require(success, "user insufficient tokens");
        _usdDec6 = (_usdDec6 / 1e4);
        int256 ethPrice = int256(tradeParams.sqrtPrice)**2;
        int256 mktvalue = _usdDec6 + (_ethIn * ethPrice) / DEC_ETHVAL_ADJ;
        equityBalances.usd += int64(_usdDec6);
        equityBalances.eth += int64(_ethIn);
        int256 fundLevel = int256(equityBalances.usd) + (int256(equityBalances.eth * ethPrice) / DEC_ETHVAL_ADJ);
        if (fundLevel > INSUR_USDVAL_TARGET) {
            tokenPayout = false;
        } else {
            tokenPayout = true;
        }
        uint256 tokensOut;
        if (fundLevel < 0 && mktvalue > -fundLevel) {
            uint256 tokensOutstanding = equityToken.totalSupply();
            tokensOut = tokensOutstanding / 3;
            (success) = equityToken.mint(msg.sender, tokensOut);
            require(success, "mint failed");
        }
        emit DepositInjection(msg.sender, _usdDec6, msg.value, tokensOut);
        return true;
    }

    function mktValReqMarginCheck(
        address _acctAddress,
        int256 _sqrtPrice,
        int256 _usdOut,
        int256 _ethOut,
        bool _initMargin
    ) internal view {
        int256 ethPosition = tradeAccount[_acctAddress].vETH + _ethOut;
        int256 usdPosition = tradeAccount[_acctAddress].vUSD + _usdOut;
        if (tradeAccount[_acctAddress].acctType == 2) {
            int256 indivLiq = liqProviderAcct[_acctAddress].liquidity;
            ethPosition += (indivLiq * DEC_POOL_ETH) / _sqrtPrice;
            usdPosition += (indivLiq * _sqrtPrice) / DEC_POOL_USD;
        }
        int256 mktValue = usdPosition + ((_sqrtPrice**2) * ethPosition) / DEC_ETHVAL_ADJ;
        int256 reqMargin = (ethPosition * (_sqrtPrice**2)) / DEC_REQM;
        reqMargin = reqMargin > 0 ? reqMargin : -reqMargin;
        if (reqMargin < MIN_REQ_MARGIN) {
            if (reqMargin > 0) {
                reqMargin = MIN_REQ_MARGIN;
            } else {
                reqMargin = 0;
            }
        }
        if (_initMargin) {
            require(mktValue >= ((reqMargin * 3) / 2), "not enough capital");
        } else {
            require(mktValue < reqMargin, "not in def");
        }
    }
}