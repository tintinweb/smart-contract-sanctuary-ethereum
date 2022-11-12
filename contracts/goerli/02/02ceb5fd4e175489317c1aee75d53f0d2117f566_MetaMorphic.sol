// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./ERC721EnumerableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./CountersUpgradeable.sol";
import "./StringsUpgradeable.sol";
import "./MerkleProofUpgradeable.sol";
import "./SafeMathUpgradeable.sol";

contract MetaMorphic is ERC721EnumerableUpgradeable, OwnableUpgradeable {
    using StringsUpgradeable for uint256;
    using SafeMathUpgradeable for uint256;
    using CountersUpgradeable for CountersUpgradeable.Counter;

    CountersUpgradeable.Counter private _tokenIdTracker;

    uint256 public maxSupply;
    string public baseURI;
    address public admin = 0x0e6569843C5E4362AE3f4cD05D5F0ec5C0FEE202;
    address public beneficiary;
    bool public revealed;

    bytes32 public merkleRoot1;
    bytes32 public merkleRoot2;
    uint256 public price1;
    uint256 public price2;
    uint256 public maxAmount1;
    uint256 public maxAmount2;
    uint256 public startTime1;
    uint256 public startTime2;
    uint256 public endTime1;
    uint256 public endTime2;
    uint256 public mintedAmount1;
    uint256 public mintedAmount2;
    mapping(address => uint256) public mintedAmounts1;
    mapping(address => uint256) public mintedAmounts2;

    error NotAdmin();
    error NotStart();
    error StageEnded();
    error MaxSupply();
    error NonExistentTokenURI();
    error MaxUserMint();
    error MaxStageMint();
    error InvalidProof();
    error InsufficientETH();
    error NotTokenOwner();

    event Mint(address account, uint256 id);
    event Mint1(uint256 index, address account, uint256 amount);
    event Mint2(uint256 index, address account, uint256 amount);

    struct Params {
        bytes32 merkleRoot1;
        bytes32 merkleRoot2;
        uint256 price1;
        uint256 price2;
        uint256 maxAmount1;
        uint256 maxAmount2;
        uint256 startTime1;
        uint256 startTime2;
        uint256 endTime1;
        uint256 endTime2;
    }

    modifier onlyAdmin() {
        if (msg.sender != admin) {
            revert NotAdmin();
        }
        _;
    }

    modifier onlyStage1() {
        if (startTime1 == 0 || block.timestamp < startTime1) {
            revert NotStart();
        }
        if (endTime1 != 0 && block.timestamp > endTime1) {
            revert StageEnded();
        }
        _;
    }

    modifier onlyStage2() {
        if (startTime2 == 0 || block.timestamp < startTime2) {
            revert NotStart();
        }
        if (endTime2 != 0 && block.timestamp > endTime2) {
            revert StageEnded();
        }
        _;
    }

    function initialize(string memory name, string memory symbol, uint256 _maxSupply, string memory _baseURI, address _admin, address _beneficiary) public initializer {
        __Ownable_init_unchained();
        __ERC721_init_unchained(name, symbol);
        maxSupply = _maxSupply;
        baseURI = _baseURI;
        admin = _admin;
        beneficiary = _beneficiary;
    }

    function totalSupply() public view override returns (uint) {
        return _tokenIdTracker.current();
    }

    /**
     * @notice get all token IDs of a address
     *
     * @param owner owner address
     */
    function walletOfOwner(address owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(owner, i);
        }

        return tokensId;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (ownerOf(tokenId) == address(0)) {
            revert NonExistentTokenURI();
        }
        if (!revealed) {
            return baseURI;
        }
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    function params() public view returns (Params memory) {
        return Params({
            merkleRoot1: merkleRoot1,
            merkleRoot2: merkleRoot2,
            price1: price1,
            price2: price2,
            maxAmount1: maxAmount1,
            maxAmount2: maxAmount2,
            startTime1: startTime1,
            startTime2: startTime2,
            endTime1: endTime1,
            endTime2: endTime2
        });
    }

    /**
     * @notice mint amount of NFTs for stage one
     */
    function mint1(uint256 index, address account, uint256 maxAmount, bytes32[] calldata merkleProof, uint256 amount) external payable onlyStage1 {
        if (mintedAmount1 + amount > maxAmount1) {
            revert MaxStageMint();
        }
        uint256 mintedAmount = mintedAmounts1[account];
        if (mintedAmount + amount > maxAmount) {
            revert MaxUserMint();
        }
        if (msg.value != amount.mul(price1)) {
            revert InsufficientETH();
        }
        // add minted amount
        mintedAmount1 = mintedAmount1.add(amount);
        mintedAmounts1[account] = mintedAmount.add(amount);
        if (msg.value > 0) {
            _transfer(beneficiary, msg.value);
        }
        _verify(index, account, maxAmount, merkleProof, merkleRoot1);
        // mint NFT
        for (uint256 i = 0; i < amount; i++) {
            _mintTo(account);
        }
        emit Mint1(index, account, amount);
    }

    /**
     * @notice mint amount of NFTs for stage two
     */
    function mint2(uint256 index, address account, uint256 maxAmount, bytes32[] calldata merkleProof, uint256 amount) external payable onlyStage2 {
        if (mintedAmount2 + amount > maxAmount2) {
            revert MaxStageMint();
        }
        uint256 mintedAmount = mintedAmounts2[account];
        if (mintedAmount + amount > maxAmount) {
            revert MaxUserMint();
        }
        if (msg.value != amount.mul(price2)) {
            revert InsufficientETH();
        }
        // add minted amount
        mintedAmount2 = mintedAmount2.add(amount);
        mintedAmounts2[account] = mintedAmount.add(amount);
        if (msg.value > 0) {
            _transfer(beneficiary, msg.value);
        }
        _verify(index, account, maxAmount, merkleProof, merkleRoot2);
        // mint NFT
        for (uint256 i = 0; i < amount; i++) {
            _mintTo(account);
        }
        emit Mint2(index, account, amount);
    }

    /**
     * @notice transfer to zero address
     */
    function burn(uint256 tokenId) public {
        if (ownerOf(tokenId) != msg.sender) {
            revert NotTokenOwner();
        }
        _burn(tokenId);
    }

    // ******************* Owner FUNCTIONS *******************

    function setAdmin(address _admin) public {
        admin = _admin;
    }

    // ******************* Admin FUNCTIONS *******************

    function setBaseURI(string memory _baseURI) public onlyAdmin {
        baseURI = _baseURI;
    }

    function setBeneficiary(address _beneficiary) public onlyAdmin {
        beneficiary = _beneficiary;
    }

    function reveal(string memory _baseURI) public onlyAdmin {
        revealed = true;
        baseURI = _baseURI;
    }

    /**
     * @notice set parameters for stage one
     */
    function setParams1(bytes32 _merkleRoot, uint256 _price, uint256 _maxAmount, uint256 _startTime, uint256 _endTime) public onlyAdmin {
        merkleRoot1 = _merkleRoot;
        price1 = _price;
        maxAmount1 = _maxAmount;
        startTime1 = _startTime;
        endTime1 = _endTime;
    }

    /**
     * @notice set parameters for stage two
     */
    function setParams2(bytes32 _merkleRoot, uint256 _price, uint256 _maxAmount, uint256 _startTime, uint256 _endTime) public onlyAdmin {
        merkleRoot2 = _merkleRoot;
        price2 = _price;
        maxAmount2 = _maxAmount;
        startTime2 = _startTime;
        endTime2 = _endTime;
    }

    // ******************* INTERNAL FUNCTIONS *******************

    function _verify(uint256 index, address account, uint256 maxAmount, bytes32[] calldata merkleProof, bytes32 merkleRoot) private pure {
        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(index, account, maxAmount));
        if (!MerkleProofUpgradeable.verify(merkleProof, merkleRoot, node)) {
            revert InvalidProof();
        }
    }

    function _mintTo(address recipient) private {
        _tokenIdTracker.increment();
        uint id = _tokenIdTracker.current();
        if (id > maxSupply) {
            revert MaxSupply();
        }
        _mint(recipient, id);
        emit Mint(recipient, id);
    }

    function _transfer(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }
}