/**
 *Submitted for verification at Etherscan.io on 2023-01-17
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library SafeMath {
    function add(uint256 a,uint256 b) internal pure returns (uint256) {
        uint256 c = a+b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a,uint256 b) internal pure returns (uint256){
        require( b <= a,"SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a,uint256 b) internal pure returns (uint256) {
        if(a == 0) {
            return 0;
        }
        uint256 c = a*b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;        
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // return div(a,b,"SafeMath: division by zero");
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modu by zero");
        return a % b;
    }
}


contract MerkleProof {
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }
    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        _transferOwnership(_msgSender());
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface isekai {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract cwallet is MerkleProof, Ownable{

    using SafeMath for uint256;

    uint256 public MAX_SUPPLY = 2312*10**17;

    uint256 public FIRST_SUPPLY = 11111*10**18;

    uint256 public SECOND_SUPPLY = 6666*10**18;

    uint256 public THIRD_SUPPLY = 3333*10**18;


    mapping(address => uint256) public CLAIM_COUNT;

    uint256 amount = 96*10**17;

    uint256 first_amount = 4630*10**17;

    uint256 second_amount = 2778*10**17;

    uint256 third_amount = 1389*10**17;    

    bytes32 root;

    address public IsekaiAddress;

    mapping(address => uint256) public claimed;

    uint256 startTime;

    address first;

    address second;
    
    address third;


    constructor (bytes32 _root,address _IsekaiAddress,uint256 _startTime) {
        root = _root;
        IsekaiAddress = _IsekaiAddress;
        startTime = _startTime;
    }


    function setFirstAddress(address _firstAddress) public onlyOwner{
        first = _firstAddress;
    }
    function setSecondAddress(address _secondAddress) public onlyOwner{
        second = _secondAddress;
    }
    function setThirdAddress(address _thirdAddress) public onlyOwner{
        third = _thirdAddress;
    }
    function setMerkleRoot(bytes32 _root) public onlyOwner{
        root = _root;
    }
    function setAmount(uint256 _amount) public onlyOwner{
        amount = _amount;
    }
    function setLsekaiAddress(address _IsekaiAddress) public onlyOwner{
        IsekaiAddress = _IsekaiAddress;
    }
    function setMaxSupply(uint256 _maxSupply) public onlyOwner{
        MAX_SUPPLY = _maxSupply;
    }
    function setStartTime(uint256 _startTime)public onlyOwner{
        startTime = _startTime;
    }
    function RELEASE_SUPPLY(address recipient) public view returns (uint256){
        uint256 releaseCount = 0;
        if(recipient == first){
            if(this.getOrder() >= 24){
                releaseCount = FIRST_SUPPLY;
            }else{
                releaseCount = this.getOrder().mul(first_amount);
            }
        } else if(recipient == second){
            if(this.getOrder() >= 24){
                releaseCount = SECOND_SUPPLY;
            }else{
                releaseCount = this.getOrder().mul(second_amount);
            }
        } else if(recipient == third){
            if(this.getOrder() >= 24){
                releaseCount = THIRD_SUPPLY;
            }else{
                releaseCount = this.getOrder().mul(third_amount);
            }
        } else{
            if(this.getOrder() >= 24){
                releaseCount = MAX_SUPPLY;
            }else{
                releaseCount = this.getOrder().mul(amount);
            }
        }
        return releaseCount;
    }
    function getMaxSupply()public view returns (uint256){
        uint256 supplyCount = 0;
        if(msg.sender == first){
            supplyCount += FIRST_SUPPLY;
        } else if(msg.sender == second){
            supplyCount += SECOND_SUPPLY;
        } else if(msg.sender == third){
            supplyCount += THIRD_SUPPLY;
        } else{
            supplyCount += MAX_SUPPLY;
        }
        return supplyCount;
    }

    function getBlockTime() public view returns (uint256){
        return block.timestamp;
    }
    function getOrder() external view returns (uint256){ 
        if(block.timestamp>=startTime){
            uint256 order = ((block.timestamp.sub(startTime)).div(60*60*24*30)).add(1);
            if(order>24){
                order = 24;
            }
            return order;
        }else{
            return 0;
        }
    }
    function getFrequency(address recipient) public view returns (bool){
        return (this.RELEASE_SUPPLY(recipient) > CLAIM_COUNT[recipient]);
    }

    function claim(bytes32[] memory proof) external {
        uint256 releaseCount = this.RELEASE_SUPPLY(msg.sender);
        require(block.timestamp>=startTime,"not started");
        require(releaseCount>CLAIM_COUNT[msg.sender], "You have claimed your token");
        // require(claimed[msg.sender] < order, "You have claimed your token");
        bytes32 result = keccak256(abi.encodePacked(msg.sender));
        require(verify(proof, root, result), "You are not on the list");
        isekai(IsekaiAddress).transfer(msg.sender,releaseCount.sub(CLAIM_COUNT[msg.sender]));
        CLAIM_COUNT[msg.sender] = releaseCount;
    }
}