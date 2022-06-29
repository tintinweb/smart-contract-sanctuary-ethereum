// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;
contract SimpleStorage2{
    uint256 public Num; // Initialized to 0
    function store(uint256 num) public virtual {Num = num;}
    function retrieve()public view returns(uint256){return Num;}
    function add(uint256 num) public {Num = Num + num;}
    function remove(uint256 num) public {Num = Num - num;}

    struct Account{
        string name;
        uint256 balance;
        uint256 id;   
    }
    Account[] public accounts;
    mapping(string => uint256) public nameToBalacne;
    function addAccount(string memory _name,uint256 _balance, uint256 _id) public {
        accounts.push(Account(_name,_balance,_id));
        nameToBalacne[_name] = _balance;
    }
}