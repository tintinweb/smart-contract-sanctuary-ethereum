pragma solidity ^0.8.10;

// 0x026ea26b624f8e632e8317eaabd7934ab54e9fc4 (goerli)
contract cMinter {
    address immutable owner;
    uint256 public count;
    constructor() {
        owner = msg.sender;
    }

    function startProxies(address[] calldata proxies, uint256 loop, uint256 bribe, address to, uint256 value, bytes calldata payload) external payable {
        require(msg.sender == owner, "owner");
        uint256 n = proxies.length;
        bytes memory p = abi.encodeWithSignature("execute(uint256,address,uint256,bytes)", loop, to, value, payload);
        for(uint256 i = 0; i < n;) {
            (bool success, bytes memory response) = proxies[i].call{value: value * loop}(p);
            require(success, string(response));
            unchecked { i++; }
        }
        block.coinbase.call{value: bribe}("");
    }
    
    function create(uint256 n, bytes memory proxyBytecode) external {
        require(msg.sender == owner, "owner");
        for(uint256 i = 0; i < n;) {
            address addr;
            assembly {
                addr := create(0, add(proxyBytecode, 0x20), mload(proxyBytecode))
            }
            unchecked { i++; }
        }
        count = count + n;
    }

    function withdrawERC721Proxies(address[] calldata proxies, address nftAddress, uint256[][] calldata ids) external {
        uint256 n = proxies.length;
        for (uint256 i = 0; i < n;) {   
            (bool success, bytes memory response) = proxies[i].call(
                abi.encodeWithSignature("withdrawERC721(address,uint256[])", nftAddress, ids[i])
            );
            require(success, string(response));
            unchecked { i++; }
        }
    }

    function withdrawERC1155Proxies(address[] calldata proxies, address nftAddress, uint256 id, uint256 amount) external {
        uint256 n = proxies.length;
        for (uint256 i = 0; i < n;) {   
            (bool success, bytes memory response) = proxies[i].call(
                abi.encodeWithSignature("withdrawERC1155(address,uint256,uint256)", nftAddress, id, amount)
            );
            require(success, string(response));
            unchecked { i++; }
        }
    }

    function execute(address to, uint256 value, bytes calldata payload) external payable returns (bytes memory) {
        require(msg.sender == owner, "owner");
        (bool success, bytes memory response) = to.call{value: value}(payload);
        require (success, string(response));
        return response;
    }

    function destroy() external {
        require(msg.sender == owner, "owner");
        selfdestruct(payable(owner));
    }
}