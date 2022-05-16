pragma solidity ^0.6.4;


/**
 * The ETR_AA contract saves the government eth address and AA 
 contract address
 */
contract ETR_AA {
  //the AA infomation struct
  struct AAinfo {
    string shortname;
    //address contract_addr;
    bytes32 infohash;
  } 
  
//   struct MAYblack{
//       bool blackornot;
//       uint times;
//   }
  // store the all address mapping the message
  mapping (address => AAinfo) public Funder;
//   mapping(address=> MAYblack) public callbacktime;
  address[] public Funder_addrlist;
  address[] public STU_addrlist;
  address[] public Sender_addrlist;
  // password for the right to store getting from the deploy-contract institution
  //string private password;
  //bool  validpassword = false;
  address public owner;
  constructor() public {
    owner = msg.sender;
  }
  //event InspectNotice(bytes32 certhash, address addrSTU, address addrCA, address addrAA, address sender);    
  // function setPassword (string memory val) public{
  //  require (owner == msg.sender); 
  //  password = val;
  //  validpassword = true;
  // }
  //加入AA机构，由政府权威机关掌控
  
  function setFunder(string memory funder_name, address addressget, bytes32 infohash) public{
    require (owner == msg.sender);
    bool newaccount = true;
    Funder[addressget] = AAinfo(funder_name,infohash);
    ETR_CA etr_ca = ETR_CA(addressget);
    etr_ca.Init(funder_name, infohash);
    for(uint i = 0;i<Funder_addrlist.length;i++){
      if (Funder_addrlist[i] == addressget){
        newaccount = false;
        break;
      }
    }
    if (newaccount){
      Funder_addrlist.push(addressget);
    }
  }
  //删除机构
  function DeleteFunder (address wrongf) public{
    require (owner == msg.sender);
    for(uint i = 0;i<Funder_addrlist.length;i++){
      if (wrongf == Funder_addrlist[i]){
        Funder_addrlist[i] = address(0);
        break;
      }
    }
    delete Funder[wrongf];
  }
  //删除学生
  function DeleteSTU (address wrongs) public{
    require (owner == msg.sender);
    for (uint i = 0;i<STU_addrlist.length;i++){
      if (wrongs == STU_addrlist[i]){
        STU_addrlist[i] = address(0);
        break;
      }
    }
  }

  function getLength () view public returns(uint len){
    len = Funder_addrlist.length;
  }
  
  function getSenderL() view public returns(uint len){
    len = Sender_addrlist.length;
  }
  
//   function getAAFunder () view public returns(address[] memory list){
//     list = Funder_addrlist;
//   }

  function AAornot(address AAaddr) view public returns(bool res){
    if (Funder[AAaddr].infohash!=bytes32(0)){
      res = true;
    }
  } 
  //在web端显示
  function showFunder (uint index_out) view public returns(address showaddr, string memory showname, bytes32 showhash){
    showaddr = Funder_addrlist[index_out];
    showname = Funder[showaddr].shortname;
    //showcontract = Funder[showaddr].contract_addr;
    showhash = Funder[showaddr].infohash;
  } 
  //一般人调用可以查看STU是否加入网络，AA机构调用可加入新的STU
  function AccessSTU (address STUaddr) public returns(bool res){
    bool exist = false;
    for(uint j = 0;j<STU_addrlist.length;j++){
      if (STU_addrlist[j] == STUaddr){
        exist = true;
        break;
      }
    }
    if (Funder[msg.sender].infohash!=bytes32(0)){
      if(!exist){
        STU_addrlist.push(STUaddr);
      }
    }else if (exist){
        res = true;
    }
  }
  
  function AccessEP (address EPaddr) public returns(bool res){
    bool exist = false;
    for(uint j = 0;j<Sender_addrlist.length;j++){
      if (Sender_addrlist[j] == EPaddr){
        exist = true;
        break;
      }
    }
    
    if (exist){
        res = true;
    }else if(msg.sender == owner){
        Sender_addrlist.push(EPaddr);
    }
  }
  
  function DeleteEP (address wrongs) public{
    require (owner == msg.sender);
    for (uint i = 0;i<Sender_addrlist.length;i++){
      if (wrongs == Sender_addrlist[i]){
        Sender_addrlist[i] = address(0);
        break;
      }
    }
  }
}

interface ETR_CA{function Init( string calldata _name, bytes32 _hashinfo) external;}