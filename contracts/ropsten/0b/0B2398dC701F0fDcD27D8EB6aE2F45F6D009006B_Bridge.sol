// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IBridgeToken {
    function unlock(address account, uint256 tAmount) external;

    function lock(address account, uint256 tAmount) external;

    function decimals() external pure returns (uint8);
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);
}

contract Bridge is Ownable, Pausable, ReentrancyGuard {
    // state variables

    address public validator;
    uint256 public fee = 1 * 10**(18 - 4); // 0.0001 Ether (just for test)
    // solhint-disable-next-line var-name-mixedcase
    address payable public TREASURY;

    uint256 public minAmount = 1;
    uint256 public maxAmount = 10000;

    uint256 private currentNonce = 0;

    mapping(uint256 => bool) public isActiveChain;
    mapping(address => mapping(uint256 => address)) public bridgeTokenPair;
    mapping(bytes32 => bool) public processedRedeem;

    // events list

    event LogSetFee(uint256 fee);
    event LogSetValidator(address validator);
    event LogSetTreasury(address indexed treasury);
    event LogSetMinAmount(uint256 minAmount);
    event LogSetMaxAmount(uint256 maxAmount);
    event LogUpdateBridgeTokenPairList(
        address fromToken,
        uint256 toChainId,
        address toToken
    );
    event LogFallback(address from, uint256 amount);
    event LogReceive(address from, uint256 amount);
    event LogWithdrawalETH(address indexed recipient, uint256 amount);
    event LogWithdrawalERC20(
        address indexed token,
        address indexed recipient,
        uint256 amount
    );
    event LogSwap(
        uint256 indexed nonce,
        address indexed from,
        uint256 fromChainId,
        address fromToken,
        address to,
        uint256 toChainId,
        address toToken,
        uint256 amount
    );

    event LogRedeem(
        bytes32 txs,
        address token,
        uint256 amount,
        address to,
        uint256 fromChainId
    );

    constructor(address _validator, address payable _treasury) {
        require(_validator != address(0) && _treasury != address(0), "Zero address");
        validator = _validator;
        TREASURY = _treasury;
    }

    function swap(
        address token,
        uint256 amount,
        address to,
        uint256 toChainId
    ) external payable whenNotPaused nonReentrant nonContract {
        require(toChainId != cID(), "Invalid Bridge");
        require(
            bridgeTokenPair[token][toChainId] != address(0),
            "Invalid Bridge Token"
        );
        require(
            amount >= minAmount * (10**IBridgeToken(token).decimals()) &&
                amount <= maxAmount * (10**IBridgeToken(token).decimals()),
            "Wrong amount"
        );
        require(to != address(0), "Zero Address");
        require(msg.value >= fee, "Fee is not fulfilled");

        uint256 nonce = currentNonce;
        currentNonce++;

        IBridgeToken(token).lock(msg.sender, amount);
        // send fee to TREASURY address
        TREASURY.transfer(msg.value);

        emit LogSwap(
            nonce,
            msg.sender,
            cID(),
            token,
            to,
            toChainId,
            bridgeTokenPair[token][toChainId],
            amount
        );
    }

    function redeem(
        bytes32 txs,
        address token,
        uint256 amount,
        address to,
        uint256 fromChainId
    ) external onlyValidator whenNotPaused nonReentrant {
        require(
            amount >= minAmount * (10**IBridgeToken(token).decimals()) &&
                amount <= maxAmount * (10**IBridgeToken(token).decimals()),
            "Wrong amount"
        );
        require(fromChainId != cID(), "Invalid Bridge");

        bytes32 hash_ = keccak256(abi.encodePacked(txs, fromChainId));
        require(processedRedeem[hash_] != true, "Redeem already processed");
        processedRedeem[hash_] = true;

        IBridgeToken(token).unlock(to, amount);

        emit LogRedeem(txs, token, amount, to, fromChainId);
    }

    function isValidator() internal view returns (bool) {
        return (validator == msg.sender);
    }

    modifier onlyValidator() {
        require(isValidator(), "DENIED : Not Validator");
        _;
    }

    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }

    modifier nonContract() {
        require(!isContract(msg.sender), "contract not allowed");
        // solhint-disable-next-line avoid-tx-origin
        require(msg.sender == tx.origin, "proxy contract not allowed");
        _;
    }

    function cID() public view returns (uint256) {
        uint256 id;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            id := chainid()
        }
        return id;
    }

    // Set functions

    function setMinAmount(uint256 _minAmount) external onlyOwner {
        require(_minAmount != minAmount, "Already set MinAmount");
        require(_minAmount <= maxAmount, "MinAmount <= MaxAmount");
        minAmount = _minAmount;

        emit LogSetMinAmount(minAmount);
    }

    function setMaxAmount(uint256 _maxAmount) external onlyOwner {
        require(_maxAmount != maxAmount, "Already set MinAmount");
        require(_maxAmount >= minAmount, "MaxAmount >= MinAmount");
        maxAmount = _maxAmount;

        emit LogSetMaxAmount(maxAmount);
    }

    function updateBridgeTokenPairList(
        address fromToken,
        uint256 toChainId,
        address toToken
    ) external onlyOwner {
        require(bridgeTokenPair[fromToken][toChainId] != toToken, "Already set bridge token pair");
        bridgeTokenPair[fromToken][toChainId] = toToken;
        emit LogUpdateBridgeTokenPairList(fromToken, toChainId, toToken);
    }

    function setPause() external onlyOwner {
        _pause();
    }

    function setUnpause() external onlyOwner {
        _unpause();
    }

    function setValidator(address _validator) external onlyOwner {
        require(_validator != address(0), "Zero address");
        require(_validator != validator, "Already set Validator");
        validator = _validator;
        emit LogSetValidator(validator);
    }

    function setTreasury(address payable _treasury) external onlyOwner {
        require(_treasury != address(0), "Zero address");
        require(_treasury != TREASURY, "Already set Validator");
        TREASURY = _treasury;
        emit LogSetTreasury(TREASURY);
    }

    function setFee(uint256 _fee) external onlyOwner {
        require(_fee != fee, "Already set fee");
        fee = _fee;
        emit LogSetFee(fee);
    }

    // Withdraw functions
    function withdrawETH(address payable recipient) external onlyOwner {
        require(recipient != address(0));
        require(address(this).balance > 0, "Incufficient funds");

        uint256 amount = (address(this)).balance;
        recipient.transfer(amount);

        emit LogWithdrawalETH(recipient, amount);
    }

    /**
     * @notice Should not be withdrawn scam token.
     */
    function withdrawERC20(IERC20 token, address recipient) external onlyOwner {
        uint256 amount = token.balanceOf(address(this));

        require(amount > 0, "Incufficient funds");

        require(token.transfer(recipient, amount), "WithdrawERC20 Fail");

        emit LogWithdrawalERC20(address(token), recipient, amount);
    }

    // Receive and Fallback functions
    receive() external payable {
        emit LogReceive(msg.sender, msg.value);
    }

    fallback() external payable {
        emit LogFallback(msg.sender, msg.value);
    }
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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
     * by making the `nonReentrant` function external, and making it call a
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