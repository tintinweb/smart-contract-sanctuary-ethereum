// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Web3Shop {
    uint256 private id;
    uint constant MINIMUM_DELAY = 10;
    uint constant MAXIMUM_DELAY = 7 days;
    uint constant GRACE_PERIOD = 7 days;
    address public owner;
    uint yearInSeconds;
    uint public constant CONFIRMATIONS_REQUIRED = 3; 
     
    // Statuses
    enum STATUS{
        Active,
        Sold,
        NotAvaliable,
        Prepearing,
        Delivering,
        Delivered,
        Recieved
    }


    // Item struct
    struct Item {
        uint256 id;
        string name;
        string description;
        uint256 price;
        address payable seller;
        address buyer;
        bool selled;
        STATUS status; 
    }

    struct Transaction {
        bytes32 uid;
        address to;
        uint value;
        bytes32 data;
        bool executed;
        uint confirmations;
    }

    // Mappings, TimeLock, MultiSig, Shop neccesaries
    mapping (uint256 => Item) private s_ItemId;
    mapping (bytes32 => bool) public queue;
    mapping (bytes32 => mapping(address => bool)) public confirmations;
    mapping (bytes32 => Transaction) public txs;
 
    // Event 
    event Agreement(
        uint256 id,
        string name,
        uint256 price,
        address payable seller,
        address buyer,
        bool selled
    );

    // TimeLock Events
    event Discarded(bytes32 txId);
    event Queued(bytes32 txId);
    event Executed(bytes32 txId);

    modifier ownerOfItem(uint256 index) {
        Item memory newItem = s_ItemId[index];
        require(msg.sender == newItem.seller, "You do not have a permission");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "You are not an owner");
        _;
    }


    constructor () {
        owner = msg.sender;
    }


    // List item
    function publicItem(
        uint256 price,
        string memory name,
        string memory desc
      ) public {
        Item memory newItem = Item(
            id,
            name,
            desc,
            price,
            payable(msg.sender),
            address(0),
            false,
            STATUS.Active
        );

        s_ItemId[id] = newItem;
        id++;
    }


    // Buy item
    function buyItem(uint256 _id, uint _timestamp) payable public {
        Item memory choosenItem = s_ItemId[_id];
        

        require(choosenItem.status != STATUS.NotAvaliable && 
                choosenItem.selled == false, 
                "Not avaliable for ordering"
                );
        require(msg.sender != choosenItem.seller, "Seller can not buy own Item");
        require(msg.value >= choosenItem.price, "Paid not enough :c");
        
        
        
        choosenItem.status == STATUS.Prepearing;
        choosenItem.buyer = msg.sender;


        emit Agreement(
            id,
            choosenItem.name,
            choosenItem.price,
            choosenItem.seller,
            msg.sender,
            false
        );

        bytes32 txId = countTxId(
                choosenItem.seller,
                msg.sender,
                msg.data,
                choosenItem.price,
                block.timestamp
            );
        
        addToQueue(_id, _timestamp, txId);
        
        
        emit Queued(txId);
    }


    // Change Item status
    function changeStatus(uint256 id_, STATUS status) public ownerOfItem(id_) view {
        Item memory choosenItem = s_ItemId[id_];

        require(msg.sender == choosenItem.seller, "You can not change status of order");
        require(status != choosenItem.status, "This status already exist");
              
        choosenItem.status = status;
    }


    // TimeLock
    function addToQueue(
            uint256 _id,
            uint _timestamp,
            bytes32 _data
        ) private returns(bytes32) {
        Item memory choosenItem = s_ItemId[_id];



        // TimeLock requires (limit for time)
        require(_timestamp > block.timestamp + MINIMUM_DELAY 
                        &&
                 _timestamp < block.timestamp + MAXIMUM_DELAY, 
                 "Not suitable timestamp"
                 );

        bytes32 txId = keccak256(abi.encode(
            choosenItem.seller,
            msg.sender,
            choosenItem.price,
            _timestamp
        ));

        txs[txId] = Transaction({
            uid: txId,
            to: choosenItem.seller,
            value: choosenItem.price,
            data: _data,
            executed: false,
            confirmations: 0
        });

        require(!queue[txId], "Already queued");

        emit Queued(txId);

        queue[txId] = true;
        
        return txId;
    }


    function confirm(bytes32 _txId, uint256 _id) external {
        Item memory choosenItem = s_ItemId[_id];


        require(queue[_txId], "Not queued!");

        require(
                msg.sender == choosenItem.seller 
                    ||
                msg.sender == choosenItem.buyer
                    ||
                msg.sender == owner,
                    "You can not confirm transaciton"    
                );

        require(!confirmations[_txId][msg.sender], "Already confirmed");

        Transaction storage transaction = txs[_txId];

        transaction.confirmations++;
        confirmations[_txId][msg.sender] = true;

    }


    // Delete transaction
    function discard(bytes32 _txId) external onlyOwner {
        require(queue[_txId], "Not queued");
        delete queue[_txId];
    }


    // Realisation of transaction
    function execute(
        address _to, // choosenItem.seller,
        address _from, // address(this) 
        bytes calldata _data,
        uint256 _price, // choosenItem.price,
        uint _timestamp // timestamp
    ) external payable onlyOwner returns(bytes memory) {

        require(block.timestamp > _timestamp, "Too early");
        require(_timestamp + GRACE_PERIOD > block.timestamp, "Tx expired");
        


        bytes32 txId = countTxId(
            _to,
            _from,
            _data,
            _price,
            _timestamp
        );

        Transaction storage transaction = txs[txId];

        require(transaction.confirmations >= CONFIRMATIONS_REQUIRED, "Not enough confirmations");

        delete queue[txId];
        
        transaction.executed = true;

        ( bool success, bytes memory resp) = _to.call{ value: _price }("");
        
        require(success);

        emit Executed(txId); 
        return resp;
    }


    function cancelConfirmation(bytes32 _txId) external {
        require(queue[_txId], "Not queued");
        require(confirmations[_txId][msg.sender], "Not confirmed");

        Transaction storage transaction = txs[_txId];
        transaction.confirmations--;
        confirmations[_txId][msg.sender] = false;
    }


    function countTxId(
        address _to, 
        address _from,
        bytes calldata _data,
        uint256 _price, 
        uint _timestamp 
    ) public pure returns(bytes32 txId) {
        txId = keccak256(abi.encodePacked(
            _to, 
            _from, 
            _data,
            _price,
           _timestamp 
        ));
    }
}