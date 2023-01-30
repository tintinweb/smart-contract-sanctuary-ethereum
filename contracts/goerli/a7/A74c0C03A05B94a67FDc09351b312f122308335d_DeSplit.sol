// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

error Not_Enough_Eth_Sent();
error Address_Zero();
error Transfer_Failed();
error ZeroAmountDeposit();
error Insufficient_Balance();
error Expense_Out_of_Bounds();
error CallerNotPartOfExpense();
error Expense_Settled();

contract DeSplit {
    struct Expense {
        string description;
        address payer;
        address to;
        address[] splitBy;
        uint256[] splitAmount;
    }

    mapping(address => uint256) balances;
    Expense[] private expenses;
    // address[] private users;

    /**
     * payer
     * to
     * splitBy
     * splitAmount
     * expenseIndex
     */
    event PaymentExpenseCreated(
        address,
        address,
        address[],
        uint256[],
        uint256
    );
    event ExpenseSettled(address, address, uint256, uint256);

    function payAndCreateExpense(
        uint256 _amount,
        address _to,
        string memory _description,
        address[] memory _splitBy,
        uint[] memory _splitAmount
    ) external {
        if (balances[msg.sender] <= _amount) {
            revert Insufficient_Balance();
        }
        if (_to == address(0)) revert Address_Zero();

        Expense memory newExpense;
        newExpense.description = _description;
        newExpense.payer = msg.sender;
        newExpense.splitBy = _splitBy;
        newExpense.splitAmount = _splitAmount;
        newExpense.to = _to;

        expenses.push(newExpense);

        balances[msg.sender] -= _amount;

        (bool success, ) = payable(_to).call{value: _amount}("");
        if (!success) revert Transfer_Failed();

        emit PaymentExpenseCreated(
            msg.sender,
            _to,
            _splitBy,
            _splitAmount,
            expenses.length - 1
        );
    }

    function settleExpense(address _recipient, uint256 _expenseIndex) public {
        if (_expenseIndex >= expenses.length) revert Expense_Out_of_Bounds();

        Expense memory _expense = expenses[_expenseIndex];

        // assuming that the splitBy index wont be that high
        uint256 callerIndex = 2 ** 256 - 1;
        for (uint256 i; i < _expense.splitBy.length; i++) {
            if (_expense.splitBy[i] == msg.sender) {
                callerIndex = i;
                break;
            }
        }
        // if the caller is not found to be a part of the splitBy array
        if (callerIndex == 2 ** 256 - 1) revert CallerNotPartOfExpense();

        if (balances[msg.sender] < _expense.splitAmount[callerIndex])
            revert Insufficient_Balance();

        // checking if the balance has already been settled;
        if (_expense.splitAmount[callerIndex] == 0) revert Expense_Settled();

        balances[msg.sender] -= _expense.splitAmount[callerIndex];
        balances[_recipient] += _expense.splitAmount[callerIndex];

        _expense.splitAmount[callerIndex] = 0;
        expenses[_expenseIndex] = _expense;

        emit ExpenseSettled(
            msg.sender,
            _recipient,
            _expenseIndex,
            _expense.splitAmount[callerIndex]
        );
    }

    function getExpense(
        uint256 _index
    )
        public
        view
        returns (
            address,
            address,
            address[] memory,
            uint256[] memory,
            string memory
        )
    {
        if (_index >= expenses.length) revert Expense_Out_of_Bounds();
        Expense memory expense = expenses[_index];
        return (
            expense.payer,
            expense.to,
            expense.splitBy,
            expense.splitAmount,
            expense.description
        );
    }

    function deposit() public payable {
        if (msg.value == 0) revert ZeroAmountDeposit();
        balances[msg.sender] += msg.value;

        // if (users.indexOf(msg.sender) == -1) users.push(msg.sender);
    }

    function withdraw(address to, uint256 amount) public {
        if (balances[msg.sender] <= amount) revert Insufficient_Balance();

        balances[msg.sender] -= amount;

        (bool success, ) = payable(to).call{value: amount}("");
        if (!success) revert Transfer_Failed();
    }

    function getbalance(address _user) public view returns (uint256) {
        return balances[_user];
    }

    fallback() external {
        deposit();
    }
}