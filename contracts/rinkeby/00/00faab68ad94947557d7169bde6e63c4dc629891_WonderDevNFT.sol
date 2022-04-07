// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.7;
import "./ERC721.sol";
import "./Ownable.sol";
import "./ERC2981.sol";

contract WonderDevNFT is ERC721, Ownable, ERC2981 {
    using SafeMath for uint256;

    string public WonderDevNFT_PROVENANCE = "";

    uint256 public constant chimsPrice = 0.01 ether; //0.01 ETH

    uint256 public constant maxChimsPurchase = 10;

    uint256 public MAX_WonderDevNFT_NFT = 1000;

    bool public saleIsActive = true;

    event SetBaseURI(string _baseUrl);
    event EventMintNFT(address _minter, uint256[] _numberOfTokens);

    constructor() ERC721("Wonder DEV VNFT", "DNFT") {
        _setDefaultRoyalty(msg.sender, 5000);
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    /*
     * Set provenance once it's calculated
     */
    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        WonderDevNFT_PROVENANCE = provenanceHash;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _setBaseURI(baseURI);
        emit SetBaseURI(baseURI);
    }

    /*
     * Pause sale if active, make active if paused
     */
    function enableMinting() external onlyOwner {
        saleIsActive = true;
    }

    function disableMinting() external onlyOwner {
        saleIsActive = false;
    }

    /**
     * Mints Wonder Dev DNFT
     */
    function mintWonderDevNFT(uint256[] memory numberOfTokens) public payable {
        require(saleIsActive, "Sale must be active to mint WONDER Dev DNFT");
        require(
            numberOfTokens.length <= maxChimsPurchase,
            "Can only mint 20 tokens at a time"
        );
        require(
            totalSupply().add(numberOfTokens.length) <= MAX_WonderDevNFT_NFT,
            "Purchase would exceed max supply of WONDER Dev DNFT"
        );
        require(
            chimsPrice.mul(numberOfTokens.length) <= msg.value,
            "Ether value sent is not correct"
        );

        for (uint256 i = 0; i < numberOfTokens.length; i++) {
            uint256 mintIndex = numberOfTokens[i];
            if (totalSupply() <= MAX_WonderDevNFT_NFT) {
                require(
                    !_exists(mintIndex),
                    string(
                        abi.encodePacked(
                            "Wonder Dev DNFT: token id ",
                            Strings.toString(mintIndex),
                            " already minted"
                        )
                    )
                );
                _safeMint(msg.sender, mintIndex);
            }
        }

        emit EventMintNFT(msg.sender, numberOfTokens);
    }

    /**
     * GET ALL NFT OF A WALLET AS AN ARRAY OF STRINGS.
     * It WOULD BE BETTER MAYBE IF IT RETURNED WITH ID-NAME
     **/
    function tokensOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    function destroySmartContract() public payable onlyOwner {
        address payable addr = payable(address(msg.sender));
        selfdestruct(addr);
    }
}