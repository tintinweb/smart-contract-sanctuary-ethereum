//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IERC20{
    function balanceOf(address _owner) external view returns (uint256);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
    function allowance(address _owner, address _spender) external view returns (uint256);
}

interface IERC721{
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;
}

interface IERC1155{
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, uint256 _value, bytes calldata data) external;
}

contract ryokoAirdrop {
    constructor(){}

    function airdropERC20(IERC20 _token, address[] calldata _to, uint256[] calldata _value) public {
      require(_to.length == _value.length, "Length of _to and _value must be equal");
      for (uint256 i = 0; i < _to.length; i++) {
        _token.transferFrom(msg.sender, _to[i], _value[i]);
      }
    }

    function airdropERC721(IERC721 _token, address[] calldata _to, uint256[] calldata _tokenId) public {
      require(_to.length == _tokenId.length, "Length of _to and _tokenId must be equal");
      for (uint256 i = 0; i < _to.length; i++) {
        _token.safeTransferFrom(msg.sender, _to[i], _tokenId[i]);
      }
    }

    function airdropERC1155(IERC1155 _token, address[] calldata _to, uint256[] calldata _tokenId, uint256[] calldata _value) public {
      require(_to.length == _tokenId.length, "Length of _to, _tokenId");
      for (uint256 i = 0; i < _to.length; i++) {
        _token.safeTransferFrom(msg.sender, _to[i], _tokenId[i], _value[i], "");
      }
    }
}