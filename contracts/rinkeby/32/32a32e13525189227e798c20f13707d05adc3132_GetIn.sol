// SPDX-License-Identifier: MIT
/*

 ██████╗ ███████╗████████╗    ██╗███╗   ██╗
██╔════╝ ██╔════╝╚══██╔══╝    ██║████╗  ██║
██║  ███╗█████╗     ██║       ██║██╔██╗ ██║
██║   ██║██╔══╝     ██║       ██║██║╚██╗██║
╚██████╔╝███████╗   ██║       ██║██║ ╚████║
 ╚═════╝ ╚══════╝   ╚═╝       ╚═╝╚═╝  ╚═══╝
                                           
*/
pragma solidity >=0.8.9 <0.9.0;

import './ERC721AQueryable.sol';
import './Ownable.sol';
import './ReentrancyGuard.sol';
import './SignedTokenVerifier.sol';
import './Pausable.sol';

contract GetIn is ERC721AQueryable, Ownable, ReentrancyGuard, SignedTokenVerifier, Pausable {
  using Strings for uint256;

  string public uriPrefix = '';
  mapping(uint256 => bool) private minted;
  event Minted(uint256 _ticketId, uint256 _purchaseUsersId, uint256 _tokenId);

  constructor(string memory baseURI, address _signer) ERC721A("Get-In", "GI") {
      setUriPrefix(baseURI);
      _setSigner(_signer);
  }

    function mint(uint256 _ticketId, uint256 _purchaseUsersId, bytes calldata _token) public whenNotPaused nonReentrant
    {   
        require(verifyTokenForAddress(_ticketId, _purchaseUsersId, _token, msg.sender), "Unauthorized");
        require(!minted[_purchaseUsersId], "Token already minted!");
        _safeMint(msg.sender, _ticketId, _purchaseUsersId);
        minted[_purchaseUsersId] = true;
    }

    function _safeMint(address _to, uint256 _ticketId, uint256 _purchaseUsersId) private {
        _safeMint(_to, 1);
        emit Minted(_ticketId, _purchaseUsersId, _currentIndex - 1);
    }

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
         uriPrefix = _uriPrefix;
    }

    function withdraw() public onlyOwner nonReentrant {
        (bool os, ) = payable(owner()).call{value: address(this).balance}('');
        require(os);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
}