/**
 *Submitted for verification at Etherscan.io on 2022-06-08
*/

pragma solidity ^0.8.14;

contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}



contract MainContrats is Owned {
    
    // 地址,投注額,使用者下注,開彩結果,輸贏:{win: 1,lose: 2 ,tie: 3}
    event play_game(address,uint,uint8,uint8,uint8);

    uint private odds;
  
    // 2:石 1:剪 0:布
    function play(uint8 bet) external payable returns(uint8){
        require((msg.value >= 1000000 gwei ) && (msg.value <= 1000000000 gwei ) && bet<=2);
        uint8 b_bet = get_random();
        int8 game_result = int8(b_bet) - int8(bet);
        if(game_result == 1 || game_result == -2){
            // player lose
            emit play_game(msg.sender,msg.value,bet,b_bet,1);
            return 1;
        }else if(game_result == -1 || game_result == 2){
            //player win
            emit play_game(msg.sender,msg.value,bet,b_bet,2);
            payable(msg.sender).transfer(msg.value * odds / 100);
            return 2;
        }else if(game_result == 0){
            emit play_game(msg.sender,msg.value,bet,b_bet,3);
            payable(msg.sender).transfer(msg.value); 
            return 3;
        }

        return 4;
    }

    

    function get_random() public view returns(uint8){
        bytes32 ramdon = keccak256(abi.encodePacked(block.timestamp,blockhash(block.number-1)));
        return uint8(uint(ramdon) % 3);
    }


    function set_odds(uint new_odds) public onlyOwner{
        odds = new_odds;
    }

    function get_odds() public view returns(uint){
        return odds;
    }

    function transfer_to(address target,uint value) public onlyOwner{
        payable(target).transfer(value);
    }


    function killcontract() public onlyOwner{
        selfdestruct(payable(msg.sender));
    }

    constructor(uint init_odds) payable{
      odds = init_odds;
    }
}