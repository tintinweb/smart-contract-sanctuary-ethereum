/**
 *Submitted for verification at Etherscan.io on 2023-01-11
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

contract isekaiProxy is MerkleProof, Ownable{

    using SafeMath for uint256;

    uint256 public MAX_SUPPLY = 875*10**16*24;

    mapping(address => uint256) public CLAIM_COUNT;

    uint256 amount = 875*10**16;

    bytes32 root;

    address public IsekaiAddress;

    mapping(address => uint256) public claimed;

    uint256 startTime;

    constructor (bytes32 _root,address _IsekaiAddress,uint256 _startTime) {
        root = _root;
        IsekaiAddress = _IsekaiAddress;
        startTime = _startTime;
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
    function RELEASE_SUPPLY() public view returns (uint256){
        return this.getOrder().mul(amount);
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
    function getFrequency(address recipient) public view returns (uint256){
        return this.getOrder().sub(claimed[recipient]);
    }




    function claim(bytes32[] memory proof) external {
        require(block.timestamp>=startTime,"not started");
        uint256 total = CLAIM_COUNT[msg.sender].add(amount);
        uint256 order = this.getOrder();
        require(total<=amount.mul(order), "Exceed release supply");
        require(total <= MAX_SUPPLY, "Exceed max supply");
        require(claimed[msg.sender] < order, "You have claimed your token");
        bytes32 result = keccak256(abi.encodePacked(msg.sender));
        require(verify(proof, root, result), "You are not on the list");
        isekai(IsekaiAddress).transfer(msg.sender,amount.mul(order.sub(claimed[msg.sender])));
        CLAIM_COUNT[msg.sender] = CLAIM_COUNT[msg.sender].add(amount.mul(order.sub(claimed[msg.sender])));
        claimed[msg.sender] = order;
    }
}