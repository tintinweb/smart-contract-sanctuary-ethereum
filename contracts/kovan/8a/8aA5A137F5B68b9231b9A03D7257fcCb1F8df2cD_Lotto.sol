//SPDX-License-Identifier: None
pragma solidity ^0.8.10;
import "./Ownable.sol";
import "./Randomizer.sol";
import "./PaymentSplitter.sol";
import "./MerkleProof.sol";

error ExceedsSupplyLimit();
error WhitelistTicketAlreadyClaimed();
error InsufficientPayment();
error InvalidProof();
error LotteryEnded();
error RandomNumberNotYetReceived();
error PublicSaleNotStarted();
error TicketSupplyRemaining();
error OwnerQueryForNonexistentTicket();
// Decentralized, fair (very unlikely that a single authority controls the list of addresses added for randomization)
contract Lotto is Randomizer, PaymentSplitter{

    event LotteryConfigUpdated();
    event WinningTicket(uint256 winningTicketNumber);
    event TicketsBought(address buyer, uint256 numberOfTickets);
    event TicketClaimed(address buyer);

    struct LotteryConfig {
        uint256 startTime;
        uint256 supplyLimit;
        uint256 ticketFee;
    }

    LotteryConfig public lotteryConfig;

    uint256 public currentId;
    uint256 public winningTicketNumber;
    uint256 immutable public NUMBER_OF_TICKETS_TO_AIRDROP = 900;
    uint256 public numberOfTicketsAirdropped;

    mapping (uint256 => address) private ticketOwner;
    mapping (address => bool) public whitelistClaimed;

    bool public lotteryEnded;

    // bytes32 public merkleRoot = "";

    //TODO change visibilty?
    address[] public lotteryPayees = [
        0x165CD37b4C644C2921454429E7F9358d18A45e14, // Ukraine Donation
        // Winner will be added after lottery ends
        0x2d516D8965BC0C37789471c8FFCC5BbBE0457eBC  // Liquidity for tokens to be released / Dev
    ];

    /* Ukraine donation will get majority shares */
    uint256[] public lotteryShares = [625, 250]; // Winner has been reserved share of 125, this will be set after the winner is selected

    constructor() Randomizer() PaymentSplitter(lotteryPayees, lotteryShares)
    {
        lotteryConfig = LotteryConfig({
        startTime: 1646449599, // Timestamp will be accomodated, initially set to May 01, 8pm EST
        ticketFee: 0.0000088 ether,
        supplyLimit: 10000
        });

    }

    function ownerOf(uint256 ticketNumber) public view returns(address){
        uint256 curr = ticketNumber;

        unchecked{
            if(curr <= currentId && curr > 0) {
                while(true){
                    if(ticketOwner[curr] != address(0)){
                        return ticketOwner[curr];
                    }
                    curr--;
                }
            }
        }
        revert OwnerQueryForNonexistentTicket();
    }

    // /**
    // // @notice Set Whitelist Merkle Tree root hash
    // // @dev Used to verify the whitelist addresses and their limits
    // // @param newMerkleRoot : The new merkle root hash
    // */
    // function setMerkleRoot(bytes32 newMerkleRoot) external onlyOwner{
    //     merkleRoot = newMerkleRoot;
    // }

    // Buy a lottery ticket
    // Buying multiple tickets costs essentially the same amount of gas with this approach
    function buyTicket(uint256 numberOfTickets) external payable {

        LotteryConfig memory _config = lotteryConfig;
        if(block.timestamp < _config.startTime) revert PublicSaleNotStarted();
        if(currentId + numberOfTickets > _config.supplyLimit) revert ExceedsSupplyLimit();
        if( msg.value < numberOfTickets*_config.ticketFee ) revert InsufficientPayment();
        if((_config.supplyLimit - currentId - numberOfTickets) < (NUMBER_OF_TICKETS_TO_AIRDROP - numberOfTicketsAirdropped)) revert("Remaining reserved for airdrop");

        /* Ticket Id starts with 1 (+1) */
        ticketOwner[currentId+1] = msg.sender;

        /* The next number of tickets will be mapped to the msg.sender */
        currentId += numberOfTickets;

        emit TicketsBought(msg.sender, numberOfTickets);
    }

    function airdropTickets(address[] memory to) external onlyOwner {
        if(to.length <= 0) revert("Minimum one entry");
        if((currentId + to.length) > lotteryConfig.supplyLimit) revert("Exceeds max supply limit");
        if(numberOfTicketsAirdropped + to.length > NUMBER_OF_TICKETS_TO_AIRDROP) revert ("Max limit of airdopped tickets reached");

        uint256 i;    
        uint256 newId = currentId;

        for(i = 0; i < to.length; i++){
            newId++;
            ticketOwner[newId] = to[i];
        }
        numberOfTicketsAirdropped = newId - currentId;
        currentId = newId;
    }

    // // Whitelisted users can claim their free ticket here
    // function claimWhitelistTicket(bytes32[] calldata merkleProof) external {

    //     if(whitelistClaimed[msg.sender]) revert WhitelistTicketAlreadyClaimed();
    //     if(currentId + 1 > lotteryConfig.supplyLimit) revert ExceedsSupplyLimit();

    //     bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    //     if(!MerkleProof.verify(merkleProof, merkleRoot, leaf)) revert InvalidProof();

    //     /* Ticket Id starts with 1 (+1) */
    //     currentId++;

    //     /* Each whitelisted address can claim only 1 free ticket */
    //     whitelistClaimed[msg.sender] = true;

    //     ticketOwner[currentId] = msg.sender;

    //     emit TicketClaimed(msg.sender);

    // }

    // Calls the Chainlink oracle network to generate a verifiable random number
    function rollRandomWinner() external {
        if(currentId < lotteryConfig.supplyLimit) revert TicketSupplyRemaining();
        randomWinner();
    }

    // To be called a few mins after calling rollRandomWinner(), taken for receiving the provable random number from oracle
    function claimWinner() external {

        if(lotteryEnded) revert LotteryEnded();

        if(randomResult[0] == 0) revert RandomNumberNotYetReceived();

        uint256 totalTicketSupply = lotteryConfig.supplyLimit;
        //TODO uncomment
        if(currentId < totalTicketSupply) revert TicketSupplyRemaining();

        lotteryEnded = true;

        /* This is the winning ticket number */
        uint256 randomWinner = uint256(keccak256(abi.encode(randomResult[0])));
        randomWinner = ( randomWinner % totalTicketSupply ) + 1;

        /* Congratss!! */
        winningTicketNumber = randomWinner;
        emit WinningTicket(randomWinner);

        /* Adding the share of prize to the winner */
        _addPayee(ownerOf(randomWinner), 125);
        isWinnerSet = true;
    }

    /// @notice Allows the contract owner to update start time for the lottery
    function configureLotteryStartTime(uint256 _startTime)
        external
        onlyOwner
    {
        require(_startTime > 0, "Invalid start time");

        lotteryConfig.startTime = _startTime;

        emit LotteryConfigUpdated();
    }

    /// @notice Allows the contract owner to update the ticket fee
    function configureLotteryFee(uint256 _fee)
        external
        onlyOwner
    {
        lotteryConfig.ticketFee = _fee;

        emit LotteryConfigUpdated();
    }
}