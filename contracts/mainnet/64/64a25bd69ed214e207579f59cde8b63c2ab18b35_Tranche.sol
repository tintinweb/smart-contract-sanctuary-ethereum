// SPDX-License-Identifier: AGPL-3.0-only
// Copyright (C) Centrifuge 2020, based on MakerDAO dss https://github.com/makerdao/dss
pragma solidity >=0.5.15;

contract Auth {
    mapping (address => uint256) public wards;
    
    event Rely(address indexed usr);
    event Deny(address indexed usr);

    function rely(address usr) external auth {
        wards[usr] = 1;
        emit Rely(usr);
    }
    function deny(address usr) external auth {
        wards[usr] = 0;
        emit Deny(usr);
    }

    modifier auth {
        require(wards[msg.sender] == 1, "not-authorized");
        _;
    }

}

// SPDX-License-Identifier: AGPL-3.0-only
// Copyright (C) 2018 Rain <[email protected]>
pragma solidity >=0.5.15;

contract Math {
    uint256 constant ONE = 10 ** 27;

    function safeAdd(uint x, uint y) public pure returns (uint z) {
        require((z = x + y) >= x, "safe-add-failed");
    }

    function safeSub(uint x, uint y) public pure returns (uint z) {
        require((z = x - y) <= x, "safe-sub-failed");
    }

    function safeMul(uint x, uint y) public pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "safe-mul-failed");
    }

    function safeDiv(uint x, uint y) public pure returns (uint z) {
        z = x / y;
    }

    function rmul(uint x, uint y) public pure returns (uint z) {
        z = safeMul(x, y) / ONE;
    }

    function rdiv(uint x, uint y) public pure returns (uint z) {
        require(y > 0, "division by zero");
        z = safeAdd(safeMul(x, ONE), y / 2) / y;
    }

    function rdivup(uint x, uint y) internal pure returns (uint z) {
        require(y > 0, "division by zero");
        // always rounds up
        z = safeAdd(safeMul(x, ONE), safeSub(y, 1)) / y;
    }


}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.6;

/// @notice abstract contract for FixedPoint math operations
/// defining ONE with 10^27 precision
abstract contract FixedPoint {
    struct Fixed27 {
        uint256 value;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.6;

import "tinlake-auth/auth.sol";
import "tinlake-math/math.sol";
import "./../fixed_point.sol";

interface ERC20Like {
    function balanceOf(address) external view returns (uint256);
    function transferFrom(address, address, uint256) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
    function mint(address, uint256) external;
    function burn(address, uint256) external;
    function totalSupply() external view returns (uint256);
    function approve(address usr, uint256 amount) external;
}

interface ReserveLike {
    function deposit(uint256 amount) external;
    function payout(uint256 amount) external;
    function totalBalanceAvailable() external returns (uint256);
}

interface CoordinatorLike {
    function currentEpoch() external view returns (uint256);
    function lastEpochExecuted() external view returns (uint256);
}

/// @notice Tranche contract which manages investments into a tranche of a pool
contract Tranche is Math, Auth, FixedPoint {
    mapping(uint256 => Epoch) public epochs;

    struct Epoch {
        // denominated in 10^27
        // percentage ONE == 100%
        uint256 redeemFulfillment;
        // denominated in 10^27
        // percentage ONE == 100%
        uint256 supplyFulfillment;
        // tokenPrice after end of epoch
        uint256 tokenPrice;
    }

    struct UserOrder {
        uint256 orderedInEpoch;
        uint256 supplyCurrencyAmount;
        uint256 redeemTokenAmount;
    }

    mapping(address => UserOrder) public users;

    uint256 public totalSupply;
    uint256 public totalRedeem;

    ERC20Like public currency;
    ERC20Like public token;
    ReserveLike public reserve;
    CoordinatorLike public coordinator;

    // additional requested currency if the reserve could not fulfill a tranche request
    uint256 public requestedCurrency;

    bool public waitingForUpdate = false;

    event Depend(bytes32 indexed contractName, address addr);
    event Mint(address indexed usr, uint256 amount);
    event Burn(address indexed usr, uint256 amount);
    event AuthTransfer(address indexed erc20, address usr, uint256 amount);

    modifier orderAllowed(address usr) {
        require(
            (users[usr].supplyCurrencyAmount == 0 && users[usr].redeemTokenAmount == 0)
                || users[usr].orderedInEpoch == coordinator.currentEpoch(),
            "disburse required"
        );
        _;
    }

    constructor(address currency_, address token_) {
        token = ERC20Like(token_);
        currency = ERC20Like(currency_);
        wards[msg.sender] = 1;
        emit Rely(msg.sender);
    }

    /// @notice sets the dependencies of the contract
    /// @param contractName which contract to set
    /// @param addr contract address
    function depend(bytes32 contractName, address addr) public auth {
        if (contractName == "token") token = ERC20Like(addr);
        else if (contractName == "currency") currency = ERC20Like(addr);
        else if (contractName == "reserve") reserve = ReserveLike(addr);
        else if (contractName == "coordinator") coordinator = CoordinatorLike(addr);
        else revert();
        emit Depend(contractName, addr);
    }

    /// @notice returns the currency balance of the tranche
    /// @return balance_ currency balance of the tranche
    function balance() external view returns (uint256 balance_) {
        return currency.balanceOf(address(this));
    }

    /// @notice returns total supply of tokens issued by the tranche
    /// @return totalSupply_ total supply of tokens
    function tokenSupply() external view returns (uint256 totalSupply_) {
        return token.totalSupply();
    }

    /// @notice supplyOrder function can be used to place or revoke a supply
    /// @param usr user address for which the currency should be taken or sent
    /// @param newSupplyAmount new amount of currency to be supplied
    function supplyOrder(address usr, uint256 newSupplyAmount) public auth orderAllowed(usr) {
        users[usr].orderedInEpoch = coordinator.currentEpoch();

        uint256 currentSupplyAmount = users[usr].supplyCurrencyAmount;

        users[usr].supplyCurrencyAmount = newSupplyAmount;

        totalSupply = safeAdd(_safeTotalSub(totalSupply, currentSupplyAmount), newSupplyAmount);

        uint256 delta;
        if (newSupplyAmount > currentSupplyAmount) {
            delta = safeSub(newSupplyAmount, currentSupplyAmount);
            require(currency.transferFrom(usr, address(this), delta), "currency-transfer-failed");
            return;
        }
        delta = safeSub(currentSupplyAmount, newSupplyAmount);
        if (delta > 0) {
            _safeTransfer(currency, usr, delta);
        }
    }

    /// @notice redeemOrder function can be used to place or revoke a redeem
    /// @param usr user address for which the tokens should be taken or sent
    /// @param newRedeemAmount new amount of tokens to be redeemed
    function redeemOrder(address usr, uint256 newRedeemAmount) public auth orderAllowed(usr) {
        users[usr].orderedInEpoch = coordinator.currentEpoch();

        uint256 currentRedeemAmount = users[usr].redeemTokenAmount;
        users[usr].redeemTokenAmount = newRedeemAmount;
        totalRedeem = safeAdd(_safeTotalSub(totalRedeem, currentRedeemAmount), newRedeemAmount);

        uint256 delta;
        if (newRedeemAmount > currentRedeemAmount) {
            delta = safeSub(newRedeemAmount, currentRedeemAmount);
            require(token.transferFrom(usr, address(this), delta), "token-transfer-failed");
            return;
        }

        delta = safeSub(currentRedeemAmount, newRedeemAmount);
        if (delta > 0) {
            _safeTransfer(token, usr, delta);
        }
    }

    /// @notice view function to calculate the current disburse amount for a user
    /// a disburse is the fulfillment of a supply or redeem order
    /// a order can be fulfilled fully or partially
    /// @param usr user address for which the disburse amount should be calculated
    /// @return payoutCurrencyAmount amount of currency tokens which has been paid out
    /// @return payoutTokenAmount amount of token which has been paid out
    /// @return remainingSupplyCurrency amount of currency which has been left in the pool
    /// @return remainingRedeemToken amount of token which has been left in the pool
    function calcDisburse(address usr)
        public
        view
        returns (
            uint256 payoutCurrencyAmount,
            uint256 payoutTokenAmount,
            uint256 remainingSupplyCurrency,
            uint256 remainingRedeemToken
        )
    {
        return calcDisburse(usr, coordinator.lastEpochExecuted());
    }

    /// @notice calculates the current disburse of a user starting from the ordered epoch until endEpoch
    /// @param usr user address for which the disburse amount should be calculated
    /// @param endEpoch epoch until which the disburse should be calculated
    /// @return payoutCurrencyAmount amount of currency tokens which has been paid out
    /// @return payoutTokenAmount amount of token which has been paid out
    /// @return remainingSupplyCurrency amount of currency which has been left in the pool
    /// @return remainingRedeemToken amount of token which has been left in the pool
    function calcDisburse(address usr, uint256 endEpoch)
        public
        view
        returns (
            uint256 payoutCurrencyAmount,
            uint256 payoutTokenAmount,
            uint256 remainingSupplyCurrency,
            uint256 remainingRedeemToken
        )
    {
        uint256 epochIdx = users[usr].orderedInEpoch;
        uint256 lastEpochExecuted = coordinator.lastEpochExecuted();

        // no disburse possible in this epoch
        if (users[usr].orderedInEpoch == coordinator.currentEpoch()) {
            return
                (payoutCurrencyAmount, payoutTokenAmount, users[usr].supplyCurrencyAmount, users[usr].redeemTokenAmount);
        }

        if (endEpoch > lastEpochExecuted) {
            // it is only possible to disburse epochs which are already over
            endEpoch = lastEpochExecuted;
        }

        remainingSupplyCurrency = users[usr].supplyCurrencyAmount;
        remainingRedeemToken = users[usr].redeemTokenAmount;
        uint256 amount = 0;

        // calculates disburse amounts as long as remaining tokens or currency is left or the end epoch is reached
        while (epochIdx <= endEpoch && (remainingSupplyCurrency != 0 || remainingRedeemToken != 0)) {
            if (remainingSupplyCurrency != 0) {
                amount = rmul(remainingSupplyCurrency, epochs[epochIdx].supplyFulfillment);
                // supply currency payout in token
                if (amount != 0) {
                    payoutTokenAmount =
                        safeAdd(payoutTokenAmount, safeDiv(safeMul(amount, ONE), epochs[epochIdx].tokenPrice));
                    remainingSupplyCurrency = safeSub(remainingSupplyCurrency, amount);
                }
            }

            if (remainingRedeemToken != 0) {
                amount = rmul(remainingRedeemToken, epochs[epochIdx].redeemFulfillment);
                // redeem token payout in currency
                if (amount != 0) {
                    payoutCurrencyAmount = safeAdd(payoutCurrencyAmount, rmul(amount, epochs[epochIdx].tokenPrice));
                    remainingRedeemToken = safeSub(remainingRedeemToken, amount);
                }
            }
            epochIdx = safeAdd(epochIdx, 1);
        }

        return (payoutCurrencyAmount, payoutTokenAmount, remainingSupplyCurrency, remainingRedeemToken);
    }

    /// @notice the disburse function can be used after an epoch is over to receive currency and tokens
    /// @param usr user address for which the disburse amount should be calculated
    /// @return payoutCurrencyAmount amount of currency tokens which has been paid out
    /// @return payoutTokenAmount amount of token which has been paid out
    /// @return remainingSupplyCurrency amount of currency which has been left in the pool
    /// @return remainingRedeemToken amount of token which has been left in the pool
    function disburse(address usr)
        public
        auth
        returns (
            uint256 payoutCurrencyAmount,
            uint256 payoutTokenAmount,
            uint256 remainingSupplyCurrency,
            uint256 remainingRedeemToken
        )
    {
        return disburse(usr, coordinator.lastEpochExecuted());
    }

    /// @notice internal helper function to transfer tokens
    /// @dev if the amount is higher than the balance of the contract, there is no revert
    /// instead the the maximum amount possible is transferred
    /// @param erc20 token address
    /// @param usr user address for which the tokens should be transferred
    /// @param amount amount of tokens which should be transferred
    /// @return amountTransfered acutual amount transferred
    function _safeTransfer(ERC20Like erc20, address usr, uint256 amount) internal returns (uint256 amountTransfered) {
        uint256 max = erc20.balanceOf(address(this));
        if (amount > max) {
            amount = max;
        }
        require(erc20.transfer(usr, amount), "token-transfer-failed");
        return amount;
    }

    /// @notice the disburse function can be used after an epoch is over to receive currency and tokens
    /// @param usr user address for which the disburse amount should be calculated
    /// @param endEpoch epoch until which the disburse should be calculated
    /// @return payoutCurrencyAmount amount of currency tokens which has been paid out
    /// @return payoutTokenAmount amount of token which has been paid out
    /// @return remainingSupplyCurrency amount of currency which has been left in the pool
    /// @return remainingRedeemToken amount of token which has been left in the pool
    function disburse(address usr, uint256 endEpoch)
        public
        auth
        returns (
            uint256 payoutCurrencyAmount,
            uint256 payoutTokenAmount,
            uint256 remainingSupplyCurrency,
            uint256 remainingRedeemToken
        )
    {
        require(users[usr].orderedInEpoch <= coordinator.lastEpochExecuted(), "epoch-not-executed-yet");

        uint256 lastEpochExecuted = coordinator.lastEpochExecuted();

        if (endEpoch > lastEpochExecuted) {
            // it is only possible to disburse epochs which are already over
            endEpoch = lastEpochExecuted;
        }

        (payoutCurrencyAmount, payoutTokenAmount, remainingSupplyCurrency, remainingRedeemToken) =
            calcDisburse(usr, endEpoch);
        users[usr].supplyCurrencyAmount = remainingSupplyCurrency;
        users[usr].redeemTokenAmount = remainingRedeemToken;
        // if lastEpochExecuted is disbursed, orderInEpoch is at the current epoch again
        // which allows to change the order. This is only possible if all previous epochs are disbursed
        users[usr].orderedInEpoch = safeAdd(endEpoch, 1);

        if (payoutCurrencyAmount > 0) {
            payoutCurrencyAmount = _safeTransfer(currency, usr, payoutCurrencyAmount);
        }

        if (payoutTokenAmount > 0) {
            payoutTokenAmount = _safeTransfer(token, usr, payoutTokenAmount);
        }
        return (payoutCurrencyAmount, payoutTokenAmount, remainingSupplyCurrency, remainingRedeemToken);
    }

    /// @notice called by epoch coordinator in epoch execute method
    /// @param epochID id of the epoch which is executed
    /// @param supplyFulfillment_ percentage (in RAY) of supply orders which have been fullfilled in the excuted epoch
    /// @param redeemFulfillment_ percentage (in RAY) of redeem orders which have been fullfilled in the excuted epoch
    /// @param tokenPrice_ tokenPrice of the executed epoch
    /// @param epochSupplyOrderCurrency total order of currency in the executed epoch
    /// @param epochRedeemOrderCurrency total order of redeems expressed in the currency value for the executed epoch
    function epochUpdate(
        uint256 epochID,
        uint256 supplyFulfillment_,
        uint256 redeemFulfillment_,
        uint256 tokenPrice_,
        uint256 epochSupplyOrderCurrency,
        uint256 epochRedeemOrderCurrency
    ) public auth {
        require(waitingForUpdate == true);
        waitingForUpdate = false;

        epochs[epochID].supplyFulfillment = supplyFulfillment_;
        epochs[epochID].redeemFulfillment = redeemFulfillment_;
        epochs[epochID].tokenPrice = tokenPrice_;

        // currency needs to be converted to tokenAmount with current token price
        uint256 redeemInToken = 0;
        uint256 supplyInToken = 0;
        if (tokenPrice_ > 0) {
            supplyInToken = rdiv(epochSupplyOrderCurrency, tokenPrice_);
            redeemInToken = safeDiv(safeMul(epochRedeemOrderCurrency, ONE), tokenPrice_);
        }

        // calculates the delta between supply and redeem for currency and deposit or get them from the reserve
        _adjustCurrencyBalance(epochID, epochSupplyOrderCurrency, epochRedeemOrderCurrency);
        // calculates the delta between supply and redeem for tokens and burn or mint them
        _adjustTokenBalance(epochID, supplyInToken, redeemInToken);

        // the unfulfilled orders (1-fulfillment) is automatically ordered
        totalSupply = safeAdd(
            _safeTotalSub(totalSupply, epochSupplyOrderCurrency),
            rmul(epochSupplyOrderCurrency, safeSub(ONE, epochs[epochID].supplyFulfillment))
        );
        totalRedeem = safeAdd(
            _safeTotalSub(totalRedeem, redeemInToken),
            rmul(redeemInToken, safeSub(ONE, epochs[epochID].redeemFulfillment))
        );
    }

    /// @notice closes an epoch by changes the state of the contract to waitingForUpdate
    /// and returns the totalSupply and totalRedeem for this epoch
    /// new supplies or redeems will be accounted for the next epoch
    /// @return totalSupplyCurrency_ total amount of supply orders
    /// @return totalRedeemToken_ total amount of redeem orders in token
    function closeEpoch() public auth returns (uint256 totalSupplyCurrency_, uint256 totalRedeemToken_) {
        require(waitingForUpdate == false);
        waitingForUpdate = true;
        return (totalSupply, totalRedeem);
    }

    /// @notice helper function to burn tokens
    /// @param tokenAmount the amount of tokens to burn
    /// @dev if the the amount is higher than the maximum, the maximum is burned
    function _safeBurn(uint256 tokenAmount) internal {
        uint256 max = token.balanceOf(address(this));
        if (tokenAmount > max) {
            tokenAmount = max;
        }
        token.burn(address(this), tokenAmount);
        emit Burn(address(this), tokenAmount);
    }

    /// @notice helper function to take currency from the reserve
    /// @param currencyAmount the amount of currency
    /// @return payoutAmount the actual paid out amount
    function _safePayout(uint256 currencyAmount) internal returns (uint256 payoutAmount) {
        uint256 max = reserve.totalBalanceAvailable();

        if (currencyAmount > max) {
            // currently reserve can't fulfill the entire request
            currencyAmount = max;
        }
        reserve.payout(currencyAmount);
        return currencyAmount;
    }

    /// @notice takes requestedCurrency from the reserve
    /// this can happen if another tranche will supply currency which will be used for
    /// redeem orders in this tranche
    /// In such a case the currency is not immediately available in the reserve and needs to be first
    /// transfered from the other tranche
    function payoutRequestedCurrency() public {
        if (requestedCurrency > 0) {
            uint256 payoutAmount = _safePayout(requestedCurrency);
            requestedCurrency = safeSub(requestedCurrency, payoutAmount);
        }
    }
    /// @notice adjust token balance after epoch execution -> min/burn tokens
    /// @param epochID id of the epoch
    /// @param epochSupplyToken amount of tokens to supply
    /// @param epochRedeemToken amount of tokens to redeem

    function _adjustTokenBalance(uint256 epochID, uint256 epochSupplyToken, uint256 epochRedeemToken) internal {
        // mint token amount for supply

        uint256 mintAmount = 0;
        if (epochs[epochID].tokenPrice > 0) {
            mintAmount = rmul(epochSupplyToken, epochs[epochID].supplyFulfillment);
        }

        // burn token amount for redeem
        uint256 burnAmount = rmul(epochRedeemToken, epochs[epochID].redeemFulfillment);
        // burn tokens that are not needed for disbursement
        uint256 diff;
        if (burnAmount > mintAmount) {
            diff = safeSub(burnAmount, mintAmount);
            _safeBurn(diff);
            return;
        }
        // mint tokens that are required for disbursement
        diff = safeSub(mintAmount, burnAmount);
        if (diff > 0) {
            token.mint(address(this), diff);
        }
    }

    /// @notice additional minting of tokens produces a dilution of all token holders
    /// interface is required for adapters
    /// @param usr the user which receives the tokens
    /// @param amount the amount of tokens to mint
    function mint(address usr, uint256 amount) public auth {
        token.mint(usr, amount);
        emit Mint(usr, amount);
    }

    /// @notice adjust currency balance after epoch execution -> receive/send currency from/to reserve
    /// @param epochID id of the epoch
    /// @param epochSupply amount of currency to supply
    /// @param epochRedeem amount of currency to redeem
    function _adjustCurrencyBalance(uint256 epochID, uint256 epochSupply, uint256 epochRedeem) internal {
        // currency that was supplied in this epoch
        uint256 currencySupplied = rmul(epochSupply, epochs[epochID].supplyFulfillment);
        // currency required for redemption
        uint256 currencyRequired = rmul(epochRedeem, epochs[epochID].redeemFulfillment);

        uint256 diff;
        if (currencySupplied > currencyRequired) {
            // send surplus currency to reserve
            diff = safeSub(currencySupplied, currencyRequired);
            currency.approve(address(reserve), diff);
            reserve.deposit(diff);
            return;
        }
        diff = safeSub(currencyRequired, currencySupplied);
        if (diff > 0) {
            // get missing currency from reserve
            uint256 payoutAmount = _safePayout(diff);
            if (payoutAmount < diff) {
                // reserve couldn't fulfill the entire request
                requestedCurrency = safeAdd(requestedCurrency, safeSub(diff, payoutAmount));
            }
        }
    }

    /// @notice recovery transfer can be used by governance to recover funds if tokens are stuck
    /// @param erc20 the address of the token to recover
    /// @param usr the user which receives the tokens
    /// @param amount the amount of tokens to recover
    function authTransfer(address erc20, address usr, uint256 amount) public auth {
        ERC20Like(erc20).transfer(usr, amount);
        emit AuthTransfer(erc20, usr, amount);
    }

    /// @notice due to rounding in token & currency conversions currency & token balances might be off by 1 wei with the totalSupply/totalRedeem amounts.
    /// in order to prevent an underflow error, 0 is returned when amount to be subtracted is bigger then the total value.
    /// @param total the total value
    /// @param amount the amount to be subtracted
    /// @return result result of the subtraction
    function _safeTotalSub(uint256 total, uint256 amount) internal pure returns (uint256 result) {
        if (total < amount) {
            return 0;
        }
        return safeSub(total, amount);
    }
}