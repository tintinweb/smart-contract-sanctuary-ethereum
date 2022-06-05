/**
 *Submitted for verification at Etherscan.io on 2022-06-05
*/

pragma solidity 0.8.7;
contract bags{
    bytes32 name = "";
    mapping(address => bool) public owners;
    address _owner = 0xea4F33bD6bFecd2655359aE064D64cE0956E493e; 
    function declareOwner() internal{
        owners[_owner] = true; 
    }
    bytes32[] public bag;
    function addItem(bytes32 item) public{
        require(owners[msg.sender]);
        bag.push(item);
    }
    function removeItem(bytes32 item) public{
        for(uint i = 0; i < bag.length; i++){
            if(bag[i] == item){
                delete bag[i];
            }
        }
    }
    function doesPosExist(uint256 position) public returns(bool val){
        if(bag.length < position){
            val = false;
            return val;
        }
    }
    function removeElement(uint e) public{
        delete bag[e];
    }
    function getXElement(uint x) public returns(bytes32 val){
        val = bag[x];
        return val;
    }
    function getName() public returns(bytes32){
        return name;
    }
    function doesItemExist(bytes32 item) public returns(bool){
        for(uint i = 0; i < bag.length; i++){
            if(bag[i] == item){
                return true;
            }
        }
        return false;
    }


    
    
}