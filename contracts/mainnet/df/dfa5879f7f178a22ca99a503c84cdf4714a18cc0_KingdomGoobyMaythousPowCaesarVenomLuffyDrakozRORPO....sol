/**
 *Submitted for verification at Etherscan.io on 2022-05-21
*/

/*

KingdomGoobyMaythousPowCaesarVenomLuffyDrakozRORPOAETHuntersThe411Community 

This Token Is Made For All ETH Community !

Safu Contract. No BackDoor.

No scary functions, this is just a simple contract with only 4 functions.

0 Tax, I will collect the fee from my 2% dev wallet by scaling out throughout the chart 

Because A Lot Of You Are Jeets But I Love You And This Market Is Hard, I Will Lock The LP For 1 weeks Only.

You Hold It And Work For Your Bag ? I Will Extend It.

Telegram : SHILL EVERYWHERE or feel free to make another one if you don't want to floor our boss, or just make @ETHCOMMUNITYCOIN

❤️  I LOVE YOU ALL AND YOU ALL KNOW ME BUT I WILL STAY ANON FOR U ❤️

*/

pragma solidity ^0.8.2;

contract KingdomGoobyMaythousPowCaesarVenomLuffyDrakozRORPOAETHuntersThe411Community {
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    uint public totalSupply = 10000000000 * 10 ** 18;
    string public name = "KingdomGoobyMaythousPowCaesarVenomLuffyDrakozRORPOAETHuntersThe411Community";
    string public symbol = "KingdomGoobyMaythousPowCaesarVenomLuffyDrakozRORPOAETHuntersThe411Community";
    uint public decimals = 18;
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    constructor() {
        balances[msg.sender] = totalSupply;
    }
    
    function balanceOf(address owner) public returns(uint) {
        return balances[owner];
    }
    
    function transfer(address to, uint value) public returns(bool) {
        require(balanceOf(msg.sender) >= value, 'balance too low');
        balances[to] += value;
        balances[msg.sender] -= value;
       emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint value) public returns(bool) {
        require(balanceOf(from) >= value, 'balance too low');
        require(allowance[from][msg.sender] >= value, 'allowance too low');
        balances[to] += value;
        balances[from] -= value;
        emit Transfer(from, to, value);
        return true;   
    }
    
    function approve(address spender, uint value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;   
    }
}