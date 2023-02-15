// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./OperatorFilterer.sol";
import "./ERC2981.sol";
contract Tests is ERC721, ERC721Enumerable, Ownable, OperatorFilterer, ERC2981 {

    string private _baseURIextended;
    mapping (uint => string) public idToInscription;
    uint256 public constant MAX_SUPPLY = 100;
 
    string public constant baseExtension = ".json";

    constructor() ERC721("tests", "test") {
        idToInscription[0] = "0";
        idToInscription[1] = "0";
        idToInscription[2] = "0";
        idToInscription[3] = "0";
        idToInscription[4] = "0";
        idToInscription[5] = "0";
        idToInscription[6] = "0";
        idToInscription[7] = "0";
        idToInscription[8] = "0";
        idToInscription[9] = "0";
        idToInscription[10] = "0";
        idToInscription[11] = "0";
        idToInscription[12] = "0";
        idToInscription[13] = "0";
        idToInscription[14] = "0";
        idToInscription[15] = "0";
        idToInscription[16] = "0";
        idToInscription[17] = "0";
        idToInscription[18] = "0";
        idToInscription[19] = "0";
        idToInscription[20] = "0";
        idToInscription[21] = "0";
        idToInscription[22] = "0";
        idToInscription[23] = "0";
        idToInscription[24] = "0";
        idToInscription[25] = "0";
        idToInscription[26] = "0";
        idToInscription[27] = "0";
        idToInscription[28] = "0";
        idToInscription[29] = "0";
        idToInscription[30] = "0";
        idToInscription[31] = "0";
        idToInscription[32] = "0";
        idToInscription[33] = "0";
        idToInscription[34] = "0";
        idToInscription[35] = "0";
        idToInscription[36] = "0";
        idToInscription[37] = "0";
        idToInscription[38] = "0";
        idToInscription[39] = "0";
        idToInscription[40] = "0";
        idToInscription[41] = "0";
        idToInscription[42] = "0";
        idToInscription[43] = "0";
        idToInscription[44] = "0";
        idToInscription[45] = "0";
        idToInscription[46] = "0";
        idToInscription[47] = "0";
        idToInscription[48] = "0";
        idToInscription[49] = "0";
        idToInscription[50] = "0";
        idToInscription[51] = "0";
        idToInscription[52] = "0";
        idToInscription[53] = "0";
        idToInscription[54] = "0";
        idToInscription[55] = "0";
        idToInscription[56] = "0";
        idToInscription[57] = "0";
        idToInscription[58] = "0";
        idToInscription[59] = "0";
        idToInscription[60] = "0";
        idToInscription[61] = "0";
        idToInscription[62] = "0";
        idToInscription[63] = "0";
        idToInscription[64] = "0";
        idToInscription[65] = "0";
        idToInscription[66] = "0";
        idToInscription[67] = "0";
        idToInscription[68] = "0";
        idToInscription[69] = "0";
        idToInscription[70] = "0";
        idToInscription[71] = "0";
        idToInscription[72] = "0";
        idToInscription[73] = "0";
        idToInscription[74] = "0";
        idToInscription[75] = "0";
        idToInscription[76] = "0";
        idToInscription[77] = "0";
        idToInscription[78] = "0";
        idToInscription[79] = "0";
        idToInscription[80] = "0";
        idToInscription[81] = "0";
        idToInscription[82] = "0";
        idToInscription[83] = "0";
        idToInscription[84] = "0";
        idToInscription[85] = "0";
        idToInscription[86] = "0";
        idToInscription[87] = "0";
        idToInscription[88] = "0";
        idToInscription[89] = "0";
        idToInscription[90] = "0";
        idToInscription[91] = "0";
        idToInscription[92] = "0";
        idToInscription[93] = "0";
        idToInscription[94] = "0";
        idToInscription[95] = "0";
        idToInscription[96] = "0";
        idToInscription[97] = "0";
        idToInscription[98] = "0";
        idToInscription[99] = "0";
        idToInscription[100] = "0";
        idToInscription[101] = "0";
        idToInscription[102] = "0";
        idToInscription[103] = "0";
        idToInscription[104] = "0";
        idToInscription[105] = "0";
        idToInscription[106] = "0";
        idToInscription[107] = "0";
        idToInscription[108] = "0";
        idToInscription[109] = "0";
        idToInscription[110] = "0";
        idToInscription[111] = "0";
        idToInscription[112] = "0";
        idToInscription[113] = "0";
        idToInscription[114] = "0";
        idToInscription[115] = "0";
        idToInscription[116] = "0";
        idToInscription[117] = "0";
        idToInscription[118] = "0";
        idToInscription[119] = "0";
        idToInscription[120] = "0";
        idToInscription[121] = "0";
        idToInscription[122] = "0";
        idToInscription[123] = "0";
        idToInscription[124] = "0";
        idToInscription[125] = "0";
        idToInscription[126] = "0";
        idToInscription[127] = "0";
        idToInscription[128] = "0";
        idToInscription[129] = "0";
        idToInscription[130] = "0";
        idToInscription[131] = "0";
        idToInscription[132] = "0";
        idToInscription[133] = "0";
        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;
        _setDefaultRoyalty(msg.sender, 500);
        _safeMint(msg.sender, 0);
        _baseURIextended = "";
    }
    
    bool public operatorFilteringEnabled;
    
    function setApprovalForAll(address operator, bool approved) public override(ERC721, IERC721) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }
    
    function approve(address operator, uint256 tokenId) public override(ERC721, IERC721) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setOperatorFilteringEnabled(bool value) public onlyOwner {
        operatorFilteringEnabled = value;
    }

    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFilteringEnabled;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }
    function transferFrom(address from, address to, uint256 tokenId) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override(ERC721, IERC721) onlyAllowedOperator(from) {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function reserve(uint256 n) public onlyOwner {
      uint supply = totalSupply();
      uint i;
      require(MAX_SUPPLY >= supply + n, "exceeds max supply");
      for (i = 0; i < n; i++) {
          _safeMint(msg.sender, supply + i);
      }
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        ); 
        return
            string(
                abi.encodePacked(
                    _baseURIextended,
                    Strings.toString(_tokenId),
                    baseExtension
                )
            );
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}