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

contract polynetwork is MerkleProof, Ownable{

    using SafeMath for uint256;

    uint256 public MAX_SUPPLY = 227*10**18;

    uint256 public FIRST_SUPPLY = 11111*10**18;

    uint256 public SECOND_SUPPLY = 6666*10**18;

    uint256 public THIRD_SUPPLY = 3333*10**18;

    uint256 public TWITTER_SUPPLY = 1333*10**18;

    uint256 public DC_SUPPLY = 1333*10**18;

    uint256 public TG_SUPPLY = 1777*10**18;

    uint256 public FIRST_FIRST_SUPPLY = 50000*10**18;

    uint256 public FIRST_SECOND_SUPPLY = 30000*10**18;

    uint256 public FIRST_THIRD_SUPPLY = 15000*10**18;

    mapping(address => uint256) public CLAIM_COUNT;

    uint256 amount = 95*10**17;

    uint256 first_amount = 4630*10**17;

    uint256 second_amount = 2778*10**17;

    uint256 third_amount = 1389*10**17;

    uint256 twitter_amount = 555*10**17;

    uint256 dc_amount = 555*10**17;

    uint256 tg_amount = 740*10**17;

    uint256 first_first_amount = 20833*10**17;

    uint256 first_second_amount = 12500*10**17;

    uint256 first_third_amount = 6250*10**17;

    bytes32 root;

    address public IsekaiAddress;

    uint256 startTime;

    address first;

    address second;
    
    address third;

    address first_first;

    address first_second;
    
    address first_third;

    mapping(address => bool) public DCAddress;

    mapping(address => bool) public TGAddress;

    mapping(address => bool) public TWITTERAddress;

    constructor (bytes32 _root,address _IsekaiAddress,uint256 _startTime,
    address[5] memory _DCAddress,address[5] memory _TGAddress,address[5] memory _TWITTERAddress) {
        root = _root;
        IsekaiAddress = _IsekaiAddress;
        startTime = _startTime;
        for(uint i=0; i<_DCAddress.length;i++){
            DCAddress[_DCAddress[i]] = true;
        }
        for(uint i=0; i<_TGAddress.length;i++){
            TGAddress[_TGAddress[i]] = true;
        }
        for(uint i=0; i<_TWITTERAddress.length;i++){
            TWITTERAddress[_TWITTERAddress[i]] = true;
        }
    }

    function setFirstAddress(address _firstAddress) public onlyOwner{
        first = _firstAddress;
    }
    function setSecondAddress(address _secondAddress) public onlyOwner{
        first = _secondAddress;
    }
    function setThirdAddress(address _thirdAddress) public onlyOwner{
        first = _thirdAddress;
    }

    function setFirstFirstAddress(address _firstAddress) public onlyOwner{
        first_first = _firstAddress;
    }
    function setFirstSecondAddress(address _secondAddress) public onlyOwner{
        first_second = _secondAddress;
    }
    function setFirstThirdAddress(address _thirdAddress) public onlyOwner{
        first_third = _thirdAddress;
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
                releaseCount = releaseCount.add(FIRST_SUPPLY);
            }else{
                releaseCount = releaseCount.add(this.getOrder().mul(first_amount));
            }
        }
        if(recipient == second){
            if(this.getOrder() >= 24){
                releaseCount = releaseCount.add(SECOND_SUPPLY);
            }else{
                releaseCount = releaseCount.add(this.getOrder().mul(second_amount));
            }
        }
        if(recipient == third){
            if(this.getOrder() >= 24){
                releaseCount = releaseCount.add(THIRD_SUPPLY);
            }else{
                releaseCount = releaseCount.add(this.getOrder().mul(third_amount));
            }
        }
        if(DCAddress[recipient]){
            if(this.getOrder() >= 24){
                releaseCount = releaseCount.add(DC_SUPPLY);
            }else{
                releaseCount = releaseCount.add(this.getOrder().mul(dc_amount));
            }
        }
        if(TGAddress[recipient]){
            if(this.getOrder() >= 24){
                releaseCount = releaseCount.add(TG_SUPPLY);
            }else{
                releaseCount = releaseCount.add(this.getOrder().mul(tg_amount));
            }
        }
        if(TWITTERAddress[recipient]){
            if(this.getOrder() >= 24){
                releaseCount = releaseCount.add(TWITTER_SUPPLY);
            }else{
                releaseCount = releaseCount.add(this.getOrder().mul(twitter_amount));
            }
        }
        if(recipient == first_first){
            if(this.getOrder() >= 24){
                releaseCount = releaseCount.add(FIRST_FIRST_SUPPLY);
            }else{
                releaseCount = releaseCount.add(this.getOrder().mul(first_first_amount));
            }
        }
        if(recipient == first_second){
            if(this.getOrder() >= 24){
                releaseCount = releaseCount.add(FIRST_SECOND_SUPPLY);
            }else{
                releaseCount = releaseCount.add(this.getOrder().mul(first_second_amount));
            }
        }
        if(recipient == first_third){
            if(this.getOrder() >= 24){
                releaseCount = releaseCount.add(FIRST_THIRD_SUPPLY);
            }else{
                releaseCount = releaseCount.add(this.getOrder().mul(first_third_amount));
            }
        }
        if(releaseCount == 0){
            if(this.getOrder() >= 24){
                releaseCount = releaseCount.add(MAX_SUPPLY);
            }else{
                releaseCount = releaseCount.add(this.getOrder().mul(amount));
            }
        }
        return releaseCount;
    }
    function getMaxSupply(address recipient)public view returns (uint256){
        uint256 supplyCount = 0;
        if(recipient == first){
            supplyCount = supplyCount.add(FIRST_SUPPLY);
        }
        if(recipient == second){
            supplyCount = supplyCount.add(SECOND_SUPPLY);
        }
        if(recipient == third){
            supplyCount = supplyCount.add(THIRD_SUPPLY);
        }
        if(DCAddress[recipient]){
            supplyCount = supplyCount.add(DC_SUPPLY);
        }
        if(TGAddress[recipient]){
            supplyCount = supplyCount.add(TG_SUPPLY);
        }
        if(TWITTERAddress[recipient]){
            supplyCount = supplyCount.add(TWITTER_SUPPLY);
        }
        if(recipient == first_first){
            supplyCount = supplyCount.add(FIRST_FIRST_SUPPLY);
        }
        if(recipient == first_second){
            supplyCount = supplyCount.add(FIRST_SECOND_SUPPLY);
        }
        if(recipient == first_third){
            supplyCount = supplyCount.add(FIRST_THIRD_SUPPLY);
        }
        if(supplyCount == 0){
            supplyCount = supplyCount.add(MAX_SUPPLY);
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
        if(msg.sender == first||msg.sender == second||msg.sender == third||msg.sender == first_first||msg.sender == first_second||msg.sender == third||DCAddress[msg.sender]||TGAddress[msg.sender]||TWITTERAddress[msg.sender]){
            require(block.timestamp>=startTime,"not started");
            require(releaseCount > CLAIM_COUNT[msg.sender], "You have claimed your token");
            // require(claimed[msg.sender] < order, "You have claimed your token");
            isekai(IsekaiAddress).transfer(msg.sender,releaseCount.sub(CLAIM_COUNT[msg.sender]));
            CLAIM_COUNT[msg.sender] = releaseCount;
        }else{
            require(block.timestamp>=startTime,"not started");
            require(releaseCount > CLAIM_COUNT[msg.sender], "You have claimed your token");
            // require(claimed[msg.sender] < order, "You have claimed your token");
            bytes32 result = keccak256(abi.encodePacked(msg.sender));
            require(verify(proof, root, result), "You are not on the list");
            isekai(IsekaiAddress).transfer(msg.sender,releaseCount.sub(CLAIM_COUNT[msg.sender]));
            CLAIM_COUNT[msg.sender] = releaseCount;
        }
    }
}