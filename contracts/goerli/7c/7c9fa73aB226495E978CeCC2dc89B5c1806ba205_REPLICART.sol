// SPDX-License-Identifier: MIT

pragma solidity ^0.8;

import "./ERC1155.sol";

interface iRegistry {
    struct Replik { address creator; string uri; uint256 id; }
    function getReplicationRegistry(uint256 id) external  view returns (Replik memory);
}

// author: jolan.eth
contract REPLICART is ERC1155 {

    iRegistry Registry;

    constructor() {}

    function name() public pure returns (string memory) {
        return "REPLICART";
    }

    function symbol() public pure returns (string memory) {
        return "REPLIC";
    }

    function setRegistry(address _Registry) public {
        require(address(Registry) == address(0), "REPLICART::setRegistry() - Registry is already set");
        Registry = iRegistry(_Registry);
    }

    function mintREPLICART(
        address receiver,
        uint256 id
    ) public {
        require(address(Registry) != address(0) && address(Registry) == msg.sender, "REPLICART::mintREPLICART() - only Registry can mint");
        require(receiver != address(0), "REPLICART::mintREPLICART() - address is 0");
        ERC1155._mint(receiver, id, 1, "");
    }

    function uri(uint256 id) public view returns (string memory) {
        require(ERC1155.totalSupply(id) > 0, "REPLICART::uri() - id does not exist");
        return Registry.getReplicationRegistry(id).uri;
    }

    function owner() public pure returns (address) {
        return address(0);
    }
}