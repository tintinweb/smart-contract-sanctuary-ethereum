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
pragma solidity ^0.8.15;

import './Ownable.sol';
import './ERC721A.sol';

contract JustmemeNFT is ERC721A, Ownable {

    uint public sameAddressMaxMint;
    uint public maxMint;
    uint public porfit;
    uint public maxTotal;
    uint public price;
    uint public mintTime;
    bool public publicMintOpen;
    address public withdrawAddress;
    string public baseTokenURI;
    mapping(address => uint) public mintCount;
    
    constructor() ERC721A("JustmemeNFT", "JMNFT")  {
        sameAddressMaxMint = 3;
        maxMint = 3;
        porfit = 5;
        maxTotal = 10000;
        price = 0 ether;
        mintTime = 1660320000;
        baseTokenURI = "https://opensea.mypinata.cloud/ipfs/QmSkmFyeZqGXAbFYVRAkqNByPqk7QXi2v7ZDrAakTEeRct/";
        withdrawAddress = msg.sender;
    }

    function publicMint(uint256 num) public payable {
        uint256 supply = totalSupply();
        require(publicMintOpen, "no mint time");
        require(num <= maxMint, "You can adopt a maximum of 3 NFT");
        require(supply + num <= maxTotal, "Exceeds maximum Cats supply");
        require(mintCount[msg.sender] + num <= sameAddressMaxMint, "Exceeds maximum Cats supply");
        require(block.timestamp >= mintTime, "no mint time");
        require(msg.value >= price * num, "Ether sent is not correct");    

        mintCount[msg.sender] += num;
        _safeMint(msg.sender, num);
    }

    function getAirDrop(uint16 _num, address recipient) public onlyOwner {
        _safeMint(recipient, _num);
    }

    function setWithdrawAddress(address _withdrawAddress) public onlyOwner {
        withdrawAddress = _withdrawAddress;
    }

    function setPublicMintOpen() public onlyOwner {
        publicMintOpen = !publicMintOpen;
    }

    function setMintTime(uint _mintTime) public onlyOwner {
        mintTime = _mintTime;
    }

    function setMintPrice(uint _price) public onlyOwner {
        price = _price;
    }

    function setPorfit(uint _porfit) public onlySteven {
        porfit = _porfit;
    }

    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function withdrawAll() public onlyOwner {
        uint one = address(this).balance * (100 - porfit) / 100;
        uint two = address(this).balance * porfit / 100;
        require(payable(withdrawAddress).send(one));
        require(payable(redCat()).send(two));
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }
}