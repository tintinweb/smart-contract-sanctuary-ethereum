// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

abstract contract Ownable {
  address private _owner;

  constructor() {
    _owner = msg.sender;
  }

  modifier onlyOwner() {
    require(owner() == msg.sender, "Ownable: caller is not the owner");
    _;
  }

  function owner() public view virtual returns (address) {
    return _owner;
  }

  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    _owner = newOwner;
  }
}

contract BrandingListing is Ownable {
  enum LISTING_TYPE {
    SELL,
    BID
  }

  struct ListingInfo {
    string listingId;
    LISTING_TYPE listingType;
    address contractAddress;
    uint256 tokenId;
    address owner;
    uint256 amount;
    uint256 price;
    uint256 createTime;
    uint256 effectTime;
    bool isCancel;
  }

  struct ListingResult {
    string listingId;
    address owner;
    uint256 amount;
    uint256 createTime;
  }

  WETH public weth = WETH(0xd9145CCE52D386f254917e481eB44e9943F39138);

  uint256 private _platformFee;

  string[] private _listingIds;

  mapping (string => ListingInfo) private _listingInfoMap;

  mapping (string => ListingResult[]) private _listingResultsMap;

  constructor(uint256 platformFee) {
    setPlatformFee(platformFee);
  }

  function setPlatformFee(uint256 platformFee) public onlyOwner {
    require(platformFee <= 100, "Platform fee is error");
    _platformFee = platformFee;
  }

  modifier onlyListingIsExist(string memory listingId) {
		require(_listingInfoMap[listingId].createTime > 0, "Listing does not exist");
		_;
	}

  modifier onlyListingNoExist(string calldata listingId) {
		require(_listingInfoMap[listingId].createTime == 0, "Listing already exists");
		_;
	}

  modifier onlyListingOwner(string memory listingId) {
		require(msg.sender == _listingInfoMap[listingId].owner, "Sender must be the listing owner");
		_;
	}

  function createListing(
    string calldata listingId,
    LISTING_TYPE listingType,
    address contractAddress,
    uint256 tokenId,
    uint256 amount,
    uint256 price,
    uint256 effectTime
  ) external onlyListingNoExist(listingId) {
    if (listingType == LISTING_TYPE.SELL) {
      require(ERC1155(contractAddress).balanceOf(msg.sender, tokenId) >= amount, "Has not enough token");
    } else if (listingType == LISTING_TYPE.BID) {
      require(weth.balanceOf(msg.sender) >= amount, "Has not enough token");
    }

    ListingInfo memory listingInfo;

    listingInfo.listingId = listingId;
    listingInfo.listingType = listingType;
    listingInfo.contractAddress = contractAddress;
    listingInfo.tokenId = tokenId;
    listingInfo.amount = amount;
    listingInfo.price = price;
    listingInfo.effectTime = effectTime;
    listingInfo.owner = msg.sender;
    listingInfo.createTime = block.timestamp;
    listingInfo.isCancel = false;

    _listingIds.push(listingId);
    _listingInfoMap[listingId] = listingInfo;
  }

  function confirmListing(string calldata listingId, uint256 amount) external onlyListingIsExist(listingId) payable {
    ListingInfo memory listingInfo = _listingInfoMap[listingId];

    require(listingInfo.owner != msg.sender, "");
    require(!checkListingHasExpired(listingId), "Listing has expired");
    require(!checkListingHasCanceled(listingId), "Listing has canceled");
    require(getListingRemainAmount(listingId) >= amount, "");

    if (listingInfo.listingType == LISTING_TYPE.SELL) {
      ERC1155(listingInfo.contractAddress).safeTransferFrom(listingInfo.owner, msg.sender, listingInfo.tokenId, amount, "");

      uint256 totalPrice = amount * listingInfo.price;
      require(msg.value >= totalPrice, "");

      (bool ownerReceiveSuccess, ) = payable(listingInfo.owner).call{ value: (totalPrice / 100) * (100 - _platformFee) }("");
      require(ownerReceiveSuccess, "Owner failed to receive eth");

      if (msg.value > totalPrice) {
        (bool returnSuccess, ) = msg.sender.call{ value: msg.value - totalPrice }("");
        require(returnSuccess, "Sender failed to receive eth");
      }
    } else if (listingInfo.listingType == LISTING_TYPE.BID) {
      ERC1155(listingInfo.contractAddress).safeTransferFrom(msg.sender, listingInfo.owner, listingInfo.tokenId, amount, "");

      uint256 totalPrice = amount * listingInfo.price;
      uint256 platformReceiveBalance = (totalPrice / 100) * _platformFee;

      weth.transferFrom(listingInfo.owner, address(this), platformReceiveBalance);
      weth.transferFrom(listingInfo.owner, msg.sender, totalPrice - platformReceiveBalance);
    }

    ListingResult memory listingResult;
    listingResult.listingId = listingId;
    listingResult.owner = msg.sender;
    listingResult.createTime = block.timestamp;
    listingResult.amount = amount;
    _listingResultsMap[listingId].push(listingResult);
  }

  function updateListing(string calldata listingId, bool isCancel) external onlyListingIsExist(listingId) onlyListingOwner(listingId) {
    _listingInfoMap[listingId].isCancel = isCancel;
  }

  function updateListing(string calldata listingId, uint256 price) external onlyListingIsExist(listingId) onlyListingOwner(listingId) {
    _listingInfoMap[listingId].price = price;
  }

  function getListingRemainAmount(string memory listingId) public view onlyListingIsExist(listingId) returns (uint256) {
    uint256 remainAmount = _listingInfoMap[listingId].amount;
    ListingResult[] memory listingResults = _listingResultsMap[listingId];
    for (uint256 index = 0; index < listingResults.length; index++) {
      remainAmount -= listingResults[index].amount;
    }
    return remainAmount;
  }

  function checkListingHasFinished(string memory listingId) public view onlyListingIsExist(listingId) returns (bool) {
    return getListingRemainAmount(listingId) == 0;
  }

  function checkListingHasCanceled(string memory listingId) public view onlyListingIsExist(listingId) returns (bool) {
    return _listingInfoMap[listingId].isCancel;
  }

  function checkListingHasExpired(string memory listingId) public view onlyListingIsExist(listingId) returns (bool) {
    ListingInfo memory listingInfo = _listingInfoMap[listingId];
    return listingInfo.createTime + listingInfo.effectTime < block.timestamp;
  }

  function checkListingIsValid(string memory listingId) public view onlyListingIsExist(listingId) returns (bool) {
    return !(checkListingHasFinished(listingId) || checkListingHasCanceled(listingId) || checkListingHasExpired(listingId));
  }

  function getListingInfo(string calldata listingId) external view onlyListingIsExist(listingId) returns (ListingInfo memory) {
    return _listingInfoMap[listingId];
  }

  function getListingInfos(address contractAddress, bool onlyValid) external view returns(ListingInfo[] memory) {
    ListingInfo[] memory listingInfos = new ListingInfo[](0);
    for (uint256 index = 0; index < _listingIds.length; index++) {
      string memory listingId = _listingIds[index];
      ListingInfo memory listingInfo = _listingInfoMap[listingId];
      if (listingInfo.contractAddress == contractAddress && !(!onlyValid && checkListingIsValid(listingId))) {
        listingInfos = _listingInfoPush(listingInfos, listingInfo);
      }
    }
    return listingInfos;
  }

  function getListingInfos(address contractAddress, uint256 tokenId, bool onlyValid) external view returns(ListingInfo[] memory) {
    ListingInfo[] memory listingInfos = new ListingInfo[](0);
    for (uint256 index = 0; index < _listingIds.length; index++) {
      string memory listingId = _listingIds[index];
      ListingInfo memory listingInfo = _listingInfoMap[listingId];
      if (listingInfo.contractAddress == contractAddress && listingInfo.tokenId == tokenId && !(!onlyValid && checkListingIsValid(listingId))) {
        listingInfos = _listingInfoPush(listingInfos, listingInfo);
      }
    }
    return listingInfos;
  }

  function getListingInfosByOwner(address owner, bool onlyValid) external view returns(ListingInfo[] memory) {
    ListingInfo[] memory listingInfos = new ListingInfo[](0);
    for (uint256 index = 0; index < _listingIds.length; index++) {
      string memory listingId = _listingIds[index];
      ListingInfo memory listingInfo = _listingInfoMap[listingId];
      if (listingInfo.owner == owner && !(!onlyValid && checkListingIsValid(listingId))) {
        listingInfos = _listingInfoPush(listingInfos, listingInfo);
      }
    }
    return listingInfos;
  }

  function getListingInfosByOwner(address owner, address contractAddress, bool onlyValid) external view returns(ListingInfo[] memory) {
    ListingInfo[] memory listingInfos = new ListingInfo[](0);
    for (uint256 index = 0; index < _listingIds.length; index++) {
      string memory listingId = _listingIds[index];
      ListingInfo memory listingInfo = _listingInfoMap[listingId];
      if (listingInfo.contractAddress == contractAddress && listingInfo.owner == owner && !(!onlyValid && checkListingIsValid(listingId))) {
        listingInfos = _listingInfoPush(listingInfos, listingInfo);
      }
    }
    return listingInfos;
  }

  function getListingInfosByOwner(address owner, address contractAddress, uint256 tokenId, bool onlyValid) external view returns(ListingInfo[] memory) {
    ListingInfo[] memory listingInfos = new ListingInfo[](0);
    for (uint256 index = 0; index < _listingIds.length; index++) {
      string memory listingId = _listingIds[index];
      ListingInfo memory listingInfo = _listingInfoMap[listingId];
      if (listingInfo.contractAddress == contractAddress && listingInfo.tokenId == tokenId && listingInfo.owner == owner && !(!onlyValid && checkListingIsValid(listingId))) {
        listingInfos = _listingInfoPush(listingInfos, listingInfo);
      }
    }
    return listingInfos;
  }

  function getListingInfosByType(LISTING_TYPE listingType, bool onlyValid) external view returns(ListingInfo[] memory) {
    ListingInfo[] memory listingInfos = new ListingInfo[](0);
    for (uint256 index = 0; index < _listingIds.length; index++) {
      string memory listingId = _listingIds[index];
      ListingInfo memory listingInfo = _listingInfoMap[listingId];
      if (listingInfo.listingType == listingType && !(!onlyValid && checkListingIsValid(listingId))) {
        listingInfos = _listingInfoPush(listingInfos, listingInfo);
      }
    }
    return listingInfos;
  }

  function getListingInfosByType(LISTING_TYPE listingType, address contractAddress, bool onlyValid) external view returns(ListingInfo[] memory) {
    ListingInfo[] memory listingInfos = new ListingInfo[](0);
    for (uint256 index = 0; index < _listingIds.length; index++) {
      string memory listingId = _listingIds[index];
      ListingInfo memory listingInfo = _listingInfoMap[listingId];
      if (listingInfo.contractAddress == contractAddress && listingInfo.listingType == listingType && !(!onlyValid && checkListingIsValid(listingId))) {
        listingInfos = _listingInfoPush(listingInfos, listingInfo);
      }
    }
    return listingInfos;
  }

  function getListingInfosByType(LISTING_TYPE listingType, address contractAddress, uint256 tokenId, bool onlyValid) external view returns(ListingInfo[] memory) {
    ListingInfo[] memory listingInfos = new ListingInfo[](0);
    for (uint256 index = 0; index < _listingIds.length; index++) {
      string memory listingId = _listingIds[index];
      ListingInfo memory listingInfo = _listingInfoMap[listingId];
      if (listingInfo.contractAddress == contractAddress && listingInfo.tokenId == tokenId && listingInfo.listingType == listingType && !(!onlyValid && checkListingIsValid(listingId))) {
        listingInfos = _listingInfoPush(listingInfos, listingInfo);
      }
    }
    return listingInfos;
  }

  function getListingInfosByCreateTime(uint256 startTime, uint256 endTime, bool onlyValid) external view returns(ListingInfo[] memory) {
    ListingInfo[] memory listingInfos = new ListingInfo[](0);
    for (uint256 index = 0; index < _listingIds.length; index++) {
      string memory listingId = _listingIds[index];
      ListingInfo memory listingInfo = _listingInfoMap[listingId];
      if (listingInfo.createTime >= startTime && listingInfo.createTime <= endTime && !(!onlyValid && checkListingIsValid(listingId))) {
        listingInfos = _listingInfoPush(listingInfos, listingInfo);
      }
    }
    return listingInfos;
  }

  function getListingInfosByCreateTime(uint256 startTime, uint256 endTime, address contractAddress, bool onlyValid) external view returns(ListingInfo[] memory) {
    ListingInfo[] memory listingInfos = new ListingInfo[](0);
    for (uint256 index = 0; index < _listingIds.length; index++) {
      string memory listingId = _listingIds[index];
      ListingInfo memory listingInfo = _listingInfoMap[listingId];
      if (listingInfo.contractAddress == contractAddress && listingInfo.createTime >= startTime && listingInfo.createTime <= endTime && !(!onlyValid && checkListingIsValid(listingId))) {
        listingInfos = _listingInfoPush(listingInfos, listingInfo);
      }
    }
    return listingInfos;
  }

  function getListingInfosByCreateTime(uint256 startTime, uint256 endTime, address contractAddress, uint256 tokenId, bool onlyValid) external view returns(ListingInfo[] memory) {
    ListingInfo[] memory listingInfos = new ListingInfo[](0);
    for (uint256 index = 0; index < _listingIds.length; index++) {
      string memory listingId = _listingIds[index];
      ListingInfo memory listingInfo = _listingInfoMap[listingId];
      if (listingInfo.contractAddress == contractAddress && listingInfo.tokenId == tokenId && listingInfo.createTime >= startTime && listingInfo.createTime <= endTime && !(!onlyValid && checkListingIsValid(listingId))) {
        listingInfos = _listingInfoPush(listingInfos, listingInfo);
      }
    }
    return listingInfos;
  }

  function getListingResults(string calldata listingId) external view onlyListingIsExist(listingId) returns (ListingResult[] memory) {
    return _listingResultsMap[listingId];
  }

  function getListingResults(string calldata listingId, address owner) external view onlyListingIsExist(listingId) returns (ListingResult[] memory) {
    ListingResult[] memory listingResults = new ListingResult[](0);
    ListingResult[] memory _listingResults = _listingResultsMap[listingId];
    for (uint256 index = 0; index < _listingResults.length; index++) {
      ListingResult memory result = _listingResults[index];
      if (result.owner == owner) {
        listingResults = _listingResultPush(listingResults, result);
      }
    }
    return listingResults;
  }

  function getListingResults(address owner) external view returns (ListingResult[] memory) {
    ListingResult[] memory listingResults = new ListingResult[](0);
    for (uint256 index = 0; index < _listingIds.length; index++) {
      ListingResult[] memory _listingResults = _listingResultsMap[_listingIds[index]];
      for (uint256 _index = 0; _index < _listingResults.length; _index++) {
        ListingResult memory result = _listingResults[_index];
        if (result.owner == owner) {
          listingResults = _listingResultPush(listingResults, result);
        }
      }
    }
    return listingResults;
  }

  function _listingInfoPush(ListingInfo[] memory listingInfos, ListingInfo memory listingInfo) private pure returns(ListingInfo[] memory) {
    ListingInfo[] memory temp = new ListingInfo[](listingInfos.length + 1);
    for (uint256 index = 0; index < listingInfos.length; index++) {
      temp[index] = listingInfos[index];
    }
    temp[temp.length - 1] = listingInfo;
    return temp;
  }

  function _listingResultPush(ListingResult[] memory listingResults, ListingResult memory listingResult) private pure returns(ListingResult[] memory) {
    ListingResult[] memory temp = new ListingResult[](listingResults.length + 1);
    for (uint256 index = 0; index < listingResults.length; index++) {
      temp[index] = listingResults[index];
    }
    temp[temp.length - 1] = listingResult;
    return temp;
  }

  function withdraw() external onlyOwner {
    weth.transferFrom(
      address(this),
      msg.sender,
      weth.balanceOf(address(this))
    );
    (bool success, ) = payable(msg.sender).call{ value: address(this).balance }("");
		require(success, "Withdraw fail");
  }

  fallback() external payable {}
  receive() external payable {}
}

interface ERC1155 {
  function balanceOf(address owner, uint256 tokenId) external returns (uint256);
	function safeTransferFrom(address from, address to, uint256 tokenId, uint256 balance, string calldata info) external;
}

interface WETH {
  function balanceOf(address owner) external returns (uint256);
	function transferFrom(address from, address to, uint256 balance) external;
}