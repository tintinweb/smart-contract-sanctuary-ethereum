/**
 *Submitted for verification at Etherscan.io on 2023-02-06
*/

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.8.0 <0.9.0;

contract MultiSigWallet
{
	event Deposit(address indexed sender, uint amount, uint balance);
	event SubmitTransaction(
		address indexed owner, 
		uint indexed txIndex,
		address indexed receiver,
		uint value,
		bytes data
	);
	event ConfirmTransaction(address indexed owner, uint indexed txIndex);
	event RevokeConfirmation(address indexed owner, uint indexed txIndex);
	event ExecuteTransaction(address indexed owner, uint indexed txIndex);

	address[] public owners; //instantiate the array to hold the multisigners address'
	mapping(address => bool) public isOwner;
	uint public confirmationsRequired;

	struct Transaction
	{
		address receiver;
		uint value;
		bytes data;
		bool executed;
		uint numConfirmations;
	}

	mapping(uint => mapping(address => bool)) public isConfirmed;

	Transaction[] public transactions;

	modifier onlyOwner()
	{
		require(isOwner[msg.sender], "caller is not owner");
		_;
	}

	modifier txExists(uint txIndex)
	{
		require(txIndex < transactions.length, "transaction not found");
		_;
	}

	modifier notExecuted(uint txIndex)
	{
		require(!transactions[txIndex].executed, "this transaction has already been executed");
		_;
	}

	modifier notConfirmed(uint txIndex)
	{
		require(!isConfirmed[txIndex][msg.sender], "transaction has already been confirmed");
		_;
	}

	constructor(address[] memory setOwners, uint256 setConfirmationsRequired)
	{
		require(setOwners.length > 0, "no owners set");
		require(
			setConfirmationsRequired > 0 && setConfirmationsRequired <= setOwners.length, 
			"not enough block confirmations reached!"
		);
		for (uint i=0; i < setOwners.length; i++)
		{
			address owner = setOwners[i];
			require(owner != address(0), "invalid owner");
			require(!isOwner[owner], "duplicate owner found");
			isOwner[owner] = true;
			owners.push(owner);
		}
		confirmationsRequired = setConfirmationsRequired;
	}
	
	receive() external payable
	{
		emit Deposit(msg.sender, msg.value, address(this).balance);
	}

	function submitTransaction
	(
		address setReceiver, 
		uint setValue,
		bytes memory setData
	) public onlyOwner 
	{
		uint txIndex = transactions.length;
		transactions.push
		(
			Transaction
			({
				receiver: setReceiver,
				value: setValue,
				data: setData,
				executed: false,
				numConfirmations: 0
			})
		);
		emit SubmitTransaction(msg.sender, txIndex, setReceiver, setValue, setData);
	}

	function confirmTransaction(uint txIndex)
        public onlyOwner txExists(txIndex) notExecuted(txIndex) notConfirmed(txIndex)
	{
		Transaction storage transaction = transactions[txIndex];
		transaction.numConfirmations += 1;
		isConfirmed[txIndex][msg.sender] = true;
		emit ConfirmTransaction(msg.sender, txIndex);
	}
	
	function executeTransaction(uint txIndex) 
	public onlyOwner txExists(txIndex) notExecuted(txIndex) 
	{
		Transaction storage transaction = transactions[txIndex];
		require(
			transaction.numConfirmations >= confirmationsRequired,
			"cannot execute tx"
		);		
		transaction.executed = true;
		(bool success, ) = transaction.receiver.call{value: transaction.value}
		(
			transaction.data
		);
		require(success, "tx failed");
		emit ExecuteTransaction(msg.sender, txIndex);
	}

	function revokeConfirmation(uint txIndex)
	public onlyOwner txExists(txIndex) notExecuted(txIndex)
	{
		Transaction storage transaction = transactions[txIndex];
		require(isConfirmed[txIndex][msg.sender], "tx not confirmed");
		transaction.numConfirmations -= 1;
		isConfirmed[txIndex][msg.sender] = false;
		emit RevokeConfirmation(msg.sender, txIndex);
	}

	function getOwners() public view returns (address[] memory)
	{
		return owners;
	}

	function getTransactionCount() public view returns (uint)
	{
		return transactions.length;
	}

	function getTransaction(uint txIndex)
		public view returns
		(
			address receiver,
			uint value,
			bytes memory data,
			bool executed,
			uint numConfirmations
		)
	{
		Transaction storage transaction = transactions[txIndex];
		return
		(
			transaction.receiver,
			transaction.value,
			transaction.data,
			transaction.executed,
			transaction.numConfirmations
		);
	}
}