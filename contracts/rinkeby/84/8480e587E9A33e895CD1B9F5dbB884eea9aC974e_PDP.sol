//SPDX-License-Identifier: MIT

//pragma solidity >=0.6.0 <0.9.0;
pragma solidity ^0.6.6;
pragma experimental ABIEncoderV2;

contract PDP{
    //（mark）for safety random() usage
    uint rand_nonce; 

    struct PublicParams{
        bytes G1;
        bytes G2;
        bytes GT;
        bytes Zr;
        bytes g1;
        bytes g2;
    }
    struct ChallSet{
        bytes[] theta_i;
        bytes[] v_i;
    }
    struct Proof{
        bytes zita;
        bytes[] mu;
        bytes R;
        bytes RI;
        bytes d;
    }
    // a trade is a obj remarks one outsource process
    struct Trade{
        uint identifier;
        uint file_tag;
        address data_owner;
        address storage_owner_addr; 
        uint rent_fee;
        // an audit obj represent an audit process
        mapping(uint => Audit) audit_array;
        uint auditarr_size;
        // update obj
        UpdateMeta update_meta;
        // update result( true: successfully updated)
        bool update_result;
    }
    struct UpdateMeta{
        uint h_R;
        uint AAI;
    }
    struct Audit{
        Proof proof;
        ChallSet challset;
        bool result;
        uint verify_fee;
        address verifier;
    }
    struct StorageOwner{
        address storage_owner_addr;
        //space it has
        uint Nbits;
        uint deposit;
        bool available;
    }
    event hahaha(address winner, uint result);
    PublicParams public pp;

    //mappings 
    mapping(address => StorageOwner) public storage_owner_map;
    mapping(uint => Trade) public trade_map;

    //array
    StorageOwner[] storage_owner_array;
    uint[] identifier_array;

    //modifiers
    // only registered CSP are allowed 
    modifier onlyStorageOwner(){
        if(storage_owner_map[msg.sender].storage_owner_addr == address(0)){
            //revert OnlyStorageowner(msg.sender);
            //(mark)
            revert("Only registered storage owner are allowed.");
        } 
        _;
    }

    // Create pp once contract is deployed
    constructor (bytes memory _G1, bytes memory _G2, bytes memory _GT, bytes memory _Zr, bytes memory _g1, bytes memory _g2) public{
        pp.G1 = _G1;
        pp.G2 = _G2;
        pp.g1 = _g1;
        pp.g2 = _g2;
        pp.GT = _GT;
        pp.Zr = _Zr;
    }
    // storage_owner register function
    function register(uint Nbits) public payable{
        require(
            storage_owner_map[msg.sender].storage_owner_addr == address(0),
             "Storage owner already exist!"
        );
        // Proof of Space here(mark)

        StorageOwner memory s_owner = StorageOwner(msg.sender, Nbits, msg.value, true);
        // add to map
        storage_owner_map[msg.sender] = s_owner;
        // add to storage_owner_arr
        storage_owner_array.push(s_owner);
    }

    // rent function
    function rent(uint Nbits, uint rent_time) public payable 
        returns(uint, address, address, address){
        //mark
        address storage_owner_addr = mmatch(Nbits, rent_time);
        uint identifier = random();
        // add mapping entry
        Trade storage trade = trade_map[identifier];
        trade.identifier = identifier;
        trade.data_owner = msg.sender;
        trade.storage_owner_addr = storage_owner_addr;
        // add identifier to array
        identifier_array.push(identifier);
        // record client payed money
        trade.rent_fee = msg.value;

        return (identifier, trade.data_owner, msg.sender, trade.storage_owner_addr);
    }

    // mmatch  sub function
    // (mark) time is a factor
    function mmatch(uint Nbits, uint rent_time) private returns(address){
        for(uint i = 0; i < storage_owner_array.length; i++){
            if(storage_owner_array[i].Nbits >= Nbits 
            && storage_owner_array[i].available == true){
                //get the storage_owner obj
                StorageOwner storage storage_owner = storage_owner_array[i];
                //change the state to unavailable
                storage_owner.available = false;
                return storage_owner.storage_owner_addr;
            }
        }
        //(mark)
        revert("Could not find a suitable storage owner by now.");
    }


    // challenge function
    function challenge(uint trade_identifier, ChallSet memory chall_set) public payable returns(address, address){
        Trade storage trade = trade_map[trade_identifier];
        require(
            trade.identifier != uint(0),
            "Trade does not exist!"
        );
        require(
            trade.data_owner == msg.sender,
            "You cannot launch audit to other's trade."
        );

        Audit memory audit;
        audit.challset = chall_set;
        // client pay for future verifier
        audit.verify_fee = msg.value;
        trade.audit_array[trade.auditarr_size] = audit;
        trade.auditarr_size += 1;

        return (trade.data_owner, msg.sender);
    }

    // response function
    function response(
        uint trade_identifier, uint audit_array_index, Proof memory _proof
        ) public onlyStorageOwner returns(address, address){
        Trade storage trade = trade_map[trade_identifier];
        require(
            trade.identifier != uint(0),
            "Trade does not exist!"
        );
        require(
            trade.storage_owner_addr == msg.sender,
            "You cannot response to other's trade audit."
        );
        
        Proof storage proof = trade.audit_array[audit_array_index].proof;
        proof.d = _proof.d;
        proof.mu = _proof.mu;
        proof.R = _proof.R;
        proof.RI = _proof.RI;
        proof.zita = _proof.zita;

        return (trade.storage_owner_addr, msg.sender);
    }
    // verify function
    function verify(uint trade_identifier, uint audit_array_index, bool result) public{
        Trade storage trade = trade_map[trade_identifier];
        require(
            trade.identifier != uint(0),
            "Trade does not exist!"
        );
        require(
            trade.audit_array[audit_array_index].verifier == address(0),
            "This audit had been verified before."
        );
        trade.audit_array[audit_array_index].verifier = msg.sender;
        trade.audit_array[audit_array_index].result = result;
        // verifier get money from contract balance
        payable(msg.sender).transfer(trade.audit_array[audit_array_index].verify_fee);
    }
    // update-response
    function update(uint trade_identifier, UpdateMeta memory update_meta) public{
        Trade storage trade = trade_map[trade_identifier];
        require(
            trade.identifier != uint(0),
            "Trade does not exist!"
        );
        require(
            trade.storage_owner_addr == msg.sender,
            "You cannot update others trade data."
        );
        trade.update_meta = update_meta;
    }
    // update-verification
    function updateVer(uint trade_identifier, bool result, uint file_tag) public{
        Trade storage trade = trade_map[trade_identifier];
        require(
            trade.identifier != uint(0),
            "Trade does not exist!"
        );
        require(
            trade.data_owner == msg.sender,
            "You cannot verify others update data."
        );
        trade.update_result = result;
        setTag(trade_identifier, file_tag);
    }

    // set file tag
    // set Tag can be called from:
    // 1. updateVer(), set the updated filetag
    // 2. called by client, when he first outsource his data to CSP
    function setTag(uint trade_identifier, uint file_tag) public {
        Trade storage trade = trade_map[trade_identifier];
        require(
            trade.identifier != uint(0),
            "Trade does not exist!"
        );
        require(
            trade.data_owner == msg.sender,
            "You cannot set others filetag."
        );
        trade.file_tag = file_tag;
    }

    function retrieveIdentifierArr() public view returns(uint[] memory){
        return identifier_array;
    }

    // retrieve an audit information
    function retrieveAudit(uint trade_identifier, uint audit_array_index) public view returns(Audit memory){
        Trade storage trade = trade_map[trade_identifier];
        Audit storage audit = trade.audit_array[audit_array_index];
        return audit;
    }

    // (mark) Maybe this is uneccessary, because it is public ?
    // retrieve trade informations( except nested audit information )
    function retrieveTrade(uint trade_identifier) public view 
        returns(address data_owner, address storage_owner_addr, uint rent_fee){
        Trade storage trade = trade_map[trade_identifier];
        data_owner = trade.data_owner;
        storage_owner_addr = trade.storage_owner_addr;
        rent_fee = trade.rent_fee;
    }
        
    // random sub function
    function random() private returns(uint){
        rand_nonce = (rand_nonce + 1) % 100;
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, rand_nonce)));
    }
}