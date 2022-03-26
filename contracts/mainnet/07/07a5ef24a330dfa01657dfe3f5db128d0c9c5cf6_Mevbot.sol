// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IERC20.sol";
import "./interfaces/IDYDX.sol";
import "./interfaces/IWETH9.sol";

contract Mevbot is ICallee {
  address private immutable executor;
  uint private constant MAX_INT = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
  uint private constant FLASH_LOAN_FEE = 2;
  
  IWETH9 private constant WETH = IWETH9(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
  ISoloMargin private constant soloMargin = ISoloMargin(0x1E0447b19BB6EcFdAe1e4AE1694b0C3659614e4e);

  modifier onlyExecutor() {
    require(msg.sender == executor);
    _;
  }

  constructor(address _myWallet, address _executor) {
    executor = _executor;
    WETH.approve(address(soloMargin), MAX_INT);
    bool success = WETH.approve(_myWallet, MAX_INT);
    require(success, "approve failed");
  }

  receive() external payable {}

  function flashLoan(uint loanAmount, address[] memory _targets, bytes[] memory _payloads, uint _percentage_to_miner) external onlyExecutor {
    Actions.ActionArgs[] memory operations = new Actions.ActionArgs[](3);

    operations[0] = Actions.ActionArgs({
      actionType: Actions.ActionType.Withdraw,
      accountId: 0,
      amount: Types.AssetAmount({
        sign: false,
        denomination: Types.AssetDenomination.Wei,
        ref: Types.AssetReference.Delta,
        value: loanAmount // Amount to borrow
      }),
      primaryMarketId: 0, // WETH
      secondaryMarketId: 0,
      otherAddress: address(this),
      otherAccountId: 0,
      data: ""
    });
    
    operations[1] = Actions.ActionArgs({
      actionType: Actions.ActionType.Call,
      accountId: 0,
      amount: Types.AssetAmount({
        sign: false,
        denomination: Types.AssetDenomination.Wei,
        ref: Types.AssetReference.Delta,
        value: 0
      }),
      primaryMarketId: 0,
      secondaryMarketId: 0,
      otherAddress: address(this),
      otherAccountId: 0,
      data: abi.encode(
        _targets,
        _payloads,
        loanAmount,
        _percentage_to_miner
      )
    });
    
    operations[2] = Actions.ActionArgs({
      actionType: Actions.ActionType.Deposit,
      accountId: 0,
      amount: Types.AssetAmount({
          sign: true,
          denomination: Types.AssetDenomination.Wei,
          ref: Types.AssetReference.Delta,
          value: loanAmount + FLASH_LOAN_FEE // Repayment amount with 2 wei fee
      }),
      primaryMarketId: 0, // WETH
      secondaryMarketId: 0,
      otherAddress: address(this),
      otherAccountId: 0,
      data: ""
    });

    Account.Info[] memory accountInfos = new Account.Info[](1);
    accountInfos[0] = Account.Info({owner: address(this), number: 1});

    soloMargin.operate(accountInfos, operations);
  }

  function resolver(uint256 _ethAmountToCoinbase, address[] memory _targets, bytes[] memory _payloads) internal {
    require (_targets.length == _payloads.length, "Payload is not equal to target length");
    uint256 _wethBalanceBefore = WETH.balanceOf(address(this));

    for (uint256 i = 0; i < _targets.length; i++) {
      (bool _success, bytes memory _response) = _targets[i].call(_payloads[i]);
      require(_success); _response;
    }

    uint256 _wethBalanceAfter = WETH.balanceOf(address(this));
    require(_wethBalanceAfter > _wethBalanceBefore, "Operation would loose money");

    uint256 _ethBalance = address(this).balance;

    if (_ethBalance < _ethAmountToCoinbase) {
      WETH.withdraw(_ethAmountToCoinbase - _ethBalance);
    }
    block.coinbase.transfer(_ethAmountToCoinbase);
  }

  // This is the function called by dydx after giving us the loan
  function callFunction(address sender, Account.Info memory accountInfo, bytes memory data) external override {
    // Decode the passed variables from the data object
    (
      // This must match the variables defined in the Call object above
      address[] memory _targets,
      bytes[] memory _payloads,
      uint loanAmount,
      uint _percentage_to_miner
    ) = abi.decode(data, (
      address [], bytes [], uint, uint
    ));

    resolver(_percentage_to_miner, _targets, _payloads);
    // It can be useful for debugging to have a verbose error message when
    // the loan can't be paid, since dydx doesn't provide one
    require(WETH.balanceOf(address(this)) > loanAmount + FLASH_LOAN_FEE, "CANNOT REPAY LOAN");
  }
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

interface ICallee {
    function callFunction(address sender, Account.Info memory accountInfo, bytes memory data) external;
}

// These definitions are taken from across multiple dydx contracts, and are
// limited to just the bare minimum necessary to make flash loans work.
library Types {
    enum AssetDenomination { Wei, Par }
    enum AssetReference { Delta, Target }
    struct AssetAmount {
        bool sign;
        AssetDenomination denomination;
        AssetReference ref;
        uint256 value;
    }
}

library Account {
    struct Info {
        address owner;
        uint256 number;
    }
}

library Actions {
    enum ActionType {
        Deposit, Withdraw, Transfer, Buy, Sell, Trade, Liquidate, Vaporize, Call
    }
    struct ActionArgs {
        ActionType actionType;
        uint256 accountId;
        Types.AssetAmount amount;
        uint256 primaryMarketId;
        uint256 secondaryMarketId;
        address otherAddress;
        uint256 otherAccountId;
        bytes data;
    }
}

interface ISoloMargin {
    function operate(Account.Info[] memory accounts, Actions.ActionArgs[] memory actions) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2015, 2016, 2017 Dapphub
// Adapted by Ethereum Community 2021
pragma solidity ^0.8.0;
import "./IERC20.sol";

interface IWETH9 is IERC20 {
  function deposit() external payable;

  function withdraw(uint256 _amount) external;
}