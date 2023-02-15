// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
//import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
contract Voting  {
    uint public tokenPrice = 10 ether;
address public owner;
string public name;

string public symbol;

uint256 public decimal;

uint public totalSupply;
uint private voteCost =100;
address public firstCand;

address public secondCand;

address public thirdCand;

// mapping of the address to the balance

mapping (address => uint256) public balanceOf;
mapping(address => uint256) public total;
// owner => spender =>  amount
mapping (address =>mapping(address => uint)) public allowance;

//events

event transfer_(address indexed from, address to, uint amount);
event _mint(address indexed from, address to, uint amount);

// constructor to declare token identity
constructor(string memory _name, string memory _symbol){
    owner = msg.sender;

    name = _name;
    symbol = _symbol;
    decimal = 1e18;
   }
   function buyTokens(uint256 _amount) public payable {
        require(msg.value >= _amount * 1 ether, "Not enough ether to buy tokens.");
        totalSupply += _amount;
        balanceOf[msg.sender] += _amount;

    }

function addCandidate(address _firstCand, address _secondCand, address _thirdCand)public{
    if (_firstCand == _secondCand || _firstCand == _thirdCand || _secondCand == _thirdCand){
        revert("can't set same address");
    } 
    firstCand = _firstCand;
    secondCand = _secondCand;
    thirdCand = _thirdCand;
    require(firstCand != address(0) || secondCand != address(0) || thirdCand != address(0), "candidate can't be Added");
}

function _totalSupply( uint _token) public returns(uint256){
    totalSupply = _token;
    return totalSupply;
}

function buyToken(address to, uint amount) public {
    require(msg.sender == owner, "Access Denied");
    require(to != address(0), "transfer to address(0)");
    require(amount == 100, "you only have access to 100 token");
    balanceOf[msg.sender] += amount;
    totalSupply  -= amount;
}

function checkBalance(address _owner) public view returns (uint256) {
        return balanceOf[_owner];
    }

function vote(address _position1, address _position2, address _position3) public{
    require(balanceOf[msg.sender]>= voteCost, "Not enough");
    balanceOf[msg.sender] - voteCost;
total[_position1] += 3;
total[_position2] += 2;
total[_position3] += 1;
 
}
function checkVote(address _check)public view returns(uint point){
 point= total[_check];
}
}