// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./ERC1155.sol";
import "./Strings.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

contract TeaZonePass is ERC1155, Ownable {
    using Strings for uint256;

    uint256 public constant PASS_ID = 0;
    address public communityWallet = 0x8B4eB12745E48851B92aA6c20f1dc15f926204b3;
    bytes32 public merkleRoot =
        0xf1ac2fafa826f86c2ce1b7c1519f021173638248b730d8c2b90ccb6fee098f2f;
    uint256 public price = 0.1 ether;
    uint256 public maxPerWallet = 1;
    uint256 public maxSupply = 444;
    uint256 public minted = 0;
    mapping(address => uint256) public minters;
    bool public paused = true;

    constructor(string memory uri) ERC1155(uri) {
        _setURI(uri);
    }

    function setUri(string memory uri) external onlyOwner {
        _setURI(uri);
    }

    ////////////
    /// Mint ///
    ////////////

    function mint(uint256 quantity, bytes32[] calldata proof)
        external
        payable
        mintCompliance(quantity)
    {
        require(_verify(_msgSender(), proof), "Not on mint list");
        minters[_msgSender()] += quantity;
        minted += quantity;
        _mint(_msgSender(), PASS_ID, quantity, "");
    }

    modifier mintCompliance(uint256 quantity) {
        require(!paused, "Paused");
        require(msg.value == price * quantity, "Invalid price");
        require(quantity > 0 && quantity <= maxPerWallet, "Invalid quantity");
        require(minted + quantity <= maxSupply, "Max supply exceeded");
        require(
            minters[_msgSender()] + quantity <= maxPerWallet,
            "Max per wallet exceeded"
        );
        _;
    }

    function _verify(address wallet, bytes32[] memory proof)
        internal
        view
        returns (bool)
    {
        return MerkleProof.verify(proof, merkleRoot, _leaf(wallet));
    }

    function _leaf(address wallet) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(wallet));
    }

    function setSaleParams(uint256 updatePrice, uint256 updatedMaxPerWallet)
        external
        onlyOwner
    {
        price = updatePrice;
        maxPerWallet = updatedMaxPerWallet;
    }

    function setMerkleRoot(bytes32 root) external onlyOwner {
        merkleRoot = root;
    }

    function setPaused(bool p) external onlyOwner {
        require(paused != p, "Paused should differ");
        paused = p;
    }

    ////////////
    /// Team ///
    ////////////

    function mintTeam(uint256 quantity) external onlyOwner {
        require(minted + quantity <= maxSupply, "Max supply exceeded");
        minted += quantity;
        _mint(communityWallet, PASS_ID, quantity, "");
    }

    function setCommunityWallet(address wallet) external onlyOwner {
        communityWallet = wallet;
    }

    function setMaxSupply(uint256 supply) external onlyOwner {
        require(supply >= minted, "Supply lower than already minted");
        maxSupply = supply;
    }

    function withdraw() external onlyOwner {
        require(address(this).balance > 0, "No balance to withdraw");
        (bool hs, ) = payable(communityWallet).call{
            value: address(this).balance
        }("");
        require(hs, "Withdraw failed");
    }
}