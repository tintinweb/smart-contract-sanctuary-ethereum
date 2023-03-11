// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

interface DiamondHands {
    function getNicknameByAddress(address _player) external view returns (string memory);
}

interface ERC1155 {
    function balanceOf(address owner, uint256 id) external view returns (uint);
}

contract Tournament  is Ownable {

    uint256 public activeTournament;
    mapping(address => uint256) private latestPayment;
    address public diamondHands;
    address public wolf2dContractAddress;


    struct TournamentDetails
    {   string name;   
        uint256 startDate;
        uint256 endDate;
        uint256 fee;
        bool nftpass;
        uint256 tokenId;
        address[] usersAddress;
        mapping(address => string) scores;
    }

    // Mapping to store the tournaments
    mapping (uint256 => TournamentDetails) public tournaments;

    event TournamentCreated(uint256 tournamentId, uint256 startDate, uint256 endDate, uint256 fee, bool nftpass, uint256 _tokenId);
    event PayTournament (address sender , uint256 currentTime ,  uint256 fee);

    function isActive() public view returns (bool) 
    {
        // Get the tournament details for the given ID
        TournamentDetails storage tournament = tournaments[activeTournament];

        // Check if the current time is between the start and end dates
        uint256 currentTime = block.timestamp;
        return tournament.startDate <= currentTime && currentTime <= tournament.endDate;
    }

    // Function pay 
    function deposit() public payable returns(bool) {
        if (tournaments[activeTournament].nftpass)
        {
            require(0<ERC1155(wolf2dContractAddress).balanceOf(msg.sender, tournaments[activeTournament].tokenId));
        }
        require(msg.value == tournaments[activeTournament].fee, "Deposit amount is wrong"); // ensure the deposit amount is correct
        latestPayment[msg.sender] = block.timestamp;
        emit PayTournament (msg.sender , block.timestamp ,  tournaments[activeTournament].fee );
        return true;
    }

    // Function to retrieve the last PayTournament event for a specific sender
    function getLastPayment(address _sender) public view returns (uint256 currentTime) 
    {
        return (latestPayment[_sender]);
    }

    
    function addScoreT(string memory _encryptedScore) public {
        require(isActive(),"Out of Time");
         TournamentDetails storage tournament = tournaments[activeTournament];
         if (tournaments[activeTournament].nftpass)
            require(hasNFT(msg.sender),"Need NFT PASS");
        if(bytes(tournament.scores[msg.sender]).length <= 0){
            tournament.usersAddress.push(msg.sender);
        }
        tournament.scores[msg.sender] = _encryptedScore;
    }

    function getAllScores() public view returns (string[] memory)
    {
        TournamentDetails storage tournament = tournaments[activeTournament];
        
        string[] memory allScores = new string[](tournament.usersAddress.length);
        for (uint i = 0; i < tournament.usersAddress.length; i++) {
            allScores[i] = tournament.scores[tournament.usersAddress[i]];
        }
        return allScores;
    }

    function getAllUsers() public view returns (address[] memory) {
        TournamentDetails storage tournament = tournaments[activeTournament];
        return tournament.usersAddress;
    }

    function getAllUsernames() public view returns (string[] memory) {
         TournamentDetails storage tournament = tournaments[activeTournament];
        string[] memory allusernames = new string[](tournament.usersAddress.length);
        for (uint i = 0; i < tournament.usersAddress.length; i++) {
            allusernames[i] = DiamondHands(diamondHands).getNicknameByAddress(tournament.usersAddress[i]);
        }
        return allusernames;
    }

    function getScore(address _player) public view returns (string memory) {
        TournamentDetails storage tournament = tournaments[activeTournament];
        return tournament.scores[_player];
    }

    function getTournamentCost() public view returns (uint256){
        TournamentDetails storage tournament = tournaments[activeTournament];
        return tournament.fee;
    }

     function getTournamentName() public view returns (string memory){
        TournamentDetails storage tournament = tournaments[activeTournament];
        return tournament.name;
    }

      function getTournamentStartDate() public view returns (uint256){
        TournamentDetails storage tournament = tournaments[activeTournament];
        return tournament.startDate;
    }

          function getTournamentEndDate() public view returns (uint256){
        TournamentDetails storage tournament = tournaments[activeTournament];
        return tournament.endDate;
    }

    function getRemainingTime() public view returns (uint256) {
        TournamentDetails storage tournament = tournaments[activeTournament];
        uint256 remainingTime = 0;
        if (block.timestamp < tournament.endDate)
        {
         remainingTime = tournament.endDate - block.timestamp;
        }
        return remainingTime;
    }

    function hasNFT( address user) public view returns (bool) {
    // Get a reference to the NFT contract
    TournamentDetails storage tournament = tournaments[activeTournament];
    ERC1155 nftContract = ERC1155(wolf2dContractAddress);

    // Get the balance of the NFT for the user
    uint balance = nftContract.balanceOf(user, tournament.tokenId);

    // Return true if the balance is greater than zero, false otherwise
    return balance > 0;
    }

    // Administrator

    function createTournament(string memory _name,uint256 _startDate, uint256 _endDate, uint256 _fee, bool _nftpass, uint256 _tokenId) public onlyOwner
    {
        // Generate a unique ID for the tournament
        uint256 tournamentId = uint256(keccak256(abi.encodePacked(_startDate)));
        activeTournament = tournamentId;
        // Update the tournament details in the mapping
        tournaments[tournamentId].name = _name;
        tournaments[tournamentId].startDate = _startDate;
        tournaments[tournamentId].endDate = _endDate;
        tournaments[tournamentId].fee = _fee;
        tournaments[tournamentId].nftpass = _nftpass;
        tournaments[tournamentId].tokenId = _tokenId;

        // Emit the event to notify the tournament creation
        emit TournamentCreated(tournamentId, _startDate, _endDate, _fee,  _nftpass,_tokenId);

    }

    function withdraw() public onlyOwner
    {
        payable(owner()).transfer(address(this).balance);
    }

    function setDiamondHabdsContract(address _diamondHands) public onlyOwner 
    {
        diamondHands = _diamondHands;
    }

    function setnftContractAddress(address address2dWolf) public onlyOwner {
        wolf2dContractAddress = address2dWolf;
    }
    
}

struct Payment {
    address sender;
    uint256 currentTime;
    uint256 fee;
}