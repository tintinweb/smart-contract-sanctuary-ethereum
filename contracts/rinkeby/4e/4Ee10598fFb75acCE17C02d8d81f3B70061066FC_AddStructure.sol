//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract AddStructure{

    //iterator address map
    mapping(address=>address) _next;
    
    //Iterator map from address to uint256 to determine address position in the queue
    mapping(uint256=> address) pointer;

    //Keep track of size of the address queue
    uint256 private size =0;

    address constant GUARD = address(1);
    //Pass array of addresses on deployment
    constructor() public {
        //Extra security for contract initialization
        require(size==0);
        require(_next[GUARD]==address(0));
        require(pointer[size]==address(0));

        //GUARD head for security/set pointer map 0-> GUARD
        _next[GUARD]=GUARD;
        pointer[size]=GUARD;
        //Increment the size of the queue
        incrementSize(); 
        
    }

    //Add address 'add' to address map
    function addAddress(address add) public {
        //Extra security for method initialization
        //Ensure msg.sender is adding only their address, not necessary for testing
        //require(add == msg.sender);
        require(_next[add]==address(0));
        require(pointer[size]==address(0));

        //Map previous address at pointer[size -1] to add
        _next[pointer[size-1]]=add;
        pointer[size]=add;
        incrementSize();

    }

    //Remove a specific address from the queue and maintain order
    function removeAddress(address add) public{
        //Extra security for method initialization
        //Ensure msg.sender can only remove their address from the queue, removing for testing purposes
        //require(add == msg.sender);
        //Ensure add is actually part of the current queue
        
        //Ensure queue is not empty, don't think it could be with the above require but still add it for shits
        require(size != 1);

        //Start at beginning of the queue and iterate forward until hitting target add
        //Once target is found switch _next of previous address to tail of add
        uint256 tempC = 0;
        while(tempC<size){
            if(pointer[tempC]==add){
                if(tempC !=0 && tempC <size-1){
                    address prevAdd = pointer[tempC -1];
                    _next[prevAdd]=_next[add];
                    _next[add]=address(0);
                    decrementSize();
                    
                    address temp = _next[prevAdd];
                    for(uint256 j=tempC; j<=size-1;j++){
                        pointer[j]=temp;
                        temp = _next[temp];
                    }
                    
                    break;
                }else if(tempC == size -1){
                    address prevAdd = pointer[tempC -1];
                    _next[prevAdd]=address(0);
                    _next[add]=address(0);
                    decrementSize();
                    break;
                }
            }
            tempC++;
        }
    }

    //Increment the size of the queue by 1 
    function incrementSize() private {
        size +=1;
        
    }
    //Decrement the size of the queue by 1 
    function decrementSize() private {
        size -=1;
    }
    //Return the size of the queue
    function getSize() public view returns (uint256) {
        return size;
    }

    //Get an address at a specific position in the queue i.e pointer[position]
    function getAddressAtPosition(uint256 position) public view returns (address) {
        return pointer[position];
    }

    //Return the current address in position size
    function getCurrentAddress() public view returns (address) {
        return pointer[size-1];
    }
}