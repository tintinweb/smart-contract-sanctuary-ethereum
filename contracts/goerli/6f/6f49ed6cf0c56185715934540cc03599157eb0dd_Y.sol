/**
 *Submitted for verification at Etherscan.io on 2023-01-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// This is a test contract
// Minting is 24-25 February 2023
/////////////////////////////////
//                             //
//                             //
//                             //
//                             //
//                             //
//              Y.             //
//              —              //
//             0xG             //
//                             //
//                             //
//                             //
//                             //
/////////////////////////////////

contract Y {
  address public creator;
  address public N;
  bool public combined;

  constructor(address _creator, address _N) {
    creator = _creator;
    N = _N;
  }

  function supportsInterface(bytes4 interfaceId) public view returns (bool) {
    return (
      interfaceId == /* ICreatorExtensionTokenURI */ 0xe9dc6375 ||
      (!combined && interfaceId == /* IERC721CreatorExtensionApproveTransfer */ 0x45ffcdad) ||
      interfaceId == /* IERC165 */ 0x01ffc9a7
    );
  }

  function tokenURI(address _creator, uint tokenId) external view returns (string memory) {
    require(creator == _creator, "Invalid Call");

    bytes memory metadata =  abi.encodePacked(
      'data:application/json;utf8,',
      '{"name":"'
    );

    if (combined && tokenId == 2) {
      uint256 NtokenId = IN(N).collectors(
        IERC721CreatorCore(creator).ownerOf(2)
      );
      metadata = abi.encodePacked(
        metadata,
        'N.',
        NtokenId == 0 ? '' : string(abi.encodePacked('%20%23', toString(NtokenId))),
        '","image":"',
        'data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAxMDAwIDEwMDAiPjxkZWZzPjxsaW5lYXJHcmFkaWVudCBpZD0iMHhHX05fYmciIHkyPSIxMDAlIj48c3RvcCBvZmZzZXQ9IjAlIiBzdG9wLWNvbG9yPSIjMTExIi8+PHN0b3Agb2Zmc2V0PSIxMDAlIiBzdG9wLWNvbG9yPSIjMDAwIi8+PC9saW5lYXJHcmFkaWVudD48bGluZWFyR3JhZGllbnQgaWQ9IjB4R19OX2wiIHkyPSIxMDAlIj48c3RvcCBvZmZzZXQ9IjAlIiBzdG9wLWNvbG9yPSIjMDAwIi8+PHN0b3Agb2Zmc2V0PSIxMDAlIiBzdG9wLWNvbG9yPSIjMDAwIiBzdG9wLW9wYWNpdHk9IjAiLz48L2xpbmVhckdyYWRpZW50PjxmaWx0ZXIgaWQ9IjB4R19OX25vaXNlIj48ZmVUdXJidWxlbmNlIHR5cGU9ImZyYWN0YWxOb2lzZSIgYmFzZUZyZXF1ZW5jeT0iNSIgbnVtT2N0YXZlcz0iMyIgc3RpdGNoVGlsZXM9InN0aXRjaCIvPjxmZUNvbG9yTWF0cml4IHR5cGU9InNhdHVyYXRlIiB2YWx1ZXM9IjAiLz48ZmVDb21wb25lbnRUcmFuc2Zlcj48ZmVGdW5jUiB0eXBlPSJsaW5lYXIiIHNsb3BlPSIwLjUiLz48ZmVGdW5jRyB0eXBlPSJsaW5lYXIiIHNsb3BlPSIwLjUiLz48ZmVGdW5jQiB0eXBlPSJsaW5lYXIiIHNsb3BlPSIwLjUiLz48L2ZlQ29tcG9uZW50VHJhbnNmZXI+PGZlQmxlbmQgbW9kZT0ic2NyZWVuIi8+PC9maWx0ZXI+PC9kZWZzPjxyZWN0IHdpZHRoPSIxMDAwIiBoZWlnaHQ9IjEwMDAiIGZpbGw9InVybCgjMHhHX05fYmcpIi8+PHJlY3QgaGVpZ2h0PSI1MDAiIHdpZHRoPSI1MDAiIHk9IjI1MCIgeD0iMjUwIiBmaWxsPSJ1cmwoIzB4R19OX2wpIi8+PHJlY3Qgd2lkdGg9IjEwMDAiIGhlaWdodD0iMTAwMCIgZmlsdGVyPSJ1cmwoIzB4R19OX25vaXNlKSIgb3BhY2l0eT0iMC4xIi8+PC9zdmc+'
      );
    } else {
      metadata = abi.encodePacked(
        metadata,
        'Y.',
        combined ? '' : string(abi.encodePacked('%20%23', toString(tokenId))),
        '","image":"data:image/svg+xml,',
        "%3Csvg%20xmlns='http://www.w3.org/2000/svg'%20viewBox='0%200%201000%201000'%3E"
      );

      string memory len = toString(combined ? 1000 : ((tokenId - 1) * 1000) / 23);
      string memory len2 = toString((combined ? 1000 : ((tokenId - 1) * 1000) / 23) / 2);
      string memory animation = combined ? "%3Canimate%20attributeName='width'%20dur='120s'%20repeatCount='indefinite'%20values='0;" : '';

      bytes memory id = abi.encodePacked('0xG_Y', toString(tokenId), '_');
      string memory st = "%3Cstop%20offset='";
      string memory rcbg = "%3Crect%20width='1000'%20height='";

      metadata = abi.encodePacked(
        metadata,
        '%3Cdefs%3E',
          "%3CradialGradient%20id='",id,"bg'%20r='100%25'%20gradientTransform='rotate(55)'%3E",
            st,"0%25'%20stop-color='%23efefef'/%3E",
            st,"100%25'%20stop-color='%23fff'/%3E",
          '%3C/radialGradient%3E'
      );

      metadata = abi.encodePacked(
        metadata,
          "%3ClinearGradient%20id='",id,"l'%20x2='0%25'%20y2='100%25'%20gradientTransform='rotate(-90)'%3E",
            st,"0%25'%20stop-color='%234bf1d0'/%3E",
            st,"100%25'%20stop-color='%23fff'%20stop-opacity='0'/%3E",
          '%3C/linearGradient%3E',
        '%3C/defs%3E'
      );

      metadata = abi.encodePacked(
        metadata,
        rcbg,"1000'%20fill='%23fff'/%3E",
        rcbg,"500'%20y='500'%20fill='url(%23",id,"bg)'/%3E",
        rcbg,"500'%20fill='url(%23",id,"bg)'/%3E"
      );

      metadata = abi.encodePacked(
        metadata,
        "%3Crect%20height='3'%20width='",len,"'%20y='498.5'%20fill='url(%23",id,"l)'%3E",
          combined ? string(abi.encodePacked(animation,len,";0'/%3E")) : '',
        '%3C/rect%3E',
        "%3Crect%20height='3'%20width='",len2,"'%20y='498.5'%20fill='url(%23",id,"l)'%20transform='rotate(180,500,500)'%3E",
          combined ? string(abi.encodePacked(animation,len2,";0'/%3E")) : '',
        '%3C/rect%3E',
        '%3C/svg%3E'
      );
    }

    return string(
      abi.encodePacked(
        metadata,'","created_by":"0xG","description":""}'
      )
    );
  }

  /**
   * @dev Combine the 24 Y. tokens to create Y. and N.
   *
   * Requirements:
   *
   * - Caller must own all the 24 Y tokens
   * - Caller must call setApprovalForAll() on creator contract with this contract address and true
   */
  function combine() external {
    require(!combined, "Already combined");
    IERC721CreatorCore target = IERC721CreatorCore(creator);
    require(target.balanceOf(msg.sender) == 24, "Must own all the Y. tokens");
    combined = true;

    target.setApproveTransferExtension(false);

    for (uint i=3; i<=24; i++) {
      target.burn(i);
    }
  }

  function approveTransfer(address, address, address to, uint256) external returns (bool) {
    if (!combined) {
      return to != address(0) && to != address(0xdEaD);
    }

    return true;
  }

  function isAdmin(address addr) external view returns (bool) {
    return IERC721CreatorCore(creator).isAdmin(addr);
  }

  function mint(address to) external {
    require(IERC721CreatorCore(creator).mintExtension(to) <= 24, "All tokens have been minted");
  }

  function destroy() external {
    require(this.isAdmin(msg.sender), "Unauthorized");
    selfdestruct(payable(msg.sender));
  }

  // Taken from "@openzeppelin/contracts/utils/Strings.sol";
  function toString(uint256 value) internal pure returns (string memory) {
    if (value == 0) {
      return "0";
    }
    uint256 temp = value;
    uint256 digits;
    while (temp != 0) {
      digits++;
      temp /= 10;
    }
    bytes memory buffer = new bytes(digits);
    while (value != 0) {
      digits -= 1;
      buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
      value /= 10;
    }
    return string(buffer);
  }
}

interface IERC721CreatorCore {
  function balanceOf(address owner) external pure returns (uint256 balance);
  function burn(uint256 tokenId) external;
  function isAdmin(address sender) external pure returns (bool);
  function mintExtension(address to) external returns (uint256 tokenId);
  function ownerOf(uint256 tokenId) external pure returns (address owner);
  function setApproveTransferExtension(bool enabled) external;
}

interface IN {
  function collectors(address collector) external view returns (uint256 tokenId);
}