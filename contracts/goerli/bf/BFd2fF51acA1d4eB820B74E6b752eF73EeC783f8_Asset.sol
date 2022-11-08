// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ERC721.sol";
import "./mintable.sol";
import "./Whitelistable.sol";

contract Asset is ERC721, Mintable, whitelistSystem {

    mapping(address => uint256) public balances;

    constructor(
        address _owner,
        string memory _name,
        string memory _symbol,
        address _imx
    ) ERC721(_name, _symbol) Mintable(_owner, _imx) {
        whitelist_autority[_owner] = true;
    }

    function _mintFor(
        address user,
        uint256 id,
        bytes memory
    ) internal override {
        _safeMint(user, id);
    }

    // SECTION Whitelist and control system hooks

    uint mintPrice = 100000000000000000;
    uint lastId = 0;

    function setMintPrice(uint _mintPrice) public onlyOwner {
        mintPrice = _mintPrice;
    }

    // NOTE FIXIT Ensure https://docs.x.immutable.com/docs/deep-dive-minting/ is respected
    
    // NOTE Public mint
    function mint() public payable safe {
        // Avoid pre mints
        require(!is_wl_on, "Whitelist is on");
        // Checking against mint price
        require(msg.value >= mintPrice, "Not enough ETH");
        uint256 id = totalSupply();
        _mintFor(msg.sender, id, "");
        lastId += 1;
    }

    // NOTE Only callable by the whitelist address
    function mintWhitelist(address receiver) public authMint returns (uint id_) {
        // Avoid whitelist mints after disabled whitelist
        require(is_wl_on, "whitelist not enabled");
        require(balances[receiver] < 4, "Max 4 mints per address");
        // NOTE The price should be already paid as this method is
        // only callable by the whitelist address that is controlled
        // by the middleware
        uint256 id = totalSupply();
        _mintFor(receiver, id, "");
        lastId += 1;
        return lastId-1;
    }

    // NOTE Token counter
    function totalSupply() public view returns (uint256) {
        return lastId;
    }
    
    // !SECTION Whitelist and control system hooks

}