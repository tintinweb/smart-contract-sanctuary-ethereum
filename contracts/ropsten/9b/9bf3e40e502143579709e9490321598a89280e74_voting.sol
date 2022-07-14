/**
 *Submitted for verification at Etherscan.io on 2022-07-14
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.22 <0.9.0;
contract voting {
struct list{
    string Pan;
    string name;
    uint age;
    address Address;
    bool Enrolled;
    bool voted;
    bool tokened;
} 
struct candidate_list{
    string symbol;
    string Name;
    address Address;
    uint id;
    bool listed;
}
address election_officer;
string public decimal="0";
uint public totalSupply;
address public founder;
mapping(address=>uint)  balances;
mapping(address=>mapping(address=>uint)) allowed;
mapping(string=>list) public voter_info;
mapping(string=>candidate_list) public can_info;
mapping(string=>uint) public review;
string[]public party_list;

constructor(address  officer_address){
    election_officer=officer_address;
    totalSupply=100000;
    founder=officer_address;
    balances[founder]=totalSupply;
}
modifier only_owner(string memory pan_no){
    list storage Voter=voter_info[pan_no];
    require(msg.sender==election_officer,"ONLY OFFICER CAN ACCESS");
    require(Voter.Enrolled==false,"YOUR ENROLLED");
    _;
}
modifier only_officer(){
    require(msg.sender==election_officer,"ONLY OFFICER CAN ACCESS");
    _;
}

modifier Voter_requirement(string memory pan_no){
    list storage Voter=voter_info[pan_no];
    require(Voter.Enrolled,"YOUR NOT ENROLLED, PLEASE ENROLLED");
    require(Voter.voted==false,"YOUR HAVE VOTED");
    _;
}
modifier candidate_check(uint _id,string memory symbol){
    candidate_list storage candidate=can_info[symbol];
    require(candidate.id==_id,"ID DOES NOT MATCH");
    require(candidate.listed,"YOUR CANDIDATE IS NOT LISTED");
    _;
}

function Enroll_voter(string memory pan_no,string memory _name,uint age,address _address)public only_owner(pan_no) returns(string memory _pan,string memory _Name,uint _age,address  _Address,bool _Enrolled,bool _Voted){
    require(age>=18,"VOTER IS UNDER 18");
    list storage Voter=voter_info[pan_no];
    Voter.Pan=pan_no;
    Voter.name=_name;
    Voter.age=age;
    Voter.Address=_address;
    Voter.Enrolled=true;
    Voter.voted=false;
    Voter.tokened=false;
    return (Voter.Pan,Voter.name,Voter.age,Voter.Address,Voter.Enrolled,Voter.voted);
}
function Enroll_candidate(string memory _symbol,string memory _name,address  _address,uint _id) public only_officer returns(string memory symbol,string memory _Name,uint id,address _Address,bool Listed){
    candidate_list storage candidate=can_info[_symbol];
    candidate.symbol=_symbol;
    candidate.Name=_name;
    candidate.id=_id;
    candidate.Address=_address;
    candidate.listed=true;
    party_list.push(_symbol);
    return (candidate.symbol,candidate.Name,candidate.id,candidate.Address,candidate.listed);
}
function Approve_voters_token(string memory pan_no)public Voter_requirement(pan_no) returns(uint token) {
    list storage Voter=voter_info[pan_no];
    require(Voter.tokened==false,"YOUR TOKEN HAS BEEN APPROVED ALREADY");
    approve(Voter.Address,1);
    transferFrom(msg.sender,Voter.Address,1);
    Voter.tokened=true;
    return allowance(msg.sender,Voter.Address);
}
function vote(string memory symbol,uint _id,string memory pan_no)public Voter_requirement(pan_no) candidate_check(_id,symbol) returns(uint _token){
    list storage Voter=voter_info[pan_no];
    candidate_list storage candidate=can_info[symbol];
    approve(candidate.Address,1);
    transferFrom(msg.sender,candidate.Address,1);
    Voter.voted=true;
    return allowance(msg.sender,candidate.Address);
}
function Winner() public only_officer view returns(string memory _partyname, uint _winner) {
    string memory partyname;
    uint winner=0;
    for(uint i=0;i<party_list.length;i++){
        candidate_list storage candidate=can_info[party_list[i]];
        uint a=balanceOf(candidate.Address);
        if(a>winner){
            winner=a;
            partyname=candidate.symbol;
        }
    }
    return (partyname,winner);
}

function vote_review() public {
    for(uint i=0;i<party_list.length;i++){
    candidate_list storage candidate=can_info[party_list[i]];
    review[candidate.symbol]=balanceOf(candidate.Address);
}
}
function balanceOf(address tokenOwner) public view  returns(uint balance){
    return balances[tokenOwner];
}

function transfer(address to,uint tokens) public  returns(bool success){
    require(balances[msg.sender]>=tokens);
    balances[to]+=tokens; 
    balances[msg.sender]-=tokens;
    return true;
}

function approve(address spender,uint tokens) public  returns(bool success){
    require(balances[msg.sender]>=tokens);
    require(tokens>0);
    allowed[msg.sender][spender]=tokens;
    return true;
}

function allowance(address tokenOwner,address spender) public view  returns(uint noOfTokens){
    return allowed[tokenOwner][spender];
}

function transferFrom(address from,address to,uint tokens) public  returns(bool success){
    require(allowed[from][to]>=tokens);
    require(balances[from]>=tokens);
    balances[from]-=tokens;
    balances[to]+=tokens;
    return true;
}
}