/**
 *Submitted for verification at Etherscan.io on 2022-09-16
*/

pragma solidity ^0.8.0;


abstract contract ReentrancyGuard {
    
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    
    modifier nonReentrant() {
        
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        
        _status = _ENTERED;

        _;

        
        _status = _NOT_ENTERED;
    }
}

library Counters {
    struct Counter {
        uint256 _value; 
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

error NotOwner();

contract Raffle is ReentrancyGuard {
    using Counters for Counters.Counter;
    mapping(address => uint256) public addressToAmountFunded;
    mapping(address => uint256) public addressToAmountPaid;
    address[] public players;
    address public i_owner;
    bool public paused = true;
    address public winner;
    uint256 public divFactor;
    uint256 _price = 10000000000000000; // 0.01 ETH
    Counters.Counter private _ticketID;
    
    constructor() {
        i_owner = msg.sender;  
    }

    function enterRaffle(address account, uint256 _amount) public payable {
        require(paused == false, "Raffle not active");
                require(
            _price * _amount <= msg.value,
            "CryptoPunks: Not enough ethers sent"
        );
        uint current = _ticketID.current();
        
       for (uint i = 0; i < _amount; i++) {
            raffleInterval();    
        } 
    }
    function raffleInterval() internal nonReentrant {
        _ticketID.increment();

        uint256 ticketID = _ticketID.current();
        addressToAmountFunded[msg.sender] += msg.value;
        players.push(msg.sender);
    }
    
    modifier onlyOwner {
        if (msg.sender != i_owner) revert NotOwner();
        _;
    }
    
    function withdraw() payable onlyOwner public {
        for (uint256 playerIndex=0; playerIndex < players.length; playerIndex++){
            address player = players[playerIndex];
            addressToAmountFunded[player] = 0;
        }
        players = new address[](0);
        (bool callSuccess, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call failed");
    }
  
    function setPaused(bool _paused) payable onlyOwner public {
       paused = _paused;
}
    function recentWinner(address _winner) payable onlyOwner public {
       winner = _winner;
       
}
    function setDivFactor (uint256 _divFactor) public onlyOwner {
    divFactor = _divFactor;
}
    function rafflePool() public view returns (uint256 ) {
      
      return payable(address(this)).balance / divFactor;
  }
       
    function rewardWinner(address payable _winner, uint256 amount) public onlyOwner payable {
            require (winner == _winner, "set winner" );
            require(address(this).balance >= amount, "Not enough tokens");        
        (bool sent, bytes memory data) = _winner.call{value: msg.value}("");
        require(sent, "Failed to send Ether");
    }
}