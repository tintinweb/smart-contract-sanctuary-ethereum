// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract Wallet {
    address private _owner; // Owner's address
    address private _voting1; // The 1st voting's address
    address private _voting2; // The 2nd voting's address
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    struct Transaction {
        address to; // Where?
        uint256 amount; // How much?
        bool[3] arr; // List of votings
        bool isSend; // Done?
    }

    Transaction[] private _transactions;

    modifier isOwner() {
        require(msg.sender == _owner, "Only for owner");
        _;
    }

    modifier isVoter() {
        require(msg.sender == _owner || msg.sender == _voting1 || msg.sender == _voting2, "Only for voitings");
        _;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }

    event SetVater(address indexed newVater, uint256 indexed id);
    event Payable(address indexed sender, uint256 indexed amount);
    event NewTransaction(uint256 indexed idTransaction, address indexed to, uint256 indexed amount);
    event ConfTransaction(address indexed who, uint256 indexed idTransaction);
    event CallETH(address indexed to, uint256 indexed amount);

    constructor() {
        _owner = msg.sender;
        _status = _NOT_ENTERED;
    }

    /// @notice Getting ETH
    receive() external payable {
        emit Payable(msg.sender, msg.value);
    }

    /// @notice Change the voiting's address
    /// @param _newVater The new voiting's address
    /// @param _id Id voting
    function setVater(address _newVater, uint8 _id) external isOwner {
        require(_id == 1 || _id == 2, "Id voting is wrong");
        require(_newVater != _owner, "The voting address is wrong");
        require(((_id == 1) && (_voting2 != _newVater)) || ((_id == 2) && (_voting1 != _newVater)), "The voting address is wrong");

        if (_id == 1) _voting1 = _newVater;
        else _voting2 = _newVater;

        emit SetVater(_newVater, _id);
    }

    /// @notice Create the transaction
    /// @param _to Address of the recipient
    /// @param _amount Sum
    function newTransaction(address _to, uint256 _amount) external isVoter {
        require(_to != address(0), "Address of the recipient is not correct");
        require(address(this).balance >= _amount, "Not enough ETH on contract");
        _transactions.push(Transaction({to: _to, amount: _amount, arr: [false, false, false], isSend: false})); // Add the new transaction
        emit NewTransaction(_transactions.length - 1, _to, _amount);
    }

    /// @notice Vote for a transaction
    /// @param _idTransaction Id transaction
    function confTransaction(uint256 _idTransaction) external isVoter {
        require(_transactions[_idTransaction].isSend == false, "Transaction already sent");
        require(msg.sender != _transactions[_idTransaction].to, "You can't vote for yourself");

        emit ConfTransaction(msg.sender, _idTransaction);

        if (voice(_transactions[_idTransaction].arr, msg.sender)) {
            safeWithdraw(_idTransaction);
        }
    }

    /// @notice Get one transaction
    /// @param _idTransaction Id transaction
    /// @return Transaction Transaction Information
    function getTransactions(uint256 _idTransaction) external view returns (Transaction memory) {
        return _transactions[_idTransaction];
    }

    /// @notice Get balance of wallet
    /// @return uint256 Balance of walet
    function walletBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /// @notice Get address voiting's address
    /// @param _id id voiting's
    function getVater(uint8 _id) external view isOwner returns (address) {
        require(_id == 1 || _id == 2, "Id voting is wrong"); //
        if (_id == 1) return _voting1;
        if (_id == 2) return _voting2;
        return address(0);
    }

    /// @notice Safe withdrawal of ETH from the wallet
    /// @param _idTransaction Id Transaction
    function safeWithdraw(uint256 _idTransaction) private isVoter nonReentrant {
        require(_transactions[_idTransaction].isSend == false, "Transaction already sent"); //
        require(address(this).balance >= _transactions[_idTransaction].amount, "Not enough ETH on contract"); //
        _transactions[_idTransaction].isSend = true; // Send transaction
        (bool sent, ) = (_transactions[_idTransaction].to).call{value: _transactions[_idTransaction].amount}(""); // Send transaction
        require(sent, "Failed to send Ether");
        emit CallETH(_transactions[_idTransaction].to, _transactions[_idTransaction].amount);
    }

    /// @notice Vote and check the number of votes
    /// @param _arr List of votings
    /// @param _sender Voting
    /// @return bool Enough votes?
    function voice(bool[3] storage _arr, address _sender) private returns (bool) {
        if (_sender == _owner) _arr[0] = true;
        else if (_sender == _voting1) _arr[1] = true;
        else if (_sender == _voting2) _arr[2] = true;

        return ((_arr[0] && _arr[1]) || (_arr[0] && _arr[2]) || (_arr[1] && _arr[2]));
    }
}