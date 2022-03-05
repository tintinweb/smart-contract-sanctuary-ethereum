/**
 *Submitted for verification at Etherscan.io on 2022-03-04
*/

pragma solidity ^0.5.0;

contract cert{
    struct college{
        string colname;
        bool value;
    }
    
    struct cert_details{
        string fname;
        string lname;
        string course;
        string colname;
        int256 id;
        string email;
        string saddress;
        string coladdress;
        string date;
    }
    
    mapping(address=>cert_details) certificates;
    mapping(address=>college) colleges;
    
    address owner;
    constructor() public {
        owner=msg.sender;
    }
    modifier ownerOnly{
        require(owner==msg.sender);
        _;
    }
    
    event coll_added(string name);//event when college is added
    
    event certadded(string fname,string lname,string course,string colname);
    
    
    function addCollege(address coladd,string memory name) ownerOnly  public{
        colleges[coladd]  =  college(name,true);
        string memory s = "this is how we do";
        emit coll_added(s); //calling event
    }
    
    function checkcoll(address col) view public returns (bool){
        return colleges[col].value;
    }
    
    function viewcert(address sender) view public returns(string memory fname){
        return certificates[sender].fname;
    }
    
    function addcert(string memory fname,string memory lname,string memory course, string memory colname, int256 id, string memory email, string memory saddress, string memory coladdress, string memory date) public{
     if(checkcoll(msg.sender)){
           certificates[msg.sender]=cert_details(fname,lname,course,colname,id,email,saddress, coladdress, date);
           emit certadded(fname,lname,course,colleges[msg.sender].colname);
     } else {
         emit coll_added("Fail");
     } 
 }
}