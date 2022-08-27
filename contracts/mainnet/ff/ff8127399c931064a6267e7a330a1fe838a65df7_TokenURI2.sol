/**
 *Submitted for verification at Etherscan.io on 2022-08-27
*/

// SPDX-License-Identifier: MIT

/*
   ______              _           ____
  /_  __/__ ______ _  (_)__  ___ _/ / /_ __
   / / / -_) __/  ' \/ / _ \/ _ `/ / / // /
  /_/__\__/_/ /_/_/_/_/_//_/\_,_/_/_/\_, /
   / __ \___  / (_)__  ___          /___/
  / /_/ / _ \/ / / _ \/ -_)
  \____/_//_/_/_/_//_/\__/


TokenURI Contract
  This contract defines all URI logic for Terminally Online.
  All values are hardcoded, except for externalUrl. While externalUrl is meant to point to an ENS/IPFS-managed decentralized website, many browsers don't support .eth domain names. As a result, the default externalUrl is set to terminallyonline.eth.limo instead of terminallyonline.eth.
  The externalUrl can only be updated by the multisig address, as determined by the base Terminally Online contract.

*/

pragma solidity ^0.8.11;

interface BaseContract {
  function multisig() external returns (address);
}


contract TokenURI2 {
  struct TokenData {
    string name;
    string displayName;
    string description;
    string uri;
    string thumbnail;
    bool still;
  }

  mapping(uint256 => TokenData) public tokens;

  BaseContract public baseContract;

  string public externalUrl = 'terminallyonline.eth.limo';
  string public baseURI = 'ipfs://bafybeighhnttnmvvtyollod2afb7abl4465r2gw2hjsp3dqi7zmhvjrl7m';

  constructor(BaseContract _base) {
    baseContract = _base;

    tokens[0].name = 'time';
    tokens[0].displayName = 'Time';
    tokens[0].description = 'TIME IS RUNNING OUT: ACT NOW';
    tokens[0].uri = 'ipfs://bafkreidpvlppqosimrvvvy5ye7wqnuu2doa3sjw3fsek2nuoii5gnjllbe';

    tokens[1].name = 'money';
    tokens[1].displayName = 'Money';
    tokens[1].description = 'Stop Throwing Your Money Away';
    tokens[1].uri = 'ipfs://bafkreiempqhdgkgzibebptqqgcxktiw6mkxjb3kls35dhyg256z34mry4e';

    tokens[2].name = 'life';
    tokens[2].displayName = 'Life';
    tokens[2].description = 'Is Something Missing From Your Life?';
    tokens[2].uri = 'ipfs://bafkreia4ogroqa7msvibwkxoot5ztsnq372dvr3dqiles6orvnj4hdgnbq';

    tokens[3].name = 'death';
    tokens[3].displayName = 'Death';
    tokens[3].description = 'Your Death Is Coming! Are YOU prepared to die?';
    tokens[3].uri = 'ipfs://bafkreidiylknzobfn3hkslw2rpm72t4vd7ksqrnwktl6rkkd3ikxyu4ofu';

    tokens[4].name = 'fomo';
    tokens[4].displayName = 'FOMO';
    tokens[4].description = 'FOMO';
    tokens[4].uri = 'ipfs://bafkreiaavsguqgj235rc6orqk2bk6myqbx64mpmygrn2hipotovn22zcw4';

    tokens[5].name = 'fear';
    tokens[5].displayName = 'Fear';
    tokens[5].description = 'FEAR UNCERTAINTY DOUBT';
    tokens[5].uri = 'ipfs://bafkreifmhtc7wod6ygnssfihrwplnvotifjx7xhlncnr2qqfv5xh7sw6oa';

    tokens[6].name = 'uncertainty';
    tokens[6].displayName = 'Uncertainty';
    tokens[6].description = 'FEAR UNCERTAINTY DOUBT';
    tokens[6].uri = 'ipfs://bafkreibp6stctm5iuxqnpni3nxiaekkxvvs2l4cxpnqpg2joadobo7qh4i';

    tokens[7].name = 'doubt';
    tokens[7].displayName = 'Doubt';
    tokens[7].description = 'Fear Uncertainty Doubt';
    tokens[7].uri = 'ipfs://bafkreie777mazoeotypfnczgjkvilmgmamg3im7wef6ez4xqhkopyxkxla';

    tokens[8].name = 'god';
    tokens[8].displayName = 'God';
    tokens[8].description = 'Disclaimer';
    tokens[8].uri = 'ipfs://bafkreiaob4jy6zl62bpmuv3nv7oxjv2phwtbwxzrughplbhssg3q4phoxu';

    tokens[9].name = 'hell';
    tokens[9].displayName = 'Hell';
    tokens[9].description = 'Are you going to HELL?';
    tokens[9].uri = 'ipfs://bafkreigqnziyeuczo4n73zpshlobzk2gvh5267ebvdvdcjlu6vtptjgbja';

    tokens[10].name = 'stop';
    tokens[10].displayName = 'Stop';
    tokens[10].description = 'STOP! Unless you understand exactly what you are doing';
    tokens[10].uri = 'ipfs://bafkreibxf6te63sfuvnu3zrji64iitp3txycvazv2wub57ramvquohhqjm';
    tokens[10].still = true;

    tokens[11].name = 'yes';
    tokens[11].displayName = 'Yes';
    tokens[11].description = 'Is this all there is? Yes!';
    tokens[11].uri = 'ipfs://bafkreiadu556ki44k2tihpho5jrpcppxzw7nhskoznhq6deo73ntohtbjq';
    tokens[11].still = true;
  }
  modifier onlyOwner() {
    require(address(baseContract.multisig()) == msg.sender, "Caller is not the URI owner");
    _;
  }


  function updateExternalUrl(string calldata _externalUrl) external onlyOwner {
    externalUrl = _externalUrl;
  }

  function getTokenData(uint256 tokenId) external view returns (
    string memory,
    string memory,
    string memory,
    string memory,
    bool
  ) {
    TokenData memory td = tokens[tokenId];
    return (td.name, td.displayName, td.description, td.uri, td.still);
  }

  function tokenURI(uint256 tokenId) external view returns (string memory) {
    require(tokenId < 12, 'URI query for nonexistent token');

    string memory name = tokens[tokenId].name;
    string memory displayName = tokens[tokenId].displayName;
    string memory description = tokens[tokenId].description;
    string memory uri = tokens[tokenId].uri;
    string memory thumbnail = string(abi.encodePacked(baseURI, '/', name, tokens[tokenId].still ? '.png' : '.gif'));
    string memory tokenExternalUrl = string(abi.encodePacked('https://', name, '.', externalUrl));

    bytes memory json = abi.encodePacked(
      'data:application/json;utf8,',
      '{"name": "', displayName,
      '", "description": "', description,
      '", "animation_url": "', uri,
      '", "image": "', thumbnail,
      '", "external_url": "', tokenExternalUrl,
      '"}'
    );

    return string(json);
  }
}