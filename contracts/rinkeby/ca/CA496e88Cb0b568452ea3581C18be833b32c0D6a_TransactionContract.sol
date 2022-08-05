// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract TransactionContract {
    struct Transaction {
        uint256 transaction_id;
        string place_no_id;
        string certificate_no_id;
        string transaction_date;
        string transaction_behavior;
        string transaction_volume;
        string target_place_no_id; //canBlank
    }

    struct Paction {
        uint256 paction_blockchain_id;
        string paction_no;
        string paction_type;
        string paction_issue_date;
        string paction_valid_date;
        string contact_name; //canBlank
        string contact_mail; //canBlank
        string contact_tel; //canBlank
        string place_no;
    }

    Transaction[] public transactions;
    Paction[] public pactions;

    mapping(uint256 => Transaction) public transactionMap;
    mapping(uint256 => Paction) public pactionMap;

    address public immutable owner;

    constructor() {
        owner = msg.sender;
    }

    function inputTransaction(
        uint256 _transaction_id,
        string memory _place_no_id,
        string memory _certificate_no_id,
        string memory _transaction_date,
        string memory _transaction_behavior,
        string memory _transaction_volume,
        string memory _target_place_no_id
    ) public {
        require(msg.sender == owner, "Sender is not the owner!!"); //not sure if this is needed or not?

        Transaction memory newTx = Transaction(
            _transaction_id,
            _place_no_id,
            _certificate_no_id,
            _transaction_date,
            _transaction_behavior,
            _transaction_volume,
            _target_place_no_id
        );
        transactions.push(newTx);
        transactionMap[_transaction_id] = newTx;
    }

    function inputPaction(
        uint256 _paction_blockchain_id,
        string memory _paction_no,
        string memory _paction_type,
        string memory _paction_issue_date,
        string memory _paction_valid_date,
        string memory _contact_name, //canBlank
        string memory _contact_mail, //canBlank
        string memory _contact_tel, //canBlank
        string memory _place_no
    ) public {
        require(msg.sender == owner, "Sender is not the owner!!"); //not sure if this is needed or not?

        Paction memory newPac = Paction(
            _paction_blockchain_id,
            _paction_no,
            _paction_type,
            _paction_issue_date,
            _paction_valid_date,
            _contact_name, //canBlank
            _contact_mail, //canBlank
            _contact_tel, //canBlank
            _place_no
        );

        pactions.push(newPac);
        pactionMap[_paction_blockchain_id] = newPac;
    }
}