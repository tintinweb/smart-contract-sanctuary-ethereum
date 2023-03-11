// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "./ERC721URIStorage.sol";
import "./Counters.sol";

contract MyNFT721 is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    // 构造函数，设置名称和代币符号
    constructor() ERC721("MyNFT721", "MNFT") {}

    // 创建新的 ERC721 智能合约
    function mintNFT() public returns (uint256) {
        _tokenIds.increment();

        uint256 newNFTId = _tokenIds.current();

        // 将 ERC721 令牌分配给调用者
        _mint(msg.sender, newNFTId);

        // 将与 ID 关联的 URI 分配给 ERC721 令牌
        //_setTokenURI(newNFTId, "data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 200 200'><rect x='0' y='0' width='200' height='200' style='fill:red'/></svg>");
        _setTokenURI(newNFTId, "data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iNTEyIiBoZWlnaHQ9IjEyMCIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj48c3R5bGU+LmJne2ZpbGw6IzIzMmMzMTt9LnRleHR7ZmlsbDojOWVhN2E2O2ZvbnQ6MzBweCBjb3VyaWVyO30udHdve2ZpbGw6IzJhNTQ5MTt9LnRocmVle2ZpbGw6IzIzNzk4Njt9LmZvdXJ7ZmlsbDojYTAzYjFlO30uZml2ZXtmaWxsOiM0ODRkNzk7fTwvc3R5bGU+PHBhdGggaWQ9InBhdGgiPjxhbmltYXRlIGF0dHJpYnV0ZU5hbWU9ImQiIGZyb209Im0wLDQwIGgwIiB0bz0ibTAsNDAgaDgwMCIgZmlsbD0iZnJlZXplIiBkdXI9IjNzIiAvPjwvcGF0aD48cGF0aCBpZD0icGF0aDAiPjxhbmltYXRlIGF0dHJpYnV0ZU5hbWU9ImQiIGZyb209Im0wLDgwIGgwIiB0bz0ibTAsODAgaDgwMCIgZmlsbD0iZnJlZXplIiBkdXI9IjNzIiBiZWdpbj0iMnMiLz48L3BhdGg+PGcgY2xhc3M9ImJveCI+PHJlY3Qgd2lkdGg9IjEwMCUiIGhlaWdodD0iMTAwJSIgY2xhc3M9ImJnIi8+PC9nPjx0ZXh0IHg9IjIwIiB5PSI0MCIgY2xhc3M9InRleHQiPjx0c3BhbiBjbGFzcz0idGhyZWUiPiB+IDwvdHNwYW4+PHRzcGFuIGNsYXNzPSJmaXZlIj4kIDwvdHNwYW4+PC90ZXh0Pjx0ZXh0IHg9IjkwIiB5PSI0MCIgY2xhc3M9InRleHQiPjx0ZXh0UGF0aCBocmVmPSIjcGF0aCI+PHRzcGFuPi4vc2F5R00uc2ggLS10b2tlbiA8L3RzcGFuPjx0c3Bhbj4zMjEyPC90c3Bhbj48L3RleHRQYXRoPjwvdGV4dD48dGV4dCB4PSIyMCIgeT0iODAiIGNsYXNzPSJ0ZXh0Ij48dGV4dFBhdGggaHJlZj0iI3BhdGgwIj48dHNwYW4gY2xhc3M9InR3byI+Z208L3RzcGFuPiA8dHNwYW4+MHg4ZTQ2MjQwMzwvdHNwYW4+PC90ZXh0UGF0aD48L3RleHQ+PC9zdmc+");

        // 返回新创建的 ERC721 令牌 ID
        return newNFTId;
    }
}