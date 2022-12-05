/**
 *Submitted for verification at Etherscan.io on 2022-12-05
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

contract PiggyBank {
    mapping(uint256 => address) private clients;
    mapping(address => uint256) private reverseLookup;
    mapping(uint256 => uint256) private balances;
    uint256 clientsIndex = 0;
    string private _strNotAuthorized = "Not authorized!";
    string private _strNotEnoughETH = "Not enough ETH!";
    string private _strTransferFailed = "Tx failed!";

    /// @dev Creates a new piggybank.
    function createAccount() public {
        clients[clientsIndex] = msg.sender;
        balances[clientsIndex] = 0;
        reverseLookup[msg.sender] = clientsIndex;
        clientsIndex++;
    }

    /// @dev Allows to deposit ETH to a piggybank.
	///      Note: Only clients can deposit to their own piggybanks.
    function clientDeposit(uint256 clientID) public payable {
        require(msg.sender == clients[clientID], _strNotAuthorized);
        balances[clientID] += msg.value;
    }

    /// @dev Allows to withdraw any ETH available on this contract.
	///      Note: Anyone can deposit to a given piggybanks.
    function thirdPartyDeposit(uint256 clientID) public payable {
        balances[clientID] += msg.value;
    }

    /// @dev Allows to withdraw any ETH available on client's piggybank.
	///      Note: Only registered clients can withdraw from their own piggybanks.
	function withdraw(uint256 clientID) public payable {
		require(msg.sender == clients[clientID], _strNotAuthorized);
		uint balance = balances[clientID];
		require(balance > 0, _strNotEnoughETH);
		(bool success, ) = (msg.sender).call{value: balance}("");
		require(success, _strTransferFailed);
	}

    function getClientID() public view returns(uint256) {
        return(reverseLookup[msg.sender]);
    }
}