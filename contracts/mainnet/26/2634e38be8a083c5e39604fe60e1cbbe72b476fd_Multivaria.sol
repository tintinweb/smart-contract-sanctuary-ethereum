// SPDX-License-Identifier: MIT

pragma solidity >= 0.8.13;

import "./ERC1155.sol";
import "./IEIP2981.sol";
import "./AdminControl.sol";
import "./Strings.sol";

contract Multivaria is ERC1155, AdminControl {
    
    address payable  private _royalties_recipient;
    mapping (uint256 => uint256) _tokenMaxSupply;
    mapping (uint256 => uint256) _tokenTier;
    uint256 public _editionsLeft = 200;
    uint256 private _royaltyAmount; //in % 
    uint256 [10] _ubs;
    string public _name = "Multivaria";
    string _uri;
    bool public _shiftActivated;
    bool public _advancedCardShifted;       

    
    constructor () ERC1155("") {
        _royalties_recipient = payable(msg.sender);
        _royaltyAmount = 10;
        _ubs = [2,5,10,20,35,55,80,110,150,200];
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

    function name() public view returns (string memory) {
        return _name;
    }

    function getPseudoRndTier() public returns (uint256){    
        bool tierFound = false;
        uint [10] memory  ubs = _ubs;
        uint256 tier=0;
        uint256 editionsLeft = _editionsLeft;
        uint256 rnd = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % editionsLeft;
        
        for(uint256 i=0; i<= ubs.length-1; i++){
            if(rnd < ubs[i] && tier == 0){
                tierFound = true;
                tier = i+2;
            }
            if(tierFound){
                ubs[i]--;
            }
        }
        editionsLeft--;
        _ubs = ubs;
        _editionsLeft = editionsLeft;
        return tier;   
    }

    function mint( 
        address to,
        uint256 id,
        uint256 amount
    ) external adminRequired{
        _mint(to, id, amount, "0x0");
    }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts
    )external adminRequired{
        _mintBatch(to, ids, amounts, "0x0");
    }

    function toggleShiftActivated()external adminRequired{
        _shiftActivated = !_shiftActivated;
    }

    function adminShift(uint256 multivariaId, uint256 shiftCardId, uint256 shiftedTier) external adminRequired{
        require(multivariaId <= 12 && multivariaId > 1, "Incorrect MultivariaId");
        require(shiftCardId == 13, "Incorrect ShiftCardId");
        require(shiftedTier < 12 , "Incorrect shiftedTier");

        _burn(msg.sender, multivariaId, 1);
        _burn(msg.sender, shiftCardId, 1);
        _mint(msg.sender, shiftedTier, 1, "0x0");
    }

    function shift() external {
        require(_shiftActivated, "Shift disabled");
        require(ERC1155.balanceOf(msg.sender, 12)>=1,"Multivaria Tier 12 missing for the shift");
        require(ERC1155.balanceOf(msg.sender, 13)>=1,"Shift card missing for the shift");

        uint256 shiftedTier = getPseudoRndTier();
        _burn(msg.sender, 12, 1);
        _burn(msg.sender, 13, 1);
        _mint(msg.sender, shiftedTier, 1, "0x0");
    }

    function uniqueShift(uint256 multivariaId) external {
        require(_shiftActivated, "Shift disabled");
        require(multivariaId <= 12 && multivariaId >=2, "A Multivaria Tier 2 needs to be burnt for this shift");
        require(ERC1155.balanceOf(msg.sender, multivariaId) >= 1,"Multivaria missing for the shift");
        require(ERC1155.balanceOf(msg.sender, 1) >= 1,"Advanced Shift card missing for the shift");
        _advancedCardShifted = true;
        _burn(msg.sender, multivariaId, 1);
        // Need to iterate on the token 1
    }

    function setURI(
        string calldata updatedURI
    ) external adminRequired{
        _uri = updatedURI;
    }

    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        if(tokenId == 1 && !_advancedCardShifted){
            return string(abi.encodePacked(_uri, Strings.toString(14), ".json"));
        }
        return string(abi.encodePacked(_uri, Strings.toString(tokenId), ".json"));
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