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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "../vouchers/IVouchers.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract StakeForVoucher is Ownable {
    event Staked(address indexed staker, uint256 indexed configIndex);
    event Unstaked(address indexed staker, uint256 indexed configIndex);

    struct StakeConfig{
        address tokenAddress;
        bool isEnabled;
        uint256 requiredAmount;
        uint256 duration;
        uint256 slotsAvailable;
        uint256 slotsMax;
        uint256 voucherTypeId;
        uint256 vouchersAmount;
    }
    mapping(uint256 => StakeConfig) public stakeConfig;
    mapping(uint256 => mapping(address => uint256)) public stakeDate;
    mapping(uint256 => mapping(address => bool)) public unstaked;
    uint256 public stakeConfigIndex;
    IVouchers public vouchers;

    function stakeDates(address adr, uint256 from, uint256 to) external view returns (uint256[] memory){
        require(to >= from, "StakeForVoucher: Sort error");
        require(to <= stakeConfigIndex, "StakeForVoucher: Not existing element");
        uint256[] memory dates = new uint256[](to-from+1);
        for(uint256 i=from; i<=to; i++){
            bool isUnstaked = unstaked[i][adr];
            dates[i-from]= isUnstaked ? 1 : stakeDate[i][adr];
        }
        return dates;
    }

    function stakeConfigs(uint256 from, uint256 to) external view returns (StakeConfig[] memory){
        require(to >= from, "StakeForVoucher: Sort error");
        require(to <= stakeConfigIndex, "StakeForVoucher: Not existing element");
        StakeConfig[] memory sc = new StakeConfig[](to-from+1);
        for(uint256 i=from; i<=to; i++){
            sc[i-from]= stakeConfig[i];
        }
        return sc;
    }

    function addStakeConfig(       
        address tokenAddress,
        bool isEnabled,
        uint256 requiredAmount,
        uint256 duration,
        uint256 slotsAvailable,
        uint256 voucherTypeId,
        uint256 vouchersAmount
    ) external onlyOwner {
        StakeConfig memory newConfig = StakeConfig(tokenAddress, isEnabled, requiredAmount, duration, slotsAvailable, slotsAvailable, voucherTypeId, vouchersAmount);
        stakeConfig[stakeConfigIndex] = newConfig;
        stakeConfigIndex++;
    }

    function editStakeConfig(
        uint256 configIndex,
        bool isEnabled,
        uint256 slotsAvailable
    )  external onlyOwner{
        require(stakeConfig[configIndex].slotsMax >= slotsAvailable, "StakeForVoucher: slotsMax limit");
        stakeConfig[configIndex].isEnabled = isEnabled;
        stakeConfig[configIndex].slotsAvailable = slotsAvailable;
    }

    function stake(uint256 configIndex) external {
        require(stakeDate[configIndex][msg.sender] == 0 && !unstaked[configIndex][msg.sender], "StakeForVoucher: Only one stake per address");
        StakeConfig memory sc = stakeConfig[configIndex];
        require(sc.isEnabled, "StakeForVoucher: Staking is disabled");
        require(sc.slotsAvailable > 0, "StakeForVoucher: No available slots");
        IERC20(sc.tokenAddress).transferFrom(msg.sender, address(this), sc.requiredAmount);
        stakeDate[configIndex][msg.sender] = block.timestamp;
        stakeConfig[configIndex].slotsAvailable--;
        vouchers.mintBatch(msg.sender, sc.voucherTypeId, sc.vouchersAmount);
        emit Staked(msg.sender, configIndex);
    }

    function unstake(uint256 configIndex) external {
        uint256 userStakeDate = stakeDate[configIndex][msg.sender];
        require(userStakeDate != 0 && !unstaked[configIndex][msg.sender], "StakeForVoucher: Stake not found");
        StakeConfig memory sc = stakeConfig[configIndex];
        require(userStakeDate + sc.duration * 1 minutes < block.timestamp, "StakeForVoucher: Withdraw before end of stake period");
        unstaked[configIndex][msg.sender]=true;
        IERC20(sc.tokenAddress).transfer(msg.sender, sc.requiredAmount);
        emit Unstaked(msg.sender, configIndex);
    }

    constructor(IVouchers vouchersAddress){
        vouchers = vouchersAddress;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface IVouchers{
    function mintBatch(address to, uint256 num, uint256 tokenType) external;
}