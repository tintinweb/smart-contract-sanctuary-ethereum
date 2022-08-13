// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title token exchange smart contract for Catheon Gaming Center
/// @author @seiji0411
contract CGCTokenExchange is Ownable {
    // signer address
    address private signerAddress;
    // mapping of token to pause flag
    mapping(address => bool) tokenPaused;
    // mapping of token to mapping account to total withdrew amount
    mapping(address => mapping(address => uint256)) private withdrawAmt;
    // mapping of token to mapping account to total deposited amount
    mapping(address => mapping(address => uint256)) private depositAmt;

    event Withdrawal(address token, uint256 amount, uint256 sum);
    event Deposit(address token, uint256 amount, uint256 sum);
    event SetSignerAddress();
    event PauseTokenExchange();
    event ResumeTokenExchange();

    modifier tokenAvailable(address token) {
        require(!tokenPaused[token], "Exchange paused");
        _;
    }

    // constructor
    constructor(address _signerAddress) payable {
        require(
            _signerAddress != address(0),
            "Invalid signer address"
        );

        signerAddress = _signerAddress;
    }

    /// @dev withdraw token
    /// @param _token Token address
    /// @param _amount Token amount
    /// @param _sig Signature of parameters including account address
    function withdraw(address _token, uint256 _amount, bytes memory _sig) external tokenAvailable(_token) {
        require(isValidSig(msg.sender, _token, _amount, _sig), "Invalid request");

        withdrawAmt[_token][msg.sender] += _amount;
        IERC20(_token).transfer(msg.sender, _amount);

        emit Withdrawal(_token, _amount, withdrawAmt[_token][msg.sender]);
    }

    /// @dev deposit token
    /// @param _token Token address
    /// @param _amount Token amount
    /// @param _sig Signature of parameters including account address
    function deposit(address _token, uint256 _amount, bytes memory _sig) external tokenAvailable(_token) {
        require(isValidSig(msg.sender, _token, _amount, _sig), "Invalid request");

        depositAmt[_token][msg.sender] += _amount;
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);

        emit Deposit(_token, _amount, depositAmt[_token][msg.sender]);
    }

    /// @dev check validate signature with parameters
    /// @param _account Account address
    /// @param _token Token address
    /// @param _amount Token amount
    /// @param _sig Signature of parameters
    function isValidSig(address _account, address _token, uint256 _amount, bytes memory _sig) public view returns (bool) {
        bytes32 message = keccak256(abi.encodePacked(_account, _token, _amount));
        bytes32 ethSignedMessage = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", message));
        return (recoverSigner(ethSignedMessage, _sig) == signerAddress);
    }

    /// @dev recover signer address
    /// @param _message Message
    /// @param _sig Singed message
    function recoverSigner(bytes32 _message, bytes memory _sig) internal pure returns (address) {
        uint8 v;
        bytes32 r;
        bytes32 s;
        (v, r, s) = splitSignature(_sig);
        return ecrecover(_message, v, r, s);
    }

    /// @dev split signature
    /// @param _sig Singed message
    function splitSignature(bytes memory _sig) internal pure returns (uint8, bytes32, bytes32) {
        require(_sig.length == 65);
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(_sig, 32))
            // second 32 bytes
            s := mload(add(_sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(_sig, 96)))
        }

        return (v, r, s);
    }

    /// @dev set signer address
    /// @param _address Signer address
    function setSingerAddress(address _address) external onlyOwner {
        signerAddress = _address;
        emit SetSignerAddress();
    }

    /// @dev pause exchange of special token
    /// @param _token Token address
    function pauseTokenExchange(address _token) external onlyOwner {
        tokenPaused[_token] = true;
        emit PauseTokenExchange();
    }

    /// @dev resume exchange of special token
    /// @param _token Token address
    function resumeTokenExchange(address _token) external onlyOwner {
        tokenPaused[_token] = false;
        emit ResumeTokenExchange();
    }

    /// @dev get account`s total withdrew amount of token
    /// @param _token Token address
    /// @param _account Account address
    function totWithdrawAmtOf(address _token, address _account) external view returns(uint256) {
        return withdrawAmt[_token][_account];
    }

    /// @dev get account`s total deposited amount of token
    /// @param _token Token address
    /// @param _account Account address
    function totDepositAmtOf(address _token, address _account) external view returns(uint256) {
        return depositAmt[_token][_account];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
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