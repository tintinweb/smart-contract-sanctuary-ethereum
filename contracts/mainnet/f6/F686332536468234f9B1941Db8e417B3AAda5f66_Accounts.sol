// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.4;

import "./lib/AccountTokenLib.sol";
import "./lib/BitmapLib.sol";
import "./config/Constant.sol";
import "./interfaces/IGlobalConfig.sol";
import "../interfaces/IGemGlobalConfig.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

contract Accounts is Constant, Initializable {
    using AccountTokenLib for AccountTokenLib.TokenInfo;
    using BitmapLib for uint128;
    using SafeMath for uint256;
    using Math for uint256;

    // globalConfig should initialized per pool
    IGlobalConfig public globalConfig;
    IGemGlobalConfig public gemGlobalConfig;

    mapping(address => Account) public accounts;
    mapping(address => uint256) public finAmount;

    modifier onlyAuthorized() {
        _isAuthorized();
        _;
    }

    struct Account {
        // Note, it's best practice to use functions minusAmount, addAmount, totalAmount
        // to operate tokenInfos instead of changing it directly.
        mapping(address => AccountTokenLib.TokenInfo) tokenInfos;
        uint128 depositBitmap;
        uint128 borrowBitmap;
        uint128 collateralBitmap;
        bool isCollInit;
    }

    event CollateralFlagChanged(address indexed _account, uint8 _index, bool _enabled);

    function _isAuthorized() internal view {
        require(
            msg.sender == address(globalConfig.savingAccount()) || msg.sender == address(globalConfig.bank()),
            "not authorized"
        );
    }

    /**
     * Initialize the Accounts
     * @param _globalConfig the global configuration contract
     */
    function initialize(IGlobalConfig _globalConfig, IGemGlobalConfig _gemGlobalConfig) public initializer {
        globalConfig = _globalConfig;
        gemGlobalConfig = _gemGlobalConfig;
    }

    /**
     * @dev Initialize the Collateral flag Bitmap for given account
     * @notice This function is required for the contract upgrade, as previous users didn't
     *         have this collateral feature. So need to init the collateralBitmap for each user.
     * @param _account User account address
     */
    function initCollateralFlag(address _account) public {
        Account storage account = accounts[_account];

        // For all users by default `isCollInit` will be `false`
        if (account.isCollInit == false) {
            // Two conditions:
            // 1) An account has some position previous to this upgrade
            //    THEN: copy `depositBitmap` to `collateralBitmap`
            // 2) A new account is setup after this upgrade
            //    THEN: `depositBitmap` will be zero for that user, so don't copy

            // all deposited tokens be treated as collateral
            if (account.depositBitmap > 0) account.collateralBitmap = account.depositBitmap;
            account.isCollInit = true;
        }

        // when isCollInit == true, function will just return after if condition check
    }

    /**
     * @dev Enable/Disable collateral for a given token
     * @param _tokenIndex Index of the token
     * @param _enable `true` to enable the collateral, `false` to disable
     */
    function setCollateral(uint8 _tokenIndex, bool _enable) public {
        address accountAddr = msg.sender;
        initCollateralFlag(accountAddr);
        Account storage account = accounts[accountAddr];

        if (_enable) {
            account.collateralBitmap = account.collateralBitmap.setBit(_tokenIndex);
            // when set new collateral, no need to evaluate borrow power
        } else {
            account.collateralBitmap = account.collateralBitmap.unsetBit(_tokenIndex);
            // when unset collateral, evaluate borrow power, only when user borrowed already
            if (account.borrowBitmap > 0) {
                require(getBorrowETH(accountAddr) <= getBorrowPower(accountAddr), "Insufficient collateral");
            }
        }

        emit CollateralFlagChanged(msg.sender, _tokenIndex, _enable);
    }

    function setCollateral(uint8[] calldata _tokenIndexArr, bool[] calldata _enableArr) external {
        require(_tokenIndexArr.length == _enableArr.length, "array length does not match");
        for (uint256 i = 0; i < _tokenIndexArr.length; i++) {
            setCollateral(_tokenIndexArr[i], _enableArr[i]);
        }
    }

    function getCollateralStatus(address _account)
        external
        view
        returns (address[] memory tokens, bool[] memory status)
    {
        Account storage account = accounts[_account];
        ITokenRegistry tokenRegistry = globalConfig.tokenRegistry();
        tokens = tokenRegistry.getTokens();
        uint256 tokensCount = tokens.length;
        status = new bool[](tokensCount);
        uint128 collBitmap = account.collateralBitmap;
        for (uint256 i = 0; i < tokensCount; i++) {
            // Example: 0001 << 1 => 0010 (mask for 2nd position)
            uint128 mask = uint128(1) << uint128(i);
            bool isEnabled = (collBitmap & mask) > 0;
            if (isEnabled) status[i] = true;
        }
    }

    /**
     * Check if the user has deposit for any tokens
     * @param _account address of the user
     * @return true if the user has positive deposit balance
     */
    function isUserHasAnyDeposits(address _account) public view returns (bool) {
        Account storage account = accounts[_account];
        return account.depositBitmap > 0;
    }

    /**
     * Check if the user has deposit for a token
     * @param _account address of the user
     * @param _index index of the token
     * @return true if the user has positive deposit balance for the token
     */
    function isUserHasDeposits(address _account, uint8 _index) public view returns (bool) {
        Account storage account = accounts[_account];
        return account.depositBitmap.isBitSet(_index);
    }

    /**
     * Check if the user has borrowed a token
     * @param _account address of the user
     * @param _index index of the token
     * @return true if the user has borrowed the token
     */
    function isUserHasBorrows(address _account, uint8 _index) public view returns (bool) {
        Account storage account = accounts[_account];
        return account.borrowBitmap.isBitSet(_index);
    }

    /**
     * Check if the user has collateral flag set
     * @param _account address of the user
     * @param _index index of the token
     * @return true if the user has collateral flag set for the given index
     */
    function isUserHasCollateral(address _account, uint8 _index) public view returns (bool) {
        Account storage account = accounts[_account];
        return account.collateralBitmap.isBitSet(_index);
    }

    /**
     * Set the deposit bitmap for a token.
     * @param _account address of the user
     * @param _index index of the token
     */
    function setInDepositBitmap(address _account, uint8 _index) internal {
        Account storage account = accounts[_account];
        account.depositBitmap = account.depositBitmap.setBit(_index);
    }

    /**
     * Unset the deposit bitmap for a token
     * @param _account address of the user
     * @param _index index of the token
     */
    function unsetFromDepositBitmap(address _account, uint8 _index) internal {
        Account storage account = accounts[_account];
        account.depositBitmap = account.depositBitmap.unsetBit(_index);
    }

    /**
     * Set the borrow bitmap for a token.
     * @param _account address of the user
     * @param _index index of the token
     */
    function setInBorrowBitmap(address _account, uint8 _index) internal {
        Account storage account = accounts[_account];
        account.borrowBitmap = account.borrowBitmap.setBit(_index);
    }

    /**
     * Unset the borrow bitmap for a token
     * @param _account address of the user
     * @param _index index of the token
     */
    function unsetFromBorrowBitmap(address _account, uint8 _index) internal {
        Account storage account = accounts[_account];
        account.borrowBitmap = account.borrowBitmap.unsetBit(_index);
    }

    function getDepositPrincipal(address _accountAddr, address _token) public view returns (uint256) {
        AccountTokenLib.TokenInfo storage tokenInfo = accounts[_accountAddr].tokenInfos[_token];
        return tokenInfo.getDepositPrincipal();
    }

    function getBorrowPrincipal(address _accountAddr, address _token) public view returns (uint256) {
        AccountTokenLib.TokenInfo storage tokenInfo = accounts[_accountAddr].tokenInfos[_token];
        return tokenInfo.getBorrowPrincipal();
    }

    function getLastDepositBlock(address _accountAddr, address _token) public view returns (uint256) {
        AccountTokenLib.TokenInfo storage tokenInfo = accounts[_accountAddr].tokenInfos[_token];
        return tokenInfo.getLastDepositBlock();
    }

    function getLastBorrowBlock(address _accountAddr, address _token) public view returns (uint256) {
        AccountTokenLib.TokenInfo storage tokenInfo = accounts[_accountAddr].tokenInfos[_token];
        return tokenInfo.getLastBorrowBlock();
    }

    /**
     * Get deposit interest of an account for a specific token
     * @param _account account address
     * @param _token token address
     * @dev The deposit interest may not have been updated in AccountTokenLib, so we need to explicited calcuate it.
     */
    function getDepositInterest(address _account, address _token) public view returns (uint256) {
        AccountTokenLib.TokenInfo storage tokenInfo = accounts[_account].tokenInfos[_token];
        // If the account has never deposited the token, return 0.
        uint256 lastDepositBlock = tokenInfo.getLastDepositBlock();
        if (lastDepositBlock == 0) return 0;
        else {
            // As the last deposit block exists, the block is also a check point on index curve.
            uint256 accruedRate = globalConfig.bank().getDepositAccruedRate(_token, lastDepositBlock);
            return tokenInfo.calculateDepositInterest(accruedRate);
        }
    }

    function getBorrowInterest(address _accountAddr, address _token) public view returns (uint256) {
        AccountTokenLib.TokenInfo storage tokenInfo = accounts[_accountAddr].tokenInfos[_token];
        // If the account has never borrowed the token, return 0
        uint256 lastBorrowBlock = tokenInfo.getLastBorrowBlock();
        if (lastBorrowBlock == 0) return 0;
        else {
            // As the last borrow block exists, the block is also a check point on index curve.
            uint256 accruedRate = globalConfig.bank().getBorrowAccruedRate(_token, lastBorrowBlock);
            return tokenInfo.calculateBorrowInterest(accruedRate);
        }
    }

    function borrow(
        address _accountAddr,
        address _token,
        uint256 _amount
    ) external onlyAuthorized {
        initCollateralFlag(_accountAddr);
        require(_amount != 0, "borrow amount is 0");
        require(isUserHasAnyDeposits(_accountAddr), "no user deposits");
        (uint8 tokenIndex, uint256 tokenDivisor, uint256 tokenPrice, ) = globalConfig
            .tokenRegistry()
            .getTokenInfoFromAddress(_token);
        require(
            getBorrowETH(_accountAddr).add(_amount.mul(tokenPrice).div(tokenDivisor)) <= getBorrowPower(_accountAddr),
            "Insufficient collateral when borrow"
        );

        AccountTokenLib.TokenInfo storage tokenInfo = accounts[_accountAddr].tokenInfos[_token];
        uint256 blockNumber = getBlockNumber();
        uint256 lastBorrowBlock = tokenInfo.getLastBorrowBlock();

        if (lastBorrowBlock == 0) tokenInfo.borrow(_amount, INT_UNIT, blockNumber);
        else {
            calculateBorrowFIN(lastBorrowBlock, _token, _accountAddr, blockNumber);
            uint256 accruedRate = globalConfig.bank().getBorrowAccruedRate(_token, lastBorrowBlock);
            // Update the token principla and interest
            tokenInfo.borrow(_amount, accruedRate, blockNumber);
        }

        // Since we have checked that borrow amount is larget than zero. We can set the borrow
        // map directly without checking the borrow balance.
        setInBorrowBitmap(_accountAddr, tokenIndex);
    }

    /**
     * Update token info for withdraw. The interest will be withdrawn with higher priority.
     */
    function withdraw(
        address _accountAddr,
        address _token,
        uint256 _amount
    ) public onlyAuthorized returns (uint256) {
        initCollateralFlag(_accountAddr);
        (, uint256 tokenDivisor, uint256 tokenPrice, uint256 borrowLTV) = globalConfig
            .tokenRegistry()
            .getTokenInfoFromAddress(_token);

        // if user borrowed before then only check for under liquidation
        Account storage account = accounts[_accountAddr];
        if (account.borrowBitmap > 0) {
            uint256 withdrawETH = _amount.mul(tokenPrice).mul(borrowLTV).div(tokenDivisor).div(100);
            require(
                getBorrowETH(_accountAddr) <= getBorrowPower(_accountAddr).sub(withdrawETH),
                "Insufficient collateral"
            );
        }

        (uint256 amountAfterCommission, ) = _withdraw(_accountAddr, _token, _amount, true);

        return amountAfterCommission;
    }

    /**
     * This function is called in liquidation function. There two difference between this function and
     * the Account.withdraw function: 1) It doesn't check the user's borrow power, because the user
     * is already borrowed more than it's borrowing power. 2) It doesn't take commissions.
     */
    function _withdrawLiquidate(
        address _accountAddr,
        address _token,
        uint256 _amount
    ) internal {
        _withdraw(_accountAddr, _token, _amount, false);
    }

    function _withdraw(
        address _accountAddr,
        address _token,
        uint256 _amount,
        bool _isCommission
    ) internal returns (uint256, uint256) {
        uint256 calcAmount = _amount;
        // Check if withdraw amount is less than user's balance
        require(calcAmount <= getDepositBalanceCurrent(_token, _accountAddr), "Insufficient balance");

        AccountTokenLib.TokenInfo storage tokenInfo = accounts[_accountAddr].tokenInfos[_token];
        uint256 lastBlock = tokenInfo.getLastDepositBlock();
        uint256 blockNumber = getBlockNumber();
        calculateDepositFIN(lastBlock, _token, _accountAddr, blockNumber);

        uint256 principalBeforeWithdraw = tokenInfo.getDepositPrincipal();

        if (lastBlock == 0) tokenInfo.withdraw(calcAmount, INT_UNIT, blockNumber);
        else {
            // As the last deposit block exists, the block is also a check point on index curve.
            uint256 accruedRate = globalConfig.bank().getDepositAccruedRate(_token, lastBlock);
            tokenInfo.withdraw(calcAmount, accruedRate, blockNumber);
        }

        uint256 principalAfterWithdraw = tokenInfo.getDepositPrincipal();
        if (principalAfterWithdraw == 0) {
            uint8 tokenIndex = globalConfig.tokenRegistry().getTokenIndex(_token);
            unsetFromDepositBitmap(_accountAddr, tokenIndex);
        }

        uint256 commission = 0;
        if (_isCommission && _accountAddr != gemGlobalConfig.deFinerCommunityFund()) {
            // DeFiner takes 10% commission on the interest a user earn
            commission = calcAmount
                .sub(principalBeforeWithdraw.sub(principalAfterWithdraw))
                .mul(globalConfig.deFinerRate())
                .div(100);
            deposit(gemGlobalConfig.deFinerCommunityFund(), _token, commission);
            calcAmount = calcAmount.sub(commission);
        }

        return (calcAmount, commission);
    }

    /**
     * Update token info for deposit
     */
    function deposit(
        address _accountAddr,
        address _token,
        uint256 _amount
    ) public onlyAuthorized {
        initCollateralFlag(_accountAddr);
        AccountTokenLib.TokenInfo storage tokenInfo = accounts[_accountAddr].tokenInfos[_token];
        if (tokenInfo.getDepositPrincipal() == 0) {
            uint8 tokenIndex = globalConfig.tokenRegistry().getTokenIndex(_token);
            setInDepositBitmap(_accountAddr, tokenIndex);
        }

        uint256 blockNumber = getBlockNumber();
        uint256 lastDepositBlock = tokenInfo.getLastDepositBlock();
        if (lastDepositBlock == 0) tokenInfo.deposit(_amount, INT_UNIT, blockNumber);
        else {
            calculateDepositFIN(lastDepositBlock, _token, _accountAddr, blockNumber);
            uint256 accruedRate = globalConfig.bank().getDepositAccruedRate(_token, lastDepositBlock);
            tokenInfo.deposit(_amount, accruedRate, blockNumber);
        }
    }

    function repay(
        address _accountAddr,
        address _token,
        uint256 _amount
    ) public onlyAuthorized returns (uint256) {
        initCollateralFlag(_accountAddr);
        // Update tokenInfo
        uint256 amountOwedWithInterest = getBorrowBalanceCurrent(_token, _accountAddr);
        uint256 amount = _amount > amountOwedWithInterest ? amountOwedWithInterest : _amount;
        uint256 remain = _amount > amountOwedWithInterest ? _amount.sub(amountOwedWithInterest) : 0;
        AccountTokenLib.TokenInfo storage tokenInfo = accounts[_accountAddr].tokenInfos[_token];
        // Sanity check
        uint256 borrowPrincipal = tokenInfo.getBorrowPrincipal();
        uint256 lastBorrowBlock = tokenInfo.getLastBorrowBlock();
        require(borrowPrincipal > 0, "BorrowPrincipal not gt 0");
        if (lastBorrowBlock == 0) tokenInfo.repay(amount, INT_UNIT, getBlockNumber());
        else {
            calculateBorrowFIN(lastBorrowBlock, _token, _accountAddr, getBlockNumber());
            uint256 accruedRate = globalConfig.bank().getBorrowAccruedRate(_token, lastBorrowBlock);
            tokenInfo.repay(amount, accruedRate, getBlockNumber());
        }

        if (borrowPrincipal == 0) {
            uint8 tokenIndex = globalConfig.tokenRegistry().getTokenIndex(_token);
            unsetFromBorrowBitmap(_accountAddr, tokenIndex);
        }
        return remain;
    }

    function getDepositBalanceCurrent(address _token, address _accountAddr)
        public
        view
        returns (uint256 depositBalance)
    {
        AccountTokenLib.TokenInfo storage tokenInfo = accounts[_accountAddr].tokenInfos[_token];
        IBank bank = globalConfig.bank();
        uint256 accruedRate;
        uint256 depositRateIndex = bank.depositeRateIndex(_token, tokenInfo.getLastDepositBlock());
        if (tokenInfo.getDepositPrincipal() == 0) {
            return 0;
        } else {
            if (depositRateIndex == 0) {
                accruedRate = INT_UNIT;
            } else {
                accruedRate = bank.depositeRateIndexNow(_token).mul(INT_UNIT).div(depositRateIndex);
            }
            return tokenInfo.getDepositBalance(accruedRate);
        }
    }

    /**
     * Get current borrow balance of a token
     * @param _token token address
     * @dev This is an estimation. Add a new checkpoint first, if you want to derive the exact balance.
     */
    function getBorrowBalanceCurrent(address _token, address _accountAddr) public view returns (uint256 borrowBalance) {
        AccountTokenLib.TokenInfo storage tokenInfo = accounts[_accountAddr].tokenInfos[_token];
        IBank bank = globalConfig.bank();
        uint256 accruedRate;
        uint256 borrowRateIndex = bank.borrowRateIndex(_token, tokenInfo.getLastBorrowBlock());
        if (tokenInfo.getBorrowPrincipal() == 0) {
            return 0;
        } else {
            if (borrowRateIndex == 0) {
                accruedRate = INT_UNIT;
            } else {
                accruedRate = bank.borrowRateIndexNow(_token).mul(INT_UNIT).div(borrowRateIndex);
            }
            return tokenInfo.getBorrowBalance(accruedRate);
        }
    }

    /**
     * Calculate an account's borrow power based on token's LTV
     */
    /*
    function getBorrowPower(address _borrower) public view returns (uint256 power) {
        TokenRegistry tokenRegistry = globalConfig.tokenInfoRegistry();
        uint256 tokenNum = tokenRegistry.getCoinLength();
        for(uint256 i = 0; i < tokenNum; i++) {
            if (isUserHasDeposits(_borrower, uint8(i))) {
                (address token, uint256 divisor, uint256 price, uint256 borrowLTV) =
                    tokenRegistry.getTokenInfoFromIndex(i);

                uint256 depositBalanceCurrent = getDepositBalanceCurrent(token, _borrower);
                power = power.add(depositBalanceCurrent.mul(price).mul(borrowLTV).div(100).div(divisor));
            }
        }
        return power;
    }
    */

    function getBorrowPower(address _borrower) public view returns (uint256 power) {
        Account storage account = accounts[_borrower];

        // if a user have deposits in some tokens and collateral enabled for some
        // then we need to iterate over his deposits for which collateral is also enabled.
        // Hence, we can derive this information by perorming AND bitmap operation
        // hasCollnDepositBitmap = collateralEnabled & hasDeposit
        // Example:
        // collateralBitmap         = 0101
        // depositBitmap            = 0110
        // ================================== OP AND
        // hasCollnDepositBitmap    = 0100 (user can only use his 3rd token as borrow power)
        uint128 hasCollnDepositBitmap = account.collateralBitmap & account.depositBitmap;

        // When no-collateral enabled and no-deposits just return '0' power
        if (hasCollnDepositBitmap == 0) return power;

        ITokenRegistry tokenRegistry = globalConfig.tokenRegistry();

        // This loop has max "O(n)" complexity where "n = TokensLength", but the loop
        // calculates borrow power only for the `hasCollnDepositBitmap` bit, hence the loop
        // iterates only till the highest bit set. Example 00000100, the loop will iterate
        // only for 4 times, and only 1 time to calculate borrow the power.
        // NOTE: When transaction gas-cost goes above the block gas limit, a user can
        //      disable some of his collaterals so that he can perform the borrow.
        //      Earlier loop implementation was iterating over all tokens, hence the platform
        //      were not able to add new tokens
        for (uint256 i = 0; i < 128; i++) {
            // if hasCollnDepositBitmap = 0000 then break the loop
            if (hasCollnDepositBitmap > 0) {
                // hasCollnDepositBitmap = 0100
                // mask                  = 0001
                // =============================== OP AND
                // result                = 0000
                bool isEnabled = (hasCollnDepositBitmap & uint128(1)) > 0;
                // Is i(th) token enabled?
                if (isEnabled) {
                    // continue calculating borrow power for i(th) token
                    (address token, uint256 divisor, uint256 price, uint256 borrowLTV) = tokenRegistry
                        .getTokenInfoFromIndex(i);

                    // avoid some gas consumption when borrowLTV == 0
                    if (borrowLTV != 0) {
                        uint256 depositBalanceCurrent = getDepositBalanceCurrent(token, _borrower);
                        power = power.add(depositBalanceCurrent.mul(price).mul(borrowLTV).div(100).div(divisor));
                    }
                }

                // right shift by 1
                // hasCollnDepositBitmap = 0100
                // BITWISE RIGHTSHIFT 1 on hasCollnDepositBitmap = 0010
                hasCollnDepositBitmap = hasCollnDepositBitmap >> 1;
                // continue loop and repeat the steps until `hasCollnDepositBitmap == 0`
            } else {
                break;
            }
        }

        return power;
    }

    function getCollateralETH(address _account) public view returns (uint256 collETH) {
        ITokenRegistry tokenRegistry = globalConfig.tokenRegistry();
        Account storage account = accounts[_account];
        uint128 hasDeposits = account.depositBitmap;
        for (uint8 i = 0; i < 128; i++) {
            if (hasDeposits > 0) {
                bool isEnabled = (hasDeposits & uint128(1)) > 0;
                if (isEnabled) {
                    (address token, uint256 divisor, uint256 price, uint256 borrowLTV) = tokenRegistry
                        .getTokenInfoFromIndex(i);
                    if (borrowLTV != 0) {
                        uint256 depositBalanceCurrent = getDepositBalanceCurrent(token, _account);
                        collETH = collETH.add(depositBalanceCurrent.mul(price).div(divisor));
                    }
                }
                hasDeposits = hasDeposits >> 1;
            } else {
                break;
            }
        }

        return collETH;
    }

    /**
     * Get current deposit balance of a token
     * @dev This is an estimation. Add a new checkpoint first, if you want to derive the exact balance.
     */
    function getDepositETH(address _accountAddr) public view returns (uint256 depositETH) {
        ITokenRegistry tokenRegistry = globalConfig.tokenRegistry();
        Account storage account = accounts[_accountAddr];
        uint128 hasDeposits = account.depositBitmap;
        for (uint8 i = 0; i < 128; i++) {
            if (hasDeposits > 0) {
                bool isEnabled = (hasDeposits & uint128(1)) > 0;
                if (isEnabled) {
                    (address token, uint256 divisor, uint256 price, ) = tokenRegistry.getTokenInfoFromIndex(i);

                    uint256 depositBalanceCurrent = getDepositBalanceCurrent(token, _accountAddr);
                    depositETH = depositETH.add(depositBalanceCurrent.mul(price).div(divisor));
                }
                hasDeposits = hasDeposits >> 1;
            } else {
                break;
            }
        }

        return depositETH;
    }

    /**
     * Get borrowed balance of a token in the uint256 of Wei
     */
    function getBorrowETH(address _accountAddr) public view returns (uint256 borrowETH) {
        ITokenRegistry tokenRegistry = globalConfig.tokenRegistry();
        Account storage account = accounts[_accountAddr];
        uint128 hasBorrows = account.borrowBitmap;
        for (uint8 i = 0; i < 128; i++) {
            if (hasBorrows > 0) {
                bool isEnabled = (hasBorrows & uint128(1)) > 0;
                if (isEnabled) {
                    (address token, uint256 divisor, uint256 price, ) = tokenRegistry.getTokenInfoFromIndex(i);

                    uint256 borrowBalanceCurrent = getBorrowBalanceCurrent(token, _accountAddr);
                    borrowETH = borrowETH.add(borrowBalanceCurrent.mul(price).div(divisor));
                }
                hasBorrows = hasBorrows >> 1;
            } else {
                break;
            }
        }

        return borrowETH;
    }

    /**
     * Check if the account is liquidatable
     * @param _borrower borrower's account
     * @return true if the account is liquidatable
     */
    function isAccountLiquidatable(address _borrower) public returns (bool) {
        ITokenRegistry tokenRegistry = globalConfig.tokenRegistry();
        IBank bank = globalConfig.bank();

        // Add new rate check points for all the collateral tokens from borrower in order to
        // have accurate calculation of liquidation oppotunites.
        Account storage account = accounts[_borrower];
        uint128 hasBorrowsOrDeposits = account.borrowBitmap | account.depositBitmap;
        for (uint8 i = 0; i < 128; i++) {
            if (hasBorrowsOrDeposits > 0) {
                bool isEnabled = (hasBorrowsOrDeposits & uint128(1)) > 0;
                if (isEnabled) {
                    address token = tokenRegistry.addressFromIndex(i);
                    bank.newRateIndexCheckpoint(token);
                }
                hasBorrowsOrDeposits = hasBorrowsOrDeposits >> 1;
            } else {
                break;
            }
        }

        uint256 liquidationThreshold = globalConfig.liquidationThreshold();

        uint256 totalBorrow = getBorrowETH(_borrower);
        uint256 totalCollateral = getCollateralETH(_borrower);

        // It is required that LTV is larger than LIQUIDATE_THREADHOLD for liquidation
        // return totalBorrow.mul(100) > totalCollateral.mul(liquidationThreshold);
        return totalBorrow.mul(100) > totalCollateral.mul(liquidationThreshold);
    }

    struct LiquidationVars {
        uint256 borrowerCollateralValue;
        uint256 targetTokenBalance;
        uint256 targetTokenBalanceBorrowed;
        uint256 targetTokenPrice;
        uint256 liquidationDiscountRatio;
        uint256 totalBorrow;
        uint256 borrowPower;
        uint256 liquidateTokenBalance;
        uint256 liquidateTokenPrice;
        uint256 limitRepaymentValue;
        uint256 borrowTokenLTV;
        uint256 repayAmount;
        uint256 payAmount;
    }

    function liquidate(
        address _liquidator,
        address _borrower,
        address _borrowedToken,
        address _collateralToken
    ) external onlyAuthorized returns (uint256, uint256) {
        initCollateralFlag(_liquidator);
        initCollateralFlag(_borrower);
        require(isAccountLiquidatable(_borrower), "borrower is not liquidatable");

        // It is required that the liquidator doesn't exceed it's borrow power.
        // if liquidator has any borrows, then only check for borrowPower condition
        Account storage liquidateAcc = accounts[_liquidator];
        if (liquidateAcc.borrowBitmap > 0) {
            require(getBorrowETH(_liquidator) < getBorrowPower(_liquidator), "No extra funds used for liquidation");
        }

        LiquidationVars memory vars;

        ITokenRegistry tokenRegistry = globalConfig.tokenRegistry();

        // _borrowedToken balance of the liquidator (deposit balance)
        vars.targetTokenBalance = getDepositBalanceCurrent(_borrowedToken, _liquidator);
        require(vars.targetTokenBalance > 0, "amount must be > 0");

        // _borrowedToken balance of the borrower (borrow balance)
        vars.targetTokenBalanceBorrowed = getBorrowBalanceCurrent(_borrowedToken, _borrower);
        require(vars.targetTokenBalanceBorrowed > 0, "borrower not own any debt token");

        // _borrowedToken available for liquidation
        uint256 borrowedTokenAmountForLiquidation = vars.targetTokenBalance.min(vars.targetTokenBalanceBorrowed);

        // _collateralToken balance of the borrower (deposit balance)
        vars.liquidateTokenBalance = getDepositBalanceCurrent(_collateralToken, _borrower);

        uint256 targetTokenDivisor;
        (, targetTokenDivisor, vars.targetTokenPrice, vars.borrowTokenLTV) = tokenRegistry.getTokenInfoFromAddress(
            _borrowedToken
        );

        uint256 liquidateTokendivisor;
        uint256 collateralLTV;
        (, liquidateTokendivisor, vars.liquidateTokenPrice, collateralLTV) = tokenRegistry.getTokenInfoFromAddress(
            _collateralToken
        );

        // _collateralToken to purchase so that borrower's balance matches its borrow power
        vars.totalBorrow = getBorrowETH(_borrower);
        vars.borrowPower = getBorrowPower(_borrower);
        vars.liquidationDiscountRatio = globalConfig.liquidationDiscountRatio();
        vars.limitRepaymentValue = vars.totalBorrow.sub(vars.borrowPower).mul(100).div(
            vars.liquidationDiscountRatio.sub(collateralLTV)
        );

        uint256 collateralTokenValueForLiquidation = vars.limitRepaymentValue.min(
            vars.liquidateTokenBalance.mul(vars.liquidateTokenPrice).div(liquidateTokendivisor)
        );

        uint256 liquidationValue = collateralTokenValueForLiquidation.min(
            borrowedTokenAmountForLiquidation.mul(vars.targetTokenPrice).mul(100).div(targetTokenDivisor).div(
                vars.liquidationDiscountRatio
            )
        );

        vars.repayAmount = liquidationValue.mul(vars.liquidationDiscountRatio).mul(targetTokenDivisor).div(100).div(
            vars.targetTokenPrice
        );
        vars.payAmount = vars.repayAmount.mul(liquidateTokendivisor).mul(100).mul(vars.targetTokenPrice);
        vars.payAmount = vars.payAmount.div(targetTokenDivisor).div(vars.liquidationDiscountRatio).div(
            vars.liquidateTokenPrice
        );

        deposit(_liquidator, _collateralToken, vars.payAmount);
        _withdrawLiquidate(_liquidator, _borrowedToken, vars.repayAmount);
        _withdrawLiquidate(_borrower, _collateralToken, vars.payAmount);
        repay(_borrower, _borrowedToken, vars.repayAmount);

        return (vars.repayAmount, vars.payAmount);
    }

    /**
     * Get current block number
     * @return the current block number
     */
    function getBlockNumber() private view returns (uint256) {
        return block.number;
    }

    /**
     * An account claim all mined FIN token.
     * @dev If the FIN mining index point doesn't exist, we have to calculate the FIN amount
     * accurately. So the user can withdraw all available FIN tokens.
     */
    function claim(address _account) public onlyAuthorized returns (uint256) {
        ITokenRegistry tokenRegistry = globalConfig.tokenRegistry();
        IBank bank = globalConfig.bank();

        uint256 currentBlock = getBlockNumber();

        Account storage account = accounts[_account];
        uint128 depositBitmap = account.depositBitmap;
        uint128 borrowBitmap = account.borrowBitmap;
        uint128 hasDepositOrBorrow = depositBitmap | borrowBitmap;

        for (uint8 i = 0; i < 128; i++) {
            if (hasDepositOrBorrow > 0) {
                if ((hasDepositOrBorrow & uint128(1)) > 0) {
                    address token = tokenRegistry.addressFromIndex(i);
                    AccountTokenLib.TokenInfo storage tokenInfo = accounts[_account].tokenInfos[token];
                    bank.updateMining(token);
                    if (depositBitmap.isBitSet(i)) {
                        bank.updateDepositFINIndex(token);
                        uint256 lastDepositBlock = tokenInfo.getLastDepositBlock();
                        calculateDepositFIN(lastDepositBlock, token, _account, currentBlock);
                        tokenInfo.deposit(0, bank.getDepositAccruedRate(token, lastDepositBlock), currentBlock);
                    }

                    if (borrowBitmap.isBitSet(i)) {
                        bank.updateBorrowFINIndex(token);
                        uint256 lastBorrowBlock = tokenInfo.getLastBorrowBlock();
                        calculateBorrowFIN(lastBorrowBlock, token, _account, currentBlock);
                        tokenInfo.borrow(0, bank.getBorrowAccruedRate(token, lastBorrowBlock), currentBlock);
                    }
                }
                hasDepositOrBorrow = hasDepositOrBorrow >> 1;
            } else {
                break;
            }
        }

        uint256 _finAmount = finAmount[_account];
        finAmount[_account] = 0;
        return _finAmount;
    }

    function claimForToken(address _account, address _token) public onlyAuthorized returns (uint256) {
        Account storage account = accounts[_account];
        uint8 index = globalConfig.tokenRegistry().getTokenIndex(_token);
        bool isDeposit = account.depositBitmap.isBitSet(index);
        bool isBorrow = account.borrowBitmap.isBitSet(index);
        if (!(isDeposit || isBorrow)) return 0;

        IBank bank = globalConfig.bank();
        uint256 currentBlock = getBlockNumber();

        AccountTokenLib.TokenInfo storage tokenInfo = accounts[_account].tokenInfos[_token];
        bank.updateMining(_token);

        if (isDeposit) {
            bank.updateDepositFINIndex(_token);
            uint256 lastDepositBlock = tokenInfo.getLastDepositBlock();
            calculateDepositFIN(lastDepositBlock, _token, _account, currentBlock);
            tokenInfo.deposit(0, bank.getDepositAccruedRate(_token, lastDepositBlock), currentBlock);
        }
        if (isBorrow) {
            bank.updateBorrowFINIndex(_token);
            uint256 lastBorrowBlock = tokenInfo.getLastBorrowBlock();
            calculateBorrowFIN(lastBorrowBlock, _token, _account, currentBlock);
            tokenInfo.borrow(0, bank.getBorrowAccruedRate(_token, lastBorrowBlock), currentBlock);
        }

        uint256 _finAmount = finAmount[_account];
        finAmount[_account] = 0;
        return _finAmount;
    }

    /**
     * Accumulate the amount FIN mined by depositing between _lastBlock and _currentBlock
     */
    function calculateDepositFIN(
        uint256 _lastBlock,
        address _token,
        address _accountAddr,
        uint256 _currentBlock
    ) internal {
        IBank bank = globalConfig.bank();

        uint256 indexDifference = bank.depositFINRateIndex(_token, _currentBlock).sub(
            bank.depositFINRateIndex(_token, _lastBlock)
        );
        uint256 getFIN = getDepositBalanceCurrent(_token, _accountAddr).mul(indexDifference).div(
            bank.depositeRateIndex(_token, _currentBlock)
        );
        finAmount[_accountAddr] = finAmount[_accountAddr].add(getFIN);
    }

    /**
     * Accumulate the amount FIN mined by borrowing between _lastBlock and _currentBlock
     */
    function calculateBorrowFIN(
        uint256 _lastBlock,
        address _token,
        address _accountAddr,
        uint256 _currentBlock
    ) internal {
        IBank bank = globalConfig.bank();

        uint256 indexDifference = bank.borrowFINRateIndex(_token, _currentBlock).sub(
            bank.borrowFINRateIndex(_token, _lastBlock)
        );
        uint256 getFIN = getBorrowBalanceCurrent(_token, _accountAddr).mul(indexDifference).div(
            bank.borrowRateIndex(_token, _currentBlock)
        );
        finAmount[_accountAddr] = finAmount[_accountAddr].add(getFIN);
    }

    function version() public pure returns (string memory) {
        return "v2.0.0";
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.4;

// NOTICE: using SafeMath as the code is copied from Savings (old solidity v0.5.16) and
// wants to avoid a lot of changes in the contract code.
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// This is for per user
library AccountTokenLib {
    using SafeMath for uint256;
    struct TokenInfo {
        // Deposit info
        uint256 depositPrincipal; // total deposit principal of ther user
        uint256 depositInterest; // total deposit interest of the user
        uint256 lastDepositBlock; // the block number of user's last deposit
        // Borrow info
        uint256 borrowPrincipal; // total borrow principal of ther user
        uint256 borrowInterest; // total borrow interest of ther user
        uint256 lastBorrowBlock; // the block number of user's last borrow
    }

    uint256 internal constant BASE = 10**18;

    // returns the principal
    function getDepositPrincipal(TokenInfo storage self) public view returns (uint256) {
        return self.depositPrincipal;
    }

    function getBorrowPrincipal(TokenInfo storage self) public view returns (uint256) {
        return self.borrowPrincipal;
    }

    function getDepositBalance(TokenInfo storage self, uint256 accruedRate) public view returns (uint256) {
        return self.depositPrincipal.add(calculateDepositInterest(self, accruedRate));
    }

    function getBorrowBalance(TokenInfo storage self, uint256 accruedRate) public view returns (uint256) {
        return self.borrowPrincipal.add(calculateBorrowInterest(self, accruedRate));
    }

    function getLastDepositBlock(TokenInfo storage self) public view returns (uint256) {
        return self.lastDepositBlock;
    }

    function getLastBorrowBlock(TokenInfo storage self) public view returns (uint256) {
        return self.lastBorrowBlock;
    }

    function getDepositInterest(TokenInfo storage self) public view returns (uint256) {
        return self.depositInterest;
    }

    function getBorrowInterest(TokenInfo storage self) public view returns (uint256) {
        return self.borrowInterest;
    }

    function borrow(
        TokenInfo storage self,
        uint256 amount,
        uint256 accruedRate,
        uint256 _block
    ) public {
        newBorrowCheckpoint(self, accruedRate, _block);
        self.borrowPrincipal = self.borrowPrincipal.add(amount);
    }

    /**
     * Update token info for withdraw. The interest will be withdrawn with higher priority.
     */
    function withdraw(
        TokenInfo storage self,
        uint256 amount,
        uint256 accruedRate,
        uint256 _block
    ) public {
        newDepositCheckpoint(self, accruedRate, _block);
        if (self.depositInterest >= amount) {
            self.depositInterest = self.depositInterest.sub(amount);
        } else if (self.depositPrincipal.add(self.depositInterest) >= amount) {
            self.depositPrincipal = self.depositPrincipal.sub(amount.sub(self.depositInterest));
            self.depositInterest = 0;
        } else {
            self.depositPrincipal = 0;
            self.depositInterest = 0;
        }
    }

    /**
     * Update token info for deposit
     */
    function deposit(
        TokenInfo storage self,
        uint256 amount,
        uint256 accruedRate,
        uint256 _block
    ) public {
        newDepositCheckpoint(self, accruedRate, _block);
        self.depositPrincipal = self.depositPrincipal.add(amount);
    }

    function repay(
        TokenInfo storage self,
        uint256 amount,
        uint256 accruedRate,
        uint256 _block
    ) public {
        // updated rate (new index rate), applying the rate from startBlock(checkpoint) to currBlock
        newBorrowCheckpoint(self, accruedRate, _block);
        // user owes money, then he tries to repays
        if (self.borrowInterest > amount) {
            self.borrowInterest = self.borrowInterest.sub(amount);
        } else if (self.borrowPrincipal.add(self.borrowInterest) > amount) {
            self.borrowPrincipal = self.borrowPrincipal.sub(amount.sub(self.borrowInterest));
            self.borrowInterest = 0;
        } else {
            self.borrowPrincipal = 0;
            self.borrowInterest = 0;
        }
    }

    function newDepositCheckpoint(
        TokenInfo storage self,
        uint256 accruedRate,
        uint256 _block
    ) public {
        self.depositInterest = calculateDepositInterest(self, accruedRate);
        self.lastDepositBlock = _block;
    }

    function newBorrowCheckpoint(
        TokenInfo storage self,
        uint256 accruedRate,
        uint256 _block
    ) public {
        self.borrowInterest = calculateBorrowInterest(self, accruedRate);
        self.lastBorrowBlock = _block;
    }

    // Calculating interest according to the new rate
    // calculated starting from last deposit checkpoint
    function calculateDepositInterest(TokenInfo storage self, uint256 accruedRate) public view returns (uint256) {
        return
            self.depositPrincipal.add(self.depositInterest).mul(accruedRate).sub(self.depositPrincipal.mul(BASE)).div(
                BASE
            );
    }

    function calculateBorrowInterest(TokenInfo storage self, uint256 accruedRate) public view returns (uint256) {
        uint256 _balance = self.borrowPrincipal;
        if (accruedRate == 0 || _balance == 0 || BASE >= accruedRate) {
            return self.borrowInterest;
        } else {
            return _balance.add(self.borrowInterest).mul(accruedRate).sub(_balance.mul(BASE)).div(BASE);
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.4;

/**
 * @notice Bitmap library to set or unset bits on bitmap value
 */
library BitmapLib {
    /**
     * @dev Sets the given bit in the bitmap value
     * @param _bitmap Bitmap value to update the bit in
     * @param _index Index range from 0 to 127
     * @return Returns the updated bitmap value
     */
    function setBit(uint128 _bitmap, uint8 _index) internal pure returns (uint128) {
        // Suppose `_bitmap` is in bit value:
        // 0001 0100 = represents third(_index == 2) and fifth(_index == 4) bit is set

        // Bit not set, hence, set the bit
        if (!isBitSet(_bitmap, _index)) {
            // Suppose `_index` is = 3 = 4th bit
            // mask = 0000 1000 = Left shift to create mask to find 4rd bit status
            uint128 mask = uint128(1) << _index;

            // Setting the corrospending bit in _bitmap
            // Performing OR (|) operation
            // 0001 0100 (_bitmap)
            // 0000 1000 (mask)
            // -------------------
            // 0001 1100 (result)
            return _bitmap | mask;
        }

        // Bit already set, just return without any change
        return _bitmap;
    }

    /**
     * @dev Unsets the bit in given bitmap
     * @param _bitmap Bitmap value to update the bit in
     * @param _index Index range from 0 to 127
     * @return Returns the updated bitmap value
     */
    function unsetBit(uint128 _bitmap, uint8 _index) internal pure returns (uint128) {
        // Suppose `_bitmap` is in bit value:
        // 0001 0100 = represents third(_index == 2) and fifth(_index == 4) bit is set

        // Bit is set, hence, unset the bit
        if (isBitSet(_bitmap, _index)) {
            // Suppose `_index` is = 2 = 3th bit
            // mask = 0000 0100 = Left shift to create mask to find 3rd bit status
            uint128 mask = uint128(1) << _index;

            // Performing Bitwise NOT(~) operation
            // 1111 1011 (mask)
            mask = ~mask;

            // Unsetting the corrospending bit in _bitmap
            // Performing AND (&) operation
            // 0001 0100 (_bitmap)
            // 1111 1011 (mask)
            // -------------------
            // 0001 0000 (result)
            return _bitmap & mask;
        }

        // Bit not set, just return without any change
        return _bitmap;
    }

    /**
     * @dev Returns true if the corrosponding bit set in the bitmap
     * @param _bitmap Bitmap value to check
     * @param _index Index to check. Index range from 0 to 127
     * @return Returns true if bit is set, false otherwise
     */
    function isBitSet(uint128 _bitmap, uint8 _index) internal pure returns (bool) {
        require(_index < 128, "Index out of range for bit operation");
        // Suppose `_bitmap` is in bit value:
        // 0001 0100 = represents third(_index == 2) and fifth(_index == 4) bit is set

        // Suppose `_index` is = 2 = 3th bit
        // 0000 0100 = Left shift to create mask to find 3rd bit status
        uint128 mask = uint128(1) << _index;

        // Example: When bit is set:
        // Performing AND (&) operation
        // 0001 0100 (_bitmap)
        // 0000 0100 (mask)
        // -------------------------
        // 0000 0100 (bitSet > 0)

        // Example: When bit is not set:
        // Performing AND (&) operation
        // 0001 0100 (_bitmap)
        // 0000 1000 (mask)
        // -------------------------
        // 0000 0000 (bitSet == 0)

        uint128 bitSet = _bitmap & mask;
        // Bit is set when greater than zero, else not set
        return bitSet > 0;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.4;

enum ActionType {
    DepositAction,
    WithdrawAction,
    BorrowAction,
    RepayAction,
    LiquidateRepayAction
}

abstract contract Constant {
    address public constant ETH_ADDR = 0x000000000000000000000000000000000000000E;
    uint256 public constant INT_UNIT = 10**uint256(18);
    uint256 public constant ACCURACY = 10**uint256(18);
}

/**
 * @dev Only some of the contracts uses BLOCKS_PER_YEAR in their code.
 * Hence, only those contracts would have to inherit from BPYConstant.
 * This is done to minimize the argument passing from other contracts.
 */
abstract contract BPYConstant is Constant {
    // solhint-disable-next-line var-name-mixedcase
    uint256 public immutable BLOCKS_PER_YEAR;

    constructor(uint256 _blocksPerYear) {
        BLOCKS_PER_YEAR = _blocksPerYear;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.4;

import "./ITokenRegistry.sol";
import "./IBank.sol";
import "./ISavingAccount.sol";
import "./IAccounts.sol";
import "./IConstant.sol";

interface IGlobalConfig {
    function initialize(
        address _gemGlobalConfig,
        address _bank,
        address _savingAccount,
        address _tokenRegistry,
        address _accounts,
        address _poolRegistry
    ) external;

    function tokenRegistry() external view returns (ITokenRegistry);

    function chainLink() external view returns (address);

    function bank() external view returns (IBank);

    function savingAccount() external view returns (ISavingAccount);

    function accounts() external view returns (IAccounts);

    function maxReserveRatio() external view returns (uint256);

    function midReserveRatio() external view returns (uint256);

    function minReserveRatio() external view returns (uint256);

    function rateCurveConstant() external view returns (uint256);

    function compoundSupplyRateWeights() external view returns (uint256);

    function compoundBorrowRateWeights() external view returns (uint256);

    function deFinerRate() external view returns (uint256);

    function liquidationThreshold() external view returns (uint256);

    function liquidationDiscountRatio() external view returns (uint256);

    function governor() external view returns (address);

    function updateMinMaxBorrowAPR(uint256 _minBorrowAPRInPercent, uint256 _maxBorrowAPRInPercent) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.4;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorInterface.sol";

interface IGemGlobalConfig {
    function initialize(
        address _finToken,
        address _governor,
        address _definerAdmin,
        address payable _deFinerCommunityFund,
        uint256 _poolCreationFeeInUSD8,
        AggregatorInterface _nativeTokenOracleForPriceInUSD8
    ) external;

    function finToken() external view returns (address);

    function governor() external view returns (address);

    function definerAdmin() external view returns (address);

    function nativeTokenOracleForPriceInUSD8() external view returns (address);

    function deFinerCommunityFund() external view returns (address payable);

    function getPoolCreationFeeInNative() external view returns (uint256);

    function getNativeTokenPriceInUSD8() external view returns (int256);

    function nativeTokenPriceOracleInUSD8() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
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
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.4;

interface ITokenRegistry {
    function initialize(
        address _gemGlobalConfig,
        address _poolRegistry,
        address _globalConfig
    ) external;

    function tokenInfo(address _token)
        external
        view
        returns (
            uint8 index,
            uint8 decimals,
            bool enabled,
            bool _isSupportedOnCompound, // compiler warning
            address cToken,
            address chainLinkOracle,
            uint256 borrowLTV
        );

    function addTokenByPoolRegistry(
        address _token,
        bool _isSupportedOnCompound,
        address _cToken,
        address _chainLinkOracle,
        uint256 _borrowLTV
    ) external;

    function getTokenDecimals(address) external view returns (uint8);

    function getCToken(address) external view returns (address);

    function getCTokens() external view returns (address[] calldata);

    function depositeMiningSpeeds(address _token) external view returns (uint256);

    function borrowMiningSpeeds(address _token) external view returns (uint256);

    function isSupportedOnCompound(address) external view returns (bool);

    function getTokens() external view returns (address[] calldata);

    function getTokenInfoFromAddress(address _token)
        external
        view
        returns (
            uint8,
            uint256,
            uint256,
            uint256
        );

    function getTokenInfoFromIndex(uint256 index)
        external
        view
        returns (
            address,
            uint256,
            uint256,
            uint256
        );

    function getTokenIndex(address _token) external view returns (uint8);

    function addressFromIndex(uint256 index) external view returns (address);

    function isTokenExist(address _token) external view returns (bool isExist);

    function isTokenEnabled(address _token) external view returns (bool);

    function priceFromAddress(address _token) external view returns (uint256);

    function updateMiningSpeed(
        address _token,
        uint256 _depositeMiningSpeed,
        uint256 _borrowMiningSpeed
    ) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.4;

import { ActionType } from "../config/Constant.sol";

interface IBank {
    /* solhint-disable func-name-mixedcase */
    function BLOCKS_PER_YEAR() external view returns (uint256);

    function initialize(address _globalConfig, address _poolRegistry) external;

    function newRateIndexCheckpoint(address) external;

    function deposit(
        address _to,
        address _token,
        uint256 _amount
    ) external;

    function withdraw(
        address _from,
        address _token,
        uint256 _amount
    ) external returns (uint256);

    function borrow(
        address _from,
        address _token,
        uint256 _amount
    ) external;

    function repay(
        address _to,
        address _token,
        uint256 _amount
    ) external returns (uint256);

    function getDepositAccruedRate(address _token, uint256 _depositRateRecordStart) external view returns (uint256);

    function getBorrowAccruedRate(address _token, uint256 _borrowRateRecordStart) external view returns (uint256);

    function depositeRateIndex(address _token, uint256 _blockNum) external view returns (uint256);

    function borrowRateIndex(address _token, uint256 _blockNum) external view returns (uint256);

    function depositeRateIndexNow(address _token) external view returns (uint256);

    function borrowRateIndexNow(address _token) external view returns (uint256);

    function updateMining(address _token) external;

    function updateDepositFINIndex(address _token) external;

    function updateBorrowFINIndex(address _token) external;

    function update(
        address _token,
        uint256 _amount,
        ActionType _action
    ) external returns (uint256 compoundAmount);

    function depositFINRateIndex(address, uint256) external view returns (uint256);

    function borrowFINRateIndex(address, uint256) external view returns (uint256);

    function getTotalDepositStore(address _token) external view returns (uint256);

    function totalLoans(address _token) external view returns (uint256);

    function totalReserve(address _token) external view returns (uint256);

    function totalCompound(address _token) external view returns (uint256);

    function getBorrowRatePerBlock(address _token) external view returns (uint256);

    function getDepositRatePerBlock(address _token) external view returns (uint256);

    function getTokenState(address _token)
        external
        view
        returns (
            uint256 deposits,
            uint256 loans,
            uint256 reserveBalance,
            uint256 remainingAssets
        );

    function configureMaxUtilToCalcBorrowAPR(uint256 _maxBorrowAPR) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.4;

interface ISavingAccount {
    function initialize(
        address[] memory _tokenAddresses,
        address[] memory _cTokenAddresses,
        address _globalConfig,
        address _poolRegistry,
        uint256 _poolId
    ) external;

    function configure(
        address _baseToken,
        address _miningToken,
        uint256 _maturesOn
    ) external;

    function toCompound(address, uint256) external;

    function fromCompound(address, uint256) external;

    function approveAll(address _token) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.4;

interface IAccounts {
    function initialize(address _globalConfig, address _gemGlobalConfig) external;

    function deposit(
        address,
        address,
        uint256
    ) external;

    function borrow(
        address,
        address,
        uint256
    ) external;

    function getBorrowPrincipal(address, address) external view returns (uint256);

    function withdraw(
        address,
        address,
        uint256
    ) external returns (uint256);

    function repay(
        address,
        address,
        uint256
    ) external returns (uint256);

    function getDepositPrincipal(address _accountAddr, address _token) external view returns (uint256);

    function getDepositBalanceCurrent(address _token, address _accountAddr) external view returns (uint256);

    function getDepositInterest(address _account, address _token) external view returns (uint256);

    function getBorrowInterest(address _accountAddr, address _token) external view returns (uint256);

    function getBorrowBalanceCurrent(address _token, address _accountAddr)
        external
        view
        returns (uint256 borrowBalance);

    function getBorrowETH(address _accountAddr) external view returns (uint256 borrowETH);

    function getDepositETH(address _accountAddr) external view returns (uint256 depositETH);

    function getBorrowPower(address _borrower) external view returns (uint256 power);

    function liquidate(
        address _liquidator,
        address _borrower,
        address _borrowedToken,
        address _collateralToken
    ) external returns (uint256, uint256);

    function claim(address _account) external returns (uint256);

    function claimForToken(address _account, address _token) external returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.4;

/* solhint-disable */
interface IConstant {
    function ETH_ADDR() external view returns (address);

    function INT_UNIT() external view returns (uint256);

    function ACCURACY() external view returns (uint256);

    function BLOCKS_PER_YEAR() external view returns (uint256);
}
/* solhint-enable */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorInterface {
  function latestAnswer() external view returns (int256);

  function latestTimestamp() external view returns (uint256);

  function latestRound() external view returns (uint256);

  function getAnswer(uint256 roundId) external view returns (int256);

  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);

  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
}