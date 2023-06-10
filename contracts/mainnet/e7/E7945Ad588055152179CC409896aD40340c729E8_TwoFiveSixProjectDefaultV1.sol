// SPDX-License-Identifier: MIT

/* 

██████╗ ███████╗ ██████╗ 
╚════██╗██╔════╝██╔════╝ 
 █████╔╝███████╗███████╗ 
██╔═══╝ ╚════██║██╔═══██╗
███████╗███████║╚██████╔╝
╚══════╝╚══════╝ ╚═════╝ 

Using this contract? 
A shout out to @Mint256Art is appreciated!
 */
pragma solidity ^0.8.19;

import "./helpers/SSTORE2.sol";
import "./helpers/OwnableUpgradeable.sol";
import "./helpers/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/Base64Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";

contract TwoFiveSixProjectDefaultV1 is
    ERC721EnumerableUpgradeable,
    OwnableUpgradeable
{
    mapping(uint256 => bytes32) public tokenIdToHash;
    mapping(address => TotalAndCount) private addressToTotalAndCount;
    mapping(address => bool) private addressToClaimed;

    struct Project {
        string name; //unknown
        string imageBase; //unkown
        address[] artScripts; //unknown
        bytes32 merkleRoot; //32
        address artInfo; //20
        uint56 biddingStartTimeStamp; //8
        uint32 maxSupply; //4
        address payable artistAddress; //20
        uint56 allowListStartTimeStamp; //8
        uint32 totalAllowListMints; //4
        address payable twoFiveSix; //20
        uint24 artistAuctionWithdrawalsClaimed; //3
        uint24 artistAllowListWithdrawalsClaimed; //3
        uint24 twoFiveSixShare; //3
        uint24 royalty; //3
        address traits; //20
        uint96 reservePrice; //12
        address payable royaltyAddress; //20
        uint96 lastSalePrice; //12
        address libraryScripts; //20
        uint56 endingTimeStamp; //8
        uint24 thirdPartyShare; //3
        bool fixedPrice; //1
        address payable thirdPartyAddress; //20
    }
    struct Trait {
        string name;
        string[] values;
        string[] descriptions;
        uint256[] weights;
    }

    struct TotalAndCount {
        uint128 total;
        uint128 count;
    }
    struct LibraryScript {
        address fileStoreFrontEnd;
        address fileStore;
        string fileName;
    }
    Project private project;

    /**
     * @notice Initializes the project.
     * @dev Initializes the ERC721 contract.
     * @param _p The project data.
     */
    function initProject(
        Project calldata _p,
        address _traits,
        address _libraryScripts
    ) public initializer {
        __ERC721_init(_p.name, "256ART");
        __Ownable_init(_p.artistAddress);
        project = _p;

        if (_traits != address(0)) {
            project.traits = _traits;
        }
        if (_libraryScripts != address(0)) {
            project.libraryScripts = _libraryScripts;
        }
    }

    /**
     * @notice Gets the current price.
     */
    function currentPrice() public view returns (uint256 p) {
        require(
            block.timestamp > project.biddingStartTimeStamp,
            "Mint not started"
        );
        require(block.timestamp < project.endingTimeStamp, "Mint ended");

        uint256 timeElapsed = block.timestamp - project.biddingStartTimeStamp;
        uint256 price;
        if (timeElapsed < 3600 && !project.fixedPrice) {
            price =
                (((((project.reservePrice * 15 ** 8) / (10 ** 8)) /
                    (15 ** (timeElapsed / 450))) *
                    (10 ** (timeElapsed / 450))) / 10 ** 14) *
                10 ** 14;
            return price;
        } else {
            return project.reservePrice;
        }
    }

    /**
     * @notice Mint tokens to an address (artist only)
     * @dev Mints a given number of tokens to a specified address. Can only be called by the project owner.
     * @param count The number of tokens to be minted.
     * @param a The address to which the tokens will be minted.
     */
    function artistMint(uint24 count, address a) public onlyOwner {
        uint256 totalSupply = _owners.length;
        require(totalSupply + count < project.maxSupply, "Minted out");
        require(block.timestamp < project.endingTimeStamp, "Mint ended");
        require(count < 5, "Mint max four per tx");
        if (!project.fixedPrice) {
            require(
                ((block.timestamp > project.biddingStartTimeStamp + 3600) ||
                    (block.timestamp < project.biddingStartTimeStamp)),
                "No artist mint during auction"
            );
        }

        for (uint256 i; i < count; ) {
            unchecked {
                uint256 tokenId = totalSupply + i;
                tokenIdToHash[tokenId] = createHash(
                    tokenId,
                    project.artistAddress
                );
                _mint(a, tokenId);
                i++;
            }
        }
        unchecked {
            project.artistAuctionWithdrawalsClaimed =
                project.artistAuctionWithdrawalsClaimed +
                count;
        }
    }

    /**
     * @notice Mint a token to an allow listed address if conditions met.
     * @dev Mints a token to a specified address if that address is on the project's allow list and has not already claimed a token.
     * @param proof The proof of inclusion in the project's Merkle tree.
     * @param a The address to which the token will be minted.
     */
    function allowListMint(bytes32[] memory proof, address a) public payable {
        require(
            block.timestamp > project.allowListStartTimeStamp,
            "Allow list mint not started"
        );
        require(
            block.timestamp < project.biddingStartTimeStamp,
            "Allow list mint ended"
        );
        require(
            MerkleProofUpgradeable.verify(
                proof,
                project.merkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Not on allow list"
        );
        require(addressToClaimed[msg.sender] == false, "Already claimed");

        uint256 totalSupply = _owners.length;

        require(totalSupply + 1 < project.maxSupply, "Minted out");
        require(project.reservePrice <= msg.value, "Invalid funds provided");
        require(msg.sender == tx.origin, "No contract minting");

        unchecked {
            uint256 tokenId = totalSupply;
            addressToClaimed[msg.sender] = true;
            project.totalAllowListMints = project.totalAllowListMints + 1;
            tokenIdToHash[tokenId] = createHash(tokenId, msg.sender);
            _mint(a, tokenId);
        }
    }

    /**
     * @notice Mint tokens to an address through a Dutch auction until reserve price is met, while checking for various conditions.
     * @dev Mints a given number of tokens to a specified address through a Dutch auction process that ends when the reserve price is met. Also checks various conditions such as max supply, minimum and maximum number of tokens that can be minted per transaction, and that the sender is not a contract.
     * @param count The number of tokens to be minted.
     * @param a The address to which the tokens will be minted.
     */
    function mint(uint128 count, address a) public payable {
        uint256 totalSupply = _owners.length;
        uint256 price = currentPrice();
        uint256 total = count * price;
        require(totalSupply + count < project.maxSupply, "Minted out");
        require(count > 0, "Mint at least one");
        require(count < 5, "Mint max four per tx");
        require(total <= msg.value, "Invalid funds provided");
        require(msg.sender == tx.origin, "No contract minting");

        if (price != project.reservePrice) {
            addressToTotalAndCount[a] = TotalAndCount(
                uint128(addressToTotalAndCount[a].total + msg.value),
                addressToTotalAndCount[a].count + count
            );
        }

        if (
            totalSupply + count == project.maxSupply - 1 && !project.fixedPrice
        ) {
            project.lastSalePrice = uint96(price);
        }

        for (uint256 i; i < count; ) {
            unchecked {
                uint256 tokenId = totalSupply + i;

                tokenIdToHash[tokenId] = createHash(tokenId, msg.sender);

                _mint(a, tokenId);
                i++;
            }
        }
    }

    /**
     * @notice Claim a rebate for each token minted at a higher price than the final price
     * @param a The address to which the rebate is paid.
     */
    function claimRebate(address payable a) public {
        require(
            block.timestamp > project.biddingStartTimeStamp + 3600,
            "Rebate phase not started"
        );
        uint256 finalPrice;

        if (
            _owners.length < (project.maxSupply - 1) ||
            project.lastSalePrice == 0
        ) {
            finalPrice = project.reservePrice;
        } else {
            finalPrice = project.lastSalePrice;
        }

        uint256 rebate = addressToTotalAndCount[msg.sender].total -
            (addressToTotalAndCount[msg.sender].count * finalPrice);

        delete addressToTotalAndCount[msg.sender];
        a.transfer(rebate);
    }

    /**
     * @notice Create a hash for the given tokenId, blockNumber and sender.
     * @param tokenId The ID of the token.
     * @param sender The address of the sender.
     * @return The resulting hash.
     */
    function createHash(
        uint256 tokenId,
        address sender
    ) private view returns (bytes32) {
        unchecked {
            return
                keccak256(
                    abi.encodePacked(
                        tokenId,
                        sender,
                        blockhash(block.number - 1),
                        blockhash(block.number - 2),
                        blockhash(block.number - 4),
                        block.prevrandao,
                        block.coinbase
                    )
                );
        }
    }

    /**
     * @notice Get the hash associated with a given tokenId.
     * @param _id The ID of the token.
     * @return The hash associated with the given tokenId.
     */
    function getHashFromTokenId(uint256 _id) public view returns (bytes32) {
        return tokenIdToHash[_id];
    }

    /**
     * @notice Withdraw funds from the contract
     * @dev Transfers a percentage of the balance to the 256ART address and optionally a third party, the rest to the artist address.
     */
    function withdraw() public {
        require(
            (msg.sender == project.twoFiveSix ||
                msg.sender == project.artistAddress ||
                msg.sender == project.thirdPartyAddress),
            "Not allowed"
        );

        uint256 totalSupply = _owners.length;

        uint256 finalPrice;
        uint256 balance;

        if (project.fixedPrice) {
            balance = address(this).balance;
        } else {
            require(
                block.timestamp > project.biddingStartTimeStamp + 3600,
                "Auction still in progress"
            );
            if (
                _owners.length < (project.maxSupply - 1) ||
                project.lastSalePrice == 0
            ) {
                finalPrice = project.reservePrice;
            } else {
                finalPrice = project.lastSalePrice;
            }
            balance =
                ((totalSupply -
                    project.totalAllowListMints -
                    project.artistAuctionWithdrawalsClaimed) * finalPrice) +
                ((project.totalAllowListMints -
                    project.artistAllowListWithdrawalsClaimed) *
                    project.reservePrice);
        }

        require(balance > 0, "Balance is zero");

        project.artistAuctionWithdrawalsClaimed = uint24(
            totalSupply - project.totalAllowListMints
        );
        project.artistAllowListWithdrawalsClaimed = uint24(
            project.totalAllowListMints
        );

        if (project.thirdPartyAddress == address(0)) {
            uint256 twoFiveSixBalance = (balance * project.twoFiveSixShare) /
                10000;
            uint256 artistBalance = balance - twoFiveSixBalance;

            project.twoFiveSix.transfer(twoFiveSixBalance);
            project.artistAddress.transfer(artistBalance);
        } else {
            uint256 twoFiveSixBalance = (balance * project.twoFiveSixShare) /
                10000;
            uint256 thirdPartyBalance = (balance * project.thirdPartyShare) /
                10000;
            uint256 artistBalance = balance -
                twoFiveSixBalance -
                thirdPartyBalance;

            project.twoFiveSix.transfer(twoFiveSixBalance);
            project.thirdPartyAddress.transfer(thirdPartyBalance);
            project.artistAddress.transfer(artistBalance);
        }
    }

    function walletOfOwner(
        address _owner
    ) public view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) return new uint256[](0);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function batchTransferFrom(
        address _from,
        address _to,
        uint256[] memory _tokenIds
    ) public {
        for (uint256 i; i < _tokenIds.length; i++) {
            transferFrom(_from, _to, _tokenIds[i]);
        }
    }

    function batchSafeTransferFrom(
        address _from,
        address _to,
        uint256[] memory _tokenIds,
        bytes memory data_
    ) public {
        for (uint256 i; i < _tokenIds.length; i++) {
            safeTransferFrom(_from, _to, _tokenIds[i], data_);
        }
    }

    function isOwnerOf(
        address account,
        uint256[] calldata _tokenIds
    ) external view returns (bool) {
        for (uint256 i; i < _tokenIds.length; ++i) {
            if (_owners[_tokenIds[i]] != account) return false;
        }

        return true;
    }

    function _mint(address to, uint256 tokenId) internal virtual override {
        _owners.push(to);
        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @notice Calculates the royalty information for a given sale.
     * @dev Implements the required royaltyInfo function for the ERC2981 standard.
     * @param _salePrice The sale price of the token being sold.
     * @return receiver The address of the royalty recipient.
     * @return royaltyAmount The amount of royalty to be paid.
     */
    function royaltyInfo(
        uint256,
        uint256 _salePrice
    ) external view returns (address receiver, uint256 royaltyAmount) {
        return (project.royaltyAddress, (_salePrice * project.royalty) / 10000);
    }

    /**
     * @notice Converts a bytes16 value to its hexadecimal representation as a bytes32 value.
     * @param data The bytes16 value to convert.
     * @return result The hexadecimal representation of the input value as a bytes32 value.
     */
    function toHex16(bytes16 data) internal pure returns (bytes32 result) {
        result =
            (bytes32(data) &
                0xFFFFFFFFFFFFFFFF000000000000000000000000000000000000000000000000) |
            ((bytes32(data) &
                0x0000000000000000FFFFFFFFFFFFFFFF00000000000000000000000000000000) >>
                64);
        result =
            (result &
                0xFFFFFFFF000000000000000000000000FFFFFFFF000000000000000000000000) |
            ((result &
                0x00000000FFFFFFFF000000000000000000000000FFFFFFFF0000000000000000) >>
                32);
        result =
            (result &
                0xFFFF000000000000FFFF000000000000FFFF000000000000FFFF000000000000) |
            ((result &
                0x0000FFFF000000000000FFFF000000000000FFFF000000000000FFFF00000000) >>
                16);
        result =
            (result &
                0xFF000000FF000000FF000000FF000000FF000000FF000000FF000000FF000000) |
            ((result &
                0x00FF000000FF000000FF000000FF000000FF000000FF000000FF000000FF0000) >>
                8);
        result =
            ((result &
                0xF000F000F000F000F000F000F000F000F000F000F000F000F000F000F000F000) >>
                4) |
            ((result &
                0x0F000F000F000F000F000F000F000F000F000F000F000F000F000F000F000F00) >>
                8);
        result = bytes32(
            0x3030303030303030303030303030303030303030303030303030303030303030 +
                uint256(result) +
                (((uint256(result) +
                    0x0606060606060606060606060606060606060606060606060606060606060606) >>
                    4) &
                    0x0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F) *
                7
        );
    }

    /**
     * @dev Converts a bytes32 value to its hexadecimal representation as a string.
     * @param data The bytes32 value to convert.
     * @return The hexadecimal representation of the bytes32 value, as a string.
     */
    function toHex(bytes32 data) private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "0x",
                    toHex16(bytes16(data)),
                    toHex16(bytes16(data << 128))
                )
            );
    }

    /**
     * @dev Generates an array of random numbers based on a seed value.
     * @param seed The seed value used to generate the random numbers.
     * @param timesToCall The number of random numbers to generate.
     * @return An array of random numbers with length equal to `timesToCall`.
     */
    function generateRandomNumbers(
        bytes32 seed,
        uint256 timesToCall
    ) private pure returns (uint256[] memory) {
        uint256[] memory randNumbers = new uint256[](timesToCall);

        for (uint256 i; i < timesToCall; i++) {
            uint256 r = uint256(
                keccak256(abi.encodePacked(uint256(seed) + i))
            ) % 10000;
            randNumbers[i] = r;
        }

        return randNumbers;
    }

    /**
     * @notice Returns a string containing base64 encoded HTML code which renders the artwork associated with the given tokenId directly from chain.
     * @dev This function reads traits and libraries from the storage and uses them to generate the HTML code for the artwork.
     * @param tokenId The ID of the token whose artwork will be generated.
     * @return artwork A string containing the base64 encoded HTML code for the artwork.
     */
    function getTokenHtml(
        uint256 tokenId
    ) public view returns (string memory artwork) {
        require(_exists(tokenId), "Token not found");

        bytes32 tokenHash = getHashFromTokenId(tokenId);

        string memory artScript;
        string memory libraryScripts;
        string memory traits;
        string memory blockParams;

        if (project.libraryScripts != address(0)) {
            LibraryScript[] memory librariesArray = abi.decode(
                SSTORE2.read(project.libraryScripts),
                (LibraryScript[])
            );
            for (uint256 l; l < librariesArray.length; l++) {
                IFileStorage fileStoreFrontEnd = IFileStorage(
                    librariesArray[l].fileStoreFrontEnd
                );
                libraryScripts = string.concat(
                    "await ls256('",
                    fileStoreFrontEnd.readFile(
                        librariesArray[l].fileStore,
                        librariesArray[l].fileName
                    ),
                    "');"
                );
            }
        }

        if (project.traits != address(0)) {
            traits = ",";
            Trait[] memory traitsArray = abi.decode(
                SSTORE2.read(project.traits),
                (Trait[])
            );

            uint256[] memory randNumbers = generateRandomNumbers(
                tokenHash,
                traitsArray.length
            );

            for (uint256 j = 0; j < traitsArray.length; j++) {
                uint256 r = randNumbers[j];
                for (uint256 k = 0; k < traitsArray[j].weights.length; k++) {
                    if (r < traitsArray[j].weights[k]) {
                        traits = string.concat(
                            traits,
                            "'",
                            traitsArray[j].name,
                            "'",
                            ":'",
                            traitsArray[j].values[k],
                            "'"
                        );
                        if (j < traitsArray.length - 1) {
                            traits = string.concat(traits, ",");
                        }
                        break;
                    }
                }
            }
        }

        blockParams = string.concat(
            ", 'ownerOfPiece' : '",
            StringsUpgradeable.toHexString(
                uint256(uint160(ownerOf(tokenId))),
                20
            ),
            "', 'blockHash' : '",
            toHex(blockhash(block.number - 1)),
            "', 'blockNumber' : ",
            StringsUpgradeable.toString(block.number),
            ", 'prevrandao' : ",
            StringsUpgradeable.toString(block.prevrandao),
            ", 'totalSupply' : ",
            StringsUpgradeable.toString(_owners.length),
            ", 'balanceOfOwner' : ",
            StringsUpgradeable.toString(balanceOf(ownerOf(tokenId)))
        );

        for (uint256 i; i < project.artScripts.length; i++) {
            IArtScript artscriptToGet = IArtScript(project.artScripts[i]);
            artScript = string.concat(artScript, artscriptToGet.artScript());
        }

        return
            string.concat(
                "data:text/html;base64,",
                Base64Upgradeable.encode(
                    abi.encodePacked(
                        "<html><head><script>let inputData={'tokenId': ",
                        StringsUpgradeable.toString(tokenId),
                        ",'hash': '",
                        toHex(tokenHash),
                        "'",
                        traits,
                        blockParams,
                        "};",
                        "</script>",
                        "<meta name='viewport' content='width=device-width, initial-scale=1, maximum-scale=1'><style type='text/css'>html{height:100%;width:100%;}body{height:100%;width:100%;margin:0;padding:0;background-color:#000000;}canvas{display:block;max-width:100%;max-height:100%;padding:0;margin:auto;display:block;position:absolute;top:0;bottom:0;left:0;right:0;object-fit:contain;}</style>",
                        "</head><body><script defer>async function ls256(e){let t=new TextDecoder,a=window.atob(e),n=a.length,r=new Uint8Array(n);for(var o=0;o<n;o++)r[o]=a.charCodeAt(o);let d=r.buffer;let c=new ReadableStream({start(e){e.enqueue(d),e.close()}}).pipeThrough(new DecompressionStream('gzip')),i=await new Response(c),p=await i.arrayBuffer(),l=await t.decode(p),s=document.createElement('script');s.type='text/javascript',s.appendChild(document.createTextNode(l)),document.body.appendChild(s)};async function la256(){",
                        libraryScripts,
                        "await ls256('",
                        artScript,
                        "');"
                        "};la256();</script></body></html>"
                    )
                )
            );
    }

    /**
     * @notice Returns the metadata of the token with the given ID, including name, artist, description, license, image and animation URL, and attributes.
     * @dev It returns a base64 encoded JSON object which conforms to the ERC721 metadata standard.
     * @param _tokenId The ID of the token to retrieve metadata for.
     * @return A base64 encoded JSON object that contains the metadata of the given token.
     */
    function tokenURI(
        uint256 _tokenId
    ) public view override returns (string memory) {
        require(_exists(_tokenId), "Token not found");

        bytes32 tokenHash = getHashFromTokenId(_tokenId);

        IArtInfo artInfoToGet = IArtInfo(project.artInfo);

        string memory imageBase;
        string memory librariesUsed = ',"libraries_used": "';
        string memory attributes;

        if (bytes(project.imageBase).length != 0) {
            imageBase = string.concat(
                ',"image":"',
                project.imageBase,
                StringsUpgradeable.toString(_tokenId),
                '"'
            );
        }

        if (project.libraryScripts != address(0)) {
            LibraryScript[] memory librariesArray = abi.decode(
                SSTORE2.read(project.libraryScripts),
                (LibraryScript[])
            );
            for (uint256 l; l < librariesArray.length; l++) {
                librariesUsed = string.concat(
                    librariesUsed,
                    librariesArray[l].fileName,
                    " "
                );
            }
        } else {
            librariesUsed = string.concat(librariesUsed, "None");
        }

        if (project.traits != address(0)) {
            Trait[] memory traitsArray = abi.decode(
                SSTORE2.read(project.traits),
                (Trait[])
            );
            uint256[] memory randNumbers = generateRandomNumbers(
                getHashFromTokenId(_tokenId),
                traitsArray.length
            );
            for (uint256 j = 0; j < traitsArray.length; j++) {
                uint256 r = randNumbers[j];
                for (uint256 k = 0; k < traitsArray[j].weights.length; k++) {
                    if (r < traitsArray[j].weights[k]) {
                        attributes = string.concat(
                            attributes,
                            '{"trait_type":"',
                            traitsArray[j].name,
                            '", "value":"',
                            traitsArray[j].descriptions[k],
                            '"}'
                        );
                        if (j < traitsArray.length - 1) {
                            attributes = string.concat(attributes, ",");
                        }
                        break;
                    }
                }
            }
        }

        return
            string.concat(
                "data:application/json;base64,",
                Base64Upgradeable.encode(
                    abi.encodePacked(
                        '{"name":"',
                        project.name,
                        " #",
                        StringsUpgradeable.toString(_tokenId),
                        '", "artist":"',
                        artInfoToGet.artist(),
                        '","description":"',
                        artInfoToGet.description(),
                        '","license":"',
                        artInfoToGet.license(),
                        '","hash":"',
                        toHex(tokenHash),
                        '"',
                        librariesUsed,
                        '"',
                        imageBase,
                        ',"animation_url":"',
                        getTokenHtml(_tokenId),
                        '","attributes":[',
                        attributes,
                        "]}"
                    )
                )
            );
    }

    /**
     * @notice Allows to set the image base URL for the project (owner)
     * @dev Only callable by the owner
     * @param _imageBase String representing the base URL for images
     */
    function setImageBase(string calldata _imageBase) public onlyOwner {
        project.imageBase = _imageBase;
    }

    /**
     * @notice Sets the maximum number of tokens that can be minted for the project (owner)
     * @dev Only the owner of the contract can call this function.
     * @dev The new maximum supply must be greater than the current number of tokens minted
     * and less than the current maximum supply
     * @param _maxSupply The new maximum number of tokens that can be minted
     */
    function setMaxSupply(uint24 _maxSupply) public onlyOwner {
        require(_maxSupply > _owners.length, "Too low");
        require(_maxSupply < project.maxSupply, "Too high");
        project.maxSupply = _maxSupply;
    }

    /**
     * @notice Allows to set the art scripts for the project
     * @param _artScripts Array of addresses representing the art scripts
     */
    function setArtScripts(address[] calldata _artScripts) public onlyOwner {
        project.artScripts = _artScripts;
    }

    /**
     * @notice Allows to set the library scripts for the project
     * @param _libraries Array of LibraryScript objects representing the library scripts
     */
    function setLibraryScripts(
        LibraryScript[] calldata _libraries
    ) public onlyOwner {
        project.libraryScripts = SSTORE2.write(abi.encode(_libraries));
    }

    /**
     * @notice Returns the reserve price for the project
     * @dev This function is view only
     * @return uint256 Representing the reserve price for the project
     */
    function getReservePrice() external view returns (uint256) {
        return project.reservePrice;
    }

    /**
     * @notice Returns the address of the ArtInfo contract used in the project
     * @dev This function is view only
     * @return address Representing the address of the ArtInfo contract
     */
    function getArtInfo() external view returns (address) {
        return project.artInfo;
    }

    /**
     * @notice Returns an array with the addresses storing the art script used in the project
     * @dev This function is view only
     * @return address[] Array of addresses storing the art script used in the project
     */
    function getArtScripts() external view returns (address[] memory) {
        return project.artScripts;
    }

    /**
     * @notice Returns the maximum number of tokens that can be minted for the project
     * @dev This function is view only
     * @return uint256 Representing the maximum number of tokens that can be minted
     */
    function getMaxSupply() external view returns (uint256) {
        return project.maxSupply - 1;
    }

    /**
     * @notice Returns the timestamp of the bidding start for the project
     * @dev This function is view only
     * @return uint256 Representing the timestamp of the bidding start
     */
    function getBiddingStartTimeStamp() external view returns (uint256) {
        return project.biddingStartTimeStamp;
    }

    /**
     * @notice Returns the timestamp of the allowlist start for the project
     * @dev This function is view only
     * @return uint256 Representing the timestamp of the allowlist start
     */
    function getallowListStartTimeStamp() external view returns (uint256) {
        return project.allowListStartTimeStamp;
    }
}

interface IArtScript {
    function artScript() external pure returns (string memory);
}

interface IArtInfo {
    function artist() external pure returns (string memory);

    function description() external pure returns (string memory);

    function license() external pure returns (string memory);
}

interface IFileStorage {
    function readFile(
        address fileStore,
        string calldata filename
    ) external pure returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (finance/PaymentSplitter.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/utils/SafeERC20Upgradeable.sol";
import "../utils/AddressUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @title PaymentSplitter
 * @dev This contract allows to split Ether payments among a group of accounts. The sender does not need to be aware
 * that the Ether will be split in this way, since it is handled transparently by the contract.
 *
 * The split can be in equal parts or in any other arbitrary proportion. The way this is specified is by assigning each
 * account to a number of shares. Of all the Ether that this contract receives, each account will then be able to claim
 * an amount proportional to the percentage of total shares they were assigned. The distribution of shares is set at the
 * time of contract deployment and can't be updated thereafter.
 *
 * `PaymentSplitter` follows a _pull payment_ model. This means that payments are not automatically forwarded to the
 * accounts but kept in this contract, and the actual transfer is triggered as a separate step by calling the {release}
 * function.
 *
 * NOTE: This contract assumes that ERC20 tokens will behave similarly to native tokens (Ether). Rebasing tokens, and
 * tokens that apply fees during transfers, are likely to not be supported as expected. If in doubt, we encourage you
 * to run tests before sending real value to this contract.
 */
contract PaymentSplitterUpgradeable is Initializable, ContextUpgradeable {
    event PayeeAdded(address account, uint256 shares);
    event PaymentReleased(address to, uint256 amount);
    event ERC20PaymentReleased(IERC20Upgradeable indexed token, address to, uint256 amount);
    event PaymentReceived(address from, uint256 amount);

    uint256 private _totalShares;
    uint256 private _totalReleased;

    mapping(address => uint256) private _shares;
    mapping(address => uint256) private _released;
    address[] private _payees;

    mapping(IERC20Upgradeable => uint256) private _erc20TotalReleased;
    mapping(IERC20Upgradeable => mapping(address => uint256)) private _erc20Released;

    /**
     * @dev Creates an instance of `PaymentSplitter` where each account in `payees` is assigned the number of shares at
     * the matching position in the `shares` array.
     *
     * All addresses in `payees` must be non-zero. Both arrays must have the same non-zero length, and there must be no
     * duplicates in `payees`.
     */
    function __PaymentSplitter_init(address[] memory payees, uint256[] memory shares_) internal onlyInitializing {
        __PaymentSplitter_init_unchained(payees, shares_);
    }

    function __PaymentSplitter_init_unchained(address[] memory payees, uint256[] memory shares_) internal onlyInitializing {
        require(payees.length == shares_.length, "PaymentSplitter: payees and shares length mismatch");
        require(payees.length > 0, "PaymentSplitter: no payees");

        for (uint256 i = 0; i < payees.length; i++) {
            _addPayee(payees[i], shares_[i]);
        }
    }

    /**
     * @dev The Ether received will be logged with {PaymentReceived} events. Note that these events are not fully
     * reliable: it's possible for a contract to receive Ether without triggering this function. This only affects the
     * reliability of the events, and not the actual splitting of Ether.
     *
     * To learn more about this see the Solidity documentation for
     * https://solidity.readthedocs.io/en/latest/contracts.html#fallback-function[fallback
     * functions].
     */
    receive() external payable virtual {
        emit PaymentReceived(_msgSender(), msg.value);
    }

    /**
     * @dev Getter for the total shares held by payees.
     */
    function totalShares() public view returns (uint256) {
        return _totalShares;
    }

    /**
     * @dev Getter for the total amount of Ether already released.
     */
    function totalReleased() public view returns (uint256) {
        return _totalReleased;
    }

    /**
     * @dev Getter for the total amount of `token` already released. `token` should be the address of an IERC20
     * contract.
     */
    function totalReleased(IERC20Upgradeable token) public view returns (uint256) {
        return _erc20TotalReleased[token];
    }

    /**
     * @dev Getter for the amount of shares held by an account.
     */
    function shares(address account) public view returns (uint256) {
        return _shares[account];
    }

    /**
     * @dev Getter for the amount of Ether already released to a payee.
     */
    function released(address account) public view returns (uint256) {
        return _released[account];
    }

    /**
     * @dev Getter for the amount of `token` tokens already released to a payee. `token` should be the address of an
     * IERC20 contract.
     */
    function released(IERC20Upgradeable token, address account) public view returns (uint256) {
        return _erc20Released[token][account];
    }

    /**
     * @dev Getter for the address of the payee number `index`.
     */
    function payee(uint256 index) public view returns (address) {
        return _payees[index];
    }

    /**
     * @dev Getter for the amount of payee's releasable Ether.
     */
    function releasable(address account) public view returns (uint256) {
        uint256 totalReceived = address(this).balance + totalReleased();
        return _pendingPayment(account, totalReceived, released(account));
    }

    /**
     * @dev Getter for the amount of payee's releasable `token` tokens. `token` should be the address of an
     * IERC20 contract.
     */
    function releasable(IERC20Upgradeable token, address account) public view returns (uint256) {
        uint256 totalReceived = token.balanceOf(address(this)) + totalReleased(token);
        return _pendingPayment(account, totalReceived, released(token, account));
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of Ether they are owed, according to their percentage of the
     * total shares and their previous withdrawals.
     */
    function release(address payable account) public virtual {
        require(_shares[account] > 0, "PaymentSplitter: account has no shares");

        uint256 payment = releasable(account);

        require(payment != 0, "PaymentSplitter: account is not due payment");

        // _totalReleased is the sum of all values in _released.
        // If "_totalReleased += payment" does not overflow, then "_released[account] += payment" cannot overflow.
        _totalReleased += payment;
        unchecked {
            _released[account] += payment;
        }

        AddressUpgradeable.sendValue(account, payment);
        emit PaymentReleased(account, payment);
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of `token` tokens they are owed, according to their
     * percentage of the total shares and their previous withdrawals. `token` must be the address of an IERC20
     * contract.
     */
    function release(IERC20Upgradeable token, address account) public virtual {
        require(_shares[account] > 0, "PaymentSplitter: account has no shares");

        uint256 payment = releasable(token, account);

        require(payment != 0, "PaymentSplitter: account is not due payment");

        // _erc20TotalReleased[token] is the sum of all values in _erc20Released[token].
        // If "_erc20TotalReleased[token] += payment" does not overflow, then "_erc20Released[token][account] += payment"
        // cannot overflow.
        _erc20TotalReleased[token] += payment;
        unchecked {
            _erc20Released[token][account] += payment;
        }

        SafeERC20Upgradeable.safeTransfer(token, account, payment);
        emit ERC20PaymentReleased(token, account, payment);
    }

    /**
     * @dev internal logic for computing the pending payment of an `account` given the token historical balances and
     * already released amounts.
     */
    function _pendingPayment(
        address account,
        uint256 totalReceived,
        uint256 alreadyReleased
    ) private view returns (uint256) {
        return (totalReceived * _shares[account]) / _totalShares - alreadyReleased;
    }

    /**
     * @dev Add a new payee to the contract.
     * @param account The address of the payee to add.
     * @param shares_ The number of shares owned by the payee.
     */
    function _addPayee(address account, uint256 shares_) private {
        require(account != address(0), "PaymentSplitter: account is the zero address");
        require(shares_ > 0, "PaymentSplitter: shares are 0");
        require(_shares[account] == 0, "PaymentSplitter: account already has shares");

        _payees.push(account);
        _shares[account] = shares_;
        _totalShares = _totalShares + shares_;
        emit PayeeAdded(account, shares_);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[43] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20PermitUpgradeable {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20PermitUpgradeable token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721EnumerableUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64Upgradeable {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        /// @solidity memory-safe-assembly
        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The tree and the proofs can be generated using our
 * https://github.com/OpenZeppelin/merkle-tree[JavaScript library].
 * You will find a quickstart guide in the readme.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 * OpenZeppelin's JavaScript library generates merkle trees that are safe
 * against this attack out of the box.
 */
library MerkleProofUpgradeable {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be simultaneously proven to be a part of a merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and sibling nodes in `proof`. The reconstruction
     * proceeds by incrementally reconstructing all inner nodes by combining a leaf/inner node with either another
     * leaf/inner node or a proof sibling node, depending on whether each `proofFlags` item is true or false
     * respectively.
     *
     * CAUTION: Not all merkle trees admit multiproofs. To use multiproofs, it is sufficient to ensure that: 1) the tree
     * is complete (but not necessarily perfect), 2) the leaves to be proven are in the opposite order they are in the
     * tree (i.e., as seen from right to left starting at the deepest layer and continuing at the next layer).
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/MathUpgradeable.sol";

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = MathUpgradeable.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, MathUpgradeable.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Bytecode {
    error InvalidCodeAtRange(uint256 _size, uint256 _start, uint256 _end);

    /**
    @notice Generate a creation code that results on a contract with `_code` as bytecode
    @param _code The returning value of the resulting `creationCode`
    @return creationCode (constructor) for new contract
  */
    function creationCodeFor(bytes memory _code)
        internal
        pure
        returns (bytes memory)
    {
        /*
      0x00    0x63         0x63XXXXXX  PUSH4 _code.length  size
      0x01    0x80         0x80        DUP1                size size
      0x02    0x60         0x600e      PUSH1 14            14 size size
      0x03    0x60         0x6000      PUSH1 00            0 14 size size
      0x04    0x39         0x39        CODECOPY            size
      0x05    0x60         0x6000      PUSH1 00            0 size
      0x06    0xf3         0xf3        RETURN
      <CODE>
    */

        return
            abi.encodePacked(
                hex"63",
                uint32(_code.length),
                hex"80_60_0E_60_00_39_60_00_F3",
                _code
            );
    }

    /**
    @notice Returns the size of the code on a given address
    @param _addr Address that may or may not contain code
    @return size of the code on the given `_addr`
  */
    function codeSize(address _addr) internal view returns (uint256 size) {
        assembly {
            size := extcodesize(_addr)
        }
    }

    /**
    @notice Returns the code of a given address
    @dev It will fail if `_end < _start`
    @param _addr Address that may or may not contain code
    @param _start number of bytes of code to skip on read
    @param _end index before which to end extraction
    @return oCode read from `_addr` deployed bytecode

    Forked from: https://gist.github.com/KardanovIR/fe98661df9338c842b4a30306d507fbd
  */
    function codeAt(
        address _addr,
        uint256 _start,
        uint256 _end
    ) internal view returns (bytes memory oCode) {
        uint256 csize = codeSize(_addr);
        if (csize == 0) return bytes("");

        if (_start > csize) return bytes("");
        if (_end < _start) revert InvalidCodeAtRange(csize, _start, _end);

        unchecked {
            uint256 reqSize = _end - _start;
            uint256 maxSize = csize - _start;

            uint256 size = maxSize < reqSize ? maxSize : reqSize;

            assembly {
                // allocate output byte array - this could also be done without assembly
                // by using o_code = new bytes(size)
                oCode := mload(0x40)
                // new "memory end" including padding
                mstore(
                    0x40,
                    add(oCode, and(add(add(size, 0x20), 0x1f), not(0x1f)))
                )
                // store length in memory
                mstore(oCode, size)
                // actually retrieve the code, this needs assembly
                extcodecopy(_addr, add(oCode, 0x20), _start, size)
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {OperatorFiltererUpgradeable} from "./OperatorFiltererUpgradeable.sol";

abstract contract DefaultOperatorFiltererUpgradeable is
    OperatorFiltererUpgradeable
{
    function __DefaultOperatorFilterer_init(address s)
        internal
        onlyInitializing
    {
        OperatorFiltererUpgradeable.__OperatorFilterer_init(s, true);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "./Address.sol";

abstract contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    string private _name;
    string private _symbol;

    // Mapping from token ID to owner address
    address[] internal _owners;

    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            owner != address(0),
            "ERC721: balance query for the zero address"
        );

        uint256 count;
        for (uint256 i; i < _owners.length; ++i) {
            if (owner == _owners[i]) ++count;
        }
        return count;
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        address owner = _owners[tokenId];
        require(
            owner != address(0),
            "ERC721: owner query for nonexistent token"
        );
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        require(
            _exists(tokenId),
            "ERC721: approved query for nonexistent token"
        );

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return tokenId < _owners.length && _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        virtual
        returns (bool)
    {
        require(
            _exists(tokenId),
            "ERC721: operator query for nonexistent token"
        );
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner ||
            getApproved(tokenId) == spender ||
            isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);
        _owners.push(to);

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);
        _owners[tokenId] = address(0);

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(
            ERC721.ownerOf(tokenId) == from,
            "ERC721: transfer of token that is not own"
        );
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try
                IERC721Receiver(to).onERC721Received(
                    _msgSender(),
                    from,
                    tokenId,
                    _data
                )
            returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert(
                        "ERC721: transfer to non ERC721Receiver implementer"
                    );
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account but rips out the core of the gas-wasting processing that comes from OpenZeppelin.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165, ERC721)
        returns (bool)
    {
        return
            interfaceId == type(IERC721Enumerable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _owners.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            index < _owners.length,
            "ERC721Enumerable: global index out of bounds"
        );
        return index;
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index)
        public
        view
        virtual
        override
        returns (uint256 tokenId)
    {
        require(
            index < balanceOf(owner),
            "ERC721Enumerable: owner index out of bounds"
        );

        uint256 count;
        for (uint256 i; i < _owners.length; i++) {
            if (owner == _owners[i]) {
                if (count == index) return i;
                else count++;
            }
        }

        revert("ERC721Enumerable: owner index out of bounds");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721EnumerableUpgradeable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account but rips out the core of the gas-wasting processing that comes from OpenZeppelin.
 */
abstract contract ERC721EnumerableUpgradeable is
    ERC721Upgradeable,
    IERC721EnumerableUpgradeable
{
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165Upgradeable, ERC721Upgradeable)
        returns (bool)
    {
        return
            interfaceId == type(IERC721EnumerableUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _owners.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            index < _owners.length,
            "ERC721Enumerable: global index out of bounds"
        );
        return index;
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index)
        public
        view
        virtual
        override
        returns (uint256 tokenId)
    {
        require(
            index < balanceOf(owner),
            "ERC721Enumerable: owner index out of bounds"
        );

        uint256 count;
        for (uint256 i; i < _owners.length; i++) {
            if (owner == _owners[i]) {
                if (count == index) return i;
                else count++;
            }
        }

        revert("ERC721Enumerable: owner index out of bounds");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "./Address.sol";

abstract contract ERC721Upgradeable is
    ContextUpgradeable,
    ERC165Upgradeable,
    IERC721Upgradeable,
    IERC721MetadataUpgradeable
{
    using Address for address;
    using StringsUpgradeable for uint256;

    string private _name;
    string private _symbol;

    // Mapping from token ID to owner address
    address[] internal _owners;

    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    function __ERC721_init(string memory name_, string memory symbol_)
        internal
        onlyInitializing
    {
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_)
        internal
        onlyInitializing
    {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165Upgradeable, IERC165Upgradeable)
        returns (bool)
    {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            owner != address(0),
            "ERC721: balance query for the zero address"
        );

        uint256 count;
        for (uint256 i; i < _owners.length; ++i) {
            if (owner == _owners[i]) ++count;
        }
        return count;
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        address owner = _owners[tokenId];
        require(
            owner != address(0),
            "ERC721: owner query for nonexistent token"
        );
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        require(
            _exists(tokenId),
            "ERC721: approved query for nonexistent token"
        );

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return tokenId < _owners.length && _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        virtual
        returns (bool)
    {
        require(
            _exists(tokenId),
            "ERC721: operator query for nonexistent token"
        );
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        return (spender == owner ||
            getApproved(tokenId) == spender ||
            isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);
        _owners.push(to);

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721Upgradeable.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);
        _owners[tokenId] = address(0);

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(
            ERC721Upgradeable.ownerOf(tokenId) == from,
            "ERC721: transfer of token that is not own"
        );
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721Upgradeable.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try
                IERC721ReceiverUpgradeable(to).onERC721Received(
                    _msgSender(),
                    from,
                    tokenId,
                    _data
                )
            returns (bytes4 retval) {
                return
                    retval ==
                    IERC721ReceiverUpgradeable.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert(
                        "ERC721: transfer to non ERC721Receiver implementer"
                    );
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "../SSTORE2.sol";

interface IContentStore {
    event NewChecksum(bytes32 indexed checksum, uint256 contentSize);

    error ChecksumExists(bytes32 checksum);
    error ChecksumNotFound(bytes32 checksum);

    function pointers(bytes32 checksum) external view returns (address pointer);

    function checksumExists(bytes32 checksum) external view returns (bool);

    function contentLength(
        bytes32 checksum
    ) external view returns (uint256 size);

    function addPointer(address pointer) external returns (bytes32 checksum);

    function addContent(
        bytes memory content
    ) external returns (bytes32 checksum, address pointer);

    function getPointer(
        bytes32 checksum
    ) external view returns (address pointer);
}

contract ContentStore is IContentStore {
    // content checksum => sstore2 pointer
    mapping(bytes32 => address) public pointers;

    function checksumExists(bytes32 checksum) public view returns (bool) {
        return pointers[checksum] != address(0);
    }

    function contentLength(
        bytes32 checksum
    ) public view returns (uint256 size) {
        if (!checksumExists(checksum)) {
            revert ChecksumNotFound(checksum);
        }
        return SSTORE2.read(pointers[checksum]).length;
    }

    function addPointer(address pointer) public returns (bytes32 checksum) {
        bytes memory content = SSTORE2.read(pointer);
        checksum = keccak256(content);
        if (pointers[checksum] != address(0)) {
            return checksum;
        }
        pointers[checksum] = pointer;
        emit NewChecksum(checksum, content.length);
        return checksum;
    }

    function addContent(
        bytes memory content
    ) public returns (bytes32 checksum, address pointer) {
        checksum = keccak256(content);
        if (pointers[checksum] != address(0)) {
            return (checksum, pointers[checksum]);
        }
        pointer = SSTORE2.write(content);
        pointers[checksum] = pointer;
        emit NewChecksum(checksum, content.length);
        return (checksum, pointer);
    }

    function getPointer(
        bytes32 checksum
    ) public view returns (address pointer) {
        if (!checksumExists(checksum)) {
            revert ChecksumNotFound(checksum);
        }
        return pointers[checksum];
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "../SSTORE2.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2Step is Ownable {
    address private _pendingOwner;

    event OwnershipTransferStarted(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(
        address newOwner
    ) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() external {
        address sender = _msgSender();
        require(
            pendingOwner() == sender,
            "Ownable2Step: caller is not the new owner"
        );
        _transferOwnership(sender);
    }
}

struct Content {
    bytes32 checksum;
    address pointer;
}

struct File {
    uint256 size; // content length in bytes, max 24k
    Content[] contents;
}

function read(File memory file) view returns (string memory contents) {
    Content[] memory chunks = file.contents;

    // Adapted from https://gist.github.com/xtremetom/20411eb126aaf35f98c8a8ffa00123cd
    assembly {
        let len := mload(chunks)
        let totalSize := 0x20
        contents := mload(0x40)
        let size
        let chunk
        let pointer

        // loop through all pointer addresses
        // - get content
        // - get address
        // - get data size
        // - get code and add to contents
        // - update total size

        for {
            let i := 0
        } lt(i, len) {
            i := add(i, 1)
        } {
            chunk := mload(add(chunks, add(0x20, mul(i, 0x20))))
            pointer := mload(add(chunk, 0x20))

            size := sub(extcodesize(pointer), 1)
            extcodecopy(pointer, add(contents, totalSize), 1, size)
            totalSize := add(totalSize, size)
        }

        // update contents size
        mstore(contents, sub(totalSize, 0x20))
        // store contents
        mstore(0x40, add(contents, and(add(totalSize, 0x1f), not(0x1f))))
    }
}

using {read} for File global;

interface IContentStore {
    event NewChecksum(bytes32 indexed checksum, uint256 contentSize);

    error ChecksumExists(bytes32 checksum);
    error ChecksumNotFound(bytes32 checksum);

    function pointers(bytes32 checksum) external view returns (address pointer);

    function checksumExists(bytes32 checksum) external view returns (bool);

    function contentLength(
        bytes32 checksum
    ) external view returns (uint256 size);

    function addPointer(address pointer) external returns (bytes32 checksum);

    function addContent(
        bytes memory content
    ) external returns (bytes32 checksum, address pointer);

    function getPointer(
        bytes32 checksum
    ) external view returns (address pointer);
}

interface IFileStore {
    event FileCreated(
        string indexed indexedFilename,
        bytes32 indexed checksum,
        string filename,
        uint256 size,
        bytes metadata
    );
    event FileDeleted(
        string indexed indexedFilename,
        bytes32 indexed checksum,
        string filename
    );

    error FileNotFound(string filename);
    error FilenameExists(string filename);
    error EmptyFile();

    function contentStore() external view returns (IContentStore);

    function files(
        string memory filename
    ) external view returns (bytes32 checksum);

    function fileExists(string memory filename) external view returns (bool);

    function getChecksum(
        string memory filename
    ) external view returns (bytes32 checksum);

    function getFile(
        string memory filename
    ) external view returns (File memory file);

    function createFile(
        string memory filename,
        bytes32[] memory checksums
    ) external returns (File memory file);

    function createFile(
        string memory filename,
        bytes32[] memory checksums,
        bytes memory extraData
    ) external returns (File memory file);

    function deleteFile(string memory filename) external;
}

contract FileStore is IFileStore, Ownable2Step {
    IContentStore public immutable contentStore;

    // filename => File checksum
    mapping(string => bytes32) public files;

    constructor(IContentStore _contentStore) {
        contentStore = _contentStore;
    }

    function fileExists(string memory filename) public view returns (bool) {
        return files[filename] != bytes32(0);
    }

    function getChecksum(
        string memory filename
    ) public view returns (bytes32 checksum) {
        checksum = files[filename];
        if (checksum == bytes32(0)) {
            revert FileNotFound(filename);
        }
        return checksum;
    }

    function getFile(
        string memory filename
    ) public view returns (File memory file) {
        bytes32 checksum = files[filename];
        if (checksum == bytes32(0)) {
            revert FileNotFound(filename);
        }
        address pointer = contentStore.pointers(checksum);
        if (pointer == address(0)) {
            revert FileNotFound(filename);
        }
        return abi.decode(SSTORE2.read(pointer), (File));
    }

    function createFile(
        string memory filename,
        bytes32[] memory checksums
    ) public returns (File memory file) {
        return createFile(filename, checksums, new bytes(0));
    }

    function createFile(
        string memory filename,
        bytes32[] memory checksums,
        bytes memory extraData
    ) public returns (File memory file) {
        if (files[filename] != bytes32(0)) {
            revert FilenameExists(filename);
        }
        return _createFile(filename, checksums, extraData);
    }

    function _createFile(
        string memory filename,
        bytes32[] memory checksums,
        bytes memory extraData
    ) private returns (File memory file) {
        Content[] memory contents = new Content[](checksums.length);
        uint256 size = 0;
        // TODO: optimize this
        for (uint256 i = 0; i < checksums.length; ++i) {
            size += contentStore.contentLength(checksums[i]);
            contents[i] = Content({
                checksum: checksums[i],
                pointer: contentStore.getPointer(checksums[i])
            });
        }
        if (size == 0) {
            revert EmptyFile();
        }
        file = File({size: size, contents: contents});
        (bytes32 checksum, ) = contentStore.addContent(abi.encode(file));
        files[filename] = checksum;
        emit FileCreated(filename, checksum, filename, file.size, extraData);
    }

    function deleteFile(string memory filename) public onlyOwner {
        bytes32 checksum = files[filename];
        if (checksum == bytes32(0)) {
            revert FileNotFound(filename);
        }
        delete files[filename];
        emit FileDeleted(filename, checksum, filename);
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "../SSTORE2.sol";

struct Content {
    bytes32 checksum;
    address pointer;
}

struct File {
    uint256 size; // content length in bytes, max 24k
    Content[] contents;
}

function read(File memory file) view returns (string memory contents) {
    Content[] memory chunks = file.contents;

    // Adapted from https://gist.github.com/xtremetom/20411eb126aaf35f98c8a8ffa00123cd
    assembly {
        let len := mload(chunks)
        let totalSize := 0x20
        contents := mload(0x40)
        let size
        let chunk
        let pointer

        // loop through all pointer addresses
        // - get content
        // - get address
        // - get data size
        // - get code and add to contents
        // - update total size

        for {
            let i := 0
        } lt(i, len) {
            i := add(i, 1)
        } {
            chunk := mload(add(chunks, add(0x20, mul(i, 0x20))))
            pointer := mload(add(chunk, 0x20))

            size := sub(extcodesize(pointer), 1)
            extcodecopy(pointer, add(contents, totalSize), 1, size)
            totalSize := add(totalSize, size)
        }

        // update contents size
        mstore(contents, sub(totalSize, 0x20))
        // store contents
        mstore(0x40, add(contents, and(add(totalSize, 0x1f), not(0x1f))))
    }
}

using {read} for File global;

// Convenience methods to call from the frontend or subgraph, where they would
// otherwise be too gas heavy for another contract.

contract FileStoreFrontend {
    function readFile(
        IFileStore fileStore,
        string memory filename
    ) public view returns (string memory contents) {
        return fileStore.getFile(filename).read();
    }

    function getContent(
        IContentStore contentStore,
        bytes32 checksum
    ) public view returns (bytes memory content) {
        return SSTORE2.read(contentStore.getPointer(checksum));
    }
}

interface IContentStore {
    event NewChecksum(bytes32 indexed checksum, uint256 contentSize);

    error ChecksumExists(bytes32 checksum);
    error ChecksumNotFound(bytes32 checksum);

    function pointers(bytes32 checksum) external view returns (address pointer);

    function checksumExists(bytes32 checksum) external view returns (bool);

    function contentLength(
        bytes32 checksum
    ) external view returns (uint256 size);

    function addPointer(address pointer) external returns (bytes32 checksum);

    function addContent(
        bytes memory content
    ) external returns (bytes32 checksum, address pointer);

    function getPointer(
        bytes32 checksum
    ) external view returns (address pointer);
}

interface IFileStore {
    event FileCreated(
        string indexed indexedFilename,
        bytes32 indexed checksum,
        string filename,
        uint256 size,
        bytes metadata
    );
    event FileDeleted(
        string indexed indexedFilename,
        bytes32 indexed checksum,
        string filename
    );

    error FileNotFound(string filename);
    error FilenameExists(string filename);
    error EmptyFile();

    function contentStore() external view returns (IContentStore);

    function files(
        string memory filename
    ) external view returns (bytes32 checksum);

    function fileExists(string memory filename) external view returns (bool);

    function getChecksum(
        string memory filename
    ) external view returns (bytes32 checksum);

    function getFile(
        string memory filename
    ) external view returns (File memory file);

    function createFile(
        string memory filename,
        bytes32[] memory checksums
    ) external returns (File memory file);

    function createFile(
        string memory filename,
        bytes32[] memory checksums,
        bytes memory extraData
    ) external returns (File memory file);

    function deleteFile(string memory filename) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IOperatorFilterRegistry {
    function isOperatorAllowed(address registrant, address operator) external view returns (bool);
    function register(address registrant) external;
    function registerAndSubscribe(address registrant, address subscription) external;
    function registerAndCopyEntries(address registrant, address registrantToCopy) external;
    function unregister(address addr) external;
    function updateOperator(address registrant, address operator, bool filtered) external;
    function updateOperators(address registrant, address[] calldata operators, bool filtered) external;
    function updateCodeHash(address registrant, bytes32 codehash, bool filtered) external;
    function updateCodeHashes(address registrant, bytes32[] calldata codeHashes, bool filtered) external;
    function subscribe(address registrant, address registrantToSubscribe) external;
    function unsubscribe(address registrant, bool copyExistingEntries) external;
    function subscriptionOf(address addr) external returns (address registrant);
    function subscribers(address registrant) external returns (address[] memory);
    function subscriberAt(address registrant, uint256 index) external returns (address);
    function copyEntriesOf(address registrant, address registrantToCopy) external;
    function isOperatorFiltered(address registrant, address operator) external returns (bool);
    function isCodeHashOfFiltered(address registrant, address operatorWithCode) external returns (bool);
    function isCodeHashFiltered(address registrant, bytes32 codeHash) external returns (bool);
    function filteredOperators(address addr) external returns (address[] memory);
    function filteredCodeHashes(address addr) external returns (bytes32[] memory);
    function filteredOperatorAt(address registrant, uint256 index) external returns (address);
    function filteredCodeHashAt(address registrant, uint256 index) external returns (bytes32);
    function isRegistered(address addr) external returns (bool);
    function codeHashOf(address addr) external returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IOperatorFilterRegistry} from "./IOperatorFilterRegistry.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

abstract contract OperatorFiltererUpgradeable is Initializable {
    error OperatorNotAllowed(address operator);

    IOperatorFilterRegistry public operatorFilterRegistry;

    function __OperatorFilterer_init(
        address subscriptionOrRegistrantToCopy,
        bool subscribe
    ) internal onlyInitializing {
        operatorFilterRegistry = IOperatorFilterRegistry(
            0x000000000000AAeB6D7670E522A718067333cd4E
        );
        if (address(operatorFilterRegistry).code.length > 0) {
            if (!operatorFilterRegistry.isRegistered(address(this))) {
                if (subscribe) {
                    operatorFilterRegistry.registerAndSubscribe(
                        address(this),
                        subscriptionOrRegistrantToCopy
                    );
                } else {
                    if (subscriptionOrRegistrantToCopy != address(0)) {
                        operatorFilterRegistry.registerAndCopyEntries(
                            address(this),
                            subscriptionOrRegistrantToCopy
                        );
                    } else {
                        operatorFilterRegistry.register(address(this));
                    }
                }
            }
        }
    }

    modifier onlyAllowedOperator(address from) virtual {
        // Check registry code length to facilitate testing in environments without a deployed registry.
        if (address(operatorFilterRegistry).code.length > 0) {
            // Allow spending tokens from addresses with balance
            // Note that this still allows listings and marketplaces with escrow to transfer tokens if transferred
            // from an EOA.
            if (from == msg.sender) {
                _;
                return;
            }
            if (
                !operatorFilterRegistry.isOperatorAllowed(
                    address(this),
                    msg.sender
                )
            ) {
                revert OperatorNotAllowed(msg.sender);
            }
        }
        _;
    }

    modifier onlyAllowedOperatorApproval(address operator) virtual {
        // Check registry code length to facilitate testing in environments without a deployed registry.
        if (address(operatorFilterRegistry).code.length > 0) {
            if (
                !operatorFilterRegistry.isOperatorAllowed(
                    address(this),
                    operator
                )
            ) {
                revert OperatorNotAllowed(operator);
            }
        }
        _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init(address _ownerOnInit) internal onlyInitializing {
        __Ownable_init_unchained(_ownerOnInit);
    }

    function __Ownable_init_unchained(address _ownerOnInit)
        internal
        onlyInitializing
    {
        _transferOwnership(_ownerOnInit);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {RevokableOperatorFiltererUpgradeable} from "./RevokableOperatorFiltererUpgradeable.sol";

abstract contract RevokableDefaultOperatorFiltererUpgradeable is RevokableOperatorFiltererUpgradeable {
    address constant DEFAULT_SUBSCRIPTION = address(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6);

    function __RevokableDefaultOperatorFilterer_init() internal onlyInitializing {
        RevokableOperatorFiltererUpgradeable.__RevokableOperatorFilterer_init(DEFAULT_SUBSCRIPTION, true);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {OperatorFiltererUpgradeable} from "./OperatorFiltererUpgradeable.sol";

/**
 * @title  RevokableOperatorFilterer
 * @notice This contract is meant to allow contracts to permanently opt out of the OperatorFilterRegistry. The Registry
 *         itself has an "unregister" function, but if the contract is ownable, the owner can re-register at any point.
 *         As implemented, this abstract contract allows the contract owner to toggle the
 *         isOperatorFilterRegistryRevoked flag in order to permanently bypass the OperatorFilterRegistry checks.
 */
abstract contract RevokableOperatorFiltererUpgradeable is OperatorFiltererUpgradeable {
    error OnlyOwner();
    error AlreadyRevoked();

    bool private _isOperatorFilterRegistryRevoked;

    function __RevokableOperatorFilterer_init(address subscriptionOrRegistrantToCopy, bool subscribe) internal {
        OperatorFiltererUpgradeable.__OperatorFilterer_init(subscriptionOrRegistrantToCopy, subscribe);
    }

    modifier onlyAllowedOperator(address from) override {
        // Check registry code length to facilitate testing in environments without a deployed registry.
        if (!_isOperatorFilterRegistryRevoked && address(operatorFilterRegistry).code.length > 0) {
            // Allow spending tokens from addresses with balance
            // Note that this still allows listings and marketplaces with escrow to transfer tokens if transferred
            // from an EOA.
            if (from == msg.sender) {
                _;
                return;
            }
            if (!operatorFilterRegistry.isOperatorAllowed(address(this), msg.sender)) {
                revert OperatorNotAllowed(msg.sender);
            }
        }
        _;
    }

    modifier onlyAllowedOperatorApproval(address operator) override {
        // Check registry code length to facilitate testing in environments without a deployed registry.
        if (!_isOperatorFilterRegistryRevoked && address(operatorFilterRegistry).code.length > 0) {
            if (!operatorFilterRegistry.isOperatorAllowed(address(this), operator)) {
                revert OperatorNotAllowed(operator);
            }
        }
        _;
    }

    /**
     * @notice Disable the isOperatorFilterRegistryRevoked flag. OnlyOwner.
     */
    function revokeOperatorFilterRegistry() external {
        if (msg.sender != owner()) {
            revert OnlyOwner();
        }
        if (_isOperatorFilterRegistryRevoked) {
            revert AlreadyRevoked();
        }
        _isOperatorFilterRegistryRevoked = true;
    }

    function isOperatorFilterRegistryRevoked() public view returns (bool) {
        return _isOperatorFilterRegistryRevoked;
    }

    /**
     * @dev assume the contract has an owner, but leave specific Ownable implementation up to inheriting contract
     */
    function owner() public view virtual returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./Bytecode.sol";

library SSTORE2 {
    error WriteError();

    /**
    @notice Stores `_data` and returns `pointer` as key for later retrieval
    @dev The pointer is a contract address with `_data` as code
    @param _data to be written
    @return pointer Pointer to the written `_data`
  */
    function write(bytes memory _data) internal returns (address pointer) {
        // Append 00 to _data so contract can't be called
        // Build init code
        bytes memory code = Bytecode.creationCodeFor(
            abi.encodePacked(hex"00", _data)
        );

        // Deploy contract using create
        assembly {
            pointer := create(0, add(code, 32), mload(code))
        }

        // Address MUST be non-zero
        if (pointer == address(0)) revert WriteError();
    }

    /**
    @notice Reads the contents of the `_pointer` code as data, skips the first byte 
    @dev The function is intended for reading pointers generated by `write`
    @param _pointer to be read
    @return data read from `_pointer` contract
  */
    function read(address _pointer) internal view returns (bytes memory) {
        return Bytecode.codeAt(_pointer, 1, type(uint256).max);
    }

    /**
    @notice Reads the contents of the `_pointer` code as data, skips the first byte 
    @dev The function is intended for reading pointers generated by `write`
    @param _pointer to be read
    @param _start number of bytes to skip
    @return data read from `_pointer` contract
  */
    function read(address _pointer, uint256 _start)
        internal
        view
        returns (bytes memory)
    {
        return Bytecode.codeAt(_pointer, _start + 1, type(uint256).max);
    }

    /**
    @notice Reads the contents of the `_pointer` code as data, skips the first byte 
    @dev The function is intended for reading pointers generated by `write`
    @param _pointer to be read
    @param _start number of bytes to skip
    @param _end index before which to end extraction
    @return data read from `_pointer` contract
  */
    function read(
        address _pointer,
        uint256 _start,
        uint256 _end
    ) internal view returns (bytes memory) {
        return Bytecode.codeAt(_pointer, _start + 1, _end + 1);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/finance/PaymentSplitterUpgradeable.sol";

contract RoyaltySplitter is Initializable {
    address payable public twoFiveSix;
    uint96 public twoFiveSixShare;
    address payable public thirdParty;
    uint96 public thirdPartyShare;
    address payable public artist;

    /**
     * @notice Initializes the RoyaltySplitter contract with artist, twoFiveSix, and twoFiveSixShare values
     * @dev This function is called only once during contract creation
     * @param _artist The address of the artist who will receive a portion of the contract's balance
     * @param _twoFiveSix The address of the other party who will receive a portion of the contract's balance
     * @param _twoFiveSixShare The percentage of the contract's balance that will be sent to twoFiveSix
     */
    function initRoyaltySplitter(
        address payable _twoFiveSix,
        uint96 _twoFiveSixShare,
        address payable _thirdParty,
        uint96 _thirdPartyShare,
        address payable _artist
    ) public initializer {
        artist = _artist;
        twoFiveSix = _twoFiveSix;
        twoFiveSixShare = _twoFiveSixShare;
        if (_thirdParty != address(0)) {
            thirdParty = _thirdParty;
            thirdPartyShare = _thirdPartyShare;
        }
    }

    /**
     * @notice Allows the artist or twoFiveSix to withdraw their share from the contract's balance
     * @dev When either the artist or twoFiveSix calls this function, their respective share will be sent to both parties
     */
    function withdraw() public {
        require(
            (msg.sender == twoFiveSix ||
                msg.sender == artist ||
                msg.sender == thirdParty),
            "Not allowed"
        );
        uint256 balance = address(this).balance;

        if (thirdParty == address(0)) {
            uint256 twoFiveSixBalance = (balance * twoFiveSixShare) / 10000;
            uint256 artistBalance = (balance - twoFiveSixBalance);

            twoFiveSix.transfer(twoFiveSixBalance);
            artist.transfer(artistBalance);
        } else {
            uint256 twoFiveSixBalance = (balance * twoFiveSixShare) / 10000;
            uint256 thirdPartyBalance = (balance * thirdPartyShare) / 10000;
            uint256 artistBalance = (balance -
                twoFiveSixBalance -
                thirdPartyBalance);

            twoFiveSix.transfer(twoFiveSixBalance);
            thirdParty.transfer(thirdPartyBalance);
            artist.transfer(artistBalance);
        }
    }

    function withdrawToken(IERC20Upgradeable token) public {
        require(
            (msg.sender == twoFiveSix ||
                msg.sender == artist ||
                msg.sender == thirdParty),
            "Not allowed"
        );

        uint256 balance = token.balanceOf(address(this));

        if (thirdParty == address(0)) {
            uint256 twoFiveSixBalance = (balance * twoFiveSixShare) / 10000;
            uint256 artistBalance = (balance - twoFiveSixBalance);

            SafeERC20Upgradeable.safeTransfer(token, artist, artistBalance);
            SafeERC20Upgradeable.safeTransfer(
                token,
                twoFiveSix,
                twoFiveSixBalance
            );
        } else {
            uint256 twoFiveSixBalance = (balance * twoFiveSixShare) / 10000;
            uint256 thirdPartyBalance = (balance * thirdPartyShare) / 10000;
            uint256 artistBalance = (balance -
                twoFiveSixBalance -
                thirdPartyBalance);

            SafeERC20Upgradeable.safeTransfer(
                token,
                twoFiveSix,
                twoFiveSixBalance
            );
            SafeERC20Upgradeable.safeTransfer(
                token,
                thirdParty,
                thirdPartyBalance
            );
            SafeERC20Upgradeable.safeTransfer(token, artist, artistBalance);
        }
    }

    /**
     * @dev Fallback function to accept incoming ether transfers to the contract
     */
    receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestToken is ERC20 {
    constructor(uint256 initialSupply) ERC20("TestToken", "TST") {
        _mint(msg.sender, initialSupply);
    }
}

// SPDX-License-Identifier: MIT

/* 

██████╗ ███████╗ ██████╗ 
╚════██╗██╔════╝██╔════╝ 
 █████╔╝███████╗███████╗ 
██╔═══╝ ╚════██║██╔═══██╗
███████╗███████║╚██████╔╝
╚══════╝╚══════╝ ╚═════╝ 

Using this contract? 
A shout out to @Mint256Art is appreciated!
 */

pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";

contract TwoFiveSixFactories is Ownable {
    address[] public twoFiveSixFactories;
    address public royaltySplitterFactory;

    /**
     * @dev Set the royalty splitter factory address
     * @notice Only the contract owner can call this function
     * @param a The new royalty splitter factory contract address
     */
    function addTwoFiveSixFactoryAddress(address a) public onlyOwner {
        twoFiveSixFactories.push(a);
    }

    /**
     * @dev Set the royalty splitter factory address
     * @notice Only the contract owner can call this function
     * @param newAddress The new royalty splitter factory contract address
     */
    function setRoyaltySplitterFactoryAddress(
        address newAddress
    ) public onlyOwner {
        royaltySplitterFactory = newAddress;
    }
}

// SPDX-License-Identifier: MIT

/* 

██████╗ ███████╗ ██████╗ 
╚════██╗██╔════╝██╔════╝ 
 █████╔╝███████╗███████╗ 
██╔═══╝ ╚════██║██╔═══██╗
███████╗███████║╚██████╔╝
╚══════╝╚══════╝ ╚═════╝ 

Using this contract? 
A shout out to @Mint256Art is appreciated!
 */

pragma solidity ^0.8.19;

import "./helpers/SSTORE2.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TwoFiveSixFactoryDefaultV1 is Ownable {
    address payable private _twoFiveSixAddress;
    address public masterProject;

    address[] public projects;

    /* Percentage multiplied by 100 */
    uint256 public twoFiveSixSharePrimary;

    uint256 public biddingDelay;
    uint256 public allowListDelay;

    event Deployed(address a);

    /**
     * @notice Launches a new TwoFiveSixProject with the provided project, traits, and libraries.
     * @dev The `masterProject` is used as the contract implementation.
     * @param _project A struct containing details about the project being launched.
     * @param _traits An array of structs containing details about the traits associated with the project.
     * @param _libraries An array of structs containing details about the libraries used by the project.
     */
    function launchProject(
        ITwoFiveSixProject.Project calldata _project,
        ITwoFiveSixProject.Trait[] calldata _traits,
        ITwoFiveSixProject.LibraryScript[] calldata _libraries
    ) public {
        require(
            _project.biddingStartTimeStamp > block.timestamp + biddingDelay,
            "Before minimum bidding delay"
        );
        require(
            _project.allowListStartTimeStamp > block.timestamp + allowListDelay,
            "Before allow list delay"
        );
        require(
            _project.twoFiveSix == _twoFiveSixAddress,
            "Incorrect 256ART address"
        );
        require(
            _project.twoFiveSixShare == uint24(twoFiveSixSharePrimary),
            "Incorrect 256ART share"
        );
        require(
            twoFiveSixSharePrimary + _project.thirdPartyShare <= 10000,
            "Third party share too high"
        );

        address a = clone(masterProject);

        address traits;

        address libraryScripts;

        if (_traits.length > 0) {
            traits = SSTORE2.write(abi.encode(_traits));
        }

        if (_libraries.length > 0) {
            libraryScripts = SSTORE2.write(abi.encode(_libraries));
        }

        ITwoFiveSixProject p = ITwoFiveSixProject(a);

        p.initProject(_project, traits, libraryScripts);
        projects.push(a);
        emit Deployed(a);
    }

    /**
     * @notice Clones a contract using the provided implementation address
     * @param implementation The address of the contract implementation
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(
                ptr,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(
                add(ptr, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Set the master project address
     * @notice Only the contract owner can call this function
     * @param _masterProject Address of the new master project contract
     */
    function setMasterProject(address _masterProject) public onlyOwner {
        masterProject = _masterProject;
    }

    /**
     * @dev Set the 256 address
     * @notice Only the contract owner can call this function
     * @param newAddress The new 256 contract address
     */
    function setTwoFiveSixAddress(address payable newAddress) public onlyOwner {
        _twoFiveSixAddress = newAddress;
    }

    /**
     * @dev Set the primary 256 share
     * @notice Only the contract owner can call this function
     * @param newShare The new primary 256 share
     */
    function setTwoFiveSixSharePrimary(uint256 newShare) public onlyOwner {
        twoFiveSixSharePrimary = newShare;
    }

    /**
     * @dev Set the bidding delay
     * @notice Only the contract owner can call this function
     * @param delay The new bidding delay
     */
    function setBiddingDelay(uint256 delay) public onlyOwner {
        biddingDelay = delay;
    }

    /**
     * @dev Set the allow list delay
     * @notice Only the contract owner can call this function
     * @param delay The new allow list delay
     */
    function setAllowListDelay(uint256 delay) public onlyOwner {
        allowListDelay = delay;
    }
}

interface ITwoFiveSixProject {
    struct Project {
        string name; //unknown
        string imageBase; //unkown
        address[] artScripts; //unknown
        bytes32 merkleRoot; //32
        address artInfo; //20
        uint56 biddingStartTimeStamp; //8
        uint32 maxSupply; //4
        address payable artistAddress; //20
        uint56 allowListStartTimeStamp; //8
        uint32 totalAllowListMints; //4
        address payable twoFiveSix; //20
        uint24 artistAuctionWithdrawalsClaimed; //3
        uint24 artistAllowListWithdrawalsClaimed; //3
        uint24 twoFiveSixShare; //3
        uint24 royalty; //3
        address traits; //20
        uint96 reservePrice; //12
        address payable royaltyAddress; //20
        uint96 lastSalePrice; //12
        address libraryScripts; //20
        uint56 endingTimeStamp; //8
        uint24 thirdPartyShare; //3
        bool fixedPrice; //1
        address payable thirdPartyAddress; //20
    }
    struct Trait {
        string name;
        string[] values;
        string[] descriptions;
        uint256[] weights;
    }

    struct TotalAndCount {
        uint128 total;
        uint128 count;
    }
    struct LibraryScript {
        address fileStoreFrontEnd;
        address fileStore;
        string fileName;
    }

    function initProject(
        Project calldata _p,
        address _traits,
        address _libraryScripts
    ) external;
}

// SPDX-License-Identifier: MIT

/* 

██████╗ ███████╗ ██████╗ 
╚════██╗██╔════╝██╔════╝ 
 █████╔╝███████╗███████╗ 
██╔═══╝ ╚════██║██╔═══██╗
███████╗███████║╚██████╔╝
╚══════╝╚══════╝ ╚═════╝ 

Using this contract? 
A shout out to @Mint256Art is appreciated!
 */

pragma solidity ^0.8.19;

import "./helpers/SSTORE2.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./RoyaltySplitter.sol";

contract TwoFiveSixFactoryRoyaltySplitterV1 is Ownable {
    address payable private _twoFiveSixAddress;

    address payable public masterRoyaltySplitter;

    /* Percentage multiplied by 100 */
    uint96 public twoFiveSixShareSecondary;

    event Deployed(address a);

    /**
     * @notice Creates a new instance of the RoyaltySplitter contract with the given artist address.
     * @dev The `masterRoyaltySplitter` is used as the contract implementation.
     * @param _artist The address of the artist who will receive the royalties.
     * @param _thirdParty The address of a potential third party who will receive a part of the royalties.
     * @param _thirdPartyShare The share of royalties the third party should receive (percentage * 100).
     */
    function createRoyaltySplitter(
        address payable _artist,
        address payable _thirdParty,
        uint96 _thirdPartyShare
    ) public {
        require(
            twoFiveSixShareSecondary + _thirdPartyShare <= 10000,
            "Third party share too high"
        );
        address payable a = clonePayable(masterRoyaltySplitter);
        RoyaltySplitter r = RoyaltySplitter(a);
        r.initRoyaltySplitter(
            _twoFiveSixAddress,
            twoFiveSixShareSecondary,
            _thirdParty,
            _thirdPartyShare,
            _artist
        );
        emit Deployed(a);
    }

    /**
     * @notice Clones a payable contract using the provided implementation address
     * @param implementation The address of the contract implementation
     */
    function clonePayable(
        address payable implementation
    ) internal returns (address payable instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(
                ptr,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(
                add(ptr, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Set the 256 address
     * @notice Only the contract owner can call this function
     * @param newAddress The new 256 contract address
     */
    function setTwoFiveSixAddress(address payable newAddress) public onlyOwner {
        _twoFiveSixAddress = newAddress;
    }

    /**
     * @dev Set the master royalty splitter address
     * @notice Only the contract owner can call this function
     * @param _masterRoyaltySplitter Address of the new master royalty splitter contract
     */
    function setMasterRoyaltySplitter(
        address payable _masterRoyaltySplitter
    ) public onlyOwner {
        masterRoyaltySplitter = _masterRoyaltySplitter;
    }

    /**
     * @dev Set the secondary 256 share
     * @notice Only the contract owner can call this function
     * @param newShare The new secondary 256 share
     */
    function setTwoFiveSixShareSecondary(uint96 newShare) public onlyOwner {
        twoFiveSixShareSecondary = newShare;
    }
}

// SPDX-License-Identifier: MIT

/* 

██████╗ ███████╗ ██████╗ 
╚════██╗██╔════╝██╔════╝ 
 █████╔╝███████╗███████╗ 
██╔═══╝ ╚════██║██╔═══██╗
███████╗███████║╚██████╔╝
╚══════╝╚══════╝ ╚═════╝ 

Using this contract? 
A shout out to @Mint256Art is appreciated!
 */

pragma solidity ^0.8.19;

import "./helpers/SSTORE2.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TwoFiveSixFactorySeededV1 is Ownable {
    address payable private _twoFiveSixAddress;

    address public masterProject;

    address[] public projects;

    /* Percentage multiplied by 100 */
    uint256 public twoFiveSixSharePrimary;

    uint256 public biddingDelay;
    uint256 public allowListDelay;

    event Deployed(address a);

    /**
     * @notice Launches a new TwoFiveSixProjectSeeded with the provided project, traits, libraries, and seed.
     * @dev The `masterProjectSeeded` is used as the contract implementation.
     * @param _project A struct containing details about the project being launched.
     * @param _traits An array of structs containing details about the traits associated with the project.
     * @param _libraries An array of structs containing details about the libraries used by the project.
     */
    function launchProject(
        ITwoFiveSixProject.Project memory _project,
        ITwoFiveSixProject.Trait[] calldata _traits,
        ITwoFiveSixProject.LibraryScript[] calldata _libraries
    ) public {
        require(
            _project.biddingStartTimeStamp > block.timestamp + biddingDelay,
            "Before minimum bidding delay"
        );
        require(
            _project.allowListStartTimeStamp > block.timestamp + allowListDelay,
            "Before allow list delay"
        );
        require(
            _project.twoFiveSix == _twoFiveSixAddress,
            "Incorrect 256ART address"
        );
        require(
            _project.twoFiveSixShare == uint24(twoFiveSixSharePrimary),
            "Incorrect 256ART share"
        );
        require(
            twoFiveSixSharePrimary + _project.thirdPartyShare <= 10000,
            "Third party share too high"
        );

        address a = clone(masterProject);

        address traits;

        address libraryScripts;

        if (_traits.length > 0) {
            traits = SSTORE2.write(abi.encode(_traits));
        }

        if (_libraries.length > 0) {
            libraryScripts = SSTORE2.write(abi.encode(_libraries));
        }

        ITwoFiveSixProject p = ITwoFiveSixProject(a);

        p.initProject(_project, traits, libraryScripts);
        projects.push(a);
        emit Deployed(a);
    }

    /**
     * @notice Clones a contract using the provided implementation address
     * @param implementation The address of the contract implementation
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(
                ptr,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(
                add(ptr, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Set the master project address
     * @notice Only the contract owner can call this function
     * @param _masterProject Address of the new master project contract
     */
    function setMasterProject(address _masterProject) public onlyOwner {
        masterProject = _masterProject;
    }

    /**
     * @dev Set the 256 address
     * @notice Only the contract owner can call this function
     * @param newAddress The new 256 contract address
     */
    function setTwoFiveSixAddress(address payable newAddress) public onlyOwner {
        _twoFiveSixAddress = newAddress;
    }

    /**
     * @dev Set the primary 256 share
     * @notice Only the contract owner can call this function
     * @param newShare The new primary 256 share
     */
    function setTwoFiveSixSharePrimary(uint256 newShare) public onlyOwner {
        twoFiveSixSharePrimary = newShare;
    }

    /**
     * @dev Set the bidding delay
     * @notice Only the contract owner can call this function
     * @param delay The new bidding delay
     */
    function setBiddingDelay(uint256 delay) public onlyOwner {
        biddingDelay = delay;
    }

    /**
     * @dev Set the allow list delay
     * @notice Only the contract owner can call this function
     * @param delay The new allow list delay
     */
    function setAllowListDelay(uint256 delay) public onlyOwner {
        allowListDelay = delay;
    }
}

interface ITwoFiveSixProject {
    struct Project {
        string name; //unknown
        string imageBase; //unkown
        address[] artScripts; //unknown
        bytes32 merkleRoot; //32
        address artInfo; //20
        uint56 biddingStartTimeStamp; //8
        uint32 maxSupply; //4
        address payable artistAddress; //20
        uint56 allowListStartTimeStamp; //8
        uint32 totalAllowListMints; //4
        address payable twoFiveSix; //20
        uint24 artistAuctionWithdrawalsClaimed; //3
        uint24 artistAllowListWithdrawalsClaimed; //3
        uint24 twoFiveSixShare; //3
        uint24 royalty; //3
        address traits; //20
        uint96 reservePrice; //12
        address payable royaltyAddress; //20
        uint96 lastSalePrice; //12
        address libraryScripts; //20
        uint56 endingTimeStamp; //8
        uint24 thirdPartyShare; //3
        bool fixedPrice; //1
        address payable thirdPartyAddress; //20
    }
    struct Trait {
        string name;
        string[] values;
        string[] descriptions;
        uint256[] weights;
    }

    struct TotalAndCount {
        uint128 total;
        uint128 count;
    }
    struct LibraryScript {
        address fileStoreFrontEnd;
        address fileStore;
        string fileName;
    }

    function initProject(
        Project calldata _p,
        address _traits,
        address _libraryScripts
    ) external;
}

// SPDX-License-Identifier: MIT

/* 

██████╗ ███████╗ ██████╗ 
╚════██╗██╔════╝██╔════╝ 
 █████╔╝███████╗███████╗ 
██╔═══╝ ╚════██║██╔═══██╗
███████╗███████║╚██████╔╝
╚══════╝╚══════╝ ╚═════╝ 

Using this contract? 
A shout out to @Mint256Art is appreciated!
 */
pragma solidity ^0.8.19;

import "./helpers/SSTORE2.sol";
import "./helpers/OwnableUpgradeable.sol";
import "./helpers/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/Base64Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";

contract TwoFiveSixProjectSeededV1 is
    ERC721EnumerableUpgradeable,
    OwnableUpgradeable
{
    mapping(uint256 => bytes32) public tokenIdToHash;
    mapping(bytes32 => uint256) public hashToTokenId;
    mapping(address => TotalAndCount) private addressToTotalAndCount;
    mapping(address => bool) private addressToClaimed;

    struct Project {
        string name; //unknown
        string imageBase; //unkown
        address[] artScripts; //unknown
        bytes32 merkleRoot; //32
        address artInfo; //20
        uint56 biddingStartTimeStamp; //8
        uint32 maxSupply; //4
        address payable artistAddress; //20
        uint56 allowListStartTimeStamp; //8
        uint32 totalAllowListMints; //4
        address payable twoFiveSix; //20
        uint24 artistAuctionWithdrawalsClaimed; //3
        uint24 artistAllowListWithdrawalsClaimed; //3
        uint24 twoFiveSixShare; //3
        uint24 royalty; //3
        address traits; //20
        uint96 reservePrice; //12
        address payable royaltyAddress; //20
        uint96 lastSalePrice; //12
        address libraryScripts; //20
        uint56 endingTimeStamp; //8
        uint24 thirdPartyShare; //3
        bool fixedPrice; //1
        address payable thirdPartyAddress; //20
    }
    struct Trait {
        string name;
        string[] values;
        string[] descriptions;
        uint256[] weights;
    }

    struct TotalAndCount {
        uint128 total;
        uint128 count;
    }
    struct LibraryScript {
        address fileStoreFrontEnd;
        address fileStore;
        string fileName;
    }
    Project private project;

    /**
     * @notice Initializes the project.
     * @dev Initializes the ERC721 contract.
     * @param _p The project data.
     */
    function initProject(
        Project calldata _p,
        address _traits,
        address _libraryScripts
    ) public initializer {
        __ERC721_init(_p.name, "256ART");
        __Ownable_init(_p.artistAddress);
        project = _p;
        if (_traits != address(0)) {
            project.traits = _traits;
        }
        if (_libraryScripts != address(0)) {
            project.libraryScripts = _libraryScripts;
        }
    }

    /**
     * @notice Gets the current price.
     */
    function currentPrice() public view returns (uint256 p) {
        require(
            block.timestamp > project.biddingStartTimeStamp,
            "Mint not started"
        );
        require(block.timestamp < project.endingTimeStamp, "Mint ended");
        uint256 timeElapsed = block.timestamp - project.biddingStartTimeStamp;
        uint256 price;
        if (timeElapsed < 3600 && !project.fixedPrice) {
            price =
                (((((project.reservePrice * 15 ** 8) / (10 ** 8)) /
                    (15 ** (timeElapsed / 450))) *
                    (10 ** (timeElapsed / 450))) / 10 ** 14) *
                10 ** 14;

            return price;
        } else {
            return project.reservePrice;
        }
    }

    /**
     * @notice Mint tokens to an address (artist only)
     * @dev Mints a given number of tokens to a specified address. Can only be called by the project owner.
     * @param seeds The seeds for which to mint.
     * @param a The address to which the tokens will be minted.
     */
    function artistMint(bytes32[] calldata seeds, address a) public onlyOwner {
        uint256 totalSupply = _owners.length;
        require(totalSupply + seeds.length < project.maxSupply, "Minted out");
        require(block.timestamp < project.endingTimeStamp, "Mint ended");
        require(seeds.length < 5, "Mint max four per tx");
        if (!project.fixedPrice) {
            require(
                ((block.timestamp > project.biddingStartTimeStamp + 3600) ||
                    (block.timestamp < project.biddingStartTimeStamp)),
                "No artist mint during auction"
            );
        }

        for (uint256 i; i < seeds.length; ) {
            require(hashToTokenId[seeds[i]] == 0, "Seed already used");
            require(tokenIdToHash[0] != seeds[i], "Seed already used");

            unchecked {
                uint256 tokenId = totalSupply + i;
                _mint(a, tokenId);
                tokenIdToHash[tokenId] = seeds[i];
                hashToTokenId[seeds[i]] = tokenId;
                i++;
            }
        }
        unchecked {
            project.artistAuctionWithdrawalsClaimed =
                project.artistAuctionWithdrawalsClaimed +
                uint24(seeds.length);
        }
    }

    /**
     * @notice Mint a token to an allow listed address if conditions met.
     * @dev Mints a token to a specified address if that address is on the project's allow list and has not already claimed a token.
     * @param proof The proof of inclusion in the project's Merkle tree.
     * @param a The address to which the token will be minted.
     * @param seed The seeds for the mint.
     */
    function allowListMint(
        bytes32[] memory proof,
        address a,
        bytes32 seed
    ) public payable {
        require(
            block.timestamp > project.allowListStartTimeStamp,
            "Allow list mint not started"
        );
        require(
            block.timestamp < project.biddingStartTimeStamp,
            "Allow list mint ended"
        );
        require(
            MerkleProofUpgradeable.verify(
                proof,
                project.merkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Not on allow list"
        );
        require(addressToClaimed[msg.sender] == false, "Already claimed");

        uint256 totalSupply = _owners.length;

        require(totalSupply + 1 < project.maxSupply, "Minted out");
        require(project.reservePrice <= msg.value, "Invalid funds provided");
        require(msg.sender == tx.origin, "No contract minting");

        require(hashToTokenId[seed] == 0, "Seed already used");
        require(tokenIdToHash[0] != seed, "Seed already used");

        unchecked {
            uint256 tokenId = totalSupply;
            addressToClaimed[msg.sender] = true;
            project.totalAllowListMints = project.totalAllowListMints + 1;
            _mint(a, tokenId);
            tokenIdToHash[tokenId] = seed;
            hashToTokenId[seed] = tokenId;
        }
    }

    /**
     * @notice Mint tokens to an address through a Dutch auction until reserve price is met, while checking for various conditions.
     * @dev Mints a given number of tokens to a specified address through a Dutch auction process that ends when the reserve price is met. Also checks various conditions such as max supply, minimum and maximum number of tokens that can be minted per transaction, and that the sender is not a contract.
     * @param seeds The seeds for which to mint.
     * @param a The address to which the tokens will be minted.
     */
    function mint(bytes32[] calldata seeds, address a) public payable {
        uint256 totalSupply = _owners.length;
        uint256 price = currentPrice();
        uint256 total = seeds.length * price;
        require(
            block.timestamp > project.biddingStartTimeStamp,
            "Mint not started"
        );
        require(totalSupply + seeds.length < project.maxSupply, "Minted out");
        require(seeds.length > 0, "Mint at least one");
        require(seeds.length < 5, "Mint max four per tx");
        require(total <= msg.value, "Invalid funds provided");
        require(msg.sender == tx.origin, "No contract minting");

        if (price != project.reservePrice) {
            addressToTotalAndCount[a] = TotalAndCount(
                uint128(addressToTotalAndCount[a].total + msg.value),
                addressToTotalAndCount[a].count + uint128(seeds.length)
            );
        }
        if (
            totalSupply + seeds.length == project.maxSupply - 1 &&
            !project.fixedPrice
        ) {
            project.lastSalePrice = uint96(price);
        }

        for (uint256 i; i < seeds.length; ) {
            require(hashToTokenId[seeds[i]] == 0, "Seed already used");
            require(tokenIdToHash[0] != seeds[i], "Seed already used");
            unchecked {
                uint256 tokenId = totalSupply + i;

                _mint(a, tokenId);
                tokenIdToHash[tokenId] = seeds[i];
                hashToTokenId[seeds[i]] = tokenId;
                i++;
            }
        }
    }

    /**
     * @notice Claim a rebate for each token minted at a higher price than the final price
     * @param a The address to which the rebate is paid.
     */
    function claimRebate(address payable a) public {
        require(
            block.timestamp > project.biddingStartTimeStamp + 3600,
            "Rebate phase has not started"
        );
        uint256 finalPrice;

        if (
            _owners.length < (project.maxSupply - 1) ||
            project.lastSalePrice == 0
        ) {
            finalPrice = project.reservePrice;
        } else {
            finalPrice = project.lastSalePrice;
        }

        uint256 rebate = addressToTotalAndCount[msg.sender].total -
            (addressToTotalAndCount[msg.sender].count * finalPrice);

        delete addressToTotalAndCount[msg.sender];
        a.transfer(rebate);
    }

    /**
     * @notice Get the hash associated with a given tokenId.
     * @param _id The ID of the token.
     * @return The hash associated with the given tokenId.
     */
    function getHashFromTokenId(uint256 _id) public view returns (bytes32) {
        return tokenIdToHash[_id];
    }

    /**
     * @notice Withdraw funds from the contract
     * @dev Transfers a percentage of the balance to the 256ART address and optionally a third party, the rest to the artist address.
     */
    function withdraw() public {
        require(
            (msg.sender == project.twoFiveSix ||
                msg.sender == project.artistAddress ||
                msg.sender == project.thirdPartyAddress),
            "Not allowed"
        );

        uint256 totalSupply = _owners.length;

        uint256 finalPrice;
        uint256 balance;

        if (project.fixedPrice) {
            balance = address(this).balance;
        } else {
            require(
                block.timestamp > project.biddingStartTimeStamp + 3600,
                "Auction still in progress"
            );
            if (
                _owners.length < (project.maxSupply - 1) ||
                project.lastSalePrice == 0
            ) {
                finalPrice = project.reservePrice;
            } else {
                finalPrice = project.lastSalePrice;
            }
            balance =
                ((totalSupply -
                    project.totalAllowListMints -
                    project.artistAuctionWithdrawalsClaimed) * finalPrice) +
                ((project.totalAllowListMints -
                    project.artistAllowListWithdrawalsClaimed) *
                    project.reservePrice);
        }

        require(balance > 0, "Balance is zero");

        project.artistAuctionWithdrawalsClaimed = uint24(
            totalSupply - project.totalAllowListMints
        );
        project.artistAllowListWithdrawalsClaimed = uint24(
            project.totalAllowListMints
        );

        if (project.thirdPartyAddress == address(0)) {
            uint256 twoFiveSixBalance = (balance * project.twoFiveSixShare) /
                10000;
            uint256 artistBalance = balance - twoFiveSixBalance;

            project.twoFiveSix.transfer(twoFiveSixBalance);
            project.artistAddress.transfer(artistBalance);
        } else {
            uint256 twoFiveSixBalance = (balance * project.twoFiveSixShare) /
                10000;
            uint256 thirdPartyBalance = (balance * project.thirdPartyShare) /
                10000;
            uint256 artistBalance = balance -
                twoFiveSixBalance -
                thirdPartyBalance;

            project.twoFiveSix.transfer(twoFiveSixBalance);
            project.thirdPartyAddress.transfer(thirdPartyBalance);
            project.artistAddress.transfer(artistBalance);
        }
    }

    function walletOfOwner(
        address _owner
    ) public view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) return new uint256[](0);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function batchTransferFrom(
        address _from,
        address _to,
        uint256[] memory _tokenIds
    ) public {
        for (uint256 i; i < _tokenIds.length; i++) {
            transferFrom(_from, _to, _tokenIds[i]);
        }
    }

    function batchSafeTransferFrom(
        address _from,
        address _to,
        uint256[] memory _tokenIds,
        bytes memory data_
    ) public {
        for (uint256 i; i < _tokenIds.length; i++) {
            safeTransferFrom(_from, _to, _tokenIds[i], data_);
        }
    }

    function isOwnerOf(
        address account,
        uint256[] calldata _tokenIds
    ) external view returns (bool) {
        for (uint256 i; i < _tokenIds.length; ++i) {
            if (_owners[_tokenIds[i]] != account) return false;
        }

        return true;
    }

    function _mint(address to, uint256 tokenId) internal virtual override {
        _owners.push(to);
        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @notice Calculates the royalty information for a given sale.
     * @dev Implements the required royaltyInfo function for the ERC2981 standard.
     * @param _salePrice The sale price of the token being sold.
     * @return receiver The address of the royalty recipient.
     * @return royaltyAmount The amount of royalty to be paid.
     */
    function royaltyInfo(
        uint256,
        uint256 _salePrice
    ) external view returns (address receiver, uint256 royaltyAmount) {
        return (project.royaltyAddress, (_salePrice * project.royalty) / 10000);
    }

    /**
     * @notice Converts a bytes16 value to its hexadecimal representation as a bytes32 value.
     * @param data The bytes16 value to convert.
     * @return result The hexadecimal representation of the input value as a bytes32 value.
     */
    function toHex16(bytes16 data) internal pure returns (bytes32 result) {
        result =
            (bytes32(data) &
                0xFFFFFFFFFFFFFFFF000000000000000000000000000000000000000000000000) |
            ((bytes32(data) &
                0x0000000000000000FFFFFFFFFFFFFFFF00000000000000000000000000000000) >>
                64);
        result =
            (result &
                0xFFFFFFFF000000000000000000000000FFFFFFFF000000000000000000000000) |
            ((result &
                0x00000000FFFFFFFF000000000000000000000000FFFFFFFF0000000000000000) >>
                32);
        result =
            (result &
                0xFFFF000000000000FFFF000000000000FFFF000000000000FFFF000000000000) |
            ((result &
                0x0000FFFF000000000000FFFF000000000000FFFF000000000000FFFF00000000) >>
                16);
        result =
            (result &
                0xFF000000FF000000FF000000FF000000FF000000FF000000FF000000FF000000) |
            ((result &
                0x00FF000000FF000000FF000000FF000000FF000000FF000000FF000000FF0000) >>
                8);
        result =
            ((result &
                0xF000F000F000F000F000F000F000F000F000F000F000F000F000F000F000F000) >>
                4) |
            ((result &
                0x0F000F000F000F000F000F000F000F000F000F000F000F000F000F000F000F00) >>
                8);
        result = bytes32(
            0x3030303030303030303030303030303030303030303030303030303030303030 +
                uint256(result) +
                (((uint256(result) +
                    0x0606060606060606060606060606060606060606060606060606060606060606) >>
                    4) &
                    0x0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F) *
                7
        );
    }

    /**
     * @dev Converts a bytes32 value to its hexadecimal representation as a string.
     * @param data The bytes32 value to convert.
     * @return The hexadecimal representation of the bytes32 value, as a string.
     */
    function toHex(bytes32 data) private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "0x",
                    toHex16(bytes16(data)),
                    toHex16(bytes16(data << 128))
                )
            );
    }

    /**
     * @dev Generates an array of random numbers based on a seed value.
     * @param seed The seed value used to generate the random numbers.
     * @param timesToCall The number of random numbers to generate.
     * @return An array of random numbers with length equal to `timesToCall`.
     */
    function generateRandomNumbers(
        bytes32 seed,
        uint256 timesToCall
    ) private pure returns (uint256[] memory) {
        uint256[] memory randNumbers = new uint256[](timesToCall);

        for (uint256 i; i < timesToCall; i++) {
            uint256 r = uint256(
                keccak256(abi.encodePacked(uint256(seed) + i))
            ) % 10000;
            randNumbers[i] = r;
        }

        return randNumbers;
    }

    /**
     * @notice Returns a string containing base64 encoded HTML code which renders the artwork associated with the given tokenId directly from chain.
     * @dev This function reads traits and libraries from the storage and uses them to generate the HTML code for the artwork.
     * @param tokenId The ID of the token whose artwork will be generated.
     * @return artwork A string containing the base64 encoded HTML code for the artwork.
     */
    function getTokenHtml(
        uint256 tokenId
    ) public view returns (string memory artwork) {
        require(_exists(tokenId), "Token not found");

        bytes32 tokenHash = getHashFromTokenId(tokenId);

        string memory artScript;
        string memory libraryScripts;
        string memory traits;
        string memory blockParams;

        if (project.libraryScripts != address(0)) {
            LibraryScript[] memory librariesArray = abi.decode(
                SSTORE2.read(project.libraryScripts),
                (LibraryScript[])
            );
            for (uint256 l; l < librariesArray.length; l++) {
                IFileStorage fileStoreFrontEnd = IFileStorage(
                    librariesArray[l].fileStoreFrontEnd
                );
                libraryScripts = string.concat(
                    "await ls256('",
                    fileStoreFrontEnd.readFile(
                        librariesArray[l].fileStore,
                        librariesArray[l].fileName
                    ),
                    "');"
                );
            }
        }

        if (project.traits != address(0)) {
            traits = ",";
            Trait[] memory traitsArray = abi.decode(
                SSTORE2.read(project.traits),
                (Trait[])
            );

            uint256[] memory randNumbers = generateRandomNumbers(
                tokenHash,
                traitsArray.length
            );

            for (uint256 j = 0; j < traitsArray.length; j++) {
                uint256 r = randNumbers[j];
                for (uint256 k = 0; k < traitsArray[j].weights.length; k++) {
                    if (r < traitsArray[j].weights[k]) {
                        traits = string.concat(
                            traits,
                            "'",
                            traitsArray[j].name,
                            "'",
                            ":'",
                            traitsArray[j].values[k],
                            "'"
                        );
                        if (j < traitsArray.length - 1) {
                            traits = string.concat(traits, ",");
                        }
                        break;
                    }
                }
            }
        }

        blockParams = string.concat(
            ", 'ownerOfPiece' : '",
            StringsUpgradeable.toHexString(
                uint256(uint160(ownerOf(tokenId))),
                20
            ),
            "', 'blockHash' : '",
            toHex(blockhash(block.number - 1)),
            "', 'blockNumber' : ",
            StringsUpgradeable.toString(block.number),
            ", 'prevrandao' : ",
            StringsUpgradeable.toString(block.prevrandao),
            ", 'totalSupply' : ",
            StringsUpgradeable.toString(_owners.length),
            ", 'balanceOfOwner' : ",
            StringsUpgradeable.toString(balanceOf(ownerOf(tokenId)))
        );

        for (uint256 i; i < project.artScripts.length; i++) {
            IArtScript artscriptToGet = IArtScript(project.artScripts[i]);
            artScript = string.concat(artScript, artscriptToGet.artScript());
        }

        return
            string.concat(
                "data:text/html;base64,",
                Base64Upgradeable.encode(
                    abi.encodePacked(
                        "<html><head><script>let inputData={'tokenId': ",
                        StringsUpgradeable.toString(tokenId),
                        ",'hash': '",
                        toHex(tokenHash),
                        "'",
                        traits,
                        blockParams,
                        "};",
                        "</script>",
                        "<meta name='viewport' content='width=device-width, initial-scale=1, maximum-scale=1'><style type='text/css'>html{height:100%;width:100%;}body{height:100%;width:100%;margin:0;padding:0;background-color:#000000;}canvas{display:block;max-width:100%;max-height:100%;padding:0;margin:auto;display:block;position:absolute;top:0;bottom:0;left:0;right:0;object-fit:contain;}</style>",
                        "</head><body><script defer>async function ls256(e){let t=new TextDecoder,a=window.atob(e),n=a.length,r=new Uint8Array(n);for(var o=0;o<n;o++)r[o]=a.charCodeAt(o);let d=r.buffer;let c=new ReadableStream({start(e){e.enqueue(d),e.close()}}).pipeThrough(new DecompressionStream('gzip')),i=await new Response(c),p=await i.arrayBuffer(),l=await t.decode(p),s=document.createElement('script');s.type='text/javascript',s.appendChild(document.createTextNode(l)),document.body.appendChild(s)};async function la256(){",
                        libraryScripts,
                        "await ls256('",
                        artScript,
                        "');"
                        "};la256();</script></body></html>"
                    )
                )
            );
    }

    /**
     * @notice Returns the metadata of the token with the given ID, including name, artist, description, license, image and animation URL, and attributes.
     * @dev It returns a base64 encoded JSON object which conforms to the ERC721 metadata standard.
     * @param _tokenId The ID of the token to retrieve metadata for.
     * @return A base64 encoded JSON object that contains the metadata of the given token.
     */
    function tokenURI(
        uint256 _tokenId
    ) public view override returns (string memory) {
        require(_exists(_tokenId), "Token not found");

        bytes32 tokenHash = getHashFromTokenId(_tokenId);

        IArtInfo artInfoToGet = IArtInfo(project.artInfo);

        string memory imageBase;
        string memory librariesUsed = ',"libraries_used": "';
        string memory attributes;

        if (bytes(project.imageBase).length != 0) {
            imageBase = string.concat(
                ',"image":"',
                project.imageBase,
                StringsUpgradeable.toString(_tokenId),
                '"'
            );
        }

        if (project.libraryScripts != address(0)) {
            LibraryScript[] memory librariesArray = abi.decode(
                SSTORE2.read(project.libraryScripts),
                (LibraryScript[])
            );
            for (uint256 l; l < librariesArray.length; l++) {
                librariesUsed = string.concat(
                    librariesUsed,
                    librariesArray[l].fileName,
                    " "
                );
            }
        } else {
            librariesUsed = string.concat(librariesUsed, "None");
        }

        if (project.traits != address(0)) {
            Trait[] memory traitsArray = abi.decode(
                SSTORE2.read(project.traits),
                (Trait[])
            );
            uint256[] memory randNumbers = generateRandomNumbers(
                getHashFromTokenId(_tokenId),
                traitsArray.length
            );
            for (uint256 j = 0; j < traitsArray.length; j++) {
                uint256 r = randNumbers[j];
                for (uint256 k = 0; k < traitsArray[j].weights.length; k++) {
                    if (r < traitsArray[j].weights[k]) {
                        attributes = string.concat(
                            attributes,
                            '{"trait_type":"',
                            traitsArray[j].name,
                            '", "value":"',
                            traitsArray[j].descriptions[k],
                            '"}'
                        );
                        if (j < traitsArray.length - 1) {
                            attributes = string.concat(attributes, ",");
                        }
                        break;
                    }
                }
            }
        }

        return
            string.concat(
                "data:application/json;base64,",
                Base64Upgradeable.encode(
                    abi.encodePacked(
                        '{"name":"',
                        project.name,
                        " #",
                        StringsUpgradeable.toString(_tokenId),
                        '", "artist":"',
                        artInfoToGet.artist(),
                        '","description":"',
                        artInfoToGet.description(),
                        '","license":"',
                        artInfoToGet.license(),
                        '","hash":"',
                        toHex(tokenHash),
                        '"',
                        librariesUsed,
                        '"',
                        imageBase,
                        ',"animation_url":"',
                        getTokenHtml(_tokenId),
                        '","attributes":[',
                        attributes,
                        "]}"
                    )
                )
            );
    }

    /**
     * @notice Allows to set the image base URL for the project (owner)
     * @dev Only callable by the owner
     * @param _imageBase String representing the base URL for images
     */
    function setImageBase(string calldata _imageBase) public onlyOwner {
        project.imageBase = _imageBase;
    }

    /**
     * @notice Sets the maximum number of tokens that can be minted for the project (owner)
     * @dev Only the owner of the contract can call this function.
     * @dev The new maximum supply must be greater than the current number of tokens minted
     * and less than the current maximum supply
     * @param _maxSupply The new maximum number of tokens that can be minted
     */
    function setMaxSupply(uint24 _maxSupply) public onlyOwner {
        require(_maxSupply > _owners.length, "Too low");
        require(_maxSupply < project.maxSupply, "Too high");
        project.maxSupply = _maxSupply;
    }

    /**
     * @notice Allows to set the art scripts for the project
     * @param _artScripts Array of addresses representing the art scripts
     */
    function setArtScripts(address[] calldata _artScripts) public onlyOwner {
        project.artScripts = _artScripts;
    }

    /**
     * @notice Allows to set the library scripts for the project
     * @param _libraries Array of LibraryScript objects representing the library scripts
     */
    function setLibraryScripts(
        LibraryScript[] calldata _libraries
    ) public onlyOwner {
        project.libraryScripts = SSTORE2.write(abi.encode(_libraries));
    }

    /**
     * @notice Returns the reserve price for the project
     * @dev This function is view only
     * @return uint256 Representing the reserve price for the project
     */
    function getReservePrice() external view returns (uint256) {
        return project.reservePrice;
    }

    /**
     * @notice Returns the address of the ArtInfo contract used in the project
     * @dev This function is view only
     * @return address Representing the address of the ArtInfo contract
     */
    function getArtInfo() external view returns (address) {
        return project.artInfo;
    }

    /**
     * @notice Returns an array with the addresses storing the art script used in the project
     * @dev This function is view only
     * @return address[] Array of addresses storing the art script used in the project
     */
    function getArtScripts() external view returns (address[] memory) {
        return project.artScripts;
    }

    /**
     * @notice Returns the maximum number of tokens that can be minted for the project
     * @dev This function is view only
     * @return uint256 Representing the maximum number of tokens that can be minted
     */
    function getMaxSupply() external view returns (uint256) {
        return project.maxSupply - 1;
    }

    /**
     * @notice Returns the timestamp of the bidding start for the project
     * @dev This function is view only
     * @return uint256 Representing the timestamp of the bidding start
     */
    function getBiddingStartTimeStamp() external view returns (uint256) {
        return project.biddingStartTimeStamp;
    }

    /**
     * @notice Returns the timestamp of the allowlist start for the project
     * @dev This function is view only
     * @return uint256 Representing the timestamp of the allowlist start
     */
    function getallowListStartTimeStamp() external view returns (uint256) {
        return project.allowListStartTimeStamp;
    }
}

interface IArtScript {
    function artScript() external pure returns (string memory);
}

interface IArtInfo {
    function artist() external pure returns (string memory);

    function description() external pure returns (string memory);

    function license() external pure returns (string memory);
}

interface IFileStorage {
    function readFile(
        address fileStore,
        string calldata filename
    ) external pure returns (string memory);
}