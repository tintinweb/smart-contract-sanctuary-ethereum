// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

// Author: @leopico

contract MultisigWallet {
    event Deposite(address indexed sender, uint amount); //deposite to contract's address
    event Submit(uint indexed txId); //tx is submited and store tx then waiting for other owners approve
    event Approve(address indexed owner, uint indexed txId); //action from other owners
    event Revoke(address indexed owner, uint indexed txId); //action from other owners
    event Execute(uint indexed txId); // after other owners approved then tx will be aproved

    struct Transcation {
        // after required owners approved then will be storage in struct
        address to; //tx of the executed
        uint value; //send amount of eth
        bytes data; //data of the send address
        bool executed; //when the tx is executed we will set executed
    }

    address[] public owners; //store of some owners addresses
    mapping(address => bool) public isOwner; //only the owner will be able to call inside the contract so that have to check with mapping that address is owners or not
    uint public required; //numbers of owner to approve for tx
    address public deployer; //who deployed the contract

    Transcation[] public transcations; //will store all tx in the struct
    mapping(uint => mapping(address => bool)) public approved; //(uint)->index of the tx / (address)->address of the owner / (bool)->all the owners approve or not/  each tx will be executed if the number of approval is greater than or equal to required

    modifier onlyOwner() {
        require(isOwner[msg.sender], "not owner");
        _;
    }

    modifier txExists(uint _txId) {
        //check tx is have or not
        require(_txId < transcations.length, "tx does not exist");
        _;
    }

    modifier notApproved(uint _txId) {
        //check have to approve or not
        require(!approved[_txId][msg.sender], "tx already approved");
        _;
    }

    modifier notExecuted(uint _txId) {
        //check not yet executed or not
        require(!transcations[_txId].executed, "tx already executed");
        _;
    }

    constructor(address[] memory _owners, uint _required) {
        deployer = msg.sender;
        require(_owners.length > 0, "owners required");
        require(
            _required > 0 && _required <= _owners.length,
            "invalid required number of owners"
        );
        for (uint i; i < _owners.length; i++) {
            address owner = _owners[i];
            require(owner != address(0), "invalid owner");
            require(!isOwner[owner], "owner is not unique");
            isOwner[owner] = true;
            owners.push(owner); //final step that is store of new owners
        }
        required = _required; //required of owners for approving
    }

    receive() external payable {
        emit Deposite(msg.sender, msg.value);
    }

    function submit(
        address _to,
        uint _value,
        bytes calldata _data
    ) external onlyOwner {
        transcations.push(
            Transcation({
                to: _to,
                value: _value,
                data: _data,
                executed: false //for checking for notExecuted(_txId)
            })
        );
        emit Submit(transcations.length - 1);
    }

    function approve(
        uint _txId
    ) external onlyOwner txExists(_txId) notApproved(_txId) notExecuted(_txId) {
        approved[_txId][msg.sender] = true;
        emit Approve(msg.sender, _txId);
    }

    function _getApprovalCount(uint _txId) private view returns (uint count) {
        //count the number of approval
        for (uint i; i < owners.length; i++) {
            if (approved[_txId][owners[i]]) {
                count += 1;
            }
        }
    }

    function execute(uint _txId) external txExists(_txId) notExecuted(_txId) {
        require(_getApprovalCount(_txId) >= required, "approvals < required");
        Transcation storage transcation = transcations[_txId]; //store transcations
        transcation.executed = true;
        (bool success, ) = transcation.to.call{value: transcation.value}(
            transcation.data
        );
        require(success, "tx failed");
        emit Execute(_txId);
    }

    function revoke(
        uint _txId
    ) external onlyOwner txExists(_txId) notExecuted(_txId) {
        require(approved[_txId][msg.sender], "tx not approved");
        approved[_txId][msg.sender] = false;
        emit Revoke(msg.sender, _txId);
    }

    function getOwners() public view returns (address[] memory) {
        return owners;
    }
}