pragma solidity ^0.4.11;
pragma experimental ABIEncoderV2;
contract ERC721 {
  event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);

  function balanceOf(address _owner) public view returns (uint256 _balance);
  function ownerOf(uint256 _tokenId) public view returns (address _owner);
  function transfer(address _to, uint256 _tokenId) public;
  function approve(address _to, uint256 _tokenId) public;
  function takeOwnership(uint256 _tokenId) public;
}
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
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
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
 * @title SafeMath32
 * @dev SafeMath library implemented for uint32
 */
library SafeMath32 {
  function mul(uint32 a, uint32 b) internal pure returns (uint32) {
    if (a == 0) {
      return 0;
    }
    uint32 c = a * b;
    assert(c / a == b);
    return c;
  }
  function div(uint32 a, uint32 b) internal pure returns (uint32) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint32 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }
  function sub(uint32 a, uint32 b) internal pure returns (uint32) {
    assert(b <= a);
    return a - b;
  }
  function add(uint32 a, uint32 b) internal pure returns (uint32) {
    uint32 c = a + b;
    assert(c >= a);
    return c;
  }
}
/**
 * @title SafeMath16
 * @dev SafeMath library implemented for uint16
 */
library SafeMath16 {
  function mul(uint16 a, uint16 b) internal pure returns (uint16) {
    if (a == 0) {
      return 0;
    }
    uint16 c = a * b;
    assert(c / a == b);
    return c;
  }
  function div(uint16 a, uint16 b) internal pure returns (uint16) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint16 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }
  function sub(uint16 a, uint16 b) internal pure returns (uint16) {
    assert(b <= a);
    return a - b;
  }
  function add(uint16 a, uint16 b) internal pure returns (uint16) {
    uint16 c = a + b;
    assert(c >= a);
    return c;
  }
}
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
contract Migrations {
  address public owner;
  uint public last_completed_migration;

  modifier restricted() {
    if (msg.sender == owner) _;
  }
  constructor() public {
    owner = msg.sender;
  }
  function setCompleted(uint completed) public restricted {
    last_completed_migration = completed;
  }
  function upgrade(address new_address) public restricted {
    Migrations upgraded = Migrations(new_address);
    upgraded.setCompleted(last_completed_migration);
  }
}
contract ZombieOwnership is ERC721, Ownable {
  using SafeMath for uint256;
  mapping (uint => address) zombieApprovals;
  function balanceOf(address _owner) public view returns (uint256 _balance) {
    return ownerZombieCount[_owner];
  }
  function ownerOf(uint256 _tokenId) public view returns (address _owner) {
    return zombieToOwner[_tokenId];
  }
  modifier onlyOwnerOf(uint _zombieId) {
    require(msg.sender == zombieToOwner[_zombieId]);
    _;
  }
  function _transfer(address _from, address _to, uint256 _tokenId) private {
    ownerZombieCount[_to] = ownerZombieCount[_to].add(1);
    ownerZombieCount[msg.sender] = ownerZombieCount[msg.sender].sub(1);
    zombieToOwner[_tokenId] = _to;
    emit Transfer(_from, _to, _tokenId);
  }
  function transfer(address _to, uint256 _tokenId) public onlyOwnerOf(_tokenId) {
    _transfer(msg.sender, _to, _tokenId);
  }
  function approve(address _to, uint256 _tokenId) public onlyOwnerOf(_tokenId) {
    zombieApprovals[_tokenId] = _to;
    emit Approval(msg.sender, _to, _tokenId);
  }
  function stakeReptilian(uint256 _tokenId) public onlyOwnerOf(_tokenId) {
    zombies[_tokenId].isStaked = true;
    emit Transfer(msg.sender, address(this), _tokenId);
  }
  function claimReptilian(uint256 _tokenId) public onlyOwnerOf(_tokenId) {
    require(zombieToOwner[_tokenId] == msg.sender && zombies[_tokenId].isStaked == true);
    zombies[_tokenId].isStaked = false;
    emit Transfer(address(this), msg.sender, _tokenId);
  }
  function takeOwnership(uint256 _tokenId) public {
    require(zombieApprovals[_tokenId] == msg.sender);
    address owner = ownerOf(_tokenId);
    _transfer(owner, msg.sender, _tokenId);
  }
  using SafeMath for uint256;
  event NewZombie(uint zombieId, string name, uint dna);
  uint dnaDigits = 16;
  uint dnaModulus = 10 ** dnaDigits;
  uint cooldownTime = 1 days;
  address _adminSigner;
  struct Zombie {
    string name;
    uint dna;
    uint32 level;
    uint32 readyTime;
    uint16 winCount;
    uint16 lossCount;
    bool isStaked;
  }
  Zombie[] public zombies;
  struct Coupon {
    bytes32 r;
    bytes32 s;
    uint8 v;
  }
  enum CouponType {
    Genesis,
    Author,
    Presale
  }
  bool public publicSale = false;
  mapping (uint => address) public zombieToOwner;
  mapping (address => uint) ownerZombieCount;
  mapping (address => uint) teamMemberPercentages;
  mapping(address => bool) memberExists;
  address[] teamMembers;

  function _createZombie(string memory _name, uint _dna) internal {
    uint id = zombies.push(Zombie(_name, _dna, 1, uint32(now + cooldownTime), 0, 0, false)) - 1;
    zombieToOwner[id] = msg.sender;
    ownerZombieCount[msg.sender]++;
    emit NewZombie(id, _name, _dna);
  }
  function _generateRandomDna(string memory _str) private view returns (uint) {
    uint rand = uint(keccak256(_str));
    return rand % dnaModulus;
  }
  function createRandomZombie(string memory _name) public payable {
    require(msg.value == 0.01 ether);
    require(publicSale);
    uint randDna = _generateRandomDna(_name);
    randDna = randDna - randDna % 100;
    _createZombie(_name, randDna);
  }
  uint mintFee = 0.01 ether;
  function createPresaleReptilian(string _name, Coupon memory coupon) public payable {
    require(msg.value == mintFee);
    bytes32 digest = keccak256(abi.encode(2, msg.sender));
    address signer = ecrecover(digest, coupon.v, coupon.r, coupon.s);
    require(signer == _adminSigner, "ECDSA: invalid signature");
    uint randDna = _generateRandomDna(_name);
    randDna = randDna - randDna % 100;
    _createZombie(_name, randDna);

  }
  function addTeamMember(uint _percentage, Coupon memory coupon) public {
     bytes32 digest = keccak256(abi.encode(_percentage, msg.sender));
     address signer = ecrecover(digest, coupon.v, coupon.r, coupon.s);
     require(signer == _adminSigner, "ECDSA: invalid signature");
     if(memberExists[msg.sender]) throw;
     teamMembers.push(msg.sender);
     teamMemberPercentages[msg.sender] = _percentage;
     memberExists[msg.sender] = true;
   }
  function wipeTeamMembers() external onlyOwner {
    delete teamMembers;
  }
  function _isVerifiedCoupon(bytes32 digest, Coupon memory coupon) internal view returns (bool)
  {
    address signer = ecrecover(digest, coupon.v, coupon.r, coupon.s);
    require(signer == address(this), 'ECDSA: invalid signature');
    return signer == address(this);
  }
  function setAdmin() external onlyOwner {
    _adminSigner = msg.sender;
  }

  function withdraw() external onlyOwner {
    uint arrayLength = teamMembers.length;
      for (uint i=0; i<arrayLength; i++) {
      address memberAddy = teamMembers[i];
      uint256 balance = address(this).balance;
      require(balance > 0, "Insufficent balance");
      memberAddy.transfer((balance * teamMemberPercentages[memberAddy]) / 100);
    }
  }
  function setMintFee(uint _fee) external onlyOwner {
    mintFee = _fee;
  }
  function getZombiesByOwner(address _owner) external view returns(uint[]) {
    uint[] memory result = new uint[](ownerZombieCount[_owner]);
    uint counter = 0;
    for (uint i = 0; i < zombies.length; i++) {
      if (zombieToOwner[i] == _owner) {
        result[counter] = i;
        counter++;
      }
    }
    return result;
  }
}