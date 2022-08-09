// SPDX-License-Identifier: MIT
/***
 *  
 *  8""""8                      
 *  8      eeeee ee   e eeee    
 *  8eeeee 8   8 88   8 8       
 *      88 8eee8 88  e8 8eee    
 *  e   88 88  8  8  8  88      
 *  8eee88 88  8  8ee8  88ee    
 *  ""8""                       
 *    8   e   e eeee            
 *    8e  8   8 8               
 *    88  8eee8 8eee            
 *    88  88  8 88              
 *    88  88  8 88ee            
 *  8""""8                      
 *  8    8 eeeee eeeee eeee     
 *  8e   8 8   8   8   8        
 *  88   8 8eee8   8e  8eee     
 *  88   8 88  8   88  88       
 *  88eee8 88  8   88  88ee     
 *  
 */
pragma solidity >=0.8.9 <0.9.0;

import './IERC721.sol';
import './Ownable.sol';
import './MerkleProof.sol';
import './ReentrancyGuard.sol';
import './Strings.sol';
import './IERC721Receiver.sol';


contract RefundContract is Ownable, ReentrancyGuard, IERC721Receiver {
  using Strings for uint256;
  using Strings for address;

  event DateRefunded(address owner, uint256 tokenId);

    bytes32 public merkleRoot;
    bool public paused = true;
    uint256 public refundPrice = 0.07 ether;
    address public rewardsContractAddress;
    mapping(uint256 => bool) public claimedRewardTokens;

    IERC721 saveTheDateContract;

    constructor(address _saveTheDateContract) {
      saveTheDateContract = IERC721(_saveTheDateContract);
    }

  function refund(uint256 _tokenId, bytes32[] calldata _merkleProof) public nonReentrant {
    require(!paused, 'The contract is paused!');
    verifyWhitelistRequirements(_tokenId, _merkleProof);
    require(!claimedRewardTokens[_tokenId], 'Token claimed reward already');
    address _owner = saveTheDateContract.ownerOf(_tokenId);
    require(_owner == msg.sender, "Must be an owner to get refund");
    saveTheDateContract.transferFrom(msg.sender, address(this), _tokenId);
    payable(msg.sender).transfer(refundPrice);
    emit DateRefunded(_owner, _tokenId);
    delete _owner;
  }

  function claimReward(uint256 _tokenId) public {
    require(rewardsContractAddress == msg.sender, "Must be rewardsContractAddress to mark the token as claimed");
    claimedRewardTokens[_tokenId] = true;
  }

  function claimRewards(uint256[] calldata _tokenIds) public {
    require(rewardsContractAddress == msg.sender, "Must be rewardsContractAddress to mark the token as claimed");
    for (uint256 i = 0; i < _tokenIds.length; i++) {
      claimedRewardTokens[_tokenIds[i]] = true;
    }
  }

  function verifyWhitelistRequirements(uint256 _tokenId, bytes32[] calldata _merkleProof) public view { 
    bytes32 leaf = keccak256(buildMerkleLeaf(_tokenId));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid proof!');
  }

  function deposit() public payable onlyOwner {
  }

  function setSaveTheDateContract(address _contractAddress) public onlyOwner {
    saveTheDateContract = IERC721(_contractAddress);
  }

  function setRewardsContractAddress(address _rewardsContractAddress) public onlyOwner {
    rewardsContractAddress = _rewardsContractAddress;
  }

  function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
  }

  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

  function setRefundPrice(uint256 _refundPrice) public onlyOwner {
    refundPrice = _refundPrice;
  }

  function withdraw() public onlyOwner nonReentrant {
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
  }

  function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4)
    {
      return bytes4(keccak256("onERC721Received(address,uint256,bytes)"));
    }

  function buildMerkleLeaf(uint256 _tokenId) internal view returns(bytes memory){ 
    return abi.encodePacked(_msgSender().toString(), "-", _tokenId.toString());
  }
}