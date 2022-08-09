// SPDX-License-Identifier: Blockchain Commodities
pragma solidity ^0.8.0;

/**
 * Hashed Timelock Contracts (HTLCs) on Ethereum ETH.
 *
 * This contract provides a way to create and keep HTLCs for ETH.
 *
 * See HashedTimelockERC20.sol for a contract that provides the same functions
 * for ERC20 tokens.
 *
 * Protocol:
 *
 *  1) newContract(receiver, hashlock, timelock) - a sender calls this to create
 *      a new HTLC and gets back a 32 byte contract id
 *  2) withdraw(contractId, preimage) - once the receiver knows the preimage of
 *      the hashlock hash they can claim the ETH with this function
 *  3) refund() - after timelock has expired and if the receiver did not
 *      withdraw funds the sender / creator of the HTLC can get their ETH
 *      back with this function.
 */
contract HashedTimelock {

    // PARAMS
    uint32 public feeNumerator;
    uint32 public feeDenominator;
    address public feeReceiver;
    address public owner;
    bytes32 private emptyLockContractHash;
    uint256 private feeCollected;

    /**
     * Setting initial values for the smart contract when it is deployed, all these values can be configured later
     */
    constructor(address initialOwner, address initialFeeReceiver, uint32 initialFeeNumerator, uint32 initialFeeDenominator) {
        require(initialOwner != address(0), "40207: INVALID OWNER");
        require(initialFeeDenominator != 0, "40209: INVALID DENOMINATOR");
        owner = initialOwner;
        feeReceiver = initialFeeReceiver;
        feeNumerator = initialFeeNumerator;
        feeDenominator = initialFeeDenominator;
        emptyLockContractHash = getEmptyContractHash();
    }

    struct LockContract {
        uint256 amount;
        bytes32 hashLock; // keccak256 hash
        bytes32 preimage;
        uint32 timeLock; // UNIX timestamp seconds - locked UNTIL this time
        address payable sender;
        address payable receiver;
        bool collected; // marks if amount in the contract has been withdrawn or refunded
    }

    mapping(bytes32 => LockContract) public contracts;

    //EVENTS

    event HTLCNew(
        bytes32 indexed contractId,
        bytes32 hashlock,
        uint32 timelock,
        address indexed sender,
        address indexed receiver,
        uint256 amount
    );
    event HTLCWithdraw(bytes32 indexed contractId);
    event HTLCRefund(bytes32 indexed contractId);
    event HTLCNewOwner(address owner);
    event HTLCNewFeeReceiver(address feeReceiver);
    event HTLCFeeUpdated(uint32 feeNumerator, uint32 feeDenominator);
    event HTLCFeeCollected(address feeReceiver, uint256 feeCollected);


    //MODIFIERS

    modifier onlyOwner() {
        require(msg.sender == owner, "40301: FORBIDDEN");
        _;
    }

    modifier onlyFeeReceiver() {
        require(msg.sender == feeReceiver, "40302: FORBIDDEN");
        _;
    }

    modifier fundsSent() {
        require(msg.value > 0, "40201: FUNDS REQUIRED");
        _;
    }
    modifier futureTimeLock(uint32 time) {
        // only requirement is the timelock time is after the last blocktime (now).
        // probably want something a bit further in the future then this.
        // but this is still a useful sanity check:
        require(time > block.timestamp, "40011: INVALID VALUE");
        _;
    }
    modifier contractExists(bytes32 contractId) {
        require(haveContract(contractId), "40400: NOT FOUND");
        _;
    }
    modifier hashLockMatches(bytes32 contractId, bytes32 x) {
        require(
            contracts[contractId].hashLock == keccak256(abi.encodePacked(x)), "40100: UNAUTHORIZED"
        );
        _;
    }
    modifier withdrawable(bytes32 contractId) {
        require(contracts[contractId].receiver == msg.sender, "40303: FORBIDDEN");
        require(!contracts[contractId].collected, "40900: CONFLICT");
        _;
    }
    modifier refundable(bytes32 contractId) {
        require(contracts[contractId].sender == msg.sender, "40304: FORBIDDEN");
        require(!contracts[contractId].collected, "40900: CONFLICT");
        require(contracts[contractId].timeLock <= block.timestamp, "40101: UNAUTHORIZED");
        _;
    }

    //FUNCTIONS

    /**
     * Sender sets up a new hash time lock contract depositing the ETH and
     * providing the receiver lock terms.
     *
     * @param receiver Receiver of the ETH.
     * @param hashLock A keccak256 hash hashlock.
     * @param timeLock UNIX epoch seconds time that the lock expires at.
     *                  Refunds can be made after this time.
     * @return contractId Id of the new HTLC. This is needed for subsequent
     *                    calls.
     */
    function newContract(address payable receiver, bytes32 hashLock, uint32 timeLock)
    external
    payable
    fundsSent
    futureTimeLock(timeLock)
    returns (bytes32 contractId)
    {
        contractId = keccak256(
            abi.encodePacked(
                msg.sender,
                receiver,
                msg.value,
                hashLock,
                timeLock
            )
        );

        // Reject if a contract already exists with the same parameters. The
        // sender must change one of these parameters to create a new distinct
        // contract.
        if (haveContract(contractId))
            revert("40901: CONFLICT");

        contracts[contractId] = LockContract(
            msg.value,
            hashLock,
            0x0,
            timeLock,
            payable(msg.sender),
            receiver,
            false
        );

        emit HTLCNew(
            contractId,
            hashLock,
            timeLock,
            msg.sender,
            receiver,
            msg.value
        );

        return contractId;
    }

    /**
     * Called by the receiver once they know the preimage of the hashlock.
     * This will transfer the locked funds to their address.
     *
     * @param contractId Id of the HTLC.
     * @param preimage keccak256(_preimage) should equal the contract hashlock.
     * @return bool true on success
     */
    function withdraw(bytes32 contractId, bytes32 preimage)
    external
    contractExists(contractId)
    hashLockMatches(contractId, preimage)
    withdrawable(contractId)
    returns (bool)
    {
        uint256 amount = contracts[contractId].amount;
        address payable receiver = contracts[contractId].receiver;
        contracts[contractId].preimage = preimage;
        contracts[contractId].collected = true;
        delete contracts[contractId].amount;
        delete contracts[contractId].hashLock;
        delete contracts[contractId].timeLock;
        delete contracts[contractId].sender;
        delete contracts[contractId].receiver;
        emit HTLCWithdraw(contractId);
        if (feeReceiver != address(0)) {
            uint fee = amount * feeNumerator / feeDenominator;
            feeCollected += fee;
            receiver.transfer(amount - fee);
        } else {
            receiver.transfer(amount);
        }
        return true;
    }

    /**
     * Called by the sender if there was no withdraw AND the time lock has
     * expired. This will refund the contract amount.
     *
     * @param contractId Id of HTLC to refund from.
     * @return bool true on success
     */
    function refund(bytes32 contractId)
    external
    contractExists(contractId)
    refundable(contractId)
    returns (bool)
    {
        uint256 amount = contracts[contractId].amount;
        address payable sender = contracts[contractId].sender;
        contracts[contractId].collected = true;
        delete contracts[contractId].amount;
        delete contracts[contractId].hashLock;
        delete contracts[contractId].timeLock;
        delete contracts[contractId].sender;
        delete contracts[contractId].receiver;
        emit HTLCRefund(contractId);
        sender.transfer(amount);
        return true;
    }

    /**
     * Get contract details.
     * @param contractId HTLC contract id
     */
    function getContract(bytes32 contractId)
    external
    view
    returns (uint256, bytes32, bytes32, uint32, address, address, bool)
    {
        if (!haveContract(contractId))
            return (0, 0, 0, 0, address(0), address(0), false);
        LockContract memory fetchedContract = contracts[contractId];
        return (
        fetchedContract.amount,
        fetchedContract.hashLock,
        fetchedContract.preimage,
        fetchedContract.timeLock,
        fetchedContract.sender,
        fetchedContract.receiver,
        fetchedContract.collected
        );
    }

    /**
     * Is there a contract with id _contractId.
     * @param contractId Id into contracts mapping.
     */
    function haveContract(bytes32 contractId)
    internal
    view
    returns (bool)
    {
        return keccak256(abi.encodePacked(contracts[contractId].amount,
            contracts[contractId].hashLock,
            contracts[contractId].preimage,
            contracts[contractId].timeLock,
            contracts[contractId].sender,
            contracts[contractId].receiver,
            contracts[contractId].collected))
        != emptyLockContractHash;
    }

    /**
     * This method return a keccak256 hash of an empty Lock contract.
     */
    function getEmptyContractHash() pure private returns (bytes32) {
        uint256 u256 = 0;
        bytes32 b32 = 0;
        uint32 u32 = 0;
        address add = address(0);
        bool b = false;
        return keccak256(abi.encodePacked(u256, b32, b32, u32, add, add, b));
    }


    /**
     * Returns the total fee collected on this smart
     * contract
     */
    function getCollectedFee() onlyOwner external view returns (uint) {
        return feeCollected;
    }

    /**
     * This method will help user to withdraw the fee collected on this
     * smart contract, it will only let the user to withdraw any fee
     * not the balance of this smart contract as the balance might have
     * some amount from the contract which has been locked.
     */
    function withdrawCollectedFee() onlyFeeReceiver external {
        require(feeCollected > 0, "40202: FUNDS INSUFFICIENT");
        uint256 currentFeeCollected = feeCollected;
        feeCollected -= currentFeeCollected;
        emit HTLCFeeCollected(msg.sender, currentFeeCollected);
        payable(msg.sender).transfer(currentFeeCollected);
    }

    /**
     * This method will update the feeReceiver address who can withdraw the
     * fee collected on this smart contract
     * @param feeReceiverAddress - address of new fee collector
     */
    function updateFeeReceiver(address feeReceiverAddress) onlyOwner external {
        feeReceiver = feeReceiverAddress;
        emit HTLCNewFeeReceiver(feeReceiver);
    }

    /**
     * This method will update the owner address on this smart contract
     * @param ownerAddress - address of new owner
     */
    function updateOwner(address ownerAddress) onlyOwner external {
        require(ownerAddress != address(0), "40207: INVALID OWNER");
        owner = ownerAddress;
        emit HTLCNewOwner(owner);
    }

    /**
     * This method will allow owner to update the fee charged upon successful withdrawal
     * @param updatedFeeNumerator - new fee numerator
     * @param updatedFeeDenominator - new fee denominator
     */
    function updateFee(uint32 updatedFeeNumerator, uint32 updatedFeeDenominator) onlyOwner external {
        require(updatedFeeNumerator != 0, "40208: INVALID NUMERATOR");
        require(updatedFeeDenominator != 0, "40209: INVALID DENOMINATOR");
        feeNumerator = updatedFeeNumerator;
        feeDenominator = updatedFeeDenominator;
        emit HTLCFeeUpdated(feeNumerator, feeDenominator);
    }

}