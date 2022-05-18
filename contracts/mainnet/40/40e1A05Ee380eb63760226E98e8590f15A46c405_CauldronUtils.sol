// SPDX-License-Identifier: UNLICENSED
// solhint-disable func-name-mixedcase
pragma solidity ^0.8.10;

contract CauldronUtils {
    uint8 internal constant ACTION_REPAY = 2;
    uint8 internal constant ACTION_REMOVE_COLLATERAL = 4;
    uint8 internal constant ACTION_BORROW = 5;
    uint8 internal constant ACTION_GET_REPAY_SHARE = 6;
    uint8 internal constant ACTION_GET_REPAY_PART = 7;
    uint8 internal constant ACTION_ACCRUE = 8;
    uint8 internal constant ACTION_ADD_COLLATERAL = 10;
    uint8 internal constant ACTION_UPDATE_EXCHANGE_RATE = 11;
    uint8 internal constant ACTION_BENTO_DEPOSIT = 20;
    uint8 internal constant ACTION_BENTO_WITHDRAW = 21;
    uint8 internal constant ACTION_BENTO_TRANSFER = 22;
    uint8 internal constant ACTION_BENTO_TRANSFER_MULTIPLE = 23;
    uint8 internal constant ACTION_BENTO_SETAPPROVAL = 24;
    uint8 internal constant ACTION_CALL = 30;

    struct ActionAddRepayRemoveBorrow {
        bool assigned;
        int256 share;
        address to;
        bool skim;
    }

    struct ActionUpdateExchangeRate {
        bool assigned;
        bool mustUpdate;
        uint256 minRate;
        uint256 maxRate;
    }

    struct CookAction {
        string name;
        uint8 action;
        uint256 value;
        bytes data;
    }

    function decodeCookWithSignature(bytes calldata rawData) public pure returns (CookAction[] memory cookActions) {
        return decodeCookData(rawData[4:]);
    }

    function decodeCookData(bytes calldata data) public pure returns (CookAction[] memory cookActions) {
        (uint8[] memory actions, uint256[] memory values, bytes[] memory datas) = abi.decode(data, (uint8[], uint256[], bytes[]));

        cookActions = new CookAction[](actions.length);

        for (uint256 i = 0; i < actions.length; i++) {
            uint8 action = actions[i];
            string memory name;

            if (action == ACTION_ADD_COLLATERAL) {
                name = "addCollateral";
            } else if (action == ACTION_REPAY) {
                name = "repay";
            } else if (action == ACTION_REMOVE_COLLATERAL) {
                name = "removeCollateral";
            } else if (action == ACTION_BORROW) {
                name = "borrow";
            } else if (action == ACTION_UPDATE_EXCHANGE_RATE) {
                name = "updateExchangeRate";
            } else if (action == ACTION_BENTO_SETAPPROVAL) {
                name = "bentoSetApproval";
            } else if (action == ACTION_BENTO_DEPOSIT) {
                name = "bentoDeposit";
            } else if (action == ACTION_BENTO_WITHDRAW) {
                name = "bentoWithdraw";
            } else if (action == ACTION_BENTO_TRANSFER) {
                name = "bentoTransfer";
            } else if (action == ACTION_BENTO_TRANSFER_MULTIPLE) {
                name = "bentoTransferMultiple";
            } else if (action == ACTION_CALL) {
                name = "call";
            } else if (action == ACTION_GET_REPAY_SHARE) {
                name = "getRepayShare";
            } else if (action == ACTION_GET_REPAY_PART) {
                name = "getRepayPart";
            }

            cookActions[i] = CookAction(name, action, values[i], datas[i]);
        }
    }

    function decode_addCollateral(bytes calldata data)
        public
        pure
        returns (
            int256 share,
            address to,
            bool skim
        )
    {
        return abi.decode(data, (int256, address, bool));
    }

    function decode_repay(bytes calldata data)
        public
        pure
        returns (
            int256 part,
            address to,
            bool skim
        )
    {
        return abi.decode(data, (int256, address, bool));
    }

    function decode_removeCollateral(bytes calldata data) public pure returns (int256 share, address to) {
        return abi.decode(data, (int256, address));
    }

    function decode_borrow(bytes calldata data) public pure returns (int256 amount, address to) {
        return abi.decode(data, (int256, address));
    }

    function decode_updateExchangeRate(bytes calldata data)
        public
        pure
        returns (
            bool mustUpdate,
            uint256 minRate,
            uint256 maxRate
        )
    {
        return abi.decode(data, (bool, uint256, uint256));
    }

    function decode_bentoSetApproval(bytes calldata data)
        public
        pure
        returns (
            address user,
            address masterContract,
            bool approved,
            uint8 v,
            bytes32 r,
            bytes32 s
        )
    {
        return abi.decode(data, (address, address, bool, uint8, bytes32, bytes32));
    }

    function decode_bentoDeposit(bytes calldata data)
        public
        pure
        returns (
            address token,
            address to,
            int256 amount,
            int256 share
        )
    {
        return abi.decode(data, (address, address, int256, int256));
    }

    function decode_bentoWithdraw(bytes calldata data)
        public
        pure
        returns (
            address token,
            address to,
            int256 amount,
            int256 share
        )
    {
        return abi.decode(data, (address, address, int256, int256));
    }

    function decode_bentoTransfer(bytes calldata data)
        public
        pure
        returns (
            address token,
            address to,
            int256 share
        )
    {
        return abi.decode(data, (address, address, int256));
    }

    function decode_bentoTransferMultiple(bytes calldata data)
        public
        pure
        returns (
            address token,
            address[] memory tos,
            uint256[] memory shares
        )
    {
        return abi.decode(data, (address, address[], uint256[]));
    }

    function decode_call(bytes calldata data)
        public
        pure
        returns (
            address callee,
            bytes memory callData,
            bool useValue1,
            bool useValue2,
            uint8 returnValues
        )
    {
        return abi.decode(data, (address, bytes, bool, bool, uint8));
    }

    function decode_getRepayShare(bytes calldata data) public pure returns (int256 part) {
        return abi.decode(data, (int256));
    }

    function decode_getRepayPart(bytes calldata data) public pure returns (int256 amount) {
        return abi.decode(data, (int256));
    }
}