// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@      @@@@@@@@@@@@   @@@@@@@@*   @@@@@@@@                   @@@                      @@@@    &@@@@@@@@@@@@    @@@@@
// @@@@@       @@@@@@@@@@@   @@@@@@@@*   @@@@@@@@    @@@@@@@@@@@@@@@@@@@@@@@@@@@    @@@@@@@@@@@@@@@    @@@@@@@@@@    @@@@@@
// @@@@@   #@    @@@@@@@@@   @@@@@@@@*   @@@@@@@@    @@@@@@@@@@@@@@@@@@@@@@@@@@@    @@@@@@@@@@@@@@@@.   @@@@@@@    @@@@@@@@
// @@@@@   #@@    @@@@@@@@   @@@@@@@@*   @@@@@@@@    @@@@@@@@@@@@@@@@@@@@@@@@@@@    @@@@@@@@@@@@@@@@@@    @@@@    @@@@@@@@@
// @@@@@   #@@@@    @@@@@@   @@@@@@@@*   @@@@@@@@                 @@@@@@@@@@@@@@    @@@@@@@@@@@@@@@@@@@@   &    @@@@@@@@@@@
// @@@@@   #@@@@@    @@@@@   @@@@@@@@*   @@@@@@@@    @@@@@@@@@@@@@@@@@@@@@@@@@@@    @@@@@@@@@@@@@@@@@@@@@     *@@@@@@@@@@@@
// @@@@@   #@@@@@@@    @@@   @@@@@@@@*   @@@@@@@@    @@@@@@@@@@@@@@@@@@@@@@@@@@@    @@@@@@@@@@@@@@@@@@@@@@    @@@@@@@@@@@@@
// @@@@@   #@@@@@@@@@   &@   @@@@@@@@*   @@@@@@@@    @@@@@@@@@@@@@@@@@@@@@@@@@@@    @@@@@@@@@@@@@@@@@@@@@@    @@@@@@@@@@@@@
// @@@@@   #@@@@@@@@@@       @@@@@@@@*   @@@@@@@@    @@@@@@@@@@@@@@@@@@@@@@@@@@@    @@@@@@@@@@@@@@@@@@@@@@    @@@@@@@@@@@@@
// @@@@@   #@@@@@@@@@@@@     @@@@@@@@*   @@@@@@@@    @@@@@@@@@@@@@@@@@@@@@@@@@@@    @@@@@@@@@@@@@@@@@@@@@@    @@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@                                                                                                                   @@
// @@@  @@@@@@@@         [email protected]@@@@@@@    @@@@@@          @@@@@       @@@@@@@@@@@@@@       @@@@@*        &@@@@@@@@@@@@       @@
// @@@  @@@@@@@@@        @@@@@@@@@    @@@@@@          @@@@@     @@@@@@@@@@@@@@@@@@     @@@@@*     /@@@@@@@@@@@@@@@@@@    @@
// @@@  @@@@@*@@@,      @@@@ @@@@@    @@@@@@          @@@@@    @@@@@          @@@@@    @@@@@*    @@@@@@,        @@@@@@   @@
// @@@  @@@@@ @@@@      @@@@ @@@@@    @@@@@@          @@@@@    @@@@@                   @@@@@*   @@@@@@           @@@@@@  @@
// @@@  @@@@@  @@@@    @@@@  @@@@@    @@@@@@          @@@@@    %@@@@@@@@@@@            @@@@@*   @@@@@                    @@
// @@@  @@@@@  @@@@    @@@@  @@@@@    @@@@@@          @@@@@       @@@@@@@@@@@@@@@@     @@@@@*  &@@@@@                    @@
// @@@  @@@@@   @@@@  @@@@   @@@@@    @@@@@@          @@@@@               @@@@@@@@@@   @@@@@*   @@@@@                    @@
// @@@  @@@@@   @@@@ ,@@@    @@@@@    @@@@@@          @@@@@   @@@@@@           @@@@@   @@@@@*   @@@@@@           @@@@@@  @@
// @@@  @@@@@    @@@@@@@@    @@@@@    @@@@@@@        @@@@@@    @@@@@#         ,@@@@@   @@@@@*    @@@@@@@        @@@@@@   @@
// @@@  @@@@@    &@@@@@@     @@@@@     /@@@@@@@@@@@@@@@@@@      @@@@@@@@@@@@@@@@@@@    @@@@@*      @@@@@@@@@@@@@@@@@     @@
// @@@  @@@@@     @@@@@@     @@@@@        @@@@@@@@@@@@@            @@@@@@@@@@@@@       @@@@@*         @@@@@@@@@@@*       @@
// @@@                                                                                                                   @@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./ERC721ABurnable.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./PaymentSplitter.sol";
import "./Strings.sol";
import "./ERC2981.sol";
import "./ReentrancyGuard.sol";

contract LoveLetters is ERC721A, ERC721ABurnable, Ownable, PaymentSplitter, ERC2981, ReentrancyGuard {

    using Strings for uint256;

    // The total tokens minted to an address. Does not matter if tokens are transferred out
    mapping(address => uint256) public addressPublicMintCount;
    mapping(address => uint256) public addressWLMintCount;
    mapping(address => bool) public freeMintClaimed;
    mapping(address => uint256) public referralCount;

    string public baseTokenURI; // Can be combined with the tokenId to create the metadata URI
    uint256 public mintPhase = 0; // 0 = closed, 1 = WL sale, 2 = public sale
    bool public allowBurn = false; // Admin toggle for allowing the burning of tokens
    uint256 public constant MINT_PRICE = 0.08 ether; // Public mint price
    uint256 public constant REFERRAL_MINT_PRICE = 0.068 ether; // Public mint price
    uint256 public constant ALLOWLIST_MINT_PRICE = 0.052 ether; // Mint price for allowlisted addresses only
    uint256 public constant MAX_TOTAL_SUPPLY = 888; // The maximum total supply of tokens
    uint256 public constant MAX_MINT_COUNT = 10; // The maximum number of tokens any one address can mint
    uint256 public constant REFERRER_FEE = 15000000000000000; // The amount sent to the referrer on each mint
    uint256 public maxWLMintCount = 20; // The maximum number of tokens a whitelisted address can mint
    bytes32 public merkleroot; // The merkle tree root. Used for verifying allowlist addresses

    uint256 private constant MAX_TOKEN_ITERATIONS = 40; // Used to prevent out-of-gas errors when looping

    event SetBaseURI(address _from);
    event MintPhaseChanged(address _from, uint newPhase);
    event ToggleAllowBurn(bool isAllowed);
    event ReferralMint(address _referrer, string _eid, uint count);

    constructor(string memory _baseUri, bytes32 _merkleroot, address[] memory _payees, uint256[] memory _shares) ERC721A("Love Letters", "LOVE") PaymentSplitter(_payees, _shares) {
        baseTokenURI = _baseUri;
        merkleroot = _merkleroot;
        _setDefaultRoyalty(address(this), 1000);
    }

    // Allows the contract owner to update the merkle root (allowlist)
    function setMerkleRoot(bytes32 _merkleroot) external onlyOwner {
        merkleroot = _merkleroot;
    }

    // Allows the contract owner to set a new base URI string
    function setBaseURI(string calldata _baseURI) external onlyOwner {
        baseTokenURI = _baseURI;
        emit SetBaseURI(msg.sender);
    }

    // Allows the contract owner to set the wl cap
    function setWLCap(uint _newCap) external onlyOwner {
        maxWLMintCount = _newCap;
    }

    // Overrides the tokenURI function so that the base URI can be returned
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        string memory baseURI = baseTokenURI;
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, _tokenId.toString())) : "";
    } 

    function _mintTo(address _recipient, uint256 _amount) internal {
        uint256 supply = totalSupply();
        uint256 mintCount = addressPublicMintCount[_recipient];
        require(mintPhase==2, "Public sale is not yet active");
        require(_amount > 0, "Mint amount can't be zero");
        require(mintCount + _amount <= MAX_MINT_COUNT, "Exceeded max mint count");
        require(supply + _amount <= MAX_TOTAL_SUPPLY, "Max mint supply has been reached");

        addressPublicMintCount[_recipient] = mintCount + _amount;
			
        _safeMint(_recipient, _amount);
    }

    function mintNoReferrer(address _recipient, uint256 _amount) external payable {
        require(_amount * MINT_PRICE == msg.value, "Check mint price");
        _mintTo(_recipient, _amount);
    }

    function mintReferrer(address _recipient, uint256 _amount, address payable _referrer, string memory _eid) external payable nonReentrant {
        require(_referrer != _recipient, "Referrer cannot be the same as sender");
        require(_amount * REFERRAL_MINT_PRICE == msg.value, "Check mint price");

        referralCount[_referrer] += _amount;
        emit ReferralMint(_referrer, _eid, _amount);

        _mintTo(_recipient, _amount);
        _payReferrer(_referrer, _amount);
    }

    // Only accessible by the contract owner. This function is used to mint tokens for the team.
    function ownerMint(uint256 _amount, address _recipient) external onlyOwner {
        uint256 supply = totalSupply();
        require(_amount > 0, "Mint amount can't be zero");
        require(_amount <= MAX_TOKEN_ITERATIONS, "You cannot mint this many in one transaction"); // Used to avoid OOG errors.
        require(supply + _amount <= MAX_TOTAL_SUPPLY, "Max supply is reached");
        
        _safeMint(_recipient, _amount);
    }

    // Minting function for addresses on the allowlist only
    function mintAllowList(address _recipient, uint256 _amount, bytes32[] calldata _proof) public payable {
        uint256 supply = totalSupply();
        uint256 mintCount = addressWLMintCount[_recipient];
        require(_verify(_leaf(_recipient, false), _proof, merkleroot), "Wallet not on allowlist");
        require(mintCount + _amount <= maxWLMintCount, "Exceeded whitelist allowance.");
        require(mintPhase==1, "Allowlist sale is not active");
        require(_amount > 0, "Mint amount can't be zero");
        require(_amount <= MAX_TOKEN_ITERATIONS, "You cannot mint this many in one transaction."); // Used to avoid OOG errors
        require(supply + _amount <= MAX_TOTAL_SUPPLY, "Max supply is reached");
        require(_amount * ALLOWLIST_MINT_PRICE == msg.value, "Incorrect price");

        addressWLMintCount[_recipient] = mintCount + _amount;
        
        _safeMint(_recipient, _amount);
    }

    function mintAllowListReferrer(address _recipient, uint256 _amount, address payable _referrer, string memory _eid, bytes32[] calldata _proof) external payable nonReentrant {
        require(_referrer != _recipient, "Referrer cannot be the same as sender");

        referralCount[_referrer] += _amount;
        emit ReferralMint(_referrer, _eid, _amount);

        mintAllowList(_recipient, _amount, _proof);
        _payReferrer(_referrer, _amount);
    }

    // Minting function addresses on the OG list only
    function mintFreeMintList(bytes32[] calldata _proof) external {
        uint256 supply = totalSupply();
        require(!freeMintClaimed[msg.sender], "Free mint already claimed");
        require(_verify(_leaf(msg.sender, true), _proof, merkleroot), "Wallet not on free mint list");
        require(mintPhase==1, "Sale is not active");
        require(supply + 1 <= MAX_TOTAL_SUPPLY, "Max supply is reached");

        freeMintClaimed[msg.sender] = true;

        _safeMint(msg.sender, 1);
    }

    // An owner-only function which toggles the public sale on/off
    function changeMintPhase(uint256 _newPhase) external onlyOwner {
        mintPhase = _newPhase;
        emit MintPhaseChanged(msg.sender, _newPhase);
    }

    // An owner-only function which toggles the allowBurn variable
    function toggleAllowBurn() external onlyOwner {
        allowBurn = !allowBurn;
        emit ToggleAllowBurn(allowBurn);
    }

    function _payReferrer(address payable _referrer, uint256 _amount) internal {
        payable(_referrer).transfer(REFERRER_FEE * _amount);
    }

    // Used to construct a merkle tree leaf
    function _leaf(address _account, bool _isFreeMintList)
    internal pure returns (bytes32)
    {
        return keccak256(abi.encodePacked(_account, _isFreeMintList));
    }

    // Verifies a leaf is part of the tree
    function _verify(bytes32 leaf, bytes32[] memory _proof, bytes32 _root) pure
    internal returns (bool)
    {
        return MerkleProof.verify(_proof, _root, leaf);
    }

    // Overrides the ERC721A burn function
    function burn(uint256 _tokenId) public virtual override {
        require(allowBurn, "Burning is not currently allowed");
        _burn(_tokenId, true);
    }

    /**
    @notice Sets the contract-wide royalty info.
     */
    function setRoyaltyInfo(address receiver, uint96 feeBasisPoints)
        external
        onlyOwner
    {
        _setDefaultRoyalty(receiver, feeBasisPoints);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721A, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}