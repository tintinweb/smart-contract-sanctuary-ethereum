// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC721Psi.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";
import "./SafeMath.sol";

error OnlyExternallyOwnedAccountsAllowed();
error SaleNotStarted();
error AmountExceedsSupply();
error InsufficientPayment();

contract ApeMinerVerse is ERC721Psi, Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    uint256 public constant MAX_SUPPLY = 1000;
    uint256 private constant FAR_FUTURE = 0xFFFFFFFFF;

    uint256 private _publicSaleStart;
    uint256 private _showTimeStart = FAR_FUTURE;
    string private _baseTokenURI;
    bytes32 private _merkleRoot;

    uint256 private _price;

    event publicSaleStart();
    event publicSalePaused();
    event baseUIRChanged(string);
    event showTimeNotStart();
    event showTimeStart();

    modifier onlyEOA() {
        if (tx.origin != msg.sender)
            revert OnlyExternallyOwnedAccountsAllowed();
        _;
    }

    constructor(
        string memory baseURI,
        uint256 price,
        bytes32 root
    ) ERC721Psi("ApeMinerVerse", "AMV") {
        _baseTokenURI = baseURI;
        _price = price;
        _merkleRoot = root;
        _publicSaleStart = block.timestamp;
    }

    // publicSale

    function isPublicSaleActive() public view returns (bool) {
        return block.timestamp > _publicSaleStart;
    }

    function isShowTimeStart() public view returns (bool) {
        return block.timestamp > _showTimeStart;
    }

    function verifyWhiteList(bytes32[] calldata _merkleProof)
        external
        view
        returns (bool)
    {
        return (
            !MerkleProof.verify(
                _merkleProof,
                _merkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            )
        );
    }

    function whiteListMint(bytes32[] calldata _merkleProof, uint8 quantity)
        external
        payable
        onlyEOA
        nonReentrant
    {
        require(isPublicSaleActive(), "Sale Not Started");
        require(!isShowTimeStart(), "Sales Finished");
        if (totalSupply() + quantity > MAX_SUPPLY) revert AmountExceedsSupply();

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        if (!MerkleProof.verify(_merkleProof, _merkleRoot, leaf))
            revert("Not in white list");

        uint256 cost = _price.mul(quantity).mul(9).div(10);
        if (msg.value < cost) revert InsufficientPayment();

        _mint(msg.sender, quantity);

        // Refund overpayment
        if (msg.value > cost) {
            // payable(msg.sender).transfer(msg.value.sub(cost));
            (bool success, ) = msg.sender.call{value: msg.value.sub(cost)}("");
            require(success, "transfer failed");
        }
    }

    function publicSaleMint(uint256 quantity)
        external
        payable
        onlyEOA
        nonReentrant
    {
        if (!isPublicSaleActive()) revert SaleNotStarted();
        if (totalSupply() + quantity > MAX_SUPPLY) revert AmountExceedsSupply();

        uint256 cost = _price.mul(quantity);
        if (msg.value < cost) revert InsufficientPayment();

        _mint(msg.sender, quantity);

        // Refund overpayment
        if (msg.value > cost) {
            // payable(msg.sender).transfer(msg.value.sub(cost));
            (bool success, ) = msg.sender.call{value: msg.value.sub(cost)}("");
            require(success, "transfer failed");
        }
    }

    // METADATA

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function tokensOf(address owner) public view returns (uint256[] memory) {
        uint256 count = balanceOf(owner);
        uint256[] memory tokenIds = new uint256[](count);
        for (uint256 i; i < count; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(owner, i);
        }
        return tokenIds;
    }

    // DISPLAY

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "nonexistent token");

        if (!isShowTimeStart())
            return string(abi.encodePacked(_baseURI(), "cover.json"));
        else
            return
                string(
                    abi.encodePacked(_baseURI(), _toString(tokenId), ".json")
                );
    }

    // OWNERS + HELPERS

    function startPublicSale() external onlyOwner {
        _publicSaleStart = block.timestamp;

        emit publicSaleStart();
    }

    function pausePublicSale() external onlyOwner {
        _publicSaleStart = FAR_FUTURE;
        emit publicSalePaused();
    }

    function startShowTime() external onlyOwner {
        _showTimeStart = block.timestamp;
        emit showTimeStart();
    }

    function pauseShowTime() external onlyOwner {
        _showTimeStart = FAR_FUTURE;
        emit showTimeNotStart();
    }

    function setURInew(string memory uri)
        external
        onlyOwner
        returns (string memory)
    {
        _baseTokenURI = uri;
        emit baseUIRChanged(uri);
        return _baseTokenURI;
    }

    // Team/Partnerships & Community
    function marketingMint(uint256 quantity) external onlyOwner {
        if (totalSupply() + quantity > MAX_SUPPLY) revert AmountExceedsSupply();

        _mint(owner(), quantity);
    }

    function withdraw() external onlyOwner nonReentrant {
        // payable(owner()).transfer(address(this).balance);
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "transfer failed");
    }

    /**
     * @dev Converts a uint256 to its ASCII string decimal representation.
     */
    function _toString(uint256 value)
        internal
        pure
        virtual
        returns (string memory str)
    {
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit),
            // but we allocate 0x80 bytes to keep the free memory pointer 32-byte word aligned.
            // We will need 1 32-byte word to store the length,
            // and 3 32-byte words to store a maximum of 78 digits. Total: 0x20 + 3 * 0x20 = 0x80.
            str := add(mload(0x40), 0x80)
            // Update the free memory pointer to allocate.
            mstore(0x40, str)

            // Cache the end of the memory to calculate the length later.
            let end := str

            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for { let temp := value } 1 {} {
                str := sub(str, 1)
                // Write the character to the pointer.
                // The ASCII index of the '0' character is 48.
                mstore8(str, add(48, mod(temp, 10)))
                // Keep dividing `temp` until zero.
                temp := div(temp, 10)
                // prettier-ignore
                if iszero(temp) { break }
            }

            let length := sub(end, str)
            // Move the pointer 32 bytes leftwards to make room for the length.
            str := sub(str, 0x20)
            // Store the length.
            mstore(str, length)
        }
    }
}


// Generated by /Users/iwan/work/brownie/ApeMiner/scripts/functions.py