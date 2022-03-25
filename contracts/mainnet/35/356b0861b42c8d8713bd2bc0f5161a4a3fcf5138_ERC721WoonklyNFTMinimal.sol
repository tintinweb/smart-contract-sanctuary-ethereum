// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "./ERC721BaseMinimal.sol";

contract ERC721WoonklyNFTMinimal is ERC721BaseMinimal {
    /// @dev true if collection is private, false if public
    bool isPrivate;

    event CreateERC721WoonklyNFT(address owner, string name, string symbol);
    event CreateERC721WoonklyNFTUser(address owner, string name, string symbol);

    function __ERC721WoonklyNFTUser_init(string memory _name, string memory _symbol, string memory baseURI, string memory contractURI, address[] memory operators, address transferProxy, address lazyTransferProxy) external initializer {
        __ERC721WoonklyNFT_init_unchained(_name, _symbol, baseURI, contractURI, transferProxy, lazyTransferProxy);

        for(uint i = 0; i < operators.length; i++) {
            setApprovalForAll(operators[i], true);
        }

        isPrivate = true;
        emit CreateERC721WoonklyNFTUser(_msgSender(), _name, _symbol);
    }

    function __ERC721WoonklyNFT_init(string memory _name, string memory _symbol, string memory baseURI, string memory contractURI, address transferProxy, address lazyTransferProxy) external initializer {
        __ERC721WoonklyNFT_init_unchained(_name, _symbol, baseURI, contractURI, transferProxy, lazyTransferProxy);

        isPrivate = false;
        emit CreateERC721WoonklyNFT(_msgSender(), _name, _symbol);
    }

    function __ERC721WoonklyNFT_init_unchained(string memory _name, string memory _symbol, string memory baseURI, string memory contractURI, address transferProxy, address lazyTransferProxy) internal {
        _setBaseURI(baseURI);
        __ERC721Lazy_init_unchained();
        __RoyaltiesV2Upgradeable_init_unchained();
        __Context_init_unchained();
        __ERC165_init_unchained();
        __Ownable_init_unchained();
        __ERC721Burnable_init_unchained();
        __Mint721Validator_init_unchained();
        __HasContractURI_init_unchained(contractURI);
        __ERC721_init_unchained(_name, _symbol);

        //setting default approver for transferProxies
        _setDefaultApproval(transferProxy, true);
        _setDefaultApproval(lazyTransferProxy, true);
    }

    function mintAndTransfer(LibERC721LazyMint.Mint721Data memory data, address to) public override virtual {
        if (isPrivate){
            require(owner() == data.creators[0].account, "minter is not the owner");
        }
        super.mintAndTransfer(data, to);
    }

    uint256[49] private __gap;
}