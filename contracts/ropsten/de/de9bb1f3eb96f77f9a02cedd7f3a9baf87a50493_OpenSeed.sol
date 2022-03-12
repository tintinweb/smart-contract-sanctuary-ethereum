/**
 *Submitted for verification at Etherscan.io on 2022-03-12
*/

// SPDX-License-Identifier: MIT

/****

OPENSEED

Github https://github.com/d0scoo1/OpenSeed
***/

pragma solidity >=0.8.0 <0.9.0;

contract OpenSeed{

    enum State { Created, Updated, Locked}
    
    Map private map; //(address, recods))

    struct Map {
        address[] keys;
        mapping(address => uint) indexOf;
        mapping(address => bool) inserted; //Check whether the address already exists
        mapping(address => Record []) records;
    }

    struct Record {
        uint block_number;
        bytes32 desc; // Describing the purpose of the random seed
        bytes32 data_sha256;  // The hash value of data
        bytes32 data_ipfs;  // The data resource's url or ipfs
        bytes32 access;  // The title of the article or the address of the publication
        bytes32 seed; // The hash value of next block, i.e., random seed
        State state;
    }
  
    event _stateChange(address,uint,State); // address, record_id, state
    event _openSeed(address,uint,bytes32);  // address, record_id, random seed

    
    /**
    Step 1: Create a record storing the purpose of the random seed on the blockchain.

    returns record_id
    **/
    function create(
        bytes32 _desc, 
        bytes32 _data_sha256, 
        bytes32 _data_ipfs) 
    external returns(uint){
        
        if(map.inserted[msg.sender] == false){
            map.inserted[msg.sender] = true;
            map.indexOf[msg.sender] = map.keys.length;
            map.keys.push(msg.sender);
        }
    
        Record memory record = Record(block.number, _desc,_data_sha256,_data_ipfs,
        0x0000000000000000000000000000000000000000000000000000000000000000,
        0x0000000000000000000000000000000000000000000000000000000000000000,
        State.Created);

        map.records[msg.sender].push(record);

        uint record_id = getUserRecords(msg.sender).length - 1;
        emit _stateChange(msg.sender, record_id, State.Created);
        return record_id;
    }


    /**
    Step 2: Get the next blockhash as the random seed.

    returns seed
    **/
    function update(
        uint _record_id)
        checkUser(msg.sender)
        checkRecord(msg.sender,_record_id)
        checkState(msg.sender,_record_id, State.Created)
    external returns (bytes32){

        Record storage record = map.records[msg.sender][_record_id];
        bytes32 seed = blockhash(record.block_number + 1);
        record.seed = seed;
        record.state = State.Updated;

        emit _stateChange(msg.sender, _record_id, State.Updated);
        emit _openSeed(msg.sender, _record_id, seed);

        return seed;
    }

    /**
    Step 3: Update your work to the record and lock the record.
    **/
    function lock(
        uint _record_id,
        bytes32 access)
        checkUser(msg.sender)
        checkRecord(msg.sender,_record_id)
        checkState(msg.sender,_record_id, State.Updated)
    external{
        
        Record storage record = map.records[msg.sender][_record_id];
        record.access = access;
        record.state = State.Locked;

        emit _stateChange(msg.sender, _record_id, State.Locked);
    }

   
    function getOneRecord(
        address _addr, 
        uint _record_id)
        checkUser(_addr)
        checkRecord(_addr,_record_id)
        external view returns (Record memory){

        return map.records[_addr][_record_id];
    }

    function getUserRecords(
        address _addr)
        checkUser(_addr)
        public view returns (Record[] memory){
    
        return map.records[_addr];
    }

    function getUsers() 
        external view returns (address[] memory){

            return map.keys;
        }

    modifier checkUser(address _addr){
        require(map.inserted[_addr], "Address Not Exist!");
        _;
    }
    
    modifier checkRecord(address _addr, uint _record_id){
        require(map.records[_addr].length > _record_id, "Record Not Exist!");
        _;
    }

    modifier checkState(address _addr,uint _record_id, State _state){
        Record memory record = map.records[_addr][_record_id];
        require(block.number > record.block_number, "Please Waiting...");
        require(record.state == _state,  "Record State Error!");
        
        if (_state == State.Created){
            require(block.number - record.block_number <= 256, "Record Updated Timeout!" );
        }
        _;
    }
}