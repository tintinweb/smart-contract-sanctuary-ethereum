// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";
import "./IERC20.sol";

/** @dev Contract definition */

contract ContractNFT is ERC721, ERC721Enumerable, Ownable, ReentrancyGuard {
    /** @dev Contract constructor. Defines mapping between index and atributes.*/
    constructor() ERC721("ContractNFT", "ContractNFT") {
        AttributesMap["SpeciesIndex"] = [ "Hippo", "Elephant", "Lion", "Giraffe", "Monkey", "Crocodile" ];
        AttributesMap["TailIndex"] = ["Blue", "Brown", "Green", "Grey", "Light Grey", "Orange", "Pink", "Purple", "Red", "White", "Gold" ];
        AttributesMap["HeadIndex"] = [ "Blue","Brown", "Green", "Grey", "Light Grey", "Orange", "Pink", "Purple", "Red", "White", "Gold" ];
        AttributesMap["EyeIndex"] = [ "Blue","Brown","Green","Grey", "Light Grey", "Orange", "Pink", "Purple", "Red", "Cat", "Yellow" ];
        AttributesMap["BodyIndex"] = [ "Blue", "Brown", "Green", "Grey", "Light Grey", "Orange", "Pink", "Purple", "Red", "White", "Gold" ];
        AttributesMap["ShirtIndex"] = [ "No Shirt", "Black Long Sleeve", "Black Buttoned", "Black T Shirt", "Blue Long Sleeve", "Blue Buttoned", "Blue T Shirt", "Tan Long Sleeve", "Tan Buttoned", "Tan T Shirt", "Green Long Sleeve", "Green Buttoned", "Green T Shirt", "Grey Long Sleeve", "Grey Buttoned", "Grey T Shirt", "Khaki Long Sleeve", "Khaki Buttoned", "Khaki T Shirt", "Orange Long Sleeve", "Orange Buttoned", "Orange T Shirt", "Pink Long Sleeve", "Pink Buttoned", "Pink T Shirt", "Purple Long Sleeve", "Purple Buttoned", "Purple T Shirt", "Red Long Sleeve", "Red Buttoned", "Red T Shirt", "White Long Sleeve", "White Buttoned", "White T Shirt", "Yellow Long Sleeve", "Yellow Buttoned", "Yellow T Shirt" ];
        AttributesMap["PantsIndex"] = [ "No Pants", "Black Belt", "Black Jeans", "Black Shorts", "Blue Belt", "Blue Jeans", "Blue Shorts", "Brown Belt", "Brown Jeans", "Brown Shorts", "Green Belt", "Green Jeans", "Green Shorts", "Grey Belt", "Grey Jeans", "Grey Shorts", "Kakhis Belt", "Kakhis Jeans", "Kakhis Shorts", "Orange Belt", "Orange Jeans", "Orange Shorts", "Pink Belt", "Pink Jeans", "Pink Shorts", "Purple Belt", "Purple Jeans", "Purple Shorts", "Red Belt", "Red Jeans", "Red Shorts", "White Belt", "White Jeans", "White Shorts", "Yellow Belt", "Yellow Jeans", "Yellow Shorts"];
        AttributesMap["ShirtPatternIndex"] = [ "No Pattern", "Black Flower", "Black Star", "Black Wave", "Blue Flower", "Blue Star", "Blue Wave", "Brown Flower", "Brown Star", "Brown Wave", "Green Flower", "Green Star", "Green Waves", "Grey Flower", "Grey Star", "Grey Wave", "Kakhi Flower", "Kakhi Star", "Kakhi Wave", "Orange Flower", "Orange Star", "Orange Wave", "Pink Flower", "Pink Star", "Pink Wave", "Purple Flower", "Purple Star", "Purple Wave", "Red Flower", "Red Star", "Red Wave", "White Flower", "White Star", "White Wave", "Yellow Flower", "Yellow Star", "Yellow Wave"];
        AttributesMap["ShoeIndex"] = [ "No Shoe", "Shoes and Socks", "Shoes", "Sandals", "Sandals and Socks", "Sneakers and Socks", "Boots"];
        AttributesMap["GlassesIndex"] = [ "No Glasses", "Black", "Blue", "Tan", "Clear", "Green", "Grey", "Orange", "Pink", "Purple", "Red", "White", "Yellow"];
        AttributesMap["HatIndex"] = ["No Hat","Hat"];
        AttributesMap["LionsManeIndex"] = [ "No Mane", "Blue", "Brown", "Green", "Grey", "Light Grey", "Orange", "Pink", "Purple", "Red", "White", "Gold"];

        NameMapAddress["SpeciesIndex"] = 0;
        NameMapAddress["TailIndex"] = 1;
        NameMapAddress["HeadIndex"] = 2;
        NameMapAddress["EyeIndex"] = 3;
        NameMapAddress["BodyIndex"] = 4;
        NameMapAddress["ShirtIndex"] = 5;
        NameMapAddress["PantsIndex"] = 6;
        NameMapAddress["ShirtPatternIndex"] = 7;
        NameMapAddress["ShoeIndex"] = 8;
        NameMapAddress["GlassesIndex"] = 9;
        NameMapAddress["HatIndex"] = 10;
        NameMapAddress["LionsManeIndex"] = 11;
    }

    /** @dev Mapping between index and atributes.*/
    mapping(string => uint8) NameMapAddress;

    mapping(string => string[]) AttributesMap;

    /** @dev Structure contraining an nft.*/
    struct NFT {
        uint8[12] Values;
    }

    /** @dev Devs' addresses. Where token will be sent when withdraw is called.*/
    address payable[5] withdrawAddresses = [
        payable(0xFA167F0b067aD4211632D939207a327e734B26C7),
        payable(0xC1E950c6B96C7af3c92b63529459B70A396Ca789),
        payable(0x0E31Df532b86755fE7E8a467aBC4aFdde0ccF8F7),
        payable(0x0A2cEb457115fEbf127D6A1902361A2E30949aFd),
        payable(0xd6D28EFe258579f416916c89F2E9D54Eb54Ac288)
    ];

    /** @dev Devs' per thousand tokens sent when withdraw is called.*/
    uint16[5] private perThousandPerAddress = [25, 25, 25, 25, 900];

    /** @dev Limit of number of token minted per transaction.*/
    uint32 public maxNFTMintingForBulk = 100; //

    /** @dev Price for miniting one NFT, in wei.*/
    uint256 public price = 225e18;

    /** @dev Extension of base URI. Used to move metadata files if needed.*/
    string private _baseURIextended;

    /** @dev Max number of NFTs to mint.*/
    uint16 NFTsLimit = 20_000;

    /** @dev Array containing minting NFTs.*/
    NFT[] private allNFTs;

    /** @dev mapping to check an NFT already exists.*/
    mapping(string => bool) public existingNFTs;

    /** @dev _beforeTokenTransfer must be overriden to make compiler happy.*/
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /** @dev Changing baseUri to move metadata files and images if needed.*/
    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURIextended = baseURI_;
    }

    /** @dev Changing miniting price if needed.*/
    function setPrice(uint256 newPrice) external onlyOwner {
        price = newPrice;
    }

    /** @dev Override of _baseUri().*/
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    /** @dev Override of supportsInterface().*/
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /** @dev withdrawing tokens received from miniting price.*/
    function withdraw() public {
        uint256 balance = address(this).balance;
        uint256 remainingBalance = balance;
        for (uint8 i = 0; i < withdrawAddresses.length - 1; i++) {
            uint256 valueToTransfer = (perThousandPerAddress[i] * balance) /
                1000;
            withdrawAddresses[i].transfer(valueToTransfer);
            remainingBalance -= valueToTransfer;
        }
        withdrawAddresses[withdrawAddresses.length - 1].transfer(
            remainingBalance
        );
    }

    /** @dev withdrawing tokens of an IERC contract.*/
    function withdrawToken(address _tokenContract) public {
        IERC20 tokenContract = IERC20(_tokenContract);
        uint256 balance = tokenContract.balanceOf(address(this));
        uint256 remainingBalance = balance;
        require(remainingBalance > 0, "Threr is no token to withdraw.");
        for (uint8 i = 0; i < withdrawAddresses.length - 1; i++) {
            uint256 valueToTransfer = (perThousandPerAddress[i] * balance) /
                1000;
            tokenContract.transfer(withdrawAddresses[i], valueToTransfer);
            remainingBalance -= valueToTransfer;
        }
        tokenContract.transfer(
            withdrawAddresses[withdrawAddresses.length - 1],
            remainingBalance
        );
    }

    /** @dev Get the number of NFTs already minted.*/
    function getNextNftMintedNumber() public view returns (uint256) {
        return allNFTs.length;
    }

    /** @dev Get attributes of an NFT.*/
    function getNftAttributes(uint256 id)
        external
        view
        returns (string memory)
    {
        require(id < allNFTs.length, "This NFT have never been minted");
        NFT memory currentNFT = allNFTs[id];
        string[26] memory to_concat = [
            "{",
            '"Species" :',
            AttributesMap["SpeciesIndex"][
                currentNFT.Values[NameMapAddress["SpeciesIndex"]]
            ],
            ', "Tail Color":',
            AttributesMap["TailIndex"][
                currentNFT.Values[NameMapAddress["TailIndex"]]
            ],
            ', "Head Color" :',
            AttributesMap["HeadIndex"][
                currentNFT.Values[NameMapAddress["HeadIndex"]]
            ],
            ',"Eye Color":',
            AttributesMap["EyeIndex"][
                currentNFT.Values[NameMapAddress["EyeIndex"]]
            ],
            ',"Body Color" :',
            AttributesMap["BodyIndex"][
                currentNFT.Values[NameMapAddress["BodyIndex"]]
            ],
            ',"Shirt" :',
            AttributesMap["ShirtIndex"][
                currentNFT.Values[NameMapAddress["ShirtIndex"]]
            ],
            ',"Pants" :',
            AttributesMap["PantsIndex"][
                currentNFT.Values[NameMapAddress["PantsIndex"]]
            ],
            ',"Shirt Pattern" :',
            AttributesMap["ShirtPatternIndex"][
                currentNFT.Values[NameMapAddress["ShirtPatternIndex"]]
            ],
            ',"Shoes" :',
            AttributesMap["ShoeIndex"][
                currentNFT.Values[NameMapAddress["ShoeIndex"]]
            ],
            ', "Glasses" :',
            AttributesMap["GlassesIndex"][
                currentNFT.Values[NameMapAddress["GlassesIndex"]]
            ],
            ',"Hat" : ',
            AttributesMap["HatIndex"][
                currentNFT.Values[NameMapAddress["HatIndex"]]
            ],
            ',"Lions Mane" : ',
            AttributesMap["LionsManeIndex"][
                currentNFT.Values[NameMapAddress["LionsManeIndex"]]
            ],
            "}"
        ];
        string memory toReturn = "";
        for (uint8 i = 0; i < to_concat.length; i++) {
            toReturn = string(abi.encodePacked(toReturn, to_concat[i]));
        }
        return toReturn;
    }

    /** @dev Getter for an NFT, only used to recreate image from the website if needed.*/
    function getNftIndices(uint256 id) external view returns (string memory) {
        require(id < allNFTs.length, "This NFT have never been minted");
        NFT memory currentNFT = allNFTs[id];
        string[26] memory to_concat = [
            "{",
            '"SpeciesIndex" :',
            Strings.toString(currentNFT.Values[NameMapAddress["SpeciesIndex"]]),
            ', "TailIndex":',
            Strings.toString(currentNFT.Values[NameMapAddress["TailIndex"]]),
            ', "HeadIndex" :',
            Strings.toString(currentNFT.Values[NameMapAddress["HeadIndex"]]),
            ',"EyeIndex":',
            Strings.toString(currentNFT.Values[NameMapAddress["EyeIndex"]]),
            ',"BodyIndex" :',
            Strings.toString(currentNFT.Values[NameMapAddress["BodyIndex"]]),
            ',"ShirtIndex" :',
            Strings.toString(currentNFT.Values[NameMapAddress["ShirtIndex"]]),
            ',"PantsIndex" :',
            Strings.toString(currentNFT.Values[NameMapAddress["PantsIndex"]]),
            ',"ShirtPatternIndex" :',
            Strings.toString(
                currentNFT.Values[NameMapAddress["ShirtPatternIndex"]]
            ),
            ',"ShoeIndex" :',
            Strings.toString(currentNFT.Values[NameMapAddress["ShoeIndex"]]),
            ', "GlassesIndex" :',
            Strings.toString(currentNFT.Values[NameMapAddress["GlassesIndex"]]),
            ',"HatIndex" : ',
            Strings.toString(currentNFT.Values[NameMapAddress["HatIndex"]]),
            ',"LionsManeIndex" : ',
            Strings.toString(
                currentNFT.Values[NameMapAddress["LionsManeIndex"]]
            ),
            "}"
        ];
        string memory toReturn = "";
        for (uint8 i = 0; i < to_concat.length; i++) {
            toReturn = string(abi.encodePacked(toReturn, to_concat[i]));
        }
        return toReturn;
    }

    /** @dev Convert a list of values representing an NFT to a string.*/
    function convertToString(uint8[12] memory values)
        private
        view
        returns (string memory)
    {
        string[12] memory to_concat = [
            Strings.toString(values[NameMapAddress["SpeciesIndex"]]),
            Strings.toString(values[NameMapAddress["TailIndex"]]),
            Strings.toString(values[NameMapAddress["HeadIndex"]]),
            Strings.toString(values[NameMapAddress["EyeIndex"]]),
            Strings.toString(values[NameMapAddress["BodyIndex"]]),
            Strings.toString(values[NameMapAddress["ShirtIndex"]]),
            Strings.toString(values[NameMapAddress["PantsIndex"]]),
            Strings.toString(values[NameMapAddress["ShirtPatternIndex"]]),
            Strings.toString(values[NameMapAddress["ShoeIndex"]]),
            Strings.toString(values[NameMapAddress["GlassesIndex"]]),
            Strings.toString(values[NameMapAddress["HatIndex"]]),
            Strings.toString(values[NameMapAddress["LionsManeIndex"]])
        ];
        string memory toReturn = "";
        for (uint8 i = 0; i < to_concat.length; i++) {
            toReturn = string(abi.encodePacked(toReturn, to_concat[i]));
        }
        return toReturn;
    }

    /** @dev Mint an NFT.*/
    function mint(uint8[12] memory values) public payable nonReentrant {
        require(
            msg.value >= price,
            string(
                abi.encodePacked(
                    "You must send ",
                    Strings.toString(price),
                    "wei to mint a token."
                )
            )
        );
        require(
            allNFTs.length < NFTsLimit,
            "All NFTs have already been minted"
        );
        require(
            values[NameMapAddress["SpeciesIndex"]] <
                AttributesMap["SpeciesIndex"].length &&
                values[NameMapAddress["TailIndex"]] <
                AttributesMap["TailIndex"].length &&
                values[NameMapAddress["HeadIndex"]] <
                AttributesMap["HeadIndex"].length &&
                values[NameMapAddress["EyeIndex"]] <
                AttributesMap["EyeIndex"].length &&
                values[NameMapAddress["BodyIndex"]] <
                AttributesMap["BodyIndex"].length &&
                values[NameMapAddress["ShirtIndex"]] <
                AttributesMap["ShirtIndex"].length &&
                values[NameMapAddress["PantsIndex"]] <
                AttributesMap["PantsIndex"].length &&
                values[NameMapAddress["ShirtPatternIndex"]] <
                AttributesMap["ShirtPatternIndex"].length &&
                values[NameMapAddress["ShoeIndex"]] <
                AttributesMap["ShoeIndex"].length &&
                values[NameMapAddress["GlassesIndex"]] <
                AttributesMap["GlassesIndex"].length &&
                values[NameMapAddress["HatIndex"]] <
                AttributesMap["HatIndex"].length &&
                values[NameMapAddress["LionsManeIndex"]] <
                AttributesMap["LionsManeIndex"].length,
            "Index of attributes out of bounds"
        );
        string memory valuesAsString = convertToString(values);
        require(!existingNFTs[valuesAsString]);
        allNFTs.push(NFT(values));
        uint256 id = allNFTs.length - 1;
        existingNFTs[valuesAsString] = true;
        _safeMint(msg.sender, id);
    }

    /** @dev Mint mutliple NFTs as once.*/
    function bulkMint(uint8[12][] memory NFTIndices)
        public
        payable
        nonReentrant
    {
        uint256 NumberNFTsToMint = NFTIndices.length;

        require(
            maxNFTMintingForBulk >= NumberNFTsToMint,
            string(
                abi.encodePacked(
                    "You can't mint more than ",
                    Strings.toString(maxNFTMintingForBulk),
                    " NFTs."
                )
            )
        );
        require(
            msg.value >= price * NumberNFTsToMint,
            string(
                abi.encodePacked(
                    "You must send ",
                    Strings.toString(price * NumberNFTsToMint),
                    " wei to mint a token."
                )
            )
        );
        require(
            allNFTs.length + NumberNFTsToMint <= NFTsLimit,
            "Number of NFTs to mint is higher than maximum mintable NFTs"
        );
        for (uint16 index = 0; index < NumberNFTsToMint; index++) {
            require(
                NFTIndices[index][NameMapAddress["SpeciesIndex"]] <
                    AttributesMap["SpeciesIndex"].length &&
                    NFTIndices[index][NameMapAddress["TailIndex"]] <
                    AttributesMap["TailIndex"].length &&
                    NFTIndices[index][NameMapAddress["HeadIndex"]] <
                    AttributesMap["HeadIndex"].length &&
                    NFTIndices[index][NameMapAddress["EyeIndex"]] <
                    AttributesMap["EyeIndex"].length &&
                    NFTIndices[index][NameMapAddress["BodyIndex"]] <
                    AttributesMap["BodyIndex"].length &&
                    NFTIndices[index][NameMapAddress["ShirtIndex"]] <
                    AttributesMap["ShirtIndex"].length &&
                    NFTIndices[index][NameMapAddress["PantsIndex"]] <
                    AttributesMap["PantsIndex"].length &&
                    NFTIndices[index][NameMapAddress["ShirtPatternIndex"]] <
                    AttributesMap["ShirtPatternIndex"].length &&
                    NFTIndices[index][NameMapAddress["ShoeIndex"]] <
                    AttributesMap["ShoeIndex"].length &&
                    NFTIndices[index][NameMapAddress["GlassesIndex"]] <
                    AttributesMap["GlassesIndex"].length &&
                    NFTIndices[index][NameMapAddress["HatIndex"]] <
                    AttributesMap["HatIndex"].length &&
                    NFTIndices[index][NameMapAddress["LionsManeIndex"]] <
                    AttributesMap["LionsManeIndex"].length,
                "Index of attributes out of bounds"
            );
            NFT memory toMint = NFT(NFTIndices[index]);
            string memory valuesAsString = convertToString(NFTIndices[index]);
            require(!existingNFTs[valuesAsString]);
            allNFTs.push(toMint);
            uint256 id = allNFTs.length - 1;
            existingNFTs[valuesAsString] = true;
            _safeMint(msg.sender, id);
        }
    }
}