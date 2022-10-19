/**
 *Submitted for verification at Etherscan.io on 2022-10-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//Multi-signature wallet requires multiple signers to transact.
contract multiSigWallet {

    // Events for notifocation

    event Deposit(address indexed sender, uint amount, uint balance);

    // Payable address can receive Ether
    address[]  public owners;
    mapping(address => bool) public approver;
    //setup the number of confirmation
    uint public numConfirmationsRequired;

    //Save the transfer list
    struct Transfer { uint id; address payable _to; uint _amount; uint approvals; bool sent;}
    Transfer[] Transfers;
    //Mapping a transfer ID to address and value
    mapping(uint => mapping(address => bool)) isConfirmed;

    //Payable constructor can receive Ether

    constructor(address[] memory _owners, uint  _numConfirmationsRequired) payable {
        require((_owners.length >= _numConfirmationsRequired) && (_numConfirmationsRequired > 0), "Not possible");  
        owners = _owners;
        numConfirmationsRequired = _numConfirmationsRequired; 
        for ( uint i = 0; i< owners.length; i++) {
            require(!approver[owners[i]], 'owner not unique');
            approver[owners[i]] = true;
        }
    }

    //Receive ether
    receive() external payable { emit Deposit(msg.sender, msg.value, address(this).balance);}

    // Add a new approver to the group
    function addApprover(address _approver) external onlyOwner {
        owners.push(_approver);
        approver[_approver] = true;
    }


    
    //Create a modifier of owners
     modifier onlyOwner() {
        require(approver[msg.sender], "not owner");
        _;
    }



    //Create a transfer 

    function createTransfer(address payable _to, uint _value) external onlyOwner {
        Transfers.push(Transfer(Transfers.length, _to, _value, 0, false));
        //emit SubmitTranfer();
    }

    //Confirm a transaction
    function confirmTransfer(uint _id) public onlyOwner {
        Transfer storage transfer = Transfers[_id];
        transfer.approvals += 1;
        isConfirmed[_id][msg.sender] = true;
    }

    //Execute the transaction
    function executeTransaction(uint _id) external onlyOwner {
        Transfer storage transfer = Transfers[_id];
        require(transfer.approvals >= numConfirmationsRequired, 'cannot execute tx');
        (bool success, ) = transfer._to.call{value: transfer._amount}('');
        require(success, "tx failed");
        transfer.sent = true;
    }

    //Get a list of transfer


    //Get the owner

      function getOwners() public view returns (address[] memory) {
        return owners;
    }
    // 
    function getTransactionCount() public view returns (uint) {
        return Transfers.length;
    }

    
 
}