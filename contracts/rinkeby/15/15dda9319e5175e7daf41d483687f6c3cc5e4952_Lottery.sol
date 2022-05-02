/**
 *Submitted for verification at Etherscan.io on 2022-05-01
*/

pragma solidity 0.6.0;

contract Lottery {
    
    uint private maxParticipantNumbers;
    uint private participantNumbers;
    uint private ticketPrice;
    address private owner;
    address payable[] participants;
    
    constructor() public {  
        owner =  msg.sender;
        maxParticipantNumbers = 100;
        ticketPrice = 0.001 ether;
    }

    modifier onlyOwner(){
        require(msg.sender == owner, "Access denied!");
        _;
    }
    
    modifier notOwner(){
        require(msg.sender != owner, "Access denied");
        _;
    }
    
    function setTicketPrice(uint256 _valueInEther) public onlyOwner{
        ticketPrice = (_valueInEther * 1000000000000000000);
    }
    
    function setParticipants(uint _maxNumbers) public onlyOwner{
        participantNumbers = _maxNumbers;
    }
    function viewTicketPrice() external view returns(uint){
        return ticketPrice;
    }

    mapping(address => uint256) interactCount;
    uint256 constant interactLimit = 1;

    modifier limit {
        require(interactCount[msg.sender] < interactLimit);
        interactCount[msg.sender]++;
        _;
    }

    function joinLottery() payable public limit {
        require(msg.value == ticketPrice);
        participants.push(msg.sender);
        participantNumbers++;
    }

    function resetInteract(address _user) external onlyOwner(){
        interactCount[_user] = 0;
    }
    
    function random() private view returns(uint){
        return uint(keccak256(abi.encode(block.difficulty, now, participants, block.number)));
    }
    
    function pickWinner() internal{
        uint win = random() % participants.length;
        
        participants[win].transfer(address(this).balance);
        
        delete participants;
        participantNumbers = 0;
    }
    
    function endGame() external onlyOwner{
        uint win = random() % participants.length;
        
        participants[win].transfer(address(this).balance);
        
        delete participants;
        participantNumbers = 0;
    }

    function EmergencyWithdraw() external{
        require(msg.sender == owner);
        payable(msg.sender).transfer(address(this).balance);
    }
}