// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract SimpleStorage {
	struct TransferDetail {
		string to;
		string from;
		int256 balance;
		int256 transferAmount;
	}

	mapping(string=> int256) public fetchBalanceByName;
	mapping(string=> int256) public fetchTransferByName;
	TransferDetail public lastTransaction = TransferDetail("", "", 0, 0);
	TransferDetail[] public allTransactions; 
	bool public transactionSuccess;

	function setLastTransaction(string memory _to, string memory _from, int256 _balance, int256 _transferAmount) internal {
		lastTransaction.to = _to;
		lastTransaction.from = _from;
		lastTransaction.balance = _balance;
		lastTransaction.transferAmount = _transferAmount;
		// Default external functions which change Blockchain state, use Gas
	}

	function makeTransaction(string memory _to, string memory _from, int _balance, int256 _transfer) public {
		// The memory or callback tag denotes temporary data available within the lifecycle of a function
		// memory variables can be altered within function lifecycle but callback variable can not. 
		int256 newBalance = _balance - _transfer;
		if(newBalance>=0){
			fetchBalanceByName[_from] = newBalance;
			fetchTransferByName[_from] = _transfer;
			setLastTransaction( _to, _from, newBalance, _transfer);
			allTransactions.push(TransferDetail( _to, _from, newBalance, _transfer));
			transactionSuccess = true;
		}else{
			transactionSuccess = false;
		}
	}

	function viewTransactions() external view returns(TransferDetail[] memory){
		return allTransactions;
	}

	function printContractName() public pure virtual returns(string memory) {
		return "Simple Storage"; 
	}
}