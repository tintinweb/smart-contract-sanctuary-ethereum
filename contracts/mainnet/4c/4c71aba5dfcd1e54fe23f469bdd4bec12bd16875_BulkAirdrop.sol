/**
 *Submitted for verification at Etherscan.io on 2023-01-06
*/

// File: contracts/BulkAirdrop.sol


pragma solidity >=0.8.0 <0.9.0;

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
}

interface IERC721 {
    function safeTransferFrom(address from, address to, uint256 tokenId) external;    
}


contract BulkAirdrop {
    constructor() {}

    function BulkAirdropERC20(IERC20 _token, address[] calldata _to, uint256[] calldata _value) public {
        require(_to.length == _value.length, "Receivers and amounts are different length");
        for (uint256 i = 0; i < _to.length; i++) {
            require(_token.transferFrom(msg.sender, _to[i], _value[i]));
        }
    }

      function BulkAirdropERC721(IERC721 _token, address[] calldata _to, uint256[] calldata _id) public {
         require(_to.length == _id.length, "Receivers and IDs are different length");
        for (uint256 i = 0; i < _to.length; i++) {
            _token.safeTransferFrom(msg.sender, _to[i], _id[i]);
        }
    }
}