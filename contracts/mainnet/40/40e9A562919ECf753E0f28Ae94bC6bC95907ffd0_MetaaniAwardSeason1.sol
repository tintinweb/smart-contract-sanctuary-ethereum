// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "./ERC1155.sol";

import "./Ownable.sol";

import "./IConataNFT.sol";

import "./Strings.sol";

//
contract MetaaniAwardSeason1 is IConataNFT, ERC1155, Ownable{
    string public name = "Metaani Award Season1";
    uint private _mintedAmount = 0;
    uint private _burnedAmount = 0;

    //
    constructor() ERC1155("ipfs://QmTvr3anBz4ED7pXJXJjaz4W5ZvNHQEJzULjes6zfDvq6m/") {}

    
    //
    function mint(bytes calldata data) override(IConataNFT) external payable{ revert("Not Implement");}
    function mint() override(IConataNFT) external payable{ revert("Not Implement");}

    
    function getOpenedMintTermNames() override(IConataNFT) external view returns(string[] memory){revert("Not Implement");}

    
    function totalSupply() override(IConataNFT) external view returns(uint256){
        return _mintedAmount - _burnedAmount;
    }

    

    
    function uri(uint256 _tokenId) public view virtual override(ERC1155) returns (string memory) {
        string memory baseURI = super.uri(_tokenId);
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, Strings.toString(_tokenId))) : "";
    }

    // 
    function burn(uint tokenId, bytes calldata data) external{
        (uint amount) = abi.decode(data, (uint));
        address account = _msgSender();
        _burn(account, tokenId, amount);
        _burnedAmount += amount;
    }

    
    
    //
    function _minter(address account, uint amount, uint tokenId) internal{
        _mint(account, tokenId, amount, "");
        _mintedAmount += amount;
    }

    
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) override(ERC1155) internal pure {
        require(
            from == address(0) || to == address(0),
            "Not allowed to transfer token"
        );
    }

    

    
    function giveaway(address[] memory accounts, uint[] memory amounts, uint tokenId) external onlyOwner {
        require(accounts.length == amounts.length, "Invalid Length");
        for(uint i=0; i < accounts.length; i++){
            _minter(accounts[i], amounts[i], tokenId);
        }
    }

    
    function setURI(string memory newURI) override(IConataNFT) external onlyOwner {
        _setURI(newURI);
    }

    //
    function withdraw() override(IConataNFT) external pure {revert("Not Implement");}
    function withdrawSpare() override(IConataNFT) external pure {revert("Not Implement");}

}