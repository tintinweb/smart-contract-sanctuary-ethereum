// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./ECDSA.sol";
import "./MerkleProof.sol";
import "./ERC2981.sol";


contract wowgClone is ERC721, ERC721Enumerable, ERC2981, ReentrancyGuard, Ownable {
    using ECDSA for bytes32;
    using Strings for uint256;

    uint256 constant TOTAL_FREE_CLAIM_IDS = 55;
    uint256 constant FIRST_PUBLIC_ID      = 1;
    uint256 constant LAST_PUBLIC_ID       = 55;
    uint256 constant FIRST_ALLOWLIST_ID   = 56;
    uint256 constant LAST_ALLOWLIST_ID    = 60;

    uint256 constant MAX_MINTS_PER_TRANSACTION = 10;
    address constant WITHDRAW_ADDRESS = 0x22D193Ed15Ddf5717eB6C9d89CEF8bB6Eb171DeE;
    address public royaltyAddress = 0x22D193Ed15Ddf5717eB6C9d89CEF8bB6Eb171DeE;
    uint96 public royaltyFee = 750;

    // Public vars
    string public baseTokenURI;
    uint256 public allowListPrice;
    uint256 public dutchAuctionDuration;
    uint256[] public dutchAuctionSteps;
    uint256 private minutesPerStep;

    uint256 public freeClaimSaleStartTime;
    uint256 public publicSaleStartTime;
    uint256 public allowListSaleStartTime;
    bytes32 public merkleRoot;

    uint256 public startingIndexFreeClaim;
    uint256 public startingIndexFreeClaimTimestamp;

    uint256 public startingIndexPublicAndAllowList;
    uint256 public startingIndexPublicAndAllowListTimestamp;

    mapping(address => bool) public allowListMinted;

    uint256 public freeClaimTokensMinted;
    uint256 public allowListTokenIdCounter = FIRST_ALLOWLIST_ID;
    uint256 public publicSaleTokenIdCounter = FIRST_PUBLIC_ID;

    bool public isFreeClaimActive = false;
    bool public isPublicSaleActive = false;
    bool public isAllowListActive = false;

    // support eth transactions to the contract
    event Received(address, uint);
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    /**
     * @notice Construct a WoWG contract instance
     * @param _name Token name
     * @param _symbol Token symbol
     * @param _baseTokenURI Base URI for all tokens
     */
    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseTokenURI
    ) ERC721(_name, _symbol) {
        baseTokenURI = _baseTokenURI;
        _setDefaultRoyalty(royaltyAddress, royaltyFee);
    }

    modifier originalUser() {
        require(msg.sender == tx.origin,"MUST_INVOKE_FUNCTION_DIRECTLY");
        _;
    }

    /**
     * @notice Update the base token URI
     */
    function setBaseURI(string calldata _newBaseURI) external onlyOwner {
        baseTokenURI = _newBaseURI;
    }

    /**
     * @notice read the base token URI
     */
    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    /**
     * @notice Change the royalty fee for the collection
     */
    function setRoyaltyFee(uint96 _feeNumerator) external onlyOwner {
        royaltyFee = _feeNumerator;
        _setDefaultRoyalty(royaltyAddress, royaltyFee);
    }

    /**
     * @notice Change the royalty address where royalty payouts are sent
     */
    function setRoyaltyAddress(address _royaltyAddress) external onlyOwner {
        royaltyAddress = _royaltyAddress;
        _setDefaultRoyalty(royaltyAddress, royaltyFee);
    }

    /**
     * @notice Manually allow the owner to set the starting index for the free claim mint
     */
    function setStartingIndexFreeClaim() external onlyOwner {
        _setStartingIndexFreeClaim();
    }

    /**
     * @notice Set the starting index for the free claim mint
     */
    function _setStartingIndexFreeClaim() internal {
        require(startingIndexFreeClaim == 0, "STARTING_INDEX_FREE_CLAIM_ALREADY_SET");

        startingIndexFreeClaim = generateRandomStartingIndex(TOTAL_FREE_CLAIM_IDS);
        startingIndexFreeClaimTimestamp = block.timestamp;
    }

    /**
     * @notice Manually allow the owner to set the starting index for the public and allow list mints
     */
    function setStartingIndexPublicAndAllowList() external onlyOwner {
        _setStartingIndexPublicAndAllowList();
    }

    /**
     * @notice Set the starting index for the public and allow list mints
     */
    function _setStartingIndexPublicAndAllowList() internal {
        require(startingIndexPublicAndAllowList == 0, "STARTING_INDEX_PUBLIC_AND_ALLOWLIST_ALREADY_SET");

        startingIndexPublicAndAllowList = generateRandomStartingIndex(
            LAST_ALLOWLIST_ID - FIRST_ALLOWLIST_ID + 1 +
            LAST_PUBLIC_ID - FIRST_PUBLIC_ID + 1);
        startingIndexPublicAndAllowListTimestamp = block.timestamp;
    }

    /**
     * @notice Creates a random starting index to offset pregenerated tokens by for fairness
     */
    function generateRandomStartingIndex(uint256  _range) public view returns (uint256) {
        uint256 startingIndex;
        // Blockhash only works for the most 256 recent blocks.
        uint256 _block_shift = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp)));
        _block_shift =  1 + (_block_shift % 255);

        // This shouldn't happen, but just in case the blockchain gets a reboot?
        if (block.number < _block_shift) {
            _block_shift = 1;
        }

        uint256 _block_ref = block.number - _block_shift;
        startingIndex = uint(blockhash(_block_ref)) % _range;

        // Prevent default sequence
        if (startingIndex == 0) {
            startingIndex++;
        }

        return startingIndex;
    }

    /**
     * @notice Set the steps and duration in minutes for the public Dutch auction mint
     */
    function setDutchAuctionParams(uint256[] calldata _steps, uint256 _duration)
        public
        onlyOwner
    {
        require(_steps.length > 0 && _duration > 0,'ZERO_STEPS_OR_ZERO_DURATION');
        dutchAuctionSteps = _steps;
        dutchAuctionDuration = _duration;
        minutesPerStep = dutchAuctionDuration / dutchAuctionSteps.length;
    }

    /**
     * @notice Retrieve the current Dutch auction price per token
     */
    function getCurrentDutchAuctionPrice() public view returns (uint256) {
        uint256 minutesPassed =
            uint256(block.timestamp - publicSaleStartTime) / 60;

        if (minutesPassed >= dutchAuctionDuration) {
            return dutchAuctionSteps[dutchAuctionSteps.length - 1];
        }

        return dutchAuctionSteps[minutesPassed / minutesPerStep];
    }

    /**
     * @notice Set the price per token for the allow list mint
     */
    function setAllowListPrice(uint256 _newAllowListPrice) public onlyOwner {
        require(_newAllowListPrice > 0 ether, "CANT_SET_ALLOW_LIST_PRICE_BACK_TO_ZERO");
        allowListPrice = _newAllowListPrice;
    }

    /**
     * @notice Set the merkle root for the allow list mint
     */
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    /**
     * @notice Verify address eligibility for the allow list mint
     */
    function isAllowListEligible(address addr, bytes32[] calldata _merkleProof) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(addr));
        return MerkleProof.verify(_merkleProof, merkleRoot, leaf);
    }

    // Sales

    /**
     * @notice Set the active/inactive state of the allow list mint
     */
    function flipAllowListState() public onlyOwner {
        require(isAllowListActive || allowListPrice > 0, "ALLOW_LIST_PRICE_NOT_SET");
        isAllowListActive = !isAllowListActive;
        if (allowListSaleStartTime == 0) {
            allowListSaleStartTime = block.timestamp;
        }
    }

    /**
     * @notice Allow an address on the allow list to mint a single token
     */
    function allowListMint(bytes32[] calldata _merkleProof)
        external
        payable
        nonReentrant
        originalUser
    {
        require(isAllowListActive, "ALLOW_LIST_SALE_IS_NOT_ACTIVE");
        require(allowListTokenIdCounter <= LAST_ALLOWLIST_ID, "INSUFFICIENT_SUPPLY");
        require(
            !allowListMinted[msg.sender],
            "ADDRESS_ALREADY_MINTED_IN_ALLOW_LIST"
        );
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, leaf),
            "ADDRESS_NOT_ELIGIBLE_FOR_ALLOW_LIST"
        );
        require(msg.value == allowListPrice, "INVALID_PRICE");

        allowListMinted[msg.sender] = true;
        _safeMint(msg.sender, allowListTokenIdCounter);
        allowListTokenIdCounter++;
    }

    /**
     * @notice Allow the owner to start/stop the public sale
     */
    function flipPublicSaleState() public onlyOwner {
        isPublicSaleActive = !isPublicSaleActive;
        if (publicSaleStartTime == 0) {
            publicSaleStartTime = block.timestamp;
        } else {
            publicSaleStartTime = 0;
        }
    }

    /**
     * @notice Allow anyone to mint tokens publicly
     */
    function publicSaleMint(uint256 _numberToMint)
        external
        payable
        nonReentrant
        originalUser
    {
        require(isPublicSaleActive, "PUBLIC_SALE_IS_NOT_ACTIVE");
        uint256 costToMint = getCurrentDutchAuctionPrice() * _numberToMint;
        require(
            _numberToMint <= MAX_MINTS_PER_TRANSACTION,
            "EXCEEDS_MAX_MINTS_PER_TRANSACTION"
        );
        require(
            msg.value >= costToMint,
            "INSUFFICIENT_PAYMENT"
        );
        require(
            publicSaleTokenIdCounter + _numberToMint <= LAST_PUBLIC_ID + 1,
            "INSUFFICIENT_SUPPLY"
        );

        for (uint256 i; i < _numberToMint; i++) {
            _safeMint(msg.sender, publicSaleTokenIdCounter + i);
        }
        publicSaleTokenIdCounter += _numberToMint;

        // last mint will increase the counter past LAST_PUBLIC_ID
        if (publicSaleTokenIdCounter > LAST_PUBLIC_ID) {
            isPublicSaleActive = false;
            if (startingIndexPublicAndAllowList == 0) {
                _setStartingIndexPublicAndAllowList();
            }
        }

        if (msg.value > costToMint) {
            Address.sendValue(payable(msg.sender), msg.value - costToMint);
        }
    }

    /**
     * @notice Allow to owner to start/stop the free claim mint
     */
    function flipFreeClaimState() public onlyOwner {
        isFreeClaimActive = !isFreeClaimActive;
        if (freeClaimSaleStartTime == 0) {
            freeClaimSaleStartTime = block.timestamp;
        }
    }


    /**
     * @notice Easily get the number of steps for the public sale
     */
    function getDutchAuctionStepsCount() public view returns (uint256 count) {
        return dutchAuctionSteps.length;
    }

    // Owner

    /**
     * @notice Allow the owner to gift tokens to an arbitrary number of addresses
     */
    function giftMint(address[] calldata _receivers) external onlyOwner {
        require(
            allowListTokenIdCounter + _receivers.length <= LAST_ALLOWLIST_ID + 1,
            "NOT_ENOUGH_ALLOW_LIST_TOKENS_REMAINING"
        );

        for (uint256 i; i < _receivers.length; i++) {
            _safeMint(_receivers[i], allowListTokenIdCounter + i);
        }
        allowListTokenIdCounter += _receivers.length;
    }

    /**
     * @notice Allow withdrawing funds to the withdrawAddress
     */
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0,'NOTHING_TO_WITHDRAW');
        require(payable(WITHDRAW_ADDRESS).send(balance));
    }

    // Utils

    /**
     * @notice Returns a list of token IDs owned by a given address
     */
    function walletOfOwner(address _owner) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        uint256[] memory tokensId = new uint256[](tokenCount);

        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokensId;
    }

    /**
     * @notice Allow external checks for token existence
     */
    function tokenExists(uint256 _tokenId) public view returns(bool) {
        return _exists(_tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}