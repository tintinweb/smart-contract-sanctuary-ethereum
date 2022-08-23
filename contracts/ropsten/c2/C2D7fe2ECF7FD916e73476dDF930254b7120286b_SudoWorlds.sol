//    //   ) )     //   / /     //    ) )     //   ) )   ||   / |  / /     //   ) )     //   ) )     / /        //    ) )     //   ) ) 
//   ((           //   / /     //    / /     //   / /    ||  /  | / /     //   / /     //___/ /     / /        //    / /     ((        
//     \\        //   / /     //    / /     //   / /     || / /||/ /     //   / /     / ___ (      / /        //    / /        \\      
//       ) )    //   / /     //    / /     //   / /      ||/ / |  /     //   / /     //   | |     / /        //    / /           ) )   
//((___ / /    ((___/ /     //____/ /     ((___/ /       |  /  | /     ((___/ /     //    | |    / /____/ / //____/ /     ((___ / /    

// SPDX-License-Identifier: MIT

// SudoWorlds [sudoswap]
// Telegram: https://t.me/sudoworlds
// sudoswap takeover test

pragma solidity ^0.8.9;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./IERC20.sol";


contract SudoWorlds is ERC721A, Ownable {

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

    constructor() ERC721A("SudoWorlds", "SUDOWORLDS") {
        _contractURI = "ipfs://QmSA9F6n91wYLkYx67RqCPtqPCW1FvDEKTtVHSRvQfrMdU";
        baseURI = "ipfs://QmR6LemGktLBBansobCnJqgVxj291GAM4BWNsZSLipeKMW/";
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
            require(false, 'Can only be swapped via sudoswap');
        }
    }
}