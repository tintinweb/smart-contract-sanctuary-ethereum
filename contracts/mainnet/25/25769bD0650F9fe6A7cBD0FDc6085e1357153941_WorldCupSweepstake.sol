// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./WCMinting.sol";

/**
* @dev The main outer contract that we deploy
**/
contract WorldCupSweepstake is WorldCupSweepstakeMinting {

    /**
     * @dev Builds a metadata URI of the form baseuri/teamid
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        string memory teamId = teamFromTokenId(tokenId).teamId;
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, teamId))
                : "";
    }

    /**
     * @dev Hardcodes the ipfs base URI for tokens
     * NOTE: overrides openzepplin ERC721 contract
     */
    function _baseURI() internal pure override returns (string memory) {
        return
            "https://gateway.pinata.cloud/ipfs/QmU7EDeqv33VySjesK8Ye7bfEepKBsZVd14dreFiGTwyeT/";
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import './StageEnum.sol';

struct TeamNFT{
    string teamId;
    TournamentStageEnum stage; //the stage that this team is currently at
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

enum TournamentStageEnum {GroupStage, Last16, QuaterFinal, SemiFinal, Final, Champion}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./WCCompetition.sol";
import "./library/TeamNFTStruct.sol";
import "./library/StageEnum.sol";

/**
* @dev   WorldCupSweepstakeMinting is concerned with
*        - Minting at time of purchase
*        - Randomised World Cup Sweepstake
**/
contract WorldCupSweepstakeMinting is WorldCupSweepstakeCompetition {
    //TODO: via deployment constructor or something more configurable?
    uint256 public INITIAL_SALE_PRICE = 0.012 * 1e18; //ETH

    constructor() {}

    //Modifiers

    /**
    * @dev Used to ensure againt common mistakes
    *      https://consensys.github.io/smart-contract-best-practices/development-recommendations/token-specific/contract-address/
    *      Zero address is somewhat irrelevant as it is checked
    *      in inherited openzepplin contract for mint
    */
    modifier validDestination( address to ) {
        require(to != address(0x0));
        require(to != address(this) );
        _;
    }

    //Public / External methods

    /**
    * @dev   Buy and Mint next NFT
    **/
    function buyNextTeam(uint256 price, address to) validDestination(to) external payable {

        //Ensure the sender sent the amount of ETH they meant to send
        require(msg.value == price, "The amount sent does not match value");

        //Check price is equal to what we are selling at
        require(INITIAL_SALE_PRICE == price, "Please submit asking price");

        //Address to is sender - help limit user making a mistake
        require(msg.sender == to, "Only sender can own");

        //Fetch next team to be minted
        string memory teamId = _fetchNextTeam();

        //Mint the team to be owned by to address
        _mintTeam(to, teamId);
    }

    //Internal / Private methods
    
    /**
    * @dev   private function to decide which team
    *        should be next
    **/
    function _fetchNextTeam() private view returns (string memory) {
        // fetch all teamIds which are available for minting
        string[] memory unmintedTeams = _fetchUnmintedTeams();

        //revert if nothing left to mint
        if (unmintedTeams.length == 0) {
            revert("No more teams available");
        }

        // generate a random number and pick a team
        uint256 randomTeamIndex = _randomise(
            "A_RANDOM_SEED_HERE?!?!?",
            unmintedTeams.length
        );
        string memory teamId = unmintedTeams[randomTeamIndex];

        // return that team
        return teamId;
    }

    /**
     * @dev Generates a random number within the range specified
     * NOTE :  it would be MUCH better to get this from a random number oracle e.g. Chainlink but
     * for now we're just using the timestamp to randomise
     **/
    function _randomise(string memory seed, uint256 range)
        private
        view
        returns (uint256)
    {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        seed,
                        block.difficulty,
                        block.timestamp,
                        block.number
                    )
                )
            ) % range;
    }

    /**
     * @dev Generates array of unminted teams
     *      to facilitate minting next team  
     **/
    function _fetchUnmintedTeams() private view returns (string[] memory) {
        // build array to hold unminted teams
        uint256 totalAvailableSupply = _teamIds.length;
        uint256 length = totalAvailableSupply - totalSupply();
        string[] memory teams = new string[](length);
        uint256 currentIndex = 0;

        // loop through all available teams
        for (uint256 i = 0; i < _teamIds.length; i++) {
            // does the team already exist?
            if (!teamExists(_teamIds[i])) {
                // this team isn't minted yet
                teams[currentIndex] = _teamIds[i];
                currentIndex++;
            }
        }

        return teams;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;



import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
* @dev   Generated using openzepplin wizard... https://docs.openzeppelin.com/contracts/4.x/wizard
*        at the time of writing it is envisaged that this file
*        will be replaced as additional functionality is required
*  NOTE: 
*    ERC721  - required to implement standard ERC721 tokens
*    ERC721Enumerable
*            - useful for keeping track of token supply and who
*              owns which tokens
*    Ownable - required for OpenSea to determine who the contract/collection owner is.. 
*              not required for this project but also to potentially transfer ownership etc.
**/
abstract contract WorldCupSweepstakeERC721 is ERC721, ERC721Enumerable, Ownable {
    

    constructor(string memory name_, string memory symbol_) ERC721(name_,symbol_) {}
    
    
    /**
     * @dev overrides required by Solidity due to multiple inheritance
     **/
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        //Will be using ERC721Enumerable implementation
        //as that is the right most Parent in inheritance
        //https://solidity-by-example.org/inheritance/#:~:text=Solidity%20supports%20multiple%20inheritance.,must%20use%20the%20keyword%20override%20.
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev allows other contracts and utilities like opensea
     *      write code to determine how it can interact with
     *      our contract based on whiche interfaces we are implementing
     **/
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./WCBase.sol";
import "./library/TeamNFTStruct.sol";
import "./library/StageEnum.sol";
import "./Payable.sol";
import "@openzeppelin/contracts/security/PullPayment.sol";

/**
* @dev WorldCupSweepstakeCompetition Contract implements the logic for
        1. progressing the competition tournament
        2. calculating the prize amount depending on the tournament stage (it's possible this should be split out as it gets more complicated)
        3. distribute to winning nft owners
  NOTE: 
    PullPayment - allows Winners to claim their winnings from the Escrow account (OpenZepplin)
    Payable  - allows method for checking prize pot via contract balance
               we could also fund the contract if we wanted to increase the prize pot.
**/
abstract contract WorldCupSweepstakeCompetition is
    WorldCupSweepstakeBase,
    Payable,
    PullPayment
{
    //Events
    event PrizeWin(
        address indexed _from,
        address _owner,
        string _teamId,
        TournamentStageEnum _stage,
        uint256 _prize
    );

    //Modifiers

    /**
     * @dev Modifier to test tournament progression is valid
     *      reverts if attempting to skip or duplicate stages
     **/
    modifier tournamentProgressValid(TournamentStageEnum stage){
        //Offers protection against accidently duplicating
        //tournament stage and paying out multiple times.
        require(
            stage > tournamentStage,
            "Tournament stage must progress. Either you are attempting to progress back or this is a duplicate call"
        );

        //Tournament stage should not be skipped
        require(uint(stage) == uint(tournamentStage) + 1,
            "Tournament stage must not skip a stage."
        );

        //We haven't reverted so far... so carry on...
        _;
    }

    /**
     * @dev Modifier to test tournament teams provided is valid
     *      See comment in code to see this has limited use
     **/
    modifier tournamentTeamsValid(TournamentStageEnum stage, string[] calldata teamIds){
      
      require(teamIds.length > 0, 'no teams provided');

      uint16 expectedTeams = 0;
      if(stage == TournamentStageEnum.GroupStage){
        expectedTeams = 32;
      }
      else if(stage == TournamentStageEnum.Last16){
        expectedTeams = 16;
      }
      else if(stage == TournamentStageEnum.QuaterFinal){
        expectedTeams = 8;
      }
      else if(stage == TournamentStageEnum.SemiFinal){
        expectedTeams = 4;
      }
      else if(stage == TournamentStageEnum.Final){
        expectedTeams = 2;
      }
      else if(stage == TournamentStageEnum.Champion){
        expectedTeams = 1;
      }
      else{
        revert("Unhandled stage");
      }
      
      //LIMITATION:
      //We cannot enforce exact number of teams
      //as some teams may not be minted which currently
      //will revert 'team does not exist'... (protects 
      //progressing with incorrectly entered teamid(s))
      //This is a risk as we could forget to include
      //a team... but the alternative would be to remove
      //the aforementioned revert and check if the
      //teamid is a possible team rather than minted team
      //but this requires an inefficient nested loop
      //or a restructuring to use mappings instead
      //but ain't nobody got time for that right now
      if(teamIds.length > expectedTeams){
        revert('too many teams provided');
      }
   
      //We haven't reverted so far... so carry on...
      _;
    }

    //Public Variables

    /**
     * @dev Determines the current stage that the tournament is at
     * NOTE :  Public state variables have get methods automatically generated
     **/
    TournamentStageEnum public tournamentStage = TournamentStageEnum.GroupStage;

    //Public/External Methods

    /**
     * @dev  Progresses the tournament onto the next stage
     *       progressing successful teams and allocating
     *       phased prize in a single transaction so as to
     *       simplifiy phased prize pot calculations and protect
     *       against inconsistencies where only some teams are progressed.
     * VISIBILITY: external because calldata is more efficient than memory
     *             https://ethereum.stackexchange.com/questions/19380/external-vs-public-best-practices
     * WARN: Will REVERT if attempting to progress UNMINTED team via _setTeamStage...
     *       Offers some simple protection against entering unidentifiable teamIds
     *       by mistake.
     * TODO: - Does not check the number of teams are correct for each stage.
     *       - Does not stop us from skipping a tournament stage 
     * NOTE: It would be MUCH better to get this from an Oracle or other non centralised solution...
     *        e.g. Chainlink Any API to fetch from consensus driven
     *             pool of centralised data providers.
     *        however for now we'll just call it manually as each phase of the tournament ends
     *        we acknowledge this heavily centralises the project!
     *        and introduces a single point of failure!!
     **/
    function progressTournament(
        string[] calldata teamIds,
        TournamentStageEnum stage
    ) external 
    onlyOwner 
    tournamentProgressValid(stage)
    tournamentTeamsValid(stage, teamIds) {
       
        //set the current stage to the new one passed in
        //attempting to follow check-effect-interactions pattern
        tournamentStage = stage;

        //determine prize pot from current contract balance
        uint256 prizeMoney = 0;
        bool isPrizeWorthy = tournamentStageIsPrizeWorthy(stage);
        if (isPrizeWorthy) {
            //  Current Balance
            uint256 pot = getContractBalance();

            //  Calculate winnings amount per team
            prizeMoney = determinePrizeMoneyPerTeam(pot, stage);
        }

        //loop through each team and set their progression
        //and paying/attributing prize winners
        //NOTE: It can be dangerous to process too many things in a loop
        //      in case the gas block limit is reached meaning the transaction
        //      as a whole cannot be completed. 
        //      However we currently only have a maximum of 32 nft owners
        //      but if this was extended to 32 thousand nft owners we would
        //      want to consider restructuring this code:
        //      https://consensys.github.io/smart-contract-best-practices/attacks/denial-of-service/#gas-limit-dos-on-a-contract-via-unbounded-operations
        for (uint256 i = 0; i < teamIds.length; i++) {
            string memory teamId = teamIds[i];
            _setTeamStage(teamId, stage);

            if (isPrizeWorthy) {
                //attribute winnings
                _attributeWinnings(teamId, stage, prizeMoney);
            }
        }
    }

    /**
    * @dev Decides if the stage of the tournament is worthy of a prize or not?
    * NOTE :  Pure because this is effectively hardcoded so that it cannot be
    *         be changed. Public so anyone can see which stages of the tournament
    *         gets a prize.
    **/  
    function tournamentStageIsPrizeWorthy(TournamentStageEnum _stage)
        public
        pure
        returns (bool)
    {
        if (_stage == TournamentStageEnum.GroupStage) {
            //Tournament starts at group stage
            return false;
        } else if (
            _stage == TournamentStageEnum.Last16 ||
            _stage == TournamentStageEnum.QuaterFinal ||
            _stage == TournamentStageEnum.SemiFinal ||
            _stage == TournamentStageEnum.Final ||
            _stage == TournamentStageEnum.Champion
        ) {
            //All of these stages require a prize
            return true;
        } else {
            //Have we forgotten to write some code?
            revert("Unsupported Tournament stage");
        }
    }


    /**
    * @dev Determines the Prize per team progressing based on
    *      pot provided and stage provided.
    * NOTE :  PURE as it simply works with parameters provided
    *         PUBLIC mostly for testing but also allows users
    *         to experiment and speculate thier winnings for
    *         various stages of the tournament and for various
    *         prize pot sizes.
    **/  
    function determinePrizeMoneyPerTeam(uint256 pot, TournamentStageEnum stage)
        public
        pure
        returns (uint256)
    {
        require(pot > 0, "Prize pot must be greater than zero");

        uint256 potDivided = 0;
        uint8 prizeWorthyStagesRemaining = 5;

        // Number of teams at each stage:
        //    Last16 (16), QuaterFinal (8), SemiFinal (4), Final (2), Champion (1)
        //  Technically this code could suffer integer round downs (re link provided below)
        //  however, any small remainder balance from prize pot will be included in the next
        //  stage of the competition until the champion is declared who receives
        //  the entire remaining prize pot.
        //  Therefore have opted for code readability over fixing a problem
        //  which has negligable impact.
        //    https://consensys.github.io/smart-contract-best-practices/development-recommendations/solidity-specific/integer-division/
        if (stage == TournamentStageEnum.Last16) {
            prizeWorthyStagesRemaining = 5;
            potDivided = pot / prizeWorthyStagesRemaining / 16;
        } else if (stage == TournamentStageEnum.QuaterFinal) {
            prizeWorthyStagesRemaining = 4;
            potDivided = pot / prizeWorthyStagesRemaining / 8;
        } else if (stage == TournamentStageEnum.SemiFinal) {
            prizeWorthyStagesRemaining = 3;
            potDivided = pot / prizeWorthyStagesRemaining / 4;
        } else if (stage == TournamentStageEnum.Final) {
            prizeWorthyStagesRemaining = 2;
            potDivided = pot / prizeWorthyStagesRemaining / 2;
        } else if (stage == TournamentStageEnum.Champion) {
            //Pointless calculation because the winner takes all
            //of remaining prize pot... pattern shown to satisfy my ocd problem
            //  prizeWorthyStagesRemaining = 1;
            //  potDivided = pot / prizeWorthyStagesRemaining / 1;
            potDivided = pot;
        } else {
            if (tournamentStageIsPrizeWorthy(stage)) {
                revert(
                    "Hmmm... the developer forgot to write some code. Prize for stage is not determined."
                );
            } else {
                revert("Tournament stage does not require a prize");
            }
        }

        return potDivided;
    }

    /**
     * @dev private method to attribute winnings
     *      according to owner of nft's representing
     *      the team in quetion.    
     */
    function _attributeWinnings(
        string memory teamId,
        TournamentStageEnum stage,
        uint256 prizeMoney
    ) private {
        //  Team exists?
        require(
            teamExists(teamId),
            "Cannot attribute winnings for unminted team"
        );

        //  Determine owner
        address nftOwner = ownerOfTeam(teamId);

        //  Escrow money for winner
        _payNftOwner(nftOwner, prizeMoney);

        //  emit event for winner
        emit PrizeWin(msg.sender, nftOwner, teamId, stage, prizeMoney);
    }

    /**
     * @dev for best practice reasons and to limit
     *      reentrancy threats, winnings are moved
     *      to escrow where winners can claim/pull
     *      their unclaimed winnings via openzepplin
     *      PullPayment withdraw.
     */     
    function _payNftOwner(address nftOwner, uint256 prizeMoney)
        private
        onlyOwner
    {
        //Use OpenZepplin PullPayment from Escrow
        _asyncTransfer(nftOwner, prizeMoney);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./WCERC721.sol";
import "./library/TeamNFTStruct.sol";
import "./library/StageEnum.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/**
* @dev WorldCupSweepstakeBase Contract Defines the state variables (such as mappings)
       which are specifically related to World Cup Teams and provides methods for
      mapping between tokenIds and teams.
**/
abstract contract WorldCupSweepstakeBase is WorldCupSweepstakeERC721 {
    using Counters for Counters.Counter;

    //Constants
    // the official FIFA team Ids to be made available
    string[32] internal _teamIds = [
        "QAT",
        "NED",
        "SEN",
        "ECU",
        "ENG",
        "USA",
        "IRN",
        "WAL",
        "ARG",
        "POL",
        "MEX",
        "KSA",
        "FRA",
        "DEN",
        "TUN",
        "AUS",
        "ESP",
        "GER",
        "JPN",
        "CRC",
        "BEL",
        "CAN",
        "MAR",
        "CRO",
        "BRA",
        "SRB",
        "SUI",
        "CMR",
        "POR",
        "GHA",
        "URU",
        "KOR"
    ];

    //Private variables
    Counters.Counter private _tokenIdCounter;
    mapping(uint256 => TeamNFT) private _tokenIdToTeam;
    mapping(string => bool) private _teamIdExists;
    mapping(string => uint256) private _teamIdToTokenId;

    //Events
    event TeamMinted(
        address indexed _to,
        string _teamId,
        TournamentStageEnum _stage
    );
    event TeamTournamentStageChange(
        address indexed _from,
        string _teamId,
        TournamentStageEnum _stage
    );

    /**
     * @dev Constructor sets contract name and symbol passing through
     *      to the openzepplin ERC721 contract
     */
    constructor() WorldCupSweepstakeERC721("World Cup Sweepstake", "WCSWP") {}

    //Public/External Methods

    /**
     * @dev Allows direct minting
     * NOTE: Public so retstricted to contract owner.
     *       Only defined for testing
     *       TODO: use a test contract instead of exposing this method
     */
    function mintTeam(address to, string memory teamId) public onlyOwner {
        _mintTeam(to, teamId);
    }

    /**
     * @dev Exposes a way to determine all teams
     *      This could be made redundant if making
     *      _teamId public
     */
    function getAllPossibleTeamIds() external view returns (string[32] memory) {
        return _teamIds;
    }

    /**
     * @dev Determine if Team has already been minted
     */
    function teamExists(string memory teamId) public view returns (bool) {
        return _teamIdExists[teamId];
    }

    /**
     * @dev Mapping helper - find team from teamId
     * NOTE: Team includes the stage of the tournament the team is at
     */
    function teamFromTeamId(string memory teamId)
        external
        view
        returns (TeamNFT memory)
    {
        require(teamExists(teamId), "teamId does not exist");
        uint256 tokenId = _teamIdToTokenId[teamId];
        return teamFromTokenId(tokenId);
    }

    /**
     * @dev Mapping helper - find team from tokenId
     * NOTE: Team includes the stage of the tournament the team is at
     */
    function teamFromTokenId(uint256 tokenId)
        public
        view
        returns (TeamNFT memory)
    {
        require(_exists(tokenId), "tokenId does not exist");
        return _tokenIdToTeam[tokenId];
    }

    /**
     * @dev Mapping helper - find tokenId from teamId
     * NOTE: Assumes one to one single token per team
     *       This is correct at time of writing but
     *       we did have aspirations to provide multiple
     *       flavours of nft teams in the future.
     */
    function tokenIdFromTeamId(string memory teamId)
        public
        view
        returns (uint256)
    {
        require(teamExists(teamId));
        return _teamIdToTokenId[teamId];
    }

    /**
     * @dev Mapping helper - find owner from teamId
     * NOTE: Assumes one to one single token per team
     *       This is correct at time of writing but
     *       we did have aspirations to provide multiple
     *       flavours of nft teams in the future.
     */
    function ownerOfTeam(string memory teamId) public view returns (address) {
        uint256 tokenId = tokenIdFromTeamId(teamId);
        return ownerOf(tokenId);
    }

    //Private / Internal Methods

    /**
     * @dev Allows direct minting and handles
     *      team to token mapping and vice versa
     * NOTE: Called internal ONLY and therefore
     *       not restricted to owner
     * WARNING: Inheriting contracts should consider restrictions if using
     */
    function _mintTeam(address to, string memory teamId) internal {
        require(!teamExists(teamId), "team already exists");

        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        //setup team to mint
        TeamNFT memory team = TeamNFT(teamId, TournamentStageEnum.GroupStage);

        //store mappings
        _tokenIdToTeam[tokenId] = team;
        _teamIdExists[team.teamId] = true;
        _teamIdToTokenId[team.teamId] = tokenId;

        //call safe mint to mint new token id
        _safeMint(to, tokenId);

        emit TeamMinted(to, team.teamId, team.stage);
    }

    /**
     * @dev Enables setting the relevant team's tournament stage
     *      via mappings.
     * NOTE: Restricted to onlyOwner of the contract to make sure
     *       system cannot be abused.
     *       However, we acknowledge this introduces a centralised
     *       and single point of failure for this simple implementation
     */
    function _setTeamStage(string memory teamId, TournamentStageEnum stage)
        internal
        virtual
        onlyOwner
    {
        require(teamExists(teamId), "team does not exist");

        uint256 tokenId = _teamIdToTokenId[teamId];
        TeamNFT memory team = _tokenIdToTeam[tokenId];
        team.stage = stage;
        _tokenIdToTeam[tokenId] = team;

        // emit event
        emit TeamTournamentStageChange(msg.sender, team.teamId, stage);
    }
}

//  SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Payable {
    /**
     * @dev enables easy access to check the contract balance
     **/
    function getContractBalance() public view returns (uint256) {
        //view amount of ETH the contract contains
        return address(this).balance;
    }

    /**
     * @dev facilitates receiving eth to the smart contract address
     **/
    function depositUsingParameter(uint256 deposit) external payable {
        //deposit ETH using a parameter
        require(msg.value == deposit);
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/escrow/Escrow.sol)

pragma solidity ^0.8.0;

import "../../access/Ownable.sol";
import "../Address.sol";

/**
 * @title Escrow
 * @dev Base escrow contract, holds funds designated for a payee until they
 * withdraw them.
 *
 * Intended usage: This contract (and derived escrow contracts) should be a
 * standalone contract, that only interacts with the contract that instantiated
 * it. That way, it is guaranteed that all Ether will be handled according to
 * the `Escrow` rules, and there is no need to check for payable functions or
 * transfers in the inheritance tree. The contract that uses the escrow as its
 * payment method should be its owner, and provide public methods redirecting
 * to the escrow's deposit and withdraw.
 */
contract Escrow is Ownable {
    using Address for address payable;

    event Deposited(address indexed payee, uint256 weiAmount);
    event Withdrawn(address indexed payee, uint256 weiAmount);

    mapping(address => uint256) private _deposits;

    function depositsOf(address payee) public view returns (uint256) {
        return _deposits[payee];
    }

    /**
     * @dev Stores the sent amount as credit to be withdrawn.
     * @param payee The destination address of the funds.
     *
     * Emits a {Deposited} event.
     */
    function deposit(address payee) public payable virtual onlyOwner {
        uint256 amount = msg.value;
        _deposits[payee] += amount;
        emit Deposited(payee, amount);
    }

    /**
     * @dev Withdraw accumulated balance for a payee, forwarding all gas to the
     * recipient.
     *
     * WARNING: Forwarding all gas opens the door to reentrancy vulnerabilities.
     * Make sure you trust the recipient, or are either following the
     * checks-effects-interactions pattern or using {ReentrancyGuard}.
     *
     * @param payee The address whose funds will be withdrawn and transferred to.
     *
     * Emits a {Withdrawn} event.
     */
    function withdraw(address payable payee) public virtual onlyOwner {
        uint256 payment = _deposits[payee];

        _deposits[payee] = 0;

        payee.sendValue(payment);

        emit Withdrawn(payee, payment);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
                /// @solidity memory-safe-assembly
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
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
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

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
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
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
        _requireMinted(tokenId);

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
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

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
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
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
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
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
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
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
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
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
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
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
// OpenZeppelin Contracts (last updated v4.7.0) (security/PullPayment.sol)

pragma solidity ^0.8.0;

import "../utils/escrow/Escrow.sol";

/**
 * @dev Simple implementation of a
 * https://consensys.github.io/smart-contract-best-practices/recommendations/#favor-pull-over-push-for-external-calls[pull-payment]
 * strategy, where the paying contract doesn't interact directly with the
 * receiver account, which must withdraw its payments itself.
 *
 * Pull-payments are often considered the best practice when it comes to sending
 * Ether, security-wise. It prevents recipients from blocking execution, and
 * eliminates reentrancy concerns.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 *
 * To use, derive from the `PullPayment` contract, and use {_asyncTransfer}
 * instead of Solidity's `transfer` function. Payees can query their due
 * payments with {payments}, and retrieve them with {withdrawPayments}.
 */
abstract contract PullPayment {
    Escrow private immutable _escrow;

    constructor() {
        _escrow = new Escrow();
    }

    /**
     * @dev Withdraw accumulated payments, forwarding all gas to the recipient.
     *
     * Note that _any_ account can call this function, not just the `payee`.
     * This means that contracts unaware of the `PullPayment` protocol can still
     * receive funds this way, by having a separate account call
     * {withdrawPayments}.
     *
     * WARNING: Forwarding all gas opens the door to reentrancy vulnerabilities.
     * Make sure you trust the recipient, or are either following the
     * checks-effects-interactions pattern or using {ReentrancyGuard}.
     *
     * @param payee Whose payments will be withdrawn.
     *
     * Causes the `escrow` to emit a {Withdrawn} event.
     */
    function withdrawPayments(address payable payee) public virtual {
        _escrow.withdraw(payee);
    }

    /**
     * @dev Returns the payments owed to an address.
     * @param dest The creditor's address.
     */
    function payments(address dest) public view returns (uint256) {
        return _escrow.depositsOf(dest);
    }

    /**
     * @dev Called by the payer to store the sent amount as credit to be pulled.
     * Funds sent in this way are stored in an intermediate {Escrow} contract, so
     * there is no danger of them being spent before withdrawal.
     *
     * @param dest The destination address of the funds.
     * @param amount The amount to transfer.
     *
     * Causes the `escrow` to emit a {Deposited} event.
     */
    function _asyncTransfer(address dest, uint256 amount) internal virtual {
        _escrow.deposit{value: amount}(dest);
    }
}

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