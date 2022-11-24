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

import "tinlake-math/math.sol";
import "tinlake-auth/auth.sol";

interface ERC20Like {
    function balanceOf(address) external view returns (uint256);
    function transferFrom(address, address, uint256) external returns (bool);
    function mint(address, uint256) external;
    function burn(address, uint256) external;
    function totalSupply() external view returns (uint256);
    function approve(address, uint256) external;
}

interface LendingAdapter {
    function remainingCredit() external view returns (uint256);
    function draw(uint256 amount) external;
    function wipe(uint256 amount) external;
    function debt() external returns (uint256);
    function activated() external view returns (bool);
}

/// @notice the reserve keeps track of the currency and the bookkeeping
/// of the total balance
contract Reserve is Math, Auth {
    ERC20Like public currency;

    // additional currency from lending adapters
    // for deactivating set to address(0)
    LendingAdapter public lending;

    // currency available for borrowing new loans
    uint256 public currencyAvailable;

    // address or contract which holds the currency
    // by default it is address(this)
    address pot;

    // total currency in the reserve
    uint256 public balance_;

    event File(bytes32 indexed what, uint256 amount);
    event Depend(bytes32 contractName, address addr);

    constructor(address currency_) {
        currency = ERC20Like(currency_);
        pot = address(this);
        currency.approve(pot, type(uint256).max);
        wards[msg.sender] = 1;
        emit Rely(msg.sender);
    }

    /// @notice file allows wards to change parameters of the reserve
    /// @param what what parameter to change
    /// @param amount the new value of a param
    function file(bytes32 what, uint256 amount) public auth {
        if (what == "currencyAvailable") {
            currencyAvailable = amount;
        } else {
            revert();
        }
        emit File(what, amount);
    }

    /// @notice depend allows wards to change dependencies of the reserve
    /// @param contractName the name of the contract to change
    /// @param addr the new address of the contract
    function depend(bytes32 contractName, address addr) public auth {
        if (contractName == "currency") {
            currency = ERC20Like(addr);
            if (pot == address(this)) {
                currency.approve(pot, type(uint256).max);
            }
        } else if (contractName == "pot") {
            pot = addr;
        } else if (contractName == "lending") {
            lending = LendingAdapter(addr);
        } else {
            revert();
        }
        emit Depend(contractName, addr);
    }

    /// @notice returns the amount of currency currently in the reserve
    /// @return totalBalance_ amount of currency in the reserve
    function totalBalance() public view returns (uint256 totalBalance_) {
        return balance_;
    }

    /// @notice return the amount of currency and the available currency from the lending adapter
    /// @return totalBalanceAvailable_ amount of currency in the reserve and from the lending adapter
    function totalBalanceAvailable() public view returns (uint256 totalBalanceAvailable_) {
        if (address(lending) == address(0)) {
            return balance_;
        }

        return safeAdd(balance_, lending.remainingCredit());
    }

    /// @notice deposits currency in the the reserve
    /// @param currencyAmount amount of currency to deposit in the reserve
    function deposit(uint256 currencyAmount) public auth {
        if (currencyAmount == 0) return;
        _deposit(msg.sender, currencyAmount);
    }

    /// @notice hard deposit guarantees that the currency stays in the reserve
    /// and is not used to repay a lending adapter
    /// @param currencyAmount amount of currency to deposit in the reserve
    function hardDeposit(uint256 currencyAmount) public auth {
        _depositAction(msg.sender, currencyAmount);
    }

    /// @notice deposits currency in the the reserve
    /// @param usr the address from which to transfer the currency
    /// @param currencyAmount amount of currency to deposit in the reserve
    function _depositAction(address usr, uint256 currencyAmount) internal {
        require(currency.transferFrom(usr, pot, currencyAmount), "reserve-deposit-failed");
        balance_ = safeAdd(balance_, currencyAmount);
    }

    /// @notice interal deposit function
    /// @param usr the address from which to transfer the currency
    /// @param currencyAmount amount of currency to deposit in the reserve
    function _deposit(address usr, uint256 currencyAmount) internal {
        _depositAction(usr, currencyAmount);
        if (address(lending) != address(0) && lending.debt() > 0 && lending.activated()) {
            uint256 wipeAmount = lending.debt();
            uint256 available = balance_;
            if (available < wipeAmount) {
                wipeAmount = available;
            }
            lending.wipe(wipeAmount);
        }
    }

    /// @notice withdraws currency from the reserve to msg.sender
    /// @param currencyAmount amount of currency to payout from the reserve
    function payout(uint256 currencyAmount) public auth {
        if (currencyAmount == 0) return;
        _payout(msg.sender, currencyAmount);
    }

    /// @notice interal payout function to transfer currency to an address
    /// @param usr the address to which to transfer the currency
    /// @param currencyAmount amount of currency to payout from the reserve
    function _payoutAction(address usr, uint256 currencyAmount) internal {
        require(currency.transferFrom(pot, usr, currencyAmount), "reserve-payout-failed");
        balance_ = safeSub(balance_, currencyAmount);
    }

    /// @notice hard payout guarantees that only currency which is already in the reserve is taken
    /// @param currencyAmount amount of currency to payout from the reserve
    function hardPayout(uint256 currencyAmount) public auth {
        _payoutAction(msg.sender, currencyAmount);
    }

    /// @notice interal payout function
    /// @param usr the address to which to transfer the currency
    /// @param currencyAmount amount of currency to payout from the reserve
    function _payout(address usr, uint256 currencyAmount) internal {
        uint256 reserveBalance = balance_;
        if (currencyAmount > reserveBalance && address(lending) != address(0) && lending.activated()) {
            uint256 drawAmount = safeSub(currencyAmount, reserveBalance);
            uint256 left = lending.remainingCredit();
            if (drawAmount > left) {
                drawAmount = left;
            }

            lending.draw(drawAmount);
        }

        _payoutAction(usr, currencyAmount);
    }

    /// @notice payout currency for loans not all funds
    /// in the reserve are compulsory available for loans in the current epoch
    /// @param currencyAmount amount of currency to payout for loan borrowings
    function payoutForLoans(uint256 currencyAmount) public auth {
        require(currencyAvailable >= currencyAmount, "not-enough-currency-reserve");

        currencyAvailable = safeSub(currencyAvailable, currencyAmount);
        _payout(msg.sender, currencyAmount);
    }
}