// SPDX-License-Identifier: MIT
// Copyright (c) 2023 Fellowship

/*

███████ ███████ ██      ██       ██████  ██     ██ ███████ ██   ██ ██ ██████
██      ██      ██      ██      ██    ██ ██     ██ ██      ██   ██ ██ ██   ██
█████   █████   ██      ██      ██    ██ ██  █  ██ ███████ ███████ ██ ██████
██      ██      ██      ██      ██    ██ ██ ███ ██      ██ ██   ██ ██ ██
██      ███████ ███████ ███████  ██████   ███ ███  ███████ ██   ██ ██ ██


██████   █████  ████████ ██████   ██████  ███    ██
██   ██ ██   ██    ██    ██   ██ ██    ██ ████   ██
██████  ███████    ██    ██████  ██    ██ ██ ██  ██
██      ██   ██    ██    ██   ██ ██    ██ ██  ██ ██
██      ██   ██    ██    ██   ██  ██████  ██   ████


██████   █████  ███████ ███████
██   ██ ██   ██ ██      ██
██████  ███████ ███████ ███████
██      ██   ██      ██      ██
██      ██   ██ ███████ ███████


contract + token art by steviep.eth

*/

pragma solidity ^0.8.17;

import "./Dependencies.sol";
import "./FellowshipPatronPass.sol";

contract FellowshipTokenURI {
  using Strings for uint256;

  FellowshipPatronPass public baseContract;
  string public description = 'The Fellowship Patron Pass is an annual membership for photography lovers [valid April 1 2023 - March 31 2024]';
  string public externalUrl = 'https://postphotography.xyz/';
  string public license = 'CC BY-NC 4.0';

  constructor() {
    baseContract = FellowshipPatronPass(msg.sender);
  }

  function tokenURI(uint256 tokenId) external view returns (string memory) {
    bytes memory encodedSVG = abi.encodePacked(
      'data:image/svg+xml;base64,',
      Base64.encode(rawSVG(tokenId))
    );

    bytes memory json = abi.encodePacked(
      'data:application/json;utf8,',
      '{"name": "Fellowship Patron Pass #', tokenId.toString(),'",'
      '"description": "', description, '",'
      '"license": "', license, '",'
      '"external_url": "', externalUrl, '",'
      '"attributes": ', attributes(tokenId), ','
      '"image": "', encodedSVG,
      '"}'
    );
    return string(json);

  }

  function rawSVG(uint256 tokenId) public view returns (bytes memory) {
    uint256[] memory txs = baseContract.tokenIdToTransactions(tokenId);
    uint256 txCount = txs.length > 300 ? 300 : txs.length;

    string memory bgColor = baseContract.exists(tokenId) ? '#fff' : '#000';
    string memory strokeColor = baseContract.exists(tokenId) ? '#000' : '#fff';

    bytes memory svg = abi.encodePacked(
      '<svg viewBox="0 0 1000 1000" xmlns="http://www.w3.org/2000/svg">'
      '<rect x="0" y="0" width="1000" height="1000" fill="', bgColor, '" />'
    );

    for (uint256 i; i < txCount; i++) {
      uint256 x = txs[i] % 1000;
      uint256 y = (txs[i] % 1000000) / 1000;

      svg = abi.encodePacked(
        svg,
        '<circle cx="', x.toString(), '" cy="', y.toString(), '" r="30" fill="', strokeColor,'" />'
      );
    }

    uint256 totalProjects = baseContract.totalProjects();
    for (uint256 i; i < totalProjects; i++) {
      uint256 passUses = baseContract.passUses(tokenId, i);
      if (passUses > 0) {
        uint256 offset = i*25 + 10;
        svg = abi.encodePacked(
          svg,
          '<rect x="', offset.toString(), '" y="', offset.toString(), '" width="', (1000 - offset*2).toString(),'" height="', (1000 - offset*2).toString(),'" fill="none" stroke-width="3" stroke="', strokeColor,'" />'
        );
      }
    }

    return abi.encodePacked(svg, '</svg>');
  }

  function attributes(uint256 tokenId) public view returns (bytes memory) {
    uint256 txCount = baseContract.tokenTransactionCount(tokenId) - 1;
    uint256 totalProjects = baseContract.totalProjects();

    bytes memory attrs = abi.encodePacked(
      '[{"trait_type": "Transfers", "value": "', txCount.toString(), '"}'
    );

    for (uint256 projectId; projectId < totalProjects; projectId++) {
      uint256 passUses = baseContract.passUses(tokenId, projectId);
      (,,string memory projectName,) = baseContract.projectInfo(projectId);

      attrs = abi.encodePacked(
        attrs, ', {"trait_type": "Mints: ', projectName,'", "value": "', passUses.toString(), '"}'
      );
    }

    return abi.encodePacked(
      attrs, ']'
    );
  }


  function render(uint256 tokenId) external view returns (string memory, string memory) {
    return (string(rawSVG(tokenId)), string(attributes(tokenId)));
  }

  function updateMetadata(string calldata _externalUrl, string calldata _description, string calldata _license) external {
    require(msg.sender == baseContract.owner(), 'Ownable: caller is not the owner');

    externalUrl = _externalUrl;
    description = _description;
    license = _license;
  }
}