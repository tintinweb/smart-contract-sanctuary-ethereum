// SPDX-License-Identifier: Unlicensed 

pragma solidity ^0.8.6;

import "./ERC721A.sol";
import "./AccessControl.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ECDSA.sol";

contract OGTex is ERC721A, Ownable, ReentrancyGuard {
    using ECDSA for bytes32;

    /**
     * @dev CONTRACT STATES
     */
    enum State {
        Setup,
        Presale,
        Public,
        Closed
    }
    State private state;

    /**
     * @dev METADATA
     */
    string private baseURIString;

    /**
     * @dev MINT DETAILS
     */
    uint256 public immutable MAX_OGREX = 7777;
    uint256 public immutable RESERVED_OGREX = 807;
    uint256 public constant MAX_BATCH = 100;
    uint256 public immutable MAX_MINT = 5;
    uint256 public OGREX_PRICE = 0.10 ether;
    address private recipientWallet;
    uint256 private amountReserved;
    bool private reservedMinted;

    /**
     * @dev PRESALE TRACKING
     */
    uint256 public immutable MAX_PRESALE_MINT = 2;
    address private endorser;
    mapping(bytes => bool) public usedKey;
    mapping(address => bool) public presaleMinted;
    mapping(address => uint256) public walletPresaleTotalMinted;

    /**
     * @dev EVENTS
     */
    event ReserveMinted(
        address receiver,
        uint256 fromTokenId,
        uint256 toTokenId,
        uint256 amount,
        bool reserveMinted
    );
    event Minted(
        address minter,
        uint256 fromTokenId,
        uint256 toTokenId,
        uint256 amount
    );
    event OGRexDetailsChanged(
        uint256 indexed tokenId,
        string name,
        string description
    );
    event BalanceWithdrawn(address receiver, uint256 value);

    constructor() ERC721A("JPunks: OG-Rex", "OGREX", MAX_BATCH) {
        state = State.Setup;
        baseURIString = "https://gateway.pinata.cloud/ipfs/QmXmsHbeMdddgmqUtgtUfb4FzcqbZMik7kGXmbkLLokTKv";
        recipientWallet = address(0x059E8918969a7FDE4921a1889a357C397D461593);
        endorser = address(0x059E8918969a7FDE4921a1889a357C397D461593);
    }

    /**
     * @notice Check token URI for given tokenId
     * @param tokenId OG Rex token ID
     * @return API endpoint for token metadata
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721A)
        returns (string memory)
    {
        return
            string(abi.encodePacked(baseTokenURI(), Strings.toString(tokenId)));
    }

    /**
     * @notice Check the token URI
     * @return Base API endpoint for token metadata URI
     */
    function baseTokenURI() public view virtual returns (string memory) {
        return baseURIString;
    }

    /**
     * @notice Update the token URI for the contract
     * @param tokenUriBase_ New metadata endpoint to set for contract
     */
    function setTokenURI(string memory tokenUriBase_) public onlyOwner {
        baseURIString = tokenUriBase_;
    }
    
    /**
     * @notice Set a new receiving wallet address for ETH
     * @param newRecipient A new receipient wallet address
     */
    function setRecipientWallet(address newRecipient) public onlyOwner {
        recipientWallet = newRecipient;
    }

    /**
     * @notice Set a new signing wallet address for presale
     * @param newEndorser A new endorser wallet address
     */
    function setEndorser(address newEndorser) public onlyOwner {
        endorser = newEndorser;
    }

    /**
     * @notice Check current contract state
     * @return Current contract state
     */
    function contractState() public view virtual returns (State) {
        return state;
    }

    /**
     * @notice Set contract state to Setup
     */
    function setStateToSetup() public onlyOwner {
        state = State.Setup;
    }

    /**
     * @notice Set contract state to Presale
     */
    function setStateToPresale() public onlyOwner {
        state = State.Presale;
    }

    /**
     * @notice Set contract state to Public sale
     */
    function setStateToPublic() public onlyOwner {
        state = State.Public;
    }

    /**
     * @notice Set contract state to Closed
     */
    function setStateToClosed() public onlyOwner {
        state = State.Closed;
    }

    /**
     * @notice Only Owner function to mint reserved OG Rex
     * @param reserveAddress Address which reserved OG Rex will be minted to
     * @param amountToReserve Amount of reserved OG Rex to be minted
     */
    function mintReserve(address reserveAddress, uint256 amountToReserve)
        public
        onlyOwner
    {
        require(!reservedMinted, "Reserve minting has already been completed");
        require(
            amountReserved + amountToReserve <= RESERVED_OGREX,
            "Reserving too many OG Rex"
        );
        _safeMint(reserveAddress, amountToReserve);
        amountReserved = amountReserved + amountToReserve;
        if (amountReserved == RESERVED_OGREX) {
            reservedMinted = true;
        }
        uint256 firstOGRexReceived = totalSupply() - amountToReserve;
        uint256 lastOGRexReceived = totalSupply() - 1;
        emit ReserveMinted(
            reserveAddress,
            firstOGRexReceived,
            lastOGRexReceived,
            amountToReserve,
            reservedMinted
        );
    }

    /**
     * @notice Presale mint function
     * @param popToken Randomly generated token for authorization to presale mint
     * @param key Marker for usage of randomly generated key
     * @param amountOfOGRex Amount of OG Rex to be minted
     */
    function mintPresaleOGRex(string calldata popToken, bytes calldata key, uint256 amountOfOGRex)
        external
        payable
        nonReentrant
    {
        require(state == State.Presale, "Presale is not active.");
        require(
            !Address.isContract(msg.sender),
            "You cannot mint from a contract."
        );
        require(
            !presaleMinted[msg.sender],
            "This wallet has minted its max presale allocation."
        );
        require(
            walletPresaleTotalMinted[msg.sender] + amountOfOGRex <= MAX_PRESALE_MINT,
            "This wallet cannot mint that many in presale."
        );
        require(
            totalSupply() + amountOfOGRex <= MAX_OGREX,
            "Maximum supply of tokens exceeded."
        );
        require(msg.value >= OGREX_PRICE * amountOfOGRex, "Ether value sent is incorrect.");
        require(verifyEndorser(hashHexAddress(popToken, msg.sender), key), "Invalid key.");
        _safeMint(msg.sender, amountOfOGRex);
        forwardEth(recipientWallet);
        walletPresaleTotalMinted[msg.sender] = walletPresaleTotalMinted[msg.sender] + amountOfOGRex;
        uint256 firstOGRexReceived = totalSupply() - amountOfOGRex;
        uint256 lastOGRexReceived = totalSupply() - 1;
        if (walletPresaleTotalMinted[msg.sender] == MAX_PRESALE_MINT) {
            presaleMinted[msg.sender] = true;
        }
        emit Minted(
            msg.sender,
            firstOGRexReceived,
            lastOGRexReceived,
            amountOfOGRex
        );
    }

    /**
     * @notice Public mint function
     * @param amountOfOGRex Amount of OG Rex to be minted
     */
    function mintOGRex(uint256 amountOfOGRex)
        public
        payable
        virtual
        nonReentrant
    {
        address recipient = msg.sender;
        require(state == State.Public, "JPunks: OG Rex aren't available yet");
        require(
            totalSupply() + amountOfOGRex <= MAX_OGREX,
            "Sorry, there is not that many OG Rex left."
        );
        require(
            amountOfOGRex <= MAX_MINT,
            "You can only mint 5 OG Rex at a time."
        );
        require(
            msg.value >= OGREX_PRICE * amountOfOGRex,
            "You must send the proper value per OG Rex."
        );

        _safeMint(recipient, amountOfOGRex);
        forwardEth(recipientWallet);
        uint256 firstOGRexReceived = totalSupply() - amountOfOGRex;
        uint256 lastOGRexReceived = totalSupply() - 1;
        emit Minted(
            msg.sender,
            firstOGRexReceived,
            lastOGRexReceived,
            amountOfOGRex
        );
    }

    /**
     * @notice Function to change the name and description on an OG Rex
     * @param tokenId Token to update details
     * @param newName New name for token
     * @param newDescription New description for token
     */
    function changeOGRexDetails(
        uint256 tokenId,
        string memory newName,
        string memory newDescription
    ) public {
        address owner = ownerOf(tokenId);
        require(msg.sender == owner, "This isn't your OG Rex");
        emit OGRexDetailsChanged(tokenId, newName, newDescription);
    }

    /**
     * @notice Only Owner Function to change OGREX_PRICE
     * @param newPrice The new price to set on contract
     */
    function setMintPricing(uint256 newPrice) public onlyOwner {
        OGREX_PRICE = newPrice;
    }

    /**
     * @notice Function to forward ETH directly to wallet on minting
     * @param to Address to forward ETH to
     */
    function forwardEth(address to) public payable {
        (bool sent, bytes memory data) = to.call{value: msg.value}("");
        require(sent, "Failed to send Ether");
    }

    /**
     * @notice Only Owner Function to withdraw ETH from contract
     * @param receiver Address to withdraw ETH to
     */
    function withdrawAllEth(address receiver) public virtual onlyOwner {
        uint256 balance = address(this).balance;
        payable(receiver).transfer(balance);
        emit BalanceWithdrawn(receiver, balance);
    }

    /**
     * @notice Function that creates hash from popToken and msgSender
     * @param popToken A random hex generated from signature
     * @param msgSender The wallet address of the message sender
     */
    function hashHexAddress(string calldata popToken, address msgSender)
        public
        view
        returns (bytes32)
    {
        return keccak256(abi.encode(popToken, address(this), msgSender));
    }

    /**
     * @notice Function that verifies hash with endorser
     * @param hash A hash generated using keccak256
     * @param key Marker for usage of a hash
     */
    function verifyEndorser(bytes32 hash, bytes memory key)
        public
        view
        returns (bool)
    {
        return (recoverEndorser(hash, key) == endorser);
    }

    /**
     * @notice Function that recovers signed message from hash using key
     * @param hash A hash generated using keccak256
     * @param key Marker for usage of a hash
     */
    function recoverEndorser(bytes32 hash, bytes memory key)
        public
        pure
        returns (address)
    {
        return hash.toEthSignedMessageHash().recover(key);
    }
}