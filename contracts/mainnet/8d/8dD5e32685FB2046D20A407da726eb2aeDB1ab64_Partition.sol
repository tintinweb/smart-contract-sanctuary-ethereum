//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Clones.sol";
import "./ERC721A.sol";
import "./TokenStandard.sol";

contract Partition is ERC721A {
    address constant impl = 0x7D530Df63D5Cf437ABC223Ef341Ad626ce3D21B2;
    struct Instance {
        address delegate;
        address tokenAddr;
        string uri;
    }

    uint256 public numMinted;
    address payable private deployer;
    mapping (uint256 => Instance) instances;

    constructor() ERC721A("Partition", "PARTS") {
        deployer = payable(msg.sender);
        _mint(deployer, 1000);
        numMinted = 1000;
    }

    function mint(uint256 amount) external payable {
        require(amount <= 20);
        require((10000 - numMinted) >= amount);
        require(msg.value >= 0.02 ether * amount);
        _mint(msg.sender, amount);
        numMinted += amount;
    }
    
    function flush() external {
        deployer.call{value: address(this).balance}("");
    }
    
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return instances[tokenId].uri;
    }
    
    function getTokenAddr(uint256 id) public view returns (address) {
        return instances[id].tokenAddr;
    }
    
    function getDelegate(uint256 id) public view returns (address) {
         return instances[id].delegate;
    }

    function activate(uint256 id,
                      address delegate,
                      string calldata uri,
                      string calldata name,
                      string calldata symbol) external {
        require((ownerOf(id) == msg.sender)
                || (instances[id].delegate == msg.sender));
        if (instances[id].tokenAddr == address(0)) {
            address tAddr = Clones.clone(impl);
            TokenStandard(tAddr).init(name, symbol);
            TokenStandard(tAddr).transfer(msg.sender, 1000000000000000000000000);
            instances[id].tokenAddr = tAddr;
        } else {
            if (bytes(name).length > 0)
                TokenStandard(instances[id].tokenAddr).changeName(name);
            if (bytes(symbol).length > 0)
                TokenStandard(instances[id].tokenAddr).changeSymbol(symbol);
        }
        if (delegate != address(0))
            instances[id].delegate = delegate;
        if (bytes(uri).length > 0)
            instances[id].uri = uri;
    }
}