/**
 *Submitted for verification at Etherscan.io on 2022-09-26
*/

/*
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%@@@@%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@%%%@@@@%%%%@@@%%%%@@@%%%@@@@@%%@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@%%%@@@%%@@%%%%&@@%%%%@@%%%@%@@%%@@@%%%@@@@@%@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@%%%%@@@@%@@%%%%@@@%%%%%%%%%%%%%%%%@@@@%%%%@@@%@@&%%%@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@%%@@%%%%%@@&%%%%@@@@@@&%%%%%%@@@@@@%%%%%%@@%%%%%@@%%@@@%%@@@@@@@@@@
@@@@@@@%%%%%%%%%@@@%%%%@@@@%%%%%%%%%%%%@%%%%%%%%%%&@@@@@%%%%@@@%%@%%%%%@@@%@@@@@
@@@@@@@@%%@@@%%%%%%@@@%%%%@@@%%%%%%%%%@@%%%%%%%%%@@@@&%%@@@@%%%%%%@@@%%@%%%@@@@@
@@@@@@@%%%%%@@@@@@%%%%@@@@@@%%%%%%%%%%@@%%%%%%%%%%@@@@@@@@%%%@@@%%%%%%%%@%%@@@@@
@@@@@@%@@@@@%%%%@@@@@@@@@@@@%%%%%%%%%%@@%%%%%%%%%%@@@@@@@@@@@@%%%@@@%%%%%%@@@@@@
@@@@@@%@@@@%%%%%@@@@@@@@@@@@%%%%%%%%%%@@%%%%%%%%%%@@@@@@@@@@@@@%%%@@@@%%@@@@@@@@
@@@@@@@%%%@@@@@@@@%%@@@@@@@@%%%%%%%%%%@@%%%%%%%%%%@@@@@@@@@&%%%@@@@%%%%%@@@@@@@@
@@@@@@@@@@%%%%%%%@@@@@%%%@@@@@%%%%%%%%@@%%%%%%%%@@@@@@@%%%@@@@@@%%%%@@@%%@@@@@@@
@@@@@@@@@@%%@@&%%@%%%@@@@@%%%%%%%%%%%%%@%%%%%%@@@@%%%@@@@@@%%%%%@@%%%%@%%@@@@@@@
@@@@@@@@@@@%@%%%%@@%%%%%%%%@@@@@@@%%%%%%%%%%%@@@@@@@@@%%%%%%%%%@@@%@@@%%@@@@@@@@
@@@@@@@@@@@%%@@@%%%%%@%@@%%%%%%%%%%%%%@@@@@&%%%%%%%%%%@%%%%@%%@%%%@@@@%@@@@@@@@@
@@@@@@@@@@@@@@@@%%&@@@%%%%%@%%@@@%%%@@@%%%@@%%%%@@%%%%@%%@@%%@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@%@@@@@%%%%@@@%%%%@@%%%%@%%%%@@@%%@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@


Sauron, also known as Annatar, Gorthaur, The Necromancer, The Dark Lord.
Sauron means in quenya "the Horrifying" or "the Abhorred", a name imposed, evidently,
by his enemies. Gorthaur is the Sindarin equivalent of Sauron, and along with this name,
the Sindar Elves gave him the nickname "The Cruel".

He was the most powerful of Melkor's servants and lieutenant of the evil stronghold, Angband;
his names, due to his services and his later deeds, are countless, and although Sauron's best 
known titles are that of "Dark Lord of Mordor" and "Lord of the Rings", he is also counted among
them: "the Great Master of Lies", "Sauron the Great", "he whom we shall not name",
"Lord of the Dark Land", "the Black Hand", "the Dark Lord", "Lord of the Lycanthropes", 
"the Cruel", "the Dark Power", Annatar (q. "Lord of the Gifts"), "Lord of Barad-dûr", "Ringmaker",
"the Necromancer", "the Red Eye", "the Eye of Fire", "the Eyeless Eye" or "the Great Eye".

Website: https://www.Sauron.com (Coming Soon)

https://twitter.com/Sauron_Trading

https://t.me/@Sauron_Trading




*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract Sauron is IERC20 {
    using SafeMath for uint256;

    string public constant name = "Sauron by The Rings of Power";
    string public constant symbol = "SAURON";
    uint8 public constant decimals = 18;

    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;

    uint256 private totalSupply_ = 100000000*10**uint256(decimals);

    constructor() public {
        balances[msg.sender] = totalSupply_;
    }

    function totalSupply() public override view returns (uint256) {
        return totalSupply_;
    }

    function balanceOf(address tokenOwner) public override view returns (uint256) {
        return balances[tokenOwner];
    }


    function transfer(address receiver, uint256 numTokens) public override returns (bool) {

        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
        emit Transfer(msg.sender, receiver, numTokens);
        return true;

    }

    function approve(address delegate, uint256 numTokens) public override returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address owner, address delegate) public override view returns (uint) {
        return allowed[owner][delegate];
    }

    function transferFrom(address owner, address buyer, uint256 numTokens) public override returns (bool) {

        require(numTokens <= balances[owner]);
        require(numTokens <= allowed[owner][msg.sender]);

        balances[owner] = balances[owner].sub(numTokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
        emit Transfer(owner, buyer, numTokens);
        return true;

    }
}

library SafeMath {
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
      assert(b <= a);
      return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
      uint256 c = a + b;
      assert(c >= a);
      return c;
    }
}