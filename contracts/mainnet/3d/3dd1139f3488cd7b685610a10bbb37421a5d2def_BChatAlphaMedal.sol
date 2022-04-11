// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @creator: bchat
/// @author: bchat
import "./ERC165.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";
import "./IERC20.sol";
import "./ERC721.sol";
import "./Address.sol";
import "./SafeMath.sol";
import "./MerkleProof.sol";
import "./Ownable.sol";
// import "hardhat/console.sol";

// ENS Reverse Lookup Remote Contract https://github.com/ensdomains/reverse-records/blob/master/contracts/ReverseRecords.sol
abstract contract ReverseRecords {
    function getNames(address[] calldata addresses)
        external
        view
        virtual
        returns (string[] memory r);
}

contract BChatAlphaMedal is ReentrancyGuard, Ownable, ERC721, Pausable {
    event ClaimedAlphaMedal(address indexed recipient, uint256 medalToken);

    using Strings for uint256;
    using SafeMath for uint256;

    string private constant _NUMBER_TAG = "<NUM>";
    string private constant _ENS_TAG = "<ENS>";
    string private constant _ADDR_TAG = "<ADDR>";
    string[] private _imageParts;

    ReverseRecords public ensReverseRecords;

    uint256 public currentMedalToken;
    uint256 public totalSupply;
    uint256 public minimumMintValue;
    mapping(address => bool) private _whitelistedAddresses;
    // Owner address => medal number
    mapping(address => uint256) private _claimedMedals;
    bytes32 public merkleRoot;

    constructor(address _ensReverseLookupAddress, uint256 _totalSupply, uint256 _minimumMintValue, bytes32 _merkleRoot)
        ERC721("BChat Alpha Medal", "BCAM")
    {
        ensReverseRecords = ReverseRecords(_ensReverseLookupAddress);
        merkleRoot = _merkleRoot;
        totalSupply = _totalSupply;
        minimumMintValue = _minimumMintValue;
        // Generate SVG template
        _imageParts.push("<svg width='600' height='600' xmlns='http://www.w3.org/2000/svg'>");
        _imageParts.push("<rect x='0' y='0' width='600' height='600' fill='#000000'/>");
        _imageParts.push("<text font-family='Courier New' font-size='70' font-weight='normal' fill='#FFFFFF'><tspan x='43' y='221'>bchat.io</tspan><tspan x='43' y='300'>#");
        _imageParts.push(_NUMBER_TAG);
        _imageParts.push("</tspan></text><text font-family='Courier New' font-size='20' font-weight='normal' fill='#FFFFFF'><tspan x='43' y='534'>");
        _imageParts.push(_ENS_TAG);
        _imageParts.push("</tspan></text><text font-family='Courier New' font-size='20' font-weight='normal' fill='#FFFFFF'><tspan x='43' y='557'>0x");
        _imageParts.push(_ADDR_TAG);
        _imageParts.push("</tspan></text></svg>");
        // 0 is reserved
        currentMedalToken = 0;
        // Pause transfering and trading by default
        _pause();
    }

    // Public functions
    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 medalToken) public view virtual override returns (string memory) {
        string memory tokenIdString = medalToken.toString();
        address medalOwner = ownerOf(medalToken);
        string memory svgString = svgOf(medalOwner);
        return string(abi.encodePacked('data:application/json;utf8,{"name":"BChat Alpha #',
                                        tokenIdString,'", "created_by":"BChat", "image":"data:image/svg+xml;utf8,',
                                        svgString,
                                        '","attributes":[{"trait_type":"Alpha Medal Number","value":"',
                                        tokenIdString,'"}]}'));
    }

    function svgOf(address medalOwner) public view returns (string memory) {
        string[] memory ensNameArray = _addressToENS(medalOwner);
        uint256 medalToken = _claimedMedals[medalOwner];
        require(medalToken != 0, "No medal token");
        string memory ensName = (
            ensNameArray.length > 0 ? ensNameArray[0] : ""
        );
        string memory svg = _svg(medalToken, ensName, medalOwner);
        return svg;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool){
        return interfaceId == type(IERC721).interfaceId
                || ERC721.supportsInterface(interfaceId)
                || interfaceId == type(IERC721Metadata).interfaceId;
    }

    // External functions
    /*
     * Claim a medal to the message sender
     */
    function claimMedal(bytes32[] calldata merkleProof) public payable nonReentrant {
        require(msg.value >= minimumMintValue, "Less than minimum mint value");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(merkleProof, merkleRoot, leaf), "Invalid Merkle Proof");
        _mintMedal(_msgSender());
    }

    // Admin require functions
    function devClaimMedal(address recipient) external onlyOwner nonReentrant {
        _mintMedal(recipient);
    }

    function updateMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function withdrawEth(address payable recipient, uint256 amount) external onlyOwner {
        recipient.transfer(amount);
    }

    function withdrawToken(address recipient, address erc20, uint256 amount) external onlyOwner {
        IERC20(erc20).transfer(recipient, amount);
    }

    function updateMinimumMintValue(uint256 _minimumMintValue) external onlyOwner {
        minimumMintValue = _minimumMintValue;
    }

    /**
     * @dev Pause/resume transfers and trading.
     */
    function setPause(bool newState) external onlyOwner {
        bool isPaused = paused();
        require(isPaused != newState, "paused was already set");
        if (isPaused) {
            _unpause();
        } else {
            _pause();
        }
    }

    // Internal functions
    function _addressToENS(address addr) internal view returns (string[] memory) {
        address[] memory t = new address[](1);
        t[0] = addr;
        return ensReverseRecords.getNames(t);
    }

    function _toAsciiString(address x) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint256 i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint256(uint160(x)) / (2**(8 * (19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2 * i] = _char(hi);
            s[2 * i + 1] = _char(lo);
        }
        return string(s);
    }

    function _char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) {
            return bytes1(uint8(b) + 0x30);
        } else {
            return bytes1(uint8(b) + 0x57);
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);
        require(
            owner() == _msgSender() || !paused() || from == address(0),
            "Transfer while paused"
        );
    }

    // Private functions
    function _mintMedal(address recipient) private {
        require(currentMedalToken < totalSupply, "Exceed total supply");
        require(_claimedMedals[recipient] == 0, "Already claimed");

        currentMedalToken = currentMedalToken.add(1);
        _claimedMedals[recipient] = currentMedalToken;
        _safeMint(recipient, currentMedalToken);
        emit ClaimedAlphaMedal(recipient, currentMedalToken);
    }

    function _svg(uint256 number, string memory ensName, address ensAddr) private view returns (string memory) {
        bytes memory byteString;
        for (uint256 i = 0; i < _imageParts.length; i++) {
            if (_checkTag(_imageParts[i], _NUMBER_TAG)) {
                byteString = abi.encodePacked(byteString, number.toString());
            } else if (_checkTag(_imageParts[i], _ENS_TAG)) {
                byteString = abi.encodePacked(byteString, ensName);
            } else if (_checkTag(_imageParts[i], _ADDR_TAG)) {
                byteString = abi.encodePacked(byteString, _toAsciiString(ensAddr));
            } else {
                byteString = abi.encodePacked(byteString, _imageParts[i]);
            }
        }
        return string(byteString);
    }

    function _checkTag(string storage a, string memory b) private pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }
}