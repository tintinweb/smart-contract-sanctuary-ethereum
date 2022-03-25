// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "./ERC1155Base.sol";

contract ERC1155WoonklyNFT is ERC1155Base {
    /// @dev true if collection is private, false if public
    bool isPrivate;

    event CreateERC1155WoonklyNFT(address owner, string name, string symbol);
    event CreateERC1155WoonklyNFTUser(address owner, string name, string symbol);

    function __ERC1155WoonklyNFTUser_init(string memory _name, string memory _symbol, string memory baseURI, string memory contractURI, address[] memory operators, address transferProxy, address lazyTransferProxy) external initializer {
        __ERC1155WoonklyNFT_init_unchained(_name, _symbol, baseURI, contractURI, transferProxy, lazyTransferProxy);
        for(uint i = 0; i < operators.length; i++) {
            setApprovalForAll(operators[i], true);
        }

        isPrivate = true;
        emit CreateERC1155WoonklyNFTUser(_msgSender(), _name, _symbol);
    }
    
    function __ERC1155WoonklyNFT_init(string memory _name, string memory _symbol, string memory baseURI, string memory contractURI, address transferProxy, address lazyTransferProxy) external initializer {
        __ERC1155WoonklyNFT_init_unchained(_name, _symbol, baseURI, contractURI, transferProxy, lazyTransferProxy);

        isPrivate = false;
        emit CreateERC1155WoonklyNFT(_msgSender(), _name, _symbol);
    }

    function __ERC1155WoonklyNFT_init_unchained(string memory _name, string memory _symbol, string memory baseURI, string memory contractURI, address transferProxy, address lazyTransferProxy) internal {
        __Ownable_init_unchained();
        __ERC1155Lazy_init_unchained();
        __ERC165_init_unchained();
        __Context_init_unchained();
        __Mint1155Validator_init_unchained();
        __ERC1155_init_unchained("");
        __HasContractURI_init_unchained(contractURI);
        __ERC1155Burnable_init_unchained();
        __RoyaltiesV2Upgradeable_init_unchained();
        __ERC1155Base_init_unchained(_name, _symbol);
        _setBaseURI(baseURI);

        //setting default approver for transferProxies
        _setDefaultApproval(transferProxy, true);
        _setDefaultApproval(lazyTransferProxy, true);
    }

    function mintAndTransfer(LibERC1155LazyMint.Mint1155Data memory data, address to, uint256 _amount) public override {
        if (isPrivate){
          require(owner() == data.creators[0].account, "minter is not the owner");
        }
        super.mintAndTransfer(data, to, _amount);
    }

    uint256[49] private __gap;
}