/**
 *Submitted for verification at Etherscan.io on 2022-03-21
*/

// File: contracts/utils/Ownable.sol

pragma solidity >=0.4.21 <0.6.0;

contract Ownable {
    address private _contract_owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = msg.sender;
        _contract_owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _contract_owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_contract_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_contract_owner, newOwner);
        _contract_owner = newOwner;
    }
}

// File: contracts/TrustListTools.sol

pragma solidity >=0.4.21 <0.6.0;


contract TrustListInterface{
  function is_trusted(address addr) public returns(bool);
}
contract TrustListTools is Ownable{
  TrustListInterface public trustlist;

  modifier is_trusted(address addr){
    require(trustlist != TrustListInterface(0x0), "trustlist is 0x0");
    require(trustlist.is_trusted(addr), "not a trusted issuer");
    _;
  }

  event ChangeTrustList(address _old, address _new);
  function changeTrustList(address _addr) public onlyOwner{
    address old = address(trustlist);
    trustlist = TrustListInterface(_addr);
    emit ChangeTrustList(old, _addr);
  }

}

// File: contracts/utils/SafeMath.sol

pragma solidity >=0.4.21 <0.6.0;

library SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a, "add");
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a, "sub");
        c = a - b;
    }
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b, "mul");
    }
    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0, "div");
        c = a / b;
    }
}

// File: contracts/core/HTokenAggregator.sol

pragma solidity >=0.4.21 <0.6.0;



contract HTokenAggregator is TrustListTools{
    using SafeMath for uint256;
    mapping (bytes32 => uint256) public balance;
    mapping (bytes32 => uint256) public total_supply;
    mapping (bytes32 => uint256) public ratio_to_target;

    mapping (uint256 => string) public types;
    constructor() public{
        types[1] = "horizon_in";
        types[2] = "horizon_out";
        types[3] = "horizon_long";
    }
    function mint(address gk, uint256 round, uint256 ratio, uint256 _type, uint256 amount, address recv) public is_trusted(msg.sender){
        bytes32 hash_ = keccak256(abi.encodePacked(gk, round, ratio, types[_type], recv));
        balance[hash_] = balance[hash_].safeAdd(amount);
        hash_ =  keccak256(abi.encodePacked(gk, round, ratio, types[_type]));
        total_supply[hash_] = total_supply[hash_].safeAdd(amount);
    }
    function burn(address gk, uint256 round, uint256 ratio, uint256 _type, uint256 amount, address recv) public is_trusted(msg.sender){
        bytes32 hash_ = keccak256(abi.encodePacked(gk, round, ratio, types[_type], recv));
        require(balance[hash_] >= amount, "not enough balance");
        balance[hash_] = balance[hash_].safeSub(amount);       
        hash_ =  keccak256(abi.encodePacked(gk, round, ratio, types[_type]));
        total_supply[hash_] = total_supply[hash_].safeSub(amount);
    }
    function balanceOf(address gk, uint256 round, uint256 ratio, uint256 _type, address recv) public view returns(uint256){
        bytes32 hash_ = keccak256(abi.encodePacked(gk, round, ratio, types[_type], recv));
        return balance[hash_];
    }
    function totalSupply(address gk, uint256 round, uint256 ratio, uint256 _type) public view returns(uint256){
        bytes32 hash_ = keccak256(abi.encodePacked(gk, round, ratio, types[_type]));
        return total_supply[hash_];
    }
    function getRatioTo(address gk, uint256 round, uint256 ratio, uint256 _type) public view returns(uint256){
        bytes32 hash_ = keccak256(abi.encodePacked(gk, round, ratio, types[_type]));
        return ratio_to_target[hash_];
    }
    function setRatioTo(address gk, uint256 round, uint256 ratio, uint256 _type, uint256 ratio_to) public is_trusted(msg.sender){
        bytes32 hash_ = keccak256(abi.encodePacked(gk, round, ratio, types[_type]));
        ratio_to_target[hash_] = ratio_to;
    }
}

contract HTokenAggregatorFactory{
  event NewHTokenAggregator(address addr);

  function createHTokenAggregator() public returns(address){
      HTokenAggregator dis = new HTokenAggregator();
      dis.transferOwnership(msg.sender);
      emit NewHTokenAggregator(address(dis));
      return address(dis);
  }
}