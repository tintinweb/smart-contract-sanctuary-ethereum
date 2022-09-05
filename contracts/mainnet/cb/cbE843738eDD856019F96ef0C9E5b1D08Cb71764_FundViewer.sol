// SPDX-License-Identifier: MIT
// Decontracts Protocol. @2022
pragma solidity >=0.8.14;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IFundAccount} from "../interfaces/fund/IFundAccount.sol";
import {TokenBalance, FundAccountData, LpDetailInfo, LPToken} from "../interfaces/external/IFundViewer.sol";
import {IFundManager} from "../interfaces/fund/IFundManager.sol";
import {IPriceOracle} from "../interfaces/fund/IPriceOracle.sol";
import {IPositionViewer} from "../interfaces/fund/IPositionViewer.sol";

contract FundViewer {
    IFundManager public fundManager;

    // Contract version
    uint256 public constant version = 1;

    constructor(address _fundManager) {
        fundManager = IFundManager(_fundManager);
    }

    function getFundAccountsData(address addr, bool extend) public view returns (FundAccountData[] memory) {
        address[] memory accounts = fundManager.getAccounts(addr);
        FundAccountData[] memory result = new FundAccountData[](accounts.length);
        for (uint256 i = 0; i < accounts.length; i++) {
            result[i] = getFundAccountData(accounts[i], extend);
        }
        return result;
    }

    function getFundAccountData(address account, bool extend) public view returns (FundAccountData memory data) {
        IFundAccount fundAccount = IFundAccount(account);
        data.since = fundAccount.since();
        data.name = fundAccount.name();
        data.gp = fundAccount.gp();
        data.managementFee = fundAccount.managementFee();
        data.carriedInterest = fundAccount.carriedInterest();
        data.underlyingToken = fundAccount.underlyingToken();
        data.initiator = fundAccount.initiator();
        data.initiatorAmount = fundAccount.initiatorAmount();
        data.recipient = fundAccount.recipient();
        data.recipientMinAmount = fundAccount.recipientMinAmount();
        data.allowedProtocols = fundAccount.allowedProtocols();
        data.allowedTokens = fundAccount.allowedTokens();
        data.totalUnit = fundAccount.totalUnit();
        data.totalManagementFeeAmount = fundAccount.totalManagementFeeAmount();
        data.totalCarryInterestAmount = fundAccount.totalCarryInterestAmount();
        data.ethBalance = fundAccount.ethBalance();
        data.totalUnit = fundAccount.totalUnit();
        data.closed = fundAccount.closed();

        data.addr = account;

        data.totalValue = fundManager.calcTotalValue(account);

        if (extend) {
            data.tokenBalances = getFundAccountTokenBalances(data);
            data.lpDetailInfos = getFundAccountLpDetailInfos(fundAccount);
            data.lpTokens = getFundAccountLpTokens(data);
        }
    }

    function getFundAccountTokenBalances(FundAccountData memory data)
        internal
        view
        returns (TokenBalance[] memory tokenBalances)
    {
        IPriceOracle priceOracle = IPriceOracle(fundManager.fundFilter().priceOracle());

        address[] memory allowedTokens = data.allowedTokens;
        tokenBalances = new TokenBalance[](allowedTokens.length + 1);

        for (uint256 i = 0; i < allowedTokens.length; i++) {
            tokenBalances[i].token = allowedTokens[i];
            tokenBalances[i].balance = IERC20(allowedTokens[i]).balanceOf(data.addr);
            tokenBalances[i].value = priceOracle.convert(
                tokenBalances[i].token,
                data.underlyingToken,
                tokenBalances[i].balance
            );
        }
        tokenBalances[allowedTokens.length] = TokenBalance({
            token: address(0),
            balance: address(data.addr).balance,
            value: priceOracle.convert(fundManager.weth9(), data.underlyingToken, address(data.addr).balance)
        });
    }

    function getFundAccountLpDetailInfos(IFundAccount fundAccount)
        internal
        view
        returns (LpDetailInfo[] memory details)
    {
        address[] memory lps = fundAccount.lpList();
        details = new LpDetailInfo[](lps.length);

        for (uint256 i = 0; i < lps.length; i++) {
            details[i].lpAddr = lps[i];
            details[i].detail = fundAccount.lpDetailInfo(lps[i]);
        }
    }

    function getFundAccountLpTokens(FundAccountData memory data) internal view returns (LPToken[] memory lpTokens) {
        IPriceOracle priceOracle = IPriceOracle(fundManager.fundFilter().priceOracle());
        IPositionViewer positionViewer = IPositionViewer(fundManager.fundFilter().positionViewer());

        uint256[] memory tokenIds = fundManager.lpTokensOfAccount(data.addr);

        lpTokens = new LPToken[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            lpTokens[i].tokenId = tokenId;
            (
                lpTokens[i].token0,
                lpTokens[i].token1,
                lpTokens[i].fee,
                lpTokens[i].amount0,
                lpTokens[i].amount1,
                lpTokens[i].fee0,
                lpTokens[i].fee1
            ) = positionViewer.query(tokenId);

            lpTokens[i].amountValue0 = priceOracle.convert(
                lpTokens[i].token0,
                data.underlyingToken,
                lpTokens[i].amount0
            );
            lpTokens[i].amountValue1 = priceOracle.convert(
                lpTokens[i].token1,
                data.underlyingToken,
                lpTokens[i].amount1
            );
            lpTokens[i].feeValue0 = priceOracle.convert(lpTokens[i].token0, data.underlyingToken, lpTokens[i].fee0);
            lpTokens[i].feeValue1 = priceOracle.convert(lpTokens[i].token1, data.underlyingToken, lpTokens[i].fee1);
        }
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
// Decontracts Protocol. @2022
pragma solidity >=0.8.14;

struct Nav {
    // Net Asset Value, can't store as float
    uint256 totalValue;
    uint256 totalUnit;
}

struct LpAction {
    uint256 actionType; // 1. buy, 2. sell
    uint256 amount;
    uint256 unit;
    uint256 time;
    uint256 gain;
    uint256 loss;
    uint256 carry;
    uint256 dao;
}

struct LpDetail {
    uint256 totalAmount;
    uint256 totalUnit;
    LpAction[] lpActions;
}

struct FundCreateParams {
    string name;
    address gp;
    uint256 managementFee;
    uint256 carriedInterest;
    address underlyingToken;
    address initiator;
    uint256 initiatorAmount;
    address recipient;
    uint256 recipientMinAmount;
    address[] allowedProtocols;
    address[] allowedTokens;
}

interface IFundAccount {

    function since() external view returns (uint256);

    function closed() external view returns (uint256);

    function name() external view returns (string memory);

    function gp() external view returns (address);

    function managementFee() external view returns (uint256);

    function carriedInterest() external view returns (uint256);

    function underlyingToken() external view returns (address);

    function ethBalance() external view returns (uint256);

    function initiator() external view returns (address);

    function initiatorAmount() external view returns (uint256);

    function recipient() external view returns (address);

    function recipientMinAmount() external view returns (uint256);

    function lpList() external view returns (address[] memory);

    function lpDetailInfo(address addr) external view returns (LpDetail memory);

    function allowedProtocols() external view returns (address[] memory);

    function allowedTokens() external view returns (address[] memory);

    function isProtocolAllowed(address protocol) external view returns (bool);

    function isTokenAllowed(address token) external view returns (bool);

    function totalUnit() external view returns (uint256);

    function totalManagementFeeAmount() external view returns (uint256);

    function lastUpdateManagementFeeAmount() external view returns (uint256);

    function totalCarryInterestAmount() external view returns (uint256);

    function initialize(FundCreateParams memory params) external;

    function approveToken(
        address token,
        address spender,
        uint256 amount
    ) external;

    function safeTransfer(
        address token,
        address to,
        uint256 amount
    ) external;

    function setTokenApprovalForAll(
        address token,
        address spender,
        bool approved
    ) external;

    function execute(address target, bytes memory data, uint256 value) external returns (bytes memory);

    function buy(address lp, uint256 amount) external;

    function sell(address lp, uint256 ratio) external;

    function collect() external;

    function close() external;

    function updateName(string memory newName) external;

    function wrapWETH9() external;

    function unwrapWETH9() external;

}

// SPDX-License-Identifier: MIT
// Decontracts Protocol. @2022
pragma solidity >=0.8.14;

import {LpDetail, LpAction} from "../fund/IFundAccount.sol";

struct TokenBalance {
    address token;
    uint256 balance;
    uint256 value;
}

struct LpDetailInfo {
    address lpAddr;
    LpDetail detail;
}

struct LPToken {
    uint256 tokenId;
    address token0;
    address token1;
    uint24 fee;
    uint256 amount0;
    uint256 amount1;
    uint256 fee0;
    uint256 fee1;
    uint256 amountValue0;
    uint256 amountValue1;
    uint256 feeValue0;
    uint256 feeValue1;
}

struct FundAccountData {
    address addr;
    // Block time when the account was opened
    uint256 since;
    // Fund create params
    string name;
    address gp;
    uint256 managementFee;
    uint256 carriedInterest;
    address underlyingToken;
    address initiator;
    uint256 initiatorAmount;
    address recipient;
    uint256 recipientMinAmount;
    address[] allowedProtocols;
    address[] allowedTokens;
    uint256 closed;

    // Fund runtime data
    uint256 totalUnit;
    uint256 totalManagementFeeAmount;
    uint256 totalCarryInterestAmount;
    // summary data
    uint256 ethBalance;
    uint256 totalValue;
    // extended data
    TokenBalance[] tokenBalances;
    LpDetailInfo[] lpDetailInfos;
    LPToken[] lpTokens;
}

// SPDX-License-Identifier: MIT
// Decontracts Protocol. @2022
pragma solidity >=0.8.14;

import {IFundFilter} from "./IFundFilter.sol";
import {IPaymentGateway} from "./IPaymentGateway.sol";

interface IFundManager is IPaymentGateway {
    struct AccountCloseParams {
        address account;
        bytes[] paths;
    }

    function owner() external view returns (address);
    function fundFilter() external view returns (IFundFilter);

    function getAccountsCount(address) external view returns (uint256);
    function getAccounts(address) external view returns (address[] memory);

    function buyFund(address, uint256) external payable;
    function sellFund(address, uint256) external;
    function unwrapWETH9(address) external;

    function calcTotalValue(address account) external view returns (uint256 total);

    function lpTokensOfAccount(address account) external view returns (uint256[] memory);

    function provideAccountAllowance(
        address account,
        address token,
        address protocol,
        uint256 amount
    ) external;

    function executeOrder(
        address account,
        address protocol,
        bytes calldata data,
        uint256 value
    ) external returns (bytes memory);

    function onMint(
        address account,
        uint256 tokenId
    ) external;

    function onCollect(
        address account,
        uint256 tokenId
    ) external;

    function onIncrease(
        address account,
        uint256 tokenId
    ) external;

    // @dev Emit an event when new account is created
    // @param account The fund account address
    // @param initiator The initiator address
    // @param recipient The recipient address
    event AccountCreated(address indexed account, address indexed initiator, address indexed recipient);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.14;

interface IPriceOracle {
    function factory() external view returns (address);

    function wethAddress() external view returns (address);

    function convertToETH(address token, uint256 amount) external view returns (uint256);

    function convert(
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) external view returns (uint256);

    function getTokenETHPool(address token) external view returns (address);

    function getPool(address token0, address token1) external view returns (address);
}

// SPDX-License-Identifier: MIT
// Decontracts Protocol. @2022
pragma solidity >=0.8.14;

interface IPositionViewer {

    function query(uint256 tokenId) external view returns (
        address token0,
        address token1,
        uint24 fee,
        uint256 amount0,
        uint256 amount1,
        uint256 fee0,
        uint256 fee1
    );

}

// SPDX-License-Identifier: MIT
// Decontracts Protocol. @2022
pragma solidity >=0.8.14;

struct FundFilterInitializeParams {
    address priceOracle;
    address swapRouter;
    address positionManager;
    address positionViewer;
    address protocolAdapter;
    address[] allowedUnderlyingTokens;
    address[] allowedTokens;
    address[] allowedProtocols;
    uint256 minManagementFee;
    uint256 maxManagementFee;
    uint256 minCarriedInterest;
    uint256 maxCarriedInterest;
    address daoAddress;
    uint256 daoProfit;
}

interface IFundFilter {

    event AllowedUnderlyingTokenUpdated(address indexed token, bool allowed);

    event AllowedTokenUpdated(address indexed token, bool allowed);

    event AllowedProtocolUpdated(address indexed protocol, bool allowed);

    function priceOracle() external view returns (address);

    function swapRouter() external view returns (address);

    function positionManager() external view returns (address);

    function positionViewer() external view returns (address);

    function protocolAdapter() external view returns (address);

    function allowedUnderlyingTokens() external view returns (address[] memory);

    function isUnderlyingTokenAllowed(address token) external view returns (bool);

    function allowedTokens() external view returns (address[] memory);

    function isTokenAllowed(address token) external view returns (bool);

    function allowedProtocols() external view returns (address[] memory);

    function isProtocolAllowed(address protocol) external view returns (bool);

    function minManagementFee() external view returns (uint256);

    function maxManagementFee() external view returns (uint256);

    function minCarriedInterest() external view returns (uint256);

    function maxCarriedInterest() external view returns (uint256);

    function daoAddress() external view returns (address);

    function daoProfit() external view returns (uint256);

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.14;

interface IPaymentGateway {
    function weth9() external view returns (address);
}