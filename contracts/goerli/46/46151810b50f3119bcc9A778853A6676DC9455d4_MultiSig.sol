// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Multi-Sig
 * @dev Multi Signature scheme for funds withdrawal from deposit contracts
 */

interface IDeposit {
    function withdraw(address to_, uint256 amount) external payable;

    function withdrawERC20(
        address token,
        address to_,
        uint256 amount
    ) external;
}

contract MultiSig {
    event Confirmation(address sender, bytes32 transactionHash);
    event Revocation(address sender, bytes32 transactionHash);
    event Submission(bytes32 transactionHash);
    event Execution(bytes32 transactionHash);
    event Deposit(address sender, uint256 value);
    event OwnerAddition(address owner);
    event OwnerRemoval(address owner);
    event RequiredUpdate(uint256 required);

    mapping(bytes32 => Transaction) public transactions;
    mapping(bytes32 => mapping(address => bool)) public confirmations;
    mapping(address => bool) public isOwner;
    address[] owners;
    bytes32[] transactionList;
    uint256 public required;

    struct Transaction {
        address depositAddress;
        address destination;
        address tokenAddress;
        uint256 value;
        bool executed;
    }

    modifier onlyWallet() {
        if (msg.sender != address(this)) revert();
        _;
    }

    modifier signaturesFromOwners(
        bytes32 transactionHash,
        uint8[] memory v,
        bytes32[] memory rs
    ) {
        for (uint256 i = 0; i < v.length; i++)
            if (
                !isOwner[
                    ecrecover(transactionHash, v[i], rs[i], rs[v.length + i])
                ]
            ) revert();
        _;
    }

    modifier ownerDoesNotExist(address owner) {
        if (isOwner[owner]) revert();
        _;
    }

    modifier ownerExists(address owner) {
        if (!isOwner[owner]) revert();
        _;
    }

    modifier confirmed(bytes32 transactionHash, address owner) {
        if (!confirmations[transactionHash][owner]) revert();
        _;
    }

    modifier notConfirmed(bytes32 transactionHash, address owner) {
        if (confirmations[transactionHash][owner]) revert();
        _;
    }

    modifier notExecuted(bytes32 transactionHash) {
        if (transactions[transactionHash].executed) revert();
        _;
    }

    modifier notNull(address destination) {
        if (destination == address(0x0)) revert();
        _;
    }

    modifier validRequired(uint256 _ownerCount, uint256 _required) {
        if (_required > _ownerCount || _required == 0 || _ownerCount == 0)
            revert();
        _;
    }

    function addOwner(address owner)
        external
        onlyWallet
        ownerDoesNotExist(owner)
    {
        isOwner[owner] = true;
        owners.push(owner);
        emit OwnerAddition(owner);
    }

    function removeOwner(address owner) external onlyWallet ownerExists(owner) {
        isOwner[owner] = false;
        for (uint256 i = 0; i < owners.length - 1; i++)
            if (owners[i] == owner) {
                owners[i] = owners[owners.length - 1];
                break;
            }
        owners.pop();
        if (required > owners.length) updateRequired(owners.length);
        emit OwnerRemoval(owner);
    }

    function updateRequired(uint256 _required)
        public
        onlyWallet
        validRequired(owners.length, _required)
    {
        required = _required;
        emit RequiredUpdate(_required);
    }

    function addTransaction(
        address depositAddress,
        address destination,
        address tokenAddress,
        uint256 value,
        uint256 nonce
    ) private notNull(destination) returns (bytes32 transactionHash) {
        transactionHash = keccak256(
            abi.encodePacked(
                depositAddress,
                destination,
                tokenAddress,
                value,
                nonce
            )
        );
        if (transactions[transactionHash].destination == address(0)) {
            transactions[transactionHash] = Transaction({
                depositAddress: depositAddress,
                destination: destination,
                tokenAddress: tokenAddress,
                value: value,
                executed: false
            });
            transactionList.push(transactionHash);
            emit Submission(transactionHash);
        }
    }

    function submitTransaction(
        address depositAddress,
        address destination,
        address tokenAddress,
        uint256 value,
        uint256 nonce
    ) external returns (bytes32 transactionHash) {
        transactionHash = addTransaction(
            depositAddress,
            destination,
            tokenAddress,
            value,
            nonce
        );
        confirmTransaction(transactionHash);
    }

    function addConfirmation(bytes32 transactionHash, address owner)
        private
        notConfirmed(transactionHash, owner)
    {
        confirmations[transactionHash][owner] = true;
        emit Confirmation(owner, transactionHash);
    }

    function confirmTransaction(bytes32 transactionHash)
        public
        ownerExists(msg.sender)
    {
        addConfirmation(transactionHash, msg.sender);
        executeTransaction(transactionHash);
    }

    function executeTransaction(bytes32 transactionHash)
        public
        notExecuted(transactionHash)
    {
        if (isConfirmed(transactionHash)) {
            Transaction storage txn = transactions[transactionHash];
            txn.executed = true;
            if (txn.tokenAddress != address(0)) {
                IDeposit(txn.depositAddress).withdrawERC20(
                    txn.tokenAddress,
                    txn.destination,
                    txn.value
                );
            } else {
                IDeposit(txn.depositAddress).withdraw(
                    txn.destination,
                    txn.value
                );
            }

            emit Execution(transactionHash);
        }
    }

    function revokeConfirmation(bytes32 transactionHash)
        external
        ownerExists(msg.sender)
        confirmed(transactionHash, msg.sender)
        notExecuted(transactionHash)
    {
        confirmations[transactionHash][msg.sender] = false;
        emit Revocation(msg.sender, transactionHash);
    }

    constructor(address[] memory _owners, uint256 _required)
        validRequired(_owners.length, _required)
    {
        for (uint256 i = 0; i < _owners.length; i++) isOwner[_owners[i]] = true;
        owners = _owners;
        required = _required;
    }

    receive() external payable {
        revert();
    }

    function isConfirmed(bytes32 transactionHash) public view returns (bool) {
        uint256 count = 0;
        for (uint256 i = 0; i < owners.length; i++)
            if (confirmations[transactionHash][owners[i]]) count += 1;
        if (count == required) return true;
        return false;
    }

    function confirmationCount(bytes32 transactionHash)
        external
        view
        returns (uint256 count)
    {
        for (uint256 i = 0; i < owners.length; i++)
            if (confirmations[transactionHash][owners[i]]) count += 1;
    }

    function filterTransactions(bool isPending)
        private
        view
        returns (bytes32[] memory _transactionList)
    {
        bytes32[] memory _transactionListTemp = new bytes32[](
            transactionList.length
        );
        uint256 count = 0;
        for (uint256 i = 0; i < transactionList.length; i++)
            if (
                (isPending && !transactions[transactionList[i]].executed) ||
                (!isPending && transactions[transactionList[i]].executed)
            ) {
                _transactionListTemp[count] = transactionList[i];
                count += 1;
            }
        _transactionList = new bytes32[](count);
        for (uint256 i = 0; i < count; i++)
            if (_transactionListTemp[i] > 0)
                _transactionList[i] = _transactionListTemp[i];
    }

    function getPendingTransactions()
        external
        view
        returns (bytes32[] memory _transactionList)
    {
        return filterTransactions(true);
    }

    function getExecutedTransactions()
        external
        view
        returns (bytes32[] memory _transactionList)
    {
        return filterTransactions(false);
    }
}