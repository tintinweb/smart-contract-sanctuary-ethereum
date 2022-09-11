/**
 *Submitted for verification at Etherscan.io on 2022-09-11
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

contract Token{
    uint256 _totalTokens;
    address[] public owners;
    uint256 public ownersCount;
    mapping(address => uint256) balances;
    string _name = "Third Ivasiuk Token";
    string _symbol = "IVS2";

    address public candidate;
    bool public voting;
    mapping(address => bool) ownersVotes;
    uint256 votesCountFor;
    uint256 votesCountAgainst;

    event Transfer(address indexed from, address indexed to, uint256 amount);

    function name() external view returns(string memory) {
        return _name;
    }

    function symbol() external view returns(string memory) {
        return _symbol;
    }

    function decimals() external pure returns(uint256){
        return 18;
    }

    function totalSupply() external view returns(uint256){
        return _totalTokens;
    }

    function balanceOf(address account) public view returns(uint256){
        return balances[account];
    }

    function transfer(address to, uint256 amount) external enoughTokens(msg.sender, amount){
        balances[msg.sender] -= amount;
        balances[to] += amount;
        emit Transfer(msg.sender, to, amount);
    }

    modifier enoughTokens(address _from, uint _amount) {
        require(balanceOf(_from) >= _amount, "Not enough tokens");
        _;
    }

    modifier onlyOwner() {
        bool flag;
        for(uint256 i = 0; i < ownersCount; i++){
            if(msg.sender == owners[i]){
                flag = true;
                break;
            }
        }
        require(flag == true, "Not and owner");
        _;
    }

    constructor(){
        owners.push(msg.sender);
        ownersCount++;
        ownersVotes[msg.sender] = false;
        mint(20 ether, msg.sender);
    }

    function mint(uint amount, address _to) public onlyOwner {
        balances[_to] += amount;
        _totalTokens += amount;
        emit Transfer(address(0), _to, amount);
    }

    function transferFrom(address sender, address recepient, uint256 amount) external enoughTokens(sender, amount){
        balances[sender] -= amount;
        balances[recepient] += amount;
        emit Transfer(sender, recepient, amount);
    }

    function setCandidate(address _new) external onlyOwner {
        require(voting == false, "The voting is started");
        voting = true;
        candidate = _new;
    }

    function vote(bool _choose) external onlyOwner {
        require(voting == true, "Voting isn't started");
        require(ownersVotes[msg.sender] == false, "This owner voted");
        ownersVotes[msg.sender] = true;
        if(_choose == true){
            votesCountFor++;
        }
        else{
            votesCountAgainst++;
        }
            
        if(votesCountFor > ownersCount/2 || votesCountAgainst > ownersCount/2){
            if(votesCountFor > ownersCount/2){
                owners.push(candidate);
                ownersCount++;
            }
            candidate = address(0);
            voting = false;
            votesCountFor = 0;
            votesCountAgainst = 0;
            for(uint256 i=0; i<owners.length; i++){
                ownersVotes[owners[i]] = false;
            }
        }
    }
}