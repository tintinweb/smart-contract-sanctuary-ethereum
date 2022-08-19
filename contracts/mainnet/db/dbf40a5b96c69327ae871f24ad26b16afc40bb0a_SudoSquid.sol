// SPDX-License-Identifier: MIT

/// SudoSquids - Only on Sudoswap
/// Twitter: https://twitter.com/SudoSquidNFT
/// Only swappable via Sudoswap

pragma solidity ^0.8.9;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./IERC20.sol";

contract SudoSquid is ERC721A, Ownable {

    bool _mintingEnabled = true;
    bool _sudoswapOnly;
    string baseURI;
    string _contractURI;

    function mintingEnable() external view returns (bool) {
        return _mintingEnabled;
    }

    function sudoswapOnly() external view returns (bool) {
        return _sudoswapOnly;
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    constructor() ERC721A("SudoSquid", "SUDOSQUID") {
        _contractURI = "ipfs://bafkreiasnx7aszvqovlccw4ajj46jmqs4kygxwp62gd7v4vacx7bpm3zdi";
        baseURI = "ipfs://bafybeiffv5q6odx6oyy5w6hh3adrgyxf54c72smb6ifxpqnamcbextdxyi/";
    }

    function ownerMintTo(address receipient, uint256 quantity) external onlyOwner() {
        require(_mintingEnabled, 'Minting has been disabled permanently');
        _safeMint(receipient, quantity);
    }

    function disableMinting() external onlyOwner() {
        _mintingEnabled = false;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory newURI) external onlyOwner() {
        baseURI = newURI;
    }

    function setContractUri(string memory newURI) external onlyOwner() {
        _contractURI = newURI;
    }

    function setSudoswapOnly(bool value) external onlyOwner() {
        _sudoswapOnly = value;
    }

    function withdraw() external onlyOwner() {
        payable(owner()).transfer(address(this).balance);
    }

    function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner() {
        IERC20(tokenAddress).transfer(owner(), tokenAmount);
    }

    /* 
    * Hook to prevent swapping unless through the SudoSwap Factory/Router.
    */
    address constant sudoswapRouter = 0x2B2e8cDA09bBA9660dCA5cB6233787738Ad68329;
    address constant sudoswapFactory = 0xb16c1342E617A5B6E4b631EB114483FDB289c0A4;

    function _beforeApproval(address operator) internal view override {
        if(_sudoswapOnly && operator != sudoswapRouter && operator != sudoswapFactory)
        {
            require(false, 'Can only be swapped via Sudoswap');
        }
    }
}