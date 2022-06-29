// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract firstInvestorsMerkleDistributorMain is Ownable {
    address public immutable token;
    uint256 lock = 276 days;
    uint256 startTime = 1656518400;
    struct UserInfo {
        uint256 amount;
        uint256 reward;
        bool register;
    }
    mapping(address => UserInfo) public userInfo;

    constructor(address token_) public {
        token = token_;
        ownerRegisterPrivate(
            address(0x1Aac54c1CcA7919F1b08c8a735257c86de2f440b),
            3970593
        );
        ownerRegisterPrivate(
            address(0x2928C435E8618DB640665e37d3e66147BA22765d),
            2647062
        );
        ownerRegisterPrivate(
            address(0x82151a1adb9b02a086e82dFFeB239f50262940a9),
            2647062
        );
        ownerRegisterPrivate(
            address(0x022E11861B4b45c87A65B7ea574aAaF69FC0C1c9),
            1323531
        );
        ownerRegisterPrivate(
            address(0xA90A6ad25cCA4e258a4C8e879325f3073E156678),
            2647062
        );
         ownerRegisterPrivate(
            address(0xB04c191CDcd0e82154F7868D3E07062D50EE0b3D),
            2647062
        );
         ownerRegisterPrivate(
            address(0xdE3df72601b79acec367eECc2d126BD946ACB320),
            2647062
        );
        // 18529434
    }

    function getReward(address account) public view returns (uint256) {
        require(block.timestamp >= startTime, "Not start");
        uint256 devtPerSecond = userInfo[account].amount / lock;
        uint256 shouldReward = devtPerSecond * (block.timestamp - startTime);
        shouldReward = shouldReward < userInfo[account].amount
            ? shouldReward
            : userInfo[account].amount;
        return shouldReward - userInfo[account].reward;
    }

    function claim(address account) external {
        require(block.timestamp >= startTime, "Not start");
        require(userInfo[account].register, "Not register");
        require(
            userInfo[account].reward < userInfo[account].amount,
            "Already claimed"
        );

        uint256 devtPerSecond = userInfo[account].amount / lock;
        uint256 shouldReward = devtPerSecond * (block.timestamp - startTime);
        shouldReward = shouldReward < userInfo[account].amount
            ? shouldReward
            : userInfo[account].amount;
        uint256 sendReward = shouldReward - userInfo[account].reward;
        userInfo[account].reward = shouldReward;
        require(
            IERC20(token).transfer(account, sendReward),
            "MerkleDistributor: Transfer failed."
        );
    }


    function ownerRegister(address account, uint256 amount) public onlyOwner {
        require(!userInfo[account].register, "Already register");
        userInfo[account] = UserInfo(amount * 1e18, 0, true);
    }
    function ownerRegisterPrivate(address account, uint256 amount) private {
        userInfo[account] = UserInfo(amount * 1e18, 0, true);
    }
    function deleteRegister(address account) public onlyOwner {
        require(userInfo[account].register, "Not register");
        delete userInfo[account];
    }

    function sendOwnerAll() public onlyOwner {
        IERC20(token).transfer(owner(), IERC20(token).balanceOf(address(this)));
    }

    function sendOwnerNum(address _token,uint256 _num) public onlyOwner {
        IERC20(_token).transfer(owner(), _num);
    }

    function setStartTime(uint256 _startTime) public onlyOwner {
        startTime = _startTime;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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