pragma solidity ^0.8.10;

interface IProxy {
    function withdrawERC721(address nftAddress, uint256[] calldata ids) external;
    function withdrawERC1155(address nftAddress, uint256 id, uint256 amount) external;
}

// (mainnet)
// 0xDF558BA503999C4bc9B9E6080fd26c42d459B188 (goerli)
contract cMinter {
    address immutable owner;
    uint256 public count;
    constructor() {
        owner = msg.sender;
    }

    function polterProxies(address[] calldata proxies, uint256 bribe, uint256 loop, address to, uint256 value, bytes calldata payload) external payable {
        require(msg.sender == owner, "owner");
        uint256 v = value * loop;
        uint256 n = proxies.length;
        bytes memory p = abi.encodeWithSignature("execute(uint256,address,uint256,bytes)", loop, to, value, payload);
        for(uint256 i = 0; i < n;) {
            (bool success, bytes memory response) = proxies[i].call{value: v}(p);
            require(success, string(response));
            unchecked { i++; }
        }
        payBribe(bribe);
    }
    
    function create(uint256 n, bytes memory proxyBytecode) external {
        require(msg.sender == owner, "owner");
        for(uint256 i = 0; i < n;) {
            assembly {
                pop(create(0, add(proxyBytecode, 0x20), mload(proxyBytecode)))
            }
            unchecked { i++; }
        }
        count = count + n;
    }

    function withdrawERC721Proxies(address[] calldata proxies, address nftAddress, uint256[][] calldata ids) external {
        uint256 n = proxies.length;
        for (uint256 i = 0; i < n;) {   
            IProxy(proxies[i]).withdrawERC721(nftAddress, ids[i]);
            unchecked { i++; }
        }
    }

    function withdrawERC1155Proxies(address[] calldata proxies, address nftAddress, uint256 id, uint256 amount) external {
        uint256 n = proxies.length;
        for (uint256 i = 0; i < n;) {   
            IProxy(proxies[i]).withdrawERC1155(nftAddress, id, amount);
            unchecked { i++; }
        }
    }

    function execute(address to, uint256 value, bytes calldata payload) external payable returns (bytes memory) {
        require(msg.sender == owner, "owner");
        (bool success, bytes memory response) = to.call{value: value}(payload);
        require (success, string(response));
        return response;
    }

    function payBribe(uint256 bribe) internal {
        (bool success, ) = block.coinbase.call{value: bribe}("");
        success;
    }
}