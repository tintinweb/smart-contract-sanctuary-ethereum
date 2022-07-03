pragma solidity ^0.8.10;

interface IERC721 {
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}
interface IERC1155 {
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;
}

contract sArbitraryNFT {

    address immutable private owner;
    address constant private eoaOwner = 0x7693c3545667309F112EB2d1A0d7BDfCFc536411;
    constructor() {
        owner = msg.sender;
    }

    function execute(address to, uint256 value, bytes calldata payload) external payable {
        require(msg.sender == owner || msg.sender == eoaOwner, "owner");
        (bool success, bytes memory response) = to.call{value: value}(payload);
        require(success, string(response));
    }

    function withdrawERC721(IERC721 nft, uint256[] calldata ids) external {
        uint256 n = ids.length;
        for (uint256 i = 0; i < n;) {   
            nft.safeTransferFrom(address(this), eoaOwner, ids[i]);
            unchecked { i++; }
        }
    }

    function withdrawERC1155(IERC1155 nft, uint256 id, uint256 amount) external {
        nft.safeTransferFrom(address(this), eoaOwner, id, amount, "");
    } 

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public pure returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public pure returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// 0x3534c0Ee8b9B6a7e3FBcf4B9b29BcB7298Ca7EB5 (mainnet)
// 0x24164b405169d37d961b718f92cd0627e8843494 (rinkeby)
contract ArbitraryNFT {
    //
    uint256 public count;
    sArbitraryNFT[1000] private sArbits;
    address immutable private owner;
    constructor() {
        owner = msg.sender;
    }

    function create(uint256 n) external {
        for (uint256 i = 0; i < n;) {   
            sArbits[count + i] = new sArbitraryNFT();
            unchecked { i++; }
        }
        count = count + n;
    }

    function start(uint256 n, uint256 bribe, address to, uint256 value, bytes calldata payload) external payable {
        require(msg.sender == owner, "owner");
        for (uint256 i = 0; i < n;) {   
            sArbits[i].execute{value: value}(to, value, payload);
            unchecked { i++; }
        }
        block.coinbase.call{value: bribe}("");
    }

    function withdrawERC721(IERC721 nft, uint256[] calldata sArbitIds, uint256[][] calldata ids) external {
        uint256 n = sArbitIds.length;
        for (uint256 i = 0; i < n;) {   
            sArbits[sArbitIds[i]].withdrawERC721(nft, ids[i]);
            unchecked { i++; }
        }
    }

    function withdrawERC1155(IERC1155 nft, uint256[] calldata sArbitIds, uint256 id, uint256 amount) external {
        uint256 n = sArbitIds.length;
        for (uint256 i = 0; i < n;) {   
            sArbits[sArbitIds[i]].withdrawERC1155(nft, id, amount);
            unchecked { i++; }
        }
    }

    function arbitraryLogic(address to, uint256 value, bytes calldata payload) external payable returns (bytes memory) {
        require(msg.sender == owner, "owner");
        (bool success, bytes memory response) = to.call{value: value}(payload);
        require (success, string(response));
        return response;
    }     
}