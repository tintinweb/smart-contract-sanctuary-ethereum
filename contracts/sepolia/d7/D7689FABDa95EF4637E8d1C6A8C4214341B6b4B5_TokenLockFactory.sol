// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
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

/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TokenLock {
    address public beneficiary;
    address public immutable tokenAddress;
    bool public immutable doVesting;
    uint latestClaim = 0;
    struct Vesting {
        uint256 vestingTime;
        uint256 releaseValue;
    }
    Vesting[12] public vestings; // Array to store the Vesting
    uint256 public immutable totalTokens;
    uint256 public tokensReleased = 0;

    constructor(
        address _beneficiary,
        bool _doVesting,
        uint256[] memory _vestingTime,
        uint256[] memory _releaseValue,
        uint256 _totalTokens,
        address _tokenAddress
    ) {
        require(
            _vestingTime.length == _releaseValue.length,
            "require same length of array"
        );
        uint totalPercentage;
        for(uint256 i = 0; i < _releaseValue.length; i++){
            totalPercentage += _releaseValue[i];
        }
        require(totalPercentage == 10000, "total must 100%");
        tokenAddress = _tokenAddress;
        beneficiary = _beneficiary;
        doVesting = _doVesting;
        totalTokens = _totalTokens;
        for (uint256 i = 0; i < _vestingTime.length; i++) {
            _releaseValue[i] = _releaseValue[i]*totalTokens/10000;
            // Create a new Vesting struct with the provided parameters
            Vesting memory vest = Vesting({
                vestingTime: _vestingTime[i],
                releaseValue: _releaseValue[i]
            });

            // Add the new pool to the vestings array
            vestings[i] = vest;
        }
    }

    modifier owner() {
        require(msg.sender == beneficiary, "only owner can Release Token!");
        _;
    }

    function releaseTokens() external owner{
        require(block.timestamp >= vestings[latestClaim].vestingTime, "cant claim token now!");
        require(vestings[latestClaim].releaseValue != 0, "All tokens have already been released");
        uint256 tokensToRelease = 0;
        for (uint256 i = latestClaim; i <= 12; i++) {
            if (block.timestamp >= vestings[i].vestingTime) {
                tokensToRelease += vestings[i].releaseValue;
                vestings[i].releaseValue = 0;
                latestClaim = i;
            } else {
            break;
            }
        }
        tokensReleased += tokensToRelease;

        // Perform token transfer to the beneficiary
        require(IERC20(tokenAddress).transfer(beneficiary, tokensToRelease));

    }
}

/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./TokenLock.sol";

contract TokenLockFactory is Ownable{
    address[] public tokenLockContracts;
    mapping(address => address[]) public tokenLockFromOwner;
    uint256 public fee = 0;

    event TokenLockContractCreated(address indexed creator, address indexed tokenLockContract);

    function setFee(uint256 _fee) external onlyOwner{
        fee = _fee;
    }

    function withdraw() public onlyOwner{
        uint256 contractBalance = address(this).balance;
        require(contractBalance > 0, "Contract has no Ether balance to withdraw");
        payable(msg.sender).transfer(contractBalance);
    }

    function createTokenLock(
        bool doVesting,
        uint256[] memory vestingTimes,
        uint256[] memory releaseValues,
        uint256 totalTokens,
        address tokenAddress
    ) external returns (address) {

        // Transfer the required amount of Lock tokens from the caller to the factory contract
        require(IERC20(tokenAddress).transferFrom(msg.sender, address(this), totalTokens));

        TokenLock tokenLock = new TokenLock(
            msg.sender,
            doVesting,
            vestingTimes,
            releaseValues,
            totalTokens,
            tokenAddress
        );

        // Transfer the Token to Lock contract
        require(IERC20(tokenAddress).transfer(address(tokenLock), totalTokens));

        address tokenLockContractAddress = address(tokenLock);
        tokenLockContracts.push(tokenLockContractAddress);
        tokenLockFromOwner[msg.sender].push(tokenLockContractAddress);
        emit TokenLockContractCreated(msg.sender, tokenLockContractAddress);
        return tokenLockContractAddress;
    }

    function getTokenLockContracts() external view returns (address[] memory) {
        return tokenLockContracts;
    }
}