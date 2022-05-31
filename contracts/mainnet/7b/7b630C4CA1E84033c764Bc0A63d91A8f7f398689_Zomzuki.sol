// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721A.sol";
import "./IERC721.sol";
import "./MerkleProof.sol";

contract Zomzuki is ERC721A, Ownable {
    uint256 public price = 0.01 ether;
    uint256 public maxTotalSupply = 4000;
    uint256 public saleStartTime;
    string private baseURI;
    address public RugzukiAddress = 0xc1c18105B3d6C32A2aa408e4Ff46177B62b5e96e;
    bytes32 public root;

    constructor() ERC721A("Zomzuki", "ZOMZUKI") {
        
    }

    modifier mintableSupply(uint256 _quantity) {
        require(
            totalSupply() + _quantity <= maxTotalSupply,
            "Over maximum supply."
        );
        _;
    }

    modifier saleActive() {
        require(saleStartTime <= block.timestamp, "Sale not start yet.");
        _;
    }

    function checkWhitelist(bytes32[] calldata merkleProof)
        public
        view
        returns (bool)
    {
        return
            MerkleProof.verify(
                merkleProof,
                root,
                keccak256(abi.encodePacked(msg.sender))
            );
    }

    function mintZoomzuki(uint256 _quantity, bytes32[] calldata merkleProof)
        external
        payable
        saleActive
        mintableSupply(_quantity)
    {
        if (checkWhitelist(merkleProof)) {
            uint256 balance = IERC721(RugzukiAddress).balanceOf(msg.sender);
            uint256 minted = _numberMinted(msg.sender);

            if (balance > minted) {
                if (balance - minted < _quantity)
                    require(
                        msg.value >= price * (_quantity - balance + minted),
                        "Insufficent funds."
                    );
            } else {
                require(msg.value >= price * _quantity, "Insufficent funds.");
            }
        } else {
            require(msg.value >= price * _quantity, "Insufficent funds.");
        }

        _safeMint(msg.sender, _quantity);
    }

    function setMintPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setMerkleRoot(bytes32 _root) external onlyOwner {
        root = _root;
    }

    function setSaleTime(uint256 _time) external onlyOwner {
        saleStartTime = _time;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
}