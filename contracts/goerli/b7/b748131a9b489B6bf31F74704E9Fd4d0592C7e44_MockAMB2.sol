// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

interface ITransactionHandler {
    event NewCommitment(bytes32 commitment, uint256 index, bytes encryptedOutput);
    event NewNullifier(bytes32 nullifier);
    event NewTransact(int256 extAmount, address relayer, uint256 fee);

    struct ExtData {
        address recipient;
        int256 extAmount;
        address relayer;
        uint256 fee;
        bytes encryptedOutput1;
        bytes encryptedOutput2;
        bool isL1Withdrawal;
    }

    struct Proof {
        bytes proof;
        bytes32 root;
        bytes32[] inputNullifiers;
        bytes32[2] outputCommitments;
        uint256 publicAmount;
        bytes32 extDataHash;
    }

    function transact(Proof memory args, ExtData memory extData) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma abicoder v2;

import "../interfaces/ITransactionHandler.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MockAMB2 {
    address public target;
    mapping(bytes32 => bool) internal boolStorage;
    mapping(bytes32 => uint256) internal uintStorage;
    mapping(bytes => bytes) internal signatures;

    event UserRequestForAffirmation(bytes32 indexed messageId, bytes encodedData);
    event UserRequestForSignature(bytes32 indexed messageId, bytes encodedData);
    event AffirmationCompleted(
        address indexed sender,
        address indexed executor,
        bytes32 indexed messageId,
        bool status
    );

    event RelayedMessage(address indexed sender, address indexed executor, bytes32 indexed messageId, bool status);

    constructor(address pool) {
        target = pool;
    }

    function setPool(address pool) public {
        target = pool;
    }

    function calledByOmni(address token, address _receiver, uint256 _value, bytes calldata _data) public {
        ITransactionHandler.Proof memory args;
        ITransactionHandler.ExtData memory extData;
        (args, extData) = abi.decode(_data, (ITransactionHandler.Proof, ITransactionHandler.ExtData));

        IERC20(token).approve(target, _value);
        IERC20(token).transferFrom(tx.origin, address(this), _value);
        ITransactionHandler(target).transact(args, extData);

        bytes32 messageId = sha256(_data);

        emit UserRequestForAffirmation(messageId, _data);
    }

    function requireToPassMessage() public {
        bytes32 messageId = sha256(abi.encodePacked(block.timestamp));
        bytes memory encodedData = abi.encodePacked(block.timestamp);
        emit UserRequestForSignature(messageId, encodedData);
    }

    function safeExecuteSignaturesWithAutoGasLimit(bytes calldata _data, bytes calldata _signatures) external {
        emit RelayedMessage(msg.sender, msg.sender, 0, true);
    }

    /**
    * @dev Sets a status of the message that came from the other side.
    * @param _messageId id of the message from the other side that triggered a call.
    * @param _status execution status, true if executed successfully.
    */
    function setMessageCallStatus(bytes32 _messageId, bool _status) public {
        boolStorage[keccak256(abi.encodePacked("messageCallStatus", _messageId))] = _status;
        if(_status == true) {
            emit AffirmationCompleted(msg.sender, msg.sender, _messageId, true);
        } else {
            setFailedMessageDataHash(_messageId, sha256(abi.encodePacked(block.timestamp)));
        }
    }

    function setFailedMessageDataHash(bytes32 _messageId, bytes32 _dataHash) public {
        uintStorage[keccak256(abi.encodePacked("failedMessageDataHash", _messageId))] = uint256(_dataHash);
    }

    function setSignatures(bytes calldata _messageHash, bytes calldata _signature) public {
        signatures[_messageHash] = _signature;
    }

    function getSignatures(bytes calldata _messageHash) external view returns(bytes memory) {
        return signatures[_messageHash];
    }

    /**
    * @dev Returns a status of the message that came from the other side.
    * @param _messageId id of the message from the other side that triggered a call.
    * @return true if call executed successfully.
    */
    function messageCallStatus(bytes32 _messageId) external view returns (bool) {
        return boolStorage[keccak256(abi.encodePacked("messageCallStatus", _messageId))];
    }

    function failedMessageDataHash(bytes32 _messageId) external view returns (bytes32) {
        return bytes32(uintStorage[keccak256(abi.encodePacked("failedMessageDataHash", _messageId))]);
    }
}