/**
 *Submitted for verification at Etherscan.io on 2022-09-03
*/

pragma solidity ^0.4.23;
contract supplychain{
    mapping(uint=>address)last_access;
    mapping(uint=>address)next_access;
    mapping(uint=>address)retailer;
    mapping(uint=>bool)sold;
    struct meds {
        string medName;
        string expdate;
        uint id;
        uint256 exp;
    }
        struct Manufacturedetails{
        address man;
    
        string name;
    }
    struct retaildetails{
        address own;
        string name;
        
    }
     struct Distdetails{
        address dist;
        string name;
    }
    
    struct user {
        mapping(string=>uint24) stock;
        string role;
        string name;
        } 
        mapping(address => user) userDetails;
    user userData;
    mapping(address=>bool) manaprove;
    mapping(address=>bool) distaprove;
    mapping(address=>bool) retailaprove;
    mapping(uint=>Manufacturedetails) md;
    mapping(uint=>retaildetails) rd;
    mapping(uint=>Distdetails) dd;
     mapping (uint => meds) med;
     meds medsData;
     retaildetails retaildetailsData;
     Manufacturedetails ManufacturedetailsData;
     Distdetails DistdetailsData;
     
     function setuser(string _role,address _user,string name)public {
         if(uint(keccak256(abi.encodePacked(_role))) == uint(keccak256(abi.encodePacked("Manufacturer")))){
          manaprove[_user]=true;
             }
       else if(uint(keccak256(abi.encodePacked(_role))) == uint(keccak256(abi.encodePacked("Distributer")))){
          distaprove[_user]=true;
             }
        else if(uint(keccak256(abi.encodePacked(_role))) == uint(keccak256(abi.encodePacked("Retailer")))){
          retailaprove[_user]=true;
             }
            else{
                revert("enter valid role");
          }
         userData.role=_role;
         userData.name=name;
         userDetails[_user]=userData;
     }
     
     function getmed(uint _id) public  view returns(string medName,
                             
                             string mname,string dname,string rname,bool soldstatus,bool expsts,string expdate) {
       
       
       bool a=false;
       if(now>=med[_id].exp){
           a==true;
       }
        string memory ed = med[_id].expdate;
        return (med[_id].medName,md[_id].name,dd[_id].name,rd[_id].name,sold[_id],a,ed);
    }  
    function setmed(string _medName,uint sid,uint lid,address _to,uint256 expiryd ,string expirydate) public {
       
        require(manaprove[msg.sender]==true,"Sender is not manufacturer");
        
        require(distaprove[_to]==true,"Reciever is not valid Distributer");
        medsData.medName=_medName;
       medsData.exp=now+expiryd*1 days;
        medsData.expdate=expirydate;
       ManufacturedetailsData.man=msg.sender;
        ManufacturedetailsData.name=userDetails[msg.sender].name;
        for(uint i=sid;i<=lid;i++){
         
        med[i]= medsData;
        sold[i]=false;
        md[i]=ManufacturedetailsData;
        last_access[i]=msg.sender;
        next_access[i]=_to;
        userDetails[msg.sender].stock[_medName]++;}
        }
        function checkex(uint id)public view returns(bool res){
            if(now>=med[id].exp){
               
               
                return false;
            }
            else{
                
                return true;
            }
        }
    function acceptdist(uint sid,uint lid,address _from)public{
        require(manaprove[_from]==true,"Sender is not manufacturer");
        require(distaprove[msg.sender]==true,"Reciever is distributer");
        
        DistdetailsData.dist=msg.sender;
        DistdetailsData.name=userDetails[msg.sender].name;
               for(uint i=sid;i<=lid;i++){
                   require(checkex(i)==true,"medicine expired");
        require(_from==last_access[i],"medicine came from someone else");
          require(msg.sender==next_access[i],"Unauthorized to access this medicine");
           require(sold[i]==false,"medicine already sold");
          last_access[i]=msg.sender;
          dd[i]=DistdetailsData;
           userDetails[msg.sender].stock[med[i].medName]++;
            userDetails[_from].stock[med[i].medName]--;
        }
       }
       function decline(uint sid,uint lid,address _from)public{
       
               for(uint i=sid;i<=lid;i++){
                   
        require(_from==last_access[i],"medicine came from someone else");
          require(msg.sender==next_access[i],"Unauthorized to access this medicine");
           require(sold[i]==false,"medicine already sold");
         next_access[i]=last_access[i];
         last_access[i]=msg.sender;
        }
       }
    function setdistdetails(address _to,uint sid,uint lid) public {
        require(distaprove[msg.sender]==true,"NOt a distributer");
        require(retailaprove[_to]==true,"Not a retailer");
               for(uint i=sid;i<=lid;i++){
                   require(checkex(i)==true,"medicine expired");
        require(msg.sender==last_access[i],"Unauthorized to access this medicine");
        require(msg.sender==next_access[i],"Unauthorized to access this medicine");
         require(sold[i]==false,"medicine already sold");
        require(userDetails[msg.sender].stock[med[i].medName]>=1,"Medicine not in stock");
        next_access[i]=_to;
               }
    }
    
    
       function setretaildetails(uint sid,uint lid,address _dist)public{
        require(retailaprove[msg.sender]==true,"Not a retailer");
       
        for(uint i=sid;i<=lid;i++){
            require(checkex(i)==true,"medicine expired");
        require(_dist==last_access[i],"medicine came from someone else");
        require(sold[i]==false,"medicine already sold");
        require(msg.sender==next_access[i],"Unauthorized to access this medicine");
        retaildetailsData.own=msg.sender;
        retaildetailsData.name=userDetails[msg.sender].name;
        rd[i]=retaildetailsData;
        retailer[i]=msg.sender;
        userDetails[msg.sender].stock[med[i].medName]++;
            userDetails[_dist].stock[med[i].medName]--;
        }
       }
   
    function sell(uint _id)public{
        require(checkex(_id)==true,"medicine expired");
        require(retailer[_id]==msg.sender,"Unauthorized to access this medicine");
   
        require(sold[_id]==false,"medicine already sold");
        sold[_id]=true;
        userDetails[msg.sender].stock[med[_id].medName]--;
    }
    function stockcheck(address[] readd,string medname)public view returns(uint24[] st){
       uint24[] memory a = new uint24[](readd.length);
        for(uint24 i=0;i<readd.length;i++){
           a[i]=userDetails[readd[i]].stock[medname];
        }
        return a;
    }
}