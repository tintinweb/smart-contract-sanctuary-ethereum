// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import {CCCall, CCService} from "./structures/CCCall.sol";
import {IAnyCall} from "./interfaces/IAnyCall.sol";
import {
    ANYCALL_ADDRESS_MUMBAI,
    ANYCALL_ADDRESS_RINKEBY
} from "./constants/Addresses.sol";
import {IG3CReceiver} from "./interfaces/IG3CReceiver.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

contract G3CSender {
    address public receiverAddress;

    event LogSendAnyCall(
        address indexed sender,
        address indexed to,
        uint256 indexed toChainId
    );

    // TODO: sendCCCall should support EIP 2771 _msgSender for trusted forwarders.
    // similar to MockG3CDestination EIP2771Context support
    // after first cross-chain ice cream lick
    function sendCCCall(CCCall[] calldata _calls) external {
        // call corresponding function for service
        for (uint256 i = 0; i < _calls.length; i++) {
            if (_calls[i].ccService == CCService.AnyCall) {
                _sendAnyCall(
                    msg.sender,
                    _calls[i].to,
                    _calls[i].ccMsg,
                    _calls[i].toChainId
                );
                emit LogSendAnyCall(
                    // TODO: emit ccMsg as well
                    msg.sender,
                    _calls[i].to,
                    _calls[i].toChainId
                );
            }
        }
    }

    function setReceiverAddress(address _receiverAddress) external {
        receiverAddress = _receiverAddress;
    }

    // check anyCall contract
    // https://etherscan.io/address/0x37414a8662bc1d25be3ee51fb27c2686e2490a89#code
    function _sendAnyCall(
        address _msgSender,
        address _to,
        bytes calldata _ccMsg,
        uint256 _toChainId
    ) private {
        //solhint-disable-next-line
        address ANYCALL_ADDRESS;
        bytes memory data = abi.encodeWithSelector(
            IG3CReceiver.receiveCCCall.selector,
            _msgSender,
            _to,
            _ccMsg
        );

        /* solhint-disable */
        if (block.chainid == 4) {
            // rinkeby
            ANYCALL_ADDRESS = ANYCALL_ADDRESS_RINKEBY;
        } else if (block.chainid == 80001) {
            // mumbai
            ANYCALL_ADDRESS = ANYCALL_ADDRESS_MUMBAI;
        }
        /* solhint-enable */

        IAnyCall(ANYCALL_ADDRESS).anyCall(
            receiverAddress,
            data,
            address(0), // no fallback.
            _toChainId
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

struct CCCall {
    CCService ccService;
    address to;
    bytes ccMsg;
    uint256 toChainId;
}

enum CCService {
    AnyCall,
    LayerZero
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

interface IG3CReceiver {
    function receiveCCCall(
        address _msgSender,
        address _to,
        bytes calldata _ccMsg
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}