/**
 *Submitted for verification at Etherscan.io on 2022-04-07
*/

pragma solidity ^0.4.19;

//此合約為 hahow 零基礎邁向區塊鏈工程師：Solidity 智能合約 課程 作業二範 ERC721 範本智能合約

//做作業前，請同學先把功能掃過一次

//做作業方式：
//老師已經完成合約75%，剩下關鍵的方法需要各位同學自行填空，發揮創意。

//做作業關鍵：
//1. 先搞懂ERC721與ERC20的差異，你就會搞懂這些功能為什麼要這樣設計
//2. 請直接搜尋 TO DO 找出要完成的地方


//erc721的介面
contract ERC721 {
  event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

  function totalSupply() public view returns (uint256 total);
  function balanceOf(address _owner) public view returns (uint256 _balance);
  function ownerOf(uint256 _tokenId) public view returns (address _owner);
  function transfer(address _to, uint256 _tokenId) public;
  function approve(address _to, uint256 _tokenId) public;
  function transferFrom(address _from, address _to, uint256 _tokenId) external;
  function name() external view returns (string _name);
  function symbol() external view returns (string _symbol);
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }



  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {//更換合約擁有者
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);

    owner = newOwner;
  }

}


contract animalMain is  ERC721,Ownable {

  using SafeMath for uint256;
    string public name_ = "anitoken";

  struct bordercollie {
    uint8 ear; //耳朵:立耳 折耳 垂耳 一折耳一立耳
    uint8 color; //顏色:黑白 黃白 巧克力白 隕石 全白
    uint8 size; //大小:s m l xl
  }

  bordercollie[] public bordercollies;//將 struct:bordercollie
  string public symbol_ = "BC";

  mapping (uint => address) public animalToOwner; //每隻動物都有一個獨一無二的編號，呼叫此mapping，得到相對應的主人
  mapping (address => uint) ownerAnimalCount; //回傳某帳號底下的動物數量
  mapping (uint => address) animalApprovals; //和 ERC721 一樣，是否同意被轉走

  event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
  event Approval(address indexed _from, address indexed _to,uint indexed _tokenId);
  event Take(address _to, address _from,uint _tokenId);
  event Create(uint _tokenId, bytes32 dna,uint8 star, uint16 roletype);

  function name() external view returns (string) {
        return name_;
  }

  function symbol() external view returns (string) {
        return symbol_;
  }

  function totalSupply() public view returns (uint256) {//顯示已生成動物總量
    return bordercollies.length;
  }

  function balanceOf(address _owner) public view returns (uint256 _balance) {
    return ownerAnimalCount[_owner]; // 此方法只是顯示某帳號的餘額
  }

  function ownerOf(uint256 _tokenId) public view returns (address _owner) {
    return animalToOwner[_tokenId]; // 此方法只是顯示某動物的擁有者
  }

  function checkAllOwner(uint256[] _tokenId, address owner) public view returns (bool) {
    for(uint i=0;i<_tokenId.length;i++){
        if(owner != animalToOwner[_tokenId[i]]){
            return false;   //給予一連串動物，判斷使用者是不是都是同一人
        }
    }
    
    return true;
  }

  function seeAnimalEar(uint256 _tokenId) public view returns (uint8 ear) {//tokenId to search ear
    return bordercollies[_tokenId].ear;
  }

  function seeAnimalColor(uint256 _tokenId) public view returns (uint8 color) {//tokenId to search color
    return bordercollies[_tokenId].color;
  }
  
  function seeAnimalSize(uint256 _tokenId) public view returns (uint16 roletype) {//tokenId to search size
    return bordercollies[_tokenId].size;
  }

  function getAnimalByOwner(address _owner) external view returns(uint[]) { //此方法回傳所有帳戶內的"動物ID"
    uint[] memory result = new uint[](ownerAnimalCount[_owner]);
    uint counter = 0;
    for (uint i = 0; i < bordercollies.length; i++) {
      if (animalToOwner[i] == _owner) {
        result[counter] = i;//counter=第counter隻符合條件，動物ID為i
        counter++;
      }
    }
    return result;//result[]
  }

  function transfer(address _to, uint256 _tokenId) public {
    //TO DO 請使用require判斷要轉的動物id是不是轉移者的
    require(animalToOwner[_tokenId]==msg.sender,"animal owner is not sender");
    //增加受贈者的擁有動物數量
    ownerAnimalCount[_to]=ownerAnimalCount[_to]+1;
    //減少轉出者的擁有動物數量
    ownerAnimalCount[msg.sender]=ownerAnimalCount[msg.sender]-1;
    //動物所有權轉移
    animalToOwner[_tokenId]=_to;

    
    emit Transfer(msg.sender, _to, _tokenId);
  }

  function approve(address _to, uint256 _tokenId) public {
    require(animalToOwner[_tokenId] == msg.sender);
    
    animalApprovals[_tokenId] = _to;
    
    emit Approval(msg.sender,_to, _tokenId);
  }

  function transferFrom(address _from, address _to, uint256 _tokenId) external {
    // Safety check to prevent against an unexpected 0x0 default.
    
    emit Transfer(_from, _to, _tokenId);
  }

  function takeOwnership(uint256 _tokenId) public {
    require(animalToOwner[_tokenId] == msg.sender);
    
    address owner = ownerOf(_tokenId);//owner=function"此動物的擁有者"

    ownerAnimalCount[msg.sender] = ownerAnimalCount[msg.sender].add(1);
    ownerAnimalCount[owner] = ownerAnimalCount[owner].sub(1);
    animalToOwner[_tokenId] = msg.sender;
    
    emit Take(msg.sender, owner, _tokenId);
  }

  function random(uint8 number,uint8 randint) public view returns(uint8){//number需小於2^8
    return uint8(keccak256(abi.encodePacked(block.timestamp,block.difficulty,  
    msg.sender,randint))) % number;
  }

  function makeNFT() private view returns(uint8,uint8,uint8) {
    uint8 rand0 = random(255,255);
    uint8 rand1 = random(255,rand0);//若直接CALL三次 random(255)會三個數值都一樣--------------------------
    uint8 rand2 = random(255,rand1);
    uint8 rand3 = random(255,rand2);

      return (rand1,rand2,rand3);//隨機產生
    
  }
  modifier maxPrice() { //限制每次建立動物需要花費多少ETH
  require(msg.value > 0 && msg.value == 0.1 ether,"value is not enough"); 
  _; 
  }

  function mint1() public payable maxPrice{

      uint8 ear; //耳朵:立耳 折耳 垂耳 一折耳一立耳
      uint8 color; //顏色:黑白 黃白 巧克力白 隕石 全白
      uint8 size; //大小:s m l xl
      (ear,color,size)=makeNFT();

      //TO DO 
      //使用亂數來產生DNA, 星級, 動物種類
       
      uint id = bordercollies.push(bordercollie(uint8(ear), uint8(color), uint8(size))) - 1 ;//生成ID (若不-1，初始ID會從1開始，但陣列(bordercollies)是從0開始，所以會無法對齊)
      animalToOwner[id] = msg.sender;//寫入ID對應的擁有者
      ownerAnimalCount[msg.sender]++;//該擁有者擁有的動物數量+1
 
  }
  
}