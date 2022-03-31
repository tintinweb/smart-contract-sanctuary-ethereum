// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;
pragma abicoder v2;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./IOneSplit.sol";
import "./IAToken.sol";


/// @title AToken Aarna token implementation
/// @notice Main contract that forms A1Token, A2Token..... AnToken
contract AToken is Context, IAToken {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // solhint-disable-next-line var-name-mixedcase
    IERC20 public aarnaFinanceContract;
    IOneSplit public constant ONEINCH_EXCHANGE =
        IOneSplit(0xee520C8042169f13DF44013561febf8F26b0Aa0b);

    uint8 public constant FEE_PERCENT = 1;
    // TODO REPLACE BELOW WITH INTENDED WALLET ADDRESS
    address payable public constant PLATFORM_WALLET =
        payable(0xb514d3814587e98933d608b221E9170cB2306C19);
    uint256 public constant PRICE_PER_TOKEN = 100;

    // uTokens -> underlyingTokens
    IERC20[] public uTokens;
    // uTokenProportions -> underlyingTokenProportions
    uint256[] public uTokenProportions;

    string public name;
    string public symbol;

    // solhint-disable-next-line var-name-mixedcase
    AggregatorV3Interface internal priceFeedETH_USD;

    /**
     * @dev Struct representing investor details
     * @param isPresent Boolean indicating whether an investor exists
     * @param ethDeposits Investor's deposited ETH
     * @param depositedAt Timestamp of when the deposit was made
     * @param ethWithdrawn Investor's withdrawn ETH
     * @param withdrawnAt Deposit withdrawn timestamp
     * @param uTokenDepositPrice Prices of underlying tokens at the time of deposit
     * @param uTokenWithdrawnPrice Prices of underlying tokens at the time of withdrawal
     * @param underlyingTokenBalances Investor underlying token balance
     */
    struct Investor {
        bool isPresent;
        uint256 ethDeposits;
        uint256 depositedAt;
        uint256 ethWithdrawn;
        uint256 withdrawnAt;
        uint256 tokensIssued;
        uint256[] uTokenDepositPrice;
        uint256[] uTokenWithdrawnPrice;
        uint256[] uTokenBalance;
    }

    uint256 public totalEthInvested;

    // List of Investors, helpful when fetching investors report
    address[] public investors;
    mapping(address => Investor) public investorInfo;

    event Deposit(
        address indexed investor,
        uint256 amount,
        uint256 depositedAt,
        uint256[] uTokenDepositPrice,
        uint256[] uTokenBalance
    );
    event Withdraw(
        address indexed investor,
        uint256 amount,
        uint256 withdrawnAt,
        uint256[] uTokenWithdrawnPrice
    );
    event UnderlyingTokenSet(IERC20[] uTokens);
    event UnderlyingTokenProportionSet(uint256[] uTokensProportion);

    modifier onlyPlatformWallet() {
        // solhint-disable-next-line reason-string
        require(
            msg.sender == PLATFORM_WALLET,
            "onlyPlatformWallet: Caller is not platform wallet"
        );
        _;
    }

    /**
     * @dev Sets values for {aarnaFinanceContract}, {uTokens} and {uTokenProportions}
     *
     * All three of these values are immutable: they can only be set during construction
     */
    function initialize(
        IERC20 _aarnaFinanceContract,
        string memory _name,
        string memory _symbol,
        IERC20[] memory _underlyingTokens,
        uint256[] memory _underlyingTokensProportion
    ) external override {
        name = _name;
        symbol = _symbol;
        priceFeedETH_USD = AggregatorV3Interface(
            0xee520C8042169f13DF44013561febf8F26b0Aa0b
        );
        uint256 sumOfProportions = 0;
        uint256 uTokensLength = _underlyingTokens.length;

        for (uint256 i = 0; i < uTokensLength; i++) {
            sumOfProportions = sumOfProportions.add(
                _underlyingTokensProportion[i]
            );
            uTokens.push(_underlyingTokens[i]);
            uTokenProportions.push(_underlyingTokensProportion[i]);
        }
        require(sumOfProportions == 100, "Invalid proportions");
        aarnaFinanceContract = _aarnaFinanceContract;

        emit UnderlyingTokenSet(_underlyingTokens);
        emit UnderlyingTokenProportionSet(_underlyingTokensProportion);
    }

    /**
     * @dev Contract might receive/hold ETH as part of the maintenance process.
     * The receive function is executed on a call to the contract with empty calldata.
     */
    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}

    /**
     * @dev The fallback function is executed on a call to the contract if
     * none of the other functions match the given function signature.
     */
    fallback() external payable {}

    /**
     * @dev To transfer all ETHs stored in the contract to the caller
     *
     * Requirements:
     * - invocation can be done, only by the contract owner.
     */
    function withdrawAll() external payable onlyPlatformWallet {
        require(
            payable(msg.sender).send(address(this).balance),
            "ETH Withdraw failed"
        );
    }

    /**
     * @dev To transfer ERC20 tokens from the contract
     *
     * Requirements:
     * - invocation can be done, only by the contract owner.
     */
    function withdrawERC20Tokens(
        IERC20 token,
        address receiver,
        uint256 amount
    ) external payable onlyPlatformWallet {
        token.transfer(receiver, amount);
    }

    /**
     * @dev User gets ATokens in exchange of ETH
     */
    function depositETHForATokens() external payable override {
        address investor = _msgSender();
        uint256 uTokensLength = uTokens.length;
        Investor memory invInfo = Investor({
            isPresent: false,
            ethDeposits: 0,
            depositedAt: 0,
            ethWithdrawn: 0,
            withdrawnAt: 0,
            tokensIssued: 0,
            uTokenDepositPrice: new uint256[](uTokensLength),
            uTokenWithdrawnPrice: new uint256[](uTokensLength),
            uTokenBalance: new uint256[](uTokensLength)
        });

        if (!invInfo.isPresent) {
            invInfo.isPresent = true;
            investors.push(investor);
        }

        uint256 totalETH = msg.value;

        // Deduct Fees from totalETH
        uint256 fee = (totalETH.mul(FEE_PERCENT)).div(100);
        // solhint-disable-next-line avoid-low-level-calls
        (bool sent, ) = PLATFORM_WALLET.call{value: fee}("");
        require(sent, "D: ETH sent wallet failed");

        uint256 ethForDeposits = totalETH.sub(fee);

        totalEthInvested = totalEthInvested.add(ethForDeposits);

        for (uint256 i = 0; i < uTokensLength; i++) {
            uint256 allowance = uTokens[i].allowance(
                address(this),
                0xee520C8042169f13DF44013561febf8F26b0Aa0b
            );
            // Gives Allowance to Underlying tokens which is required during withdrawal
            if (!(allowance > 0)) {
                uTokens[i].safeApprove(
                  0xee520C8042169f13DF44013561febf8F26b0Aa0b,
                    ~uint256(0)
                );
            }
            uint256 uTokenBalanceBeforeSwap = uTokens[i].balanceOf(
                address(this)
            );
            uint256 uETHAsPerProportion = (
                ethForDeposits.mul(uTokenProportions[i])
            ).div(100);
            // 1inch Exchange contracts functions
            (
                uint256 returnAmount,
                uint256[] memory distribution
            ) = ONEINCH_EXCHANGE.getExpectedReturn(
                    IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE),
                    uTokens[i],
                    uETHAsPerProportion,
                    1,
                    0
                );
            ONEINCH_EXCHANGE.swap{value: uETHAsPerProportion}(
                IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE),
                uTokens[i],
                uETHAsPerProportion,
                returnAmount,
                distribution,
                0
            );
            uint256 uTokenBalanceAfterSwap = uTokens[i].balanceOf(
                address(this)
            );
            uint8 uTokenDecimal = ERC20(address(uTokens[i])).decimals();
            if (uTokenDecimal < 18) {
                uTokenBalanceAfterSwap = uTokenBalanceAfterSwap.mul(
                    10**(18 - uTokenDecimal)
                );
            }
            invInfo.uTokenBalance[i] = invInfo.uTokenBalance[i].add(
                uTokenBalanceAfterSwap.sub(uTokenBalanceBeforeSwap)
            );
            invInfo.uTokenDepositPrice[i] = (
                uTokenBalanceAfterSwap.sub(uTokenBalanceBeforeSwap)
            ).div(uETHAsPerProportion);
        }
        // solhint-disable-next-line not-rely-on-time
        invInfo.depositedAt = block.timestamp;
        invInfo.ethDeposits = invInfo.ethDeposits.add(ethForDeposits);

        // Transfer Aarna Token to investor
        (, int256 price, , , ) = priceFeedETH_USD.latestRoundData();
        uint256 _price = uint256(price).div(1e8);
        uint256 investorsETHToUSD = (ethForDeposits.div(1e18)).mul(_price);
        uint256 investorAarnaTokens = (investorsETHToUSD.div(PRICE_PER_TOKEN))
            .mul(1e18);
        aarnaFinanceContract.transferFrom(
            PLATFORM_WALLET,
            investor,
            investorAarnaTokens
        );
        invInfo.tokensIssued = invInfo.tokensIssued.add(investorAarnaTokens);
        // Store investor info to contract storage
        investorInfo[investor] = invInfo;

        emit Deposit(
            investor,
            ethForDeposits,
            invInfo.depositedAt,
            invInfo.uTokenDepositPrice,
            invInfo.uTokenBalance
        );
    }

    /**
     * @dev Investor withdraws ETH from the contract
     */
    function withdraw() external override {
        address investor = _msgSender();
        Investor memory invInfo = investorInfo[investor];
        require(invInfo.isPresent, "Not an investor");

        uint256 uTokensLength = uTokens.length;
        invInfo.uTokenWithdrawnPrice = new uint256[](uTokensLength);
        for (uint256 i = 0; i < uTokensLength; i++) {
            require(invInfo.uTokenBalance[i] != 0, "Already withdrawn");
            /**
             * Check allowance from AToken to UnderlyingToken
             */
            // uint256 allowance = uTokens[i].allowance(
            //     address(this),
            //     address(uTokens[i])
            // );
            // console.log("Allowance is %s: ", allowance);
            // console.log(
            //     "uToken contract balance: %s",
            //     uTokens[i].balanceOf(address(this))
            // );
            uint8 uTokenDecimal = ERC20(address(uTokens[i])).decimals();
            // console.log("uTokenDecimal: %s", uTokenDecimal);
            if (uTokenDecimal < 18) {
                invInfo.uTokenBalance[i] = invInfo.uTokenBalance[i].div(
                    10**(18 - uTokenDecimal)
                );
            }
            // 1inch Exchange contracts functions
            (
                uint256 returnAmount,
                uint256[] memory distribution
            ) = ONEINCH_EXCHANGE.getExpectedReturn(
                    uTokens[i],
                    IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE),
                    invInfo.uTokenBalance[i],
                    10,
                    0
                );
            // console.log("Return amount: %s", returnAmount);
            ONEINCH_EXCHANGE.swap(
                uTokens[i],
                IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE),
                invInfo.uTokenBalance[i],
                returnAmount,
                distribution,
                0
            );

            invInfo.ethWithdrawn = invInfo.ethWithdrawn.add(returnAmount);
            // console.log(
            //     "invInfo.uTokenBalance[i] / returnAmount: %s / %s",
            //     invInfo.uTokenBalance[i],
            //     returnAmount
            // );
            if (uTokenDecimal < 18) {
                invInfo.uTokenWithdrawnPrice[i] = (
                    invInfo.uTokenBalance[i].mul(10**(18 - uTokenDecimal))
                ).div(returnAmount);
            } else {
                invInfo.uTokenWithdrawnPrice[i] = invInfo.uTokenBalance[i].div(
                    returnAmount
                );
            }
            // console.log(
            //     "invInfo.uTokenWithdrawnPrice[i]: %s",
            //     invInfo.uTokenWithdrawnPrice[i]
            // );
            invInfo.uTokenBalance[i] = 0;
        }
        // solhint-disable-next-line not-rely-on-time
        invInfo.withdrawnAt = block.timestamp;
        invInfo.ethDeposits = 0;

        // Get Aarna Tokens from Investor's wallet to PLATFORM_WALLET
        // solhint-disable-next-line reason-string
        require(
            aarnaFinanceContract.balanceOf(investor) >= invInfo.tokensIssued,
            "Insufficient balance cannot withdraw"
        );
        aarnaFinanceContract.transferFrom(
            investor,
            PLATFORM_WALLET,
            invInfo.tokensIssued
        );

        invInfo.tokensIssued = 0;

        totalEthInvested = totalEthInvested.sub(invInfo.ethWithdrawn);

        // Store investor info to contract storage
        investorInfo[investor] = invInfo;

        // Transfer ETH to Investor
        // solhint-disable-next-line avoid-low-level-calls
        (bool sent, ) = payable(investor).call{value: invInfo.ethWithdrawn}("");
        require(sent, "W: ETH sent failed");

        emit Withdraw(
            investor,
            invInfo.ethWithdrawn,
            invInfo.withdrawnAt,
            invInfo.uTokenWithdrawnPrice
        );
    }

    /**
     * @dev Returns the underlying tokens proportion
     */
    function getUnderlyingTokenProportions()
        external
        view
        override
        returns (uint256[] memory underlyingTokenProportions)
    {
        return uTokenProportions;
    }

    /**
     * @dev Returns the underlying tokens proportion
     */
    function getUnderlyingTokens()
        external
        view
        override
        returns (IERC20[] memory underlyingTokens)
    {
        return uTokens;
    }

    /**
     * @dev Returns the lenght of total investors
     */
    function getInvestorsLength() external view override returns (uint256) {
        return investors.length;
    }

    /**
     * @dev Returns the investor details
     */
    function getInvestorDetails(address investor)
        external
        view
        returns (Investor memory)
    {
        return investorInfo[investor];
    }
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title IAToken Interface for AToken
/// @notice Interface of the AToken
interface IAToken {
    /**
     * @dev User gets ATokens in exchange of ETH
     */
    function depositETHForATokens() external payable;

    /**
     * @dev User withdraws the deposited ETH and gives back ATokens
     */
    function withdraw() external;

    /**
     *
     */
    function initialize(
        IERC20 aarnaFinanceContract,
        string memory _name,
        string memory _symbol,
        IERC20[] memory _underlyingTokens,
        uint256[] memory _underlyingTokensProportion
    ) external;

    /**
     * @dev Returns the underlying tokens proportion
     */
    function getUnderlyingTokenProportions()
        external
        view
        returns (uint256[] memory underlyingTokenProportions);

    /**
     * @dev Returns the underlying tokens proportion
     */
    function getUnderlyingTokens()
        external
        view
        returns (IERC20[] memory underlyingTokens);

    /**
     * @dev Returns the length of investors
     */
    function getInvestorsLength() external view returns (uint256);
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

//
//  [ msg.sender ]
//       | |
//       | |
//       \_/
// +---------------+ ________________________________
// | OneSplitAudit | _______________________________  \
// +---------------+                                 \ \
//       | |                      ______________      | | (staticcall)
//       | |                    /  ____________  \    | |
//       | | (call)            / /              \ \   | |
//       | |                  / /               | |   | |
//       \_/                  | |               \_/   \_/
// +--------------+           | |           +----------------------+
// | OneSplitWrap |           | |           |   OneSplitViewWrap   |
// +--------------+           | |           +----------------------+
//       | |                  | |                     | |
//       | | (delegatecall)   | | (staticcall)        | | (staticcall)
//       \_/                  | |                     \_/
// +--------------+           | |             +------------------+
// |   OneSplit   |           | |             |   OneSplitView   |
// +--------------+           | |             +------------------+
//       | |                  / /
//        \ \________________/ /
//         \__________________/
//

contract IOneSplitConsts {
    // flags = FLAG_DISABLE_UNISWAP + FLAG_DISABLE_BANCOR + ...
    uint256 internal constant FLAG_DISABLE_UNISWAP = 0x01;
    uint256 internal constant DEPRECATED_FLAG_DISABLE_KYBER = 0x02; // Deprecated
    uint256 internal constant FLAG_DISABLE_BANCOR = 0x04;
    uint256 internal constant FLAG_DISABLE_OASIS = 0x08;
    uint256 internal constant FLAG_DISABLE_COMPOUND = 0x10;
    uint256 internal constant FLAG_DISABLE_FULCRUM = 0x20;
    uint256 internal constant FLAG_DISABLE_CHAI = 0x40;
    uint256 internal constant FLAG_DISABLE_AAVE = 0x80;
    uint256 internal constant FLAG_DISABLE_SMART_TOKEN = 0x100;
    uint256 internal constant DEPRECATED_FLAG_ENABLE_MULTI_PATH_ETH = 0x200; // Deprecated, Turned off by default
    uint256 internal constant FLAG_DISABLE_BDAI = 0x400;
    uint256 internal constant FLAG_DISABLE_IEARN = 0x800;
    uint256 internal constant FLAG_DISABLE_CURVE_COMPOUND = 0x1000;
    uint256 internal constant FLAG_DISABLE_CURVE_USDT = 0x2000;
    uint256 internal constant FLAG_DISABLE_CURVE_Y = 0x4000;
    uint256 internal constant FLAG_DISABLE_CURVE_BINANCE = 0x8000;
    uint256 internal constant DEPRECATED_FLAG_ENABLE_MULTI_PATH_DAI = 0x10000; // Deprecated, Turned off by default
    uint256 internal constant DEPRECATED_FLAG_ENABLE_MULTI_PATH_USDC = 0x20000; // Deprecated, Turned off by default
    uint256 internal constant FLAG_DISABLE_CURVE_SYNTHETIX = 0x40000;
    uint256 internal constant FLAG_DISABLE_WETH = 0x80000;
    uint256 internal constant FLAG_DISABLE_UNISWAP_COMPOUND = 0x100000; // Works only when one of assets is ETH or FLAG_ENABLE_MULTI_PATH_ETH
    uint256 internal constant FLAG_DISABLE_UNISWAP_CHAI = 0x200000; // Works only when ETH<>DAI or FLAG_ENABLE_MULTI_PATH_ETH
    uint256 internal constant FLAG_DISABLE_UNISWAP_AAVE = 0x400000; // Works only when one of assets is ETH or FLAG_ENABLE_MULTI_PATH_ETH
    uint256 internal constant FLAG_DISABLE_IDLE = 0x800000;
    uint256 internal constant FLAG_DISABLE_MOONISWAP = 0x1000000;
    uint256 internal constant FLAG_DISABLE_UNISWAP_V2 = 0x2000000;
    uint256 internal constant FLAG_DISABLE_UNISWAP_V2_ETH = 0x4000000;
    uint256 internal constant FLAG_DISABLE_UNISWAP_V2_DAI = 0x8000000;
    uint256 internal constant FLAG_DISABLE_UNISWAP_V2_USDC = 0x10000000;
    uint256 internal constant FLAG_DISABLE_ALL_SPLIT_SOURCES = 0x20000000;
    uint256 internal constant FLAG_DISABLE_ALL_WRAP_SOURCES = 0x40000000;
    uint256 internal constant FLAG_DISABLE_CURVE_PAX = 0x80000000;
    uint256 internal constant FLAG_DISABLE_CURVE_RENBTC = 0x100000000;
    uint256 internal constant FLAG_DISABLE_CURVE_TBTC = 0x200000000;
    uint256 internal constant DEPRECATED_FLAG_ENABLE_MULTI_PATH_USDT =
        0x400000000; // Deprecated, Turned off by default
    uint256 internal constant DEPRECATED_FLAG_ENABLE_MULTI_PATH_WBTC =
        0x800000000; // Deprecated, Turned off by default
    uint256 internal constant DEPRECATED_FLAG_ENABLE_MULTI_PATH_TBTC =
        0x1000000000; // Deprecated, Turned off by default
    uint256 internal constant DEPRECATED_FLAG_ENABLE_MULTI_PATH_RENBTC =
        0x2000000000; // Deprecated, Turned off by default
    uint256 internal constant FLAG_DISABLE_DFORCE_SWAP = 0x4000000000;
    uint256 internal constant FLAG_DISABLE_SHELL = 0x8000000000;
    uint256 internal constant FLAG_ENABLE_CHI_BURN = 0x10000000000;
    uint256 internal constant FLAG_DISABLE_MSTABLE_MUSD = 0x20000000000;
    uint256 internal constant FLAG_DISABLE_CURVE_SBTC = 0x40000000000;
    uint256 internal constant FLAG_DISABLE_DMM = 0x80000000000;
    uint256 internal constant FLAG_DISABLE_UNISWAP_ALL = 0x100000000000;
    uint256 internal constant FLAG_DISABLE_CURVE_ALL = 0x200000000000;
    uint256 internal constant FLAG_DISABLE_UNISWAP_V2_ALL = 0x400000000000;
    uint256 internal constant FLAG_DISABLE_SPLIT_RECALCULATION = 0x800000000000;
    uint256 internal constant FLAG_DISABLE_BALANCER_ALL = 0x1000000000000;
    uint256 internal constant FLAG_DISABLE_BALANCER_1 = 0x2000000000000;
    uint256 internal constant FLAG_DISABLE_BALANCER_2 = 0x4000000000000;
    uint256 internal constant FLAG_DISABLE_BALANCER_3 = 0x8000000000000;
    uint256 internal constant DEPRECATED_FLAG_ENABLE_KYBER_UNISWAP_RESERVE =
        0x10000000000000; // Deprecated, Turned off by default
    uint256 internal constant DEPRECATED_FLAG_ENABLE_KYBER_OASIS_RESERVE =
        0x20000000000000; // Deprecated, Turned off by default
    uint256 internal constant DEPRECATED_FLAG_ENABLE_KYBER_BANCOR_RESERVE =
        0x40000000000000; // Deprecated, Turned off by default
    uint256 internal constant FLAG_ENABLE_REFERRAL_GAS_SPONSORSHIP =
        0x80000000000000; // Turned off by default
    uint256 internal constant DEPRECATED_FLAG_ENABLE_MULTI_PATH_COMP =
        0x100000000000000; // Deprecated, Turned off by default
    uint256 internal constant FLAG_DISABLE_KYBER_ALL = 0x200000000000000;
    uint256 internal constant FLAG_DISABLE_KYBER_1 = 0x400000000000000;
    uint256 internal constant FLAG_DISABLE_KYBER_2 = 0x800000000000000;
    uint256 internal constant FLAG_DISABLE_KYBER_3 = 0x1000000000000000;
    uint256 internal constant FLAG_DISABLE_KYBER_4 = 0x2000000000000000;
    uint256 internal constant FLAG_ENABLE_CHI_BURN_BY_ORIGIN =
        0x4000000000000000;
    uint256 internal constant FLAG_DISABLE_MOONISWAP_ALL = 0x8000000000000000;
    uint256 internal constant FLAG_DISABLE_MOONISWAP_ETH = 0x10000000000000000;
    uint256 internal constant FLAG_DISABLE_MOONISWAP_DAI = 0x20000000000000000;
    uint256 internal constant FLAG_DISABLE_MOONISWAP_USDC = 0x40000000000000000;
    uint256 internal constant FLAG_DISABLE_MOONISWAP_POOL_TOKEN =
        0x80000000000000000;
}

abstract contract IOneSplit is IOneSplitConsts {
    function getExpectedReturn(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags // See constants in IOneSplit.sol
    )
        public
        view
        virtual
        returns (uint256 returnAmount, uint256[] memory distribution);

    function getExpectedReturnWithGas(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags, // See constants in IOneSplit.sol
        uint256 destTokenEthPriceTimesGasPrice
    )
        public
        view
        virtual
        returns (
            uint256 returnAmount,
            uint256 estimateGasAmount,
            uint256[] memory distribution
        );

    function swap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 minReturn,
        uint256[] memory distribution,
        uint256 flags
    ) public payable virtual returns (uint256 returnAmount);
}

abstract contract IOneSplitMulti is IOneSplit {
    function getExpectedReturnWithGasMulti(
        IERC20[] memory tokens,
        uint256 amount,
        uint256[] memory parts,
        uint256[] memory flags,
        uint256[] memory destTokenEthPriceTimesGasPrices
    )
        public
        view
        virtual
        returns (
            uint256[] memory returnAmounts,
            uint256 estimateGasAmount,
            uint256[] memory distribution
        );

    function swapMulti(
        IERC20[] memory tokens,
        uint256 amount,
        uint256 minReturn,
        uint256[] memory distribution,
        uint256[] memory flags
    ) public payable virtual returns (uint256 returnAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
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

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}