/*
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&#&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@&#P!^!PGP55Y55PGB&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@GJ~:. .:[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@B.                .^[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@~   .#@@@@@@@P^   ~JYJ~   ^5&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@&P^   !GGB#####BPY~   ^[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&:   [email protected]@@@@@&7   [email protected]@@@@B7. [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@5!!7Y#@@@@@@@@@@@
@@@@@@@@@~   [email protected]@@@@@@@@@@@~   [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&:   [email protected]@@@@&~   [email protected]@@@@@@@@&#&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@^    [email protected]@@@@@@@@@@
@@@@@@@@@~   [email protected]@@@@@@@@@@G:   [email protected]@@@@@@@@@#GPGGB#&@@@@@@@@@@@@@BPYYY5G&#.   [email protected]@@@@?   [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@&#BGGB#@@@@@@@@@@@@@^    [email protected]@@@@@@@@@@
@@@@@@@@@~   [email protected]@@@@@@&B5!   .?&@@@@@@@#J^       :[email protected]@@@@@@@5^       .~    [email protected]@@@G    [email protected]@@@@@@@@@@@@@@@@@@@@@&GJ!:.     .^[email protected]@@@@B555Y.    [email protected]@@@@@@
@@@@@@@@@!   5BGPYJ7~:   .~Y#@@@@@@@@5.   !5GG5J~   [email protected]@@@#~   .?PGPY^     [email protected]@@@7   [email protected]@@@@@@@@@@@@@@@@@@@@@J.   .!J55Y7.   [email protected]@@@?          .:^J&@@@@@@
@@@@@@@B!.          :~7YG#@@@@@@@@@@?   [email protected]@@@@@@Y   [email protected]@@&^   ^#@@@@@@7    [email protected]@@&^   [email protected]@@@@@@@@@@@@@@@@@@@@@J::~5&@@@@@@B:   [email protected]@@&P55Y.   ~#&@@@@@@@@@@
@@@@@@@B!.   ~J7:   ^Y&@@@@@@@@@@@@P    ^G&&&&#BY^  :[email protected]@@J   .#@@@@@@@G    [email protected]@@#.   [email protected]@@@@@@@@@@@@@BG#@@@@@@@&#BPY?!~^^:.   ^@@@@@@@#.   [email protected]@@@@@@@@@@@
@@@@@@@@@?   [email protected]@&G?:  [email protected]@@@@@@@@@!    . ..:..  :75&@@@@^   [email protected]@@@@@@@Y   [email protected]@@@^   [email protected]@@@@@@@@@@@P~   [email protected]@@@BJ~.  .:~!7??^   :&@@@@@@B    [email protected]@@@@@@@@@@@
@@@@@@@@@J   [email protected]@@@@&P!.  ^J#@@@@@@@?    Y#P555PG#@@@@@@@@~   [email protected]@@@@@@#:   .#@@@@P   [email protected]@@@@@@@BY^   ^[email protected]@@@Y    7B&@@@@@@!   :&@@@@@@B    [email protected]@@@@@@@@@@@
@@@@@@@@@J   [email protected]@@@@@@@#Y^  .!5#&@@@#^   .5&@@@@@&[email protected]@@G.   J#@@@#Y.    .#@@@@@G^   ^JY5YJ!:    [email protected]@@@@@7    ?B&&&#BY~    :&@@@@@@&^   [email protected]@&BG&@@@@@@
@@@@@@@@@G.   [email protected]@@@@@@@@@G!.   [email protected]@@&J^.  .^~~^:.  [email protected]@@@#?:   :::  :7    [email protected]@@@@@@G?^.      .^[email protected]@@@@@@@&Y~.   ...   ^:   .&@@@@@@@B^   ~?: [email protected]@@@@@
@@@@@@@@@@#P5P&@@@@@@@@@@@@#57!Y&@@@@@@#PY?777??YPB&@@@@@@@@&BPY???YG&@Y~^[email protected]@@@@@@@@@&BBGGB#&@@@@@@@@@@@@@@@&BP55Y5PB#@G~:^[email protected]@@@@@@@@@GY?7?YG&@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import './ERC721A.sol';
import './Strings.sol';

contract BlueFragment is ERC721A {

     // library
    using Strings for uint256;

    // constant
    uint constant public maxMint = 3;
    uint constant public maxTotal = 6666;
    uint constant public mintTime = 1655125200;
    
    // attributes
    bool public freeMintOpen = false;
    bool public blindBoxOpen = false;
    address public withdrawAddress;
    string public baseTokenURI;
    string public blindTokenURI;
    mapping(address => uint) public buyRecord;
    
    // modifiers
    modifier onlyOwner {
        require(msg.sender == withdrawAddress, "not owner");
        _;
    }

    constructor(string memory name, string memory symbol, string memory _blindTokenURI) ERC721A(name, symbol)  {
        blindTokenURI = _blindTokenURI;
        withdrawAddress = msg.sender;
    }

    //Free Mint
    function freeMint(uint256 num) public {
        uint256 supply = totalSupply();
        require(freeMintOpen, "not open");
        require(num + buyRecord[msg.sender] <= maxMint, "You can mint a maximum of 3 NFT");
        require(supply + num <= maxTotal, "Exceeds maximum NFT supply");
        require(block.timestamp >= mintTime, "no mint time");

        buyRecord[msg.sender] += num;
        _safeMint(msg.sender, num);
    }

    //Only Owner
    function getAirDrop(address recipient, uint16 _num) public onlyOwner {
        _safeMint(recipient, _num);
    }

    function setWithdrawAddress(address _withdrawAddress) public onlyOwner {
        withdrawAddress = _withdrawAddress;
    }

    function setFreeMintOpened() public onlyOwner {
        freeMintOpen = !freeMintOpen;
    }

    function setBlindBoxOpened() public onlyOwner {
        blindBoxOpen = !blindBoxOpen;
    }

    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function setBlindTokenURI(string memory _blindTokenURI) public onlyOwner {
        blindTokenURI = _blindTokenURI;
    }

    function withdrawAll() public onlyOwner {
        (bool success, ) = withdrawAddress.call{value : address(this).balance}("");
        require(success, "withdrawAddress error");
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), 'ERC721Metadata: URI query for nonexistent token');

        if (blindBoxOpen) {
            string memory baseURI = _baseURI();
            return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : '';
        } else {
            return blindTokenURI;
        }
    }
}