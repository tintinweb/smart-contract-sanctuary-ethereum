// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.8;

import "./TPL_place_helper.sol";
import "./safemath.sol";


contract PixelOwnership is PlaceHelper   {

  using SafeMath for uint;


  mapping (uint => address) pixelApprovals;

  function balanceOf(address _owner) public view returns (uint _balance) {
    return ownerPixelCount[_owner];
  }

  function ownerOf(uint _pixelId) public view returns (address _owner) {
    return pixelToOwner[_pixelId];
  }

  function _transfer(address _from, address _to, uint _pixelId) internal {
    ownerPixelCount[_to] = ownerPixelCount[_to].add(1);
    ownerPixelCount[msg.sender] = ownerPixelCount[msg.sender].sub(1);
    Pixel memory lePixel = getPixelByID(_pixelId);
    lePixel.owner = _to;
    pixelToOwner[_pixelId] = _to;
    // emit Transfer(_from, _to, _pixelId);
  }

  function transfer(address _to, uint _pixelId) public {
    _transfer(msg.sender, _to, _pixelId);
  }

  // function approve(address _to, uint _pixelId) public override{
  //   pixelApprovals[_pixelId] = _to;
  //   // emit Approval(msg.sender, _to, _pixelId);
  // }

  // function takeOwnership(uint _pixelId) public {
  //   require(pixelApprovals[_pixelId] == msg.sender);
  //   address owner = ownerOf(_pixelId);
  //   _transfer(owner, msg.sender, _pixelId);
  // }
}