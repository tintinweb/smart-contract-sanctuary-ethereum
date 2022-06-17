// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import {Context, IAnyCall} from "./interfaces/IAnyCall.sol";
import {
    ANYCALL_ADDRESS_MUMBAI,
    ANYCALL_ADDRESS_RINKEBY
} from "./constants/Addresses.sol";

contract G3CReceiver {
    address public immutable anyExec;
    address public g3cSenderAddress;

    event LogReceiveCCCall(
        address indexed msgSender,
        address indexed to,
        bytes indexed ccMsg
    );

    modifier onlyAnyExec() {
        require(msg.sender == anyExec, "G3CReceiver: onlyAnyExec");
        _;
    }

    constructor(address _g3cSenderAddress) {
        anyExec = _getAnyCallAddress();
        g3cSenderAddress = _g3cSenderAddress;
    }

    function receiveCCCall(
        address _msgSender,
        address _to,
        bytes calldata _ccMsg
    ) external onlyAnyExec {
        //solhint-disable-next-line
        address ANYCALL_ADDRESS = _getAnyCallAddress();
        Context memory context = IAnyCall(ANYCALL_ADDRESS).context();
        require(
            context.sender == g3cSenderAddress,
            "G3CReceiver: _from does not match G3CSender address"
        );
        // EIP 2771 compliance
        (bool success, ) = _to.call(abi.encodePacked(_ccMsg, _msgSender));
        require(success, "G3CReceiver: _to call reverted");
        emit LogReceiveCCCall(_msgSender, _to, _ccMsg);
    }

    function _getAnyCallAddress() internal view returns (address) {
        //solhint-disable-next-line
        address ANYCALL_ADDRESS;
        if (block.chainid == 4) {
            // rinkeby
            ANYCALL_ADDRESS = ANYCALL_ADDRESS_RINKEBY;
        } else if (block.chainid == 80001) {
            // mumbai
            ANYCALL_ADDRESS = ANYCALL_ADDRESS_MUMBAI;
        }
        return ANYCALL_ADDRESS;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

struct Context {
    address sender;
    uint256 fromChainID;
}

interface IAnyCall {
    event LogAnyCall(
        address indexed from,
        address indexed to,
        bytes data,
        address _fallback,
        uint256 indexed toChainID
    );

    event LogAnyExec(
        address indexed from,
        address indexed to,
        bytes data,
        bool success,
        bytes result,
        address _fallback,
        uint256 indexed fromChainID
    );

    event Deposit(address indexed account, uint256 amount);

    event SetWhitelist(
        address indexed from,
        address indexed to,
        uint256 indexed toChainID,
        bool flag
    );

    function context() external returns (Context calldata);

    function anyCall(
        address _to,
        bytes calldata _data,
        address _fallback,
        uint256 _toChainId
    ) external;

    function anyExec(
        address _from,
        address _to,
        bytes calldata _data,
        address _fallback,
        uint256 _fromChainID
    ) external;

    function deposit(address _account) external payable;

    function setWhitelist(
        address _from,
        address _to,
        uint256 _toChainID,
        bool _flag
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

address constant ANYCALL_ADDRESS_RINKEBY = 0xf8a363Cf116b6B633faEDF66848ED52895CE703b;
address constant ANYCALL_ADDRESS_MUMBAI = 0xE3F5a90F9cb311505cd691a46596599aA1A0AD7D;