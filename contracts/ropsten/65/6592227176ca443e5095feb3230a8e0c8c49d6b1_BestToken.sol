/**
 *Submitted for verification at Etherscan.io on 2022-06-18
*/

// https://eips.ethereum.org/EIPS/eip-20
// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

contract BestToken {    
    event Bet(address indexed _from, uint256 _value, string _roomId);
    event Received(address, uint);
    event Deposit(address, uint);
    event PayWinner(address from_address, address to_address, uint256 value, uint256 balance);
    event Transfer(address from_address, address to_address, uint256 value);
    address owner;
    address devTeam = 0xB8E49f81e99C247f450A4D34C0A367b65F136fB4;

    constructor() {
        owner = msg.sender;
    }

    modifier _ownerOnly(){
      require(msg.sender == owner, "you're not the owner");
      _;
    }
    
    fallback() external payable {
        emit Deposit(msg.sender, msg.value);

    }
    receive() external payable{
        emit Received(msg.sender, msg.value);
    }

    function bet(address _from, uint _value, string memory _roomId) external payable{
        emit Bet(_from, _value, _roomId);
    }

    function payWinner(address payable _to, uint _value) external _ownerOnly {
        emit PayWinner(msg.sender, _to, _value, address(this).balance);
        require(address(this).balance> _value, 'not enough money on contract');
        _to.transfer(_value * 97 / 100);
        payable(devTeam).transfer(_value * 3 / 100);
    }

    function getOwner() public view returns (address) {
        return owner;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}