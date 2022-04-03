/**
 *Submitted for verification at Etherscan.io on 2022-04-03
*/

// File: contracts/kessak.sol

pragma solidity ^0.8.0;


contract SpynxEnigma {
  
    bytes32 public answer = 0xbe43044869010662209ff76ea7fcfe94b49aee4e72c3a5da934425d51b20d656; //web3.utils.keccak256("merlin")  
    address public admin;
    event good_response(address _winner, string responsewin); //reponse visible dans les logs
    event bad_response(address _player, string response); //reponse visible dans les logs
    uint public price;
    uint public gain;
    
    constructor() public {
        admin = msg.sender;
    }

    receive() external payable {}

    function change_answer(bytes32 new_answer) external {
        require(admin == msg.sender);
        answer = new_answer;
    }

    function change_price(uint _price) external {
        require(admin == msg.sender);
        price = _price;
    }

    function change_admin(address _admin) external {
        require(admin == msg.sender);
        admin = _admin;
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function withdraw() public payable {
        require(msg.sender == admin);
        (bool sent,) = msg.sender.call{value: address(this).balance}("");
        require(sent, "Failed to send user balance back to the owner");
    }

    function play(string memory _word) public payable {
        require(msg.value >= price, "Send ETH to play :)");
        if (keccak256(abi.encodePacked(_word)) == answer){ 
        emit good_response(msg.sender, _word);  
        (bool sent,) = msg.sender.call{value:address(this).balance}("");
        require(sent, "Failed to send user balance back to the owner");   
        }
        else{
            emit bad_response(msg.sender, _word); 
        }       
    }
}