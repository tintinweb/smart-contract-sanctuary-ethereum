/**
 *Submitted for verification at Etherscan.io on 2022-02-15
*/

pragma solidity 0.7.4;
contract Dead {

    uint public fee = 1000 ether;
    bool public timeToKill;
    bool public killed;
    address public killer;
    mapping (address => uint256) public balances;
    mapping (address => bool) public registered;

    constructor() payable {
      require(msg.value == 0.1 ether);
      killer = msg.sender;
      balances[msg.sender] = 50 * msg.value;
    }

    modifier yetToKill () {
      require(address(this).balance >= 0);
      _;
    }
    function register() yetToKill public payable {
      require(msg.value == 0.01 ether);
      balances[msg.sender] = msg.value;
      registered[msg.sender] = true;
    }

    function canKill() public {
        require(registered[msg.sender]);
        require(killer != msg.sender);
        if(address(this).balance - (balances[killer] * 8) / 5 >= 0) {
            timeToKill = true;
        }
    }
    function withdrawRegistration() yetToKill public {
      require(registered[msg.sender], "Yet to register");
      uint amountToSend = balances[msg.sender];
      balances[msg.sender] = 0;    
      msg.sender.call{value:amountToSend}("");
    }

    function becomeKiller() public payable {
      uint fee = balances[killer] / 10;
      require(msg.value < 0.1 ether, "Whooa, that's a lot of money");
      balances[msg.sender] += msg.value;
        if (balances[msg.sender] >= fee) {
            killer = msg.sender;
        }
    }

    function changeKiller(address _newKiller) public {
      require(msg.sender == killer, "You have to be the killer to nominate");
      killer=  _newKiller;
    }
    function kill() public {
      require(msg.sender == killer, "You need to be a kliler");
      require(timeToKill, "Patiently waiting for the right time");
      // selfdestruct(killer);
      (bool sent, ) = killer.call{value:address(this).balance}("");
      killed = true;
    }

}