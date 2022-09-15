/**
 *Submitted for verification at Etherscan.io on 2022-09-15
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/**
 * @dev EtherSwap is a contract for swapping Ether across chains.
 *
 *
 * This contract should be deployed on the chains you want to swap Ether on.
 *
 *
 * How does a swap work?
 *
 * A user would announce his intention to swap Ether on a chain by calling the
 * contract's overloaded {commit} function with:
 *  - `msg.value` equal to the contract's `fee` + `_payout`
 *  - `_expectedAmount` the expected amount of ether to receive on the target
 *     chain
 *  - `_lockTimeSec` the duration the swap offer is valid
 *  - `_secretHash` the hash of the secret that will be revealed to claim the
 *    swap
 *  - `_payout` the amount of ether to be paid to the counterparty claiming the
 *    swap
 *  - `_recipient` either set to the ZERO_ADDRESS (if counterparty is unknown) or
 *    to the address of the counterparty
 *
 * A counterparty that wants to match this trade would first have to check
 * whether the duration of the offer is enough for him to complete the swap.
 * If so, he would call the {changeRecipient} function to designate himself as
 * the recipient of the funds locked for this trade.
 *
 * Then he would call the {commit} function on the target chain with:
 *  - `msg.sender` set to the same address that was used in `changeRecipient`
 *  - `_recipient` set to the user who created the swap on the source chain
 *  - `_expectedAmount` expected amount of ether to receive should be set to the
 *    amount of ether locked in source chain swap
 *  - `_swapEndTimestamp` the duration should be set to a value lower than the
 *    source swap's endTimeStamp (if source endTimeStamp is bigger than
 *    recipientChangeLockDuration, the endTimestamp should be set to a value
 *    lower than recipientChangeLockDuration)
 *  - `_hashedSecret` should be set to the same value as the source swap's
 *    `_hashedSecret`.
 *
 * Once the target swap is created, the user who created the source swap would
 * make sure that the target swap is created with the expected params and then
 * call the {claim} function on the target chain with the secret that was used
 * to create the source swap. If the secret is correct the user would  receive
 * the amount of ether locked on the target chain.
 *
 * Now the counterparty knows the secret and can call the `claim` function on
 * the source chain with it. This call should happen within the endTimestamp
 * of the source swap. If that is the case the counterparty would receive the
 * amount of ether locked on the source chain. If the counterparty calls the
 * {claim} function after the endTimestamp of the source swap has passed he
 * won't receive any funds.
 *
 * ATTENTION: A counterparty matching a swap should make sure to have enough
 * time to submit the proof once it is being revealed by the user. Failure to
 * submit the {claim} transaction in time would result in the counterparty not
 * receiving any funds on the source chain.
 *
 * How does a refund work?
 *
 * If a swap didn't occur, once the endTimestamp of the swap has passed, the
 * parties can call the {refund} function to receive their funds back.
 *
 * Fees
 *
 * The contract can be deployed with a _feePerMillion value. This value would
 * indicate the amount of ETH that would be taken from the amount of ETH locked.
 *
 * The accrued fees can be sent to the _feeRecipient address by calling the
 * {withdrawFees} function.
 */
contract EtherSwap {

    struct Swap {
        bytes32 hashedSecret;
        address payable initiator;
        // timestamp after which the swap is expired, can no longer be claimed and can be reimbursed
        uint64 endTimeStamp;
        address payable recipient;
        // timestamp after which the recipient of the swap can be changed
        // used to prevent dos attacks by locking swaps of users with a random address
        uint64 changeRecipientTimestamp;
        uint256 value;
        uint256 expectedAmount;
    }

    uint32 public numberOfSwaps;
    // duration in seconds of the lock put on swaps to prevent changing their recipient repeatedly
    uint64 public recipientChangeLockDuration;

    address payable public feeRecipient;
    // the fee on a swap will be `swapValue * feePerMillion / 1_000_000`
    uint64 public feePerMillion;
    uint256 public collectedFees;

    mapping(uint32 => Swap) public swaps;

    event Commit(address initiator, address recipient, uint256 value, uint256 expectedAmount, uint64 endTimeStamp, bytes32 indexed hashedSecret, uint32 indexed id);
    event ChangeRecipient(address recipient, uint32 indexed id);
    event Claim(address recipient, uint256 value, bytes32 proof, uint32 indexed id);
    event Refund(uint32 indexed id);
    event WithdrawFees(uint256 value);

    constructor (uint64 _recipientChangeLockDuration, address payable _feeRecipient, uint64 _feePerMillion) {
        recipientChangeLockDuration = _recipientChangeLockDuration;
        feeRecipient = _feeRecipient;
        feePerMillion = _feePerMillion;
        // Pay the tx.origin to incentivize deployment via a contract using create2 allowing us to pre-compile
        // the contract address
        payable(tx.origin).transfer(address(this).balance);
    }

    /**
    * @dev Commit to swap
    *
    * This function can be directly called by users matching an already committed swap
    * and they know the end timestamp and recipient they should use.
    *
    * @param _swapEndTimestamp the timestamp at which the commit expires
    * @param _hashedSecret the hashed secret
    * @param _payout the value paid to the counterparty claiming the swap
    * @param _expectedAmount the value expected by the committer in return for _payout
    * @param _recipient the recipient of the swap - can be the zero address
    */
    function commit(uint64 _swapEndTimestamp, bytes32 _hashedSecret, uint256 _payout, uint256 _expectedAmount, address payable _recipient) public payable {
        require(block.timestamp < _swapEndTimestamp, "Swap end timestamp must be in the future");
        require(_payout != 0, "Cannot commit to 0 payout");
        require(_expectedAmount != 0, "Cannot commit to 0 expected amount");

        uint256 fee = feeFromSwapValue(_payout);
        require(msg.value == fee + _payout, "Ether value does not match payout + fee");

        Swap memory swap;
        swap.hashedSecret = _hashedSecret;
        swap.initiator = payable(msg.sender);
        swap.recipient = _recipient;
        swap.endTimeStamp = _swapEndTimestamp;
        swap.changeRecipientTimestamp = 0;
        swap.value = _payout;
        swap.expectedAmount = _expectedAmount;

        if (_recipient != address(0)) {
            swap.changeRecipientTimestamp = type(uint64).max;
        }

        swaps[numberOfSwaps] = swap;

        emit Commit(msg.sender, _recipient, _payout, _expectedAmount, swap.endTimeStamp, _hashedSecret, numberOfSwaps);

        numberOfSwaps = numberOfSwaps + 1;
    }

    /**
    * @dev Commit to swap
    *
    * This function can be called by users uncertain as to when their transaction will be mined
    *
    * @param _transactionExpiryTime the timestamp at which the transaction expires
    *        used to make sure the user does not see himself committed later than expected
    * @param _lockTimeSec the duration of the swap lock
    *        swap will expire at block.timestamp + _lockTimeSec
    * @param _hashedSecret the hashed secret
    * @param _payout the value paid to the counterparty claiming the swap
    * @param _expectedAmount the value expected by the committer in return for _payout
    * @param _recipient the recipient of the swap
    *        can be the zero address
    */
    function commit(uint64 _transactionExpiryTime, uint64 _lockTimeSec, bytes32 _hashedSecret, uint256 _payout, uint256 _expectedAmount, address payable _recipient) external payable {
        require(block.timestamp < _transactionExpiryTime, "Transaction no longer valid");
        commit(uint64(block.timestamp) + _lockTimeSec, _hashedSecret, _payout, _expectedAmount, _recipient);
    }

    /**
    * @dev Change recipient of an existing swap
    *
    * Call this function when you want to match a swap to set yourself as
    * the recipient of the swap for `recipientChangeLockDuration` seconds
    *
    * @param _swapId the swap id
    * @param _recipient the recipient to be set
    */
    function changeRecipient(uint32 _swapId, address payable _recipient) external {
        require(_swapId < numberOfSwaps, "No swap with corresponding id");
        require(swaps[_swapId].changeRecipientTimestamp <= block.timestamp, "Cannot change recipient: timestamp");

        swaps[_swapId].recipient = _recipient;
        swaps[_swapId].changeRecipientTimestamp = uint64(block.timestamp) + recipientChangeLockDuration;

        emit ChangeRecipient(_recipient, _swapId);
    }

    /**
    * @dev Claim a swap
    *
    * Claim a swap to sent its locked value to its recipient by revealing the hashed secret
    *
    * @param _id the swap id
    * @param _proof the proof that once hashed produces the `hashedSecret` committed to in the swap
    */
    function claim(uint32 _id, bytes32 _proof) external {
        require(_id < numberOfSwaps, "No swap with corresponding id");

        Swap memory swap = swaps[_id];

        require(swap.endTimeStamp >= block.timestamp, "Swap expired");
        require(swap.recipient != address(0), "Swap has no recipient");

        bytes32 hashedSecret = keccak256(abi.encode(_proof));
        require(hashedSecret == swap.hashedSecret, "Incorrect secret");

        collectedFees = collectedFees + feeFromSwapValue(swap.value);
        clean(_id);
        swap.recipient.transfer(swap.value);
        emit Claim(swap.recipient, swap.value, _proof, _id);
    }

    /**
    * @dev Refund a swap
    *
    * Refund an expired swap by transferring back its locked value to the swap initiator.
    * Requires the swap to be expired.
    * Also reimburses the eventual fee locked for the swap.
    *
    * @param id the swap id
    */
    function refund(uint32 id) external {
        require(id < numberOfSwaps, "No swap with corresponding id");
        require(swaps[id].endTimeStamp < block.timestamp, "TimeStamp violation");
        require(swaps[id].value > 0, "Nothing to refund");

        uint256 value = swaps[id].value;
        uint256 fee = feeFromSwapValue(value);
        address payable initiator = swaps[id].initiator;

        clean(id);

        initiator.transfer(value + fee);
        emit Refund(id);
    }

    /*
    * @dev Withdraw the fees
    *
    * Send the total collected fees to the `feeRecipient` address.
    */
    function withdrawFees() external {
        uint256 toTransfer = collectedFees;
        collectedFees = 0;
        feeRecipient.transfer(toTransfer);
        emit WithdrawFees(toTransfer);
    }

    /**
    * @dev Clean a swap from storage
    *
    * @param id the swap id
    */
    function clean(uint32 id) private {
        Swap storage swap = swaps[id];
        delete swap.hashedSecret;
        delete swap.initiator;
        delete swap.endTimeStamp;
        delete swap.recipient;
        delete swap.changeRecipientTimestamp;
        delete swap.value;
        delete swap.expectedAmount;
        delete swaps[id];
    }

    /**
    * @dev Get the fee paid for a swap from its swap value
    *
    * @param value the swap value
    * @return the fee paid for the swap
    */
    function feeFromSwapValue(uint256 value) public view returns (uint256) {
        uint256 fee = value * feePerMillion / 1_000_000;
        return fee;
    }
}