/**
 *Submitted for verification at Etherscan.io on 2022-03-11
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

contract OpenSeed{

    struct Map {
        address[] keys;
        mapping(address => uint) indexOf;
        mapping(address => bool) inserted;
        mapping(address => Proposal []) values;
    }

    struct Proposal {
        uint block_number;
        bytes32 desc;
        bytes32 data_sha256;
        bytes32 data_ipfs;
        bytes32 doi;
        bytes32 seed; //next block hash
        State state;
    }
    
    enum State { Created, Updated, Locked }

    Map private map; //(address, proposals))

    event _stateChange(address,uint,State);
    event _seed(address,uint,bytes32);

    /**
    returns prop_id
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
    
        Proposal memory prop = Proposal(block.number, _desc,_data_sha256,_data_ipfs,
        0x0000000000000000000000000000000000000000000000000000000000000000,
        0x0000000000000000000000000000000000000000000000000000000000000000,  //0x7465737400000000000000000000000000000000000000000000000000000000
        State.Created);

        map.values[msg.sender].push(prop);

        uint prop_id = getUserPropsNum(msg.sender) - 1;

        emit _stateChange(msg.sender, prop_id, State.Created);

        return prop_id;
    }


    /**
    returns seed
    **/
    function update(
        uint _prop_id)
        checkUser(msg.sender)
        checkProp(msg.sender,_prop_id)
        checkState(msg.sender,_prop_id, State.Created)
    external returns (bytes32){

        Proposal storage prop = map.values[msg.sender][_prop_id];
        bytes32 seed = blockhash(prop.block_number + 1);
        prop.seed = seed;
        prop.state = State.Updated;

        emit _stateChange(msg.sender, _prop_id, State.Updated);
        emit _seed(msg.sender, _prop_id, seed);

        return seed;
    }


    function lock(
        uint _prop_id,
        bytes32 doi)
        checkUser(msg.sender)
        checkProp(msg.sender,_prop_id)
        checkState(msg.sender,_prop_id, State.Updated)
    external{
        
        Proposal storage prop = map.values[msg.sender][_prop_id];
        prop.doi = doi;
        prop.state = State.Locked;

        emit _stateChange(msg.sender, _prop_id, State.Locked);
    }
   
    function getOneProp(
        address user, 
        uint _prop_id)
        checkUser(user)
        checkProp(user,_prop_id)
        external view returns (Proposal memory){

        return map.values[user][_prop_id];
    }

    function getUserProps(
        address user)
        checkUser(user)
        external view returns (Proposal[] memory){
    
        return map.values[user];
    }

    function getUserPropsNum(
        address user) 
        checkUser(user)
        public view returns (uint){
        
        return map.values[user].length;
    }


    function getUsers() 
        external view returns (address[] memory){
            
            return map.keys;
        }

    modifier checkUser(address user){
        require(map.inserted[user], "Proposal Not Exist!");
        _;
    }
    
    modifier checkProp(address user, uint _prop_id){
        require(map.values[user].length > _prop_id, "Proposal Not Created!");
        _;
    }


    modifier checkState(address user,uint _prop_id, State state){
        Proposal memory prop = map.values[user][_prop_id];
        require(block.number > prop.block_number, "Please Waiting...");
        require(prop.state == state,  "Proposal State Error!");
        
        if (state == State.Created){
            require(block.number - prop.block_number <= 256, "Proposal Updated Timeout!" );
        }

        _;
    }

}