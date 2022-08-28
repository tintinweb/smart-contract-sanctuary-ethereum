// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./AbstractERC1155Factory.sol";
import "./Strings.sol";

/*

 ██████╗ ███████╗████████╗    ██╗███╗   ██╗
██╔════╝ ██╔════╝╚══██╔══╝    ██║████╗  ██║
██║  ███╗█████╗     ██║       ██║██╔██╗ ██║
██║   ██║██╔══╝     ██║       ██║██║╚██╗██║
╚██████╔╝███████╗   ██║       ██║██║ ╚████║
 ╚═════╝ ╚══════╝   ╚═╝       ╚═╝╚═╝  ╚═══╝
                                           
*/
contract GetIn is AbstractERC1155Factory {
    using Strings for uint256;
    
    event Minted(address _wallet, uint256 _ticketId, uint256 _amount, uint256 _purchaseUsersId);

    constructor(string memory _baseURI, address _signer) ERC1155(_baseURI) {
        name_ = "Get-In";
        symbol_ = "GI";
        _setSigner(_signer);
    }

    function mint(uint256 _ticketId, uint256 _amount, uint256 _purchaseUsersId, bytes calldata _token) public whenNotPaused nonReentrant
    {   
        require(verifyTokenForAddress(_ticketId, _amount, _purchaseUsersId, _token, msg.sender), "Unauthorized");
        _safeMint(msg.sender, _amount, _ticketId, _purchaseUsersId);
    }

    function airDrop(address _receiver, uint256 _mintAmount, uint256 _ticketId) public onlyOwner {
        _safeMint(_receiver, _mintAmount, _ticketId, 0);
    }

    function batchAirDrop(uint256 _ticketId, address[] memory _addresses) public onlyOwner {
        for (uint i = 0; i < _addresses.length; i++) {
            airDrop(_addresses[i], 1, _ticketId);
        }
    }

    function _safeMint(address _to, uint256 _amount, uint256 _ticketId, uint256 _purchaseUsersId) private {
        _mint(_to, _ticketId, _amount, "");
        emit Minted(_to, _ticketId, _amount, _purchaseUsersId);
    }

    function uri(uint256 _id) public view override returns(string memory) {
        require(exists(_id), "URI: nonexistent token");
        return string(abi.encodePacked(super.uri(_id), Strings.toString(_id)));
    }

    function withdraw() public onlyOwner nonReentrant {
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
    }
}