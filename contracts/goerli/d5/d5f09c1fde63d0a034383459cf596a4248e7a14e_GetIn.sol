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

import "./ERC721AQueryable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./SignedTokenVerifier.sol";
import "./Pausable.sol";

contract GetIn is
    ERC721AQueryable,
    Ownable,
    ReentrancyGuard,
    SignedTokenVerifier,
    Pausable
{
    using Strings for uint256;

    string public uriPrefix = "";
    mapping(uint256 => bool) private minted;
    event Minted(uint256 _ticketId, uint256 _purchaseUsersId, uint256 _tokenId);

    constructor(string memory baseURI, address _signer)
        ERC721A("Get-In", "GI")
    {
        setUriPrefix(baseURI);
        _setSigner(_signer);
    }

    function mint(
        uint256 _ticketId,
        uint256 _purchaseUsersId,
        bytes calldata _token,
        string calldata _salt
    ) public whenNotPaused nonReentrant {
        //for this scope only
        {
            uint256[] memory _ticketIdArray = new uint256[](1);
            _ticketIdArray[0] = _ticketId;
            uint256[] memory _purchaseUsersIdArray = new uint256[](1);
            _purchaseUsersIdArray[0] = _purchaseUsersId;
            require(
                verifyTokenForAddress(
                    _salt,
                    _ticketIdArray,
                    _purchaseUsersIdArray,
                    _token,
                    msg.sender
                ),
                "Unauthorized"
            );
        }
        require(!minted[_purchaseUsersId], "Token already minted!");
        _safeMint(msg.sender, _ticketId, _purchaseUsersId);
        minted[_purchaseUsersId] = true;
    }

    function bulkMint(
        uint256[] memory _ticketIds,
        uint256[] memory _purchaseUsersIds,
        bytes calldata _token,
        string calldata _salt
    ) public whenNotPaused nonReentrant {
        require(_ticketIds.length == _purchaseUsersIds.length, "Invalid args");
        require(
            verifyTokenForAddress(
                _salt,
                _ticketIds,
                _purchaseUsersIds,
                _token,
                msg.sender
            ),
            "Unauthorized"
        );
        for (uint256 index = 0; index < _purchaseUsersIds.length; index++) {
            require(!minted[_purchaseUsersIds[index]], "Token already minted!");
        }
        for (uint256 index = 0; index < _purchaseUsersIds.length; index++) {
            uint256 _ticketId = _ticketIds[index];
            uint256 _purchaseUsersId = _purchaseUsersIds[index];
            _safeMint(msg.sender, _ticketId, _purchaseUsersId);
            minted[_purchaseUsersId] = true;
        }
    }

    function _safeMint(
        address _to,
        uint256 _ticketId,
        uint256 _purchaseUsersId
    ) private {
        _safeMint(_to, 1);
        emit Minted(_ticketId, _purchaseUsersId, _currentIndex - 1);
    }

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function withdraw() public onlyOwner nonReentrant {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
}