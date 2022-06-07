// SPDX-License-Identifier: MIT
import "../interfaces/IFeeManagerProxy.sol";

pragma solidity 0.8.13;

contract CallProxy {

  IFeeManager public feeManager;
  address public owner;

  struct CommunityFee {
    address nftAddr;
    address[] tokenAddrs;
    uint256[] feeAmounts;
  }

  struct CollectionFee {
    address nftAddr;
    uint256 tokenID;
    address[] tokenAddrs;
    uint256[] feeAmounts;
    uint256[] claimedAmounts;
    uint256[] feePerNFT;
    uint256[] accumulatedFeeAmount;
  }

  struct AllCollectionFee {
    address nftAddr;
    uint256[] tokenID;
    address[][] tokenAddrs;
    uint256[][] feeAmounts;
    uint256[][] claimedAmounts;
    uint256[][] feePerNFT;
    uint256[][] accumulatedFeeAmount;
  }

  modifier onlyOwner() {
    require(owner == msg.sender, "Ownable: caller is not the owner");
    _;
  }

  constructor(address _feeManagerAddr) {
    feeManager = IFeeManager(_feeManagerAddr);
    owner = msg.sender;
  }

  function setFeeManager(address _feeManagerAddr) external onlyOwner {
    feeManager = IFeeManager(_feeManagerAddr);
  }
  
  function setOwner(address _owner) external onlyOwner {
    owner = _owner;
  }

  function getAllAccumulatedCommunityFee(address[] memory _nftAddrs, address[][] memory _tokenAddrs) external view returns (CommunityFee[] memory) {
    CommunityFee[] memory communityFee = new CommunityFee[](_nftAddrs.length);

    for(uint256 nftIndex; nftIndex < _nftAddrs.length; nftIndex++){
      address nftAddr = _nftAddrs[nftIndex];
      address[] memory tokensPerNFT = _tokenAddrs[nftIndex];
      uint256[] memory feeAmounts = new uint256[](tokensPerNFT.length);

      for(uint256 tokenIndex; tokenIndex < tokensPerNFT.length; tokenIndex++){
          feeAmounts[tokenIndex] = feeManager.getAccumulatedCommunityFee(nftAddr, tokensPerNFT[tokenIndex]);
      }

      communityFee[nftIndex] = CommunityFee(nftAddr, tokensPerNFT, feeAmounts);
    }

    return communityFee;
  }

  function getCollectionFeeAmount(address _nftAddr, address[] memory _tokenAddrs, uint256[] memory _tokenIDs) external view returns (CollectionFee[] memory) {
     CollectionFee[] memory collectionFee = new CollectionFee[](_tokenIDs.length);

    for(uint256 tokenIDIndex; tokenIDIndex < _tokenIDs.length; tokenIDIndex++){
        uint256[] memory _feeAmounts = new uint256[](_tokenAddrs.length);
        uint256[] memory _claimedAmounts = new uint256[](_tokenAddrs.length);
        uint256[] memory _rewardPerNFT = new uint256[](_tokenAddrs.length);
        uint256[] memory _accumulatedFeeAmounts = new uint256[](_tokenAddrs.length);
        uint256 _tokenID = _tokenIDs[tokenIDIndex];

        for(uint256 tokenAddrIndex; tokenAddrIndex < _tokenAddrs.length; tokenAddrIndex++){
            address _tokenAddr = _tokenAddrs[tokenAddrIndex];
            _feeAmounts[tokenAddrIndex] = feeManager.getRewardAmount(_nftAddr, _tokenAddr, _tokenID);
            _claimedAmounts[tokenAddrIndex] = feeManager.getClaimedCommunityFee(_nftAddr, _tokenAddr, _tokenID);
            _rewardPerNFT[tokenAddrIndex]= feeManager.getRewardPerNFT(_nftAddr, _tokenAddr);
            _accumulatedFeeAmounts[tokenAddrIndex] = feeManager.getAccumulatedCommunityFee(_nftAddr, _tokenAddr);
        }

        collectionFee[tokenIDIndex] = CollectionFee(_nftAddr, _tokenID, _tokenAddrs, _feeAmounts, _claimedAmounts, _rewardPerNFT, _accumulatedFeeAmounts);
    }

    return collectionFee;
  }

  function getFeeManagerAddr() external view returns (address){
    return address(feeManager);
  }

  function getOwner() external view returns (address) {
    return owner;
  }

  function getRewardPerNFT(address _nftAddr, address _tokenAddr) external view returns (uint256) {
    return feeManager.getRewardPerNFT(_nftAddr, _tokenAddr);
  }

  function getRewardAmount(address _nftAddr, address _tokenAddr, uint256 _tokenID) external view returns (uint256) {
    return feeManager.getRewardAmount(_nftAddr, _tokenAddr, _tokenID);
  }

  function getClaimedCommunityFee(address _nftAddr, address _tokenAddr, uint256 _tokenID) external view returns (uint256) {
    return feeManager.getClaimedCommunityFee(_nftAddr, _tokenAddr, _tokenID);
  }

  function getAccumulatedCommunityFee(address _nftAddr, address _tokenAddr) external view returns (uint256) {
    return feeManager.getAccumulatedCommunityFee(_nftAddr, _tokenAddr);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IFeeManager {

    function communityFeeUpdate(address nftAddr, address paymentTokenAddr, uint256 cummunityFee) external;

    function feeClaim(address nftAddr, uint256[] memory tokenID, address[] memory tokenAddrs) external;

    function setOwner(address _owner) external;

    function setWyvernProtocolAddr(address _wyvernProtocolAddr) external;

    function getOwner() external view returns (address);

    function getWyvernProtocolAddr() external view returns (address);

    function getRewardPerNFT(address _nftAddr, address _tokenAddr) external view returns (uint256);

    function getRewardAmount(address _nftAddr, address _tokenAddr, uint256 _tokenID) external view returns (uint256);

    function getAccumulatedCommunityFee(address _nftAddr, address _tokenAddr) external view returns (uint256);

    function getClaimedCommunityFee(address _nftAddr, address _tokenAddr, uint256 _tokenID) external view returns (uint256);
}