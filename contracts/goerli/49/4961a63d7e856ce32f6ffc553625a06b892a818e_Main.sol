/**
 *Submitted for verification at Etherscan.io on 2022-07-07
*/

pragma solidity ^0.8.0;
interface  Token{
    function mint(address _to) external;
   
    function transferFrom(address sender, address recipient, uint256 amount) external;
} 
contract Main{
    
    uint256 public  nftNodePrice = 3000000000;
    
    uint256 public  nftmintPrice = 300000000;
   
    address public nftmintAddress;
    
    address public nftNodeAddress;
    
    address public _owner;
    
    address usdtAddress;
    
    address nftAddress;
    
    mapping(address => uint256) public nodeStart;
    
    mapping(address => address) public higherLevel;
    
    event BuyNftNode(address to, uint price, address nftNodeAddress);  
     
    event BuyNftMint(address to, uint price, address nftmintAddress, address supaddress);
      
    constructor(){
        _owner = msg.sender;
    }
    
    modifier Owner {   //管理员 判断
        require(_owner ==msg.sender);
        _;
    }
    function setUpOwner(address _to) public Owner{
        _owner = _to;
    }
    function setUpnftmintAddress(address _to) public Owner{
        
        nftmintAddress = _to;
    }
      function setUpnftNodeAddress(address _to) public Owner{
        
        nftNodeAddress = _to;
    }
      function setUpnftNodePrice(uint256 _prcie) public Owner{
        
        nftNodePrice = _prcie;
    }
      function setUpnftmintPrice(uint256 _prcie) public Owner{
        
        nftmintPrice = _prcie;
    }
    
    function setUpusdtAddress(address _to) public Owner{
      usdtAddress = _to;
    }
    
     function setUpnftAddress(address _to) public Owner{
      nftAddress = _to;
    }
    
    
    function buyNodeNft(uint256 _value) public{
        require(_value >= nftNodePrice,"nodeprice not pic" );
        Token t = Token(usdtAddress);
        t.transferFrom(msg.sender,nftNodeAddress,_value);
        nodeStart[msg.sender] = 1;
        
        emit BuyNftNode(msg.sender, _value, nftNodeAddress);
        
    }
    
    
    function heightNode(address _to) public view  returns(uint256){
        if(nodeStart[_to] == 1){
            return nodeStart[_to];
        }else{
            if(higherLevel[_to] == address(0x00)){
                return 0;
            }else{
                 return heightNode(higherLevel[_to]);
            }
        }
    }
    
    
    function heightStart(address _to,address _to2) public view  returns(uint256){
        if(higherLevel[_to] == address(0x00)){
            return 1;
        }else{
            if(higherLevel[_to] == _to2){
                return 2;
            }else{
                return heightStart(higherLevel[_to],_to2);
            }
        }
    }
    
    
    
    function buyNftMint(address _supadr,uint256 _value) public {
          require(_value >= nftmintPrice,"nodeprice not pic" );
          require(heightNode(_supadr) == 1,"heightNode not node");
          require(heightStart(_supadr,msg.sender) == 1,"heightStart not node");
          require(_supadr != msg.sender);
          Token t = Token(usdtAddress);
          t.transferFrom(msg.sender,nftmintAddress,_value);
          higherLevel[msg.sender] = _supadr;
          Token toNft = Token(nftAddress);
          toNft.mint(msg.sender);
          emit BuyNftMint(msg.sender,_value,nftmintAddress,_supadr);
    }
    
    

    
    
}