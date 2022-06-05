// SPDX-License-Identifier: MIT

pragma solidity >= 0.8.12;

import "./ERC1155.sol";
import "./IERC20.sol";
import "./IEIP2981.sol";
import "./AdminControl.sol";


//////////////////////////////////////////////////////////////////////////////////////////
//                                                                                      //
//   @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@   //
//   @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@   //
//   @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@   //
//   @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@   //
//   @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&,               /&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@   //
//   @@@@@@@@@@@@@@@@@@@@@@@@&&                            [email protected]@@@@@@@@@@@@@@@@@@@@@@@@   //
//   @@@@@@@@@@@@@@@@@@@@@@                                    [email protected]@@@@@@@@@@@@@@@@@@@@   //
//   @@@@@@@@@@@@@@@@@@&            %&@@@@@@@@@@@@@@@@/           ,&@@@@@@@@@@@@@@@@@   //
//   @@@@@@@@@@@@@@@@#         /@@@@@@@@@@@@@@@@@@@@@@@@@@@          @@@@@@@@@@@@@@@@   //
//   @@@@@@@@@@@@@@%        /@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@         &@@@@@@@@@@@@@   //
//   @@@@@@@@@@@@@        &@@@@@@@@%@@@@@@@@@@@@@@@@@@@@@@@@@@@@,       (@@@@@@@@@@@@   //
//   @@@@@@@@@@@@       /@@@@@@@@.    #@@@@@@@@@@@@@    #@@@@@@@@@       [email protected]@@@@@@@@@@   //
//   @@@@@@@@@@@       @@@@@@@@          @@@@@@@@/         &@@@@@@@.      ,@@@@@@@@@@   //
//   @@@@@@@@@&       @@@@@@@@@,           #@@@            &@@@@@@@&.      &@@@@@@@@@   //
//   @@@@@@@@@@      [email protected]@@@@@@@@@@&            @         /@@@@@@@@@@@@       &@@@@@@@@   //
//   @@@@@@@@@,      @@@@@@@@@@@@@@&,           #/    @@@@@@@@@@@@@@@       @@@@@@@@@   //
//   @@@@@@@@@.      @@@@@@@@@@@@@@@@@@            @@@@@@@@@@@@@@@@@@,      @@@@@@@@@   //
//   @@@@@@@@@*      @@@@@@@@@@@@@@@@   &,           #@@@@@@@@@@@@@@@       @@@@@@@@@   //
//   @@@@@@@@@@       @@@@@@@@@@@@/       .&            @@@@@@@@@@@@@       &@@@@@@@@   //
//   @@@@@@@@@@.      #@@@@@@@@&            @@,           #@@@@@@@@&       &@@@@@@@@@   //
//   @@@@@@@@@@&       #@@@@@@,          /@@@@@@&          &@@@@@@@       /@@@@@@@@@@   //
//   @@@@@@@@@@@@       [email protected]@@@@@@@      @@@@@@@@@@@@,    [email protected]@@@@@@@@       /@@@@@@@@@@@   //
//   @@@@@@@@@@@@@.       /@@@@@@@&,(@@@@@@@@@@@@@@@@@@@@@@@@@@&        &@@@@@@@@@@@@   //
//   @@@@@@@@@@@@@@@         @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&        .&@@@@@@@@@@@@@   //
//   @@@@@@@@@@@@@@@@@          &@@@@@@@@@@@@@@@@@@@@@@@@@(         [email protected]@@@@@@@@@@@@@@@   //
//   @@@@@@@@@@@@@@@@@@&.           .%&@@@@@@@@@@@@@@%            %@@@@@@@@@@@@@@@@@@   //
//   @@@@@@@@@@@@@@@@@@@@@@.                                   #@@@@@@@@@@@@@@@@@@@@@   //
//   @@@@@@@@@@@@@@@@@@@@@@@@@@*                           &@@@@@@@@@@@@@@@@@@@@@@@@@   //
//   @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&*            .#&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@   //
//   @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@   //
//   @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@   //
//   @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@   //
//                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////

contract GRAVITY is ERC1155, AdminControl {
    
    mapping(uint256 => mapping(address => bool)) public _tokenClaimed;
    mapping(uint256 => string) _uris;
    mapping(uint256 => bool) _transferAllowed;
    string private _name = "GRAVITY";

    uint256 public _ashPrice = 55*10**18; //55 Ash
    uint256 private _royaltyAmount; //in % 
    uint256 public _maxSupply = 100;
    uint256 public _supply = 0;
    uint256 public _activeToken;

    address public _ashContract = 0x64D91f12Ece7362F91A6f8E7940Cd55F05060b92;
    address private _royalties_recipient;
    address private _signer;

    bool public _ALMintOpened = false;
    bool public _publicMintOpened = false;

    
    constructor () ERC1155("") {
        _activeToken=1;
        _royalties_recipient = payable(msg.sender);
        _royaltyAmount = 10;
    } 

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, AdminControl)
        returns (bool)
    {
        return
        AdminControl.supportsInterface(interfaceId) ||
        ERC1155.supportsInterface(interfaceId) ||
        interfaceId == type(IEIP2981).interfaceId ||
        super.supportsInterface(interfaceId);
    }

    function mintAllowed( uint8 v, bytes32 r, bytes32 s)internal view returns(bool){
        return(
            _signer ==
                ecrecover(
                    keccak256(
                        abi.encodePacked(
                            "\x19Ethereum Signed Message:\n32",
                            keccak256(
                                abi.encodePacked(
                                    msg.sender,
                                    address(this),
                                    _activeToken,
                                    _ALMintOpened,
                                    _tokenClaimed[_activeToken][msg.sender],
                                    _supply < _maxSupply
                                )
                            )
                        )
                    )
                , v, r, s)
        );
    }

    function setAshAddress(address ashAddress) external adminRequired{
        _ashContract = ashAddress;
    }

    function setSigner (address signer) external adminRequired{
        _signer = signer;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function ALMint(
        uint8 v,
        bytes32 r, 
        bytes32 s
    ) external {
        require(mintAllowed(v, r, s), "Mint not allowed");
        IERC20(_ashContract).transferFrom(msg.sender, _royalties_recipient, _ashPrice);
        _mint(msg.sender ,_activeToken ,1 ,"0x00");
        _tokenClaimed[_activeToken][msg.sender] = true;
        _supply += 1;
    }

    function publicMint() external {
        require( _publicMintOpened,  "Public mint is currently closed");
        require(!_tokenClaimed[_activeToken][msg.sender],  "Can only mint one token");
        require(_supply < _maxSupply, "Max supply reached");
        IERC20(_ashContract).transferFrom(msg.sender, _royalties_recipient, _ashPrice);
        _mint(msg.sender, _activeToken, 1, "0x00");
        _tokenClaimed[_activeToken][msg.sender] = true;
        _supply += 1;
    }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts
    )external adminRequired{
        uint256 quantity = 0; 
        for(uint256 i = 0 ; i < amounts.length; i++){
            quantity += amounts[i];
        }
        require(_supply < _maxSupply, "Max supply reached");
        _mintBatch(to, ids, amounts, "0x0");
        _supply += quantity;
    }

    function initateNewDrop(
        uint256 tokenId, 
        uint256 newPrice, 
        uint256 maxSupply,  
        string calldata newURI
    ) external adminRequired{
        _activeToken = tokenId;
        _ashPrice = newPrice;
        _maxSupply = maxSupply;
        _uris[tokenId] = newURI;
        _supply = 0;
    }

    function setActiveToken(uint256 tokenId)external adminRequired{
        _activeToken = tokenId;
    }

    function toggleALMintState()external adminRequired{
        _ALMintOpened = !_ALMintOpened;
    }

    function togglePublicMintState()external adminRequired{
        _publicMintOpened = !_publicMintOpened;
    }

    function addURI(
        uint256 tokenId,
        string calldata newURI
    ) external adminRequired{
        _uris[tokenId] = newURI;
    }

    function editURI(uint256 tokenId, string calldata newURI) external adminRequired {
        _uris[tokenId] = newURI;
    }

    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        return _uris[tokenId];
    }

    function burn(uint256 tokenId, uint256 quantity) external {
        _burn(msg.sender, tokenId, quantity);
    }

    function burnBatch(
        uint256[] memory ids,
        uint256[] memory amounts
    )external{
        _burnBatch(msg.sender, ids, amounts);
    }

    function activateTransfer(uint256 tokenId)external adminRequired{
        _transferAllowed[tokenId] = true;
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override {
        for(uint256 i=0; i< ids.length; i++){
            require(from == address(0)  || _transferAllowed[ids[i]], "Transfer not allowed");
        }
    }

    function setRoyalties(address payable _recipient, uint256 _royaltyPerCent) external adminRequired {
        _royalties_recipient = _recipient;
        _royaltyAmount = _royaltyPerCent;
    }

    function royaltyInfo(uint256 salePrice) external view returns (address, uint256) {
        if(_royalties_recipient != address(0)){
            return (_royalties_recipient, (salePrice * _royaltyAmount) / 100 );
        }
        return (address(0), 0);
    }

    function withdraw(address recipient) external adminRequired {
        payable(recipient).transfer(address(this).balance);
    }

}