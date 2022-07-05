/**
 *Submitted for verification at Etherscan.io on 2022-07-05
*/

// SPDX-License-Identifier: AGPL-3.0-or-later

// The ABI encoder is necessary, but older Solidity versions should work
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

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
        Deposit, 
        Withdraw,
        Transfer,
        Buy,
        Sell,
        Trade,
        Liquidate,
        Vaporize,
        Call
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

contract TestMe {

    event TestInfo(Account.Info[]);
    event TestAction(Actions.ActionArgs[]);

    function paramTest(Account.Info[] memory accounts, Actions.ActionArgs[] memory actions) external {
        emit TestAction(actions);
        emit TestInfo(accounts);
    }

    receive() external payable {
        // React to receiving ether
    }
}