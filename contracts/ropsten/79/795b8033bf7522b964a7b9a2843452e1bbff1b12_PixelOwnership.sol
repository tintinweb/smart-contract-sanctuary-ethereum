// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.8;

import "./TPL_place_helper.sol";
// import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./safemath.sol";


contract PixelOwnership is PlaceHelper   {

  // constructor() ERC721("Pixel", "PXL") public { }

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
    // Todo update Pixel (with pixelsAccess)
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

  function takeOwnership(uint _pixelId) public {
    require(pixelApprovals[_pixelId] == msg.sender);
    address owner = ownerOf(_pixelId);
    _transfer(owner, msg.sender, _pixelId);
  }



  // function _buyPixel(uint x, uint y, uint price) internal {
  //       address _to = msg.sender;
  //       address _from = getOwner(x, y); // a effacer
  //       Pixel memory lePixel = pixelsAccess[x][y];
  //       // uint index = 9999999;
  //       Pixel[] memory pixelsArray = ownedPixels[_from];
  //       // Pixel[] memory newProprietairePixelArray = new Pixel[](pixelsArray.length-1);
  //       Pixel[] memory newProprietairePixelArray;
  //       uint compteur = 0;
  //       for(uint i ; i < pixelsArray.length ; i++){
  //           // Assert.equal(keccak256(array1)), keccak256(array2));
  //           // if(pixelsArray[i].id == lePixel.id){
  //           if(compareStrings(pixelsArray[i].id,lePixel.id) == false){
  //               newProprietairePixelArray[compteur] = pixelsArray[i];
  //               compteur++;
  //           }else{
  //               delete pixelsArray[i];
  //           }
  //       }

  //       // Proprietaire
        
  //       // ownedPixels[_from] = newProprietairePixelArray;
  //       ownerPixelCount[_from]++;

  //       // Receiver
  //       ownedPixels[_to].push(lePixel);
  //       ownerPixelCount[_to]++;
  //   }


  //   function buyPixel(uint x, uint y) public {
  //       require(isOwnedBy(x, y, msg.sender) == true);
  //       uint price = 1;
  //       _buyPixel(x, y, price);
  //   }

    
  //   function compareStrings(string memory a, string memory b) public view returns (bool) {
  //       return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
  //   }
}