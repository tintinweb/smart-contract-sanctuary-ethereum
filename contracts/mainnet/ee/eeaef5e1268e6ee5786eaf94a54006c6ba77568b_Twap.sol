/**
 *Submitted for verification at Etherscan.io on 2022-12-08
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

/**
 * @title Represents a resource that requires initialization.
 */
contract CustomInitializable {
    bool private _wasInitialized;

    /**
     * @notice Throws if the resource was not initialized yet.
     */
    modifier ifInitialized () {
        require(_wasInitialized, "Not initialized yet");
        _;
    }

    /**
     * @notice Throws if the resource was initialized already.
     */
    modifier ifNotInitialized () {
        require(!_wasInitialized, "Already initialized");
        _;
    }

    /**
     * @notice Marks the resource as initialized.
     */
    function _initializationCompleted () internal ifNotInitialized {
        _wasInitialized = true;
    }
}

/**
 * @title Represents an ownable resource.
 */
contract CustomOwnable {
    // The current owner of this resource.
    address internal _owner;

    /**
     * @notice This event is triggered when the current owner transfers ownership of the contract.
     * @param previousOwner The previous owner
     * @param newOwner The new owner
     */
    event OnOwnershipTransferred (address previousOwner, address newOwner);

    /**
     * @notice This modifier indicates that the function can only be called by the owner.
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == msg.sender, "Only owner");
        _;
    }

    /**
     * @notice Transfers ownership to the address specified.
     * @param addr Specifies the address of the new owner.
     * @dev Throws if called by any account other than the owner.
     */
    function transferOwnership (address addr) external virtual onlyOwner {
        require(addr != address(0), "non-zero address required");
        emit OnOwnershipTransferred(_owner, addr);
        _owner = addr;
    }

    /**
     * @notice Gets the owner of this contract.
     * @return Returns the address of the owner.
     */
    function owner () external virtual view returns (address) {
        return _owner;
    }
}

interface IBasicAsset {
    function transfer(address to, uint256 value) external;
    function approve(address spender, uint256 value) external;
    function balanceOf(address addr) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
}

interface IParaSwapAugustus {
  function getTokenTransferProxy() external view returns (address);
}

contract Twap is CustomOwnable, CustomInitializable, ReentrancyGuard {
    address private constant AUGUSTUS_SWAPPER_ADDR = 0xDEF171Fe48CF0115B1d80b88dc8eAB59176FEe57;
    uint8 private constant STEP_PENDING = 0;
    uint8 private constant STEP_PROCESSED = 1;

    address public operator;

    mapping (bytes32 => uint256) private _deadlines;
    mapping (bytes32 => mapping (uint256 => bytes32)) private _requests;
    mapping (bytes32 => mapping (uint256 => uint8)) private _stepStates;

    event OnFeedProcessed(bytes32 topic, uint256 stepIndex);
    event OnCompletion(bytes32 topic, address targetTokenAddr);

    constructor () {
        _owner = msg.sender;
    }

    modifier onlyOperator() {
        require(operator == msg.sender, "Only operator");
        _;
    }

    function initialize (address newOwnerAddr, address operatorAddr) external onlyOwner ifNotInitialized {
        require(newOwnerAddr != address(0) && newOwnerAddr != address(this), "Invalid owner");
        require(operatorAddr != address(0) && operatorAddr != address(this), "Invalid operator");

        _owner = newOwnerAddr;
        operator = operatorAddr;

        _initializationCompleted();
    }
    
    function approveSpender (IBasicAsset token, uint256 amount) external onlyOperator ifInitialized nonReentrant {
        _approveSpenderProxy(token, amount);
    }

    function revokeSpender (IBasicAsset token) external onlyOperator ifInitialized nonReentrant {
        _revokeSpenderProxy(token);
    }

    function createTopic (bytes32 topic, uint256 deadline, bytes32[] calldata steps) external onlyOperator ifInitialized nonReentrant {
        require(topic != bytes32(0), "Topic required");
        require(steps.length > 0, "Steps required");
        require(deadline > block.timestamp, "Invalid deadline"); // solhint-disable-line not-rely-on-time

        _deadlines[topic] = deadline;
        
        for (uint8 i = 0; i < steps.length; i++) {
            require(steps[i] != bytes32(0), "Invalid step");
            _requests[topic][i] = steps[i];
            _stepStates[topic][i] = STEP_PENDING;
        }

        _requests[topic][steps.length] = bytes32(0);
    }

    function cancel (bytes32 topic) external onlyOperator ifInitialized nonReentrant {
        require(_deadlines[topic] > 0, "Topic already cancelled");

        _deadlines[topic] = 0;
    }

    function acceptFeed (bytes32 topic, IBasicAsset targetToken, uint256 stepIndex, uint256 notBeforeEpoch, uint256 buyingAmount, bytes32 secretRevealed, bytes memory payload) external onlyOperator ifInitialized nonReentrant {
        require(_deadlines[topic] > block.timestamp, "Topic expired"); // solhint-disable-line not-rely-on-time
        require(block.timestamp >= notBeforeEpoch, "Feed came too soon"); // solhint-disable-line not-rely-on-time

        bytes32 expectedHash = _requests[topic][stepIndex];
        require(expectedHash != bytes32(0), "Invalid step");

        require(_stepStates[topic][stepIndex] == STEP_PENDING, "Step already processed");
        if (stepIndex > 0) require(_stepStates[topic][stepIndex - 1] == STEP_PROCESSED, "Previous step not processed");

        bytes32 actualHash = _buildHash(address(targetToken), stepIndex, buyingAmount, notBeforeEpoch, secretRevealed);
        require(expectedHash == actualHash, "Invalid proof");

        _stepStates[topic][stepIndex] = STEP_PROCESSED;
        _requests[topic][stepIndex] = bytes32(0);

        uint256 balanceBefore = targetToken.balanceOf(address(this));

        // Run the swap
        (bool success,) = AUGUSTUS_SWAPPER_ADDR.call(payload); // solhint-disable-line avoid-low-level-calls
        require(success, "Swap failed");

        uint256 balanceAfter = targetToken.balanceOf(address(this));
        require(balanceAfter > balanceBefore, "Balance check failed");

        emit OnFeedProcessed(topic, stepIndex);

        if (_requests[topic][stepIndex + 1] == bytes32(0)) {
            _deadlines[topic] = 0;
            emit OnCompletion(topic, address(targetToken));
        }
    }
    
    function withdraw (IBasicAsset token) external onlyOwner ifInitialized nonReentrant {
        uint256 currentBalance = token.balanceOf(address(this));
        require(currentBalance > 0, "Zero balance");

        token.transfer(msg.sender, currentBalance);

        require(token.balanceOf(address(this)) == 0, "Balance check failed");
    }

    function _approveSpenderProxy (IBasicAsset token, uint256 amount) private {
        address proxyAddr = IParaSwapAugustus(AUGUSTUS_SWAPPER_ADDR).getTokenTransferProxy();
        if (token.allowance(address(this), proxyAddr) < amount) {
            token.approve(proxyAddr, amount);
        }
    }

    function _revokeSpenderProxy (IBasicAsset token) private {
        address proxyAddr = IParaSwapAugustus(AUGUSTUS_SWAPPER_ADDR).getTokenTransferProxy();
        if (token.allowance(address(this), proxyAddr) > 0) {
            token.approve(proxyAddr, 0);
        }
    }

    function getDeadline (bytes32 topic) external view onlyOperator ifInitialized returns (uint256) {
        return _deadlines[topic];
    }

    function getStep (bytes32 topic, uint256 stepIndex) external view onlyOperator ifInitialized returns (bytes32 stepHash, uint8 stepState) {
        stepState = _stepStates[topic][stepIndex];
        stepHash = _requests[topic][stepIndex];
    }

    function _buildHash (address targetTokenAddr, uint256 stepIndex, uint256 amount, uint256 notBeforeEpoch, bytes32 secretRevealed) private pure returns (bytes32) {
        bytes32 tokenHash = keccak256(abi.encodePacked(targetTokenAddr));
        return keccak256(abi.encode(amount, stepIndex, notBeforeEpoch, secretRevealed, tokenHash));
    }
}