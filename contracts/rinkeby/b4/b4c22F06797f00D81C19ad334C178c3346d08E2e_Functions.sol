/**
 *Submitted for verification at Etherscan.io on 2022-05-24
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Functions {
    address private owner;
    constructor() {
        owner = msg.sender;
    }
    string coinName = "BDD";
    uint myBalance = 3.0;
    struct Coin {
        string name;
        uint balance;
        uint supply;
    }
    function getOwner() public view returns(address) {
        return owner;
    } 
    mapping(address => Coin) internal myCoins;
    function getBalance() public view returns(uint) {
        return myBalance;
    }
    function guessNumber(uint _guess) public view returns (bool) {
        require(msg.sender == owner, "ouch");
        if(_guess == 5) {
            return true;
        } else {
            return false;
        }
    }

    function getName() public view returns (string memory) {
        return coinName;
    }
    function multiplyBalance(uint _multiplier) external {
        myBalance = myBalance * _multiplier;
    }

    
    function searchCoins(uint _start, string[] memory coins, string memory coin ) public pure returns (uint){
        for(uint index=_start; _start < coins.length; _start++) {
            string memory mCoin = coins[index];
            
            if(keccak256(abi.encodePacked(mCoin)) == keccak256(abi.encodePacked(coin))) {
                return index;
            }
        }
        return 1;
    }

    function addCoin(string memory _name, uint _value, uint _supply) external {
        require(_value > 0, "should be more than zero");
        myCoins[msg.sender] = Coin(_name, _value, _supply);
    }
    
    function getCoin() public view returns(Coin memory) {
        return myCoins[msg.sender];
    }



}