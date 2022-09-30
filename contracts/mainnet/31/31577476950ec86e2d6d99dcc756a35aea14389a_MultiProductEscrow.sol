// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import "./ERC20.sol";
import "./EnumerableSet.sol";

contract MultiProductEscrow {
	struct TransactionInfo {
		address sellerAddress;
		address buyerAddress;
		uint256 usdcAmount;
		uint256 depositTimeSeconds;
		uint256 timeUntilFundsReleasedAutomatically;
		bool created;
		bool fundsLocked;
		bool fundsReleased;
		bool completed;
	}

	mapping(string => TransactionInfo) public transactions;
	mapping(address => bool) public sellers;
	mapping(address => string[]) public transactionsByBuyer;
	mapping(address => uint64) public numTransactionsPerBuyer;

	address private usdcAddress = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;

	/**
	 * @dev Initializes the NftMinter with default admin and payout roles.
	 *
	 * @param _usdcAddress the contract address of USDC.	 
	 */
	constructor(address _usdcAddress) {
		usdcAddress = _usdcAddress;
	}

	/**
	 * @dev Only the buyer can execute these functions.
	 */
	modifier onlyBuyer(string calldata transactionId) {
		TransactionInfo memory transactionInfo = transactions[transactionId];
		require(transactionInfo.created, "Invalid transaction.");
		require(!transactionInfo.completed, "Transaction already completed.");
		require(
			transactionInfo.buyerAddress == msg.sender,
			"Only the buyer can call this function."
		);
		_;
	}

	/**
	 * @dev Only the seller can execute these functions.
	 */
	modifier onlySeller(string calldata transactionId) {
		TransactionInfo memory transactionInfo = transactions[transactionId];
		require(transactionInfo.created, "Invalid transaction.");
		require(!transactionInfo.completed, "Transaction already completed.");
		require(
			transactionInfo.sellerAddress == msg.sender,
			"Only the seller can call this function."
		);
		_;
	}

	function addSellerToSellerlist() public {
		sellers[msg.sender] = true;
	}

	/**
	 * @dev Buyer deposits USDC into the contract.
	 */
	function createTransaction(
		string calldata transactionId,
		address sellerAddress,
		uint256 usdcAmount,
		uint256 timeUntilFundsReleasedAutomatically
	) public {
		require(
			!transactions[transactionId].created,
			"Transaction ID already exists."
		);
		require(sellers[sellerAddress], "Seller must be on seller list.");
		address buyerAddress = msg.sender;
		// Transfer funds from the buyer's account to this contract.		
		require(
			ERC20(usdcAddress).transferFrom(
				buyerAddress,
				address(this),
				usdcAmount
			)
		);
		uint256 depositTimeSeconds = block.timestamp;
		transactions[transactionId] = TransactionInfo({
			sellerAddress: sellerAddress,
			buyerAddress: buyerAddress,
			usdcAmount: usdcAmount,
			depositTimeSeconds: depositTimeSeconds,
			timeUntilFundsReleasedAutomatically: timeUntilFundsReleasedAutomatically,
			created: true,
			fundsLocked: false,
			fundsReleased: false,
			completed: false
		});
		transactionsByBuyer[buyerAddress].push(transactionId);
		numTransactionsPerBuyer[buyerAddress] += 1;
	}

	/**
	 * @dev Seller can refund the money.
	 */
	function refund(string calldata transactionId) public onlySeller(transactionId) {		
		transactions[transactionId].completed = true;
		uint256 totalFunds = transactions[transactionId].usdcAmount;
		require(
			ERC20(usdcAddress).transfer(
				transactions[transactionId].buyerAddress,
				totalFunds
			)
		);
	}

	/**
	 * @dev The buyer can release the funds to the seller allowing the
	 * seller to withdraw the funds.
	 */
	function releaseFunds(string calldata transactionId)
		public
		onlyBuyer(transactionId)
	{
		transactions[transactionId].fundsReleased = true;
	}

	/**
	 * @dev The buyer can lock funds if they are unhappy preventing them from
	 * being released.
	 */
	function lockFunds(string calldata transactionId) public onlyBuyer(transactionId) {		
		transactions[transactionId].fundsLocked = true;
	}

	/**
	 * @dev The buyer can unlock funds if the seller has satisfied them.
	 */
	function unlockFunds(string calldata transactionId)
		public
		onlyBuyer(transactionId)
	{		
		transactions[transactionId].fundsLocked = false;
	}

	/**
	 * @dev The seller can withdraw funds once the buyer has released them or
	 * a specified time has passed and the buyer hasn't locked the funds.
	 */
	function withdraw(string calldata transactionId) public onlySeller(transactionId) {		
		require(!transactions[transactionId].fundsLocked, "Buyer has locked funds.");
		require(
			transactions[transactionId].fundsReleased ||
				block.timestamp >
				transactions[transactionId].depositTimeSeconds +
					transactions[transactionId].timeUntilFundsReleasedAutomatically,
			"Funds have not been released."
		);
		transactions[transactionId].completed = true;
		uint256 totalFunds = transactions[transactionId].usdcAmount;
		require(
			ERC20(usdcAddress).transfer(
				transactions[transactionId].sellerAddress,
				totalFunds
			)
		);
	}
}