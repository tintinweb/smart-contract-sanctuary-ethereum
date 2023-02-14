// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract voting {
    
address private owner;
string public name_;
string public symbol_;
uint256 private decimal;
uint totalSupply;

mapping (address => uint256) balanceOf;

event transfer_(address from, address to, uint amount);
event _mint(address from, address to, uint amount);

constructor(){
   owner = msg.sender;
   name_ = "web3bridge";
   symbol_ = "CVIII";
   decimal = 1e18;
   totalSupply += 50000 * _decimal();
   balanceOf[address(this)] += 50000 * _decimal();
}

mapping(address => uint) public contenderCount;
mapping(address => bool) public contenderStatus;
address[] public contenders;
mapping(address => uint) public votingPoint;
mapping(address => mapping(address => mapping(address => mapping(address => bool)))) public votersStatus;
mapping(address => bool) setVoteStatus;
mapping(address => bool) collateVoteStatus;
address[] votersLIst;

modifier mod(address _contender1, address _contender2, address _contender3){
require(setVoteStatus[owner] == true, "voting hasn't commenced");
   require(votersStatus[msg.sender][_contender1][_contender2][_contender3] == false, "already voted");
   require(votersStatus[msg.sender][_contender2][_contender1][_contender3] == false, "already voted");
   require(votersStatus[msg.sender][_contender3][_contender2][_contender1] == false, "already voted");
   require(votersStatus[msg.sender][_contender1][_contender3][_contender2] == false, "already voted");
   require(votersStatus[msg.sender][_contender3][_contender1][_contender2] == false, "already voted");
   require(votersStatus[msg.sender][_contender2][_contender3][_contender1] == false, "already voted");
   require(balanceOf[msg.sender] >= (3 *_decimal()), "not enough token to vote");
  
   _;
}

modifier contenderMod(address _contender1, address _contender2, address _contender3){
 require(contenderStatus[_contender1] == true, "not a contender");
   require(contenderStatus[_contender2] == true, "not a contender");
   require(contenderStatus[_contender3] == true, "not a contender");

   _;
}

struct contenderDetail {
   address contenderAddress;
   uint contenderVotes;
}
contenderDetail[] _contenderDetails;

function _decimal() internal view returns(uint256){
   return decimal;
}
function _totalSupply() public view returns(uint256){
   return totalSupply;
}
function _balanceOf(address user) public view returns(uint256){
   return balanceOf[user];
}

function transfer(address _to, uint amount)public {
   _transfer(msg.sender, _to, amount);
   emit transfer_(msg.sender, _to, amount);
}
function _transfer(address from, address to, uint amount) internal {
   require(balanceOf[from] >= amount, "insufficient fund");
   require(to != address(0), "transferr to address(0)");
   balanceOf[from] -= amount;
   balanceOf[to] += amount;
}

function mint(uint amount) public {
   require(msg.sender == owner, "Access Denied");
   totalSupply += amount * _decimal();
   balanceOf[address(this)] += amount * _decimal();
   emit _mint(address(0), address(this), amount);
}


function buyToken() public payable {
      uint cost = (msg.value * 500);        
         (bool sent, bytes memory data) = owner.call{value: msg.value}("");
        require(sent);           
         _transfer(address(this), msg.sender, cost);
    }


function registerContender(address _contender) public {
  uint contenderNumber = contenders.length;
   require(msg.sender == _contender, "contender has to register themselves");
   require(contenderStatus[_contender] == false, "Already registered");
   require(contenderNumber <= 3, "contending slot is full");    
   contenderCount[_contender]++;
   contenderStatus[_contender] = true;
   contenders.push(_contender);
}


function votingPool(address _contender1, address _contender2, address _contender3) public mod(_contender1, _contender2, _contender3) contenderMod(_contender1, _contender2, _contender3){   
   balanceOf[msg.sender] -= (3 *_decimal());
   totalSupply -= (3 *_decimal());
   votingPoint[_contender1] += 3;
   votingPoint[_contender2] += 2;
   votingPoint[_contender3] += 1;
   votersStatus[msg.sender][_contender1][_contender2][_contender3] == true;
   votersStatus[msg.sender][_contender2][_contender1][_contender3] == true;
   votersStatus[msg.sender][_contender3][_contender2][_contender1] == true;
   votersStatus[msg.sender][_contender1][_contender3][_contender2] == true;
   votersStatus[msg.sender][_contender3][_contender1][_contender2] == true;
   votersStatus[msg.sender][_contender2][_contender3][_contender1] == true;
   votersLIst.push(msg.sender);

}

function collateVote(address _contender1, address _contender2, address _contender3) external contenderMod(_contender1, _contender2, _contender3){
   require(msg.sender == owner, "not authorized");
   require(_contenderDetails.length != 3, "vote already collated");
   _contenderDetails.push(contenderDetail(_contender1,votingPoint[_contender1]));
   _contenderDetails.push(contenderDetail(_contender2,votingPoint[_contender2]));
   _contenderDetails.push(contenderDetail(_contender3,votingPoint[_contender3]));
   collateVoteStatus[owner] = true;
}

function getResult() external view returns(contenderDetail[] memory){ 
   return _contenderDetails;
}

function startVoting() external {
   require(msg.sender == owner, "not authoruzed");
   setVoteStatus[msg.sender] = true;
}

function endVoting(address _contender1, address _contender2, address _contender3)external {
   require(collateVoteStatus[owner] == true, "collation has not been done");
   require(msg.sender == owner, "not authoruzed");
   setVoteStatus[msg.sender] = false;
   uint size = votersLIst.length;
   address[] memory addressMemory = new address[](size);
   addressMemory = votersLIst;
      for(uint i = 0; i < size; i++){
   votersStatus[addressMemory[i]][_contender1][_contender2][_contender3] == false;
   votersStatus[addressMemory[i]][_contender2][_contender1][_contender3] == false;
   votersStatus[addressMemory[i]][_contender3][_contender2][_contender1] == false;
   votersStatus[addressMemory[i]][_contender1][_contender3][_contender2] == false;
   votersStatus[addressMemory[i]][_contender3][_contender1][_contender2] == false;
   votersStatus[addressMemory[i]][_contender2][_contender3][_contender1] == false;
      }
   votersLIst = addressMemory;
   delete _contenderDetails;
   delete contenders;
   delete  votingPoint[_contender1];
   delete  votingPoint[_contender2];
   delete  votingPoint[_contender3];
   contenderCount[_contender1] = 0;
   contenderCount[_contender2] = 0;
   contenderCount[_contender3] = 0; 
   contenderStatus[_contender1] = false;
   contenderStatus[_contender2] = false;
   contenderStatus[_contender3] = false;
   collateVoteStatus[owner] == false;
}

   function getWinner() external view returns(contenderDetail memory final_result) {
   require(collateVoteStatus[owner] == true, "collation has not been done");
   contenderDetail memory Result1 = _contenderDetails[0];
   contenderDetail memory Result2 = _contenderDetails[1];
   contenderDetail memory Result3 = _contenderDetails[2];
   require( Result1.contenderVotes != Result2.contenderVotes || Result1.contenderVotes != Result3.contenderVotes || Result2.contenderVotes != Result3.contenderVotes, "there is a tie, check total result");
   if(Result1.contenderVotes > Result2.contenderVotes && Result1.contenderVotes > Result2.contenderVotes){
      final_result = Result1;
      return final_result;
   }else if (Result2.contenderVotes > Result1.contenderVotes && Result2.contenderVotes > Result3.contenderVotes){
      final_result = Result2;
      return final_result;
   }else if (Result3.contenderVotes > Result1.contenderVotes && Result3.contenderVotes > Result2.contenderVotes){
         final_result = Result3;
         return final_result;
   }
}

}