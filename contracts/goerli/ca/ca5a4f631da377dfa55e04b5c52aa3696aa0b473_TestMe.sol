/**
 *Submitted for verification at Etherscan.io on 2022-07-07
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

    struct Easy {
        uint256 number1;
        uint256 number2;
    }

    event TestInfo(Account.Info[]);
    event TestAction(Actions.ActionArgs[]);
    event TestEasy(Easy);
    event TestEasyArr(Easy[2]);
    event TestWow(Actions.ActionArgs);

    function paramTest(Account.Info[] memory accounts, Actions.ActionArgs[] memory actions) external {
        emit TestAction(actions);
        emit TestInfo(accounts);
    }

    function paramTest2(Account.Info[] memory accounts) external {
        emit TestInfo(accounts);
    }

    function paramSimpleTest(Easy memory easy) public {
        emit TestEasy(easy);
    }

    function ligma(uint256 easy) external {
        Easy memory splunkMe = Easy({
            number1: easy,
            number2: 9
        });

        Easy[2] memory printItOut = [
            Easy({
                number1: 1,
                number2: 2
            }), 
            Easy({
                number1: 3,
                number2: 4
            })
        ];

        paramSimpleTest(printItOut[1]);

        emit TestEasyArr(printItOut);

        emit TestEasy(splunkMe);
    }

    function Wow() public {
        Actions.ActionArgs memory actions = Actions.ActionArgs({
            actionType: Actions.ActionType.Call,
            accountId: 1,
            amount: Types.AssetAmount({
                sign: false,
                denomination: Types.AssetDenomination.Wei,
                ref: Types.AssetReference.Delta,
                value: 2
            }),
            primaryMarketId: 3,
            secondaryMarketId: 4,
            otherAddress: address(this),
            otherAccountId: 5,
            data: abi.encode(
                // Replace or add any additional variables that you want
                // to be available to the receiver function
                    msg.sender,
                    6
            )
        });
        emit TestWow(actions);
    }

    function ActionTest(Actions.ActionArgs[] memory actions) public {
        emit TestAction(actions);
    }

    receive() external payable {
        // React to receiving ether
    }
}