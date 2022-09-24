/**
 *Submitted for verification at Etherscan.io on 2022-09-24
*/

/**
 *Submitted for verification at hecoinfo.com on 2022-06-24
*/

pragma solidity ^0.5.17;


interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract Ownable {
  address payable public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  modifier onlyOwner() {
    require(msg.sender == owner,'Must contract owner');
    _;
  }

  function transferOwnership(address payable newOwner) public onlyOwner {
    require(newOwner != address(0),'Must contract owner');
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

library SafeMath {


  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }


  function div(uint256 a, uint256 b) internal pure returns (uint256) {

    uint256 c = a / b;

    return c;
  }


  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract NftFactory is Ownable {

  using SafeMath for uint256;

  event NewNft(uint nftId, string name, uint dna);

  uint dnaDigits = 16;
  uint dnaModulus = 10 ** dnaDigits;
  uint public cooldownTime = 1 days;
  uint public nftPrice = 16;
  uint public nftCount = 0;
  IERC20 usdt;
  uint256 public decimals;

  address private admin = address(0xd6F9FFb06834692A67A8c7A88a6F06c403a2dE89);

  struct Nft {
    string name;
    string url;
    uint dna;
    uint types;//1。url_nft/2。dan_nft
    uint32 level;
    uint32 readyTime;
  }

  Nft[] public nfts;

  mapping (uint => address) public nftToOwner;
  mapping (address => uint) ownerNftCount;
  mapping (uint => uint) public nftFeedTimes;

  function _createNft(string memory _name,string memory _url, uint _dna,uint _types,uint32 _level) internal {
    uint id = nfts.push(Nft(_name, _url, _dna, _types, _level, 0)) - 1;
    nftToOwner[id] = msg.sender;
    ownerNftCount[msg.sender] = ownerNftCount[msg.sender].add(1);
    nftCount = nftCount.add(1);
    emit NewNft(id, _name, _dna);
  }
  function _createNftAdmin(string memory _name,string memory _url, uint _dna,uint _types,uint32 _level,address _user) internal {
    uint id = nfts.push(Nft(_name, _url, _dna, _types, _level, 0)) - 1;
    nftToOwner[id] = _user;
    ownerNftCount[_user] = ownerNftCount[_user].add(1);
    nftCount = nftCount.add(1);
    emit NewNft(id, _name, _dna);
  }

  function _generateRandomDna(string memory _str) private view returns (uint) {
    return uint(keccak256(abi.encodePacked(_str,now))) % dnaModulus;
  }

  function createUrlNftAdmin(string memory _name,string memory url,uint32 _level,address _user) public {
    require(msg.sender == admin,"you are not admin");
    _createNftAdmin(_name, url, 0, 1, _level,_user);
  }

  function createDnaNftAdmin(string memory _name,uint32 _level,address _user) public{
    require(msg.sender == admin,"you are not admin");
    uint randDna = _generateRandomDna(_name);
    randDna = randDna - randDna % 10;
    _createNftAdmin(_name, '', randDna, 2, _level,_user);
  }


  function createUrlNftUser(string memory _name,string memory url,uint32 _level) public{
    require(usdt.balanceOf(msg.sender)>=nftPrice*10**decimals,"Token balance too low");
    usdt.transferFrom(msg.sender,address(this), nftPrice*10**decimals);
    _createNft(_name, url, 0, 1, _level);
  }

  function createDnaNftUser(string memory _name,uint32 _level) public{
    require(usdt.balanceOf(msg.sender)>=nftPrice*10**decimals,"Token balance too low");
    usdt.transferFrom(msg.sender,address(this), nftPrice*10**decimals);
    uint randDna = _generateRandomDna(_name);
    randDna = randDna - randDna % 10;
    _createNft(_name, '', randDna, 2, _level);
  }




  function setNftPrice(uint _price) external onlyOwner {
    nftPrice = _price;
  }

   function setadminaddress(address address3) public onlyOwner(){
        admin = address3;
    }
  function setusdtaddress(IERC20 address3,uint256 _decimals) public onlyOwner(){
        usdt = address3;
        decimals=_decimals;
    }

    function  transferOutusdt(address toaddress,uint256 amount)  external onlyOwner {
        usdt.transfer(toaddress, amount);
    }

}
contract NftHelper is NftFactory {

  uint public levelUpFee = 0.001 ether;

  modifier aboveLevel(uint _level, uint _zombieId) {
    require(nfts[_zombieId].level >= _level,'Level is not sufficient');
    _;
  }
  modifier onlyOwnerOf(uint _zombieId) {
    require(msg.sender == nftToOwner[_zombieId],'Zombie is not yours');
    _;
  }
  

  function changeName(uint _Id, string calldata _newName) external  aboveLevel(2, _Id) onlyOwnerOf(_Id) {
    nfts[_Id].name = _newName;
  }

  function getNftByOwner(address  _owner) external view returns(uint[] memory) {
    uint[] memory result = new uint[](ownerNftCount[_owner]);
    uint counter = 0;
    for (uint i = 0; i < nfts.length; i++) {
      if (nftToOwner[i] == _owner) {
        result[counter] = i;
        counter++;
      }
    }
    return result;
  }

}




contract ERC721 {
  event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);

  function balanceOf(address _owner) public view returns (uint256 _balance);
  function ownerOf(uint256 _tokenId) public view returns (address _owner);
  function transfer(address _to, uint256 _tokenId) public;
  function approve(address _to, uint256 _tokenId) public;
  function takeOwnership(uint256 _tokenId) public;
}

contract NftOwnership is NftHelper, ERC721 {

  mapping (uint => address) zombieApprovals;

  function balanceOf(address _owner) public view returns (uint256 _balance) {
    return ownerNftCount[_owner];
  }

  function ownerOf(uint256 _tokenId) public view returns (address _owner) {
    return nftToOwner[_tokenId];
  }

  function _transfer(address _from, address _to, uint256 _tokenId) internal {
    ownerNftCount[_to] = ownerNftCount[_to].add(1);
    ownerNftCount[_from] = ownerNftCount[_from].sub(1);
    nftToOwner[_tokenId] = _to;
    emit Transfer(_from, _to, _tokenId);
  }

  function transfer(address _to, uint256 _tokenId) public onlyOwnerOf(_tokenId) {
    _transfer(msg.sender, _to, _tokenId);
  }

  function approve(address _to, uint256 _tokenId) public onlyOwnerOf(_tokenId) {
    zombieApprovals[_tokenId] = _to;
    emit Approval(msg.sender, _to, _tokenId);
  }

  function takeOwnership(uint256 _tokenId) public {
    require(zombieApprovals[_tokenId] == msg.sender);
    address owner = ownerOf(_tokenId);
    _transfer(owner, msg.sender, _tokenId);
  }
}


contract NftMarket is NftOwnership {
    struct nftSales{
        address payable seller;
        uint price;
    }
    mapping(uint=>nftSales) public nftShop;
    uint shopNftCount;


    event SaleNft(uint indexed zombieId,address indexed seller);
    event BuyShopZombie(uint indexed zombieId,address indexed buyer,address indexed seller);

    function saleMyNft(uint _Id,uint _price)public onlyOwnerOf(_Id){
        uint _yesno=getShopNftyesno(_Id);
        require(_yesno==0,"is selling");
        nftShop[_Id] = nftSales(msg.sender,_price);
        shopNftCount = shopNftCount.add(1);
        emit SaleNft(_Id,msg.sender);
    }
    function buyShopNft(uint _nftId)public {
        uint _yesno=getShopNftyesno(_nftId);
        require(_yesno==1,"is not selling");
       
        require(nftShop[_nftId].seller!=msg.sender,"buy can not myself");
        require(usdt.balanceOf(msg.sender)>=nftShop[_nftId].price*10**decimals,"Token balance too low");
        usdt.transferFrom(msg.sender,nftShop[_nftId].seller,nftShop[_nftId].price*10**decimals);
        _transfer(nftShop[_nftId].seller,msg.sender, _nftId);
        delete nftShop[_nftId];
        shopNftCount = shopNftCount.sub(1);
        emit BuyShopZombie(_nftId,msg.sender,nftShop[_nftId].seller);
    }
    function getShopNfts() external view returns(uint[] memory) {
        uint[] memory result = new uint[](shopNftCount);
        uint counter = 0;
        for (uint i = 0; i < nfts.length; i++) {
            if (nftShop[i].price != 0) {
                result[counter] = i;
                counter++;
            }
        }
        return result;
    }

    
    function getShopNftyesno(uint _Id) public view returns(uint yesno) {
        
        uint counter = 0;
        for (uint i = 0; i < nfts.length; i++) {
            if (nftShop[i].price != 0 && i==_Id) {
                counter=1;
                break;
            }
        }
        return counter;
    }


}



contract NftCore is NftMarket {

    string public constant name = "HbobNft";
    string public constant symbol = "HbobNft";

    
    constructor(IERC20 _usdt,uint256 _decimals) public {
      
        usdt=_usdt;
        decimals=_decimals;
        owner = msg.sender;
    }

    function() external payable {
    }

    function withdraw() external onlyOwner {
        owner.transfer(address(this).balance);
    }

    function checkBalance() external view onlyOwner returns(uint) {
        return address(this).balance;
    }

}