/**
 *Submitted for verification at Etherscan.io on 2023-06-12
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

/// @title A Token Locker contract.
/// @author Doe John.
/// @notice You can use this contract to lock X amount of tokens for Y amount of time.
/// @dev Simple and optimized functions for minimum gas spend.
/// @dev Doesn't emit events on purpose to save gas!
contract Locker {
    /// @notice Lock contains tokenholder address and unlock timestamp
    /// @param holder The token holder sub-contract address
    /// @param endTime The unlock timestamp
    struct Lock {
        address holder;
        //Block.timestamp to reach uint64: Sun Jul 21 2554 23:34:33 GMT+0000
        //Can scale down to uint64 to fit 1 slot
        uint64 endTime;
    }

    /// @notice User Address To tokenAddress To Lock
    mapping(address => mapping(address => Lock)) public lockers;
    /// @notice User Address To List of Tokens Locked
    mapping(address => address[]) public addressToTokensLocked;

    /// @dev Owner used for serviceFee withdraw
    address owner = msg.sender;

    /// @dev Custom Errors
    error InsufficientServiceFeePayment();
    error ZeroTransferAmount();
    error TryingToUnlockBeforeUnlockTime();
    error WantToUnlockMoreThanLocked();
    error TransferFromCallFailed();
    error MustHaveALocker();

    /// @notice Lock 'amount' of token for 'duration' time.
    /// @param token The token address to be locked.
    /// @param amount The amount of 'token' to be locked.
    /// @param duration The lock duration in seconds.
    function lockTokens(
        address token,
        uint128 amount,
        uint64 duration
    ) external payable {
        //Service fee must be 0.02 ETH
        if (msg.value != 2e16) revert InsufficientServiceFeePayment();

        //Does the user have a token holder for this token address already ?
        if (lockers[msg.sender][token].endTime != 0) {
            //User has already a tokenHolder
            //If duration is not 0. This function serves also as duration extend
            if (duration != 0) lockers[msg.sender][token].endTime += duration;

            //Transfer tokens to the tokenHolder
            safeTransferFrom(
                token,
                msg.sender,
                lockers[msg.sender][token].holder,
                amount
            );
        } else {
            //User doesn't have a tokenHolder
            //Create new tokenHolder
            address holder = address(new tokenHolder(token));

            //Update State | Register duration and tokenHolder for this token address
            lockers[msg.sender][token].endTime =
                uint64(block.timestamp) +
                duration;
            lockers[msg.sender][token].holder = holder;
            addressToTokensLocked[msg.sender].push(token);

            //Transfer tokens to the tokenHolder
            safeTransferFrom(token, msg.sender, holder, amount);
        }
    }

    /// @notice Unlock 'amount' of 'token' from an already existing locker.
    /// @dev Unlock works with token.balanceOf(holder) for always accurate balances.
    /// @param token The token address to be locked.
    /// @param amount The amount of 'token' to be locked.s
    function unlockTokens(address token, uint256 amount) external {
        //Get the tokenHolder address for 'token'
        address lockHolder = lockers[msg.sender][token].holder;

        //Expiry check
        if (uint64(block.timestamp) <= lockers[msg.sender][token].endTime)
            revert TryingToUnlockBeforeUnlockTime();
        //Amount check
        if (amount > IERC20(token).balanceOf(lockHolder))
            revert WantToUnlockMoreThanLocked();

        //Transfer tokens out from tokenHolder to msg.sender
        safeTransferFrom(token, lockHolder, msg.sender, amount);
    }

    /// @notice SafeTransferFrom function copied from Openzeppelin
    /// @dev Reverts on failed call OR return empty return data OR return data = "false"
    /// @param token The token address to be transferred.
    /// @param from The transfer sender address. (Tokens will be taken from this)
    /// @param to The transfer recipient address. (Tokens will be give to this)
    /// @param amount The amount of 'token' to be transferred.
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 amount
    ) internal {
        //If transfer amount is 0
        if (amount == 0) revert ZeroTransferAmount();

        //Execute the transferFrom call
        (bool suc, bytes memory returndata) = address(token).call(
            abi.encodeCall(IERC20.transferFrom, (from, to, amount))
        );

        //If call failed
        if (!suc) revert TransferFromCallFailed();

        //If return data is empty OR return data is bool and it is false
        require(
            returndata.length == 0 || abi.decode(returndata, (bool)),
            "SafeERC20: ERC20 operation did not succeed"
        );
    }

    /// @notice Extend duration of already existing locker for 'token' with 'plusDuration' seconds.
    /// @dev Must have a locker to interact with this function.
    /// @param token The token address for which locker duration will be extended.
    /// @param plusDuration The duration in seconds which is added to locker unlock timestamp.
    function extendLock(address token, uint64 plusDuration) external {
        //Check if user has a locker for this 'token'
        if (lockers[msg.sender][token].endTime == 0) revert MustHaveALocker();

        //Update state
        lockers[msg.sender][token].endTime += plusDuration;
    }

    /// @notice Transfers the collected service fees to contract creator
    /// @dev Most likely will remain EOA
    function takeServiceFee() external {
        owner.call{value: address(this).balance}("");
    }

    
    //Utils
    function getLocker(address who, address token)
        external
        view
        returns (
            address holderContract,
            uint128 endTime,
            uint256 lockedAmt
        )
    {
        return (
            lockers[who][token].holder,
            lockers[who][token].endTime,
            IERC20(token).balanceOf(lockers[who][token].holder)
        );
    }

    function getAllTokensLockedByUser(address user)
        external
        view
        returns (address[] memory tokensLocked)
    {
        tokensLocked = addressToTokensLocked[user];
    }

    function getAllLockersForAddress(address user)
        external
        view
        returns (
            string[] memory tokenNames,
            address[] memory tokensForAdr,
            address[] memory holderContract,
            uint128[] memory endTime,
            uint256[] memory lockedAmt
        )
    {
        tokensForAdr = this.getAllTokensLockedByUser(user);
        uint128 size = uint128(tokensForAdr.length);
        holderContract = new address[](size);
        endTime = new uint128[](size);
        lockedAmt = new uint256[](size);
        tokenNames = new string[](size);
        for (uint128 i; i < size; ) {
            (holderContract[i], endTime[i], lockedAmt[i]) = this.getLocker(
                user,
                tokensForAdr[i]
            );
            tokenNames[i] = IERC20(tokensForAdr[i]).name();
            unchecked {
                ++i;
            }
        }
    }

    function durationUtil(uint256 val, uint256 flag)
        external
        pure
        returns (uint256 dur)
    {
        if (flag == 1) {
            dur = val * 1;
        }
        if (flag == 2) {
            dur = val * 1 minutes;
        }
        if (flag == 3) {
            dur = val * 1 hours;
        }
        if (flag == 4) {
            dur = val * 1 days;
        }
        if (flag == 5) {
            dur = val * 30 days;
        }
        if (flag == 6) {
            dur = val * 12 * 30 days;
        }
    }

    function getSecondsTillUnlock(address token, address who)
        external
        view
        returns (uint256 left)
    {
        return
            lockers[who][token].endTime >= uint128(block.timestamp)
                ? lockers[who][token].endTime - uint128(block.timestamp)
                : 0;
    }
}

/// @title Token Holder sub-contract.
/// @notice Created by Token Locker for each new token address locked per user.
/// @notice A token holder is connected to token address. If user already has a token holder for token address, a new one won't be created.
/// @dev Approves deployer (Token Locker) with type(uint256).max value. This ensures that Token Locker can transfer tokens out upon 'unlockTokens'.
contract tokenHolder {
    /// @notice Doesn't support non-standard approval tokens such as USDT and thats fine
    /// @dev Token Locker operates with token.balanceOf(tokenHolder) for always accurate balances
    /// @dev Suppports all kinds of tokens - positive/negative rebases, reflection tokens and such
    /// @param _t The token address for which this contract is created for
    constructor(address _t) payable {
        IERC20(_t).approve(msg.sender, type(uint256).max);
    }
}

//////////Interface
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function name() external view returns (string memory name_);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}