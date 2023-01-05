/**
 *Submitted for verification at Etherscan.io on 2023-01-05
*/

pragma solidity ^0.4.0;
contract  VoteChain{
    // Voter,Government,Manager,Candidate,Undefined
    enum ROLE{UND,USR,GOV,MAN,CAN}
        // Returns  uint
        // UND      0
        // USR      1
        // GOV      2
        // MAN      3
        // CAN      4

    address GOV_addr;

    struct MEMBER{
        string name;
        uint areaID;
        uint age;
        ROLE Role;
        bool role_confirm;
        bool vote_right;
        bool voteDone;
    }
    mapping(address=>MEMBER) members;

    struct VoteEvent{
        string name;
        uint areaID;
        uint votingtime;
        bool isprocess;        
    }
    VoteEvent sampleEvent;

    // canlist
    address[] CANList;
    mapping(address => address) voterToCAN;
    mapping(address => uint)CAN_address_To_Count;


    constructor() public{
    GOV_addr = msg.sender;
    }

    //modifier
    modifier only_account_owner(address _addr){
    require(msg.sender == _addr);
    _;
    }

    modifier only_MAN(){
    require((members[msg.sender].Role==ROLE.MAN)&&(members[msg.sender].role_confirm ==true));
    _;
    }

    modifier only_CAN(){
    require (members[msg.sender].Role==ROLE.CAN) /*&&(members[msg.sender].role_confirm==true))*/;
    _;
    }

    modifier only_GOV(){
    require(msg.sender == GOV_addr);
    _;
    }

    modifier only_GOV_or_MAN(){
        require((msg.sender == GOV_addr) || ((members[msg.sender].Role==ROLE.MAN)&&(members[msg.sender].role_confirm ==true)));
        _;
    }

    modifier only_USR(){
        require( (members[msg.sender].Role==ROLE.USR)&&(members[msg.sender].role_confirm==true) );
        _;
    }

    modifier only_vote_time(){
    require(sampleEvent.isprocess);
    _;
    }

    modifier right_to_vote() {
        require (
            members[msg.sender].vote_right==true,
            " You don't have the right to vote.");
            _;
    }

    modifier vote_not_yet() {
        require (
            members[msg.sender].voteDone == false,
            "You have already voted."
        );
        _;
    }

        modifier already_vote() {
        require (
            members[msg.sender].voteDone == true,
            "You have not voted."
        );
        _;
    }

 

    function set_infor_Role(address _addr, string _name,  ROLE _Role, bool _voteRight, uint _age) only_GOV_or_MAN public{
    members[_addr].age = _age;
    members[_addr].name = _name;
    members[_addr].Role = _Role;
    members[_addr].role_confirm = false;
    members[_addr].vote_right = _voteRight;
    members[_addr].voteDone = false;
    }

    
    function show_infor(address _addr) only_GOV_or_MAN  public view returns ( string _name, uint _age, ROLE _Role, bool _voteRight) {
    _name = members[_addr].name ;
    _age = members[_addr].age ;
    _Role = members[_addr].Role;
    _voteRight = members[_addr].vote_right;
 
    }
    

    //USR
    function vote(address _addr) right_to_vote vote_not_yet public{
        uint m = 0;
        for (uint i = 0; i < CANList.length; i++){
            if ( CANList[i] == _addr) {
                m++;
            }
        }
        require(
            m == 1,
            "Not available for candidate"
        );
    if ( m==1 ){
    CAN_address_To_Count[_addr]++;
    members[msg.sender].voteDone=true;
    }
    }
    
    function unvote() right_to_vote  already_vote public{
    CAN_address_To_Count[voterToCAN[msg.sender]]--;
    members[msg.sender].voteDone=false;
    }


    function add_candidate(address _addr) only_GOV_or_MAN public{
  

    CANList.push(_addr);
    members[_addr].Role = ROLE.CAN;

    CAN_address_To_Count[_addr]=0;
 
    }

    function show_results(address _addr) view public returns(uint){
        return CAN_address_To_Count[_addr];
    }

    function determine_Winner() view public returns(string _WinnerName) {
        uint tempVoteCount = 0;
        address Winner_ID;
        for (uint i = 0; i < CANList.length; i++){
            address _addr = CANList[i]; 
            if(CAN_address_To_Count[_addr] > tempVoteCount ) {
                tempVoteCount = CAN_address_To_Count[_addr];
                Winner_ID = CANList[i];
                _WinnerName = members[CANList[i]].name; 
            }
        }
    }
 
    
    }