// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract RockPaperScissors {

    enum RPS {ROCK, PAPER, SCISSORS}
    address public owner;
    uint256 public result;

    constructor() payable{ 
        owner = msg.sender;
    }

    function play(uint _number) public payable returns(bool success){
        require(uint(RPS.SCISSORS) >= _number, "This symbol is not valide for Rock Paper Scissors !" );
        // only 5 wei per game
        require(
            msg.value == 5,
            "Only 5 (Nano)Ether per game !"
        );
        require(
            //msg.value <= 2*getBalance(),
            getBalance() >= 2*msg.value,
            "No sufficient Deposit on contract !"
        );

        
        uint256 ran_num = get_random_number();
        //Same Symbol, no Winner, Try it again
        if (_number == ran_num){
            revert('Same Symbol, no Winner, Try it again!');
        }
        
        if(_number == uint(RPS.SCISSORS) && ran_num == uint(RPS.PAPER)){
            success = true;
        }
        if(_number == uint(RPS.SCISSORS) && ran_num == uint(RPS.ROCK)){
            success = false;
        }
        if(_number == uint(RPS.ROCK) && ran_num == uint(RPS.SCISSORS)){
            success = true;
        }
        if(_number == uint(RPS.ROCK) && ran_num == uint(RPS.PAPER)){
            success = false;
        }
        if(_number == uint(RPS.PAPER) && ran_num == uint(RPS.ROCK)){
            success = true;
        }
        if(_number == uint(RPS.PAPER) && ran_num == uint(RPS.SCISSORS)){
            success = false;
        }

        //money for the player?
        if (success){
            address payable receiver = payable(msg.sender);
            //receiver.transfer(10);
            receiver.call{value: 10}("");
        }

        return success;

    }

    function get_random_number() public returns(uint256){
        return uint256(
            keccak256(
                abi.encodePacked(
                    blockhash(block.number-1),
                    msg.sender,
                    block.difficulty,
                    block.timestamp
                )
            )
        ) % 3;
    }

/** 
    function get_random_number() public returns(uint256){
        uint256 blockValue = uint256(blockhash(block.number-1));
        result = blockValue % 3;
        return result;
    }

    function get_random_number_block() public returns(uint256, uint256){
        uint256 block_number = block.number-1;
        uint256 blockValue = uint256(blockhash(block.number-1));
        result = blockValue % 3;
        return (result, blockValue);
    }
*/
    function getBalance() public view returns(uint256 balance){
        return address(this).balance; 
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function withdraw() public payable onlyOwner {
        //msg.sender.transfer(address(this).balance);
        address payable withdrawer = payable(msg.sender);
            //receiver.transfer(10);
        withdrawer.call{value: address(this).balance}("");
    }

    function fund() public payable {

    }


}