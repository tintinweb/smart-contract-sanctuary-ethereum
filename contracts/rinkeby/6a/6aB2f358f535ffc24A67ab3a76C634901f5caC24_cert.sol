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
        //string colname;
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
    
    event certadded(string fname,string lname,string course,string cname);
    
    
    function addCollege(address coladd,string memory name) ownerOnly  public{
        colleges[coladd]  =  college(name,true);
        string memory s = "this is how we do";
        emit coll_added(s); //calling event
    }
    
    function checkcoll(address col) view public returns (bool){
        return colleges[col].value;
    }
    
    function viewcert(address sender) view public returns(string memory ffname){
        return certificates[sender].fname;
    }
    
    function addcert(string memory lname,string memory fname,string memory course) public{
     if(checkcoll(msg.sender)){
           certificates[msg.sender]=cert_details(fname,lname,course);
          // emit certadded(fname,lname,course,colleges[msg.sender].colname);
     }
        
 }
}