// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

interface IERC721A {
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

contract BulkAirdrop {
    function bulkAirdrop(IERC721A _token, address[] calldata _to, uint256[] calldata _id)
        public
    {
        require(_to.length == _id.length, "Length mismatch in arrays");
        for (uint256 i = 0; i <= _to.length; i++) {
            _token.safeTransferFrom(msg.sender, _to[i], _id[i]);
        }
    }
}