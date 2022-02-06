/**
 *Submitted for verification at Etherscan.io on 2022-02-06
*/

pragma solidity ^0.4.19;


interface ERC165 {
    /// @notice 查询一个合约时候实现了一个接口
    /// @param interfaceID  参数：接口ID, 参考上面的定义
    /// @return true 如果函数实现了 interfaceID (interfaceID 不为 0xffffffff )返回true, 否则为 false
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}


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

library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a); // underflow 
    uint256 c = a - b;

    return c;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a); // overflow

    return c;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
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
   constructor() public  {
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
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}



contract animalMain is  ERC721,ERC165, Ownable {
  string public name_ = "anitoken";
  uint256 public mintPrice = 0.1 ether;

  constructor() public payable{}

  struct animal {
    bytes32 dna; //DNA
    uint8 star; //幾星級(抽卡的概念)
    uint8 roletype; //(哪種動物 1老虎  2狗  3獅子  4鳥)
    string url;
    uint256 price;
    bool exist;
  }
  string public symbol_ = "ANI";
  
  animal[] private animals;
  mapping (bytes4 => bool) internal supportedInterfaces;
  mapping (uint => address) public animalToOwner; //每隻動物都有一個獨一無二的編號，呼叫此mapping，得到相對應的主人
  mapping (address => uint) ownerAnimalCount; //回傳某帳號底下的動物數量
  mapping (uint => address) animalApprovals; //和 ERC721 一樣，是否同意被轉走


  event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
  event Approval(address indexed _from, address indexed _to,uint indexed _tokenId);
  event Take(address _to, address _from,uint _tokenId);
  event Create(address _from , uint _tokenId, bytes32 dna,uint8 star, uint8 roletype, string url, uint256 price);

  function name() external view returns (string) {
        return name_;
  }

  function symbol() external view returns (string) {
        return symbol_;
  }

  function totalSupply() public view returns (uint256) {
    return animals.length;
  }

  function balanceOf(address _owner) public view returns (uint256 _balance) {
    return ownerAnimalCount[_owner]; // 此方法只是顯示某帳號 餘額
  }

  function ownerOf(uint256 _tokenId) public view returns (address _owner) {
    return animalToOwner[_tokenId]; // 此方法只是顯示某動物 擁有者
  }

  function checkAllOwner(uint256[] _tokenId, address owner) public view returns (bool) {
    for(uint i=0;i<_tokenId.length;i++){
        if(owner != animalToOwner[_tokenId[i]]){
            return false;   //給予一連串動物，判斷使用者是不是都是同一人
        }
    }
    
    return true;
  }

  function seeAnimalDna(uint256 _tokenId) public view returns (bytes32 dna) {
    return animals[_tokenId].dna;
  }

  function seeAnimalStar(uint256 _tokenId) public view returns (uint8 star) {
    return animals[_tokenId].star;
  }
  
  function seeAnimalRole(uint256 _tokenId) public view returns (uint16 roletype) {
    return animals[_tokenId].roletype;
  }

  function getAnimalByOwner(address _owner) external view returns(uint[]) { //此方法回傳所有帳戶內的"動物ID"
    uint[] memory result = new uint[](ownerAnimalCount[_owner]);
    uint counter = 0;
    for (uint i = 0; i < animals.length; i++) {
      if (animalToOwner[i] == _owner) {
        result[counter] = i;
        counter++;
      }
    }
    return result;
  }

  function transfer(address _to, uint256 _tokenId) public {
    //TO DO 請使用require判斷要轉的動物id是不是轉移者的
    require(ownerOf(_tokenId) == msg.sender,"Only owner can transfer");
    //增加受贈者的擁有動物數量
    ownerAnimalCount[_to] = SafeMath.add(ownerAnimalCount[_to],1);
    //減少轉出者的擁有動物數量
    ownerAnimalCount[msg.sender] = SafeMath.sub(ownerAnimalCount[msg.sender],1);
    //動物所有權轉移
    animalToOwner[_tokenId] = _to;
    
    emit Transfer(msg.sender, _to, _tokenId);
  }

  function approve(address _to, uint256 _tokenId) public {
    require(animalToOwner[_tokenId] == msg.sender);
    
    animalApprovals[_tokenId] = _to;
    
    emit Approval(msg.sender, _to, _tokenId);
  }

  function transferFrom(address _from, address _to, uint256 _tokenId) external {
    // Safety check to prevent against an unexpected 0x0 default.
    emit Transfer(_from, _to, _tokenId);
  }


  function takeOwnership(uint256 _tokenId) public {
    require(animalToOwner[_tokenId] == msg.sender);
    address owner = ownerOf(_tokenId);
    ownerAnimalCount[msg.sender] = SafeMath.add(ownerAnimalCount[msg.sender],1);
    ownerAnimalCount[owner] = SafeMath.sub(ownerAnimalCount[owner],1);
    animalToOwner[_tokenId] = msg.sender;
    emit Take(msg.sender, owner, _tokenId);
  }

  
  function createAnimal() public payable{
    require(
        mintPrice == msg.value
    );

    bytes32 dna;
    uint8 star;
    uint8 roletype;
    uint256 price = 0.1 ether;
    string memory url = "";
    //TO DO 
    //使用亂數來產生DNA, 星級, 動物種類
    dna = keccak256(abi.encodePacked(now));
    star = uint8(now % 6);
    roletype = uint8(now % 4);
    
    uint id = animals.length;
    emit Create(msg.sender, id, dna, star, roletype, url,  price);
    animals.push(animal(dna, uint8(star), uint8(roletype), url,  price, true));
    animalToOwner[id] = msg.sender;
    ownerAnimalCount[msg.sender]++;
        
 
  }

  function get_animal(uint idx) view public returns(bytes32, uint8, uint8,string,  uint256){
    require(idx>=0 && idx<animals.length);
    return (animals[idx].dna, animals[idx].star, animals[idx].roletype,animals[idx].url, animals[idx].price);
  }

  function update_animal_price(uint idx, uint256 new_price) public returns(bytes32, uint8, uint8,string,uint256){
    require(idx>=0 && idx<animals.length && new_price>0);
    animals[idx].price = SafeMath.mul(new_price, 1 ether);
    return (animals[idx].dna, animals[idx].star, animals[idx].roletype, animals[idx].url,  animals[idx].price);
  }

  function supportsInterface(bytes4 interfaceID) external view returns (bool) {
    return supportedInterfaces[interfaceID];
  }
}