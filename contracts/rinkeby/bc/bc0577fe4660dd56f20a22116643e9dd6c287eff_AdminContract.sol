/**
 *Submitted for verification at Etherscan.io on 2022-09-26
*/

pragma solidity >=0.4.21 <0.7.0;

contract AdminContract{
    address public owner;

    producer[] public producers;
    User[] public retailers;
    User[] public consumers;
    User[] public recycleUnits;

    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }

    struct producer{
        address addr;
        bool ispresent;
        string name;
        uint penalize;
    }

    struct User{
        address addr;
        bool ispresent;
        string name;
    }

    constructor() public{
        owner = msg.sender;
    }

    function addProducer(address _pAddress,string memory _name) public returns(bool){
        if(!checkProducer(_pAddress)){
            producers.push(producer(_pAddress, true, _name,0));
            return true;
        }else{
            return false;
        }
    }

    function addRetailer(address _rAddress,string memory _name) public returns(bool){
        if(!checkRetailer(_rAddress)){
            retailers.push(User(_rAddress, true, _name));
            return true;
        }else{
            return false;
        }
    }

    function addConsumer(address _cAddress,string memory _name) public returns(bool){
        if(!checkConsumer(_cAddress)){
            consumers.push(User(_cAddress, true, _name));
            return true;
        }else{
            return false;
        }
    }

    function addRecycleUnit(address _rAddress,string memory _name) public returns(bool){
        if(!checkRecycleUnit(_rAddress)){
            recycleUnits.push(User(_rAddress, true, _name));
            return true;
        }else{
            return false;
        }
    }

    //validate users
    function checkProducer(address _address) public view returns(bool) {
        if(producers.length == 0){
            return false;
        }else{
            for (uint i=0; i<producers.length; i++){
                if(producers[i].addr == _address){
                    return producers[i].ispresent;
                }
            }
            return false;
        }
    }

    function checkRetailer(address _address) public view returns(bool) {
        if(retailers.length == 0){
            return false;
        }else{
            for (uint i=0; i<retailers.length; i++){
                if(retailers[i].addr == _address){
                    return retailers[i].ispresent;
                }
            }
            return false;
        }
    }

    function checkConsumer(address _address) public view returns(bool) {
        if(consumers.length == 0){
            return false;
        }else{
            for (uint i=0; i<consumers.length; i++){
                if(consumers[i].addr == _address){
                    return consumers[i].ispresent;
                }
            }
            return false;
        }
    }

    function checkRecycleUnit(address _address) public view returns(bool) {
        if(recycleUnits.length == 0){
            return false;
        }else{
            for (uint i=0; i<recycleUnits.length; i++){
                if(recycleUnits[i].addr == _address){
                    return recycleUnits[i].ispresent;
                }
            }
            return false;
        }
    }

    //returning length
    function getProducerCount() public view returns(uint){
        return producers.length;
    }

    function getRetailerCount() public view returns(uint){
        return retailers.length;
    }

    function getConsumerCount() public view returns(uint){
        return consumers.length;
    }

    function getRecyclingUintCount() public view returns(uint){
        return recycleUnits.length;
    }

    //return names
    function getProducerName(address _address) public view returns(string memory,uint){
        for(uint i=0; i<producers.length; i++){
            if(producers[i].addr == _address){
                return (producers[i].name,producers[i].penalize);
            }
        }
    }

    function getRetailerName(address _address) public view returns(string memory){
        for(uint i=0; i<retailers.length; i++){
            if(retailers[i].addr == _address){
                return retailers[i].name;
            }
        }
    }

    function getConsumerName(address _address) public view returns(string memory){
        for(uint i=0; i<consumers.length; i++){
            if(consumers[i].addr == _address){
                return consumers[i].name;
            }
        }
    }

    function getRecycleUnitName(address _address) public view returns(string memory){
        for(uint i=0; i<recycleUnits.length; i++){
            if(recycleUnits[i].addr == _address){
                return recycleUnits[i].name;
            }
        }
    }

    function addPenalizeAmount(uint _amount,address _producer) public {
        for(uint i=0; i<producers.length; i++){
            if(producers[i].addr == _producer){
                producers[i].penalize=_amount;
            }
        }
    }

    function payPenalizeAmount(address _producer) public payable {
        for(uint i=0; i<producers.length; i++){
            if(producers[i].addr == _producer){
                producers[i].penalize=0;
            }
        }
        address payable _admin=address(uint160(owner));
        _admin.transfer(msg.value);
    }

    function getPenalizeAmount(address _producer)public view returns(uint){
        for(uint i=0; i<producers.length; i++){
            if(producers[i].addr == _producer){
                return producers[i].penalize;
            }
        }
    }


}