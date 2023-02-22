// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./ERC20.sol";
///////////////////////////////////////////////
// QANX STARTS HERE, OPENZEPPELIN CODE ABOVE //
///////////////////////////////////////////////

contract QANX is ERC20 {

    /// @notice Represents a lock which might be applied on an address
    /// @dev Lock logic is described in the _applyLock() method
    struct Lock {
        uint256 tokenAmount;    /// How many tokens are locked
        uint256 unlockPerSec;   /// How many tokens are unlockable each sec from hl -> sl
        uint64 hardLockUntil;   /// Until when no locked tokens can be accessed
        uint64 softLockUntil;   /// Until when locked tokens can be gradually released
        uint64 lastUnlock;      /// Last gradual unlock time (softlock period)
        uint64 allowedHops;     /// How many transfers left with same lock params
    }

    /// @notice Cheque signer address
    /// @dev This is compared against a recovered secp256k1 signature
    address private chequeSigner;

    /// @notice This maps used cheques so they can not be encashed twice
    /// @dev Ensures that every unique cheque paramset can be encashed once
    mapping (bytes32 => bool) private chequesEncashed;

    /// @notice This maps lock params to certain addresses which received locked tokens
    /// @dev Lookup table for locks assigned to specific addresses
    mapping (address => Lock) private _locks;    

    /// @notice Emitted when a lock is applied on an account
    /// @dev The first param is indexed which makes it easy to listen to locks applied to a specific account
    event LockApplied(address indexed account, uint256 amount, uint64 hardLockUntil, uint64 softLockUntil, uint64 allowedHops);

    /// @notice Emitted when a lock is removed from an account
    /// @dev The account param is indexed which makes it easy to listen to locks getting removed from a specific account
    event LockRemoved(address indexed account);

    /// @notice Emitted when a lock amount is decreased on an account
    /// @dev The first param is indexed which makes it easy to listen to locked amount getting decreased on a specific account
    event LockDecreased(address indexed account, uint256 amount);

    /// @notice Emitted when a the permitted cheque signer address is changed
    /// @dev This will be new address the ecrecover result is compared against
    event ChequeSignerUpdated(address signer);

    /// @notice Initialize an erc20 token based on the openzeppelin version
    /// @dev Sets the initial cheque signer to the deployer address and mints total supply to the contract itself
    constructor() ERC20("QANX Token", "QANX") {

        // Assign deployer as cheque signer initially
        chequeSigner = msg.sender;

        // Initially mint total supply to contract itself
        _mint(address(this), 3_333_333_000 * 1e18);
    }

    /// @notice Refuse any kind of payment to the contract
    /// @dev This is the implicit default behavior, it just exists for verbosity
    receive() external payable {
        revert();
    }

    /// @notice Refuse any kind of payment to the contract
    /// @dev This is the implicit default behavior, it just exists for verbosity
    fallback() external payable {
        revert();
    }

    /// @notice Ability to update cheque signer
    /// @dev Make sure to externally double check the new cheque signer address!
    /// @param _newChequeSigner The address which new cheque signatures will be compared against from now
    function setChequeSigner(address _newChequeSigner) external {
        require(msg.sender == chequeSigner && _newChequeSigner != address(0), "Invalid cheque signer");
        chequeSigner = _newChequeSigner;
        emit ChequeSignerUpdated(chequeSigner);
    }

    /// @notice Method to encash a received cheque
    /// @dev Ability to encash offline signed cheques using on-chain signature verification.
    /// Please note that cheques are expected to be one cheque per address, so using CID as
    /// a nonce is intentional and works as designed.
    /// @param beneficiary The address which will receive the tokens
    /// @param amount The amount of tokens the beneficiary will receive
    /// @param hardLockUntil The UNIX timestamp until which the tokens are not transferable
    /// @param softLockUntil The UNIX timestamp until which the tokens are gradually unlockable
    /// @param allowedHops How many times the locked tokens can be transferred further
    /// @param signature The secp256k1 signature of CID as per EIP-2098 (r + _vs)
    function encashCheque(address beneficiary, uint256 amount, uint64 hardLockUntil, uint64 softLockUntil, uint64 allowedHops, bytes32[2] calldata signature) external {

        // Calculate cheque id
        bytes32 cid = keccak256(abi.encode(block.chainid, address(this), beneficiary, amount, hardLockUntil, softLockUntil, allowedHops));

        // Verify cheque signature
        require(verifyChequeSignature(cid, signature), "Cheque signature is invalid!");

        // Make sure this cheque was not encashed before
        require(!chequesEncashed[cid], "This cheque was encashed already!");

        // Mark cheque as encashed
        chequesEncashed[cid] = true;
        
        // If any lock related params were defined as non-zero
        if (hardLockUntil > 0) {

            // Encash through a locked transfer
            _transferLocked(address(this), beneficiary, amount, hardLockUntil, softLockUntil, allowedHops);
            return;
        }

        // Otherwise encash using a normal transfer
        _transfer(address(this), beneficiary, amount);
    }

    /// @notice Transfer function with lock parameters
    /// @dev Wraps the _transferLocked internal method
    /// @param recipient The address whose locked balance will be credited
    /// @param amount The amount which will be credited to the recipient address
    /// @param hardLockUntil The UNIX timestamp until which the tokens are not transferable
    /// @param softLockUntil The UNIX timestamp until which the tokens are gradually unlockable
    /// @param allowedHops How many times the locked tokens can be transferred further
    /// @return Success
    function transferLocked(address recipient, uint256 amount, uint64 hardLockUntil, uint64 softLockUntil, uint64 allowedHops) external returns (bool) {
        _transferLocked(_msgSender(), recipient, amount, hardLockUntil, softLockUntil, allowedHops);
        return true;
    }

    /// @notice Transferfrom function with lock parameters
    /// @dev Wraps the _transferLocked internal method
    /// @param sender The address whose balance will be debited
    /// @param recipient The address whose locked balance will be credited
    /// @param amount The amount which will be credited to the recipient address
    /// @param hardLockUntil The UNIX timestamp until which the tokens are not transferable
    /// @param softLockUntil The UNIX timestamp until which the tokens are gradually unlockable
    /// @param allowedHops How many times the locked tokens can be transferred further
    /// @return Success
    function transferFromLocked(address sender, address recipient, uint256 amount, uint64 hardLockUntil, uint64 softLockUntil, uint64 allowedHops) external returns (bool) {

        // Query current allowance of spender
        uint256 currentAllowance = _allowances[sender][_msgSender()];

        // If the allowance is not unlimited
        if (currentAllowance != type(uint256).max) {

            // Ensure sufficient allowance and decrease it by current amount
            require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
            unchecked {
                _approve(sender, _msgSender(), currentAllowance - amount);
            }
        }

        // Perform locked transfer
        _transferLocked(sender, recipient, amount, hardLockUntil, softLockUntil, allowedHops);
        return true;
    }

    /// @notice Unlocks all unlockable tokens of a particular account
    /// @dev Calculates the unlockable amount based on the private _locks mapping
    /// @param account The address whose tokens should be unlocked
    /// @return Success
    function unlock(address account) external returns (bool) {

        // Lookup lock
        Lock storage lock = _locks[account];

        // Calculate unlockable balance
        uint256 unlockable = unlockableBalanceOf(account);

        // Only addresses owning locked tokens and bypassed hardlock time are unlockable
        require(unlockable > 0 && lock.tokenAmount > 0, "No unlockable tokens!");

        // Set last unlock time, deduct from locked balance & credit to regular balance
        lock.lastUnlock = uint64(block.timestamp);
        lock.tokenAmount = lock.tokenAmount - unlockable;
        _balances[account] += unlockable;

        // If no more locked tokens left, remove lock object from address
        if(lock.tokenAmount == 0){
            delete _locks[account];
            emit LockRemoved(account);
        }

        // Unlock successful
        emit LockDecreased(account, unlockable);
        return true;
    }

    /// @notice Returns the locked token balance of a particular account
    /// @dev Reads the private _locks mapping to return data
    /// @param account The address whose locked balance should be read
    /// @return The number of locked tokens owned by the account
    function lockedBalanceOf(address account) external view returns (uint256) {
        return _locks[account].tokenAmount;
    }

    /// @notice Returns the unlocked token balance of a particular account
    /// @dev Reads the internal _balances mapping to return data
    /// @param account The address whose unlocked balance should be read
    /// @return The number of unlocked tokens owned by the account
    function unlockedBalanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    /// @notice Returns lock information of a given address
    /// @dev Reads a whole entry of the private _locks mapping to return data
    /// @param account The address whose lock object should be read
    /// @return The lock object of the particular account
    function lockOf(address account) external view returns (Lock memory) {
        return _locks[account];
    }

    /// @notice Return the balance of unlocked and locked tokens combined
    /// @dev This overrides the OZ version for combined output
    /// @param account The address whose total balance is looked up
    /// @return The combined (unlocked + locked) balance of the particular account
    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account] + _locks[account].tokenAmount;
    }

    /// @notice Calculates the number of unlockable tokens of a particular account
    /// @dev Dynamically calculates unlockable balance based on current block timestamp
    /// @param account The address whose unlockable balance is calculated
    /// @return The amount of tokens which can be unlocked at the current block timestamp
    function unlockableBalanceOf(address account) public view returns (uint256) {

        // Lookup lock
        Lock memory lock = _locks[account];

        // If the hardlock has not passed yet, there are no unlockable tokens
        if(block.timestamp < lock.hardLockUntil) {
            return 0;
        }

        // If the softlock period passed, all currently tokens are unlockable
        if(block.timestamp > lock.softLockUntil) {
            return lock.tokenAmount;
        }

        // Otherwise the proportional amount is unlockable
        uint256 unlockable = (block.timestamp - lock.lastUnlock) * lock.unlockPerSec;
        return lock.tokenAmount < unlockable ? lock.tokenAmount : unlockable;
    }

    /// @dev Abstract method to execute locked transfers
    /// @param sender The address whose balance will be debited
    /// @param recipient The address whose locked balance will be credited
    /// @param amount The amount which will be credited to the recipient address
    /// @param hardLockUntil The UNIX timestamp until which the tokens are not transferable
    /// @param softLockUntil The UNIX timestamp until which the tokens are gradually unlockable
    /// @param allowedHops How many times the locked tokens can be transferred further
    /// @return Success
    function _transferLocked(address sender, address recipient, uint256 amount, uint64 hardLockUntil, uint64 softLockUntil, uint64 allowedHops) internal returns (bool) {

        // Perform zero address validation
        require(recipient != address(0), "ERC20: transfer to the zero address");

        // Lookup sender balance
        uint256 sBalance = _balances[sender];

        // Lookup lock of sender and recipient
        Lock storage rLock = _locks[recipient];
        Lock storage sLock = _locks[sender];

        // Only a single set of lock parameters allowed per recipient
        if (rLock.tokenAmount > 0){
            require(
                hardLockUntil == rLock.hardLockUntil &&
                softLockUntil == rLock.softLockUntil &&
                allowedHops == rLock.allowedHops
            , "Only one lock params per address allowed!");
        }

        // Sender must have enough tokens (unlocked + locked balance combined)
        require(sBalance + sLock.tokenAmount >= amount, "Transfer amount exceeds balance");

        // If sender has enough unlocked balance, then lock params can be chosen
        if(sBalance >= amount){

            // Deduct sender balance
            unchecked {
                _balances[sender] = sBalance - amount;
            }

            // Apply lock
            return _applyLock(sender, recipient, amount, hardLockUntil, softLockUntil, allowedHops);
        }

        // Otherwise require that the chosen lock params are same / stricter (allowedhops) than the sender's
        require(
            hardLockUntil >= sLock.hardLockUntil && 
            softLockUntil >= sLock.softLockUntil && 
            allowedHops < sLock.allowedHops
            , "Only same / stricter lock params allowed!"
        );

        // If sender has enough locked balance
        if(sLock.tokenAmount >= amount){

            // Decrease locked balance of sender
            unchecked {
                sLock.tokenAmount = sLock.tokenAmount - amount;
            }

            // Apply lock
            return _applyLock(sender, recipient, amount, hardLockUntil, softLockUntil, allowedHops);
        }

        // If no conditions were met so far, deduct from the unlocked balance
        unchecked {
            _balances[sender] = sBalance - (amount - sLock.tokenAmount);
        }

        // Then spend locked balance of sender first
        sLock.tokenAmount = 0;

        // Apply lock
        return _applyLock(sender, recipient, amount, hardLockUntil, softLockUntil, allowedHops);
    }

    /// @notice Applies lock to recipient with specified params and emits a transfer event
    /// @param sender The address whose balance will be debited
    /// @param recipient The address whose locked balance will be credited
    /// @param amount The amount which will be credited to the recipient address
    /// @param hardLockUntil The UNIX timestamp until which the tokens are not transferable
    /// @param softLockUntil The UNIX timestamp until which the tokens are gradually unlockable
    /// @param allowedHops How many times the locked tokens can be transferred further
    /// @return Success
    function _applyLock(address sender, address recipient, uint256 amount, uint64 hardLockUntil, uint64 softLockUntil, uint64 allowedHops) private returns (bool) {

        // Make sure that softlock is not before hardlock
        require(softLockUntil >= hardLockUntil, "SoftLock must be >= HardLock!");

        // Make sure that hardlock is in the future
        require(hardLockUntil >= block.timestamp, "HardLock must be in the future!");

        // Make sure that the amount is increased if a lock already exists
        uint256 totalAmount;
        uint256 lockSeconds;
        uint256 unlockPerSec;
        unchecked {
            totalAmount = _locks[recipient].tokenAmount + amount;
            lockSeconds = softLockUntil - hardLockUntil;
            unlockPerSec = lockSeconds > 0 ? totalAmount / lockSeconds : 0;
        }

        // Apply lock, emit transfer event
        _locks[recipient] = Lock({
            tokenAmount: totalAmount,
            unlockPerSec: unlockPerSec,
            hardLockUntil: hardLockUntil,
            softLockUntil: softLockUntil,
            lastUnlock: hardLockUntil,
            allowedHops: allowedHops
        });
        emit LockApplied(recipient, totalAmount, hardLockUntil, softLockUntil, allowedHops);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    /// @notice Method to verify cheque signature
    /// @dev This verifies a compact secp256k1 signature as per EIP-2098
    /// @param cid The Cheque ID which is calculated deterministically based on cheque params
    /// @param signature The EIP-2098 signature which was created offline by the permitted chequeSigner
    /// @return Whether the recovered signer address matches the permitted chequeSigner
    function verifyChequeSignature(bytes32 cid, bytes32[2] memory signature) private view returns (bool) {

        // Determine s and v from vs (signature[1])
        bytes32 s = signature[1] & bytes32(0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
        uint8 v = uint8((uint256(signature[1]) >> 255) + 27);

        // Ensure valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return false;
        }

        // Recover & verify signer identity related to amount
        return ecrecover(cid, v, signature[0], s) == chequeSigner;
    }
}