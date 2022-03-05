/**
 *Submitted for verification at Etherscan.io on 2022-03-04
*/

contract ERC721 {
 
 string private name = "jay's NFT";
 mapping(int256=>address) private owner;
 mapping(int256=>address) private approval;
 mapping(address=>int256) private balance;
 mapping(address=>mapping(address=>bool)) private allapproval;

//   mint the nft 
function mint(int256 token) external {
    owner[token] = msg.sender;
    balance[msg.sender] +=1;
}

//  balanceoff to get the balance 
function balanceOff(address owner) external returns(int256 ownerBalance){
    require(owner != address(0), "not a valid address ");
    return balance[owner];
}
//  get the owner of nft 
function ownerOff(int256 token) external returns(address ownersAddress){
    require(owner[token] != address(0), "not a valid token");
    return owner[token];
}
// function for the transfer of  the NFT 
function safeTransferFrom(address from, address to, int256 token) external payable {
require( msg.sender == owner[token] || isApproveOneOrAll(from,msg.sender,token), "no authorizaion to send NFT");
owner[token] = to;
balance[to] += 1;
balance[from] -= 1;
approval[token] = address(0);

 
}
// check approval in case of transaction
function isApproveOneOrAll(address owner, address sender , int256 token) internal returns(bool){
    if(approval[token] == sender || allapproval[owner][sender] == true){
        return true;
    }else{
        return false;
    }
} 
// direct transfer function 
function transferfrom(address to , int256 token) external payable{
    require(msg.sender == owner[token], "You are not the owner");
    owner[token] = to;
    balance[to] += 1;
    balance[msg.sender] -= 1;
    approval[token] = address(0);
}
 // aproval to a token function 
 function setApproval(address to , int token) external payable{
    address from = owner[token];
     require(msg.sender == owner[token] || allapproval[from][msg.sender] == true, "no authorization ");
     approval[token] = to ;
    
 }
 function getApproval(int256 token) external returns(address){
     require(owner[token] != address(0), "not a valid token");
    //  require(approval[token] != address(0), "not approved");
     return approval[token];
 }
//  setapproval all function
function setApprovalAll(address to , bool approval) external {
    allapproval[msg.sender][to] = approval;
}
function getApprovalAll(address owner , address to ) external returns(bool){
    if(allapproval[owner][to]){
      return allapproval[owner][to];
    }else{
        return false;
    }
    
} 
}