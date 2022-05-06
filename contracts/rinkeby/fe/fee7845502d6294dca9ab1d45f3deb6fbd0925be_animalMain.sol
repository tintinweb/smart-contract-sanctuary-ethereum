/**
 *Submitted for verification at Etherscan.io on 2022-05-06
*/

/**
 *Submitted for verification at Etherscan.io on 2021-06-22
*/

pragma solidity ^0.4.19;

//此合約為 hahow 零基礎邁向區塊鏈工程師：Solidity 智能合約 課程 作業二範 ERC721 範本智能合約

//做作業方式：
//老師已經完成合約75%，剩下關鍵的方法需要各位同學自行填空，發揮創意。

//做作業關鍵：
//1. 先搞懂ERC721與ERC20的差異，你就會搞懂這些功能為什麼要這樣設計
//ERC20  每個幣種之間相同 
//ERC721 個幣種之間具有獨特性 ex.NFT

//2. 請直接搜尋 TO DO 找出要完成的地方


//erc721的介面
contract ERC721 {
  event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

  function totalSupply() public view returns (uint256 total);  //發行總量
  function balanceOf(address _owner) public view returns (uint256 _balance); //計算此地址下有多少token
  function ownerOf(uint256 _tokenId) public view returns (address _owner);  //**給予tokenID 回傳持有者（與ERC20不同）
  function transfer(address _to, uint256 _tokenId) public; //＊＊一次只能給予一持有者一個token（與ERC20不同）
  function approve(address _to, uint256 _tokenId) public; //成功approve容許_spender 從 _owner錢包中提取代幣
  function transferFrom(address _from, address _to, uint256 _tokenId) external;
  function name() external view returns (string _name);
  function symbol() external view returns (string _symbol);
}

/**
 * @title SafeMath   SafeMath庫來防止溢出問題
 * @dev Math operations with safety checks that throw on error
 */
//SafeMath 合約安全增強解決上溢出與下溢出 ex: uint256 上溢出（overflow）2^256  下溢出（underflow） 0-1
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;      //上溢出（overflow）
    assert(c / a == b);     //使用了assert，之前驗證使用的是require 
    return c;               //assert 和 require 區別在，require 若失敗則會返還給用戶剩下的gas， assert 則不會。
                            //所以大部分情況下，寫程式較常使用 require，assert 只在程式可能出現嚴重錯誤的時候使用，比如 uint 溢出。
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
 //Ownable 合約提供 owner 地址 以及基本的 授權控制
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
    string public name_ = "anitoken";
    
    struct animal {
        bytes32 dna; // DNA
        uint8 star; // 幾星級(抽卡的概念)
        string roletype; // 哪種動物
    }
    
    animal[] public animals;
    string public symbol_ = "ANI";
    
    mapping (uint => address) public animalToOwner; //每隻動物都有一個獨一無二的編號，呼叫此mapping，得到相對應的主人
    mapping (address => uint) ownerAnimalCount; //回傳某帳號底下的動物數量
    mapping (uint => address) animalApprovals; //和 ERC721 一樣，是否同意被轉走
    
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _from, address indexed _to,uint indexed _tokenId);
    event Take(address _to, address _from,uint _tokenId);
    event Create(uint _tokenId, bytes32 dna,uint8 star, string roletype);

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
    
    function seeAnimalRole(uint256 _tokenId) public view returns (string roletype) {
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
        require(msg.sender == animalToOwner[_tokenId]);
        
        //增加受贈者的擁有動物數量
        ownerAnimalCount[_to] = ownerAnimalCount[_to].add(1);
        //減少轉出者的擁有動物數量
        ownerAnimalCount[msg.sender] = ownerAnimalCount[msg.sender].sub(1);
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
        require(animalApprovals[_tokenId] == msg.sender);
        
        address owner = ownerOf(_tokenId);
        
        ownerAnimalCount[msg.sender] = ownerAnimalCount[msg.sender].add(1);
        ownerAnimalCount[owner] = ownerAnimalCount[owner].sub(1);
        animalToOwner[_tokenId] = msg.sender;
        
        emit Take(msg.sender, owner, _tokenId);
    }
  
    function createAnimal() public payable{
        require(msg.value >= 0.01 ether, "Create an animal needs 0.01 ether.");    
        bytes32 _dna;
        uint8 _star;
        string memory _animaltype;
        
        
        
        //TO DO 
        //使用亂數來產生DNA, 星級, 動物種類
        _dna = bytes32(keccak256(abi.encode(now, block.coinbase, msg.sender)));
        
        // determine star
        uint rand = uint(keccak256(abi.encode(now, block.coinbase, msg.sender)))%100; //進行亂數分割
        if(rand<30) _star = 1;      
        else if (rand<50) _star = 2;
        else if (rand<80) _star = 3;
        else if (rand<90) _star = 4;
        else _star = 1;
        
        // determine animal
        rand = uint(keccak256(abi.encode(block.timestamp,block.difficulty, block.coinbase)))%100;
        if(rand<40) _animaltype = "Ant";
        else if (rand<50) _animaltype = "Cat";
        else if (rand<80) _animaltype = "Dog";
        else if (rand<90) _animaltype = "Dragon";
        else _animaltype = "Ant";
           
        uint id = animals.push(animal(_dna, uint8(_star), _animaltype)) - 1;  //將此animal的數量
        animalToOwner[id] = msg.sender; // 每隻動物都有一個獨特編號，呼叫mapping，得到相對應的主人 轉移擁有權 
        ownerAnimalCount[msg.sender]++; //回傳某帳號底下的動物數量  擁有者的個數＋1
        emit Create(id, _dna, _star, _animaltype);
    }
  
}