// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../interfaces/IINO.sol";

contract NFTSpaceXINOInfo {
  function getInoInfo(address _addrINO) public view returns(
      address nftAddress,
      uint256 startTime,
      uint256 endTime,
      uint256 floorPoint,
      uint32 limitItemPerUser
  ) {
    require(_addrINO != address(0), "NSII: zero address");
    return IINO(_addrINO).info();
  }

  function getInoStatus(address _addrINO) public view returns(
      uint256 numParticipants,
      uint256[] memory tokenIds,
      uint256[] memory quantity,
      bool finalized
  ) {
    require(_addrINO != address(0), "NSII: zero address");
    return IINO(_addrINO).status();
  }

  function getInoPayment(address _addrINO) public view returns(
    address[] memory paymentToken,
    uint256[] memory priceItem
  ) {
    require(_addrINO != address(0), "NSII: zero address");
    return IINO(_addrINO).payments();
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IINO {
    function inoTemplate() external returns (uint256);
    function initIno(address, address,address, address) external;
    function info() external view returns(address,uint256,uint256,uint256,uint32);
    function payments() external view returns(address[] memory, uint256[] memory);
    function status() external view returns(uint256,uint256[] memory,uint256[] memory,bool);
}