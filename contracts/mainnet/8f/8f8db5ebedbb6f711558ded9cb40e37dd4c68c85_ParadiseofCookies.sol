// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
/*

    ▒▒▒▒▒▒▒▒▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▒▒▒▒▒▒▒▒
    ▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▒▒▒▒▒▒▒▒
    ▒▒▒▒▒▒▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▒▒▒▒▒▒
    ▒▒▒▒▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▒▒▒▒
    ▒▒▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▒▒
    ▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░│││││││'''''│││││││░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▒
    ▒▒░░░░░░░░░░░░░░░░░░░░░░░░││││¡▄▄╗╗▄▄,▄#╬╬╬╬▀╗▄,;▄▄;'││░░░░░░░░░░░░░░░░░░░░░░░░▒
    ▒░░░░░░░░░░░░░░░░░░░░░░│││''╓@╬╬╬╬╣╣╬╬╬╠╠╠╠╩╙╙╙╙░░░││▀╗µ││░░░░░░░░░░░░░░░░░░░░░░
    ▒░░░░░░░░░░░░░░░░░░░│││'.▄▓╬╬╬╬╬╬╠╠╠╠╠╠╩╩╙░░░░╬ " ¼░░░░▓▄'│││░░░░░░░░░░░░░░░░░░░
    ▒░░░░░░░░░░░░░░░░░│││''╓▓╬╬╬╣╬╬╬╬╬╠╠░░░░░░░░░░≡ -,ô░░░░░│╙▀▀W▄│░░░░░░░░░░░░░░░░░
    ▒░░░░░░░░░░░░░░░░││'' ▄╬╬╬╬╠╠╠╩╙╙░░░░░░░░░░░░░░░;░░░░░░░░░░░░╙▌││░░░░░░░░░░░░░░░
    ░░░░░░░░░░░░░░░││''▄▓▓╬╬╣╩╙╙╙╬░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░╠▒││░░░░░░░░░░░░░░
    ░░░░░░░░░░░░░░││''▐╬╬╬╬╬▒,.⌐ ╓░░░░░░░░Q▄▓▓▄░░░░░░░░░░░░░░░░░░░░╙bQ│░░░░░░░░░░░░░
    ░░░░░░░░░░░░░││'' ╟╬╬╬╬╬╬╬╓,▄╩░░░░░░░░,┘` "╢▀░░░░░░#▀╩╩▒░░░░░░░░≤░▌│░░░░░░░░░░░░
    ░░░░░░░░░░░░░│''  ▐╬╬╬╬╣╬╠╠╠╠░░░░░░░░@      └░░░░░░╩    ╙░░░░░░░░╚▌││░░░░░░░░░░░
    ░░░░░░░░░░░░││'  ▄▓╬╬╬╬╬╠╬╬╠╩░░░░░░░░▒ ╔▓µ#╗ ╠░░░░╠⌐,╖,╖ ╞░░░░░░Γ ╝µ│░░░░░░░░░░░
    ░░░░░░░░░░░░│''.▓╬╬╬╬╬╬╠╠╠╠░░░░░░░░░░▒ ╣▌ ╟▓ φ░░░░╞⌐╟▌`▓Γ⌠░░░░░░,  ╙▄¡░░░░░░░░░░
    ░░░░░░░░░░░││' ▐╬╬╬╬╬╠╠╠╠╠▒≥░░░░░░░░░║╦ ╙▓▀ ,░░░░░░╬ ╙▀  ╩░░░░░░│░░½▌¡░░░░░░░░░░
    ░░░░░░░░░░░││' '▓╬╬╬▒╠╠╠╠╠' ]╔ê░░░░░░░╙▄,,,φ│░░░░░░│╠≥≥≤▒░░░░░░░░░╣▌│¡░░░░░░░░░░
    ░░░░░░░░░░░░│┐  ╙▓╬╬▓╣▒╠╠▒  ╠░░░░░░░░░│░░░░│░░░╓▒░░░░░░░░φ░░░░░░░.░▓│░░░░░░░░░░░
    ░░░░░░░░░░░░│┐.  ▐╬╬╬╣▒╠╠╬▒╩░]╙,└ ╛`▒░░░░░░░░░▓▀│╠▒░░░╙,╙⌐ ╙░░░░;░░▌│░░░░░░░░░░░
    ░░░░░░░░░░░░░│┐. ▓╝╝╣╬╠╬╠╬╠╦╔".  ,'Æ▌╠░░░░░░░░││)│░░░▐ ⌐` `└▒░░░░░╫'¡░░░░░░░░░░░
    ░░░░░░░░░░░░░││..╟^~▀└╣╬╠╠╠╠╠⌐φ=     ╠;░░░░)▄▒▄é╬Q∩╩│░░≥╓Γφ░░░Γ;░φ▒¡░░░░░░░░░░░░
    ░░░░░░░░░░░░░░││┐ ▀ç▄ ╣▒╠╠╠╠╠▒%, │▀╓∩│░░░░░░╫▓▓██▓▓░░░░░░░░░░;░╓▓▀│░░░░░░░░░░░░░
    ░░░░░░░░░░░░░░░░│┐.'╙╣╬▓▒╠╠╠╠▒░░▒░;≤░░░░░░░░░╫╬▓▓╣▒▒░░░░░░░;░░#╙'¡░░░░░░░░░░░░░░
    ▒░░░░░░░░░░░░░░░░││┐. ▓╬╬╣╠╠╠╠╠╠╠╠▒░░░░░░░░░░░││││░░░░░░░";░░å'│░░░░░░░░░░░░░░░░
    ▒░░░░░░░░░░░░░░░░░░││┌'▓╬╬╣╣╣╣╣╣╬╠╠╠▒░░░░░░░░░░░░░░░░░░░;░░▄╩,¡░░░░░░░░░░░░░░░░░
    ▒░░░░░░░░░░░░░░░░░░░░││'╙▀▓╬╬╬╣╬╠╠╠╠╠╠φφφφ╦░   "░░╔Q ² ╠Ä▀╙.¡░░░░░░░░░░░░░░░░░░░
    ▒░░░░░░░░░░░░░░░░░░░░░░░││┌'╙▀╬╬╣▓╣╣╣╣╣╣╣▒╠╠▒╦╥╓φ▒╠▄▄▄▀╙│¡░░░░░░░░░░░░░░░░░░░░░░
    ▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░││└╙▀▀▀▀▀▀▀▀╝▓╬╬╬╬╣▓▀╙^┐┐¡░░░░░░░░░░░░░░░░░░░░░░░░░░
    ▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░¡│││,▄▄▓░╙╙│░▓ƒ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒
    ▒▒▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▄▓╬╩╩▀▀▀▀╡░#╩╩▀▀▄░░░░░░░░░░░░░░░░░░░░░░░░▒▒▒▒
    ▒▒▒▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░▓╬╠▒░░░░░░░░░░░░░░▀▒░░░░░░░░░░░░░░░░░░░░░▒▒▒▒▒
    ▒▒▒▒▒▒▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░░▐▓╬▒░░░░╠└╓─ ╛"▒░)░░╫░░░░░░░░░░░░░░░░░░▒▒▒▒▒▒▒▒
    ▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░░░░░░░░░░░░░░░░░▓╬╠░░]▓▒ ~  ╓'Θ▀╠▐▒░░▌░░░░░░░░░░░░░░░▒▒▒▒▒▒▒▒▒▒
    ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░░░░░░░░░░░░░░█╬╠░░▓╬▒ ≥"',,  ▒╫╬░░╫░░░░░░░░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒

    */
import "./ERC721A.sol";
import "./Ownable.sol";
import "./DefaultOperatorFilterer.sol";
import "./MerkleProof.sol";

    contract ParadiseofCookies is ERC721A, Ownable, DefaultOperatorFilterer {
    uint256 public price;   
    uint256 public maxSupply;
    address private withdrawWallet;
    string baseURI;
    string public baseExtension;   
    bytes32 public root;

    constructor() ERC721A("Paradise of Cookies", "POC") {
        root = 0xe4a70dade03b10d1637a538a313730762b8d44effddcd168e0606cce142c593d;
        price = 0.05 ether;
        maxSupply = 420;
        baseExtension = ".json";
        baseURI = "";
        withdrawWallet = address(msg.sender);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }


    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setTreeRoot(bytes32 newroot) public onlyOwner {
        root = newroot;
    }
    
    function setWithdrawWallet(address wallet) public onlyOwner {
        withdrawWallet = wallet;
    }

    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }

    function withdraw() public payable onlyOwner {
        (bool os, ) = payable(withdrawWallet).call{value: address(this).balance}("");
        require(os);
    }

    function mint(uint256 _mintAmount, bytes32[] memory proof) external payable {
        require(totalSupply() + _mintAmount <= maxSupply);
        require(isValid(proof, keccak256(abi.encodePacked(msg.sender))), "Not a part of Allowlist");
        _mint(msg.sender, _mintAmount);
    }

    function publicMint(uint256 _mintAmount) external payable {
        require(totalSupply() + _mintAmount <= maxSupply);
        require(msg.value >= price * _mintAmount);
        _mint(msg.sender, _mintAmount);
    }

    function isValid(bytes32[] memory proof, bytes32 leaf) public view returns (bool) {
        return MerkleProof.verify(proof, root, leaf);
    }

    function _startTokenId() internal view virtual override(ERC721A) returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721A) returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(_baseURI(), _toString(tokenId), baseExtension)) : '';
    }

    function transferFrom(address from,address to, uint256 tokenId) public payable override(ERC721A) onlyAllowedOperator {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override(ERC721A) onlyAllowedOperator {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to,uint256 tokenId, bytes memory data) public payable override(ERC721A) onlyAllowedOperator {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}