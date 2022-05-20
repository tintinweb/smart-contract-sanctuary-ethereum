/**
 *Submitted for verification at Etherscan.io on 2022-05-20
*/

pragma solidity >=0.7.0 <0.9.0;

contract Escrow {

   //VARIABLES
    enum State {NOT_STARTED, STARTED, COMPLETE }

    State public currState;
    address payable public owner = 0x66e384E1D633D9f610fc46403a99Ac7278F6d66A;
    uint8 public dataCount = 0;
    mapping (uint=>Data) public datas;

    struct Data {

    uint price;
    address payable client;

    }

    event Sobytie(
        address indexed client,
        uint price
    );

    //MODIFIERS

    modifier onlyOwner(){

        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier EscrowNotStarted(){

        require(currState == State.NOT_STARTED);
        _;

    }

    
    //function


    function addData(address payable client, uint price) public {
        dataCount+=1;
        datas[dataCount]=Data(price, client);

}

    function deposit(uint price) EscrowNotStarted public payable{
        
        require(msg.value == price * (1 ether), "Wrong deposit amount");
        currState = State.STARTED; 
    }

function balance() public returns (uint256){
    return payable(address(this)).balance;
  }

    function roolcomplete(address payable client, uint price) payable public{
        
        client.transfer(price * (1 ether));
        currState = State.COMPLETE;
    }

    function roolbroken(uint price) payable public{
        owner.transfer(price * (1 ether));
        currState = State.COMPLETE;
        
    }

      receive() external payable {
       emit Sobytie(msg.sender, msg.value);
    }

    

}