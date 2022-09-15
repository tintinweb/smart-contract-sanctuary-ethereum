/**
 *Submitted for verification at Etherscan.io on 2022-09-15
*/

// Sources flattened with hardhat v2.11.1 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/access/[email protected]

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

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


// File contracts/OnlyAdmin.sol

pragma solidity ^0.8.0;

contract OnlyAdmin is Ownable {
    
    /* ===== STATE ===== */
    uint256 public nAdmins = 0;
    address[] public adminArray;
    mapping (address => bool) public adminTeam;
    mapping (address => bool) public previouslyApproved;

    function approveAdmin (address _admin) public onlyOwner () {
        if (!previouslyApproved[_admin]) {
            previouslyApproved[_admin] = true;
            nAdmins += 1;
            adminArray.push(_admin);
        }
        adminTeam[_admin] = true;
    } 

    function revokeAdmin (address _admin) public onlyOwner () {
        adminTeam[_admin] = false;
    }

    function revokeAllAdmins () public onlyOwner () {
        for (uint256 i = 0; i < adminArray.length; i++) {
            adminTeam[adminArray[i]] = false;
        }
        nAdmins = 0;
        delete adminArray;
    }

    modifier onlyAdmin () {
        if (msg.sender == owner()) {
            _;
        } else {
            require(adminTeam[msg.sender], "Only callable by administrator accounts");
            _;
        }
    }

}


// File contracts/interfaces/IFASTStaking.sol

pragma solidity 0.8.4;

interface IFASTStaking {
    function addReward(address rewardsToken, address distributor) external;

    function mint(address user, uint256 amount) external;

    function notifyRewardAmount(address rewardsToken, uint256 reward) external;

    function stake(uint256 amount, bool lock) external;
    
    function getReward() external;
}


// File @openzeppelin/contracts/token/ERC20/[email protected]

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


// File contracts/TeamAlloc.sol

pragma solidity ^0.8.0;




contract TeamAlloc is OnlyAdmin {

    /* ===== STATE ===== */
    uint256 public lockedAlloc; // 1000000 == 100%
    uint256 public unlockedAlloc;
    IERC20 public yToken; 
    IFASTStaking public FASTStaking;
    address public teamAddress;
    address public protocolFund; 
    uint256 public yStakingRewards;

    /* ===== CONSTRUCTOR ===== */
    constructor (
        address _yToken, 
        uint256 _lockedAlloc, 
        address _FASTStaking, 
        address _teamAddress, 
        address _protocolFund
    ) OnlyAdmin () {
        require(_lockedAlloc <= 1000000, "TeamAlloc::constructor: _lockPercent must be < 1000000");
        yToken = IERC20(_yToken);
        lockedAlloc = _lockedAlloc;
        unlockedAlloc = 1000000 - lockedAlloc;
        FASTStaking = IFASTStaking(_FASTStaking);
        teamAddress = _teamAddress;
        protocolFund = _protocolFund;
    }

    /* ===== ADMIN ===== */ 
    function setTeamAddress (address _teamAddress) public onlyOwner () {
        teamAddress = _teamAddress;
    }

    function setProtocolFundAddress (address _protocolFund) public onlyOwner () {
        protocolFund = _protocolFund;
    }

    /* ===== MUTATIVE ===== */
    // allocate to project maintenance fund and lock
    function allocate () public onlyAdmin () {
        uint256 _yBal = yToken.balanceOf(address(this)) - yStakingRewards;
        uint256 _protocolFundAmount = (_yBal * unlockedAlloc) / 1000000;
        uint256 _lockAmount = _yBal - _protocolFundAmount;

        // send y to protocolFund
        yToken.transfer(protocolFund, _protocolFundAmount);

        // lock team alloc 
        yToken.approve(address(FASTStaking), _lockAmount);
        FASTStaking.stake(_lockAmount, true);

    }

    // claim from staking
    function claimFromStaking () public onlyAdmin () {
        uint256 _preClaimY = yToken.balanceOf(address(this));
        FASTStaking.getReward();
        uint256 _yClaimed = yToken.balanceOf(address(this)) - _preClaimY;
        yStakingRewards += _yClaimed;
    }

    // distribute yield (any ERC20)
    function distributeYield (address _token, uint256 _amount) public onlyAdmin () {
        if (_token == address(yToken)) {
            require(_amount <= yStakingRewards, "TeamAlloc::distributeYield: can only claim y recieved as staking yield");
            yStakingRewards -= _amount;
        }
        IERC20(_token).transfer(teamAddress, _amount);
    }

    // distribute ETH yield
    receive() external payable {}
    
    function getEthBalance () public view returns (uint256) {
        return address(this).balance;
    }

    function distributeETH (uint256 _amount) public onlyAdmin() {
        payable(teamAddress).transfer(_amount);
    }

}