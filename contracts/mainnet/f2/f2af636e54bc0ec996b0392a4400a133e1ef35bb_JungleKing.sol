// JungleKing

// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@          @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@          @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@      @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@  @@@@@@@@@@@@@@@@@@@@@@@@@@@@ @@@@@  @@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@   (((((@ @@***@@@@***@@****  @((    @ @@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@       ((****@@**************@@*@*    @ @@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@ *   *****@***@******@**@@@@**@******  @@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@***************@@@@**@@@*********@ @@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@ @*%****@@%%*********  **  ********%@*@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@    @*%@****@@@(((         **      ((((@@*@ @@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@ @****%%***@**** @@@@@@((((***(((@@@@@ ****%* @@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@  @@@****%%@@******  @@@**%%**%%**@@@ ***@%% @@@ @@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@   @#    **%@@@@@@%%%****@@@@@@****%%%%%    ##@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@   @@@#       %*@@**** @@@@@@ **@***%% ##@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@  @@#    %*********   @   *******@@   @@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@   @@@#  %%        @@*@@      @@ @@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@ ## ##     @@@@***             @@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@ @@@@*#######          #####   @@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@          @@   ## #####@@  %%    @@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@   %%%@                       %%  @@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@ %%%@   %%@@@@@@@@@ %%          @@% @@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@ %@@  @                   @%%  @%  @@ @@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@  @    %%%              @        @@  @@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@    %%%@           @@@%%          @@%   @@@@@@@@@@@@@@@@@@@

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";

contract JungleKing is ERC721A, Ownable {
    using Strings for uint256;

    uint256 public maxSupply = 10000;

    uint256 public maxFreePerWallet = 2;

    uint256 public price = 0.005 ether;

    uint256 public maxPerTx = 10;

    string public baseURI =
        "https://bucketjungleking.s3.us-east-2.amazonaws.com/json/";

    bool public mintEnabled = true;

    constructor() ERC721A("JungleKing", "JK") {
        _safeMint(msg.sender, 10);
    }

    function mint(uint256 amount) external payable {
        uint256 userMinted = _numberMinted(msg.sender);
        uint256 requiredValueNum = amount;

        if (userMinted < maxFreePerWallet) {
            if (amount < maxFreePerWallet) {
                requiredValueNum = 0;
            } else {
                requiredValueNum -= (maxFreePerWallet - userMinted);
            }
        }

        uint256 requiredValue = requiredValueNum * price;

        require(msg.value >= requiredValue, "Please send the exact amount.");

        require(amount < maxPerTx + 1, "Max per TX reached.");

        require(mintEnabled, "Minting is not live yet.");

        _safeMint(msg.sender, amount);
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