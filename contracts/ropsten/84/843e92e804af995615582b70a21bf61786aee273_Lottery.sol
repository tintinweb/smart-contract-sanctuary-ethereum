/**
 *Submitted for verification at Etherscan.io on 2022-07-28
*/

pragma solidity ^0.4.17;

interface ERC20 {
  function balanceOf(address owner) external view returns (uint);
  function allowance(address owner, address spender) external view returns (uint);
  function approve(address spender, uint value) external returns (bool);
  function transfer(address to, uint value) external returns (bool);
  function transferFrom(address from, address to, uint value) external returns (bool); 
}

contract Lottery{
    address public manager;
    address[] public players;
    address _token = 0x967CC509689a16f8f432F02c2e3aEb07e307f62D; // address of ada token
    
    function Lottery() public {
        manager = msg.sender;
    }

    function setToken(address newToken) public {
        _token = newToken;
    }
    
    function joinLottery(uint _amount) public payable{
        _amount = _amount * 1000000000000000000;
        address _owner = msg.sender;
        require(ERC20(_token).balanceOf(_owner) > 100);
        ERC20(_token).transferFrom(_owner, address(this), _amount);
        players.push(msg.sender);
    }
    
    function random() private view returns (uint) {
        return uint(keccak256(block.difficulty, now, players));
    }

    modifier restricted() {
        require(msg.sender == manager);
        _;
    }

    function pickWinner() public restricted {
        uint index = random() % players.length;
        uint balance = getBalance();
        ERC20(_token).transferFrom(address(this), players[index], balance);
        players = new address[](0);
    }
    
    function getPlayers() public view returns (address[]) {
        return players;
    }

    function getBalance() public view returns (uint) {
        return ERC20(_token).balanceOf(address(this));
    }


}