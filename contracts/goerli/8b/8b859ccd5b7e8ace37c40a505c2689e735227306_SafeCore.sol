//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface IOrgValidatorCore {
    struct Transaction {
        address to;
        uint256 value;
        bytes data;
    }

    struct Signature {
        uint256 actingRole;
        address signer;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    function validateAuthorizationTransaction(Transaction calldata transaction, Signature[] calldata signatures) external;
}

contract SafeCore {
    IOrgValidatorCore public validator;
    string public name;

    event TransactionConfirmed(IOrgValidatorCore.Transaction transaction, IOrgValidatorCore.Signature[] signatures);

    function initialize(address _validator, string memory _name) public {
        validator = IOrgValidatorCore(_validator);
        name = _name;
    }

    function execTransaction(IOrgValidatorCore.Transaction memory transaction, IOrgValidatorCore.Signature[] memory signatures)
        public
    {
        validator.validateAuthorizationTransaction(transaction, signatures);
        transaction.to.call{value: transaction.value}(transaction.data);
        emit TransactionConfirmed(transaction, signatures);
    }
}