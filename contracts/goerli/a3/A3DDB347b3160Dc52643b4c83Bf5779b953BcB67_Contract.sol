/**
 *Submitted for verification at Etherscan.io on 2023-03-03
*/

pragma solidity ^0.8.18;

contract Contract{

    address payable public owner;

    uint public total_pool;
    uint[] public pool_state; // 0 = closed, 1 = open;
    uint[] public is_pool_ended;
    uint[] public init_amount;
    uint[] public pool_amount;
    uint[] public total_participants;
    mapping(uint => mapping(address => uint)) public participant_id;
    mapping(uint => mapping(uint => uint)) public participant_amount;
    mapping(uint => mapping(uint => address)) public address_of_participant;

    uint public fee_amount; // If fee is x%, then this value is set to x * 100;
    uint public total_fee;
    uint public extra_value; // extra ether left because of rounded division operation or received by fallback function

    event feeSet(uint value);
    event feeGot(uint value);
    event extraValueGot(uint value);
    event poolAdded(uint pool_id, uint init_amount);
    event etherAddedIntoPool(address participant, uint participant_id, uint pool_id, uint amount_added_this_time, uint total_amonut_of_participant);
    event poolStateChanged(uint state_before, uint state_after);
    event poolEnded(uint pool_id, uint result);
    event etherSent(address receiver, uint value);

    constructor() {
        owner = payable(msg.sender);
        total_pool = 0;
        pool_state.push(0);
        is_pool_ended.push(1);
        init_amount.push(0);
        pool_amount.push(0);
        total_participants.push(0);
        fee_amount = 0;
        total_fee = 0;
        extra_value = 0;
    }

    modifier ownerOnly {
        require(msg.sender == owner, "Sender is not owner!");
        _;
    }

    function setFee(uint value) public ownerOnly {
        require(value <= 10000);
        fee_amount = value;
        emit feeSet(value);
    }

    function newPool() public payable ownerOnly {
        total_pool = total_pool + 1;
        pool_state.push(0);
        is_pool_ended.push(0);
        init_amount.push(msg.value);
        pool_amount.push(0);
        total_participants.push(0);
        emit poolAdded(total_pool, init_amount[total_pool]);
    }

    function setPoolState(uint pool_id, uint state) public ownerOnly {
        require(pool_id <= total_pool, "Invalid pool id!");
        require(pool_state[pool_id] != state, "No state change needed!");
        require(is_pool_ended[pool_id] == 0, "Pool has ended!");
        pool_state[pool_id] = state;
        emit poolStateChanged(pool_state[pool_id], state);
    }

    function addEtherIntoPool(uint pool_id) public payable {
        require(pool_id <= total_pool, "Invalid pool id!");
        require(is_pool_ended[pool_id] == 0, "Pool has ended!");
        require(pool_state[pool_id] == 1, "Pool currently closed!");
        if(participant_id[pool_id][msg.sender] == 0){
            total_participants[pool_id] = total_participants[pool_id] + 1;
            participant_id[pool_id][msg.sender] = total_participants[pool_id];
            address_of_participant[pool_id][total_participants[pool_id]] = msg.sender;
        }
        uint id = participant_id[pool_id][msg.sender];
        uint value = msg.value;
        pool_amount[pool_id] = pool_amount[pool_id] + value;
        participant_amount[pool_id][id] = participant_amount[pool_id][id] + value;
        emit etherAddedIntoPool(msg.sender, id, pool_id, value, participant_amount[pool_id][id]);
    }

    function endPool(uint pool_id, uint result, address payable receiver) public ownerOnly {
        require(pool_id <= total_pool, "Invalid pool id!");
        require(is_pool_ended[pool_id] == 0, "Pool has ended!");
        require(result == 1 || result == 2, "Invalid result code!");
        if(pool_state[pool_id] == 1) setPoolState(pool_id, 0);
        // result: 1 = hacked, 2 = not hacked
        if(result == 1){
            uint total = init_amount[pool_id] + pool_amount[pool_id];
            uint fee = total * fee_amount / 10000;
            total = total - fee;
            total_fee = total_fee + fee;
            emit feeGot(fee);
            receiver.transfer(init_amount[pool_id] + pool_amount[pool_id]);
            emit etherSent(receiver, total);
            is_pool_ended[pool_id] = 1;
            emit poolEnded(pool_id, result);
        }
        if(result == 2){
            uint id = 1;
            uint total = init_amount[pool_id] + pool_amount[pool_id];
            uint fee = total * fee_amount / 10000;
            total = total - fee;
            total_fee = total_fee + fee;
            emit feeGot(fee);
            uint sum = 0;
            while(id <= total_participants[pool_id]){
                uint value = total * participant_amount[pool_id][id] / pool_amount[pool_id];
                sum = sum + value;
                payable(address_of_participant[pool_id][id]).transfer(value);
                emit etherSent(address_of_participant[pool_id][id], value);
                id = id + 1;
            }
            extra_value = extra_value + total - sum;
            emit extraValueGot(total - sum);
            is_pool_ended[pool_id] = 1;
            emit poolEnded(pool_id, result);
        }
    }

    function forceEnd(uint pool_id) public ownerOnly {
        require(pool_id <= total_pool, "Invalid pool id!");
        require(is_pool_ended[pool_id] == 0, "Pool has ended!");
        if(pool_state[pool_id] == 1) setPoolState(pool_id, 0);
        is_pool_ended[pool_id] = 0;
        emit poolEnded(pool_id, 3);
        extra_value = extra_value + init_amount[pool_id] + pool_amount[pool_id];
        emit extraValueGot(init_amount[pool_id] + pool_amount[pool_id]);
    }

    function removeFee() public ownerOnly {
        owner.transfer(total_fee);
        emit etherSent(owner, total_fee);
        total_fee = 0;
    }

    function removeExtraValue() public ownerOnly {
        owner.transfer(extra_value);
        emit etherSent(owner, extra_value);
        extra_value = 0;
    }

    function removeFeeAndExtraValue() public ownerOnly {
        removeFee();
        removeExtraValue();
    }

    function removeFund(uint value) public ownerOnly {
        require(address(this).balance >= value, "Not enough balance!");
        owner.transfer(value);
        emit etherSent(owner, value);
    }
    
    function removeAllFund() public ownerOnly {
        uint value = address(this).balance;
        owner.transfer(value);
        emit etherSent(owner, value);
    }

    receive() external payable {
        extra_value = extra_value + msg.value;
        emit extraValueGot(msg.value);
    }
    
    fallback() external payable {
        extra_value = extra_value + msg.value;
        emit extraValueGot(msg.value);
    }
}