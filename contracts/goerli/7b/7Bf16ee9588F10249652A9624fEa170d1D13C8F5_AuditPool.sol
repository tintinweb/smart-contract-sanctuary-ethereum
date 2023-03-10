/**
 *Submitted for verification at Etherscan.io on 2023-03-10
*/

pragma solidity 0.6.12;
 
contract AuditPool{
 
    address payable public owner;
 
    uint public total_pool;
    uint[] public is_pool_ended;
    uint[] public is_pool_hacked;
    uint[] public init_amount;
    uint[] public start_time;
    uint[] public duration_time;
    address[] public auditing_contracts;
    address[] public receiver_of_init_amount;
    mapping(address => uint) public id_of_auditing_contracts;
    uint[] public pool_amount;
    uint[] public total_participants;
    uint[] public total_minus_fee;
    mapping(uint => mapping(address => uint)) public participant_id;
    mapping(uint => mapping(uint => uint)) public participant_amount;
    mapping(uint => mapping(uint => address)) public address_of_participant;
    mapping(uint => mapping(uint => uint)) public has_claimed_reward;
 
    uint public fee_amount; // If fee is x%, then this value is set to x * 100;
    uint public total_fee;
    uint public extra_value; // Extra ether received by fallback function (wtf?)
 
    event feeSet(uint value);
    event feeGot(uint value);
    event extraValueGot(uint value);
    event poolInitiated(uint pool_id, uint init_amount, uint duration);
    event etherAddedIntoPool(address participant, uint participant_id, uint pool_id, uint amount_added_this_time, uint total_amonut_of_participant);
    event poolEnded(uint pool_id, uint result);
    event etherSent(address receiver, uint value);
 
    constructor() public {
        owner = payable(msg.sender);
        total_pool = 0;
        is_pool_ended.push(1);
        is_pool_hacked.push(0);
        init_amount.push(0);
        start_time.push(0);
        duration_time.push(0);
        auditing_contracts.push(address(this));
        receiver_of_init_amount.push(address(this));
        pool_amount.push(0);
        total_participants.push(0);
        total_minus_fee.push(0);
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
 
    function initiatePool(address audited_contract, uint duration, address receiver) public payable {
        total_pool = total_pool + 1;
        uint pool_id = total_pool;
        is_pool_ended.push(0);
        is_pool_hacked.push(0);
        init_amount.push(msg.value);
        start_time.push(block.timestamp);
        duration_time.push(duration);
        auditing_contracts.push(audited_contract);
        receiver_of_init_amount.push(receiver);
        id_of_auditing_contracts[audited_contract] = pool_id;
        pool_amount.push(0);
        total_participants.push(0);
        total_minus_fee.push(0);
        emit poolInitiated(total_pool, init_amount[pool_id], duration_time[pool_id]);
    }
 
    function endPool(uint pool_id) private {
        is_pool_ended[pool_id] = 1;
        uint total = init_amount[pool_id] + pool_amount[pool_id];
        uint fee = total * fee_amount / 10000;
        total_fee = total_fee + fee;
        emit feeGot(fee);
        total_minus_fee[pool_id] = total - fee;
        emit poolEnded(pool_id, 1);
    }
 
    function check_is_pool_ended(uint pool_id) private returns (uint) {
        if(is_pool_ended[pool_id] == 1) return 1;
        if(start_time[pool_id] + duration_time[pool_id] < block.timestamp){
            endPool(pool_id);
        }
        return is_pool_ended[pool_id];
    }
 
    function addEtherIntoPool(uint pool_id) public payable {
        require(pool_id <= total_pool, "Invalid pool id!");
        check_is_pool_ended(pool_id);
        require(is_pool_ended[pool_id] == 0, "Pool has ended!");
        require(msg.value > 0, "No ether attached!");
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
 
    function claimReward(uint pool_id) public {
        require(pool_id <= total_pool, "Invalid pool id!");
        check_is_pool_ended(pool_id);
        require(is_pool_ended[pool_id] == 1, "Pool hasn't ended!");
        require(is_pool_hacked[pool_id] == 0, "The auditing contract has been hacked and the pool has been distributed!");
        uint id = participant_id[pool_id][msg.sender];
        require(id > 0, "This address didn't participate in this pool!");
        require(has_claimed_reward[pool_id][id] == 0, "Reward has been claimed!");
        uint value = total_minus_fee[pool_id] * participant_amount[pool_id][id] / pool_amount[pool_id];
        has_claimed_reward[pool_id][id] = 1;
        payable(msg.sender).transfer(value);
        emit etherSent(msg.sender, value);
    }
 
    function contractHacked(address receiver, uint portion) public {
        require(portion <= 10000, "Invalid portion assigned!");
        uint pool_id = id_of_auditing_contracts[msg.sender];
        require(pool_id > 0, "Invalid call of contractHacked!");
        require(check_is_pool_ended(pool_id) == 0, "Pool has ended!");
        endPool(pool_id);
        is_pool_hacked[pool_id] = 1;
        payable(receiver).transfer(total_minus_fee[pool_id] * portion / 10000);
        emit etherSent(msg.sender, total_minus_fee[pool_id]);
        if(portion < 10000){
            uint id = 1;
            while(id <= total_participants[pool_id]){
                uint value = (participant_amount[pool_id][id] * (10000 - fee_amount) / 10000) * (10000 - portion) / 10000;
                payable(address_of_participant[pool_id][id]).transfer(value);
                emit etherSent(address_of_participant[pool_id][id], value);
                id = id + 1;
            }
            uint value = (init_amount[pool_id] * (10000 - fee_amount) / 10000) * (10000 - portion) / 10000;
            payable(receiver_of_init_amount[pool_id]).transfer(value);
            emit etherSent(receiver_of_init_amount[pool_id], value);
        }
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
 
    receive() external payable {
        extra_value = extra_value + msg.value;
        emit extraValueGot(msg.value);
    }
 
    fallback() external payable {
        extra_value = extra_value + msg.value;
        emit extraValueGot(msg.value);
    }
}