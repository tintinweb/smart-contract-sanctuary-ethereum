/**
 *Submitted for verification at Etherscan.io on 2022-09-20
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.13;

contract TokenURI {
  bytes private constant base64urlchars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_";

  bytes private constant txt1 = "{\"$id\":\"https://localhost/nft.schema.json\",\"$schema\":\"https://json-schema.org/draft/2020-12/schema\",\"animation_url\":\"https://arweave.net/XxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxX\",\"attributes\":[{\"trait_type\":\"Authenticity\",\"value\":\"Authentic Certified NFT\"},{\"display_type\":\"date\",\"trait_type\":\"Created\",\"value\":0000000000},{\"trait_type\":\"Creator\",\"value\":\"XxXx XxXxXx\"}],\"description\":\"Desc\",\"external_url\":\"https://localhost/\",\"image\":\"https://arweave.net/XxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxX\",\"imageUrl\":\"https://arweave.net/XxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxX\",\"name\":\"Image Painting 1/";
  bytes private constant txt2 = "\",\"properties\":{\"animation_url\":\"https://arweave.net/XxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxX\",\"created_at\":\"0000-00-00T00:00:00.000000Z\",\"creator_wallet\":\"0xXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXx\",\"description\":\"Image Painting Description\",\"image\":\"https://arweave.net/XxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxX\",\"imageUrl\":\"https://arweave.net/XxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxX\",\"minted_on\":\"00 XxXxXxXx 0000\",\"name\":\"Image Painting 1/";
  bytes private constant txt3 = "\",\"nft_type\":\"non-fungible video token (video/mp4)\",\"preview_media_file\":\"https://arweave.net/XxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxX\",\"preview_media_file_dimensions\":\"640x360\",\"preview_media_file_size\":3343521,\"preview_media_file_type\":\"video/mp4\",\"raw_media_dimensions\":\"1920x1080\",\"raw_media_file\":\"https://arweave.net/XxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxX\",\"raw_media_file_size\":00000000,\"raw_media_file_spec\":\"Duration:00:00:00.00, start:0.000000, bitrate:11168 kb/s\nVideo:h264 (Main) (avc1 / 0x31637661), yuv420p, 1920x1080 [SAR 1:1 DAR 16:9], 10884 kb/s, 24 fps, 24 tbr, 24k tbn, 48 tbc (default)\nAudio:aac (LC) (mp4a / 0x6134706D), 48000 Hz, stereo, fltp, 317 kb/s (default)\",\"raw_media_file_type\":\"video/mp4\",\"raw_media_format\":\"landscape\",\"raw_media_signature\":\"0xXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXx\",\"raw_media_signature_type\":\"SHA-256\",\"thumb_media_file\":\"https://arweave.net/XxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxX\",\"thumb_media_file_type\":\"image/jpg\",\"title\":\"Image Painting 1/";
  bytes private constant txt4 = "\",\"total_supply\":";
  bytes private constant txt5 = "},\"title\":\"Image Painting 1/";
  bytes private constant txt6 = "\"}";

  function tokenURI2(uint256 supply) public pure returns (string memory) {
    bytes memory supplyString = uint2str(supply);
    bytes memory output = abi.encodePacked(txt1, supplyString, txt2);
    output = abi.encodePacked(output, supplyString, txt3);
    output = abi.encodePacked(output, supplyString, txt4);
    output = abi.encodePacked(output, supplyString, txt5);
    output = abi.encodePacked(output, supplyString, txt6);
    output = encode(output);
    output = abi.encodePacked("data:application/json;base64,", output);
    return string(output);
  }

  function uint2str(uint256 _i) internal pure returns (bytes memory) {
    if (_i == 0) {
      return "0";
    }
    uint256 j = _i;
    uint256 len;
    while (j != 0) {
      len++;
      j /= 10;
    }
    bytes memory bstr = new bytes(len);
    uint256 k = len;
    while (_i != 0) {
      k = k - 1;
      uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
      bytes1 b1 = bytes1(temp);
      bstr[k] = b1;
      _i /= 10;
    }
    return bstr;
  }

  function encode(bytes memory _bs) internal pure returns (bytes memory) {
    uint256 rem = _bs.length % 3;
    uint256 res_length = ((_bs.length + 2) / 3) * 4 - ((3 - rem) % 3);
    bytes memory res = new bytes(res_length);
    uint256 i = 0;
    uint256 j = 0;
    for (; i + 3 <= _bs.length; i += 3) {
      (res[j], res[j + 1], res[j + 2], res[j + 3]) = encode3(uint8(_bs[i]), uint8(_bs[i + 1]), uint8(_bs[i + 2]));
      j += 4;
    }
    if (rem != 0) {
      uint8 la0 = uint8(_bs[_bs.length - rem]);
      uint8 la1 = 0;
      if (rem == 2) {
        la1 = uint8(_bs[_bs.length - 1]);
      }
      (bytes1 b0, bytes1 b1, bytes1 b2, /* bytes1 b3*/) = encode3(la0, la1, 0);
      res[j] = b0;
      res[j + 1] = b1;
      if (rem == 2) {
        res[j + 2] = b2;
      }
    }
    return res;
  }

  function encode3(uint256 a0, uint256 a1, uint256 a2) internal pure returns (bytes1 b0, bytes1 b1, bytes1 b2, bytes1 b3) {
    uint256 n = (a0 << 16) | (a1 << 8) | a2;
    uint256 c0 = (n >> 18) & 63;
    uint256 c1 = (n >> 12) & 63;
    uint256 c2 = (n >> 6) & 63;
    uint256 c3 = (n) & 63;
    b0 = base64urlchars[c0];
    b1 = base64urlchars[c1];
    b2 = base64urlchars[c2];
    b3 = base64urlchars[c3];
  }
}