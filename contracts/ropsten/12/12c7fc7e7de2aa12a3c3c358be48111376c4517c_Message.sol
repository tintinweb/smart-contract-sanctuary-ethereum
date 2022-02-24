/**
 *Submitted for verification at Etherscan.io on 2022-02-24
*/

pragma solidity ^0.8.7;

contract Message {
    
    struct Log {
        uint timestamp;
        address sender;
        uint amount;
        bytes name;
    }
   
    mapping(address => Log []) private receives;
    mapping(address => Log []) private sends;
    mapping(address => bytes) private keys;
    
    event Transfer(address indexed sender,address indexed receiver);
    event Create(address indexed sender);

    function createKey() public returns(bytes memory key){
        require(keys[msg.sender].length == 0); 
        keys[msg.sender] = abi.encodePacked(uint(keccak256(abi.encodePacked(block.timestamp,block.difficulty,msg.sender))));
        emit Create(msg.sender);
        return keys[msg.sender];
    }

    function getKey() public view returns(bytes memory){
        return keys[msg.sender];
    }

    function transfer(address to, bytes memory name) public payable{
        require(keys[msg.sender].length != 0 , "Key not created."); 
        require(msg.value > 0 , "Value is 0.");
        receives[to].push(Log(block.timestamp,msg.sender,msg.value,name));
        sends[msg.sender].push(Log(block.timestamp,to,msg.value,name));
        emit Transfer(msg.sender, to);
        payable(to).transfer(msg.value);
    }

    function getReceives(uint page, uint perPage) public view returns(Log [] memory items, uint total){
        require(page != 0, "Please specify the page from 1.");
        Log [] memory datas = receives[msg.sender];
        uint start = (page - 1) * perPage;
        uint end = page * perPage;
        if(end > datas.length || perPage == 0) end = datas.length;
        if(start > end) start = end;
        uint length = end - start;
        Log [] memory returnDatas = new Log[](length);
        uint point = 0;
        for (uint i = datas.length - start; i > datas.length - end; i--) {
            Log memory _data = datas[i-1];
            bytes memory _name = bytes(_data.name);
            for(uint8 s = 0; s < _name.length;s++){
                _name[s] =  _name[s] ^ keys[_data.sender][s%keys[_data.sender].length];
            }
            _data.name = _name;
            returnDatas[point] = _data;
            point++;
        }
        return (returnDatas, datas.length);
    }

    function getSends(uint page, uint perPage) public view returns(Log [] memory items, uint total){
        require(page != 0, "Please specify the page from 1.");
        Log [] memory datas = sends[msg.sender];
        uint start = (page - 1) * perPage;
        uint end = page * perPage;
        if(end > datas.length || perPage == 0) end = datas.length;
        if(start > end) start = end;
        uint length = end - start;
        Log [] memory returnDatas = new Log[](length);
        uint point = 0;
        for (uint i = datas.length - start; i > datas.length - end; i--) {
            Log memory _data = datas[i-1];
            bytes memory _name = bytes(_data.name);
            for(uint8 s = 0; s < _name.length;s++){
                _name[s] =  _name[s] ^ keys[msg.sender][s%keys[msg.sender].length];
            }
            _data.name = _name;
            returnDatas[point] = _data;
            point++;
        }
        return (returnDatas, datas.length);
    }

}