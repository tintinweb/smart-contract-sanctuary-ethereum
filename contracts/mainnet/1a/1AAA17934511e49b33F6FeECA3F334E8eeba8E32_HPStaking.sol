// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import { ReentrancyGuard } from "./lib/solmate/utils/ReentrancyGuard.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Pausable } from "@openzeppelin/contracts/security/Pausable.sol";

interface IERC20 {
    function burn(uint256 amount) external;
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function mint(address _to, uint _amount) external;
}

interface IERC721 {
    function ownerOf(uint256 tokenID) external view returns (address);
    function transferFrom(address from, address to, uint256 tokenId) external;
    function balanceOf(address owner) external view returns (uint256);
}

contract HPStaking is ReentrancyGuard, Ownable, Pausable {
    constructor() {
        phaseRewardRate[1] = 1000;
        phaseRewardRate[2] = 400;
        phaseRewardRate[3] = 100;
    }
    
    /////////////////////////////////////////////////////////
    /// Global variables
    /////////////////////////////////////////////////////////
    IERC20 private _hausToken;
    IERC721 private _hausPhase;

    struct UserInfo {
        uint16[] balances;
        uint256 lastClaimedReward;
        uint256 totalClaimed;
    }

    mapping (address => UserInfo) private userInfo;
    mapping (uint256 => address) private tokenOwner;
    mapping (uint256 => uint256) private phaseRewardRate;

    event Staked(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event Claimed(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed from, uint256 amount);

    /////////////////////////////////////////////////////////////////////////////
    ///  Stake/withdraw functions
    /////////////////////////////////////////////////////////////////////////////

    /// @notice            Calculates and claims the rewards for the user
    function claimRewards() external nonReentrant returns (uint) {
        uint lastClaimed = userInfo[msg.sender].lastClaimedReward;
        require(lastClaimed > 0, "ClaimRewards: You need to stake first");

        uint timeBetweenClaims = block.timestamp - lastClaimed;
        uint pendingRewards = timeBetweenClaims * _getRateForUser(msg.sender) / 86400;

        userInfo[msg.sender].lastClaimedReward = block.timestamp;
        userInfo[msg.sender].totalClaimed += pendingRewards;
        _hausToken.mint(msg.sender, pendingRewards);
        emit Claimed(msg.sender, pendingRewards);
        return pendingRewards;
    }

    /// @notice             Stakes multiple tokens for the user and claims pending tokens if there is any
    /// @param _tokenIds    target tokens
    function stakeMultiple(uint16[] calldata _tokenIds) external nonReentrant returns (uint) {
        if (userInfo[msg.sender].lastClaimedReward == 0) userInfo[msg.sender].lastClaimedReward = block.timestamp; // If this is the user's first time interacting with the contract, initialize lastClaimedReward to the current timestamp
        if (userInfo[msg.sender].balances.length > 0) _handleClaim(_getRateForUser(msg.sender));

        emit Staked(msg.sender, _tokenIds.length);
        for(uint i; i < _tokenIds.length;) {
            _stakeNft(_tokenIds[i]);
            unchecked {
                ++i;
            }
        }
        return (block.timestamp);
    }

    /// @notice             Withdraws all owned tokens by user and claim tokens for the user
    function withdrawAll() external nonReentrant {
        uint16[] memory tokenIds = userInfo[msg.sender].balances;
        require(tokenIds.length > 0, "Withdraw: Empty balance");

        uint length = tokenIds.length;
        _handleClaim(_getRateForUser(msg.sender));
        
        for(uint i; i < length;) {
            _withdrawNft(tokenIds[i]);
            unchecked {
                ++i;
            }
        }
        emit Withdraw(msg.sender, length);
    }

    /// @notice             Withdraws multiple tokens for the user and claims pending if there is any
    /// @param _tokenIds    Target tokenIDs
    function withdrawMultiple(uint16[] calldata _tokenIds) external nonReentrant {
        require(userInfo[msg.sender].balances.length > 0, "Withdraw: Empty balance");
        _handleClaim(_getRateForUser(msg.sender));

        emit Withdraw(msg.sender, _tokenIds.length);
        for(uint i; i < _tokenIds.length;) {
            _withdrawNft(_tokenIds[i]);
            unchecked {
                ++i;
            }
        }
    }

    /// @notice      Withdraw staked tokens and give up rewards. Only use in case of emergecies
    function emergencyWithdraw() external nonReentrant whenPaused {
        uint16[] memory balance = userInfo[msg.sender].balances;
        uint256 length = balance.length;
        require(length > 0, "Withdraw: Amount must be > 0");

        // Reset internal value for user
        userInfo[msg.sender].lastClaimedReward = block.timestamp;

        emit EmergencyWithdraw(msg.sender, length);
        for(uint i; i < length;){
            _withdrawNft(balance[i]);
            unchecked {
                ++i;
            }
        }
    }

    /////////////////////////////////////////////////////////////////////////////
    ///  Internal functions
    /////////////////////////////////////////////////////////////////////////////

    /// @notice             Internal function to stake a single token for the user
    /// @param  _tokenId    Target token
    function _stakeNft(uint16 _tokenId) internal {
        require(_hausPhase.ownerOf(_tokenId) == msg.sender, "Stake: not owner of token");

        userInfo[msg.sender].balances.push(_tokenId);
        _hausPhase.transferFrom(msg.sender, address(this), _tokenId);
        tokenOwner[_tokenId] = msg.sender;
    }

    /// @notice             Internal function to withdraw a single token for the user
    /// @param _tokenId     Target token
    function _withdrawNft(uint16 _tokenId) internal {
        require(tokenOwner[_tokenId] == msg.sender, "Withdraw: not owner of token");

        _removeElement(userInfo[msg.sender].balances, _tokenId);
        delete tokenOwner[_tokenId];
        _hausPhase.transferFrom(address(this), msg.sender, _tokenId);
    }

    /// @notice             Internal function to remove element from the balance array
    /// @param _array       target array
    /// @param _element     target element of the array
    function _removeElement(uint16[] storage _array, uint256 _element) internal {
        uint256 length = _array.length;
        for (uint256 i; i < length;) {
            if (_array[i] == _element) {
                _array[i] = _array[_array.length - 1];
                _array.pop();
                break;
            }
            unchecked {
                ++i;
            }
        }
    }

    /// @notice             Internal function to get base rate for single token
    /// @param _tokenId     Target tokenId
    function _getRatePerToken(uint16 _tokenId) internal view returns(uint) {
        if (_tokenId >= 0 && _tokenId < 390) {
            return phaseRewardRate[1] * 1e18;
        } else if (_tokenId > 389 && _tokenId < 3112) {
            return phaseRewardRate[2] * 1e18;
        } else if (_tokenId > 3111) {
            return phaseRewardRate[3] * 1e18;
        } else {
            revert();
        }
    }

    /// @notice             Internal function to to get base rate for all owned tokens
    /// @param _user        Target user
    function _getRateForUser(address _user) internal view returns(uint) {
        uint16[] memory tokenIds = userInfo[_user].balances;
        uint length = tokenIds.length;
        uint totalAmount;
        for(uint i; i < length;) {
            totalAmount += _getRatePerToken(tokenIds[i]);
            unchecked {
                ++i;
            }
        }
        return totalAmount;
    }

    /// @notice             Handles claiming for functions modifying the users state
    /// @param _rate        Base rate amount for the user
    function _handleClaim(uint _rate) internal {
        uint timeBetweenClaims = block.timestamp - userInfo[msg.sender].lastClaimedReward;
        uint pendingRewards = timeBetweenClaims * _rate / 86400;

        userInfo[msg.sender].lastClaimedReward = block.timestamp;
        userInfo[msg.sender].totalClaimed += pendingRewards;
        _hausToken.mint(msg.sender, pendingRewards);
        emit Claimed(msg.sender, pendingRewards);
    }

    /// @notice             Internal function to calculate pending rewards for a user
    /// @param _user        target user
    function _calculateReward(address _user) internal view returns(uint) {
        if (userInfo[_user].balances.length == 0) return 0;
        uint timeBetweenClaims = block.timestamp - userInfo[_user].lastClaimedReward;
        uint pendingRewards = timeBetweenClaims * _getRateForUser(_user) / 86400;
        return pendingRewards;
    }

    /////////////////////////////////////////////////////////////////////////////
    ///  Getter functions
    /////////////////////////////////////////////////////////////////////////////

    /// @notice             Gets total amount of staked tokens in the contract
    function getTotalStakedTokens() external view returns(uint) {
        return _hausPhase.balanceOf(address(this));
    }

    /// @notice             Gets total amount of staked tokens by the user
    /// @param _user        Target user
    function getUserBalance(address _user) external view returns(uint){
        return userInfo[_user].balances.length;
    }

    /// @notice             Gets all tokenIds staked by the user
    /// @param _user        Target user
    function getUserStakedTokens(address _user) external view returns(uint16[] memory){
        return userInfo[_user].balances;
    }

    /// @notice             Returns the daily reward rate for the user
    /// @dev                The rate is returned with decimals, so manage in the frontend accordingly
    /// @param _user        Target user
    function getUserRewardRate(address _user) external view returns(uint) {
        return _getRateForUser(_user);
    }

    /// @notice             Calculates all pending rewards for a user. More for frontend
    /// @param _user        Target user
    function calculatePendingRewards(address _user) external view returns(uint) {
        return  _calculateReward(_user);
    }

    /// @notice             Returns the total amount earned from staking (includes pending)
    /// @param _user        Target user
    function calculateTotalAndPendingRewards(address _user) external view returns(uint) {
        return userInfo[_user].totalClaimed + _calculateReward(_user);
    }

    /// @notice             Returns the amount of tokens each phase version yields daily
    /// @param  _version    Version of the hausphase
    function getPhaseRewardRate(uint _version) external view returns(uint) {
        return phaseRewardRate[_version];
    }

    /////////////////////////////////////////////////////////////////////////////
    ///  Owner functions
    /////////////////////////////////////////////////////////////////////////////

    /// @notice                     Sets the hausPhase contract
    /// @param _contract            Target ERC721 contract
    function setHausPhaseContract(address _contract) external onlyOwner {
        _hausPhase = IERC721(_contract);
    }

    /// @notice                     Sets the hausToken contract
    /// @param _contract            Target ERC20 contract
    function setHausTokenContract(address _contract) external onlyOwner {
        _hausToken = IERC20(_contract);
    }

    /// @notice                     Set the daily reward rate for hausphases
    /// @dev                        Note that changing this value will affect unclaimed rewards for every user
    /// @param _phaseVersion        The hausphase version
    /// @param _amount              The amount of hausTokens that will accumulate daily              
    function setRewardRate(uint _phaseVersion, uint _amount) external onlyOwner {
        require(_phaseVersion > 0 && _phaseVersion < 4, "Incorrect phase version");
        phaseRewardRate[_phaseVersion] = _amount;
    }

    /// @notice                     Pause contract.Allows calling emergency withdraw
    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    /// @notice                     Unpause contract
    function unpause() external onlyOwner whenPaused {
        _unpause();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

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
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 private locked = 1;

    modifier nonReentrant() virtual {
        require(locked == 1, "REENTRANCY");

        locked = 2;

        _;

        locked = 1;
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