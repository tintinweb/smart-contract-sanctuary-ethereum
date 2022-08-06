// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;
import "./helpers.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract EulerResolver is EulerHelper {
    /**
     * @dev Get all active sub-account Ids and addresses of a user.
     * @notice Get all sub-account of a user that has some token liquidity in it.
     * @param user Address of user
     * @param tokens Array of the tokens(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     */
    function getAllActiveSubAccounts(address user, address[] memory tokens)
        public
        view
        returns (SubAccount[] memory activeSubAccounts)
    {
        address[] memory _tokens = new address[](tokens.length);

        for (uint256 i = 0; i < tokens.length; i++) {
            _tokens[i] = tokens[i] == getEthAddr() ? getWethAddr() : tokens[i];
        }

        SubAccount[] memory subAccounts = getAllSubAccounts(user);

        bool[] memory activeSubAccBool = new bool[](256);
        uint256 count;
        (activeSubAccBool, count) = getActiveSubAccounts(subAccounts, _tokens);

        activeSubAccounts = new SubAccount[](count);
        uint256 k = 0;

        for (uint256 j = 0; j < subAccounts.length; j++) {
            if (activeSubAccBool[j]) {
                activeSubAccounts[k].id = j;
                activeSubAccounts[k].subAccountAddress = subAccounts[j].subAccountAddress;
                k++;
            }
        }
    }

    /**
     * @dev Get position details of all active sub-accounts.
     * @notice Get position details of all active sub-accounts.
     * @param user Address of user
     * @param activeSubAccountIds Array of active sub-account Ids(0 for primary and 1 - 255 for sub-account)
     * @param tokens Array of the tokens(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     */
    function getPositionOfActiveSubAccounts(
        address user,
        uint256[] memory activeSubAccountIds,
        address[] memory tokens
    ) public view returns (uint256 claimedAmount, Position[] memory positions) {
        address[] memory _tokens = new address[](tokens.length);

        for (uint256 i = 0; i < tokens.length; i++) {
            _tokens[i] = tokens[i] == getEthAddr() ? getWethAddr() : tokens[i];
        }

        uint256 length = activeSubAccountIds.length;
        address[] memory subAccountAddresses = new address[](length);
        positions = new Position[](length);

        Query[] memory qs = new Query[](length);

        for (uint256 i = 0; i < length; i++) {
            subAccountAddresses[i] = getSubAccountAddress(user, activeSubAccountIds[i]);
            qs[i] = Query({ eulerContract: EULER_MAINNET, account: subAccountAddresses[i], markets: _tokens });
        }

        Response[] memory response = new Response[](length);
        response = eulerView.doQueryBatch(qs);

        claimedAmount = getClaimedAmount(user);

        for (uint256 j = 0; j < length; j++) {
            (ResponseMarket[] memory marketsInfo, AccountStatus memory accountStatus) = getSubAccountInfo(
                subAccountAddresses[j],
                response[j],
                _tokens
            );

            positions[j] = Position({
                subAccountInfo: SubAccount({ id: activeSubAccountIds[j], subAccountAddress: subAccountAddresses[j] }),
                accountStatus: accountStatus,
                marketsInfoSubAcc: marketsInfo
            });
        }
    }

    /**
     * @dev Get position details of all active sub-accounts of a user.
     * @notice Get position details of all active sub-accounts.
     * @param user Address of user
     * @param tokens Array of the tokens(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     */
    function getAllPositionsOfUser(address user, address[] memory tokens)
        public
        view
        returns (uint256 claimedAmount, Position[] memory activePositions)
    {
        address[] memory _tokens = new address[](tokens.length);

        for (uint256 i = 0; i < tokens.length; i++) {
            _tokens[i] = tokens[i] == getEthAddr() ? getWethAddr() : tokens[i];
        }

        uint256 length = 256;

        SubAccount[] memory subAccounts = getAllSubAccounts(user);
        (bool[] memory activeSubAcc, uint256 count) = getActiveSubAccounts(subAccounts, _tokens);

        Query[] memory qs = new Query[](count);
        Response[] memory response = new Response[](count);

        SubAccount[] memory activeSubAccounts = new SubAccount[](count);
        uint256 k;

        for (uint256 i = 0; i < length; i++) {
            if (activeSubAcc[i]) {
                qs[i] = Query({
                    eulerContract: EULER_MAINNET,
                    account: subAccounts[i].subAccountAddress,
                    markets: _tokens
                });

                activeSubAccounts[k] = SubAccount({
                    id: subAccounts[i].id,
                    subAccountAddress: subAccounts[i].subAccountAddress
                });

                k++;
            }
        }

        response = eulerView.doQueryBatch(qs);

        claimedAmount = getClaimedAmount(user);

        activePositions = new Position[](count);

        for (uint256 j = 0; j < count; j++) {
            (ResponseMarket[] memory marketsInfo, AccountStatus memory accountStatus) = getSubAccountInfo(
                activeSubAccounts[j].subAccountAddress,
                response[j],
                _tokens
            );

            activePositions[j] = Position({
                subAccountInfo: SubAccount({
                    id: activeSubAccounts[j].id,
                    subAccountAddress: activeSubAccounts[j].subAccountAddress
                }),
                accountStatus: accountStatus,
                marketsInfoSubAcc: marketsInfo
            });
        }
    }
}

contract InstaEulerResolver is EulerResolver {
    string public constant name = "Euler-Resolver-v1.0";
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;
import { DSMath } from "../../../utils/dsmath.sol";
import "./interface.sol";

contract EulerHelper is DSMath {
    address internal constant EUL = 0xd9Fcd98c322942075A5C3860693e9f4f03AAE07b;

    address internal constant EULER_MAINNET = 0x27182842E098f60e3D576794A5bFFb0777E025d3;

    IEulerMarkets internal constant markets = IEulerMarkets(0x3520d5a913427E6F0D6A83E07ccD4A4da316e4d3);

    IEulerGeneralView internal constant eulerView = IEulerGeneralView(0xACC25c4d40651676FEEd43a3467F3169e3E68e42);

    IEulerExecute internal constant eulerExec = IEulerExecute(0x59828FdF7ee634AaaD3f58B19fDBa3b03E2D9d80);

    IEulerDistributor internal constant eulerDistribute = IEulerDistributor(0xd524E29E3BAF5BB085403Ca5665301E94387A7e2);

    struct SubAccount {
        uint256 id;
        address subAccountAddress;
    }

    struct Position {
        SubAccount subAccountInfo;
        AccountStatus accountStatus;
        ResponseMarket[] marketsInfoSubAcc;
    }

    struct AccountStatus {
        uint256 totalCollateral;
        uint256 totalBorrowed;
        uint256 riskAdjustedTotalCollateral;
        uint256 riskAdjustedTotalBorrow;
        uint256 healthScore;
    }

    struct AccountStatusHelper {
        uint256 collateralValue;
        uint256 liabilityValue;
        uint256 healthScore;
    }

    /**
     * @dev Return ethereum address
     */
    function getEthAddr() internal pure returns (address) {
        return 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE; // ETH Address
    }

    /**
     * @dev Return Weth address
     */
    function getWethAddr() internal pure returns (address) {
        return 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; // Mainnet WETH Address
        // return 0xd0A1E359811322d97991E03f863a0C30C2cF029C; // Kovan WETH Address
    }

    function convertTo18(uint256 _dec, uint256 _amt) internal pure returns (uint256 amt) {
        amt = mul(_amt, 10**(18 - _dec));
    }

    /**
     * @dev Get all sub-accounts of a user.
     * @notice Get all sub-accounts of a user.
     * @param user Address of user
     */
    function getAllSubAccounts(address user) public pure returns (SubAccount[] memory subAccounts) {
        uint256 length = 256;
        subAccounts = new SubAccount[](length);

        for (uint256 i = 0; i < length; i++) {
            address subAccount = getSubAccountAddress(user, i);
            subAccounts[i] = SubAccount({ id: i, subAccountAddress: subAccount });
        }
    }

    /**
     * @dev Get all sub-accounts of a user.
     * @notice Get all sub-accounts of a user.
     * @param primary Address of user
     * @param subAccountId sub-account Id(0 for primary and 1 - 255 for sub-account)
     */
    function getSubAccountAddress(address primary, uint256 subAccountId) public pure returns (address) {
        require(subAccountId < 256, "sub-account-id-too-big");
        return address(uint160(primary) ^ uint160(subAccountId));
    }

    /**
     * @dev Get active sub-accounts.
     * @notice Get active sub-accounts.
     * @param subAccounts Array of SubAccount struct(id and address)
     * @param tokens Array of the tokens
     */
    function getActiveSubAccounts(SubAccount[] memory subAccounts, address[] memory tokens)
        public
        view
        returns (bool[] memory activeSubAcc, uint256 count)
    {
        uint256 accLength = subAccounts.length;
        uint256 tokenLength = tokens.length;
        activeSubAcc = new bool[](accLength);

        for (uint256 i = 0; i < accLength; i++) {
            for (uint256 j = 0; j < tokenLength; j++) {
                address eToken = markets.underlyingToEToken(tokens[j]);

                if ((IEToken(eToken).balanceOfUnderlying(subAccounts[i].subAccountAddress)) > 0) {
                    activeSubAcc[i] = true;
                    count++;
                    break;
                }
            }
        }
    }

    /**
     * @dev Get detailed sub-account info.
     * @notice Get detailed sub-account info.
     * @param response Response of a sub-account. 
        (ResponseMarket include enteredMarkets followed by queried token response).
     * @param tokens Array of the tokens(Use WETH address for ETH token)
     */
    function getSubAccountInfo(
        address subAccount,
        Response memory response,
        address[] memory tokens
    ) public view returns (ResponseMarket[] memory marketsInfo, AccountStatus memory accountStatus) {
        uint256 totalLend;
        uint256 totalBorrow;
        uint256 k;

        marketsInfo = new ResponseMarket[](tokens.length);

        for (uint256 i = response.enteredMarkets.length; i < response.markets.length; i++) {
            totalLend += convertTo18(response.markets[i].decimals, response.markets[i].eTokenBalanceUnderlying);
            totalBorrow += convertTo18(response.markets[i].decimals, response.markets[i].dTokenBalance);

            marketsInfo[k] = response.markets[i];
            k++;
        }

        AccountStatusHelper memory accHelper;

        (accHelper.collateralValue, accHelper.liabilityValue, accHelper.healthScore) = getAccountStatus(subAccount);

        accountStatus = AccountStatus({
            totalCollateral: totalLend,
            totalBorrowed: totalBorrow,
            riskAdjustedTotalCollateral: accHelper.collateralValue,
            riskAdjustedTotalBorrow: accHelper.liabilityValue,
            healthScore: accHelper.healthScore //based on risk adjusted values
        });
    }

    function getAccountStatus(address account)
        public
        view
        returns (
            uint256 collateralValue,
            uint256 liabilityValue,
            uint256 healthScore
        )
    {
        LiquidityStatus memory status = eulerExec.liquidity(account);

        collateralValue = status.collateralValue;
        liabilityValue = status.liabilityValue;

        if (liabilityValue == 0) {
            healthScore = type(uint256).max;
        } else {
            healthScore = (collateralValue * 1e18) / liabilityValue;
        }
    }

    function getClaimedAmount(address user) public view returns (uint256 claimedAmount) {
        claimedAmount = eulerDistribute.claimed(user, address(EUL));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
pragma solidity >=0.7.0;

contract DSMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "math-not-safe");
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x - y <= x ? x - y : 0;
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "math-not-safe");
    }

    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    uint256 internal constant WAD = 10**18;
    uint256 internal constant RAY = 10**27;

    function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }

    function wmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }

    function rdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, RAY), y / 2) / y;
    }

    function wdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, WAD), y / 2) / y;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

struct LiquidityStatus {
    uint256 collateralValue;
    uint256 liabilityValue;
    uint256 numBorrows;
    bool borrowIsolated;
}

struct AssetConfig {
    address eTokenAddress;
    bool borrowIsolated;
    uint32 collateralFactor;
    uint32 borrowFactor;
    uint24 twapWindow;
}

// Query
struct Query {
    address eulerContract;
    address account;
    address[] markets;
}

// Response
struct ResponseMarket {
    // Universal
    address underlying;
    string name;
    string symbol;
    uint8 decimals;
    address eTokenAddr;
    address dTokenAddr;
    address pTokenAddr;
    AssetConfig config;
    uint256 poolSize;
    uint256 totalBalances;
    uint256 totalBorrows;
    uint256 reserveBalance;
    uint32 reserveFee;
    uint256 borrowAPY;
    uint256 supplyAPY;
    // Pricing
    uint256 twap;
    uint256 twapPeriod;
    uint256 currPrice;
    uint16 pricingType;
    uint32 pricingParameters;
    address pricingForwarded;
    // Account specific
    uint256 underlyingBalance;
    uint256 eulerAllowance;
    uint256 eTokenBalance;
    uint256 eTokenBalanceUnderlying;
    uint256 dTokenBalance;
    LiquidityStatus liquidityStatus; //for asset
}

struct Response {
    uint256 timestamp;
    uint256 blockNumber;
    ResponseMarket[] markets;
    address[] enteredMarkets;
}

interface IEulerMarkets {
    function underlyingToEToken(address underlying) external view returns (address);
}

interface IEToken {
    function balanceOfUnderlying(address account) external view returns (uint256);
}

interface IEulerGeneralView {
    function doQueryBatch(Query[] memory qs) external view returns (Response[] memory r);

    function doQuery(Query memory q) external view returns (Response memory r);
}

interface IEulerExecute {
    function liquidity(address account) external view returns (LiquidityStatus memory status);
}

interface IEulerDistributor {
    function claimed(address user, address token) external view returns (uint256 claimedAmount);
}