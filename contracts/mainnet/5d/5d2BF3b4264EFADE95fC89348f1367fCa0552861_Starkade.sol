// SPDX-License-Identifier: AGPL-3.0
// ©2022 Ponderware Ltd

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

interface IReverseResolver {
    function claim(address owner) external returns (bytes32);
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

interface IMoonCatSVGS {
    function uint2str (uint value) external pure returns (string memory);
}

interface IMetadata {
    function legionMetadata (uint256 tokenId) external view returns (string memory);
}

/*
 * @title STARKADE Legion
 * @author Ponderware Ltd
 * @dev ERC-721 contract for Starkade Legion NFT
 * @notice license: https://starkade.com/licences/nft/starkade-legion/
 */
contract Starkade is IERC721Enumerable, IERC721Metadata {

    string public IPFS_URI_Prefix = "https://starkade-legion.mypinata.cloud/ipfs/";
    string public IPFS_Pass_Folder = "";
    string public IPFS_Core_Folder = "";
    string public IPFS_Legion_Folder = "";

    address public MetadataContractAddress;

    address public contractOwner;
    address internal flightlistSigner;

    bool public paused = true;

    string public name = "STARKADE";
    string public symbol = unicode"💫";

    address[7015] private Owners;
    mapping (address => uint256[]) internal TokensByOwner;
    uint16[7015] internal OwnerTokenIndex;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private TokenApprovals;
    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private OperatorApprovals;

    uint256 internal constant maxSupply = 7015;
    uint256 public totalSupply = 0;

    enum State
    {
     Ready,
     SaleOpen,
     RevealPrepped,
     Revealed
    }

    State public contractState = State.Ready;

    uint256 public saleOpenBlock;

    bytes32 public revealHash;
    uint256 public revealBlock;
    bytes32 public revealSeed;

    uint256 public coreRaffleIncrement;
    uint256[8] internal Primes = [81918643972203779099,
                                  72729269248899238429,
                                  19314683338901247061,
                                  38707402401747623009,
                                  54451314435228525599,
                                  16972551169207064863,
                                  44527956848616763003,
                                  51240633499522341181];

    uint256 coreRaffleOffset;

    /**
     * @dev Begin the reveal process by submitting the ipfs asset CIDs and a commitment hash of a secret "seed" value
     */
    function setSeedHash (bytes32 hash, string calldata ipfsCore, string calldata ipfsLegion) public onlyOwner {
        require(contractState == State.SaleOpen ||
                contractState == State.RevealPrepped,
                "Invalid State");
        require(block.number > revealBlock + 200);
        contractState = State.RevealPrepped;
        revealHash = hash;
        revealBlock = block.number;
        IPFS_Core_Folder = ipfsCore;
        IPFS_Legion_Folder = ipfsLegion;
    }

    /**
     * @dev Reveal all legion NFTs and determine core indexes by combining the value of the seed with blockhashes
     */
    function reveal (uint256 seed) public onlyOwner {
        require(block.number > revealBlock + 4
                && block.number < revealBlock + 200,
                "Block Range");
        require(contractState == State.RevealPrepped, "Already Revealed");
        require(keccak256(abi.encodePacked(seed)) == revealHash, "Seed Mismatch");
        revealSeed = keccak256(abi.encodePacked(seed,
                                                blockhash(revealBlock + 1),
                                                blockhash(revealBlock + 2),
                                                blockhash(revealBlock + 3)));
        coreRaffleOffset = uint256(revealSeed) % (totalSupply - 5);
        coreRaffleIncrement = Primes[uint256(revealSeed) % 8];
        contractState = State.Revealed;
    }

    /**
     * @dev Return the coreIndex of a token (only valid if returned value is < 15)
     */
    function coreIndex (uint256 tokenId) internal view returns (uint256) {
        if (tokenId < 5) {
            return tokenId;
        } else {
            return ((coreRaffleIncrement * (tokenId - 5) + coreRaffleOffset) % (totalSupply - 5)) + 5;
        }
    }

    /**
     * @dev Return whether a given tokenId represents a core character and, if so, the associated coreIndex
     */
    function isCore (uint256 tokenId) public view returns (bool, uint256) {
        uint256 coreIdx = coreIndex(tokenId);
        if (coreIdx < 15) {
            return (true, coreIdx);
        } else {
            return (false, 0);
        }
    }

    /* Minting/Passes */

    uint256 constant FLIGHTLIST_ISSUANCE_DELAY = 830; // Approximately 3 hours time

    uint256 public price = 0.08 ether;

    uint256 giftCutoff = 8000;
    uint256 flightlistCutoff = 8000;

    /**
     * @dev Set mint price
     */
    function setPrice (uint256 priceWei) public onlyOwner {
        price = priceWei;
    }

    /**
     * @dev Begin token sale
     */
    function openSale () public onlyOwner {
        require(contractState == State.Ready, "Not Ready");
        contractState = State.SaleOpen;
        saleOpenBlock = block.number;
        giftCutoff = totalSupply;
    }

    /**
     * @dev Bookeeping for pass issuance
     */
    function issuePassHelper (address recipient, uint256 passId) private whenNotPaused {
        TokensByOwner[recipient].push(passId);
        OwnerTokenIndex[passId] = uint16(TokensByOwner[recipient].length);
        Owners[passId] = recipient;
        emit Transfer(address(0), recipient, passId);
    }

    /**
     * @dev Allow contract owner to give a single pass
     */
    function givePass (address recipient) public onlyOwner {
        require(contractState == State.SaleOpen
                || contractState == State.Ready,
                "Sale Closed");
        require(totalSupply < maxSupply, "Max Supply Exceeded");
        issuePassHelper(recipient, totalSupply);
        totalSupply++;
    }

    /**
     * @dev Allow contract owner to give multiple passes
     */
    function givePasses (address[] calldata recipients) public onlyOwner {
        require(contractState == State.SaleOpen
                || contractState == State.Ready,
                "Sale Closed");
        require((totalSupply + recipients.length) <= maxSupply, "Max Supply Exceeded");
        for (uint i = 0; i < recipients.length; i++) {
            issuePassHelper(recipients[i], totalSupply + i);
        }
        totalSupply += recipients.length;
    }

    /**
     * @dev Check if a flightpass represents the given recipient and is signed by the flightlistSigner address
     */
    function validFlightlistPass (address recipient, bytes memory pass) public view returns (bool) {
        bytes32 m = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", keccak256(abi.encodePacked("flightlisted", recipient))));

        uint8 v;
        bytes32 r;
        bytes32 s;

        require(pass.length == 65, "Invalid Flightpass");

        assembly {
            r := mload(add(pass, 32))
            s := mload(add(pass, 64))
            v := byte(0, mload(add(pass, 96)))
        }

        return (ecrecover(m, v, r, s) == flightlistSigner);
    }

    /**
     * @dev Mint one or more tokens to the provided address
     */
    function mint (address recipient, uint256 quantity, bytes memory pass) public payable {
        if (quantity > 10) {
            quantity = 10;
        }

        require(contractState == State.SaleOpen, "Sale Closed");

        if (block.number < saleOpenBlock + (8 * FLIGHTLIST_ISSUANCE_DELAY)) {
            require(validFlightlistPass(recipient, pass), "Invalid Flightpass");
            require(balanceOf(recipient) == 0, "Preflight Claimed");
            quantity = 1;
        } else if (block.number < saleOpenBlock + (9 * FLIGHTLIST_ISSUANCE_DELAY)) {
            require(validFlightlistPass(recipient, pass), "Invalid Flightpass");
            require(balanceOf(recipient) + quantity <= 11, "Flightpass limit exceeded");
        } else if (flightlistCutoff == 8000) {
            flightlistCutoff = totalSupply;
        }

        require((totalSupply + quantity) <= maxSupply, "Max Supply Exceeded");

        uint256 cost = price * quantity;
        require(msg.value >= cost, "Insufficient Funds");

        for (uint i = 0; i < quantity; i++) {
            issuePassHelper(recipient, totalSupply + i);
        }

        totalSupply += quantity;

        if (msg.value > cost) {
            (bool success,) = payable(msg.sender).call{value: msg.value - cost}("");
            require(success, "Refund Transfer Failed");
        }

    }

    /**
     * @dev Withdraw collected ETH to the contractOwner address
     */
    function withdraw () public {
        payable(contractOwner).transfer(address(this).balance);
    }

    /**
     * @dev Determine which issuance window a pass was minted in: 0 => Gift; 1 => Flightlist; 2 => General Sale
     */
    function passType (uint256 tokenId) public view returns (uint8) {
        require(tokenExists(tokenId), "Nonexistent Token");
        if (tokenId < giftCutoff) return 0;
        if (tokenId < flightlistCutoff) return 1;
        return 2;
    }

    /* SVG Assembly */

    IMoonCatSVGS MoonCatSVGS = IMoonCatSVGS(0xB39C61fe6281324A23e079464f7E697F8Ba6968f);

    /**
     * @dev Assemble one png layer of the SVG composite
     */
    function svgLayer (uint16 componentId)
        internal
        view
        returns (bytes memory)
    {
        return abi.encodePacked("<image x=\"0\" y=\"0\" width=\"600\" height=\"600\" href=\"",
                                IPFS_URI_Prefix,
                                IPFS_Legion_Folder,
                                "/",
                                MoonCatSVGS.uint2str(componentId),
                                ".png\" />");
    }

    /**
     * @dev Assemble the full SVG image for a legion fighter
     */
    function assembleSVG (uint16[13] memory componentIds) internal view returns (string memory) {
        bytes memory svg = "<svg xmlns=\"http://www.w3.org/2000/svg\" preserveAspectRatio=\"xMidYMid meet\" viewBox=\"0 0 600 600\" width=\"600\" height=\"600\">";
        for (uint i = 0; i < 12; i++) {
            svg = abi.encodePacked(svg, svgLayer(componentIds[i]));
        }
        return string(abi.encodePacked(svg, "</svg>"));
    }

    /* Enumerable */

    function tokenByIndex(uint256 tokenId) public view returns (uint256) {
        require(tokenExists(tokenId), "Nonexistent Token");
        return tokenId;
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) {
        require(index < balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return TokensByOwner[owner][index];
    }

    /* Owner Functions */

    constructor(address flightlistSigningAddress, string memory ipfsPass) {
        contractOwner = msg.sender;
        flightlistSigner = flightlistSigningAddress;
        // https://docs.ens.domains/contract-api-reference/reverseregistrar#claim-address
        IReverseResolver(0x084b1c3C81545d370f3634392De611CaaBFf8148).claim(msg.sender);
        configureCities();
        IPFS_Pass_Folder = ipfsPass;
    }

    /**
     * @dev Reset the flightlist signing address used for passes
     */
    function setFlightlistSigningAddress (address flightlistSigningAddress) public onlyOwner {
        flightlistSigner = flightlistSigningAddress;
    }

    /**
     * @dev Set the contract address for on-chain metadata assembly
     */
    function setMetadataContract (address metadata) public onlyOwner {
        MetadataContractAddress = metadata;
    }

    /**
     * @dev Set the URI prefix for accessing ipfs resources through a gateway
     */
    function setIpfsURIPrefix (string calldata ipfsURIPrefix) public onlyOwner {
        IPFS_URI_Prefix = ipfsURIPrefix;
    }

    /**
     * @dev Change the owner of the contract
     */
    function transferOwnership(address newOwner) public onlyOwner {
        contractOwner = newOwner;
    }

    function pause () public onlyOwner {
        paused = true;
    }

    function unpause () public onlyOwner {
        paused = false;
    }

    /**
     * @dev Public method to fetch a core character or assemble the image of a legion character on-chain (or passes, if not yet revealed)
     */
    function tokenImage (uint256 tokenId) public view returns (string memory) {
        require(tokenExists(tokenId), "Nonexistent Token");
        if (contractState == State.Revealed) {
            uint256 coreIdx = coreIndex(tokenId);
            if(coreIdx < 15) {
                return string(abi.encodePacked("ipfs://", IPFS_Core_Folder, "/", MoonCatSVGS.uint2str(coreIdx), ".png"));
            } else {
                uint256 dna = getDNA(tokenId);
                (uint16[13] memory components,,,) = getTraitComponents(tokenId, dna);
                return assembleSVG(components);
            }
        } else {
            return string(abi.encodePacked("ipfs://", IPFS_Pass_Folder, "/", MoonCatSVGS.uint2str(passType(tokenId)), ".png"));
        }
    }

    /**
     * @notice tokenURIs are returned as IPFS URIs for core characters and on-chain generated BASE64 encoded JSON for legion characters (or IPFS URIs for passes, if not yet revealed)
     * @dev JSON data is generated by a call to an external metadata contract
     */
    function tokenURI(uint256 tokenId) public view returns (string memory) {
        require(tokenId < totalSupply, "ERC721Metadata: URI query for nonexistent token");
        if (contractState == State.Revealed) {
            uint256 coreIdx = coreIndex(tokenId);
            if (coreIdx < 15) {
                return string(abi.encodePacked("ipfs://", IPFS_Core_Folder, "/", MoonCatSVGS.uint2str(coreIdx), ".json"));
            } else {
                return IMetadata(MetadataContractAddress).legionMetadata(tokenId);
            }
        } else {
            return string(abi.encodePacked("ipfs://", IPFS_Pass_Folder, "/", MoonCatSVGS.uint2str(passType(tokenId)), ".json"));
        }
    }

    function tokenExists(uint256 tokenId) public view returns (bool) {
        return (tokenId < totalSupply);
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        require(tokenExists(tokenId), "ERC721: Nonexistent token");
        return Owners[tokenId];
    }

    function balanceOf(address owner) public view returns (uint256) {
        return TokensByOwner[owner].length;
    }

    function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
        return
            interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC721Enumerable).interfaceId;
    }

    function _approve(address to, uint256 tokenId) internal {
        TokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    function approve(address to, uint256 tokenId) public  {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
                msg.sender == owner || isApprovedForAll(owner, msg.sender),
                "ERC721: approve caller is not owner nor approved for all"
                );
        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) public view returns (address) {
        require(tokenId < totalSupply, "ERC721: approved query for nonexistent token");
        return TokenApprovals[tokenId];
    }

    function isApprovedForAll(address owner, address operator) public view  returns (bool) {
        return OperatorApprovals[owner][operator];
    }

    function setApprovalForAll(
                               address operator,
                               bool approved
                               ) external virtual {
        require(msg.sender != operator, "ERC721: approve to caller");
        OperatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
        size := extcodesize(account)
                }
        return size > 0;
    }

    function _checkOnERC721Received(
                                    address from,
                                    address to,
                                    uint256 tokenId,
                                    bytes memory _data
                                    ) private returns (bool) {
        if (isContract(to)) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
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

    function _transfer(
                       address from,
                       address to,
                       uint256 tokenId
                       ) private whenNotPaused {
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");
        require(block.number > saleOpenBlock + (9 * FLIGHTLIST_ISSUANCE_DELAY), "Flightlist Active");
        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        uint16 valueIndex = OwnerTokenIndex[tokenId];
        uint256 toDeleteIndex = valueIndex - 1;
        uint256 lastIndex = TokensByOwner[from].length - 1;
        if (lastIndex != toDeleteIndex) {
            uint256 lastTokenId = TokensByOwner[from][lastIndex];
            TokensByOwner[from][toDeleteIndex] = lastTokenId;
            OwnerTokenIndex[lastTokenId] = valueIndex;
        }
        TokensByOwner[from].pop();

        TokensByOwner[to].push(tokenId);
        OwnerTokenIndex[tokenId] = uint16(TokensByOwner[to].length);

        Owners[tokenId] = to;
        emit Transfer(from, to, tokenId);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(tokenId < totalSupply, "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function transferFrom(
                          address from,
                          address to,
                          uint256 tokenId
                          ) public {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(
                              address from,
                              address to,
                              uint256 tokenId
                              ) public {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
                              address from,
                              address to,
                              uint256 tokenId,
                              bytes memory _data
                              ) public {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }


    function _safeTransfer(
                           address from,
                           address to,
                           uint256 tokenId,
                           bytes memory _data
                           ) private {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /* Modifiers */

    modifier onlyOwner() {
        require(msg.sender == contractOwner, "Not Owner");
        _;
    }

    modifier whenNotPaused() {
        require(paused == false, "Paused");
        _;
    }

    modifier whenRevealed() {
        require(contractState == State.Revealed, "Not Revealed");
        _;
    }


    /* Rescuers */
    /**
    * @dev Rescue ERC20 assets sent directly to this contract.
    */
    function withdrawForeignERC20(address tokenContract) public onlyOwner {
        IERC20 token = IERC20(tokenContract);
        token.transfer(contractOwner, token.balanceOf(address(this)));
        }

    /**
     * @dev Rescue ERC721 assets sent directly to this contract.
     */
    function withdrawForeignERC721(address tokenContract, uint256 tokenId) public onlyOwner {
        IERC721(tokenContract).safeTransferFrom(address(this), contractOwner, tokenId);
    }

    /* Tokens */

    string[3] public PassTypeNames =
        [
         "Signalnoise",
         "Flight List",
         "STARKADE"
         ];

    string[182] internal Tokens =
        [
         "",
         "None",
         "$Magna",
         "Aeon",
         "Agile",
         "Ai",
         "Arcade",
         "Arm",
         "Armband",
         "Arms",
         "Arrows",
         "Athletic",
         "Aviators",
         "Awesome",
         "Back",
         "Bangs",
         "Basher",
         "Beefy",
         "Biker",
         "Black",
         "Blaster",
         "Blonde",
         "Blue",
         "Bounty",
         "Braids",
         "Bronco",
         "Camo",
         "Cap",
         "Chaos",
         "Choker",
         "Classic",
         "Clenched",
         "Comms",
         "Crash",
         "CrossStrap",
         "Cyan",
         "Cyber",
         "CyberBangs",
         "CyberWolf",
         "Digital",
         "Doomsday",
         "Double",
         "Dreadlocks",
         "Earring",
         "Elv",
         "Evil",
         "Eye",
         "Eyes",
         "Fangs",
         "Field",
         "Finisher",
         "Fire",
         "Flaming",
         "Flash",
         "Focussed",
         "Force",
         "Fortress",
         "Frostware",
         "Future",
         "GM",
         "Gem",
         "Green",
         "Grimm",
         "Grin",
         "Growl",
         "Grump",
         "Half-sleeves",
         "Hat",
         "Headphones",
         "Helmet",
         "Hex",
         "Hood",
         "Ice",
         "JacK",
         "Jacket",
         "Jet",
         "Kentaro",
         "Laugh",
         "Lavaware",
         "Leather",
         "Legion",
         "Leopard",
         "Lightning",
         "Line",
         "Long",
         "Magic",
         "Magna",
         "Magnaton",
         "Mask",
         "Mauve",
         "Mech",
         "Meh",
         "Merc",
         "Mohawk",
         "Morningstar",
         "Multi",
         "Necro",
         "NeonFire",
         "NuTech",
         "OG",
         "Obrakian",
         "Ochre",
         "Ombre",
         "Orange",
         "Pads",
         "Panther",
         "Paradise",
         "Patch",
         "Pink",
         "Pods",
         "Ponderware",
         "Ponytail",
         "Pout",
         "Power",
         "Punk",
         "Purple",
         "Rad",
         "Rain",
         "Rainbow",
         "Rev",
         "Ripped",
         "Robo",
         "Rocker",
         "SN",
         "Samurai",
         "Savage",
         "Shade",
         "Shades",
         "SharpShooter",
         "Shave",
         "Short",
         "Showhawk",
         "Side",
         "Silver",
         "Skull",
         "Sleeves",
         "Smile",
         "Sneer",
         "Spear",
         "Spears",
         "Spectran",
         "Spiked",
         "Spikes",
         "Staff",
         "Staffs",
         "Starkadian",
         "Stay",
         "Stealth",
         "Strapped",
         "Strike",
         "Stripe",
         "Stripes",
         "Stubble",
         "SunFire",
         "Sweep",
         "Swoosh",
         "Sword",
         "Syndicate",
         "Tattoos",
         "Tawny",
         "Tezukan",
         "Tongue",
         "Toothy",
         "Tribe",
         "VR",
         "Vapour",
         "Vest",
         "Visor",
         "Visualiser",
         "Volta",
         "Volume",
         "Warrior",
         "Wave",
         "Whip",
         "White",
         "Wig",
         "Wild",
         "Windblown",
         "Wink",
         "Yell",
         "Zebra",
         "Shaved"
         ];

    /* Trait Names */

    uint8[996] internal TraitNames =
        [
         17 , 0  , 0  , 11 , 0  , 0  , 86 , 117, 0  , 51 , 0  , 0  , 82 , 0  , 0  ,
         28 , 0  , 103, 28 , 0  , 108, 28 , 0  , 22 , 28 , 0  , 115, 113, 0  , 103,
         113, 0  , 108, 113, 0  , 22 , 113, 0  , 115, 86 , 143, 0  , 173, 0  , 0  ,
         20 , 0  , 0  , 75 , 109, 0  , 94 , 0  , 0  , 41 , 139, 0  , 55 , 49 , 0  ,
         10 , 0  , 0  , 138, 0  , 0  , 156, 0  , 0  , 86 , 143, 0  , 173, 0  , 0  ,
         20 , 0  , 0  , 75 , 109, 0  , 94 , 0  , 0  , 41 , 139, 0  , 144, 0  , 0  ,
         10 , 0  , 0  , 138, 0  , 0  , 156, 0  , 0  , 89 , 0  , 0  , 35 , 0  , 0  ,
         44 , 0  , 0  , 101, 0  , 0  , 159, 0  , 0  , 89 , 0  , 0  , 35 , 0  , 0  ,
         44 , 0  , 0  , 101, 0  , 0  , 159, 0  , 0  , 13 , 0  , 0  , 39 , 106, 0  ,
         157, 0  , 0  , 123, 134, 0  , 180, 0  , 22 , 145, 0  , 0  , 2  , 0  , 0  ,
         59 , 0  , 0  , 180, 0  , 108, 80 , 0  , 0  , 146, 116, 0  , 26 , 0  , 0  ,
         169, 62 , 0  , 39 , 106, 0  , 98 , 0  , 0  , 123, 134, 0  , 81 , 0  , 0  ,
         145, 0  , 0  , 2  , 0  , 0  , 105, 0  , 0  , 180, 0  , 108, 80 , 0  , 0  ,
         151, 0  , 0  , 26 , 0  , 0  , 5  , 0  , 0  , 145, 0  , 0  , 38 , 0  , 0  ,
         128, 0  , 0  , 126, 0  , 0  , 57 , 0  , 0  , 99 , 0  , 0  , 34 , 0  , 0  ,
         160, 0  , 0  , 80 , 0  , 115, 80 , 0  , 174, 100, 0  , 22 , 100, 0  , 61 ,
         5  , 0  , 0  , 145, 0  , 0  , 60 , 0  , 0  , 128, 0  , 0  , 126, 0  , 0  ,
         57 , 0  , 0  , 23 , 0  , 0  , 34 , 0  , 0  , 147, 0  , 0  , 80 , 0  , 174,
         78 , 0  , 0  , 87 , 0  , 0  , 100, 0  , 61 , 53 , 0  , 0  , 3  , 0  , 108,
         3  , 0  , 174, 1  , 0  , 0  , 40 , 0  , 0  , 16 , 0  , 19 , 16 , 0  , 108,
         16 , 0  , 115, 152, 0  , 0  , 36 , 163, 108, 36 , 163, 115, 53 , 0  , 0  ,
         3  , 0  , 108, 3  , 0  , 174, 1  , 0  , 0  , 171, 47 , 0  , 150, 0  , 0  ,
         16 , 0  , 22 , 16 , 0  , 115, 16 , 0  , 174, 36 , 163, 108, 36 , 163, 115,
         48 , 0  , 0  , 161, 0  , 0  , 162, 136, 0  , 91 , 0  , 0  , 31 , 0  , 0  ,
         65 , 0  , 0  , 77 , 0  , 0  , 137, 0  , 0  , 63 , 0  , 0  , 179, 0  , 0  ,
         48 , 0  , 0  , 161, 0  , 0  , 162, 136, 0  , 112, 0  , 0  , 31 , 0  , 0  ,
         137, 0  , 19 , 64 , 0  , 0  , 137, 0  , 0  , 136, 0  , 0  , 179, 0  , 0  ,
         90 , 0  , 0  , 153, 0  , 0  , 72 , 0  , 0  , 97 , 0  , 0  , 96 , 0  , 0  ,
         45 , 0  , 0  , 85 , 0  , 0  , 178, 0  , 0  , 30 , 0  , 0  , 54 , 0  , 0  ,
         90 , 0  , 0  , 153, 0  , 0  , 72 , 0  , 0  , 97 , 0  , 0  , 96 , 0  , 0  ,
         45 , 0  , 0  , 85 , 0  , 0  , 178, 0  , 0  , 30 , 0  , 0  , 54 , 0  , 0  ,
         36 , 46 , 0  , 118, 167, 0  , 124, 88 , 108, 134, 88 , 108, 164, 167, 0  ,
         46 , 107, 0  , 124, 88 , 61 , 83 , 127, 0  , 134, 88 , 174, 168, 0  , 0  ,
         60 , 0  , 0  , 33 , 88 , 0  , 121, 167, 108, 127, 0  , 133, 127, 0  , 19 ,
         127, 0  , 108, 12 , 0  , 0  , 50 , 88 , 22 , 50 , 88 , 115, 43 , 0  , 0  ,
         36 , 46 , 0  , 118, 167, 0  , 124, 88 , 103, 134, 88 , 115, 164, 167, 0  ,
         46 , 107, 0  , 57 , 88 , 0  , 83 , 127, 0  , 134, 88 , 103, 168, 0  , 0  ,
         60 , 0  , 0  , 121, 167, 19 , 121, 167, 174, 127, 0  , 133, 127, 0  , 19 ,
         125, 127, 0  , 12 , 0  , 0  , 50 , 88 , 103, 50 , 88 , 61 , 43 , 0  , 0  ,
         93 , 0  , 108, 124, 84 , 22 , 155, 0  , 174, 42 , 0  , 115, 176, 0  , 19 ,
         176, 0  , 174, 124, 0  , 174, 93 , 0  , 19 , 172, 0  , 115, 93 , 0  , 174,
         124, 84 , 174, 172, 0  , 174, 155, 0  , 19 , 42 , 0  , 174, 177, 0  , 19 ,
         131, 0  , 19 , 177, 0  , 108, 141, 0  , 19 , 141, 0  , 21 , 130, 142, 19 ,
         130, 142, 21 , 124, 0  , 19 , 124, 84 , 19 , 155, 0  , 21 , 172, 0  , 19 ,
         102, 0  , 0  , 93 , 0  , 115, 24 , 0  , 115, 141, 14 , 22 , 132, 129, 174,
         37 , 0  , 22 , 37 , 0  , 115, 154, 0  , 108, 130, 0  , 115, 111, 0  , 108,
         141, 130, 35 , 141, 84 , 35 , 141, 84 , 174, 130, 0  , 174, 24 , 0  , 22 ,
         132, 129, 19 , 111, 0  , 19 , 170, 0  , 0  , 141, 14 , 19 , 141, 130, 174,
         141, 84 , 19 , 15 , 0  , 108, 15 , 0  , 174, 93 , 0  , 19 , 154, 0  , 19 ,
         76 , 74 , 108, 6  , 74 , 0  , 50 , 104, 115, 36 , 7  , 0  , 128, 9  , 0  ,
         5  , 9  , 0  , 126, 9  , 0  , 76 , 74 , 22 , 92 , 104, 115, 40 , 104, 108,
         40 , 104, 115, 36 , 158, 0  , 73 , 9  , 174, 18 , 166, 0  , 79 , 74 , 19 ,
         148, 104, 0  , 149, 104, 108, 149, 104, 22 , 50 , 104, 22 , 145, 9  , 0  ,
         73 , 9  , 115, 70 , 9  , 103, 120, 135, 0  , 76 , 74 , 95 , 6  , 74 , 0  ,
         114, 166, 0  , 36 , 7  , 0  , 128, 9  , 0  , 5  , 9  , 0  , 126, 9  , 0  ,
         92 , 104, 95 , 141, 104, 0  , 40 , 104, 19 , 36 , 158, 0  , 73 , 9  , 174,
         29 , 0  , 115, 56 , 104, 0  , 79 , 74 , 174, 66 , 0  , 0  , 149, 104, 108,
         4  , 104, 0  , 145, 9  , 0  , 73 , 9  , 115, 29 , 0  , 19 , 120, 135, 0  ,
         8  , 0  , 0  , 128, 69 , 0  , 38 , 69 , 0  , 52 , 134, 0  , 73 , 69 , 174,
         5  , 69 , 0  , 121, 69 , 0  , 110, 69 , 108, 73 , 69 , 19 , 126, 69 , 0  ,
         119, 69 , 19 , 110, 69 , 22 , 119, 69 , 115, 25 , 67 , 0  , 122, 175, 0  ,
         71 , 0  , 22 , 71 , 0  , 115, 80 , 27 , 0  , 68 , 0  , 0  , 32 , 0  , 0  ,
         58 , 167, 0  , 128, 69 , 0  , 57 , 69 , 0  , 52 , 134, 0  , 73 , 69 , 174,
         5  , 69 , 0  , 78 , 69 , 0  , 110, 69 , 108, 73 , 69 , 19 , 126, 69 , 0  ,
         119, 69 , 19 , 110, 69 , 22 , 119, 69 , 115, 165, 88 , 0  , 25 , 67 , 0  ,
         140, 69 , 0  , 71 , 0  , 22 , 71 , 0  , 174, 80 , 27 , 0  , 68 , 0  , 0  ,
         32 , 0  , 0  , 181, 0  , 0
         ];

    /*
     * @dev Assemble the name associated with a traitIndex by building TraitNames from their associated Tokens
     */
    function traitName (uint256 traitIndex) public view returns (string memory) {
        uint256 baseIndex = traitIndex * 3;
        uint8 index1 = TraitNames[baseIndex];
        uint8 index2 = TraitNames[baseIndex + 1];
        uint8 index3 = TraitNames[baseIndex + 2];
        bytes memory result = bytes(Tokens[index1]);
        if (index2 > 0) {
            result = abi.encodePacked(result, " ", Tokens[index2]);
        }
        if (index3 > 0) {
            result = abi.encodePacked(result, ": ", Tokens[index3]);
        }
        return string(result);
    }

    string[7] public RegionNames =
      ["Shoreridge",
       "Skyroar Mountains",
       "Ark Teknos",
       "The Wailands",
       "Aeon Morrow",
       "Neowave Desert",
       "Grinferno Plains"];

    struct City {
        uint8 region;
        string name;
        string characteristic;
        uint8[5] bonus;
    }
    mapping (uint256 => City) internal Cities;

    /*
     * @dev Initialize Cities
     */
    function configureCities() internal {
        //                Rg. CityName             Characteristic   Po En Sp De Ch
        Cities[0] =  City(0, "Fellbreeze",         "Idealistic",   [0, 15, 0, 0, 0]);
        Cities[1] =  City(1, "Driftwood Quay",     "Imposing",     [0, 0, 0, 15, 0]);
        Cities[2] =  City(2, "Westforge",          "Industrious",  [15, 0, 0, 0, 0]);
        Cities[3] =  City(3, "Stonebrigg",         "Regimented",   [5, 0, 0, 5, 5]);
        Cities[4] =  City(3, "Kingdom of Spectra", "Fantastical",  [0, 0, 0, 0, 15]);
        Cities[5] =  City(4, "Magnaton City",      "Proud",        [5, 10, 0, 0, 0]);
        Cities[6] =  City(4, "Los Astra",          "Boisterous",   [0, 10, 0, 5, 0]);
        Cities[7] =  City(5, "Tezuka",             "Adaptable",    [0, 10, 0, 5, 0]);
        Cities[8] =  City(6, "Castor Locke",       "Cosmopolitan", [5, 5, 5, 0, 0]);
        Cities[9] =  City(6, "Obrak",              "Resourceful",  [0, 5, 5, 0, 5]);
        Cities[10] = City(6, "Warren Lake",        "Grim",         [5, 0, 5, 5, 0]);
        Cities[11] = City(6, "Brawna",             "Optimistic",   [0, 10, 5, 0, 0]);
    }

    /*
     * @dev Get info about a particular city
     */
    function cityInfo (uint256 cityId) public view returns (string memory regionName, string memory cityName, string memory characteristic) {
        require(cityId < 12, "Invalid cityId");
        City memory city = Cities[cityId];
        regionName = RegionNames[city.region];
        cityName = city.name;
        characteristic = city.characteristic;
    }

    //                                   Pow Ene Spe Def Cha
    uint8[55] public EquipmentBonuses = [ 0,  0,  0,  0,  0,
                                          0,  0,  0,  0, 15,
                                          5,  5,  5,  0,  0,
                                         15,  0,  0,  0,  0,
                                          0,  0, 15,  0,  0,
                                          5,  0,  0, 10,  0,
                                         10,  0,  0,  5,  0,
                                          0,  0,  5, 10,  0,
                                          0,  5, 10,  0,  0,
                                          5,  0,  5,  5,  0,
                                         10,  0,  5,  0,  0];

    string[5] public BoostNames =
        ["Power",
         "Energy",
         "Speed",
         "Defence",
         "Chaos"];

    /*
     * @dev Determines the bonus associated with a trait based on its rarity
     */
    function determineTraitBonus (uint8 strand)
        internal
        pure
        returns (uint8)
    {
        if (strand < 4) {
            return 6; // UltraRare
        } else if (strand < 24) {
            return 5; // Rare
        } else if (strand < 96) {
            return 4; // Uncommon
        } else {
            return 3; // Common
        }
    }

    /*
     * @dev Computes the component and bonus associated with an indexed trait
     */
    function determineTraitValue (uint256 dna,
                                  bool altBodyType,
                                  uint8 traitIndex,
                                  uint16 traitOffset,
                                  uint8 numElite,
                                  uint8 numRare,
                                  uint8 numUncommon,
                                  uint8 numCommon)

        internal
        pure
        returns (uint16 componentIndex, uint8 traitBonus)
    {
        uint8 strand = uint8(dna >> (traitIndex * 8));

        traitBonus = determineTraitBonus(strand);

        componentIndex = traitOffset;

        if (traitBonus == 6) {
            // UltraRare
            componentIndex += strand % numElite;
        } else if (traitBonus == 5) {
            // Rare
            componentIndex += (strand % numRare) + numElite;
        } else if (traitBonus == 4) {
            // Uncommon
            componentIndex += (strand % numUncommon) + numElite + numRare;
        } else {
            // Common
            componentIndex += (strand % numCommon) + numElite + numRare + numUncommon;
        }

        if (altBodyType) {
            componentIndex += (numElite + numRare + numUncommon + numCommon);
        }
    }


    mapping (uint256 => uint8) public Equipped;

    enum EquipmentSelectionStates
    {
     Open,
     Closed,
     Frozen
    }


    EquipmentSelectionStates public equipmentSelectionState = EquipmentSelectionStates.Closed;

    /*
     * @dev Allow equipment selection
     */
    function openEquipmentSelection () public onlyOwner {
        require (equipmentSelectionState == EquipmentSelectionStates.Closed, "Not Closed");
        equipmentSelectionState = EquipmentSelectionStates.Open;
    }

    /*
     * @dev Temporarily halt equipment selection
     */
    function closeEquipmentSelection () public onlyOwner {
        require (equipmentSelectionState == EquipmentSelectionStates.Open, "Not Open");
        equipmentSelectionState = EquipmentSelectionStates.Closed;
    }

    /*
     * @dev Permanently halt equipment selection
     */
    function permanentlyFreezeEquimentSelection () public onlyOwner {
        equipmentSelectionState = EquipmentSelectionStates.Frozen;
    }

    /*
     * @dev One-time selection of equipment for a legion character as an index from 1 through 5 into their specific equipment options
     */
    function chooseEquipment (uint256 tokenId, uint8 choice) public whenRevealed {
        require(ownerOf(tokenId) == msg.sender, "Not owner");
        require(choice > 0 && choice <= 5, "Invalid Choice");
        require(Equipped[tokenId] == 0, "Already Equipped");
        require(equipmentSelectionState == EquipmentSelectionStates.Open, "Not Open");
        Equipped[tokenId] = choice;
    }

    /*
     * @dev Process a tokenId into its associated DNA sequence by combining with the revealSeed (not applicable to core characters)
     */
    function getDNA (uint256 tokenId) public view returns (uint256) {
        require (coreIndex(tokenId) >= 15, "Core Character");
        return uint256(keccak256(abi.encodePacked(revealSeed, tokenId)));
    }

    /*
     * @dev Determine the pseudorandom selection of equipment available to a specific legion character
     */
    function equipmentOptions (uint256 dna) internal pure returns (uint8[5] memory) {

        uint16 equipmentSeed = uint8(dna >> 16);
        uint8[5] memory options;
        for (uint8 i = 0; i < 10; i++) {
            uint8 index = uint8((13 * i + equipmentSeed) % 10);
            if(index < 5) {
                options[index] = i + 1;
            }
        }

        return options;
    }

    uint16 constant EQUIPMENT_OFFSET = 13;
    uint16 constant SKIN_TONE_OFFSET = 33;

    /*
     * @dev Convert token DNA into an array of trait components, total bonus, active equipment, and body type
     */
    function getTraitComponents (uint256 tokenId, uint256 dna)
        internal
        view
        returns (uint16[13] memory components, uint8 totalBonus, uint8 equipmentId, bool alt)
    {

        alt = (dna >> 252 & 1) == 1;
        bool head = (dna >> 253 & 1) == 1; // Hair or Head Gear
        bool wear = (dna >> 254 & 1) == 1; // Shirt or Armour

        uint8 tempBonus;

        (components[0], tempBonus) = determineTraitValue(dna, false, 0, 2, 1, 2, 4, 4); // Background
        totalBonus += tempBonus;

        uint8 equipmentOption = Equipped[tokenId];
        if (equipmentOption > 0) {
            uint8[5] memory options = equipmentOptions(dna);
            equipmentId = options[equipmentOption - 1];
            components[1] = equipmentId - 1 + EQUIPMENT_OFFSET;
            if (alt) {
                components[1] += 10;
            }
        } else {
            components[1] = 96;
        }


        components[2] = uint16((((dna >> 24) & 255) % 5) + SKIN_TONE_OFFSET);
        if (alt) {
            components[2] += 5; // Skin Tone
        }

        if (wear) {
            (components[3], tempBonus) = determineTraitValue(dna, alt, 3, 43, 1, 3, 3, 5); // Shirt
            components[4] = 96;
        } else {
            (components[4], tempBonus) = determineTraitValue(dna, alt, 4, 67, 1, 2, 4, 6); // Armour
            components[3] = 96;
        }
        totalBonus += tempBonus;

        (components[5], tempBonus) = determineTraitValue(dna, alt, 5, 93, 1, 3, 3, 4); // Face Paint
        totalBonus += tempBonus;
        (components[6], tempBonus) = determineTraitValue(dna, alt, 6, 115, 1, 1, 4, 4); // Mouth
        totalBonus += tempBonus;
        (components[7], tempBonus) = determineTraitValue(dna, alt, 7, 135, 1, 4, 3, 2); // Eyes
        totalBonus += tempBonus;
        (components[8], tempBonus) = determineTraitValue(dna, alt, 8, 155, 3, 4, 6, 7); // Face Gear
        totalBonus += tempBonus;

        if (head) {
            (components[9], tempBonus) = determineTraitValue(dna, alt, 9, 195, 4, 5, 6, 10); // Hair
            components[11] = 96;
        } else {
            (components[11], tempBonus) = determineTraitValue(dna, alt, 11, 291, 3, 4, 6, 7); // Head Gear
            components[9] = 331;
        }
        totalBonus += tempBonus;

        (components[10], tempBonus) = determineTraitValue(dna, alt, 10, 245, 2, 4, 7, 10); // Gear
        totalBonus += tempBonus;

        components[12] = uint16((dna >> 96)) % 12; // City

    }

    /*
     * @dev Compute the boosts for each of Power, Energy, Speed, Defence, & Chaos
     */
    function getBoosts (uint256 dna, uint16 cityId, uint8 traitBonus, uint8 equipmentId) internal view returns (uint8[5] memory boosts) {
        uint8[5] memory cityBonus = Cities[cityId].bonus;

        for (uint i = 0; i < 10; i++) {
            uint boostId = (dna >> (i * 2 + 14 * 8)) & 3;
            while (boosts[boostId] >= 20) {
                if(boostId == 3) {
                    boostId = 0;
                } else {
                    boostId++;
                }
            }
            boosts[boostId] += 5;
        }

        for (uint i = 0; i < 5; i++) {
            boosts[i] += 10 + traitBonus + cityBonus[i] + EquipmentBonuses[equipmentId * 5 + i];
        }

        return boosts;
    }

    /*
     * @dev Public method for fetching the 5 pseudorandom equipment options for a legion character
     */
    function getEquipmentOptions (uint256 tokenId) public view whenRevealed returns (uint8[5] memory) {
        return equipmentOptions(getDNA(tokenId));
    }

    string[16] public Attributes =
        ["Body Type",
         "Background",
         "Equipment",
         "Skin Tone",
         "Shirt",
         "Armour",
         "Face Paint",
         "Mouth",
         "Eyes",
         "Face Gear",
         "Hair",
         "Gear",
         "Head Gear",
         "Region",
         "City",
         "Characteristic"];

    /*
     * @dev Return human-readable traits and boosts, along with a generated SVG for the provided tokenId (not applicable to core characters)
     */
    function getTraits (uint256 tokenId) public view whenRevealed returns (string[16] memory attributes, uint8[5] memory boosts, string memory image) {
        //  ** Attributes **
        //  0 - Body Type
        //  1 - Background
        //  2 - Equipment
        //  3 - Skin Tone
        //  4 - Shirt
        //  5 - Armour
        //  6 - Face Paint
        //  7 - Mouth
        //  8 - Eyes
        //  9 - Face Gear
        // 10 - Hair
        // 11 - Gear
        // 12 - Head Gear
        // 13 - Region
        // 14 - City
        // 15 - Characteristic

        // ** Boosts **
        //  0 - Power
        //  1 - Energy
        //  2 - Speed
        //  3 - Defence
        //  4 - Chaos

        uint256 dna = getDNA(tokenId);
        (uint16[13] memory components, uint8 totalBonus, uint8 equipmentId, bool alt) = getTraitComponents(tokenId, dna);
        boosts = getBoosts(dna, components[12], totalBonus, equipmentId);

        if(alt) {
            attributes[0] = traitName(1);
        } else {
            attributes[0] = traitName(0);
        }

        for (uint i = 0; i < 12; i++) {
            attributes[i + 1] = traitName(components[i]);
        }

        City memory city = Cities[components[12]];

        attributes[13] = RegionNames[city.region];
        attributes[14] = city.name;
        attributes[15] = city.characteristic;

        image = assembleSVG(components);
    }

    /*
     * @dev Return attributes and boosts for metadata or other contract consumption
     */
    function getTraitIndexes (uint256 tokenId) public view whenRevealed returns (uint16[15] memory attributes, uint8[5] memory boosts) {
        uint256 dna = getDNA(tokenId);
        (uint16[13] memory components, uint8 totalBonus, uint8 equipmentId, bool alt) = getTraitComponents(tokenId, dna);
        boosts = getBoosts(dna, components[12], totalBonus, equipmentId);

        if(alt) {
            attributes[0] = 1;
        } else {
            attributes[0] = 0;
        }

        for (uint i = 0; i < 12; i++) {
            attributes[i + 1] = components[i];
        }

        City memory city = Cities[components[12]];

        attributes[13] = city.region;
        attributes[14] = components[12];
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Enumerable.sol)

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
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

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