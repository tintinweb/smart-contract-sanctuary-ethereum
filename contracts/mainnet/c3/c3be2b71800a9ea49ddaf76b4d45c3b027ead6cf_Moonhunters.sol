// ..............................................................................................................
// ..............................................................................................................
// ..............................................................................................................
// .....[email protected]@@@@@@@@@@@..............................
// [email protected]@@@@@@@@@@@[email protected]@::......::::[email protected]
// [email protected]@::.   ....::[email protected]@@::....::::::::::[email protected]
// [email protected]@::,..   ......::[email protected]@@::....::::::::::::[email protected]
// [email protected]@..    LLLLLL::::::[email protected]@@::....::::::::::::::::[email protected]
// [email protected]@::....fLiiiiii11::::::[email protected]@@::......::::::::::::::::[email protected]
// [email protected]@......:iiiiiiiii11::::::[email protected]@@......::::::::::::::::::[email protected]
// [email protected]@....::....iiiiiiii11::::::[email protected]@@::....::::::::::::::::::::[email protected]
// [email protected]@..............iiiiii11::::::[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@::::::::::::::::[email protected]
// [email protected]@................iiiiii11::[email protected]@@@@@@@@@[email protected]@@@::::::::::::[email protected]
// [email protected]@[email protected]@@@@@GGGGGGGGGG          [email protected]@::::::::::[email protected]
// [email protected]@[email protected]@@@GGGGGG          ;;;;;;;;;;;;[email protected]@::::::::[email protected]
// [email protected]@[email protected]@@@GGCC      ;;;;;;;;;;;;;;;;;;;;;;;;[email protected]@::::::[email protected]
// [email protected]@[email protected]@@@[email protected]@@@@@;;;;;;;;;;;;;;;;;;;;;;[email protected]@@@@@::[email protected]
// [email protected]@....::[email protected]@[email protected]@@@@@@@@@[email protected]@@@@@@@@@@@@@::[email protected]
// [email protected]@....::[email protected]@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@::[email protected]
// [email protected]@  [email protected]@@@[email protected]@@@@@@@@@@@@@@@ff....::[email protected]@@@@@@@@@@@@@88::[email protected]
// [email protected]@::@@@@[email protected]@@@@@@@    @@@@@@@@@@......::[email protected]@@@@@@@@@  ;;@@88..........................
// [email protected]@[email protected]@@@@@@@::@@@@;;    @@;;@@@@@@......::[email protected]@@@@@;f    @@;;@@..........................
// [email protected]@@@@@@@@@@@[email protected]@@@ff;;@@@@;;@@....            [email protected]@ff;;@@@@;;@@@@........................
// [email protected]@@@:::ttttt::........::@@@@  ff;;;;[email protected]@::........::::...:@@  ff;;;;[email protected]@@@........................
// [email protected]@::ii::::[email protected]@@;;[email protected]@::..................::[email protected]@@::[email protected]
// [email protected]@::::::..............LLff::[email protected]@@@@@@::......................::[email protected]@@@@::[email protected]@........................
// [email protected]@::::..............ttff....::::ttff...................................:@@........................
// [email protected]@::::............LLff......:iLLff..................................tt:[email protected]@........................
// [email protected]@::............LLtt........ttff::::........::[email protected]@@@@@@@@@@@@::......::::@@........................
// [email protected]@::[email protected]@@@@[email protected]@[email protected]@@@......
// [email protected]@::......tLLL..................::::::[email protected]@@@@@@@@@[email protected]@....::::::@@[email protected]@  @@......
// [email protected]@................................::::......::[email protected]@@@@@@@@@@@@::....::::[email protected]@[email protected]@  @@........
// [email protected]@............................................::[email protected]@@@@@@@@::[email protected]@[email protected]@::  @@........
// [email protected]@....::ittt........tt::[email protected]@[email protected]@[email protected]@    @@........
// [email protected]@..::;t::[email protected]@[email protected]@[email protected]@  ::@@........
// [email protected]@..ittLtttLLL..........................::[email protected]@@@@@@@@@........::@@[email protected]@  @@..........
// [email protected]@::..tLLLLLLLLL............................::::;[email protected]@::::::::@@@@@@@@[email protected]@@  @@..........
// [email protected]@[email protected]@@@::        ::@@@@@@@@[email protected]@@@............
// [email protected]@[email protected]@@@::          ::  @@@@....................
// [email protected]@..................tttLLL::it....::[email protected]@@@::        11LL::@@@@................
// [email protected]@..................tLLLLLtttL::....::::......................::@@@@    LLLL::11::@@................
// [email protected]@....LLLL::........tLLLLLLLLLtt........::::::::;ttttttttttttt:i::@@@@@@  [email protected]@@@..................
// [email protected]@..LLtLGGLL::......::tLLLLLLLLL..........::1111:::::::::::::::::[email protected]@[email protected]@@@@@......................
// [email protected]@..LGGGGGGGLL::......::tLLLLL..........tt;1::::::::::::::::::::::@@................................
// [email protected]@..LGGGGGGGGGLL......................tt::::::::::::::::::::::::::@@................................
// [email protected]@..LGGGGGGGGGGG......................::::::::::::::::::::::::::::@@................................
// [email protected]@....LGGGGGGG......................::::LLLL::::::::::::::::::LL::@@................................
// [email protected]@::::................LLLLLL::........::::LCCC::::::::::::::::::::::@@................................
// [email protected]@::::..............::tGGGGGLL::......::::::::::::::LLLLLLLL::::::::::@@..............................
// [email protected]@..:;::............tLLGGGGGGGLL......::::::::::::LLLCCCCCCCLL::::::::@@..............................
// [email protected]@...:::;1::..........LGGGGGGGGGGG....::::::::::::LLLCCCCCCCCCCC::::::::::@@............................

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";

contract Moonhunters is ERC721A, Ownable {
    using Strings for uint256;

    uint256 public maxSupply = 2200;

    uint256 public maxFreeAmount = 1000;

    uint256 public maxFreePerWallet = 1;

    uint256 public maxFreePerTx = 1;

    uint256 public price = 0.005 ether;

    uint256 public maxPerTx = 5;

    string public baseURI;

    bool public mintEnabled;

    mapping(address => uint256) private _mintedFreeAmount;

    constructor() ERC721A("Moonhunters", "Moonhunters") {
        _safeMint(msg.sender, 10);
    }

    function mint(uint256 amount) external payable {
        uint256 cost = price;
        uint256 num = amount > 0 ? amount : 1;
        bool free = ((totalSupply() + num < maxFreeAmount + 1) &&
            (_mintedFreeAmount[msg.sender] + num <= maxFreePerWallet));
        if (free) {
            cost = 0;
            _mintedFreeAmount[msg.sender] += num;
            require(num < maxFreePerTx + 1, "Max per TX reached.");
        } else {
            require(num < maxPerTx + 1, "Max per TX reached.");
        }

        require(mintEnabled, "Minting is not live yet.");
        require(msg.value >= num * cost, "Please send the exact amount.");
        require(totalSupply() + num < maxSupply + 1, "No more");

        _safeMint(msg.sender, num);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function setPrice(uint256 _newPrice) external onlyOwner {
        price = _newPrice;
    }

    function setMaxPerTx(uint256 _amount) external onlyOwner {
        maxPerTx = _amount;
    }

    function setMaxFreeAmount(uint256 _amount) external onlyOwner {
        maxFreeAmount = _amount;
    }

    function setMaxFreePerWallet(uint256 _amount) external onlyOwner {
        maxFreePerWallet = _amount;
    }

    function flipSale() external onlyOwner {
        mintEnabled = !mintEnabled;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Transfer failed.");
    }
}