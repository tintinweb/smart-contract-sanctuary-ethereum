/**
 *Submitted for verification at Etherscan.io on 2021-05-19
*/

pragma solidity ^0.4.19;

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
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}



contract animalMain is  ERC721,Ownable {

  using SafeMath for uint256;
    string public name_ = "BillLtoken";

  struct animal {
    bytes32 dna;
    uint8 star;
    uint16 roletype;
    uint8 gender; // 0=female 1=male
    uint8 ages;
  }

  animal[] public animals;
  string public symbol_ = "BL";

  mapping (uint => address) public animalToOwner; //?????????????????????????????????????????????????????????mapping???????????????????????????
  mapping (address => uint) ownerAnimalCount; //????????????????????????????????????
  mapping (uint => address) animalApprovals; //??? ERC721 ??????????????????????????????

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
    return ownerAnimalCount[_owner]; // ?????????????????????????????? ??????
  }

  function ownerOf(uint256 _tokenId) public view returns (address _owner) {
    return animalToOwner[_tokenId]; // ?????????????????????????????? ?????????
  }

  function checkAllOwner(uint256[] _tokenId, address owner) public view returns (bool) {
    for(uint i=0;i<_tokenId.length;i++){
        if(owner != animalToOwner[_tokenId[i]]){
            return false;   //???????????????????????????????????????????????????????????????
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
  function seeAnimalgender(uint256 _tokenId) public view returns (uint8 gender) {
    return animals[_tokenId].gender;
  }
  function seeAnimalage(uint256 _tokenId) public view returns (uint8 ages) {
    return animals[_tokenId].ages;
  }

  function getAnimalByOwner(address _owner) external view returns(uint[]) { //?????????????????????????????????"??????ID"
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

    //TO DO ?????????require?????????????????????id?????????????????????
    require(animalToOwner[_tokenId]==msg.sender);
    //????????????????????????????????????
    ownerAnimalCount[_to]++;
    //????????????????????????????????????
    ownerAnimalCount[msg.sender]--;
    //?????????????????????
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
   require(animalApprovals[_tokenId] == msg.sender);
   ownerAnimalCount[_to]=ownerAnimalCount[_to].add(1);
   ownerAnimalCount[_from]=ownerAnimalCount[_from].sub(1);
   animalToOwner[_tokenId] = _to;
    
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
  
  function random() private view returns(bytes32){
         bytes32 result = keccak256(abi.encodePacked(block.coinbase, blockhash(block.number-1), msg.sender));
         return result;
    }
  
  function createAnimal() public payable {
    require( msg.value  ==  100 wei );
    
       bytes32 dna;
       uint star;
       uint roletype;
       uint gender;
       uint ages;
       
      //TO DO 
      //?????????????????????DNA, ??????, ????????????
      
      //??????????????????????????????????????????????????????????????????ETH
      
      dna = random();
      uint ram = uint(random()) % 100;
      if(ram<40){
          star = 1;
      }
      else if(ram<65){
          star = 2;
      }
      else if(ram<85){
          star = 3;
      }
      else if(ram<95){
          star = 4;
      }else{
          star=5;
      }
      roletype = uint(random()) % 4+1;
      gender = uint(random()) % 2+1;
      ages = uint(random()) % 100;
       
      uint id = animals.push(animal(dna, uint8(star), uint8(roletype),uint8(gender),uint8(ages))) - 1;
      animalToOwner[id] = msg.sender;
      ownerAnimalCount[msg.sender]++;
 
  }
  
}