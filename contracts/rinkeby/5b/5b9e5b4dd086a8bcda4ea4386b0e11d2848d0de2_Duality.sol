// SPDX-License-Identifier: MIT

pragma solidity >= 0.8.12;

import "./ERC1155.sol";
import "./IERC20.sol";
import "./IEIP2981.sol";
import "./AdminControl.sol";
import "./Strings.sol";




contract Duality is ERC1155, AdminControl {
    
    mapping(address => uint256) public _tokensClaimed;

    string private _uri = "https://arweave.net/tGXT29j1OAIPHwJHoxZYA7u9CKPe3ZHSfBWdGZpGx4o";

    uint256 public _ashPrice = 9*10**18; //9 ASH
    uint256 private _royaltyAmount; //in % 

    // address _ashContract;
    address public _ashContract = 0x4392329a8565E81E3C041034feAC84616fe9A722;
    // address public _ashContract = 0x64D91f12Ece7362F91A6f8E7940Cd55F05060b92;
    address private _royalties_recipient;
    address private _signer;

    bool public _mintOpened = false;
    bool public _mergeOpened = false;

// 1	Zero Video
// 2	Zero Audio
// 3	One Video
// 4	One Audio
// 5	∞ Video
// 6	∞ Audio
// 7	Zero Video, Zero Audio
// 8	Zero Video, One Audio
// 9	Zero Video, ∞ Audio
// 10	One Video, Zero Audio
// 11	One Video, One Audio
// 12	One Video, ∞ Audio
// 13	∞ Video, Zero Audio
// 14	∞ Video, One Audio
// 15	∞ Video, ∞ Audio
// 16   No Video, No Audio

    
    constructor () ERC1155("") {
        _royalties_recipient = payable(msg.sender);
        _royaltyAmount = 10;
    } 

    //////////  TO BE DELETED //////////
    // function setAshContractAddress(address ashContractAddress) external adminRequired{
    //     _ashContract = ashContractAddress;
    // }
    ////////////////////////////////////

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

    function mintAllowed(uint256 quantity, uint8 v, bytes32 r, bytes32 s)internal view returns(bool){
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
                                    _mintOpened,
                                    quantity <= 2
                                )
                            )
                        )
                    )
                , v, r, s)
        );
    }

    function setSigner (address signer) external adminRequired{
        _signer = signer;
    }

    function publicMint(
        address account,
        uint256[] calldata  tokenIds,
        uint256[] calldata quantities,
        uint8 v,
        bytes32 r, 
        bytes32 s
    ) external {
        uint256 quantity; 
        for(uint256 i = 0 ; i<quantities.length; i++){
            quantity += quantities[i];
        }
        require(mintAllowed(quantity, v, r, s), "Mint not allowed");
        require(_tokensClaimed[account] + quantity <= 2, "Cannot mint more than 2 tokens");
        IERC20(_ashContract).transferFrom(msg.sender, _royalties_recipient, _ashPrice * quantity);
        _mintBatch(account ,tokenIds ,quantities ,"0x00");
        _tokensClaimed[account] = _tokensClaimed[account] + quantity;
    }

    // function adminMint(
    //     address account,
    //     uint tokenId,
    //     uint256 quantity
    // ) external adminRequired {
    //     _mint(account ,tokenId ,quantity ,"0x00");
    // }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts
    )external adminRequired{
        _mintBatch(to, ids, amounts, "0x0");
    }

    function toggleMintState()external adminRequired{
        _mintOpened = !_mintOpened;
    }

    function toggleMergeState()external adminRequired{
        _mergeOpened = !_mergeOpened;
    }

    // function updateURIs(
    //     uint256[] calldata tokenIds, 
    //     string[] calldata uris
    // ) external adminRequired{
    //     require(tokenIds.length == uris.length, "Invalid data provided");
    //     for(uint256 i=0; i <= tokenIds.length - 1; i++){
    //         _uris[tokenIds[i]] = uris[i];
    //     }
    // }

    function setURI(
        string calldata updatedURI
    ) external adminRequired{
        _uri = updatedURI;
    }

    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(_uri, Strings.toString(tokenId), ".json"));
    }

    function merge(address account, uint256 token1, uint256 token2)external{
        require(isAdmin(msg.sender) || account == msg.sender,"Cannot merge another person's token");
        require(_mergeOpened, "Merge phase not activated");
        require(balanceOf(account, token1)>0, "Not enough token to merge");
        require(balanceOf(account, token2)>0, "Not enough token to merge");
        uint256 sum = token1 + token2;
        require(sum % 2 == 1 && token1 <= 6 && token2 <= 6, "Token combination invalid for merge");
        uint256 mergedToken;
        if(token1 == 1 || token2 ==1){
            mergedToken = sum == 3 ? 7 : sum == 5 ? 8 : 9; 
        }else if(token1 == 3 || token2 == 3){
            mergedToken = sum == 5 ? 10 : sum == 7 ? 11 : 12;
        }else{
            mergedToken = sum == 7 ? 13 : sum == 9 ? 14 : 15;
        }
        _burn(account, token1, 1);
        _burn(account, token2, 1);
        _mint(account, mergedToken, 1, "0x0");
    }

    function burn(uint256 tokenId, uint256 quantity) public {
        _burn(msg.sender, tokenId, quantity);
    }

    function burnBatch(
        uint256[] memory ids,
        uint256[] memory amounts
    )external{
        _burnBatch(msg.sender, ids, amounts);
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