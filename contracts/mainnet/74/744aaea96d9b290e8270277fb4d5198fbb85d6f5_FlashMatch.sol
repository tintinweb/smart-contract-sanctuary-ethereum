// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "./interfaces/IWETH.sol";
import "./interfaces/IMorpho.sol";
import "solmate/tokens/ERC20.sol";
import "./interfaces/ICompound.sol";
import "solmate/utils/SafeTransferLib.sol";
import "./interfaces/IERC3156FlashLender.sol";
import "./interfaces/IERC3156FlashBorrower.sol";

contract FlashMatch is IERC3156FlashBorrower {
    using SafeTransferLib for ERC20;
    enum Mode {
        DAI,
        OTHER
    }

    address public constant dai = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public constant cDai = 0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643;
    address public constant wEth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant cEth = 0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5;
    IMorpho public constant morpho =
        IMorpho(0x8888882f8f843896699869179fB6E4f7e3B58888);
    IComptroller public constant comptroller =
        IComptroller(0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B);
    IERC3156FlashLender public constant lender =
        IERC3156FlashLender(0x1EB4CF3A948E7D72A198fe073cCb8C7a948cD853);

    constructor() {
        address[] memory cTokens = new address[](1);
        cTokens[0] = cDai;
        comptroller.enterMarkets(cTokens);
    }

    /// @dev Allows to receive ETH.
    receive() external payable {}

    /// @dev ERC-3156 Flash loan callback
    function onFlashLoan(
        address initiator,
        address, // token = dai
        uint256 amount,
        uint256, // fee = 0
        bytes calldata data
    ) external override returns (bytes32) {
        require(msg.sender == address(lender), "FlashMatch: Untrusted lender");
        require(
            initiator == address(this),
            "FlashMatch: Untrusted loan initiator"
        );

        (Mode mode, address cToken, uint256 maxGasForMatching) = abi.decode(
            data,
            (Mode, address, uint256)
        );

        if (mode == Mode.DAI) {
            // supply on Morpho
            ERC20(dai).approve(address(morpho), amount);
            morpho.supply(cDai, address(this), amount, maxGasForMatching);
            // transfer withdraw on Morpho
            morpho.withdraw(cDai, type(uint256).max);
        } else {
            // supply DAI on Compound
            ERC20(dai).approve(cDai, type(uint256).max);
            require(
                ICToken(cDai).mint(amount) == 0,
                "Flashmatch: supply on Compound failed"
            );

            // borrow token on Compound
            (, uint256 collateralFactor, ) = comptroller.markets(cDai);
            uint256 amountToBorrow = (amount *
                collateralFactor *
                95 *
                ICompoundOracle(comptroller.oracle()).getUnderlyingPrice(
                    cDai
                )) /
                ICompoundOracle(comptroller.oracle()).getUnderlyingPrice(
                    cToken
                ) /
                100 /
                1e18;

            require(
                ICToken(cToken).borrow(amountToBorrow) == 0,
                "Flashmatch: borrow on Compound failed"
            );

            // supply on Morpho
            address underlying = cToken != cEth
                ? ICToken(cToken).underlying()
                : wEth;
            if (cToken == cEth) IWETH(wEth).deposit{value: amountToBorrow}();
            ERC20(underlying).safeApprove(address(morpho), amountToBorrow);
            morpho.supply(
                cToken,
                address(this),
                amountToBorrow,
                maxGasForMatching
            );

            // transfer withdraw from Morpho
            morpho.withdraw(cToken, type(uint256).max);

            // repay on Compound
            if (cToken != cEth) {
                ERC20(underlying).safeApprove(cToken, type(uint256).max);
                require(
                    ICToken(cToken).repayBorrow(amountToBorrow) == 0,
                    "FlashMatch: repay on Compound failed"
                );
            } else {
                IWETH(wEth).withdraw(amountToBorrow);
                ICEth(cEth).repayBorrow{value: amountToBorrow}();
            }

            // withdraw from Compound
            ICToken(cDai).redeemUnderlying(amount);
        }

        return keccak256("ERC3156FlashBorrower.onFlashLoan");
    }

    /// @dev Match dai market on Morpho.
    ///     - initiate a DAI flash loan
    ///     - supply them into Morpho to match on pool borrowers
    ///     - withdraw to do a transfer withdraw, and match on pool suppliers.
    ///     - reimburse the flash loan
    /// @dev Send some DAI dust on the contract, to avoid revert because of
    /// Morpho rounding errors.
    /// @param amount the amount of DAI to flashloan.
    /// @param maxGasForMatching the `maxGasForMatching` to use for the supply.
    function flashMatchDai(uint256 amount, uint256 maxGasForMatching) public {
        bytes memory data = abi.encode(Mode.DAI, address(0), maxGasForMatching);
        require(lender.flashFee(dai, amount) == 0, "Flashloan is not free");
        ERC20(dai).approve(
            address(lender),
            ERC20(dai).allowance(address(this), address(lender)) + amount
        );
        lender.flashLoan(this, dai, amount, data);
    }

    /// @dev Match `cToken` market on Morpho.
    ///     - initiate a DAI flash loan
    ///     - supply them into Compound
    ///     - borrow on the `cToken` market
    ///     - use the borrowed tokens to supply on Morpho to match on pool borrowers
    ///     - withdraw to do a transfer withdraw, and match on pool suppliers
    ///     - reimburse the flash loan
    /// @dev Send some underlying token dust on the contract, to avoid revert because
    /// of Morpho rounding errors.
    /// @param cToken the market to match.
    /// @param amount the amount of DAI to flashloan.
    /// @param maxGasForMatching the `maxGasForMatching` to use for the supply.
    function flashMatchOther(
        address cToken,
        uint256 amount,
        uint256 maxGasForMatching
    ) public {
        bytes memory data = abi.encode(Mode.OTHER, cToken, maxGasForMatching);
        require(lender.flashFee(dai, amount) == 0, "Flashloan is not free");
        ERC20(dai).approve(
            address(lender),
            ERC20(dai).allowance(address(this), address(lender)) + amount
        );
        lender.flashLoan(this, dai, amount, data);
    }
}

// SPDX-License-Identifier: GNU AGPLv3
pragma solidity ^0.8.0;

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256) external;
}

// SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.13;

// prettier-ignore
interface IMorpho {

    /// STORAGE ///

    function defaultMaxGasForMatching() external view returns (Types.MaxGasForMatching memory);
    function maxSortedUsers() external view returns (uint256);
    function dustThreshold() external view returns (uint256);
    function supplyBalanceInOf(address, address) external view returns (Types.SupplyBalance memory);
    function borrowBalanceInOf(address, address) external view returns (Types.BorrowBalance memory);
    function enteredMarkets(address) external view returns (address);
    function deltas(address) external view returns (Types.Delta memory);
    function marketsCreated() external view returns (address[] memory);
    function marketParameters(address) external view returns (Types.MarketParameters memory);
    function p2pDisabled(address) external view returns (bool);
    function p2pSupplyIndex(address) external view returns (uint256);
    function p2pBorrowIndex(address) external view returns (uint256);
    function lastPoolIndexes(address) external view returns (Types.LastPoolIndexes memory);
    function marketStatus(address) external view returns (Types.MarketStatus memory);
    // function comptroller() external view returns (IComptroller);
    // function interestRatesManager() external view returns (IInterestRatesManager);
    // function rewardsManager() external view returns (IRewardsManager);
    // function positionsManager() external view returns (IPositionsManager);
    // function incentiveVault() external view returns (IIncentivesVault);
    function treasuryVault() external view returns (address);
    function cEth() external view returns (address);
    function wEth() external view returns (address);

    /// GETTERS ///

    function updateP2PIndexes(address _poolTokenAddress) external;
    function getEnteredMarkets(address _user) external view returns (address[] memory enteredMarkets_);
    function getAllMarkets() external view returns (address[] memory marketsCreated_);
    function getHead(address _poolTokenAddress, Types.PositionType _positionType) external view returns (address head);
    function getNext(address _poolTokenAddress, Types.PositionType _positionType, address _user) external view returns (address next);

    /// GOVERNANCE ///

    function setMaxSortedUsers(uint256 _newMaxSortedUsers) external;
    function setDefaultMaxGasForMatching(Types.MaxGasForMatching memory _maxGasForMatching) external;
    function setTreasuryVault(address _newTreasuryVaultAddress) external;
    function setIncentivesVault(address _newIncentivesVault) external;
    function setRewardsManager(address _rewardsManagerAddress) external;
    function setDustThreshold(uint256 _dustThreshold) external;
    function setP2PDisable(address _poolTokenAddress, bool _p2pDisabled) external;
    function setReserveFactor(address _poolTokenAddress, uint256 _newReserveFactor) external;
    function setP2PIndexCursor(address _poolTokenAddress, uint16 _p2pIndexCursor) external;
    function setPauseStatus(address _poolTokenAddress) external;
    function setPartialPauseStatus(address _poolTokenAddress) external;
    function claimToTreasury(address _poolTokenAddress, uint256 _amount) external;
    function createMarket(address _poolTokenAddress, Types.MarketParameters calldata _params) external;

    /// USERS ///

    function supply(address _poolTokenAddress, address _onBehalf, uint256 _amount) external;
    function supply(address _poolTokenAddress, address _onBehalf, uint256 _amount, uint256 _maxGasForMatching) external;
    function borrow(address _poolTokenAddress, uint256 _amount) external;
    function borrow(address _poolTokenAddress, uint256 _amount, uint256 _maxGasForMatching) external;
    function withdraw(address _poolTokenAddress, uint256 _amount) external;
    function repay(address _poolTokenAddress, address _onBehalf, uint256 _amount) external;
    function liquidate(address _poolTokenBorrowedAddress, address _poolTokenCollateralAddress, address _borrower, uint256 _amount) external;
    function claimRewards(address[] calldata _cTokenAddresses, bool _tradeForMorphoToken) external;
}

library Types {
    /// ENUMS ///

    enum PositionType {
        SUPPLIERS_IN_P2P,
        SUPPLIERS_ON_POOL,
        BORROWERS_IN_P2P,
        BORROWERS_ON_POOL
    }

    /// STRUCTS ///

    struct SupplyBalance {
        uint256 inP2P; // In supplier's peer-to-peer unit, a unit that grows in underlying value, to keep track of the interests earned by suppliers in peer-to-peer. Multiply by the peer-to-peer supply index to get the underlying amount.
        uint256 onPool; // In cToken. Multiply by the pool supply index to get the underlying amount.
    }

    struct BorrowBalance {
        uint256 inP2P; // In borrower's peer-to-peer unit, a unit that grows in underlying value, to keep track of the interests paid by borrowers in peer-to-peer. Multiply by the peer-to-peer borrow index to get the underlying amount.
        uint256 onPool; // In cdUnit, a unit that grows in value, to keep track of the debt increase when borrowers are on Compound. Multiply by the pool borrow index to get the underlying amount.
    }

    // Max gas to consume during the matching process for supply, borrow, withdraw and repay functions.
    struct MaxGasForMatching {
        uint64 supply;
        uint64 borrow;
        uint64 withdraw;
        uint64 repay;
    }

    struct Delta {
        uint256 p2pSupplyDelta; // Difference between the stored peer-to-peer supply amount and the real peer-to-peer supply amount (in cToken).
        uint256 p2pBorrowDelta; // Difference between the stored peer-to-peer borrow amount and the real peer-to-peer borrow amount (in cdUnit).
        uint256 p2pSupplyAmount; // Sum of all stored peer-to-peer supply (in peer-to-peer unit).
        uint256 p2pBorrowAmount; // Sum of all stored peer-to-peer borrow (in peer-to-peer unit).
    }

    struct AssetLiquidityData {
        uint256 collateralValue; // The collateral value of the asset.
        uint256 maxDebtValue; // The maximum possible debt value of the asset.
        uint256 debtValue; // The debt value of the asset.
        uint256 underlyingPrice; // The price of the token.
        uint256 collateralFactor; // The liquidation threshold applied on this token.
    }

    struct LiquidityData {
        uint256 collateralValue; // The collateral value.
        uint256 maxDebtValue; // The maximum debt value possible.
        uint256 debtValue; // The debt value.
    }

    // Variables are packed together to save gas (will not exceed their limit during Morpho's lifetime).
    struct LastPoolIndexes {
        uint32 lastUpdateBlockNumber; // The last time the peer-to-peer indexes were updated.
        uint112 lastSupplyPoolIndex; // Last pool supply index.
        uint112 lastBorrowPoolIndex; // Last pool borrow index.
    }

    struct MarketParameters {
        uint16 reserveFactor; // Proportion of the interest earned by users sent to the DAO for each market, in basis point (100% = 10 000). The value is set at market creation.
        uint16 p2pIndexCursor; // Position of the peer-to-peer rate in the pool's spread. Determine the weights of the weighted arithmetic average in the indexes computations ((1 - p2pIndexCursor) * r^S + p2pIndexCursor * r^B) (in basis point).
    }

    struct MarketStatus {
        bool isCreated; // Whether or not this market is created.
        bool isPaused; // Whether the market is paused or not (all entry points on Morpho are frozen; supply, borrow, withdraw, repay and liquidate).
        bool isPartiallyPaused; // Whether the market is partially paused or not (only supply and borrow are frozen).
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
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
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
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

// SPDX-License-Identifier: GNU AGPLv3
pragma solidity ^0.8.0;

interface ICEth {
    function accrueInterest() external returns (uint256);

    function borrowRate() external returns (uint256);

    function borrowIndex() external returns (uint256);

    function borrowBalanceStored(address) external returns (uint256);

    function mint() external payable;

    function exchangeRateCurrent() external returns (uint256);

    function exchangeRateStored() external view returns (uint256);

    function supplyRatePerBlock() external returns (uint256);

    function redeem(uint256) external returns (uint256);

    function redeemUnderlying(uint256) external returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address,
        address,
        uint256
    ) external returns (bool);

    function transfer(address dst, uint256 amount) external returns (bool);

    function balanceOf(address) external returns (uint256);

    function balanceOfUnderlying(address account) external returns (uint256);

    function borrow(uint256) external returns (uint256);

    function repayBorrow() external payable;

    function borrowBalanceCurrent(address) external returns (uint256);

    function borrowRatePerBlock() external view returns (uint256);
}

interface IComptroller {
    struct CompMarketState {
        /// @notice The market's last updated compBorrowIndex or compSupplyIndex
        uint224 index;
        /// @notice The block number the index was last updated at
        uint32 block;
    }

    function liquidationIncentiveMantissa() external view returns (uint256);

    function closeFactorMantissa() external view returns (uint256);

    function admin() external view returns (address);

    function oracle() external view returns (address);

    function markets(address)
        external
        view
        returns (
            bool isListed,
            uint256 collateralFactorMantissa,
            bool isComped
        );

    function enterMarkets(address[] calldata cTokens) external returns (uint256[] memory);

    function exitMarket(address cToken) external returns (uint256);

    function mintAllowed(
        address cToken,
        address minter,
        uint256 mintAmount
    ) external returns (uint256);

    function mintVerify(
        address cToken,
        address minter,
        uint256 mintAmount,
        uint256 mintTokens
    ) external;

    function redeemAllowed(
        address cToken,
        address redeemer,
        uint256 redeemTokens
    ) external returns (uint256);

    function redeemVerify(
        address cToken,
        address redeemer,
        uint256 redeemAmount,
        uint256 redeemTokens
    ) external;

    function borrowAllowed(
        address cToken,
        address borrower,
        uint256 borrowAmount
    ) external returns (uint256);

    function borrowVerify(
        address cToken,
        address borrower,
        uint256 borrowAmount
    ) external;

    function repayBorrowAllowed(
        address cToken,
        address payer,
        address borrower,
        uint256 repayAmount
    ) external returns (uint256);

    function repayBorrowVerify(
        address cToken,
        address payer,
        address borrower,
        uint256 repayAmount,
        uint256 borrowerIndex
    ) external;

    function liquidateBorrowAllowed(
        address cTokenBorrowed,
        address cTokenCollateral,
        address liquidator,
        address borrower,
        uint256 repayAmount
    ) external returns (uint256);

    function liquidateBorrowVerify(
        address cTokenBorrowed,
        address cTokenCollateral,
        address liquidator,
        address borrower,
        uint256 repayAmount,
        uint256 seizeTokens
    ) external;

    function seizeAllowed(
        address cTokenCollateral,
        address cTokenBorrowed,
        address liquidator,
        address borrower,
        uint256 seizeTokens
    ) external returns (uint256);

    function seizeVerify(
        address cTokenCollateral,
        address cTokenBorrowed,
        address liquidator,
        address borrower,
        uint256 seizeTokens
    ) external;

    function transferAllowed(
        address cToken,
        address src,
        address dst,
        uint256 transferTokens
    ) external returns (uint256);

    function transferVerify(
        address cToken,
        address src,
        address dst,
        uint256 transferTokens
    ) external;

    /*** Liquidity/Liquidation Calculations ***/

    function liquidateCalculateSeizeTokens(
        address cTokenBorrowed,
        address cTokenCollateral,
        uint256 repayAmount
    ) external view returns (uint256, uint256);

    function getAccountLiquidity(address)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    function getHypotheticalAccountLiquidity(
        address,
        address,
        uint256,
        uint256
    )
        external
        returns (
            uint256,
            uint256,
            uint256
        );

    function checkMembership(address, address) external view returns (bool);

    function claimComp(address holder) external;

    function claimComp(address holder, address[] memory cTokens) external;

    function compSpeeds(address) external view returns (uint256);

    function compSupplySpeeds(address) external view returns (uint256);

    function compBorrowSpeeds(address) external view returns (uint256);

    function compSupplyState(address) external view returns (CompMarketState memory);

    function compBorrowState(address) external view returns (CompMarketState memory);

    function getCompAddress() external view returns (address);

    function _setPriceOracle(address newOracle) external returns (uint256);

    function _setMintPaused(ICToken cToken, bool state) external returns (bool);

    function _setBorrowPaused(ICToken cToken, bool state) external returns (bool);

    function _setCollateralFactor(ICToken cToken, uint256 newCollateralFactorMantissa)
        external
        returns (uint256);

    function _setCompSpeeds(
        ICToken[] memory cTokens,
        uint256[] memory supplySpeeds,
        uint256[] memory borrowSpeeds
    ) external;
}

interface IInterestRateModel {
    function getBorrowRate(
        uint256 cash,
        uint256 borrows,
        uint256 reserves
    ) external view returns (uint256);

    function getSupplyRate(
        uint256 cash,
        uint256 borrows,
        uint256 reserves,
        uint256 reserveFactorMantissa
    ) external view returns (uint256);
}

interface ICToken {
    function isCToken() external returns (bool);

    function transfer(address dst, uint256 amount) external returns (bool);

    function transferFrom(
        address src,
        address dst,
        uint256 amount
    ) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function balanceOfUnderlying(address owner) external returns (uint256);

    function getAccountSnapshot(address account)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );

    function borrowRatePerBlock() external view returns (uint256);

    function supplyRatePerBlock() external view returns (uint256);

    function totalBorrowsCurrent() external returns (uint256);

    function borrowBalanceCurrent(address account) external returns (uint256);

    function borrowBalanceStored(address account) external view returns (uint256);

    function exchangeRateCurrent() external returns (uint256);

    function exchangeRateStored() external view returns (uint256);

    function getCash() external view returns (uint256);

    function seize(
        address liquidator,
        address borrower,
        uint256 seizeTokens
    ) external returns (uint256);

    function borrowRate() external returns (uint256);

    function borrowIndex() external view returns (uint256);

    function borrow(uint256) external returns (uint256);

    function repayBorrow(uint256) external returns (uint256);

    function repayBorrowBehalf(address borrower, uint256 repayAmount) external returns (uint256);

    function liquidateBorrow(
        address borrower,
        uint256 repayAmount,
        address cTokenCollateral
    ) external returns (uint256);

    function underlying() external view returns (address);

    function mint(uint256) external returns (uint256);

    function redeemUnderlying(uint256) external returns (uint256);

    function accrueInterest() external returns (uint256);

    function totalSupply() external view returns (uint256);

    function totalBorrows() external view returns (uint256);

    function accrualBlockNumber() external view returns (uint256);

    function totalReserves() external view returns (uint256);

    function interestRateModel() external view returns (IInterestRateModel);

    function reserveFactorMantissa() external view returns (uint256);

    function initialExchangeRateMantissa() external view returns (uint256);

    /*** Admin Functions ***/

    function _setPendingAdmin(address payable newPendingAdmin) external returns (uint256);

    function _acceptAdmin() external returns (uint256);

    function _setComptroller(IComptroller newComptroller) external returns (uint256);

    function _setReserveFactor(uint256 newReserveFactorMantissa) external returns (uint256);

    function _reduceReserves(uint256 reduceAmount) external returns (uint256);

    function _setInterestRateModel(IInterestRateModel newInterestRateModel)
        external
        returns (uint256);
}

interface ICEther is ICToken {
    function mint() external payable;

    function repayBorrow() external payable;
}

interface ICompoundOracle {
    function getUnderlyingPrice(address) external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2021 Dai Foundation
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity 0.8.13;

import "./IERC3156FlashBorrower.sol";

interface IERC3156FlashLender {
    /**
     * @dev The amount of currency available to be lent.
     * @param token The loan currency.
     * @return The amount of `token` that can be borrowed.
     */
    function maxFlashLoan(address token) external view returns (uint256);

    /**
     * @dev The fee to be charged for a given loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @return The amount of `token` to be charged for the loan, on top of the returned principal.
     */
    function flashFee(address token, uint256 amount)
        external
        view
        returns (uint256);

    /**
     * @dev Initiate a flash loan.
     * @param receiver The receiver of the tokens in the loan, and the receiver of the callback.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     */
    function flashLoan(
        IERC3156FlashBorrower receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2021 Dai Foundation
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity 0.8.13;

interface IERC3156FlashBorrower {
    /**
     * @dev Receive a flash loan.
     * @param initiator The initiator of the loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param fee The additional amount of tokens to repay.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     * @return The keccak256 hash of "ERC3156FlashBorrower.onFlashLoan"
     */
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32);
}