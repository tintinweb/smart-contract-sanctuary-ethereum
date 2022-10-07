/**
 *Submitted for verification at Etherscan.io on 2022-10-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Multisig {
    struct Transaction {
        address dst;
        uint256 value;
        bytes data;
        bool isExecuted;
        uint256 blockNumber;
    }

    uint8 public quorum;
    uint128 public ttl;
    mapping(uint256 => Transaction) public txs;
    uint256 public txsCount;
    mapping(uint256 => mapping(address => bool)) public confirms;
    mapping(address => bool) public isOwner;
    address[] public owners;

    event Submission(uint256 indexed txId);
    event Confirmation(address indexed sender, uint256 indexed txId);
    event Revocation(address indexed sender, uint256 indexed txId);
    event Execution(uint256 indexed txId);
    event QuorumChange(uint8 quorum);
    event OwnerAddition(address indexed owner);
    event OwnerRemoval(address indexed owner);

    modifier onlySelf() {
        require(msg.sender == address(this), "only self");
        _;
    }

    modifier onlyOwner(address owner_) {
        require(isOwner[owner_], "only owner");
        _;
    }

    modifier whenNotConfirmed(uint256 txId_, address owner_) {
        require(!confirms[txId_][owner_], "tx is confirmed");
        _;
    }

    modifier whenNotExecuted(uint256 txId) {
        require(!txs[txId].isExecuted, "tx is executed");
        _;
    }

    modifier quorumIsValid(uint8 ownersCount_, uint8 quorum_) {
        require(
            quorum_ <= ownersCount_ && quorum_ != 0 && ownersCount_ != 0,
            "invalid quorum"
        );
        _;
    }

    constructor(
        address[] memory owners_,
        uint8 quorum_,
        uint128 ttl_
    ) quorumIsValid(uint8(owners_.length), quorum_) {
        for (uint8 i = 0; i < owners_.length; i++) {
            address owner = owners_[i];
            require(owner != address(0), "zero address");
            require(!isOwner[owner], "owner is duplicated");
            isOwner[owner] = true;
        }

        owners = owners_;
        quorum = quorum_;
        ttl = ttl_;
    }

    receive() external payable {}

    function addOwner(address owner_)
        external
        onlySelf
        quorumIsValid(uint8(owners.length + 1), quorum)
    {
        require(owner_ != address(0), "zero address");
        require(!isOwner[owner_], "only not owner");
        isOwner[owner_] = true;
        owners.push(owner_);
        emit OwnerAddition(owner_);
    }

    function removeOwner(address owner_) external onlySelf onlyOwner(owner_) {
        isOwner[owner_] = false;
        for (uint8 i = 0; i < owners.length - 1; i++) {
            if (owners[i] == owner_) {
                owners[i] = owners[owners.length - 1];
                break;
            }
        }
        owners.pop();
        if (quorum > owners.length) {
            setQuorum(uint8(owners.length));
        }
        emit OwnerRemoval(owner_);
    }

    function setQuorum(uint8 quorum_)
        public
        onlySelf
        quorumIsValid(uint8(owners.length), quorum_)
    {
        quorum = quorum_;
        emit QuorumChange(quorum_);
    }

    function submitTransaction(
        address dst_,
        uint256 value_,
        bytes calldata calldata_
    ) external onlyOwner(msg.sender) returns (uint256 txId) {
        require(dst_ != address(0), "zero address");
        txId = txsCount;
        txs[txId] = Transaction({
            dst: dst_,
            value: value_,
            data: calldata_,
            isExecuted: false,
            blockNumber: block.number
        });
        txsCount = txId + 1;
        emit Submission(txId);
    }

    function confirmTransaction(uint256 txId_)
        external
        onlyOwner(msg.sender)
        whenNotConfirmed(txId_, msg.sender)
    {
        require(txs[txId_].dst != address(0), "txId is incorrect");
        confirms[txId_][msg.sender] = true;
        emit Confirmation(msg.sender, txId_);
    }

    function revokeConfirmation(uint256 txId_)
        external
        onlyOwner(msg.sender)
        whenNotExecuted(txId_)
    {
        require(confirms[txId_][msg.sender], "tx is not confirmed");
        confirms[txId_][msg.sender] = false;
        emit Revocation(msg.sender, txId_);
    }

    function executeTransaction(uint256 txId_) external whenNotExecuted(txId_) {
        require(isConfirmed(txId_), "is not confirmed");
        Transaction storage tx_ = txs[txId_];
        require(tx_.blockNumber + ttl >= block.number, "tx too old");
        tx_.isExecuted = true;
        emit Execution(txId_);
        (bool success, ) = tx_.dst.call{value: tx_.value}(tx_.data);
        require(success, "execution failure");
    }

    function isConfirmed(uint256 txId_) public view returns (bool) {
        uint8 count = 0;
        for (uint8 i = 0; i < owners.length; i++) {
            if (confirms[txId_][owners[i]]) count++;
            if (count == quorum) return true;
        }

        return false;
    }

    function getConfirmationsCount(uint256 txId_)
        external
        view
        returns (uint8 count)
    {
        for (uint8 i = 0; i < owners.length; i++)
            if (confirms[txId_][owners[i]]) count++;
    }

    function getConfirmations(uint256 txId_)
        external
        view
        returns (address[] memory confirms_)
    {
        uint8 i = 0;
        uint8 count = 0;
        address[] memory tmp = new address[](owners.length);
        for (; i < owners.length; i++) {
            address owner = owners[i];
            if (confirms[txId_][owner]) {
                tmp[count] = owner;
                count++;
            }
        }

        confirms_ = new address[](count);
        for (i = 0; i < count; i++) confirms_[i] = tmp[i];
    }
}