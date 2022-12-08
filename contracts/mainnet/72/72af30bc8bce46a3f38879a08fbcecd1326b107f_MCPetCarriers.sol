// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;
import "./ERC721ABurnable.sol";
import "./ERC721A.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";
import {DefaultOperatorFilterer} from "./DefaultOperatorFilterer.sol";
contract OwnableDelegateProxy {}

/**
 * Used to delegate ownership of a contract to another address, to save on unneeded transactions to approve contract use for users
 */
contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract MCPetCarriers is ERC721ABurnable, DefaultOperatorFilterer, Ownable, ReentrancyGuard {
    using Strings for uint256;
    string public baseURI;
    uint256 public totalWithdrawn = 0;
    uint256 public maxSupply = 3000;
    uint256 public maxMint = 30; // max per transaction
    bool public claimingDisabled = false;
    bool public redeemingDisabled = true;
    bool public burningDisabled = true;

    address public constant MASTERCATS_CONTRACT = 0xF03c4e6b6187AcA96B18162CBb4468FC6E339120;
    address public constant MASTERCATS_VAULT = 0x7d0b3f2F241CaeDE2d6d885Bb6d7f149ecdfba24;
    address public constant SIGNER = 0x918de5F6A7411219D7ea785DCe2d5D6B120B2912;
    
    string _name = "MC Pet Carriers";
    string _symbol = "CARRIER";
    string _initBaseURI = "https://mastercatsnft.io:7777/api/tokens/carriers/";

    address public proxyRegistryAddress = 0xa5409ec958C83C3f309868babACA7c86DCB077c1; // OpenSea Mainnet Proxy Registry address
    
    constructor() ERC721A(_name, _symbol) {
        setBaseURI(_initBaseURI);
    }

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
    
    /* claim signature verification */
    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature) private pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }
    
    function splitSignature(bytes memory sig) private pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, "Invalid signature length");
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }

    function checkClaimSignature(address user, bytes memory signature, uint256 userMaxAllowance) public pure returns (bool) {
        bytes32 messageHash = keccak256(abi.encodePacked(user, userMaxAllowance));
        bytes32 ethSignedMessageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));
        return recoverSigner(ethSignedMessageHash, signature) == SIGNER;
    }

    function checkRedeemSignature(address user, bytes memory signature, uint256[] calldata carrierIds, uint256[] calldata catIds) public pure returns (bool) {
        bytes32 messageHash = keccak256(abi.encodePacked(carrierIds, user, catIds));
        bytes32 ethSignedMessageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));
        return recoverSigner(ethSignedMessageHash, signature) == SIGNER;
    }

    // public redeem (burn) pet carrier to receive cat - requires signature
    function redeemCarrier(uint256[] calldata carrierIds, uint256[] calldata catIds, bytes memory signature) external nonReentrant {
        require(!redeemingDisabled, "Redeeming has been disabled");
        require(carrierIds.length == catIds.length, "Invalid carrierIds and catIds (length mismatch)");
        require(checkRedeemSignature(msg.sender, signature, carrierIds, catIds), "Signature invalid"); // verifies the carrier & cat ids
        for(uint256 i = 0; i < carrierIds.length; ++i) {
            _burn(carrierIds[i], true); // will fail if user does not own carrier/is not approved
            IERC721A(MASTERCATS_CONTRACT).safeTransferFrom(MASTERCATS_VAULT, msg.sender, catIds[i]); // will fail if the vault does not own the cat
        }
    }

    // public claim pet carrier - requires signature
    function claimCarrier(uint256 userMaxAllowance, uint256 claimQty, bytes memory signature) external nonReentrant {
        require(!claimingDisabled, "Claiming has been disabled");
        require(checkClaimSignature(msg.sender, signature, userMaxAllowance), "Signature invalid"); // verifies their allowance
        uint256 userMinted = _numberMinted(msg.sender); // qty user has minted
        uint256 userCanMint = userMaxAllowance - userMinted; // qty user can mint based on existing mints and their allowance
        // restrict to maxMint limit per tx
        if(userCanMint > maxMint) {
            userCanMint = maxMint;
        }
        // restrict to max user can mint
        if(claimQty > userCanMint) {
            claimQty = userCanMint;
        }
        uint256 supply = _totalMinted(); // total minted globally
        require((supply + claimQty) <= maxSupply, "Exceeds max supply");
        _mint(msg.sender, claimQty);
        delete supply;
        delete userMinted;
        delete userCanMint;
    }

    // admin minting
    function adminClaimCarrier(uint256[] calldata quantities, address[] calldata recipients) external onlyOwner {
        require(quantities.length == recipients.length, "Invalid quantities and recipients (length mismatch)");
        uint256 totalQuantity = 0;
        uint256 supply = _totalMinted(); // total minted globally
        for (uint256 i = 0; i < quantities.length; ++i) {
            totalQuantity += quantities[i];
        }
        require(supply + totalQuantity <= maxSupply, "Exceeds max mupply");
        delete totalQuantity;
        for (uint256 i = 0; i < recipients.length; ++i) {
            _mint(recipients[i], quantities[i]);
        }
        delete supply;
    }

    function burn(uint256 tokenId) public virtual override {
        require(!burningDisabled, "Burning is disabled");
        _burn(tokenId, true);
    }

    function batchTransferFrom(address _from, address _to, uint256[] memory _tokenIds) public {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            transferFrom(_from, _to, _tokenIds[i]);
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: Nonexistent token");
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, tokenId.toString())) : "";
    }

    function setMaxMint(uint256 _maxMint) public onlyOwner {
        maxMint = _maxMint;
    }

    function setMaxSupply(uint256 _newMaxSupply) public onlyOwner {
        maxSupply = _newMaxSupply;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setClaimingDisabled(bool _claimingDisabled) public onlyOwner {
        claimingDisabled = _claimingDisabled;
    }

    function setRedeemingDisabled(bool _redeemingDisabled) public onlyOwner {
        redeemingDisabled = _redeemingDisabled;
    }

    function setBurningDisabled(bool _burningDisabled) public onlyOwner {
        burningDisabled = _burningDisabled;
    }

    function totalMinted() public view returns (uint256) {
        return _totalMinted();
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function totalBurned() public view returns (uint256) {
        return _totalBurned();
    }

    function numberBurned(address owner) public view returns (uint256) {
        return _numberBurned(owner);
    }

    function ownershipOf(uint256 tokenId)
        external
        view
        returns (TokenOwnership memory)
    {
        return _ownershipOf(tokenId);
    }

    function getTotalWithdrawn() public view returns (uint256) {
        return totalWithdrawn;
    }

    function getTotalBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getTotalRaised() public view returns (uint256) {
        return getTotalWithdrawn() + getTotalBalance();
    }

    /**
     * withdraw ETH from the contract (callable by Owner only)
     */
    function withdraw() public payable onlyOwner {
        uint256 val = address(this).balance;
        (bool success, ) = payable(msg.sender).call{
            value: val
        }("");
        require(success);
        totalWithdrawn += val;
        delete val;
    }
    /**
     * whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator) override public view returns (bool) {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }
        return super.isApprovedForAll(owner, operator);
    }
}