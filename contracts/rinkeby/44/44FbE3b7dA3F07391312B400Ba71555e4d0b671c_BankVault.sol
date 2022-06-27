// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title Bank Vault
/// @author 0x6Fa02ed6248A4a78609368441265a5798ebaFC78
/// @notice A secure decentralized Ether Bank Vault. Store Ether on multiple accounts only you have access to. Transfers, debits, credit many, escrow, ...
/// @dev Built as an Ether vault for Rounds V4. Free to use.
contract BankVault {
    address public owner;

    constructor () {
        owner = msg.sender;
    }

    /*
        Banking
    */

    mapping(string=>mapping(address=>uint256)) public accountBalances;

    mapping(address=>mapping(string=>bool)) private hasAccount;
    mapping(address=>string[]) private availableAccounts;
    mapping(address=>uint64) private accountCounts;

    event newAccount(address user, string account);
    event newCredit(address user, address from, uint256 amount, string account, string note);
    event newDebit(address user, uint256 amount, string account, string note);
    event newBatchCredit(address[] users, address from, uint256[] amounts, string account, string note);
    event newBatchTransfer(address[] users, address from, uint256[] amounts, string account, string note);
    event newTransfer(address from, address to, uint256 amount, string fromAccount, string toAccount, string note);


    /// @notice Returns the user's list of accounts
    /// @param user User Address
    /// @return accounts An array of account names
    function accounts(address user) public view returns (string[] memory) {
        return availableAccounts[user];
    }


    /// @notice Returns the balance of a user account
    /// @param user User Address
    /// @param account Account name
    /// @return balance The account balance
    function balance(address user, string memory account) public view returns (uint256) {
        return accountBalances[account][user];
    }

    /// @notice Return the balance of a all the accounts
    /// @param user User Address
    function balance(address user) public view returns (uint256) {
        uint256 totalBalance;
        uint l = accountCounts[user];
        if (l > 0) {
            uint i;
            for (i=0;i<l;i++) {
                totalBalance += accountBalances[availableAccounts[user][i]][user];
            }
        }
        return totalBalance;
    }

    /// @notice Internal, record a new account
    /// @param user User Address
    /// @param account Account name
    function saveAccount(address user, string memory account) internal {
        if (!hasAccount[user][account]) {
            hasAccount[user][account] = true;
            availableAccounts[user].push(account);
            accountCounts[user] += 1;
            emit newAccount(user, account);
        }
    }


    /// @notice Internal account credit from contract balance.
    /// @param user User to credit
    /// @param account Account name
    /// @param amount Amount in wei
    /// @param note Note attached to the operation
    /// @param emitEvent True to emit `newCredit(address user, address from, uint256 amount, string account, string note)`
    function _credit(address user, string memory account, uint256 amount, string memory note, bool emitEvent) internal {
        accountBalances[account][user] += amount;
        saveAccount(user, account);
        if (emitEvent) {
            emit newCredit(user, msg.sender, amount, account, note);
        }
    }

    /// @notice Internal account debit from contract balance. Reverts if the account doesn't have enough balance.
    /// @param user User to debit
    /// @param account Account name
    /// @param amount Amount in wei
    /// @param note Note attached to the operation
    /// @param emitEvent True to emit `newCredit(address user, address from, uint256 amount, string account, string note)`
    function _debit(address user, string memory account, uint256 amount, string memory note, bool emitEvent) internal {
        require(accountBalances[account][user]>=amount, "Not enough balance");
        accountBalances[account][user] -= amount;
        if (emitEvent) {
            emit newDebit(user, amount, account, note);
        }
    }

    /// @notice Credit external value to a single user
    /// @param user User Address
    /// @param account Account name
    /// @param note Note attached to the operation
    function credit(address user, string memory account, string memory note) public payable {
        _credit(user, account, msg.value, note, true);
    }

    /// @notice Credit external value to an array of users. The value sent must match `sum(amounts[])`
    /// @param users Array of addresses
    /// @param amounts Array of amounts in wei
    /// @param account Account name where that value is received
    /// @param note Note attached to the operation
    function creditMany(address[] memory users, uint256[] memory amounts, string memory account, string memory note) public payable {
        // Verify the sum matches the received value
        uint256 valSum = fastSum(amounts);
        require(msg.value>=valSum, "Sum mismatch");
        require(users.length==amounts.length, "Array mismatch");
        // increment the value mappings
        uint l = users.length;
        if (l > 0) {
            uint i;
            for (i=0;i<l;i++) {
                _credit(users[i], account, amounts[i], note, true);
            }
            emit newBatchCredit(users, msg.sender, amounts, account, note);
        }

        // Refund the extra is the crezator overpays the fees
        if (msg.value>valSum) {
            uint256 overpaid = msg.value-valSum;
            _credit(msg.sender, "Overpaid", overpaid, note, true);
        }
    }

    /// @notice User debit
    /// @param account Account name
    /// @param amount Amount to debit in wei
    function debit(string memory account, uint256 amount) public {
        uint256 accountBalance = accountBalances[account][msg.sender];
        // Check the value in that account
        require(accountBalance >= amount, "Zero balance");
        // Transfer the value
        _debit(msg.sender, account, amount, "Direct Debit", true);
        payable(msg.sender).transfer(accountBalance);
    }

    /// @notice User total withdraw: Empties all accounts
    function withdrawAll() public {
        uint256 totalBalance;
        uint l = accountCounts[msg.sender];
        uint i;
        if (l > 0) {
            for (i=0;i<l;i++) {
                totalBalance += accountBalances[availableAccounts[msg.sender][i]][msg.sender];
                accountBalances[availableAccounts[msg.sender][i]][msg.sender] = 0;
                emit newDebit(msg.sender, totalBalance, availableAccounts[msg.sender][i], "User withdrawal");
            }
            if (totalBalance>0) {
                payable(msg.sender).transfer(totalBalance);
            }
        }
    }

    /// @notice Internal transfer to many users.
    /// @param users Array of addresses
    /// @param amounts Array of amounts in wei
    /// @param fromAccount Account name from which to debit (sender)
    /// @param toAccount Account name where that value is received (recipients)
    /// @param note Note attached to the operation
    function transferMany(address[] memory users, uint256[] memory amounts, string memory fromAccount, string memory toAccount, string memory note) public {
        // Verify the sum matches the received value
        uint256 valSum = fastSum(amounts);
        require(accountBalances[fromAccount][msg.sender]>=valSum, "Sum mismatch");
        require(users.length==amounts.length, "Array mismatch");
        // Debit the account
        _debit(msg.sender, fromAccount, valSum, note, true);
        // increment the value mappings
        uint l = users.length;
        if (l > 0) {
            uint i;
            for (i=0;i<l;i++) {
                _credit(users[i], toAccount, amounts[i], note, true);
            }
        }
        emit newBatchTransfer(users, msg.sender, amounts, toAccount, note);
    }

    /// @notice Internal transfer to a single user
    /// @param to Address of the recipient
    /// @param amount Amount to transfer
    /// @param fromAccount Account name from which to debit (sender)
    /// @param toAccount Account name where that value is received (recipient)
    /// @param note Note attached to the operation
    function transfer(address to, uint256 amount, string memory fromAccount, string memory toAccount, string memory note) public {
        _debit(msg.sender, fromAccount, amount, note, true);
        _credit(to, toAccount, amount, note, true);
        emit newTransfer(msg.sender, to, amount, fromAccount, toAccount, note);
    }



    /*
        Escrow
    */
    struct escrow_struct {
        address user;
        uint256 amount;
        string account;
        string note;
    }
    // escrow_owner -> escrow_id -> data
    mapping(address=>mapping(uint256=>escrow_struct[])) public escrows;
    mapping(address=>mapping(uint256=>uint256)) public escrowCounts;
    mapping(address=>mapping(uint256=>uint32)) public escrowStatus; // 0:none, 1:open , 2:closed, 3:canceled

    event newEscrow(address escrow_owner, uint256 escrow_id);
    event escrowClosed(address escrow_owner, uint256 escrow_id);
    event escrowCanceled(address escrow_owner, uint256 escrow_id);


    /// @notice Returns a dynamic account name for an escrow. Internal function.
    /// @param escrow_owner Owner of the escrow
    /// @param escrow_id Escrow ID
    /// @return accountName The generated account name
    function escrowAccountName(address escrow_owner, uint256 escrow_id) internal pure returns (string memory) {
        return string(abi.encodePacked(escrow_owner,escrow_id));
    }

    /// @notice Escrow some value. Transfered on closing, returned to the sender on cancelation. Multiple escrow can be done under a single escrow ID, as long as that escrow is open.
    /// @dev `msg.sender` is the escrow owner. Multiple senders can use the same escrow ID, as they are unique per owner.
    /// @param escrow_id Escrow ID
    /// @param user The recipient
    /// @param account Account on which to transfer the value on closing
    /// @param note Note attached to the operation
    function escrow(uint256 escrow_id, address user, string memory account, string memory note) public payable {
        require(escrowStatus[msg.sender][escrow_id]==0||escrowStatus[msg.sender][escrow_id]==1, "Wrong escrow status");
        escrows[msg.sender][escrow_id].push(escrow_struct(user, msg.value, account, note));
        escrowCounts[msg.sender][escrow_id] += 1;
        if (escrowStatus[msg.sender][escrow_id]==0) {
            escrowStatus[msg.sender][escrow_id] = 1;
            emit newEscrow(msg.sender, escrow_id);
        }
        _credit(address(this), escrowAccountName(msg.sender, escrow_id), msg.value, note, true);
    }

    /// @notice Close an escrow, releasing the funds to their respective accounts
    /// @dev Doesn't break on failure as to not fail transactions that calls it.
    /// @param escrow_id Escrow ID
    /// @return success True if the escrow was successfully closed. Failure if the escrow wasn't open.
    function closeEscrow(uint256 escrow_id) public returns (bool) {
        if (escrowStatus[msg.sender][escrow_id]!=1) {
            return false;
        }
        escrowStatus[msg.sender][escrow_id] = 2; // Closed
        accountBalances[escrowAccountName(msg.sender, escrow_id)][address(this)] = 0; // Empty the escrow account
        uint256 l = escrowCounts[msg.sender][escrow_id];
        if (l > 0) {
            uint256 i;
            for (i=0;i<l;i++) {
                escrow_struct memory escrowObj = escrows[msg.sender][escrow_id][i];
                _credit(escrowObj.user, escrowObj.account, escrowObj.amount, escrowObj.note, true);
            }
        }
        emit escrowClosed(msg.sender, escrow_id);
        return true;
    }

    /// @notice Cancel an escrow, transfer the funds to their respective accounts.
    /// @dev Doesn't break on failure as to not fail transactions that calls it.
    /// @param escrow_id Escrow ID
    /// @return success True if the escrow was successfully closed. Failure if the escrow wasn't open.
    function cancelEscrow(uint256 escrow_id) public returns (bool) {
        if (escrowStatus[msg.sender][escrow_id]!=1) {
            return false;
        }
        escrowStatus[msg.sender][escrow_id] = 3; // Canceled
        uint256 l = escrowCounts[msg.sender][escrow_id];
        if (l>0) {
            uint256 i;
            uint256 sum;
            for (i=0;i<l;i++) {
                escrow_struct memory escrowObj = escrows[msg.sender][escrow_id][i];
                sum += escrowObj.amount;
            }
            payable(msg.sender).transfer(sum);
        }
        emit escrowCanceled(msg.sender, escrow_id);
        return true;
    }



    /*
        Utilities fallbacks
    */


    /// @notice Fast Sum in assembly, for gas efficiency. Internal.
    /// @param _data Array of uint256 to sum
    /// @return sum Sum of the values
    function fastSum(uint256[] memory _data) internal pure returns (uint sum) {
        assembly {
            let len := mload(_data)
            let data := add(_data, 0x20)
            for
                { let end := add(data, mul(len, 0x20)) }
                lt(data, end)
                { data := add(data, 0x20) }
            {
                sum := add(sum, mload(data))
            }
        }
    }

    /// @notice Transfer ownership of the Vault. An owner has no power.
    /// @param newOwner Address of the new owner
    function transferOwnership(address newOwner) public {
        require(msg.sender==owner, 'Forbidden');
        owner = newOwner;
    }

    /// @notice Direct transfer, assign the value to the user's default account so they can withdraw it back
    receive() external payable {
        _credit(msg.sender, "default", msg.value, "Direct transfer to the vault", true);
    }
    
    fallback() external payable {
        _credit(msg.sender, "default", msg.value, "Direct transfer to the vault", true);
    }
}