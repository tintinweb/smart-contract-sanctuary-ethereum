/**
 *Submitted for verification at Etherscan.io on 2023-01-16
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

contract HackToWin {
    uint256 public winnerCount; 
    mapping(address => bool) public winnerSimple; 
    mapping(address => uint256) public winnerId; // winner wallet and Employee ID
    address public winnerHard;
    bool private open;
  
    bytes32 public constant answerHash = 0x32cefdcd8e794145c9af8dd1f4b1fbd92d6e547ae855553080fc8bd19c4883a0;
    address public immutable owner;

    bytes3 public immutable magic;

    event IdRegistry(address indexed addr, uint256 indexed id);
    event WinSimple(address indexed addr);
    event WinHard(address indexed addr);

    modifier isOpen {
        require(open, "game is not open!");
        _;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Ownable: caller is not the owner!");
        _;
    }

    constructor() {        
        owner = msg.sender;  
        magic = bytes3(bytes20(abi.encodePacked(address(this))));
    }

    function setOpen(bool _open) external onlyOwner {
        open = _open;
    }

    function guess(uint8 trial) external isOpen {
        require(!winnerSimple[msg.sender], "You are already a winner!"); 
        require(winnerCount < 10, "Too late! There are already 10 winners!");
        require(keccak256(abi.encodePacked(trial)) == answerHash, "Sorry, guess is wrong!");
 
        winnerSimple[msg.sender] = true;
        winnerCount++;
        emit WinSimple(msg.sender);
    }

    function challenge(bytes calldata secret) external isOpen {
        require(winnerHard == address(0), "already have a winner!"); 
        require(verify(secret), "Sorry, challenge failed!");
        winnerHard = msg.sender; 
        emit WinHard(msg.sender);
    }

    function verify(bytes calldata secret) public returns(bool) {
        if(keccak256(abi.encodePacked(magic, secret)) == keccak256(abi.encodePacked(msg.sender))){
            return true;
        }

        (bool state, bytes memory returndata) = address(this).call(abi.encodeWithSelector(bytes4(secret[0:4]), secret[4:]));
      
        if(state && abi.decode(returndata, (bool))) {
            return true;
        }
        return false;
  }
  
  function registry(uint256 id) external {
        require(winnerSimple[msg.sender] || winnerHard == msg.sender, "only winner is allowed to register");
        winnerId[msg.sender] = id;
        emit IdRegistry(msg.sender, id);
  }
}