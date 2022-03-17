// SPDX-License-Identifier: MIT
// TokenX Contracts v1.0.0 (contracts/TokenTimelockController.sol)
pragma solidity ^0.8.0;

import "./TokenTimelockV2.sol";
import "../extensions/EmergencyWithdrawable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @dev TokenTimelockController, including:
 *
 *  - Ability to create {TokenTimelock} to beneficiaries by an authorized account.
 *  - Ability to query {TokenTimelock} that created by this controller.
 *  - Ability to destory {TokenTimelock} by an authorized account.
 *  - The beneficiary is allowed to claim tokens in {TokenTimelock} by themself.
 *
 * This contract uses {Ownable} to include access control capabilities.
 */
contract TokenTimelockControllerV2 is Ownable, EmergencyWithdrawable {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    IERC20 private immutable _token;
    
    address private immutable _tokenTimelockImplementation;
    address[] private _claimedTokenTimelocks;
    address[] private _destoryedTokenTimelocks;

    EnumerableSet.AddressSet private _beneficiaries;
    EnumerableSet.AddressSet private _lockedTokenTimelocks;

    mapping(address => EnumerableSet.AddressSet) private _tokenTimelocks;

    /**
     * @dev Set the ERC20 `token_` address that used with {TokenTimelock}.
     */
    constructor(IERC20 token_) {
        _token = token_;
        _tokenTimelockImplementation = address(new TokenTimelockV2());
    }

    /**
     * @dev Emitted when {TokenTimelock} has created.
     */
    event TokenTimelockCreated(TokenTimelockV2 tokenTimelock, address beneficiary, uint256 releasedTime, uint256 amount);
    
    /**
     * @dev Emitted when {TokenTimelock} has claimed.
     */
    event TokenTimelockClaimed(TokenTimelockV2 tokenTimelock, address beneficiary, uint256 claimedTime, uint256 amount);

    /**
     * @dev Emitted when {TokenTimelock} has detroyed.
     */
    event TokenTimelockDestroyed(TokenTimelockV2 tokenTimelock, address beneficiary, uint256 destroyedTime, uint256 amount);

    /**
     * @dev Returns the token being held.
     */
    function token() public view virtual returns (IERC20) {
        return _token;
    }

    /**
     * @dev Returns addresses of beneficiaries in `_beneficiaries`.
     */
    function beneficiaries() public view returns (address[] memory) {
        return _beneficiaries.values();
    }

    /**
     * @dev Returns number of beneficiaries in `_beneficiaries`.
     */
    function beneficiaryCount() public view returns (uint256) {
        return _beneficiaries.length();
    }

    /**
     * @dev Returns addresses of locked {TokenTimelock} in `_lockedTokenTimelocks`.
     */
    function lockedTokenTimelock() public view returns (address[] memory) {
        return _lockedTokenTimelocks.values();
    }

    /**
     * @dev Returns number of locked {TokenTimelock} in `_lockedTokenTimelocks`.
     */
    function lockedTokenTimelockCount() public view returns (uint256) {
        return _lockedTokenTimelocks.length();
    }

    /**
     * @dev Returns addresses of claimed {TokenTimelock} in `_claimedTokenTimelocks`.
     */
    function claimedTokenTimelock() public view returns (address[] memory) {
        return _claimedTokenTimelocks;
    }

    /**
     * @dev Returns number of claimed {TokenTimelock} in `_claimedTokenTimelocks`.
     */
    function claimedTokenTimelockCount() public view returns (uint256) {
        return _claimedTokenTimelocks.length;
    }

    /**
     * @dev Returns addresses of destroyed {TokenTimelock} in `_destoryedTokenTimelocks`.
     */
    function destroyedTokenTimelock() public view returns (address[] memory) {
        return _destoryedTokenTimelocks;
    }

    /**
     * @dev Returns number of destroyed {TokenTimelock} in `_destoryedTokenTimelocks`.
     */
    function destroyedTokenTimelockCount() public view returns (uint256) {
        return _destoryedTokenTimelocks.length;
    }

    /**
     * @dev Returns beneficiary address by `index_` in `_beneficiaries`.
     */
    function getBeneficiary(uint256 index_) public view returns (address) {
        return _beneficiaries.at(index_);
    }

    /**
     * @dev Returns {TokenTimelock} address that belongs to an `beneficiary_` 
     * by `index_` in `_tokenTimelocks`.
     */
    function getTokenTimelock(address beneficiary_, uint256 index_) public view returns (address) {
        return _tokenTimelocks[beneficiary_].at(index_);
    }

    /**
     * @dev Returns number of {TokenTimelock} that belongs to an `beneficiary_` 
     * in `_tokenTimelocks`.
     */
    function getTokenTimelockCount(address beneficiary_) public view returns (uint256) {
        return _tokenTimelocks[beneficiary_].length();
    }

    /**
     * @dev Returns release time of `tokenTimelock_` address.
     *
     * Note that release time is a Unix timestamp.
     */
    function getReleaseTime(address tokenTimelock_) public view returns (uint256) {
        TokenTimelockV2 tokenTimelock = TokenTimelockV2(tokenTimelock_);
        return tokenTimelock.releaseTime();
    }

    /**
     * @dev Returns {TokenTimelock} informations `address`, `claimable`, `releaseTime`, `balance` 
     * by `tokenTimelock_` address.
     */
    function getTokenTimelockInfo(address tokenTimelock_) public view returns (address, bool, uint256, uint256) {
        TokenTimelockV2 tokenTimelock = TokenTimelockV2(tokenTimelock_);

        uint256 releaseTime = tokenTimelock.releaseTime();
        uint256 balance = token().balanceOf(address(tokenTimelock));

        bool claimable = false;
        if (block.timestamp >= releaseTime) {
            claimable = true;
        }

        return (address(tokenTimelock), claimable, releaseTime, balance);
    }

    /**
     * @dev Returns all {TokenTimelock} informations `addresses`, `claimables`, `releaseTimes`, `balances` 
     * that belongs to `beneficiary_`.
     */
    function getBeneficiaryTokenTimelockInfo(address beneficiary_) public view returns (
        address[] memory,
        bool[] memory,
        uint256[] memory,
        uint256[] memory)
    {
        uint256 length = getTokenTimelockCount(beneficiary_);
        bool[] memory claimables = new bool[](length);
        address[] memory addresses = new address[](length);
        uint256[] memory releaseTimes = new uint256[](length);
        uint256[] memory balances = new uint256[](length);

        for (uint256 i = 0; i < length; i++) {
            TokenTimelockV2 tokenTimelock = TokenTimelockV2(getTokenTimelock(beneficiary_, i));

            uint256 releaseTime = tokenTimelock.releaseTime();

            addresses[i] = address(tokenTimelock);
            releaseTimes[i] = releaseTime;
            balances[i] = token().balanceOf(address(tokenTimelock));

            claimables[i] = false;
            if (block.timestamp >= releaseTime) {
                claimables[i] = true;
            }
        }

        return (addresses, claimables, releaseTimes, balances);
    }

    /**
     * @dev Create a new {TokenTimelock} to `beneficiary_` that locked within `lockTime_`
     * for `amount_` tokens.
     *
     * Emits a {TokenTimelockCreated} event.
     *
     * Requirements:
     *
     * - the caller must be owner.
     *
     * NOTE that `lockTime_` is a second unit.
     */
    function createTokenTimelock(address beneficiary_, uint256 lockTime_, uint256 amount_) public onlyOwner {
        require(beneficiary_ != address(0), "TokenTimelockController: beneficiary cannot be zero address");
        require(beneficiary_ != address(this), "TokenTimelockController: beneficiary cannot be this contract address");
        require(amount_ > 0, "TokenTimelockController: amount must greater than zero");

        uint256 controllerBalance = _token.balanceOf(address(this));
        require(controllerBalance >= amount_, "TokenTimelockController: transfer amount exceeds balance");

        uint256 releaseTime = block.timestamp + lockTime_;

        address clone = Clones.clone(_tokenTimelockImplementation);
        TokenTimelockV2(clone).initialize(token(), beneficiary_, releaseTime, address(this));

        token().safeTransfer(clone, amount_);

        if (!_beneficiaries.contains(beneficiary_)) {
            _beneficiaries.add(beneficiary_);
        }

        _lockedTokenTimelocks.add(clone);
        _tokenTimelocks[beneficiary_].add(clone);

        emit TokenTimelockCreated(TokenTimelockV2(clone), beneficiary_, releaseTime, amount_);
    }

    /** 
     * @dev Claims tokens that are locked on `tokenTimelock_` {TokenTimelock} address.
     */
    function _claim(address tokenTimelock_) private returns (TokenTimelockV2, address, uint256) {
        TokenTimelockV2 tokenTimelock = TokenTimelockV2(tokenTimelock_);

        address beneficiary = tokenTimelock.beneficiary();
        uint256 balance = token().balanceOf(address(tokenTimelock));

        tokenTimelock.release();

        return (tokenTimelock, beneficiary, balance);
    }

    /**
     * @dev Claims released tokens on `tokenTimelock_` {TokenTimelock}.
     *
     * Emits a {TokenTimelockClaimed} event.
     *
     * Requirements:
     *
     * - The locked tokens on {TokenTimelock} must be released.
     */
    function claim(address tokenTimelock_) public {
        bool avaialble = _lockedTokenTimelocks.contains(tokenTimelock_);
        require(avaialble, "TokenTimelockController: TokenTimelock is not available");

        (TokenTimelockV2 tokenTimelock, address beneficiary, uint256 amount) = _claim(tokenTimelock_);

        _claimedTokenTimelocks.push(tokenTimelock_);
        _lockedTokenTimelocks.remove(tokenTimelock_);
        _tokenTimelocks[beneficiary].remove(tokenTimelock_);

        emit TokenTimelockClaimed(tokenTimelock, beneficiary, block.timestamp, amount);
    }

    /**
     * @dev Claims released tokens on {TokenTimelock}
     * by `beneficiary_` address and `index_` in `_tokenTimelocks` enumerable sets.
     *
     * Emits a {TokenTimelockClaimed} event.
     *
     * Requirements:
     *
     * - The locked tokens on {TokenTimelock} must be released.
     */
    function claim(address beneficiary_, uint256 index_) public {
        (TokenTimelockV2 tokenTimelock, address beneficiary, uint256 amount) = _claim(getTokenTimelock(beneficiary_, index_));

        _claimedTokenTimelocks.push(address(tokenTimelock));
        _lockedTokenTimelocks.remove(address(tokenTimelock));
        _tokenTimelocks[beneficiary].remove(address(tokenTimelock));

        emit TokenTimelockClaimed(tokenTimelock, beneficiary, block.timestamp, amount);
    }

    /** @dev Claims all released {TokenTimelock} tokens in `_lockedTokenTimelocks` enumerable sets.
     *
     * Emits a {TokenTimelockClaimed} event.
     *
     * WARNING: This operation quite expensive.
     */
    function claimAll() public {
        uint256 length = _lockedTokenTimelocks.length();
        address[] memory addresses = new address[](length);
        address[] memory claimedTokenTimelocks = new address[](length);

        for (uint256 i = 0; i < length; i++) {
            TokenTimelockV2 tokenTimelock = TokenTimelockV2(_lockedTokenTimelocks.at(i));
            addresses[i] = tokenTimelock.beneficiary();

            if (block.timestamp >= tokenTimelock.releaseTime()) {
                (, , uint256 amount) = _claim(address(tokenTimelock));

                claimedTokenTimelocks[i] = (address(tokenTimelock));

                emit TokenTimelockClaimed(tokenTimelock, addresses[i], block.timestamp, amount);
            }
        }

        for (uint256 i = 0; i < claimedTokenTimelocks.length; i++) {
            if (claimedTokenTimelocks[i] != address(0)) {
                _claimedTokenTimelocks.push(claimedTokenTimelocks[i]);
                _lockedTokenTimelocks.remove(claimedTokenTimelocks[i]);
                _tokenTimelocks[addresses[i]].remove(claimedTokenTimelocks[i]);
            }
        }
    }

    /** @dev Claims all released {TokenTimelock} tokens of `beneficiary_` in `_tokenTimelocks` enumerable sets.
     *
     * Emits a {TokenTimelockClaimed} event.
     */
    function claimBeneficiaryAll(address beneficiary_) public {
        require(_beneficiaries.contains(beneficiary_), "TokenTimelockController: invalid beneficiary address");

        uint256 length = getTokenTimelockCount(beneficiary_);
        address[] memory claimedTokenTimelocks = new address[](length);

        for (uint256 i = 0; i < length; i++) {
            TokenTimelockV2 tokenTimelock = TokenTimelockV2(getTokenTimelock(beneficiary_, i));

            if (block.timestamp >= tokenTimelock.releaseTime()) {
                (, , uint256 amount) = _claim(address(tokenTimelock));

                claimedTokenTimelocks[i] = (address(tokenTimelock));

                emit TokenTimelockClaimed(tokenTimelock, beneficiary_, block.timestamp, amount);
            }
        }

        for (uint256 i = 0; i < claimedTokenTimelocks.length; i++) {
            if (claimedTokenTimelocks[i] != address(0)) {
                _claimedTokenTimelocks.push(claimedTokenTimelocks[i]);
                _lockedTokenTimelocks.remove(claimedTokenTimelocks[i]);
                _tokenTimelocks[beneficiary_].remove(claimedTokenTimelocks[i]);
            }
        }
    }

    /** 
     * @dev Destory `tokenTimelock_` {TokenTimelock} and transfer locked token to the controller.
     */
    function _destroy(address tokenTimelock_) private returns (TokenTimelockV2, address, uint256) {
        TokenTimelockV2 tokenTimelock = TokenTimelockV2(tokenTimelock_);

        address beneficiary = tokenTimelock.beneficiary();
        uint256 balance = token().balanceOf(address(tokenTimelock));

        tokenTimelock.destroy();

        return (tokenTimelock, beneficiary, balance);
    }

    /** 
     * @dev Destory `tokenTimelock_` {TokenTimelock} and transfer locked tokens to the controller.
     *
     * Emits a {TokenTimelockDestroyed} event.
     *
     * Requirements:
     *
     * - The locked tokens on {TokenTimelock} must represent in `_lockedTokenTimelocks` enumerable sets.
     */
    function destroy(address tokenTimelock_) public onlyOwner {
        bool avaialble = _lockedTokenTimelocks.contains(tokenTimelock_);
        require(avaialble, "TokenTimelockController: TokenTimelock is not available");

        (TokenTimelockV2 tokenTimelock, address beneficiary, uint256 amount) = _destroy(tokenTimelock_);

        _destoryedTokenTimelocks.push(tokenTimelock_);
        _lockedTokenTimelocks.remove(address(tokenTimelock_));
        _tokenTimelocks[beneficiary].remove(address(tokenTimelock));

        emit TokenTimelockDestroyed(tokenTimelock, beneficiary, block.timestamp, amount);
    }

    /**
     * @dev Destroy {TokenTimelock} by `beneficiary_` address 
     * and `index_` in `_tokenTimelocks` enumerable sets
     * and transfer locked tokens to the controller.
     *
     * Emits a {TokenTimelockDestroyed} event.
     *
     * Requirements:
     *
     * - The locked tokens on {TokenTimelock} must represent in `_lockedTokenTimelocks` enumerable sets.
     */
    function destroy(address beneficiary_, uint256 index_) public onlyOwner {
        (TokenTimelockV2 tokenTimelock, address beneficiary, uint256 amount) = _destroy(getTokenTimelock(beneficiary_, index_));

        _destoryedTokenTimelocks.push(address(tokenTimelock));
        _lockedTokenTimelocks.remove(address(tokenTimelock));
        _tokenTimelocks[beneficiary].remove(address(tokenTimelock));

        emit TokenTimelockDestroyed(tokenTimelock, beneficiary, block.timestamp, amount);
    }

    /** @dev Destroys all {TokenTimelock} in `_lockedTokenTimelocks` enumerable sets
     * and transfer all locked tokens to the controller.
     *
     * Emits a {TokenTimelockDestroyed} event.
     *
     * WARNING: This operation quite expensive.
     */
    function destroyAll() public onlyOwner {
        uint256 length = lockedTokenTimelockCount();
        address[] memory addresses = new address[](length);
        address[] memory destoryedTokenTimelocks = new address[](length);

        for (uint256 i = 0; i < length; i++) {
            TokenTimelockV2 tokenTimelock = TokenTimelockV2(_lockedTokenTimelocks.at(i));

            (, , uint256 amount) = _destroy(address(tokenTimelock));

            addresses[i] = tokenTimelock.beneficiary();
            destoryedTokenTimelocks[i] = (address(tokenTimelock));

            emit TokenTimelockDestroyed(tokenTimelock, addresses[i], block.timestamp, amount);
        }

        for (uint256 i = 0; i < destoryedTokenTimelocks.length; i++) {
            _destoryedTokenTimelocks.push(destoryedTokenTimelocks[i]);
            _lockedTokenTimelocks.remove(destoryedTokenTimelocks[i]);
            _tokenTimelocks[addresses[i]].remove(destoryedTokenTimelocks[i]);
        }
    }

    /** @dev Destroys all {TokenTimelock} of `beneficiary_` in `_tokenTimelocks` enumerable sets
     * and transfer locked tokens to the controller.
     *
     * Emits a {TokenTimelockDestroyed} event.
     */
    function destroyBeneficiaryAll(address beneficiary_) public onlyOwner {
        require(_beneficiaries.contains(beneficiary_), "TokenTimelockController: invalid beneficiary address");

        uint256 length = getTokenTimelockCount(beneficiary_);
        address[] memory destoryedTokenTimelocks = new address[](length);

        for (uint256 i = 0; i < length; i++) {
            TokenTimelockV2 tokenTimelock = TokenTimelockV2(getTokenTimelock(beneficiary_, i));

            (, , uint256 amount) = _destroy(address(tokenTimelock));

            destoryedTokenTimelocks[i] = (address(tokenTimelock));

            emit TokenTimelockDestroyed(tokenTimelock, beneficiary_, block.timestamp, amount);
        }

        for (uint256 i = 0; i < destoryedTokenTimelocks.length; i++) {
            _destoryedTokenTimelocks.push(destoryedTokenTimelocks[i]);
            _lockedTokenTimelocks.remove(destoryedTokenTimelocks[i]);
            _tokenTimelocks[beneficiary_].remove(destoryedTokenTimelocks[i]);
        }
    }

    /**
     * @dev Withdraw ERC20 `token` from (this) contract to the owner.
     *
     * See {EmergencyWithdrawable-_emergencyWithdrawToken}.
     *
     * Requirements:
     *
     * - the caller must be owner.
     */
    function emergencyWithdrawToken(address token_) public onlyOwner {
        _emergencyWithdrawToken(owner(), token_);
    }
}

// SPDX-License-Identifier: MIT
// Forked OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/utils/TokenTimelock.sol)
// TokenX Contracts v1.0.0 (contracts/TokenTimelock.sol)
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @dev A token holder contract that will allow a beneficiary to extract the
 * tokens after a given release time.
 *
 * Useful for simple vesting schedules like "advisors get all of their tokens
 * after 1 year".
 * 
 * Implementation with
 * - Ability to force transfer locked token (AKA destory timelock) to an authorized account.
 */
contract TokenTimelockV2 is Ownable, Initializable {
    using SafeERC20 for IERC20;

    // ERC20 basic token contract being held
    IERC20 private _token;

    // beneficiary of tokens after they are released
    address private _beneficiary;

    // timestamp when token release is enabled
    uint256 private _releaseTime;

    // status that determined the token timelock has destroyed
    bool private _destroyed;

    /**
     * @dev Deploys a timelock instance that is able to hold the token specified, and will only release it to
     * `beneficiary_` when {release} is invoked after `releaseTime_`. The release time is specified as a Unix timestamp
     * (in seconds).
     */
    function initialize(IERC20 token_, address beneficiary_, uint256 releaseTime_, address owner_) public virtual initializer {
        __TokenTimelockV2_init_unchained(token_, beneficiary_, releaseTime_, owner_);
    }

    function __TokenTimelockV2_init_unchained(IERC20 token_, address beneficiary_, uint256 releaseTime_, address owner_) internal onlyInitializing {
        require(releaseTime_ > block.timestamp, "TokenTimelock: release time is before current time");
        _token = token_;
        _beneficiary = beneficiary_;
        _releaseTime = releaseTime_;

        _transferOwnership(owner_);
    }

    /**
     * @dev Returns the token being held.
     */
    function token() public view virtual returns (IERC20) {
        return _token;
    }

    /**
     * @dev Returns the beneficiary that will receive the tokens.
     */
    function beneficiary() public view virtual returns (address) {
        return _beneficiary;
    }

    /**
     * @dev Returns the time when the tokens are released in seconds since Unix epoch (i.e. Unix timestamp).
     */
    function releaseTime() public view virtual returns (uint256) {
        return _releaseTime;
    }

    /**
     * @dev Returns the status that determined the token timelock has destroyed.
     */
    function destroyed() public view virtual returns (bool) {
        return _destroyed;
    }

    /**
     * @dev Transfers tokens held by the timelock to the beneficiary. Will only succeed if invoked after the release
     * time.
     */
    function release() public virtual onlyOwner {
        require(!destroyed(), "TokenTimelock: token timelock has destroyed");
        require(block.timestamp >= releaseTime(), "TokenTimelock: current time is before release time");

        uint256 amount = token().balanceOf(address(this));
        require(amount > 0, "TokenTimelock: no tokens to release");

        token().safeTransfer(beneficiary(), amount);
    }

    /**
     * @dev Destroy the token timelock and transfers tokens held by the timelock to the owner.
     */
    function destroy() public virtual onlyOwner {
        require(!destroyed(), "TokenTimelock: already destroyed");

        uint256 amount = token().balanceOf(address(this));

        if (amount > 0) {
            token().safeTransfer(owner(), amount);
        }

        _destroyed = true;
    }
}

// SPDX-License-Identifier: MIT
// TokenX Contracts v1.0.0 (extensions/EmergencyWithdrawable.sol)
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @dev Contract module which allows children to implement an emergency withdraw
 * mechanism that can be called by an authorized account.
 *
 * This module is used through inheritance.
 */
abstract contract EmergencyWithdrawable {
    using SafeERC20 for IERC20;

    /**
     * @dev Emitted when emergeny withdraw ether has called.
     */
    event EmergencyWithdrawEther(address beneficiary, uint256 amount);

    /**
     * @dev Emitted when emergeny withdraw token has called.
     */
    event EmergencyWithdrawToken(address token, address beneficiary, uint256 amount);

    /**
     * @dev Withdraw ether from (this) contract to `beneficiary`.
     */
    function _emergencyWithdrawEther(address payable beneficiary) internal virtual {
        uint256 balance = address(this).balance;
        require(balance > 0, "EmergencyWithdrawable: out of balance");

        (bool succeed,) = beneficiary.call{value: balance}("");
        require(succeed, "EmergencyWithdrawable: failed to withdraw Ether");

        emit EmergencyWithdrawEther(beneficiary, balance);
    }

    /**
     * @dev Withdraw token from (this) contract to `beneficiary`.
     */
    function _emergencyWithdrawToken(address beneficiary, address token) internal virtual {
        uint256 balance = IERC20(token).balanceOf(address(this));

        IERC20(token).safeTransfer(beneficiary, balance);

        emit EmergencyWithdrawToken(token, beneficiary, balance);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
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
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !Address.isContract(address(this));
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
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