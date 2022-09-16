// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.8.6;

/**
* @title NFTs for the AccessPass to Metaframes Maradona Club
* @author MetaFrames
* @notice This NFT Contract follows the ERC721 Standards and sets one of its properties (tier), on chain.
* The three tiers are as follows: GOLD, SILVER, BRONZE. This contract is also connected to Metaframes' TicketNFT
* which are used to join Metaframes' Ticket Competition for the World Cup Ticket.
* @dev The flow of this contract is as follows:
*    Deployment: Contract is deployed and configured
*    -----------------------------------------------
*    Additional Configuration
*     -setWhitelistSigner()
*     -setPrivateMintingTimestamp() if privateMintingTimestamp is 0
*    -----------------------------------------------
*    Private Minting: Allows accounts in the mint whitelist to mint
*    -----------------------------------------------
*    Public Minting: Allows all accounts to mint
*     -setPublicMintingTimestamp() if publicMintingTimestamp is 0
*    -----------------------------------------------
*    Reveal: Revealing the tiers
*     -randomizeTiers()
*     -nftTiers() then builds the final token metadata
*    -----------------------------------------------
*    Airdrop: Minting TicketNFTs to 500 Random Users
*     -randomizeTickets()
*     -winners() then builds the 500 random users
*     NOTE: the actual minting will happen in the TicketNFT contract
*/

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./WhitelistVerifier.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "./TicketNFT.sol";
import "./interfaces/IAccessPassNFT.sol";
import "./interfaces/ITicketNFT.sol";

contract AccessPassNFT is Ownable, WhitelistVerifier, ERC721Royalty, VRFConsumerBaseV2, IAccessPassNFT {
    using Counters for Counters.Counter;
    using Strings for uint256;

    /**
    * @dev maxTotalSupply is the amount of NFTs that can be minted
    */
    uint16 public immutable maxTotalSupply;

    /**
    * @dev goldenTierSupply is the amount of GOLD NFTs
    */
    uint16 public immutable goldenTierSupply;

    /**
    * @dev silverTierSupply is the amount of SILVER NFTs
    */
    uint16 public immutable silverTierSupply;

    /**
    * @dev ticketSupply is the amount of TicketNFTs to be airdropped
    */
    uint16 public immutable ticketSupply;

    /**
    * @dev Mapping minter address to amount minted
    */
    struct Minted {
        uint256 publicMinted;
        uint256 privateMinted;
    }
    mapping(address => Minted) private minted;

    /**
    * @dev Keeps track of how many NFTs have been minted
    */
    Counters.Counter public tokenIdCounter;

    /**
    * @dev privateMintingTimestamp sets when privateMinting is enabled. When this is 0,
    * it means all minting is disabled
    */
    uint256 public privateMintingTimestamp;

    /**
    * @dev publicMintingTimestamp sets when publicMinting is enabled. When this is 0, it means
    * public minting is disabled. This value must be greater than the privateMintingTimestamp if this is not 0
    */
    uint256 public publicMintingTimestamp;

    /**
    * @dev price specifies how much eth an account pays for a mint. This is in wei
    */
    uint256 public price;

    /**
    * @dev maxPublicMintable is the maximum an account can publicMint
    */
    uint16 public maxPublicMintable;

    /**
    * @dev flag that tells if the final uri has been set
    */
    bool public tiersRevealed;

    /**
    * @dev unrevealedURI is the placeholder token metadata when the reveal has not happened yet
    */
    string unrevealedURI;

    /**
    * @dev baseURI is the base of the real token metadata after the reveal
    */
    string baseURI;

    /**
    * @dev contractURI is an OpenSea standard. This should point to a metadata that tells who will
    * receive revenues from OpensSea. See https://docs.opensea.io/docs/contract-level-metadata
    */
    string public contractURI;

    /**
    * @dev receives the eth from accounts private and public minting and the royalties from selling the token.
    * All revenues should be sent to this address
    */
    address payable public treasury;

    /**
    * @dev ticketNFT decides the trade freeze when the winners have been selected
    */
    TicketNFT public ticketNFT;

    /**
    * @dev The following variables are needed to request a random value from Chainlink
    * see https://docs.chain.link/docs/vrf-contracts/
    */
    address public chainlinkCoordinator;  // Chainlink coordinator address
    uint256 public tiersRequestId;        // Chainlink request id for tier randomization
    uint256 public tiersRandomWord;       // Random value received from Chainlink VRF
    uint256 public ticketsRequestId;      // Chainlink request id for ticket randomization
    uint256 public ticketsRandomWord;     // Random value received from Chainlink VRF

    /**
    * @notice initializes the contract
    * @param treasury_ is the recipient of eth from private and public minting as well as the recipient for token selling fees
    * @param vrfCoordinator_ is the address of the VRF Contract for generating random number
    * @param maxTotalSupply_ is the max number of tokens that can be minted
    * @param goldenTierSupply_ is the max number of golden tiered tokens
    * @param silverTierSupply_ is the max number of silver tiered tokens
    * @param ticketSupply_ is the max number of tickets that will be airdropped
    * @param privateMintingTimestamp_ is when the private minting will be enabled. NOTE: this could also be set later. 0 is an acceptable value
    * @param royaltyFee is the fees taken from second-hand selling. This is expressed in _royaltyFee/10_000.
    * So to do 5% means supplying 500 since 500/10_000 is 5% (see ERC2981 function _setDefaultRoyalty(address receiver, uint96 feeNumerator))
    * @param price_ is the price of a public or private mint in wei
    * @param contractURI_ is an OpenSeas standard and is necessary for getting revenues from OpenSeas
    * @param unrevealedURI_ is the token metadata placeholder while the reveal has not happened yet.
    */
    constructor(
        address payable treasury_,
        address vrfCoordinator_,

        uint16 maxTotalSupply_,
        uint16 goldenTierSupply_,
        uint16 silverTierSupply_,
        uint16 ticketSupply_,

        uint256 privateMintingTimestamp_,

        uint96 royaltyFee,
        uint256 price_,

        string memory contractURI_,
        string memory unrevealedURI_
    )   ERC721("Maradona Official Access Pass", "OMFC")
        WhitelistVerifier()
        VRFConsumerBaseV2(vrfCoordinator_) {

        if (treasury_ == address(0)) revert ZeroAddress("treasury");
        treasury = treasury_;

        if (vrfCoordinator_ == address(0)) revert ZeroAddress("vrfCoordinator");
        chainlinkCoordinator = vrfCoordinator_;

        if (maxTotalSupply_ == 0) revert IsZero("maxTotalSupply");
        maxTotalSupply = maxTotalSupply_;

        // The following is to ensure that there will be bronzeTierSupply
        require(
            goldenTierSupply_ + silverTierSupply_ < maxTotalSupply_,
                "Tier Supplies must be less than maxTotalSupply"
        );
        if (goldenTierSupply_ == 0) revert IsZero("goldenTierSupply");
        goldenTierSupply = goldenTierSupply_;

        if (silverTierSupply_ == 0) revert IsZero("silverTierSupply");
        silverTierSupply = silverTierSupply_;

        if (ticketSupply_ > maxTotalSupply_) revert IncorrectValue("ticketSupply");
        ticketSupply = ticketSupply_;

        // not checking for zero on purpose here
        privateMintingTimestamp = privateMintingTimestamp_;

        if (royaltyFee == 0) revert IsZero("royaltyFee");
        _setDefaultRoyalty(treasury_, royaltyFee);

        if (price_ == 0) revert IsZero("price");
        price = price_;

        bytes memory bytesUnrevealedURI = bytes(unrevealedURI_);
        if (bytesUnrevealedURI[bytesUnrevealedURI.length - 1] != bytes("/")[0]) revert IncorrectValue("unrevealedURI");
        unrevealedURI = unrevealedURI_;

        if (bytes(contractURI_).length == 0) revert EmptyString("contractURI");
        contractURI = contractURI_;

        maxPublicMintable = 10;

        // mint one to deployer so the OpenSeas store front can be edited before private minting starts
        uint256 tokenId = tokenIdCounter.current();
        _safeMint(msg.sender, tokenId);
        tokenIdCounter.increment();

        // classifying this mint as a private mint
        minted[msg.sender].privateMinted += 1;
    }

    /********************** EXTERNAL ********************************/

    /**
    * @inheritdoc IAccessPassNFT
    */
    function privateMint(
        VerifiedSlot calldata verifiedSlot
    ) external
        override
        payable
        onlyDuring(ContractStatus.PRIVATE_MINTING)
    {
        validateVerifiedSlot(msg.sender, minted[msg.sender].privateMinted, verifiedSlot);
        internalMint(msg.sender, msg.value, MintingType.PRIVATE_MINT);
    }

    /**
    * @inheritdoc IAccessPassNFT
    */
    function publicMint() external override payable onlyDuring(ContractStatus.PUBLIC_MINTING) {
        if (minted[msg.sender].publicMinted >= maxPublicMintable) revert ExceedMintingCapacity(minted[msg.sender].publicMinted);
        internalMint(msg.sender, msg.value, MintingType.PUBLIC_MINT);
    }

    /**
    * @inheritdoc IAccessPassNFT
    */
    function randomizeTiers(
        uint64 subscriptionId,
        bytes32 gasLane,
        uint32 callbackGasLimit
    ) external
        override
        onlyOwner
        onlyOnOrAfter(ContractStatus.END_MINTING)
    {
        /// Only allow randomize if random word has not been set
        if (tiersRandomWord != 0) revert CanNoLongerCall();

        // making sure that the request has enough callbackGasLimit to execute
        if (callbackGasLimit < 40_000) revert IncorrectValue("callbackGasLimit");

        /// Call Chainlink to receive a random word
        /// Will revert if subscription is not funded.
        VRFCoordinatorV2Interface coordinator = VRFCoordinatorV2Interface(chainlinkCoordinator);
        /// Now Chainlink will call us back in a future transaction, see function fulfillRandomWords

        tiersRequestId = coordinator.requestRandomWords(
            gasLane,
            subscriptionId,
            3, /// Request confirmations
            callbackGasLimit,
            1 /// request 1 random number
        );

        emit TiersRandomWordRequested(tiersRequestId);
    }

    /**
    * @inheritdoc IAccessPassNFT
    */
    function revealTiers(
        string memory revealedURI
    ) external
        override
        onlyOwner
        onlyOnOrAfter(ContractStatus.TIERS_RANDOMIZED)
    {
        if (tiersRevealed) revert CallingMoreThanOnce();
        bytes memory bytesRevealedURI = bytes(revealedURI);
        if (bytesRevealedURI[bytesRevealedURI.length - 1] != bytes("/")[0]) revert IncorrectValue("revealedURI");
        baseURI = revealedURI;
        tiersRevealed = true;

        emit TiersRevealed();
    }

    /**
    * @inheritdoc IAccessPassNFT
    */
    function randomizeTickets(
        uint64 subscriptionId,
        bytes32 gasLane,
        uint32 callbackGasLimit
    ) external
        override
        onlyOwner
        onlyOnOrAfter(ContractStatus.END_MINTING)
    {
        // Only allow randomize if random word has not been set
        if (ticketsRandomWord != 0) revert CanNoLongerCall();

        // making sure that the request has enough callbackGasLimit to execute
        if (callbackGasLimit < 40_000) revert IncorrectValue("callbackGasLimit");

        /// Call Chainlink to receive a random word
        /// Will revert if subscription is not funded.
        VRFCoordinatorV2Interface coordinator = VRFCoordinatorV2Interface(chainlinkCoordinator);
        ticketsRequestId = coordinator.requestRandomWords(
            gasLane,
            subscriptionId,
            3, /// Request confirmations
            callbackGasLimit,
            1 /// request 1 random number
        );

        emit TicketsRandomWordRequested(ticketsRequestId);
        /// Now Chainlink will call us back in a future transaction, see function fulfillRandomWords
    }

    /**
    * @inheritdoc IAccessPassNFT
    */
    function setWhitelistSigner(address whiteListSigner_) external override onlyOwner {
        _setWhiteListSigner(whiteListSigner_);
    }

    /**
    * @inheritdoc IAccessPassNFT
    */
    function setTicketNFT(TicketNFT ticketNFT_) external override onlyOwner() {
        bytes4 ticketNFTInterfaceId = type(ITicketNFT).interfaceId;
        if (!ticketNFT_.supportsInterface(ticketNFTInterfaceId)) revert IncorrectValue("ticketNFT_");

        // should not be able to setTicketNFT if ticketNFTs have been airdropped
        if (address(ticketNFT) != address(0)) {

            // contractStatus 2 means that the tickets have been airdropped so any status before that should be good
            if (uint(ticketNFT.contractStatus()) > 1) revert  CanNoLongerCall();
        }
        emit TicketNFTSet(ticketNFT, ticketNFT_);
        ticketNFT = ticketNFT_;
    }

    /**
    * @inheritdoc IAccessPassNFT
    */
    function setTreasury(address payable treasury_) external override onlyOwner() {
        if (treasury_ == address(0)) revert ZeroAddress("treasury");
        emit TreasurySet(treasury, treasury_);
        treasury = treasury_;
    }

    /**
    * @inheritdoc IAccessPassNFT
    */
    function setRoyaltyFee(uint96 royaltyFee) external override onlyOwner() {
        _setDefaultRoyalty(treasury, royaltyFee);

        emit RoyaltyFeesSet(royaltyFee);
    }

    /**
    * @inheritdoc IAccessPassNFT
    */
    function setPrice(uint256 price_) external override onlyOwner {
        if (price_ == 0) revert IsZero("price");
        emit PriceSet(price, price_);
        price = price_;
    }

    /**
    * @inheritdoc IAccessPassNFT
    */
    function setContractURI(string memory contractURI_) external override onlyOwner() {
        if (bytes(contractURI_).length == 0) revert EmptyString("contractURI");
        emit ContractURISet(contractURI, contractURI_);
        contractURI = contractURI_;
    }

    /**
    * @inheritdoc IAccessPassNFT
    */
    function setUnrevealedURI(string memory unrevealedURI_) external override onlyOwner {
        bytes memory bytesUnrevealedURI = bytes(unrevealedURI_);
        if (bytesUnrevealedURI[bytesUnrevealedURI.length - 1] != bytes("/")[0]) revert IncorrectValue("unrevealedURI");
        emit UnrevealedURISet(unrevealedURI, unrevealedURI_);
        unrevealedURI = unrevealedURI_;
    }

    /**
    * @inheritdoc IAccessPassNFT
    */
    function setPrivateMintingTimestamp(
        uint256 privateMintingTimestamp_
    ) external
        override
        onlyOwner
        onlyBefore(ContractStatus.PRIVATE_MINTING)
    {
        if (
            privateMintingTimestamp_ >= publicMintingTimestamp &&
            privateMintingTimestamp_ != 0 &&
            publicMintingTimestamp != 0
        ) revert IncorrectValue("privateMintingTimestamp");
        emit PrivateMintingTimestampSet(privateMintingTimestamp, privateMintingTimestamp_);
        privateMintingTimestamp = privateMintingTimestamp_;
    }

    /**
    * @inheritdoc IAccessPassNFT
    */
    function setPublicMintingTimestamp(
        uint256 publicMintingTimestamp_
    ) external
        override
        onlyOwner
        onlyBefore(ContractStatus.PUBLIC_MINTING)
    {
        if (
            publicMintingTimestamp_ < privateMintingTimestamp &&
            publicMintingTimestamp_ != 0
        ) revert IncorrectValue("publicMintingTimestamp");

        emit PublicMintingTimestampSet(publicMintingTimestamp, publicMintingTimestamp_);
        publicMintingTimestamp = publicMintingTimestamp_;
    }

    /**
    * @inheritdoc IAccessPassNFT
    */
    function setMaxPublicMintable(uint16 maxPublicMintable_) external override onlyOwner {
        if (maxPublicMintable_ == 0) revert IsZero("maxPublicMintable");
        emit MaxPublicMintableSet(maxPublicMintable, maxPublicMintable_);
        maxPublicMintable = maxPublicMintable_;
    }

    /********************** EXTERNAL VIEW ********************************/

    /**
    * @inheritdoc IAccessPassNFT
    */
    function mintedBy(address minter) external view override returns (uint256) {
        if(minter == address(0)) revert ZeroAddressQuery();
        return minted[minter].privateMinted + minted[minter].publicMinted;
    }

    /**
    * @inheritdoc IAccessPassNFT
    */
    function mintedBy(address minter, MintingType mintingType) external view override returns (uint256) {
        if(minter == address(0)) revert ZeroAddressQuery();
        if (mintingType == MintingType.PRIVATE_MINT) return minted[minter].privateMinted;
        else return minted[minter].publicMinted;
    }

    /**
    * @inheritdoc IAccessPassNFT
    */
    function nftTier(
        uint256 tokenId
    ) external
        view
        override
        onlyOnOrAfter(ContractStatus.TIERS_RANDOMIZED)
        returns (uint16 tier)
    {
        if (!_exists(tokenId)) revert NonExistentToken();
        return nftTiers()[tokenId];
    }

    /**
    * @inheritdoc IAccessPassNFT
    */
    function ticketsRevealed() external view override returns(bool) {
        return ticketsRandomWord != 0;
    }

    /**
    * @inheritdoc IAccessPassNFT
    */
    function winners() external view override onlyOnOrAfter(ContractStatus.TICKETS_RANDOMIZED) returns (uint16[] memory) {

        // Setup a pool with random values
        uint256 randomPoolSize = 100;
        uint256 batch = 0;
        uint16[] memory randomPool = randArray(ticketsRandomWord, randomPoolSize, batch++);

        /// Setup an array with nfts that will be returned
        uint16[] memory nfts = new uint16[](maxTotalSupply);
        uint256 counter;
        uint256 randomId;

        // Assign 500 winners
        for(uint256 i = 0; i < ticketSupply; i++) {
            randomId = randomPool[counter++];
            if (counter == randomPoolSize) {
                randomPool = randArray(ticketsRandomWord, randomPoolSize, batch++);
                counter = 0;
            }
            while(nfts[randomId] != 0) {
                randomId = randomPool[counter++];
                if (counter == randomPoolSize) {
                    randomPool = randArray(ticketsRandomWord, randomPoolSize, batch++);
                    counter = 0;
                }
            }
            nfts[randomId] = 1;     // Winner
        }

        return nfts;
    }

    /********************** PUBLIC ********************************/

    /**
    * @inheritdoc IAccessPassNFT
    */
    function totalSupply() public view override returns (uint256) {
        return tokenIdCounter.current();
    }

    /**
    * @inheritdoc IAccessPassNFT
    */
    function contractStatus() public view override returns (ContractStatus) {
        if (ticketsRandomWord != 0) return ContractStatus.TICKETS_RANDOMIZED;
        if (tiersRevealed) return ContractStatus.TIERS_REVEALED;
        if (tiersRandomWord != 0) return ContractStatus.TIERS_RANDOMIZED;
        if (maxTotalSupply == tokenIdCounter.current()) return ContractStatus.END_MINTING;
        if (
            block.timestamp >= privateMintingTimestamp &&
            privateMintingTimestamp != 0 &&
            (
            block.timestamp < publicMintingTimestamp ||
            publicMintingTimestamp == 0
            )
        ) return ContractStatus.PRIVATE_MINTING;
        if (
            block.timestamp >= publicMintingTimestamp &&
            publicMintingTimestamp != 0 &&
            privateMintingTimestamp != 0
        ) return ContractStatus.PUBLIC_MINTING;
        return ContractStatus.NO_MINTING;
    }

    /**
    * @notice returns the unrevealed uri when the reveal hasn't happened yet and when it has, returns the real uri
    * @param tokenId should be a minted tokenId owned by an account
    */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert NonExistentToken();

        if (!tiersRevealed) return string(abi.encodePacked(unrevealedURI, tokenId.toString(), ".json"));
        return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
    }

    /**
    * @inheritdoc IAccessPassNFT
    */
    function nftTiers() public view override onlyOnOrAfter(ContractStatus.TIERS_RANDOMIZED) returns (uint16[] memory) {
        /// Setup a pool with random values
        uint256 randomPoolSize = 500;
        uint256 batch = 0;
        uint16[] memory randomPool = randArray(tiersRandomWord, randomPoolSize, batch++);

        /// Setup an array with nfts that will be returned
        uint16[] memory nfts = new uint16[](maxTotalSupply);
        uint256 counter;    /// Loop counter to check when we exhaust our random pool and need to fill it again
        uint256 randomId;   /// Random NFT id

        /// Assign goldenTierSupply golden tier nfts
        for(uint256 i = 0; i < goldenTierSupply; i++) {
            randomId = randomPool[counter++];
            if (counter == randomPoolSize) { /// If we exhaust the random pool, fill it again
                randomPool = randArray(tiersRandomWord, randomPoolSize, batch++);
                counter = 0;
            }
            while(nfts[randomId] != 0) { /// Loop while the NFT id already has a tier assigned
                randomId = randomPool[counter++]; /// If we exhaust the random pool, fill it again
                if (counter == randomPoolSize) {
                    randomPool = randArray(tiersRandomWord, randomPoolSize, batch++);
                    counter = 0;
                }
            }
            nfts[randomId] = uint16(Tier.GOLD);
        }

        // Assign silverTierSupply silver tier nfts
        for(uint256 i = 0; i < silverTierSupply; i++) {
            randomId = randomPool[counter++];
            if (counter == randomPoolSize) { /// If we exhaust the random pool, fill it again
                randomPool = randArray(tiersRandomWord, randomPoolSize, batch++);
                counter = 0;
            }
            while(nfts[randomId] != 0) { /// Loop while the NFT id already has a tier assigned
                randomId = randomPool[counter++];
                if (counter == randomPoolSize) { /// If we exhaust the random pool, fill it again
                    randomPool = randArray(tiersRandomWord, randomPoolSize, batch++);
                    counter = 0;
                }
            }
            nfts[randomId] = uint16(Tier.SILVER);
        }

        // All remaining nfts are automatically bronze because they are already set to 0
        return nfts;
    }

    /**
    * @inheritdoc IERC165
    */
    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721Royalty, IERC165)
    returns (bool)
    {
        return
            interfaceId == type(IAccessPassNFT).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /********************** INTERNAL ********************************/

    /**
    * @notice check if the owner has a winning ticket
    * @inheritdoc ERC721
    */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {

        if (address(ticketNFT) != address(0)) {
            uint256 frozenPeriod = ticketNFT.frozenPeriod();
            // not allowing winners to transfer if they only have one AccessPassNFT
            if (
                block.timestamp < frozenPeriod &&
                ticketNFT.isAccountWinner(from) &&
                balanceOf(from) == 1
            ) revert TransferringFrozenAccount(from, block.timestamp, frozenPeriod);
        }
    }

    /**
    * @notice pays treasury the amount
    * @param account is the account that paid
    * @param amount is how much the account has paid
    */
    function payTreasury(address account, uint256 amount) internal {
        (bool success, ) = treasury.call{value: amount}("");
        require (success, "Could not pay treasury");
        emit TreasuryPaid(account, amount);
    }

    /**
    * @notice internal mint function
    * @param to is the account receiving the NFT
    * @param amountPaid is the amount that the account has paid for the mint
    * @param mintingType could be PRIVATE_MINT or PUBLIC_MINT
    */
    function internalMint(
        address to,
        uint256 amountPaid,
        MintingType mintingType
    ) internal
        onlyBefore(ContractStatus.END_MINTING)
    {
        if (amountPaid != price) revert IncorrectValue("amountPaid");
        uint256 tokenId = tokenIdCounter.current();

        payTreasury(to, amountPaid);

        tokenIdCounter.increment();
        if (MintingType.PRIVATE_MINT == mintingType) {
            minted[to].privateMinted += 1;
        } else {
            minted[to].publicMinted += 1;
        }

        _safeMint(to, tokenId);
    }

    /**
    * @notice Chainlink calls us with a random value. (See VRFConsumerBaseV2's fulfillRandomWords function)
    * @dev Note that this happens in a later transaction than the request.
    * @param requestId is the id of the request from VRF's side
    * @param randomWords is an array of random numbers generated by VRF
    */
    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        if (requestId == 0) revert IsZero("requestId");
        if (requestId == tiersRequestId) {
            if (tiersRandomWord != 0) revert CallingMoreThanOnce();
            tiersRandomWord = randomWords[0]; /// Set the random value received from Chainlink
            emit TiersRandomized(tiersRandomWord);
        } else if (requestId == ticketsRequestId) {
            if (ticketsRandomWord != 0) revert CallingMoreThanOnce();
            ticketsRandomWord = randomWords[0]; /// Set the random value received from Chainlink
            emit TicketsRandomized(ticketsRandomWord);
        }
    }

    /**
    * @notice Returns a list of x random numbers, in increments of 16 numbers.
    * So you may receive x random numbers or up to 15 more. The random numbers are between 0 and 499
    * Each batch will be different, you can call multiple times with different batch numbers
    * This routine is deterministic and will always return the same result if randomWord is the same
    * @param randomWord can only be tiersRandomWord and ticketsRandomWord
    * @param max is the max numbers needed in a batch
    * @param batch represents the batch number
    */
    function randArray(uint256 randomWord, uint256 max, uint256 batch) internal view returns (uint16[] memory) {
        // First make sure the random chainlinkVRF value is initialized
        if (randomWord == 0) revert IsZero("randomWord");
        uint256 mask = 0xFFFF;   // 0xFFFF == [1111111111111111], masking the last 16 bits

        uint256 mainCounterMax = max / 16;
        if (max % 16 > 0) {
            mainCounterMax +=1;
        }
        uint256 batchOffset = (batch * mainCounterMax * 16);
        uint16[] memory randomValues = new uint16[](mainCounterMax * 16);
        for (uint256 mainCounter = 0; mainCounter < mainCounterMax; mainCounter++) {
            uint256 randomValue = uint256(keccak256(abi.encode(randomWord, mainCounter + batchOffset)));
            for (uint256 subCounter = 0; subCounter < 16; subCounter++) {
                randomValues[mainCounter * 16 + subCounter] = uint16(randomValue & mask) % maxTotalSupply;   // Mask 16 bits, value between 0 .. MAX_TOTAL_SUPPLY-1
                randomValue = randomValue / 2 ** 16;     // Right shift 16 bits into oblivion
            }
        }
        return randomValues;
    }

    /********************** MODIFIERS ********************************/

    /**
    * @notice functions like a less than to the supplied status
    * @param status is a ContractStatus in which the function must happen before in. For example:
    * setting the privateMintTimestamp should only happen before private minting starts to ensure that no one
    * messes with the privateMint settings during ContractStatus.PrivateMinting. To do that add this modifier
    * with the parameter: ContractStatus.PrivateMinting
    */
    modifier onlyBefore(ContractStatus status) {
        // asserting here because there should be no state before NO_MINTING
        assert(status != ContractStatus.NO_MINTING);
        ContractStatus lastStatus = ContractStatus(uint(status) - 1);
        if (contractStatus() >= status) revert IncorrectContractStatus(contractStatus(), lastStatus);
        _;
    }

    /**
    * @notice functions like a an equal to the supplied status
    * @param status is the ContractStatus it must be in
    */
    modifier onlyDuring(ContractStatus status) {
        if (contractStatus() != status) revert IncorrectContractStatus(contractStatus(), status);
        _;
    }

    /**
    * @notice functions like a greater than or equal to. The current status must be the same as or happened after the parameter.
    * @param status that the contract must at least be in. For example:
    * getting the nftTiers should only happen when TIERS_RANDOMIZED has already happened. so the parameter will be
    * TIERS_RANDOMIZED, because the function can only work once the status is TIERS_RANDOMIZED or has passed that
    */
    modifier onlyOnOrAfter(ContractStatus status) {
        if (contractStatus() < status) revert IncorrectContractStatus(contractStatus(), status);
        _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
* @title An abstract contract that checks if the verified slot is valid
* @author Oost & Voort, Inc
* @notice This contract is to be used in conjunction with the AccessPassNFT contract
*/

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./interfaces/IVerifiedSlot.sol";

abstract contract WhitelistVerifier is IVerifiedSlot {
    using ECDSA for bytes32;

    /**
    * @dev The following struct follows the EIP712 Standard
    */
    struct EIP712Domain {
        string name;
        string version;
        uint256 chainId;
        address verifyingContract;
    }

    /**
    * @dev The typehash for EIP712Domain
    */
    bytes32 constant EIP712DOMAIN_TYPEHASH = keccak256(
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
    );

    /**
    * @dev The typehash for the message being sent to the contract
    */
    bytes32 constant VERIFIED_SLOT_TYPEHASH =
        keccak256("VerifiedSlot(address minter,uint256 mintingCapacity)");

    /**
    * @dev The hashed Domain Message
    */
    bytes32 DOMAIN_SEPARATOR;

    /**
    * @dev the address of the whiteListSigner which is an EOA that signs a message that confirms who can mint how much
    */
    address public whiteListSigner;

    /**
    * @dev emitted when the whitelistSigner has been set
    * @param oldSigner represents the old signer for the Contract
    * @param newSigner represents the newly set signer for the Contract
    */
    event WhitelistSignerSet(address oldSigner, address newSigner);

    /**
    * @dev reverts with this message when the Zero Address is being used to set the Whitelist Signer
    */
    error WhitelistSignerIsZeroAddress();

    /**
    * @dev reverts with this message when the Caller of the mint is not the same as the one in the VerifiedSLot
    * @param caller is the account that called for the mint
    * @param minter is the address specified in the VerifiedSlot
    */
    error CallerIsNotMinter(address caller, address minter);

    /**
    * @dev reverts with this message when the message is not correct or if it is not signed by the WhitelistSigner
    * @param unknownSigner is the signer that signed the message
    * @param whitelistSigner is the signer who should have signed the message
    */
    error UnknownSigner(address unknownSigner, address whitelistSigner);

    /**
    * @dev reverts with this message when the caller is trying to mint more than allowed
    * @param minted is the amount of tokens the caller has minted already
    */
    error ExceedMintingCapacity(uint256 minted);

    /**
    * @notice initializes the contract
    */
    constructor () {
        DOMAIN_SEPARATOR = hash(EIP712Domain({
            name: "AccessPassNFT",
            version: '1',
            chainId: block.chainid,
            verifyingContract: address(this)
        }));
    }

    /**
    * @notice sets the whitelistSigner
    * @param whitelistSigner_ is an EOA that signs verified slots
    */
    function _setWhiteListSigner(address whitelistSigner_) internal virtual {
        if (whitelistSigner_ == address(0)) revert WhitelistSignerIsZeroAddress();

        emit WhitelistSignerSet(whiteListSigner, whitelistSigner_);
        whiteListSigner = whitelistSigner_;

    }

    /**
    * @notice validates verified slot
    * @param minter is msg.sender
    * @param minted is the amount the minter has minted
    * @param verifiedSlot is an object with the following:
    * minter: address of the minter,
    * mintingCapacity: amount Metaframes has decided to grant to the minter,
    * r and s --- The x co-ordinate of r and the s value of the signature
    * v: The parity of the y co-ordinate of r
    */
    function validateVerifiedSlot(
        address minter,
        uint256 minted,
        VerifiedSlot memory verifiedSlot
    ) internal view
    {
        if (whiteListSigner == address(0)) revert WhitelistSignerIsZeroAddress();
        if (verifiedSlot.minter != minter) revert CallerIsNotMinter(minter, verifiedSlot.minter);
        if(verifiedSlot.mintingCapacity <= minted) revert ExceedMintingCapacity(minted);

        address wouldBeSigner = getSigner(verifiedSlot);
        if (wouldBeSigner != whiteListSigner) revert UnknownSigner(wouldBeSigner, whiteListSigner);
    }

    /**
    * @notice hashes the DOMAIN object using keccak256
    * @param eip712Domain represents the EIP712 object to be hashed
    */
    function hash(EIP712Domain memory eip712Domain) internal pure returns (bytes32) {
        return keccak256(abi.encode(
                EIP712DOMAIN_TYPEHASH,
                keccak256(bytes(eip712Domain.name)),
                keccak256(bytes(eip712Domain.version)),
                eip712Domain.chainId,
                eip712Domain.verifyingContract
            ));
    }

    /**
    * @notice hashes the verifiedslot object using keccak256
    * @param verifiedSlot is an object with the following:
    * minter: address of the minter,
    * mintingCapacity: amount Metaframes has decided to grant to the minter,
    * r and s --- The x co-ordinate of r and the s value of the signature
    * v: The parity of the y co-ordinate of r
    */
    function hash(VerifiedSlot memory verifiedSlot) internal pure returns (bytes32) {
        return
        keccak256(abi.encode(
            VERIFIED_SLOT_TYPEHASH,
            verifiedSlot.minter,
            verifiedSlot.mintingCapacity
        ));
    }

    /**
    * @notice returns the signer of a given verifiedSlot to be used to check who signed the message
    * @param verifiedSlot is an object with the following:
    * minter: address of the minter,
    * mintingCapacity: amount Metaframes has decided to grant to the minter,
    * r and s --- The x co-ordinate of r and the s value of the signature
    * v: The parity of the y co-ordinate of r
    */
    function getSigner(VerifiedSlot memory verifiedSlot) internal view returns (address) {

        // Note: we need to use `encodePacked` here instead of `encode`.
        bytes32 digest = keccak256(abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                hash(verifiedSlot)
            ));

        return ecrecover(digest, verifiedSlot.v, verifiedSlot.r, verifiedSlot.s);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/ERC721Royalty.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "../../common/ERC2981.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev Extension of ERC721 with the ERC2981 NFT Royalty Standard, a standardized way to retrieve royalty payment
 * information.
 *
 * Royalty information can be specified globally for all token ids via {_setDefaultRoyalty}, and/or individually for
 * specific token ids via {_setTokenRoyalty}. The latter takes precedence over the first.
 *
 * IMPORTANT: ERC-2981 only specifies a way to signal royalty information and does not enforce its payment. See
 * https://eips.ethereum.org/EIPS/eip-2981#optional-royalty-payments[Rationale] in the EIP. Marketplaces are expected to
 * voluntarily pay royalties together with sales, but note that this standard is not yet widely supported.
 *
 * _Available since v4.5._
 */
abstract contract ERC721Royalty is ERC2981, ERC721 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {ERC721-_burn}. This override additionally clears the royalty information for the token.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);
        _resetTokenRoyalty(tokenId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface VRFCoordinatorV2Interface {
  /**
   * @notice Get configuration relevant for making requests
   * @return minimumRequestConfirmations global min for request confirmations
   * @return maxGasLimit global max for request gas limit
   * @return s_provingKeyHashes list of registered key hashes
   */
  function getRequestConfig()
    external
    view
    returns (
      uint16,
      uint32,
      bytes32[] memory
    );

  /**
   * @notice Request a set of random words.
   * @param keyHash - Corresponds to a particular oracle job which uses
   * that key for generating the VRF proof. Different keyHash's have different gas price
   * ceilings, so you can select a specific one to bound your maximum per request cost.
   * @param subId  - The ID of the VRF subscription. Must be funded
   * with the minimum subscription balance required for the selected keyHash.
   * @param minimumRequestConfirmations - How many blocks you'd like the
   * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
   * for why you may want to request more. The acceptable range is
   * [minimumRequestBlockConfirmations, 200].
   * @param callbackGasLimit - How much gas you'd like to receive in your
   * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
   * may be slightly less than this amount because of gas used calling the function
   * (argument decoding etc.), so you may need to request slightly more than you expect
   * to have inside fulfillRandomWords. The acceptable range is
   * [0, maxGasLimit]
   * @param numWords - The number of uint256 random values you'd like to receive
   * in your fulfillRandomWords callback. Note these numbers are expanded in a
   * secure way by the VRFCoordinator from a single random value supplied by the oracle.
   * @return requestId - A unique identifier of the request. Can be used to match
   * a request to a response in fulfillRandomWords.
   */
  function requestRandomWords(
    bytes32 keyHash,
    uint64 subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords
  ) external returns (uint256 requestId);

  /**
   * @notice Create a VRF subscription.
   * @return subId - A unique subscription id.
   * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
   * @dev Note to fund the subscription, use transferAndCall. For example
   * @dev  LINKTOKEN.transferAndCall(
   * @dev    address(COORDINATOR),
   * @dev    amount,
   * @dev    abi.encode(subId));
   */
  function createSubscription() external returns (uint64 subId);

  /**
   * @notice Get a VRF subscription.
   * @param subId - ID of the subscription
   * @return balance - LINK balance of the subscription in juels.
   * @return reqCount - number of requests for this subscription, determines fee tier.
   * @return owner - owner of the subscription.
   * @return consumers - list of consumer address which are able to use this subscription.
   */
  function getSubscription(uint64 subId)
    external
    view
    returns (
      uint96 balance,
      uint64 reqCount,
      address owner,
      address[] memory consumers
    );

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @param newOwner - proposed new owner of the subscription
   */
  function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external;

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @dev will revert if original owner of subId has
   * not requested that msg.sender become the new owner.
   */
  function acceptSubscriptionOwnerTransfer(uint64 subId) external;

  /**
   * @notice Add a consumer to a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - New consumer which can use the subscription
   */
  function addConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Remove a consumer from a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - Consumer to remove from the subscription
   */
  function removeConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Cancel a subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the remaining LINK to
   */
  function cancelSubscription(uint64 subId, address to) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness. It ensures 2 things:
 * @dev 1. The fulfillment came from the VRFCoordinator
 * @dev 2. The consumer contract implements fulfillRandomWords.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash). Create subscription, fund it
 * @dev and your consumer contract as a consumer of it (see VRFCoordinatorInterface
 * @dev subscription management functions).
 * @dev Call requestRandomWords(keyHash, subId, minimumRequestConfirmations,
 * @dev callbackGasLimit, numWords),
 * @dev see (VRFCoordinatorInterface for a description of the arguments).
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomWords method.
 *
 * @dev The randomness argument to fulfillRandomWords is a set of random words
 * @dev generated from your requestId and the blockHash of the request.
 *
 * @dev If your contract could have concurrent requests open, you can use the
 * @dev requestId returned from requestRandomWords to track which response is associated
 * @dev with which randomness request.
 * @dev See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ.
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request. It is for this reason that
 * @dev that you can signal to an oracle you'd like them to wait longer before
 * @dev responding to the request (however this is not enforced in the contract
 * @dev and so remains effective only in the case of unmodified oracle software).
 */
abstract contract VRFConsumerBaseV2 {
  error OnlyCoordinatorCanFulfill(address have, address want);
  address private immutable vrfCoordinator;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   */
  constructor(address _vrfCoordinator) {
    vrfCoordinator = _vrfCoordinator;
  }

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBaseV2 expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomWords the VRF output expanded to the requested number of words
   */
  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual;

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
    if (msg.sender != vrfCoordinator) {
      revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
    }
    fulfillRandomWords(requestId, randomWords);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.8.6;

/**
* @title NFTs for the TicketCompetition to the World Cup for Metaframes
* @author MetaFrames
* @notice This is the NFT contract used as basis to determine the winner of the World Cup Ticket. This is also
* related to the AccessPassNFT
* @dev The flow of the contract is as follows:
* Deployment: Contract is deployed and configured
* -----------------------------------------------
* Airdrop: Minting TicketNFTs to 500 Random Users
*  -airdrop()
* -----------------------------------------------
* Ticket Competition: Selection of the ticket winner
*  -setRegistered() means registration was done off-chain
*  -requestRandomWord() requests the random number from VRF
*  -ticketWinners() then returns the winner
* -----------------------------------------------
* Winners Frozen: When winning tokens are barred from trading their tokens
* -----------------------------------------------
* Trading Enabled: When all trading has been enabled again
*/

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "./AccessPassNFT.sol";
import "./interfaces/IAccessPassNFT.sol";
import "./interfaces/ITicketNFT.sol";

contract TicketNFT is Ownable, ERC721Royalty, VRFConsumerBaseV2, ITicketNFT {
    using Strings for uint256;

    uint16 public constant NUMBER_OF_WINNERS = 2;

    /**
    * @dev maxTotalSupply is the amount of NFTs that can be minted
    */
    uint16 public immutable maxTotalSupply;

    /**
    * @dev contractURI is an OpenSea standard. This should point to a metadata that tells who will receive revenues
    * from OpensSea. See https://docs.opensea.io/docs/contract-level-metadata
    */
    string public contractURI;

    /**
    * @dev frozenPeriod is a timestamp for when the ticket winners can start trading again
    */
    uint256 public frozenPeriod;

    /**
    * @dev if set to true, that particular nft is a winner
    */
    mapping(uint256 => bool) public isWinner;

    /**
    * @dev array of winning ids
    */
    uint256[] public ticketWinners;

    /**
    * @dev baseURI is the base of the token metadata used in conjunction with the token id
    */
    string public baseURI;

    /**
    * @dev flag that tells if the tickets have been airdropped
    */
    bool public ticketsAirdropped;

    /**
    * @dev flag that tells if the registration has been set
    */
    bool public hasSetRegistration;

    /**
    * @dev Mapping of token id to if the owner of that token id has not registered off-chain.
    * For example:
    * 1. owner of token id 0 has registered, so 0 => false
    * 2. owner of token id 2 has NOT registered, so 1 => true
    * This was purposely made as hasNotRegistered so that we only write for values that have not registered.
    * This is to save gas since there should be more people who have registered than those who have not.
    * The registration comes from an off-chain database.
    */
    mapping(uint16 => bool) private _hasNotRegistered;

    /**
    * @dev the related AccessPassNFT to this contract
    */
    AccessPassNFT public accessPassNFT;

    /**
    * @dev The following variables are needed to request a random value from Chainlink.
    * See https://docs.chain.link/docs/vrf-contracts/
    */
    address public chainlinkCoordinator; // Chainlink Coordinator address
    uint256 public requestId;            // Chainlink request id for the selection of the ticket winner
    uint256 public randomWord;           // Random value received from Chainlink VRF

    /**
    * @notice initializes the contract
    * @param baseURI_ is the metadata's uri
    * @param contractURI_ is for OpenSeas compatability
    * @param royaltyAddress receives royalties fee from selling this token
    * @param royaltyFee is the fees taken from second-hand selling. This is expressed in _royaltyFee/1000.
    * So to do 5% means supplying 50 since 50/1000 is 5% (see ERC2981 function _setDefaultRoyalty(address receiver, uint96 feeNumerator))
    * @param accessPassNFT_ is the address of the AccessPassNFT related to this token
    * @param vrfCoordinator_ is the address of the VRF used for getting a random number
    * @param nftHolder is the temporary holder of the NFTs before the airdrop
    * @param frozenPeriod_ is a timestamp for when the ticket winners can start trading again
    */
    constructor(
        string memory baseURI_,
        string memory contractURI_,
        address royaltyAddress,
        uint96 royaltyFee,
        AccessPassNFT accessPassNFT_,
        address vrfCoordinator_,
        address nftHolder,
        uint256 frozenPeriod_
    ) ERC721("Maradona Official World Cup Ticket", "OMWC")
      VRFConsumerBaseV2(vrfCoordinator_){

        // crucial to check if there is a '/' in the end since this can no longer be changed once set
        // must have a '/' in the end since the token id follows the '/'
        bytes memory bytesBaseURI = bytes(baseURI_);
        if (bytesBaseURI[bytesBaseURI.length - 1] != bytes("/")[0]) revert IncorrectValue("baseURI");
        baseURI = baseURI_;

        if (bytes(contractURI_).length == 0) revert EmptyString("contractURI");
        contractURI = contractURI_;

        if(royaltyAddress == address(0)) revert ZeroAddress("royaltyAddress");
        // not checking royaltyFee on purpose here
        _setDefaultRoyalty(royaltyAddress, royaltyFee);

        uint16 maxTotalSupply_ = accessPassNFT_.ticketSupply();
        maxTotalSupply = maxTotalSupply_;

        bytes4 accessPassNFTInterfaceId = type(IAccessPassNFT).interfaceId;
        if(!accessPassNFT_.supportsInterface(accessPassNFTInterfaceId)) revert IncorrectValue("accessPassNFT");
        accessPassNFT = accessPassNFT_;

        if(address(vrfCoordinator_) == address(0)) revert ZeroAddress("vrfCoordinator");
        chainlinkCoordinator = vrfCoordinator_;

        if(nftHolder == address(0)) revert ZeroAddress("nftHolder");

        // sending nfts to nftHolder which will be the eventual owner of the contract who will do the airdrop
        for (uint256 i = 0; i < maxTotalSupply_; i++) {
            _safeMint(nftHolder, i);
        }

        // not checking frozenPeriod_ on purpose here because there's a way to change it later
        frozenPeriod = frozenPeriod_;

    }

    /********************** EXTERNAL ********************************/

    /**
    * @inheritdoc ITicketNFT
    */
    function airdrop(
        uint16[] calldata winners
    ) external
        override
        onlyOwner
        onlyDuring(ContractStatus.TICKETS_REVEALED)
    {
        if (winners.length != maxTotalSupply) revert IncorrectValue("winners");

        for (uint256 i = 0; i < winners.length; i++) {
            safeTransferFrom(msg.sender, accessPassNFT.ownerOf(winners[i]), i);
        }

        ticketsAirdropped = true;
        emit TicketsAirdropped(winners);
    }

    /**
    * @inheritdoc ITicketNFT
    */
    function requestRandomWord(
        uint64 subscriptionId,
        bytes32 gasLane,
        uint32 callbackGasLimit
    ) external
        override
        onlyOwner
        onlyDuring(ContractStatus.SET_REGISTRATION)
    {

        // making sure that the request has enough callbackGasLimit to execute
        if (callbackGasLimit < 150_000) revert IncorrectValue("callbackGasLimit");

        /// Call Chainlink to receive a random word
        /// Will revert if subscription is not funded.
        VRFCoordinatorV2Interface coordinator = VRFCoordinatorV2Interface(chainlinkCoordinator);
        requestId = coordinator.requestRandomWords(
            gasLane,
            subscriptionId,
            3, /// Request confirmations
            callbackGasLimit,
            1 /// request 1 random number
        );
        /// Now Chainlink will call us back in a future transaction, see function fulfillRandomWords

        emit RandomWordRequested(requestId);
    }

    /**
    * @inheritdoc ITicketNFT
    */
    function setContractURI(string memory uri) external override onlyOwner() {
        if (bytes(uri).length == 0) revert EmptyString("contractURI");
        emit ContractURISet(contractURI, uri);
        contractURI = uri;
    }

    /**
    * @inheritdoc ITicketNFT
    */
    function setDefaultRoyalty(address royaltyAddress, uint96 royaltyFee) external override onlyOwner(){
        if (address(0) == royaltyAddress) revert ZeroAddress("royaltyAddress");
        _setDefaultRoyalty(royaltyAddress, royaltyFee);
        emit RoyaltiesSet(royaltyAddress, royaltyFee);
    }

    /**
    * @inheritdoc ITicketNFT
    */
    function setRegistered(
        bool[] calldata hasRegistered_
    ) external
        override
        onlyOwner
        onlyDuring(ContractStatus.AIRDROPPED_TICKETS)
    {
        // sending an empty array means all accounts have registered
        if (hasRegistered_.length == 0) {
            hasSetRegistration = true;
        } else {
            if (hasRegistered_.length != maxTotalSupply) revert IncorrectValue("hasRegistered");
            uint16 notRegisteredCounter = 0;

            for (uint16 i = 0; i < hasRegistered_.length; i++) {
                if (!hasRegistered_[i]) {
                    // only writing for those who have not registered
                    _hasNotRegistered[i] = true;
                    // counting how many accounts have not registred
                    notRegisteredCounter++;
                }
            }

            // ensuring that there are enough registered to have enough winners
            if (maxTotalSupply - notRegisteredCounter < NUMBER_OF_WINNERS) revert IncorrectValue("notRegisteredCounter");
            hasSetRegistration = true;
        }
        emit RegistrationSet(hasRegistered_);
    }

    /**
    * @inheritdoc ITicketNFT
    */
    function setFrozenPeriod(uint256 frozenPeriod_) external override onlyOwner() onlyBefore(ContractStatus.WINNERS_FROZEN) {
        if (frozenPeriod_ < block.timestamp && frozenPeriod_ != 0) revert IncorrectValue("frozenPeriod_");
        emit FrozenPeriodSet(frozenPeriod, frozenPeriod_);
        frozenPeriod = frozenPeriod_;
    }

    /********************** PUBLIC VIEW ********************************/

    /**
    * @notice returns a token metadata's uri
    * @param tokenId is the id of the token being queried
    */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if(!_exists(tokenId)) revert NonExistentToken();

        return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
    }

    /**
    * @inheritdoc ITicketNFT
    */
    function hasRegistered(
        uint16 tokenId
    ) public
        view
        override
        onlyOnOrAfter(ContractStatus.SET_REGISTRATION)
        returns (bool)
    {
        if(tokenId >= maxTotalSupply) revert NonExistentToken();
        return !_hasNotRegistered[tokenId];
    }

    /**
    * @inheritdoc ITicketNFT
    */
    function isAccountWinner(address account) public view override returns (bool){
        for (uint16 i = 0; i < ticketWinners.length; i++) {
            if (ownerOf(ticketWinners[i]) == account) return true;
        }
        return false;
    }

    /**
    * @inheritdoc ITicketNFT
    */
    function contractStatus() public view override returns (ContractStatus) {
        if(randomWord != 0) {
            if(block.timestamp < frozenPeriod) return ContractStatus.WINNERS_FROZEN;
            else return ContractStatus.TRADING_ENABLED;
        }
        if(hasSetRegistration) return ContractStatus.SET_REGISTRATION;
        if(ticketsAirdropped) return ContractStatus.AIRDROPPED_TICKETS;
        if(accessPassNFT.ticketsRevealed()) return ContractStatus.TICKETS_REVEALED;
        return ContractStatus.PRE_AIRDROP;
    }

    /**
    * @inheritdoc ITicketNFT
    */
    function totalSupply() public view override returns (uint256) {
        return maxTotalSupply;
    }

    /**
    * @inheritdoc IERC165
    */
    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721Royalty, IERC165)
    returns (bool)
    {
        return
            interfaceId == type(ITicketNFT).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /********************** INTERNAL ********************************/

    /**
    * @notice check if token is frozen before transferring
    * @inheritdoc ERC721
    * @param from is the address that will give the token
    * @param to is the address that will receive the token
    * @param tokenId is the id being transferred
    */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {

        // not allowing winningIds to be transferred when in frozenPeriod
        if (
            block.timestamp < frozenPeriod &&
            isWinner[tokenId]
        ) revert TransferringFrozenToken(tokenId, block.timestamp, frozenPeriod);
    }

    /**
    * @notice sets the winners
    */
    function setWinners() internal {
        // Setup a pool with random values
        uint256 randomPoolSize = 16;
        uint256 batch = 0;
        uint16[] memory randomPool = randArray(randomPoolSize, batch++);

        uint256 counter = 0;
        uint16 randomId;

        for (uint16 i = 0; i < NUMBER_OF_WINNERS; i++) {
            randomId = randomPool[counter++];
            if (counter == randomPoolSize) {
                randomPool = randArray(randomPoolSize, batch++);
                counter = 0;
            }

            // only stays in the loop when the current id has not registered or if the current id already won
            while(_hasNotRegistered[randomId] || isWinner[randomId]) {
                randomId = randomPool[counter++];
                if (counter == randomPoolSize) {
                    randomPool = randArray(randomPoolSize, batch++);
                    counter = 0;
                }
            }

            ticketWinners.push(randomId);
            isWinner[randomId] = true; // Using mapping to keep track for if the id was already chosen as a winner
        }

        emit TicketWinnersFrozen(frozenPeriod);
    }

    /**
    * @notice Chainlink calls us with a random value. (See VRFConsumerBaseV2's fulfillRandomWords function)
    * @dev Note that this happens in a later transaction than the request. This approximately costs 139_000 in gas
    * @param requestId_ is the id of the request from VRF's side
    * @param randomWords is an array of random numbers generated by VRF
    */
    function fulfillRandomWords(
        uint256 requestId_,
        uint256[] memory randomWords
    ) internal override {
        if(requestId != requestId_) revert IncorrectValue("requestId");
        if(randomWord != 0) revert CallingMoreThanOnce();
        randomWord = randomWords[0];
        emit TicketWinnersSelected(randomWords[0]);

        setWinners();
    }

    /**
    * @notice Returns a list of x random numbers, in increments of 16 numbers.
    * So you may receive x random numbers or up to 15 more. The random numbers are between 0 and 499
    * Each batch will be different, you can call multiple times with different batch numbers
    * This routine is deterministic and will always return the same result if randomWord is the same
    * @param max is the max numbers needed in a batch
    * @param batch represents the batch number
    */
    function randArray(
        uint256 max,
        uint256 batch
    ) internal
        view
        returns (uint16[] memory)
    {
        uint256 mask = 0xFFFF;   // 0xFFFF == [1111111111111111], masking the last 16 bits

        uint256 mainCounterMax = max / 16;
        if (max % 16 > 0) {
            mainCounterMax +=1;
        }
        uint256 batchOffset = (batch * mainCounterMax * 16);
        uint16[] memory randomValues = new uint16[](mainCounterMax * 16);
        for (uint256 mainCounter = 0; mainCounter < mainCounterMax; mainCounter++) {
            uint256 randomValue = uint256(keccak256(abi.encode(randomWord, mainCounter + batchOffset)));
            for (uint256 subCounter = 0; subCounter < 16; subCounter++) {

                // Mask 16 bits, value between 0 .. maxTotalSupply-1
                randomValues[mainCounter * 16 + subCounter] = uint16(randomValue & mask) % maxTotalSupply;

                // Right shift 16 bits into oblivion
                randomValue = randomValue / 2 ** 16;
            }
        }
        return randomValues;
    }

    /********************** MODIFIER ********************************/

    /**
    * @notice functions like a less than to the supplied status
    * @param status is a ContractStatus in which the function must happen before in. For example:
    * setting the frozenPeriod should only happen before the ticketWinners have been selected to ensure that no one
    * messes with the trading period during ContractStatus.WINNERS_FROZEN. To do that add this modifier
    * with the parameter: ContractStatus.WINNERS_FROZEN
    */
    modifier onlyBefore(ContractStatus status) {
        // asserting here because there should be no state before PRE_AIRDROP
        assert(status != ContractStatus.PRE_AIRDROP);
        ContractStatus lastStatus = ContractStatus(uint(status) - 1);
        if (contractStatus() >= status) revert IncorrectContractStatus(contractStatus(), lastStatus);
        _;
    }

    /**
    * @notice the current status must be equal to the status in the parameter
    * @param status is the ContractStatus it must be in
    */
    modifier onlyDuring(ContractStatus status) {
        if (status != contractStatus()) revert IncorrectContractStatus(contractStatus(), status);
        _;
    }


    /**
    * @notice the current status must be greater than or equal to the status in the parameter
    * @param status that the contract must at least be in. For example:
    * getting the nftTiers should only happen when TIERS_RANDOMIZED has already happened. so the parameter will be
    * TIERS_RANDOMIZED, because the function can only work once the status is TIERS_RANDOMIZED or has passed that
    */
    modifier onlyOnOrAfter(ContractStatus status) {
        if (contractStatus() < status) revert IncorrectContractStatus(contractStatus(), status);
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.8.6;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "../TicketNFT.sol";
import "./IVerifiedSlot.sol";

/**
* @title Required interface for an AccessPassNFT compliant contract
* @author Oost & Voort, Inc
*/

interface IAccessPassNFT is IERC165, IVerifiedSlot {
    /**
    * @dev The following are the stages of the contract in order:
    * NO_MINTING: Minting is not yet allowed
    * PRIVATE_MINTING: Only people in the mint whitelist can mint
    * PUBLIC_MINTING: Everyone can mint
    * END_MINTING: When everything's been minted already
    * TIERS_RANDOMIZED: When a random number has been set for the tiers
    * TIERS_REVEALED: When the final token metadata has been uploaded to IPFS
    * TICKETS_RANDOMIZED: When a random number has been set for the tickets airdrop
    */
    enum ContractStatus {
        NO_MINTING,
        PRIVATE_MINTING,
        PUBLIC_MINTING,
        END_MINTING,
        TIERS_RANDOMIZED,
        TIERS_REVEALED,
        TICKETS_RANDOMIZED
    }

    /**
    * @dev Minting types are explained below:
    * PRIVATE_MINT: minted using the private mint function
    * PUBLIC_MINT: minted using the public mint function
    */
    enum MintingType {PRIVATE_MINT, PUBLIC_MINT}

    /**
    * @dev The on-chain property of the nft that is determined by a random number
    */
    enum Tier {BRONZE, SILVER, GOLD}

    /**
    * @dev emitted when the owner has set the private minting timestamp
    * @param oldTimestamp is for what the timestamp used to be
    * @param newTimestamp is the new value
    */
    event PrivateMintingTimestampSet(uint256 oldTimestamp, uint256 newTimestamp);


    /**
    * @dev emitted when the owner has set the public minting timestamp
    * @param oldTimestamp is for what the timestamp used to be
    * @param newTimestamp is the new value
    */
    event PublicMintingTimestampSet(uint256 oldTimestamp, uint256 newTimestamp);

    /**
    * @dev emitted when the owner has changed the max number of nfts a public user can mint
    * @param oldMaxPublicMintable is the old value for the maximum a public account can mint
    * @param newMaxPublicMintable is the new value for the maximum a public account can mint
    */
    event MaxPublicMintableSet(uint16 oldMaxPublicMintable, uint16 newMaxPublicMintable);


    /**
    * @dev emitted when the owner changes the treasury
    * @param oldTreasury is the old value for the treasury
    * @param newTreasury is the new value for the treasury
    */
    event TreasurySet(address oldTreasury, address newTreasury);

    /**
    * @dev emitted when the owner changes the minting price
    * @param oldPrice is the price the minting was set as
    * @param newPrice is the new price minting will cost as
    */
    event PriceSet(uint256 oldPrice, uint256 newPrice);

    /**
    * @dev emitted when the owner changes the royalties
    * @param newRoyalties is the new royalties set by the owner
    */
    event RoyaltyFeesSet(uint96 newRoyalties);

    /**
    * @dev emitted when the owner has changed the contract uri
    * @param oldURI is the uri it was set as before
    * @param newURI is the uri it is now set in
    */
    event ContractURISet(string oldURI, string newURI);

    /**
    * @dev emitted when the owner has changed the unrevealed uri
    * @param oldURI is the uri it was set as before
    * @param newURI is the uri it is now set in
    */
    event UnrevealedURISet(string oldURI, string newURI);

    /**
    * @dev emitted when the TicketNFT has been set
    * @param oldTicketNFT is the old TicketNFT it was pointing to
    * @param newTicketNFT is the TicketNFT it is now pointing to
    */
    event TicketNFTSet(TicketNFT oldTicketNFT, TicketNFT newTicketNFT);

    /**
    * @dev emitted when the treasury has been paid in ETH
    * @param account is the account that paid the treasury
    * @param amount is how much ETH the account sent to the treasury
    */
    event TreasuryPaid(address indexed account, uint256 amount);

    /**
    * @dev the following events must be done in order
    */

    /**
    * @dev emitted when the owner has requested a random word from VRF to set the tiers of each NFT
    * @param requestId is the id set by VRF
    */
    event TiersRandomWordRequested(uint256 requestId);

    /**
    * @dev emitted when VRF has used fulfillRandomness to set the random number
    * @param randomWord is the randomWord given back in a callback by VRF
    */
    event TiersRandomized(uint256 randomWord);

    /**
    * @dev emitted when the owner has put the final token metadata uri for the nfts
    */
    event TiersRevealed();

    /**
    * @dev emitted when the owner has requested a random word from VRF to set who will be airdropped TicketNFTs
    * @param requestId is the id set by VRF
    */
    event TicketsRandomWordRequested(uint256 requestId);

    /**
    * @dev emitted when VRF has used fulfillRandomness to set the random number
    * @param randomWord is the randomWord given back in a callback by VRF
    */
    event TicketsRandomized(uint256 randomWord);

    /**
    * @dev reverted with this error when the address being supplied is Zero Address
    * @param addressName is for whom the Zero Address is being set for
    */
    error ZeroAddress(string addressName);

    /**
    * @dev reverted with this error when a view function is asking for a Zero Address' information
    */
    error ZeroAddressQuery();

    /**
    * @dev reverted with this error when a view function is being used to look for a nonExistent Token
    */
    error NonExistentToken();

    /**
    * @dev reverted with this error when a function is being called more than once
    */
    error CallingMoreThanOnce();

    /**
    * @dev reverted with this error when a function should no longer be called
    */
    error CanNoLongerCall();

    /**
    * @dev reverted with this error when a variable being supplied is valued 0
    * @param variableName is the name of the variable being supplied with 0
    */
    error IsZero(string variableName);

    /**
    * @dev reverted with this error when a variable has an incorrect value
    * @param variableName is the name of the variable with an incorrect value
    */
    error IncorrectValue(string variableName);

    /**
    * @dev reverted with this error when a string being supplied should not be empty
    * @param stringName is the name of the string being supplied with an empty value
    */
    error EmptyString(string stringName);

    /**
    * @dev reverted with this error when a function being called should not be called with the current Contract Status
    * @param currentStatus is the contract's current status
    * @param requiredStatus is the status the current must be in for the function to not revert
    */
    error IncorrectContractStatus(ContractStatus currentStatus, ContractStatus requiredStatus);

    /**
    * @dev reverted with this error when an account that has won is trying to transfer his or her last AccessPassNFT
    * during WINNERS_FROZEN in TicketNFT
    * @param account is the address trying to transfer
    * @param currentTimestamp is the current block's timestamp
    * @param requiredTimestamp is the timestamp the block must at least be in
    */
    error TransferringFrozenAccount(address account, uint256 currentTimestamp, uint256 requiredTimestamp);

    /********************** EXTERNAL ********************************/

    /**
    * @notice private mints for people in the whitelist
    * @param verifiedSlot is a signed message by the whitelist signer that presents how many the minter can mint
    */
    function privateMint(VerifiedSlot calldata verifiedSlot) external payable;

    /*
    * @notice public mints for anyone
    */
    function publicMint() external payable;

    /**
    * @notice Randomize the NFT. This requests a random Chainlink value, which causes the tier of each nft id to be known.
    * @dev See https://docs.chain.link/docs/vrf-contracts/#configurations for Chainlink VRF documentation
    * @param subscriptionId The chainlink subscription id that pays for the call to Chainlink, needs to be setup with ChainLink beforehand
    * @param gasLane The maximum gas price you are willing to pay for a Chainlink VRF request in wei
    * @param callbackGasLimit How much gas to use for the callback request. Approximately 29_000 is used up solely by
    * fulfillRandomWords
    */
    function randomizeTiers(
        uint64 subscriptionId,
        bytes32 gasLane,
        uint32 callbackGasLimit
    ) external;

    /**
    * @notice sets the base URI for the token metadata
    * @dev This can only happen once after the generation of the token metadata in unison with the winners function.
    * @param revealedURI must end in a '/' (slash), because the tokenURI expects it to end in a slash.
    */
    function revealTiers(string memory revealedURI) external;

    /**
    * @notice Randomize the tickets. This requests a random Chainlink value, which causes the winners to be known.
    * @dev See https://docs.chain.link/docs/vrf-contracts/#configurations for Chainlink VRF documentation
    * @param subscriptionId The chainlink subscription id that pays for the call to Chainlink, needs to be setup with ChainLink beforehand
    * @param gasLane The maximum gas price you are willing to pay for a Chainlink VRF request in wei
    * @param callbackGasLimit How much gas to use for the callback request. Approximately 31_000 gas is used up
    * solely by fulfillRandomWords.
    */
    function randomizeTickets(
        uint64 subscriptionId,
        bytes32 gasLane,
        uint32 callbackGasLimit
    ) external;

    /**
    * @notice sets the whitelist signer
    * @dev immediately do this after deploying the contract
    * @param whiteListSigner_ is the signer address for verifying the minting slots
    */
    function setWhitelistSigner(address whiteListSigner_) external;

    /**
    * @notice sets the ticketNFT
    * @dev set this before selecting the TicketWinners in TicketNFT
    * @param ticketNFT_ is the TicketNFT that selects the ticketWinners
    */
    function setTicketNFT(TicketNFT ticketNFT_) external;

    /**
    * @notice sets the recipient of the eth from public and private minting and the royalty fees
    * @dev setRoyaltyFee right after setting the treasury
    * @param treasury_ could be an EOA or a gnosis contract that receives eth and royalty fees
    */
    function setTreasury(address payable treasury_) external;

    /**
    * @notice sets the royalty fee for the second hand market selling
    * @param royaltyFee is the fees taken from second-hand selling. This is expressed in a _royaltyFee/10_000.
    * So to do 5% means supplying 500 since 500/10_000 is 5% (see ERC2981 function _setDefaultRoyalty(address receiver, uint96 feeNumerator))
    */
    function setRoyaltyFee(uint96 royaltyFee) external;

    /**
    * @notice sets the price of minting. the amount is sent to the treasury right after the minting
    * @param price_ is expressed in wei
    */
    function setPrice(uint256 price_) external;

    /**
    * @notice sets the contract uri
    * @param contractURI_ points to a json file that follows OpenSeas standard (see https://docs.opensea.io/docs/contract-level-metadata)
    */
    function setContractURI(string memory contractURI_) external;

    /**
    * @notice sets the unrevealedURI
    * @param unrevealedURI_ points to a json file with the placeholder image inside
    */
    function setUnrevealedURI(string memory unrevealedURI_) external;

    /**
    * @notice sets the private minting timestamp
    * @param privateMintingTimestamp_ is when private minting is enabled. Setting this to zero disables all minting
    */
    function setPrivateMintingTimestamp(uint256 privateMintingTimestamp_) external;

    /**
    * @notice sets the public minting timestamp
    * @param publicMintingTimestamp_ is when public minting will be enabled.
    * Setting this to zero disables public minting.
    * If set, public minting must happen after private minting
    */
    function setPublicMintingTimestamp(uint256 publicMintingTimestamp_) external;

    /**
    /* @notice sets how many a minter can public mint
    /* @param maxPublicMintable_ is how many a public account can mint
    */
    function setMaxPublicMintable(uint16 maxPublicMintable_) external;

    /********************** EXTERNAL VIEW ********************************/

    /**
    * @notice returns the count an account has minted
    * @param minter is for the account being queried
    */
    function mintedBy(address minter) external view returns (uint256);

    /**
    * @notice returns the count an account has minted per type
    * @param minter is for the account being queried
    * @param mintingType is the type of minting expected
    */
    function mintedBy(address minter, MintingType mintingType) external view returns (uint256);

    /**
    * @notice Returns the tier for an nft id
    * @param tokenId is the id of the token being queried
    */
    function nftTier(uint256 tokenId) external view returns (uint16 tier);

    /**
    * @notice Returns true if the ticketsRandomWord has been set in the VRF Callback
    * @dev this is used by TicketNFT as a prerequisite for the airdrop. See TicketNFT for more info.
    */
    function ticketsRevealed() external view returns(bool);

    /**
    * @notice Returns an array of all NFT id's, with 500 winners, indicated by 1. The others are indicated by 0.
    */
    function winners() external view returns (uint16[] memory);

    /**
    * @notice returns the current supply of the NFT
    */
    function totalSupply() external view returns (uint256);

    /**
    * @notice returns the current contract status of the NFT
    */
    function contractStatus() external view returns (ContractStatus);

    /**
    * @notice Returns an array with all nft id's and their tier
    * @dev This function works by filling a pool with random values. When we exhaust the pool,
    * we refill the pool again with different values. We do it like this because we don't
    * know in advance how many random values we need.
    */
    function nftTiers() external view returns (uint16[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.8.6;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
* @title Required interface for a TicketNFT compliant contract
* @author Oost & Voort, Inc
*/

interface ITicketNFT is IERC165 {

    /**
    * @dev The following are the stages of the contract in order:
    * PRE_AIRDROP: Before the airdrop has happened
    * TICKETS_REVEALED: when accessPassNFT has already set who the TicketWinners will be
    * AIRDROPPED_TICKETS: when the nfts have been airdropped
    * SET_REGISTRATION: when the _hasNotRegistered have been filled up
    * WINNERS_FROZEN: When the winners have been frozen from doing transfers
    * TRADING_ENABLED: When all trading has been enabled again
    */
    enum ContractStatus {
        PRE_AIRDROP,
        TICKETS_REVEALED,
        AIRDROPPED_TICKETS,
        SET_REGISTRATION,
        WINNERS_FROZEN,
        TRADING_ENABLED
    }

    /**
    * @dev emitted when the owner has changed the contract uri
    * @param oldURI is the uri it was set as before
    * @param newURI is the uri it is now set in
    */
    event ContractURISet(string oldURI, string newURI);

    /**
    * @dev emitted when the owner changes the royalties
    * @param newRoyaltyAddress is the new royalty address that will receive the royalties.
    * @param newRoyalties is the new royalties set by the owner
    */
    event RoyaltiesSet(address newRoyaltyAddress, uint96 newRoyalties);

    /**
    * @dev emitted when the frozenPeriod has been set
    * @param oldTimestamp is the old timestamp for when the frozenPeriod was set
    * @param newTimestamp is the timestamp for when the frozenPeriod will now correspond as
    */
    event FrozenPeriodSet(uint256 oldTimestamp, uint256 newTimestamp);

    /**
    * @dev the following events must be done in order
    */

    /**
    * @dev emitted when the airdrop happens
    * @param winners is the ids of winners from AccessPassNFT. See AccessPassNFT's winners function for more information.
    */
    event TicketsAirdropped(uint16[] winners);

    /**
    * @dev emitted when the registration has been set
    * @param hasRegistered is an array boolean that represents if the onwer of that index has registered off-chain
    */
    event RegistrationSet(bool[] hasRegistered);

    /**
    * @dev emitted when a random number has been requested from VRF
    * @param requestId is the id sent back by VRF to keep track of the request
    */
    event RandomWordRequested(uint256 requestId);

    /**
    * @dev emitted when a ticket winner has been selected
    * @param randomWord is used to determine the TicketWinner
    */
    event TicketWinnersSelected(uint256 randomWord);

    /**
    * @dev emitted when the trading for winners have been frozen
    * @param frozenTimestamp is until when trading for winning nfts have been frozen for
    */
    event TicketWinnersFrozen(uint256 frozenTimestamp);

    /**
    * @dev reverted with this error when the address being supplied is Zero Address
    * @param addressName is for whom the Zero Address is being set for
    */
    error ZeroAddress(string addressName);

    /**
    * @dev reverted with this error when a view function is being used to look for a nonExistent Token
    */
    error NonExistentToken();

    /**
    * @dev reverted with this error when a function is being called more than once
    */
    error CallingMoreThanOnce();

    /**
    * @dev reverted with this error when a variable has an incorrect value
    * @param variableName is the name of the variable with an incorrect value
    */
    error IncorrectValue(string variableName);

    /**
    * @dev reverted with this error when a string being supplied should not be empty
    * @param stringName is the name of the string being supplied with an empty value
    */
    error EmptyString(string stringName);

    /**
    * @dev reverted with this error when a function being called should not be called with the current Contract Status
    * @param currentStatus is the contract's current status
    * @param requiredStatus is the status the current must be in for the function to not revert
    */
    error IncorrectContractStatus(ContractStatus currentStatus, ContractStatus requiredStatus);

    /**
    * @dev reverted with this error when transferring a winningId during frozenPeriod
    * @param tokenId is the id being transferred
    * @param currentTimestamp is the current block's timestamp
    * @param requiredTimestamp is the timestamp the block must at least be in
    */
    error TransferringFrozenToken(uint256 tokenId, uint256 currentTimestamp, uint256 requiredTimestamp);

    /**
    * @notice airdrops to accessPassNFT winners
    * @param winners are accessPassNFT winners taken off-chain
    */
    function airdrop(
        uint16[] calldata winners
    ) external;

    /**
    * @notice requests a random word from VRF to be used for selecting a ticket winner
    * @dev See https://docs.chain.link/docs/vrf-contracts/#configurations for Chainlink VRF documentation
    * @param subscriptionId The chainlink subscription id that pays for the call to Chainlink, needs to be setup with ChainLink beforehand
    * @param gasLane The maximum gas price you are willing to pay for a Chainlink VRF request in wei
    * @param callbackGasLimit How much gas to use for the callback request. Approximately 139_000 gas is used up solely
    * by fulfillRandomWords.
    */
    function requestRandomWord(
        uint64 subscriptionId,
        bytes32 gasLane,
        uint32 callbackGasLimit
    ) external;

    /**
    * @notice sets the contract uri
    * @param uri points to a json file that follows OpenSeas standard (see https://docs.opensea.io/docs/contract-level-metadata)
    */
    function setContractURI(string memory uri) external;

    /**
    * @notice sets the royalty fee for the second hand market selling
    * @param royaltyAddress is the recepient of royalty fees from second hand market.
    * @param royaltyFee is the fees taken from second-hand selling. This is expressed in a _royaltyFee/1000.
    * So to do 5% means supplying 50 since 50/1000 is 5% (see ERC2981 function _setDefaultRoyalty(address receiver, uint96 feeNumerator))
    */
    function setDefaultRoyalty(address royaltyAddress, uint96 royaltyFee) external;

    /**
    * @notice sets the ids of the people who have not registered
    * @dev It is important to do this before requesting a random word. To make it cheaper gas-wise, sending an empty
    * array signifies that all token owners registered off-chain. An explanation of what the array of hasRegistered looks
    * like will follow:
    * if the owner of token id 0 has registered in the array it will show as true,
    * so [true, ...]
    * if the owner of token id 1 has not registered in the array it will show as false
    * so [true, false, ...]
    * and so on..
    * @param hasRegistered_ is an array of boolean that tells if the owner of the id has registered off-chain
    */
    function setRegistered(bool[] calldata hasRegistered_) external;

    /**
    * @notice sets the frozenPeriod for when trading winning token ids is disabled
    * @param frozenPeriod_ is a timestamp for when the ticket winners can start trading again
    */
    function setFrozenPeriod(uint256 frozenPeriod_) external;


    /**
    * @notice returns if the token id has registered or not
    * @param tokenId is the id of the token being queried
    */
    function hasRegistered(
        uint16 tokenId
    ) external view returns (bool);

    /**
    * @notice Returns if the address owns a winning nft
    * @param account is the queried address
    */
    function isAccountWinner(address account) external view returns (bool);

    /**
    * @notice returns the current contract status of the NFT
    */
    function contractStatus() external view returns (ContractStatus);

    /**
    * @notice returns the current supply of the NFT
    */
    function totalSupply() external view returns (uint256);
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IVerifiedSlot {
    struct VerifiedSlot {
        address minter;
        uint16 mintingCapacity;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
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
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
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
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
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
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
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
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
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
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
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

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
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

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
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
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
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
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
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
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
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

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/common/ERC2981.sol)

pragma solidity ^0.8.0;

import "../../interfaces/IERC2981.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the NFT Royalty Standard, a standardized way to retrieve royalty payment information.
 *
 * Royalty information can be specified globally for all token ids via {_setDefaultRoyalty}, and/or individually for
 * specific token ids via {_setTokenRoyalty}. The latter takes precedence over the first.
 *
 * Royalty is specified as a fraction of sale price. {_feeDenominator} is overridable but defaults to 10000, meaning the
 * fee is specified in basis points by default.
 *
 * IMPORTANT: ERC-2981 only specifies a way to signal royalty information and does not enforce its payment. See
 * https://eips.ethereum.org/EIPS/eip-2981#optional-royalty-payments[Rationale] in the EIP. Marketplaces are expected to
 * voluntarily pay royalties together with sales, but note that this standard is not yet widely supported.
 *
 * _Available since v4.5._
 */
abstract contract ERC2981 is IERC2981, ERC165 {
    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    RoyaltyInfo private _defaultRoyaltyInfo;
    mapping(uint256 => RoyaltyInfo) private _tokenRoyaltyInfo;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc IERC2981
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) public view virtual override returns (address, uint256) {
        RoyaltyInfo memory royalty = _tokenRoyaltyInfo[_tokenId];

        if (royalty.receiver == address(0)) {
            royalty = _defaultRoyaltyInfo;
        }

        uint256 royaltyAmount = (_salePrice * royalty.royaltyFraction) / _feeDenominator();

        return (royalty.receiver, royaltyAmount);
    }

    /**
     * @dev The denominator with which to interpret the fee set in {_setTokenRoyalty} and {_setDefaultRoyalty} as a
     * fraction of the sale price. Defaults to 10000 so fees are expressed in basis points, but may be customized by an
     * override.
     */
    function _feeDenominator() internal pure virtual returns (uint96) {
        return 10000;
    }

    /**
     * @dev Sets the royalty information that all ids in this contract will default to.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setDefaultRoyalty(address receiver, uint96 feeNumerator) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: invalid receiver");

        _defaultRoyaltyInfo = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Removes default royalty information.
     */
    function _deleteDefaultRoyalty() internal virtual {
        delete _defaultRoyaltyInfo;
    }

    /**
     * @dev Sets the royalty information for a specific token id, overriding the global default.
     *
     * Requirements:
     *
     * - `tokenId` must be already minted.
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: Invalid parameters");

        _tokenRoyaltyInfo[tokenId] = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Resets royalty information for the token id back to the global default.
     */
    function _resetTokenRoyalty(uint256 tokenId) internal virtual {
        delete _tokenRoyaltyInfo[tokenId];
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
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
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}