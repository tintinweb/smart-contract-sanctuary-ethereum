/**
 *Submitted for verification at Etherscan.io on 2022-04-27
*/

// SPDX-License-Identifier: MIT

// MTS-BDEV 27-04-2022  

pragma solidity ^0.8.9;

contract MultiSigWallet {
    event Deposit(address indexed sender, uint amount, uint balance);
    event SubmitTransaction(
        address indexed owner,
        uint indexed txIndex,
        address indexed to,
        uint value,
        bytes data
    );
    event ConfirmTransaction(address indexed owner, uint indexed txIndex);
    event RevokeConfirmation(address indexed owner, uint indexed txIndex);
    event ExecuteTransaction(address indexed owner, uint indexed txIndex);

    address[] public owners;
    mapping(address => bool) public isOwner;
    uint public numConfirmationsRequired;

    struct Transaction {
        address to;
        uint value;
        bytes data;
        bool executed;
        uint numConfirmations;
    }

    // mapping from tx index => owner => bool
    mapping(uint => mapping(address => bool)) public isConfirmed;

    Transaction[] public transactions;

    modifier onlyOwner() {
        require(isOwner[msg.sender], "not owner");
        _;
    }

    modifier txExists(uint _txIndex) {
        require(_txIndex < transactions.length, "tx does not exist");
        _;
    }

    modifier notExecuted(uint _txIndex) {
        require(!transactions[_txIndex].executed, "tx already executed");
        _;
    }

    modifier notConfirmed(uint _txIndex) {
        require(!isConfirmed[_txIndex][msg.sender], "tx already confirmed");
        _;
    }

    modifier onlyMainOwner() {
        require(msg.sender==owners[0], "not main owner");
        _;
    }

    //////////////////////////////////////////////////
    // modifier checkOwnerLength() {
    //     require(owners.length > 0, "owners required");
    //     require(
    //         numConfirmationsRequired > 0 && numConfirmationsRequired <= owners.length,
    //         "invalid number of required confirmations"
    //     );
    //     // Owner just unique
    //     for (uint i = 0; i < owners.length; i++) {
    //         address owner = owners[i];

    //         require(owner != address(0), "invalid owner");
    //         require(!isOwner[owner], "owner not unique"); // ถ้า owner มีอยู่แล้ว isOwner[owner] จะ true 

    //         isOwner[owner] = true;
    //         owners.push(owner);
    //     }
    //     _;
    // }
    /////////////////////////////////////////////////

    constructor (address[] memory _owners, uint _numConfirmationsRequired) { 
        require(_owners.length > 0, "owners required");
        require(
            _numConfirmationsRequired > 0 &&
                _numConfirmationsRequired <= _owners.length,
            "invalid number of required confirmations"
        );

        for (uint i = 0; i < _owners.length; i++) {
            address owner = _owners[i];

            require(owner != address(0), "invalid owner");
            require(!isOwner[owner], "owner not unique"); // ถ้า owner มีอยู่แล้ว isOwner[owner] จะ true 

            isOwner[owner] = true;
            owners.push(owner);
        }

        numConfirmationsRequired = _numConfirmationsRequired;
    }
    // constructor (address[] memory _owners, uint _numConfirmationsRequired) {
    //     owners = _owners;
    //     numConfirmationsRequired = _numConfirmationsRequired;
    // }

    // Helper function to deposit in Remix
    function deposit() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }
    
    // The amount of Ether stored in this contract
    function balanceOf() public view returns (uint) {
        uint balance = address(this).balance;
        return balance;
    }

    function submitTransaction(
        address _to,
        uint _value,
        bytes memory _data
    ) public onlyOwner {
        uint txIndex = transactions.length;

        transactions.push(
            Transaction({
                to: _to,
                value: _value,
                data: _data,
                executed: false,
                numConfirmations: 0
            })
        );

        emit SubmitTransaction(msg.sender, txIndex, _to, _value, _data);
    }

    function confirmTransaction(uint _txIndex)
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
        notConfirmed(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];
        transaction.numConfirmations += 1;
        isConfirmed[_txIndex][msg.sender] = true;

        emit ConfirmTransaction(msg.sender, _txIndex);
    }

    function executeTransaction(uint _txIndex)
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];

        require(
            transaction.numConfirmations >= numConfirmationsRequired,
            "cannot execute tx"
        );

        transaction.executed = true;

        (bool success, ) = transaction.to.call{value: transaction.value}(
            transaction.data
        );
        require(success, "tx failed");

        emit ExecuteTransaction(msg.sender, _txIndex);
    }

    function revokeConfirmation(uint _txIndex)
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];

        require(isConfirmed[_txIndex][msg.sender], "tx not confirmed");

        transaction.numConfirmations -= 1;
        isConfirmed[_txIndex][msg.sender] = false;

        emit RevokeConfirmation(msg.sender, _txIndex);
    }

    function getOwners() public view returns (address[] memory) {
        return owners;
    }

    function getTransactionCount() public view returns (uint) {
        return transactions.length;
    }

    function getTransaction(uint _txIndex)
        public
        view
        returns (
            address to,
            uint value,
            bytes memory data,
            bool executed,
            uint numConfirmations
        )
    {
        Transaction storage transaction = transactions[_txIndex];

        return (
            transaction.to,
            transaction.value,
            transaction.data,
            transaction.executed,
            transaction.numConfirmations
        );
    }

    //////////////////////////////////////////
    function setNewOwnerList() private {
        for (uint i = 0; i < owners.length; i++) {
            address owner = owners[i];

            require(owner != address(0), "invalid owner");
            require(!isOwner[owner], "owner not unique"); // ถ้า owner มีอยู่แล้ว isOwner[owner] จะ true 

            isOwner[owner] = true;
            owners.push(owner);
        }
    }
    
    function pushNewOwner(address _newOwner) public onlyMainOwner { // onlyOwner ให้ทุก owners สามารถ, onlyMainOwner ให้แค่ owner[0] เท่านั้น
        // Append to array
        // This will increase the array length by 1.
        owners.push(_newOwner);
        isOwner[_newOwner] = true;
    }

    // function popLastedOwner(uint i) public onlyOwner {
    //     // Remove last element from array
    //     // This will decrease the array length by 1
    //     owners.pop(i);
    // }
    function removeOwnerByIndex(uint i) public onlyMainOwner {
        isOwner[owners[i]] = false;
        owners[i] = owners[owners.length - 1];
        owners.pop();
    }

    function getOwnerByIndex(uint i) public onlyMainOwner view returns (address) { // only main owner can see
        return owners[i];
    }

    function pushNewNumConfirmation(uint num) public onlyMainOwner {
        numConfirmationsRequired = num;
    }
    //////////////////////////////////////////

}

// deploy ด้วย 3 owners และ 2 approvers
// ["0xdC147A1C62C2C83C8E2f6688706376269A346B02", "0x038F7131436B32e6a1133DC96612F856B258Ea92", "0xa0993817cdeaBC68B506b7972eB2BbA0D739A4aC"], 2
// ["0x5B38Da6a701c568545dCfcB03FcB875f56beddC4", "0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2", "0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db"], 2

// submit tx for send 1 eth to 0x123... บน Remix ตั้งค่า value หน่วย Ether พร้อมใส่ค่า 1 Ether (สอดคล้องกับจำนวนที่จะโอนใน submit tx) หลังจาก deploy แล้วให้กด deposit (โอน 1 Ether เข้า contract นี้) ก่อน owner ถึงจะ execute ได้ 
// 0x617F2E2fD72FD9D5503197092aC168c91465E7f2, 1000000000000000000, 0x00

// submit tx for contracts ในที่นี้ใช้ sample_contract.sol ส่ง value j = 123 (เรียกใช้ฟังก์ชั่น callMe(123) ซึ่งจะส่งไปแบบเข้ารหัส)
// sample_contract_address, 0, bytes_data