/**
 *Submitted for verification at Etherscan.io on 2021-06-30
*/

pragma solidity ^0.4.19;

//erc721็ไป้ข
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
  function Ownable() public {
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
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}



contract animalMain is  ERC721,Ownable {

  using SafeMath for uint256;
    string public name_ = "anitoken";

  struct animal {
    bytes32 dna; //DNA
    uint8 star; //ๅนพๆ็ด(ๆฝๅก็ๆฆๅฟต)
    uint16 roletype; //(ๅช็จฎๅ็ฉ 1่่  2็  3็ๅญ  4้ณฅ)
  }

  animal[] public animals;
  string public symbol_ = "ANI";

  mapping (uint => address) public animalToOwner; //ๆฏ้ปๅ็ฉ้ฝๆไธๅ็จไธ็กไบ็็ทจ่๏ผๅผๅซๆญคmapping๏ผๅพๅฐ็ธๅฐๆ็ไธปไบบ
  mapping (address => uint) ownerAnimalCount; //ๅๅณๆๅธณ่ๅบไธ็ๅ็ฉๆธ้
  mapping (uint => address) animalApprovals; //ๅ ERC721 ไธๆจฃ๏ผๆฏๅฆๅๆ่ขซ่ฝ่ตฐ

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

  function totalSupply() public view returns (uint256) {
    return animals.length;
  }

  function balanceOf(address _owner) public view returns (uint256 _balance) {
    return ownerAnimalCount[_owner]; // ๆญคๆนๆณๅชๆฏ้กฏ็คบๆๅธณ่ ้ค้ก
  }

  function ownerOf(uint256 _tokenId) public view returns (address _owner) {
    return animalToOwner[_tokenId]; // ๆญคๆนๆณๅชๆฏ้กฏ็คบๆๅ็ฉ ๆๆ่
  }

  function checkAllOwner(uint256[] _tokenId, address owner) public view returns (bool) {
    for(uint i=0;i<_tokenId.length;i++){
        if(owner != animalToOwner[_tokenId[i]]){
            return false;   //็ตฆไบไธ้ฃไธฒๅ็ฉ๏ผๅคๆทไฝฟ็จ่ๆฏไธๆฏ้ฝๆฏๅไธไบบ
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

  function getAnimalByOwner(address _owner) external view returns(uint[]) { //ๆญคๆนๆณๅๅณๆๆๅธณๆถๅง็"ๅ็ฉID"
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
    //ไฝฟ็จrequireๅคๆท่ฆ่ฝ็ๅ็ฉidๆฏไธๆฏ่ฝ็งป่็
    require(animalToOwner[_tokenId] == msg.sender);
    //ๅขๅ?ๅ่ด่็ๆๆๅ็ฉๆธ้
    ownerAnimalCount[_to] = ownerAnimalCount[_to].add(1);
    //ๆธๅฐ่ฝๅบ่็ๆๆๅ็ฉๆธ้
    ownerAnimalCount[msg.sender] = ownerAnimalCount[msg.sender].sub(1);
    //ๅ็ฉๆๆๆฌ่ฝ็งป
    animalToOwner[_tokenId] == _to;
    
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

    ownerAnimalCount[msg.sender] = ownerAnimalCount[msg.sender].add(1);
    ownerAnimalCount[owner] = ownerAnimalCount[owner].sub(1);
    animalToOwner[_tokenId] = msg.sender;
    
    emit Take(msg.sender, owner, _tokenId);
  }
  
  function createAnimal() public payable{

       bytes32 dna;
       uint star;
       uint roletype;
      
      require(msg.value == 0.01 ether);
      
      //ไฝฟ็จไบๆธไพ็ข็DNA, ๆ็ด, ๅ็ฉ็จฎ้ก
      dna = keccak256(abi.encodePacked(block.coinbase,blockhash(block.number-1)));
      
      star = uint(dna) % 5 + 1;
      
      roletype = uint(dna) % 100 + 1;
       
      uint id = animals.push(animal(dna, uint8(star), uint8(roletype))) - 1;
      animalToOwner[id] = msg.sender;
      ownerAnimalCount[msg.sender]++;
 
  }
  
}